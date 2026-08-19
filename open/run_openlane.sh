#!/bin/sh
# open/run_openlane.sh — OpenLane 2 sign-off run for riscv_doom_soc.
# Pre-req (blocked on this box as of this commit):
#   - Docker Desktop WSL integration, logger-in registry, then the pull:
#       docker pull ghcr.io/efabless/openlane2:<v2-tag>
#     OR pip route on Python 3.8-3.12 (conda/python3.11), then `openlane`.
set -e
OL=/mnt/c/Users/tosha/Downloads/RiscV/open
D=${OL}/designs/riscv_doom_soc
mkdir -p ${D}/runs

MODE=$1   # "docker" or "pip"

if [ "$MODE" = "pip" ]; then
  . $HOME/openlane2/.venv/bin/activate
  openlane ${D}/config.json --run-dir ${D}/runs
else
  docker run --rm -v ${D}:/home/openlane/designs/riscv_doom_soc \
    ghcr.io/efabless/openlane2:latest openlane \
    --config /home/openlane/designs/riscv_doom_soc/config.json
fi
echo "ARTIFACTS:"; ls -R ${D}/runs | sed -n '1,40p'