#!/bin/bash
# stage_small_design.sh — create a second design copy with SRAM_AW=2 (fast probe).
set -e
SRC=/mnt/c/Users/tosha/Downloads/RiscV/open/designs/riscv_doom_soc
DST=/home/toshal/work/riscv_doom_soc_small
mkdir -p "$DST/src"
cp -r "$SRC/bootrom.hex" "$DST/"
cp -r "$SRC/src/rtl" "$DST/src/"
# small-RAM top wrapper
cat > "$DST/src/riscv_doom_soc.v" <<'EOF'
// riscv_doom_soc_small — probe top with SRAM_AW=2 for tractable P&R.
module riscv_doom_soc (
  input  wire clk,
  input  wire rst_n,
  input  wire f_miso,
  output wire uart_txd,
  output wire tft_rst_n, tft_dc, tft_cs_n, tft_sclk, tft_sdi,
  output wire f_cs_n, f_sclk, f_mosi
);
  riscv_soc #(.SRAM_AW(2)) u_soc (
    .clk(clk), .rst_n(rst_n), .uart_txd(uart_txd),
    .tft_rst_n(tft_rst_n), .tft_dc(tft_dc), .tft_cs_n(tft_cs_n),
    .tft_sclk(tft_sclk), .tft_sdi(tft_sdi),
    .f_cs_n(f_cs_n), .f_sclk(f_sclk), .f_mosi(f_mosi), .f_miso(f_miso)
  );
endmodule
EOF
# config identical except design name (module stays riscv_doom_soc for OL)
cp "$SRC/config.json" "$DST/config.json"
echo "STAGED_SMALL:"; find "$DST" -type f | wc -l