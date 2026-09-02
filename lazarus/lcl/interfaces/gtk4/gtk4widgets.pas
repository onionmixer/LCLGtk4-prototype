{
 *****************************************************************************
 *                               gtk4widgets.pas                             *
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

unit Gtk4Widgets;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

interface

uses
  {$IFDEF UNIX}dynlibs,{$ENDIF}
  Classes, SysUtils, types, math,
  // LCL
  Controls, StdCtrls, ExtCtrls, Buttons, ComCtrls, Graphics, Dialogs, Forms, Menus, ExtDlgs,
  Spin, CheckLst, PairSplitter, LCLType, LMessages, LCLMessageGlue, LCLIntf,
  // LazUtils
  GraphType, LazUtilities, LCLProc, LazLoggerBase, LazUTF8, Maps,
  // GTK4
  LazGtk4, LazGdk4, LazGObject2, LazGLib2, LazGio2, LazCairo1, LazPango1, LazGdkPixbuf2,
  LazGsk4, LazGtk4_Compat, gtk4objects, gtk4procs, gtk4private, Gtk4CellRenderer;

const
  GTK4_COORD_SANITY_LIMIT = 1000000;

type
  TByteSet = set of byte;

  // records
  TPaintData = record
    PaintWidget: PGtkWidget;
    ClipRect: PRect;
    ClipRegion: Pcairo_region_t;
  end;

  TDefaultRGBA = record
    R: Double;
    G: Double;
    B: Double;
    Alpha: Double;
  end;

  TGtk4WidgetType = (wtWidget, wtStaticText, wtProgressBar, wtLayout,
    wtContainer, wtMenuBar, wtMenu, wtMenuItem, wtEntry, wtSpinEdit,
    wtNotebook, wtTabControl, wtComboBox,
    wtGroupBox, wtCalendar, wtTrackBar, wtScrollBar,
    wtScrollingWin, wtListBox, wtListView, wtCheckListBox, wtMemo, wtTreeModel,
    wtCustomControl, wtScrollingWinControl,
    wtWindow, wtDialog, wtHintWindow, wtGLArea);
  TGtk4WidgetTypes = set of TGtk4WidgetType;

  { TGtk4Widget }

  TGtk4Widget = class(TGtk4Object, IUnknown)
  strict private
    FCairoContext: Pcairo_t;
    FCentralWidgetRGBA: array [0{GTK_STATE_NORMAL}..4{GTK_STATE_INSENSITIVE}] of TDefaultRGBA;
    FContext: HDC;
    FWidgetCssProvider: PGtkCssProvider;
    FWidgetCssFont: String;
    FWidgetCssFgColor: String;
    FWidgetCssBgColor: String;
    FWidgetCssBorder: String;
    FEnterLeaveTime: Cardinal;
    FFocusableByMouse: Boolean; {shell we call SetFocus on mouse down. Default = False}
    FVisibleState: Boolean;
    FOwner: PGtkWidget;
    FPaintData: TPaintData;
    FProps: TStringList;
    FWidgetRGBA: array [0{GTK_STATE_NORMAL}..4{GTK_STATE_INSENSITIVE}] of TDefaultRGBA;
    procedure ApplyWidgetCss(const ACss: String);
    function GetCairoContext: Pcairo_t;
    function GetEnabled: Boolean;
    function GetFont: PPangoFontDescription;
    function GetStyleContext: PGtkStyleContext;
    function GetVisible: Boolean;
    procedure SetEnabled(AValue: Boolean);
    procedure SetFont(AValue: PPangoFontDescription);
    procedure SetVisible(AValue: Boolean);
    procedure SetStyleContext(AValue: PGtkStyleContext);
    class procedure destroy_event(widget: PGtkWidget; data: gpointer); cdecl;
  protected
    FCentralWidget: PGtkWidget;
    FDesignerDC: HDC;       { Non-zero during designer paint phase 2 (selection handles) }
    FHasPaint: Boolean;
    FKeysToEat: TByteSet;
    FLastKeyVal: Word;    { For auto-repeat detection: last key pressed }
    FLastKeyPress: Boolean; { True if last key event was a press }
    FLastMotionPos: TPoint;               { Motion dedup: last delivered client pos }
    FLastMotionState: TGdkModifierType;   { Motion dedup: last modifier/button state }
    FLastMotionValid: Boolean;            { False until first motion after enter/leave }
    FIMContext: PGtkIMContext; { GTK4: Input method context for CJK/Hangul etc. }
    FIMPreeditActive: Boolean; { True while in preedit composition (CJK/Hangul) }
    FIMSkipDelete: Boolean;    { First preedit-changed after start: no REPLACE flag }
    FPaintArea: PGtkDrawingArea; { GTK4: overlay drawing area for custom painting }
    FParams: TCreateParams;
    fText: string;
    FOwnWidget: Boolean;
    FWidget: PGtkWidget;
    FWidgetType: TGtk4WidgetTypes;
    // IUnknown implementation
    function QueryInterface(constref iid: TGuid; out obj): LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _AddRef: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function _Release: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
    function EatArrowKeys(const AKey: Word): Boolean; virtual;
    { Offset of the LCL client area origin within the widget (e.g. a form's
      menu bar, a notebook's tab bar).  Used by ClientToScreen/ScreenToClient
      so that TWinControl.ClientOrigin points at the real client area —
      required for ControlAtPos hit-testing (hints, drag targets). }
    function GetClientAreaOffset: TPoint; virtual;
    function getText: String; virtual;
    procedure setText(const AValue: String); virtual;
    function GetContext: HDC; virtual;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; virtual;
    procedure DetachEvents; virtual;
    procedure DestroyWidget; virtual;
    procedure DoBeforeLCLPaint; virtual;
    procedure SetupPaintArea(AOverlay: PGtkOverlay);

    function GetColor: TColor; virtual;
    procedure SetColor(AValue: TColor); virtual;
    function GetFontColor: TColor; virtual;
    procedure SetFontColor(AValue: TColor); virtual;
    function GetWidget:PGtkWidget;
  public
    LCLObject: TWinControl;
  public
    function CanSendLCLMessage: Boolean;
    constructor Create(const AWinControl: TWinControl; const AParams: TCreateParams); virtual; overload;
    constructor CreateFrom(const AWinControl: TWinControl; AWidget: PGtkWidget); virtual;

    procedure InitializeWidget; virtual;
    procedure UpdateWidgetConstraints;virtual;
    procedure DeInitializeWidget;
    procedure RecreateWidget;
    procedure DestroyNotify({%H-}AWidget: PGtkWidget); virtual;
    destructor Destroy; override;

    function CanFocus: Boolean; virtual;
    function GetFocusableByMouse: Boolean;
    function getClientOffset: TPoint; virtual;
    function getWidgetPos: TPoint; virtual;

    procedure OffsetMousePos(APoint: PPoint); virtual;

    function ClientToScreen(var P:TPoint):boolean;
    function ScreenToClient(var P: TPoint): Integer;

    function DeliverMessage(var Msg; const AIsInputEvent: Boolean = False): LRESULT; virtual;
    function GtkEventMouseEnterLeave(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventKey(Sender: PGtkWidget; Event: PGdkEvent; AKeyPress: Boolean): Boolean; virtual; cdecl;
    function GtkEventMouse(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventMouseMove(Sender: PGtkWidget; Event: PGdkEvent): Boolean; virtual; cdecl;
    function GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t): Boolean; virtual; cdecl;
    procedure GtkEventDesignerPaint(Sender: PGtkWidget; AContext: Pcairo_t);
    procedure GtkEventFocus(Sender: PGtkWidget; Event: PGdkEvent); cdecl;
    procedure GtkEventDestroy; cdecl;
    function IsValidHandle: Boolean;
    function IsWidgetOk: Boolean; virtual;
    function IsIconic: Boolean; virtual;

    function getType: TGType;
    function getTypeName: PgChar;

    procedure lowerWidget; virtual;
    procedure raiseWidget; virtual;
    procedure stackUnder(AWidget: PGtkWidget); virtual;

    function GetCapture: TGtk4Widget; virtual;
    function SetCapture: HWND; virtual;

    function getClientRect: TRect; virtual;
    function getClientBounds: TRect; virtual;

    procedure SetBounds(ALeft,ATop,AWidth,AHeight:integer);virtual;
    procedure SetLclFont(const AFont:TFont);virtual;

    function GetContainerWidget: PGtkWidget; virtual;
    function GetPosition(out APoint: TPoint): Boolean; virtual;
    procedure Release; override;
    procedure Hide; virtual;
    function getParent: TGtk4Widget;
    function GetWindow: PGdkWindow; virtual;
    procedure Move(ALeft, ATop: Integer);
    procedure Activate; virtual;
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer; {%H-}WithThemeSpace: Boolean); virtual;
    procedure SetBorderStyle(AValue: TBorderStyle);
    procedure SetCursor(ACursor: HCURSOR);
    procedure SetFocus; virtual;
    procedure SetParent(AParent: TGtk4Widget; const ALeft, ATop: Integer); virtual;
    procedure Show; virtual;
    procedure ShowAll; virtual;
    procedure Update(ARect: PRect); virtual;
    property CairoContext: Pcairo_t read GetCairoContext;
    property Color: TColor read GetColor write SetColor;
    property Context: HDC read GetContext;
    property DesignerDC: HDC read FDesignerDC;
    property Enabled: Boolean read GetEnabled write SetEnabled;
    property Font: PPangoFontDescription read GetFont write SetFont;
    property FontColor: TColor read GetFontColor write SetFontColor;
    property IMContext: PGtkIMContext read FIMContext;
    property KeysToEat: TByteSet read FKeysToEat write FKeysToEat;
    property PaintData: TPaintData read FPaintData write FPaintData;
    property StyleContext: PGtkStyleContext read GetStyleContext write SetStyleContext;
    property Text: String read getText write setText;
    property Visible: Boolean read GetVisible write SetVisible;
    property Widget: PGtkWidget read GetWidget;
    property WidgetType: TGtk4WidgetTypes read FWidgetType;
  end;

  { TGtk4Editable }

  TGtk4Editable = class(TGtk4Widget)
  private
    FSelStartPending: Boolean;    { setSelStart is deferred, see ApplyPendingSelStart }
    FPendingSelStart: Integer;    { valid only while FSelStartPending }
    FPendingSelStartIdle: guint;  { g_idle_add_full id of the deferred apply, 0 = none }
    function GetReadOnly: Boolean;
    procedure SetReadOnly(AValue: Boolean);
  protected
    PrivateCursorPos: Integer; // used only for delayed selStart and selLength
    PrivateSelection: Integer;
    function getCaretPos: TPoint; virtual;
    procedure SetCaretPos(AValue: TPoint); virtual;
    procedure ApplyPendingSelStart;
    procedure CancelPendingSelStart;
  public
    function DeliverMessage(var Msg; const AIsInputEvent: Boolean = False): LRESULT; override;
    procedure DetachEvents; override;
    function getSelStart: Integer; virtual;
    function getSelLength: Integer; virtual;
    procedure setSelStart(AValue: Integer); virtual;
    procedure setSelLength(AValue: Integer); virtual;
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
  end;

  { TGtk4Entry }

  TGtk4Entry = class(TGtk4Editable)
  private
    FUndoBaseline: String;   { text at the last programmatic setText; used to
                               approximate CanUndo (GtkText exposes no can-undo). }
    FDelegateKeyPending: Boolean;     { an unmodified key press is in flight on
                                        the inner GtkText — gates OnKeyPress }
    FSuppressInsertFeedback: Boolean; { guards programmatic + re-entrant inserts }
    FPendingKeyText: String;          { unicode text of the pending unmodified
                                        key — identifies raw-key bypass inserts }
    FPreeditText: String;             { observed IM preedit on the delegate }
    FDeferredText: String;            { raw key text deferred until the pending
                                        IM commit lands (fcitx5-gtk4 ordering) }
    FFlushingDeferred: Boolean;       { re-entrancy: flushing FDeferredText }
    function GetAlignment: TAlignment;
    procedure SetAlignment(AValue: TAlignment);
  protected
    function EatArrowKeys(const AKey: Word): Boolean; override;
    procedure InsertText(const atext:pchar;len:gint;var pos:gint;edt:TGtk4Entry);cdecl;
    function getText: String; override;
    procedure setText(const AValue: String); override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure SetBounds(Left,Top,Width,Height:integer);override;
    procedure InitializeWidget; override;
    procedure UpdateWidgetConstraints;override;
    procedure SetEchoMode(AVisible: Boolean);
    procedure SetMaxLength(AMaxLength: Integer);
    procedure SetPasswordChar(APasswordChar: Char);
    procedure SetNumbersOnly(ANumbersOnly:boolean);
    procedure SetTextHint(const AHint:string);
    procedure SetFrame(const aborder:boolean);
    function GetTextHint:string;
    function IsWidgetOk: Boolean; override;
    { Approximate CanUndo: GtkText/GtkEntry expose no can-undo query, so we
      report whether the current text differs from the last programmatically-set
      value (undoing user edits back to that baseline clears it). }
    function GetCanUndoState: Boolean;
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property TextHint:string read GetTextHint write SetTextHint;
  end;

  { TGtk4SpinEdit }

  TGtk4SpinEdit = class(TGtk4Entry)
  private
    function GetMaximum: Double;
    function GetMinimum: Double;
    function GetNumDigits: Integer;
    function GetNumeric: Boolean;
    function GetStep: Double;
    function GetValue: Double;
    procedure SetNumDigits(AValue: Integer);
    procedure SetNumeric(AValue: Boolean);
    procedure SetStep(AValue: Double);
    procedure SetValue(AValue: Double);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
  public
    function IsWidgetOk: Boolean; override;
    procedure SetRange(AMin, AMax: Double);
    property Minimum: Double read GetMinimum;
    property Maximum: Double read GetMaximum;
    property Numeric: Boolean read GetNumeric write SetNumeric;
    property NumDigits: Integer read GetNumDigits write SetNumDigits;
    property Step: Double read GetStep write SetStep;
    property Value: Double read GetValue write SetValue;
  end;

  { TGtk4Range }

  TGtk4Range = class(TGtk4Widget)
  private
    function GetPosition: Integer; reintroduce;
    function GetRange: TPoint;
    procedure SetPosition(AValue: Integer);
    procedure SetRange(AValue: TPoint);
  public
    procedure InitializeWidget; override;
    procedure SetStep(AStep: Integer; APageSize: Integer);
    property Range: TPoint read GetRange write SetRange;
    property Position: Integer read GetPosition write SetPosition;
  end;

  { TGtk4TrackBar }

  TGtk4TrackBar = class(TGtk4Range)
  private
    FOrientation: TTrackBarOrientation;
    function GetReversed: Boolean;
    procedure SetReversed(AValue: Boolean);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure SetBounds(ALeft,ATop,AWidth,AHeight:integer);override;
    function GetTrackBarOrientation: TTrackBarOrientation;
    procedure SetScalePos(AValue: TTrackBarScalePos);
    procedure SetTickMarks(AValue: TTickMark; ATickStyle: TTickStyle);
    property Reversed: Boolean read GetReversed write SetReversed;
  end;

  { TGtk4ScrollBar }

  TGtk4ScrollBar = class(TGtk4Range)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure DetachEvents; override;
    procedure SetParams;
  end;

  { TGtk4ProgressBar }

  TGtk4ProgressBar = class(TGtk4Widget)
  private
    function GetOrientation: TProgressBarOrientation;
    function GetPosition: Integer; reintroduce;
    function GetShowText: Boolean;
    function GetStyle: TProgressBarStyle;
    procedure SetOrientation(AValue: TProgressBarOrientation);
    procedure SetPosition(AValue: Integer);
    procedure SetShowText(AValue: Boolean);
    procedure SetStyle(AValue: TProgressBarStyle);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
    property Orientation: TProgressBarOrientation read GetOrientation write SetOrientation;
    property Position: Integer read GetPosition write SetPosition;
    property ShowText: Boolean read GetShowText write SetShowText;
    property Style: TProgressBarStyle read GetStyle write SetStyle;
  end;

  { TGtk4Calendar }

  TGtk4Calendar = class(TGtk4Widget)
  private
    FMinDate: TDateTime;
    FMaxDate: TDateTime;
    FUpdatingDate: Boolean;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure GetDate(out AYear, AMonth, ADay: LongWord);
    procedure SetDate(const AYear, AMonth, ADay: LongWord);
    procedure SetDisplayOptions(const ADisplayOptions: TGtkCalendarDisplayOptions);
    procedure SetMinMaxDate(AMinDate, AMaxDate: TDateTime);
    procedure RemoveMinMaxDates;
    procedure ClampDate;
    property MinDate: TDateTime read FMinDate;
    property MaxDate: TDateTime read FMaxDate;
  end;

  { TGtk4StaticText }

  TGtk4StaticText = class(TGtk4Widget)
  private
    FBorderStyle: TStaticBorderStyle;
    function GetAlignment: TAlignment;
    function GetStaticBorderStyle: TStaticBorderStyle;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetStaticBorderStyle(AValue: TStaticBorderStyle);
  protected
    function getText: String; override;
    procedure setText(const AValue: String); override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property StaticBorderStyle: TStaticBorderStyle read GetStaticBorderStyle write SetStaticBorderStyle;
  end;

  { TGtk4Container }

  TGtk4Container = class(TGtk4Widget)
  public
    procedure AddChild(AWidget: PGtkWidget; const ALeft, ATop: Integer); virtual;
  end;

  { TGtk4Page }

  TGtk4Page = class(TGtk4Container)
  private
    FTabBox: PGtkBox;
    FTabImage: PGtkImage;
  protected
  public
    FPageLabel: PGtkLabel;
    procedure setText(const AValue: String); override;
    function CreateWidget(const Params: TCreateParams):PGtkWidget; override;
    procedure DestroyWidget; override;
  public
    procedure UpdateTabImage;
    function getClientRect: TRect; override;
  end;

  { TGtk4NoteBook }

  TGtk4NoteBook = class (TGtk4Container)
  private
    FDestroyingNotebook: Boolean;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    procedure DetachEvents; override;
    procedure DestroyWidget; override;
  public
    procedure InitializeWidget;override;
    function GetClientAreaOffset: TPoint; override;
    function getClientRect: TRect; override;
    function getPagesCount: integer;
    procedure InsertPage(ACustomPage: TCustomPage; AIndex: Integer);
    procedure MovePage(ACustomPage: TCustomPage; ANewIndex: Integer);
    procedure RemovePage(AIndex: Integer; AExpectedChild: PGtkWidget = nil);
    procedure SetPageIndex(AIndex: Integer);
    procedure SetShowTabs(const AShowTabs: Boolean);
    procedure SetTabPosition(const ATabPosition: TTabPosition);
    procedure SetTabLabelText(AChild: TCustomPage; const AText: String);
    function  GetTabLabelText(AChild: TCustomPage): String;
    property IsDestroyingNotebook: Boolean read FDestroyingNotebook;
  end;

  { TGtk4Bin }

  TGtk4Bin = class(TGtk4Container)

  end;


  { TGtk4Paned }

  TGtk4Paned = class(TGtk4Container)
  private
    FSyncIdleId: guint;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
    procedure DetachEvents; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
    procedure QueueSyncSides;
    procedure SyncSideSizes;
  end;

  { TGtk4SplitterSide }

  TGtk4SplitterSide = class(TGtk4Container)
  private
    FDetachedRef: Boolean; { we hold the widget's only ref after DetachFromPaned }
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure DetachFromPaned(APaned: PGtkPaned);
    procedure PanedAdopted;
    procedure DestroyWidget; override;
  end;


  { TGtk4MenuShell - GTK4: now wraps GMenu model + GtkPopoverMenuBar/GtkPopoverMenu }

  TGtk4MenuShell = class(TGtk4Container)
  public
    MenuObject: TMenu;
    FMenuModel: PGMenu;          { GMenu model for this menu }
    FActionGroup: PGSimpleActionGroup; { Action group for menu items }
    constructor Create(const AMenu: TMenu; AExistingWidget: PGtkWidget); virtual; overload;
    procedure InitializeWidget; override;
    destructor Destroy; override;
  end;

  { TGtk4MenuBar - GTK4: wraps GtkPopoverMenuBar }

  TGtk4MenuBar = class(TGtk4MenuShell)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk4Menu - GTK4: wraps GtkPopoverMenu for popup menus }

  TGtk4Menu = class(TGtk4MenuShell)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    PopupPoint: TPoint;
  end;

  { TGtk4MenuItem - GTK4: wraps a GMenuItem + GSimpleAction pair }

  TGtk4MenuItem = class(TGtk4Bin)
  private
    function GetCaption: string;
    procedure SetCaption(const AValue: string);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    Lock: integer;
    MenuItem: TMenuItem;
    FActionName: string;         { Action name like "item-N" }
    FAction: PGSimpleAction;     { GSimpleAction for this item }
    FGMenuItem: PGMenuItem;      { GMenuItem in the model }
    FSubMenu: PGMenu;            { Submenu model if this item has children }
    constructor Create(const AMenuItem: TMenuItem); virtual; overload;
    destructor Destroy; override;
    procedure InitializeWidget; override;
    procedure SetCheck(ACheck:boolean);
    procedure SyncGroupToLCL;
    procedure SetEnabled(AEnabled: boolean);
    property Caption: string read GetCaption write SetCaption;
    property ActionName: string read FActionName;
    property Action: PGSimpleAction read FAction;
    property SubMenu: PGMenu read FSubMenu;
  end;

  { TGtk4ScrollableWin }

  TGtk4ScrollableWin = class(TGtk4Container)
  private
    FBorderStyle: TBorderStyle;
    FScrollX: Integer;
    FScrollY: Integer;
    function GetHScrollBarPolicy: TGtkPolicyType;
    function GetVScrollBarPolicy: TGtkPolicyType;
    procedure SetBorderStyle(AValue: TBorderStyle);
    procedure SetHScrollBarPolicy(AValue: TGtkPolicyType); virtual;
    procedure SetVScrollBarPolicy(AValue: TGtkPolicyType); virtual;
  public
    procedure DetachEvents; override;
    procedure SetScrollBarsSignalHandlers;
    function getClientBounds: TRect; override;
    function getHorizontalScrollbar: PGtkScrollbar; virtual; abstract;
    function getVerticalScrollbar: PGtkScrollbar; virtual; abstract;
    function getScrolledWindow: PGtkScrolledWindow; virtual; abstract;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle;
    property HScrollBarPolicy: TGtkPolicyType read GetHScrollBarPolicy write SetHScrollBarPolicy;
    property VScrollBarPolicy: TGtkPolicyType read GetVScrollBarPolicy write SetVScrollBarPolicy;
    property ScrollX: Integer read FScrollX write FScrollX;
    property ScrollY: Integer read FScrollY write FScrollY;
  end;

  { TGtk4ToolBar }

  TGtk4ToolBar = class(TGtk4Container)
  private
    fBmpList:TList;
    procedure ButtonClicked(data: gPointer); cdecl;
    procedure ClearGlyphs;
  public
    destructor Destroy;override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk4Memo }

  TGtk4Memo = class(TGtk4ScrollableWin)
  private
    FWantReturns: Boolean;
    FKeyPending: Boolean;             { an unmodified key press is in flight on
                                        the GtkTextView — gates OnKeyPress }
    FPendingKeyText: String;          { unicode text of the pending key }
    FPreeditText: String;             { observed IM preedit on the text view }
    FDeferredText: String;            { raw key text deferred until the pending
                                        IM commit lands (fcitx5-gtk4 ordering) }
    FFlushingDeferred: Boolean;       { re-entrancy: flushing FDeferredText }
    FSuppressInsertFeedback: Boolean; { guards programmatic + re-entrant inserts }
    FBubbleReplacePending: Boolean;   { an OnKeyPress handler replaced the char
                                        in the bubble path — apply at insert }
    FBubbleReplaceFrom: String;       { the text the view is about to insert }
    FBubbleReplaceTo: String;         { the replacement the handler produced }
    function GetAlignment: TAlignment;
    function GetReadOnly: Boolean;
    function GetWantTabs: Boolean;
    function GetWordWrap: Boolean;
    procedure SetAlignment(AValue: TAlignment);
    procedure SetReadOnly(AValue: Boolean);
    procedure SetWantTabs(AValue: Boolean);
    procedure SetWordWrap(AValue: Boolean);
  protected
    function getText: String; override;
    procedure setText(const AValue: String); override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
  public
    procedure DetachEvents; override;
    procedure InitializeWidget; override;
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
  public
    property Alignment: TAlignment read GetAlignment write SetAlignment;
    property ReadOnly: Boolean read GetReadOnly write SetReadOnly;
    property WantReturns: Boolean read FWantReturns write FWantReturns;
    property WantTabs: Boolean read GetWantTabs write SetWantTabs;
    property WordWrap: Boolean read GetWordWrap write SetWordWrap;
  end;

  { TGtk4ListBox }

  TGtk4ListBox = class(TGtk4ScrollableWin)
  private
    FListBoxStyle: TListBoxStyle;
    FIsListView: Boolean;         { True when using GtkListView (modern path) }
    FIsGridView: Boolean;         { True when Columns>0 uses GtkGridView (multi-column) }
    FGridColumns: Integer;        { column count applied to the GtkGridView }
    FSelectionModel: Pointer;     { PGtkSingleSelection or PGtkMultiSelection }
    FListModel: Pointer;          { PGtkStringList }
    function GetItemIndex: Integer;
    function GetMultiSelect: Boolean;
    procedure SetItemIndex(AValue: Integer);
    procedure SetListBoxStyle(AValue: TListBoxStyle);
    procedure SetMultiSelect(AValue: Boolean);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
  public
    procedure DetachEvents; override;
    procedure InitializeWidget; override;
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
  public
    function GetSelCount: Integer;
    function GetSelection: PGtkTreeSelection;
    function GetItemSelected(const AIndex: Integer): Boolean;
    procedure SelectItem(const AIndex: Integer; ASelected: Boolean);
    procedure SetTopIndex(const AIndex: Integer);
    property IsListView: Boolean read FIsListView;
    property IsGridView: Boolean read FIsGridView;
    property GridColumns: Integer read FGridColumns;
    property SelectionModel: Pointer read FSelectionModel;
    property ListModel: Pointer read FListModel;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect;
    property ListBoxStyle: TListBoxStyle read FListBoxStyle write SetListBoxStyle;
  end;

  { TGtk4CheckListBox }

  TGtk4CheckListBox = class(TGtk4ListBox)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams): PGtkWidget; override;
  end;

  { TGtk4ListView }

  TGtk4ListView = class(TGtk4ScrollableWin)
  private
    FPreselectedIndices: TFPList;
    FImages: TFPList;
    FStateImages: TFPList;      { TBitmap list from StateImages (lvilState) }
    FIsTreeView: Boolean;
    FIsColumnView: Boolean;     { True when using GtkColumnView (vsReport/vsList) }
    FIsGridView: Boolean;       { True when using GtkGridView (vsIcon/vsSmallIcon) }
    FCheckboxes: Boolean;       { GtkColumnView: checkboxes enabled }
    FHideSelection: Boolean;
    FSelectionModel: Pointer;   { PGtkSingleSelection or PGtkMultiSelection }
    FListModel: Pointer;        { PGtkStringList — row count management }
    FColumnFactories: TFPList;  { PGtkSignalListItemFactory per column }
    FColumnObjects: TFPList;    { PGtkColumnViewColumn per column }
    FColumnSorters: TFPList;    { PGtkSorter (GtkCustomSorter) per column }
    FRowsDirty: Boolean;        { ColumnView/GridView: rows need a factory rebind
                                  once the current BeginUpdate/EndUpdate batch ends }
    FWasCleared: Boolean;       { ColumnView/GridView: model was emptied during the
                                  batch — reset scroll to top on EndUpdate (qt5 parity) }
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
  public
    procedure preferredSize(var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;
    procedure EndUpdate; override;
    procedure DetachEvents; override;
    destructor Destroy; override;
    {interface implementation}
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
    procedure ClearImages;
    procedure ClearStateImages;
    procedure ColumnDelete(AIndex: Integer);
    function ColumnGetWidth(AIndex: Integer): Integer;
    procedure ColumnInsert(AIndex: Integer; AColumn: TListColumn);
    procedure SetAlignment(AIndex: Integer; {%H-}AColumn: TListColumn; AAlignment: TAlignment);
    procedure SetColumnAutoSize(AIndex: Integer; {%H-}AColumn: TListColumn; AAutoSize: Boolean);
    procedure SetColumnCaption(AIndex: Integer; {%H-}AColumn: TListColumn; const ACaption: String);
    procedure SetColumnMaxWidth(AIndex: Integer; {%H-}AColumn: TListColumn; AMaxWidth: Integer);
    procedure SetColumnMinWidth(AIndex: Integer; {%H-}AColumn: TListColumn; AMinWidth: Integer);
    procedure SetColumnWidth(AIndex: Integer; {%H-}AColumn: TListColumn; AWidth: Integer);
    procedure SetColumnVisible(AIndex: Integer; {%H-}AColumn: TListColumn; AVisible: Boolean);
    procedure ColumnSetImage(AIndex: Integer; AImageIndex: Integer);
    procedure ColumnSetSortIndicator(const AIndex: Integer; const {%H-}AColumn: TListColumn; const ASortIndicator: TSortIndicator);

    procedure UpdateItem(AIndex:integer;AItem: TListItem);
    procedure ItemDelete(AIndex: Integer);
    procedure ItemInsert(AIndex: Integer; AItem: TListItem);
    procedure ItemSetText(AIndex, ASubIndex: Integer; AItem: TListItem; const AText: String);
    procedure ItemSetImage(AIndex, ASubIndex: Integer; AItem: TListItem);
    procedure ItemSetState(const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState;
      const AIsSet: Boolean);
    function ItemGetState(const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState;
      out AIsSet: Boolean): Boolean;

    procedure UpdateImageCellsSize;
    procedure ItemRebindRow(AIndex: Integer);
    procedure RebindAllRows;
    procedure AddRemoveCheckboxRenderer(const Add: Boolean);
    procedure SetHideSelection(AValue: Boolean);
    procedure ModelNotifyItemsChanged;

    property Images: TFPList read FImages write FImages;
    property StateImages: TFPList read FStateImages write FStateImages;
    property IsTreeView: Boolean read FIsTreeView;
    property IsColumnView: Boolean read FIsColumnView;
    property IsGridView: Boolean read FIsGridView;
    property SelectionModel: Pointer read FSelectionModel;
    property ListModel: Pointer read FListModel;
    property HideSelection: Boolean read FHideSelection write SetHideSelection;
  end;

  { TGtk4Box }

  TGtk4Box = class(TGtk4Container)

  end;

  { TGtk4StatusBar }

  TGtk4StatusBar = class(TGtk4Box)
  private
    FPanels: array of PGtkLabel;
    procedure ClearPanels;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure RecreatePanels;
    procedure UpdatePanel(AIndex: Integer);
  end;

  { TGtk4Panel }

  TGtk4Panel = class(TGtk4Bin)
  private
    FBorderStyle: TBorderStyle;
  protected
    procedure SetColor(AValue: TColor); override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    procedure DoBeforeLCLPaint; override;
    procedure setText(const AValue: String); override;
  public
    procedure UpdateWidgetConstraints;override;
    property BorderStyle: TBorderStyle read FBorderStyle write FBorderStyle;
  end;

  { TGtk4GroupBox }

  TGtk4GroupBox = class(TGtk4Bin)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function getText: String; override;
    procedure setText(const AValue: String); override;
  public
  end;

  { TGtk4ComboBox }

  TGtk4ComboBox = class(TGtk4Bin)
  private
    FEntry: PGtkWidget;            { PGtkEntry — text input }
    FButton: PGtkWidget;           { PGtkButton — dropdown arrow }
    FPopover: PGtkWidget;          { PGtkPopover — popup }
    FListView: PGtkWidget;         { PGtkListView — item list }
    FScrollWin: PGtkWidget;        { PGtkScrolledWindow — dropdown scroll area }
    FSelectionModel: Pointer;      { PGtkSingleSelection }
    FListModel: Pointer;           { PGtkStringList }
    FOwnerDrawn: Boolean;
    FDropDownCount: Integer;       { max visible items in dropdown }
    FSelStartPending: Boolean;     { entry SelStart is deferred, see ApplyPendingSelStart }
    FPendingSelStart: Integer;     { valid only while FSelStartPending }
    FPendingSelStartIdle: guint;   { g_idle_add_full id of the deferred apply, 0 = none }
    { Mirror of the TGtk4Entry IM commit-order deferral (see Gtk4EntryFlushDeferred);
      intentionally no LCL key delivery or filtering here. }
    FImKeyPending: Boolean;        { an unmodified key press is in flight on the delegate }
    FImPendingKeyText: string;     { that key's own character }
    FImPreeditText: string;        { observed IM preedit on the delegate }
    FImDeferredText: string;       { raw key text held until the pending commit lands }
    FImFlushing: Boolean;          { re-entrancy: flushing FImDeferredText / programmatic write }
    { Dropdown transaction: while the popover is visible the selection model is
      only a preview (hover / arrow keys highlight); FCommittedIndex is the LCL
      ItemIndex, captured when the popover opens, replaced by an activate
      (click / Return) and restored on cancel (Escape / outside click). }
    FCommittedIndex: Integer;
    FActivated: Boolean;           { the popover is closing because of an activate }
    function PopoverVisible: Boolean;
    function GetItemIndex: Integer;
    procedure SetDroppedDown(AValue: boolean);
    procedure SetItemIndex(AValue: Integer);
    function GetDroppedDown: boolean;
    function EntryOk: Boolean;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(const AValue: String); override;
    procedure DestroyWidget; override;
  public
    procedure DetachEvents; override;
    function DeliverMessage(var Msg; const AIsInputEvent: Boolean = False): LRESULT; override;
  public
    function CanFocus: Boolean; override;
    procedure SetFocus; override;
    procedure InitializeWidget; override;
    procedure SetDropDownCount(AValue: Integer);
    { entry selection with the deferred SelStart transaction (same mechanism as
      TGtk4Editable, see "Deferred SelStart" there) }
    procedure ApplyPendingSelStart;
    procedure CancelPendingSelStart;
    function GetEntrySelStart: Integer;
    function GetEntrySelLength: Integer;
    procedure SetEntrySelStart(AValue: Integer);
    procedure SetEntrySelLength(AValue: Integer);
    { bracket every programmatic replacement/truncation of the entry text:
      drops held IM text and keeps the delegate insert-text hooks out }
    procedure BeginEntryWrite;
    procedure EndEntryWrite;
    procedure CommitSelection(APosition: Integer);
    property DroppedDown: boolean read GetDroppedDown write SetDroppedDown;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property Entry: PGtkWidget read FEntry;
    property SelectionModel: Pointer read FSelectionModel;
    property ListModel: Pointer read FListModel;
    property OwnerDrawn: Boolean read FOwnerDrawn;
  end;

  { TGtk4DropDown — GtkDropDown wrapper for non-editable ComboBox styles.
    Handles csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable.
    Uses GtkStringList model (not GtkListStore/TreeModel).
    OwnerDraw styles use GtkSignalListItemFactory for custom rendering. }

  TGtk4DropDown = class(TGtk4Widget)
  private
    FFactory: PGtkSignalListItemFactory;
    function GetItemIndex: Integer;
    procedure SetItemIndex(AValue: Integer);
    function GetInternalToggleButton: PGtkWidget;
  protected
    function CreateWidget(const {%H-}Params: TCreateParams): PGtkWidget; override;
    function EatArrowKeys(const AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(const AValue: String); override;
  public
    procedure DetachEvents; override;
    function CanFocus: Boolean; override;
    procedure SetFocus; override;
    procedure InitializeWidget; override;
    procedure SetDroppedDown(AValue: boolean);
    function GetDroppedDown: boolean;
    property ItemIndex: Integer read GetItemIndex write SetItemIndex;
    property DroppedDown: boolean read GetDroppedDown write SetDroppedDown;
  end;

  { TGtk4Button }

  TGtk4Button = class(TGtk4Bin)
  private
    FMargin: Integer;
    FLayout: Integer;
    FSpacing: Integer;
    FImage: TBitmap;
    function getLayout: Integer;
    function getMargin: Integer;
    procedure SetLayout(AValue: Integer);
    procedure SetMargin(AValue: Integer);
    procedure SetSpacing(AValue: Integer);
  protected
    procedure ButtonClicked(pData:pointer);cdecl;
    procedure SetImage(AImage:TBitmap);
    function getText: String; override;
    procedure setText(const AValue: String); override;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    destructor Destroy;override;
    function IsWidgetOk: Boolean; override;
    procedure SetDefault(const ADefault: Boolean);
    property Layout: Integer read getLayout write SetLayout;
    property Margin: Integer read getMargin write SetMargin;
    property Spacing: Integer read FSpacing write SetSpacing;
    property Image:TBitmap read fImage write SetImage;
  end;

  { TGtk4ToggleButton }

  TGtk4ToggleButton = class(TGtk4Button)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
  end;

  { TGtk4CheckBox }

  TGtk4CheckBox = class(TGtk4ToggleButton)
  private
    function GetState: TCheckBoxState;
    procedure SetState(AValue: TCheckBoxState);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    { GTK4: GtkCheckButton is no longer a GtkButton. Override text methods. }
    function getText: String; override;
    procedure setText(const AValue: String); override;
    function IsWidgetOk: Boolean; override;
    property State: TCheckBoxState read GetState write SetState;
  end;

  { TGtk4RadioButton }

  TGtk4RadioButton = class(TGtk4CheckBox)
  private
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk4CustomControl }

  TGtk4CustomControl = class(TGtk4ScrollableWin)
    private
    protected
      function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
      function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
    public
      procedure InitializeWidget; override;
      procedure UpdateWidgetConstraints; override;
      function getClientRect: TRect; override;
      function getClientBounds: TRect; override;
      function getHorizontalScrollbar: PGtkScrollbar; override;
      function getVerticalScrollbar: PGtkScrollbar; override;
      function GetScrolledWindow: PGtkScrolledWindow; override;
      procedure SetFocus; override;
  end;

  { TGtk4ScrollingWinControl }

  TGtk4ScrollingWinControl = class(TGtk4CustomControl)
    protected
      function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  end;

  { TGtk4Splitter }

  TGtk4Splitter = class(TGtk4Panel)
  public
  end;


  { TGtk4Window }

  TGtk4Window = class(TGtk4ScrollableWin) {we are TGtk4Bin actually, but it won't hurt since we need scroll}
  private
    FIcon: PGdkPixBuf;
    FScrollWin: PGtkScrolledWindow;
    FMenuBar: PGtkWidget;  { GTK4: GtkPopoverMenuBar (not GtkMenuBar) }
    FMenuModel: PGMenu;   { GTK4: GMenu model for the menu bar }
    FMenuActionGroup: PGSimpleActionGroup; { GTK4: action group for menu items }
    FBox: PGtkBox;
    FOverlay: PGtkWidget;        { GTK4: GtkOverlay wrapping ScrolledWindow + DrawingArea }
    FMaxWidth: Integer;          { GTK4: max width constraint (<=0 = none) }
    FMaxHeight: Integer;         { GTK4: max height constraint (<=0 = none) }
    FComputeSizeId: gulong;      { Signal handler ID for notify::default-height }
    FEnforcingMax: Boolean;      { Guard against recursive notify during sync snap-back }
    FAfterPaintId: gulong;           { Signal handler ID for frame clock after-paint }
    FLastMoveX: SmallInt;            { Last reported window X position (for LM_MOVE) }
    FLastMoveY: SmallInt;            { Last reported window Y position (for LM_MOVE) }
    FMoveTracked: Boolean;           { True after first position is captured }
    function GetSkipTaskBarHint: Boolean;
    function GetTitle: String;
    procedure SetIcon(AValue: PGdkPixBuf);
    procedure SetSkipTaskBarHint(AValue: Boolean);
    procedure SetTitle(const AValue: String);
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
    function EatArrowKeys(const {%H-}AKey: Word): Boolean; override;
    function getText: String; override;
    procedure setText(const AValue: String); override;
    procedure DoBeforeLCLPaint; override;
  public
    function GetMenuBarHeight: Integer;
    function GetNonClientOverhead: Integer;
    function GetClientAreaOffset: TPoint; override;
    function getClientBounds: TRect; override;
    function getClientRect: TRect; override;
    function getHorizontalScrollbar: PGtkScrollbar; override;
    function getVerticalScrollbar: PGtkScrollbar; override;
    function GetScrolledWindow: PGtkScrolledWindow; override;
    function ShowState(nstate:integer):boolean; // winapi ShowWindow
    procedure UpdateWindowState; // LCL WindowState
    class function decoration_flags(Aform: TCustomForm): TGdkWMDecoration;
  public
    procedure DetachEvents; override;
    procedure SetBounds(ALeft,ATop,AWidth,AHeight:integer);override;
    destructor Destroy; override;
    procedure Activate; override;
    function Gtk4CloseQuery: Boolean;
    function GetWindow: PGdkWindow; override;
    procedure EnsureMenuBar;
    function GetMenuBar: PGtkWidget;
    function GetMenuModel: PGMenu;
    function GetMenuActionGroup: PGSimpleActionGroup;
    function GetBox: PGtkBox;
    function GetWindowState: TGdkWindowState;
    procedure SetMaxSize(AMaxWidth, AMaxHeight: Integer);
    procedure ConnectComputeSize;
    procedure ConnectAfterPaint;
    procedure ApplyX11SizeHints;
    procedure PreparePopupShow;
    procedure PrepareTooltipShow;
    procedure RaiseX11Popup;
    procedure CheckSendLMMove;
    property Icon: PGdkPixBuf read FIcon write SetIcon;
    property SkipTaskBarHint: Boolean read GetSkipTaskBarHint write SetSkipTaskBarHint;
    property Title: String read GetTitle write SetTitle;
  end;

  { TGtk4HintWindow }

  TGtk4HintWindow = class(TGtk4Window)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    procedure InitializeWidget; override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: integer); override;
  end;

  { TGtk4Dialog }

  TGtk4Dialog = class(TGtk4Widget)
  private
    { NOTE: These are class functions with cdecl. In FPC, class methods have
      a hidden class reference as the first parameter, which occupies the
      GTK widget/instance slot. Do NOT add an explicit widget parameter. }
    class function CloseCB(dlg:TGtk4Dialog): GBoolean; cdecl;
    class function CloseQueryCB(dlg:TGtk4Dialog): GBoolean; cdecl;
    class function DestroyCB(dlg:TGtk4Dialog): GBoolean; cdecl;
    class function ResponseCB(response_id:gint; dlg: TGtk4Dialog): GBoolean; cdecl;
    class function RealizeCB(dlg:TGtk4Dialog): GBoolean; cdecl;
  protected
    function response_handler(response_id:TGtkResponseType):boolean;virtual;
    function close_handler():boolean;virtual;
    procedure SetCallbacks;virtual;
    function CreateWidget(const {%H-}Params: TCreateParams):PGtkWidget; override;
  public
    CommonDialog: TCommonDialog;
    FModalLoop: PGMainLoop;
    procedure InitializeWidget; override;
    procedure CloseDialog;virtual;
    procedure QuitModalLoop;
  end;

  { TGtk4FileDialog }

  TGtk4FileDialog = class(TGtk4Dialog)
  private
  protected
    function CreateWidget(const {%H-}Params: TCreateParams): PGtkWidget; override;
    { GtkFileChooserNative-based: FWidget holds a PGtkFileChooserNative (a
      GObject, NOT a GtkWidget). SetCallbacks connects only 'response'; there is
      no realize/destroy/close-request on a native dialog. DestroyWidget tears
      down the native dialog and clears FWidget so the base gtk_window_destroy
      is skipped. Showing/modality/transient go through gtk_native_dialog_* in
      TGtk4WSCommonDialog.ShowModal (which branches on TGtk4FileDialog). }
    procedure SetCallbacks; override;
    procedure DestroyWidget; override;
  public
    constructor Create(const ACommonDialog: TCommonDialog); virtual; overload;
  end;

  { TGtk4FontSelectionDialog }

  TGtk4FontSelectionDialog = class(TGtk4Dialog)
  protected
    function response_handler(resp_id:TGtkResponseType):boolean; override;
  public
    procedure InitializeWidget; override;
    constructor Create(const ACommonDialog: TCommonDialog); virtual; overload;
  end;

  { TGtk4newColorSelectionDialog }

  TGtk4newColorSelectionDialog = class(TGtk4Dialog)
  protected
    function response_handler(resp_id:TGtkResponseType):boolean;override;
  public
    constructor Create(const ACommonDialog: TCommonDialog); virtual; overload;
    procedure InitializeWidget;override;
    class procedure color_to_rgba(clr:TColor;out rgba:TgdkRGBA);
    class function rgba_to_color(const rgba:TgdkRGBA):TColor;
  end;

  { TGtk4GLArea }
  TGtk4GLArea = class(TGtk4Widget)
  protected
    function CreateWidget(const {%H-}Params: TCreateParams): PGtkWidget; override;
  public
    procedure Update({%H-}ARect: PRect); override;
  end;

function Gtk4BitmapToPixbuf(const ABmp: TBitmap): PGdkPixbuf;

{ GTK4: Process deferred mouse events queued by event controller callbacks.
  Called from AppProcessMessages AFTER g_main_context_iteration returns,
  so we are completely outside GLib dispatch — no re-entrancy issues. }
procedure ProcessGtk4DeferredMouseEvents;
{ Menu-dismissal focus restore — see TGtk4WSPopupMenu.Popup. }
function Gtk4SaveFocusOwner: TObject;
procedure Gtk4RestoreFocusOwner(AOwner: TObject);

var
  { GTK4: gtk_grab_add/remove/get_current were removed. We track mouse capture
    at the Pascal level using a simple global variable. When gdk_seat_grab is
    available, native pointer grab is also engaged for robust capture. }
  Gtk4CapturedWidget: PGtkWidget;
  { gdk_seat_grab/ungrab — dynamically loaded for native pointer capture.
    Declared here so gtk4winapi.inc (ReleaseCapture) can access them. }
  GdkGrabInit: Boolean;
  GdkpSeatUngrab: Pointer;
  { GTK4: Deferred mouse event queue. Button press/release events from event
    controllers are queued here and processed outside g_main_context_iteration
    to avoid re-entrant dispatch that causes modal dialog hangs. }
  Gtk4DeferredMouseEvents: TFPList;
  { GTK4: Double-click detection state. GTK4 removed GDK_2BUTTON_PRESS at the
    raw event level — double-clicks are only available via GtkGestureClick's
    n_press parameter. Since we use a legacy event controller (not
    GtkGestureClick) for reliable CAPTURE-phase event handling, we must detect
    double/triple clicks manually by tracking time/position/button. }
  Gtk4LastClickTime: guint32 = 0;
  Gtk4LastClickX: double = 0;
  Gtk4LastClickY: double = 0;
  Gtk4LastClickButton: guint = 0;
  Gtk4ClickCount: Integer = 0;

{ Patch GtkFixedLayout's class vtable so children are allocated at their
  set_size_request values instead of intrinsic minimums. Must be called
  once after gtk4_init, before any GtkFixed widgets are created. }
procedure PatchGtkFixedLayoutClass;

{ Patch GtkFixed's snapshot vfunc so LCL custom painting renders BEFORE child
  widgets, matching GTK2/Qt5 z-order. Must be called once after gtk4_init. }
procedure PatchGtkFixedSnapshotClass;

{ Check if AData points to a still-live TGtk4Widget instance (registered in
  the global live widget list). Used by callbacks and caret timer to avoid
  accessing freed Pascal objects during shutdown. }
function Gtk4IsLiveWidgetPointer(AData: gpointer): Boolean;

{ GTK4/X11: Get the absolute screen origin of a GtkWidget's toplevel window.
  Returns True on success (X11 backend), False on Wayland or if not available. }
function Gtk4X11GetWindowOrigin(AWidget: PGtkWidget; out X, Y: LongInt): Boolean;
function Gtk4WindowCanPresent(AWidget: TGtk4Widget): Boolean;

implementation

uses gtk4int, imglist;

type
  { Cracker class to access protected members of TCustomComboBox }
  TCustomComboBoxAccess = class(TCustomComboBox);
  { Cracker class to access protected members of TCustomListView }
  TCustomListViewAccess = class(TCustomListView);

  { Factory callback data for GtkColumnView columns }
  PColumnFactoryData = ^TColumnFactoryData;
  TColumnFactoryData = record
    ListView: TGtk4ListView;
    ColumnIndex: Integer;
  end;

function Gtk4WindowCanPresent(AWidget: TGtk4Widget): Boolean;
begin
  Result := AWidget <> nil;
  if Result and (AWidget.LCLObject is TCustomForm) then
    Result := TCustomForm(AWidget.LCLObject).HandleObjectShouldBeVisible;
end;

{ --- gdk_seat_grab/ungrab dynamic loading ---
  GDK4 bindings declare TGdkSeat.grab/ungrab as stubs. We dynamically load the
  real functions from libgtk-4.so.1 for native pointer capture (SetCapture).
  Works on both X11 and Wayland. }
type
  TGdkSeatGrabFunc = function(seat: Pointer; surface: Pointer;
    capabilities: guint; owner_events: gboolean;
    cursor: Pointer; event: Pointer;
    prepare_func: Pointer; prepare_func_data: Pointer): guint; cdecl;

var
  GdkpSeatGrab: TGdkSeatGrabFunc = nil;

procedure InitGdkSeatGrab;
var
  hGdk: TLibHandle;
begin
  GdkGrabInit := True;
  hGdk := LoadLibrary('libgtk-4.so.1');
  if hGdk = NilHandle then
    Exit;
  GdkpSeatGrab := TGdkSeatGrabFunc(GetProcAddress(hGdk, 'gdk_seat_grab'));
  GdkpSeatUngrab := GetProcAddress(hGdk, 'gdk_seat_ungrab');
end;

const
  { GDK_SEAT_CAPABILITY_POINTER = 1 shl 0 }
  GDK_SEAT_CAP_POINTER: guint = 1;

function Gtk4BitmapToPixbuf(const ABmp: TBitmap): PGdkPixbuf;
var
  AHandleObj: TObject;
  ALoader: PGdkPixbufLoader;
  AErr: PGError;
  APng: TPortableNetworkGraphic;
  AStream: TMemoryStream;
begin
  Result := nil;
  if (ABmp = nil) or ABmp.Empty then
    Exit;

  { TBitmap.Handle is lazily created; touching it here guarantees a consistent
    conversion path like Qt5/GTK2-based code paths. }
  AHandleObj := TObject(ABmp.Handle);
  if AHandleObj is TGtk4Image then
  begin
    Result := TGtk4Image(AHandleObj).Handle;
    if Result <> nil then
      g_object_ref(Result);
    Exit;
  end;

  { Fallback path: image-list extracted bitmaps can arrive without a TGtk4Image
    handle. Encode to PNG in-memory and let gdk-pixbuf decode it. }
  APng := TPortableNetworkGraphic.Create;
  AStream := TMemoryStream.Create;
  try
    APng.Assign(ABmp);
    APng.SaveToStream(AStream);
    if AStream.Size <= 0 then
      Exit;

    ALoader := gdk_pixbuf_loader_new;
    if ALoader = nil then
      Exit;
    try
      AErr := nil;
      if not gdk_pixbuf_loader_write(ALoader, Pguint8(AStream.Memory), AStream.Size, @AErr) then
      begin
        if AErr <> nil then
          g_error_free(AErr);
        Exit;
      end;

      AErr := nil;
      if not gdk_pixbuf_loader_close(ALoader, @AErr) then
      begin
        if AErr <> nil then
          g_error_free(AErr);
        Exit;
      end;

      Result := gdk_pixbuf_loader_get_pixbuf(ALoader);
      if Result <> nil then
        g_object_ref(Result);
    finally
      g_object_unref(ALoader);
    end;
  finally
    AStream.Free;
    APng.Free;
  end;
end;

{ ====================================================================
  GTK4 Event Controller Callbacks
  These build synthetic TGdkEvent records and delegate to the existing
  GtkEvent* methods which contain all LCL message delivery logic.
  The synthetic events are Pascal records, never passed to GTK4 API.
  ==================================================================== }

{ GTK4: Deferred mouse event dispatch.
  Button press/release events are dispatched via g_idle_add to avoid
  nested event processing inside GTK4 event controller callbacks.
  GTK4 blocks re-entrant event dispatch, which causes hangs when
  a button click triggers a modal dialog (e.g. File Open). }
type
  PDeferredMouseEvent = ^TDeferredMouseEvent;
  TDeferredMouseEvent = record
    Ctl: TGtk4Widget;
    Widget: PGtkWidget;
    Event: TGdkEvent;
    DoFocus: Boolean;
    IsWindow: Boolean;
  end;

var
  Gtk4ProcessingDeferredEvents: Boolean = False;

{ True when a LATER queue entry describes the same physical button event
  as AInfo (same timestamp, button, event type and root position).
  CAPTURE-phase controllers append one entry per ancestor widget for a
  single click; the last entry is the deepest widget — the win32-style
  message target. }
{ True when the GTK focus widget of ACtl's toplevel lies inside ACtl's own
  widget subtree.  Used by the deferred click focus pass: LCL's Focused
  bookkeeping alone cannot detect GTK focus drifting to a sibling widget
  (e.g. the notebook tab) while LCL still believes the control is focused. }
function Gtk4WidgetSubtreeHasGtkFocus(ACtl: TGtk4Widget): Boolean;
var
  TL, F: PGtkWidget;
begin
  Result := False;
  if (ACtl = nil) or (ACtl.Widget = nil) then exit;
  if not Gtk4IsWidget(PGObject(ACtl.Widget)) then exit;
  TL := ACtl.Widget^.get_ancestor(gtk_window_get_type);
  if TL = nil then exit;
  F := gtk_window_get_focus(PGtkWindow(TL));
  if F = nil then exit;
  Result := (F = ACtl.Widget) or F^.is_ancestor(ACtl.Widget);
end;

function Gtk4DeferredQueueHasSameButtonEvent(AInfo: PDeferredMouseEvent): Boolean;
var
  j: Integer;
  Other: PDeferredMouseEvent;
begin
  Result := False;
  for j := 0 to Gtk4DeferredMouseEvents.Count - 1 do
  begin
    Other := PDeferredMouseEvent(Gtk4DeferredMouseEvents[j]);
    if (Other^.Event.type_ = AInfo^.Event.type_) and
       (Other^.Event.button.time = AInfo^.Event.button.time) and
       (Other^.Event.button.button = AInfo^.Event.button.button) and
       (Other^.Event.button.x_root = AInfo^.Event.button.x_root) and
       (Other^.Event.button.y_root = AInfo^.Event.button.y_root) then
      Exit(True);
  end;
end;

procedure ProcessGtk4DeferredMouseEvents;
var
  Info: PDeferredMouseEvent;
  i: Integer;
  FocusTarget: TGtk4Widget;
  FocusIsWindow: Boolean;
begin
  if Gtk4ProcessingDeferredEvents then
    exit;
  if Gtk4DeferredMouseEvents = nil then exit;
  if Gtk4DeferredMouseEvents.Count = 0 then exit;

  Gtk4ProcessingDeferredEvents := True;
  try
    { GTK4: Find the deepest (last) focusable widget in the queue.
      CAPTURE phase fires parent→child, so the last DoFocus entry is the
      most specific (deepest) widget that should receive focus. Focusing
      only this widget avoids parent→child focus bouncing. }
    FocusTarget := nil;
    FocusIsWindow := False;
    for i := 0 to Gtk4DeferredMouseEvents.Count - 1 do
    begin
      Info := PDeferredMouseEvent(Gtk4DeferredMouseEvents[i]);
      if Info^.DoFocus and Gtk4IsLiveWidgetPointer(Info^.Ctl) and
         Info^.Ctl.CanSendLCLMessage then
      begin
        FocusTarget := Info^.Ctl;
        FocusIsWindow := Info^.IsWindow;
      end;
    end;
    { Apply focus once to the deepest widget }
    if FocusTarget <> nil then
    begin
      if FocusIsWindow then
        FocusTarget.Activate
      else
        LCLIntf.SetFocus(HWND(FocusTarget));
    end;

    while Gtk4DeferredMouseEvents.Count > 0 do
    begin
      Info := PDeferredMouseEvent(Gtk4DeferredMouseEvents[0]);
      Gtk4DeferredMouseEvents.Delete(0);
      try
        { Deliver each PHYSICAL button event only once, to the deepest
          widget (win32 semantics: only the target control receives the
          message).  CAPTURE-phase controllers fire parent->child and each
          appends its own entry for the same click, so if a later entry
          matches this one's identity key, skip this shallower entry.
          Key: (time, button, type) + root position as a time=0 safety
          net; applies to button press/release entries only. }
        if (Info^.Event.type_ in [GDK_BUTTON_PRESS, GDK_2BUTTON_PRESS,
             GDK_3BUTTON_PRESS, GDK_BUTTON_RELEASE]) and
           Gtk4DeferredQueueHasSameButtonEvent(Info) then
          Continue;
        if Gtk4IsLiveWidgetPointer(Info^.Ctl) and
           Info^.Ctl.CanSendLCLMessage then
        begin
          Info^.Ctl.GtkEventMouse(Info^.Widget, @Info^.Event);
        end;
      finally
        Dispose(Info);
      end;
    end;
  finally
    Gtk4ProcessingDeferredEvents := False;
  end;
end;

function Gtk4HasDeferredMouseEvents: Boolean;
begin
  Result := (Gtk4DeferredMouseEvents <> nil) and
            (Gtk4DeferredMouseEvents.Count > 0);
end;

function Gtk4IsUndoRedoShortcut(keyval: guint; state: TGdkModifierType): Boolean;
begin
  Result := (GDK_CONTROL_MASK in state) and
            not (GDK_MOD1_MASK in state) and
            ((keyval = GDK_KEY_z_) or (keyval = GDK_KEY_Z) or
             (keyval = GDK_KEY_y_) or (keyval = GDK_KEY_Y));
end;

procedure Gtk4FlushDesignInputBeforeCommandKey(keyval: guint; state: TGdkModifierType);
begin
  if not Gtk4IsUndoRedoShortcut(keyval, state) then exit;

  if not Gtk4ProcessingDeferredEvents and Gtk4HasDeferredMouseEvents then
    ProcessGtk4DeferredMouseEvents;

  { IDE command enabled state is updated from Application.Idle.  Run it only
    just before designer undo/redo shortcuts are dispatched.  The deferred
    mouse queue may already be empty by this point, while the command state is
    still stale until the menu or idle machinery refreshes it. }
  if Assigned(Application) and Application.Active and (Application.ModalLevel = 0) then
    Application.Idle(False);
end;

{ GTK4: Legacy event controller callback for mouse events.
  GestureClick in capture phase doesn't fire reliably on GtkWindow,
  so we use EventControllerLegacy with GDK4 opaque event accessors instead.
  IMPORTANT: gdk_event_get_event_type returns GTK4-native values (GDK4_xxx
  constants from lazgtk4_compat), NOT the GTK3 enum values in lazgdk4.pas.
  Synthetic events must use the lazgdk4.pas constants (GDK_BUTTON_PRESS etc.)
  because GtkEventMouse checks Event^.type_ against those. }
function Gtk4LegacyEventCB(controller: PGtkEventController;
  event: PGdkEvent; Data: gpointer): gboolean; cdecl;
var
  evTypeNative: Integer;
  SynEvent: TGdkEvent;
  ACtl: TGtk4Widget;
  AWidget: PGtkWidget;
  x, y: double;
  NativeW: PGtkWidget;
  SurfOffX, SurfOffY: double;
  ClickTime: guint32;
  ClickButton: guint;
  DblClickTime, DblClickDist: gint;
  WidgetX, WidgetY: double;
  DeferInfo: PDeferredMouseEvent;
begin
  Result := False;
  if Data = nil then exit;
  if not Gtk4IsLiveWidgetPointer(Data) then exit;

  evTypeNative := Ord(gdk_event_get_event_type(event));

  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then exit;

  AWidget := gtk_event_controller_get_widget(controller);

  case evTypeNative of
    GDK4_BUTTON_PRESS, GDK4_BUTTON_RELEASE:
    begin
      { TButtonControl: GTK4 fires 'clicked' signal directly, so at runtime
        we skip the LCL mouse path to avoid double-handling. But in design
        mode the designer intercepts LM_LBUTTONDOWN via IsDesignMsg —
        we must let the event through so components can be selected. }
      if (ACtl.LCLObject is TButtonControl) and
         not (csDesigning in ACtl.LCLObject.ComponentState) then exit;

      { GTK4 composite input widgets (GtkEntry→GtkText, GtkTextView):
        CAPTURE-phase controllers fire before GTK4's native focus mechanism.
        GTK4 uses gtk_widget_pick to find the target, but GtkText (internal
        child of GtkEntry) needs focus for text input. Calling grab_focus
        synchronously here ensures focus enters the entry before TARGET phase,
        enabling text editing mode on click. }
      if (evTypeNative = GDK4_BUTTON_PRESS) and
         (ACtl.WidgetType * [wtEntry, wtMemo] <> []) then
      begin
        if wtEntry in ACtl.WidgetType then
          gtk_entry_grab_focus_without_selecting(PGtkEntry(AWidget))
        else
          AWidget^.grab_focus;
      end;

      FillChar(SynEvent{%H-}, SizeOf(SynEvent), 0);
      { Map GTK4 native type to Pascal/GTK3 constants for GtkEventMouse.
        GTK4 removed GDK_2BUTTON_PRESS at the raw event level — double-clicks
        are only available via GtkGestureClick n_press. Since we use a legacy
        event controller, detect double/triple clicks manually. }
      if evTypeNative = GDK4_BUTTON_PRESS then
      begin
        ClickTime := gdk_event_get_time(event);
        ClickButton := gdk4_button_event_get_button(event);
        gdk4_event_get_position(event, x, y);
        { Double-click thresholds: use GTK defaults (400ms, 5px).
          GtkSettings properties could be queried but require varargs
          g_object_get which doesn't bind cleanly to Pascal. }
        DblClickTime := 400;
        DblClickDist := 5;
        { CAPTURE-phase controllers fire parent→child for each physical click,
          so the same GDK event triggers multiple callbacks with different
          widgets but identical timestamps. Only update click tracking for
          NEW physical clicks (different timestamp). Subsequent CAPTURE
          callbacks for the same click reuse the existing Gtk4ClickCount. }
        if ClickTime <> Gtk4LastClickTime then
        begin
          if (ClickButton = Gtk4LastClickButton) and
             (ClickTime - Gtk4LastClickTime <= guint32(DblClickTime)) and
             (Abs(x - Gtk4LastClickX) <= DblClickDist) and
             (Abs(y - Gtk4LastClickY) <= DblClickDist) then
            Inc(Gtk4ClickCount)
          else
            Gtk4ClickCount := 1;
          Gtk4LastClickTime := ClickTime;
          Gtk4LastClickX := x;
          Gtk4LastClickY := y;
          Gtk4LastClickButton := ClickButton;
        end;

        if Gtk4ClickCount = 2 then
          SynEvent.type_ := GDK_2BUTTON_PRESS
        else if Gtk4ClickCount >= 3 then
          SynEvent.type_ := GDK_3BUTTON_PRESS
        else
          SynEvent.type_ := GDK_BUTTON_PRESS;
      end
      else
        SynEvent.type_ := GDK_BUTTON_RELEASE;
      gdk4_event_get_position(event, x, y);
      { GTK4: gdk_event_get_position returns surface-relative coordinates
        (including CSD title bar). Always subtract CSD offset via
        gtk4_native_get_surface_transform to get content-relative coords.
        For nested child widgets, additionally translate from toplevel
        content coords to widget-local coords. }
      NativeW := gtk4_widget_get_native(AWidget);
      if NativeW <> nil then
      begin
        gtk4_native_get_surface_transform(NativeW, @SurfOffX, @SurfOffY);
        SynEvent.button.x_root := x - SurfOffX;
        SynEvent.button.y_root := y - SurfOffY;
        if (NativeW <> AWidget) and
           gtk4_widget_translate_coordinates(NativeW, AWidget,
             x - SurfOffX, y - SurfOffY, @WidgetX, @WidgetY) then
        begin
          SynEvent.button.x := WidgetX;
          SynEvent.button.y := WidgetY;
        end
        else
        begin
          SynEvent.button.x := x - SurfOffX;
          SynEvent.button.y := y - SurfOffY;
        end;
      end
      else
      begin
        SynEvent.button.x_root := x;
        SynEvent.button.y_root := y;
        SynEvent.button.x := x;
        SynEvent.button.y := y;
      end;
      SynEvent.button.button := gdk4_button_event_get_button(event);
      SynEvent.button.state := gdk4_event_get_modifier_state(event);
      SynEvent.button.send_event := 0;
      { Identify the physical event (deferred-dispatch dedup key — see
        ProcessGtk4DeferredMouseEvents).  Applies to both press and
        release: this block is shared by GDK4_BUTTON_PRESS/RELEASE. }
      SynEvent.button.time := gdk_event_get_time(event);
      { GTK4: Queue mouse button event for deferred dispatch. Events are
        processed in AppProcessMessages AFTER g_main_context_iteration
        returns, ensuring we are completely outside GLib dispatch and
        avoiding re-entrant event processing that causes modal dialog hangs. }
      New(DeferInfo);
      DeferInfo^.Ctl := ACtl;
      DeferInfo^.Widget := AWidget;
      DeferInfo^.Event := SynEvent;
      { GTK4: Unlike GTK2/Qt5, GTK4's native click-to-focus does not work
        reliably for child widgets inside CAPTURE-phase event controller
        chains. Explicitly set focus on click for any focusable widget. }
      { Focus criterion: LCL bookkeeping (Focused) OR — for child controls —
        the GTK reality check: with single-source focus delivery LCL can
        legitimately consider a control focused while the GTK focus widget
        sits on a sibling (e.g. notebook tab after a page switch), and only
        a grab re-syncs key routing. }
      DeferInfo^.DoFocus := (evTypeNative = GDK4_BUTTON_PRESS) and
         ACtl.LCLObject.CanFocus and
         ((not ACtl.LCLObject.Focused) or
          ((not (wtWindow in ACtl.WidgetType)) and
           not Gtk4WidgetSubtreeHasGtkFocus(ACtl)));
      DeferInfo^.IsWindow := (wtWindow in ACtl.WidgetType);
      Gtk4DeferredMouseEvents.Add(DeferInfo);
    end;
    GDK4_MOTION_NOTIFY:
    begin
      FillChar(SynEvent{%H-}, SizeOf(SynEvent), 0);
      SynEvent.type_ := GDK_MOTION_NOTIFY;
      gdk4_event_get_position(event, x, y);
      { Convert surface-relative to content-relative (subtract CSD offset).
        For nested widgets, additionally translate to widget-local coords. }
      NativeW := gtk4_widget_get_native(AWidget);
      if NativeW <> nil then
      begin
        gtk4_native_get_surface_transform(NativeW, @SurfOffX, @SurfOffY);
        if (NativeW <> AWidget) and
           gtk4_widget_translate_coordinates(NativeW, AWidget,
             x - SurfOffX, y - SurfOffY, @WidgetX, @WidgetY) then
        begin
          SynEvent.motion.x := WidgetX;
          SynEvent.motion.y := WidgetY;
        end
        else
        begin
          SynEvent.motion.x := x - SurfOffX;
          SynEvent.motion.y := y - SurfOffY;
        end;
      end
      else
      begin
        SynEvent.motion.x := x;
        SynEvent.motion.y := y;
      end;
      SynEvent.motion.state := gdk4_event_get_modifier_state(event);
      ACtl.GtkEventMouseMove(AWidget, @SynEvent);
    end;
    GDK4_ENTER_NOTIFY:
    begin
      FillChar(SynEvent{%H-}, SizeOf(SynEvent), 0);
      SynEvent.type_ := GDK_ENTER_NOTIFY;
      gdk4_event_get_position(event, x, y);
      { Convert surface-relative to content-relative (subtract CSD offset).
        For nested widgets, additionally translate to widget-local coords. }
      NativeW := gtk4_widget_get_native(AWidget);
      if NativeW <> nil then
      begin
        gtk4_native_get_surface_transform(NativeW, @SurfOffX, @SurfOffY);
        if (NativeW <> AWidget) and
           gtk4_widget_translate_coordinates(NativeW, AWidget,
             x - SurfOffX, y - SurfOffY, @WidgetX, @WidgetY) then
        begin
          SynEvent.crossing.x := WidgetX;
          SynEvent.crossing.y := WidgetY;
        end
        else
        begin
          SynEvent.crossing.x := x - SurfOffX;
          SynEvent.crossing.y := y - SurfOffY;
        end;
      end
      else
      begin
        SynEvent.crossing.x := x;
        SynEvent.crossing.y := y;
      end;
      ACtl.GtkEventMouseEnterLeave(AWidget, @SynEvent);
    end;
    GDK4_LEAVE_NOTIFY:
    begin
      FillChar(SynEvent{%H-}, SizeOf(SynEvent), 0);
      SynEvent.type_ := GDK_LEAVE_NOTIFY;
      ACtl.GtkEventMouseEnterLeave(AWidget, @SynEvent);
    end;
  end;
end;

{ IME preedit-start callback: fired when composition begins (CJK/Hangul) }
procedure Gtk4IMPreeditStartCB({%H-}context: PGtkIMContext; Data: gpointer); cdecl;
var
  ACtl: TGtk4Widget;
  Msg: TLMessage;
begin
  if (Data = nil) or not Gtk4IsLiveWidgetPointer(Data) then Exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then Exit;
  ACtl.FIMPreeditActive := True;
  ACtl.FIMSkipDelete := True;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_IM_COMPOSITION;
  Msg.WParam := GTK_IM_FLAG_START;
  Msg.LParam := 0;
  ACtl.DeliverMessage(Msg, False);
end;

{ IME preedit-end callback: fired when composition ends }
procedure Gtk4IMPreeditEndCB({%H-}context: PGtkIMContext; Data: gpointer); cdecl;
var
  ACtl: TGtk4Widget;
  Msg: TLMessage;
begin
  if (Data = nil) or not Gtk4IsLiveWidgetPointer(Data) then Exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then Exit;
  ACtl.FIMPreeditActive := False;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_IM_COMPOSITION;
  Msg.WParam := GTK_IM_FLAG_END;
  Msg.LParam := 0;
  ACtl.DeliverMessage(Msg, False);
end;

{ IME preedit-changed callback: fired when the intermediate preedit text changes.
  Called repeatedly as the user types CJK/Hangul characters to show
  the "in-progress" composition (e.g., ㅎ → 하 → 한). }
procedure Gtk4IMPreeditChangedCB(context: PGtkIMContext; Data: gpointer); cdecl;
var
  ACtl: TGtk4Widget;
  Msg: TLMessage;
  str: Pgchar;
  pangoattr: PPangoAttrList;
  curpos: gint;
  Flag: WPARAM;
  PreeditStr: string;
begin
  if (Data = nil) or not Gtk4IsLiveWidgetPointer(Data) then Exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then Exit;
  ACtl.FIMPreeditActive := True;

  { Retrieve the current preedit string, Pango attributes, and cursor offset }
  str := nil;
  pangoattr := nil;
  curpos := 0;
  gtk_im_context_get_preedit_string(context, @str, @pangoattr, @curpos);
  if str <> nil then
    PreeditStr := str
  else
    PreeditStr := '';
  if str <> nil then
    g_free(str);
  if pangoattr <> nil then
    pango_attr_list_unref(pangoattr);

  Flag := GTK_IM_FLAG_PREEDIT;
  if not ACtl.FIMSkipDelete then
    Flag := Flag or GTK_IM_FLAG_REPLACE
  else
    ACtl.FIMSkipDelete := False;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_IM_COMPOSITION;
  Msg.WParam := Flag;
  Msg.LParam := LPARAM(PChar(PreeditStr));
  ACtl.DeliverMessage(Msg, False);
end;

{ IME commit callback: fired when the input method produces a final string.
  For controls with an IME handler (SynEdit), sends LM_IM_COMPOSITION(COMMIT)
  so the handler can replace preedit selection with final text.
  For other controls, falls back to IntfUTF8KeyPress. }
procedure Gtk4IMCommitCB({%H-}context: PGtkIMContext; str: Pgchar; Data: gpointer); cdecl;
var
  ACtl: TGtk4Widget;
  UTF8Str: TUTF8Char;
  Msg: TLMessage;
begin
  if Data = nil then exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then exit;
  if (str = nil) or (str^ = #0) then exit;

  { Try LM_IM_COMPOSITION(COMMIT) first — SynEdit's IME handler processes this
    and replaces the selected preedit text with the committed text. }
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_IM_COMPOSITION;
  Msg.WParam := GTK_IM_FLAG_COMMIT;
  Msg.LParam := LPARAM(PChar(str));
  ACtl.DeliverMessage(Msg, False);

  { If handled by IME handler (Result=1), the text is already inserted.
    Otherwise, fall back to IntfUTF8KeyPress for controls without IME handling. }
  if Msg.Result = 0 then
  begin
    UTF8Str := str;
    ACtl.LCLObject.IntfUTF8KeyPress(UTF8Str, 1, False);
  end;
end;

{ im-update: fired AFTER filter_keypress returns TRUE (IM handled the key).
  If this fires, key-pressed signal will NOT fire for the same event. }
procedure Gtk4IMUpdateCB({%H-}controller: PGtkEventController; Data: gpointer); cdecl;
begin
  { IM handled the key — key-pressed/key-released won't fire for this event.
    Currently a no-op; kept for potential future use. }
  if Data = nil then exit;
end;

{ True when AWidget is a form and a child control is focused, so a key that
  bubbled up to the form's key controller was already delivered (KeyPreview
  included) by that child's own controller. Suppresses the double
  Form.OnKeyDown/OnKeyUp this bubbling would otherwise cause. When no child
  control is active the form legitimately owns the key. }
function Gtk4FormKeyBelongsToChild(AWidget: TGtk4Widget): Boolean;
begin
  Result := (wtWindow in AWidget.WidgetType)
    and (AWidget.LCLObject is TCustomForm)
    and (TCustomForm(AWidget.LCLObject).ActiveControl <> nil);
end;

function Gtk4KeyPressedCB(controller: PGtkEventController; keyval: guint;
  keycode: guint; state: TGdkModifierType; Data: gpointer): gboolean; cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
  UChar: guint32;
  UTF8Buf: array[0..6] of char;
  Len: Integer;
begin
  Result := False;
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;
  { When a CHILD control has focus, its own key controller already delivered the
    key (KeyPreview included) and the event only bubbled up to the form's
    controller because the child did not consume it — delivering again would
    fire Form.OnKeyDown twice. Skip that bubbled-up copy. }
  if Gtk4FormKeyBelongsToChild(TGtk4Widget(Data)) then exit;
  FillChar(Event{%H-}, SizeOf(Event), 0);
  Event.type_ := GDK_KEY_PRESS;
  Event.key.keyval := keyval;
  Event.key.hardware_keycode := keycode;
  Event.key.state := state;
  Event.key.send_event := 0;

  { Convert keyval to string via gdk_keyval_to_unicode }
  UChar := gdk_keyval_to_unicode(keyval);
  if (UChar > 0) and (UChar < $110000) then
  begin
    FillChar(UTF8Buf{%H-}, SizeOf(UTF8Buf), 0);
    if UChar < $80 then
    begin
      UTF8Buf[0] := Char(UChar);
      Len := 1;
    end else
    if UChar < $800 then
    begin
      UTF8Buf[0] := Char($C0 or (UChar shr 6));
      UTF8Buf[1] := Char($80 or (UChar and $3F));
      Len := 2;
    end else
    if UChar < $10000 then
    begin
      UTF8Buf[0] := Char($E0 or (UChar shr 12));
      UTF8Buf[1] := Char($80 or ((UChar shr 6) and $3F));
      UTF8Buf[2] := Char($80 or (UChar and $3F));
      Len := 3;
    end else
    begin
      UTF8Buf[0] := Char($F0 or (UChar shr 18));
      UTF8Buf[1] := Char($80 or ((UChar shr 12) and $3F));
      UTF8Buf[2] := Char($80 or ((UChar shr 6) and $3F));
      UTF8Buf[3] := Char($80 or (UChar and $3F));
      Len := 4;
    end;
    if Len > 0 then ;
    Event.key.string_ := @UTF8Buf[0];
  end else
    Event.key.string_ := '';

  AWidget := gtk_event_controller_get_widget(controller);
  Result := TGtk4Widget(Data).GtkEventKey(AWidget, @Event, True);
end;

function Gtk4KeyReleasedCB(controller: PGtkEventController; keyval: guint;
  keycode: guint; state: TGdkModifierType; Data: gpointer): gboolean; cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
begin
  Result := False;
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;
  { See Gtk4KeyPressedCB: skip the bubbled-up copy when a child control owns the
    key, so Form.OnKeyUp does not fire twice. }
  if Gtk4FormKeyBelongsToChild(TGtk4Widget(Data)) then exit;

  FillChar(Event{%H-}, SizeOf(Event), 0);
  Event.type_ := GDK_KEY_RELEASE;
  Event.key.keyval := keyval;
  Event.key.hardware_keycode := keycode;
  Event.key.state := state;
  Event.key.send_event := 0;
  Event.key.string_ := '';

  AWidget := gtk_event_controller_get_widget(controller);
  Result := TGtk4Widget(Data).GtkEventKey(AWidget, @Event, False);
end;

{ GTK4: Design-mode key interception (CAPTURE phase).
  Native input widgets (GtkEntry→GtkText, GtkTextView) consume editing keys
  (Delete, Backspace, arrows, characters) internally during the TARGET phase,
  before the LCL key controller (BUBBLE phase) ever sees them. In the form
  designer this is wrong: pressing Delete on a selected TEdit must delete the
  component, not edit its text. This capture-phase controller fires FIRST; when
  csDesigning is set it routes the key to the designer via GtkEventKey (which
  delivers LM_KEYDOWN → TControl.WndProc → Designer.IsDesignMsg) and consumes
  it so the native widget performs no editing. At runtime it is a no-op
  (returns False), leaving normal key handling untouched. }
function Gtk4DesignKeyPressedCB(controller: PGtkEventController; keyval: guint;
  keycode: guint; state: TGdkModifierType; Data: gpointer): gboolean; cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
  ACtl: TGtk4Widget;
begin
  Result := False;
  if Data = nil then exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then exit;
  if not Assigned(ACtl.LCLObject)
     or not (csDesigning in ACtl.LCLObject.ComponentState) then
    exit;

  FillChar(Event{%H-}, SizeOf(Event), 0);
  Event.type_ := GDK_KEY_PRESS;
  Event.key.keyval := keyval;
  Event.key.hardware_keycode := keycode;
  Event.key.state := state;
  Event.key.send_event := 0;
  Event.key.string_ := '';

  AWidget := gtk_event_controller_get_widget(controller);
  { Deliver to the designer; consume unconditionally so the native widget
    (entry/text) does not edit its content in design mode. }
  Gtk4FlushDesignInputBeforeCommandKey(keyval, state);
  ACtl.GtkEventKey(AWidget, @Event, True);
  Result := True;
end;

procedure Gtk4MotionCB(controller: PGtkEventController; x: double;
  y: double; Data: gpointer); cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
  AState: TGdkModifierType;
begin
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;

  FillChar(Event{%H-}, SizeOf(Event), 0);
  AState := gtk4_event_controller_get_current_event_state(controller);

  Event.type_ := GDK_MOTION_NOTIFY;
  Event.motion.x := x;
  Event.motion.y := y;
  Event.motion.x_root := x;
  Event.motion.y_root := y;
  Event.motion.state := AState;
  Event.motion.send_event := 0;

  AWidget := gtk_event_controller_get_widget(controller);
  TGtk4Widget(Data).GtkEventMouseMove(AWidget, @Event);
end;

procedure Gtk4EnterCB(controller: PGtkEventController; x: double;
  y: double; Data: gpointer); cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
begin
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;

  { Skip enter for windows unless on container widget }
  if wtWindow in TGtk4Widget(Data).WidgetType then
  begin
    AWidget := gtk_event_controller_get_widget(controller);
    if AWidget <> TGtk4Widget(Data).GetContainerWidget then
      exit;
  end;

  FillChar(Event{%H-}, SizeOf(Event), 0);
  Event.type_ := GDK_ENTER_NOTIFY;
  Event.crossing.x := x;
  Event.crossing.y := y;

  AWidget := gtk_event_controller_get_widget(controller);
  TGtk4Widget(Data).GtkEventMouseEnterLeave(AWidget, @Event);
end;

procedure Gtk4LeaveCB(controller: PGtkEventController; Data: gpointer); cdecl;
var
  Event: TGdkEvent;
  AWidget: PGtkWidget;
begin
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;

  { Skip leave for windows unless on container widget }
  if wtWindow in TGtk4Widget(Data).WidgetType then
  begin
    AWidget := gtk_event_controller_get_widget(controller);
    if AWidget <> TGtk4Widget(Data).GetContainerWidget then
      exit;
  end;

  FillChar(Event{%H-}, SizeOf(Event), 0);
  Event.type_ := GDK_LEAVE_NOTIFY;

  AWidget := gtk_event_controller_get_widget(controller);
  TGtk4Widget(Data).GtkEventMouseEnterLeave(AWidget, @Event);
end;

var
  Gtk4LastFocusIn: PGtkWidget = nil;
  Gtk4LastFocusOut: PGtkWidget = nil;
  Gtk4FocusTimer: guint = 0;
  Gtk4AppActive: Boolean = False;
  { Live-widget registry: a pointer-keyed set used to tell a valid TGtk4Widget
    handle from a freed one without dereferencing it (see IsValidHandle). A TMap
    (balanced tree, O(log n)) keeps HasId off the hot paths that a linear list
    scan slowed down — the same structure qt5 uses for SavedHandlesList. }
  Gtk4LiveWidgetObjects: TMap = nil;

procedure Gtk4RegisterLiveWidget(AWidget: TGtk4Widget);
begin
  if AWidget = nil then
    Exit;
  if Gtk4LiveWidgetObjects = nil then
    Gtk4LiveWidgetObjects := TMap.Create(TMapIdType(ituPtrSize), SizeOf(Pointer));
  if not Gtk4LiveWidgetObjects.HasId(AWidget) then
    Gtk4LiveWidgetObjects.Add(AWidget, AWidget);
end;

procedure Gtk4UnregisterLiveWidget(AWidget: TGtk4Widget);
begin
  if (AWidget = nil) or (Gtk4LiveWidgetObjects = nil) then
    Exit;
  if Gtk4LiveWidgetObjects.HasId(AWidget) then
    Gtk4LiveWidgetObjects.Delete(AWidget);
end;

function Gtk4IsLiveWidgetPointer(AData: gpointer): Boolean;
begin
  Result := (AData <> nil) and (Gtk4LiveWidgetObjects <> nil) and
    Gtk4LiveWidgetObjects.HasId(AData);
end;

function Gtk4AppFocusTimerCB({%H-}Data: gpointer): gboolean; cdecl;
begin
  Result := G_SOURCE_REMOVE_;
  Gtk4FocusTimer := 0;
  if Gtk4LastFocusIn = nil then
  begin
    if Gtk4AppActive then
    begin
      Gtk4AppActive := False;
      Application.IntfAppDeactivate();
    end;
  end;
end;

procedure Gtk4StartFocusTimer;
begin
  if Gtk4FocusTimer <> 0 then
    g_source_remove(Gtk4FocusTimer);
  Gtk4FocusTimer := g_timeout_add(50, @Gtk4AppFocusTimerCB, nil);
end;

procedure Gtk4EnsureAppActive(AWidget: PGtkWidget);
begin
  if AWidget = nil then exit;
  Gtk4LastFocusIn := AWidget;
  if Gtk4FocusTimer <> 0 then
  begin
    g_source_remove(Gtk4FocusTimer);
    Gtk4FocusTimer := 0;
  end;
  if not Gtk4AppActive then
  begin
    Gtk4AppActive := True;
    Application.IntfAppActivate();
  end;
end;

procedure Gtk4HandleAppFocusIn(AWidget: PGtkWidget);
begin
  { MenuBar/Popover focus churn is internal menu navigation and should not
    toggle global app active state. }
  if Gtk4IsMenuBar(PGObject(AWidget)) or Gtk4IsMenu(PGObject(AWidget)) then
    Exit;
  Gtk4EnsureAppActive(AWidget);
end;

procedure Gtk4HandleAppFocusOut(AWidget: PGtkWidget);
begin
  { Ignore menu widget focus transitions for app activation bookkeeping. }
  if Gtk4IsMenuBar(PGObject(AWidget)) or Gtk4IsMenu(PGObject(AWidget)) then
    Exit;
  Gtk4LastFocusOut := AWidget;
  if Gtk4LastFocusOut = Gtk4LastFocusIn then
  begin
    Gtk4LastFocusIn := nil;
    Gtk4StartFocusTimer;
  end;
end;

{ LM_SETFOCUS/LM_KILLFOCUS delivery moved to the toplevel's
  notify::focus-widget handler (Gtk4WindowFocusWidgetCB below).
  GtkEventControllerFocus enter/leave use CONTAINMENT semantics: a
  container's controller fires 'enter' when focus lands on a NESTED LCL
  child, so forwarding them as LM_SETFOCUS made LCL believe the container
  itself got focus.  The resulting ActiveControl repair loop was measured
  as an unbounded SetFocus war (SynEdit1<->SrcEditNotebook, ~150 calls/s)
  that froze menus and keyboard.  The controllers stay attached for
  app-level activity tracking and per-widget IM state only. }
procedure Gtk4FocusEnterCB(controller: PGtkEventController; Data: gpointer); cdecl;
var
  AWidget: PGtkWidget;
begin
  if Data = nil then exit;
  if not TGtk4Widget(Data).CanSendLCLMessage then exit;
  AWidget := gtk_event_controller_get_widget(controller);
  Gtk4HandleAppFocusIn(AWidget);
end;

procedure Gtk4FocusLeaveCB(controller: PGtkEventController; Data: gpointer); cdecl;
var
  AWidget: PGtkWidget;
  ACtl: TGtk4Widget;
begin
  if Data = nil then exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then exit;
  AWidget := gtk_event_controller_get_widget(controller);
  Gtk4HandleAppFocusOut(AWidget);
  { Reset a live IM preedit when GTK focus leaves this widget's subtree —
    the LM_KILLFOCUS from the window-level handler also does this, but
    containment-leave can happen without an LCL focus change (e.g. focus
    moving into a popover). }
  if (ACtl.FIMContext <> nil) and ACtl.FIMPreeditActive then
  begin
    ACtl.FIMContext^.reset;
    ACtl.FIMPreeditActive := False;
  end;
end;

var
  { The LCL control that was last told via LM_SETFOCUS that it owns
    keyboard focus.  Single source of truth for LCL focus messages. }
  Gtk4CurrentFocusCtl: TGtk4Widget = nil;
  Gtk4FocusDeliveryDepth: Integer = 0;
  { True while TGtk4Widget.SetFocus runs its grab: the synchronous
    focus-widget notify then knows the change is LCL-INTENDED (SetFocus /
    click focus pass) rather than a GTK-internal fallback (e.g. focus
    dropped onto the notebook tab when a popover disappears). }
  Gtk4LCLFocusIntent: Boolean = False;
  { Whether the CURRENT owner acquired focus through an LCL-intended
    change.  Menu-dismissal restore must not override intended moves. }
  Gtk4FocusOwnerIntended: Boolean = False;

{ Owner widget can meaningfully take focus right now. }
function Gtk4OwnerFocusable(ACtl: TGtk4Widget): Boolean;
begin
  Result := (ACtl <> nil) and Gtk4IsLiveWidgetPointer(ACtl) and
    ACtl.CanSendLCLMessage and (ACtl.Widget <> nil) and
    Gtk4IsWidget(PGObject(ACtl.Widget)) and
    ACtl.Widget^.get_mapped and ACtl.Widget^.is_sensitive;
end;


{ Resolve which LCL control owns the GTK focus widget AFocus: nearest
  'lclwidget'-tagged ancestor.  Focus inside a GtkPopover (menu dropdown,
  context menu) is TRANSIENT — win32 menus never move WM_SETFOCUS either —
  reported via ATransient so callers leave LCL focus untouched.  This also
  keeps menu interaction from generating any LM focus traffic, which used
  to feed the popover open/close storm. }
function Gtk4ResolveFocusOwner(AFocus: PGtkWidget; out ATransient: Boolean): TGtk4Widget;
var
  W: PGtkWidget;
begin
  Result := nil;
  ATransient := False;
  W := AFocus;
  while (W <> nil) and Gtk4IsWidget(PGObject(W)) do
  begin
    { Menu machinery is transient too: GtkPopoverMenuBar grabs focus onto
      its bar items during hover/keynav (set_active_item -> grab_focus).
      Mapping a bar item to the owning form made LCL restore ActiveControl,
      which fought the bar's focus grab in a ~30ms loop. }
    if g_type_check_instance_is_a(PGTypeInstance(W), gtk_popover_get_type) or
       (g_type_name_from_instance(PGTypeInstance(W)) = 'GtkPopoverMenuBar') then
    begin
      ATransient := True;
      exit;
    end;
    Result := TGtk4Widget(g_object_get_data(PGObject(W), 'lclwidget'));
    if Result <> nil then
      exit;
    W := W^.get_parent;
  end;
end;

procedure Gtk4DeliverFocusChange(ANewOwner: TGtk4Widget);
var
  Old: TGtk4Widget;
  Event: TGdkEvent;
begin
  if ANewOwner = Gtk4CurrentFocusCtl then
    exit;
  if (ANewOwner <> nil) and (ANewOwner.Widget <> nil) then
    Gtk4EnsureAppActive(ANewOwner.Widget);
  { Hard stop for pathological LCL SetFocus cycles re-entering via the
    synchronous notify. }
  if Gtk4FocusDeliveryDepth > 3 then
    exit;
  Inc(Gtk4FocusDeliveryDepth);
  try
    Old := Gtk4CurrentFocusCtl;
    { Update BEFORE delivering: a re-entrant notify for the same owner
      then no-ops instead of recursing. }
    Gtk4CurrentFocusCtl := ANewOwner;
    Gtk4FocusOwnerIntended := Gtk4LCLFocusIntent;
    if (Old <> nil) and Gtk4IsLiveWidgetPointer(Old) and Old.CanSendLCLMessage then
    begin
      FillChar(Event{%H-}, SizeOf(Event), 0);
      Event.type_ := GDK_FOCUS_CHANGE;
      Event.focus_change.in_ := 0;
      Old.GtkEventFocus(Old.Widget, @Event);
    end;
    { The KILLFOCUS handler (CM_EXIT/OnExit user code) may itself have
      moved focus; a nested notify then already delivered the new state
      and ANewOwner is stale — do not send it a SETFOCUS. }
    if Gtk4CurrentFocusCtl <> ANewOwner then
      exit;
    if (ANewOwner <> nil) and Gtk4IsLiveWidgetPointer(ANewOwner) and
       ANewOwner.CanSendLCLMessage then
    begin
      FillChar(Event{%H-}, SizeOf(Event), 0);
      Event.type_ := GDK_FOCUS_CHANGE;
      Event.focus_change.in_ := 1;
      ANewOwner.GtkEventFocus(ANewOwner.Widget, @Event);
    end;
  finally
    Dec(Gtk4FocusDeliveryDepth);
  end;
end;

{ Deliver toplevel form activation (LM_ACTIVATE) to the LCL. gtk4's
  notify::is-active previously delivered only focus, so the IDE never learned
  a form was activated: DisplayState never became dsForm and Screen's active
  custom form stayed unset, leaving form-designer IDE commands (Ctrl+Z undo,
  redo, ...) disabled. Guards mirror gtk3/qt: forms only, not embedded, and
  skip when already in that active state so we don't fire duplicate
  OnActivate/OnDeactivate. }
procedure Gtk4DeliverFormActivate(AWin: TGtk4Widget; AActive: Boolean);
var
  Form: TCustomForm;
begin
  if (AWin = nil) or not Gtk4IsLiveWidgetPointer(AWin) or not AWin.CanSendLCLMessage then
    exit;
  if not (AWin.LCLObject is TCustomForm) then exit;
  Form := TCustomForm(AWin.LCLObject);
  if Form.Parent <> nil then exit;      { embedded form, not a real toplevel }
  if Form.Active = AActive then exit;   { already in that state }
  if AActive then
    LCLSendActivateMsg(Form, WA_ACTIVE, False)
  else
    LCLSendActivateMsg(Form, WA_INACTIVE, False);
end;

{ True when the current LCL focus owner's toplevel is AWindow. }
function Gtk4CurrentFocusInWindow(AWindow: PGObject): Boolean;
begin
  Result := (Gtk4CurrentFocusCtl <> nil) and
    Gtk4IsLiveWidgetPointer(Gtk4CurrentFocusCtl) and
    (Gtk4CurrentFocusCtl.Widget <> nil) and
    Gtk4IsWidget(PGObject(Gtk4CurrentFocusCtl.Widget)) and
    (Gtk4CurrentFocusCtl.Widget^.get_ancestor(gtk_window_get_type) = PGtkWidget(AWindow));
end;

{ Save/restore the LCL focus owner around a popup menu's nested loop.
  Closing/unparenting the popover lets GTK drop focus onto an arbitrary
  fallback widget (measured: the notebook tab), silently hijacking
  keyboard input.  Win32 returns focus to the pre-menu control after
  dismissal — restore explicitly.  Restore is skipped when the owner's
  toplevel is no longer the active window (a menu action opened a dialog
  that now legitimately holds focus). }
function Gtk4SaveFocusOwner: TObject;
begin
  Result := Gtk4CurrentFocusCtl;
end;

procedure Gtk4RestoreFocusOwner(AOwner: TObject);
var
  TL: PGtkWidget;
begin
  if (AOwner = nil) or not Gtk4IsLiveWidgetPointer(AOwner) then exit;
  { A menu action may have intentionally focused ANOTHER control (LCL
    SetFocus during the handler).  Only GTK-internal drift — the fallback
    focus GTK picks when the popover disappears — gets overridden. }
  if (Gtk4CurrentFocusCtl <> nil) and (TObject(Gtk4CurrentFocusCtl) <> AOwner) and
     Gtk4FocusOwnerIntended then
    exit;
  if not Gtk4OwnerFocusable(TGtk4Widget(AOwner)) then exit;
  TL := TGtk4Widget(AOwner).Widget^.get_ancestor(gtk_window_get_type);
  if TL = nil then exit;
  if not gtk_window_is_active(PGtkWindow(TL)) then exit;
  TGtk4Widget(AOwner).SetFocus;
end;

{ notify::focus-widget — fires AFTER GtkWindow updates its focus widget
  (gtkwindow.c gtk_window_root_set_focus ends with g_object_notify), so
  gtk_window_get_focus is reliable here, unlike inside the focus
  controllers' enter/leave (crossing runs while focus_widget is nil). }
procedure Gtk4WindowFocusWidgetCB(AObject: PGObject; {%H-}pspec: Pointer;
  Data: gpointer); cdecl;
var
  F: PGtkWidget;
  Owner: TGtk4Widget;
  Transient: Boolean;
begin
  if Data = nil then exit;
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  F := gtk_window_get_focus(PGtkWindow(AObject));
  if F = nil then
  begin
    { Qt model (TQtWidgetSet.FocusChanged): when focus goes to nothing,
      deliver only the KILLFOCUS and let LCL's own activation machinery
      (or the next click's focus pass) re-assert.  Re-grabbing here was
      tried and became a pump for the menubar popover open/close storm. }
    if Gtk4CurrentFocusInWindow(AObject) then
      Gtk4DeliverFocusChange(nil);
    exit;
  end;
  Owner := Gtk4ResolveFocusOwner(F, Transient);
  if Transient then
    exit;
  Gtk4DeliverFocusChange(Owner);
end;

{ True when any popover in AWidget's subtree is currently mapped — an
  open menubar dropdown, popup menu or combo dropdown. }
function Gtk4SubtreeHasOpenPopover(AWidget: PGtkWidget): Boolean;
var
  Child: PGtkWidget;
begin
  Result := False;
  if AWidget = nil then exit;
  Child := gtk4_widget_get_first_child(AWidget);
  while Child <> nil do
  begin
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_popover_get_type) then
    begin
      if Child^.get_mapped then
        exit(True);
    end;
    if Gtk4SubtreeHasOpenPopover(Child) then
      exit(True);
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

var
  { Debounce for grab-flap suppression: popover seat grabs flap is-active
    at the popover open/close rate; a REAL deactivation (user switched to
    another application while a dropdown was open) stays inactive.  The
    pending check delivers the KILLFOCUS only if the window is still
    inactive when it fires. }
  Gtk4DeactivateCheckId: guint = 0;
  Gtk4DeactivateCheckWin: TGtk4Widget = nil;

function Gtk4DeactivateCheckCB({%H-}data: gpointer): gboolean; cdecl;
var
  AWin: TGtk4Widget;
begin
  Result := False; { G_SOURCE_REMOVE }
  Gtk4DeactivateCheckId := 0;
  AWin := Gtk4DeactivateCheckWin;
  Gtk4DeactivateCheckWin := nil;
  if (AWin = nil) or not Gtk4IsLiveWidgetPointer(AWin) then exit;
  if (AWin.Widget = nil) or not Gtk4IsGtkWindow(AWin.Widget) then exit;
  if gtk_window_is_active(PGtkWindow(AWin.Widget)) then exit; { flap-back }
  Gtk4DeliverFormActivate(AWin, False);
  if Gtk4CurrentFocusInWindow(PGObject(AWin.Widget)) then
    Gtk4DeliverFocusChange(nil);
end;

procedure Gtk4CancelDeactivateCheck;
begin
  if Gtk4DeactivateCheckId <> 0 then
  begin
    g_source_remove(Gtk4DeactivateCheckId);
    Gtk4DeactivateCheckId := 0;
  end;
  Gtk4DeactivateCheckWin := nil;
end;

{ notify::is-active — window (de)activation moves LCL focus like GTK2's
  toplevel focus-in/out events did: deactivate=KILLFOCUS to the owner in
  this window, activate=SETFOCUS to the owner of its focus widget. }
procedure Gtk4WindowIsActiveCB(AObject: PGObject; {%H-}pspec: Pointer;
  Data: gpointer); cdecl;
var
  F: PGtkWidget;
  Owner: TGtk4Widget;
  Transient: Boolean;
begin
  if Data = nil then exit;
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  { X11 grab-mode focus flap suppression: every popover seat grab sends
    the toplevel a FocusOut(NotifyGrab) and the ungrab a FocusIn, so
    is-active FLAPS at the popover open/close rate during menubar
    interaction (measured ~30Hz, translated into 56 KILL/SET pairs per
    second before this guard — the classic X11 rule is to ignore
    grab-mode focus events).  While a popover is open, a deactivation is
    therefore DEBOUNCED instead of delivered: if the window is still
    inactive when the check fires, it was a real switch (e.g. to another
    application with a dropdown open) and the KILLFOCUS goes out; a
    flap-back cancels it. }
  if gtk_window_is_active(PGtkWindow(AObject)) then
  begin
    Gtk4CancelDeactivateCheck;
    if Gtk4SubtreeHasOpenPopover(PGtkWidget(AObject)) then
      exit; { grab flap — no information }
    F := gtk_window_get_focus(PGtkWindow(AObject));
    Owner := Gtk4ResolveFocusOwner(F, Transient);
    if (not Transient) and (Owner <> nil) then
      Gtk4DeliverFocusChange(Owner);
    Gtk4DeliverFormActivate(TGtk4Widget(Data), True);
  end
  else
  begin
    { Window deactivated. Deliver form deactivation (LM_ACTIVATE/WA_INACTIVE)
      ALWAYS — even when the LCL focus owner is not inside this window.
      Previously this whole branch was gated on Gtk4CurrentFocusInWindow, so a
      tool window (e.g. the Object Inspector) whose focus owner had already
      moved elsewhere never got WA_INACTIVE and stayed stale-active. That kept
      Screen.ActiveCustomForm on the OI instead of returning to the designer
      form, which disabled form-designer IDE commands (Undo/Redo/...). The
      focus-out (Gtk4DeliverFocusChange(nil)) is still gated on the focus
      actually being in this window. }
    if Gtk4SubtreeHasOpenPopover(PGtkWidget(AObject)) then
    begin
      { Real deactivation vs grab flap is undecided yet — defer both the
        focus-out and the form deactivation to the debounce check. }
      Gtk4CancelDeactivateCheck;
      Gtk4DeactivateCheckWin := TGtk4Widget(Data);
      Gtk4DeactivateCheckId := g_timeout_add(120, @Gtk4DeactivateCheckCB, nil);
    end
    else
    begin
      Gtk4DeliverFormActivate(TGtk4Widget(Data), False);
      if Gtk4CurrentFocusInWindow(AObject) then
        Gtk4DeliverFocusChange(nil);
    end;
  end;
end;

function Gtk4ScrollCB(controller: PGtkEventController; dx: double;
  dy: double; Data: gpointer): gboolean; cdecl;
var
  Msg: TLMMouseEvent;
  ACtl: TGtk4Widget;
  AEvent: PGdkEvent;
  ex, ey: double;
  AWidget, NativeW: PGtkWidget;
  SurfOffX, SurfOffY, WidgetX, WidgetY: double;
begin
  Result := False;
  if Data = nil then exit;
  ACtl := TGtk4Widget(Data);
  if not ACtl.CanSendLCLMessage then exit;
  if (dx = 0) and (dy = 0) then exit;

  FillChar(Msg{%H-}, SizeOf(Msg), 0);

  { Vertical scroll takes priority; if dy=0, handle horizontal }
  if dy <> 0 then
  begin
    Msg.Msg := LM_MOUSEWHEEL;
    if dy < 0 then
      Msg.WheelDelta := 120
    else
      Msg.WheelDelta := -120;
  end else
  begin
    Msg.Msg := LM_MOUSEHWHEEL;
    if dx > 0 then
      Msg.WheelDelta := 120
    else
      Msg.WheelDelta := -120;
  end;

  { Get mouse position from the current GdkEvent.
    gdk4_event_get_position returns surface-relative coords; convert to
    widget-local by subtracting the CSD offset and translating. }
  AEvent := gtk4_event_controller_get_current_event(controller);
  if AEvent <> nil then
  begin
    Msg.State := GdkModifierStateToShiftState(
      gdk4_event_get_modifier_state(AEvent));
    if gdk4_event_get_position(AEvent, ex, ey) then
    begin
      AWidget := ACtl.GetContainerWidget;
      NativeW := gtk4_widget_get_native(AWidget);
      if NativeW <> nil then
      begin
        gtk4_native_get_surface_transform(NativeW, @SurfOffX, @SurfOffY);
        if (NativeW <> AWidget) and
           gtk4_widget_translate_coordinates(NativeW, AWidget,
             ex - SurfOffX, ey - SurfOffY, @WidgetX, @WidgetY) then
        begin
          Msg.X := SmallInt(Trunc(WidgetX));
          Msg.Y := SmallInt(Trunc(WidgetY));
        end
        else
        begin
          Msg.X := SmallInt(Trunc(ex - SurfOffX));
          Msg.Y := SmallInt(Trunc(ey - SurfOffY));
        end;
      end
      else
      begin
        Msg.X := SmallInt(Trunc(ex));
        Msg.Y := SmallInt(Trunc(ey));
      end;
    end;
  end;

  Msg.UserData := ACtl.LCLObject;
  Msg.Button := 0;

  NotifyApplicationUserInput(ACtl.LCLObject, Msg.Msg);
  if ACtl.DeliverMessage(Msg, True) <> 0 then
    Result := True;
end;

{ ====================================================================
  End GTK4 Event Controller Callbacks
  ==================================================================== }

function Gtk4DrawWidget(AWidget: PGtkWidget; AContext: Pcairo_t; Data: gpointer): gboolean; cdecl;
begin
  Result := False;
  if Data <> nil then
  begin
    { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents if needed. }
    Result := TGtk4Widget(Data).GtkEventPaint(AWidget, AContext);
  end;
end;

{ GTK4: draw_func callback for GtkDrawingArea overlays.
  Used by all widgets with FHasPaint=True (Window, Panel, GroupBox, CustomControl, etc.).
  This replaces the old GTK3 'draw' signal approach. }
procedure Gtk4PaintAreaDrawFunc(drawing_area: PGtkDrawingArea; cr: Pcairo_t;
  width: gint; height: gint; user_data: gpointer); cdecl;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  TGtk4Widget(user_data).GtkEventPaint(PGtkWidget(drawing_area), cr);
end;

procedure Gtk4MapWidget(AWidget: PGtkWidget; Data: gPointer); cdecl;
var
  Allocation: TGtkAllocation;
  ARect: TRect;
begin
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  if TGtk4Widget(Data).LCLObject is TCustomGroupBox then
  begin
    { GTK4 removed the size-allocate signal, so the client rect that was cached
      before the frame reserved its border+label space (pre-realize getClientRect
      -> full BoundsRect) is never refreshed. Now that the groupbox is mapped
      (realized + allocated), invalidate it so LCL re-queries getClientRect,
      which then reads the inset overlay allocation. }
    TGtk4Widget(Data).LCLObject.InvalidateClientRectCache(True);
    TGtk4Widget(Data).LCLObject.DoAdjustClientRectChange;
  end;
  AWidget^.get_allocation(@Allocation);
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('**** Gtk4MapWidget ....',dbgsName(TGtk4Widget(Data).LCLObject));
  with Allocation do
    DebugLn(' Allocation ',Format('x %d y %d w %d h %d',[x,y,width,height]));
  {$ENDIF}
  ARect := TGtk4Widget(Data).LCLObject.BoundsRect;
  {$IFDEF GTK4DEBUGCORE}
  with ARect do
    DebugLn(' Rect ',Format('x %d y %d w %d h %d',[Left,Top,Right - Left, Bottom - Top]));
  {$ENDIF}
  if ARect.Left<ARect.Right then ;
  { GTK4: GdkWindow removed. No gdk_window_set_events, move, resize.
    Widget positioning is handled by layout managers. }

  { GTK4: Set client_widget on the IM context when the widget is mapped
    (i.e., realized and visible). GtkText does this in its realize handler.
    The IM module (ibus/fcitx5) needs a realized widget to get the GDK surface
    and display for proper D-Bus connection. }
  if TGtk4Widget(Data).FIMContext <> nil then
  begin
    gtk4_im_context_set_client_widget(TGtk4Widget(Data).FIMContext,
      TGtk4Widget(Data).GetContainerWidget);
  end;
end;

{ ---- GtkFixedLayout vtable patch ----
  Root cause: GTK4's GtkFixedLayout.allocate() uses gtk_widget_get_preferred_size()
  which returns the INTRINSIC minimum size (incorporating set_size_request only as
  a MAX floor). When intrinsic minimum > set_size_request, children get allocated
  at their intrinsic minimum, ignoring the LCL-requested size.

  Example: GtkNotebook's intrinsic minimum = tab bar height + page content minimum,
  which can exceed the space LCL allocated. This causes the notebook to visually
  overflow and cover sibling widgets (e.g., bottom-aligned button panels).

  Fix: patch the GtkFixedLayout class vtable so that when set_size_request was
  explicitly called (value >= 0), we allocate at that exact size instead of the
  intrinsic minimum. This matches Qt5 behavior where QWidget_resize() sets exact
  sizes without layout manager override. }
type
  TGtkLayoutManagerAllocateFunc = procedure(manager: Pointer; widget: PGtkWidget;
    width, height, baseline: gint); cdecl;

  TGtkLayoutManagerMeasureFunc = procedure(manager: Pointer; widget: PGtkWidget;
    orientation: TGtkOrientation; for_size: gint;
    minimum, natural, minimum_baseline, natural_baseline: Pgint); cdecl;

  { Partial record matching GtkLayoutManagerClass layout (from gtklayoutmanager.h).
    GObjectClass = 17 pointer-sized fields on all platforms. }
  PGtkLayoutManagerClass = ^TGtkLayoutManagerClass;
  TGtkLayoutManagerClass = record
    parent_class: array[0..16] of Pointer; { GObjectClass }
    get_request_mode: Pointer;
    measure: TGtkLayoutManagerMeasureFunc;
    allocate: TGtkLayoutManagerAllocateFunc;
  end;

var
  {%H-}OrigFixedLayoutAllocate: TGtkLayoutManagerAllocateFunc = nil;
  {%H-}OrigFixedLayoutMeasure: TGtkLayoutManagerMeasureFunc = nil;

{ Patched measure: use set_size_request values (when set) instead of intrinsic
  minimums. This prevents GtkViewport from over-allocating the GtkFixed —
  viewport allocates child at MAX(viewport_size, child_natural_size), so
  if measure reports inflated sizes, the GtkFixed becomes larger than the
  viewport, which disrupts the layout.
  For GtkFixed inside a GtkScrolledWindow (tagged 'lcl-scroll-fixed'):
  return minimum=0 to match GTK2's GtkLayout behavior. GTK2's GtkLayout
  does NOT inflate its minimum size from children's bounding boxes. The LCL
  manages scrollbar visibility through SetScrollInfo/ShowScrollBar. Without
  this, GtkFixed's bounding-box minimum causes the ScrolledWindow to show
  scrollbars that don't appear in GTK2/Qt5 (see IDE component palette). }
procedure LCLFixedLayoutMeasure(manager: Pointer; widget: PGtkWidget;
  orientation: TGtkOrientation; for_size: gint;
  minimum, natural, minimum_baseline, natural_baseline: Pgint); cdecl;
var
  Child: PGtkWidget;
  ChildInfo: Pointer;
  Transform: PGskTransform;
  ChildMin, ChildNat: gint;
  ReqW, ReqH: gint;
  MinSize, NatSize: gint;
  dx, dy: Single;
  Offset: gint;
  EffSize: gint;
begin
  { GtkFixed inside ScrolledWindow: report 0 minimum so the ScrolledWindow
    doesn't show scrollbars based on children's bounding boxes. The LCL
    handles scrollbar visibility through its own logic (SetScrollInfo). }
  if g_object_get_data(PGObject(widget), 'lcl-scroll-fixed') <> nil then
  begin
    if minimum <> nil then minimum^ := 0;
    if natural <> nil then natural^ := 0;
    if minimum_baseline <> nil then minimum_baseline^ := -1;
    if natural_baseline <> nil then natural_baseline^ := -1;
    Exit;
  end;

  MinSize := 0;
  NatSize := 0;
  Child := gtk4_widget_get_first_child(widget);
  while Child <> nil do
  begin
    if gtk4_widget_should_layout(Child) then
    begin
      ChildInfo := gtk4_layout_manager_get_layout_child(manager, Child);
      Transform := gtk4_fixed_layout_child_get_transform(ChildInfo);

      { Measure the child's intrinsic min/nat in the requested orientation }
      gtk4_widget_measure(Child, orientation, -1, @ChildMin, @ChildNat, nil, nil);

      { Read explicit set_size_request }
      gtk_widget_get_size_request(Child, @ReqW, @ReqH);

      { Use set_size_request when explicitly set (>= 0); this can be SMALLER
        than intrinsic minimum, unlike gtk_widget_measure which caps at intrinsic. }
      if orientation = GTK_ORIENTATION_HORIZONTAL then
      begin
        if ReqW >= 0 then
          EffSize := ReqW
        else
          EffSize := ChildMin;
      end else
      begin
        if ReqH >= 0 then
          EffSize := ReqH
        else
          EffSize := ChildMin;
      end;

      { Extract position offset from the child's transform (always a translation
        for GtkFixed children set via gtk_fixed_put/gtk_fixed_move) }
      Offset := 0;
      if Transform <> nil then
      begin
        dx := 0; dy := 0;
        gsk4_transform_to_translate(Transform, @dx, @dy);
        if orientation = GTK_ORIENTATION_HORIZONTAL then
          Offset := Round(dx)
        else
          Offset := Round(dy);
      end;

      {$IFDEF GTK4DEBUGFIXED}
      WriteLn(Format('  MEASURE child=[%s] ori=%d intrMin=%d intrNat=%d reqW=%d reqH=%d eff=%d off=%d total=%d',
        [g_type_name(PGTypeInstance(Child)^.g_class^.g_type), Ord(orientation),
         ChildMin, ChildNat, ReqW, ReqH, EffSize, Offset, Offset + EffSize]));
      {$ENDIF}

      MinSize := Max(MinSize, Offset + EffSize);
      NatSize := Max(NatSize, Offset + EffSize);
    end;
    Child := gtk4_widget_get_next_sibling(Child);
  end;

  {$IFDEF GTK4DEBUGFIXED}
  WriteLn(Format('LCL-MEASURE Fixed=%p ori=%d result min=%d nat=%d',
    [Pointer(widget), Ord(orientation), MinSize, NatSize]));
  {$ENDIF}

  if minimum <> nil then minimum^ := MinSize;
  if natural <> nil then natural^ := NatSize;
  if minimum_baseline <> nil then minimum_baseline^ := -1;
  if natural_baseline <> nil then natural_baseline^ := -1;
end;

{ Maximum children we track in the two-pass allocate }
const
  LCL_FIXED_MAX_CHILDREN = 64;

type
  TLCLFixedChildEntry = record
    Widget: PGtkWidget;
    Transform: PGskTransform;
    PosX, PosY: gint;
    AllocW, AllocH: gint;
    IntrW, IntrH: gint;
    Constrained: Boolean;
  end;

procedure LCLFixedLayoutAllocate(manager: Pointer; widget: PGtkWidget;
  width, height, baseline: gint); cdecl;
var
  Child: PGtkWidget;
  ChildInfo: Pointer;
  Transform: PGskTransform;
  ReqW, ReqH: gint;
  ChildReq: TGtkRequisition;
  dx, dy: Single;
  Entries: array[0..LCL_FIXED_MAX_CHILDREN-1] of TLCLFixedChildEntry;
  Count, i, j: Integer;
  SibBottom: gint;
begin
  {$IFDEF GTK4DEBUGFIXED}
  WriteLn(Format('LCL-ALLOCATE Fixed=%p container=%dx%d', [Pointer(widget), width, height]));
  {$ENDIF}

  { Pass 1: collect all children with their positions and computed sizes }
  Count := 0;
  Child := gtk4_widget_get_first_child(widget);
  while Child <> nil do
  begin
    if gtk4_widget_should_layout(Child) and (Count < LCL_FIXED_MAX_CHILDREN) then
    begin
      ChildInfo := gtk4_layout_manager_get_layout_child(manager, Child);
      Transform := gtk4_fixed_layout_child_get_transform(ChildInfo);

      gtk_widget_get_size_request(Child, @ReqW, @ReqH);
      gtk_widget_get_preferred_size(Child, @ChildReq, nil);

      Entries[Count].Widget := Child;
      Entries[Count].Transform := Transform;
      Entries[Count].IntrW := ChildReq.width;
      Entries[Count].IntrH := ChildReq.height;

      { Extract position from transform }
      dx := 0; dy := 0;
      if Transform <> nil then
        gsk4_transform_to_translate(Transform, @dx, @dy);
      Entries[Count].PosX := Round(dx);
      Entries[Count].PosY := Round(dy);

      { Use set_size_request if explicitly set, otherwise intrinsic minimum }
      if ReqW >= 0 then
        Entries[Count].AllocW := ReqW
      else
        Entries[Count].AllocW := ChildReq.width;
      if ReqH >= 0 then
        Entries[Count].AllocH := ReqH
      else
        Entries[Count].AllocH := ChildReq.height;

      Entries[Count].Constrained :=
        (Entries[Count].AllocW < ChildReq.width) or
        (Entries[Count].AllocH < ChildReq.height);

      Inc(Count);
    end;
    Child := gtk4_widget_get_next_sibling(Child);
  end;

  { Pass 2: for constrained children, clip their bottom edge so they do not
    visually overlap earlier siblings positioned below them.

    In GtkFixed, later children (higher index) are drawn ON TOP of earlier
    children. When a constrained widget (e.g. GtkNotebook allocated smaller
    than intrinsic) extends past an earlier sibling (e.g. a bottom-aligned
    panel), the constrained widget's CSS background covers the earlier
    sibling, making it invisible.

    Fix: clip the constrained child's height so its bottom does not exceed
    the top of any earlier sibling that is positioned below it and overlaps
    horizontally. This only affects constrained widgets to minimize side
    effects on normal layouts. }
  for i := 0 to Count - 1 do
  begin
    if not Entries[i].Constrained then Continue;

    SibBottom := Entries[i].PosY + Entries[i].AllocH;
    for j := 0 to i - 1 do
    begin
      { Check: is sibling j positioned below child i's top? }
      if Entries[j].PosY <= Entries[i].PosY then Continue;
      { Check: does child i extend past sibling j's top? }
      if SibBottom <= Entries[j].PosY then Continue;
      { Check: do they overlap horizontally? }
      if (Entries[i].PosX >= Entries[j].PosX + Entries[j].AllocW) or
         (Entries[j].PosX >= Entries[i].PosX + Entries[i].AllocW) then Continue;

      { Clip child i's height so it stops at sibling j's top }
      Entries[i].AllocH := Entries[j].PosY - Entries[i].PosY;
      if Entries[i].AllocH < 0 then Entries[i].AllocH := 0;
      SibBottom := Entries[i].PosY + Entries[i].AllocH;
      { Continue checking other siblings — clip to the nearest one }
    end;
  end;

  { Pass 3: allocate all children }
  for i := 0 to Count - 1 do
  begin
    {$IFDEF GTK4DEBUGFIXED}
    WriteLn(Format('  ALLOC child=[%s] intrMin=%dx%d alloc=%dx%d pos=%d,%d constrained=%s overflow=%d',
      [g_type_name(PGTypeInstance(Entries[i].Widget)^.g_class^.g_type),
       Entries[i].IntrW, Entries[i].IntrH,
       Entries[i].AllocW, Entries[i].AllocH,
       Entries[i].PosX, Entries[i].PosY,
       BoolToStr(Entries[i].Constrained, 'YES', 'no'),
       gtk4_widget_get_overflow(Entries[i].Widget)]));
    {$ENDIF}

    gtk4_widget_allocate(Entries[i].Widget, Entries[i].AllocW, Entries[i].AllocH,
      -1, gsk4_transform_ref(Entries[i].Transform));

    { Clip overflow when allocated smaller than intrinsic minimum }
    if Entries[i].Constrained then
      gtk4_widget_set_overflow(Entries[i].Widget, GTK4_OVERFLOW_HIDDEN);
  end;
end;

procedure PatchGtkFixedLayoutClass;
var
  Cls: PGtkLayoutManagerClass;
begin
  Cls := PGtkLayoutManagerClass(g_type_class_ref(gtk4_fixed_layout_get_type()));
  if Cls = nil then exit;
  OrigFixedLayoutMeasure := Cls^.measure;
  Cls^.measure := @LCLFixedLayoutMeasure;
  OrigFixedLayoutAllocate := Cls^.allocate;
  Cls^.allocate := @LCLFixedLayoutAllocate;
  { Note: intentionally do NOT call g_type_class_unref — keep the class pinned }
end;

{ ---- GtkFixed snapshot vfunc patch ----
  Root cause: GTK4 has no expose-event or draw signal. Custom painting uses a
  GtkDrawingArea overlay which renders ON TOP of child widgets in GtkFixed,
  hiding embedded editors (e.g. Object Inspector property TEdit/TComboBox).

  GTK2 solution: expose-event BEFORE signal → LCL paints first, GTK renders
  children on top.
  Qt5 solution: native scene graph composites children on top of viewport paint.

  GTK4 solution: patch GtkFixed's snapshot vfunc to inject LCL custom painting
  (via gtk_snapshot_append_cairo) BEFORE child widget rendering. This achieves
  the same paint-below-children z-order as GTK2 and Qt5. }
type
  TGtkWidgetSnapshotFunc = procedure(widget: PGtkWidget;
    snapshot: PGtkSnapshot); cdecl;

  { Partial record matching the REAL GTK4 4.6 GtkWidgetClass layout.
    GInitiallyUnownedClass = GObjectClass = 17 pointer-sized fields.
    After parent_class: 23 vfunc pointers before snapshot.
    WARNING: Do NOT use TGtkWidgetClass from lazgtk4.pas — that is GTK3. }
  PGtkWidgetClassForSnapshot = ^TGtkWidgetClassForSnapshot;
  TGtkWidgetClassForSnapshot = record
    parent_class: array[0..16] of Pointer; { GInitiallyUnownedClass: 17 fields }
    vfuncs_before_snapshot: array[0..22] of Pointer; { show..system_setting_changed }
    snapshot: TGtkWidgetSnapshotFunc; { slot 23 }
    contains: Pointer;                { slot 24 }
  end;

var
  OrigGtkFixedSnapshot: TGtkWidgetSnapshotFunc = nil;

{ Custom snapshot for GtkFixed: paint LCL content BEFORE child widgets.
  This replaces the GtkDrawingArea overlay approach, achieving GTK2/Qt5-style
  z-order where custom painting is background and child widgets render on top. }
procedure LCLGtkFixedSnapshot(widget: PGtkWidget; snapshot: PGtkSnapshot); cdecl;
var
  LCLWidget: TGtk4Widget;
  cr: Pcairo_t;
  bounds: graphene_rect_t;
  w, h: gint;
  ScrollX, ScrollY: gint;
  sw: PGtkScrolledWindow;
  adj: PGtkAdjustment;
begin
  { Only intercept GtkFixed instances associated with LCL widgets }
  LCLWidget := TGtk4Widget(g_object_get_data(widget, 'lclwidget'));
  if (LCLWidget <> nil) and LCLWidget.FHasPaint
    and Gtk4IsLiveWidgetPointer(LCLWidget) then
  begin
    { Step 1: LCL custom painting — rendered BEFORE children }
    w := gtk_widget_get_allocated_width(widget);
    h := gtk_widget_get_allocated_height(widget);
    if (w > 0) and (h > 0) then
    begin
      { GTK4 scroll compensation: When GtkFixed is inside a GtkScrolledWindow,
        GtkViewport does physical scrolling (shifts GtkFixed in the viewport).
        The LCL ALSO applies scroll offset in its own painting (software scroll).
        Without compensation, both offsets stack → double-scroll → wrong content.
        Fix: translate cairo origin by the current scroll position, undoing the
        viewport's physical scroll so only LCL's software scroll takes effect. }
      ScrollX := 0;
      ScrollY := 0;
      if g_object_get_data(PGObject(widget), 'lcl-scroll-fixed') <> nil then
      begin
        if LCLWidget is TGtk4ScrollableWin then
        begin
          sw := TGtk4ScrollableWin(LCLWidget).getScrolledWindow;
          if (sw <> nil) and Gtk4IsScrolledWindow(PGObject(sw)) then
          begin
            adj := sw^.get_hadjustment;
            if adj <> nil then
              ScrollX := Round(adj^.get_value);
            adj := sw^.get_vadjustment;
            if adj <> nil then
              ScrollY := Round(adj^.get_value);
          end;
        end;
      end;

      bounds.origin.x := 0;
      bounds.origin.y := 0;
      bounds.size.width := w;
      bounds.size.height := h;
      cr := gtk4_snapshot_append_cairo(snapshot, @bounds);
      if cr <> nil then
      begin
        try
          { Undo GtkViewport physical scroll before LCL painting }
          if (ScrollX <> 0) or (ScrollY <> 0) then
            cairo_translate(cr, Double(ScrollX), Double(ScrollY));
          { Phase 1: Regular paint — IsDesignerDC=False → grid dots painted }
          LCLWidget.GtkEventPaint(widget, cr);
          { Phase 2: Designer paint — IsDesignerDC=True → selection handles painted }
          if csDesigning in LCLWidget.LCLObject.ComponentState then
            LCLWidget.GtkEventDesignerPaint(widget, cr);
        finally
          cairo_destroy(cr);
        end;
      end;
    end;
  end;

  { Step 2: Render child widgets — ON TOP of LCL painting }
  if Assigned(OrigGtkFixedSnapshot) then
    OrigGtkFixedSnapshot(widget, snapshot);
end;

procedure PatchGtkFixedSnapshotClass;
var
  Cls: PGtkWidgetClassForSnapshot;
begin
  Cls := PGtkWidgetClassForSnapshot(g_type_class_ref(gtk_fixed_get_type()));
  if Cls = nil then exit;
  OrigGtkFixedSnapshot := Cls^.snapshot;
  Cls^.snapshot := @LCLGtkFixedSnapshot;
  { Note: intentionally do NOT call g_type_class_unref — keep the class pinned }
end;

{ GTK4: notify::width / notify::height property signals.
  NOTE: In GTK4 < 4.12, GtkWidget does NOT have these readable properties,
  so this callback never fires. Kept for forward-compatibility. }
procedure Gtk4WidgetSizeChanged(AWidget: PGObject; {%H-}pspec: PGParamSpec; Data: gpointer); cdecl;
var
  Msg: TLMSize;
  NewSize: TSize;
  ACtl: TGtk4Widget;
begin
  { NOTE: In GTK4 < 4.12, GtkWidget does NOT have 'width'/'height' readable
    properties, so notify::width / notify::height never fire. This callback
    is effectively dead on GTK4 4.6.x. The size-allocate signal (connected
    separately as Gtk4WidgetSizeAllocated) handles allocation tracking.
    This callback is kept for forward-compatibility with GTK4 >= 4.12. }
  ACtl := TGtk4Widget(Data);

  if not Assigned(ACtl.LCLObject) then exit;
  if not ACtl.CanSendLCLMessage then exit;

  { Get current widget size from GTK4 }
  NewSize.cx := PGtkWidget(AWidget)^.get_allocated_width;
  NewSize.cy := PGtkWidget(AWidget)^.get_allocated_height;

  // do not loop with LCL
  if not (csDesigning in ACtl.LCLObject.ComponentState) then
  begin
    if ACtl.InUpdate then
      exit;
  end;

  if ((NewSize.cx <> ACtl.LCLObject.Width) or (NewSize.cy <> ACtl.LCLObject.Height) or
     ACtl.LCLObject.ClientRectNeedsInterfaceUpdate) then
  begin
    ACtl.LCLObject.DoAdjustClientRectChange;
  end;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  Msg.Msg := LM_SIZE;
  { Determine window state for window-type widgets }
  if (wtWindow in ACtl.WidgetType) and Gtk4IsGtkWindow(ACtl.Widget) then
  begin
    if gtk4_window_is_fullscreen(PGtkWindow(ACtl.Widget)) then
      Msg.SizeType := SIZE_FULLSCREEN
    else if PGtkWindow(ACtl.Widget)^.is_maximized then
      Msg.SizeType := SIZE_MAXIMIZED
    else
      Msg.SizeType := SIZE_RESTORED;
  end else
    Msg.SizeType := SIZE_RESTORED;

  Msg.SizeType := Msg.SizeType or Size_SourceIsInterface;

  if ACtl.WidgetType*[wtEntry,wtComboBox,wtScrollBar,wtSpinEdit,wtHintWindow]<>[] then
  begin
    Msg.Width := ACtl.LCLObject.Width;
    Msg.Height := ACtl.LCLObject.Height;
  end else
  if ACtl.WidgetType*[wtWindow,wtDialog,wtGroupBox,
     wtScrollingWin,wtNotebook,wtContainer]<>[] then
  begin
    Msg.Width := Word(NewSize.cx);
    Msg.Height := Word(NewSize.cy);
  end else
  begin
    Msg.Width := ACtl.LCLObject.Width;
    Msg.Height := ACtl.LCLObject.Height;
  end;

  ACtl.DeliverMessage(Msg);
end;

procedure Gtk4WidgetHide({%H-}AWidget: PGtkWidget; AData: gpointer); cdecl;
var
  Msg: TLMShowWindow;
  Gtk4Widget: TGtk4Widget;
begin
  if not Gtk4IsLiveWidgetPointer(AData) then exit;
  Gtk4Widget := TGtk4Widget(AData);
  Gtk4Widget.Visible := False;
  {do not pass message to LCL if LCL setted up control visibility}
  if Gtk4Widget.inUpdate then
    exit;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := False;

  Gtk4Widget.DeliverMessage(Msg);
end;

procedure Gtk4WidgetShow({%H-}AWidget: PGtkWidget; AData: gpointer); cdecl;
var
  Msg: TLMShowWindow;
  Gtk4Widget: TGtk4Widget;
begin
  if not Gtk4IsLiveWidgetPointer(AData) then exit;
  Gtk4Widget := TGtk4Widget(AData);
  Gtk4Widget.Visible := True;
  {do not pass message to LCL if LCL setted up control visibility}
  if Gtk4Widget.inUpdate then
    exit;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  Msg.Msg := LM_SHOWWINDOW;
  Msg.Show := True;

  Gtk4Widget.DeliverMessage(Msg);
end;

{ GTK4: 'close-request' signal callback replaces 'delete-event'.
  Returns TRUE to prevent default close, FALSE to allow it. }
function Gtk4CloseRequestCB(AWidget: PGtkWindow; AData: gpointer): gboolean; cdecl;
begin
  if AWidget=nil then ;
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then
    Exit(False);
  Result := TGtk4Window(AData).Gtk4CloseQuery;
end;

function GtkModifierStateToShiftState(AState: TGdkModifierType;
    AIsKeyEvent: Boolean): Cardinal;
begin
  Result := 0;
  if GDK_SHIFT_MASK in AState  then
    Result := Result or MK_SHIFT;
  if GDK_CONTROL_MASK in AState  then
    Result := Result or MK_CONTROL;
  if GDK_MOD1_MASK in AState  then
  begin
    if AIsKeyEvent then
      Result := Result or KF_ALTDOWN
    else
      Result := Result or MK_ALT;
  end;
end;

{ TGtk4SplitterSide }

function TGtk4SplitterSide.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  { A pair-splitter side is a plain LCL child container: GtkOverlay with a
    GtkFixed for the LCL-positioned children plus the standard paint area
    (same structure as TGtk4GroupBox minus the frame). The previous side
    wrapper was TGtk4Window, which hard-casts the LCLObject to TCustomForm
    and runs window-only machinery (get_default_size etc.) against a
    non-window widget — the sides never propagated their real size and
    stayed 1x1. }
  FHasPaint := True;
  FWidgetType := [wtWidget, wtContainer];
  FDetachedRef := False;
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  FCentralWidget := TGtkFixed.new;
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);
  Result := PGtkWidget(AOverlay);
end;

{ Clear this side out of its GtkPaned slot THROUGH the paned API.
  GtkPaned does not null its start_child/end_child pointer when a child is
  unparented externally (gtkpaned.c only clears them in set_start/end_child
  and dispose), so destroying a side with plain unparent left the paned
  holding a dangling child pointer. set_*_child(nil) both unparents and
  nulls the slot; we take over the widget's last reference so the wrapper
  outlives the detach until DestroyWidget (or a re-adoption) releases it. }
procedure TGtk4SplitterSide.DetachFromPaned(APaned: PGtkPaned);
begin
  if (FWidget = nil) or (APaned = nil) then Exit;
  if FDetachedRef then Exit;
  g_object_ref(PGObject(FWidget));
  FDetachedRef := True;
  { NOTE: read the slots with gtk4_paned_get_start/end_child — the legacy
    TGtkPaned.get_child1/get_child2 binding helpers are constant-nil stubs
    (found the hard way: the slot match never fired and the paned kept
    dangling child pointers into its dispose). }
  if gtk4_paned_get_start_child(APaned) = FWidget then
    APaned^.add1(nil)  { gtk_paned_set_start_child(nil) }
  else if gtk4_paned_get_end_child(APaned) = FWidget then
    APaned^.add2(nil)  { gtk_paned_set_end_child(nil) }
  else
  begin
    { not in a slot after all — drop the ref again }
    g_object_unref(PGObject(FWidget));
    FDetachedRef := False;
  end;
end;

{ A paned slot adopted the widget again (AddSide) — the pane now holds its
  own reference, release ours. }
procedure TGtk4SplitterSide.PanedAdopted;
begin
  if FDetachedRef and (FWidget <> nil) and Gtk4IsWidget(FWidget) then
    g_object_unref(PGObject(FWidget));
  FDetachedRef := False;
end;

procedure TGtk4SplitterSide.DestroyWidget;
var
  AParent: PGtkWidget;
begin
  { If we still sit in a GtkPaned slot, clear it through the paned API
    first. This covers destruction paths that never go through the WS
    RemoveSide (e.g. RecreateWnd on SetSplitterType destroys child handles
    directly): a plain unparent leaves paned->start/end_child dangling and
    the paned's own dispose then unparents the finalized child
    (gdb-confirmed "gtk_widget_unparent: assertion GTK_IS_WIDGET failed"
    during the splitter-type recreate). }
  if (not FDetachedRef) and (FWidget <> nil) and FOwnWidget and
     Gtk4IsWidget(FWidget) then
  begin
    AParent := FWidget^.get_parent;
    if (AParent <> nil) and
       g_type_check_instance_is_a(PGTypeInstance(AParent), gtk_paned_get_type) then
      DetachFromPaned(PGtkPaned(AParent));
  end;
  { After DetachFromPaned the widget is normally parentless and we own its
    only reference — the base destroy path's unparent would be a no-op and
    the reference would leak. Release it here instead. Exception: the LCL
    allows reparenting a side to a NON-splitter container (pairsplitter.pas
    SetParent re-adds only when the new parent is a pair splitter) — then
    the widget has a new parent holding its own ref; drop just our survival
    ref and destroy through the normal unparent path so the new parent
    releases it too (codex review finding). }
  if FDetachedRef and (FWidget <> nil) and FOwnWidget and
     Gtk4IsWidget(FWidget) then
  begin
    FDetachedRef := False;
    if FWidget^.get_parent <> nil then
      g_object_unref(PGObject(FWidget))
      { fall through to inherited: unparent from the adopting container }
    else
    begin
      FOwnWidget := False;
      g_signal_handlers_disconnect_matched(PGObject(FWidget),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
      g_object_unref(PGObject(FWidget));
      FWidget := nil;
      Exit;
    end;
  end;
  inherited DestroyWidget;
end;

{ TGtk4Paned }

{ GtkPaned position changed (user drag or programmatic) — the side
  allocations settle during the following layout pass, so read them from
  an idle. }
procedure Gtk4PanedPositionNotifyCB({%H-}AObject: PGObject;
  {%H-}pspec: Pointer; AData: gPointer); cdecl;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  TGtk4Paned(AData).QueueSyncSides;
end;

function Gtk4PanedSyncIdleCB(AData: gpointer): gboolean; cdecl;
begin
  Result := G_SOURCE_REMOVE_;
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  TGtk4Paned(AData).FSyncIdleId := 0;
  TGtk4Paned(AData).SyncSideSizes;
end;

function TGtk4Paned.CreateWidget(const Params: TCreateParams): PGtkWidget;
const
  ornt:array[TPairSplitterType] of TGtkOrientation=(
    GTK_ORIENTATION_HORIZONTAL,
    GTK_ORIENTATION_VERTICAL
    );
begin
  FSyncIdleId := 0;
  Result:=TGtkPaned.new(ornt[TPairSplitter(Self.LCLObject).SplitterType]);
end;

procedure TGtk4Paned.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(FWidget, 'notify::position',
    TGCallback(@Gtk4PanedPositionNotifyCB), Self, nil, G_CONNECT_DEFAULT);
end;

procedure TGtk4Paned.DetachEvents;
begin
  if FSyncIdleId <> 0 then
  begin
    g_source_remove(FSyncIdleId);
    FSyncIdleId := 0;
  end;
  inherited DetachEvents;
end;

procedure TGtk4Paned.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  { Resizing the paned re-allocates both panes }
  QueueSyncSides;
end;

procedure TGtk4Paned.QueueSyncSides;
begin
  if FSyncIdleId <> 0 then Exit;
  FSyncIdleId := g_idle_add(@Gtk4PanedSyncIdleCB, Self);
end;

{ Feed the native pane allocations back into the LCL sides. The LCL has no
  other way to learn GtkPaned's layout: without this both sides stay at
  their 1x1 creation size, so their children never lay out and mouse
  routing into the sides is wrong. Mirrors what WM_SIZE/WM_MOVE deliver on
  win32 when a native splitter moves. }
procedure TGtk4Paned.SyncSideSizes;
var
  Splitter: TCustomPairSplitter;
  i, W, H, X, Y, PanedW, PanedH: Integer;
  SideW: TGtk4Widget;
  SizeMsg: TLMSize;
  MoveMsg: TLMMove;
  ASide: TPairSplitterSide;
begin
  if not IsWidgetOK or not CanSendLCLMessage then Exit;
  if not (LCLObject is TCustomPairSplitter) then Exit;
  Splitter := TCustomPairSplitter(LCLObject);
  PanedW := FWidget^.get_allocated_width;
  PanedH := FWidget^.get_allocated_height;
  for i := 0 to 1 do
  begin
    ASide := Splitter.Sides[i];
    if (ASide = nil) or not ASide.HandleAllocated then Continue;
    SideW := TGtk4Widget(ASide.Handle);
    if (SideW = nil) or not SideW.IsWidgetOK then Continue;
    W := SideW.Widget^.get_allocated_width;
    H := SideW.Widget^.get_allocated_height;
    if (W <= 0) or (H <= 0) then Continue;
    { Pane origins: side 0 at (0,0); side 1 fills the end, so its origin
      is the paned extent minus its own size along the split axis. }
    X := 0; Y := 0;
    if i = 1 then
    begin
      if Splitter.SplitterType = pstHorizontal then
        X := PanedW - W
      else
        Y := PanedH - H;
    end;
    if (ASide.Left <> X) or (ASide.Top <> Y) then
    begin
      FillChar(MoveMsg{%H-}, SizeOf(MoveMsg), 0);
      MoveMsg.Msg := LM_MOVE;
      MoveMsg.MoveType := Move_SourceIsInterface;
      MoveMsg.XPos := SmallInt(X);
      MoveMsg.YPos := SmallInt(Y);
      SideW.DeliverMessage(MoveMsg);
    end;
    if (ASide.Width <> W) or (ASide.Height <> H) then
    begin
      FillChar(SizeMsg{%H-}, SizeOf(SizeMsg), 0);
      SizeMsg.Msg := LM_SIZE;
      SizeMsg.SizeType := SIZE_RESTORED or Size_SourceIsInterface;
      SizeMsg.Width := Word(W);
      SizeMsg.Height := Word(H);
      SideW.DeliverMessage(SizeMsg);
    end;
  end;
end;

{ TGtk4Widget }

function TGtk4Widget.GtkEventMouseEnterLeave(Sender: PGtkWidget; Event: PGdkEvent): Boolean;
  cdecl;
var
  Msg: TLMessage;
  // MouseMsg: TLMMouseMove absolute Msg;
  {$IFDEF GTK4DEBUGCORE}
  MousePos: TPoint;
  {$ENDIF}
begin
  Result := False;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  if Event^.type_ = GDK_ENTER_NOTIFY then
    Msg.Msg := LM_MOUSEENTER
  else
    Msg.Msg := LM_MOUSELEAVE;

  { Reset motion dedup on crossing: NotifyApplicationUserInput below cancels
    the hint for non-move messages, so the first motion after (re)entry must
    always be delivered or the hint timer never restarts. }
  FLastMotionValid := False;

  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  Result := DeliverMessage(Msg, True) <> 0;
  {$IFDEF GTK4DEBUGCORE}
  MousePos.X := Round(Event^.crossing.x);
  MousePos.Y := Round(Event^.crossing.y);
  DebugLn('GtkEventMouseEnterLeave: mousePos ',dbgs(MousePos),' Object ',dbgsName(LCLObject),
    ' IsEnter ',dbgs(Event^.type_ = GDK_ENTER_NOTIFY),' Result=',dbgs(Result));
  {$ENDIF}
end;

function TGtk4Widget.GtkEventMouseMove(Sender: PGtkWidget; Event: PGdkEvent
  ): Boolean; cdecl;
var
  Msg: TLMMouseMove;
  MousePos: TPoint;
begin
  Result := False;

  {$IFDEF GTK4DEBUGEVENTS}
  R := GetClientBounds;
  DebugLn(['GtkEventMouseMove: ',dbgsName(LCLObject),' Send=',dbgs(Event^.motion.send_event),
  ' state=',dbgs(event^.motion.state),
  ' x=',dbgs(Round(event^.motion.x)),
  ' y=',dbgs(Round(event^.motion.y)),
  ' x_root=',dbgs(Round(event^.motion.x_root)),
  ' y_root=',dbgs(Round(event^.motion.y_root)),
  ' STOP PROCESSING ? ',dbgs(Event^.motion.send_event = NO_PROPAGATION_TO_PARENT),
  ' GtkBounds ',dbgs(R),' LCLBounds ',dbgs(LCLObject.BoundsRect),' W=',dbgs(LCLObject.Width)]
  );
  {$ENDIF}

  if Event^.motion.send_event = NO_PROPAGATION_TO_PARENT then
    exit;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  MousePos.x := Round(Event^.motion.x);
  MousePos.y := Round(Event^.motion.y);

  OffsetMousePos(@MousePos);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  { Per-widget dedup of duplicate motion events: skip only when position AND
    modifier/button state are unchanged (state is part of the key so that
    Msg.Keys updates are never lost).  Replaces the GTK2-era guard that
    compared Mouse.CursorPos (screen coords) against widget-local coords —
    a coordinate-space mismatch that discarded all synthetic (warped) motion
    and cost one XQueryPointer round-trip per event. }
  if FLastMotionValid and (MousePos.X = FLastMotionPos.X) and
     (MousePos.Y = FLastMotionPos.Y) and
     (Event^.motion.state = FLastMotionState) then exit;
  FLastMotionPos := MousePos;
  FLastMotionState := Event^.motion.state;
  FLastMotionValid := True;

  Msg.Keys := GdkModifierStateToLCL(Event^.motion.state, False);

  Msg.Msg := LM_MOUSEMOVE;

  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  if Widget^.get_parent <> nil then
    Event^.motion.send_event := NO_PROPAGATION_TO_PARENT;
  DeliverMessage(Msg, True);
end;

function TGtk4Widget.GtkEventPaint(Sender: PGtkWidget; AContext: Pcairo_t
  ): Boolean; cdecl;
var
  Msg: TLMPaint;
  AStruct: TPaintStruct;
  AClipRect: TGdkRectangle;
  localClip:TRect;
  cx1, cy1, cx2, cy2: double;
begin
  Result := False;

  if not FHasPaint then
    exit;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  Msg.Msg := LM_PAINT;
  FillChar(AStruct{%H-}, SizeOf(TPaintStruct), 0);
  Msg.PaintStruct := @AStruct;

  with PaintData do
  begin
    if GetContainerWidget = nil then
      PaintWidget := Widget
    else
      PaintWidget := GetContainerWidget;
    ClipRegion := nil;
    { GTK4: gdk_cairo_get_clip_rectangle removed. Use cairo_clip_extents. }
    cairo_clip_extents(AContext, @cx1, @cy1, @cx2, @cy2);
    AClipRect.x := Floor(cx1);
    AClipRect.y := Floor(cy1);
    AClipRect.width := Ceil(cx2) - AClipRect.x;
    AClipRect.height := Ceil(cy2) - AClipRect.y;
    localClip:=RectFromGdkRect(AClipRect);
    ClipRect := @localClip;
  end;

  FCairoContext := AContext;
  Msg.DC := BeginPaint(HWND(Self), AStruct);
  FContext := Msg.DC;

  Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
  Msg.PaintStruct^.hdc := FContext;

  try
    try
      DoBeforeLCLPaint;
      LCLObject.WindowProc(TLMessage(Msg));
      { Draw software caret on top of LCL content }
      if GTK4WidgetSet <> nil then
        GTK4WidgetSet.DrawCaret(AContext, Self);
    finally
      FCairoContext := nil;
      Fillchar(FPaintData, SizeOf(FPaintData), 0);
      FContext := 0;
      EndPaint(HWND(Self), AStruct);
    end;
  except
    Application.HandleException(nil);
  end;
end;

{ Phase 2 of two-phase designer painting: dispatches LM_PAINT with
  FDesignerDC set so IsDesignerDC returns True. This causes
  DoPaintDesignerItems to run (selection handles, grabbers).
  DoBeforeLCLPaint is NOT called — grid dots from Phase 1 are preserved.
  PaintControls exits early (IsDesignerDC=True → skip child painting). }
procedure TGtk4Widget.GtkEventDesignerPaint(Sender: PGtkWidget; AContext: Pcairo_t);
var
  Msg: TLMPaint;
  AStruct: TPaintStruct;
  AClipRect: TGdkRectangle;
  localClip: TRect;
  cx1, cy1, cx2, cy2: double;
begin
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_PAINT;
  FillChar(AStruct{%H-}, SizeOf(TPaintStruct), 0);
  Msg.PaintStruct := @AStruct;

  with PaintData do
  begin
    if GetContainerWidget = nil then
      PaintWidget := Widget
    else
      PaintWidget := GetContainerWidget;
    ClipRegion := nil;
    cairo_clip_extents(AContext, @cx1, @cy1, @cx2, @cy2);
    AClipRect.x := Floor(cx1);
    AClipRect.y := Floor(cy1);
    AClipRect.width := Ceil(cx2) - AClipRect.x;
    AClipRect.height := Ceil(cy2) - AClipRect.y;
    localClip := RectFromGdkRect(AClipRect);
    ClipRect := @localClip;
  end;

  FCairoContext := AContext;
  Msg.DC := BeginPaint(HWND(Self), AStruct);
  FContext := Msg.DC;
  FDesignerDC := Msg.DC;

  Msg.PaintStruct^.rcPaint := PaintData.ClipRect^;
  Msg.PaintStruct^.hdc := FContext;

  try
    try
      { No DoBeforeLCLPaint — preserve grid dots from Phase 1 }
      LCLObject.WindowProc(TLMessage(Msg));
    finally
      FDesignerDC := 0;
      FCairoContext := nil;
      FillChar(FPaintData, SizeOf(FPaintData), 0);
      FContext := 0;
      EndPaint(HWND(Self), AStruct);
    end;
  except
    Application.HandleException(nil);
  end;
end;

procedure TGtk4Widget.GtkEventFocus(Sender: PGtkWidget; Event: PGdkEvent);
  cdecl;
var
  Msg: TLMessage;
begin
  {$IF DEFINED(GTK4DEBUGEVENTS) OR DEFINED(GTK4DEBUGFOCUS)}
  DebugLn('TGtk4Widget.GtkEventFocus ',dbgsName(LCLObject),' FocusIn ',dbgs(Event^.focus_change.in_ <> 0));
  {$ENDIF}
  { GTK4: IM focus_in/focus_out is handled by GtkEventControllerKey's
    handle_crossing callback. Do NOT call FIMContext^.focus_in/focus_out/reset
    here — double-calling confuses some IM engines (fcitx5-hangul) and can
    cause premature composition commits. Only reset on actual focus-out
    when preedit is active. }
  if (FIMContext <> nil) and (Event^.focus_change.in_ = 0) and FIMPreeditActive then
  begin
    FIMContext^.reset;
    FIMPreeditActive := False;
  end;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  if Event^.focus_change.in_ <> 0 then
    Msg.Msg := LM_SETFOCUS
  else
    Msg.Msg := LM_KILLFOCUS;
  DeliverMessage(Msg);
end;

procedure TGtk4Widget.GtkEventDestroy; cdecl;
var
  Msg: TLMessage;
begin
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_DESTROY;
  DeliverMessage(Msg);
  Release;
end;

function TGtk4Widget.IsValidHandle: Boolean;
begin
  Result := Assigned(FWidget) and Gtk4IsWidget(FWidget) and not FWidget^.in_destruction;
end;

function TGtk4Widget.IsWidgetOk: Boolean;
begin
  Result := Gtk4IsWidget(FWidget);
end;

function TGtk4Widget.IsIconic: Boolean;
var
  ASurface: PGdkWindow; { GTK4: GdkWindow = GdkSurface (renamed) }
begin
  Result := False;
  if not IsWidgetOK then Exit;
  { Only toplevel windows (GtkWindow/GtkDialog) implement GtkNative. }
  if not (wtWindow in FWidgetType) and not (wtDialog in FWidgetType) then Exit;
  ASurface := gtk4_native_get_surface(FWidget);
  if ASurface = nil then Exit;
  Result := (gdk4_toplevel_get_state(ASurface) and GDK_TOPLEVEL_STATE_MINIMIZED) <> 0;
end;

function TGtk4Widget.getType: TGType;
begin
  Result := getContainerWidget^.g_type_instance.g_class^.g_type;
end;

function TGtk4Widget.getTypeName: PgChar;
begin
  Result := g_type_name(getType);
end;

procedure TGtk4Widget.lowerWidget;
var
  AParent: PGtkWidget;
begin
  if not IsWidgetOK then Exit;
  AParent := FWidget^.get_parent;
  if AParent <> nil then
    gtk4_widget_insert_before(FWidget, AParent, gtk4_widget_get_first_child(AParent));
end;

procedure TGtk4Widget.raiseWidget;
var
  AParent: PGtkWidget;
begin
  if not IsWidgetOK then Exit;
  AParent := FWidget^.get_parent;
  if AParent <> nil then
    gtk4_widget_insert_after(FWidget, AParent, gtk4_widget_get_last_child(AParent));
end;

procedure TGtk4Widget.stackUnder(AWidget: PGtkWidget);
var
  AParent: PGtkWidget;
begin
  if not IsWidgetOK or (AWidget = nil) then Exit;
  AParent := FWidget^.get_parent;
  if AParent <> nil then
    gtk4_widget_insert_before(FWidget, AParent, AWidget);
end;

function TGtk4Widget.GetCapture: TGtk4Widget;
var
  AHandle: HWND;
begin
  Result := nil;
  { GTK4: gtk_grab_get_current removed. Use our software tracking. }
  if Gtk4CapturedWidget <> nil then
  begin
    AHandle := HwndFromGtkWidget(Gtk4CapturedWidget);
    if AHandle <> 0 then
      Result := TGtk4Widget(AHandle);
  end;
end;

function TGtk4Widget.SetCapture: HWND;
var
  ASeat: PGdkSeat;
  ASurface: PGdkWindow;
  ANative: PGtkWidget;
begin
  Result := HWND(GetCapture);
  { GTK4: gtk_grab_add removed. Track capture in software. }
  Gtk4CapturedWidget := GetContainerWidget;
  { Try native pointer grab via gdk_seat_grab for robust capture }
  if not GdkGrabInit then
    InitGdkSeatGrab;
  if Assigned(GdkpSeatGrab) then
  begin
    ANative := gtk4_widget_get_native(GetContainerWidget);
    if ANative <> nil then
    begin
      ASurface := gtk4_native_get_surface(ANative);
      if ASurface <> nil then
      begin
        ASeat := gdk_display_get_default_seat(gdk_display_get_default);
        if ASeat <> nil then
          GdkpSeatGrab(ASeat, ASurface, GDK_SEAT_CAP_POINTER,
            True, nil, nil, nil, nil);
      end;
    end;
  end;
end;

function TGtk4Widget.GtkEventKey(Sender: PGtkWidget; Event: PGdkEvent; AKeyPress: Boolean): Boolean;
  cdecl;
const
  CN_KeyDownMsgs: array[Boolean] of UINT = (CN_KEYDOWN, CN_SYSKEYDOWN);
  CN_KeyUpMsgs: array[Boolean] of UINT = (CN_KEYUP, CN_SYSKEYUP);
  LM_KeyDownMsgs: array[Boolean] of UINT = (LM_KEYDOWN, LM_SYSKEYDOWN);
  LM_KeyUpMsgs: array[Boolean] of UINT = (LM_KEYUP, LM_SYSKEYUP);
  CN_CharMsg: array[Boolean] of UINT = (CN_CHAR, CN_SYSCHAR);
  LM_CharMsg: array[Boolean] of UINT = (LM_CHAR, LM_SYSCHAR);
var
  AEvent: TGdkEventKey;
  Msg: TLMKey;
  CharMsg: TLMChar;
  MsgPopup: TLMContextMenu;
  AEventString: String;
  KeyValue, ACharCode: Word;
  LCLModifiers: Word;
  IsSysKey: Boolean;
  UTF8Char: TUTF8Char;
  AChar: Char;
  IsArrowKey: Boolean;
begin
  Result := False;
  AEvent := Event^.key;
  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  AEventString := AEvent.string_;

  if gdk_keyval_is_lower(AEvent.keyval) then
    KeyValue := Word(gdk_keyval_to_upper(AEvent.keyval))
  else
    KeyValue := Word(AEvent.keyval);

  // state=16 = numlock= on.

  LCLModifiers := GtkModifierStateToShiftState(AEvent.state, True);

  if length(AEventString) = 0 then
  begin
    if KeyValue = GDK_KEY_Alt_L then
      LCLModifiers := LCLModifiers or KF_ALTDOWN
    else
    if (KeyValue = GDK_KEY_Control_L) or (KeyValue = GDK_KEY_Control_R)  then
      LCLModifiers := LCLModifiers or MK_CONTROL
    else
    if (KeyValue = GDK_KEY_Shift_L) or (KeyValue = GDK_KEY_Shift_R) then
      LCLModifiers := LCLModifiers or MK_SHIFT;
    // writeln('MODIFIERS BY KEYS ',LCLModifiers);
  end;

  IsSysKey := LCLModifiers and KF_ALTDOWN <> 0;

  { Auto-repeat detection: same key pressed without intervening release }
  if AKeyPress and (FLastKeyVal = KeyValue) and FLastKeyPress then
    LCLModifiers := LCLModifiers or KF_REPEAT;
  FLastKeyVal := KeyValue;
  FLastKeyPress := AKeyPress;

  if not AKeyPress then
    LCLModifiers := LCLModifiers or KF_UP;

  // else
  //  writeln('KeyRelease: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' hwkey=',KeyCode,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier);

  // this is just for testing purposes.
  ACharCode := GdkKeyToLCLKey(KeyValue);
  if KeyValue > VK_UNDEFINED then
    KeyValue := ACharCode; // VK_UNKNOWN;

  if AKeyPress and (ACharCode = VK_TAB) then
  begin
    if Sender^.is_focus then
    Self.LCLObject.SelectNext(Self.LCLObject,true,true);
    exit;
  end;

  IsArrowKey := (AEventString='') and ((ACharCode = VK_UP) or (ACharCode = VK_DOWN) or (ACharCode = VK_LEFT) or (ACharCode = VK_RIGHT));

  { Keyboard context menu trigger: Menu key or Shift+F10 }
  if AKeyPress and ((ACharCode = VK_APPS) or
     ((ACharCode = VK_F10) and (LCLModifiers and KF_ALTDOWN = 0) and
      (GDK_SHIFT_MASK in AEvent.state))) then
  begin
    FillChar(MsgPopup{%H-}, SizeOf(MsgPopup), 0);
    MsgPopup.Msg := LM_CONTEXTMENU;
    MsgPopup.hWnd := HWND(Self);
    MsgPopup.XPos := -1;
    MsgPopup.YPos := -1;
    if DeliverMessage(MsgPopup, True) <> 0 then
    begin
      Result := True;
      Exit;
    end;
  end;

  {$IFDEF GTK4DEBUGKEYPRESS}
  if AKeyPress then
    writeln('EVENT KeyPress: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier,
    ' KeyValue ',KeyValue,' MODIFIERS ',LCLModifiers,' CharCode ',ACharCode,' EAT ',EatArrowKeys(ACharCode))
  else
    writeln('EVENT KeyRelease: ',dbgsName(LCLObject),' Dump state=',AEvent.state,' keyvalue=',KeyValue,' modifier=',AEvent.Bitfield0.is_modifier,
    ' KeyValue ',KeyValue,' MODIFIERS ',LCLModifiers,' CharCode ',ACharCode,
    ' EAT ',EatArrowKeys(ACharCode));
  {$ENDIF}

  if (ACharCode <> VK_UNKNOWN) then
  begin
    if AKeyPress then
      Msg.Msg := CN_KeyDownMsgs[IsSysKey]
    else
      Msg.Msg := CN_KeyUpMsgs[IsSysKey];
    Msg.CharCode := ACharCode;
    Msg.KeyData := PtrInt((KeyValue shl 16) or (LCLModifiers shl 16) or $0001);

    NotifyApplicationUserInput(LCLObject, Msg.Msg);

    if not CanSendLCLMessage then
      exit;

    if (DeliverMessage(Msg, True) <> 0) or (Msg.CharCode = VK_UNKNOWN) or (IsArrowKey{EatArrowKeys(ACharCode)}) then
    begin
      {$IFDEF GTK4DEBUGKEYPRESS}
      DebugLn('CN_KeyDownMsgs handled ... exiting');
      {$ENDIF}
      if ([wtEntry,wtMemo] * WidgetType <>[]) then
      exit(false)
      else
      exit(True);
    end;

    if not CanSendLCLMessage then
      exit;

    if AKeyPress then
      Msg.Msg := LM_KeyDownMsgs[IsSysKey]
    else
      Msg.Msg := LM_KeyUpMsgs[IsSysKey];
    Msg.CharCode := ACharCode;
    Msg.KeyData := PtrInt((KeyValue shl 16) or (LCLModifiers shl 16) or $0001);

    NotifyApplicationUserInput(LCLObject, Msg.Msg);

    if not CanSendLCLMessage then
      exit;

    if ([wtListBox,wtListView,wtEntry,wtMemo] * WidgetType <> []) then
    begin
      { For native input widgets, deliver LM_KeyDown to LCL so OnKeyDown fires,
        but return False so GTK4 also handles native key behavior (selection
        change in TreeView, text input in Entry/Memo, etc.).
        Only consume the event if the LCL explicitly zeroed CharCode. }
      DeliverMessage(Msg, True);
      if not CanSendLCLMessage then exit;
      if Msg.CharCode = 0 then
        exit(True);
      { Memo WantReturns=False: consume VK_RETURN so GTK4 doesn't insert newline.
        The LCL already received LM_KEYDOWN and dialog key handling will activate
        the default button if applicable. }
      if AKeyPress and (ACharCode = VK_RETURN) and (wtMemo in WidgetType) and
        (Self is TGtk4Memo) and not TGtk4Memo(Self).WantReturns then
        exit(True);
    end
    else
    if (DeliverMessage(Msg, True) <> 0) or (Msg.CharCode = 0) then
    begin
      Result := Msg.CharCode = 0;
      {$IFDEF GTK4DEBUGKEYPRESS}
      DebugLn('LM_KeyDownMsgs handled ... exiting ',dbgs(ACharCode),' Result=',dbgs(Result),' AKeyPress=',dbgs(AKeyPress));
      {$ENDIF}
      exit;
    end;

    if not CanSendLCLMessage then
      exit;

  end;

  if AKeyPress and (length(AEventString) > 0) and
    { Do not send UTF8KeyPress for non-character control keys (F1-F12,
      Insert, Delete, Home, End, etc.) — same as Qt5. Enter/Return/Backspace
      are allowed through since they are meaningful character input. }
    not ((ACharCode >= VK_PRIOR) and (ACharCode <= VK_DOWN)) and  // PgUp..Arrow
    not ((ACharCode >= VK_INSERT) and (ACharCode <= VK_DELETE)) and // Ins, Del
    not ((ACharCode >= VK_F1) and (ACharCode <= VK_F24)) then     // F1..F24
  begin
    UTF8Char := AEventString;
    Result := LCLObject.IntfUTF8KeyPress(UTF8Char, 1, IsSysKey);

    if not CanSendLCLMessage then
      exit;

    if Result then
    begin
      {$IFDEF GTK4DEBUGKEYPRESS}
      DebugLn('LCLObject.IntfUTF8KeyPress handled ... exiting');
      {$ENDIF}
      exit;
    end;

    // create the CN_CHAR / CN_SYSCHAR message
    FillChar(CharMsg{%H-}, SizeOf(CharMsg), 0);
    CharMsg.Msg := CN_CharMsg[IsSysKey];
    CharMsg.KeyData := Msg.KeyData;
    AChar := AEventString[1];
    CharMsg.CharCode := Word(AChar);
    NotifyApplicationUserInput(LCLObject, CharMsg.Msg);

    if not CanSendLCLMessage then
      exit;

    Result := (DeliverMessage(CharMsg, True) <> 0) or (CharMsg.CharCode = VK_UNKNOWN);

    if not CanSendLCLMessage then
      exit;

    if Result then
    begin
      {$IFDEF GTK4DEBUGKEYPRESS}
      DebugLn('CN_CharMsg handled ... exiting');
      {$ENDIF}
      exit;
    end;

    //Send a LM_(SYS)CHAR
    CharMsg.Msg := LM_CharMsg[IsSysKey];

    NotifyApplicationUserInput(LCLObject, CharMsg.Msg);

    if not CanSendLCLMessage then
      exit;

    DeliverMessage(CharMsg, True);

    if not CanSendLCLMessage then
      exit;

    { Memo: this bubble delivery runs BEFORE the GtkTextView inserts the key
      (empirically verified), and an OnKeyPress handler may have REPLACED the
      character (DoKeyPress writes the changed char back into CharCode). The
      view will still insert the ORIGINAL key, so record the replacement for
      the memo's buffer insert-text handler to apply. Enter maps #13 <-> the
      "\n" the buffer actually inserts. Consumption needs nothing here (a
      consumed char already exited above, claiming the event). }
    if (wtMemo in WidgetType) and (Self is TGtk4Memo)
       and (CharMsg.CharCode <> VK_UNKNOWN)
       and (Char(CharMsg.CharCode) <> AChar) then
    begin
      if AChar = #13 then
        TGtk4Memo(Self).FBubbleReplaceFrom := #10
      else
        TGtk4Memo(Self).FBubbleReplaceFrom := AChar;
      if Char(CharMsg.CharCode) = #13 then
        TGtk4Memo(Self).FBubbleReplaceTo := #10
      else
        TGtk4Memo(Self).FBubbleReplaceTo := Char(CharMsg.CharCode);
      TGtk4Memo(Self).FBubbleReplacePending := True;
    end;
  end;
  if AKeyPress then
  begin
    {$IFDEF GTK4DEBUGKEYPRESS}
    if Msg.CharCode in FKeysToEat then
    begin
      DebugLn('EVENT: ******* KeyPress charcode is in keys to eat (FKeysToEat), charcode=',dbgs(Msg.CharCode));
    end;
    {$ENDIF}
    Result := Msg.CharCode in FKeysToEat;
  end;
end;

function TGtk4Widget.GtkEventMouse(Sender: PGtkWidget; Event: PGdkEvent): Boolean;
  cdecl;
var
  Msg: TLMMouse;
  MsgPopup : TLMMouse;
  MousePos: TPoint;
  MButton: guint;
  PopupPos: TPoint;
  PopupToplevel: PGtkWidget;
  PopupOrigX, PopupOrigY: LongInt;
  PopupSurfX, PopupSurfY: Double;
begin
  Result := False;
  {$IF DEFINED(GTK4DEBUGEVENTS) OR DEFINED(GTK4DEBUGMOUSE)}
  DebugLn('TGtk4Widget.GtkEventMouse ',dbgsName(LCLObject),
    ' propagate=',dbgs(not (Event^.button.send_event = NO_PROPAGATION_TO_PARENT)));
  {$ENDIF}
  if Event^.button.send_event = NO_PROPAGATION_TO_PARENT then
    exit;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);

  MousePos.x := Round(Event^.button.x);
  MousePos.y := Round(Event^.button.y);

  Msg.Keys := GdkModifierStateToLCL(Event^.button.state, False);

  Msg.XPos := SmallInt(MousePos.X);
  Msg.YPos := SmallInt(MousePos.Y);

  MButton := Event^.button.button;

  case Event^.type_ of
  GDK_BUTTON_PRESS:
    begin
      if MButton = GTK4_LEFT_BUTTON then
      begin
        Msg.Msg := LM_LBUTTONDOWN;
        Msg.Keys := Msg.Keys or MK_LBUTTON;
      end
      else
      if MButton = GTK4_RIGHT_BUTTON then
      begin
        Msg.Msg := LM_RBUTTONDOWN;
        Msg.Keys := Msg.Keys or MK_RBUTTON;
      end
      else
      if MButton = GTK4_MIDDLE_BUTTON then
      begin
        Msg.Msg := LM_MBUTTONDOWN;
        Msg.Keys := Msg.Keys or MK_MBUTTON;
      end
      else
      if MButton = GTK4_XBUTTON1 then
      begin
        Msg.Msg := LM_XBUTTONDOWN;
        Msg.Keys := Msg.Keys or MK_XBUTTON1;
      end
      else
      if MButton = GTK4_XBUTTON2 then
      begin
        Msg.Msg := LM_XBUTTONDOWN;
        Msg.Keys := Msg.Keys or MK_XBUTTON2;
      end;
    end;
  GDK_2BUTTON_PRESS: //-> double click GDK_DOUBLE_BUTTON_PRESS
    begin
      if MButton = GTK4_LEFT_BUTTON then
      begin
        Msg.Msg := LM_LBUTTONDBLCLK;
        Msg.Keys := Msg.Keys or MK_LBUTTON;
      end
      else
      if MButton = GTK4_RIGHT_BUTTON then
      begin
        Msg.Msg := LM_RBUTTONDBLCLK;
        Msg.Keys := Msg.Keys or MK_RBUTTON;
      end
      else
      if MButton = GTK4_MIDDLE_BUTTON then
      begin
        Msg.Msg := LM_MBUTTONDBLCLK;
        Msg.Keys := Msg.Keys or MK_MBUTTON;
      end
      else
      if MButton = GTK4_XBUTTON1 then
      begin
        Msg.Msg := LM_XBUTTONDBLCLK;
        Msg.Keys := Msg.Keys or MK_XBUTTON1;
      end
      else
      if MButton = GTK4_XBUTTON2 then
      begin
        Msg.Msg := LM_XBUTTONDBLCLK;
        Msg.Keys := Msg.Keys or MK_XBUTTON2;
      end;
    end;
  GDK_BUTTON_RELEASE:
    begin
      if MButton = GTK4_LEFT_BUTTON then
      begin
        Msg.Msg := LM_LBUTTONUP;
        Msg.Keys := Msg.Keys or MK_LBUTTON;
      end
      else
      if MButton = GTK4_RIGHT_BUTTON then
      begin
        Msg.Msg := LM_RBUTTONUP;
        Msg.Keys := Msg.Keys or MK_RBUTTON;
      end
      else
      if MButton = GTK4_MIDDLE_BUTTON then
      begin
        Msg.Msg := LM_MBUTTONUP;
        Msg.Keys := Msg.Keys or MK_MBUTTON;
      end
      else
      if MButton = GTK4_XBUTTON1 then
      begin
        Msg.Msg := LM_XBUTTONUP;
        Msg.Keys := Msg.Keys or MK_XBUTTON1;
      end
      else
      if MButton = GTK4_XBUTTON2 then
      begin
        Msg.Msg := LM_XBUTTONUP;
        Msg.Keys := Msg.Keys or MK_XBUTTON2;
      end;
    end;
  end;

  {$IF DEFINED(GTK4DEBUGEVENTS) OR DEFINED(GTK4DEBUGMOUSE)}
  DebugLn('TGtk4Widget.GtkEventMouse ',dbgsName(LCLObject),
    ' msg=',dbgs(msg.Msg), ' point=',dbgs(Msg.XPos),',',dbgs(Msg.YPos));
  {$ENDIF}
  NotifyApplicationUserInput(LCLObject, Msg.Msg);
  Event^.button.send_event := NO_PROPAGATION_TO_PARENT;

  Result := DeliverMessage(Msg, True) <> 0;
  { The LM_*DOWN/*UP delivery above runs user code that may free this wrapper
    (e.g. a windowed control freed from its own OnClick — the release path
    below would then run LM_CONTEXTMENU/LM_CLICKED against a dangling Self).
    The live-widget registry outlives us, so a pointer-value check is safe. }
  if not Gtk4IsLiveWidgetPointer(Pointer(Self)) then
    Exit;
  if Event^.type_ = GDK_BUTTON_RELEASE then
  begin
    { WM semantics (win32, and what SynEdit expects): the button DOWN and UP
      are always delivered, and LM_CONTEXTMENU follows AFTER the right
      button release.  Sending it before/instead of RBUTTONDOWN starves
      controls that open their menu from a mouse action (SynEdit's
      emcContextMenu is bound to right-button cdUp) and their duplicate
      guard (FInMouseClickEvent in DoContextPopup) then suppresses the
      generic TControl.WMContextMenu fallback as well. }
    if Msg.Msg = LM_RBUTTONUP then
    begin
      MsgPopup := Msg;
      MsgPopup.Msg := LM_CONTEXTMENU;
      { LM_CONTEXTMENU carries SCREEN coordinates (TControl.WMContextMenu
        does ScreenToClient on them).  The synthesized x_root/y_root are
        only window-CONTENT-relative in this backend — add the toplevel's
        screen origin (no-op fallback on Wayland). }
      PopupPos := Point(Round(Event^.button.x_root), Round(Event^.button.y_root));
      PopupToplevel := FWidget;
      while gtk_widget_get_parent(PopupToplevel) <> nil do
        PopupToplevel := gtk_widget_get_parent(PopupToplevel);
      if Gtk4X11GetWindowOrigin(PopupToplevel, PopupOrigX, PopupOrigY) then
      begin
        PopupSurfX := 0;
        PopupSurfY := 0;
        gtk4_native_get_surface_transform(PopupToplevel, @PopupSurfX, @PopupSurfY);
        Inc(PopupPos.X, PopupOrigX + Round(PopupSurfX));
        Inc(PopupPos.Y, PopupOrigY + Round(PopupSurfY));
      end;
      MsgPopup.XPos := SmallInt(PopupPos.X);
      MsgPopup.YPos := SmallInt(PopupPos.Y);
      Result := DeliverMessage(MsgPopup, True) <> 0;
    end;
    Msg.Msg := LM_CLICKED;
    DeliverMessage(Msg, True);
  end;
end;

function TGtk4Widget.GetVisible: Boolean;
begin
  { Avoid querying gtk_widget_get_visible on potentially stale widget pointers.
    Keep visibility state from show/hide/SetVisible transitions. }
  Result := Assigned(FWidget) and FVisibleState;
end;

procedure TGtk4Widget.SetEnabled(AValue: Boolean);
begin
  if IsWidgetOK then
    FWidget^.set_sensitive(AValue);
end;

procedure TGtk4Widget.ApplyWidgetCss(const ACss: String);

  { GTK4: gtk_style_context_add_provider is per-widget only — CSS does NOT
    cascade to child widgets (e.g., GtkEntry's internal GtkText).
    Recursively add the same provider to all descendants so font/color
    settings propagate to internal child widgets. }
  procedure AddProviderToChildren(AWidget: PGtkWidget; AProvider: PGtkStyleProvider);
  var
    Child: PGtkWidget;
    ChildCtx: PGtkStyleContext;
  begin
    Child := gtk4_widget_get_first_child(AWidget);
    while Child <> nil do
    begin
      ChildCtx := Child^.get_style_context;
      if ChildCtx <> nil then
        ChildCtx^.add_provider(AProvider, GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
      AddProviderToChildren(Child, AProvider);
      Child := gtk4_widget_get_next_sibling(Child);
    end;
  end;

var
  AContext: PGtkStyleContext;
  CssData: String;
  ContainerWidget: PGtkWidget;
begin
  if not IsWidgetOK then Exit;
  ContainerWidget := GetContainerWidget;
  AContext := ContainerWidget^.get_style_context;
  if AContext = nil then Exit;
  if FWidgetCssProvider = nil then
  begin
    FWidgetCssProvider := gtk_css_provider_new;
    AContext^.add_provider(PGtkStyleProvider(FWidgetCssProvider),
      GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    { Propagate to all current children (e.g., GtkEntry → GtkText) }
    AddProviderToChildren(ContainerWidget, PGtkStyleProvider(FWidgetCssProvider));
  end;
  if ACss = '' then
    CssData := '* {}'
  else
    CssData := ACss;
  gtk_css_provider_load_from_data(FWidgetCssProvider, PgChar(CssData), -1, nil);
end;

procedure TGtk4Widget.SetFont(AValue: PPangoFontDescription);
var
  AFamily: Pgchar;
  ASize: gint;
  AWeight: TPangoWeight;
  AStyle: TPangoStyle;
  ASizePt: Double;
begin
  if AValue = nil then Exit;
  AFamily := pango_font_description_get_family(AValue);
  ASize := pango_font_description_get_size(AValue);
  AWeight := pango_font_description_get_weight(AValue);
  AStyle := pango_font_description_get_style(AValue);

  if ASize > 0 then
    ASizePt := ASize / PANGO_SCALE
  else
    ASizePt := 10;

  FWidgetCssFont := '';
  if AFamily <> nil then
    FWidgetCssFont := FWidgetCssFont + 'font-family: "' + String(AFamily) + '"; ';
  { GTK4: pango_context_get_font_description returns absolute (pixel) sizes
    for entry/combo widgets (CSS-resolved), but point sizes for others.
    Use 'px' for absolute sizes, 'pt' for point sizes in the CSS output. }
  if pango_font_description_get_size_is_absolute(AValue) then
    FWidgetCssFont := FWidgetCssFont + Format('font-size: %.1fpx; ', [ASizePt])
  else
    FWidgetCssFont := FWidgetCssFont + Format('font-size: %.1fpt; ', [ASizePt]);
  if AWeight >= PANGO_WEIGHT_BOLD then
    FWidgetCssFont := FWidgetCssFont + 'font-weight: bold; '
  else
    FWidgetCssFont := FWidgetCssFont + 'font-weight: normal; ';
  if AStyle = PANGO_STYLE_ITALIC then
    FWidgetCssFont := FWidgetCssFont + 'font-style: italic; '
  else if AStyle = PANGO_STYLE_OBLIQUE then
    FWidgetCssFont := FWidgetCssFont + 'font-style: oblique; '
  else
    FWidgetCssFont := FWidgetCssFont + 'font-style: normal; ';

  ApplyWidgetCss('* { ' + FWidgetCssFont + FWidgetCssFgColor + FWidgetCssBgColor + FWidgetCssBorder + '}');
end;

procedure TGtk4Widget.SetFontColor(AValue: TColor);
var
  R, G, B: Byte;
begin
  if AValue = clDefault then
    FWidgetCssFgColor := ''
  else begin
    AValue := ColorToRGB(AValue);
    R := AValue and $FF;
    G := (AValue shr 8) and $FF;
    B := (AValue shr 16) and $FF;
    FWidgetCssFgColor := Format('color: rgb(%d,%d,%d); ', [R, G, B]);
  end;
  ApplyWidgetCss('* { ' + FWidgetCssFont + FWidgetCssFgColor + FWidgetCssBgColor + FWidgetCssBorder + '}');
end;

procedure TGtk4Widget.SetColor(AValue: TColor);
var
  R, G, B: Byte;
begin
  if AValue = clDefault then
    FWidgetCssBgColor := ''
  else begin
    AValue := ColorToRGB(AValue);
    R := AValue and $FF;
    G := (AValue shr 8) and $FF;
    B := (AValue shr 16) and $FF;
    FWidgetCssBgColor := Format('background-color: rgb(%d,%d,%d); ', [R, G, B]);
  end;
  ApplyWidgetCss('* { ' + FWidgetCssFont + FWidgetCssFgColor + FWidgetCssBgColor + FWidgetCssBorder + '}');
end;

procedure TGtk4Widget.SetBorderStyle(AValue: TBorderStyle);
begin
  case AValue of
    bsSingle:
      FWidgetCssBorder := 'border: 1px solid; ';
    bsNone:
      FWidgetCssBorder := 'border: none; ';
  else
    FWidgetCssBorder := '';
  end;
  ApplyWidgetCss('* { ' + FWidgetCssFont + FWidgetCssFgColor + FWidgetCssBgColor + FWidgetCssBorder + '}');
end;

function TGtk4Widget.GetStyleContext: PGtkStyleContext;
begin
  Result := nil;
  if IsWidgetOK then
    Result := GetContainerWidget^.get_style_context;
end;

function TGtk4Widget.GetFont: PPangoFontDescription;
var
  AContext: PPangoContext;
begin
  Result := nil;
  if IsWidgetOK then
  begin
    AContext := GetContainerWidget^.get_pango_context;
    Result := pango_context_get_font_description(AContext);
  end;
end;

function TGtk4Widget.CanSendLCLMessage: Boolean;
begin
  { Avoid calling Gtk type checks from late callbacks during teardown.
    A live wrapper + non-nil widget/object is sufficient for message gating. }
  Result := Gtk4IsLiveWidgetPointer(Self) and (FWidget <> nil) and (LCLObject <> nil);
end;

function TGtk4Widget.GetCairoContext: Pcairo_t;
begin
  Result := FCairoContext;
end;

function TGtk4Widget.GetEnabled: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := FWidget^.get_sensitive;
end;

function TGtk4Widget.GetFontColor: TColor;
var
  AStyle: PGtkStyleContext;
  AGdkRGBA: TGdkRGBA;
begin
  Result := clDefault;
  { GTK4: get_background_color removed. Return white as default. }
  if IsWidgetOK then
  begin
    AStyle := GetStyleContext;
    if AStyle=nil then ;
    AGdkRGBA.red := 1.0; AGdkRGBA.green := 1.0; AGdkRGBA.blue := 1.0; AGdkRGBA.alpha := 1.0;
    Result := TGdkRGBAToTColor(AGdkRGBA);
  end;
end;

function TGtk4Widget.GetColor: TColor;
var
  AStyle: PGtkStyleContext;
  AColor: TGdkRGBA;
begin
  Result := clDefault;
  { GTK4: get_background_color removed. Return white as default. }
  if IsWidgetOK then
  begin
    AStyle := GetStyleContext;
    if AStyle=nil then ;
    AColor.red := 1.0; AColor.green := 1.0; AColor.blue := 1.0; AColor.alpha := 1.0;
    Result := TGdkRGBAToTColor(AColor);
  end;
end;

procedure TGtk4Widget.SetStyleContext(AValue: PGtkStyleContext);
begin
  { GTK4: gtk_widget_set_style() was removed. Style is controlled via
    CSS classes and providers. This setter is intentionally a no-op. }
end;

class procedure TGtk4Widget.destroy_event(widget: PGtkWidget; data: gpointer); cdecl;
var
  AObj: TGtk4Widget;
begin
  { During application teardown, GTK can emit destroy notifications after LCL
    wrapper finalization. Only touch callback data while the wrapper is still
    tracked as a live object, and only for its own widget instance. }
  if Gtk4IsLiveWidgetPointer(data) then
  begin
    AObj := TGtk4Widget(data);
    if AObj.FWidget = widget then
    begin
      AObj.FVisibleState := False;
      AObj.FWidget := nil;
    end;
  end;
  { Avoid touching object data on teardown: GTK may emit destroy notifications
    after wrapper/object lifetimes diverge, which can trigger G_IS_OBJECT
    criticals in shutdown paths. }
  if widget <> nil then ;
end;

function TGtk4Widget.getText: String;
begin
  Result := fText; // default text storage
end;

procedure TGtk4Widget.setText(const AValue: String);
begin
  fText:=AValue;
end;

procedure TGtk4Widget.SetVisible(AValue: Boolean);
begin
  FVisibleState := AValue;
  if IsWidgetOK then
    FWidget^.set_visible(AValue);
end;

function TGtk4Widget.QueryInterface(constref iid: TGuid; out obj): LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
begin
  if GetInterface(iid, obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TGtk4Widget._AddRef: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
begin
  Result := -1; // no ref counting
end;

function TGtk4Widget._Release: LongInt; {$IFDEF WINDOWS}stdcall{$ELSE}cdecl{$ENDIF};
begin
  Result := -1;
end;

function TGtk4Widget.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_LEFT, VK_UP, VK_RIGHT, VK_DOWN];
end;

function TGtk4Widget.GetContext: HDC;
begin
  Result := FContext;
end;

function TGtk4Widget.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkWidget.newv(32, 0 ,nil));
end;

function TGtk4Widget.GetWidget:PGtkWidget;
begin
  if not Assigned(fWidget) then
    Self.InitializeWidget;
  Result:=fWidget;
end;

procedure Gtk4SilentLogHandler({%H-}log_domain: Pgchar;
  {%H-}log_level: TGLogLevelFlags; {%H-}message_: Pgchar;
  {%H-}user_data: gpointer); cdecl;
begin
  { Suppress GLib/GTK CRITICAL messages during gtk_window_destroy cascade.
    The GTK4 dispose cascade can trigger g_object_unref/g_signal_handler_disconnect
    on already-finalized sibling GObjects — cosmetic and harmless. }
end;

procedure TGtk4Widget.DestroyWidget;
var
  OldHandler: TGLogFunc;
begin
  if (FWidget <> nil) and FOwnWidget then
  begin
    fOwnWidget:=false;
    { Validate with Gtk4IsWidget: during shutdown the GObject may already be
      finalized (NULL class pointer) — matches GTK2 GTK_IS_OBJECT pattern. }
    if Gtk4IsWidget(FWidget) then
    begin
      g_signal_handlers_disconnect_matched(PGObject(FWidget),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
      { GTK4: gtk_widget_destroy was removed.
        Toplevel windows must use gtk_window_destroy.
        Non-toplevel widgets use gtk_widget_unparent. }
      if Gtk4IsGtkWindow(PGObject(FWidget)) then
      begin
        { Suppress GLib CRITICAL messages during the brief gtk_window_destroy.
          The dispose cascade may g_object_unref/g_signal_handler_disconnect
          on already-finalized sibling GObjects — cosmetic, not real errors. }
        OldHandler := g_log_set_default_handler(@Gtk4SilentLogHandler, nil);
        try
          gtk4_window_destroy(PGtkWindow(FWidget));
        finally
          g_log_set_default_handler(OldHandler, nil);
        end;
      end
      else
        FWidget^.destroy_;
    end;
  end;
  FWidget := nil;
end;

procedure TGtk4Widget.DoBeforeLCLPaint;
begin
  //
end;

constructor TGtk4Widget.Create(const AWinControl: TWinControl;
  const AParams: TCreateParams);
begin
  inherited Create;

  FContext := 0;
  FHasPaint := False;
  FVisibleState := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := True;

  FProps := nil;
  LCLObject := AWinControl;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];

  FParams := AParams;
  Gtk4RegisterLiveWidget(Self);
  InitializeWidget;
end;

constructor TGtk4Widget.CreateFrom(const AWinControl: TWinControl;
  AWidget: PGtkWidget);
begin
  inherited Create;
  FContext := 0;
  FHasPaint := False;
  FVisibleState := False;
  FWidget := nil;
  FOwner := nil;
  FCentralWidget := nil;
  FOwnWidget := False;

  FProps := nil;
  LCLObject := AWinControl;
  FWidget := AWidget;
  FVisibleState := AWidget <> nil;
  Gtk4RegisterLiveWidget(Self);
  if FWidget <> nil then
    g_signal_connect_data(FWidget, 'destroy', TGCallback(@TGtk4Widget.destroy_event), Self, nil, G_CONNECT_DEFAULT);
  // FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
end;

procedure TGtk4Widget.InitializeWidget;
var
  ARect: TGdkRectangle;
  i: TGtkStateType;
  AController: PGtkEventController;
begin
  FFocusableByMouse := False;
  FCentralWidget := nil;
  FCairoContext := nil;
  FContext := 0;
  FEnterLeaveTime := 0;

  FWidgetType := [wtWidget];
  FWidget := CreateWidget(FParams);
  FVisibleState := FWidget <> nil;

  if not (wtWindow in FWidgetType) then
  begin
    { GTK4: show_all removed. Use show (children are visible by default in GTK4). }
    FWidget^.show;
    { A handle can be created for a control that must stay invisible —
      TRadioGroup calls HandleNeeded on its Visible=False HiddenRadioButton,
      and LCL sends no ShowHide for a control whose showing state never
      changes. GTK4 widgets default to visible, so without this the hidden
      helper painted over the first radio item (runtime-measured). Only the
      control's OWN visible flag matters here (IsControlVisible) — the
      parent-chain check (HandleObjectShouldBeVisible) is False for every
      child created before the form is shown and hiding those caused
      0-size gtk_widget_measure criticals during the pre-show layout. }
    if Assigned(LCLObject) and not LCLObject.IsControlVisible then
    begin
      FWidget^.hide;
      FVisibleState := False;
    end;
    with ARect do
    begin
      x := LCLObject.Left;
      y := LCLObject.Top;
      width := LCLObject.Width;
      height := LCLObject.Height;
    end;
    FWidget^.set_size_request(ARect.width, ARect.height);

    UpdateWidgetConstraints;
  end;
  LCLIntf.SetProp(HWND(Self),'lclwidget',Self);

  { GTK4: set_events removed (events are implicit). 'event' signal removed.
    get_background_color removed. 'draw' and 'scroll-event' signals removed.
    Event controllers replace signal-based event handling. }

  g_signal_connect_data(FWidget, 'destroy', TGCallback(@TGtk4Widget.destroy_event), Self, nil, G_CONNECT_DEFAULT);

  { Initialize RGBA arrays to sensible defaults (get_background_color removed in GTK4) }
  for i := GTK_STATE_NORMAL to GTK_STATE_INSENSITIVE do
  begin
    with FWidgetRGBA[i] do
    begin
      R := 1.0; G := 1.0; B := 1.0; Alpha := 1.0;
    end;
    FCentralWidgetRGBA[i] := FWidgetRGBA[i];
  end;

  g_signal_connect_data(FWidget,'hide', TGCallback(@Gtk4WidgetHide), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(FWidget,'show', TGCallback(@Gtk4WidgetShow), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(FWidget,'map', TGCallback(@Gtk4MapWidget), Self, nil, G_CONNECT_DEFAULT);
  { notify::width/height: only works in GTK4 >= 4.12, kept for forward compat }
  g_signal_connect_data(FWidget, 'notify::width', TGCallback(@Gtk4WidgetSizeChanged), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(FWidget, 'notify::height', TGCallback(@Gtk4WidgetSizeChanged), Self, nil, G_CONNECT_DEFAULT);

  { GTK4 Event Controllers — replace the old 'event' signal }

  { Key events — attached to GetContainerWidget (the focus target).
    GTK2 connects key-press-event to the inner Client widget (GtkFixed),
    not the outer GtkScrolledWindow.  GTK4 must do the same: if the key
    controller sits on GtkScrolledWindow while focus is on a descendant
    GtkFixed, GtkScrolledWindow's built-in shortcut controller runs first
    and steals navigation keys.  Also, GtkEventControllerKey.handle_crossing
    only sets is_focus=True when new_target equals the controller's widget,
    so IM focus_in is never called when the controller is on a parent. }
  { Design-mode key interception — CAPTURE phase, fires before native
    GtkEntry/GtkText editing. No-op at runtime (see Gtk4DesignKeyPressedCB).
    For toplevel forms the controller goes on the WINDOW widget, not the
    inner GtkFixed: GTK4 dispatches keys along root->focus-widget only,
    and after selecting a component the focus widget is the form's
    GtkScrolledWindow — an ANCESTOR of the fixed — so a fixed-attached
    controller never sees the key (Del could not delete components).
    On the window it is the outermost capture controller and consumes
    design keys once, before any per-child design controller. }
  AController := gtk4_event_controller_key_new;
  gtk_event_controller_set_propagation_phase(AController, GTK_PHASE_CAPTURE);
  g_signal_connect_data(AController, 'key-pressed', TGCallback(@Gtk4DesignKeyPressedCB), Self, nil, G_CONNECT_DEFAULT);
  if wtWindow in FWidgetType then
    gtk4_widget_add_controller(FWidget, AController)
  else
    gtk4_widget_add_controller(GetContainerWidget, AController);

  AController := gtk4_event_controller_key_new;
  g_signal_connect_data(AController, 'key-pressed', TGCallback(@Gtk4KeyPressedCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AController, 'key-released', TGCallback(@Gtk4KeyReleasedCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AController, 'im-update', TGCallback(@Gtk4IMUpdateCB), Self, nil, G_CONNECT_DEFAULT);
  { IME: Connect input method context for non-native-text widgets.
    GtkEntry/GtkTextView have their own built-in IMContext. }
  if FWidgetType * [wtEntry, wtMemo] = [] then
  begin
    FIMContext := PGtkIMContext(gtk_im_multicontext_new);
    if FIMContext <> nil then
    begin
      PGtkEventControllerKey(AController)^.set_im_context(FIMContext);
      g_signal_connect_data(FIMContext, 'commit',
        TGCallback(@Gtk4IMCommitCB), Self, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(FIMContext, 'preedit-start',
        TGCallback(@Gtk4IMPreeditStartCB), Self, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(FIMContext, 'preedit-end',
        TGCallback(@Gtk4IMPreeditEndCB), Self, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(FIMContext, 'preedit-changed',
        TGCallback(@Gtk4IMPreeditChangedCB), Self, nil, G_CONNECT_DEFAULT);
    end;
  end;
  gtk4_widget_add_controller(GetContainerWidget, AController);

  { Set client_widget on the IM context. Called here (early) for immediate
    setup, and again in Gtk4MapWidget (deferred) when widget is realized.
    GtkIMMulticontext checks client_widget==widget and returns early on
    duplicate calls. Without client_widget, the delegate IM (ibus/fcitx5)
    operates in degraded mode — Korean Hangul composition fails. }
  if FIMContext <> nil then
    gtk4_im_context_set_client_widget(FIMContext, GetContainerWidget);

  { A form with NO focusable control keeps focus on the window/scrolled-window,
    which are not descendants of the GtkFixed above, so the container key
    controller never dispatches and Form.OnKeyDown/KeyPreview was lost. Add a
    second, bare controller on the WINDOW for that case; when a child control
    has focus, the Gtk4FormKeyBelongsToChild guard inside the callbacks
    suppresses this controller's bubbled duplicate. NOTE: this is an ADDITIONAL
    controller with no IM context — RELOCATING the container controller (which
    carries the IM context) to the window was tried and caused hangs on
    control-less forms; do not retry that. }
  if wtWindow in FWidgetType then
  begin
    AController := gtk4_event_controller_key_new;
    g_signal_connect_data(AController, 'key-pressed', TGCallback(@Gtk4KeyPressedCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(AController, 'key-released', TGCallback(@Gtk4KeyReleasedCB), Self, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(FWidget, AController);
  end;

  { Legacy event controller for mouse events (click, motion, enter/leave).
    Handles all mouse-related events via the opaque GdkEvent accessors.
    GestureClick doesn't work reliably on GtkWindow with child widgets. }
  AController := gtk4_event_controller_legacy_new;
  gtk_event_controller_set_propagation_phase(AController, GTK_PHASE_CAPTURE);
  g_signal_connect_data(AController, 'event', TGCallback(@Gtk4LegacyEventCB), Self, nil, G_CONNECT_DEFAULT);
  gtk4_widget_add_controller(FWidget, AController);

  { Focus — on GetContainerWidget, matching the key controller.
    For widgets with FCentralWidget (e.g. TGtk4CustomControl backed by
    GtkScrolledWindow), focus enter/leave must track the inner content
    widget, not the outer scroll container. }
  AController := gtk4_event_controller_focus_new;
  g_signal_connect_data(AController, 'enter', TGCallback(@Gtk4FocusEnterCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AController, 'leave', TGCallback(@Gtk4FocusLeaveCB), Self, nil, G_CONNECT_DEFAULT);
  gtk4_widget_add_controller(GetContainerWidget, AController);

  { Scroll — on container widget (both vertical and horizontal) }
  AController := gtk4_event_controller_scroll_new(
    [GTK_EVENT_CONTROLLER_SCROLL_VERTICAL, GTK_EVENT_CONTROLLER_SCROLL_HORIZONTAL,
     GTK_EVENT_CONTROLLER_SCROLL_DISCRETE]);
  g_signal_connect_data(AController, 'scroll', TGCallback(@Gtk4ScrollCB), Self, nil, G_CONNECT_DEFAULT);
  gtk4_widget_add_controller(GetContainerWidget, AController);
end;


procedure TGtk4Widget.UpdateWidgetConstraints;
var mh,nh,mw,nw:gint;
    oldW, oldH: gint;
begin
  // some GTK4 widgets may report unacceptable for LCL values
  // i.e. GtkEntry have 152px minimal and natural width
  // this has to be handled in specific classes
  { GTK4: get_preferred_width/height removed. Use gtk_widget_measure instead.
    Temporarily clear size_request so gtk_widget_measure returns the true
    intrinsic minimum, not the inflated value from set_size_request.
    Use SetInterfaceConstraints (not Constraints.MinHeight) so we only set
    the interface-level floor, leaving the user-level constraint untouched. }
  fWidget^.get_size_request(@oldW, @oldH);
  fWidget^.set_size_request(-1, -1);

  gtk4_widget_measure(fWidget, GTK_ORIENTATION_VERTICAL, -1, @mh, @nh, nil, nil);
  gtk4_widget_measure(fWidget, GTK_ORIENTATION_HORIZONTAL, -1, @mw, @nw, nil, nil);

  fWidget^.set_size_request(oldW, oldH);

  LCLObject.Constraints.SetInterfaceConstraints(mw, mh, 0, 0);
end;

procedure TGtk4Widget.DeInitializeWidget;
begin
  DetachEvents;
  DestroyWidget;
end;

procedure TGtk4Widget.DetachEvents;
begin
  { Disconnect 'commit' signal from FIMContext (PGtkIMContext) — a standalone
    GObject not in the widget hierarchy. Without this, the callback fires with
    stale Self during widget destruction. Also unref to prevent memory leak. }
  if FIMContext <> nil then
  begin
    g_signal_handlers_disconnect_matched(PGObject(FIMContext),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
    g_object_unref(PGObject(FIMContext));
    FIMContext := nil;
  end;
end;

procedure TGtk4Widget.RecreateWidget;
begin

end;

procedure TGtk4Widget.DestroyNotify(AWidget: PGtkWidget);
begin

end;

destructor TGtk4Widget.Destroy;
begin
  { If this widget owns the caret, stop the blink timer and clear the handle
    to prevent the timer callback from accessing freed memory. }
  if GTK4WidgetSet <> nil then
    GTK4WidgetSet.DestroyCaret(HWND(Self));
  if Gtk4CurrentFocusCtl = Self then
    Gtk4CurrentFocusCtl := nil;
  if Gtk4DeactivateCheckWin = Self then
    Gtk4CancelDeactivateCheck;
  Gtk4UnregisterLiveWidget(Self);
  DeInitializeWidget;
  inherited Destroy;
end;

function TGtk4Widget.CanFocus: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := FWidget^.can_focus or GetContainerWidget^.can_focus;
end;

function TGtk4Widget.GetFocusableByMouse: Boolean;
begin
  Result := FFocusableByMouse;
end;

function TGtk4Widget.getClientOffset: TPoint;
var
  dx, dy: double;
begin
  { Offset of the client (container/central) widget's origin within the outer
    FWidget — subtracted from a widget-local mouse point to get client coords.

    The old computation mixed FWidget.get_allocation / getClientBounds, whose
    Left/Top are the widget's PARENT-relative POSITION, not an inner-vs-outer
    offset. For a widget allocated away from its parent origin AND having a
    separate central widget (e.g. a TPanel at x=267 in the IDE options dialog)
    that leaked the 267px position into the offset, so EVERY mouse coordinate
    delivered to that widget was shifted by 267. It stayed invisible because
    such panels are usually ancestors with no mouse handler and the actual
    target (deepest widget) was unaffected — but DragManager aggregates the
    ClientToScreen of every control the motion reaches, so the shifted ancestor
    value jumped past the drag threshold and a plain click reordered the palette
    page list. translate_coordinates gives the true inner-vs-outer offset
    (0 for a plain panel, the border for bordered widgets) unambiguously. }
  Result := Point(0, 0);
  if (Widget = getContainerWidget) or not IsWidgetOk then
    exit;
  if gtk4_widget_translate_coordinates(GetContainerWidget, Widget, 0, 0, @dx, @dy) then
    Result := Point(Round(dx), Round(dy));
end;

function TGtk4Widget.getWidgetPos: TPoint;
var
  Allocation: TGtkAllocation;
begin
  Result := Point(0, 0);
  if IsWidgetOk then
  begin
    FWidget^.get_allocation(@Allocation);
    Result := Point(Allocation.X, Allocation.Y);
  end;
end;

procedure TGtk4Widget.OffsetMousePos(APoint: PPoint);
begin
  with getClientOffset do
  begin
    dec(APoint^.x, x);
    dec(APoint^.y, y);
  end;
end;

function TGtk4Widget.GetClientAreaOffset: TPoint;
begin
  { Offset from the widget's top-left to its client-area origin. Must equal
    getClientOffset — the same value OffsetMousePos SUBTRACTS from an incoming
    mouse point — so that ClientToScreen (which ADDS this) and ScreenToClient
    (which SUBTRACTS it) form an exact inverse of the mouse-input path. When the
    client area is inset within FWidget (e.g. a GroupBox's frame title, ~26px),
    returning (0,0) here left ClientToScreen short by that inset: a groupbox
    ancestor then reported a screen position one title-height off, which during
    an LCL drag crossed the threshold and spuriously reordered a list. This
    matches qt5, whose ClientToScreen maps through GetContainerWidget
    (QWidget_mapToGlobal(GetContainerWidget,...)) — i.e. from the client-area
    origin — so the inset is inherently included. Widgets with no separate
    central widget yield (0,0); TGtk4Window/TGtk4NoteBook override this for the
    menu-bar / tab overhead. }
  Result := getClientOffset;
end;

function TGtk4Widget.ClientToScreen(var P: TPoint): boolean;
var
  dx, dy: double;
  SurfX, SurfY: double;
  w, parentW: PgtkWidget;
  WinX, WinY: LongInt;
begin
  Result := False;
  if not IsWidgetOk then
    exit;

  { GTK4: GdkWindow removed. Use gtk_widget_translate_coordinates to convert
    from widget coords to toplevel GtkWindow coords (content-relative).
    Then add:
      1. CSD surface transform (offset from X11 window to content area)
      2. X11 window origin (offset from root to X11 window)
    to get absolute screen coordinates.
    On Wayland, Gtk4X11GetWindowOrigin returns False — fallback to
    toplevel-relative (popup positioning uses set_transient_for). }
  w := fWidget;
  repeat
    parentW := gtk_widget_get_parent(w);
    if parentW <> nil then
      w := parentW;
  until parentW = nil;

  if gtk4_widget_translate_coordinates(fWidget, w, P.X, P.Y, @dx, @dy) then
  begin
    if (Abs(dx) > GTK4_COORD_SANITY_LIMIT) or (Abs(dy) > GTK4_COORD_SANITY_LIMIT) then
      Exit(False);
    P.X := Round(dx);
    P.Y := Round(dy);

    if Gtk4X11GetWindowOrigin(w, WinX, WinY) then
    begin
      { CSD surface transform: X11 window includes shadow/decoration area.
        gtk4_native_get_surface_transform gives the offset from X11 window
        edge to the content area. Content-relative + this offset + X11 origin
        = screen-absolute. }
      SurfX := 0;
      SurfY := 0;
      gtk4_native_get_surface_transform(w, @SurfX, @SurfY);
      Inc(P.X, WinX + Round(SurfX));
      Inc(P.Y, WinY + Round(SurfY));
    end;

    { The LCL client area may start below non-client elements (form menu
      bar, notebook tab bar).  ClientToScreen(0,0) must return the origin
      of that area, or ScreenToClient-based hit tests (hints, drag targets)
      land above the real client content and miss every child. }
    with GetClientAreaOffset do
    begin
      Inc(P.X, X);
      Inc(P.Y, Y);
    end;

    Result := True;
  end;
end;

function TGtk4Widget.ScreenToClient(var P: TPoint): Integer;
var
  dx, dy: double;
  SurfX, SurfY: double;
  w, parentW: PgtkWidget;
  WinX, WinY: LongInt;
begin
  { GTK4: inverse of ClientToScreen — translate from screen to widget coords.
    First subtract X11 origin + CSD surface transform, then translate from
    toplevel content to widget. }
  Result := -1;
  if not IsWidgetOk then
    exit;

  w := fWidget;
  repeat
    parentW := gtk_widget_get_parent(w);
    if parentW <> nil then
      w := parentW;
  until parentW = nil;

  { Subtract X11 window origin + CSD surface transform }
  if Gtk4X11GetWindowOrigin(w, WinX, WinY) then
  begin
    SurfX := 0;
    SurfY := 0;
    gtk4_native_get_surface_transform(w, @SurfX, @SurfY);
    Dec(P.X, WinX + Round(SurfX));
    Dec(P.Y, WinY + Round(SurfY));
  end;

  if gtk4_widget_translate_coordinates(w, fWidget, P.X, P.Y, @dx, @dy) then
  begin
    if (Abs(dx) > GTK4_COORD_SANITY_LIMIT) or (Abs(dy) > GTK4_COORD_SANITY_LIMIT) then
      Exit(-1);
    P.X := Round(dx);
    P.Y := Round(dy);
    { Inverse of the ClientToScreen client-area adjustment. }
    with GetClientAreaOffset do
    begin
      Dec(P.X, X);
      Dec(P.Y, Y);
    end;
    Result := 0;
  end;
end;

function TGtk4Widget.DeliverMessage(var Msg; const AIsInputEvent: Boolean
  ): LRESULT;
begin
  Result := LRESULT(AIsInputEvent);
  if LCLObject = nil then
    Exit;
  try
    if LCLObject.HandleAllocated then
    begin
      LCLObject.WindowProc(TLMessage(Msg));
      Result := TLMessage(Msg).Result;
    end;
  except
    Application.HandleException(nil);
  end;
end;

function TGtk4Widget.getClientRect: TRect;
var
  AAlloc: TGtkAllocation;
  AOverlay: PGtkWidget;
begin
  //writeln('GetClientRect ',LCLObject.Name,':',LCLObject.Name);
  Result := LCLObject.BoundsRect;
  if not IsWidgetOK then
    exit;
  if GetContainerWidget^.get_realized then
  begin
    GetContainerWidget^.get_allocation(@AAlloc);
    Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
  end
  else
  begin
    { The central GtkFixed can report unrealized/0x0 even after the control is
      shown (it caches natural sizes); its overlay parent carries the real
      content allocation, which a GtkFrame insets for its border+label — so a
      groupbox client rect reflects the caption. Fall back to the overlay, then
      to FWidget. }
    AOverlay := gtk_widget_get_parent(GetContainerWidget);
    if (AOverlay <> nil) and (AOverlay <> FWidget) and AOverlay^.get_realized then
    begin
      AOverlay^.get_allocation(@AAlloc);
      if (AAlloc.width > 0) and (AAlloc.height > 0) then
        Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x, AAlloc.height + AAlloc.y);
    end
    else if FWidget^.get_realized then
    begin
      FWidget^.get_allocation(@AAlloc);
      Result := Rect(AAlloc.x, AAlloc.y, AAlloc.width + AAlloc.x,AAlloc.height + AAlloc.y);
    end;
  end;
  Types.OffsetRect(Result, -Result.Left, -Result.Top);
end;

function TGtk4Widget.getClientBounds: TRect;
var
  AAlloc: TGtkAllocation;
begin
  { The client bounds is the inner content rectangle in the control's OWN
    coordinate space: Left/Top are the content-area offset (a border/margin,
    normally 0), NOT the widget's parent-relative position. LCL subtracts
    Left/Top from mouse coordinates (TWinControl.IsControlMouseMsg) and shifts
    the paint DC origin by them, so returning the allocation's x/y (the widget's
    position within its parent, e.g. 267 for a panel in the Options dialog) used
    to corrupt every mapped mouse coordinate and child paint origin. Match the
    qt5 semantics (QWidget_contentsRect: 0-based) — keep the size, zero the
    origin. }
  Result := Rect(0, 0, 0, 0);
  if IsWidgetOk then
  begin
    if FWidget^.get_realized then
    begin
      FWidget^.get_allocation(@AAlloc);
      Result := Rect(0, 0, AAlloc.width, AAlloc.height);
    end else
    if GetContainerWidget^.get_realized then
    begin
      GetContainerWidget^.get_allocation(@AAlloc);
      Result := Rect(0, 0, AAlloc.width, AAlloc.height);
    end;
  end;
end;

procedure TGtk4Widget.SetBounds(ALeft,ATop,AWidth,AHeight:integer);
var
  ARect: TGdkRectangle;
  Alloc: TGtkAllocation;
  AMinSize, ANaturalSize: gint;
begin
  if (Widget=nil) then
    exit;

  ARect.x := ALeft;
  ARect.y := ATop;
  ARect.width := AWidth;
  ARect.Height := AHeight;
  with Alloc do
  begin
    x := ALeft;
    y := ATop;
    width := AWidth;
    height := AHeight;
  end;

  if Self is TGtk4Button then
  begin
    AWidth:=Max(1,AWidth-4);
    AHeight:=Max(1,AHeight-4);
  end;

  BeginUpdate;
  try
    { GTK4: get_preferred_width/height removed. Use gtk_widget_measure. }
    gtk4_widget_measure(Widget, GTK_ORIENTATION_HORIZONTAL, -1, @AMinSize, @ANaturalSize, nil, nil);
    gtk4_widget_measure(Widget, GTK_ORIENTATION_VERTICAL, -1, @AMinSize, @ANaturalSize, nil, nil);

    Widget^.set_size_request(AWidth,AHeight);

    { GTK4: size_allocate now requires baseline param (-1 = no baseline) }
    gtk4_widget_size_allocate(Widget, @ARect, -1);

    { GTK4: GtkOverlay does not always propagate allocation to overlay children
      (e.g. when inside a GtkFixed that caches natural sizes). Explicitly allocate
      FPaintArea and FCentralWidget so they match the widget's dimensions.
      Without this, a GtkFixed (FCentralWidget) inside a GtkOverlay may retain
      a stale 0x0 allocation, causing all its children to be clipped invisible. }
    Alloc.x := 0;
    Alloc.y := 0;
    Alloc.width := AWidth;
    Alloc.height := AHeight;
    if Assigned(FCentralWidget) and (FCentralWidget <> FWidget)
       and not (LCLObject is TCustomGroupBox) then
    begin
      { Only use size_allocate, not set_size_request, because set_size_request
        would affect gtk4_widget_measure results in preferredSize, preventing
        AutoSize from computing the correct intrinsic content size.

        Skipped for a groupbox: forcing the fixed to the full outer size would
        override the GtkFrame's inset (border+label) and make children cover the
        label / the client rect ignore the caption. The fixed instead fills its
        overlay via set_h/vexpand (SetupPaintArea), so GtkOverlay allocates it to
        the frame's actual content area as the layout settles. }
      gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
    end;
    if Assigned(FPaintArea) then
    begin
      { Only use size_allocate, not set_size_request, because FPaintArea is an
        overlay child with halign/valign=FILL — GtkOverlay automatically sizes
        it to match the main child.  set_size_request would inflate the
        GtkOverlay's minimum size, which can feed back into AutoSize via
        gtk4_widget_measure, causing controls like OI filter edits to grow
        taller on every window resize. }
      gtk4_widget_size_allocate(PGtkWidget(FPaintArea), @Alloc, -1);
    end;

    if LCLObject.Parent <> nil then
      Move(ALeft, ATop);
  finally
    EndUpdate;
  end;
end;

procedure TGtk4Widget.SetLclFont(const AFont:TFont);
var
  AGtkFont: PPangoFontDescription;
  APangoStyle: TPangoStyle;
  AOwned: Boolean;
begin
  if not IsWidgetOk then exit;
  if IsFontNameDefault(AFont.Name) then
  begin
    AGtkFont := Self.Font;
    AOwned := False;
  end else
  begin
    AGtkFont := pango_font_description_from_string(PgChar(AFont.Name));
    AGtkFont^.set_family(PgChar(AFont.Name));
    AOwned := True;
  end;

  if AFont.Size <> 0 then
    AGtkFont^.set_size(Abs(AFont.Size) * PANGO_SCALE);

  if fsItalic in AFont.Style then
    APangoStyle := PANGO_STYLE_ITALIC
  else
    APangoStyle := PANGO_STYLE_NORMAL;
  AGtkFont^.set_style(APangoStyle);
  if fsBold in AFont.Style then
    AGtkFont^.set_weight(PANGO_WEIGHT_BOLD);
  Font := AGtkFont;
  FontColor := AFont.Color;
  if AOwned then
    pango_font_description_free(AGtkFont);
end;

function TGtk4Widget.GetContainerWidget: PGtkWidget;
begin
  if Assigned(FCentralWidget) then
    Result := FCentralWidget
  else
    Result := FWidget;
end;

procedure Gtk4ParentScrollOffset(AParent: TGtk4Widget; var DX, DY: Integer); forward;

function TGtk4Widget.GetPosition(out APoint: TPoint): Boolean;
var
  Alloc:TGtkAllocation;
  prnt:TGtk4Widget;
  wtype:TGType;
  ScrollDX, ScrollDY: Integer;
begin
  Result := False;
  fWidget^.get_allocation(@Alloc);
  if (alloc.X=-1) and (alloc.Y=-1) and (alloc.height=1) and (alloc.width=1) then
  // default allocation
  else
  begin
    APoint.X:=alloc.X;
    APoint.Y:=alloc.Y;
  end;

  prnt:=self.GetParent; // TGtk4Widget
  if (prnt<>nil) then
  begin
    wtype:=prnt.getType; // parent widget type
    { GTK4: gtk_layout_get_type removed (GtkLayout removed). Only check GtkFixed. }
    if (wtype<>gtk_fixed_get_type()) then
    begin
      // widget is not on a normal client area. e.g. TPage
      Apoint.X:=0;
      APoint.Y:=0;
      Result:=true;
    end
    else
    if (wtype=gtk_fixed_get_type()) then
    begin
      { GTK4: get_has_window removed. Always adjust for parent allocation. }
      prnt.Widget^.get_allocation(@alloc);
      Dec(Apoint.X, alloc.x);
      Dec(APoint.Y, alloc.y);
      { Children of LCL-managed scrolled containers are placed at
        client + adjustment (see Gtk4ParentScrollOffset) — subtract the
        same offset so LCL reads back plain client coordinates. }
      Gtk4ParentScrollOffset(prnt, ScrollDX, ScrollDY);
      Dec(APoint.X, ScrollDX);
      Dec(APoint.Y, ScrollDY);
      Result:=true;
    end;
  end;

  if (self.getType=gtk_window_get_type()) then
  begin
    { GTK4: GdkWindow removed. gdk_window_get_root_origin does not exist.
      Use LCL coords as fallback. }
    Apoint.X:=LCLObject.Left;
    Apoint.Y:=LCLObject.Top;
    Result:=true;
  end;
end;

procedure TGtk4Widget.Release;
begin
  LCLObject := nil;
  Free;
end;

procedure TGtk4Widget.Hide;
begin
  if Assigned(FWidget) then
    FWidget^.hide;
end;

function TGtk4Widget.getParent: TGtk4Widget;
begin
  Result := Gtk4WidgetFromGtkWidget(Widget^.get_parent);
end;

function TGtk4Widget.GetWindow: PGdkWindow;
begin
  { GTK4: GdkWindow removed. gtk_widget_get_window does not exist. }
  Result := nil;
end;

{ Children of an LCL-managed scrolled container must be pinned against the
  GtkViewport's physical scroll. TGtk4CustomControl hosts TCustomControl
  descendants (OI property grid, string grids, SynEdit) whose scrollbars are
  indicator-only: the LCL scrolls by repainting with its own offset and
  expects child widgets (in-place editors) at plain client coordinates.
  The paint side is already compensated (cairo_translate in
  LCLGtkFixedSnapshot); without the same shift on child placement an editor
  lands scroll-offset pixels above its row (runtime-measured in the IDE
  Object Inspector). TGtk4ScrollingWinControl (TScrollBox and friends) is
  excluded — there the viewport shift IS the scrolling mechanism and
  children must move with the content. }
procedure Gtk4ParentScrollOffset(AParent: TGtk4Widget; var DX, DY: Integer);
var
  sw: PGtkScrolledWindow;
  adj: PGtkAdjustment;
begin
  DX := 0;
  DY := 0;
  if (AParent is TGtk4CustomControl) and
     not (AParent is TGtk4ScrollingWinControl) then
  begin
    sw := TGtk4CustomControl(AParent).getScrolledWindow;
    if (sw <> nil) and Gtk4IsScrolledWindow(PGObject(sw)) then
    begin
      adj := sw^.get_hadjustment;
      if adj <> nil then
        DX := Round(adj^.get_value);
      adj := sw^.get_vadjustment;
      if adj <> nil then
        DY := Round(adj^.get_value);
    end;
  end;
end;

procedure TGtk4Widget.Move(ALeft, ATop: Integer);
var
  AParent: TGtk4Widget;
  AContainer: PGtkWidget;
  DX, DY: Integer;
begin
  AParent := getParent;
  if (AParent <> nil) then
  begin
    AContainer := AParent.GetContainerWidget;
    if Gtk4IsFixed(AContainer) then
    begin
      Gtk4ParentScrollOffset(AParent, DX, DY);
      gtk4_fixed_move(PGtkFixed(AContainer), FWidget, ALeft + DX, ATop + DY);
    end;
  end;
end;

procedure TGtk4Widget.Activate;
begin
  if IsWidgetOK then
  begin
    if not FWidget^.visible then
      exit;
    { GTK4: GdkWindow.raise_ and get_parent_window removed.
      Just grab focus instead. }
    if FWidget^.can_focus then
      FWidget^.grab_focus;
  end;
end;

procedure TGtk4Widget.preferredSize(var PreferredWidth,
  PreferredHeight: integer; WithThemeSpace: Boolean);
var
  AMinH: gint;
  AMinW: gint;
  CW: PGtkWidget;
  wType: GType;
  ovTop, ovBottom, ovLeft, ovRight: Integer;
  w, h: Integer;
  bounds: graphene_rect_t;
  ScrollFixed: Boolean;
begin
  if IsWidgetOK then
  begin
    CW := GetContainerWidget;
    {$IFDEF GTK4DEBUGPREFERREDSIZE}
    CW^.get_size_request(@AMinW, @AMinH);
    DebugLn('>',dbgsName(LCLObject),'.preferredSize W=',dbgs(PreferredWidth),' H=',dbgs(PreferredHeight),' WithThemeSpace ',dbgs(WithThemeSpace),' AMinW=',dbgs(AMinW),' AMinH=',dbgs(AMinH));
    {$ENDIF}
    { GTK4: gtk_widget_measure includes set_size_request in its minimum/natural
      output.  SetBounds calls set_size_request(AWidth,AHeight) to tell the
      parent layout manager the intended allocation, but that inflates the
      measured minimum/natural size returned here.  PreferredSize should return
      the INTRINSIC content size (for AutoSize).

      IMPORTANT: Do NOT temporarily clear set_size_request before measuring.
      set_size_request calls gtk_widget_queue_resize which marks the widget as
      needing re-layout.  During LCL autosize processing, this creates an
      infinite loop: preferredSize → queue_resize → autosize → preferredSize.
      Symptoms: IDE Options dialog hangs when 60+ editor frames trigger layout.

      Instead, measure normally.  gtk_widget_measure returns
      max(intrinsic, request).  When request > intrinsic we cannot recover
      the exact intrinsic, but the measured value is a safe upper bound
      that the LCL autosize can work with. }
    gtk4_widget_measure(CW, GTK_ORIENTATION_VERTICAL, -1, @AMinH, @PreferredHeight, nil, nil);
    gtk4_widget_measure(CW, GTK_ORIENTATION_HORIZONTAL, -1, @AMinW, @PreferredWidth, nil, nil);

    { Scrolling container (TScrollBox/TCustomControl): CW is the GtkFixed inside
      the GtkScrolledWindow, tagged 'lcl-scroll-fixed'. LCLFixedLayoutMeasure
      intentionally returns 0 for it (LCL manages the scroll range itself). But
      gtk_widget_measure returns MAX(layout-measure=0, set_size_request), and
      SetBounds/scroll-range code sets set_size_request on this GtkFixed to the
      logical client size (viewport + horizontal range). That leaks back here as
      the widgetset preferred size, so TWinControl.CalculatePreferredSize feeds
      it into CalculateAutoRanges -> HorzScrollBar.Range -> a larger logical
      client -> a larger set_size_request: a self-reinforcing loop that grows
      the range without bound (child Left eventually overflows SmallInt ->
      ELayoutException). qt5 does not have this leak.

      Report 0 for the scroll-fixed container (its designed intrinsic), so the
      scrollbox's preferred size comes purely from LCL's own anchor-aware
      ComputePreferredClientArea over the real children. We do NOT clear
      set_size_request (that would queue_resize and can loop) — we only ignore
      the inflated measurement. The WithThemeSpace overflow correction below is
      also skipped for these containers, so their reported preferred stays
      exactly 0 (LCL owns their client size). }
    ScrollFixed := g_object_get_data(PGObject(CW), 'lcl-scroll-fixed') <> nil;
    if ScrollFixed then
    begin
      PreferredWidth := 0;
      PreferredHeight := 0;
    end;

    { WithThemeSpace: compensate for GTK4 CSS visual overflow (box-shadow etc.)
      gtk_widget_measure does NOT include CSS effects that extend outside the
      allocation bounds. We use gtk_widget_compute_bounds to measure the full
      visual extent and cache the overflow per widget GType. }
    if WithThemeSpace and not ScrollFixed then
    begin
      wType := PGTypeInstance(CW)^.g_class^.g_type;
      if not GetGTypeOverflow(wType, ovTop, ovBottom, ovLeft, ovRight) then
      begin
        { Widget must be realized for compute_bounds to work.
          On first layout pass (before realization), overflow will be 0.
          Once any widget of this GType is realized and measured,
          the cached values apply to all subsequent calls. }
        w := CW^.get_allocated_width;
        h := CW^.get_allocated_height;
        if (w > 0) and (h > 0) and
           gtk4_widget_compute_bounds(CW, CW, @bounds) then
        begin
          ovTop := Max(0, Round(-bounds.origin.y));
          ovBottom := Max(0, Round(bounds.origin.y + bounds.size.height - h));
          ovLeft := Max(0, Round(-bounds.origin.x));
          ovRight := Max(0, Round(bounds.origin.x + bounds.size.width - w));
          SetGTypeOverflow(wType, ovTop, ovBottom, ovLeft, ovRight);
        end;
      end;
      Inc(PreferredWidth, ovLeft + ovRight);
      Inc(PreferredHeight, ovTop + ovBottom);
    end;

    {$IFDEF GTK4DEBUGPREFERREDSIZE}
    DebugLn('<',dbgsName(LCLObject),'.preferredSize W=',dbgs(PreferredWidth),' H=',dbgs(PreferredHeight),' WithThemeSpace ',dbgs(WithThemeSpace),' AMinH=',dbgs(AMinH),' AMinW=',dbgs(AMinW));
    {$ENDIF}
  end;
end;

procedure TGtk4Widget.SetCursor(ACursor: HCURSOR);
begin
  if not IsWidgetOK then Exit;
  { GTK4: Use gtk_widget_set_cursor. HCURSOR is PtrUInt(PGdkCursor).
    Passing nil resets to the default cursor. }
  if ACursor <> 0 then
    gtk4_widget_set_cursor(GetContainerWidget, PGdkCursor(ACursor))
  else
    gtk4_widget_set_cursor(GetContainerWidget, nil);
end;

procedure TGtk4Widget.SetFocus;
begin
  { Mark the synchronous focus-widget notify as LCL-intended — see
    Gtk4LCLFocusIntent. }
  Gtk4LCLFocusIntent := True;
  try
    if GetContainerWidget^.can_focus then
      GetContainerWidget^.grab_focus
    else
    if FWidget^.can_focus then
      FWidget^.grab_focus;
  finally
    Gtk4LCLFocusIntent := False;
  end;
end;

procedure TGtk4Widget.SetParent(AParent: TGtk4Widget; const ALeft, ATop: Integer
  );
begin
  if (FWidget = nil) or (AParent = nil) then Exit;

  if wtNotebook in AParent.WidgetType then
    Exit; // notebook pages are attached by notebook-specific code

  { Route all container parenting through TGtk4Container.AddChild.
    The old path force-cast wtContainer parents to GtkFixed, which is invalid
    for containers backed by GtkBox (e.g. toolbar host) and can corrupt GTK state. }
  if AParent is TGtk4Container then
  begin
    TGtk4Container(AParent).AddChild(FWidget, ALeft, ATop);
    Exit;
  end;

  FWidget^.set_parent(AParent.GetContainerWidget);
end;

procedure TGtk4Widget.Show;
begin
  if IsValidHandle then
  begin
    FWidget^.show;
  end;
end;

procedure TGtk4Widget.ShowAll;
begin
  { GTK4: show_all removed. Use show. }
  if IsValidHandle then
    FWidget^.show;
end;

procedure TGtk4Widget.SetupPaintArea(AOverlay: PGtkOverlay);
begin
  { GTK4: Custom painting is now handled by patching GtkFixed's snapshot vfunc
    (LCLGtkFixedSnapshot). The DrawingArea overlay is kept for allocation sizing
    but does NOT paint — draw_func is nil. LCL painting happens inside
    GtkFixed's snapshot, BEFORE child widgets, matching GTK2/Qt5 z-order. }
  FPaintArea := PGtkDrawingArea(gtk_drawing_area_new);
  { No draw_func — painting is done in LCLGtkFixedSnapshot via snapshot vfunc }
  PGtkWidget(FPaintArea)^.set_hexpand(True);
  PGtkWidget(FPaintArea)^.set_vexpand(True);
  PGtkWidget(FPaintArea)^.set_halign(GTK_ALIGN_FILL);
  PGtkWidget(FPaintArea)^.set_valign(GTK_ALIGN_FILL);
  { Prevent DrawingArea from capturing input — pass events through to widgets below }
  gtk4_widget_set_can_target(PGtkWidget(FPaintArea), False);
  PGtkWidget(FPaintArea)^.set_can_focus(False);
  gtk4_widget_set_overflow(PGtkWidget(FPaintArea), GTK4_OVERFLOW_HIDDEN);
  gtk_overlay_add_overlay(AOverlay, PGtkWidget(FPaintArea));
  { GTK4: GtkFixed (FCentralWidget) must be targetable so GTK4 hit-testing
    traverses into it and finds child WinControls (e.g. toolbar inside coolbar).
    Without this, mouse events stop at the parent overlay. }
  if Assigned(FCentralWidget) then
  begin
    gtk4_widget_set_can_target(FCentralWidget, True);
    gtk4_widget_set_overflow(FCentralWidget, GTK4_OVERFLOW_HIDDEN);
    { Fill the overlay so, where SetBounds does not force an explicit size (a
      GtkFrame-wrapped groupbox), GtkOverlay allocates the fixed to the overlay's
      actual content area — which the frame insets for its border+label — instead
      of leaving it 0x0. This lets the client area track the frame chrome as the
      layout settles, without a fixed-time allocation guess. }
    PGtkWidget(FCentralWidget)^.set_hexpand(True);
    PGtkWidget(FCentralWidget)^.set_vexpand(True);
    PGtkWidget(FCentralWidget)^.set_halign(GTK_ALIGN_FILL);
    PGtkWidget(FCentralWidget)^.set_valign(GTK_ALIGN_FILL);
    { Tag FCentralWidget with 'lclwidget' so LCLGtkFixedSnapshot can find
      the TGtk4Widget owner for painting. }
    g_object_set_data(PGObject(FCentralWidget), 'lclwidget', Self);
  end;
  { Clip the overlay itself to prevent any content leakage }
  gtk4_widget_set_overflow(PGtkWidget(AOverlay), GTK4_OVERFLOW_HIDDEN);
end;

procedure TGtk4Widget.Update(ARect: PRect);
begin
  { GTK4: gtk_widget_queue_draw_area was removed. Use queue_draw.
    Painting is now done in GtkFixed's snapshot vfunc (LCLGtkFixedSnapshot),
    so queue_draw on FCentralWidget to trigger snapshot re-rendering. }
  if IsWidgetOK then
  begin
    if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
      FCentralWidget^.queue_draw
    else
    begin
      FWidget^.queue_draw;
      if FWidget <> GetContainerWidget then
        GetContainerWidget^.queue_draw;
    end;
  end;
end;

{ TGtk4StatusBar }

procedure TGtk4StatusBar.ClearPanels;
var
  i: Integer;
begin
  for i := High(FPanels) downto 0 do
  begin
    gtk4_box_remove(PGtkBox(FCentralWidget), PGtkWidget(FPanels[i]));
    { gtk4_box_remove unrefs the child, so no extra unref needed }
  end;
  SetLength(FPanels, 0);
end;

procedure TGtk4StatusBar.RecreatePanels;
var
  AStatusBar: TStatusBar;
  i, NewCount: Integer;
  ALabel: PGtkLabel;
  PanelText: String;
begin
  ClearPanels;
  if not (LCLObject is TStatusBar) then Exit;
  AStatusBar := TStatusBar(LCLObject);

  if AStatusBar.SimplePanel or (AStatusBar.Panels.Count < 1) then
    NewCount := 1
  else
    NewCount := AStatusBar.Panels.Count;

  SetLength(FPanels, NewCount);
  for i := 0 to NewCount - 1 do
  begin
    { Determine panel text }
    if AStatusBar.SimplePanel or (AStatusBar.Panels.Count < 1) then
      PanelText := AStatusBar.SimpleText
    else
      PanelText := AStatusBar.Panels[i].Text;

    ALabel := gtk_label_new(PgChar(PanelText));
    FPanels[i] := ALabel;

    { Set alignment }
    if (not AStatusBar.SimplePanel) and (AStatusBar.Panels.Count > i) then
    begin
      case AStatusBar.Panels[i].Alignment of
        taLeftJustify:  gtk_label_set_xalign(ALabel, 0.0);
        taRightJustify: gtk_label_set_xalign(ALabel, 1.0);
        taCenter:       gtk_label_set_xalign(ALabel, 0.5);
      end;

      { Set width via size request; hide panels with width=0 }
      if AStatusBar.Panels[i].Width > 0 then
        PGtkWidget(ALabel)^.set_size_request(AStatusBar.Panels[i].Width, -1)
      else
        PGtkWidget(ALabel)^.set_visible(False);
    end else
      gtk_label_set_xalign(ALabel, 0.0);

    { Last panel expands to fill remaining space }
    if i = NewCount - 1 then
      PGtkWidget(ALabel)^.set_hexpand(True)
    else
      PGtkWidget(ALabel)^.set_hexpand(False);

    gtk4_box_append(PGtkBox(FCentralWidget), PGtkWidget(ALabel));
  end;
end;

procedure TGtk4StatusBar.UpdatePanel(AIndex: Integer);
var
  AStatusBar: TStatusBar;
  ALabel: PGtkLabel;
  PanelText: String;
begin
  if not (LCLObject is TStatusBar) then Exit;
  AStatusBar := TStatusBar(LCLObject);

  { If panel count changed, do a full rebuild }
  if AStatusBar.SimplePanel or (AStatusBar.Panels.Count < 1) then
  begin
    if Length(FPanels) <> 1 then
    begin
      RecreatePanels;
      Exit;
    end;
  end else
  begin
    if Length(FPanels) <> AStatusBar.Panels.Count then
    begin
      RecreatePanels;
      Exit;
    end;
  end;

  { Bounds check }
  if (AIndex < 0) or (AIndex > High(FPanels)) then Exit;

  ALabel := FPanels[AIndex];

  { Text }
  if AStatusBar.SimplePanel then
    PanelText := AStatusBar.SimpleText
  else
    PanelText := AStatusBar.Panels[AIndex].Text;

  gtk_label_set_text(ALabel, PgChar(PanelText));

  { Alignment, width — only for non-simple panels }
  if (not AStatusBar.SimplePanel) and (AStatusBar.Panels.Count > AIndex) then
  begin
    case AStatusBar.Panels[AIndex].Alignment of
      taLeftJustify:  gtk_label_set_xalign(ALabel, 0.0);
      taRightJustify: gtk_label_set_xalign(ALabel, 1.0);
      taCenter:       gtk_label_set_xalign(ALabel, 0.5);
    end;

    if AStatusBar.Panels[AIndex].Width > 0 then
    begin
      PGtkWidget(ALabel)^.set_size_request(AStatusBar.Panels[AIndex].Width, -1);
      PGtkWidget(ALabel)^.set_visible(True);
    end else
      PGtkWidget(ALabel)^.set_visible(False);
  end;

  { Last panel gets hexpand }
  PGtkWidget(ALabel)^.set_hexpand(AIndex = High(FPanels));
end;

function TGtk4StatusBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  { GTK4: GtkEventBox removed. Use GtkBox as container instead. }
  Result := TGtkBox.new(GTK_ORIENTATION_VERTICAL, 0);
  FCentralWidget := TGtkHBox.new(GTK_ORIENTATION_HORIZONTAL, 1);
  PGtkBox(FCentralWidget)^.set_homogeneous(False);
  gtk4_box_append(PGtkBox(Result), FCentralWidget);
end;

{ TGtk4Panel }

procedure TGtk4Panel.SetColor(AValue: TColor);
begin
  inherited SetColor(AValue);
end;

function TGtk4Panel.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  FHasPaint := True;
  FBorderStyle := bsNone;

  FWidgetType := [wtWidget, wtContainer];

  { GTK4: Use GtkOverlay as main widget to support custom painting.
    Hierarchy: GtkOverlay → [GtkFixed (children), GtkDrawingArea (paint)]
    Child widgets are placed in FCentralWidget (GtkFixed) via GetContainerWidget. }
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  Result := PGtkWidget(AOverlay);
  FCentralWidget := TGtkFixed.new;
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);

  // this is here to make TGtk4Panel shown under Plasma
  Result^.set_size_request(LCLObject.Width, LCLObject.Height);
end;

procedure TGtk4Panel.DoBeforeLCLPaint;
var
  DC: TGtk4DeviceContext;
  NColor: TColor;
begin
  inherited DoBeforeLCLPaint;
  if not Visible then
    exit;

  DC := TGtk4DeviceContext(Context);

  NColor := LCLObject.Color;
  if (NColor <> clNone) and (NColor <> clDefault) then
  begin
    DC.CurrentBrush.Color := ColorToRGB(NColor);
    DC.fillRect(0, 0, LCLObject.Width, LCLObject.Height);
  end;

  if BorderStyle <> bsNone then
  begin
    DC.CurrentPen.Color := ColorToRGB(clBtnShadow); // not sure what color to use here?
    DC.drawRect(0, 0, LCLObject.Width, LCLObject.Height, False, True);
  end;
end;

procedure TGtk4Panel.setText(const AValue: String);
begin
  if FText = AValue then
    exit;
  FText := AValue;
  if Self.Visible then
    Widget^.queue_draw;
end;

procedure TGtk4Panel.UpdateWidgetConstraints;
begin
  inherited UpdateWidgetConstraints;
end;

{ TGtk4GroupBox }

function TGtk4GroupBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  FHasPaint := True;
  FWidgetType := [wtWidget, wtContainer, wtGroupBox];
  Result := TGtkFrame.new(PChar(Self.LCLObject.Caption));

  { GTK4: Insert GtkOverlay between GtkFrame and GtkFixed for painting.
    Hierarchy: GtkFrame → GtkOverlay → [GtkFixed (children), GtkDrawingArea (paint)] }
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  FCentralWidget := TGtkFixed.new;
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);
  gtk4_frame_set_child(PGtkFrame(Result), PGtkWidget(AOverlay));

  { GTK4: set_label_align takes only xalign in GTK4 (yalign removed).
    Using 0.1 for xalign. }
  PgtkFrame(result)^.set_label_align(0.1, 0.5);
end;

function TGtk4GroupBox.getText: String;
begin
  Result := '';
  if IsWidgetOK then
  begin
    if PGtkFrame(Widget)^.get_label_widget = nil then
      exit;
    Result := ReplaceUnderscoresWithAmpersands(PGtkFrame(Widget)^.get_label);
  end;
end;

function Gtk4GroupBoxReRectIdleCB(Data: gpointer): gboolean; cdecl;
begin
  { Runs after the frame has re-laid-out for a caption change (the overlay's
    inset content allocation is only updated on the next layout pass), so that
    re-querying getClientRect now reads the new inset. }
  Result := G_SOURCE_REMOVE_;
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  if TGtk4Widget(Data).LCLObject <> nil then
  begin
    TGtk4Widget(Data).LCLObject.InvalidateClientRectCache(True);
    TGtk4Widget(Data).LCLObject.DoAdjustClientRectChange;
  end;
end;

procedure TGtk4GroupBox.setText(const AValue: String);
begin
  if IsWidgetOK then
  begin
    if AValue = '' then
      PGtkFrame(Widget)^.set_label_widget(nil)
    else
    begin
      if PGtkFrame(Widget)^.get_label_widget = nil then
        PGtkFrame(Widget)^.set_label_widget(TGtkLabel.new(''));
      PGtkFrame(Widget)^.set_label(PgChar(ReplaceAmpersandsWithUnderscores(AValue)));
    end;
    { Caption presence changes the frame's reserved label height and thus the
      client area; refresh the cached client rect after the layout settles. }
    g_idle_add(@Gtk4GroupBoxReRectIdleCB, Self);
  end;
end;


{ TGtk4Editable }

function TGtk4Editable.GetReadOnly: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := not PGtkEditable(Widget)^.get_editable;
end;

procedure TGtk4Editable.SetReadOnly(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkEditable(Widget)^.set_editable(not AValue);
end;

{ Deferred SelStart (X11 PRIMARY race).
  LCL sets a selection as SetSelStart(a) followed by SetSelLength(n)
  (TCustomEdit.SelectAll does exactly that). Applying SelStart at once with
  gtk_editable_set_position collapses any existing selection, which makes
  GtkText release PRIMARY (XSetSelectionOwner None, time T); the following
  select_region reclaims PRIMARY with the same server time T, and the X server's
  delayed SelectionClear(T) is then not recognised as stale by GDK
  (gdkclipboard-x11.c ignores it only when time < claim time) - GDK marks the
  clipboard remote, GtkText's content provider is detached and the selection is
  cleared. Symptom: SelectAll on a focused TEdit leaves nothing selected.
  So setSelStart only records the wanted position; setSelLength consumes it and
  makes a single select_region call (no collapse in between). A lone SelStart is
  applied by a one-shot high priority idle (before the next queued event), at
  the end of the LCL message handler that set it, or right before any native
  operation that depends on the caret (setText, MaxLength, spin formatting, the
  deferred IM insert). The LCL getters report the pending value meanwhile. }

function Gtk4EditableSelStartIdleCB(AData: gpointer): gboolean; cdecl;
begin
  Result := G_SOURCE_REMOVE_;
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  { the source is removed by our return value - do not g_source_remove it again }
  TGtk4Editable(AData).FPendingSelStartIdle := 0;
  TGtk4Editable(AData).ApplyPendingSelStart;
end;

procedure TGtk4Editable.CancelPendingSelStart;
begin
  FSelStartPending := False;
  if FPendingSelStartIdle <> 0 then
  begin
    g_source_remove(FPendingSelStartIdle);
    FPendingSelStartIdle := 0;
  end;
end;

procedure TGtk4Editable.ApplyPendingSelStart;
var
  APos: Integer;
begin
  if not FSelStartPending then
    Exit;
  APos := FPendingSelStart;
  { clear our state before the native call: set_position notifies
    cursor-position and may re-enter the LCL }
  CancelPendingSelStart;
  if IsValidHandle and IsWidgetOk then
    PGtkEditable(Widget)^.set_position(APos);
end;

function TGtk4Editable.DeliverMessage(var Msg; const AIsInputEvent: Boolean
  ): LRESULT;
begin
  Result := inherited DeliverMessage(Msg, AIsInputEvent);
  { a SelStart set by the LCL handler must be in place before GTK continues
    with the native action (key insert, paste, ...). The handler may have
    destroyed this wrapper: touch it only while it is still registered. }
  if Gtk4IsLiveWidgetPointer(Self) then
    ApplyPendingSelStart;
end;

procedure TGtk4Editable.DetachEvents;
begin
  CancelPendingSelStart;
  inherited DetachEvents;
end;

function TGtk4Editable.getCaretPos: TPoint;
begin
  Result := Point(0, 0);
  if not IsWidgetOk then
    exit;
  if FSelStartPending then
    Result.X := FPendingSelStart
  else
    Result.X := PGtkEditable(Widget)^.get_position;
end;

procedure TGtk4Editable.SetCaretPos(AValue: TPoint);
begin
  if not IsWidgetOk then
    exit;
  { an explicit caret position supersedes a pending SelStart }
  CancelPendingSelStart;
  PGtkEditable(Widget)^.set_position(AValue.X);
end;

function TGtk4Editable.getSelStart: Integer;
var
  AStart: gint;
  AStop: gint;
begin
  Result := 0;
  if not IsWidgetOk then
    exit;
  if FSelStartPending then
    Result := FPendingSelStart
  else
  if PGtkEditable(Widget)^.get_selection_bounds(@AStart, @AStop) then
    Result := AStart
  else
    { no selection: the caret, like GTK2 (Min(current_pos, selection_bound)) }
    Result := PGtkEditable(Widget)^.get_position;
end;

function TGtk4Editable.getSelLength: Integer;
var
  AStart: gint;
  AStop: gint;
begin
  Result := 0;
  if not IsWidgetOk then
    exit;
  if FSelStartPending then
    exit; { a pending SelStart collapses the selection when applied }
  if PGtkEditable(Widget)^.get_selection_bounds(@AStart, @AStop) then
  begin
    Result := AStop - AStart;
  end;
end;

procedure TGtk4Editable.setSelStart(AValue: Integer);
var
  ALen: Integer;
begin
  if not IsWidgetOk then
    exit;
  { clamp like GTK does on apply (characters, negative = end of text) so the
    getters report the effective position while it is pending }
  ALen := g_utf8_strlen(gtk4_editable_get_text(Widget), -1);
  if AValue < 0 then
    FPendingSelStart := ALen
  else
    FPendingSelStart := Min(AValue, ALen);
  FSelStartPending := True;
  if FPendingSelStartIdle = 0 then
    FPendingSelStartIdle := g_idle_add_full(G_PRIORITY_HIGH,
      @Gtk4EditableSelStartIdleCB, Self, nil);
end;

procedure TGtk4Editable.setSelLength(AValue: Integer);
var
  AStart: gint;
  AStop: gint;
begin
  if not IsWidgetOk then
    exit;
  if FSelStartPending then
  begin
    { the SelStart/SelLength transaction: one select_region, no collapse }
    AStart := FPendingSelStart;
    CancelPendingSelStart;
  end else
  if not PGtkEditable(Widget)^.get_selection_bounds(@AStart, @AStop) then
    AStart := PGtkEditable(Widget)^.get_position;
  { else AStart = start of the existing selection (GTK2/Win32 semantics) }
  if InUpdate then
  begin
    PrivateCursorPos := AStart;
    PrivateSelection := AValue;
  end;
  PGtkEditable(Widget)^.select_region(AStart, AStart + AValue);
end;

{ TGtk4Entry }

{ cut-clipboard / copy-clipboard / paste-clipboard action signals of GtkText and
  GtkTextView (emitted by the Ctrl+X/C/V key bindings and the context menu
  actions, not by middle click or gtk_text_buffer_paste_clipboard): tell the
  LCL control like the GTK2 widgetset does. The handler runs before the GTK
  class handler, it is a notification and cannot veto the native operation. }
procedure Gtk4EditableClipboardMsg(AData: GPointer; AMsg: Cardinal);
var
  Msg: TLMessage;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  if not TGtk4Widget(AData).CanSendLCLMessage then Exit;
  if csDesigning in TGtk4Widget(AData).LCLObject.ComponentState then Exit;
  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := AMsg;
  TGtk4Widget(AData).DeliverMessage(Msg);
  { the LCL handler may have destroyed the control - do not touch AData afterwards }
end;

procedure Gtk4EditableCutCB({%H-}AWidget: PGtkWidget; AData: GPointer); cdecl;
begin
  Gtk4EditableClipboardMsg(AData, LM_CUT);
end;

procedure Gtk4EditableCopyCB({%H-}AWidget: PGtkWidget; AData: GPointer); cdecl;
begin
  Gtk4EditableClipboardMsg(AData, LM_COPY);
end;

procedure Gtk4EditablePasteCB({%H-}AWidget: PGtkWidget; AData: GPointer); cdecl;
begin
  Gtk4EditableClipboardMsg(AData, LM_PASTE);
end;

procedure Gtk4EntryChanged({%H-}AEntry: PGtkEntryBuffer; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  { Design mode: do not report native text/value changes (e.g. a click on the
    spin-button arrows of a TSpinEdit) back to the LCL — the design-time
    Text/Value would be corrupted. }
  if Assigned(TGtk4Widget(AData).LCLObject) and
     (csDesigning in TGtk4Widget(AData).LCLObject.ComponentState) then
    Exit;
  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := CM_TEXTCHANGED;
  TGtk4Widget(AData).DeliverMessage(Msg);
end;

function TGtk4Entry.GetAlignment: TAlignment;
var
  AFloat: GFloat;
begin
  Result := taLeftJustify;
  if not IsWidgetOk or not Gtk4IsEntry(Widget) then
    exit;
  AFloat := PGtkEntry(Widget)^.get_alignment;
  if AFloat = 1 then
    Result := taRightJustify
  else
  if AFloat = 0.5 then
    Result := taCenter;
end;

procedure TGtk4Entry.SetAlignment(AValue: TAlignment);
var
  AFloat: GFloat;
begin
  AFloat := 0;
  if not IsWidgetOk or not Gtk4IsEntry(Widget) then
    exit;
  case AValue of
    taCenter: AFloat := 0.5;
    taRightJustify: AFloat := 1.0;
  end;
  PGtkEntry(Widget)^.set_alignment(AFloat);
end;

function TGtk4Entry.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_UP, VK_DOWN];
end;

{ ---- Entry typed-text key events (qt5 model) --------------------------------
  GtkText consumes printable key presses in its TARGET phase (directly or via
  the input method), so the bubble-phase LCL key controller never sees them and
  OnKeyPress/OnUTF8KeyPress/form KeyPreview never fired for typed characters.
  Following qt5 (which derives text events from QKeyEvent.text / the IM
  commitString, never from raw keyvals), we hook 'insert-text' on the entry's
  inner GtkText DELEGATE — the only place typed AND IM-committed text reliably
  arrives (the wrapper GtkEntry's editable signals fire only for programmatic
  sets) — and deliver the inserted text to the LCL as key-press events.

  A capture-phase key controller on the delegate records (never consumes)
  whether an unmodified key press is in flight: insertions outside a pending
  key (clipboard paste via menu/middle-click, programmatic writes) do not fire
  key events, and Ctrl/Alt-chorded keys (e.g. Ctrl+V) are treated as shortcuts,
  not text producers. The IM is untouched: we neither filter nor reorder its
  output — composition and commit order remain exactly native. }

function Gtk4EntryDelegateKeyPressCB({%H-}controller: PGtkEventController;
  keyval: guint; {%H-}keycode: guint; state: TGdkModifierType;
  user_data: gpointer): gboolean; cdecl;
var
  Entry: TGtk4Entry;
  UChar: guint32;
begin
  Result := False; { record only — never consume, never disturb the IM }
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  Entry := TGtk4Entry(user_data);
  Entry.FDelegateKeyPending := state * [GDK_CONTROL_MASK, GDK_MOD1_MASK] = [];
  Entry.FPendingKeyText := '';
  if Entry.FDelegateKeyPending then
  begin
    { The key's own character — used to recognize a raw-key bypass insertion
      that raced ahead of a pending IM commit (see the deferral logic below). }
    UChar := gdk_keyval_to_unicode(keyval);
    if (UChar >= 32) and (UChar <> 127) and (UChar < $110000) then
      Entry.FPendingKeyText := UnicodeToUTF8(UChar);
  end;
end;

procedure Gtk4EntryDelegateKeyReleaseCB({%H-}controller: PGtkEventController;
  {%H-}keyval: guint; {%H-}keycode: guint; {%H-}state: TGdkModifierType;
  user_data: gpointer); cdecl;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  TGtk4Entry(user_data).FDelegateKeyPending := False;
  TGtk4Entry(user_data).FPendingKeyText := '';
end;

{ ---- IM commit-order repair (deferral, never reordering by guesswork) -------
  With some IM stacks (observed: fcitx5-frontend-gtk4 + fcitx5-hangul on GTK
  4.6), a key that is not part of the composition (e.g. space while a Hangul
  syllable is in preedit) is forwarded to the widget and INSERTED BEFORE the
  pending preedit commit arrives, so "한글이 " ends up as "한글 이". This is the
  IM module's delivery order — reproduced in pure-C GTK4 — not something LCL
  causes, but we can repair it locally: when the text being inserted is exactly
  the pending physical key's own character while a preedit is active, that
  insertion is the bypassed raw key racing ahead of the commit. We defer it,
  let the commit insert first, then insert the deferred text after it (at the
  post-commit position). For well-behaved IM stacks the commit arrives first or
  no preedit is active, the condition never matches, and all of this is a
  strict no-op. Fallback flushes (preedit cleared, focus leaves) mean the worst
  case equals today's behavior — never worse. }

procedure Gtk4EntryFlushDeferred(Entry: TGtk4Entry; editable: PGtkEditable;
  position: Pgint);
var
  S: string;
  APos: gint;
begin
  S := Entry.FDeferredText;
  if S = '' then exit;
  Entry.FDeferredText := '';
  Entry.ApplyPendingSelStart; { a caret move requested by the LCL comes first }
  Entry.FFlushingDeferred := True;
  try
    if position <> nil then
      { inside the commit's insert-text AFTER handler: position^ is the
        post-insert offset, so the deferred text lands right after the commit }
      editable^.insert_text(PgChar(S), Length(S), position)
    else
    begin
      { fallback (preedit cleared / focus leave): insert at the caret }
      APos := gtk_editable_get_position(editable);
      editable^.insert_text(PgChar(S), Length(S), @APos);
      gtk_editable_set_position(editable, APos);
    end;
  finally
    Entry.FFlushingDeferred := False;
  end;
end;

procedure Gtk4EntryDelegatePreeditCB(w: PGtkWidget; preedit: Pgchar;
  user_data: gpointer); cdecl;
var
  Entry: TGtk4Entry;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  Entry := TGtk4Entry(user_data);
  if preedit = nil then
    Entry.FPreeditText := ''
  else
    Entry.FPreeditText := string(preedit);
  { composition ended without a commit-triggered flush — release anything held }
  if (Entry.FPreeditText = '') and (Entry.FDeferredText <> '') then
    Gtk4EntryFlushDeferred(Entry, PGtkEditable(w), nil);
end;

procedure Gtk4EntryDelegateInsertAfterCB(editable: PGtkEditable;
  {%H-}new_text: Pgchar; {%H-}new_len: gint; position: Pgint;
  user_data: gpointer); cdecl;
begin
  { AFTER handler: runs once the default insert completed (never for stopped
    emissions). An accepted insert during composition is the IM commit — flush
    the deferred raw key right after it, at the updated position. }
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  if TGtk4Entry(user_data).FSuppressInsertFeedback then exit;
  if TGtk4Entry(user_data).FFlushingDeferred then exit;
  if TGtk4Entry(user_data).FDeferredText = '' then exit;
  Gtk4EntryFlushDeferred(TGtk4Entry(user_data), editable, position);
end;

procedure Gtk4EntryDelegateFocusLeaveCB(controller: PGtkEventController;
  user_data: gpointer); cdecl;
var
  W: PGtkWidget;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  if TGtk4Entry(user_data).FDeferredText = '' then exit;
  W := gtk_event_controller_get_widget(controller);
  if W <> nil then
    Gtk4EntryFlushDeferred(TGtk4Entry(user_data), PGtkEditable(W), nil);
end;

procedure Gtk4EntryDelegateInsertTextCB(editable: PGtkEditable; new_text: Pgchar;
  new_len: gint; position: Pgint; user_data: gpointer); cdecl;
var
  Entry: TGtk4Entry;
  AEdit: TCustomEdit;
  InStr, OutStr: string;
  UTF8In, UTF8Key: TUTF8Char;
  BytePos, CpLen: Integer;
  CharMsg: TLMChar;
  Eaten: Boolean;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  Entry := TGtk4Entry(user_data);
  if Entry.FSuppressInsertFeedback then exit;
  if (new_text = nil) or (new_len <= 0) then exit;
  if (Entry.LCLObject = nil) or not (Entry.LCLObject is TCustomEdit) then exit;
  AEdit := TCustomEdit(Entry.LCLObject);
  if csDesigning in AEdit.ComponentState then exit;

  SetString(InStr, new_text, new_len);

  { NumbersOnly applies to EVERY insertion — typed, pasted, dropped, IM-committed
    — so it comes before the key-origin gate. The wrapper's insert-text handler
    (TGtk4Entry.InsertText) only ever fires for programmatic sets; typed text
    lands here on the delegate. Same semantics as the wrapper: an insertion
    containing any non-digit is rejected whole. Rejected text is stopped before
    the deferral below, so it never enters the deferred queue either.
    (CharCase needs nothing here: TCustomEdit.TextChanged applies it generically
    at the LCL level.) }
  if AEdit.NumbersOnly then
    for BytePos := 1 to Length(InStr) do
      if not (InStr[BytePos] in ['0'..'9']) then
      begin
        g_signal_stop_emission_by_name(PGObject(editable), 'insert-text');
        exit;
      end;

  { key-origin gate: paste/programmatic inserts fire no key events. A deferred
    flush is key-originated by construction (its key may already be released). }
  if not (Entry.FDelegateKeyPending or Entry.FFlushingDeferred) then exit;
  if not Entry.CanSendLCLMessage then exit;

  { IM commit-order repair (see Gtk4EntryFlushDeferred above): a raw-key bypass
    insertion racing ahead of a pending commit is deferred until the commit
    lands. Matches only the pending key's own character during active preedit. }
  if (not Entry.FFlushingDeferred) and (Entry.FPreeditText <> '')
     and (InStr = Entry.FPendingKeyText) and (InStr <> Entry.FPreeditText) then
  begin
    Entry.FDeferredText := Entry.FDeferredText + InStr;
    g_signal_stop_emission_by_name(PGObject(editable), 'insert-text');
    exit;
  end;
  OutStr := '';
  BytePos := 1;
  while BytePos <= Length(InStr) do
  begin
    CpLen := UTF8CodepointSize(@InStr[BytePos]);
    if CpLen <= 0 then CpLen := 1;
    if BytePos + CpLen - 1 > Length(InStr) then CpLen := Length(InStr) - BytePos + 1;
    UTF8In := Copy(InStr, BytePos, CpLen);
    Inc(BytePos, CpLen);
    UTF8Key := UTF8In;
    Eaten := False;

    { form KeyPreview + control OnUTF8KeyPress (LCL walks parent forms first) }
    if AEdit.IntfUTF8KeyPress(UTF8Key, 1, False) or (UTF8Key = '') then
      Eaten := True;
    if not Entry.CanSendLCLMessage then exit;

    { classic single-byte OnKeyPress via CN_CHAR/LM_CHAR — mirrors the
      GtkEventKey character block used by non-native widgets }
    if not Eaten and (Length(UTF8Key) = 1) then
    begin
      FillChar(CharMsg{%H-}, SizeOf(CharMsg), 0);
      CharMsg.Msg := CN_CHAR;
      CharMsg.CharCode := Word(UTF8Key[1]);
      NotifyApplicationUserInput(AEdit, CharMsg.Msg);
      if not Entry.CanSendLCLMessage then exit;
      if (Entry.DeliverMessage(CharMsg, True) <> 0) or (CharMsg.CharCode = VK_UNKNOWN) then
        Eaten := True
      else
      begin
        if Char(CharMsg.CharCode) <> UTF8Key[1] then
          UTF8Key := Char(CharMsg.CharCode);   { handler replaced the char }
        { LM_CHAR is a notification; its Result does not mean "consume" (the
          default handler returns nonzero after dispatching). Only an explicitly
          zeroed CharCode eats the character here. }
        CharMsg.Msg := LM_CHAR;
        NotifyApplicationUserInput(AEdit, CharMsg.Msg);
        if not Entry.CanSendLCLMessage then exit;
        Entry.DeliverMessage(CharMsg, True);
        if not Entry.CanSendLCLMessage then exit;
        if CharMsg.CharCode = VK_UNKNOWN then
          Eaten := True
        else if Char(CharMsg.CharCode) <> UTF8Key[1] then
          UTF8Key := Char(CharMsg.CharCode);
      end;
      if not Entry.CanSendLCLMessage then exit;
    end;

    if not Eaten then
      OutStr := OutStr + UTF8Key;
  end;

  if OutStr = InStr then
    exit;  { untouched — let the native insertion proceed }

  { the LCL consumed or changed the text: replace the native insertion }
  g_signal_stop_emission_by_name(PGObject(editable), 'insert-text');
  if OutStr <> '' then
  begin
    Entry.FSuppressInsertFeedback := True;
    try
      editable^.insert_text(PgChar(OutStr), Length(OutStr), position);
    finally
      Entry.FSuppressInsertFeedback := False;
    end;
  end;
end;

procedure TGtk4Entry.InsertText(const atext:pchar;len:gint;var pos:gint;edt:TGtk4Entry);cdecl;
var
  i: integer;
  AEdit: TCustomEdit;
  AUpper, ALower: String;
begin
  AEdit := TCustomEdit(edt.LCLObject);

  if AEdit.NumbersOnly then
  begin
    for i := 0 to len-1 do
    begin
       if not (atext[i] in ['0'..'9']) then
       begin
         g_signal_stop_emission_by_name(PGObject(Self), 'insert-text');
         exit;
       end;
    end;
  end;

  { Handle CharCase: intercept insertion, stop original, insert converted text }
  case AEdit.CharCase of
    ecUpperCase:
    begin
      AUpper := UpperCase(Copy(atext, 1, len));
      if AUpper <> Copy(atext, 1, len) then
      begin
        g_signal_stop_emission_by_name(PGObject(Self), 'insert-text');
        PGtkEditable(edt.Widget)^.insert_text(PgChar(AUpper), Length(AUpper), @pos);
      end;
    end;
    ecLowerCase:
    begin
      ALower := LowerCase(Copy(atext, 1, len));
      if ALower <> Copy(atext, 1, len) then
      begin
        g_signal_stop_emission_by_name(PGObject(Self), 'insert-text');
        PGtkEditable(edt.Widget)^.insert_text(PgChar(ALower), Length(ALower), @pos);
      end;
    end;
  end;
end;

function TGtk4Entry.getText: String;
begin
  if IsValidHandle and IsWidgetOk then
    { GTK4: gtk_entry_get_text removed. Use GtkEditable interface. }
    Result := StrPas(gtk4_editable_get_text(Widget))
  else
    Result := '';
end;

procedure TGtk4Entry.setText(const AValue: String);
begin
  if IsValidHandle and IsWidgetOK then
  begin
    ApplyPendingSelStart; { keep the "SelStart := a; Text := s" order }
    { Programmatic text must not fire OnKeyPress via the delegate insert-text
      hook (it is not key input). }
    FSuppressInsertFeedback := True;
    try
      { GTK4: gtk_entry_set_text removed. Use GtkEditable interface. }
      gtk4_editable_set_text(Widget, PgChar(AValue));
    finally
      FSuppressInsertFeedback := False;
    end;
  end;
  { A programmatic set re-baselines the undo approximation: there is nothing to
    undo until the user edits away from this value. }
  FUndoBaseline := AValue;
end;

function TGtk4Entry.GetCanUndoState: Boolean;
begin
  Result := IsValidHandle and IsWidgetOk and (getText <> FUndoBaseline);
end;

function TGtk4Entry.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  Result := PGtkWidget(TGtkEntry.new);
  FWidgetType := FWidgetType + [wtEntry];
  fText:=Params.Caption;
  FUndoBaseline := Params.Caption;
  PrivateCursorPos := -1;
  PrivateSelection := -1;
end;

procedure TGtk4Entry.SetBounds(Left, Top, Width, Height: integer);
begin
  inherited SetBounds(Left, Top, Width, Height);
end;

procedure TGtk4Entry.InitializeWidget;
var
  ADelegate: PGtkEditable;
  AKeyRec, AFocusRec: PGtkEventController;
begin
  inherited InitializeWidget;

  Widget^.set_size_request(fParams.Width,fParams.Height);
  { GTK4: gtk_entry_set_text was removed. Use GtkEditable interface. }
  gtk4_editable_set_text(Widget, PgChar(fParams.Caption));

  Self.SetTextHint(TCustomEdit(Self.LCLObject).TextHint);
  Self.SetNumbersOnly(TCustomEdit(Self.LCLObject).NumbersOnly);
  { Apply initial border style — has_frame=False removes Adwaita entry chrome }
  Self.SetFrame(TCustomEdit(Self.LCLObject).BorderStyle = bsSingle);

  g_signal_connect_data(Widget, 'changed', TGCallback(@Gtk4EntryChanged), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(Widget, 'insert-text', TGCallback(@TGtk4Entry.InsertText), Self, nil, G_CONNECT_DEFAULT);

  { Typed/IM-committed text arrives on the inner GtkText delegate, not the
    wrapper (see Gtk4EntryDelegateInsertTextCB). Hook it for OnKeyPress/
    KeyPreview, with a record-only capture key controller gating the hook to
    key-originated insertions. }
  ADelegate := gtk_editable_get_delegate(PGtkEditable(Widget));
  if ADelegate <> nil then
  begin
    g_signal_connect_data(PGObject(ADelegate), 'insert-text',
      TGCallback(@Gtk4EntryDelegateInsertTextCB), Self, nil, G_CONNECT_DEFAULT);
    { AFTER handler flushes text deferred by the IM commit-order repair right
      after the commit's own insertion (see Gtk4EntryFlushDeferred). }
    g_signal_connect_data(PGObject(ADelegate), 'insert-text',
      TGCallback(@Gtk4EntryDelegateInsertAfterCB), Self, nil, [G_CONNECT_AFTER]);
    g_signal_connect_data(PGObject(ADelegate), 'preedit-changed',
      TGCallback(@Gtk4EntryDelegatePreeditCB), Self, nil, G_CONNECT_DEFAULT);
    { clipboard notifications (LM_CUT/LM_COPY/LM_PASTE) come from the inner GtkText }
    g_signal_connect_data(PGObject(ADelegate), 'cut-clipboard',
      TGCallback(@Gtk4EditableCutCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(ADelegate), 'copy-clipboard',
      TGCallback(@Gtk4EditableCopyCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(ADelegate), 'paste-clipboard',
      TGCallback(@Gtk4EditablePasteCB), Self, nil, G_CONNECT_DEFAULT);
    AKeyRec := gtk4_event_controller_key_new;
    gtk_event_controller_set_propagation_phase(AKeyRec, GTK_PHASE_CAPTURE);
    g_signal_connect_data(AKeyRec, 'key-pressed',
      TGCallback(@Gtk4EntryDelegateKeyPressCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(AKeyRec, 'key-released',
      TGCallback(@Gtk4EntryDelegateKeyReleaseCB), Self, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(PGtkWidget(ADelegate), AKeyRec);
    AFocusRec := gtk4_event_controller_focus_new;
    g_signal_connect_data(AFocusRec, 'leave',
      TGCallback(@Gtk4EntryDelegateFocusLeaveCB), Self, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(PGtkWidget(ADelegate), AFocusRec);
  end;
end;

procedure TGtk4Entry.UpdateWidgetConstraints;
begin
  { Measuring GtkEntry very early can trigger unstable IM-module paths
    (seen with GTK4+fcitx during startup). Keep conservative constraints. }
  if LCLObject = nil then Exit;
  if (fParams.Height > 0) and (fParams.Height > LCLObject.Constraints.MinHeight) then
    LCLObject.Constraints.MinHeight := fParams.Height
  else if LCLObject.Constraints.MinHeight < 24 then
    LCLObject.Constraints.MinHeight := 24;
end;

procedure TGtk4Entry.SetPasswordChar(APasswordChar: Char);
var
  PWChar: Integer;
begin
  if IsWidgetOK and Gtk4IsEntry(Widget) then
  begin
    PWChar := ord(APasswordChar);
    if (PWChar < 192) or (PWChar = ord('*')) then
      PWChar := 9679;
    PGtkEntry(Widget)^.set_invisible_char(PWChar);
  end;
end;

procedure TGtk4Entry.SetNumbersOnly(ANumbersOnly:boolean);
const
  ips:array[boolean]of TGtkInputPurpose=(GTK_INPUT_PURPOSE_FREE_FORM,GTK_INPUT_PURPOSE_NUMBER);
begin
  // this is not enough for numeric input - it is just a hint for GUI
  if IsWidgetOK and Gtk4IsEntry(Widget) then
    PGtkEntry(Widget)^.set_input_purpose(ips[ANumbersOnly]);
end;

procedure TGtk4Entry.SetTextHint(const AHint: string);
begin
  { Clearing must reach the native placeholder too — the old guard
    (AHint <> '') left a stale placeholder visible after the LCL
    TextHint was set back to empty. }
  if IsWidgetOK and Gtk4IsEntry(Widget) then
  begin
    if AHint <> '' then
      PGtkEntry(Widget)^.set_placeholder_text(PgChar(AHint))
    else
      PGtkEntry(Widget)^.set_placeholder_text(nil);
  end;
end;

procedure TGtk4Entry.SetFrame(const aborder: boolean);
begin
  if IsWidgetOk and Gtk4IsEntry(Widget) then
    PGtkEntry(Widget)^.set_has_frame(aborder);
end;

function TGtk4Entry.GetTextHint:string;

begin
  if IsWidgetOK and Gtk4IsEntry(Widget) then
    Result:=PGtkEntry(Widget)^.get_placeholder_text()
  else
    Result:='';
end;

procedure TGtk4Entry.SetEchoMode(AVisible: Boolean);
begin
  if IsWidgetOK and Gtk4IsEntry(Widget) then
    PGtkEntry(Widget)^.set_visibility(AVisible);
end;

procedure TGtk4Entry.SetMaxLength(AMaxLength: Integer);
begin
  if IsWidgetOK and Gtk4IsEntry(Widget) then
  begin
    ApplyPendingSelStart; { set_max_length may truncate the text }
    PGtkEntry(Widget)^.set_max_length(AMaxLength);
    PGtkEntry(Widget)^.set_width_chars(AMaxLength);
  end;

end;

function TGtk4Entry.IsWidgetOk: Boolean;
begin
  Result := (Widget <> nil) and Gtk4IsEntry(Widget);
end;

{ TGtk4SpinEdit }

function TGtk4SpinEdit.GetMaximum: Double;
var
  AFloat: gdouble;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(Widget)^.get_range(@AFloat ,@Result);
end;

function TGtk4SpinEdit.GetMinimum: Double;
var
  AFloat: gdouble;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(Widget)^.get_range(@Result ,@AFloat);
end;

function TGtk4SpinEdit.GetNumDigits: Integer;
begin
  Result := 0;
  if IsWidgetOk then
    Result := Integer(PGtkSpinButton(Widget)^.get_digits);
end;

function TGtk4SpinEdit.GetNumeric: Boolean;
begin
  Result := False;
  if IsWidgetOk then
    Result := PGtkSpinButton(Widget)^.get_numeric;
end;

function TGtk4SpinEdit.GetStep: Double;
var
  AFloat: Double;
begin
  Result := 0;
  if IsWidgetOk then
    PGtkSpinButton(Widget)^.get_increments(@Result, @AFloat);
end;

function TGtk4SpinEdit.GetValue: Double;
begin
  Result := 0;
  if IsWidgetOk then
  begin
    ApplyPendingSelStart; { update may reformat the text }
    PGtkSpinButton(Widget)^.update;
    Result := PGtkSpinButton(Widget)^.get_value;
  end;
end;

procedure TGtk4SpinEdit.SetNumDigits(AValue: Integer);
begin
  if IsWidgetOk then
  begin
    ApplyPendingSelStart; { set_digits reformats the text }
    PGtkSpinButton(Widget)^.set_digits(GUint(AValue));
  end;
end;

procedure TGtk4SpinEdit.SetNumeric(AValue: Boolean);
begin
  if IsWidgetOk then
    PGtkSpinButton(Widget)^.set_numeric(AValue);
end;

procedure TGtk4SpinEdit.SetStep(AValue: Double);
var
  AStep: gdouble;
  APage: gdouble;
begin
  if IsWidgetOk then
  begin
    PGtkSpinButton(Widget)^.get_increments(@AStep, @APage);
    PGtkSpinButton(Widget)^.set_increments(AValue, APage);
  end;
end;

procedure TGtk4SpinEdit.SetValue(AValue: Double);
begin
  if IsWidgetOk then
  begin
    ApplyPendingSelStart; { set_value rewrites the text }
    PGtkSpinButton(Widget)^.set_value(AValue);
  end;
end;

function TGtk4SpinEdit.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ASpin: TCustomSpinEdit;
begin
  PrivateCursorPos := -1;
  PrivateSelection := -1;
  ASpin := TCustomSpinEdit(LCLObject);
  FWidgetType := FWidgetType + [wtSpinEdit];
  // Adjustment := TGtkAdjustment.new(ASpin.Value, ASpin.MinValue, ASpin.MaxValue, ASpin.Increment,
  //  ASpin.Increment, ASpin.Increment);
  Result := TGtkSpinButton.new_with_range(ASpin.MinValue, ASpin.MaxValue, ASpin.Increment);
end;

function TGtk4SpinEdit.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk4SpinEdit.IsWidgetOk: Boolean;
begin
  Result := (Widget <> nil) and Gtk4IsSpinButton(Widget);
end;

procedure TGtk4SpinEdit.SetRange(AMin, AMax: Double);
begin
  if IsWidgetOk then
  begin
    ApplyPendingSelStart; { set_range may clamp the value and rewrite the text }
    PGtkSpinButton(Widget)^.set_range(AMin, AMax);
  end;
end;

{ TGtk4Range }

procedure Gtk4RangeChanged({%H-}ARange: PGtkRange; AData: gPointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    if TGtk4Widget(AData).InUpdate then
      Exit;
    { Design mode: a click/drag on the trough changes the native GtkRange
      value; do not report it back to the LCL or the design-time Position
      would be corrupted. The designer handles the click for selection. }
    if Assigned(TGtk4Widget(AData).LCLObject) and
       (csDesigning in TGtk4Widget(AData).LCLObject.ComponentState) then
      Exit;
    FillChar(Msg{%H-}, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    TGtk4Widget(AData).DeliverMessage(Msg);
  end;
end;

function TGtk4Range.GetPosition: Integer;
var
  AAdj: PGtkAdjustment;
begin
  Result := 0;
  if not IsWidgetOK then Exit;
  { GTK4: GtkScrollbar is NOT a GtkRange — use adjustment API }
  if wtScrollBar in FWidgetType then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(Widget);
    if AAdj <> nil then Result := Round(AAdj^.get_value);
  end
  else
    Result := Round(PGtkRange(Widget)^.get_value);
end;

function TGtk4Range.GetRange: TPoint;
begin
  Result := Point(0, 0);
  if not IsWidgetOK then Exit;
  { GTK4: GtkScrollbar is NOT a GtkRange }
  if not (wtScrollBar in FWidgetType) then
    PGtkRange(Widget)^.get_slider_range(@Result.X, @Result.Y);
end;

procedure TGtk4Range.SetPosition(AValue: Integer);
var
  AAdj: PGtkAdjustment;
begin
  if not IsWidgetOK then Exit;
  if wtScrollBar in FWidgetType then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(Widget);
    if AAdj <> nil then AAdj^.set_value(gDouble(AValue));
  end
  else
    PGtkRange(Widget)^.set_value(gDouble(AValue));
end;

procedure TGtk4Range.SetRange(AValue: TPoint);
var
  dx,dy: gdouble;
begin
  if not IsWidgetOK then Exit;
  { GTK4: GtkScrollbar has no set_range equivalent }
  if not (wtScrollBar in FWidgetType) then
  begin
    dx := AValue.X;
    dy := AValue.Y;
    PGtkRange(Widget)^.set_range(dx, dy);
  end;
end;

procedure TGtk4Range.InitializeWidget;
begin
  inherited InitializeWidget;
  { GTK4: GtkScrollbar no longer inherits from GtkRange, so 'value-changed'
    signal only exists on true GtkRange widgets (GtkScale). ScrollBar handles
    its own value-changed via adjustment signal in CreateWidget. }
  if not (wtScrollBar in FWidgetType) then
    g_signal_connect_data(GetContainerWidget, 'value-changed', TGCallback(@Gtk4RangeChanged), Self, nil, G_CONNECT_DEFAULT);
end;

procedure TGtk4Range.SetStep(AStep: Integer; APageSize: Integer);
var
  AAdj: PGtkAdjustment;
begin
  if not IsWidgetOk then Exit;
  if wtScrollBar in FWidgetType then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(Widget);
    if AAdj <> nil then
    begin
      AAdj^.set_step_increment(gDouble(AStep));
      AAdj^.set_page_increment(gDouble(APageSize));
    end;
  end
  else
    PGtkRange(Widget)^.set_increments(gDouble(AStep), gDouble(APageSize));
end;

{ TGtk4TrackBar }

function TGtk4TrackBar.GetReversed: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkScale(Widget)^.get_inverted;
end;

procedure TGtk4TrackBar.SetReversed(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkScale(Widget)^.set_inverted(AValue);
end;

function TGtk4TrackBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ATrack: TCustomTrackBar;
begin
  ATrack := TCustomTrackBar(LCLObject);
  FWidgetType := FWidgetType + [wtTrackBar];

 { Result := TGtkHBox.new(1,0);
  fCentralWidget:=PGtkWidget(TGtkScale.new(Ord(ATrack.Orientation), nil));
  PgtkBox(Result)^.add(fCentralWidget);}

  Result :=PGtkWidget(TGtkScale.new(TGtkOrientation(ATrack.Orientation), nil));

  FOrientation := ATrack.Orientation;
  if ATrack.Reversed then
    PGtkScale(Result)^.set_inverted(True);
  PGtkScale(Result)^.set_digits(0);
end;

procedure TGtk4TrackBar.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  Widget^.set_size_request(AWidth,AHeight);
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

function TGtk4TrackBar.GetTrackBarOrientation: TTrackBarOrientation;
begin
  Result := FOrientation;
end;

procedure TGtk4TrackBar.SetScalePos(AValue: TTrackBarScalePos);
begin
  if IsWidgetOK then
    PGtkScale(Widget)^.set_value_pos(TGtkPositionType(AValue));
end;

procedure TGtk4TrackBar.SetTickMarks(AValue: TTickMark; ATickStyle: TTickStyle);
var
  fldw: Integer;
  i,cnt: Int64; { Int64: Max near High(Integer) must not wrap the loop/span }
  Track:TCustomTrackbar;
const
  tick_map:array[TTrackBarOrientation,0..1] of TGtkPositionType =
    ((GTK_POS_TOP,GTK_POS_BOTTOM), // trHorizontal
     (GTK_POS_LEFT,GTK_POS_RIGHT) // trVertical
    );
begin
  if IsWidgetOK then
  begin
    PGtkScale(Widget)^.set_draw_value(ATickStyle <> tsNone);
    if ATickStyle = tsNone then
      PGtkScale(Widget)^.clear_marks
    else
    begin
      PGtkScale(Widget)^.clear_marks;
      Track:=TCustomTrackbar(LCLObject);
      if Track.Frequency > 0 then
      begin
        { Place tick marks at Frequency intervals (matching Qt5 behavior) }
        if Track.Orientation=trHorizontal then
          fldw:=Track.Width
        else
          fldw:=Track.Height;
        cnt:=round(abs(Int64(Track.Max)-Int64(Track.Min))/Track.Frequency);
        { Guard: skip if marks would be too dense for the widget size.
          Compare the mark COUNT against the widget pixel size (at least
          ~1px per mark). The old test compared cnt*Frequency — the range
          span in range units — against pixels, so any range wider than
          the widget in numeric value (e.g. 0..1000 on a 420px track)
          silently drew no marks even when only a handful were due. }
        if cnt < fldw then
        begin
          i := Track.Min;
          while i <= Track.Max do
          begin
            if AValue in [tmBoth, tmTopLeft] then
              PGtkScale(Widget)^.add_mark(gDouble(i), tick_map[Track.Orientation,0], nil);
            if AValue in [tmBoth, tmBottomRight] then
              PGtkScale(Widget)^.add_mark(gDouble(i), tick_map[Track.Orientation,1], nil);
            i := i + Track.Frequency;
          end;
        end;
      end;
    end;
  end;
end;

{ TGtk4ScrollBar }

{ GTK4: GtkScrollbar no longer inherits from GtkRange.
  Must use gtk4_scrollbar_get_adjustment instead of PGtkRange cast. }

{ Adjustment value-changed for a standalone TScrollBar. Deliver the new
  position as LM_HSCROLL/LM_VSCROLL so the LCL scroll path (DoScroll) runs:
  it fires OnScroll, clamps, and updates Position (which fires OnChange) —
  matching GTK2 (Gtk2RangeScrollCB) and Qt5. Never feed the adjustment
  upper back into TScrollBar.SetParams: doing so grew LCL Max by PageSize
  on every native change (see Gtk4ScrollAdjChangedCB for the same pattern
  on scrolled windows). }
procedure Gtk4ScrollBarAdjChangedCB(AAdj: PGtkAdjustment; AData: TGtk4ScrollBar); cdecl;
var
  Msg: TLMVScroll;
  AValue, AMaxValue: gdouble;
begin
  if (AAdj = nil) or (AData = nil) then Exit;
  if not Gtk4IsLiveWidgetPointer(AData) then Exit;
  if (AData.LCLObject = nil) or AData.InUpdate then Exit;
  { Design mode: do not report native changes back or the design-time
    Position would be corrupted (same rule as Gtk4RangeChanged). }
  if csDesigning in AData.LCLObject.ComponentState then Exit;

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  if TCustomScrollBar(AData.LCLObject).Kind = sbHorizontal then
    Msg.Msg := LM_HSCROLL
  else
    Msg.Msg := LM_VSCROLL;

  AValue := AAdj^.get_value;
  if AAdj^.get_page_size > 0 then
    AMaxValue := AAdj^.get_upper - AAdj^.get_page_size
  else
    AMaxValue := AAdj^.get_upper;
  if AValue > AMaxValue then
    AValue := AMaxValue;
  if AValue < AAdj^.get_lower then
    AValue := AAdj^.get_lower;

  with Msg do
  begin
    Pos := Round(AValue);
    if Pos < High(SmallPos) then
      SmallPos := Pos
    else
      SmallPos := High(SmallPos);
    ScrollBar := HWND(AData);
    { GtkAdjustment value-changed carries no scroll-type detail (unlike
      GtkRange change-value on gtk2), so report a plain position change. }
    ScrollCode := SB_THUMBPOSITION;
  end;
  DeliverMessage(AData.LCLObject, Msg);
end;

procedure TGtk4ScrollBar.DetachEvents;
var
  AAdj: PGtkAdjustment;
begin
  { Disconnect value-changed from Adjustment (child GObject, not FWidget) }
  if IsWidgetOk then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(Widget);
    if AAdj <> nil then
      g_signal_handlers_disconnect_matched(PGObject(AAdj),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  inherited DetachEvents;
end;

function TGtk4ScrollBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AScrollbar: TCustomScrollBar;
  AAdj: PGtkAdjustment;
begin
  AScrollBar := TCustomScrollBar(LCLObject);
  FWidgetType := FWidgetType + [wtScrollBar];
  Result := TGtkScrollbar.new(TGtkOrientation(AScrollBar.Kind), nil);
  AAdj := gtk4_scrollbar_get_adjustment(Result);
  if AAdj <> nil then
    with AScrollBar do
    begin
      { upper = Max like gtk2 (gtk clamps the reachable value to
        upper - page_size). upper = Max + PageSize let the native value
        exceed the LCL maximum and snap back. }
      AAdj^.configure(Position, Min, Max,
        SmallChange, LargeChange, PageSize);
      AAdj^.set_value(Position);
      g_signal_connect_data(AAdj,
           'value-changed', TGCallback(@Gtk4ScrollBarAdjChangedCB), Self, nil, G_CONNECT_DEFAULT);
    end;
end;

procedure TGtk4ScrollBar.SetParams;
var
  AAdj: PGtkAdjustment;
begin
  if not IsWidgetOk then
    exit;
  AAdj := gtk4_scrollbar_get_adjustment(Widget);
  if AAdj = nil then Exit;
  with TCustomScrollbar(LCLObject) do
  begin
    { upper = Max like gtk2 — see CreateWidget }
    AAdj^.configure(Position, Min, Max,
      SmallChange, LargeChange, PageSize);
    AAdj^.set_value(Position);
    AAdj^.changed;
  end;
end;

{ TGtk4Calendar }

procedure Gtk4CalendarDaySelected({%H-}ACalendar: PGtkCalendar; AData: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    { Design mode: clicking a day changes the native GtkCalendar date; do not
      report it back to the LCL or the design-time Date would be corrupted. }
    if Assigned(TGtk4Calendar(AData).LCLObject) and
       (csDesigning in TGtk4Calendar(AData).LCLObject.ComponentState) then
      Exit;
    TGtk4Calendar(AData).ClampDate;
    if not TGtk4Calendar(AData).InUpdate then
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), #0);
      Msg.Msg := LM_DAYCHANGED;
      TGtk4Calendar(AData).DeliverMessage(Msg);
    end;
  end;
end;

{ Connected to notify::month — the only complete month-change hook: every
  GtkCalendar month change (arrow buttons, adjacent-month day cells, DnD,
  programmatic select_day) funnels through gtk_calendar_select_day, which
  emits notify::month (gtkcalendar.c). The prev/next-month SIGNALS fire for
  the header arrows only, so connecting those missed the other paths. }
procedure Gtk4CalendarMonthChanged({%H-}AObject: PGObject;
  {%H-}pspec: PGParamSpec; AData: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    if Assigned(TGtk4Calendar(AData).LCLObject) and
       (csDesigning in TGtk4Calendar(AData).LCLObject.ComponentState) then
      Exit;
    if not TGtk4Calendar(AData).InUpdate then
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), #0);
      Msg.Msg := LM_MONTHCHANGED;
      TGtk4Calendar(AData).DeliverMessage(Msg);
    end;
  end;
end;

{ Connected to notify::year — see Gtk4CalendarMonthChanged for why the
  property notification, not the prev/next-year arrow signals, is used. }
procedure Gtk4CalendarYearChanged({%H-}AObject: PGObject;
  {%H-}pspec: PGParamSpec; AData: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    if Assigned(TGtk4Calendar(AData).LCLObject) and
       (csDesigning in TGtk4Calendar(AData).LCLObject.ComponentState) then
      Exit;
    if not TGtk4Calendar(AData).InUpdate then
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), #0);
      Msg.Msg := LM_YEARCHANGED;
      TGtk4Calendar(AData).DeliverMessage(Msg);
    end;
  end;
end;

function TGtk4Calendar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtCalendar];
  Result := TGtkCalendar.new;
  Result^.set_can_focus(True);
  gtk4_widget_set_focusable(Result, True);
  { Connect Calendar change signals → LCL OnDayChanged/OnMonthChanged/OnYearChanged.
    Signals are on FWidget itself (no wrapper), so base DestroyWidget disconnects them. }
  g_signal_connect_data(PGObject(Result),
    'day-selected', TGCallback(@Gtk4CalendarDaySelected), Self, nil, G_CONNECT_DEFAULT);
  { GTK4 GtkCalendar has no 'month-changed' signal (GTK3 leftover;
    connecting it only produced a GLib "signal is invalid" warning).
    notify::month / notify::year are the complete replacements: every
    month/year change funnels through gtk_calendar_select_day, which emits
    them — the prev/next-month/year SIGNALS only fire for the header
    arrows and would miss adjacent-month day clicks, DnD, and programmatic
    changes. }
  g_signal_connect_data(PGObject(Result),
    'notify::month', TGCallback(@Gtk4CalendarMonthChanged), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(PGObject(Result),
    'notify::year', TGCallback(@Gtk4CalendarYearChanged), Self, nil, G_CONNECT_DEFAULT);
end;

{ GTK4 calendar dates go through GDateTime (see the compat bindings): the
  legacy binding helpers keep the GTK3 shapes — select_day(guint) passed an
  integer as a GDateTime pointer (access violation, runtime-confirmed) and
  get_date's out-params were never written. The wrapper keeps the GTK3
  ZERO-BASED month contract the WS layer already applies (+1/-1). }
procedure TGtk4Calendar.GetDate(out AYear, AMonth, ADay: LongWord);
var
  dt: PGDateTime;
begin
  AYear := 0;
  AMonth := 0;
  ADay := 0;
  if not IsWidgetOk then Exit;
  dt := gtk4_calendar_get_date(PGtkCalendar(GetContainerWidget));
  if dt = nil then Exit;
  AYear := LongWord(g_date_time_get_year(dt));
  AMonth := LongWord(g_date_time_get_month(dt) - 1); { zero-based contract }
  ADay := LongWord(g_date_time_get_day_of_month(dt));
  g_date_time_unref(dt);
end;

procedure TGtk4Calendar.SetDate(const AYear, AMonth, ADay: LongWord);
var
  dt: PGDateTime;
begin
  if not IsWidgetOK then Exit;
  dt := g_date_time_new_local(gint(AYear), gint(AMonth) + 1, gint(ADay),
    0, 0, 0);
  if dt = nil then Exit; { invalid date components }
  gtk4_calendar_select_day(PGtkCalendar(GetContainerWidget), dt);
  g_date_time_unref(dt);
end;

procedure TGtk4Calendar.SetDisplayOptions(
  const ADisplayOptions: TGtkCalendarDisplayOptions);
begin
  if IsWidgetOK then
    PGtkCalendar(GetContainerWidget)^.set_display_options(ADisplayOptions);
end;

procedure TGtk4Calendar.ClampDate;
var
  Year, Month, Day: LongWord;
  CurDate, ClampedDate: TDateTime;
  Y, M, D: Word;
begin
  if FUpdatingDate then Exit;
  if (FMinDate = 0) and (FMaxDate = 0) then Exit;
  if not IsWidgetOK then Exit;

  GetDate(Year, Month, Day);
  try
    CurDate := EncodeDate(Year, Month + 1, Day);
  except
    Exit;
  end;

  ClampedDate := CurDate;
  if (FMinDate <> 0) and (CurDate < FMinDate) then
    ClampedDate := FMinDate
  else if (FMaxDate <> 0) and (CurDate > FMaxDate) then
    ClampedDate := FMaxDate;

  if ClampedDate <> CurDate then
  begin
    FUpdatingDate := True;
    try
      DecodeDate(ClampedDate, Y, M, D);
      SetDate(Y, M - 1, D);
    finally
      FUpdatingDate := False;
    end;
  end;
end;

procedure TGtk4Calendar.SetMinMaxDate(AMinDate, AMaxDate: TDateTime);
begin
  FMinDate := AMinDate;
  FMaxDate := AMaxDate;
  { day-selected signal is always connected in CreateWidget —
    ClampDate is called from the callback when min/max are set }
  ClampDate;
end;

procedure TGtk4Calendar.RemoveMinMaxDates;
begin
  FMinDate := 0;
  FMaxDate := 0;
end;

{ TGtk4StaticText }

function TGtk4StaticText.GetAlignment: TAlignment;
var
  X: gfloat;
  Y: gfloat;
begin
  Result := taLeftJustify;
  if IsWidgetOK then
  begin
    PGtkLabel(GetContainerWidget)^.get_alignment(@X, @Y);
    if X = 1 then
      Result := taRightJustify
    else
    if X = 0.5 then
      Result := taCenter;
  end;
end;

function TGtk4StaticText.GetStaticBorderStyle: TStaticBorderStyle;
begin
  { GTK4 removed GtkFrame get_shadow_type (the old code read a removed/stubbed
    API and always returned sbsNone). Track the value we applied instead. }
  Result := FBorderStyle;
end;

procedure TGtk4StaticText.SetAlignment(AValue: TAlignment);
begin
  { GTK4: GtkMisc.set_alignment removed. Use set_xalign/set_yalign on GtkLabel. }
  if IsWidgetOk then
    PGtkLabel(GetContainerWidget)^.set_xalign(AGtkJustificationF[AValue]);
end;

procedure TGtk4StaticText.SetStaticBorderStyle(AValue: TStaticBorderStyle);
begin
  FBorderStyle := AValue;
  if not IsWidgetOK then
    exit;
  { GTK4 removed GtkFrame set_shadow_type; drive the frame border via CSS
    classes defined in TGtk4WidgetSet.LoadCSSTheme's display provider.
    sbsSingle carries no class — it keeps the theme's own frame border, which
    is consistent and theme-coloured (overriding the colour ourselves fought
    the theme and flipped light/dark with focus state). }
  gtk4_widget_remove_css_class(Widget, 'lcl-static-none');
  gtk4_widget_remove_css_class(Widget, 'lcl-static-sunken');
  case AValue of
    sbsNone: gtk4_widget_add_css_class(Widget, 'lcl-static-none');
    sbsSunken: gtk4_widget_add_css_class(Widget, 'lcl-static-sunken');
  end;
end;

function TGtk4StaticText.getText: String;
begin
  Result := '';
  if IsWidgetOk then
    Result := PGtkLabel(getContainerWidget)^.get_text;
end;

procedure TGtk4StaticText.setText(const AValue: String);
begin
  if IsWidgetOk then
    PGtkLabel(getContainerWidget)^.set_text(PgChar(AValue));
end;

function TGtk4StaticText.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AStaticText: TCustomStaticText;
begin
  FWidgetType := FWidgetType + [wtStaticText];
  AStaticText := TCustomStaticText(LCLObject);
  Result := TGtkFrame.new('');
  { GTK4: set_shadow_type removed from GtkFrame }
  FCentralWidget := TGtkLabel.new('');
  { GTK4: set_has_window removed }
  PGtkFrame(Result)^.set_label_widget(nil);
  { GTK4: gtk_container_add removed. Use gtk4_frame_set_child. }
  gtk4_frame_set_child(PGtkFrame(Result), FCentralWidget);
  { GTK4: GtkMisc.set_alignment removed. Use set_xalign on GtkLabel. }
  PGtkLabel(FCentralWidget)^.set_xalign(AGtkJustificationF[AStaticText.Alignment]);
end;

{ TGtk4ProgressBar }

function TGtk4ProgressBar.GetOrientation: TProgressBarOrientation;
var
  AOrientation: TGtkOrientation;
begin
  Result := pbHorizontal;
  if IsWidgetOk then
  begin
    AOrientation := PGtkOrientable(getContainerWidget)^.get_orientation;
    if AOrientation = GTK_ORIENTATION_HORIZONTAL then
    begin
      if PGtkProgressBar(getContainerWidget)^.get_inverted then
        Result := pbRightToLeft
      else
        Result := pbHorizontal;
    end else
    begin
      { GTK4: a non-inverted vertical progress bar grows top to bottom
        (gtkprogressbar.c set_inverted doc), so inverted = pbVertical
        (bottom to top). Mirrors SetOrientation — the old mapping here was
        swapped and read pbVertical back as pbTopDown and vice versa. }
      if PGtkProgressBar(getContainerWidget)^.get_inverted then
        Result := pbVertical
      else
        Result := pbTopDown;
    end;
  end;
end;

function TGtk4ProgressBar.GetPosition: Integer;
var
  ABar: TCustomProgressBar;
begin
  Result := 0;
  if not IsWidgetOk then Exit;
  { Map the native 0..1 fraction back through Min/Max — the inverse of
    SetPosition. Round(fraction) alone only ever yielded 0 or 1. }
  if Assigned(LCLObject) then
  begin
    ABar := TCustomProgressBar(LCLObject);
    Result := ABar.Min + Round(
      PGtkProgressBar(GetContainerWidget)^.get_fraction * (ABar.Max - ABar.Min));
  end else
    Result := Round(PGtkProgressBar(GetContainerWidget)^.get_fraction);
end;

function TGtk4ProgressBar.GetShowText: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkProgressBar(GetContainerWidget)^.get_show_text;
end;

function TGtk4ProgressBar.GetStyle: TProgressBarStyle;
begin
  Result := pbstNormal;
  if Assigned(LCLObject) and IsWidgetOk then
    Result := TCustomProgressBar(LCLObject).Style;
end;

procedure TGtk4ProgressBar.SetOrientation(AValue: TProgressBarOrientation);
begin
  if IsWidgetOk then
  begin
    case AValue of
      pbHorizontal,pbRightToLeft:
      begin
        PGtkOrientable(GetContainerWidget)^.set_orientation(GTK_ORIENTATION_HORIZONTAL);
        PGtkProgressBar(GetContainerWidget)^.set_inverted(AValue = pbRightToLeft);
      end;
      pbVertical, pbTopDown:
      begin
        PGtkOrientable(GetContainerWidget)^.set_orientation(GTK_ORIENTATION_VERTICAL);
        PGtkProgressBar(GetContainerWidget)^.set_inverted(AValue = pbVertical);
      end;
    end;
  end;
end;

procedure TGtk4ProgressBar.SetPosition(AValue: Integer);
var
  ABar: TCustomProgressBar;
  fraction: gDouble;
begin
  if not Assigned(LCLObject) or not IsWidgetOK then
    exit;
  ABar := TCustomProgressBar(LCLObject);
  if ((ABar.Max - ABar.Min) <> 0) then
    fraction := (AValue - ABar.Min) / (ABar.Max - ABar.Min)
  else
    fraction := 0;
  PGtkProgressBar(GetContainerWidget)^.set_fraction(fraction);
end;

procedure TGtk4ProgressBar.SetShowText(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkProgressBar(GetContainerWidget)^.set_show_text(AValue);
end;

function ProgressPulseTimeout(data: gpointer): gboolean; cdecl;
begin
  Result := False;
  if (data = nil) or not Gtk4IsWidget(data) then exit;
  Result := {%H-}PtrUInt(g_object_get_data(data, 'lclprogressbarstyle')) = 1;
  if Result then
    PGtkProgressBar(Data)^.pulse;
end;

procedure ProgressDestroy(data: gpointer); cdecl;
begin
  g_source_remove({%H-}PtrUInt(data));
end;

procedure TGtk4ProgressBar.SetStyle(AValue: TProgressBarStyle);
begin
  if IsWidgetOk then
  begin
    g_object_set_data(GetContainerWidget,'lclprogressbarstyle', {%H-}Pointer(PtrUInt(Ord(AValue))));
    if AValue = pbstNormal then
    begin
      { Remove the pulse timer NOW via its destroy notify (ProgressDestroy →
        g_source_remove on the still-live source). Without this the source
        dies by itself (ProgressPulseTimeout returns False on the cleared
        style flag) but the stored id stays behind, and the next marquee
        set_data_full — or widget destruction — would g_source_remove a
        stale id (GLib-CRITICAL "Source ID not found"). }
      g_object_set_data(GetContainerWidget, 'timeout', nil);
      Position := TCustomProgressBar(LCLObject).Position;
    end else
    begin
      g_object_set_data_full(GetContainerWidget, 'timeout',
        {%H-}Pointer(PtrUInt(g_timeout_add(100, @ProgressPulseTimeout, GetContainerWidget))), @ProgressDestroy);
      PGtkProgressBar(GetContainerWidget)^.pulse;
    end;
  end;
end;

{we must override preferred width since gtk4 have strange opinion about minimum width of progress bar}
procedure get_progress_preferred_width(widget: PGtkWidget; minimum_width: Pgint; natural_width: Pgint); cdecl;
var
  Handle: HWND;
begin
  Handle := HwndFromGtkWidget(Widget);
  if Handle <> 0 then
  begin
    minimum_width^ := TGtk4Widget(Handle).LCLObject.Width;
    natural_width^ := TGtk4Widget(Handle).LCLObject.Width;
  end else
  begin
    minimum_width^ := 0;
    natural_width^ := 0;
    {$IFDEF GTK4DEBUGCORE}
    DebugLn('ERROR: get_progress_preferred_width cannot find GtkWidget LCL Handle ....');
    {$ENDIF}
  end;
end;

function TGtk4ProgressBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := FWidgetType + [wtProgressBar];
  { GTK4: GtkEventBox removed. Use GtkBox as container instead. }
  Result := TGtkBox.new(GTK_ORIENTATION_VERTICAL, 0);
  FCentralWidget := TGtkProgressBar.new;
  { GTK4: Progress bar must expand to fill the GtkBox container.
    Without this, GtkProgressBar uses its minimum size from CSS. }
  FCentralWidget^.set_hexpand(True);
  FCentralWidget^.set_vexpand(True);
  gtk4_box_append(PGtkBox(Result), FCentralWidget);
  FCentralWidget^.set_can_focus(True);
  gtk4_widget_set_focusable(FCentralWidget, True);
end;

procedure TGtk4ProgressBar.InitializeWidget;
begin
  inherited InitializeWidget;
  { GTK4: Use set_size_request with both dimensions to override
    the progress bar's CSS-defined minimum size. }
  if Assigned(FCentralWidget) and Assigned(LCLObject) then
    FCentralWidget^.set_size_request(LCLObject.Width, LCLObject.Height);
end;

{ TGtk4Container }

procedure TGtk4Container.AddChild(AWidget: PGtkWidget; const ALeft, ATop: Integer);
var
  DX, DY: Integer;
begin
  if Assigned(FCentralWidget) then
  begin
    { GTK4: GtkBin removed. FCentralWidget is the GtkFixed directly.
      Same viewport-scroll pinning as TGtk4Widget.Move — a child added while
      an LCL-managed container is scrolled must not inherit the shift. }
    Gtk4ParentScrollOffset(Self, DX, DY);
    gtk4_fixed_put(PGtkFixed(FCentralWidget), AWidget, ALeft + DX, ATop + DY);
  end
  else
  begin
    { GTK4: PGtkContainer^.add removed. Use gtk_widget_set_parent as fallback. }
    AWidget^.set_parent(Widget);
  end;
end;

{ TGtk4ToolBar }

procedure TGtk4ToolBar.ClearGlyphs;
var i:integer;
begin
  if Assigned(fBmpList) then
  for i:=fBmpList.Count-1 downto 0 do
    TObject(fBmpList[i]).Free;
end;

destructor TGtk4ToolBar.Destroy;
begin
  ClearGlyphs;
  fBmpList.Free;
  inherited Destroy;
end;

procedure TGtk4ToolBar.ButtonClicked(data: gPointer);cdecl;
begin
  if TObject(data) is TToolButton then
  TToolButton(data).Click;
end;

function TGtk4ToolBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  FHasPaint := True;
  FWidgetType := [wtWidget, wtContainer];
  { Keep toolbar rendering in LCL (like GTK2/Qt5 path) instead of creating
    native GTK4 buttons once at handle creation time. This preserves dynamic
    ImageList-driven icon updates used by IDE toolbars/component palette. }
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  Result := PGtkWidget(AOverlay);
  FCentralWidget := TGtkFixed.new;
  { GTK4: GtkFixed must be targetable so hit-testing reaches the toolbar
    and mouse events propagate through the capture phase to our controller. }
  gtk4_widget_set_can_target(FCentralWidget, True);
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);

  if not Assigned(fBmpList) then
    fBmpList := TList.Create;

  ClearGlyphs;
end;

{ TGtk4Page }

procedure TGtk4Page.setText(const AValue: String);
var
  bs:string;
begin
  inherited;
  if Assigned(FPageLabel) then
  begin
    bs:=ReplaceAmpersandsWithUnderscores(Avalue);
    FPageLabel^.set_markup_with_mnemonic(PChar(bs));
  end;
end;

function TGtk4Page.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := FWidgetType + [wtContainer];
  { Tab widget: a box containing optional image + label }
  FTabBox := PGtkBox(gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4));
  FPageLabel := TGtkLabel.new(PChar(Params.Caption));
  FPageLabel^.set_use_underline(True);
  FTabImage := nil;
  gtk4_box_append(FTabBox, PGtkWidget(FPageLabel));
  Self.FHasPaint := True;
  // ref it to save it in case TabVisible is set to false
  PGtkWidget(FTabBox)^.ref;
  Result := PGtkWidget(gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0));
  FCentralWidget := TGtkFixed.new;
  { Tag FCentralWidget so LCLGtkFixedSnapshot can find the TGtk4Page owner
    and call GtkEventPaint → PaintControls for TGraphicControl children
    (e.g. TImage on a TTabSheet). }
  g_object_set_data(PGObject(FCentralWidget), 'lclwidget', Self);
  { GTK4: GtkFixed has zero natural size when it has no GTK children (only
    TGraphicControl children like TImage). Without expand, GtkBoxLayout
    allocates natural_width=0 → LCLGtkFixedSnapshot skips painting.
    Set expand so GtkFixed fills the entire GtkBox cell. }
  FCentralWidget^.set_hexpand(True);
  FCentralWidget^.set_vexpand(True);
  { GTK4: pack_start removed. Use gtk4_box_append. }
  gtk4_box_append(PGtkBox(Result), FCentralWidget);
end;

procedure TGtk4Page.DestroyWidget;
var
  AParent: PGtkWidget;
  AAncestor: PGtkWidget;
  AOwnByNotebookStack: Boolean;
  ALevel: Integer;
begin
  AParent := nil;
  if (FWidget <> nil) and Gtk4IsWidget(FWidget) and (not FWidget^.in_destruction) then
    AParent := FWidget^.get_parent;
  AOwnByNotebookStack := False;
  AAncestor := AParent;
  ALevel := 0;
  while (AAncestor <> nil) and (ALevel < 6) do
  begin
    if Gtk4IsNoteBook(AAncestor) then
    begin
      AOwnByNotebookStack := True;
      Break;
    end;
    if Get3WidgetClassName(AAncestor) = 'GtkStack' then
    begin
      AOwnByNotebookStack := True;
      Break;
    end;
    AAncestor := AAncestor^.get_parent;
    Inc(ALevel);
  end;
  if AOwnByNotebookStack then
    FOwnWidget := False;
  // unref the tab box (which owns the label and optional image)
  if (FTabBox <> nil) and Gtk4IsWidget(PGtkWidget(FTabBox)) then
    PGtkWidget(FTabBox)^.unref;
  inherited DestroyWidget;
end;

procedure TGtk4Page.UpdateTabImage;
var
  APage: TCustomPage;
  ATabCtl: TCustomTabControl;
  AImageList: TCustomImageList;
  AImageIndex: Integer;
  ABmp: TBitmap;
  APixbuf: PGdkPixbuf;
begin
  if not IsWidgetOK then Exit;
  APage := TCustomPage(LCLObject);
  if (APage = nil) or (APage.Parent = nil) then Exit;
  ATabCtl := TCustomTabControl(APage.Parent);
  AImageList := ATabCtl.Images;
  AImageIndex := ATabCtl.GetImageIndex(APage.PageIndex);

  if Assigned(AImageList) and (AImageIndex >= 0) and (AImageIndex < AImageList.Count) then
  begin
    ABmp := TBitmap.Create;
    try
      AImageList.GetBitmap(AImageIndex, ABmp);
      if ABmp.HandleAllocated then
      begin
        APixbuf := Gtk4BitmapToPixbuf(ABmp);
        if APixbuf <> nil then
        begin
          if FTabImage = nil then
          begin
            FTabImage := TGtkImage.new_from_pixbuf(APixbuf);
            { Insert image before the label (prepend) }
            gtk4_box_prepend(FTabBox, PGtkWidget(FTabImage));
          end else
            FTabImage^.set_from_pixbuf(APixbuf);
          g_object_unref(APixbuf);
        end;
      end;
    finally
      ABmp.Free;
    end;
  end else
  begin
    { No valid image — remove the image widget if it exists }
    if FTabImage <> nil then
    begin
      gtk4_box_remove(FTabBox, PGtkWidget(FTabImage));
      FTabImage := nil;
    end;
  end;
end;

function TGtk4Page.getClientRect: TRect;
begin
  Result := inherited getClientRect;
end;

{ TGtk4NoteBook }

function NotebookPageRealToLCLIndex(const ATabControl: TCustomTabControl; AIndex: integer): integer;
var
  I: Integer;
  PageCnt: Integer;
begin
  if ATabControl = nil then
    Exit(AIndex);
  Result := AIndex;
  if csDesigning in ATabControl.ComponentState then exit;
  if csDestroying in ATabControl.ComponentState then exit;
  PageCnt := ATabControl.PageCount;
  if PageCnt <= 0 then
    Exit(AIndex);
  I := 0;
  while (I < PageCnt) and (I <= Result) do
  begin
    if (I < ATabControl.PageCount) and (ATabControl.Page[I] <> nil)
      and (not ATabControl.Page[I].TabVisible) then
      Inc(Result);
    Inc(I);
  end;
end;

procedure GtkNotebookAfterSwitchPage(widget: PGtkWidget; {%H-}page: PGtkWidget; pagenum: integer; data: gPointer); cdecl;
var
  ACtl: TGtk4Widget;
  ATabControl: TCustomTabControl;
  Mess: TLMNotify;
  NMHdr: tagNMHDR;
  LCLPageIndex: Integer;
begin
  if widget=nil then ;
  if not Gtk4IsLiveWidgetPointer(Data) then
    Exit;
  ACtl := TGtk4Widget(Data);
  if (not ACtl.CanSendLCLMessage) or ACtl.InUpdate then
    exit;
  if (pagenum < 0) or (not (ACtl.LCLObject is TCustomTabControl)) then
    Exit;
  ATabControl := TCustomTabControl(ACtl.LCLObject);
  if csDestroying in ATabControl.ComponentState then
    Exit;
  {page is deleted}
 { DebugLn('GtkNotebookAfterSwitchPage ');
  if TGtk4NoteBook(Data).getPagesCount < TCustomTabControl(TGtk4NoteBook(Data).LCLObject).PageCount then
  begin
    DebugLn('GtkNotebookAfterSwitchPage PageIsDeleted');
    exit;
  end;}
  FillChar(Mess{%H-}, SizeOf(Mess), 0);
  Mess.Msg := LM_NOTIFY;
  FillChar(NMHdr{%H-}, SizeOf(NMHdr), 0);
  NMHdr.code := TCN_SELCHANGE;
  NMHdr.hwndFrom := HWND(ACtl);
  LCLPageIndex := NotebookPageRealToLCLIndex(ATabControl, pagenum);  //use this to set pageindex to the correct page.
  NMHdr.idFrom := LCLPageIndex;
  Mess.NMHdr := @NMHdr;
  ACtl.DeliverMessage(Mess);
end;

function BackNoteBookSignal(AData: Pointer): gboolean; cdecl;
var
  AWidget: PGtkNotebook;
  {$IFDEF GTK4DEBUGCORE}
  APageNum: PtrInt;
  {$ENDIF}
begin
  Result := False;
  AWidget := AData;
  if not Gtk4IsWidget(AWidget) then
    exit;
  if g_object_get_data(AWidget,'switch-page-signal-stopped') <> nil then
  begin
    Result := True;
    {$IFDEF GTK4DEBUGCORE}
    APageNum := {%H-}PtrInt(g_object_get_data(AWidget,'switch-page-signal-stopped'));
    DebugLn('BackNoteBookSignal back notebook switch-page signal currpage=',dbgs(AWidget^.get_current_page),' blockedPage ',dbgs(APageNum));
    {$ENDIF}
    g_object_set_data(AWidget,'switch-page-signal-stopped', nil);
  end;
  { Result=False → GLib removes idle source; Result=True → re-call until flag cleared }
end;

procedure GtkNotebookSwitchPage(widget: PGtkWidget; {%H-}page: PGtkWidget; pagenum: integer; data: gPointer); cdecl;
var
  ACtl: TGtk4Widget;
  ATabControl: TCustomTabControl;
  Mess: TLMNotify;
  NMHdr: tagNMHDR;
begin
  if not Gtk4IsLiveWidgetPointer(Data) then
    Exit;
  ACtl := TGtk4Widget(Data);
  if (not ACtl.CanSendLCLMessage) or ACtl.InUpdate then
    exit;
  if (widget = nil) or (pagenum < 0) or (not (ACtl.LCLObject is TCustomTabControl)) then
    Exit;
  ATabControl := TCustomTabControl(ACtl.LCLObject);
  if csDestroying in ATabControl.ComponentState then
    Exit;

  {$IFDEF GTK4DEBUGCORE}
  DebugLn('GtkNotebookSwitchPage Data ',dbgHex({%H-}PtrUInt(Data)),' Realized ',dbgs(Widget^.get_realized),' pageNum=',dbgs(pageNum));
  {$ENDIF}

  {page is deleted}
 { c1:=TGtk4NoteBook(Data).getPagesCount;
  c2:=TCustomTabControl(TGtk4NoteBook(Data).LCLObject).PageCount;
  if c1 < c2 then
  begin
    DebugLn('GtkNotebookSwitchPage PageIsDeleted ');
    exit;
  end;}

  FillChar(Mess{%H-}, SizeOf(Mess), 0);
  Mess.Msg := LM_NOTIFY;
  FillChar(NMHdr{%H-}, SizeOf(NMHdr), 0);
  NMHdr.code := TCN_SELCHANGING;
  NMHdr.hwndFrom := HWND(ACtl);
  NMHdr.idFrom := NotebookPageRealToLCLIndex(ATabControl, pagenum);  //use this to set pageindex to the correct page.
  Mess.NMHdr := @NMHdr;
  Mess.Result := 0;
  ACtl.DeliverMessage(Mess);
  if Mess.Result <> 0 then
  begin
    g_object_set_data(Widget,'switch-page-signal-stopped', GPointer(PtrUInt(pageNum)));
    g_signal_stop_emission_by_name(PGObject(Widget), 'switch-page');
    // GtkNotebookAfterSwitchPage(Widget, page, pagenum, data);
    g_idle_add(@BackNoteBookSignal, Widget);
    Exit;
  end;
end;

function TGtk4NoteBook.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := FWidgetType + [wtNotebook];
  { GTK4: GtkNotebook is placed directly in GtkFixed (no GtkBox wrapper).
    A GtkBox wrapper causes GtkBoxLayout to re-allocate the notebook at
    its intrinsic minimum on subsequent layout passes, overriding our
    LCLFixedLayoutAllocate patch that constrains children to set_size_request. }
  Result := PGtkWidget(TGtkNotebook.new);
  PGtkNoteBook(Result)^.set_scrollable(True);
  if (nboHidePageListPopup in TCustomTabControl(LCLObject).Options) then
    PGtkNoteBook(Result)^.popup_disable;
  PGtkNoteBook(Result)^.show;

  g_signal_connect_data(Result,'switch-page', TGCallback(@GtkNotebookSwitchPage), Self, nil, G_CONNECT_DEFAULT);
  // this one triggers after above switch-page
  g_signal_connect_data(Result,'switch-page', TGCallback(@GtkNotebookAfterSwitchPage), Self, nil, G_CONNECT_DEFAULT);
end;

procedure TGtk4NoteBook.DestroyWidget;
begin
  FDestroyingNotebook := True;
  inherited DestroyWidget;
end;

procedure TGtk4NoteBook.DetachEvents;
begin
  FDestroyingNotebook := True;
  if (FWidget <> nil) and Gtk4IsWidget(FWidget) then
    g_signal_handlers_disconnect_matched(PGObject(FWidget),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  inherited DetachEvents;
end;

procedure TGtk4NoteBook.InitializeWidget;
begin
  inherited;
  SetTabPosition(TCustomTabControl(LCLObject).TabPosition);
end;

function TGtk4NoteBook.GetClientAreaOffset: TPoint;
var
  TabBarChild: PGtkWidget;
  TabBarH: gint;
begin
  { Client area (the page/stack region) starts below the tab bar — same
    measurement as getClientRect.  Without this offset, ControlAtPos maps
    hit-test points one tab-bar height too high and misses page content
    (e.g. component palette buttons never receive hints).
    Only handled for top tabs (the getClientRect math has the same
    assumption); other positions keep the previous (0,0) behaviour.
    NO 37px fallback here (unlike getClientRect): when the tab bar is not
    mapped — hidden tabs (ShowTabs=False) or pre-realize — the offset must
    be 0, or hidden-tab notebooks would hit-test 37px too low. }
  Result := Point(0, 0);
  if PGtkNoteBook(GetContainerWidget)^.get_tab_pos <> GTK_POS_TOP then
    Exit;
  TabBarH := 0;
  TabBarChild := gtk4_widget_get_first_child(GetContainerWidget);
  if (TabBarChild <> nil) and TabBarChild^.get_mapped then
    TabBarH := TabBarChild^.get_allocated_height;
  if TabBarH > 0 then
    Result := Point(0, TabBarH);
end;

function TGtk4NoteBook.getClientRect: TRect;
var
  NB: PGtkWidget;
  NBW, NBH: gint;
  TabBarChild: PGtkWidget;
  TabBarH: gint;
begin
  { Compute client rect from notebook allocation minus the tab bar height.
    Do NOT use the current page's allocation — that creates a feedback loop:
    page set_size_request drives GtkStack minimum, which then inflates
    the page allocation reported back, preventing proper shrinking.
    Instead, measure the tab bar (first internal child of GtkNotebook)
    and subtract it from the notebook's allocation. This matches how
    native GTK4 notebooks divide space: tab_bar + stack = total height. }
  NB := GetContainerWidget;
  NBW := NB^.get_allocated_width;
  NBH := NB^.get_allocated_height;

  { The first child of GtkNotebook is the tab bar (a GtkBox) }
  TabBarH := 0;
  TabBarChild := gtk4_widget_get_first_child(NB);
  if (TabBarChild <> nil) and TabBarChild^.get_mapped then
    TabBarH := TabBarChild^.get_allocated_height;

  { Fallback when tab bar hasn't been realized/mapped yet }
  if TabBarH <= 0 then
    TabBarH := 37; { reasonable GTK4 default }

  Result := Rect(0, 0, Max(0, NBW), Max(0, NBH - TabBarH));
end;

function TGtk4NoteBook.getPagesCount: integer;
begin
  Result := 0;
  if IsWidgetOk then
    Result := PGtkNoteBook(GetContainerWidget)^.get_n_pages;
end;

procedure EnumerateChildren(ANotebook: PGtkNoteBook);
var
  AList: PGList;
  i: Integer;
  AWidget: PGtkWidget;
  AMinimumH, ANaturalH, ANaturalW, AMinimumW: gint;
begin
  AList := ANoteBook^.get_children;
  for i := 0 to g_list_length(AList) - 1 do
  begin
    AWidget := PGtkWidget(g_list_nth_data(AList, I));
    { GTK4: get_preferred_width/height removed. Use gtk_widget_measure. }
    gtk4_widget_measure(AWidget, GTK_ORIENTATION_VERTICAL, -1, @AMinimumH, @ANaturalH, nil, nil);
    gtk4_widget_measure(AWidget, GTK_ORIENTATION_HORIZONTAL, -1, @AMinimumW, @ANaturalW, nil, nil);
    DebugLn(Format('Child[%d] MinH %d NatH %d MinW %d NatW %d ALLOCW %d ALLOCH %d child_type %s',
      [I, AMinimumH, ANaturalH, AMinimumW, ANaturalW,
      AWidget^.get_allocated_width, AWidget^.get_allocated_height, g_type_name(ANotebook^.child_type)]));
  end;
  g_list_free(AList);
end;

procedure TGtk4NoteBook.InsertPage(ACustomPage: TCustomPage; AIndex: Integer);
var
  Gtk4Page: TGtk4Page;
begin
  if IsWidgetOK then
  begin
    Gtk4Page := TGtk4Page(ACustomPage.Handle);
    with PGtkNoteBook(GetContainerWidget)^ do begin
      insert_page(Gtk4Page.Widget, PGtkWidget(Gtk4Page.FTabBox), AIndex);
      // Check why this give sometimes: Gtk-WARNING: Negative content width -1 (allocation 1, extents 1x1) while allocating gadget (node notebook, owner GtkNotebook)
      resize_children;
    end;
  end;
end;

procedure TGtk4NoteBook.MovePage(ACustomPage: TCustomPage; ANewIndex: Integer);
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.reorder_child(TGtk4Widget(ACustomPage.Handle).Widget, ANewIndex);
end;

procedure TGtk4NoteBook.RemovePage(AIndex: Integer; AExpectedChild: PGtkWidget);
var
  AMinSizeW, AMinSizeH, ANaturalSizeW, ANaturalSizeH: gint;
  NB: PGtkNotebook;
  AChild: PGtkWidget;
  PageCount, ARemoveIndex: Integer;
  procedure TraceSkip(const AReason: String);
  begin
    DebugLn(Format('[GTK4-TRACE][NB.RemovePage] SKIP reason=%s lcl=%s index=%d expected=%p widget=%p',
      [AReason, dbgsName(LCLObject), AIndex, Pointer(AExpectedChild), Pointer(FWidget)]));
  end;
begin
  if FDestroyingNotebook then
  begin
    TraceSkip('destroying-flag');
    Exit;
  end;
  if (LCLObject = nil) or (csDestroying in LCLObject.ComponentState) then
  begin
    TraceSkip('lcl-destroying');
    Exit;
  end;
  if Assigned(Application) and Application.Terminated then
  begin
    TraceSkip('app-terminated');
    Exit;
  end;
  if IsWidgetOK then
  begin
    NB:=PGtkNotebook(GetContainerWidget);
    if NB = nil then
    begin
      TraceSkip('nb-nil');
      Exit;
    end;
    if NB^.in_destruction then
    begin
      TraceSkip('nb-in-destruction');
      Exit;
    end;
    DebugLn(Format('[GTK4-TRACE][NB.RemovePage] ENTER lcl=%s index=%d expected=%p pages=%d nb=%p',
      [dbgsName(LCLObject), AIndex, Pointer(AExpectedChild), NB^.get_n_pages, Pointer(NB)]));
    ARemoveIndex := AIndex;
    if AExpectedChild <> nil then
    begin
      if (not Gtk4IsWidget(AExpectedChild)) or AExpectedChild^.in_destruction then
      begin
        TraceSkip('expected-invalid-or-destroying');
        Exit;
      end;
      if AExpectedChild^.get_parent <> PGtkWidget(NB) then
      begin
        DebugLn(Format('[GTK4-TRACE][NB.RemovePage] PARENT-MISMATCH expected=%p parent=%p nb=%p',
          [Pointer(AExpectedChild), Pointer(AExpectedChild^.get_parent), Pointer(NB)]));
        TraceSkip('expected-parent-mismatch');
        Exit;
      end;
      ARemoveIndex := NB^.page_num(AExpectedChild);
      if ARemoveIndex < 0 then
      begin
        TraceSkip('expected-page-num-negative');
        Exit;
      end;
      AChild := AExpectedChild;
    end
    else
    begin
      PageCount := NB^.get_n_pages;
      if (AIndex < 0) or (AIndex >= PageCount) then
      begin
        TraceSkip('index-out-of-range');
        Exit;
      end;
      AChild := NB^.get_nth_page(AIndex);
      if (AChild = nil) or (AChild^.get_parent = nil) then
      begin
        TraceSkip('child-or-parent-nil');
        Exit;
      end;
      if AChild^.in_destruction then
      begin
        TraceSkip('child-in-destruction');
        Exit;
      end;
      if AChild^.get_parent <> PGtkWidget(NB) then
      begin
        DebugLn(Format('[GTK4-TRACE][NB.RemovePage] INDEX-CHILD-PARENT-MISMATCH child=%p parent=%p nb=%p',
          [Pointer(AChild), Pointer(AChild^.get_parent), Pointer(NB)]));
        TraceSkip('index-child-parent-mismatch');
        Exit;
      end;
    end;
    DebugLn(Format('[GTK4-TRACE][NB.RemovePage] CALL remove_page idx=%d child=%p parent=%p nb=%p',
      [ARemoveIndex, Pointer(AChild), Pointer(AChild^.get_parent), Pointer(NB)]));
    NB^.remove_page(ARemoveIndex);
    { GTK4: get_preferred_width/height removed. Use gtk_widget_measure. }
    gtk4_widget_measure(PGtkWidget(NB), GTK_ORIENTATION_HORIZONTAL, -1, @AMinSizeW, @ANaturalSizeW, nil, nil);
    gtk4_widget_measure(PGtkWidget(NB), GTK_ORIENTATION_VERTICAL, -1, @AMinSizeH, @ANaturalSizeH, nil, nil);
    NB^.resize_children;
  end;
end;

procedure TGtk4NoteBook.SetPageIndex(AIndex: Integer);
begin
  if IsWidgetOK then
  begin
    PGtkNotebook(GetContainerWidget)^.set_current_page(AIndex);
  end;
end;

procedure TGtk4NoteBook.SetShowTabs(const AShowTabs: Boolean);
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.set_show_tabs(AShowTabs);
end;

procedure TGtk4NoteBook.SetTabPosition(const ATabPosition: TTabPosition);
const
  GtkPositionTypeMap: array[TTabPosition] of TGtkPositionType =
  (
    { tpTop    } GTK_POS_TOP,
    { tpBottom } GTK_POS_BOTTOM,
    { tpLeft   } GTK_POS_LEFT,
    { tpRight  } GTK_POS_RIGHT
  );
begin
  if IsWidgetOK then
    PGtkNoteBook(GetContainerWidget)^.set_tab_pos(GtkPositionTypeMap[ATabPosition]);
end;

procedure TGtk4NoteBook.SetTabLabelText(AChild: TCustomPage; const AText: String);
begin
  if IsWidgetOK then
    TGtk4Widget(AChild.Handle).setText(AText);
end;

function TGtk4NoteBook.GetTabLabelText(AChild: TCustomPage): String;
begin
  if IsWidgetOK then
    Result := TGtk4Widget(AChild.Handle).getText
  else
    Result := '';
end;

{ TGtk4MenuShell - GTK4: GMenu model based }

var
  Gtk4MenuItemCounter: Integer = 0;

constructor TGtk4MenuShell.Create(const AMenu: TMenu; AExistingWidget: PGtkWidget);
begin
  inherited Create;
  MenuObject := AMenu;
  FCentralWidget := nil;
  if AExistingWidget <> nil then
  begin
    { Wrapping an existing widget (e.g. form's PopoverMenuBar).
      The model and action group will be set by the caller (WS layer).
      Don't create our own — they'd just leak. }
    FOwnWidget := False;
    FWidget := AExistingWidget;
    FMenuModel := nil;
    FActionGroup := nil;
  end else
  begin
    { Creating a new menu (e.g. popup menu). Create our own model/group. }
    FOwnWidget := True;
    FMenuModel := PGMenu(g_menu_new);
    FActionGroup := g_simple_action_group_new;
  end;
  InitializeWidget;
end;

procedure TGtk4MenuShell.InitializeWidget;
begin
  if FOwnWidget then
    FWidget := CreateWidget(FParams);

  { For wrapped external widgets (main menu bar owned by TGtk4Window),
    avoid storing Self as destroy callback data to prevent stale-pointer calls
    after wrapper destruction. }
  if (FWidget <> nil) and FOwnWidget then
    g_signal_connect_data(FWidget, 'destroy', TGCallback(@TGtk4Widget.destroy_event), Self, nil, G_CONNECT_DEFAULT);
  LCLIntf.SetProp(HWND(Self),'lclwidget',Self);
end;

destructor TGtk4MenuShell.Destroy;
begin
  { Only free model/action group if we own them (popup menus).
    For main menus, these belong to the TGtk4Window. }
  if FOwnWidget then
  begin
    if FMenuModel <> nil then
    begin
      if Gtk4IsObject(PGObject(FMenuModel)) then
        g_object_unref(FMenuModel);
      FMenuModel := nil;
    end;
    if FActionGroup <> nil then
    begin
      if Gtk4IsObject(PGObject(FActionGroup)) then
        g_object_unref(FActionGroup);
      FActionGroup := nil;
    end;
  end;
  inherited Destroy;
end;


{ TGtk4MenuBar - GTK4: uses GtkPopoverMenuBar }

function TGtk4MenuBar.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtMenuBar];
  Result := gtk4_popover_menu_bar_new_from_model(PGMenuModel(FMenuModel));
  { Install action group on the menu bar widget so actions are found }
  gtk_widget_insert_action_group(Result, PgChar('menu'), PGActionGroup(FActionGroup));
end;

{ TGtk4Menu - GTK4: uses GtkPopoverMenu for popup menus }

function TGtk4Menu.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtMenu];
  Result := gtk4_popover_menu_new_from_model(PGMenuModel(FMenuModel));
  gtk4_popover_set_has_arrow(Result, False);
  gtk_widget_insert_action_group(Result, PgChar('menu'), PGActionGroup(FActionGroup));
end;

{ TGtk4MenuItem - GTK4: GMenuItem + GSimpleAction pair }

function TGtk4MenuItem.GetCaption: string;
begin
  if MenuItem <> nil then
    Result := MenuItem.Caption
  else
    Result := '';
end;

procedure TGtk4MenuItem.SetCaption(const AValue: string);
begin
  { GTK4: GMenu is immutable per-item. To change label, we'd need to
    rebuild the menu model. For now, store and rebuild on next attach. }
  if MenuItem <> nil then
    MenuItem.Caption := AValue;
end;

function TGtk4MenuItem.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  { GTK4: Menu items are not widgets. We don't create a GtkWidget here.
    Instead, GMenuItem objects are inserted into GMenu models.
    Return nil - the "handle" for a menu item is the TGtk4MenuItem object itself. }
  Result := nil;
  FWidgetType := [wtWidget, wtMenuItem];
end;

{ State value for a radio menu item's string-state action: the GMenuItem
  target is the fixed 'on', so 'on' marks the item toggled and '' clears it. }
function Gtk4RadioMenuStateValue(AChecked: Boolean): PgChar;
begin
  if AChecked then
    Result := 'on'
  else
    Result := '';
end;

{ Build a checked-state variant matching the ACTION's actual state type.
  TMenuItem.RadioItem can be flipped at runtime: the LCL setter changes the
  sibling FRadioItem fields directly and only recreates SELF's handle, so a
  sibling can be RadioItem=True in the LCL while still owning the boolean
  action created earlier — deciding the variant type from the LCL flag would
  send a mismatched type. }
function Gtk4MenuCheckStateVariant(AAction: PGSimpleAction; AChecked: Boolean): PGVariant;
var
  StateType: PGVariantType;
begin
  StateType := g_action_get_state_type(PGAction(AAction));
  if (StateType <> nil) and
     (g_variant_type_peek_string(StateType)^ = 's') then
    Result := g_variant_new_string(Gtk4RadioMenuStateValue(AChecked))
  else
    Result := g_variant_new_boolean(AChecked);
end;

constructor TGtk4MenuItem.Create(const AMenuItem: TMenuItem);
var
  ALabel: string;
  RadioType: PGVariantType;
begin
  inherited Create;
  MenuItem := AMenuItem;
  FOwnWidget := False; { No widget to own }
  Lock := 0;

  { Generate unique action name }
  Inc(Gtk4MenuItemCounter);
  FActionName := 'item-' + IntToStr(Gtk4MenuItemCounter);

  { Create GSimpleAction for this menu item }
  if AMenuItem.Caption = cLineCaption then
  begin
    { Separator - no action needed }
    FAction := nil;
    FGMenuItem := nil;
  end
  else if AMenuItem.RadioItem then
  begin
    { Radio items need a STRING-state action plus a target on the menu
      item: GtkMenuTrackerItem assigns ROLE_RADIO (radio dot) only when
      the item carries a target and the action is stateful, with
      toggled = (state == target); a boolean state renders a CHECK mark
      (gtkmenutrackeritem.c). The parameter type must match the target
      type or the tracker disables the item. Exclusivity stays LCL-driven
      (per-item actions, sibling sync in SetCheck), so the target is a
      fixed 'on' and unchecked items hold ''. }
    RadioType := g_variant_type_new('s');
    FAction := g_simple_action_new_stateful(
      PgChar(FActionName), RadioType,
      g_variant_new_string(Gtk4RadioMenuStateValue(AMenuItem.Checked)));
    g_variant_type_free(RadioType);
    g_simple_action_set_enabled(FAction, AMenuItem.Enabled);
  end
  else if AMenuItem.IsCheckItem then
  begin
    { Stateful boolean action for check items }
    FAction := g_simple_action_new_stateful(
      PgChar(FActionName), nil,
      g_variant_new_boolean(AMenuItem.Checked));
    g_simple_action_set_enabled(FAction, AMenuItem.Enabled);
  end
  else
  begin
    { Normal action }
    FAction := g_simple_action_new(PgChar(FActionName), nil);
    g_simple_action_set_enabled(FAction, AMenuItem.Enabled);
  end;
  if (FAction <> nil) and Gtk4IsObject(PGObject(FAction)) then
    g_object_set_data(PGObject(FAction), 'lcl-menuitem', AMenuItem);

  { Create GMenuItem }
  if AMenuItem.Caption = cLineCaption then
  begin
    { Separator: represented as a section boundary in GMenu }
    FGMenuItem := nil;
  end
  else
  begin
    ALabel := ReplaceAmpersandsWithUnderscores(AMenuItem.Caption);
    FGMenuItem := g_menu_item_new(PgChar(ALabel), PgChar('menu.' + FActionName));
    { Keep our own strong reference. The menu model API may consume/unref
      temporary items when inserting them into a GMenu. }
    if (FGMenuItem <> nil) and Gtk4IsObject(PGObject(FGMenuItem)) then
    begin
      { Radio items: attach the fixed target so the menu tracker assigns
        the radio role (see the action comment above). }
      if AMenuItem.RadioItem then
        g_menu_item_set_action_and_target_value(FGMenuItem,
          PgChar('menu.' + FActionName), g_variant_new_string('on'));
      g_object_ref(PGObject(FGMenuItem));
      { GTK4 menu accelerator parsing can hit regex assertions if accel is NULL.
        Keep it initialized and let SetShortCut overwrite it when needed. }
      g_menu_item_set_attribute_value(FGMenuItem, 'accel',
        g_variant_new_string(''));
    end;
  end;

  FSubMenu := nil;

  InitializeWidget;
end;

destructor TGtk4MenuItem.Destroy;
begin
  if FAction <> nil then
  begin
    if Gtk4IsObject(PGObject(FAction)) then
    begin
      g_signal_handlers_disconnect_matched(PGObject(FAction), [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
      g_object_set_data(PGObject(FAction), 'lcl-menuitem', nil);
    end;
  end;
  if FSubMenu <> nil then
  begin
    if Gtk4IsObject(PGObject(FSubMenu)) then
      g_object_unref(PGObject(FSubMenu));
    FSubMenu := nil;
  end;
  if FGMenuItem <> nil then
  begin
    if Gtk4IsObject(PGObject(FGMenuItem)) then
      g_object_unref(PGObject(FGMenuItem));
    FGMenuItem := nil;
  end;
  if FAction <> nil then
  begin
    if Gtk4IsObject(PGObject(FAction)) then
      g_object_unref(PGObject(FAction));
    FAction := nil;
  end;
  inherited Destroy;
end;

{ GAction 'activate' callback - dispatches LM_ACTIVATE to the LCL TMenuItem }
procedure Gtk4MenuActionActivated({%H-}action: PGSimpleAction;
  {%H-}parameter: PGVariant; user_data: gpointer); cdecl;
var
  Msg: TLMessage;
  LCLMenuItem: TMenuItem;
begin
  LCLMenuItem := nil;
  if (action <> nil) and Gtk4IsObject(PGObject(action)) then
    LCLMenuItem := TMenuItem(g_object_get_data(PGObject(action), 'lcl-menuitem'));
  if Assigned(LCLMenuItem) and not (csDestroying in LCLMenuItem.ComponentState) then
  begin
    FillChar(Msg{%H-}, SizeOf(Msg), #0);
    Msg.Msg := LM_ACTIVATE;
    LCLMenuItem.Dispatch(Msg);
  end;
  if user_data = nil then ;
end;

{ GAction 'change-state' callback for check/radio items }
procedure Gtk4MenuActionChangeState({%H-}action: PGSimpleAction;
  value: PGVariant; user_data: gpointer); cdecl;
var
  LCLMenuItem: TMenuItem;
begin
  { Do NOT blindly accept GTK's proposed toggle: the LCL owns check/radio
    state (gtk2 parity — the native indicator must mirror
    TMenuItem.Checked). Dispatch the click first (LM_ACTIVATE → Click,
    which applies AutoCheck / runs OnClick and reaches WS SetCheck when
    Checked changes), then force the native state to the LCL truth. This
    keeps an item whose OnClick leaves Checked unchanged from drifting
    (previously the indicator toggled natively while the LCL state did
    not). set_state does not re-emit change-state, so no recursion. }
  if action = nil then Exit;
  { Hold a ref across the dispatch: the click handler may free the menu
    item, whose destructor unrefs the action — probing a possibly-freed
    GObject afterwards would itself be use-after-free. Our ref keeps the
    object alive; the destructor clears the 'lcl-menuitem' data first,
    which is the reliable signal to skip the post-dispatch sync. }
  g_object_ref(PGObject(action));
  try
    Gtk4MenuActionActivated(action, nil, user_data);
    LCLMenuItem := TMenuItem(g_object_get_data(PGObject(action), 'lcl-menuitem'));
    if Assigned(LCLMenuItem) and not (csDestroying in LCLMenuItem.ComponentState) then
      g_simple_action_set_state(action,
        Gtk4MenuCheckStateVariant(action, LCLMenuItem.Checked));
  finally
    g_object_unref(PGObject(action));
  end;
  if value = nil then ;
end;

procedure TGtk4MenuItem.InitializeWidget;
begin
  { GTK4: Menu items are NOT widgets. Do NOT call SetProp — it triggers
    GetWidget which loops forever since FWidget is nil.
    Just connect the GAction 'activate' signal. }
  if FAction <> nil then
  begin
    if MenuItem.IsCheckItem or MenuItem.RadioItem then
      g_signal_connect_data(FAction, 'change-state',
        TGCallback(@Gtk4MenuActionChangeState), Self, nil, G_CONNECT_DEFAULT)
    else
      g_signal_connect_data(FAction, 'activate',
        TGCallback(@Gtk4MenuActionActivated), nil, nil, G_CONNECT_DEFAULT);
  end;
end;

procedure TGtk4MenuItem.SetCheck(ACheck: boolean);
var
  i: Integer;
  Sibling: TMenuItem;
begin
  if (FAction <> nil) and (Lock = 0) then
  begin
    Inc(Lock);
    try
      { The variant type must match the ACTION's state type — see
        Gtk4MenuCheckStateVariant for why the LCL RadioItem flag alone
        cannot decide it. }
      g_simple_action_set_state(FAction,
        Gtk4MenuCheckStateVariant(FAction, ACheck));
    finally
      Dec(Lock);
    end;
    { Radio group: LCL TurnSiblingsOff only clears the siblings' FChecked
      field and never calls WS SetCheck for them — gtk2/qt5 get away with
      that through native radio grouping (GtkRadioMenuItem/QActionGroup).
      Our per-item boolean actions have no native grouping, so sync the
      sibling action states here or their indicators stay stale
      (runtime-confirmed: both radio actions read true after switching). }
    if ACheck and (MenuItem <> nil) and MenuItem.RadioItem and
       (MenuItem.Parent <> nil) then
    begin
      for i := 0 to MenuItem.Parent.Count - 1 do
      begin
        Sibling := MenuItem.Parent.Items[i];
        if (Sibling <> MenuItem) and Sibling.RadioItem and
           (Sibling.GroupIndex = MenuItem.GroupIndex) and
           Sibling.HandleAllocated then
          TGtk4MenuItem(Sibling.Handle).SetCheck(False);
      end;
    end;
  end;
end;

{ Push the LCL Checked state of every radio item in this item's group onto
  its native action. Called from RegroupMenuItem after LCL SetGroupIndex ran
  TurnSiblingsOff — which clears sibling FChecked DIRECTLY without any WS
  SetCheck, so a merged sibling's native action would otherwise stay stale
  ('on' while the LCL says unchecked → two radio dots in one group). LCL has
  already enforced exactly-one-checked, so each item's own Checked is
  authoritative; set states directly (no sibling cascade). }
procedure TGtk4MenuItem.SyncGroupToLCL;
var
  i: Integer;
  Item: TMenuItem;
  ItemGtk: TGtk4MenuItem;
begin
  if (MenuItem = nil) or (MenuItem.Parent = nil) then Exit;
  for i := 0 to MenuItem.Parent.Count - 1 do
  begin
    Item := MenuItem.Parent.Items[i];
    if Item.RadioItem and (Item.GroupIndex = MenuItem.GroupIndex) and
       Item.HandleAllocated and (TObject(Item.Handle) is TGtk4MenuItem) then
    begin
      ItemGtk := TGtk4MenuItem(Item.Handle);
      if (ItemGtk.FAction <> nil) and (ItemGtk.Lock = 0) then
      begin
        Inc(ItemGtk.Lock);
        try
          g_simple_action_set_state(ItemGtk.FAction,
            Gtk4MenuCheckStateVariant(ItemGtk.FAction, Item.Checked));
        finally
          Dec(ItemGtk.Lock);
        end;
      end;
    end;
  end;
end;

procedure TGtk4MenuItem.SetEnabled(AEnabled: boolean);
begin
  if FAction <> nil then
    g_simple_action_set_enabled(FAction, AEnabled);
end;


{ TGtk4ScrollableWin}

function TGtk4ScrollableWin.GetHScrollBarPolicy: TGtkPolicyType;
var
  AScrollWin: PGtkScrolledWindow;
  APolicy: TGtkPolicyType;
begin
  Result := GTK_POLICY_AUTOMATIC;
  AScrollWin := getScrolledWindow;
  if not Gtk4IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@Result, @APolicy);
end;

function TGtk4ScrollableWin.GetVScrollBarPolicy: TGtkPolicyType;
var
  AScrollWin: PGtkScrolledWindow;
  APolicy: TGtkPolicyType;
begin
  Result := GTK_POLICY_AUTOMATIC;
  AScrollWin := getScrolledWindow;
  if not Gtk4IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicy, @Result);
end;

procedure TGtk4ScrollableWin.SetBorderStyle(AValue: TBorderStyle);
begin
  if FBorderStyle=AValue then Exit;
  FBorderStyle:=AValue;
  { GTK4: set_shadow_type removed from GtkScrolledWindow.
    Use CSS border instead (same approach as TGtk4Widget.SetBorderStyle). }
  inherited SetBorderStyle(AValue);
end;

procedure TGtk4ScrollableWin.SetHScrollBarPolicy(AValue: TGtkPolicyType);
var
  AScrollWin: PGtkScrolledWindow;
  APolicyH, APolicyV: TGtkPolicyType;
begin
  AScrollWin := getScrolledWindow;
  if not Gtk4IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicyH, @APolicyV);
  if APolicyH <> AValue then
    AScrollWin^.set_policy(AValue, APolicyV);
end;

procedure TGtk4ScrollableWin.SetVScrollBarPolicy(AValue: TGtkPolicyType);
var
  AScrollWin: PGtkScrolledWindow;
  APolicyH, APolicyV: TGtkPolicyType;
begin
  AScrollWin := getScrolledWindow;
  if not Gtk4IsScrolledWindow(AScrollWin) then
    exit;
  AScrollWin^.get_policy(@APolicyH, @APolicyV);
  if APolicyV <> AValue then
    AScrollWin^.set_policy(APolicyH, AValue);
end;

function Gtk4RangeScrollCB(ARange: PGtkRange; AScrollType: TGtkScrollType;
  AValue: gdouble; AData: TGtk4Widget): gboolean; cdecl;
var
  Msg: TLMVScroll;
  MaxValue: gdouble;
  Widget: PGtkWidget;
  StateFlags: TGtkStateFlags;
begin
  Result := False;

  Widget := PGTKWidget(ARange);
  {$IFDEF SYNSCROLLDEBUG}
  DebugLn(Format('Trace:[Gtk4RangeScrollCB] Value: %d', [RoundToInt(AValue)]),' IsHScrollBar ',dbgs(PGtkOrientable(ARange)^.get_orientation = GTK_ORIENTATION_HORIZONTAL));
  {$ENDIF}
  if PGtkOrientable(ARange)^.get_orientation = GTK_ORIENTATION_HORIZONTAL then
    Msg.Msg := LM_HSCROLL
  else
    Msg.Msg := LM_VSCROLL;

  if ARange^.adjustment^.page_size > 0 then
    MaxValue := ARange^.adjustment^.upper - ARange^.adjustment^.page_size
  else
    MaxValue := ARange^.adjustment^.upper;

  if (AValue > MaxValue) then
    AValue := MaxValue
  else if (AValue < ARange^.adjustment^.lower) then
    AValue := ARange^.adjustment^.lower;

  with Msg do
  begin
    Pos := Round(AValue);
    if Pos < High(SmallPos) then
      SmallPos := Pos
    else
      SmallPos := High(SmallPos);
    { ScrollBar HWND is not used by LCL scroll handlers (TControlScrollBar.ScrollHandler).
      Passing parent widget handle for API compatibility. }
    ScrollBar := HWND(AData);
    ScrollCode := Gtk4ScrollTypeToScrollCode(AScrollType);
  end;
  DeliverMessage(AData.LCLObject, Msg);

  if Msg.Scrollcode = SB_THUMBTRACK then
  begin
    StateFlags := Widget^.get_state_flags;
    if not (GTK_STATE_FLAG_ACTIVE in StateFlags) then
    begin
      Msg.ScrollCode := SB_THUMBPOSITION;
      DeliverMessage(AData.LCLObject, Msg);
      Msg.ScrollCode := SB_ENDSCROLL;
      DeliverMessage(AData.LCLObject, Msg);
    end;
  end else
    Widget^.set_state_flags([GTK_STATE_FLAG_ACTIVE], True);

  if (AData.LCLObject is TScrollingWinControl) and
  ((Msg.ScrollCode=SB_LINEUP) or (Msg.ScrollCode=SB_LINEDOWN)) then
    Result:=True;
end;

{ Re-apply the LCL client coordinates of every windowed child so that
  TGtk4Widget.Move recomputes the GtkFixed position with the current
  adjustment value. Used by LCL-managed scrolled containers after a native
  adjustment change (see Gtk4ParentScrollOffset). }
procedure Gtk4RepinScrolledChildren(AWinControl: TWinControl);
var
  i: Integer;
  Child: TControl;
begin
  for i := 0 to AWinControl.ControlCount - 1 do
  begin
    Child := AWinControl.Controls[i];
    if (Child is TWinControl) and TWinControl(Child).HandleAllocated then
      TGtk4Widget(TWinControl(Child).Handle).Move(Child.Left, Child.Top);
  end;
end;

procedure Gtk4ScrollAdjChangedCB(AAdj: PGtkAdjustment; AData: TGtk4ScrollableWin); cdecl;
var
  Msg: TLMVScroll;
  HBar, VBar: PGtkScrollbar;
  HAdj, VAdj: PGtkAdjustment;
  AValue, AMaxValue: gdouble;
begin
  if (AAdj = nil) or (AData = nil) then Exit;
  if not Gtk4IsLiveWidgetPointer(AData) then Exit;
  if (AData.LCLObject = nil) or AData.InUpdate then Exit;

  HBar := AData.getHorizontalScrollbar;
  VBar := AData.getVerticalScrollbar;
  if HBar <> nil then
    HAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(HBar))
  else
    HAdj := nil;
  if VBar <> nil then
    VAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(VBar))
  else
    VAdj := nil;

  if AAdj = HAdj then
    Msg.Msg := LM_HSCROLL
  else if AAdj = VAdj then
    Msg.Msg := LM_VSCROLL
  else
    Exit;

  AValue := AAdj^.get_value;
  AMaxValue := AAdj^.get_upper - AAdj^.get_page_size;
  if AValue > AMaxValue then
    AValue := AMaxValue;
  if AValue < AAdj^.get_lower then
    AValue := AAdj^.get_lower;

  with Msg do
  begin
    Pos := Round(AValue);
    if Pos < High(SmallPos) then
      SmallPos := Pos
    else
      SmallPos := High(SmallPos);
    ScrollBar := HWND(AData);
    ScrollCode := SB_THUMBTRACK;
  end;

  DeliverMessage(AData.LCLObject, Msg);

  { LCL-managed scrolled containers (see Gtk4ParentScrollOffset): the
    viewport physically shifted all GtkFixed children with this adjustment
    change, but LCL semantics keep TCustomControl children at their client
    coordinates. Re-apply each child's LCL position so the placement
    compensation picks up the new adjustment value. }
  if Gtk4IsLiveWidgetPointer(AData) and (AData is TGtk4CustomControl) and
     not (AData is TGtk4ScrollingWinControl) and
     Assigned(AData.LCLObject) then
    Gtk4RepinScrolledChildren(AData.LCLObject);
end;

procedure TGtk4ScrollableWin.DetachEvents;
var
  sb: PGtkScrollbar;
  AAdj: PGtkAdjustment;
begin
  { Disconnect adjustment value-changed signals (connected to child GObjects,
    not FWidget). These would fire with stale Self during widget destruction. }
  sb := getHorizontalScrollbar;
  if sb <> nil then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(sb));
    if AAdj <> nil then
      g_signal_handlers_disconnect_matched(PGObject(AAdj),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  sb := getVerticalScrollbar;
  if sb <> nil then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(sb));
    if AAdj <> nil then
      g_signal_handlers_disconnect_matched(PGObject(AAdj),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  inherited DetachEvents;
end;

procedure TGtk4ScrollableWin.SetScrollBarsSignalHandlers;
var
  sb: PGtkScrollbar;
  AAdj: PGtkAdjustment;
begin
  { GTK4 scrollbars do not provide GtkRange "change-value"; connect to their
    GtkAdjustment "value-changed" signal instead. }
  FBorderStyle := bsNone;
  sb := getHorizontalScrollbar;
  if sb <> nil then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(sb));
    if AAdj <> nil then
      g_signal_connect_data(AAdj, 'value-changed',
        TGCallback(@Gtk4ScrollAdjChangedCB), Self, nil, G_CONNECT_DEFAULT);
  end;
  sb := getVerticalScrollbar;
  if sb <> nil then
  begin
    AAdj := gtk4_scrollbar_get_adjustment(PGtkWidget(sb));
    if AAdj <> nil then
      g_signal_connect_data(AAdj, 'value-changed',
        TGCallback(@Gtk4ScrollAdjChangedCB), Self, nil, G_CONNECT_DEFAULT);
  end;
end;

function TGtk4ScrollableWin.getClientBounds: TRect;
var
  Allocation: TGtkAllocation;
begin
  { 0-based inner rect (see TGtk4Widget.getClientBounds): Left/Top are the
    content offset, not the viewport's parent-relative position. }
  Result := Rect(0, 0, 0, 0);
  if IsWidgetOK then
  begin
    getContainerWidget^.get_allocation(@Allocation);
    Result := Rect(0, 0, Allocation.width, Allocation.height);
  end;
end;

{ GtkTextBuffer "insert-text" callback for Memo MaxLength and CharCase enforcement }
procedure Gtk4MemoBufferInsertText(buffer: PGtkTextBuffer; location: PGtkTextIter;
  new_text: PgChar; new_text_length: gint; Data: gpointer); cdecl;
var
  AMemo: TGtk4Memo;
  AEdit: TCustomEdit;
  CurrentCharCount, NewCharCount, AllowedChars: gint;
  ATruncEnd: PgChar;
  ATruncLen: gint;
  AConverted: String;
  ATextStr: String;
begin
  if (Data = nil) or not Gtk4IsLiveWidgetPointer(Data) then Exit;
  AMemo := TGtk4Memo(Data);
  if not AMemo.CanSendLCLMessage then
    Exit;
  AEdit := TCustomEdit(AMemo.LCLObject);

  { MaxLength enforcement }
  if AEdit.MaxLength > 0 then
  begin
    CurrentCharCount := buffer^.get_char_count;
    NewCharCount := g_utf8_strlen(new_text, new_text_length);
    if CurrentCharCount + NewCharCount > AEdit.MaxLength then
    begin
      AllowedChars := AEdit.MaxLength - CurrentCharCount;
      if AllowedChars <= 0 then
      begin
        g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
        Exit;
      end;
      { Truncate to allowed number of UTF-8 characters }
      ATruncEnd := g_utf8_offset_to_pointer(new_text, AllowedChars);
      ATruncLen := ATruncEnd - new_text;
      g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
      buffer^.insert(location, new_text, ATruncLen);
      Exit;
    end;
  end;

  { CharCase enforcement }
  case AEdit.CharCase of
    ecUpperCase:
    begin
      ATextStr := Copy(new_text, 1, new_text_length);
      AConverted := UpperCase(ATextStr);
      if AConverted <> ATextStr then
      begin
        g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
        buffer^.insert(location, PgChar(AConverted), Length(AConverted));
      end;
    end;
    ecLowerCase:
    begin
      ATextStr := Copy(new_text, 1, new_text_length);
      AConverted := LowerCase(ATextStr);
      if AConverted <> ATextStr then
      begin
        g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
        buffer^.insert(location, PgChar(AConverted), Length(AConverted));
      end;
    end;
  end;
end;

{ TGtk4Memo }

function TGtk4Memo.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AMemo: TCustomMemo;
  ABuffer: PGtkTextBuffer;
  AScrollStyle: TGtkScrollStyle;
begin
  FScrollX := 0;
  FScrollY := 0;
  FWantReturns := True;

  FKeysToEat := [];
  AMemo := TCustomMemo(LCLObject);

  FWidgetType := FWidgetType + [wtMemo, wtScrollingWin];
  Result := PGtkScrolledWindow(PGtkScrolledWindow(gtk4_scrolled_window_new));

  FCentralWidget := PGtkTextView(TGtkTextView.new);

  { GTK4: set_has_window removed }

  if AMemo.WordWrap then
    PGtkTextView(FCentralWidget)^.set_wrap_mode(GTK_WRAP_WORD)
  else
    PGtkTextView(FCentralWidget)^.set_wrap_mode(GTK_WRAP_NONE);

  ABuffer := PGtkTextBuffer^.new(PGtkTextTagTable^.new);
  ABuffer^.set_text(PgChar(AMemo.Text), -1);
  PGtkTextView(FCentralWidget)^.set_buffer(ABuffer);

  { GTK4: gtk_container_add removed. Use gtk4_scrolled_window_set_child. }
  gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), FCentralWidget);

  AScrollStyle := Gtk4TranslateScrollStyle(AMemo.ScrollBars);

  // Gtk4 GtkTextView is weird. When scrollbars policy is GTK_POLICY_NONE
  // then GtkTextView resizes itself (resizes parent) while adding text,
  PGtkScrolledWindow(Result)^.set_policy(AScrollStyle.Horizontal, AScrollStyle.Vertical);

  { GTK4: set_shadow_type removed from GtkScrolledWindow }
  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);

  FCentralWidget^.set_can_focus(True);
  gtk4_widget_set_focusable(FCentralWidget, True);
  { GTK4 focus model: leave can_focus=True (default) on ScrolledWindow so
    descendants can be focused.  See TGtk4CustomControl.CreateWidget comment. }
end;

procedure TGtk4Memo.DetachEvents;
var
  ABuffer: PGtkTextBuffer;
begin
  { Disconnect 'insert-text' signal from PGtkTextBuffer (not FWidget).
    Without this, the callback fires with stale Self during widget destruction. }
  if (FCentralWidget <> nil) and Gtk4IsWidget(FCentralWidget) then
  begin
    ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
    if ABuffer <> nil then
      g_signal_handlers_disconnect_matched(PGObject(ABuffer),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  inherited DetachEvents;
end;

{ ---- Memo IM commit-order repair (deferral only) ----------------------------
  Unlike GtkText (whose TARGET-phase handling consumes printable presses before
  the bubble-phase LCL key controller — which is why the ENTRY derives its key
  events from the delegate's insert-text), GtkTextView lets key presses reach
  the LCL bubble controller FIRST: empirically the GtkEventKey character block
  already delivers OnKeyPress/UTF8KeyPress (form KeyPreview included) for every
  typed memo character, including Enter (#13), and OnKeyPress consumption
  already blocks the native insertion. So the memo needs NO event delivery
  here; adding one double-fires every accepted character. What the memo does
  share with the entry is the fcitx5-gtk4 commit-ordering defect ("한글이 " ->
  "한글 이" — reproduced in a pure-C GtkTextView), so only the commit-order
  DEFERRAL is hooked on the buffer: a record-only capture key controller
  remembers the pending key's character, and an insertion equal to it while a
  preedit is active is deferred until the commit lands (same discriminator and
  flush triggers as the entry; flushed inserts pass through silently — their
  key event was already delivered by the bubble path at press time). }

function Gtk4MemoKeyRecPressCB({%H-}controller: PGtkEventController;
  keyval: guint; {%H-}keycode: guint; state: TGdkModifierType;
  user_data: gpointer): gboolean; cdecl;
var
  AMemo: TGtk4Memo;
  UChar: guint32;
begin
  Result := False; { record only — never consume, never disturb the IM }
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  AMemo := TGtk4Memo(user_data);
  AMemo.FKeyPending := state * [GDK_CONTROL_MASK, GDK_MOD1_MASK] = [];
  AMemo.FPendingKeyText := '';
  AMemo.FBubbleReplacePending := False;  { new press invalidates any recording }
  if AMemo.FKeyPending then
  begin
    UChar := gdk_keyval_to_unicode(keyval);
    if (UChar >= 32) and (UChar <> 127) and (UChar < $110000) then
      AMemo.FPendingKeyText := UnicodeToUTF8(UChar);
  end;
end;

procedure Gtk4MemoKeyRecReleaseCB({%H-}controller: PGtkEventController;
  {%H-}keyval: guint; {%H-}keycode: guint; {%H-}state: TGdkModifierType;
  user_data: gpointer); cdecl;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  TGtk4Memo(user_data).FKeyPending := False;
  TGtk4Memo(user_data).FPendingKeyText := '';
end;

procedure Gtk4MemoFlushDeferred(AMemo: TGtk4Memo; buffer: PGtkTextBuffer;
  location: PGtkTextIter);
var
  S: string;
begin
  S := AMemo.FDeferredText;
  if S = '' then exit;
  AMemo.FDeferredText := '';
  AMemo.FFlushingDeferred := True;
  try
    if location <> nil then
      { inside the commit's insert-text AFTER handler: location has been
        revalidated to the end of the inserted text, so the deferred raw key
        lands right after the commit }
      buffer^.insert(location, PgChar(S), Length(S))
    else
    begin
      { fallback (preedit cleared / focus leave): insert at the caret }
      buffer^.begin_user_action;
      try
        buffer^.insert_at_cursor(PgChar(S), Length(S));
      finally
        buffer^.end_user_action;
      end;
    end;
  finally
    AMemo.FFlushingDeferred := False;
  end;
end;

procedure Gtk4MemoPreeditCB({%H-}w: PGtkWidget; preedit: Pgchar;
  user_data: gpointer); cdecl;
var
  AMemo: TGtk4Memo;
  ABuffer: PGtkTextBuffer;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  AMemo := TGtk4Memo(user_data);
  if preedit = nil then
    AMemo.FPreeditText := ''
  else
    AMemo.FPreeditText := string(preedit);
  if (AMemo.FPreeditText = '') and (AMemo.FDeferredText <> '') then
  begin
    ABuffer := PGtkTextView(AMemo.FCentralWidget)^.get_buffer;
    if ABuffer <> nil then
      Gtk4MemoFlushDeferred(AMemo, ABuffer, nil);
  end;
end;

procedure Gtk4MemoInsertDeferCB(buffer: PGtkTextBuffer;
  location: PGtkTextIter; new_text: PgChar; new_text_length: gint;
  Data: gpointer); cdecl;
var
  AMemo: TGtk4Memo;
  InStr: string;
begin
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  AMemo := TGtk4Memo(Data);
  if AMemo.FSuppressInsertFeedback then exit;
  if AMemo.FFlushingDeferred then exit;  { flushed text passes untouched }
  if (new_text = nil) or (new_text_length <= 0) then exit;
  if not AMemo.FKeyPending then exit;    { not key input (paste etc.) }

  SetString(InStr, new_text, new_text_length);

  { an OnKeyPress handler replaced the character during the bubble delivery
    (recorded in GtkEventKey) — the view is inserting the ORIGINAL key, swap
    in the replacement }
  if AMemo.FBubbleReplacePending then
  begin
    AMemo.FBubbleReplacePending := False;
    if (InStr = AMemo.FBubbleReplaceFrom) and (AMemo.FBubbleReplaceTo <> '') then
    begin
      g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
      AMemo.FSuppressInsertFeedback := True;
      try
        { the MaxLength/CharCase handler still runs for this re-insert }
        buffer^.insert(location, PgChar(AMemo.FBubbleReplaceTo),
          Length(AMemo.FBubbleReplaceTo));
      finally
        AMemo.FSuppressInsertFeedback := False;
      end;
      exit;
    end;
  end;

  if AMemo.FPreeditText = '' then exit;

  { a raw-key bypass insertion racing ahead of the pending IM commit -- defer
    it (same discriminator as the entry: only the pending physical key's own
    character, never a commit) }
  if (InStr = AMemo.FPendingKeyText) and (InStr <> AMemo.FPreeditText) then
  begin
    AMemo.FDeferredText := AMemo.FDeferredText + InStr;
    g_signal_stop_emission_by_name(PGObject(buffer), 'insert-text');
  end;
end;

procedure Gtk4MemoInsertAfterCB(buffer: PGtkTextBuffer;
  location: PGtkTextIter; {%H-}new_text: PgChar; {%H-}new_text_length: gint;
  Data: gpointer); cdecl;
begin
  { AFTER handler: never runs for stopped emissions; an accepted insert during
    composition is the IM commit — flush the deferred raw key right after it }
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  if TGtk4Memo(Data).FSuppressInsertFeedback then exit;
  if TGtk4Memo(Data).FFlushingDeferred then exit;
  if TGtk4Memo(Data).FDeferredText = '' then exit;
  Gtk4MemoFlushDeferred(TGtk4Memo(Data), buffer, location);
end;

procedure Gtk4MemoFocusLeaveCB({%H-}controller: PGtkEventController;
  user_data: gpointer); cdecl;
var
  ABuffer: PGtkTextBuffer;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  if TGtk4Memo(user_data).FDeferredText = '' then exit;
  ABuffer := PGtkTextView(TGtk4Memo(user_data).FCentralWidget)^.get_buffer;
  if ABuffer <> nil then
    Gtk4MemoFlushDeferred(TGtk4Memo(user_data), ABuffer, nil);
end;

procedure TGtk4Memo.InitializeWidget;
var
  ABuffer: PGtkTextBuffer;
  AKeyRec, AFocusRec: PGtkEventController;
begin
  inherited InitializeWidget;
  ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
  if ABuffer <> nil then
  begin
    g_signal_connect_data(ABuffer, 'insert-text',
      TGCallback(@Gtk4MemoBufferInsertText), Self, nil, G_CONNECT_DEFAULT);
    { IM commit-order deferral (key events for typed memo text come from the
      bubble-phase key path, not from here — see the comment block above) }
    g_signal_connect_data(ABuffer, 'insert-text',
      TGCallback(@Gtk4MemoInsertDeferCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(ABuffer, 'insert-text',
      TGCallback(@Gtk4MemoInsertAfterCB), Self, nil, [G_CONNECT_AFTER]);
  end;
  g_signal_connect_data(PGObject(FCentralWidget), 'preedit-changed',
    TGCallback(@Gtk4MemoPreeditCB), Self, nil, G_CONNECT_DEFAULT);
  { clipboard notifications (LM_CUT/LM_COPY/LM_PASTE) from the GtkTextView }
  g_signal_connect_data(PGObject(FCentralWidget), 'cut-clipboard',
    TGCallback(@Gtk4EditableCutCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(PGObject(FCentralWidget), 'copy-clipboard',
    TGCallback(@Gtk4EditableCopyCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(PGObject(FCentralWidget), 'paste-clipboard',
    TGCallback(@Gtk4EditablePasteCB), Self, nil, G_CONNECT_DEFAULT);
  AKeyRec := gtk4_event_controller_key_new;
  gtk_event_controller_set_propagation_phase(AKeyRec, GTK_PHASE_CAPTURE);
  g_signal_connect_data(AKeyRec, 'key-pressed',
    TGCallback(@Gtk4MemoKeyRecPressCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AKeyRec, 'key-released',
    TGCallback(@Gtk4MemoKeyRecReleaseCB), Self, nil, G_CONNECT_DEFAULT);
  gtk4_widget_add_controller(FCentralWidget, AKeyRec);
  AFocusRec := gtk4_event_controller_focus_new;
  g_signal_connect_data(AFocusRec, 'leave',
    TGCallback(@Gtk4MemoFocusLeaveCB), Self, nil, G_CONNECT_DEFAULT);
  gtk4_widget_add_controller(FCentralWidget, AFocusRec);
end;

function TGtk4Memo.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk4Memo.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk4Memo.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk4Memo.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

function TGtk4Memo.GetAlignment: TAlignment;
var
  AJustification: TGtkJustification;
begin
  Result := taLeftJustify;
  if IsWidgetOk then
  begin
    AJustification := PGtkTextView(GetContainerWidget)^.get_justification;
    if AJustification = GTK_JUSTIFY_RIGHT then
      Result := taRightJustify
    else
    if AJustification = GTK_JUSTIFY_CENTER then
      Result := taCenter;
  end;
end;

function TGtk4Memo.GetReadOnly: Boolean;
begin
  Result := True;
  if IsWidgetOk then
    Result := not PGtkTextView(GetContainerWidget)^.get_editable;
end;

function TGtk4Memo.GetWantTabs: Boolean;
begin
  Result := False;
  if IsWidgetOK then
    Result := PGtkTextView(GetContainerWidget)^.get_accepts_tab;
end;

function TGtk4Memo.GetWordWrap: Boolean;
begin
  Result := True;
  if IsWidgetOk then
    Result := PGtkTextView(GetContainerWidget)^.get_wrap_mode = GTK_WRAP_WORD;
end;

procedure TGtk4Memo.SetAlignment(AValue: TAlignment);
begin
  if IsWidgetOk then
    PGtkTextView(GetContainerWidget)^.set_justification(AGtkJustification[AValue]);
end;

procedure TGtk4Memo.SetReadOnly(AValue: Boolean);
begin
  if IsWidgetOk then
    PGtkTextView(GetContainerWidget)^.set_editable(not AValue);
end;

procedure TGtk4Memo.SetWantTabs(AValue: Boolean);
begin
  if IsWidgetOK then
    PGtkTextView(GetContainerWidget)^.set_accepts_tab(AValue);
end;

procedure TGtk4Memo.SetWordWrap(AValue: Boolean);
begin
  if IsWidgetOk then
  begin
    if AValue then
      PGtkTextView(GetContainerWidget)^.set_wrap_mode(GTK_WRAP_WORD)
    else
      PGtkTextView(GetContainerWidget)^.set_wrap_mode(GTK_WRAP_NONE);
  end;
end;

function TGtk4Memo.getText: String;
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
  ALastIter: TGtkTextIter;
begin
  Result := '';
  if IsWidgetOk then
  begin
    ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
    ABuffer^.get_start_iter(@AIter);
    ABuffer^.get_end_iter(@ALastIter);
    Result := ABuffer^.get_text(@AIter, @ALastIter, False);
  end;
end;

procedure TGtk4Memo.setText(const AValue: String);
var
  ABuffer: PGtkTextBuffer;
  AIter: PGtkTextIter;
begin
  if IsWidgetOk then
  begin
    ABuffer := PGtkTextView(FCentralWidget)^.get_buffer;
    { programmatic text must not fire OnKeyPress via the buffer insert hook }
    FSuppressInsertFeedback := True;
    try
      ABuffer^.set_text(PgChar(AValue), -1);
    finally
      FSuppressInsertFeedback := False;
    end;
    AIter:=nil;
    ABuffer^.get_start_iter(AIter);
    ABuffer^.place_cursor(AIter);
  end;
end;

{ TGtk4ListBox }

procedure Gtk4ListBoxSelectionChanged({%H-}ASelection: PGtkTreeSelection; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  if not TGtk4Widget(AData).InUpdate then
    TGtk4Widget(AData).DeliverMessage(Msg, False);
end;

{ GtkListView factory callbacks for ListBox }

procedure Gtk4LB_FactorySetup({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  ALabel: PGtkWidget;
begin
  ALabel := gtk_label_new(nil);
  gtk_label_set_xalign(PGtkLabel(ALabel), 0.0);
  gtk_widget_set_halign(ALabel, GTK_ALIGN_FILL);
  gtk4_list_item_set_child(listitem, ALabel);
end;

procedure Gtk4LB_FactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  ALabel: PGtkWidget;
  AItem: PGtkStringObject;
  AText: PChar;
begin
  ALabel := gtk4_list_item_get_child(listitem);
  AItem := PGtkStringObject(gtk4_list_item_get_item(listitem));
  if AItem <> nil then
  begin
    AText := gtk4_string_object_get_string(AItem);
    gtk_label_set_text(PGtkLabel(ALabel), AText);
  end;
end;

procedure Gtk4LB_SelectionChanged({%H-}model: Pointer;
  {%H-}position: guint; {%H-}n_items: guint; user_data: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if (user_data = nil) or not Gtk4IsLiveWidgetPointer(user_data) then Exit;
  { Design mode: clicking an item changes the native selection; do not report
    it as a selection change or the design-time ItemIndex would be corrupted.
    The designer handles the click for selecting the list control itself. }
  if Assigned(TGtk4Widget(user_data).LCLObject) and
     (csDesigning in TGtk4Widget(user_data).LCLObject.ComponentState) then
    Exit;
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_SELCHANGE;
  if not TGtk4Widget(user_data).InUpdate then
    TGtk4Widget(user_data).DeliverMessage(Msg, False);
end;

{ GtkListView factory callbacks for CheckListBox }

procedure Gtk4CLB_FactorySetup({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  ABox, ACheck, ALabel: PGtkWidget;
begin
  ABox := gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
  ACheck := gtk_check_button_new;
  gtk4_box_append(PGtkBox(ABox), ACheck);
  ALabel := gtk_label_new(nil);
  gtk_label_set_xalign(PGtkLabel(ALabel), 0.0);
  gtk_widget_set_hexpand(ALabel, True);
  PGtkLabel(ALabel)^.set_ellipsize(PANGO_ELLIPSIZE_END);
  gtk4_box_append(PGtkBox(ABox), ALabel);
  gtk4_list_item_set_child(listitem, ABox);
end;

procedure Gtk4CLB_CheckToggled(check: PGtkCheckButton; user_data: gpointer); cdecl;
var
  AListBox: TGtk4CheckListBox;
  APosition: guint;
  Msg: TLMessage;
begin
  AListBox := TGtk4CheckListBox(g_object_get_data(PGObject(check), 'lcl-listbox'));
  APosition := guint(PtrUInt(g_object_get_data(PGObject(check), 'lcl-position')));
  if (AListBox = nil) or not Gtk4IsLiveWidgetPointer(AListBox) then Exit;
  if not AListBox.IsWidgetOk then Exit;
  if AListBox.InUpdate then Exit;
  { Design mode: do not flip the item's checked state — the designer owns
    the click (component selection). }
  if Assigned(AListBox.LCLObject) and
     (csDesigning in AListBox.LCLObject.ComponentState) then
    Exit;

  TCustomCheckListBox(AListBox.LCLObject).Toggle(APosition);

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  Msg.WParam := APosition;
  DeliverMessage(AListBox.LCLObject, Msg);
end;

procedure Gtk4CLB_FactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  ABox, ACheck, ALabel: PGtkWidget;
  AItem: PGtkStringObject;
  AText: PChar;
  APosition: guint;
  AListBox: TGtk4CheckListBox;
  AState: TCheckBoxState;
  AEnabled: Boolean;
  ACheckListBox: TCustomCheckListBox;
begin
  if (user_data = nil) or not Gtk4IsLiveWidgetPointer(user_data) then Exit;
  ABox := gtk4_list_item_get_child(listitem);
  ACheck := gtk4_widget_get_first_child(ABox);
  ALabel := gtk4_widget_get_next_sibling(ACheck);
  APosition := gtk4_list_item_get_position(listitem);
  AListBox := TGtk4CheckListBox(user_data);

  { Bind text }
  AItem := PGtkStringObject(gtk4_list_item_get_item(listitem));
  if AItem <> nil then
  begin
    AText := gtk4_string_object_get_string(AItem);
    gtk_label_set_text(PGtkLabel(ALabel), AText);
  end;

  { Bind check state }
  ACheckListBox := TCustomCheckListBox(AListBox.LCLObject);
  if Integer(APosition) < ACheckListBox.Items.Count then
  begin
    AState := ACheckListBox.State[APosition];
    AEnabled := ACheckListBox.ItemEnabled[APosition];

    { Block signal during programmatic set }
    g_signal_handlers_block_matched(ACheck,
      [G_SIGNAL_MATCH_FUNC], 0, 0, nil, @Gtk4CLB_CheckToggled, nil);
    gtk4_check_button_set_active(PGtkCheckButton(ACheck), AState = cbChecked);
    g_object_set(ACheck, 'inconsistent', [gboolean(AState = cbGrayed), nil]);
    gtk_widget_set_sensitive(ACheck, AEnabled);
    g_signal_handlers_unblock_matched(ACheck,
      [G_SIGNAL_MATCH_FUNC], 0, 0, nil, @Gtk4CLB_CheckToggled, nil);
  end;

  { Store references for toggle callback }
  g_object_set_data(PGObject(ACheck), 'lcl-listbox', AListBox);
  g_object_set_data(PGObject(ACheck), 'lcl-position', gpointer(PtrUInt(APosition)));

  { Connect toggle signal (reconnect is safe — GTK deduplicates) }
  g_signal_connect_data(ACheck, 'toggled',
    TGCallback(@Gtk4CLB_CheckToggled), nil, nil, G_CONNECT_DEFAULT);
end;

function TGtk4ListBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AListBox: TCustomListBox;
  StringList: PGtkStringList;
  Factory: PGtkSignalListItemFactory;
  ItemList: TGtkStringListStrings;
begin
  FScrollX := 0;
  FScrollY := 0;
  FListBoxStyle := lbStandard;

  FWidgetType := FWidgetType + [wtListBox, wtScrollingWin];
  FIsListView := True;
  AListBox := TCustomListBox(LCLObject);

  Result := PGtkScrolledWindow(gtk4_scrolled_window_new);
  Result^.show;

  { GtkStringList as data model }
  StringList := gtk4_string_list_new(nil);
  FListModel := StringList;

  { Selection model }
  if AListBox.MultiSelect then
    FSelectionModel := gtk4_multi_selection_new(PGListModel(StringList))
  else
    FSelectionModel := gtk4_single_selection_new(PGListModel(StringList));

  { Factory }
  Factory := gtk4_signal_list_item_factory_new;
  g_signal_connect_data(Factory, 'setup',
    TGCallback(@Gtk4LB_FactorySetup), nil, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(Factory, 'bind',
    TGCallback(@Gtk4LB_FactoryBind), nil, nil, G_CONNECT_DEFAULT);

  { GtkListView for a single-column list; GtkGridView for TListBox.Columns>0.
    Both are GtkListBase widgets sharing the exact same selection-model +
    factory API, so the whole data path is identical — only the widget and the
    item geometry (row-major grid vs vertical list) differ. }
  FGridColumns := AListBox.Columns;
  FIsGridView := FGridColumns > 0;
  if FIsGridView then
  begin
    FCentralWidget := PGtkWidget(gtk4_grid_view_new(
      PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory)));
    { Fix the grid to exactly Columns columns (min=max) for LCL's fixed
      column-count semantics rather than GtkGridView's default reflow. }
    gtk4_grid_view_set_min_columns(PGtkGridView(FCentralWidget), guint(FGridColumns));
    gtk4_grid_view_set_max_columns(PGtkGridView(FCentralWidget), guint(FGridColumns));
  end
  else
    FCentralWidget := PGtkWidget(gtk4_list_view_new(
      PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory)));

  { TStrings wrapper }
  ItemList := TGtkStringListStrings.Create(StringList, LCLObject);
  g_object_set_data(PGObject(FCentralWidget), GtkListItemLCLListTag, ItemList);

  { Selection changed signal }
  g_signal_connect_data(PGObject(FSelectionModel), 'selection-changed',
    TGCallback(@Gtk4LB_SelectionChanged), Self, nil, G_CONNECT_DEFAULT);

  gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), FCentralWidget);

  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  FListBoxStyle := AListBox.Style;
end;

function TGtk4ListBox.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

procedure TGtk4ListBox.DetachEvents;
begin
  { Disconnect signals on FSelectionModel (not FWidget) }
  if FSelectionModel <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FSelectionModel),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  inherited DetachEvents;
end;

procedure TGtk4ListBox.InitializeWidget;
begin
  inherited InitializeWidget;
  { GtkListView: selection-changed already connected in CreateWidget }
end;

function TGtk4ListBox.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk4ListBox.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk4ListBox.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

function TGtk4ListBox.GetItemIndex: Integer;
var
  Sel: guint;
begin
  Result := -1;
  if not IsWidgetOk then Exit;
  if FIsListView then
  begin
    Sel := gtk4_single_selection_get_selected(PGtkSingleSelection(FSelectionModel));
    if Sel = GTK_INVALID_LIST_POSITION then
      Result := -1
    else
      Result := Integer(Sel);
  end else
  begin
    Result := -1;
  end;
end;

function TGtk4ListBox.GetMultiSelect: Boolean;
begin
  Result := False;
  if not IsWidgetOk then Exit;
  if FIsListView then
    Result := g_type_check_instance_is_a(PGTypeInstance(FSelectionModel),
      gtk4_multi_selection_get_type)
  else
    Result := False;
end;

procedure TGtk4ListBox.SetItemIndex(AValue: Integer);
begin
  if not IsWidgetOk then Exit;
  if FIsListView then
  begin
    if AValue < 0 then
    begin
      gtk4_selection_model_unselect_all(PGtkSelectionModel(FSelectionModel));
    end else
    begin
      gtk4_selection_model_select_item(PGtkSelectionModel(FSelectionModel),
        guint(AValue), True);
    end;
  end;
end;

procedure TGtk4ListBox.SetListBoxStyle(AValue: TListBoxStyle);
begin
  if FListBoxStyle=AValue then Exit;
  FListBoxStyle:=AValue;
end;

procedure TGtk4ListBox.SetMultiSelect(AValue: Boolean);
begin
  if not IsWidgetOk then Exit;
  { MultiSelect requires recreation (different selection model type) }
end;

function TGtk4ListBox.GetSelCount: Integer;
var
  ABitset: PGtkBitset;
begin
  Result := 0;
  if not IsWidgetOk then Exit;
  if FIsListView then
  begin
    ABitset := gtk4_selection_model_get_selection(PGtkSelectionModel(FSelectionModel));
    if ABitset <> nil then
    begin
      Result := gtk4_bitset_get_size(ABitset);
      gtk4_bitset_unref(ABitset);
    end;
  end;
end;

function TGtk4ListBox.GetSelection: PGtkTreeSelection;
begin
  { Not used in GtkListView path }
  Result := nil;
end;

function TGtk4ListBox.GetItemSelected(const AIndex: Integer): Boolean;
begin
  Result := False;
  if not IsWidgetOK then Exit;
  if FIsListView then
    Result := gtk4_selection_model_is_selected(
      PGtkSelectionModel(FSelectionModel), guint(AIndex));
end;

procedure TGtk4ListBox.SelectItem(const AIndex: Integer; ASelected: Boolean);
begin
  if not IsWidgetOK then Exit;
  if FIsListView then
  begin
    if ASelected then
      gtk4_selection_model_select_item(PGtkSelectionModel(FSelectionModel),
        guint(AIndex), not GetMultiSelect)
    else
      gtk4_selection_model_unselect_item(PGtkSelectionModel(FSelectionModel),
        guint(AIndex));
  end;
end;

procedure TGtk4ListBox.SetTopIndex(const AIndex: Integer);
var
  Adj: PGtkAdjustment;
  RowH, NewVal: Double;
  NItems: guint;
begin
  if not IsWidgetOk then Exit;
  if FIsListView then
  begin
    Adj := PGtkScrolledWindow(Widget)^.get_vadjustment;
    if Adj = nil then Exit;
    NItems := g_list_model_get_n_items(PGListModel(FListModel));
    if NItems = 0 then Exit;
    RowH := Adj^.get_upper / NItems;
    NewVal := AIndex * RowH;
    Adj^.set_value(NewVal);
  end;
end;

{ TGtk4CheckListBox }

function TGtk4CheckListBox.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
var
  ACheckListBox: TCustomCheckListBox;
  StringList: PGtkStringList;
  Factory: PGtkSignalListItemFactory;
  ItemList: TGtkStringListStrings;
begin
  FScrollX := 0;
  FScrollY := 0;
  FWidgetType := FWidgetType + [wtListBox, wtCheckListBox, wtScrollingWin];
  FIsListView := True;
  ACheckListBox := TCustomCheckListBox(LCLObject);
  FListBoxStyle := lbStandard;

  Result := PGtkScrolledWindow(gtk4_scrolled_window_new);
  Result^.show;

  { GtkStringList as data model }
  StringList := gtk4_string_list_new(nil);
  FListModel := StringList;

  { Selection model }
  if ACheckListBox.MultiSelect then
    FSelectionModel := gtk4_multi_selection_new(PGListModel(StringList))
  else
    FSelectionModel := gtk4_single_selection_new(PGListModel(StringList));

  { Factory with CheckButton }
  Factory := gtk4_signal_list_item_factory_new;
  g_signal_connect_data(Factory, 'setup',
    TGCallback(@Gtk4CLB_FactorySetup), nil, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(Factory, 'bind',
    TGCallback(@Gtk4CLB_FactoryBind), Self, nil, G_CONNECT_DEFAULT);

  FGridColumns := ACheckListBox.Columns;
  FIsGridView := FGridColumns > 0;

  { GtkListView, or GtkGridView when Columns>0 (shared model/factory API). }
  if FIsGridView then
  begin
    FCentralWidget := PGtkWidget(gtk4_grid_view_new(
      PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory)));
    gtk4_grid_view_set_min_columns(PGtkGridView(FCentralWidget), guint(FGridColumns));
    gtk4_grid_view_set_max_columns(PGtkGridView(FCentralWidget), guint(FGridColumns));
  end
  else
    FCentralWidget := PGtkWidget(gtk4_list_view_new(
      PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory)));

  { TStrings wrapper }
  ItemList := TGtkStringListStrings.Create(StringList, LCLObject);
  g_object_set_data(PGObject(FCentralWidget), GtkListItemLCLListTag, ItemList);

  { Selection changed signal }
  g_signal_connect_data(PGObject(FSelectionModel), 'selection-changed',
    TGCallback(@Gtk4LB_SelectionChanged), Self, nil, G_CONNECT_DEFAULT);

  gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), FCentralWidget);

  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  FListBoxStyle := ACheckListBox.Style;
end;

{ ---- GtkColumnView factory callbacks and selection handler ---- }

function Gtk4CV_HasCustomDraw(LV: TCustomListView): Boolean;
begin
  Result := TCustomListViewAccess(LV).IsCustomDrawn(dtItem, cdPrePaint) or
            TCustomListViewAccess(LV).IsCustomDrawn(dtSubItem, cdPrePaint);
end;

procedure Gtk4CV_CheckToggled(button: PGtkCheckButton; {%H-}user_data: gpointer); cdecl;
var
  Box: PGtkWidget;
  LV: TGtk4ListView;
  Position: PtrUInt;
  ListItem: TListItem;
  AListView: TCustomListView;
begin
  Box := PGtkWidget(button)^.get_parent;
  if Box = nil then Exit;
  LV := TGtk4ListView(g_object_get_data(PGObject(Box), 'lcl-list-view'));
  if (LV = nil) or not Gtk4IsLiveWidgetPointer(LV) then Exit;
  Position := PtrUInt(g_object_get_data(PGObject(Box), 'lcl-item-position'));
  AListView := TCustomListView(LV.LCLObject);
  if (AListView = nil) or (Integer(Position) >= AListView.Items.Count) then Exit;
  { Design mode: do not flip the item's checked state — the designer owns
    the click (component selection). }
  if csDesigning in AListView.ComponentState then Exit;
  ListItem := AListView.Items[Position];
  if ListItem <> nil then
    ListItem.Checked := gtk4_check_button_get_active(button);
end;

{ Bitmap for a list item's icon cell. State image takes the single icon
  slot when StateImages is assigned and StateIndex is valid — the same
  semantics as qt5 (Qt items have one icon slot; ItemSetStateImage sets it
  and ItemSetImage preserves it while StateIndex >= 0). Falls back to the
  normal item image, or nil (hide) when neither applies. }
function Gtk4LVItemImageBitmap(AView: TGtk4ListView; AItem: TListItem): TBitmap;
begin
  Result := nil;
  if (AView = nil) or (AItem = nil) then Exit;
  if Assigned(AView.StateImages) and (AItem.StateIndex >= 0) and
     (AItem.StateIndex < AView.StateImages.Count) and
     (AView.StateImages[AItem.StateIndex] <> nil) then
    Exit(TBitmap(AView.StateImages[AItem.StateIndex]));
  if Assigned(AView.Images) and (AItem.ImageIndex >= 0) and
     (AItem.ImageIndex < AView.Images.Count) and
     (AView.Images[AItem.ImageIndex] <> nil) then
    Result := TBitmap(AView.Images[AItem.ImageIndex]);
end;

procedure Gtk4CV_FactorySetup({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  Box: PGtkWidget;
  CheckBtn: PGtkWidget;
  Image: PGtkWidget;
  ALabel: PGtkWidget;
  CssProvider: PGtkCssProvider;
begin
  Box := PGtkWidget(TGtkBox.new(GTK_ORIENTATION_HORIZONTAL, 4));

  { Checkbox — hidden by default, shown in Bind when FCheckboxes = True }
  CheckBtn := PGtkWidget(gtk_check_button_new);
  CheckBtn^.hide;
  gtk4_box_append(PGtkBox(Box), CheckBtn);
  g_object_set_data(PGObject(Box), 'lcl-check-button', CheckBtn);
  g_signal_connect_data(PGObject(CheckBtn), 'toggled',
    TGCallback(@Gtk4CV_CheckToggled), nil, nil, G_CONNECT_DEFAULT);

  Image := PGtkWidget(TGtkImage.new);
  Image^.hide; { show only when image is assigned }
  ALabel := PGtkWidget(TGtkLabel.new(nil));
  ALabel^.set_halign(GTK_ALIGN_START);
  ALabel^.set_hexpand(True);
  { Ellipsize so the label's minimum width is small (~"..."), preventing
    negative width allocation when the column is narrower than the
    combined intrinsic widths of CheckBtn + Image + Label + spacing. }
  PGtkLabel(ALabel)^.set_ellipsize(PANGO_ELLIPSIZE_END);
  gtk4_box_append(PGtkBox(Box), Image);
  gtk4_box_append(PGtkBox(Box), ALabel);

  { Row coloring: create per-cell CssProvider.
    g_object_set_data_full with g_object_unref ensures the initial ref from
    gtk_css_provider_new is released when Box is destroyed. add_provider holds
    its own ref so the provider stays alive while the style context exists. }
  CssProvider := gtk_css_provider_new;
  Box^.get_style_context^.add_provider(
    PGtkStyleProvider(CssProvider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_set_data_full(PGObject(Box), 'lcl-css-provider', CssProvider,
    TGDestroyNotify(@g_object_unref));

  gtk4_list_item_set_child(listitem, Box);
end;

procedure Gtk4CV_FactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  Data: PColumnFactoryData;
  Position: guint;
  Box: PGtkWidget;
  CheckBtn, Image, LabelW: PGtkWidget;
  ALclItem: TListItem;
  LV: TCustomListView;
  S: String;
  ABmp: TBitmap;
  APixbuf: PGdkPixbuf;
  { IntfCustomDraw }
  CssProvider: PGtkCssProvider;
  TmpDC, OldDC: HDC;
  LVTarget: TCustomDrawTarget;
  LVState: TCustomDrawState;
  DefaultBrushColor, NewBrushColor: TColor;
  CssStr: String;
  C: TColorRef;
  { CustomDraw icon rendering }
  IconW, IconH: Integer;
  IconRect: TRect;
  DrawY: Integer;
  IconSurface: Pcairo_surface_t;
  cr: Pcairo_t;
begin
  Data := PColumnFactoryData(user_data);
  if Data = nil then Exit;
  Position := gtk4_list_item_get_position(listitem);
  Box := gtk4_list_item_get_child(listitem);
  if Box = nil then Exit;

  LV := TCustomListView(Data^.ListView.LCLObject);
  if LV = nil then Exit;

  if Integer(Position) >= LV.Items.Count then Exit;
  ALclItem := LV.Items[Position];

  { Box children: CheckBtn(0) → Image(1) → Label(2) }
  CheckBtn := gtk4_widget_get_first_child(Box);
  Image := gtk4_widget_get_next_sibling(CheckBtn);
  LabelW := gtk4_widget_get_last_child(Box);

  { Set text }
  if Data^.ColumnIndex = 0 then
    S := ALclItem.Caption
  else if Data^.ColumnIndex - 1 < ALclItem.SubItems.Count then
    S := ALclItem.SubItems[Data^.ColumnIndex - 1]
  else
    S := '';
  PGtkLabel(LabelW)^.set_text(PgChar(S));

  { Checkbox binding (first column only) }
  if CheckBtn <> nil then
  begin
    g_object_set_data(PGObject(Box), 'lcl-list-view', Data^.ListView);
    g_object_set_data(PGObject(Box), 'lcl-item-position', gpointer(PtrUInt(Position)));
    if Data^.ListView.FCheckboxes and (Data^.ColumnIndex = 0) then
    begin
      { Block signal to avoid feedback loop during programmatic set }
      g_signal_handlers_block_matched(PGObject(CheckBtn),
        [G_SIGNAL_MATCH_FUNC], 0, 0, nil, @Gtk4CV_CheckToggled, nil);
      gtk4_check_button_set_active(PGtkCheckButton(CheckBtn), ALclItem.Checked);
      g_signal_handlers_unblock_matched(PGObject(CheckBtn),
        [G_SIGNAL_MATCH_FUNC], 0, 0, nil, @Gtk4CV_CheckToggled, nil);
      CheckBtn^.show;
    end else
      CheckBtn^.hide;
  end;

  { Set image (first column only) — state image takes the slot when set
    (qt5 semantics, see Gtk4LVItemImageBitmap) }
  if Data^.ColumnIndex = 0 then
    ABmp := Gtk4LVItemImageBitmap(Data^.ListView, ALclItem)
  else
    ABmp := nil;
  if (Image <> nil) and (ABmp <> nil) then
  begin
    APixbuf := Gtk4BitmapToPixbuf(ABmp);
    if APixbuf <> nil then
    begin
      PGtkImage(Image)^.set_from_pixbuf(APixbuf);
      g_object_unref(APixbuf);
      Image^.show;
    end else
      Image^.hide;
  end
  else if (Data^.ColumnIndex = 0) and (Image <> nil) and
          Gtk4CV_HasCustomDraw(LV) then
  begin
    { CustomDraw icon rendering: OnCustomDrawItem draws icons via
      TPaletteComponent.Images etc. Capture the drawing on a small
      cairo image surface, then convert to GdkPixbuf for the GtkImage. }
    IconW := 24; IconH := 24;
    if Assigned(TCustomListViewAccess(LV).SmallImages) then
    begin
      IconW := TCustomListViewAccess(LV).SmallImages.Width;
      IconH := TCustomListViewAccess(LV).SmallImages.Height;
    end;
    { Get the rect that the CustomDraw handler will use via Item.DisplayRect(drIcon).
      Translate our cairo context so the handler's drawing maps to (0,0) on the surface. }
    IconRect := ALclItem.DisplayRect(drIcon);
    if (IconRect.Right <= IconRect.Left) or (IconRect.Bottom <= IconRect.Top) then
      IconRect := Rect(0, 0, IconW, IconH);
    DrawY := IconRect.Top + (IconRect.Bottom - IconRect.Top - IconH) div 2;

    IconSurface := cairo_image_surface_create(CAIRO_FORMAT_ARGB32, IconW, IconH);
    cr := cairo_create(IconSurface);
    cairo_translate(cr, Double(-IconRect.Left), Double(-DrawY));

    TmpDC := GTK4WidgetSet.CreateDCForWidget(nil, nil, cr);
    OldDC := TCustomListViewAccess(LV).Canvas.Handle;
    TCustomListViewAccess(LV).Canvas.Handle := TmpDC;
    try
      TCustomListViewAccess(LV).IntfCustomDraw(
        dtItem, cdPrePaint, Integer(Position), 0, [], nil);
    finally
      TCustomListViewAccess(LV).Canvas.Handle := OldDC;
      GTK4WidgetSet.ReleaseDC(0, TmpDC);
    end;
    cairo_destroy(cr);

    cairo_surface_flush(IconSurface);
    APixbuf := gdk_pixbuf_get_from_surface(IconSurface, 0, 0, IconW, IconH);
    cairo_surface_destroy(IconSurface);
    if APixbuf <> nil then
    begin
      PGtkImage(Image)^.set_from_pixbuf(APixbuf);
      g_object_unref(APixbuf);
      Image^.show;
    end else
      Image^.hide;
  end
  else if Image <> nil then
    Image^.hide;

  { IntfCustomDraw row coloring — apply background via per-cell CssProvider }
  if Gtk4CV_HasCustomDraw(LV) then
  begin
    CssProvider := PGtkCssProvider(g_object_get_data(PGObject(Box), 'lcl-css-provider'));
    if CssProvider <> nil then
    begin
      TmpDC := GTK4WidgetSet.CreateDCForWidget(PGtkWidget(nil), nil, nil);
      OldDC := TCustomListViewAccess(LV).Canvas.Handle;
      TCustomListViewAccess(LV).Canvas.Handle := TmpDC;
      try
        if Data^.ColumnIndex = 0 then
          LVTarget := dtItem
        else
          LVTarget := dtSubItem;
        LVState := [];
        if gtk4_selection_model_is_selected(
          PGtkSelectionModel(Data^.ListView.SelectionModel), Position) then
          Include(LVState, cdsSelected);

        DefaultBrushColor := TGtk4DeviceContext(TmpDC).CurrentBrush.Color;

        TCustomListViewAccess(LV).IntfCustomDraw(
          LVTarget, cdPrePaint, Integer(Position), Data^.ColumnIndex, LVState, nil);

        NewBrushColor := TGtk4DeviceContext(TmpDC).CurrentBrush.Color;
        if NewBrushColor <> DefaultBrushColor then
        begin
          C := ColorToRGB(NewBrushColor);
          CssStr := Format('* { background-color: #%.2x%.2x%.2x; }',
            [Red(C), Green(C), Blue(C)]);
          gtk_css_provider_load_from_data(CssProvider, PgChar(CssStr), -1, nil);
        end else
          gtk_css_provider_load_from_data(CssProvider, PgChar('* {}'), -1, nil);
      finally
        TCustomListViewAccess(LV).Canvas.Handle := OldDC;
        GTK4WidgetSet.ReleaseDC(0, TmpDC);
      end;
    end;
  end;
end;

procedure Gtk4CV_FactoryUnbind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  Box: PGtkWidget;
  CssProvider: PGtkCssProvider;
begin
  Box := gtk4_list_item_get_child(listitem);
  if Box = nil then Exit;
  { Reset CSS to avoid stale styles on recycled items }
  CssProvider := PGtkCssProvider(g_object_get_data(PGObject(Box), 'lcl-css-provider'));
  if CssProvider <> nil then
    gtk_css_provider_load_from_data(CssProvider, PgChar('* {}'), -1, nil);
end;

procedure Gtk4CV_SelectionChanged({%H-}model: PGtkSelectionModel;
  position: guint; n_items: guint; user_data: gpointer); cdecl;
var
  Msg: TLMNotify;
  NM: TNMListView;
  Widget: TGtk4ListView;
  i: guint;
begin
  Widget := TGtk4ListView(user_data);
  if (Widget = nil) or not Gtk4IsLiveWidgetPointer(user_data) then Exit;
  if Widget.InUpdate then Exit;
  { Design mode: clicking a row changes the native selection; do not report it
    or the design-time selection state would be corrupted. The designer owns
    the click (selecting the list control itself). }
  if Assigned(Widget.LCLObject) and
     (csDesigning in Widget.LCLObject.ComponentState) then
    Exit;

  Widget.BeginUpdate;
  try
    for i := 0 to n_items - 1 do
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), 0);
      Msg.Msg := CN_NOTIFY;
      FillChar(NM{%H-}, SizeOf(NM), 0);
      NM.hdr.hwndfrom := HWND(Widget);
      NM.hdr.code := LVN_ITEMCHANGED;
      NM.iItem := Integer(position + i);
      NM.iSubItem := 0;
      NM.uChanged := LVIF_STATE;
      if gtk4_selection_model_is_selected(model, position + i) then
        NM.uNewState := LVIS_SELECTED
      else
        NM.uNewState := 0;
      Msg.NMHdr := @NM.hdr;
      Widget.DeliverMessage(Msg);
    end;
  finally
    Widget.EndUpdate;
  end;
end;

procedure Gtk4CV_FactoryDataDestroy(data: gpointer; {%H-}closure: PGClosure); cdecl;
begin
  if data <> nil then
    Dispose(PColumnFactoryData(data));
end;

{ ---- GtkColumnView OwnerDraw factory callbacks ---- }

procedure Gtk4CV_ItemDrawFunc({%H-}drawing_area: PGtkDrawingArea;
  cr: Pcairo_t; width: gint; height: gint; user_data: gpointer); cdecl;
var
  Data: PColumnFactoryData;
  Msg: TLMDrawListItem;
  Position: Integer;
  State: TOwnerDrawState;
  IsSelected: Boolean;
begin
  Data := PColumnFactoryData(user_data);
  if (Data = nil) or (Data^.ListView = nil) then Exit;
  Position := Integer({%H-}PtrUInt(g_object_get_data(
    PGObject(drawing_area), 'lcl-item-position')));
  IsSelected := Boolean({%H-}PtrUInt(g_object_get_data(
    PGObject(drawing_area), 'lcl-item-selected')));

  State := [odBackgroundPainted];
  if IsSelected then Include(State, odSelected);

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := CN_DRAWITEM;
  New(Msg.DrawListItemStruct);
  try
    FillChar(Msg.DrawListItemStruct^, SizeOf(TDrawListItemStruct), 0);
    Msg.DrawListItemStruct^.ItemID := UINT(Position);
    Msg.DrawListItemStruct^.Area := Rect(0, 0, width, height);
    Msg.DrawListItemStruct^.DC := GTK4WidgetSet.CreateDCForWidget(
      PGtkWidget(drawing_area), nil, cr);
    Msg.DrawListItemStruct^.ItemState := State;
    Data^.ListView.DeliverMessage(TLMessage(Msg));
    GTK4WidgetSet.ReleaseDC(0, Msg.DrawListItemStruct^.DC);
  finally
    Dispose(Msg.DrawListItemStruct);
  end;
end;

procedure Gtk4CV_FactorySetup_OwnerDraw({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  DrawArea: PGtkDrawingArea;
  Data: PColumnFactoryData;
  LV: TCustomListView;
  ItemH: Integer;
begin
  Data := PColumnFactoryData(user_data);
  if (Data = nil) or (Data^.ListView = nil) then Exit;
  LV := TCustomListView(Data^.ListView.LCLObject);
  DrawArea := PGtkDrawingArea(gtk_drawing_area_new);
  ItemH := TCustomListViewAccess(LV).DefaultItemHeight;
  if ItemH <= 0 then
    ItemH := 20;
  gtk4_drawing_area_set_content_height(DrawArea, ItemH);
  gtk4_drawing_area_set_draw_func(DrawArea,
    @Gtk4CV_ItemDrawFunc, user_data, nil);
  gtk4_list_item_set_child(listitem, PGtkWidget(DrawArea));
end;

procedure Gtk4CV_FactoryBind_OwnerDraw({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  DrawArea: PGtkDrawingArea;
  Position: guint;
begin
  if user_data = nil then Exit;
  Position := gtk4_list_item_get_position(listitem);
  DrawArea := PGtkDrawingArea(gtk4_list_item_get_child(listitem));
  if DrawArea = nil then Exit;

  g_object_set_data(PGObject(DrawArea), 'lcl-list-view',
    PColumnFactoryData(user_data)^.ListView);
  g_object_set_data(PGObject(DrawArea), 'lcl-item-position',
    {%H-}gpointer(PtrUInt(Position)));
  g_object_set_data(PGObject(DrawArea), 'lcl-item-selected',
    {%H-}gpointer(PtrUInt(Ord(gtk4_list_item_get_selected(listitem)))));

  PGtkWidget(DrawArea)^.queue_draw;
end;

{ ---- GtkGridView factory callbacks ---- }

procedure Gtk4GV_FactorySetup_Icon({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  Box: PGtkWidget;
  Image: PGtkWidget;
  ALabel: PGtkWidget;
begin
  { Vertical box: Image on top, Label below }
  Box := PGtkWidget(TGtkBox.new(GTK_ORIENTATION_VERTICAL, 4));
  Box^.set_halign(GTK_ALIGN_CENTER);
  Image := PGtkWidget(TGtkImage.new);
  Image^.hide;
  ALabel := PGtkWidget(TGtkLabel.new(nil));
  ALabel^.set_halign(GTK_ALIGN_CENTER);
  PGtkLabel(ALabel)^.set_ellipsize(PANGO_ELLIPSIZE_END);
  PGtkLabel(ALabel)^.set_max_width_chars(14);
  gtk4_box_append(PGtkBox(Box), Image);
  gtk4_box_append(PGtkBox(Box), ALabel);
  gtk4_list_item_set_child(listitem, Box);
end;

procedure Gtk4GV_FactorySetup_SmallIcon({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  Box: PGtkWidget;
  Image: PGtkWidget;
  ALabel: PGtkWidget;
begin
  { Horizontal box: Image left, Label right }
  Box := PGtkWidget(TGtkBox.new(GTK_ORIENTATION_HORIZONTAL, 4));
  Image := PGtkWidget(TGtkImage.new);
  Image^.hide;
  ALabel := PGtkWidget(TGtkLabel.new(nil));
  ALabel^.set_halign(GTK_ALIGN_START);
  ALabel^.set_hexpand(True);
  PGtkLabel(ALabel)^.set_ellipsize(PANGO_ELLIPSIZE_END);
  gtk4_box_append(PGtkBox(Box), Image);
  gtk4_box_append(PGtkBox(Box), ALabel);
  gtk4_list_item_set_child(listitem, Box);
end;

procedure Gtk4GV_FactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  Data: PColumnFactoryData;
  Position: guint;
  Box: PGtkWidget;
  Image, LabelW: PGtkWidget;
  ALclItem: TListItem;
  LV: TCustomListView;
  ABmp: TBitmap;
  APixbuf: PGdkPixbuf;
begin
  Data := PColumnFactoryData(user_data);
  if Data = nil then Exit;
  Position := gtk4_list_item_get_position(listitem);
  Box := gtk4_list_item_get_child(listitem);
  if Box = nil then Exit;

  LV := TCustomListView(Data^.ListView.LCLObject);
  if (LV = nil) or (Integer(Position) >= LV.Items.Count) then Exit;
  ALclItem := LV.Items[Position];

  { Store position metadata for pick-based hit testing (matches ColumnView pattern) }
  g_object_set_data(PGObject(Box), 'lcl-list-view', Data^.ListView);
  g_object_set_data(PGObject(Box), 'lcl-item-position', {%H-}gpointer(PtrUInt(Position)));

  { Box children: Image(first) → Label(last) }
  Image := gtk4_widget_get_first_child(Box);
  LabelW := gtk4_widget_get_last_child(Box);

  { Set text }
  PGtkLabel(LabelW)^.set_text(PgChar(ALclItem.Caption));

  { Set image — state image takes the slot when set (qt5 semantics,
    see Gtk4LVItemImageBitmap) }
  ABmp := Gtk4LVItemImageBitmap(Data^.ListView, ALclItem);
  if ABmp <> nil then
  begin
    APixbuf := Gtk4BitmapToPixbuf(ABmp);
    if APixbuf <> nil then
    begin
      PGtkImage(Image)^.set_from_pixbuf(APixbuf);
      g_object_unref(APixbuf);
      Image^.show;
    end else
      Image^.hide;
  end else
    Image^.hide;
end;

{ ---- GtkColumnView sort infrastructure ---- }

var
  GLastSortColumnIndex: Integer = -1;

function Gtk4CV_ColumnSorterCompare({%H-}a: gconstpointer;
  {%H-}b: gconstpointer; user_data: gpointer): gint; cdecl;
begin
  { Record which column's sorter was invoked }
  GLastSortColumnIndex := {%H-}PtrInt(user_data);
  Result := 0; { All equal — LCL manages sort order }
end;

procedure Gtk4CV_SorterChanged({%H-}sorter: PGtkSorter;
  {%H-}change: gint; user_data: gpointer); cdecl;
var
  Widget: TGtk4ListView;
  Msg: TLMNotify;
  NM: TNMListView;
  ColIdx: Integer;
begin
  Widget := TGtk4ListView(user_data);
  if (Widget = nil) or not Gtk4IsLiveWidgetPointer(user_data) then Exit;
  if Widget.InUpdate then Exit;
  ColIdx := GLastSortColumnIndex;
  if (ColIdx < 0) or (ColIdx >= Widget.FColumnObjects.Count) then Exit;

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := CN_NOTIFY;
  FillChar(NM{%H-}, SizeOf(NM), 0);
  NM.hdr.hwndfrom := HWND(Widget);
  NM.hdr.code := LVN_COLUMNCLICK;
  NM.iItem := -1;
  NM.iSubItem := ColIdx;
  Msg.NMHdr := @NM.hdr;
  Widget.DeliverMessage(Msg);
end;

{ TGtk4ListView }

function Gtk4WS_ListViewItemPreSelected({%H-}selection: PGtkTreeSelection; {%H-}model: PGtkTreeModel;
  path: PGtkTreePath; path_is_currently_selected: GBoolean; AData: GPointer): GBoolean; cdecl;
begin
  if path_is_currently_selected then ;
  // this function is called *before* the item is selected
  // The result should be True to allow the Item to change selection
  Result := True;

  if (AData = nil) or TGtk4Widget(AData).InUpdate then
    exit;

  if not Assigned(TGtk4ListView(AData).FPreselectedIndices) then
    TGtk4ListView(AData).FPreselectedIndices := TFPList.Create;

  if TGtk4ListView(AData).FPreselectedIndices.IndexOf({%H-}Pointer(PtrInt(gtk_tree_path_get_indices(path)^))) = -1 then
    TGtk4ListView(AData).FPreselectedIndices.Add({%H-}Pointer(PtrInt(gtk_tree_path_get_indices(path)^)));
end;

procedure Gtk4WS_ListViewItemSelected(ASelection: PGtkTreeSelection; AData: GPointer); cdecl;
var
  AList: PGList;
  Msg: TLMNotify;
  NM: TNMListView;
  Path: PGtkTreePath;
  Indices: Integer;
  i, j: Integer;
  B: Boolean;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  if TGtk4Widget(AData).InUpdate then
    exit;
  if not Assigned(TGtk4ListView(AData).FPreselectedIndices) then
    exit;
  AList := gtk_tree_selection_get_selected_rows(ASelection, nil);
  TGtk4Widget(AData).BeginUpdate; // dissalow entering Gtk4WS_ListViewItemPreSelected
  try
    for i := 0 to TGtk4ListView(AData).FPreselectedIndices.Count - 1 do
    begin
      FillChar(Msg{%H-}, SizeOf(Msg), 0);
      Msg.Msg := CN_NOTIFY;
      FillChar(NM{%H-}, SizeOf(NM), 0);
      NM.hdr.hwndfrom := HWND(TGtk4Widget(AData));
      NM.hdr.code := LVN_ITEMCHANGED;
      NM.iItem := {%H-}PtrInt(TGtk4ListView(AData).FPreselectedIndices.Items[i]);
      NM.iSubItem := 0;
      B := False;
      for j := 0 to g_list_length(AList) - 1 do
      begin
        Path := g_list_nth_data(AList, guint(j));
        if Path <> nil then
        begin
          Indices := gtk_tree_path_get_indices(Path)^;
          B := Indices = {%H-}PtrUInt(TGtk4ListView(AData).FPreselectedIndices.Items[i]);
          if B then
            break;
        end;
      end;
      if not B then
        NM.uOldState := LVIS_SELECTED
      else
        NM.uNewState := LVIS_SELECTED;
      NM.uChanged := LVIF_STATE;
      Msg.NMHdr := @NM.hdr;
      DeliverMessage(TGtk4Widget(AData).LCLObject, Msg);
    end;
  finally
    FreeAndNil(TGtk4ListView(AData).FPreselectedIndices);
    if AList <> nil then
      g_list_free(AList);
    TGtk4Widget(AData).EndUpdate;
  end;
end;

function TGtk4ListView.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AListView: TCustomListView;
  AScrollStyle: TGtkScrollStyle;
  StringList: PGtkStringList;
  Factory: PGtkSignalListItemFactory;
  FactoryData: PColumnFactoryData;
  CVSorter: PGtkSorter;
  CVColumn: PGtkColumnViewColumn;
begin
  FImages := nil;
  FScrollX := 0;
  FScrollY := 0;
  FPreselectedIndices := nil;
  FIsColumnView := False;
  FIsGridView := False;
  FSelectionModel := nil;
  FListModel := nil;
  FColumnFactories := nil;
  FColumnObjects := nil;
  FColumnSorters := nil;
  AListView := TCustomListView(LCLObject);
  Result := PGtkWidget(gtk4_scrolled_window_new);

  if TListView(AListView).ViewStyle in [vsIcon, vsSmallIcon] then
  begin
    { GtkGridView path — replaces deprecated GtkIconView }
    FWidgetType := FWidgetType + [wtListView, wtScrollingWin];
    FIsTreeView := False;
    FIsColumnView := False;
    FIsGridView := True;

    StringList := gtk4_string_list_new(nil);
    FListModel := StringList;

    if TListView(AListView).MultiSelect then
      FSelectionModel := gtk4_multi_selection_new(PGListModel(StringList))
    else
    begin
      FSelectionModel := gtk4_single_selection_new(PGListModel(StringList));
      gtk4_single_selection_set_autoselect(FSelectionModel, False);
      gtk4_single_selection_set_can_unselect(FSelectionModel, True);
    end;

    Factory := PGtkSignalListItemFactory(gtk4_signal_list_item_factory_new);
    New(FactoryData);
    FactoryData^.ListView := Self;
    FactoryData^.ColumnIndex := 0;

    if TListView(AListView).ViewStyle = vsIcon then
      g_signal_connect_data(PGObject(Factory), 'setup',
        TGCallback(@Gtk4GV_FactorySetup_Icon), FactoryData, nil, G_CONNECT_DEFAULT)
    else
      g_signal_connect_data(PGObject(Factory), 'setup',
        TGCallback(@Gtk4GV_FactorySetup_SmallIcon), FactoryData, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(Factory), 'bind',
      TGCallback(@Gtk4GV_FactoryBind), FactoryData, @Gtk4CV_FactoryDataDestroy, G_CONNECT_DEFAULT);

    FCentralWidget := gtk4_grid_view_new(
      PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory));

    if TListView(AListView).MultiSelect then
      gtk4_grid_view_set_enable_rubberband(PGtkGridView(FCentralWidget), True);

    FCentralWidget^.show;
    gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), FCentralWidget);

    AScrollStyle := Gtk4TranslateScrollStyle(TListView(AListView).ScrollBars);
    PGtkScrolledWindow(Result)^.set_policy(AScrollStyle.Horizontal, AScrollStyle.Vertical);
    PGtkScrolledWindow(Result)^.set_overlay_scrolling(False);
    PGtkScrolledWindow(Result)^.set_kinetic_scrolling(False);
    { Keep the scrolled window's preferred size bounded (see preferredSize): do
      NOT let the ColumnView's/TreeView's all-rows natural size propagate up, so
      an autosizing parent can't inflate the list to fit every row. }
    PGtkScrolledWindow(Result)^.set_propagate_natural_width(False);
    PGtkScrolledWindow(Result)^.set_propagate_natural_height(False);
    PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
    PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
    FCentralWidget^.set_can_focus(True);
    gtk4_widget_set_focusable(FCentralWidget, True);

    g_signal_connect_data(PGObject(FSelectionModel), 'selection-changed',
      TGCallback(@Gtk4CV_SelectionChanged), Self, nil, G_CONNECT_DEFAULT);
  end
  else
  begin
    { GtkColumnView path — new for vsReport/vsList }
    FWidgetType := FWidgetType + [wtListView, wtScrollingWin];
    FIsTreeView := True;  { WS layer compat: "not icon view" }
    FIsColumnView := True;

    StringList := gtk4_string_list_new(nil);
    FListModel := StringList;

    if TListView(AListView).MultiSelect then
      FSelectionModel := gtk4_multi_selection_new(PGListModel(StringList))
    else
    begin
      FSelectionModel := gtk4_single_selection_new(PGListModel(StringList));
      gtk4_single_selection_set_autoselect(FSelectionModel, False);
      gtk4_single_selection_set_can_unselect(FSelectionModel, True);
    end;

    FCentralWidget := PGtkWidget(gtk4_column_view_new(
      PGtkSelectionModel(FSelectionModel)));

    FColumnFactories := TFPList.Create;
    FColumnObjects := TFPList.Create;
    FColumnSorters := TFPList.Create;

    if (TListView(AListView).ViewStyle = vsList) and
       (TListView(AListView).Columns.Count = 0) then
    begin
      { Match the GTK2/Qt5 behavior for vsList without explicit columns:
        create a widgetset-only display column for item captions. }
      Factory := PGtkSignalListItemFactory(gtk4_signal_list_item_factory_new);
      New(FactoryData);
      FactoryData^.ListView := Self;
      FactoryData^.ColumnIndex := 0;
      g_signal_connect_data(PGObject(Factory), 'setup',
        TGCallback(@Gtk4CV_FactorySetup), FactoryData, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(PGObject(Factory), 'bind',
        TGCallback(@Gtk4CV_FactoryBind), FactoryData, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(PGObject(Factory), 'unbind',
        TGCallback(@Gtk4CV_FactoryUnbind), FactoryData, @Gtk4CV_FactoryDataDestroy, G_CONNECT_DEFAULT);

      CVColumn := PGtkColumnViewColumn(gtk4_column_view_column_new('', PGtkListItemFactory(Factory)));
      gtk4_column_view_column_set_resizable(CVColumn, False);
      gtk4_column_view_column_set_expand(CVColumn, True);
      gtk4_column_view_insert_column(PGtkColumnView(FCentralWidget), 0, CVColumn);
    end;

    { Sorter "changed" signal — fires on column header click }
    CVSorter := gtk4_column_view_get_sorter(PGtkColumnView(FCentralWidget));
    if CVSorter <> nil then
      g_signal_connect_data(PGObject(CVSorter), 'changed',
        TGCallback(@Gtk4CV_SorterChanged), Self, nil, G_CONNECT_DEFAULT);

    { Grid lines — set via SetProperties called by LCL after handle creation }

    { Headers visibility for vsList }
    if TListView(AListView).ViewStyle = vsList then
    begin
      { vsList: single column, no headers — will be set up when column is inserted }
    end;

    FCentralWidget^.show;
    gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), FCentralWidget);

    AScrollStyle := Gtk4TranslateScrollStyle(TListView(AListView).ScrollBars);
    PGtkScrolledWindow(Result)^.set_policy(AScrollStyle.Horizontal, AScrollStyle.Vertical);
    PGtkScrolledWindow(Result)^.set_overlay_scrolling(False);
    PGtkScrolledWindow(Result)^.set_kinetic_scrolling(False);
    { Keep the scrolled window's preferred size bounded (see preferredSize): do
      NOT let the ColumnView's/TreeView's all-rows natural size propagate up, so
      an autosizing parent can't inflate the list to fit every row. }
    PGtkScrolledWindow(Result)^.set_propagate_natural_width(False);
    PGtkScrolledWindow(Result)^.set_propagate_natural_height(False);
    PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
    PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
    FCentralWidget^.set_can_focus(True);
    gtk4_widget_set_focusable(FCentralWidget, True);

    { Selection changed signal }
    g_signal_connect_data(PGObject(FSelectionModel), 'selection-changed',
      TGCallback(@Gtk4CV_SelectionChanged), Self, nil, G_CONNECT_DEFAULT);
  end;
end;

{ selection_changed: removed — was dead code for old GtkIconView path.
  All selection handling now uses Gtk4CV_SelectionChanged callback. }

function TGtk4ListView.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

procedure TGtk4ListView.DetachEvents;
var
  CVSorter: Pointer;
begin
  { Disconnect signals on FSelectionModel (not FWidget) }
  if FSelectionModel <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FSelectionModel),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  { Disconnect ColumnView sorter 'changed' signal }
  if FIsColumnView and (FCentralWidget <> nil) and Gtk4IsWidget(FCentralWidget) then
  begin
    CVSorter := gtk4_column_view_get_sorter(PGtkColumnView(FCentralWidget));
    if CVSorter <> nil then
      g_signal_handlers_disconnect_matched(PGObject(CVSorter),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  inherited DetachEvents;
end;

destructor TGtk4ListView.Destroy;
begin
  ClearImages;
  FreeAndNil(FImages);
  ClearStateImages;
  FreeAndNil(FStateImages);
  FreeAndNil(FPreselectedIndices);
  FreeAndNil(FColumnFactories);
  FreeAndNil(FColumnObjects);
  FreeAndNil(FColumnSorters);
  inherited Destroy;
end;

function TGtk4ListView.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
end;

function TGtk4ListView.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
end;

function TGtk4ListView.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

procedure TGtk4ListView.ClearImages;
var
  i: Integer;
begin
  if Assigned(FImages) then
  begin
    for i := FImages.Count - 1 downto 0 do
      if FImages[i] <> nil then
        TGtk4Object(FImages[i]).Free;
    FImages.Clear;
  end;
end;

procedure TGtk4ListView.ClearStateImages;
var
  i: Integer;
begin
  if Assigned(FStateImages) then
  begin
    for i := FStateImages.Count - 1 downto 0 do
      if FStateImages[i] <> nil then
        TObject(FStateImages[i]).Free;
    FStateImages.Clear;
  end;
end;

procedure TGtk4ListView.ColumnDelete(AIndex: Integer);
var
  AColumn: PGtkTreeViewColumn;
  CVColumn: PGtkColumnViewColumn;
begin
  if not IsWidgetOK then Exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
    begin
      CVColumn := PGtkColumnViewColumn(FColumnObjects[AIndex]);
      gtk4_column_view_remove_column(PGtkColumnView(FCentralWidget), CVColumn);
      FColumnObjects.Delete(AIndex);
      FColumnFactories.Delete(AIndex);
      if (FColumnSorters <> nil) and (AIndex < FColumnSorters.Count) then
        FColumnSorters.Delete(AIndex);
    end;
  end
  else if IsTreeView then
  begin
    AColumn := PGtkTreeView(GetContainerWidget)^.get_column(AIndex);
    if (AColumn <> nil) then
      PGtkTreeView(GetContainerWidget)^.remove_column(AColumn);
  end;
end;

function TGtk4ListView.ColumnGetWidth(AIndex: Integer): Integer;
var
  AColumn: PGtkTreeViewColumn;
begin
  Result := 0;
  if not IsWidgetOK then Exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
      Result := gtk4_column_view_column_get_fixed_width(
        PGtkColumnViewColumn(FColumnObjects[AIndex]));
  end
  else if IsTreeView then
  begin
    AColumn := PGtkTreeView(GetContainerWidget)^.get_column(AIndex);
    if (AColumn <> nil) then
      Result := AColumn^.get_width;
  end;
end;

{ ListView checkbox data function — sets toggle state from TListItem.Checked }
procedure Gtk4WSLV_ListViewGetCheckedDataFunc({%H-}tree_column: PGtkTreeViewColumn;
  cell: PGtkCellRenderer; tree_model: PGtkTreeModel; iter: PGtkTreeIter; AData: GPointer); cdecl;
var
  ListItem: TListItem;
  APath: PGtkTreePath;
begin
  gtk_tree_model_get(tree_model, iter, [0, @ListItem, -1]);

  if (ListItem = nil) and TCustomListView(TGtk4Widget(AData).LCLObject).OwnerData then
  begin
    APath := gtk_tree_model_get_path(tree_model, iter);
    ListItem := TCustomListView(TGtk4Widget(AData).LCLObject).Items[gtk_tree_path_get_indices(APath)^];
    gtk_tree_path_free(APath);
  end;

  if ListItem = nil then
    Exit;
  gtk_cell_renderer_toggle_set_active(PGtkCellRendererToggle(cell), ListItem.Checked);
end;

{ ListView checkbox toggled signal handler }
procedure Gtk4WS_ListViewItemCheckedChanged({%H-}renderer: PGtkCellRendererToggle;
  PathStr: Pgchar; AData: GPointer); cdecl;
var
  LV: TCustomListView;
  Index: Integer;
  ListItem: TListItem;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  LV := TCustomListView(TGtk4Widget(AData).LCLObject);
  Index := StrToInt(String(PathStr));
  if (Index < 0) or (Index >= LV.Items.Count) then Exit;
  ListItem := LV.Items.Item[Index];
  if ListItem <> nil then
  begin
    ListItem.Checked := not ListItem.Checked;
    PGtkWidget(TGtk4Widget(AData).GetContainerWidget)^.queue_draw;
  end;
end;

procedure Gtk4WSLV_ListViewGetPixbufDataFuncForColumn(tree_column: PGtkTreeViewColumn;
  {%H-}cell: PGtkCellRenderer; tree_model: PGtkTreeModel; iter: PGtkTreeIter; AData: GPointer); cdecl;
var
  ListItem: TListItem;
  Images: TFPList;
  // Widgets: PTVWidgets;
  ListColumn: TListColumn;
  ImageIndex: Integer;
  ColumnIndex: Integer;
  APath: PGtkTreePath;
  gv:TGValue;
  pb:PgdkPixbuf;
  ABmp: TBitmap;
begin
  fillchar(gv,sizeof(gv),0);
  gv.init(G_TYPE_OBJECT);
  gv.set_instance(nil);
  PGtkCellRendererPixbuf(cell)^.set_property('pixbuf',@gv);

  gtk_tree_model_get(tree_model, iter, [0, @ListItem, -1]);

  ListColumn := TListColumn(g_object_get_data(tree_column, 'TListColumn'));
  if ListColumn = nil then
    Exit;
  ColumnIndex := ListColumn.Index;
  Images := TGtk4ListView(AData).Images;
  if Images = nil then
    Exit;
  ImageIndex := -1;

  if (ListItem = nil) and TCustomListView(TGtk4Widget(AData).LCLObject).OwnerData then
  begin
    APath := gtk_tree_model_get_path(tree_model,iter);
    ListItem := TCustomListView(TGtk4Widget(AData).LCLObject).Items[gtk_tree_path_get_indices(APath)^];
    gtk_tree_path_free(APath);
  end;

  if ListItem = nil then
    Exit;

  if ColumnIndex = 0 then
    ImageIndex := ListItem.ImageIndex
  else
    if ColumnIndex -1 <= ListItem.SubItems.Count-1 then
      ImageIndex := ListItem.SubItemImages[ColumnIndex-1];

  pb := nil;
  if (ImageIndex > -1) and (ImageIndex <= Images.Count-1) and
     (Images.Items[ImageIndex] <> nil) then
  begin
    ABmp := TBitmap(Images.Items[ImageIndex]);
    pb := Gtk4BitmapToPixbuf(ABmp);
  end;

  gv.set_instance(pb);
  PGtkCellRendererPixbuf(cell)^.set_property('pixbuf',@gv);
  if pb <> nil then
    g_object_unref(pb);
end;

procedure Gtk4WS_ListViewColumnClicked(column: PGtkTreeViewColumn; AData: GPointer); cdecl;
var
  AColumn: TListColumn;
  Msg: TLMNotify;
  NM: TNMListView;
begin
  AColumn := TListColumn(g_object_get_data(PGObject(column), 'TListColumn'));

  if (AColumn = nil) or (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then
    exit;

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := CN_NOTIFY;

  FillChar(NM{%H-}, SizeOf(NM), 0);
  NM.hdr.hwndfrom := {%H-}PtrUInt(AData);
  NM.hdr.code := LVN_COLUMNCLICK;
  NM.iItem := -1;
  NM.iSubItem := AColumn.Index;
  Msg.NMHdr := @NM.hdr;
  DeliverMessage(TGtk4Widget(AData).LCLObject, Msg);
end;

procedure TGtk4ListView.ColumnInsert(AIndex: Integer; AColumn: TListColumn);
var
  AGtkColumn: PGtkTreeViewColumn;
  PixRenderer,
  TextRenderer: PGtkCellRenderer;
  Factory: PGtkSignalListItemFactory;
  CVColumn: PGtkColumnViewColumn;
  FactoryData: PColumnFactoryData;
  ColumnSorter: PGtkSorter;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;

  if FIsColumnView then
  begin
    Factory := PGtkSignalListItemFactory(gtk4_signal_list_item_factory_new);

    New(FactoryData);
    FactoryData^.ListView := Self;
    FactoryData^.ColumnIndex := AIndex;

    if TCustomListViewAccess(LCLObject).OwnerDraw and
       (TCustomListViewAccess(LCLObject).ViewStyle = vsReport) then
    begin
      { OwnerDraw: GtkDrawingArea-based rendering }
      g_signal_connect_data(PGObject(Factory), 'setup',
        TGCallback(@Gtk4CV_FactorySetup_OwnerDraw), FactoryData, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(PGObject(Factory), 'bind',
        TGCallback(@Gtk4CV_FactoryBind_OwnerDraw), FactoryData, @Gtk4CV_FactoryDataDestroy, G_CONNECT_DEFAULT);
    end else
    begin
      { Standard: GtkBox(CheckBtn+Image+Label) rendering }
      g_signal_connect_data(PGObject(Factory), 'setup',
        TGCallback(@Gtk4CV_FactorySetup), FactoryData, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(PGObject(Factory), 'bind',
        TGCallback(@Gtk4CV_FactoryBind), FactoryData, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(PGObject(Factory), 'unbind',
        TGCallback(@Gtk4CV_FactoryUnbind), FactoryData, @Gtk4CV_FactoryDataDestroy, G_CONNECT_DEFAULT);
    end;

    CVColumn := PGtkColumnViewColumn(gtk4_column_view_column_new(
      PgChar(AColumn.Caption), PGtkListItemFactory(Factory)));
    gtk4_column_view_column_set_resizable(CVColumn, True);
    gtk4_column_view_column_set_expand(CVColumn, AIndex = 0);

    gtk4_column_view_insert_column(PGtkColumnView(FCentralWidget),
      AIndex, CVColumn);

    if AIndex <= FColumnFactories.Count then
      FColumnFactories.Insert(AIndex, Factory)
    else
      FColumnFactories.Add(Factory);
    if AIndex <= FColumnObjects.Count then
      FColumnObjects.Insert(AIndex, CVColumn)
    else
      FColumnObjects.Add(CVColumn);

    g_object_set_data(PGObject(CVColumn), PgChar('TListColumn'), gpointer(AColumn));

    { Attach a custom sorter — makes header clickable with sort arrow }
    if FColumnSorters <> nil then
    begin
      ColumnSorter := gtk4_custom_sorter_new(
        @Gtk4CV_ColumnSorterCompare, gpointer(PtrUInt(AIndex)), nil);
      gtk4_column_view_column_set_sorter(CVColumn, ColumnSorter);
      if AIndex <= FColumnSorters.Count then
        FColumnSorters.Insert(AIndex, ColumnSorter)
      else
        FColumnSorters.Add(ColumnSorter);
    end;
  end
  else
  begin
    AGtkColumn := TGtkTreeViewColumn.new;

    PixRenderer := gtk_cell_renderer_pixbuf_new();
    TextRenderer := LCLIntfCellRenderer_New;

    AGtkColumn^.pack_start(PixRenderer, False);
    AGtkColumn^.pack_start(TextRenderer, True);

    AGtkColumn^.set_cell_data_func(PixRenderer, @Gtk4WSLV_ListViewGetPixbufDataFuncForColumn, Self, nil);
    AGtkColumn^.set_cell_data_func(PGtkCellRenderer(TextRenderer), TGtkTreeCellDataFunc(@LCLIntfCellRenderer_CellDataFunc), Self, nil);

    g_object_set_data(AGtkColumn, PgChar('TListColumn'), gpointer(AColumn));

    g_signal_connect_data(AGtkColumn,'clicked', TGCallback(@Gtk4WS_ListViewColumnClicked), Self, nil, G_CONNECT_DEFAULT);
    PGtkTreeView(GetContainerWidget)^.insert_column(AGtkColumn, AIndex);
    AGtkColumn^.set_clickable(True);
  end;
end;

procedure TGtk4ListView.SetAlignment(AIndex: Integer; AColumn: TListColumn;
  AAlignment: TAlignment);
var
  AGtkColumn: PGtkTreeViewColumn;
  AFloat: Double;
  AList: PGList;
  textrenderer: PGtkCellRenderer;
  Value: TGValue;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
    exit; { GtkColumnView: alignment is handled within the factory cell widget }
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn = nil then
    exit;

  AFloat := 0;
  case AAlignment of
    taRightJustify: AFloat := 1;
    taCenter: AFloat := 0.5;
  end;


  AList := PGtkCellLayout(AGtkColumn)^.get_cells;
  // AList := gtk_tree_view_column_get_cell_renderers(AColumn);
  textrenderer := PGtkCellRenderer(g_list_last(AList)^.data);
  g_list_free(AList);

  Value.g_type := G_TYPE_FLOAT;
  Value.set_float(AFloat);
  g_object_set_property(textrenderer, PChar('xalign'), @Value);

  {now we call set alignment because it calls update over visible rows in col}
  AGtkColumn^.set_alignment(AFloat);
end;

procedure TGtk4ListView.SetColumnAutoSize(AIndex: Integer;
  AColumn: TListColumn; AAutoSize: Boolean);
const
  SizingMap: array[Boolean] of TGtkTreeViewColumnSizing = (
    GTK_TREE_VIEW_COLUMN_FIXED {2},
    GTK_TREE_VIEW_COLUMN_AUTOSIZE {1}
  );
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
    begin
      gtk4_column_view_column_set_resizable(
        PGtkColumnViewColumn(FColumnObjects[AIndex]), True);
      { GtkColumnView auto-size: use expand=True + fixed_width=-1 }
      if AAutoSize then
        gtk4_column_view_column_set_fixed_width(
          PGtkColumnViewColumn(FColumnObjects[AIndex]), -1);
    end;
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_resizable(True);
    AGtkColumn^.set_sizing(SizingMap[AAutoSize]);
  end;
end;

procedure TGtk4ListView.SetColumnCaption(AIndex: Integer; AColumn: TListColumn;
  const ACaption: String);
var
  AGtkColumn: PGtkTreeViewColumn;
  AHeaderWidget, AChild: PGtkWidget;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
      gtk4_column_view_column_set_title(
        PGtkColumnViewColumn(FColumnObjects[AIndex]), PgChar(ACaption));
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_title(PgChar(ACaption));
    { If a custom header widget (GtkBox with image+label) is set,
      also update the label inside it }
    AHeaderWidget := AGtkColumn^.get_widget;
    if (AHeaderWidget <> nil) and g_type_check_instance_is_a(
        PGTypeInstance(AHeaderWidget), gtk_box_get_type) then
    begin
      AChild := gtk4_widget_get_last_child(AHeaderWidget);
      if (AChild <> nil) and g_type_check_instance_is_a(
          PGTypeInstance(AChild), gtk_label_get_type) then
        PGtkLabel(AChild)^.set_text(PgChar(ACaption));
    end;
  end;
end;

procedure TGtk4ListView.ColumnSetImage(AIndex: Integer; AImageIndex: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
  ABox: PGtkBox;
  AImage: PGtkWidget;
  ALabel: PGtkLabel;
  ATitle: Pgchar;
  ABmp: TBitmap;
  APixbuf: PGdkPixbuf;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
    exit; { GtkColumnView: column images handled within factory }
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn = nil then
    exit;

  if (AImageIndex >= 0) and Assigned(FImages) and (AImageIndex < FImages.Count)
    and (FImages[AImageIndex] <> nil) then
  begin
    ABmp := TBitmap(FImages[AImageIndex]);
    APixbuf := Gtk4BitmapToPixbuf(ABmp);
    if APixbuf = nil then
      exit;

    { Get current column title for the label }
    ATitle := AGtkColumn^.get_title;

    { Create horizontal box with image + label }
    ABox := PGtkBox(TGtkBox.new(GTK_ORIENTATION_HORIZONTAL, 4));
    AImage := PGtkWidget(TGtkImage.new_from_pixbuf(APixbuf));
    g_object_unref(APixbuf);
    ALabel := TGtkLabel.new(ATitle);

    gtk4_box_append(ABox, AImage);
    gtk4_box_append(ABox, PGtkWidget(ALabel));

    { Replace default header with custom widget }
    AGtkColumn^.set_widget(PGtkWidget(ABox));
  end else
  begin
    { Remove custom header widget, revert to title }
    AGtkColumn^.set_widget(nil);
  end;
end;

procedure TGtk4ListView.SetColumnMaxWidth(AIndex: Integer;
  AColumn: TListColumn; AMaxWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
    Exit; { GtkColumnViewColumn has no max-width API }
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    if AMaxWidth <= 0 then
      AGtkColumn^.set_max_width(10000)
    else
      AGtkColumn^.set_max_width(AMaxWidth);
  end;
end;

procedure TGtk4ListView.SetColumnMinWidth(AIndex: Integer;
  AColumn: TListColumn; AMinWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
  begin
    { GtkColumnViewColumn: use fixed_width as minimum when positive }
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) and (AMinWidth > 0) then
      gtk4_column_view_column_set_fixed_width(
        PGtkColumnViewColumn(FColumnObjects[AIndex]), AMinWidth);
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
    AGtkColumn^.set_min_width(AMinWidth);
end;

procedure TGtk4ListView.SetColumnWidth(AIndex: Integer; AColumn: TListColumn;
  AWidth: Integer);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
      gtk4_column_view_column_set_fixed_width(
        PGtkColumnViewColumn(FColumnObjects[AIndex]), AWidth + Ord(AWidth < 1));
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_fixed_width(AWidth + Ord(AWidth < 1));
  end;
end;

procedure TGtk4ListView.SetColumnVisible(AIndex: Integer; AColumn: TListColumn;
  AVisible: Boolean);
var
  AGtkColumn: PGtkTreeViewColumn;
begin
  if not IsWidgetOK or not IsTreeView then
    exit;
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
      gtk4_column_view_column_set_visible(
        PGtkColumnViewColumn(FColumnObjects[AIndex]),
        AVisible and (TListView(LCLObject).ViewStyle in [vsList, vsReport]));
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);
  if AGtkColumn <> nil then
  begin
    AGtkColumn^.set_visible(AVisible and (TListView(LCLObject).ViewStyle in [vsList, vsReport]));
  end;
end;

procedure TGtk4ListView.ColumnSetSortIndicator(const AIndex: Integer;
  const AColumn: TListColumn; const ASortIndicator: TSortIndicator);
const
  GtkOrder : array [ TSortIndicator] of TGtkSortType = (GTK_SORT_ASCENDING {0}, GTK_SORT_ASCENDING {0}, GTK_SORT_DESCENDING {1});
var
  AGtkColumn: PGtkTreeViewColumn;
  CVColumn: PGtkColumnViewColumn;
begin
  if FIsColumnView then
  begin
    if (AIndex >= 0) and (AIndex < FColumnObjects.Count) then
    begin
      CVColumn := PGtkColumnViewColumn(FColumnObjects[AIndex]);
      if ASortIndicator = siNone then
        gtk4_column_view_sort_by_column(PGtkColumnView(FCentralWidget), nil, GTK_SORT_ASCENDING)
      else
        gtk4_column_view_sort_by_column(PGtkColumnView(FCentralWidget), CVColumn, GtkOrder[ASortIndicator]);
    end;
    Exit;
  end;
  AGtkColumn := PGtkTreeView(getContainerWidget)^.get_column(AIndex);

  if AGtkColumn <> nil then
  begin
    if ASortIndicator = siNone then
      AGtkColumn^.set_sort_indicator(false)
    else
    begin
      AGtkColumn^.set_sort_indicator(true);
      AgtkColumn^.set_sort_order(GtkOrder[ASortIndicator]);
    end;
  end;
end;

procedure TGtk4ListView.ItemDelete(AIndex: Integer);
var
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
begin
  if FIsColumnView or FIsGridView then
  begin
    if (FListModel <> nil) and (AIndex >= 0) then
    begin
      gtk4_string_list_remove(PGtkStringList(FListModel), AIndex);
      { Emptied by a Clear (LCL deletes down to 0): remember to reset the scroll
        to the top on EndUpdate. GTK keeps the old adjustment value across a
        model refill, so switching to another page would otherwise leave the
        view scrolled to the previous position (qt5 resets to top). }
      if g_list_model_get_n_items(PGListModel(FListModel)) = 0 then
        FWasCleared := True;
    end;
    Exit;
  end;
  AModel := PGtkTreeView(getContainerWidget)^.get_model;
  if gtk_tree_model_iter_nth_child(AModel, @Iter, nil, AIndex) then
    gtk_list_store_remove(PGtkListStore(AModel), @Iter);
end;

procedure TGtk4ListView.ItemInsert(AIndex: Integer; AItem: TListItem);
var
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
  NewIndex: Integer;
  EmptyStr: Pgchar;
  EmptyArr: array[0..1] of Pgchar;
begin
  if not IsWidgetOK then
    exit;
  if FIsColumnView or FIsGridView then
  begin
    { Insert empty placeholder string into GtkStringList }
    if FListModel <> nil then
    begin
      EmptyStr := PgChar('');
      EmptyArr[0] := EmptyStr;
      EmptyArr[1] := nil;
      if AIndex = -1 then
        gtk4_string_list_append(PGtkStringList(FListModel), EmptyStr)
      else
        gtk4_string_list_splice(PGtkStringList(FListModel), AIndex, 0, @EmptyArr[0]);
    end;
    Exit;
  end;
  AModel := PGtkTreeView(getContainerWidget)^.get_model;

  if AIndex = -1 then
    NewIndex := AModel^.iter_n_children(nil)
  else
    NewIndex := AIndex;

  gtk_list_store_insert_with_values(PGtkListStore(AModel), @Iter, NewIndex,
    [0, Pointer(AItem), -1]);
end;

{ Force a factory rebind of one ColumnView/GridView row. queue_draw only
  repaints the existing cell widgets — it never re-runs the factory bind —
  so per-item visual changes (state image, image index) would stay stale
  until the row is recycled. Emitting items_changed alone is ALSO not
  enough: GtkListItemManager reacquires the released widget when the item
  object at the position is unchanged, and gtk_list_item_widget_update
  rebinds only when the item differs (gtklistitemmanager.c
  try_reacquire_list_item). Therefore splice the GtkStringList row so the
  placeholder object really is replaced — the reacquire fails and the
  factory setup/bind runs again. The selection model drops selection for
  a replaced item, so save and restore it. }
procedure TGtk4ListView.ItemRebindRow(AIndex: Integer);
var
  WasSelected: Boolean;
  EmptyArr: array[0..1] of Pgchar;
begin
  if not IsWidgetOK then Exit;
  if not (FIsColumnView or FIsGridView) then Exit;
  if (FListModel = nil) or (FSelectionModel = nil) then Exit;
  if (AIndex < 0) or
     (guint(AIndex) >= g_list_model_get_n_items(PGListModel(FListModel))) then
    Exit;
  WasSelected := gtk4_selection_model_is_selected(
    PGtkSelectionModel(FSelectionModel), guint(AIndex));
  BeginUpdate; { suppress selection-changed feedback to the LCL }
  try
    EmptyArr[0] := PgChar('');
    EmptyArr[1] := nil;
    gtk4_string_list_splice(PGtkStringList(FListModel), guint(AIndex), 1,
      @EmptyArr[0]);
    if WasSelected then
      gtk4_selection_model_select_item(PGtkSelectionModel(FSelectionModel),
        guint(AIndex), False);
  finally
    EndUpdate;
  end;
end;

{ Rebind every ColumnView/GridView row — used when a whole image list is
  (re)assigned at runtime and already-bound rows must pick it up. Splices
  the entire GtkStringList so every placeholder object is replaced (see
  ItemRebindRow for why items_changed with unchanged objects is not
  enough), saving and restoring the selected positions. }
procedure TGtk4ListView.RebindAllRows;
var
  N, i: guint;
  j: Integer;
  Selected: TFPList;
  Additions: array of Pgchar;
begin
  if not IsWidgetOK then Exit;
  if not (FIsColumnView or FIsGridView) then Exit;
  if (FListModel = nil) or (FSelectionModel = nil) then Exit;
  N := g_list_model_get_n_items(PGListModel(FListModel));
  if N = 0 then Exit;
  Selected := TFPList.Create;
  BeginUpdate; { suppress selection-changed feedback to the LCL }
  try
    for i := 0 to N - 1 do
      if gtk4_selection_model_is_selected(
           PGtkSelectionModel(FSelectionModel), i) then
        Selected.Add({%H-}Pointer(PtrUInt(i)));
    SetLength(Additions, N + 1);
    for i := 0 to N - 1 do
      Additions[i] := PgChar('');
    Additions[N] := nil;
    gtk4_string_list_splice(PGtkStringList(FListModel), 0, N, @Additions[0]);
    for j := 0 to Selected.Count - 1 do
      gtk4_selection_model_select_item(PGtkSelectionModel(FSelectionModel),
        guint({%H-}PtrUInt(Selected[j])), False);
  finally
    EndUpdate;
    Selected.Free;
  end;
end;

procedure TGtk4ListView.preferredSize(var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  { A SCROLLING list must report a BOUNDED preferred size, not its full content
    extent. TGtk4Widget.preferredSize measures GetContainerWidget (the
    ColumnView/TreeView), whose natural size spans every row. Inside an
    autosizing parent (e.g. the options-page TScrollBox) that inflates the frame
    to fit all rows, so the list is allocated its whole content height, loses its
    own scrollbar, and the outer scrollbox scrolls instead — the content jumps
    out of view on a page switch (qt5 keeps a fixed-height list with its own
    scrollbar).

    Measure the GtkScrolledWindow (FWidget) instead of the content: with
    propagate-natural off (see CreateWidget) it returns a bounded value, so the
    real size comes from the LCL align/anchors (viewport) with the list scrolling
    internally. A list WITHOUT scrollbars (ssNone) is meant to show everything,
    so keep the content-based preferred there. }
  if (LCLObject is TListView)
  and (TListView(LCLObject).ScrollBars = ssNone) then
  begin
    inherited preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
    Exit;
  end;
  PreferredWidth := 0;
  PreferredHeight := 0;
  if not (IsWidgetOK and Gtk4IsScrolledWindow(PGObject(FWidget))) then Exit;
  gtk4_widget_measure(FWidget, GTK_ORIENTATION_HORIZONTAL, -1, nil,
    @PreferredWidth, nil, nil);
  gtk4_widget_measure(FWidget, GTK_ORIENTATION_VERTICAL, -1, nil,
    @PreferredHeight, nil, nil);
end;

procedure TGtk4ListView.EndUpdate;
var
  ASW: PGtkScrolledWindow;
  AAdj: PGtkAdjustment;
  DoRebind, DoResetScroll: Boolean;
begin
  inherited EndUpdate;
  if InUpdate then Exit;   { only act when the outermost batch closes }
  { Snapshot and clear the deferred-work flags up front. RebindAllRows below runs
    its own Begin/EndUpdate, which re-enters this method; clearing first makes
    that re-entrant call a no-op so each action runs exactly once, in this
    (outermost) frame. }
  DoRebind := FRowsDirty;
  DoResetScroll := FWasCleared;
  FRowsDirty := False;
  FWasCleared := False;
  { A single deferred ColumnView/GridView factory rebind (requested by
    ItemSetText during the batch) so rows show text set after their placeholder
    was bound. }
  if DoRebind then
    RebindAllRows;
  { If the model was emptied by a Clear this batch (a page/content switch), reset
    the scroll to the top-left. GTK preserves the old adjustment value across a
    model refill, so without this the new (often shorter) list stays scrolled to
    the previous position — qt5 resets to the top. }
  if DoResetScroll then
  begin
    ASW := GetScrolledWindow;
    if ASW <> nil then
    begin
      AAdj := ASW^.get_vadjustment;
      if AAdj <> nil then AAdj^.set_value(0);
      AAdj := ASW^.get_hadjustment;
      if AAdj <> nil then AAdj^.set_value(0);
    end;
  end;
end;

procedure TGtk4ListView.ModelNotifyItemsChanged;
var
  N: guint;
  AModel: PGtkTreeModel;
  Iter: TGtkTreeIter;
  LV: TCustomListView;
  I: Integer;
begin
  if not IsWidgetOK then Exit;
  LV := TCustomListView(LCLObject);
  if LV = nil then Exit;
  if FIsColumnView or FIsGridView then
  begin
    { Signal that all items changed — forces factory rebind of visible rows.
      MUST use the actual GTK model item count, NOT LV.Items.Count, because
      during InitializeWnd SetSort is called BEFORE items are synced to the
      model (WSCreateItems). Using LV.Items.Count when the model is empty
      emits an invalid items_changed signal (removed=N on 0-item model),
      causing GtkColumnView to enter an infinite loop. }
    if FListModel <> nil then
    begin
      N := g_list_model_get_n_items(PGListModel(FListModel));
      if N > 0 then
        g_list_model_items_changed(PGListModel(FListModel), 0, N, N);
    end;
    Exit;
  end;
  { TreeView: model stores Pointer(AItem) per row — must reorder rows }
  N := LV.Items.Count;
  if N = 0 then Exit;
  AModel := PGtkTreeView(GetContainerWidget)^.get_model;
  if AModel = nil then Exit;
  gtk_list_store_clear(PGtkListStore(AModel));
  for I := 0 to LV.Items.Count - 1 do
    gtk_list_store_insert_with_values(PGtkListStore(AModel), @Iter, I,
      [0, Pointer(LV.Items[I]), -1]);
end;

procedure TGtk4ListView.UpdateItem(AIndex:integer;AItem: TListItem);
var
  Path: PGtkTreePath;
  ItemRect: TGdkRectangle;
begin
  if FIsColumnView or FIsGridView then
  begin
    { GtkColumnView/GtkGridView: trigger rebind by queue_draw }
    if IsWidgetOK then
      GetContainerWidget^.queue_draw;
    Exit;
  end;
  Path := gtk_tree_path_new_from_indices(AIndex, [-1]);
  PGtkTreeView(GetContainerWidget)^.get_cell_area(Path, nil, @ItemRect);
  gtk_tree_path_free(Path);
end;

procedure TGtk4ListView.ItemSetText(AIndex, ASubIndex: Integer;
  AItem: TListItem; const AText: String);
var
  Path: PGtkTreePath;
  ItemRect: TGdkRectangle;
  AContainer: PGtkWidget;
begin
  if not IsWidgetOK then
    exit;
  if FIsColumnView or FIsGridView then
  begin
    { GtkColumnView/GtkGridView: the factory binds a row as soon as ItemInsert
      appends its placeholder — which, for a live/realized view, happens BEFORE
      the LCL fills in Caption/SubItems. queue_draw only repaints existing cell
      widgets, it never re-runs the factory bind (see ItemRebindRow), so the
      just-set text would never appear (row stays blank after a refill).
      During a BeginUpdate/EndUpdate batch (bulk fill) defer to a single
      RebindAllRows in EndUpdate — rebinding per cell would splice the model
      once per subitem (O(cells), visibly slow for large lists). Outside a
      batch (single-cell edit) rebind just this row immediately. }
    if InUpdate then
      FRowsDirty := True
    else
      ItemRebindRow(AIndex);
    Exit;
  end;
  if IsTreeView then
  begin
    Path := gtk_tree_path_new_from_indices(AIndex, [-1]);
    if GetContainerWidget^.get_realized then
    begin
      PGtkTreeView(GetContainerWidget)^.get_cell_area(Path, nil, @ItemRect);
    end;
    gtk_tree_path_free(Path);
  end else
  begin
    UpdateItem(AIndex, AItem);
  end;
  AContainer := GetContainerWidget;
  if Gtk4IsWidget(AContainer) and (not AContainer^.in_destruction)
    and (ItemRect.height <> 0) then
    AContainer^.queue_draw;
end;

procedure TGtk4ListView.ItemSetImage(AIndex, ASubIndex: Integer; AItem: TListItem);
var
  Path: PGtkTreePath;
  ItemRect: TGdkRectangle;
  AContainer: PGtkWidget;
begin
  if not IsWidgetOK then
    exit;
  if FIsColumnView or FIsGridView then
  begin
    GetContainerWidget^.queue_draw;
    Exit;
  end;
  if IsTreeView then
  begin
    Path := gtk_tree_path_new_from_indices(AIndex, [-1]);
    if GetContainerWidget^.get_realized then
    begin
      PGtkTreeView(GetContainerWidget)^.get_cell_area(Path, nil, @ItemRect);
    end;
    gtk_tree_path_free(Path);
  end else
  begin
    UpdateItem(AIndex, AItem);
  end;
  AContainer := GetContainerWidget;
  if Gtk4IsWidget(AContainer) and (not AContainer^.in_destruction)
    and (ItemRect.height <> 0) then
    AContainer^.queue_draw;
end;

procedure TGtk4ListView.ItemSetState(const AIndex: Integer;
  const AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean);
var
  Path: PGtkTreePath;
  ATreeSelection: PGtkTreeSelection;
begin
  if not IsWidgetOK then
    exit;

  { GtkColumnView/GtkGridView path — uses GtkSelectionModel }
  if FIsColumnView or FIsGridView then
  begin
    case AState of
      lisSelected:
      begin
        if AIsSet then
          gtk4_selection_model_select_item(
            PGtkSelectionModel(FSelectionModel), AIndex, False)
        else
          gtk4_selection_model_unselect_item(
            PGtkSelectionModel(FSelectionModel), AIndex);
      end;
      lisFocused:
      begin
        { GTK 4.6 has no scroll_to / focus API for ColumnView/GridView items.
          Selection is the closest approximation. }
      end;
    end;
    Exit;
  end;

  case AState of
    lisCut,
    lisDropTarget:
    begin
      { Not implemented in GTK2 or Qt5 backends either. }
    end;

    lisFocused:
    begin
      Path := gtk_tree_path_new_from_string(PgChar(IntToStr(AIndex)));
      if AIsSet then
        PGtkTreeView(getContainerWidget)^.set_cursor(Path, nil, False)
      else
        PGtkTreeView(GetContainerWidget)^.set_cursor(Path, nil, False);
      if Path <> nil then
        gtk_tree_path_free(Path);
    end;

    lisSelected:
    begin
      Path := gtk_tree_path_new_from_string(PgChar(IntToStr(AIndex)));
      ATreeSelection := PGtkTreeView(GetContainerWidget)^.get_selection;
      if AIsSet and not ATreeSelection^.path_is_selected(Path) then
        ATreeSelection^.select_path(Path)
      else
      if not AIsSet and ATreeSelection^.path_is_selected(Path) then
        ATreeSelection^.unselect_path(Path);
      if Path <> nil then
        gtk_tree_path_free(Path);
    end;
  end;

end;

function TGtk4ListView.ItemGetState(const AIndex: Integer;
  const AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean
  ): Boolean;
var
  Path: PGtkTreePath;
  Column: PPGtkTreeViewColumn;
  APath: PGtkTreePath;
  AStr: PChar;
begin
  Result := False;
  AIsSet := False;
  if not IsWidgetOK then
    exit;

  { GtkColumnView/GtkGridView path — uses GtkSelectionModel }
  if FIsColumnView or FIsGridView then
  begin
    case AState of
      lisSelected:
      begin
        AIsSet := gtk4_selection_model_is_selected(
          PGtkSelectionModel(FSelectionModel), AIndex);
        Result := True;
      end;
      lisFocused:
      begin
        { GTK 4.6 has no direct focus query for ColumnView/GridView items.
          Return False (not focused). }
        Result := True;
        AIsSet := False;
      end;
    end;
    Exit;
  end;

  case AState of
    lisCut,
    lisDropTarget:
    begin
      { Not implemented in GTK2 or Qt5 backends either. }
    end;
    lisFocused:
    begin
      Path := nil;
      Column := nil;
      PGtkTreeView(GetContainerWidget)^.get_cursor(@Path, Column);
      if Assigned(Path) then
      begin
        AStr := gtk_tree_path_to_string(Path);
        AIsSet := (StrToIntDef(AStr,-1) = AIndex);
        if AStr <> nil then
          g_free(AStr);
        gtk_tree_path_free(Path);
        Result := True;
      end;
    end;

    lisSelected:
    begin
      APath := gtk_tree_path_new_from_string(PChar(IntToStr(AIndex)));
      AIsSet := PGtkTreeView(GetContainerWidget)^.get_selection^.path_is_selected(APath);
      if APath <> nil then
        gtk_tree_path_free(APath);
      Result := True;
    end;
  end;
end;

procedure TGtk4ListView.UpdateImageCellsSize;
var
  i: Integer;
  ATreeView: PGtkTreeView;
  AGtkColumn: PGtkTreeViewColumn;
  AList: PGList;
  APixRenderer: PGtkCellRenderer;
  ABmp: TBitmap;
  AWidth, AHeight: gint;
  ANumCols: Integer;
begin
  if not IsWidgetOK or not IsTreeView or FIsColumnView then Exit;
  if (Images = nil) or (Images.Count = 0) then Exit;
  ABmp := TBitmap(Images.Items[0]);
  AWidth := ABmp.Width + 2;
  AHeight := ABmp.Height + 2;
  ATreeView := PGtkTreeView(GetContainerWidget);
  ANumCols := ATreeView^.get_n_columns;
  for i := 0 to ANumCols - 1 do
  begin
    AGtkColumn := ATreeView^.get_column(i);
    if AGtkColumn = nil then Continue;
    AList := PGtkCellLayout(AGtkColumn)^.get_cells;
    if AList = nil then Continue;
    { PixRenderer is packed first in ColumnInsert, so it is the first cell }
    APixRenderer := PGtkCellRenderer(g_list_first(AList)^.data);
    g_list_free(AList);
    if APixRenderer <> nil then
      APixRenderer^.set_fixed_size(AWidth, AHeight);
    AGtkColumn^.queue_resize;
  end;
end;

procedure TGtk4ListView.AddRemoveCheckboxRenderer(const Add: Boolean);
var
  AGtkColumn: PGtkTreeViewColumn;
  PixRenderer,
  TextRenderer: PGtkCellRenderer;
  ToggleRenderer: PGtkCellRendererToggle;
begin
  if not IsWidgetOK or not IsTreeView then
    Exit;

  if FIsColumnView then
  begin
    FCheckboxes := Add;
    { Trigger factory rebind so Bind callback shows/hides checkboxes }
    GetContainerWidget^.queue_draw;
    Exit;
  end;

  AGtkColumn := PGtkTreeView(GetContainerWidget)^.get_column(0);
  if AGtkColumn = nil then
    Exit;

  { Clear all renderers from the column }
  gtk_cell_layout_clear(PGtkCellLayout(AGtkColumn));

  if Add then
  begin
    { Create and pack: Toggle → Pixbuf → Text }
    ToggleRenderer := gtk_cell_renderer_toggle_new;
    PixRenderer := gtk_cell_renderer_pixbuf_new;
    TextRenderer := LCLIntfCellRenderer_New;

    AGtkColumn^.pack_start(PGtkCellRenderer(ToggleRenderer), False);
    AGtkColumn^.pack_start(PixRenderer, False);
    AGtkColumn^.pack_start(TextRenderer, True);

    AGtkColumn^.set_cell_data_func(PGtkCellRenderer(ToggleRenderer),
      @Gtk4WSLV_ListViewGetCheckedDataFunc, Self, nil);
    AGtkColumn^.set_cell_data_func(PixRenderer,
      @Gtk4WSLV_ListViewGetPixbufDataFuncForColumn, Self, nil);
    AGtkColumn^.set_cell_data_func(PGtkCellRenderer(TextRenderer),
      TGtkTreeCellDataFunc(@LCLIntfCellRenderer_CellDataFunc), Self, nil);

    g_signal_connect_data(ToggleRenderer, 'toggled',
      TGCallback(@Gtk4WS_ListViewItemCheckedChanged), Self, nil, G_CONNECT_DEFAULT);
  end
  else
  begin
    { Create and pack: Pixbuf → Text (no toggle) }
    PixRenderer := gtk_cell_renderer_pixbuf_new;
    TextRenderer := LCLIntfCellRenderer_New;

    AGtkColumn^.pack_start(PixRenderer, False);
    AGtkColumn^.pack_start(TextRenderer, True);

    AGtkColumn^.set_cell_data_func(PixRenderer,
      @Gtk4WSLV_ListViewGetPixbufDataFuncForColumn, Self, nil);
    AGtkColumn^.set_cell_data_func(PGtkCellRenderer(TextRenderer),
      TGtkTreeCellDataFunc(@LCLIntfCellRenderer_CellDataFunc), Self, nil);
  end;
end;

procedure TGtk4ListView.SetHideSelection(AValue: Boolean);
begin
  if FHideSelection = AValue then Exit;
  FHideSelection := AValue;
  if not IsWidgetOK then Exit;
  { Use global CSS class '.lcl-hide-sel' defined in TGtk4WidgetSet.Create }
  if AValue then
    gtk4_widget_add_css_class(GetContainerWidget, 'lcl-hide-sel')
  else
    gtk4_widget_remove_css_class(GetContainerWidget, 'lcl-hide-sel');
end;

{ TGtk4ComboBox }

function TGtk4ComboBox.PopoverVisible: Boolean;
begin
  Result := (FPopover <> nil) and Gtk4IsWidget(FPopover) and
    (not FPopover^.in_destruction) and FPopover^.get_visible;
end;

function TGtk4ComboBox.GetItemIndex: Integer;
var
  Sel: guint;
begin
  Result := -1;
  if PopoverVisible then
    Exit(FCommittedIndex); { the model only previews while dropped down }
  if FSelectionModel <> nil then
  begin
    Sel := gtk4_single_selection_get_selected(PGtkSingleSelection(FSelectionModel));
    if Sel <> GTK_INVALID_LIST_POSITION then
      Result := Integer(Sel);
  end;
end;

procedure TGtk4ComboBox.SetDroppedDown(AValue: boolean);
begin
  if not IsWidgetOK then Exit;
  if (FPopover = nil) or not Gtk4IsWidget(FPopover) or FPopover^.in_destruction then Exit;
  if AValue then
    gtk4_popover_popup(FPopover)
  else
    gtk4_popover_popdown(FPopover);
end;

procedure TGtk4ComboBox.SetItemIndex(AValue: Integer);
var
  AText: PChar;
begin
  if FSelectionModel = nil then Exit;
  if AValue < 0 then
    FCommittedIndex := -1
  else
    FCommittedIndex := AValue;
  if AValue < 0 then
  begin
    gtk4_single_selection_set_selected(PGtkSingleSelection(FSelectionModel),
      GTK_INVALID_LIST_POSITION);
    if FEntry <> nil then
    begin
      ApplyPendingSelStart; { keep the "SelStart := a; ItemIndex := i" order }
      BeginEntryWrite;
      try
        gtk4_editable_set_text(FEntry, '');
      finally
        EndEntryWrite;
      end;
    end;
  end else
  begin
    gtk4_single_selection_set_selected(PGtkSingleSelection(FSelectionModel), guint(AValue));
    { Sync entry text with selected item }
    if FEntry <> nil then
    begin
      AText := gtk4_string_list_get_string(PGtkStringList(FListModel), guint(AValue));
      if AText <> nil then
      begin
        ApplyPendingSelStart;
        BeginEntryWrite;
        try
          gtk4_editable_set_text(FEntry, AText);
        finally
          EndEntryWrite;
        end;
      end;
    end;
  end;
end;

{ ---- Editable ComboBox factory callbacks ---- }

procedure Gtk4ECB_FactorySetup({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  ALabel: PGtkWidget;
begin
  ALabel := TGtkLabel.new('');
  PGtkLabel(ALabel)^.set_xalign(0);
  ALabel^.set_halign(GTK_ALIGN_FILL);
  gtk4_list_item_set_child(listitem, ALabel);
end;

procedure Gtk4ECB_FactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; {%H-}user_data: gpointer); cdecl;
var
  ALabel: PGtkWidget;
  AItem: PGtkStringObject;
  AText: PChar;
begin
  ALabel := gtk4_list_item_get_child(listitem);
  AItem := PGtkStringObject(gtk4_list_item_get_item(listitem));
  if AItem <> nil then
  begin
    AText := gtk4_string_object_get_string(AItem);
    gtk_label_set_text(PGtkLabel(ALabel), AText);
  end;
end;

{ ---- Editable ComboBox signal callbacks ---- }

procedure Gtk4ECB_EntryChanged({%H-}AEditable: PGtkWidget; AData: gpointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    if TGtk4Widget(AData).InUpdate then
      Exit;
    { Design mode: do not report combo text changes or the design-time
      Text/ItemIndex would be corrupted. }
    if Assigned(TGtk4Widget(AData).LCLObject) and
       (csDesigning in TGtk4Widget(AData).LCLObject.ComponentState) then
      Exit;
    FillChar(Msg{%H-}, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    TGtk4Widget(AData).DeliverMessage(Msg);
  end;
end;

procedure Gtk4ECB_ButtonClicked({%H-}AButton: PGtkWidget; AData: gpointer); cdecl;
var
  ACombo: TGtk4ComboBox;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  ACombo := TGtk4ComboBox(AData);
  if not ACombo.IsWidgetOK then Exit;
  { Design mode: do not open the dropdown — the designer owns the click. }
  if Assigned(ACombo.LCLObject) and
     (csDesigning in ACombo.LCLObject.ComponentState) then Exit;
  if (ACombo.FPopover = nil) or not Gtk4IsWidget(ACombo.FPopover)
    or ACombo.FPopover^.in_destruction then Exit;
  if ACombo.FPopover^.get_visible then
    gtk4_popover_popdown(ACombo.FPopover)
  else
  begin
    { Match popover width to the combo box width. IntfGetItems and
      CBN_DROPDOWN are sent once from the notify::visible handler (like the
      GTK2 popup-shown handler), for this path and SetDroppedDown alike. }
    ACombo.FPopover^.set_size_request(
      ACombo.Widget^.get_allocated_width, -1);
    gtk4_popover_popup(ACombo.FPopover);
  end;
end;

procedure Gtk4ECB_SelectionChanged({%H-}AModel: PGtkSelectionModel;
  {%H-}position: guint; {%H-}n_items: guint; AData: gpointer); cdecl;
var
  ACombo: TGtk4ComboBox;
  Sel: guint;
  AText: PChar;
  Msg: TLMessage;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  ACombo := TGtk4ComboBox(AData);
  if not ACombo.IsWidgetOK then Exit;
  if ACombo.InUpdate then Exit;
  { Design mode: do not apply selection changes or the design-time
    ItemIndex/Text would be corrupted. }
  if Assigned(ACombo.LCLObject) and
     (csDesigning in ACombo.LCLObject.ComponentState) then Exit;
  { While the dropdown is open the selection only previews (hover, arrow keys);
    the commit happens in Gtk4ECB_ListActivate (click / Return). }
  if ACombo.PopoverVisible then Exit;
  Sel := gtk4_single_selection_get_selected(PGtkSingleSelection(ACombo.FSelectionModel));
  if Sel <> GTK_INVALID_LIST_POSITION then
  begin
    ACombo.FCommittedIndex := Integer(Sel);
    { Update entry text }
    AText := gtk4_string_list_get_string(PGtkStringList(ACombo.FListModel), Sel);
    if (ACombo.FEntry <> nil) and (AText <> nil) then
    begin
      ACombo.ApplyPendingSelStart;
      ACombo.BeginUpdate;
      ACombo.BeginEntryWrite;
      try
        gtk4_editable_set_text(ACombo.FEntry, AText);
      finally
        ACombo.EndEntryWrite;
        ACombo.EndUpdate;
      end;
    end;
    { Close popover }
    if (ACombo.FPopover <> nil) and Gtk4IsWidget(ACombo.FPopover)
      and (not ACombo.FPopover^.in_destruction)
      and ACombo.FPopover^.get_visible then
      gtk4_popover_popdown(ACombo.FPopover);
    { Notify LCL }
    FillChar(Msg{%H-}, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    ACombo.DeliverMessage(Msg);
  end;
end;

procedure Gtk4ECB_PopoverNotifyVisible({%H-}AObject: PGObject;
  {%H-}pspec: PGParamSpec; AData: GPointer); cdecl;
var
  ACombo: TGtk4ComboBox;
  Sel: guint;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  ACombo := TGtk4ComboBox(AData);
  if not ACombo.IsWidgetOK then Exit;
  if (ACombo.FPopover = nil) or not Gtk4IsWidget(ACombo.FPopover)
    or ACombo.FPopover^.in_destruction then Exit;
  if ACombo.FPopover^.get_visible then
  begin
    { opening: the model holds the committed index - remember it, the model
      becomes a preview until activate / cancel }
    ACombo.FActivated := False;
    ACombo.FCommittedIndex := -1;
    if ACombo.FSelectionModel <> nil then
    begin
      Sel := gtk4_single_selection_get_selected(PGtkSingleSelection(ACombo.FSelectionModel));
      if Sel <> GTK_INVALID_LIST_POSITION then
        ACombo.FCommittedIndex := Integer(Sel);
    end;
    { GTK2 order: let the LCL fill the items just in time, then CBN_DROPDOWN -
      exactly once, for the arrow button and SetDroppedDown alike }
    if Assigned(ACombo.LCLObject) and (ACombo.LCLObject is TCustomComboBox) then
      TCustomComboBox(ACombo.LCLObject).IntfGetItems;
    { OnGetItems is user code: re-validate before the notification, and
      nothing may follow it (OnDropDown may close or destroy the combo) }
    if not Gtk4IsLiveWidgetPointer(AData) then Exit;
    if not ACombo.CanSendLCLMessage then Exit;
    if not ACombo.PopoverVisible then Exit;
    LCLSendDropDownMsg(TCustomComboBox(ACombo.LCLObject));
  end else
  begin
    if not ACombo.FActivated then
    begin
      { cancelled (Escape / outside click / programmatic close): drop the preview }
      if ACombo.FSelectionModel <> nil then
      begin
        if (ACombo.FCommittedIndex >= 0) and
           (ACombo.FCommittedIndex < Integer(g_list_model_get_n_items(PGListModel(ACombo.FListModel)))) then
          Sel := guint(ACombo.FCommittedIndex)
        else
        begin
          Sel := GTK_INVALID_LIST_POSITION;
          ACombo.FCommittedIndex := -1;
        end;
        ACombo.BeginUpdate;
        try
          gtk4_single_selection_set_selected(PGtkSingleSelection(ACombo.FSelectionModel), Sel);
        finally
          ACombo.EndUpdate;
        end;
      end;
    end;
    ACombo.FActivated := False;
    { the LCL close-up handler may destroy the combo: nothing after this call }
    LCLSendCloseUpMsg(ACombo.LCLObject);
  end;
end;

{ GtkListView::activate - click (single-click-activate) or Return on a row }
procedure Gtk4ECB_ListActivate({%H-}AList: PGtkWidget; position: guint; AData: gpointer); cdecl;
var
  ACombo: TGtk4ComboBox;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  ACombo := TGtk4ComboBox(AData);
  if not ACombo.IsWidgetOK then Exit;
  if ACombo.InUpdate then Exit;
  if Assigned(ACombo.LCLObject) and
     (csDesigning in ACombo.LCLObject.ComponentState) then Exit;
  if position = GTK_INVALID_LIST_POSITION then Exit;
  ACombo.CommitSelection(Integer(position));
end;

function TGtk4ComboBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  ABox: PGtkWidget;
  StringList: PGtkStringList;
  Factory: PGtkSignalListItemFactory;
  ItemList: TGtkStringListStrings;
  ACombo: TCustomComboBox;
  DropH: Integer;
begin
  FWidgetType := FWidgetType + [wtComboBox];
  ACombo := TCustomComboBox(LCLObject);
  FOwnerDrawn := ACombo.Style.IsOwnerDrawn;

  { Main container: GtkBox (horizontal) with linked style }
  ABox := PGtkWidget(TGtkBox.new(GTK_ORIENTATION_HORIZONTAL, 0));
  gtk4_widget_add_css_class(ABox, 'linked');
  Result := ABox;

  { GtkEntry — text input }
  FEntry := PGtkWidget(TGtkEntry.new);
  gtk4_box_append(PGtkBox(ABox), FEntry);
  FEntry^.set_hexpand(True);
  g_object_set_data(PGObject(FEntry), 'lclwidget', Self);
  if ACombo.ReadOnly then
    PGtkEditable(FEntry)^.set_editable(False);

  { Set initial text }
  if Self.LCLObject.Caption <> '' then
    gtk4_editable_set_text(FEntry, PChar(Self.LCLObject.Caption));

  { Dropdown button with arrow icon }
  FButton := PGtkWidget(TGtkButton.new);
  gtk4_button_set_child(PGtkButton(FButton),
    gtk4_image_new_from_icon_name('pan-down-symbolic'));
  gtk4_widget_add_css_class(FButton, 'combo');
  FButton^.set_can_focus(False);
  gtk4_box_append(PGtkBox(ABox), FButton);

  { Model: GtkStringList + GtkSingleSelection }
  StringList := gtk4_string_list_new(nil);
  FListModel := StringList;
  FSelectionModel := gtk4_single_selection_new(PGListModel(StringList));
  gtk4_single_selection_set_autoselect(PGtkSingleSelection(FSelectionModel), False);
  gtk4_single_selection_set_can_unselect(PGtkSingleSelection(FSelectionModel), True);

  { Factory: simple label for each item }
  Factory := gtk4_signal_list_item_factory_new;
  g_signal_connect_data(PGObject(Factory), 'setup',
    TGCallback(@Gtk4ECB_FactorySetup), nil, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(PGObject(Factory), 'bind',
    TGCallback(@Gtk4ECB_FactoryBind), nil, nil, G_CONNECT_DEFAULT);

  { GtkListView inside a ScrolledWindow }
  FListView := PGtkWidget(gtk4_list_view_new(
    PGtkSelectionModel(FSelectionModel), PGtkListItemFactory(Factory)));
  gtk4_list_view_set_single_click_activate(PGtkListView(FListView), True);
  FScrollWin := PGtkWidget(gtk4_scrolled_window_new);
  PGtkScrolledWindow(FScrollWin)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
  gtk4_scrolled_window_set_child(PGtkScrolledWindow(FScrollWin), FListView);

  { Dropdown height: use DropDownCount if set, otherwise default 200px }
  FDropDownCount := ACombo.DropDownCount;
  if FDropDownCount > 0 then
    DropH := FDropDownCount * 24
  else
    DropH := 200;
  FScrollWin^.set_size_request(-1, DropH);

  { GtkPopover attached to the box }
  FPopover := gtk4_popover_new;
  gtk4_popover_set_child(FPopover, FScrollWin);
  gtk4_popover_set_has_arrow(FPopover, False);
  gtk4_popover_set_position(FPopover, GTK_POS_BOTTOM);
  FPopover^.set_parent(ABox);
  FPopover^.set_size_request(Params.Width, -1);

  { Items wrapper: reuse TGtkStringListStrings }
  ItemList := TGtkStringListStrings.Create(StringList, LCLObject);
  g_object_set_data(PGObject(Result), GtkListItemLCLListTag, ItemList);
end;

function TGtk4ComboBox.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_UP, VK_DOWN];
end;

function TGtk4ComboBox.getText: String;
begin
  Result := '';
  if FEntry <> nil then
    Result := StrPas(gtk4_editable_get_text(FEntry));
end;

procedure TGtk4ComboBox.setText(const AValue: String);
begin
  if FEntry <> nil then
  begin
    ApplyPendingSelStart; { keep the "SelStart := a; Text := s" order }
    BeginEntryWrite;
    try
      gtk4_editable_set_text(FEntry, PChar(AValue));
    finally
      EndEntryWrite;
    end;
  end;
end;

procedure TGtk4ComboBox.BeginEntryWrite;
begin
  FImDeferredText := '';
  FImFlushing := True;
end;

procedure TGtk4ComboBox.EndEntryWrite;
begin
  FImFlushing := False;
end;

procedure TGtk4ComboBox.CommitSelection(APosition: Integer);
var
  AText: PChar;
  Old: Integer;
  Msg: TLMessage;
  WasVisible: Boolean;
begin
  if (FSelectionModel = nil) or (FListModel = nil) then Exit;
  if (APosition < 0) or
     (APosition >= Integer(g_list_model_get_n_items(PGListModel(FListModel)))) then Exit;
  WasVisible := PopoverVisible;
  if WasVisible then
    Old := FCommittedIndex
  else
    Old := GetItemIndex;
  { the model: a no-op when hover / arrow keys already previewed this row }
  BeginUpdate;
  try
    gtk4_single_selection_set_selected(PGtkSingleSelection(FSelectionModel), guint(APosition));
  finally
    EndUpdate;
  end;
  FCommittedIndex := APosition;
  AText := gtk4_string_list_get_string(PGtkStringList(FListModel), guint(APosition));
  if (FEntry <> nil) and (AText <> nil) then
  begin
    ApplyPendingSelStart;
    BeginUpdate;
    BeginEntryWrite;
    try
      gtk4_editable_set_text(FEntry, AText);
    finally
      EndEntryWrite;
      EndUpdate;
    end;
  end;
  if WasVisible then
  begin
    FActivated := True; { tells the notify::visible handler not to restore }
    gtk4_popover_popdown(FPopover);
    { CBN_CLOSEUP was delivered synchronously: the LCL may have destroyed us }
    if not CanSendLCLMessage then Exit;
  end;
  { like the GTK2 'changed' callback: LM_CHANGED, then LM_SELCHANGE (OnSelect)
    when the index actually changed }
  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_CHANGED;
  DeliverMessage(Msg);
  if not CanSendLCLMessage then Exit;
  if Old <> APosition then
    LCLSendSelectionChangedMsg(LCLObject);
end;

{ ---- combo entry: IM commit-order deferral ---------------------------------
  Mirror of the TGtk4Entry mechanism (see "IM commit-order repair" above and
  Gtk4EntryFlushDeferred): with fcitx5-frontend-gtk4 a key outside the
  composition (space, punctuation) can be inserted BEFORE the pending preedit
  commit, so "한글이 " becomes "한글 이". When the inserted text is exactly the
  pending physical key's own character while a preedit is active, that insert
  is held and re-inserted right after the commit. Invariants kept from the
  entry version: exact raw-key match, the queue is cleared before the flush
  inserts, the AFTER handler's position is used. Unlike TGtk4Entry this
  delivers no OnKeyPress/CN_CHAR and applies no NumbersOnly/CharCase: the
  combo's LCL key route is unchanged. }

procedure Gtk4ComboFlushDeferred(ACombo: TGtk4ComboBox; editable: PGtkEditable;
  position: Pgint);
var
  S: string;
  APos: gint;
begin
  S := ACombo.FImDeferredText;
  if S = '' then exit;
  ACombo.FImDeferredText := '';
  ACombo.ApplyPendingSelStart; { a caret move requested by the LCL comes first }
  ACombo.FImFlushing := True;
  try
    if position <> nil then
      { inside the commit's insert-text AFTER handler: position^ is the
        post-insert offset, so the deferred text lands right after the commit }
      editable^.insert_text(PgChar(S), Length(S), position)
    else
    begin
      { fallback (preedit cleared / focus leave): insert at the caret }
      APos := gtk_editable_get_position(editable);
      editable^.insert_text(PgChar(S), Length(S), @APos);
      gtk_editable_set_position(editable, APos);
    end;
  finally
    ACombo.FImFlushing := False;
  end;
end;

function Gtk4ComboDelegateKeyPressCB({%H-}controller: PGtkEventController;
  keyval: guint; {%H-}keycode: guint; state: TGdkModifierType;
  user_data: gpointer): gboolean; cdecl;
var
  ACombo: TGtk4ComboBox;
  UChar: guint32;
begin
  Result := False; { record only - never consume, never disturb the IM }
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  ACombo := TGtk4ComboBox(user_data);
  ACombo.FImKeyPending := state * [GDK_CONTROL_MASK, GDK_MOD1_MASK] = [];
  ACombo.FImPendingKeyText := '';
  if ACombo.FImKeyPending then
  begin
    UChar := gdk_keyval_to_unicode(keyval);
    if (UChar >= 32) and (UChar <> 127) and (UChar < $110000) then
      ACombo.FImPendingKeyText := UnicodeToUTF8(UChar);
  end;
end;

procedure Gtk4ComboDelegateKeyReleaseCB({%H-}controller: PGtkEventController;
  {%H-}keyval: guint; {%H-}keycode: guint; {%H-}state: TGdkModifierType;
  user_data: gpointer); cdecl;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  TGtk4ComboBox(user_data).FImKeyPending := False;
  TGtk4ComboBox(user_data).FImPendingKeyText := '';
end;

procedure Gtk4ComboDelegatePreeditCB(w: PGtkWidget; preedit: Pgchar;
  user_data: gpointer); cdecl;
var
  ACombo: TGtk4ComboBox;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  ACombo := TGtk4ComboBox(user_data);
  if preedit = nil then
    ACombo.FImPreeditText := ''
  else
    ACombo.FImPreeditText := string(preedit);
  { composition ended without a commit-triggered flush - release anything held }
  if (ACombo.FImPreeditText = '') and (ACombo.FImDeferredText <> '') then
    Gtk4ComboFlushDeferred(ACombo, PGtkEditable(w), nil);
end;

procedure Gtk4ComboDelegateInsertTextCB(editable: PGtkEditable; new_text: Pgchar;
  new_len: gint; {%H-}position: Pgint; user_data: gpointer); cdecl;
var
  ACombo: TGtk4ComboBox;
  InStr: string;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  ACombo := TGtk4ComboBox(user_data);
  if ACombo.FImFlushing then exit; { our own flush / a programmatic write }
  if (new_text = nil) or (new_len <= 0) then exit;
  if Assigned(ACombo.LCLObject) and (csDesigning in ACombo.LCLObject.ComponentState) then exit;
  { key-origin gate: paste/programmatic inserts fire no key events }
  if not ACombo.FImKeyPending then exit;
  SetString(InStr, new_text, new_len);
  if (ACombo.FImPreeditText <> '') and (InStr = ACombo.FImPendingKeyText)
     and (InStr <> ACombo.FImPreeditText) then
  begin
    ACombo.FImDeferredText := ACombo.FImDeferredText + InStr;
    g_signal_stop_emission_by_name(PGObject(editable), 'insert-text');
  end;
end;

procedure Gtk4ComboDelegateInsertAfterCB(editable: PGtkEditable;
  {%H-}new_text: Pgchar; {%H-}new_len: gint; position: Pgint;
  user_data: gpointer); cdecl;
begin
  { AFTER handler: runs once the default insert completed (never for stopped
    emissions). An accepted insert during composition is the IM commit - flush
    the deferred raw key right after it, at the updated position. }
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  if TGtk4ComboBox(user_data).FImFlushing then exit;
  if TGtk4ComboBox(user_data).FImDeferredText = '' then exit;
  Gtk4ComboFlushDeferred(TGtk4ComboBox(user_data), editable, position);
end;

procedure Gtk4ComboDelegateFocusLeaveCB(controller: PGtkEventController;
  user_data: gpointer); cdecl;
var
  W: PGtkWidget;
begin
  if not Gtk4IsLiveWidgetPointer(user_data) then exit;
  if TGtk4ComboBox(user_data).FImDeferredText = '' then exit;
  W := gtk_event_controller_get_widget(controller);
  if W <> nil then
    Gtk4ComboFlushDeferred(TGtk4ComboBox(user_data), PGtkEditable(W), nil);
end;

{ ---- entry selection: deferred SelStart transaction (see TGtk4Editable) ---- }

function TGtk4ComboBox.EntryOk: Boolean;
begin
  Result := IsValidHandle and (FEntry <> nil) and Gtk4IsWidget(FEntry) and
    not FEntry^.in_destruction;
end;

function Gtk4ComboBoxSelStartIdleCB(AData: gpointer): gboolean; cdecl;
begin
  Result := G_SOURCE_REMOVE_;
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  { the source is removed by our return value - do not g_source_remove it again }
  TGtk4ComboBox(AData).FPendingSelStartIdle := 0;
  TGtk4ComboBox(AData).ApplyPendingSelStart;
end;

procedure TGtk4ComboBox.CancelPendingSelStart;
begin
  FSelStartPending := False;
  if FPendingSelStartIdle <> 0 then
  begin
    g_source_remove(FPendingSelStartIdle);
    FPendingSelStartIdle := 0;
  end;
end;

procedure TGtk4ComboBox.ApplyPendingSelStart;
var
  APos: Integer;
begin
  if not FSelStartPending then
    Exit;
  APos := FPendingSelStart;
  { clear our state before the native call: set_position may re-enter the LCL }
  CancelPendingSelStart;
  if EntryOk then
    PGtkEditable(FEntry)^.set_position(APos);
end;

function TGtk4ComboBox.DeliverMessage(var Msg; const AIsInputEvent: Boolean
  ): LRESULT;
begin
  Result := inherited DeliverMessage(Msg, AIsInputEvent);
  { a SelStart set by the LCL handler must be in place before GTK continues
    with the native action. The handler may have destroyed this wrapper. }
  if Gtk4IsLiveWidgetPointer(Self) then
    ApplyPendingSelStart;
end;

function TGtk4ComboBox.GetEntrySelStart: Integer;
var
  AStart, AEnd: gint;
begin
  Result := 0;
  if not EntryOk then
    Exit;
  if FSelStartPending then
    Result := FPendingSelStart
  else
  if PGtkEditable(FEntry)^.get_selection_bounds(@AStart, @AEnd) then
    Result := AStart
  else
    Result := PGtkEditable(FEntry)^.get_position;
end;

function TGtk4ComboBox.GetEntrySelLength: Integer;
var
  AStart, AEnd: gint;
begin
  Result := 0;
  if not EntryOk then
    Exit;
  if FSelStartPending then
    Exit; { a pending SelStart collapses the selection when applied }
  if PGtkEditable(FEntry)^.get_selection_bounds(@AStart, @AEnd) then
    Result := AEnd - AStart;
end;

procedure TGtk4ComboBox.SetEntrySelStart(AValue: Integer);
var
  ALen: Integer;
begin
  if not EntryOk then
    Exit;
  { clamp like GTK does on apply (characters, negative = end of text) }
  ALen := g_utf8_strlen(gtk4_editable_get_text(FEntry), -1);
  if AValue < 0 then
    FPendingSelStart := ALen
  else
    FPendingSelStart := Min(AValue, ALen);
  FSelStartPending := True;
  if FPendingSelStartIdle = 0 then
    FPendingSelStartIdle := g_idle_add_full(G_PRIORITY_HIGH,
      @Gtk4ComboBoxSelStartIdleCB, Self, nil);
end;

procedure TGtk4ComboBox.SetEntrySelLength(AValue: Integer);
var
  AStart, AEnd: gint;
begin
  if not EntryOk then
    Exit;
  if FSelStartPending then
  begin
    { the SelStart/SelLength transaction: one select_region, no collapse }
    AStart := FPendingSelStart;
    CancelPendingSelStart;
  end else
  if not PGtkEditable(FEntry)^.get_selection_bounds(@AStart, @AEnd) then
    AStart := PGtkEditable(FEntry)^.get_position;
  { else AStart = start of the existing selection (GTK2/Win32 semantics) }
  PGtkEditable(FEntry)^.select_region(AStart, AStart + AValue);
end;

function TGtk4ComboBox.CanFocus: Boolean;
begin
  Result := False;
  if IsWidgetOK and (FEntry <> nil) then
    Result := FEntry^.can_focus;
end;

procedure TGtk4ComboBox.SetFocus;
begin
  if Assigned(LCLObject) and IsWidgetOK and (FEntry <> nil) then
  begin
    { Keep the LCL-intent marker in sync with TGtk4Widget.SetFocus —
      the focus-widget notify must classify this as an intended move. }
    Gtk4LCLFocusIntent := True;
    try
      FEntry^.grab_focus;
    finally
      Gtk4LCLFocusIntent := False;
    end;
  end
  else
    inherited SetFocus;
end;

procedure TGtk4ComboBox.SetDropDownCount(AValue: Integer);
var
  DropH: Integer;
begin
  FDropDownCount := AValue;
  if IsWidgetOK and (FScrollWin <> nil) then
  begin
    if AValue > 0 then
      DropH := AValue * 24
    else
      DropH := 200;
    FScrollWin^.set_size_request(-1, DropH);
  end;
end;

procedure TGtk4ComboBox.DetachEvents;
var
  ADelegate: PGtkEditable;
begin
  CancelPendingSelStart;
  FImDeferredText := '';
  { Disconnect signals connected to child GObjects (not FWidget).
    DestroyWidget only disconnects FWidget signals. The IM hooks live on the
    entry's GtkText delegate; its key/focus controllers are widget-owned (GTK
    destroys them with the GtkText) and every callback is live-guarded. }
  if (FEntry <> nil) and Gtk4IsWidget(FEntry) then
  begin
    ADelegate := gtk_editable_get_delegate(PGtkEditable(FEntry));
    if ADelegate <> nil then
      g_signal_handlers_disconnect_matched(PGObject(ADelegate),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  if FEntry <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FEntry),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  if FButton <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FButton),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  if FListView <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FListView),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  if FSelectionModel <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FSelectionModel),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  if FPopover <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FPopover),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  inherited DetachEvents;
end;

procedure TGtk4ComboBox.InitializeWidget;
var
  ADelegate: PGtkEditable;
  AKeyRec, AFocusRec: PGtkEventController;
begin
  inherited InitializeWidget;

  { Entry changed → LM_CHANGED }
  g_signal_connect_data(PGObject(FEntry), 'changed',
    TGCallback(@Gtk4ECB_EntryChanged), Self, nil, G_CONNECT_DEFAULT);

  { IM commit-order deferral on the entry's GtkText delegate (see
    Gtk4ComboFlushDeferred); record-only capture key controller + preedit +
    insert-text before/after + focus leave, as TGtk4Entry does. }
  ADelegate := gtk_editable_get_delegate(PGtkEditable(FEntry));
  if ADelegate <> nil then
  begin
    g_signal_connect_data(PGObject(ADelegate), 'insert-text',
      TGCallback(@Gtk4ComboDelegateInsertTextCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(ADelegate), 'insert-text',
      TGCallback(@Gtk4ComboDelegateInsertAfterCB), Self, nil, [G_CONNECT_AFTER]);
    g_signal_connect_data(PGObject(ADelegate), 'preedit-changed',
      TGCallback(@Gtk4ComboDelegatePreeditCB), Self, nil, G_CONNECT_DEFAULT);
    AKeyRec := gtk4_event_controller_key_new;
    gtk_event_controller_set_propagation_phase(AKeyRec, GTK_PHASE_CAPTURE);
    g_signal_connect_data(AKeyRec, 'key-pressed',
      TGCallback(@Gtk4ComboDelegateKeyPressCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(AKeyRec, 'key-released',
      TGCallback(@Gtk4ComboDelegateKeyReleaseCB), Self, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(PGtkWidget(ADelegate), AKeyRec);
    AFocusRec := gtk4_event_controller_focus_new;
    g_signal_connect_data(AFocusRec, 'leave',
      TGCallback(@Gtk4ComboDelegateFocusLeaveCB), Self, nil, G_CONNECT_DEFAULT);
    gtk4_widget_add_controller(PGtkWidget(ADelegate), AFocusRec);
  end;

  { Button clicked → toggle popover }
  g_signal_connect_data(PGObject(FButton), 'clicked',
    TGCallback(@Gtk4ECB_ButtonClicked), Self, nil, G_CONNECT_DEFAULT);

  { Selection changed → update entry, close popover }
  g_signal_connect_data(PGObject(FSelectionModel), 'selection-changed',
    TGCallback(@Gtk4ECB_SelectionChanged), Self, nil, G_CONNECT_DEFAULT);

  { Row activated (click / Return) → commit the dropdown transaction }
  g_signal_connect_data(PGObject(FListView), 'activate',
    TGCallback(@Gtk4ECB_ListActivate), Self, nil, G_CONNECT_DEFAULT);

  { Popover visibility → dropdown/closeup events }
  g_signal_connect_data(PGObject(FPopover), 'notify::visible',
    TGCallback(@Gtk4ECB_PopoverNotifyVisible), Self, nil, G_CONNECT_DEFAULT);
end;

procedure TGtk4ComboBox.DestroyWidget;
begin
  { Ensure popup-related pointers are cleared before base destroy path runs.
    LCL may still query DroppedDown during teardown. }
  FPopover := nil;
  FEntry := nil;
  FButton := nil;
  FListView := nil;
  FScrollWin := nil;
  FSelectionModel := nil;
  FListModel := nil;
  inherited DestroyWidget;
end;

function TGtk4ComboBox.GetDroppedDown: boolean;
begin
  Result := False;
  if not IsWidgetOK then Exit;
  if (FPopover <> nil) and Gtk4IsWidget(FPopover) and (not FPopover^.in_destruction) then
    Result := FPopover^.get_visible;
end;

{ ---- TGtk4DropDown ---- }

procedure Gtk4DropDownSelectedChanged({%H-}AObject: PGObject;
  {%H-}pspec: PGParamSpec; AData: GPointer); cdecl;
var
  Msg: TLMessage;
begin
  if (AData <> nil) and Gtk4IsLiveWidgetPointer(AData) then
  begin
    if TGtk4Widget(AData).InUpdate then
      Exit;
    FillChar(Msg{%H-}, SizeOf(Msg), #0);
    Msg.Msg := LM_CHANGED;
    TGtk4Widget(AData).DeliverMessage(Msg);
  end;
end;

{ ---- TGtk4DropDown OwnerDraw factory callbacks ---- }

procedure Gtk4DropDownItemDrawFunc({%H-}drawing_area: PGtkDrawingArea;
  cr: Pcairo_t; width: gint; height: gint; user_data: gpointer); cdecl;
var
  Msg: TLMDrawListItem;
  ItemIndex: Integer;
  State: TOwnerDrawState;
  IsSelected: Boolean;
begin
  if user_data = nil then Exit;
  ItemIndex := Integer({%H-}PtrUInt(g_object_get_data(
    PGObject(drawing_area), 'lcl-item-position')));
  IsSelected := Boolean({%H-}PtrUInt(g_object_get_data(
    PGObject(drawing_area), 'lcl-item-selected')));

  State := [odBackgroundPainted];
  if IsSelected then
    Include(State, odSelected);

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := LM_DrawListItem;
  New(Msg.DrawListItemStruct);
  try
    FillChar(Msg.DrawListItemStruct^, SizeOf(TDrawListItemStruct), 0);
    Msg.DrawListItemStruct^.ItemID := UINT(ItemIndex);
    Msg.DrawListItemStruct^.Area := Rect(0, 0, width, height);
    Msg.DrawListItemStruct^.DC := GTK4WidgetSet.CreateDCForWidget(
      PGtkWidget(drawing_area), nil, cr);
    Msg.DrawListItemStruct^.ItemState := State;
    TGtk4Widget(user_data).DeliverMessage(TLMessage(Msg));
    GTK4WidgetSet.ReleaseDC(0, Msg.DrawListItemStruct^.DC);
  finally
    Dispose(Msg.DrawListItemStruct);
  end;
end;

procedure Gtk4DropDownFactorySetup({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  DrawArea: PGtkDrawingArea;
  ACombo: TCustomComboBox;
  ItemH: Integer;
begin
  if user_data = nil then Exit;
  ACombo := TCustomComboBox(TGtk4Widget(user_data).LCLObject);
  DrawArea := PGtkDrawingArea(gtk_drawing_area_new);
  ItemH := TCustomComboBoxAccess(ACombo).ItemHeight;
  if ItemH <= 0 then
    ItemH := 20; { fallback default }
  gtk4_drawing_area_set_content_height(DrawArea, ItemH);
  gtk4_drawing_area_set_draw_func(DrawArea,
    @Gtk4DropDownItemDrawFunc, user_data, nil);
  gtk4_list_item_set_child(listitem, PGtkWidget(DrawArea));
end;

procedure Gtk4DropDownFactoryBind({%H-}factory: PGtkSignalListItemFactory;
  listitem: PGtkListItem; user_data: gpointer); cdecl;
var
  DrawArea: PGtkDrawingArea;
  Position: guint;
  ACombo: TCustomComboBox;
  MeasureMsg: TLMMeasureItem;
  MeasureStruct: TMeasureItemStruct;
  ItemH: Integer;
begin
  if user_data = nil then Exit;
  Position := gtk4_list_item_get_position(listitem);
  DrawArea := PGtkDrawingArea(gtk4_list_item_get_child(listitem));
  if DrawArea = nil then Exit;

  { Store position and selected state for the draw callback }
  g_object_set_data(PGObject(DrawArea), 'lcl-item-position',
    {%H-}gpointer(PtrUInt(Position)));
  g_object_set_data(PGObject(DrawArea), 'lcl-item-selected',
    {%H-}gpointer(PtrUInt(Ord(gtk4_list_item_get_selected(listitem)))));

  ACombo := TCustomComboBox(TGtk4Widget(user_data).LCLObject);

  { csOwnerDrawVariable: query height via LM_MeasureItem }
  if ACombo.Style.IsVariable then
  begin
    FillChar(MeasureMsg{%H-}, SizeOf(MeasureMsg), 0);
    MeasureMsg.Msg := LM_MeasureItem;
    FillChar(MeasureStruct{%H-}, SizeOf(MeasureStruct), 0);
    MeasureStruct.itemID := Position;
    ItemH := TCustomComboBoxAccess(ACombo).ItemHeight;
    if ItemH <= 0 then
      ItemH := 20;
    MeasureStruct.itemHeight := UINT(ItemH);
    MeasureMsg.MeasureItemStruct := @MeasureStruct;
    TGtk4Widget(user_data).DeliverMessage(TLMessage(MeasureMsg));
    gtk4_drawing_area_set_content_height(DrawArea, Integer(MeasureStruct.itemHeight));
  end;

  { Trigger redraw }
  PGtkWidget(DrawArea)^.queue_draw;
end;

function TGtk4DropDown.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  StringList: PGtkStringList;
  ItemList: TGtkStringListStrings;
  ACombo: TCustomComboBox;
begin
  FWidgetType := FWidgetType + [wtComboBox];
  StringList := gtk4_string_list_new(nil);
  Result := gtk4_drop_down_new(PGListModel(StringList), nil);

  ACombo := TCustomComboBox(LCLObject);
  if ACombo.Style.IsOwnerDrawn then
  begin
    { OwnerDraw: use GtkSignalListItemFactory for custom rendering }
    FFactory := PGtkSignalListItemFactory(gtk4_signal_list_item_factory_new);
    g_signal_connect_data(PGObject(FFactory), 'setup',
      TGCallback(@Gtk4DropDownFactorySetup), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(FFactory), 'bind',
      TGCallback(@Gtk4DropDownFactoryBind), Self, nil, G_CONNECT_DEFAULT);
    gtk4_drop_down_set_factory(PGtkDropDown(Result), PGtkListItemFactory(FFactory));
  end;

  ItemList := TGtkStringListStrings.Create(StringList, LCLObject);
  g_object_set_data(PGObject(Result), GtkListItemLCLListTag, ItemList);
  { GtkDropDown takes ownership of the model ref from gtk4_drop_down_new,
    but we passed a floating ref from gtk4_string_list_new, so no unref needed. }
end;

procedure TGtk4DropDown.DetachEvents;
begin
  { Disconnect signals on FFactory (not FWidget) }
  if FFactory <> nil then
    g_signal_handlers_disconnect_matched(PGObject(FFactory),
      [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  inherited DetachEvents;
end;

procedure TGtk4DropDown.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(FWidget, 'notify::selected',
    TGCallback(@Gtk4DropDownSelectedChanged), Self, nil, G_CONNECT_DEFAULT);
end;

function TGtk4DropDown.GetItemIndex: Integer;
var
  Sel: guint;
begin
  Result := -1;
  if IsWidgetOK then
  begin
    Sel := gtk4_drop_down_get_selected(PGtkDropDown(FWidget));
    if Sel <> GTK_INVALID_LIST_POSITION then
      Result := Integer(Sel);
  end;
end;

procedure TGtk4DropDown.SetItemIndex(AValue: Integer);
begin
  if IsWidgetOK then
  begin
    if AValue < 0 then
      gtk4_drop_down_set_selected(PGtkDropDown(FWidget), GTK_INVALID_LIST_POSITION)
    else
      gtk4_drop_down_set_selected(PGtkDropDown(FWidget), guint(AValue));
  end;
end;

function TGtk4DropDown.getText: String;
var
  Idx: Integer;
  Model: PGListModel;
begin
  Result := '';
  if not IsWidgetOK then Exit;
  Idx := GetItemIndex;
  if Idx < 0 then Exit;
  Model := gtk4_drop_down_get_model(PGtkDropDown(FWidget));
  if Model <> nil then
    Result := StrPas(gtk4_string_list_get_string(PGtkStringList(Model), guint(Idx)));
end;

procedure TGtk4DropDown.setText(const AValue: String);
var
  Model: PGListModel;
  i: Integer;
  Cnt: guint;
  S: Pgchar;
begin
  if not IsWidgetOK then Exit;
  Model := gtk4_drop_down_get_model(PGtkDropDown(FWidget));
  if Model = nil then Exit;
  Cnt := g_list_model_get_n_items(Model);
  for i := 0 to Integer(Cnt) - 1 do
  begin
    S := gtk4_string_list_get_string(PGtkStringList(Model), guint(i));
    if (S <> nil) and (StrPas(S) = AValue) then
    begin
      SetItemIndex(i);
      Exit;
    end;
  end;
  { String not found — deselect }
  SetItemIndex(-1);
end;

function TGtk4DropDown.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := AKey in [VK_UP, VK_DOWN];
end;

function TGtk4DropDown.CanFocus: Boolean;
begin
  Result := IsWidgetOK and FWidget^.can_focus;
end;

procedure TGtk4DropDown.SetFocus;
begin
  if IsWidgetOK then
  begin
    { Keep the LCL-intent marker in sync with TGtk4Widget.SetFocus. }
    Gtk4LCLFocusIntent := True;
    try
      FWidget^.grab_focus;
    finally
      Gtk4LCLFocusIntent := False;
    end;
  end
  else
    inherited SetFocus;
end;

function TGtk4DropDown.GetInternalToggleButton: PGtkWidget;
begin
  { GtkDropDown is a final type (cannot be subclassed), but it opens/closes its
    popover purely from its internal GtkToggleButton's active state
    (gtkdropdown.c: button_toggled -> gtk_popover_popup/popdown). The button is
    the first child of the dropdown node (gtkdropdown.ui: first <child> is the
    "button" GtkToggleButton, second is the popover). Return it so DroppedDown
    can drive it; return nil (caller no-ops) if the structure ever differs. }
  Result := nil;
  if not IsWidgetOK then
    exit;
  Result := gtk4_widget_get_first_child(Widget);
  if (Result <> nil) and (Get3WidgetClassName(Result) <> 'GtkToggleButton') then
    Result := nil;
end;

procedure TGtk4DropDown.SetDroppedDown(AValue: boolean);
var
  ABtn: PGtkWidget;
begin
  ABtn := GetInternalToggleButton;
  if ABtn = nil then
    Exit;
  { Pass compile-time gboolean literals, matching the rest of the widgetset. }
  if AValue then
    gtk_toggle_button_set_active(PGtkToggleButton(ABtn), True)
  else
    gtk_toggle_button_set_active(PGtkToggleButton(ABtn), False);
end;

function TGtk4DropDown.GetDroppedDown: boolean;
var
  ABtn: PGtkWidget;
begin
  Result := False;
  ABtn := GetInternalToggleButton;
  if ABtn <> nil then
    Result := gtk_toggle_button_get_active(PGtkToggleButton(ABtn)) <> False;
end;

{ TGtk4Button }

function TGtk4Button.getLayout: Integer;
begin
  Result := FLayout;
end;

function TGtk4Button.getMargin: Integer;
begin
  Result := FMargin;
end;

procedure TGtk4Button.SetLayout(AValue: Integer);
begin
  FLayout := AValue;
  if IsWidgetOk then
  begin
    { GTK4: set_image_position removed. Layout via margin/spacing. }
    SetMargin(FMargin);
    SetSpacing(FSpacing);
  end;
end;

procedure TGtk4Button.SetMargin(AValue: Integer);
var
  AChild: PGtkWidget;
begin
  FMargin := AValue;
  if not IsWidgetOk then Exit;
  { GTK4: GtkButton.set_alignment removed. Use halign/valign on child. }
  AChild := gtk4_button_get_child(PGtkButton(FWidget));
  if AChild = nil then Exit;
  if AValue < 0 then
  begin
    { Margin = -1 → center content (default) }
    AChild^.set_halign(GTK_ALIGN_CENTER);
    AChild^.set_valign(GTK_ALIGN_CENTER);
    AChild^.set_margin_start(0);
    AChild^.set_margin_end(0);
    AChild^.set_margin_top(0);
    AChild^.set_margin_bottom(0);
  end else
  begin
    { Push content toward the layout edge by AValue pixels }
    case TGtkPositionType(FLayout) of
      GTK_POS_LEFT:
      begin
        AChild^.set_halign(GTK_ALIGN_START);
        AChild^.set_valign(GTK_ALIGN_CENTER);
        AChild^.set_margin_start(AValue);
        AChild^.set_margin_end(0);
        AChild^.set_margin_top(0);
        AChild^.set_margin_bottom(0);
      end;
      GTK_POS_RIGHT:
      begin
        AChild^.set_halign(GTK_ALIGN_END);
        AChild^.set_valign(GTK_ALIGN_CENTER);
        AChild^.set_margin_start(0);
        AChild^.set_margin_end(AValue);
        AChild^.set_margin_top(0);
        AChild^.set_margin_bottom(0);
      end;
      GTK_POS_TOP:
      begin
        AChild^.set_halign(GTK_ALIGN_CENTER);
        AChild^.set_valign(GTK_ALIGN_START);
        AChild^.set_margin_start(0);
        AChild^.set_margin_end(0);
        AChild^.set_margin_top(AValue);
        AChild^.set_margin_bottom(0);
      end;
      GTK_POS_BOTTOM:
      begin
        AChild^.set_halign(GTK_ALIGN_CENTER);
        AChild^.set_valign(GTK_ALIGN_END);
        AChild^.set_margin_start(0);
        AChild^.set_margin_end(0);
        AChild^.set_margin_top(0);
        AChild^.set_margin_bottom(AValue);
      end;
    end;
  end;
end;

procedure TGtk4Button.SetSpacing(AValue: Integer);
var
  AChild: PGtkWidget;
  AImage: PGtkWidget;
begin
  FSpacing := AValue;
  if AValue < 0 then
    FSpacing := 2;
  if not IsWidgetOk then Exit;
  { GTK4: image-spacing style property removed. Set margin on the image
    widget inside the button's child box, layout-aware. }
  AChild := gtk4_button_get_child(PGtkButton(FWidget));
  if AChild = nil then Exit;
  { The child is a GtkBox when both image and label are present.
    Find the first child (image) via GTK4 widget iteration. }
  if not g_type_check_instance_is_a(PGTypeInstance(AChild), gtk_box_get_type()) then
    Exit;
  AImage := gtk4_widget_get_first_child(AChild);
  if AImage = nil then Exit;
  if AValue < 0 then
    AValue := 0;
  { Clear all spacing margins first }
  AImage^.set_margin_start(0);
  AImage^.set_margin_end(0);
  AImage^.set_margin_top(0);
  AImage^.set_margin_bottom(0);
  { Apply spacing to the edge facing the label, based on layout }
  case TGtkPositionType(FLayout) of
    GTK_POS_LEFT:   AImage^.set_margin_end(AValue);
    GTK_POS_RIGHT:  AImage^.set_margin_start(AValue);
    GTK_POS_TOP:    AImage^.set_margin_bottom(AValue);
    GTK_POS_BOTTOM: AImage^.set_margin_top(AValue);
  end;
end;

procedure TGtk4Button.ButtonClicked(pData: pointer); cdecl;
begin
  if TObject(pdata) is TCustomButton then
  begin
    { In design mode the designer must handle clicks, not the button itself.
      GTK4 'clicked' signal bypasses the LCL message queue so the designer's
      IsDesignMsg filter never sees it — skip Click entirely. }
    if csDesigning in TCustomButton(pdata).ComponentState then
      Exit;
    TCustomButton(pdata).Click;
  end;
end;

procedure TGtk4Button.SetImage(AImage: TBitmap);
begin
  if Assigned(fImage) then
    fImage.free;
  fImage:=AImage;
end;

function TGtk4Button.getText: String;
var
  AChild, AItem: PGtkWidget;
  p: PgChar;
begin
  Result := '';
  if not IsWidgetOK then Exit;
  { When a glyph is shown the button child is a GtkBox (image+label), not the
    button's internal label, so gtk_button_get_label() returns empty. Read the
    caption from the box's label instead — symmetric with setText. Without this,
    TWinControl.RealGetText reads '' back into TControl.Caption once the handle
    exists, and the next RebuildButtonChild (from SetLayout/Margin/Spacing)
    rebuilds the box with an empty label, wiping the visible text. }
  AChild := gtk4_button_get_child(PGtkButton(FWidget));
  if (AChild <> nil) and g_type_check_instance_is_a(
      PGTypeInstance(AChild), gtk_box_get_type()) then
  begin
    AItem := gtk4_widget_get_first_child(AChild);
    while AItem <> nil do
    begin
      if g_type_check_instance_is_a(
          PGTypeInstance(AItem), gtk_label_get_type()) then
      begin
        p := PGtkLabel(AItem)^.get_label();
        if p <> nil then
          Result := ReplaceUnderscoresWithAmpersands(p);
        Exit;
      end;
      AItem := gtk4_widget_get_next_sibling(AItem);
    end;
  end;
  p := PGtkButton(FWidget)^.get_label();
  if p <> nil then
    Result := ReplaceUnderscoresWithAmpersands(p);
end;

procedure TGtk4Button.setText(const AValue: String);
var
  AChild, AItem: PGtkWidget;
  AText: PgChar;
begin
  if not IsWidgetOk then Exit;
  AText := PgChar(ReplaceAmpersandsWithUnderscores(AValue));
  AChild := gtk4_button_get_child(PGtkButton(FWidget));
  { If child is a GtkBox (image+label layout), find and update the label }
  if (AChild <> nil) and g_type_check_instance_is_a(
      PGTypeInstance(AChild), gtk_box_get_type()) then
  begin
    AItem := gtk4_widget_get_first_child(AChild);
    while AItem <> nil do
    begin
      if g_type_check_instance_is_a(
          PGTypeInstance(AItem), gtk_label_get_type()) then
      begin
        PGtkLabel(AItem)^.set_label(AText);
        Exit;
      end;
      AItem := gtk4_widget_get_next_sibling(AItem);
    end;
  end;
  { Fallback: standard label }
  PGtkButton(FWidget)^.set_label(AText);
end;

function TGtk4Button.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  btn:PGtkButton absolute Result;
begin
  Result := PGtkWidget(TGtkButton.new);

  btn^.set_use_underline(true);

  g_signal_connect_data(btn,'clicked',
        TGCallback(@TGtk4Button.ButtonClicked), LCLObject, nil, G_CONNECT_DEFAULT);

  LCLObject.ControlStyle:=LCLObject.ControlStyle+[csClickEvents];

  FMargin := -1;
  FLayout := ord(GTK_POS_LEFT);
  FSpacing := 2; // default gtk4 spacing is 2
end;

destructor TGtk4Button.Destroy;
begin
  SetImage(nil);
  inherited Destroy;
end;

function TGtk4Button.IsWidgetOk: Boolean;
begin
  Result := (FWidget <> nil) and Gtk4IsButton(FWidget);
end;

procedure TGtk4Button.SetDefault(const ADefault: Boolean);
begin
  { GTK4 removed can-default; the binding's set_can_default helper
    redirects to set_can_focus, which made the LCL's active-default
    bookkeeping (WSSetDefault passes FActive) turn the Default button
    UNFOCUSABLE whenever another control became the active default —
    tabbing back to the OK button stopped working. receives_default is
    the GTK4 property for default-button semantics and does not touch
    focusability. Return-key activation itself is LCL-driven
    (TCustomForm.DefaultControl), same as gtk2 where the native
    grab_default call is commented out. }
  if IsWidgetOk then
    GetContainerWidget^.set_receives_default(ADefault);
end;

{ TGtk4ToggleButton }
procedure Gtk4Toggled({%H-}AWidget: PGtkToggleButton; AData: gPointer); cdecl;
var
  Msg: TLMessage;
begin
  if not Gtk4IsLiveWidgetPointer(AData) then Exit;
  { Design mode: a click toggles the native GtkCheckButton state; do not
    report it back to the LCL or the design-time Checked/State would be
    corrupted. The designer handles the click for selection. }
  if (TGtk4Widget(AData).LCLObject <> nil) and
     (csDesigning in TGtk4Widget(AData).LCLObject.ComponentState) then
    Exit;
  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := LM_CHANGED;
  if (TGtk4Widget(AData).LCLObject <> nil) and not TGtk4Widget(AData).InUpdate then
    TGtk4Widget(AData).DeliverMessage(Msg, False);
end;

procedure TGtk4ToggleButton.InitializeWidget;
begin
  inherited InitializeWidget;
  g_signal_connect_data(FWidget, 'toggled', TGCallback(@Gtk4Toggled), Self, nil, G_CONNECT_DEFAULT);
end;

function TGtk4ToggleButton.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  btn: PGtkToggleButton;
begin
  btn := TGtkToggleButton.new;
  btn^.use_underline := True;
  Result := PGtkWidget(btn);
end;

{ TGtk4CheckBox }

function TGtk4CheckBox.GetState: TCheckBoxState;
begin
  Result := cbUnchecked;
  if IsWidgetOk then
  begin
    { GTK4: GtkCheckButton has its own API, not inherited from GtkToggleButton. }
    if gtk4_check_button_get_inconsistent(PGtkCheckButton(FWidget)) then
      Result := cbGrayed
    else
    if gtk4_check_button_get_active(PGtkCheckButton(FWidget)) then
      Result := cbChecked;
  end;
end;

procedure TGtk4CheckBox.SetState(AValue: TCheckBoxState);
begin
  if IsWidgetOK then
  begin
    { GTK4: GtkCheckButton has its own API, not inherited from GtkToggleButton. }
    if AValue = cbGrayed then
      gtk4_check_button_set_inconsistent(PGtkCheckButton(FWidget), True)
    else
    begin
      { 'active' and 'inconsistent' are independent GtkCheckButton properties:
        set_active does NOT clear inconsistent. Without clearing it here, a
        cbGrayed -> cbChecked/cbUnchecked change stays reported as cbGrayed
        because GetState checks inconsistent first. }
      gtk4_check_button_set_inconsistent(PGtkCheckButton(FWidget), False);
      gtk4_check_button_set_active(PGtkCheckButton(FWidget), AValue = cbChecked);
    end;
  end;
end;

function TGtk4CheckBox.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  check: PGtkCheckButton;
begin
  check := TGtkCheckButton.new;
  Result := PGtkWidget(check);
  { GTK4: GtkCheckButton is no longer a subclass of GtkButton.
    Use GTK4-specific API instead of inherited GtkButton methods. }
  gtk4_check_button_set_use_underline(check, True);
end;

function TGtk4CheckBox.getText: String;
var
  p: Pgchar;
begin
  if IsWidgetOk then
  begin
    { GTK4: GtkCheckButton is not a GtkButton. Use its own label API. }
    p := gtk4_check_button_get_label(PGtkCheckButton(FWidget));
    if p <> nil then
      Result := ReplaceUnderscoresWithAmpersands(p)
    else
      Result := '';
  end else
    Result := '';
end;

procedure TGtk4CheckBox.setText(const AValue: String);
begin
  { GTK4: GtkCheckButton is not a GtkButton. Use its own label API. }
  if IsWidgetOk then
    gtk4_check_button_set_label(PGtkCheckButton(FWidget),
      PgChar(ReplaceAmpersandsWithUnderscores(AValue)));
end;

function TGtk4CheckBox.IsWidgetOk: Boolean;
begin
  { GTK4: GtkCheckButton is not a GtkButton. Don't use Gtk4IsButton check. }
  Result := (FWidget <> nil) and Gtk4IsWidget(PGObject(FWidget));
end;

{ TGtk4RadioButton }

function TGtk4RadioButton.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  btn: PGtkRadioButton;
  w: PGtkWidget;
  ctl, Parent: TWinControl;
  rb: TRadioButton;
  //pl: PGsList;
  i: Integer;
begin
  { The hidden radio button (TRadioGroup ItemIndex=-1 helper) gets a REAL
    native widget like every other radio: the previous nil-widget special
    case made downstream generic WS calls (SetBiDiMode direction,
    ConstraintsChange size_request) hit a nil GtkWidget — three
    Gtk-CRITICALs at every TRadioGroup creation (runtime-measured). LCL
    creates it with Visible=False, so the real widget is never shown. It
    deliberately does NOT join the native group (see below): LCL drives
    every button's checked state explicitly, and staying ungrouped keeps
    the proven ItemIndex=-1 semantics while avoiding a stale native group
    after TRadioGroup rebuilds its item buttons. }
  Result := nil;
  btn := TGtkRadioButton.new(nil);
  { GTK4: GtkCheckButton (parent of radio) is NOT a GtkButton.
    Must use GtkCheckButton-specific API, not inherited GtkButton property. }
  gtk4_check_button_set_use_underline(PGtkCheckButton(btn), True);
  Result := PGtkWidget(btn);
  ctl := Self.LCLObject;
  if Assigned(ctl) then
  begin
    Parent := ctl.Parent;
    { Native grouping MUST use gtk_check_button_set_group — the legacy
      TGtkRadioButton.join_group binding is an empty stub, so siblings
      were never grouped natively (runtime-confirmed: setting one radio
      active left the other checked both natively and in the LCL). }
    if (Parent is TRadioGroup) then
    begin
      { The HiddenRadioButton stays out of the native group (see the
        comment at the top of this function) — both as a JOINER and as the
        group ANCHOR: after Items.Clear + Items.Add rebuilds the hidden
        button can temporarily be Controls[0], so scan for the first real
        item button instead of blindly anchoring to Controls[0]. }
      if (TRadioGroup(Parent).Items.Count>0) and
         (ctl.Name<>'HiddenRadioButton') then
      begin
        rb := nil;
        for i := 0 to Parent.ControlCount - 1 do
          if (Parent.Controls[i] is TRadioButton) and
             (Parent.Controls[i] <> ctl) and
             (Parent.Controls[i].Name <> 'HiddenRadioButton') and
             TRadioButton(Parent.Controls[i]).HandleAllocated then
          begin
            rb := TRadioButton(Parent.Controls[i]);
            Break;
          end;
        if rb <> nil then
        begin
          w := TGtk4RadioButton(rb.Handle).Widget;
          if w <> nil then
            gtk4_check_button_set_group(PGtkCheckButton(Result), PGtkCheckButton(w));
        end;
      end
    end
    else
    begin
      for i := 0 to Parent.ControlCount - 1 do
        if (Parent.Controls[i] is TRadioButton) and
           TWinControl(Parent.Controls[i]).HandleAllocated then
        begin
          rb := TRadioButton(Parent.Controls[i]);
          w := TGtk4RadioButton(rb.Handle).Widget;
          gtk4_check_button_set_group(PGtkCheckButton(Result), PGtkCheckButton(w));
          Break;
        end;
    end;
  end;
end;


{ TGtk4CustomControl }

function TGtk4CustomControl.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  FScrollX := 0;
  FScrollY := 0;
  FHasPaint := True;
  FWidgetType := [wtWidget, wtContainer, wtTabControl, wtScrollingWin, wtCustomControl];

  // this hack is requred for controls without custom WS classes
  if LCLObject is TUpDown then
    include(FWidgetType, wtSpinEdit);

  Result := PGtkScrolledWindow(gtk4_scrolled_window_new);

  { GTK4: Insert GtkOverlay between ScrolledWindow and GtkFixed for painting.
    Hierarchy: ScrolledWindow → [Viewport(auto)] → GtkOverlay → [GtkFixed (children), GtkDrawingArea (paint)] }
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  FCentralWidget := TGtkFixed.new;
  { Tag GtkFixed as inside a ScrolledWindow so LCLFixedLayoutMeasure reports
    small minimum (matching GTK2's GtkLayout which doesn't inflate min size). }
  g_object_set_data(PGObject(FCentralWidget), 'lcl-scroll-fixed', GPointer(1));
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);
  gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), PGtkWidget(AOverlay));

  { GTK4: POLICY_NEVER — matching GTK2.  SetScrollInfo resets set_size_request
    to -1 when hiding the scrollbar, so the tagged GtkFixed minimum stays 0
    and NEVER does not propagate a large minimum upward.  Overlay disabled. }
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
  PGtkScrolledWindow(Result)^.set_overlay_scrolling(False);
  PGtkScrolledWindow(Result)^.set_kinetic_scrolling(False);
  { GTK4 focus model: can_focus is a TREE-LEVEL flag — setting it to False
    on GtkScrolledWindow blocks ALL descendants from receiving focus via
    get_effective_can_focus(). Leave can_focus=True (default) on ScrolledWindow
    so descendants can be focused.  Use focusable=False (default) to prevent
    the ScrolledWindow itself from accepting focus. }
  { GTK4: Respect csNoFocus — container GtkFixed should not accept focus
    from child widgets (e.g. GtkEntry in OI filter edits). Qt5 does the same. }
  if not (csNoFocus in LCLObject.ControlStyle) then
  begin
    FCentralWidget^.set_can_focus(True);
    gtk4_widget_set_focusable(FCentralWidget, True);
  end
  else
  begin
    FCentralWidget^.set_can_focus(False);
    gtk4_widget_set_focusable(FCentralWidget, False);
  end;
  { GtkFixed layout containers must never grab focus on mouse click —
    that steals focus from child input widgets (GtkEntry, GtkTextView).
    Tab/keyboard focus still works (focusable=True is preserved). }
  FCentralWidget^.set_focus_on_click(False);
end;

function TGtk4CustomControl.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

procedure TGtk4CustomControl.InitializeWidget;
begin
  inherited InitializeWidget;
  SetScrollBarsSignalHandlers;
  { GTK4: 'scroll-event' signal removed. Scroll handling is via
    Gtk4ScrollCB event controller connected in base InitializeWidget. }
end;

procedure TGtk4CustomControl.UpdateWidgetConstraints;
begin
  ;
end;

function TGtk4CustomControl.getClientRect: TRect;
var
  Allocation: TGtkAllocation;
  sb: PGtkWidget;
  sbSize: gint;
begin
  { GTK4: The client rect must be the VIEWPORT size (visible area), not the
    GtkFixed allocation.  GtkFixed may be enlarged via set_size_request to the
    full content size for scrolling.  Using GtkFixed allocation would make the
    LCL think everything fits → scrollbars never appear.
    Use FWidget (GtkScrolledWindow) allocation minus visible scrollbar space. }
  if IsWidgetOK then
  begin
    FWidget^.get_allocation(@Allocation);
    Result := Rect(0, 0, Allocation.width, Allocation.height);
    { Subtract visible scrollbar dimensions }
    sb := PGtkScrolledWindow(FWidget)^.get_vscrollbar;
    if (sb <> nil) and sb^.get_visible then
    begin
      sbSize := gtk_widget_get_allocated_width(sb);
      Dec(Result.Right, sbSize);
    end;
    sb := PGtkScrolledWindow(FWidget)^.get_hscrollbar;
    if (sb <> nil) and sb^.get_visible then
    begin
      sbSize := gtk_widget_get_allocated_height(sb);
      Dec(Result.Bottom, sbSize);
    end;
    if Result.Right < 0 then Result.Right := 0;
    if Result.Bottom < 0 then Result.Bottom := 0;
  end
  else
    Result := Rect(0, 0, 0, 0);
end;

function TGtk4CustomControl.getClientBounds: TRect;
begin
  { Same logic as getClientRect — viewport size, not GtkFixed content size.
    getClientBounds returns rect with position relative to FWidget. For
    GtkScrolledWindow the viewport starts at (0,0) within the widget. }
  Result := getClientRect;
end;

function TGtk4CustomControl.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_hscrollbar);
  if Result <> nil then
    g_object_set_data(Result,'lclwidget',Self);
end;

function TGtk4CustomControl.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  Result := PGtkScrollBar(PGtkScrolledWindow(Widget)^.get_vscrollbar);
  if Result <> nil then
    g_object_set_data(Result,'lclwidget',Self);
end;

function TGtk4CustomControl.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := PGtkScrolledWindow(Widget)
  else
    Result := nil;
end;

procedure TGtk4CustomControl.SetFocus;
var
  sb: PGtkWidget;
  VAdj, HAdj: PGtkAdjustment;
  OldVValue, OldHValue: gdouble;
begin
  { GTK4: grab_focus on a child inside GtkScrolledWindow triggers
    scroll-to-focus, which changes the adjustment value.  For custom controls
    (TreeView etc.) the LCL manages scroll position independently — the
    GTK-initiated scroll causes a spurious WMVScroll that scrolls the control
    on the first focus acquisition.
    Fix: save adjustment values, call grab_focus inside BeginUpdate (suppresses
    Gtk4ScrollAdjChangedCB), then restore original values so the viewport
    position is preserved. }
  VAdj := nil;
  HAdj := nil;
  OldVValue := 0;
  OldHValue := 0;
  if IsWidgetOK then
  begin
    sb := PGtkScrolledWindow(FWidget)^.get_vscrollbar;
    if sb <> nil then
    begin
      VAdj := gtk4_scrollbar_get_adjustment(sb);
      if VAdj <> nil then
        OldVValue := VAdj^.get_value;
    end;
    sb := PGtkScrolledWindow(FWidget)^.get_hscrollbar;
    if sb <> nil then
    begin
      HAdj := gtk4_scrollbar_get_adjustment(sb);
      if HAdj <> nil then
        OldHValue := HAdj^.get_value;
    end;
  end;

  BeginUpdate;
  try
    inherited SetFocus;
    { Restore within BeginUpdate so the value-changed from set_value
      is also suppressed. }
    if VAdj <> nil then
      VAdj^.set_value(OldVValue);
    if HAdj <> nil then
      HAdj^.set_value(OldHValue);
  finally
    EndUpdate;
  end;
end;

{ TGtk4ScrollingWinControl }

function TGtk4ScrollingWinControl.CreateWidget(const Params: TCreateParams
  ): PGtkWidget;
var
  AOverlay: PGtkOverlay;
begin
  FHasPaint := True;
  FScrollX := 0;
  FScrollY := 0;
  FWidgetType := [wtWidget, wtContainer, wtScrollingWin, wtScrollingWinControl];
  Result := PGtkScrolledWindow(gtk4_scrolled_window_new);

  { GTK4: Insert GtkOverlay between ScrolledWindow and GtkFixed for painting.
    Hierarchy: ScrolledWindow → [Viewport(auto)] → GtkOverlay → [GtkFixed (children), GtkDrawingArea (paint)] }
  AOverlay := PGtkOverlay(gtk4_overlay_new);
  FCentralWidget := TGtkFixed.new;
  { Tag GtkFixed as inside a ScrolledWindow so LCLFixedLayoutMeasure reports
    small minimum (matching GTK2's GtkLayout which doesn't inflate min size). }
  g_object_set_data(PGObject(FCentralWidget), 'lcl-scroll-fixed', GPointer(1));
  gtk4_overlay_set_child(AOverlay, FCentralWidget);
  SetupPaintArea(AOverlay);
  gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), PGtkWidget(AOverlay));

  PGtkScrolledWindow(Result)^.get_vscrollbar^.set_can_focus(False);
  PGtkScrolledWindow(Result)^.get_hscrollbar^.set_can_focus(False);
  { GTK4: POLICY_NEVER — matching GTK2.  SetScrollInfo resets set_size_request
    to -1 when hiding, so tagged GtkFixed minimum stays 0 and NEVER does not
    propagate a large minimum upward.  Overlay disabled. }
  PGtkScrolledWindow(Result)^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
  PGtkScrolledWindow(Result)^.set_overlay_scrolling(False);
  PGtkScrolledWindow(Result)^.set_kinetic_scrolling(False);
  { GTK4 focus model: leave can_focus=True (default) on ScrolledWindow so
    descendants can be focused.  See TGtk4CustomControl.CreateWidget comment. }
  if not (csNoFocus in LCLObject.ControlStyle) then
  begin
    FCentralWidget^.set_can_focus(True);
    gtk4_widget_set_focusable(FCentralWidget, True);
  end
  else
  begin
    FCentralWidget^.set_can_focus(False);
    gtk4_widget_set_focusable(FCentralWidget, False);
  end;
  { GtkFixed layout containers must never grab focus on mouse click —
    that steals focus from child input widgets (GtkEntry, GtkTextView).
    Tab/keyboard focus still works (focusable=True is preserved). }
  FCentralWidget^.set_focus_on_click(False);
end;

{ TGtk4Window }

function TGtk4Window.GetTitle: String;
begin
  if Gtk4IsGtkWindow(fWidget) then
    Result:=PGtkWindow(fWidget)^.get_title()
  else
    Result:=''
end;

procedure TGtk4Window.SetIcon(AValue: PGdkPixBuf);
begin
  if Assigned(FIcon) then
  begin
    FIcon^.unref;
    FIcon := nil;
  end;
  if Gtk4IsGdkPixbuf(AValue) then
    FIcon := PGdkPixbuf(AValue)^.copy
  else
    FIcon := nil;
  { GTK4 removed gtk_window_set_icon(GdkPixbuf*) — only themed-icon-name
    lookup (gtk_window_set_icon_name) exists, so the binding call below is a
    documented no-op. FIcon is still cached for LCL-side queries. Follow-up
    (if per-pixbuf window icons are ever needed on X11): export the pixbuf
    via _NET_WM_ICON directly. }
  if Gtk4IsGtkWindow(fWidget) then
    PGtkWindow(Widget)^.set_icon(FIcon);
end;

function TGtk4Window.GetSkipTaskBarHint: Boolean;
begin
  Result := False;
  if Gtk4IsGtkWindow(fWidget) then
    Result := PGtkWindow(Widget)^.get_skip_taskbar_hint;
end;

procedure TGtk4Window.SetSkipTaskBarHint(AValue: Boolean);
begin
  if Gtk4IsGtkWindow(fWidget) then
    PGtkWindow(Widget)^.set_skip_taskbar_hint(AValue);
end;

procedure TGtk4Window.SetTitle(const AValue: String);
begin
  if Gtk4IsGtkWindow(fWidget) then
    PGtkWindow(FWidget)^.set_title(PGChar(AValue))
end;

{ GTK4: 'window-state-event' removed. Window state is tracked via
  'notify::maximized' and 'notify::fullscreened' property change signals.
  This callback handles both signals and sends LM_SIZE to the LCL. }
procedure Gtk4WindowStateNotifyCB({%H-}AObject: PGObject;
  {%H-}pspec: PGParamSpec; AData: gPointer); cdecl;
var
  AWindow: PGtkWindow;
  TheForm: TCustomForm;
  SizeMsg: TLMSize;
  W, H: Integer;
  AWgt: TGtk4Widget;
begin
  AWgt := TGtk4Widget(AData);
  if not AWgt.CanSendLCLMessage then Exit;
  if not (AWgt.LCLObject is TCustomForm) then Exit;
  TheForm := TCustomForm(AWgt.LCLObject);
  AWindow := PGtkWindow(AWgt.Widget);

  { Determine the current window state }
  if gtk4_window_is_fullscreen(AWindow) then
    SizeMsg.SizeType := SIZE_FULLSCREEN + Size_SourceIsInterface
  else if AWindow^.is_maximized then
    SizeMsg.SizeType := SIZE_MAXIMIZED + Size_SourceIsInterface
  else
    SizeMsg.SizeType := SIZE_RESTORED + Size_SourceIsInterface;

  { Avoid redundant messages }
  case SizeMsg.SizeType - Size_SourceIsInterface of
    SIZE_RESTORED:    if TheForm.WindowState = wsNormal then Exit;
    SIZE_MAXIMIZED:   if TheForm.WindowState = wsMaximized then Exit;
    SIZE_FULLSCREEN:  if TheForm.WindowState = wsFullScreen then Exit;
  end;

  W := AWgt.Widget^.get_allocated_width;
  H := AWgt.Widget^.get_allocated_height;
  if W < 0 then W := 0;
  if H < 0 then H := 0;

  SizeMsg.Msg := LM_SIZE;
  SizeMsg.Width := Word(W);
  SizeMsg.Height := Word(H);
  SizeMsg.Result := 0;
  AWgt.DeliverMessage(SizeMsg);

  { Notify application when main form is minimized/restored.
    Note: GTK4 minimize is compositor-controlled and there is no reliable
    'notify::minimized' signal, so we only handle maximize/fullscreen here. }
  if TheForm = Application.MainForm then
  begin
    if (SizeMsg.SizeType - Size_SourceIsInterface) = SIZE_RESTORED then
      Application.IntfAppRestore;
  end;
end;

{ GTK4: When a window's scrollbar is hidden (our AUTOMATIC-policy workaround
  to prevent GtkFixed min-size propagation), the ScrolledWindow adjustment may
  still change when the viewport shrinks below the content, causing unwanted
  auto-scroll to the bottom.  Pin the adjustment to 0 when the scrollbar is
  not visible. }
procedure Gtk4WindowVScrollPinCB(AAdjustment: PGtkAdjustment; AData: gpointer); cdecl;
var
  AWidget: TGtk4Window;
  SW: PGtkScrolledWindow;
  SBar: PGtkWidget;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  AWidget := TGtk4Window(AData);
  if not AWidget.IsWidgetOk then Exit;
  SW := AWidget.GetScrolledWindow;
  if SW = nil then Exit;
  SBar := SW^.get_vscrollbar;
  if (SBar <> nil) and not SBar^.get_visible then
    if gtk_adjustment_get_value(AAdjustment) <> 0 then
      gtk_adjustment_set_value(AAdjustment, 0);
end;

procedure Gtk4WindowHScrollPinCB(AAdjustment: PGtkAdjustment; AData: gpointer); cdecl;
var
  AWidget: TGtk4Window;
  SW: PGtkScrolledWindow;
  SBar: PGtkWidget;
begin
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  AWidget := TGtk4Window(AData);
  if not AWidget.IsWidgetOk then Exit;
  SW := AWidget.GetScrolledWindow;
  if SW = nil then Exit;
  SBar := SW^.get_hscrollbar;
  if (SBar <> nil) and not SBar^.get_visible then
    if gtk_adjustment_get_value(AAdjustment) <> 0 then
      gtk_adjustment_set_value(AAdjustment, 0);
end;

{$IFDEF UNIX}
{ --- X11 XSizeHints support ---
  GTK4 removed gtk_window_set_geometry_hints and has no max-size API.
  On X11, we set PMaxSize in XSizeHints directly via Xlib to let the
  window manager enforce max width/height during interactive resize.
  Functions are loaded dynamically to avoid hard dependency on X11. }
type
  { Must match Xlib XSizeHints layout. flags = C long (PtrInt), rest = C int. }
  TX11SizeHints = record
    flags: PtrInt;
    x, y: Integer;
    width, height: Integer;
    min_width, min_height: Integer;
    max_width, max_height: Integer;
    width_inc, height_inc: Integer;
    min_aspect_x, min_aspect_y: Integer;
    max_aspect_x, max_aspect_y: Integer;
    base_width, base_height: Integer;
    win_gravity: Integer;
  end;
  PX11SizeHints = ^TX11SizeHints;

  TX11GetWMNormalHints = function(display: Pointer; w: PtrUInt;
    hints_return: PX11SizeHints; supplied_return: Pointer): Integer; cdecl;
  TX11SetWMNormalHints = procedure(display: Pointer; w: PtrUInt;
    hints: PX11SizeHints); cdecl;
  TX11TranslateCoordinates = function(display: Pointer; src_w, dest_w: PtrUInt;
    src_x, src_y: LongInt; out dest_x, dest_y: LongInt;
    out child_return: PtrUInt): LongInt; cdecl;
  TX11DefaultRootWindow = function(display: Pointer): PtrUInt; cdecl;
  TX11MoveWindow = function(display: Pointer; w: PtrUInt;
    x, y: LongInt): LongInt; cdecl;
  TX11InternAtom = function(display: Pointer; name: PChar;
    only_if_exists: LongBool): PtrUInt; cdecl;
  { format=32 expects data as C long array (8 bytes each on LP64) —
    pass a PtrUInt variable's address for a single Atom. }
  TX11ChangeProperty = function(display: Pointer; w: PtrUInt;
    prop, proptype: PtrUInt; format: LongInt; mode: LongInt;
    data: Pointer; nelements: LongInt): LongInt; cdecl;
  TGdkX11GetXDisplay = function(display: PGdkDisplay): Pointer; cdecl;
  TGdkX11SurfaceGetXid = function(surface: Pointer): PtrUInt; cdecl;

  { Must match Xlib XSetWindowAttributes layout (x86_64: XID/unsigned long/long
    = 8 bytes → PtrUInt/PtrInt, int/Bool = 4 bytes → Integer). Only
    override_redirect is used; the rest keep the layout correct. }
  TX11SetWindowAttributes = record
    background_pixmap: PtrUInt;      { Pixmap (XID) }
    background_pixel: PtrUInt;       { unsigned long }
    border_pixmap: PtrUInt;         { Pixmap (XID) }
    border_pixel: PtrUInt;          { unsigned long }
    bit_gravity: Integer;           { int }
    win_gravity: Integer;           { int }
    backing_store: Integer;         { int }
    backing_planes: PtrUInt;        { unsigned long }
    backing_pixel: PtrUInt;         { unsigned long }
    save_under: Integer;            { Bool }
    event_mask: PtrInt;             { long }
    do_not_propagate_mask: PtrInt;  { long }
    override_redirect: Integer;     { Bool }
    colormap: PtrUInt;              { Colormap (XID) }
    cursor: PtrUInt;                { Cursor (XID) }
  end;
  PX11SetWindowAttributes = ^TX11SetWindowAttributes;

  TX11ChangeWindowAttributes = function(display: Pointer; w: PtrUInt;
    valuemask: PtrUInt; attributes: PX11SetWindowAttributes): LongInt; cdecl;
  TX11RaiseWindow = function(display: Pointer; w: PtrUInt): LongInt; cdecl;

const
  X11_PMaxSize = PtrInt(1) shl 5;
  X11_CWOverrideRedirect = PtrUInt(1) shl 9;   { X.h: CWOverrideRedirect }
  X11_PropModeReplace = 0;                     { X.h: PropModeReplace }
  X11_XA_ATOM = PtrUInt(4);                    { Xatom.h: XA_ATOM }

var
  X11HintsInit: Boolean = False;
  X11HintsOK: Boolean = False;
  X11pGetXDisplay: TGdkX11GetXDisplay = nil;
  X11pGetXid: TGdkX11SurfaceGetXid = nil;
  X11pGetHints: TX11GetWMNormalHints = nil;
  X11pSetHints: TX11SetWMNormalHints = nil;
  X11pTranslateCoordinates: TX11TranslateCoordinates = nil;
  X11pDefaultRootWindow: TX11DefaultRootWindow = nil;
  X11pMoveWindow: TX11MoveWindow = nil;
  X11pChangeWindowAttributes: TX11ChangeWindowAttributes = nil;
  X11pRaiseWindow: TX11RaiseWindow = nil;
  X11pInternAtom: TX11InternAtom = nil;
  X11pChangeProperty: TX11ChangeProperty = nil;

procedure InitX11SizeHints;
var
  hGdk, hX11: TLibHandle;
begin
  X11HintsInit := True;
  X11HintsOK := False;
  { GTK4 compiles GDK into libgtk-4.so.1 (no separate libgdk-4.so.1) }
  hGdk := LoadLibrary('libgtk-4.so.1');
  if hGdk = NilHandle then
    Exit;
  { Keep libraries loaded for app lifetime — no FreeLibrary }
  X11pGetXDisplay := TGdkX11GetXDisplay(GetProcAddress(hGdk, 'gdk_x11_display_get_xdisplay'));
  X11pGetXid := TGdkX11SurfaceGetXid(GetProcAddress(hGdk, 'gdk_x11_surface_get_xid'));
  hX11 := LoadLibrary('libX11.so.6');
  if hX11 = NilHandle then
    Exit;
  X11pGetHints := TX11GetWMNormalHints(GetProcAddress(hX11, 'XGetWMNormalHints'));
  X11pSetHints := TX11SetWMNormalHints(GetProcAddress(hX11, 'XSetWMNormalHints'));
  X11pTranslateCoordinates := TX11TranslateCoordinates(GetProcAddress(hX11, 'XTranslateCoordinates'));
  X11pDefaultRootWindow := TX11DefaultRootWindow(GetProcAddress(hX11, 'XDefaultRootWindow'));
  X11pMoveWindow := TX11MoveWindow(GetProcAddress(hX11, 'XMoveWindow'));
  X11pChangeWindowAttributes := TX11ChangeWindowAttributes(GetProcAddress(hX11, 'XChangeWindowAttributes'));
  X11pRaiseWindow := TX11RaiseWindow(GetProcAddress(hX11, 'XRaiseWindow'));
  X11pInternAtom := TX11InternAtom(GetProcAddress(hX11, 'XInternAtom'));
  X11pChangeProperty := TX11ChangeProperty(GetProcAddress(hX11, 'XChangeProperty'));
  X11HintsOK := Assigned(X11pGetXDisplay) and Assigned(X11pGetXid)
    and Assigned(X11pSetHints);
end;
{$ENDIF}

function Gtk4X11GetWindowOrigin(AWidget: PGtkWidget; out X, Y: LongInt): Boolean;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow, RootWindow, ChildReturn: PtrUInt;
begin
  Result := False;
  X := 0;
  Y := 0;
  if (AWidget = nil) or not Gtk4IsWidget(PGObject(AWidget)) then Exit;
  if not X11HintsInit then
    InitX11SizeHints;
  if not Assigned(X11pTranslateCoordinates) or not Assigned(X11pGetXDisplay)
     or not Assigned(X11pGetXid) or not Assigned(X11pDefaultRootWindow) then
    Exit;
  Display := gdk_display_get_default;
  if Display = nil then Exit;
  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;
  Surface := gtk4_native_get_surface(AWidget);
  if Surface = nil then Exit;
  XWindow := X11pGetXid(Surface);
  RootWindow := X11pDefaultRootWindow(XDisplay);
  ChildReturn := 0;
  Result := X11pTranslateCoordinates(XDisplay, XWindow, RootWindow,
    0, 0, X, Y, ChildReturn) <> 0;
end;
{$ELSE}
begin
  Result := False;
  X := 0;
  Y := 0;
end;
{$ENDIF}

{ GTK4: notify::default-height / default-width callback.
  Two responsibilities:
  1. Enforce max constraints by snapping back (synchronous — critical on X11
     where the WM caches XSizeHints at drag start).
  2. Deliver LM_SIZE to the LCL.  In GTK4, notify::width/height does NOT
     fire for GtkWindow — only notify::default-width/height does.  Without
     this, the LCL never learns about user-initiated window resizes.
  FEnforcingMax prevents recursion (our set_default_size triggers another
  notify). }
procedure Gtk4WindowNotifyDefaultSizeCB({%H-}AWidget: PGObject;
  {%H-}pspec: Pointer; AData: gpointer); cdecl;
var
  AWindow: TGtk4Window;
  CurW, CurH: gint;
  MinW, MinH: gint;
  NeedFix: Boolean;
  Msg: TLMSize;
begin
  { Safety: verify the Pascal widget object is still attached to this GObject.
    During destruction, the GtkWindow may emit notify signals after the
    Pascal object has been freed or detached. }
  if g_object_get_data(AWidget, 'lclwidget') = nil then Exit;
  AWindow := TGtk4Window(AData);
  if (AWindow = nil) or not AWindow.IsWidgetOk then Exit;
  if AWindow.FEnforcingMax then Exit; { prevent recursion }

  PGtkWindow(AWindow.Widget)^.get_default_size(@CurW, @CurH);

  { GTK won't display below its minimum (set_size_request), but
    get_default_size may return a value below that minimum.
    Clamp up so our size reporting reflects the actual window. }
  AWindow.Widget^.get_size_request(@MinW, @MinH);
  if (MinW > 0) and (CurW < MinW) then CurW := MinW;
  if (MinH > 0) and (CurH < MinH) then CurH := MinH;

  { --- Constraint enforcement --- }
  if (AWindow.FMaxWidth > 0) or (AWindow.FMaxHeight > 0) then
  begin
    NeedFix := False;
    if (AWindow.FMaxHeight > 0) and (CurH > AWindow.FMaxHeight) then
    begin
      CurH := AWindow.FMaxHeight;
      NeedFix := True;
    end;
    if (AWindow.FMaxWidth > 0) and (CurW > AWindow.FMaxWidth) then
    begin
      CurW := AWindow.FMaxWidth;
      NeedFix := True;
    end;

    if NeedFix then
    begin
      AWindow.FEnforcingMax := True;
      try
        PGtkWindow(AWindow.Widget)^.set_default_size(CurW, CurH);
      finally
        AWindow.FEnforcingMax := False;
      end;
    end;
    { Do NOT rewrite WM_NORMAL_HINTS here — see Gtk4WindowAfterPaintCB.
      The snap-back above is the sole max-size enforcement. }
  end;

  { --- Deliver LM_SIZE to LCL --- }
  if not Assigned(AWindow.LCLObject) then Exit;
  if not AWindow.CanSendLCLMessage then Exit;
  if AWindow.InUpdate then Exit;
  if (CurW <= 0) or (CurH <= 0) then Exit;

  { GTK4: Convert GtkWindow size to LCL Height by subtracting non-client
    overhead (menu bar).  This is the inverse of SetBounds which adds
    overhead before set_default_size.  The LCL Height convention is:
    Height = client area (excluding menu bar), matching getClientRect. }
  Dec(CurH, AWindow.GetNonClientOverhead);
  if CurH < 1 then CurH := 1;

  { Invalidate the cached client rect so that WMSize (triggered by LM_SIZE
    below) recomputes it with fresh, consistent values.  We must NOT call
    DoAdjustClientRectChange here because GetWindowSize may still return
    stale allocation while the LCLObject dimensions haven't been updated yet
    by WMSize — that mismatch inflates the client rect and mispositions
    anchored children.  Qt5 follows the same pattern: alignment runs only
    after SetBounds has updated the form's dimensions. }
  if ((CurW <> AWindow.LCLObject.Width) or (CurH <> AWindow.LCLObject.Height) or
     AWindow.LCLObject.ClientRectNeedsInterfaceUpdate) then
    AWindow.LCLObject.InvalidateClientRectCache(False);

  FillChar(Msg{%H-}, SizeOf(Msg), #0);
  Msg.Msg := LM_SIZE;
  Msg.SizeType := SIZE_RESTORED or Size_SourceIsInterface;
  Msg.Width := Word(CurW);
  Msg.Height := Word(CurH);
  AWindow.DeliverMessage(Msg);

  { Check for position changes and send LM_MOVE if needed }
  AWindow.CheckSendLMMove;
end;

{ Per-frame move polling for max-constrained windows.  Connected only when
  FMaxWidth/FMaxHeight > 0 (SetMaxSize/ConnectAfterPaint).  Do NOT rewrite
  WM_NORMAL_HINTS here: GTK4's compute_toplevel_size unconditionally rewrites
  the hints (PMinSize only) on every layout pass, so reasserting PMaxSize per
  frame makes the hint content toggle min-only <-> min+max at frame rate.
  Mutter re-evaluates window features on each change (fixed height <->
  vertically resizable), rebuilding the frame — visible as rapid full-width
  flicker at the window bottom whenever hover animations produce frames.
  Max size is enforced solely by the notify::default-size snap-back in
  Gtk4WindowNotifyDefaultSizeCB. }
procedure Gtk4WindowAfterPaintCB({%H-}AClock: PGdkFrameClock; AData: gpointer); cdecl;
var
  AWindow: TGtk4Window;
begin
  if (AData = nil) or not Gtk4IsWidget(PGtkWidget(AData)) then Exit;
  AWindow := TGtk4Window(g_object_get_data(PGObject(AData), 'lclwidget'));
  if (AWindow = nil) or not AWindow.IsWidgetOk then Exit;
  { Track window position changes and send LM_MOVE }
  AWindow.CheckSendLMMove;
end;

class function TGtk4Window.decoration_flags(Aform: TCustomForm): TGdkWMDecoration;
var
  icns:TBorderIcons;
  bs:TFormBorderStyle;
begin
  Result := [];
  icns:=AForm.BorderIcons;
  bs:=AForm.BorderStyle;

  case bs of
  bsSingle: Include(Result, GDK_DECOR_TITLE{GDK_DECOR_BORDER});
  bsDialog:
      Result += [GDK_DECOR_BORDER, GDK_DECOR_TITLE];
  bsSizeable:
    begin
      if biMaximize in icns then
        Include(Result, GDK_DECOR_MAXIMIZE);
      if biMinimize in icns then
        Include(Result, GDK_DECOR_MINIMIZE);
      Result += [GDK_DECOR_BORDER, GDK_DECOR_RESIZEH, GDK_DECOR_TITLE];
    end;
  bsSizeToolWin:
    Result += [GDK_DECOR_BORDER, GDK_DECOR_RESIZEH, GDK_DECOR_TITLE];
  bsToolWindow:
    Include(Result, GDK_DECOR_BORDER);
  bsNone: Result := [];
  end;

  if GDK_DECOR_TITLE in Result then
  if biSystemMenu in icns then
     Include(Result, GDK_DECOR_MENU);
end;

function TGtk4Window.ShowState(nstate:integer):boolean; // winapi ShowWindow
begin
  if not Gtk4IsGtkWindow(fWidget) then
    exit(false);
  if not Gtk4WindowCanPresent(Self) then
  begin
    Hide;
    exit(true);
  end;
  case nstate of
  SW_SHOWNORMAL:
    begin
      { GTK4: GdkWindow state query removed. Just present the window. }
      PGtkWindow(fWidget)^.unmaximize;
      PGtkWindow(fWidget)^.present;
    end;
  SW_SHOWMAXIMIZED: PGtkWindow(fWidget)^.maximize;
  SW_MINIMIZE, SW_SHOWMINIMIZED, SW_SHOWMINNOACTIVE:
    gtk4_window_minimize(PGtkWindow(fWidget));
  SW_SHOWFULLSCREEN: PGtkWindow(fWidget)^.fullscreen;
  SW_RESTORE:
    begin
      { Restore from minimized, maximized or fullscreen to normal state }
      PGtkWindow(fWidget)^.unmaximize;
      gtk_window_unminimize(PGtkWindow(fWidget));
      PGtkWindow(fWidget)^.unfullscreen;
      PGtkWindow(fWidget)^.present;
    end;
  SW_SHOWNOACTIVATE:
    begin
      { Show without activating — present would steal focus }
      PGtkWidget(fWidget)^.show;
    end;
  else
    PGtkWidget(fWidget)^.show;
  end;
  Result := true;
end;

procedure TGtk4Window.UpdateWindowState; // LCL WindowState
const
  ShowCommands: array[TWindowState] of Integer =
      (SW_SHOWNORMAL, SW_MINIMIZE, SW_SHOWMAXIMIZED, SW_SHOWFULLSCREEN);
begin
  ShowState(ShowCommands[TCustomForm(LCLObject).WindowState]);
end;

function TGtk4Window.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AForm: TCustomForm;
begin
  FIcon := nil;
  FScrollX := 0;
  FScrollY := 0;
  FMaxWidth := 0;
  FMaxHeight := 0;
  FComputeSizeId := 0;
  FEnforcingMax := False;

  FHasPaint := True;
  AForm := TCustomForm(LCLObject);

  if not Assigned(LCLObject.Parent) then
  begin
    { GTK4: gtk_window_new() takes no args, always creates toplevel }
    Result := gtk4_window_new;
    FWidget := Result;
    Title := Params.Caption;
    { GTK4: gdk_window_set_decorations removed. Use gtk_window_set_decorated. }
    gtk_window_set_decorated(PGtkWindow(Result), AForm.BorderStyle <> bsNone);
    if AForm.AlphaBlend then
      gtk_widget_set_opacity(Result, TForm(LCLObject).AlphaBlendValue/255);

    FWidgetType := [wtWidget, wtLayout, wtScrollingWin, wtWindow];
  end else
  begin
    { GTK4: gtk_scrolled_window_new() takes no args }
    Result := gtk4_scrolled_window_new;
    FWidgetType := [wtWidget, wtLayout, wtScrollingWin, wtCustomControl]
  end;
  Text := Params.Caption;

  { GTK4: TGtkVBox removed. Use gtk_box_new with vertical orientation. }
  FBox := PGtkBox(gtk_box_new(GTK_ORIENTATION_VERTICAL, 0));

  { GTK4: Create GMenu model + GtkPopoverMenuBar instead of GtkMenuBar }
  FMenuModel := nil;
  FMenuActionGroup := nil;
  FMenuBar := nil;
  if (AForm.Menu <> nil) then
  begin
    FMenuModel := PGMenu(g_menu_new);
    FMenuActionGroup := g_simple_action_group_new;
    FMenuBar := gtk4_popover_menu_bar_new_from_model(PGMenuModel(FMenuModel));
    gtk_widget_insert_action_group(FMenuBar, PgChar('menu'), PGActionGroup(FMenuActionGroup));
    g_object_set_data(Result,'lclmenubar',GPointer(1));
    gtk4_box_append(FBox, FMenuBar);
  end;

  { GTK4: gtk_scrolled_window_new() takes no args }
  FScrollWin := PGtkScrolledWindow(gtk4_scrolled_window_new);
  g_object_set_data(FScrollWin,'lclscrollingwindow',GPointer(1));
  g_object_set_data(PGObject(FScrollWin), 'lclwidget', Self);

  { GTK4: TGtkLayout removed. Use TGtkFixed instead. }
  FCentralWidget := TGtkFixed.new;
  g_object_set_data(PGObject(FCentralWidget), 'lclwidget', Self);
  g_object_set_data(PGObject(FCentralWidget), 'lcl-scroll-fixed', GPointer(1));
  gtk4_widget_set_can_target(FCentralWidget, True);

  { GTK4: ScrolledWindow.add / add_with_viewport removed. Use set_child. }
  gtk4_scrolled_window_set_child(FScrollWin, FCentralWidget);

  { GTK4: Use GtkOverlay so the DrawingArea renders ON TOP of form content.
    Hierarchy: GtkBox → GtkOverlay → [ScrolledWindow (main), DrawingArea (overlay)]
    This ensures custom painting appears above all child widgets. }
  FOverlay := PGtkWidget(gtk4_overlay_new);
  FOverlay^.set_hexpand(True);
  FOverlay^.set_vexpand(True);
  PGtkWidget(FScrollWin)^.set_hexpand(True);
  PGtkWidget(FScrollWin)^.set_vexpand(True);
  gtk4_overlay_set_child(PGtkOverlay(FOverlay), PGtkWidget(FScrollWin));

  SetupPaintArea(PGtkOverlay(FOverlay));

  { GTK4: pack_end removed. Use gtk4_box_append (appends at end). }
  gtk4_box_append(FBox, FOverlay);

  { GTK4: Start with POLICY_NEVER — matching GTK2 behaviour. The patched
    LCLFixedLayoutMeasure returns minimum=0 for tagged GtkFixed children,
    so POLICY_NEVER no longer propagates a large minimum to the window.
    LCL manages scrollbar visibility via ShowScrollBar/SetScrollInfo which
    switch to POLICY_ALWAYS/POLICY_NEVER as needed. Overlay scrolling is
    disabled so GTK4 does not show transient scrollbar indicators on hover
    (which would conflict with LCL scrollbar management and cause flicker). }
  FScrollWin^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_NEVER);
  FScrollWin^.set_overlay_scrolling(False);
  FScrollWin^.set_kinetic_scrolling(False);
  FScrollWin^.set_propagate_natural_height(False);
  FScrollWin^.set_propagate_natural_width(False);
  g_signal_connect_data(
    gtk_scrolled_window_get_vadjustment(FScrollWin), 'value-changed',
    TGCallback(@Gtk4WindowVScrollPinCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(
    gtk_scrolled_window_get_hadjustment(FScrollWin), 'value-changed',
    TGCallback(@Gtk4WindowHScrollPinCB), Self, nil, G_CONNECT_DEFAULT);
  FScrollWin^.get_vscrollbar^.set_can_focus(False);
  FScrollWin^.get_hscrollbar^.set_can_focus(False);

  { GTK4: PGtkContainer^.add removed. Use gtk_window_set_child for windows. }
  if wtWindow in FWidgetType then
    gtk4_window_set_child(PGtkWindow(Result), PGtkWidget(FBox))
  else
    gtk4_scrolled_window_set_child(PGtkScrolledWindow(Result), PGtkWidget(FBox));

  if wtWindow in FWidgetType then
  begin
    g_signal_connect_data(Result, 'close-request', TGCallback(@Gtk4CloseRequestCB), Self, nil, G_CONNECT_DEFAULT);
    { GTK4: Track window state changes via property notify signals }
    g_signal_connect_data(Result, 'notify::maximized', TGCallback(@Gtk4WindowStateNotifyCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(Result, 'notify::fullscreened', TGCallback(@Gtk4WindowStateNotifyCB), Self, nil, G_CONNECT_DEFAULT);
    { GTK4: notify::width/height does NOT fire for GtkWindow — only child
      widgets.  Use notify::default-width/height instead.  This callback
      handles both constraint enforcement and LM_SIZE delivery. }
    FComputeSizeId := g_signal_connect_data(Result, 'notify::default-height',
      TGCallback(@Gtk4WindowNotifyDefaultSizeCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(Result, 'notify::default-width',
      TGCallback(@Gtk4WindowNotifyDefaultSizeCB), Self, nil, G_CONNECT_DEFAULT);
    { Single-source LCL focus delivery — see Gtk4WindowFocusWidgetCB. }
    g_signal_connect_data(Result, 'notify::focus-widget',
      TGCallback(@Gtk4WindowFocusWidgetCB), Self, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(Result, 'notify::is-active',
      TGCallback(@Gtk4WindowIsActiveCB), Self, nil, G_CONNECT_DEFAULT);
  end;

  if AForm.FormStyle = fsSplash then
  begin
    gtk_window_set_decorated(PGtkWindow(Result), False);
    PGtkWindow(Result)^.set_resizable(False);
    Result^.set_size_request(Params.Width, Params.Height);
    FCentralWidget^.set_size_request(Params.Width, Params.Height);
  end;

  { GTK4: Set initial default size BEFORE UpdateWindowState calls present().
    Without this, present() maps the window at its natural content size
    (the GtkFixed bounding box), which can be much larger than intended.
    set_default_size must be called before the first show/present. }
  if wtWindow in FWidgetType then
  begin
    PGtkWindow(Result)^.set_default_size(Params.Width, Params.Height);
  end;

  { GTK4: Do NOT call UpdateWindowState here. UpdateWindowState calls
    ShowState(SW_SHOWNORMAL) which calls present() — this makes the
    GtkWindow visible immediately during CreateWidget, even for forms
    that should remain hidden (e.g. dialogs created but not yet shown).
    Window state is applied in ShowHide when the form becomes visible. }
end;

function TGtk4Window.EatArrowKeys(const AKey: Word): Boolean;
begin
  Result := False;
end;

function TGtk4Window.getText: String;
begin
  // query widget
  Result:=Title;
  // return cached
  if Result='' then
    Result := inherited GetText;
end;

procedure TGtk4Window.setText(const AValue: String);
begin
  // set cached text
  inherited SetText(AValue);
  // set widget text
  Title := AValue;
end;

function TGtk4Window.GetMenuBarHeight: Integer;
var
  MenuH: gint;
begin
  Result := 0;
  if (FMenuBar <> nil) and FMenuBar^.get_visible then
  begin
    { Use allocated height when available (accurate after realization).
      Include CSS margins — they consume space in the parent GtkBox
      but are NOT included in allocated_height. }
    MenuH := FMenuBar^.get_allocated_height;
    if MenuH > 0 then
      Result := MenuH
        + gtk_widget_get_margin_top(FMenuBar)
        + gtk_widget_get_margin_bottom(FMenuBar)
    else
    begin
      { Before realization, measure natural height }
      MenuH := 0;
      gtk4_widget_measure(FMenuBar, GTK_ORIENTATION_VERTICAL, -1,
        nil, @MenuH, nil, nil);
      Result := MenuH;
    end;
  end;
end;

function TGtk4Window.GetNonClientOverhead: Integer;
var
  Viewport: PGtkWidget;
  BoxNatH, ViewportNatH: gint;
begin
  { Compute total vertical space consumed by non-client elements
    between the window content area and the actual client viewport.
    This includes: menu bar + CSS margins + GtkBox CSS padding +
    GtkOverlay CSS + GtkScrolledWindow CSS borders/frame.

    The client area = the GtkViewport inside FScrollWin, which is
    FCentralWidget's parent.  This is where the LCL places child controls.

    Use widget measurements (natural heights) which are stable regardless
    of current allocation state. Do NOT use get_allocated_height — during
    constraint changes the window and viewport allocations are out of sync,
    giving wildly wrong overhead (e.g. 52 instead of 26). This caused
    getClientRect to under-report the client area, shrinking CoolBar. }
  Viewport := nil;
  if (FCentralWidget <> nil) then
    Viewport := FCentralWidget^.get_parent;

  if (FBox <> nil) and (Viewport <> nil) then
  begin
    { Measure overhead from natural heights.
      For a vertical GtkBox containing MenuBar + Overlay:
        Box.natural = Menu.natural + Overlay.natural + padding
      The viewport is nested: Overlay → ScrolledWindow → Viewport.
      Overhead = Box.natural - Viewport.natural captures ALL
      intermediate CSS (GtkBox padding, ScrolledWindow frame, etc.) }
    BoxNatH := 0;
    ViewportNatH := 0;
    gtk4_widget_measure(PGtkWidget(FBox), GTK_ORIENTATION_VERTICAL, -1,
      nil, @BoxNatH, nil, nil);
    gtk4_widget_measure(Viewport, GTK_ORIENTATION_VERTICAL, -1,
      nil, @ViewportNatH, nil, nil);
    if BoxNatH > ViewportNatH then
      Result := BoxNatH - ViewportNatH
    else
      Result := GetMenuBarHeight;
  end
  else
    Result := GetMenuBarHeight;
end;

function TGtk4Window.getClientRect: TRect;
var
  W, H, MinW, MinH: gint;
begin
  { GTK4: Use get_default_size for the window dimensions.  During
    interactive resize, notify::default-width/height fires BEFORE GTK
    has re-allocated children — get_allocated_width/height would return
    stale values at that point.  get_default_size is updated immediately
    and reflects the current window content size. }
  if not IsWidgetOK then
  begin
    Result := LCLObject.BoundsRect;
    Types.OffsetRect(Result, -Result.Left, -Result.Top);
    Exit;
  end;

  PGtkWindow(FWidget)^.get_default_size(@W, @H);

  { Before set_default_size is called, values are -1. Fall back to allocation. }
  if (W <= 0) or (H <= 0) then
  begin
    W := FWidget^.get_allocated_width;
    H := FWidget^.get_allocated_height;
  end;

  { Before realization, fall back to LCLObject bounds }
  if (W <= 0) and (H <= 0) then
  begin
    Result := LCLObject.BoundsRect;
    Types.OffsetRect(Result, -Result.Left, -Result.Top);
    Exit;
  end;

  { GTK4: get_default_size can return a value below the GTK minimum
    (from set_size_request). The actual window will never be smaller
    than the minimum, so clamp up to avoid under-reporting. }
  FWidget^.get_size_request(@MinW, @MinH);
  if (MinW > 0) and (W > 0) and (W < MinW) then W := MinW;
  if (MinH > 0) and (H > 0) and (H < MinH) then H := MinH;

  { Subtract non-client overhead (menu bar + CSS margins/padding) }
  Dec(H, GetNonClientOverhead);
  if H < 0 then H := 0;

  Result := Rect(0, 0, W, H);
end;

function TGtk4Window.GetClientAreaOffset: TPoint;
begin
  { Form client area starts below the menu bar (getClientBounds subtracts
    the same overhead from the height). }
  Result := Point(0, GetNonClientOverhead);
end;

function TGtk4Window.getClientBounds: TRect;
var
  W, H, MinW, MinH: gint;
begin
  { Must be consistent with getClientRect — use get_default_size for
    immediate values during interactive resize. }
  if not IsWidgetOK then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  PGtkWindow(FWidget)^.get_default_size(@W, @H);
  if (W <= 0) or (H <= 0) then
  begin
    W := FWidget^.get_allocated_width;
    H := FWidget^.get_allocated_height;
  end;

  if (W <= 0) and (H <= 0) then
  begin
    Result := Rect(0, 0, 0, 0);
    Exit;
  end;

  { Clamp up to GTK minimum — same as getClientRect }
  FWidget^.get_size_request(@MinW, @MinH);
  if (MinW > 0) and (W > 0) and (W < MinW) then W := MinW;
  if (MinH > 0) and (H > 0) and (H < MinH) then H := MinH;

  Dec(H, GetNonClientOverhead);
  if H < 0 then H := 0;

  Result := Rect(0, 0, W, H);
end;

procedure TGtk4Window.SetBounds(ALeft,ATop,AWidth,AHeight:integer);
var
  MinW, MinH: gint;
  CurW, CurH: gint;
  Overhead: Integer;
  Msg: TLMSize;
  {$IFDEF UNIX}
  Surface: Pointer;
  {$ENDIF}
begin
  CurW := 0;
  CurH := 0;
  BeginUpdate;
  try
    { GTK4: application code must not call gtk_widget_size_allocate() on
      toplevel windows. Only apply size through gtk_window_set_default_size().
      Positioning is compositor-managed in GTK4/Wayland. }
    if AWidth < 1 then AWidth := 1;
    if AHeight < 1 then AHeight := 1;
    if Gtk4IsGtkWindow(fWidget) then
    begin
      { GTK4: The LCL Height = client area (excluding menu bar), but
        GtkWindow default_size = full content (including menu bar).
        Add non-client overhead so that LCL Height maps correctly to
        the GtkWindow size. This compensates for LCL constraint
        clamping (Constraints.MaxHeight) which operates on LCL Height
        without knowing about the menu bar overhead. }
      Inc(AHeight, GetNonClientOverhead);
      { GTK4: Clamp to max constraints. FMaxHeight is already in
        GtkWindow coordinates (includes menu bar height). }
      if (FMaxWidth > 0) and (AWidth > FMaxWidth) then
        AWidth := FMaxWidth;
      if (FMaxHeight > 0) and (AHeight > FMaxHeight) then
        AHeight := FMaxHeight;
      { GTK4: Clamp UP to the GTK minimum (from set_size_request).
        GTK won't display the window smaller than its minimum, but
        get_default_size would return the unclamped value, causing
        getClientRect to report a size smaller than actual. }
      FWidget^.get_size_request(@MinW, @MinH);
      if (MinW > 0) and (AWidth < MinW) then AWidth := MinW;
      if (MinH > 0) and (AHeight < MinH) then AHeight := MinH;
      { GTK4: Preserve width when the window is already realized.
        During the show sequence, the LCL may call SetBounds with
        design-time form dimensions (e.g. 320x240) after the window
        has been positioned by the WM/session manager at the correct
        width (e.g. 1471). Shrinking the default_size width triggers
        CoolBar re-layout, causing CalcMainIDEHeight oscillation.
        NOT for hint windows: they are resized for every hint text and
        must be able to SHRINK (GTK remembers the size across hide/show,
        so a sticky maximum width would turn short hints into wide
        empty strips). }
      if Widget^.get_realized and not (wtHintWindow in FWidgetType) then
      begin
        PGtkWindow(Widget)^.get_default_size(@CurW, @CurH);
        if CurW > AWidth then
          AWidth := CurW;
      end;
      PGtkWindow(Widget)^.set_default_size(AWidth, AHeight);

      {$IFDEF UNIX}
      { GTK4: gtk_window_move() was removed. Use X11 XMoveWindow to position
        undecorated popup windows (SynCompletion, hints) at absolute screen
        coordinates.  Decorated windows are positioned by the WM — do NOT
        call XMoveWindow on them (it fights with the WM, causing drift).
        On Wayland, absolute positioning is not available — the compositor
        positions popups relative to their parent (set_transient_for). }
      if Widget^.get_realized and ((ALeft <> 0) or (ATop <> 0))
         and not PGtkWindow(Widget)^.get_decorated then
      begin
        if not X11HintsInit then
          InitX11SizeHints;
        if Assigned(X11pMoveWindow) and Assigned(X11pGetXDisplay)
           and Assigned(X11pGetXid) then
        begin
          Surface := gtk4_native_get_surface(Widget);
          if Surface <> nil then
            {%H-}X11pMoveWindow(
              X11pGetXDisplay(gdk_display_get_default),
              X11pGetXid(Surface),
              ALeft, ATop);
        end;
      end;
      {$ENDIF}
    end;
  finally
    EndUpdate;
  end;

  { GTK4: Deliver LM_SIZE that was suppressed by the InUpdate guard in
    Gtk4WindowNotifyDefaultSizeCB.  The notify::default-height signal fires
    synchronously during set_default_size (inside BeginUpdate/EndUpdate), so
    LM_SIZE delivery is skipped.  Without this, the LCL never learns about
    the new window height and doesn't re-layout children (CoolBar, toolbar
    icons).  Horizontal resize accidentally fixes this because GTK fires
    notify::default-width from outside any InUpdate context.
    The (CurW <> Width) / (CurH <> Height) guard prevents infinite oscillation:
    after the first delivery, LCLObject dimensions match and no further
    delivery occurs. }
  if Gtk4IsGtkWindow(fWidget) and Assigned(LCLObject) and
     CanSendLCLMessage and not InUpdate then
  begin
    PGtkWindow(FWidget)^.get_default_size(@CurW, @CurH);
    FWidget^.get_size_request(@MinW, @MinH);
    if (MinW > 0) and (CurW < MinW) then CurW := MinW;
    if (MinH > 0) and (CurH < MinH) then CurH := MinH;
    if (CurW > 0) and (CurH > 0) then
    begin
      Overhead := GetNonClientOverhead;
      Dec(CurH, Overhead);
      if CurH < 1 then CurH := 1;
      if ((CurW <> LCLObject.Width) or (CurH <> LCLObject.Height) or
         LCLObject.ClientRectNeedsInterfaceUpdate) then
      begin
        LCLObject.InvalidateClientRectCache(False);
        FillChar(Msg{%H-}, SizeOf(Msg), #0);
        Msg.Msg := LM_SIZE;
        Msg.SizeType := SIZE_RESTORED or Size_SourceIsInterface;
        Msg.Width := Word(CurW);
        Msg.Height := Word(CurH);
        DeliverMessage(Msg);
      end;
    end;
  end;
end;


function TGtk4Window.getHorizontalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  if (FScrollWin = nil) or (not Gtk4IsScrolledWindow(FScrollWin)) then
    exit;
  Result := PGtkScrollBar(FScrollWin^.get_hscrollbar);
  if (Result <> nil) and (not Gtk4IsWidget(PGObject(Result))) then
    Result := nil;
end;

function TGtk4Window.getVerticalScrollbar: PGtkScrollbar;
begin
  Result := nil;
  if not IsWidgetOk then
    exit;
  if (FScrollWin = nil) or (not Gtk4IsScrolledWindow(FScrollWin)) then
    exit;
  Result := PGtkScrollBar(FScrollWin^.get_vscrollbar);
  if (Result <> nil) and (not Gtk4IsWidget(PGObject(Result))) then
    Result := nil;
end;

function TGtk4Window.GetScrolledWindow: PGtkScrolledWindow;
begin
  if IsWidgetOK then
    Result := FScrollWin
  else
    Result := nil;
end;

procedure TGtk4Window.DoBeforeLCLPaint;
var
  DC: TGtk4DeviceContext;
  NColor: TColor;
begin
  inherited DoBeforeLCLPaint;
  if not Visible then
    exit;
  DC := TGtk4DeviceContext(Context);
  NColor := LCLObject.Color;
  if (NColor <> clNone) and (NColor <> clDefault) then
  begin
    DC.CurrentBrush.Color := ColorToRGB(NColor);
    DC.fillRect(0, 0, LCLObject.Width, LCLObject.Height);
  end;
end;

procedure TGtk4Window.DetachEvents;
var
  Adj: PGtkAdjustment;
  FrameClock: PGdkFrameClock;
begin
  { Disconnect signals on non-FWidget GObjects before DestroyWidget runs.
    During shutdown GTK may have already finalized these objects, so we
    must validate each GObject with Gtk4IsObject before touching it.
    Pattern follows GTK2 (GTK_IS_OBJECT check) and TGtk4MenuShell.Destroy. }
  if (FScrollWin <> nil) and Gtk4IsObject(PGObject(FScrollWin)) then
  begin
    Adj := gtk_scrolled_window_get_vadjustment(FScrollWin);
    if (Adj <> nil) and Gtk4IsObject(PGObject(Adj)) then
      g_signal_handlers_disconnect_matched(PGObject(Adj),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
    Adj := gtk_scrolled_window_get_hadjustment(FScrollWin);
    if (Adj <> nil) and Gtk4IsObject(PGObject(Adj)) then
      g_signal_handlers_disconnect_matched(PGObject(Adj),
        [G_SIGNAL_MATCH_DATA], 0, 0, nil, nil, Self);
  end;
  if FAfterPaintId <> 0 then
  begin
    if (FWidget <> nil) and Gtk4IsWidget(FWidget) then
    begin
      FrameClock := FWidget^.get_frame_clock;
      if (FrameClock <> nil) and Gtk4IsObject(PGObject(FrameClock)) then
        g_signal_handler_disconnect(PGObject(FrameClock), FAfterPaintId);
    end;
    FAfterPaintId := 0;
  end;
  inherited DetachEvents;
end;

destructor TGtk4Window.Destroy;
begin
  if Gtk4IsGdkPixbuf(FIcon) then
  begin
    FIcon^.unref;
    FIcon := nil;
  end;
  { Unref ref-counted GObjects — validate with Gtk4IsObject first because
    during shutdown GTK may have already finalized them (GTK2: GTK_IS_OBJECT
    pattern, already used in TGtk4MenuShell.Destroy). }
  if (FMenuModel <> nil) and Gtk4IsObject(PGObject(FMenuModel)) then
    g_object_unref(PGObject(FMenuModel));
  FMenuModel := nil;
  if (FMenuActionGroup <> nil) and Gtk4IsObject(PGObject(FMenuActionGroup)) then
    g_object_unref(PGObject(FMenuActionGroup));
  FMenuActionGroup := nil;
  inherited Destroy;
  { After inherited: FWidget destroyed, child widgets gone.
    Nil stale pointers to prevent accidental use. }
  FBox := nil;
  FScrollWin := nil;
  FOverlay := nil;
  FMenuBar := nil;
end;

procedure TGtk4Window.Activate;
begin
  if Gtk4IsGtkWindow(fWidget) then
  begin
    if not Gtk4WindowCanPresent(Self) then
      Exit;
    { GTK4: GdkWindow^.raise_ removed. present() handles raising+focusing. }
    PGtkWindow(FWidget)^.present;
  end;
end;

function TGtk4Window.Gtk4CloseQuery: Boolean;
var
  Msg : TLMessage;
begin
  {$IFDEF GTK4DEBUGCORE}
    DebugLn('TGtk4Window.Gtk4CloseQuery');
  {$ENDIF}
  FillChar(Msg{%H-}, SizeOf(Msg), 0);

  Msg.Msg := LM_CLOSEQUERY;

  DeliverMessage(Msg);

  Result := False;
end;

function TGtk4Window.GetWindow: PGdkWindow;
begin
  { GTK4: FWidget^.window (GdkWindow) removed. Return nil. }
  Result := nil;
end;

procedure TGtk4Window.EnsureMenuBar;
begin
  if FMenuBar <> nil then exit;
  if FBox = nil then exit;

  { Create menu bar on demand when a menu is assigned after form creation }
  FMenuModel := PGMenu(g_menu_new);
  FMenuActionGroup := g_simple_action_group_new;
  FMenuBar := gtk4_popover_menu_bar_new_from_model(PGMenuModel(FMenuModel));
  gtk_widget_insert_action_group(FMenuBar, PgChar('menu'), PGActionGroup(FMenuActionGroup));
  { Prepend to the box so it appears at the top }
  gtk4_box_prepend(FBox, FMenuBar);
end;

function TGtk4Window.GetMenuBar: PGtkWidget;
begin
  Result := FMenuBar;
end;

function TGtk4Window.GetMenuModel: PGMenu;
begin
  EnsureMenuBar;
  Result := FMenuModel;
end;

function TGtk4Window.GetMenuActionGroup: PGSimpleActionGroup;
begin
  EnsureMenuBar;
  Result := FMenuActionGroup;
end;

function TGtk4Window.GetBox: PGtkBox;
begin
  Result := FBox;
end;

procedure TGtk4Window.SetMaxSize(AMaxWidth, AMaxHeight: Integer);
var
  FrameClock: PGdkFrameClock;
begin
  { GTK4 CSS does not support max-width/max-height (GTK3-only properties) —
    enforcement is done solely via the notify::default-size snap-back in
    Gtk4WindowNotifyDefaultSizeCB.  X11 WM_NORMAL_HINTS PMaxSize is NOT
    used: GTK4 rewrites the hints on every layout pass, so keeping our max
    in them causes a WM-visible hint war (see Gtk4WindowAfterPaintCB). }
  FMaxWidth := AMaxWidth;
  FMaxHeight := AMaxHeight;
  ConnectComputeSize;

  { GTK4/X11: Connect to the frame clock's after-paint signal for move
    polling of max-constrained windows (LM_MOVE).  Max size itself is
    enforced by the notify::default-size snap-back — WM_NORMAL_HINTS must
    not be rewritten here (see Gtk4WindowAfterPaintCB comment). }
  if IsWidgetOk and (FAfterPaintId = 0)
     and ((AMaxWidth > 0) or (AMaxHeight > 0)) then
  begin
    FrameClock := Widget^.get_frame_clock;
    if FrameClock <> nil then
      FAfterPaintId := g_signal_connect_data(FrameClock, 'after-paint',
        TGCallback(@Gtk4WindowAfterPaintCB), Widget, nil, G_CONNECT_DEFAULT);
  end;
end;

procedure TGtk4Window.ConnectAfterPaint;
var
  FrameClock: PGdkFrameClock;
begin
  if FAfterPaintId <> 0 then Exit; { already connected }
  if (FMaxWidth <= 0) and (FMaxHeight <= 0) then Exit;
  if not IsWidgetOk then Exit;
  FrameClock := Widget^.get_frame_clock;
  if FrameClock <> nil then
    FAfterPaintId := g_signal_connect_data(FrameClock, 'after-paint',
      TGCallback(@Gtk4WindowAfterPaintCB), Widget, nil, G_CONNECT_DEFAULT);
end;

procedure TGtk4Window.ConnectComputeSize;
begin
  if FComputeSizeId <> 0 then Exit; { already connected }
  if not IsWidgetOk then Exit;
  { Connect to GtkWindow property notifications to detect user resize.
    GTK4 removed gtk_window_set_geometry_hints and has no set_max_size API,
    so we monitor default-height/width and snap back when exceeded.
    Both signals use the same handler — it checks both dimensions. }
  FComputeSizeId := g_signal_connect_data(Widget, 'notify::default-height',
    TGCallback(@Gtk4WindowNotifyDefaultSizeCB), Self, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(Widget, 'notify::default-width',
    TGCallback(@Gtk4WindowNotifyDefaultSizeCB), Self, nil, G_CONNECT_DEFAULT);
end;

{ NOTE: currently unused — kept for potential future use.  All PMaxSize call
  sites were removed because GTK4 rewrites WM_NORMAL_HINTS on every layout
  pass, turning any reassertion into a WM-visible hint war (frame flicker).
  Max size is enforced by the notify::default-size snap-back instead. }
procedure TGtk4Window.ApplyX11SizeHints;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow: PtrUInt;
  Hints: TX11SizeHints;
  Supplied: PtrInt;
begin
  if not IsWidgetOk then Exit;
  if (FMaxWidth <= 0) and (FMaxHeight <= 0) then Exit;

  if not X11HintsInit then
    InitX11SizeHints;
  if not X11HintsOK then Exit;

  Display := gdk_display_get_default;
  if Display = nil then Exit;

  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;

  Surface := gtk4_native_get_surface(Widget);
  if Surface = nil then Exit;

  XWindow := X11pGetXid(Surface);
  if XWindow = 0 then Exit;

  { Read existing hints — preserves GTK4-set min size, base size, etc. }
  FillChar(Hints, SizeOf(Hints), 0);
  Supplied := 0;
  if Assigned(X11pGetHints) then
    X11pGetHints(XDisplay, XWindow, @Hints, @Supplied);

  { Add max size constraint }
  Hints.flags := Hints.flags or X11_PMaxSize;
  if FMaxWidth > 0 then
    Hints.max_width := FMaxWidth
  else
    Hints.max_width := 32767; { effectively unlimited }
  if FMaxHeight > 0 then
    Hints.max_height := FMaxHeight
  else
    Hints.max_height := 32767;

  X11pSetHints(XDisplay, XWindow, @Hints);
end;
{$ELSE}
begin
  { X11 size hints not available on non-Unix }
end;
{$ENDIF}

{ GTK4/X11: Make this window an override-redirect popup (GTK2's
  GTK_WINDOW_POPUP / Qt5's QtBypassWindowManagerHint equivalent). The WM then
  fully ignores the window — it won't reposition it (XMoveWindow sticks) and
  won't give it focus (so the owning editor keeps focus and the completion
  popup isn't dismissed by an app-deactivate).
  MUST be called before the window is mapped: X evaluates override_redirect at
  map time. Realizes the widget (creates the unmapped GdkSurface), sets the
  attribute, then positions it at the LCL screen coordinates.
  On Wayland (X11 procs unresolved), only the realize happens — harmless. }
procedure TGtk4Window.PreparePopupShow;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow: PtrUInt;
  Attrs: TX11SetWindowAttributes;
begin
  if not IsWidgetOk then Exit;

  { Ensure the X window exists (unmapped) so we can set attributes before map. }
  gtk_widget_realize(Widget);

  if not X11HintsInit then
    InitX11SizeHints;
  if not Assigned(X11pChangeWindowAttributes) or not Assigned(X11pGetXDisplay)
     or not Assigned(X11pGetXid) then
    Exit;

  Display := gdk_display_get_default;
  if Display = nil then Exit;
  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;
  Surface := gtk4_native_get_surface(Widget);
  if Surface = nil then Exit;
  XWindow := X11pGetXid(Surface);
  if XWindow = 0 then Exit;

  FillChar(Attrs, SizeOf(Attrs), 0);
  Attrs.override_redirect := 1;
  X11pChangeWindowAttributes(XDisplay, XWindow, X11_CWOverrideRedirect, @Attrs);

  { Position at the LCL screen coordinates (SynCompletion sets Form.SetBounds
    with absolute screen coords; Left/Top are that screen position). }
  if Assigned(X11pMoveWindow) and Assigned(LCLObject) then
    X11pMoveWindow(XDisplay, XWindow, LCLObject.Left, LCLObject.Top);
end;
{$ELSE}
begin
  { Override-redirect popups are X11-only }
end;
{$ENDIF}

{ GTK4/X11: Raise an override-redirect popup above other windows after it is
  mapped. WM stacking doesn't apply to override-redirect surfaces, so raise
  explicitly to guarantee the popup is on top. Called after show(). }
{ GTK4/X11: Prepare a WM-managed hint window (normal THintWindow) for show.
  Unlike completion popups, hints stay WM-managed (no override-redirect), so
  the WM must be told to leave placement and focus alone:
  - GDK4 writes _NET_WM_WINDOW_TYPE_DIALOG when set_transient_for is called
    (gdksurface-x11.c) — Mutter then auto-places dialogs (centered on parent)
    and may focus them, which deactivates the app and hides the hint again.
    Overwrite the type with _NET_WM_WINDOW_TYPE_TOOLTIP: EWMH WMs exclude
    tooltips from auto-placement and focus.
  - Position via XMoveWindow at the LCL screen coordinates (THintWindow
    bounds are screen-absolute).
  MUST be called after set_transient_for (which would rewrite the type) and
  is idempotent — safe to call again right after map as a placement safety
  net. On Wayland only the realize happens — harmless. }
procedure TGtk4Window.PrepareTooltipShow;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow: PtrUInt;
  TooltipAtom, TypeAtom: PtrUInt;
begin
  if not IsWidgetOk then Exit;

  { Ensure the X window exists (unmapped) so properties can be set pre-map. }
  gtk_widget_realize(Widget);

  if not X11HintsInit then
    InitX11SizeHints;
  if not Assigned(X11pGetXDisplay) or not Assigned(X11pGetXid) then
    Exit;

  Display := gdk_display_get_default;
  if Display = nil then Exit;
  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;
  Surface := gtk4_native_get_surface(Widget);
  if Surface = nil then Exit;
  XWindow := X11pGetXid(Surface);
  if XWindow = 0 then Exit;

  if Assigned(X11pInternAtom) and Assigned(X11pChangeProperty) then
  begin
    TypeAtom := X11pInternAtom(XDisplay, '_NET_WM_WINDOW_TYPE', False);
    TooltipAtom := X11pInternAtom(XDisplay, '_NET_WM_WINDOW_TYPE_TOOLTIP', False);
    if (TypeAtom <> 0) and (TooltipAtom <> 0) then
      X11pChangeProperty(XDisplay, XWindow, TypeAtom, X11_XA_ATOM, 32,
        X11_PropModeReplace, @TooltipAtom, 1);
  end;

  { Position at the LCL screen coordinates (same as PreparePopupShow). }
  if Assigned(X11pMoveWindow) and Assigned(LCLObject) then
    X11pMoveWindow(XDisplay, XWindow, LCLObject.Left, LCLObject.Top);
end;
{$ELSE}
begin
  { X11-only; on other platforms transient_for placement applies. }
end;
{$ENDIF}

procedure TGtk4Window.RaiseX11Popup;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow: PtrUInt;
begin
  if not IsWidgetOk then Exit;
  if not Assigned(X11pRaiseWindow) or not Assigned(X11pGetXDisplay)
     or not Assigned(X11pGetXid) then
    Exit;
  Display := gdk_display_get_default;
  if Display = nil then Exit;
  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;
  Surface := gtk4_native_get_surface(Widget);
  if Surface = nil then Exit;
  XWindow := X11pGetXid(Surface);
  if XWindow = 0 then Exit;
  X11pRaiseWindow(XDisplay, XWindow);
end;
{$ELSE}
begin
  { Override-redirect popups are X11-only }
end;
{$ENDIF}

procedure TGtk4Window.CheckSendLMMove;
{$IFDEF UNIX}
var
  Display: PGdkDisplay;
  Surface: PGdkWindow;
  XDisplay: Pointer;
  XWindow: PtrUInt;
  RootWindow: PtrUInt;
  ChildReturn: PtrUInt;
  DestX, DestY: LongInt;
  X, Y: SmallInt;
  Msg: TLMMove;
begin
  if not IsWidgetOk then Exit;
  if not Assigned(LCLObject) then Exit;
  if not CanSendLCLMessage then Exit;

  if not X11HintsInit then
    InitX11SizeHints;
  if not X11HintsOK then Exit;
  if not Assigned(X11pTranslateCoordinates) then Exit;
  if not Assigned(X11pDefaultRootWindow) then Exit;

  Display := gdk_display_get_default;
  if Display = nil then Exit;

  XDisplay := X11pGetXDisplay(Display);
  if XDisplay = nil then Exit;

  Surface := gtk4_native_get_surface(Widget);
  if Surface = nil then Exit;

  XWindow := X11pGetXid(Surface);
  if XWindow = 0 then Exit;

  RootWindow := X11pDefaultRootWindow(XDisplay);
  ChildReturn := 0;
  DestX := 0;
  DestY := 0;
  X11pTranslateCoordinates(XDisplay, XWindow, RootWindow, 0, 0, DestX, DestY, ChildReturn);

  X := SmallInt(DestX);
  Y := SmallInt(DestY);

  { Only send if position actually changed }
  if FMoveTracked and (X = FLastMoveX) and (Y = FLastMoveY) then Exit;

  FLastMoveX := X;
  FLastMoveY := Y;
  FMoveTracked := True;

  FillChar(Msg{%H-}, SizeOf(Msg), 0);
  Msg.Msg := LM_MOVE;
  Msg.MoveType := Move_SourceIsInterface;
  Msg.XPos := X;
  Msg.YPos := Y;
  DeliverMessage(Msg);
end;
{$ELSE}
begin
  { Window position tracking requires X11 }
end;
{$ENDIF}

function TGtk4Window.GetWindowState: TGdkWindowState;
var
  ASurface: PGdkWindow;
  AState: guint;
begin
  Result := [];
  if not IsWidgetOK then Exit;
  if not Gtk4IsGtkWindow(FWidget) then Exit;
  ASurface := gtk4_native_get_surface(FWidget);
  if ASurface = nil then Exit;
  AState := gdk4_toplevel_get_state(ASurface);
  if (AState and GDK_TOPLEVEL_STATE_MINIMIZED) <> 0 then
    Include(Result, GDK_WINDOW_STATE_ICONIFIED);
  if (AState and GDK_TOPLEVEL_STATE_MAXIMIZED) <> 0 then
    Include(Result, GDK_WINDOW_STATE_MAXIMIZED);
  if (AState and GDK_TOPLEVEL_STATE_FULLSCREEN) <> 0 then
    Include(Result, GDK_WINDOW_STATE_FULLSCREEN);
  if (AState and GDK_TOPLEVEL_STATE_FOCUSED) <> 0 then
    Include(Result, GDK_WINDOW_STATE_FOCUSED);
  if (AState and GDK_TOPLEVEL_STATE_ABOVE) <> 0 then
    Include(Result, GDK_WINDOW_STATE_ABOVE);
  if (AState and GDK_TOPLEVEL_STATE_BELOW) <> 0 then
    Include(Result, GDK_WINDOW_STATE_BELOW);
  if (AState and GDK_TOPLEVEL_STATE_STICKY) <> 0 then
    Include(Result, GDK_WINDOW_STATE_STICKY);
end;

{ TGtk4HintWindow }

function TGtk4HintWindow.CreateWidget(const Params: TCreateParams): PGtkWidget;
var
  AForm: THintWindow;
begin
  FText := '';
  FHasPaint := True;
  AForm := THintWindow(LCLObject);

  FWidgetType := [wtWidget, wtContainer, wtWindow, wtHintWindow];

  { GTK4: GTK_WINDOW_POPUP removed. Create undecorated window for tooltip. }
  Result := gtk4_window_new;
  gtk_window_set_decorated(PGtkWindow(Result), False);
  PGtkWindow(Result)^.set_resizable(False);

  FBox := PGtkBox(gtk_box_new(GTK_ORIENTATION_VERTICAL, 0));
  gtk4_window_set_child(PGtkWindow(Result), PGtkWidget(FBox));

  FCentralWidget := TGtkFixed.new;
  { Tag FCentralWidget so LCLGtkFixedSnapshot can find the TGtk4HintWindow
    owner and call GtkEventPaint for hint content painting. }
  g_object_set_data(PGObject(FCentralWidget), 'lclwidget', Self);
  FCentralWidget^.set_size_request(AForm.Width, AForm.Height+1);

  gtk4_box_append(FBox, FCentralWidget);

  PGtkWindow(Result)^.set_can_focus(false);
end;

procedure TGtk4HintWindow.InitializeWidget;
begin
  inherited;
  { GTK4: GdkWindow / set_transient_for via GdkWindow removed.
    Hint window transient relationship will be handled differently. }
end;

procedure TGtk4HintWindow.SetBounds(ALeft, ATop, AWidth, AHeight: integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  { Track the current hint size in the central widget's size request —
    CreateWidget sets it only once, so without this the FIRST hint's size
    stays as the window minimum forever (the non-resizable window's natural
    size can never shrink for shorter hints).  The +1 mirrors the
    CreateWidget policy (AForm.Height+1). }
  if IsWidgetOk and Assigned(FCentralWidget) then
    FCentralWidget^.set_size_request(AWidth, AHeight + 1);
end;

{ TGtk4Dialog }

procedure TGtk4Dialog.SetCallbacks;
begin
  // common callbacks for all kind of dialogs
  g_signal_connect_data(fWidget,
    'destroy', TGCallback(@TGtk4Dialog.DestroyCB), Self, nil, G_CONNECT_DEFAULT);
  { GTK4: 'delete-event' removed, use 'close-request' }
  g_signal_connect_data(fWidget,
    'close-request', TGCallback(@TGtk4Dialog.CloseQueryCB), Self, nil, G_CONNECT_DEFAULT);

  g_signal_connect_data(fWidget,
    'response', TGCallback(@TGtk4Dialog.ResponseCB), Self, nil, G_CONNECT_DEFAULT);

  g_signal_connect_data(fWidget,
    'close', TGCallback(@TGtk4Dialog.CloseCB), Self, nil, G_CONNECT_DEFAULT);

  { GTK4: key-press-event/key-release-event removed. Dialogs handle Escape/Enter natively. }

  g_signal_connect_data(fWidget,
    'realize', TGCallback(@TGtk4Dialog.RealizeCB), Self, nil, G_CONNECT_DEFAULT);
end;

class function TGtk4Dialog.RealizeCB(dlg: TGtk4Dialog): GBoolean; cdecl;
begin
  Result := False;
  if (dlg=nil) then exit;
  if (wtDialog in dlg.WidgetType) then
  begin
    if Assigned(dlg.CommonDialog) then
      TCommonDialog(dlg.CommonDialog).DoShow;
  end;
  Result := True;
end;


class function TGtk4Dialog.DestroyCB(dlg:TGtk4Dialog): GBoolean; cdecl;
begin
  Result := True;
  if not Assigned(dlg) then exit;
  dlg.CommonDialog.UserChoice := mrCancel;
  dlg.QuitModalLoop;
  dlg.CommonDialog.Close;
end;

class function TGtk4Dialog.ResponseCB(response_id:gint; dlg: TGtk4Dialog): GBoolean; cdecl;
begin
  if Assigned(dlg) then
    Result:=dlg.response_handler(TGtkResponseType(response_id))
  else
    Result:= false;
end;

function TGtk4Dialog.response_handler(response_id:TGtkResponseType):boolean;
begin
 (* case response_id of
  GTK_RESPONSE_NONE:;
  GTK_RESPONSE_REJECT: ;
  GTK_RESPONSE_ACCEPT:;
  GTK_RESPONSE_DELETE_EVENT:;
  GTK_RESPONSE_OK:;
  GTK_RESPONSE_CANCEL:;
  GTK_RESPONSE_CLOSE:;
  GTK_RESPONSE_YES:;
  GTK_RESPONSE_NO:;
  GTK_RESPONSE_APPLY:;
  GTK_RESPONSE_HELP:;
  end;*)
  if response_id=GTK_RESPONSE_YES then
  begin
    Self.CommonDialog.UserChoice:=mrYes;
  end else
  if response_id=GTK_RESPONSE_NO then
  begin
    Self.CommonDialog.UserChoice:=mrNo;
  end else
  if response_id=GTK_RESPONSE_OK then
  begin
    Self.CommonDialog.UserChoice:=mrOk;
  end else
  if response_id=GTK_RESPONSE_CANCEL then
  begin
    Self.CommonDialog.UserChoice:=mrCancel;
  end else
  if response_id=GTK_RESPONSE_CLOSE then
  begin
    Self.CommonDialog.UserChoice:=mrClose;
  end;
  { GTK4: do NOT hide here. Like gtk2, the response handler only records
    UserChoice; the dialog is torn down by TCommonDialog.Close/DestroyHandle
    once DoExecute's wait loop observes UserChoice (and after DoCanClose has
    had a chance to veto it — hiding first would leave a vetoed dialog
    invisible). }
  QuitModalLoop;
  Result:=false;
end;

function TGtk4Dialog.close_handler(): boolean;
begin
  Result:=false;
end;

class function TGtk4Dialog.CloseCB(dlg: TGtk4Dialog): GBoolean;
  cdecl;
begin
  if Assigned(dlg) then
    Result:=dlg.close_handler()
  else
    Result:= true;
end;

class function TGtk4Dialog.CloseQueryCB(dlg:TGtk4Dialog): GBoolean;
  cdecl;
var
  theDialog : TCommonDialog;
  CanClose: boolean;
begin
  Result := False; // true = do nothing, false = destroy or hide window
  if (dlg=nil) then exit;
  if (dlg <> nil) and (wtDialog in TGtk4Widget(dlg).WidgetType) then
  begin
    theDialog := dlg.CommonDialog;
    if theDialog = nil then exit;
    if theDialog.OnCanClose<>nil then
    begin
      CanClose:=True;
      theDialog.DoCanClose(CanClose);
      Result := not CanClose;
    end;
  end;
end;



function TGtk4Dialog.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtDialog];
  Result := TGtkDialog.new;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('WARNING: TGtk4Dialog.CreateWidget should be used in real dialog constructor .');
  {$ENDIF}
end;

procedure TGtk4Dialog.InitializeWidget;
begin
  LCLIntf.SetProp(HWND(Self),'lclwidget', Self);
  SetCallbacks;
end;

procedure TGtk4Dialog.CloseDialog;
begin
  QuitModalLoop;
  if fWidget<>nil then
    fWidget^.destroy_;
end;

procedure TGtk4Dialog.QuitModalLoop;
begin
  if (FModalLoop <> nil) and g_main_loop_is_running(FModalLoop) then
    g_main_loop_quit(FModalLoop);
end;


{ TGtk4FileDialog }

function TGtk4FileDialog.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('ERROR: TGtk4FileDialog.CreateWidget error.');
  {$ENDIF}
  Result := TGtkFileChooserDialog.new;
end;

{ GTK4: GtkDialog button-to-response connection is broken in newer GTK4
  (GtkDialog/GtkFileChooserDialog deprecated since 4.10). Manually emit
  the 'response' signal when dialog buttons are clicked. }
type
  PGtk4DialogBtnInfo = ^TGtk4DialogBtnInfo;
  TGtk4DialogBtnInfo = record
    Dialog: PGtkDialog;
    ResponseId: TGtkResponseType;
  end;

procedure Gtk4DialogButtonClickedCB({%H-}button: PGtkWidget; data: gpointer); cdecl;
var
  Info: PGtk4DialogBtnInfo;
begin
  Info := PGtk4DialogBtnInfo(data);
  gtk_dialog_response(Info^.Dialog, Info^.ResponseId);
end;

procedure Gtk4DialogBtnInfoFreeCB(data: gpointer; {%H-}closure: PGClosure); cdecl;
begin
  Dispose(PGtk4DialogBtnInfo(data));
end;

constructor TGtk4FileDialog.Create(const ACommonDialog: TCommonDialog);

var
  FileDialog: TFileDialog absolute ACommonDialog;
  Action: TGtkFileChooserAction;
  AcceptLabel: String;
  AGFile: PGFile;
  Native: PGtkFileChooserNative;
begin
  inherited Create;
  FOwnWidget := True;

  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];

  CommonDialog := ACommonDialog;
  Action := GTK_FILE_CHOOSER_ACTION_OPEN;
  AcceptLabel := 'Open';

  if (FileDialog is TSaveDialog) or (FileDialog is TSavePictureDialog) then
  begin
    Action := GTK_FILE_CHOOSER_ACTION_SAVE;
    AcceptLabel := 'Save';
  end
  else
  if FileDialog is TSelectDirectoryDialog then
    Action := GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER;

  { Use GtkFileChooserNative (portal / native file dialog) instead of the
    deprecated GtkFileChooserDialog. The native dialog runs out-of-process, so
    it never hits the in-process GtkFileChooserWidget folder-load async that
    GTK 4.6.9 mis-reports as "cannot display folder contents". OK/Cancel are
    provided by the native UI; only the accept label is customised. FWidget
    holds the native dialog (a GObject, not a GtkWidget). }
  Native := gtk_file_chooser_native_new(PgChar(FileDialog.Title), nil, Action,
    PgChar(AcceptLabel), PgChar('Cancel'));
  FWidget := PGtkWidget(Native);

  { All chooser properties must be set BEFORE gtk_native_dialog_show — native
    dialogs reject changes while visible. }
  if FileDialog.InitialDir <> '' then
  begin
    AGFile := g_file_new_for_path(Pgchar(FileDialog.InitialDir));
    gtk4_file_chooser_set_current_folder(PGtkFileChooser(Native), AGFile, nil);
    g_object_unref(PGObject(AGFile));
  end;

  if Action in [GTK_FILE_CHOOSER_ACTION_SAVE, GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER] then
    { set_current_name expects a bare file name, not a path. }
    gtk_file_chooser_set_current_name(PGtkFileChooser(Native),
      Pgchar(ExtractFileName(FileDialog.FileName)));

  InitializeWidget;
end;

procedure TGtk4FileDialog.SetCallbacks;
begin
  { No-op. A GtkNativeDialog has no realize/destroy/close-request signals, so
    the base TGtk4Dialog.SetCallbacks (which connects those) must not run
    against the non-widget native dialog. The 'response'/'notify' handlers
    (Gtk4FileChooserResponseCB / Gtk4FileChooserNotifyCB) live in the widgetset
    unit and are connected there, in TGtk4WSFileDialog.SetCallbacks. }
end;

procedure TGtk4FileDialog.DestroyWidget;
begin
  { FWidget is a GtkFileChooserNative (GObject), not a GtkWidget, so the base
    gtk_window_destroy must not run on it. Destroy the native dialog, drop our
    reference, and clear FWidget so the inherited path becomes a no-op. }
  if FWidget <> nil then
  begin
    gtk_native_dialog_destroy(PGtkNativeDialog(FWidget));
    g_object_unref(PGObject(FWidget));
    FWidget := nil;
  end;
  inherited DestroyWidget;
end;

{ TGtk4FontSelectionDialog }

procedure TGtk4FontSelectionDialog.InitializeWidget;
var
  Btn: PGtkWidget;
  BtnInfo: PGtk4DialogBtnInfo;
  InitFont: TFont;
  pfd: PPangoFontDescription;
begin
  fWidget:=TGtkFontChooserDialog.new(PChar(CommonDialog.Title),nil);

  { Set the initial font from the dialog's Font property }
  InitFont := TFontDialog(CommonDialog).Font;
  if (InitFont <> nil) and (InitFont.Name <> '') then
  begin
    pfd := pango_font_description_new;
    pango_font_description_set_family(pfd, PGChar(InitFont.Name));
    if InitFont.Size > 0 then
      pango_font_description_set_size(pfd, InitFont.Size * PANGO_SCALE);
    if fsBold in InitFont.Style then
      pango_font_description_set_weight(pfd, PANGO_WEIGHT_BOLD)
    else
      pango_font_description_set_weight(pfd, PANGO_WEIGHT_NORMAL);
    if fsItalic in InitFont.Style then
      pango_font_description_set_style(pfd, PANGO_STYLE_ITALIC)
    else
      pango_font_description_set_style(pfd, PANGO_STYLE_NORMAL);
    PGtkFontChooser(fWidget)^.set_font_desc(pfd);
    pango_font_description_free(pfd);
  end;

  { PreviewText — GTK2 parity (gtk2wsdialogs sets it only when non-empty,
    keeping GTK's default sample string otherwise). GtkFontChooser still
    ships the preview entry in GTK 4.6 (deprecated in 4.10, present here).
    fdApplyButton has NO GtkFontChooserDialog counterpart — GTK4 removed
    the apply button; that option stays a documented backend limitation. }
  if TFontDialog(CommonDialog).PreviewText <> '' then
    gtk_font_chooser_set_preview_text(PGtkFontChooser(fWidget),
      PGChar(TFontDialog(CommonDialog).PreviewText));

  { GTK4: GtkDialog's internal button→response connection is broken in newer
    GTK4 versions (deprecated API). Manually bridge button clicks. }
  Btn := PGtkDialog(fWidget)^.get_widget_for_response(GTK_RESPONSE_CANCEL);
  if Btn <> nil then
  begin
    New(BtnInfo);
    BtnInfo^.Dialog := PGtkDialog(fWidget);
    BtnInfo^.ResponseId := GTK_RESPONSE_CANCEL;
    g_signal_connect_data(Btn, 'clicked',
      TGCallback(@Gtk4DialogButtonClickedCB), BtnInfo,
      TGClosureNotify(@Gtk4DialogBtnInfoFreeCB), G_CONNECT_DEFAULT);
  end;
  Btn := PGtkDialog(fWidget)^.get_widget_for_response(GTK_RESPONSE_OK);
  if Btn <> nil then
  begin
    New(BtnInfo);
    BtnInfo^.Dialog := PGtkDialog(fWidget);
    BtnInfo^.ResponseId := GTK_RESPONSE_OK;
    g_signal_connect_data(Btn, 'clicked',
      TGCallback(@Gtk4DialogButtonClickedCB), BtnInfo,
      TGClosureNotify(@Gtk4DialogBtnInfoFreeCB), G_CONNECT_DEFAULT);
  end;
  inherited InitializeWidget;
end;

function TGtk4FontSelectionDialog.response_handler(resp_id: TGtkResponseType): boolean;
var
  fnt: TFont;
  pch: PGtkFontChooser;
  pfd: PPangoFontDescription;
  sz: integer;
  sfamily: string;
  fnts: TFontStyles;
  AWeight: TPangoWeight;
  AStyle: TPangoStyle;
begin
  if resp_id = GTK_RESPONSE_OK then
  begin
    fnt := TFontDialog(CommonDialog).Font;
    pch := PGtkFontChooser(fWidget);
    pfd := pch^.get_font_desc;
    if pfd <> nil then
    begin
      sfamily := pfd^.get_family();
      sz := pch^.get_font_size() div PANGO_SCALE;
      fnt.Name := sfamily;
      fnt.Size := sz;

      { Use PangoFontDescription weight/style for reliable detection }
      fnts := [];
      AWeight := pfd^.get_weight();
      if AWeight >= PANGO_WEIGHT_BOLD then
        Include(fnts, fsBold);

      AStyle := pfd^.get_style();
      if AStyle in [PANGO_STYLE_ITALIC, PANGO_STYLE_OBLIQUE] then
        Include(fnts, fsItalic);

      { BACKEND LIMITATION: GtkFontChooser exposes no strikeout/underline
        controls, and the PangoFontDescription it returns has no such fields
        — underline/strikeout are Pango TEXT attributes (PangoAttribute), not
        font-description properties, so there is nothing to read back from
        the chooser. (Qt5 maps them because QFontDialog's QFont does carry
        underline/strikeOut.) Preserve the incoming TFont state so a caller
        that pre-set these styles keeps them across the dialog. }
      if fsStrikeOut in fnt.Style then
        Include(fnts, fsStrikeOut);
      if fsUnderline in fnt.Style then
        Include(fnts, fsUnderline);

      fnt.Style := fnts;
      pango_font_description_free(pfd);
    end;
  end;
  Result := inherited response_handler(resp_id);
end;

constructor TGtk4FontSelectionDialog.Create(const ACommonDialog: TCommonDialog);
begin
  inherited Create;
  FOwnWidget := True;

  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];

  CommonDialog := ACommonDialog;
  InitializeWidget;
end;

{ TGtk4newColorSelectionDialog }

procedure TGtk4newColorSelectionDialog.InitializeWidget;
var
  rgba:TGdkRGBA;
  Btn: PGtkWidget;
  BtnInfo: PGtk4DialogBtnInfo;
begin
  fWidget:= TGtkColorChooserDialog.new(PChar(Self.CommonDialog.Title),nil);
  self.color_to_rgba(TColorDialog(Self.CommonDialog).Color,rgba);
  PGtkColorChooser(fWidget)^.use_alpha:=false;
  PGtkColorChooser(fWidget)^.set_rgba(@rgba);
  { GTK4: GtkDialog's internal button→response connection is broken in newer
    GTK4 versions (deprecated API). Manually bridge button clicks. }
  Btn := PGtkDialog(fWidget)^.get_widget_for_response(GTK_RESPONSE_CANCEL);
  if Btn <> nil then
  begin
    New(BtnInfo);
    BtnInfo^.Dialog := PGtkDialog(fWidget);
    BtnInfo^.ResponseId := GTK_RESPONSE_CANCEL;
    g_signal_connect_data(Btn, 'clicked',
      TGCallback(@Gtk4DialogButtonClickedCB), BtnInfo,
      TGClosureNotify(@Gtk4DialogBtnInfoFreeCB), G_CONNECT_DEFAULT);
  end;
  Btn := PGtkDialog(fWidget)^.get_widget_for_response(GTK_RESPONSE_OK);
  if Btn <> nil then
  begin
    New(BtnInfo);
    BtnInfo^.Dialog := PGtkDialog(fWidget);
    BtnInfo^.ResponseId := GTK_RESPONSE_OK;
    g_signal_connect_data(Btn, 'clicked',
      TGCallback(@Gtk4DialogButtonClickedCB), BtnInfo,
      TGClosureNotify(@Gtk4DialogBtnInfoFreeCB), G_CONNECT_DEFAULT);
  end;
  inherited;
end;

function TGtk4newColorSelectionDialog.response_handler(resp_id: TGtkResponseType): boolean;
var
  clr:TColor;
  rgba:TGdkRGBA;
begin
  if resp_id=GTK_RESPONSE_OK then
  begin
    PGtkColorChooser(fWidget)^.get_rgba(@rgba);
    clr:=self.rgba_to_color(rgba);
    TColorDialog(Self.CommonDialog).Color:=clr;
  end;
  Result:=inherited response_handler(resp_id);
end;

constructor TGtk4newColorSelectionDialog.Create(const ACommonDialog: TCommonDialog
  );
begin
  inherited Create;
  FOwnWidget := True;

  LCLObject := nil;
  FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE];
  FWidgetType := [wtWidget, wtDialog];

  CommonDialog := ACommonDialog;
  TGtk4Widget(Self).InitializeWidget;
end;

class procedure TGtk4newColorSelectionDialog.color_to_rgba(clr: TColor; out
  rgba: TgdkRGBA);
begin
  clr:=ColorToRgb(clr);
  rgba.red:=Red(clr)/255;
  rgba.blue:=Blue(clr)/255;
  rgba.green:=Green(clr)/255;
  rgba.alpha:=(clr shl 24)/255;
end;

class function TGtk4newColorSelectionDialog.rgba_to_color(const rgba: TgdkRGBA
  ): TColor;
var
  q:array[0..3] of byte absolute Result;
begin
  q[0]:= round(255*rgba.red);
  q[1]:= round(255*rgba.green);
  q[2]:= round(255*rgba.blue);
  q[3]:= round(255*rgba.alpha);
end;


{ TGtk4GLArea }

procedure TGtk4GLArea.Update(ARect: PRect);
begin
  if IsWidgetOK then
    PGtkGLArea(Widget)^.queue_render;
end;

function TGtk4GLArea.CreateWidget(const Params: TCreateParams): PGtkWidget;
begin
  FWidgetType := [wtWidget, wtGLArea];
  Result := TGtkGLArea.new;
end;

initialization
  Gtk4DeferredMouseEvents := TFPList.Create;

finalization
  FreeAndNil(Gtk4DeferredMouseEvents);
  FreeAndNil(Gtk4LiveWidgetObjects);

end.
