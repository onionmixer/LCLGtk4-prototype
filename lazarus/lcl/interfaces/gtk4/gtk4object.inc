{%MainUnit gtk4int.pas}

{ TGtk4WidgetSet }

var
  Gtk4MPF: TGPollFunc;

function Gtk4PollFunction(ufds:PGPollFD; nfsd:guint; timeout:gint):gint; cdecl;
begin
  Result := 0;
  if TimeOut = -1 then
    Gtk4WidgetSet.FMainPoll := ufds
  else
    Gtk4WidgetSet.FMainPoll := nil;
  if Gtk4MPF <> nil then
    Result := Gtk4MPF(ufds, nfsd, timeout);
end;

{ GTK4: gtk_main removed. Events dispatched via GLib main context
  and GTK4 event controllers. No manual event loop procedure needed. }

{ ---- Caret support ---- }

function Gtk4CaretBlinkTimerCB(Data: gpointer): gboolean; cdecl;
var
  WS: TGtk4WidgetSet;
begin
  Result := G_SOURCE_CONTINUE;
  WS := TGtk4WidgetSet(Data);
  with WS.FCaret do
  begin
    if Timer = 0 then
    begin
      Result := G_SOURCE_REMOVE_;
      Exit;
    end;
    BlinkHide := not BlinkHide;
    WS.InvalidateCaret;
  end;
end;

procedure TGtk4WidgetSet.InvalidateCaret;
var
  AWidget: TGtk4Widget;
  AW: PGtkWidget;
begin
  with FCaret do
  begin
    if Handle = 0 then Exit;
    AWidget := TGtk4Widget(Handle);
    { Safety: verify the TGtk4Widget is still alive. During shutdown, a widget
      may be freed without calling DestroyCaret, leaving a dangling handle.
      The caret timer callback would then access freed memory → SIGSEGV. }
    if not Gtk4IsLiveWidgetPointer(AWidget) then
    begin
      Handle := 0;
      Exit;
    end;
    AW := AWidget.GetContainerWidget;
    if AW = nil then
      AW := AWidget.Widget;
    if (AW <> nil) and Gtk4IsWidget(AW) then
      AW^.queue_draw_area(X, Y, Width, Height);
  end;
end;

