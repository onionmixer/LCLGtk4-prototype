#!/bin/bash
# rungate.sh [suffix]: Phase gate with the repo-linked binary (allocmatrix_gtk4) -> out_fixed<suffix>/ (same scenario set as
# runexp3.sh), out_fixed_all<suffix>/ (same set as runall.sh), shots_fixed<suffix>/. Prints the strict analysis and compares.
# Exit status: 1 when the strict analysis of the scrolling classes fails. (Give the suffix WITH its underscore, e.g. _H2.)
S=$(cd "$(dirname "$0")" && pwd); SUF=$1; O="$S/out_fixed$SUF"; A="$S/out_fixed_all$SUF"; SH="$S/shots_fixed$SUF"
mkdir -p "$O" "$SH"; RC=0
for c in custom scrollbox; do
  for m in "" notruth rehide inactivepage zero late hidden gtkscroll; do n=${m:-truth}; "$S/run.sh" $c hv "$m" 91 > "$O/${c}_hv_$n.txt"; done
  "$S/run.sh" $c hv notruth 91 "$SH/${c}_scroll2.png" > /dev/null 2>&1
  "$S/run.sh" $c hv gtkscroll 91 "$SH/${c}_gtkscroll.png" > /dev/null 2>&1
  "$S/run.sh" $c hv growmid 91 "$SH/${c}_growmid.png" > "$O/${c}_hv_growmid.txt"
done
for c in memo memowrap listbox listboxgrid checklist listview listviewicon treeview synedit; do
  "$S/run.sh" $c hv "" 91 > "$O/${c}_hv_truth.txt"; "$S/run.sh" $c hv notruth 91 > "$O/${c}_hv_notruth.txt"
done
for c in treeview synedit; do "$S/run.sh" $c hv notruth 91 "$SH/${c}_scroll2.png" > /dev/null 2>&1; "$S/run.sh" $c hv gtkscroll 91 "$SH/${c}_gtkscroll.png" > /dev/null 2>&1; "$S/run.sh" $c hv growmid 91 "$SH/${c}_growmid.png" > "$O/${c}_hv_growmid.txt"; done
for c in formscroll panel groupbox toolbar page statictext; do "$S/run.sh" $c hv notruth 91 "$SH/${c}_scroll2.png" > /dev/null 2>&1; done
GSK=gl "$S/run.sh" custom hv notruth 91 > "$O/custom_hv_notruth_gl.txt"
"$S/runall.sh" "$A" > "$S/runall_fixed$SUF.out" 2>&1
echo "=== strict (scroll classes) on $O"
python3 "$S/analyze.py" "$O" --strict '--include=^(custom|scrollbox|treeview|synedit|listview|listviewicon|listbox|listboxgrid|checklist|memo|memowrap)' | sed -n '/SUMMARY/,$p'
[ ${PIPESTATUS[0]} -eq 0 ] || RC=1; echo "strict exit=$([ $RC -eq 0 ] && echo 0 || echo 1)"
echo "=== compare out_v2 -> $O (logs with differing rows)"; python3 "$S/compare.py" "$S/out_v2" "$O" | grep "^+" | awk '{print $2}' | sort -u | tr '\n' ' '; echo
echo "=== compare out -> $A (logs with differing rows)"; python3 "$S/compare.py" "$S/out" "$A" | grep "^+" | awk '{print $2}' | sort -u | tr '\n' ' '; echo
echo "GATEDONE rc=$RC"; exit $RC
