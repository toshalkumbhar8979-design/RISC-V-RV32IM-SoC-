#====================================================================
# Makefile — RV32IM simulation (Phase 1) + SoC end-to-end (Phase 2).
# Run inside sim/ from WSL2:  make          -> Phase-1 core smoke
#                            make soc       -> Phase-2 SoC SOC test
#                            make qspi tft  -> unit tests
#====================================================================
BUILD  := build
VSRC   := ../rtl/rv32/rv32_core.v ../rtl/rv32/rv32_decoder.v ../rtl/rv32/rv32_alu.v \
          ../rtl/rv32/rv32_regfile.v ../rtl/rv32/rv32_immgen.v \
          ../rtl/rv32/rv32_muldiv.v ../rtl/rv32/rv32_csr.v
SOCV   := ../rtl/soc/riscv_soc.v ../rtl/soc/sram_wrap.v ../rtl/soc/bootrom.v \
          ../rtl/periph/qspi_ctrl.v ../rtl/periph/spi_tft.v \
          ../rtl/periph/uart_lite.v ../rtl/periph/timer.v
TB     := ../tb/tb_rv32.v
HEX    := ../tests/smoke.hex
VVP    := smoke.vvp

.PHONY: all hex run waves clean soc qspi

all: run

# ---- Phase 1: core smoke ----
$(BUILD)/smoke.o: ../tests/smoke.S | $(BUILD)
	riscv64-unknown-elf-as -march=rv32im_zicsr -mabi=ilp32 -o $@ $<

$(BUILD)/smoke.elf: $(BUILD)/smoke.o
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0 -o $@ $<

$(HEX): $(BUILD)/smoke.elf
	riscv64-unknown-elf-objcopy -O binary -j .text $< $(BUILD)/smoke.bin
	python3 ../tests/bin2hex.py $(BUILD)/smoke.bin $(HEX)

$(VVP): $(HEX) $(VSRC) $(TB)
	iverilog -g2005 -I ../rtl/rv32 -o $@ -s tb_rv32_core $(VSRC) $(TB)

run: $(VVP)
	vvp $(VVP)

# ---- Phase 2: SoC end-to-end ----
$(BUILD)/boot.o: ../tests/boot.S | $(BUILD)
	riscv64-unknown-elf-as -march=rv32im_zicsr -mabi=ilp32 -o $@ $<
$(BUILD)/boot.elf: $(BUILD)/boot.o
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0 -o $@ $<
$(BUILD)/boot.bin: $(BUILD)/boot.elf
	riscv64-unknown-elf-objcopy -O binary -j .text $< $@
bootrom.hex: $(BUILD)/boot.bin
	python3 ../tests/bin2hex.py $(BUILD)/boot.bin $@

$(BUILD)/app.o: ../tests/app.S | $(BUILD)
	riscv64-unknown-elf-as -march=rv32im_zicsr -mabi=ilp32 -o $@ $<
$(BUILD)/app.elf: $(BUILD)/app.o
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0x10000 -o $@ $<
$(BUILD)/app.bin: $(BUILD)/app.elf
	riscv64-unknown-elf-objcopy -O binary -j .text $< $@
app_flash.hex: $(BUILD)/app.bin
	python3 ../tests/bin2hex.py --bytes $(BUILD)/app.bin $@

soc: bootrom.hex app_flash.hex
	iverilog -g2005 -I ../rtl/rv32 -o soc.vvp -s tb_soc $(VSRC) $(SOCV) ../tb/tb_soc.v
	vvp soc.vvp

qspi:
	iverilog -g2005 -o q.vvp ../rtl/periph/qspi_ctrl.v ../tb/_tb_qspi.v
	vvp q.vvp

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD) $(VVP) smoke.vcd $(HEX) bootrom.hex app_flash.hex soc.vvp
