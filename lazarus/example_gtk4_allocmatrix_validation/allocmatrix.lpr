program allocmatrix;
{$MODE OBJFPC}{$H+}
{ FCentralWidget allocation matrix harness (gtk4 only).
  Usage: allocmatrix <control> [range] [mode]
    control: panel groupbox scrollbox custom memo listbox checklist listview
             statictext progressbar toolbar page statusbar splitterside form
             treeview synedit   (LCL-painted TCustomControl descendants used by the IDE)
    range:   hv (default, horizontal+vertical content range) | v (vertical only) | none | tall (1400x60000)
    control (extra): listboxgrid (Columns=3 -> GtkGridView) listviewicon (vsIcon -> GtkGridView) memowrap (WordWrap)
                     formscroll (AutoScroll form: the TGtk4Window scroll GtkFixed)
    mode:    (empty) | notruth | late | hidden | rehide | inactivepage | zero | perf
             perf:    after show, 40 alternating scroll steps; prints PERF wall/cpu ms and rss (no truth steps)
             perfstale: like perf but after a -100h resize (unfixed build: stale viewport-sized GtkFixed)
             gtkscroll: scroll steps drive the GTK vertical adjustment directly (wheel/scrollbar path), not the LCL API
             growmid: scroll to the middle, shrink -100h, grow +100h (viewport grows, position unchanged), screenshot pause there
             notruth: the truth steps do not call queue_resize
             late:    the control is created after the form is shown (find-panel case)
             hidden:  created Visible=False, shown after the form is up
             rehide:  shown, then hidden, resized while hidden, shown again (extra steps before the normal ones)
             inactivepage: the control sits on an inactive TTabSheet; resized there, then the page is activated
             zero:    height set to 0 and back to 400 before the normal steps
  Every SNAP also carries rss=<VmRSS kB> (process resident size).
  For every step it prints one SNAP line with the outer widget / FCentralWidget /
  central parent allocations, size requests and the scrolled-window adjustments.
  "truth" steps call gtk_widget_queue_resize on FCentralWidget and settle, so the
  layout cycle recomputes the allocation: a SNAP that differs from the following
  truth SNAP is a stale allocation left behind by TGtk4Widget.SetBounds. }
uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  CheckLst, PairSplitter, Graphics, LCLType, LCLIntf, LMessages, SynEdit,
  gtk4widgets, LazGtk4, LazGObject2, LazGLib2;

type
  { KMemo-like TCustomControl: own content extents, ShowScrollBar+SetScrollInfo
    like TKCustomMemo.UpdateScrollRange, range re-pushed on every Resize. }
  TKLike = class(TCustomControl)
  public
    HorzExtent, VertExtent, TopPos, LeftPos: Integer;
    PaintCount: Integer;
    LastClip: TRect;   { Canvas.ClipRect seen by the last Paint = LCL rcPaint }
    procedure UpdateScrollRange;
    procedure ScrollTo(APos: Integer);
    procedure ScrollToBottom;
    procedure WMVScroll(var Msg: TLMVScroll); message LM_VSCROLL;   { software scroll like KMemo }
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
  end;

  TMain = class(TForm)
  public
    Target: TWinControl;
    Kind, Range, Mode: String;
    procedure Settle(MS: Integer = 400);
    procedure Snap(const ATag: String);
    procedure Truth(const ATag: String);
    procedure DoScroll;
    procedure Perf;
    procedure Build;
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

var
  T0: QWord;

procedure L(const S: String);
begin
  WriteLn(Format('%6d %s', [GetTickCount64 - T0, S])); Flush(Output);
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
  SI.nMin := 0;
  SI.nTrackPos := SB_POLICY_CONTINUOUS;
  Vis := ClientWidth < HorzExtent;
  ShowScrollBar(Handle, SB_HORZ, Vis);
  if Vis then
  begin
    SI.nMax := HorzExtent; SI.nPage := ClientWidth; SI.nPos := LeftPos;
    SetScrollInfo(Handle, SB_HORZ, SI, True);
  end;
  Vis := ClientHeight < VertExtent;
  ShowScrollBar(Handle, SB_VERT, Vis);
  if Vis then
  begin
    SI.nMax := VertExtent; SI.nPage := ClientHeight; SI.nPos := TopPos;
    SetScrollInfo(Handle, SB_VERT, SI, True);
  end;
end;

