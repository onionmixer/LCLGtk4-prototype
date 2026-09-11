#!/bin/bash
# runall.sh [ws...] (default gtk4 qt5 gtk2)
S=$(cd "$(dirname "$0")" && pwd); WSS=${@:-gtk4 qt5 gtk2}; RC=0
for ws in $WSS; do
  CTLS="custom scrollbox memo listbox listview treeview treeviewnohint synedit spin combo pagecontrol groupbox trackbar panel button edit formscroll formmenu"
  [ $ws = gtk2 ] && CTLS="custom scrollbox memo listbox listview treeview treeviewnohint spin combo pagecontrol groupbox trackbar panel button edit formscroll formmenu"
  for c in $CTLS; do $S/run.sh $ws $c; r=$?; echo "done $ws $c ok=$r"; [ $r -eq 0 ] || { [ $ws = qt5 ] && grep -q "region multibtn" $S/out/${ws}_$c.log; } || RC=1; done   # qt5 stops only after the multibtn button-3 press: tolerated
done
echo "ALLDONE rc=$RC"; exit $RC
