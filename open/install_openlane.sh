#!/bin/sh
# open/install_openlane.sh — OpenLane 2 install (WSL2/Kali, docker mode).
#   - clones efabless/openlane2
#   - creates a python venv and installs the flow metapackage
#   - downloads the sky130 PDK via volare (sky130B)
# Logs: $HOME/ol_install.log etc.
set -e

OL_ROOT=$HOME/openlane2
PDK_ROOT=$HOME/pdk
export PDK_ROOT

echo "== clone openlane2 =="
if [ ! -d $OL_ROOT/.git ]; then
  git clone --depth 1 https://github.com/efabless/openlane2 $OL_ROOT
fi
cd $OL_ROOT

echo "== venv + pip install =="
[ -d .venv ] || python3 -m venv .venv
. .venv/bin/activate
pip install -q -e . 2>&1 | tail -5

echo "== versions =="
openlane -h 2>&1 | head -3
volare --version 2>&1

echo "== PDK (sky130B) =="
mkdir -p $PDK_ROOT
volare enable --pdk sky130B --pdk-root $PDK_ROOT latest 2>&1 | tail -10

echo "== done =="