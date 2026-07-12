program trackbar_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Gtk4Widgets, LazGtk4;

type
  TTrackBarValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FHorizontal: TTrackBar;
    FHorizontalReversed: TTrackBar;
    FVertical: TTrackBar;
    FVerticalReversed: TTrackBar;
    FEqualRange: TTrackBar;
    FDenseRange: TTrackBar;
    FChangeCount: Integer;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure ConfigureTrack(ATrack: TTrackBar; AOrientation: TTrackBarOrientation;
      AReversed: Boolean; AMin, AMax, APosition: Integer);
    procedure CreateLabel(const ACaption: string; ALeft, ATop: Integer);
    procedure Log(const S: string);
    procedure LogTrack(const AName: string; ATrack: TTrackBar);
    procedure TrackChanged(Sender: TObject);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  TrackBarValidationForm: TTrackBarValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('TRACKBAR_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('TRACKBAR_VALIDATION_CLOSE_MS'), 0);
end;

function OrientationName(AOrientation: TTrackBarOrientation): string;
begin
  case AOrientation of
    trHorizontal: Result := 'trHorizontal';
    trVertical: Result := 'trVertical';
  else
    Result := 'unknown';
  end;
end;

function TickStyleName(AStyle: TTickStyle): string;
begin
  case AStyle of
    tsNone: Result := 'tsNone';
    tsAuto: Result := 'tsAuto';
    tsManual: Result := 'tsManual';
  else
    Result := 'unknown';
  end;
end;

function ScalePosName(APos: TTrackBarScalePos): string;
begin
  case APos of
    trLeft: Result := 'trLeft';
    trRight: Result := 'trRight';
    trTop: Result := 'trTop';
    trBottom: Result := 'trBottom';
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

function GtkPositionName(APosition: TGtkPositionType): string;
begin
  case APosition of
    GTK_POS_LEFT: Result := 'GTK_POS_LEFT';
    GTK_POS_RIGHT: Result := 'GTK_POS_RIGHT';
    GTK_POS_TOP: Result := 'GTK_POS_TOP';
    GTK_POS_BOTTOM: Result := 'GTK_POS_BOTTOM';
  else
    Result := 'GTK_POS_UNKNOWN';
  end;
end;

constructor TTrackBarValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 TrackBar validation';
  Position := poDesigned;
  SetBounds(100, 100, 820, 620);

  CreateLabel('Horizontal', 24, 24);
  FHorizontal := TTrackBar.Create(Self);
  FHorizontal.Parent := Self;
  FHorizontal.SetBounds(144, 16, 420, 48);
  ConfigureTrack(FHorizontal, trHorizontal, False, 0, 100, 25);

  CreateLabel('Horizontal reversed', 24, 84);
  FHorizontalReversed := TTrackBar.Create(Self);
  FHorizontalReversed.Parent := Self;
  FHorizontalReversed.SetBounds(144, 76, 420, 48);
  ConfigureTrack(FHorizontalReversed, trHorizontal, True, 0, 100, 40);

  CreateLabel('Vertical', 24, 160);
  FVertical := TTrackBar.Create(Self);
  FVertical.Parent := Self;
  { Set Orientation BEFORE bounds: LCL SetOrientation swaps W/H }
  ConfigureTrack(FVertical, trVertical, False, 0, 100, 60);
  FVertical.SetBounds(144, 144, 48, 180);

  CreateLabel('Vertical reversed', 280, 160);
  FVerticalReversed := TTrackBar.Create(Self);
  FVerticalReversed.Parent := Self;
  { Set Orientation BEFORE bounds: LCL SetOrientation swaps W/H }
  ConfigureTrack(FVerticalReversed, trVertical, True, 0, 100, 70);
  FVerticalReversed.SetBounds(420, 144, 48, 180);

  CreateLabel('Equal range', 520, 160);
  FEqualRange := TTrackBar.Create(Self);
  FEqualRange.Parent := Self;
  { Set Orientation BEFORE bounds: LCL SetOrientation swaps W/H }
  ConfigureTrack(FEqualRange, trVertical, False, 50, 50, 50);
  FEqualRange.SetBounds(640, 144, 48, 180);

  { Range span (1000) exceeds the widget pixel width (420) while only 11
    marks would be drawn — exercises the tick-mark density guard, which
    must compare mark COUNT against pixels, not the range span. }
  CreateLabel('Dense range', 24, 336);
  FDenseRange := TTrackBar.Create(Self);
  FDenseRange.Parent := Self;
  FDenseRange.SetBounds(144, 328, 420, 48);
  ConfigureTrack(FDenseRange, trHorizontal, False, 0, 1000, 300);
  FDenseRange.Frequency := 100;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 396, 752, 200);
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

procedure TTrackBarValidationForm.ConfigureTrack(ATrack: TTrackBar;
  AOrientation: TTrackBarOrientation; AReversed: Boolean; AMin, AMax,
  APosition: Integer);
begin
  ATrack.SetParams(APosition, AMin, AMax);
  ATrack.Orientation := AOrientation;
  ATrack.Reversed := AReversed;
  ATrack.LineSize := 2;
  ATrack.PageSize := 10;
  ATrack.Frequency := 10;
  ATrack.TickStyle := tsAuto;
  ATrack.TickMarks := tmBoth;
  ATrack.ScalePos := trTop;
  ATrack.OnChange := @TrackChanged;
end;

procedure TTrackBarValidationForm.CreateLabel(const ACaption: string;
  ALeft, ATop: Integer);
var
  L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := ACaption;
  L.SetBounds(ALeft, ATop + 8, 140, 24);
end;

