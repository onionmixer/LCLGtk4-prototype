unit mainform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Buttons
  {$IFDEF LCLGtk4}
  , gtk4widgets, lazgtk4, lazgtk4_compat, lazgobject2, lazglib2
  {$ENDIF}
  ;

type
  TTestSetupForm = class(TForm)
    WelcomePaintBox: TPaintBox;
    PropertiesTreeView: TTreeView;
    Splitter1: TSplitter;
    BtnPanel: TPanel;
    StartIDEBitBtn: TBitBtn;
    PropertiesPageControl: TPageControl;
    LazarusTabSheet: TTabSheet;
    CompilerTabSheet: TTabSheet;
    DebuggerTabSheet: TTabSheet;
    LazDirLabel: TLabel;
    LazDirMemo: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure WelcomePaintBoxPaint(Sender: TObject);
    procedure StartIDEBitBtnClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    FDumpCount: Integer;
    procedure DumpLayout(const ATag: String);
    procedure DumpLayoutAsync({%H-}Data: PtrInt);
    procedure DumpLayoutAsync2({%H-}Data: PtrInt);
    {$IFDEF LCLGtk4}
    procedure DumpGtk4WidgetTree(const ATag: String);
    {$ENDIF}
  public
  end;

{$IFDEF LCLGtk4}
type
  { Hack to access protected fields (FCentralWidget, FPaintArea) }
  TGtk4WidgetHack = class(TGtk4Widget);
{$ENDIF}

var
  TestSetupForm: TTestSetupForm;

implementation

{$R *.lfm}

procedure TTestSetupForm.FormCreate(Sender: TObject);
var
  i: Integer;
  {$IFDEF LCLGtk4}
  PW, PH: Integer;
  {$ENDIF}
