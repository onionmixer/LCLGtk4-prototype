{
 *****************************************************************************
 *                             Gtk4WSExtCtrls.pp                             *
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
unit Gtk4WSExtCtrls;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // LCL
  LCLProc, ExtCtrls, Classes, Controls, SysUtils, types, Graphics, LCLType,
  // widgetset
  WSExtCtrls, WSLCLClasses;

type

  { TGtk4WSPage }

  TGtk4WSPage = class(TWSPage)
  published
  end;

  { TGtk4WSNotebook }

  TGtk4WSNotebook = class(TWSNotebook)
  published
  end;

  { TGtk4WSCustomShape }

  TGtk4WSCustomShape = class(TWSCustomShape)
  published
  end;

  { TGtk4WSCustomSplitter }

  TGtk4WSCustomSplitter = class(TWSCustomSplitter)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSSplitter }

  TGtk4WSSplitter = class(TWSSplitter)
  published
  end;

  { TGtk4WSPaintBox }

  TGtk4WSPaintBox = class(TWSPaintBox)
  published
  end;

  { TGtk4WSCustomImage }

  TGtk4WSCustomImage = class(TWSCustomImage)
  published
  end;

  { TGtk4WSImage }

  TGtk4WSImage = class(TWSImage)
  published
  end;

  { TGtk4WSBevel }

  TGtk4WSBevel = class(TWSBevel)
  published
  end;

  { TGtk4WSCustomRadioGroup }

  TGtk4WSCustomRadioGroup = class(TWSCustomRadioGroup)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSRadioGroup }

  TGtk4WSRadioGroup = class(TWSRadioGroup)
  published
  end;

  { TGtk4WSCustomCheckGroup }

  TGtk4WSCustomCheckGroup = class(TWSCustomCheckGroup)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSCheckGroup }

  TGtk4WSCheckGroup = class(TWSCheckGroup)
  published
  end;

  { TGtk4WSCustomLabeledEdit }

  TGtk4WSCustomLabeledEdit = class(TWSCustomLabeledEdit)
  published
  end;

  { TGtk4WSLabeledEdit }

  TGtk4WSLabeledEdit = class(TWSLabeledEdit)
  published
  end;

  { TGtk4WSCustomPanel }

  TGtk4WSCustomPanel = class(TWSCustomPanel)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function GetDefaultColor(const AControl: TControl; const ADefaultColorType: TDefaultColorType): TColor; override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;
  end;

  { TGtk4WSPanel }

  TGtk4WSPanel = class(TWSPanel)
  published
  end;

  { TGtk4WSCustomTrayIcon }

  TGtk4WSCustomTrayIcon = class(TWSCustomTrayIcon)
  published
    class function Hide(const ATrayIcon: TCustomTrayIcon): Boolean; override;
    class function Show(const ATrayIcon: TCustomTrayIcon): Boolean; override;
    class procedure InternalUpdate(const ATrayIcon: TCustomTrayIcon); override;
    class function GetPosition(const ATrayIcon: TCustomTrayIcon): TPoint; override;
  end;

implementation

uses
  gtk4widgets;

{ TGtk4WSCustomRadioGroup }

class function TGtk4WSCustomRadioGroup.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AGroupBox: TGtk4GroupBox;
begin
  AGroupBox := TGtk4GroupBox.Create(AWinControl, AParams);
  AGroupBox.Text := AWinControl.Caption;
  Result := TLCLHandle(AGroupBox);
end;

{ TGtk4WSCustomCheckGroup }

class function TGtk4WSCustomCheckGroup.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AGroupBox: TGtk4GroupBox;
begin
  AGroupBox := TGtk4GroupBox.Create(AWinControl, AParams);
  AGroupBox.Text := AWinControl.Caption;
  Result := TLCLHandle(AGroupBox);
end;

{ TGtk4WSCustomSplitter }

class function TGtk4WSCustomSplitter.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  ASplitter: TGtk4Splitter;
begin
  ASplitter := TGtk4Splitter.Create(AWinControl, AParams);
  Result := TLCLHandle(ASplitter);
end;

{ TGtk4WSCustomPanel }

class function TGtk4WSCustomPanel.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  APanel: TGtk4Panel;
begin
  APanel := TGtk4Panel.Create(AWinControl, AParams);

  APanel.BorderStyle := TCustomControl(AWinControl).BorderStyle;
  APanel.Text := AWinControl.Caption;

  Result := TLCLHandle(APanel);
end;

class function TGtk4WSCustomPanel.GetDefaultColor(const AControl: TControl;
  const ADefaultColorType: TDefaultColorType): TColor;
const
  DefColors: array[TDefaultColorType] of TColor = (
    { dctBrush } clBackground,
    { dctFont  } clBtnText
  );
begin
  Result := DefColors[ADefaultColorType];
end;

class procedure TGtk4WSCustomPanel.SetBorderStyle(
  const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
var
  APanel: TGtk4Panel;
begin
  if not AWinControl.HandleAllocated then
    Exit;
  APanel := TGtk4Panel(AWinControl.Handle);
  if APanel.BorderStyle = ABorderStyle then
    Exit;
  APanel.BorderStyle := ABorderStyle;
  APanel.Widget^.queue_draw;
end;

{ TGtk4WSCustomTrayIcon }

class function TGtk4WSCustomTrayIcon.Hide(const ATrayIcon: TCustomTrayIcon
  ): Boolean;
begin
  Result:=inherited Hide(ATrayIcon);
end;

class function TGtk4WSCustomTrayIcon.Show(const ATrayIcon: TCustomTrayIcon
  ): Boolean;
begin
  Result:=inherited Show(ATrayIcon);
end;

class procedure TGtk4WSCustomTrayIcon.InternalUpdate(
  const ATrayIcon: TCustomTrayIcon);
begin
  inherited InternalUpdate(ATrayIcon);
end;

class function TGtk4WSCustomTrayIcon.GetPosition(
  const ATrayIcon: TCustomTrayIcon): TPoint;
begin
  Result:=inherited GetPosition(ATrayIcon);
end;

end.
