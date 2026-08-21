#!/bin/bash
# resolved_check.sh — peek resolved config keys.
R=/home/toshal/work/riscv_doom_soc/runs/RUN_2026-08-20_21-04-07
grep -a -o '"PDK[^,]*' "$R/resolved.json" | head -4
grep -a -o '"STD_CELL_LIBRARY[^,]*' "$R/resolved.json" | head -2
grep -a -o '"CLOCK_PERIOD[^,]*' "$R/resolved.json" | head -2
grep -a -o '"CLOCK_PORT[^,]*' "$R/resolved.json" | head -2
grep -a -o '"DESIGN_NAME[^,]*' "$R/resolved.json" | head -2