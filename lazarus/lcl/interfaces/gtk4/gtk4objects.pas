{
 *****************************************************************************
 *                             gtk4objects.pas                               *
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
unit Gtk4Objects;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

interface

uses
  Classes, SysUtils, Types, math, FPCanvas,
  // LazUtils
  LazUTF8, IntegerList, LazStringUtils,
  // LCL
  LCLType, LCLProc, LazLoggerBase, LazTracer, Graphics,
  LazGtk4, LazGdk4, LazGObject2, LazGLib2, LazGdkPixbuf2,
  LazPango1, LazPangoCairo1, LazCairo1, gtk4procs;

type
  TGtk4DeviceContext = class;

  { TGtk4Object }

  TGtk4Object = class(TObject)
  private
    FUpdateCount: Integer;
  public
    constructor Create; virtual; overload;
    procedure Release; virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    function InUpdate: Boolean;
  end;

  { TGtk4ContextObject }

  TGtk4ContextObject = class(TGtk4Object)
  private
    FShared: Boolean;
    fContext:TGtk4DeviceContext;
  public
    constructor Create; override;
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;virtual;
    function Get(szbuf:integer;pbuf:pointer):integer;virtual;abstract;
    property Shared: Boolean read FShared write FShared;
  end;

  { TGtk4Font }

  TGtk4Font = class(TGtk4ContextObject)
  private
    FLayout: PPangoLayout;
    FLogFont: TLogFont;
    FFontName: String;
    FHandle: PPangoFontDescription;
    FCachedMetrics: TTextMetric;
    FMetricsValid: Boolean;
  public
    constructor Create(ACairo: Pcairo_t; AWidget: PGtkWidget = nil);
    constructor Create(ALogFont: TLogFont; const ALongFontName: String);
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;override;
    function Get(szbuf:integer;pbuf:pointer):integer;override;
    destructor Destroy; override;
    procedure UpdateLogFont;
    property CachedMetrics: TTextMetric read FCachedMetrics write FCachedMetrics;
    property MetricsValid: Boolean read FMetricsValid write FMetricsValid;
    property FontName: String read FFontName write FFontName;
    property Handle: PPangoFontDescription read FHandle;
    property Layout: PPangoLayout read FLayout;
    property LogFont: TLogFont read FLogFont;
  end;

  { TGtk4Brush }

  TGtk4Brush = class(TGtk4ContextObject)
  private
    FColor: TColor;
    FStyle: LongWord;
    procedure SetColor(AValue: TColor);
    procedure SetStyle(AStyle:longword);
  public
    brush_pattern:pcairo_pattern_t;
    pat_buf:pdword;
    LogBrush: TLogBrush;
    constructor Create; override;
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;override;
    function Get(szbuf:integer;pbuf:pointer):integer;override;
    destructor Destroy;override;
    procedure UpdatePattern;
    property Color: TColor read FColor write SetColor;
    property Context: TGtk4DeviceContext read FContext write FContext;
    property Style: LongWord read FStyle write SetStyle;
  end;

  { TGtk4Pen }

  TGtk4Pen = class(TGtk4ContextObject)
  private
    FCosmetic: Boolean;
    FDashes: array of Double;
    FEndCap: TPenEndCap;
    FJoinStyle: TPenJoinStyle;
    FPenMode: TPenMode;
    FStyle: TFPPenStyle;
    FWidth: Integer;
    FColor: TColor;
    FIsExtPen: Boolean;
    procedure SetColor(AValue: TColor);
    procedure setCosmetic(b: Boolean);
    procedure setWidth(p1: Integer);
  public
    LogPen: TLogPen;
    constructor Create; override;
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;override;
    function Get(szbuf:integer;pbuf:pointer):integer;override;
    procedure SetDashes(ADashes: PDWord; ACount: DWord);
    function GetDashCount: Integer;
    function GetDashArray: PDouble;
    property Color: TColor read FColor write SetColor;
    property Context: TGtk4DeviceContext read FContext write FContext;

    property Cosmetic: Boolean read FCosmetic write SetCosmetic;
    property EndCap: TPenEndCap read FEndCap write FEndCap;
    property IsExtPen: Boolean read FIsExtPen write FIsExtPen;
    property JoinStyle: TPenJoinStyle read FJoinStyle write FJoinStyle;
    property Mode: TPenMode read FPenMode write FPenMode;
    property Style: TFPPenStyle read FStyle write FStyle;
    property Width: Integer read FWidth write SetWidth;
  end;

  { TGtk4Region }

  TGtk4Region = class(TGtk4ContextObject)
  private
    FHandle: Pcairo_region_t;
  public
    property Handle: Pcairo_region_t read FHandle write FHandle;
    constructor Create({%H-}CreateHandle: Boolean); virtual; overload;
    constructor Create({%H-}CreateHandle: Boolean; X1,Y1,X2,Y2: Integer); virtual; overload;
    constructor Create(X1,Y1,X2,Y2,nW,nH: Integer); virtual; overload;
    constructor CreateEllipse(X1,Y1,X2,Y2: Integer); virtual; overload;
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;override;
    function Get(szbuf:integer;pbuf:pointer):integer;override;
    destructor Destroy; override;
    function GetExtents: TRect;
    function ContainsRect(ARect: TRect): Boolean;
    function ContainsPoint(APoint: TPoint): Boolean;
  end;

  { TGtk4Image }

  TGtk4Image = class(TGtk4ContextObject)
  private
    FData: PByte;
    FDataOwner: Boolean;
    FHandle: PGdkPixbuf;
    FFormat : Tcairo_format_t;
  public
    constructor Create; override;
    constructor Create(vHandle: PGdkPixbuf); overload;
    constructor Create(AData: PByte; width: Integer; height: Integer; format: Tcairo_format_t; const ADataOwner: Boolean = False); overload;
    constructor Create(AData: PByte; width: Integer; height: Integer; bytesPerLine: Integer; format: Tcairo_format_t; const ADataOwner: Boolean = False); overload;
    function Select(ACtx:TGtk4DeviceContext):TGtk4ContextObject;override;
    function Get(szbuf:integer;pbuf:pointer):integer;override;
    destructor Destroy; override;
    procedure CopyFrom(AImage: PGdkPixbuf; x, y, w, h: integer);
    function height: Integer;
    function width: Integer;
    function depth: Integer;
    function dotsPerMeterX: Integer;
    function dotsPerMeterY: Integer;
    function bits: PByte;
    function numBytes: LongWord;
    function bytesPerLine: Integer;
    property Format: Tcairo_format_t read FFormat;
    property Handle: PGdkPixbuf read FHandle;
  end;

  { TGtk4DeviceContext }

  TGtk4DeviceContext = class (TGtk4Object)
  private
    FBrush: TGtk4Brush;
    FFont: TGtk4Font;
    FvImage: TGtk4Image;
    FCanRelease: Boolean;
    FSaveDCCount: Integer;
    FCurrentBrush: TGtk4Brush;
    FCurrentFont: TGtk4Font;
    FCurrentImage: TGtk4Image;
    FCurrentTextColor: TColorRef;
    FCurrentRegion: TGtk4Region;
    FOwnsCairo: Boolean;
    FOwnsSurface: Boolean;
    FPen: TGtk4Pen;
    FvClipRect: TRect;
    FCurrentPen: TGtk4Pen;
    FBkMode: Integer;
    FMapMode: Integer;
    FViewPortExt: TPoint;
    FViewPortOrg: TPoint;
    FWindowExt: TPoint;
    FRop2: Integer;
    function GetOffset: TPoint;
    procedure setBrush(AValue: TGtk4Brush);
    procedure SetFont(AValue: TGtk4Font);
    procedure SetOffset(AValue: TPoint);
    procedure setPen(AValue: TGtk4Pen);
    procedure SetvImage(AValue: TGtk4Image);
    function SX(const x: double): Double;
    function SY(const y: double): Double;
    function SX2(const x: double): Double;
    function SY2(const y: double): Double;
    procedure ApplyBrush;
    procedure ApplyFont;
    procedure ApplyPen;
    procedure FillAndStroke;
  public
    CairoSurface: Pcairo_surface_t;
    pcr: Pcairo_t;
    Parent: PGtkWidget;
    Window: PGdkWindow;
    ParentPixmap: PGdkPixbuf;
    fncOrigin:TPoint; // non-client area offsets surface origin
    constructor Create(AWidget: PGtkWidget; const APaintEvent: Boolean = False); virtual;
    constructor Create(AWindow: PGdkWindow; const APaintEvent: Boolean); virtual;
    constructor CreateFromCairo(AWidget: PGtkWidget; ACairo: PCairo_t); virtual;
    destructor Destroy; override;
    procedure CreateObjects;
    procedure DeleteObjects;
  public
    procedure drawPixel(x, y: Integer; AColor: TColor);
    function getPixel(x, y: Integer): TColor;
    procedure drawRect(x1, y1, w, h: Integer; const AFill, ABorder: Boolean);
    procedure drawRoundRect(x, y, w, h, rx, ry: Integer);
    procedure drawText(x, y: Integer; AText: PChar; ALen: Integer);
    procedure drawEllipse(x, y, w, h: Integer; AFill, ABorder: Boolean);
    procedure drawArc(Left, Top, Right, Bottom, Angle1, Angle2: Integer);
    procedure drawChord(Left, Top, Right, Bottom, Angle1, Angle2: Integer; AFill, ABorder: Boolean);
    procedure drawPie(Left, Top, Right, Bottom, Angle1, Angle2: Integer; AFill, ABorder: Boolean);
    procedure drawSurface(targetRect: PRect; Surface: Pcairo_surface_t; sourceRect: PRect;
      mask: PGdkPixBuf; maskRect: PRect);
    procedure drawImage(targetRect: PRect; image: PGdkPixBuf; sourceRect: PRect;
      mask: PGdkPixBuf; maskRect: PRect);
    procedure drawImage1(targetRect: PRect; image: PGdkPixBuf; sourceRect: PRect;
      mask: PGdkPixBuf; maskRect: PRect);
    procedure drawPixmap(p: PPoint; pm: PGdkPixbuf; sr: PRect);
    procedure drawPolyLine(P: PPoint; NumPts: Integer);
    procedure drawPolygon(P: PPoint; NumPts: Integer; FillRule: Integer; AFill,
      ABorder: Boolean);
    procedure drawPolyBezier(P: PPoint; NumPoints: Integer; Filled, Continuous: boolean);
    procedure EllipseArcPath(CX, CY, RX, RY: Double; Angle1, Angle2: Double; Clockwise, Continuous: Boolean);
    procedure eraseRect(ARect: PRect);
    procedure fillRect(ARect: PRect; ABrush: HBRUSH); overload;
    procedure fillRect(x, y, w, h: Integer; ABrush: HBRUSH); overload;
    procedure fillRect(x, y, w, h: Integer); overload;
    function RoundRect(X1, Y1, X2, Y2: Integer; RX, RY: Integer): Boolean;
    function drawFrameControl(arect:TRect;uType,uState:cardinal):boolean;
    function drawFocusRect(const aRect: TRect): boolean;
    function getBpp: integer;
    function getDepth: integer;
    function getDeviceSize: TPoint;
    function LineTo(X, Y: Integer): Boolean;
    function MoveTo(const X, Y: Integer; OldPoint: PPoint): Boolean;
    function SetClipRegion(ARgn: TGtk4Region): Integer;
    procedure SetSourceColor(AColor: TColor);
    procedure SetImage(AImage: TGtk4Image);
    function ResetClip: Integer;
    procedure TranslateCairoToDevice;
    procedure Translate(APoint: TPoint);
    procedure set_antialiasing(aamode:boolean);
    property BkMode: Integer read FBkMode write FBkMode;
    property CanRelease: Boolean read FCanRelease write FCanRelease;
    property SaveDCCount: Integer read FSaveDCCount write FSaveDCCount;
    property CurrentBrush: TGtk4Brush read FCurrentBrush write FCurrentBrush;
    property CurrentFont: TGtk4Font read FCurrentFont write FCurrentFont;
    property CurrentImage: TGtk4Image read FCurrentImage write FCurrentImage;
    property CurrentPen: TGtk4Pen read FCurrentPen write FCurrentPen;
    property CurrentRegion: TGtk4Region read FCurrentRegion;
    property CurrentTextColor: TColorRef read FCurrentTextColor write FCurrentTextColor;
    property Offset: TPoint read GetOffset write SetOffset;
    property OwnsCairo: Boolean read FOwnsCairo;
    property OwnsSurface: Boolean read FOwnsSurface;
    property vBrush: TGtk4Brush read FBrush write setBrush;
    property vClipRect: TRect read FvClipRect write FvClipRect;
    property vFont: TGtk4Font read FFont write SetFont;
    property vImage: TGtk4Image read FvImage write SetvImage;
    property vPen: TGtk4Pen read FPen write setPen;
    property MapMode: Integer read FMapMode write FMapMode;
    property ViewPortExt: TPoint read FViewPortExt write FViewPortExt;
    property ViewPortOrg: TPoint read FViewPortOrg write FViewPortOrg;
    property WindowExt: TPoint read FWindowExt write FWindowExt;
    property Rop2: Integer read FRop2 write FRop2;
  end;

function CheckBitmap(const ABitmap: HBITMAP; const AMethodName: String;
  const AParamName: String = ''): Boolean;
procedure Gtk4WordWrap(DC: HDC; AText: PChar;
  MaxWidthInPixel: integer; out Lines: PPChar; out LineCount: integer);

function Gtk4DefaultContext: TGtk4DeviceContext;
function Gtk4ScreenContext: TGtk4DeviceContext;

function ReplaceAmpersandsWithUnderscores(const S: string): string; inline;
function ReplaceUnderscoresWithAmpersands(const S: string): string; inline;

implementation

uses gtk4int,controls;

const
  PixelOffset = 0.5; // Cairo API needs 0.5 pixel offset to not make blurry lines

const
  Dash_Dash:        array [0..1] of double = (3, 2);              //____ ____
  Dash_Dot:         array [0..1] of double = (1, 2);              //.........
  Dash_DashDot:     array [0..3] of double = (3, 2, 1, 2);        //__ . __ .
  FocusDashPattern: array [0..1] of double = (1, 1);              // focus rect
  Dash_DashDotDot:  array [0..5] of double = (3, 2, 1, 2, 1, 2);  //__ . . __

var
  FDefaultContext: TGtk4DeviceContext = nil;
  FScreenContext: TGtk4DeviceContext = nil;

  function create_stipple(stipple_data:pbyte;width,height:integer):pcairo_pattern_t;forward;

  const clr_A = $FF008000;// $3093BA52;
  const clr_B = $FFFFFFFF;// $30FFFFFF;

  const
        (* the stipple patten should look like that
         *	    1 1 1 0  0 0 0 1
         *	    1 1 0 0  0 0 1 1
         *	    1 0 0 0  0 1 1 1
         *	    0 0 0 0  1 1 1 1
         *
         *	    0 0 0 1  1 1 1 0
         *	    0 0 1 1  1 1 0 0
         *	    0 1 1 1  1 0 0 0
         *	    1 1 1 1  0 0 0 0
         *)

       stipple_bdiag: array[0..8 * 8-1] of dword = (
            clr_A, clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A,
            clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A,
            clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A, clr_A,
            clr_B, clr_B, clr_B, clr_B, clr_A, clr_A, clr_A, clr_A,
            //-----------------------------------------------------
            clr_B, clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B,
            clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B,
            clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B, clr_B,
            clr_A, clr_A, clr_A, clr_A, clr_B, clr_B, clr_B, clr_B);

        stipple_fdiag: array[0..8 * 8-1] of dword = (
            clr_A, clr_A, clr_A, clr_A, clr_B, clr_B, clr_B, clr_B,
            clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B, clr_B,
            clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B,
            clr_B, clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B,
            //-----------------------------------------------------
            clr_B, clr_B, clr_B, clr_B, clr_A, clr_A, clr_A, clr_A,
            clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A, clr_A,
            clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A,
            clr_A, clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A);



       //bsHorizontal
       stipple_horz: array[0..15] of dword = (
          clr_B, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_B,
          clr_A, clr_A, clr_A, clr_A
       );

       stipple_vert: array[0..15] of dword = (
          clr_A, clr_B, clr_B, clr_B,
          clr_A, clr_B, clr_B, clr_B,
          clr_A, clr_B, clr_B, clr_B,
          clr_A, clr_B, clr_B, clr_B
       );

      (* , bsVertical, bsFDiagonal,
                   bsBDiagonal, bsCross, bsDiagCross, bsImage, bsPattern);*)


       { stipple_cross0: 3x3 version, unused — 8x8 stipple_cross1 is used instead
       stipple_cross0: array[0..8] of dword = (
          clr_B, clr_A, clr_B,
          clr_A, clr_A, clr_A,
          clr_B, clr_A, clr_B
       ); }

       stipple_cross1: array[0..63] of dword = (
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_A, clr_A, clr_A, clr_A, clr_A, clr_A, clr_A, clr_A,
          clr_A, clr_A, clr_A, clr_A, clr_A, clr_A, clr_A, clr_A,
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B
       );

       { stipple_dcross0: 3x3 version, unused — 8x8 stipple_dcross is used instead
       stipple_dcross0: array[0..8] of dword = (
          clr_A, clr_B, clr_A,
          clr_B, clr_A, clr_B,
          clr_A, clr_B, clr_A
       ); }

       stipple_dcross: array[0..63] of dword = (
          clr_A, clr_B, clr_B, clr_B, clr_B, clr_B, clr_B, clr_A,
          clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A,
          clr_B, clr_A, clr_A, clr_B, clr_B, clr_A, clr_A, clr_B,
          clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B,
          //----------------------------------------------------
          clr_B, clr_B, clr_B, clr_A, clr_A, clr_B, clr_B, clr_B,
          clr_B, clr_B, clr_A, clr_A, clr_A, clr_A, clr_B, clr_B,
          clr_B, clr_A, clr_A, clr_B, clr_B, clr_A, clr_A, clr_B,
          clr_A, clr_A, clr_B, clr_B, clr_B, clr_B, clr_A, clr_A
       );

