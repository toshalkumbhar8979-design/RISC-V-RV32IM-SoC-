#!/bin/sh
# open/refresh_src.sh — snapshot the synthesizable RTL used by the ASIC probe
# into the design src/ tree (kept in sync with rtl/ by re-running this).
RTL=/mnt/c/Users/tosha/Downloads/RiscV/rtl
D=/mnt/c/Users/tosha/Downloads/RiscV/open/designs/riscv_doom_soc/src
set -e
rm -rf "$D/rtl"
mkdir -p "$D/rtl/rv32" "$D/rtl/soc" "$D/rtl/periph"
cp "$RTL"/rv32/rv32_alu.v "$RTL"/rv32/rv32_core.v "$RTL"/rv32/rv32_csr.v \
   "$RTL"/rv32/rv32_decoder.v "$RTL"/rv32/rv32_immgen.v "$RTL"/rv32/rv32_muldiv.v \
   "$RTL"/rv32/rv32_regfile.v "$RTL"/rv32/rv32_defs.vh    "$D/rtl/rv32/"
cp "$RTL"/soc/bootrom.v "$RTL"/soc/riscv_soc.v "$RTL"/soc/sram_wrap.v "$D/rtl/soc/"
cp "$RTL"/periph/qspi_ctrl.v "$RTL"/periph/spi_tft.v \
   "$RTL"/periph/timer.v  "$RTL"/periph/uart_lite.v "$D/rtl/periph/"
echo "synced $(find "$D/rtl" -name '*.v*' | wc -l) files into src/rtl"