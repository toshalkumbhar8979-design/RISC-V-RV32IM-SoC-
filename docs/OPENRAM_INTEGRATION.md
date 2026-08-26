# OpenRAM Integration Plan — full-SRAM sign-off closure

**Status: plan + behavioral wrapper committed (`rtl/soc/openram_wrap.v`); macro generation gated on the OpenRAM tool + PDK, which are available but not run here to keep the verified baseline clean.**

## Why (the problem)
The 32 KB flop-based `sram_wrap` (33,105 cells; 18,185 sequential in the
placed design) drives the OpenLane post-CTS resizer to 17,809 setup
endpoints. That is the **dominant runtime** and the reason the whole SoC does
not reach final 0-slack GDS closure in reasonable time, while the small-RAM
probe does. A hard SRAM macro removes thousands of flops, slashing resizer
work and improving area/timing/power.

## What to do (exact steps)

### 1. Generate the macro with OpenRAM
```sh
python3 OpenRAM.py --outdir $OL/designs/riscv_doom_soc/sram \
  --tech_name scn3me_subm --process_corners tt --supply 1.80 \
  --num_rw_ports 1 --num_r_ports 1 --num_w_ports 0 \
  --words 8192 --word_size 32 --recompute_corners
```
Produces `sky130_sram_1rw1r` + `sky130_sram_1rw` GDS/LEF/lib/verilog + a
`.lib` timing file. (Alternatively use the pre-built SkyWater SRAM macros in
the PDK: `sky130_sram_1rw1r_32x1024` / `32x8192` under
`sky130B/libs.ref/sky130_sram_macros`.)

### 2. Instantiate the macro
Replace the generated-code stand-in body in `openram_wrap.v` with the
OpenRAM instance (same port map: 1RW port + 1R port). Instantiate
`openram_wrap` in `riscv_soc.v` behind a `USE_OPENRAM` parameter:
```verilog
parameter USE_OPENRAM = 0
...
if (USE_OPENRAM) begin : g_ram
  openram_wrap #(.AW(SRAM_AW)) u_sram (...);
end else begin ... existing sram_wrap/sram_dp_sync ...
end
```
Because `openram_wrap` reads are registered (1-cycle), reuse the exact
`g_u_sram` grant adaptation already added for the sync path.

### 3. Point OpenLane at the macro
- Add `MACROS`: the macro LEF in config (`LIB_FILES`, `MACRO_PLACEMENT_*`
  or use `--run-macro-placement`), and list the macro's `.lef`/`.lib` in
  `config.json`.
- OpenLane 2 supports hard macros via `MACROS` variable in `config.json`.
- Then run `bash open/run_ol2.sh` — the resizer now sees ~1000 flops, not
  18,185, so it converges quickly and the full SoC closes.

### 4. Expected effect
| Metric | Flop-based (measured) | OpenRAM macro (expected) |
|---|---|---|
| Sequential cells | 18,185 | ~1 k (SDFFCTL only) |
| Post-CTS resizer endpoints | 17,809 | < ~2,000 |
| Resizer runtime | >>1 h | minutes |
| Cell area / power | 0.92 mm2 / 8.3 mW (probe) | lower (macro is dense) |

## Reference
- OpenRAM: https://github.com/VLSIDA/OpenRAM
- PDK SRAM macros baked into volare sky130 (already pulled):
  `pdk/volare/sky130/versions/0fe599b.../sky130B/libs.ref/sky130_sram_macros`

## Verification after swap
Rerun `make -C sim soc` (async) — expect identical `SOC TEST: PASS` since the
macro is a 1-cycle-read drop-in; then the full OL2 run closes without the
resizer heavy tail.
