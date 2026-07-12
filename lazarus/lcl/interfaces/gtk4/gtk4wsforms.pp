{
 *****************************************************************************
 *                                Gtk4WSForms.pp                                 *
 *                                ----------                                 * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSForms;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

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
  Classes, Graphics, Controls, Forms, LCLType, LCLProc, LMessages,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, Gtk4WSControls, WSForms, WSProc,
  LazGtk4, LazGdk4, LazGLib2, LazGtk4_Compat, gtk4widgets, gtk4int, gtk4objects;

type
  { TWSScrollingWinControl }

  TGtk4WSScrollingWinControlClass = class of TWSScrollingWinControl;

  { TGtk4WSScrollingWinControl }

  TGtk4WSScrollingWinControl = class(TWSScrollingWinControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure ScrollBy(const AWinControl: TWinControl; DeltaX, DeltaY: integer); override;
  end;

  { TWSScrollBox }

  TGtk4WSScrollBox = class(TGtk4WSScrollingWinControl)
  published
  end;

  { TWSCustomFrame }

  TGtk4WSCustomFrame = class(TGtk4WSScrollingWinControl)
  published
  end;

  { TWSFrame }

  TGtk4WSFrame = class(TGtk4WSCustomFrame)
  published
  end;

  { TWSCustomForm }

  { TGtk4WSCustomForm }

  TGtk4WSCustomForm = class(TWSCustomForm)
  published
    class function  CanFocus(const AWincontrol: TWinControl): Boolean; override;
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class function  GetDefaultClientRect(const AWinControl: TWinControl;
      const {%H-}aLeft, {%H-}aTop, aWidth, aHeight: integer;
      var aClientRect: TRect): boolean; override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;

    class procedure CloseModal(const ACustomForm: TCustomForm); override;
    class procedure SetAllowDropFiles(const AForm: TCustomForm; AValue: Boolean); override;
    class procedure SetAlphaBlend(const ACustomForm: TCustomForm; const AlphaBlend: Boolean;
      const Alpha: Byte); override;
    class procedure SetBorderIcons(const AForm: TCustomForm;
        const ABorderIcons: TBorderIcons); override;
    class procedure SetFormBorderStyle(const AForm: TCustomForm;
                             const AFormBorderStyle: TFormBorderStyle); override;
    class procedure SetFormStyle(const AForm: TCustomform; const AFormStyle, AOldFormStyle: TFormStyle); override;
    class procedure SetIcon(const AForm: TCustomForm; const Small, Big: HICON); override;
    class procedure ShowModal(const ACustomForm: TCustomForm); override;
    class procedure SetRealPopupParent(const ACustomForm: TCustomForm;
      const APopupParent: TCustomForm); override;
    class procedure SetShowInTaskbar(const AForm: TCustomForm; const AValue: TShowInTaskbar); override;
    class procedure SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition); override;
    class procedure ScrollBy(const AWinControl: TWinControl; DeltaX, DeltaY: integer); override;
    class function GetDefaultColor(const AControl: TControl; const ADefaultColorType: TDefaultColorType): TColor; override;

    {mdi support}
    class function ActiveMDIChild(const AForm: TCustomForm): TCustomForm; override;
    class function Cascade(const AForm: TCustomForm): Boolean; override;
    class function GetClientHandle(const AForm: TCustomForm): HWND; override;
    class function GetMDIChildren(const AForm: TCustomForm; AIndex: Integer): TCustomForm; override;
    class function Next(const AForm: TCustomForm): Boolean; override;
    class function Previous(const AForm: TCustomForm): Boolean; override;
    class function Tile(const AForm: TCustomForm): Boolean; override;
    class function MDIChildCount(const AForm: TCustomForm): Integer; override;
  end;
  TGtk4WSCustomFormClass = class of TGtk4WSCustomForm;

  { TWSForm }

  TGtk4WSForm = class(TGtk4WSCustomForm)
  published
  end;

  { TWSHintWindow }

  { TGtk4WSHintWindow }

  TGtk4WSHintWindow = class(TGtk4WSCustomForm)
  published
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;

  { TWSScreen }

  TGtk4WSScreen = class(TWSLCLComponent)
  published
  end;

  { TWSApplicationProperties }

  TGtk4WSApplicationProperties = class(TWSLCLComponent)
  published
  end;

implementation
uses Math, SysUtils, LazGio2, LazGObject2, gtk4procs;

{ TGtk4WSScrollingWinControl }

class function TGtk4WSScrollingWinControl.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4ScrollingWinControl.Create(AWinControl, AParams));
end;

