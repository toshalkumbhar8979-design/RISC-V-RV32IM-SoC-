#====================================================================
# Makefile — riscv_doom_soc software (Phase 3) build.
# CROSS-compile bare-metal C for rv32im/ilp32, link with the Phase-0
# memory-map linker script, emit the SPI-flash image for the SoC TB.
#====================================================================
CROSS   := riscv64-unknown-elf-
CC      := $(CROSS)gcc
AS      := $(CROSS)as
LD      := $(CROSS)ld
OBJCOPY := $(CROSS)objcopy
BUILD   := build

ARCH    := -march=rv32im_zicsr -mabi=ilp32
CFLAGS  := $(ARCH) -Os -ffreestanding -fno-builtin -fno-stack-protector \
           -Wall -Iplatform
LDFLAGS := -m elf32lriscv -T platform/linker.ld

OBJS    := $(BUILD)/crt.o $(BUILD)/platform.o $(BUILD)/demo.o

.PHONY: all hex clean

all: $(BUILD)/app.elf

$(BUILD)/app.elf: $(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILD)/crt.o: platform/crt.S | $(BUILD)
	$(AS) $(ARCH) -o $@ $^

$(BUILD)/platform.o: platform/platform.c platform/platform.h platform/sys_regs.h | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD)/demo.o: demo.c | $(BUILD)
	$(CC) $(CFLAGS) -c -o $@ $<

hex: $(BUILD)/app.elf
	$(OBJCOPY) -O binary -j .text -j .rodata -j .data $< $(BUILD)/app.bin
	python3 ../tests/bin2hex.py --bytes $(BUILD)/app.bin ../sim/app_flash.hex

$(BUILD):
	mkdir -p $(BUILD)

clean:
	rm -rf $(BUILD)