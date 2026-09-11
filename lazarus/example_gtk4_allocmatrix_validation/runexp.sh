#!/bin/bash
# runexp.sh: matrix for the two experimental binaries -> out_expA/, out_expB/ (+ screenshots)
S=$(cd "$(dirname "$0")" && pwd)
for v in expA expB; do
  BIN=allocmatrix_gtk4_$v "$S/runall.sh" "$S/out_$v" > "$S/runall_$v.out" 2>&1
  for c in scrollbox custom; do BIN=allocmatrix_gtk4_$v "$S/run.sh" $c hv notruth 91 "$S/shots/${c}_hv_notruth_scroll_$v.png" > /dev/null 2>&1; done
  echo "done $v"
done
echo ALLEXPDONE
