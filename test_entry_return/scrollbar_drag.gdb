set pagination off
set breakpoint pending on
set language pascal
dprintf 'KMEMO$_$TKCUSTOMMEMO_$__$$_MOUSEDOWN$TMOUSEBUTTON$TSHIFTSTATE$LONGINT$LONGINT',"### KMemo.MouseDown x=%d y=%d\n", X, Y
dprintf 'KMEMO$_$TKCUSTOMMEMO_$__$$_MOUSEUP$TMOUSEBUTTON$TSHIFTSTATE$LONGINT$LONGINT',"### KMemo.MouseUp x=%d y=%d\n", X, Y
dprintf 'KMEMO$_$TKCUSTOMMEMO_$__$$_MOUSEMOVE$TSHIFTSTATE$LONGINT$LONGINT',"### KMemo.MouseMove x=%d y=%d\n", X, Y
run
