#!/bin/bash
# tomboy-ng 검색창 Enter 재현 스크립트 (Xvfb + xdotool + gdb).
#   ./run.sh <tomboy-ng 바이너리> [display 번호=95]
# 결과: EditFindKeyDown / SpeedRightClick / EditFindChange 호출 로그와 단계별 스크린샷.
set -u
HERE=$(cd "$(dirname "$0")" && pwd); BIN=$1; DN=${2:-95}; NOTE=${3:-bigsearch.note}
W=$HERE/work; rm -rf "$W"; mkdir -p "$W/cfg" "$W/notes" "$W/shots"
cp "$HERE/$NOTE" "$W/notes/bigsearch.note"
if [ -f ~/.config/tomboy-ng/tomboy-ng.cfg ]; then
  sed -e "s|^NotesPath=.*|NotesPath=$W/notes/|" -e 's/^ShowSearchAtStart=.*/ShowSearchAtStart=false/' -e 's/^ShowSplash=.*/ShowSplash=false/' ~/.config/tomboy-ng/tomboy-ng.cfg > "$W/cfg/tomboy-ng.cfg"
else
  printf '[BasicSettings]\nNotesPath=%s/notes/\nShowSplash=false\nShowSearchAtStart=false\nFindToggles=true\nFontSize=medium\n' "$W" > "$W/cfg/tomboy-ng.cfg"
fi
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=${GSK_RENDERER:-cairo} GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.5
cat > "$W/bp.gdb" <<'G'
set pagination off
set breakpoint pending on
dprintf 'EDITBOX$_$TEDITBOXFORM_$__$$_EDITFINDKEYDOWN$TOBJECT$WORD$TSHIFTSTATE',"### EditFindKeyDown Key=%d\n", Key
dprintf 'EDITBOX$_$TEDITBOXFORM_$__$$_SPEEDRIGHTCLICK$TOBJECT',"### SpeedRightClick\n"
dprintf 'EDITBOX$_$TEDITBOXFORM_$__$$_EDITFINDCHANGE$TOBJECT',"### EditFindChange\n"
dprintf 'EDITBOX$_$TEDITBOXFORM_$__$$_MENUFINDNEXTCLICK$TOBJECT',"### MenuFindNextClick\n"
run
G
gdb -q -batch -x "$W/bp.gdb" --args "$BIN" --config-dir="$W/cfg" --no-splash --open-note="$W/notes/bigsearch.note" >"$W/gdb.log" 2>&1 & GPID=$!
for i in $(seq 1 40); do WID=$(xdotool search --name 'Big search test' 2>/dev/null | head -1); [ -n "$WID" ] && break; sleep 0.5; done
echo "note window: ${WID:-NOT FOUND}"; sleep 1
shot(){ import -window root "$W/shots/$1.png"; }
xdotool key --window "$WID" ctrl+f; sleep 0.7; shot 1-findpanel
xdotool type --delay 250 "${SEARCH_TERM:-zebra}"; sleep 0.8; shot 2-typed
echo "--- Return";   xdotool key Return;   sleep 0.8; shot 3-return
echo "--- KP_Enter"; xdotool key KP_Enter; sleep 0.8; shot 4-kpenter
echo "--- F3";       xdotool key F3;       sleep 0.8; shot 5-f3
kill -INT $GPID 2>/dev/null; sleep 0.5; kill $GPID 2>/dev/null; sleep 0.5; kill $XPID 2>/dev/null
echo "=== handler calls (gdb)"; grep -E '^###' "$W/gdb.log"
echo "=== screenshot digests (same digest = view did not move)"; for f in "$W"/shots/*.png; do printf '%s  %s\n' "$(md5sum < "$f" | cut -c1-8)" "$(basename "$f")"; done
