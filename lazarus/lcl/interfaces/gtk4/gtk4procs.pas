{
 *****************************************************************************
 *                               gtk4procs.pas                               *
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
unit Gtk4Procs;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

interface

uses
  {$IFDEF UNIX}
  Unix,
  {$ENDIF}
  Classes, SysUtils, Controls, StdCtrls, Graphics,
  LazGtk4, LazGdk4, LazGLib2, LazGObject2, LazGio2, LazGdkPixbuf2, LazPango1,
  LazGtk4_Compat, LCLType, InterfaceBase;

type
  GType = TGType;
  PPWaitHandleEventHandler = ^PWaitHandleEventHandler;
  PWaitHandleEventHandler = ^TWaitHandleEventHandler;
  TWaitHandleEventHandler = record
    Handle: TLCLHandle;
    GIOChannel: PGIOChannel;
    GSourceID: guint;
    UserData: PtrInt;
    OnEvent: TWaitHandleEvent;
    PrevHandler: PWaitHandleEventHandler;
    NextHandler: PWaitHandleEventHandler;
  end;

{$IFDEF UNIX}
  PPChildSignalEventHandler = ^PChildSignalEventHandler;
  PChildSignalEventHandler = ^TChildSignalEventHandler;
  TChildSignalEventHandler = record
    PID: TPid;
    UserData: PtrInt;
    OnEvent: TChildExitEvent;
    PrevHandler: PChildSignalEventHandler;
    NextHandler: PChildSignalEventHandler;
  end;
{$ENDIF}

  // styles -------------------------------------------------------------------

  TLazGtkStyle = (
    lgsGTK_Default, // without anything
    lgsDefault,     // with rc file
    lgsButton,
    lgsLabel,
    lgsWindow,
    lgsCheckbox,
    lgsRadiobutton,
    lgsMenu,
    lgsMenuBar,
    lgsMenuitem,
    lgsList,
    lgsVerticalScrollbar,
    lgsHorizontalScrollbar,
    lgsTooltip,
    lgsVerticalPaned,
    lgsHorizontalPaned,
    lgsNotebook,
    lgsStatusBar,
    lgsHScale,
    lgsVScale,
    lgsGroupBox,
    lgsTreeView,      // for gtk4
    lgsToolBar,       // toolbar
    lgsToolButton,    // button placed on toolbar
    lgsCalendar,      // button placed on toolbar
    lgsScrolledWindow,
    lgsMemo, // memo
    lgsFrame,
    // user defined
    lgsUserDefined
    );


  PStyleObject = ^TStyleObject;
  TStyleObject = record
    Style: PGTKStyle;
    Owner: PGtkWidget;  // The widget that we hold a reference to.
    Widget: PGTKWidget; // This is the style widget.
    FrameBordersValid: boolean;
    FrameBorders: TRect;
  end;

  TGtkScrollStyle = record
    Horizontal,
	  Vertical: TGtkPolicyType;
  end;

const
  SysColorMap: array [0..MAX_SYS_COLORS] of DWORD = (
    $C0C0C0,     {COLOR_SCROLLBAR}
    $808000,     {COLOR_BACKGROUND}
    $800000,     {COLOR_ACTIVECAPTION}
    $808080,     {COLOR_INACTIVECAPTION}
    $C0C0C0,     {COLOR_MENU}
    $FFFFFF,     {COLOR_WINDOW}
    $000000,     {COLOR_WINDOWFRAME}
    $000000,     {COLOR_MENUTEXT}
    $000000,     {COLOR_WINDOWTEXT}
    $FFFFFF,     {COLOR_CAPTIONTEXT}
    $C0C0C0,     {COLOR_ACTIVEBORDER}
    $C0C0C0,     {COLOR_INACTIVEBORDER}
    $808080,     {COLOR_APPWORKSPACE}
    $800000,     {COLOR_HIGHLIGHT}
    $FFFFFF,     {COLOR_HIGHLIGHTTEXT}
    $D0D0D0,     {COLOR_BTNFACE}
    $808080,     {COLOR_BTNSHADOW}
    $808080,     {COLOR_GRAYTEXT}
    $000000,     {COLOR_BTNTEXT}
    $C0C0C0,     {COLOR_INACTIVECAPTIONTEXT}
    $F0F0F0,     {COLOR_BTNHIGHLIGHT}
    $000000,     {COLOR_3DDKSHADOW}
    $C0C0C0,     {COLOR_3DLIGHT}
    $000000,     {COLOR_INFOTEXT}
    $AEF3F3,     {COLOR_INFOBK}
    $000000,     {unassigned}
    $000000,     {COLOR_HOTLIGHT}
    $800000,     {COLOR_GRADIENTACTIVECAPTION}
    $808080,     {COLOR_GRADIENTINACTIVECAPTION}
    $800000,     {COLOR_MENUHILIGHT}
    $D0D0D0,     {COLOR_MENUBAR}
    $D0D0D0      {COLOR_FORM}
  ); {end _SysColors}

  LazGtkStyleNames: array[TLazGtkStyle] of string = (
    'gtk_default',
    'default',
    'button',
    'label',
    'window',
    'checkbox',
    'radiobutton',
    'menu',
    'menubar',
    'menuitem',
    'list',
    'vertical scrollbar',
    'horizontal scrollbar',
    'tooltip',
    'vertical paned',
    'horizontal paned',
    'notebook',
    'statusbar',
    'hscale',
    'vscale',
    'groupbox',
    'treeview',
    'toolbar',
    'toolbutton',
    'calendar',
    'scrolled window',
    'memo',
    'frame',
    ''
    );

  NO_PROPAGATION_TO_PARENT = 127;
  GTK4_LEFT_BUTTON = 1;
  GTK4_MIDDLE_BUTTON = 2;
  GTK4_RIGHT_BUTTON = 3;
  GTK4_XBUTTON1 = 4;  { Back/X1 extra mouse button }
  GTK4_XBUTTON2 = 5;  { Forward/X2 extra mouse button }

  G_TYPE_FUNDAMENTAL_SHIFT = 2;
  G_TYPE_FUNDAMENTAL_MAX = 255 shl G_TYPE_FUNDAMENTAL_SHIFT;

{ Constant fundamental types,
  introduced by g_type_init(). }
  G_TYPE_INVALID = GType(0 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_NONE = GType(1 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_INTERFACE = GType(2 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_CHAR = GType(3 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_UCHAR = GType(4 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_BOOLEAN = GType(5 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_INT = GType(6 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_UINT = GType(7 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_LONG = GType(8 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_ULONG = GType(9 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_INT64 = GType(10 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_UINT64 = GType(11 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_ENUM = GType(12 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_FLAGS = GType(13 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_FLOAT = GType(14 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_DOUBLE = GType(15 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_STRING = GType(16 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_POINTER = GType(17 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_BOXED = GType(18 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_PARAM = GType(19 shl G_TYPE_FUNDAMENTAL_SHIFT);
  G_TYPE_OBJECT = GType(20 shl G_TYPE_FUNDAMENTAL_SHIFT);


  GtkListItemGtkListTag = 'GtkList';
  GtkListItemLCLListTag = 'LCLList';

  AGtkJustification: array[TAlignment] of TGTKJustification =
  (
    GTK_JUSTIFY_LEFT, {0  taLeftJustify}
    GTK_JUSTIFY_RIGHT, {1 taRightJustify}
    GTK_JUSTIFY_CENTER {2 taCenter}
  );

  AGtkJustificationF: array[TAlignment] of gfloat =
  (
    0.0, {GTK_JUSTIFY_LEFT  taLeftJustify}
    1.0, {GTK_JUSTIFY_RIGHT taRightJustify}
    0.5 {GTK_JUSTIFY_CENTER taCenter}
  );

  BorderStyleShadowMap: array[TBorderStyle] of TGtkShadowType =
  (
   GTK_SHADOW_NONE, {0 bsNone   }
   GTK_SHADOW_ETCHED_IN {3 bsSingle }
  );

  StaticBorderShadowMap: array[TStaticBorderStyle] of TGtkShadowType =
  (
    GTK_SHADOW_NONE, {0 sbsNone   }
    GTK_SHADOW_ETCHED_IN, {3 sbsSingle }
    GTK_SHADOW_IN {1 sbsSunken}
  );

  MenuDirection : array[Boolean] of TGtkPackDirection = (
    GTK_PACK_DIRECTION_LTR,
    GTK_PACK_DIRECTION_RTL
    );



  odnScrollArea = 'scroll_area'; // the gtk_scrolled_window of a widget
                                 // used by TCustomForm and TScrollbox
  odnScrollBar = 'ScrollBar'; // Gives the scrollbar the tgtkrange is belonging to
                              // Used by TScrollbar, TScrollbox and TWinApiWidget
  odnScrollBarLastPos = 'ScrollBarLastPos';




function Gtk4IsObject(AWidget: PGObject): GBoolean;
function Gtk4IsButton(AWidget: PGObject): GBoolean;

function Gtk4IsCellView(AWidget: PGObject): GBoolean;
function Gtk4IsComboBox(AWidget: PGObject): GBoolean;
function Gtk4IsEditable(AWidget: PGObject): GBoolean;
function Gtk4IsEntry(AWidget: PGObject): GBoolean;
function Gtk4IsTextView(AWidget: PGObject): GBoolean;

function Gtk4IsBox(AWidget: PGObject): GBoolean;
function Gtk4IsFixed(AWidget: PGObject): GBoolean;
function Gtk4IsLayout(AWidget: PGObject): GBoolean;

function Gtk4IsMenu(AWidget: PGObject): GBoolean;
function Gtk4IsMenuBar(AWidget: PGObject): GBoolean;

function Gtk4IsNoteBook(AWidget: PGObject): GBoolean;

function Gtk4IsHScrollbar(AWidget: PGObject): GBoolean;
function Gtk4IsVScrollbar(AWidget: PGObject): GBoolean;

function Gtk4IsScrolledWindow(AWidget: PGObject): GBoolean;
function Gtk4IsSpinButton(AWidget: PGObject): GBoolean;
function Gtk4IsViewPort(AWidget: PGObject): GBoolean;
function Gtk4IsWidget(AWidget: PGObject): GBoolean;
function Gtk4IsGtkWindow(AWidget: PGObject): GBoolean;
function Gtk4IsGdkPixbuf(AWidget: PGObject): GBoolean;

function Gtk4WidgetIsA(AWidget: PGtkWidget; AType: TGType): boolean;
function Get3WidgetClassName(AWidget: PGtkWidget): string;

function Gtk4IsPangoContext(APangoContext: PGObject): GBoolean;
function Gtk4IsPangoFontMetrics(APangoFontMetrics: PGObject): GBoolean;

function Gtk4TranslateScrollStyle(const SS: TScrollStyle): TGtkScrollStyle;
function Gtk4ScrollTypeToScrollCode(ScrollType: TGtkScrollType): LongWord;

function TGDKColorToTColor(const value : TGDKColor) : TColor;
function TColorToTGDKColor(const value : TColor) : TGDKColor;
function TGdkRGBAToTColor(const value : TGdkRGBA) : TColor;
function TColortoTGdkRGBA(const value : TColor; IgnoreAlpha: Boolean = True) : TGdkRGBA;
function ColorToCairoRGB(AColor: TColor; out ARed, AGreen, ABlue: Double): Boolean;
function RectFromGtkAllocation(AGtkAllocation: TGtkAllocation): TRect;
function RectFromGdkRect(AGdkRect: TGdkRectangle): TRect;
function RectFromPangoRect(APangoRect: TPangoRectangle): TRect;
function GdkRectFromRect(R: TRect): TGdkRectangle;
function GtkAllocationFromRect(R: TRect): TGtkAllocation;

function GdkKeyToLCLKey(AValue: Word): Word;
function LCLKeyToGdkKeyval(AVK: Word): guint;
function ShiftStateToGdkMods(AShift: TShiftState): TGdkModifierType;
function GdkModifierStateToLCL(AState: TGdkModifierType; const AIsKeyEvent: Boolean): PtrInt;
function GdkModifierStateToShiftState(AState: TGdkModifierType): TShiftState;

procedure SetWindowCursor(AWindow: PGdkWindow; ACursor: HCursor;
  ARecursive: Boolean; ASetDefault: Boolean);
procedure SetGlobalCursor(Cursor: HCURSOR);

type
  Charsetstr = string[15];
  PCharSetEncodingRec=^TCharSetEncodingRec;
  TCharSetEncodingRec=record
    CharSet: byte;              // winapi charset value
    CharSetReg:CharSetStr;      // Charset Registry Pattern
    CharSetCod:CharSetStr;      // Charset Encoding Pattern
    EnumMap: boolean;           // this mapping is meanful when enumerating fonts?
    CharsetRegPart: boolean;    // is CharsetReg a partial pattern?
    CharsetCodPart: boolean;    // is CharsetCod a partial pattern?
  end;

  { Per-GType visual overflow cache for WithThemeSpace compensation.
    GTK4 CSS effects (box-shadow etc.) extend outside widget allocation bounds.
    gtk_widget_compute_bounds returns full visual bounds including these effects.
    We cache overflow per widget GType to avoid repeated measurement. }
  TGTypeOverflow = record
    WidgetGType: GType;
    Top, Bottom, Left, Right: Integer;
  end;

var
  CharSetEncodingList: TList;
  StandardStyles: array[TLazGtkStyle] of PStyleObject;
  Styles: TStrings;
  GTypeOverflowCache: array of TGTypeOverflow;
  GTypeOverflowCacheCount: Integer;



  procedure AddCharsetEncoding(CharSet: Byte; CharSetReg, CharSetCod: CharSetStr;
    ToEnum:boolean=true; CrPart:boolean=false; CcPart:boolean=false);
  procedure ClearCharsetEncodings;
  procedure CreateDefaultCharsetEncodings;
  function Gtk4CharSetToPangoLanguage(ACharSet: Byte): PPangoLanguage;

function PANGO_PIXELS(d:integer):integer; inline;
function GetStyleWidget(aStyle: TLazGtkStyle): PGtkWidget;
procedure ReleaseAllStyles;

{ Per-GType visual overflow cache — used by WithThemeSpace in preferredSize }
function GetGTypeOverflow(AType: GType; out ATop, ABottom, ALeft, ARight: Integer): Boolean;
procedure SetGTypeOverflow(AType: GType; ATop, ABottom, ALeft, ARight: Integer);
procedure ClearGTypeOverflowCache;

implementation
uses LCLProc;

function PANGO_PIXELS(d:integer):integer;
begin
  Result:=((d + 512) shr 10);
end;

function TGdkRGBAToTColor(const value: TGdkRGBA): TColor;
begin
  Result := Trunc(value.red * $FF)
         or (Trunc(value.green * $FF) shl  8)
         or (Trunc(value.blue * $FF) shl  16)
         or (Trunc(value.alpha * $FF) shl  24);
end;

function TColortoTGdkRGBA(const value: TColor; IgnoreAlpha: Boolean = True): TGdkRGBA;
begin
  Result.red := (value and $FF) / 255;
  Result.green := ((value shr 8) and $FF) / 255;
  Result.blue := ((value shr 16) and $FF) / 255;
  if not IgnoreAlpha then
    Result.alpha := ((value shr 24) and $FF) / 255
  else
    Result.alpha:=1;
end;

function ColorToCairoRGB(AColor: TColor; out ARed, AGreen, ABlue: Double): Boolean;
begin
  Result := True;
  ARed := (AColor and $FF) / 255;
  AGreen := ((AColor shr 8) and $FF) / 255;
  ABlue := ((AColor shr 16) and $FF) / 255;
end;

function RectFromGtkAllocation(AGtkAllocation: TGtkAllocation): TRect;
begin
  with AGtkAllocation do
  begin
    Result.Left := x;
    Result.Top := y;
    Result.Right := Width + x;
    Result.Bottom := Height + y;
  end;
end;

function RectFromGdkRect(AGdkRect: TGdkRectangle): TRect;
begin
  with AGdkRect do
  begin
    Result.Left := x;
    Result.Top := y;
    Result.Right := Width + x;
    Result.Bottom := Height + y;
  end;
end;

function RectFromPangoRect(APangoRect: TPangoRectangle): TRect;
begin
  with APangoRect do
  begin
    Result.Left := PANGO_PIXELS(x);
    Result.Top := PANGO_PIXELS(y);
    Result.Right := PANGO_PIXELS(Width+x);
    Result.Bottom := PANGO_PIXELS(Height+y);
  end;
end;

function GdkRectFromRect(R: TRect): TGdkRectangle;
begin
  with Result do
  begin
    x := R.Left;
    y := R.Top;
    width := R.Right-R.Left;
    height := R.Bottom-R.Top;
  end;
end;

function GtkAllocationFromRect(R: TRect): TGtkAllocation;
begin
  with Result do
  begin
    x := R.Left;
    y := R.Top;
    width := R.Right-R.Left;
    height := R.Bottom-R.Top;
  end;
end;

function Gtk4IsObject(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), g_object_get_type);
end;

function Gtk4IsButton(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_button_get_type);
end;

function Gtk4IsCellView(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_cell_view_get_type);
end;

function Gtk4IsComboBox(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_combo_box_get_type);
end;

function Gtk4IsEntry(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_entry_get_type);
end;

function Gtk4IsEditable(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_editable_get_type);
end;

function Gtk4IsTextView(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_text_view_get_type);
end;

function Gtk4IsBox(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_box_get_type);
end;

function Gtk4IsFixed(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_fixed_get_type);
end;

function Gtk4IsLayout(AWidget: PGObject): GBoolean;
begin
  { GTK4: GtkLayout removed. Check for GtkFixed instead. }
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_fixed_get_type);
end;

function Gtk4IsNoteBook(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_notebook_get_type);
end;

function Gtk4IsMenu(AWidget: PGObject): GBoolean;
begin
  { GTK4: GtkMenu removed. Check for GtkPopoverMenu instead. }
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_popover_menu_get_type);
end;

function Gtk4IsMenuBar(AWidget: PGObject): GBoolean;
begin
  { GTK4: GtkMenuBar removed. Check for GtkPopoverMenuBar instead. }
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk4_popover_menu_bar_get_type);
end;

function Gtk4IsHScrollbar(AWidget: PGObject): GBoolean;
begin
  { GTK4: GtkHScrollbar removed. Check for GtkScrollbar. }
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_scrollbar_get_type);
end;

function Gtk4IsVScrollbar(AWidget: PGObject): GBoolean;
begin
  { GTK4: GtkVScrollbar removed. Check for GtkScrollbar. }
  Result := (AWidget <> nil) and g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_scrollbar_get_type);
end;

function Gtk4IsScrolledWindow(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_scrolled_window_get_type);
end;

function Gtk4IsSpinButton(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_spin_button_get_type);
end;

function Gtk4IsViewPort(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_viewport_get_type);
end;

function Gtk4IsWidget(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_widget_get_type);
end;

function Gtk4IsGtkWindow(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gtk_window_get_type);
end;

function Gtk4IsGdkPixbuf(AWidget: PGObject): GBoolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), gdk_pixbuf_get_type);
end;

function Gtk4WidgetIsA(AWidget: PGtkWidget; AType: TGType): boolean;
begin
  Result := (AWidget <> nil) and  g_type_check_instance_is_a(PGTypeInstance(AWidget), AType);
end;

function Get3WidgetClassName(AWidget: PGtkWidget): string;
var
  ClassPGChar: Pgchar;
  ClassLen: Integer;
begin
  Result:='';
  if AWidget=nil then begin
    Result:='nil';
    exit;
  end;
  ClassPGChar:=g_type_name_from_instance(PGTypeInstance(AWidget));
  if ClassPGChar=nil then begin
    Result:='<Widget without classname>';
    exit;
  end;
  ClassLen:=strlen(ClassPGChar);
  SetLength(Result,ClassLen);
  if ClassLen>0 then
    Move(ClassPGChar[0],Result[1],ClassLen);
end;

function Gtk4IsPangoContext(APangoContext: PGObject): GBoolean;
begin
  Result := (APangoContext <> nil) and  g_type_check_instance_is_a(PGTypeInstance(APangoContext), pango_context_get_type);
end;

function Gtk4IsPangoFontMetrics(APangoFontMetrics: PGObject): GBoolean;
begin
  Result := (APangoFontMetrics <> nil);//  and  g_type_check_instance_is_a(PGTypeInstance(APangoFontMetrics), pango_font_metrics_get_type);
end;

function Gtk4TranslateScrollStyle(const SS: TScrollStyle): TGtkScrollStyle;
  function return(Horiz, Vert: TGtkPolicyType): TGtkScrollStyle;
  begin
    with Result do begin
	  Horizontal := Horiz;
	  Vertical := Vert;
	end;
  end;
begin
  with Result do begin
    Horizontal := GTK_POLICY_AUTOMATIC;
	Vertical := GTK_POLICY_AUTOMATIC;
  end;
  case SS of
    ssAutoBoth: return(GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    ssAutoHorizontal: return(GTK_POLICY_AUTOMATIC, GTK_POLICY_NEVER);
    ssAutoVertical: return(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
    ssBoth: return(GTK_POLICY_ALWAYS, GTK_POLICY_ALWAYS);
    ssHorizontal: return(GTK_POLICY_ALWAYS, GTK_POLICY_NEVER);
    ssNone: return(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
    ssVertical: return(GTK_POLICY_NEVER, GTK_POLICY_ALWAYS);
  end;
end;

function Gtk4ScrollTypeToScrollCode(ScrollType: TGtkScrollType): LongWord;
begin
  case ScrollType of
    GTK_SCROLL_NONE {0}           : Result := SB_ENDSCROLL;
    GTK_SCROLL_JUMP {1}           : Result := SB_THUMBTRACK;
    GTK_SCROLL_STEP_BACKWARD {2}  : Result := SB_LINELEFT;
    GTK_SCROLL_STEP_FORWARD {3}   : Result := SB_LINERIGHT;
    GTK_SCROLL_PAGE_BACKWARD {4}  : Result := SB_PAGELEFT;
    GTK_SCROLL_PAGE_FORWARD {5}   : Result := SB_PAGERIGHT;
    GTK_SCROLL_STEP_UP {6}        : Result := SB_LINEUP;
    GTK_SCROLL_STEP_DOWN {7}      : Result := SB_LINEDOWN;
    GTK_SCROLL_PAGE_UP {8}        : Result := SB_PAGEUP;
    GTK_SCROLL_PAGE_DOWN {9}      : Result := SB_PAGEDOWN;
    GTK_SCROLL_STEP_LEFT {10}      : Result := SB_LINELEFT;
    GTK_SCROLL_STEP_RIGHT {11}     : Result := SB_LINERIGHT;
    GTK_SCROLL_PAGE_LEFT {12}      : Result := SB_PAGELEFT;
    GTK_SCROLL_PAGE_RIGHT {13}     : Result := SB_PAGERIGHT;
    GTK_SCROLL_START {14}          : Result := SB_TOP;
    GTK_SCROLL_END {15}            : Result := SB_BOTTOM;
  end;
end;

function TGDKColorToTColor(const value : TGDKColor) : TColor;
begin
  Result := ((Value.Blue shr 8) shl 16) + ((Value.Green shr 8) shl 8)
           + (Value.Red shr 8);
end;

function TColorToTGDKColor(const value : TColor) : TGDKColor;
begin
  if Value<0 then
  begin
    Result.blue := $FF;
    Result.red := $FF;
    Result.green := $FF;
    Result.pixel := 0;
    exit;
  end;
  with Result do
  begin
    pixel := 0;
    red   := (value and $ff) * 257;
    green := ((value shr 8) and $ff) * 257;
    blue  := ((value shr 16) and $ff) * 257;
  end;
end;

function GdkKeyToLCLKey(AValue: Word): Word;
begin
  if AValue <= $FF then
    exit(AValue);
  Result := VK_UNKNOWN;
  case AValue of
    GDK_KEY_Return, GDK_KEY_KP_Enter, GDK_KEY_3270_Enter: Result := VK_RETURN;
    GDK_KEY_Escape: Result := VK_ESCAPE;
    GDK_KEY_BackSpace: Result := VK_BACK;
    GDK_KEY_Home, GDK_KEY_KP_Home: Result := VK_HOME;
    GDK_KEY_End, GDK_KEY_KP_End: Result := VK_END;
    GDK_KEY_Page_Up, GDK_KEY_KP_Page_Up: Result := VK_PRIOR;
    GDK_KEY_Page_Down, GDK_KEY_KP_Page_Down: Result := VK_NEXT;
    GDK_KEY_Insert, GDK_KEY_KP_Insert: Result := VK_INSERT;
    GDK_KEY_Delete, GDK_KEY_KP_Delete: Result := VK_DELETE;
    GDK_KEY_Left, GDK_KEY_KP_Left: Result := VK_LEFT;
    GDK_KEY_Up, GDK_KEY_KP_Up: Result := VK_UP;
    GDK_KEY_Right, GDK_KEY_KP_Right: Result := VK_RIGHT;
    GDK_KEY_Down, GDK_KEY_KP_Down: Result := VK_DOWN;
    GDK_KEY_Menu: Result := VK_APPS;
    GDK_KEY_Tab, GDK_KEY_3270_BackTab, GDK_KEY_ISO_Left_Tab, GDK_KEY_KP_Tab: Result := VK_TAB;
    GDK_KEY_Shift_L, GDK_KEY_Shift_R: Result := VK_SHIFT;
    GDK_KEY_Control_L, GDK_KEY_Control_R: Result := VK_CONTROL;
    GDK_KEY_Num_Lock: Result := VK_NUMLOCK;
    GDK_KEY_KP_0 .. GDK_KEY_KP_9:
      Result := VK_NUMPAD0 + (AValue - GDK_KEY_KP_0);
    GDK_KEY_KP_Multiply: Result := VK_MULTIPLY;
    GDK_KEY_KP_Add: Result := VK_ADD;
    GDK_KEY_KP_Separator: Result := VK_SEPARATOR;
    GDK_KEY_KP_Subtract: Result := VK_SUBTRACT;
    GDK_KEY_KP_Decimal: Result := VK_DECIMAL;
    GDK_KEY_KP_Divide: Result := VK_DIVIDE;
    GDK_KEY_KP_Space, GDK_KEY_KP_Begin: Result := VK_CLEAR;
    GDK_KEY_KP_F1 .. GDK_KEY_KP_F4:
      Result := VK_F1 + (AValue - GDK_KEY_KP_F1);
    GDK_KEY_F1 .. GDK_KEY_F30:
      Result:= VK_F1 + (AValue - GDK_KEY_F1);
  end;
end;

function LCLKeyToGdkKeyval(AVK: Word): guint;
begin
  case AVK of
    VK_BACK:       Result := GDK_KEY_BackSpace;
    VK_TAB:        Result := GDK_KEY_Tab;
    VK_RETURN:     Result := GDK_KEY_Return;
    VK_ESCAPE:     Result := GDK_KEY_Escape;
    VK_DELETE:     Result := GDK_KEY_Delete;
    VK_INSERT:     Result := GDK_KEY_Insert;
    VK_HOME:       Result := GDK_KEY_Home;
    VK_END:        Result := GDK_KEY_End;
    VK_PRIOR:      Result := GDK_KEY_Page_Up;
    VK_NEXT:       Result := GDK_KEY_Page_Down;
    VK_LEFT:       Result := GDK_KEY_Left;
    VK_UP:         Result := GDK_KEY_Up;
    VK_RIGHT:      Result := GDK_KEY_Right;
    VK_DOWN:       Result := GDK_KEY_Down;
    VK_SPACE:      Result := GDK_KEY_space;
    VK_APPS:       Result := GDK_KEY_Menu;
    VK_NUMPAD0..VK_NUMPAD9: Result := GDK_KEY_KP_0 + (AVK - VK_NUMPAD0);
    VK_MULTIPLY:   Result := GDK_KEY_KP_Multiply;
    VK_ADD:        Result := GDK_KEY_KP_Add;
    VK_SEPARATOR:  Result := GDK_KEY_KP_Separator;
    VK_SUBTRACT:   Result := GDK_KEY_KP_Subtract;
    VK_DECIMAL:    Result := GDK_KEY_KP_Decimal;
    VK_DIVIDE:     Result := GDK_KEY_KP_Divide;
    VK_NUMLOCK:    Result := GDK_KEY_Num_Lock;
    VK_F1..VK_F24: Result := GDK_KEY_F1 + (AVK - VK_F1);
    VK_A..VK_Z:   Result := Ord('a') + (AVK - VK_A);
    VK_0..VK_9:   Result := Ord('0') + (AVK - VK_0);
    VK_OEM_PLUS:   Result := Ord('+');
    VK_OEM_MINUS:  Result := Ord('-');
    VK_OEM_COMMA:  Result := Ord(',');
    VK_OEM_PERIOD: Result := Ord('.');
  else
    if AVK <= $FF then
      Result := AVK
    else
      Result := 0;
  end;
end;

function ShiftStateToGdkMods(AShift: TShiftState): TGdkModifierType;
begin
  Result := [];
  if ssShift in AShift then Include(Result, GDK_SHIFT_MASK);
  if ssCtrl in AShift then Include(Result, GDK_CONTROL_MASK);
  if ssAlt in AShift then Include(Result, GDK_META_MASK);
end;

function GdkModifierStateToLCL(AState: TGdkModifierType; const AIsKeyEvent: Boolean): PtrInt;
begin
  Result := 0;
  if GDK_BUTTON1_MASK in AState  then
    Result := Result or MK_LBUTTON;

  if GDK_BUTTON2_MASK in AState  then
    Result := Result or MK_MBUTTON;

  if GDK_BUTTON3_MASK in AState  then
    Result := Result or MK_RBUTTON;

  if GDK_BUTTON4_MASK in AState  then
    Result := Result or MK_XBUTTON1;

  if GDK_BUTTON5_MASK in AState  then
    Result := Result or MK_XBUTTON2;

  if GDK_SHIFT_MASK in AState  then
    Result := Result or MK_SHIFT;

  if GDK_CONTROL_MASK in AState  then
    Result := Result or MK_CONTROL;

  if GDK_META_MASK in AState  then
    Result := Result or MK_ALT;
end;

function GdkModifierStateToShiftState(AState: TGdkModifierType): TShiftState;
begin
  Result := [];
  if GDK_BUTTON1_MASK in AState  then
    Include(Result, ssLeft);

  if GDK_BUTTON2_MASK in AState  then
    Include(Result, ssMiddle);

  if GDK_BUTTON3_MASK in AState  then
    Include(Result, ssRight);

  if GDK_BUTTON4_MASK in AState  then
    Include(Result, ssExtra1);

  if GDK_BUTTON5_MASK in AState  then
    Include(Result, ssExtra2);

  if GDK_SHIFT_MASK in AState  then
    Include(Result, ssShift);

  if GDK_CONTROL_MASK in AState  then
    Include(Result, ssCtrl);

  if GDK_META_MASK in AState  then
    Include(Result, ssAlt);

  if GDK_LOCK_MASK in AState  then
    Include(Result, ssCaps);

  if GDK_MOD2_MASK in AState  then
    Include(Result, ssNum);
end;

procedure AddCharsetEncoding(CharSet: Byte; CharSetReg, CharSetCod: CharSetStr;
  ToEnum:boolean=true; CrPart:boolean=false; CcPart:boolean=false);
var
  Rec: PCharsetEncodingRec;
begin
   New(Rec);
   Rec^.Charset := CharSet;
   Rec^.CharsetReg := CharSetReg;
   Rec^.CharsetCod := CharSetCod;
   Rec^.EnumMap := ToEnum;
   Rec^.CharsetRegPart := CrPart;
   Rec^.CharsetCodPart := CcPart;
   CharSetEncodingList.Add(Rec);
end;

procedure ClearCharsetEncodings;
var
  Rec: PCharsetEncodingRec;
  i: Integer;
begin
  for i:=0 to CharsetEncodingList.Count-1 do
  begin
    Rec := CharsetEncodingList[i];
    if Rec<>nil then
      Dispose(Rec);
  end;
  CharsetEncodingList.Clear;
end;

procedure CreateDefaultCharsetEncodings;
begin
  ClearCharsetEncodings;

  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '1',    false);
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '3',    false);
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '15',   false);
  AddCharsetEncoding(ANSI_CHARSET,        'ansi',     '0');
  AddCharsetEncoding(ANSI_CHARSET,        '*',        'cp1252');
  AddCharsetEncoding(ANSI_CHARSET,        'iso8859',  '*');
  AddCharsetEncoding(DEFAULT_CHARSET,     '*',        '*');
  AddCharsetEncoding(SYMBOL_CHARSET,      '*',        'fontspecific');
  AddCharsetEncoding(MAC_CHARSET,         '*',        'cp10000');
  AddCharsetEncoding(SHIFTJIS_CHARSET,    'jis',      '0',    true, true);
  AddCharsetEncoding(SHIFTJIS_CHARSET,    '*',        'cp932');
  AddCharsetEncoding(HANGEUL_CHARSET,     '*',        'cp949');
  AddCharsetEncoding(JOHAB_CHARSET,       '*',        'cp1361');
  AddCharsetEncoding(GB2312_CHARSET,      'gb2312',   '0',    true, true);
  AddCharsetEncoding(CHINESEBIG5_CHARSET, 'big5',     '0',    true, true);
  AddCharsetEncoding(CHINESEBIG5_CHARSET, '*',        'cp950');
  AddCharsetEncoding(GREEK_CHARSET,       'iso8859',  '7');
  AddCharsetEncoding(GREEK_CHARSET,       '*',        'cp1253');
  AddCharsetEncoding(TURKISH_CHARSET,     'iso8859',  '9');
  AddCharsetEncoding(TURKISH_CHARSET,     '*',        'cp1254');
  AddCharsetEncoding(VIETNAMESE_CHARSET,  '*',        'cp1258');
  AddCharsetEncoding(HEBREW_CHARSET,      'iso8859',  '8');
  AddCharsetEncoding(HEBREW_CHARSET,      '*',        'cp1255');
  AddCharsetEncoding(ARABIC_CHARSET,      'iso8859',  '6');
  AddCharsetEncoding(ARABIC_CHARSET,      '*',        'cp1256');
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '13');
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '4');  // northern europe
  AddCharsetEncoding(BALTIC_CHARSET,      'iso8859',  '14'); // CELTIC_CHARSET
  AddCharsetEncoding(BALTIC_CHARSET,      '*',        'cp1257');
  AddCharsetEncoding(RUSSIAN_CHARSET,     'iso8859',  '5');
  AddCharsetEncoding(RUSSIAN_CHARSET,     'koi8',     '*');
  AddCharsetEncoding(RUSSIAN_CHARSET,     '*',        'cp1251');
  AddCharsetEncoding(THAI_CHARSET,        'iso8859',  '11');
  AddCharsetEncoding(THAI_CHARSET,        'tis620',   '*',  true, true);
  AddCharsetEncoding(THAI_CHARSET,        '*',        'cp874');
  AddCharsetEncoding(EASTEUROPE_CHARSET,  'iso8859',  '2');
  AddCharsetEncoding(EASTEUROPE_CHARSET,  '*',        'cp1250');
  AddCharsetEncoding(OEM_CHARSET,         'ascii',    '0');
  AddCharsetEncoding(OEM_CHARSET,         'iso646',   '*',  true, true);
  AddCharsetEncoding(FCS_ISO_10646_1,     'iso10646', '1');
  AddCharsetEncoding(FCS_ISO_8859_1,      'iso8859',  '1');
  AddCharsetEncoding(FCS_ISO_8859_2,      'iso8859',  '2');
  AddCharsetEncoding(FCS_ISO_8859_3,      'iso8859',  '3');
  AddCharsetEncoding(FCS_ISO_8859_4,      'iso8859',  '4');
  AddCharsetEncoding(FCS_ISO_8859_5,      'iso8859',  '5');
  AddCharsetEncoding(FCS_ISO_8859_6,      'iso8859',  '6');
  AddCharsetEncoding(FCS_ISO_8859_7,      'iso8859',  '7');
  AddCharsetEncoding(FCS_ISO_8859_8,      'iso8859',  '8');
  AddCharsetEncoding(FCS_ISO_8859_9,      'iso8859',  '9');
  AddCharsetEncoding(FCS_ISO_8859_10,     'iso8859',  '10');
  AddCharsetEncoding(FCS_ISO_8859_15,     'iso8859',  '15');
end;

function Gtk4CharSetToPangoLanguage(ACharSet: Byte): PPangoLanguage;
begin
  case ACharSet of
    RUSSIAN_CHARSET:
      Result := pango_language_from_string(PgChar('ru'));
    GREEK_CHARSET:
      Result := pango_language_from_string(PgChar('el'));
    HEBREW_CHARSET:
      Result := pango_language_from_string(PgChar('he'));
    ARABIC_CHARSET:
      Result := pango_language_from_string(PgChar('ar'));
    THAI_CHARSET:
      Result := pango_language_from_string(PgChar('th'));
    SHIFTJIS_CHARSET:
      Result := pango_language_from_string(PgChar('ja'));
    HANGEUL_CHARSET:
      Result := pango_language_from_string(PgChar('ko'));
    GB2312_CHARSET:
      Result := pango_language_from_string(PgChar('zh-cn'));
    CHINESEBIG5_CHARSET:
      Result := pango_language_from_string(PgChar('zh-tw'));
    TURKISH_CHARSET:
      Result := pango_language_from_string(PgChar('tr'));
    VIETNAMESE_CHARSET:
      Result := pango_language_from_string(PgChar('vi'));
  else
    Result := nil;
  end;
end;

function IndexOfStyleWithName(const WName : String): integer;
begin
  if Styles<>nil then
  begin
    for Result := 0 to Styles.Count-1 do
      if CompareText(WName, Styles[Result]) = 0 then
        exit;
  end;
  Result:=-1;
end;

function NewStyleObject: PStyleObject;
begin
  New(Result);
  FillChar(Result^, SizeOf(TStyleObject), 0);
end;

{ GTK4: Extract system colors from CSS theme via GtkStyleContext.
  Uses lookup_color for standard CSS named colors defined by GTK themes (Adwaita etc.),
  and get_color with state flags for foreground/text colors. }
procedure UpdateSysColorMap(Widget: PGtkWidget; Lgs: TLazGtkStyle);

  function LookupColor(ctx: PGtkStyleContext; const AName: PgChar): TColor;
  var
    rgba: TGdkRGBA;
  begin
    if gtk_style_context_lookup_color(ctx, AName, @rgba) then
      Result := TGdkRGBAToTColor(rgba) and $00FFFFFF
    else
      Result := -1; { not found }
  end;

  function GetFgColor(ctx: PGtkStyleContext): TColor;
  var
    rgba: TGdkRGBA;
  begin
    { GTK4: get_color no longer takes state flags }
    ctx^.get_color(@rgba);
    Result := TGdkRGBAToTColor(rgba) and $00FFFFFF;
  end;

var
  ctx: PGtkStyleContext;
  c: TColor;
begin
  if Widget = nil then exit;
  if not (Lgs in [lgsButton, lgsWindow, lgsMenuBar, lgsMenuitem,
    lgsVerticalScrollbar, lgsHorizontalScrollbar, lgsTooltip]) then exit;

  ctx := gtk_widget_get_style_context(Widget);
  if ctx = nil then exit;

  case Lgs of
    lgsButton:
    begin
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_BTNFACE]        := c;
        SysColorMap[COLOR_ACTIVEBORDER]   := c;
        SysColorMap[COLOR_INACTIVEBORDER] := c;
        SysColorMap[COLOR_3DLIGHT]        := c;
      end;
      c := LookupColor(ctx, 'theme_fg_color');
      if c >= 0 then
        SysColorMap[COLOR_BTNTEXT] := c;
      c := LookupColor(ctx, 'insensitive_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_BTNHIGHLIGHT] := c;
      c := LookupColor(ctx, 'borders');
      if c >= 0 then
      begin
        SysColorMap[COLOR_BTNSHADOW]  := c;
        SysColorMap[COLOR_WINDOWFRAME]:= c;
        SysColorMap[COLOR_3DDKSHADOW] := c;
      end;
    end;
    lgsWindow:
    begin
      c := LookupColor(ctx, 'theme_base_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_WINDOW]       := c;
        SysColorMap[COLOR_APPWORKSPACE] := c;
        SysColorMap[COLOR_GRADIENTINACTIVECAPTION] := c;
      end;
      c := LookupColor(ctx, 'theme_text_color');
      if c >= 0 then
        SysColorMap[COLOR_WINDOWTEXT] := c;
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_FORM]       := c;
        SysColorMap[COLOR_BACKGROUND] := c;
      end;
      c := LookupColor(ctx, 'theme_selected_bg_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_HIGHLIGHT]                := c;
        SysColorMap[COLOR_ACTIVECAPTION]            := c;
        SysColorMap[COLOR_HOTLIGHT]                 := c;
        SysColorMap[COLOR_GRADIENTACTIVECAPTION]    := c;
        SysColorMap[COLOR_MENUHILIGHT]              := c;
      end;
      c := LookupColor(ctx, 'theme_selected_fg_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_HIGHLIGHTTEXT]     := c;
        SysColorMap[COLOR_CAPTIONTEXT]       := c;
      end;
      c := LookupColor(ctx, 'insensitive_fg_color');
      if c >= 0 then
      begin
        SysColorMap[COLOR_GRAYTEXT]             := c;
        SysColorMap[COLOR_INACTIVECAPTIONTEXT]  := c;
      end;
      c := LookupColor(ctx, 'insensitive_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_INACTIVECAPTION] := c;
    end;
    lgsMenuBar:
    begin
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_MENUBAR] := c;
    end;
    lgsMenuitem:
    begin
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_MENU] := c;
      c := LookupColor(ctx, 'theme_fg_color');
      if c >= 0 then
        SysColorMap[COLOR_MENUTEXT] := c;
      c := LookupColor(ctx, 'theme_selected_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_MENUHILIGHT] := c;
    end;
    lgsVerticalScrollbar,
    lgsHorizontalScrollbar:
    begin
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_SCROLLBAR] := c;
    end;
    lgsTooltip:
    begin
      { Adwaita 4.6 does not define tooltip named colors. Use get_color for
        the foreground and default yellow for background as fallback. }
      SysColorMap[COLOR_INFOTEXT] := GetFgColor(ctx);
      c := LookupColor(ctx, 'theme_bg_color');
      if c >= 0 then
        SysColorMap[COLOR_INFOBK] := c;
    end;
  end;
end;

{ GTK3 UpdateSysColorMap_GTK3 removed. GTK4 uses GtkStyleContext + CSS.
  See UpdateSysColorMap above for the GTK4 implementation. }

function GetStyleWithName(const WName: String): PStyleObject;
var
  StyleObject : PStyleObject;
  AIndex: Integer;
  lgs: TLazGtkStyle;
  WidgetName: String;
  AModel: PGMenuModel;
begin
  Result := nil;
  if (WName='') then exit;
  AIndex := IndexOfStyleWithName(WName);
  if AIndex >= 0 then
  begin
    Result := PStyleObject(Styles.Objects[AIndex]);
  end else
  begin
    StyleObject := NewStyleObject;
    Result:=StyleObject;
    lgs := lgsUserDefined;
    WidgetName := 'LazStyle' + WName;
    if CompareText(WName, LazGtkStyleNames[lgsButton]) = 0 then
    begin
      StyleObject^.Widget := TGtkButton.new;
      lgs := lgsButton;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsNotebook]) = 0 then
    begin
      StyleObject^.Widget := TGtkNoteBook.new;
      lgs := lgsNotebook;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsWindow]) = 0 then
    begin
      { GTK4: gtk_window_new takes no args }
      StyleObject^.Widget := gtk4_window_new;
      lgs := lgsWindow;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsTreeView]) = 0 then
    begin
      StyleObject^.Widget := TGtkTreeView.new;
      lgs := lgsTreeView;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsMemo]) = 0 then
    begin
      StyleObject^.Widget := TGtkTextView.new;
      lgs := lgsMemo;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsFrame]) = 0 then
    begin
      StyleObject^.Widget := TGtkFixed.new;
      lgs := lgsFrame;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsVerticalScrollbar]) = 0 then
    begin
      StyleObject^.Widget := TGtkScrollbar.new(GTK_ORIENTATION_VERTICAL, nil);
      lgs := lgsVerticalScrollbar;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsHorizontalScrollbar]) = 0 then
    begin
      StyleObject^.Widget := TGtkScrollbar.new(GTK_ORIENTATION_HORIZONTAL, nil);
      lgs := lgsHorizontalScrollbar;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsMenuBar]) = 0 then
    begin
      { GTK4: GtkPopoverMenuBar expects a valid GMenuModel. }
      AModel := PGMenuModel(g_menu_new);
      StyleObject^.Widget := gtk4_popover_menu_bar_new_from_model(AModel);
      if (AModel <> nil) and Gtk4IsObject(PGObject(AModel)) then
        g_object_unref(PGObject(AModel));
      lgs := lgsMenuBar;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsMenu]) = 0 then
    begin
      { GTK4: GtkPopoverMenu expects a valid GMenuModel. }
      AModel := PGMenuModel(g_menu_new);
      StyleObject^.Widget := gtk4_popover_menu_new_from_model(AModel);
      if (AModel <> nil) and Gtk4IsObject(PGObject(AModel)) then
        g_object_unref(PGObject(AModel));
      lgs := lgsMenu;
    end else
    if CompareText(WName, LazGtkStyleNames[lgsMenuitem]) = 0 then
    begin
      { GTK4: GtkMenuItem removed. Use GtkButton as style proxy. }
      StyleObject^.Widget := TGtkButton.new;
      lgs := lgsMenuItem;
    end else
    begin
    end;
    if Gtk4IsWidget(StyleObject^.Widget) then
    begin
      StyleObject^.Widget^.set_name(PgChar(WidgetName));
      { GTK4: Do not realize/show detached probe widgets.
        Realizing a widget without a toplevel triggers criticals and can
        destabilize subsequent painting/state queries. }
      Styles.AddObject(WName, TObject(StyleObject));
      if lgs <> lgsUserDefined then
        StandardStyles[lgs] := StyleObject;

      UpdateSysColorMap(StyleObject^.Widget, lgs);
    end else
    begin
    end;
  end;
