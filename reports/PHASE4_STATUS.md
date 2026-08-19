# Phase 4 — FPGA Bring-Up (Track B validation gate)

**State: BLOCKED (tooling ready; on-board validation impossible in this environment).**

## What is ready (real Open-Source ECP5 flow, installed & scripted)
| Tool | Purpose | Status |
|---|---|---|
| yosys 0.65 (`synth_ecp5`) | synthesis | installed |
| nextpnr-ecp5 0.10 + chipdb-25k | placement & routing | installed |
| fpga-trellis (ecppack) | bitstream packing | installed |
| fpga-trellis-database | ECP5 bitstream DB | installed |
| openFPGALoader | flash/board loading | **not packaged in Kali**; Ubuntu PPA provides it (see README) |

Flow scripts: `fpga/ecp5/{soc.ys, runner.sh, launch.sh, syn.sh, run_fast.sh, riscv_doom_soc.lpf, src/top_riscv_ecp5.v}`.
Board target: Lattice ECP5 (**LFE5U-25F** − e.g. Colorlight-i5 line), on-board 25 MHz oscillator + SPI
flash + goldfinger/PMOD breakout for the SPI TFT and external SPI PSRAM/flash.

Standard run (once the BRAM refactor is done):
```
sh fpga/ecp5/runner.sh syn        # yosys -s soc.ys → riscv.json
sh fpga/ecp5/runner.sh pnr        # nextpnr-ecp5 --25k ... → riscv.config
sh fpga/ecp5/runner.sh bit        # ecppack → riscv.bit
# on hardware (Ubuntu host): openFPGALoader -c colorlight-i5 riscv.bit
```

## The hard blocker (why the flow can’t complete today, stated plainly)
The SoC’s 32 KB `sram_wrap` uses **asynchronous (combinational) reads**. On an FPGA, Yosys
is forced to flatten the array into flip-flops: **8192 words × 32 bit = 262,144 registers**,
which exceeds the ECP5-25F’s ~48 k FF budget and makes synthesis extremely slow/impractical.
This is not a tool bug — it is the textbook reason why ASIC-style SRAM ports need a FPGA
BRAM wrapper.

**Required SoC refactor (the actual Phase 4 gate):**
```
rtl/periph:  add fpga/sram_dp_sync.v  — synchronous-read dual-port BRAM instance
             (ECP5 EBR: $mem with write-sync + registered-read, size adjustable)
riscv_soc.v: use the sync wrapper; grant the core one extra cycle for reads
             (the core already stalls on `dmem_grant` — caches/reads simply become
             1-cycle; the existing stall path makes this mechanical)
tb:          rerun `make -C sim soc` with the sync wrap (expected PASS identical)
```

## Why on-chip validation can’t be claimed in this environment
The brief’s gate — *“it actually runs Doom on a real board, measured”* — requires an ECP5
board and a TFT/PSRAM/flash bench. **There is no physical hardware attached to this machine.**
No amount of synthesis proves runtime behaviour; I’ll only claim the FPGA gate after a real
board has been run and FPS documented, as the brief mandates.

## Concrete step order (this is the plan for when hardware/tooling is available)
1. Sync-BRAM sram wrap + core dmem-latency hook (describe above) → re-verify in simulation.
2. Run runner.sh syn→pnr→bit, capture LUT/FF/fmax numbers.
3. Load to colorlight-i5 (or ULX3S-25F) via openFPGALoader; wire colour TFT + PSRAM/flash.
4. Boot smoke → UART text → TFT pattern → Doom fps measurement; record numbers in this report.
5. Only then Phase 5 (OpenLane 2 signoff) begins.

## Environment notes
- Yosys/nextpnr/ecppack verified present (apt). `openFPGALoader` install command for Ubuntu:
  `sudo apt install openfpgaloader` (or build from source).
- The WSL 30s-tool-cap means long synthesis runs must be started detached (`launcher.sh`).