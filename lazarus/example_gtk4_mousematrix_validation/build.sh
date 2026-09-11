#!/bin/bash
# build.sh <gtk4|gtk2|qt5> -> binary mousematrix_<ws> (link only against prebuilt units; gtk2 has no SynEdit units)
set -e
S=$(cd "$(dirname "$0")" && pwd); WS=$1
P=/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus
case $WS in
  gtk4|gtk2) WSDIR=$WS; LCLU=$P/lcl/units/x86_64-linux; LAZU=$P/components/lazutils/lib/x86_64-linux; FT=$P/components/freetype/lib/x86_64-linux; PK=$P/packager/units/x86_64-linux; SYN=$P/components/synedit/units/x86_64-linux/$WS; DEF=-dLCL$WS ;;
  gtk4sys) SYS=/usr/lib/lazarus/4.4; LCLU=$SYS/lcl/units/x86_64-linux; LAZU=$SYS/components/lazutils/lib/x86_64-linux; FT=$SYS/components/freetype/lib/x86_64-linux; PK=$SYS/packager/units/x86_64-linux; SYN=$SYS/components/synedit/units/x86_64-linux/gtk4; DEF=-dLCLgtk4; WSDIR=gtk4 ;;
  qt5) SYS=/usr/lib/lazarus/4.4; LCLU=$SYS/lcl/units/x86_64-linux; LAZU=$SYS/components/lazutils/lib/x86_64-linux; FT=$SYS/components/freetype/lib/x86_64-linux; PK=$SYS/packager/units/x86_64-linux; SYN=$SYS/components/synedit/units/x86_64-linux/qt5; DEF=-dLCLqt5; WSDIR=qt5 ;;
esac
rm -rf $S/lib/$WS; mkdir -p $S/lib/$WS; rm -f $S/mousematrix_$WS; cd $S
for i in 1 2; do
  fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq -dLCL $DEF \
    -Fu$LCLU/$WSDIR -Fu$LCLU -Fu$SYN -Fu$LAZU -Fu$FT -Fu$PK -Fi$LCLU/../../include -Fi$LCLU/../.. -Fi$LCLU/../../interfaces/$WSDIR \
    -FU$S/lib/$WS -FE$S -o$S/mousematrix_$WS $S/mousematrix.lpr > $S/build_$WS.log 2>&1 && break
done
grep -E 'Error|Fatal|lines compiled' $S/build_$WS.log | head -5
test -x $S/mousematrix_$WS || { echo "BUILD FAILED ($WS)"; exit 1; }
