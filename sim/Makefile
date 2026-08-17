#====================================================================
# Makefile — RV32IM core simulation (iverilog). Run inside sim/ (WSL2).
#====================================================================
BUILD  := build
VSRC   := ../rtl/rv32/rv32_core.v ../rtl/rv32/rv32_decoder.v ../rtl/rv32/rv32_alu.v \
          ../rtl/rv32/rv32_regfile.v ../rtl/rv32/rv32_immgen.v \
          ../rtl/rv32/rv32_muldiv.v ../rtl/rv32/rv32_csr.v
TB     := ../tb/tb_rv32.v
HEX    := ../tests/smoke.hex
ELF    := $(BUILD)/smoke.elf
VVP    := smoke.vvp

.PHONY: all hex sim run waves clean

all: run

# ---- 1. build the .hex program image from assembly ----
$(BUILD)/smoke.o: ../tests/smoke.S | $(BUILD)
	riscv64-unknown-elf-as -march=rv32im_zicsr -mabi=ilp32 -o $@ $<

$(ELF): $(BUILD)/smoke.o
	riscv64-unknown-elf-ld -m elf32lriscv -Ttext 0 -o $@ $<

$(HEX): $(ELF)
	riscv64-unknown-elf-objcopy -O binary -j .text $(ELF) $(BUILD)/smoke.bin
	python3 ../tests/bin2hex.py $(BUILD)/smoke.bin $(HEX)

# ---- 2. compile + run simulation ----
$(VVP): $(HEX) $(VSRC) $(TB)
	iverilog -g2005 -I ../rtl/rv32 -o $(VVP) -s tb_rv32_core $(VSRC) $(TB)

run: $(VVP)
	vvp $(VVP)

waves: run
	gtkwave smoke.vcd

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD) $(VVP) smoke.vcd $(HEX)
