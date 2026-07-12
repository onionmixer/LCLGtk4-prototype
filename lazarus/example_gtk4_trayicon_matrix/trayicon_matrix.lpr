program trayicon_matrix;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, Menus,
  StdCtrls;

type
  TTrayMatrixForm = class(TForm)
  private
    FTrayIcon: TTrayIcon;
    FSecondTrayIcon: TTrayIcon;
    FPopupMenu: TPopupMenu;
    FAutoCheckMenuItem: TMenuItem;
    FMutableMenuItem: TMenuItem;
    FCloseTimer: TTimer;
    FUpdateTimer: TTimer;
    FStartTick: QWord;
    function AddMenuItem(const ACaption: string; AEnabled, AVisible,
      AChecked, ARadio: Boolean): TMenuItem;
    procedure CloseTimer(Sender: TObject);
    procedure CreateTrayIcon;
    procedure LogExpectedSNI;
    procedure MenuClick(Sender: TObject);
    procedure TrayClick(Sender: TObject);
    procedure TrayDblClick(Sender: TObject);
    procedure TrayMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TrayMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure TrayMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure UpdateTimer(Sender: TObject);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  TrayMatrixForm: TTrayMatrixForm;

function BoolName(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

function RuntimeDir: string;
begin
  Result := GetEnvironmentVariable('XDG_RUNTIME_DIR');
  if Result = '' then
    Result := '/tmp';
end;

function CurrentUserName: string;
begin
  Result := GetEnvironmentVariable('USER');
  if Result = '' then
    Result := 'unknown';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('TRAY_MATRIX_CLOSE_MS'), 300000);
  if Result < 0 then
    Result := 0;
end;

function ExpectedAppId(AInstance: Integer): string;
begin
  Result := 'lcl-' + IntToStr(GetProcessID) + '-' + IntToStr(AInstance);
end;

function ExpectedIconDir: string;
begin
  Result := IncludeTrailingPathDelimiter(RuntimeDir) + 'lcl-sni-' +
    CurrentUserName + DirectorySeparator;
end;

function ExpectedIconName(AInstance: Integer): string;
begin
  Result := ExpectedAppId(AInstance) + '-icon';
end;

function ExpectedBusName(AInstance: Integer): string;
begin
  Result := 'org.kde.StatusNotifierItem-' + IntToStr(GetProcessID) + '-' +
    IntToStr(AInstance);
end;

function ExpectedObjectPath(AInstance: Integer): string;
begin
  if AInstance = 1 then
    Result := '/StatusNotifierItem'
  else
    Result := '/StatusNotifierItem/Item' + IntToStr(AInstance);
end;

function ExpectedMenuPath(AInstance: Integer): string;
begin
  if AInstance = 1 then
    Result := '/MenuBar'
  else
    Result := '/MenuBar/Item' + IntToStr(AInstance);
end;

procedure FillIcon(AIcon: TIcon; AFirstColor, ASecondColor: TColor);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(32, 32);
    Bmp.Canvas.Brush.Color := AFirstColor;
    Bmp.Canvas.FillRect(0, 0, 32, 32);
    Bmp.Canvas.Brush.Color := ASecondColor;
    Bmp.Canvas.Ellipse(6, 6, 26, 26);
    Bmp.Canvas.Pen.Color := clWhite;
    Bmp.Canvas.MoveTo(4, 28);
    Bmp.Canvas.LineTo(28, 4);
    AIcon.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

constructor TTrayMatrixForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 TrayIcon Matrix';
  SetBounds(100, 100, 360, 160);
  Position := poDesigned;

  with TLabel.Create(Self) do
  begin
    Parent := Self;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := 'TrayIcon matrix is running.' + LineEnding +
      'Inspect stdout and D-Bus while this window is open.';
  end;

  FStartTick := GetTickCount64;
  CreateTrayIcon;

  FUpdateTimer := TTimer.Create(Self);
  FUpdateTimer.Enabled := False;
  FUpdateTimer.Interval := 3000;
  FUpdateTimer.OnTimer := @UpdateTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;
end;

