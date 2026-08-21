#!/bin/bash
# progr_check.sh — check openroad process CPU TIME accumulation.
CID=$(docker ps -q | head -1)
docker top "$CID" > /tmp/dtop.txt 2>&1
PID=$(grep openroad /tmp/dtop.txt | awk '{print $2}')
echo "openroad pid=$PID"
ps -p "$PID" -o pid,etime,time,pcpu,rss 2>&1 | tail -2