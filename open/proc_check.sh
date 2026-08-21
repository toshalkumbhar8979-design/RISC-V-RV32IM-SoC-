#!/bin/bash
# resizer_check.sh — check the resizer step is alive.
CID=$(docker ps -q | head -1)
echo "container=$CID"
docker exec "$CID" sh -c 'cat /proc/loadavg; echo "---"; ls -la /home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/36-openroad-resizertimingpostcts/' 2>&1 | head -12
echo "== flow tail =="
tail -4 /home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/flow.log