class procedure TGtk4WSScrollingWinControl.ScrollBy(
  const AWinControl: TWinControl; DeltaX, DeltaY: integer);
begin
  TGtk4WSWinControl.ScrollBy(AWinControl, DeltaX, DeltaY);
end;

{ TGtk4WSCustomForm }

class function TGtk4WSCustomForm.CanFocus(const AWincontrol: TWinControl): Boolean;
begin
  if AWinControl.HandleAllocated then
    Result := TGtk4Widget(AWinControl.Handle).Widget^.get_visible and
              TGtk4Widget(AWinControl.Handle).Widget^.get_can_focus
  else
    Result := True;
end;

class function TGtk4WSCustomForm.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
begin
  Result := False;
  if AWinControl.HandleAllocated then Exit;
  { For unallocated handles, client rect equals full area }
  aClientRect := Rect(0, 0, Max(0, aWidth), Max(0, aHeight));
  Result := True;
end;

class function TGtk4WSCustomForm.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AWindow: TGtk4Window;
  AGtkWindow: PGtkWindow;
  ARect: TGdkRectangle;
  AWidget: PGtkWidget;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.CreateHandle');
  {$ENDIF}
  AWindow := TGtk4Window.Create(AWinControl, AParams);

  //debugln(['TGtk4WSCustomForm.CreateHandle AWindow.Widget=',Get3WidgetClassName(AWindow.Widget)]);

  AWidget:=AWindow.Widget;
  AGtkWindow:=nil;
  if Gtk4IsGtkWindow(AWidget) then
  begin
    AGtkWindow := PGtkWindow(AWidget);
    AWindow.Title := AWinControl.Caption;

    AGtkWindow^.set_resizable(True);
    { GTK4: set_has_resize_grip removed }
  end;

  with ARect do
  begin
    x := AWinControl.Left;
    y := AWinControl.Top;
    width := AWinControl.Width;
    height := AWinControl.Height;
  end;
  AWidget^.set_size_request(ARect.width, ARect.height);
  { GTK4: Do NOT call AddWindow here. gtk_application_add_window() may
    implicitly show the window, and a deferred GTK idle callback can re-show
    it even after an explicit hide(). Defer AddWindow to ShowHide so that
    windows that are never shown (e.g. dialogs created but not yet displayed)
    are never added to the application and remain invisible. }

  Result := TLCLHandle(AWindow);

  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.CreateHandle handle ',dbgs(Result));
  {$ENDIF}
end;

class procedure TGtk4WSCustomForm.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBounds') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.SetBounds ',dbgsName(AWinControl),Format(' ALeft %d ATop %d AWidth %d AHeight %d',[ALeft, ATop, AWidth, AHeight]));
  {$ENDIF}
  TGtk4Widget(AWinControl.Handle).SetBounds(ALeft,ATop,AWidth,AHeight);
end;

{ GTK4: Identify undecorated stay-on-top popups (code completion list, its
  long-line hint) that must become X11 override-redirect windows so the WM
  neither repositions them nor steals focus from the owning editor. Mirrors
  Qt5's QtBypassWindowManagerHint use.
  Deliberately EXCLUDES plain THintWindow tooltips (bsNone + fsNormal): making
  those override-redirect + always-on-top under the cursor causes pointer
  enter/leave feedback loops (heavy flicker when hovering the component
  palette). Tooltips keep their prior WM-managed transient-for behaviour.
  Completion-related popups all set fsSystemStayOnTop explicitly, so they are
  still covered here. csDesigning forms stay WM-managed. }
function Gtk4FormIsPopup(AForm: TCustomForm): Boolean;
begin
  Result := (AForm <> nil)
    and (not (csDesigning in AForm.ComponentState))
    and ((csNoFocus in AForm.ControlStyle)
      or ((AForm.BorderStyle = bsNone)
          and (AForm.FormStyle in [fsStayOnTop, fsSystemStayOnTop])));
end;

