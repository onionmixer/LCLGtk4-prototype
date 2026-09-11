#!/bin/bash
# runexp2.sh: after runexp.sh finished, rebuild the experimental binaries with the current harness
# and add the late/hidden/treeview/synedit scenarios to out_expA/ out_expB/.
S=$(cd "$(dirname "$0")" && pwd); SC=/tmp/claude-1000/-mnt-STORAGE16T-Workspace-STORAGE16T-LCL-GTK4/ebf5374b-19fa-464e-b67b-9af1c017a195/scratchpad
while ! grep -q ALLEXPDONE "$S/runexp.out" 2>/dev/null; do sleep 5; done
"$S/build_exp.sh" $SC/exp_gtk4_A expA; "$S/build_exp.sh" $SC/exp_gtk4_B expB
for v in expA expB; do
  for c in scrollbox custom; do for m in late hidden; do BIN=allocmatrix_gtk4_$v "$S/run.sh" $c hv $m 91 > "$S/out_$v/${c}_hv_$m.txt"; done; done
  for c in treeview synedit; do
    BIN=allocmatrix_gtk4_$v "$S/run.sh" $c hv "" 91 > "$S/out_$v/${c}_hv.txt"
    BIN=allocmatrix_gtk4_$v "$S/run.sh" $c hv notruth 91 "$S/shots/${c}_hv_notruth_scroll_$v.png" > "$S/out_$v/${c}_hv_notruth.txt"
  done
  echo "done2 $v"
done
echo ALLEXP2DONE
