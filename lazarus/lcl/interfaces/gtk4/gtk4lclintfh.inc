{%MainUnit gtk4int.pas}

{******************************************************************************
                 All GTK4 interface communication implementations.

  !! Keep alphabetical !!

 ******************************************************************************
 Interface
 ******************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}

//##apiwiz##sps##   // Do not remove
function AddEventHandler(AHandle: TLCLHandle; AFlags: dword; 
  AEventHandler: TWaitHandleEvent; AData: PtrInt): PEventHandler; override;
function AddPipeEventHandler(AHandle: TLCLHandle;
  AEventHandler: TPipeEvent; AData: PtrInt): PPipeEventHandler; override;
function AddProcessEventHandler(AHandle: TLCLHandle;
  AEventHandler: TChildExitEvent; AData: PtrInt): PProcessEventHandler; override;
function AskUser(const DialogCaption, DialogMessage: string; DialogType:
   LongInt; Buttons: TDialogButtons; {%H-}HelpCtx: Longint): LongInt; override;

{ CreateStandardCursor is declared in TGtk4WidgetSet class body (gtk4int.pas) }
function CreateRubberBand(const ARect: TRect; const ABrush: HBrush = 0): HWND; override;
procedure DestroyRubberBand(ARubberBand: HWND); override;
procedure DrawDefaultDockImage({%H-}AOldRect, ANewRect: TRect; AOperation: TDockImageOperation); override;
procedure DrawGrid(DC: HDC; const R: TRect; DX, DY: Integer); override;

function ExtUTF8Out(DC: HDC; X, Y: Integer; Options: Longint; Rect: PRect;
                    Str: PChar; Count: Longint; Dx: PInteger): Boolean; override;
function FontIsMonoSpace(Font: HFont): boolean; override;

function GetAcceleratorString(const AVKey: Byte; const AShiftState: TShiftState): String; override;
function IsDesignerDC(WindowHandle: HWND; DC: HDC): Boolean; override;
 function GetControlConstraints(Constraints: TObject): boolean; override;
function GetLCLOwnerObject(Handle: HWnd): TObject; override;

function PromptUser(const DialogCaption : string;
                    const DialogMessage : string;
                          DialogType    : LongInt;
                          Buttons       : PLongInt;
                          ButtonCount   : LongInt;
                          DefaultIndex  : LongInt;
                          EscapeResult  : LongInt) : LongInt; override;

function RadialPie(DC: HDC; x1, y1, x2, y2, Angle1, Angle2: Integer): Boolean; override;

function RawImage_CreateBitmaps(const ARawImage: TRawImage; out ABitmap, AMask: HBitmap; ASkipMask: boolean = False): boolean; override;
function RawImage_DescriptionFromBitmap(ABitmap: HBITMAP; out ADesc: TRawImageDescription): boolean; override;
function RawImage_DescriptionFromDevice(ADC: HDC; out ADesc: TRawImageDescription): Boolean; override;
function RawImage_FromBitmap(out ARawImage: TRawImage; ABitmap, AMask: HBITMAP; ARect: PRect = nil): Boolean; override;
function RawImage_FromDevice(out ARawImage: TRawImage; ADC: HDC; const ARect: TRect): Boolean; override;
function RawImage_QueryDescription(AFlags: TRawImageQueryFlags; var ADesc: TRawImageDescription): Boolean; override;

procedure RemoveEventHandler(var AHandler: PEventHandler); override;
procedure RemovePipeEventHandler(var AHandler: PPipeEventHandler); override;
procedure RemoveProcessEventHandler(var AHandler: PProcessEventHandler); override;
procedure HandlePipeEvent(AData: PtrInt; AFlags: dword);

function SetComboMinDropDownSize(Handle: HWND; MinItemsWidth, MinItemsHeight, MinItemCount: integer): boolean; override;
procedure SetEventHandlerFlags(AHandler: PEventHandler; NewFlags: dword); override;
procedure SetRubberBandRect(const ARubberBand: HWND; const ARect: TRect); override;

function TextUTF8Out(DC: HDC; X, Y: Integer; Str: PChar; Count: Longint): Boolean; override;
//##apiwiz##eps##   // Do not remove, no wizard declaration after this line
