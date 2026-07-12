{
 *****************************************************************************
 *                               gtk4int.pas                                 *
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
unit gtk4int;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

{ GTK4 interface no longer links GTK3 stub object. }

interface

uses
  {$IFDEF UNIX}
  BaseUnix, Unix, dynlibs,
  {$ENDIF}
  SysUtils, Classes, types, Math, FPImage,
  // LazUtils
  LazUTF8, IntegerList, GraphType, LazUtilities,
  // LCL
  LCLPlatformDef, InterfaceBase, LCLProc, LCLType, LMessages, LCLMessageGlue, LCLStrConsts,
  // LazUtils (after LCLProc so non-deprecated symbols take precedence)
  LazLoggerBase, LazTracer,
  Controls, Forms, Graphics, GraphUtil, IntfGraphics, StdCtrls, ComCtrls, Themes,
  LazGtk4, LazGdk4, LazGlib2, LazGObject2, LazCairo1, LazPango1, LazGio2,
  LazGdkPixbuf2, LazGtk4_Compat, LazGsk4,
  gtk4widgets, gtk4objects, gtk4procs, gtk4boxes;

type

  { lazarus GtkInterface definition for additional timer data, not in gtk }
  PGtkITimerInfo = ^TGtkITimerinfo;
  TGtkITimerInfo = record
    TimerHandle: guint;        // the gtk handle for this timer
    TimerFunc  : TWSTimerProc; // owner function to handle timer
  end;

  { Software caret info — one caret per application (WinAPI model) }
  TGtk4CaretInfo = record
    Handle: HWND;          { Owner widget handle }
    X, Y: Integer;         { Position within the owner widget }
    Width, Height: Integer; { Caret dimensions }
    Visible: Boolean;      { ShowCaret was called }
    IsDrawn: Boolean;      { Currently visible on screen (blink phase) }
    Blinking: Boolean;     { Blink timer is active }
    BlinkHide: Boolean;    { Current blink phase: True=hidden }
    BlinkTime: guint;      { Blink interval in ms }
    Timer: guint;          { g_timeout_add handle, 0 = no timer }
    ShowHideOnFocus: Boolean; { Auto show/hide on focus change }
  end;

  { TGtk4WidgetSet }

  TGtk4WidgetSet = class(TWidgetSet)
  private
    FMainPoll: PGPollFD;
    FGtk4Application: PGtkApplication;
    FDefaultAppFontName: String;
    FWaitHandles: PWaitHandleEventHandler;
    {$IFDEF UNIX}
    FChildSignalHandlers: PChildSignalEventHandler;
    {$ELSE}
    {$IFDEF VerboseGtkToDos}{$warning no declaration of FChildSignalHandlers for this OS}{$ENDIF}
    {$ENDIF}

    procedure Gtk4Create;
    procedure Gtk4Destroy;
    {$IFNDEF UNIX}
    procedure DoWakeMainThread(Sender: TObject);
    {$ENDIF}
    procedure SetDefaultAppFontName;
    procedure InitSysColorBrushes;
    procedure FreeSysColorBrushes;
  protected
    {shared stuff}
    FAppIcon: PGdkPixbuf;
    FStockNullBrush: HBRUSH;
    FStockBlackBrush: HBRUSH;
    FStockLtGrayBrush: HBRUSH;
    FStockGrayBrush: HBRUSH;
    FStockDkGrayBrush: HBRUSH;
    FStockWhiteBrush: HBRUSH;

    FStockNullPen: HPEN;
    FStockBlackPen: HPEN;
    FStockWhitePen: HPEN;
    FStockSystemFont: HFONT;
    FStockDefaultDC: HDC;
    FSysColorBrushes: array[0..MAX_SYS_COLORS] of HBRUSH;
    FGlobalCursor: HCursor;
    FThemeName: string;
    FCSSTheme: TStringList;
    FCaret: TGtk4CaretInfo;
    FDockImage: PGtkWidget;
    FStayOnTopList: TFPList;
    // tmp
    cssProvider:PGtkCssProvider;
    FLclCssProvider: PGtkCssProvider;

    function CreateThemeServices: TThemeServices; override;
  public
    function CreateDCForWidget(AWidget: PGtkWidget; AWindow: PGdkWindow; cr: Pcairo_t): HDC;
    procedure AddWindow(AWindow: PGtkWindow);
    { Caret support }
    procedure InvalidateCaret;
    procedure DrawCaret(cr: Pcairo_t; AWidget: TGtk4Widget);
    procedure StartCaretTimer;
    procedure StopCaretTimer;
    {$IFDEF UNIX}
    procedure InitSynchronizeSupport;
    procedure ProcessChildSignal;
    procedure PrepareSynchronize({%H-}AObject: TObject);
    {$ENDIF}
    procedure LoadCSSTheme;
    procedure ClearCSSTheme;
    function GetCSSTheme(AList: TStrings): boolean;
    function GetThemeName: string;
    procedure InitStockItems;
    procedure FreeStockItems;
    function CreateDefaultFont: HFONT;

  public
    constructor Create; override;
    destructor Destroy; override;

    function LCLPlatform: TLCLPlatform; override;
    procedure AppInit(var ScreenInfo: TScreenInfo); override;
    procedure AppRun(const ALoop: TApplicationMainLoop); override;
    procedure AppWaitMessage; override;
    procedure AppProcessMessages; override;
    procedure AppTerminate; override;

    procedure AppMinimize; override;
    procedure AppRestore; override;
    procedure AppBringToFront; override;
    procedure AppSetIcon(const Small, Big: HICON); override;
    procedure AppSetTitle(const ATitle: string); override;
    function AppRemoveStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;
    function AppRestoreStayOnTopFlags(const ASystemTopAlso: Boolean = False): Boolean; override;

    function CreateStandardCursor(ACursor: SmallInt): HCURSOR; override;

    function  DCGetPixel(CanvasHandle: HDC; X, Y: integer): TGraphicsColor; override;
    procedure DCSetPixel(CanvasHandle: HDC; X, Y: integer; AColor: TGraphicsColor); override;
    procedure DCRedraw(CanvasHandle: HDC); override;
    procedure DCSetAntialiasing(CanvasHandle: HDC; AEnabled: Boolean); override;
    procedure SetDesigning(AComponent: TComponent); override;
    function  GetLCLCapability(ACapability: TLCLCapability): PtrUInt; override;

    function CreateTimer(Interval: integer; TimerFunc: TWSTimerProc): TLCLHandle; override;
    function DestroyTimer(TimerHandle: TLCLHandle): boolean; override;

    function IsValidDC(const DC: HDC): Boolean;
    function IsValidGDIObject(const AGdiObject: HGDIOBJ): Boolean;
    function IsValidHandle(const AHandle: HWND): Boolean;

    property AppIcon: PGdkPixbuf read FAppIcon;
    property DefaultAppFontName: String read FDefaultAppFontName;
    property Gtk4Application: PGtkApplication read FGtk4Application;

    {$i gtk4winapih.inc}
    {$i gtk4lclintfh.inc}
  end;

var
  GTK4WidgetSet: TGTK4WidgetSet;
  // FTimerData contains the currently running timers
  FTimerData: TFPList;   // list of PGtkITimerinfo


function Gtk4WidgetFromGtkWidget(const AWidget: PGtkWidget): TGtk4Widget;
function HwndFromGtkWidget(AWidget: PGtkWidget): HWND;

implementation

uses
  {%H-}Gtk4WSFactory{%H-}, gtk4themes;

{------------------------------------------------------------------------------
  Function: FillStandardDescription
  Params:
  Returns:
 ------------------------------------------------------------------------------}
procedure FillStandardDescription(var Desc: TRawImageDescription);
begin
  Desc.Init;

  Desc.Format := ricfRGBA;
//  Desc.Width := 0
//  Desc.Height := 0
//  Desc.PaletteColorCount := 0;

  Desc.BitOrder := riboReversedBits;
  Desc.ByteOrder := riboLSBFirst;
  Desc.LineOrder := riloTopToBottom;

  Desc.BitsPerPixel := 32;
  Desc.Depth := 32;
  // Qt wants dword-aligned data
  Desc.LineEnd := rileDWordBoundary;

  // 8-8-8-8 mode, high byte is Alpha
  Desc.AlphaPrec := 8;
  Desc.RedPrec := 8;
  Desc.GreenPrec := 8;
  Desc.BluePrec := 8;

  Desc.AlphaShift := 24;
  Desc.RedShift := 0;
  Desc.GreenShift := 8;
  Desc.BlueShift := 16;

  // Qt wants dword-aligned data
  Desc.MaskLineEnd := rileDWordBoundary;
  Desc.MaskBitOrder := riboReversedBits;
  Desc.MaskBitsPerPixel := 1;
//  Desc.MaskShift := 0;
end;


function Gtk4WidgetFromGtkWidget(const AWidget: PGtkWidget): TGtk4Widget;
var
  W: PGtkWidget;
begin
  Result := nil;

  if AWidget = nil then
    exit;

  { GTK4: guard against invalid widget pointers (e.g. internal GTK widgets
    returned by get_parent that are not valid GObjects). }
  if not Gtk4IsWidget(PGObject(AWidget)) then
    exit;

  { Try direct lookup first. Validate the stored pointer against the live-widget
    registry: a destroyed TGtk4Widget may leave stale 'lclwidget' data on a
    GtkWidget that outlives it (or is reused), and returning that dangling
    object crashes any caller that dereferences it — e.g. GetFocus ->
    GetProp(.Widget) during NewFile autosize. Gtk4IsLiveWidgetPointer only
    accepts pointers still registered (every TGtk4Widget registers in its ctor
    and unregisters in its dtor), so a stale entry is treated as not-found. }
  Result := TGtk4Widget(g_object_get_data(AWidget, 'lclwidget'));
  if Gtk4IsLiveWidgetPointer(Result) then
    exit;
  Result := nil;

  { GTK4 composite widgets: internal children (e.g. GtkText inside GtkEntry)
    don't have 'lclwidget' tag. Walk parent chain to find the owning LCL widget. }
  W := AWidget^.get_parent;
  while (W <> nil) and Gtk4IsWidget(PGObject(W)) do
  begin
    Result := TGtk4Widget(g_object_get_data(W, 'lclwidget'));
    if Gtk4IsLiveWidgetPointer(Result) then
      exit;
    Result := nil;
    W := W^.get_parent;
  end;
end;

function HwndFromGtkWidget(AWidget: PGtkWidget): HWND;
begin
  Result := HWND(Gtk4WidgetFromGtkWidget(AWidget));
end;

function TGtk4WidgetSet.GetLCLCapability(ACapability: TLCLCapability): PtrUInt;
begin
  case ACapability of
  lcTextHint: Result := LCL_CAPABILITY_YES;
  else
    Result := inherited GetLCLCapability(ACapability);
  end;
end;


{$i gtk4object.inc}
{$i gtk4winapi.inc}
{$i gtk4lclintf.inc}

end.