function Gtk4DefaultContext: TGtk4DeviceContext;
begin
  if FDefaultContext = nil then
    FDefaultContext := TGtk4DeviceContext.Create(PGtkWidget(nil), False);
  Result := FDefaultContext;
end;

function Gtk4ScreenContext: TGtk4DeviceContext;
var
  surface: Pcairo_surface_t;
  cr: Pcairo_t;
begin
  if FScreenContext = nil then
  begin
    // GTK4: gdk_get_default_root_window removed. Use image surface fallback.
    surface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
    cr := cairo_create(surface);
    FScreenContext := TGtk4DeviceContext.CreateFromCairo(nil, cr);
    FScreenContext.FOwnsCairo := True;
    cairo_surface_destroy(surface);
  end;
  Result := FScreenContext;
end;

{------------------------------------------------------------------------------
  Name:    CheckBitmap
  Params:  Bitmap      - Handle to a bitmap (TGtk4Image)
           AMethodName - Method name
           AParamName  - Param name
  Returns: If the bitmap is valid
 ------------------------------------------------------------------------------}
function CheckBitmap(const ABitmap: HBITMAP; const AMethodName: String;
  const AParamName: String): Boolean;
begin
  Result := TObject(ABitmap) is TGtk4Image;
  if Result then Exit;

  {$IFDEF GTK4DEBUGCORE}
  if Pos('.', AMethodName) = 0 then
    DebugLn('Gtk4WidgetSet ' + AMethodName + ' Error - invalid bitmap ' +
      AParamName + ' = ' + DbgS(ABitmap) + '!')
  else
    DebugLn(AMethodName + ' Error - invalid bitmap ' + AParamName + ' = ' +
      DbgS(ABitmap) + '!');
  {$ENDIF}
end;

procedure TColorToRGB(AColor: TColor; out R, G, B: double);
begin
  R := (AColor and $FF) / 255;
  G := ((AColor shr 8) and $FF) / 255;
  B := ((AColor shr 16) and $FF) / 255;
end;

{ TGtk4ContextObject }

constructor TGtk4ContextObject.Create;
begin
  inherited Create;
  FShared := False;
end;

function TGtk4ContextObject.Select(ACtx:TGtk4DeviceContext): TGtk4ContextObject;
begin
  DbgS('Default context object selected, please implement');
  Result:=nil;
end;

{ TGtk4Region }

constructor TGtk4Region.Create(CreateHandle: Boolean);
begin
  inherited Create;
  FHandle := cairo_region_create;
end;

constructor TGtk4Region.Create(CreateHandle: Boolean; X1, Y1, X2, Y2: Integer);
var
  ARect: Tcairo_rectangle_int_t;
begin
  inherited Create;
  FHandle := nil;
  ARect.x := x1;
  ARect.y := y1;
  ARect.width := x2 - x1;
  ARect.height := y2 - y1;
  FHandle := cairo_region_create_rectangle(@ARect);
end;

constructor TGtk4Region.Create(X1,Y1,X2,Y2,nW,nH: Integer);
var
  ASurface: pcairo_surface_t;
  cr:Pcairo_t;
  rr:double;
  w,h:integer;
begin
  inherited Create;
  FHandle := nil;
  w:=x2-x1;
  h:=y2-y1;
  rr:=nW/2;

  ASurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
  cr:=cairo_create(ASurface);
  try
    cairo_new_path(cr);

    cairo_move_to(cr,x1,y2-rr);
    cairo_line_to(cr,x1,y1+rr);
    cairo_arc(cr,x1 + rr, y1 + rr, rr, pi, 3*pi/2);
    cairo_line_to(cr,x2-rr,y1);
    cairo_arc(cr,x2 - rr, y1 + rr, rr, 3*pi/2, 0);
    cairo_line_to(cr,x2,y2-rr);
    cairo_arc(cr,x2 - rr, y2 - rr, rr, 0, pi/2);
    cairo_line_to(cr,x1-rr,y2);
    cairo_arc(cr,x1 + rr, y2 - rr, rr, pi/2, pi);

    cairo_close_path(cr);
    cairo_set_source_rgba(cr,1,1,1,1);
    cairo_fill_preserve(cr);

    FHandle := gdk_cairo_region_create_from_surface(ASurface);
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(ASurface);
  end;
end;

constructor TGtk4Region.CreateEllipse(X1,Y1,X2,Y2: Integer);
var
  ASurface: pcairo_surface_t;
  cr:Pcairo_t;
  w,h:integer;
  save_matrix: Tcairo_matrix_t;
begin
  inherited Create;
  FHandle := nil;
  w:=x2-x1;
  h:=y2-y1;

  ASurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, w, h);
  cr:=cairo_create(ASurface);
  try
    cairo_save(cr);
    try
      cairo_get_matrix(cr, @save_matrix);
      cairo_translate (cr, x1 + w / 2.0 + PixelOffset, y1 + h / 2.0 + PixelOffset);
      cairo_scale (cr, w / 2.0, h / 2.0);
      cairo_new_path(cr);
      cairo_arc
          (
            (*cr =*) cr,
            (*xc =*) 0,
            (*yc =*) 0,
            (*radius =*) 1,
            (*angle1 =*) 0,
            (*angle2 =*) 2 * Pi
          );
      cairo_close_path(cr);
      cairo_set_source_rgba(cr,1,1,1,1);
      cairo_fill_preserve(cr);
    finally
      cairo_restore(cr);
    end;
    FHandle := gdk_cairo_region_create_from_surface(ASurface);
  finally
    cairo_destroy(cr);
    cairo_surface_destroy(ASurface);
  end;
end;

function TGtk4Region.Select(ACtx: TGtk4DeviceContext): TGtk4ContextObject;
begin
  fContext:=ACtx;
  if not Assigned(fContext) then exit(nil);
  fContext.setClipRegion(Self);
  Result:=Self;
end;

function TGtk4Region.Get(szbuf: integer; pbuf: pointer): integer;
begin
  Result:=0;
end;

destructor TGtk4Region.Destroy;
begin
  if Assigned(FHandle) then
  begin
    cairo_region_destroy(FHandle);
    FHandle := nil;
  end;
  inherited Destroy;
end;

function TGtk4Region.GetExtents: TRect;
var
  ARect: Tcairo_rectangle_int_t;
begin
  Result := Rect(0, 0, 0, 0);
  if Assigned(FHandle) then
  begin
    cairo_region_get_extents(FHandle, @ARect);
    Result.Left := ARect.x;
    Result.Top := ARect.y;
    Result.Right := ARect.width + ARect.x;
    Result.Bottom := ARect.height + ARect.y;
  end;
end;

function TGtk4Region.ContainsRect(ARect: TRect): Boolean;
var
  ACairoRect: Tcairo_rectangle_int_t;
begin
  with ACairoRect do
  begin
    x := ARect.Left;
    y := ARect.Top;
    width := ARect.Right - ARect.Left;
    height := ARect.Bottom - ARect.Top;
  end;
  Result := cairo_region_contains_rectangle(FHandle, @ACairoRect) = CAIRO_REGION_OVERLAP_IN;
end;

function TGtk4Region.ContainsPoint(APoint: TPoint): Boolean;
begin
  Result := cairo_region_contains_point(FHandle, APoint.x, APoint.y);
end;

{ TGtk4Font }

procedure TGtk4Font.UpdateLogFont;
var
  sz:integer;
  members:TPangoFontMask;
  AStyle: TPangoStyle;
  AGravity: TPangoGravity;
  SavedCharSet: Byte;
  SavedEscapement: Longint;
  SavedQuality: Byte;
  SavedPitchAndFamily: Byte;
