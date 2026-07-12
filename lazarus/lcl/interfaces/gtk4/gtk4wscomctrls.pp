{
 *****************************************************************************
 *                             Gtk4WSComCtrls.pp                             *
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
unit Gtk4WSComCtrls;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // libs
  LazGtk4, LazGdk4, LazGlib2, LazGio2, LazGtk4_Compat,
  // RTL, FCL
  Types, Classes, Math, Sysutils,
  // LCL
  LCLType, Controls, Graphics, StdCtrls, ComCtrls, Forms,
  ImgList, InterfaceBase,
  // LazUtils
  LazLoggerBase,
  // widgetset
  WSComCtrls, WSLCLClasses, WSControls, WSProc,
  gtk4widgets;
  
type
  { TGtk4WSCustomPage }

  TGtk4WSCustomPage = class(TWSCustomPage)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLHandle; override;
    class procedure UpdateProperties(const ACustomPage: TCustomPage); override;
    class procedure SetBounds(const {%H-}AWinControl: TWinControl; const {%H-}ALeft, {%H-}ATop, {%H-}AWidth, {%H-}AHeight: Integer); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
    class function GetDefaultClientRect(const AWinControl: TWinControl;
             const {%H-}aLeft, {%H-}aTop, {%H-}aWidth, {%H-}aHeight: integer; var aClientRect: TRect
             ): boolean; override;
  end;

  { TGtk4WSCustomTabControl }

  TGtk4WSCustomTabControl = class(TWSCustomTabControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
                                const AParams: TCreateParams): TLCLHandle; override;
    class function GetDefaultClientRect(const AWinControl: TWinControl;
            const {%H-}aLeft, {%H-}aTop, aWidth, aHeight: integer; var aClientRect: TRect
            ): boolean; override;
    class function GetDesignInteractive(const AWinControl: TWinControl; AClientPos: TPoint): Boolean; override;
    class procedure AddPage(const ATabControl: TCustomTabControl;
      const AChild: TCustomPage; const AIndex: integer); override;
    class procedure MovePage(const ATabControl: TCustomTabControl;
      const AChild: TCustomPage; const NewIndex: integer); override;
    class procedure RemovePage(const ATabControl: TCustomTabControl; const AIndex: integer); override;

    class function GetCapabilities: TCTabControlCapabilities; override;
    class function GetNotebookMinTabHeight(const AWinControl: TWinControl): integer; override;
    class function GetNotebookMinTabWidth(const AWinControl: TWinControl): integer; override;
    class function GetTabIndexAtPos(const ATabControl: TCustomTabControl; const AClientPos: TPoint): integer; override;
    class function GetTabRect(const ATabControl: TCustomTabControl; const AIndex: Integer): TRect; override;
    class procedure SetPageIndex(const ATabControl: TCustomTabControl; const AIndex: integer); override;
    class procedure SetTabCaption(const ATabControl: TCustomTabControl; const AChild: TCustomPage; const AText: string); override;
    class procedure SetTabPosition(const ATabControl: TCustomTabControl; const ATabPosition: TTabPosition); override;
    class procedure SetTabSize(const ATabControl: TCustomTabControl; const ATabWidth, ATabHeight: integer); override;
    class procedure ShowTabs(const ATabControl: TCustomTabControl; AShowTabs: boolean); override;
    class procedure UpdateProperties(const ATabControl: TCustomTabControl); override;
  end;

  { TGtk4WSStatusBar }

  TGtk4WSStatusBar = class(TWSStatusBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure PanelUpdate(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure SetPanelText(const AStatusBar: TStatusBar; PanelIndex: integer); override;
    class procedure Update(const AStatusBar: TStatusBar); override;
    class procedure GetPreferredSize(const {%H-}AWinControl: TWinControl;
                        var {%H-}PreferredWidth, PreferredHeight: integer;
                        {%H-}WithThemeSpace: Boolean); override;

    class procedure SetSizeGrip(const AStatusBar: TStatusBar; {%H-}SizeGrip: Boolean); override;
  end;

  { TGtk4WSTabSheet }

  TGtk4WSTabSheet = class(TWSTabSheet)
  published
  end;

  { TGtk4WSPageControl }

  TGtk4WSPageControl = class(TWSPageControl)
  published
  end;

  { TGtk4WSCustomListView }

  TGtk4WSCustomListView = class(TWSCustomListView)
  private
    class procedure SetPropertyInternal(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean);
  published
    // columns
    class procedure ColumnDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ColumnGetWidth(const ALV: TCustomListView; const {%H-}AIndex: Integer; const AColumn: TListColumn): Integer; override;
    class procedure ColumnInsert(const ALV: TCustomListView; const AIndex: Integer; const AColumn: TListColumn); override;
    class procedure ColumnMove(const ALV: TCustomListView; const AOldIndex, ANewIndex: Integer; const {%H-}AColumn: TListColumn); override;
    class procedure ColumnSetAlignment(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAlignment: TAlignment); override;
    class procedure ColumnSetAutoSize(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AAutoSize: Boolean); override;
    class procedure ColumnSetCaption(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const ACaption: String); override;
    class procedure ColumnSetImage(const ALV: TCustomListView; const {%H-}AIndex: Integer; const {%H-}AColumn: TListColumn; const {%H-}AImageIndex: Integer); override;
    class procedure ColumnSetMaxWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMaxWidth: Integer); override;
    class procedure ColumnSetMinWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AMinWidth: integer); override;
    class procedure ColumnSetWidth(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AWidth: Integer); override;
    class procedure ColumnSetVisible(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AColumn: TListColumn; const AVisible: Boolean); override;
    class procedure ColumnSetSortIndicator(const ALV: TCustomListView; const AIndex: Integer;
      const AColumn: TListColumn; const ASortIndicator: TSortIndicator);override;

    // items
    class procedure ItemDelete(const ALV: TCustomListView; const AIndex: Integer); override;
    class function  ItemDisplayRect(const ALV: TCustomListView; const AIndex, ASubItem: Integer; {%H-}ACode: TDisplayCode): TRect; override;
    class procedure ItemExchange(const ALV: TCustomListView; {%H-}AItem: TListItem; const AIndex1, AIndex2: Integer); override;
    class procedure ItemMove(const ALV: TCustomListView; {%H-}AItem: TListItem; const AFromIndex, AToIndex: Integer); override;
    class function  ItemGetChecked(const {%H-}ALV: TCustomListView; const {%H-}AIndex: Integer; const AItem: TListItem): Boolean; override;
    class function  ItemGetState(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; out AIsSet: Boolean): Boolean; override; // returns True if supported
    class procedure ItemInsert(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem); override;
    class procedure ItemSetChecked(const ALV: TCustomListView; const {%H-}AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}AChecked: Boolean); override;
    class procedure ItemSetImage(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex, AImageIndex: Integer); override;
    class procedure ItemSetState(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const AState: TListItemState; const AIsSet: Boolean); override;
    class procedure ItemSetStateImage(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex, {%H-}AStateImageIndex: Integer); override;
    class procedure ItemSetText(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}ASubIndex: Integer; const {%H-}AText: String); override;
    class procedure ItemShow(const ALV: TCustomListView; const AIndex: Integer; const {%H-}AItem: TListItem; const {%H-}PartialOK: Boolean); override;
    class function  ItemGetPosition(const ALV: TCustomListView; const AIndex: Integer): TPoint; override;
    class procedure ItemUpdate(const ALV: TCustomListView; const {%H-}AIndex: Integer; const {%H-}AItem: TListItem); override;

    // lv
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;

    class procedure BeginUpdate(const ALV: TCustomListView); override;
    class procedure EndUpdate(const ALV: TCustomListView); override;

    class function GetBoundingRect(const ALV: TCustomListView): TRect; override;
    class function GetDropTarget(const ALV: TCustomListView): Integer; override;
    class function GetFocused(const ALV: TCustomListView): Integer; override;
    class function GetHitTestInfoAt(const ALV: TCustomListView; X, Y: Integer): THitTests; override;
    class function GetHoverTime(const ALV: TCustomListView): Integer; override;
    class function GetItemAt(const ALV: TCustomListView; x,y: integer): Integer; override;
    class function GetSelCount(const ALV: TCustomListView): Integer; override;
    class function GetSelection(const ALV: TCustomListView): Integer; override;
    class function GetTopItem(const ALV: TCustomListView): Integer; override;
    class function GetViewOrigin(const ALV: TCustomListView): TPoint; override;
    class function GetVisibleRowCount(const ALV: TCustomListView): Integer; override;

    class procedure SelectAll(const ALV: TCustomListView; const AIsSet: Boolean); override;
    class procedure SetAllocBy(const ALV: TCustomListView; const {%H-}AValue: Integer); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetDefaultItemHeight(const ALV: TCustomListView; const {%H-}AValue: Integer); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetHotTrackStyles(const ALV: TCustomListView; const {%H-}AValue: TListHotTrackStyles); override;
    class procedure SetHoverTime(const ALV: TCustomListView; const {%H-}AValue: Integer); override;
    class procedure SetImageList(const ALV: TCustomListView; const AList: TListViewImageList; const AValue: TCustomImageListResolution); override;
    class procedure SetItemsCount(const ALV: TCustomListView; const {%H-}Avalue: Integer); override;
    class procedure SetProperty(const ALV: TCustomListView; const AProp: TListViewProperty; const AIsSet: Boolean); override;
    class procedure SetProperties(const ALV: TCustomListView; const AProps: TListViewProperties); override;
    class procedure SetScrollBars(const ALV: TCustomListView; const AValue: TScrollStyle); override;
    class procedure SetSort(const ALV: TCustomListView; const {%H-}AType: TSortType; const {%H-}AColumn: Integer;
      const {%H-}ASortDirection: TSortDirection); override;
    class procedure SetIconArrangement(const ALV: TCustomListView; const {%H-}AValue: TIconArrangement); override;
    class procedure SetOwnerData(const ALV: TCustomListView; const {%H-}AValue: Boolean); override;
    class procedure SetViewOrigin(const ALV: TCustomListView; const AValue: TPoint); override;
    class procedure SetViewStyle(const ALV: TCustomListView; const AValue: TViewStyle); override;
    class function RestoreItemCheckedAfterSort(const ALV: TCustomListView): Boolean; override;
  end;

  { TGtk4WSListView }

  TGtk4WSListView = class(TWSListView)
  published
  end;

  { TGtk4WSProgressBar }

  TGtk4WSProgressBar = class(TWSProgressBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure ApplyChanges(const AProgressBar: TCustomProgressBar); override;
    class procedure SetPosition(const AProgressBar: TCustomProgressBar; const NewPosition: integer); override;
    class procedure SetStyle(const AProgressBar: TCustomProgressBar; const NewStyle: TProgressBarStyle); override;
  end;

  { TGtk4WSCustomUpDown }

  TGtk4WSCustomUpDown = class(TWSCustomUpDown)
  published
  end;

  { TGtk4WSUpDown }

  TGtk4WSUpDown = class(TWSUpDown)
  published
  end;

  { TGtk4WSToolButton }

  TGtk4WSToolButton = class(TWSToolButton)
  published
  end;

  { TGtk4WSToolBar }

  TGtk4WSToolBar = class(TWSToolBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TGtk4WSTrackBar }

  TGtk4WSTrackBar = class(TWSTrackBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure ApplyChanges(const ATrackBar: TCustomTrackBar); override;
    class function  GetPosition(const ATrackBar: TCustomTrackBar): integer; override;
    class procedure SetPosition(const ATrackBar: TCustomTrackBar; const NewPosition: integer); override;
    class procedure SetOrientation(const ATrackBar: TCustomTrackBar; const {%H-}AOrientation: TTrackBarOrientation); override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
      var PreferredWidth, PreferredHeight: integer;
      WithThemeSpace: Boolean); override;
  end;

  { TGtk4WSCustomTreeView }

  TGtk4WSCustomTreeView = class(TWSCustomTreeView)
  published
  end;

  { TGtk4WSTreeView }

  TGtk4WSTreeView = class(TWSTreeView)
  published
  end;


implementation
uses gtk4procs, LazGObject2;

{ ---- Pick-based item position helper ---- }

{ Pick the deepest widget at (X, Y) relative to AWidget, then walk up
  the parent chain looking for 'lcl-list-view' metadata stored by factory bind.
  Returns the item position or -1 if no item found. }
function Gtk4_PickItemPosition(AWidget: PGtkWidget; X, Y: Double): Integer;
var
  Picked, Walk: PGtkWidget;
begin
  Result := -1;
  if not AWidget^.get_realized then Exit;
  Picked := gtk4_widget_pick(AWidget, X, Y,
    GTK_PICK_DEFAULT or GTK_PICK_INSENSITIVE or GTK_PICK_NON_TARGETABLE);
  if Picked = nil then Exit;
  Walk := Picked;
  while Walk <> nil do
  begin
    if g_object_get_data(PGObject(Walk), 'lcl-list-view') <> nil then
    begin
      Result := Integer({%H-}PtrUInt(
        g_object_get_data(PGObject(Walk), 'lcl-item-position')));
      Exit;
    end;
    if Walk = AWidget then Break;
    Walk := Walk^.get_parent;
  end;
end;

{ Recursively walk the widget tree starting from AWidget to find a child
  that has 'lcl-item-position' metadata matching APosition.
  Only visits realized/visible widgets (factory-created items for visible rows).
  Returns the matching widget or nil if not found (item not visible). }
function Gtk4_FindItemWidget(AWidget: PGtkWidget; APosition: Integer): PGtkWidget;
var
  Child, Found: PGtkWidget;
begin
  Result := nil;
  if AWidget = nil then Exit;
  { Check if this widget has the metadata }
  if g_object_get_data(PGObject(AWidget), 'lcl-list-view') <> nil then
  begin
    if Integer({%H-}PtrUInt(
      g_object_get_data(PGObject(AWidget), 'lcl-item-position'))) = APosition then
    begin
      Result := AWidget;
      Exit;
    end;
  end;
  { Recurse into children }
  Child := gtk4_widget_get_first_child(AWidget);
  while Child <> nil do
  begin
    Found := Gtk4_FindItemWidget(Child, APosition);
    if Found <> nil then
    begin
      Result := Found;
      Exit;
    end;
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

function Gtk4_FindListItemWidget(AWidget, AContainer: PGtkWidget): PGtkWidget;
var
  Walk: PGtkWidget;
begin
  Result := AWidget;
  Walk := AWidget;
  while (Walk <> nil) and (Walk <> AContainer) do
  begin
    { GtkColumnView/GtkGridView place factory children inside this internal
      per-item widget; its allocation is the row/tile bounds LCL expects. }
    if StrPas(g_type_name(PGTypeInstance(Walk)^.g_class^.g_type)) = 'GtkListItemWidget' then
    begin
      Result := Walk;
      Exit;
    end;
    Walk := Walk^.get_parent;
  end;
end;

function Gtk4_GetWidgetRectInAncestor(AWidget, AAncestor: PGtkWidget;
  out ARect: TRect): Boolean;
var
  Walk, Parent: PGtkWidget;
  Alloc: TGtkAllocation;
  X, Y, W, H: Integer;
begin
  Result := False;
  ARect := Rect(0, 0, 0, 0);
  if (AWidget = nil) or (AAncestor = nil) then Exit;

  Walk := AWidget;
  gtk_widget_get_allocation(Walk, @Alloc);
  X := Alloc.x;
  Y := Alloc.y;
  W := Alloc.width;
  H := Alloc.height;

  while Walk <> AAncestor do
  begin
    Parent := Walk^.get_parent;
    if Parent = nil then Exit;
    if Parent = AAncestor then Break;
    Walk := Parent;
    gtk_widget_get_allocation(Walk, @Alloc);
    Inc(X, Alloc.x);
    Inc(Y, Alloc.y);
  end;

  ARect.Left := X;
  ARect.Top := Y;
  ARect.Right := X + W;
  ARect.Bottom := Y + H;
  Result := True;
end;

{ TGtk4WSTrackBar }

class function TGtk4WSTrackBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  ATrack: TGtk4TrackBar;
begin
  ATrack := TGtk4TrackBar.Create(AWinControl, AParams);
  Result := TLCLHandle(ATrack);
end;

class procedure TGtk4WSTrackBar.ApplyChanges(const ATrackBar: TCustomTrackBar);
var
  ATrack: TGtk4TrackBar;
  APt: TPoint;
begin
  if not WSCheckHandleAllocated(ATrackBar, 'ApplyChanges') then
    Exit;
  ATrack := TGtk4TrackBar(ATrackBar.Handle);
  APt.X := ATrackBar.Min;
  APt.Y := ATrackBar.Max;
  ATrack.BeginUpdate;
  ATrack.Range := APt;
  ATrack.Position:=ATrackBar.Position;
  ATrack.SetStep(ATrackBar.LineSize, ATrackBar.PageSize);
  ATrack.SetScalePos(ATrackBar.ScalePos);
  ATrack.SetTickMarks(ATrackbar.TickMarks, ATrackBar.TickStyle);
  ATrack.Reversed := ATrackBar.Reversed;
  ATrack.EndUpdate;
end;

class function TGtk4WSTrackBar.GetPosition(const ATrackBar: TCustomTrackBar
  ): integer;
begin
  if not WSCheckHandleAllocated(ATrackBar, 'GetPosition') then
    Exit(0);
  Result := TGtk4TrackBar(ATrackBar.Handle).Position;
end;

class procedure TGtk4WSTrackBar.SetPosition(const ATrackBar: TCustomTrackBar;
  const NewPosition: integer);
begin
  if not WSCheckHandleAllocated(ATrackBar, 'SetPosition') then
    Exit;
  TGtk4TrackBar(ATrackBar.Handle).BeginUpdate;
  TGtk4TrackBar(ATrackBar.Handle).Position := NewPosition;
  TGtk4TrackBar(ATrackBar.Handle).EndUpdate;
end;

class procedure TGtk4WSTrackBar.SetOrientation(
  const ATrackBar: TCustomTrackBar; const AOrientation: TTrackBarOrientation);
begin
  if not WSCheckHandleAllocated(ATrackBar, 'SetOrientation') then
    Exit;
  if TGtk4TrackBar(ATrackBar.Handle).GetTrackBarOrientation <> AOrientation then
    RecreateWnd(ATrackBar);
end;

class procedure TGtk4WSTrackBar.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then Exit;
  TGtk4Widget(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

{ TGtk4WSToolBar }

class function TGtk4WSToolBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AToolBar: TGtk4ToolBar;
begin
  AToolBar := TGtk4ToolBar.Create(AWinControl, AParams);
  Result := TLCLHandle(AToolBar);
end;

{ TGtk4WSProgressBar }

class function TGtk4WSProgressBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AProgress: TGtk4ProgressBar;
begin
  AProgress := TGtk4ProgressBar.Create(AWinControl, AParams);
  Result := TLCLHandle(AProgress);
end;

class procedure TGtk4WSProgressBar.ApplyChanges(
  const AProgressBar: TCustomProgressBar);
begin
  if not WSCheckHandleAllocated(AProgressBar, 'ApplyChanges') then
    Exit;
  TGtk4ProgressBar(AProgressBar.Handle).BeginUpdate;
  SetPosition(AProgressBar, AProgressBar.Position);
  SetStyle(AProgressBar, AProgressBar.Style);
  TGtk4ProgressBar(AProgressBar.Handle).ShowText := AProgressBar.BarShowText;
  TGtk4ProgressBar(AProgressBar.Handle).Orientation := AProgressBar.Orientation;
  TGtk4ProgressBar(AProgressBar.Handle).EndUpdate;
end;

class procedure TGtk4WSProgressBar.SetPosition(
  const AProgressBar: TCustomProgressBar; const NewPosition: integer);
begin
  if not WSCheckHandleAllocated(AProgressBar, 'SetPosition') then
    Exit;
  TGtk4ProgressBar(AProgressBar.Handle).BeginUpdate;
  TGtk4ProgressBar(AProgressBar.Handle).Position := NewPosition;
  TGtk4ProgressBar(AProgressBar.Handle).EndUpdate;
end;

class procedure TGtk4WSProgressBar.SetStyle(
  const AProgressBar: TCustomProgressBar; const NewStyle: TProgressBarStyle);
begin
  if not WSCheckHandleAllocated(AProgressBar, 'SetStyle') then
    Exit;
  TGtk4ProgressBar(AProgressBar.Handle).BeginUpdate;
  TGtk4ProgressBar(AProgressBar.Handle).Style := NewStyle;
  TGtk4ProgressBar(AProgressBar.Handle).EndUpdate;
end;

{ TGtk4WSCustomListView }

class function TGtk4WSCustomListView.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AListView: TGtk4ListView;
begin
  AListView := TGtk4ListView.Create(AWinControl, AParams);
  Result := TLCLHandle(AListView);
end;

class procedure TGtk4WSCustomListView.SetPropertyInternal(
  const ALV: TCustomListView; const AProp: TListViewProperty;
  const AIsSet: Boolean);
const
  BoolToSelectionMode: array[Boolean] of TGtkSelectionMode = (
    GTK_SELECTION_SINGLE {1} ,
    GTK_SELECTION_MULTIPLE {3}
  );
begin
  case AProp of
    lvpAutoArrange:
    begin
      { GtkIconView manages layout automatically. No equivalent for TreeView. }
    end;
    lvpCheckboxes:
    begin
      if TListView(ALV).ViewStyle in [vsReport, vsList] then
        TGtk4ListView(ALV.Handle).AddRemoveCheckboxRenderer(AIsSet);
    end;
    lvpColumnClick:
    begin
      // allow only column modifications when in report mode
      if TListView(ALV).ViewStyle <> vsReport then Exit;
      if TGtk4ListView(ALV.Handle).IsColumnView then
        { GtkColumnView does not expose headers_clickable in 4.6 }
      else if TGtk4ListView(ALV.Handle).IsTreeView then
        PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_headers_clickable(AIsSet);
    end;
    lvpFlatScrollBars:
    begin
      { GTK4 scrollbar styling is CSS-only. Not controllable from Pascal. }
    end;
    lvpFullDrag:
    begin
      { No GTK4 equivalent for live column drag rendering during resize. }
    end;
    lvpGridLines:
    begin
      if TGtk4ListView(ALV.Handle).IsColumnView then
      begin
        gtk4_column_view_set_show_row_separators(
          PGtkColumnView(TGtk4ListView(ALV.Handle).GetContainerWidget), AIsSet);
        gtk4_column_view_set_show_column_separators(
          PGtkColumnView(TGtk4ListView(ALV.Handle).GetContainerWidget), AIsSet);
      end
      else if TGtk4ListView(ALV.Handle).IsTreeView then
      begin
        if AIsSet then
          PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_grid_lines(GTK_TREE_VIEW_GRID_LINES_BOTH)
        else
          PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_grid_lines(GTK_TREE_VIEW_GRID_LINES_NONE);
      end;
    end;
    lvpHideSelection:
    begin
      TGtk4ListView(ALV.Handle).HideSelection := AIsSet;
    end;
    lvpHotTrack:
    begin
      if TGtk4ListView(ALV.Handle).IsColumnView then
        { GtkColumnView does not expose hover_selection }
      else if TGtk4ListView(ALV.Handle).IsTreeView then
        PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_hover_selection(AIsSet);
    end;
    lvpMultiSelect:
    begin
      if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
        { GtkColumnView/GtkGridView: switching Single↔Multi selection requires
          widget recreation (selection model type is set at construction). }
        RecreateWnd(ALV)
      else if TGtk4ListView(ALV.Handle).IsTreeView then
        PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.get_selection^.set_mode(BoolToSelectionMode[AIsSet])
      else
        PGtkIconView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_selection_mode(BoolToSelectionMode[AIsSet]);
    end;
    lvpOwnerDraw:
    begin
      { OwnerDraw painting is handled in LCLIntfCellRenderer_Render
        (gtk4cellrenderer.pas). When OwnerDraw=True and ViewStyle=vsReport,
        the cell renderer sends CN_DRAWITEM to the LCL, which invokes
        TCustomListView.DrawItem / OnDrawItem. No action needed here. }
    end;
    lvpReadOnly:
    begin
      { GtkTreeView/GtkIconView CellRenderers are not set to editable,
        so inline editing is not enabled. ReadOnly is effectively always true. }
    end;
    lvpRowSelect:
    begin
      { GtkTreeView always selects entire rows. Cell-level selection is not
        supported by GtkTreeView natively. RowSelect=True is the default. }
    end;
    lvpShowColumnHeaders:
    begin
      // allow only column modifications when in report mode
      if not (TListView(ALV).ViewStyle in [vsList, vsReport]) then Exit;
      if TGtk4ListView(ALV.Handle).IsColumnView then
      begin
        { GtkColumnView 4.6 does not have headers_visible API.
          For vsList mode, headers are already hidden by design. }
      end
      else if TGtk4ListView(ALV.Handle).IsTreeView then
      begin
        PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_headers_visible(AIsSet and (TListView(ALV).ViewStyle = vsReport));
        PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.resize_children;
      end;
    end;
    lvpShowWorkAreas:
    begin
      { Windows-specific concept, not applicable in GTK4. }
    end;
    lvpWrapText:
    begin
      { GtkIconView wraps text by default. Not implemented in GTK2 or Qt5 either. }
    end;
  end;
end;

class procedure TGtk4WSCustomListView.ColumnDelete(const ALV: TCustomListView;
  const AIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnDelete') then
    Exit;
  TGtk4ListView(ALV.Handle).ColumnDelete(AIndex);
end;

class function TGtk4WSCustomListView.ColumnGetWidth(const ALV: TCustomListView;
  const AIndex: Integer; const AColumn: TListColumn): Integer;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnGetWidth') then
    Exit;
  Result := TGtk4ListView(ALV.Handle).ColumnGetWidth(AIndex);
end;

class procedure TGtk4WSCustomListView.ColumnInsert(const ALV: TCustomListView;
  const AIndex: Integer; const AColumn: TListColumn);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnInsert') then
    Exit;
  TGtk4ListView(ALV.Handle).ColumnInsert(AIndex, AColumn);
end;

class procedure TGtk4WSCustomListView.ColumnMove(const ALV: TCustomListView;
  const AOldIndex, ANewIndex: Integer; const AColumn: TListColumn);
var
  ATreeView: PGtkTreeView;
  ACol, APrevCol: PGtkTreeViewColumn;
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnMove') then Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then Exit;
  if not TGtk4ListView(ALV.Handle).IsTreeView then Exit;
  ATreeView := PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget);
  ACol := ATreeView^.get_column(AOldIndex);
  if ACol = nil then Exit;
  if ANewIndex = 0 then
    APrevCol := nil
  else
    APrevCol := ATreeView^.get_column(ANewIndex);
  ATreeView^.move_column_after(ACol, APrevCol);
end;

class procedure TGtk4WSCustomListView.ColumnSetAlignment(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AAlignment: TAlignment);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetAlignment') then
    Exit;
  TGtk4ListView(ALV.Handle).SetAlignment(AIndex, AColumn, AAlignment);
end;

class procedure TGtk4WSCustomListView.ColumnSetAutoSize(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AAutoSize: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetAutoSize') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnAutoSize(AIndex, AColumn, AAutoSize);
end;

class procedure TGtk4WSCustomListView.ColumnSetCaption(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const ACaption: String);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetCaption') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnCaption(AIndex, AColumn, ACaption);
end;

class procedure TGtk4WSCustomListView.ColumnSetImage(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AImageIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetImage') then
    Exit;
  TGtk4ListView(ALV.Handle).ColumnSetImage(AIndex, AImageIndex);
end;

class procedure TGtk4WSCustomListView.ColumnSetMaxWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AMaxWidth: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetMaxWidth') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnMaxWidth(AIndex, AColumn, AMaxWidth);
end;

class procedure TGtk4WSCustomListView.ColumnSetMinWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AMinWidth: integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetMinWidth') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnMinWidth(AIndex, AColumn, AMinWidth);
end;

class procedure TGtk4WSCustomListView.ColumnSetWidth(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AWidth: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetWidth') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnWidth(AIndex, AColumn, AWidth);
end;

class procedure TGtk4WSCustomListView.ColumnSetVisible(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const AVisible: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetVisible') then
    Exit;
  TGtk4ListView(ALV.Handle).SetColumnVisible(AIndex, AColumn, AVisible);
end;

class procedure TGtk4WSCustomListView.ColumnSetSortIndicator(
  const ALV: TCustomListView; const AIndex: Integer;
  const AColumn: TListColumn; const ASortIndicator: TSortIndicator);
begin
  if not WSCheckHandleAllocated(ALV, 'ColumnSetSortIndicator') then
    Exit;

  TGtk4ListView(ALV.Handle).ColumnSetSortIndicator(AIndex,AColumn,ASortIndicator);
end;




type
  TListItemHack = class(TListItem)
  end;

class procedure TGtk4WSCustomListView.ItemDelete(const ALV: TCustomListView;
  const AIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemDelete') then
    Exit;
  TGtk4ListView(ALV.Handle).ItemDelete(AIndex);
end;

class function TGtk4WSCustomListView.ItemDisplayRect(
  const ALV: TCustomListView; const AIndex, ASubItem: Integer;
  ACode: TDisplayCode): TRect;
var
  AWidget: TGtk4ListView;
  APath: PGtkTreePath;
  AColumn: PGtkTreeViewColumn;
  AGdkRect: TGdkRectangle;
  AIdx: gint;
  ItemWidget: PGtkWidget;
begin
  Result := Rect(0, 0, 0, 0);
  if not WSCheckHandleAllocated(ALV, 'ItemDisplayRect') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);

  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    { ColumnView/GridView: walk visible item widgets to find matching position.
      Only works for items currently visible (GTK4 recycles off-screen widgets). }
    if not AWidget.GetContainerWidget^.get_realized then Exit;
    ItemWidget := Gtk4_FindItemWidget(AWidget.GetContainerWidget, AIndex);
    if ItemWidget = nil then Exit;
    ItemWidget := Gtk4_FindListItemWidget(ItemWidget, AWidget.GetContainerWidget);
    Gtk4_GetWidgetRectInAncestor(ItemWidget, AWidget.GetContainerWidget, Result);
    Exit;
  end;

  if not AWidget.IsTreeView then Exit;
  AIdx := AIndex;
  APath := gtk_tree_path_new_from_indicesv(@AIdx, 1);
  if APath = nil then Exit;
  AColumn := nil;
  if ASubItem >= 0 then
    AColumn := PGtkTreeView(AWidget.GetContainerWidget)^.get_column(ASubItem);
  case ACode of
    drBounds, drSelectBounds:
      PGtkTreeView(AWidget.GetContainerWidget)^.get_background_area(APath, AColumn, @AGdkRect);
    drLabel, drIcon:
      PGtkTreeView(AWidget.GetContainerWidget)^.get_cell_area(APath, AColumn, @AGdkRect);
  end;
  gtk_tree_path_free(APath);
  Result.Left := AGdkRect.x;
  Result.Top := AGdkRect.y;
  Result.Right := AGdkRect.x + AGdkRect.width;
  Result.Bottom := AGdkRect.y + AGdkRect.height;
end;

class procedure TGtk4WSCustomListView.ItemExchange(const ALV: TCustomListView;
  AItem: TListItem; const AIndex1, AIndex2: Integer);
var
  AModel: PGtkTreeModel;
  AStore: PGtkListStore;
  AIter1, AIter2: TGtkTreeIter;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemExchange') then Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
  begin
    { GtkStringList holds only placeholders — real data is in TListItem.
      After LCL swaps items, just redraw. }
    TGtk4ListView(ALV.Handle).GetContainerWidget^.queue_draw;
    Exit;
  end;
  if not TGtk4ListView(ALV.Handle).IsTreeView then Exit;
  AModel := PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.get_model;
  if AModel = nil then Exit;
  AStore := PGtkListStore(AModel);
  if AModel^.iter_nth_child(@AIter1, nil, AIndex1) and
     AModel^.iter_nth_child(@AIter2, nil, AIndex2) then
    AStore^.swap(@AIter1, @AIter2);
end;

class procedure TGtk4WSCustomListView.ItemMove(const ALV: TCustomListView;
  AItem: TListItem; const AFromIndex, AToIndex: Integer);
var
  AModel: PGtkTreeModel;
  AStore: PGtkListStore;
  AFromIter, AToIter: TGtkTreeIter;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemMove') then Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
  begin
    { GtkStringList holds only placeholders — real data is in TListItem.
      After LCL moves items, just redraw. }
    TGtk4ListView(ALV.Handle).GetContainerWidget^.queue_draw;
    Exit;
  end;
  if not TGtk4ListView(ALV.Handle).IsTreeView then Exit;
  AModel := PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.get_model;
  if AModel = nil then Exit;
  AStore := PGtkListStore(AModel);
  if not AModel^.iter_nth_child(@AFromIter, nil, AFromIndex) then Exit;
  if AModel^.iter_nth_child(@AToIter, nil, AToIndex) then
  begin
    if AFromIndex < AToIndex then
      AStore^.move_after(@AFromIter, @AToIter)
    else
      AStore^.move_before(@AFromIter, @AToIter);
  end;
end;

class function TGtk4WSCustomListView.ItemGetChecked(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem): Boolean;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemGetChecked') then
    Exit;
  Result := TListItemHack(AItem).GetCheckedInternal;
end;

class function TGtk4WSCustomListView.ItemGetState(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
  out AIsSet: Boolean): Boolean;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemGetState') then
    Exit;
  Result := TGtk4ListView(ALV.Handle).ItemGetState(AIndex, AItem, AState, AIsSet);
end;

class procedure TGtk4WSCustomListView.ItemInsert(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemInsert') then
    Exit;
  TGtk4ListView(ALV.Handle).ItemInsert(AIndex, AItem);
end;

class procedure TGtk4WSCustomListView.ItemSetChecked(
  const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem;
  const AChecked: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetChecked') then
    Exit;
  { The checked state is stored in TListItem. We just need to trigger a
    redraw so the cell data function / factory bind picks up the new value. }
  if TGtk4ListView(ALV.Handle).IsTreeView then
    PGtkWidget(TGtk4ListView(ALV.Handle).GetContainerWidget)^.queue_draw;
end;

class procedure TGtk4WSCustomListView.ItemSetImage(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const ASubIndex,
  AImageIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetImage') then
    Exit;
  TGtk4ListView(ALV.Handle).BeginUpdate;
  TGtk4ListView(ALV.Handle).ItemSetImage(AIndex,ASubIndex, AItem);
  TGtk4ListView(ALV.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomListView.ItemSetState(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const AState: TListItemState;
  const AIsSet: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetState') then
    Exit;
  TGtk4ListView(ALV.Handle).BeginUpdate;
  TGtk4ListView(ALV.Handle).ItemSetState(AIndex, AItem, AState, AIsSet);
  TGtk4ListView(ALV.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomListView.ItemSetStateImage(
  const ALV: TCustomListView; const AIndex: Integer; const AItem: TListItem;
  const ASubIndex, AStateImageIndex: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetStateImage') then Exit;
  { The state image is rendered from AItem.StateIndex during factory bind
    (Gtk4LVItemImageBitmap) when StateImages is assigned — qt5 semantics:
    it occupies the item icon slot. A visible row keeps its bound cell
    widgets until re-bound, so force a rebind of this row (queue_draw is
    not enough — it repaints without re-running the factory bind). }
  TGtk4ListView(ALV.Handle).ItemRebindRow(AIndex);
end;

class procedure TGtk4WSCustomListView.ItemSetText(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const ASubIndex: Integer;
  const AText: String);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemSetText') then
    Exit;
  TGtk4ListView(ALV.Handle).ItemSetText(AIndex, ASubIndex, AItem, AText);
end;

class procedure TGtk4WSCustomListView.ItemShow(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem; const PartialOK: Boolean);
var
  APath: PGtkTreePath;
  AIdx: gint;
  AVAdj: PGtkAdjustment;
  ARowHeight: Double;
  AWidget: TGtk4ListView;
begin
  if not WSCheckHandleAllocated(ALV, 'ItemShow') then Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
  begin
    { GTK 4.6 has no scroll_to for GtkColumnView/GtkGridView.
      Approximate using ScrolledWindow vertical adjustment. }
    AWidget := TGtk4ListView(ALV.Handle);
    AVAdj := AWidget.GetScrolledWindow^.get_vadjustment;
    if AVAdj = nil then Exit;
    ARowHeight := AVAdj^.get_upper / Max(1, ALV.Items.Count);
    AVAdj^.set_value(AIndex * ARowHeight);
    Exit;
  end;
  if not TGtk4ListView(ALV.Handle).IsTreeView then Exit;
  AIdx := AIndex;
  APath := gtk_tree_path_new_from_indicesv(@AIdx, 1);
  if APath = nil then Exit;
  PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.scroll_to_cell(
    APath, nil, False, 0.0, 0.0);
  gtk_tree_path_free(APath);
end;

class function TGtk4WSCustomListView.ItemGetPosition(
  const ALV: TCustomListView; const AIndex: Integer): TPoint;
var
  APath: PGtkTreePath;
  AGdkRect: TGdkRectangle;
  AIdx: gint;
  AWidget: TGtk4ListView;
  AVAdj: PGtkAdjustment;
  ARowHeight: Double;
begin
  Result := Point(0, 0);
  if not WSCheckHandleAllocated(ALV, 'ItemGetPosition') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    { Estimate item position relative to the visible viewport using
      adjustment math. For GridView this is a rough approximation. }
    if ALV.Items.Count = 0 then Exit;
    AVAdj := AWidget.GetScrolledWindow^.get_vadjustment;
    if AVAdj = nil then Exit;
    ARowHeight := AVAdj^.get_upper / Max(1, ALV.Items.Count);
    if ARowHeight <= 0 then Exit;
    Result.X := 0;
    Result.Y := Round(AIndex * ARowHeight - AVAdj^.get_value);
    Exit;
  end;
  if not AWidget.IsTreeView then Exit;
  AIdx := AIndex;
  APath := gtk_tree_path_new_from_indicesv(@AIdx, 1);
  if APath = nil then Exit;
  PGtkTreeView(AWidget.GetContainerWidget)^.get_background_area(
    APath, nil, @AGdkRect);
  gtk_tree_path_free(APath);
  Result.X := AGdkRect.x;
  Result.Y := AGdkRect.y;
end;

class procedure TGtk4WSCustomListView.ItemUpdate(const ALV: TCustomListView;
  const AIndex: Integer; const AItem: TListItem);
begin
  if not WSCheckHandleAllocated(ALV, 'ItemUpdate') then Exit;
  TGtk4ListView(ALV.Handle).UpdateItem(AIndex, AItem);
end;

class procedure TGtk4WSCustomListView.BeginUpdate(const ALV: TCustomListView);
begin
  if not WSCheckHandleAllocated(ALV, 'BeginUpdate') then Exit;
  TGtk4ListView(ALV.Handle).BeginUpdate;
end;

class procedure TGtk4WSCustomListView.EndUpdate(const ALV: TCustomListView);
begin
  if not WSCheckHandleAllocated(ALV, 'EndUpdate') then Exit;
  TGtk4ListView(ALV.Handle).EndUpdate;
end;

class function TGtk4WSCustomListView.GetBoundingRect(const ALV: TCustomListView
  ): TRect;
begin
  Result := Rect(0, 0, 0, 0);
  if not WSCheckHandleAllocated(ALV, 'GetBoundingRect') then Exit;
  Result.Right := TGtk4ListView(ALV.Handle).GetContainerWidget^.get_allocated_width;
  Result.Bottom := TGtk4ListView(ALV.Handle).GetContainerWidget^.get_allocated_height;
end;

class function TGtk4WSCustomListView.GetDropTarget(const ALV: TCustomListView
  ): Integer;
var
  AWidget: TGtk4ListView;
  APath: PGtkTreePath;
  APos: TGtkTreeViewDropPosition;
  AIndices: Pgint;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetDropTarget') then exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then exit;
  if not AWidget.IsTreeView then exit;
  APath := nil;
  PGtkTreeView(AWidget.GetContainerWidget)^.get_drag_dest_row(@APath, @APos);
  if APath <> nil then
  begin
    AIndices := gtk_tree_path_get_indices(APath);
    if AIndices <> nil then
      Result := AIndices^;
    gtk_tree_path_free(APath);
  end;
end;

class function TGtk4WSCustomListView.GetFocused(const ALV: TCustomListView
  ): Integer;
var
  APath: PGtkTreePath;
  ABitset: PGtkBitset;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetFocused') then Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
  begin
    { GTK 4.6 has no cursor/focus API for GtkColumnView/GtkGridView.
      Return first selected item as approximation. }
    ABitset := gtk4_selection_model_get_selection_in_range(
      PGtkSelectionModel(TGtk4ListView(ALV.Handle).SelectionModel),
      0, g_list_model_get_n_items(PGListModel(TGtk4ListView(ALV.Handle).ListModel)));
    if ABitset <> nil then
    begin
      if gtk4_bitset_get_size(ABitset) > 0 then
        Result := Integer(gtk4_bitset_get_minimum(ABitset));
      gtk4_bitset_unref(ABitset);
    end;
    Exit;
  end;
  if not TGtk4ListView(ALV.Handle).IsTreeView then Exit;
  APath := nil;
  PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.get_cursor(@APath, nil);
  if APath <> nil then
  begin
    Result := gtk_tree_path_get_indices(APath)^;
    gtk_tree_path_free(APath);
  end;
end;

class function TGtk4WSCustomListView.GetHoverTime(const ALV: TCustomListView
  ): Integer;
begin
  { Hover time is a Windows-specific concept (LVM_GETHOVERTIME).
    GTK does not expose this value. GTK2 also returns default (-1). }
  Result := -1;
end;

class function TGtk4WSCustomListView.GetItemAt(const ALV: TCustomListView; x,
  y: integer): Integer;
var
  ItemPath: PGtkTreePath;
  Column: PGtkTreeViewColumn;
  AWidget: TGtk4ListView;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetItemAt') then
    Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    { Use gtk4_widget_pick to find the item at (x, y) via stored
      factory metadata ('lcl-list-view' + 'lcl-item-position'). }
    if ALV.Items.Count = 0 then Exit;
    Result := Gtk4_PickItemPosition(AWidget.GetContainerWidget, Double(x), Double(y));
    Exit;
  end
  else if AWidget.IsTreeView then
  begin
    ItemPath := nil;
    Column := nil;
    if PGtkTreeView(AWidget.GetContainerWidget)^.get_path_at_pos(x, y, @ItemPath, @Column, nil, nil) then
    begin
      if ItemPath <> nil then
      begin
        Result := gtk_tree_path_get_indices(ItemPath)^;
        gtk_tree_path_free(ItemPath);
      end;
    end;
  end else
  begin
    ItemPath := PGtkIconView(AWidget.GetContainerWidget)^.get_path_at_pos(x, y);
    if ItemPath <> nil then
    begin
      Result := gtk_tree_path_get_indices(ItemPath)^;
      gtk_tree_path_free(ItemPath);
    end;
  end;
end;

class function TGtk4WSCustomListView.GetSelCount(const ALV: TCustomListView
  ): Integer;
var
  ASelection: PGtkTreeSelection;
  ABitset: PGtkBitset;
  AWidget: TGtk4ListView;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ALV, 'GetSelCount') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    ABitset := gtk4_selection_model_get_selection_in_range(
      PGtkSelectionModel(AWidget.SelectionModel),
      0, g_list_model_get_n_items(PGListModel(AWidget.ListModel)));
    if ABitset <> nil then
    begin
      Result := Integer(gtk4_bitset_get_size(ABitset));
      gtk4_bitset_unref(ABitset);
    end;
    Exit;
  end;
  if not AWidget.IsTreeView then Exit;
  ASelection := PGtkTreeView(AWidget.GetContainerWidget)^.get_selection;
  if ASelection <> nil then
    Result := ASelection^.count_selected_rows;
end;

class function TGtk4WSCustomListView.GetSelection(const ALV: TCustomListView
  ): Integer;
var
  ASelection: PGtkTreeSelection;
  AList: PGList;
  APath: PGtkTreePath;
  ABitset: PGtkBitset;
  AWidget: TGtk4ListView;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ALV, 'GetSelection') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    ABitset := gtk4_selection_model_get_selection_in_range(
      PGtkSelectionModel(AWidget.SelectionModel),
      0, g_list_model_get_n_items(PGListModel(AWidget.ListModel)));
    if ABitset <> nil then
    begin
      if gtk4_bitset_get_size(ABitset) > 0 then
        Result := Integer(gtk4_bitset_get_minimum(ABitset));
      gtk4_bitset_unref(ABitset);
    end;
    Exit;
  end;
  if not AWidget.IsTreeView then Exit;
  ASelection := PGtkTreeView(AWidget.GetContainerWidget)^.get_selection;
  if ASelection = nil then Exit;
  AList := ASelection^.get_selected_rows(nil);
  if AList <> nil then
  begin
    APath := PGtkTreePath(AList^.data);
    if APath <> nil then
      Result := gtk_tree_path_get_indices(APath)^;
    g_list_free_full(AList, TGDestroyNotify(@gtk_tree_path_free));
  end;
end;

class function TGtk4WSCustomListView.GetTopItem(const ALV: TCustomListView
  ): Integer;
var
  AStartPath: PGtkTreePath;
  AWidget: TGtk4ListView;
  AVAdj: PGtkAdjustment;
  ARowHeight: Double;
  AProbeY, APickResult: Integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ALV, 'GetTopItem') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    if ALV.Items.Count = 0 then Exit;
    { Try pick-based detection: probe at x=4 with increasing y to skip header }
    for AProbeY := 0 to 10 do
    begin
      APickResult := Gtk4_PickItemPosition(AWidget.Widget,
        4.0, Double(AProbeY * 4));
      if APickResult >= 0 then
      begin
        Result := APickResult;
        Exit;
      end;
    end;
    { Fallback: adjustment approximation }
    AVAdj := AWidget.GetScrolledWindow^.get_vadjustment;
    if AVAdj = nil then Exit;
    ARowHeight := AVAdj^.get_upper / Max(1, ALV.Items.Count);
    if ARowHeight > 0 then
      Result := Trunc(AVAdj^.get_value / ARowHeight);
    Exit;
  end;
  if not AWidget.IsTreeView then Exit;
  AStartPath := nil;
  if PGtkTreeView(AWidget.GetContainerWidget)^.get_visible_range(@AStartPath, nil) then
  begin
    if AStartPath <> nil then
    begin
      Result := gtk_tree_path_get_indices(AStartPath)^;
      gtk_tree_path_free(AStartPath);
    end;
  end;
end;

class function TGtk4WSCustomListView.GetViewOrigin(const ALV: TCustomListView
  ): TPoint;
var
  AWidget: TGtk4ListView;
  AScrollWin: PGtkScrolledWindow;
  AHAdj, AVAdj: PGtkAdjustment;
begin
  Result := Point(0, 0);
  if not WSCheckHandleAllocated(ALV, 'GetViewOrigin') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  AScrollWin := AWidget.GetScrolledWindow;
  if AScrollWin = nil then Exit;
  AHAdj := AScrollWin^.get_hadjustment;
  AVAdj := AScrollWin^.get_vadjustment;
  if AHAdj <> nil then
    Result.X := Round(AHAdj^.get_value);
  if AVAdj <> nil then
    Result.Y := Round(AVAdj^.get_value);
end;

class function TGtk4WSCustomListView.GetVisibleRowCount(
  const ALV: TCustomListView): Integer;
var
  AStartPath, AEndPath: PGtkTreePath;
  AStartIdx, AEndIdx: Integer;
  AWidget: TGtk4ListView;
  AVAdj: PGtkAdjustment;
  ARowHeight: Double;
  ATopIdx, ABottomIdx, AViewH, AProbeY: Integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ALV, 'GetVisibleRowCount') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    if ALV.Items.Count = 0 then Exit;
    ATopIdx := -1;
    ABottomIdx := -1;
    AViewH := AWidget.Widget^.get_allocated_height;
    { Pick top item }
    for AProbeY := 0 to 10 do
    begin
      ATopIdx := Gtk4_PickItemPosition(AWidget.Widget, 4.0, Double(AProbeY * 4));
      if ATopIdx >= 0 then Break;
    end;
    { Pick bottom item }
    if ATopIdx >= 0 then
    begin
      for AProbeY := 0 to 10 do
      begin
        ABottomIdx := Gtk4_PickItemPosition(AWidget.Widget,
          4.0, Double(AViewH - 1 - AProbeY * 4));
        if ABottomIdx >= 0 then Break;
      end;
    end;
    if (ATopIdx >= 0) and (ABottomIdx >= 0) then
      Result := ABottomIdx - ATopIdx + 1
    else begin
      { Fallback: adjustment approximation }
      AVAdj := AWidget.GetScrolledWindow^.get_vadjustment;
      if AVAdj = nil then Exit;
      ARowHeight := AVAdj^.get_upper / Max(1, ALV.Items.Count);
      if ARowHeight > 0 then
        Result := Min(ALV.Items.Count, Ceil(AVAdj^.get_page_size / ARowHeight));
    end;
    Exit;
  end;
  if not AWidget.IsTreeView then Exit;
  AStartPath := nil;
  AEndPath := nil;
  if PGtkTreeView(AWidget.GetContainerWidget)^.get_visible_range(@AStartPath, @AEndPath) then
  begin
    if (AStartPath <> nil) and (AEndPath <> nil) then
    begin
      AStartIdx := gtk_tree_path_get_indices(AStartPath)^;
      AEndIdx := gtk_tree_path_get_indices(AEndPath)^;
      Result := AEndIdx - AStartIdx + 1;
    end;
    if AStartPath <> nil then gtk_tree_path_free(AStartPath);
    if AEndPath <> nil then gtk_tree_path_free(AEndPath);
  end;
end;

class procedure TGtk4WSCustomListView.SelectAll(const ALV: TCustomListView;
  const AIsSet: Boolean);
var
  AWidget: TGtk4ListView;
begin
  if not WSCheckHandleAllocated(ALV, 'SelectAll') then
    Exit;
  AWidget := TGtk4ListView(ALV.Handle);
  if AWidget.SelectionModel = nil then
    Exit;
  if AIsSet then
    gtk4_selection_model_select_all(PGtkSelectionModel(AWidget.SelectionModel))
  else
    gtk4_selection_model_unselect_all(PGtkSelectionModel(AWidget.SelectionModel));
end;

class procedure TGtk4WSCustomListView.SetAllocBy(const ALV: TCustomListView;
  const AValue: Integer);
begin
end;

class procedure TGtk4WSCustomListView.SetColor(const AWinControl: TWinControl);
begin
  { Background color applied via CSS in TGtk4Widget.SetColor }
  inherited SetColor(AWinControl);
end;

class procedure TGtk4WSCustomListView.SetDefaultItemHeight(
  const ALV: TCustomListView; const AValue: Integer);
begin
  if not WSCheckHandleAllocated(ALV, 'SetDefaultItemHeight') then
    Exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
    { GtkColumnView/GtkGridView does not have fixed_height_mode }
  else if TGtk4ListView(ALV.Handle).IsTreeView then
    PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.set_fixed_height_mode(AValue > 0);
end;

class procedure TGtk4WSCustomListView.SetFont(const AWinControl: TWinControl;
  const AFont: TFont);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetFont') then Exit;
  TGtk4Widget(AWinControl.Handle).SetLclFont(AFont);
end;

class procedure TGtk4WSCustomListView.SetHotTrackStyles(
  const ALV: TCustomListView; const AValue: TListHotTrackStyles);
begin
end;

class procedure TGtk4WSCustomListView.SetHoverTime(const ALV: TCustomListView;
  const AValue: Integer);
begin
end;

class procedure TGtk4WSCustomListView.SetImageList(const ALV: TCustomListView;
  const AList: TListViewImageList; const AValue: TCustomImageListResolution);
var
  AView: TGtk4ListView;
  i: Integer;
  Bmp: TBitmap;
begin
  if not WSCheckHandleAllocated(ALV, 'SetImageList') then
    exit;
  AView := TGtk4ListView(ALV.Handle);
  { State images are accepted for every view style like qt5 (they occupy
    the item icon slot during factory bind — see Gtk4LVItemImageBitmap). }
  if AList = lvilState then
  begin
    if Assigned(AView.StateImages) then
      AView.ClearStateImages
    else
      AView.StateImages := TFPList.Create;
    if Assigned(AValue) then
    begin
      for i := 0 to AValue.Count - 1 do
      begin
        Bmp := TBitmap.Create;
        AValue.GetBitmap(i, Bmp);
        AView.StateImages.Add(Bmp);
      end;
    end;
    { Already-bound rows keep their old pixbufs — queue_draw does not
      re-run the factory bind, so force a rebind of all rows (no-op
      before items exist, e.g. during InitializeWnd). }
    AView.RebindAllRows;
    AView.Update(nil);
    exit;
  end;
  { Route image lists by ViewStyle like gtk2/qt5/win32: only vsIcon uses
    LargeImages; vsSmallIcon, vsReport and vsList use SmallImages. The old
    widget-kind test ("not IsTreeView" accepts lvilLarge) mis-routed
    vsSmallIcon — its GtkGridView is not a tree view, so it consumed
    LargeImages and ignored SmallImages. }
  if ((AList = lvilLarge) and (TListView(ALV).ViewStyle = vsIcon)) or
     ((AList = lvilSmall) and (TListView(ALV).ViewStyle <> vsIcon)) then
  begin
    if Assigned(AView.Images) then
      AView.ClearImages
    else
      AView.Images := TFPList.Create;
    if Assigned(AValue) then
    begin
      for i := 0 to AValue.Count - 1 do
      begin
        Bmp := TBitmap.Create;
        AValue.GetBitmap(i, Bmp);
        AView.Images.Add(Bmp);
      end;
    end;

    if AView.IsTreeView then
      AView.UpdateImageCellsSize;

    AView.Update(nil);
  end;
end;

class procedure TGtk4WSCustomListView.SetItemsCount(const ALV: TCustomListView;
  const Avalue: Integer);
var
  AView: TGtk4ListView;
  AModel: PGtkTreeModel;
  AStore: PGtkListStore;
  Iter: TGtkTreeIter;
  i, ACurCount: Integer;
begin
  if not WSCheckHandleAllocated(ALV, 'SetItemsCount') then Exit;
  AView := TGtk4ListView(ALV.Handle);
  if AView.IsColumnView or AView.IsGridView then
  begin
    { Virtual mode (OwnerData): resize GtkStringList to AValue rows.
      Clear all then add AValue empty placeholder strings. }
    ACurCount := Integer(g_list_model_get_n_items(PGListModel(AView.ListModel)));
    if ACurCount > 0 then
      gtk4_string_list_splice(PGtkStringList(AView.ListModel), 0, ACurCount, nil);
    for i := 0 to AValue - 1 do
      gtk4_string_list_append(PGtkStringList(AView.ListModel), '');
    Exit;
  end;
  if AView.IsTreeView then
    AModel := PGtkTreeView(AView.GetContainerWidget)^.get_model
  else
    AModel := PGtkIconView(AView.GetContainerWidget)^.get_model;
  if AModel = nil then Exit;
  AStore := PGtkListStore(AModel);
  { Virtual mode (OwnerData): clear the store and insert N empty rows.
    Data is provided on demand via OnData callback. }
  gtk_list_store_clear(AStore);
  for i := 0 to AValue - 1 do
    gtk_list_store_insert_with_values(AStore, @Iter, i, [-1]);
end;

class procedure TGtk4WSCustomListView.SetProperty(const ALV: TCustomListView;
  const AProp: TListViewProperty; const AIsSet: Boolean);
begin
  if not WSCheckHandleAllocated(ALV, 'SetProperty') then
    Exit;
  SetPropertyInternal(ALV, AProp, AIsSet);
end;

class procedure TGtk4WSCustomListView.SetProperties(const ALV: TCustomListView;
  const AProps: TListViewProperties);
var
  Prop: TListViewProperty;
begin
  if not WSCheckHandleAllocated(ALV, 'SetProperties') then
    Exit;
  for Prop := Low(Prop) to High(Prop) do
    SetPropertyInternal(ALV, Prop, Prop in AProps);
end;

class procedure TGtk4WSCustomListView.SetScrollBars(const ALV: TCustomListView;
  const AValue: TScrollStyle);
var
  SS: TGtkScrollStyle;
begin
  if not WSCheckHandleAllocated(ALV, 'SetScrollBars') then
    Exit;
  SS := Gtk4TranslateScrollStyle(AValue);
  TGtk4ListView(ALV.Handle).GetScrolledWindow^.set_policy(SS.Horizontal, SS.Vertical);
end;

class procedure TGtk4WSCustomListView.SetSort(const ALV: TCustomListView;
  const AType: TSortType; const AColumn: Integer;
  const ASortDirection: TSortDirection);
begin
  if not WSCheckHandleAllocated(ALV, 'SetSort') then
    Exit;
  { LCL has already sorted FListItems before calling this.
    We must notify the GTK model that items changed so factories rebind. }
  TGtk4ListView(ALV.Handle).ModelNotifyItemsChanged;
end;

class procedure TGtk4WSCustomListView.SetViewOrigin(const ALV: TCustomListView;
  const AValue: TPoint);
begin
  if not WSCheckHandleAllocated(ALV, 'SetViewOrigin') then
    Exit;
  if not TGtk4ListView(ALV.Handle).GetContainerWidget^.get_realized then
    exit;
  if TGtk4ListView(ALV.Handle).IsColumnView or TGtk4ListView(ALV.Handle).IsGridView then
  begin
    { GtkColumnView/GtkGridView has no scroll_to_point. Use ScrolledWindow adjustments. }
    TGtk4ListView(ALV.Handle).GetScrolledWindow^.get_hadjustment^.set_value(AValue.X);
    TGtk4ListView(ALV.Handle).GetScrolledWindow^.get_vadjustment^.set_value(AValue.Y);
  end
  else if TGtk4ListView(ALV.Handle).IsTreeView then
    PGtkTreeView(TGtk4ListView(ALV.Handle).GetContainerWidget)^.scroll_to_point(AValue.X, AValue.Y)
  else
  begin
    { GtkIconView has no scroll_to_point. Use ScrolledWindow adjustments. }
    TGtk4ListView(ALV.Handle).GetScrolledWindow^.get_hadjustment^.set_value(AValue.X);
    TGtk4ListView(ALV.Handle).GetScrolledWindow^.get_vadjustment^.set_value(AValue.Y);
  end;
end;

class procedure TGtk4WSCustomListView.SetViewStyle(const ALV: TCustomListView;
  const AValue: TViewStyle);
begin
  if not WSCheckHandleAllocated(ALV, 'SetViewStyle') then
    Exit;
  { Switching between vsReport (GtkTreeView) and vsIcon/vsSmallIcon (GtkIconView)
    requires widget recreation. The LCL handles this via RecreateWnd. }
  RecreateWnd(ALV);
end;

class function TGtk4WSCustomListView.GetHitTestInfoAt(
  const ALV: TCustomListView; X, Y: Integer): THitTests;
var
  AWidget: TGtk4ListView;
  ItemPath: PGtkTreePath;
  Column: PGtkTreeViewColumn;
  CellX, CellY: gint;
  CellList: PGList;
  PixRenderer: PGtkCellRenderer;
  PixOffset, PixWidth: gint;
begin
  Result := [];
  if not WSCheckHandleAllocated(ALV, 'GetHitTestInfoAt') then Exit;
  AWidget := TGtk4ListView(ALV.Handle);

  if AWidget.IsColumnView or AWidget.IsGridView then
  begin
    { ColumnView/GridView use GTK4 factory widgets, not GtkTreeView cells. }
    if GetItemAt(ALV, X, Y) >= 0 then
      Result := [htOnItem, htOnLabel]
    else
      Result := [htNowhere];
  end
  else if AWidget.IsTreeView then
  begin
    ItemPath := nil;
    Column := nil;
    if PGtkTreeView(AWidget.GetContainerWidget)^.get_path_at_pos(
        X, Y, @ItemPath, @Column, @CellX, @CellY) then
    begin
      if ItemPath <> nil then
      begin
        Include(Result, htOnItem);
        { Determine icon vs label using cell renderer positions }
        if Column <> nil then
        begin
          CellList := PGtkCellLayout(Column)^.get_cells;
          if (CellList <> nil) and (CellList^.data <> nil) then
          begin
            { First renderer is the pixbuf (icon) renderer }
            PixRenderer := PGtkCellRenderer(CellList^.data);
            PixOffset := 0;
            PixWidth := 0;
            if Column^.cell_get_position(PixRenderer, @PixOffset, @PixWidth) and
               (PixWidth > 0) and (CellX >= PixOffset) and (CellX < PixOffset + PixWidth) then
              Include(Result, htOnIcon)
            else
              Include(Result, htOnLabel);
          end
          else
            Include(Result, htOnLabel);
          if CellList <> nil then
            g_list_free(CellList);
        end
        else
          Include(Result, htOnLabel);
        gtk_tree_path_free(ItemPath);
      end
      else
        Include(Result, htNowhere);
    end
    else
      Include(Result, htNowhere);
  end
  else
  begin
    if GetItemAt(ALV, X, Y) >= 0 then
      Result := [htOnItem, htOnLabel]
    else
      Result := [htNowhere];
  end;
end;

class procedure TGtk4WSCustomListView.SetIconArrangement(
  const ALV: TCustomListView; const AValue: TIconArrangement);
begin
  { GTK4: icon arrangement is managed by the GtkGridView/GtkFlowBox layout }
end;

class procedure TGtk4WSCustomListView.SetOwnerData(
  const ALV: TCustomListView; const AValue: Boolean);
begin
  { GTK4: virtual/owner-data mode handled by LCL data callbacks }
end;

class function TGtk4WSCustomListView.RestoreItemCheckedAfterSort(
  const ALV: TCustomListView): Boolean;
begin
  { GTK4: model-based sorting preserves item check state automatically }
  Result := False;
end;

{ TGtk4WSStatusBar }

class function TGtk4WSStatusBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AStatusBar: TGtk4StatusBar;
begin
  AStatusBar := TGtk4StatusBar.Create(AWinControl, AParams);
  Result := TLCLHandle(AStatusBar);
end;

class procedure TGtk4WSStatusBar.PanelUpdate(const AStatusBar: TStatusBar;
  PanelIndex: integer);
var
  AWidget: TGtk4StatusBar;
begin
  if not WSCheckHandleAllocated(AStatusBar, 'PanelUpdate') then Exit;
  AWidget := TGtk4StatusBar(AStatusBar.Handle);
  if PanelIndex >= 0 then
    AWidget.UpdatePanel(PanelIndex)
  else
    AWidget.RecreatePanels;
end;

class procedure TGtk4WSStatusBar.SetPanelText(const AStatusBar: TStatusBar;
  PanelIndex: integer);
var
  AWidget: TGtk4StatusBar;
begin
  if not WSCheckHandleAllocated(AStatusBar, 'SetPanelText') then Exit;
  AWidget := TGtk4StatusBar(AStatusBar.Handle);
  AWidget.UpdatePanel(PanelIndex);
end;

class procedure TGtk4WSStatusBar.Update(const AStatusBar: TStatusBar);
var
  AWidget: TGtk4StatusBar;
begin
  if not WSCheckHandleAllocated(AStatusBar, 'Update') then Exit;
  AWidget := TGtk4StatusBar(AStatusBar.Handle);
  AWidget.RecreatePanels;
end;

class procedure TGtk4WSStatusBar.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then Exit;
  TGtk4Widget(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class procedure TGtk4WSStatusBar.SetSizeGrip(const AStatusBar: TStatusBar;
  SizeGrip: Boolean);
begin
  { GTK4: GtkStatusBar widget removed. Size grip is handled by the
    window manager in GTK4, so this is a no-op. }
end;

{ TGtk4WSCustomTabControl }

class function TGtk4WSCustomTabControl.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
begin
  if AWinControl is TTabControl then
    Result := TLCLHandle(TGtk4CustomControl.Create(AWinControl, AParams))
  else
    Result := TLCLHandle(TGtk4NoteBook.Create(AWinControl, AParams));
end;

class function TGtk4WSCustomTabControl.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
var
  NB: TGtk4NoteBook;
  TabBarChild: PGtkWidget;
  TabBarH: gint;
begin
  Result := True;
  if AWinControl.HandleAllocated and not (AWinControl is TTabControl) then
  begin
    { Measure actual tab bar height from the notebook's first child (GtkBox).
      This properly accounts for theme-specific tab sizes and padding. }
    NB := TGtk4NoteBook(AWinControl.Handle);
    TabBarH := 0;
    TabBarChild := gtk4_widget_get_first_child(NB.GetContainerWidget);
    if (TabBarChild <> nil) and TabBarChild^.get_mapped then
      TabBarH := TabBarChild^.get_allocated_height;
    if TabBarH <= 0 then
      TabBarH := 37; { reasonable default }
    aClientRect := Rect(0, 0, Max(0, aWidth), Max(0, aHeight - TabBarH));
  end else
  begin
    { Handle not allocated — estimate with a default tab bar height }
    aClientRect := Rect(0, 0, Max(0, aWidth), Max(0, aHeight - 37));
  end;
end;

class function TGtk4WSCustomTabControl.GetDesignInteractive(
  const AWinControl: TWinControl; AClientPos: TPoint): Boolean;
var
  TabIndex: Integer;
begin
  Result := False;
  if not WSCheckHandleAllocated(AWinControl, 'GetDesignInteractive') then Exit;
  if AWinControl is TTabControl then Exit;
  TabIndex := GetTabIndexAtPos(TCustomTabControl(AWinControl), AClientPos);
  Result := (TabIndex >= 0) and
    (PGtkNotebook(TGtk4Widget(AWinControl.Handle).GetContainerWidget)^.get_current_page <> TabIndex);
end;

class procedure TGtk4WSCustomTabControl.AddPage(
  const ATabControl: TCustomTabControl; const AChild: TCustomPage;
  const AIndex: integer);
begin
  if not WSCheckHandleAllocated(ATabControl, 'AddPage') then
    Exit;
  // set LCL size
  AChild.SetBounds(AChild.Left, AChild.Top, ATabControl.ClientWidth, ATabControl.ClientHeight);

  if AChild.TabVisible then
    TGtk4Widget(AChild.Handle).Show;

  if ATabControl is TTabControl then
    exit;

  TGtk4Notebook(ATabControl.Handle).InsertPage(AChild, AIndex);
end;

class procedure TGtk4WSCustomTabControl.MovePage(
  const ATabControl: TCustomTabControl; const AChild: TCustomPage;
  const NewIndex: integer);
begin
  if not WSCheckHandleAllocated(ATabControl, 'MovePage') then
    Exit;
  if (ATabControl is TTabControl) then
    exit;
  TGtk4Notebook(ATabControl.Handle).MovePage(AChild, NewIndex);
end;

class procedure TGtk4WSCustomTabControl.RemovePage(
  const ATabControl: TCustomTabControl; const AIndex: integer);
var
  ANotebook: TGtk4Notebook;
  AContainer: PGtkWidget;
  APage: TCustomPage;
  APageWidget: PGtkWidget;
  procedure TraceSkip(const {%H-}AReason: String);
  begin
    {$IFDEF GTK4DEBUGCORE}
    DebugLn(Format('[GTK4-TRACE][WS.RemovePage] SKIP reason=%s tab=%s index=%d pageCount=%d',
      [AReason, dbgsName(ATabControl), AIndex, ATabControl.PageCount]));
    {$ENDIF}
  end;
begin
  APage := nil;
  if not WSCheckHandleAllocated(ATabControl, 'RemovePage') then
  begin
    TraceSkip('no-handle');
    Exit;
  end;
  if csDestroying in ATabControl.ComponentState then
  begin
    TraceSkip('tab-destroying');
    Exit;
  end;
  if csDestroyingHandle in ATabControl.ControlState then
  begin
    TraceSkip('tab-destroying-handle');
    Exit;
  end;
  if Assigned(Application) and Application.Terminated then
  begin
    TraceSkip('app-terminated');
    Exit;
  end;
  if (ATabControl.Owner <> nil) and (csDestroying in ATabControl.Owner.ComponentState) then
  begin
    TraceSkip('owner-destroying');
    Exit;
  end;
  if (ATabControl is TTabControl) then
    exit;
  if (AIndex >= 0) and (AIndex < ATabControl.PageCount) then
  begin
    APage := ATabControl.Page[AIndex];
    if (APage <> nil) and (csDestroying in APage.ComponentState) then
    begin
      TraceSkip('page-destroying');
      Exit;
    end;
    if (APage <> nil) and (csDestroyingHandle in APage.ControlState) then
    begin
      TraceSkip('page-destroying-handle');
      Exit;
    end;
    if (APage <> nil) and APage.HandleAllocated then
      APageWidget := TGtk4Widget(APage.Handle).Widget
    else
      APageWidget := nil;
  end
  else
  begin
    APageWidget := nil;
  end;
  ANotebook := TGtk4Notebook(ATabControl.Handle);
  if ANotebook.IsDestroyingNotebook then
  begin
    TraceSkip('notebook-destroying-flag');
    Exit;
  end;
  AContainer := ANotebook.GetContainerWidget;
  if (AContainer <> nil) and AContainer^.in_destruction then
  begin
    TraceSkip('container-in-destruction');
    Exit;
  end;
  {$IFDEF GTK4DEBUGCORE}
  DebugLn(Format('[GTK4-TRACE][WS.RemovePage] CALL tab=%s index=%d page=%s pageWidget=%p nbWidget=%p container=%p',
    [dbgsName(ATabControl), AIndex, dbgsName(APage), Pointer(APageWidget),
    Pointer(ANotebook.Widget), Pointer(AContainer)]));
  {$ENDIF}
  ANotebook.RemovePage(AIndex, APageWidget);
end;

class function TGtk4WSCustomTabControl.GetCapabilities: TCTabControlCapabilities;
begin
  Result := [nbcShowCloseButtons, nbcMultiLine, nbcPageListPopup, nbcShowAddTabButton];
end;

class function TGtk4WSCustomTabControl.GetNotebookMinTabHeight(
  const AWinControl: TWinControl): integer;
var
  NoteBookWidget: PGtkNotebook;
  PageWidget, TabWidget: PGtkWidget;
  MinH, NatH: gint;
begin
  Result := inherited GetNotebookMinTabHeight(AWinControl);
  if not AWinControl.HandleAllocated then Exit;
  if AWinControl is TTabControl then Exit;
  NoteBookWidget := PGtkNotebook(TGtk4NoteBook(AWinControl.Handle).GetContainerWidget);
  if (NoteBookWidget = nil) or (NoteBookWidget^.get_n_pages = 0) then Exit;
  { Measure the first tab label to get a real minimum height }
  PageWidget := NoteBookWidget^.get_nth_page(0);
  if PageWidget = nil then Exit;
  TabWidget := NoteBookWidget^.get_tab_label(PageWidget);
  if (TabWidget <> nil) and Gtk4IsWidget(TabWidget) then
  begin
    MinH := 0; NatH := 0;
    gtk4_widget_measure(TabWidget, GTK_ORIENTATION_VERTICAL, -1, @MinH, @NatH, nil, nil);
    if NatH > 0 then
      Result := NatH;
  end;
end;

class function TGtk4WSCustomTabControl.GetNotebookMinTabWidth(
  const AWinControl: TWinControl): integer;
var
  NoteBookWidget: PGtkNotebook;
  PageWidget, TabWidget: PGtkWidget;
  MinW, NatW: gint;
begin
  Result := inherited GetNotebookMinTabWidth(AWinControl);
  if not AWinControl.HandleAllocated then Exit;
  if AWinControl is TTabControl then Exit;
  NoteBookWidget := PGtkNotebook(TGtk4NoteBook(AWinControl.Handle).GetContainerWidget);
  if (NoteBookWidget = nil) or (NoteBookWidget^.get_n_pages = 0) then Exit;
  { Measure the first tab label to get a real minimum width }
  PageWidget := NoteBookWidget^.get_nth_page(0);
  if PageWidget = nil then Exit;
  TabWidget := NoteBookWidget^.get_tab_label(PageWidget);
  if (TabWidget <> nil) and Gtk4IsWidget(TabWidget) then
  begin
    MinW := 0; NatW := 0;
    gtk4_widget_measure(TabWidget, GTK_ORIENTATION_HORIZONTAL, -1, @MinW, @NatW, nil, nil);
    if NatW > 0 then
      Result := NatW;
  end;
end;

class function TGtk4WSCustomTabControl.GetTabIndexAtPos(
  const ATabControl: TCustomTabControl; const AClientPos: TPoint): integer;
var
  NoteBookWidget: PGtkNotebook;
  TabWidget, PageWidget: PGtkWidget;
  i, Count: integer;
  Allocation: TGtkAllocation;
  ARect: TRect;
  APos: TPoint;
  TX, TY: gdouble;
begin
  Result:=-1;
  if (ATabControl is TTabControl) then
    exit;
  NoteBookWidget := PGtkNotebook(TGtk4NoteBook(ATabControl.Handle).GetContainerWidget);
  if (NotebookWidget=nil) then exit;

  { AClientPos is in LCL client coordinates (origin below the tab bar —
    see TGtk4NoteBook.GetClientAreaOffset).  Tab label allocations are in
    notebook WIDGET coordinates (tab bar included) — convert before
    comparing. }
  APos := AClientPos;
  with TGtk4NoteBook(ATabControl.Handle).GetClientAreaOffset do
  begin
    Inc(APos.X, X);
    Inc(APos.Y, Y);
  end;

  { GTK4: avoid gtk_container_get_children/g_list APIs for GtkNotebook. }
  Count := NoteBookWidget^.get_n_pages;
  for i := 0 to Count - 1 do
  begin
    PageWidget := NoteBookWidget^.get_nth_page(i);
    if (PageWidget<>nil) and Gtk4IsWidget(PageWidget) then
    begin
      TabWidget := NoteBookWidget^.get_tab_label(PageWidget);
      if (TabWidget <> nil) and Gtk4IsWidget(TabWidget) then
      begin
        { Build the tab rect in notebook WIDGET coordinates the same way
          GetTabRect does: translate the tab label origin to the notebook
          (allocation x/y alone are relative to the internal header box). }
        gtk_widget_get_allocation(TabWidget, @Allocation);
        if gtk4_widget_translate_coordinates(TabWidget,
             PGtkWidget(NoteBookWidget), 0, 0, @TX, @TY) then
          ARect := Rect(Round(TX), Round(TY),
            Round(TX) + Allocation.width, Round(TY) + Allocation.height)
        else
          ARect := RectFromGdkRect(Allocation);
        if PtInRect(ARect, APos) then
        begin
          Result := I;
          break;
        end;
      end;
    end;
  end;
end;

class function TGtk4WSCustomTabControl.GetTabRect(
  const ATabControl: TCustomTabControl; const AIndex: Integer): TRect;
var
  NoteBookWidget: PGtkNotebook;
  TabWidget, PageWidget: PGtkWidget;
  Count: guint;
  Allocation: TGtkAllocation;
  X, Y: gdouble;
  AOffset: TPoint;
begin
  Result := Rect(0, 0, 0, 0);
  if (ATabControl is TTabControl) then
    exit;

  NoteBookWidget := PGtkNotebook(TGtk4NoteBook(ATabControl.Handle).GetContainerWidget);
  if (NotebookWidget=nil) then exit;

  Count := NoteBookWidget^.get_n_pages;
  PageWidget := NoteBookWidget^.get_nth_page(AIndex);
  if (PageWidget = nil) or not Gtk4IsWidget(PageWidget) or (AIndex >= Count) then
    exit;

  TabWidget := NoteBookWidget^.get_tab_label(PageWidget);
  if (TabWidget = nil) or not Gtk4IsWidget(TabWidget) then
    exit;

  gtk_widget_get_allocation(TabWidget, @Allocation);

  { Translate from TabWidget's coordinate space to Notebook's space.
    This handles the internal header hierarchy automatically. }
  if gtk4_widget_translate_coordinates(TabWidget, PGtkWidget(NoteBookWidget),
    0, 0, @X, @Y) then
  begin
    Result := Rect(
      Round(X), Round(Y),
      Round(X) + Allocation.width,
      Round(Y) + Allocation.height);
    { Convert to LCL client coordinates (origin below the tab bar) —
      inverse of the GetTabIndexAtPos input conversion. }
    AOffset := TGtk4NoteBook(ATabControl.Handle).GetClientAreaOffset;
    Types.OffsetRect(Result, -AOffset.X, -AOffset.Y);
  end;
end;

class procedure TGtk4WSCustomTabControl.SetPageIndex(
  const ATabControl: TCustomTabControl; const AIndex: integer);
begin
  if (ATabControl is TTabControl) then
    exit;
  if not WSCheckHandleAllocated(ATabControl, 'SetPageIndex') then
    Exit;
  TGtk4Notebook(ATabControl.Handle).BeginUpdate;
  TGtk4Notebook(ATabControl.Handle).SetPageIndex(AIndex);
  TGtk4Notebook(ATabControl.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomTabControl.SetTabCaption(
  const ATabControl: TCustomTabControl; const AChild: TCustomPage;
  const AText: string);
begin
  if (ATabControl is TTabControl) then
    exit;
  if not WSCheckHandleAllocated(ATabControl, 'SetTabCaption') then
    Exit;
  TGtk4NoteBook(ATabControl.Handle).SetTabLabelText(AChild, AText);
end;

class procedure TGtk4WSCustomTabControl.SetTabPosition(
  const ATabControl: TCustomTabControl; const ATabPosition: TTabPosition);
begin
  if (ATabControl is TTabControl) then
    exit;
  if not WSCheckHandleAllocated(ATabControl, 'SetTabPosition') then
    Exit;
  TGtk4NoteBook(ATabControl.Handle).SetTabPosition(ATabPosition);
end;

class procedure TGtk4WSCustomTabControl.SetTabSize(
  const ATabControl: TCustomTabControl; const ATabWidth, ATabHeight: integer);
var
  CSSProvider: PGtkCssProvider;
  CSSStr: string;
  NB: PGtkWidget;
begin
  if not WSCheckHandleAllocated(ATabControl, 'SetTabSize') then Exit;
  if ATabControl is TTabControl then Exit;
  NB := TGtk4Widget(ATabControl.Handle).GetContainerWidget;
  if NB = nil then Exit;
  CSSProvider := gtk_css_provider_new;
  CSSStr := 'notebook tab {';
  if ATabWidth > 0 then
    CSSStr := CSSStr + ' min-width: ' + IntToStr(ATabWidth) + 'px;';
  if ATabHeight > 0 then
    CSSStr := CSSStr + ' min-height: ' + IntToStr(ATabHeight) + 'px;';
  CSSStr := CSSStr + ' }';
  gtk_css_provider_load_from_data(CSSProvider, PgChar(CSSStr), -1, nil);
  NB^.get_style_context^.add_provider(
    PGtkStyleProvider(CSSProvider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(CSSProvider);
end;

class procedure TGtk4WSCustomTabControl.ShowTabs(
  const ATabControl: TCustomTabControl; AShowTabs: boolean);
begin
  if ATabControl is TTabControl then
    exit;
  if not WSCheckHandleAllocated(ATabControl, 'ShowTabs') then
    Exit;
  TGtk4NoteBook(ATabControl.Handle).SetShowTabs(AShowTabs);
end;

class procedure TGtk4WSCustomTabControl.UpdateProperties(
  const ATabControl: TCustomTabControl);
begin
  if ATabControl is TTabControl then
    exit;
  if not WSCheckHandleAllocated(ATabControl, 'UpdateProperties') then
    Exit;

  if (nboHidePageListPopup in ATabControl.Options) then
    PGtkNotebook(TGtk4NoteBook(ATabControl.Handle).GetContainerWidget)^.popup_disable
  else
    PGtkNotebook(TGtk4NoteBook(ATabControl.Handle).GetContainerWidget)^.popup_enable;
end;


{ TGtk4WSCustomPage }

class function TGtk4WSCustomPage.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4Page.Create(AWinControl, AParams));
end;

class procedure TGtk4WSCustomPage.UpdateProperties(
  const ACustomPage: TCustomPage);
begin
  if not WSCheckHandleAllocated(ACustomPage, 'UpdateProperties') then Exit;
  TGtk4Page(ACustomPage.Handle).UpdateTabImage;
end;

class procedure TGtk4WSCustomPage.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  // ignore lcl bounds
end;

class procedure TGtk4WSCustomPage.SetFont(const AWinControl: TWinControl;
  const AFont: TFont);
var
  Page: TGtk4Page;
  TabLabel: PGtkWidget;
  CssProvider: PGtkCssProvider;
  AContext: PGtkStyleContext;
  CssData: string;
  AColor: TColor;
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetFont') then Exit;
  if AFont = nil then Exit;

  Page := TGtk4Page(AWinControl.Handle);
  TabLabel := PGtkWidget(Page.FPageLabel);
  if TabLabel = nil then
    Exit;

  { Build CSS from TFont properties }
  CssData := '* { ';
  if AFont.Name <> '' then
    CssData := CssData + 'font-family: "' + AFont.Name + '"; ';
  if AFont.Size > 0 then
    CssData := CssData + Format('font-size: %dpt; ', [AFont.Size]);
  if fsBold in AFont.Style then
    CssData := CssData + 'font-weight: bold; '
  else
    CssData := CssData + 'font-weight: normal; ';
  if fsItalic in AFont.Style then
    CssData := CssData + 'font-style: italic; '
  else
    CssData := CssData + 'font-style: normal; ';
  if AFont.Color <> clDefault then
  begin
    AColor := ColorToRGB(AFont.Color);
    CssData := CssData + Format('color: rgb(%d,%d,%d); ',
      [AColor and $FF, (AColor shr 8) and $FF, (AColor shr 16) and $FF]);
  end;
  CssData := CssData + '}';

  { Apply CSS to the tab label widget }
  AContext := TabLabel^.get_style_context;
  if AContext = nil then Exit;
  CssProvider := gtk_css_provider_new;
  AContext^.add_provider(PGtkStyleProvider(CssProvider),
    GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  gtk_css_provider_load_from_data(CssProvider, PGChar(CssData), -1, nil);
  g_object_unref(PGObject(CssProvider));
end;

class procedure TGtk4WSCustomPage.ShowHide(const AWinControl: TWinControl);
begin
  inherited ShowHide(AWinControl);
end;

class function TGtk4WSCustomPage.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
begin
  Result:=false;
  if AWinControl.Parent = nil then exit;
  if AWinControl.HandleAllocated and AWinControl.Parent.HandleAllocated and
    (gtk_widget_get_parent(TGtk4Widget(AWinControl.Handle).Widget) <> nil) then
  begin

  end else
  begin
    Result := True;
    aClientRect := AWinControl.Parent.ClientRect;
  end;
end;

end.
