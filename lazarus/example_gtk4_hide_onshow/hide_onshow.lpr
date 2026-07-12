program hide_onshow;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, ExtCtrls;

type
  TRunMode = (rmHideOnShow, rmNormal, rmSecondaryHideOnShow);

  THideOnShowForm = class(TForm)
  private
    FCloseTimer: TTimer;
    FHideInOnShow: Boolean;
    FSecondaryForm: TForm;
    procedure CloseTimer(Sender: TObject);
    procedure FormShown(Sender: TObject);
    procedure SecondaryShown(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  HideOnShowForm: THideOnShowForm;
  RunMode: TRunMode = rmHideOnShow;
  RequestedWindowState: TWindowState = wsNormal;

function HasArg(const AName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if ParamStr(I) = AName then
      Exit(True);
end;

function BoolName(AValue: Boolean): string;
begin
  if AValue then
    Result := 'TRUE'
  else
    Result := 'FALSE';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('HIDE_ONSHOW_CLOSE_MS'), 4000);
  if Result < 0 then
    Result := 0;
end;

constructor THideOnShowForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption := 'lcl-gtk4-hide-onshow-test';
  Width := 360;
  Height := 180;
  Position := poDesigned;
  Left := 100;
  Top := 100;
  WindowState := RequestedWindowState;
  FHideInOnShow := RunMode = rmHideOnShow;
  OnShow := @FormShown;

  if RunMode = rmSecondaryHideOnShow then
  begin
    FSecondaryForm := TForm.Create(Self);
    FSecondaryForm.Caption := 'lcl-gtk4-hide-secondary';
    FSecondaryForm.Width := 300;
    FSecondaryForm.Height := 150;
    FSecondaryForm.Left := 520;
    FSecondaryForm.Top := 100;
    FSecondaryForm.OnShow := @SecondaryShown;
  end;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;
end;

procedure THideOnShowForm.FormShown(Sender: TObject);
begin
  WriteLn('EVENT main OnShow before-hide visible=', BoolName(Visible));
  if FHideInOnShow then
  begin
    Hide;
    WriteLn('EVENT main OnShow after-hide visible=', BoolName(Visible));
  end;
  if FSecondaryForm <> nil then
    FSecondaryForm.Show;
  FCloseTimer.Enabled := True;
end;

procedure THideOnShowForm.SecondaryShown(Sender: TObject);
begin
  WriteLn('EVENT secondary OnShow before-hide visible=',
    BoolName(FSecondaryForm.Visible));
  FSecondaryForm.Hide;
  WriteLn('EVENT secondary OnShow after-hide visible=',
    BoolName(FSecondaryForm.Visible));
end;

procedure THideOnShowForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  WriteLn('EVENT close-timer main-visible=', BoolName(Visible));
  if FSecondaryForm <> nil then
    WriteLn('EVENT close-timer secondary-visible=',
      BoolName(FSecondaryForm.Visible));
  Application.Terminate;
end;

begin
  if HasArg('--normal') then
    RunMode := rmNormal
  else if HasArg('--secondary-hide-on-show') then
    RunMode := rmSecondaryHideOnShow
  else
    RunMode := rmHideOnShow;

  if HasArg('--maximized') then
    RequestedWindowState := wsMaximized
  else if HasArg('--fullscreen') then
    RequestedWindowState := wsFullScreen;

  WriteLn('EVENT mode=', Ord(RunMode), ' window-state=', Ord(RequestedWindowState),
    ' close-ms=', CloseInterval);
  Application.Initialize;
  Application.CreateForm(THideOnShowForm, HideOnShowForm);
  Application.Run;
end.