begin
  if not Assigned(fHandle) then exit;
  { Preserve attributes that Pango cannot represent before clearing }
  SavedCharSet := fLogFont.lfCharSet;
  SavedEscapement := fLogFont.lfEscapement;
  SavedQuality := fLogFont.lfQuality;
  SavedPitchAndFamily := fLogFont.lfPitchAndFamily;

  fillchar(fLogFont,sizeof(fLogFont),0);

  { Restore Pango-invisible attributes for correct roundtrip via GetObject }
  fLogFont.lfCharSet := SavedCharSet;
  fLogFont.lfEscapement := SavedEscapement;
  fLogFont.lfQuality := SavedQuality;
  fLogFont.lfPitchAndFamily := SavedPitchAndFamily;

  members:=fHandle^.get_set_fields;
  if PANGO_FONT_MASK_FAMILY in members then
  begin
    fLogFont.lfFaceName:=PChar(fHandle^.get_family);
  end;
  if PANGO_FONT_MASK_STYLE in members then
  begin
    AStyle := fHandle^.get_style;
    if AStyle = PANGO_STYLE_ITALIC then
      fLogFont.lfItalic:=1;
  end;
  if PANGO_FONT_MASK_WEIGHT in members then
  begin
    fLogFont.lfWeight := Integer(fHandle^.get_weight());
  end;
  if PANGO_FONT_MASK_GRAVITY in members then
  begin
    AGravity := fHandle^.get_gravity;
    if AGravity = PANGO_GRAVITY_SOUTH then
      fLogFont.lfOrientation := 0
    else
    if AGravity = PANGO_GRAVITY_EAST then
      fLogFont.lfOrientation := 900
    else
    if AGravity = PANGO_GRAVITY_NORTH then
      fLogFont.lfOrientation := 1800
    else
    if AGravity = PANGO_GRAVITY_WEST then
      fLogFont.lfOrientation := 2700;
  end else
  begin
    { If Pango has no gravity, use escapement as orientation (for drawText) }
    if SavedEscapement <> 0 then
      fLogFont.lfOrientation := SavedEscapement;
  end;
  if PANGO_FONT_MASK_SIZE in members then
  begin
    sz:=fHandle^.get_size;
    if fHandle^.get_size_is_absolute then
    begin
      sz:= PANGO_PIXELS(sz);
    end else
    begin
      { in points }
      //sz:=round(96*sz/PANGO_SCALE/72);//round(2.03*sz/PANGO_SCALE);
      sz := MulDiv(PANGO_PIXELS(sz), 96{Screen.PixelsPerInch}, 72 )
    end;

    fLogFont.lfHeight:=sz;//round(sz/PANGO_SCALE);
  end;
end;

constructor TGtk4Font.Create(ACairo: Pcairo_t; AWidget: PGtkWidget);
var
  AContext: PPangoContext;
  AOwnsContext: Boolean;
begin
  inherited Create;
  AOwnsContext := not Gtk4IsWidget(AWidget);
  if not AOwnsContext then
  begin
    AContext := gtk_widget_get_pango_context(AWidget);
  end else
  begin
    AContext := pango_cairo_create_context(ACairo);
  end;
  FHandle := pango_font_description_copy(pango_context_get_font_description(AContext));
  FFontName := pango_font_description_get_family(FHandle);

  FLayout := pango_layout_new(AContext);
  if FHandle^.get_size_is_absolute then
  begin
    FHandle^.set_absolute_size(FHandle^.get_size);
  end else
  begin
    FHandle^.set_size(FHandle^.get_size);
  end;

  FLayout^.set_font_description(FHandle);
  if AOwnsContext then
    g_object_unref(AContext);
end;

constructor TGtk4Font.Create(ALogFont: TLogFont; const ALongFontName: String);
var
  AContext: PPangoContext;
  AFontMap: PPangoFontMap;
  AttrList: PPangoAttrList;
  Attr: PPangoAttribute;
  AFontOpts: Pcairo_font_options_t;
  APitch: Byte;
  AFamily: Byte;
  AFamilyStr: String;
  APangoLanguage: PPangoLanguage;
begin
  FLogFont := ALogFont;
  FFontName := ALogFont.lfFaceName;
  APangoLanguage := Gtk4CharSetToPangoLanguage(ALogFont.lfCharSet);
  { GTK4: pango_context_new alone has no font map; bind the default map explicitly. }
  AContext := pango_context_new;
  if Assigned(AContext) then
  begin
    AFontMap := pango_cairo_font_map_get_default;
    if Assigned(AFontMap) then
      AContext^.set_font_map(AFontMap);
    if Assigned(APangoLanguage) then
      AContext^.set_language(APangoLanguage);
  end;
  if IsFontNameDefault(FFontName) or (FFontName = '') then
  begin
    if Gtk4WidgetSet.DefaultAppFontName <> '' then
      FHandle := pango_font_description_from_string(PgChar(Gtk4WidgetSet.DefaultAppFontName))
    else
      FHandle := pango_font_description_copy(pango_context_get_font_description(AContext));
  end else
    FHandle := pango_font_description_from_string(PgChar(FFontName));
  FFontName := FHandle^.get_family;

  { lfPitchAndFamily → Pango generic family fallback (ported from GTK2 approach).
    Only apply when the face name is default/empty so we don't override an
    explicit font request. }
  if IsFontNameDefault(ALogFont.lfFaceName) or (ALogFont.lfFaceName = '') then
  begin
    APitch := ALogFont.lfPitchAndFamily and $03;
    AFamily := ALogFont.lfPitchAndFamily and $F0;
    AFamilyStr := '';
    if APitch = FIXED_PITCH then
      AFamilyStr := 'monospace'
    else begin
      case AFamily of
        FF_ROMAN:      AFamilyStr := 'serif';
        FF_SWISS:      AFamilyStr := 'sans-serif';
        FF_MODERN:     AFamilyStr := 'monospace';
        FF_SCRIPT:     AFamilyStr := 'cursive';
        FF_DECORATIVE: AFamilyStr := 'fantasy';
      end;
    end;
    if AFamilyStr <> '' then
    begin
      FHandle^.set_family(PgChar(AFamilyStr));
      FFontName := AFamilyStr;
    end;
  end;

  if ALogFont.lfHeight <> 0 then
    FHandle^.set_absolute_size(Abs(ALogFont.lfHeight) * PANGO_SCALE);
  if ALogFont.lfItalic > 0 then
    FHandle^.set_style(PANGO_STYLE_ITALIC);
  FHandle^.set_weight(TPangoWeight(ALogFont.lfWeight));

  { lfEscapement → store as lfOrientation for drawText rotation.
    drawText uses lfOrientation for cairo_rotate. }
  if (ALogFont.lfEscapement <> 0) and (FLogFont.lfOrientation = 0) then
    FLogFont.lfOrientation := ALogFont.lfEscapement;

  FLayout := pango_layout_new(AContext);
  FLayout^.set_font_description(FHandle);

  { lfQuality → Cairo font options (antialias/hinting hint).
    GTK2 does not apply quality at all; here we go beyond GTK2 by using Cairo. }
  case ALogFont.lfQuality of
    NONANTIALIASED_QUALITY:
    begin
      AFontOpts := cairo_font_options_create;
      cairo_font_options_set_antialias(AFontOpts, CAIRO_ANTIALIAS_NONE);
      pango_cairo_context_set_font_options(AContext, AFontOpts);
      cairo_font_options_destroy(AFontOpts);
    end;
    ANTIALIASED_QUALITY:
    begin
      AFontOpts := cairo_font_options_create;
      cairo_font_options_set_antialias(AFontOpts, CAIRO_ANTIALIAS_GRAY);
      pango_cairo_context_set_font_options(AContext, AFontOpts);
      cairo_font_options_destroy(AFontOpts);
    end;
    CLEARTYPE_QUALITY:
    begin
      AFontOpts := cairo_font_options_create;
      cairo_font_options_set_antialias(AFontOpts, CAIRO_ANTIALIAS_SUBPIXEL);
      pango_cairo_context_set_font_options(AContext, AFontOpts);
      cairo_font_options_destroy(AFontOpts);
    end;
    DRAFT_QUALITY:
    begin
      AFontOpts := cairo_font_options_create;
      cairo_font_options_set_hint_style(AFontOpts, CAIRO_HINT_STYLE_NONE);
      pango_cairo_context_set_font_options(AContext, AFontOpts);
      cairo_font_options_destroy(AFontOpts);
    end;
    PROOF_QUALITY:
    begin
      AFontOpts := cairo_font_options_create;
      cairo_font_options_set_hint_style(AFontOpts, CAIRO_HINT_STYLE_FULL);
      pango_cairo_context_set_font_options(AContext, AFontOpts);
      cairo_font_options_destroy(AFontOpts);
    end;
  end;

  if Assigned(APangoLanguage) or (ALogFont.lfUnderline<>0) or (ALogFont.lfStrikeOut<>0) then
  begin
    AttrList := pango_attr_list_new();
    if Assigned(APangoLanguage) then
    begin
      Attr := pango_attr_language_new(APangoLanguage);
      pango_attr_list_change(AttrList, Attr);
    end;
    if ALogFont.lfUnderline <> 0 then
    begin
      Attr := pango_attr_underline_new(PANGO_UNDERLINE_SINGLE);
      pango_attr_list_change(AttrList, Attr);
    end;

    if ALogFont.lfStrikeOut <> 0 then
    begin
      Attr := pango_attr_strikethrough_new(True);
      pango_attr_list_change(AttrList, Attr);
    end;
    pango_layout_set_attributes(FLayout, AttrList);
    pango_attr_list_unref(AttrList);
  end;
  if AContext <> nil then
    g_object_unref(AContext);
end;

function TGtk4Font.Select(ACtx:TGtk4DeviceContext): TGtk4ContextObject;
begin
  fContext:=ACtx;
  if not Assigned(fContext) then exit(nil);
  Result := fContext.CurrentFont;
  fContext.CurrentFont:= Self;
end;

function TGtk4Font.Get(szbuf: integer; pbuf: pointer): integer;
begin
  Result:=sizeof(Self.LogFont);
  if pbuf=nil then exit;
  Self.UpdateLogFont;
  move(LogFont,pbuf^,min(szbuf,Result));
end;

destructor TGtk4Font.Destroy;
begin
  if Assigned(FLayout) then
  begin
    g_object_unref(FLayout);
    FLayout := nil;
  end;
  if Assigned(FHandle) then
  begin
    pango_font_description_free(FHandle);
    FHandle := nil;
  end;
  inherited Destroy;
end;

{ TGtk4Object }

constructor TGtk4Object.Create;
begin
  FUpdateCount := 0;
end;

procedure TGtk4Object.Release;
begin
  Free;
end;

procedure TGtk4Object.BeginUpdate;
begin
  inc(FUpdateCount);
end;

procedure TGtk4Object.EndUpdate;
begin
  if FUpdateCount > 0 then
    dec(FUpdateCount);
end;

function TGtk4Object.InUpdate: Boolean;
begin
  Result := FUpdateCount > 0;
end;

{ TGtk4Image }

constructor TGtk4Image.Create;
var
  ASurface: Pcairo_surface_t;
begin
  {$IFDEF VerboseGtk4DeviceContext}
    DebugLn('TGtk4Image.Create 1');
  {$ENDIF}
  inherited Create;
  // GTK4: gdk_cairo_create/gdk_get_default_root_window removed
  // Create a small default image surface
  ASurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
  try
    FHandle := gdk_pixbuf_get_from_surface(ASurface, 0, 0, 1, 1);
  finally
    cairo_surface_destroy(ASurface);
  end;
  FData := nil;
  FDataOwner := False;
  FFormat := CAIRO_FORMAT_ARGB32;
end;

constructor TGtk4Image.Create(vHandle: PGdkPixbuf);
var
  ASurface: Pcairo_surface_t;
begin
  {$IFDEF VerboseGtk4DeviceContext}
    if vHandle <> nil then
      DebugLn('TGtk4Image.Create 2 vHandle=',dbgs(vHandle),' channels ',dbgs(vHandle^.get_n_channels),' bps ',dbgs(vHandle^.get_bits_per_sample),' has_alpha=',dbgs(vHandle^.get_has_alpha))
    else
      DebugLn('TGtk4Image.Create 2 vHandle=nil');
  {$ENDIF}
  inherited Create;
  if vHandle <> nil then
    FHandle := vHandle^.copy
  else
  begin
    ASurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
    try
      FHandle := gdk_pixbuf_get_from_surface(ASurface, 0, 0, 1, 1);
    finally
      cairo_surface_destroy(ASurface);
    end;
  end;
  FData := nil;
  FDataOwner := False;

  if FHandle^.get_has_alpha then
    FFormat := CAIRO_FORMAT_ARGB32
  else
    FFormat := CAIRO_FORMAT_RGB24;
end;

constructor TGtk4Image.Create(AData: PByte; width: Integer; height: Integer;
  format: Tcairo_format_t; const ADataOwner: Boolean);
var
  ASurface: Pcairo_surface_t;
  w,h: Integer;
  AStride: Integer;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4Image.Create 3 AData=',dbgs(AData <> nil),' format=',dbgs(Ord(format)),' w=',dbgs(width),' h=',dbgs(height),' dataowner=',dbgs(ADataOwner));
  {$ENDIF}
  inherited Create;
  FFormat := format;
  FData := AData;
  FDataOwner := ADataOwner;
  if FData = nil then
  begin
    w := width;
    h := height;
    if w <= 0 then
      w := 16;
    if h <= 0 then
      h := 16;

    ASurface := cairo_image_surface_create(format, w, h);
    try
      FHandle := gdk_pixbuf_get_from_surface(ASurface, 0 ,0, w, h);
    finally
      cairo_surface_destroy(ASurface);
    end;
    gdk_pixbuf_fill(FHandle, 0);
  end else
  begin
    AStride := cairo_format_stride_for_width(format, width);
    if AStride <= 0 then
      AStride := width * 4;
    { Convert through a cairo image surface to avoid format/channel mismatches
      when source data is A1/A8/RGB24 and to keep byte-order handling consistent
      with GTK4 drawing code. }
    ASurface := cairo_image_surface_create_for_data(AData, format, width, height, AStride);
    try
      FHandle := gdk_pixbuf_get_from_surface(ASurface, 0, 0, width, height);
    finally
      cairo_surface_destroy(ASurface);
    end;
  end;
