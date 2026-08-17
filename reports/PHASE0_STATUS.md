# Phase 0 — Status Report

**Date:** 2026-08-18 · **State:** COMPLETE (documents written into `docs/PHASE0_ARCHITECTURE.md`)

## Deliverables
1. Architecture document `docs/PHASE0_ARCHITECTURE.md` (block diagram, memory map, IO plan).
2. Area + pin budget (tables in the doc).
3. Track decision: **Track B** (RTL→GDS sign-off exercise; no physical submission).
4. Repo scaffold: `rtl/ rv32` `rtl/soc` `rtl/periph` `tb/` `tests/` `sim/` `docs/` `reports/` `fpga/` `open/`.

## What was verified (evidence)
- Environment: iverilog 12.0, vvp, GTKWave, verilator, riscv64-unknown-elf GNU toolchain, yosys/nextpnr-ecp5 targets all present in WSL2 (Kali); Docker Desktop running (needed for OpenLane 2 later).
- Feasibility numbers cross-checked: Doom ≈ 15–25 MIPS baseline vs 33–43 MIPS forecast @66 MHz — margin ≥1.3×, flagged as a Phase-4 measured gate.

## Hard blockers / scope changes
- None in Phase 0. Explicit scope notes: Tiny Tapeout 1 mm² tile rejected for the 32 KB SRAM (would force 8 KB); ILI9341 SPI display is the only display option (pin budget).

## Phase 0→1 hand-off
- Phase 1 (RV32IM core) started per the map in the architecture doc.