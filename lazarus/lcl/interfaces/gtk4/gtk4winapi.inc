{%MainUnit gtk4int.pas}

function TGtk4WidgetSet.Arc(DC: HDC; Left, top, right, bottom, angle1,
  angle2: Integer): Boolean;
begin
  Result := IsValidDC(DC);
  if not Result then Exit;
  TGtk4DeviceContext(DC).drawArc(Left, Top, Right, Bottom, angle1, angle2);
end;

function TGtk4WidgetSet.AngleChord(DC: HDC; x1, y1, x2, y2, angle1,
  angle2: Integer): Boolean;
var
  ctx: TGtk4DeviceContext;
  bFill, bBorder: Boolean;
begin
  Result := IsValidDC(DC);
  if not Result then Exit;
  ctx := TGtk4DeviceContext(DC);
  bFill := ctx.CurrentBrush.Style <> BS_NULL;
  bBorder := ctx.CurrentPen.Style <> psClear;
  if not (bFill or bBorder) then Exit;
  ctx.drawChord(x1, y1, x2, y2, angle1, angle2, bFill, bBorder);
end;

function TGtk4WidgetSet.BeginPaint(Handle: hWnd; var PS: TPaintStruct): hdc;
var
  Widget: TGtk4Widget;
  GtkWidget: PGtkWidget;
  DC: TGtk4DeviceContext;
begin
  Widget := TGtk4Widget(Handle);
  if Widget <> nil then
  begin
    GtkWidget := Widget.GetContainerWidget;
    if Widget.CairoContext <> nil then
      DC := TGtk4DeviceContext.CreateFromCairo(GtkWidget, Widget.CairoContext)
    else
      DC := TGtk4DeviceContext.Create(GtkWidget, True);
  end
  else
    DC := TGtk4DeviceContext.Create(PGtkWidget(nil), True);

  PS.hdc := HDC(DC);

  if Handle<>0 then
  begin
    DC.vClipRect := Widget.PaintData.ClipRect^;
  end;

  Result := PS.hdc;
end;

function TGtk4WidgetSet.BitBlt(DestDC: HDC; X, Y, Width, Height: Integer;
  SrcDC: HDC; XSrc, YSrc: Integer; Rop: DWORD): Boolean;
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('Trace:> [TGtk4WidgetSet.BitBlt]');
  {$endif}
  Result := StretchBlt(DestDC, X, Y, Width, Height, SrcDC, XSrc, YSrc, Width,
                       Height, ROP);

  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('Trace:< [TGtk4WidgetSet.BitBlt]');
  {$endif}
end;

function TGtk4WidgetSet.CallNextHookEx(hHk: HHOOK; ncode: Integer;
  wParam: WParam; lParam: LParam): Integer;
begin
  { Windows hook chains not applicable to GTK4. }
  Result := inherited CallNextHookEx(hHk, ncode, wParam, lParam);
end;

function TGtk4WidgetSet.CallWindowProc(lpPrevWndFunc: TFarProc; Handle: HWND;
  Msg: UINT; wParam: WParam; lParam: lParam): Integer;
var
  Proc: TWndMethod;
  LMsg: TLMessage;
  P: Pointer;
  AWidget: PGtkWidget;
begin
  Result := -1;
  if not IsValidHandle(Handle) then
    Exit;
  AWidget := TGtk4Widget(Handle).Widget;
  if AWidget = nil then
    Exit;
  P := g_object_get_data(PGObject(AWidget), 'lclwndproc');
  if P = nil then
    Exit;
  Proc := TWndMethod(P^);
  LMsg.msg := Msg;
  LMsg.lParam := lParam;
  LMsg.wParam := wParam;
  Proc(LMsg);
  Result := LMsg.Result;
end;

function TGtk4WidgetSet.ClientToScreen(Handle: HWND; var P: TPoint): Boolean;
begin
  {$ifdef VerboseGtk4WinApi}
    DebugLn('Trace:> [TGtk4WidgetSet.ClientToScreen] ',dbgs(P));
  {$endif}
  Result := False;
  if IsValidHandle(Handle) then
    Result := TGtk4Widget(Handle).ClientToScreen(P);
  {$ifdef VerboseGtk4WinApi}
    DebugLn('Trace:< [TGtk4WidgetSet.ClientToScreen] ',dbgs(P),' result=',dbgs(Result));
  {$endif}
end;

function TGtk4WidgetSet.ClipboardFormatNeedsNullByte(
  const AFormat: TPredefinedClipboardFormat): Boolean;
begin
  Result := False;
end;

function TGtk4WidgetSet.ClipboardFormatToMimeType(FormatID: TClipboardFormat
  ): string;
var
  p: PgChar;
begin
  { GTK4: Format IDs are GQuarks from mime type strings }
  if FormatID <> 0 then
  begin
    p := g_quark_to_string(TGQuark(FormatID));
    if p <> nil then
      Result := string(p)
    else
      Result := '';
  end
  else
    Result := '';
end;

{ Helper: get the GdkClipboard for a TClipboardType }
function Gtk4GetClipboard(ClipboardType: TClipboardType): PGdkClipboard;
var
  ADisplay: PGdkDisplay;
begin
  ADisplay := gdk4_display_get_default;
  if ADisplay = nil then
    exit(nil);
  case ClipboardType of
    ctPrimarySelection:
      Result := gdk4_display_get_primary_clipboard(ADisplay);
    ctClipboard:
      Result := gdk4_display_get_clipboard(ADisplay);
  else
    { ctSecondarySelection: GTK4 doesn't have a secondary selection.
      Fall back to primary. }
    Result := gdk4_display_get_primary_clipboard(ADisplay);
  end;
end;

{ Helper record for async clipboard read operations }
type
  TClipboardReadInfo = record
    Loop: PGMainLoop;
    Text: PgChar;
    Stream: PGInputStream;
    Error: PGError;
    Done: Boolean;
  end;
  PClipboardReadInfo = ^TClipboardReadInfo;

{ Callback for gdk_clipboard_read_text_async }
procedure Gtk4ClipboardReadTextCB(source_object: PGObject;
  res: PGAsyncResult; user_data: gpointer); cdecl;
var
  Info: PClipboardReadInfo;
begin
  Info := PClipboardReadInfo(user_data);
  Info^.Text := gdk4_clipboard_read_text_finish(PGdkClipboard(source_object),
    res, @Info^.Error);
  Info^.Done := True;
  if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
    g_main_loop_quit(Info^.Loop);
end;

{ Callback for gdk_clipboard_read_async (arbitrary mime type) }
procedure Gtk4ClipboardReadCB(source_object: PGObject;
  res: PGAsyncResult; user_data: gpointer); cdecl;
var
  Info: PClipboardReadInfo;
begin
  Info := PClipboardReadInfo(user_data);
  Info^.Stream := gdk4_clipboard_read_finish(PGdkClipboard(source_object),
    res, nil, @Info^.Error);
  Info^.Done := True;
  if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
    g_main_loop_quit(Info^.Loop);
end;

function TGtk4WidgetSet.ClipboardGetData(ClipboardType: TClipboardType;
  FormatID: TClipboardFormat; Stream: TStream): boolean;
var
  AClipboard: PGdkClipboard;
  Info: TClipboardReadInfo;
  AMimeType: string;
  ALen: Integer;
  AByte: Byte;
  MimeArr: array[0..1] of PgChar;
  ABuf: array[0..4095] of Byte;
  ABytesRead: gssize;
begin
  Result := False;
  if (FormatID = 0) or (Stream = nil) then exit;

  AClipboard := Gtk4GetClipboard(ClipboardType);
  if AClipboard = nil then exit;

  AMimeType := ClipboardFormatToMimeType(FormatID);

  FillChar(Info, SizeOf(Info), 0);
  Info.Loop := g_main_loop_new(nil, False);

  if (AMimeType = 'text/plain') or (AMimeType = 'UTF8_STRING') or
     (AMimeType = 'STRING') or (AMimeType = 'TEXT') then
  begin
    { Text: use the specialized text read which handles encoding }
    gdk4_clipboard_read_text_async(AClipboard, nil,
      @Gtk4ClipboardReadTextCB, @Info);

    if not Info.Done then
      g_main_loop_run(Info.Loop);
    g_main_loop_unref(Info.Loop);

    if (Info.Error = nil) and (Info.Text <> nil) then
    begin
      ALen := Length(string(Info.Text));
      if ALen > 0 then
        Stream.Write(Info.Text^, ALen);
      { Add null terminator - LCL expects it for text }
      AByte := 0;
      Stream.Write(AByte, 1);
      g_free(Info.Text);
      Result := True;
    end;
    if Info.Error <> nil then
      g_error_free(Info.Error);
  end
  else
  begin
    { Arbitrary mime type: use generic read }
    MimeArr[0] := PgChar(AMimeType);
    MimeArr[1] := nil;
    gdk4_clipboard_read_async(AClipboard, @MimeArr[0], 0, nil,
      @Gtk4ClipboardReadCB, @Info);

    if not Info.Done then
      g_main_loop_run(Info.Loop);
    g_main_loop_unref(Info.Loop);

    if (Info.Error = nil) and (Info.Stream <> nil) then
    begin
      { Read all data from the GInputStream }
      repeat
        ABytesRead := g_input_stream_read(Info.Stream, @ABuf[0], SizeOf(ABuf),
          nil, nil);
        if ABytesRead > 0 then
          Stream.Write(ABuf[0], ABytesRead);
      until ABytesRead <= 0;
      g_input_stream_close(Info.Stream, nil, nil);
      g_object_unref(Info.Stream);
      Result := True;
    end;
    if Info.Error <> nil then
      g_error_free(Info.Error);
  end;
end;

function TGtk4WidgetSet.ClipboardGetFormats(ClipboardType: TClipboardType;
  var Count: integer; var List: PClipboardFormat): boolean;
var
  AClipboard: PGdkClipboard;
  AFormats: PGdkContentFormats;
  AMimeTypes: PPgChar;
  AMimeCount: gsize;
  i: Integer;
  p: PgChar;
begin
  Result := False;
  Count := 0;
  List := nil;

  AClipboard := Gtk4GetClipboard(ClipboardType);
  if AClipboard = nil then exit;

  AFormats := gdk4_clipboard_get_formats(AClipboard);
  if AFormats = nil then exit;

  AMimeTypes := gdk4_content_formats_get_mime_types(AFormats, @AMimeCount);
  if (AMimeTypes = nil) or (AMimeCount = 0) then exit;

  Count := AMimeCount;
  GetMem(List, SizeOf(TClipboardFormat) * Count);
  p := AMimeTypes^;
  for i := 0 to Count - 1 do
  begin
    p := PPgChar(PByte(AMimeTypes) + i * SizeOf(PgChar))^;
    if p <> nil then
      List[i] := TClipboardFormat(PtrUInt(g_quark_from_string(p)))
    else
      List[i] := 0;
  end;
  Result := True;
  { Note: AMimeTypes is owned by the GdkContentFormats, do NOT free it }
end;

var
  { Store clipboard ownership callback per clipboard type.
    Currently assigned but not re-read — will be needed for async clipboard requests. }
  {%H-}Gtk4ClipboardOnRequest: array[TClipboardType] of TClipboardRequestEvent;

function TGtk4WidgetSet.ClipboardGetOwnerShip(ClipboardType: TClipboardType;
  OnRequestProc: TClipboardRequestEvent; FormatCount: integer;
  Formats: PClipboardFormat): boolean;
var
  AClipboard: PGdkClipboard;
  i: Integer;
  AMimeType: PgChar;
  AStream: TMemoryStream;
  ABytes: PGBytes;
  AProviders: array of PGdkContentProvider;
  AUnion: PGdkContentProvider;
  ProvCount: Integer;
begin
  Result := False;
  AClipboard := Gtk4GetClipboard(ClipboardType);
  if AClipboard = nil then exit;

  if (OnRequestProc = nil) or (FormatCount = 0) then
  begin
    { Release ownership }
    {%H-}Gtk4ClipboardOnRequest[ClipboardType] := nil;
    gdk4_clipboard_set_content(AClipboard, nil);
    Result := True;
    exit;
  end;

  { Store the callback }
  {%H-}Gtk4ClipboardOnRequest[ClipboardType] := OnRequestProc;

  { Collect data for each format and create content providers.
    The LCL caches data internally and provides it via the callback.
    We request all format data now and package it as GdkContentProviders. }
  SetLength(AProviders, FormatCount);
  ProvCount := 0;

  for i := 0 to FormatCount - 1 do
  begin
    if Formats[i] = 0 then Continue;
    AMimeType := g_quark_to_string(TGQuark(Formats[i]));
    if AMimeType = nil then Continue;

    AStream := TMemoryStream.Create;
    try
      OnRequestProc(Formats[i], AStream);
      if AStream.Size > 0 then
      begin
        ABytes := glib2_bytes_new(AStream.Memory, AStream.Size);
        AProviders[ProvCount] := gdk4_content_provider_new_for_bytes(AMimeType, ABytes);
        g_bytes_unref(ABytes);
        Inc(ProvCount);
      end;
    finally
      AStream.Free;
    end;
  end;

  if ProvCount > 0 then
  begin
    { Create a union provider from all individual providers }
    AUnion := gdk4_content_provider_new_union(@AProviders[0], ProvCount);
    Result := gdk4_clipboard_set_content(AClipboard, AUnion);
    { The union takes ownership of child providers, and clipboard takes
      ownership of the union. We don't need to unref them. }
  end;
end;

function TGtk4WidgetSet.ClipboardRegisterFormat(const AMimeType: string): TClipboardFormat;
begin
  { GTK4: GdkAtom was removed. GTK4 uses mime type strings directly.
    We use GQuark as a stable format ID for each mime type string. }
  if Assigned(Application) then
    Result := TClipboardFormat(PtrUInt(g_quark_from_string(PgChar(AMimeType))))
  else
    LazTracer.RaiseGDBException(
      'ERROR: TGtk4WidgetSet.ClipboardRegisterFormat gdk not initialized');
end;

function TGtk4WidgetSet.CombineRgn(Dest, Src1, Src2: HRGN;
  fnCombineMode: Longint): Longint;
var
  RDest,RSrc1,RSrc2: Pcairo_region_t;
  ARegion: Pcairo_region_t;
  AStatus: Tcairo_status_t;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4WidgetSet.CombineRgn combineMode=',dbgs(fnCombineMode));
  {$ENDIF}
  Result := ERROR;
  if not IsValidGDIObject(Dest) or not IsValidGDIObject(Src1) then
    exit;
  RDest := TGtk4Region(Dest).Handle;
  RSrc1 := TGtk4Region(Src1).Handle;
  if (fnCombineMode<>RGN_COPY) and not IsValidGDIObject(Src2) then
    exit
  else
    RSrc2 := TGtk4Region(Src2).Handle;
  AStatus := CAIRO_STATUS_READ_ERROR;
  ARegion := nil;
  case fnCombineMode of
     RGN_AND:
     begin
       ARegion := cairo_region_copy(RSrc1);
       AStatus := cairo_region_intersect(ARegion, RSrc2);
     end;
     RGN_COPY:
     begin
       ARegion := cairo_region_copy(RSrc2);
       AStatus := CAIRO_STATUS_SUCCESS;
     end;
     RGN_DIFF:
     begin
      ARegion := cairo_region_copy(RSrc1);
      AStatus := cairo_region_subtract(ARegion, RSrc2);
     end;
     RGN_OR:
     begin
       ARegion := cairo_region_copy(RSrc1);
       AStatus := cairo_region_union(ARegion, RSrc2);
     end;
     RGN_XOR:
     begin
       ARegion := cairo_region_copy(RSrc1);
       AStatus := cairo_region_xor(ARegion, RSrc2);
     end;
  end;
  if (AStatus <> CAIRO_STATUS_SUCCESS) or (ARegion = nil) or cairo_region_is_empty(ARegion) then
    Result := NullRegion
  else
  begin

    cairo_region_destroy(RDest);
    RDest := cairo_region_copy(ARegion);
    TGtk4Region(Dest).Handle := RDest;
    if cairo_region_num_rectangles(ARegion) > 1 then
      Result := ComplexRegion
    else
      Result := SimpleRegion;
  end;
  {$IFDEF VerboseGtk4DeviceContext}
  if Result <> NullRegion then
  begin
    cairo_region_get_extents(ARegion, @ACairoRect);
    DebugLn('TGtk4WidgetSet.CombineRgn combineMode=',dbgs(fnCombineMode),' Result=',dbgs(Result),' X=',dbgs(ACairoRect.x),' Y=',dbgs(ACairoRect.y),' W=',dbgs(ACairoRect.width),' h=',dbgs(ACairoRect.height));
  end;
  {$ENDIF}
  cairo_region_destroy(ARegion);
end;

function TGtk4WidgetSet.CreateBitmap(Width, Height: Integer; Planes,
  BitCount: Longint; BitmapBits: Pointer): HBITMAP;
var
  Format: Tcairo_format_t;
  NewBits: PByte;
  NewBitsSize: PtrUInt;
  ARowStride, RSS: Integer;
begin
  {$IFDEF VerboseGtk4WinAPI}
    DebugLn('Trace:> [Gtk4WinAPI CreateBitmap]',
     ' Width:', dbgs(Width),
     ' Height:', dbgs(Height),
     ' Planes:', dbgs(Planes),
     ' BitCount:', dbgs(BitCount),
     ' BitmapBits: ', dbgs(BitmapBits));
  {$ENDIF}
  case BitCount of
    1: Format := CAIRO_FORMAT_A1;
    8: Format := CAIRO_FORMAT_A8;
    24: Format := CAIRO_FORMAT_RGB24;
    else
      Format := CAIRO_FORMAT_ARGB32;
  end;

  RSS := GetBytesPerLine(Width, BitCount, rileWordBoundary);
  if BitmapBits <> nil then
  begin
    ARowStride := GetBytesPerLine(Width, BitCount, rileDWordBoundary);
    if not CopyImageData(Width, Height, RSS, BitCount, BitmapBits, Rect(0, 0, Width, Height),
      riloBottomToTop, riloBottomToTop, rileDWordBoundary, NewBits, NewBitsSize) then
    begin
      // this was never tested
      ARowStride := RSS;
      NewBits := AllocMem(RSS * Height);
      Move(BitmapBits^, NewBits^, RSS * Height);
    end;
    Result := HBitmap(TGtk4Image.Create(NewBits, Width, Height, ARowStride, Format, True));
  end
  else
    Result := HBitmap(TGtk4Image.Create(nil, Width, Height, Format));

  {$IFDEF VerboseGtk4WinAPI}
  DebugLn('Trace:< [Gtk4WinAPI CreateBitmap] Bitmap:', dbghex(Result));
  {$ENDIF}
end;

function TGtk4WidgetSet.CreateBrushIndirect(const LogBrush: TLogBrush): HBRUSH;
var
  ABrush: TGtk4Brush;
begin
  Result := 0;
  ABrush := TGtk4Brush.Create;
  try
    ABrush.Style := LogBrush.lbStyle;
    ABrush.Color := ColorToRGB(TColor(logBrush.lbColor));
    ABrush.LogBrush := LogBrush;
    // ABrush.LogBrush.lbColor := ABrush.Color;
    Result := HBRUSH(ABrush);
  except
    Result := 0;
    DebugLn('TGtk4WidgetSet.CreateBrushIndirect: Failed');
  end;

  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('Trace:< [Gtk4WinAPI CreateBrushIndirect] Result: ', dbghex(Result));
  {$ENDIF}
end;

function TGtk4WidgetSet.CreatePatternBrush(ABitmap: HBITMAP): HBRUSH;
var
  ABrush: TGtk4Brush;
  AImage: TGtk4Image;
  Surface: Pcairo_surface_t;
  cr: Pcairo_t;
  W, H: Integer;
begin
  Result := 0;
  if ABitmap = 0 then
    Exit;
  AImage := TGtk4Image(ABitmap);
  if AImage.Handle = nil then
    Exit;
  W := AImage.width;
  H := AImage.height;
  if (W <= 0) or (H <= 0) then
    Exit;

  { Create a Cairo image surface and render the pixbuf onto it }
  Surface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, W, H);
  cr := cairo_create(Surface);
  try
    gdk_cairo_set_source_pixbuf(cr, AImage.Handle, 0, 0);
    cairo_paint(cr);
  finally
    cairo_destroy(cr);
  end;

  ABrush := TGtk4Brush.Create;
  ABrush.brush_pattern := cairo_pattern_create_for_surface(Surface);
  cairo_pattern_set_extend(ABrush.brush_pattern, CAIRO_EXTEND_REPEAT);
  cairo_surface_destroy(Surface);

  ABrush.LogBrush.lbStyle := BS_PATTERN;
  ABrush.LogBrush.lbHatch := ABitmap;
  Result := HBRUSH(ABrush);
end;

function TGtk4WidgetSet.CreateBrushWithRadialGradient(
  const LogBrush: TLogRadialGradient): HBRUSH;
var
  ABrush: TGtk4Brush;
  Pattern: Pcairo_pattern_t;
  i: Integer;
  Stop: TLogGradientStop;
begin
  Result := 0;
  Pattern := cairo_pattern_create_radial(
    LogBrush.radFocalX, LogBrush.radFocalY, 0,
    LogBrush.radCenterX, LogBrush.radCenterY, LogBrush.radRadius);
  if cairo_pattern_status(Pattern) <> CAIRO_STATUS_SUCCESS then
  begin
    cairo_pattern_destroy(Pattern);
    Exit;
  end;
  for i := 0 to High(LogBrush.radStops) do
  begin
    Stop := LogBrush.radStops[i];
    cairo_pattern_add_color_stop_rgba(Pattern, Stop.radPosition,
      Stop.radColorR / $FFFF, Stop.radColorG / $FFFF,
      Stop.radColorB / $FFFF, Stop.radColorA / $FFFF);
  end;
  ABrush := TGtk4Brush.Create;
  ABrush.brush_pattern := Pattern;
  ABrush.LogBrush.lbStyle := BS_DIBPATTERN;
  Result := HBRUSH(ABrush);
end;

function TGtk4WidgetSet.CreateCaret(Handle: HWND; Bitmap: hBitmap; width,
  Height: Integer): Boolean;
begin
  Result := Handle <> 0;
  if not Result then Exit;
  { Destroy existing caret first }
  StopCaretTimer;
  FCaret.Handle := Handle;
  FCaret.X := 0;
  FCaret.Y := 0;
  FCaret.Width := width;
  FCaret.Height := Height;
  FCaret.Visible := False;
  FCaret.IsDrawn := False;
  FCaret.BlinkHide := False;
  FCaret.BlinkTime := 530;
  FCaret.ShowHideOnFocus := True;
end;

function TGtk4WidgetSet.CreateCompatibleBitmap(DC: HDC; Width, Height: Integer
  ): HBITMAP;
var
  Gtk4DC: TGtk4DeviceContext;
  Format: Tcairo_format_t = CAIRO_FORMAT_ARGB32;
  ADepth: Integer;
  ABpp: gint;
  ARowStride: PtrUInt;
begin
  {$IFDEF VerboseGtk4WinAPI}
  DebugLn('Trace:> [WinAPI CreateCompatibleBitmap]',
     ' DC:', dbghex(DC),
     ' Width:', dbgs(Width),
     ' Height:', dbgs(Height));
  {$ENDIF}
  Result := 0;
  if IsValidDC(DC) then
  begin
    Gtk4DC := TGtk4DeviceContext(DC);
    ADepth := Gtk4DC.getDepth;
    ABpp := Gtk4DC.getBpp;
  end else
  begin
    { GTK4: gdk_window_get_visual/gdk_get_default_root_window removed; hardcode 32-bit }
    ADepth := 32;
    ABpp := 8;
  end;
  case ADepth of
    1: Format := CAIRO_FORMAT_A1;
    2: Format := CAIRO_FORMAT_A8;
    24: Format := CAIRO_FORMAT_RGB24;
    else
      Format := CAIRO_FORMAT_ARGB32;
  end;
  ARowStride := GetBytesPerLine(Width, ABpp, rileDWordBoundary);
  Result := HBitmap(TGtk4Image.Create(nil, Width, Height, ARowStride, Format));
  {$IFDEF VerboseGtk4WinAPI}
  DebugLn('Trace:< [Gtk4WinAPI CreateCompatibleBitmap] Bitmap:', dbghex(Result));
  {$ENDIF}
end;

function TGtk4WidgetSet.CreateCompatibleDC(DC: HDC): HDC;
begin
  Result := HDC(TGtk4DeviceContext.Create(PGtkWidget(nil), False));
end;

function TGtk4WidgetSet.CreateEllipticRgn(X1, Y1, X2, Y2: Integer): HRGN;
begin
  Result:=HRGN(TGtk4Region.CreateEllipse(X1,Y1,X2,Y2));
end;

function TGtk4WidgetSet.CreateRoundRectRgn(X1, Y1, X2, Y2, nW, nH: Integer): HRGN;
begin
  Result:=HRGN(TGtk4Region.Create(X1,Y1,X2,Y2,nW,nH));
end;


function TGtk4WidgetSet.CreateFontIndirect(const LogFont: TLogFont): HFONT;
begin
  Result := CreateFontIndirectEx(LogFont, '');
end;

function TGtk4WidgetSet.CreateFontIndirectEx(const LogFont: TLogFont;
  const LongFontName: string): HFONT;
begin
  Result := HFONT(TGtk4Font.Create(LogFont, LongFontName));
end;

function TGtk4WidgetSet.CreateIconIndirect(IconInfo: PIconInfo): HICON;
var
  ATexture: PGdkTexture;
begin
  Result := 0;
  if IsValidGDIObject(IconInfo^.hbmColor) then
  begin
    if IconInfo^.fIcon then
    begin
      Result := HICON(TGtk4Image.Create(TGtk4Image(IconInfo^.hbmColor).Handle));
    end else
    begin
      // GTK4: gdk_cursor_new_from_pixbuf removed. Convert pixbuf→texture→cursor.
      ATexture := gdk4_texture_new_for_pixbuf(TGtk4Image(IconInfo^.hbmColor).Handle);
      if ATexture <> nil then
      begin
        Result := HCURSOR({%H-}PtrUInt(gdk4_cursor_new_from_texture(ATexture,
          IconInfo^.xHotSpot, IconInfo^.yHotSpot, nil)));
        g_object_unref(PGObject(ATexture));
      end;
    end;
  end;
end;

function TGtk4WidgetSet.CreatePalette(const LogPalette: TLogPalette): HPALETTE;
begin
  { Palette management is not used in GTK4 (32-bit color always). }
  Result := 0;
end;

function TGtk4WidgetSet.CreatePenIndirect(const LogPen: TLogPen): HPEN;
var
  APen: TGtk4Pen;
