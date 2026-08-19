#!/bin/sh
# pip_install.sh — OpenLane2 venv pip install (writes to $HOME/ol2/pip.log)
cd "$HOME/openlane2" || exit 1
[ -d .venv ] || python3 -m venv .venv
. .venv/bin/activate
pip install -e .