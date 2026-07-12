program menu_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Menus,
  Graphics, LCLType, Gtk4Widgets, LazGio2, LazGLib2;

type
  TMenuValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FMain: TMainMenu;
    FPopup: TPopupMenu;
    FMarker: TPanel;
    FNormal: TMenuItem;
    FShortcut: TMenuItem;
    FCheck: TMenuItem;
    FRadio1: TMenuItem;
    FRadio2: TMenuItem;
    FDisabled: TMenuItem;
    FHidden: TMenuItem;
    FClickLog: TStringList;
    FPopupCount: Integer;
    FCloseCount: Integer;
    FHintCount: Integer;
    FLastHint: string;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure CreateButton(const ACaption: string; ALeft: Integer;
      AHandler: TNotifyEvent);
    function CreateMenuItem(const ACaption: string; AOnClick: TNotifyEvent): TMenuItem;
    procedure EnsureHandles;
    procedure HintEvent(Sender: TObject);
    procedure ItemClick(Sender: TObject);
    procedure Log(const S: string);
    procedure LogItem(const AName: string; AItem: TMenuItem);
    procedure LogSummary(const AContext: string);
    procedure PlacePopupMarker(AScreenX, AScreenY: Integer);
    procedure PopupClose(Sender: TObject);
    procedure PopupCenter(Sender: TObject);
    procedure PopupEvent(Sender: TObject);
    procedure PopupLeft(Sender: TObject);
    procedure PopupRight(Sender: TObject);
    procedure RunChecks;
    procedure TriggerAction(AItem: TMenuItem; ACheckState: Integer);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MenuValidationForm: TMenuValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('MENU_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('MENU_VALIDATION_CLOSE_MS'), 0);
end;

function VariantText(AValue: PGVariant): string;
var
  P: Pgchar;
begin
  if AValue = nil then
    Exit('nil');
  P := g_variant_print(AValue, True);
  try
    if P <> nil then
      Result := StrPas(P)
    else
      Result := 'nil-print';
  finally
    if P <> nil then
      g_free(P);
  end;
end;

constructor TMenuValidationForm.Create(AOwner: TComponent);
var
  Root: TMenuItem;
begin
  inherited Create(AOwner);
  Caption := 'GTK4 Menu validation';
  Position := poDesigned;
  SetBounds(100, 100, 820, 560);

  FClickLog := TStringList.Create;

  FMain := TMainMenu.Create(Self);
  Menu := FMain;
  Root := TMenuItem.Create(FMain);
  Root.Caption := '&File';
  FMain.Items.Add(Root);

  FNormal := CreateMenuItem('&Normal', @ItemClick);
  Root.Add(FNormal);
  FShortcut := CreateMenuItem('&Shortcut', @ItemClick);
  FShortcut.ShortCut := ShortCut(VK_N, [ssCtrl]);
  Root.Add(FShortcut);
  FCheck := CreateMenuItem('&Check', @ItemClick);
  FCheck.AutoCheck := True;
  FCheck.Checked := False;
  Root.Add(FCheck);
  FRadio1 := CreateMenuItem('Radio &One', @ItemClick);
  FRadio1.RadioItem := True;
  FRadio1.GroupIndex := 7;
  FRadio1.AutoCheck := True;
  FRadio1.Checked := True;
  Root.Add(FRadio1);
  FRadio2 := CreateMenuItem('Radio &Two', @ItemClick);
  FRadio2.RadioItem := True;
  FRadio2.GroupIndex := 7;
  FRadio2.AutoCheck := True;
  Root.Add(FRadio2);
  FDisabled := CreateMenuItem('&Disabled', @ItemClick);
  FDisabled.Enabled := False;
  Root.Add(FDisabled);
  FHidden := CreateMenuItem('&Hidden', @ItemClick);
  FHidden.Visible := False;
  Root.Add(FHidden);

  FPopup := TPopupMenu.Create(Self);
  FPopup.OnPopup := @PopupEvent;
  FPopup.OnClose := @PopupClose;
  FPopup.Items.Add(CreateMenuItem('Popup &Normal', @ItemClick));
  FPopup.Items.Add(CreateMenuItem('Popup &Check', @ItemClick));
  FPopup.Items[1].AutoCheck := True;
  FPopup.Items.Add(CreateMenuItem('Popup Radio &A', @ItemClick));
  FPopup.Items[2].RadioItem := True;
  FPopup.Items[2].GroupIndex := 3;
  FPopup.Items[2].AutoCheck := True;
  FPopup.Items[2].Checked := True;
  FPopup.Items.Add(CreateMenuItem('Popup Radio &B', @ItemClick));
  FPopup.Items[3].RadioItem := True;
  FPopup.Items[3].GroupIndex := 3;
  FPopup.Items[3].AutoCheck := True;

  { Red marker showing the intended popup screen point, for screenshot
    measurement of TPopupMenu.Alignment placement. }
  FMarker := TPanel.Create(Self);
  FMarker.Parent := Self;
  FMarker.Color := clRed;
  FMarker.BevelOuter := bvNone;
  FMarker.SetBounds(-20, -20, 8, 8);
  FMarker.Visible := False;

  CreateButton('Popup Left', 24, @PopupLeft);
  CreateButton('Popup Center', 136, @PopupCenter);
  CreateButton('Popup Right', 268, @PopupRight);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 72, 760, 420);
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

  Application.ShowHint := True;
  Application.OnHint := @HintEvent;
