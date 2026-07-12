program calendar_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Types, Forms, Controls, StdCtrls, ExtCtrls,
  Calendar, Gtk4Widgets, LazGtk4, LazGObject2, LazGLib2, Gtk4Procs;

type
  TCalendarValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FCalendar: TCalendar;
    FChangeCount: Integer;
    procedure AutoTimer(Sender: TObject);
    procedure CalendarChange(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure AppException(Sender: TObject; E: Exception);
    function BoolProperty(const AName: PGChar): Boolean;
    function NativeDateText: string;
    procedure Log(const S: string);
    procedure LogState(const AContext: string);
    procedure LogHitTests(const AContext: string);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  CalendarValidationForm: TCalendarValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('CALENDAR_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('CALENDAR_VALIDATION_CLOSE_MS'), 0);
end;

function BoolName(AValue: Boolean): string;
begin
  Result := BoolToStr(AValue, True);
end;

function PartName(APart: TCalendarPart): string;
begin
  case APart of
    cpNoWhere: Result := 'cpNoWhere';
    cpDate: Result := 'cpDate';
    cpWeekNumber: Result := 'cpWeekNumber';
    cpTitle: Result := 'cpTitle';
    cpTitleBtn: Result := 'cpTitleBtn';
    cpTitleMonth: Result := 'cpTitleMonth';
    cpTitleYear: Result := 'cpTitleYear';
  else
    Result := 'unknown';
  end;
end;

function ViewName(AView: TCalendarView): string;
begin
  case AView of
    cvMonth: Result := 'cvMonth';
    cvYear: Result := 'cvYear';
    cvDecade: Result := 'cvDecade';
    cvCentury: Result := 'cvCentury';
  else
    Result := 'unknown';
  end;
end;

function DisplaySettingsName(ASettings: TDisplaySettings): string;
begin
  Result := '';
  if dsShowHeadings in ASettings then Result := Result + 'headings,';
  if dsShowDayNames in ASettings then Result := Result + 'daynames,';
  if dsNoMonthChange in ASettings then Result := Result + 'nomonthchange,';
  if dsShowWeekNumbers in ASettings then Result := Result + 'weeknumbers,';
  if Result = '' then
    Result := 'none'
  else
    Delete(Result, Length(Result), 1);
end;

constructor TCalendarValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 Calendar validation';
  Position := poDesigned;
  SetBounds(100, 100, 780, 620);

  FCalendar := TCalendar.Create(Self);
  FCalendar.Parent := Self;
  FCalendar.SetBounds(24, 24, 330, 260);
  FCalendar.DateTime := EncodeDate(2026, 7, 9);
  FCalendar.DisplaySettings := [dsShowHeadings, dsShowDayNames, dsShowWeekNumbers];
  FCalendar.OnChange := @CalendarChange;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 308, 720, 240);
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

  Application.OnException := @AppException;
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TCalendarValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolName(AutoMode));
  LogState('after-show');
  LogHitTests('after-show');
  if (not AutoMode) and (CloseInterval > 0) then
    FCloseTimer.Enabled := True;
end;

procedure TCalendarValidationForm.CalendarChange(Sender: TObject);
begin
  Inc(FChangeCount);
end;

procedure TCalendarValidationForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

function TCalendarValidationForm.BoolProperty(const AName: PGChar): Boolean;
var
  Val: TGValue;
  W: PGtkWidget;
begin
  Result := False;
  if not FCalendar.HandleAllocated then
    Exit;
  W := TGtk4Calendar(FCalendar.Handle).GetContainerWidget;
  if W = nil then
    Exit;
  FillByte(Val{%H-}, SizeOf(Val), 0);
  Val.init(G_TYPE_BOOLEAN);
  g_object_get_property(PGObject(W), AName, @Val);
  Result := Val.get_boolean;
  Val.unset;
end;

function TCalendarValidationForm.NativeDateText: string;
var
  Y, M, D: LongWord;
