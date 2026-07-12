unit LazSynGtk4IMM;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Messages, LMessages, LazSynIMMBase, SynEditKeyCmds,
  LazUTF8;

type

  { LazSynImeGtk4 }

  LazSynImeGtk4 = class(LazSynIme)
  private
    FIMEPreeditLen: Integer; // number of UTF-8 codepoints in current preedit
    FIMEPreeditCommitted: Boolean; // set after double-commit reorder; skip next commit
    procedure RemovePreedit;
    procedure FinalizePreedit;
    procedure InsertAndSelectPreedit(const IMStr: string);
  public
    procedure WMImeComposition(var Message: TMessage); override;
  end;

implementation

uses
  SynEdit;

{ LazSynImeGtk4 }

procedure LazSynImeGtk4.RemovePreedit;
var
  i: Integer;
begin
  if FIMEPreeditLen > 0 then
  begin
    { Cursor is at start of preedit (after ecSelLeft sequence).
      Select forward to cover the preedit text, then delete. }
    for i := 1 to FIMEPreeditLen do
      TSynEdit(FriendEdit).CommandProcessor(ecSelRight, #0, nil);
    TSynEdit(FriendEdit).CommandProcessor(ecDeleteLastChar, #0, nil);
    FIMEPreeditLen := 0;
  end;
end;

procedure LazSynImeGtk4.FinalizePreedit;
begin
  if FIMEPreeditLen > 0 then
  begin
    { Preedit is selected (cursor at left edge, selection extends right).
      ecRight collapses selection to right end — keeps text, clears selection. }
    TSynEdit(FriendEdit).CommandProcessor(ecRight, #0, nil);
    FIMEPreeditLen := 0;
  end;
end;

procedure LazSynImeGtk4.InsertAndSelectPreedit(const IMStr: string);
var
  i, CodepointCount: Integer;
begin
  CodepointCount := UTF8Length(IMStr);
  if CodepointCount > 0 then
  begin
    for i := 1 to CodepointCount do
      TSynEdit(FriendEdit).CommandProcessor(ecChar, UTF8Copy(IMStr, i, 1), nil);
    { Select the preedit text backwards for visual feedback }
    for i := 1 to CodepointCount do
      TSynEdit(FriendEdit).CommandProcessor(ecSelLeft, #0, nil);
    FIMEPreeditLen := CodepointCount;
  end;
end;

procedure LazSynImeGtk4.WMImeComposition(var Message: TMessage);
var
  IMStr: string;
  i, CodepointCount: Integer;
begin
  if FriendEdit.ReadOnly then exit;
  Message.Result := 1; // Mark as handled

  { START: composition beginning }
  if (Message.WParam and GTK_IM_FLAG_START) <> 0 then
  begin
    FIMEPreeditLen := 0;
    FIMEPreeditCommitted := False;
    FInCompose := True;
    DoIMEStarted;
    exit;
  end;

  { END: composition finished. Safety: remove any leftover preedit text
    (normally preedit-changed("") precedes END, but guard against edge cases). }
  if (Message.WParam and GTK_IM_FLAG_END) <> 0 then
  begin
    RemovePreedit;
    FIMEPreeditCommitted := False;
    FInCompose := False;
    DoIMEEnded;
    exit;
  end;

  { COMMIT: final composed text replaces the preedit selection. }
  if (Message.WParam and GTK_IM_FLAG_COMMIT) <> 0 then
  begin
    { Skip trailing echo from a double-commit sequence (see ASCII path below) }
    if FIMEPreeditCommitted then
    begin
      FIMEPreeditCommitted := False;
      exit;
    end;

    if Message.LParam <> 0 then
      IMStr := PChar(Message.LParam)
    else
      IMStr := '';

    CodepointCount := UTF8Length(IMStr);

    { fcitx5 double-commit reorder:
      When a non-composable key (Space, punctuation, digit) is pressed during
      Korean composition, fcitx5 sends two commits in reverse order:
        1) Commit(ASCII char)   — the non-composable key
        2) Commit(preedit text) — the finalized Korean syllable
      We detect this pattern (active preedit + ASCII commit) and reorder:
      finalize preedit in-place, insert ASCII after it, skip the second commit. }
    if (FIMEPreeditLen > 0) and (Length(IMStr) > 0) and (Ord(IMStr[1]) < 128) then
    begin
      FinalizePreedit;
      for i := 1 to CodepointCount do
        TSynEdit(FriendEdit).CommandProcessor(ecChar, UTF8Copy(IMStr, i, 1), nil);
      FIMEPreeditCommitted := True;
      exit;
    end;

    { Normal commit: remove preedit and insert committed text }
    RemovePreedit;
    for i := 1 to CodepointCount do
      TSynEdit(FriendEdit).CommandProcessor(ecChar, UTF8Copy(IMStr, i, 1), nil);
    exit;
  end;

  { PREEDIT: intermediate composition text (e.g. ㅎ → 하 → 한) }
  if (Message.WParam and GTK_IM_FLAG_PREEDIT) <> 0 then
  begin
    { Safety: if a new preedit arrives, any pending double-commit skip is stale }
    FIMEPreeditCommitted := False;
    if Message.LParam <> 0 then
      IMStr := PChar(Message.LParam)
    else
      IMStr := '';

    { Remove previous preedit if REPLACE flag is set }
    if (Message.WParam and GTK_IM_FLAG_REPLACE) <> 0 then
      RemovePreedit;

    { Insert and select new preedit text }
    if Length(IMStr) > 0 then
      InsertAndSelectPreedit(IMStr);
    exit;
  end;
end;

end.
