program autosize_repro;

{$mode objfpc}{$H+}

{ Investigation harness for the GTK4 widgetset autosize "child Left overflow"
  crash seen in the IDE Options dialog (Fppkg page). See
  PROBLEM_PREEXISTING_GTK4_IDE.md for the full analysis.

  NOTE: the CRASH is timing-flaky in this focused harness (0..3 of N runs);
  the IDE reproduces it more reliably (heavier layout). The PREFERRED-SIZE
  PROBES below (leaf/container/stretch/growtofit) ARE deterministic and are
  the reliable signal for the container-measure feedback dimension. The
  NO_SCROLL=1 toggle deterministically shows the TScrollBox is required (no
  crash without it) — the runaway is the scrollbox horizontal-range feedback
  with right/bottom-anchored children, NOT the container preferredSize
  (measure=0 experiments did not stop the crash).

  Layout mirrors ide/frames/files_options.lfm's crashing pattern:
    TScrollBox (fills form)
      -> content TWinControl (AutoSize)
           -> N rows of: [ TComboBox anchored akLeft+akRight to owner..button ]
                         [ TButton  anchored akRight to owner (a "..." button) ]

  The combo stretches left->button, the button is pinned to the owner's right
  edge (Left = ownerClientWidth - buttonWidth). Under GTK4, preferredSize =
  max(intrinsic, set_size_request) (SetBounds sets request = current
  allocation), so the right-anchored circular width dependency can grow
  unbounded across autosize passes -> child Left exceeds SmallInt ->
  ELayoutException. Qt5's sizeHint is intrinsic, so it stays bounded.

  Drives a sequence of programmatic form resizes and reports the maximum
  child Left seen and whether ELayoutException fired. Self-asserting:
  ExitCode=1 on overflow/exception. }

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, LCLType;

type
  TReproForm = class(TForm)
  private
    FScroll: TScrollBox;
    FContent: TPanel;
    FButtons: array of TButton;
    FTimer: TTimer;
    FStep: Integer;
    FMaxLeft: Integer;
    procedure Timer(Sender: TObject);
    procedure Log(const S: string);
    procedure DumpPreferred(const AContext: string);
    procedure PreferredSizeProbe;
    procedure ContainerProbe;
    procedure StretchChildProbe;
    procedure GrowToFitProbe;
    procedure SnapMaxLeft(const AContext: string);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  ReproForm: TReproForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('AUTOSIZE_REPRO_AUTO') = '1';
end;

constructor TReproForm.Create(AOwner: TComponent);
var
  i, y: Integer;
  Combo: TComboBox;
  Btn: TButton;
  Lbl: TLabel;
begin
  inherited Create(AOwner);
  Caption := 'GTK4 autosize repro';
  Position := poDesigned;
  SetBounds(80, 80, 640, 560);

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;

  FContent := TPanel.Create(Self);
  if GetEnvironmentVariable('NO_SCROLL') = '1' then
    FContent.Parent := Self
  else
    FContent.Parent := FScroll;
  FContent.Name := 'Content';
  FContent.Caption := '';
  FContent.BevelOuter := bvNone;
  FContent.Align := alTop;
  FContent.AutoSize := GetEnvironmentVariable('NO_AUTOSIZE') <> '1';

  SetLength(FButtons, StrToIntDef(GetEnvironmentVariable('ROWS'), 40));
  y := 2;
  for i := 0 to High(FButtons) do
  begin
    Lbl := TLabel.Create(Self);
    Lbl.Parent := FContent;
    Lbl.AnchorSideLeft.Control := FContent;
    Lbl.SetBounds(2, y, 176, 18);
    Lbl.Caption := Format('Config item %d (e.g. some.cfg)', [i]);
    Inc(y, 20);

    Btn := TButton.Create(Self);
    Btn.Parent := FContent;
    Btn.Name := Format('DotButton%d', [i]);
    Btn.Caption := '...';
    Btn.SetBounds(597, y, 23, 32);
    Btn.AnchorSideRight.Control := FContent;
    Btn.AnchorSideRight.Side := asrBottom;
    Btn.Anchors := [akTop, akRight];
    FButtons[i] := Btn;

    Combo := TComboBox.Create(Self);
    Combo.Parent := FContent;
    Combo.SetBounds(2, y, 595, 32);
    Combo.Text := Format('ComboBox value %d', [i]);
    Combo.AnchorSideLeft.Control := FContent;
    Combo.AnchorSideRight.Control := Btn;
    Combo.Anchors := [akTop, akLeft, akRight];
    Inc(y, 40);
  end;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 350;
  FTimer.OnTimer := @Timer;
end;

procedure TReproForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
end;

procedure TReproForm.DumpPreferred(const AContext: string);
var
  cpw, cph, spw, sph: Integer;
