program mousematrix;
{$MODE OBJFPC}{$H+}
{ Mouse-delivery matrix harness (builds for gtk4 / qt5 / gtk2).
  Usage: mousematrix <control>
    control: custom scrollbox memo listbox listview treeview synedit(gtk4/qt5) spin combo
             pagecontrol groupbox trackbar panel edit
  The harness drives xdotool ITSELF (so markers and events align exactly): for each region
  (client centre, vertical scrollbar thumb, vertical trough, horizontal thumb, control-specific
  chrome) it presses button 1, drags down/right, moves into the client area, releases, then logs
  the scroll positions and selection state. Every OnMouseDown/Move/Up of the target control is
  logged with control-local coordinates. Run under Xvfb (run.sh). }
uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Spin,
  Graphics, LCLType, LCLIntf, LMessages, Process, LCLPlatformDef, InterfaceBase, Menus
  {$IFNDEF LCLgtk2}, SynEdit{$ENDIF}{$IFDEF LCLgtk4}, gtk4widgets{$ENDIF};

type
  { KMemo-like TCustomControl: own extents, ShowScrollBar+SetScrollInfo, software scroll on LM_VSCROLL }
  TKLike = class(TCustomControl)
  public
    HorzExtent, VertExtent, TopPos, LeftPos: Integer;
    SelStart, SelEnd: TPoint;   { "selection" = press point .. last drag point, like KMemo }
    Selecting, SelEver: Boolean;   { SelEver: a drag extended the selection since the last STATE }
    procedure UpdateScrollRange;
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
    procedure WMVScroll(var Msg: TLMVScroll); message LM_VSCROLL;
    procedure WMHScroll(var Msg: TLMHScroll); message LM_HSCROLL;
  end;

  { protected event properties of TControl become assignable through this cast }
  TCtlHack = class(TControl);

  TMain = class(TForm)
  public
    Target: TWinControl;
    Kind: String;
    T0: QWord;
    procedure L(const S: String);
    procedure Settle(MS: Integer);
    procedure MD(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MM(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MU(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Clk(Sender: TObject);
    procedure DblClk(Sender: TObject);
    procedure Hook(C: TControl);
    procedure Build;
    procedure Xdo(const Args: array of string);
    procedure Region(const AName: String; CX, CY: Integer);
    procedure MultiBtn(const AName: String; CX, CY: Integer);
    procedure ContentDrag(const AName: String; CX, CY: Integer);
    procedure State(const ATag: String);
    procedure RunAll;
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

var
  TLeft, TTop: Integer;   { target position inside the form (0 when the target is the form itself) }

function OneOf(const S: String; const L: array of string): Boolean;
var i: Integer;
begin
  Result := False;
  for i := 0 to High(L) do if S = L[i] then Exit(True);
end;

function N(Sender: TObject): String;
begin
  if Sender = nil then Result := 'nil' else if Sender is TComponent then Result := TComponent(Sender).Name + ':' + Sender.ClassName else Result := Sender.ClassName;
end;

{ TKLike }

procedure TKLike.UpdateScrollRange;
var
  SI: TScrollInfo;
  Vis: Boolean;
begin
  if not HandleAllocated then exit;
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_RANGE or SIF_PAGE or SIF_POS or SIF_UPDATEPOLICY;
  SI.nMin := 0; SI.nTrackPos := SB_POLICY_CONTINUOUS;
  Vis := ClientWidth < HorzExtent;
  ShowScrollBar(Handle, SB_HORZ, Vis);
  if Vis then begin SI.nMax := HorzExtent; SI.nPage := ClientWidth; SI.nPos := LeftPos; SetScrollInfo(Handle, SB_HORZ, SI, True); end;
  Vis := ClientHeight < VertExtent;
  ShowScrollBar(Handle, SB_VERT, Vis);
  if Vis then begin SI.nMax := VertExtent; SI.nPage := ClientHeight; SI.nPos := TopPos; SetScrollInfo(Handle, SB_VERT, SI, True); end;
end;

procedure TKLike.Paint;
var
  y: Integer;
begin
  Canvas.Brush.Color := clCream; Canvas.FillRect(ClientRect);
  y := -TopPos;
  while y < VertExtent - TopPos do begin Canvas.TextOut(4 - LeftPos, y, IntToStr(y + TopPos)); Inc(y, 40); end;
  if Selecting then
  begin
    Canvas.Brush.Color := clHighlight;
    Canvas.FillRect(Rect(SelStart.X, SelStart.Y, SelEnd.X, SelEnd.Y));
  end;
end;

procedure TKLike.Resize; begin inherited Resize; UpdateScrollRange; end;
procedure TKLike.CreateWnd; begin inherited CreateWnd; UpdateScrollRange; end;

procedure TKLike.WMVScroll(var Msg: TLMVScroll);
var SI: TScrollInfo;
begin
  SI.cbSize := SizeOf(SI); SI.fMask := SIF_POS or SIF_TRACKPOS; GetScrollInfo(Handle, SB_VERT, SI);
  case Msg.ScrollCode of SB_THUMBTRACK, SB_THUMBPOSITION: TopPos := Msg.Pos; else TopPos := SI.nPos; end;
  Invalidate;
end;

procedure TKLike.WMHScroll(var Msg: TLMHScroll);
var SI: TScrollInfo;
begin
  SI.cbSize := SizeOf(SI); SI.fMask := SIF_POS or SIF_TRACKPOS; GetScrollInfo(Handle, SB_HORZ, SI);
  case Msg.ScrollCode of SB_THUMBTRACK, SB_THUMBPOSITION: LeftPos := Msg.Pos; else LeftPos := SI.nPos; end;
  Invalidate;
end;

{ TMain }

constructor TMain.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  SetBounds(50, 50, 800, 600);
  Caption := 'mousematrix';
  T0 := GetTickCount64;
end;

procedure TMain.L(const S: String);
begin
  WriteLn(Format('%6d %s', [GetTickCount64 - T0, S])); Flush(Output);
end;

procedure TMain.Settle(MS: Integer);
var Deadline: QWord;
begin
  Deadline := GetTickCount64 + MS;
  while GetTickCount64 < Deadline do begin Application.ProcessMessages; Sleep(5); end;
end;

procedure TMain.MD(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  L(Format('EV %s Down btn=%d x=%d y=%d', [N(Sender), Ord(Button), X, Y]));
  if Sender is TKLike then with TKLike(Sender) do begin Selecting := True; SelStart := Point(X, Y); SelEnd := SelStart; end;
end;

procedure TMain.MM(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  L(Format('EV %s Move x=%d y=%d btn=%s', [N(Sender), X, Y, BoolToStr(ssLeft in Shift, True)]));
  if (Sender is TKLike) and TKLike(Sender).Selecting then with TKLike(Sender) do begin SelEnd := Point(X, Y); SelEver := SelEver or (SelEnd <> SelStart); Invalidate; end;
end;

procedure TMain.MU(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  L(Format('EV %s Up btn=%d x=%d y=%d', [N(Sender), Ord(Button), X, Y]));
  if Sender is TKLike then TKLike(Sender).Selecting := False;
end;

procedure TMain.Clk(Sender: TObject); begin L('EV ' + N(Sender) + ' Click'); end;
procedure TMain.DblClk(Sender: TObject); begin L('EV ' + N(Sender) + ' DblClick'); end;

procedure TMain.Hook(C: TControl);
begin
  TCtlHack(C).OnMouseDown := @MD; TCtlHack(C).OnMouseMove := @MM; TCtlHack(C).OnMouseUp := @MU;
  TCtlHack(C).OnClick := @Clk; TCtlHack(C).OnDblClick := @DblClk;
end;

procedure TMain.Build;
var
  i: Integer;
  K: TKLike; SB: TScrollBox; Pn: TPanel; M: TMemo; LB: TListBox; LV: TListView; LI: TListItem;
  TV: TTreeView; PC: TPageControl; TS: TTabSheet; CB: TComboBox; AMenu: TMainMenu; MI, MI2: TMenuItem;
  Long: String;
  {$IFNDEF LCLgtk2}SE: TSynEdit;{$ENDIF}
begin
  Long := StringOfChar('x', 200);
  case Kind of
    'custom': begin K := TKLike.Create(Self); K.HorzExtent := 1400; K.VertExtent := 2000; Target := K; end;
    'scrollbox':
      begin
        SB := TScrollBox.Create(Self); Target := SB;
        Pn := TPanel.Create(Self); Pn.Parent := SB; Pn.SetBounds(0, 0, 1400, 2000); Pn.Caption := 'big'; Pn.Name := 'bigpanel';
      end;
    'memo': begin M := TMemo.Create(Self); M.ScrollBars := ssBoth; M.WordWrap := False; for i := 1 to 120 do M.Lines.Add(IntToStr(i) + ' ' + Long); Target := M; end;
    'listbox': begin LB := TListBox.Create(Self); for i := 1 to 100 do LB.Items.Add(IntToStr(i) + ' ' + Long); Target := LB; end;
    'listview':
      begin
        LV := TListView.Create(Self); LV.ViewStyle := vsReport; LV.Columns.Add.Width := 200; LV.Columns.Add.Width := 1200;
        for i := 1 to 100 do begin LI := LV.Items.Add; LI.Caption := IntToStr(i); LI.SubItems.Add(Long); end;
        Target := LV;
      end;
    'treeview', 'treeviewnohint':
      begin
        TV := TTreeView.Create(Self); for i := 1 to 100 do TV.Items.Add(nil, 'node ' + IntToStr(i) + ' ' + Long);
        if Kind = 'treeviewnohint' then TV.ToolTips := False;   { the node tooltip (THintWindow) is a separate toplevel }
        Target := TV;
      end;
    {$IFNDEF LCLgtk2}
    'synedit': begin SE := TSynEdit.Create(Self); for i := 1 to 120 do SE.Lines.Add('line ' + IntToStr(i) + ' ' + Long); Target := SE; end;
    {$ENDIF}
    'spin': begin Target := TSpinEdit.Create(Self); TSpinEdit(Target).MaxValue := 1000; end;
    'combo': begin CB := TComboBox.Create(Self); CB.Style := csDropDownList; for i := 1 to 20 do CB.Items.Add('item ' + IntToStr(i)); CB.ItemIndex := 0; Target := CB; end;
    'pagecontrol':
      begin
        PC := TPageControl.Create(Self); TS := TTabSheet.Create(Self); TS.PageControl := PC; TS.Caption := 'first';
        TS := TTabSheet.Create(Self); TS.PageControl := PC; TS.Caption := 'second'; Target := PC;
      end;
    'groupbox': begin Target := TGroupBox.Create(Self); TGroupBox(Target).Caption := 'group caption'; end;
    'trackbar': begin Target := TTrackBar.Create(Self); TTrackBar(Target).Max := 100; TTrackBar(Target).Position := 50; end;
    'panel': begin Pn := TPanel.Create(Self); Pn.Caption := 'panel'; Target := Pn; end;
    'button': begin Target := TButton.Create(Self); TButton(Target).Caption := 'button'; end;   { native button: does an ANCESTOR get its press/release/motion? }
    'edit': Target := TEdit.Create(Self);
    'formmenu':
      begin
        { a form with a menu bar; the form itself is the target: are its press/motion coordinates client-relative? }
        AMenu := TMainMenu.Create(Self); MI := TMenuItem.Create(AMenu); MI.Caption := 'File'; AMenu.Items.Add(MI);
        MI2 := TMenuItem.Create(AMenu); MI2.Caption := 'Open'; MI.Add(MI2);   { a real submenu: GTK rejects a leaf top-level item }
        Menu := AMenu;
        Target := Self;
      end;
    'formscroll':
      begin
        { the form's own scrollbars (TGtk4Window): AutoScroll with a tall/wide panel, target = the form }
        AutoScroll := True;
        Pn := TPanel.Create(Self); Pn.Parent := Self; Pn.SetBounds(0, 0, 1400, 2000); Pn.Caption := 'big'; Pn.Name := 'bigpanel';
        Target := Self;
      end;
  else
    raise Exception.Create('unknown control ' + Kind);
  end;
  if Target <> Self then
  begin
    Target.Name := 'target';
    Target.Parent := Self;
  end
  else
    Name := 'target';
  if Target <> Self then Hook(Self);   { the form too: shows who receives a press that the target does not }
  { hook every other control as well (e.g. an inplace editor a control creates) }
  for i := 0 to ComponentCount - 1 do
    if (Components[i] is TControl) and (Components[i] <> Target) then Hook(TControl(Components[i]));
  for i := 0 to Target.ControlCount - 1 do Hook(Target.Controls[i]);
  L(Format('CONTROLS form=%d target.children=%d', [ControlCount, Target.ControlCount]));
  if Target = Self then SetBounds(50, 50, 640, 440)
  else if OneOf(Kind, ['spin', 'combo', 'edit']) then Target.SetBounds(20, 20, 200, 0) else Target.SetBounds(20, 20, 600, 400);
  Hook(Target);
  { target position inside the form, AFTER SetBounds (regions are computed from it) }
  if Target = Self then begin TLeft := 0; TTop := 0; end else begin TLeft := Target.Left; TTop := Target.Top; end;
  L(Format('TARGET at %d,%d size %dx%d', [TLeft, TTop, Target.Width, Target.Height]));
end;

procedure TMain.Xdo(const Args: array of string);
var
  Outp: String;
begin
  RunCommand('xdotool', Args, Outp, [poWaitOnExit]);
end;

procedure TMain.State(const ATag: String);
var
  S: String;
  SI: TScrollInfo;
begin
  S := Format('STATE %s vpos=%d hpos=%d', [ATag, GetScrollPos(Target.Handle, SB_VERT), GetScrollPos(Target.Handle, SB_HORZ)]);
  { does the control actually have scroll ranges (a region row is only a scrollbar row when it does) }
  SI.cbSize := SizeOf(SI); SI.fMask := SIF_RANGE or SIF_PAGE;
  if GetScrollInfo(Target.Handle, SB_VERT, SI) then S := S + Format(' vrange=%d/%d', [SI.nMax, SI.nPage]);
  if GetScrollInfo(Target.Handle, SB_HORZ, SI) then S := S + Format(' hrange=%d/%d', [SI.nMax, SI.nPage]);
  S := S + Format(' vbar=%s hbar=%s', [BoolToStr(GetScrollBarVisible(Target.Handle, SB_VERT), True), BoolToStr(GetScrollBarVisible(Target.Handle, SB_HORZ), True)]);
  { ClientToScreen consistency: the control's own answer for its client origin vs the form's answer
    for the same point; a non-zero difference means the control's screen mapping drifts (e.g. with scrolling) }
  with Target.ClientToScreen(Point(0, 0)) do
    S := S + Format(' c2sdrift=%d,%d', [X - ClientToScreen(Point(TLeft, TTop)).X, Y - ClientToScreen(Point(TLeft, TTop)).Y]);
  if Target is TKLike then
  begin
    S := S + Format(' top=%d left=%d sel=%s', [TKLike(Target).TopPos, TKLike(Target).LeftPos, BoolToStr(TKLike(Target).SelEver, True)]);
    TKLike(Target).SelEver := False;
  end;
  if Target is TMemo then S := S + Format(' sellen=%d', [TMemo(Target).SelLength]);
  {$IFNDEF LCLgtk2}
  if Target is TSynEdit then S := S + Format(' sellen=%d topline=%d', [Length(TSynEdit(Target).SelText), TSynEdit(Target).TopLine]);
  {$ENDIF}
  if Target is TListBox then S := S + Format(' itemindex=%d top=%d', [TListBox(Target).ItemIndex, TListBox(Target).TopIndex]);
  if Target is TListView then S := S + Format(' itemindex=%d', [TListView(Target).ItemIndex]);
  if Target is TTreeView then S := S + Format(' selected=%s', [BoolToStr(TTreeView(Target).Selected <> nil, True)]);
  if Target is TScrollBox then S := S + Format(' vsb=%d hsb=%d', [TScrollBox(Target).VertScrollBar.Position, TScrollBox(Target).HorzScrollBar.Position]);
  if Target is TSpinEdit then S := S + Format(' value=%d', [TSpinEdit(Target).Value]);
  if Target is TComboBox then S := S + Format(' itemindex=%d dropped=%s', [TComboBox(Target).ItemIndex, BoolToStr(TComboBox(Target).DroppedDown, True)]);
  if Target is TPageControl then S := S + Format(' page=%d', [TPageControl(Target).ActivePageIndex]);
  if Target is TTrackBar then S := S + Format(' pos=%d', [TTrackBar(Target).Position]);
  {$IFDEF LCLgtk4}
  { the offset the widgetset subtracts from motion coordinates (getClientOffset, used by OffsetMousePos) }
  with TGtk4Widget(Target.Handle) do
    S := S + Format(' wsoff=%d,%d', [getClientOffset.X, getClientOffset.Y]);
  {$ENDIF}
  L(S);
end;

{ press at region, drag +60/+120 down, move to the client centre, release there }
procedure TMain.Region(const AName: String; CX, CY: Integer);
var
  P, C: TPoint;
begin
  { screen position via the FORM (stable); Target.ClientToScreen is itself under test, see State }
  P := ClientToScreen(Point(TLeft + CX, TTop + CY));
  C := ClientToScreen(Point(TLeft + Target.ClientWidth div 2, TTop + Target.ClientHeight div 2));
  L(Format('--- region %s at local %d,%d screen %d,%d', [AName, CX, CY, P.X, P.Y]));
  Xdo(['mousemove', IntToStr(P.X), IntToStr(P.Y)]); Settle(250);
  Xdo(['mousedown', '1']); Settle(250);
  Xdo(['mousemove', IntToStr(P.X), IntToStr(P.Y + 60)]); Settle(150);
  Xdo(['mousemove', IntToStr(P.X), IntToStr(P.Y + 120)]); Settle(150);
  Xdo(['mousemove', IntToStr(C.X), IntToStr(C.Y)]); Settle(150);
  Xdo(['mouseup', '1']); Settle(400);
  State(AName);
  { park the pointer outside the control and give the control a moment }
  Xdo(['mousemove', IntToStr(P.X), IntToStr(Top + Height + 60)]); Settle(300);
end;

{ press button 1 on the region (scrollbar thumb), move into the client, press+release button 3 there,
  move again, release button 1: with the qt5 semantics nothing reaches the control }
procedure TMain.MultiBtn(const AName: String; CX, CY: Integer);
var
  P, C: TPoint;
begin
  P := ClientToScreen(Point(TLeft + CX, TTop + CY));
  C := ClientToScreen(Point(TLeft + Target.ClientWidth div 2, TTop + Target.ClientHeight div 2));
  L(Format('--- region %s at local %d,%d screen %d,%d', [AName, CX, CY, P.X, P.Y]));
  Xdo(['mousemove', IntToStr(P.X), IntToStr(P.Y)]); Settle(250);
  Xdo(['mousedown', '1']); Settle(250);
  Xdo(['mousemove', IntToStr(C.X), IntToStr(C.Y)]); Settle(150);
  Xdo(['mousedown', '3']); Settle(150); Xdo(['mouseup', '3']); Settle(150);
  Xdo(['mousemove', IntToStr(C.X + 40), IntToStr(C.Y + 40)]); Settle(150);
  Xdo(['mouseup', '1']); Settle(400);
  State(AName);
  Xdo(['mousemove', IntToStr(P.X), IntToStr(Top + Height + 60)]); Settle(300);
end;

{ press in the client, drag across the vertical scrollbar and out of the control, release outside }
procedure TMain.ContentDrag(const AName: String; CX, CY: Integer);
var
  P: TPoint;
begin
  P := ClientToScreen(Point(TLeft + CX, TTop + CY));
  L(Format('--- region %s at local %d,%d screen %d,%d', [AName, CX, CY, P.X, P.Y]));
  Xdo(['mousemove', IntToStr(P.X), IntToStr(P.Y)]); Settle(250);
  Xdo(['mousedown', '1']); Settle(250);
  Xdo(['mousemove', IntToStr(P.X + 200), IntToStr(P.Y)]); Settle(150);
  Xdo(['mousemove', IntToStr(ClientToScreen(Point(TLeft + Target.Width - 7, TTop + CY)).X), IntToStr(P.Y)]); Settle(150);
  Xdo(['mousemove', IntToStr(ClientToScreen(Point(TLeft + Target.Width + 60, TTop + CY)).X), IntToStr(P.Y)]); Settle(150);
  Xdo(['mouseup', '1']); Settle(400);
  State(AName);
  Xdo(['mousemove', IntToStr(P.X), IntToStr(Top + Height + 60)]); Settle(300);
end;

procedure TMain.RunAll;
var
  W, H: Integer;
begin
  W := Target.ClientWidth; H := Target.ClientHeight;
  State('start');
  Region('client', W div 2, H div 2);
  if not OneOf(Kind, ['spin', 'combo', 'edit', 'trackbar', 'panel', 'button', 'groupbox', 'pagecontrol', 'formmenu']) then
  begin
    Region('vthumb', Target.Width - 7, 30);
    Region('vtrough', Target.Width - 7, Target.Height - 40);
    Region('hthumb', 30, Target.Height - 7);
  end;
  if not OneOf(Kind, ['spin', 'combo', 'edit', 'trackbar', 'panel', 'button', 'groupbox', 'pagecontrol', 'formscroll', 'formmenu']) then
  begin
    ContentDrag('contentdrag', W div 2, H div 2);
    MultiBtn('multibtn', Target.Width - 7, 30);   { last: a button-3 press may open a native popup on some widgetsets }
  end;
  case Kind of
    'spin': Region('spinup', Target.Width - 8, Target.Height div 2 - 4);
    'combo': Region('combobutton', Target.Width - 10, Target.Height div 2);
    'pagecontrol': Region('tab2', 90, 10);
    'groupbox': Region('caption', 30, 6);
    'listview': Region('header', 100, 8);
    'trackbar': Region('slider', Target.Width div 2, Target.Height div 2);
  end;
  State('end');
end;

var
  F: TMain;
begin
  Application.Initialize;
  F := TMain.CreateNew(nil);
  F.Kind := ParamStr(1);
  F.Build;
  F.Show;
  F.Settle(1500);
  F.L(Format('READY control=%s widgetset=%s client=%dx%d', [F.Kind, LCLPlatformDirNames[WidgetSet.LCLPlatform], F.Target.ClientWidth, F.Target.ClientHeight]));
  F.RunAll;
  F.L('DONE');
  F.Free;
end.
