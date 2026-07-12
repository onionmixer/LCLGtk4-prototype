program wsdialogs_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  Graphics, LazGtk4, LazGtk4_Compat, LazGObject2, LazGLib2, LazGio2, Gtk4Widgets;

type
  TNativeProbeStimulus = (
    npsEscape,
    npsCancelMnemonic,
    npsWindowClose,
    npsAcceptReturn,
    npsAcceptMnemonic,
    npsAcceptReturnThenEscape,
    npsClickAccept,
    npsClickCancel
  );

  PNativeResponseProbeState = ^TNativeResponseProbeState;
  TNativeResponseProbeState = record
    LabelText: string;
    Done: Boolean;
    ResponseId: TGtkResponseType;
  end;

  TWSDialogsValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FEscapeTimer: TTimer;
    FCloseTimer: TTimer;
    FFontPreviewTimer: TTimer;
    FFontPreviewDialog: TFontDialog;
    FLog: TMemo;
    FStep: Integer;
    FEscapeCount: Integer;
    FQueuedStimulus: TNativeProbeStimulus;
    FQueuedWindowTitle: string;
    FQueuedAcceptKey: string;
    FCanCloseCount: Integer;
    FCanCloseLabel: string;
    FCanCloseAllow: Boolean;
    FCanCloseDenyCount: Integer;
    procedure AppException(Sender: TObject; E: Exception);
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure DialogCanClose(Sender: TObject; var CanClose: Boolean);
    procedure EscapeTimer(Sender: TObject);
    procedure Log(const S: string);
    procedure PrepareCanCloseProbe(const ALabel: string; AAllow: Boolean);
    procedure QueueEscape;
    procedure QueueFontPreviewProbe(AFontDialog: TFontDialog);
    procedure FontPreviewTimer(Sender: TObject);
    procedure QueueStimulus(AStimulus: TNativeProbeStimulus;
      const AWindowTitle: string = ''; const AAcceptKey: string = '');
    procedure RunCanCloseVetoProbe;
    procedure RunDialogSequence;
    procedure RunFileCanCloseVetoProbe;
    procedure RunLCLAcceptProbe;
    function RunNativeChooserProbe(const ALabel: string;
      AAction: TGtkFileChooserAction; const AAcceptLabel: string;
      AStimulus: TNativeProbeStimulus): Integer;
    procedure RunNativeResponseProbe;
    procedure RunStep;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  WSDialogsValidationForm: TWSDialogsValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_VALIDATION_AUTO') = '1';
end;

function NativeResponseProbeMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_NATIVE_RESPONSE_PROBE') = '1';
end;

function NativeWindowCloseProbeMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_NATIVE_WINDOW_CLOSE_PROBE') = '1';
end;

function CanCloseVetoProbeMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_CANCLOSE_VETO_PROBE') = '1';
end;

function LCLAcceptProbeMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_LCL_ACCEPT_PROBE') = '1';
end;

function FileCanCloseVetoProbeMode: Boolean;
begin
  Result := GetEnvironmentVariable('WSDIALOGS_FILE_CANCLOSE_VETO_PROBE') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('WSDIALOGS_VALIDATION_CLOSE_MS'), 0);
end;

function BoolName(AValue: Boolean): string;
begin
  Result := BoolToStr(AValue, True);
end;

function ResponseName(AValue: TGtkResponseType): string;
begin
  case AValue of
    GTK_RESPONSE_HELP: Result := 'GTK_RESPONSE_HELP';
    GTK_RESPONSE_APPLY: Result := 'GTK_RESPONSE_APPLY';
    GTK_RESPONSE_NO: Result := 'GTK_RESPONSE_NO';
    GTK_RESPONSE_YES: Result := 'GTK_RESPONSE_YES';
    GTK_RESPONSE_CLOSE: Result := 'GTK_RESPONSE_CLOSE';
    GTK_RESPONSE_CANCEL: Result := 'GTK_RESPONSE_CANCEL';
    GTK_RESPONSE_OK: Result := 'GTK_RESPONSE_OK';
    GTK_RESPONSE_DELETE_EVENT: Result := 'GTK_RESPONSE_DELETE_EVENT';
    GTK_RESPONSE_ACCEPT: Result := 'GTK_RESPONSE_ACCEPT';
    GTK_RESPONSE_REJECT: Result := 'GTK_RESPONSE_REJECT';
    GTK_RESPONSE_NONE: Result := 'GTK_RESPONSE_NONE';
  else
    Result := 'GTK_RESPONSE_UNKNOWN';
  end;