procedure TGtk4WidgetSet.DrawCaret(cr: Pcairo_t; AWidget: TGtk4Widget);
begin
  with FCaret do
  begin
    if Handle = 0 then Exit;
    if TGtk4Widget(Handle) <> AWidget then Exit;
    if not Visible then Exit;
    if BlinkHide then Exit;
    { GTK4 snapshot cairo: CAIRO_OPERATOR_DIFFERENCE zeroes alpha on opaque
      surfaces → caret invisible. Use explicit OVER with solid black instead. }
    cairo_save(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    cairo_set_source_rgba(cr, 0.0, 0.0, 0.0, 1.0);
    cairo_rectangle(cr, X, Y, Width, Height);
    cairo_fill(cr);
    cairo_restore(cr);
    IsDrawn := True;
  end;
end;

procedure TGtk4WidgetSet.StartCaretTimer;
begin
  with FCaret do
  begin
    if Timer <> 0 then Exit;
    if BlinkTime = 0 then
      BlinkTime := 530; { Default cursor blink time }
    Blinking := True;
    BlinkHide := False;
    Timer := g_timeout_add(BlinkTime, @Gtk4CaretBlinkTimerCB, Self);
  end;
end;

procedure TGtk4WidgetSet.StopCaretTimer;
begin
  with FCaret do
  begin
    if Timer <> 0 then
    begin
      g_source_remove(Timer);
      Timer := 0;
    end;
    Blinking := False;
    BlinkHide := False;
  end;
end;

{ ---- End caret support ---- }

function TGtk4WidgetSet.CreateThemeServices: TThemeServices;
begin
  Result := TGtk4ThemeServices.Create;
end;

procedure TGtk4WidgetSet.Gtk4Create;
var
  AGtkThread: PGThread;
  AId: String;
begin
  // GTK4: g_type_init removed (auto-init since GLib 2.36)
  // GTK4: gtk_init takes no arguments
  gtk4_init;
  { Patch GtkFixedLayout class vtable so children are allocated at their
    set_size_request values instead of intrinsic minimums. This prevents
    complex widgets (e.g., GtkNotebook) from overflowing their LCL bounds. }
  PatchGtkFixedLayoutClass;
  PatchGtkFixedSnapshotClass;
  AGtkThread := g_thread_self();
  if not IsLibrary then
  begin
  AId := 'org.lcl.thread_' + dbgHex({%H-}PtrUInt(AGtkThread));
  FGtk4Application := TGtkApplication.new(PgChar(AId), [G_APPLICATION_NON_UNIQUE]);
  // FGtk4Application^.set_application_id(PgChar(AId));
  FGtk4Application^.register(nil, nil);
  end;
  GTK4WidgetSet := Self;
end;

procedure TGtk4WidgetSet.Gtk4Destroy;
begin
  StopCaretTimer;
  FillChar(FCaret, SizeOf(FCaret), 0);

  Gtk4MPF := nil;
  GTK4WidgetSet := nil;
  WakeMainThread := nil;

  if Assigned(FAppIcon) then
    FAppIcon^.unref;
  FAppIcon := nil;
end;

procedure TGtk4WidgetSet.SetDefaultAppFontName;
var
  AValue: TGValue;
begin
  FillByte(AValue{%H-}, SizeOf(AValue), 0);
  AValue.init(G_TYPE_STRING);
  g_object_get_property(gtk_settings_get_default, 'gtk-font-name', @AValue);
  FDefaultAppFontName := AValue.get_string;
  AValue.unset;
end;

procedure TGtk4WidgetSet.InitSysColorBrushes;
var
  i: integer;
  LogBrush: TLogBrush;
begin
  LogBrush.lbHatch := 0;
  FillChar(LogBrush, SizeOf(TLogBrush), 0);
  for i := Low(FSysColorBrushes) to High(FSysColorBrushes) do
  begin
    LogBrush.lbColor := GetSysColor(i);
    FSysColorBrushes[i] := CreateBrushIndirect(LogBrush);
    TGtk4Brush(FSysColorBrushes[i]).Shared := True;
  end;
end;

procedure TGtk4WidgetSet.FreeSysColorBrushes;

  procedure DeleteAndNilObject(var h: HGDIOBJ);
  begin
    if h <> 0 then
      TGtk4Brush(h).Shared := False;
    DeleteObject(h);
    h := 0;
  end;

var
  i: Integer;
begin
  for i := Low(FSysColorBrushes) to High(FSysColorBrushes) do
    if FSysColorBrushes[i] <> HBRUSH(-1) then
      DeleteAndNilObject(FSysColorBrushes[i]);
end;

{$IFNDEF UNIX}
procedure TGtk4WidgetSet.DoWakeMainThread(Sender: TObject);
begin
  g_main_context_wakeup(g_main_context_default);
  CheckSynchronize;
end;
{$ENDIF}

function TGtk4WidgetSet.CreateDCForWidget(AWidget: PGtkWidget;
  AWindow: PGdkWindow; cr: Pcairo_t): HDC;
begin
  if AWindow <> nil then
  begin
    Result := HDC(TGtk4DeviceContext.Create(AWindow, False))
  end else
  begin
    if cr <> nil then
      Result := HDC(TGtk4DeviceContext.CreateFromCairo(AWidget, Cr))
    else
      Result := HDC(TGtk4DeviceContext.Create(AWidget, False));
  end;
  TGtk4DeviceContext(Result).CanRelease := True;
end;

procedure TGtk4WidgetSet.AddWindow(AWindow: PGtkWindow);
begin
  if Assigned(FGtk4Application) then
    FGtk4Application^.add_window(AWindow);
end;

{$IFDEF UNIX}
var
  threadsync_pipein, threadsync_pipeout: cint;
  threadsync_giochannel: pgiochannel;
  childsig_pending: boolean;

  procedure ChildEventHandler({%H-}sig: longint; {%H-}siginfo: psiginfo;
    {%H-}sigcontext: psigcontext); cdecl;
  begin
    childsig_pending := true;
    WakeMainThread(nil);
  end;

  procedure InstallSignalHandler;
  var
    child_action: sigactionrec;
  begin
    child_action.sa_handler := @ChildEventHandler;
    fpsigemptyset(child_action.sa_mask);
    child_action.sa_flags := 0;
    fpsigaction(SIGCHLD, @child_action, nil);
  end;

  function threadsync_iocallback({%H-}source: PGIOChannel; {%H-}condition: TGIOCondition;
    data: gpointer): gboolean; cdecl;
  var
    thrashspace: array[1..1024] of byte;
  begin
    // read the sent bytes
    fpread(threadsync_pipein, {%H-}thrashspace[1], 1);

    Result := true;
    // one of children signaled ?
    if childsig_pending then
    begin
      childsig_pending := false;
      TGtk4WidgetSet(data).ProcessChildSignal;
    end;
    // execute the to-be synchronized method
    if IsMultiThread then
      CheckSynchronize;
  end;

procedure TGtk4WidgetSet.InitSynchronizeSupport;
begin
  WakeMainThread := @PrepareSynchronize;
  assignpipe(threadsync_pipein, threadsync_pipeout);
  threadsync_giochannel := g_io_channel_unix_new(threadsync_pipein);
  g_io_add_watch(threadsync_giochannel, [G_IO_IN], @threadsync_iocallback, Self);
end;

procedure TGtk4WidgetSet.ProcessChildSignal;
var
  pid: tpid;
  reason: TChildExitReason;
  status: integer;
  info: dword;
  handler: PChildSignalEventHandler;
begin
  repeat
    status:=0;
    pid := fpwaitpid(-1, status, WNOHANG);
    if pid <= 0 then break;
    if wifexited(status) then
    begin
      reason := cerExit;
      info := wexitstatus(status);
    end else
    if wifsignaled(status) then
    begin
      reason := cerSignal;
      info := wtermsig(status);
    end else
      continue;

    handler := FChildSignalHandlers;
    while handler <> nil do
    begin
      if handler^.pid = pid then
      begin
        handler^.OnEvent(handler^.UserData, reason, info);
        break;
      end;
      handler := handler^.NextHandler;
    end;
  until false;
end;

procedure TGtk4WidgetSet.PrepareSynchronize(AObject: TObject);
var
  thrash: char;
begin
  // wake up GUI thread by sending a byte through the threadsync pipe
  thrash:='l';
  fpwrite(threadsync_pipeout, thrash, 1);
end;
{$ENDIF}

constructor TGtk4WidgetSet.Create;
var
  i: Integer;
begin
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow, exUnderflow, exPrecision]);
  inherited Create;
  FCSSTheme := TStringList.Create;
  FThemeName := '';
  FTimerData := TFPList.Create;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('** TGtk4WidgetSet.Create **');
  {$ENDIF}
  Gtk4Create;
  FMainPoll := nil;
  Gtk4MPF := g_main_context_get_poll_func(g_main_context_default);
  g_main_context_set_poll_func(g_main_context_default, @Gtk4PollFunction);

  // GTK4: gdk_event_handler_set removed. Event controllers handle dispatch.

  {$IFDEF UNIX}
  InitSynchronizeSupport;
  // InstallSignalHandler;
  {$ELSE}
  WakeMainThread := @DoWakeMainThread;
  {$ENDIF}
  CharSetEncodingList := TList.Create;
  CreateDefaultCharsetEncodings;
  // GTK4: 'gtk-button-images' property removed

  FGlobalCursor := 0;
  FAppIcon := nil;
  FStockNullBrush := 0;
  FStockBlackBrush := 0;
  FStockLtGrayBrush := 0;
  FStockGrayBrush := 0;
  FStockDkGrayBrush := 0;
  FStockWhiteBrush := 0;

  FStockNullPen := 0;
  FStockBlackPen := 0;
  FStockWhitePen := 0;
  FStockSystemFont := 0;
  FStockDefaultDC := 0;

  Styles := TStringList.Create;

  InitStockItems;
  // initialize default app font name
  SetDefaultAppFontName;
  for i := Low(FSysColorBrushes) to High(FSysColorBrushes) do
    FSysColorBrushes[i] := HBRUSH(-1);

  cssProvider := gtk_css_provider_new();
  if FileExists('theme.css') then
    gtk4_css_provider_load_from_path(cssProvider, PgChar('theme.css'));
  // GTK4: uses display instead of screen
  gtk4_style_context_add_provider_for_display(gdk4_display_get_default(),
                               PGtkStyleProvider(cssProvider),
                               GTK_STYLE_PROVIDER_PRIORITY_USER);

  { LCL default CSS rules (display-level, lower priority than user theme) }
  FLclCssProvider := gtk_css_provider_new();
  gtk_css_provider_load_from_data(FLclCssProvider, PgChar(
    { GTK4 Adwaita theme sets entry min-height: 32px which prevents entries from
      fitting in tight spaces (e.g., Object Inspector 25px rows). LCL manages
      widget sizes via set_size_request/size_allocate, so remove this constraint. }
    'entry { min-height: 0; padding-top: 2px; padding-bottom: 2px; } '
    + 'entry > text { min-height: 0; } '
    { HideSelection: make selection invisible when widget is unfocused }
    + '.lcl-hide-sel:not(:focus-within) selection { background-color: transparent; color: inherit; } '
    { Suppress overshoot/undershoot/junction visual artifacts in GtkScrolledWindow }
    + 'undershoot, overshoot { background: none; } '
    + 'scrolledwindow junction { background: none; } '
    { TStaticText.BorderStyle: GTK4 removed GtkFrame set_shadow_type, so drive
      the frame border with CSS classes instead (see TGtk4StaticText).
      sbsSingle keeps the theme's own frame border (consistent, theme-coloured);
      only sbsNone (suppress) and sbsSunken (inset) need explicit rules. }
    + '.lcl-static-none { border-style: none; } '
    + '.lcl-static-sunken { border-style: inset; border-width: 2px; } '
  ), -1, nil);
  gtk4_style_context_add_provider_for_display(gdk4_display_get_default(),
                               PGtkStyleProvider(FLclCssProvider),
                               GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
end;

destructor TGtk4WidgetSet.Destroy;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('** TGtk4WidgetSet.Destroy **');
  {$ENDIF}
  { Deferred GtkApplication cleanup — safe because RunLoop has already exited.
    Do NOT call release here: each gtk_window_destroy already calls
    g_application_release via gtk_window_release_application (GTK4 source:
    gtkwindow.c). Calling release without a matching hold causes the
    'use_count > 0' assertion failure. }
  if Assigned(FGtk4Application) then
  begin
    FGtk4Application^.quit;
    FGtk4Application^.unref;
    FGtk4Application := nil;
  end;
  if Assigned(cssProvider) and Gtk4IsObject(PGObject(cssProvider)) then
    cssProvider^.unref;
  cssProvider := nil;
  if Assigned(FLclCssProvider) and Gtk4IsObject(PGObject(FLclCssProvider)) then
    FLclCssProvider^.unref;
  FLclCssProvider := nil;
  ReleaseAllStyles;
  Styles.Free;
  Styles := nil;
  FreeStockItems;
  Gtk4Destroy;
  FTimerData.Free;
  Gtk4DefaultContext.Free;
  Gtk4ScreenContext.Free;
  if Assigned(CharSetEncodingList) then
  begin
    ClearCharsetEncodings;
    FreeAndNil(CharSetEncodingList);
  end;
  FreeSysColorBrushes;
  FCSSTheme.Free;
  FStayOnTopList.Free;
  inherited Destroy;
end;

function TGtk4WidgetSet.LCLPlatform: TLCLPlatform;
begin
  Result := lpGtk4;
end;

procedure TGtk4WidgetSet.AppInit(var ScreenInfo: TScreenInfo);
//var
//  AId: String;
var
  ScreenDC: HDC;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WidgetSet.AppInit');
  {$ENDIF}
  ScreenDC := GetDC(0);
  try
    ScreenInfo.PixelsPerInchX := GetDeviceCaps(ScreenDC, LOGPIXELSX);
    ScreenInfo.PixelsPerInchY := GetDeviceCaps(ScreenDC, LOGPIXELSY);
    ScreenInfo.ColorDepth := GetDeviceCaps(ScreenDC, BITSPIXEL);
  finally
    ReleaseDC(0, ScreenDC);
  end;
end;

procedure TGtk4WidgetSet.LoadCSSTheme;
var
  ACSSProvider: PGtkCssProvider;
  ASettings: PGtkSettings;
  AValue: TGValue;
  cStr: Pgchar;
begin
  ASettings := gtk_settings_get_default;
  FillByte(AValue{%H-}, SizeOf(AValue), 0);
  AValue.init(G_TYPE_STRING);
  ASettings^.get_property('gtk-theme-name', @AValue);
  FThemeName := AValue.get_string;
  AValue.unset;
  // GTK4: gtk_css_provider_get_named removed, use load_named
  ACSSProvider := gtk_css_provider_new();
  gtk_css_provider_load_from_data(ACSSProvider, PgChar('* {}'), -1, nil);
  { System colors are now extracted via GtkStyleContext in UpdateSysColorMap,
    which is called from GetStyleWithName for each style widget type. }
  { gtk_css_provider_to_string returns a newly-allocated string — must g_free }
  cStr := gtk_css_provider_to_string(ACSSProvider);
  FCSSTheme.Text := cStr;
  g_free(cStr);
  ACSSProvider^.unref;
end;

procedure TGtk4WidgetSet.ClearCSSTheme;
begin
  FCSSTheme.Clear;
end;

function TGtk4WidgetSet.GetCSSTheme(AList: TStrings): boolean;
begin
  Result := FCSSTheme.Count > 0;
  if not Result then
    LoadCSSTheme;
  AList.Assign(FCSSTheme);
end;

function TGtk4WidgetSet.GetThemeName: string;
begin
  if FThemeName = '' then
    LoadCSSTheme;
  Result := FThemeName;
end;

procedure TGtk4WidgetSet.AppRun(const ALoop: TApplicationMainLoop);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WidgetSet.AppRun');
  {$ENDIF}
  if Assigned(ALoop) then
    ALoop;
end;

procedure TGtk4WidgetSet.AppWaitMessage;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WidgetSet.AppWaitMessage');
  {$ENDIF}
  // GTK4: gtk_main_iteration removed, use GLib main context
  g_main_context_iteration(g_main_context_default, True);
end;

procedure TGtk4WidgetSet.AppProcessMessages;
const
  MAX_MAIN_CONTEXT_DRAIN = 10000;
var
  IterCount: Integer;
  Pending: gboolean;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WidgetSet.AppProcessMessages');
  {$ENDIF}
  // GTK4: gtk_events_pending/gtk_main_iteration_do removed
  Pending := g_main_context_pending(g_main_context_default);
  IterCount := 0;
  while Pending do
  begin
    g_main_context_iteration(g_main_context_default, False);
    Inc(IterCount);
    if IterCount >= MAX_MAIN_CONTEXT_DRAIN then
      Break;
    Pending := g_main_context_pending(g_main_context_default);
  end;
  { GTK4: Process deferred mouse events AFTER g_main_context_iteration has
    fully returned. This ensures we are outside GLib event dispatch, so if
    a deferred click triggers a modal dialog, DoExecute's nested event loop
    can call g_main_context_iteration without re-entrancy. }
  ProcessGtk4DeferredMouseEvents;
end;

procedure TGtk4WidgetSet.AppTerminate;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WidgetSet.AppTerminate');
  {$ENDIF}
  { Do NOT destroy GtkApplication here.
    AppTerminate is called from inside g_main_context_iteration (via timer/event
    callback).  Destroying the application while the GLib main context still
    references its event sources causes AppProcessMessages' pending-event loop
    to hang on orphaned sources.
    Cleanup is deferred to Destroy, which runs after RunLoop has exited. }
end;


procedure TGtk4WidgetSet.AppMinimize;
var
  i: Integer;
  AForm: TCustomForm;
  W: TGtk4Widget;
begin
  if Screen=nil then exit;
  for i:= 0 to Screen.CustomFormZOrderCount-1 do
  begin
    AForm := Screen.CustomFormsZOrdered[i];
    if (AForm.Parent=nil) and AForm.HandleAllocated and
      (TGtk4Widget(AForm.Handle).Visible) and
      not (AForm.FormStyle in [fsMDIChild, fsSplash]) and
      not (AForm.BorderStyle in [bsNone]) then
      begin
        W := TGtk4Widget(AForm.Handle);
        // GTK4: iconify removed, use minimize
        gtk4_window_minimize(PGtkWindow(W.Widget));
      end;
  end;
end;


procedure TGtk4WidgetSet.AppRestore;
var
  i: Integer;
  AForm: TCustomForm;
begin
  if Screen=nil then exit;
  for i:= Screen.CustomFormZOrderCount-1 downto 0 do
  begin
    AForm:=Screen.CustomFormsZOrdered[i];
    if (AForm.Parent=nil) and AForm.HandleAllocated and
      (TGtk4Widget(AForm.Handle).Visible) and
      not (AForm.FormStyle in [fsMDIChild, fsSplash]) and
      not (AForm.BorderStyle in [bsNone]) then
        { GTK4: deiconify removed. Use unminimize instead of present().
          present() both raises AND focuses the window, causing focus bouncing
          between multiple windows. unminimize only restores from minimized
          state without stealing focus (matches GTK2's deiconify behavior). }
        gtk_window_unminimize(PGtkWindow(TGtk4Window(AForm.Handle).Widget));
  end;
end;

procedure TGtk4WidgetSet.AppBringToFront;
begin
  if Assigned(Application.MainForm) and Application.MainForm.HandleAllocated then
  begin
    // GTK4: gdk_window_focus removed, use present
    if Gtk4WindowCanPresent(TGtk4Window(Application.MainForm.Handle)) then
      PGtkWindow(TGtk4Window(Application.MainForm.Handle).Widget)^.present;
  end;
end;
procedure TGtk4WidgetSet.AppSetIcon(const Small, Big: HICON);
var
  DoDestroyIcon: Boolean;
  AIcon: PGdkPixbuf;
begin
  DoDestroyIcon := Big = 0;
  if DoDestroyIcon then
  begin
    if Assigned(FAppIcon) then
      FAppIcon^.unref;
    FAppIcon := nil;
  end else
  begin
    AIcon := TGtk4Image(Big).Handle;
    FAppIcon := PGdkPixbuf(AIcon)^.copy;
  end;
end;

procedure TGtk4WidgetSet.AppSetTitle(const ATitle: string);
begin
  if Assigned(Application.MainForm) and (Application.MainForm.HandleAllocated) then
  begin
    TGtk4Window(Application.MainForm.Handle).Title := ATitle;
  end;
end;

function TGtk4WidgetSet.AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean
  ): Boolean;
var
  i: Integer;
  AForm: TCustomForm;
  W: PGtkWindow;
  TopForms: set of TFormStyle;
begin
  Result := True;
  if Screen = nil then Exit;
  if FStayOnTopList = nil then
    FStayOnTopList := TFPList.Create;

  if ASystemTopAlso then
    TopForms := fsAllStayOnTop
  else
    TopForms := fsAllNonSystemStayOnTop;

  for i := 0 to Screen.CustomFormZOrderCount - 1 do
  begin
    AForm := Screen.CustomFormsZOrdered[i];
    if AForm.HandleAllocated and (AForm.Parent = nil) and
      not (csDesigning in AForm.ComponentState) and
      (AForm.FormStyle in TopForms) and
      TGtk4Widget(AForm.Handle).Visible and
      not PGtkWindow(TGtk4Widget(AForm.Handle).Widget)^.get_modal then
    begin
      W := PGtkWindow(TGtk4Widget(AForm.Handle).Widget);
      if FStayOnTopList.IndexOf(W) < 0 then
        FStayOnTopList.Add(W);
      { GTK4 4.6 has no gtk_window_set_keep_above (added in later versions).
        Modal dialogs use set_modal+set_transient_for which ensures they
        appear above parent windows without needing to lower stay-on-top. }
    end;
  end;
end;

function TGtk4WidgetSet.AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean
  ): Boolean;
var
  i: Integer;
  AForm: TCustomForm;
  W: PGtkWindow;
  TopForms: set of TFormStyle;
begin
  Result := True;
  if (Screen = nil) or (FStayOnTopList = nil) then Exit;

  if ASystemTopAlso then
    TopForms := fsAllStayOnTop
  else
    TopForms := fsAllNonSystemStayOnTop;

  for i := Screen.CustomFormZOrderCount - 1 downto 0 do
  begin
    AForm := Screen.CustomFormsZOrdered[i];
    if AForm.HandleAllocated and (AForm.Parent = nil) and
      not (csDesigning in AForm.ComponentState) and
      (AForm.FormStyle in TopForms) and
      TGtk4Widget(AForm.Handle).Visible and
      not PGtkWindow(TGtk4Widget(AForm.Handle).Widget)^.get_modal then
    begin
      W := PGtkWindow(TGtk4Widget(AForm.Handle).Widget);
      if FStayOnTopList.IndexOf(W) >= 0 then
      begin
        { GTK4 4.6 has no gtk_window_set_keep_above (added in later versions).
          Do NOT call present() here — it both raises AND focuses the window,
          causing focus bouncing between stay-on-top windows like Object
          Inspector and Main Window. The windows are already visible. }
      end;
    end;
  end;

  FreeAndNil(FStayOnTopList);
end;

function TGtk4WidgetSet.CreateStandardCursor(ACursor: SmallInt): HCURSOR;
const
  { Map LCL cursor constants (crLow=-30 .. crHigh=0) to GTK4 CSS cursor names.
    Array indexed by TCursor value. nil = unsupported/unused. }
  CursorNames: array[crLow..crHigh] of PgChar = (
    'se-resize',    // crSizeSE    = -30
    's-resize',     // crSizeS     = -29
    'sw-resize',    // crSizeSW    = -28
    'e-resize',     // crSizeE     = -27
    'w-resize',     // crSizeW     = -26
    'ne-resize',    // crSizeNE    = -25
    'n-resize',     // crSizeN     = -24
    'nw-resize',    // crSizeNW    = -23
    'move',         // crSizeAll   = -22
    'pointer',      // crHandPoint = -21
    'help',         // crHelp      = -20
    'progress',     // crAppStart  = -19
    'not-allowed',  // crNo        = -18
    'progress',     // crSQLWait   = -17
    'grab',         // crMultiDrag = -16
    'row-resize',   // crVSplit    = -15
    'col-resize',   // crHSplit    = -14
    'no-drop',      // crNoDrop    = -13
    'grabbing',     // crDrag      = -12
    'wait',         // crHourGlass = -11
    'n-resize',     // crUpArrow   = -10
    'ew-resize',    // crSizeWE    = -9
    'nwse-resize',  // crSizeNWSE  = -8
    'ns-resize',    // crSizeNS    = -7
    'nesw-resize',  // crSizeNESW  = -6
    nil,            // -5 (unused)
    'text',         // crIBeam     = -4
    'crosshair',    // crCross     = -3
    'default',      // crArrow     = -2
    'none',         // crNone      = -1
    'default'       // crDefault   = 0
  );
var
  ACssName: PgChar;
  AGdkCursor: PGdkCursor;
begin
  Result := 0;
  if (ACursor < crLow) or (ACursor > crHigh) then Exit;
  ACssName := CursorNames[TCursor(ACursor)];
  if ACssName = nil then Exit;
  AGdkCursor := gdk4_cursor_new_from_name(ACssName, nil);
  if AGdkCursor <> nil then
    Result := HCURSOR(PtrUInt(AGdkCursor));
end;

function TGtk4WidgetSet.DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor;
begin
  if IsValidDC(CanvasHandle) then
    Result := TGtk4DeviceContext(CanvasHandle).getPixel(X, Y)
  else
    Result := 0;
end;

procedure TGtk4WidgetSet.DCSetPixel(CanvasHandle: HDC; X, Y: Integer; AColor: TGraphicsColor);
begin
  if IsValidDC(CanvasHandle) then
    TGtk4DeviceContext(CanvasHandle).drawPixel(X, Y, AColor);
end;

procedure TGtk4WidgetSet.DCRedraw(CanvasHandle: HDC);
var
  AWidget: PGtkWidget;
begin
  if not IsValidDC(CanvasHandle) then Exit;
  AWidget := TGtk4DeviceContext(CanvasHandle).Parent;
  if (AWidget <> nil) and Gtk4IsWidget(PGObject(AWidget)) then
    AWidget^.queue_draw;
end;

procedure TGtk4WidgetSet.DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean
  );
