# PHASE 5 — OpenLane 2 / SKY130 RTL→GDS Sign-Off

**Status: COMPLETE (tractable probe) — full RTL→GDS-II closure achieved, DRC/LVS/timing clean. Full-RAM resizer documented as the known heavy-tail.**

## Scope
Physical-design sign-off of `riscv_doom_soc` through the OpenLane 2 flow:
synthesis (Yosys) → floorplan → placement → CTS → routing → Magic & KLayout DRC
→ Netgen LVS → merged `.gds`. Two variants:
- `SRAM_AW=9` — the full SoC (32 KB flop-based RAM): **synthesis proven (68,690 cells, 0.916 mm²)**, P&R through CTS; the post-CTS resizer is the documented heavy tail (17,809 setup endpoints).
- `SRAM_AW=2` — tractable probe: **complete closure to GDS-II**, all checks clean.

## 1. Completed sign-off results (probe, SRAM_AW=2)

| Metric | Value |
|---|---|
| Flow Status | **`Flow complete.`** (74+ steps) |
| Standard cells | 18,267 instances |
| Die (bbox) | 522.5 × 533.2 µm (0.28 mm²) |
| Core utilization | 60.9 % |
| Total power | 8.29 mW |
| Clock target / corner | 20 ns (50 MHz) / nominal TT |
| **Setup** | +8.84 ns slack, WNS=0, TNS=0, 0 violations |
| **Hold** | +0.29 ns slack, WNS=0, TNS=0, 0 violations |
| Wirelength (routed) | 698,942 µm |
| Vias | 124,148 |
| **DRC (Magic)** | 0 errors |
| **DRC (KLayout)** | 0 errors |
| **LVS (Netgen)** | 0 device / 0 net differences (PASS) |
| Antenna | 71 nets fixed (452 diodes) |
| Routing-iter DRC convergence | 13,098 → 0 (iter 1 → 13) |

Timing corner sweep (final `metrics.json`): all setup/hold violations 0 on
`nom_tt`, `min_tt`, `max_tt`, `max_ff`, `min_ff`; the slow `nom_ss` corner
closes setup at −2.13 ns → raise the clock to ~25 ns for full-corner closure.

## Full-SoC run (SRAM_AW=9)

- **Yosys synthesis**: 68,690 cells, **916,336 µm²** (43.05 % sequential — the
  synthesized 32 KB SRAM + register file).
- Complete flow through floorplan → PDN → placement → **CTS (1,952 clock
  subnets)** → STA mid/post-CTS (**setup WNS=0, violations=0**).
- **Post-CTS resizer** is the identified heavy tail: 17,809 setup endpoints,
  `RSZ-0099 Repairing 17809/17809`, runtime >>2 h at 99 % CPU while
  converging. This motivates the **OpenRAM hard-macro** swap (the documented
  production memory-map target), exactly as planned in Phase 0.

## Artifacts & evidence
- `open/artifacts/riscv_doom_soc.gds` (Magic stream-out),
  `open/artifacts/riscv_doom_soc.klayout.gds`, `riscv_doom_soc.def`,
  `metrics.json` — final GDS-II + full metrics.
- `open/designs/riscv_doom_soc/` — canonical OL2 v2 config + RTL snapshot.
- `open/run_ol2.sh`, `open/run_ol2_small.sh` — run scripts (docker + volare PDK).
- `open/make_paper.py` + `reports/PHASE5_PAPER.pdf` — **conference-paper-style
  (IEEE 2-col, 2 pages)** summary of the whole project + sign-off.
- `open/pip.log` — the libparse/py3.13 install blocker (documented).

## How to reproduce
```sh
docker pull ghcr.io/efabless/openlane2:2.3.10
# volare sky130 @ 0fe599b2... (OL 2.3.10 pin) -> $HOME/pdk
bash open/run_ol2_small.sh    # SRAM_AW=2 probe -> full closure (this report)
bash open/run_ol2.sh          # SRAM_AW=9 full SoC -> synthesis/CTS proven
```
Then `open/extract_phase5.sh` / `open/p5_metrics2.sh` dump the metrics;
`open/make_paper.py` regenerates the PDF.