end;

function StimulusName(AValue: TNativeProbeStimulus): string;
begin
  case AValue of
    npsEscape: Result := 'escape';
    npsCancelMnemonic: Result := 'cancel-mnemonic';
    npsWindowClose: Result := 'window-close';
    npsAcceptReturn: Result := 'accept-return';
    npsAcceptMnemonic: Result := 'accept-mnemonic';
    npsAcceptReturnThenEscape: Result := 'accept-return-then-escape';
    npsClickAccept: Result := 'click-accept';
    npsClickCancel: Result := 'click-cancel';
  else
    Result := 'unknown';
  end;
end;

function FontStyleText(AStyle: TFontStyles): string;
begin
  Result := '';
  if fsBold in AStyle then
    Result := Result + 'bold,';
  if fsItalic in AStyle then
    Result := Result + 'italic,';
  if fsUnderline in AStyle then
    Result := Result + 'underline,';
  if fsStrikeOut in AStyle then
    Result := Result + 'strikeout,';
  if Result = '' then
    Result := 'none'
  else
    Delete(Result, Length(Result), 1);
end;

procedure NativeResponseProbeCB({%H-}dialog: PGtkNativeDialog;
  AResponseId: TGtkResponseType; AData: gpointer); cdecl;
var
  State: PNativeResponseProbeState;
begin
  State := PNativeResponseProbeState(AData);
  State^.ResponseId := AResponseId;
  State^.Done := True;
  WriteLn('native-response-callback label=' + State^.LabelText +
    ' response=' + IntToStr(Ord(AResponseId)) + ' name=' +
    ResponseName(AResponseId));
  Flush(Output);
end;

constructor TWSDialogsValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 WSDialogs validation';
  Position := poDesigned;
  SetBounds(160, 160, 680, 460);

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 24, 620, 360);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 500;
  FAutoTimer.OnTimer := @AutoTimer;

  FEscapeTimer := TTimer.Create(Self);
  FEscapeTimer.Enabled := False;
  FEscapeTimer.Interval := 900;
  FEscapeTimer.OnTimer := @EscapeTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;

  FFontPreviewTimer := TTimer.Create(Self);
  FFontPreviewTimer.Enabled := False;
  FFontPreviewTimer.Interval := 400;
  FFontPreviewTimer.OnTimer := @FontPreviewTimer;

  Application.OnException := @AppException;
  if AutoMode then
    FAutoTimer.Enabled := True;
end;

procedure TWSDialogsValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolName(AutoMode));
  if (not AutoMode) and (CloseInterval > 0) then
    FCloseTimer.Enabled := True;
end;

procedure TWSDialogsValidationForm.Log(const S: string);
begin
  WriteLn(S);
  Flush(Output);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TWSDialogsValidationForm.PrepareCanCloseProbe(const ALabel: string;
  AAllow: Boolean);
begin
  FCanCloseLabel := ALabel;
  FCanCloseCount := 0;
  FCanCloseAllow := AAllow;
  FCanCloseDenyCount := 0;
end;

procedure TWSDialogsValidationForm.DialogCanClose(Sender: TObject;
  var CanClose: Boolean);
begin
  Inc(FCanCloseCount);
  if FCanCloseCount <= FCanCloseDenyCount then
    CanClose := False
  else
    CanClose := FCanCloseAllow;
  Log('canclose label=' + FCanCloseLabel + ' sender=' +
    Sender.ClassName + ' count=' + IntToStr(FCanCloseCount) +
    ' allow=' + BoolName(CanClose));
end;

procedure TWSDialogsValidationForm.QueueEscape;
begin
  QueueStimulus(npsEscape);
end;

procedure TWSDialogsValidationForm.QueueFontPreviewProbe(AFontDialog: TFontDialog);
begin
  { The font dialog is modal; read its native preview text back from a timer
    that fires while Execute pumps messages, BEFORE the escape closes it. }
  FFontPreviewDialog := AFontDialog;
  FFontPreviewTimer.Enabled := False;
  FFontPreviewTimer.Interval := 400;
  FFontPreviewTimer.Enabled := True;
end;

procedure TWSDialogsValidationForm.FontPreviewTimer(Sender: TObject);
var
  Dlg: TGtk4Widget;
  NativePreview: PGChar;
  GotText: string;
