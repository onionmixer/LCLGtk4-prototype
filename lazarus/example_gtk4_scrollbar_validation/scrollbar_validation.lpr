program scrollbar_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls,
  gtk4widgets, LazGtk4, LazGtk4_Compat;

type
  TScrollValidationForm = class(TForm)
  private
    FHScroll: TScrollBar;
    FVScroll: TScrollBar;
    FLog: TMemo;
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FScrollEvents: Integer;
    FChangeEvents: Integer;
    procedure AddButton(const ACaption: string; ATop: Integer;
      AHandler: TNotifyEvent);
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure ConfigureCase0(Sender: TObject);
    procedure ConfigureCase1(Sender: TObject);
    procedure ConfigureCase2(Sender: TObject);
    procedure ConfigureCase3(Sender: TObject);
    procedure ConfigureKindSwap(Sender: TObject);
    procedure ConfigureProgrammaticPosition(Sender: TObject);
    function DescribeNative(const AScrollBar: TScrollBar): string;
    procedure DumpState(const AContext: string; const AScrollBar: TScrollBar);
    procedure Log(const S: string);
    procedure NativeSetValue(const AScrollBar: TScrollBar; AValue: Double);
    procedure ScrollBarChange(Sender: TObject);
    procedure ScrollBarScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure SetBoth(APosition, AMin, AMax, APageSize: Integer);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  ScrollValidationForm: TScrollValidationForm;

function BoolName(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

function ScrollCodeName(ACode: TScrollCode): string;
begin
  case ACode of
    scLineUp: Result := 'scLineUp';
    scLineDown: Result := 'scLineDown';
    scPageUp: Result := 'scPageUp';
    scPageDown: Result := 'scPageDown';
    scPosition: Result := 'scPosition';
    scTrack: Result := 'scTrack';
    scTop: Result := 'scTop';
    scBottom: Result := 'scBottom';
    scEndScroll: Result := 'scEndScroll';
  else
    Result := 'unknown';
  end;
end;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('SCROLLBAR_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('SCROLLBAR_VALIDATION_CLOSE_MS'), 0);
end;

constructor TScrollValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 ScrollBar validation';
  Position := poDesigned;
  SetBounds(100, 100, 760, 520);

  FHScroll := TScrollBar.Create(Self);
  FHScroll.Parent := Self;
  FHScroll.Kind := sbHorizontal;
  FHScroll.SetBounds(24, 24, 360, 24);
  FHScroll.OnScroll := @ScrollBarScroll;
  FHScroll.OnChange := @ScrollBarChange;

  FVScroll := TScrollBar.Create(Self);
  FVScroll.Parent := Self;
  FVScroll.Kind := sbVertical;
  FVScroll.SetBounds(410, 24, 24, 240);
  FVScroll.OnScroll := @ScrollBarScroll;
  FVScroll.OnChange := @ScrollBarChange;

  AddButton('0..100 page=0', 72, @ConfigureCase0);
  AddButton('0..100 page=10', 112, @ConfigureCase1);
  AddButton('50..150 page=20', 152, @ConfigureCase2);
  AddButton('0..10 page=20', 192, @ConfigureCase3);
  AddButton('swap kind', 232, @ConfigureKindSwap);
  AddButton('programmatic pos +7', 272, @ConfigureProgrammaticPosition);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 320, 700, 160);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 300;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;

  SetBoth(0, 0, 100, 10);
end;

procedure TScrollValidationForm.AddButton(const ACaption: string; ATop: Integer;
  AHandler: TNotifyEvent);
var
  Button: TButton;
begin
  Button := TButton.Create(Self);
  Button.Parent := Self;
  Button.Caption := ACaption;
  Button.SetBounds(470, ATop, 220, 30);
  Button.OnClick := AHandler;
end;

procedure TScrollValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolName(AutoMode));
  DumpState('initial horizontal', FHScroll);
  DumpState('initial vertical', FVScroll);
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TScrollValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

function TScrollValidationForm.DescribeNative(const AScrollBar: TScrollBar): string;
var
  Widget: TGtk4Widget;
  Adj: PGtkAdjustment;
begin
  Result := 'native=unavailable';
  if not AScrollBar.HandleAllocated then
    Exit('native=no-handle');
  Widget := TGtk4Widget(AScrollBar.Handle);
  if (Widget = nil) or (Widget.Widget = nil) then
    Exit('native=no-widget');
  Adj := gtk4_scrollbar_get_adjustment(Widget.Widget);
  if Adj = nil then
    Exit('native=no-adjustment');
  Result := Format('native value=%.2f lower=%.2f upper=%.2f page=%.2f step=%.2f pageinc=%.2f',
    [Adj^.get_value, Adj^.get_lower, Adj^.get_upper, Adj^.get_page_size,
     Adj^.get_step_increment, Adj^.get_page_increment]);
end;

procedure TScrollValidationForm.DumpState(const AContext: string;
  const AScrollBar: TScrollBar);