begin
  // inherited DCSetAntialiasing(CanvasHandle, AEnabled);
  if IsValidDC(CanvasHandle) then
  begin
    TGtk4DeviceContext(CanvasHandle).set_antialiasing(AEnabled);
  end;
end;

procedure TGtk4WidgetSet.SetDesigning(AComponent: TComponent);
begin
  // inherited SetDesigning(AComponent);
end;

function gtk4TimerProc(Data: gPointer): gBoolean; cdecl;
var
  TimerInfo: PGtkITimerinfo;
begin
  Result := False;

  TimerInfo := PGtkITimerinfo(Data);

  if (FTimerData = nil) or (FTimerData.IndexOf(Data)<0) then
  begin
    Result := False // timer was killed
  end else
  begin
    if TimerInfo^.TimerFunc <> nil then
    begin
      TimerInfo^.TimerFunc;
      Result := True; // timer will go on
    end else
    begin
      Result := False; // stop timer
    end;
  end;

  if Result and (FTimerData.IndexOf(Data)<0) then
  begin
    // timer was killed
    // -> stop timer
    Result := False;
  end;
end;

procedure gtk4TimerDestroyed(Data: gPointer); cdecl;
var
  TimerInfo: PGtkITimerinfo;
begin
  if (FTimerData <> nil) and Assigned(Data) and
    (FTimerData.IndexOf(Data) >= 0) then
  begin
    TimerInfo := PGtkITimerinfo(Data);
    FTimerData.Remove(Data);
    Dispose(TimerInfo);
  end;
