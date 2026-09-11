#!/bin/bash
S=$(cd "$(dirname "$0")" && pwd)
for c in custom scrollbox memo listbox listview treeviewnohint synedit groupbox pagecontrol formscroll formmenu; do $S/run.sh gtk4 $c 71; echo "done gtk4 $c ok=$?"; done
echo ALLDONE
