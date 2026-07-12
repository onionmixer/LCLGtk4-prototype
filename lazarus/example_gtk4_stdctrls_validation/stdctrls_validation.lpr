program stdctrls_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, LCLType,
  Gtk4Widgets, LazGtk4, LazGtk4_Compat;

type
  TStdCtrlsValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FStatic: TStaticText;
    FButton: TButton;
    FCheck: TCheckBox;
    FToggle: TToggleBox;
    FRadio1: TRadioButton;
    FRadio2: TRadioButton;
    FRadioGroup: TRadioGroup;
    FClickCount: Integer;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure ButtonClick(Sender: TObject);
    procedure Log(const S: string);
    procedure LogState(const AContext: string);
    procedure LogRadioGroupNative(const AContext: string);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  StdCtrlsValidationForm: TStdCtrlsValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('STDCTRLS_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('STDCTRLS_VALIDATION_CLOSE_MS'), 0);
end;

function CheckStateName(AState: TCheckBoxState): string;
begin
  case AState of
    cbUnchecked: Result := 'cbUnchecked';
    cbChecked: Result := 'cbChecked';
    cbGrayed: Result := 'cbGrayed';
  else
    Result := 'unknown';
  end;
end;

function StaticBorderName(AStyle: TStaticBorderStyle): string;
begin
  case AStyle of
    sbsNone: Result := 'sbsNone';
    sbsSingle: Result := 'sbsSingle';
    sbsSunken: Result := 'sbsSunken';
  else
    Result := 'unknown';
  end;
end;

constructor TStdCtrlsValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 StdCtrls validation';
  Position := poDesigned;
  SetBounds(100, 100, 780, 580);

  FStatic := TStaticText.Create(Self);
  FStatic.Parent := Self;
  FStatic.Caption := 'StaticText border/alignment';
  FStatic.SetBounds(24, 24, 220, 32);
  FStatic.Alignment := taCenter;
  FStatic.BorderStyle := sbsNone;

  FButton := TButton.Create(Self);
  FButton.Parent := Self;
  FButton.Caption := 'Default Button';
  FButton.SetBounds(280, 24, 140, 32);
  FButton.Default := True;
  FButton.OnClick := @ButtonClick;

  FCheck := TCheckBox.Create(Self);
  FCheck.Parent := Self;
  FCheck.Caption := 'Allow grayed checkbox';
  FCheck.AllowGrayed := True;
  FCheck.State := cbGrayed;
  FCheck.SetBounds(24, 76, 220, 28);

  FToggle := TToggleBox.Create(Self);
  FToggle.Parent := Self;
  FToggle.Caption := 'Toggle grayed';
  FToggle.State := cbGrayed;
  FToggle.SetBounds(280, 76, 140, 32);

  FRadio1 := TRadioButton.Create(Self);
  FRadio1.Parent := Self;
  FRadio1.Caption := 'Radio 1';
  FRadio1.Checked := True;
  FRadio1.SetBounds(24, 124, 120, 28);

  FRadio2 := TRadioButton.Create(Self);
  FRadio2.Parent := Self;
  FRadio2.Caption := 'Radio 2';
  FRadio2.SetBounds(160, 124, 120, 28);

  FRadioGroup := TRadioGroup.Create(Self);
  FRadioGroup.Parent := Self;
  FRadioGroup.Caption := 'RadioGroup';
  FRadioGroup.Items.Add('Group A');
  FRadioGroup.Items.Add('Group B');
  FRadioGroup.ItemIndex := 0;
  FRadioGroup.SetBounds(24, 172, 220, 92);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 292, 700, 220);
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

procedure TStdCtrlsValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TStdCtrlsValidationForm.ButtonClick(Sender: TObject);
begin
  Inc(FClickCount);
end;

procedure TStdCtrlsValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TStdCtrlsValidationForm.LogState(const AContext: string);
var
  StaticGtk: TGtk4StaticText;
  ButtonGtk: TGtk4Button;
  CheckGtk: TGtk4CheckBox;
  ToggleGtk: TGtk4Widget;
  Radio1Gtk: TGtk4RadioButton;
  Radio2Gtk: TGtk4RadioButton;
