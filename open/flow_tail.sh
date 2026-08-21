#!/bin/bash
# flow_tail.sh — tail flow.log + count steps.
FLOW=/home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/flow.log
tail -3 "$FLOW"
echo "== run dir entries: $(ls /home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07 | wc -l) =="
docker top $(docker ps -q | head -1) 2>/dev/null | tail -2 | cut -c1-80