{ GTK4: Deferred re-layout after initial window show.  Fires once in the
  next idle cycle after present() and all constraint cycling has settled.
  During initial window creation, constraint cycling (SetBounds with
  intermediate heights 126→198→90) fires while InUpdate=True, preventing
  LM_SIZE delivery.  The LCL dimensions are set correctly, but the child
  layout (CoolBar, toolbar) may not have been recalculated after the final
  constraint was applied — the LCL skipped Realign because dimensions were
  updated before calling WS.SetBounds.  This idle callback forces one
  unconditional LM_SIZE delivery which triggers Realign and fixes layout. }
function Gtk4PostShowResizeCB(AData: gpointer): gboolean; cdecl;
var
  W: PGtkWidget;
  AWindow: TGtk4Window;
  CurW, CurH: gint;
  MinW, MinH: gint;
  Overhead: Integer;
  Msg: TLMSize;
begin
  Result := False; { G_SOURCE_REMOVE — run once }
  W := PGtkWidget(AData);
  if (W = nil) or not Gtk4IsWidget(PGObject(W)) or not W^.get_realized then Exit;
  if not Gtk4IsGtkWindow(W) then Exit;
  AWindow := TGtk4Window(g_object_get_data(PGObject(W), 'lclwidget'));
  if (AWindow = nil) or not AWindow.IsWidgetOk then Exit;
  if not Assigned(AWindow.LCLObject) or not AWindow.CanSendLCLMessage then Exit;

  PGtkWindow(W)^.get_default_size(@CurW, @CurH);
  W^.get_size_request(@MinW, @MinH);
  if (MinW > 0) and (CurW < MinW) then CurW := MinW;
  if (MinH > 0) and (CurH < MinH) then CurH := MinH;
  if (CurW <= 0) or (CurH <= 0) then Exit;

  Overhead := AWindow.GetNonClientOverhead;
  Dec(CurH, Overhead);
  if CurH < 1 then CurH := 1;

  AWindow.LCLObject.InvalidateClientRectCache(False);
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_SIZE;
  Msg.SizeType := SIZE_RESTORED or Size_SourceIsInterface;
  Msg.Width := Word(CurW);
  Msg.Height := Word(CurH);
  AWindow.DeliverMessage(Msg);
end;

