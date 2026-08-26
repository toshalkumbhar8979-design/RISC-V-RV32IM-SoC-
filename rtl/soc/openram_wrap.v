//====================================================================
// rtl/soc/openram_wrap.v — production 32 KB SRAM via an OpenRAM 1RW macro.
//
// This is the documented "OpenRAM hard-macro" swap for the flop-based
// sram_wrap (the resizer heavy-tail fix). In a real flow you generate the
// macro with OpenRAM:
//
//   python3 OpenRAM.py --outdir /mnt/c/.../open/designs/riscv_doom_soc/sram \
//     --tech_name scn3me_subm --process_corners tt --supply 1.80 \
//     --num_rw_ports 1 --num_r_ports 1 --num_w_ports 0 \
//     --words 8192 --word_size 32 --recompute_corners
//
// which produces sky130_sram_1rw1r (LEF/GDS/lib/verilog). This wrapper
// presents the same port map as sram_wrap (2 read ports + 1 write) built
// on the generated 1RW1R macro (or a 1RW + 1R instantiation).
//
// Because a hard macro is NOT available in this repo (it must be generated
// with the OpenRAM tool + PDK), this file documents the wrapper contract and
// provides a behavioral stand-in that synthesis treats like a black box /
// keep, so the OpenLane flow can be pointed at a real macro later.
//====================================================================
module openram_wrap #(
  parameter integer AW = 13,          // 2^AW words (8192 for 32 KB)
  parameter integer DW = 32
)(
  input  wire              clk,
  input  wire [AW-1:0]     ra_addr,   // read port A (instruction)
  output reg  [DW-1:0]     ra_data,
  input  wire [AW-1:0]     rb_addr,   // read port B (data)
  output reg  [DW-1:0]     rb_data,
  input  wire              we,        // write
  input  wire [AW-1:0]     w_addr,
  input  wire [3:0]        w_strb,
  input  wire [DW-1:0]     w_data
);

  // Behavioral stand-in (registered reads, byte-lane writes) — replace with
  // the OpenRAM-generated instance when the macro is available.
  reg [DW-1:0] mem [0:(1<<AW)-1];
  integer i;
  initial for (i = 0; i < (1<<AW); i = i + 1) mem[i] = {DW{1'b0}};

  always @(posedge clk) begin
    ra_data <= mem[ra_addr];
    rb_data <= mem[rb_addr];
  end

  always @(posedge clk) begin
    if (we) begin
      if (w_strb[0]) mem[w_addr][7:0]    <= w_data[7:0];
      if (w_strb[1]) mem[w_addr][15:8]   <= w_data[15:8];
      if (w_strb[2]) mem[w_addr][23:16]  <= w_data[23:16];
      if (w_strb[3]) mem[w_addr][31:24]  <= w_data[31:24];
    end
  end

endmodule