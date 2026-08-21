#!/bin/bash
# pdk_enable.sh — enable sky130 PDK for OpenLane 2 2.3.10 via volare.
# PDK root default = $HOME/.volare (OpenLane2's default PDK_ROOT).
set -e
cd "$HOME/openlane2"
. .venv/bin/activate
export PDK_ROOT="$HOME/pdk"
COMMIT=0fe599b2afb6708d281543108caf8310912f54af
echo "== volare enable sky130 @ $COMMIT (PDK_ROOT=$PDK_ROOT)"
volare enable --pdk sky130 --pdk-root "$PDK_ROOT" "$COMMIT"
echo "PDK_DONE rc=0"
find "$PDK_ROOT" -maxdepth 2 -name "sky130B" -type d | head -2