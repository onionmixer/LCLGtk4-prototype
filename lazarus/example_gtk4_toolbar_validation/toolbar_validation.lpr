program toolbar_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Types, Forms, Controls, StdCtrls, ExtCtrls,
  Buttons,
  ComCtrls, Graphics, ImgList, Menus, GraphType;

type
  TProbeToolButton = class(TToolButton)
  public
    procedure ProbeMouseEnter;
    procedure ProbeMouseLeave;
  end;

  TToolBarValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FDisabledImages: TImageList;
    FHotImages: TImageList;
    FImages: TImageList;
    FImages2: TImageList;
    FLog: TMemo;
    FMenu: TPopupMenu;
    FMenuDynamicItem: TMenuItem;
    FMenuHiddenItem: TMenuItem;
    FMenuSubItem: TMenuItem;
    FMenuSubMenu: TMenuItem;
    FMutationTimer: TTimer;
    FNarrowHost: TPanel;
    FNarrowToolBar: TToolBar;
    FSpeedButton: TSpeedButton;
    FToolBar: TToolBar;
    FVisualToolBar: TToolBar;
    FButton: TToolButton;
    FCheck: TToolButton;
    FSeparator: TToolButton;
    FDropDown: TToolButton;
    FButtonDrop: TToolButton;
    FDisabled: TToolButton;
    FVisualNormal: TToolButton;
    FVisualHot: TProbeToolButton;
    FVisualDisabled: TToolButton;
    FDestroyToolBar: TToolBar;
    FDestroySelfBtn: TToolButton;
    FDestroySibBtn: TToolButton;
    FDoomedBtn: TToolButton;
    FDestroyHardBtn: TToolButton;
    FDestroyWinBtn: TButton;
    FDestroyWinHardBtn: TButton;
    FDestroyClicks: Integer;
    FClickCount: Integer;
    FArrowClickCount: Integer;
    FMouseDownCount: Integer;
    FMouseEnterCount: Integer;
    FMouseLeaveCount: Integer;
    FMouseMoveCount: Integer;
    FMouseUpCount: Integer;
    FMenuCloseCount: Integer;
    FMenuItemClickCount: Integer;
    FMenuMutationCount: Integer;
    FMenuPopupCount: Integer;
    FSubMenuItemClickCount: Integer;
    FPaintButtonCount: Integer;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AppShowHint(var HintStr: string; var CanShow: Boolean;
      var HintInfo: THintInfo);
    procedure ArrowClick(Sender: TObject);
    procedure AutoTimer(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure DestroyHardClick(Sender: TObject);
    procedure DestroySelfClick(Sender: TObject);
    procedure DestroySibClick(Sender: TObject);
    procedure DestroyWinClick(Sender: TObject);
    procedure DestroyWinHardClick(Sender: TObject);
    procedure LogDestructionState(const AContext: string);
    procedure WriteDestructionCoords;
    procedure Log(const S: string);
    procedure LogState(const AContext: string);
    procedure LogToolBarState(const AContext, AName: string; AToolBar: TToolBar);
    procedure MouseDownLog(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MouseEnterLog(Sender: TObject);
    procedure MouseLeaveLog(Sender: TObject);
    procedure MouseMoveLog(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MouseUpLog(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuCloseLog(Sender: TObject);
    procedure MenuItemClick(Sender: TObject);
    procedure MenuMutationTimer(Sender: TObject);
    procedure MenuPopupLog(Sender: TObject);
    procedure PaintButton(Sender: TToolButton; State: Integer);
    procedure SubMenuItemClick(Sender: TObject);
    procedure RunChecks;
    procedure LogVisualHotIcon(const AContext: string);
    procedure SaveVisualSnapshot;
    procedure SetupImages(AImages: TImageList; AFirstColor, ASecondColor: TColor);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  ToolBarValidationForm: TToolBarValidationForm;

procedure TProbeToolButton.ProbeMouseEnter;
begin
  MouseEnter;
end;

procedure TProbeToolButton.ProbeMouseLeave;
begin
  MouseLeave;
end;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('TOOLBAR_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('TOOLBAR_VALIDATION_CLOSE_MS'), 0);
end;

function ForceHotSnapshot: Boolean;
begin
  Result := GetEnvironmentVariable('TOOLBAR_FORCE_HOT_SNAPSHOT') = '1';
end;

function DestructionProbe: Boolean;
begin
  Result := GetEnvironmentVariable('TOOLBAR_DESTRUCTION_PROBE') = '1';
end;

function DestructionCoordsPath: string;
begin
  Result := GetEnvironmentVariable('TOOLBAR_DESTRUCTION_COORDS');
end;

function ForceHotOnShow: Boolean;
begin
  Result := GetEnvironmentVariable('TOOLBAR_FORCE_HOT_ON_SHOW') = '1';
end;

function BoolName(AValue: Boolean): string;
begin
  Result := BoolToStr(AValue, True);
end;

function StyleName(AStyle: TToolButtonStyle): string;
begin
  case AStyle of
    tbsButton: Result := 'button';
    tbsCheck: Result := 'check';
    tbsDropDown: Result := 'dropdown';
    tbsSeparator: Result := 'separator';
    tbsDivider: Result := 'divider';
    tbsButtonDrop: Result := 'buttondrop';
  else
    Result := 'unknown';
  end;
end;

constructor TToolBarValidationForm.Create(AOwner: TComponent);
var
  Btn: TToolButton;
  Item: TMenuItem;

  procedure AddNarrowButton(const ACaption: string; AStyle: TToolButtonStyle;
    AImageIndex: Integer; AEnabled: Boolean);
  begin
    Btn := TToolButton.Create(Self);
    Btn.Parent := FNarrowToolBar;
    Btn.Caption := ACaption;
    Btn.Style := AStyle;
    Btn.ImageIndex := AImageIndex;
    Btn.Enabled := AEnabled;
    Btn.OnClick := @ButtonClick;
    Btn.OnMouseDown := @MouseDownLog;
    Btn.OnMouseUp := @MouseUpLog;
    if AStyle in [tbsDropDown, tbsButtonDrop] then
    begin
      Btn.DropdownMenu := FMenu;
      Btn.OnArrowClick := @ArrowClick;
    end;
  end;
begin
  inherited Create(AOwner);
  Caption := 'GTK4 ToolBar validation';
  Position := poDesigned;
  SetBounds(100, 100, 860, 760);

  FImages := TImageList.Create(Self);
  FImages.Width := 16;
  FImages.Height := 16;
  SetupImages(FImages, clRed, clBlue);

  FImages2 := TImageList.Create(Self);
  FImages2.Width := 16;
  FImages2.Height := 16;
  SetupImages(FImages2, clGreen, clPurple);

  FHotImages := TImageList.Create(Self);
  FHotImages.Width := 16;
  FHotImages.Height := 16;
  SetupImages(FHotImages, clLime, clYellow);

  FDisabledImages := TImageList.Create(Self);
  FDisabledImages.Width := 16;
  FDisabledImages.Height := 16;
  SetupImages(FDisabledImages, clGray, clSilver);

  FMenu := TPopupMenu.Create(Self);
  FMenu.OnClose := @MenuCloseLog;
  FMenu.OnPopup := @MenuPopupLog;
  Item := TMenuItem.Create(FMenu);
  Item.Caption := 'Menu item';
  Item.OnClick := @MenuItemClick;
  FMenu.Items.Add(Item);
  FMenuDynamicItem := TMenuItem.Create(FMenu);
  FMenuDynamicItem.Caption := 'Dynamic item';
  FMenuDynamicItem.OnClick := @MenuItemClick;
  FMenu.Items.Add(FMenuDynamicItem);
  FMenuHiddenItem := TMenuItem.Create(FMenu);
  FMenuHiddenItem.Caption := 'Hidden until mutation';
  FMenuHiddenItem.Visible := False;
  FMenuHiddenItem.OnClick := @MenuItemClick;
  FMenu.Items.Add(FMenuHiddenItem);
  FMenuSubMenu := TMenuItem.Create(FMenu);
  FMenuSubMenu.Caption := 'Sub menu';
  FMenuSubItem := TMenuItem.Create(FMenu);
  FMenuSubItem.Caption := 'Sub item';
  FMenuSubItem.OnClick := @SubMenuItemClick;
  FMenuSubMenu.Add(FMenuSubItem);
  FMenu.Items.Add(FMenuSubMenu);

  FToolBar := TToolBar.Create(Self);
  FToolBar.Parent := Self;
  FToolBar.SetBounds(24, 24, 620, 72);
  FToolBar.Images := FImages;
  FToolBar.ShowCaptions := True;
  FToolBar.ButtonWidth := 76;
  FToolBar.ButtonHeight := 44;
  FToolBar.Wrapable := True;
  FToolBar.OnPaintButton := @PaintButton;

  FButton := TToolButton.Create(Self);
  FButton.Parent := FToolBar;
  FButton.Caption := 'Run';
  FButton.Hint := 'Run tool button hint';
  FButton.ShowHint := True;
  FButton.ImageIndex := 0;
  FButton.OnClick := @ButtonClick;
  FButton.OnMouseDown := @MouseDownLog;
  FButton.OnMouseUp := @MouseUpLog;

  FCheck := TToolButton.Create(Self);
  FCheck.Parent := FToolBar;
  FCheck.Caption := 'Check';
  FCheck.Hint := 'Check tool button hint';
  FCheck.ShowHint := True;
  FCheck.Style := tbsCheck;
  FCheck.ImageIndex := 1;
  FCheck.OnClick := @ButtonClick;
  FCheck.OnMouseDown := @MouseDownLog;
  FCheck.OnMouseUp := @MouseUpLog;

  FSeparator := TToolButton.Create(Self);
  FSeparator.Parent := FToolBar;
  FSeparator.Style := tbsSeparator;

  FDropDown := TToolButton.Create(Self);
  FDropDown.Parent := FToolBar;
  FDropDown.Caption := 'Drop';
  FDropDown.Hint := 'Drop tool button hint';
  FDropDown.ShowHint := True;
  FDropDown.Style := tbsDropDown;
  FDropDown.DropdownMenu := FMenu;
  FDropDown.ImageIndex := 0;
  FDropDown.OnClick := @ButtonClick;
  FDropDown.OnArrowClick := @ArrowClick;
  FDropDown.OnMouseDown := @MouseDownLog;
  FDropDown.OnMouseUp := @MouseUpLog;

  FButtonDrop := TToolButton.Create(Self);
  FButtonDrop.Parent := FToolBar;
  FButtonDrop.Caption := 'Split';
  FButtonDrop.Hint := 'Split tool button hint';
  FButtonDrop.ShowHint := True;
  FButtonDrop.Style := tbsButtonDrop;
  FButtonDrop.DropdownMenu := FMenu;
  FButtonDrop.ImageIndex := 1;
  FButtonDrop.OnClick := @ButtonClick;
  FButtonDrop.OnArrowClick := @ArrowClick;
  FButtonDrop.OnMouseDown := @MouseDownLog;
  FButtonDrop.OnMouseUp := @MouseUpLog;

  FDisabled := TToolButton.Create(Self);
  FDisabled.Parent := FToolBar;
  FDisabled.Caption := 'Off';
  FDisabled.Hint := 'Disabled tool button hint';
  FDisabled.ShowHint := True;
  FDisabled.ImageIndex := 0;
  FDisabled.Enabled := False;
  FDisabled.OnClick := @ButtonClick;
  FDisabled.OnMouseDown := @MouseDownLog;
  FDisabled.OnMouseUp := @MouseUpLog;

  FNarrowHost := TPanel.Create(Self);
  FNarrowHost.Parent := Self;
  FNarrowHost.SetBounds(24, 456, 260, 260);
  FNarrowHost.BevelOuter := bvLowered;

  FNarrowToolBar := TToolBar.Create(Self);
  FNarrowToolBar.Parent := FNarrowHost;
  FNarrowToolBar.Align := alNone;
  FNarrowToolBar.SetBounds(2, 2, 220, 144);
  FNarrowToolBar.Images := FImages;
  FNarrowToolBar.ShowCaptions := True;
  FNarrowToolBar.ButtonWidth := 76;
  FNarrowToolBar.ButtonHeight := 44;
  FNarrowToolBar.Wrapable := True;
  FNarrowToolBar.OnPaintButton := @PaintButton;

  AddNarrowButton('N1', tbsButton, 0, True);
  AddNarrowButton('N2', tbsCheck, 1, True);
  AddNarrowButton('', tbsSeparator, -1, True);
  AddNarrowButton('N3', tbsDropDown, 0, True);
  AddNarrowButton('N4', tbsButtonDrop, 1, True);
  AddNarrowButton('Off', tbsButton, 0, False);

  FVisualToolBar := TToolBar.Create(Self);
  FVisualToolBar.Parent := Self;
  FVisualToolBar.Align := alNone;
  FVisualToolBar.SetBounds(320, 456, 220, 56);
  FVisualToolBar.Images := FImages;
  FVisualToolBar.HotImages := FHotImages;
  FVisualToolBar.DisabledImages := FDisabledImages;
  FVisualToolBar.ShowCaptions := False;
  FVisualToolBar.ButtonWidth := 44;
  FVisualToolBar.ButtonHeight := 36;
  FVisualToolBar.Wrapable := False;

  FVisualNormal := TToolButton.Create(Self);
  FVisualNormal.Parent := FVisualToolBar;
  FVisualNormal.Caption := 'VisualNormal';
  FVisualNormal.Hint := 'Visual normal hint';
  FVisualNormal.ShowHint := True;
  FVisualNormal.ImageIndex := 0;
  FVisualNormal.OnMouseDown := @MouseDownLog;
  FVisualNormal.OnMouseEnter := @MouseEnterLog;
  FVisualNormal.OnMouseLeave := @MouseLeaveLog;
  FVisualNormal.OnMouseMove := @MouseMoveLog;
  FVisualNormal.OnMouseUp := @MouseUpLog;

  FVisualHot := TProbeToolButton.Create(Self);
  FVisualHot.Parent := FVisualToolBar;
  FVisualHot.Caption := 'VisualHot';
  FVisualHot.Hint := 'Visual hot hint';
  FVisualHot.ShowHint := True;
  FVisualHot.ImageIndex := 0;
  FVisualHot.OnMouseDown := @MouseDownLog;
  FVisualHot.OnMouseEnter := @MouseEnterLog;
  FVisualHot.OnMouseLeave := @MouseLeaveLog;
  FVisualHot.OnMouseMove := @MouseMoveLog;
  FVisualHot.OnMouseUp := @MouseUpLog;

  FVisualDisabled := TToolButton.Create(Self);
  FVisualDisabled.Parent := FVisualToolBar;
  FVisualDisabled.Caption := 'VisualDisabled';
  FVisualDisabled.Hint := 'Visual disabled hint';
  FVisualDisabled.ShowHint := True;
  FVisualDisabled.ImageIndex := 0;
  FVisualDisabled.Enabled := False;
  FVisualDisabled.OnMouseDown := @MouseDownLog;
  FVisualDisabled.OnMouseEnter := @MouseEnterLog;
  FVisualDisabled.OnMouseLeave := @MouseLeaveLog;
  FVisualDisabled.OnMouseMove := @MouseMoveLog;
  FVisualDisabled.OnMouseUp := @MouseUpLog;

  FSpeedButton := TSpeedButton.Create(Self);
  FSpeedButton.Parent := Self;
  FSpeedButton.SetBounds(560, 456, 120, 32);
  FSpeedButton.Caption := 'Speed hint';
  FSpeedButton.Hint := 'Standalone speed button hint';
  FSpeedButton.ShowHint := True;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 128, 780, 300);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  if DestructionProbe then
  begin
    FDestroyToolBar := TToolBar.Create(Self);
    FDestroyToolBar.Parent := Self;
    FDestroyToolBar.Align := alNone;
    FDestroyToolBar.SetBounds(24, 520, 400, 56);
    FDestroyToolBar.ShowCaptions := True;
    FDestroyToolBar.ButtonWidth := 84;
    FDestroyToolBar.ButtonHeight := 48;
    FDestroyToolBar.Wrapable := False;

    { TToolBar stacks new buttons leftward; creation order is irrelevant here
      because click coordinates are computed per button after layout. }
    FDestroySelfBtn := TToolButton.Create(Self);
    FDestroySelfBtn.Parent := FDestroyToolBar;
    FDestroySelfBtn.Name := 'DestroySelfBtn';
    FDestroySelfBtn.Caption := 'SELF';
    FDestroySelfBtn.OnClick := @DestroySelfClick;

    FDestroySibBtn := TToolButton.Create(Self);
    FDestroySibBtn.Parent := FDestroyToolBar;
    FDestroySibBtn.Name := 'DestroySibBtn';
    FDestroySibBtn.Caption := 'SIB';
    FDestroySibBtn.OnClick := @DestroySibClick;

    FDoomedBtn := TToolButton.Create(Self);
    FDoomedBtn.Parent := FDestroyToolBar;
    FDoomedBtn.Name := 'DoomedBtn';
    FDoomedBtn.Caption := 'DOOM';
    FDoomedBtn.OnClick := @ButtonClick;

    FDestroyHardBtn := TToolButton.Create(Self);
    FDestroyHardBtn.Parent := FDestroyToolBar;
    FDestroyHardBtn.Name := 'DestroyHardBtn';
    FDestroyHardBtn.Caption := 'HARD';
    FDestroyHardBtn.OnClick := @DestroyHardClick;

    FDestroyWinBtn := TButton.Create(Self);
    FDestroyWinBtn.Parent := Self;
    FDestroyWinBtn.Name := 'DestroyWinBtn';
    FDestroyWinBtn.Caption := 'WBTN';
    FDestroyWinBtn.SetBounds(24, 590, 110, 36);
    FDestroyWinBtn.OnClick := @DestroyWinClick;

    FDestroyWinHardBtn := TButton.Create(Self);
    FDestroyWinHardBtn.Parent := Self;
    FDestroyWinHardBtn.Name := 'DestroyWinHardBtn';
    FDestroyWinHardBtn.Caption := 'WHARD';
    FDestroyWinHardBtn.SetBounds(160, 590, 110, 36);
    FDestroyWinHardBtn.OnClick := @DestroyWinHardClick;
  end;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 500;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;

  FMutationTimer := TTimer.Create(Self);
  FMutationTimer.Enabled := False;
  FMutationTimer.Interval := 250;
  FMutationTimer.OnTimer := @MenuMutationTimer;

  Application.OnException := @AppException;
  Application.OnShowHint := @AppShowHint;
  Application.ShowHint := True;
  Application.HintPause := 500;
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TToolBarValidationForm.SetupImages(AImages: TImageList;
  AFirstColor, ASecondColor: TColor);
var
  B: TBitmap;
begin
  B := TBitmap.Create;
  try
    B.SetSize(16, 16);
    B.Canvas.Brush.Color := AFirstColor;
    B.Canvas.FillRect(Rect(0, 0, 16, 16));
    AImages.Add(B, nil);
    B.Canvas.Brush.Color := ASecondColor;
    B.Canvas.FillRect(Rect(0, 0, 16, 16));
    AImages.Add(B, nil);
  finally
    B.Free;
  end;
end;

procedure TToolBarValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolName(AutoMode));
  LogState('after-show');
  if ForceHotOnShow and (FVisualHot <> nil) then
  begin
    LogVisualHotIcon('show-before-force-hot');
    FVisualHot.ProbeMouseEnter;
    LogVisualHotIcon('show-after-force-hot');
  end;
  if DestructionProbe then
  begin
    Application.ProcessMessages;
    WriteDestructionCoords;
    LogDestructionState('after-show');
  end;
  if (not AutoMode) and (CloseInterval > 0) then
    FCloseTimer.Enabled := True;
end;

procedure TToolBarValidationForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TToolBarValidationForm.LogState(const AContext: string);
begin
  LogToolBarState(AContext, 'main', FToolBar);
  if Assigned(FNarrowToolBar) then
    LogToolBarState(AContext, 'narrow', FNarrowToolBar);
  if Assigned(FVisualToolBar) then
    LogToolBarState(AContext, 'visual', FVisualToolBar);
end;

procedure TToolBarValidationForm.LogToolBarState(const AContext,
  AName: string; AToolBar: TToolBar);
var
  I: Integer;
  ImageCount: Integer;
  B: TToolButton;
begin
  if AToolBar.Images <> nil then
    ImageCount := AToolBar.Images.Count
  else
    ImageCount := -1;
  Log(Format('%s %s toolbar handle=%s buttons=%d childcontrols=%d rowcount=%d size=(%d,%d) buttonsize=(%d,%d) showcaptions=%s list=%s wrapable=%s clicks=%d arrows=%d mousedown=%d mouseup=%d mouseenter=%d mousemove=%d mouseleave=%d menuPopup=%d menuClose=%d menuItemClick=%d submenuClick=%d menuMutation=%d paints=%d images=%d',
    [AContext, AName, BoolName(AToolBar.HandleAllocated), AToolBar.ButtonCount,
     AToolBar.ControlCount, AToolBar.RowCount, AToolBar.Width, AToolBar.Height,
     AToolBar.ButtonWidth, AToolBar.ButtonHeight, BoolName(AToolBar.ShowCaptions),
     BoolName(AToolBar.List), BoolName(AToolBar.Wrapable),
     FClickCount, FArrowClickCount, FMouseDownCount, FMouseUpCount,
     FMouseEnterCount, FMouseMoveCount, FMouseLeaveCount,
     FMenuPopupCount, FMenuCloseCount, FMenuItemClickCount,
     FSubMenuItemClickCount, FMenuMutationCount,
     FPaintButtonCount, ImageCount]));
  for I := 0 to AToolBar.ButtonCount - 1 do
  begin
    B := AToolBar.Buttons[I];
    Log(Format('%s %s button[%d] name=%s caption="%s" style=%s down=%s enabled=%s visible=%s image=%d bounds=(%d,%d,%d,%d)',
      [AContext, AName, I, B.Name, B.Caption, StyleName(B.Style), BoolName(B.Down),
       BoolName(B.Enabled), BoolName(B.Visible), B.ImageIndex,
       B.Left, B.Top, B.Width, B.Height]));
  end;
end;

procedure TToolBarValidationForm.RunChecks;
begin
  LogState('initial');

  FButton.Click;
  FCheck.Click;
  FDropDown.Click;
  FDropDown.ArrowClick;
  FButtonDrop.Click;
  FButtonDrop.ArrowClick;
  Application.ProcessMessages;
  LogState('after-programmatic-clicks');

  FToolBar.Images := FImages2;
  FToolBar.ShowCaptions := False;
  FToolBar.List := True;
  FToolBar.SetButtonSize(52, 36);
  FToolBar.Wrapable := False;
  Application.ProcessMessages;
  LogState('after-layout-images-change');

  FToolBar.Width := 220;
  FToolBar.Wrapable := True;
  FToolBar.ShowCaptions := True;
  Application.ProcessMessages;
  LogState('after-narrow-wrap');

  FNarrowToolBar.SetBounds(2, 2, 220, 144);
  FNarrowToolBar.Wrapable := True;
  FNarrowToolBar.ShowCaptions := True;
  FNarrowToolBar.List := False;
  FNarrowToolBar.SetButtonSize(76, 44);
  Application.ProcessMessages;
  LogState('after-independent-narrow-wrap');

  Application.Terminate;
end;

procedure TToolBarValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunChecks;
  except
    on E: Exception do
    begin
      Log('EXCEPTION ' + E.ClassName + ': ' + E.Message);
      Application.Terminate;
    end;
  end;
end;

procedure TToolBarValidationForm.ButtonClick(Sender: TObject);
begin
  Inc(FClickCount);
  if Sender is TToolButton then
    Log(Format('OnClick %s down=%s',
      [TToolButton(Sender).Caption, BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.ArrowClick(Sender: TObject);
begin
  Inc(FArrowClickCount);
  if Sender is TToolButton then
    Log(Format('OnArrowClick %s down=%s',
      [TToolButton(Sender).Caption, BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MouseDownLog(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Inc(FMouseDownCount);
  if Sender is TToolButton then
    Log(Format('OnMouseDown %s button=%d pos=(%d,%d) down=%s',
      [TToolButton(Sender).Caption, Ord(Button), X, Y,
       BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MouseEnterLog(Sender: TObject);
begin
  Inc(FMouseEnterCount);
  if Sender is TToolButton then
    Log(Format('OnMouseEnter %s down=%s',
      [TToolButton(Sender).Caption, BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MouseLeaveLog(Sender: TObject);
begin
  Inc(FMouseLeaveCount);
  if Sender is TToolButton then
    Log(Format('OnMouseLeave %s down=%s',
      [TToolButton(Sender).Caption, BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MouseMoveLog(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  Inc(FMouseMoveCount);
  if Sender is TToolButton then
    Log(Format('OnMouseMove %s pos=(%d,%d) down=%s',
      [TToolButton(Sender).Caption, X, Y, BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MouseUpLog(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Inc(FMouseUpCount);
  if Sender is TToolButton then
    Log(Format('OnMouseUp %s button=%d pos=(%d,%d) down=%s',
      [TToolButton(Sender).Caption, Ord(Button), X, Y,
       BoolName(TToolButton(Sender).Down)]));
end;

procedure TToolBarValidationForm.MenuCloseLog(Sender: TObject);
begin
  Inc(FMenuCloseCount);
  FMutationTimer.Enabled := False;
  Log(Format('OnMenuClose popupPoint=(%d,%d) mutation=%d hiddenVisible=%s dynamicCaption="%s"',
    [FMenu.PopupPoint.X, FMenu.PopupPoint.Y, FMenuMutationCount,
     BoolName(FMenuHiddenItem.Visible), FMenuDynamicItem.Caption]));
end;

procedure TToolBarValidationForm.MenuItemClick(Sender: TObject);
begin
  Inc(FMenuItemClickCount);
  if Sender is TMenuItem then
    Log('OnMenuItemClick ' + TMenuItem(Sender).Caption)
  else
    Log('OnMenuItemClick');
end;

procedure TToolBarValidationForm.SubMenuItemClick(Sender: TObject);
begin
  Inc(FSubMenuItemClickCount);
  if Sender is TMenuItem then
    Log('OnSubMenuItemClick ' + TMenuItem(Sender).Caption)
  else
    Log('OnSubMenuItemClick');
end;

procedure TToolBarValidationForm.MenuMutationTimer(Sender: TObject);
begin
  FMutationTimer.Enabled := False;
  Inc(FMenuMutationCount);
  FMenuDynamicItem.Caption := 'Dynamic mutated ' + IntToStr(FMenuMutationCount);
  FMenuHiddenItem.Visible := True;
  FMenuHiddenItem.Caption := 'Visible mutated ' + IntToStr(FMenuMutationCount);
  FMenuSubItem.Caption := 'Sub item mutated ' + IntToStr(FMenuMutationCount);
  Log(Format('OnMenuMutation mutation=%d hiddenVisible=%s dynamicCaption="%s" subCaption="%s"',
    [FMenuMutationCount, BoolName(FMenuHiddenItem.Visible),
     FMenuDynamicItem.Caption, FMenuSubItem.Caption]));
end;

procedure TToolBarValidationForm.MenuPopupLog(Sender: TObject);
begin
  Inc(FMenuPopupCount);
  FMenuHiddenItem.Visible := False;
  FMenuDynamicItem.Caption := 'Dynamic popup ' + IntToStr(FMenuPopupCount);
  FMenuSubItem.Caption := 'Sub item popup ' + IntToStr(FMenuPopupCount);
  FMutationTimer.Enabled := False;
  FMutationTimer.Enabled := True;
  Log(Format('OnMenuPopup popupPoint=(%d,%d) alignment=%d items=%d hiddenVisible=%s dynamicCaption="%s" subCaption="%s"',
    [FMenu.PopupPoint.X, FMenu.PopupPoint.Y, Ord(FMenu.Alignment),
     FMenu.Items.Count, BoolName(FMenuHiddenItem.Visible),
     FMenuDynamicItem.Caption, FMenuSubItem.Caption]));
end;

procedure TToolBarValidationForm.PaintButton(Sender: TToolButton; State: Integer);
begin
  Inc(FPaintButtonCount);
end;

procedure TToolBarValidationForm.LogVisualHotIcon(const AContext: string);
var
  ImgList: TCustomImageList;
  ImgIndex: Integer;
  ImgEffect: TGraphicsDrawEffect;
  ListName: string;
begin
  if FVisualHot = nil then
    Exit;
  ImgList := nil;
  ImgIndex := -1;
  ImgEffect := gdeNormal;
  FVisualHot.GetCurrentIcon(ImgList, ImgIndex, ImgEffect);
  if ImgList = FImages then
    ListName := 'Images'
  else if ImgList = FHotImages then
    ListName := 'HotImages'
  else if ImgList = FDisabledImages then
    ListName := 'DisabledImages'
  else if ImgList = nil then
    ListName := 'nil'
  else
    ListName := ImgList.ClassName;
  Log(Format('%s visual-hot-current-icon list=%s index=%d effect=%d enabled=%s',
    [AContext, ListName, ImgIndex, Ord(ImgEffect), BoolName(FVisualHot.Enabled)]));
end;

procedure TToolBarValidationForm.SaveVisualSnapshot;
var
  B: TBitmap;
  FileName: string;
begin
  FileName := GetEnvironmentVariable('TOOLBAR_VISUAL_SNAPSHOT');
  if FileName = '' then
    Exit;
  if FVisualToolBar = nil then
    Exit;

  if ForceHotSnapshot and (FVisualHot <> nil) then
  begin
    LogVisualHotIcon('before-force-hot');
    FVisualHot.ProbeMouseEnter;
    LogVisualHotIcon('after-force-hot');
  end;

  if FileName <> '' then
  begin
    B := TBitmap.Create;
    try
      B.SetSize(FVisualToolBar.Width, FVisualToolBar.Height);
      B.Canvas.Brush.Color := clBtnFace;
      B.Canvas.FillRect(Rect(0, 0, B.Width, B.Height));
      FVisualToolBar.PaintTo(B.Canvas.Handle, 0, 0);
      B.SaveToFile(FileName);
      Log('visual-snapshot ' + FileName);
    finally
      B.Free;
    end;
  end;
end;

procedure TToolBarValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  SaveVisualSnapshot;
  LogState('before-manual-close');
  if DestructionProbe then
    LogDestructionState('before-manual-close');
  Log('manual-close-timer');
  Application.Terminate;
end;

{ Destruction-during-click probe. Frees tool buttons from inside their own
  OnClick handlers, driven by REAL X11 clicks (programmatic .Click would skip
  the widgetset mouse-up chain where a use-after-free would live). }

procedure TToolBarValidationForm.DestroySelfClick(Sender: TObject);
begin
  Inc(FDestroyClicks);
  Log('destroy-self-click releasing ' + TComponent(Sender).Name);
  FDestroySelfBtn := nil;
  { The LCL-sanctioned way: deferred free after message processing. }
  Application.ReleaseComponent(TComponent(Sender));
  Log('destroy-self-click queued release');
end;

procedure TToolBarValidationForm.DestroySibClick(Sender: TObject);
begin
  Inc(FDestroyClicks);
  Log('destroy-sibling-click freeing doomed assigned=' + BoolName(Assigned(FDoomedBtn)));
  FreeAndNil(FDoomedBtn); { direct synchronous free of ANOTHER live button }
  Log('destroy-sibling-click freed');
end;

procedure TToolBarValidationForm.DestroyHardClick(Sender: TObject);
begin
  Inc(FDestroyClicks);
  { Harsh case: direct synchronous free of the SENDER inside its own OnClick.
    Formally unsupported by LCL/VCL, but real code does it; run it LAST and
    compare widgetsets — a crash here on every widgetset is an LCL-core
    property, not a GTK4 defect. }
  Log('destroy-hard-click direct free BEGIN');
  FDestroyHardBtn := nil;
  TToolButton(Sender).Free;
  Log('destroy-hard-click direct free END');
end;

{ Windowed-control cases. TToolButton is a TGraphicControl (no own GTK4
  handle), so the toolbar cases above never free a TGtk4Widget wrapper while
  its own GtkEventMouse callback is running. These two TButton cases do:
  the button-release path delivers LM_LBUTTONUP (running OnClick) and then
  LM_CLICKED on the same wrapper (gtk4widgets.pas GtkEventMouse). }

procedure TToolBarValidationForm.DestroyWinClick(Sender: TObject);
begin
  Inc(FDestroyClicks);
  Log('destroy-win-click releasing windowed ' + TComponent(Sender).Name);
  FDestroyWinBtn := nil;
  { Supported pattern: deferred free of a windowed control from its own
    OnClick — the release is processed after the mouse event unwinds. }
  Application.ReleaseComponent(TComponent(Sender));
  Log('destroy-win-click queued release');
end;

procedure TToolBarValidationForm.DestroyWinHardClick(Sender: TObject);
begin
  Inc(FDestroyClicks);
  { Formally UNSUPPORTED on every widgetset: synchronous free of a windowed
    control inside its own OnClick unwinds through freed LCL WndProc frames
    before the widgetset even regains control. Run LAST; a crash here on
    every widgetset is an LCL-core property, not a GTK4 defect. }
  Log('destroy-win-hard-click direct free of windowed self BEGIN');
  FDestroyWinHardBtn := nil;
  TButton(Sender).Free;
  Log('destroy-win-hard-click direct free of windowed self END');
end;

procedure TToolBarValidationForm.LogDestructionState(const AContext: string);
begin
  if FDestroyToolBar = nil then
    Exit;
  Log(Format('%s destruction clicks=%d buttons=%d self-alive=%s doomed-alive=%s hard-alive=%s win-alive=%s winhard-alive=%s survived=True',
    [AContext, FDestroyClicks, FDestroyToolBar.ButtonCount,
     BoolName(Assigned(FDestroySelfBtn)), BoolName(Assigned(FDoomedBtn)),
     BoolName(Assigned(FDestroyHardBtn)), BoolName(Assigned(FDestroyWinBtn)),
     BoolName(Assigned(FDestroyWinHardBtn))]));
end;

procedure TToolBarValidationForm.WriteDestructionCoords;
var
  SL: TStringList;

  procedure AddCoord(const AName: string; B: TControl);
  var
    Pt: TPoint;
  begin
    if B = nil then
      Exit;
    Pt := B.Parent.ClientToScreen(
      Point(B.Left + B.Width div 2, B.Top + B.Height div 2));
    SL.Add(Format('%s %d %d', [AName, Pt.X, Pt.Y]));
    Log(Format('destruction-coord %s screen=(%d,%d) bounds=(%d,%d,%d,%d)',
      [AName, Pt.X, Pt.Y, B.Left, B.Top, B.Width, B.Height]));
  end;

begin
  if (FDestroyToolBar = nil) or (DestructionCoordsPath = '') then
    Exit;
  SL := TStringList.Create;
  try
    AddCoord('SELF', FDestroySelfBtn);
    AddCoord('SIB', FDestroySibBtn);
    AddCoord('HARD', FDestroyHardBtn);
    AddCoord('WBTN', FDestroyWinBtn);
    AddCoord('WHARD', FDestroyWinHardBtn);
    SL.SaveToFile(DestructionCoordsPath);
  finally
    SL.Free;
  end;
end;

procedure TToolBarValidationForm.AppException(Sender: TObject; E: Exception);
begin
  Log('APPLICATION_EXCEPTION ' + E.ClassName + ': ' + E.Message);
  if AutoMode then
    Application.Terminate;
end;

procedure TToolBarValidationForm.AppShowHint(var HintStr: string;
  var CanShow: Boolean; var HintInfo: THintInfo);
begin
  Log(Format('OnShowHint hint="%s" canShow=%s cursor=(%d,%d) pos=(%d,%d)',
    [HintStr, BoolName(CanShow), HintInfo.CursorPos.X, HintInfo.CursorPos.Y,
     HintInfo.HintPos.X, HintInfo.HintPos.Y]));
end;

begin
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TToolBarValidationForm, ToolBarValidationForm);
  Application.Run;
end.