function TTrayMatrixForm.AddMenuItem(const ACaption: string; AEnabled,
  AVisible, AChecked, ARadio: Boolean): TMenuItem;
begin
  Result := TMenuItem.Create(FPopupMenu);
  Result.Caption := ACaption;
  Result.Enabled := AEnabled;
  Result.Visible := AVisible;
  Result.Checked := AChecked;
  Result.RadioItem := ARadio;
  Result.OnClick := @MenuClick;
  FPopupMenu.Items.Add(Result);
end;

procedure TTrayMatrixForm.CreateTrayIcon;
var
  SubMenu, SubItem: TMenuItem;
begin
  FPopupMenu := TPopupMenu.Create(Self);
  AddMenuItem('Normal item', True, True, False, False);
  AddMenuItem('Disabled item', False, True, False, False);
  AddMenuItem('Hidden item', True, False, False, False);
  AddMenuItem('Checked item', True, True, True, False);
  AddMenuItem('Radio item', True, True, True, True);
  FAutoCheckMenuItem := AddMenuItem('AutoCheck item', True, True, False, False);
  FAutoCheckMenuItem.AutoCheck := True;
  FMutableMenuItem := AddMenuItem('Mutable item initial', True, True, False, False);
  AddMenuItem('-', True, True, False, False);

  SubMenu := TMenuItem.Create(FPopupMenu);
  SubMenu.Caption := 'Submenu';
  FPopupMenu.Items.Add(SubMenu);
  SubItem := TMenuItem.Create(FPopupMenu);
  SubItem.Caption := 'Submenu item';
  SubItem.OnClick := @MenuClick;
  SubMenu.Add(SubItem);

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.Hint := 'GTK4 tray matrix initial hint';
  FTrayIcon.PopUpMenu := FPopupMenu;
  FillIcon(FTrayIcon.Icon, clRed, clBlue);
  FillIcon(Application.Icon, clGreen, clBlack);
  WriteLn('TRAY pre-show icon-handle-allocated=',
    BoolName(FTrayIcon.Icon.HandleAllocated),
    ' app-icon-handle-allocated=', BoolName(Application.Icon.HandleAllocated));
  FTrayIcon.OnClick := @TrayClick;
  FTrayIcon.OnDblClick := @TrayDblClick;
  FTrayIcon.OnMouseDown := @TrayMouseDown;
  FTrayIcon.OnMouseMove := @TrayMouseMove;
  FTrayIcon.OnMouseUp := @TrayMouseUp;

  FSecondTrayIcon := TTrayIcon.Create(Self);
  FSecondTrayIcon.Hint := 'GTK4 tray matrix second hint';
  FSecondTrayIcon.PopUpMenu := FPopupMenu;
  FillIcon(FSecondTrayIcon.Icon, clAqua, clMaroon);
  FSecondTrayIcon.OnClick := @TrayClick;
  FSecondTrayIcon.OnDblClick := @TrayDblClick;
  FSecondTrayIcon.OnMouseDown := @TrayMouseDown;
  FSecondTrayIcon.OnMouseMove := @TrayMouseMove;
  FSecondTrayIcon.OnMouseUp := @TrayMouseUp;
end;

procedure TTrayMatrixForm.DoShow;
begin
  inherited DoShow;
  LogExpectedSNI;
  FTrayIcon.Visible := True;
  WriteLn('TRAY first visible-request result visible=', BoolName(FTrayIcon.Visible),
    ' handle=', PtrUInt(FTrayIcon.Handle),
    ' icon-handle-allocated=', BoolName(FTrayIcon.Icon.HandleAllocated),
    ' app-icon-handle-allocated=', BoolName(Application.Icon.HandleAllocated));
  FSecondTrayIcon.Visible := True;
  WriteLn('TRAY second visible-request result visible=',
    BoolName(FSecondTrayIcon.Visible),
    ' handle=', PtrUInt(FSecondTrayIcon.Handle),
    ' icon-handle-allocated=', BoolName(FSecondTrayIcon.Icon.HandleAllocated));
  FUpdateTimer.Enabled := True;
  FCloseTimer.Enabled := True;
end;