end;

function TGtk4WidgetSet.CreateTimer(Interval: integer; TimerFunc: TWSTimerProc
  ): TLCLHandle;
var
  TimerInfo: PGtkITimerinfo;
begin
  if ((Interval < 1) or (not Assigned(TimerFunc)))
  then
    Result := 0
  else begin
    New(TimerInfo);
    FillByte(TimerInfo^,SizeOf(TGtkITimerinfo),0);
    TimerInfo^.TimerFunc := TimerFunc;
    {$IFDEF VerboseTimer}
    DebugLn(['TGtk4WidgetSet.CreateTimer Interval=',dbgs(Interval)]);
    {$ENDIF}
    Result:=g_timeout_add(Interval, @gtk4TimerProc, TimerInfo);
    if Result = 0 then
      Dispose(TimerInfo)
    else begin
      TimerInfo^.TimerFunc := TimerFunc;
      TimerInfo^.TimerHandle:=Result;
      FTimerData.Add(TimerInfo);
    end;
  end;
end;

function TGtk4WidgetSet.DestroyTimer(TimerHandle: TLCLHandle): boolean;
var
  n: integer;
  TimerInfo: PGtkITimerinfo;
begin
  Result := False;
  n := FTimerData.Count;
  while (n > 0) do
  begin
    dec (n);
    TimerInfo := PGtkITimerinfo(FTimerData.Items[n]);
    if (TimerInfo^.TimerHandle = guint(TimerHandle)) then
    begin
      // in gtk4 timeout is automatically removed
      // g_timeout_remove(TimerInfo^.TimerHandle);
      g_source_remove(TimerInfo^.TimerHandle);
      TimerInfo^.TimerHandle := 0;
      FTimerData.Delete(n);
      Dispose(TimerInfo);
    end;
  end;
  Result := True;
