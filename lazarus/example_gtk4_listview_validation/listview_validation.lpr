program listview_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, TypInfo, Math, Forms, Controls, Graphics,
  StdCtrls, ExtCtrls, ComCtrls, ImgList, Types;

type
  TListViewValidationForm = class(TForm)
  private
    FListView: TListView;
    FLog: TMemo;
    FLargeImages: TImageList;
    FSmallImages: TImageList;
    FStateImages: TImageList;
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    procedure AddButton(const ACaption: string; ALeft: Integer;
      AHandler: TNotifyEvent);
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure ConfigureView(AViewStyle: TViewStyle);
    procedure Log(const S: string);
    procedure LogCurrentState(const AContext: string);
    procedure ManualIcon(Sender: TObject);
    procedure ManualList(Sender: TObject);
    procedure ManualReport(Sender: TObject);
    procedure ManualSmallIcon(Sender: TObject);
    procedure ManualStateAll(Sender: TObject);
    procedure ManualStateNone(Sender: TObject);
    procedure Populate;
    procedure RunViewChecks(AViewStyle: TViewStyle);
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  ListViewValidationForm: TListViewValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('LISTVIEW_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('LISTVIEW_VALIDATION_CLOSE_MS'), 0);
end;

function RectText(const R: TRect): string;
begin
  Result := Format('(%d,%d,%d,%d) %dx%d',
    [R.Left, R.Top, R.Right, R.Bottom, R.Width, R.Height]);
end;

function HitTestsText(AHits: THitTests): string;
var
  H: THitTest;
begin
  Result := '';
  for H := Low(THitTest) to High(THitTest) do
    if H in AHits then
    begin
      if Result <> '' then
        Result := Result + ',';
      Result := Result + GetEnumName(TypeInfo(THitTest), Ord(H));
    end;
  if Result = '' then
    Result := '[]';
end;

function ViewStyleName(AStyle: TViewStyle): string;
begin
  case AStyle of
    vsIcon: Result := 'vsIcon';
    vsSmallIcon: Result := 'vsSmallIcon';
    vsList: Result := 'vsList';
    vsReport: Result := 'vsReport';
  else
    Result := 'unknown';
  end;
end;

procedure AddIcon(AImages: TImageList; ASize: Integer; AColor, AAccent: TColor);
var
  Bmp: TBitmap;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(ASize, ASize);
    Bmp.Canvas.Brush.Color := AColor;
    Bmp.Canvas.FillRect(0, 0, ASize, ASize);
    Bmp.Canvas.Brush.Color := AAccent;
    Bmp.Canvas.Ellipse(ASize div 4, ASize div 4, ASize - ASize div 4,
      ASize - ASize div 4);
    Bmp.Canvas.Pen.Color := clWhite;
    Bmp.Canvas.Line(1, ASize - 2, ASize - 2, 1);
    AImages.AddMasked(Bmp, clFuchsia);
  finally
    Bmp.Free;
  end;
end;

constructor TListViewValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 ListView validation';
  Position := poDesigned;
  SetBounds(100, 100, 900, 680);

  FLargeImages := TImageList.Create(Self);
  FLargeImages.Width := 32;
  FLargeImages.Height := 32;
  AddIcon(FLargeImages, 32, clRed, clYellow);
  AddIcon(FLargeImages, 32, clBlue, clWhite);

  FSmallImages := TImageList.Create(Self);
  FSmallImages.Width := 16;
  FSmallImages.Height := 16;
  AddIcon(FSmallImages, 16, clLime, clBlack);
  AddIcon(FSmallImages, 16, clAqua, clNavy);

  FStateImages := TImageList.Create(Self);
  FStateImages.Width := 12;
  FStateImages.Height := 12;
  AddIcon(FStateImages, 12, clPurple, clWhite);
  AddIcon(FStateImages, 12, clMaroon, clYellow);

  FListView := TListView.Create(Self);
  FListView.Parent := Self;
  FListView.SetBounds(16, 56, 850, 360);
  FListView.ReadOnly := True;
  FListView.RowSelect := True;
  FListView.HideSelection := False;
  FListView.MultiSelect := True;
  FListView.LargeImages := FLargeImages;
  FListView.SmallImages := FSmallImages;
  FListView.StateImages := FStateImages;
  FListView.Columns.Add.Caption := 'Name';
  FListView.Columns[0].Width := 220;
  FListView.Columns.Add.Caption := 'Sub';
  FListView.Columns[1].Width := 160;
  Populate;

  AddButton('Report', 16, @ManualReport);
  AddButton('List', 112, @ManualList);
  AddButton('Icon', 208, @ManualIcon);
  AddButton('SmallIcon', 304, @ManualSmallIcon);
  AddButton('StateAll', 400, @ManualStateAll);
  AddButton('StateNone', 496, @ManualStateNone);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(16, 432, 850, 200);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 400;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;

  ConfigureView(vsReport);
end;

destructor TListViewValidationForm.Destroy;
begin
  inherited Destroy;
end;

procedure TListViewValidationForm.Populate;
var
  I: Integer;
  Item: TListItem;
begin
  FListView.Items.BeginUpdate;
  try
    FListView.Items.Clear;
    for I := 0 to 119 do
    begin
      Item := FListView.Items.Add;
      Item.Caption := Format('Item %.3d', [I]);
      Item.SubItems.Add(Format('Sub %.3d', [I]));
      Item.ImageIndex := I mod 2;
      { -1, 0, 1 cycle: items without a state image must fall back to the
        normal item image (state image occupies the icon slot when set) }
      Item.StateIndex := (I mod 3) - 1;
      Item.Checked := (I mod 3) = 0;
    end;
  finally
    FListView.Items.EndUpdate;
  end;
end;

procedure TListViewValidationForm.AddButton(const ACaption: string;
  ALeft: Integer; AHandler: TNotifyEvent);
var
  Button: TButton;
begin
  Button := TButton.Create(Self);
  Button.Parent := Self;
  Button.Caption := ACaption;
  Button.SetBounds(ALeft, 16, 88, 28);
  Button.OnClick := AHandler;
end;

procedure TListViewValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  LogCurrentState('initial');
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

procedure TListViewValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TListViewValidationForm.ConfigureView(AViewStyle: TViewStyle);
begin
  FListView.ViewStyle := AViewStyle;
  FListView.Checkboxes := AViewStyle in [vsReport, vsList];
  FListView.ShowColumnHeaders := True;
  FListView.ColumnClick := True;
  FListView.Items[0].Selected := True;
  FListView.Items[0].Focused := True;
  FListView.Items[15].Selected := True;
  Application.ProcessMessages;
end;

procedure TListViewValidationForm.LogCurrentState(const AContext: string);
var
  TopText, FocusText: string;
begin
  if FListView.TopItem <> nil then
    TopText := FListView.TopItem.Caption
  else
    TopText := 'nil';
  if FListView.ItemFocused <> nil then
    FocusText := FListView.ItemFocused.Caption
  else
    FocusText := 'nil';
  Log(Format('%s view=%s count=%d sel=%d top=%s visibleRows=%d focused=%s',
    [AContext, ViewStyleName(FListView.ViewStyle), FListView.Items.Count,
     FListView.SelCount, TopText, FListView.VisibleRowCount, FocusText]));
end;

procedure TListViewValidationForm.RunViewChecks(AViewStyle: TViewStyle);
var
  R0, R80Before, R80After: TRect;
  P0, P80: TPoint;
  Hits: THitTests;
begin
  ConfigureView(AViewStyle);
  Log('--- CHECK ' + ViewStyleName(AViewStyle) + ' ---');
  LogCurrentState('after configure');
  R0 := FListView.Items[0].DisplayRect(drBounds);
  R80Before := FListView.Items[80].DisplayRect(drBounds);
  P0 := FListView.Items[0].Position;
  P80 := FListView.Items[80].Position;
  Hits := FListView.GetHitTestInfoAt(Max(0, R0.Left + 4), Max(0, R0.Top + 4));
  Log('item0 rect=' + RectText(R0) + ' pos=' + Format('(%d,%d)', [P0.X, P0.Y]) +
    ' hit=' + HitTestsText(Hits));
  Log('item80 before visible rect=' + RectText(R80Before) +
    ' pos=' + Format('(%d,%d)', [P80.X, P80.Y]));
  FListView.Items[80].MakeVisible(False);
  Application.ProcessMessages;
  R80After := FListView.Items[80].DisplayRect(drBounds);
  LogCurrentState('after MakeVisible item80');
  Log('item80 after visible rect=' + RectText(R80After));
  Log(Format('state sample item0=%d item1=%d large=%dx%d small=%dx%d state=%dx%d',
    [FListView.Items[0].StateIndex, FListView.Items[1].StateIndex,
     FLargeImages.Width, FLargeImages.Height, FSmallImages.Width,
     FSmallImages.Height, FStateImages.Width, FStateImages.Height]));
end;

procedure TListViewValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  RunViewChecks(vsReport);
  RunViewChecks(vsList);
  RunViewChecks(vsIcon);
  RunViewChecks(vsSmallIcon);
  Log('AUTO end');
  Application.Terminate;
end;

procedure TListViewValidationForm.CloseTimer(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TListViewValidationForm.ManualReport(Sender: TObject);
begin
  ConfigureView(vsReport);
  LogCurrentState('manual report');
end;

procedure TListViewValidationForm.ManualList(Sender: TObject);
begin
  ConfigureView(vsList);
  LogCurrentState('manual list');
end;

procedure TListViewValidationForm.ManualIcon(Sender: TObject);
begin
  ConfigureView(vsIcon);
  LogCurrentState('manual icon');
end;

procedure TListViewValidationForm.ManualSmallIcon(Sender: TObject);
begin
  ConfigureView(vsSmallIcon);
  LogCurrentState('manual smallicon');
end;

{ Runtime StateIndex change — validates that ItemSetStateImage refreshes
  already-bound rows (state image must appear/disappear without scrolling). }
procedure TListViewValidationForm.ManualStateAll(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to FListView.Items.Count - 1 do
    FListView.Items[I].StateIndex := I mod 2;
  LogCurrentState('state all');
end;

procedure TListViewValidationForm.ManualStateNone(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to FListView.Items.Count - 1 do
    FListView.Items[I].StateIndex := -1;
  LogCurrentState('state none');
end;

begin
  Application.Initialize;
  Application.CreateForm(TListViewValidationForm, ListViewValidationForm);
  Application.Run;
end.
