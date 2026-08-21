#!/bin/bash
# run_info.sh — container + run-dir snapshot for the OL2 flow.
docker ps --no-trunc > /tmp/dps.txt
grep -v CONTAINER /tmp/dps.txt | head -2
echo "== stats =="
docker stats --no-stream 2>&1 | head -3
echo "== runs dir =="
ls /home/toshal/work/riscv_doom_soc/runs/ 2>/dev/null | head -4
echo "== run steps =="
ls /home/toshal/work/riscv_doom_soc/runs/*/ 2>/dev/null | head -20