begin
  Result := 0;
  APen := TGtk4Pen.Create;
  with LogPen do
  begin
    case lopnStyle and PS_STYLE_MASK of
      PS_SOLID: APen.Style := psSolid;
      PS_DASH: APen.Style := psDash;
      PS_DOT: APen.Style := psDot;
      PS_DASHDOT: APen.Style := psDashDot;
      PS_DASHDOTDOT: APen.Style := psDashDotDot;
      PS_NULL: APen.Style := psClear;
    else
      APen.Style := psSolid;
    end;
    APen.Color := ColorToRgb(TColor(lopnColor));
    APen.Cosmetic := lopnWidth.X <= 0 ;
    if not APen.Cosmetic then
      APen.Width := lopnWidth.X;
  end;
  APen.LogPen := LogPen;

  Result := HPEN(APen);
end;

function TGtk4WidgetSet.CreatePolygonRgn(Points: PPoint; NumPts: Integer;
  FillMode: integer): HRGN;
var
  ARegion: TGtk4Region;
  Surface: Pcairo_surface_t;
  cr: Pcairo_t;
  Data: PByte;
  Stride, W, H, x, y, RunStart: Integer;
  MinX, MinY, MaxX, MaxY, i: Integer;
  ARect: Tcairo_rectangle_int_t;
  InRun: Boolean;
begin
  Result := 0;
  if (Points = nil) or (NumPts < 3) then Exit;

  { Find bounding box }
  MinX := Points[0].x; MaxX := MinX;
  MinY := Points[0].y; MaxY := MinY;
  for i := 1 to NumPts - 1 do
  begin
    if Points[i].x < MinX then MinX := Points[i].x;
    if Points[i].x > MaxX then MaxX := Points[i].x;
    if Points[i].y < MinY then MinY := Points[i].y;
    if Points[i].y > MaxY then MaxY := Points[i].y;
  end;
  W := MaxX - MinX + 1;
  H := MaxY - MinY + 1;
  if (W <= 0) or (H <= 0) then Exit;

  { Render polygon to A8 surface, then scan for filled pixels }
  Surface := cairo_image_surface_create(CAIRO_FORMAT_A8, W, H);
  cr := cairo_create(Surface);
  try
    { Draw polygon }
    if FillMode = WINDING then
      cairo_set_fill_rule(cr, CAIRO_FILL_RULE_WINDING)
    else
      cairo_set_fill_rule(cr, CAIRO_FILL_RULE_EVEN_ODD);
    cairo_move_to(cr, Points[0].x - MinX + 0.5, Points[0].y - MinY + 0.5);
    for i := 1 to NumPts - 1 do
      cairo_line_to(cr, Points[i].x - MinX + 0.5, Points[i].y - MinY + 0.5);
    cairo_close_path(cr);
    cairo_set_source_rgba(cr, 1, 1, 1, 1);
    cairo_fill(cr);
    cairo_surface_flush(Surface);

    { Scan pixels to build region }
    ARegion := TGtk4Region.Create(True);
    Data := PByte(cairo_image_surface_get_data(Surface));
    Stride := cairo_image_surface_get_stride(Surface);
    for y := 0 to H - 1 do
    begin
      InRun := False;
      RunStart := 0;
      for x := 0 to W - 1 do
      begin
        if Data[y * Stride + x] <> 0 then
        begin
          if not InRun then
          begin
            RunStart := x;
            InRun := True;
          end;
        end else
        begin
          if InRun then
          begin
            ARect.x := RunStart + MinX;
            ARect.y := y + MinY;
            ARect.width := x - RunStart;
            ARect.height := 1;
            cairo_region_union_rectangle(ARegion.Handle, @ARect);
            InRun := False;
          end;
        end;
      end;
      if InRun then
      begin
        ARect.x := RunStart + MinX;
        ARect.y := y + MinY;
        ARect.width := W - RunStart;
        ARect.height := 1;
        cairo_region_union_rectangle(ARegion.Handle, @ARect);
      end;
    end;
    Result := HRGN(ARegion);
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(Surface);
  end;
end;

function TGtk4WidgetSet.CreateRectRgn(X1, Y1, X2, Y2: Integer): HRGN;
begin
  Result := HRGN(TGtk4Region.Create(True, X1, Y1, X2, Y2));
end;

procedure TGtk4WidgetSet.DeleteCriticalSection(var CritSection: TCriticalSection
  );
var
  ACritSec: System.PRTLCriticalSection;
begin
  ACritSec:=System.PRTLCriticalSection(CritSection);
  System.DoneCriticalsection(ACritSec^);
  Dispose(ACritSec);
  CritSection:=0;
end;

function TGtk4WidgetSet.DeleteDC(hDC: HDC): Boolean;
begin
  {$ifdef VerboseGtk4DeviceContext}
  DebugLn('TGtk4WidgetSet.DeleteDC Handle: ', dbghex(hDC));
  {$endif}

  if not IsValidDC(hDC) then
    exit(False);

  TGtk4DeviceContext(hDC).Free;
  Result := True;
end;

function TGtk4WidgetSet.DeleteObject(GDIObject: HGDIOBJ): Boolean;
begin
  Result := False;

  if GDIObject = 0 then
    Exit(True);

  if not IsValidGDIObject(GDIObject) then
    Exit;
  {$ifdef VerboseGtk4DeviceContext}
  DebugLn('TGtk4WidgetSet.DeleteObject GDIObject: ', dbghex(GdiObject),' name ',dbgsName(TObject(GdiObject)));
  {$endif}
  if TObject(GDIObject) is TGtk4ContextObject then
  begin
    if TGtk4ContextObject(GDIOBJECT).Shared then
    else
      TGtk4ContextObject(GDIObject).Free;
  end else
    TObject(GDIObject).Free;
end;

function TGtk4WidgetSet.DestroyCaret(Handle: HWND): Boolean;
begin
  Result := True;
  if FCaret.Handle = Handle then
  begin
    StopCaretTimer;
    InvalidateCaret;
    FillChar(FCaret, SizeOf(FCaret), 0);
  end;
end;

function TGtk4WidgetSet.DestroyCursor(Handle: HCURSOR): Boolean;
begin
  Result := Handle <> 0;
  if Result then
    g_object_unref(PGdkCursor(Handle));
   // gdk_cursor_destroy({%H-}PGdkCursor(Handle));
end;

function TGtk4WidgetSet.DestroyIcon(Handle: HICON): Boolean;
begin
  Result := False;
  if IsValidGDIObject(Handle) then
  begin
    TGtk4Image(Handle).Free;
    Result := True;
  end;
end;

function TGtk4WidgetSet.DPtoLP(DC: HDC; var Points; Count: Integer): BOOL;
var
  cr: Pcairo_t;
  P: PPoint;
  dx, dy: Double;
begin
  Result := False;
  if not IsValidDC(DC) then Exit;
  cr := TGtk4DeviceContext(DC).pcr;

  P := @Points;
  while Count > 0 do
  begin
    Dec(Count);
    DX := P^.X + TGtk4DeviceContext(DC).fncOrigin.X;
    DY := P^.Y + TGtk4DeviceContext(DC).fncOrigin.Y;
    cairo_device_to_user(cr, @dx, @dy);
    P^.X := Round(DX);
    P^.Y := Round(DY);
    Inc(P);
  end;
  Result := True;
end;

function TGtk4WidgetSet.DrawFrameControl(DC: HDC; const aRect: TRect; uType,
  uState: Cardinal): Boolean;
begin
  Result:=false;
  if IsValidDC(DC) then
    Result:=TGtk4DeviceContext(DC).drawFrameControl(aRect,uType,uState);
end;

function TGtk4WidgetSet.DrawFocusRect(DC: HDC; const aRect: TRect): boolean;
begin
  Result := False;
  if IsValidDC(DC) then
    Result:=TGtk4DeviceContext(DC).drawFocusRect(aRect);
end;

function TGtk4WidgetSet.DrawEdge(DC: HDC; var ARect: TRect; Edge: Cardinal;
  grfFlags: Cardinal): Boolean;

  procedure CairoDrawEdges(cr: Pcairo_t; var R: TRect;
    TLColor, BRColor: TColor);
  var
    tlR, tlG, tlB, brR, brG, brB: Double;
  begin
    ColorToCairoRGB(ColorToRGB(TLColor), tlR, tlG, tlB);
    ColorToCairoRGB(ColorToRGB(BRColor), brR, brG, brB);

    cairo_set_source_rgb(cr, tlR, tlG, tlB);
    if (grfFlags and BF_TOP) = BF_TOP then
    begin
      cairo_move_to(cr, R.Left + 0.5, R.Top + 0.5);
      cairo_line_to(cr, R.Right - 0.5, R.Top + 0.5);
      cairo_stroke(cr);
      Inc(R.Top);
    end;
    if (grfFlags and BF_LEFT) = BF_LEFT then
    begin
      cairo_move_to(cr, R.Left + 0.5, R.Top + 0.5);
      cairo_line_to(cr, R.Left + 0.5, R.Bottom - 0.5);
      cairo_stroke(cr);
      Inc(R.Left);
    end;

    cairo_set_source_rgb(cr, brR, brG, brB);
    if (grfFlags and BF_BOTTOM) = BF_BOTTOM then
    begin
      cairo_move_to(cr, R.Left + 0.5, R.Bottom - 0.5);
      cairo_line_to(cr, R.Right - 0.5, R.Bottom - 0.5);
      cairo_stroke(cr);
      Dec(R.Bottom);
    end;
    if (grfFlags and BF_RIGHT) = BF_RIGHT then
    begin
      cairo_move_to(cr, R.Right - 0.5, R.Top + 0.5);
      cairo_line_to(cr, R.Right - 0.5, R.Bottom - 0.5);
      cairo_stroke(cr);
      Dec(R.Right);
    end;
  end;

var
  ctx: TGtk4DeviceContext;
  R: TRect;
  InnerTL, InnerBR, OuterTL, OuterBR: TColor;
  BInner, BOuter: Boolean;
  mR, mG, mB: Double;
begin
  Result := IsValidDC(DC);
  if not Result then Exit;

  ctx := TGtk4DeviceContext(DC);
  if ctx.pcr = nil then begin Result := False; Exit; end;

  R := ARect;
  BInner := False;
  BOuter := False;
  InnerTL := 0; InnerBR := 0;
  OuterTL := 0; OuterBR := 0;

  if (Edge and BDR_RAISEDINNER) = BDR_RAISEDINNER then
  begin
    InnerTL := GetSysColor(COLOR_BTNHIGHLIGHT);
    InnerBR := GetSysColor(COLOR_BTNSHADOW);
    BInner := True;
  end;
  if (Edge and BDR_SUNKENINNER) = BDR_SUNKENINNER then
  begin
    InnerTL := GetSysColor(COLOR_BTNSHADOW);
    InnerBR := GetSysColor(COLOR_BTNHIGHLIGHT);
    BInner := True;
  end;
  if (Edge and BDR_RAISEDOUTER) = BDR_RAISEDOUTER then
  begin
    OuterTL := GetSysColor(COLOR_BTNHIGHLIGHT);
    OuterBR := GetSysColor(COLOR_BTNSHADOW);
    BOuter := True;
  end;
  if (Edge and BDR_SUNKENOUTER) = BDR_SUNKENOUTER then
  begin
    OuterTL := GetSysColor(COLOR_BTNSHADOW);
    OuterBR := GetSysColor(COLOR_BTNHIGHLIGHT);
    BOuter := True;
  end;

  cairo_save(ctx.pcr);
  try
    cairo_set_line_width(ctx.pcr, 1.0);
    cairo_set_antialias(ctx.pcr, CAIRO_ANTIALIAS_NONE);

    { Draw outer edge }
    if BOuter then
      CairoDrawEdges(ctx.pcr, R, OuterTL, OuterBR);

    { Draw inner edge }
    if BInner then
      CairoDrawEdges(ctx.pcr, R, InnerTL, InnerBR);

    { Fill middle }
    if (grfFlags and BF_MIDDLE) = BF_MIDDLE then
    begin
      ColorToCairoRGB(ColorToRGB(GetSysColor(COLOR_BTNFACE)), mR, mG, mB);
      cairo_set_source_rgb(ctx.pcr, mR, mG, mB);
      cairo_rectangle(ctx.pcr, R.Left, R.Top,
        R.Right - R.Left, R.Bottom - R.Top);
      cairo_fill(ctx.pcr);
    end;

    { Adjust rect }
    if (grfFlags and BF_ADJUST) = BF_ADJUST then
      ARect := R;
  finally
    cairo_restore(ctx.pcr);
  end;
  Result := True;
end;

function TGtk4WidgetSet.DrawText(DC: HDC; Str: PChar; Count: Integer;
  var Rect: TRect; Flags: Cardinal): Integer;
const
  TabString = '        ';
