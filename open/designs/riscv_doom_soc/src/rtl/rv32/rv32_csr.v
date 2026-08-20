//====================================================================
// rv32_csr.v — minimal machine-level CSR block (MSTATUS, MEPC, MCAUSE,
// MTVEC, MIP/MIE-echo) + trap/mret state transitions.
// Bare-metal scope: single hart, machine mode, timer + one generic IRQ.
//====================================================================
`include "rv32_defs.vh"

module rv32_csr (
  input  wire        clk,
  input  wire        rst_n,

  // program-visible CSR access (from EX stage)
  input  wire [11:0] csr_addr_i,
  input  wire        csr_we_i,
  input  wire [31:0] csr_wdata_i,
  output wire [31:0] csr_rdata_o,

  // trap / machine-control hooks
  input  wire        trap_valid_i,     // one-cycle pulse: capture trap
  input  wire [31:0] trap_mepc_i,
  input  wire [31:0] trap_mcause_i,
  input  wire        mret_i,           // one-cycle pulse: mret

  // global interrupt state to core
  output wire        mstatus_mie_o,
  output wire [31:0] mtvec_o,          // trap vector (read-only back)
  output wire [31:0] mepc_o,           // exception pc (read-only back)
  input  wire        irq_timer_i       // 1 = timer interrupt asserted
);

  localparam MSTATUS_ADDR = `CSR_MSTATUS;
  localparam MEPC_ADDR    = `CSR_MEPC;
  localparam MCAUSE_ADDR  = `CSR_MCAUSE;
  localparam MTVEC_ADDR   = `CSR_MTVEC;

  reg [31:0] mstatus;  // [3]=MIE [7]=MPIE [12:11]=MPP
  reg [31:0] mepc;
  reg [31:0] mcause;
  reg [31:0] mtvec;

  reg [31:0] rdata;
  always @(*) begin
    case (csr_addr_i)
      MSTATUS_ADDR: rdata = mstatus;
      MEPC_ADDR    : rdata = mepc;
      MCAUSE_ADDR  : rdata = mcause;
      MTVEC_ADDR   : rdata = mtvec;
      default      : rdata = 32'h0;   // MIE/MIP read as 0 in this build
    endcase
  end
  assign csr_rdata_o = rdata;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mstatus <= 32'h0000_1000;  // MPP=M
      mepc    <= 32'h0;
      mcause  <= 32'h0;
      mtvec   <= 32'h0;
    end else begin
      // trap entry: MPIE(bit7)<=MIE, MIE(bit3)<=0, MPP/bits4..6 hold
      if (trap_valid_i) begin
        mstatus <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
        mepc    <= trap_mepc_i;
        mcause  <= trap_mcause_i;
      end else if (mret_i) begin
        // mret: MIE <= MPIE, MPIE <= 1
        mstatus <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]};
      end else if (csr_we_i) begin
        case (csr_addr_i)
          MSTATUS_ADDR: mstatus <= csr_wdata_i;
          MEPC_ADDR:    mepc    <= csr_wdata_i;
          MCAUSE_ADDR:  mcause  <= csr_wdata_i;
          MTVEC_ADDR:   mtvec   <= csr_wdata_i;   // mode bits handled by SW
          default:      ;
        endcase
      end
    end
  end

  assign mstatus_mie_o = mstatus[3];
  assign mtvec_o       = mtvec;
  assign mepc_o        = mepc;
endmodule