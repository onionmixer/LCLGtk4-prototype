set pagination off
set breakpoint pending on
set language pascal
break gtk4widgets.pas:3082
commands
  silent
  if H > 5000
    set $kfixed := WIDGET
  end
  continue
end
run
echo === after SIGINT 1: allocation, then queue_resize ===\n
delete
set language c
print (int)gtk_widget_get_allocated_height((void*)$kfixed)
call (void)gtk_widget_queue_resize((void*)$kfixed)
continue
echo === after SIGINT 2 ===\n
print (int)gtk_widget_get_allocated_height((void*)$kfixed)
