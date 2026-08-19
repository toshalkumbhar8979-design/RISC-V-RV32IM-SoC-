# Phase 3 — Status Report (Software stack + doomgeneric platform layer)

**Date:** 2026 · **State: COMPLETE (core milestone) / engine integration OPEN.**

## Toolchain (verified)
```
riscv64-unknown-elf-gcc -march=rv32im_zicsr -mabi=ilp32 \
    -Os -ffreestanding -fno-builtin -fno-stack-protector -nostdlib ...
riscv64-unknown-elf-as  -march=rv32im_zicsr -mabi=ilp32
riscv64-unknown-elf-ld  -m elf32lriscv -T <linker>
riscv64-unknown-elf-objcopy -O binary
```
`sw/Makefile` builds `sw/build/app.bin` → `sim/app_flash.hex` for the SoC TB.
Secret: this freestanding GCC ships no libc headers — `platform.h` self-defines the few
typedefs used (honest note).

## Software components (all in `sw/`)
| Item | File | Notes |
|---|---|---|
| start-up | `platform/crt.S` | zero .bss, set sp (top of SRAM), call main |
| linker | `platform/linker.ld` | Phase-0 map: image at 0x0001_0000; heap after bss; 4 KB stack at top (0x18000) |
| register map | `platform/sys_regs.h` | UART / TFT / Timer addresses (matches RTL) |
| hal+bindings | `platform/platform.c/.h` | uart_putc/puts, mtime→millis, TFT cmd/data pump, DG_* doomgeneric callbacks |
| demo | `demo.c` | UART banner, TFT pattern, mtime sample, PASS mailbox |
| engine sources | `sw/doomgeneric/` | **doomgeneric vendored** (shallow git clone, ozkl/doomgeneric) — not yet compiled in this milestone |

## Verification (evidence)
```
$ make hex                      # cross-compile + image
wrote 635 bytes -> ../sim/app_flash.hex
$ (SoC TB with this app image)
FLASH->SRAM COPY: OK (64 words)
DISPLAY data bytes: de ad be ef  (cmds 28 2c)
DISPLAY pattern:  OK  (DE AD BE EF)
PCEND=00010040
TIMER IRQ + mailbox: OK (0x600DF00D)
SOC TEST: PASS
```
This proves: C **toolchain + crt0 + linker + HAL** produce a binary the SoC boots from SPI
flash, loads into SRAM and executes — the delivery vehicle for the doom port.

## Doom asset / memory budgets (explicit)
| Item | Size | Where it lives |
|---|---|---|
| shareware `doom1.wad` | ~4.2 MB | fits 8 MB PSRAM after boot copy |
| full `doom1.wad` | ~4.2 MB | fits PSRAM |
| `doom2.wad` | ~14.6 MB | **does not fit** 8 MB PSRAM → external flash XIP (slower) |
| code + data (.text/.bss/rodata) | >32 KB | on-die SRAM 32 KB holds stack/heap + caches ONLY (fits: engine ~200 KB must be PSRAM-resident) |
| logical framebuffer 320×200×8-bit | 64 KB | **external PSRAM** (on-die 32 KB SRAM is too small by design, Phase 0) |
| panel GRAM 320×240 RGB565 | — | the ILI9341 itself |

Flash part assumption: 8 MB QSPI flash (boot+WAD archive) + 8 MB QSPI PSRAM for the
logical fb / code / game data — stated in Phase 0 and re-affirmed.

## FPS forecast (to be resolved by Phase-4 measurement and Phase-5 STA)
- Core: 2-stage RV32IM, multi-cycle mul/div; estimated ~0.55–0.65 IPC.
- At the Phase-0 nominal clock 66 MHz → ≈36–43 MIPS (post-STA clock to be stated after Phase 5).
- Doom software renderer 320×200 (low detail) reference ≈ 18–30 MIPS.
- Forecast: **≈20–35 fps @320×200**, i.e. “playable at low detail, choppy”.
  This number is an engineering estimate, not a measurement. The Phase-4 FPGA bring-up is
  the committed gate where real fps is measured and documented, then Phase-5 STA fixes the
  final silicon clock.

## Honest open blockers for the next step (not hidden)
1. **doomgeneric engine integration**: sources are vendored; integrating them is an
   engineering task (freestanding stdio/math stubs, screen-less rendering path, and the
   64 KB framebuffer in the external PSRAM window which our Phase-2 SoC does not map yet).
2. A real `doom1.wad` (shareware, freely distributable) is needed for in-sim validation.
3. The Phase-3 software milestone can’t include a playable Doom until those two + FPGA
   proof are done — explicitly out of scope of this checkpoint.

Next actions: extend the SoC with the PSRAM window + a TFT pixel DMA (feeds the 64 KB
screen push), then wire doomgeneric against it, then Phase 4 FPGA.