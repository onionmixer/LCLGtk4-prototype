#!/bin/bash
# run.sh <ws> <control> [display]  -> out/<ws>_<control>.log  (the harness drives xdotool itself)
S=$(cd "$(dirname "$0")" && pwd); WS=$1; CTL=$2; DN=${3:-71}
mkdir -p $S/out; OUT=$S/out/${WS}_${CTL}.log
unset XAUTHORITY; export DISPLAY=:$DN GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb GSK_RENDERER=cairo LANG=C.UTF-8
Xvfb :$DN -ac -screen 0 1200x900x24 >/dev/null 2>&1 & XPID=$!
for i in $(seq 1 60); do xdpyinfo -display :$DN >/dev/null 2>&1 && break; sleep 0.1; done; sleep 0.3
timeout 60 "$S/mousematrix_$WS" "$CTL" > "$OUT" 2>&1; echo "PROCEXIT $?" >> "$OUT"
kill $XPID 2>/dev/null; wait $XPID 2>/dev/null; rm -f /tmp/.X$DN-lock
grep -q "^ *[0-9]* DONE" "$OUT" && grep -q "^PROCEXIT 0" "$OUT"
