#!/bin/bash
# run_ol2_small.sh — run OL2 on the small-SRAM variant (parallel, tractable).
set -e
DESIGN=/home/toshal/work/riscv_doom_soc_small
PDKROOT=/home/toshal/pdk
IMG=ghcr.io/efabless/openlane2:2.3.10

docker run --rm \
  -v "$DESIGN:$DESIGN" \
  -w "$DESIGN" \
  -v "$PDKROOT:$PDKROOT" \
  -e PDK_ROOT="$PDKROOT" \
  -e PDK=sky130B \
  -e STD_CELL_LIBRARY=sky130_fd_sc_hd \
  "$IMG" \
  openlane --pdk-root "$PDKROOT" -p sky130B -s sky130_fd_sc_hd \
    "$DESIGN/config.json" "$@"