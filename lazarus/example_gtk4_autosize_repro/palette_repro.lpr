program palette_repro;

{ Mirrors ide/frames/componentpalette_options: a left TListBox (OnSelectionChange)
  that refills a right TListView (vsReport) via Clear+Add. Reproduces the report
  that clicking the left list blanks the right list and never recovers.

  Env:
    CLICK=<row>   after showing, programmatically set PagesListBox.ItemIndex
                  (simulates the LCL side of a click) and dump.
  Always dumps ItemIndex + right item count on every SelectionChange. }

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, ComCtrls,
  LCLType, LCLIntf, ImgList;

type
  TMainForm = class(TForm)
  private
    FList: TListBox;
    FView: TListView;
    FImages: TImageList;
    FPrev: Integer;
    procedure SelChange(Sender: TObject; User: boolean);
    procedure FillView(const APage: string);
    procedure Dump(const Ctx: string);
    procedure ViewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

procedure TMainForm.ViewCustomDrawItem(Sender: TCustomListView; Item: TListItem;
  State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw := True;   { activate the widgetset custom-draw bind path }
end;

procedure TMainForm.Dump(const Ctx: string);
begin
  WriteLn(Format('DUMP %-14s listIdx=%d prev=%d viewCount=%d viewVisible=%s',
    [Ctx, FList.ItemIndex, FPrev, FView.Items.Count,
     BoolToStr(FView.IsControlVisible, True)]));
  Flush(Output);
end;

procedure TMainForm.FillView(const APage: string);
var
  i, n: Integer;
  it: TListItem;
  t0: QWord;
begin
  t0 := GetTickCount64;
  FView.Items.BeginUpdate;
  FView.Items.Clear;
  if APage = '<All>' then
    n := StrToIntDef(GetEnvironmentVariable('ALLN'), 12)
  else n := StrToIntDef(GetEnvironmentVariable('PAGEN'), 4);
  for i := 0 to n - 1 do
  begin
    it := FView.Items.Add;                        { caption empty (icon col) }
    it.SubItems.Add(APage + '-item' + IntToStr(i));
    it.SubItems.Add(APage);
    it.SubItems.Add('unit' + IntToStr(i));
  end;
  FView.Items.EndUpdate;
  { real frame does NOT select any item here (autoselect off) }
  WriteLn(Format('FillView(%s) n=%d took %d ms', [APage, n, GetTickCount64 - t0]));
  Flush(Output);
end;

procedure TMainForm.SelChange(Sender: TObject; User: boolean);
var
  lb: TListBox;
begin
  lb := Sender as TListBox;
  Dump('selchange-in');
  if lb.ItemIndex = FPrev then begin Dump('selchange-skip'); Exit; end;
  if lb.ItemIndex >= 0 then
    FillView(lb.Items[lb.ItemIndex]);
  FPrev := lb.ItemIndex;
  Dump('selchange-out');
end;

constructor TMainForm.CreateNew(AOwner: TComponent; Num: Integer);
var
  i: Integer;
  c: TListColumn;
begin
  inherited CreateNew(AOwner, Num);
  Caption := 'palette repro';
  SetBounds(80, 80, 600, 400);
  FPrev := -1;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alLeft;
  FList.Width := 200;
  FList.OnSelectionChange := @SelChange;

  FImages := TImageList.Create(Self);
  FImages.Width := 24; FImages.Height := 24;

  FView := TListView.Create(Self);
  FView.Parent := Self;
  FView.Align := alClient;
  FView.ViewStyle := vsReport;
  FView.RowSelect := True;
  FView.ReadOnly := True;
  FView.SmallImages := FImages;                       { real frame: IDEImages.Images_24 }
  FView.OnCustomDrawItem := @ViewCustomDrawItem;      { real frame has OnCustomDrawItem }
  c := FView.Columns.Add; c.Width := 35;              { icon column (real frame) }
  c := FView.Columns.Add; c.Caption := 'Name'; c.Width := 150;
  c := FView.Columns.Add; c.Caption := 'Page'; c.Width := 120;
  c := FView.Columns.Add; c.Caption := 'Unit'; c.Width := 120;

  FList.Items.BeginUpdate;
  FList.Items.Add('<All>');
  for i := 1 to 6 do
    FList.Items.Add('Page' + IntToStr(i));
  FList.ItemIndex := 0;
  FList.Items.EndUpdate;
end;

var
  F: TMainForm;
  clk: Integer;
begin
  Application.Initialize;
  F := TMainForm.CreateNew(Application);
  F.Show;
  Application.ProcessMessages;
  F.Dump('after-show');
  clk := StrToIntDef(GetEnvironmentVariable('CLICK'), -99);
  if clk <> -99 then
  begin
    F.FList.ItemIndex := clk;   { LCL-side selection change }
    Application.ProcessMessages;
    F.Dump('after-setidx');
  end;
  if GetEnvironmentVariable('SHOT') <> '' then
  begin
    for clk := 0 to 120 do   { ~12s, processing messages so clicks work }
    begin
      Application.ProcessMessages;
      Sleep(100);
    end;
  end;
end.