end;

function TGtk4WidgetSet.IsValidDC(const DC: HDC): Boolean;
begin
  Result := DC <> 0;
end;

function TGtk4WidgetSet.IsValidGDIObject(const AGdiObject: HGDIOBJ): Boolean;
begin
  Result := (AGdiObject <> 0) and (TObject(AGdiObject) is TGtk4ContextObject);
end;

function TGtk4WidgetSet.IsValidHandle(const AHandle: HWND): Boolean;
begin
  { A handle is an HWND-cast TGtk4Widget pointer. Checking only AHandle<>0 (the
    old behaviour) reported freed widgets as valid, so any winapi function that
    then dereferenced TGtk4Widget(Handle).Widget could segfault on a stale
    handle (e.g. GetProp via FindControl(GetFocus) during editor autosize).
    Validate against the live-widget registry instead — the same approach as
    qt5 (TQtWidgetSet.IsValidHandle -> SavedHandlesList.HasId). Every
    TGtk4Widget registers in its ctor and unregisters in its dtor, so a pointer
    absent from the registry is either freed or never a widget. }
  Result := Gtk4IsLiveWidgetPointer(Pointer(AHandle));
end;

procedure TGtk4WidgetSet.InitStockItems;
var
  LogBrush: TLogBrush;
  logPen : TLogPen;
