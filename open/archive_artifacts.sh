#!/bin/bash
# archive_artifacts.sh — copy final GDS + metrics into the repo.
set -e
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
D=/mnt/c/Users/tosha/Downloads/RiscV/open/artifacts
mkdir -p "$D"
cp "$R/final/gds/riscv_doom_soc.gds"            "$D/riscv_doom_soc.gds"
cp "$R/final/klayout_gds/riscv_doom_soc.klayout.gds" "$D/riscv_doom_soc.klayout.gds"
cp "$R/final/metrics.json"                      "$D/metrics.json"
cp "$R/final/def/riscv_doom_soc.def"            "$D/riscv_doom_soc.def" 2>/dev/null || true
echo "archived:"
ls -la "$D"