{
 *****************************************************************************
 *                               WSControls.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSControls;

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
  Classes,
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Controls, Graphics, LCLType, Types, LCLProc,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, WSProc, LazGtk4, LazGlib2, LazGObject2,
  gtk4widgets, LazCairo1, LazGsk4, LazGtk4_Compat,
  InterfaceBase, gtk4procs;

type

  { TGtk4WSLazAccessibleObject }

  TGtk4WSLazAccessibleObject = class(TWSLazAccessibleObject)
  public
    class function CreateHandle(const AObject: TLazAccessibleObject): HWND; override;
    class procedure DestroyHandle(const AObject: TLazAccessibleObject); override;
    class procedure SetAccessibleName(const AObject: TLazAccessibleObject; const AName: string); override;
    class procedure SetAccessibleDescription(const AObject: TLazAccessibleObject; const ADescription: string); override;
    class procedure SetAccessibleValue(const AObject: TLazAccessibleObject; const AValue: string); override;
    class procedure SetAccessibleRole(const AObject: TLazAccessibleObject; const ARole: TLazAccessibilityRole); override;
    class procedure SetPosition(const AObject: TLazAccessibleObject; const AValue: TPoint); override;
    class procedure SetSize(const AObject: TLazAccessibleObject; const AValue: TSize); override;
  end;
  TGtk4WSLazAccessibleObjectClass = class of TGtk4WSLazAccessibleObject;

  { TGtk4WSDragImageListResolution }

  TGtk4WSDragImageListResolution = class(TWSDragImageListResolution)
  published
    class function BeginDrag(const ADragImageList: TDragImageListResolution; Window: HWND; AIndex, X, Y: Integer): Boolean; override;
    class function DragMove(const ADragImageList: TDragImageListResolution; X, Y: Integer): Boolean; override;
    class procedure EndDrag(const ADragImageList: TDragImageListResolution); override;
    class function HideDragImage(const ADragImageList: TDragImageListResolution;
      ALockedWindow: HWND; DoUnLock: Boolean): Boolean; override;
    class function ShowDragImage(const ADragImageList: TDragImageListResolution;
      ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean; override;
  end;

  TGtk4WSDragImageListResolutionClass = class of TGtk4WSDragImageListResolution;


  { TGtk4WSControl }

  TGtk4WSControl = class(TWSControl)
  end;

  TGtk4WSControlClass = class of TGtk4WSControl;


  { TGtk4WSWinControl }

  TGtk4WSWinControl = class(TWSWinControl)
  published
    class procedure AddControl(const AControl: TControl); override;
    class function  CanFocus(const AWincontrol: TWinControl): Boolean; override;
    
    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    class function  GetDefaultClientRect(const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer; var aClientRect: TRect): boolean; override;
    class function GetDesignInteractive(const AWinControl: TWinControl; AClientPos: TPoint): Boolean; override;
    class function  GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function  GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; override;

    class procedure SetBiDiMode(const AWinControl: TWinControl; UseRightToLeftAlign, UseRightToLeftReading, UseRightToLeftScrollBar : Boolean); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetChildZPosition(const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer; const AChildren: TFPList); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer); override;
    class procedure SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer); override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class procedure SetCursor(const AWinControl: TWinControl; const ACursor: HCursor); override;
    class procedure SetShape(const AWinControl: TWinControl; const AShape: HBITMAP); override;

    class procedure AdaptBounds(const AWinControl: TWinControl;
          var Left, Top, Width, Height: integer; var SuppressMove: boolean); override;

    class procedure ConstraintsChange(const AWinControl: TWinControl); override;
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class procedure DefaultWndHandler(const AWinControl: TWinControl; var AMessage); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
    class procedure Repaint(const AWinControl: TWinControl); override;
    class procedure PaintTo(const AWinControl: TWinControl; ADC: HDC; X, Y: Integer); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
    class procedure ScrollBy(const AWinControl: TWinControl; DeltaX, DeltaY: integer); override;
  end;
  TGtk4WSWinControlClass = class of TGtk4WSWinControl;


  { TGtk4WSCustomControl }

  TGtk4WSCustomControl = class(TGtk4WSWinControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
  end;


implementation
uses SysUtils, gtk4objects;

{ TGtk4WSLazAccessibleObject }

{ In GTK4, every widget IS a GtkAccessible. The widget handle serves as
  the accessible handle. We just need to set LABEL/DESCRIPTION properties
  and sync state flags. }

class function TGtk4WSLazAccessibleObject.CreateHandle(
  const AObject: TLazAccessibleObject): HWND;
var
  AWinControl: TWinControl;
begin
  { GTK4 widgets are already accessible — use the owning control's handle }
  AWinControl := AObject.FindOwnerWinControl;
  if (AWinControl <> nil) and AWinControl.HandleAllocated then
    Result := AWinControl.Handle
  else
    Result := 0;
end;

class procedure TGtk4WSLazAccessibleObject.DestroyHandle(
  const AObject: TLazAccessibleObject);
begin
  { Nothing to destroy — handle is the widget handle, owned by the control }
end;

class procedure TGtk4WSLazAccessibleObject.SetAccessibleName(
  const AObject: TLazAccessibleObject; const AName: string);
var
  AWidget: PGtkWidget;
  Props: TGtkAccessibleProperty;
  Val: TGValue;
begin
  if not AObject.HandleAllocated then Exit;
  AWidget := TGtk4Widget(AObject.Handle).Widget;
  if AWidget = nil then Exit;

  if AName = '' then
  begin
    gtk4_accessible_reset_property(AWidget, GTK_ACCESSIBLE_PROPERTY_LABEL);
    Exit;
  end;

  Props := GTK_ACCESSIBLE_PROPERTY_LABEL;
  FillChar(Val{%H-}, SizeOf(Val), 0);
  g_value_init(@Val, G_TYPE_STRING);
  g_value_set_string(@Val, PgChar(AName));
  gtk4_accessible_update_property_value(AWidget, 1, @Props, @Val);
  Val.unset;
end;

class procedure TGtk4WSLazAccessibleObject.SetAccessibleDescription(
  const AObject: TLazAccessibleObject; const ADescription: string);
var
  AWidget: PGtkWidget;
  Props: TGtkAccessibleProperty;
  Val: TGValue;
begin
  if not AObject.HandleAllocated then Exit;
  AWidget := TGtk4Widget(AObject.Handle).Widget;
  if AWidget = nil then Exit;

  if ADescription = '' then
  begin
    gtk4_accessible_reset_property(AWidget, GTK_ACCESSIBLE_PROPERTY_DESCRIPTION);
    Exit;
  end;

  Props := GTK_ACCESSIBLE_PROPERTY_DESCRIPTION;
  FillChar(Val{%H-}, SizeOf(Val), 0);
  g_value_init(@Val, G_TYPE_STRING);
  g_value_set_string(@Val, PgChar(ADescription));
  gtk4_accessible_update_property_value(AWidget, 1, @Props, @Val);
  Val.unset;
end;

class procedure TGtk4WSLazAccessibleObject.SetAccessibleValue(
  const AObject: TLazAccessibleObject; const AValue: string);
var
  AWidget: PGtkWidget;
  Props: TGtkAccessibleProperty;
  Val: TGValue;
begin
  if not AObject.HandleAllocated then Exit;
  AWidget := TGtk4Widget(AObject.Handle).Widget;
  if AWidget = nil then Exit;

  if AValue = '' then
  begin
    gtk4_accessible_reset_property(AWidget, GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT);
    Exit;
  end;

  Props := GTK_ACCESSIBLE_PROPERTY_VALUE_TEXT;
  FillChar(Val{%H-}, SizeOf(Val), 0);
  g_value_init(@Val, G_TYPE_STRING);
  g_value_set_string(@Val, PgChar(AValue));
  gtk4_accessible_update_property_value(AWidget, 1, @Props, @Val);
  Val.unset;
end;

class procedure TGtk4WSLazAccessibleObject.SetAccessibleRole(
  const AObject: TLazAccessibleObject; const ARole: TLazAccessibilityRole);
begin
  { GTK4: Widget roles are set at construction time and cannot be changed
    afterward. GTK4 widgets already have correct default roles
    (GtkButton→BUTTON, GtkEntry→TEXT_BOX, etc.). }
end;

class procedure TGtk4WSLazAccessibleObject.SetPosition(
  const AObject: TLazAccessibleObject; const AValue: TPoint);
begin
  { GTK4 handles position accessibility automatically from widget geometry }
end;

class procedure TGtk4WSLazAccessibleObject.SetSize(
  const AObject: TLazAccessibleObject; const AValue: TSize);
begin
  { GTK4 handles size accessibility automatically from widget geometry }
end;

{ TGtk4WSWinControl }

class procedure TGtk4WSWinControl.AdaptBounds(const AWinControl: TWinControl;
  var Left, Top, Width, Height: integer; var SuppressMove: boolean);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.AdaptBounds');
  {$ENDIF}
end;

class procedure TGtk4WSWinControl.ConstraintsChange(const AWinControl: TWinControl);
var
  AWidget: PGtkWidget;
  MW, MH: Integer;
  MaxW, MaxH: Integer;
  CurW, CurH: gint;
  MenuBarH: gint;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ConstraintsChange') then
    Exit;
  AWidget := TGtk4Widget(AWinControl.Handle).Widget;
  MW := AWinControl.Constraints.MinWidth;
  MH := AWinControl.Constraints.MinHeight;
  MaxW := AWinControl.Constraints.MaxWidth;
  MaxH := AWinControl.Constraints.MaxHeight;

  { GTK4: gtk_window_set_geometry_hints was removed. For windows, emulate
    max constraints: when MaxHeight=MinHeight>0 (fixed height, as used by
    TMainIDEBar), use set_size_request to enforce the height as minimum.
    ShowHide applies set_default_size BEFORE gtk_widget_show() so the
    window is mapped at the correct size initially. }
  if Gtk4IsGtkWindow(AWidget) then
  begin
    { GTK4: The menu bar is inside the client area (GtkBox child), but the
      LCL calculates constraints using CalcNonClientHeight which returns 0
      for GTK4. Compensate by adding the non-client overhead (menu bar +
      CSS margins/padding) to constraints.  GetNonClientOverhead uses the
      actual allocation difference when available, which is more accurate
      than measuring the menu bar alone. }
    MenuBarH := 0;
    if TGtk4Widget(AWinControl.Handle) is TGtk4Window then
      MenuBarH := TGtk4Window(AWinControl.Handle).GetNonClientOverhead;

    { set_size_request is the GTK MINIMUM. Feed it the real LCL Min only —
      Max is enforced independently by the notify::default-size snap-back
      (Gtk4WindowNotifyDefaultSizeCB) and by SetBounds clamping. Coercing
      Min:=Max here made every Max-only window unable to shrink below Max
      (LCL Width/Height changed but the native window stayed at Max, so LCL
      and native disagreed — runtime-confirmed). A genuinely fixed-size
      window (TMainIDEBar, fixed dialogs) sets Min=Max explicitly, so its
      minimum is unaffected.
      Both Min AND Max heights carry the menu-bar overhead: LCL Min/Max are
      CLIENT dimensions, but set_size_request/set_default_size are full
      GtkWindow (content incl. menu bar) — this matches gtk2/qt5/win32,
      which add the client->window height fix to both bounds. (The overhead
      is vertical only, so widths are untouched.) }
    if MH > 0 then
      MH := MH + MenuBarH;
    if MaxH > 0 then
      MaxH := MaxH + MenuBarH;
    if MW <= 0 then MW := -1;
    if MH <= 0 then MH := -1;
    AWidget^.set_size_request(MW, MH);
    { set_default_size: for unconstrained dimensions, preserve the current
      window size instead of passing -1 (which resets to natural size and
      would fight user-initiated horizontal resize).
      Wrap in BeginUpdate/EndUpdate to suppress LM_SIZE delivery — this is
      a programmatic change, not a user-initiated resize. }
    PGtkWindow(AWidget)^.get_default_size(@CurW, @CurH);
    if MaxW <= 0 then
    begin
      if CurW > 0 then MaxW := CurW else MaxW := -1;
    end;
    if MaxH <= 0 then
    begin
      if CurH > 0 then MaxH := CurH else MaxH := -1;
    end;
    TGtk4Widget(AWinControl.Handle).BeginUpdate;
    try
      PGtkWindow(AWidget)^.set_default_size(MaxW, MaxH);
    finally
      TGtk4Widget(AWinControl.Handle).EndUpdate;
    end;

    { GTK4: Enforce max constraints solely via the notify::default-height/
      width snap-back in Gtk4WindowNotifyDefaultSizeCB.  WM_NORMAL_HINTS
      PMaxSize is not used — GTK4 rewrites the hints every layout pass and
      fighting it causes WM frame flicker (see Gtk4WindowAfterPaintCB). }
    if TGtk4Widget(AWinControl.Handle) is TGtk4Window then
    begin
      if AWinControl.Constraints.MaxHeight > 0 then
        CurH := AWinControl.Constraints.MaxHeight + MenuBarH
      else
        CurH := 0;
      TGtk4Window(AWinControl.Handle).SetMaxSize(
        AWinControl.Constraints.MaxWidth, CurH);
    end;
  end
  else
  begin
    { Non-window widgets: preserve existing size_request when no constraint. }
    AWidget^.get_size_request(@CurW, @CurH);
    if MW <= 0 then MW := CurW;
    if MH <= 0 then MH := CurH;
    AWidget^.set_size_request(MW, MH);
  end;
end;

class function TGtk4WSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  { Generic TWinControl handle: creates a TGtk4Panel (GtkOverlay + GtkFixed)
    which supports child controls and custom painting. Specific WS classes
    (TGtk4WSCustomPanel, TGtk4WSCustomForm, etc.) override with their own
    wrapper types. }
  Result := TLCLHandle(TGtk4Panel.Create(AWinControl, AParams));
end;

class procedure TGtk4WSWinControl.DestroyHandle(const AWinControl: TWinControl);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.DestroyHandle ',dbgsName(AWinControl),' handle ',dbgs(AWinControl.HandleAllocated));
  {$ENDIF}
  if AWinControl.HandleAllocated then
  begin
    TGtk4Widget(AWinControl.Handle).Free;
  end;
end;

class procedure TGtk4WSWinControl.DefaultWndHandler(const AWinControl: TWinControl; var AMessage);
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.DefaultWndHandler');
  {$ENDIF}
end;

class procedure TGtk4WSWinControl.AddControl(const AControl: TControl);
var
  AHandle: TGtk4Widget;
  AParent: TWinControl;
begin
  if not WSCheckHandleAllocated(TWinControl(AControl), 'AddControl') then
    Exit;
  AParent := TWinControl(AControl).Parent;
  AHandle := TGtk4Widget(AParent.Handle);

  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGSIZE) OR DEFINED(GTK4DEBUGREPARENTING)}
  DebugLn('TGtk4WSWinControl.AddControl ',dbgsName(AControl),' LEFT=',dbgs(AControl.Left),' TOP=',dbgs(AControl.Top),
    ' PARENT=',dbgsName(AParent));
  {$ENDIF}

  // better use this, since it sets position imediatelly if its child of container
  // so, reduce flickering.
  TGtk4Widget(TWinControl(AControl).Handle).SetParent(AHandle, AControl.Left, AControl.Top);
