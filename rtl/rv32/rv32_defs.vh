//===================================================================
// rv32_defs.vh — RV32IM instruction-set constants and helper macros
// Verilog-2001, Yosys-synthesizable. Include once.
//===================================================================
`ifndef RV32_DEFS_VH
`define RV32_DEFS_VH

// ---------- opcodes (7-bit [6:0]) ----------
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111
`define OP_JALR     7'b1100111
`define OP_BRANCH   7'b1100011
`define OP_LOAD     7'b0000011
`define OP_STORE    7'b0100011
`define OP_OPIMM    7'b0010011
`define OP_OP       7'b0110011
`define OP_MISCMEM  7'b0001111
`define OP_SYSTEM   7'b1110011

// ---------- funct3 (LOAD/STORE sizes) ----------
`define F3_LB 3'b000
`define F3_LH 3'b001
`define F3_LW 3'b010
`define F3_LBU 3'b100
`define F3_LHU 3'b101

`define F3_SB 3'b000
`define F3_SH 3'b001
`define F3_SW 3'b010

// ---------- funct3 (BRANCH) ----------
`define F3_BEQ 3'b000
`define F3_BNE 3'b001
`define F3_BLT 3'b100
`define F3_BGE 3'b101
`define F3_BLTU 3'b110
`define F3_BGEU 3'b111

// ---------- funct3 (OPIMM / OP arith-logic) ----------
`define F3_ADDI 3'b000
`define F3_SLTI 3'b010
`define F3_SLTIU 3'b011
`define F3_XORI 3'b100
`define F3_ORI  3'b110
`define F3_ANDI 3'b111
`define F3_SSHIFT 3'b001   // SLLI
`define F3_RSHIFT 3'b101   // SRLI / SRAI

`define F3_ADDSUB 3'b000
`define F3_SLL  3'b001
`define F3_SLT  3'b010
`define F3_SLTU 3'b011
`define F3_XOR  3'b100
`define F3_SRL  3'b101
`define F3_OR   3'b110
`define F3_AND  3'b111

// ---------- funct3 (M extension) ----------
`define F3_MUL     3'b000
`define F3_MULH    3'b001
`define F3_MULHSU  3'b010
`define F3_MULHU   3'b011
`define F3_DIV     3'b100
`define F3_DIVU    3'b101
`define F3_REM     3'b110
`define F3_REMU    3'b111
`define F7_M        7'b0000001

// ---------- funct3 (CSR) ----------
`define F3_CSRRW  3'b001
`define F3_CSRRS  3'b010
`define F3_CSRRC  3'b011
`define F3_CSRRWI 3'b101
`define F3_CSRRSI 3'b110
`define F3_CSRRCI 3'b111

// ---------- SYSTEM immediate/rs2 encodings ----------
`define SYST_ECALL  12'h000
`define SYST_EBREAK 12'h001
`define SYST_MRET   12'h302
`define SYST_WFI    12'h105

// ---------- CSR addresses (low 12 bits) ----------
`define CSR_MSTATUS 12'h300
`define CSR_MCAUSE  12'h342
`define CSR_MEPC    12'h341
`define CSR_MTVEC   12'h305
`define CSR_MIE     12'h304
`define CSR_MIP     12'h344

// ---------- trap causes ----------
`define CAUSE_ILLEGAL_INSTR    32'd2
`define CAUSE_EBREAK           32'd3
`define CAUSE_ECALL_M          32'd11
`define CAUSE_LOAD_MISALIGN    32'd4
`define CAUSE_STORE_MISALIGN   32'd6
`define CAUSE_TIMER_IRQ        32'h8000_0005  // M.TIMER (trigger); MPP-independent for now

// ---------- MUL/DIV operator codes (core-internal) ----------
`define MOP_NONE   3'b000
`define MOP_MUL    3'b001
`define MOP_MULH   3'b010
`define MOP_MULHSU 3'b011
`define MOP_MULHU  3'b100
`define MOP_DIV    3'b101
`define MOP_DIVU   3'b110
`define MOP_REM    3'b111
`define MOP_REMU   3'b111

`endif