begin
  { Force fresh (uncached) preferred sizes — the cfPreferredSizeValid cache
    can otherwise return a stale value that hides the divergence. }
  FContent.InvalidatePreferredSize;
  FScroll.InvalidatePreferredSize;
  cpw := 0; cph := 0; spw := 0; sph := 0;
  FContent.GetPreferredSize(cpw, cph);
  FScroll.GetPreferredSize(spw, sph);
  Log(Format('  %s: content.w=%d content.pref=(%d,%d) scroll.pref=(%d,%d) hrange=%d hvis=%s scroll.clientw=%d',
    [AContext, FContent.Width, cpw, cph, spw, sph, FScroll.HorzScrollBar.Range,
     BoolToStr(FScroll.HorzScrollBar.Visible, True), FScroll.ClientWidth]));
end;

procedure TReproForm.SnapMaxLeft(const AContext: string);
var
  i, L: Integer;
begin
  for i := 0 to High(FButtons) do
  begin
    L := FButtons[i].Left;
    if L > FMaxLeft then FMaxLeft := L;
    if (L < Low(SmallInt)) or (L > High(SmallInt)) then
      Log(Format('%s OVERFLOW button[%d].Left=%d', [AContext, i, L]));
  end;
  Log(Format('%s content.width=%d scroll.client=%d hrange=%d hpage=%d maxbtnleft=%d',
    [AContext, FContent.Width, FScroll.ClientWidth,
     FScroll.HorzScrollBar.Range, FScroll.HorzScrollBar.Page, FMaxLeft]));
end;

procedure TReproForm.PreferredSizeProbe;
var
  Combo: TComboBox;
  pw, ph, pw2, ph2, pw3, ph3: Integer;
begin
  { Deterministic root-cause probe: does a control's reported preferred WIDTH
    grow when its allocation (SetBounds width) grows? Qt5/gtk2 return the
    intrinsic sizeHint (stable). GTK4 returns max(intrinsic, set_size_request)
    where SetBounds sets request=allocation, so preferred tracks the
    allocation -> feeds the right-anchor autosize feedback. }
  Combo := TComboBox.Create(Self);
  try
    Combo.Parent := Self;
    Combo.Text := 'probe';
    Combo.SetBounds(0, 0, 120, 30);
    Application.ProcessMessages;
    pw := 0; ph := 0; Combo.GetPreferredSize(pw, ph);
    Combo.SetBounds(0, 0, 600, 30);
    Application.ProcessMessages;
    pw2 := 0; ph2 := 0; Combo.GetPreferredSize(pw2, ph2);
    Combo.SetBounds(0, 0, 1200, 30);
    Application.ProcessMessages;
    pw3 := 0; ph3 := 0; Combo.GetPreferredSize(pw3, ph3);
    Log(Format('preferred-probe combo(leaf): alloc120->pw=%d alloc600->pw=%d alloc1200->pw=%d  tracks-alloc=%s',
      [pw, pw2, pw3, BoolToStr((pw3 > pw2) and (pw2 > pw), True)]));
  finally
    Combo.Free;
  end;
  { Container probe: a panel holding a RIGHT-ANCHORED button. If the GtkFixed
    measure = max(child.x+width), the panel's preferred WIDTH tracks its own
    width (button.x = width - 23), which is the circular feedback. }
  ContainerProbe;
end;

procedure TReproForm.ContainerProbe;
var
  P: TPanel;
  B: TButton;
  pw, ph, pw2, ph2, pw3, ph3: Integer;
begin
  P := TPanel.Create(Self);
  try
    P.Parent := Self;
    P.BevelOuter := bvNone;
    P.SetBounds(0, 300, 200, 40);
    B := TButton.Create(P);
    B.Parent := P;
    B.Caption := '...';
    B.SetBounds(200 - 23, 4, 23, 32);
    B.AnchorSideRight.Control := P;
    B.AnchorSideRight.Side := asrBottom;
    B.Anchors := [akTop, akRight];
    Application.ProcessMessages;
    pw := 0; ph := 0; P.GetPreferredSize(pw, ph);
    P.Width := 600; Application.ProcessMessages;
    pw2 := 0; ph2 := 0; P.GetPreferredSize(pw2, ph2);
    P.Width := 1200; Application.ProcessMessages;
    pw3 := 0; ph3 := 0; P.GetPreferredSize(pw3, ph3);
    Log(Format('preferred-probe panel(right-anchor-child): w200->pw=%d w600->pw=%d w1200->pw=%d  tracks-width=%s',
      [pw, pw2, pw3, BoolToStr((pw3 > pw2) and (pw2 > pw), True)]));
  finally
    P.Free;
  end;
  GrowToFitProbe;
end;

procedure TReproForm.StretchChildProbe;
var
  P: TPanel;
  B: TButton;
  C: TComboBox;
  pw, ph, pw2, ph2, pw3, ph3: Integer;
