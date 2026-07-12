{
 *****************************************************************************
 *                             Gtk4WSCheckLst.pp                             *
 *                             -----------------                             * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSCheckLst;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

interface

uses
  LazGtk4,
  gtk4widgets,
  ////////////////////////////////////////////////////
  // I M P O R T A N T
  ////////////////////////////////////////////////////
  // To get as little as posible circles,
  // uncomment only when needed for registration
  ////////////////////////////////////////////////////
  CheckLst, StdCtrls, Controls, LCLType, SysUtils, Classes, LCLProc,
  ////////////////////////////////////////////////////
   WSCheckLst, WSLCLClasses, WSProc;

type

  { TGtk4WSCheckListBox }

  { TGtk4WSCustomCheckListBox }

  TGtk4WSCustomCheckListBox = class(TWSCustomCheckListBox)
  published
    class function  CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function GetItemEnabled(const ACheckListBox: TCustomCheckListBox;
      const AIndex: integer): Boolean; override;
    class function GetState(const ACheckListBox: TCustomCheckListBox;
      const AIndex: integer): TCheckBoxState; override;
    class procedure SetItemEnabled(const ACheckListBox: TCustomCheckListBox;
      const AIndex: integer; const AEnabled: Boolean); override;
    class procedure SetState(const ACheckListBox: TCustomCheckListBox;
      const AIndex: integer; const AState: TCheckBoxState); override;
  end;


implementation

uses
  gtk4procs;

type
  { Class cracker to access protected GetCachedData / GetCachedDataSize }
  TCheckListBoxCracker = class(TCustomCheckListBox);

  { Mirror of TCachedItemData declared in checklst.pas implementation section.
    Used to read check state from LCL cache without triggering WS dispatch.
    (WS GetState/GetItemEnabled must NOT call ACheckListBox.State[i] or
     ACheckListBox.ItemEnabled[i] — those dispatch back to WS, causing
     infinite recursion.) }
  PGtk4CLBCacheData = ^TGtk4CLBCacheData;
  TGtk4CLBCacheData = record
    State: TCheckBoxState;
    Disabled: Boolean;
    Header: Boolean;
  end;

{ TGtk4WSCheckListBox }

class function TGtk4WSCustomCheckListBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4CheckListBox.Create(AWinControl, AParams));
end;

class function TGtk4WSCustomCheckListBox.GetItemEnabled(
  const ACheckListBox: TCustomCheckListBox; const AIndex: integer): Boolean;
var
  ABase: Pointer;
  AOffset: Integer;
begin
  { Read directly from LCL cache via class cracker.
    ACheckListBox.ItemEnabled[AIndex] must NOT be used here — it dispatches
    back to this WS method, causing infinite recursion.
    GetCachedData may raise EInvalidOperation when cache is not yet valid
    (e.g. during handle creation), so guard with try/except. }
  Result := True;
  if not WSCheckHandleAllocated(ACheckListBox, 'GetItemEnabled') then
    Exit;
  if (AIndex >= 0) and (AIndex < ACheckListBox.Items.Count) then
  try
    ABase := TCheckListBoxCracker(ACheckListBox).GetCachedData(AIndex);
    if ABase <> nil then
    begin
      AOffset := TCheckListBoxCracker(ACheckListBox).GetCachedDataSize
                 - SizeOf(TGtk4CLBCacheData);
      Result := not PGtk4CLBCacheData(ABase + AOffset)^.Disabled;
    end;
  except
    { Cache not valid yet (during handle creation) — return default }
  end;
end;

class function TGtk4WSCustomCheckListBox.GetState(
  const ACheckListBox: TCustomCheckListBox; const AIndex: integer
  ): TCheckBoxState;
var
  ABase: Pointer;
  AOffset: Integer;
begin
  { Read directly from LCL cache via class cracker.
    ACheckListBox.State[AIndex] must NOT be used here — it dispatches
    back to this WS method, causing infinite recursion (stack overflow).
    GetCachedData may raise EInvalidOperation when cache is not yet valid
    (e.g. during handle creation), so guard with try/except. }
  Result := cbUnchecked;
  if not WSCheckHandleAllocated(ACheckListBox, 'GetState') then
    Exit;
  if (AIndex >= 0) and (AIndex < ACheckListBox.Items.Count) then
  try
    ABase := TCheckListBoxCracker(ACheckListBox).GetCachedData(AIndex);
    if ABase <> nil then
    begin
      AOffset := TCheckListBoxCracker(ACheckListBox).GetCachedDataSize
                 - SizeOf(TGtk4CLBCacheData);
      Result := PGtk4CLBCacheData(ABase + AOffset)^.State;
    end;
  except
    { Cache not valid yet (during handle creation) — return default }
  end;
end;

class procedure TGtk4WSCustomCheckListBox.SetItemEnabled(
  const ACheckListBox: TCustomCheckListBox; const AIndex: integer;
  const AEnabled: Boolean);
begin
  if not WSCheckHandleAllocated(ACheckListBox, 'SetItemEnabled') then
    Exit;
  if (AIndex < 0) or (AIndex >= ACheckListBox.Items.Count) then
    Exit;
  { State is stored in LCL. Trigger visual refresh via queue_draw. }
  TGtk4CheckListBox(ACheckListBox.Handle).GetContainerWidget^.queue_draw;
end;

class procedure TGtk4WSCustomCheckListBox.SetState(
  const ACheckListBox: TCustomCheckListBox; const AIndex: integer;
  const AState: TCheckBoxState);
begin
  if not WSCheckHandleAllocated(ACheckListBox, 'SetState') then
    Exit;
  if (AIndex < 0) or (AIndex >= ACheckListBox.Items.Count) then
    Exit;
  { State is stored in LCL. Trigger visual refresh via queue_draw. }
  TGtk4CheckListBox(ACheckListBox.Handle).GetContainerWidget^.queue_draw;
end;

end.
