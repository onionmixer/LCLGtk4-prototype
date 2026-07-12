program toolbarpage_repro;

{ Replicates the ide/frames/editortoolbar_options.lfm layout inside a TScrollBox
  (alClient frame), to check whether page content + BitBtn captions render.
  Dumps every control's bounds/visibility, and (if SHOT env set) writes a PNG. }

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Buttons,
  Graphics, DividerBevel, LCLType;

function MakeGlyph(AColor: TColor): TBitmap;
begin
  Result := TBitmap.Create;
  Result.SetSize(16, 16);
  Result.Canvas.Brush.Color := AColor;
  Result.Canvas.FillRect(0, 0, 16, 16);
end;

type
  TMainForm = class(TForm)
  private
    FScroll: TScrollBox;
    FFrame: TPanel;    { the alClient "frame" (= EditorToolbarOptionsFrame) }
    FPanel: TPanel;    { pnTop alClient }
    procedure Dump(Sender: TObject);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

procedure TMainForm.Dump(Sender: TObject);
  procedure D(C: TControl; const N: string);
  begin
    WriteLn(Format('  %-22s L=%d T=%d W=%d H=%d vis=%s show=%s',
      [N, C.Left, C.Top, C.Width, C.Height, BoolToStr(C.Visible, True),
       BoolToStr(C.IsControlVisible, True)]));
  end;
var
  i: Integer;
  c: TControl;
begin
  WriteLn('=== DUMP form=', Width, 'x', Height,
    ' scroll.client=', FScroll.ClientWidth, 'x', FScroll.ClientHeight,
    ' frame=', FFrame.Width, 'x', FFrame.Height,
    ' panel=', FPanel.Width, 'x', FPanel.Height, ' ===');
  for i := 0 to FPanel.ControlCount - 1 do
  begin
    c := FPanel.Controls[i];
    D(c, c.Name + ':' + c.ClassName);
  end;
  Flush(Output);
  if GetEnvironmentVariable('SHOT') <> '' then
  begin
    Application.ProcessMessages;
    // give GTK a moment to paint, then let external 'import' grab it
  end;
end;

constructor TMainForm.CreateNew(AOwner: TComponent; Num: Integer);
var
  db: TDividerBevel;
  cb: TCheckBox;
  b1, b2: TBitBtn;
  lbl, lbl2: TLabel;
  combo: TComboBox;
begin
  inherited CreateNew(AOwner, Num);
  Caption := 'toolbarpage repro';
  SetBounds(60, 60, StrToIntDef(GetEnvironmentVariable('FW'), 520), 380);

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;

  { the frame — alClient inside the scrollbox (like ideoptionsdlg sets) }
  FFrame := TPanel.Create(Self);
  FFrame.Parent := FScroll;
  FFrame.Align := alClient;
  FFrame.BevelOuter := bvNone;
  FFrame.Caption := '';

  { pnTop alClient }
  FPanel := TPanel.Create(Self);
  FPanel.Parent := FFrame;
  FPanel.Align := alClient;
  FPanel.BevelOuter := bvNone;
  FPanel.Caption := '';
  FPanel.Constraints.MinWidth := 350;

  db := TDividerBevel.Create(Self);
  db.Parent := FPanel;
  db.Name := 'dbGeneralSettings';
  db.Caption := 'Editor Toolbars Settings';
  db.Align := alTop;
  db.Top := 5;
  db.BorderSpacing.Top := 5;
  db.BorderSpacing.Bottom := 5;

  cb := TCheckBox.Create(Self);
  cb.Parent := FPanel;
  cb.Name := 'cbCoolBarVisible';
  cb.Caption := 'Toolbar is visible';
  cb.SetBounds(0, 30, 96, 17);
  cb.BorderSpacing.Top := 12;

  lbl := TLabel.Create(Self);
  lbl.Parent := FPanel;
  lbl.Name := 'lblpos';
  lbl.Caption := 'Position';
  lbl.SetBounds(128, 32, 27, 13);

  combo := TComboBox.Create(Self);
  combo.Parent := FPanel;
  combo.Name := 'cbPos';
  combo.Style := csDropDownList;
  combo.Items.Add('Top'); combo.Items.Add('Bottom');
  combo.Items.Add('Right'); combo.Items.Add('Left');
  combo.ItemIndex := 0;
  combo.SetBounds(161, 28, 100, 21);

  b1 := TBitBtn.Create(Self);
  b1.Parent := FPanel;
  b1.Name := 'bConfig';
  b1.Caption := 'Configure';
  b1.Glyph := MakeGlyph(clNavy);   { image+label path, like IDEImages.AssignImage }
  b1.AutoSize := True;
  b1.SetBounds(0, 65, 73, 23);

  b2 := TBitBtn.Create(Self);
  b2.Parent := FPanel;
  b2.Name := 'bDefaultToolbar';
  b2.Caption := 'Restore defaults';
  b2.Glyph := MakeGlyph(clMaroon);
  b2.AutoSize := True;
  b2.Anchors := [akTop, akRight];
  b2.SetBounds(155, 65, 106, 23);

  lbl2 := TLabel.Create(Self);
  lbl2.Parent := FPanel;
  lbl2.Name := 'lblNoAutoSave';
  lbl2.Caption := '''Auto save active desktop'' option is turned off, you will need to save current desktop manually.';
  lbl2.WordWrap := True;
  lbl2.Anchors := [akTop, akLeft, akRight];
  lbl2.SetBounds(0, 94, 503, 13);

  OnShow := @Dump;
end;

var
  F: TMainForm;
begin
  Application.Initialize;
  F := TMainForm.CreateNew(Application);
  F.Show;
  Application.ProcessMessages;
  F.Dump(nil);
  { keep alive briefly so an external screenshotter can grab it }
  if GetEnvironmentVariable('SHOT') <> '' then
  begin
    Application.ProcessMessages;
    Sleep(1500);
    Application.ProcessMessages;
  end;
end.
