{%MainUnit gtk4int.pas}

{******************************************************************************
                 All GTK4 interface communication implementations.

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}


//##apiwiz##sps##   // Do not remove

function TGtk4WidgetSet.CreateRubberBand(const ARect: TRect; const ABrush: HBrush): HWND;
var
  Widget: PGtkWidget absolute Result;
  dx, dy: integer;
begin
  dx := ARect.Right - ARect.Left;
  dy := ARect.Bottom - ARect.Top;
  if dx < 0 then
    dx := 0;
  if dy < 0 then
    dy := 0;

  // rubber band is just a window without a title
  { GTK4: gtk_window_new takes no arguments }
  Result := {%H-}HWND(gtk4_window_new);
  gtk_window_set_default_size({%H-}PGtkWindow(Result), dx, dy);

  { GTK4: gdk_window_set_decorations/functions removed; use gtk_window_set_decorated }
  gtk_window_set_decorated({%H-}PGtkWindow(Result), False);
  gtk_widget_set_opacity(Widget, 0.25);

  gtk_widget_show(Widget);
end;

procedure TGtk4WidgetSet.DestroyRubberBand(ARubberBand: HWND);
begin
  if ARubberBand <> 0 then
    gtk_window_close({%H-}PGtkWindow(ARubberBand));
end;

procedure TGtk4WidgetSet.DrawDefaultDockImage(AOldRect, ANewRect: TRect;
  AOperation: TDockImageOperation);
var
  dx, dy: integer;
begin
  dx := ANewRect.Right - ANewRect.Left;
  dy := ANewRect.Bottom - ANewRect.Top;
  if dx < 0 then dx := 0;
  if dy < 0 then dy := 0;

  if FDockImage = nil then
  begin
    { Create undecorated semi-transparent window }
    FDockImage := PGtkWidget(gtk4_window_new);
    gtk_window_set_decorated(PGtkWindow(FDockImage), False);
    gtk_widget_set_opacity(FDockImage, 0.25);
    gtk_window_set_default_size(PGtkWindow(FDockImage), dx, dy);
  end
  else
    gtk_window_set_default_size(PGtkWindow(FDockImage), dx, dy);

  { GTK4/Wayland: Cannot position windows arbitrarily.
    The dock image will appear but may not be at the exact position. }
  case AOperation of
    disShow: gtk_widget_show(FDockImage);
    disHide: gtk_widget_hide(FDockImage);
  end;
end;

procedure TGtk4WidgetSet.DrawGrid(DC: HDC; const R: TRect; DX, DY: Integer);
var
  X, Y: Integer;
  W, H: Integer;
  ctx: TGtk4DeviceContext;
begin
  if not IsValidDC(DC) then Exit;
  ctx := TGtk4DeviceContext(DC);
  W := (R.Right - R.Left - 1) div DX;
  H := (R.Bottom - R.Top - 1) div DY;
  ctx.SetSourceColor(ctx.CurrentPen.Color);
  for Y := 0 to H do
    for X := 0 to W do
      cairo_rectangle(ctx.pcr, R.Left + X * DX, R.Top + Y * DY, 1, 1);
  cairo_fill(ctx.pcr);
end;


function TGtk4WidgetSet.IsDesignerDC(WindowHandle: HWND; DC: HDC): Boolean;
begin
  { GTK4 two-phase painting: Returns True ONLY during Phase 2
    (GtkEventDesignerPaint) where FDesignerDC is set.
    Phase 1 (GtkEventPaint): FDesignerDC=0 → False → PaintClientGrid runs → grid dots.
    Phase 2: FDesignerDC=DC → True → DoPaintDesignerItems runs → selection handles.
    PaintControls checks this to skip child painting during Phase 2. }
  Result := False;
  if (WindowHandle = 0) or not IsValidHandle(WindowHandle) then Exit;
  if not (csDesigning in TGtk4Widget(WindowHandle).LCLObject.ComponentState) then Exit;
  Result := (TGtk4Widget(WindowHandle).DesignerDC <> 0) and
            (TGtk4Widget(WindowHandle).DesignerDC = DC);
end;

