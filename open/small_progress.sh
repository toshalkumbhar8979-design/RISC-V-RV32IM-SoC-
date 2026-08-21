#!/bin/bash
# small_progress.sh — overall small-variant status: run steps + STA metrics + RSZ.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* 2>/dev/null | head -1)
echo "RUN=$R  steps=$(ls "$R" 2>/dev/null | wc -l)"
tail -2 "$R/flow.log" 2>/dev/null
RSZ="$R/36-openroad-resizertimingpostcts/openroad-resizertimingpostcts.log"
if [ -f "$RSZ" ]; then
  echo "-- RSZ endpoints:"
  strings "$RSZ" | grep -aE "RSZ-009[0-9]" | tail -2
fi