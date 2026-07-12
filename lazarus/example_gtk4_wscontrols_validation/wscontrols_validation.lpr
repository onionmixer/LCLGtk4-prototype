program wscontrols_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Types, Forms, Controls, StdCtrls, ExtCtrls,
  Graphics, Menus, Gtk4Widgets, LazGtk4;

type
  TPaintProbe = class(TCustomControl)
  private
    FPaintCount: Integer;
  protected
    procedure Paint; override;
  public
    property PaintCount: Integer read FPaintCount;
  end;

  TDragProbePanel = class(TPanel)
  public
    function ProbeDragMessage(ADragMessage: TDragMessage; APosition: TPoint;
      ADragObject: TDragObject; ATarget: TControl): PtrInt;
  end;

  TDragProbeObject = class(TDragControlObject)
  public
    function ProbeCursor(Accepted: Boolean; X, Y: Integer): TCursor;
  end;

  TWSControlsValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FPanel: TPanel;
    FProbe: TPaintProbe;
    FScrollBox: TScrollBox;
    FScrollChild: TPanel;
    FBackPanel: TPanel;
    FFrontPanel: TPanel;
    FHiddenPanel: TPanel;
    FReparentLeft: TPanel;
    FReparentRight: TPanel;
    FReparentButton: TButton;
    FGraphicLabel: TLabel;
    FMemo: TMemo;
    FDragSource: TPanel;
    FDragTarget: TDragProbePanel;
    FDragOverCount: Integer;
    FDragDropCount: Integer;
    FStep: Integer;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure DragOverProbe(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure DragDropProbe(Sender, Source: TObject; X, Y: Integer);
    procedure Log(const S: string);
    procedure LogState(const AContext: string);
    procedure RunStep;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  WSControlsValidationForm: TWSControlsValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSCONTROLS_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('WSCONTROLS_VALIDATION_CLOSE_MS'), 0);
end;

function BoolName(AValue: Boolean): string;
begin
  Result := BoolToStr(AValue, True);
end;

function RectText(const R: TRect): string;
begin
  Result := Format('(%d,%d,%d,%d)', [R.Left, R.Top, R.Right, R.Bottom]);
end;

function AdjustmentText(AAdjustment: PGtkAdjustment): string;
begin
  if AAdjustment = nil then
    Exit('nil');

  Result := Format('value=%.1f lower=%.1f upper=%.1f page=%.1f',
    [gtk_adjustment_get_value(AAdjustment),
     gtk_adjustment_get_lower(AAdjustment),
     gtk_adjustment_get_upper(AAdjustment),
     gtk_adjustment_get_page_size(AAdjustment)]);
end;

function NativeScrollText(AControl: TWinControl): string;
var
  Widget: TGtk4Widget;
  Scrollable: TGtk4ScrollableWin;
  ScrolledWindow: PGtkScrolledWindow;
begin
  if (AControl = nil) or (not AControl.HandleAllocated) then
    Exit('native-scroll=unallocated');

  Widget := TGtk4Widget(AControl.Handle);
  if not (Widget is TGtk4ScrollableWin) then
    Exit('native-scroll=not-scrollable-widget');

  Scrollable := TGtk4ScrollableWin(Widget);
  ScrolledWindow := Scrollable.GetScrolledWindow;
  if ScrolledWindow = nil then
    Exit('native-scroll=no-scrolled-window');

  Result := Format('native-scroll=(stored=%d,%d h:[%s] v:[%s])',
    [Scrollable.ScrollX, Scrollable.ScrollY,
     AdjustmentText(gtk_scrolled_window_get_hadjustment(ScrolledWindow)),
     AdjustmentText(gtk_scrolled_window_get_vadjustment(ScrolledWindow))]);
end;

function NativeParentText(AChild, AExpectedParent: TWinControl): string;
var
  ChildWidget: TGtk4Widget;
  ParentWidget: TGtk4Widget;
  ActualParent: PGtkWidget;
  ExpectedParent: PGtkWidget;
