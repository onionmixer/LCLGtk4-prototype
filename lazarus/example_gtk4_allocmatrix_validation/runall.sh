#!/bin/bash
# runall.sh [outdir]  -> one log per control/range/mode in outdir (default out/)
S=$(cd "$(dirname "$0")" && pwd); OUT=${1:-$S/out}; mkdir -p "$OUT"
for c in panel groupbox scrollbox custom memo listbox checklist listview statictext progressbar toolbar page statusbar splitterside form; do
  "$S/run.sh" $c hv "" 91 > "$OUT/${c}_hv.txt"; echo "done $c hv $(grep -c '^ *[0-9]* SNAP' "$OUT/${c}_hv.txt") snaps"
done
for c in scrollbox custom; do
  for r in v none; do "$S/run.sh" $c $r "" 91 > "$OUT/${c}_${r}.txt"; echo "done $c $r"; done
  "$S/run.sh" $c hv notruth 91 > "$OUT/${c}_hv_notruth.txt"; echo "done $c hv notruth"
done
for c in memo listbox listview; do "$S/run.sh" $c hv notruth 91 > "$OUT/${c}_hv_notruth.txt"; echo "done $c hv notruth"; done
echo ALLDONE
