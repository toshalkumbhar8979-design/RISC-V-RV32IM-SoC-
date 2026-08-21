#!/bin/bash
# run_ol2.sh — launch the OpenLane 2 2.3.10 flow for riscv_doom_soc in Docker.
#   design:   /home/toshal/work/riscv_doom_soc   (Linux-native work copy)
#   PDK:      volare sky130 @ 0fe599b... (pinned to OL 2.3.10), volare-root layout
# Usage: bash run_ol2.sh [extra-openlane-args...]
set -e
DESIGN=/home/toshal/work/riscv_doom_soc
PDKROOT=/home/toshal/pdk            # volare home (contains volare/sky130/versions/...)
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