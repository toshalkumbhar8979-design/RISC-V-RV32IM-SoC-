#!/bin/bash
# p5_progress.sh — consolidated status of both runs.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
RB=$(ls -dt /home/toshal/work/riscv_doom_soc/runs/RUN_* | head -1)
echo "== SMALL steps=$(ls "$R" | grep -c '^[0-9]') =="
tail -2 "$R/flow.log" 2>/dev/null
echo
echo "== BIG steps=$(ls "$RB" | grep -c '^[0-9]') =="
tail -1 "$RB/flow.log" 2>/dev/null
echo
echo "== small GDS/DRC/LVS artifacts =="
find "$R" -name "*.gds" 2>/dev/null | head -3
ls -d "$R"/*drc* "$R"/*lvs* "$R"/*gds* 2>/dev/null | head -6