class procedure TGtk4WSCustomForm.ShowHide(const AWinControl: TWinControl);
var
  AForm, OtherForm: TCustomForm;
  AWindow: PGtkWindow;
  i: Integer;
  ShouldBeVisible: Boolean;
  AGtk4Widget: TGtk4Widget;
  OtherGtk4Window: TGtk4Window;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.ShowHide handleAllocated=',dbgs(AWinControl.HandleAllocated));
  {$ENDIF}
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then
    Exit;
  AForm := TCustomForm(AWinControl);
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.ShowHide visible=',dbgs(AWinControl.HandleObjectShouldBeVisible));
  {$ENDIF}
  AGtk4Widget:=TGtk4Widget(AForm.Handle);
  if Gtk4IsGtkWindow(AGtk4Widget.Widget) then
    AWindow := PGtkWindow(AGtk4Widget.Widget)
  else
    AWindow := nil;

  ShouldBeVisible:=AForm.HandleObjectShouldBeVisible;
  if (fsModal in AForm.FormState) and ShouldBeVisible and (AWindow<>nil) then
  begin
    { GTK4: set_type_hint removed (GDK_WINDOW_TYPE_HINT_DIALOG) }
    AWindow^.set_modal(True);
  end;
  { GTK4/X11: For undecorated popup forms (completion, hints), set
    override-redirect BEFORE the window is mapped (below). X evaluates the
    attribute at map time, and Visible:=True is what maps the surface. }
  if ShouldBeVisible and (AWindow <> nil) and (AGtk4Widget is TGtk4Window)
     and Gtk4FormIsPopup(AForm) then
    TGtk4Window(AGtk4Widget).PreparePopupShow;
  AGtk4Widget.Visible := ShouldBeVisible;
  if AGtk4Widget.Visible then
  begin
    if (fsModal in AForm.FormState) and (Application.ModalLevel > 0) and (AWindow<>nil) then
    begin
      if Application.ModalLevel > 1 then
      begin
        for i := 0 to Screen.CustomFormZOrderCount - 1 do
        begin
          OtherForm:=Screen.CustomFormsZOrdered[i];
          if (OtherForm <> AForm) and
            (fsModal in OtherForm.FormState) and
            OtherForm.HandleAllocated then
          begin
            OtherGtk4Window:=TGtk4Window(OtherForm.Handle);
            if Gtk4IsGtkWindow(OtherGtk4Window.Widget) then
            begin
              AWindow^.set_transient_for(PGtkWindow(OtherGtk4Window.Widget));
              break;
            end;
          end;
        end;
      end;
    end;
    if AWindow<>nil then
    begin
      { GTK4: Ensure window is registered with the application before showing.
        Deferred from CreateHandle because gtk_application_add_window() may
        implicitly show the window (and a GTK idle callback re-shows it even
        after hide). Adding here guarantees only visible windows are registered. }
      Gtk4WidgetSet.AddWindow(AWindow);

      { GTK4: Use present() for decorated windows — it triggers immediate
        window mapping and full layout allocation needed for child widgets
        (toolbar icons, tab icons).  For undecorated windows (popups, hints,
        completion lists), use show() to avoid stealing focus from the owner
        window.  present() activates/focuses the window, which would cause
        SynEdit to close its completion popup when it loses focus. }
      if AWindow^.get_decorated then
        AWindow^.present
      else
      begin
        PGtkWidget(AWindow)^.show;
        { Override-redirect popups aren't stacked by the WM — raise explicitly. }
        if (AGtk4Widget is TGtk4Window) and Gtk4FormIsPopup(AForm) then
          TGtk4Window(AGtk4Widget).RaiseX11Popup;
      end;

      { Apply window state: minimize, maximize, fullscreen }
      if not (csDesigning in AForm.ComponentState) then
      begin
        case AForm.WindowState of
          wsMinimized:
            gtk4_window_minimize(AWindow);
          wsMaximized:
            AWindow^.maximize;
          wsFullScreen:
            AWindow^.fullscreen;
        end;
      end;

      { GTK4: Reconnect the after-paint move-polling callback now that the
        window is realized.  The initial SetMaxSize (from ConstraintsChange)
        may have been called before realization when get_frame_clock
        returned nil.  WM_NORMAL_HINTS are NOT written here — max size is
        enforced by the notify::default-size snap-back (see
        Gtk4WindowAfterPaintCB in gtk4widgets.pas). }
      if AGtk4Widget is TGtk4Window then
        TGtk4Window(AGtk4Widget).ConnectAfterPaint;

      { GTK4: Schedule a deferred re-layout for DECORATED windows only.
        During the initial show sequence, constraint cycling changes the
        window's default_size multiple times.  The LCL dimensions are correct,
        but GTK child widget allocations (toolbar icons, CoolBar children) may
        be stale.  A deferred queue_resize ensures one clean layout pass.
        Skip for undecorated windows (popups, hints) — they don't need
        re-layout and the unexpected LM_SIZE can interfere with popup logic. }
      if AWindow^.get_decorated then
        g_idle_add(@Gtk4PostShowResizeCB, PGtkWidget(AWindow));
    end;
  end else
  begin
    if (fsModal in AForm.FormState) and (AWindow<>nil) then
    begin
      { Ensure hidden modal forms do not keep blocking input on other toplevels. }
      AWindow^.set_modal(False);
      if AWindow^.transient_for <> nil then
        AWindow^.set_transient_for(nil);
    end;
  end;
end;

class procedure TGtk4WSCustomForm.CloseModal(const ACustomForm: TCustomForm);
var
  AWindow: PGtkWindow;
  AGtk4Widget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(ACustomForm, 'CloseModal') then
    Exit;
  AGtk4Widget := TGtk4Widget(ACustomForm.Handle);
  if Gtk4IsGtkWindow(AGtk4Widget.Widget) then
  begin
    AWindow := PGtkWindow(AGtk4Widget.Widget);
    { Remove modal state so the parent windows become interactive again }
    AWindow^.set_modal(False);
  end;
end;

{ GTK4: File drop callback for GtkDropTarget 'drop' signal.
  Receives a GValue containing GdkFileList, extracts file paths,
  and delivers them to the LCL via IntfDropFiles. }
function Gtk4DropFilesCB({%H-}target: PGtkEventController; value: PGValue;
  {%H-}x: gdouble; {%H-}y: gdouble; Data: gpointer): gboolean; cdecl;
var
  AFileList: Pointer;
  ANode: PGSList;
  APath: PgChar;
  Files: array of String;
  AForm: TCustomForm;
begin
  Result := False;
  if Data = nil then exit;

  AFileList := g_value_get_boxed(value);
  if AFileList = nil then exit;

  ANode := gdk4_file_list_get_files(AFileList);
  SetLength(Files{%H-}, 0);
  while ANode <> nil do
  begin
    APath := g_file_get_path(PGFile(ANode^.data));
    if APath <> nil then
    begin
      SetLength(Files, Length(Files) + 1);
      Files[High(Files)] := APath;
      g_free(APath);
    end;
    ANode := ANode^.next;
  end;

  if Length(Files) > 0 then
  begin
    AForm := TCustomForm(Data);
    AForm.IntfDropFiles(Files);
    if Application <> nil then
      Application.IntfDropFiles(Files);
    Result := True;
  end;
end;

class procedure TGtk4WSCustomForm.SetAllowDropFiles(const AForm: TCustomForm;
  AValue: Boolean);
var
  AGtk4Widget: TGtk4Widget;
  AController: PGtkEventController;
  AOldController: PGtkEventController;
begin
  if not WSCheckHandleAllocated(AForm, 'SetAllowDropFiles') then exit;
  AGtk4Widget := TGtk4Widget(AForm.Handle);

  { Remove existing drop controller if any }
  AOldController := PGtkEventController(g_object_get_data(
    PGObject(AGtk4Widget.Widget), 'lcl-drop-files'));
  if AOldController <> nil then
  begin
    gtk4_widget_remove_controller(AGtk4Widget.Widget, AOldController);
    g_object_set_data(PGObject(AGtk4Widget.Widget), 'lcl-drop-files', nil);
  end;

  if AValue then
  begin
    { GTK4: Create GtkDropTarget accepting GDK_TYPE_FILE_LIST.
      The 'drop' signal provides a GValue containing GdkFileList. }
    AController := gtk4_drop_target_new(gdk4_file_list_get_type,
      [GDK_ACTION_COPY, GDK_ACTION_MOVE]);
    g_signal_connect_data(AController, 'drop',
      TGCallback(@Gtk4DropFilesCB), AForm, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(AGtk4Widget.Widget, AController);
    { Store controller ref so we can remove it later }
    g_object_set_data(PGObject(AGtk4Widget.Widget), 'lcl-drop-files', AController);
  end;
end;

class procedure TGtk4WSCustomForm.SetBorderIcons(const AForm: TCustomForm;
        const ABorderIcons: TBorderIcons);
var
  AWindow: PGtkWindow;
  AGtk4Widget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(AForm, 'SetBorderIcons') then
    Exit;
  if csDesigning in AForm.ComponentState then
    Exit;
  AGtk4Widget := TGtk4Widget(AForm.Handle);
  if not Gtk4IsGtkWindow(AGtk4Widget.Widget) then
    Exit;
  AWindow := PGtkWindow(AGtk4Widget.Widget);
  { GTK4: The window manager controls minimize/maximize buttons.
    We can control the close button via set_deletable. }
  gtk_window_set_deletable(AWindow, biSystemMenu in ABorderIcons);
end;

class procedure TGtk4WSCustomForm.SetFormBorderStyle(const AForm: TCustomForm;
  const AFormBorderStyle: TFormBorderStyle);
const
  FormResizableMap: array[TFormBorderStyle] of gboolean = (
    False, // bsNone
    False, // bsSingle
    True,  // bsSizeable
    False, // bsDialog
    False, // bsToolWindow
    True   // bsSizeToolWin
  );
var
  AWindow: PGtkWindow;
  AGtk4Widget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(AForm, 'SetFormBorderStyle') then
    Exit;
  if csDesigning in AForm.ComponentState then
    Exit;
  AGtk4Widget := TGtk4Widget(AForm.Handle);
  if not Gtk4IsGtkWindow(AGtk4Widget.Widget) then
    Exit;
  AWindow := PGtkWindow(AGtk4Widget.Widget);
  gtk_window_set_decorated(AWindow, AFormBorderStyle <> bsNone);
  gtk_window_set_resizable(AWindow, FormResizableMap[AFormBorderStyle]);
end;

class procedure TGtk4WSCustomForm.SetFormStyle(const AForm: TCustomform;
  const AFormStyle, AOldFormStyle: TFormStyle);
begin
  { GTK4 4.6 has no gtk_window_set_keep_above (added in later versions).
    Do NOT call present() — it both raises AND focuses the window, causing
    focus bouncing between stay-on-top forms (Object Inspector vs Main Window).
    Stay-on-top behavior is not available in GTK4 4.6. }
end;
    
class procedure TGtk4WSCustomForm.SetIcon(const AForm: TCustomForm; const Small, Big: HICON);
begin
  if not WSCheckHandleAllocated(AForm, 'SetIcon') then
    Exit;
  if Big = 0 then
    TGtk4Window(AForm.Handle).Icon := Gtk4WidgetSet.AppIcon
  else
    TGtk4Window(AForm.Handle).Icon := TGtk4Image(Big).Handle;
end;

class procedure TGtk4WSCustomForm.SetShowInTaskbar(const AForm: TCustomForm;
  const AValue: TShowInTaskbar);
var
  AWindow: TGtk4Window;
  Enable: boolean;
begin
  if not WSCheckHandleAllocated(AForm, 'SetShowInTaskbar') then
    Exit;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomForm.SetShowInTaskbar');
  {$ENDIF}
  if (AForm.Parent <> nil) or
     (AForm.ParentWindow <> 0) or
     not (AForm.HandleAllocated) then Exit;
  AWindow := TGtk4Window(AForm.Handle);
  { GTK4: GdkWindow removed. Check widget validity instead. }
  if not AWindow.IsWidgetOK then
    exit;
  Enable := AValue <> stNever;
  if (not Enable) and AWindow.SkipTaskBarHint then
    AWindow.SkipTaskBarHint := False;
  AWindow.SkipTaskBarHint := not Enable;
end;

class procedure TGtk4WSCustomForm.SetZPosition(const AWinControl: TWinControl; const APosition: TWSZPosition);
var
  AWindow: PGtkWindow;
  AGtk4Widget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetZPosition') then
    Exit;
  AGtk4Widget := TGtk4Widget(AWinControl.Handle);
  if not Gtk4IsGtkWindow(AGtk4Widget.Widget) then
    Exit;
  AWindow := PGtkWindow(AGtk4Widget.Widget);
  { GTK4/Wayland: Window stacking order is compositor-managed.
    We can use present() to bring to front. Sending to back is not
    supported by GTK4 API. }
  if (APosition = wszpFront) and AWinControl.HandleObjectShouldBeVisible then
    PGtkWidget(AWindow)^.show;
end;

class procedure TGtk4WSCustomForm.ScrollBy(const AWinControl: TWinControl;
  DeltaX, DeltaY: integer);
begin
  TGtk4WSWinControl.ScrollBy(AWinControl, DeltaX, DeltaY);
end;

class function TGtk4WSCustomForm.GetDefaultColor(const AControl: TControl; const ADefaultColorType: TDefaultColorType): TColor;
const
  DefColors: array[TDefaultColorType] of TColor = (
 { dctBrush } clForm,
 { dctFont  } clBtnText
  );
begin
  Result := DefColors[ADefaultColorType];
end;

class procedure TGtk4WSCustomForm.ShowModal(const ACustomForm: TCustomForm);
begin
  { Modal state is set in ShowHide when fsModal is in FormState.
    This is by design — same pattern as GTK2 and Qt5 backends. }
  if not WSCheckHandleAllocated(ACustomForm, 'ShowModal') then
    Exit;
end;

class procedure TGtk4WSCustomForm.SetRealPopupParent(
  const ACustomForm: TCustomForm; const APopupParent: TCustomForm);
var
  AWindow: PGtkWindow;
  AGtk4Widget: TGtk4Widget;
  ParentWindow: PGtkWindow;
begin
  if not WSCheckHandleAllocated(ACustomForm, 'SetRealPopupParent') then
    Exit;
  if csDestroying in ACustomForm.ComponentState then
    Exit;
  AGtk4Widget := TGtk4Widget(ACustomForm.Handle);
  if not Gtk4IsGtkWindow(AGtk4Widget.Widget) then
    Exit;
  AWindow := PGtkWindow(AGtk4Widget.Widget);
  ParentWindow := nil;
  if (APopupParent <> nil) and APopupParent.HandleAllocated then
  begin
    if Gtk4IsGtkWindow(TGtk4Widget(APopupParent.Handle).Widget) then
      ParentWindow := PGtkWindow(TGtk4Widget(APopupParent.Handle).Widget);
  end;
  AWindow^.set_transient_for(ParentWindow);
end;

class procedure TGtk4WSCustomForm.SetAlphaBlend(const ACustomForm: TCustomForm;
  const AlphaBlend: Boolean; const Alpha: Byte);
var
  AGtk4Widget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(ACustomForm, 'SetAlphaBlend') then
    Exit;
  AGtk4Widget := TGtk4Widget(ACustomForm.Handle);
  { GTK4: gtk_window_set_opacity removed. Use gtk_widget_set_opacity instead. }
  if AlphaBlend then
    AGtk4Widget.Widget^.set_opacity(Alpha / 255)
  else
    AGtk4Widget.Widget^.set_opacity(1);
end;

{ mdi support }

class function TGtk4WSCustomForm.ActiveMDIChild(const AForm: TCustomForm
  ): TCustomForm;
begin
  Result := nil;
end;

class function TGtk4WSCustomForm.Cascade(const AForm: TCustomForm): Boolean;
begin
  Result := False;
end;

class function TGtk4WSCustomForm.GetClientHandle(const AForm: TCustomForm): HWND;
begin
  Result := 0;
end;

class function TGtk4WSCustomForm.GetMDIChildren(const AForm: TCustomForm;
  AIndex: Integer): TCustomForm;
begin
  Result := nil;
end;

class function TGtk4WSCustomForm.MDIChildCount(const AForm: TCustomForm): Integer;
begin
  Result := 0;
end;

class function TGtk4WSCustomForm.Next(const AForm: TCustomForm): Boolean;
begin
  Result := False;
end;

class function TGtk4WSCustomForm.Previous(const AForm: TCustomForm): Boolean;
begin
  Result := False;
end;

class function TGtk4WSCustomForm.Tile(const AForm: TCustomForm): Boolean;
begin
  Result := False;
end;

{ TGtk4WSHintWindow }

class function TGtk4WSHintWindow.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4HintWindow.Create(AWinControl, AParams));
end;

class procedure TGtk4WSHintWindow.ShowHide(const AWinControl: TWinControl);
var
  AWidget: TGtk4Widget;
  AWindow: PGtkWindow;
  ParentWindow: PGtkWindow;
  ShouldBeVisible: Boolean;
  IsPopup: Boolean;
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then Exit;
  AWidget := TGtk4Widget(AWinControl.Handle);
  ShouldBeVisible := AWinControl.HandleObjectShouldBeVisible;
  IsPopup := (AWinControl is TCustomForm)
    and Gtk4FormIsPopup(TCustomForm(AWinControl));
  AWidget.BeginUpdate;
  { GTK4/X11: set override-redirect before the surface is mapped (Visible:=True). }
  if ShouldBeVisible and IsPopup and (AWidget is TGtk4Window) then
    TGtk4Window(AWidget).PreparePopupShow;
  { Normal (non-popup) hint windows stay WM-managed.  Everything the WM
    evaluates at map time must be set BEFORE map, in this order:
    1) realize (create the unmapped surface/XID),
    2) set_transient_for (GDK writes _NET_WM_WINDOW_TYPE_DIALOG here —
       kept for Wayland parent-relative placement),
    3) PrepareTooltipShow (overwrite type with TOOLTIP + XMoveWindow) —
       EWMH WMs leave tooltips unplaced and unfocused, so the hint appears
       at the LCL position and does not deactivate the application. }
  if ShouldBeVisible and (not IsPopup) and (AWidget is TGtk4Window)
     and Gtk4IsGtkWindow(AWidget.Widget) then
  begin
    AWindow := PGtkWindow(AWidget.Widget);
    gtk_widget_realize(AWidget.Widget);
    if (AWindow^.transient_for = nil) and
       (Application.MainForm <> nil) and Application.MainForm.HandleAllocated and
       (wtWindow in TGtk4Widget(Application.MainForm.Handle).WidgetType) then
    begin
      ParentWindow := PGtkWindow(TGtk4Widget(Application.MainForm.Handle).Widget);
      AWindow^.set_transient_for(ParentWindow);
    end;
    TGtk4Window(AWidget).PrepareTooltipShow;
  end;
  AWidget.Visible := ShouldBeVisible;
  if AWidget.Visible and (AWidget is TGtk4Window) then
  begin
    if IsPopup then
      TGtk4Window(AWidget).RaiseX11Popup
    else
      { Placement safety net: re-assert the position after map in case the
        WM re-placed the window (idempotent, no-op when already correct). }
      TGtk4Window(AWidget).PrepareTooltipShow;
  end;
  AWidget.EndUpdate;
end;

end.