end;

function GetStyleWidgetWithName(const WName : String) : PGtkWidget;
var
  aStyle: PStyleObject;
begin
  aStyle := GetStyleWithName(WName);
  if aStyle<>nil then
    Result:=aStyle^.Widget
  else
    Result:=nil;
end;

function GetStyleWidget(aStyle: TLazGtkStyle) : PGtkWidget;
begin
  if aStyle in [lgsUserDefined] then
    raise Exception.Create('Gtk4: user styles are defined by name');

  if StandardStyles[aStyle]<>nil then
    // already created
    Result := StandardStyles[aStyle]^.Widget
  else
    // create it
    Result := GetStyleWidgetWithName(LazGtkStyleNames[aStyle]);
end;

procedure FreeStyleObject(var StyleObject : PStyleObject);
// internal function to dispose a styleobject
// it does *not* remove it from the style lists
begin
  if StyleObject <> nil then
  begin
    if (StyleObject^.Owner <> nil) and Gtk4IsObject(StyleObject^.Owner) then
    begin
      // GTK owns the reference to top level widgets created by application,
      // so they cannot be destroyed by unreferencing.
      { GTK4: gtk_widget_destroy removed. Use g_object_unref. }
      g_object_unref(StyleObject^.Owner);
    end;
    Dispose(StyleObject);
    StyleObject := nil;
  end;