end;

constructor TGtk4Image.Create(AData: PByte; width: Integer; height: Integer;
  bytesPerLine: Integer; format: Tcairo_format_t; const ADataOwner: Boolean);
var
  ASurface: Pcairo_surface_t;
  w, h: Integer;
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('TGtk4Image.Create 4 AData=',dbgs(AData <> nil),' format=',dbgs(Ord(format)),' w=',dbgs(width),' h=',dbgs(height),' dataowner=',dbgs(ADataOwner),' bpl=',dbgs(bytesPerLine));
  {$endif}
  inherited Create;
  FFormat := format;
  FData := AData;
  FDataOwner := ADataOwner;

  if FData = nil then
  begin
    w := width;
    h := height;
    if (w <= 0) then
      w := 16;
    if (h <= 0) then
      h := 16;
    ASurface := cairo_image_surface_create(format, w, h);
    try
      FHandle := gdk_pixbuf_get_from_surface(ASurface, 0 ,0, w, h);
    finally
      cairo_surface_destroy(ASurface);
    end;
    gdk_pixbuf_fill(FHandle, 0);
  end else
  begin
    { Keep conversion path identical to the other overload to avoid subtle
      format interpretation differences. }
    ASurface := cairo_image_surface_create_for_data(AData, format, width, height, bytesPerLine);
    try
      FHandle := gdk_pixbuf_get_from_surface(ASurface, 0, 0, width, height);
    finally
      cairo_surface_destroy(ASurface);
    end;
  end;
end;

function TGtk4Image.Select(ACtx: TGtk4DeviceContext): TGtk4ContextObject;
begin
  fContext:=ACtx;
  if not Assigned(ACtx) then exit(nil);
  Result := fContext.CurrentImage;
  fContext.SetImage(Self);
end;

function TGtk4Image.Get(szbuf: integer; pbuf: pointer): integer;
begin
  Result:=0;
end;

destructor TGtk4Image.Destroy;
begin
  if FHandle <> nil then
  begin
    FHandle^.unref;
    FHandle := nil;
  end;
  if (FDataOwner) and (FData <> nil) then
    FreeMem(FData);

  inherited Destroy;
end;

procedure TGtk4Image.CopyFrom(AImage: PGdkPixbuf; x, y, w, h: integer);
var
  ASub: PGdkPixbuf;
begin
  if FHandle <> nil then
  begin
    {$IFDEF GTK4DEBUGCORE}
    DebugLn('*TGtk4Image.CopyFrom replacing existing ...');
    {$ENDIF}
    g_object_unref(FHandle);
  end else
  begin
    {$IFDEF GTK4DEBUGCORE}
    DebugLn('*TGtk4Image.CopyFrom create copy ...');
    {$ENDIF}
  end;
  { gdk_pixbuf_new_subpixbuf shares source memory — use gdk_pixbuf_copy
    to create an independent copy that survives source pixbuf destruction. }
  ASub := gdk_pixbuf_new_subpixbuf(AImage, x, y, w, h);
  FHandle := gdk_pixbuf_copy(ASub);
  g_object_unref(ASub);
end;

function TGtk4Image.height: Integer;
begin
  Result := FHandle^.get_height;
end;

function TGtk4Image.width: Integer;
begin
  Result := FHandle^.get_width;
end;

function TGtk4Image.depth: Integer;
var
  AOption: Pgchar;
begin
  Result := 32;
  AOption := FHandle^.get_option('depth');
  if AOption <> nil then
  begin
    TryStrToInt(StrPas(AOption), Result);
  end;
end;

function TGtk4Image.dotsPerMeterX: Integer;
var
  AOption: Pgchar;
  ADpi: Integer;
begin
  Result := 0;
  if FHandle = nil then Exit;
  AOption := FHandle^.get_option('x-dpi');
  if (AOption <> nil) and TryStrToInt(StrPas(AOption), ADpi) and (ADpi > 0) then
    Result := Round(ADpi * 39.3701); { 1 inch = 0.0254 m → dpm = dpi / 0.0254 }
end;

function TGtk4Image.dotsPerMeterY: Integer;
var
  AOption: Pgchar;
  ADpi: Integer;
begin
  Result := 0;
  if FHandle = nil then Exit;
  AOption := FHandle^.get_option('y-dpi');
  if (AOption <> nil) and TryStrToInt(StrPas(AOption), ADpi) and (ADpi > 0) then
    Result := Round(ADpi * 39.3701);
end;

function TGtk4Image.bits: PByte;
begin
  Result := FHandle^.pixels;
end;

function TGtk4Image.numBytes: LongWord;
begin
  Result := FHandle^.get_byte_length;
end;

function TGtk4Image.bytesPerLine: Integer;
begin
  Result := FHandle^.rowstride;
end;

{ TGtk4Pen }

procedure TGtk4Pen.SetColor(AValue: TColor);
var
  ARed, AGreen, ABlue: Double;
begin
  FColor := AValue;
  ColorToCairoRGB(FColor, ARed, AGreen, ABlue);
  if Assigned(FContext) and Assigned(FContext.pcr) then
  begin
    cairo_stroke(fContext.Pcr);
    cairo_new_path(fContext.Pcr);
    cairo_set_source_rgb(FContext.pcr, ARed, AGreen, ABlue);
  end;
end;

