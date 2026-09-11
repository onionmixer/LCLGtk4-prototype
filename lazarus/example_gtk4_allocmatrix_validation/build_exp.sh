#!/bin/bash
# build_exp.sh <expdir> <suffix> -> allocmatrix_gtk4_<suffix> linked against gtk4 interface units recompiled
# from <expdir> (a patched copy of lcl/interfaces/gtk4); the repo's unit dir is never written to.
set -e
S=$(cd "$(dirname "$0")" && pwd); EXP=$1; SUF=$2
P=/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus
LCLU=$P/lcl/units/x86_64-linux; LAZU=$P/components/lazutils/lib/x86_64-linux; FT=$P/components/freetype/lib/x86_64-linux; PK=$P/packager/units/x86_64-linux
rm -rf $S/lib/gtk4_$SUF; mkdir -p $S/lib/gtk4_$SUF; rm -f $S/allocmatrix_gtk4_$SUF; cd $S
fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq -dLCL -dLCLgtk4 \
  -Fu$EXP -Fu$EXP/gtk4bindings -Fi$EXP -Fi$EXP/gtk4bindings \
  -Fu$LCLU/gtk4 -Fu$LCLU -Fu$P/components/synedit/units/x86_64-linux/gtk4 -Fu$LAZU -Fu$FT -Fu$PK -Fi$P/lcl/include -Fi$P/lcl -Fi$LCLU/../../interfaces/gtk4 \
  -FU$S/lib/gtk4_$SUF -FE$S -o$S/allocmatrix_gtk4_$SUF $S/allocmatrix.lpr > $S/build_gtk4_$SUF.log 2>&1 || { grep -E "Error|Fatal" $S/build_gtk4_$SUF.log | head -5; echo "BUILD FAILED ($SUF)"; exit 1; }
grep -E 'lines compiled' $S/build_gtk4_$SUF.log | head -1
ls $S/lib/gtk4_$SUF | grep -c ppu
test -x $S/allocmatrix_gtk4_$SUF || { echo "no binary"; exit 1; }