begin
  if (AChild = nil) or (AExpectedParent = nil) then
    Exit('native-parent=nil-control');
  if (not AChild.HandleAllocated) or (not AExpectedParent.HandleAllocated) then
    Exit('native-parent=unallocated');

  ChildWidget := TGtk4Widget(AChild.Handle);
  ParentWidget := TGtk4Widget(AExpectedParent.Handle);
  ActualParent := ChildWidget.Widget^.get_parent;
  ExpectedParent := ParentWidget.GetContainerWidget;
  Result := Format('native-parent-match=%s actual=%s expected=%s',
    [BoolName(ActualParent = ExpectedParent),
     IntToHex(PtrUInt(ActualParent), SizeOf(PtrUInt) * 2),
     IntToHex(PtrUInt(ExpectedParent), SizeOf(PtrUInt) * 2)]);
end;

function NativeSizeText(AControl: TWinControl): string;
var
  Widget: TGtk4Widget;
  ReqW: Integer;
  ReqH: Integer;
  DefW: Integer;
  DefH: Integer;
begin
  if (AControl = nil) or (not AControl.HandleAllocated) then
    Exit('native-size=unallocated');

  Widget := TGtk4Widget(AControl.Handle);
  ReqW := 0;
  ReqH := 0;
  Widget.Widget^.get_size_request(@ReqW, @ReqH);
  Result := Format('native-size=(alloc=%dx%d request=%dx%d',
    [Widget.Widget^.get_allocated_width, Widget.Widget^.get_allocated_height,
     ReqW, ReqH]);
  if Widget is TGtk4Window then
  begin
    DefW := 0;
    DefH := 0;
    PGtkWindow(Widget.Widget)^.get_default_size(@DefW, @DefH);
    Result := Result + Format(' default=%dx%d', [DefW, DefH]);
  end;
  Result := Result + ')';
end;

function NativeWindowMenuText(AForm: TCustomForm): string;
var
  Window: TGtk4Window;
  MenuBar: PGtkWidget;
begin
  if (AForm = nil) or (not AForm.HandleAllocated) then
    Exit('window-menu=unallocated');
  if not (TGtk4Widget(AForm.Handle) is TGtk4Window) then
    Exit('window-menu=not-gtk4-window');

  Window := TGtk4Window(AForm.Handle);
  MenuBar := Window.GetMenuBar;
  if MenuBar = nil then
    Exit(Format('window-menu=(none overhead=%d)', [Window.GetNonClientOverhead]));

  Result := Format('window-menu=(visible=%s alloc=%dx%d menubar-height=%d overhead=%d)',
    [BoolName(MenuBar^.get_visible),
     MenuBar^.get_allocated_width,
     MenuBar^.get_allocated_height,
     Window.GetMenuBarHeight,
     Window.GetNonClientOverhead]);
end;

function AccessibleText(AControl: TControl): string;
var
  AccObj: TLazAccessibleObject;
  OwnerWin: TWinControl;
  AccHandle: PtrInt;
  OwnerHandle: PtrInt;
  OwnerName: string;
begin
  if AControl = nil then
    Exit('accessible=nil-control');

  AccObj := AControl.GetAccessibleObject;
  OwnerWin := AccObj.FindOwnerWinControl;
  AccHandle := AccObj.Handle;
  OwnerHandle := 0;
  OwnerName := 'nil';
  if OwnerWin <> nil then
  begin
    OwnerName := OwnerWin.Name;
    if OwnerWin.HandleAllocated then
      OwnerHandle := OwnerWin.Handle;
  end;

  Result := Format('accessible control=%s:%s owner-win=%s handle-allocated=%s handle-match=%s name="%s" description="%s" value="%s" role=%d',
    [AControl.Name, AControl.ClassName, OwnerName,
     BoolName(AccObj.HandleAllocated), BoolName(AccHandle = OwnerHandle),
     AccObj.AccessibleName, AccObj.AccessibleDescription,
     AccObj.AccessibleValue, Ord(AccObj.AccessibleRole)]);
end;

function ColorText(ABitmap: TBitmap; X, Y: Integer): string;
var
  C: TColor;
begin
  if (X < 0) or (Y < 0) or (X >= ABitmap.Width) or (Y >= ABitmap.Height) then
    Exit('oob');
  C := ColorToRGB(ABitmap.Canvas.Pixels[X, Y]);
  Result := Format('(%d,%d,%d)', [Red(C), Green(C), Blue(C)]);
