set pagination off
set breakpoint pending on
break 'GTK4WIDGETS$_$TGTK4WIDGET_$__$$_SETBOUNDS$LONGINT$LONGINT$LONGINT$LONGINT'
commands
  silent
  printf "ORDER SetBounds\n"
  continue
end
break 'GTK4INT$_$TGTK4WIDGETSET_$__$$_SETSCROLLINFO$HWND$LONGINT$TAGSCROLLINFO$BOOLEAN$$LONGINT'
commands
  silent
  printf "ORDER SetScrollInfo\n"
  continue
end
break gtk_widget_queue_resize
commands
  silent
  printf "ORDER queue_resize %p\n", $rdi
  continue
end
break gtk_widget_set_size_request
commands
  silent
  printf "ORDER set_size_request %p %ld %ld\n", $rdi, $rsi, $rdx
  continue
end
run
