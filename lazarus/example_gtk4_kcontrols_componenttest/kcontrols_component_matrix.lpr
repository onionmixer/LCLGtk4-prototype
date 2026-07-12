program kcontrols_component_matrix;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Types, Forms, Controls, StdCtrls, ComCtrls,
  Graphics;

var
  PassCount: Integer = 0;
  FailCount: Integer = 0;

type
  TTestUpDown = class(TUpDown)
  public
    procedure PressButton(AButton: TUDBtnType);
  end;

procedure TTestUpDown.PressButton(AButton: TUDBtnType);
begin
  Click(AButton);
end;

function RectIsValid(const R: TRect): Boolean;
begin
  Result := (R.Right > R.Left) and (R.Bottom > R.Top);
end;

procedure Pump;
begin
  Application.ProcessMessages;
  Sleep(30);
  Application.ProcessMessages;
end;

procedure Check(const AName: string; ACondition: Boolean; const ADetails: string = '');
begin
  if ACondition then
  begin
    Inc(PassCount);
    WriteLn('PASS ', AName);
  end
  else
  begin
    Inc(FailCount);
    if ADetails <> '' then
      WriteLn('FAIL ', AName, ' :: ', ADetails)
    else
      WriteLn('FAIL ', AName);
  end;
end;

function ItemName(AItem: TListItem): string;
begin
  if AItem = nil then
    Result := 'nil'
  else
    Result := Format('%d:%s', [AItem.Index, AItem.Caption]);
end;

function HitTestsName(const AHitTests: THitTests): string;
begin
  Result := '';
  if htOnItem in AHitTests then
    Result := Result + ' htOnItem';
  if htOnLabel in AHitTests then
    Result := Result + ' htOnLabel';
  if htOnIcon in AHitTests then
    Result := Result + ' htOnIcon';
  if htNowhere in AHitTests then
    Result := Result + ' htNowhere';
  if Result = '' then
    Result := '[]'
  else
    Delete(Result, 1, 1);
end;

procedure AddListItem(AListView: TListView; const ACaption: string; AValue: Integer);
var
  Item: TListItem;
begin
  Item := AListView.Items.Add;
  Item.Caption := ACaption;
  Item.SubItems.Add(IntToStr(AValue));
  Item.SubItems.Add(IntToStr(AValue * 10));
  Item.SubItems.Add(IntToStr(AValue * 100));
  Item.SubItems.Add('no');
end;

procedure RunUpDownTest(AOwner: TComponent; AParent: TWinControl);
var
  Edit: TEdit;
  UpDown: TTestUpDown;
begin
  WriteLn('SECTION updown');

  Edit := TEdit.Create(AOwner);
  Edit.Parent := AParent;
  Edit.SetBounds(16, 16, 90, 28);

  UpDown := TTestUpDown.Create(AOwner);
  UpDown.Parent := AParent;
  UpDown.SetBounds(110, 16, 24, 28);
  UpDown.Associate := Edit;
  UpDown.Min := 0;
  UpDown.Max := 10;
  UpDown.Increment := 2;
  UpDown.Position := 5;
  UpDown.Wrap := False;
  Pump;

  Check('updown.initial-position', UpDown.Position = 5, Format('position=%d', [UpDown.Position]));
  Check('updown.associate-text', Edit.Text = '5', 'edit=' + Edit.Text);

  UpDown.PressButton(btNext);
  Pump;
  Check('updown.next-increments-position', UpDown.Position = 7, Format('position=%d', [UpDown.Position]));
  Check('updown.next-updates-edit', Edit.Text = '7', 'edit=' + Edit.Text);

  UpDown.PressButton(btNext);
  UpDown.PressButton(btNext);
  Pump;
  Check('updown.clamps-at-max-without-wrap', UpDown.Position = 10, Format('position=%d', [UpDown.Position]));

  UpDown.Wrap := True;
  UpDown.PressButton(btNext);
  Pump;
  Check('updown.wraps-after-max', UpDown.Position = 1, Format('position=%d', [UpDown.Position]));

  UpDown.PressButton(btPrev);
  Pump;
  Check('updown.wraps-before-min', UpDown.Position = 10, Format('position=%d', [UpDown.Position]));

  UpDown.Orientation := udHorizontal;
  Pump;
  Check('updown.orientation-horizontal-property', UpDown.Orientation = udHorizontal);

  Edit.Enabled := False;
  Pump;
  Check('updown.follows-associate-enabled-false', not UpDown.Enabled);

  Edit.Enabled := True;
  Edit.Visible := False;
  Pump;
  Check('updown.follows-associate-visible-false', not UpDown.Visible);

  Edit.Visible := True;
  Pump;
  Check('updown.follows-associate-visible-true', UpDown.Visible);