begin
  { The REAL crash pattern: a horizontally STRETCHING combo (akLeft+akRight)
    plus a right-anchored button. The combo's set_size_request tracks the
    panel width, so if the container measure uses the child's request the
    panel preferred tracks its own width (2nd circular feedback, distinct
    from the button-position one). }
  P := TPanel.Create(Self);
  try
    P.Parent := Self;
    P.BevelOuter := bvNone;
    P.SetBounds(0, 410, 200, 40);
    B := TButton.Create(P);
    B.Parent := P;
    B.Caption := '...';
    B.SetBounds(200 - 23, 4, 23, 32);
    B.AnchorSideRight.Control := P;
    B.AnchorSideRight.Side := asrBottom;
    B.Anchors := [akTop, akRight];
    C := TComboBox.Create(P);
    C.Parent := P;
    C.Text := 'stretch';
    C.SetBounds(2, 4, 200 - 23 - 4, 30);
    C.AnchorSideLeft.Control := P;
    C.AnchorSideRight.Control := B;
    C.Anchors := [akTop, akLeft, akRight];
    Application.ProcessMessages;
    pw := 0; ph := 0; P.GetPreferredSize(pw, ph);
    P.Width := 600; Application.ProcessMessages;
    pw2 := 0; ph2 := 0; P.GetPreferredSize(pw2, ph2);
    P.Width := 1200; Application.ProcessMessages;
    pw3 := 0; ph3 := 0; P.GetPreferredSize(pw3, ph3);
    Log(Format('preferred-probe panel(stretch-combo+button): w200->pw=%d w600->pw=%d w1200->pw=%d  tracks-width=%s',
      [pw, pw2, pw3, BoolToStr((pw3 > pw2) and (pw2 > pw), True)]));
  finally
    P.Free;
  end;
end;

procedure TReproForm.GrowToFitProbe;
var
  P: TPanel;
  B: TButton;
begin
  StretchChildProbe;
  { Regression guard for the offset removal: an AutoSize panel with a
    FIXED-position (non-anchored) child at x=100,w=150 should still end up
    wide enough to contain it (right edge 250). LCL's own child-based
    autosize must handle this even though the widgetset now reports only the
    child extent (150), not its right edge (250). }
  P := TPanel.Create(Self);
  try
    P.Parent := Self;
    P.BevelOuter := bvNone;
    P.SetBounds(0, 360, 60, 40);
    P.AutoSize := True;
    B := TButton.Create(P);
    B.Parent := P;
    B.Caption := 'fixed';
    B.SetBounds(100, 4, 150, 32);   { fixed position, no anchors beyond default }
    Application.ProcessMessages;
    Log(Format('growtofit-probe panel.autosize child-right=250 -> panel.width=%d (ok=%s)',
      [P.Width, BoolToStr(P.Width >= 250, True)]));
  finally
    P.Free;
  end;
end;

procedure TReproForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  FMaxLeft := 0;
  PreferredSizeProbe;
  if AutoMode then
    FTimer.Enabled := True;
end;

procedure TReproForm.Timer(Sender: TObject);
const
  Sizes: array[0..7] of TPoint = (
    (X: 400; Y: 300), (X: 900; Y: 700), (X: 500; Y: 400),
    (X: 807; Y: 622), (X: 350; Y: 300), (X: 1000; Y: 750),
    (X: 500; Y: 560), (X: 640; Y: 560));
begin
  try
    if FStep <= High(Sizes) then
    begin
      Width := Sizes[FStep].X;
      Height := Sizes[FStep].Y;
      Application.ProcessMessages;
      { Force full autosize re-passes (where the transient overflow occurs). }
      FContent.DisableAutoSizing;
      FContent.EnableAutoSizing;
      FScroll.DisableAutoSizing;
      FScroll.EnableAutoSizing;
      Application.ProcessMessages;
      SnapMaxLeft(Format('step%d-%dx%d', [FStep, Sizes[FStep].X, Sizes[FStep].Y]));
      DumpPreferred(Format('step%d', [FStep]));
      Inc(FStep);
    end
    else
    begin
      Log(Format('DONE maxbtnleft=%d (overflow=%s)',
        [FMaxLeft, BoolToStr(FMaxLeft > High(SmallInt), True)]));
      if FMaxLeft > High(SmallInt) then
        ExitCode := 1;
      FTimer.Enabled := False;
      Application.Terminate;
    end;
  except
    on E: Exception do
    begin
      Log('EXCEPTION ' + E.ClassName + ': ' + E.Message);
      Log(Format('  at-crash: content.width=%d content.clientw=%d scroll.width=%d scroll.clientw=%d form.width=%d',
        [FContent.Width, FContent.ClientWidth, FScroll.Width, FScroll.ClientWidth, Width]));
      DumpPreferred('at-crash');
      ExitCode := 1;
      FTimer.Enabled := False;
      Application.Terminate;
    end;
  end;
end;

begin
  Application.Initialize;
  Application.CreateForm(TReproForm, ReproForm);
  Application.Run;
end.