end;

class function TGtk4WSWinControl.CanFocus(const AWincontrol: TWinControl): Boolean;
begin
  // lets consider that by deafult all WinControls can be focused
  Result := False;
  if AWinControl.HandleAllocated then
    Result := TGtk4Widget(AWinControl.Handle).CanFocus;
  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGFOCUS)}
  DebugLn('TGtk4WSWinControl.CanFocus ',dbgsName(AWinControl),' result ',dbgs(Result));
  {$ENDIF}
end;

class function TGtk4WSWinControl.GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('TGtk4WSWinControl.GetClientBounds ',dbgsName(AWinControl));
  {$ENDIF}
  Result := False;
  if AWinControl.HandleAllocated then
  begin
    ARect := TGtk4Widget(AWinControl.Handle).getClientBounds;
    Result := True;
  end else
    ARect := Rect(0, 0, 0, 0);
end;

class function TGtk4WSWinControl.GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('TGtk4WSWinControl.GetClientRect ',dbgsName(AWinControl));
  {$ENDIF}
  Result := False;
  if AWinControl.HandleAllocated then
  begin
    ARect := TGtk4Widget(AWinControl.Handle).getClientRect;
    Result := True;
  end else
    ARect := Rect(0, 0, 0, 0);
end;

{------------------------------------------------------------------------------
  Function: TGtk4WSWinControl.GetText
  Params:  Sender: The control to retrieve the text from
  Returns: the requested text

  Retrieves the text from a control. 
 ------------------------------------------------------------------------------}
