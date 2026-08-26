//====================================================================
// rv32_core.v — RV32IM 5-stage-style, implemented as a simple 2-phase
// pipeline with one-instruction prefetch depth:
//
//   Stage 1 (IF)   : fetch next instruction (1-cycle), redirect on
//                    branches/jumps/traps
//   Stage 2 (EX/M) : full decode+execute+memory+writeback in one cycle
//                    with combinational ready/ack memory ports
//
// Multi-cycle M-extension (rv32_muldiv) and CSR state
// (rv32_csr.v) are attached in EX. Hazards: no load-use stall needed
// (writeback lands at the same edge the consumer reads), branches
// resolve in EX with 3-cycle taken penalty, IRQs taken exactly at
// instruction boundaries (when the prefetch slot is empty).
//
// Memory interface contract (combinational in this testbench,
// gated through grant signals; Phase-2 memory adaptor will add
// latency and stall the core):
//   imem: addr + req, data must be ready when grant is high
//   dmem: addr + we + wstrb + wdata on req, rdata when grant high
//====================================================================
`include "rv32_defs.vh"

module rv32_core #(
  parameter [31:0] RESET_PC = 32'h0000_0000
)(
  input  wire        clk,
  input  wire        rst_n,

  // ---- instruction memory (read-only) ----
  output wire [31:0] imem_addr,
  output wire        imem_valid,
  input  wire        imem_grant,
  input  wire [31:0] imem_rdata,

  // ---- data memory ----
  output wire [31:0] dmem_addr,
  output wire        dmem_valid,
  output wire        dmem_we,
  output wire [3:0]  dmem_wstrb,
  output wire [31:0] dmem_wdata,
  input  wire        dmem_grant,
  input  wire [31:0] dmem_rdata,

  // ---- interrupts / debug ----
  input  wire        irq_tmr,
  output wire        inst_commit,
  output wire        trap_active
);

  //===============================================================
  // Register pipeline state
  //===============================================================
  reg  [31:0] fetch_pc;   // next address to fetch
  reg  [31:0] ins;        // instruction in EX stage
  reg  [31:0] ins_pc;     // its program counter
  reg         ins_v;      // ins is valid (EX stage busy)

  //===============================================================
  // Instruction decode
  //===============================================================
  wire        illegal;
  wire        reg_we;
  wire [3:0]  alu_op;
  wire [1:0]  alu_b_sel;
  wire        is_lui;
  wire        is_auipc;
  wire        mem_load;
  wire        mem_store;
  wire [1:0]  mem_sz;
  wire        mem_sign;
  wire        branch_en;
  wire        jal_en;
  wire        jalr_en;
  wire        csr_en;
  wire [1:0]  csr_mode;
  wire        csr_imm_sel;
  wire        mret_en;
  wire        ecall_en;
  wire        ebreak_en;
  wire        wfi_en;
  wire        m_instr;
  wire [2:0]  m_op;

  rv32_decoder u_dec (
    .instr       (ins),
    .illegal     (illegal),
    .reg_we      (reg_we),
    .alu_op      (alu_op),
    .alu_b_sel   (alu_b_sel),
    .is_lui      (is_lui),
    .is_auipc    (is_auipc),
    .mem_load    (mem_load),
    .mem_store   (mem_store),
    .mem_sz      (mem_sz),
    .mem_sign    (mem_sign),
    .branch_en   (branch_en),
    .jal_en      (jal_en),
    .jalr_en     (jalr_en),
    .csr_en      (csr_en),
    .csr_mode    (csr_mode),
    .csr_imm_sel (csr_imm_sel),
    .mret_en     (mret_en),
    .ecall_en    (ecall_en),
    .ebreak_en   (ebreak_en),
    .wfi_en      (wfi_en),
    .m_instr     (m_instr),
    .m_op        (m_op)
  );

  //===============================================================
  // Immediate + register file
  //===============================================================
  wire [31:0] imm;
  wire [31:0] zimm = {27'b0, ins[19:15]};
  wire [4:0]  rs1a = ins[19:15];
  wire [4:0]  rs2a = ins[24:20];
  wire [4:0]  rda  = ins[11:7];

  rv32_immgen u_imm (.instr(ins), .imm(imm));

  wire [31:0] rf1, rf2;
  rv32_regfile u_rf (
    .clk   (clk),
    .rst_n (rst_n),
    .we    (wb_we),
    .waddr (rda),
    .wdata (wb_data),
    .raddr1(rs1a),
    .rdata1(rf1),
    .raddr2(rs2a),
    .rdata2(rf2)
  );

  //===============================================================
  // ALU
  //===============================================================
  wire [31:0] alu_a  = is_auipc ? ins_pc : rf1;
  wire [31:0] alu_b  = (alu_b_sel == 2'b01) ? imm :
                       (alu_b_sel == 2'b10) ? csr_rdata :
                       (alu_b_sel == 2'b11) ? zimm : rf2;
  wire [31:0] alu_y;
  wire        eq, lt;
  wire        ltu;

  rv32_alu u_alu (
    .a     (alu_a),
    .b     (alu_b),
    .alu_op(alu_op),
    .y     (alu_y),
    .eq    (eq),
    .lt    (lt),
    .ltu   (ltu)
  );

//===============================================================
  // CSR block
  //===============================================================
  wire [31:0] csr_rdata;
  wire        mstatus_mie;
  wire [31:0] csr_mtvec, csr_mepc;

  // trap / machine op pulses (combinational; consumed at the edge)
  wire trap_pulse = ( (ins_v && (ecall_en || ebreak_en || illegal ||
                                 misaligned)) || irq_ok );
  wire [31:0] trap_mepc   = irq_ok ? fetch_pc : ins_pc;
  wire [31:0] trap_mcause = irq_ok    ? `CAUSE_TIMER_IRQ :
                            ecall_en  ? `CAUSE_ECALL_M :
                            ebreak_en ? `CAUSE_EBREAK :
                            illegal   ? `CAUSE_ILLEGAL_INSTR :
                            mem_load  ? `CAUSE_LOAD_MISALIGN :
                                        `CAUSE_STORE_MISALIGN;
  wire mret_pulse = ins_v && mret_en;

  // CSR write from instruction (fires with the instruction)
  wire [31:0] csr_operand = csr_imm_sel ? zimm : rf1;
  wire [31:0] csr_wr_data = (csr_mode == 2'b00) ? csr_operand :
                            (csr_mode == 2'b01) ? (csr_rdata | csr_operand) :
                            (csr_mode == 2'b10) ? (csr_rdata & ~csr_operand) :
                                                  csr_rdata;
  wire csr_wr_en = csr_en && ins_v;

  rv32_csr u_csr (
    .clk           (clk),
    .rst_n         (rst_n),
    .csr_addr_i    (ins[31:20]),
    .csr_we_i      (csr_wr_en),
    .csr_wdata_i   (csr_wr_data),
    .csr_rdata_o   (csr_rdata),
    .trap_valid_i  (trap_pulse),
    .trap_mepc_i   (trap_mepc),
    .trap_mcause_i (trap_mcause),
    .mret_i        (mret_pulse),
    .mstatus_mie_o (mstatus_mie),
    .mtvec_o       (csr_mtvec),
    .mepc_o        (csr_mepc),
    .irq_timer_i   (irq_tmr)
  );

  //===============================================================
  // M-extension engine
  //===============================================================
  wire        md_busy, md_done;
  wire [31:0] md_res;
  wire md_start = ins_v && m_instr && !md_busy && !md_done;

  rv32_muldiv u_md (
    .clk    (clk),
    .rst_n  (rst_n),
    .start_i(md_start),
    .a_i    (rf1),
    .b_i    (rf2),
    .op_i   (m_op),
    .res_o  (md_res),
    .done_o (md_done),
    .busy_o (md_busy)
  );

  //===============================================================
  // EX control (combinational)
  //===============================================================
  wire [2:0] f3    = ins[14:12];
  wire [31:0] bjump_tgt = ins_pc + imm;              // B/J immediate
  wire [31:0] jalr_tgt  = (rf1 + imm) & 32'hFFFF_FFFE;

  wire b_taken = branch_en &&
    ((f3 == 3'b000) ?  eq  :   // beq
     (f3 == 3'b001) ? !eq  :   // bne
     (f3 == 3'b100) ?  lt  :   // blt
     (f3 == 3'b101) ? !lt  :   // bge
     (f3 == 3'b110) ?  ltu :   // bltu
                      !ltu);   // bgeu

  wire [31:0] mem_addr = alu_y;

  wire misaligned = ins_v && (mem_load || mem_store) &&
      ((mem_sz == 2'b10) ? (mem_addr[1:0] != 2'b00) :
       (mem_sz == 2'b01) ? (mem_addr[0]  != 1'b0)   : 1'b0);
  wire ex_trap    = ins_v && (ecall_en || ebreak_en || illegal || misaligned);
  wire ex_branch  = ins_v && (b_taken || jal_en || jalr_en);
  wire ex_mret    = ins_v && mret_en;
  wire irq_ok     = irq_tmr && mstatus_mie && !ins_v;

  // stalls: multi-cycle M unit, deferred memory grant, deferred instruction
  // grant (1-cycle-latency instruction memory, e.g. sync FPGA BRAM)
  wire md_stall   = ins_v && m_instr && !md_done;
  wire mem_stall  = ins_v && (mem_load || mem_store) && !dmem_grant;
  wire if_stall   = imem_valid && !imem_grant;   // fetch issued, data not returned yet
  wire all_stop   = md_stall || mem_stall || if_stall;

  wire redirect = (ex_branch || ex_trap || ex_mret || irq_ok) && !all_stop;

  wire [31:0] tgt_pc =
      (ex_mret) ? csr_mepc :
      (b_taken) ? bjump_tgt :
      (jal_en)  ? bjump_tgt :
      (jalr_en) ? jalr_tgt :
                  csr_mtvec;     // traps and IRQs

//===============================================================
  // Load mux + write-back
  //===============================================================
  wire [7:0]  sel_b = (mem_addr[1:0] == 2'b00) ? dmem_rdata[7:0] :
                      (mem_addr[1:0] == 2'b01) ? dmem_rdata[15:8] :
                      (mem_addr[1:0] == 2'b10) ? dmem_rdata[23:16] :
                                                 dmem_rdata[31:24];
  wire [15:0] sel_h = mem_addr[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];

  wire [31:0] ld_val =
    (mem_sz == 2'b00) ? (mem_sign ? {{24{sel_b[7]}}, sel_b} : {24'b0, sel_b}) :
    (mem_sz == 2'b01) ? (mem_sign ? {{16{sel_h[15]}}, sel_h} : {16'b0, sel_h}) :
                        dmem_rdata;

  wire [31:0] wb_data =
                        (jal_en || jalr_en) ? (ins_pc + 32'h4) :
                        mem_load  ? ld_val  :
                        (m_instr) ? md_res  :
                        (csr_en)  ? csr_rdata :
                                    alu_y;

  wire wb_we = ins_v && reg_we && !ex_trap && !all_stop;

  //===============================================================
  // Data memory request (combinational)
  //===============================================================
  wire mem_op = ins_v && (mem_load || mem_store) && !ex_trap;

  assign dmem_addr  = mem_addr;
  assign dmem_valid = mem_op;
  assign dmem_we    = mem_store;
  assign dmem_wdata = rf2;
  assign dmem_wstrb = (mem_sz == 2'b00) ? (4'b0001 << mem_addr[1:0])  :
                      (mem_sz == 2'b01) ? (4'b0011 << {mem_addr[1], 1'b0}) :
                                          4'b1111;

  //===============================================================
  //  Instruction memory request
  //===============================================================
  assign imem_addr  = fetch_pc;
  assign imem_valid = !(md_stall || mem_stall);   // fetch request independent of
                                                  // if_stall (avoids comb loop)

  //===============================================================
  //  Debug outputs
  //===============================================================
  assign inst_commit = ins_v && !all_stop && !ex_trap;
  assign trap_active = (ex_trap || irq_ok) && !all_stop;

  //===============================================================
  //  Pipeline register update (posedge)
  //===============================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      fetch_pc <= RESET_PC;
      ins      <= 32'h0;
      ins_pc   <= 32'h0;
      ins_v    <= 1'b0;
    end else if (!all_stop) begin
      if (irq_ok) begin
        // interrupt at an instruction boundary
        ins_v    <= 1'b0;
        fetch_pc <= csr_mtvec;
      end else if (ex_branch || ex_mret || ex_trap) begin
        // control transfer: branch / jal / jalr / mret / exception
        ins_v    <= 1'b0;
        fetch_pc <= tgt_pc;
      end else begin
        // normal single-issue: execute `ins`, prefetch the next
        ins      <= imem_rdata;
        ins_pc   <= fetch_pc;
        ins_v    <= 1'b1;
        fetch_pc <= fetch_pc + 32'h4;
      end
    end
  end

endmodule