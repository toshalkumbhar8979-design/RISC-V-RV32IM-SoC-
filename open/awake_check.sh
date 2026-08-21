#!/bin/bash
# awake_check.sh — is the openroad resizer still accumulating CPU time?
CID=$(docker ps -q | head -1)
docker top "$CID" 2>&1 | grep openroad | awk '{print "pid",$2,"cpu%",$4,"cpu_time",$7}' | head -2