begin
  FillChar(LogBrush{%H-},SizeOf(TLogBrush),0);
  LogBrush.lbStyle := BS_NULL;
  FStockNullBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockNullBrush).Shared := True;

  LogBrush.lbStyle := BS_SOLID;
  LogBrush.lbColor := $000000;
  FStockBlackBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockBlackBrush).Shared := True;

  LogBrush.lbColor := $C0C0C0;
  FStockLtGrayBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockLtGrayBrush).Shared := True;

  LogBrush.lbColor := $808080;
  FStockGrayBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockGrayBrush).Shared := True;

  LogBrush.lbColor := $404040;
  FStockDkGrayBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockDkGrayBrush).Shared := True;

  LogBrush.lbColor := $FFFFFF;
  FStockWhiteBrush := CreateBrushIndirect(LogBrush);
  TGtk4Brush(FStockWhiteBrush).Shared := True;

  LogPen.lopnStyle := PS_NULL;
  LogPen.lopnWidth := Point(0, 0); // create cosmetic pens
  LogPen.lopnColor := $FFFFFF;
  FStockNullPen := CreatePenIndirect(LogPen);
  TGtk4Pen(FStockNullPen).Shared := True;

  LogPen.lopnStyle := PS_SOLID;
  FStockWhitePen := CreatePenIndirect(LogPen);
  TGtk4Pen(FStockWhitePen).Shared := True;

  LogPen.lopnColor := $000000;
  FStockBlackPen := CreatePenIndirect(LogPen);
  TGtk4Pen(FStockBlackPen).Shared := True;

  FStockSystemFont := 0; // styles aren't initialized yet

  FStockDefaultDC := 0; // app must be initialized
