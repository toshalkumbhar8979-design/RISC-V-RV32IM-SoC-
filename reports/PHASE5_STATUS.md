# PHASE 5 — OpenLane 2 / SKY130 RTL→GDS Sign-Off (Tooling)

**Status: BLOCKED (environment). Probe config/scripts staged — runnable once
tooling is unblocked.**

## Scope
Physical-design sign-off of `riscv_doom_soc` through the OpenLane 2 flow:
synthesis (Yosys) → floorplan/packing → placement (simulated-annealing) → CTS →
global + detailed routing (TritonRoute/fast-router) → Magic DRC & Netgen LVS →
KLayout-verified merged `.gds`. The SoC's `CLK`/`rst_n` and peripheral IO are
ported; the flop-array SRAM is withdrawn from the probe and re-entered as an
OpenRAM hard macro at production scale (32 KB).

## 2. Blocked IN-SESSION (evidence)
- **Docker-image route**: `docker pull ghcr.io/efabless/openlane2:latest` →
  `manifest unknown`; registry requires auth (`HEAD .../manifests/latest` →
  "denied"; anonymous tag list → `UNAUTHORIZED`). The v2 image sits under a
  restricted ghcr org — needs Docker sign-in or a personal token plus tag
  discovery.
- **pip route** (`pip install -e openlane2`): fails building **libparse** (only
  an sdist ships) on the sole interpreter, Python 3.13.12 — libparse's
  `make patch` step doesn't support 3.13. Kali's apt offers no python3.11/3.12
  follow-up (`apt-cache policy` → both absent).
- Docker daemon itself is fine (docker 27.5.1, `docker ps` ok from WSL2 Kali).

## Unblock (any one)
1. **Docker login + tag**: sign into Docker Desktop (or use a personal GitHub
   token with `gh:read`), then pull `ghcr.io/efabless/openlane2:latest`; if
   versioned, discover tags via
   `curl -H "Authorization: Bearer <gh-token>" -H "Accept: application/vnd.docker.distribution.manifest.list.v2+json" https://ghcr.io/v2/efabless/openlane2/tags/list`
   and pull that tag.
2. **Older Python** (pip route): `conda create -n ol2 python=3.11`,
   `conda activate ol2`, then `pip install -e $HOME/openlane2`.
3. Swap to the **containerless/local** OpenLane install (all tools compiled
   locally; slow, no registry needed).

Then `sh open/run_openlane.sh pip` (or `open/run_openlane.sh docker`).

## Staged probe
- `open/designs/riscv_doom_soc/config.json` — OpenLane 2 v2 draft: AREA synth,
  core_util 0.5, die 600×400, `sky130_fd_sc_hd` SCL, STA clock period 20 ns
  (50 MHz floor; Phase-0 nominal is 66+, raise once STA reports critical-path
  slack). First P&R pass instantiates the top with the SRAM macro out
  (demo `AW=9`); production enters the 32 KB via the OpenRAM macro flow.
- `open/run_openlane.sh` — docker & pip invocations plus artifact dump.

## First-run acceptance (run these when unblocked)
- Yosys cell count + cell area vs. Phase-2 Pareto row (expect ≈ ≤55 k cells for
  the RAM-less probe).
- OpenSTA setup/hold slack → derive Fmax from the 20 ns clock, compare with the
  Phase-3 playability target.
- Magic DRC report (no ERR/CRT), Netgen LVS (matches% ≥ 98).
- KLayout walk of the final merged `.gds` (die, macro, routing sanity).

## Files
- `open/install_openlane.sh` — clone/venv/pip/volare installer (blocked step).
- `open/run_openlane.sh` — runnable once unblocked.
- `open/designs/riscv_doom_soc/config.json` — probe design config (draft).
- `open/pip.log` — failed libparse build evidence.