end;

procedure ReleaseAllStyles;
var
  StyleObject: PStyleObject;
  lgs: TLazGtkStyle;
  i: Integer;
begin
  if Styles = nil then
    exit;
  for i:=Styles.Count-1 downto 0 do
  begin
    StyleObject := PStyleObject(Styles.Objects[i]);
    FreeStyleObject(StyleObject);
  end;
  Styles.Clear;
  for lgs:=Low(TLazGtkStyle) to High(TLazGtkStyle) do
    StandardStyles[lgs]:=nil;
end;

{------------------------------------------------------------------------------
  procedure: SetWindowCursor
  Params:  AWindow : PGDkWindow, ACursor: PGdkCursor, ASetDefault: Boolean
  Returns: Nothing

  Sets the cursor for a window.
  Tries to avoid messing with the cursors of implicitly created
  child windows (e.g. headers in TListView) with the following logic:
  - If Cursor <> nil, saves the old cursor (if not already done or ASetDefault = true)
    before setting the new one.
  - If Cursor = nil, restores the old cursor (if not already done).
  ------------------------------------------------------------------------------}
{ GTK4: gdk_window_set_cursor, gdk_window_get_cursor, gdk_window_get_children removed.
  Cursor handling in GTK4 uses gtk_widget_set_cursor.
  Stubbed for Phase 1. }
