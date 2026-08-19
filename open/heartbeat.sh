#!/bin/sh
# heartbeat.sh <logfile> <cmd...>
# Runs $@ with stdout/stderr to LOG, prints a heartbeat to our stdout so
# long jobs aren't killed by 30 s of silence, then prints the log tail.
LOG=$1; shift
"$@" > "$LOG" 2>&1 &
PID=$!
while kill -0 "$PID" 2>/dev/null; do sleep 3; printf "."; done
wait "$PID"; RC=$?
printf "\nrc=%d\n" "$RC"
tail -15 "$LOG"
exit "$RC"