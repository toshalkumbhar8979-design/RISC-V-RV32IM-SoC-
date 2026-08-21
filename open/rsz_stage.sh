#!/bin/bash
# rsz_stage.sh — what repair stage is the resizer on?
L=/home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07/36-openroad-resizertimingpostcts/openroad-resizertimingpostcts.log
strings "$L" | grep -aiE "repair_timing|repair_hold|repair_setup|hold|setup|conver|finish|complete" | tail -8