end;

procedure PrepareListViewColumns(AListView: TListView);
begin
  AListView.Columns.Add.Caption := 'Image';
  AListView.Columns[0].Width := 80;
  AListView.Columns.Add.Caption := 'Width';
  AListView.Columns[1].Width := 70;
  AListView.Columns.Add.Caption := 'Height';
  AListView.Columns[2].Width := 70;
  AListView.Columns.Add.Caption := 'Resolution';
  AListView.Columns[3].Width := 90;
  AListView.Columns.Add.Caption := 'PNG';
  AListView.Columns[4].Width := 50;
end;

procedure RunListViewReportTest(AOwner: TComponent; AParent: TWinControl);
var
  ListView: TListView;
  R: TRect;
  Center: TPoint;
  FoundItem: TListItem;
  HitTests: THitTests;
begin
  WriteLn('SECTION listview-report');

  ListView := TListView.Create(AOwner);
  ListView.Parent := AParent;
  ListView.SetBounds(16, 58, 470, 180);
  ListView.ViewStyle := vsReport;
  ListView.ReadOnly := True;
  ListView.RowSelect := True;
  ListView.HideSelection := False;
  ListView.GridLines := True;
  ListView.ShowColumnHeaders := True;
  PrepareListViewColumns(ListView);
  AddListItem(ListView, 'first', 16);
  AddListItem(ListView, 'second', 32);
  AddListItem(ListView, 'third', 48);
  AddListItem(ListView, 'fourth', 64);
  AddListItem(ListView, 'fifth', 128);
  Pump;

  ListView.Selected := ListView.Items[2];
  ListView.ItemFocused := ListView.Items[2];
  Pump;

  Check('listview.report-column-count', ListView.Columns.Count = 5, Format('columns=%d', [ListView.Columns.Count]));
  Check('listview.report-item-count', ListView.Items.Count = 5, Format('items=%d', [ListView.Items.Count]));
  Check('listview.report-caption-stored', ListView.Items[2].Caption = 'third', 'caption=' + ListView.Items[2].Caption);
  Check('listview.report-subitem-stored', ListView.Items[2].SubItems[1] = '480', 'subitem=' + ListView.Items[2].SubItems[1]);
  Check('listview.report-column-width-positive', ListView.Columns[0].Width > 0, Format('width=%d', [ListView.Columns[0].Width]));
  Check('listview.report-selected-item', ListView.Selected = ListView.Items[2], 'selected=' + ItemName(ListView.Selected));
  Check('listview.report-selected-state', ListView.Items[2].Selected);
  Check('listview.report-selcount-single', ListView.SelCount = 1, Format('selcount=%d', [ListView.SelCount]));
  Check('listview.report-focused-item', ListView.ItemFocused = ListView.Items[2], 'focused=' + ItemName(ListView.ItemFocused));
  Check('listview.report-itemindex', ListView.ItemIndex = 2, Format('itemindex=%d', [ListView.ItemIndex]));
  Check('listview.report-visible-row-count', ListView.VisibleRowCount > 0, Format('visible=%d', [ListView.VisibleRowCount]));
  Check('listview.report-topitem-present', ListView.TopItem <> nil, 'top=' + ItemName(ListView.TopItem));

  R := ListView.Items[2].DisplayRect(drBounds);
  Check('listview.report-displayrect-valid', RectIsValid(R),
    Format('rect=%d,%d,%d,%d', [R.Left, R.Top, R.Right, R.Bottom]));
  if RectIsValid(R) then
  begin
    Center := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
    FoundItem := ListView.GetItemAt(Center.X, Center.Y);
    Check('listview.report-getitemat-center', FoundItem = ListView.Items[2],
      'found=' + ItemName(FoundItem) + Format(' at %d,%d', [Center.X, Center.Y]));
    HitTests := ListView.GetHitTestInfoAt(Center.X, Center.Y);
    Check('listview.report-hittest-center-onitem', htOnItem in HitTests,
      'hit=' + HitTestsName(HitTests));
  end;

  ListView.MultiSelect := True;
  Pump;
  ListView.SelectAll;
  Pump;
  Check('listview.report-selectall-multiselect', ListView.SelCount = ListView.Items.Count,
    Format('selcount=%d items=%d', [ListView.SelCount, ListView.Items.Count]));

  ListView.Selected := nil;
  Pump;
  Check('listview.report-clear-selection', ListView.SelCount = 0, Format('selcount=%d', [ListView.SelCount]));
end;

procedure RunListViewColumnOpsTest(AOwner: TComponent; AParent: TWinControl);
var
  ListView: TListView;
  Column: TListColumn;
