#!/bin/bash
set -e
D=/mnt/c/Users/tosha/Downloads/RiscV/open/designs/riscv_doom_soc
cd "$D"
mkdir -p out
yosys -p 'read_verilog -I src/rtl/rv32 src/riscv_doom_soc.v src/rtl/rv32/rv32_alu.v src/rtl/rv32/rv32_csr.v src/rtl/rv32/rv32_decoder.v src/rtl/rv32/rv32_immgen.v src/rtl/rv32/rv32_muldiv.v src/rtl/rv32/rv32_regfile.v src/rtl/rv32/rv32_core.v src/rtl/soc/bootrom.v src/rtl/soc/riscv_soc.v src/rtl/soc/sram_wrap.v src/rtl/periph/qspi_ctrl.v src/rtl/periph/spi_tft.v src/rtl/periph/timer.v src/rtl/periph/uart_lite.v; stat -top riscv_doom_soc' > "$D/probe.log" 2>&1
RC=$?
echo "PROBE_DONE rc=$RC" >> "$D/probe.log"
cp "$D/probe.log" "$D/out/elaborate_stat.txt" 2>/dev/null || true