begin
  FFontPreviewTimer.Enabled := False;
  if (FFontPreviewDialog = nil) or not FFontPreviewDialog.HandleAllocated then
  begin
    Log('font-preview-probe no-handle');
    Exit;
  end;
  Dlg := TGtk4Widget(FFontPreviewDialog.Handle);
  if Dlg.Widget = nil then
  begin
    Log('font-preview-probe nil-widget');
    Exit;
  end;
  { gtk_font_chooser_get_preview_text returns transfer-full — copy then free. }
  NativePreview := gtk_font_chooser_get_preview_text(PGtkFontChooser(Dlg.Widget));
  if NativePreview <> nil then
  begin
    GotText := NativePreview;
    g_free(NativePreview);
  end
  else
    GotText := '<nil>';
  Log('font-preview-probe lcl="' + FFontPreviewDialog.PreviewText +
    '" native="' + GotText + '" match=' +
    BoolName(GotText = FFontPreviewDialog.PreviewText));
end;

procedure TWSDialogsValidationForm.QueueStimulus(AStimulus: TNativeProbeStimulus;
  const AWindowTitle: string; const AAcceptKey: string);
begin
  FEscapeTimer.Enabled := False;
  FEscapeCount := 0;
  FQueuedStimulus := AStimulus;
  FQueuedWindowTitle := AWindowTitle;
  FQueuedAcceptKey := AAcceptKey;
  FEscapeTimer.Enabled := True;
end;

procedure TWSDialogsValidationForm.EscapeTimer(Sender: TObject);
begin
  Inc(FEscapeCount);
  try
    case FQueuedStimulus of
      npsEscape:
        begin
          if FQueuedWindowTitle = '' then
            ExecuteProcess('/usr/bin/xdotool', ['key', 'Escape'])
          else
            ExecuteProcess('/usr/bin/xdotool',
              ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
              'Escape']);
          Log('escape-sent count=' + IntToStr(FEscapeCount));
        end;
      npsCancelMnemonic:
        begin
          if FQueuedWindowTitle = '' then
            ExecuteProcess('/usr/bin/xdotool', ['key', 'alt+c'])
          else
            ExecuteProcess('/usr/bin/xdotool',
              ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
              'alt+c']);
          Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
            ' count=' + IntToStr(FEscapeCount));
        end;
      npsWindowClose:
        begin
          if FQueuedWindowTitle = '' then
            ExecuteProcess('/usr/bin/xdotool', ['getactivewindow', 'windowclose'])
          else
            ExecuteProcess('/usr/bin/xdotool',
              ['search', '--name', FQueuedWindowTitle, 'windowclose']);
          Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
            ' count=' + IntToStr(FEscapeCount));
        end;
      npsAcceptReturn:
        begin
          if FQueuedWindowTitle = '' then
            ExecuteProcess('/usr/bin/xdotool', ['key', 'Return'])
          else
            ExecuteProcess('/usr/bin/xdotool',
              ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
              'Return']);
          Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
            ' count=' + IntToStr(FEscapeCount));
        end;
      npsAcceptMnemonic:
        begin
          if FQueuedAcceptKey = '' then
            FQueuedAcceptKey := 'alt+o';
          if FQueuedWindowTitle = '' then
            ExecuteProcess('/usr/bin/xdotool', ['key', FQueuedAcceptKey])
          else
            ExecuteProcess('/usr/bin/xdotool',
              ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
              FQueuedAcceptKey]);
          Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
            ' key=' + FQueuedAcceptKey + ' count=' + IntToStr(FEscapeCount));
        end;
      npsAcceptReturnThenEscape:
        begin
          if FEscapeCount <= 3 then
          begin
            if FQueuedWindowTitle = '' then
              ExecuteProcess('/usr/bin/xdotool', ['key', 'Return'])
            else
              ExecuteProcess('/usr/bin/xdotool',
                ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
                'Return']);
            Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
              ' key=Return count=' + IntToStr(FEscapeCount));
          end
          else
          begin
            if FQueuedWindowTitle = '' then
              ExecuteProcess('/usr/bin/xdotool', ['key', 'Escape'])
            else
              ExecuteProcess('/usr/bin/xdotool',
                ['search', '--name', FQueuedWindowTitle, 'windowfocus', 'key',
                'Escape']);
            Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
              ' key=Escape count=' + IntToStr(FEscapeCount));
          end;
        end;
      npsClickAccept, npsClickCancel:
        begin
          if FQueuedWindowTitle = '' then
            raise Exception.Create('window title required for click stimulus');
          if FQueuedStimulus = npsClickAccept then
            ExecuteProcess('/bin/sh',
              ['-c',
              'title="$1"; w=$(xdotool search --name "$title" | tail -n 1); ' +
              '[ -n "$w" ] || exit 2; eval "$(xdotool getwindowgeometry --shell "$w")"; ' +
              'xdotool windowfocus "$w"; xdotool mousemove --window "$w" "$((WIDTH - 70))" "$((HEIGHT - 35))"; xdotool click --window "$w" 1',
              'click-window', FQueuedWindowTitle])
          else
            ExecuteProcess('/bin/sh',
              ['-c',
              'title="$1"; w=$(xdotool search --name "$title" | tail -n 1); ' +
              '[ -n "$w" ] || exit 2; eval "$(xdotool getwindowgeometry --shell "$w")"; ' +
              'xdotool windowfocus "$w"; xdotool mousemove --window "$w" "$((WIDTH - 165))" "$((HEIGHT - 35))"; xdotool click --window "$w" 1',
              'click-window', FQueuedWindowTitle]);
          Log('stimulus-sent kind=' + StimulusName(FQueuedStimulus) +
            ' count=' + IntToStr(FEscapeCount));
        end;
    end;
  except
    on E: Exception do
      Log('stimulus-send-error kind=' + StimulusName(FQueuedStimulus) + ' ' +
        E.ClassName + ' ' + E.Message);
  end;
  if FEscapeCount >= 6 then
    FEscapeTimer.Enabled := False;
