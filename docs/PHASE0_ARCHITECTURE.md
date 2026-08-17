# Phase 0 — Architecture & Feasibility Budget (`riscv_doom_soc`)

*Status: COMPLETE. Written before any RTL; the numbers below are the budget the build is committed to.*

## 0.1 Delivery target decision

**Track (B) selected.** FPGA-proven SoC first, then OpenLane 2 / sky130 `sky130_fd_sc_hd`
hardening as a **full RTL→GDS signoff exercise**: synthesis → floorplan → placement → CTS →
routing → STA → DRC (Magic) → LVS (Netgen) → merged GDS (KLayout). **No physical fab
submission is assumed** (user did not confirm paying for a shuttle).
Consequences stated *up front* (no silent scope reduction):

- **Phase 6 (pad ring)** cannot be drawn without a specific carrier's fixed pad frame —
  replaced by a pad-ring plan document; re-opened only on explicit Track-A confirmation.
- **Phase 7 (Virtuoso import)** — SKILL + stream-in + layer-map deliverable is produced,
  but executing it requires a licensed Cadence environment (not present on this host);
  that requirement is flagged, not hidden.
- Everything before those two steps is executed in full, with tool-run evidence.

## 0.2 Block diagram

```
                 riscv_doom_soc — single 32-bit clock domain, async-active-low reset

 ┌───────────┐   ┌──────────────────────────────────────────────────────────┐
 │ RV32IM     │   │ Wishbone-lite (single master, 32b addr / 32b data)       │
 │ 2-stage    │   │  0x0000_0000 BootROM   4KB (logic ROM)                   │
 │ pipeline   │◄──┤  0x0001_0000 On-chip SRAM 32KB (OpenRAM 1RW macro)       │
 │ (M ext)    │──►│  0x1000_0000 QSPI-PSRAM window (8MB, reads via page-     │
 └───────────┘   │             buffer + small D$/I$ caches)                 │
                 │  0x2000_0000 QSPI-flash XIP window                        │
                 │  0x4000_0000 QSPI mem-controller regs                     │
                 │  0x4001_0000 SPI-TFT (ILI9341) ctrl + pixel DMA           │
                 │  0x4002_0000 UART                                         │
                 │  0x4003_0000 Timer mtime/mtimecmp + IRQ->PLIC            │
                 └───────────────┬────────────────────────────────────────┐
                                 │                                        │
   ┌─────────────────────────────┴──────────────┐    ┌────────────────────┴───────┐
   │ QSPI mem ctrl (flash+PSRAM, page-buffer,   │    │ SPI-TFT DMA                  │
   │ cmd sequencer, ready-stall)                │    │ init-sequence FSM,          │
   └─────────────────────────────┬──────────────┘    │ dirty-rect pixel push       │
                                 │                    └────────────────────────────┘
  ┌────────────────┐   ┌─────────────────────┐
  │ W25Q128 (flash)│   │ APS6406/PSRAM 8MB    │        ILI9341 320x240 TFT (GRAM =
  │ boot+WAD archive│   │ code+data+logical FB │        the display framebuffer, on-panel)
  └────────────────┘   └───────────────────┘
```

### 0.2.1 Memory ownership rules (on-die vs off-die)
- **On-die SRAM: exactly 32 KB**. Stack/heap/scratch only. Doom's box-S 320×200 8-bit
  render target (64 KB) is **not** on die.
- **Flight 2** deliberately leaves **no** multi-MB RAM on die — the PSRAM holds the
  logical 8-bit framebuffer and game code/data; the TFT's own GRAM is the display
  framebuffer. The SoC pushes *changed* spans over SPI (dirty-rect transport).
- BootROM is logic (synthesized), not a macro.

## 0.3 Area budget (sky130_fd_sc_hd, estimates, refine later with synthesis)

| Block | ~Gates | ~Area (routed, 50% util) |
|---|---|---|
| RV32IM core (2-stage + M unit + CSR) | ~25–35 kgates | 0.20–0.35 mm² |
| Bus fabric + PLIC glue + replay logic | ~6 kgates | 0.05 mm² |
| QSPI ctrl (flash+PSRAM) + 4KB I$ / 8KB D$ caches | ~10 kgates | 0.10 mm² |
| SPI-TFT engine + palette LUT | ~3 kgates | 0.03 mm² |
| UART + mtime | ~2 kgates | 0.02 mm² |
| On-chip SRAM macro 32KB (OpenRAM sky130) | — | ~0.25–0.35 mm² |
| **Total** | ~50–60 kgates | **~1.0–1.4 mm²** |

Shuttle-class verdict: fits a 1.5–3.0 mm² tile with 38 usable IO. A 1 mm² tile would force the
SRAM down to ≤8 KB — judged insufficient for Doom's stack+heap — so **ChipIgnite/Caravel-class
tile (or larger) is the realistic track**; Tiny Tapeout 1 mm² is a hard scope cut.

## 0.4 Pin budget (user IO)

| Function | Pins |
|---|---|
| QSPI flash + PSRAM (shared bus) | SCK, DQ[3:0], CS0, CS1 (7) |
| ILI9341 TFT (SPI) | CS, SCK, MOSI, DC, RST (5) |
| UART | 2 |
| JTAG | 4 |
| EXT_CLK / EXT_RST | 2 |
| BOOT strap | 1 |
| **Total** | **~21–22** |

All within the 38-user-IO class. Power/GND separate.

## 0.5 Clock / performance feasibility (numbers used to size everything)

- Nominal SoC clock 66 MHz (15 ns), refined via PHASE 5 STA; Phase 4 FPGA fmax stays ceiling.
- 2-stage core: ≈1 IPC on straight-line code, ≈0.55–0.65 average → 33–43 MIPS @66MHz.
- Doom baseline ≈ 15–25 MIPS for 320×200 @35 fps → **feasible with margin ≥1.3×; Phase 4 gate**.
- DSP/BW worst cases: dirty-pixel push 320×200×2×35 = 4.5 MB/s ≤ SPI@40MHz; PSRAM reads ≤ 40 MB/s.

## 0.6 Toolchain & flows (what this environment uses)

- Simulation: iverilog 12.0 + GTKWave (WSL2 Kali). Assembler: riscv64-unknown-elf (rv32im/zicsr).
- ASIC (phase 5): OpenLane 2 Docker + volare sky130B; OpenRAM macro for the SRAM.
- FPGA (phase 4): yosys + nextpnr-ecp5 (+ trellis) for ECP5 (Colorlight-i5 class).

## 0.7 Phase-0 review notes

- Delivery target: **Track B** (full RTL→GDS sign-off exercise; no physical fab submission).
- The multi-MB memory is external (flash + PSRAM); the on-die SRAM is 32 KB (stack/heap/caches).
- Display outline is SPI-to-ILI9341 with the panel GRAM as the display framebuffer.