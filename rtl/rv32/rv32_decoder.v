//====================================================================
// rv32_decoder.v — combinational RV32IM (base + M) instruction decode.
// Produces flat control for the EX stage of the 2-stage pipeline.
//====================================================================
`include "rv32_defs.vh"

module rv32_decoder (
  input  wire [31:0] instr,

  output reg         illegal,
  output reg         reg_we,      // GPR write-back enable
  output reg  [3:0]  alu_op,      // rv32_alu op (see rv32_alu.v)
  output reg  [1:0]  alu_b_sel,   // 0=rs2 1=imm 2=csr_cur 3=zimm
  output reg         is_lui,
  output reg         is_auipc,
  output reg         mem_load,
  output reg         mem_store,
  output reg  [1:0]  mem_sz,      // 0=B 1=H 2=W
  output reg         mem_sign,    // sign-extend for LB/LH
  output reg         branch_en,
  output reg         jal_en,
  output reg         jalr_en,
  output reg         csr_en,
  output reg  [1:0]  csr_mode,    // 0=csrrw 1=csrrs 2=csrrc (imm variants too)
  output reg         csr_imm_sel, // 1 = zimm[4:0] operand instead of rs1
  output reg         mret_en,
  output reg         ecall_en,
  output reg         ebreak_en,
  output reg         wfi_en,
  output reg         m_instr,     // M-extension (MUL/DIV)
  output reg  [2:0]  m_op         // rv32_muldiv select
);

  wire [6:0]  op    = instr[6:0];
  wire [2:0]  f3    = instr[14:12];
  wire [6:0]  f7    = instr[31:25];
  wire [11:0] imm12 = instr[31:20];

  always @(*) begin
    illegal    = 1'b0;
    reg_we     = 1'b0;
    alu_op     = 4'b0000;
    alu_b_sel  = 2'b00;
    is_lui     = 1'b0;
    is_auipc   = 1'b0;
    mem_load   = 1'b0;
    mem_store  = 1'b0;
    mem_sz     = 2'b10;
    mem_sign   = 1'b1;
    branch_en  = 1'b0;
    jal_en     = 1'b0;
    jalr_en    = 1'b0;
    csr_en     = 1'b0;
    csr_mode   = 2'b00;
    csr_imm_sel= 1'b0;
    mret_en    = 1'b0;
    ecall_en   = 1'b0;
    ebreak_en  = 1'b0;
    wfi_en     = 1'b0;
    m_instr    = 1'b0;
    m_op       = `MOP_NONE;

    case (op)
      `OP_LUI: begin
        reg_we = 1'b1; is_lui = 1'b1; alu_op = 4'b1010; alu_b_sel = 2'b01;
      end
      `OP_AUIPC: begin
        reg_we = 1'b1; is_auipc = 1'b1; alu_op = 4'b0000; alu_b_sel = 2'b01;
      end
      `OP_JAL: begin
        reg_we = 1'b1; jal_en = 1'b1;
      end
      `OP_JALR: begin
        reg_we = 1'b1; jalr_en = 1'b1; alu_op = 4'b0000; alu_b_sel = 2'b01;
      end
      `OP_BRANCH: begin
        branch_en = 1'b1;
      end
      `OP_LOAD: begin
        reg_we = 1'b1; mem_load = 1'b1; alu_op = 4'b0000; alu_b_sel = 2'b01;
        case (f3)
          `F3_LB:  begin mem_sz = 2'b00; mem_sign = 1'b1; end
          `F3_LH:  begin mem_sz = 2'b01; mem_sign = 1'b1; end
          `F3_LW:  begin mem_sz = 2'b10; mem_sign = 1'b0; end
          `F3_LBU: begin mem_sz = 2'b00; mem_sign = 1'b0; end
          `F3_LHU: begin mem_sz = 2'b01; mem_sign = 1'b0; end
          default: illegal = 1'b1;
        endcase
      end
      `OP_STORE: begin
        mem_store = 1'b1; alu_op = 4'b0000; alu_b_sel = 2'b01;
        case (f3)
          `F3_SB:   mem_sz = 2'b00;
          `F3_SH:   mem_sz = 2'b01;
          `F3_SW:   mem_sz = 2'b10;
          default:  illegal = 1'b1;
        endcase
      end
      `OP_OPIMM: begin
        reg_we = 1'b1; alu_b_sel = 2'b01;
        case (f3)
          `F3_ADDI:  alu_op = 4'b0000;
          `F3_SLTI:  alu_op = 4'b1000;
          `F3_SLTIU: alu_op = 4'b1001;
          `F3_XORI:  alu_op = 4'b0101;
          `F3_ORI:   alu_op = 4'b0111;
          `F3_ANDI:  alu_op = 4'b0110;
          `F3_SSHIFT: begin
            if (f7 == 7'b0000000) alu_op = 4'b0010; else illegal = 1'b1;
          end
          `F3_RSHIFT: begin
            if      (f7 == 7'b0000000) alu_op = 4'b0011;
            else if (f7 == 7'b0100000) alu_op = 4'b0100;
            else                       illegal = 1'b1;
          end
          default: illegal = 1'b1;
        endcase
      end
`OP_OP: begin
        if (f7 == `F7_M) begin
          // M extension — m_op carries raw funct3 (MUL..REMU)
          m_instr = 1'b1; reg_we = 1'b1; m_op = f3;
        end else begin
          reg_we = 1'b1;
          case (f3)
            `F3_ADDSUB: begin
              if (f7 == 7'b0000000)      alu_op = 4'b0000;
              else if (f7 == 7'b0100000) alu_op = 4'b0001;
              else illegal = 1'b1;
            end
            `F3_SLL:  if (f7 == 7'b0000000) alu_op = 4'b0010; else illegal = 1'b1;
            `F3_SLT:  if (f7 == 7'b0000000) alu_op = 4'b1000; else illegal = 1'b1;
            `F3_SLTU: if (f7 == 7'b0000000) alu_op = 4'b1001; else illegal = 1'b1;
            `F3_XOR:  if (f7 == 7'b0000000) alu_op = 4'b0101; else illegal = 1'b1;
            `F3_SRL:  begin
              if      (f7 == 7'b0000000) alu_op = 4'b0011;
              else if (f7 == 7'b0100000) alu_op = 4'b0100;
              else illegal = 1'b1;
            end
            `F3_OR:   if (f7 == 7'b0000000) alu_op = 4'b0111; else illegal = 1'b1;
            `F3_AND:  if (f7 == 7'b0000000) alu_op = 4'b0110; else illegal = 1'b1;
            default: illegal = 1'b1;
          endcase
        end
      end
      `OP_MISCMEM: begin
        // fence / fence.i — NOP (documented; coherent caches are a
        // Phase-2 system concern, not a core one)
      end
      `OP_SYSTEM: begin
        if (f3 == 3'b000) begin
          // system instructions (funct3=000, imm12 encodes)
          if      (imm12 == `SYST_MRET)   mret_en = 1'b1;
          else if (imm12 == `SYST_ECALL)  ecall_en = 1'b1;
          else if (imm12 == `SYST_EBREAK) ebreak_en = 1'b1;
          else if (imm12 == `SYST_WFI)    wfi_en   = 1'b1;
          else illegal = 1'b1;
        end else begin
          csr_en    = 1'b1;
          reg_we    = 1'b1;
          alu_op    = 4'b1010;      // rd = csr value (pass through ALU-b)
          alu_b_sel = 2'b10;
          case (f3)
            `F3_CSRRW:  csr_mode = 2'b00;
            `F3_CSRRS:  csr_mode = 2'b01;
            `F3_CSRRC:  csr_mode = 2'b10;
            `F3_CSRRWI: begin csr_mode = 2'b00; csr_imm_sel = 1'b1; end
            `F3_CSRRSI: begin csr_mode = 2'b01; csr_imm_sel = 1'b1; end
            `F3_CSRRCI: begin csr_mode = 2'b10; csr_imm_sel = 1'b1; end
            default: illegal = 1'b1;
          endcase
        end
      end
      default: illegal = 1'b1;
    endcase
  end

endmodule