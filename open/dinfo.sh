#!/bin/bash
# dinfo.sh — docker info essentials + pull progress.
docker info > /tmp/di.txt 2>&1
grep -iE "Docker Root|Storage Driver" /tmp/di.txt | head -3
du -s /var/lib/docker 2>/dev/null | head -1
echo "== pull log =="
cat /mnt/c/Users/tosha/Downloads/RiscV/open/pull2.log 2>/dev/null
echo "== procs =="
ps -e -o pid,etime,comm > /tmp/ps.txt
grep -iE "docker$|containerd" /tmp/ps.txt | head -4
echo "END"