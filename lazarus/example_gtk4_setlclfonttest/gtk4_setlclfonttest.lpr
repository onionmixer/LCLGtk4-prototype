program gtk4_setlclfonttest;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Classes, SysUtils, StrUtils, Forms, Controls, Graphics, StdCtrls, ExtCtrls,
  LCLIntf, LCLType, LCLPlatformDef, InterfaceBase;

type
  TCharSetCase = record
    Name: string;
    CharSet: TFontCharSet;
    Sample: string;
  end;

  { TMainForm }

  TMainForm = class(TForm)
  private
    FPaintBox: TPaintBox;
    FRunAndClose: Boolean;
    procedure DumpCase(const ACase: TCharSetCase; const AControlFont: TFont);
    procedure DumpResults;
    procedure PaintSamples(Sender: TObject);
    procedure QueueDump(Data: PtrInt);
  public
    constructor Create(TheOwner: TComponent); override;
  end;

const
  CharSetCases: array[0..6] of TCharSetCase = (
    (Name: 'DEFAULT_CHARSET'; CharSet: DEFAULT_CHARSET; Sample: 'Default: Hello GTK4 Lazarus'),
    (Name: 'RUSSIAN_CHARSET'; CharSet: RUSSIAN_CHARSET; Sample: 'Russian: Привет мир'),
    (Name: 'GREEK_CHARSET'; CharSet: GREEK_CHARSET; Sample: 'Greek: Καλημέρα κόσμε'),
    (Name: 'SHIFTJIS_CHARSET'; CharSet: SHIFTJIS_CHARSET; Sample: 'Japanese: 日本語の表示'),
    (Name: 'HANGEUL_CHARSET'; CharSet: HANGEUL_CHARSET; Sample: 'Korean: 한글 표시 테스트'),
    (Name: 'GB2312_CHARSET'; CharSet: GB2312_CHARSET; Sample: 'Simplified Chinese: 中文显示测试'),
    (Name: 'CHINESEBIG5_CHARSET'; CharSet: CHINESEBIG5_CHARSET; Sample: 'Traditional Chinese: 繁體中文顯示測試')
  );

function HasParam(const AName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 1 to ParamCount do
    if SameText(ParamStr(I), AName) then
      Exit(True);
end;

{ TMainForm }

constructor TMainForm.Create(TheOwner: TComponent);
var
  I: Integer;
  L: TLabel;
begin
  inherited Create(TheOwner);
  Caption := 'GTK4 SetLclFont CharSet test';
  Width := 980;
  Height := 620;
  Position := poScreenCenter;
  FRunAndClose := not HasParam('--stay-open');

  for I := Low(CharSetCases) to High(CharSetCases) do
  begin
    L := TLabel.Create(Self);
    L.Parent := Self;
    L.Left := 16;
    L.Top := 12 + I * 30;
    L.Width := 920;
    L.Height := 24;
    L.Font.Name := 'Sans';
    L.Font.Size := 12;
    L.Font.CharSet := CharSetCases[I].CharSet;
    L.Caption := Format('%s (%d): %s',
      [CharSetCases[I].Name, Ord(CharSetCases[I].CharSet), CharSetCases[I].Sample]);
  end;

  FPaintBox := TPaintBox.Create(Self);
  FPaintBox.Parent := Self;
  FPaintBox.Left := 16;
  FPaintBox.Top := 240;
  FPaintBox.Width := 930;
  FPaintBox.Height := 320;
  FPaintBox.OnPaint := @PaintSamples;

  Application.QueueAsyncCall(@QueueDump, 0);
end;

procedure TMainForm.DumpCase(const ACase: TCharSetCase; const AControlFont: TFont);
var
  LF: TLogFont;
  TM: TTextMetric;
  W: Integer;
begin
  FillChar(LF, SizeOf(LF), 0);
  FillChar(TM, SizeOf(TM), 0);

  Canvas.Font.Assign(AControlFont);
  Canvas.Font.CharSet := ACase.CharSet;

  W := Canvas.TextWidth(ACase.Sample);
  if GetObject(Canvas.Font.Handle, SizeOf(LF), @LF) = 0 then
    WriteLn('  GetObject: failed')
  else
    WriteLn('  GetObject.lfCharSet=', LF.lfCharSet);

  if GetTextMetrics(Canvas.Handle, TM) then
    WriteLn('  Metrics: height=', TM.tmHeight,
      ' ave=', TM.tmAveCharWidth,
      ' max=', TM.tmMaxCharWidth,
      ' tmCharSet=', TM.tmCharSet)
  else
    WriteLn('  Metrics: failed');

  WriteLn('  TextWidth=', W);
end;

procedure TMainForm.DumpResults;
var
  I: Integer;
  BaseFont: TFont;
begin
  WriteLn('GTK4 SetLclFont / Canvas CharSet test');
  WriteLn('WidgetSet=', LCLPlatformDisplayNames[WidgetSet.LCLPlatform]);
  WriteLn('Run mode=', IfThen(FRunAndClose, 'auto-close', 'stay-open'));

  BaseFont := TFont.Create;
  try
    BaseFont.Name := 'Sans';
    BaseFont.Size := 12;
    for I := Low(CharSetCases) to High(CharSetCases) do
    begin
      WriteLn('CASE ', CharSetCases[I].Name,
        ' charset=', Ord(CharSetCases[I].CharSet),
        ' sample="', CharSetCases[I].Sample, '"');
      DumpCase(CharSetCases[I], BaseFont);
    end;
  finally
    BaseFont.Free;
  end;
end;

procedure TMainForm.PaintSamples(Sender: TObject);
var
  I, Y: Integer;
begin
  FPaintBox.Canvas.Brush.Color := clWhite;
  FPaintBox.Canvas.FillRect(FPaintBox.ClientRect);
  FPaintBox.Canvas.Font.Name := 'Sans';
  FPaintBox.Canvas.Font.Size := 12;

  Y := 12;
  for I := Low(CharSetCases) to High(CharSetCases) do
  begin
    FPaintBox.Canvas.Font.CharSet := CharSetCases[I].CharSet;
    FPaintBox.Canvas.TextOut(12, Y, CharSetCases[I].Name + ': ' + CharSetCases[I].Sample);
    Inc(Y, 34);
  end;
end;

procedure TMainForm.QueueDump(Data: PtrInt);
begin
  DumpResults;
  if FRunAndClose then
    Application.Terminate;
end;

var
  MainForm: TMainForm;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