procedure TKLike.ScrollTo(APos: Integer);
var
  SI: TScrollInfo;
begin
  TopPos := APos;
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_POS;
  SI.nPos := TopPos;
  SetScrollInfo(Handle, SB_VERT, SI, True);
  Invalidate;
end;

procedure TKLike.WMVScroll(var Msg: TLMVScroll);
var
  SI: TScrollInfo;
begin
  SI.cbSize := SizeOf(SI); SI.fMask := SIF_POS or SIF_TRACKPOS;
  GetScrollInfo(Handle, SB_VERT, SI);
  case Msg.ScrollCode of
    SB_THUMBTRACK, SB_THUMBPOSITION: TopPos := Msg.Pos;
  else
    TopPos := SI.nPos;
  end;
  Invalidate;
end;

procedure TKLike.ScrollToBottom;
var
  SI: TScrollInfo;
begin
  TopPos := VertExtent - ClientHeight;
  if TopPos < 0 then TopPos := 0;
  SI.cbSize := SizeOf(SI);
  SI.fMask := SIF_POS;
  SI.nPos := TopPos;
  SetScrollInfo(Handle, SB_VERT, SI, True);
  Invalidate;
end;

procedure TKLike.Paint;
var
  y: Integer;
begin
  Inc(PaintCount);
  LastClip := Canvas.ClipRect;
  Canvas.Brush.Color := clCream;
  Canvas.FillRect(ClientRect);
  y := -TopPos;
  while y < VertExtent - TopPos do
  begin
    Canvas.TextOut(4 - LeftPos, y, IntToStr(y + TopPos));
    Inc(y, 40);
  end;
end;

procedure TKLike.Resize;
begin
  inherited Resize;
  UpdateScrollRange;
end;

procedure TKLike.CreateWnd;
begin
  inherited CreateWnd;
  UpdateScrollRange;
end;

{ TMain }

constructor TMain.CreateNew(AOwner: TComponent; Num: Integer);
begin
  inherited CreateNew(AOwner, Num);
  SetBounds(50, 50, 800, 600);
  Caption := 'allocmatrix';
end;

procedure TMain.Settle(MS: Integer);
var
  Deadline: QWord;
begin
  Deadline := GetTickCount64 + MS;
  while GetTickCount64 < Deadline do
  begin
    Application.ProcessMessages;
    Sleep(10);
  end;
end;

function RssKB: Integer;
var
  F: TextFile;
  L: String;
begin
  Result := -1;
  AssignFile(F, '/proc/self/status');
  try
    Reset(F);
    while not Eof(F) do
    begin
      ReadLn(F, L);
      if Pos('VmRSS:', L) = 1 then
      begin
        Delete(L, 1, 6);
        Result := StrToIntDef(Trim(StringReplace(L, 'kB', '', [])), -1);
        Break;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

function TypeName(W: PGtkWidget): String;
begin
  if W = nil then Exit('nil');
  Result := g_type_name_from_instance(PGTypeInstance(W));
end;

function AllocStr(W: PGtkWidget): String;
var
  A: TGtkAllocation;
begin
  if W = nil then Exit('nil');
  W^.get_allocation(@A);
  Result := Format('%d,%d %dx%d', [A.x, A.y, A.width, A.height]);
end;

function ReqStr(W: PGtkWidget): String;
var
  rw, rh: gint;
begin
  if W = nil then Exit('nil');
  gtk_widget_get_size_request(W, @rw, @rh);
  Result := Format('%dx%d', [rw, rh]);
end;

function AdjStr(A: PGtkAdjustment): String;
begin
  if A = nil then Exit('nil');
  Result := Format('%d/%d/%d', [Round(A^.get_value), Round(A^.get_upper), Round(A^.get_page_size)]);
end;

procedure TMain.Snap(const ATag: String);
var
  H: TGtk4Widget;
  W, CW, P: PGtkWidget;
  SW: PGtkScrolledWindow;
  S: String;
  R: TRect;
