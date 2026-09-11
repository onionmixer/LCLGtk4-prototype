#!/bin/bash
# build.sh <gtk4|gtk2|qt5> -> binary allocmatrix_<ws>
set -e
S=$(cd "$(dirname "$0")" && pwd); WS=$1
P=/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus
case $WS in
  gtk4|gtk2) LCLU=$P/lcl/units/x86_64-linux; LAZU=$P/components/lazutils/lib/x86_64-linux; FT=$P/components/freetype/lib/x86_64-linux; PK=$P/packager/units/x86_64-linux; DEF=-dLCL$WS ;;
  qt5) SYS=/usr/lib/lazarus/4.4; LCLU=$SYS/lcl/units/x86_64-linux; LAZU=$SYS/components/lazutils/lib/x86_64-linux; FT=$SYS/components/freetype/lib/x86_64-linux; PK=$SYS/packager/units/x86_64-linux; DEF=-dLCLqt5 ;;
esac
rm -rf $S/lib/$WS; mkdir -p $S/lib/$WS; rm -f $S/allocmatrix_$WS; cd $S
for i in 1 2; do
  fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq -dLCL $DEF \
    -Fu$LCLU/$WS -Fu$LCLU -Fu$P/components/synedit/units/x86_64-linux/$WS -Fu$LAZU -Fu$FT -Fu$PK -Fi$LCLU/../../include -Fi$LCLU/../.. -Fi$LCLU/../../interfaces/$WS \
    -FU$S/lib/$WS -FE$S -o$S/allocmatrix_$WS $S/allocmatrix.lpr > $S/build_$WS.log 2>&1 && break
done
grep -E 'Error|Fatal|lines compiled' $S/build_$WS.log | head -5
test -x $S/allocmatrix_$WS || { echo 'BUILD FAILED'; exit 1; }
