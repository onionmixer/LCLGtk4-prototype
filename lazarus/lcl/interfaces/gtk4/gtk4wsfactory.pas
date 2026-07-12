{
 *****************************************************************************
 *                                Gtk4WSFactory.pp                           *
 *                                ----------                                 *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSFactory;

{$mode objfpc}{$H+}

interface
uses
  Classes, Controls, ComCtrls, Calendar, StdCtrls, Dialogs, ExtCtrls, ExtDlgs,
  Buttons, Spin, CheckLst, Forms, Grids, Menus, ImgList, PairSplitter,
  WSLCLClasses, WSDialogs;


// imglist
function RegisterCustomImageListResolution: Boolean;
// controls
function RegisterDragImageListResolution: Boolean;
function RegisterLazAccessibleObject: Boolean;
function RegisterControl: Boolean;
function RegisterWinControl: Boolean;
function RegisterGraphicControl: Boolean;
function RegisterCustomControl: Boolean;
// comctrls
function RegisterStatusBar: Boolean;
function RegisterTabSheet: Boolean;
function RegisterPageControl: Boolean;
function RegisterCustomListView: Boolean;
function RegisterCustomProgressBar: Boolean;
function RegisterCustomUpDown: Boolean;
function RegisterCustomToolButton: Boolean;
function RegisterToolBar: Boolean;
function RegisterCustomTrackBar: Boolean;
function RegisterCustomTreeView: Boolean;
// calendar
function RegisterCustomCalendar: Boolean;
// dialogs
function RegisterCommonDialog: Boolean;
function RegisterFileDialog: Boolean;
function RegisterOpenDialog: Boolean;
function RegisterSaveDialog: Boolean;
function RegisterSelectDirectoryDialog: Boolean;
function RegisterColorDialog: Boolean;
function RegisterColorButton: Boolean;
function RegisterFontDialog: Boolean;
function RegisterTaskDialog: Boolean;
// StdCtrls
function RegisterCustomScrollBar: Boolean;
function RegisterCustomGroupBox: Boolean;
function RegisterCustomComboBox: Boolean;
function RegisterCustomListBox: Boolean;
function RegisterCustomEdit: Boolean;
function RegisterCustomMemo: Boolean;
function RegisterButtonControl: Boolean;
function RegisterCustomButton: Boolean;
function RegisterCustomCheckBox: Boolean;
function RegisterToggleBox: Boolean;
function RegisterRadioButton: Boolean;
function RegisterCustomStaticText: Boolean;
function RegisterCustomLabel: Boolean;
// extctrls
function RegisterCustomPage: Boolean;
function RegisterCustomNotebook: Boolean;
function RegisterCustomShape: Boolean;
function RegisterCustomSplitter: Boolean;
function RegisterPaintBox: Boolean;
function RegisterCustomImage: Boolean;
function RegisterBevel: Boolean;
function RegisterCustomRadioGroup: Boolean;
function RegisterCustomCheckGroup: Boolean;
function RegisterCustomLabeledEdit: Boolean;
function RegisterCustomPanel: Boolean;
function RegisterCustomTrayIcon: Boolean;
//ExtDlgs
function RegisterPreviewFileControl: Boolean;
function RegisterPreviewFileDialog: Boolean;
function RegisterOpenPictureDialog: Boolean;
function RegisterSavePictureDialog: Boolean;
function RegisterCalculatorDialog: Boolean;
function RegisterCalculatorForm: Boolean;
function RegisterCalendarDialog: Boolean;
// Buttons
function RegisterCustomBitBtn: Boolean;
function RegisterCustomSpeedButton: Boolean;
// CheckLst
function RegisterCustomCheckListBox: Boolean;
// Forms
function RegisterScrollingWinControl: Boolean;
function RegisterScrollBox: Boolean;
function RegisterCustomFrame: Boolean;
function RegisterCustomForm: Boolean;
function RegisterHintWindow: Boolean;
function RegisterCustomGrid: Boolean;
function RegisterMenuItem: Boolean;
function RegisterMenu: Boolean;
function RegisterMainMenu: Boolean;
function RegisterPopupMenu: Boolean;
function RegisterPairSplitterSide: Boolean;
function RegisterCustomPairSplitter: Boolean;
function RegisterCustomFloatSpinEdit: Boolean;
function RegisterCustomRubberBand: Boolean;
// ShellCtrls
function RegisterCustomShellTreeView: Boolean;
function RegisterCustomShellListView: Boolean;
// LazDeviceAPIs
function RegisterLazDeviceAPIs: Boolean;

implementation

uses
  Gtk4WSImgList, Gtk4WSControls, Gtk4WSForms, Gtk4WSButtons, Gtk4WSStdCtrls,
  Gtk4WSComCtrls, Gtk4WSExtCtrls, Gtk4WSSpin, Gtk4WSMenus, Gtk4WSCalendar,
  Gtk4WSDialogs, Gtk4WSCheckLst, Gtk4WSExtDlgs, gtk4wssplitter, Gtk4WSTrayIcon,
  Gtk4WSGrids;

// imglist
function RegisterCustomImageListResolution: Boolean; alias : 'WSRegisterCustomImageListResolution';
begin
  RegisterWSComponent(TCustomImageListResolution, TGtk4WSCustomImageListResolution);
  Result := True;
end;

// controls
function RegisterDragImageListResolution: Boolean; alias : 'WSRegisterDragImageListResolution';
begin
  { TGtk4WSDragImageListResolution is a no-visual implementation: GTK4/Wayland
    removed arbitrary surface positioning, so no drag-image overlay is drawn,
    but its methods return True so TDragImageList.BeginDrag/Dragging behave
    like the other widgetsets and the drag operation proceeds normally.
    Returning False here dropped the public path to the base class and made
    BeginDrag fail (runtime-measured, PLAN_GTK4_WSCONTROLS_VALIDATION.md). }
  RegisterWSComponent(TDragImageListResolution, TGtk4WSDragImageListResolution);
  Result := True;
end;

function RegisterLazAccessibleObject: Boolean; alias : 'WSRegisterLazAccessibleObject';
begin
  RegisterWSLazAccessibleObject(TGtk4WSLazAccessibleObject);
  Result := True;
end;

function RegisterControl: Boolean; alias : 'WSRegisterControl';
begin
  Result := False;
end;

function RegisterWinControl: Boolean; alias : 'WSRegisterWinControl';
begin
  RegisterWSComponent(TWinControl, TGtk4WSWinControl);
  Result := True;
end;

function RegisterGraphicControl: Boolean; alias : 'WSRegisterGraphicControl';
begin
  Result := False;
end;

function RegisterCustomControl: Boolean; alias : 'WSRegisterCustomControl';
begin
  RegisterWSComponent(TCustomControl, TGtk4WSCustomControl);
  Result := True;
end;

// comctrls
function RegisterStatusBar: Boolean; alias : 'WSRegisterStatusBar';
begin
  RegisterWSComponent(TStatusBar, TGtk4WSStatusBar);
  Result := True;
end;

function RegisterTabSheet: Boolean; alias : 'WSRegisterTabSheet';
begin
  Result := False;
end;

function RegisterPageControl: Boolean; alias : 'WSRegisterPageControl';
begin
  Result := False;
end;

function RegisterCustomListView: Boolean; alias : 'WSRegisterCustomListView';
begin
  RegisterWSComponent(TCustomListView, TGtk4WSCustomListView);
  Result := True;
end;

function RegisterCustomProgressBar: Boolean; alias : 'WSRegisterCustomProgressBar';
begin
  RegisterWSComponent(TCustomProgressBar, TGtk4WSProgressBar);
  Result := True;
end;

function RegisterCustomUpDown: Boolean; alias : 'WSRegisterCustomUpDown';
begin
  Result := False;
end;

function RegisterCustomToolButton: Boolean; alias : 'WSRegisterCustomToolButton';
begin
  Result := False;
end;

function RegisterToolBar: Boolean; alias : 'WSRegisterToolBar';
begin
  RegisterWSComponent(TToolBar, TGtk4WSToolBar);
  Result := True;
end;

function RegisterCustomTrackBar: Boolean; alias : 'WSRegisterCustomTrackBar';
begin
  RegisterWSComponent(TCustomTrackBar, TGtk4WSTrackBar);
  Result := True;
end;

function RegisterCustomTreeView: Boolean; alias : 'WSRegisterCustomTreeView';
begin
  Result := False;
end;

// calendar
function RegisterCustomCalendar: Boolean; alias : 'WSRegisterCustomCalendar';
begin
  RegisterWSComponent(TCustomCalendar, TGtk4WSCustomCalendar);
  Result := True;
end;

// dialogs
function RegisterCommonDialog: Boolean; alias : 'WSRegisterCommonDialog';
begin
  RegisterWSComponent(TCommonDialog, TGtk4WSCommonDialog);
  Result := True;
end;

function RegisterFileDialog: Boolean; alias : 'WSRegisterFileDialog';
begin
  RegisterWSComponent(TFileDialog, TGtk4WSFileDialog);
  Result := True;
end;

function RegisterOpenDialog: Boolean; alias : 'WSRegisterOpenDialog';
begin
  RegisterWSComponent(TOpenDialog, TGtk4WSOpenDialog);
  Result := True;
end;

function RegisterSaveDialog: Boolean; alias : 'WSRegisterSaveDialog';
begin
  { Do NOT register TSaveDialog to TGtk4WSSaveDialog. That class descends from
    TWSSaveDialog, not TGtk4WSOpenDialog, so the LCL VClass synthesizer patches
    only the common-ancestor (TWSOpenDialog) slots. TGtk4WSOpenDialog's own
    virtual helpers (CreateOpenDialogHistory, CreateOpenDialogFilter,
    CreatePreviewDialogControl) — called from the inherited CreateHandle — are
    left pointing at undefined VMT slots, so Save As crashes (EAccessViolation)
    the moment CreateHandle dispatches CreateOpenDialogHistory. Like gtk2, leave
    TSaveDialog on the TOpenDialog widgetset class; TGtk4WSOpenDialog.CreateHandle
    already handles Save via InheritsFrom(TSaveDialog). }
//  RegisterWSComponent(TSaveDialog, TGtk4WSSaveDialog);
  Result := False;
end;

function RegisterSelectDirectoryDialog: Boolean; alias : 'WSRegisterSelectDirectoryDialog';
begin
  { Same VClass virtual-slot problem as RegisterSaveDialog — see above. The
    select-folder action is set from the LCL object type in
    TGtk4FileDialog.Create, so leaving TSelectDirectoryDialog on the TOpenDialog
    widgetset class keeps folder selection working. }
//  RegisterWSComponent(TSelectDirectoryDialog, TGtk4WSSelectDirectoryDialog);
  Result := False;
end;

function RegisterColorDialog: Boolean; alias : 'WSRegisterColorDialog';
begin
  RegisterWSComponent(TColorDialog, TGtk4WSColorDialog);
  Result := True;
end;

function RegisterColorButton: Boolean; alias : 'WSRegisterColorButton';
begin
  Result := False;
end;

function RegisterFontDialog: Boolean; alias : 'WSRegisterFontDialog';
begin
  RegisterWSComponent(TFontDialog, TGtk4WSFontDialog);
  Result := True;
end;

function RegisterTaskDialog: Boolean; alias : 'WSRegisterTaskDialog';
begin
   RegisterWSComponent(TTaskDialog, TWSTaskDialog);
   Result := True;
end;

// StdCtrls
function RegisterCustomScrollBar: Boolean; alias : 'WSRegisterCustomScrollBar';
begin
  RegisterWSComponent(TCustomScrollBar, TGtk4WSScrollBar);
  Result := True;
end;

function RegisterCustomGroupBox: Boolean; alias : 'WSRegisterCustomGroupBox';
begin
  RegisterWSComponent(TCustomGroupBox, TGtk4WSCustomGroupBox);
  Result := True;
end;

function RegisterCustomComboBox: Boolean; alias : 'WSRegisterCustomComboBox';
begin
  RegisterWSComponent(TCustomComboBox, TGtk4WSCustomComboBox);
  Result := True;
end;

function RegisterCustomListBox: Boolean; alias : 'WSRegisterCustomListBox';
begin
  RegisterWSComponent(TCustomListBox, TGtk4WSCustomListBox);
  Result := True;
end;

function RegisterCustomEdit: Boolean; alias : 'WSRegisterCustomEdit';
begin
  RegisterWSComponent(TCustomEdit, TGtk4WSCustomEdit);
  Result := True;
end;

function RegisterCustomMemo: Boolean; alias : 'WSRegisterCustomMemo';
begin
  RegisterWSComponent(TCustomMemo, TGtk4WSCustomMemo);
  Result := True;
end;

function RegisterButtonControl: Boolean; alias : 'WSRegisterButtonControl';
begin
  Result := False;
end;

function RegisterCustomButton: Boolean; alias : 'WSRegisterCustomButton';
begin
  RegisterWSComponent(TCustomButton, TGtk4WSButton);
  Result := True;
end;

function RegisterCustomCheckBox: Boolean; alias : 'WSRegisterCustomCheckBox';
begin
  RegisterWSComponent(TCustomCheckBox, TGtk4WSCustomCheckBox);
  Result := True;
end;

function RegisterToggleBox: Boolean; alias : 'WSRegisterToggleBox';
begin
  RegisterWSComponent(TToggleBox, TGtk4WSToggleBox);
  Result := True;
end;

function RegisterRadioButton: Boolean; alias : 'WSRegisterRadioButton';
begin
  RegisterWSComponent(TRadioButton, TGtk4WSRadioButton);
  Result := True;
end;

function RegisterCustomStaticText: Boolean; alias : 'WSRegisterCustomStaticText';
begin
  RegisterWSComponent(TCustomStaticText, TGtk4WSCustomStaticText);
  Result := True;
end;

function RegisterCustomLabel: Boolean; alias : 'WSRegisterCustomLabel';
begin
  Result := False;
end;

// extctrls
function RegisterCustomPage: Boolean; alias : 'WSRegisterCustomPage';
begin
  RegisterWSComponent(TCustomPage, TGtk4WSCustomPage);
  Result := True;
end;

function RegisterCustomNotebook: Boolean; alias : 'WSRegisterCustomNotebook';
begin
  RegisterWSComponent(TCustomTabControl, TGtk4WSCustomTabControl);
  Result := True;
end;

function RegisterCustomShape: Boolean; alias : 'WSRegisterCustomShape';
begin
  Result := False;
end;

function RegisterCustomSplitter: Boolean; alias : 'WSRegisterCustomSplitter';
begin
  RegisterWSComponent(TCustomSplitter, TGtk4WSCustomSplitter);
  Result := true;
end;

function RegisterPaintBox: Boolean; alias : 'WSRegisterPaintBox';
begin
  Result := False;
end;

function RegisterCustomImage: Boolean; alias : 'WSRegisterCustomImage';
begin
  Result := False;
end;

function RegisterBevel: Boolean; alias : 'WSRegisterBevel';
begin
  Result := False;
end;

function RegisterCustomRadioGroup: Boolean; alias : 'WSRegisterCustomRadioGroup';
begin
  RegisterWSComponent(TCustomRadioGroup, TGtk4WSCustomRadioGroup);
  RegisterWSComponent(TRadioGroup, TGtk4WSRadioGroup);
  Result := True;
end;

function RegisterCustomCheckGroup: Boolean; alias : 'WSRegisterCustomCheckGroup';
begin
  RegisterWSComponent(TCustomCheckGroup, TGtk4WSCustomCheckGroup);
  RegisterWSComponent(TCheckGroup, TGtk4WSCheckGroup);
  Result := True;
end;

function RegisterCustomLabeledEdit: Boolean; alias : 'WSRegisterCustomLabeledEdit';
begin
  Result := False;
end;

function RegisterCustomPanel: Boolean; alias : 'WSRegisterCustomPanel';
begin
  RegisterWSComponent(TCustomPanel, TGtk4WSCustomPanel);
  Result := True;
end;

function RegisterCustomTrayIcon: Boolean; alias : 'WSRegisterCustomTrayIcon';
begin
  // (Linux only) SNI D-Bus tray icon — requires D-Bus session bus
  Result := True;
  if Gtk4SNITrayIconInit then
    RegisterWSComponent(TCustomTrayIcon, TGtk4WSTrayIcon)
  else
    Result := False;
end;

//ExtDlgs
function RegisterPreviewFileControl: Boolean; alias : 'WSRegisterPreviewFileControl';
begin
  RegisterWSComponent(TPreviewFileControl, TGtk4WSPreviewFileControl);
  Result := True;
end;

function RegisterPreviewFileDialog: Boolean; alias : 'WSRegisterPreviewFileDialog';
begin
  Result := False;
end;

function RegisterOpenPictureDialog: Boolean; alias : 'WSRegisterOpenPictureDialog';
begin
  Result := False;
end;

function RegisterSavePictureDialog: Boolean; alias : 'WSRegisterSavePictureDialog';
begin
  Result := False;
end;

function RegisterCalculatorDialog: Boolean; alias : 'WSRegisterCalculatorDialog';
begin
  Result := False;
end;

function RegisterCalculatorForm: Boolean; alias : 'WSRegisterCalculatorForm';
begin
  Result := False;
end;

function RegisterCalendarDialog: Boolean; alias : 'WSRegisterCalendarDialog';
begin
  Result := False;
end;

// Buttons
function RegisterCustomBitBtn: Boolean; alias : 'WSRegisterCustomBitBtn';
begin
  RegisterWSComponent(TCustomBitBtn, TGtk4WSBitBtn);
  Result := True;
end;

function RegisterCustomSpeedButton: Boolean; alias : 'WSRegisterCustomSpeedButton';
begin
  Result := False;
end;

// CheckLst
function RegisterCustomCheckListBox: Boolean; alias : 'WSRegisterCustomCheckListBox';
begin
  RegisterWSComponent(TCustomCheckListBox, TGtk4WSCustomCheckListBox);
  Result := True;
end;

// Forms
function RegisterScrollingWinControl: Boolean; alias : 'WSRegisterScrollingWinControl';
begin
  RegisterWSComponent(TScrollingWinControl, TGtk4WSScrollingWinControl);
  Result := True;
end;

function RegisterScrollBox: Boolean; alias : 'WSRegisterScrollBox';
begin
  RegisterWSComponent(TScrollBox, TGtk4WSScrollBox);
  Result := True;
end;

function RegisterCustomFrame: Boolean; alias : 'WSRegisterCustomFrame';
begin
  RegisterWSComponent(TCustomFrame, TGtk4WSCustomFrame);
  Result := True;
end;

function RegisterCustomForm: Boolean; alias : 'WSRegisterCustomForm';
begin
  RegisterWSComponent(TCustomForm, TGtk4WSCustomForm);
  Result := True;
end;

function RegisterHintWindow: Boolean; alias : 'WSRegisterHintWindow';
begin
  RegisterWSComponent(THintWindow, TGtk4WSHintWindow);
  Result := True;
end;

function RegisterCustomGrid: Boolean; alias : 'WSRegisterCustomGrid';
begin
  RegisterWSComponent(TCustomGrid, TGtk4WSCustomGrid);
  Result := True;
end;

function RegisterMenuItem: Boolean; alias : 'WSRegisterMenuItem';
begin
  RegisterWSComponent(TMenuItem, TGtk4WSMenuItem);
  Result := True;
end;

function RegisterMenu: Boolean; alias : 'WSRegisterMenu';
begin
  RegisterWSComponent(TMenu, TGtk4WSMenu);
  Result := True;
end;

function RegisterMainMenu: Boolean; alias : 'WSRegisterMainMenu';
begin
  Result := False;
end;

function RegisterPopupMenu: Boolean; alias : 'WSRegisterPopupMenu';
begin
  RegisterWSComponent(TPopupMenu, TGtk4WSPopupMenu);
  Result := True;
end;

function RegisterPairSplitterSide: Boolean; alias : 'WSRegisterPairSplitterSide';
begin
  RegisterWSComponent(TPairSplitterSide, TGtk4WSPairSplitterSide);
  Result := true;
end;

function RegisterCustomPairSplitter: Boolean; alias : 'WSRegisterCustomPairSplitter';
begin
  RegisterWSComponent(TCustomPairSplitter, TGtk4WSCustomPairSplitter);
  Result := true;
end;

function RegisterCustomFloatSpinEdit: Boolean; alias : 'WSRegisterCustomFloatSpinEdit';
begin
  RegisterWSComponent(TCustomFloatSpinEdit, TGtk4WSCustomFloatSpinEdit);
  Result := True;
end;

function RegisterCustomRubberBand: Boolean; alias : 'WSRegisterCustomRubberBand';
begin
  Result := False;
end;

// ShellCtrls
function RegisterCustomShellTreeView: Boolean; alias : 'WSRegisterCustomShellTreeView';
begin
  Result := False;
end;

function RegisterCustomShellListView: Boolean; alias : 'WSRegisterCustomShellListView';
begin
  Result := False;
end;

function RegisterLazDeviceAPIs: Boolean; alias : 'WSRegisterLazDeviceAPIs';
begin
  Result := False;
end;

end.
