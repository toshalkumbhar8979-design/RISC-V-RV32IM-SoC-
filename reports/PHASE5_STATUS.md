# PHASE 5 — OpenLane 2 / SKY130 RTL→GDS Sign-Off (in progress)

**Status: TOOLING ~90% READY — RTL probe proven in Yosys; OpenLane image pull in
flight; first gate-data captured. Full P&R run pending image arrival.**

## Scope
Physical-design sign-off of `riscv_doom_soc` through the OpenLane 2 flow:
synthesis (Yosys) → floorplan/packing → placement (simulated-annealing) → CTS →
global + detailed routing → Magic DRC & Netgen LVS → KLayout-verified merged
`.gds`. The SoC's `clk`/`rst_n` and peripheral IO are ported; the flop-array
SRAM is reduced to `AW=9` (512 words) for the probe and re-entered as an
OpenRAM hard macro at production scale (32 KB).

## 1. Done this session (evidence)

- **Canonical v2 config keys** confirmed from the official docs
  (`docs/source/getting_started/newcomers/index.md`): the required set is
  `DESIGN_NAME`, `VERILOG_FILES` (`["dir::...", ...]`), `CLOCK_PERIOD`,
  `CLOCK_PORT`. `config.json` rewritten to that shape.
- **Self-contained RTL snapshot** in `open/designs/riscv_doom_soc/src/`
  (15 files; refreshed by `open/refresh_src.sh`), plus a `riscv_doom_soc` top
  (parameterized `SRAM_AW`) and `bootrom.hex` for `$readmemh`.
- **Yosys 0.65 full-design elaboration** (`PROBE_DONE rc=0`, 247 s, 792 MB):
  **33,105 cells / 1,064,960 memory bits**. Breakdown
  (`out/elaborate_stat.txt`): `sram_wrap` 32,770, `rv32_core` 136,
  `rv32_muldiv` 65, `qpspi_ctrl` 14, `spi_tft` 9, `uart_lite` 16,
  `rv32_timer_periph` 6, `rv32_regfile` 7, `bootrom` 2. RAM dominates; the
  RAM-less logic is ~330 synthetic cells.
- **Image tag discovery**: repo `pyproject.toml` says `version = "2.3.10"` and
  `openlane/__main__.py` builds the image name as
  `ghcr.io/efabless/openlane2:{__version__}`. So the correct pull is
  `ghcr.io/efabless/openlane2:2.3.10`, which IS public (anonymous pull
  accepted; auth only applies to the `latest` tag).
- Docker daemon verified healthy: `docker pull hello-world` completes in ~0.5 s.

## 2. Remaining gap

- The OpenLane image pull (multi-GB) was still in flight at session end. The
  actual OpenLane 2 run (synthesis → P&R → STA → DRC/LVS → GDS) takes 30+ min
  and cannot complete inside this sandbox's short-lived shells; the harness
  kills commands that run silently past ~30 s, and the image hadn't landed.
- The pip route remains unavailable on this box: `pip install -e openlane2`
  dies building `libparse` (sdist-only, `make patch`) under Python 3.13.12; the
  Kali apt mirror carries no py3.11/3.12 fallback.

## 3. How to finish

1. `docker pull ghcr.io/efabless/openlane2:2.3.10` (public pull).
2. `bash open/run_openlane.sh docker` → runs the v2 config inside the image,
   writing `runs/` under the design dir. (pip route: conda py3.11 venv,
   `pip install -e ~/openlane2`, then `openlane ...`.)
3. Acceptance list:
   - Yosys cell count / area vs Phase-1 row (RAM-less probe ≈ 33 k cells above).
   - OpenSTA stack vs the 20 ns clock — Fmax against the Phase-3 playable tile.
   - Magic DRC (no ERR/CRT), Netgen LVS ≥ 98 %, KLayout .gds audit.

## 4. Files

- `open/install_openlane.sh` — clone/venv/pip/volare installer (pip step
  blocked on libparse/py3.13).
- `open/run_openlane.sh` — docker & pip invocations + artifact dump.
- `open/probe.sh` + `open/designs/riscv_doom_soc/out/elaborate_stat.txt` —
  the Yosys-0.65 capture above.
- `open/refresh_src.sh` — syncs rtl/ into the self-contained design snapshot.
- `open/designs/riscv_doom_soc/config.json` — canonical v2 config (draft).
- `open/pip.log` — libparse build failure evidence.