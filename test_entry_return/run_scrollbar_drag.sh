#!/bin/bash
# 세로 스크롤바 썸을 마우스로 드래그한 뒤 본문이 선택되는지 스크린샷으로 확인한다 (2-after-drag, 3-after-drag2).
#   ./run_scrollbar_drag.sh <tomboy-ng 바이너리> [display=78] [note] [outdir]   (Qt5 바이너리로 돌리면 기준선)
HERE=$(cd "$(dirname "$0")" && pwd); BIN=$1; DN=${2:-78}; NOTE=${3:-synth_long_only.note}; OUT=${4:-$HERE/work/out}
W=$HERE/work; rm -rf "$W"; mkdir -p "$W/cfg" "$W/notes" "$W/shots"; cp "$HERE/$NOTE" "$W/notes/bigsearch.note"
sed -e "s|^NotesPath=.*|NotesPath=$W/notes/|" -e 's/^ShowSearchAtStart=.*/ShowSearchAtStart=false/' -e 's/^ShowSplash=.*/ShowSplash=false/' ~/.config/tomboy-ng/tomboy-ng.cfg > "$W/cfg/tomboy-ng.cfg"
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=cairo GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.5
"$BIN" --config-dir="$W/cfg" --no-splash --open-note="$W/notes/bigsearch.note" >"$W/app.log" 2>&1 & APID=$!
for i in $(seq 1 40); do WID=$(xdotool search --name 'Big search test' 2>/dev/null | head -1); [ -n "$WID" ] && break; sleep 0.5; done
sleep 1.5; eval $(xdotool getwindowgeometry --shell $WID); echo "window $WID at $X,$Y ${WIDTH}x${HEIGHT}"
shot(){ import -window root "$W/shots/$1.png"; printf '%s  %s\n' "$(md5sum < "$W/shots/$1.png" | cut -c1-8)" "$1"; }
SBX=$((X+WIDTH-8)); TOP=$((Y+60)); shot 0-opened
# drag the vertical scrollbar thumb down and up several times
xdotool mousemove $SBX $TOP; sleep 0.3; xdotool mousedown 1; sleep 0.3
for y in 150 300 450 600 450 300 150 400 650 200; do xdotool mousemove $SBX $((Y+y)); sleep 0.15; done
shot 1-during-drag
xdotool mouseup 1; sleep 0.8; shot 2-after-drag
# second drag
xdotool mousemove $SBX $((Y+200)); sleep 0.3; xdotool mousedown 1; sleep 0.2
for y in 100 500 100 600 80; do xdotool mousemove $SBX $((Y+y)); sleep 0.15; done
xdotool mouseup 1; sleep 0.8; shot 3-after-drag2
# Esc test: open find panel then press Escape
xdotool key --window "$WID" ctrl+f; sleep 0.8; shot 4-findpanel
xdotool key Escape; sleep 0.8; shot 5-after-esc
kill $APID 2>/dev/null; sleep 0.5; kill $XPID 2>/dev/null
rm -rf "$OUT"; mkdir -p "$OUT"; cp "$W"/shots/*.png "$OUT"/