end;

function CountNonWhitePixels(ABitmap: TBitmap): Integer;
var
  X: Integer;
  Y: Integer;
begin
  Result := 0;
  for Y := 0 to ABitmap.Height - 1 do
    for X := 0 to ABitmap.Width - 1 do
      if ColorToRGB(ABitmap.Canvas.Pixels[X, Y]) <> ColorToRGB(clWhite) then
        Inc(Result);
end;

function PaintToSummary(AControl: TWinControl; AWidth, AHeight: Integer): string;
var
  B: TBitmap;
  NonWhite: Integer;
  AllocText: string;
begin
  AllocText := 'alloc=unallocated';
  if AControl.HandleAllocated then
    AllocText := Format('alloc=(%d,%d)',
      [TGtk4Widget(AControl.Handle).Widget^.get_allocated_width,
       TGtk4Widget(AControl.Handle).Widget^.get_allocated_height]);
  B := TBitmap.Create;
  try
    B.SetSize(AWidth, AHeight);
    B.Canvas.Brush.Color := clWhite;
    B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
    AControl.PaintTo(B.Canvas.Handle, 0, 0);
    NonWhite := CountNonWhitePixels(B);
    if GetEnvironmentVariable('WSCONTROLS_PAINTTO_DUMP') <> '' then
      B.SaveToFile(GetEnvironmentVariable('WSCONTROLS_PAINTTO_DUMP') + '_' +
        AControl.Name + '.bmp');
    Result := Format('handle=%s visible=%s bounds=%s %s bitmap=(%d,%d) nonwhite=%d center-rgb=%s',
      [BoolName(AControl.HandleAllocated), BoolName(AControl.Visible),
       RectText(AControl.BoundsRect), AllocText, B.Width, B.Height, NonWhite,
       ColorText(B, AWidth div 2, AHeight div 2)]);
  finally
    B.Free;
  end;
end;

procedure TPaintProbe.Paint;
begin
  Inc(FPaintCount);
  Canvas.Brush.Color := clMoneyGreen;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := clGreen;
  Canvas.Rectangle(0, 0, Width, Height);
  Canvas.TextOut(8, 8, 'paint ' + IntToStr(FPaintCount));
end;

function TDragProbePanel.ProbeDragMessage(ADragMessage: TDragMessage;
  APosition: TPoint; ADragObject: TDragObject; ATarget: TControl): PtrInt;
begin
  Result := DoDragMsg(ADragMessage, APosition, ADragObject, ATarget, False);
end;

function TDragProbeObject.ProbeCursor(Accepted: Boolean; X, Y: Integer): TCursor;
begin
  Result := GetDragCursor(Accepted, X, Y);
end;