constructor TGtk4Pen.Create;
begin
  inherited Create;
  FillChar(LogPen, SizeOf(LogPen), #0);
  FIsExtPen := False;
  FContext := nil;
  FColor := clBlack;
  FCosmetic := True;
  FWidth := 0;
  FStyle := psSolid;
  FEndCap := pecFlat;
  FJoinStyle := pjsRound;
  FPenMode := pmCopy; // default pen mode
end;

function TGtk4Pen.Select(ACtx:TGtk4DeviceContext): TGtk4ContextObject;
begin
  fContext:=ACtx;
  if not Assigned(fContext) then exit(nil);
  Result := FContext.CurrentPen;
  fContext.CurrentPen := Self;
  Self.SetColor(fColor); // update Cairo
end;

function TGtk4Pen.Get(szbuf: integer; pbuf: pointer): integer;
begin
  Result:=sizeof(LogPen);
  if pbuf=nil then exit;
  move(LogPen,pbuf^,min(result,szbuf));
end;

procedure TGtk4Pen.setCosmetic(b: Boolean);
begin
  FCosmetic := B;
  if Assigned(FContext) and Assigned(FContext.pcr) then
  begin
    if b then
      cairo_set_line_width(FContext.pcr, 0)
    else
      cairo_set_line_width(FContext.pcr, 1);
  end;
end;

procedure TGtk4Pen.setWidth(p1: Integer);
begin
  FWidth := p1;
  if Assigned(FContext) then
    cairo_set_line_width(FContext.pcr, p1);
end;

procedure TGtk4Pen.SetDashes(ADashes: PDWord; ACount: DWord);
var
  i: DWord;
begin
  SetLength(FDashes, ACount);
  for i := 0 to ACount - 1 do
  begin
    FDashes[i] := Double(ADashes^);
    Inc(ADashes);
  end;
end;

function TGtk4Pen.GetDashCount: Integer;
begin
  Result := Length(FDashes);
end;

function TGtk4Pen.GetDashArray: PDouble;
begin
  if Length(FDashes) > 0 then
    Result := @FDashes[0]
  else
    Result := nil;
end;

{ TGtk4Brush }

procedure TGtk4Brush.SetColor(AValue: TColor);
var
  ARed, AGreen, ABlue: Double;
begin
  FColor := AValue;
  ColorToCairoRGB(FColor, ARed, AGreen, ABlue);
  if Assigned(FContext) then
    cairo_set_source_rgb(FContext.pcr, ARed, AGreen, ABlue);
end;

procedure TGtk4Brush.SetStyle(AStyle: longword);
begin
  if AStyle=fStyle then exit;
  fStyle:=AStyle;
  Self.UpdatePattern;
end;

constructor TGtk4Brush.Create;
begin
  inherited Create;
  FColor := clNone;
  FillChar(LogBrush, SizeOf(TLogBrush), #0);
end;

function TGtk4Brush.Select(ACtx:TGtk4DeviceContext): TGtk4ContextObject;
begin
  fContext:=ACtx;
  if not Assigned(fContext) then exit(nil);
  Result := fContext.CurrentBrush;
  Self.UpdatePattern;
  fContext.CurrentBrush := Self;
end;

function TGtk4Brush.Get(szbuf: integer; pbuf: pointer): integer;
begin
  Result:=sizeof(LogBrush);
  if pbuf=nil then exit;
  move(LogBrush,pbuf^,min(Result,szbuf));
end;

destructor TGtk4Brush.Destroy;
begin
  if Assigned(brush_pattern) then
    cairo_pattern_destroy(brush_pattern);
  if Assigned(pat_buf) then
  freeandnil(pat_buf);
  inherited Destroy;
end;

procedure TGtk4Brush.UpdatePattern;
var
  w,h,i,j:integer;
  clr:dword;
  rgb:array[0..3] of byte absolute clr;
  pat_sample,psrc,pdst:pdword;
begin
  if Self.LogBrush.lbStyle<>BS_HATCHED then exit;

  if Assigned(Self.brush_pattern) then
  begin
     cairo_pattern_destroy(brush_pattern);
     freeandnil(pat_buf);
  end;
  case TBrushStyle(Self.LogBrush.lbHatch+ord(bsHorizontal)) of
  bsHorizontal:
    begin
      w:=4; h:=4;
      pat_sample:=@stipple_horz[0];
    end;
  bsVertical:
    begin
      w:=4; h:=4;
      pat_sample:=@stipple_vert[0];
    end;
  bsFDiagonal:
    begin
      w:=8; h:=8;
      pat_sample:=@stipple_fdiag[0];
    end;
  bsBDiagonal:
    begin
      w:=8; h:=8;
      pat_sample:=@stipple_bdiag[0];
    end;
  bsCross:
    begin
      w:=8; h:=8;
      pat_sample:=@stipple_cross1[0];
    end;
  bsDiagCross:
    begin
      w:=8; h:=8;
      pat_sample:=@stipple_dcross[0];
    end;
  else
    exit
  end;
  psrc:=pat_sample;
  getmem(pat_buf,w*h*sizeof(dword));
  pdst:=pat_buf;
  clr:=ColorToRgb(Self.Color);
  for i:=0 to h-1 do
  for j:=0 to w-1 do
  begin
    case psrc^ of
    clr_A: pdst^:=$ff000000 or (rgb[0] shl 16) or (rgb[1] shl 8) or (rgb[2]);
    clr_B: pdst^:=$ffffffff;
    end;
    inc(psrc); inc(pdst);
  end;
  {GTK4 states the buffer must exist, until image that uses the buffer - destroyed}
  brush_pattern:=create_stipple(PByte(pat_buf),w,h);
end;



function create_stipple(stipple_data:pbyte;width,height:integer):pcairo_pattern_t;
var
  surface:pcairo_surface_t;
	pattern:pcairo_pattern_t;
  stride:integer;
begin
	stride := cairo_format_stride_for_width (CAIRO_FORMAT_ARGB32, width);
	surface := cairo_image_surface_create_for_data (stipple_data, CAIRO_FORMAT_ARGB32, width, height,
	                                               stride);
	pattern := cairo_pattern_create_for_surface (surface);
	cairo_surface_destroy (surface);
	cairo_pattern_set_extend (pattern, CAIRO_EXTEND_REPEAT);

	result:= pattern;
end;

{ TGtk4DeviceContext }

function TGtk4DeviceContext.GetOffset: TPoint;
var
  dx,dy: Double;
begin
  cairo_surface_get_device_offset(cairo_get_target(pcr), @dx, @dy);
  Result := Point(Round(dx), Round(dy));
end;

procedure TGtk4DeviceContext.setBrush(AValue: TGtk4Brush);
begin
  if Assigned(FBrush) then
    FBrush.Free;
  FBrush := AValue;
end;

procedure TGtk4DeviceContext.SetFont(AValue: TGtk4Font);
begin
  if Assigned(FFont) then
    FFont.Free;
  FFont := AValue;
end;

procedure TGtk4DeviceContext.SetOffset(AValue: TPoint);
var
  dx, dy: Double;
begin
  dx := AValue.X;
  dy := AValue.Y;
  cairo_surface_set_device_offset(cairo_get_target(pcr), dx, dy);
end;

procedure TGtk4DeviceContext.setPen(AValue: TGtk4Pen);
begin
  if Assigned(FPen) then
    FPen.Free;
  FPen := AValue;
end;

procedure TGtk4DeviceContext.SetvImage(AValue: TGtk4Image);
begin
  if Assigned(FvImage) then
    FvImage.Free;
  FvImage := AValue;
end;

function TGtk4DeviceContext.SX(const x: double): Double;
begin
  Result := 1*(x+vClipRect.Left);
end;

function TGtk4DeviceContext.SY(const y: double): Double;
begin
  Result := 1*(y+vClipRect.Top);
end;

function TGtk4DeviceContext.SX2(const x: double): Double;
begin
  Result := x;
end;

function TGtk4DeviceContext.SY2(const y: double): Double;
begin
  Result := y;
end;

procedure TGtk4DeviceContext.ApplyBrush;
begin
  { Always set the brush color. BkMode=TRANSPARENT only affects text
    background and hatch brush gaps — solid brush fills are unaffected. }
  SetSourceColor(FCurrentBrush.Color);

  if Self.FCurrentBrush.Style <> 0 then
  begin
    if Assigned(Self.FCurrentBrush.brush_pattern) then
      cairo_set_source(pcr, Self.FCurrentBrush.brush_pattern);
  end;
end;

procedure TGtk4DeviceContext.ApplyFont;
var
  AFont: TGtk4Font;
begin
  if Assigned(FCurrentFont) then
    AFont := FCurrentFont
  else
    AFont := FFont;
  if (AFont <> nil) and (AFont.Layout <> nil) and (pcr <> nil) then
  begin
    { Ensure the pango layout's font description is current }
    if AFont.Handle <> nil then
      AFont.Layout^.set_font_description(AFont.Handle);
    { Sync the layout with the cairo context (resolution, matrix) }
    pango_cairo_update_layout(pcr, AFont.Layout);
  end;
end;

procedure TGtk4DeviceContext.ApplyPen;

  procedure SetDash(d: array of double);
  begin
    cairo_set_dash(pcr, @d[0], High(d)+1, 0);
  end;

var
  cap: Tcairo_line_cap_t;
  w: Double;
begin
  SetSourceColor(FCurrentPen.Color);
  case FCurrentPen.Mode of
    pmBlack: begin
      SetSourceColor(clBlack);
      cairo_set_operator(pcr, CAIRO_OPERATOR_OVER);
    end;
    pmWhite: begin
      SetSourceColor(clWhite);
      cairo_set_operator(pcr, CAIRO_OPERATOR_OVER);
    end;
    pmCopy: cairo_set_operator(pcr, CAIRO_OPERATOR_OVER);
    pmXor: cairo_set_operator(pcr, CAIRO_OPERATOR_XOR);
    pmNotXor: cairo_set_operator(pcr, CAIRO_OPERATOR_XOR);
    pmNop: cairo_set_operator(pcr, CAIRO_OPERATOR_DEST);
    { Cairo lacks bitwise ROP2 operators (GTK2 had GdkFunction for these).
      pmNot, pmNotCopy, pmMergePenNot, pmMaskPenNot, pmMergeNotPen,
      pmMaskNotPen, pmMerge, pmNotMerge, pmMask, pmNotMask
      all require bitwise pixel ops not available in Cairo.
      Same limitation exists in GTK3. }
    else
      cairo_set_operator(pcr, CAIRO_OPERATOR_OVER);
  end;

  if FCurrentPen.Cosmetic then
    cairo_set_line_width(pcr, 1.0)
  else
  begin
    w := FCurrentPen.Width;
    if w <= 1 then
      w := 0.5;
    cairo_set_line_width(pcr, w {* ScaleX}); //line_width is diameter of the pen circle
  end;

  case FCurrentPen.Style of
    psSolid: cairo_set_dash(pcr, nil, 0, 0);
    psDash: SetDash(Dash_Dash);
    psDot: SetDash(Dash_Dot);
    psDashDot: SetDash(Dash_DashDot);
    psDashDotDot: SetDash(Dash_DashDotDot);
    psPattern:
      if FCurrentPen.GetDashCount > 0 then
        cairo_set_dash(pcr, FCurrentPen.GetDashArray, FCurrentPen.GetDashCount, 0)
      else
        cairo_set_dash(pcr, nil, 0, 0);
  else
    cairo_set_dash(pcr, nil, 0, 0);
  end;

  case FCurrentPen.EndCap of
    pecRound: cap := CAIRO_LINE_CAP_ROUND;
    pecSquare: cap := CAIRO_LINE_CAP_SQUARE;
    pecFlat: cap := CAIRO_LINE_CAP_BUTT;
  end;

  // dashed patterns do not look ok  combined with round or squared caps
  // make it flat until a solution is found
  case FCurrentPen.Style of
    psDash, psDot, psDashDot, psDashDotDot, psPattern:
      cap := CAIRO_LINE_CAP_BUTT
  end;
  cairo_set_line_cap(pcr, cap);

  case FCurrentPen.JoinStyle of
    pjsRound: cairo_set_line_join(pcr, CAIRO_LINE_JOIN_ROUND);
    pjsBevel: cairo_set_line_join(pcr, CAIRO_LINE_JOIN_BEVEL);
    pjsMiter: cairo_set_line_join(pcr, CAIRO_LINE_JOIN_MITER);
  end;
end;

constructor TGtk4DeviceContext.Create(AWidget: PGtkWidget;
  const APaintEvent: Boolean);
var
  W: gint;
  H: gint;
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('TGtk4DeviceContext.Create (',
     ' WidgetHandle: ', dbghex(PtrInt(AWidget)),
     ' FromPaintEvent:',BoolToStr(APaintEvent),' )');
  {$endif}
  inherited Create;
  FvClipRect := Rect(0, 0, 0, 0);
  Window := nil;
  Parent := nil;
  ParentPixmap := nil;
  CairoSurface := nil;
  FCanRelease := False;
  FOwnsCairo := True;
  FOwnsSurface := False;
  FCurrentTextColor := clBlack;

  if AWidget = nil then
  begin
    // GTK4: gdk_cairo_create/gdk_get_default_root_window removed
    // Create an image surface as fallback
    CairoSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
    pcr := cairo_create(CairoSurface);
    ParentPixmap := nil;
    FOwnsSurface := True;
  end else
  begin
    Parent := AWidget;
    {avoid paints on null pixmaps !}
    W := gtk_widget_get_allocated_width(AWidget);
    H := gtk_widget_get_allocated_height(AWidget);
    if W <= 0 then W := 1;
    if H <= 0 then H := 1;
    // GTK4: gdk_cairo_create/gtk_widget_get_window removed
    // Create image surface of widget's allocated size
    CairoSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, W, H);
    pcr := cairo_create(CairoSurface);
    FOwnsSurface := True;
  end;
  if not FOwnsSurface then
    CairoSurface := cairo_get_target(pcr);
  CreateObjects;
  FRop2 := R2_COPYPEN;
  FMapMode := MM_TEXT;
  FViewPortExt := Point(1, 1);
  FViewPortOrg := Point(0, 0);
  FWindowExt := Point(1, 1);
end;

constructor TGtk4DeviceContext.Create(AWindow: PGdkWindow;
  const APaintEvent: Boolean);
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('TGtk4DeviceContext.Create (',
     ' WindowHandle: ', dbghex(PtrInt(AWindow)),
     ' FromPaintEvent:',BoolToStr(APaintEvent),' )');
  {$endif}
  inherited Create;
  FvClipRect := Rect(0, 0, 0, 0);
  Parent := nil;
  ParentPixmap := nil;
  Window := AWindow;
  FOwnsSurface := True;
  FCanRelease := False;
  FOwnsCairo := True;
  FCurrentTextColor := clBlack;
  // GTK4: gdk_cairo_create/gdk_cairo_set_source_window removed
  // Stub: create image surface fallback
  CairoSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, 1, 1);
  pcr := cairo_create(CairoSurface);
  CreateObjects;
  FRop2 := R2_COPYPEN;
  FMapMode := MM_TEXT;
  FViewPortExt := Point(1, 1);
  FViewPortOrg := Point(0, 0);
  FWindowExt := Point(1, 1);
end;

constructor TGtk4DeviceContext.CreateFromCairo(AWidget: PGtkWidget;
  ACairo: PCairo_t);
var
  x1, y1, x2, y2: double;
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('TGtk4DeviceContext.CreateFromCairo (',
     ' WidgetHandle: ', dbghex(PtrInt(AWidget)),
     ' FromPaintEvent:',BoolToStr(True),' )');
  {$endif}
  inherited Create;
  FOwnsCairo := False;
  Window := nil;
  Parent := AWidget;
  ParentPixmap := nil;
  CairoSurface := nil;
  FOwnsSurface := False;
  FCurrentTextColor := clBlack;
  // GTK4: gdk_cairo_get_clip_rectangle removed, use cairo_clip_extents
  cairo_clip_extents(ACairo, @x1, @y1, @x2, @y2);
  FvClipRect := Rect(Round(x1), Round(y1), Round(x2), Round(y2));
  pcr := ACairo;
  CairoSurface := cairo_get_target(pcr);
  CreateObjects;
  FRop2 := R2_COPYPEN;
  FMapMode := MM_TEXT;
  FViewPortExt := Point(1, 1);
  FViewPortOrg := Point(0, 0);
  FWindowExt := Point(1, 1);
end;

destructor TGtk4DeviceContext.Destroy;
begin
  {$ifdef VerboseGtk4DeviceContext}
    DebugLn('TGtk4DeviceContext.Destroy ',dbgHex(PtrUInt(Self)));
  {$endif}
  DeleteObjects;
  if FOwnsCairo and (pcr <> nil) then
    cairo_destroy(pcr);
  if (ParentPixmap <> nil) then
    g_object_unref(ParentPixmap);
  if FOwnsSurface and (CairoSurface <> nil) then
    cairo_surface_destroy(CairoSurface);
  Parent := nil;
  pcr := nil;
  ParentPixmap := nil;
  CairoSurface := nil;
  Window := nil;
  inherited Destroy;
end;

procedure TGtk4DeviceContext.CreateObjects;
var
  Matrix: Tcairo_matrix_t;
begin
  FBkMode := TRANSPARENT;
  FCurrentImage := nil;
  FCurrentRegion := nil;
  FBrush := TGtk4Brush.Create;
  FBrush.Context := Self;
  FBrush.Color := clNone;
  FBrush.Style := BS_SOLID;
  FPen := TGtk4Pen.Create;
  FPen.Context := Self;
  FPen.Color := clBlack;
  FCurrentPen := FPen;
  FCurrentBrush := FBrush;
  FFont := TGtk4Font.Create(pcr, Parent);
  FCurrentFont := FFont;
  FvImage := TGtk4Image.Create(nil, 1, 1, 8, CAIRO_FORMAT_ARGB32);
  FCurrentImage := FvImage;

  cairo_get_matrix(pcr, @Matrix);
  // widget with menu or other non-client exclusions have offset in trasform matrix
  fncOrigin:=Point(round(Matrix.x0),round(Matrix.y0));
end;

procedure TGtk4DeviceContext.DeleteObjects;
begin
  if Assigned(FBrush) then
    FreeAndNil(FBrush);
  if Assigned(FPen) then
    FreeAndNil(FPen);
  if Assigned(FFont) then
    FreeAndNil(FFont);
  if Assigned(FvImage) then
    FreeAndNil(FvImage);
end;

procedure TGtk4DeviceContext.drawPixel(x, y: Integer; AColor: TColor);
// Seems that painting line from (a-1, b-1) to (a,b) gives one pixel
begin
  SetSourceColor(AColor);
  cairo_set_line_width(pcr, 1);
  cairo_move_to(pcr, x - PixelOffset, y - PixelOffset);
  cairo_line_to(pcr, x + PixelOffset, y + PixelOffset);
  cairo_stroke(pcr);
end;

function TGtk4DeviceContext.getPixel(x, y: Integer): TColor;
var
  pixbuf: PGdkPixbuf;
  pixels: pointer;
begin
  Result := 0;
  pixbuf := gdk_pixbuf_get_from_surface(CairoSurface, X, Y, 1, 1);
  if Assigned(pixbuf) then
  try
    pixels := gdk_pixbuf_get_pixels(pixbuf);
    if Assigned(pixels) then
      Result := PLongInt(pixels)^ and $FFFFFF; // take first 3 bytes at pixels^
  finally
    g_object_unref(PGObject(pixbuf));
  end;
end;

procedure TGtk4DeviceContext.drawRect(x1, y1, w, h: Integer; const AFill, ABorder: Boolean);
begin
  cairo_save(pcr);
  try
    cairo_rectangle(pcr, x1 + PixelOffset, y1 + PixelOffset, w - 1, h - 1);

    if AFill then
    begin
      ApplyBrush;
      cairo_fill_preserve(pcr);
    end;
    if ABorder then
    begin
      ApplyPen;
      cairo_stroke(pcr);
    end;

    cairo_new_path(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawRoundRect(x, y, w, h, rx, ry: Integer);
begin
  RoundRect(x, y, w, h, rx, ry);
end;

procedure TGtk4DeviceContext.drawText(x, y: Integer; AText: PChar; ALen: Integer
  );
var
  R, G, B: Double;
  gColor: TGdkColor;
  Attr: PPangoAttribute;
  AttrList, SavedAttrList: PPangoAttrList;
  UseBack: boolean;
  ornt:integer;
begin
  cairo_save(pcr);
  try
    cairo_move_to(pcr, X, Y);
    ornt := Self.FCurrentFont.FLogFont.lfOrientation;
    if ornt<>0 then
      cairo_rotate(pcr, - pi * (ornt / 10)/180);
    ColorToCairoRGB(ColorToRgb(TColor(CurrentTextColor)), R, G, B);
    cairo_set_source_rgb(pcr, R, G, B);

    FCurrentFont.Layout^.set_text(AText, ALen);

    UseBack := (FBkMode <> TRANSPARENT) and (FCurrentBrush.Style <> BS_NULL);
    SavedAttrList := nil;
    if UseBack then
    begin
      gColor := TColorToTGDKColor(FCurrentBrush.Color);
      { Save existing attributes (underline/strikeout from font constructor).
        pango_layout_get_attributes returns a borrowed ref — take our own ref
        so it survives set_attributes replacing the layout's internal list. }
      SavedAttrList := pango_layout_get_attributes(FCurrentFont.Layout);
      if SavedAttrList <> nil then
      begin
        pango_attr_list_ref(SavedAttrList);
        AttrList := pango_attr_list_copy(SavedAttrList);
      end else
        AttrList := pango_attr_list_new;
      Attr := pango_attr_background_new(gColor.red, gColor.green, gColor.blue);
      pango_attr_list_insert(AttrList, Attr); { takes ownership of Attr }
      FCurrentFont.Layout^.set_attributes(AttrList);
      pango_attr_list_unref(AttrList);
    end;

    pango_cairo_show_layout(pcr, FCurrentFont.Layout);

    if UseBack then
    begin
      { Restore the font's original attributes (without background) }
      FCurrentFont.Layout^.set_attributes(SavedAttrList); { nil is valid }
      if SavedAttrList <> nil then
        pango_attr_list_unref(SavedAttrList);
    end;
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawEllipse(x, y, w, h: Integer; AFill, ABorder: Boolean);
var
  save_matrix: Tcairo_matrix_t;
begin
  cairo_save(pcr);
  try
    cairo_get_matrix(pcr, @save_matrix);
    cairo_translate (pcr, x + w / 2.0 + PixelOffset, y + h / 2.0 + PixelOffset);
    cairo_scale (pcr, w / 2.0, h / 2.0);
    cairo_new_path(pcr);
    cairo_arc
        (
          (*cr =*) pcr,
          (*xc =*) 0,
          (*yc =*) 0,
          (*radius =*) 1,
          (*angle1 =*) 0,
          (*angle2 =*) 2 * Pi
        );
    cairo_close_path(pcr);
    if AFill then
    begin
      ApplyBrush;
      cairo_fill_preserve(pcr);
    end;
  finally
    cairo_restore(pcr);
  end;
  if ABorder then
  begin
    ApplyPen;
    cairo_stroke(pcr);
  end;
  { If ABorder=false, clear current path }
  cairo_new_path(pcr);
end;

procedure TGtk4DeviceContext.drawArc(Left, Top, Right, Bottom, Angle1,
  Angle2: Integer);
var
  cx, cy, rx, ry: Double;
  a1Rad, a2Rad: Double;
begin
  if Assigned(FCurrentPen) and (FCurrentPen.Style = psClear) then Exit;
  rx := (Right - Left) / 2.0;
  ry := (Bottom - Top) / 2.0;
  if (rx = 0) or (ry = 0) then Exit;
  cx := Left + rx;
  cy := Top + ry;
  { LCL angles are in 1/16th degree. Convert to radians. }
  a1Rad := Angle1 * Pi / (180 * 16);
  a2Rad := Angle2 * Pi / (180 * 16);
  cairo_save(pcr);
  try
    cairo_translate(pcr, cx + PixelOffset, cy + PixelOffset);
    cairo_scale(pcr, rx, ry);
    cairo_new_path(pcr);
    { In cairo Y increases downward, so negate angles.
      Positive Angle2 = counter-clockwise on screen = cairo_arc_negative. }
    if a2Rad >= 0 then
      cairo_arc_negative(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad))
    else
      cairo_arc(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad));
  finally
    cairo_restore(pcr);
  end;
  { Stroke after restore so pen width is not scaled by the ellipse transform }
  ApplyPen;
  cairo_stroke(pcr);
  cairo_new_path(pcr);
end;

procedure TGtk4DeviceContext.drawChord(Left, Top, Right, Bottom, Angle1,
  Angle2: Integer; AFill, ABorder: Boolean);
var
  cx, cy, rx, ry: Double;
  a1Rad, a2Rad: Double;
begin
  rx := (Right - Left) / 2.0;
  ry := (Bottom - Top) / 2.0;
  if (rx = 0) or (ry = 0) then Exit;
  cx := Left + rx;
  cy := Top + ry;
  a1Rad := Angle1 * Pi / (180 * 16);
  a2Rad := Angle2 * Pi / (180 * 16);
  cairo_save(pcr);
  try
    cairo_translate(pcr, cx + PixelOffset, cy + PixelOffset);
    cairo_scale(pcr, rx, ry);
    cairo_new_path(pcr);
    if a2Rad >= 0 then
      cairo_arc_negative(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad))
    else
      cairo_arc(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad));
    cairo_close_path(pcr);
    if AFill then
    begin
      ApplyBrush;
      cairo_fill_preserve(pcr);
    end;
  finally
    cairo_restore(pcr);
  end;
  if ABorder then
  begin
    ApplyPen;
    cairo_stroke(pcr);
  end;
  cairo_new_path(pcr);
