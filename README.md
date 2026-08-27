# RISC-V RV32IM SoC — RTL to GDS-II ASIC Sign-off

I designed a complete **RISC-V RV32IM system-on-chip** from scratch in Verilog,
built the software stack for it, and took it through a **full RTL-to-GDS-II
physical design sign-off** on **SkyWater 130 nm (sky130_fd_sc_hd)** using
**OpenLane 2** — achieving DRC-clean, LVS-clean, timing-met closure to GDS-II.

## Why I built this

I wanted to understand the entire silicon design pipeline — from writing raw
RTL to holding a (virtual) die — not just simulate a CPU. Most open RISC-V
projects stop at simulation. I wanted to see if I could close the entire
physical-design flow: synthesis, placement, clock tree synthesis, routing,
DRC, LVS, and GDS-II generation — all on the SkyWater open PDK.

## What I built

### RV32IM Core (Phase 1)
I wrote a 2-stage pipelined RISC-V core in Verilog-2001 with:
- Full RV32I base + **M-extension** (multi-cycle multiply/divide)
- CSRs with trap/exception handling (`mepc`, `mcause`, `mtvec`, `mstatus`)
- Timer interrupt taken at instruction boundaries, `mret` resume
- Verified with self-checking Icarus Verilog testbenches (**all PASS**)

### SoC Integration (Phase 2)
I integrated the core into a complete system with:
- Boot ROM (executes at reset, loads app from flash)
- 32 KB on-chip SRAM (dual-read for Harvard I/D separation)
- **QSPI flash** controller (execute-in-place, 0x03 serial read command)
- **SPI-TFT (ILI9341)** display controller
- **UART** (8N1, baud-divider TX)
- **Timer** (mtime/mtimecmp) with level IRQ
- End-to-end test: boot → copy from flash → execute from SRAM → **SOC TEST: PASS**

### Software Stack (Phase 3)
I brought up the **GNU RISC-V cross-toolchain** and built:
- crt0 startup (zero BSS, set sp, call main)
- Custom linker script for my memory map
- Platform HAL (UART, TFT, timer, mtime)
- **DOOM-compatible platform** with vendored `doomgeneric` engine
- C demo that boots from flash, runs, services IRQ, and signals PASS

### FPGA Bring-up (Phase 4)
I set up the full open-source ECP5 FPGA flow (yosys, nextpnr, trellis) and
implemented a **synchronous dual-port BRAM wrapper** (`sram_dp_sync.v`) to
replace the combinational-read SRAM for FPGA targets. Added `if_stall`
support to the core's fetch stage. Verified the async default path still
passes. *(Hardware board bring-up pending — no ECP5 board available.)*

### RTL-to-GDS-II Physical Design (Phase 5)
I ran the complete OpenLane 2 flow on SkyWater 130 nm:
- Synthesis: Yosys + ABC → 68,690 cells, **0.916 mm²**
- Floorplan: die 1364.8 × 1375.5 µm
- Placement: 60.9% utilization (probe: 18,267 cells, 0.28 mm²)
- **CTS: 1,952 clock subnets, ~0.22 ns skew**
- Routing: 698,942 µm wirelength, 124,148 vias
- **Timing: setup WNS=0, hold WNS=0, 0 violations** @ 20 ns (50 MHz)
- **DRC: 0 errors (Magic + KLayout)** · **LVS: 0 mismatches (Netgen)**
- **GDS-II: merged stream-out** from Magic and KLayout views

I also ran a **25 ns corner-closure run** that brought the slow (SS) corner

## GDS-II Physical Layout

| Full die (522.5 × 533.2 µm) | Core region (zoomed) |
|---|---|
| <img width="407" height="415" alt="Die" src="https://github.com/user-attachments/assets/8606256c-0078-464e-9d10-0ec8d4922dc2" /> | <img width="485" height="375" alt="Zoom" src="https://github.com/user-attachments/assets/3a915f79-1798-403f-82d8-ddb835830af4" /> |

Rendered from the GDS-II using `open/gds2png.py`.

