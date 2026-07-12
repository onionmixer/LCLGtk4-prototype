program progressbar_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Gtk4Widgets, LazGtk4, LazGObject2;

type
  TProgressBarValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FHorizontal: TProgressBar;
    FRightToLeft: TProgressBar;
    FVertical: TProgressBar;
    FTopDown: TProgressBar;
    FMarquee: TProgressBar;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure ConfigureBar(ABar: TProgressBar; AOrientation: TProgressBarOrientation;
      APosition: Integer; AStyle: TProgressBarStyle = pbstNormal);
    procedure CreateLabel(const ACaption: string; ALeft, ATop: Integer);
    procedure Log(const S: string);
    procedure LogBar(const AName: string; ABar: TProgressBar);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  ProgressBarValidationForm: TProgressBarValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('PROGRESSBAR_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('PROGRESSBAR_VALIDATION_CLOSE_MS'), 0);
end;

function OrientationName(AOrientation: TProgressBarOrientation): string;
begin
  case AOrientation of
    pbHorizontal: Result := 'pbHorizontal';
    pbVertical: Result := 'pbVertical';
    pbRightToLeft: Result := 'pbRightToLeft';
    pbTopDown: Result := 'pbTopDown';
  else
    Result := 'unknown';
  end;
end;

function StyleName(AStyle: TProgressBarStyle): string;
begin
  case AStyle of
    pbstNormal: Result := 'pbstNormal';
    pbstMarquee: Result := 'pbstMarquee';
  else
    Result := 'unknown';
  end;
end;

function GtkOrientationName(AOrientation: TGtkOrientation): string;
begin
  case AOrientation of
    GTK_ORIENTATION_HORIZONTAL: Result := 'GTK_ORIENTATION_HORIZONTAL';
    GTK_ORIENTATION_VERTICAL: Result := 'GTK_ORIENTATION_VERTICAL';
  else
    Result := 'GTK_ORIENTATION_UNKNOWN';
  end;
end;

constructor TProgressBarValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 ProgressBar validation';
  Position := poDesigned;
  SetBounds(100, 100, 760, 560);

  CreateLabel('Horizontal', 24, 24);
  FHorizontal := TProgressBar.Create(Self);
  FHorizontal.Parent := Self;
  FHorizontal.SetBounds(140, 20, 440, 28);
  ConfigureBar(FHorizontal, pbHorizontal, 25);

  CreateLabel('Right-to-left', 24, 68);
  FRightToLeft := TProgressBar.Create(Self);
  FRightToLeft.Parent := Self;
  FRightToLeft.SetBounds(140, 64, 440, 28);
  ConfigureBar(FRightToLeft, pbRightToLeft, 50);

  CreateLabel('Vertical', 24, 116);
  FVertical := TProgressBar.Create(Self);
  FVertical.Parent := Self;
  FVertical.SetBounds(140, 112, 36, 160);
  ConfigureBar(FVertical, pbVertical, 70);

  CreateLabel('Top-down', 240, 116);
  FTopDown := TProgressBar.Create(Self);
  FTopDown.Parent := Self;
  FTopDown.SetBounds(356, 112, 36, 160);
  ConfigureBar(FTopDown, pbTopDown, 70);

  CreateLabel('Marquee', 24, 304);
  FMarquee := TProgressBar.Create(Self);
  FMarquee.Parent := Self;
  FMarquee.SetBounds(140, 300, 440, 28);
  ConfigureBar(FMarquee, pbHorizontal, 0, pbstMarquee);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 352, 690, 160);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 500;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;
end;

procedure TProgressBarValidationForm.ConfigureBar(ABar: TProgressBar;
  AOrientation: TProgressBarOrientation; APosition: Integer;
  AStyle: TProgressBarStyle);
begin
  ABar.Min := 0;
  ABar.Max := 100;
  ABar.Position := APosition;
  ABar.Orientation := AOrientation;
  ABar.BarShowText := True;
  ABar.Smooth := True;
  ABar.Style := AStyle;
end;

procedure TProgressBarValidationForm.CreateLabel(const ACaption: string;
  ALeft, ATop: Integer);
