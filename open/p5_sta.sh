#!/bin/bash
# p5_sta.sh — extract STA WNS/TNS/hold metrics for the small run.
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
echo "SMALL RUN: $R  steps=$(ls "$R" | grep -c '^[0-9]')"
for s in 30-openroad-stamidpnr 35-openroad-stamidpnr-1 37-openroad-stamidpnr-2 42-openroad-stamidpnr-3 36-openroad-resizertimingpostcts; do
  l="$R/$s/$(basename "$s").log"
  if [ -f "$l" ]; then
    echo "== $s =="
    strings "$l" | grep -aE "timing__setup__wns|timing__setup_vio|timing__hold_vio|Slack" | tail -3
  fi
done