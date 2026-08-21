#!/bin/bash
# flow_small.sh — tail the small-variant run.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* 2>/dev/null | head -1)
echo "RUN=$R"
if [ -n "$R" ]; then
  tail -4 "$R/flow.log" 2>/dev/null
  echo "== steps: $(ls "$R" | wc -l) =="
fi