begin
  Log(Format('%s kind=%d pos=%d min=%d max=%d page=%d events scroll=%d change=%d %s',
    [AContext, Ord(AScrollBar.Kind), AScrollBar.Position, AScrollBar.Min,
     AScrollBar.Max, AScrollBar.PageSize, FScrollEvents, FChangeEvents,
     DescribeNative(AScrollBar)]));
end;

procedure TScrollValidationForm.NativeSetValue(const AScrollBar: TScrollBar;
  AValue: Double);
var
  Widget: TGtk4Widget;
  Adj: PGtkAdjustment;
begin
  if not AScrollBar.HandleAllocated then
  begin
    Log('native-set skipped no handle');
    Exit;
  end;
  Widget := TGtk4Widget(AScrollBar.Handle);
  Adj := gtk4_scrollbar_get_adjustment(Widget.Widget);
  if Adj = nil then
  begin
    Log('native-set skipped no adjustment');
    Exit;
  end;
  Log(Format('native-set request kind=%d value=%.2f', [Ord(AScrollBar.Kind), AValue]));
  Adj^.set_value(AValue);
end;

procedure TScrollValidationForm.SetBoth(APosition, AMin, AMax, APageSize: Integer);
begin
  FHScroll.SetParams(APosition, AMin, AMax, APageSize);
  FVScroll.SetParams(APosition, AMin, AMax, APageSize);
  DumpState('after SetBoth horizontal', FHScroll);
  DumpState('after SetBoth vertical', FVScroll);
end;

procedure TScrollValidationForm.ConfigureCase0(Sender: TObject);
begin
  SetBoth(0, 0, 100, 0);
end;

procedure TScrollValidationForm.ConfigureCase1(Sender: TObject);
begin
  SetBoth(0, 0, 100, 10);
end;

procedure TScrollValidationForm.ConfigureCase2(Sender: TObject);
begin
  SetBoth(75, 50, 150, 20);
end;

procedure TScrollValidationForm.ConfigureCase3(Sender: TObject);
begin
  SetBoth(0, 0, 10, 20);
end;

procedure TScrollValidationForm.ConfigureKindSwap(Sender: TObject);
var
  HKind, VKind: TScrollBarKind;
begin
  HKind := FHScroll.Kind;
  VKind := FVScroll.Kind;
  FHScroll.Kind := VKind;
  FVScroll.Kind := HKind;
  DumpState('after kind swap h', FHScroll);
  DumpState('after kind swap v', FVScroll);
end;

procedure TScrollValidationForm.ConfigureProgrammaticPosition(Sender: TObject);
begin
  FHScroll.Position := FHScroll.Position + 7;
  FVScroll.Position := FVScroll.Position + 7;
  DumpState('after programmatic h', FHScroll);
  DumpState('after programmatic v', FVScroll);
end;

procedure TScrollValidationForm.ScrollBarScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
  Inc(FScrollEvents);
  Log(Format('EVENT OnScroll sender-kind=%d code=%s arg=%d',
    [Ord(TScrollBar(Sender).Kind), ScrollCodeName(ScrollCode), ScrollPos]));
  DumpState('during OnScroll', TScrollBar(Sender));
end;

procedure TScrollValidationForm.ScrollBarChange(Sender: TObject);
begin
  Inc(FChangeEvents);
  Log(Format('EVENT OnChange sender-kind=%d', [Ord(TScrollBar(Sender).Kind)]));
  DumpState('during OnChange', TScrollBar(Sender));
end;

procedure TScrollValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  Log('AUTO begin');
  SetBoth(0, 0, 100, 10);
  NativeSetValue(FHScroll, 25);
  DumpState('after native h=25', FHScroll);
  NativeSetValue(FVScroll, 40);
  DumpState('after native v=40', FVScroll);
  SetBoth(75, 50, 150, 20);
  NativeSetValue(FHScroll, 120);
  DumpState('after native h=120', FHScroll);
  NativeSetValue(FVScroll, 160);
  DumpState('after native v=160', FVScroll);

  { PageSize-only assignment, as the IDE Object Inspector does when the
    PageSize property is edited. With the pre-fix adjustment feedback
    (upper = Max + PageSize fed back into SetParams) this walked Max and
    could move Position; post-fix both must stay put. Idle re-reads catch
    delayed creep from queued adjustment notifications. }
  SetBoth(30, 0, 100, 10);
  Application.ProcessMessages;
  DumpState('pagesize-probe baseline', FHScroll);
  FHScroll.PageSize := 25;
  Application.ProcessMessages;
  DumpState('after pagesize-only-25', FHScroll);
  FHScroll.PageSize := 5;
  Application.ProcessMessages;
  DumpState('after pagesize-only-5', FHScroll);
  Application.ProcessMessages;
  DumpState('after pagesize idle-reread', FHScroll);

  Log('AUTO end');
  Application.Terminate;
end;

procedure TScrollValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  DumpState('final horizontal', FHScroll);
  DumpState('final vertical', FVScroll);
  Application.Terminate;
end;

begin
  Application.Initialize;
  Application.CreateForm(TScrollValidationForm, ScrollValidationForm);
  Application.Run;
end.