begin
  if not Target.HandleAllocated then begin L('SNAP ' + ATag + ' nohandle'); exit; end;
  H := TGtk4Widget(Target.Handle);
  W := H.Widget;
  CW := H.GetContainerWidget;
  P := nil;
  if CW <> nil then P := CW^.get_parent;
  S := Format('SNAP %-8s cls=%s widget=%s alloc=[%s] req=%s', [ATag, H.ClassName, TypeName(W), AllocStr(W), ReqStr(W)]);
  if CW = W then
    S := S + ' central=SAME'
  else
    S := S + Format(' central=%s alloc=[%s] req=%s parent=%s alloc=[%s]',
      [TypeName(CW), AllocStr(CW), ReqStr(CW), TypeName(P), AllocStr(P)]);
  if (wtScrollingWin in H.WidgetType) and (H is TGtk4ScrollableWin) then
  begin
    SW := TGtk4ScrollableWin(H).getScrolledWindow;
    if SW <> nil then
      S := S + Format(' hadj=%s vadj=%s', [AdjStr(SW^.get_hadjustment), AdjStr(SW^.get_vadjustment)]);
  end;
  R := Target.ClientRect;
  S := S + Format(' lcl=%dx%d client=%dx%d ptr=%p/%p rss=%d', [Target.Width, Target.Height, R.Right, R.Bottom, Pointer(W), Pointer(CW), RssKB]);
  { widgetset-level client rect (fresh query, not the LCL cache) }
  R := H.getClientRect;
  S := S + Format(' wsclient=%d,%d %dx%d', [R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top]);
  L(S);
end;

procedure TMain.Truth(const ATag: String);
var
  CW: PGtkWidget;
begin
  if not Target.HandleAllocated then exit;
  CW := TGtk4Widget(Target.Handle).GetContainerWidget;
  { mode=notruth: never repair, so the following steps show whether GTK itself
    ever recovers the allocation (scroll / resize) without our queue_resize }
  if (CW <> nil) and (Mode <> 'notruth') then gtk_widget_queue_resize(CW);
  Settle;
  Snap(ATag);
end;

function CpuMs: Int64;
var
  F: TextFile;
  L: String;
  Parts: TStringArray;
begin
  AssignFile(F, '/proc/self/stat'); Reset(F); ReadLn(F, L); CloseFile(F);
  L := Copy(L, Pos(') ', L) + 2, MaxInt);      { after "comm) " }
  Parts := L.Split(' ');
  Result := (StrToInt64(Parts[11]) + StrToInt64(Parts[12])) * 10;   { utime+stime in clock ticks (100 Hz) -> ms }
end;

{ perf: 40 scroll steps alternating between 1/4 and 3/4 of the range (each one
  invalidates and forces a repaint); wall/cpu time and rss are printed per step
  block so the renderer cost of the content-sized cairo node can be compared. }
procedure TMain.Perf;
var
  i, n, Pos1, Pos2, P, Before: Integer;
  T0, C0: Int64;
  K: TKLike;
  Adj: PGtkAdjustment;
  SW: PGtkScrolledWindow;
  Deadline: QWord;
begin
  n := 40;
  T0 := GetTickCount64; C0 := CpuMs;
  for i := 1 to n do
  begin
    if Target is TKLike then
    begin
      K := TKLike(Target);
      Pos1 := (K.VertExtent - K.ClientHeight) div 4; Pos2 := Pos1 * 3;
      if Odd(i) then P := Pos1 else P := Pos2;
      Before := K.PaintCount;
      K.ScrollTo(P);
      Deadline := GetTickCount64 + 2000;
      while (K.PaintCount = Before) and (GetTickCount64 < Deadline) do
      begin
        Application.ProcessMessages;
        Sleep(1);
      end;
    end
    else if Target is TScrollBox then
    begin
      Pos1 := TScrollBox(Target).VertScrollBar.Range div 4; Pos2 := Pos1 * 3;
      if Odd(i) then P := Pos1 else P := Pos2;
      TScrollBox(Target).VertScrollBar.Position := P;
      Settle(40);
    end;
    Application.ProcessMessages;
  end;
  if Target is TKLike then
    L(Format('PAINTCLIP %d,%d %dx%d (Canvas.ClipRect in the last Paint; client %dx%d)',
      [TKLike(Target).LastClip.Left, TKLike(Target).LastClip.Top, TKLike(Target).LastClip.Width, TKLike(Target).LastClip.Height,
       Target.ClientWidth, Target.ClientHeight]));
  L(Format('PERF steps=%d wall_ms=%d cpu_ms=%d rss=%d', [n, GetTickCount64 - T0, CpuMs - C0, RssKB]));
end;

procedure TMain.DoScroll;
var
  H: TGtk4Widget;
  SW: PGtkScrolledWindow;
  Adj: PGtkAdjustment;
