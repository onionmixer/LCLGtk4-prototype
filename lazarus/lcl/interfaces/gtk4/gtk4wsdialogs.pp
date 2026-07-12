{
 *****************************************************************************
 *                             Gtk4WSDialogs.pp                              *
 *                             ----------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSDialogs;

{$mode objfpc}{$H+}
{$I gtk4defines.inc}

interface

uses
  // Bindings
  LazGtk4, LazGlib2, LazGdk4, LazGObject2, LazPango1, LazGio2, LazGtk4_Compat,
  // RTL, FCL and LCL
  SysUtils, Classes, Graphics, Controls, Dialogs, ExtDlgs, Forms, LCLType,
  LazFileUtils, LCLStrConsts, LCLProc,
  // Widgetset
  gtk4int, gtk4widgets,
  WSDialogs;
  
type
  { TGtk4WSCommonDialog }

  TGtk4WSCommonDialog = class(TWSCommonDialog)
  private
    class procedure SetColorDialogColor(ColorSelection: PGtkColorSelectionDialog; Color: TColor);
    class procedure SetColorDialogPalette(ColorSelection: PGtkColorSelectionDialog; Palette: TStrings);
  protected
    class procedure SetCallbacks(const AGtkWidget: PGtkWidget; const AWidgetInfo: TGtk4Dialog); virtual;
    class procedure SetSizes(const AGtkWidget: PGtkWidget; const AWidgetInfo: TGtk4Dialog); virtual;
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle; override;
    class procedure ShowModal(const ACommonDialog: TCommonDialog); override;
    class procedure DestroyHandle(const ACommonDialog: TCommonDialog); override;
  end;

  { TGtk4WSFileDialog }

  TGtk4WSFileDialog = class(TWSFileDialog)
  protected
    class procedure SetCallbacks(const AGtkWidget: PGtkWidget; const AWidgetInfo: TGtk4Dialog); virtual;
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle; override;
  end;

  { TGtk4WSOpenDialog }

  TGtk4WSOpenDialog = class(TWSOpenDialog)
  protected
    class function CreateOpenDialogFilter(OpenDialog: TOpenDialog;
      Chooser: PGtkFileChooser): string; virtual;
    class procedure CreateOpenDialogHistory(OpenDialog: TOpenDialog;
      SelWidget: PGtkWidget); virtual;
    class procedure CreatePreviewDialogControl(PreviewDialog: TPreviewFileDialog;
      Chooser: PGtkFileChooser); virtual;
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle; override;
    class function QueryWSEventCapabilities(const {%H-}ACommonDialog: TCommonDialog): TCDWSEventCapabilities; override;
  end;

  { TGtk4WSSaveDialog }

  TGtk4WSSaveDialog = class(TWSSaveDialog)
  published
    class function QueryWSEventCapabilities(const {%H-}ACommonDialog: TCommonDialog): TCDWSEventCapabilities; override;
  end;

  { TGtk4WSSelectDirectoryDialog }

  TGtk4WSSelectDirectoryDialog = class(TWSSelectDirectoryDialog)
  published
    class function QueryWSEventCapabilities(const {%H-}ACommonDialog: TCommonDialog): TCDWSEventCapabilities; override;
  end;

  { TGtk4WSColorDialog }

  TGtk4WSColorDialog = class(TWSColorDialog)
  protected
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle; override;
    class function QueryWSEventCapabilities(const {%H-}ACommonDialog: TCommonDialog): TCDWSEventCapabilities; override;
  end;

  { TGtk4WSColorButton }

  TGtk4WSColorButton = class(TWSColorButton)
  published
  end;

  { TGtk4WSFontDialog }

  TGtk4WSFontDialog = class(TWSFontDialog)
  protected
  published
    class function CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle; override;
    class function QueryWSEventCapabilities(const {%H-}ACommonDialog: TCommonDialog): TCDWSEventCapabilities; override;
  end;

// forward declarations

procedure UpdateDetailView(OpenDialog: TOpenDialog);

implementation
uses gtk4procs;

  { file dialog }

type
  { TFileSelFilterEntry }

  TFileSelFilterEntry = class
  public
    Description: String;
    Mask: String;
    FilterIndex: integer;
    MenuItem: PGtkWidget;
    constructor Create(const ADescription, AMask: string);
    destructor Destroy; override;
  end;

constructor TFileSelFilterEntry.Create(const ADescription, AMask: string);
begin
  Description := ADescription;
  Mask := AMask;
  FilterIndex := 1;
  MenuItem := nil;
end;

destructor TFileSelFilterEntry.Destroy;
begin
  inherited Destroy;
end;


{------------------------------------------------------------------------------
  Function: ExtractFilterList
  Params: const Filter: string; var FilterIndex: integer;
          var ListOfPFileSelFilterEntry: TStringList
  Returns: -

  Converts a Delphi file filter of the form
  'description1|mask1|description2|mask2|...'
  into a TFPList of PFileSelFilterEntry(s).
  Multi masks:
    - multi masks like '*.pas;*.pp' are converted into multiple entries.
    - if the masks are found in the description they are adjusted
    - if the mask is not included in the description it will be concatenated
    For example:
      'Pascal files (*.pas;*.pp)|*.pas;*.lpr;*.pp;
      is converted to three filter entries:
        'Pascal files (*.pas)' + '*.pas'
        'Pascal files (*.pp)'  + '*.pp'
        'Pascal files (*.lpr)' + '*.lpr'
 ------------------------------------------------------------------------------}
procedure ExtractFilterList(const Filter: string;
  out ListOfFileSelFilterEntry: TFPList;
  SplitMultiMask: boolean);
var
  Masks: TStringList;
  CurFilterIndex: integer;

  procedure ExtractMasks(const MultiMask: string);
  var CurMaskStart, CurMaskEnd: integer;
    s: string;
  begin
    if Masks=nil then
      Masks:=TStringList.Create
    else
      Masks.Clear;
    CurMaskStart:=1;
    while CurMaskStart<=length(MultiMask) do begin
      CurMaskEnd:=CurMaskStart;
      if SplitMultiMask then begin
        while (CurMaskEnd<=length(MultiMask)) and (MultiMask[CurMaskEnd]<>';')
        do
          inc(CurMaskEnd);
      end else begin
        CurMaskEnd:=length(MultiMask)+1;
      end;
      s:=Trim(copy(MultiMask,CurMaskStart,CurMaskEnd-CurMaskStart));
      Masks.Add(s);
      CurMaskStart:=CurMaskEnd+1;
    end;
  end;

  procedure AddEntry(const Desc, Mask: string);
  var NewFilterEntry: TFileSelFilterEntry;
  begin
    NewFilterEntry:=TFileSelFilterEntry.Create(Desc,Mask);
    NewFilterEntry.FilterIndex:=CurFilterIndex;
    ListOfFileSelFilterEntry.Add(NewFilterEntry);
  end;

  // remove all but one masks from description string
  function RemoveOtherMasks(const Desc: string; MaskIndex: integer): string;
  var i, StartPos, EndPos: integer;
  begin
    Result:=Desc;
    for i:=0 to Masks.Count-1 do begin
      if i=MaskIndex then continue;
      StartPos:=Pos(Masks[i],Result);
      EndPos:=StartPos+length(Masks[i]);
      if StartPos<1 then continue;
      while (StartPos>1) and (Result[StartPos-1] in [' ',#9,';']) do
        dec(StartPos);
      while (EndPos<=length(Result)) and (Result[EndPos] in [' ',#9]) do
        inc(EndPos);
      if (StartPos>1) and (Result[StartPos-1]='(')
      and (EndPos<=length(Result)) then begin
        if (Result[EndPos]=')') then begin
          dec(StartPos);
          inc(EndPos);
        end else if Result[EndPos]=';' then begin
          inc(EndPos);
        end;
      end;
      System.Delete(Result,StartPos,EndPos-StartPos);
    end;
  end;

  procedure AddEntries(const Desc: string; const MultiMask: string);
  var i: integer;
    CurDesc: string;
  begin
    ExtractMasks(MultiMask);
    for i:=0 to Masks.Count-1 do begin
      CurDesc:=RemoveOtherMasks(Desc,i);
      if (Masks.Count>1) and (Pos(Masks[i],CurDesc)<1) then begin
        if (CurDesc='') or (CurDesc[length(CurDesc)]<>' ') then
          CurDesc:=CurDesc+' ';
        CurDesc:=CurDesc+'('+Masks[i]+')';
      end;
      AddEntry(CurDesc,Masks[i]);
    end;
    inc(CurFilterIndex);
  end;

var
  CurDescStart, CurDescEnd, CurMultiMaskStart, CurMultiMaskEnd: integer;
  CurDesc, CurMultiMask: string;
begin
  ListOfFileSelFilterEntry:=TFPList.Create;
  Masks:=nil;
  CurFilterIndex:=0;
  CurDescStart:=1;
  while CurDescStart<=length(Filter) do
  begin
    // extract next filter description
    CurDescEnd:=CurDescStart;
    while (CurDescEnd<=length(Filter)) and (Filter[CurDescEnd]<>'|') do
      inc(CurDescEnd);
    CurDesc:=copy(Filter,CurDescStart,CurDescEnd-CurDescStart);
    // extract next filter multi mask
    CurMultiMaskStart:=CurDescEnd+1;
    CurMultiMaskEnd:=CurMultiMaskStart;
    while (CurMultiMaskEnd<=length(Filter)) and (Filter[CurMultiMaskEnd]<>'|') do
      inc(CurMultiMaskEnd);
    CurMultiMask:=copy(Filter,CurMultiMaskStart,CurMultiMaskEnd-CurMultiMaskStart);
    if CurDesc='' then CurDesc:=CurMultiMask;
    // add filter(s)
    if (CurMultiMask<>'') or (CurDesc<>'') then
      AddEntries(CurDesc,CurMultiMask);
    // next filter
    CurDescStart:=CurMultiMaskEnd+1;
  end;
  Masks.Free;
end;

procedure FreeListOfFileSelFilterEntry(ListOfFileSelFilterEntry: TFPList);
var
  i: Integer;
begin
  if ListOfFileSelFilterEntry=nil then exit;
  for i:=0 to ListOfFileSelFilterEntry.Count-1 do
    TObject(ListOfFileSelFilterEntry[i]).Free;
  ListOfFileSelFilterEntry.Free;
end;

{-------------------------------------------------------------------------------
  procedure UpdateDetailView
  Params: OpenDialog: TOpenDialog
  Result: none

  Shows some OS dependent information about the current file
-------------------------------------------------------------------------------}
procedure UpdateDetailView(OpenDialog: TOpenDialog);
var
  FileDetailLabel: PGtkWidget;
  Filename, OldFilename, Details: String;
  Widget: PGtkWidget;
  AFile: PGFile;
  cPath: Pgchar;
begin
  Widget := TGtk4Dialog(OpenDialog.Handle).Widget;

  { GTK4: get_filename removed, use get_file + g_file_get_path }
  AFile := gtk4_file_chooser_get_file(PGtkFileChooser(Widget));
  if AFile <> nil then
  begin
    cPath := g_file_get_path(AFile);
    FileName := cPath;
    g_free(cPath);
    g_object_unref(PGObject(AFile));
  end
  else
    FileName := '';

  OldFilename := OpenDialog.Filename;
  if Filename = OldFilename then
    Exit;
  OpenDialog.Filename := Filename;
  // tell application, that selection has changed
  OpenDialog.DoSelectionChange;
  if (OpenDialog.OnFolderChange <> nil) and
     (ExtractFilePath(Filename) <> ExtractFilePath(OldFilename)) then
    OpenDialog.DoFolderChange;
  // show some information
  FileDetailLabel := g_object_get_data({%H-}TGtk4Dialog(OpenDialog.Handle).Widget, 'FileDetailLabel');
  if FileDetailLabel = nil then
    Exit;
  if FileExistsUTF8(Filename) then
    Details := GetFileDescription(Filename)
  else
    Details := Format(rsFileInfoFileNotFound, [Filename]);
  gtk_label_set_text(PGtkLabel(FileDetailLabel), PChar(Details));
end;


{------------------------------------------------------------------------------
  Procedure: StoreCommonDialogSetup
  Params:    ADialog: TCommonDialog
  Returns:   none

  Stores the size of a TCommonDialog.
 ------------------------------------------------------------------------------}
procedure StoreCommonDialogSetup(ADialog: TCommonDialog);
var
  DlgWindow: PGtkWidget;
begin
  if (ADialog=nil) or not ADialog.HandleAllocated then exit;
  DlgWindow := TGtk4Dialog(ADialog.Handle).Widget;
  if DlgWindow^.get_allocated_width > 0 then
    ADialog.Width := DlgWindow^.get_allocated_width;
  if DlgWindow^.get_allocated_height > 0 then
    ADialog.Height := DlgWindow^.get_allocated_height;
end;

{------------------------------------------------------------------------------
  Procedure: DestroyCommonDialogAddOns
  Params:    ADialog: TCommonDialog
  Returns:   none

  Free the memory of additional data of a TCommonDialog
 ------------------------------------------------------------------------------}
procedure DestroyCommonDialogAddOns(ADialog: TCommonDialog);
begin
  if (ADialog=nil) or (not ADialog.HandleAllocated) then exit;
  { GTK4: GtkFileSelection removed. Dialog cleanup handled by GtkFileChooserNative destroy. }
end;

// ---------------------- signals ----------------------------------------------

procedure gtkFileChooserSelectionChangedCB(Chooser: PGtkFileChooser;
  Data: Pointer); cdecl;
var
  theDialog: TFileDialog;
begin
  theDialog := TFileDialog(TGtk4Dialog(Data).CommonDialog);
  if theDialog is TOpenDialog then
    UpdateDetailView(TOpenDialog(theDialog));
end;

{ History combo box selection changed — navigate to the selected path }
procedure Gtk4HistoryComboChangedCB(combo: PGtkComboBoxText;
  data: gpointer); cdecl;
var
  ActiveText: Pgchar;
  AFile: PGFile;
begin
  ActiveText := gtk_combo_box_text_get_active_text(combo);
  if (ActiveText = nil) or (ActiveText^ = #0) then
  begin
    if ActiveText <> nil then
      g_free(ActiveText);
    Exit;
  end;
  AFile := g_file_new_for_path(ActiveText);
  gtk4_file_chooser_set_current_folder(PGtkFileChooser(data), AFile, nil);
  g_object_unref(PGObject(AFile));
  g_free(ActiveText);
end;

procedure Gtk4FileChooserResponseCB(widget: PGtkFileChooser; arg1: TGtkResponseType;
  data: gpointer); cdecl;

  procedure AddFile(List: TStrings; const NewFile: string);
  var
    i: Integer;
  begin
    for i := 0 to List.Count-1 do
      if List[i] = NewFile then
        Exit;
    List.Add(NewFile);
  end;

  function SkipDirectory(const AName: String): Boolean;
  begin
    Result := (gtk_file_chooser_get_action(Widget) =  GTK_FILE_CHOOSER_ACTION_OPEN) and
      DirectoryExists(AName);
  end;

var
  TheDialog: TFileDialog;
  cFilename: Pgchar;
  AFile: PGFile;
  AFilesModel: PGListModel;
  Files: TStringList;
  i, nItems: guint;
begin
  theDialog := TFileDialog(TGtk4Dialog(Data).CommonDialog);

  { GtkFileChooserNative emits exactly three responses (gtkfilechoosernative.c):
    GTK_RESPONSE_ACCEPT (accepted), GTK_RESPONSE_CANCEL (cancel button) and
    GTK_RESPONSE_DELETE_EVENT (dialog dismissed, e.g. Escape/close). Mapping
    only CANCEL to cancel turned an Escape into a false OK result
    (runtime-confirmed: Open/Save/SelectDirectory returned Execute=True on
    Escape). Treat anything that is not an accept as cancel.
    GTK_RESPONSE_OK is included for safety with plain GtkDialog choosers. }
  if (arg1 <> GTK_RESPONSE_ACCEPT) and (arg1 <> GTK_RESPONSE_OK) then
  begin
    TheDialog.UserChoice := mrCancel;
    Exit;
  end;

  if theDialog is TOpenDialog then
  begin
    if ofAllowMultiSelect in TOpenDialog(theDialog).Options then
    begin
      TheDialog.FileName := '';
      Files := TStringList(TheDialog.Files);
      Files.Clear;
      { GTK4: get_filenames removed, use get_files (returns GListModel of GFile) }
      AFilesModel := gtk4_file_chooser_get_files(PGtkFileChooser(widget));
      if AFilesModel <> nil then
      begin
        nItems := g_list_model_get_n_items(AFilesModel);
        for i := 0 to nItems - 1 do
        begin
          AFile := PGFile(g_list_model_get_item(AFilesModel, i));
          if AFile <> nil then
          begin
            cFilename := g_file_get_path(AFile);
            if (cFilename <> nil) and not SkipDirectory(cFilename) then
              AddFile(Files, cFilename);
            if cFilename <> nil then
              g_free(cFilename);
            g_object_unref(PGObject(AFile));
          end;
        end;
        g_object_unref(PGObject(AFilesModel));
      end;
    end
    else
      TheDialog.Files.Clear;
  end;

  { GTK4: get_filename removed, use get_file + g_file_get_path }
  AFile := gtk4_file_chooser_get_file(PGtkFileChooser(widget));
  if AFile <> nil then
  begin
    cFilename := g_file_get_path(AFile);
    if (cFilename <> nil) and SkipDirectory(cFilename) then
      TheDialog.FileName := ''
    else if cFilename <> nil then
      TheDialog.FileName := cFilename;
    if cFilename <> nil then
      g_free(cFilename);
    g_object_unref(PGObject(AFile));
    if (TheDialog is TOpenDialog) and (not (ofAllowMultiSelect in TOpenDialog(theDialog).Options)) then
      TheDialog.Files.Add(TheDialog.FileName);
  end;

  theDialog.UserChoice := mrOK;
end;

procedure Gtk4FileChooserNotifyCB(dialog: PGObject; pspec: PGParamSpec;
  user_data: gpointer); cdecl;
var
  TheDialog: TFileDialog;
  GtkFilter, AItem: PGtkFileFilter;
  FiltersModel: PGListModel;
  NewFilterIndex: Integer;
  i, n: guint;
begin
  if pspec^.name = 'filter' then
  begin // filter changed
    theDialog := TFileDialog(TGtk4Dialog(user_data).CommonDialog);
    GtkFilter := gtk_file_chooser_get_filter(PGtkFileChooser(dialog));
    { GTK4: gtk_file_chooser_list_filters removed. Use get_filters (GListModel). }
    FiltersModel := gtk4_file_chooser_get_filters(PGtkFileChooser(dialog));
    n := g_list_model_get_n_items(FiltersModel);
    if (GtkFilter = nil) and (theDialog.Filter <> '') then
    begin
      // Either we don't have filter or gtk reset it.
      // Gtk resets filter if we set both filename and filter but filename
      // does not fit into filter.
      i := theDialog.FilterIndex - 1;
      if i < n then
      begin
        AItem := PGtkFileFilter(g_list_model_get_item(FiltersModel, i));
        gtk_file_chooser_set_filter(PGtkFileChooser(dialog), AItem);
        g_object_unref(PGObject(AItem));
      end;
    end
    else
    begin
      // Find the index of the current filter in the model
      NewFilterIndex := -1;
      for i := 0 to n - 1 do
      begin
        AItem := PGtkFileFilter(g_list_model_get_item(FiltersModel, i));
        if AItem = GtkFilter then
        begin
          NewFilterIndex := i;
          g_object_unref(PGObject(AItem));
          Break;
        end;
        g_object_unref(PGObject(AItem));
      end;
      theDialog.IntfFileTypeChanged(NewFilterIndex + 1);
    end;
    g_object_unref(PGObject(FiltersModel));
  end;
end;

// ------------------------ Signals --------------------------------------------

{ GTK4: gtkDialogSelectRowCB removed. GtkFileSelection/GtkCList not available in GTK4.
  File selection row handling is done via GtkFileChooser selection-changed signal. }

{-------------------------------------------------------------------------------
  function gtkDialogHelpclickedCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called, whenever the user clicks the help button in a
  commondialog
-------------------------------------------------------------------------------}
function gtkDialogHelpclickedCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
var
  theDialog : TCommonDialog;
begin
  Result := False;
  if (Widget=nil) then ;
  theDialog := TCommonDialog(TGtk4Dialog(data).CommonDialog);
  if theDialog is TOpenDialog then begin
    if TOpenDialog(theDialog).OnHelpClicked<>nil then
      TOpenDialog(theDialog).OnHelpClicked(theDialog);
  end;
end;

{-------------------------------------------------------------------------------
  function gtkDialogApplyclickedCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called, whenever the user clicks the Apply button in a
  commondialog
-------------------------------------------------------------------------------}
function gtkDialogApplyclickedCB(widget: PGtkWidget; data: gPointer): GBoolean;
  cdecl;
var
  theDialog : TCommonDialog;
  FontName: string;
  ALogFont: TLogFont;
  FontChooser: PGtkFontChooser;
  FontDesc: PPangoFontDescription;
  APangoFontFamily: PPangoFontFamily;
begin
  Result := False;

  if (Widget=nil) then ;
  theDialog := TCommonDialog(TGtk4Dialog(data).CommonDialog);
  if (theDialog is TFontDialog)
  and (fdApplyButton in TFontDialog(theDialog).Options)
  and (Assigned(TFontDialog(theDialog).OnApplyClicked)) then
  begin
    FontChooser := PGtkFontChooser(TGtk4Dialog(data).Widget);
    APangoFontFamily := gtk_font_chooser_get_font_family(FontChooser);
    FontName := APangoFontFamily^.get_name;
    if IsFontNameXLogicalFontDesc(FontName) then
    begin
      // extract basic font attributes from the font name in XLFD format
      ALogFont:=XLFDNameToLogFont(FontName);
      TFontDialog(theDialog).Font.Assign(ALogFont);
      // set the font name in XLFD format
      // a font name in XLFD format overrides in the gtk interface all other font
      // settings.
      TFontDialog(theDialog).Font.Name := FontName;
    end else begin
      FontDesc := pango_font_description_from_string(PChar(FontName));
      with TFontDialog(theDialog).Font do
      begin
        BeginUpdate;
        Size := pango_font_description_get_size(FontDesc) div PANGO_SCALE;
        if pango_font_description_get_weight(FontDesc) >= PANGO_WEIGHT_BOLD then
          Style := Style + [fsBold]
        else
          Style := Style - [fsBold];
        if pango_font_description_get_style(FontDesc) > PANGO_STYLE_NORMAL then
          Style := Style + [fsItalic]
        else
          Style := Style - [fsItalic];
        Name := pango_font_description_get_family(FontDesc);
        EndUpdate;
      end;
      pango_font_description_free(FontDesc);
    end;
    TFontDialog(theDialog).OnApplyClicked(theDialog);
  end;
end;

function gtkDialogOKclickedCB( widget: PGtkWidget; data: gPointer) : GBoolean; cdecl;
var
  theDialog : TCommonDialog;
  Fpointer : Pointer;
  FontName : String;
  cFontName: PgChar;
  ALogFont  : TLogFont;
  AFile: PGFile;
  AFilesModel: PGListModel;
  nItems, fi: guint;
  cPath: Pgchar;

  FontDesc: PPangoFontDescription;

  DirName  : string;
  FileName : string;
  Files: TStringList;
  CurFilename: string;
  Argba: TGdkRGBA;
  ARed: Byte;
  AGreen: Byte;
  ABlue: Byte;

  function CheckOpenedFilename(var AFilename: string): boolean;
  begin
    Result:=true;

    // maybe file already exists
    if (ofOverwritePrompt in TOpenDialog(theDialog).Options) and
      FileExistsUTF8(AFilename) then
    begin
      Result := MessageDlg(rsfdOverwriteFile,
                         Format(rsfdFileAlreadyExists,[AFileName]),
                         mtConfirmation,[mbOk,mbCancel],0)=mrOk;
      if not Result then exit;
    end;
  end;

  procedure AddFile(List: TStrings; const NewFile: string);
  var
    i: Integer;
  begin
    for i:=0 to List.Count-1 do
      if List[i]=NewFile then exit;
    List.Add(NewFile);
  end;

begin
  Result := True;
  if (Widget=nil) then ;
  theDialog := TCommonDialog(TGtk4Dialog(data).CommonDialog);
  FPointer := Pointer(TGtk4Dialog(theDialog.Handle).Widget);

  if theDialog is TFileDialog then
  begin
    { GTK4: get_filename removed, use get_file + g_file_get_path }
    AFile := gtk4_file_chooser_get_file(PGtkFileChooser(FPointer));
    if AFile <> nil then
    begin
      cPath := g_file_get_path(AFile);
      FileName := cPath;
      g_free(cPath);
      g_object_unref(PGObject(AFile));
    end
    else
      FileName := '';

    if theDialog is TOpenDialog then
    begin
      // check extra options
      if ofAllowMultiSelect in TOpenDialog(theDialog).Options then
      begin
        DirName:=ExtractFilePath(FileName);
        TFileDialog(data).FileName := '';
        Files:=TStringList(TFileDialog(theDialog).Files);
        Files.Clear;
        if (Filename<>'') then
        begin
          Result:=CheckOpenedFilename(Filename);
          if not Result then exit;
          AddFile(Files,FileName);
        end;
        { GTK4: get_filenames removed, use get_files (returns GListModel of GFile) }
        AFilesModel := gtk4_file_chooser_get_files(PGtkFileChooser(FPointer));
        if AFilesModel <> nil then
        begin
          nItems := g_list_model_get_n_items(AFilesModel);
          for fi := 0 to nItems - 1 do
          begin
            AFile := PGFile(g_list_model_get_item(AFilesModel, fi));
            if AFile <> nil then
            begin
              cPath := g_file_get_path(AFile);
              CurFilename := cPath;
              if (CurFilename<>'') and (Files.IndexOf(CurFilename)<0) then
              begin
                CurFilename:=DirName+cPath;
                Result:=CheckOpenedFilename(CurFilename);
                if not Result then
                begin
                  g_free(cPath);
                  g_object_unref(PGObject(AFile));
                  g_object_unref(PGObject(AFilesModel));
                  exit;
                end;
                Files.Add(CurFilename);
              end;
              g_free(cPath);
              g_object_unref(PGObject(AFile));
            end;
          end;
          g_object_unref(PGObject(AFilesModel));
        end;
      end
      else
      begin
        Result:=CheckOpenedFilename(Filename);
        if not Result then exit;
        TFileDialog(TGtk4Dialog(data).CommonDialog).FileName := Filename;
      end;
    end else
      TFileDialog(TGtk4Dialog(data).CommonDialog).FileName := Filename;
  end else
  if theDialog is TColorDialog then
  begin
    { GTK4: Use GtkColorChooserDialog API directly }
    PGtkColorChooser(FPointer)^.get_rgba(@Argba);
    ARed := Byte(Round(Argba.red * 255));
    AGreen := Byte(Round(Argba.green * 255));
    ABlue := Byte(Round(Argba.blue * 255));
    TColorDialog(theDialog).Color := RGBToColor(ARed, AGreen, ABlue);
    {$IFDEF VerboseColorDialog}
    DebugLn('gtkDialogOKclickedCB ',DbgS(TColorDialog(theDialog).Color));
    {$ENDIF}
  end else
  if theDialog is TFontDialog then
  begin
    { gtk_font_chooser_get_font returns a newly-allocated string — must g_free }
    cFontName := gtk_font_chooser_get_font(PGtkFontChooser(FPointer));
    FontName := cFontName;
    g_free(cFontName);

    if IsFontNameXLogicalFontDesc(FontName) then
    begin
      ALogFont:=XLFDNameToLogFont(FontName);
      TFontDialog(theDialog).Font.Assign(ALogFont);
      TFontDialog(theDialog).Font.Name := FontName;
    end else
    begin
      FontDesc := pango_font_description_from_string(PChar(FontName));
      with TFontDialog(theDialog).Font do
      begin
        BeginUpdate;
        Size := pango_font_description_get_size(FontDesc) div PANGO_SCALE;
        if pango_font_description_get_weight(FontDesc) >= PANGO_WEIGHT_BOLD then
          Style := Style + [fsBold]
        else
          Style := Style - [fsBold];
        if pango_font_description_get_style(FontDesc) > PANGO_STYLE_NORMAL then
          Style := Style + [fsItalic]
        else
          Style := Style - [fsItalic];
        Name := pango_font_description_get_family(FontDesc);
        EndUpdate;
      end;
      pango_font_description_free(FontDesc);
    end;

  end;

  StoreCommonDialogSetup(theDialog);
  theDialog.UserChoice := mrOK;

end;

{-------------------------------------------------------------------------------
  function gtkDialogCancelclickedCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called, whenever the user clicks the cancel button in a
  commondialog
-------------------------------------------------------------------------------}
function gtkDialogCancelclickedCB(widget: PGtkWidget; data: gPointer): GBoolean;
  cdecl;
var
  theDialog : TCommonDialog;
begin
  Result := False;
  if (Widget=nil) then ;
  theDialog := TCommonDialog(data);
  if theDialog is TFileDialog then
  begin
    TFileDialog(data).FileName := '';
  end;
  StoreCommonDialogSetup(theDialog);
  theDialog.UserChoice := mrCancel;
end;

{-------------------------------------------------------------------------------
  function GTKDialogRealizeCB
  Params: Widget: PGtkWidget; Data: Pointer
  Result: GBoolean

  This function is called, whenever a commondialog window is realized
-------------------------------------------------------------------------------}
function GTKDialogRealizeCB(Widget: PGtkWidget; Data: Pointer): GBoolean; cdecl;
var
  LCLComponent: TObject;
  AHandle: HWND;
begin
  Result := False;
  if (Data=nil) then ;
  { GTK4: gdk_window_set_events/get_events removed. Event masks no longer exist.
    Key events are handled via GtkEventControllerKey which is already connected
    in InitializeWidget. No action needed here. }
  AHandle := HwndFromGtkWidget(Widget);
  if (AHandle <> 0) and (wtDialog in TGtk4Widget(AHandle).WidgetType) then
  begin
    LCLComponent := TGtk4Dialog(AHandle).CommonDialog;
    if LCLComponent is TCommonDialog then
      TCommonDialog(LCLComponent).DoShow;
  end;
  Result := True;
end;

{-------------------------------------------------------------------------------
  function gtkDialogCloseQueryCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called, before a commondialog is destroyed
-------------------------------------------------------------------------------}
function gtkDialogCloseQueryCB(widget: PGtkWidget; data: gPointer): GBoolean;
  cdecl;
var
  theDialog : TCommonDialog;
  CanClose: boolean;
  AHandle: HWND;
begin
  Result := False; // true = do nothing, false = destroy or hide window
  if (Data=nil) then ;
  // data is not the commondialog. Get it manually.
  AHandle := HwndFromGtkWidget(Widget);
  if (AHandle <> 0) and (wtDialog in TGtk4Widget(AHandle).WidgetType) then
  begin
    theDialog := TGtk4Dialog(AHandle).CommonDialog;
    if theDialog = nil then exit;
    if theDialog.OnCanClose<>nil then
    begin
      CanClose:=True;
      theDialog.DoCanClose(CanClose);
      Result := not CanClose;
    end;
    if not Result then
    begin
      StoreCommonDialogSetup(theDialog);
      DestroyCommonDialogAddOns(theDialog);
    end;
  end;
end;

{-------------------------------------------------------------------------------
  function gtkDialogDestroyCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called when a commondialog is destroyed (caused a crash, removed)
-------------------------------------------------------------------------------
function gtkDialogDestroyCB(widget: PGtkWidget; data: gPointer): GBoolean; cdecl;
begin
  Result := True;
  if (Widget=nil) then ;
  TCommonDialog(data).UserChoice := mrCancel;
  TCommonDialog(data).Close;
end;
}
{ GTK4: GTKDialogKeyUpDownCB removed — key-press-event/key-release-event
  signals don't exist in GTK4. Dialogs handle Escape/Enter natively. }

{-------------------------------------------------------------------------------
  function GTKDialogFocusInCB
  Params: widget: PGtkWidget; data: gPointer
  Result: GBoolean

  This function is called, when a widget of a commondialog gets focus
-------------------------------------------------------------------------------}
function GTKDialogFocusInCB(widget: PGtkWidget; data: gPointer): GBoolean;
  cdecl;
begin
  Result := False;
  if (Data=nil) then ;
  if (Widget=nil) then ;
end;

{ GTK4: GTKDialogMenuActivateCB removed. GtkFileSelection menu system
  not available in GTK4. Filter and history handled via GtkFileChooser
  and GtkComboBoxText in CreateOpenDialogHistory. }

// ---------------------- END OF signals ---------------------------------------

{ TGtk4WSOpenDialog }

class function TGtk4WSOpenDialog.CreateOpenDialogFilter(
  OpenDialog: TOpenDialog; Chooser: PGtkFileChooser): string;
var
  ListOfFileSelFilterEntry: TFPList;
  i, j, k: integer;
  GtkFilter, GtkSelFilter: PGtkFileFilter;
  MaskList: TStringList;
  FilterEntry: TFileSelFilterEntry;
  FilterIndex: Integer;
begin
  FilterIndex := OpenDialog.FilterIndex;
  ExtractFilterList(OpenDialog.Filter, ListOfFileSelFilterEntry, false);
  GtkSelFilter := nil;
  if ListOfFileSelFilterEntry.Count > 0 then
  begin
    j := 1;
    MaskList := TStringList.Create;
    MaskList.Delimiter := ';';
    for i := 0 to ListOfFileSelFilterEntry.Count-1 do
    begin
      GtkFilter := gtk_file_filter_new();
      FilterEntry := TFileSelFilterEntry(ListOfFileSelFilterEntry[i]);
      MaskList.DelimitedText := FilterEntry.Mask;

      for k := 0 to MaskList.Count - 1 do
        if pos('/',MaskList.Strings[k])>0 then
          gtk_file_filter_add_mime_type(GtkFilter, PgChar(MaskList.Strings[k]))
        else
          gtk_file_filter_add_pattern(GtkFilter, PgChar(MaskList.Strings[k]));

      gtk_file_filter_set_name(GtkFilter, PgChar(FilterEntry.Description));
      gtk_file_chooser_add_filter(Chooser, GtkFilter);
      if j = FilterIndex then
        GtkSelFilter := GtkFilter;

      Inc(j);
      GtkFilter := nil;
    end;
    MaskList.Free;
  end;

  FreeListOfFileSelFilterEntry(ListOfFileSelFilterEntry);

  if GtkSelFilter <> nil then
    gtk_file_chooser_set_filter(Chooser, GtkSelFilter);

  Result := 'hm'; { Don't use '' as null return as this is used for *.* }
end;

class procedure TGtk4WSOpenDialog.CreateOpenDialogHistory(
  OpenDialog: TOpenDialog; SelWidget: PGtkWidget);
var
  i: integer;
  s: string;
  HBox: PGtkBox;
  LabelWidget: PGtkWidget;
  ComboWidget: PGtkComboBoxText;
  ContentArea: PGtkBox;
begin
  { GTK4: gtk_file_chooser_set_extra_widget and gtk_option_menu removed.
    Use GtkComboBoxText in the dialog's content area instead. }
  if OpenDialog.HistoryList.Count <= 0 then Exit;

  ContentArea := gtk_dialog_get_content_area(PGtkDialog(SelWidget));

  // Create horizontal box for History label + ComboBox
  HBox := gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 4);
  gtk_widget_set_margin_start(PGtkWidget(HBox), 8);
  gtk_widget_set_margin_end(PGtkWidget(HBox), 8);
  gtk_widget_set_margin_bottom(PGtkWidget(HBox), 4);

  // Create label
  LabelWidget := PGtkWidget(TGtkLabel.new(PChar(rsgtkHistory)));
  gtk4_box_append(HBox, LabelWidget);

  // Create ComboBoxText and populate with history entries
  ComboWidget := gtk_combo_box_text_new;
  for i := 0 to OpenDialog.HistoryList.Count - 1 do
  begin
    s := OpenDialog.HistoryList[i];
    if s <> '' then
      gtk_combo_box_text_append_text(ComboWidget, PGChar(s));
  end;
  gtk4_box_append(HBox, PGtkWidget(ComboWidget));

  // Connect selection changed — navigate to selected history path
  g_signal_connect_data(PGObject(ComboWidget), 'changed',
    TGCallback(@Gtk4HistoryComboChangedCB), SelWidget, nil, G_CONNECT_DEFAULT);

  // Add to dialog content area
  gtk4_box_append(ContentArea, PGtkWidget(HBox));
end;

class procedure TGtk4WSOpenDialog.CreatePreviewDialogControl(
  PreviewDialog: TPreviewFileDialog; Chooser: PGtkFileChooser);
var
  PreviewWidget,SubWidget: PGtkWidget;
  AControl: TPreviewFileControl;
  AHnd,Ahnd1:TGtk4Widget;
  Win,SubWin:TWinControl;
begin
  AControl := PreviewDialog.PreviewFileControl;
  if AControl = nil then Exit;

  AHnd:=TGtk4CustomControl(AControl.Handle);
  PreviewWidget := AHnd.Widget;

  g_object_set_data(PGObject(PreviewWidget),'LCLPreviewFixed',PreviewWidget);
  gtk_widget_set_size_request(PreviewWidget,AControl.Width,AControl.Height);

  // manually resize the preview objects, it seems, automatic resize is not
  // working when parent of LCL control is not a LCL control.
  if (AControl.ControlCount>0) and (AControl.Controls[0] is TWinControl) then begin
    Win := TWinControl(AControl.Controls[0]);  // groupbox
    SubWin := TWinControl(Win.Controls[0]);    // image
    AHnd1:=TGtk4Widget(Win.Handle);
    SubWidget:=AHnd1.Widget;
    AHnd1.SetParent(Ahnd,0,0);
    gtk_widget_set_size_request({%H-}SubWidget, AControl.Width, AControl.Height);
    SubWin.width := AControl.Width-4;          // skip borders
    SubWin.height := AControl.Height-15;       //
  end;

  { GTK4: gtk_file_chooser_set_preview_widget removed.
    Add the preview widget to the dialog's content area instead.
    The preview appears below the file list. }
  gtk4_box_append(
    PGtkBox(gtk_dialog_get_content_area(PGtkDialog(Chooser))),
    PreviewWidget);
end;

{
  Adds some functionality to a gtk file selection dialog.
  - multiselection
  - range selection
  - close on escape
  - file information
  - history pulldown
  - filter pulldown
  - preview control

  requires: gtk+ 2.6
}
class function TGtk4WSOpenDialog.CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle;
var
  OpenDialog: TOpenDialog absolute ACommonDialog;
  HelpButton: PGtkWidget;
  InitialFilename: String;
  Dlg: TGtk4Dialog;
  Chooser: PGtkFileChooser;
  AFile: PGFile;
begin
  Dlg := TGtk4FileDialog.Create(ACommonDialog);
  Result := TLCLHandle(Dlg);
  Chooser := PGtkFileChooser(Dlg.Widget);
  TGtk4WSFileDialog.SetCallbacks(Dlg.Widget, Dlg);

  { InitialDir and the Save initial name are already applied in
    TGtk4FileDialog.Create. }

  { GtkFileChooserNative is a portal / out-of-process dialog and cannot host
    custom widgets, so the history combo, preview widget and Help button are
    not available (ofShowHelp is ignored). 'selection-changed' is never emitted
    by the native dialog, so it is not connected. Multi-select and filters work
    through the GtkFileChooser interface. }
  if ofAllowMultiSelect in OpenDialog.Options then
    gtk_file_chooser_set_select_multiple(Chooser, True);

  // Filter
  CreateOpenDialogFilter(OpenDialog, Chooser);

  { Initial filename: Open selects an existing file via set_file. Save's
    proposed name is already set via set_current_name in
    TGtk4FileDialog.Create, so Save skips this. }
  if not OpenDialog.InheritsFrom(TSaveDialog) then
  begin
    InitialFilename := TrimFilename(OpenDialog.FileName);
    if InitialFilename <> '' then
    begin
      if not FilenameIsAbsolute(InitialFilename) and (OpenDialog.InitialDir <> '') then
        InitialFilename := TrimFilename(OpenDialog.InitialDir + PathDelim + InitialFilename);
      if not FilenameIsAbsolute(InitialFilename) then
        InitialFilename := CleanAndExpandFilename(InitialFilename);
      { GTK4: set_filename removed, use set_file }
      AFile := g_file_new_for_path(Pgchar(InitialFilename));
      gtk4_file_chooser_set_file(PGtkFileChooser(Chooser), AFile, nil);
      g_object_unref(PGObject(AFile));
    end;
  end;

end;

{ TGtk4WSFileDialog }


class procedure TGtk4WSFileDialog.SetCallbacks(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: TGtk4Dialog);
begin
  { AGtkWidget is a GtkFileChooserNative (a GObject, not a GtkWidget). It has no
    close-request/realize signals, so we do NOT call the base
    TGtk4WSCommonDialog.SetCallbacks. Connect only the native 'response' (ends
    the DoExecute wait loop via UserChoice) and 'notify' (FilterIndex). }
  g_signal_connect_data(AGtkWidget, 'response', TGCallback(@Gtk4FileChooserResponseCB), AWidgetInfo, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AGtkWidget, 'notify', TGCallback(@Gtk4FileChooserNotifyCB), AWidgetInfo, nil, G_CONNECT_DEFAULT);
end;

{
  Creates a new TFile/Open/SaveDialog
}
class function TGtk4WSFileDialog.CreateHandle(const ACommonDialog: TCommonDialog
  ): TLCLHandle;
begin
  Result := TLCLHandle(TGtk4FileDialog.Create(ACommonDialog));
end;

{ TGtk4WSCommonDialog }

{------------------------------------------------------------------------------
  Method: SetColorDialogColor
  Params:  ColorSelection : a gtk color selection dialog;
           Color          : the color to select
  Returns: nothing

  Set the color of the color selection dialog
 ------------------------------------------------------------------------------}
class procedure TGtk4WSCommonDialog.SetColorDialogColor(ColorSelection: PGtkColorSelectionDialog;
  Color: TColor);
var
  rgba: TGdkRGBA;
begin
  { GTK4: GtkColorChooserDialog implements GtkColorChooser interface.
    The pointer is actually a GtkColorChooserDialog, cast to PGtkColorChooser. }
  TGtk4newColorSelectionDialog.color_to_rgba(Color, rgba);
  PGtkColorChooser(ColorSelection)^.set_rgba(@rgba);
end;

class procedure TGtk4WSCommonDialog.SetColorDialogPalette(
  ColorSelection: PGtkColorSelectionDialog; Palette: TStrings);
var
  Colors: array[0..15] of TGdkRGBA;
  i, AIndex, Count: Integer;
  AColor: TColor;
begin
  { GTK4: Use gtk_color_chooser_add_palette to set custom colors.
    The Palette TStrings format is "ColorA=RRGGBB", "ColorB=RRGGBB", etc.
    Indices A..P map to 0..15. }
  if (Palette = nil) or (Palette.Count = 0) then
    Exit;
  Count := 0;
  for i := 0 to Palette.Count - 1 do
    if ExtractColorIndexAndColor(Palette, i, AIndex, AColor) then
      if (AIndex >= 0) and (AIndex <= 15) then
      begin
        TGtk4newColorSelectionDialog.color_to_rgba(AColor, Colors[AIndex]);
        if AIndex >= Count then
          Count := AIndex + 1;
      end;
  if Count > 0 then
    PGtkColorChooser(ColorSelection)^.add_palette(
      GTK_ORIENTATION_HORIZONTAL, 8, Count, @Colors[0]);
end;


class procedure TGtk4WSCommonDialog.SetCallbacks(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: TGtk4Dialog);
begin
  { GTK4: 'delete-event' renamed to 'close-request'.
    'key-press-event'/'key-release-event' removed — GTK4 dialogs handle
    Escape/Enter natively; GTKDialogKeyUpDownCB body was empty. }
  g_signal_connect_data(AGtkWidget,
    'close-request', TGCallback(@gtkDialogCloseQueryCB), AWidgetInfo, nil, G_CONNECT_DEFAULT);
  g_signal_connect_data(AGtkWidget,
    'realize', TGCallback(@GTKDialogRealizeCB), AWidgetInfo, nil, G_CONNECT_DEFAULT);
end;

class procedure TGtk4WSCommonDialog.SetSizes(const AGtkWidget: PGtkWidget;
  const AWidgetInfo: TGtk4Dialog);
var
  NewWidth, NewHeight: integer;
begin
  // set default size
  NewWidth := TCommonDialog(AWidgetInfo.CommonDialog).Width;
  if NewWidth <= 0 then
    NewWidth := -2; // -2 = let the window manager decide
  NewHeight := TCommonDialog(AWidgetInfo.CommonDialog).Height;
  if NewHeight<=0 then
    NewHeight := -2; // -2 = let the window manager decide
  if (NewWidth > 0) or (NewHeight > 0) then
    gtk_window_set_default_size(PGtkWindow(AGtkWidget), NewWidth, NewHeight);
end;

class function TGtk4WSCommonDialog.CreateHandle(
  const ACommonDialog: TCommonDialog): TLCLHandle;
begin
  Result := 0;
end;

class procedure TGtk4WSCommonDialog.ShowModal(const ACommonDialog: TCommonDialog);
var
  AGtkWindow: PGtkWidget;
  ActiveHandle: HWND;
  Dlg: TGtk4Dialog;
  CanClose: Boolean;
begin
  if not ACommonDialog.HandleAllocated then
    exit;
  Dlg := TGtk4Dialog(ACommonDialog.Handle);

  if Dlg is TGtk4FileDialog then
  begin
    { GtkFileChooserNative path — Dlg.Widget is a GtkNativeDialog (GObject),
      not a GtkWidget, so it uses the gtk_native_dialog_* API. Modality and
      transient parent still apply. }
    ActiveHandle := GTK4WidgetSet.GetActiveWindow;
    if ActiveHandle = 0 then
    begin
      if (Screen.ActiveForm <> nil) and Screen.ActiveForm.HandleAllocated then
        ActiveHandle := Screen.ActiveForm.Handle
      else if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
        ActiveHandle := Application.MainForm.Handle;
    end;
    gtk_native_dialog_set_modal(PGtkNativeDialog(Dlg.Widget), True);
    if ActiveHandle <> 0 then
      gtk_native_dialog_set_transient_for(PGtkNativeDialog(Dlg.Widget),
        PGtkWindow(TGtk4Widget(ActiveHandle).Widget));
    gtk_native_dialog_show(PGtkNativeDialog(Dlg.Widget));
    { Run the wait loop here instead of leaving it to TCommonDialog.DoExecute.
      GtkFileChooserNative hides itself after emitting 'response', but the
      DoExecute veto flow assumes the dialog outlives the check: when
      OnCanClose returns False it resets UserChoice to mrNone and pumps for
      another response that a hidden native dialog can never produce — the
      application stalled forever (runtime-proven). Performing DoCanClose
      here lets a vetoed accept re-present the still-live native dialog.
      Cancel responses skip DoCanClose so the LCL loop keeps its standard
      cancel bookkeeping (TFileDialog.DoCanClose fires OnCanClose only for
      mrOK anyway). }
    repeat
      if ACommonDialog.UserChoice = mrOK then
      begin
        CanClose := True;
        ACommonDialog.DoCanClose(CanClose);
        { The OnCanClose handler is user code and may have called Close,
          which destroys the handle and frees the cached TGtk4Dialog —
          re-validate and re-acquire before touching the native dialog. }
        if not ACommonDialog.HandleAllocated then
          break;
        Dlg := TGtk4Dialog(ACommonDialog.Handle);
        if not CanClose then
        begin
          ACommonDialog.UserChoice := mrNone;
          gtk_native_dialog_show(PGtkNativeDialog(Dlg.Widget));
        end;
      end;
      if (ACommonDialog.UserChoice <> mrNone) or Application.Terminated or
         (not ACommonDialog.HandleAllocated) then
        break;
      Application.HandleMessage;
    until False;
    exit;
  end;

  AGtkWindow := Dlg.Widget;
  if not Gtk4IsWidget(AGtkWindow) then
    raise Exception.Create('TGtk4WSCommonDialog.ShowModal error');
  { GTK4: set_position removed. Window positioning handled by compositor. }
  PGtkDialog(AGtkWindow)^.set_application(GTK4WidgetSet.Gtk4Application);
  PGtkDialog(AGtkWindow)^.set_modal(True);
  { Set transient parent for proper modal behavior. GetActiveWindow relies on
    GtkWindow.is_active, which can momentarily be false for every form when a
    dialog is being brought up (hence the "GtkDialog mapped without a transient
    parent" warning). Fall back to the active form, then the main form, so the
    dialog always gets a real parent for stacking/focus. }
  ActiveHandle := GTK4WidgetSet.GetActiveWindow;
  if ActiveHandle = 0 then
  begin
    if (Screen.ActiveForm <> nil) and Screen.ActiveForm.HandleAllocated then
      ActiveHandle := Screen.ActiveForm.Handle
    else if (Application.MainForm <> nil) and Application.MainForm.HandleAllocated then
      ActiveHandle := Application.MainForm.Handle;
  end;
  if ActiveHandle <> 0 then
    PGtkWindow(AGtkWindow)^.set_transient_for(
      PGtkWindow(TGtk4Widget(ActiveHandle).Widget));
  if ACommonDialog is TColorDialog then
  begin
    SetColorDialogColor(PGtkColorSelectionDialog(AGtkWindow),
                        TColorDialog(ACommonDialog).Color);
    SetColorDialogPalette(PGtkColorSelectionDialog(AGtkWindow),
      TColorDialog(ACommonDialog).CustomColors);
  end;
  { GTK4: gtk_dialog_run() removed. Just present the dialog.
    DoExecute's modal loop handles event processing via
    Application.HandleMessage until UserChoice is set by
    response/close/destroy callbacks. }
  PGtkWidget(AGtkWindow)^.show;
  PGtkDialog(AGtkWindow)^.present;
end;

class procedure TGtk4WSCommonDialog.DestroyHandle(
  const ACommonDialog: TCommonDialog);
var
  DrainCount: Integer;
begin
  if ACommonDialog.HandleAllocated then
  begin
    { GtkFileChooserDialog (SAVE action) queues file-exists / overwrite checks
      as GTask async when the location entry changes or a response is confirmed.
      In our manual message loop the dialog is destroyed right after the
      response, so a still-queued callback runs later against the freed
      location_entry (gtk_editable_get_text on a non-editable) → EAccessViolation
      inside g_main_context_dispatch. Let the queued callbacks finish against the
      still-live dialog before destroying it. Bounded so a self-refilling queue
      can't spin forever. }
    DrainCount := 0;
    while (g_main_context_pending(nil)) and (DrainCount < 100) do
    begin
      g_main_context_iteration(nil, False);
      Inc(DrainCount);
    end;
    TGtk4Dialog(ACommonDialog.Handle).Free;
  end;
end;

{ TGtk4WSColorDialog }

class function TGtk4WSColorDialog.CreateHandle(
  const ACommonDialog: TCommonDialog): TLCLHandle;
begin
  Result:=TLCLHandle(TGtk4newColorSelectionDialog.Create(ACommonDialog));
end;

{ TGtk4WSFontDialog }

class function TGtk4WSFontDialog.CreateHandle(const ACommonDialog: TCommonDialog): TLCLHandle;
begin
  Result:=TLCLHandle(TGtk4FontSelectionDialog.Create(ACommonDialog));
end;

class function TGtk4WSFontDialog.QueryWSEventCapabilities(
  const ACommonDialog: TCommonDialog): TCDWSEventCapabilities;
begin
  { See TGtk4WSOpenDialog.QueryWSEventCapabilities — must not skip the
    DoExecute wait loop. TGtk4FontSelectionDialog.response_handler sets
    UserChoice via inherited, so the loop terminates normally. }
  Result := [cdecWSPerformsDoShow];
end;

{ TGtk4WSOpenDialog - QueryWSEventCapabilities }

class function TGtk4WSOpenDialog.QueryWSEventCapabilities(
  const ACommonDialog: TCommonDialog): TCDWSEventCapabilities;
begin
  { Must NOT include cdecWSNoCanCloseSupport: ShowModal is non-blocking
    (show+present only) and relies on TCommonDialog.DoExecute's
    Application.HandleMessage wait loop to pump events until UserChoice is
    set. cdecWSNoCanCloseSupport would skip that loop, so Execute returns
    immediately and the dialog is destroyed right after present — cancelling
    the in-flight folder load, disconnecting the response handlers (dead
    buttons) and dropping modality. Matches gtk2. }
  Result := [cdecWSPerformsDoShow];
end;

{ TGtk4WSSaveDialog - QueryWSEventCapabilities }

class function TGtk4WSSaveDialog.QueryWSEventCapabilities(
  const ACommonDialog: TCommonDialog): TCDWSEventCapabilities;
begin
  { See TGtk4WSOpenDialog.QueryWSEventCapabilities — must not skip the
    DoExecute wait loop. Matches gtk2. }
  Result := [cdecWSPerformsDoShow];
end;

{ TGtk4WSSelectDirectoryDialog - QueryWSEventCapabilities }

class function TGtk4WSSelectDirectoryDialog.QueryWSEventCapabilities(
  const ACommonDialog: TCommonDialog): TCDWSEventCapabilities;
begin
  { See TGtk4WSOpenDialog.QueryWSEventCapabilities — must not skip the
    DoExecute wait loop. Matches gtk2. }
  Result := [cdecWSPerformsDoShow];
end;

{ TGtk4WSColorDialog - QueryWSEventCapabilities }

class function TGtk4WSColorDialog.QueryWSEventCapabilities(
  const ACommonDialog: TCommonDialog): TCDWSEventCapabilities;
begin
  { See TGtk4WSOpenDialog.QueryWSEventCapabilities — must not skip the
    DoExecute wait loop. TGtk4newColorSelectionDialog.response_handler sets
    UserChoice via inherited, so the loop terminates normally. }
  Result := [cdecWSPerformsDoShow];
end;

end.
