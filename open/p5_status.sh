#!/bin/bash
# p5status.sh — one-shot status snapshot for the Phase-5 flow.
echo "== time =="
date +%H:%M:%S
echo "== dockerd =="
ps -e -o pid,etime,comm | grep dockerd | head -2
echo "== sleep/keepalive =="
ps -e -o pid,etime,comm | grep -i sleep | head -4
echo "== pull logs =="
for f in pull.log pull2.log; do
  p="/mnt/c/Users/tosha/Downloads/RiscV/open/$f"
  if [ -f "$p" ]; then
    echo "-- $f ($(wc -c < "$p")B) --"
    tail -c 300 "$p" | tr '\r' '\n' | tail -3
  else
    echo "-- $f MISSING --"
  fi
done
echo "== images =="
docker images 2>/dev/null | grep -i openlane
echo "== done =="