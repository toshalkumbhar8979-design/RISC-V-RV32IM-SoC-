#!/bin/bash
# proc_cmd.sh — show each container's openroad command line.
for CID in $(docker ps -q); do
  NAME=$(docker inspect -f '{{.Name}}' "$CID")
  echo "== $NAME =="
  docker top "$CID" 2>/dev/null | grep openroad | awk '{print $2, $5, $6, $7, $8}' | head -1
done