begin
  StaticGtk := TGtk4StaticText(FStatic.Handle);
  ButtonGtk := TGtk4Button(FButton.Handle);
  CheckGtk := TGtk4CheckBox(FCheck.Handle);
  ToggleGtk := TGtk4Widget(FToggle.Handle);
  Radio1Gtk := TGtk4RadioButton(FRadio1.Handle);
  Radio2Gtk := TGtk4RadioButton(FRadio2.Handle);

  Log(Format('%s static.lcl=%s static.native=%s button.default=%s button.native_receives_default=%s check.lcl=%s check.native=%s toggle.lcl=%s toggle.native_active=%s radio1.lcl=%s radio1.native=%s radio2.lcl=%s radio2.native=%s radiogroup.index=%d click_count=%d',
    [AContext,
     StaticBorderName(FStatic.BorderStyle),
     StaticBorderName(StaticGtk.StaticBorderStyle),
     BoolToStr(FButton.Default, True),
     BoolToStr(PGtkWidget(ButtonGtk.GetContainerWidget)^.get_receives_default, True), { get_can_default is a constant-False stub }
     CheckStateName(FCheck.State),
     CheckStateName(CheckGtk.State),
     CheckStateName(FToggle.State),
     BoolToStr(gtk_toggle_button_get_active(PGtkToggleButton(ToggleGtk.Widget)), True),
     BoolToStr(FRadio1.Checked, True),
     CheckStateName(Radio1Gtk.State),
     BoolToStr(FRadio2.Checked, True),
     CheckStateName(Radio2Gtk.State),
     FRadioGroup.ItemIndex,
     FClickCount]));
  LogRadioGroupNative(AContext);
end;

{ Log every TRadioButton inside the TRadioGroup — the visible items AND the
  LCL HiddenRadioButton (ItemIndex=-1 helper) — with LCL checked state and
  native widget presence/active state. }
procedure TStdCtrlsValidationForm.LogRadioGroupNative(const AContext: string);
var
  i: Integer;
  C: TControl;
  W: TGtk4Widget;
  NativeState: string;
begin
  for i := 0 to FRadioGroup.ControlCount - 1 do
  begin
    C := FRadioGroup.Controls[i];
    if not (C is TRadioButton) then
      Continue;
    NativeState := 'no-handle';
    if TRadioButton(C).HandleAllocated then
    begin
      W := TGtk4Widget(TRadioButton(C).Handle);
      if W.Widget = nil then
        NativeState := 'nil-widget'
      else
        NativeState := Format('active=%s visible=%s',
          [BoolToStr(gtk4_check_button_get_active(PGtkCheckButton(W.Widget)), True),
           BoolToStr(W.Widget^.visible, True)]);
    end;
    Log(Format('%s group-child[%d] name=%s caption="%s" lcl.checked=%s native(%s)',
      [AContext, i, C.Name, TRadioButton(C).Caption,
       BoolToStr(TRadioButton(C).Checked, True), NativeState]));
  end;
end;

procedure TStdCtrlsValidationForm.RunChecks;
begin
  Application.ProcessMessages;
  Log('widget_shortcuts_source_enabled=False');
  LogState('initial');

  FStatic.BorderStyle := sbsSingle;
  FButton.Click;
  FCheck.State := cbChecked;
  FToggle.State := cbGrayed;
  FRadio2.Checked := True;
  FRadioGroup.ItemIndex := 1;
  Application.ProcessMessages;
  LogState('after programmatic changes');

  FCheck.State := cbGrayed;
  FToggle.State := cbUnchecked;
  FRadio1.Checked := True;
  FRadioGroup.ItemIndex := -1;
  Application.ProcessMessages;
  LogState('after second changes');

  { Rebuild: Items.Clear leaves the HiddenRadioButton as a temporary
    Controls[0], so the new first item must NOT anchor its native group to
    it (hidden stays out of the native group by design). Verify native
    exclusivity still holds after the rebuild. }
  FRadioGroup.Items.Clear;
  Application.ProcessMessages;
  FRadioGroup.Items.Add('Rebuilt A');
  FRadioGroup.Items.Add('Rebuilt B');
  FRadioGroup.ItemIndex := 1;
  Application.ProcessMessages;
  LogState('after items rebuild index=1');
  FRadioGroup.ItemIndex := 0;
  Application.ProcessMessages;
  LogState('after rebuild switch index=0');

  Log('AUTO end');
end;

procedure TStdCtrlsValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunChecks;
  except
    on E: Exception do
      Log('AUTO exception ' + E.ClassName + ': ' + E.Message);
  end;
  Close;
end;

procedure TStdCtrlsValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TStdCtrlsValidationForm, StdCtrlsValidationForm);
  Application.Run;
end.
