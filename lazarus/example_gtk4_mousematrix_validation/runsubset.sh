#!/bin/bash
# runsubset.sh [outdir]: the v2 harness subset for the plan (gtk4/qt5/gtk2)
S=$(cd "$(dirname "$0")" && pwd); O=${1:-$S/out}
for ws in gtk4 qt5 gtk2; do
  for c in custom scrollbox memo listbox listview treeviewnohint synedit groupbox pagecontrol formscroll; do
    [ $ws = gtk2 ] && [ $c = synedit ] && continue
    $S/run.sh $ws $c 71; echo "done $ws $c ok=$?"
  done
done
echo ALLDONE
