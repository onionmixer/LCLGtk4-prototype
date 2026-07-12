program listview_oversize_repro;

{ Reproduces the Component Palette options-page structure:
    Form -> TScrollBox(alClient) -> frame TPanel(alClient) ->
      TListView(vsReport, anchored akTop+akLeft+akRight+akBottom).
  If the listview reports its full content height as preferred, the scrollbox
  autosize inflates the frame and the listview is allocated its whole content
  height (no internal scroll) — the outer scrollbox then scrolls instead. This
  dumps the listview's allocated Height vs the form/viewport, so gtk4 (bug) and
  qt5 (fixed-height list) can be compared. Env ROWS = item count (default 200). }

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, ComCtrls, ExtCtrls, LCLType;

type
  TMainForm = class(TForm)
  private
    FScroll: TScrollBox;
    FFrame: TPanel;
    FView: TListView;
    procedure Dump;
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

procedure TMainForm.Dump;
begin
  WriteLn(Format('form=%dx%d scroll.client=%dx%d frame=%dx%d listview.H=%d '
    + 'scroll.VertRange=%d',
    [Width, Height, FScroll.ClientWidth, FScroll.ClientHeight,
     FFrame.Width, FFrame.Height, FView.Height,
     FScroll.VertScrollBar.Range]));
  Flush(Output);
end;

constructor TMainForm.CreateNew(AOwner: TComponent; Num: Integer);
var
  i, n: Integer;
  it: TListItem;
  c: TListColumn;
begin
  inherited CreateNew(AOwner, Num);
  Caption := 'listview oversize repro';
  SetBounds(80, 80, 500, 400);

  FScroll := TScrollBox.Create(Self);
  FScroll.Parent := Self;
  FScroll.Align := alClient;

  FFrame := TPanel.Create(Self);
  FFrame.Parent := FScroll;
  FFrame.Align := alClient;
  FFrame.BevelOuter := bvNone;

  FView := TListView.Create(Self);
  FView.Parent := FFrame;
  FView.ViewStyle := vsReport;
  FView.RowSelect := True;
  FView.Anchors := [akTop, akLeft, akRight, akBottom];
  FView.SetBounds(6, 6, FFrame.Width - 12, FFrame.Height - 12);
  c := FView.Columns.Add; c.Caption := 'Name'; c.Width := 200;
  c := FView.Columns.Add; c.Caption := 'Unit'; c.Width := 200;

  n := StrToIntDef(GetEnvironmentVariable('ROWS'), 200);
  FView.Items.BeginUpdate;
  for i := 0 to n - 1 do
  begin
    it := FView.Items.Add;
    it.Caption := 'Item' + IntToStr(i);
    it.SubItems.Add('unit' + IntToStr(i));
  end;
  FView.Items.EndUpdate;
end;

var
  F: TMainForm;
begin
  Application.Initialize;
  F := TMainForm.CreateNew(Application);
  F.Show;
  Application.ProcessMessages;
  F.Dump;
  if GetEnvironmentVariable('SHOT') <> '' then
  begin
    Application.ProcessMessages; Sleep(1500); Application.ProcessMessages;
  end;
end.
