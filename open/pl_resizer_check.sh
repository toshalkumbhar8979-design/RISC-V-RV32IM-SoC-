#!/bin/bash
# pl_resizer_check.sh — read the resizer step config values.
C=/home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/36-openroad-resizertimingpostcts/config.json
grep -a -o '"PL_RESIZER[A-Z_]*[^,]*' "$C" | head -14