constructor TWSControlsValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 WSControls validation';
  Position := poDesigned;
  SetBounds(120, 120, 860, 620);
  Color := clBtnFace;
  Constraints.MinWidth := 500;
  Constraints.MinHeight := 420;

  FPanel := TPanel.Create(Self);
  FPanel.Parent := Self;
  FPanel.Caption := 'host panel';
  FPanel.SetBounds(24, 24, 260, 130);
  FPanel.Color := clSkyBlue;

  FProbe := TPaintProbe.Create(Self);
  FProbe.Parent := FPanel;
  FProbe.SetBounds(16, 32, 210, 72);

  FScrollBox := TScrollBox.Create(Self);
  FScrollBox.Parent := Self;
  FScrollBox.SetBounds(312, 24, 250, 140);
  FScrollBox.HorzScrollBar.Visible := True;
  FScrollBox.VertScrollBar.Visible := True;

  FScrollChild := TPanel.Create(Self);
  FScrollChild.Parent := FScrollBox;
  FScrollChild.Caption := 'scroll child';
  FScrollChild.SetBounds(20, 20, 460, 260);
  FScrollChild.Color := clYellow;

  FBackPanel := TPanel.Create(Self);
  FBackPanel.Name := 'BackPanel';
  FBackPanel.Parent := Self;
  FBackPanel.Caption := 'back';
  FBackPanel.SetBounds(600, 32, 140, 90);
  FBackPanel.Color := clRed;

  FFrontPanel := TPanel.Create(Self);
  FFrontPanel.Name := 'FrontPanel';
  FFrontPanel.Parent := Self;
  FFrontPanel.Caption := 'front';
  FFrontPanel.SetBounds(640, 64, 140, 90);
  FFrontPanel.Color := clLime;

  FHiddenPanel := TPanel.Create(Self);
  FHiddenPanel.Name := 'HiddenPanel';
  FHiddenPanel.Parent := Self;
  FHiddenPanel.Caption := 'hidden toggle';
  FHiddenPanel.SetBounds(24, 178, 180, 54);
  FHiddenPanel.Color := clAqua;
  FHiddenPanel.Visible := False;

  FReparentLeft := TPanel.Create(Self);
  FReparentLeft.Name := 'ReparentLeft';
  FReparentLeft.Parent := Self;
  FReparentLeft.Caption := 'left parent';
  FReparentLeft.SetBounds(230, 178, 150, 54);
  FReparentLeft.Color := clCream;

  FReparentRight := TPanel.Create(Self);
  FReparentRight.Name := 'ReparentRight';
  FReparentRight.Parent := Self;
  FReparentRight.Caption := 'right parent';
  FReparentRight.SetBounds(392, 178, 150, 54);
  FReparentRight.Color := clSilver;

  FReparentButton := TButton.Create(Self);
  FReparentButton.Name := 'ReparentButton';
  FReparentButton.Parent := FReparentLeft;
  FReparentButton.Caption := 'move';
  FReparentButton.SetBounds(14, 18, 84, 26);

  FGraphicLabel := TLabel.Create(Self);
  FGraphicLabel.Name := 'GraphicLabel';
  FGraphicLabel.Parent := FReparentLeft;
  FGraphicLabel.Caption := 'graphic label';
  FGraphicLabel.SetBounds(104, 22, 70, 18);

  FMemo := TMemo.Create(Self);
  FMemo.Name := 'ScrollMemo';
  FMemo.Parent := Self;
  FMemo.SetBounds(574, 178, 250, 54);
  FMemo.ScrollBars := ssBoth;
  FMemo.WordWrap := False;
  FMemo.Lines.Text :=
    'memo scroll line 01'#10'memo scroll line 02'#10'memo scroll line 03'#10+
    'memo scroll line 04'#10'memo scroll line 05'#10'memo scroll line 06'#10+
    'memo scroll line 07'#10'memo scroll line 08'#10'memo scroll line 09'#10+
    'memo scroll line 10';

  FDragSource := TPanel.Create(Self);
  FDragSource.Name := 'DragSource';
  FDragSource.Parent := Self;
  FDragSource.Caption := 'drag source';
  FDragSource.SetBounds(24, 560, 140, 36);
  FDragSource.Color := clFuchsia;
  FDragSource.DragCursor := crHandPoint;

  FDragTarget := TDragProbePanel.Create(Self);
  FDragTarget.Name := 'DragTarget';
  FDragTarget.Parent := Self;
  FDragTarget.Caption := 'drag target';
  FDragTarget.SetBounds(180, 560, 140, 36);
  FDragTarget.Color := clMoneyGreen;
  FDragTarget.OnDragOver := @DragOverProbe;
  FDragTarget.OnDragDrop := @DragDropProbe;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 252, 800, 300);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 400;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;

  Application.OnException := @AppException;
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TWSControlsValidationForm.DragOverProbe(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Inc(FDragOverCount);
  Accept := True;
  Log(Format('drag-over sender=%s source=%s xy=(%d,%d) state=%d accept=%s count=%d',
    [TComponent(Sender).Name, TObject(Source).ClassName, X, Y, Ord(State),
     BoolName(Accept), FDragOverCount]));
end;

procedure TWSControlsValidationForm.DragDropProbe(Sender, Source: TObject; X,
  Y: Integer);
begin
  Inc(FDragDropCount);
  Log(Format('drag-drop sender=%s source=%s xy=(%d,%d) count=%d',
    [TComponent(Sender).Name, TObject(Source).ClassName, X, Y,
     FDragDropCount]));
end;

procedure TWSControlsValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolName(AutoMode));
  LogState('after-show');
  if (not AutoMode) and (CloseInterval > 0) then
    FCloseTimer.Enabled := True;
