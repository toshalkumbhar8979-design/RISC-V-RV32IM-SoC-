#!/bin/bash
# small_awake.sh — is the SMALL run's openroad alive (target by name angry_meninsky)?
for CID in $(docker ps -q); do
  NAME=$(docker inspect -f '{{.Name}}' "$CID")
  if [ "$NAME" = "/angry_meninsky" ]; then
    docker top "$CID" 2>/dev/null | grep -i openroad | awk '{print "SMALL pid",$2,"cpu%",$4,"cpu_time",$7}'
  fi
done