# Cadence Import Plan — Phase 7 (gated on licensed tool)

**Status: PLAN ONLY. Executing requires a licensed Cadence environment
(Virtuoso/Innovus) which is NOT present on this host. Deliverable is the
stream-in recipe, so it runs in minutes once a license exists.**

## Goal
Open the OpenLane-produced GDS-II + LEF in Cadence Virtuoso for review/
sign-off: floorplan view, cell placement, routing, DRC/LVS in the Cadence
flow (Assura/PVS or Calibre via Virtuoso).

## Recipe (when licensed)
1. **Stream-in the GDS** — Virtuoso Layout XL:
   - `File → Import → Stream in`
   - File: `open/artifacts/riscv_doom_soc.gds`
   - Layer map: use the sky130 stream-out layer map
     (`$PDK/libs.ref/sky130_* .../streamout.map`) output map for top.
   - Import as `LIBRISCV_SOC` cell `riscv_doom_soc`
2. **Merge the std cell LEF/abstracts** — `??lef2ioa`? Actually: import the
   std-cell LEF from the PDK (`sky130_fd_sc_hd/sky130_fd_sc_hd__*.lef`), which
   gives abstracts for PnR views; or simply rely on the GDS polygons for
   layout view.
3. **Instantiate in a testbench** — a tiny Virtuoso schematic that instantiates
   `riscv_doom_soc' and runs:
   - DRC: Assura/PVS against sky130 rules (`sky130A.14_...` tech)
   - LVS: netlist vs GDS (import the nl.v/cdl from `runs/.../final/`)
4. **Screenshot + report** — export view(s) for the sign-off doc.

## Files in this repo already relevant
- `open/artifacts/riscv_doom_soc.gds` (42 MB) — full layout
- `open/artifacts/riscv_doom_soc.klayout.gds` — KLayout stream-out
- `runs/.../final/nl/riscv_doom_soc.nl.v` (netlist for LVS)
- `runs/.../final/lef/` — std abstract views
- PDK sky130 (volare) has the `sky130_fd_sc_hd` LEF + tech LEF for the
  import.

## Blockers / notes
- No Cadence license on this host (flag, not hidden).
- The toolkit's layer map must match the sky130 tech; both are open-source.

## Verification today (no Cadence)
- The GDS-II / LEF / DEF are already verified by Magic, KLayout, Netgen (Phase 5).
  Cadence becomes an independent cross-check plus a human-readable layout tool.