procedure TTrackBarValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TTrackBarValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TTrackBarValidationForm.LogTrack(const AName: string;
  ATrack: TTrackBar);
var
  GtkTrack: TGtk4TrackBar;
  NativeWidget: PGtkWidget;
  Adj: PGtkAdjustment;
  NativeOrientation: TGtkOrientation;
  NativeInverted: Boolean;
  NativeValue: Double;
  NativeLower: Double;
  NativeUpper: Double;
  NativeStep: Double;
  NativePage: Double;
  NativeDrawValue: Boolean;
  NativeValuePos: TGtkPositionType;
begin
  if ATrack.Handle = 0 then
  begin
    Log(AName + ' handle=0');
    Exit;
  end;

  GtkTrack := TGtk4TrackBar(ATrack.Handle);
  NativeWidget := GtkTrack.GetContainerWidget;
  Adj := PGtkRange(NativeWidget)^.get_adjustment;
  NativeOrientation := PGtkOrientable(NativeWidget)^.get_orientation;
  NativeInverted := PGtkRange(NativeWidget)^.get_inverted;
  NativeValue := PGtkRange(NativeWidget)^.get_value;
  NativeLower := Adj^.get_lower;
  NativeUpper := Adj^.get_upper;
  NativeStep := Adj^.get_step_increment;
  NativePage := Adj^.get_page_increment;
  NativeDrawValue := PGtkScale(NativeWidget)^.get_draw_value;
  NativeValuePos := PGtkScale(NativeWidget)^.get_value_pos;

  Log(Format('%s lcl.bounds=%d,%d %dx%d native.alloc=%dx%d',
    [AName, ATrack.Left, ATrack.Top, ATrack.Width, ATrack.Height,
     NativeWidget^.get_allocated_width, NativeWidget^.get_allocated_height]));
  Log(Format('%s lcl.orientation=%s lcl.reversed=%s lcl.min=%d lcl.max=%d lcl.position=%d lcl.tickstyle=%s lcl.scalepos=%s native.orientation=%s native.inverted=%s native.value=%.3f native.lower=%.3f native.upper=%.3f native.step=%.3f native.page=%.3f native.draw_value=%s native.value_pos=%s wrapper.orientation=%s wrapper.reversed=%s wrapper.position=%d',
    [AName,
     OrientationName(ATrack.Orientation),
     BoolToStr(ATrack.Reversed, True),
     ATrack.Min,
     ATrack.Max,
     ATrack.Position,
     TickStyleName(ATrack.TickStyle),
     ScalePosName(ATrack.ScalePos),
     GtkOrientationName(NativeOrientation),
     BoolToStr(NativeInverted, True),
     NativeValue,
     NativeLower,
     NativeUpper,
     NativeStep,
     NativePage,
     BoolToStr(NativeDrawValue, True),
     GtkPositionName(NativeValuePos),
     OrientationName(GtkTrack.GetTrackBarOrientation),
     BoolToStr(GtkTrack.Reversed, True),
     GtkTrack.Position]));
end;

procedure TTrackBarValidationForm.TrackChanged(Sender: TObject);
begin
  Inc(FChangeCount);
  if Sender is TTrackBar then
    Log(Format('EVENT OnChange sender=%p position=%d min=%d max=%d total=%d',
      [Pointer(Sender), TTrackBar(Sender).Position, TTrackBar(Sender).Min,
       TTrackBar(Sender).Max, FChangeCount]));
end;

procedure TTrackBarValidationForm.RunChecks;
var
  OldHandle: PtrUInt;
begin
  Application.ProcessMessages;
  LogTrack('horizontal initial', FHorizontal);
  LogTrack('horizontal reversed initial', FHorizontalReversed);
  LogTrack('vertical initial', FVertical);
  LogTrack('vertical reversed initial', FVerticalReversed);
  LogTrack('equal initial', FEqualRange);

  FHorizontal.Position := 33;
  FHorizontalReversed.Position := 44;
  FVertical.Position := 66;
  FVerticalReversed.Position := 77;
  FEqualRange.SetParams(50, 50, 50);
  Application.ProcessMessages;

  LogTrack('horizontal updated', FHorizontal);
  LogTrack('horizontal reversed updated', FHorizontalReversed);
  LogTrack('vertical updated', FVertical);
  LogTrack('vertical reversed updated', FVerticalReversed);
  LogTrack('equal updated', FEqualRange);

  OldHandle := PtrUInt(FHorizontal.Handle);
  FHorizontal.TickStyle := tsNone;
  Application.ProcessMessages;
  Log(Format('horizontal tickstyle changed old_handle=%d new_handle=%d', [OldHandle, PtrUInt(FHorizontal.Handle)]));
  LogTrack('horizontal tickstyle none', FHorizontal);

  OldHandle := PtrUInt(FHorizontal.Handle);
  FHorizontal.Orientation := trVertical;
  Application.ProcessMessages;
  Log(Format('horizontal orientation changed old_handle=%d new_handle=%d', [OldHandle, PtrUInt(FHorizontal.Handle)]));
  LogTrack('horizontal now vertical', FHorizontal);

  Log('change_count=' + IntToStr(FChangeCount));
  Log('AUTO end');
end;

procedure TTrackBarValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  RunChecks;
  Close;
end;

procedure TTrackBarValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  LogTrack('final horizontal', FHorizontal);
  LogTrack('final horizontal reversed', FHorizontalReversed);
  LogTrack('final vertical', FVertical);
  LogTrack('final vertical reversed', FVerticalReversed);
  LogTrack('final equal range', FEqualRange);
  Log('final change_count=' + IntToStr(FChangeCount));
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TTrackBarValidationForm, TrackBarValidationForm);
  Application.Run;
end.