var
  pIndex: Longint;
  AStr: String;

  TM: TTextmetric;
  theRect: TRect;
  Lines: PPChar;
  I, NumLines: Longint;
  TempDC: HDC;
  TempPen: HPEN;
  TempBrush: HBRUSH;
  l: LongInt;
  Pt: TPoint;
  SavedRect: TRect; // if font orientation <> 0
  LineHeight: Integer;
  Size: TSize;

  function LeftOffset: Longint;
  begin
    if (Flags and DT_RIGHT) = DT_RIGHT then
      Result := DT_RIGHT
    else
      if (Flags and DT_CENTER) = DT_CENTER then
        Result := DT_CENTER
    else
      Result := DT_LEFT;
  end;

  function TopOffset: Longint;
  begin
    if (Flags and DT_BOTTOM) = DT_BOTTOM then
      Result := DT_BOTTOM
    else
      if (Flags and DT_VCENTER) = DT_VCENTER then
        Result := DT_VCENTER
    else
      Result := DT_TOP;
  end;

  function CalcRect: Boolean;
  begin
    Result := (Flags and DT_CALCRECT) = DT_CALCRECT;
  end;

  function TextExtentPoint(Str: PChar; Count: Integer; var Sz: TSize): Boolean;
  var
    NewStr: String;
  begin
    if (Flags and DT_EXPANDTABS) <> 0 then
    begin
      NewStr := StringReplace(Str, #9, TabString, [rfReplaceAll]);
      Result := GetTextExtentPoint(DC, PChar(NewStr), Length(NewStr), Sz);
    end
    else
      Result := GetTextExtentPoint(Dc, Str, Count, Sz);
  end;

  procedure DoCalcRect;
  var
    AP: TSize;
    J, MaxWidth,
    LineWidth, LineHeight: Integer;
  begin
    theRect := Rect;

    MaxWidth := theRect.Right - theRect.Left;

    if (Flags and DT_SINGLELINE) > 0 then
    begin
      // ignore word and line breaks
      TextExtentPoint(PChar(AStr), length(AStr), AP{%H-});
      theRect.Bottom := theRect.Top + TM.tmHeight;
      if (Flags and DT_CALCRECT)<>0 then
      begin
        theRect.Right := theRect.Left +  AP.cX;
        theRect.Bottom := theRect.Top + AP.cY;
      end
      else
      begin
        theRect.Right := theRect.Left + Min(MaxWidth, AP.cX);
        theRect.Bottom := theRect.Top + AP.cY;
        if (Flags and DT_VCENTER) > 0 then
        begin
          Types.OffsetRect(theRect, 0, ((Rect.Bottom - Rect.Top) - (theRect.Bottom - theRect.Top)) div 2);
        end
        else
        if (Flags and DT_BOTTOM) > 0 then
        begin
          Types.OffsetRect(theRect, 0, (Rect.Bottom - Rect.Top) - (theRect.Bottom - theRect.Top));
        end;
      end;
    end
    else
    begin
      // consider line breaks
      if (Flags and DT_WORDBREAK) = 0 then
      begin
        // do not break at word boundaries
        TextExtentPoint(PChar(AStr), length(AStr), AP);
        MaxWidth := AP.cX;
      end;

      Gtk4WordWrap(DC, PChar(AStr), MaxWidth, Lines, NumLines);
      if (Flags and DT_CALCRECT)<>0 then
      begin
        LineWidth := 0;
        LineHeight := 0;
        if (Lines <> nil) then
        begin
          for J := 0 to NumLines - 1 do
          begin
            TextExtentPoint(Lines[J], StrLen(Lines[J]), AP);
            LineWidth := Max(LineWidth, AP.cX);
            Inc(LineHeight, AP.cY);
          end;
        end;
        LineWidth := Min(MaxWidth, LineWidth);
      end else
      begin
        LineWidth := MaxWidth;
        LineHeight := NumLines*TM.tmHeight;
      end;

      theRect.Right := theRect.Left + LineWidth;
      theRect.Bottom := theRect.Top + LineHeight;
      if NumLines>1 then
        Inc(theRect.Bottom, (NumLines-1)*TM.tmExternalLeading);// space between lines

      //        ' LineWidth=',dbgs(LineWidth),' NumLines=',dbgs(NumLines));
    end;

    if not CalcRect then
      case LeftOffset of
        DT_CENTER:
          Types.OffsetRect(theRect, (Rect.Right - theRect.Right) div 2, 0);
        DT_RIGHT:
          Types.OffsetRect(theRect, Rect.Right - theRect.Right, 0);
      end;
  end;

  // if our Font.Orientation <> 0 we must recalculate X,Y offset
  // also it works only with DT_TOP DT_LEFT. Gtk2 can handle multiline
  // text in this case too.
  procedure CalculateOffsetWithAngle(const AFontAngle: Integer;
    var TextLeft,TextTop: Integer);
  var
    OffsX, OffsY: integer;
    Angle: Double;
    Size: TSize;
    R: TRect;
  begin
    R := SavedRect;
    OffsX := R.Right - R.Left;
    OffsY := R.Bottom - R.Top;
    Size.cx := OffsX;
    Size.cy := OffsY;
    Angle := AFontAngle / 10;
    if Angle < 0 then
      Angle := 360 + Angle;

    if Angle <= 90 then
    begin
      OffsX := 0;
      OffsY := Trunc(Size.cx * sin(Angle * Pi / 180));
    end else
    if Angle <= 180 then
    begin
      OffsX := Trunc(Size.cx * -cos(Angle * Pi / 180));
      OffsY := Trunc(Size.cx * sin(Angle * Pi / 180) +
         Size.cy * cos((180 - Angle) * Pi / 180));
    end else
    if Angle <= 270 then
    begin
      OffsX := Trunc(Size.cx * -cos(Angle * Pi / 180) +
        Size.cy * sin((Angle - 180) * Pi / 180));
      OffsY := Trunc(Size.cy * sin((270 - Angle) * Pi / 180));
    end else
    if Angle <= 360 then
    begin
      OffsX := Trunc(Size.cy * sin((360 - Angle) * Pi / 180));
      OffsY := 0;
    end;
    TextTop := OffsY;
    TextLeft := OffsX;
  end;

  function NeedOffsetCalc: Boolean;
  begin
    Result := (TGtk4DeviceContext(DC).CurrentFont.LogFont.lfOrientation <> 0) and
        (Flags and DT_SINGLELINE <> 0) and
        (Flags and DT_VCENTER = 0) and (Flags and DT_CENTER = 0) and
        (Flags and DT_RIGHT = 0) and (Flags and  DT_BOTTOM = 0) and
        (Flags and DT_CALCRECT = 0) and not IsRectEmpty(SavedRect);
  end;


  procedure DrawLineRaw(theLine: PChar; LineLength, TopPos: Longint);
  var
    Points: array[0..1] of TSize;
    LeftPos: Longint;
  begin
    if LeftOffset <> DT_LEFT then
      GetTextExtentPoint(DC, theLine, LineLength, {%H-}Points[0]);

    if TempBrush = HBRUSH(-1) then
      TempBrush := SelectObject(DC, GetStockObject(NULL_BRUSH));
    case LeftOffset of
      DT_LEFT:
        LeftPos := theRect.Left;
      DT_CENTER:
        LeftPos := theRect.Left + (theRect.Right - theRect.Left) div 2
                 - Points[0].cX div 2;
      DT_RIGHT:
        LeftPos := theRect.Right - Points[0].cX;
    end;

    Pt := Point(0, 0);
    // Draw line of Text
    if NeedOffsetCalc then
    begin
      Pt.X := SavedRect.Left;
      Pt.Y := SavedRect.Top;
      CalculateOffsetWithAngle(TGtk4DeviceContext(DC).CurrentFont.LogFont.lfOrientation, Pt.X, Pt.Y);
    end;
    TextUtf8Out(DC, LeftPos + Pt.X, TopPos + Pt.Y, theLine, lineLength);
  end;

  procedure DrawLine(theLine: PChar; LineLength, TopPos: Longint);
  var
    Points: array[0..1] of TSize;
    LogP: TLogPen;
    LeftPos: Longint;
  begin
    if TempBrush = HBRUSH(-1) then
      TempBrush := SelectObject(DC, GetStockObject(NULL_BRUSH));

    FillByte({%H-}Points[0],SizeOf(Points[0])*2,0);
    if LeftOffset <> DT_Left then
      GetTextExtentPoint(DC, theLine, LineLength, Points[0]);

    case LeftOffset of
      DT_LEFT:
        LeftPos := theRect.Left;
      DT_CENTER:
        LeftPos := theRect.Left + (theRect.Right - theRect.Left) div 2
                 - Points[0].cX div 2;
      DT_RIGHT:
        LeftPos := theRect.Right - Points[0].cX;
    end;

    Pt := Point(0, 0);
    if NeedOffsetCalc then
    begin
      Pt.X := SavedRect.Left;
      Pt.Y := SavedRect.Top;
      CalculateOffsetWithAngle(TGtk4DeviceContext(DC).CurrentFont.LogFont.lfOrientation, Pt.X, Pt.Y);
    end;
    // Draw line of Text
    TextUtf8Out(DC, LeftPos + Pt.X, TopPos + Pt.Y, theLine, LineLength);

    // Draw Prefix
    if (pIndex > 0) and (pIndex<=LineLength) then
    begin
      // Create & select pen of font color
      if TempPen = HPEN(-1) then
      begin
        LogP.lopnStyle := PS_SOLID;
        LogP.lopnWidth.X := 1;
        LogP.lopnColor := GetTextColor(DC);
        TempPen := SelectObject(DC, CreatePenIndirect(LogP));
      end;

      {Get prefix line position}
      GetTextExtentPoint(DC, theLine, pIndex - 1, Points[0]);
      Points[0].cX := LeftPos + Points[0].cX;
      Points[0].cY := TopPos + tm.tmHeight - TM.tmDescent + 1;

      GetTextExtentPoint(DC, @aStr[pIndex], UTF8CodepointSize(@aStr[pIndex]), Points[1]);
      Points[1].cX := Points[0].cX + Points[1].cX;
      Points[1].cY := Points[0].cY;

      {Draw prefix line}
      Polyline(DC, PPoint(@Points[0]), 2);
    end;
  end;
begin
  Result := 0;
  if (Str=nil) or (Str[0]=#0) or not IsValidDC(DC) then
  begin
    exit;
  end;

  if (Count < -1) or (IsRectEmpty(Rect) and
    ((Flags and DT_CALCRECT = 0) and (Flags and DT_NOCLIP = 0))) then Exit;

  // Don't try to use StrLen(Str) in cases count >= 0
  // In those cases str is NOT required to have a null terminator !
  if Count = -1 then
    Count := StrLen(Str);

  Lines := nil;
  NumLines := 0;
  TempDC := HDC(-1);
  TempPen := HPEN(-1);
  TempBrush := HBRUSH(-1);
  try
    if (Flags and (DT_SINGLELINE or DT_CALCRECT or DT_NOPREFIX or DT_NOCLIP or DT_EXPANDTABS)) =
       (DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP) then
    begin
      System.Move(Rect, TheRect, SizeOf(TRect));
      SavedRect := Rect;
      DrawLineRaw(Str, Count, Rect.Top);
      Result := Rect.Bottom - Rect.Top;
      Exit;
    end;

    SetLength(AStr{%H-},Count);
    if Count>0 then
      System.Move(Str^,AStr[1],Count);

    if (Flags and DT_EXPANDTABS) <> 0 then
      AStr := StringReplace(AStr, #9, TabString, [rfReplaceAll]);

    if (Flags and DT_NOPREFIX) <> DT_NOPREFIX then
      pIndex := DeleteAmpersands(AStr)
    else
      pIndex := -1;

    GetTextMetrics(DC, TM{%H-});
    DoCalcRect;
    Result := theRect.Bottom - theRect.Top;
    if (Flags and DT_CALCRECT) = DT_CALCRECT then
    begin
      System.Move(TheRect, Rect, SizeOf(TRect));
      exit;
    end;

    TempDC := SaveDC(DC);

    if (Flags and DT_NOCLIP) <> DT_NOCLIP then
    begin
      if theRect.Right > Rect.Right then
        theRect.Right := Rect.Right;
      if theRect.Bottom > Rect.Bottom then
        theRect.Bottom := Rect.Bottom;
      IntersectClipRect(DC, theRect.Left, theRect.Top,
        theRect.Right, theRect.Bottom);
    end;

    if (Flags and DT_SINGLELINE) = DT_SINGLELINE
    then begin
      SavedRect := TheRect;
      DrawLine(PChar(AStr), length(AStr), theRect.Top);
      Exit; //we're ready
    end;

    // multiple lines
    if Lines = nil then Exit;  // nothing to do
    if NumLines = 0 then Exit; //


    SavedRect := Classes.Rect(0, 0, 0, 0); // no font orientation change if multilined text
    for i := 0 to NumLines - 1 do
    begin
      if theRect.Top > theRect.Bottom then Break;

      if  ((Flags and DT_EDITCONTROL) = DT_EDITCONTROL)
      and (tm.tmHeight > (theRect.Bottom - theRect.Top+1))
      then Break;

      if Lines[i] <> nil then
      begin
        l:=StrLen(Lines[i]);
        DrawLine(Lines[i], l, theRect.Top);
        dec(pIndex,l+length(LineEnding));
        Size:=default(TSize);
        GetTextExtentPoint(DC, Lines[i], l, Size);
        LineHeight := Size.cY;
      end
      else
        LineHeight := TM.tmHeight;
      Inc(theRect.Top, LineHeight + TM.tmExternalLeading); // space between lines
    end;

  finally
    Reallocmem(Lines, 0);
    if TempBrush <> HBRUSH(-1) then
      SelectObject(DC, TempBrush);// DeleteObject not needed here, because it was a default Brush
    if TempPen <> HPEN(-1) then
      DeleteObject(SelectObject(DC, TempPen));
    if TempDC <> HDC(-1) then
      RestoreDC(DC, TempDC);
  end;
end;

function TGtk4WidgetSet.Ellipse(DC: HDC; x1, y1, x2, y2: Integer): Boolean;
var
  bFill, bBorder: Boolean;
begin
  bFill := TGtk4DeviceContext(DC).CurrentBrush.Style <> BS_NULL;
  bBorder := TGtk4DeviceContext(DC).CurrentPen.Style <> psClear;
  TGtk4DeviceContext(DC).drawEllipse(x1, y1, x2 - x1 - 1, y2 - y1 - 1, bFill, bBorder);
  Result := True;
end;

function TGtk4WidgetSet.EnableScrollBar(Wnd: HWND; wSBflags, wArrows: Cardinal
  ): Boolean;
begin
  { Not implemented — same as GTK2 and Qt5. }
  Result := False;
end;

function TGtk4WidgetSet.EnableWindow(hWnd: HWND; bEnable: Boolean): Boolean;
begin
  Result := False;
  if hWnd <> 0 then
  begin
    Result := TGtk4Widget(HWND).Enabled;
    TGtk4Widget(HWND).Enabled := bEnable;
  end;
end;

function TGtk4WidgetSet.EndPaint(Handle: hwnd; var PS: TPaintStruct): Integer;
begin
  Result := 0;
  if IsValidDC(PS.HDC) then
  begin
    TGtk4DeviceContext(PS.HDC).Free;
    PS.HDC := 0;
    Result := 1;
  end;
end;

procedure TGtk4WidgetSet.EnterCriticalSection(var CritSection: TCriticalSection
  );
var
  ACritSec: System.PRTLCriticalSection;
begin
  ACritSec:=System.PRTLCriticalSection(CritSection);
  System.EnterCriticalsection(ACritSec^);
end;

function TGtk4WidgetSet.EnumDisplayMonitors(hdc: HDC; lprcClip: PRect;
  lpfnEnum: MonitorEnumProc; dwData: LPARAM): LongBool;
var
  ADisplay: PGdkDisplay;
  AMonitors: PGListModel;
  i: guint;
  ACount: guint;
begin
  Result := True;
  ACount := 0;
  ADisplay := gdk_display_get_default;
  if ADisplay <> nil then
  begin
    AMonitors := gtk4_display_get_monitors(ADisplay);
    if AMonitors <> nil then
      ACount := g_list_model_get_n_items(AMonitors);
  end;
  if ACount = 0 then
  begin
    { GTK4 under headless/xvfb may report 0 monitors.
      Emit one synthetic primary monitor so the LCL has a valid TMonitor.
      GetMonitorInfo handles HMONITOR(1) with 0 real monitors. }
    lpfnEnum(HMONITOR(1), 0, nil, dwData);
    Exit;
  end;
  for i := 0 to ACount - 1 do
  begin
    { HMONITOR is 1-based index (LCL convention) }
    Result := Result and lpfnEnum(HMONITOR(i + 1), 0, nil, dwData);
    if not Result then Break;
  end;
end;

function TGtk4WidgetSet.EnumFontFamiliesEx(DC: HDC; lpLogFont: PLogFont;
  Callback: FontEnumExProc; Lparam: LParam; Flags: dword): longint;
type
  TPangoFontFaces = packed record
    FamilyName: String;
    Faces: Array of String;
  end;
  PPangoFontFaces = Array of TPangoFontFaces;

var
  i: Integer;
  FontType: Integer;
  EnumLogFont: TEnumLogFontEx;
  Metric: TNewTextMetricEx;
  FontList: TStringList;
  Faces: PPangoFontFaces;

  AStyle: String;
  StylesCount: Integer;
  StylesList: TStringList;
  y: Integer;
  CharsetList: TByteList;
  CS: Byte;

  function Gtk4GetFontFamiliesDefault(var AList: TStringList): Integer;
  var
    i, j: Integer;
    AFamilies: PPPangoFontFamily;
    AFaces: PPPangoFontFace;
    ANumFaces: Integer;
    AContext: PPangoContext;
  begin
    AList.Clear;
    SetLength(Faces, 0);
    Result := -1;
    AFamilies := nil;

    AContext := pango_context_new();
    pango_context_list_families(AContext, @AFamilies, @Result);
    SetLength(Faces, Result);
    for i := 0 to Result - 1 do
    begin
      j := AList.Add(StrPas(pango_font_family_get_name(AFamilies[i])));
      AList.Objects[j] := TObject(PtrUInt(pango_font_family_is_monospace(AFamilies[i])));
      Faces[i].FamilyName := AList[j];
      AFaces := nil;
      pango_font_family_list_faces(AFamilies[i], @AFaces, @ANumFaces);
      SetLength(Faces[i].Faces, ANumFaces);
      for j := 0 to ANumFaces - 1 do
        Faces[i].Faces[j] := StrPas(pango_font_face_get_face_name(AFaces[j]));
      g_free(AFaces);
    end;
    g_free(AFamilies);
    g_object_unref(AContext);
  end;

  function Gtk4GetFontFamilies(var List: TStringList;
    const APitch: Byte;
    const AFamilyName: String;
    const {%H-}AWritingSystem: Byte): Integer;
  var
    StrLst: TStringList;
    NewList: TStringList;
    S: String;
    j: integer;
  begin
    Result := -1;
    StrLst := TStringList.Create;
    NewList := TStringList.Create;

    try
      Gtk4GetFontFamiliesDefault(StrLst);
      for j := 0 to StrLst.Count - 1 do
      begin
        S := StrLst[j];
        if APitch <> DEFAULT_PITCH then
        begin
          case APitch of
            FIXED_PITCH, MONO_FONT:
            begin
              if StrLst.Objects[j] <> nil then
                NewList.Add(S);
            end;
            VARIABLE_PITCH:
            begin
              if StrLst.Objects[j] = nil then
                NewList.Add(S);
            end;
          end;
        end else
          NewList.Add(S);
      end;

      if AFamilyName <> '' then
      begin
        for j := NewList.Count - 1 downto 0 do
        begin
          S := NewList[j];;
          if S <> AFamilyName then
            NewList.Delete(J);
        end;
      end;
      for j := 0 to NewList.Count - 1 do
      begin
        S := NewList[j];
        List.Add(S);
      end;
      Result := List.Count;
    finally
      StrLst.Free;
      NewList.Free;
    end;
  end;

  function GetStyleAt(AIndex: Integer): String;
  var
    S: String;
  begin
    Result := '';
    if (AIndex >= 0) and (AIndex < StylesList.Count) then
    begin
      S := StylesList[AIndex];
      Result := S;
    end;
  end;

  function FillLogFontA(const AIndex: Integer; var ALogFontA: TLogFontA;
    var {%H-}AMetric: TNewTextMetricEx; var {%H-}AFontType: Integer;
    out AStyle: String): Integer;
  var
    Font: PPangoFontDescription;
    FontStyle: TPangoStyle;
    FontWeight: TPangoWeight;
    S: String;
    i: Integer;
  begin
    S := FontList[AIndex];
    Font := pango_font_description_from_string(PChar(S));
    try
      FontStyle := pango_font_description_get_style(Font);
      FontWeight := pango_font_description_get_weight(Font);

      ALogFontA.lfItalic := Byte(FontStyle = PANGO_STYLE_ITALIC);

      // keep newer pango compat to LCL
      if FontWeight = PANGO_WEIGHT_BOOK {380 as of pango 1.24} then
        FontWeight := PANGO_WEIGHT_NORMAL
      else
      if FontWeight = PANGO_WEIGHT_ULTRAHEAVY {1000 as of pango 1.24} then
        FontWeight := PANGO_WEIGHT_HEAVY;

      ALogFontA.lfWeight := Integer(FontWeight);

      ALogFontA.lfHeight := pango_font_description_get_size(Font);
      if not pango_font_description_get_size_is_absolute(Font) then
        ALogFontA.lfHeight := PANGO_PIXELS(ALogFontA.lfHeight);

      StylesList.Clear;
      for i := High(Faces[AIndex].Faces) downto 0 do
        StylesList.Add(Faces[AIndex].Faces[i]);

      AStyle := '';
      Result := StylesList.Count;

      if StylesList.Count > 0  then
        AStyle := GetStyleAt(0);
    finally
      pango_font_description_free(Font);
    end;
  end;

begin
  Result := 0;
  {$ifdef VerboseEnumFonts}
  DebugLn(['[TGtk4WidgetSet.EnumFontFamiliesEx] Charset=',lpLogFont^.lfCharSet,
  ' face ',lpLogFont^.lfFaceName,' pitchAndFamily=',lpLogFont^.lfPitchAndFamily]);
  {$endif}
  Result := 0;
  Metric.ntmentm.ntmAvgWidth := 0; // just to shutup compiler
  if (lpLogFont^.lfCharSet = DEFAULT_CHARSET) and
     (lpLogFont^.lfFaceName= '') and
     (lpLogFont^.lfPitchAndFamily = 0) then
  begin
    FontType := 0;
    FontList := TStringList.create;
    try
      if Gtk4GetFontFamiliesDefault(FontList) > 0 then
      begin
        for i := 0 to FontList.Count - 1 do
        begin
          EnumLogFont.elfLogFont.lfFaceName := FontList[i];
          Result := Callback(EnumLogFont, Metric, FontType, LParam);
        end;
      end;
    finally
      FontList.free;
    end;
  end else
  begin
    Result := 0;
    FontType := TRUETYPE_FONTTYPE;
    FontList := TStringList.Create;
    StylesList := TStringList.Create;
    CharsetList := TByteList.Create;
    for i := 0 to CharsetEncodingList.Count - 1 do
    begin
      CS := TCharSetEncodingRec(CharsetEncodingList.Items[i]^).CharSet;
      if CharsetList.IndexOf(CS) = -1 then
        CharsetList.Add(CS);
    end;
    try
      if Gtk4GetFontFamilies(FontList, lpLogFont^.lfPitchAndFamily,
        lpLogFont^.lfFaceName, lpLogFont^.lfCharSet) > 0 then
      begin
        for i := 0 to FontList.Count - 1 do
        begin
          EnumLogFont.elfLogFont.lfFaceName := FontList[i];
          EnumLogFont.elfLogFont.lfPitchAndFamily := lpLogFont^.lfPitchAndFamily;
          EnumLogFont.elfFullName := FontList[i];

          StylesCount := FillLogFontA(i, EnumLogFont.elfLogFont, Metric, FontType, AStyle);
          EnumLogFont.elfStyle := AStyle;

          if CharSetList.Count > 0 then
            EnumLogFont.elfLogFont.lfCharSet := CharsetList.Items[0];

          Result := Callback(EnumLogFont, Metric, FontType, LParam);
          for y := 1 to StylesCount - 1 do
          begin
            AStyle := GetStyleAt(y);
            EnumLogFont.elfStyle := AStyle;
            Result := Callback(EnumLogFont, Metric, FontType, LParam);
          end;
          for y := 1 to CharSetList.Count - 1 do
          begin
            EnumLogFont.elfLogFont.lfCharSet := CharsetList.Items[y];
            Result := Callback(EnumLogFont, Metric, FontType, LParam);
          end;
        end;
      end;
    finally
      CharSetList.Free;
      StylesList.Free;
      FontList.Free;
    end;
  end;
end;

function TGtk4WidgetSet.EqualRgn(Rgn1: HRGN; Rgn2: HRGN): Boolean;
begin
  Result := Rgn1 = Rgn2;
  if Result then
    exit;
  if not IsValidGDIObject(Rgn1) or not IsValidGDIObject(Rgn2) then
    exit;
  Result := cairo_region_equal(TGtk4Region(Rgn1).Handle,TGtk4Region(Rgn2).Handle);
end;

function TGtk4WidgetSet.IntersectClipRect(dc: hdc; Left, Top, Right,Bottom: Integer): Integer;
var
  rgn, clip: HRGN;
begin
  rgn := Self.CreateRectRgn(Left, Top, Right, Bottom);
  clip := Self.CreateEmptyRegion;
  Self.GetClipRGN(dc, clip);
  Result := Self.CombineRgn(clip, rgn, clip, RGN_AND);
  Self.SelectClipRGN(dc, clip);
  DeleteObject(clip);
  DeleteObject(rgn);
end;


function TGtk4WidgetSet.ExcludeClipRect(dc: hdc; Left, Top, Right,
  Bottom: Integer): Integer;
var
  rgn, clip: HRGN;
begin
  rgn := Self.CreateRectRgn(Left, Top, Right, Bottom);
  clip := Self.CreateEmptyRegion;
  Self.GetClipRGN(dc, clip);
  Result := Self.CombineRgn(clip, clip, rgn, RGN_DIFF);
  Self.SelectClipRGN(dc, clip);
  DeleteObject(clip);
  DeleteObject(rgn);
end;

function TGtk4WidgetSet.ExtCreatePen(dwPenStyle, dwWidth: DWord;
  const lplb: TLogBrush; dwStyleCount: DWord; lpStyle: PDWord): HPEN;
var
  APen: TGtk4Pen;
begin
  APen := TGtk4Pen.Create;
  APen.IsExtPen := True;
  case dwPenStyle and PS_STYLE_MASK of
    PS_SOLID: APen.Style := psSolid;
    PS_DASH: APen.Style := psDash;
    PS_DOT: APen.Style := psDot;
    PS_DASHDOT: APen.Style := psDashDot;
    PS_DASHDOTDOT: APen.Style := psDashDotDot;
    PS_NULL: APen.Style := psClear;
  else
    APen.Style := psSolid;
  end;

  APen.Cosmetic := (dwPenStyle and PS_TYPE_MASK) = PS_COSMETIC;

  if (dwPenStyle and PS_TYPE_MASK) = PS_GEOMETRIC then
  begin
    APen.Width := dwWidth;
    case dwPenStyle and PS_JOIN_MASK of
      PS_JOIN_ROUND: APen.JoinStyle := pjsRound;
      PS_JOIN_BEVEL: APen.JoinStyle := pjsBevel;
      PS_JOIN_MITER: APen.JoinStyle := pjsMiter;
    end;
    case dwPenStyle and PS_ENDCAP_MASK of
      PS_ENDCAP_ROUND: APen.EndCap := pecRound;
      PS_ENDCAP_SQUARE: APen.EndCap := pecSquare;
      PS_ENDCAP_FLAT: APen.EndCap := pecFlat;
    end;
  end;

  if ((dwPenStyle and PS_STYLE_MASK) = PS_USERSTYLE) and (dwStyleCount > 0) and (lpStyle <> nil) then
  begin
    APen.Style := psPattern;
    APen.SetDashes(lpStyle, dwStyleCount);
  end;

  APen.Color := TColor(lplb.lbColor);  // ColorToRGB() ?
  APen.LogPen.lopnColor := lplb.lbColor;
  APen.LogPen.lopnStyle := (dwPenStyle and PS_STYLE_MASK) or (dwPenStyle and PS_JOIN_MASK) or (dwPenStyle and PS_ENDCAP_MASK);
  APen.LogPen.lopnWidth.X := dwWidth;
  APen.LogPen.lopnWidth.Y := dwWidth;

  Result := HPen(APen);
end;

function TGtk4WidgetSet.ExtSelectClipRGN(dc: hdc; rgn: hrgn; Mode: Longint): Integer;
var
  GtkDC: TGtk4DeviceContext absolute DC;
  ARect: TGdkRectangle;
  DCOrigin: TPoint;
  R: Classes.TRect;
  Clip: HRGN;
  Tmp: HRGN;
  cx1, cy1, cx2, cy2: double;
begin
  if not IsValidDC(DC) then
  begin
    Result := ERROR;
    exit;
  end else
    Result := SIMPLEREGION;
  case Mode of
    RGN_COPY: Result := SelectClipRGN(DC, RGN);
      RGN_OR,
      RGN_XOR,
      RGN_AND:
        begin
          // as MSDN says only RGN_COPY allows NULL RGN param.
          if not IsValidGDIObject(RGN) then
          begin
            Result := ERROR;
            exit;
          end;
          // get existing clip
          { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents. }
          cairo_clip_extents(GtkDC.pcr, @cx1, @cy1, @cx2, @cy2);
          ARect.x := Trunc(cx1); ARect.y := Trunc(cy1);
          ARect.width := Ceil(cx2) - ARect.x; ARect.height := Ceil(cy2) - ARect.y;
          R := RectFromGdkRect(ARect);
          if IsRectEmpty(R) then
          begin
            // no clip, just select RGN
            Result := SelectClipRGN(DC, RGN);
            exit;
          end;

          // get transformation
          GetWindowOrgEx(DC, @DCOrigin);
          // OffsetRect(R, -DCOrigin.X, -DCOrigin.Y);
          Clip := CreateRectRGN(0, 0, R.Right - R.Left, R.Bottom - R.Top);

          cairo_region_translate(TGtk4Region(Clip).Handle, -DCOrigin.X, -DCOrigin.Y);

          // create target clip
          Tmp := CreateEmptyRegion;
          // CreateEmptyRegion;
          // combine
          Result := CombineRGN(Tmp, Clip, RGN, Mode);
          // commit
          SelectClipRGN(DC, Tmp);
          // clean up
          DeleteObject(Clip);
          DeleteObject(Tmp);
        end;
      RGN_DIFF:
      begin
        { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents. }
        cairo_clip_extents(GtkDC.pcr, @cx1, @cy1, @cx2, @cy2);
        ARect.x := Trunc(cx1); ARect.y := Trunc(cy1);
        ARect.width := Ceil(cx2) - ARect.x; ARect.height := Ceil(cy2) - ARect.y;
        R := RectFromGdkRect(ARect);
        if IsRectEmpty(R) then
        begin
          // no clip, just select RGN
          Result := SelectClipRGN(DC, RGN);
          exit;
        end;

        Clip := CreateRectRGN(R.Left, R.Top, R.Right, R.Bottom);

        Tmp := CreateEmptyRegion;
        Result := CombineRGN(Tmp, HRGN(Clip), RGN, MODE);

        SelectClipRGN(DC, Tmp);
        DeleteObject(Clip);
        DeleteObject(Tmp);
      end;
  end;
end;

function TGtk4WidgetSet.ExtTextOut(DC: HDC; X, Y: Integer; Options: Longint;
  Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean;
var
  DevCtx: TGtk4DeviceContext absolute DC;
  LineStart, LineEnd, StrEnd: PChar;
  TopY, LineLen, LineHeight: Integer;
  TxtPt: TPoint;
  CurDx: PInteger;
  CurStr: PChar;

  function FindLineLen(p: PChar; Max: integer): integer;
  begin
    Result:=0;
    while Result<Max do begin
      if p[Result] in [#10,#13] then exit;
      inc(Result);
    end;
    Result:=-1;
  end;

  procedure DoTextOut(X,Y : Integer; Str: Pchar; CurCount: Integer);
  var
    CurScreenX: LongInt;
    CharLen: LongInt;
  begin
    if (Dx <> nil) then
    begin
      CurScreenX := X;
      while CurCount > 0 do
      begin
        CharLen := UTF8CodepointSize(CurStr);
        DevCtx.drawText(CurScreenX, Y, CurStr, CharLen);
        inc(CurScreenX, CurDx^);
        inc(CurDx);
        inc(CurStr, CharLen);
        dec(CurCount, CharLen);
      end;
    end
    else begin
      DevCtx.drawText(X, Y, Str, Count);
    end;
  end;

begin
  Result := False;
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn(Format('TGtk4WidgetSet.ExtTextOut x=%d y=%d Text=%s count=%d ',[X, Y, String(Str), Count]));
  {$ENDIF}
  if IsValidDC(DC)then
  begin
    cairo_save(DevCtx.pcr);
    if Options and ETO_CLIPPED = ETO_CLIPPED then
    begin
      cairo_rectangle(DevCtx.pcr, Rect^.Left, Rect^.Top, Rect^.Right - Rect^.Left, Rect^.Bottom - Rect^.Top);
      cairo_clip(DevCtx.pcr);
    end;
    if Options and ETO_OPAQUE = ETO_OPAQUE then
      DevCtx.fillRect(Rect, HBRUSH(DevCtx.CurrentBrush));

    LineLen := FindLineLen(Str,Count);
    TopY := Y;
    TxtPt.X := X;;
    LineHeight := DevCtx.CurrentPen.Width; // Cairo assumes Heigh = Width
    TxtPt.Y := TopY;;

    CurDx:=Dx;
    CurStr:=Str;
    LineStart:=Str;
    if LineLen < 0 then
    begin
      LineLen:=Count;
      if Count> 0 then
        DoTextOut(TxtPt.X, TxtPt.Y, LineStart, LineLen);
    end else
    begin  //write multiple lines
      StrEnd := Str + Count;
      while LineStart < StrEnd do
      begin
        LineEnd := LineStart + LineLen;
        if LineLen>0 then
          DoTextOut(TxtPt.X, TxtPt.Y, LineStart, LineLen);
        inc(TxtPt.Y, LineHeight);
        LineStart := LineEnd + 1; // skip #13
        if (LineStart<StrEnd) and (LineStart^ in [#10,#13])
        and (LineStart^ <> LineEnd^) then
          inc(LineStart); // skip #10
        Count := StrEnd - LineStart;
        LineLen := FindLineLen(LineStart, Count);
        if LineLen < 0 then
          LineLen := Count;
      end;
    end;
    cairo_restore(DevCtx.pcr);
    Result := True;
  end;
end;

function TGtk4WidgetSet.FillRect(DC: HDC; const Rect: TRect; Brush: HBRUSH
  ): Boolean;
begin
  Result := False;
  if IsValidDC(DC) then
  begin
    with Rect do
      TGtk4DeviceContext(DC).fillRect(Left, Top, Right - Left, Bottom - Top, Brush);
    Result := True;
  end;
end;

{------------------------------------------------------------------------------
  Function: GradientFill
  Params: DC - DeviceContext to perform on
          Vertices - array of Points W/Color & Alpha
          NumVertices - Number of Vertices
          Meshes - array of Triangle or Rectangle Meshes
          NumMeshes - Number of Meshes
          Mode - GRADIENT_FILL_RECT_H, GRADIENT_FILL_RECT_V, or
                 GRADIENT_FILL_TRIANGLE

  Performs gradient fills using Cairo linear patterns.
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.GradientFill(DC: HDC; Vertices: PTriVertex;
  NumVertices: Longint; Meshes: Pointer; NumMeshes: Longint; Mode: Longint
  ): Boolean;
var
  Ctx: TGtk4DeviceContext;

  function DoFillTriangle: Boolean;
  begin
    Result := (Mode and GRADIENT_FILL_TRIANGLE) = GRADIENT_FILL_TRIANGLE;
  end;

  function DoFillVRect: Boolean;
  begin
    Result := (Mode and GRADIENT_FILL_RECT_V) = GRADIENT_FILL_RECT_V;
  end;

  function FillTriMesh({%H-}Mesh: tagGradientTriangle): Boolean;
  begin
    { Triangle gradient not implemented (same as GTK2/GTK3) }
    Result := False;
  end;

  function FillRectMesh(Mesh: tagGradientRect): Boolean;
  var
    TL, BR: tagTRIVERTEX;
    Pattern: Pcairo_pattern_t;
    Swap: Longint;
    SwapColors: Boolean;
    R1, G1, B1, R2, G2, B2: Double;
  begin
    with Mesh do
    begin
      Result := (UpperLeft < Cardinal(NumVertices)) and
        (LowerRight < Cardinal(NumVertices));
      if (LowerRight = UpperLeft) or not Result then
        Exit;
      TL := Vertices[UpperLeft];
      BR := Vertices[LowerRight];

      SwapColors := (BR.Y < TL.Y) and (BR.X < TL.X);
      if BR.X < TL.X then
      begin
        Swap := BR.X;
        BR.X := TL.X;
        TL.X := Swap;
      end;
      if BR.Y < TL.Y then
      begin
        Swap := BR.Y;
        BR.Y := TL.Y;
        TL.Y := Swap;
      end;

      { Convert 16-bit color components to 0..1 range }
      R1 := TL.Red / 65535.0;
      G1 := TL.Green / 65535.0;
      B1 := TL.Blue / 65535.0;
      R2 := BR.Red / 65535.0;
      G2 := BR.Green / 65535.0;
      B2 := BR.Blue / 65535.0;
      if SwapColors then
      begin
        Pattern := nil; { suppress warning }
        { swap start/end colors }
        R1 := BR.Red / 65535.0; G1 := BR.Green / 65535.0; B1 := BR.Blue / 65535.0;
        R2 := TL.Red / 65535.0; G2 := TL.Green / 65535.0; B2 := TL.Blue / 65535.0;
      end;

      { Create linear gradient pattern }
      if DoFillVRect then
        Pattern := cairo_pattern_create_linear(0, TL.Y, 0, BR.Y)
      else
        Pattern := cairo_pattern_create_linear(TL.X, 0, BR.X, 0);

      cairo_pattern_add_color_stop_rgb(Pattern, 0.0, R1, G1, B1);
      cairo_pattern_add_color_stop_rgb(Pattern, 1.0, R2, G2, B2);

      cairo_save(Ctx.pcr);
      try
        cairo_set_source(Ctx.pcr, Pattern);
        cairo_rectangle(Ctx.pcr, TL.X, TL.Y, BR.X - TL.X, BR.Y - TL.Y);
        cairo_fill(Ctx.pcr);
      finally
        cairo_restore(Ctx.pcr);
      end;
      cairo_pattern_destroy(Pattern);
    end;
  end;

var
  I: Integer;
begin
  Result := (Meshes <> nil) and (NumMeshes >= 1) and (NumVertices >= 2)
            and (Vertices <> nil) and IsValidDC(DC);
  if not Result then Exit;
  Ctx := TGtk4DeviceContext(DC);
  if DoFillTriangle then
    Result := NumVertices >= 3;
  if not Result then Exit;

  Result := False;
  for I := 0 to NumMeshes - 1 do
  begin
    if DoFillTriangle then
    begin
      if not FillTriMesh(PGradientTriangle(Meshes)[I]) then
        Exit;
    end
    else
    begin
      if not FillRectMesh(PGradientRect(Meshes)[I]) then
        Exit;
    end;
  end;
  Result := True;
end;

function TGtk4WidgetSet.FillRgn(DC: HDC; RegionHnd: HRGN; hbr: HBRUSH): Bool;
var
  R: TRect;
begin
  Result := False;
  if IsValidDC(DC) and IsValidGDIObject(RegionHnd) then
  begin
    R := TGtk4Region(RegionHnd).GetExtents;
    TGtk4DeviceContext(DC).fillRect(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top);
    Result := True;
  end;
end;

function TGtk4WidgetSet.Frame3d(DC: HDC; var ARect: TRect;
  const FrameWidth: integer; const Style: TBevelCut): Boolean;
const
  PixelOffset = 0.5;
  NColorLight = clWindow;
  NColorDark = clBtnShadow;
var
  Color1, Color2: TGdkRGBA;
  cr: Pcairo_t;
  i: Integer;
begin
  Result := False;
  if not IsValidDC(DC) then
    Exit;
  Result := True;
  if FrameWidth <= 0 then
    Exit;

  case Style of
    bvNone:
      Exit;
    bvSpace:
      begin
        InflateRect(ARect, -FrameWidth, -FrameWidth);
        Exit;
      end;
    bvRaised:
      begin
        Color1 := TColorToTGdkRGBA(ColorToRGB(NColorLight));
        Color2 := TColorToTGdkRGBA(ColorToRGB(NColorDark));
      end;
    bvLowered:
      begin
        Color1 := TColorToTGdkRGBA(ColorToRGB(NColorDark));
        Color2 := TColorToTGdkRGBA(ColorToRGB(NColorLight));
      end;
  end;

  cr := TGtk4DeviceContext(DC).pcr;
  cairo_save(cr);
  try
    cairo_set_line_width(cr, 1);
    cairo_set_line_cap(cr, Tcairo_line_cap_t.CAIRO_LINE_CAP_ROUND);
    cairo_set_line_join(cr, Tcairo_line_join_t.CAIRO_LINE_JOIN_ROUND);

    for i := 1 to FrameWidth do
    begin
      cairo_set_source_rgb(cr, Color1.red, Color1.green, Color1.blue);
      cairo_move_to(cr, ARect.Left+PixelOffset, ARect.Top+PixelOffset);
      cairo_line_to(cr, ARect.Right+PixelOffset-1, ARect.Top+PixelOffset);
      cairo_move_to(cr, ARect.Left+PixelOffset, ARect.Top+PixelOffset);
      cairo_line_to(cr, ARect.Left+PixelOffset, ARect.Bottom+PixelOffset-1);
      cairo_stroke(cr);

      cairo_set_source_rgb(cr, Color2.red, Color2.green, Color2.blue);
      cairo_move_to(cr, ARect.Left+PixelOffset, ARect.Bottom+PixelOffset-1);
      cairo_line_to(cr, ARect.Right+PixelOffset-1, ARect.Bottom+PixelOffset-1);
      cairo_move_to(cr, ARect.Right+PixelOffset-1, ARect.Top+PixelOffset);
      cairo_line_to(cr, ARect.Right+PixelOffset-1, ARect.Bottom+PixelOffset-1);
      cairo_stroke(cr);

      InflateRect(ARect, -1, -1);
    end;
  finally
    cairo_restore(cr);
  end;
end;

function TGtk4WidgetSet.FrameRect(DC: HDC; const ARect: TRect; hBr: HBRUSH): Integer;
const
  PixelOffset = 0.5;
var
  cr: Pcairo_t;
begin
  Result := 0;
  if not IsValidDC(DC) then
    exit;
  cr := TGtk4DeviceContext(DC).pcr;
  cairo_rectangle(cr, ARect.Left+PixelOffset, ARect.Top+PixelOffset, ARect.Right-ARect.Left-1, ARect.Bottom-ARect.Top-1);
  if IsValidGDIObject(hBr) then
    TGtk4DeviceContext(DC).SetSourceColor(TGtk4Brush(HBR).Color);
  cairo_set_line_width(cr, 1);
  cairo_stroke(cr); //Don't touch
end;

function TGtk4WidgetSet.HideCaret(hWnd: HWND): Boolean;
begin
  Result := (hWnd <> 0) and (FCaret.Handle = hWnd);
  if Result then
  begin
    FCaret.Visible := False;
    { Do NOT stop the blink timer here. SynEdit calls HideCaret + ShowCaret
      every paint cycle. Stopping the timer would reset BlinkHide and prevent
      blinking. The timer continues toggling BlinkHide; DrawCaret skips when
      Visible=False so the overhead is negligible. Timer is properly cleaned
      up by DestroyCaret (on widget destruction / focus loss). }
    InvalidateCaret;
    FCaret.IsDrawn := False;
  end;
end;

function TGtk4WidgetSet.GetActiveWindow: HWND;
var
  AGtkWin: PGtkWindow;
  Hndl: HWND;
  i: Integer;
begin
  { GTK4: gdk_screen_get_active_window removed; iterate forms to find active }
  Result := 0;
  for i := 0 to Screen.FormCount - 1 do
  begin
    if Screen.Forms[i].HandleAllocated then
    begin
      Hndl := Screen.Forms[i].Handle;
      AGtkWin := PGtkWindow(TGtk4Window(Hndl).Widget);
      if AGtkWin^.is_active then
      begin
        Result := Hndl;
        break;
      end;
    end;
  end;
end;

function TGtk4WidgetSet.GetBitmapBits(Bitmap: HBITMAP; Count: Longint;
  Bits: Pointer): Longint;
var
  Img: TGtk4Image;
  ByteCount: LongWord;
begin
  Result := 0;
  if not IsValidGDIObject(Bitmap) then Exit;
  if not (TObject(Bitmap) is TGtk4Image) then Exit;
  Img := TGtk4Image(Bitmap);
  if (Img.Handle = nil) or (Img.bits = nil) then Exit;
  ByteCount := Img.numBytes;
  if Count > LongInt(ByteCount) then
    Count := LongInt(ByteCount);
  if (Count > 0) and (Bits <> nil) then
  begin
    System.Move(Img.bits^, Bits^, Count);
    Result := Count;
  end;
end;

function TGtk4WidgetSet.GetBkColor(DC: HDC): TColorRef;
begin
  Result := 0;
  if IsValidDC(DC) then
    Result := TGtk4DeviceContext(DC).CurrentBrush.Color;
end;

function TGtk4WidgetSet.GetCapture: HWND;
begin
  { GTK4: gtk_grab_get_current removed. Use our software capture tracking. }
  if Gtk4CapturedWidget <> nil then
    Result := HwndFromGtkWidget(Gtk4CapturedWidget)
  else
    Result := 0;
  {$IFDEF VerboseGtk4WinApi}
  DebugLn('TGtk4WidgetSet.GetCapture ',dbgHex(Result));
  {$ENDIF}
end;

function TGtk4WidgetSet.GetCaretPos(var lpPoint: TPoint): Boolean;
begin
  Result := FCaret.Handle <> 0;
  if Result then
  begin
    lpPoint.X := FCaret.X;
    lpPoint.Y := FCaret.Y;
  end;
end;

function TGtk4WidgetSet.GetCaretRespondToFocus(handle: HWND;
  var ShowHideOnFocus: boolean): Boolean;
begin
  Result := (handle <> 0) and (FCaret.Handle = handle);
  if Result then
    ShowHideOnFocus := FCaret.ShowHideOnFocus;
end;

function TGtk4WidgetSet.GetCharABCWidths(DC: HDC; p2, p3: UINT; const ABCStructs
  ): Boolean;
begin
  { Win32-specific. No GTK/Qt backend implements this. }
  Result := False;
end;

function TGtk4WidgetSet.GetClientBounds(handle: HWND; var ARect: TRect
  ): Boolean;
begin
  {$IF DEFINED(VerboseGtk4WinAPI) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('[Gtk4WinAPI GetClientBounds]');
  {$ENDIF}
  if Handle = 0 then
    Exit(False);
  ARect := TGtk4Widget(handle).getClientBounds;
  Result := True;
end;

function TGtk4WidgetSet.GetClientRect(handle: HWND; var ARect: TRect): Boolean;
begin
  {$IF DEFINED(VerboseGtk4WinAPI) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('[Gtk4WinAPI GetClientRect]');
  {$ENDIF}
  if Handle = 0 then
    Exit(False);
  ARect := TGtk4Widget(handle).getClientRect;
  Result := True;
end;

function TGtk4WidgetSet.GetClipBox(DC: hDC; lpRect: PRect): Longint;
var
  GtkDC: TGtk4DeviceContext absolute DC;
  cr: Pcairo_t;
  ARect: TGdkRectangle;
  cx1, cy1, cx2, cy2: double;
begin
  Result := NULLREGION;
  if lpRect <> nil then
    lpRect^ := Rect(0,0,0,0);

  if not IsValidDC(DC) then
    Result := ERROR;

  if Result <> ERROR then
  begin
    cr := GtkDC.pcr;
    { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents. }
    cairo_clip_extents(cr, @cx1, @cy1, @cx2, @cy2);
    ARect.x := Trunc(cx1); ARect.y := Trunc(cy1);
    ARect.width := Ceil(cx2) - ARect.x; ARect.height := Ceil(cy2) - ARect.y;
    if not IsRectEmpty(RectFromGdkRect(ARect)) then
    begin
      lpRect^ := RectFromGdkRect(ARect);
      Result := SimpleRegion;
    end;
  end;
end;

function TGtk4WidgetSet.GetClipRGN(DC: hDC; RGN: hRGN): Longint;
var
  RectList: Pcairo_rectangle_list_t;
  CairoRgn: Pcairo_region_t;
  ARect: Tcairo_rectangle_int_t;
  i: Integer;
begin
  Result := -1;
  if not IsValidDC(DC) or (RGN = 0) then
    exit;
  { GTK4: Use cairo_copy_clip_rectangle_list to preserve complex clip regions.
    The previous cairo_clip_extents approach returned only the bounding box,
    losing all ExcludeClipRect holes — which caused DrawGrid to show full
    vertical lines instead of individual dots. }
  RectList := cairo_copy_clip_rectangle_list(TGtk4DeviceContext(DC).pcr);
  if (RectList = nil) then
    exit(0);
  if (RectList^.status <> CAIRO_STATUS_SUCCESS) or (RectList^.num_rectangles = 0) then
  begin
    cairo_rectangle_list_destroy(RectList);
    exit(0);
  end;
  CairoRgn := cairo_region_create;
  for i := 0 to RectList^.num_rectangles - 1 do
  begin
    ARect.x := Trunc(RectList^.rectangles[i].x);
    ARect.y := Trunc(RectList^.rectangles[i].y);
    ARect.width := Ceil(RectList^.rectangles[i].x + RectList^.rectangles[i].width) - ARect.x;
    ARect.height := Ceil(RectList^.rectangles[i].y + RectList^.rectangles[i].height) - ARect.y;
    cairo_region_union_rectangle(CairoRgn, @ARect);
  end;
  cairo_rectangle_list_destroy(RectList);
  if cairo_region_is_empty(CairoRgn) then
  begin
    cairo_region_destroy(CairoRgn);
    exit(0);
  end;
  cairo_region_destroy(TGtk4Region(RGN).Handle);
  TGtk4Region(RGN).Handle := CairoRgn;
  Result := 1;
end;

function TGtk4WidgetSet.GetCmdLineParamDescForInterface: TStringList;
begin
  Result := TStringList.Create;
  AddCmdLineParamDesc(Result, ['--display <h:s:d>'], rsgtkOptionDisplay);
  AddCmdLineParamDesc(Result, ['--sync'], rsgtkOptionSync);
  AddCmdLineParamDesc(Result, ['--g-fatal-warnings'], rsgOptionFatalWarnings);
  AddCmdLineParamDesc(Result, ['--gdk-debug <flags>'], rsgdkOptionDebug);
  AddCmdLineParamDesc(Result, ['--gdk-no-debug <flags>'], rsgdkOptionNoDebug);
end;

function TGtk4WidgetSet.GetCurrentObject(DC: HDC; uObjectType: UINT): HGDIOBJ;
var
  GtkDC: TGtk4DeviceContext absolute DC;
begin
  Result := 0;
  if not IsValidDC(DC) then
    Exit;
  case uObjectType of
    OBJ_BITMAP: Result := HGDIOBJ(GtkDC.CurrentImage);
    OBJ_BRUSH: Result := HGDIOBJ(GtkDC.CurrentBrush);
    OBJ_FONT: Result := HGDIOBJ(GtkDC.CurrentFont);
    OBJ_PEN: Result := HGDIOBJ(GtkDC.CurrentPen);
    OBJ_REGION: Result := HGDIOBJ(GtkDC.CurrentRegion);
  end;
end;

function TGtk4WidgetSet.GetCursorPos(var lpPoint: TPoint): Boolean;
var
  ADisplay: PGdkDisplay;
  ASeat: PGdkSeat;
  ADevice: PGdkDevice;
  ASurface: PGdkWindow;
  NativeW: PGtkWidget;
  wx, wy: double;
  WinX, WinY: LongInt;
begin
  { GTK4: gdk_device_get_position was removed.
    Use gdk_device_get_surface_at_position which returns surface-relative coords.
    Surface coords are relative to the X11 window (GdkSurface).  Adding the
    X11 window origin gives screen-absolute coordinates directly — no CSD
    subtraction needed (the surface already starts at the X11 window edge).
    This matches ClientToScreen's coordinate system. }
  Result := False;
  lpPoint.X := 0;
  lpPoint.Y := 0;

  ADisplay := gdk4_display_get_default;
  if ADisplay = nil then exit;

  ASeat := gdk_display_get_default_seat(ADisplay);
  if ASeat = nil then exit;

  ADevice := gdk_seat_get_pointer(ASeat);
  if ADevice = nil then exit;

  ASurface := gdk4_device_get_surface_at_position(ADevice, @wx, @wy);
  if ASurface <> nil then
  begin
    NativeW := gtk4_native_get_for_surface(ASurface);
    if NativeW <> nil then
    begin
      { Add window screen position for absolute screen coordinates.
        surface_coords + X11_origin = screen-absolute. }
      if Gtk4X11GetWindowOrigin(NativeW, WinX, WinY) then
      begin
        wx := wx + WinX;
        wy := wy + WinY;
      end;
    end;
  end;
  lpPoint.X := Round(wx);
  lpPoint.Y := Round(wy);
  Result := True;
end;

function TGtk4WidgetSet.GetDC(hWnd: HWND): HDC;
var
  Widget: TGtk4Widget;
begin
  if Gtk4WidgetSet.IsValidHandle(hWnd) then
  begin
    Widget := TGtk4Widget(hWnd);
    Result := Widget.Context;
    if Result = 0 then
      Result := HDC(Gtk4DefaultContext);
  end else
    Result := HDC(Gtk4ScreenContext);
end;

function TGtk4WidgetSet.GetDCOriginRelativeToWindow(PaintDC: HDC;
  WindowHandle: HWND; var OriginDiff: TPoint): boolean;
var
  ctx: TGtk4DeviceContext;
  DCWidget, WinWidget: PGtkWidget;
  dx, dy: double;
begin
  Result := False;
  OriginDiff := Point(0, 0);
  if not IsValidDC(PaintDC) then Exit;

  ctx := TGtk4DeviceContext(PaintDC);
  DCWidget := ctx.Parent;
  if DCWidget = nil then Exit;

  if not IsValidHandle(WindowHandle) then Exit;
  WinWidget := TGtk4Widget(WindowHandle).Widget;
  if WinWidget = nil then Exit;

  { Translate DC widget origin (0,0) to the window widget's coordinate space.
    GTK4 changed translate_coordinates signature from gint to double. }
  dx := 0;
  dy := 0;
  if gtk4_widget_translate_coordinates(DCWidget, WinWidget, 0, 0, @dx, @dy) then
  begin
    { Add the DC's own offset (device offset from cairo surface) }
    OriginDiff.X := Round(dx) + ctx.fncOrigin.X;
    OriginDiff.Y := Round(dy) + ctx.fncOrigin.Y;
    Result := True;
  end;
end;

function TGtk4WidgetSet.GetDesignerDC(WindowHandle: HWND): HDC;
begin
  { For the designer, return the widget's device context (same as GetDC).
    The designer uses this to paint selection handles and guidelines. }
  Result := GetDC(WindowHandle);
end;

function TGtk4WidgetSet.GetDoubleClickTime: UINT;
var
  AValue: TGValue;
begin
  Result := 400; { default fallback }
  FillChar({%H-}AValue, SizeOf(AValue), 0);
  g_value_init(@AValue, G_TYPE_INT);
  g_object_get_property(PGObject(gtk_settings_get_default),
    'gtk-double-click-time', @AValue);
  if g_value_get_int(@AValue) > 0 then
    Result := g_value_get_int(@AValue);
  g_value_unset(@AValue);
end;

function TGtk4WidgetSet.GetDeviceCaps(DC: HDC; Index: Integer): Integer;
var
  ADisplay: PGdkDisplay;
  AMonitors: PGListModel;
  AMonitor: PGdkMonitor;
begin
  Result := 0;

  case Index of

    HORZRES : { Horizontal width in pixels }
    begin
      if IsValidDC(DC) then
      begin
        Result := TGtk4DeviceContext(DC).getDeviceSize.X;
      end else
        Result := GetSystemMetrics(SM_CXSCREEN);
    end;

    VERTRES : { Vertical height in pixels }
    begin
      if IsValidDC(DC) then
      begin
        Result := TGtk4DeviceContext(DC).getDeviceSize.Y;
      end else
        Result := GetSystemMetrics(SM_CYSCREEN);
    end;

    HORZSIZE : { Horizontal size in millimeters }
      Result := LazUtilities.RoundToInt((GetDeviceCaps(DC, HORZRES) * 100) /
                    (GetDeviceCaps(DC, LOGPIXELSX) * 25.4));

    VERTSIZE : { Vertical size in millimeters }
      Result := LazUtilities.RoundToInt((GetDeviceCaps(DC, VERTRES) * 100) /
                    (GetDeviceCaps(DC, LOGPIXELSY) * 25.4));

    BITSPIXEL:
    begin
      if IsValidDC(DC) then
        Result := TGtk4DeviceContext(DC).getDepth
      else
        Result := 32; { GTK4: gdk_window_get_visual removed; hardcode 32-bit depth }
    end;
    PLANES: Result := 1;
    SIZEPALETTE: Result := 256; { GTK4: gdk_window_get_visual removed; hardcode 256 }

    LOGPIXELSX, LOGPIXELSY : { Logical pixels per inch in X and Y }
    begin
      { Use gdk_monitor_get_scale_factor for real DPI }
      Result := 96;
      ADisplay := gdk_display_get_default;
      if ADisplay <> nil then
      begin
        AMonitors := gtk4_display_get_monitors(ADisplay);
        if (AMonitors <> nil) and (g_list_model_get_n_items(AMonitors) > 0) then
        begin
          AMonitor := PGdkMonitor(g_list_model_get_item(AMonitors, 0));
          if AMonitor <> nil then
          begin
            Result := 96 * gdk_monitor_get_scale_factor(AMonitor);
            g_object_unref(AMonitor);
          end;
        end;
      end;
    end;

    NUMCOLORS: Result := 0;  { > 8bpp, return 0 per Windows convention }
  end;

end;

function TGtk4WidgetSet.GetDeviceSize(DC: HDC; var p: TPoint): boolean;
var
  cx1, cy1, cx2, cy2: double;
begin
  Result := False;
  if not IsValidDC(DC) then
    exit;
  if TGtk4DeviceContext(DC).Parent <> nil then
  begin
    { GTK4: GdkWindow/.window removed; use widget allocation instead }
    p.X := TGtk4DeviceContext(DC).Parent^.get_allocated_width;
    p.Y := TGtk4DeviceContext(DC).Parent^.get_allocated_height;
    Result := True;
  end else
  if (TGtk4DeviceContext(DC).ParentPixmap <> nil) and
    Gtk4IsGdkPixbuf(TGtk4DeviceContext(DC).ParentPixmap) then
  begin
    p.X := TGtk4DeviceContext(DC).ParentPixmap^.get_width;
    p.Y := TGtk4DeviceContext(DC).ParentPixmap^.get_height;
    Result := True;
  end else
  if TGtk4DeviceContext(DC).pcr <> nil then
  begin
    { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents. }
    cairo_clip_extents(TGtk4DeviceContext(DC).pcr, @cx1, @cy1, @cx2, @cy2);
    p.X := Ceil(cx2) - Trunc(cx1);
    p.Y := Ceil(cy2) - Trunc(cy1);
    Result := True;
  end;
end;

function TGtk4WidgetSet.GetDIBits(DC: HDC; Bitmap: HBitmap; StartScan,
  NumScans: UINT; Bits: Pointer; var BitInfo: BitmapInfo; Usage: UINT): Integer;
var
  Img: TGtk4Image;
  SrcLineBytes, DstLineBytes: Integer;
  SrcData: PByte;
  Y: Integer;
begin
  Result := 0;
  if not IsValidGDIObject(Bitmap) then Exit;
  if not (TObject(Bitmap) is TGtk4Image) then Exit;
  Img := TGtk4Image(Bitmap);
  if (Img.Handle = nil) or (Img.bits = nil) then Exit;
  if Integer(StartScan) >= Img.height then Exit;
  if Integer(StartScan + NumScans) > Img.height then
    NumScans := UINT(Img.height) - StartScan;

  { Fill BitmapInfo header }
  with BitInfo.bmiHeader do
  begin
    biSize := SizeOf(BitInfo.bmiHeader);
    biWidth := Img.width;
    biHeight := -Img.height; { top-down DIB }
    biPlanes := 1;
    biBitCount := Img.depth;
    biCompression := 0; { BI_RGB }
    biSizeImage := 0;
    biXPelsPerMeter := Img.dotsPerMeterX;
    biYPelsPerMeter := Img.dotsPerMeterY;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  if Bits <> nil then
  begin
    SrcLineBytes := Img.bytesPerLine;
    DstLineBytes := ((Img.width * Img.depth + 31) div 32) * 4;
    SrcData := Img.bits;
    Inc(SrcData, Integer(StartScan) * SrcLineBytes);
    for Y := 0 to Integer(NumScans) - 1 do
    begin
      System.Move(SrcData^, PByte(Bits)[Y * DstLineBytes], Img.width * (Img.depth div 8));
      Inc(SrcData, SrcLineBytes);
    end;
    Result := Integer(NumScans);
  end else
    Result := Integer(NumScans);
end;

function TGtk4WidgetSet.GetDpiForMonitor(hmonitor: HMONITOR;
  dpiType: TMonitorDpiType; out dpiX: UINT; out dpiY: UINT): HRESULT;
var
  ADisplay: PGdkDisplay;
  AMonitors: PGListModel;
  AGdkMonitor: PGdkMonitor;
  AScale: gint;
  AIdx: guint;
begin
  { Default to 96 DPI }
  dpiX := 96;
  dpiY := 96;
  Result := 0;
  ADisplay := gdk_display_get_default;
  if ADisplay = nil then Exit;
  AMonitors := gtk4_display_get_monitors(ADisplay);
  if AMonitors = nil then Exit;
  AIdx := guint(hmonitor) - 1; { HMONITOR is 1-based }
  if AIdx >= g_list_model_get_n_items(AMonitors) then Exit;
  AGdkMonitor := PGdkMonitor(g_list_model_get_item(AMonitors, AIdx));
  if AGdkMonitor = nil then Exit;
  try
    { GTK4 scale factor is integer (1 = 96 DPI, 2 = 192 DPI for HiDPI) }
    AScale := gdk_monitor_get_scale_factor(AGdkMonitor);
    dpiX := UINT(96 * AScale);
    dpiY := UINT(96 * AScale);
  finally
    g_object_unref(AGdkMonitor);
  end;
end;

function TGtk4WidgetSet.GetFocus: HWND;
var
  i: Integer;
  AWidget: PGtkWidget;
  AList: PGList;
  AHandle: TGtk4Window;
  AWindow: PGtkWindow;
  AActiveWindow: HWND;
begin
  AWidget := nil;

  AActiveWindow := GetActiveWindow;
  if AActiveWindow <> 0 then
  begin
    AWidget := PGtkWindow(TGtk4Widget(AActiveWindow).Widget)^.get_focus;
  end else
  begin
    // worst case scenario is to search for widget or when application
    // isn't active anymore
    AList := gtk_window_list_toplevels;
    for i := 0 to g_list_length(AList) - 1 do
    begin
      if Gtk4IsGtkWindow(PGObject(g_list_nth(AList, i)^.data)) then
      begin
        // gtk4 this is really ugly, it returns .is_active for non active
        // windows, while docs says that is_active is window with kbd focus
        AWindow := PGtkWindow(g_list_nth(AList, i)^.data);
        AHandle := TGtk4Window(HwndFromGtkWidget(AWindow));
        if Assigned(AHandle) and (Screen.FocusedForm = AHandle.LCLObject) and
           (AWindow^.is_active) then
        begin
          AWidget := PGtkWindow(g_list_nth(AList, i)^.data)^.get_focus;
          if AWidget <> nil then
            break;
        end;
      end;
    end;
    g_list_free(AList);
  end;

  Result := HwndFromGtkWidget(AWidget);
  {$IFDEF GTK4DEBUGFOCUS}
  DebugLn('TGtk4WidgetSet.GetFocus current focus ',dbgHex(Result));
  if IsValidHandle(Result) then
    DebugLn('TGtk4WidgetSet.GetFocus current focus ',dbgsName(TGtk4Widget(Result).LCLObject));
  {$ENDIF}
end;

function TGtk4WidgetSet.GetFontLanguageInfo(DC: HDC): DWord;
var
  AFont: TGtk4Font;
  SingleW, DoubleW: gint;
begin
  Result := 0;
  if not IsValidDC(DC) then
    Exit;
  AFont := TGtk4DeviceContext(DC).CurrentFont;
  if (AFont = nil) or (AFont.Layout = nil) then
    Exit;
  { Detect double-byte character font: measure 'A' (single byte) vs #0'A'
    (double byte). A DBCS font renders the double-byte form but not the
    single-byte form. Same heuristic as GTK2 backend. }
  pango_layout_set_single_paragraph_mode(AFont.Layout, True);
  pango_layout_set_width(AFont.Layout, -1);
  pango_layout_set_text(AFont.Layout, 'A', 1);
  pango_layout_get_pixel_size(AFont.Layout, @SingleW, nil);
  pango_layout_set_text(AFont.Layout, #0'A', 2);
  pango_layout_get_pixel_size(AFont.Layout, @DoubleW, nil);
  if (SingleW = 0) and (DoubleW > 0) then
    Result := Result or GCP_DBCS;
end;

function TGtk4WidgetSet.GetForegroundWindow: HWND;
var
  i: Integer;
  AWidget: PGtkWindow;
  AWindow: PGtkWindow;
  AList: PGList;
begin
  { Keep this conservative, like gtk2/qt5 implementations.
    Returning active window avoids iterating transient widget trees in unstable states. }
  Result := GetActiveWindow;
  if Result <> 0 then
    Exit;

  Result := 0;
  AWidget := nil;
  AWindow := nil;
  AList := gtk_window_list_toplevels;
  for i := 0 to g_list_length(AList) - 1 do
  begin
    if Gtk4IsGtkWindow(PGObject(g_list_nth(AList, i)^.data)) then
    begin
      AWidget := g_list_nth(AList, i)^.data;
      if Gtk4IsWidget(PGObject(AWidget))
      and (not AWidget^.in_destruction)
      and AWidget^.is_toplevel
      and AWidget^.is_active then
      begin
        AWindow := AWidget;
        break;
      end;
    end;
  end;
  g_list_free(AList);
  Result := HwndFromGtkWidget(AWindow);
end;

function TGtk4WidgetSet.GetKeyState(nVirtKey: Integer): Smallint;
const
  StateDown    = SmallInt($FF80);
var
  ASeat: PGdkSeat;
  AKeyboard: PGdkDevice;
  AModifiers: TGdkModifierType;
begin
  Result := 0;

  case nVirtKey of
    VK_LSHIFT:   nVirtKey := VK_SHIFT;
    VK_LCONTROL: nVirtKey := VK_CONTROL;
    VK_LMENU:    nVirtKey := VK_MENU;
  end;

  { GTK4: GdkKeymap removed. Use GdkSeat/GdkDevice to query modifier state. }
  ASeat := gdk_display_get_default_seat(gdk_display_get_default);
  if ASeat = nil then
    exit;
  AKeyboard := gdk_seat_get_keyboard(ASeat);
  if AKeyboard = nil then
    exit;
  AModifiers := TGdkModifierType(gtk4_device_get_modifier_state(AKeyboard));
  case nVirtKey of
    VK_LBUTTON:
      if GDK_BUTTON1_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_RBUTTON:
      if GDK_BUTTON2_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_MBUTTON:
      if GDK_BUTTON3_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_XBUTTON1:
      if GDK_BUTTON4_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_XBUTTON2:
      if GDK_BUTTON5_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_MENU:
      if GDK_MOD1_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_SHIFT:
      if GDK_SHIFT_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_CONTROL:
      if GDK_CONTROL_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_LWIN, VK_RWIN:
      if GDK_META_MASK in AModifiers  then
        Result := Result or StateDown;
    VK_CAPITAL:
      if GDK_LOCK_MASK in AModifiers then
        Result := Result or 1; { toggled }
    VK_NUMLOCK:
      if GDK_MOD2_MASK in AModifiers then
        Result := Result or 1; { toggled }
    { VK_SCROLL: GDK has no standard modifier mask for Scroll Lock.
      On X11 it may map to Mod3 but this is not reliable. Not implemented
      in GTK2 or Qt5 either. }
   {$ifdef VerboseGtk4WinAPI}
    else
      DebugLn('TGtk4WidgetSet.GetKeyState TODO ', DbgSVKCode(Word(nVirtkey)));
   {$endif}
  end;
end;

function TGtk4WidgetSet.GetMapMode(DC: HDC): Integer;
begin
  if IsValidDC(DC) then
    Result := TGtk4DeviceContext(DC).MapMode
  else
    Result := 0;
end;

function TGtk4WidgetSet.GetMonitorInfo(Monitor: HMONITOR; lpmi: PMonitorInfo
  ): Boolean;
var
  ADisplay: PGdkDisplay;
  AMonitors: PGListModel;
  AGdkMonitor: PGdkMonitor;
  AGeometry: TGdkRectangle;
  AIdx: guint;
  ACount: guint;
  AGotGeometry: Boolean;
const
  // Guard against broken monitor geometry values from backend/driver.
  MAX_REASONABLE_MONITOR = 32768;
begin
  Result := (lpmi <> nil) and ((lpmi^.cbSize >= SizeOf(TMonitorInfo)) or (Monitor = 0));
  if not Result then Exit;
  AIdx := guint(Monitor) - 1; { HMONITOR is 1-based }
  AGotGeometry := False;
  ACount := 0;
  ADisplay := gdk_display_get_default;
  if ADisplay <> nil then
  begin
    AMonitors := gtk4_display_get_monitors(ADisplay);
    if AMonitors <> nil then
      ACount := g_list_model_get_n_items(AMonitors);
  end;
  if (ACount > 0) and (AIdx < ACount) then
  begin
    AGdkMonitor := PGdkMonitor(g_list_model_get_item(AMonitors, AIdx));
    if AGdkMonitor <> nil then
    begin
      try
        AGeometry.x := 0; AGeometry.y := 0;
        AGeometry.width := 0; AGeometry.height := 0;
        gdk_monitor_get_geometry(AGdkMonitor, @AGeometry);
        if (AGeometry.width > 0) and (AGeometry.height > 0)
        and (AGeometry.width <= MAX_REASONABLE_MONITOR)
        and (AGeometry.height <= MAX_REASONABLE_MONITOR) then
        begin
          lpmi^.rcMonitor := Bounds(AGeometry.x, AGeometry.y, AGeometry.width, AGeometry.height);
          AGotGeometry := True;
        end;
      finally
        g_object_unref(AGdkMonitor);
      end;
    end;
  end;
  if not AGotGeometry then
  begin
    { Fallback: monitor item unavailable or geometry invalid.
      Use GetSystemMetrics dimensions (has its own 1920x1080 fallback). }
    lpmi^.rcMonitor := Bounds(0, 0, GetSystemMetrics(SM_CXSCREEN),
                                     GetSystemMetrics(SM_CYSCREEN));
  end;
  { GTK4: gdk_monitor_get_workarea removed (deprecated 4.10, gone 4.12).
    Fall back to full monitor geometry. }
  lpmi^.rcWork := lpmi^.rcMonitor;
  { GTK4: gdk_monitor_is_primary removed (no primary concept in Wayland).
    Treat first monitor (index 0) as primary. }
  if AIdx = 0 then
    lpmi^.dwFlags := MONITORINFOF_PRIMARY
  else
    lpmi^.dwFlags := 0;
end;

function TGtk4WidgetSet.GetObject(GDIObj: HGDIOBJ; BufSize: Integer;
  Buf: Pointer): Integer;
begin
  Result := 0;
  if not IsValidGDIObject(GDIObj) then
  begin
    {$ifdef VerboseGtk4WinAPI}
    DebugLn('Trace:< TGtk4WidgetSet.GetObject Invalid GDI Object');
    {$endif}
    Exit;
  end;
  Result:=TGtk4ContextObject(GDIObj).Get(bufsize, buf);
end;

function TGtk4WidgetSet.GetParent(Handle: HWND): HWND;
begin
  if Handle <> 0 then
    Result := HWND(TGtk4Widget(Handle).getParent)
  else
    Result := 0;
end;

function TGtk4WidgetSet.GetProp(Handle: hwnd; Str: PChar): Pointer;
var
  AWidget: PGtkWidget;
begin
  Result := nil;
  if (Handle = 0) or (Str = nil) then
    exit;
  { IsValidHandle only checks Handle<>0; validate the pointer is a live
    TGtk4Widget before dereferencing .Widget, and guard the GtkWidget before
    g_object_get_data (mirrors SetProp). GetFocus/FindControl can hand us a
    stale handle for a widget torn down mid-autosize. }
  if not Gtk4IsLiveWidgetPointer(Pointer(Handle)) then
    exit;
  AWidget := TGtk4Widget(Handle).Widget;
  if (AWidget <> nil) and Gtk4IsObject(PGObject(AWidget)) then
    Result := g_object_get_data(PGObject(AWidget), PgChar(Str));
end;

function TGtk4WidgetSet.GetRgnBox(RGN: HRGN; lpRect: PRect): Longint;
var
  ARegion: TGtk4Region;
begin
  Result := ERROR;
  if not IsValidGDIObject(RGN) then Exit;
  if not (TObject(RGN) is TGtk4Region) then Exit;

  ARegion := TGtk4Region(RGN);
  if lpRect <> nil then
    lpRect^ := ARegion.GetExtents;

  if (ARegion.Handle = nil) or cairo_region_is_empty(ARegion.Handle) then
    Result := NULLREGION
  else if cairo_region_num_rectangles(ARegion.Handle) = 1 then
    Result := SIMPLEREGION
  else
    Result := COMPLEXREGION;
end;

function TGtk4WidgetSet.GetROP2(DC: HDC): Integer;
begin
  Result := R2_COPYPEN;
  if IsValidDC(DC) then
    Result := TGtk4DeviceContext(DC).Rop2;
end;

function TGtk4WidgetSet.GetScrollBarSize(Handle: HWND; BarKind: Integer
  ): integer;
var
  BarWidget: PGtkWidget;
  Scrolled: PGtkScrolledWindow;
begin
  Result := 0;
  if not IsValidHandle(Handle) then
    exit;
  BarWidget := nil;
  if wtScrollbar in TGtk4Widget(Handle).WidgetType then
    BarWidget := TGtk4Widget(Handle).Widget
  else
  if wtScrollingWin in TGtk4Widget(Handle).WidgetType then
  begin
    Scrolled := TGtk4ScrollableWin(Handle).GetScrolledWindow;
    if Scrolled <> nil then
    begin
      if BarKind = SM_CYVSCROLL then
        BarWidget := Scrolled^.get_vscrollbar
      else
        BarWidget := Scrolled^.get_hscrollbar;
    end;
  end;
  if BarWidget <> nil then
  begin
    if BarKind = SM_CYVSCROLL then
      Result := BarWidget^.get_allocated_width
    else
      Result := BarWidget^.get_allocated_height;
  end;
end;

function TGtk4WidgetSet.GetScrollbarVisible(Handle: HWND; SBStyle: Integer
  ): boolean;
var
  AWidget: TGtk4Widget;
  AScrollBar: PGtkScrollbar;
  ABarWidget: PGtkWidget;
begin
  Result := False;
  if not IsValidHandle(Handle) then
    exit;
  AWidget := TGtk4Widget(Handle);
  if (AWidget.LCLObject = nil)
  or (csDestroying in AWidget.LCLObject.ComponentState)
  or (csFreeNotification in AWidget.LCLObject.ComponentState) then
    exit;

  if wtScrollBar in AWidget.WidgetType then
    Result := AWidget.Visible
  else
  begin
    if wtScrollingWin in AWidget.WidgetType then
    begin
      AScrollBar := nil;
      if SBStyle = SB_Horz then
        AScrollBar := TGtk4ScrollableWin(Handle).getHorizontalScrollbar
      else
      if SBStyle = SB_Vert then
        AScrollBar := TGtk4ScrollableWin(Handle).getVerticalScrollbar;
      if AScrollBar <> nil then
      begin
        ABarWidget := PGtkWidget(AScrollBar);
        if Gtk4IsWidget(ABarWidget) and (not ABarWidget^.in_destruction) then
          { Do not query gtk_widget_get_visible on volatile scroll widgets.
            Presence of a live scrollbar widget is enough for WinAPI-style checks. }
          Result := True;
      end;
    end;
  end;
end;

function TGtk4WidgetSet.GetScrollInfo(Handle: HWND; SBStyle: Integer;
  var ScrollInfo: TScrollInfo): Boolean;
var
  Adjustment: PGtkAdjustment;
  AWidget: TGtk4Widget;
  AScrollWin: PGtkScrolledWindow;
begin
  Result := False;
  if not IsValidHandle(Handle) then
    exit;
  AWidget := TGtk4Widget(Handle);
  if (AWidget.LCLObject = nil)
  or (csDestroying in AWidget.LCLObject.ComponentState)
  or (csFreeNotification in AWidget.LCLObject.ComponentState) then
    exit;
  if not AWidget.IsWidgetOK then
    exit;
  Adjustment := nil;
  AScrollWin := nil;
  if wtScrollBar in AWidget.WidgetType then
  begin
    if Gtk4IsWidget(AWidget.Widget) and not AWidget.Widget^.in_destruction then
      { GTK4: GtkScrollbar is NOT a GtkRange. Use gtk4_scrollbar_get_adjustment. }
      Adjustment := gtk4_scrollbar_get_adjustment(AWidget.Widget);
  end
  else
  if wtScrollingWin in AWidget.WidgetType then
    AScrollWin := TGtk4ScrollableWin(Handle).GetScrolledWindow;

  case SBStyle of
    SB_Horz:
    begin
      if not Assigned(Adjustment) and Assigned(AScrollWin) then
        Adjustment := AScrollWin^.get_hadjustment;
    end;
    SB_Vert:
    begin
      if not Assigned(Adjustment) and Assigned(AScrollWin) then
        Adjustment := AScrollWin^.get_vadjustment;
    end;
    SB_CTL:
    begin

    end;
    SB_BOTH:
    begin

    end;
  end;

  if Adjustment = nil then
  begin
    DebugLn('TGtk4WidgetSet.GetScrollInfo error: cannot get PGtkAdjustment from ',dbgsName(AWidget.LCLObject));
    exit;
  end;

  // POS
  if (ScrollInfo.fMask and SIF_POS) <> 0 then
    ScrollInfo.nPos := Round(Adjustment^.Value);

  // RANGE
  if (ScrollInfo.fMask and SIF_RANGE) <> 0 then
  begin
    ScrollInfo.nMin:= Round(Adjustment^.Lower);
    ScrollInfo.nMax:= Round(Adjustment^.Upper);
  end;
  // PAGE
  if (ScrollInfo.fMask and SIF_PAGE) <> 0 then
  begin
    ScrollInfo.nPage := Round(Adjustment^.Page_Size);
  end;
  // TRACKPOS
  if (ScrollInfo.fMask and SIF_TRACKPOS) <> 0 then
  begin
    ScrollInfo.nTrackPos := Round(Adjustment^.Value);
  end;

  Result := True;
end;

function TGtk4WidgetSet.GetStockObject(Value: Integer): TLCLHandle;
begin
  Result := 0;

  case Value of
    BLACK_BRUSH:         // Black brush.
      Result := FStockBlackBrush;
    DKGRAY_BRUSH:        // Dark gray brush.
      Result := FStockDKGrayBrush;
    GRAY_BRUSH:          // Gray brush.
      Result := FStockGrayBrush;
    LTGRAY_BRUSH:        // Light gray brush.
      Result := FStockLtGrayBrush;
    NULL_BRUSH:          // Null brush (equivalent to HOLLOW_BRUSH).
      Result := FStockNullBrush;
    WHITE_BRUSH:         // White brush.
      Result := FStockWhiteBrush;

    BLACK_PEN:           // Black pen.
      Result := FStockBlackPen;
    NULL_PEN:            // Null pen.
      Result := FStockNullPen;
    WHITE_PEN:           // White pen.
      Result := FStockWhitePen;

    {System font. By default, Windows uses the system font to draw menus,
     dialog box controls, and text. In Windows versions 3.0 and later,
     the system font is a proportionally spaced font; earlier versions of
     Windows used a monospace system font.}
    DEFAULT_GUI_FONT, SYSTEM_FONT:
      begin

        If FStockSystemFont <> 0 then
        begin
          DeleteObject(FStockSystemFont);
          FStockSystemFont := 0;
        end;

        If FStockSystemFont = 0 then
          FStockSystemFont := CreateDefaultFont;
        Result := FStockSystemFont;
      end;
  end;
end;

function TGtk4WidgetSet.GetSysColor(nIndex: Integer): DWORD;
begin
  if (nIndex = COLOR_WINDOW) or (nIndex = COLOR_WINDOWTEXT) or
    (nIndex = COLOR_HIGHLIGHT) or (nIndex = COLOR_HIGHLIGHTTEXT) then
      GetStyleWidget(lgsMemo)
  else
  if (nIndex = COLOR_MENU) or (nIndex = COLOR_MENUHILIGHT) or
    (nIndex = COLOR_MENUTEXT) then
  begin
    GetStyleWidget(lgsMenu);
    GetStyleWidget(lgsMenuitem);
  end else
  if (nIndex = COLOR_MENUBAR) then
    GetStyleWidget(lgsMenuBar)
  else
  if (nIndex = COLOR_SCROLLBAR) then
    GetStyleWidget(lgsVerticalScrollbar)
  else
  if (nIndex = COLOR_BTNFACE) or (nIndex = COLOR_BTNTEXT) or
    (nIndex = COLOR_BTNSHADOW) or (nIndex = COLOR_BTNHIGHLIGHT) then
    GetStyleWidget(lgsButton)
  else
  if (nIndex = COLOR_BACKGROUND) or (nIndex = COLOR_FORM) then
    GetStyleWidget(lgsWindow);
  Result := SysColorMap[nIndex];
end;

function TGtk4WidgetSet.GetSysColorBrush(nIndex: Integer): HBrush;
begin
  if (nIndex < 0) or (nIndex > MAX_SYS_COLORS) then
  begin
    Result := 0;
    DebugLn(Format('ERROR: [TGtk4WidgetSet.GetSysColorBrush] Bad Value: %d. Valid Range between 0 and %d', [nIndex, MAX_SYS_COLORS]));
  end else
  begin
    Result := FSysColorBrushes[nIndex];
    if Result = HBRUSH(-1) then
    begin
      InitSysColorBrushes;
      Result := FSysColorBrushes[nIndex];
      if Result = HBRUSH(-1) then
        DebugLn('WARNING: GetSysColorBrush SysColorBrushes arent''t initialized properly....');
    end;
  end;
end;

function TGtk4WidgetSet.GetSystemMetrics(nIndex: Integer): Integer;
var
  AMonitors: PGListModel;
  AMonitor: PGdkMonitor;
  AGeom: TGdkRectangle;
const
  // Keep desktop metrics in sane range to avoid layout arithmetic overflow.
  MAX_REASONABLE_MONITOR = 32768;

  procedure GetPrimaryMonitorGeometry;
  var
    ADisplay: PGdkDisplay;
  begin
    ADisplay := gdk_display_get_default;
    if ADisplay <> nil then
    begin
      AMonitors := gtk4_display_get_monitors(ADisplay);
      if (AMonitors <> nil) and (g_list_model_get_n_items(AMonitors) > 0) then
      begin
        AMonitor := PGdkMonitor(g_list_model_get_item(AMonitors, 0));
        if AMonitor <> nil then
        begin
          AGeom.x := 0; AGeom.y := 0;
          AGeom.width := 0; AGeom.height := 0;
          gdk_monitor_get_geometry(AMonitor, @AGeom);
          g_object_unref(AMonitor);
          if (AGeom.width > 0) and (AGeom.height > 0)
          and (AGeom.width <= MAX_REASONABLE_MONITOR)
          and (AGeom.height <= MAX_REASONABLE_MONITOR) then
            exit;
        end;
      end;
    end;
    { Fallback if no monitor found or geometry invalid }
    AGeom.x := 0; AGeom.y := 0;
    AGeom.width := 1920; AGeom.height := 1080;
  end;

begin
  Result := 0;
  case nIndex of
    SM_CXVSCROLL,
    SM_CYHSCROLL,
    SM_CXHSCROLL,
    SM_CYVSCROLL:
      Result := 16; { scrollbar arrow button / extent }
    SM_CYCAPTION:
      Result := 30; { title bar height }
    SM_CXBORDER,
    SM_CYBORDER:
      Result := 1;  { single-pixel border }
    SM_CXDLGFRAME,
    SM_CYDLGFRAME:
      Result := 3;  { dialog frame (fixed frame) }
    SM_CYVTHUMB,
    SM_CXHTHUMB:
      Result := 16; { scrollbar thumb minimum size }
    SM_CYMENU:
      Result := 24; { menu bar height }
    SM_MOUSEPRESENT:
      Result := 1;
    SM_CXCURSOR,
    SM_CYCURSOR:
      begin
        { GTK4: gdk_display_get_maximal_cursor_size removed.
          Return 128 which is the typical maximum cursor size on modern systems. }
        Result := 128;
      end;
    SM_CXDRAG:
      Result := 2;
    SM_CYDRAG:
      Result := 2;
    SM_CXEDGE:
      Result := 2;
    SM_CYEDGE:
      Result := 2;
    SM_CXFRAME,
    SM_CYFRAME:
      Result := 4;  { sizing frame (resizable window border) }
    SM_CXDOUBLECLK,
    SM_CYDOUBLECLK:
      Result := 4;  { double-click target area }

    SM_CXICON,
    SM_CYICON:
      Result := 128;
    SM_CXSMICON,
    SM_CYSMICON:
      Result := 16; { small icon size }
    SM_CXMENUSIZE,
    SM_CYMENUSIZE:
      Result := 24; { menu bar button size }

    SM_CXMENUCHECK,
    SM_CYMENUCHECK:
      Result := 16; { menu check mark size }
    SM_MOUSEWHEELPRESENT:
      Result := 1;

    SM_CMONITORS:
      begin
        GetPrimaryMonitorGeometry; { initialises AMonitors }
        if AMonitors <> nil then
          Result := g_list_model_get_n_items(AMonitors)
        else
          Result := 1;
      end;

    SM_CXMAXIMIZED,
    SM_CXFULLSCREEN,
    SM_CXSCREEN,
    SM_CXVIRTUALSCREEN:
      begin
        GetPrimaryMonitorGeometry;
        Result := AGeom.width;
      end;
    SM_CYMAXIMIZED,
    SM_CYFULLSCREEN,
    SM_CYSCREEN,
    SM_CYVIRTUALSCREEN:
      begin
        GetPrimaryMonitorGeometry;
        Result := AGeom.height;
      end;
    SM_SWSCROLLBARSPACING:
      Result := 0;
    SM_LCLHasFormAlphaBlend:
      Result := 1;
  end;
end;

function TGtk4WidgetSet.GetTextColor(DC: HDC): TColorRef;
begin
  Result := CLR_INVALID;
  if IsValidDC(DC) then
    Result := TColorRef(TGtk4DeviceContext(DC).CurrentTextColor);
end;

function TGtk4WidgetSet.GetTextExtentPoint(DC: HDC; Str: PChar; Count: Integer;
  var Size: TSize): Boolean;
begin
  Result := False;
  if not IsValidDC(DC) then
    exit;
  if (Count <= 0) or (Str = nil) or (StrPas(Str) = '') then
  begin
    FillChar(Size, SizeOf(Size), 0);
    Exit;
  end;
  TGtk4DeviceContext(DC).CurrentFont.Layout^.set_text(Str, Count);
  TGtk4DeviceContext(DC).CurrentFont.Layout^.get_pixel_size(@Size.Cx, @Size.CY);
  //  ' avgcharwidth ',dbgs(ACharWidth div PANGO_SCALE),' avgdigitwidth ',dbgs(ADigitWidth div PANGO_SCALE));
  Result := True;
end;

function TGtk4WidgetSet.GetTextMetrics(DC: HDC; var TM: TTextMetric): Boolean;
const
  TestString: array[boolean] of string = (
    // single byte char font
    '{ABCDEFGHIJKLMNOPQRSTUVWXYZXYZabcdefghijklmnopqrstuvwxyz|_}',
    // double byte char font
    #0'{'#0'A'#0'B'#0'C'#0'D'#0'E'#0'F'#0'G'#0'H'#0'I'#0'J'#0'K'#0'L'#0'M'#0'N'
    +#0'O'#0'P'#0'Q'#0'R'#0'S'#0'T'#0'U'#0'V'#0'W'#0'X'#0'Y'#0'Z'#0'X'#0'Y'#0'Z'
    +#0'a'#0'b'#0'c'#0'd'#0'e'#0'f'#0'g'#0'h'#0'i'#0'j'#0'k'#0'l'#0'm'#0'n'#0'o'
    +#0'p'#0'q'#0'r'#0's'#0't'#0'u'#0'v'#0'w'#0'x'#0'y'#0'z'#0'|'#0'_'#0'}'
    );
var
  AFont: TGtk4Font;
  APangoMetrics: PPangoFontMetrics;
  aRect: TPangoRectangle;
  APangoWeight: TPangoWeight;
begin
  Result := False;
  if IsValidDC(DC) then
  begin
    AFont := TGtk4DeviceContext(DC).CurrentFont;

    { Return cached metrics if available }
    if AFont.MetricsValid then
    begin
      TM := AFont.CachedMetrics;
      Result := True;
      Exit;
    end;

    APangoMetrics := pango_context_get_metrics(AFont.Layout^.get_context,
      AFont.Handle, AFont.Layout^.get_context^.get_language);
    if APangoMetrics = nil then
    begin
      DebugLn(['TGtk4WidgetSet.GetTextMetrics WARNING: no pango metrics']);
      exit;
    end;
    FillChar(TM, SizeOf(TM), #0);

    TM.tmAveCharWidth := Max(1,
               PANGO_PIXELS(pango_font_metrics_get_approximate_char_width(APangoMetrics))
               );
    TM.tmAscent := PANGO_PIXELS(APangoMetrics^.get_ascent);
    TM.tmDescent := PANGO_PIXELS(APangoMetrics^.get_descent);

    TM.tmHeight := TM.tmAscent + TM.tmDescent;

    pango_layout_set_text(AFont.Layout, PChar(TestString[True]),
                          length(PChar(TestString[True])));
    pango_layout_get_extents(AFont.Layout, nil, @aRect);

    pango_layout_set_text(AFont.Layout, 'M', 1);
    pango_layout_get_pixel_size(AFont.Layout, @aRect.width, @aRect.height);
    TM.tmMaxCharWidth := Max(1,aRect.width);
    pango_layout_set_text(AFont.Layout, 'W', 1);
    pango_layout_get_pixel_size(AFont.Layout, @aRect.width, @aRect.height);
    TM.tmMaxCharWidth := Max(TM.tmMaxCharWidth,aRect.width);

    APangoWeight := AFont.Handle^.get_weight;

    if APangoWeight < PANGO_WEIGHT_THIN then
      APangoWeight := PANGO_WEIGHT_THIN;
    if APangoWeight > PANGO_WEIGHT_HEAVY then
      APangoWeight := PANGO_WEIGHT_HEAVY;

    TM.tmWeight := Integer(APangoWeight);

    TM.tmFirstChar := 'a';
    TM.tmLastChar := 'z';
    TM.tmDefaultChar := 'x';
    TM.tmBreakChar := '?';

    TM.tmItalic := Ord(AFont.Handle^.get_style = PANGO_STYLE_ITALIC);
    pango_font_metrics_unref(APangoMetrics);

    { Cache the metrics on the font object }
    AFont.CachedMetrics := TM;
    AFont.MetricsValid := True;
    Result := True;
  end;
end;

function TGtk4WidgetSet.GetViewPortExtEx(DC: HDC; Size: PSize): Integer;
begin
  if IsValidDC(DC) and (Size <> nil) then
  begin
    Size^.cx := TGtk4DeviceContext(DC).ViewPortExt.x;
    Size^.cy := TGtk4DeviceContext(DC).ViewPortExt.y;
    Result := Integer(True);
  end else
    Result := Integer(False);
end;

function TGtk4WidgetSet.GetViewPortOrgEx(DC: HDC; P: PPoint): Integer;
begin
  Result := 0;
  if not IsValidDC(DC) or (P = nil) then Exit;
  { In MM_TEXT mode, viewport origin is the device offset }
  P^ := TGtk4DeviceContext(DC).Offset;
  Result := 1;
end;

function TGtk4WidgetSet.GetWindowExtEx(DC: HDC; Size: PSize): Integer;
begin
  if IsValidDC(DC) and (Size <> nil) then
  begin
    Size^.cx := TGtk4DeviceContext(DC).WindowExt.x;
    Size^.cy := TGtk4DeviceContext(DC).WindowExt.y;
    Result := Integer(True);
  end else
    Result := Integer(False);
end;

function TGtk4WidgetSet.GetWindowLong(Handle: HWND; int: Integer): PtrInt;
var
  AWidget: PGtkWidget;
begin
  Result := 0;
  if not IsValidHandle(Handle) then
    Exit;
  AWidget := TGtk4Widget(Handle).Widget;
  if AWidget = nil then
    Exit;
  if not Gtk4IsObject(PGObject(AWidget)) then
    Exit;
  case int of
    GWL_WNDPROC:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclwndproc')));
    GWL_HINSTANCE:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclhinstance')));
    GWL_HWNDPARENT:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclhwndparent')));
    GWL_STYLE:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclstyle')));
    GWL_EXSTYLE:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclexstyle')));
    GWL_USERDATA:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lcluserdata')));
    GWL_ID:
      Result := PtrInt({%H-}PtrUInt(g_object_get_data(PGObject(AWidget), 'lclid')));
  end;
end;

function TGtk4WidgetSet.GetWindowOrgEx(dc: hdc; P: PPoint): Integer;
var
  Matrix: Tcairo_matrix_t;
  dx, dy: Double;
  OrigX, OrigY: LongInt;
begin
  Result := 0;
  if not IsValidDC(DC) and (P <> nil) then
  begin
    {$ifdef VerboseGtk4WinAPI}
      DebugLn('Trace: < [WinAPI GetWindowOrgEx] No valid DC or P is nil');
    {$endif}
    exit;
  end;
  cairo_get_matrix(TGtk4DeviceContext(DC).pcr, @Matrix);
  dx := 0;
  dy := 0;
  cairo_matrix_transform_point(@Matrix, @dx, @dy);
  if P <> nil then
  begin
    OrigX := TGtk4DeviceContext(DC).fncOrigin.X;
    OrigY := TGtk4DeviceContext(DC).fncOrigin.Y;
    //                                       [OrigX, OrigY, Trunc(dx), Trunc(dy)]));
    P^.X := OrigX-Trunc(dx);
    P^.Y := OrigY-Trunc(dy);
  end;
  Result := 1;
end;

function TGtk4WidgetSet.GetWindowRect(Handle: hwnd; var ARect: TRect): Integer;
var
  Allocation: TGtkAllocation;
  AWidget: PGtkWidget;
begin
  Result := 0;
  if IsValidHandle(Handle) then
  begin
    AWidget := TGtk4Widget(Handle).Widget;
    if AWidget = nil then
      Exit;
    AWidget^.get_allocation(@Allocation);
    ARect := Bounds(Allocation.x, Allocation.y, Allocation.width, Allocation.height);
    if (Allocation.width <= 0) or (Allocation.height <= 0) then
      ARect := Bounds(TGtk4Widget(Handle).LCLObject.Left, TGtk4Widget(Handle).LCLObject.Top,
        TGtk4Widget(Handle).LCLObject.Width, TGtk4Widget(Handle).LCLObject.Height);
    Result := 1;
  end;
end;

function TGtk4WidgetSet.GetWindowRelativePosition(Handle: hwnd; var Left,
  Top: integer): boolean;
var
  AWidget: TGtk4Widget;
  APos: TPoint;
begin
  Left:=0;
  Top:=0;
  if Handle = 0 then
    exit(False);
  AWidget := TGtk4Widget(Handle);
  Result := AWidget.GetPosition(APos);
  Left:=APos.X;
  Top:=APos.Y;
end;

function TGtk4WidgetSet.GetWindowSize(Handle: hwnd; var Width, Height: integer
  ): boolean;
var
  aWidget: PGtkWidget;
  W, H: gint;
begin
  Result := False;
  if IsValidHandle(Handle) then
  begin
    aWidget:= TGtk4Widget(Handle).Widget;
    if aWidget<>nil then
    begin
      { For GtkWindow, use get_default_size — same source as getClientRect.
        During interactive resize, notify::default-width/height fires BEFORE
        GTK propagates allocation to children, so get_allocated_width/height
        returns stale values. Using get_default_size here keeps GetWindowSize
        consistent with getClientRect, preventing ClientRectNeedsInterfaceUpdate
        from computing a wrong adjusted client rect. }
      if TGtk4Widget(Handle) is TGtk4Window then
      begin
        PGtkWindow(aWidget)^.get_default_size(@W, @H);
        if (W > 0) and (H > 0) then
        begin
          Width := W;
          Height := H;
          Result := True;
          Exit;
        end;
      end;
      { Fallback for non-window widgets and before set_default_size is called }
      Width := aWidget^.get_allocated_width;
      Height := aWidget^.get_allocated_Height;
      Result := True;
    end;
  end;
end;

procedure TGtk4WidgetSet.InitializeCriticalSection(
  var CritSection: TCriticalSection);
var
  ACritSec: System.PRTLCriticalSection;
begin
  New(ACritSec);
  System.InitCriticalSection(ACritSec^);
  CritSection:=TCriticalSection(ACritSec);
end;

function TGtk4WidgetSet.InitStockFont(AFont: TObject; AStockFont: TStockFont
  ): Boolean;
var
  Font: TFont absolute AFont;
  FontDesc: PPangoFontDescription;
  FontName: string;
  FontSize: Integer;
  GtkFontStr: PGChar;
  ASettings: PGtkSettings;
  AValue: TGValue;
begin
  Result := False;
  if not (AFont is TFont) then
    Exit;

  { Read the system font from GTK4 settings ('gtk-font-name' property) }
  ASettings := gtk_settings_get_default;
  if ASettings = nil then
    Exit;

  FillByte(AValue{%H-}, SizeOf(AValue), 0);
  AValue.init(G_TYPE_STRING);
  g_object_get_property(PGObject(ASettings), 'gtk-font-name', @AValue);
  GtkFontStr := AValue.get_string;
  if (GtkFontStr = nil) or (GtkFontStr^ = #0) then
  begin
    AValue.unset;
    Exit;
  end;

  { Parse the font string with Pango to extract family and size }
  FontDesc := pango_font_description_from_string(GtkFontStr);
  AValue.unset;
  if FontDesc = nil then
    Exit;

  try
    FontName := string(pango_font_description_get_family(FontDesc));
    if FontName <> '' then
      Font.Name := FontName;

    FontSize := pango_font_description_get_size(FontDesc);
    if FontSize > 0 then
    begin
      if pango_font_description_get_size_is_absolute(FontDesc) then
        Font.Height := -(FontSize div PANGO_SCALE)
      else
        Font.Size := FontSize div PANGO_SCALE;
    end;

    Font.Style := [];
    if pango_font_description_get_weight(FontDesc) >= PANGO_WEIGHT_BOLD then
      Font.Style := Font.Style + [fsBold];
    if pango_font_description_get_style(FontDesc) <> PANGO_STYLE_NORMAL then
      Font.Style := Font.Style + [fsItalic];

    { Set appropriate color based on stock font type }
    case AStockFont of
      sfMenu: Font.Color := clMenuText;
      sfHint: Font.Color := clInfoText;
    else
      Font.Color := clWindowText;
    end;

    Result := True;
  finally
    pango_font_description_free(FontDesc);
  end;
end;

function TGtk4WidgetSet.InvalidateRect(aHandle: HWND; Rect: pRect;
  bErase: Boolean): Boolean;
begin
  Result := False;
  if AHandle <> 0 then
  begin
    TGtk4Widget(AHandle).Update(Rect);
    Result := True;
  end;
end;

function TGtk4WidgetSet.InvalidateRgn(Handle: HWND; Rgn: HRGN; Erase: Boolean): Boolean;
var
  ARect: TRect;
begin
  { GTK4: gtk_widget_queue_draw_region was removed. Use bounding rect of
    region to limit the invalidated area instead of full widget queue_draw. }
  Result := False;
  if not IsValidHandle(Handle) then Exit;
  if IsValidGDIObject(Rgn) and (TObject(Rgn) is TGtk4Region) then
  begin
    ARect := TGtk4Region(Rgn).GetExtents;
    TGtk4Widget(Handle).Update(@ARect);
  end else
    TGtk4Widget(Handle).Update(nil);
  Result := True;
end;

function TGtk4WidgetSet.IsIconic(handle: HWND): boolean;
begin
  Result := (handle <> 0) and TGtk4Widget(Handle).IsIconic;
end;

function TGtk4WidgetSet.IsWindow(handle: HWND): boolean;
begin
  { Use IsValidHandle instead of .Widget to avoid triggering GetWidget's
    auto-initialization (InitializeWidget) on destroyed/freed objects.
    IsValidHandle directly checks FWidget without lazy init. }
  Result := (handle <> 0) and TGtk4Widget(Handle).IsValidHandle;
end;

function TGtk4WidgetSet.IsWindowEnabled(handle: HWND): boolean;
begin
  Result := (handle <> 0) and TGtk4Widget(Handle).IsValidHandle and
    TGtk4Widget(Handle).Enabled and TGtk4Widget(Handle).Visible;
end;

function TGtk4WidgetSet.IsWindowVisible(handle: HWND): boolean;
begin
  Result := (handle <> 0) and TGtk4Widget(Handle).IsValidHandle and
    TGtk4Widget(Handle).Visible;
end;

function TGtk4WidgetSet.IsZoomed(handle: HWND): boolean;
begin
  Result := False;
  if IsValidHandle(handle) and (TGtk4Widget(Handle) is TGtk4Window) then
    Result := gtk_window_is_maximized(
      PGtkWindow(TGtk4Window(Handle).Widget));
end;

procedure TGtk4WidgetSet.LeaveCriticalSection(var CritSection: TCriticalSection
  );
var
  ACritSec: System.PRTLCriticalSection;
begin
  ACritSec:=System.PRTLCriticalSection(CritSection);
  System.LeaveCriticalsection(ACritSec^);
end;

function TGtk4WidgetSet.LineTo(DC: HDC; X, Y: Integer): Boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  Result := TGtk4DeviceContext(DC).LineTo(X, Y);
end;

function TGtk4WidgetSet.LPtoDP(DC: HDC; var Points; Count: Integer): BOOL;
var
  cr: PCairo_t;
  P: PPoint;
  dx, dy: Double;
begin
  Result := False;
  if not IsValidDC(DC) then
    exit;
  cr := TGtk4DeviceContext(DC).pcr;

  P := @Points;
  while Count > 0 do
  begin
    Dec(Count);
    DX := P^.X;
    DY := P^.Y;
    cairo_user_to_device(cr,@dx,@dy);
    P^.X := Round(DX)-TGtk4DeviceContext(DC).fncOrigin.x;
    P^.Y := Round(DY)-TGtk4DeviceContext(DC).fncOrigin.y;
    Inc(P);
  end;
  Result:=true;
end;

function TGtk4WidgetSet.MessageBox(hWnd: HWND; lpText, lpCaption: PChar;
  uType: Cardinal): integer;
var
  fact:TGtk4DialogFactory;
begin
  fact:=TGtk4DialogFactory.CreateMsgBox(hWnd,lpText,lpCaption,uType);
  try
    fact.run;
    Result:=fact.lcl_result;
  finally
    fact.Free;
  end;
end;

function TGtk4WidgetSet.MonitorFromPoint(ptScreenCoords: TPoint; dwFlags: DWord
  ): HMONITOR;
var
  ADisplay: PGdkDisplay;
  AMonitors: PGListModel;
  AMonitor: PGdkMonitor;
  AGeometry: TGdkRectangle;
  i, n: guint;
  APrimary: guint;
begin
  Result := HMONITOR(1); { fallback: primary/first monitor }
  ADisplay := gdk_display_get_default;
  if ADisplay = nil then Exit;
  AMonitors := gtk4_display_get_monitors(ADisplay);
  if AMonitors = nil then Exit;
  n := g_list_model_get_n_items(AMonitors);
  if n = 0 then Exit;
  APrimary := 0; { GTK4: no primary concept; treat index 0 as primary }
  for i := 0 to n - 1 do
  begin
    AMonitor := PGdkMonitor(g_list_model_get_item(AMonitors, i));
    if AMonitor = nil then Continue;
    try
      AGeometry.x := 0; AGeometry.y := 0;
      AGeometry.width := 0; AGeometry.height := 0;
      gdk_monitor_get_geometry(AMonitor, @AGeometry);
      if (AGeometry.width > 0) and (AGeometry.height > 0) and
         (ptScreenCoords.X >= AGeometry.x) and
         (ptScreenCoords.X < AGeometry.x + AGeometry.width) and
         (ptScreenCoords.Y >= AGeometry.y) and
         (ptScreenCoords.Y < AGeometry.y + AGeometry.height) then
      begin
        Result := HMONITOR(i + 1); { 1-based }
        Exit;
      end;
    finally
      g_object_unref(AMonitor);
    end;
  end;
  { Point not on any monitor }
  case dwFlags of
    MONITOR_DEFAULTTOPRIMARY: Result := HMONITOR(APrimary + 1);
    MONITOR_DEFAULTTONEAREST:
    begin
      { Simple nearest: return primary. A full implementation would
        compute distance to each monitor edge. }
      Result := HMONITOR(APrimary + 1);
    end;
    MONITOR_DEFAULTTONULL: Result := HMONITOR(0);
  end;
end;

function TGtk4WidgetSet.MonitorFromRect(lprcScreenCoords: PRect;
  dwFlags: DWord): HMONITOR;
var
  cx, cy: Integer;
begin
  { Use rect center and delegate to MonitorFromPoint }
  if lprcScreenCoords <> nil then
  begin
    cx := (lprcScreenCoords^.Left + lprcScreenCoords^.Right) div 2;
    cy := (lprcScreenCoords^.Top + lprcScreenCoords^.Bottom) div 2;
    Result := MonitorFromPoint(Point(cx, cy), dwFlags);
  end else
  begin
    case dwFlags of
      MONITOR_DEFAULTTONULL: Result := HMONITOR(0);
    else
      Result := HMONITOR(1);
    end;
  end;
end;

function TGtk4WidgetSet.MonitorFromWindow(hWnd: HWND; dwFlags: DWord): HMONITOR;
var
  R: TRect;
  cx, cy: Integer;
begin
  { Get the window's center point and delegate to MonitorFromPoint }
  if (hWnd <> 0) and IsValidHandle(hWnd) then
  begin
    R := TGtk4Widget(hWnd).LCLObject.BoundsRect;
    cx := (R.Left + R.Right) div 2;
    cy := (R.Top + R.Bottom) div 2;
    Result := MonitorFromPoint(Point(cx, cy), dwFlags);
  end else
  begin
    case dwFlags of
      MONITOR_DEFAULTTONULL: Result := HMONITOR(0);
    else
      Result := HMONITOR(1); { primary }
    end;
  end;
end;

function TGtk4WidgetSet.MoveToEx(DC: HDC; X, Y: Integer; OldPoint: PPoint
  ): Boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  Result := TGtk4DeviceContext(DC).MoveTo(X, Y, OldPoint);
end;

function TGtk4WidgetSet.OffsetRgn(RGN: HRGN; nXOffset, nYOffset: Integer
  ): Integer;
var
  ARegion: TGtk4Region;
  AExtents: Tcairo_rectangle_int_t;
begin
  Result := ERROR;
  if not IsValidGDIObject(RGN) then Exit;
  if not (TObject(RGN) is TGtk4Region) then Exit;
  ARegion := TGtk4Region(RGN);
  if ARegion.Handle = nil then Exit;

  cairo_region_translate(ARegion.Handle, nXOffset, nYOffset);

  { Determine region complexity for return value }
  cairo_region_get_extents(ARegion.Handle, @AExtents);
  if cairo_region_is_empty(ARegion.Handle) then
    Result := NULLREGION
  else if cairo_region_num_rectangles(ARegion.Handle) = 1 then
    Result := SIMPLEREGION
  else
    Result := COMPLEXREGION;
end;

function TGtk4WidgetSet.PaintRgn(DC: HDC; RGN: HRGN): Boolean;
var
  ctx: TGtk4DeviceContext;
  ARegion: TGtk4Region;
  i, n: Integer;
  ARect: Tcairo_rectangle_int_t;
  R, G, B: Double;
begin
  Result := False;
  if not IsValidDC(DC) then Exit;
  if not IsValidGDIObject(RGN) then Exit;
  if not (TObject(RGN) is TGtk4Region) then Exit;

  ctx := TGtk4DeviceContext(DC);
  ARegion := TGtk4Region(RGN);
  if (ctx.pcr = nil) or (ARegion.Handle = nil) then Exit;

  cairo_save(ctx.pcr);
  try
    { Fill each rectangle in the region with the current brush color }
    if ctx.CurrentBrush <> nil then
      ColorToCairoRGB(ColorToRGB(TColor(ctx.CurrentBrush.Color)), R, G, B)
    else
      ColorToCairoRGB(ColorToRGB(clWhite), R, G, B);
    cairo_set_source_rgb(ctx.pcr, R, G, B);

    n := cairo_region_num_rectangles(ARegion.Handle);
    for i := 0 to n - 1 do
    begin
      cairo_region_get_rectangle(ARegion.Handle, i, @ARect);
      cairo_rectangle(ctx.pcr, ARect.x, ARect.y, ARect.width, ARect.height);
    end;
    cairo_fill(ctx.pcr);
    Result := True;
  finally
    cairo_restore(ctx.pcr);
  end;
end;

function TGtk4WidgetSet.PeekMessage(var lpMsg: TMsg; Handle: HWND;
  wMsgFilterMin, wMsgFilterMax, wRemoveMsg: UINT): Boolean;
begin
  { GTK4 does not maintain a TMsg queue. The GLib main loop dispatches events
    internally and does not expose individual messages. Use AppProcessMessages
    for cross-platform event processing. Same as Qt5. }
  Result := False;
end;

function TGtk4WidgetSet.PolyBezier(DC: HDC; Points: PPoint; NumPts: Integer;
  Filled, Continuous: boolean): boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  TGtk4DeviceContext(DC).drawPolyBezier(Points, NumPts, Filled, Continuous);
  Result:=True;
end;

function TGtk4WidgetSet.Polygon(DC: HDC; Points: PPoint; NumPts: Integer;
  Winding: boolean): boolean;
var
  NFillRule: integer;
  bFill, bBorder: boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  if Winding then
    NFillRule := Ord(CAIRO_FILL_RULE_WINDING)
  else
    NFillRule := Ord(CAIRO_FILL_RULE_EVEN_ODD);
  bFill := TGtk4DeviceContext(DC).CurrentBrush.Style <> BS_NULL;
  bBorder := TGtk4DeviceContext(DC).CurrentPen.Style <> psClear;
  TGtk4DeviceContext(DC).drawPolygon(Points, NumPts, NFillRule, bFill, bBorder);
  Result:= True;
end;

function TGtk4WidgetSet.Polyline(DC: HDC; Points: PPoint; NumPts: Integer): boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  if TGtk4DeviceContext(DC).CurrentPen.Style = psClear then Exit;
  TGtk4DeviceContext(DC).drawPolyLine(Points, NumPts);
  Result:=True;
end;


type
  PCustomGtk4Message = ^TCustomGtk4Message;
  TCustomGtk4Message = record
    Handle: HWND;
    Msg: Cardinal;
    AwParam: WParam;
    AlParam: LParam;
    Result: LRESULT;
  end;

function Gtk4ProcessPostMessage(user_data: gpointer): gboolean; cdecl;
var
  AMsg: TCustomGtk4Message;
  AMessage: TLMessage;
begin
  Result := False;
  if user_data <> nil then
  begin
    AMsg := TCustomGtk4Message(user_data^);
    { Validate the target widget is still alive before delivering the message.
      PostMessage queues via g_idle_add, so the widget may have been destroyed
      between the PostMessage call and this idle callback firing. Accessing
      a freed TGtk4Widget causes SIGSEGV (EAccessViolation at shutdown). }
    if (AMsg.Handle <> 0) and Gtk4IsLiveWidgetPointer(Pointer(AMsg.Handle)) then
    begin
      FillChar(AMessage{%H-}, SizeOf(AMessage), #0);
      AMessage.Msg := AMsg.Msg;
      AMessage.WParam := AMsg.AwParam;
      AMessage.LParam := AMsg.AlParam;
      TGtk4Widget(AMsg.Handle).DeliverMessage(AMessage);
    end;
    Freemem(user_data);
    user_data := nil;
    { Result stays False → GLib removes this idle source after return }
  end;
end;

function TGtk4WidgetSet.PostMessage(Handle: HWND; Msg: Cardinal;
  wParam: WParam; lParam: LParam): Boolean;
var
  AEvent: PCustomGtk4Message;
begin
  Result := False;
  if Handle <> 0 then
  begin
    AEvent := GetMem(SizeOf(TCustomGtk4Message));
    AEvent^.Handle := Handle;
    AEvent^.Msg := Msg;
    AEvent^.AwParam := wParam;
    AEvent^.AlParam := lParam;
    AEvent^.Result := 0;
    g_idle_add(@Gtk4ProcessPostMessage, AEvent);
    if GetCurrentThreadId <> MainThreadID then
    begin
      // writeln('TGtk4WidgetSet.PostMessage from different thread !');
      g_main_context_wakeup(g_main_context_default);
    end;
    Result := True;
  end;
end;

function TGtk4WidgetSet.PtInRegion(RGN: HRGN; X, Y: Integer): Boolean;
begin
  Result := False;
  if IsValidGDIObject(RGN) then
    Result := TGtk4Region(RGN).ContainsPoint(Point(X, Y));
end;

function TGtk4WidgetSet.RadialArc(DC: HDC; left, top, right, bottom, sx, sy,
  ex, ey: Integer): Boolean;
begin
  { Inherited converts radial coords to angles and calls Arc }
  Result := inherited RadialArc(DC, left, top, right, bottom, sx, sy, ex, ey);
end;

function TGtk4WidgetSet.RadialChord(DC: HDC; x1, y1, x2, y2, sx, sy, ex,
  ey: Integer): Boolean;
begin
  { Inherited converts radial coords to angles and calls AngleChord }
  Result := inherited RadialChord(DC, x1, y1, x2, y2, sx, sy, ex, ey);
end;

function TGtk4WidgetSet.RealizePalette(DC: HDC): Cardinal;
begin
  { Palette management is a legacy concept for 8-bit displays.
    Modern GTK4 always uses truecolor. Return 0 (no palette entries changed). }
  Result := 0;
end;

function TGtk4WidgetSet.Rectangle(DC: HDC; X1, Y1, X2, Y2: Integer): Boolean;
var
  R: TRect;
  bFill, bBorder: Boolean;
begin
  if not IsValidDC(DC) then
    exit(False);
  R := NormalizeRect(Rect(X1, Y1, X2, Y2));
  if IsRectEmpty(R) then Exit(True);
  bFill := TGtk4DeviceContext(DC).CurrentBrush.Style <> BS_NULL;
  bBorder := TGtk4DeviceContext(DC).CurrentPen.Style <> psClear;
  TGtk4DeviceContext(DC).drawRect(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, bFill, bBorder);
  Result := True;
end;

function TGtk4WidgetSet.RectInRegion(RGN: HRGN; ARect: TRect): Boolean;
begin
  Result := False;
  if IsValidGDIObject(RGN) then
    Result := TGtk4Region(Rgn).ContainsRect(ARect);
end;

function TGtk4WidgetSet.RectVisible(dc: hdc; const ARect: TRect): Boolean;
var
  ACairoRegion: Pcairo_region_t;
  ACairoRect: Tcairo_rectangle_int_t;
begin
  Result := False;
  if not IsValidDC(DC) then
    exit;
  { GTK4: gdk_window_get_visible_region/gdk_get_default_root_window removed;
    assume visible if widget parent exists, otherwise always visible }
  ACairoRect.x := ARect.Left;
  ACairoRect.y := ARect.Top;
  ACairoRect.width := ARect.Right - ARect.Left;
  ACairoRect.height := ARect.Bottom - ARect.Top;
  if (TGtk4DeviceContext(DC).Parent <> nil) then
  begin
    ACairoRegion := cairo_region_create_rectangle(@ACairoRect);
    Result := cairo_region_contains_rectangle(ACairoRegion, @ACairoRect) <> CAIRO_REGION_OVERLAP_OUT;
    cairo_region_destroy(ACairoRegion);
  end else
    Result := True;
end;

function TGtk4WidgetSet.RedrawWindow(Handle: HWND; lprcUpdate: PRect;
  hrgnUpdate: HRGN; flags: Cardinal): Boolean;
var
  AWidget: TGtk4Widget;
begin
  Result := False;
  if Handle = 0 then Exit;
  AWidget := TGtk4Widget(Handle);
  if not AWidget.IsWidgetOK then Exit;

  { RDW_INVALIDATE: mark area for repaint }
  if (flags and RDW_INVALIDATE) <> 0 then
  begin
    if lprcUpdate <> nil then
      AWidget.Update(lprcUpdate)
    else
      AWidget.Update(nil);
  end;

  { RDW_ERASE: ensure background is erased on next paint }
  { GTK4 always redraws the background — no separate erase step needed }

  { RDW_UPDATENOW: process pending paint immediately }
  if (flags and RDW_UPDATENOW) <> 0 then
  begin
    { Force pending draws to be processed }
    while g_main_context_iteration(g_main_context_default, False) do ;
  end;

  { RDW_ALLCHILDREN: invalidate all child widgets }
  if (flags and RDW_ALLCHILDREN) <> 0 then
  begin
    { GTK4: queue_draw on the container invalidates children too }
    AWidget.Widget^.queue_draw;
  end;

  Result := True;
end;

function TGtk4WidgetSet.RegroupMenuItem(hndMenu: HMENU; GroupIndex: integer
  ): Boolean;
begin
  { GTK4 radio grouping is LCL-driven (per-item string-state actions, no
    native GtkRadioMenuItem). LCL SetGroupIndex runs TurnSiblingsOff before
    calling here — it clears merged siblings' FChecked WITHOUT a WS SetCheck,
    so their native action state would stay stale. Resync every radio item in
    the group to its LCL Checked value. }
  Result := True;
  if (hndMenu <> 0) and (TObject(hndMenu) is TGtk4MenuItem) then
    TGtk4MenuItem(hndMenu).SyncGroupToLCL;
  if GroupIndex = 0 then ;
end;

function TGtk4WidgetSet.ReleaseCapture: Boolean;
type
  TSeatUngrab = procedure(seat: Pointer); cdecl;
var
  ASeat: PGdkSeat;
begin
  {$IFDEF VerboseGtk4WinApi}
  DebugLn('TGtk4WidgetSet.ReleaseCapture');
  {$ENDIF}
  { GTK4: gtk_grab_remove removed. Clear our software capture tracking. }
  Result := Gtk4CapturedWidget <> nil;
  Gtk4CapturedWidget := nil;
  { Release native pointer grab if engaged }
  if GdkpSeatUngrab <> nil then
  begin
    ASeat := gdk_display_get_default_seat(gdk_display_get_default);
    if ASeat <> nil then
      TSeatUngrab(GdkpSeatUngrab)(ASeat);
  end;
end;

function TGtk4WidgetSet.ReleaseDC(hWnd: HWND; DC: HDC): Integer;
begin
  Result := 0;
  if IsValidDC(DC) then
  begin
    if TGtk4DeviceContext(DC).CanRelease then
      TGtk4DeviceContext(DC).Free;
    Result := 1;
  end;
end;

function TGtk4WidgetSet.RemoveProp(Handle: hwnd; Str: PChar): TLCLHandle;
var
  AWidget: PGtkWidget;
  AContainer: PGtkWidget;
begin
  Result := 0;
  if (Handle = 0) or (Str = nil) then
    exit;
  if not IsValidHandle(Handle) then
    Exit;
  AWidget := TGtk4Widget(Handle).Widget;
  if (AWidget <> nil) and Gtk4IsObject(PGObject(AWidget)) then
    g_object_set_data(PGObject(AWidget), Str, nil);
  AContainer := TGtk4Widget(Handle).GetContainerWidget;
  if (AContainer <> nil) and (AContainer <> AWidget) then
  begin
    if Gtk4IsObject(PGObject(AContainer)) then
      g_object_set_data(PGObject(AContainer), Str, nil);
  end;
  Result := 1;
end;

function TGtk4WidgetSet.RestoreDC(DC: HDC; SavedDC: Integer): Boolean;
var
  Ctx: TGtk4DeviceContext;
  Target: Integer;
begin
  Result := False;
  if not IsValidDC(DC) then
    Exit;
  Ctx := TGtk4DeviceContext(DC);

  { Convert negative offset to absolute index }
  if SavedDC < 0 then
    Target := Ctx.SaveDCCount + SavedDC
  else
    Target := SavedDC - 1;

  if Target < 0 then
    Target := 0;

  { Pop cairo state stack down to the target level }
  while Ctx.SaveDCCount > Target do
  begin
    cairo_restore(Ctx.pcr);
    Ctx.SaveDCCount := Ctx.SaveDCCount - 1;
  end;
  Result := True;
end;

function TGtk4WidgetSet.RoundRect(DC: hDC; X1, Y1, X2, Y2: Integer; RX,
  RY: Integer): Boolean;
begin
  Result := False;
  if not IsValidDC(DC) then
    exit;
  Result := TGtk4DeviceContext(DC).RoundRect(X1, Y1, X2, Y2, RX, RY);
end;

function TGtk4WidgetSet.SaveDC(DC: HDC): Integer;
var
  Ctx: TGtk4DeviceContext;
begin
  Result := 0;
  if not IsValidDC(DC) then
    Exit;
  Ctx := TGtk4DeviceContext(DC);
  cairo_save(Ctx.pcr);
  Ctx.SaveDCCount := Ctx.SaveDCCount + 1;
  Result := Ctx.SaveDCCount;
end;

function TGtk4WidgetSet.ScreenToClient(Handle: HWND; var P: TPoint): Integer;
begin
  Result := 0;
  {$ifdef VerboseGtk4WinApi}
  DebugLn('Trace:> [TGtk4WidgetSet.ScreenToClient] ',dbgs(P));
  {$endif}
  if not IsValidHandle(Handle) then
    exit;

  Result := TGtk4Widget(Handle).ScreenToClient(P);
end;

function TGtk4WidgetSet.ScrollWindowEx(hWnd: HWND; dx, dy: Integer; prcScroll,
  prcClip: PRect; hrgnUpdate: HRGN; prcUpdate: PRect; flags: UINT): Boolean;
var
  AWidget: TGtk4Widget;
  AW: PGtkWidget;
  Alloc: TGtkAllocation;
  ARect: TRect;
begin
  { GTK4: gdk_window_scroll/gdk_window_move_region removed.
    GTK4 uses compositing — invalidate the area for repaint. }
  Result := False;
  if (hWnd = 0) or ((dx = 0) and (dy = 0)) then Exit;
  AWidget := TGtk4Widget(hWnd);
  AW := AWidget.GetContainerWidget;
  if AW = nil then
    AW := AWidget.Widget;
  if AW = nil then Exit;

  AW^.get_allocation(@Alloc);
  if prcScroll <> nil then
    ARect := prcScroll^
  else
    ARect := Rect(0, 0, Alloc.width, Alloc.height);

  { Calculate the update rect (area exposed by the scroll) }
  if prcUpdate <> nil then
  begin
    if dy > 0 then
      prcUpdate^ := Rect(ARect.Left, ARect.Top, ARect.Right, ARect.Top + dy)
    else if dy < 0 then
      prcUpdate^ := Rect(ARect.Left, ARect.Bottom + dy, ARect.Right, ARect.Bottom)
    else if dx > 0 then
      prcUpdate^ := Rect(ARect.Left, ARect.Top, ARect.Left + dx, ARect.Bottom)
    else
      prcUpdate^ := Rect(ARect.Right + dx, ARect.Top, ARect.Right, ARect.Bottom);
  end;

  { Invalidate the scrolled area for repaint }
  if (flags and SW_INVALIDATE) <> 0 then
    InvalidateRect(hWnd, @ARect, (flags and SW_ERASE) <> 0)
  else
    AW^.queue_draw;

  Result := True;
end;

function TGtk4WidgetSet.SelectClipRGN(DC: hDC; RGN: HRGN): Longint;
begin
  Result := 0;
  if IsValidDC(DC) then
  begin
    if IsValidGDIObject(RGN) then
      Result := TGtk4DeviceContext(DC).setClipRegion(TGtk4Region(RGN))
    else
      Result := TGtk4DeviceContext(DC).ResetClip;
  end;
end;

function TGtk4WidgetSet.SelectObject(DC: HDC; GDIObj: HGDIOBJ): HGDIOBJ;
begin
  Result := 0;
  if not IsValidDC(DC) then
    exit;
  if IsValidGDIObject(GDIObj) then
  begin
    Result:=HGDIOBJ(TGtk4ContextObject(GDIOBJ).Select(TGtk4DeviceContext(DC)));
  end;
end;

function TGtk4WidgetSet.SelectPalette(DC: HDC; Palette: HPALETTE;
  ForceBackground: Boolean): HPALETTE;
begin
  { Palette management is a legacy concept for 8-bit displays.
    Modern GTK4 always uses truecolor. Return 0 (no previous palette). }
  Result := 0;
end;

function TGtk4WidgetSet.SendMessage(HandleWnd: HWND; Msg: Cardinal;
  wParam: WParam; lParam: LParam): LResult;
var
  AMessage: TLMessage;
  AWidget: TGtk4Widget;
begin
  Result := 0;
  if HandleWnd = 0 then Exit;
  AWidget := TGtk4Widget(HandleWnd);
  if AWidget.LCLObject = nil then Exit;
  AMessage.Msg := Msg;
  AMessage.WParam := WParam;
  AMessage.LParam := LParam;
  AMessage.Result := 0;
  Result := AWidget.DeliverMessage(AMessage);
end;

function TGtk4WidgetSet.SetActiveWindow(Handle: HWND): HWND;
begin
  Result := GetActiveWindow;
  if IsValidHandle(Handle) then
  begin
    if wtWindow in TGtk4Widget(Handle).WidgetType then
    begin
      if Gtk4WindowCanPresent(TGtk4Window(Handle)) then
        PGtkWindow(TGtk4Window(Handle).Widget)^.present;
    end;
  end;
end;

function TGtk4WidgetSet.SetBkColor(DC: HDC; Color: TColorRef): TColorRef;
begin
  Result := clNone;
  if not IsValidDC(DC) then
    exit;
  Result := TGtk4DeviceContext(DC).CurrentBrush.Color;
  TGtk4DeviceContext(DC).CurrentBrush.Color := TColor(ColorToRGB(TColor(Color)));
end;

function TGtk4WidgetSet.SetBkMode(DC: HDC; bkMode: Integer): Integer;
begin
  Result := 0;
  if not IsValidDC(DC) then
    exit;
  Result := TGtk4DeviceContext(DC).BkMode;
  TGtk4DeviceContext(DC).BkMode := bkMode;
end;

function TGtk4WidgetSet.SetCapture(AHandle: HWND): HWND;
var
  Message: TLMessage;
begin
  {$IFDEF VerboseGtk4WinApi}
  DebugLn('TGtk4WidgetSet.SetCapture');
  {$ENDIF}
  Result := GetCapture;
  if Result <> AHandle then
  begin
    if Result <> 0 then
      ReleaseCapture;
    if IsValidHandle(AHandle) then
    begin
      TGtk4Widget(AHandle).SetCapture;
      Message.Msg := 0;
      FillChar(Message, SizeOf(Message), 0);
      Message.msg := LM_CAPTURECHANGED;
      Message.wParam := 0;
      Message.lParam := PtrInt(Result);
      LCLMessageGlue.DeliverMessage(TGtk4Widget(AHandle).LCLObject, Message);
    end;
  end;
end;

function TGtk4WidgetSet.SetCaretPos(X, Y: Integer): Boolean;
begin
  Result := SetCaretPosEx(GetFocus, X, Y);
end;

function TGtk4WidgetSet.SetCaretPosEx(Handle: HWnd; X, Y: Integer): Boolean;
var
  AWidget: TGtk4Widget;
  CursorRect: TGdkRectangle;
begin
  Result := (Handle <> 0) and (FCaret.Handle = Handle);
  if Result then
  begin
    if (FCaret.X = X) and (FCaret.Y = Y) then Exit;
    { Invalidate old position }
    InvalidateCaret;
    FCaret.X := X;
    FCaret.Y := Y;
    FCaret.BlinkHide := False;
    { Reset blink timer so caret shows immediately after move }
    if FCaret.Visible and FCaret.Blinking then
    begin
      StopCaretTimer;
      StartCaretTimer;
    end;
    { Invalidate new position }
    InvalidateCaret;
    { Update IMContext cursor location for CJK/Hangul candidate window placement }
    if Gtk4IsLiveWidgetPointer(Pointer(Handle)) then
    begin
      AWidget := TGtk4Widget(Handle);
      if AWidget.IMContext <> nil then
      begin
        CursorRect.x := X;
        CursorRect.y := Y;
        CursorRect.width := 0;
        CursorRect.height := FCaret.Height;
        AWidget.IMContext^.set_cursor_location(@CursorRect);
      end;
    end;
  end;
end;

function TGtk4WidgetSet.SetCaretRespondToFocus(handle: HWND;
  ShowHideOnFocus: boolean): Boolean;
begin
  Result := (handle <> 0) and (FCaret.Handle = handle);
  if Result then
    FCaret.ShowHideOnFocus := ShowHideOnFocus;
end;

function TGtk4WidgetSet.SetCursor(ACursor: HCURSOR): HCURSOR;
begin
  Result := FGlobalCursor;
  if ACursor = FGlobalCursor then Exit;
  if ACursor = Screen.Cursors[crDefault]
  then SetGlobalCursor(0)
  else SetGlobalCursor(ACursor);
  FGlobalCursor := ACursor;
end;

function TGtk4WidgetSet.SetCursorPos(X, Y: Integer): Boolean;
{$IFDEF UNIX}
type
  TXWarpPointer = function(display: Pointer; src_w, dst_w: PtrUInt;
    src_x, src_y: Integer; src_width, src_height: Cardinal;
    dest_x, dest_y: Integer): Integer; cdecl;
  TXDefaultRootWindow = function(display: Pointer): PtrUInt; cdecl;
  TXFlush = function(display: Pointer): Integer; cdecl;
  TGdkX11GetXDisplay = function(display: PGdkDisplay): Pointer; cdecl;
var
  Display: PGdkDisplay;
  hX11, hGdk: TLibHandle;
  pWarp: TXWarpPointer;
  pRoot: TXDefaultRootWindow;
  pFlush: TXFlush;
  pGetXDisplay: TGdkX11GetXDisplay;
  XDisplay: Pointer;
begin
  { GTK4: gdk_device_warp removed. Use X11 XWarpPointer directly via
    dynamic loading. On Wayland this is not possible (compositor policy). }
  Result := False;
  Display := gdk_display_get_default;
  if Display = nil then Exit;

  hGdk := LoadLibrary('libgtk-4.so.1');
  if hGdk = NilHandle then Exit;
  try
    pGetXDisplay := TGdkX11GetXDisplay(GetProcAddress(hGdk, 'gdk_x11_display_get_xdisplay'));
    if not Assigned(pGetXDisplay) then Exit;
    XDisplay := pGetXDisplay(Display);
    if XDisplay = nil then
    begin
      { Wayland: cursor warping is blocked by the compositor security policy }
      {$IFDEF VerboseGtk4DeviceContext}
      DebugLn('TGtk4WidgetSet.SetCursorPos: not available under Wayland');
      {$ENDIF}
      Exit;
    end;

    hX11 := LoadLibrary('libX11.so.6');
    if hX11 = NilHandle then Exit;
    try
      pWarp := TXWarpPointer(GetProcAddress(hX11, 'XWarpPointer'));
      pRoot := TXDefaultRootWindow(GetProcAddress(hX11, 'XDefaultRootWindow'));
      pFlush := TXFlush(GetProcAddress(hX11, 'XFlush'));
      if not Assigned(pWarp) or not Assigned(pRoot) then Exit;

      pWarp(XDisplay, 0, pRoot(XDisplay), 0, 0, 0, 0, X, Y);
      if Assigned(pFlush) then
        pFlush(XDisplay);
      Result := True;
    finally
      FreeLibrary(hX11);
    end;
  finally
    FreeLibrary(hGdk);
  end;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function TGtk4WidgetSet.SetFocus(hWnd: HWND): HWND;
var
  AWidget: TGtk4Widget;
begin
  Result := GetFocus;
  if IsValidHandle(hWnd) then
  begin
    {$IFDEF GTK4DEBUGFOCUS}
    if Result <> 0 then
      DebugLn('TGtk4WidgetSet.SetFocus: ',dbgsName(TGtk4Widget(HWND).LCLObject),' oldFocus ',dbgsName(TGtk4Widget(Result).LCLObject))
    else
      DebugLn('TGtk4WidgetSet.SetFocus: ',dbgsName(TGtk4Widget(HWND).LCLObject),' oldFocus 0');
    {$ENDIF}
    AWidget := TGtk4Widget(HWND);
    { GTK4: Do NOT call TGtk4Window.Activate here. Activate uses present()
      which steals focus from the current active window. When multiple
      windows exist (MainIDEBar + ObjectInspector), this creates an infinite
      focus bouncing loop: SetFocus→Activate→present()→other window loses
      focus→LCL restores focus on other window→SetFocus→Activate→loop.
      GTK4's grab_focus works on child widgets of any shown window. }
    AWidget.setFocus;
  end;
end;

function TGtk4WidgetSet.SetForegroundWindow(hWnd: HWND): boolean;
var
  AWindow: TGtk4Window;
begin
  if not IsValidHandle(HWnd) then
    exit(False);
  Result := wtWindow in TGtk4Widget(HWND).WidgetType;
  if Result then
  begin
    AWindow := TGtk4Window(HWND);
    if not Gtk4WindowCanPresent(AWindow) then
      exit(False);
    if not AWindow.Visible then
      exit(False);
    AWindow.Activate;
    Result := True;
  end;
end;

function TGtk4WidgetSet.SetMapMode(DC: HDC; fnMapMode: Integer): Integer;
var
  DevCtx: TGtk4DeviceContext;
begin
  Result := Integer(False);
  if not IsValidDC(DC) then Exit;
  DevCtx := TGtk4DeviceContext(DC);
  if fnMapMode <> DevCtx.MapMode then
  begin
    case fnMapMode of
      MM_ANISOTROPIC:; { user's choice }
      MM_ISOTROPIC:; { adjusted after each SetViewPortExtEx }
      MM_HIENGLISH: DevCtx.WindowExt := Point(1000, -1000);
      MM_HIMETRIC: DevCtx.WindowExt := Point(2540, -2540);
      MM_LOENGLISH: DevCtx.WindowExt := Point(100, -100);
      MM_LOMETRIC: DevCtx.WindowExt := Point(254, -254);
      MM_TWIPS: DevCtx.WindowExt := Point(1440, -1440);
    else
      fnMapMode := MM_TEXT;
      DevCtx.WindowExt := Point(1, 1);
      DevCtx.ViewPortExt := Point(1, 1);
    end;
    DevCtx.MapMode := fnMapMode;
    if not (fnMapMode in [MM_TEXT, MM_ANISOTROPIC, MM_ISOTROPIC]) then
    begin
      DevCtx.ViewPortExt := Point(
        GetDeviceCaps(DC, LOGPIXELSX),
        GetDeviceCaps(DC, LOGPIXELSY));
    end;
  end;
  Result := Integer(True);
end;

function TGtk4WidgetSet.SetParent(hWndChild: HWND; hWndParent: HWND): HWND;
begin
  Result := HWND(TGtk4Widget(hWndChild).getParent);
  TGtk4Widget(hWndChild).SetParent(TGtk4Widget(hWndParent),0,0)
end;

function TGtk4WidgetSet.SetProp(Handle: hwnd; Str: PChar; Data: Pointer
  ): Boolean;
var
  AWidget: PGtkWidget;
  AContainer: PGtkWidget;
begin
  if (Handle = 0) or (Str = nil) then
    exit(False);
  if not IsValidHandle(Handle) then
    Exit(False);
  AWidget := TGtk4Widget(Handle).Widget;
  if (AWidget <> nil) and Gtk4IsObject(PGObject(AWidget)) then
    g_object_set_data(PGObject(AWidget), Str, Data);
  AContainer := TGtk4Widget(Handle).GetContainerWidget;
  if (AContainer <> nil) and (AContainer <> AWidget) then
  begin
    if Gtk4IsObject(PGObject(AContainer)) then
      g_object_set_data(PGObject(AContainer), Str, Data);
  end;
  Result := True;
end;

function TGtk4WidgetSet.SetRectRgn(aRGN: HRGN; X1, Y1, X2, Y2: Integer
  ): Boolean;
var
  ARegion: TGtk4Region;
  ARect: Tcairo_rectangle_int_t;
  ANewRgn: Pcairo_region_t;
begin
  Result := False;
  if not IsValidGDIObject(aRGN) then Exit;
  if not (TObject(aRGN) is TGtk4Region) then Exit;

  ARegion := TGtk4Region(aRGN);

  { Create a new region with the specified rectangle }
  ARect.x := X1;
  ARect.y := Y1;
  ARect.width := X2 - X1;
  ARect.height := Y2 - Y1;
  ANewRgn := cairo_region_create_rectangle(@ARect);

  { Replace the old handle }
  if ARegion.Handle <> nil then
    cairo_region_destroy(ARegion.Handle);
  ARegion.Handle := ANewRgn;
  Result := True;
end;

function TGtk4WidgetSet.SetROP2(DC: HDC; Mode: Integer): Integer;
begin
  Result := R2_COPYPEN;
  if not IsValidDC(DC) then Exit;
  Result := TGtk4DeviceContext(DC).Rop2;
  TGtk4DeviceContext(DC).Rop2 := Mode;
end;

function TGtk4WidgetSet.SetScrollInfo(Handle: HWND; SBStyle: Integer;
  ScrollInfo: TScrollInfo; bRedraw: Boolean): Integer;

const
  POLICY: array[BOOLEAN] of TGTKPolicyType = (GTK_POLICY_NEVER, GTK_POLICY_ALWAYS);
var
  Adjustment,hadj,vadj: PGtkAdjustment;
  AWidget: TGtk4Widget;
  ACenter: PGtkWidget;
  AScrollWin: PGtkScrolledWindow;
  IsScrollbarVis, HasChanged: Boolean;
  OldW, OldH: gint;
  NewPage, NewVal: gdouble;
  SwAlloc: TGtkAllocation;
  ViewportW, ViewportH: gint;
  ContentSize: gint;
  sb: PGtkWidget;
  AdjLower, AdjUpper, AdjPageSize, AdjPageInc, AdjStepInc, AdjValue: gdouble;
begin
  Result := 0;
  if not IsValidHandle(Handle) then
    exit;

  AWidget := TGtk4Widget(Handle);
  if (AWidget.LCLObject = nil)
  or (csDestroying in AWidget.LCLObject.ComponentState)
  or (csFreeNotification in AWidget.LCLObject.ComponentState) then
    exit;
  if not AWidget.IsWidgetOK then
    exit;

  Adjustment := nil;
  AScrollWin := nil;
  HasChanged := False;

  if wtScrollBar in AWidget.WidgetType then
  begin
    if Gtk4IsWidget(AWidget.Widget) and not AWidget.Widget^.in_destruction then
      Adjustment := gtk4_scrollbar_get_adjustment(AWidget.Widget);
  end else
  if wtScrollingWin in AWidget.WidgetType then
  begin
    AScrollWin := TGtk4ScrollableWin(Handle).GetScrolledWindow;
    if AScrollWin = nil then
      exit;
    if not Gtk4IsScrolledWindow(AScrollWin) then
    begin
      DebugLn('ERROR: TGtk4WidgetSet.SetScrollInfo: Wrong class extracted for scrollwin ',dbgsName(TGtk4Widget(Handle).LCLObject));
      AScrollWin := nil;
    end;
    if Assigned(AScrollWin) then
    begin
      hadj := AScrollWin^.get_hadjustment;
      vadj := AScrollWin^.get_vadjustment;
    end else
    begin
      hadj := nil;
      vadj := nil;
    end;
  end;

  { Resolve which adjustment to use — NO set_size_request here (moved below). }
  case SBStyle of
    SB_Horz:
      if not Assigned(Adjustment) and Assigned(AScrollWin) then
        Adjustment := hadj;
    SB_Vert:
      if not Assigned(Adjustment) and Assigned(AScrollWin) then
        Adjustment := vadj;
    SB_CTL: ; { already resolved above for wtScrollBar }
    SB_BOTH:
      if not Assigned(Adjustment) and Assigned(AScrollWin) then
        Adjustment := hadj;
  end;

  if Adjustment = nil then
  begin
    { Silently exit for widgets without a ScrolledWindow (e.g. THintWindow). }
    if not (wtWindow in AWidget.WidgetType) then
      DebugLn('TGtk4WidgetSet.SetScrollInfo error: cannot get PGtkAdjustment from ',
        dbgsName(AWidget.LCLObject));
    exit;
  end;

  { Collect target adjustment values — start from current, apply ScrollInfo masks.
    This computes new values WITHOUT touching the GtkAdjustment (no signals emitted).
    GTK4 property setters each emit ::changed individually; we avoid that by
    computing everything first, then applying via gtk_adjustment_configure(). }
  AdjLower := Adjustment^.lower;
  AdjUpper := Adjustment^.upper;
  AdjPageSize := Adjustment^.page_size;
  AdjPageInc := Adjustment^.page_increment;
  AdjStepInc := Adjustment^.step_increment;
  AdjValue := Adjustment^.value;

  if (ScrollInfo.fMask and SIF_RANGE) <> 0 then
  begin
    if AdjLower <> gdouble(ScrollInfo.nMin) then
    begin
      AdjLower := ScrollInfo.nMin;
      HasChanged := True;
    end;
    if AdjUpper <> gdouble(ScrollInfo.nMax) then
    begin
      AdjUpper := ScrollInfo.nMax;
      HasChanged := True;
    end;
  end;
  if (ScrollInfo.fMask and SIF_PAGE) <> 0 then
  begin
    NewPage := ScrollInfo.nPage;
    NewPage := Min(Max(NewPage, 0), AdjUpper - AdjLower + 1);
    if AdjPageSize <> NewPage then
    begin
      AdjPageSize := NewPage;
      HasChanged := True;
    end;
    NewVal := (AdjPageSize / 6) + 1;
    if AdjPageInc <> NewVal then
    begin
      AdjPageInc := NewVal;
      HasChanged := True;
    end;
  end;
  if (ScrollInfo.fMask and SIF_POS) <> 0 then
  begin
    NewVal := Min(Max(gdouble(ScrollInfo.nPos), AdjLower),
                  AdjUpper - Max(AdjPageSize - 1, 0));
    if AdjValue <> NewVal then
    begin
      AdjValue := NewVal;
      HasChanged := True;
    end;
  end;

  { For scrolling-win types with GtkViewport: convert LCL adjustment values
    (upper=nMax, page_size=nPage) to GtkViewport-compatible format
    (upper=ContentSize, page_size=ViewportH).  Both encode the same scroll
    range (nMax - nPage), but using GtkViewport's convention prevents
    GtkViewport from overwriting our values during re-layout, which would
    trigger value-changed callbacks and cause scrollbar collapse on click. }
  ContentSize := -1;
  if (AScrollWin <> nil) and not (wtWindow in AWidget.WidgetType)
    and not (wtScrollBar in AWidget.WidgetType) then
  begin
    AScrollWin^.get_allocation(@SwAlloc);
    if (SwAlloc.width > 0) and (SwAlloc.height > 0) then
    begin
      ViewportW := SwAlloc.width;
      ViewportH := SwAlloc.height;
      sb := AScrollWin^.get_vscrollbar;
      if (sb <> nil) and sb^.get_visible then
        Dec(ViewportW, gtk_widget_get_allocated_width(sb));
      sb := AScrollWin^.get_hscrollbar;
      if (sb <> nil) and sb^.get_visible then
        Dec(ViewportH, gtk_widget_get_allocated_height(sb));
      if ViewportW < 1 then ViewportW := 1;
      if ViewportH < 1 then ViewportH := 1;
      if SBStyle = SB_HORZ then
      begin
        ContentSize := Round(AdjUpper - AdjPageSize) + ViewportW;
        if ContentSize < ViewportW then ContentSize := ViewportW;
        AdjUpper := ContentSize;
        AdjPageSize := ViewportW;
      end
      else if SBStyle in [SB_VERT, SB_BOTH] then
      begin
        ContentSize := Round(AdjUpper - AdjPageSize) + ViewportH;
        if ContentSize < ViewportH then ContentSize := ViewportH;
        AdjUpper := ContentSize;
        AdjPageSize := ViewportH;
      end;
      AdjPageInc := (AdjPageSize / 6) + 1;
      { Re-clamp value to converted range }
      NewVal := AdjUpper - AdjPageSize;
      if NewVal < AdjLower then NewVal := AdjLower;
      if AdjValue > NewVal then
        AdjValue := NewVal;
      if AdjValue < AdjLower then
        AdjValue := AdjLower;
      { Re-check HasChanged against current adjustment (which GtkViewport
        may have already set to these same values) }
      HasChanged :=
        (AdjLower <> Adjustment^.lower) or
        (AdjUpper <> Adjustment^.upper) or
        (AdjPageSize <> Adjustment^.page_size) or
        (AdjValue <> Adjustment^.value) or
        (AdjStepInc <> Adjustment^.step_increment) or
        (AdjPageInc <> Adjustment^.page_increment);
    end;
  end;

  // check if scrollbar should be hidden
  IsScrollbarVis := True;
  if ((ScrollInfo.fMask and (SIF_RANGE or SIF_PAGE)) <> 0) and
     ((SBStyle=SB_HORZ) or (SBStyle=SB_VERT)) then
  begin
    if (AdjLower >= (AdjUpper - Max(AdjPageSize - 1, 0)))
    then begin
      if (ScrollInfo.fMask and SIF_DISABLENOSCROLL) = 0 then
        IsScrollbarVis := False
      else
        ;// scrollbar should look disabled
    end;
  end;

  Result := Round(AdjValue);

  { GTK2-style early exit: if nothing actually changed, skip policy changes
    and adjustment signal emission to prevent re-layout cascades. }
  if not HasChanged then
    exit;

  { Block Gtk4ScrollAdjChangedCB from delivering LM_VSCROLL/LM_HSCROLL during
    update.  This mirrors the Qt5 pattern: BeginUpdate increments FUpdateCount,
    the callback checks InUpdate and exits early, EndUpdate decrements. }
  AWidget.BeginUpdate;
  try
    { Use gtk_adjustment_configure() for batched update — emits ::changed at
      most 1x and ::value-changed at most 1x, vs individual property setters
      which each emit ::changed separately.  Combined with BeginUpdate, any
      emitted value-changed is suppressed by the InUpdate guard. }
    gtk_adjustment_configure(Adjustment, AdjValue, AdjLower, AdjUpper,
      AdjStepInc, AdjPageInc, AdjPageSize);
  finally
    AWidget.EndUpdate;
  end;

  if bRedraw then
  begin
    if (AScrollWin <> nil) then
    begin
      { GTK4: set_size_request on GtkFixed tells the GtkViewport the content
        size (replacing GTK2's gtk_layout_set_size).  When hiding the scrollbar
        (POLICY_NEVER), reset to -1 so the minimum drops to 0 (from the
        'lcl-scroll-fixed' measure tag) and NEVER does not propagate a large
        minimum upward.  When showing (POLICY_ALWAYS), set it so the viewport
        allocates the child at content size and computes correct adjustments.
        ContentSize is pre-computed above during viewport conversion.
        If not yet allocated (ContentSize=-1), use nMax as fallback. }
      if not (wtWindow in AWidget.WidgetType) then
      begin
        ACenter := AWidget.GetContainerWidget;
        ACenter^.get_size_request(@OldW, @OldH);
        if ContentSize < 0 then
          ContentSize := ScrollInfo.nMax;
        if SBStyle = SB_HORZ then
        begin
          if IsScrollbarVis then
          begin
            if ContentSize < 1 then ContentSize := 1;
            ACenter^.set_size_request(ContentSize, OldH);
          end
          else if OldW <> -1 then
            ACenter^.set_size_request(-1, OldH);
        end
        else if SBStyle = SB_VERT then
        begin
          if IsScrollbarVis then
          begin
            if ContentSize < 1 then ContentSize := 1;
            ACenter^.set_size_request(OldW, ContentSize);
          end
          else if OldH <> -1 then
            ACenter^.set_size_request(OldW, -1);
        end;
      end;

      { For window-type widgets: keep POLICY_NEVER always.  GTK4 lacks
        GtkLayout, so toggling NEVER/ALWAYS on the window ScrolledWindow
        causes full widget-tree re-layout cascades (the viewport size
        changes, triggering WMSize → LCL relayout → SetScrollInfo again
        → oscillation).  Child scrolling widgets handle their own policy.
        For non-window widgets: the scrollbar policy toggle is safe because
        the parent window viewport clips their minimum. }
      if not (wtWindow in AWidget.WidgetType) then
      begin
        if SBStyle = SB_HORZ then
          TGtk4ScrollableWin(AWidget).HScrollBarPolicy := POLICY[IsScrollbarVis]
        else
        if SBStyle = SB_VERT then
          TGtk4ScrollableWin(AWidget).VScrollBarPolicy := POLICY[IsScrollbarVis];
      end;
    end else
      AWidget.Update(nil);
  end;
end;

function TGtk4WidgetSet.SetSysColors(cElements: Integer; const lpaElements;
  const lpaRgbValues): Boolean;
var
  i: Integer;
  Elements: array[0..MaxInt div SizeOf(LongInt) - 1] of LongInt absolute lpaElements;
  RgbValues: array[0..MaxInt div SizeOf(DWORD) - 1] of DWORD absolute lpaRgbValues;
begin
  Result := True;
  for i := 0 to cElements - 1 do
  begin
    if (Elements[i] >= 0) and (Elements[i] <= MAX_SYS_COLORS) then
      SysColorMap[Elements[i]] := RgbValues[i];
  end;
end;

function TGtk4WidgetSet.SetTextCharacterExtra(DC: hdc; nCharExtra: Integer
  ): Integer;
begin
  { Character spacing is managed by Pango font attributes.
    Not implemented in GTK2 either. }
  Result := 0;
end;

function TGtk4WidgetSet.SetTextColor(DC: HDC; Color: TColorRef): TColorRef;
begin
  Result := CLR_INVALID;
  if IsValidDC(DC) then
  begin
    Result := TGtk4DeviceContext(DC).CurrentTextColor;
    TGtk4DeviceContext(DC).CurrentTextColor := Color;
  end;
end;

function TGtk4WidgetSet.SetViewPortExtEx(DC: HDC; XExtent, YExtent: Integer;
  OldSize: PSize): Boolean;
var
  DevCtx: TGtk4DeviceContext;
begin
  Result := False;
  if not IsValidDC(DC) then Exit;
  DevCtx := TGtk4DeviceContext(DC);
  if OldSize <> nil then
  begin
    OldSize^.cx := DevCtx.ViewPortExt.x;
    OldSize^.cy := DevCtx.ViewPortExt.y;
  end;
  if (XExtent <> DevCtx.ViewPortExt.x) or (YExtent <> DevCtx.ViewPortExt.y) then
  begin
    case DevCtx.MapMode of
      MM_ANISOTROPIC, MM_ISOTROPIC:
      begin
        DevCtx.ViewPortExt := Point(XExtent, YExtent);
        Result := True;
      end;
    end;
  end;
end;

function TGtk4WidgetSet.SetViewPortOrgEx(DC: HDC; NewX, NewY: Integer;
  OldPoint: PPoint): Boolean;
begin
  Result := False;
  if not IsValidDC(DC) then Exit;
  if OldPoint <> nil then
    OldPoint^ := TGtk4DeviceContext(DC).Offset;
  TGtk4DeviceContext(DC).Offset := Point(NewX, NewY);
  Result := True;
end;

function TGtk4WidgetSet.SetWindowExtEx(DC: HDC; XExtent, YExtent: Integer;
  OldSize: PSize): Boolean;
var
  DevCtx: TGtk4DeviceContext;
begin
  Result := False;
  if not IsValidDC(DC) then Exit;
  DevCtx := TGtk4DeviceContext(DC);
  if OldSize <> nil then
  begin
    OldSize^.cx := DevCtx.WindowExt.x;
    OldSize^.cy := DevCtx.WindowExt.y;
  end;
  if (XExtent <> DevCtx.WindowExt.x) or (YExtent <> DevCtx.WindowExt.y) then
  begin
    case DevCtx.MapMode of
      MM_ANISOTROPIC, MM_ISOTROPIC:
      begin
        DevCtx.WindowExt := Point(XExtent, YExtent);
        Result := True;
      end;
    end;
  end;
end;

function TGtk4WidgetSet.SetWindowLong(Handle: HWND; Idx: Integer;
  NewLong: PtrInt): PtrInt;
var
  AWidget: PGtkWidget;
  Data: Pointer;
begin
  { Return the previous value }
  Result := GetWindowLong(Handle, Idx);
  if not IsValidHandle(Handle) then
    Exit;
  AWidget := TGtk4Widget(Handle).Widget;
  if AWidget = nil then
    Exit;
  if not Gtk4IsObject(PGObject(AWidget)) then
    Exit;
  Data := {%H-}Pointer(PtrUInt(NewLong));
  case Idx of
    GWL_WNDPROC:
      g_object_set_data(PGObject(AWidget), 'lclwndproc', Data);
    GWL_HINSTANCE:
      g_object_set_data(PGObject(AWidget), 'lclhinstance', Data);
    GWL_HWNDPARENT:
      g_object_set_data(PGObject(AWidget), 'lclhwndparent', Data);
    GWL_STYLE:
      g_object_set_data(PGObject(AWidget), 'lclstyle', Data);
    GWL_EXSTYLE:
      g_object_set_data(PGObject(AWidget), 'lclexstyle', Data);
    GWL_USERDATA:
      g_object_set_data(PGObject(AWidget), 'lcluserdata', Data);
    GWL_ID:
      g_object_set_data(PGObject(AWidget), 'lclid', Data);
  end;
end;

function TGtk4WidgetSet.SetWindowOrgEx(dc: hdc; NewX, NewY: Integer;
  OldPoint: PPoint): Boolean;
var
  Matrix: Tcairo_matrix_t;
  //dx, dy: Double;
begin
  Result := False; // inherited SetWindowOrgEx(dc, NewX, NewY, OldPoint);
  if IsValidDC(DC) then
  begin
    GetWindowOrgEx(dc, OldPoint);
    cairo_get_matrix(TGtk4DeviceContext(DC).pcr, @Matrix);
    cairo_matrix_translate(@Matrix,
    	-NewX - TGtk4DeviceContext(DC).fncOrigin.x,
        -NewY - TGtk4DeviceContext(DC).fncOrigin.Y);
    cairo_transform(TGtk4DeviceContext(DC).pcr, @Matrix);
    Result := True;

  end;
end;

function TGtk4WidgetSet.SetWindowPos(hWnd: HWND; hWndInsertAfter: HWND; X, Y,
  cx, cy: Integer; uFlags: UINT): Boolean;
var
  AWidget: TGtk4Widget;
  ALeft, ATop, AWidth, AHeight: Integer;
begin
  Result := False;
  if hWnd = 0 then Exit;
  AWidget := TGtk4Widget(hWnd);
  if AWidget.Widget = nil then Exit;

  { Get current values for unchanged dimensions }
  if (uFlags and SWP_NOMOVE) <> 0 then
  begin
    ALeft := AWidget.LCLObject.Left;
    ATop := AWidget.LCLObject.Top;
  end else
  begin
    ALeft := X;
    ATop := Y;
  end;

  if (uFlags and SWP_NOSIZE) <> 0 then
  begin
    AWidth := AWidget.LCLObject.Width;
    AHeight := AWidget.LCLObject.Height;
  end else
  begin
    AWidth := cx;
    AHeight := cy;
  end;

  { Apply move and/or size }
  if ((uFlags and SWP_NOMOVE) = 0) or ((uFlags and SWP_NOSIZE) = 0) then
    AWidget.SetBounds(ALeft, ATop, AWidth, AHeight);

  { Show/Hide }
  if (uFlags and SWP_SHOWWINDOW) <> 0 then
    AWidget.Widget^.show;
  if (uFlags and SWP_HIDEWINDOW) <> 0 then
    AWidget.Widget^.hide;

  { Z-order: GTK4 doesn't support explicit Z-ordering of child widgets
    within a GtkFixed container. Skip silently. }

  Result := True;
end;

function TGtk4WidgetSet.SetWindowRgn(hWnd: HWND; hRgn: HRGN; bRedraw: Boolean
  ): longint;
begin
  { GTK4: gtk_widget_shape_combine_region removed. Shaped/non-rectangular
    windows are not supported in GTK4. }
  Result := 0;
end;

function TGtk4WidgetSet.ShowCaret(hWnd: HWND): Boolean;
begin
  Result := (hWnd <> 0) and (FCaret.Handle = hWnd);
  if Result then
  begin
    FCaret.Visible := True;
    if not FCaret.Blinking then
    begin
      { Timer not running — start a fresh blink cycle }
      FCaret.BlinkHide := False;
      StartCaretTimer;
    end;
    { If timer already running, preserve BlinkHide state (blink phase) }
    InvalidateCaret;
  end;
end;

function TGtk4WidgetSet.ShowScrollBar(Handle: HWND; wBar: Integer;
  bShow: Boolean): Boolean;
var
  AWidget: TGtk4Widget;
  NewPolicy: TGtkPolicyType;
  OldW, OldH: gint;
begin
  Result := IsValidHandle(Handle);
  if not Result then
    exit;
  AWidget := TGtk4Widget(Handle);
  if (AWidget.LCLObject = nil)
  or (csDestroying in AWidget.LCLObject.ComponentState)
  or (csFreeNotification in AWidget.LCLObject.ComponentState) then
    exit(False);
  if not AWidget.IsWidgetOK then
    exit(False);
  if wtScrollBar in AWidget.WidgetType then
  begin
    AWidget.Visible := bShow;
  end else
  if wtScrollingWin in AWidget.WidgetType then
  begin
    if TGtk4ScrollableWin(Handle).GetScrolledWindow = nil then
      exit;
    { For window-type widgets: skip policy changes entirely (same reason as
      SetScrollInfo — prevents layout oscillation on the main window). }
    if wtWindow in AWidget.WidgetType then
      exit;
    { GTK4: Matching GTK2 — straight ALWAYS/NEVER.  When hiding, also reset
      set_size_request on the GtkFixed so NEVER does not propagate a large
      minimum from a previous SetScrollInfo call. }
    if wBar in [SB_BOTH, SB_HORZ] then
    begin
      if bShow then
        NewPolicy := GTK_POLICY_ALWAYS
      else
      begin
        NewPolicy := GTK_POLICY_NEVER;
        AWidget.GetContainerWidget^.get_size_request(@OldW, @OldH);
        if OldW <> -1 then
          AWidget.GetContainerWidget^.set_size_request(-1, OldH);
      end;
      TGtk4ScrollableWin(AWidget).HScrollBarPolicy := NewPolicy;
    end;
    if wBar in [SB_BOTH, SB_VERT] then
    begin
      if bShow then
        NewPolicy := GTK_POLICY_ALWAYS
      else
      begin
        NewPolicy := GTK_POLICY_NEVER;
        AWidget.GetContainerWidget^.get_size_request(@OldW, @OldH);
        if OldH <> -1 then
          AWidget.GetContainerWidget^.set_size_request(OldW, -1);
      end;
      TGtk4ScrollableWin(AWidget).VScrollBarPolicy := NewPolicy;
    end;
  end else
  if not (wtWindow in AWidget.WidgetType) then
    DebugLn('WARNING: TGtk4WidgetSet.ShowScrollBar cannot get scrollbar from ',dbgsName(AWidget.LCLObject));
end;

function TGtk4WidgetSet.ShowWindow(hWnd: HWND; nCmdShow: Integer): Boolean;
begin
  Result := IsValidHandle(Hwnd);
  if not Result then Exit;
  if nCmdShow = SW_HIDE then
  begin
    TGtk4Widget(hWnd).Hide;
    Result := True;
  end
  else if TObject(hWnd) is TGtk4Window then
  begin
    if not Gtk4WindowCanPresent(TGtk4Window(hWnd)) then
    begin
      TGtk4Widget(hWnd).Hide;
      Exit(True);
    end;
    Result := TGtk4Window(hWnd).ShowState(nCmdShow)
  end
  else
  begin
    TGtk4Widget(hWnd).Show;
    Result := True;
  end;
end;

function TGtk4WidgetSet.StretchBlt(DestDC: HDC; X, Y, Width, Height: Integer;
  SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; ROp: Cardinal): Boolean;
begin
  Result := StretchMaskBlt(DestDC,X,Y,Width,Height,
                          SrcDC,XSrc,YSrc,SrcWidth,SrcHeight,
                          0,0,0,
                          ROp);
end;

function TGtk4WidgetSet.StretchMaskBlt(DestDC: HDC; X, Y, Width,
  Height: Integer; SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer;
  Mask: HBITMAP; XMask, YMask: Integer; Rop: DWORD): Boolean;
var
  DestContext: TGtk4DeviceContext absolute DestDC;
  SrcContext: TGtk4DeviceContext absolute SrcDC;
  ATargetRect, ASrcRect: TRect;
  MaskPixbuf: PGdkPixbuf;
  MaskSurface: Pcairo_surface_t;
  MaskData: PByte;
  MaskA8: PByte;
  MaskPixW, MaskPixH: Integer;
  MaskPixStride: Integer;
  MaskPixChannels: Integer;
  MaskA8Stride: Integer;
  MX, MY: Integer;
  MaskSrc: PByte;
  MaskDst: PByte;
  M: Tcairo_matrix_t;
begin
  Result := False;
  if not IsValidDC(DestDC) or not IsValidDC(SrcDC) then Exit;
  ATargetRect := Rect(X, Y, Width + X, Height + Y);
  ASrcRect := Rect(XSrc, YSrc, SrcWidth + XSrc, SrcHeight + YSrc);

  if (Mask <> 0) and IsValidGDIObject(Mask) and (TObject(Mask) is TGtk4Image) then
  begin
    { Draw source image through mask using cairo_mask_surface }
    MaskPixbuf := TGtk4Image(Mask).Handle;
    if MaskPixbuf <> nil then
    begin
      cairo_save(DestContext.pcr);
      try
        { Set source to the source image }
        if DestContext.OwnsSurface and SrcContext.OwnsSurface then
          gdk_cairo_set_source_pixbuf(DestContext.pcr,
            SrcContext.CurrentImage.Handle, 0, 0)
        else
          cairo_set_source_surface(DestContext.pcr,
            SrcContext.CairoSurface, 0, 0);
        { Set up source transformation for stretching }
        cairo_matrix_init_identity(@M);
        cairo_matrix_translate(@M, ASrcRect.Left, ASrcRect.Top);
        if (Width <> 0) and (Height <> 0) then
          cairo_matrix_scale(@M,
            (ASrcRect.Right - ASrcRect.Left) / (ATargetRect.Right - ATargetRect.Left),
            (ASrcRect.Bottom - ASrcRect.Top) / (ATargetRect.Bottom - ATargetRect.Top));
        cairo_matrix_translate(@M, -ATargetRect.Left, -ATargetRect.Top);
        cairo_pattern_set_matrix(cairo_get_source(DestContext.pcr), @M);
        { Clip to target rect }
        cairo_rectangle(DestContext.pcr, X, Y, Width, Height);
        cairo_clip(DestContext.pcr);
        { Convert pixbuf mask to explicit A8. Treat brighter pixels as more
          opaque; this matches the A8 mask semantics expected by cairo. }
        MaskPixW := gdk_pixbuf_get_width(MaskPixbuf);
        MaskPixH := gdk_pixbuf_get_height(MaskPixbuf);
        MaskPixStride := gdk_pixbuf_get_rowstride(MaskPixbuf);
        MaskPixChannels := gdk_pixbuf_get_n_channels(MaskPixbuf);
        MaskData := PByte(gdk_pixbuf_get_pixels(MaskPixbuf));
        MaskA8Stride := cairo_format_stride_for_width(CAIRO_FORMAT_A8, MaskPixW);
        GetMem(MaskA8, MaskA8Stride * MaskPixH);
        try
          for MY := 0 to MaskPixH - 1 do
          begin
            MaskSrc := MaskData + (MY * MaskPixStride);
            MaskDst := MaskA8 + (MY * MaskA8Stride);
            for MX := 0 to MaskPixW - 1 do
            begin
              if MaskPixChannels >= 4 then
                MaskDst^ := MaskSrc[3]
              else
                MaskDst^ := MaskSrc[0];
              Inc(MaskDst);
              Inc(MaskSrc, MaskPixChannels);
            end;
          end;

          MaskSurface := cairo_image_surface_create_for_data(MaskA8,
            CAIRO_FORMAT_A8, MaskPixW, MaskPixH, MaskA8Stride);
          try
            cairo_mask_surface(DestContext.pcr, MaskSurface, X - XMask, Y - YMask);
          finally
            cairo_surface_destroy(MaskSurface);
          end;
        finally
          FreeMem(MaskA8);
        end;
      finally
        cairo_restore(DestContext.pcr);
      end;
      Result := True;
      Exit;
    end;
  end;

  { No mask — draw normally, respecting basic ROP codes }
  case Rop of
    BLACKNESS:
      begin
        cairo_save(DestContext.pcr);
        cairo_set_source_rgb(DestContext.pcr, 0, 0, 0);
        cairo_rectangle(DestContext.pcr, X, Y, Width, Height);
        cairo_fill(DestContext.pcr);
        cairo_restore(DestContext.pcr);
        Result := True;
        Exit;
      end;
    WHITENESS:
      begin
        cairo_save(DestContext.pcr);
        cairo_set_source_rgb(DestContext.pcr, 1, 1, 1);
        cairo_rectangle(DestContext.pcr, X, Y, Width, Height);
        cairo_fill(DestContext.pcr);
        cairo_restore(DestContext.pcr);
        Result := True;
        Exit;
      end;
    SRCINVERT:
      cairo_set_operator(DestContext.pcr, CAIRO_OPERATOR_XOR);
  end;

  if DestContext.OwnsSurface and SrcContext.OwnsSurface then
    DestContext.drawImage1(@ATargetRect,
      PgdkPixbuf(SrcContext.CurrentImage.Handle), @ASrcRect, nil, nil)
  else
    DestContext.drawSurface(@ATargetRect,
      SrcContext.CairoSurface, @ASrcRect, nil, nil);

  { Restore default operator if changed }
  if Rop = SRCINVERT then
    cairo_set_operator(DestContext.pcr, CAIRO_OPERATOR_OVER);
  Result := True;
end;

function TGtk4WidgetSet.SystemParametersInfo(uiAction: DWord; uiParam: DWord;
  pvParam: Pointer; fWinIni: DWord): LongBool;
var
  wa:TGdkRectangle;
  pdisp:PGdkDisplay;
  pmon:PgdkMonitor;
  pr:PRect;
begin
  Result:=True;
  Case uiAction of
    SPI_GETWHEELSCROLLLINES: PDword(pvParam)^ := 3;
    SPI_GETWORKAREA: begin
      { Always write pvParam first (fallback = virtual screen metrics).
        GetWorkAreaRect in screen.inc ignores the return value, so we must
        never leave pvParam uninitialized — matching GTK2 behaviour. }
      pr:=PRect(pvParam);
      pr^:=Bounds(GetSystemMetrics(SM_XVIRTUALSCREEN),
                  GetSystemMetrics(SM_YVIRTUALSCREEN),
                  GetSystemMetrics(SM_CXVIRTUALSCREEN),
                  GetSystemMetrics(SM_CYVIRTUALSCREEN));
      { Try to refine with actual workarea from the primary monitor }
      pdisp:=TGdkDisplay.get_default;
      pmon:=pdisp^.get_primary_monitor();
      if not Assigned(pmon) then begin
        if pdisp^.get_n_monitors > 0 then
          pmon := pdisp^.get_monitor(0);
      end;
      if Assigned(pmon) then
      begin
        wa.x := 0; wa.y := 0; wa.width := 0; wa.height := 0;
        pmon^.get_workarea(@wa);
        if (wa.width <= 0) or (wa.height <= 0)
        or (wa.width > 32768) or (wa.height > 32768) then
        begin
          wa.x := 0; wa.y := 0; wa.width := 0; wa.height := 0;
          gdk_monitor_get_geometry(pmon, @wa);
        end;
        if (wa.width > 0) and (wa.height > 0)
        and (wa.width <= 32768) and (wa.height <= 32768) then
        begin
          pr^.Left:=wa.x;
          pr^.Top:=wa.y;
          pr^.Width:=wa.width;
          pr^.Height:=wa.height;
        end;
      end;
    end;
  else
    Result:=False;
  end;
end;

function TGtk4WidgetSet.TextOut(DC: HDC; X, Y: Integer; Str: PChar; Count: Integer): Boolean;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4WidgetSet.TextOut X=',dbgs(x),' Y=',dbgs(y),' Text=',dbgs(Str),' Count=',dbgs(Count));
  {$ENDIF}
  Result := False;
  if Count <= 0 then
    Exit;
  if IsValidDC(DC) then
  begin
    Result := True;
    TGtk4DeviceContext(DC).drawText(X, Y, Str, Count);
  end;
end;

function TGtk4WidgetSet.UpdateWindow(Handle: HWND): Boolean;
begin
  {$ifdef VerboseGtk4WinAPI}
  DebugLn('[Gtk4WinAPI UpdateWindow]');
  {$endif}
  Result := False;
  if IsValidHandle(Handle) then
  begin
    TGtk4Widget(Handle).Update(nil);
    { GTK4: .window^.process_updates removed; gtk_widget_queue_draw replaces it }
    TGtk4Widget(Handle).GetContainerWidget^.queue_draw;
    Result := True;
  end;
end;

function TGtk4WidgetSet.WindowFromPoint(APoint: TPoint): HWND;
var
  AList, ANode: PGList;
  AWindow: PGtkWindow;
  AWidget, APickedWidget: PGtkWidget;
  Alloc: TGtkAllocation;
  AHandle: TGtk4Widget;
  LocalX, LocalY: Double;
  OrigX, OrigY: LongInt;
  SurfX, SurfY: Double;
begin
  Result := 0;
  AList := gtk_window_list_toplevels;
  if AList = nil then Exit;
  try
    ANode := AList;
    while ANode <> nil do
    begin
      AWindow := PGtkWindow(ANode^.data);
      ANode := ANode^.next;
      if (AWindow = nil) or (not Gtk4IsGtkWindow(PGObject(AWindow))) then
        Continue;
      AWidget := PGtkWidget(AWindow);
      if (not Gtk4IsWidget(PGObject(AWidget))) or (AWidget^.in_destruction) then
        Continue;
      { Hit-test only windows actually on screen — with correct screen
        origins a hidden toplevel would otherwise match at its last
        position. }
      if not AWidget^.get_mapped then
        Continue;
      AWidget^.get_allocation(@Alloc);
      { Convert the screen point to window-content-local coordinates.
        A GTK4 toplevel's allocation x/y is always (0,0) — it is NOT a
        screen position.  Use the X11 window origin + CSD surface transform
        (same as TGtk4Widget.ClientToScreen).  On Wayland the origin query
        fails — fall back to the old allocation-based math (content-relative,
        pre-existing limitation). }
      if Gtk4X11GetWindowOrigin(AWidget, OrigX, OrigY) then
      begin
        SurfX := 0;
        SurfY := 0;
        gtk4_native_get_surface_transform(AWidget, @SurfX, @SurfY);
        LocalX := APoint.X - (OrigX + SurfX);
        LocalY := APoint.Y - (OrigY + SurfY);
      end
      else
      begin
        LocalX := APoint.X - Alloc.x;
        LocalY := APoint.Y - Alloc.y;
      end;
      if (LocalX >= 0) and (LocalX < Alloc.width) and
         (LocalY >= 0) and (LocalY < Alloc.height) then
      begin
        { Try to pick the deepest widget at this point }
        APickedWidget := gtk4_widget_pick(AWidget, LocalX, LocalY,
          GTK_PICK_DEFAULT or GTK_PICK_INSENSITIVE or GTK_PICK_NON_TARGETABLE);
        if APickedWidget <> nil then
        begin
          { Walk up to find the first widget with an LCL handle }
          while APickedWidget <> nil do
          begin
            AHandle := Gtk4WidgetFromGtkWidget(APickedWidget);
            if AHandle <> nil then
            begin
              Result := HWND(AHandle);
              Exit;
            end;
            APickedWidget := APickedWidget^.get_parent;
          end;
        end;
        { Fallback: return the window handle }
        AHandle := Gtk4WidgetFromGtkWidget(AWidget);
        if AHandle <> nil then
        begin
          Result := HWND(AHandle);
          Exit;
        end;
      end;
    end;
  finally
    g_list_free(AList);
  end;
end;
