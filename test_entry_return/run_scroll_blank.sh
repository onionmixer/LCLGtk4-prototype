#!/bin/bash
# GTK4 빈 화면 재현: 노트 열기 -> Ctrl+F(패널 열림, KMemo 리사이즈) -> 메모 클릭 -> PageDown x6 -> Ctrl+End -> Ctrl+Home
#   ./run_scroll_blank.sh <tomboy-ng-gtk4 바이너리> [display=83] [note=synth_long_only.note] [outdir]
# 같은 digest 가 반복되면 화면이 안 바뀐 것. 빈 화면은 밝은 회색 단색이다(내용이 있으면 크림색 배경).
HERE=$(cd "$(dirname "$0")" && pwd); BIN=$1; DN=${2:-83}; NOTE=${3:-synth_long_only.note}; OUT=${4:-$HERE/work/out}
W=$HERE/work; rm -rf "$W"; mkdir -p "$W/cfg" "$W/notes" "$W/shots"; cp "$HERE/$NOTE" "$W/notes/bigsearch.note"
sed -e "s|^NotesPath=.*|NotesPath=$W/notes/|" -e 's/^ShowSearchAtStart=.*/ShowSearchAtStart=false/' -e 's/^ShowSplash=.*/ShowSplash=false/' ~/.config/tomboy-ng/tomboy-ng.cfg > "$W/cfg/tomboy-ng.cfg"
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=cairo GDK_BACKEND=x11
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.5
"$BIN" --config-dir="$W/cfg" --no-splash --open-note="$W/notes/bigsearch.note" >"$W/app.log" 2>&1 & APID=$!
for i in $(seq 1 40); do WID=$(xdotool search --name 'Big search test' 2>/dev/null | head -1); [ -n "$WID" ] && break; sleep 0.5; done
sleep 1.5
shot(){ import -window root "$W/shots/$1.png"; printf '%s  %s\n' "$(md5sum < "$W/shots/$1.png" | cut -c1-8)" "$1"; }
xdotool key --window "$WID" ctrl+f; sleep 0.8; shot 0-panel-open
xdotool mousemove 400 300 click 1; sleep 0.5; shot 1-clicked
for n in 1 2 3 4 5 6; do xdotool key Next; sleep 0.6; shot pgdn-$n; done
xdotool key ctrl+End; sleep 0.8; shot ctrl-end
xdotool key ctrl+Home; sleep 0.8; shot ctrl-home
kill $APID 2>/dev/null; sleep 0.5; kill $XPID 2>/dev/null
rm -rf "$OUT"; mkdir -p "$OUT"; cp "$W"/shots/*.png "$OUT"/
