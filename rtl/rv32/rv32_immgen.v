//====================================================================
// rv32_immgen.v — immediate generation for all RISC-V 32-bit formats.
// Selects by opcode (funct3 given for store/load disambiguation).
//====================================================================
module rv32_immgen (
  input  wire [31:0] instr,
  output reg  [31:0] imm
);

  wire [31:0] imm_i = { {21{instr[31]}}, instr[30:20] };
  wire [31:0] imm_s = { {21{instr[31]}}, instr[30:25], instr[11:7] };
  wire [31:0] imm_b = { {20{instr[31]}}, instr[7], instr[30:25],
                        instr[11:8], 1'b0 };
  wire [31:0] imm_u = { instr[31:12], 12'b0 };
  wire [31:0] imm_j = { {12{instr[31]}}, instr[19:12], instr[20],
                        instr[30:21], 1'b0 };
  wire [31:0] imm_z = { 27'b0, instr[19:15] };   // CSR zimm (uimm5)

  always @(*) begin
    case (instr[6:0])
      `OP_JAL    : imm = imm_j;
      `OP_BRANCH: imm = imm_b;
      `OP_STORE : imm = imm_s;
      `OP_LUI,
      `OP_AUIPC : imm = imm_u;
      `OP_SYSTEM: imm = imm_z;
      default:   imm = imm_i;   // loads, jalr, op-imm, csr-imm
     endcase
  end
endmodule