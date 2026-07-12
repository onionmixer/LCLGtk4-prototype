program dockdrag_validation;

{$mode objfpc}{$H+}

{ Focused validation for the LCL-core TDockPerformer.DragStop asymmetry:
  TDragPerformer.DragStop calls FDragImageList.EndDrag, TDockPerformer.DragStop
  does not. A custom dock object that overrides GetDragImages therefore leaks
  TDragImageList.Dragging=True (and the Screen temp drag cursor) after every
  dock drag, on every widgetset whose drag-image resolution is registered. }

uses
  Interfaces, Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, LCLIntf;

type
  TImageDockObject = class(TDragDockObject)
  private
    FImages: TDragImageList;
  public
    function GetDragImages: TDragImageList; override;
    property Images: TDragImageList read FImages write FImages;
  end;

  TDockDragValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FDockImages: TDragImageList;
    FSourceWithImages: TPanel;
    FSourcePlain: TPanel;
    FStartDockCount: Integer;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AutoTimer(Sender: TObject);
    procedure Log(const S: string);
    procedure SourceStartDock(Sender: TObject; var DragObject: TDragDockObject);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  DockDragValidationForm: TDockDragValidationForm;

function TImageDockObject.GetDragImages: TDragImageList;
begin
  Result := FImages;
end;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('DOCKDRAG_VALIDATION_AUTO') = '1';
end;

constructor TDockDragValidationForm.Create(AOwner: TComponent);
var
  Bmp: TBitmap;
begin
  inherited Create(AOwner);
  Caption := 'LCL dock drag-image validation';
  Position := poDesigned;
  SetBounds(80, 80, 480, 320);

  FDockImages := TDragImageList.Create(Self);
  FDockImages.Width := 16;
  FDockImages.Height := 16;
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(16, 16);
    Bmp.Canvas.Brush.Color := clRed;
    Bmp.Canvas.FillRect(0, 0, 16, 16);
    FDockImages.Add(Bmp, nil);
  finally
    Bmp.Free;
  end;

  FSourceWithImages := TPanel.Create(Self);
  FSourceWithImages.Parent := Self;
  FSourceWithImages.SetBounds(24, 24, 160, 60);
  FSourceWithImages.Caption := 'ImagesDock';
  FSourceWithImages.DragKind := dkDock;
  FSourceWithImages.DragMode := dmManual;
  FSourceWithImages.OnStartDock := @SourceStartDock;

  FSourcePlain := TPanel.Create(Self);
  FSourcePlain.Parent := Self;
  FSourcePlain.SetBounds(24, 100, 160, 60);
  FSourcePlain.Caption := 'PlainDock';
  FSourcePlain.DragKind := dkDock;
  FSourcePlain.DragMode := dmManual;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 400;
  FAutoTimer.OnTimer := @AutoTimer;

  Application.OnException := @AppException;
end;

procedure TDockDragValidationForm.AppException(Sender: TObject; E: Exception);
begin
  Log('APPLICATION_EXCEPTION ' + E.ClassName + ': ' + E.Message);
  Application.Terminate;
end;

procedure TDockDragValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TDockDragValidationForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
end;

procedure TDockDragValidationForm.SourceStartDock(Sender: TObject;
  var DragObject: TDragDockObject);
var
  Obj: TImageDockObject;
begin
  Inc(FStartDockCount);
  Obj := TImageDockObject.Create(TControl(Sender));
  Obj.Images := FDockImages;
  DragObject := Obj;
  Log('start-dock custom object with images');
end;

procedure TDockDragValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunChecks;
  except
    on E: Exception do
    begin
      Log('EXCEPTION ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
      Application.Terminate;
    end;
  end;
end;

procedure TDockDragValidationForm.RunChecks;

  procedure Expect(const ALabel: string; AGot, AWant: Boolean);
  begin
    if AGot <> AWant then
    begin
      Log(Format('FAIL %s got=%s want=%s',
        [ALabel, BoolToStr(AGot, True), BoolToStr(AWant, True)]));
      ExitCode := 1;
    end;
  end;

begin
  { Round 1: dock drag with a custom drag-image dock object, then cancel.
    TDockPerformer.DragStarted calls FDragImageList.BeginDrag; the missing
    EndDrag in TDockPerformer.DragStop leaves Dragging=True afterwards. }
  Log(Format('round1-before dragging=%s', [BoolToStr(FDockImages.Dragging, True)]));
  FSourceWithImages.BeginDrag(True);
  Application.ProcessMessages;
  Log(Format('round1-during startdock=%d dragging=%s',
    [FStartDockCount, BoolToStr(FDockImages.Dragging, True)]));
  CancelDrag;
  Application.ProcessMessages;
  Log(Format('round1-after-cancel dragging=%s', [BoolToStr(FDockImages.Dragging, True)]));
  Expect('round1-after-cancel', FDockImages.Dragging, False);

  { Round 2: repeat — with the leak, DragStarted calls BeginDrag on an
    already-dragging list, stacking another Screen.BeginTempCursor. }
  FSourceWithImages.BeginDrag(True);
  Application.ProcessMessages;
  Log(Format('round2-during startdock=%d dragging=%s',
    [FStartDockCount, BoolToStr(FDockImages.Dragging, True)]));
  CancelDrag;
  Application.ProcessMessages;
  Log(Format('round2-after-cancel dragging=%s', [BoolToStr(FDockImages.Dragging, True)]));
  Expect('round2-after-cancel', FDockImages.Dragging, False);

  { Round 3: default dock object (GetDragImages=nil) — must stay unaffected. }
  FSourcePlain.BeginDrag(True);
  Application.ProcessMessages;
  Log('round3-plain-during ok');
  CancelDrag;
  Application.ProcessMessages;
  Log('round3-plain-after-cancel ok');

  Log('DONE');
  Application.Terminate;
end;

begin
  Application.Initialize;
  Application.CreateForm(TDockDragValidationForm, DockDragValidationForm);
  Application.Run;
end.