end;

procedure TGtk4DeviceContext.drawPie(Left, Top, Right, Bottom, Angle1,
  Angle2: Integer; AFill, ABorder: Boolean);
var
  cx, cy, rx, ry: Double;
  a1Rad, a2Rad: Double;
begin
  rx := (Right - Left) / 2.0;
  ry := (Bottom - Top) / 2.0;
  if (rx = 0) or (ry = 0) then Exit;
  cx := Left + rx;
  cy := Top + ry;
  a1Rad := Angle1 * Pi / (180 * 16);
  a2Rad := Angle2 * Pi / (180 * 16);
  cairo_save(pcr);
  try
    cairo_translate(pcr, cx + PixelOffset, cy + PixelOffset);
    cairo_scale(pcr, rx, ry);
    cairo_new_path(pcr);
    { Pie: line from center to arc start, arc, line back to center }
    cairo_move_to(pcr, 0, 0);
    if a2Rad >= 0 then
      cairo_arc_negative(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad))
    else
      cairo_arc(pcr, 0, 0, 1, -a1Rad, -(a1Rad + a2Rad));
    cairo_close_path(pcr);
    if AFill then
    begin
      ApplyBrush;
      cairo_fill_preserve(pcr);
    end;
  finally
    cairo_restore(pcr);
  end;
  if ABorder then
  begin
    ApplyPen;
    cairo_stroke(pcr);
  end;
  cairo_new_path(pcr);
end;

procedure TGtk4DeviceContext.drawSurface(targetRect: PRect;
  Surface: Pcairo_surface_t; sourceRect: PRect; mask: PGdkPixBuf;
  maskRect: PRect);
