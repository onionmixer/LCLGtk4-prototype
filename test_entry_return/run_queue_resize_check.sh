#!/bin/bash
# 빈 화면 상태에서 gdb 로 gtk_widget_queue_resize(GtkFixed) 만 호출해 내용이 되살아나는지 확인한다.
#   ./run_queue_resize_check.sh <tomboy-ng-gtk4-dbg 바이너리> [display] [note] [gdb script]
HERE=$(cd "$(dirname "$0")" && pwd); BIN=$1; DN=${2:-79}; NOTE=${3:-synth_long_only.note}; GDBX=${4:-$HERE/queue_resize.gdb}
W=$HERE/work; rm -rf "$W"; mkdir -p "$W/cfg" "$W/notes" "$W/shots"; cp "$HERE/$NOTE" "$W/notes/bigsearch.note"
sed -e "s|^NotesPath=.*|NotesPath=$W/notes/|" -e 's/^ShowSearchAtStart=.*/ShowSearchAtStart=false/' -e 's/^ShowSplash=.*/ShowSplash=false/' ~/.config/tomboy-ng/tomboy-ng.cfg > "$W/cfg/tomboy-ng.cfg"
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=cairo GDK_BACKEND=x11
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.5
gdb -q -batch -x "$GDBX" --args "$BIN" --config-dir="$W/cfg" --no-splash --open-note="$W/notes/bigsearch.note" >"$W/gdb.log" 2>&1 & GPID=$!
for i in $(seq 1 40); do WID=$(xdotool search --name 'Big search test' 2>/dev/null | head -1); [ -n "$WID" ] && break; sleep 0.5; done
echo "window $WID"; sleep 1.5
shot(){ import -window root "$W/shots/$1.png"; printf '%s  %s\n' "$(md5sum < "$W/shots/$1.png" | cut -c1-8)" "$1"; }
xdotool key --window "$WID" ctrl+f; sleep 0.7
xdotool type --delay 250 ubi; sleep 1.0; shot 1-blank-after-find
kill -INT $GPID 2>/dev/null; sleep 4; shot 2-after-queue-resize
kill -INT $GPID 2>/dev/null; sleep 3; kill $GPID 2>/dev/null; sleep 0.5; kill $XPID 2>/dev/null
