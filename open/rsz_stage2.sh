#!/bin/bash
# rsz_stage2.sh — extended resizer status.
L=/home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/36-openroad-resizertimingpostcts/openroad-resizertimingpostcts.log
echo "== RSZ hints =="
strings "$L" | grep -aiE "RSZ-00[0-9][0-9]" | tail -6
echo "== last conv table =="
strings "$L" | grep -aE "^\s+[0-9]+\*?" | tail -3