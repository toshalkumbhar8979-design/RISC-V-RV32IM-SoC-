#!/bin/bash
# peek_rsz.sh — peek the resizer TCL loop structure.
CID=$(docker ps -q | head -1)
docker exec "$CID" cat /nix/store/ss2cw3sxbrwwx9jl0rrppbw4kgcmgi2n-python3-3.11.9-env/lib/python3.11/site-packages/openlane/scripts/openroad/rsz_timing_postcts.tcl 2>/dev/null | grep -nE "repair|while|loop|foreach" | head -20