begin
  if (Mode = 'gtkscroll') and Target.HandleAllocated and (TGtk4Widget(Target.Handle) is TGtk4ScrollableWin) then
  begin
    SW := TGtk4ScrollableWin(TGtk4Widget(Target.Handle)).getScrolledWindow;
    if SW <> nil then
    begin
      Adj := SW^.get_vadjustment;
      if Adj <> nil then Adj^.set_value(Adj^.get_upper - Adj^.get_page_size);
    end;
    exit;
  end;
  if Target = Self then
    VertScrollBar.Position := VertScrollBar.Range
  else if Target is TScrollBox then
    TScrollBox(Target).VertScrollBar.Position := TScrollBox(Target).VertScrollBar.Range
  else if Target is TKLike then
    TKLike(Target).ScrollToBottom
  else if Target is TMemo then
  begin
    TMemo(Target).SelStart := Length(TMemo(Target).Text);
    TMemo(Target).SelLength := 0;
  end
  else if Target is TListBox then
    TListBox(Target).TopIndex := TListBox(Target).Items.Count - 1
  else if Target is TListView then
    TListView(Target).Items[TListView(Target).Items.Count - 1].MakeVisible(False)
  else if Target is TTreeView then
    TTreeView(Target).TopItem := TTreeView(Target).Items[TTreeView(Target).Items.Count - 1]
  else if Target is TSynEdit then
    TSynEdit(Target).TopLine := TSynEdit(Target).Lines.Count;
  { natively scrolling widgets (Memo/ListBox/ListView): also drive the GTK vertical
    adjustment to its end, so the scrolled state is measured regardless of the LCL API }
  if Target.HandleAllocated then
  begin
    H := TGtk4Widget(Target.Handle);
    if (H is TGtk4ScrollableWin) and not (H is TGtk4CustomControl) then
    begin
      SW := TGtk4ScrollableWin(H).getScrolledWindow;
      if SW <> nil then
      begin
        Adj := SW^.get_vadjustment;
        if Adj <> nil then Adj^.set_value(Adj^.get_upper - Adj^.get_page_size);
      end;
    end;
  end;
end;

procedure TMain.Build;
var
  i: Integer;
  SB: TScrollBox;
  K: TKLike;
  M: TMemo;
  LB: TListBox;
  CL: TCheckListBox;
  LV: TListView;
  LI: TListItem;
  PC: TPageControl;
  TS: TTabSheet;
  PS: TPairSplitter;
  TV: TTreeView;
  SE: TSynEdit;
  Pn: TPanel;
  CW, CH: Integer;
  Long: String;
