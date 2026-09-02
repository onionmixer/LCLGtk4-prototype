{
 *****************************************************************************
 *                               Gtk4WSStdCtrls.pp                           *
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
unit Gtk4WSStdCtrls;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// 1) Only class methods allowed
// 2) Class methods have to be published and virtual
// 3) To get as little as posible circles, the uses
//    clause should contain only those LCL units 
//    needed for registration. WSxxx units are OK
// 4) To improve speed, register only classes in the 
//    initialization section which actually 
//    implement something
// 5) To enable your XXX widgetset units, look at
//    the uses clause of the XXXintf.pp
////////////////////////////////////////////////////
uses
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
  Graphics, Controls, StdCtrls, LCLType, LCLProc,
////////////////////////////////////////////////////
  WSLCLClasses, WSControls, WSStdCtrls, WSProc, Classes, Clipbrd,
  gtk4widgets, gtk4procs, gtk4private, LazGtk4, LazGdk4, LazGLib2, LazGio2,
  LazPango1, LazGtk4_Compat;

type
  { TGtk4WSScrollBar }

  TGtk4WSScrollBar = class(TWSScrollBar)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure SetParams(const AScrollBar: TCustomScrollBar); override;
    class procedure SetKind(const AScrollBar: TCustomScrollBar; const AIsHorizontal: Boolean); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;
  TGtk4WSScrollBarClass = class of TGtk4WSScrollBar;

  { TGtk4WSCustomGroupBox }

  TGtk4WSCustomGroupBox = class(TWSCustomGroupBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function GetDefaultClientRect(const AWinControl: TWinControl;
      const {%H-}aLeft, {%H-}aTop, aWidth, aHeight: integer;
      var aClientRect: TRect): boolean; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
  end;

  { TGtk4WSGroupBox }

  TGtk4WSGroupBox = class(TGtk4WSCustomGroupBox)
  published
  end;

  { TGtk4WSCustomComboBox }

  TGtk4WSCustomComboBox = class(TWSCustomComboBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;

    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;

    class function GetDroppedDown(const ACustomComboBox: TCustomComboBox): Boolean; override;
    class function GetSelStart(const ACustomComboBox: TCustomComboBox): integer; override;
    class function GetSelLength(const ACustomComboBox: TCustomComboBox): integer; override;
    class function GetItemIndex(const ACustomComboBox: TCustomComboBox): integer; override;
    class function GetMaxLength(const ACustomComboBox: TCustomComboBox): integer; override;
    
    class procedure SetArrowKeysTraverseList(const ACustomComboBox: TCustomComboBox; 
      NewTraverseList: boolean); override;
    class procedure SetDropDownCount(const ACustomComboBox: TCustomComboBox; NewCount: Integer); override;
    class procedure SetDroppedDown(const ACustomComboBox: TCustomComboBox; ADroppedDown: Boolean); override;
    class procedure SetSelStart(const ACustomComboBox: TCustomComboBox; NewStart: integer); override;
    class procedure SetSelLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;
    class procedure SetItemIndex(const ACustomComboBox: TCustomComboBox; NewIndex: integer); override;
    class procedure SetMaxLength(const ACustomComboBox: TCustomComboBox; NewLength: integer); override;
    class procedure SetStyle(const ACustomComboBox: TCustomComboBox; NewStyle: TComboBoxStyle); override;

    class procedure SetReadOnly(const ACustomComboBox: TCustomComboBox; NewReadOnly: boolean); override;
    class procedure SetTextHint(const ACustomComboBox: TCustomComboBox; const ATextHint: string); override;

    class function  GetItems(const ACustomComboBox: TCustomComboBox): TStrings; override;
    class procedure Sort(const ACustomComboBox: TCustomComboBox; AList: TStrings; IsSorted: boolean); override;

    class function GetItemHeight(const ACustomComboBox: TCustomComboBox): Integer; override;
    class procedure SetItemHeight(const ACustomComboBox: TCustomComboBox; const AItemHeight: Integer); override;
  end;
  TGtk4WSCustomComboBoxClass = class of TGtk4WSCustomComboBox;

  { TGtk4WSComboBox }

  TGtk4WSComboBox = class(TGtk4WSCustomComboBox)
  published
  end;

  { TGtk4WSCustomListBox }

  TGtk4WSCustomListBox = class(TWSCustomListBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class function GetIndexAtXY(const ACustomListBox: TCustomListBox; X, Y: integer): integer; override;
    class function GetItemIndex(const ACustomListBox: TCustomListBox): integer; override;
    class function GetItemRect(const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect): boolean; override;
    class function GetScrollWidth(const ACustomListBox: TCustomListBox): Integer; override;
    class function GetSelCount(const ACustomListBox: TCustomListBox): integer; override;
    class function GetSelected(const ACustomListBox: TCustomListBox; const AIndex: integer): boolean; override;
    class function GetStrings(const ACustomListBox: TCustomListBox): TStrings; override;
    class function GetTopIndex(const ACustomListBox: TCustomListBox): integer; override;

    class procedure SelectItem(const ACustomListBox: TCustomListBox; AIndex: integer; ASelected: boolean); override;

    class procedure SetBorder(const ACustomListBox: TCustomListBox); override;
    class procedure SetColumnCount(const ACustomListBox: TCustomListBox; ACount: Integer); override;
    class procedure SetItemIndex(const ACustomListBox: TCustomListBox; const AIndex: integer); override;
    class procedure SetScrollWidth(const ACustomListBox: TCustomListBox; const AScrollWidth: Integer); override;
    class procedure SetSelectionMode(const ACustomListBox: TCustomListBox; const AExtendedSelect, 
      AMultiSelect: boolean); override;
    class procedure SetStyle(const ACustomListBox: TCustomListBox); override;
    class procedure SetSorted(const ACustomListBox: TCustomListBox; AList: TStrings; ASorted: boolean); override;
    class procedure SetTopIndex(const ACustomListBox: TCustomListBox; const NewTopIndex: integer); override;
  end;
  TGtk4WSCustomListBoxClass = class of TGtk4WSCustomListBox;
  
  { TWSListBox }

  TGtk4WSListBox = class(TGtk4WSCustomListBox)
  published
  end;

  { TGtk4WSCustomEdit }

  TGtk4WSCustomEdit = class(TWSCustomEdit)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;

    class function GetCanUndo(const ACustomEdit: TCustomEdit): Boolean; override;
    class function GetCaretPos(const ACustomEdit: TCustomEdit): TPoint; override;
    class function GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    class procedure SetAlignment(const ACustomEdit: TCustomEdit; const AAlignment: TAlignment); override;
    class procedure SetCaretPos(const ACustomEdit: TCustomEdit; const NewPos: TPoint); override;
    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); override;
    class procedure SetHideSelection(const ACustomEdit: TCustomEdit; NewHideSelection: Boolean); override;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetNumbersOnly(const ACustomEdit: TCustomEdit; NewNumbersOnly: Boolean); override;
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetTextHint(const ACustomEdit: TCustomEdit; const ATextHint: string); override;

    class procedure Cut(const ACustomEdit: TCustomEdit); override;
    class procedure Copy(const ACustomEdit: TCustomEdit); override;
    class procedure Paste(const ACustomEdit: TCustomEdit); override;
    class procedure SetBorderStyle(const AWinControl: TWinControl; const ABorderStyle: TBorderStyle); override;

    class procedure Undo(const ACustomEdit: TCustomEdit); override;
  end;
  TGtk4WSCustomEditClass = class of TGtk4WSCustomEdit;

  { TGtk4WSCustomMemo }

  TGtk4WSCustomMemo = class(TWSCustomMemo)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure AppendText(const ACustomMemo: TCustomMemo; const AText: string); override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;

    class function GetStrings(const ACustomMemo: TCustomMemo): TStrings; override;
    class procedure SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle); override;
    class procedure SetWantTabs(const ACustomMemo: TCustomMemo; const NewWantTabs: boolean); override;
    class procedure SetWantReturns(const ACustomMemo: TCustomMemo; const NewWantReturns: boolean); override;
    class procedure SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean); override;

    class function GetCanUndo(const ACustomEdit: TCustomEdit): Boolean; override;
    class function GetCaretPos(const ACustomEdit: TCustomEdit): TPoint; override;
    class function GetSelStart(const ACustomEdit: TCustomEdit): integer; override;
    class function GetSelLength(const ACustomEdit: TCustomEdit): integer; override;

    class procedure SetAlignment(const ACustomEdit: TCustomEdit; const AAlignment: TAlignment); override;
    class procedure SetCaretPos(const ACustomEdit: TCustomEdit; const NewPos: TPoint); override;
    class procedure SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase); override;
    class procedure SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode); override;
    class procedure SetHideSelection(const ACustomEdit: TCustomEdit; NewHideSelection: Boolean); override;
    class procedure SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;
    class procedure SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char); override;
    class procedure SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean); override;
    class procedure SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer); override;
    class procedure SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer); override;

    class procedure Undo(const ACustomEdit: TCustomEdit); override;

  end;
  TGtk4WSCustomMemoClass = class of TGtk4WSCustomMemo;

  { TGtk4WSEdit }

  TGtk4WSEdit = class(TGtk4WSCustomEdit)
  published
  end;

  { TGtk4WSMemo }

  TGtk4WSMemo = class(TGtk4WSCustomMemo)
  published
  end;

  { TGtk4WSCustomStaticText }

  TGtk4WSCustomStaticText = class(TWSCustomStaticText)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class procedure SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment); override;
    class procedure SetStaticBorderStyle(const ACustomStaticText: TCustomStaticText; const NewBorderStyle: TStaticBorderStyle); override;
  end;
  TGtk4WSCustomStaticTextClass = class of TGtk4WSCustomStaticText;

  { TGtk4WSStaticText }

  TGtk4WSStaticText = class(TGtk4WSCustomStaticText)
  published
  end;

  { TGtk4WSButtonControl }

  TGtk4WSButtonControl = class(TWSButtonControl)
  published
    class function GetDefaultColor(const AControl: TControl; const ADefaultColorType: TDefaultColorType): TColor; override;
  end;

  { TGtk4WSButton }

  TGtk4WSButton = class(TWSButton)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class procedure SetDefault(const AButton: TCustomButton; ADefault: Boolean); override;
    class procedure SetShortCut(const AButton: TCustomButton; const ShortCutK1, ShortCutK2: TShortCut); override;
  end;
  TGtk4WSButtonClass = class of TGtk4WSButton;

  { TGtk4WSCustomCheckBox }

  TGtk4WSCustomCheckBox = class(TWSCustomCheckBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class function RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; override;
    class procedure SetAlignment(const ACustomCheckBox: TCustomCheckBox; const NewAlignment: TLeftRight); override;
    class procedure SetShortCut(const ACustomCheckBox: TCustomCheckBox; const ShortCutK1, ShortCutK2: TShortCut); override;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
  end;
  TGtk4WSCustomCheckBoxClass = class of TGtk4WSCustomCheckBox;

  { TGtk4WSCheckBox }

  TGtk4WSCheckBox = class(TGtk4WSCustomCheckBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
  end;

  { TWSToggleBox }

  { TGtk4WSToggleBox }

  TGtk4WSToggleBox = class(TGtk4WSCustomCheckBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl;
                        var PreferredWidth, PreferredHeight: integer;
                        WithThemeSpace: Boolean); override;
    class function RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState; override;
    class procedure SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState); override;
  end;

  { TGtk4WSRadioButton }

  TGtk4WSRadioButton = class(TGtk4WSCustomCheckBox)
  published
    class function CreateHandle(const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle; override;
  end;

implementation

uses
  SysUtils, Math, LResources, LazGObject2, Menus, Gtk4WSControls;

const
  LCL_SHORTCUT_CONTROLLER_KEY = 'lcl-shortcut-ctl';
  GTK4_ENABLE_WIDGET_SHORTCUTS = False;

function Gtk4ShortcutActivateActionCB(widget: PGtkWidget; args: Pointer;
  user_data: gpointer): gboolean; cdecl;
begin
  if args <> nil then ;
  if user_data <> nil then ;
  if widget = nil then
    Exit(False);
  Result := gtk_widget_activate(widget);
end;

{ Helper: Set GtkShortcutController on a widget for TShortCut values.
  Replaces any previously set LCL shortcut controller on the widget.
  Uses GTK_SHORTCUT_SCOPE_MANAGED so the shortcut works when any widget
  in the same window has focus. Uses gtk_activate_action to trigger
  the widget's activate signal (clicks the button / toggles the checkbox). }
procedure Gtk4SetWidgetShortCut(AWidget: PGtkWidget; AShortCut1, AShortCut2: TShortCut);
var
  AController: PGtkEventController;
  AKey: Word;
  AShift: TShiftState;
  AKeyval: guint;
  AMods: TGdkModifierType;
  ATrigger: PGtkShortcutTrigger;
  AShortcut: PGtkShortcut;
  AOldCtl: PGtkEventController;
  AAction: PGtkShortcutAction;

  function CreateActivateAction: PGtkShortcutAction; inline;
  begin
    { Do not use gtk_activate_action_get() singleton here:
      gtk_shortcut_new() takes ownership of the action and may finalize it,
      which can trigger GTK aborts for singleton activate action objects. }
    Result := gtk4_callback_action_new(@Gtk4ShortcutActivateActionCB, nil, nil);
  end;
begin
  if AWidget = nil then Exit;
  if not Gtk4IsObject(PGObject(AWidget)) then Exit;

  { Remove any previous LCL shortcut controller from this widget }
  AOldCtl := PGtkEventController(g_object_get_data(PGObject(AWidget), LCL_SHORTCUT_CONTROLLER_KEY));
  if (AOldCtl <> nil) and Gtk4IsObject(PGObject(AOldCtl)) then
  begin
    gtk4_widget_remove_controller(AWidget, AOldCtl);
    g_object_set_data(PGObject(AWidget), LCL_SHORTCUT_CONTROLLER_KEY, nil);
  end;

  if (AShortCut1 = 0) and (AShortCut2 = 0) then Exit;
  if not GTK4_ENABLE_WIDGET_SHORTCUTS then Exit;

  AController := gtk4_shortcut_controller_new;
  gtk4_shortcut_controller_set_scope(PGtkShortcutController(AController),
    GTK_SHORTCUT_SCOPE_MANAGED);

  if AShortCut1 <> 0 then
  begin
    ShortCutToKey(AShortCut1, AKey, AShift);
    AKeyval := LCLKeyToGdkKeyval(AKey);
    AMods := ShiftStateToGdkMods(AShift);
    if AKeyval <> 0 then
    begin
      AAction := CreateActivateAction;
      if AAction = nil then
        Exit;
      ATrigger := gtk4_keyval_trigger_new(AKeyval, AMods);
      AShortcut := gtk4_shortcut_new(ATrigger, AAction);
      gtk4_shortcut_controller_add_shortcut(PGtkShortcutController(AController), AShortcut);
    end;
  end;

  if AShortCut2 <> 0 then
  begin
    ShortCutToKey(AShortCut2, AKey, AShift);
    AKeyval := LCLKeyToGdkKeyval(AKey);
    AMods := ShiftStateToGdkMods(AShift);
    if AKeyval <> 0 then
    begin
      AAction := CreateActivateAction;
      if AAction = nil then
        Exit;
      ATrigger := gtk4_keyval_trigger_new(AKeyval, AMods);
      AShortcut := gtk4_shortcut_new(ATrigger, AAction);
      gtk4_shortcut_controller_add_shortcut(PGtkShortcutController(AController), AShortcut);
    end;
  end;

  gtk4_widget_add_controller(AWidget, AController);
  g_object_set_data(PGObject(AWidget), LCL_SHORTCUT_CONTROLLER_KEY, AController);
end;

{ TGtk4WSCustomGroupBox }

class function TGtk4WSCustomGroupBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AGroupBox: TGtk4GroupBox;
begin
  AGroupBox := TGtk4GroupBox.Create(AWinControl, AParams);
  Result := TLCLHandle(AGroupBox);
end;

class function TGtk4WSCustomGroupBox.GetDefaultClientRect(
  const AWinControl: TWinControl; const aLeft, aTop, aWidth, aHeight: integer;
  var aClientRect: TRect): boolean;
const
  cGroupBoxTopMargin = 20;  { approximate title label height }
  cGroupBoxPadding = 2;
begin
  Result := False;
  if AWinControl.HandleAllocated then Exit;
  aClientRect := Rect(cGroupBoxPadding, cGroupBoxTopMargin,
    Max(0, aWidth - cGroupBoxPadding * 2),
    Max(0, aHeight - cGroupBoxTopMargin - cGroupBoxPadding));
  Result := True;
end;

class procedure TGtk4WSCustomGroupBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4GroupBox(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

{ TGtk4WSRadioButton }

class function TGtk4WSRadioButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  ARadioButton: TGtk4RadioButton;
begin
  ARadioButton := TGtk4RadioButton.Create(AWinControl, AParams);
  Result := TLCLHandle(ARadioButton);
end;

{ TGtk4WSToggleBox }

class function TGtk4WSToggleBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AToggleBox: TGtk4ToggleButton;
begin
  AToggleBox := TGtk4ToggleButton.Create(AWinControl, AParams);
  Result := TLCLHandle(AToggleBox);
end;

class procedure TGtk4WSToggleBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  { TGtk4ToggleButton is a TGtk4Button, not a TGtk4CheckBox }
  TGtk4ToggleButton(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSToggleBox.RetrieveState(
  const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
begin
  Result := cbUnchecked;
  if not WSCheckHandleAllocated(ACustomCheckBox, 'RetrieveState') then
    Exit;
  { TGtk4ToggleButton uses GtkToggleButton, not GtkCheckButton.
    GtkToggleButton has no inconsistent/grayed state. }
  if gtk_toggle_button_get_active(PGtkToggleButton(
       TGtk4Widget(ACustomCheckBox.Handle).Widget)) then
    Result := cbChecked;
end;

class procedure TGtk4WSToggleBox.SetState(
  const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
begin
  if not WSCheckHandleAllocated(ACustomCheckBox, 'SetState') then
    Exit;
  { TGtk4ToggleButton uses GtkToggleButton, not GtkCheckButton.
    Map cbGrayed to checked (GtkToggleButton has no tri-state). }
  gtk_toggle_button_set_active(PGtkToggleButton(
    TGtk4Widget(ACustomCheckBox.Handle).Widget), NewState <> cbUnchecked);
end;

{ TGtk4WSCheckBox }

class function TGtk4WSCheckBox.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  ACheckBox: TGtk4CheckBox;
begin
  ACheckBox := TGtk4CheckBox.Create(AWinControl, AParams);
  Result := TLCLHandle(ACheckBox);
end;

{ TGtk4WSScrollBar }

class function TGtk4WSScrollBar.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AGtkScrollbar: TGtk4ScrollBar;
begin
  AGtkScrollBar := TGtk4ScrollBar.Create(AWinControl, AParams);
  Result:= TLCLHandle(AGtkScrollBar);
end;

class procedure TGtk4WSScrollBar.SetParams(const AScrollBar: TCustomScrollBar);
begin
  if not WSCheckHandleAllocated(AScrollBar, 'SetParams') then
    Exit;
  TGtk4ScrollBar(AScrollBar.Handle).BeginUpdate;
  TGtk4ScrollBar(AScrollBar.Handle).SetParams;
  TGtk4ScrollBar(AScrollBar.Handle).EndUpdate;
end;

class procedure TGtk4WSScrollBar.SetKind(const AScrollBar: TCustomScrollBar;
  const AIsHorizontal: Boolean);
begin
  if not WSCheckHandleAllocated(AScrollBar, 'SetKind') then
    Exit;
  RecreateWnd(AScrollBar);
end;

class procedure TGtk4WSScrollBar.ShowHide(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then Exit;
  { Reapply params before showing — slider may be stale }
  if AWinControl.HandleObjectShouldBeVisible then
    SetParams(TCustomScrollBar(AWinControl));
  TGtk4WSWinControl.ShowHide(AWinControl);
end;

{ TGtk4WSCustomListBox }

class function TGtk4WSCustomListBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AListBox: TGtk4ListBox;
begin
  AListBox := TGtk4ListBox.Create(AWinControl, AParams);
  AListBox.BorderStyle := TCustomListBox(AWinControl).BorderStyle;
  AListBox.MultiSelect := TCustomListBox(AWinControl).MultiSelect;
  Result := TLCLHandle(AListBox);
end;

class function TGtk4WSCustomListBox.GetIndexAtXY(
  const ACustomListBox: TCustomListBox; X, Y: integer): integer;
var
  AWidget: TGtk4ListBox;
  Adj: PGtkAdjustment;
  NItems, NRows: guint;
  RowH, ColW: Double;
  Cols, ARow, ACol: Integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetIndexAtXY') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  Adj := PGtkScrolledWindow(AWidget.Widget)^.get_vadjustment;
  NItems := g_list_model_get_n_items(PGListModel(AWidget.ListModel));
  if AWidget.IsGridView then
  begin
    { Row-major grid: index = row*Cols + col. }
    Cols := AWidget.GridColumns;
    if (Adj = nil) or (NItems = 0) or (Cols <= 0) then Exit;
    NRows := (NItems + guint(Cols) - 1) div guint(Cols);
    if NRows = 0 then Exit;
    RowH := Adj^.get_upper / NRows;
    ColW := AWidget.GetContainerWidget^.get_allocated_width / Cols;
    if (RowH <= 0) or (ColW <= 0) then Exit;
    ARow := Trunc((Y + Adj^.get_value) / RowH);
    ACol := Trunc(X / ColW);
    if ACol < 0 then ACol := 0;
    if ACol >= Cols then ACol := Cols - 1;
    Result := ARow * Cols + ACol;
    if (Result < 0) or (guint(Result) >= NItems) then
      Result := -1;
  end
  else if AWidget.IsListView then
  begin
    { Approximate: Y + scroll offset / row height }
    if (Adj = nil) or (NItems = 0) then Exit;
    RowH := Adj^.get_upper / NItems;
    if RowH <= 0 then Exit;
    Result := Trunc((Y + Adj^.get_value) / RowH);
    if (Result < 0) or (guint(Result) >= NItems) then
      Result := -1;
  end;
end;

class function  TGtk4WSCustomListBox.GetItemIndex(const ACustomListBox: TCustomListBox): integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetItemIndex') then
    Exit;
  Result := TGtk4ListBox(ACustomListBox.Handle).ItemIndex;
end;

class function TGtk4WSCustomListBox.GetItemRect(
  const ACustomListBox: TCustomListBox; Index: integer; var ARect: TRect
  ): boolean;
var
  AWidget: TGtk4ListBox;
  Adj: PGtkAdjustment;
  NItems, NRows: guint;
  RowH, ColW: Double;
  W, Cols, ARow, ACol: Integer;
begin
  FillChar(ARect, SizeOf(ARect), 0);
  Result := False;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetItemRect') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  Adj := PGtkScrolledWindow(AWidget.Widget)^.get_vadjustment;
  NItems := g_list_model_get_n_items(PGListModel(AWidget.ListModel));
  if AWidget.IsGridView then
  begin
    Cols := AWidget.GridColumns;
    if (Adj = nil) or (NItems = 0) or (Cols <= 0) then Exit;
    NRows := (NItems + guint(Cols) - 1) div guint(Cols);
    if NRows = 0 then Exit;
    RowH := Adj^.get_upper / NRows;
    ColW := AWidget.GetContainerWidget^.get_allocated_width / Cols;
    ARow := Index div Cols;
    ACol := Index mod Cols;
    ARect.Left := Round(ACol * ColW);
    ARect.Top := Round(ARow * RowH - Adj^.get_value);
    ARect.Right := ARect.Left + Round(ColW);
    ARect.Bottom := ARect.Top + Round(RowH);
    Result := True;
  end
  else if AWidget.IsListView then
  begin
    if (Adj = nil) or (NItems = 0) then Exit;
    RowH := Adj^.get_upper / NItems;
    W := AWidget.GetContainerWidget^.get_allocated_width;
    ARect.Left := 0;
    ARect.Top := Round(Index * RowH - Adj^.get_value);
    ARect.Right := W;
    ARect.Bottom := ARect.Top + Round(RowH);
    Result := True;
  end;
end;

class function TGtk4WSCustomListBox.GetScrollWidth(
  const ACustomListBox: TCustomListBox): Integer;
var
  AWidget: TGtk4ListBox;
  MinW, NatW: gint;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetScrollWidth') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  { Return natural width of the inner ListView (content width) }
  if AWidget.GetContainerWidget <> nil then
  begin
    gtk4_widget_measure(AWidget.GetContainerWidget, GTK_ORIENTATION_HORIZONTAL,
      -1, @MinW, @NatW, nil, nil);
    Result := NatW;
  end
  else
    Result := AWidget.Widget^.get_allocated_width;
end;

class function  TGtk4WSCustomListBox.GetSelCount(const ACustomListBox: TCustomListBox): integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetSelCount') then
    Exit;
  Result := TGtk4ListBox(ACustomListBox.Handle).GetSelCount;
end;

class function  TGtk4WSCustomListBox.GetSelected(const ACustomListBox: TCustomListBox; const AIndex: integer): boolean;
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'GetSelected') then
    Exit(False);
  Result := TGtk4ListBox(ACustomListBox.Handle).GetItemSelected(AIndex);
end;

class function TGtk4WSCustomListBox.GetStrings(const ACustomListBox: TCustomListBox): TStrings;
var
  AWidget: TGtk4ListBox;
begin
  Result := nil;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetStrings') then
    Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  if AWidget.IsListView then
  begin
    Result := TGtkStringListStrings(g_object_get_data(
      PGObject(AWidget.GetContainerWidget), GtkListItemLCLListTag));
    TGtkStringListStrings(Result).Sorted := ACustomListBox.Sorted;
  end;
end;

class function  TGtk4WSCustomListBox.GetTopIndex(const ACustomListBox: TCustomListBox): integer;
var
  AWidget: TGtk4ListBox;
  Adj: PGtkAdjustment;
  NItems, NRows: guint;
  RowH: Double;
  Cols: Integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomListBox, 'GetTopIndex') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  Adj := PGtkScrolledWindow(AWidget.Widget)^.get_vadjustment;
  NItems := g_list_model_get_n_items(PGListModel(AWidget.ListModel));
  if AWidget.IsGridView then
  begin
    Cols := AWidget.GridColumns;
    if (Adj = nil) or (NItems = 0) or (Cols <= 0) then Exit;
    NRows := (NItems + guint(Cols) - 1) div guint(Cols);
    if NRows = 0 then Exit;
    RowH := Adj^.get_upper / NRows;
    if RowH > 0 then
      Result := Trunc(Adj^.get_value / RowH) * Cols;  { first item of the top row }
  end
  else if AWidget.IsListView then
  begin
    if (Adj = nil) or (NItems = 0) then Exit;
    RowH := Adj^.get_upper / NItems;
    if RowH > 0 then
      Result := Trunc(Adj^.get_value / RowH);
  end;
end;

class procedure TGtk4WSCustomListBox.SelectItem(const ACustomListBox: TCustomListBox; AIndex: integer; ASelected: boolean);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SelectItem') then
    Exit;
  TGtk4ListBox(ACustomListBox.Handle).BeginUpdate;
  TGtk4ListBox(ACustomListBox.Handle).SelectItem(AIndex, ASelected);
  TGtk4ListBox(ACustomListBox.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomListBox.SetBorder(const ACustomListBox: TCustomListBox);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetBorder') then Exit;
  TGtk4ListBox(ACustomListBox.Handle).BorderStyle := ACustomListBox.BorderStyle;
end;

class procedure TGtk4WSCustomListBox.SetColumnCount(const ACustomListBox: TCustomListBox;
  ACount: Integer);
var
  AWidget: TGtk4ListBox;
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetColumnCount') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  { Columns>0 uses GtkGridView (multi-column), Columns=0 uses GtkListView — two
    different widgets — and the grid's column count is fixed at min=max. Recreate
    the handle on any change that affects the widget kind or its column count;
    CreateWidget re-reads TListBox.Columns and rebuilds the correct widget. The
    common (design-time) case is set before handle allocation, so this only runs
    for genuine runtime Columns changes. }
  if ((ACount > 0) <> AWidget.IsGridView) or
     (AWidget.IsGridView and (ACount <> AWidget.GridColumns)) then
    RecreateWnd(ACustomListBox);
end;

class procedure TGtk4WSCustomListBox.SetItemIndex(const ACustomListBox: TCustomListBox; const AIndex: integer);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetItemIndex') then
    Exit;
  TGtk4ListBox(ACustomListBox.Handle).BeginUpdate;
  TGtk4ListBox(ACustomListBox.Handle).ItemIndex := AIndex;
  TGtk4ListBox(ACustomListBox.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomListBox.SetScrollWidth(
  const ACustomListBox: TCustomListBox; const AScrollWidth: Integer);
var
  AWidget: TGtk4ListBox;
  ScrollWin: PGtkScrolledWindow;
  ClientWidth: Integer;
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetScrollWidth') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  ScrollWin := AWidget.GetScrolledWindow;
  if ScrollWin = nil then Exit;
  ClientWidth := PGtkWidget(ScrollWin)^.get_allocated_width;
  if AScrollWidth > ClientWidth then
    ScrollWin^.set_policy(GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC)
  else
    ScrollWin^.set_policy(GTK_POLICY_NEVER, GTK_POLICY_AUTOMATIC);
end;

class procedure TGtk4WSCustomListBox.SetSelectionMode(const ACustomListBox: TCustomListBox;
  const AExtendedSelect, AMultiSelect: boolean);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetSelectionMode') then
    Exit;
  { GtkListView: selection model type is determined at creation,
    so changing multiselect requires RecreateWnd }
  if TGtk4ListBox(ACustomListBox.Handle).IsListView then
    RecreateWnd(ACustomListBox)
  else
    TGtk4ListBox(ACustomListBox.Handle).MultiSelect := AMultiSelect;
end;

class procedure TGtk4WSCustomListBox.SetStyle(const ACustomListBox: TCustomListBox);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetStyle') then
    Exit;
  if TGtk4ListBox(ACustomListBox.Handle).ListBoxStyle <> ACustomListBox.Style then
    RecreateWnd(ACustomListBox);
end;

class procedure TGtk4WSCustomListBox.SetSorted(const ACustomListBox: TCustomListBox;
  AList: TStrings; ASorted: boolean);
var
  AWidget: TGtk4ListBox;
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetSorted') then Exit;
  AWidget := TGtk4ListBox(ACustomListBox.Handle);
  if AWidget.IsListView then
  begin
    { TGtkStringListStrings handles sorting at Pascal level }
    TGtkStringListStrings(g_object_get_data(
      PGObject(AWidget.GetContainerWidget), GtkListItemLCLListTag)).Sorted := ASorted;
  end;
end;

class procedure TGtk4WSCustomListBox.SetTopIndex(const ACustomListBox: TCustomListBox;
  const NewTopIndex: integer);
begin
  if not WSCheckHandleAllocated(ACustomListBox, 'SetTopIndex') then
    Exit;
  TGtk4ListBox(ACustomListBox.Handle).SetTopIndex(NewTopIndex);
end;

{ TGtk4WSCustomComboBox }

class function TGtk4WSCustomComboBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  ACombo: TCustomComboBox;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomComboBox.CreateHandle');
  {$ENDIF}
  ACombo := TCustomComboBox(AWinControl);
  if not ACombo.Style.HasEditBox then
    { csDropDownList, csOwnerDrawFixed, csOwnerDrawVariable → GtkDropDown }
    Result := TLCLHandle(TGtk4DropDown.Create(AWinControl, AParams))
  else
    { csDropDown, csSimple, csOwnerDrawEditable* → GtkComboBox (has entry) }
    Result := TLCLHandle(TGtk4ComboBox.Create(AWinControl, AParams));
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSCustomComboBox.CreateHandle Handle=',dbgs(Result));
  {$ENDIF}
end;

class procedure TGtk4WSCustomComboBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  { Both TGtk4ComboBox and TGtk4DropDown inherit preferredSize from TGtk4Widget }
  TGtk4Widget(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSCustomComboBox.GetDroppedDown(
  const ACustomComboBox: TCustomComboBox): Boolean;
begin
  Result := False;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetDroppedDown') then
    Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
    Result := TGtk4DropDown(ACustomComboBox.Handle).DroppedDown
  else
    Result := TGtk4ComboBox(ACustomComboBox.Handle).DroppedDown;
end;

class function TGtk4WSCustomComboBox.GetSelStart(const ACustomComboBox: TCustomComboBox
  ): integer;
var
  AEntry: PGtkWidget;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetSelStart') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  Result := TGtk4ComboBox(ACustomComboBox.Handle).GetEntrySelStart;
end;

class function TGtk4WSCustomComboBox.GetSelLength(const ACustomComboBox: TCustomComboBox
  ): integer;
var
  AEntry: PGtkWidget;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetSelLength') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  Result := TGtk4ComboBox(ACustomComboBox.Handle).GetEntrySelLength;
end;

class function TGtk4WSCustomComboBox.GetItemIndex(const ACustomComboBox: TCustomComboBox
  ): integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetItemIndex') then
    Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
    Result := TGtk4DropDown(ACustomComboBox.Handle).ItemIndex
  else
    Result := TGtk4ComboBox(ACustomComboBox.Handle).ItemIndex;
end;

class function TGtk4WSCustomComboBox.GetMaxLength(const ACustomComboBox: TCustomComboBox
  ): integer;
var
  AEntry: PGtkWidget;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetMaxLength') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  Result := PGtkEntry(AEntry)^.get_max_length;
end;

class procedure TGtk4WSCustomComboBox.SetArrowKeysTraverseList(
  const ACustomComboBox: TCustomComboBox; NewTraverseList: boolean);
begin
  { GtkComboBox arrow key navigation is built-in and cannot be disabled.
    ArrowKeysTraverseList=True is always the effective behavior. }
end;

class procedure TGtk4WSCustomComboBox.SetDropDownCount(
  const ACustomComboBox: TCustomComboBox; NewCount: Integer);
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetDropDownCount') then Exit;
  if not (TGtk4Widget(ACustomComboBox.Handle) is TGtk4ComboBox) then Exit;
  TGtk4ComboBox(ACustomComboBox.Handle).DropDownCount := NewCount;
end;

class procedure TGtk4WSCustomComboBox.SetDroppedDown(
  const ACustomComboBox: TCustomComboBox; ADroppedDown: Boolean);
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetDroppedDown') then
    Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
    { GtkDropDown has no public popup API; drive its internal toggle button }
    TGtk4DropDown(ACustomComboBox.Handle).DroppedDown := ADroppedDown
  else
    TGtk4ComboBox(ACustomComboBox.Handle).DroppedDown := ADroppedDown;
end;

class procedure TGtk4WSCustomComboBox.SetMaxLength(const ACustomComboBox: TCustomComboBox;
  NewLength: integer);
var
  AEntry: PGtkWidget;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetMaxLength') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  TGtk4ComboBox(ACustomComboBox.Handle).ApplyPendingSelStart; { set_max_length may truncate }
  TGtk4ComboBox(ACustomComboBox.Handle).BeginEntryWrite;
  try
    PGtkEntry(AEntry)^.set_max_length(NewLength);
  finally
    TGtk4ComboBox(ACustomComboBox.Handle).EndEntryWrite;
  end;
end;

class procedure TGtk4WSCustomComboBox.SetSelStart(const ACustomComboBox: TCustomComboBox;
  NewStart: integer);
var
  AEntry: PGtkWidget;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetSelStart') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  TGtk4ComboBox(ACustomComboBox.Handle).SetEntrySelStart(NewStart);
end;

class procedure TGtk4WSCustomComboBox.SetSelLength(const ACustomComboBox: TCustomComboBox;
  NewLength: integer);
var
  AEntry: PGtkWidget;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetSelLength') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then Exit;
  AEntry := TGtk4ComboBox(ACustomComboBox.Handle).Entry;
  if AEntry = nil then Exit;
  TGtk4ComboBox(ACustomComboBox.Handle).SetEntrySelLength(NewLength);
end;

class procedure TGtk4WSCustomComboBox.SetItemIndex(const ACustomComboBox: TCustomComboBox;
  NewIndex: integer);
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetItemIndex') then
    Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
  begin
    TGtk4DropDown(ACustomComboBox.Handle).BeginUpdate;
    TGtk4DropDown(ACustomComboBox.Handle).ItemIndex := NewIndex;
    TGtk4DropDown(ACustomComboBox.Handle).EndUpdate;
  end else
  begin
    TGtk4ComboBox(ACustomComboBox.Handle).BeginUpdate;
    TGtk4ComboBox(ACustomComboBox.Handle).ItemIndex := NewIndex;
    TGtk4ComboBox(ACustomComboBox.Handle).EndUpdate;
  end;
end;

class procedure TGtk4WSCustomComboBox.SetStyle(const ACustomComboBox: TCustomComboBox;
  NewStyle: TComboBoxStyle);
begin
  { Changing between editable (csDropDown) and non-editable (csDropDownList)
    requires widget recreation in GTK4. The LCL handles this by calling
    RecreateWnd when Style changes, so no action needed here. }
end;

class function TGtk4WSCustomComboBox.GetItems(const ACustomComboBox: TCustomComboBox
  ): TStrings;
begin
  Result := nil;
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetItems') then
    Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
    Result := TGtkStringListStrings(g_object_get_data(
      PGObject(TGtk4DropDown(ACustomComboBox.Handle).Widget),
      GtkListItemLCLListTag))
  else
    Result := TGtkStringListStrings(g_object_get_data(
      PGObject(TGtk4ComboBox(ACustomComboBox.Handle).Widget),
      GtkListItemLCLListTag));
end;

class procedure TGtk4WSCustomComboBox.Sort(const ACustomComboBox: TCustomComboBox;
  AList: TStrings; IsSorted: boolean);
var
  SL: TGtkStringListStrings;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'Sort') then Exit;
  if TGtk4Widget(ACustomComboBox.Handle) is TGtk4DropDown then
    SL := TGtkStringListStrings(g_object_get_data(
      PGObject(TGtk4DropDown(ACustomComboBox.Handle).Widget),
      GtkListItemLCLListTag))
  else
    SL := TGtkStringListStrings(g_object_get_data(
      PGObject(TGtk4ComboBox(ACustomComboBox.Handle).Widget),
      GtkListItemLCLListTag));
  if SL <> nil then
    SL.Sorted := IsSorted;
end;

class function TGtk4WSCustomComboBox.GetItemHeight(const ACustomComboBox: TCustomComboBox): Integer;
var
  AWidget: PGtkWidget;
  PangoCtx: PPangoContext;
  FontDesc: PPangoFontDescription;
  Metrics: PPangoFontMetrics;
  Ascent, Descent: Integer;
begin
  Result := 24; { fallback }
  if not WSCheckHandleAllocated(ACustomComboBox, 'GetItemHeight') then Exit;
  AWidget := TGtk4Widget(ACustomComboBox.Handle).Widget;
  if AWidget = nil then Exit;

  { Measure item height from the widget's font metrics plus padding }
  PangoCtx := AWidget^.get_pango_context;
  if PangoCtx = nil then Exit;
  FontDesc := pango_context_get_font_description(PangoCtx);
  if FontDesc = nil then Exit;
  Metrics := PangoCtx^.get_metrics(FontDesc, nil);
  if Metrics <> nil then
  begin
    Ascent := pango_font_metrics_get_ascent(Metrics) div PANGO_SCALE;
    Descent := pango_font_metrics_get_descent(Metrics) div PANGO_SCALE;
    Result := Ascent + Descent + 4; { 4px padding }
    pango_font_metrics_unref(Metrics);
  end;
  { FontDesc from pango_context_get_font_description is owned by context — do not free }
end;

class procedure TGtk4WSCustomComboBox.SetItemHeight(const ACustomComboBox: TCustomComboBox; const AItemHeight: Integer);
var
  CSSProvider: PGtkCssProvider;
  CSSStr: string;
  AWidget: TGtk4Widget;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetItemHeight') then Exit;
  if AItemHeight <= 0 then Exit;
  AWidget := TGtk4Widget(ACustomComboBox.Handle);
  if not (AWidget is TGtk4ComboBox) then Exit;
  CSSProvider := gtk_css_provider_new;
  CSSStr := 'listview > row { min-height: ' + IntToStr(AItemHeight) + 'px; }';
  gtk_css_provider_load_from_data(CSSProvider, PgChar(CSSStr), -1, nil);
  AWidget.Widget^.get_style_context^.add_provider(
    PGtkStyleProvider(CSSProvider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(CSSProvider);
end;

class procedure TGtk4WSCustomComboBox.SetReadOnly(
  const ACustomComboBox: TCustomComboBox; NewReadOnly: boolean);
var
  ACombo: TGtk4ComboBox;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetReadOnly') then Exit;
  if not (TGtk4Widget(ACustomComboBox.Handle) is TGtk4ComboBox) then Exit;
  ACombo := TGtk4ComboBox(ACustomComboBox.Handle);
  if ACombo.Entry <> nil then
    PGtkEditable(ACombo.Entry)^.set_editable(not NewReadOnly);
end;

class procedure TGtk4WSCustomComboBox.SetTextHint(
  const ACustomComboBox: TCustomComboBox; const ATextHint: string);
var
  ACombo: TGtk4ComboBox;
begin
  if not WSCheckHandleAllocated(ACustomComboBox, 'SetTextHint') then Exit;
  if not (TGtk4Widget(ACustomComboBox.Handle) is TGtk4ComboBox) then Exit;
  ACombo := TGtk4ComboBox(ACustomComboBox.Handle);
  if ACombo.Entry <> nil then
    PGtkEntry(ACombo.Entry)^.set_placeholder_text(PgChar(ATextHint));
end;

{ TGtk4WSCustomEdit }

class function TGtk4WSCustomEdit.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AGtkEntry: TGtk4Entry;
begin
  AGtkEntry := TGtk4Entry.Create(AWinControl, AParams);
  Result := TLCLHandle(AGtkEntry);
end;

class procedure TGtk4WSCustomEdit.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4Entry(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSCustomEdit.GetCanUndo(const ACustomEdit: TCustomEdit
  ): Boolean;
begin
  { GtkText/GtkEntry expose no public can-undo query (its undo history is private
    and the text.undo action is always enabled), so we approximate: report True
    when the current text differs from the last programmatically-set value. A
    pristine field (text == the value LCL set) reports False instead of the old
    blanket True. It is imprecise only where the text differs from that baseline
    yet the native undo stack is actually empty -- e.g. after undoing past a
    programmatic set down to the widget's original empty state; there it may
    over-report True, which is no worse than the previous always-True. }
  Result := WSCheckHandleAllocated(ACustomEdit, 'GetCanUndo')
            and TGtk4Entry(ACustomEdit.Handle).GetCanUndoState;
end;

class function TGtk4WSCustomEdit.GetCaretPos(const ACustomEdit: TCustomEdit): TPoint;
begin
  Result := Point(0, 0);
  if not WSCheckHandleAllocated(ACustomEdit, 'GetCaretPos') then
    Exit;
  Result := TGtk4Editable(ACustomEdit.Handle).CaretPos;
end;

class function  TGtk4WSCustomEdit.GetSelStart(const ACustomEdit: TCustomEdit): integer;
begin
  Result := -1;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelStart') then
    Exit;
  Result := TGtk4Editable(ACustomEdit.Handle).getSelStart;
end;

class function  TGtk4WSCustomEdit.GetSelLength(const ACustomEdit: TCustomEdit): integer;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelLength') then
    Exit;
  Result := TGtk4Editable(ACustomEdit.Handle).getSelLength;
end;

class procedure TGtk4WSCustomEdit.SetAlignment(const ACustomEdit: TCustomEdit;
  const AAlignment: TAlignment);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetAlignment') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Entry(ACustomEdit.Handle).Alignment := AAlignment;
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomEdit.SetCaretPos(const ACustomEdit: TCustomEdit; const NewPos: TPoint);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetCaretPos') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Editable(ACustomEdit.Handle).CaretPos := NewPos;
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomEdit.SetCharCase(const ACustomEdit: TCustomEdit; NewCase: TEditCharCase);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetCharCase') then
    Exit;
  { CharCase is enforced by TGtk4Entry.InsertText callback which reads
    AEdit.CharCase directly. LCL base class converts existing text. No WS action needed. }
end;

class procedure TGtk4WSCustomEdit.SetEchoMode(const ACustomEdit: TCustomEdit; NewMode: TEchoMode);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetEchoMode') then
    Exit;
  if NewMode in [emNone,emPassword] then
  begin
    TGtk4Entry(ACustomEdit.Handle).SetEchoMode(False);
    SetPasswordChar(ACustomEdit, ACustomEdit.PasswordChar);
  end else
  begin
    TGtk4Entry(ACustomEdit.Handle).SetEchoMode(True);
  end;
end;

class procedure TGtk4WSCustomEdit.SetHideSelection(const ACustomEdit: TCustomEdit;
  NewHideSelection: Boolean);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetHideSelection') then
    Exit;
  if NewHideSelection then
    gtk4_widget_add_css_class(TGtk4Widget(ACustomEdit.Handle).Widget, 'lcl-hide-sel')
  else
    gtk4_widget_remove_css_class(TGtk4Widget(ACustomEdit.Handle).Widget, 'lcl-hide-sel');
end;

class procedure TGtk4WSCustomEdit.SetMaxLength(const ACustomEdit: TCustomEdit; NewLength: integer);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetMaxLength') then
    Exit;
  TGtk4Entry(ACustomEdit.Handle).SetMaxLength(NewLength);
end;

class procedure TGtk4WSCustomEdit.SetNumbersOnly(
  const ACustomEdit: TCustomEdit; NewNumbersOnly: Boolean);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetNumbersOnly') then
    Exit;
  TGtk4Entry(ACustomEdit.Handle).SetNumbersOnly(NewNumbersOnly);
end;

class procedure TGtk4WSCustomEdit.SetPasswordChar(const ACustomEdit: TCustomEdit; NewChar: char);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetPasswordChar') then
    Exit;
  TGtk4Entry(ACustomEdit.Handle).SetPasswordChar(NewChar);
end;

class procedure TGtk4WSCustomEdit.SetReadOnly(const ACustomEdit: TCustomEdit; NewReadOnly: boolean);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetReadOnly') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).ReadOnly := NewReadOnly;
end;

class procedure TGtk4WSCustomEdit.SetSelStart(const ACustomEdit: TCustomEdit; NewStart: integer);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelStart') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Editable(ACustomEdit.Handle).SetSelStart(NewStart);
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomEdit.SetSelLength(const ACustomEdit: TCustomEdit; NewLength: integer);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelLength') then
    Exit;
  TGtk4Editable(ACustomEdit.Handle).BeginUpdate;
  TGtk4Editable(ACustomEdit.Handle).SetSelLength(NewLength);
  TGtk4Editable(ACustomEdit.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomEdit.SetTextHint(const ACustomEdit: TCustomEdit;
  const ATextHint: string);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetTextHint') then
    Exit;
  TGtk4Entry(ACustomEdit.Handle).SetTextHint(ATextHint);
end;

class procedure TGtk4WSCustomEdit.Cut(const ACustomEdit: TCustomEdit);
begin
  ACustomEdit.CopyToClipboard;
  ACustomEdit.ClearSelection;
end;

class procedure TGtk4WSCustomEdit.Copy(const ACustomEdit: TCustomEdit);
begin
  if (ACustomEdit.EchoMode = emNormal) and (ACustomEdit.SelLength > 0) then
    Clipboard.AsText := ACustomEdit.SelText;
end;

class procedure TGtk4WSCustomEdit.Paste(const ACustomEdit: TCustomEdit);
begin
  if Clipboard.HasFormat(CF_TEXT) then
    ACustomEdit.SelText := Clipboard.AsText;
end;

class procedure TGtk4WSCustomEdit.SetBorderStyle(
  const AWinControl: TWinControl; const ABorderStyle: TBorderStyle);
begin
  if not WSCheckHandleAllocated(AWinControl, 'SetBorderStyle') then
    Exit;
  TGtk4Entry(AWinControl.Handle).SetFrame(ABorderStyle = bsSingle);
end;

class procedure TGtk4WSCustomEdit.Undo(const ACustomEdit: TCustomEdit);
var
  W: PGtkWidget;
  Delegate: PGtkEditable;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'Undo') then
    Exit;
  { The "text.undo" action is installed on the inner GtkText delegate, NOT on the
    outer GtkEntry (widget actions do not propagate parent->child), so activating
    it on the entry handle was a silent no-op. Route to the GtkText delegate. }
  W := TGtk4Widget(ACustomEdit.Handle).Widget;
  Delegate := gtk_editable_get_delegate(PGtkEditable(W));
  if Delegate <> nil then
    W := PGtkWidget(Delegate);
  gtk4_widget_activate_action(W, 'text.undo', nil);
end;

{ TGtk4WSCustomMemo }

class function TGtk4WSCustomMemo.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AGtkMemo: TGtk4Memo;
begin
  AGtkMemo := TGtk4Memo.Create(AWinControl, AParams);
  AGtkMemo.BorderStyle := TCustomMemo(AWinControl).BorderStyle;
  Result := TLCLHandle(AGtkMemo);
end;

class procedure TGtk4WSCustomMemo.AppendText(const ACustomMemo: TCustomMemo;
  const AText: string);
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
begin
  if not WSCheckHandleAllocated(ACustomMemo, 'AppendText') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomMemo.Handle).GetContainerWidget)^.get_buffer;
  if ABuffer = nil then Exit;
  ABuffer^.get_end_iter(@AIter);
  ABuffer^.insert(@AIter, PgChar(AText), Length(AText));
end;

class procedure TGtk4WSCustomMemo.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4Memo(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSCustomMemo.GetStrings(const ACustomMemo: TCustomMemo
  ): TStrings;
begin
  Result := TGtk4MemoStrings.Create(ACustomMemo);
end;

class procedure TGtk4WSCustomMemo.SetScrollbars(const ACustomMemo: TCustomMemo; const NewScrollbars: TScrollStyle);
var
  AScrollStyle: TGtkScrollStyle;
begin
  if not WSCheckHandleAllocated(ACustomMemo, 'SetScrollBars') then
    Exit;
  AScrollStyle := Gtk4TranslateScrollStyle(ACustomMemo.ScrollBars);
  TGtk4Memo(ACustomMemo.Handle).BeginUpdate;
  TGtk4Memo(ACustomMemo.Handle).HScrollBarPolicy := AScrollStyle.Horizontal;
  TGtk4Memo(ACustomMemo.Handle).VScrollBarPolicy := AScrollStyle.Vertical;
  TGtk4Memo(ACustomMemo.Handle).EndUpdate;
end;

class procedure TGtk4WSCustomMemo.SetWantTabs(const ACustomMemo: TCustomMemo; const NewWantTabs: boolean);
begin
  if not WSCheckHandleAllocated(ACustomMemo, 'SetWantTabs') then
    Exit;
  TGtk4Memo(ACustomMemo.Handle).WantTabs := NewWantTabs;
end;

class procedure TGtk4WSCustomMemo.SetWantReturns(const ACustomMemo: TCustomMemo; const NewWantReturns: boolean);
begin
  if not WSCheckHandleAllocated(ACustomMemo, 'SetWantReturns') then
    Exit;
  TGtk4Memo(ACustomMemo.Handle).WantReturns := NewWantReturns;
end;

class procedure TGtk4WSCustomMemo.SetWordWrap(const ACustomMemo: TCustomMemo; const NewWordWrap: boolean);
begin
  if not WSCheckHandleAllocated(ACustomMemo, 'SetWordWrap') then
    Exit;
  TGtk4Memo(ACustomMemo.Handle).WordWrap := NewWordWrap;
end;

class function TGtk4WSCustomMemo.GetCanUndo(const ACustomEdit: TCustomEdit
  ): Boolean;
var
  ABuffer: PGtkTextBuffer;
begin
  Result := False;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetCanUndo') then
    Exit;
  ABuffer := PGtkTextView(TGtk4Widget(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  if ABuffer <> nil then
    Result := gtk4_text_buffer_get_can_undo(ABuffer);
end;

class procedure TGtk4WSCustomMemo.Undo(const ACustomEdit: TCustomEdit);
var
  ABuffer: PGtkTextBuffer;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'Undo') then
    Exit;
  ABuffer := PGtkTextView(TGtk4Widget(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  if (ABuffer <> nil) and gtk4_text_buffer_get_can_undo(ABuffer) then
    gtk4_text_buffer_undo(ABuffer);
end;

class function TGtk4WSCustomMemo.GetCaretPos(const ACustomEdit: TCustomEdit
  ): TPoint;
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
  AMark: PGtkTextMark;
begin
  Result := Point(0, 0);
  if not WSCheckHandleAllocated(ACustomEdit, 'GetCaretPos') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  AMark := ABuffer^.get_insert;
  ABuffer^.get_iter_at_mark(@AIter, AMark);
  Result.Y := AIter.get_line;
  Result.X := AIter.get_line_offset;
end;

class function TGtk4WSCustomMemo.GetSelStart(const ACustomEdit: TCustomEdit
  ): integer;
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
  AMark: PGtkTextMark;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelStart') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  AMark := ABuffer^.get_insert;
  ABuffer^.get_iter_at_mark(@AIter, AMark);
  Result := AIter.get_offset;
end;

class function TGtk4WSCustomMemo.GetSelLength(const ACustomEdit: TCustomEdit
  ): integer;
var
  ABuffer: PGtkTextBuffer;
  AStart, AEnd: TGtkTextIter;
begin
  Result := 0;
  if not WSCheckHandleAllocated(ACustomEdit, 'GetSelLength') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  if ABuffer^.get_selection_bounds(@AStart, @AEnd) then
    Result := AEnd.get_offset - AStart.get_offset;
end;

class procedure TGtk4WSCustomMemo.SetAlignment(const ACustomEdit: TCustomEdit;
  const AAlignment: TAlignment);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetAlignment') then
    Exit;
  TGtk4Memo(ACustomEdit.Handle).Alignment := AAlignment;
end;

class procedure TGtk4WSCustomMemo.SetCaretPos(const ACustomEdit: TCustomEdit;
  const NewPos: TPoint);
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetCaretPos') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  ABuffer^.get_iter_at_offset(@AIter, 0);
  AIter.set_line(NewPos.Y);
  AIter.set_line_offset(NewPos.X);
  ABuffer^.place_cursor(@AIter);
end;

class procedure TGtk4WSCustomMemo.SetCharCase(const ACustomEdit: TCustomEdit;
  NewCase: TEditCharCase);
begin
  { CharCase is enforced by the Gtk4MemoBufferInsertText callback
    connected to the GtkTextBuffer "insert-text" signal. No WS action needed. }
end;

class procedure TGtk4WSCustomMemo.SetEchoMode(const ACustomEdit: TCustomEdit;
  NewMode: TEchoMode);
begin
  { GtkTextView does not support echo/password mode. Not applicable for Memo. }
end;

class procedure TGtk4WSCustomMemo.SetHideSelection(
  const ACustomEdit: TCustomEdit; NewHideSelection: Boolean);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetHideSelection') then
    Exit;
  if NewHideSelection then
    gtk4_widget_add_css_class(TGtk4Widget(ACustomEdit.Handle).GetContainerWidget, 'lcl-hide-sel')
  else
    gtk4_widget_remove_css_class(TGtk4Widget(ACustomEdit.Handle).GetContainerWidget, 'lcl-hide-sel');
end;

class procedure TGtk4WSCustomMemo.SetMaxLength(const ACustomEdit: TCustomEdit;
  NewLength: integer);
begin
  { MaxLength is enforced by the Gtk4MemoBufferInsertText callback
    connected to the GtkTextBuffer "insert-text" signal. No WS action needed. }
end;

class procedure TGtk4WSCustomMemo.SetPasswordChar(
  const ACustomEdit: TCustomEdit; NewChar: char);
begin
  { GtkTextView does not support password characters. Not applicable for Memo. }
end;

class procedure TGtk4WSCustomMemo.SetReadOnly(const ACustomEdit: TCustomEdit;
  NewReadOnly: boolean);
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetReadOnly') then
    Exit;
  TGtk4Memo(ACustomEdit.Handle).ReadOnly := NewReadOnly;
end;

class procedure TGtk4WSCustomMemo.SetSelStart(const ACustomEdit: TCustomEdit;
  NewStart: integer);
var
  ABuffer: PGtkTextBuffer;
  AIter: TGtkTextIter;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelStart') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  ABuffer^.get_iter_at_offset(@AIter, NewStart);
  ABuffer^.place_cursor(@AIter);
end;

class procedure TGtk4WSCustomMemo.SetSelLength(const ACustomEdit: TCustomEdit;
  NewLength: integer);
var
  ABuffer: PGtkTextBuffer;
  AInsert, ABound: TGtkTextIter;
  AMark: PGtkTextMark;
begin
  if not WSCheckHandleAllocated(ACustomEdit, 'SetSelLength') then Exit;
  ABuffer := PGtkTextView(TGtk4Memo(ACustomEdit.Handle).GetContainerWidget)^.get_buffer;
  { Get current cursor position as selection start }
  AMark := ABuffer^.get_insert;
  ABuffer^.get_iter_at_mark(@AInsert, AMark);
  { Create bound iter at start + length }
  ABuffer^.get_iter_at_offset(@ABound, AInsert.get_offset + NewLength);
  ABuffer^.select_range(@AInsert, @ABound);
end;

{ TGtk4WSCustomStaticText }

class function TGtk4WSCustomStaticText.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  AStaticText: TGtk4StaticText;
begin
  AStaticText := TGtk4StaticText.Create(AWinControl, AParams);
  Result := TLCLHandle(AStaticText);
end;

class procedure TGtk4WSCustomStaticText.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4StaticText(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class procedure TGtk4WSCustomStaticText.SetAlignment(const ACustomStaticText: TCustomStaticText; const NewAlignment: TAlignment);
begin
  if not WSCheckHandleAllocated(ACustomStaticText, 'SetAlignment') then
    Exit;
  TGtk4StaticText(ACustomStaticText.Handle).Alignment := NewAlignment;
end;

class procedure TGtk4WSCustomStaticText.SetStaticBorderStyle(
  const ACustomStaticText: TCustomStaticText;
  const NewBorderStyle: TStaticBorderStyle);
begin
  if not WSCheckHandleAllocated(ACustomStaticText, 'SetStaticBorderStyle') then
    Exit;
  TGtk4StaticText(ACustomStaticText.Handle).StaticBorderStyle := NewBorderStyle;
end;

{ TGtk4WSButton }

class function TGtk4WSButton.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLHandle;
var
  AButton: TGtk4Button;
begin
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSButton.CreateHandle');
  {$ENDIF}
  AButton := TGtk4Button.Create(AWinControl, AParams);
  Result := TLCLHandle(AButton);
  {$IFDEF GTK4DEBUGCORE}
  DebugLn('TGtk4WSButton.CreateHandle Handle=',dbgs(Result));
  {$ENDIF}
end;

class procedure TGtk4WSButton.GetPreferredSize(const AWinControl: TWinControl;
  var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4Button(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class procedure TGtk4WSButton.SetDefault(const AButton: TCustomButton; ADefault: Boolean);
begin
  if not WSCheckHandleAllocated(AButton, 'SetDefault') then
    Exit;
  TGtk4Button(AButton.Handle).SetDefault(ADefault);
end;

class procedure TGtk4WSButton.SetShortCut(const AButton: TCustomButton;
  const ShortCutK1, ShortCutK2: TShortCut);
begin
  if not WSCheckHandleAllocated(AButton, 'SetShortCut') then
    Exit;
  Gtk4SetWidgetShortCut(TGtk4Widget(AButton.Handle).Widget, ShortCutK1, ShortCutK2);
end;

{ TGtk4WSCustomCheckBox }

class function TGtk4WSCustomCheckBox.CreateHandle(
  const AWinControl: TWinControl; const AParams: TCreateParams): TLCLHandle;
var
  ACheckBox: TGtk4CheckBox;
begin
  ACheckBox := TGtk4CheckBox.Create(AWinControl, AParams);

  Result := TLCLHandle(ACheckBox);
end;

class procedure TGtk4WSCustomCheckBox.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
begin
  if not WSCheckHandleAllocated(AWinControl, 'GetPreferredSize') then
    Exit;
  TGtk4CheckBox(AWinControl.Handle).preferredSize(PreferredWidth, PreferredHeight, WithThemeSpace);
end;

class function TGtk4WSCustomCheckBox.RetrieveState(const ACustomCheckBox: TCustomCheckBox): TCheckBoxState;
begin
  Result := cbUnchecked;
  if not WSCheckHandleAllocated(ACustomCheckBox, 'RetrieveState') then
    Exit;
  Result := TGtk4CheckBox(ACustomCheckBox.Handle).State;
end;

class procedure TGtk4WSCustomCheckBox.SetShortCut(const ACustomCheckBox: TCustomCheckBox;
  const ShortCutK1, ShortCutK2: TShortCut);
begin
  if not WSCheckHandleAllocated(ACustomCheckBox, 'SetShortCut') then
    Exit;
  Gtk4SetWidgetShortCut(TGtk4Widget(ACustomCheckBox.Handle).Widget, ShortCutK1, ShortCutK2);
end;

class procedure TGtk4WSCustomCheckBox.SetState(const ACustomCheckBox: TCustomCheckBox; const NewState: TCheckBoxState);
begin
  if not WSCheckHandleAllocated(ACustomCheckBox, 'SetState') then
    Exit;
  TGtk4CheckBox(ACustomCheckBox.Handle).State := NewState;
end;

class procedure TGtk4WSCustomCheckBox.SetAlignment(
  const ACustomCheckBox: TCustomCheckBox; const NewAlignment: TLeftRight);
begin
  if not WSCheckHandleAllocated(ACustomCheckBox, 'SetAlignment') then Exit;
  if NewAlignment = taLeftJustify then
    TGtk4Widget(ACustomCheckBox.Handle).Widget^.set_direction(GTK_TEXT_DIR_RTL)
  else
    TGtk4Widget(ACustomCheckBox.Handle).Widget^.set_direction(GTK_TEXT_DIR_LTR);
end;

class procedure TGtk4WSCustomCheckBox.ShowHide(const AWinControl: TWinControl);
begin
  if not WSCheckHandleAllocated(AWinControl, 'ShowHide') then Exit;
  { Apply alignment direction before showing }
  if TCustomCheckBox(AWinControl).Alignment = taLeftJustify then
    TGtk4Widget(AWinControl.Handle).Widget^.set_direction(GTK_TEXT_DIR_RTL)
  else
    TGtk4Widget(AWinControl.Handle).Widget^.set_direction(GTK_TEXT_DIR_LTR);
  { Delegate to base WinControl ShowHide }
  TGtk4WSWinControl.ShowHide(AWinControl);
end;

{ TGtk4WSButtonControl }

class function TGtk4WSButtonControl.GetDefaultColor(const AControl: TControl; const ADefaultColorType: TDefaultColorType): TColor;
begin
  Result := DefBtnColors[ADefaultColorType];
end;

end.
