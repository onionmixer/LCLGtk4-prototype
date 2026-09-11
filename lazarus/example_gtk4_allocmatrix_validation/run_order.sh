#!/bin/bash
# run_order.sh <control> [range] [display] -> interleaves SNAP lines with SetBounds/SetScrollInfo/queue_resize order (gdb)
S=$(cd "$(dirname "$0")" && pwd); C=$1; R=${2:-hv}; DN=${3:-92}
unset XAUTHORITY; export DISPLAY=:$DN GSK_RENDERER=cairo GDK_BACKEND=x11 LANG=C.UTF-8
Xvfb :$DN -ac -screen 0 1400x1000x24 >/dev/null 2>&1 & XPID=$!; sleep 1.2
timeout 120 gdb -q -batch -x "$S/order.gdb" --args "$S/allocmatrix_gtk4" "$C" "$R" notruth 2>&1 | grep -E "^ORDER|SNAP|START|DONE"
kill $XPID 2>/dev/null
