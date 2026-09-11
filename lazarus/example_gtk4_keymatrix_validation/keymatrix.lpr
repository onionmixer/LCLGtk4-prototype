program keymatrix;
{$MODE OBJFPC}{$H+}
{ Key-delivery matrix harness. Usage: keymatrix <control> [eatlist]
  <control>: edit spin comboedit combolist memo listbox checklist listview treeview
             button checkbox trackbar grid radio
  eatlist (optional): comma list of VK codes to zero in that control's OnKeyDown, e.g. 13,27
  Logs every OnKeyDown/OnKeyUp/OnKeyPress/OnUTF8KeyPress + form KeyPreview + native effects,
  then prints the final native state and exits after KEYMATRIX_MS ms (default 9000). }
uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Spin,
  Grids, CheckLst, LCLType, LCLProc, TypInfo, LCLPlatformDef, InterfaceBase;

type
  TMain = class(TForm)
  private
    FT0: QWord;
    FTimer: TTimer;
    FIsoTimer: TTimer;
    FTarget: TWinControl;
    FIsolate: Boolean;
    FEat: set of Byte;
    procedure L(const S: String);
    procedure KD(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KU(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure KP(Sender: TObject; var Key: Char);
    procedure U8(Sender: TObject; var UTF8Key: TUTF8Char);
    procedure FormKD(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKU(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Eff(Sender: TObject);
    procedure EditingDoneH(Sender: TObject);
    procedure DefClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure Tick(Sender: TObject);
    procedure IsoTick(Sender: TObject);
    procedure Hook(C: TWinControl);
    function StateOf: String;
  public
    E: TEdit; Sp: TSpinEdit; FSp: TFloatSpinEdit; CE, CL: TComboBox; M: TMemo; LB: TListBox; CLB: TCheckListBox;
    LV: TListView; TV: TTreeView; B, DefB, CanB: TButton; CB: TCheckBox; TB: TTrackBar;
    G: TStringGrid; R: TRadioButton;
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

function N(Sender: TObject): String;
begin
  if Sender = nil then Result := 'nil' else if Sender is TComponent then Result := TComponent(Sender).Name else Result := Sender.ClassName;
end;

procedure TMain.L(const S: String);
begin
  WriteLn(Format('%6d %s', [GetTickCount64 - FT0, S])); Flush(Output);
end;

procedure TMain.KD(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  L(Format('KEYDOWN  %-9s key=%d shift=%s', [N(Sender), Key, SetToString(PTypeInfo(TypeInfo(TShiftState)), Integer(Shift), True)]));
  if (Key < 256) and (Byte(Key) in FEat) then begin L(Format('  -> eaten key=%d', [Key])); Key := 0; end;
end;

procedure TMain.KU(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  L(Format('KEYUP    %-9s key=%d', [N(Sender), Key]));
end;

procedure TMain.KP(Sender: TObject; var Key: Char);
begin
  L(Format('KEYPRESS %-9s char=#%d', [N(Sender), Ord(Key)]));
end;

procedure TMain.U8(Sender: TObject; var UTF8Key: TUTF8Char);
begin
  L(Format('UTF8KEY  %-9s "%s"', [N(Sender), UTF8Key]));
end;

procedure TMain.FormKD(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  L(Format('FORMKD   preview key=%d', [Key]));
  if Key = VK_F5 then begin
    if FSp.DecimalPlaces = 2 then FSp.DecimalPlaces := 3 else FSp.DecimalPlaces := 2;
    L(Format('CMD      fspin.DecimalPlaces=%d value=%s text="%s"', [FSp.DecimalPlaces, FormatFloat('0.000', FSp.Value), FSp.Text]));
  end else if Key = VK_F6 then begin
    FSp.ReadOnly := not FSp.ReadOnly;
    L(Format('CMD      fspin.ReadOnly=%s value=%s', [BoolToStr(FSp.ReadOnly, True), FormatFloat('0.000', FSp.Value)]));
  end else if Key = VK_F7 then
    L(Format('CMD      values spin=%d fspin=%s fspin.text="%s"', [Sp.Value, FormatFloat('0.000', FSp.Value), FSp.Text]));
end;

procedure TMain.FormKU(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  L(Format('FORMKU   preview key=%d', [Key]));
end;

procedure TMain.Eff(Sender: TObject);
begin
  L(Format('EFFECT   %-9s %s', [N(Sender), StateOf]));
end;

procedure TMain.EditingDoneH(Sender: TObject);
begin
  L(Format('EDITINGDONE %s', [N(Sender)]));
end;

procedure TMain.DefClick(Sender: TObject);
begin
  L('DEFAULTBTN click');
end;

procedure TMain.CancelClick(Sender: TObject);
begin
  L('CANCELBTN click');
end;

function TMain.StateOf: String;
begin
  Result := Format('edit="%s" spin=%d fspin=%s comboedit="%s"/%d combolist=%d memo=%dlines listbox=%d checklist=%d/%s listview=%d treeview=%s button=- checkbox=%s trackbar=%d grid=%d,%d radio=%s',
    [E.Text, Sp.Value, FormatFloat('0.00', FSp.Value), CE.Text, CE.ItemIndex, CL.ItemIndex, M.Lines.Count, LB.ItemIndex, CLB.ItemIndex,
     BoolToStr(CLB.Checked[1], True), LV.ItemIndex, BoolToStr(TV.Selected <> nil, True), BoolToStr(CB.Checked, True),
     TB.Position, G.Row, G.Col, BoolToStr(R.Checked, True)]);
end;

procedure TMain.Hook(C: TWinControl);
begin
  if C is TEdit then begin TEdit(C).OnKeyDown := @KD; TEdit(C).OnKeyUp := @KU; TEdit(C).OnKeyPress := @KP; TEdit(C).OnUTF8KeyPress := @U8; TEdit(C).OnChange := @Eff; TEdit(C).OnEditingDone := @EditingDoneH; end
  else if C is TSpinEdit then begin TSpinEdit(C).OnKeyDown := @KD; TSpinEdit(C).OnKeyUp := @KU; TSpinEdit(C).OnKeyPress := @KP; TSpinEdit(C).OnUTF8KeyPress := @U8; TSpinEdit(C).OnChange := @Eff; TSpinEdit(C).OnEditingDone := @EditingDoneH; end
  else if C is TFloatSpinEdit then begin TFloatSpinEdit(C).OnKeyDown := @KD; TFloatSpinEdit(C).OnKeyUp := @KU; TFloatSpinEdit(C).OnKeyPress := @KP; TFloatSpinEdit(C).OnUTF8KeyPress := @U8; TFloatSpinEdit(C).OnChange := @Eff; TFloatSpinEdit(C).OnEditingDone := @EditingDoneH; end
  else if C is TComboBox then begin TComboBox(C).OnKeyDown := @KD; TComboBox(C).OnKeyUp := @KU; TComboBox(C).OnKeyPress := @KP; TComboBox(C).OnUTF8KeyPress := @U8; TComboBox(C).OnChange := @Eff; TComboBox(C).OnSelect := @Eff; TComboBox(C).OnEditingDone := @EditingDoneH; end
  else if C is TMemo then begin TMemo(C).OnKeyDown := @KD; TMemo(C).OnKeyUp := @KU; TMemo(C).OnKeyPress := @KP; TMemo(C).OnUTF8KeyPress := @U8; TMemo(C).OnChange := @Eff; end
  else if C is TCheckListBox then begin TCheckListBox(C).OnKeyDown := @KD; TCheckListBox(C).OnKeyUp := @KU; TCheckListBox(C).OnKeyPress := @KP; TCheckListBox(C).OnUTF8KeyPress := @U8; TCheckListBox(C).OnSelectionChange := nil; TCheckListBox(C).OnClick := @Eff; TCheckListBox(C).OnItemClick := nil; end
  else if C is TListBox then begin TListBox(C).OnKeyDown := @KD; TListBox(C).OnKeyUp := @KU; TListBox(C).OnKeyPress := @KP; TListBox(C).OnUTF8KeyPress := @U8; TListBox(C).OnSelectionChange := nil; TListBox(C).OnClick := @Eff; end
  else if C is TListView then begin TListView(C).OnKeyDown := @KD; TListView(C).OnKeyUp := @KU; TListView(C).OnKeyPress := @KP; TListView(C).OnUTF8KeyPress := @U8; TListView(C).OnSelectItem := nil; TListView(C).OnClick := @Eff; end
  else if C is TTreeView then begin TTreeView(C).OnKeyDown := @KD; TTreeView(C).OnKeyUp := @KU; TTreeView(C).OnKeyPress := @KP; TTreeView(C).OnUTF8KeyPress := @U8; TTreeView(C).OnClick := @Eff; end
  else if C is TButton then begin TButton(C).OnKeyDown := @KD; TButton(C).OnKeyUp := @KU; TButton(C).OnKeyPress := @KP; TButton(C).OnUTF8KeyPress := @U8; TButton(C).OnClick := @Eff; end
  else if C is TCheckBox then begin TCheckBox(C).OnKeyDown := @KD; TCheckBox(C).OnKeyUp := @KU; TCheckBox(C).OnKeyPress := @KP; TCheckBox(C).OnUTF8KeyPress := @U8; TCheckBox(C).OnChange := @Eff; end
  else if C is TRadioButton then begin TRadioButton(C).OnKeyDown := @KD; TRadioButton(C).OnKeyUp := @KU; TRadioButton(C).OnKeyPress := @KP; TRadioButton(C).OnUTF8KeyPress := @U8; TRadioButton(C).OnChange := @Eff; end
  else if C is TTrackBar then begin TTrackBar(C).OnKeyDown := @KD; TTrackBar(C).OnKeyUp := @KU; TTrackBar(C).OnKeyPress := @KP; TTrackBar(C).OnUTF8KeyPress := @U8; TTrackBar(C).OnChange := @Eff; end
  else if C is TStringGrid then begin TStringGrid(C).OnKeyDown := @KD; TStringGrid(C).OnKeyUp := @KU; TStringGrid(C).OnKeyPress := @KP; TStringGrid(C).OnUTF8KeyPress := @U8; TStringGrid(C).OnSelection := nil; TStringGrid(C).OnClick := @Eff; end;
end;

constructor TMain.CreateNew(AOwner: TComponent; Num: Integer);
var
  i: Integer; y: Integer;
  procedure Place(C: TControl; const AName: String; H: Integer = 24);
  begin C.Name := AName; C.Parent := Self; C.Left := 10; C.Top := y; C.Width := 220; C.Height := H; Inc(y, H + 6); end;
begin
  inherited CreateNew(AOwner, Num);
  FT0 := GetTickCount64;
  Caption := 'keymatrix'; Width := 520; Height := 760; KeyPreview := True;
  OnKeyDown := @FormKD; OnKeyUp := @FormKU;
  y := 8;
  E := TEdit.Create(Self); Place(E, 'edit'); E.Text := 'abc';
  Sp := TSpinEdit.Create(Self); Place(Sp, 'spin'); Sp.Value := 5;
  { Increment 0.25 and MinValue > MaxValue (LCL: unlimited) exercise the GTK4 construction path (D5) }
  FSp := TFloatSpinEdit.Create(Self); FSp.DecimalPlaces := 2; FSp.Increment := 0.25; FSp.MinValue := 10; FSp.MaxValue := 0; FSp.Value := 5.25; Place(FSp, 'fspin');
  CE := TComboBox.Create(Self); Place(CE, 'comboedit'); CE.Style := csDropDown; CE.Items.CommaText := 'one,two,three'; CE.Text := 'abc';
  CL := TComboBox.Create(Self); Place(CL, 'combolist'); CL.Style := csDropDownList; CL.Items.CommaText := 'one,two,three'; CL.ItemIndex := 1;
  M := TMemo.Create(Self); Place(M, 'memo', 60); M.Text := 'abc';
  LB := TListBox.Create(Self); Place(LB, 'listbox', 70); LB.Items.CommaText := 'i0,i1,i2,i3,i4'; LB.ItemIndex := 1;
  CLB := TCheckListBox.Create(Self); Place(CLB, 'checklist', 70); CLB.Items.CommaText := 'c0,c1,c2,c3'; CLB.ItemIndex := 1;
  LV := TListView.Create(Self); Place(LV, 'listview', 70); LV.ViewStyle := vsReport; LV.Columns.Add.Caption := 'col'; LV.Columns[0].Width := 150;
  for i := 0 to 4 do LV.Items.Add.Caption := 'r' + IntToStr(i);
  LV.ItemIndex := 1;
  TV := TTreeView.Create(Self); Place(TV, 'treeview', 70);
  for i := 0 to 4 do TV.Items.Add(nil, 'n' + IntToStr(i));
  TV.Selected := TV.Items[1];
  B := TButton.Create(Self); Place(B, 'button'); B.Caption := 'button';
  CB := TCheckBox.Create(Self); Place(CB, 'checkbox'); CB.Caption := 'check';
  R := TRadioButton.Create(Self); Place(R, 'radio'); R.Caption := 'radio';
  TB := TTrackBar.Create(Self); Place(TB, 'trackbar', 30); TB.Max := 10; TB.Position := 5;
  G := TStringGrid.Create(Self); Place(G, 'grid', 70); G.RowCount := 4; G.ColCount := 3; G.Row := 1; G.Col := 1;
  DefB := TButton.Create(Self); DefB.Name := 'defbtn'; DefB.Parent := Self; DefB.Left := 260; DefB.Top := 8; DefB.Caption := 'default'; DefB.Default := True; DefB.OnClick := @DefClick;
  CanB := TButton.Create(Self); CanB.Name := 'cancelbtn'; CanB.Parent := Self; CanB.Left := 260; CanB.Top := 40; CanB.Caption := 'cancel'; CanB.Cancel := True; CanB.OnClick := @CancelClick;
  for i := 0 to ControlCount - 1 do if Controls[i] is TWinControl then Hook(TWinControl(Controls[i]));
  FTimer := TTimer.Create(Self); FTimer.Interval := StrToIntDef(GetEnvironmentVariable('KEYMATRIX_MS'), 9000); FTimer.OnTimer := @Tick; FTimer.Enabled := True;
  FIsolate := GetEnvironmentVariable('KEYMATRIX_ISOLATE') = '1';
  FIsoTimer := TTimer.Create(Self); FIsoTimer.Interval := 120; FIsoTimer.OnTimer := @IsoTick; FIsoTimer.Enabled := FIsolate;
end;

procedure TMain.Tick(Sender: TObject);
begin
  FTimer.Enabled := False;
  L('FINAL    ' + StateOf);
  L('EXIT     normal');
  Application.Terminate;
end;

procedure TMain.IsoTick(Sender: TObject);
begin
  { isolation mode: if a key moved the focus away (Tab, GTK move-focus, LCL
    navigation), pull it back so every key is measured on the target control }
  if FIsolate and (FTarget <> nil) and FTarget.CanFocus and (ActiveControl <> FTarget) then
  begin
    L('REFOCUS  ' + FTarget.Name + ' (was ' + N(ActiveControl) + ')');
    FTarget.SetFocus;
  end;
end;

var
  Main: TMain; C: TComponent; s: String; i: Integer;
begin
  Application.Initialize;
  Application.CreateForm(TMain, Main);
  if ParamCount >= 2 then
    for s in ParamStr(2).Split(',') do begin i := StrToIntDef(s, -1); if (i >= 0) and (i < 256) then Include(Main.FEat, i); end;
  C := Main.FindComponent(ParamStr(1));
  if C is TWinControl then Main.FTarget := TWinControl(C) else Main.FTarget := Main.E;
  Main.Show;
  Main.FTarget.SetFocus;
  Main.L('READY    focus=' + Main.FTarget.Name + ' widgetset=' + {$I %FPCTARGETOS%} + '/' + LCLPlatformDirNames[WidgetSet.LCLPlatform] + ' isolate=' + BoolToStr(Main.FIsolate, True) + ' eat=' + ParamStr(2));
  Application.Run;
end.
