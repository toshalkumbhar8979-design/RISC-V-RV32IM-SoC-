# Pad Ring Plan — Phase 6 (Track-A gated)

**Status: PLAN ONLY. Not executable in this environment — requires a specific
carrier's fixed pad frame (Caravel/ChipIgnite/IHP) and, for a real shuttle,
foundry IO cells. Kept as the honest hand-off so Track A can start instantly.**

## What a pad ring needs
1. **Carrier decision** — which shuttle/harness (Caravel Harness vs ChipIgnite
   custom). This fixes:
   - die size / aspect ratio (e.g., Caravel 7120 × 7120 µm area with a
     fixed 38-pin IO set), 
   - the **fixed pad frame** (pad coordinates, IO cell types: digital in/out,
     analog, power/GND/ESD).
2. **sky130 IO cells** — from the PDK (`sky130_ef_io`, GPIO38, IOPad) or the
   via-volare `libs.ref/sky130_ef_io`. These provide ESD, level shift, and
   drive strength.
3. **Connect the SoC ports** to the pad frame via the IO cell instances:
   - CLK/RST via GPIO or dedicated
   - UART TX/RX, QSPI (SCK, MOSI, MISO, CS0, CS1), TFT (CS, SCK, MOSI, DC,
     RST), power/ground
4. **Run the pad ring in the ASIC flow**:
   - Add `IO_LIBRARY`/pad cells as macros (LEF from `sky130_ef_io`)
   - Place IO cells on the ring; autorun (OpenLane `RUN_PIN_DETAIL_ENHANCEMENT`
     or manual `io_placement`)
   - Clock pad handled with the `IO_CLOCK` constraint + special routing
5. **Sign-off re-run**: DRC (pad/ESD rules), LVS (with IO cells), antenna,
   and the final merge of the SoC GDS + pad ring GDS.

## Deliverable in this repo (no tool needed)
- `docs/PADRING_PLAN.md` — this file
- The SoC already exposes all required ports (`f_cs_n, f_sclk, f_mosi,
  f_miso, p_cs_n, uart_txd, tft_*`) — see `rtl/soc/riscv_soc.v` port list.

## When it's doable
- The moment a carrier is chosen AND the user confirms a real shuttle/fab
  budget (Track A). Until then, per Phase-0 scope, pad ring stays a plan.