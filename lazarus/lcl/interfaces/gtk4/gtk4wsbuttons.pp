{
 *****************************************************************************
 *                               Gtk4WSButtons.pp                            *
 *                               ------------                                * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSButtons;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Classes, Controls, Buttons, Graphics,
////////////////////////////////////////////////////
  WSLCLClasses, WSButtons, WSProc,
  LCLType, LCLIntf, LCLProc,
  gtk4widgets, LazGtk4, LazGObject2, LazGdkPixbuf2;

type

  { TGtk4WSBitBtn }

  TGtk4WSBitBtn = class(TWSBitBtn)
  private
    class procedure RebuildButtonChild(const ABitBtn: TCustomBitBtn);
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class procedure SetGlyph(const ABitBtn: TCustomBitBtn; const AValue: TButtonGlyph); override;
    class procedure SetLayout(const ABitBtn: TCustomBitBtn; const AValue: TButtonLayout); override;
    class procedure SetMargin(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
    class procedure SetSpacing(const ABitBtn: TCustomBitBtn; const AValue: Integer); override;
  end;
  TGtk4WSBitBtnClass = class of TGtk4WSBitBtn;

  { TGtk4WSSpeedButton }

  TGtk4WSSpeedButton = class(TWSSpeedButton)
  private
  protected
  public
  end;

implementation

uses
  graphtype,imglist,LResources, LazGtk4_Compat, LazGLib2, gtk4objects, gtk4procs;


{ TGtk4WSCustomBitBtn }

class function TGtk4WSBitBtn.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  ABitBtn: TGtk4Button;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.CreateHandle');
  {$ENDIF}
  ABitBtn := TGtk4Button.Create(AWinControl, AParams);
{  with ARect do
  begin
    x := AWinControl.Left;
    y := AWinControl.Top;
    width := AWinControl.Width;
    height := AWinControl.Height;
  end;

  ABitBtn.Widget^.set_allocation(@ARect);}

  Result := TLCLHandle(ABitBtn);
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.CreateHandle Handle=',dbgs(Result));
  {$ENDIF}
end;

class procedure TGtk4WSBitBtn.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4Button(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class procedure TGtk4WSBitBtn.SetGlyph(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonGlyph);
var
  AImage: PGtkWidget;
  AGlyph: TBitmap;
  APixbuf: PGdkPixbuf;
  ABox: PGtkBox;
  ALabel: PGtkLabel;
  ABtn: TGtk4Button;
  Orientation: TGtkOrientation;
  resolution: TCustomImageListResolution;
  ScaleFactor: Double;
  raw: TRawImage;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.SetGlyph');
  {$ENDIF}
  if not WSCheckHandleAllocated(ABitBtn, 'SetGlyph') then
    Exit;
  ABtn := TGtk4Button(ABitBtn.Handle);
  if ABitBtn.CanShowGlyph(True) then
  begin
    { allocate image which would be cached in TGtk4Button instance }
    AGlyph := TBitmap.Create;
    ScaleFactor := ABitBtn.GetCanvasScaleFactor;
    if (ABitBtn.ImageIndex >= 0) and Assigned(ABitBtn.Images) then
    begin
      resolution := ABitBtn.Images.Resolution[round(ABitBtn.Images.Width * ScaleFactor)];
      resolution.GetRawImage(ABitBtn.ImageIndex, raw);
      AGlyph.BeginUpdate();
      AGlyph.LoadFromRawImage(raw, false);
      AGlyph.EndUpdate();
    end else
    begin
      AGlyph.BeginUpdate();
      AGlyph.LoadFromRawImage(AValue.Glyph.RawImage, false);
      AGlyph.EndUpdate();
    end;

    APixbuf := Gtk4BitmapToPixbuf(AGlyph);
    if APixbuf <> nil then
    begin
      AImage := PGtkWidget(gtk_image_new_from_pixbuf(APixbuf));
      g_object_unref(APixbuf);
    end else
      AImage := nil;

    if Assigned(AImage) then
    begin
      { GTK4: gtk_button_set_image removed. Build a Box with image + label. }
      case TButtonLayout(ABtn.Layout) of
        blGlyphLeft, blGlyphRight:
          Orientation := GTK_ORIENTATION_HORIZONTAL;
      else
        Orientation := GTK_ORIENTATION_VERTICAL;
      end;
      ABox := PGtkBox(TGtkBox.new(Orientation, ABtn.Spacing));

      { Create label preserving button text and underline support }
      ALabel := TGtkLabel.new(
        PgChar(ReplaceAmpersandsWithUnderscores(ABitBtn.Caption)));
      ALabel^.set_use_underline(True);

      { Pack in correct order based on layout }
      case TButtonLayout(ABtn.Layout) of
        blGlyphLeft, blGlyphTop:
        begin
          gtk4_box_append(ABox, AImage);
          gtk4_box_append(ABox, PGtkWidget(ALabel));
        end;
        blGlyphRight, blGlyphBottom:
        begin
          gtk4_box_append(ABox, PGtkWidget(ALabel));
          gtk4_box_append(ABox, AImage);
        end;
      end;

      gtk4_button_set_child(PGtkButton(ABtn.Widget), PGtkWidget(ABox));
    end;

    { store glyph to prevent leaks }
    ABtn.Image := AGlyph;
  end
  else
  begin
    { No glyph — restore text-only label }
    PGtkButton(ABtn.Widget)^.set_label(
      PgChar(ReplaceAmpersandsWithUnderscores(ABitBtn.Caption)));
    PGtkButton(ABtn.Widget)^.set_use_underline(True);
    ABtn.Image := nil;
  end;
end;

{ Helper: Rebuild the button's Box child widget from the stored Image bitmap.
  Called after Layout/Margin/Spacing changes to update the visual layout. }
class procedure TGtk4WSBitBtn.RebuildButtonChild(const ABitBtn: TCustomBitBtn);
var
  ABtn: TGtk4Button;
  AImage: PGtkWidget;
  APixbuf: PGdkPixbuf;
  ABox: PGtkBox;
  ALabel: PGtkLabel;
  Orientation: TGtkOrientation;
begin
  ABtn := TGtk4Button(ABitBtn.Handle);
  if ABtn.Image = nil then Exit; { no glyph — nothing to rebuild }

  APixbuf := Gtk4BitmapToPixbuf(ABtn.Image);
  if APixbuf = nil then Exit;

  AImage := PGtkWidget(gtk_image_new_from_pixbuf(APixbuf));
  g_object_unref(APixbuf);
  if AImage = nil then Exit;

  case TButtonLayout(ABtn.Layout) of
    blGlyphLeft, blGlyphRight:
      Orientation := GTK_ORIENTATION_HORIZONTAL;
  else
    Orientation := GTK_ORIENTATION_VERTICAL;
  end;
  ABox := PGtkBox(TGtkBox.new(Orientation, ABtn.Spacing));

  ALabel := TGtkLabel.new(
    PgChar(ReplaceAmpersandsWithUnderscores(ABitBtn.Caption)));
  ALabel^.set_use_underline(True);

  case TButtonLayout(ABtn.Layout) of
    blGlyphLeft, blGlyphTop:
    begin
      gtk4_box_append(ABox, AImage);
      gtk4_box_append(ABox, PGtkWidget(ALabel));
    end;
    blGlyphRight, blGlyphBottom:
    begin
      gtk4_box_append(ABox, PGtkWidget(ALabel));
      gtk4_box_append(ABox, AImage);
    end;
  end;

  gtk4_button_set_child(PGtkButton(ABtn.Widget), PGtkWidget(ABox));
end;

class procedure TGtk4WSBitBtn.SetLayout(const ABitBtn: TCustomBitBtn;
  const AValue: TButtonLayout);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.SetLayout');
  {$ENDIF}
  if not WSCheckHandleAllocated(ABitBtn, 'SetLayout') then
    Exit;
  TGtk4Button(ABitBtn.Handle).Layout := Ord(AValue);
  RebuildButtonChild(ABitBtn);
end;

class procedure TGtk4WSBitBtn.SetMargin(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.SetMargin');
  {$ENDIF}
  if not WSCheckHandleAllocated(ABitBtn, 'SetMargin') then
    Exit;
  TGtk4Button(ABitBtn.Handle).Margin := AValue;
  RebuildButtonChild(ABitBtn);
end;

class procedure TGtk4WSBitBtn.SetSpacing(const ABitBtn: TCustomBitBtn;
  const AValue: Integer);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSBitBtn.SetSpacing');
  {$ENDIF}
  if not WSCheckHandleAllocated(ABitBtn, 'SetSpacing') then
    Exit;
  TGtk4Button(ABitBtn.Handle).Spacing := AValue;
  RebuildButtonChild(ABitBtn);
end;

end.