end;

procedure TWSControlsValidationForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TWSControlsValidationForm.LogState(const AContext: string);
var
  R: TRect;
  PreferredW: Integer;
  PreferredH: Integer;
  TopControl: TControl;
  TopControlName: string;
  ReparentParentName: string;
begin
  PreferredW := 0;
  PreferredH := 0;
  FProbe.GetPreferredSize(PreferredW, PreferredH);
  TopControl := ControlAtPos(Point(665, 85), True, True);
  if TopControl <> nil then
    TopControlName := TopControl.Name
  else
    TopControlName := 'nil';
  if FReparentButton.Parent <> nil then
    ReparentParentName := FReparentButton.Parent.Name
  else
    ReparentParentName := 'nil';
  R := FProbe.ClientRect;
  Log(Format('%s form handle=%s client=%s %s hidden-visible=%s probe handle=%s bounds=%s client=%s preferred=(%d,%d) paintcount=%d top-at-overlap=%s scrollpos=(%d,%d) %s scrollchild=%s reparent-parent=%s reparent-bounds=%s %s reparent-left %s graphic-is-wincontrol=%s graphic-parent=%s memo %s',
    [AContext, BoolName(HandleAllocated), RectText(ClientRect),
     NativeSizeText(Self),
     BoolName(FHiddenPanel.Visible), BoolName(FProbe.HandleAllocated),
     RectText(FProbe.BoundsRect), RectText(R), PreferredW, PreferredH,
     FProbe.PaintCount, TopControlName,
     FScrollBox.HorzScrollBar.Position, FScrollBox.VertScrollBar.Position,
     NativeScrollText(FScrollBox),
     RectText(FScrollChild.BoundsRect), ReparentParentName,
     RectText(FReparentButton.BoundsRect),
     NativeParentText(FReparentButton, TWinControl(FReparentButton.Parent)),
     NativeSizeText(FReparentLeft),
     BoolName(FGraphicLabel.ClassType.InheritsFrom(TWinControl)),
     FGraphicLabel.Parent.Name, NativeScrollText(FMemo)]));
end;

procedure TWSControlsValidationForm.RunStep;
var
  B: TBitmap;
  P: TPanel;
  DragImages: TDragImageList;
  DragBitmap: TBitmap;
  DragObject: TDragProbeObject;
  DragScreenPoint: TPoint;
  DragBegin: Boolean;
  DraggingAfterBegin: Boolean;
  DragMove: Boolean;
  DragEnd: Boolean;
  DraggingAfterEnd: Boolean;
  DragEnterResult: PtrInt;
  DragMoveResult: PtrInt;
  MenuForm: TForm;
  HiddenForm: TForm;
  MainMenu: TMainMenu;
  MenuItem: TMenuItem;
  SubMenuItem: TMenuItem;
