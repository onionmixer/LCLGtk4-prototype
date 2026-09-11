#!/bin/bash
# runexp3.sh: second measurement round (after codex review 1): new scenarios/controls for base, expA, expB,
# post-resize screenshots, and a GL-renderer RSS run. Output: out_v2/, out_v2_expA/, out_v2_expB/, shots_v2/
S=$(cd "$(dirname "$0")" && pwd); SC=/tmp/claude-1000/-mnt-STORAGE16T-Workspace-STORAGE16T-LCL-GTK4/ebf5374b-19fa-464e-b67b-9af1c017a195/scratchpad
"$S/build_exp.sh" $SC/exp_gtk4_A expA; "$S/build_exp.sh" $SC/exp_gtk4_B expB
mkdir -p "$S/shots_v2"
for v in base expA expB; do
  B=allocmatrix_gtk4; [ $v != base ] && B=allocmatrix_gtk4_$v; O="$S/out_v2"; [ $v != base ] && O="$S/out_v2_$v"; mkdir -p "$O"
  for c in custom scrollbox; do
    for m in "" notruth rehide inactivepage zero late hidden; do n=${m:-truth}; BIN=$B "$S/run.sh" $c hv "$m" 91 > "$O/${c}_hv_$n.txt"; done
    BIN=$B "$S/run.sh" $c hv notruth 91 "$S/shots_v2/${c}_scroll2_$v.png" > /dev/null 2>&1
  done
  for c in memo memowrap listbox listboxgrid checklist listview listviewicon treeview synedit; do
    BIN=$B "$S/run.sh" $c hv "" 91 > "$O/${c}_hv_truth.txt"; BIN=$B "$S/run.sh" $c hv notruth 91 > "$O/${c}_hv_notruth.txt"
  done
  for c in treeview synedit; do BIN=$B "$S/run.sh" $c hv notruth 91 "$S/shots_v2/${c}_scroll2_$v.png" > /dev/null 2>&1; done
  GSK=gl BIN=$B "$S/run.sh" custom hv notruth 91 > "$O/custom_hv_notruth_gl.txt"
  echo "done $v"
done
echo ALLEXP3DONE