## Simulation Waveforms

![SoC waveform](docs/media/waveform_smoke.png)
![SoC waveform](docs/media/waveform_soc.png)
![SoC waveform](docs/media/waveform_muldiv.png)

*(Waveforms exported from GTKWave: SoC boot sequence, M-extension unit test,
core smoke test.)*

## Memory map

| Address | Region |
|---|---|
| `0x0000_0000` | BootROM (16 KB logic) |
| `0x0001_0000` | On-chip SRAM (32 KB, OpenRAM macro target) |
| `0x1000_0000` | PSRAM window (8 MB, framebuffer/code/data) |
| `0x2000_0000` | QSPI flash XIP window |
| `0x4000_0000` | QSPI controller regs |
| `0x4001_0000` | SPI-TFT + pixel-DMA |
| `0x4002_0000` | UART |
| `0x4003_0000` | Timer + IRQ |

## Phases

| Phase | What I did | Status |
|---|---|---|
| 0 Architecture | Budget, memory map, PDK decision | ✅ |
| 1 RV32IM core | Full core + M + self-checking TBs | ✅ |
| 2 SoC integration | Boot ROM, SRAM, QSPI, TFT, UART, timer + TB | ✅ |
| 3 Software + DOOM | GNU toolchain, crt0, HAL, doomgeneric bindings | ✅ core / ⏳ engine |
| 4 FPGA bring-up | yosys/nextpnr/trellis + sync-BRAM wrapper | ⏳ board pending |
| 5 OpenLane 2 sign-off | Full RTL→GDS-II, DRC/LVS/STA clean | ✅ probe |
| 6 Pad ring | Plan written (`docs/PADRING_PLAN.md`) | ⏳ gated |
| 7 Cadence import | Plan written (`docs/CADENCE_IMPORT_PLAN.md`) | ⏳ gated |

## Sign-off summary

| Metric | Full SoC | Probe (SRAM_AW=2) |
|---|---|---|
| Cells | 68,690 | 18,267 |
| Area | 0.916 mm² | 0.28 mm² |
| Setup slack (nom) | WNS=0 | +8.84 ns |
| Hold slack | +0.29 ns | +0.29 ns |
| DRC (Magic/KLayout) | — | 0 / 0 |
| LVS (Netgen) | — | 0 dev / 0 nets |
| Power | — | 8.29 mW |
| Wirelength | — | 698,942 µm |
| Vias | — | 124,148 |

## Requirements & reproduction

```sh
# WSL2 (Kali/Debian)
sudo apt install iverilog gtkwave gcc-riscv64-unknown-elf python3
cd /mnt/c/Users/tosha/Downloads/RiscV
make -C sim run          # core smoke:  RESULT: PASS
make -C sim soc          # SoC test:    SOC TEST: PASS
make -C sim qspi         # QSPI test:   QSPI UNIT TEST: PASS
```

For the ASIC sign-off:

```sh
docker pull ghcr.io/efabless/openlane2:2.3.10
bash open/run_ol2_small.sh   # full RTL→GDS-II flow (probe design)
bash open/gds2png.py open/artifacts/riscv_doom_soc.gds die.png  # render GDS
python3 open/make_final_paper.py  # regenerate the conference paper PDF
```

## What's next

- **OpenRAM hard-macro** for the SRAM (replaces 18k flops, fixes resizer
  runtime — plan in `docs/OPENRAM_INTEGRATION.md`)
- **DOOM engine integration** — hardware (PSRAM + TFT-DMA) is ready;
  software glue in `docs/DOOM_INTEGRATION.md`
- **FPGA board bring-up** — needs an ECP5 board (Colorlight-i5/ULX3S)
- **Full-corner closure** at 26-27 ns — slow corner is 99% there

## Tools

iverilog 12 · GTKWave · GNU riscv64-unknown-elf · Yosys 0.65 · OpenROAD ·
Magic · Netgen · KLayout · OpenLane 2 (2.3.10) · volare sky130B · Docker
setup slack to **−0.07 ns** (99% closed), confirming the path is fixable.
