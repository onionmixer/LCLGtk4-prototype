program constraints_validation;

{$mode objfpc}{$H+}

{ Focused validation for the GTK4 window-constraints "max acts as effective
  minimum" defect (audit §5.7). LCL contract: Constraints.Max limits growth,
  Constraints.Min limits shrink; they are independent. The GTK4
  ConstraintsChange used to coerce Min:=Max, so a Max-only window could not be
  made smaller than Max (programmatically or by the WM). This checks:
   A. Max-only window can be resized BELOW max (the fix).
   B. Max is still enforced (cannot grow beyond max).
   C. Min=Max fixed-size window stays fixed (no regression). }

uses
  Interfaces, Classes, SysUtils, Forms, Controls, ExtCtrls, LCLType,
  Gtk4Widgets, LazGtk4, LazGLib2;

type
  TConstraintsForm = class(TForm)
  private
    FAutoTimer: TTimer;
    procedure AutoTimer(Sender: TObject);
    procedure Expect(const ALabel: string; ACond: Boolean);
    procedure Log(const S: string);
    procedure LogSize(const AContext: string; F: TForm);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  ConstraintsForm: TConstraintsForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('CONSTRAINTS_VALIDATION_AUTO') = '1';
end;

constructor TConstraintsForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 constraints validation';
  Position := poDesigned;
  SetBounds(120, 120, 700, 500);

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 500;
  FAutoTimer.OnTimer := @AutoTimer;
end;

procedure TConstraintsForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
end;

procedure TConstraintsForm.LogSize(const AContext: string; F: TForm);
var
  W: TGtk4Widget;
  DefW, DefH, ReqW, ReqH: gint;
begin
  DefW := -1; DefH := -1; ReqW := -1; ReqH := -1;
  if F.HandleAllocated then
  begin
    W := TGtk4Widget(F.Handle);
    if W.Widget <> nil then
    begin
      PGtkWindow(W.Widget)^.get_default_size(@DefW, @DefH);
      W.Widget^.get_size_request(@ReqW, @ReqH);
    end;
  end;
  Log(Format('%s lcl=(%d,%d) client=(%d,%d) constraints[min=(%d,%d) max=(%d,%d)] native[default=(%d,%d) request=(%d,%d)]',
    [AContext, F.Width, F.Height, F.ClientWidth, F.ClientHeight,
     F.Constraints.MinWidth, F.Constraints.MinHeight,
     F.Constraints.MaxWidth, F.Constraints.MaxHeight,
     DefW, DefH, ReqW, ReqH]));
end;

procedure TConstraintsForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TConstraintsForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunChecks;
  except
    on E: Exception do
    begin
      Log('EXCEPTION ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
  Application.Terminate;
end;

{ Native GTK minimum (set_size_request height) for a form. }
function NativeReqH(F: TForm): gint;
var
  W: TGtk4Widget;
  ReqW, ReqH: gint;
begin
  Result := -1;
  if F.HandleAllocated then
  begin
    W := TGtk4Widget(F.Handle);
    if W.Widget <> nil then
    begin
      W.Widget^.get_size_request(@ReqW, @ReqH);
      Result := ReqH;
    end;
  end;
end;

procedure TConstraintsForm.Expect(const ALabel: string; ACond: Boolean);
begin
  if not ACond then
  begin
    Log('FAIL ' + ALabel);
    ExitCode := 1;
  end;
end;

procedure TConstraintsForm.RunChecks;
var
  FA, FC: TForm;
begin
  { Case A/B: Max-only window (no Min). }
  FA := TForm.CreateNew(Self);
  try
    FA.Caption := 'MaxOnly';
    FA.Position := poDesigned;
    FA.SetBounds(140, 140, 400, 300);
    FA.Constraints.MaxWidth := 400;
    FA.Constraints.MaxHeight := 300;
    FA.Show;
    Application.ProcessMessages;
    LogSize('A0-maxonly-shown', FA);

    { Max-only form has no forced GTK minimum. }
    Expect('A0-maxonly-no-forced-min', NativeReqH(FA) <= 0);

    { A: shrink BELOW max — height must actually shrink (was stuck at 300). }
    FA.SetBounds(140, 140, 200, 150);
    Application.ProcessMessages;
    LogSize('A1-maxonly-shrink-200x150', FA);
    Expect('A1-maxonly-height-shrinks', FA.Height < 300);

    { B: grow ABOVE max — must clamp to 400x300. }
    FA.SetBounds(140, 140, 600, 480);
    Application.ProcessMessages;
    LogSize('B1-maxonly-grow-600x480', FA);
    Expect('B1-maxonly-width-clamped', FA.ClientWidth <= 400);
    Expect('B1-maxonly-height-clamped', FA.ClientHeight <= 300);
  finally
    FA.Free;
  end;

  { Case C: fixed-size window (Min=Max) must stay fixed. }
  FC := TForm.CreateNew(Self);
  try
    FC.Caption := 'Fixed';
    FC.Position := poDesigned;
    FC.SetBounds(160, 160, 360, 260);
    FC.Constraints.MinWidth := 360;
    FC.Constraints.MinHeight := 260;
    FC.Constraints.MaxWidth := 360;
    FC.Constraints.MaxHeight := 260;
    FC.Show;
    Application.ProcessMessages;
    LogSize('C0-fixed-shown', FC);

    FC.SetBounds(160, 160, 200, 150);
    Application.ProcessMessages;
    LogSize('C1-fixed-shrink-attempt', FC);
    Expect('C1-fixed-stays-360x260',
      (FC.ClientWidth = 360) and (FC.ClientHeight = 260));

    FC.SetBounds(160, 160, 500, 400);
    Application.ProcessMessages;
    LogSize('C2-fixed-grow-attempt', FC);
    Expect('C2-fixed-stays-360x260',
      (FC.ClientWidth = 360) and (FC.ClientHeight = 260));
  finally
    FC.Free;
  end;

  Log('DONE');
end;

begin
  Application.Initialize;
  Application.CreateForm(TConstraintsForm, ConstraintsForm);
  Application.Run;
end.
