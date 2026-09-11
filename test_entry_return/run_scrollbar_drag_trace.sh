#!/bin/bash
# gdb dprintf 로 스크롤바 드래그 중 KMemo 가 받는 MouseDown/MouseMove/MouseUp 좌표를 기록한다 (디버그 바이너리 필요).
#   ./run_scrollbar_drag_trace.sh <tomboy-ng-gtk4-dbg> [display=76] [note] [gdb script]
HERE=$(cd "$(dirname "$0")" && pwd); BIN=$1; DN=${2:-76}; NOTE=${3:-synth_long_only.note}; GDBX=${4:-$HERE/scrollbar_drag.gdb}
W=$HERE/work; rm -rf "$W"; mkdir -p "$W/cfg" "$W/notes" "$W/shots"; cp "$HERE/$NOTE" "$W/notes/bigsearch.note"
sed -e "s|^NotesPath=.*|NotesPath=$W/notes/|" -e 's/^ShowSearchAtStart=.*/ShowSearchAtStart=false/' -e 's/^ShowSplash=.*/ShowSplash=false/' ~/.config/tomboy-ng/tomboy-ng.cfg > "$W/cfg/tomboy-ng.cfg"
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=cairo GDK_BACKEND=x11
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.5
gdb -q -batch -x "$GDBX" --args "$BIN" --config-dir="$W/cfg" --no-splash --open-note="$W/notes/bigsearch.note" >"$W/gdb.log" 2>&1 & GPID=$!
for i in $(seq 1 40); do WID=$(xdotool search --name 'Big search test' 2>/dev/null | head -1); [ -n "$WID" ] && break; sleep 0.5; done
sleep 1.5; eval $(xdotool getwindowgeometry --shell $WID); SBX=$((X+WIDTH-8)); TOP=$((Y+60))
echo "--- drag on scrollbar x=$SBX"; xdotool mousemove $SBX $TOP; sleep 0.3; xdotool mousedown 1; sleep 0.3
for y in 150 300 450 300 150; do xdotool mousemove $SBX $((Y+y)); sleep 0.15; done
xdotool mouseup 1; sleep 0.8
kill -INT $GPID 2>/dev/null; sleep 1; kill $GPID 2>/dev/null; sleep 0.5; kill $XPID 2>/dev/null
grep -E '^###|Error' "$W/gdb.log" | head -30
