#!/bin/bash
# run.sh <control> [range] [mode] [display] [shotfile]   (env BIN=allocmatrix_gtk4_expA selects another binary)
#   prints the SNAP lines (Xvfb, cairo renderer, x11 backend). With a 5th arg, a root screenshot
#   is taken right after the "SNAP scroll2" line, i.e. scrolled AFTER all resizes (the harness pauses 1.5 s there when ALLOC_SHOT=1). GSK=gl selects the GL renderer.
S=$(cd "$(dirname "$0")" && pwd); C=$1; R=${2:-hv}; MODE=$3; DN=${4:-91}; SHOT=$5
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=${GSK:-cairo} GDK_BACKEND=x11 LANG=C.UTF-8
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!
for i in $(seq 1 60); do xdpyinfo -display :$DN >/dev/null 2>&1 && break; sleep 0.1; done; sleep 0.3
if [ -n "$SHOT" ]; then
  export ALLOC_SHOT=1; LOG=$(mktemp)
  timeout 60 "$S/${BIN:-allocmatrix_gtk4}" "$C" "$R" $MODE > "$LOG" 2>&1 & APID=$!
  for i in $(seq 1 100); do grep -q "SNAP scroll2 \|SNAP mid-grow " "$LOG" && break; sleep 0.1; done; sleep 0.6
  import -window root "$SHOT"; wait $APID; echo "EXIT=$?"; cat "$LOG"; rm -f "$LOG"
else
  timeout 60 "$S/${BIN:-allocmatrix_gtk4}" "$C" "$R" $MODE 2>&1; echo "EXIT=$?"
fi
kill $XPID 2>/dev/null; wait $XPID 2>/dev/null; rm -f /tmp/.X$DN-lock