class function TGtk4WSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
begin
  Result := False;
  if not WSCheckHandleAllocated(AWinControl, 'GetText') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.GetText ',dbgsName(AWinControl));
  {$ENDIF}
  AText := TGtk4Widget(AWinControl.Handle).Text;
  Result := True;
end;
  
class function TGtk4WSWinControl.GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean;
var
  S: String;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.GetTextLen');
  {$ENDIF}
  S := '';
  Result := GetText(AWinControl, S);
  if Result then
    ALength := Length(S);
end;

class procedure TGtk4WSWinControl.SetBiDiMode(const AWinControl: TWinControl; UseRightToLeftAlign, UseRightToLeftReading, UseRightToLeftScrollBar : Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBiDiMode') then Exit;
  { UseRightToLeftAlign controls widget layout direction (mirroring),
    matching Qt5 behavior. GTK4's set_direction affects both text and
    widget layout. }
  if UseRightToLeftAlign then
    TGtk4Widget(AWinControl.Handle).Widget^.set_direction(GTK_TEXT_DIR_RTL)
  else
    TGtk4Widget(AWinControl.Handle).Widget^.set_direction(GTK_TEXT_DIR_LTR);
end;

class procedure TGtk4WSWinControl.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then Exit;
  TGtk4Widget(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSWinControl.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.GetDefaultClientRect ',dbgsName(AWinControl),' handle=',dbgs(AWinControl.HandleAllocated));
  {$ENDIF}
  Result:=false;
end;

class function TGtk4WSWinControl.GetDesignInteractive(
  const AWinControl: TWinControl; AClientPos: TPoint): Boolean;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.GetDesignInteractive');
  {$ENDIF}
  Result := False;
end;

class procedure TGtk4WSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'Invalidate') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.Invalidate');
  {$ENDIF}
  TGtk4Widget(AWinControl.Handle).Update(nil);
end;

class procedure TGtk4WSWinControl.Repaint(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'Repaint') then
    Exit;
  TGtk4Widget(AWinControl.Handle).Update(nil);
end;

class procedure TGtk4WSWinControl.PaintTo(const AWinControl: TWinControl; ADC: HDC;
  X, Y: Integer);
var
  AWidget: TGtk4Widget;
  cr: Pcairo_t;
  APaintable: PGdkPaintable;
  ASnapshot: PGtkSnapshot;
  ANode: PGskRenderNode;
  AWidth, AHeight: gint;
  AParent: PGtkWidget;
  ABounds: graphene_rect_t;
  AOffset: graphene_point_t;
begin
  if not WSCheckHandleAllocated(AWincontrol, 'PaintTo') or (ADC = 0) then
    Exit;
  AWidget := TGtk4Widget(AWinControl.Handle);
  if AWidget = nil then Exit;
  if AWidget.Widget = nil then Exit;

  cr := TGtk4DeviceContext(ADC).pcr;
  if cr = nil then Exit;

  AWidth := AWidget.Widget^.get_allocated_width;
  AHeight := AWidget.Widget^.get_allocated_height;
  if (AWidth <= 0) or (AHeight <= 0) then Exit;

  { GTK4: Use GtkWidgetPaintable to capture the widget's rendering,
    snapshot it into a GskRenderNode, then draw that to our cairo context. }
  APaintable := gtk4_widget_paintable_new(AWidget.Widget);
  if APaintable = nil then Exit;
  try
    ASnapshot := gtk4_snapshot_new;
    gdk4_paintable_snapshot(APaintable, ASnapshot, AWidth, AHeight);
    ANode := gtk4_snapshot_free_to_node(ASnapshot);
    { ASnapshot is consumed by free_to_node — do not free again }
    if ANode <> nil then
    begin
      cairo_save(cr);
      cairo_translate(cr, X, Y);
      gsk4_render_node_draw(ANode, cr);
      cairo_restore(cr);
      gsk4_render_node_unref(ANode);
    end
    else
    begin
      { GtkWidgetPaintable draws from the widget's cached render_node
        (its last on-screen frame). A control created hidden and shown
        programmatically has never rendered a frame, so render_node is
        NULL and the paintable yields an empty node — PaintTo drew blank
        (runtime-confirmed). gtk_widget_snapshot_child forces a LIVE
        snapshot of a mapped child, populating its render_node. It wants a
        pristine snapshot and wraps the node in the child's parent-relative
        transform, so cancel that offset at the cairo stage (X - origin)
        rather than pre-translating the snapshot. }
      AParent := AWidget.Widget^.get_parent;
      if (AParent <> nil) and AWidget.Widget^.get_mapped then
      begin
        AOffset.x := 0;
        AOffset.y := 0;
        if gtk4_widget_compute_bounds(AWidget.Widget, AParent, @ABounds) then
        begin
          AOffset.x := ABounds.origin.x;
          AOffset.y := ABounds.origin.y;
        end;
        ASnapshot := gtk4_snapshot_new;
        gtk4_widget_snapshot_child(AParent, AWidget.Widget, ASnapshot);
        ANode := gtk4_snapshot_free_to_node(ASnapshot);
        if ANode <> nil then
        begin
          cairo_save(cr);
          cairo_translate(cr, X - AOffset.x, Y - AOffset.y);
          gsk4_render_node_draw(ANode, cr);
          cairo_restore(cr);
          gsk4_render_node_unref(ANode);
        end;
      end;
    end;
  finally
    g_object_unref(PGObject(APaintable));
  end;
end;

class procedure TGtk4WSWinControl.SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBounds') then
    Exit;
  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('TGtk4WSWinControl.SetBounds ',dbgsName(AWinControl),Format(' ALeft %d ATop %d AWidth %d AHeight %d',[ALeft, ATop, AWidth, AHeight]));
  {$ENDIF}
  TGtk4Widget(AWinControl.Handle).SetBounds(ALeft,ATop,AWidth,AHeight);
  {$IF DEFINED(GTK4DEBUGCORE) OR DEFINED(GTK4DEBUGSIZE)}
  DebugLn('TGtk4WSWinControl.SetBounds ',dbgsName(AWinControl),' isRealized=',dbgs(AWidget^.get_realized),
    ' IsMapped=',dbgs(AWidget^.get_mapped));
  {$ENDIF}
end;
    
class procedure TGtk4WSWinControl.SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBorderStyle') then
    Exit;
  TGtk4Widget(AWinControl.Handle).SetBorderStyle(ABorderStyle);
end;

class procedure TGtk4WSWinControl.SetChildZPosition(
  const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer;
  const AChildren: TFPList);
var
  Reorder: TFPList;
  n: Integer;
  Child: TWinControl;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetChildZPosition') then
    Exit;
  if not WSCheckHandleAllocated(AChild, 'SetChildZPosition (child)') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.SetChildZPosition');
  {$ENDIF}
  if (ANewPos <= 0) or (ANewPos >= AChildren.Count - 1) then
  begin
    // simple
    if ANewPos <= 0 then // bottom
      TGtk4Widget(AChild.Handle).lowerWidget
    else
      TGtk4Widget(AChild.Handle).raiseWidget;
  end else
  begin
    if (ANewPos >= 0) and (ANewPos < AChildren.Count -1) then
    begin
      Reorder := TFPList.Create;
      for n := AChildren.Count - 1 downto 0 do
        Reorder.Add(AChildren[n]);
      Child := TWinControl(Reorder[ANewPos + 1]);
      if Child.HandleAllocated then
        TGtk4Widget(AChild.Handle).stackUnder(TGtk4Widget(Child.Handle).Widget)
      else
        TGtk4Widget(AChild.Handle).lowerWidget;
      Reorder.Free;
    end;
  end;
end;

class procedure TGtk4WSWinControl.SetColor(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetColor') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.SetColor ',dbgsName(AWinControl));
  {$ENDIF}
  TGtk4Widget(AWinControl.Handle).Color := AWinControl.Color;
end;

class procedure TGtk4WSWinControl.SetCursor(const AWinControl: TWinControl; const ACursor: HCursor);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetCursor') then
    Exit;
  TGtk4Widget(AWinControl.Handle).SetCursor(ACursor);
end;

class procedure TGtk4WSWinControl.SetShape(const AWinControl: TWinControl;
  const AShape: HBITMAP);
begin
  { GTK4 removed gdk_window_shape_combine_region.
    Window shapes are not supported in GTK4/Wayland. }
end;

class procedure TGtk4WSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
var
  AWidget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetFont') then
    Exit;

  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.SetFont ',dbgsName(AWinControl),' font.Size=',dbgs(AFont.Size),' font.Height=',dbgs(AFont.Height),' ASize=',dbgs(ASize),
  ' pxPerInch ',dbgs(AFont.PixelsPerInch));
  {$ENDIF}
  AWidget := TGtk4Widget(AWinControl.Handle);
  AWidget.SetLclFont(AFont);
