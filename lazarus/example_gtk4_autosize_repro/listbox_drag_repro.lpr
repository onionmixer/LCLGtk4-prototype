program listbox_drag_repro;

{ Reproduces PagesListBox (Component Palette) drag behavior: a TListBox with
  DragMode=dmAutomatic whose OnDragDrop reorders items via Items.Move — exactly
  like TCompPaletteOptionsFrame.PagesListBoxDragDrop. Logs when DragStart /
  DragOver / DragDrop fire and dumps the item order before/after, so a plain
  click that triggers a spurious drag (data mutation) is visible. }

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, Forms, Controls, StdCtrls, LCLType;

var
  GSeq: Integer = 0;

function Seq: Integer;
begin
  Inc(GSeq); Result := GSeq;
end;

type
  TMainForm = class(TForm)
  private
    FList: TListBox;
    procedure ListDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ListDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ListStartDrag(Sender: TObject; var DragObject: TDragObject);
    procedure ListMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DumpOrder(const Ctx: string);
  public
    constructor CreateNew(AOwner: TComponent; Num: Integer = 0); override;
  end;

procedure TMainForm.DumpOrder(const Ctx: string);
var i: Integer; s: string;
begin
  s := '';
  for i := 0 to FList.Count - 1 do s := s + FList.Items[i] + ' ';
  WriteLn(Format('ORDER %-12s idx=%d : %s', [Ctx, FList.ItemIndex, s]));
  Flush(Output);
end;

procedure TMainForm.ListMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  WriteLn(Format('[%d] MOUSEDOWN x=%d y=%d itemAtPos=%d', [Seq, X, Y, FList.ItemAtPos(Point(X,Y),True)]));
  Flush(Output);
end;

procedure TMainForm.ListMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  WriteLn(Format('[%d] MOUSEUP   x=%d y=%d', [Seq, X, Y])); Flush(Output);
end;

procedure TMainForm.ListStartDrag(Sender: TObject; var DragObject: TDragObject);
begin
  WriteLn(Format('[%d] STARTDRAG', [Seq])); Flush(Output);
  DumpOrder('start-drag');
end;

procedure TMainForm.ListDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
var DestInd: Integer;
begin
  DestInd := FList.ItemAtPos(Point(X, Y), True);
  Accept := (DestInd > 0) and (Source = Sender) and (FList.ItemIndex > 0);
  WriteLn(Format('[%d] DRAGOVER x=%d y=%d destInd=%d accept=%s', [Seq, X, Y, DestInd, BoolToStr(Accept, True)]));
  Flush(Output);
end;

procedure TMainForm.ListDragDrop(Sender, Source: TObject; X, Y: Integer);
var lb: TListBox; DestInd: Integer;
begin
  lb := Sender as TListBox;
  DestInd := lb.ItemAtPos(Point(X, Y), True);
  WriteLn(Format('[%d] DRAGDROP x=%d y=%d destInd=%d itemIndex=%d', [Seq, X, Y, DestInd, lb.ItemIndex]));
  Flush(Output);
  DumpOrder('before-drop');
  if DestInd > 0 then
  begin
    if lb.ItemIndex < DestInd then Dec(DestInd);
    if (lb.ItemIndex > 0) and (lb.ItemIndex <> DestInd) then
    begin
      lb.Items.Move(lb.ItemIndex, DestInd);   { DATA MUTATION }
      lb.ItemIndex := DestInd;
      WriteLn('  >>> Items.Move performed (DATA CHANGED)'); Flush(Output);
    end;
  end;
  DumpOrder('after-drop');
end;

constructor TMainForm.CreateNew(AOwner: TComponent; Num: Integer);
var i: Integer;
begin
  inherited CreateNew(AOwner, Num);
  Caption := 'listbox drag repro';
  SetBounds(80, 80, 260, 320);

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.Align := alClient;
  FList.DragMode := dmAutomatic;
  FList.OnDragOver := @ListDragOver;
  FList.OnDragDrop := @ListDragDrop;
  FList.OnStartDrag := @ListStartDrag;
  FList.OnMouseDown := @ListMouseDown;
  FList.OnMouseUp := @ListMouseUp;

  FList.Items.BeginUpdate;
  FList.Items.Add('<All>');
  for i := 1 to 7 do FList.Items.Add('Page' + IntToStr(i));
  FList.Items.EndUpdate;
end;

var
  F: TMainForm;
  k: Integer;
begin
  Application.Initialize;
  F := TMainForm.CreateNew(Application);
  F.Show;
  Application.ProcessMessages;
  F.DumpOrder('initial');
  if GetEnvironmentVariable('SHOT') <> '' then
    for k := 0 to 150 do begin Application.ProcessMessages; Sleep(100); end;
end.
