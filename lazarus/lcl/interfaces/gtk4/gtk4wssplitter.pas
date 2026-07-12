{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSSplitter;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // LCL
  LCLProc, ExtCtrls, Classes, Controls, SysUtils, Graphics, LCLType,
  // widgetset
  WSLCLClasses, WSPairSplitter,
  PairSplitter;

type

  { TGtk4WSPairSplitterSide }

  TGtk4WSPairSplitterSide = class(TWSPairSplitterSide)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSCustomPairSplitter }

  TGtk4WSCustomPairSplitter = class(TWSCustomPairSplitter)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function AddSide(ASplitter: TCustomPairSplitter; ASide: TPairSplitterSide; Side: integer): Boolean; override;
    class function RemoveSide(ASplitter: TCustomPairSplitter; ASide: TPairSplitterSide; Side: integer): Boolean; override;
    class function GetPosition(ASplitter: TCustomPairSplitter): Integer; override;
    class function SetPosition(ASplitter: TCustomPairSplitter; var NewPosition: integer): Boolean; override;
    // special cursor handling
    class function GetSplitterCursor(ASplitter: TCustomPairSplitter; var ACursor: TCursor): Boolean; override;
    class function SetSplitterCursor(ASplitter: TCustomPairSplitter; ACursor: TCursor): Boolean; override;
  end;

implementation
uses
  wsproc,gtk4widgets,lazgtk4,LazGObject2;

{ TGtk4WSPairSplitterSide }

class function TGtk4WSPairSplitterSide.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  { TGtk4SplitterSide is a plain child container (overlay + fixed + paint
    area). The former TGtk4Window wrapper hard-cast the side to TCustomForm
    and ran window-only APIs against a non-window widget — the sides never
    learned their real size and stayed 1x1. }
  Result:=TLCLHandle(TGtk4SplitterSide.Create(AWinControl, AParams));
end;

{ TGtk4WSSplitter }


{ TGtk4WSCustomPairSplitter }

class function TGtk4WSCustomPairSplitter.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result:=TLCLHandle(TGtk4Paned.Create(AWinControl, AParams));
end;

class function TGtk4WSCustomPairSplitter.AddSide(ASplitter: TCustomPairSplitter;
  ASide: TPairSplitterSide; Side: integer): Boolean;
var
  paned: TGtk4Paned;
  wside:TGtk4Widget;
begin
  Result := False;
  if not (WSCheckHandleAllocated(ASplitter, 'AddSide - splitter') and
          WSCheckHandleAllocated(ASide, 'AddSide - side'))
  then Exit;

  if (Side < 0) or (Side > 1) then exit;

  paned:=TGtk4Paned(ASplitter.Handle);
  wside:=TGtk4Widget(ASide.Handle);

  { The side arrives already parented: the generic TGtk4Widget.SetParent
    attached it to the paned as a plain (unmanaged) child, which GtkPaned
    never allocates — the sides stayed 1x1. Detach with unparent();
    set_parent(nil) is not a GTK4 removal API and only emitted
    "assertion GTK_IS_WIDGET (parent)" criticals while leaving the old
    parent in place, so add1/add2 could not adopt the widget either.
    Hold a temporary ref so dropping the old parent's ref cannot
    finalize the widget before the pane takes it. }
  g_object_ref(PGObject(wside.Widget));
  try
    if PGtkWidget(wside.Widget)^.get_parent <> nil then
      PGtkWidget(wside.Widget)^.unparent;
    if Side=0 then
      PGtkPaned(paned.Widget)^.add1(wside.Widget)
    else
      PGtkPaned(paned.Widget)^.add2(wside.Widget);
    { a previously detached side carries its own survival ref — the pane
      holds one now, so release ours }
    if wside is TGtk4SplitterSide then
      TGtk4SplitterSide(wside).PanedAdopted;
  finally
    g_object_unref(PGObject(wside.Widget));
  end;
  Result := True;
end;

class function TGtk4WSCustomPairSplitter.RemoveSide(ASplitter: TCustomPairSplitter;
  ASide: TPairSplitterSide; Side: integer): Boolean;
var
  wside: TGtk4Widget;
begin
  { The base class is a no-op (gtk2/qt5 use the common TSplitter fallback),
    but gtk4's native GtkPaned does NOT null its slot pointer when a child
    is unparented externally — destroying a side with plain unparent left
    paned->start/end_child dangling. Clear the slot through the paned API
    (TGtk4SplitterSide keeps the widget alive for the wrapper's remaining
    lifetime). }
  Result := False;
  if not (WSCheckHandleAllocated(ASplitter, 'RemoveSide - splitter') and
          WSCheckHandleAllocated(ASide, 'RemoveSide - side'))
  then Exit;
  wside := TGtk4Widget(ASide.Handle);
  if wside is TGtk4SplitterSide then
  begin
    TGtk4SplitterSide(wside).DetachFromPaned(
      PGtkPaned(TGtk4Paned(ASplitter.Handle).Widget));
    Result := True;
  end;
end;

class function TGtk4WSCustomPairSplitter.GetPosition(
  ASplitter: TCustomPairSplitter): Integer;
begin
  if not WSCheckHandleAllocated(ASplitter, 'GetPosition') then
    Result := inherited GetPosition(ASplitter)
  else
    Result := PGtkPaned(TGtk4Paned(ASplitter.Handle).Widget)^.get_position;
end;

class function TGtk4WSCustomPairSplitter.SetPosition(
  ASplitter: TCustomPairSplitter; var NewPosition: integer): Boolean;
var
  paned:PGtkPaned;
begin
  Result:=false;
  if not WSCheckHandleAllocated(ASplitter, ClassName+'.SetPosition') then
  	Exit;

  paned:=PGtkPaned(TGtk4Paned(ASplitter.Handle).Widget);
  { Contract (see the base TWSCustomPairSplitter.SetPosition): a negative
    NewPosition means "query only" — TCustomPairSplitter.UpdatePosition
    passes -1 and stores the returned value in FPosition. Writing -1 to
    GtkPaned would UNSET the user position, and never writing the actual
    value back left LCL Position stuck at -1 (runtime-confirmed). }
  if NewPosition >= 0 then
    paned^.set_position(NewPosition);
  NewPosition := paned^.get_position;
  Result:=true;
end;

class function TGtk4WSCustomPairSplitter.GetSplitterCursor(
  ASplitter: TCustomPairSplitter; var ACursor: TCursor): Boolean;
begin
  { GTK4 has no internal LCL TSplitter to carry a cursor (unlike the gtk2/qt5
    common fallback); it uses a native GtkPaned whose handle already shows its
    own resize cursor. Returning False lets TCustomPairSplitter.GetCursor fall
    back to the inherited TControl cursor, so a custom Splitter.Cursor survives
    the round-trip instead of being masked by a forced crVsplit/crHsplit. This
    pairs with SetSplitterCursor also returning False (below). }
  Result := False;
end;

class function TGtk4WSCustomPairSplitter.SetSplitterCursor(
  ASplitter: TCustomPairSplitter; ACursor: TCursor): Boolean;
begin
  { See GetSplitterCursor: no internal splitter to store the cursor on, so defer
    to the inherited TControl cursor path (which stores it on the control and
    applies it to the native widget). }
  Result := False;
end;


end.

