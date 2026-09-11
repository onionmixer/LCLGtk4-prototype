#!/bin/bash
# runall.sh [ws...]  (default gtk4 qt5 gtk2). Runs isolated (ISOLATE=1, SUFFIX=_iso) and sequential (no suffix) modes.
S=$(cd "$(dirname "$0")" && pwd)
WSS=${@:-gtk4 qt5 gtk2}
CTLS="edit spin fspin comboedit combolist memo listbox checklist listview treeview button checkbox radio trackbar grid"
for ws in $WSS; do for c in $CTLS; do
  ISOLATE=1 SUFFIX=_iso $S/run.sh $ws $c; r1=$?
  $S/run.sh $ws $c; r2=$?
  echo "done $ws $c iso_ok=$r1 seq_ok=$r2"
done; done
echo ALLDONE