end;

procedure TWSDialogsValidationForm.RunDialogSequence;
var
  OpenDialog: TOpenDialog;
  SaveDialog: TSaveDialog;
  SelectDialog: TSelectDirectoryDialog;
  ColorDialog: TColorDialog;
  FontDialog: TFontDialog;
  TaskDialog: TTaskDialog;
  TaskResult: Boolean;
begin
  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Title := 'GTK4 open cancel validation';
    OpenDialog.InitialDir := GetCurrentDir;
    OpenDialog.Filter := 'Pascal files|*.pas;*.pp|All files|*';
    OpenDialog.FilterIndex := 1;
    OpenDialog.Options := OpenDialog.Options + [ofAllowMultiSelect];
    OpenDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('open-escape', True);
    QueueEscape;
    Log('open-before');
    Log('open-result=' + BoolName(OpenDialog.Execute) + ' filename="' +
      OpenDialog.FileName + '" files=' + IntToStr(OpenDialog.Files.Count) +
      ' filterindex=' + IntToStr(OpenDialog.FilterIndex) +
      ' canclose-count=' + IntToStr(FCanCloseCount));
  finally
    OpenDialog.Free;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'GTK4 save cancel validation';
    SaveDialog.InitialDir := GetCurrentDir;
    SaveDialog.FileName := 'wsdialogs_validation_output.txt';
    SaveDialog.Filter := 'Text files|*.txt|All files|*';
    SaveDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('save-escape', True);
    QueueEscape;
    Log('save-before');
    Log('save-result=' + BoolName(SaveDialog.Execute) + ' filename="' +
      SaveDialog.FileName + '" filterindex=' + IntToStr(SaveDialog.FilterIndex) +
      ' canclose-count=' + IntToStr(FCanCloseCount));
  finally
    SaveDialog.Free;
  end;

  SelectDialog := TSelectDirectoryDialog.Create(Self);
  try
    SelectDialog.Title := 'GTK4 select directory cancel validation';
    SelectDialog.InitialDir := GetCurrentDir;
    SelectDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('selectdir-escape', True);
    QueueEscape;
    Log('selectdir-before');
    Log('selectdir-result=' + BoolName(SelectDialog.Execute) + ' filename="' +
      SelectDialog.FileName + '" canclose-count=' + IntToStr(FCanCloseCount));
  finally
    SelectDialog.Free;
  end;

    ColorDialog := TColorDialog.Create(Self);
  try
    ColorDialog.Title := 'GTK4 color cancel validation';
    ColorDialog.Color := clRed;
    ColorDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('color-escape', True);
    QueueEscape;
    Log('color-before');
    Log('color-result=' + BoolName(ColorDialog.Execute) + ' color=' +
      IntToStr(ColorDialog.Color) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    ColorDialog.Free;
  end;

  FontDialog := TFontDialog.Create(Self);
  try
    FontDialog.Title := 'GTK4 font cancel validation';
    FontDialog.Font.Name := 'Sans';
    FontDialog.Font.Size := 12;
    FontDialog.Font.Style := [fsBold, fsUnderline];
    { PreviewText parity probe: the custom sample must appear in the
      GtkFontChooser preview entry (screenshot-verified). }
    FontDialog.PreviewText := 'LCL Preview 0123';
    FontDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('font-escape', True);
    QueueEscape;
    QueueFontPreviewProbe(FontDialog);
    Log('font-before');
    Log('font-result=' + BoolName(FontDialog.Execute) + ' font="' +
      FontDialog.Font.Name + '" size=' + IntToStr(FontDialog.Font.Size) +
      ' style=' + FontStyleText(FontDialog.Font.Style) +
      ' canclose-count=' + IntToStr(FCanCloseCount));
  finally
    FontDialog.Free;
  end;

  TaskDialog := TTaskDialog.Create(Self);
  try
    TaskDialog.Title := 'GTK4 task cancel validation';
    TaskDialog.Caption := 'Task dialog';
    TaskDialog.Text := 'Escape should close this dialog.';
    TaskDialog.CommonButtons := [tcbOk, tcbCancel];
    QueueEscape;
    Log('task-before');
    TaskResult := TaskDialog.Execute(Handle);
    Log('task-result=' + BoolName(TaskResult) + ' modalresult=' +
      IntToStr(TaskDialog.ModalResult));
  finally
    TaskDialog.Free;
  end;

  FEscapeTimer.Enabled := False;
end;

procedure TWSDialogsValidationForm.RunLCLAcceptProbe;
var
  OpenDialog: TOpenDialog;
  SaveDialog: TSaveDialog;
  SelectDialog: TSelectDirectoryDialog;
  ExistingName: string;
  ExistingFile: TStringList;
begin
  Log('lcl-accept-probe-start');

  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Title := 'GTK4 LCL open accept validation';
    OpenDialog.InitialDir := ExpandFileName('example_gtk4_wsdialogs_validation');
    OpenDialog.FileName := ExpandFileName('example_gtk4_wsdialogs_validation/wsdialogs_validation.lpr');
    OpenDialog.Filter := 'Pascal files|*.pas;*.pp;*.lpr|All files|*';
    OpenDialog.FilterIndex := 1;
    OpenDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('lcl-open-accept-return', True);
    QueueStimulus(npsAcceptReturnThenEscape, OpenDialog.Title);
    Log('lcl-open-accept-before');
    Log('lcl-open-accept-result=' + BoolName(OpenDialog.Execute) +
      ' filename="' + OpenDialog.FileName + '" files=' +
      IntToStr(OpenDialog.Files.Count) + ' filterindex=' +
      IntToStr(OpenDialog.FilterIndex) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    OpenDialog.Free;
  end;

  OpenDialog := TOpenDialog.Create(Self);
  try
    OpenDialog.Title := 'GTK4 LCL open multiselect accept validation';
    OpenDialog.InitialDir := ExpandFileName('example_gtk4_wsdialogs_validation');
    OpenDialog.FileName := ExpandFileName('example_gtk4_wsdialogs_validation/wsdialogs_validation.lpr');
    OpenDialog.Filter := 'Pascal files|*.pas;*.pp;*.lpr|All files|*';
    OpenDialog.FilterIndex := 1;
    OpenDialog.Options := OpenDialog.Options + [ofAllowMultiSelect];
    OpenDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('lcl-open-multiselect-accept-return', True);
    QueueStimulus(npsAcceptReturnThenEscape, OpenDialog.Title);
    Log('lcl-open-multiselect-accept-before');
    Log('lcl-open-multiselect-accept-result=' + BoolName(OpenDialog.Execute) +
      ' filename="' + OpenDialog.FileName + '" files=' +
      IntToStr(OpenDialog.Files.Count) + ' filterindex=' +
      IntToStr(OpenDialog.FilterIndex) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    OpenDialog.Free;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'GTK4 LCL save accept validation';
    SaveDialog.InitialDir := GetCurrentDir;
    SaveDialog.FileName := 'wsdialogs_lcl_accept_probe.txt';
    SaveDialog.Filter := 'Text files|*.txt|All files|*';
    SaveDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('lcl-save-accept-return', True);
    QueueStimulus(npsAcceptReturnThenEscape, SaveDialog.Title);
    Log('lcl-save-accept-before');
    Log('lcl-save-accept-result=' + BoolName(SaveDialog.Execute) +
      ' filename="' + SaveDialog.FileName + '" filterindex=' +
      IntToStr(SaveDialog.FilterIndex) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    SaveDialog.Free;
  end;

  ExistingName := ExpandFileName('wsdialogs_existing_overwrite_probe.txt');
  ExistingFile := TStringList.Create;
  try
    ExistingFile.Text := 'existing overwrite probe';
    ExistingFile.SaveToFile(ExistingName);
  finally
    ExistingFile.Free;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'GTK4 LCL save overwrite accept validation';
    SaveDialog.InitialDir := GetCurrentDir;
    SaveDialog.FileName := ExtractFileName(ExistingName);
    SaveDialog.Filter := 'Text files|*.txt|All files|*';
    SaveDialog.Options := SaveDialog.Options + [ofOverwritePrompt];
    SaveDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('lcl-save-overwrite-accept-return', True);
    QueueStimulus(npsAcceptReturnThenEscape, SaveDialog.Title);
    Log('lcl-save-overwrite-before exists=' + BoolName(FileExists(ExistingName)));
    Log('lcl-save-overwrite-result=' + BoolName(SaveDialog.Execute) +
      ' filename="' + SaveDialog.FileName + '" filterindex=' +
      IntToStr(SaveDialog.FilterIndex) + ' canclose-count=' +
      IntToStr(FCanCloseCount) + ' exists-after=' +
      BoolName(FileExists(ExistingName)));
  finally
    SaveDialog.Free;
    DeleteFile(ExistingName);
  end;

  SelectDialog := TSelectDirectoryDialog.Create(Self);
  try
    SelectDialog.Title := 'GTK4 LCL selectdir accept validation';
    SelectDialog.InitialDir := GetCurrentDir;
    SelectDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('lcl-selectdir-accept-return', True);
    QueueStimulus(npsAcceptReturnThenEscape, SelectDialog.Title);
    Log('lcl-selectdir-accept-before');
    Log('lcl-selectdir-accept-result=' + BoolName(SelectDialog.Execute) +
      ' filename="' + SelectDialog.FileName + '" canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    SelectDialog.Free;
  end;

  FEscapeTimer.Enabled := False;
  Log('lcl-accept-probe-end');
end;

procedure TWSDialogsValidationForm.RunFileCanCloseVetoProbe;
var
  SaveDialog: TSaveDialog;
begin
  Log('file-canclose-veto-probe-start');

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'GTK4 file canclose veto validation';
    SaveDialog.InitialDir := GetCurrentDir;
    SaveDialog.FileName := 'wsdialogs_file_veto_probe.txt';
    SaveDialog.Filter := 'Text files|*.txt|All files|*';
    SaveDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('file-save-veto-first-accept', True);
    FCanCloseDenyCount := 1;
    QueueStimulus(npsAcceptReturnThenEscape, SaveDialog.Title);
    Log('file-save-veto-before');
    Log('file-save-veto-result=' + BoolName(SaveDialog.Execute) +
      ' filename="' + SaveDialog.FileName + '" filterindex=' +
      IntToStr(SaveDialog.FilterIndex) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    SaveDialog.Free;
  end;

  FEscapeTimer.Enabled := False;
  Log('file-canclose-veto-probe-end');
end;

procedure TWSDialogsValidationForm.RunCanCloseVetoProbe;
var
  ColorDialog: TColorDialog;
  FontDialog: TFontDialog;
begin
  Log('canclose-veto-probe-start');

  ColorDialog := TColorDialog.Create(Self);
  try
    ColorDialog.Title := 'GTK4 color canclose veto validation';
    ColorDialog.Color := clBlue;
    ColorDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('color-veto-first-escape', True);
    FCanCloseDenyCount := 1;
    QueueEscape;
    Log('color-veto-before');
    Log('color-veto-result=' + BoolName(ColorDialog.Execute) + ' color=' +
      IntToStr(ColorDialog.Color) + ' canclose-count=' +
      IntToStr(FCanCloseCount));
  finally
    ColorDialog.Free;
  end;

  FontDialog := TFontDialog.Create(Self);
  try
    FontDialog.Title := 'GTK4 font canclose veto validation';
    FontDialog.Font.Name := 'Sans';
    FontDialog.Font.Size := 12;
    FontDialog.OnCanClose := @DialogCanClose;
    PrepareCanCloseProbe('font-veto-first-escape', True);
    FCanCloseDenyCount := 1;
    QueueEscape;
    Log('font-veto-before');
    Log('font-veto-result=' + BoolName(FontDialog.Execute) + ' font="' +
      FontDialog.Font.Name + '" size=' + IntToStr(FontDialog.Font.Size) +
      ' canclose-count=' + IntToStr(FCanCloseCount));
  finally
    FontDialog.Free;
  end;

  FEscapeTimer.Enabled := False;
  Log('canclose-veto-probe-end');
end;

function TWSDialogsValidationForm.RunNativeChooserProbe(const ALabel: string;
  AAction: TGtkFileChooserAction; const AAcceptLabel: string;
  AStimulus: TNativeProbeStimulus): Integer;
var
  Native: PGtkFileChooserNative;
  Folder: PGFile;
  SelectedFile: PGFile;
  State: TNativeResponseProbeState;
  I: Integer;
  SelectedPath: string;
  DialogTitle: string;
  AcceptKey: string;
begin
  State.LabelText := ALabel;
  State.Done := False;
  State.ResponseId := GTK_RESPONSE_NONE;
  DialogTitle := 'native response probe ' + ALabel;

  Native := gtk_file_chooser_native_new(PgChar(DialogTitle), nil, AAction,
    PgChar(AAcceptLabel), PgChar('Cancel'));
  if Native = nil then
  begin
    Log('native-' + ALabel + '-create-failed');
    Exit(Ord(GTK_RESPONSE_NONE));
  end;

  try
    Folder := g_file_new_for_path(PgChar(GetCurrentDir));
    if Folder <> nil then
    begin
      gtk4_file_chooser_set_current_folder(PGtkFileChooser(Native), Folder, nil);
      g_object_unref(PGObject(Folder));
    end;

    if AAction = GTK_FILE_CHOOSER_ACTION_SAVE then
      gtk_file_chooser_set_current_name(PGtkFileChooser(Native),
        PgChar('wsdialogs_native_response_probe.txt'));

    if AStimulus = npsAcceptReturn then
    begin
      SelectedFile := nil;
      if AAction = GTK_FILE_CHOOSER_ACTION_OPEN then
      begin
        SelectedPath := ExpandFileName('example_gtk4_wsdialogs_validation/wsdialogs_validation.lpr');
        SelectedFile := g_file_new_for_path(PgChar(SelectedPath));
      end
      else if AAction = GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER then
      begin
        SelectedPath := GetCurrentDir;
        SelectedFile := g_file_new_for_path(PgChar(SelectedPath));
      end
      else
        SelectedPath := 'wsdialogs_native_response_probe.txt';

      if SelectedFile <> nil then
      begin
        Log('native-' + ALabel + '-set-file path="' + SelectedPath +
          '" result=' + BoolName(gtk4_file_chooser_set_file(
          PGtkFileChooser(Native), SelectedFile, nil)));
        g_object_unref(PGObject(SelectedFile));
      end;
    end;

    g_signal_connect_data(PGObject(Native), 'response',
      TGCallback(@NativeResponseProbeCB), @State, nil, G_CONNECT_DEFAULT);

    Log('native-' + ALabel + '-before action=' + IntToStr(Ord(AAction)) +
      ' stimulus=' + StimulusName(AStimulus));
    if SameText(AAcceptLabel, 'Save') then
      AcceptKey := 'alt+s'
    else
      AcceptKey := 'alt+o';
    QueueStimulus(AStimulus, DialogTitle, AcceptKey);
    gtk_native_dialog_set_modal(PGtkNativeDialog(Native), True);
    gtk_native_dialog_show(PGtkNativeDialog(Native));

    I := 0;
    while (not State.Done) and (I < 240) do
    begin
      Application.ProcessMessages;
      Sleep(25);
      Inc(I);
    end;

    FEscapeTimer.Enabled := False;
    Log('native-' + ALabel + '-after done=' + BoolName(State.Done) +
      ' response=' + IntToStr(Ord(State.ResponseId)) + ' name=' +
      ResponseName(State.ResponseId));
    Result := Ord(State.ResponseId);
  finally
    gtk_native_dialog_destroy(PGtkNativeDialog(Native));
    g_object_unref(PGObject(Native));
  end;
end;

procedure TWSDialogsValidationForm.RunNativeResponseProbe;
begin
  Log('native-probe-start');
  RunNativeChooserProbe('open-escape', GTK_FILE_CHOOSER_ACTION_OPEN, 'Open',
    npsEscape);
  RunNativeChooserProbe('save-escape', GTK_FILE_CHOOSER_ACTION_SAVE, 'Save',
    npsEscape);
  RunNativeChooserProbe('select-folder-escape',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsEscape);
  RunNativeChooserProbe('open-cancel-mnemonic', GTK_FILE_CHOOSER_ACTION_OPEN,
    'Open', npsCancelMnemonic);
  RunNativeChooserProbe('save-cancel-mnemonic', GTK_FILE_CHOOSER_ACTION_SAVE,
    'Save', npsCancelMnemonic);
  RunNativeChooserProbe('select-folder-cancel-mnemonic',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsCancelMnemonic);
  if NativeWindowCloseProbeMode then
  begin
    RunNativeChooserProbe('open-window-close', GTK_FILE_CHOOSER_ACTION_OPEN,
      'Open', npsWindowClose);
    RunNativeChooserProbe('save-window-close', GTK_FILE_CHOOSER_ACTION_SAVE,
      'Save', npsWindowClose);
    RunNativeChooserProbe('select-folder-window-close',
      GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsWindowClose);
  end
  else
    Log('native-window-close-probe-skipped reason=requires-explicit-env');
  RunNativeChooserProbe('open-accept-return', GTK_FILE_CHOOSER_ACTION_OPEN,
    'Open', npsAcceptReturn);
  RunNativeChooserProbe('save-accept-return', GTK_FILE_CHOOSER_ACTION_SAVE,
    'Save', npsAcceptReturn);
  RunNativeChooserProbe('select-folder-accept-return',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsAcceptReturn);
  RunNativeChooserProbe('open-accept-mnemonic', GTK_FILE_CHOOSER_ACTION_OPEN,
    'Open', npsAcceptMnemonic);
  RunNativeChooserProbe('save-accept-mnemonic', GTK_FILE_CHOOSER_ACTION_SAVE,
    'Save', npsAcceptMnemonic);
  RunNativeChooserProbe('select-folder-accept-mnemonic',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsAcceptMnemonic);
  RunNativeChooserProbe('open-click-accept', GTK_FILE_CHOOSER_ACTION_OPEN,
    'Open', npsClickAccept);
  RunNativeChooserProbe('save-click-accept', GTK_FILE_CHOOSER_ACTION_SAVE,
    'Save', npsClickAccept);
  RunNativeChooserProbe('select-folder-click-accept',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsClickAccept);
  RunNativeChooserProbe('open-click-cancel', GTK_FILE_CHOOSER_ACTION_OPEN,
    'Open', npsClickCancel);
  RunNativeChooserProbe('save-click-cancel', GTK_FILE_CHOOSER_ACTION_SAVE,
    'Save', npsClickCancel);
  RunNativeChooserProbe('select-folder-click-cancel',
    GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER, 'Open', npsClickCancel);
  Log('native-probe-end');
end;

procedure TWSDialogsValidationForm.RunStep;
begin
  case FStep of
    0:
      begin
        if NativeResponseProbeMode then
          RunNativeResponseProbe;
        RunDialogSequence;
        if LCLAcceptProbeMode then
          RunLCLAcceptProbe;
        if CanCloseVetoProbeMode then
          RunCanCloseVetoProbe;
        if FileCanCloseVetoProbeMode then
          RunFileCanCloseVetoProbe;
        Log('DONE');
      end;
  end;
  Inc(FStep);
  if AutoMode then
    Close;
end;

procedure TWSDialogsValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  RunStep;
end;

procedure TWSDialogsValidationForm.CloseTimer(Sender: TObject);
begin
  Close;
end;

procedure TWSDialogsValidationForm.AppException(Sender: TObject; E: Exception);
begin
  Log('APPLICATION_EXCEPTION ' + E.ClassName + ' ' + E.Message);
  Halt(1);
end;

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TWSDialogsValidationForm, WSDialogsValidationForm);
  Application.Run;
end.
