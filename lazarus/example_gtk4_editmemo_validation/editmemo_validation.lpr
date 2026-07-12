program editmemo_validation;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Clipbrd,
  Gtk4Widgets, LazGtk4, LazGLib2;

type
  TEditMemoValidationForm = class(TForm)
  private
    FAutoTimer: TTimer;
    FCloseTimer: TTimer;
    FLog: TMemo;
    FEdit: TEdit;
    FPassword: TEdit;
    FFiltered: TEdit;
    FMemo: TMemo;
    procedure AutoTimer(Sender: TObject);
    procedure CloseTimer(Sender: TObject);
    procedure CreateLabel(const ACaption: string; ALeft, ATop: Integer);
    function EntryPlaceholder(AEdit: TEdit): string;
    procedure Log(const S: string);
    procedure LogEdit(const AName: string; AEdit: TEdit);
    procedure LogMemo(const AName: string; AMemo: TMemo);
    procedure RunChecks;
  protected
    procedure DoShow; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  EditMemoValidationForm: TEditMemoValidationForm;

function AutoMode: Boolean;
begin
  Result := GetEnvironmentVariable('EDITMEMO_VALIDATION_AUTO') = '1';
end;

function CloseInterval: Integer;
begin
  Result := StrToIntDef(GetEnvironmentVariable('EDITMEMO_VALIDATION_CLOSE_MS'), 0);
end;

function NullableText(P: Pgchar): string;
begin
  if P = nil then
    Result := 'nil'
  else
    Result := '''' + StrPas(P) + '''';
end;

function ScrollStyleName(AStyle: TScrollStyle): string;
begin
  case AStyle of
    ssNone: Result := 'ssNone';
    ssHorizontal: Result := 'ssHorizontal';
    ssVertical: Result := 'ssVertical';
    ssBoth: Result := 'ssBoth';
    ssAutoHorizontal: Result := 'ssAutoHorizontal';
    ssAutoVertical: Result := 'ssAutoVertical';
    ssAutoBoth: Result := 'ssAutoBoth';
  else
    Result := 'unknown';
  end;
end;

function EchoModeName(AMode: TEchoMode): string;
begin
  case AMode of
    emNormal: Result := 'emNormal';
    emNone: Result := 'emNone';
    emPassword: Result := 'emPassword';
  else
    Result := 'unknown';
  end;
end;

constructor TEditMemoValidationForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Caption := 'GTK4 Edit/Memo validation';
  Position := poDesigned;
  SetBounds(100, 100, 860, 640);

  CreateLabel('Edit', 24, 24);
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.SetBounds(120, 20, 300, 28);
  FEdit.Text := 'abc';
  FEdit.TextHint := 'initial hint';

  CreateLabel('Password', 24, 64);
  FPassword := TEdit.Create(Self);
  FPassword.Parent := Self;
  FPassword.SetBounds(120, 60, 300, 28);
  FPassword.Text := 'secret';
  FPassword.EchoMode := emPassword;
  FPassword.PasswordChar := '*';

  CreateLabel('Filtered', 24, 104);
  FFiltered := TEdit.Create(Self);
  FFiltered.Parent := Self;
  FFiltered.SetBounds(120, 100, 300, 28);
  FFiltered.Text := '12';
  FFiltered.NumbersOnly := True;
  FFiltered.CharCase := ecUpperCase;
  FFiltered.MaxLength := 5;

  CreateLabel('Memo', 24, 152);
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.SetBounds(120, 148, 300, 150);
  FMemo.Text := 'line1' + LineEnding + 'line2';
  FMemo.ScrollBars := ssAutoBoth;
  FMemo.WordWrap := False;
  FMemo.WantTabs := True;

  FLog := TMemo.Create(Self);
  FLog.Parent := Self;
  FLog.SetBounds(24, 328, 790, 260);
  FLog.ScrollBars := ssAutoBoth;
  FLog.WordWrap := False;

  FAutoTimer := TTimer.Create(Self);
  FAutoTimer.Enabled := False;
  FAutoTimer.Interval := 500;
  FAutoTimer.OnTimer := @AutoTimer;

  FCloseTimer := TTimer.Create(Self);
  FCloseTimer.Enabled := False;
  FCloseTimer.Interval := CloseInterval;
  FCloseTimer.OnTimer := @CloseTimer;
end;

procedure TEditMemoValidationForm.CreateLabel(const ACaption: string;
  ALeft, ATop: Integer);
var
  L: TLabel;
begin
  L := TLabel.Create(Self);
  L.Parent := Self;
  L.Caption := ACaption;
  L.SetBounds(ALeft, ATop + 4, 88, 24);
end;

procedure TEditMemoValidationForm.DoShow;
begin
  inherited DoShow;
  Log('START auto=' + BoolToStr(AutoMode, True));
  if AutoMode then
    FAutoTimer.Enabled := True
  else if CloseInterval > 0 then
    FCloseTimer.Enabled := True;
end;

function TEditMemoValidationForm.EntryPlaceholder(AEdit: TEdit): string;
var
  GtkEntry: TGtk4Entry;
begin
  if not AEdit.HandleAllocated then
    Exit('handle=0');
  GtkEntry := TGtk4Entry(AEdit.Handle);
  Result := NullableText(PGtkEntry(GtkEntry.GetContainerWidget)^.get_placeholder_text);
end;