end;

destructor TMenuValidationForm.Destroy;
begin
  FClickLog.Free;
  inherited Destroy;
end;

function TMenuValidationForm.CreateMenuItem(const ACaption: string;
  AOnClick: TNotifyEvent): TMenuItem;
begin
  Result := TMenuItem.Create(Self);
  Result.Caption := ACaption;
  Result.Hint := 'hint ' + StringReplace(ACaption, '&', '', [rfReplaceAll]);
  Result.OnClick := AOnClick;
end;

procedure TMenuValidationForm.CreateButton(const ACaption: string; ALeft: Integer;
  AHandler: TNotifyEvent);
var
  Button: TButton;
begin
  Button := TButton.Create(Self);
  Button.Parent := Self;
  Button.Caption := ACaption;
  Button.SetBounds(ALeft, 24, 104, 28);
  Button.OnClick := AHandler;
end;

procedure TMenuValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TMenuValidationForm.EnsureHandles;
begin
  FMain.HandleNeeded;
  FMain.Items.HandleNeeded;
  FNormal.HandleNeeded;
  FShortcut.HandleNeeded;
  FCheck.HandleNeeded;
  FRadio1.HandleNeeded;
  FRadio2.HandleNeeded;
  FDisabled.HandleNeeded;
  if FHidden.Visible then
    FHidden.HandleNeeded;
  FPopup.HandleNeeded;
  FPopup.Items.HandleNeeded;
  Application.ProcessMessages;
end;

procedure TMenuValidationForm.HintEvent(Sender: TObject);
begin
  Inc(FHintCount);
  FLastHint := Application.Hint;
  Log('EVENT OnHint hint=' + FLastHint + ' total=' + IntToStr(FHintCount));
end;

procedure TMenuValidationForm.ItemClick(Sender: TObject);
begin
  if Sender is TMenuItem then
    FClickLog.Add(TMenuItem(Sender).Caption + ' checked=' + BoolToStr(TMenuItem(Sender).Checked, True));
end;

procedure TMenuValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TMenuValidationForm.LogItem(const AName: string; AItem: TMenuItem);
var
  GtkItem: TGtk4MenuItem;
  State: PGVariant;
  Accel: PGVariant;
  EnabledText: string;
begin
  if not AItem.HandleAllocated then
  begin
    Log(Format('%s handle=0 visible=%s enabled=%s checked=%s radio=%s',
      [AName, BoolToStr(AItem.Visible, True), BoolToStr(AItem.Enabled, True),
       BoolToStr(AItem.Checked, True), BoolToStr(AItem.RadioItem, True)]));
    Exit;
  end;

  GtkItem := TGtk4MenuItem(AItem.Handle);
  if GtkItem.Action <> nil then
  begin
    State := g_action_get_state(PGAction(GtkItem.Action));
    try
      EnabledText := BoolToStr(g_action_get_enabled(PGAction(GtkItem.Action)), True);
      Accel := nil;
      if GtkItem.FGMenuItem <> nil then
        Accel := g_menu_item_get_attribute_value(GtkItem.FGMenuItem, 'accel', nil);
      try
        Log(Format('%s handle=%d action=%s action_enabled=%s action_state=%s accel=%s visible=%s enabled=%s checked=%s radio=%s group=%d shortcut=%d',
          [AName, PtrUInt(AItem.Handle), GtkItem.ActionName, EnabledText,
           VariantText(State), VariantText(Accel), BoolToStr(AItem.Visible, True),
           BoolToStr(AItem.Enabled, True), BoolToStr(AItem.Checked, True),
           BoolToStr(AItem.RadioItem, True), AItem.GroupIndex, AItem.ShortCut]));
      finally
        if Accel <> nil then
          g_variant_unref(Accel);
      end;
    finally
      if State <> nil then
        g_variant_unref(State);
    end;
  end
  else
    Log(AName + ' action=nil');
end;

procedure TMenuValidationForm.LogSummary(const AContext: string);
var
  I: Integer;
begin
  Log(Format('%s popup_count=%d close_count=%d hint_count=%d last_hint=%s click_log_count=%d',
    [AContext, FPopupCount, FCloseCount, FHintCount, FLastHint, FClickLog.Count]));
  for I := 0 to FClickLog.Count - 1 do
    Log(AContext + ' click_log[' + IntToStr(I) + ']=' + FClickLog[I]);
end;