procedure TTrayMatrixForm.LogExpectedSNI;
begin
  WriteLn('TRAY matrix pid=', GetProcessID);
  WriteLn('TRAY first expected-bus-name=', ExpectedBusName(1));
  WriteLn('TRAY first expected-object-path=', ExpectedObjectPath(1));
  WriteLn('TRAY first expected-menu-path=', ExpectedMenuPath(1));
  WriteLn('TRAY first expected-app-id=', ExpectedAppId(1));
  WriteLn('TRAY first expected-icon-name=', ExpectedIconName(1));
  WriteLn('TRAY second expected-bus-name=', ExpectedBusName(2));
  WriteLn('TRAY second expected-object-path=', ExpectedObjectPath(2));
  WriteLn('TRAY second expected-menu-path=', ExpectedMenuPath(2));
  WriteLn('TRAY second expected-app-id=', ExpectedAppId(2));
  WriteLn('TRAY second expected-icon-name=', ExpectedIconName(2));
  WriteLn('TRAY expected-icon-dir=', ExpectedIconDir);
  WriteLn('TRAY first expected-icon-path=', ExpectedIconDir, ExpectedIconName(1), '.png');
  WriteLn('TRAY second expected-icon-path=', ExpectedIconDir, ExpectedIconName(2), '.png');
  WriteLn('TRAY first inspect-command=busctl --user introspect ',
    ExpectedBusName(1), ' ', ExpectedObjectPath(1),
    ' org.kde.StatusNotifierItem --no-pager');
  WriteLn('TRAY second inspect-command=busctl --user introspect ',
    ExpectedBusName(2), ' ', ExpectedObjectPath(2),
    ' org.kde.StatusNotifierItem --no-pager');
end;

procedure TTrayMatrixForm.MenuClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    WriteLn('TRAY event menu-click caption=', TMenuItem(Sender).Caption,
      ' checked=', BoolName(TMenuItem(Sender).Checked));
end;

procedure TTrayMatrixForm.TrayClick(Sender: TObject);
begin
  WriteLn('TRAY event click elapsed-ms=', GetTickCount64 - FStartTick);
end;

procedure TTrayMatrixForm.TrayDblClick(Sender: TObject);
begin
  WriteLn('TRAY event dblclick elapsed-ms=', GetTickCount64 - FStartTick);
end;

procedure TTrayMatrixForm.TrayMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  WriteLn('TRAY event mouse-down button=', Ord(Button), ' x=', X, ' y=', Y);
end;

procedure TTrayMatrixForm.TrayMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  WriteLn('TRAY event mouse-move x=', X, ' y=', Y);
end;

procedure TTrayMatrixForm.TrayMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  WriteLn('TRAY event mouse-up button=', Ord(Button), ' x=', X, ' y=', Y);
end;

procedure TTrayMatrixForm.UpdateTimer(Sender: TObject);
begin
  FUpdateTimer.Enabled := False;
  FTrayIcon.Hint := 'GTK4 tray matrix updated hint';
  FillIcon(FTrayIcon.Icon, clYellow, clPurple);
  FMutableMenuItem.Caption := 'Mutable item updated';
  FMutableMenuItem.Enabled := False;
  FAutoCheckMenuItem.Checked := False;
  FTrayIcon.InternalUpdate;
  WriteLn('TRAY update icon-and-hint elapsed-ms=', GetTickCount64 - FStartTick);
  WriteLn('TRAY updated-icon-path=', ExpectedIconDir, ExpectedIconName(1), '.png');
  FTrayIcon.BalloonTitle := 'GTK4 tray matrix balloon';
  FTrayIcon.BalloonHint := 'GTK4 tray notification body';
  FTrayIcon.BalloonFlags := bfInfo;
  FTrayIcon.BalloonTimeout := 3000;
  WriteLn('TRAY balloon-request elapsed-ms=', GetTickCount64 - FStartTick);
  FTrayIcon.ShowBalloonHint;
end;

procedure TTrayMatrixForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  WriteLn('TRAY auto-close elapsed-ms=', GetTickCount64 - FStartTick);
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TTrayMatrixForm, TrayMatrixForm);
  Application.Run;
end.
