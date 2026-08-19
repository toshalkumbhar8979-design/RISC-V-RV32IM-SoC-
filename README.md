# riscv_doom_soc

RISC-V SoC (RV32IM) targeting SKY130 `sky130_fd_sc_hd`, tapeout-eligible RTL→GDS, with a
doomgeneric port. **Track B** — FPGA-proven first, then OpenLane 2 hardening as a sign-off
exercise (no physical fab submission assumed).

## Phases

| Phase | Status | Deliverables |
|---|---|---|
| 0 Architecture & budget | ✅ | `docs/PHASE0_ARCHITECTURE.md`, `reports/PHASE0_STATUS.md` |
| 1 RV32IM core + M + TBs | ✅ | `rtl/rv32/*.v`, `tb/tb_rv32.v`, `tb/tb_muldiv.v`, `tests/smoke.S`, `reports/PHASE1_STATUS.md` |
| 2 SoC integration | ✅ | `rtl/soc/*.v`, `rtl/periph/*.v`, bootloader+app (`tests/boot.S`,`app.S`), `tb/tb_soc.v`, `reports/PHASE2_STATUS.md` |
| 3 doomgeneric port (platform) | ✅ core / ⏳ engine | `sw/` (crt0, linker, platform hal + DG_* bindings, C demo → **SOC PASS**), doomgeneric vendored: `sw/doomgeneric`, `reports/PHASE3_STATUS.md` |
| 4 FPGA bring-up | ⏳ | — |
| 5 OpenLane 2 sign-off | ⏳ | — |
| 6 Pad ring | ⏳ (Track-A gated) | — |
| 7 Cadence import | ⏳ | — |

## Memory map (target, locked in Phase 0)

- `0x0000_0000` BootROM (4 KB logic)
- `0x0001_0000` On-chip SRAM 32 KB (OpenRAM macro)
- `0x1000_0000` QSPI-PSRAM window 8 MB (code+data+logical framebuffer)
- `0x2000_0000` QSPI-flash XIP window
- `0x4000_0000` QSPI controller regs
- `0x4001_0000` SPI-TFT (ILI9341) + pixel DMA
- `0x4002_0000` UART
- `0x4003_0000` Timer (mtime/mtimecmp) + IRQ

## Requirements

- WSL2 (Kali or any Debian-family) with: `iverilog 12+`, `gtkwave`,
  `gcc-riscv64-unknown-elf` (+ binutils), `python3`.
- Docker Desktop (later phases: OpenLane 2 image).

## Build & run (inside WSL2)

```sh
cd /mnt/c/Users/tosha/Downloads/RiscV
make run            # (from root: delegates) Phase-1 core smoke  -> RESULT: PASS
make -C sim waves   # GTKWave on sim/smoke.vcd
make -C sim soc     # Phase-2 SoC end-to-end                    -> SOC TEST: PASS
make -C sim qspi    # QSPI engine unit test                     -> QSPI UNIT TEST: PASS
```

Expected output:
```
RESULT: PASS   mailbox=0x600df00d irq_count=1 commits=1107
```

Unit test for the M-extension engine:
```sh
iverilog -g2005 -I rtl/rv32 -o /tmp/md.vvp rtl/rv32/rv32_muldiv.v tb/tb_muldiv.v
vvp /tmp/md.vvp    # -> MULDIV UNIT TEST: PASS
```

## RTL layout

```
rtl/rv32/             core (Phase 1)
rtl/soc/              SoC glue + boot ROM (Phase 2)
rtl/periph/           UART/timer/QSPI/TFT (Phase 2)
tb/                   iverilog testbenches
tests/                RISC-V asm bootloader/app + bin2hex.py
sw/                   Phase-3 software: crt0, linker, platform HAL,
                      demo, vendored doomgeneric
sim/                  Makefile, vcds, trace
docs/ reports/        docs and phase status reports
```