procedure TEditMemoValidationForm.Log(const S: string);
begin
  WriteLn(S);
  if Assigned(FLog) then
    FLog.Lines.Add(S);
end;

procedure TEditMemoValidationForm.LogEdit(const AName: string; AEdit: TEdit);
var
  GtkEntry: TGtk4Entry;
  Native: PGtkEntry;
  NativeEditable: Boolean;
  NativeVisible: Boolean;
  NativeMaxLength: Integer;
begin
  if not AEdit.HandleAllocated then
  begin
    Log(AName + ' handle=0');
    Exit;
  end;
  GtkEntry := TGtk4Entry(AEdit.Handle);
  Native := PGtkEntry(GtkEntry.GetContainerWidget);
  NativeEditable := PGtkEditable(Native)^.get_editable;
  NativeVisible := Native^.get_visibility;
  NativeMaxLength := Native^.get_max_length;
  Log(Format('%s text="%s" selstart=%d sellength=%d canundo=%s readonly=%s echomode=%s placeholder=%s native.editable=%s native.visible=%s native.maxlen=%d native.wrapperhint=%s',
    [AName, AEdit.Text, AEdit.SelStart, AEdit.SelLength,
     BoolToStr(AEdit.CanUndo, True), BoolToStr(AEdit.ReadOnly, True),
     EchoModeName(AEdit.EchoMode), EntryPlaceholder(AEdit),
     BoolToStr(NativeEditable, True), BoolToStr(NativeVisible, True),
     NativeMaxLength, GtkEntry.TextHint]));
end;

procedure TEditMemoValidationForm.LogMemo(const AName: string; AMemo: TMemo);
var
  GtkMemo: TGtk4Memo;
  Native: PGtkTextView;
begin
  if not AMemo.HandleAllocated then
  begin
    Log(AName + ' handle=0');
    Exit;
  end;
  GtkMemo := TGtk4Memo(AMemo.Handle);
  Native := PGtkTextView(GtkMemo.GetContainerWidget);
  Log(Format('%s text="%s" selstart=%d sellength=%d canundo=%s readonly=%s wordwrap=%s wanttabs=%s scrollbars=%s native.editable=%s native.wrap=%d native.accepts_tab=%s',
    [AName, StringReplace(AMemo.Text, LineEnding, '\n', [rfReplaceAll]),
     AMemo.SelStart, AMemo.SelLength, BoolToStr(AMemo.CanUndo, True),
     BoolToStr(AMemo.ReadOnly, True), BoolToStr(AMemo.WordWrap, True),
     BoolToStr(AMemo.WantTabs, True), ScrollStyleName(AMemo.ScrollBars),
     BoolToStr(Native^.get_editable, True), Ord(Native^.get_wrap_mode),
     BoolToStr(Native^.get_accepts_tab, True)]));
end;

procedure TEditMemoValidationForm.RunChecks;
begin
  Application.ProcessMessages;
  LogEdit('edit initial', FEdit);
  LogEdit('password initial', FPassword);
  LogEdit('filtered initial', FFiltered);
  LogMemo('memo initial', FMemo);

  FEdit.TextHint := 'replacement hint';
  Application.ProcessMessages;
  LogEdit('edit after hint replacement', FEdit);
  FEdit.TextHint := '';
  Application.ProcessMessages;
  LogEdit('edit after hint clear', FEdit);

  FEdit.SelStart := 1;
  FEdit.SelLength := 1;
  FEdit.SelText := 'XYZ';
  Application.ProcessMessages;
  LogEdit('edit after seltext', FEdit);
  FEdit.Undo;
  Application.ProcessMessages;
  LogEdit('edit after undo', FEdit);

  FEdit.SelectAll;
  FEdit.CopyToClipboard;
  Log('clipboard after normal copy="' + Clipboard.AsText + '"');
  FPassword.SelectAll;
  FPassword.CopyToClipboard;
  Log('clipboard after password copy="' + Clipboard.AsText + '"');

  FFiltered.SelStart := Length(FFiltered.Text);
  FFiltered.SelText := 'ab34';
  Application.ProcessMessages;
  LogEdit('filtered after seltext ab34', FFiltered);

  FMemo.SelStart := Length(FMemo.Text);
  FMemo.SelLength := 0;
  FMemo.SelText := LineEnding + 'added';
  Application.ProcessMessages;
  LogMemo('memo after seltext', FMemo);
  FMemo.Undo;
  Application.ProcessMessages;
  LogMemo('memo after undo', FMemo);
  FMemo.WordWrap := True;
  FMemo.WantTabs := False;
  FMemo.ReadOnly := True;
  Application.ProcessMessages;
  LogMemo('memo after flags', FMemo);

  Log('AUTO end');
end;

procedure TEditMemoValidationForm.AutoTimer(Sender: TObject);
begin
  FAutoTimer.Enabled := False;
  try
    RunChecks;
  except
    on E: Exception do
      Log('AUTO exception ' + E.ClassName + ': ' + E.Message);
  end;
  Close;
end;

procedure TEditMemoValidationForm.CloseTimer(Sender: TObject);
begin
  FCloseTimer.Enabled := False;
  LogEdit('close edit', FEdit);
  LogEdit('close password', FPassword);
  LogEdit('close filtered', FFiltered);
  LogMemo('close memo', FMemo);
  Close;
end;

begin
  Application.Initialize;
  Application.CreateForm(TEditMemoValidationForm, EditMemoValidationForm);
  Application.Run;
end.
