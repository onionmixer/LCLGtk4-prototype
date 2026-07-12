program pairsplitter_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls,
  PairSplitter, LCLType, Gtk4Widgets, LazGtk4;

type
  TPairSplitterValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FSplitter: TPairSplitter;
    FSide0Label: TLabel;
    FSide1Label: TLabel;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure EnsureSideLabels;
    procedure Log(const S: string);
    procedure LogState(const AContext: string; AReadLCLPosition: Boolean = False);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  PairSplitterValidationForm: TPairSplitterValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('PAIRSPLITTER_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('PAIRSPLITTER_VALIDATION_CLOSE_MS'), 0);
end;

function BoolName(AValue: Boolean): string;
begin
  Result := BoolToStr(AValue, True);
end;

function SplitterTypeName(AType: TPairSplitterType): string;
begin
  case AType of
    pstHorizontal: Result := 'pstHorizontal';
    pstVertical: Result := 'pstVertical';
  else
    Result := 'unknown';
  end;
end;

function OrientationName(AOrientation: TGtkOrientation): string;
begin
  case AOrientation of
    GTK_ORIENTATION_HORIZONTAL: Result := 'GTK_ORIENTATION_HORIZONTAL';
    GTK_ORIENTATION_VERTICAL: Result := 'GTK_ORIENTATION_VERTICAL';
  else
    Result := 'unknown';
  end;
end;

function CursorName(ACursor: TCursor): string;
begin
  case ACursor of
    crDefault: Result := 'crDefault';
    crArrow: Result := 'crArrow';
    crHSplit: Result := 'crHSplit';
    crVSplit: Result := 'crVSplit';
    crSize: Result := 'crSize';
  else
    Result := IntToStr(ACursor);
  end;
end;

function SideWidth(ASide: TPairSplitterSide): Integer;
begin
  if Assigned(ASide) then
    Result := ASide.Width
  else
    Result := -1;
end;

function SideHeight(ASide: TPairSplitterSide): Integer;
begin
  if Assigned(ASide) then
    Result := ASide.Height
  else
    Result := -1;
end;

function NativePosition(ASplitter: TPairSplitter): Integer;
begin
  Result := -999999;
  if Assigned(ASplitter) and ASplitter.HandleAllocated then
    Result := PGtkPaned(TGtk4Paned(ASplitter.Handle).Widget)^.get_position;
end;

function NativeOrientation(ASplitter: TPairSplitter): string;
begin
  Result := 'no-handle';
  if Assigned(ASplitter) and ASplitter.HandleAllocated then
    Result := OrientationName(PGtkOrientable(TGtk4Paned(ASplitter.Handle).Widget)^.get_orientation);
end;

constructor TPairSplitterValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 PairSplitter validation';
  Position := poDesigned;
  SetBounds(100, 100, 760, 560);

  FSplitter := TPairSplitter.Create(Self);
  FSplitter.Parent := Self;
  FSplitter.SetBounds(24, 24, 700, 260);
  FSplitter.Position := 180;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 304, 700, 200);
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

procedure TPairSplitterValidationForm.DoShow;
begin
  inherited DoShow;
  EnsureSideLabels;
  Log('START auto=' + BoolName(AutoMode));
  LogState('after-show');
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TPairSplitterValidationForm.EnsureSideLabels;
begin
  if Assigned(FSplitter.Sides[0]) and not Assigned(FSide0Label) then
  begin
    FSide0Label := TLabel.Create(Self);
    FSide0Label.Parent := FSplitter.Sides[0];
    FSide0Label.Caption := 'Side 0';
    FSide0Label.SetBounds(12, 12, 120, 24);
  end;

  if Assigned(FSplitter.Sides[1]) and not Assigned(FSide1Label) then
  begin
    FSide1Label := TLabel.Create(Self);
    FSide1Label.Parent := FSplitter.Sides[1];
    FSide1Label.Caption := 'Side 1';
    FSide1Label.SetBounds(12, 12, 120, 24);
  end;
end;

procedure TPairSplitterValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TPairSplitterValidationForm.LogState(const AContext: string;
  AReadLCLPosition: Boolean);
var
  S0: TPairSplitterSide;
  S1: TPairSplitterSide;
  P0: TWinControl;
  P1: TWinControl;
  LCLPositionText: string;
begin
  S0 := FSplitter.Sides[0];
  S1 := FSplitter.Sides[1];
  P0 := nil;
  P1 := nil;
  if Assigned(S0) then
    P0 := S0.Parent;
  if Assigned(S1) then
    P1 := S1.Parent;

  if AReadLCLPosition then
    LCLPositionText := IntToStr(FSplitter.Position)
  else
    LCLPositionText := 'not-read';

  Log(Format('%s type=%s lcl.position=%s native.position=%d native.orientation=%s cursor=%s side0.assigned=%s side0.parent_is_splitter=%s side0.size=%dx%d side1.assigned=%s side1.parent_is_splitter=%s side1.size=%dx%d',
    [AContext,
     SplitterTypeName(FSplitter.SplitterType),
     LCLPositionText,
     NativePosition(FSplitter),
     NativeOrientation(FSplitter),
     CursorName(FSplitter.Cursor),
     BoolName(Assigned(S0)),
     BoolName(P0 = FSplitter),
     SideWidth(S0),
     SideHeight(S0),
     BoolName(Assigned(S1)),
     BoolName(P1 = FSplitter),
     SideWidth(S1),
     SideHeight(S1)]));
end;

procedure TPairSplitterValidationForm.RunChecks;
var
  ReadPosition: Integer;
  DetachedSide: TPairSplitterSide;
begin
  EnsureSideLabels;
  LogState('initial-native-only');
  LogState('initial-read-lcl-position', True);

  FSplitter.Position := 120;
  Application.ProcessMessages;
  LogState('after-set-position-120-native-only');

  ReadPosition := FSplitter.Position;
  Log('read-position-after-set=' + IntToStr(ReadPosition));
  Application.ProcessMessages;
  LogState('after-read-position-native-only');

  FSplitter.Cursor := crSize;
  Application.ProcessMessages;
  LogState('after-set-cursor-crSize-native-only');

  FSplitter.SplitterType := pstVertical;
  Application.ProcessMessages;
  EnsureSideLabels;
  LogState('after-set-vertical-native-only');

  FSplitter.Position := 90;
  Application.ProcessMessages;
  LogState('after-vertical-set-position-90-native-only');

  ReadPosition := FSplitter.Position;
  Log('read-position-after-vertical-set=' + IntToStr(ReadPosition));
  Application.ProcessMessages;
  LogState('after-vertical-read-position-native-only');

  DetachedSide := FSplitter.Sides[1];
  if Assigned(DetachedSide) then
  begin
    DetachedSide.Parent := nil;
    Application.ProcessMessages;
    LogState('after-detach-side1-native-only');
    DetachedSide.Parent := FSplitter;
    Application.ProcessMessages;
    EnsureSideLabels;
    LogState('after-reattach-side1-native-only');
  end
  else
    Log('side1-detach-skipped=nil');

  Application.Terminate;
end;

procedure TPairSplitterValidationForm.AutoTimer(Sender: TObject);
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

procedure TPairSplitterValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  Log('manual-close-timer');
  LogState('close-native-only');
  LogState('close-read-lcl-position', True);
  Application.Terminate;
end;

begin
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TPairSplitterValidationForm, PairSplitterValidationForm);
  Application.Run;
end.
