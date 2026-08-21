#!/bin/bash
# pdkcheck.sh — volare/PDK fetch status.
ls -la "$HOME/pdk" 2>/dev/null | head -6
echo "== pdk.log =="
cat /mnt/c/Users/tosha/Downloads/RiscV/open/pdk.log 2>/dev/null | head -6
echo "== procs =="
ps -e -o pid,etime,comm > /tmp/ps.txt
grep -iE "volare|python|curl" /tmp/ps.txt | head -5
echo "END"