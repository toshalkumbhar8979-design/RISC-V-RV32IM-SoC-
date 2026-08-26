//====================================================================
// fpga/sram_dp_sync.v — synchronous dual-port SRAM for FPGA targets.
//
// Same port map as rtl/soc/sram_wrap.v (two read ports + one byte-lane
// write port), but the read data is REGISTERED on the clock edge, so
// Yosys can infer ECP5 EBR block RAM instead of exploding the array
// into ~262k flip-flops (the Phase-4 blocker).
//
//  Read latency: 1 cycle.
//    cycle N : ra_addr captured, grant sampled
//    cycle N+1: ra_data valid for that address (mem[ra_addr] at N's edge)
//
//  The SoC adaptor drives imem_grant/dmem_grant so the core stalls one
//  cycle on SRAM reads (see riscv_soc.v, SYNC_SRAM param and the rv32_core
//  if_stall term).
//
//  Write: byte-lane, same semantics as the ASIC wrapper.
//====================================================================
module sram_dp_sync #(
  parameter integer AW = 15          // 2^AW words
)(
  input  wire             clk,
  // read port A (instruction)
  input  wire [AW-1:0]    ra_addr,
  output reg  [31:0]      ra_data,
  // read port B (data)
  input  wire [AW-1:0]    rb_addr,
  output reg  [31:0]      rb_data,
  // write port (data)
  input  wire             we,
  input  wire [AW-1:0]    w_addr,
  input  wire [3:0]       w_strb,
  input  wire [31:0]      w_data
);

  reg [31:0] mem [0:(1<<AW)-1];

  integer i;
  initial for (i = 0; i < (1<<AW); i = i + 1) mem[i] = 32'h0;

  // registered (synchronous) read ports -> EBR inference
  always @(posedge clk) begin
    ra_data <= mem[ra_addr];
  end

  always @(posedge clk) begin
    rb_data <= mem[rb_addr];
  end

  // byte-lane write (same semantics as the ASIC wrapper)
  always @(posedge clk) begin
    if (we) begin
      if (w_strb[0]) mem[w_addr][7:0]   <= w_data[7:0];
      if (w_strb[1]) mem[w_addr][15:8]  <= w_data[15:8];
      if (w_strb[2]) mem[w_addr][23:16] <= w_data[23:16];
      if (w_strb[3]) mem[w_addr][31:24] <= w_data[31:24];
    end
  end

endmodule