procedure TMenuValidationForm.TriggerAction(AItem: TMenuItem; ACheckState: Integer);
var
  GtkItem: TGtk4MenuItem;
begin
  if not AItem.HandleAllocated then
    Exit;
  GtkItem := TGtk4MenuItem(AItem.Handle);
  if GtkItem.Action = nil then
    Exit;
  if AItem.RadioItem then
    { Radio actions are string-typed with a fixed 'on' target; a real menu
      click makes GtkMenuTracker call g_action_activate with the target. }
    g_action_activate(PGAction(GtkItem.Action), g_variant_new_string('on'))
  else if ACheckState < 0 then
    g_action_activate(PGAction(GtkItem.Action), nil)
  else
    g_action_change_state(PGAction(GtkItem.Action), g_variant_new_boolean(ACheckState <> 0));
  Application.ProcessMessages;
end;

procedure TMenuValidationForm.RunChecks;
var
  I: Integer;
begin
  EnsureHandles;
  LogItem('normal initial', FNormal);
  LogItem('shortcut initial', FShortcut);
  LogItem('check initial', FCheck);
  LogItem('radio1 initial', FRadio1);
  LogItem('radio2 initial', FRadio2);
  LogItem('disabled initial', FDisabled);
  LogItem('hidden initial', FHidden);

  TriggerAction(FNormal, -1);
  TriggerAction(FCheck, 1);
  TriggerAction(FRadio2, 1);

  LogItem('normal after action', FNormal);
  LogItem('check after action', FCheck);
  LogItem('radio1 after radio2 action', FRadio1);
  LogItem('radio2 after action', FRadio2);

  { Runtime GroupIndex-merge probe: put radio1 back on (so it is checked in
    group 7 while radio2 is unchecked), then move radio1 into a NEW group
    where a DIFFERENT checked radio already lives. LCL SetGroupIndex calls
    TurnSiblingsOff (clears sibling FChecked directly, no WS SetCheck), so
    without a GTK4-side resync the sibling's native action stays stale. }
  TriggerAction(FRadio1, 1);              { radio1 checked in group 7 }
  FRadio2.GroupIndex := 9;               { park radio2 alone in group 9 }
  FRadio2.Checked := True;               { radio2 checked in group 9 }
  Application.ProcessMessages;
  LogItem('groupmerge-before radio1(g7,checked)', FRadio1);
  LogItem('groupmerge-before radio2(g9,checked)', FRadio2);
  { Merge radio1 into group 9 while checked — this must turn radio2 off both
    in LCL AND natively. }
  FRadio1.GroupIndex := 9;
  Application.ProcessMessages;
  LogItem('groupmerge-after radio1(g9)', FRadio1);
  LogItem('groupmerge-after radio2(g9)', FRadio2);

  Log('click_log_count=' + IntToStr(FClickLog.Count));
  for I := 0 to FClickLog.Count - 1 do
    Log('click_log[' + IntToStr(I) + ']=' + FClickLog[I]);
  LogSummary('auto summary');
  Log('AUTO end');
end;

procedure TMenuValidationForm.PopupEvent(Sender: TObject);
begin
  Inc(FPopupCount);
  Log(Format('EVENT OnPopup alignment=%d popup_point=%d,%d component=%s total=%d',
    [Ord(FPopup.Alignment), FPopup.PopupPoint.X, FPopup.PopupPoint.Y,
     BoolToStr(FPopup.PopupComponent <> nil, True), FPopupCount]));
end;

procedure TMenuValidationForm.PopupClose(Sender: TObject);
begin
  Inc(FCloseCount);
  Log(Format('EVENT OnClose alignment=%d total=%d',
    [Ord(FPopup.Alignment), FCloseCount]));
end;

procedure TMenuValidationForm.PlacePopupMarker(AScreenX, AScreenY: Integer);
var
  P: TPoint;
begin
  P := ScreenToClient(Point(AScreenX, AScreenY));
  FMarker.SetBounds(P.X - 4, P.Y - 4, 8, 8);
  FMarker.Visible := True;
end;

procedure TMenuValidationForm.PopupLeft(Sender: TObject);
begin
  FPopup.Alignment := paLeft;
  PlacePopupMarker(Left + 100, Top + 240);
  FPopup.PopUp(Left + 100, Top + 240);
end;

procedure TMenuValidationForm.PopupCenter(Sender: TObject);
begin
  FPopup.Alignment := paCenter;
  PlacePopupMarker(Left + 300, Top + 240);
  FPopup.PopUp(Left + 300, Top + 240);
end;

procedure TMenuValidationForm.PopupRight(Sender: TObject);
begin
  FPopup.Alignment := paRight;
  PlacePopupMarker(Left + 500, Top + 240);
  FPopup.PopUp(Left + 500, Top + 240);
end;

procedure TMenuValidationForm.AutoTimer(Sender: TObject);
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

procedure TMenuValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  LogSummary('close summary');
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TMenuValidationForm, MenuValidationForm);
  Application.Run;
end.
