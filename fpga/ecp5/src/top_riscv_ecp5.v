//====================================================================
// top_riscv_ecp5.v — ECP5 target wrapper for `riscv_doom_soc`.
// Target: Lattice ECP5 (e.g., Colorlight-i5 / ULX3S-class board).
// The SoC is run directly off the board oscillator with no PLL in this
// milestone (25 MHz); clock-domain constraints in the .lpf.
// Pin numbers are deliberately NOT hard-bound here to stay board-
// agnostic; a concrete pin map gets filled in per actual carrier when
// bring-up hardware is on the bench (see fpga/colorlight-i5/README).
//====================================================================
`timescale 1ns/1ps
module top_riscv_ecp5 (
    input  wire  i_clk,      // board oscillator (25 MHz)
    input  wire  i_rst_n,    // active-low reset
    output wire  o_uart_tx,
    output wire  o_led,
    // SPI flash (W25Q128/N25Q class)
    output wire  o_f_cs_n, o_f_sck, o_f_mosi,
    input  wire  i_f_miso,
    // PSRAM chip-select (CS1, same SPI bus)
    output wire  o_p_cs_n,
    // SPI TFT (ILI9341-class, Pmod/breakout)
    output wire  o_tft_rst_n, o_tft_dc, o_tft_cs_n,
    output wire  o_tft_sclk, o_tft_sdi
);

  riscv_soc u_soc (
    .clk     (i_clk),
    .rst_n   (i_rst_n),
    .uart_txd(o_uart_tx),
    .tft_rst_n(o_tft_rst_n), .tft_dc(o_tft_dc), .tft_cs_n(o_tft_cs_n),
    .tft_sclk(o_tft_sclk), .tft_sdi(o_tft_sdi),
    .f_cs_n(o_f_cs_n), .f_sclk(o_f_sck), .f_mosi(o_f_mosi),
    .f_miso(i_f_miso),
    .p_cs_n(o_p_cs_n)
  );

  assign o_led = i_rst_n;   // simple "alive" indicator

endmodule