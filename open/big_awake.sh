#!/bin/bash
# big_awake.sh — is the BIG run's openroad alive (target by image/older container)?
for CID in $(docker ps -q); do
  NAME=$(docker inspect -f '{{.Name}}' "$CID")
  if [ "$NAME" = "/wizardly_curran" ]; then
    docker top "$CID" 2>/dev/null | grep -i openroad | awk '{print "BIG pid",$2,"cpu%",$4,"cpu_time",$7}'
  fi
done