end;

class procedure TGtk4WSWinControl.SetPos(const AWinControl: TWinControl; const ALeft, ATop: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetPos') then
    Exit;
  { Move widget within its parent GtkFixed container }
  TGtk4Widget(AWinControl.Handle).Move(ALeft, ATop);
end;

class procedure TGtk4WSWinControl.SetSize(const AWinControl: TWinControl; const AWidth, AHeight: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetSize') then
    Exit;
  { Resize widget via size_request + size_allocate }
  TGtk4Widget(AWinControl.Handle).SetBounds(
    AWinControl.Left, AWinControl.Top, AWidth, AHeight);
end;

{------------------------------------------------------------------------------
  Method: TGtk4WSWinControl.SetText
  Params:  AWinControl - the calling object
           AText       - String to be set as label/text for a control
  Returns: Nothing

  Sets the label text on a widget
 ------------------------------------------------------------------------------}
class procedure TGtk4WSWinControl.SetText(const AWinControl: TWinControl; const AText: String);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetText') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.SetText ',dbgsName(AWinControl));
  {$ENDIF}
  TGtk4Widget(AWinControl.Handle).Text := AText;
end;

class procedure TGtk4WSWinControl.ShowHide(const AWinControl: TWinControl);
var
  wgt:TGtk4Widget;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSWinControl.ShowHide ',dbgsName(AWinControl));
  {$ENDIF}
  wgt:=TGtk4Widget(AWinControl.Handle);
  wgt.Visible := AWinControl.HandleObjectShouldBeVisible;
  if wgt.Visible then
  begin
    wgt.ShowAll;
    // imediatelly realize (create widget handles), so we'll get updated bounds
    // and everything just on time.
    if not (wtScrollingWin in wgt.WidgetType) then
    begin
      wgt.GetContainerWidget^.realize;
    end;
  end;
end;

class procedure TGtk4WSWinControl.ScrollBy(const AWinControl: TWinControl;
  DeltaX, DeltaY: integer);
var
  ScrollableWin: TGtk4ScrollableWin;
  Scrolled: PGtkScrolledWindow;
  Adjustment: PGtkAdjustment;
  h, v: Double;
  NewPos: Double;
begin
  if not AWinControl.HandleAllocated then exit;
  { ScrollBy_WS reaches here from TScrollingWinControl.ScrollBy AND
    TCustomMemo.ScrollBy — the handle can be any TGtk4ScrollableWin
    descendant (TGtk4Memo is not a TGtk4ScrollingWinControl), so check the
    common ancestor that declares GetScrolledWindow/ScrollX/ScrollY instead
    of hard-casting to TGtk4ScrollingWinControl. }
  if not (TObject(AWinControl.Handle) is TGtk4ScrollableWin) then
    exit;
  ScrollableWin := TGtk4ScrollableWin(AWinControl.Handle);
  Scrolled := ScrollableWin.GetScrolledWindow;
  if not Gtk4IsScrolledWindow(Scrolled) then
    exit;
  ScrollableWin.ScrollX := ScrollableWin.ScrollX + DeltaX;
  ScrollableWin.ScrollY := ScrollableWin.ScrollY + DeltaY;
  Adjustment := gtk_scrolled_window_get_hadjustment(Scrolled);
  if Adjustment <> nil then
  begin
    h := gtk_adjustment_get_value(Adjustment);
    NewPos := h - DeltaX;
    if NewPos < 0 then
      NewPos := 0
    else
    begin
      v := Adjustment^.upper - Adjustment^.page_size;
      if NewPos > v then
        NewPos := v;
    end;
    gtk_adjustment_set_value(Adjustment, NewPos);
  end;
  Adjustment := gtk_scrolled_window_get_vadjustment(Scrolled);
  if Adjustment <> nil then
  begin
    v := gtk_adjustment_get_value(Adjustment);
    NewPos := v - DeltaY;
    if NewPos < 0 then
      NewPos := 0
    else
    begin
      h := Adjustment^.upper - Adjustment^.page_size;
      if NewPos > h then
        NewPos := h;
    end;
    gtk_adjustment_set_value(Adjustment, NewPos);
  end;
  AWinControl.Invalidate;
end;

{ TGtk4WSCustomControl }

class function TGtk4WSCustomControl.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  Gtk4CustomControl: TGtk4CustomControl;
begin
  Gtk4CustomControl := TGtk4CustomControl.Create(AWinControl, AParams);
  Result := TLCLHandle(Gtk4CustomControl);
end;


{ TGtk4WSDragImageListResolution }

{ GTK4/Wayland: Arbitrary window positioning (gtk_window_move) was removed.
  Popup windows for drag images cannot be freely positioned on screen.
  The LCL drag manager still works (cursor changes, drag messages) —
  only the visual drag image overlay is unavailable.
  Returns True so the drag operation proceeds normally. }

class function TGtk4WSDragImageListResolution.BeginDrag(const ADragImageList: TDragImageListResolution;
  Window: HWND; AIndex, X, Y: Integer): Boolean;
begin
  Result := True;
end;

class function TGtk4WSDragImageListResolution.DragMove(const ADragImageList: TDragImageListResolution;
  X, Y: Integer): Boolean;
begin
  Result := True;
end;

class procedure TGtk4WSDragImageListResolution.EndDrag(const ADragImageList: TDragImageListResolution);
begin
end;

class function TGtk4WSDragImageListResolution.HideDragImage(const ADragImageList: TDragImageListResolution;
  ALockedWindow: HWND; DoUnLock: Boolean): Boolean;
begin
  Result := True;
end;

class function TGtk4WSDragImageListResolution.ShowDragImage(const ADragImageList: TDragImageListResolution;
  ALockedWindow: HWND; X, Y: Integer; DoLock: Boolean): Boolean;
begin
  Result := True;
end;

end.