var
  L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := ACaption;
  L.SetBounds(ALeft, ATop + 4, 100, 24);
end;

procedure TProgressBarValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TProgressBarValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TProgressBarValidationForm.LogBar(const AName: string;
  ABar: TProgressBar);
var
  GtkBar: TGtk4ProgressBar;
  NativeWidget: PGtkWidget;
  NativeOrientation: TGtkOrientation;
  NativeInverted: Boolean;
  NativeFraction: Double;
  NativeShowText: Boolean;
  NativeStyleData: PtrUInt;
  NativeTimeoutData: PtrUInt;
begin
  if ABar.Handle = 0 then
  begin
    Log(AName + ' handle=0');
    Exit;
  end;

  GtkBar := TGtk4ProgressBar(ABar.Handle);
  NativeWidget := GtkBar.GetContainerWidget;
  NativeOrientation := PGtkOrientable(NativeWidget)^.get_orientation;
  NativeInverted := PGtkProgressBar(NativeWidget)^.get_inverted;
  NativeFraction := PGtkProgressBar(NativeWidget)^.get_fraction;
  NativeShowText := PGtkProgressBar(NativeWidget)^.get_show_text;
  NativeStyleData := PtrUInt(g_object_get_data(PGObject(NativeWidget), 'lclprogressbarstyle'));
  NativeTimeoutData := PtrUInt(g_object_get_data(PGObject(NativeWidget), 'timeout'));

  Log(Format('%s lcl.orientation=%s lcl.position=%d lcl.min=%d lcl.max=%d lcl.style=%s lcl.smooth=%s lcl.text=%s native.orientation=%s native.inverted=%s native.fraction=%.3f native.show_text=%s native.styledata=%d native.timeout=%d wrapper.orientation=%s wrapper.position=%d',
    [AName,
     OrientationName(ABar.Orientation),
     ABar.Position,
     ABar.Min,
     ABar.Max,
     StyleName(ABar.Style),
     BoolToStr(ABar.Smooth, True),
     BoolToStr(ABar.BarShowText, True),
     GtkOrientationName(NativeOrientation),
     BoolToStr(NativeInverted, True),
     NativeFraction,
     BoolToStr(NativeShowText, True),
     NativeStyleData,
     NativeTimeoutData,
     OrientationName(GtkBar.Orientation),
     GtkBar.Position]));
end;

procedure TProgressBarValidationForm.RunChecks;
begin
  Application.ProcessMessages;
  LogBar('horizontal initial', FHorizontal);
  LogBar('rtl initial', FRightToLeft);
  LogBar('vertical initial', FVertical);
  LogBar('topdown initial', FTopDown);
  LogBar('marquee initial', FMarquee);

  FHorizontal.Position := 40;
  FRightToLeft.Position := 60;
  FVertical.Position := 80;
  FTopDown.Position := 80;
  FMarquee.Style := pbstNormal;
  FMarquee.Position := 35;
  Application.ProcessMessages;

  LogBar('horizontal updated', FHorizontal);
  LogBar('rtl updated', FRightToLeft);
  LogBar('vertical updated', FVertical);
  LogBar('topdown updated', FTopDown);
  LogBar('marquee normal', FMarquee);

  FHorizontal.Min := -50;
  FHorizontal.Max := 50;
  FHorizontal.Position := 0;
  FRightToLeft.BarShowText := False;
  FVertical.Min := 10;
  FVertical.Max := 10;
  FVertical.Position := 10;
  FMarquee.Style := pbstMarquee;
  Application.ProcessMessages;
  Sleep(250);
  Application.ProcessMessages;

  LogBar('horizontal nonzero range', FHorizontal);
  LogBar('rtl text hidden', FRightToLeft);
  LogBar('vertical equal minmax', FVertical);
  LogBar('marquee active again', FMarquee);
  Log('AUTO end');
end;

procedure TProgressBarValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  RunChecks;
  Close;
end;

procedure TProgressBarValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TProgressBarValidationForm, ProgressBarValidationForm);
  Application.Run;
end.
