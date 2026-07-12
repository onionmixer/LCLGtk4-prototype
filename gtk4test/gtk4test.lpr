program gtk4test;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, StdCtrls, Controls, Classes, SysUtils, Graphics, LCLType,
  ExtCtrls, Dialogs, Menus, Clipbrd,
  ComCtrls, CheckLst, Spin;

var
  LogFile: TextFile;

procedure Log(const S: string);
begin
  WriteLn(LogFile, FormatDateTime('hh:nn:ss.zzz', Now) + ' ' + S);
  Flush(LogFile);
end;

type
  TForm1 = class(TForm)
  private
    FBtn: TButton;
    FLabel: TLabel;
    FEdit: TEdit;
    FCheckBox: TCheckBox;
    FMemo: TMemo;
    FBtn2: TButton;
    FBtnDlg: TButton;
    FMainMenu: TMainMenu;
    { Phase 6 - Extended widget coverage }
    FTimer: TTimer;
    FComboBox: TComboBox;
    FComboBoxDDL: TComboBox;
    FListBox: TListBox;
    FCheckListBox: TCheckListBox;
    FListView: TListView;
    FStatusBar: TStatusBar;
    FPageControl: TPageControl;
    FTabSheet1: TTabSheet;
    FTabSheet2: TTabSheet;
    FSpinEdit: TSpinEdit;
    FTrackBar: TTrackBar;
    FProgressBar: TProgressBar;
    FPanel: TPanel;
    FGroupBox: TGroupBox;
    FScrollBar: TScrollBar;
    FToolBar: TToolBar;
    FWidgetCount: Integer;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure TimerAutoExit(Sender: TObject);
    procedure BtnDlgClick(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure BtnClick(Sender: TObject);
    procedure Btn2Click(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure CheckBoxChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuFileNewClick(Sender: TObject);
    procedure MenuFileQuitClick(Sender: TObject);
    procedure MenuEditCopyClick(Sender: TObject);
    procedure MenuEditPasteClick(Sender: TObject);
    procedure MenuHelpAboutClick(Sender: TObject);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

constructor TForm1.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  Log('TForm1.CreateNew');
  OnCreate := @FormCreate;
  OnPaint := @FormPaint;
  OnClose := @FormClose;
  OnKeyDown := @FormKeyDown;
  OnMouseDown := @FormMouseDown;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  Log('FormShow called');
end;

procedure TForm1.TimerAutoExit(Sender: TObject);
begin
  FTimer.Enabled := False;
  Log('TimerAutoExit fired - closing application');
  Log(Format('Total widgets created: %d', [FWidgetCount]));
  Log('=== Phase 6 Runtime Verification COMPLETE ===');
  Close;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  MFile, MEdit, MHelp: TMenuItem;
  MNew, MQuit, MCopy, MPaste, MAbout, MSep: TMenuItem;
begin
  Log('FormCreate called');
  Caption := 'GTK4 Widget Test (Phase 6)';
  Width := 900;
  Height := 700;
  FWidgetCount := 0;

  { Create main menu }
  FMainMenu := TMainMenu.Create(Self);

  MFile := TMenuItem.Create(FMainMenu);
  MFile.Caption := '&File';
  FMainMenu.Items.Add(MFile);

  MNew := TMenuItem.Create(FMainMenu);
  MNew.Caption := '&New';
  MNew.OnClick := @MenuFileNewClick;
  MFile.Add(MNew);

  MSep := TMenuItem.Create(FMainMenu);
  MSep.Caption := '-';
  MFile.Add(MSep);

  MQuit := TMenuItem.Create(FMainMenu);
  MQuit.Caption := '&Quit';
  MQuit.OnClick := @MenuFileQuitClick;
  MFile.Add(MQuit);

  MEdit := TMenuItem.Create(FMainMenu);
  MEdit.Caption := '&Edit';
  FMainMenu.Items.Add(MEdit);

  MCopy := TMenuItem.Create(FMainMenu);
  MCopy.Caption := '&Copy';
  MCopy.OnClick := @MenuEditCopyClick;
  MEdit.Add(MCopy);

  MPaste := TMenuItem.Create(FMainMenu);
  MPaste.Caption := '&Paste';
  MPaste.OnClick := @MenuEditPasteClick;
  MEdit.Add(MPaste);

  MHelp := TMenuItem.Create(FMainMenu);
  MHelp.Caption := '&Help';
  FMainMenu.Items.Add(MHelp);

  MAbout := TMenuItem.Create(FMainMenu);
  MAbout.Caption := '&About';
  MAbout.OnClick := @MenuHelpAboutClick;
  MHelp.Add(MAbout);

  Menu := FMainMenu;
  Inc(FWidgetCount); { menu }
  Log('Menu created');

  { =============================== }
  { Existing basic widgets           }
  { =============================== }

  { TLabel }
  FLabel := TLabel.Create(Self);
  FLabel.Parent := Self;
  FLabel.SetBounds(10, 10, 200, 20);
  FLabel.Caption := 'Hello from TLabel';
  FLabel.Font.Color := clRed;
  FLabel.Color := clAqua;
  FLabel.Transparent := False;
  Inc(FWidgetCount);
  Log('Label created');

  { TButton }
  FBtn := TButton.Create(Self);
  FBtn.Parent := Self;
  FBtn.SetBounds(10, 40, 120, 30);
  FBtn.Caption := 'Click Me';
  FBtn.OnClick := @BtnClick;
  Inc(FWidgetCount);
  Log('Button created');

  { TEdit }
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.SetBounds(10, 80, 200, 25);
  FEdit.Text := 'Type here';
  FEdit.OnChange := @EditChange;
  Inc(FWidgetCount);
  Log('Edit created');

  { TCheckBox }
  FCheckBox := TCheckBox.Create(Self);
  FCheckBox.Parent := Self;
  FCheckBox.SetBounds(10, 115, 200, 25);
  FCheckBox.Caption := 'Check me';
  FCheckBox.OnChange := @CheckBoxChange;
  Inc(FWidgetCount);
  Log('CheckBox created');

  { TMemo }
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.SetBounds(10, 150, 300, 100);
  FMemo.Lines.Add('Line 1: TMemo test');
  FMemo.Lines.Add('Line 2: Multi-line text');
  Inc(FWidgetCount);
  Log('Memo created');

  { Second button to read Edit text }
  FBtn2 := TButton.Create(Self);
  FBtn2.Parent := Self;
  FBtn2.SetBounds(140, 40, 120, 30);
  FBtn2.Caption := 'Read Edit';
  FBtn2.OnClick := @Btn2Click;
  Inc(FWidgetCount);
  Log('Button2 created');

  { Dialog test button }
  FBtnDlg := TButton.Create(Self);
  FBtnDlg.Parent := Self;
  FBtnDlg.SetBounds(270, 40, 120, 30);
  FBtnDlg.Caption := 'Show Dialog';
  FBtnDlg.OnClick := @BtnDlgClick;
  Inc(FWidgetCount);
  Log('DialogButton created');

  Log('All basic widgets created');

  { CRASH ISOLATION: Uncomment Exit below to skip extended widgets }
  //Exit;

  { =============================== }
  { Phase 6: TPageControl + TabSheets }
  { =============================== }
  try
    FPageControl := TPageControl.Create(Self);
    FPageControl.Parent := Self;
    FPageControl.SetBounds(10, 270, 870, 400);
    Inc(FWidgetCount);
    Log('PageControl created');

    FTabSheet1 := TTabSheet.Create(FPageControl);
    FTabSheet1.PageControl := FPageControl;
    FTabSheet1.Caption := 'StdCtrls';
    Inc(FWidgetCount);
    Log('TabSheet1 created');

    FTabSheet2 := TTabSheet.Create(FPageControl);
    FTabSheet2.PageControl := FPageControl;
    FTabSheet2.Caption := 'ComCtrls';
    Inc(FWidgetCount);
    Log('TabSheet2 created');
  except
    on E: Exception do
      Log('FAILED PageControl: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ComboBox (csDropDown) }
  { =============================== }
  try
    FComboBox := TComboBox.Create(Self);
    FComboBox.Parent := FTabSheet1;
    FComboBox.SetBounds(10, 10, 200, 25);
    FComboBox.Style := csDropDown;
    FComboBox.Items.Add('Item 1');
    FComboBox.Items.Add('Item 2');
    FComboBox.Items.Add('Item 3');
    FComboBox.ItemIndex := 0;
    Inc(FWidgetCount);
    Log('ComboBox (csDropDown) created, ItemIndex=' + IntToStr(FComboBox.ItemIndex));
  except
    on E: Exception do
      Log('FAILED ComboBox csDropDown: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ComboBox (csDropDownList) → GtkDropDown }
  { =============================== }
  try
    FComboBoxDDL := TComboBox.Create(Self);
    FComboBoxDDL.Parent := FTabSheet1;
    FComboBoxDDL.SetBounds(220, 10, 200, 25);
    FComboBoxDDL.Style := csDropDownList;
    FComboBoxDDL.Items.Add('DDL Item A');
    FComboBoxDDL.Items.Add('DDL Item B');
    FComboBoxDDL.Items.Add('DDL Item C');
    FComboBoxDDL.ItemIndex := 1;
    Inc(FWidgetCount);
    Log('ComboBox (csDropDownList/GtkDropDown) created, ItemIndex=' +
      IntToStr(FComboBoxDDL.ItemIndex));
  except
    on E: Exception do
      Log('FAILED ComboBox csDropDownList: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ListBox (GtkListView)   }
  { =============================== }
  try
    FListBox := TListBox.Create(Self);
    FListBox.Parent := FTabSheet1;
    FListBox.SetBounds(10, 45, 200, 100);
    FListBox.Items.Add('ListBox Item 1');
    FListBox.Items.Add('ListBox Item 2');
    FListBox.Items.Add('ListBox Item 3');
    FListBox.Items.Add('ListBox Item 4');
    FListBox.ItemIndex := 0;
    Inc(FWidgetCount);
    Log('ListBox created, Items.Count=' + IntToStr(FListBox.Items.Count));
  except
    on E: Exception do
      Log('FAILED ListBox: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: CheckListBox            }
  { =============================== }
  try
    FCheckListBox := TCheckListBox.Create(Self);
    FCheckListBox.Parent := FTabSheet1;
    FCheckListBox.SetBounds(220, 45, 200, 100);
    FCheckListBox.Items.Add('Check Item 1');
    FCheckListBox.Items.Add('Check Item 2');
    FCheckListBox.Items.Add('Check Item 3');
    FCheckListBox.Checked[0] := True;
    FCheckListBox.Checked[2] := True;
    Inc(FWidgetCount);
    Log('CheckListBox created, Items.Count=' + IntToStr(FCheckListBox.Items.Count));
    Log('  Checked[0]=' + BoolToStr(FCheckListBox.Checked[0], True));
    Log('  Checked[1]=' + BoolToStr(FCheckListBox.Checked[1], True));
    Log('  Checked[2]=' + BoolToStr(FCheckListBox.Checked[2], True));
  except
    on E: Exception do
      Log('FAILED CheckListBox: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: SpinEdit                }
  { =============================== }
  try
    FSpinEdit := TSpinEdit.Create(Self);
    FSpinEdit.Parent := FTabSheet1;
    FSpinEdit.SetBounds(430, 155, 120, 30);
    FSpinEdit.MinValue := 0;
    FSpinEdit.MaxValue := 100;
    FSpinEdit.Value := 42;
    FSpinEdit.Increment := 1;
    Inc(FWidgetCount);
    Log('SpinEdit created, Value=' + IntToStr(FSpinEdit.Value));
  except
    on E: Exception do
      Log('FAILED SpinEdit: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ScrollBar                }
  { =============================== }
  try
    FScrollBar := TScrollBar.Create(Self);
    FScrollBar.Parent := FTabSheet1;
    FScrollBar.SetBounds(430, 45, 200, 20);
    FScrollBar.Kind := sbHorizontal;
    FScrollBar.Min := 0;
    FScrollBar.Max := 100;
    FScrollBar.Position := 50;
    Inc(FWidgetCount);
    Log('ScrollBar created, Position=' + IntToStr(FScrollBar.Position));
  except
    on E: Exception do
      Log('FAILED ScrollBar: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: GroupBox                 }
  { =============================== }
  try
    FGroupBox := TGroupBox.Create(Self);
    FGroupBox.Parent := FTabSheet1;
    FGroupBox.SetBounds(430, 75, 200, 70);
    FGroupBox.Caption := 'GroupBox Test';
    Inc(FWidgetCount);
    Log('GroupBox created');
  except
    on E: Exception do
      Log('FAILED GroupBox: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: Panel                    }
  { =============================== }
  try
    FPanel := TPanel.Create(Self);
    FPanel.Parent := FTabSheet1;
    FPanel.SetBounds(10, 155, 200, 50);
    FPanel.Caption := 'Panel Test';
    FPanel.BevelOuter := bvRaised;
    Inc(FWidgetCount);
    Log('Panel created');
  except
    on E: Exception do
      Log('FAILED Panel: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: TrackBar                 }
  { =============================== }
  try
    FTrackBar := TTrackBar.Create(Self);
    FTrackBar.Parent := FTabSheet1;
    FTrackBar.SetBounds(220, 155, 200, 30);
    FTrackBar.Min := 0;
    FTrackBar.Max := 100;
    FTrackBar.Position := 30;
    Inc(FWidgetCount);
    Log('TrackBar created, Position=' + IntToStr(FTrackBar.Position));
  except
    on E: Exception do
      Log('FAILED TrackBar: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: StatusBar (on main form) }
  { =============================== }
  try
    FStatusBar := TStatusBar.Create(Self);
    FStatusBar.Parent := Self;
    FStatusBar.SimplePanel := False;
    with FStatusBar.Panels.Add do begin
      Text := 'Panel 0';
      Width := 150;
    end;
    with FStatusBar.Panels.Add do begin
      Text := 'Panel 1';
      Width := 150;
    end;
    with FStatusBar.Panels.Add do begin
      Text := 'Ready';
      Width := 200;
    end;
    Inc(FWidgetCount);
    Log('StatusBar created, Panels.Count=' + IntToStr(FStatusBar.Panels.Count));
  except
    on E: Exception do
      Log('FAILED StatusBar: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ListView (vsReport)   }
  { =============================== }
  try
    FListView := TListView.Create(Self);
    FListView.Parent := FTabSheet2;
    FListView.SetBounds(10, 10, 400, 200);
    FListView.ViewStyle := vsReport;
    FListView.Checkboxes := True;
    with FListView.Columns.Add do begin
      Caption := 'Name';
      Width := 150;
    end;
    with FListView.Columns.Add do begin
      Caption := 'Value';
      Width := 100;
    end;
    with FListView.Columns.Add do begin
      Caption := 'Status';
      Width := 100;
    end;
    with FListView.Items.Add do begin
      Caption := 'Item 0';
      SubItems.Add('Value 0');
      SubItems.Add('OK');
      Checked := True;
    end;
    with FListView.Items.Add do begin
      Caption := 'Item 1';
      SubItems.Add('Value 1');
      SubItems.Add('Warning');
    end;
    with FListView.Items.Add do begin
      Caption := 'Item 2';
      SubItems.Add('Value 2');
      SubItems.Add('Error');
      Checked := True;
    end;
    Inc(FWidgetCount);
    Log('ListView (vsReport) created, Items.Count=' +
      IntToStr(FListView.Items.Count) +
      ', Columns.Count=' + IntToStr(FListView.Columns.Count));
    Log('  Checkboxes=' + BoolToStr(FListView.Checkboxes, True));
    Log('  Items[0].Checked=' + BoolToStr(FListView.Items[0].Checked, True));
  except
    on E: Exception do
      Log('FAILED ListView: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ProgressBar              }
  { =============================== }
  try
    FProgressBar := TProgressBar.Create(Self);
    FProgressBar.Parent := FTabSheet2;
    FProgressBar.SetBounds(10, 220, 400, 25);
    FProgressBar.Min := 0;
    FProgressBar.Max := 100;
    FProgressBar.Position := 65;
    Inc(FWidgetCount);
    Log('ProgressBar created, Position=' + IntToStr(FProgressBar.Position));
  except
    on E: Exception do
      Log('FAILED ProgressBar: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Phase 6: ToolBar                  }
  { =============================== }
  try
    FToolBar := TToolBar.Create(Self);
    FToolBar.Parent := FTabSheet2;
    FToolBar.SetBounds(10, 255, 400, 30);
    FToolBar.ShowCaptions := True;
    with TToolButton.Create(FToolBar) do begin
      Parent := FToolBar;
      Caption := 'Btn1';
    end;
    with TToolButton.Create(FToolBar) do begin
      Parent := FToolBar;
      Caption := 'Btn2';
    end;
    with TToolButton.Create(FToolBar) do begin
      Parent := FToolBar;
      Style := tbsSeparator;
      Width := 8;
    end;
    with TToolButton.Create(FToolBar) do begin
      Parent := FToolBar;
      Caption := 'Btn3';
    end;
    Inc(FWidgetCount);
    Log('ToolBar created with 3 buttons + separator');
  except
    on E: Exception do
      Log('FAILED ToolBar: ' + E.ClassName + ': ' + E.Message);
  end;

  { =============================== }
  { Final summary                     }
  { =============================== }
  Log(Format('=== All Phase 6 widgets created: %d total ===', [FWidgetCount]));

  { Auto-exit timer — created here instead of FormShow because
    OnShow does not fire (FVisible is already True when Show is called) }
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 3000;
  FTimer.OnTimer := @TimerAutoExit;
  FTimer.Enabled := True;
  Log('Timer created, will auto-close in 3 seconds');
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  i: Integer;
begin
  Log('FormPaint called');
  try
    { Existing canvas tests }
    Canvas.Brush.Color := clYellow;
    Canvas.FillRect(Rect(320, 10, 480, 80));
    Canvas.Font.Color := clBlack;
    Canvas.TextOut(330, 20, 'Painted!');

    { Phase 6: Additional canvas drawing tests }
    Canvas.Pen.Color := clBlue;
    Canvas.Pen.Width := 2;
    Canvas.MoveTo(500, 10);
    Canvas.LineTo(650, 80);

    Canvas.Pen.Color := clRed;
    Canvas.Brush.Color := clLime;
    Canvas.Rectangle(660, 10, 800, 60);

    Canvas.Pen.Color := clMaroon;
    Canvas.Brush.Color := clAqua;
    Canvas.Ellipse(660, 65, 800, 130);

    Canvas.Font.Color := clNavy;
    Canvas.Font.Size := 14;
    Canvas.Font.Style := [fsBold];
    Canvas.TextOut(500, 90, 'Bold 14pt');
    Canvas.Font.Style := [];
    Canvas.Font.Size := 0;

    Log('Canvas drawing complete');

    { Log child control info }
    Log(Format('ControlCount=%d', [ControlCount]));
    for i := 0 to ControlCount - 1 do
      Log(Format('  Control[%d]: %s %s %d,%d %dx%d Vis=%s',
        [i, Controls[i].ClassName, Controls[i].Name,
         Controls[i].Left, Controls[i].Top,
         Controls[i].Width, Controls[i].Height,
         BoolToStr(Controls[i].Visible, True)]));
  except
    on E: Exception do
      Log('Paint exception: ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Log('FormClose called');
  CloseAction := caFree;
end;

procedure TForm1.BtnClick(Sender: TObject);
begin
  Log('BtnClick called');
  FLabel.Caption := 'Button clicked at ' + TimeToStr(Now);
end;

procedure TForm1.BtnDlgClick(Sender: TObject);
var
  Res: Integer;
begin
  Log('BtnDlgClick called - showing MessageDlg');
  Res := MessageDlg('Test Dialog', 'Do you like GTK4?', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  Log('MessageDlg result: ' + IntToStr(Res));
  case Res of
    mrYes: FLabel.Caption := 'Dialog: Yes!';
    mrNo: FLabel.Caption := 'Dialog: No';
    mrCancel: FLabel.Caption := 'Dialog: Cancel';
  else
    FLabel.Caption := 'Dialog: ' + IntToStr(Res);
  end;
end;

procedure TForm1.Btn2Click(Sender: TObject);
begin
  Log('Btn2Click: Edit.Text = "' + FEdit.Text + '"');
  FLabel.Caption := 'Edit: ' + FEdit.Text;
end;

procedure TForm1.EditChange(Sender: TObject);
begin
  Log('EditChange: "' + FEdit.Text + '"');
end;

procedure TForm1.CheckBoxChange(Sender: TObject);
begin
  Log('CheckBoxChange: Checked=' + BoolToStr(FCheckBox.Checked, True));
end;

procedure TForm1.MenuFileNewClick(Sender: TObject);
begin
  Log('Menu: File > New clicked');
  FLabel.Caption := 'Menu: File > New';
end;

procedure TForm1.MenuFileQuitClick(Sender: TObject);
begin
  Log('Menu: File > Quit clicked');
  Close;
end;

procedure TForm1.MenuEditCopyClick(Sender: TObject);
begin
  Log('Menu: Edit > Copy clicked');
  Clipboard.AsText := 'Hello from GTK4 clipboard!';
  FLabel.Caption := 'Copied to clipboard';
  Log('Clipboard set to: "Hello from GTK4 clipboard!"');
end;

procedure TForm1.MenuEditPasteClick(Sender: TObject);
var
  S: string;
begin
  Log('Menu: Edit > Paste clicked');
  S := Clipboard.AsText;
  FLabel.Caption := 'Paste: ' + S;
  Log('Clipboard read: "' + S + '"');
end;

procedure TForm1.MenuHelpAboutClick(Sender: TObject);
begin
  Log('Menu: Help > About clicked');
  FLabel.Caption := 'Menu: Help > About';
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Log('KeyDown Key=' + IntToStr(Key));
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  Log(Format('MouseDown X=%d Y=%d', [X, Y]));
end;

var
  Form1: TForm1;
begin
  {$IF DECLARED(UseHeapTrace)}
  GlobalSkipIfNoLeaks := True;
  SetHeapTraceOutput('/tmp/gtk4test_heap.log');
  {$ENDIF}

  AssignFile(LogFile, '/tmp/gtk4test_events.log');
  Rewrite(LogFile);
  Log('Starting GTK4 Widget test (Phase 6)...');
  Log('Compiled: ' + {$I %DATE%} + ' ' + {$I %TIME%});
  Application.Initialize;
  Log('After Application.Initialize');
  Application.CreateForm(TForm1, Form1);
  Log('After CreateForm');
  Log('Calling Application.Run...');
  Application.Run;
  Log('Application.Run finished - clean exit');
  CloseFile(LogFile);
end.