procedure SetWindowCursor(AWindow: PGdkWindow; ACursor: HCursor;
  ARecursive: Boolean; ASetDefault: Boolean);
begin
  { GTK4: GdkWindow cursor API removed. Per-widget cursors are set
    via TGtk4Widget.SetCursor using gtk_widget_set_cursor. }
  if AWindow=nil then ;
  if ACursor=0 then ;
  if ARecursive then ;
  if ASetDefault then ;
end;

procedure SetGlobalCursor(Cursor: HCURSOR);
var
  AList, AItem: PGList;
begin
  { GTK4: Set cursor on all toplevel windows }
  AList := gtk_window_list_toplevels;
  AItem := AList;
  while AItem <> nil do
  begin
    if AItem^.Data <> nil then
      gtk4_widget_set_cursor(PGtkWidget(AItem^.Data), PGdkCursor(Cursor));
    AItem := AItem^.Next;
  end;
  g_list_free(AList);
end;

{ ------------------------------------------------------------------------------
  Per-GType visual overflow cache
  GTK4 CSS effects (box-shadow etc.) extend outside widget allocation bounds.
  We cache the measured overflow per GType so each widget type is measured once.
  ------------------------------------------------------------------------------}

function GetGTypeOverflow(AType: GType; out ATop, ABottom, ALeft, ARight: Integer): Boolean;
var
  i: Integer;
