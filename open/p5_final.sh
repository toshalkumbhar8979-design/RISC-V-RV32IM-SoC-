#!/bin/bash
# p5_final.sh — dump the final artifacts + metrics of the completed small run.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
echo "RUN=$R"
echo
echo "== final/ contents =="
ls -la "$R/final" 2>/dev/null | head -20
echo
echo "== GDS files =="
find "$R" -name "*.gds" 2>/dev/null
echo
echo "== DRC logs =="
for d in 62-magic-drc 63-klayout-drc; do
  echo "-- $d:"
  tail -3 "$R/$d/$(basename "$d").log" 2>/dev/null | strings | tail -3
done
echo
echo "== LVS =="
ls -d "$R"/*lvs* 2>/dev/null | head -3