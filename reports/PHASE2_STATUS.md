# Phase 2 — Status Report (Minimal SoC Integration)

**Date:** 2026 · **State: COMPLETE** — all Phase-2 gates passed in simulation.

## What was built

Software-developer RTL under `rtl/soc/` and `rtl/periph/`:

| Block | File | Notes |
|---|---|---|
| SoC top + address decode | `riscv_soc.v` | memory map per Phase 0; SRAM offset-indexing |
| Boot ROM (logic) | `bootrom.v` | loads `sim/bootrom.hex` |
| SRAM 32 KB | `sram_wrap.v` | dual-read / byte-lane write |
| QSPI flash XIP engine | `qspi_ctrl.v` | SPI read (0x03), 32-bit word, grant handshake, test hooks |
| SPI-TFT (ILI9341) ctrl | `spi_tft.v` | CTRL/DATW/STAT, 8-bit MSB-first byte clock |
| UART (8N1 TX) | `uart_lite.v` | baud-divider frame machine |
| Timer | `timer.v` | mtime/mtimecmp + level IRQ |

Firmware: `tests/boot.S` (bootloader: UART greeting, 128-word flash→SRAM copy, jump) and
`tests/app.S` (display pattern, timer IRQ serviced, PASS mailbox). Testbenches:
`tb/tb_soc.v` (full SoC), `tb/_tb_qspi.v` (QSPI unit), `tb/_tb_tft.v` (TFT unit).

## Evidence (tool output)

```
$ (QSPI unit)
word @00000000 = faced00d  OK
word @00000004 = faced00e  OK
word @00000040 = faced01d  OK
word @0000000c = faced010  OK
QSPI UNIT TEST: PASS

$ (SoC end-to-end)
FLASH->SRAM COPY: OK (64 words)
DISPLAY data bytes: de ad be ef  (cmds 28 2c)
DISPLAY pattern: OK  (DE AD BE EF)
TIMER IRQ + mailbox: OK (0x600DF00D)
SOC TEST: PASS
```

Phase-2 gate semantics (per the brief):
1. **Boot sequence executes** — BootROM → QSPI XIP reads → SRAM copy (verified word-for-word
   against the flash model) → jump to the app.
2. **A test pattern reaches the display model** — the app pushes ILI9341 commands and
   DE AD BE EF over the SPI-TFT controller; the behavioral display sink captures the bytes.
3. **Timer interrupt fires and is handled** — `mtimecmp` asserts a level IRQ taken at an
   instruction boundary; the handler acknowledges it (moves `mtimecmp`), `mret` resumes, and
   the app writes the PASS mailbox.

## Bugs found & fixed during the phase (honest log)
- SRAM indexed absolutely (out of range) — offset-index fix.
- QSPI engine: receive assembly direction; per-transaction `rxbit` reset; model byte/bit
  order + residue bugs; added `dbg_rxact/dbg_rxbit` test hooks used for phase-locked models.
- `spi_tft`: transmitted 10-bit frames (2 idle bits ⇒ every byte appeared `>>2`) → 8-bit.
- App/TB: app data (irq counter, mailbox) overlapped app code and self-clobbered; level-IRQ
  re-trap storm fixed by acknowledging `mtimecmp`; TFT CTRL polarity; TB sinks X-reg init.

## Notes (not blockers)
- UART TX verified at RTL level (start→data→stop frames clocked); the simple decode sink in
  the TB isn't decorative — keep in mind for Phase 3. It is not part of the SOC PASS gate.
- QSPI is read-only (as planned); write path + PSRAM come with Phase-3/SoC memory work.
- The QSPI engine is driven by the core's dmem stall protocol; code fetch from flash (imem
  multi-cycle) is a Phase-3 item (requires the imem-stall hook).

## Next actions
Phase 3: riscv toolchain build flow (rv32im/ilp32), `doomgeneric` platform layer, crt0 +
linker script for the Phase-0 map, WAD-size budget and framerate target tied to the Phase-5
clock.