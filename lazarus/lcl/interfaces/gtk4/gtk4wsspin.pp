{
 *****************************************************************************
 *                               Gtk4WSSpin.pp                               *
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSSpin;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // RTL, FCL, LCL
  SysUtils, Math, Classes, Controls, LCLType, LCLProc, Spin, StdCtrls,
  // Widgetset
  lazgtk4, gtk4widgets, WSLCLClasses, WSProc, WSSpin;

type

  { TGtk4WSCustomFloatSpinEdit }

  TGtk4WSCustomFloatSpinEdit = class(TWSCustomFloatSpinEdit)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class function GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function GetSelLength(const ACustomEdit: TCustomEdit): integer; override;
    class function GetValue(const ACustomFloatSpinEdit: TCustomFloatSpinEdit): Double; override;

    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; ReadOnly: boolean); override;
    class procedure SetAlignment(const ACustomEdit: TCustomEdit; const AAlignment: TAlignment); override;
    class procedure SetEditorEnabled(const ACustomFloatSpinEdit: TCustomFloatSpinEdit; AValue: Boolean); override;
    class procedure UpdateControl(const ACustomFloatSpinEdit: TCustomFloatSpinEdit); override;
  end;

implementation


{ TGtk4WSCustomFloatSpinEdit }

class function TGtk4WSCustomFloatSpinEdit.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  ASpin: TGtk4SpinEdit;
begin
  ASpin := TGtk4SpinEdit.Create(AWinControl, AParams);
  Result := TLCLHandle(ASpin);
end;

class procedure TGtk4WSCustomFloatSpinEdit.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4SpinEdit(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSCustomFloatSpinEdit.GetSelStart(
  const ACustomEdit: TCustomEdit): integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelStart') then
    Exit;
  Result := TGtk4Editable(ACustomEdit.Handle).getSelStart;
end;

class function TGtk4WSCustomFloatSpinEdit.GetSelLength(
  const ACustomEdit: TCustomEdit): integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelLength') then
    Exit;
  Result := TGtk4Editable(ACustomEdit.Handle).getSelLength;
end;

class function TGtk4WSCustomFloatSpinEdit.GetValue(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit): Double;
var
  StrValue: String;
  DecSeparator: Char;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomFloatSpinEdit, 'GetValue') then
    Exit;
  { Same contract as gtk2 (gtk2wsspin.pp GetValue): the LCL value follows the
    entry TEXT; this getter must not touch the widget. The previous
    implementation ran gtk_spin_button_update here, which rewrites the text
    and emits 'changed' -> CM_TEXTCHANGED -> TextChanged -> Value -> GetValue
    ... (unbounded recursion when the text is transiently empty, e.g. after
    Delete/BackSpace). GTK itself runs update on activate, focus-out, the
    spin buttons and the change-value key bindings. }
  StrValue := TGtk4SpinEdit(ACustomFloatSpinEdit.Handle).Text;
  DecSeparator := DefaultFormatSettings.DecimalSeparator;
  if DecSeparator <> '.' then
    StrValue := StringReplace(StrValue, '.', DecSeparator, [rfReplaceAll]);
  if DecSeparator <> ',' then
    StrValue := StringReplace(StrValue, ',', DecSeparator, [rfReplaceAll]);
  Result := ACustomFloatSpinEdit.StrToValue(StrValue);
end;

class procedure TGtk4WSCustomFloatSpinEdit.SetSelStart(
  const ACustomEdit: TCustomEdit; NewStart: integer);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelStart') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Editable(ACustomEdit.Handle).SetSelStart(NewStart);
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomFloatSpinEdit.SetSelLength(
  const ACustomEdit: TCustomEdit; NewLength: integer);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelLength') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Editable(ACustomEdit.Handle).SetSelLength(NewLength);
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;


class procedure TGtk4WSCustomFloatSpinEdit.SetReadOnly(
  const ACustomEdit: TCustomEdit; ReadOnly: boolean);