begin
  WriteLn('SECTION listview-columnops');

  ListView := TListView.Create(AOwner);
  ListView.Parent := AParent;
  ListView.SetBounds(500, 58, 190, 180);
  ListView.ViewStyle := vsReport;

  Column := ListView.Columns.Add;
  Column.Caption := 'A';
  Column.Width := 60;
  Column := ListView.Columns.Add;
  Column.Caption := 'B';
  Column.Width := 70;
  Column := ListView.Columns.Add;
  Column.Caption := 'C';
  Column.Width := 80;
  AddListItem(ListView, 'row', 10);
  Pump;

  Check('listview.columns.initial-count', ListView.Columns.Count = 3,
    Format('columns=%d', [ListView.Columns.Count]));
  Check('listview.columns.caption-set', ListView.Columns[1].Caption = 'B',
    'caption=' + ListView.Columns[1].Caption);
  Check('listview.columns.width-set', ListView.Columns[1].Width > 0,
    Format('width=%d', [ListView.Columns[1].Width]));

  ListView.Columns[1].Caption := 'B2';
  ListView.Columns[1].Width := 90;
  Pump;
  Check('listview.columns.caption-change', ListView.Columns[1].Caption = 'B2',
    'caption=' + ListView.Columns[1].Caption);
  Check('listview.columns.width-change', ListView.Columns[1].Width > 0,
    Format('width=%d', [ListView.Columns[1].Width]));

  ListView.Columns[1].Visible := False;
  Pump;
  Check('listview.columns.visible-false-property', not ListView.Columns[1].Visible);
  ListView.Columns[1].Visible := True;
  Pump;
  Check('listview.columns.visible-true-property', ListView.Columns[1].Visible);

  ListView.Columns[2].Index := 0;
  Pump;
  Check('listview.columns.move-index', ListView.Columns[0].Caption = 'C',
    'caption0=' + ListView.Columns[0].Caption);

  ListView.Columns.Delete(1);
  Pump;
  Check('listview.columns.delete-count', ListView.Columns.Count = 2,
    Format('columns=%d', [ListView.Columns.Count]));
  Column := ListView.Columns.Add;
  Column.Caption := 'D';
  Column.Width := 75;
  Pump;
  Check('listview.columns.insert-after-delete-count', ListView.Columns.Count = 3,
    Format('columns=%d', [ListView.Columns.Count]));
  Check('listview.columns.insert-after-delete-caption', ListView.Columns[2].Caption = 'D',
    'caption=' + ListView.Columns[2].Caption);
end;

procedure RunListViewStyleSmokeTest(AOwner: TComponent; AParent: TWinControl;
  AStyle: TViewStyle; const AName: string; ATop: Integer);
var
  ListView: TListView;
  R: TRect;
begin
  WriteLn('SECTION listview-', AName);

  ListView := TListView.Create(AOwner);
  ListView.Parent := AParent;
  ListView.SetBounds(16, ATop, 220, 100);
  ListView.ViewStyle := AStyle;
  AddListItem(ListView, AName + '-first', 1);
  AddListItem(ListView, AName + '-second', 2);
  AddListItem(ListView, AName + '-third', 3);
  Pump;

  ListView.Selected := ListView.Items[1];
  ListView.ItemFocused := ListView.Items[1];
  Pump;

  Check('listview.' + AName + '.item-count', ListView.Items.Count = 3, Format('items=%d', [ListView.Items.Count]));
  Check('listview.' + AName + '.selected-item', ListView.Selected = ListView.Items[1], 'selected=' + ItemName(ListView.Selected));
  Check('listview.' + AName + '.focused-item', ListView.ItemFocused = ListView.Items[1], 'focused=' + ItemName(ListView.ItemFocused));

  R := ListView.Items[1].DisplayRect(drBounds);
  Check('listview.' + AName + '.displayrect-valid', RectIsValid(R),
    Format('rect=%d,%d,%d,%d', [R.Left, R.Top, R.Right, R.Bottom]));
end;

var
  Form: TForm;
begin
  Application.Initialize;
  Form := TForm.Create(nil);
  try
    Form.Caption := 'GTK component matrix';
    Form.SetBounds(100, 100, 720, 640);
    Form.Show;
    Pump;
    RunUpDownTest(Form, Form);
    RunListViewReportTest(Form, Form);
    RunListViewColumnOpsTest(Form, Form);
    RunListViewStyleSmokeTest(Form, Form, vsList, 'list', 250);
    RunListViewStyleSmokeTest(Form, Form, vsIcon, 'icon', 360);
    RunListViewStyleSmokeTest(Form, Form, vsSmallIcon, 'smallicon', 470);
    Pump;
  finally
    Form.Free;
  end;

  WriteLn('SUMMARY pass=', PassCount, ' fail=', FailCount);
  if FailCount <> 0 then
    Halt(1);
end.