end;

procedure TGtk4WidgetSet.FreeStockItems;
  procedure DeleteAndNilObject(var h: HGDIOBJ);
  begin
    if h <> 0 then
      TGtk4ContextObject(h).Shared := False;
    DeleteObject(h);
    h := 0;
  end;
begin
  DeleteAndNilObject(FStockNullBrush);
  DeleteAndNilObject(FStockBlackBrush);
  DeleteAndNilObject(FStockLtGrayBrush);
  DeleteAndNilObject(FStockGrayBrush);
  DeleteAndNilObject(FStockDkGrayBrush);
  DeleteAndNilObject(FStockWhiteBrush);

  DeleteAndNilObject(FStockNullPen);
  DeleteAndNilObject(FStockBlackPen);
  DeleteAndNilObject(FStockWhitePen);

  DeleteAndNilObject(FStockSystemFont);
end;

function TGtk4WidgetSet.CreateDefaultFont: HFONT;
var
  AFont: TGtk4Font;
  cr: Pcairo_t;
  surface: Pcairo_surface_t;
begin
  Result := 0;
  // GTK4: gdk_cairo_create/gdk_get_default_root_window removed
  // Use a temporary cairo image surface for font creation
  surface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
  cr := cairo_create(surface);
  AFont := TGtk4Font.Create(cr, nil);
  cairo_destroy(cr);
  cairo_surface_destroy(surface);
  Result := HFONT(AFont);
end;
