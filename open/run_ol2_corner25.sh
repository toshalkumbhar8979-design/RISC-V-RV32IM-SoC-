#!/bin/bash
# run_ol2_corner25.sh — run the tractable probe at 25 ns clock (closes slow corner).
DESIGN=/home/toshal/work/riscv_doom_soc_small
PDKROOT=/home/toshal/pdk
IMG=ghcr.io/efabless/openlane2:2.3.10
CFG="$DESIGN/config.json"
# override clock to 25 ns for this run (config has 20)
timeout 7200 docker run --rm \
  -v "$DESIGN:$DESIGN" -w "$DESIGN" \
  -v "$PDKROOT:$PDKROOT" -e PDK_ROOT="$PDKROOT" \
  -e PDK=sky130B -e STD_CELL_LIBRARY=sky130_fd_sc_hd \
  "$IMG" openlane --pdk-root "$PDKROOT" -p sky130B -s sky130_fd_sc_hd \
  --override-config CLOCK_PERIOD=25 "$CFG" 2>&1 | tail -40
echo "CORNER25_RC=$?"