{------------------------------------------------------------------------------
  function TGtk4WidgetSet.ExtUTF8Out(DC: HDC; X, Y: Integer; Options: Longint;
    Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean;

  As ExtTextOut except that Str is treated as UTF8
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.ExtUTF8Out(DC: HDC; X, Y: Integer; Options: Longint;
  Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean;
begin
  // all fonts are UTF-8 under GTK => no mapping needed
  Result:=ExtTextOut(DC,X,Y,Options,Rect,Str,Count,Dx);
end;

function TGtk4WidgetSet.TextUTF8Out(DC: HDC; X, Y: Integer; Str: PChar; Count: Longint): Boolean;
begin
  // all fonts are UTF-8 under gtk4 => no mapping needed
  Result := TextOut(DC, X, Y, Str, Count);
end;

{------------------------------------------------------------------------------
  function TGtk4WidgetSet.FontIsMonoSpace(Font: HFont): boolean;

  True if font characters have all the same width.
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.FontIsMonoSpace(Font: HFont): boolean;
var
  AFont: TGtk4Font;
  MWidth, IWidth: gint;
begin
  Result := False;
  if not IsValidGDIObject(Font) then
    Exit;
  if not (TObject(Font) is TGtk4Font) then
    Exit;
  AFont := TGtk4Font(Font);
  if AFont.Layout = nil then
    Exit;
  { Heuristic: compare pixel widths of 'm' (wide) and 'i' (narrow).
    If equal, the font is monospaced. Same approach as GTK2 backend. }
  pango_layout_set_single_paragraph_mode(AFont.Layout, True);
  pango_layout_set_width(AFont.Layout, -1);
  pango_layout_set_text(AFont.Layout, 'm', 1);
  pango_layout_get_pixel_size(AFont.Layout, @MWidth, nil);
  pango_layout_set_text(AFont.Layout, 'i', 1);
  pango_layout_get_pixel_size(AFont.Layout, @IWidth, nil);
  Result := (MWidth = IWidth);
end;

{------------------------------------------------------------------------------
  Function: GetAcceleratorString
  Params: AVKey:
          AShiftState:
  Returns:

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.GetAcceleratorString(const AVKey: Byte;
  const AShiftState: TShiftState): String;
begin
  Result:=inherited GetAcceleratorString(AVKey,AShiftState);
end;



{------------------------------------------------------------------------------
  Function: RadialPie
  Params: DC, bounding rectangle (x1,y1,x2,y2), angles in 1/16th degree
  Returns: True on success

  Native Cairo pie drawing — more efficient than the base class PolyBezier fallback.
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RadialPie(DC: HDC; x1, y1, x2, y2, Angle1,
  Angle2: Integer): Boolean;
var
  ctx: TGtk4DeviceContext;
  bFill, bBorder: Boolean;
begin
  Result := IsValidDC(DC) and (x2 > x1) and (y2 > y1);
  if not Result then Exit;
  ctx := TGtk4DeviceContext(DC);
  bFill := ctx.CurrentBrush.Style <> BS_NULL;
  bBorder := ctx.CurrentPen.Style <> psClear;
  if not (bFill or bBorder) then Exit;
  ctx.drawPie(x1, y1, x2, y2, Angle1, Angle2, bFill, bBorder);
end;

{------------------------------------------------------------------------------
  Function: RawImage_CreateBitmap
  Params: ARawImage:
          ABitmap:
          AMask:
          ASkipMask: When set, no mask is created
  Returns:

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_CreateBitmaps(const ARawImage: TRawImage; out
  ABitmap, AMask: HBitmap; ASkipMask: boolean): boolean;
var
  Desc: TRawImageDescription absolute ARawImage.Description;
  NewData: PByte;
  ImageFormat: Tcairo_format_t;
  ARowStride: PtrUInt;
  SrcRowStride: PtrUInt;
  DstRowStride: PtrUInt;
  MaskSrcRowStride: PtrUInt;
  x,y:integer;
  src,dst,SrcRowPtr,DstRowPtr:pbyte;
  ridx,gidx,bidx,aidx:byte;
  MaskByte: Byte;
  MaskBit: Byte;
  SrcIntf: TLazIntfImage;
  SrcColor: TFPColor;
  AlphaAllZero: Boolean;
  AlphaHasNonZero: Boolean;
begin
  Result := False;
  ABitmap := 0;
  AMask := 0;

  if ARawImage.DataSize > 0 then
  begin
    SrcRowStride := Desc.BytesPerLine;
    if SrcRowStride = 0 then
      SrcRowStride := GetBytesPerLine(Desc.Width, Desc.BitsPerPixel, Desc.LineEnd);

    // check if the pixels are in order, pixbuf expects them in R-G-B-A
    Desc.GetRGBIndices(Ridx, Gidx, Bidx, AIdx);

    GetMem(NewData, ArawImage.DataSize);
    DstRowStride := SrcRowStride;

    if desc.BitsPerPixel = 1 then
    begin
      { 1-bit images: copy raw data directly for CAIRO_FORMAT_A1 }
      System.Move(ArawImage.Data^, NewData^, ArawImage.DataSize);
    end
    else if desc.BitsPerPixel = 8 then
    begin
      { 8-bit images can be either gray/alpha-like data or indexed palette
        images (common in icon resources). Handle palette data explicitly. }
      FreeMem(NewData);
      DstRowStride := GetBytesPerLine(Desc.Width, 32, rileDWordBoundary);
      GetMem(NewData, DstRowStride * Desc.Height);

      if Desc.PaletteColorCount > 0 then
      begin
        SrcIntf := TLazIntfImage.Create(ARawImage, False);
        try
          for y := 0 to Desc.Height - 1 do
          begin
            Dst := NewData + (y * DstRowStride);
            for x := 0 to Desc.Width - 1 do
            begin
              SrcColor := SrcIntf.Colors[x, y];
              Dst[0] := SrcColor.Red shr 8;
              Dst[1] := SrcColor.Green shr 8;
              Dst[2] := SrcColor.Blue shr 8;
              Dst[3] := SrcColor.Alpha shr 8;
              Inc(Dst, 4);
            end;
          end;
        finally
          SrcIntf.Free;
        end;
      end
      else
      begin
        DstRowPtr := NewData;
        SrcRowPtr := ArawImage.Data;
        y := Desc.Height;
        while y > 0 do
        begin
          Src := SrcRowPtr;
          Dst := DstRowPtr;
          x := Desc.Width;
          while x > 0 do
          begin
            Dst[0] := Src^;
            Dst[1] := Src^;
            Dst[2] := Src^;
            Dst[3] := $FF;
            Inc(Src);
            Inc(Dst, 4);
            Dec(x);
          end;
          Inc(SrcRowPtr, SrcRowStride);
          Inc(DstRowPtr, DstRowStride);
          Dec(y);
        end;
      end;
    end
    else if desc.BitsPerPixel = 16 then
    begin
      { 16-bit images: no matching cairo format, convert to 32-bit ARGB32 }
      FreeMem(NewData);
      GetMem(NewData, Desc.Width * Desc.Height * 4);
      SrcRowPtr := ArawImage.Data;
      DstRowPtr := NewData;
      for y := 0 to Desc.Height - 1 do
      begin
        Src := SrcRowPtr;
        Dst := DstRowPtr;
        for x := 0 to Desc.Width - 1 do
        begin
          { Assume RGB565 format: RRRRRGGGGGGBBBBB }
          Dst[0] := (Src[1] and $F8);               { R: 5 bits }
          Dst[1] := ((Src[1] shl 5) or (Src[0] shr 3)) and $FC; { G: 6 bits }
          Dst[2] := (Src[0] shl 3) and $F8;          { B: 5 bits }
          Dst[3] := $FF;                              { A: opaque }
          Inc(Src, 2);
          Inc(Dst, 4);
        end;
        Inc(SrcRowPtr, Desc.BytesPerLine);
        Inc(DstRowPtr, Desc.Width * 4);
      end;
    end
    else if desc.BitsPerPixel = 24 then
    begin
      { Cairo RGB24 uses 32-bit pixels. Normalize 24bpp input into 32bpp buffer. }
      FreeMem(NewData);
      DstRowStride := GetBytesPerLine(Desc.Width, 32, rileDWordBoundary);
      GetMem(NewData, DstRowStride * Desc.Height);
      DstRowPtr := NewData;
      SrcRowPtr := ArawImage.Data;
      y := Desc.Height;
      while y > 0 do
      begin
        Src := SrcRowPtr;
        Dst := DstRowPtr;
        x := Desc.Width;
        while x > 0 do
        begin
          Dst[0] := Src[Ridx];
          Dst[1] := Src[Gidx];
          Dst[2] := Src[Bidx];
          Dst[3] := $FF;

          Inc(Src, 3);
          Inc(Dst, 4);
          Dec(x);
        end;
        Inc(SrcRowPtr, SrcRowStride);
        Inc(DstRowPtr, DstRowStride);
        Dec(y);
      end;
    end else
    if (Ridx <> 0) or (Gidx <> 1) or (Bidx <> 2) or (AIdx <> 3) then
    begin
      // put components in right order

      DstRowPtr := NewData;
      SrcRowPtr := ArawImage.Data;
      y := Desc.Height;
      while y > 0 do
      begin
        Src := SrcRowPtr;
        Dst := DstRowPtr;
        x := Desc.Width;
        while x > 0 do
        begin
          Dst[0] := Src[Ridx];
          Dst[1] := Src[Gidx];
          Dst[2] := Src[Bidx];
          Dst[3] := Src[Aidx] ;

          Inc(Src, 4);
          Inc(Dst, 4);
          Dec(x);
        end;
        Inc(SrcRowPtr, SrcRowStride);
        Inc(DstRowPtr, DstRowStride);
        Dec(y);
      end;
    end else begin
      System.Move(ArawImage.Data^, NewData^, ArawImage.DataSize);
    end;

    if (Desc.BitsPerPixel = 32) and (NewData <> nil) then
    begin
      { Some image sources carry a separate mask while alpha bytes are zeroed.
        In GTK4/cairo ARGB32 this makes icons fully transparent. }
      AlphaAllZero := True;
      AlphaHasNonZero := False;
      SrcRowPtr := NewData;
      y := Desc.Height;
      while y > 0 do
      begin
        Dst := SrcRowPtr;
        x := Desc.Width;
        while x > 0 do
        begin
          if Dst[3] <> 0 then
          begin
            AlphaAllZero := False;
            AlphaHasNonZero := True;
            Break;
          end;
          Inc(Dst, 4);
          Dec(x);
        end;
        if AlphaHasNonZero then Break;
        Inc(SrcRowPtr, DstRowStride);
        Dec(y);
      end;
      if AlphaAllZero then
      begin
        SrcRowPtr := NewData;
        y := Desc.Height;
        while y > 0 do
        begin
          Dst := SrcRowPtr;
          x := Desc.Width;
          while x > 0 do
          begin
            Dst[3] := $FF;
            Inc(Dst, 4);
            Dec(x);
          end;
          Inc(SrcRowPtr, DstRowStride);
          Dec(y);
        end;
      end;
    end;

  end
  else
    NewData := nil;

  case Desc.BitsPerPixel of
    1: ImageFormat := CAIRO_FORMAT_A1;
    8: ImageFormat := CAIRO_FORMAT_ARGB32; { converted to 32-bit above }
    16: ImageFormat := CAIRO_FORMAT_ARGB32; { converted to 32-bit above }
    24: ImageFormat := CAIRO_FORMAT_ARGB32; { converted to 32-bit above }
    32: ImageFormat := CAIRO_FORMAT_ARGB32;
  else
    Exit(False);
  end;
  if (Desc.BitsPerPixel = 8) or (Desc.BitsPerPixel = 16) or (Desc.BitsPerPixel = 24) then
    ARowStride := GetBytesPerLine(Desc.Width, 32, rileDWordBoundary) { converted to 32-bit }
  else if (Desc.BitsPerPixel = 32) then
    ARowStride := DstRowStride
  else
    ARowStride := GetBytesPerLine(Desc.Width, Desc.BitsPerPixel, rileDWordBoundary);
  ABitmap := HBitmap(TGtk4Image.Create(NewData, Desc.Width, Desc.Height, ARowStride, ImageFormat,
                     {not ASkipMask}true));  // Using ASkipMask for DataOwner param prevents a crash later.
  Result := ABitmap <> 0;

  if ASkipMask then Exit;

  if (ARawImage.Mask <> nil) and (ARawImage.MaskSize > 0) then
  begin
    { Convert LCL mask (1bpp/8bpp) to GTK4 cairo A8 alpha mask.
      LCL mask bit=True means transparent -> alpha 0. }
    ARowStride := GetBytesPerLine(Desc.Width, 8, rilebyteBoundary);
    GetMem(NewData, ARowStride * Desc.Height);
    FillChar(NewData^, ARowStride * Desc.Height, $FF); { default: opaque }

    SrcRowPtr := ARawImage.Mask;
    DstRowPtr := NewData;
    if Desc.Height > 0 then
      MaskSrcRowStride := ARawImage.MaskSize div Desc.Height
    else
      MaskSrcRowStride := 0;

    if MaskSrcRowStride = 0 then
    begin
      if Desc.MaskBitsPerPixel > 0 then
        MaskSrcRowStride := GetBytesPerLine(Desc.Width, Desc.MaskBitsPerPixel, Desc.MaskLineEnd)
      else
        MaskSrcRowStride := GetBytesPerLine(Desc.Width, 1, Desc.MaskLineEnd);
    end;

    y := Desc.Height;
    while y > 0 do
    begin
      Src := SrcRowPtr;
      Dst := DstRowPtr;
      x := 0;
      while x < Desc.Width do
      begin
        case Desc.MaskBitsPerPixel of
          1:
            begin
              MaskByte := Src[x shr 3];
              if Desc.MaskBitOrder = riboBitsInOrder then
                MaskBit := (MaskByte shr (x and 7)) and $1
              else
                MaskBit := (MaskByte shr (7 - (x and 7))) and $1;
            end;
          8:
            begin
              { Non-zero mask byte is treated as transparent }
              if Src[x] <> 0 then
                MaskBit := 1
              else
                MaskBit := 0;
            end;
        else
          MaskBit := 0;
        end;

        if MaskBit <> 0 then
          Dst^ := $00
        else
          Dst^ := $FF;
        Inc(Dst);
        Inc(x);
      end;
      Inc(SrcRowPtr, MaskSrcRowStride);
      Inc(DstRowPtr, ARowStride);
      Dec(y);
    end;
  end
  else
    NewData := nil;

  if NewData <> nil then
  begin
    ARowStride := GetBytesPerLine(Desc.Width, 8, rilebyteBoundary);
    AMask := HBitmap(TGtk4Image.Create(NewData, Desc.Width, Desc.Height, ARowStride, CAIRO_FORMAT_A8, True));
  end;
  { No mask data -> AMask stays 0 (initialized at top).
    Caller sets FMasked := False, StretchMaskBlt uses cairo_paint (no clip). }

end;

{------------------------------------------------------------------------------
  Function: RawImage_DescriptionFromBitmap
  Params: Bitmap: HBITMAP;
          Desc: PRawImageDescription
  Returns: boolean;

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_DescriptionFromBitmap(ABitmap: HBITMAP; out ADesc: TRawImageDescription): boolean;
const
  CairoImageFormatToDepth: array[CAIRO_FORMAT_INVALID..CAIRO_FORMAT_RGB30] of integer =
  (
    {CAIRO_FORMAT_INVALID}   -1,
    {CAIRO_FORMAT_ARGB32}    32,
    {CAIRO_FORMAT_RGB24}     24,
    {CAIRO_FORMAT_A8}         8,
    {CAIRO_FORMAT_A1}         1,
    {CAIRO_FORMAT_RGB16_565} 16,
    {CAIRO_FORMAT_RGB30}     15
  );
//============================
var
  Image: TGtk4Image absolute ABitmap;

begin
  Result := False;
  Result := CheckBitmap(ABitmap, 'RawImage_DescriptionFromBitmap');
  if not Result then Exit;

  ADesc.Init;
  ADesc.Width := Image.Width;
  ADesc.Height := Image.Height;

  ADesc.BitOrder := riboReversedBits;
  ADesc.ByteOrder := riboLSBFirst;
  ADesc.LineOrder := riloTopToBottom;
  ADesc.LineEnd := rileDWordBoundary;

  ADesc.Depth := CairoImageFormatToDepth[Image.Format];
  ADesc.BitsPerPixel := ADesc.Depth;
  if ADesc.BitsPerPixel = 24 then
    ADesc.BitsPerPixel := 32;

  ADesc.Format := ricfRGBA;
  case ADesc.Depth of
    1, 8:
      begin
        ADesc.Format := ricfGray;

        ADesc.RedPrec := ADesc.BitsPerPixel;
      end;
    16:
      begin
        ADesc.Depth := 15;

        ADesc.RedPrec := 5;
        ADesc.GreenPrec := 5;
        ADesc.BluePrec := 5;

        ADesc.RedShift := 10;
        ADesc.GreenShift := 5;
        ADesc.BlueShift := 0;
      end;
    24:
      begin
        ADesc.RedPrec := 8;
        ADesc.GreenPrec := 8;
        ADesc.BluePrec := 8;

        ADesc.RedShift := 16;
        ADesc.GreenShift := 8;
        ADesc.BlueShift := 0;
      end;
    32:
      begin
        ADesc.AlphaPrec := 8;
        ADesc.RedPrec := 8;
        ADesc.GreenPrec := 8;
        ADesc.BluePrec := 8;

        ADesc.AlphaShift := 24;
        ADesc.RedShift := 0;
        ADesc.GreenShift := 8;
        ADesc.BlueShift := 16;
      end;
  end;
end;

{------------------------------------------------------------------------------
  function RawImage_DescriptionFromDevice
  Params: DC: HDC;
          Desc: PRawImageDescription
  Returns: boolean;

  Retrieves the information about the structure of the supported image data.
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_DescriptionFromDevice(ADC: HDC; out
  ADesc: TRawImageDescription): Boolean;
begin
  Result := true;

  FillStandardDescription(ADesc{%H-});
end;

function RawImage_DescriptionFromPixbuf(out ADesc: TRawImageDescription; APixbuf: PGdkPixbuf): boolean;
var
  Width, Height, Depth: integer;
  HasAlpha: Boolean;
begin
  Width := 0;
  Height := 0;

  if APixbuf = nil then
  begin
    HasAlpha := False;
    Depth := 24;
  end else
  begin
    Width := gdk_pixbuf_get_width(APixbuf);
    Height := gdk_pixbuf_get_height(APixbuf);
    Depth := gdk_pixbuf_get_bits_per_sample(APixbuf) * gdk_pixbuf_get_n_channels(APixbuf);
    HasAlpha := gdk_pixbuf_get_has_alpha(APixbuf);
  end;

  ADesc.Init;
  ADesc.Width := cardinal(Width);
  ADesc.Height := cardinal(Height);
  ADesc.BitOrder := riboBitsInOrder;

  if HasAlpha then
  begin
    // always give pixbuf description for alpha images
    ADesc.Format:=ricfRGBA;
    ADesc.Depth := 32;
    ADesc.BitsPerPixel := 32;
    ADesc.LineEnd := rileDWordBoundary;
    ADesc.ByteOrder := riboLSBFirst;

    ADesc.RedPrec := 8;
    ADesc.RedShift := 0;
    ADesc.GreenPrec := 8;
    ADesc.GreenShift := 8;
    ADesc.BluePrec := 8;
    ADesc.BlueShift := 16;
    ADesc.AlphaPrec := 8;
    ADesc.AlphaShift := 24;

    ADesc.MaskBitsPerPixel := 0;
    ADesc.MaskShift := 0;
    ADesc.MaskLineEnd := rileByteBoundary;
    ADesc.MaskBitOrder := riboBitsInOrder;
  end else
  begin
    ADesc.Depth := Depth;
    ADesc.BitsPerPixel := 32;
    ADesc.LineEnd := rileDWordBoundary;
    ADesc.ByteOrder := riboLSBFirst;
    ADesc.MaskBitsPerPixel := 0;
    ADesc.MaskShift := 0;
    ADesc.MaskLineEnd := rileByteBoundary;
    ADesc.MaskBitOrder := riboBitsInOrder;

    ADesc.RedPrec := 8;
    ADesc.RedShift := 0;
    ADesc.GreenPrec := 8;
    ADesc.GreenShift := 8;
    ADesc.BluePrec := 8;
    ADesc.BlueShift := 16;
    ADesc.AlphaPrec := 0;
    ADesc.AlphaShift := 24;
  end;

  Result := True;
end;


function RawImage_DescriptionFromDrawable(out
  ADesc: TRawImageDescription; ADrawable: PGdkPixbuf; ACustomAlpha: Boolean
  ): boolean;
var
  Visual: PGdkVisual;
  Image: PGdkPixbuf;
  Width, Height: integer;
  IsBitmap: Boolean;
  AMask: guint32;
  AShift: gint;
  APrecision: gint;
begin
  Visual := nil;
  Width := 0;
  Height := 0;

  if ADrawable = nil then
  begin
    { GTK4: gdk_visual_get_system removed. Return a standard 32-bit ARGB description. }
    IsBitmap := False;

    ADesc.Init;
    ADesc.Width := 0;
    ADesc.Height := 0;
    ADesc.BitOrder := riboBitsInOrder;

    if ACustomAlpha then
    begin
      ADesc.Format := ricfRGBA;
      ADesc.Depth := 32;
      ADesc.BitsPerPixel := 32;
      ADesc.LineEnd := rileDWordBoundary;
      ADesc.ByteOrder := riboLSBFirst;
      ADesc.RedPrec := 8;  ADesc.RedShift := 0;
      ADesc.GreenPrec := 8;  ADesc.GreenShift := 8;
      ADesc.BluePrec := 8;  ADesc.BlueShift := 16;
      ADesc.AlphaPrec := 8;  ADesc.AlphaShift := 24;
      ADesc.MaskBitsPerPixel := 1;
      ADesc.MaskShift := 0;
      ADesc.MaskLineEnd := rileByteBoundary;
      ADesc.MaskBitOrder := riboBitsInOrder;
    end else
    begin
      ADesc.Format := ricfRGBA;
      ADesc.Depth := 24;
      ADesc.BitsPerPixel := 32;
      ADesc.LineEnd := rileDWordBoundary;
      ADesc.ByteOrder := riboLSBFirst;
      ADesc.LineOrder := riloTopToBottom;
      ADesc.RedPrec := 8;  ADesc.RedShift := 16;
      ADesc.GreenPrec := 8;  ADesc.GreenShift := 8;
      ADesc.BluePrec := 8;  ADesc.BlueShift := 0;
      ADesc.MaskBitsPerPixel := 1;
      ADesc.MaskShift := 0;
      ADesc.MaskLineEnd := rileByteBoundary;
      ADesc.MaskBitOrder := riboBitsInOrder;
    end;

    Exit(True);
  end else
  begin
    { GTK4: GdkDrawable removed. This path is not reached. }
  end;

  if (Visual = nil) and not IsBitmap then
  begin
    DebugLn('TGtk4WidgetSet.RawImage_DescriptionFromDrawable: visual failed');
    Exit(False);
  end;

  ADesc.Init;
  ADesc.Width := cardinal(Width);
  ADesc.Height := cardinal(Height);
  ADesc.BitOrder := riboBitsInOrder;

  if ACustomAlpha then
  begin
    // always give pixbuf description for alpha images
    ADesc.Format:=ricfRGBA;
    ADesc.Depth := 32;
    ADesc.BitsPerPixel := 32;
    ADesc.LineEnd := rileDWordBoundary;
    ADesc.ByteOrder := riboLSBFirst;

    ADesc.RedPrec := 8;
    ADesc.RedShift := 0;
    ADesc.GreenPrec := 8;
    ADesc.GreenShift := 8;
    ADesc.BluePrec := 8;
    ADesc.BlueShift := 16;
    ADesc.AlphaPrec := 8;
    ADesc.AlphaShift := 24;

    ADesc.MaskBitsPerPixel := 1;
    ADesc.MaskShift := 0;
    ADesc.MaskLineEnd := rileByteBoundary;
    ADesc.MaskBitOrder := riboBitsInOrder;

    Exit(True);
  end;

  // Format
  if IsBitmap then
  begin
    ADesc.Format := ricfGray;
  end else
  begin
    case Visual^.get_visual_type of
      GDK_VISUAL_STATIC_GRAY {0} :  ADesc.Format:=ricfGray;
      GDK_VISUAL_GRAYSCALE {1} :    ADesc.Format:=ricfGray;
      GDK_VISUAL_STATIC_COLOR {2} : ADesc.Format:=ricfGray; // this is not really gray, but an index in a color map, but colormaps are not supported yet, so use gray
      GDK_VISUAL_PSEUDO_COLOR {3} : ADesc.Format:=ricfGray;
      GDK_VISUAL_TRUE_COLOR {4} :   ADesc.Format:=ricfRGBA;
      GDK_VISUAL_DIRECT_COLOR {5} : ADesc.Format:=ricfRGBA;
    else
      DebugLn('TGtk4WidgetSet.GetWindowRawImageDescription unknown Visual type ',
              dbgs(Integer(Visual^.get_visual_type)));
      Exit(False);
    end;
  end;

  // Palette
  if not IsBitmap and
    (Visual^.get_visual_type in [GDK_VISUAL_GRAYSCALE,
       GDK_VISUAL_STATIC_COLOR,GDK_VISUAL_PSEUDO_COLOR]) then
  begin
    // has palette
    // ToDo
    ADesc.PaletteColorCount:=0;
  end;

  // Depth
  if IsBitmap then
    ADesc.Depth := 1
  else
    ADesc.Depth := Visual^.get_depth;

  if IsBitmap or (Visual^.get_byte_order = GDK_MSB_FIRST) then
    ADesc.ByteOrder := riboMSBFirst
  else
    ADesc.ByteOrder := riboLSBFirst;

  ADesc.LineOrder := riloTopToBottom;

  case ADesc.Depth of
    0..8:   ADesc.BitsPerPixel := ADesc.Depth;
    9..16:  ADesc.BitsPerPixel := 16;
    17..32: ADesc.BitsPerPixel := 32;
  else
    ADesc.BitsPerPixel := 64;
  end;

  if IsBitmap then
  begin
    ADesc.LineEnd  := rileByteBoundary;
    ADesc.RedPrec  := 1;
    ADesc.RedShift := 0;
  end else
  begin
    // Try retrieving the lineend
    Image := gdk_pixbuf_new(GDK_COLORSPACE_RGB, False, Visual^.get_bits_per_rgb, 1, 1);
    // gdk_image_new(GDK_IMAGE_NORMAL, Visual, 1, 1);
    if Image = nil then
    begin
      DebugLn('TGtk4WidgetSet.GetWindowRawImageDescription testimage creation failed ');
      Exit(False);
    end;
    try
      // the minimum alignment we can detect is bpp
      // that is no problem since a line consists of n x bytesperpixel bytes
      case Image^.get_bits_per_sample of
        1: ADesc.LineEnd := rileByteBoundary;
        2: ADesc.LineEnd := rileWordBoundary;
        4: ADesc.LineEnd := rileDWordBoundary;
        8: ADesc.LineEnd := rileQWordBoundary;
      else
        DebugLn('TGtk4WidgetSet.GetWindowRawImageDescription Unknown line end: %d', [Image^.get_bits_per_sample]);
        Exit(False);
      end;
    finally
      g_object_unref(Image);
      // gdk_image_destroy(Image);
      Image := nil;
    end;

    Visual^.get_red_pixel_details(@AMask, @AShift, @APrecision);
    ADesc.RedPrec := APrecision;
    ADesc.RedShift := AShift;
    Visual^.get_green_pixel_details(@AMask, @AShift, @APrecision);
    ADesc.GreenPrec := APrecision;
    ADesc.GreenShift := AShift;
    Visual^.get_blue_pixel_details(@AMask, @AShift, @APrecision);
    ADesc.BluePrec := APrecision;
    ADesc.BlueShift := AShift;

    ADesc.MaskBitsPerPixel := 1;
    ADesc.MaskShift := 0;
    ADesc.MaskLineEnd := rileByteBoundary;
    ADesc.MaskBitOrder := riboBitsInOrder;
  end;

  {$IFDEF VerboseRawImage}
  DebugLn('TGtk4WidgetSet.GetWindowRawImageDescription A ',ADesc.AsString);
  {$ENDIF}

  Result := True;
end;

{------------------------------------------------------------------------------
  Function: RawImage_QueryDescription
  Params: AFlags:
          ADesc:
  Returns:

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_QueryDescription(AFlags: TRawImageQueryFlags; var ADesc: TRawImageDescription): Boolean;
begin
  Result := inherited RawImage_QueryDescription(AFlags, ADesc);
  if ADesc.BitsPerPixel > 8 then
    ADesc.BitsPerPixel := 32
  else
  if ADesc.BitsPerPixel > 1 then
    ADesc.BitsPerPixel := 8;
  if (riqfMask in AFlags) then
    RawImage_DescriptionFromDrawable(ADesc, nil, riqfAlpha in AFlags);
end;

{------------------------------------------------------------------------------
  function TGtk4WidgetSet.GetRawImageFromBitmap(SrcBitmap, SrcMaskBitmap: HBITMAP;
    const SrcRect: TRect; var NewRawImage: TRawImage): boolean; override;
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_FromBitmap(out ARawImage: TRawImage; ABitmap, AMask: HBITMAP; ARect: PRect): Boolean;
var
  Desc: TRawImageDescription absolute ARawImage.Description;
  Image: TGtk4Image absolute ABitmap;
  Mask: TGtk4Image absolute AMask;

  WorkImage, WorkMask: TGtk4Image;
  R: TRect;
  Width, Height: Integer;
begin
  Result := false;

  if not CheckBitmap(ABitmap, 'RawImage_FromBitmap') then Exit;
  if (AMask <> 0) and not CheckBitmap(AMask, 'RawImage_FromBitmap (mask)') then Exit;

  ARawImage.Init;
  RawImage_DescriptionFromBitmap(ABitmap, Desc);

  if ARect = nil
  then begin
    Width := Image.Width;
    Height := Image.Height;
    R := Rect(0, 0, Width, Height)
  end
  else begin
    R := ARect^;
    Width := R.Right - R.Left;
    Height := R.Bottom - R.Top;
  end;

  WorkMask:=nil;

  if (Width = Image.Width) and (Height = Image.Height) then
  begin
    WorkImage := Image;
    WorkMask := Mask;
  end
  else begin
    WorkImage := TGtk4Image.Create;
    WorkImage.CopyFrom(Image.Handle, R.Left, R.Top, Width, Height);
    if Mask <> nil then
    begin
      WorkMask := TGtk4Image.Create;
      WorkMask.CopyFrom(Mask.Handle, R.Left, R.Top, Width, Height);
    end
    else
      WorkMask := nil;
  end;

  Desc.Width := WorkImage.width;
  Desc.Height := WorkImage.height;

  // copy data
  ARawImage.DataSize := WorkImage.numBytes;
  ReAllocMem(ARawImage.Data, ARawImage.DataSize);

  if ARawImage.DataSize > 0 then
    Move(WorkImage.bits^, ARawImage.Data^, ARawImage.DataSize);

  if WorkMask <> nil then
  begin
    Desc.MaskLineEnd := rileDWordBoundary;
    Desc.MaskBitOrder := riboReversedBits;
    Desc.MaskBitsPerPixel := 1;
    ARawImage.MaskSize := WorkMask.numBytes;
    ReAllocMem(ARawImage.Mask, ARawImage.MaskSize);
    if ARawImage.MaskSize > 0 then
    begin
      if (WorkMask.bits<>nil) and (ARawImage.Mask<>nil) then
        Move(WorkMask.bits^, ARawImage.Mask^, ARawImage.MaskSize);
    end;
  end;

  if WorkImage <> Image then
    WorkImage.Free;
  if WorkMask <> Mask then
    WorkMask.Free;

  Result := True;
end;

{------------------------------------------------------------------------------
  function TGtk4WidgetSet.GetRawImageFromDevice(SrcDC: HDC; const SrcRect: TRect;
    var NewRawImage: TRawImage): boolean;

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.RawImage_FromDevice(out ARawImage: TRawImage; ADC: HDC;
  const ARect: TRect): Boolean;
var
  Desc: TRawImageDescription absolute ARawImage.Description;
  DCSize: TSize;
  Pixmap: PGdkPixbuf;
  Context: TGtk4DeviceContext;

  procedure RawImage_FromImage(AImage: PGdkPixbuf);
  var
    pixels: Pguint8;
  begin
    ARawImage.DataSize := AImage^.get_byte_length;
    ARawImage.Data := GetMem(ARawImage.DataSize);
    Pixels := AImage^.get_pixels;
    Move(pixels^, ARawImage.Data^, ARawImage.DataSize);
    ARawImage.Mask := nil;
  end;

  { GTK4: Capture widget rendering via GtkWidgetPaintable + GskRenderNode.
    Renders to a cairo image surface (BGRA premultiplied), then converts to
    RGBA byte order matching FillStandardDescription. }
  function RawImage_FromWidget(AWidget: PGtkWidget; AWidth, AHeight: Integer): Boolean;
  var
    APaintable: PGdkPaintable;
    ASnapshot: PGtkSnapshot;
    ANode: PGskRenderNode;
    ASurface: Pcairo_surface_t;
    ACr: Pcairo_t;
    SrcData: PByte;
    DstData: PByte;
    AStride: Integer;
    Row, Col: Integer;
    SrcPixel, DstPixel: PByte;
  begin
    Result := False;
    if (AWidth <= 0) or (AHeight <= 0) then Exit;

    APaintable := gtk4_widget_paintable_new(AWidget);
    if APaintable = nil then Exit;
    try
      ASnapshot := gtk4_snapshot_new;
      gdk4_paintable_snapshot(APaintable, ASnapshot, AWidth, AHeight);
      ANode := gtk4_snapshot_free_to_node(ASnapshot);
      { ASnapshot consumed by free_to_node }
      if ANode = nil then Exit;
      try
        ASurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, AWidth, AHeight);
        ACr := cairo_create(ASurface);
        gsk4_render_node_draw(ANode, ACr);
        cairo_destroy(ACr);

        cairo_surface_flush(ASurface);
        SrcData := PByte(cairo_image_surface_get_data(ASurface));
        AStride := cairo_image_surface_get_stride(ASurface);

        ARawImage.DataSize := AWidth * AHeight * 4;
        ARawImage.Data := GetMem(ARawImage.DataSize);
        DstData := PByte(ARawImage.Data);
        ARawImage.Mask := nil;

        { Convert cairo ARGB32 (little-endian: B,G,R,A) to LCL RGBA (R,G,B,A) }
        for Row := 0 to AHeight - 1 do
        begin
          SrcPixel := SrcData + Row * AStride;
          DstPixel := DstData + Row * AWidth * 4;
          for Col := 0 to AWidth - 1 do
          begin
            DstPixel[0] := SrcPixel[2]; { R }
            DstPixel[1] := SrcPixel[1]; { G }
            DstPixel[2] := SrcPixel[0]; { B }
            DstPixel[3] := SrcPixel[3]; { A }
            Inc(SrcPixel, 4);
            Inc(DstPixel, 4);
          end;
        end;

        cairo_surface_destroy(ASurface);
        Result := True;
      finally
        gsk4_render_node_unref(ANode);
      end;
    finally
      g_object_unref(PGObject(APaintable));
    end;
  end;

begin
  Result := True;

  if not IsValidDC(ADC) then
  begin
    DebugLn('WARNING: TGtk4WidgetSet.GetRawImageFromDevice invalid SrcDC');
    Exit(False);
  end;

  ARawImage.Init;
  FillStandardDescription(ARawImage.Description);

  Context := TGtk4DeviceContext(ADC);

  with DCSize, Context.getDeviceSize do
  begin
    cx := x;
    cy := y;
  end;

  if Context.Parent <> nil then
  begin
    { GTK4: Use snapshot API to capture widget rendering }
    if not RawImage_FromWidget(Context.Parent, DCSize.cx, DCSize.cy) then
      Result := False;
  end else
  begin
    if Context.ParentPixmap <> nil then
    begin
      Pixmap := gdk_pixbuf_copy(Context.ParentPixmap);
      if Pixmap <> nil then
      begin
        RawImage_FromImage(Pixmap);
        g_object_unref(Pixmap);
      end;
    end else
      Result := False;
  end;

  // In this case we use the size of the context
  Desc.Width := DCSize.cx;
  Desc.Height := DCSize.cy;

  {$ifdef VerboseGtk4WinApi}
  DebugLn('Trace:< [WinAPI GetRawImageFromDevice]');
  {$endif}

end;

{------------------------------------------------------------------------------
  Function: GetControlConstraints
  Params: Constraints: TObject
  Returns: true on success

  Updates the constraints object (e.g. TSizeConstraints) with interface specific
  bounds.
 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.GetControlConstraints(Constraints: TObject): boolean;
var
  SizeConstraints: TSizeConstraints absolute Constraints;
  Widget: PGtkWidget;
  MinWidth: Integer;
  MinHeight: Integer;
  MaxWidth: Integer;
  MaxHeight: Integer;
  aPageControl: TPageControl;
begin
  Result := True;

  if Constraints is TSizeConstraints then
  begin
    if (SizeConstraints.Control=nil) then exit;
    MinWidth := 1;
    MinHeight := 1;
    MaxWidth := 0;
    MaxHeight := 0;

    if SizeConstraints.Control is TScrollBar then begin
      // TScrollBar
      if TScrollBar(SizeConstraints.Control).Kind=sbHorizontal then begin
        Widget:=GetStyleWidget(lgsHorizontalScrollbar);
        { GTK4: get_preferred_height/width removed. Use gtk_widget_measure. }
        gtk4_widget_measure(widget, GTK_ORIENTATION_VERTICAL, -1, @MinHeight, @MaxHeight, nil, nil);
      end else begin
        Widget:=GetStyleWidget(lgsVerticalScrollbar);
        gtk4_widget_measure(widget, GTK_ORIENTATION_HORIZONTAL, -1, @MinWidth, @MaxWidth, nil, nil);
      end;
    end else if SizeConstraints.Control is TPageControl then begin
      aPageControl:=TPageControl(SizeConstraints.Control);
      if aPageControl.TabPosition in [tpTop, tpBottom] then begin
        MinHeight:=20;
      end else begin
        MinWidth:=20;
      end;
    end;


    SizeConstraints.SetInterfaceConstraints(MinWidth,MinHeight,
                                            MaxWidth,MaxHeight);
  end;
end;

{------------------------------------------------------------------------------
  function TGtk4WidgetSet.GetLCLOwnerObject(Handle: HWnd): TObject;

 ------------------------------------------------------------------------------}
function TGtk4WidgetSet.GetLCLOwnerObject(Handle: HWnd): TObject;
begin
  if Handle<>0 then
    Result := TGtk4Widget(Handle).LCLObject
  else
    Result := nil;
end;

function TGtk4WidgetSet.AskUser(const DialogCaption, DialogMessage: string; DialogType:
   LongInt; Buttons: TDialogButtons; HelpCtx: Longint): LongInt;
var
  fact:TGtk4DialogFactory;
begin
  fact:=TGtk4DialogFactory.CreateAsk(DialogCaption,DialogMessage,DialogType,Buttons,HelpCtx);
  try
    fact.run;
    Result := fact.lcl_result;
  finally
    fact.Free;
  end;
end;

function TGtk4WidgetSet.PromptUser(const DialogCaption: string;
  const DialogMessage: string; DialogType: LongInt; Buttons: PLongInt;
  ButtonCount: LongInt; DefaultIndex: LongInt; EscapeResult: LongInt): LongInt;
var
  fact:TGtk4DialogFactory;
begin
  fact:=TGtk4DialogFactory.CreatePrompt(DialogCaption,DialogMessage,
     DialogType,Buttons,ButtonCount,DefaultIndex,EscapeResult);
  try
    fact.run;
    Result:=fact.btn_result;
  finally
    fact.Free;
  end;
end;


function TGtk4WidgetSet.SetComboMinDropDownSize(Handle: HWND; MinItemsWidth,
  MinItemsHeight, MinItemCount: integer): boolean;
var
  p: PGtkWidget;
begin
  Result := True;
  p := TGtk4Widget(Handle).Widget;
  if (p <> nil) and
    g_type_check_instance_is_a(PGTypeInstance(p), gtk_combo_box_get_type) then
  begin
    { GTK4: The popup/dropdown is internal to GtkComboBox and not directly
      accessible. We can influence sizing by:
      1. Setting the widget's own minimum width (popup matches combo width)
      2. Disabling popup_fixed_width so popup can be wider than the combo }
    if MinItemsWidth > 0 then
    begin
      gtk_widget_set_size_request(p, MinItemsWidth, -1);
      PGtkComboBox(p)^.set_popup_fixed_width(False);
    end;
  end;
end;


//##apiwiz##eps##   // Do not remove, no wizard declaration after this line


function waithandle_iocallback({%H-}source: PGIOChannel; condition: TGIOCondition;
  data: gpointer): gboolean; cdecl;
var
  lEventHandler: PWaitHandleEventHandler absolute data;
begin
  lEventHandler^.OnEvent(lEventHandler^.UserData, dword(condition));
  Result := true;
end;

function TGtk4WidgetSet.AddEventHandler(AHandle: TLCLHandle; AFlags: dword;
  AEventHandler: TWaitHandleEvent; AData: PtrInt): PEventHandler;
var
  giochannel: PGIOChannel;
  lEventHandler: PWaitHandleEventHandler;
begin
  Result := nil;
  if AEventHandler = nil then exit;
  New(lEventHandler);
  giochannel := g_io_channel_unix_new(AHandle);
  lEventHandler^.Handle := AHandle;
  lEventHandler^.UserData := AData;
  lEventHandler^.GIOChannel := giochannel;
  lEventHandler^.OnEvent := AEventHandler;
  lEventHandler^.GSourceID := g_io_add_watch(giochannel,
    TGIOCondition(AFlags), @waithandle_iocallback, lEventHandler);
  lEventHandler^.PrevHandler := nil;
  lEventHandler^.NextHandler := FWaitHandles;
  if FWaitHandles <> nil then
    FWaitHandles^.PrevHandler := lEventHandler;
  FWaitHandles := lEventHandler;
  Result := lEventHandler;
end;


procedure TGtk4WidgetSet.RemoveEventHandler(var AHandler: PEventHandler);
var
  lEventHandler: PWaitHandleEventHandler absolute AHandler;
begin
  if AHandler = nil then exit;
  g_source_remove(lEventHandler^.GSourceID);
  { channel will be freed when ref count drops to 0 }
  g_io_channel_unref(lEventHandler^.GIOChannel);
  if lEventHandler^.PrevHandler = nil then
    FWaitHandles := lEventHandler^.NextHandler
  else
    lEventHandler^.PrevHandler^.NextHandler := lEventHandler^.NextHandler;
  if lEventHandler^.NextHandler <> nil then
    lEventHandler^.NextHandler^.PrevHandler := lEventHandler^.PrevHandler;
  Dispose(lEventHandler);
  AHandler := nil;
end;

procedure TGtk4WidgetSet.SetEventHandlerFlags(AHandler: PEventHandler; NewFlags: dword);
var
  lEventHandler: PWaitHandleEventHandler absolute AHandler;
begin
  if AHandler = nil then exit;
  g_source_remove(lEventHandler^.GSourceID);
  lEventHandler^.GSourceID := g_io_add_watch(lEventHandler^.GIOChannel,
    TGIOCondition(NewFlags), @waithandle_iocallback, lEventHandler);
end;

procedure TGtk4WidgetSet.SetRubberBandRect(const ARubberBand: HWND; const ARect: TRect);
var
  dx, dy: Integer;
begin
  if ARubberBand = 0 then Exit;
  dx := ARect.Right - ARect.Left;
  dy := ARect.Bottom - ARect.Top;
  if dx < 0 then dx := 0;
  if dy < 0 then dy := 0;
  { GTK4/Wayland: Cannot position windows arbitrarily.
    We can only resize the rubber band window. }
  gtk_window_set_default_size({%H-}PGtkWindow(ARubberBand), dx, dy);
end;

type
  PPipeEventInfo = ^TPipeEventInfo;
  TPipeEventInfo = record
    Handler: PEventHandler;
    UserData: PtrInt;
    OnEvent: TPipeEvent;
  end;

function TGtk4WidgetSet.AddPipeEventHandler(AHandle: TLCLHandle;
  AEventHandler: TPipeEvent; AData: PtrInt): PPipeEventHandler;
var
  lPipeEventInfo: PPipeEventInfo;
begin
  Result := nil;
  if AEventHandler = nil then exit;
  New(lPipeEventInfo);
  lPipeEventInfo^.UserData := AData;
  lPipeEventInfo^.OnEvent := AEventHandler;
  lPipeEventInfo^.Handler := AddEventHandler(AHandle,
    dword([G_IO_IN, G_IO_HUP, G_IO_OUT]),
    @HandlePipeEvent, {%H-}PtrInt(lPipeEventInfo));
  Result := lPipeEventInfo;
end;

procedure TGtk4WidgetSet.HandlePipeEvent(AData: PtrInt; AFlags: dword);
var
  lPipeEventInfo: PPipeEventInfo absolute AData;
  lReasons: TPipeReasons;
  ACond: TGIOCondition;
begin
  lReasons := [];
  ACond := TGIOCondition(AFlags);
  if G_IO_IN in ACond then
    Include(lReasons, prDataAvailable);
  if G_IO_OUT in ACond then
    Include(lReasons, prCanWrite);
  if G_IO_HUP in ACond then
    Include(lReasons, prBroken);

  lPipeEventInfo^.OnEvent(lPipeEventInfo^.UserData, lReasons);
end;

procedure TGtk4WidgetSet.RemovePipeEventHandler(var AHandler: PPipeEventHandler);
var
  lPipeEventInfo: PPipeEventInfo absolute AHandler;
begin
  if AHandler = nil then exit;
  RemoveEventHandler(lPipeEventInfo^.Handler);
  Dispose(lPipeEventInfo);
  AHandler := nil;
end;

{$ifdef UNIX}
function TGtk4WidgetSet.AddProcessEventHandler(AHandle: TLCLHandle;
  AEventHandler: TChildExitEvent; AData: PtrInt): PProcessEventHandler;
var
  lHandler: PChildSignalEventHandler;
begin
  Result := nil;
  if AEventHandler = nil then exit(nil);
  New(lHandler);
  lHandler^.PID := TPid(AHandle);
  lHandler^.UserData := AData;
  lHandler^.OnEvent := AEventHandler;
  lHandler^.PrevHandler := nil;
  lHandler^.NextHandler := FChildSignalHandlers;
  if FChildSignalHandlers <> nil then
    FChildSignalHandlers^.PrevHandler := lHandler;
  FChildSignalHandlers := lHandler;
  Result := lHandler;
end;

procedure TGtk4WidgetSet.RemoveProcessEventHandler(var AHandler: PProcessEventHandler);
var
  lHandler: PChildSignalEventHandler absolute AHandler;
begin
  if AHandler = nil then exit;
  if lHandler^.PrevHandler = nil then
    FChildSignalHandlers := lHandler^.NextHandler
  else
    lHandler^.PrevHandler^.NextHandler := lHandler^.NextHandler;
  if lHandler^.NextHandler <> nil then
    lHandler^.NextHandler^.PrevHandler := lHandler^.PrevHandler;
  Dispose(lHandler);
  AHandler := nil;
end;
{$else}
{$IFDEF VerboseGtkToDos}{$warning TGtk4WidgetSet.RemoveProcessEventHandler and TGtk4WidgetSet.AddProcessEventHandler not implemented on this OS}{$ENDIF}
//PChildSignalEventHandler is only defined on unix
function TGtk4WidgetSet.AddProcessEventHandler(AHandle: THandle;
  AEventHandler: TChildExitEvent; AData: PtrInt): PProcessEventHandler;
begin
  Result := nil;
end;

procedure TGtk4WidgetSet.RemoveProcessEventHandler(var AHandler: PProcessEventHandler);
begin
end;
{$endif}