var
  IsEditable: Boolean;
  ASpin: TGtk4SpinEdit;
  ASpinEdit: TCustomFloatSpinEdit;
  AMin, AMax: Double;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetReadOnly') then
    Exit;
  ASpin := TGtk4SpinEdit(ACustomEdit.Handle);
  ASpin.BeginUpdate;
  ASpin.ReadOnly := ReadOnly;
  { Disable spin buttons by collapsing adjustment range (GTK2 pattern).
    When ReadOnly, set min=max=current value so +/- buttons have no effect. }
  if ACustomEdit is TCustomFloatSpinEdit then
  begin
    ASpinEdit := TCustomFloatSpinEdit(ACustomEdit);
    if ReadOnly then
      ASpin.SetRange(ASpinEdit.Value, ASpinEdit.Value)
    else
    begin
      { LCL (GetLimitedValue) and gtk2: Max = Min means unlimited }
      if ASpinEdit.MaxValue > ASpinEdit.MinValue then
      begin
        AMin := ASpinEdit.MinValue;
        AMax := ASpinEdit.MaxValue;
      end else
      begin
        AMin := -MaxDouble;
        AMax := MaxDouble;
      end;
      ASpin.SetRange(AMin, AMax);
      { Restore EditorEnabled state — the spin entry should remain
        non-editable if EditorEnabled was set to False }
      IsEditable := ASpinEdit.EditorEnabled;
      gtk_editable_set_editable(PGtkEditable(ASpin.Widget), IsEditable);
    end;
  end;
  ASpin.EndUpdate;
end;

class procedure TGtk4WSCustomFloatSpinEdit.SetAlignment(
  const ACustomEdit: TCustomEdit; const AAlignment: TAlignment);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetAlignment') then
    Exit;
  TGtk4Entry(ACustomEdit.Handle).Alignment := AAlignment;
end;

class procedure TGtk4WSCustomFloatSpinEdit.SetEditorEnabled(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit; AValue: Boolean);
begin
  if not WSCheckHandleAllocated(ACustomFloatSpinEdit, 'SetEditorEnabled') then
    Exit;
  TGtk4Editable(ACustomFloatSpinEdit.Handle).BeginUpdate;
  { If ReadOnly is true, the entry must stay non-editable regardless of EditorEnabled }
  if ACustomFloatSpinEdit.ReadOnly then
    gtk_editable_set_editable(PGtkEditable(TGtk4Widget(ACustomFloatSpinEdit.Handle).Widget), False)
  else
    gtk_editable_set_editable(PGtkEditable(TGtk4Widget(ACustomFloatSpinEdit.Handle).Widget), AValue);
  TGtk4Editable(ACustomFloatSpinEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomFloatSpinEdit.UpdateControl(
  const ACustomFloatSpinEdit: TCustomFloatSpinEdit);
var
  ASpin: TGtk4SpinEdit;
  AMin: Double;
  AMax: Double;
  AValue: Double;
begin
  if not WSCheckHandleAllocated(ACustomFloatSpinEdit, 'UpdateControl') then
    Exit;
  ASpin := TGtk4SpinEdit(ACustomFloatSpinEdit.Handle);
  { Read the LCL value BEFORE touching digits/step/range: changing the digits
    makes GTK re-emit the formatted text from the (possibly stale) adjustment,
    and that 'changed' notification would replace the LCL value with the
    parsed native text before it is assigned below. }
  AValue := ACustomFloatSpinEdit.Value;

  { LCL (GetLimitedValue) and gtk2: Max = Min means unlimited }
  if ACustomFloatSpinEdit.MaxValue > ACustomFloatSpinEdit.MinValue then
  begin
    AMin := ACustomFloatSpinEdit.MinValue;
    AMax := ACustomFloatSpinEdit.MaxValue;
  end else
  begin
    AMin := -MaxDouble;
    AMax := MaxDouble;
  end;
  ASpin.BeginUpdate;
  try
    ASpin.Numeric := ACustomFloatSpinEdit.DecimalPlaces > 0;
    ASpin.NumDigits := ACustomFloatSpinEdit.DecimalPlaces;
    ASpin.Step := ACustomFloatSpinEdit.Increment;
    { Set range before value so value is within bounds }
    ASpin.SetRange(AMin, AMax);
    ASpin.Value := AValue;
    ASpin.ReadOnly := ACustomFloatSpinEdit.ReadOnly;
    { When ReadOnly, collapse adjustment range to disable spin buttons }
    if ACustomFloatSpinEdit.ReadOnly then
      ASpin.SetRange(AValue, AValue);
  finally
    ASpin.EndUpdate;
  end;
end;

end.
