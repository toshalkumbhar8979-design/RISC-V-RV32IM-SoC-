#!/bin/bash
# p5_data.sh — collect all Phase-5 metrics + small-run routing summary.
echo "################## SMALL RUN ##################"
R=$(ls -dt /home/toshal/work/riscv_doom_soc_small/runs/RUN_* | head -1)
echo "RUN=$R  steps=$(ls "$R" | grep -c '^[0-9]')"
echo
echo "-- SYNTH --"
grep -aE "Chip area for module|Number of cells|sequential elements" "$R/06-yosys-synthesis/yosys-synthesis.log" | tail -4
echo
echo "-- FLOORPLAN --"
grep -aE "die area|core area" "$R/13-openroad-floorplan/openroad-floorplan.log" | tail -2
echo
echo "-- detailed routing log tail --"
DR=$(ls -d "$R"/*detailedrouting/* | grep -v ^$ | head -1)
tail -c 700 "$R/43-openroad-detailedrouting/openroad-detailedrouting.log" 2>/dev/null | strings | tail -3
echo
echo "-- STA setup WNS (latest) --"
for s in "$R"/30-openroad-stamidpnr "$R"/35-openroad-stamidpnr-1 "$R"/37-openroad-stamidpnr-2 "$R"/42-openroad-stamidpnr-3; do
  l="$s/$(basename "$s").log"
  [ -f "$l" ] && strings "$l" | grep -a "timing__setup__wns" | tail -1
done
echo
echo "################## BIG RUN ##################"
RB=$(ls -dt /home/toshal/work/riscv_doom_soc/runs/RUN_* | head -1)
echo "RUN=$RB  steps=$(ls "$RB" | grep -c '^[0-9]')"
grep -aE "Chip area for module|Number of cells" "$RB/06-yosys-synthesis/yosys-synthesis.log" | tail -2
echo
echo "-- big resizer --"
bash /mnt/c/Users/tosha/Downloads/RiscV/open/big_awake.sh 2>&1 | tail -1