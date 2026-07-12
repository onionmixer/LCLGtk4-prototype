{
 *****************************************************************************
 *                              Gtk4WSExtDlgs.pp                             *
 *                              ----------------                             *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSExtDlgs;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  ExtDlgs,
////////////////////////////////////////////////////
  Controls, LCLType,
  gtk4widgets,
  WSExtDlgs, WSLCLClasses;

type

  { TGtk4WSPreviewFileControl }

  TGtk4WSPreviewFileControl = class(TWSPreviewFileControl)
  published
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSPreviewFileDialog }

  TGtk4WSPreviewFileDialog = class(TWSPreviewFileDialog)
  published
  end;

  { TGtk4WSOpenPictureDialog }

  TGtk4WSOpenPictureDialog = class(TWSOpenPictureDialog)
  published
  end;

  { TGtk4WSSavePictureDialog }

  TGtk4WSSavePictureDialog = class(TWSSavePictureDialog)
  published
  end;

  { TGtk4WSCalculatorDialog }

  TGtk4WSCalculatorDialog = class(TWSCalculatorDialog)
  published
  end;

  { TGtk4WSCalculatorForm }

  TGtk4WSCalculatorForm = class(TWSCalculatorForm)
  published
  end;

  { TGtk4WSCalendarDialogForm }

  TGtk4WSCalendarDialogForm = class(TWSCalendarDialogForm)
  published
  end;

  { TGtk4WSCalendarDialog }

  TGtk4WSCalendarDialog = class(TWSCalendarDialog)
  published
  end;


implementation

{ TGtk4WSPreviewFileControl }

class function TGtk4WSPreviewFileControl.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  Gtk4CustomControl: TGtk4CustomControl;
begin
  Gtk4CustomControl := TGtk4CustomControl.Create(AWinControl, AParams);
  Result := TLCLHandle(Gtk4CustomControl);
end;

end.