begin
  Result := 'no-handle';
  if FCalendar.HandleAllocated then
  begin
    TGtk4Calendar(FCalendar.Handle).GetDate(Y, M, D);
    Result := Format('%d-%2.2d-%2.2d', [Y, M + 1, D]);
  end;
end;

procedure TCalendarValidationForm.LogState(const AContext: string);
begin
  Log(Format('%s lcl.date=%s native.date=%s display=%s native.heading=%s native.daynames=%s native.weeknumbers=%s firstday=%d view=%s changes=%d',
    [AContext,
     FormatDateTime('yyyy-mm-dd', FCalendar.DateTime),
     NativeDateText,
     DisplaySettingsName(FCalendar.DisplaySettings),
     BoolName(BoolProperty('show-heading')),
     BoolName(BoolProperty('show-day-names')),
     BoolName(BoolProperty('show-week-numbers')),
     Ord(FCalendar.FirstDayOfWeek),
     ViewName(FCalendar.GetCalendarView),
     FChangeCount]));
end;

procedure TCalendarValidationForm.LogHitTests(const AContext: string);
var
  W: Integer;
  H: Integer;
begin
  W := FCalendar.Width;
  H := FCalendar.Height;
  Log(Format('%s hit title-left=%s title-center=%s title-right=%s body-left=%s body-center=%s body-right=%s',
    [AContext,
     PartName(FCalendar.HitTest(Point(W div 8, 16))),
     PartName(FCalendar.HitTest(Point(W div 2, 16))),
     PartName(FCalendar.HitTest(Point((W * 7) div 8, 16))),
     PartName(FCalendar.HitTest(Point(W div 8, H div 2))),
     PartName(FCalendar.HitTest(Point(W div 2, H div 2))),
     PartName(FCalendar.HitTest(Point((W * 7) div 8, H div 2)))]));
end;

procedure TCalendarValidationForm.RunChecks;
begin
  LogState('initial');
  LogHitTests('initial');

  FCalendar.DateTime := EncodeDate(2026, 12, 25);
  Application.ProcessMessages;
  LogState('after-date-2026-12-25');

  FCalendar.DisplaySettings := [dsShowHeadings, dsShowDayNames];
  Application.ProcessMessages;
  LogState('after-no-weeknumbers');
  LogHitTests('after-no-weeknumbers');

  FCalendar.DisplaySettings := [dsShowHeadings, dsShowDayNames, dsShowWeekNumbers, dsNoMonthChange];
  Application.ProcessMessages;
  LogState('after-nomonthchange-with-weeknumbers');
  LogHitTests('after-nomonthchange-with-weeknumbers');

  FCalendar.DisplaySettings := [];
  Application.ProcessMessages;
  LogState('after-display-none');
  LogHitTests('after-display-none');

  FCalendar.DisplaySettings := [dsShowHeadings, dsShowDayNames, dsShowWeekNumbers];
  FCalendar.FirstDayOfWeek := dowMonday;
  Application.ProcessMessages;
  LogState('after-firstday-monday');

  FCalendar.MinDate := EncodeDate(2026, 7, 10);
  FCalendar.MaxDate := EncodeDate(2026, 7, 20);
  Application.ProcessMessages;
  LogState('after-minmax-2026-07-10-20');

  try
    FCalendar.DateTime := EncodeDate(2026, 7, 1);
  except
    on E: Exception do
      Log('set-date-before-min exception=' + E.ClassName + ': ' + E.Message);
  end;
  Application.ProcessMessages;
  LogState('after-set-before-min');

  Application.Terminate;
end;

procedure TCalendarValidationForm.AutoTimer(Sender: TObject);
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

procedure TCalendarValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  Log('manual-close-timer');
  Application.Terminate;
end;

procedure TCalendarValidationForm.AppException(Sender: TObject; E: Exception);
begin
  Log('APPLICATION_EXCEPTION ' + E.ClassName + ': ' + E.Message);
  if AutoMode then
    Application.Terminate;
end;

begin
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TCalendarValidationForm, CalendarValidationForm);
  Application.Run;
end.
