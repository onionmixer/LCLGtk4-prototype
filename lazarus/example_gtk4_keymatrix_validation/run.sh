#!/bin/bash
# run.sh <ws> <control> [eatlist]
#   env: KEYS="k1 k2 ..." (xdotool key names; "REPEAT:<key>" = 3 auto-repeats, "DOWN:<key>"/"UP:<key>" = press/release only), SUFFIX=_x (log name suffix),
#        ISOLATE=1 (refocus target before every key), GAP_MS (default 350)
# -> out/<ws>_<control>[_eat][SUFFIX].log (+ .keys) ; prints nothing, exit 0 if the program ended with FINAL+EXIT
S=$(cd "$(dirname "$0")" && pwd); WS=$1; CTL=$2; EAT=${3:-}
mkdir -p $S/out; OUT=$S/out/${WS}_${CTL}${EAT:+_eat}${SUFFIX:-}.log
KEYS=${KEYS:-"Return KP_Enter Escape Up Down Left Right Home End Prior Next Delete BackSpace Insert F3 space a ctrl+a Tab shift+Tab"}
GAP=${GAP_MS:-350}
NK=$(python3 -c "print(len('$KEYS'.split()))")
export KEYMATRIX_MS=$(python3 -c "print(1500 + $GAP * $NK + 900)")
export KEYMATRIX_ISOLATE=${ISOLATE:-0}
rm -f $OUT $OUT.keys
timeout 60 xvfb-run -a -s "-screen 0 1200x900x24" bash -c "
  export GDK_BACKEND=x11 QT_QPA_PLATFORM=xcb GSK_RENDERER=cairo
  $S/keymatrix_$WS $CTL $EAT > $OUT 2>&1 & pid=\$!
  for i in \$(seq 1 30); do xdotool search --name '^keymatrix\$' >/dev/null 2>&1 && break; sleep 0.2; done
  sleep 1.2
  t0=\$(date +%s%3N)
  for k in $KEYS; do
    echo \"\$(( \$(date +%s%3N) - t0 )) --- key \$k\" >> $OUT.keys
    case \$k in
      REPEAT:*) xdotool key --repeat 3 --delay 40 \${k#REPEAT:} ;;
      DOWN:*) xdotool keydown \${k#DOWN:} ;;
      UP:*) xdotool keyup \${k#UP:} ;;
      *) xdotool key \$k ;;
    esac
    sleep $(python3 -c "print($GAP/1000)")
  done
  wait \$pid; echo \"PROCEXIT \$?\" >> $OUT"
grep -q '^ *[0-9]* FINAL' $OUT && grep -q 'EXIT     normal' $OUT && grep -q '^PROCEXIT 0' $OUT