begin
  case FStep of
    0:
      begin
        LogState('step0-initial');
        FProbe.Invalidate;
        FProbe.Repaint;
        LogState('step0-after-invalidate-repaint');
      end;
    1:
      begin
        B := TBitmap.Create;
        try
          B.SetSize(260, 120);
          B.Canvas.Brush.Color := clWhite;
          B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
          FProbe.PaintTo(B.Canvas.Handle, 12, 14);
          Log(Format('step1-paintto bitmap-size=(%d,%d) paintcount=%d',
            [B.Width, B.Height, FProbe.PaintCount]));
        finally
          B.Free;
        end;
      end;
    2:
      begin
        Log('step2-paintto-visible-parent ' +
          PaintToSummary(FReparentLeft, FReparentLeft.Width, FReparentLeft.Height));
        Log('step2-paintto-hidden-panel ' +
          PaintToSummary(FHiddenPanel, FHiddenPanel.Width, FHiddenPanel.Height));
        FHiddenPanel.Visible := True;
        try
          Application.ProcessMessages;
          FHiddenPanel.Repaint;
          Application.ProcessMessages;
          Log('step2-paintto-hidden-panel-temporarily-shown ' +
            PaintToSummary(FHiddenPanel, FHiddenPanel.Width, FHiddenPanel.Height));
        finally
          FHiddenPanel.Visible := False;
        end;
        P := TPanel.Create(Self);
        try
          P.SetBounds(0, 0, 90, 40);
          P.Caption := 'unparented';
          Log('step2-paintto-unparented-panel ' +
            PaintToSummary(P, 90, 40));
        finally
          P.Free;
        end;
      end;
    3:
      begin
        FProbe.SetBounds(30, 44, 180, 64);
        FScrollChild.SetBounds(80, 90, 460, 260);
        LogState('step3-after-bounds');
      end;
    4:
      begin
        FScrollBox.ScrollBy(-40, -50);
        LogState('step4-after-scrollbox-scrollby');
      end;
    5:
      begin
        FScrollBox.ScrollBy(20, 25);
        LogState('step5-after-scrollbox-scrollby-back');
      end;
    6:
      begin
        FPanel.ScrollBy(12, 18);
        LogState('step6-after-nonscroll-panel-scrollby');
      end;
    7:
      begin
        FBackPanel.BringToFront;
        LogState('step7-after-back-bringtofront');
        FFrontPanel.BringToFront;
        LogState('step7-after-front-bringtofront');
      end;
    8:
      begin
        FReparentButton.Parent := FReparentRight;
        FReparentButton.SetBounds(20, 16, 84, 26);
        LogState('step8-after-button-reparent-right');
        FReparentButton.Parent := FReparentLeft;
        FReparentButton.SetBounds(14, 18, 84, 26);
        LogState('step8-after-button-reparent-left');
      end;
    9:
      begin
        FMemo.ScrollBy(0, -40);
        LogState('step9-after-memo-scrollby-down');
        FMemo.ScrollBy(0, 20);
        LogState('step9-after-memo-scrollby-up');
      end;
    10:
      begin
        FHiddenPanel.Visible := True;
        Application.ProcessMessages;
        FHiddenPanel.Repaint;
        Application.ProcessMessages;
        LogState('step10-hidden-shown');
        Log('step10-paintto-hidden-panel-shown-later ' +
          PaintToSummary(FHiddenPanel, FHiddenPanel.Width, FHiddenPanel.Height));
        FHiddenPanel.Visible := False;
        LogState('step10-hidden-hidden');
      end;
    11:
      begin
        FReparentLeft.Constraints.MinWidth := 180;
        FReparentLeft.Constraints.MinHeight := 72;
        Application.ProcessMessages;
        LogState('step11-after-child-min-constraints');
        FReparentLeft.Constraints.MinWidth := 0;
        FReparentLeft.Constraints.MinHeight := 0;

        Constraints.MinWidth := 500;
        Constraints.MinHeight := 420;
        Constraints.MaxWidth := 0;
        Constraints.MaxHeight := 0;
        SetBounds(120, 120, 420, 340);
        LogState('step11-after-too-small-form-bounds');
        Constraints.MaxWidth := 700;
        Constraints.MaxHeight := 500;
        Application.ProcessMessages;
        SetBounds(120, 120, 900, 700);
        Application.ProcessMessages;
        LogState('step11-after-too-large-form-bounds');
        Constraints.MinWidth := 640;
        Constraints.MaxWidth := 640;
        Constraints.MinHeight := 480;
        Constraints.MaxHeight := 480;
        Application.ProcessMessages;
        SetBounds(120, 120, 760, 560);
        Application.ProcessMessages;
        LogState('step11-after-fixed-form-bounds');
        Constraints.MinWidth := 500;
        Constraints.MinHeight := 420;
        Constraints.MaxWidth := 0;
        Constraints.MaxHeight := 0;
        SetBounds(120, 120, 860, 620);
        LogState('step11-after-restore-form-bounds');
      end;
    12:
      begin
        FReparentButton.AccessibleName := 'Accessible Move Button';
        FReparentButton.AccessibleDescription := 'Button used by GTK4 WSControls validation';
        FReparentButton.AccessibleValue := 'ready';
        Log('step12-accessible-button-after-set ' + AccessibleText(FReparentButton));

        FGraphicLabel.AccessibleName := 'Accessible Graphic Label';
        FGraphicLabel.AccessibleDescription := 'Graphic label hosted by parent panel';
        FGraphicLabel.AccessibleValue := 'label-value';
        Log('step12-accessible-label-after-set ' + AccessibleText(FGraphicLabel));

        FReparentButton.AccessibleName := '';
        FReparentButton.AccessibleDescription := '';
        FReparentButton.AccessibleValue := '';
        Log('step12-accessible-button-after-reset ' + AccessibleText(FReparentButton));
      end;
    13:
      begin
        try
          Log('step13-drag-image begin setup');
          DragImages := TDragImageList.Create(Self);
          DragBitmap := TBitmap.Create;
          try
            DragImages.Width := 16;
            DragImages.Height := 16;
            DragImages.DragCursor := crHandPoint;
            DragBitmap.SetSize(16, 16);
            DragBitmap.Canvas.Brush.Color := clRed;
            DragBitmap.Canvas.FillRect(Rect(0, 0, 16, 16));
            Log('step13-drag-image before add');
            DragImages.Add(DragBitmap, nil);
            Log('step13-drag-image before setdragimage');
            DragImages.SetDragImage(0, 4, 4);
            Log('step13-drag-image before begindrag');
            DragBegin := DragImages.BeginDrag(Handle, 40, 40);
            DraggingAfterBegin := DragImages.Dragging;
            DragMove := False;
            DragEnd := False;
            if DraggingAfterBegin then
            begin
              Log('step13-drag-image before dragmove');
              DragMove := DragImages.DragMove(48, 52);
              DragImages.HideDragImage;
              DragImages.ShowDragImage;
              Log('step13-drag-image before enddrag');
              DragEnd := DragImages.EndDrag;
            end
            else
              Log('step13-drag-image skip move/show/end because begin failed');
            DraggingAfterEnd := DragImages.Dragging;
            Log(Format('step13-drag-image begin=%s dragging-after-begin=%s move=%s end=%s dragging-after-end=%s cursor=%d',
              [BoolName(DragBegin), BoolName(DraggingAfterBegin),
               BoolName(DragMove), BoolName(DragEnd), BoolName(DraggingAfterEnd),
               Ord(DragImages.DragCursor)]));
          finally
            DragBitmap.Free;
            DragImages.Free;
          end;
        except
          on E: Exception do
            Log('step13-drag-image exception ' + E.ClassName + ' ' + E.Message);
        end;

        DragObject := TDragProbeObject.Create(FDragSource);
        try
          DragScreenPoint := FDragTarget.ClientToScreen(Point(12, 14));
          DragEnterResult := FDragTarget.ProbeDragMessage(dmDragEnter,
            DragScreenPoint, DragObject, FDragTarget);
          DragMoveResult := FDragTarget.ProbeDragMessage(dmDragMove,
            FDragTarget.ClientToScreen(Point(18, 16)), DragObject, FDragTarget);
          FDragTarget.ProbeDragMessage(dmDragDrop,
            FDragTarget.ClientToScreen(Point(22, 18)), DragObject, FDragTarget);
          Log(Format('step13-drag-message enter-result=%d move-result=%d over-count=%d drop-count=%d cursor-accept=%d cursor-reject=%d source-dragcursor=%d',
            [DragEnterResult, DragMoveResult, FDragOverCount, FDragDropCount,
             Ord(DragObject.ProbeCursor(True, 0, 0)),
             Ord(DragObject.ProbeCursor(False, 0, 0)),
             Ord(FDragSource.DragCursor)]));
        finally
          DragObject.Free;
        end;
      end;
    14:
      begin
        MenuForm := TForm.Create(Self);
        try
          MenuForm.Name := 'ConstraintMenuForm';
          MenuForm.Caption := 'Constraint menu form';
          MenuForm.Position := poDesigned;
          MenuForm.SetBounds(200, 200, 360, 240);
          MenuForm.Constraints.MinWidth := 320;
          MenuForm.Constraints.MinHeight := 180;
          MenuForm.Constraints.MaxWidth := 400;
          MenuForm.Constraints.MaxHeight := 220;

          MainMenu := TMainMenu.Create(MenuForm);
          MenuItem := TMenuItem.Create(MainMenu);
          MenuItem.Caption := 'File';
          SubMenuItem := TMenuItem.Create(MenuItem);
          SubMenuItem.Caption := 'New';
          MenuItem.Add(SubMenuItem);
          MainMenu.Items.Add(MenuItem);
          MenuItem := TMenuItem.Create(MainMenu);
          MenuItem.Caption := 'Edit';
          SubMenuItem := TMenuItem.Create(MenuItem);
          SubMenuItem.Caption := 'Copy';
          MenuItem.Add(SubMenuItem);
          MainMenu.Items.Add(MenuItem);
          MenuForm.Menu := MainMenu;

          Log('step14-menuform-before-show handle=' +
            BoolName(MenuForm.HandleAllocated) + ' client=' +
            RectText(MenuForm.ClientRect));
          MenuForm.Show;
          Application.ProcessMessages;
          Log('step14-menuform-after-show client=' +
            RectText(MenuForm.ClientRect) + ' ' +
            NativeSizeText(MenuForm) + ' ' +
            NativeWindowMenuText(MenuForm));
          MenuForm.SetBounds(200, 200, 460, 280);
          Application.ProcessMessages;
          Log('step14-menuform-after-too-large-bounds client=' +
            RectText(MenuForm.ClientRect) + ' ' +
            NativeSizeText(MenuForm) + ' ' +
            NativeWindowMenuText(MenuForm));
          MenuForm.SetBounds(200, 200, 280, 140);
          Application.ProcessMessages;
          Log('step14-menuform-after-too-small-bounds client=' +
            RectText(MenuForm.ClientRect) + ' ' +
            NativeSizeText(MenuForm) + ' ' +
            NativeWindowMenuText(MenuForm));
        finally
          MenuForm.Free;
        end;

        HiddenForm := TForm.Create(Self);
        try
          HiddenForm.Name := 'ConstraintHiddenStartupForm';
          HiddenForm.Caption := 'Constraint hidden startup form';
          HiddenForm.Position := poDesigned;
          HiddenForm.Constraints.MinWidth := 420;
          HiddenForm.Constraints.MinHeight := 260;
          HiddenForm.Constraints.MaxWidth := 480;
          HiddenForm.Constraints.MaxHeight := 320;
          HiddenForm.SetBounds(240, 240, 300, 200);
          Log('step14-hiddenform-before-show handle=' +
            BoolName(HiddenForm.HandleAllocated) + ' client=' +
            RectText(HiddenForm.ClientRect));
          HiddenForm.Show;
          Application.ProcessMessages;
          Log('step14-hiddenform-after-show client=' +
            RectText(HiddenForm.ClientRect) + ' ' +
            NativeSizeText(HiddenForm) + ' ' +
            NativeWindowMenuText(HiddenForm));
          HiddenForm.SetBounds(240, 240, 520, 360);
          Application.ProcessMessages;
          Log('step14-hiddenform-after-too-large-bounds client=' +
            RectText(HiddenForm.ClientRect) + ' ' +
            NativeSizeText(HiddenForm) + ' ' +
            NativeWindowMenuText(HiddenForm));
        finally
          HiddenForm.Free;
        end;
      end;
  else
    begin
      Log('DONE');
      FAutoTimer.Enabled := False;
      if AutoMode then
        Close;
    end;
  end;
  Inc(FStep);
end;

procedure TWSControlsValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunStep;
  finally
    if (FStep <= 15) and AutoMode then
      FAutoTimer.Enabled := True;
  end;
end;

procedure TWSControlsValidationForm.CloseTimer(Sender: TObject);
begin
  Close;
end;

procedure TWSControlsValidationForm.AppException(Sender: TObject; E: Exception);
begin
  Log('APPLICATION_EXCEPTION ' + E.ClassName + ' ' + E.Message);
  Halt(1);
end;

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TWSControlsValidationForm, WSControlsValidationForm);
  Application.Run;
end.