begin
  FDumpCount := 0;
  for i := 0 to 5 do
    PropertiesTreeView.Items.AddChild(nil, 'Item ' + IntToStr(i));
  PropertiesTreeView.Items[0].Selected := True;

  WriteLn('=== FormCreate (before show) ===');
  {$IFDEF LCLGtk4}
  PW := 0; PH := 0;
  if BtnPanel.HandleAllocated then
  begin
    TGtk4Widget(BtnPanel.Handle).preferredSize(PW, PH, True);
    WriteLn('[FormCreate] BtnPanel.preferredSize=', PW, 'x', PH,
      ' HandleAlloc=TRUE realized=', TGtk4Widget(BtnPanel.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(BtnPanel.Handle).Widget^.get_mapped);
  end
  else
    WriteLn('[FormCreate] BtnPanel.HandleAllocated=FALSE');
  PW := 0; PH := 0;
  if StartIDEBitBtn.HandleAllocated then
  begin
    TGtk4Widget(StartIDEBitBtn.Handle).preferredSize(PW, PH, True);
    WriteLn('[FormCreate] StartIDEBitBtn.preferredSize=', PW, 'x', PH,
      ' realized=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_mapped);
  end
  else
    WriteLn('[FormCreate] StartIDEBitBtn.HandleAllocated=FALSE');
  {$ENDIF}
  DumpLayout('FormCreate');
  Application.QueueAsyncCall(@DumpLayoutAsync, 0);
end;

procedure TTestSetupForm.DumpLayoutAsync(Data: PtrInt);
{$IFDEF LCLGtk4}
var
  PW, PH: Integer;
{$ENDIF}
begin
  {$IFDEF LCLGtk4}
  PW := 0; PH := 0;
  if BtnPanel.HandleAllocated then
  begin
    TGtk4Widget(BtnPanel.Handle).preferredSize(PW, PH, True);
    WriteLn('[AfterShow-Idle1] BtnPanel.preferredSize=', PW, 'x', PH,
      ' realized=', TGtk4Widget(BtnPanel.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(BtnPanel.Handle).Widget^.get_mapped);
  end;
  PW := 0; PH := 0;
  if StartIDEBitBtn.HandleAllocated then
  begin
    TGtk4Widget(StartIDEBitBtn.Handle).preferredSize(PW, PH, True);
    WriteLn('[AfterShow-Idle1] StartIDEBitBtn.preferredSize=', PW, 'x', PH,
      ' realized=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_mapped);
  end;
  {$ENDIF}
  DumpLayout('AfterShow-Idle1');
  {$IFDEF LCLGtk4}
  DumpGtk4WidgetTree('AfterShow-Idle1');
  {$ENDIF}
  Application.QueueAsyncCall(@DumpLayoutAsync2, 0);
end;

procedure TTestSetupForm.DumpLayoutAsync2(Data: PtrInt);
{$IFDEF LCLGtk4}
var
  PW, PH: Integer;
{$ENDIF}
begin
  {$IFDEF LCLGtk4}
  PW := 0; PH := 0;
  if BtnPanel.HandleAllocated then
  begin
    TGtk4Widget(BtnPanel.Handle).preferredSize(PW, PH, True);
    WriteLn('[AfterShow-Idle2] BtnPanel.preferredSize=', PW, 'x', PH,
      ' realized=', TGtk4Widget(BtnPanel.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(BtnPanel.Handle).Widget^.get_mapped);
  end;
  PW := 0; PH := 0;
  if StartIDEBitBtn.HandleAllocated then
  begin
    TGtk4Widget(StartIDEBitBtn.Handle).preferredSize(PW, PH, True);
    WriteLn('[AfterShow-Idle2] StartIDEBitBtn.preferredSize=', PW, 'x', PH,
      ' realized=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_realized,
      ' mapped=', TGtk4Widget(StartIDEBitBtn.Handle).Widget^.get_mapped);
  end;
  {$ENDIF}
  DumpLayout('AfterShow-Idle2-BEFORE-Realign');

  { Test: manual Realign }
  WriteLn('[AfterShow-Idle2] Calling Self.Realign...');
  Self.Realign;
  DumpLayout('AfterShow-Idle2-AFTER-Realign');

  { Test: manually inspect anchor chain values }
  WriteLn('[AfterShow-Idle2] TreeView Bottom=', PropertiesTreeView.Top + PropertiesTreeView.Height);
  WriteLn('[AfterShow-Idle2] Splitter.AnchorSide[akBottom].Control=',
    Splitter1.AnchorSide[akBottom].Control.Name,
    ' .Side=', Ord(Splitter1.AnchorSide[akBottom].Side));
  WriteLn('[AfterShow-Idle2] PageCtrl.AnchorSide[akBottom].Control=',
    PropertiesPageControl.AnchorSide[akBottom].Control.Name,
    ' .Side=', Ord(PropertiesPageControl.AnchorSide[akBottom].Side));

  { Test: check anchor resolution directly }
  WriteLn('[AfterShow-Idle2] Splitter.BaseBounds.Bottom=',
    Splitter1.BaseBounds.Bottom);
  WriteLn('[AfterShow-Idle2] Splitter.BaseParentClientSize=',
    Splitter1.BaseParentClientSize.cx, 'x', Splitter1.BaseParentClientSize.cy);
  WriteLn('[AfterShow-Idle2] PropertiesTreeView.BaseBounds.Bottom=',
    PropertiesTreeView.BaseBounds.Bottom);

  { Test: force SetBounds directly to see if it sticks }
  WriteLn('[AfterShow-Idle2] Force Splitter1.Height := ', PropertiesTreeView.Height);
  Splitter1.SetBounds(Splitter1.Left, Splitter1.Top, Splitter1.Width, PropertiesTreeView.Height);
  WriteLn('[AfterShow-Idle2] After force: Splitter1.Height=', Splitter1.Height);

  { Test: use Height property setter directly }
  WriteLn('[AfterShow-Idle2] Before: Height=', Splitter1.Height,
    ' Constraints.MinH=', Splitter1.Constraints.MinHeight,
    ' Constraints.MinInterfaceH=', Splitter1.Constraints.MinInterfaceHeight,
    ' MaxH=', Splitter1.Constraints.MaxHeight,
    ' MaxInterfaceH=', Splitter1.Constraints.MaxInterfaceHeight);
  WriteLn('[AfterShow-Idle2] TreeView Constraints.MinH=', PropertiesTreeView.Constraints.MinHeight,
    ' MinInterfaceH=', PropertiesTreeView.Constraints.MinInterfaceHeight);
  WriteLn('[AfterShow-Idle2] PageCtrl Constraints.MinH=', PropertiesPageControl.Constraints.MinHeight,
    ' MinInterfaceH=', PropertiesPageControl.Constraints.MinInterfaceHeight);
  Self.DisableAlign;
  Splitter1.Anchors := [akTop, akLeft];
  Splitter1.Height := 407;
  WriteLn('[AfterShow-Idle2] After Height:=407 (DisableAlign, no akBottom): H=', Splitter1.Height);
  { Try direct top/left only, simple non-anchor property }
  Splitter1.Top := 54;
  WriteLn('[AfterShow-Idle2] After Top:=54: Top=', Splitter1.Top, ' H=', Splitter1.Height);
  { Try Width change to verify SetBounds works at all }
  Splitter1.Width := 10;
  WriteLn('[AfterShow-Idle2] After Width:=10: W=', Splitter1.Width, ' H=', Splitter1.Height);
  Splitter1.Width := 5;
  Splitter1.Anchors := [akTop, akLeft, akBottom];
  Self.EnableAlign;
  WriteLn('[AfterShow-Idle2] After EnableAlign: H=', Splitter1.Height);

  DumpLayout('AfterShow-Idle2-AFTER-ForceSetBounds');

  {$IFDEF LCLGtk4}
  DumpGtk4WidgetTree('AfterShow-Idle2');
  {$ENDIF}
end;

procedure TTestSetupForm.FormResize(Sender: TObject);
begin
  Inc(FDumpCount);
  if FDumpCount <= 2 then
    DumpLayout('Resize#' + IntToStr(FDumpCount));
end;

procedure TTestSetupForm.WelcomePaintBoxPaint(Sender: TObject);
begin
  with WelcomePaintBox.Canvas do
  begin
    Brush.Color := clHighlight;
    FillRect(0, 0, WelcomePaintBox.Width, WelcomePaintBox.Height);
    Font.Color := clHighlightText;
    Font.Size := 14;
    TextOut(10, 12, 'Welcome to Lazarus IDE - Test Layout');
  end;
end;

procedure TTestSetupForm.StartIDEBitBtnClick(Sender: TObject);
begin
  DumpLayout('ButtonClick');
  {$IFDEF LCLGtk4}
  DumpGtk4WidgetTree('ButtonClick');
  {$ENDIF}
  ShowMessage('Start IDE clicked!');
end;

procedure TTestSetupForm.DumpLayout(const ATag: String);

  procedure DumpControl(C: TControl; Indent: String);
  var
    i: Integer;
    WC: TWinControl;
  begin
    WriteLn(Indent, C.Name, ' [', C.ClassName, '] ',
      'B=', C.Left, ',', C.Top, ',', C.Width, 'x', C.Height,
      ' CL=', C.ClientWidth, 'x', C.ClientHeight,
      ' Vis=', C.Visible,
      ' Al=', Ord(C.Align),
      ' AS=', C.AutoSize);
    if C is TWinControl then
    begin
      WC := TWinControl(C);
      for i := 0 to WC.ControlCount - 1 do
        DumpControl(WC.Controls[i], Indent + '  ');
    end;
  end;

begin
  WriteLn('=== [', ATag, '] Form: ', Width, 'x', Height,
    ' Client: ', ClientWidth, 'x', ClientHeight, ' ===');
  DumpControl(Self, '');
  WriteLn;
end;

{$IFDEF LCLGtk4}
procedure TTestSetupForm.DumpGtk4WidgetTree(const ATag: String);

  function GtkTypeName(W: PGtkWidget): String;
  begin
    if W = nil then
      Result := 'nil'
    else
      Result := g_type_name_from_instance(PGTypeInstance(W));
  end;

  procedure DumpGtkWidget(const AName: String; W: PGtkWidget; AParentRef: PGtkWidget);
  var
    Bounds: graphene_rect_t;
    AW, AH: gint;
    OvflStr: String;
  begin
    if W = nil then
    begin
      WriteLn('  GTK ', AName, ': nil');
      Exit;
    end;
    AW := W^.get_allocated_width;
    AH := W^.get_allocated_height;
    case gtk4_widget_get_overflow(W) of
      0: OvflStr := 'VIS';
      1: OvflStr := 'HID';
    else
      OvflStr := '?';
    end;
    Write('  GTK ', AName, ' [', GtkTypeName(W), ']: ',
      'alloc=', AW, 'x', AH,
      ' vis=', W^.get_visible,
      ' map=', W^.get_mapped,
      ' ovfl=', OvflStr);
    // Compute bounds relative to given reference parent
    if (AParentRef <> nil) and (AW > 0) and (AH > 0) then
    begin
      FillChar(Bounds{%H-}, SizeOf(Bounds), 0);
      if gtk4_widget_compute_bounds(W, AParentRef, @Bounds) then
        Write(' @ref=', Round(Bounds.origin.x), ',',
          Round(Bounds.origin.y), ',',
          Round(Bounds.size.width), 'x', Round(Bounds.size.height));
    end;
    WriteLn;
  end;

  { Walk GTK widget tree from a parent, printing children }
  procedure DumpGtkChildren(const APrefix: String; W: PGtkWidget; ARef: PGtkWidget; ADepth: Integer);
  var
    Child: PGtkWidget;
    Idx: Integer;
  begin
    if (W = nil) or (ADepth > 4) then Exit;
    Child := gtk4_widget_get_first_child(W);
    Idx := 0;
    while Child <> nil do
    begin
      DumpGtkWidget(APrefix + '[' + IntToStr(Idx) + ']', Child, ARef);
      // Recurse one level deeper for important containers
      if ADepth < 3 then
        DumpGtkChildren(APrefix + '[' + IntToStr(Idx) + '].child', Child, ARef, ADepth + 1);
      Child := gtk4_widget_get_next_sibling(Child);
      Inc(Idx);
    end;
  end;

var
  FormWgt: TGtk4WidgetHack;
  FormWin: TGtk4Window;
  BtnWgt: TGtk4WidgetHack;
  BtnChildWgt: TGtk4WidgetHack;
  ScrollWin, Viewport, CentralFixed: PGtkWidget;
begin
  WriteLn('=== [', ATag, '] GTK4 Widget Tree ===');

  if not HandleAllocated then
  begin
    WriteLn('  Form handle not allocated');
    Exit;
  end;

  FormWgt := TGtk4WidgetHack(TGtk4Widget(Handle));
  CentralFixed := FormWgt.FCentralWidget;

  // Form widget: GtkWindow
  DumpGtkWidget('Form.Widget', FormWgt.Widget, nil);

  // Walk into GtkWindow children to find GtkBox → GtkOverlay → GtkScrolledWindow → Viewport → GtkFixed
  WriteLn('  --- Form GTK4 internal hierarchy ---');
  DumpGtkChildren('Form', FormWgt.Widget, FormWgt.Widget, 0);

  // Form FCentralWidget and FPaintArea
  WriteLn('  --- Form LCL pointers ---');
  DumpGtkWidget('Form.FCentralWidget', CentralFixed, nil);
  DumpGtkWidget('Form.FPaintArea', PGtkWidget(FormWgt.FPaintArea), nil);

  // Use public accessor for ScrolledWindow
  if TGtk4Widget(Handle) is TGtk4Window then
  begin
    FormWin := TGtk4Window(Handle);
    ScrollWin := PGtkWidget(FormWin.GetScrolledWindow);
    DumpGtkWidget('Form.ScrollWin', ScrollWin, nil);
    if ScrollWin <> nil then
    begin
      Viewport := PGtkScrolledWindow(ScrollWin)^.get_child;
      DumpGtkWidget('Form.Viewport', Viewport, nil);
    end;
  end;

  // BtnPanel
  // Check FCentralWidget parent chain
  WriteLn('  --- FCentralWidget parent chain ---');
  if CentralFixed <> nil then
  begin
    WriteLn('  FCentralWidget.parent = [', GtkTypeName(CentralFixed^.get_parent), ']');
    if CentralFixed^.get_parent <> nil then
    begin
      WriteLn('  FCentralWidget.parent.parent = [',
        GtkTypeName(CentralFixed^.get_parent^.get_parent), ']');
      if CentralFixed^.get_parent^.get_parent <> nil then
        WriteLn('  FCentralWidget.parent.parent.parent = [',
          GtkTypeName(CentralFixed^.get_parent^.get_parent^.get_parent), ']');
    end;
    // Count children of FCentralWidget
    WriteLn('  FCentralWidget child count:');
    DumpGtkChildren('FCentralWidget.child', CentralFixed, CentralFixed, 0);
  end;

  WriteLn('  --- BtnPanel ---');
  if BtnPanel.HandleAllocated then
  begin
    BtnWgt := TGtk4WidgetHack(TGtk4Widget(BtnPanel.Handle));
    DumpGtkWidget('BtnPanel.Widget', BtnWgt.Widget, CentralFixed);
    DumpGtkWidget('BtnPanel.FCentralWidget', BtnWgt.FCentralWidget, BtnWgt.Widget);
    DumpGtkWidget('BtnPanel.FPaintArea', PGtkWidget(BtnWgt.FPaintArea), BtnWgt.Widget);
    WriteLn('  BtnPanel.Widget.parent=[', GtkTypeName(BtnWgt.Widget^.get_parent), ']');
    // Walk BtnPanel's GTK children
    DumpGtkChildren('BtnPanel', BtnWgt.Widget, BtnWgt.Widget, 0);
  end;

  // StartIDEBitBtn
  WriteLn('  --- StartIDEBitBtn ---');
  if StartIDEBitBtn.HandleAllocated then
  begin
    BtnChildWgt := TGtk4WidgetHack(TGtk4Widget(StartIDEBitBtn.Handle));
    DumpGtkWidget('StartIDEBitBtn.Widget', BtnChildWgt.Widget, BtnWgt.FCentralWidget);
    WriteLn('  StartIDEBitBtn.Widget.parent=[', GtkTypeName(BtnChildWgt.Widget^.get_parent), ']');
  end;

  WriteLn;
end;
{$ENDIF}

end.
