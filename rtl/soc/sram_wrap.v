//====================================================================
// sram_wrap.v — simple on-chip RAM (32-bit word, byte-lane writes).
// Two combinational read ports (for the Harvard I$ and D$), one write.
// Yosys will map this to registers; an OpenRAM macro replaces it in
// Phase 5 for the real 32KB. Physical addresses are word-aligned via
// the caller.
//====================================================================
module sram_wrap #(
  parameter integer AW = 15,          // 2^AW words
  parameter integer INIT_HEX = ""     // optional .hex init (mostly unused)
)(
  input  wire             clk,
  // read port A (instruction)
  input  wire [AW-1:0]    ra_addr,
  output wire [31:0]      ra_data,
  // read port B (data)
  input  wire [AW-1:0]    rb_addr,
  output wire [31:0]      rb_data,
  // write port (data)
  input  wire             we,
  input  wire [AW-1:0]    w_addr,
  input  wire [3:0]       w_strb,
  input  wire [31:0]      w_data
);

  reg [31:0] mem [0:(1<<AW)-1];

  integer i;
  generate if (INIT_HEX != "") begin : gin
    initial $readmemh(INIT_HEX, mem);
  end else begin : gno
    initial for (i = 0; i < (1<<AW); i = i + 1) mem[i] = 32'h0;
  end endgenerate

  always @(posedge clk) begin
    if (we) begin
      if (w_strb[0]) mem[w_addr][7:0]   <= w_data[7:0];
      if (w_strb[1]) mem[w_addr][15:8]  <= w_data[15:8];
      if (w_strb[2]) mem[w_addr][23:16] <= w_data[23:16];
      if (w_strb[3]) mem[w_addr][31:24] <= w_data[31:24];
    end
  end

  assign ra_data = mem[ra_addr];
  assign rb_data = mem[rb_addr];

endmodule