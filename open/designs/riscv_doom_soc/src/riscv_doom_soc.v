// riscv_doom_soc.v — OpenLane 2 silicon top for the ASIC probe.
// Re-enters riscv_soc with a RAM-less SRAM (SRAM_AW=9 => 512 words flops)
// so a full synthesis/place/route/jam sign-off fits the 600x400um die.
// The real 32 KB comes in as an OpenRAM macro in the production target
// (see reports/PHASE5_STATUS.md).
module riscv_doom_soc (
  input  wire clk,
  input  wire rst_n,
  input  wire f_miso,
  output wire uart_txd,
  output wire tft_rst_n, tft_dc, tft_cs_n, tft_sclk, tft_sdi,
  output wire f_cs_n, f_sclk, f_mosi
);
  riscv_soc #(.SRAM_AW(9)) u_soc (
    .clk        (clk),
    .rst_n      (rst_n),
    .uart_txd   (uart_txd),
    .tft_rst_n  (tft_rst_n), .tft_dc (tft_dc), .tft_cs_n (tft_cs_n),
    .tft_sclk   (tft_sclk), .tft_sdi (tft_sdi),
    .f_cs_n     (f_cs_n), .f_sclk (f_sclk), .f_mosi (f_mosi),
    .f_miso     (f_miso)
  );
endmodule