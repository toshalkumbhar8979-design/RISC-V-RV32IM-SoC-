#!/bin/bash
# extract_phase5.sh — full Phase-5 acceptance extraction (run after OL2 completes).
set -e
RUN=$(ls -dt /home/toshal/work/riscv_doom_soc/runs/RUN_* | head -1)
echo "RUN=$RUN"

echo; echo "===================== SYNTH ====================="
S=${RUN}/06-yosys-synthesis
if [ -f "$S/yosys-synthesis.log" ]; then
  grep -aE "Chip area for module|Number of cells|of which used for sequential" "$S/yosys-synthesis.log" | tail -4
fi

echo; echo "===================== FLOORPLAN ====================="
FP=${RUN}/13-openroad-floorplan
if [ -f "$FP/openroad-floorplan.log" ]; then
  grep -aE "Design area|core area|die area|Chip area|Util" "$FP/openroad-floorplan.log" | tail -4
fi

echo; echo "===================== STA (mid) ===================="
for d in ${RUN}/30-openroad-stamidpnr ${RUN}/35-openroad-stamidpnr-1; do
  l="$d/$(basename "$d").log"
  if [ -f "$l" ]; then
    echo "-- $d"
    grep -aE "Slack|WNS|TNS|VIOLATED|met" "$l" | tail -3
  fi
done

echo; echo "===================== ROUTING ====================="
GL=$(ls -d "${RUN}"/*globalroute* "${RUN}"/*globalrouting* 2>/dev/null | head -1)
DR=$(ls -d "${RUN}"/*detailedroute* "${RUN}"/*detailroute* 2>/dev/null | head -1)
for d in "$GL" "$DR"; do
  l="$d/$(basename "$d").log"
  if [ -n "$d" ] && [ -f "$l" ]; then
    echo "-- $d"
    grep -aE "Layers|routing|Wire|Total|vias|Completed" "$l" | tail -3
  fi
done

echo; echo "===================== DRC ====================="
DRC=$(ls -d "${RUN}"/*magic*drc* "${RUN}"/*checkdrc* "${RUN}"/*drc* 2>/dev/null | head -1)
if [ -n "$DRC" ]; then echo "drc dir: $DRC"; ls "$DRC" | head -6; fi

echo; echo "===================== LVS ====================="
LVS=$(ls -d "${RUN}"/*lvs* "${RUN}"/*netgen* 2>/dev/null | head -1)
if [ -n "$LVS" ]; then echo "lvs dir: $LVS"; ls "$LVS" | head -6; fi

echo; echo "===================== GDS ====================="
find "$RUN" -name "*.gds" 2>/dev/null | head
find "$RUN" -name "*.def" -o -name "*.spef" 2>/dev/null | head

echo
echo "===================== FINAL ==================="
tail -14 "${RUN}/flow.log"