begin
  for i := 0 to GTypeOverflowCacheCount - 1 do
    if GTypeOverflowCache[i].WidgetGType = AType then
    begin
      ATop := GTypeOverflowCache[i].Top;
      ABottom := GTypeOverflowCache[i].Bottom;
      ALeft := GTypeOverflowCache[i].Left;
      ARight := GTypeOverflowCache[i].Right;
      Result := True;
      Exit;
    end;
  ATop := 0;
  ABottom := 0;
  ALeft := 0;
  ARight := 0;
  Result := False;
end;

procedure SetGTypeOverflow(AType: GType; ATop, ABottom, ALeft, ARight: Integer);
var
  i: Integer;
begin
  { Update existing entry if present }
  for i := 0 to GTypeOverflowCacheCount - 1 do
    if GTypeOverflowCache[i].WidgetGType = AType then
    begin
      GTypeOverflowCache[i].Top := ATop;
      GTypeOverflowCache[i].Bottom := ABottom;
      GTypeOverflowCache[i].Left := ALeft;
      GTypeOverflowCache[i].Right := ARight;
      Exit;
    end;
  { Append new entry }
  if GTypeOverflowCacheCount >= Length(GTypeOverflowCache) then
    SetLength(GTypeOverflowCache, GTypeOverflowCacheCount + 16);
  GTypeOverflowCache[GTypeOverflowCacheCount].WidgetGType := AType;
  GTypeOverflowCache[GTypeOverflowCacheCount].Top := ATop;
  GTypeOverflowCache[GTypeOverflowCacheCount].Bottom := ABottom;
  GTypeOverflowCache[GTypeOverflowCacheCount].Left := ALeft;
  GTypeOverflowCache[GTypeOverflowCacheCount].Right := ARight;
  Inc(GTypeOverflowCacheCount);
end;

procedure ClearGTypeOverflowCache;
begin
  GTypeOverflowCache := nil;
  GTypeOverflowCacheCount := 0;
end;

end.