var
  M: Tcairo_matrix_t;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4DeviceContext.DrawSurface ');
  {$ENDIF}
  cairo_save(pcr);
  try
    with targetRect^ do
      cairo_rectangle(pcr, Left + PixelOffset, Top + PixelOffset, Right - Left, Bottom - Top);
    cairo_set_source_surface(pcr, Surface, 0, 0);
    cairo_matrix_init_identity(@M);
    cairo_matrix_translate(@M, SourceRect^.Left, SourceRect^.Top);
    cairo_matrix_scale(@M,  (sourceRect^.Right-sourceRect^.Left) / (targetRect^.Right-targetRect^.Left),
        (sourceRect^.Bottom-sourceRect^.Top) / (targetRect^.Bottom-targetRect^.Top));
    cairo_matrix_translate(@M, -targetRect^.Left, -targetRect^.Top);
    cairo_pattern_set_matrix(cairo_get_source(pcr), @M);
    cairo_clip(pcr);
    cairo_paint(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawImage(targetRect: PRect; image: PGdkPixBuf;
  sourceRect: PRect; mask: PGdkPixBuf; maskRect: PRect);
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4DeviceContext.DrawImage ');
  {$ENDIF}
  cairo_save(pcr);
  try
    gdk_cairo_set_source_pixbuf(pcr, Image, 0, 0);
    with targetRect^ do
      cairo_rectangle(pcr, Left + PixelOffset, Top + PixelOffset, Right - Left, Bottom - Top);
    cairo_paint(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawImage1(targetRect: PRect; image: PGdkPixBuf;
  sourceRect: PRect; mask: PGdkPixBuf; maskRect: PRect);
var
  M: Tcairo_matrix_t;
  SrcL, SrcT, SrcW, SrcH: Integer;
  DstL, DstT, DstW, DstH: Integer;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4DeviceContext.DrawImage ');
  {$ENDIF}
  if (image = nil) or (targetRect = nil) then
    Exit;

  DstL := targetRect^.Left;
  DstT := targetRect^.Top;
  DstW := targetRect^.Right - targetRect^.Left;
  DstH := targetRect^.Bottom - targetRect^.Top;
  if (DstW <= 0) or (DstH <= 0) then
    Exit;

  if sourceRect <> nil then
  begin
    SrcL := sourceRect^.Left;
    SrcT := sourceRect^.Top;
    SrcW := sourceRect^.Right - sourceRect^.Left;
    SrcH := sourceRect^.Bottom - sourceRect^.Top;
  end
  else
  begin
    SrcL := 0;
    SrcT := 0;
    SrcW := gdk_pixbuf_get_width(image);
    SrcH := gdk_pixbuf_get_height(image);
  end;
  if (SrcW <= 0) or (SrcH <= 0) then
    Exit;

  cairo_save(pcr);
  try
    gdk_cairo_set_source_pixbuf(pcr, Image, 0, 0);
    cairo_rectangle(pcr, DstL + PixelOffset, DstT + PixelOffset, DstW, DstH);

    cairo_set_operator (pcr, CAIRO_OPERATOR_OVER);


    cairo_matrix_init_identity(@M);
    cairo_matrix_translate(@M, SrcL, SrcT);
    cairo_matrix_scale(@M, SrcW / DstW, SrcH / DstH);
    cairo_matrix_translate(@M, -DstL, -DstT);
    cairo_pattern_set_matrix(cairo_get_source(pcr), @M);
    cairo_clip(pcr);
    cairo_paint(pcr);
  finally
    cairo_restore(pcr);
  end;
end;


procedure TGtk4DeviceContext.drawPixmap(p: PPoint; pm: PGdkPixbuf; sr: PRect);
var
  ASurface: Pcairo_surface_t;
  AData: PByte;
begin
  {$IFDEF VerboseGtk4DeviceContext}
  DebugLn('TGtk4DeviceContext.DrawPixmap ');
  {$ENDIF}
  cairo_save(pcr);
  try
    AData := PByte(gdk_pixbuf_get_pixels(pm));
    ASurface := cairo_image_surface_create_for_data(AData, CAIRO_FORMAT_ARGB32, gdk_pixbuf_get_width(pm), gdk_pixbuf_get_height(pm), gdk_pixbuf_get_rowstride(pm));
    cairo_set_source_surface(pcr, ASurface, sr^.Left, sr^.Top);
    cairo_paint(pcr);
  finally
    cairo_surface_destroy(ASurface);
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawPolyLine(P: PPoint; NumPts: Integer);
var
  i: Integer;
begin
  cairo_save(pcr);
  try
    ApplyPen;
    cairo_move_to(pcr, P[0].X+PixelOffset, P[0].Y+PixelOffset);
    for i := 1 to NumPts-1 do
      cairo_line_to(pcr, P[i].X+PixelOffset, P[i].Y+PixelOffset);
    cairo_stroke(pcr);
  finally
    cairo_restore(pcr);
  end;

end;

procedure TGtk4DeviceContext.drawPolygon(P: PPoint; NumPts: Integer;
  FillRule: Integer; AFill, ABorder: Boolean);
var
  i: Integer;
begin
  cairo_save(pcr);
  try
    // add offset so the center of the pixel is used
    cairo_move_to(pcr, P[0].X+PixelOffset, P[0].Y+PixelOffset);
    for i := 1 to NumPts-1 do
      cairo_line_to(pcr, P[i].X+PixelOffset, P[i].Y+PixelOffset);
    cairo_close_path(pcr);

    if AFill then
    begin
      ApplyBrush;
      cairo_set_fill_rule(pcr, Tcairo_fill_rule_t(FillRule));
      cairo_fill_preserve(pcr);
    end;

    if ABorder then
    begin
      ApplyPen;
      cairo_stroke(pcr);
    end;

    cairo_new_path(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.drawPolyBezier(P: PPoint; NumPoints: Integer; Filled, Continuous: boolean);
var
  MaxIndex, i: Integer;
  bFill, bBorder: Boolean;
begin
  // 3 points per curve + a starting point for the first curve
  if (NumPoints < 4) then
    Exit;

  bFill := CurrentBrush.Style <> BS_NULL;
  bBorder := CurrentPen.Style <> psClear;

  // we need 3 points left for continuous and 4 for not continous
  MaxIndex := NumPoints - 3 - Ord(not Continuous);

  cairo_save(pcr);
  try
    i := 0;
    while i <= MaxIndex do
    begin
      if i = 0 then
      begin
        cairo_move_to(pcr, P[i].X+PixelOffset, P[i].Y+PixelOffset); // start point
        Inc(i);
      end
      else
      if not Continuous then
      begin
        cairo_line_to(pcr, P[i].X+PixelOffset, P[i].Y+PixelOffset); // start point
        Inc(i);
      end;

      cairo_curve_to(pcr,
                     P[i].X+PixelOffset, P[i].Y+PixelOffset, // control point 1
                     P[i+1].X+PixelOffset, P[i+1].Y+PixelOffset, // control point 2
                     P[i+2].X+PixelOffset, P[i+2].Y+PixelOffset); // end point and start point of next
      Inc(i, 3);
    end;

    if Filled then
    begin
      cairo_close_path(pcr);
      if bFill then
      begin
        ApplyBrush;
        cairo_fill_preserve(pcr);
      end;
    end;

    if bBorder then
    begin
      ApplyPen;
      cairo_stroke(pcr);
    end
    else
      cairo_new_path(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.eraseRect(ARect: PRect);
var
  R, G, B: Double;
begin
  if (ARect = nil) or (pcr = nil) then Exit;
  cairo_save(pcr);
  try
    { Fill with the current brush (background) color }
    ColorToCairoRGB(ColorToRgb(TColor(FCurrentBrush.Color)), R, G, B);
    cairo_set_source_rgb(pcr, R, G, B);
    cairo_rectangle(pcr, ARect^.Left, ARect^.Top,
      ARect^.Right - ARect^.Left, ARect^.Bottom - ARect^.Top);
    cairo_fill(pcr);
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.fillRect(ARect: PRect; ABrush: HBRUSH);
begin
  with ARect^ do
    fillRect(Left, Top, Right - Left, Bottom - Top, ABrush);
end;

procedure TGtk4DeviceContext.fillRect(x, y, w, h: Integer; ABrush: HBRUSH);
var
  ATempBrush: TGtk4Brush;
begin
  cairo_save(pcr);
  try
    ATempBrush := nil;
    if ABrush <> 0 then
    begin
      ATempBrush := FCurrentBrush;
      fBkMode := OPAQUE;
      CurrentBrush:= TGtk4Brush(ABrush);
    end;

    applyBrush;
    cairo_rectangle(pcr, x + PixelOffset, y + PixelOffset, w - 1, h - 1);
    cairo_fill_preserve(pcr);

    // must paint border, filling is not enough
    SetSourceColor(FCurrentBrush.Color);
    cairo_set_line_width(pcr, 1);
    cairo_stroke(pcr);

    if ABrush <> 0 then
      CurrentBrush:= ATempBrush;
  finally
    cairo_restore(pcr);
  end;
end;

procedure TGtk4DeviceContext.fillRect(x, y, w, h: Integer);
begin
  fillRect(x, y, w, h , 0);
end;

procedure TGtk4DeviceContext.FillAndStroke;
begin
  if Assigned(FCurrentBrush) and (FCurrentBrush.Style <> BS_NULL) then
  begin
    ApplyBrush;
    if Assigned(FCurrentPen) and (FCurrentPen.Style = psClear) then
      cairo_fill(pcr)
    else
      cairo_fill_preserve(pcr);
  end;
  if Assigned(FCurrentPen) and (FCurrentPen.Style <> psClear) then
  begin
    ApplyPen;
    cairo_stroke(pcr);
  end;
end;

procedure TGtk4DeviceContext.EllipseArcPath(CX, CY, RX, RY: Double; Angle1, Angle2: Double; Clockwise, Continuous: Boolean);
begin
  if (RX=0) or (RY=0) then //cairo_scale do not likes zero params
    Exit;
  cairo_save(pcr);
  try
    cairo_translate(pcr, SX(CX), SY(CY));
    cairo_scale(pcr, SX2(RX), SY2(RY));
    if not Continuous then
      cairo_move_to(pcr, cos(Angle1), sin(Angle1)); //Move to arcs starting point
    if Clockwise then
      cairo_arc(pcr, 0, 0, 1, Angle1, Angle2)
    else
      cairo_arc_negative(pcr, 0, 0, 1, Angle1, Angle2);
  finally
    cairo_restore(pcr);
  end;
end;

function TGtk4DeviceContext.RoundRect(X1, Y1, X2, Y2: Integer; RX, RY: Integer): Boolean;
var
  DX, DY,drx,dry: Double;
begin
  Result := False;
  cairo_surface_get_device_offset(cairo_get_target(pcr), @DX, @DY);
  DX := DX+PixelOffset;
  DY := DY+PixelOffset;
  drx:=rx/2;
  dry:=ry/2;
  cairo_translate(pcr, DX, DY);
  try
    cairo_move_to(pcr, X1+dRX, Y1);
    cairo_line_to(pcr, X2-dRX-PixelOffset, Y1);
    EllipseArcPath(X2-dRX-PixelOffset, Y1+dRY, dRX, dRY, -PI/2, 0, True, True);
    cairo_line_to(pcr, X2-PixelOffset, Y2-dRY-PixelOffset);
    EllipseArcPath(X2-dRX-PixelOffset, Y2-dRY-PixelOffset, dRX, dRY, 0, PI/2, True, True);
    cairo_line_to(pcr, X1+dRX, Y2-PixelOffset);
    EllipseArcPath(X1+dRX, Y2-dRY-PixelOffset, dRX, dRY, PI/2, PI, True, True);
    cairo_line_to(pcr, X1, Y1+dRX);
    EllipseArcPath(X1+dRX, Y1+dRY, dRX, dRY, PI, PI*1.5, True, True);
    FillAndStroke;
    Result := True;
  finally
    cairo_translate(pcr, -DX, -DY);
  end;
end;

function TGtk4DeviceContext.drawFrameControl(arect:TRect;uType,uState:cardinal):boolean;

  function MapStateFlags(aState: Cardinal): TGtkStateFlags;
  begin
    Result := [];
    if (aState and DFCS_INACTIVE) <> 0 then
      Include(Result, GTK_STATE_FLAG_INSENSITIVE);
    if (aState and DFCS_PUSHED) <> 0 then
      Include(Result, GTK_STATE_FLAG_ACTIVE);
    if (aState and DFCS_CHECKED) <> 0 then
      Include(Result, GTK_STATE_FLAG_CHECKED);
    if (aState and DFCS_HOT) <> 0 then
      Include(Result, GTK_STATE_FLAG_PRELIGHT);
  end;

  function DrawButton: Boolean;
  var
    w: PGtkWidget;
    Context: PGtkStyleContext;
    StateFlags: TGtkStateFlags;
    SubType: Cardinal;
  begin
    Result := False;
    SubType := uState and $1F;
    StateFlags := MapStateFlags(uState);

    if SubType in [DFCS_BUTTONCHECK, DFCS_BUTTON3STATE] then
    begin
      w := GetStyleWidget(lgsCheckbox);
      if not Assigned(w) then exit;
      Context := w^.get_style_context;
      gtk_style_context_set_state(Context, StateFlags);
      with aRect do
      begin
        gtk_render_background(Context, pcr, Left, Top, Right - Left, Bottom - Top);
        gtk_render_check(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      end;
      Result := True;
    end
    else if (SubType = DFCS_BUTTONRADIO)
         or (SubType = DFCS_BUTTONRADIOIMAGE)
         or (SubType = DFCS_BUTTONRADIOMASK) then
    begin
      w := GetStyleWidget(lgsRadiobutton);
      if not Assigned(w) then exit;
      Context := w^.get_style_context;
      gtk_style_context_set_state(Context, StateFlags);
      with aRect do
      begin
        gtk_render_background(Context, pcr, Left, Top, Right - Left, Bottom - Top);
        gtk_render_option(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      end;
      Result := True;
    end
    else { DFCS_BUTTONPUSH and default }
    begin
      w := GetStyleWidget(lgsButton);
      if not Assigned(w) then exit;
      Context := w^.get_style_context;
      gtk_style_context_set_state(Context, StateFlags);
      with aRect do
      begin
        gtk_render_background(Context, pcr, Left, Top, Right - Left, Bottom - Top);
        gtk_render_frame(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      end;
      Result := True;
    end;
  end;

  function DrawScroll: Boolean;
  var
    w: PGtkWidget;
    Context: PGtkStyleContext;
    StateFlags: TGtkStateFlags;
    SubType: Cardinal;
    ArrowAngle: Double;
    ArrowSize: Double;
  begin
    Result := False;
    SubType := uState and $1F;
    StateFlags := MapStateFlags(uState);

    w := GetStyleWidget(lgsVerticalScrollbar);
    if not Assigned(w) then exit;
    Context := w^.get_style_context;
    gtk_style_context_set_state(Context, StateFlags);

    { gtk_render_arrow angle: 0=up, pi/2=right, pi=down, 3pi/2=left }
    case SubType of
      DFCS_SCROLLUP:    ArrowAngle := 0;
      DFCS_SCROLLDOWN:  ArrowAngle := Pi;
      DFCS_SCROLLLEFT:  ArrowAngle := 3 * Pi / 2;
      DFCS_SCROLLRIGHT: ArrowAngle := Pi / 2;
    else
      exit;
    end;

    with aRect do
    begin
      gtk_render_background(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      gtk_render_frame(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      ArrowSize := Right - Left;
      if (Bottom - Top) < ArrowSize then
        ArrowSize := Bottom - Top;
      gtk_render_arrow(Context, pcr, ArrowAngle, Left, Top, ArrowSize);
    end;
    Result := True;
  end;

  function DrawMenu: Boolean;
  var
    w: PGtkWidget;
    Context: PGtkStyleContext;
    StateFlags: TGtkStateFlags;
    SubType: Cardinal;
  begin
    Result := False;
    SubType := uState and $1F;
    StateFlags := MapStateFlags(uState);

    w := GetStyleWidget(lgsMenuitem);
    if not Assigned(w) then
      w := GetStyleWidget(lgsMenu);
    if not Assigned(w) then exit;
    Context := w^.get_style_context;
    gtk_style_context_set_state(Context, StateFlags);

    with aRect do
    begin
      gtk_render_background(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      case SubType of
        DFCS_MENUCHECK:
          gtk_render_check(Context, pcr, Left, Top, Right - Left, Bottom - Top);
        DFCS_MENUBULLET:
          gtk_render_option(Context, pcr, Left, Top, Right - Left, Bottom - Top);
        DFCS_MENUARROW:
          gtk_render_arrow(Context, pcr, Pi / 2, Left, Top, Right - Left);
      else
        gtk_render_frame(Context, pcr, Left, Top, Right - Left, Bottom - Top);
      end;
    end;
    Result := True;
  end;

begin
  Result := False;
  case uType of
    DFC_BUTTON:  Result := DrawButton;
    DFC_SCROLL:  Result := DrawScroll;
    DFC_MENU:    Result := DrawMenu;
    DFC_CAPTION: ; { caption buttons not supported in GTK4 }
  end;
end;

function TGtk4DeviceContext.drawFocusRect(const aRect: TRect): boolean;
var
  Context: PGtkStyleContext;
begin
  Result := False;

  if Parent <> nil then
  begin
    Context := Parent^.get_style_context;
    with aRect do
      gtk_render_focus(Context, pcr, Left, Top, Right - Left, Bottom - Top);
  end else
  begin
    { Non-widget DC: draw a standard dotted focus rectangle with Cairo }
    cairo_save(pcr);
    cairo_set_line_width(pcr, 1.0);
    cairo_set_source_rgb(pcr, 0.0, 0.0, 0.0);
    cairo_set_dash(pcr, @FocusDashPattern[0], 2, 0);
    cairo_rectangle(pcr, aRect.Left + 0.5, aRect.Top + 0.5,
      aRect.Right - aRect.Left - 1, aRect.Bottom - aRect.Top - 1);
    cairo_stroke(pcr);
    cairo_restore(pcr);
  end;

  Result := True;
end;

function TGtk4DeviceContext.getBpp: integer;
begin
  // GTK4: GdkVisual/gdk_window_get_visual removed. Default to 8 bits per channel.
  if (ParentPixmap <> nil) and (Parent = nil) then
    Result := ParentPixmap^.get_bits_per_sample
  else
    Result := 8;
end;

function TGtk4DeviceContext.getDepth: integer;
begin
  // GTK4: GdkVisual/gdk_window_get_visual removed. Default to 32-bit depth.
  Result := 32;
end;

function TGtk4DeviceContext.getDeviceSize: TPoint;
begin
  Result := Point(0 , 0);
  if Parent <> nil then
  begin
    Result.y := Parent^.get_allocated_height;
    Result.x := Parent^.get_allocated_width;
  end else
  if ParentPixmap <> nil then
  begin
    Result.y := ParentPixmap^.height;
    Result.x := ParentPixmap^.width;
  end;
  // GTK4: GdkWindow branch removed
end;

function TGtk4DeviceContext.LineTo(X, Y: Integer): Boolean;
var
  FX, FY: Double;
  X0, Y0,dx,dy:integer;
begin
  if not Assigned(pcr) then
    exit(False);
  ApplyPen;


  if fCurrentPen.Width<=1 then // optimizations
  begin
    cairo_get_current_point(pcr, @FX, @FY);
    X0:=round(FX);
    Y0:=round(FY);
    dx:=X-X0;
    dy:=Y-Y0;

    if (dx=0) and (dy=0) then exit;

    if (dx=0) then
    begin
      cairo_move_to(pcr,X+PixelOffset,Y0);
      cairo_line_to(pcr,X+PixelOffset,Y);
    end else
    if (dy=0) then
    begin
      cairo_move_to(pcr,X0,Y+PixelOffset);
      cairo_line_to(pcr,X,Y+PixelOffset);
    end else
    if abs(dx)=abs(dy) then
    begin
      // here is required more Cairo magic
      if (dx>0) then
      begin
        cairo_move_to(pcr,FX-PixelOffset,FY-PixelOffset);
        cairo_line_to(pcr,X+2*PixelOffset, Y+2*PixelOffset);
      end else
      begin
        cairo_move_to(pcr,FX+2*PixelOffset,FY);
        cairo_line_to(pcr,X+PixelOffset, Y+PixelOffset);
      end;
    end else
      cairo_line_to(pcr,X+PixelOffset, Y+PixelOffset);

  end else
    cairo_line_to(pcr,X+PixelOffset, Y+PixelOffset);

  cairo_stroke_preserve(pcr);
  Result := True;
end;

function TGtk4DeviceContext.MoveTo(const X, Y: Integer; OldPoint: PPoint): Boolean;
var
  dx: Double;
  dy: Double;
begin
  if not Assigned(pcr) then
    exit(False);
  if OldPoint <> nil then
  begin
    cairo_get_current_point(pcr, @dx, @dy);
    OldPoint^.X := Round(dx);
    OldPoint^.Y := Round(dy);
  end;
  cairo_move_to(pcr, X{-PixelOffset}, Y{-PixelOffset});
  Result := True;
end;

function TGtk4DeviceContext.SetClipRegion(ARgn: TGtk4Region): Integer;
begin
  Result := SimpleRegion;
  if Assigned(pcr) then
  begin
    cairo_reset_clip(pcr);
    gdk_cairo_region(pcr, ARgn.FHandle);
    cairo_clip(pcr);
  end;
end;

procedure TGtk4DeviceContext.SetSourceColor(AColor: TColor);
var
  R, G, B: double;
begin
  TColorToRGB(AColor, R, G, B);
  cairo_set_source_rgb(pcr, R, G, B);
end;

procedure TGtk4DeviceContext.SetImage(AImage: TGtk4Image);
var
  APixBuf: PGdkPixbuf;
begin
  FCurrentImage := AImage;
  cairo_destroy(pcr);
  APixBuf := AImage.Handle;
  if not Gtk4IsGdkPixbuf(APixBuf) then
  begin
    {$IFDEF GTK4DEBUGCORE}
    DebugLn('ERROR: TGtk4DeviceContext.SetImage image handle isn''t PGdkPixbuf.');
    {$ENDIF}
    exit;
  end;
  if FOwnsSurface and (CairoSurface <> nil) then
    cairo_surface_destroy(CairoSurface);
  CairoSurface := cairo_image_surface_create_for_data(APixBuf^.pixels,
                                                AImage.Format,
                                                APixBuf^.get_width,
                                                APixBuf^.get_height,
                                                APixBuf^.rowstride);
  pcr := cairo_create(CairoSurface);
  FOwnsSurface := true;
end;

function TGtk4DeviceContext.ResetClip: Integer;
begin
  Result := NullRegion;
  if Assigned(pcr) then
    cairo_reset_clip(pcr);
end;

procedure TGtk4DeviceContext.TranslateCairoToDevice;
var
  Pt: TPoint;
begin
  Pt := Offset;
  Translate(Pt);
end;

procedure TGtk4DeviceContext.Translate(APoint: TPoint);
begin
  cairo_translate(pcr, APoint.X, APoint.Y);
end;

procedure TGtk4DeviceContext.set_antialiasing(aamode: boolean);
const
   caa:array[boolean] of Tcairo_antialias_t = (CAIRO_ANTIALIAS_NONE,CAIRO_ANTIALIAS_DEFAULT);
begin
  cairo_set_antialias(pcr, caa[aamode]);
end;


//various routines for text

// LCL denotes accelerator keys by '&', while Gtk denotes them with '_'.
// LCL allows to show literal '&' by escaping (doubling) it.
// Gtk allows to show literal '_' by escaping (doubling) it.
// As the situation for LCL and Gtk is symmetric, conversion is made by generic function.
function TransformAmpersandsAndUnderscores(const S: string; const FromChar, ToChar: char): string;
var
  i: Integer;
begin
  Result := '';
  i := 1;
  while i <= Length(S) do
  begin
    if S[i] = ToChar then
      Result := Result + ToChar + ToChar
    else
      if S[i] = FromChar then
        if i < Length(S) then
        begin
          if S[i + 1] = FromChar then
          begin
            Result := Result + FromChar;
            inc(i);
          end
          else
            Result := Result + ToChar;
        end
        else
          Result := Result + FromChar
      else
        Result := Result + S[i];
    inc(i);
  end;
end;

function ReplaceAmpersandsWithUnderscores(const S: string): string; inline;
begin
  Result := TransformAmpersandsAndUnderscores(S, '&', '_');
end;

function ReplaceUnderscoresWithAmpersands(const S: string): string; inline;
begin
  Result := TransformAmpersandsAndUnderscores(S, '_', '&');
end;

{-------------------------------------------------------------------------------
  function GetTextExtentIgnoringAmpersands(TheFont: PGDKFont;
    Str : PChar; StrLength: integer;
    MaxWidth: Longint; lbearing, rbearing, width, ascent, descent : Pgint);

  Gets text extent of a string, ignoring escaped Ampersands.
  That means, ampersands are not counted.
  Negative MaxWidth means no limit.
-------------------------------------------------------------------------------}
procedure GetTextExtentIgnoringAmpersands(TheFont: TGtk4Font;
  Str : PChar; StrLength: integer;
  lbearing, rbearing, width, ascent, descent : Pgint);
var
  NewStr : PChar;
  AMetrics: PPangoFontMetrics;
  {ACharWidth,}ATextWidth,ATextHeight: gint;
begin
  if lbearing<>nil then
    lbearing^:=0;
  if rbearing<>nil then
    rbearing^:=0;
  // check if Str contains an ampersand before removing them all.
  if StrLScan(Str, '&', StrLength) <> nil then
    NewStr := RemoveAmpersands(Str, StrLength)
  else
    NewStr := Str;
  TheFont.Layout^.set_text(NewStr, StrLength);
  // TheFont.Layout^.get_extents(@AInkRect, @ALogicalRect);

  AMetrics := pango_context_get_metrics(TheFont.Layout^.get_context, TheFont.Handle, TheFont.Layout^.get_context^.get_language);
  if AMetrics = nil then
  begin
    Debugln('WARNING: GetTextExtentIgnoringAmpersands AMetrics=nil');
    exit;
  end;

  if ascent <> nil then
    ascent^ := AMetrics^.get_ascent;
  if descent <> nil then
    descent^ := AMetrics^.get_descent;
  if width <> nil then
  begin
    TheFont.Layout^.get_pixel_size(@ATextWidth, @ATextHeight);
    width^:=ATextWidth;
  end;
  if NewStr <> Str then
    StrDispose(NewStr);
  AMetrics^.unref;
end;

{------------------------------------------------------------------------------
  procedure Gtk4WordWrap(DC: HDC; AText: PChar; MaxWidthInPixel: integer;
    var Lines: PPChar; var LineCount: integer); virtual;

  Breaks AText into several lines and creates a list of PChar. The last entry
  will be nil.
  Lines break at new line chars and at spaces if a line is longer than
  MaxWidthInPixel or in a word.
  Lines will be one memory block so that you can free the list and all lines
  with FreeMem(Lines).
------------------------------------------------------------------------------}
procedure Gtk4WordWrap(DC: HDC; AText: PChar;
  MaxWidthInPixel: integer; out Lines: PPChar; out LineCount: integer);
var
  UseFont: TGtk4Font;

  function GetLineWidthInPixel(LineStart, LineLen: integer): integer;
  var
    width: LongInt;
  begin
    GetTextExtentIgnoringAmpersands(UseFont, @AText[LineStart], LineLen,
                                    nil, nil, @width, nil, nil);
    Result := Width;
  end;

  function FindLineEnd(LineStart: integer): integer;
  var
    CharLen,
    LineStop,
    LineWidth, WordWidth, WordEnd, CharWidth: integer;
  begin
    // first search line break or text break
    Result:=LineStart;
    while not (AText[Result] in [#0,#10,#13]) do inc(Result);
    if Result<=LineStart+1 then exit;
    lineStop:=Result;

    // get current line width in pixel
    LineWidth:=GetLineWidthInPixel(LineStart,Result-LineStart);
    if LineWidth>MaxWidthInPixel then
    begin
      // line too long
      // -> add words till line size reached
      LineWidth:=0;
      WordEnd:=LineStart;
      WordWidth:=0;
      repeat
        Result:=WordEnd;
        inc(LineWidth,WordWidth);
        // find word start
        while AText[WordEnd] in [' ',#9] do inc(WordEnd);
        // find word end
        while not (AText[WordEnd] in [#0,' ',#9,#10,#13]) do inc(WordEnd);
        // calculate word width
        WordWidth:=GetLineWidthInPixel(Result,WordEnd-Result);
      until LineWidth+WordWidth>MaxWidthInPixel;
      if LineWidth=0 then
      begin
        // the first word is longer than the maximum width
        // -> add chars till line size reached
        Result:=LineStart;
        LineWidth:=0;
        repeat
          charLen:=UTF8CodepointSize(@AText[result]);
          CharWidth:=GetLineWidthInPixel(Result,charLen);
          inc(LineWidth,CharWidth);
          if LineWidth>MaxWidthInPixel then break;
          if result>=lineStop then break;
          inc(Result,charLen);
        until false;
        // at least one char
        if Result=LineStart then begin
          charLen:=UTF8CodepointSize(@AText[result]);
          inc(Result,charLen);
        end;
      end;
    end;
  end;

  function IsEmptyText: boolean;
  begin
    if (AText=nil) or (AText[0]=#0) then
    begin
      // no text
      GetMem(Lines,SizeOf(PChar));
      Lines[0]:=nil;
      LineCount:=0;
      Result:=true;
    end else
      Result:=false;
  end;

  procedure InitFont;
  begin
    UseFont := TGtk4DeviceContext(DC).CurrentFont;
  end;

var
  LinesList: TIntegerList;
  LineStart, LineEnd, LineLen: integer;
  ArraySize, TotalSize: integer;
  i: integer;
  CurLineEntry: PPChar;
  CurLineStart: PChar;
begin
  if IsEmptyText then
  begin
    Lines:=nil;
    LineCount:=0;
    exit;
  end;
  InitFont;
  LinesList:=TIntegerList.Create;
  LineStart:=0;

  // find all line starts and line ends
  repeat
    LinesList.Add(LineStart);
    // find line end
    LineEnd:=FindLineEnd(LineStart);
    LinesList.Add(LineEnd);
    // find next line start
    LineStart:=LineEnd;
    if AText[LineStart] in [#10,#13] then
    begin
      // skip new line chars
      inc(LineStart);
      if (AText[LineStart] in [#10,#13])
      and (AText[LineStart]<>AText[LineStart-1]) then
        inc(LineStart);
    end else
    if AText[LineStart] in [' ',#9] then
    begin
      // skip space
      while AText[LineStart] in [' ',#9] do
        inc(LineStart);
    end;
  until AText[LineStart]=#0;

  // create mem block for 'Lines': array of PChar + all lines
  LineCount:=LinesList.Count shr 1;
  ArraySize:=(LineCount+1)*SizeOf(PChar);
  TotalSize:=ArraySize;
  i:=0;
  while i<LinesList.Count do
  begin
    // add  LineEnd - LineStart + 1 for the #0
    LineLen:=LinesList[i+1]-LinesList[i]+1;
    inc(TotalSize,LineLen);
    inc(i,2);
  end;
  GetMem(Lines,TotalSize);
  FillChar(Lines^,TotalSize,0);

  // create Lines
  CurLineEntry:=Lines;
  CurLineStart:=PChar(CurLineEntry)+ArraySize;
  i:=0;
  while i<LinesList.Count do
  begin
    // set the pointer to the start of the current line
    CurLineEntry[i shr 1]:=CurLineStart;
    // copy the line
    LineStart:=LinesList[i];
    LineEnd:=LinesList[i+1];
    LineLen:=LineEnd-LineStart;
    if LineLen>0 then
      Move(AText[LineStart],CurLineStart^,LineLen);
    inc(CurLineStart,LineLen);
    // add #0 as line end
    CurLineStart^:=#0;
    inc(CurLineStart);
    // next line
    inc(i,2);
  end;
  if {%H-}PtrUInt(CurLineStart)-{%H-}PtrUInt(Lines)<>TotalSize then
    RaiseGDBException('Gtk4WordWrap Consistency Error:'
      +' Lines+TotalSize<>CurLineStart');
  CurLineEntry[i shr 1]:=nil;

  LinesList.Free;
end;

end.