begin
  if Range = 'v' then CW := 300 else CW := 1400;
  CH := 12000;
  if Range = 'tall' then CH := 60000;
  Long := StringOfChar('x', 300);
  if Kind = 'memowrap' then Long := StringOfChar('w', 30) + StringOfChar(' ', 1);  { breakable: 'wwww... ' x 10 }
  if Range = 'v' then Long := 'short line';
  case Kind of
    'panel': begin Pn := TPanel.Create(Self); Pn.Caption := 'panel'; Target := Pn; end;
    'groupbox': begin Target := TGroupBox.Create(Self); TGroupBox(Target).Caption := 'group'; end;
    'scrollbox':
      begin
        SB := TScrollBox.Create(Self);
        Target := SB;
        if Range <> 'none' then
          { a column of captioned panels so a screenshot shows which part of the
            content is visible (a single huge panel looks blank anywhere) }
          for i := 0 to (CH div 300) - 1 do
          begin
            Pn := TPanel.Create(Self); Pn.Parent := SB; Pn.SetBounds(0, i * 300, CW, 300);
            Pn.Caption := 'panel ' + IntToStr(i) + ' y=' + IntToStr(i * 300);
            Pn.Color := $E0FFE0; Pn.BevelOuter := bvLowered;
          end;
      end;
    'custom':
      begin
        K := TKLike.Create(Self);
        if Range = 'none' then begin K.HorzExtent := 10; K.VertExtent := 10; end
        else begin K.HorzExtent := CW; K.VertExtent := CH; end;
        Target := K;
      end;
    'memo', 'memowrap':
      begin
        M := TMemo.Create(Self); M.ScrollBars := ssBoth; M.WordWrap := (Kind = 'memowrap');
        if Range <> 'none' then
          for i := 1 to 400 do
            if Kind = 'memowrap' then M.Lines.Add(IntToStr(i) + ' ' + Long + Long + Long + Long + Long + Long + Long + Long + Long + Long)
            else M.Lines.Add(IntToStr(i) + ' ' + Long);
        Target := M;
      end;
    'listbox', 'listboxgrid':
      begin
        LB := TListBox.Create(Self);
        if Kind = 'listboxgrid' then LB.Columns := 3;
        if Range <> 'none' then for i := 1 to 300 do LB.Items.Add(IntToStr(i) + ' ' + Long);
        Target := LB;
      end;
    'checklist':
      begin
        CL := TCheckListBox.Create(Self);
        if Range <> 'none' then for i := 1 to 300 do CL.Items.Add(IntToStr(i) + ' ' + Long);
        Target := CL;
      end;
    'listview', 'listviewicon':
      begin
        LV := TListView.Create(Self);
        if Kind = 'listviewicon' then LV.ViewStyle := vsIcon else LV.ViewStyle := vsReport;
        LV.Columns.Add.Width := 200; LV.Columns.Add.Width := 1200;
        if Range <> 'none' then
          for i := 1 to 300 do begin LI := LV.Items.Add; LI.Caption := IntToStr(i); LI.SubItems.Add(Long); end;
        Target := LV;
      end;
    'statictext': begin Target := TStaticText.Create(Self); TStaticText(Target).Caption := 'static'; end;
    'progressbar': begin Target := TProgressBar.Create(Self); TProgressBar(Target).Position := 40; end;
    'toolbar': begin Target := TToolBar.Create(Self); TToolBar(Target).Align := alNone; end;
    'page':
      begin
        PC := TPageControl.Create(Self); PC.Parent := Self; PC.SetBounds(20, 20, 600, 400);
        TS := TTabSheet.Create(Self); TS.PageControl := PC; TS.Caption := 'tab';
        Pn := TPanel.Create(Self); Pn.Parent := TS; Pn.SetBounds(10, 10, 100, 50);
        Target := TS;
      end;
    'statusbar': begin Target := TStatusBar.Create(Self); TStatusBar(Target).SimpleText := 'status'; TStatusBar(Target).Align := alNone; end;
    'splitterside':
      begin
        PS := TPairSplitter.Create(Self); PS.Parent := Self; PS.SetBounds(20, 20, 600, 400);
        Pn := TPanel.Create(Self); Pn.Parent := PS.Sides[0]; Pn.SetBounds(10, 10, 100, 50);
        Target := PS.Sides[0];
      end;
    'form': Target := Self;
    'formscroll':
      begin
        { the form's own scroll GtkFixed (TGtk4Window): AutoScroll form with a column of panels }
        AutoScroll := True;
        for i := 0 to 9 do
        begin
          Pn := TPanel.Create(Self); Pn.Parent := Self; Pn.SetBounds(0, i * 300, 1400, 300);
          Pn.Caption := 'form panel ' + IntToStr(i); Pn.Color := $FFE0E0; Pn.BevelOuter := bvLowered;
        end;
        Target := Self;
      end;
    'treeview':
      begin
        TV := TTreeView.Create(Self);
        if Range <> 'none' then for i := 1 to 300 do TV.Items.Add(nil, 'node ' + IntToStr(i) + ' ' + Long);
        Target := TV;
      end;
    'synedit':
      begin
        SE := TSynEdit.Create(Self);
        if Range <> 'none' then for i := 1 to 400 do SE.Lines.Add('line ' + IntToStr(i) + ' ' + Long);
        Target := SE;
      end;
  else
    raise Exception.Create('unknown control ' + Kind);
  end;
  if (Target <> Self) and (Target.Parent = nil) then
  begin
    if Mode = 'inactivepage' then
    begin
      PC := TPageControl.Create(Self); PC.Parent := Self; PC.SetBounds(10, 10, 700, 500);
      TS := TTabSheet.Create(Self); TS.PageControl := PC; TS.Caption := 'first';
      TS := TTabSheet.Create(Self); TS.PageControl := PC; TS.Caption := 'second';
      Target.Parent := TS;
      PC.ActivePageIndex := 0;
    end
    else
      Target.Parent := Self;
    Target.SetBounds(20, 20, 600, 400);
  end;
end;

var
  F: TMain;
  Steps, i: Integer;
begin
  T0 := GetTickCount64;
  Application.Initialize;
  F := TMain.CreateNew(nil);
  F.Kind := ParamStr(1);
  F.Range := ParamStr(2);
  if F.Range = '' then F.Range := 'hv';
  F.Mode := ParamStr(3);
  L(Format('START control=%s range=%s mode=%s', [F.Kind, F.Range, F.Mode]));
  if F.Mode = 'late' then
  begin
    F.Show; F.Settle(800); F.Build; F.Settle(800);
  end
  else
  begin
    F.Build;
    if F.Mode = 'hidden' then F.Target.Visible := False;
    F.Show;
    F.Settle(800);
    if F.Mode = 'hidden' then begin F.Target.Visible := True; F.Settle(800); end;
  end;
  F.Snap('show');
  F.Truth('t-show');
  if F.Mode = 'growmid' then
  begin
    if F.Target is TKLike then TKLike(F.Target).ScrollTo((TKLike(F.Target).VertExtent - F.Target.ClientHeight) div 2)
    else if F.Target is TScrollBox then TScrollBox(F.Target).VertScrollBar.Position := TScrollBox(F.Target).VertScrollBar.Range div 2
    else if F.Target is TTreeView then TTreeView(F.Target).TopItem := TTreeView(F.Target).Items[TTreeView(F.Target).Items.Count div 2]
    else if F.Target is TSynEdit then TSynEdit(F.Target).TopLine := TSynEdit(F.Target).Lines.Count div 2;
    F.Settle; F.Snap('mid');
    F.Target.Height := F.Target.Height - 100; F.Settle; F.Snap('mid-shr');
    F.Target.Height := F.Target.Height + 100; F.Settle; F.Snap('mid-grow');
    if GetEnvironmentVariable('ALLOC_SHOT') <> '' then F.Settle(1500);
    L('DONE'); F.Free; Exit;
  end;
  if F.Mode = 'rehide' then
  begin
    F.Target.Visible := False; F.Settle; F.Snap('hid');
    F.Target.Height := F.Target.Height - 100; F.Settle; F.Snap('hid-shr');
    F.Target.Visible := True; F.Settle; F.Snap('reshown'); F.Truth('t-reshown');
    F.Target.Height := F.Target.Height + 100; F.Settle; F.Snap('regrow'); F.Truth('t-regrow');
  end
  else if F.Mode = 'inactivepage' then
  begin
    F.Target.Height := F.Target.Height - 100; F.Settle; F.Snap('inact-shr');
    TPageControl(F.Target.Parent.Parent).ActivePageIndex := 1; F.Settle; F.Snap('activated'); F.Truth('t-activated');
    F.Target.Height := F.Target.Height + 100; F.Settle; F.Snap('act-grow'); F.Truth('t-act-grow');
  end
  else if F.Mode = 'zero' then
  begin
    F.Target.Height := 0; F.Settle; F.Snap('zero'); F.Truth('t-zero');
    F.Target.Height := 400; F.Settle; F.Snap('unzero'); F.Truth('t-unzero');
  end;
  if F.Mode = 'perfstale' then
  begin
    { resize with unchanged content extents before measuring: the unfixed build then scrolls a
      viewport-sized (stale, blank) GtkFixed, the fixed build a content-sized one }
    F.Target.Height := F.Target.Height - 100; F.Settle; F.Snap('shrunk');
  end;
  if (F.Mode = 'perf') or (F.Mode = 'perfstale') then begin F.Perf; F.Snap('perf'); L('DONE'); F.Free; Exit; end;
  F.DoScroll; F.Settle; F.Snap('scroll'); F.Truth('t-scroll');
  F.Target.Height := F.Target.Height - 100; F.Settle; F.Snap('shrink'); F.Truth('t-shrink');
  TGtk4Widget(F.Target.Handle).SetBounds(F.Target.Left, F.Target.Top, F.Target.Width, F.Target.Height);
  F.Settle; F.Snap('same'); F.Truth('t-same');
  F.Target.Height := F.Target.Height + 100; F.Settle; F.Snap('grow'); F.Truth('t-grow');
  F.Target.Width := F.Target.Width + 50; F.Settle; F.Snap('wider'); F.Truth('t-wider');
  F.DoScroll; F.Settle; F.Snap('scroll2'); if GetEnvironmentVariable('ALLOC_SHOT') <> '' then F.Settle(1500); F.Truth('t-scroll2');
  L('DONE');
  F.Free;
end.
