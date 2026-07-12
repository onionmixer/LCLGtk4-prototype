{
 *****************************************************************************
                             gtk4prndialogs.inc
                             ------------------
                     GTK4 native print dialog implementations
 *****************************************************************************

 *****************************************************************************
  This file is part of the Printer4Lazarus package

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Abstract:
    Native GTK4 dialog implementations for:
    - TPageSetupDialog: uses gtk_print_run_page_setup_dialog()
    - TPrintDialog: uses GtkPrintOperation with PRINT_DIALOG action
    - TPrinterSetupDialog: reuses CUPS LCL dialog form

  Notes:
    - gtk_print_run_page_setup_dialog() always returns a non-nil
      GtkPageSetup (a copy of the input on Cancel, the modified setup on OK).
      GTK4 does not provide a way to detect Cancel. TPageSetupDialog.DoExecute
      always returns True. This matches GTK4's design intent.
}

{ Unit-level variables to store GTK4 print settings across dialog invocations }
var
  Gtk4StoredPrintSettings: PGtkPrintSettings = nil;
  Gtk4StoredPageSetup: PGtkPageSetup = nil;

{ Callback for TPrintDialog: empty draw_page — we set n_pages(0) in
  begin_print so this should never be called, but required as safety }
procedure Gtk4PrintDialogDrawPage({%H-}Operation: PGtkPrintOperation;
  {%H-}Context: PGtkPrintContext; {%H-}PageNr: gint;
  {%H-}UserData: gpointer); cdecl;
begin
  { do nothing }
end;

{ Callback for TPrintDialog: set n_pages to 0 to prevent actual printing.
  We must NOT call cancel() here because that would change the run() result
  from RESULT_APPLY to RESULT_CANCEL, making it impossible to distinguish
  user-cancel from our programmatic cancel. Instead, setting n_pages(0)
  completes the operation immediately without rendering any pages. }
procedure Gtk4PrintDialogBeginPrint(Operation: PGtkPrintOperation;
  {%H-}Context: PGtkPrintContext; {%H-}UserData: gpointer); cdecl;
begin
  Operation^.set_n_pages(0);
end;

{ Helper: get active GTK4 parent window for dialogs }
function GetGtk4DialogParentWindow: PGtkWindow;
var
  AForm: TCustomForm;
  ActiveWnd: HWND;
begin
  Result := nil;
  AForm := Screen.ActiveCustomForm;
  if AForm = nil then
    AForm := Application.MainForm;
  if (AForm <> nil) and AForm.HandleAllocated then
  begin
    ActiveWnd := AForm.Handle;
    if ActiveWnd <> 0 then
      Result := PGtkWindow(TGtk4Widget(ActiveWnd).Widget);
  end;
end;

{ TPrinterSetupDialog }

function TPrinterSetupDialog.DoExecute: Boolean;
var
  Dlg: TdlgPropertiesPrinter;
begin
  { No native GTK4 printer setup dialog - reuse CUPS LCL form }
  Dlg := TdlgPropertiesPrinter.Create(nil);
  try
    if (Title = '') then
    begin
      if Printer <> nil then
        Dlg.Caption := Printer.PrinterName;
    end else
      Dlg.Caption := Title;
    Result := (Dlg.ShowModal = mrOk);
    if Result then
      Dlg.InitProperties;
  finally
    Dlg.Free;
  end;
end;

{ TPrintDialog }

function TPrintDialog.DoExecute: Boolean;
var
  Op: PGtkPrintOperation;
  Res: TGtkPrintOperationResult;
  Settings: PGtkPrintSettings;
  Err: PGError;
  PageSetup: PGtkPageSetup;
  Ranges: PGtkPageRange;
  NumRanges: gint;
  ParentWin: PGtkWindow;
  PageRange: TGtkPageRange;
  PrinterName: string;
begin
  Result := False;

  { Pre-condition checks }
  if not Assigned(Printer) then
    Exit;
  if Printer.Printers.Count <= 0 then
    Exit;

  Op := TGtkPrintOperation.new;
  try
    Op^.set_n_pages(1);

    { Pre-populate settings from TPrintDialog properties }
    if Gtk4StoredPrintSettings <> nil then
      Settings := Gtk4StoredPrintSettings^.copy
    else
      Settings := TGtkPrintSettings.new;

    Settings^.set_n_copies(Self.Copies);
    Settings^.set_collate(Self.Collate);

    { Pre-populate print range }
    case Self.PrintRange of
      prAllPages:
        Settings^.set_print_pages(GTK_PRINT_PAGES_ALL);
      prPageNums:
        begin
          Settings^.set_print_pages(GTK_PRINT_PAGES_RANGES);
          if (Self.FromPage > 0) and (Self.ToPage >= Self.FromPage) then
          begin
            PageRange.start := Self.FromPage - 1; { GTK uses 0-based }
            PageRange.end_ := Self.ToPage - 1;
            Settings^.set_page_ranges(@PageRange, 1);
          end;
        end;
      prCurrentPage:
        Settings^.set_print_pages(GTK_PRINT_PAGES_CURRENT);
      prSelection:
        Settings^.set_print_pages(GTK_PRINT_PAGES_SELECTION);
    end;

    { Apply PrintToFile }
    if Self.PrintToFile then
      Settings^.set_printer(PGChar('Print to File'));

    Op^.set_print_settings(Settings);

    { Apply stored page setup }
    if Gtk4StoredPageSetup <> nil then
      Op^.set_default_page_setup(Gtk4StoredPageSetup);

    { Apply TPrintDialogOptions }
    if poSelection in Self.Options then
    begin
      Op^.set_support_selection(True);
      Op^.set_has_selection(True);
    end;

    if Self.FromPage > 0 then
      Op^.set_current_page(Self.FromPage - 1);

    { Connect signals to prevent actual printing }
    g_signal_connect_data(PGObject(Op), 'begin-print',
      TGCallback(@Gtk4PrintDialogBeginPrint), nil, nil, G_CONNECT_DEFAULT);
    g_signal_connect_data(PGObject(Op), 'draw-page',
      TGCallback(@Gtk4PrintDialogDrawPage), nil, nil, G_CONNECT_DEFAULT);

    ParentWin := GetGtk4DialogParentWindow;
    Err := nil;
    Res := Op^.run(GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG, ParentWin, @Err);

    { RESULT_APPLY means user clicked Print }
    if Res = GTK_PRINT_OPERATION_RESULT_APPLY then
    begin
      Settings := Op^.get_print_settings;
      if Settings <> nil then
      begin
        { Extract dialog results into TPrintDialog properties }
        Self.Copies := Settings^.get_n_copies;
        Self.Collate := Settings^.get_collate;

        case Settings^.get_print_pages of
          GTK_PRINT_PAGES_ALL:
            Self.PrintRange := prAllPages;
          GTK_PRINT_PAGES_RANGES:
            begin
              Self.PrintRange := prPageNums;
              NumRanges := 0;
              Ranges := Settings^.get_page_ranges(@NumRanges);
              if (Ranges <> nil) and (NumRanges > 0) then
              begin
                Self.FromPage := Ranges^.start + 1; { GTK uses 0-based }
                Self.ToPage := Ranges^.end_ + 1;
                g_free(Ranges);
              end;
            end;
          GTK_PRINT_PAGES_CURRENT:
            Self.PrintRange := prCurrentPage;
          GTK_PRINT_PAGES_SELECTION:
            Self.PrintRange := prSelection;
        end;

        { Clamp to MinPage/MaxPage if set }
        if (Self.MinPage > 0) and (Self.FromPage < Self.MinPage) then
          Self.FromPage := Self.MinPage;
        if (Self.MaxPage > 0) and (Self.ToPage > Self.MaxPage) then
          Self.ToPage := Self.MaxPage;

        { Read PrintToFile state — check output-uri for locale independence }
        PrinterName := '';
        if Settings^.get_printer <> nil then
          PrinterName := string(Settings^.get_printer);
        Self.PrintToFile := (Settings^.get(PGChar('output-uri')) <> nil) or
          (PrinterName = 'Print to File');

        { Store settings for future use and for the printer backend }
        if Gtk4StoredPrintSettings <> nil then
          g_object_unref(PGObject(Gtk4StoredPrintSettings));
        Gtk4StoredPrintSettings := Settings^.copy;

        { Store page setup }
        PageSetup := Op^.get_default_page_setup;
        if PageSetup <> nil then
        begin
          if Gtk4StoredPageSetup <> nil then
            g_object_unref(PGObject(Gtk4StoredPageSetup));
          Gtk4StoredPageSetup := PageSetup^.copy;
        end;

        { Apply printer selection to CUPS backend }
        if PrinterName <> '' then
        begin
          try
            Printer.SetPrinter(PrinterName);
          except
            { Printer might not be found in CUPS list - ignore }
          end;
        end;

        { Apply copies }
        Printer.Copies := Self.Copies;

        { Apply orientation from settings }
        case Settings^.get_orientation of
          GTK_PAGE_ORIENTATION_PORTRAIT:
            Printer.Orientation := poPortrait;
          GTK_PAGE_ORIENTATION_LANDSCAPE:
            Printer.Orientation := poLandscape;
          GTK_PAGE_ORIENTATION_REVERSE_PORTRAIT:
            Printer.Orientation := poReversePortrait;
          GTK_PAGE_ORIENTATION_REVERSE_LANDSCAPE:
            Printer.Orientation := poReverseLandscape;
        end;

        Result := True;
      end;
    end;

    if Err <> nil then
      g_error_free(Err);

    { Free the settings we created for pre-population }
    g_object_unref(PGObject(Settings));
  finally
    g_object_unref(PGObject(Op));
  end;
end;


{ TPageSetupDialog }

function TPageSetupDialog.DoExecute: Boolean;
var
  Settings: PGtkPrintSettings;
  PageSetup, NewSetup: PGtkPageSetup;
  PaperSize: PGtkPaperSize;
  ParentWin: PGtkWindow;
  NScale: Double;
begin
  Result := False;

  if Printer.PrinterIndex < 0 then
  begin
    if psoWarning in Options then
      MessageDlg(Title, p4lrsNoDefaultPrinter, mtWarning, [mbOk], 0);
    Exit(False);
  end;

  { Use stored settings or create new ones }
  if Gtk4StoredPrintSettings <> nil then
    Settings := Gtk4StoredPrintSettings^.copy
  else
    Settings := TGtkPrintSettings.new;

  { Use stored page setup or create new one }
  if Gtk4StoredPageSetup <> nil then
    PageSetup := Gtk4StoredPageSetup^.copy
  else
    PageSetup := TGtkPageSetup.new;

  { Apply current orientation }
  case Printer.Orientation of
    poPortrait:          PageSetup^.set_orientation(GTK_PAGE_ORIENTATION_PORTRAIT);
    poLandscape:         PageSetup^.set_orientation(GTK_PAGE_ORIENTATION_LANDSCAPE);
    poReverseLandscape:  PageSetup^.set_orientation(GTK_PAGE_ORIENTATION_REVERSE_LANDSCAPE);
    poReversePortrait:   PageSetup^.set_orientation(GTK_PAGE_ORIENTATION_REVERSE_PORTRAIT);
  end;

  { Determine scale factor: margins are in 1/1000 inch or 1/100 mm }
  if FUnits = pmInches then
    NScale := 1000.0
  else
    NScale := 100.0;

  { Apply current margins if provided }
  if psoMargins in Options then
  begin
    if FUnits = pmInches then
    begin
      PageSetup^.set_left_margin(FMarginLeft / NScale * 25.4, GTK_UNIT_MM);
      PageSetup^.set_top_margin(FMarginTop / NScale * 25.4, GTK_UNIT_MM);
      PageSetup^.set_right_margin(FMarginRight / NScale * 25.4, GTK_UNIT_MM);
      PageSetup^.set_bottom_margin(FMarginBottom / NScale * 25.4, GTK_UNIT_MM);
    end else
    begin
      PageSetup^.set_left_margin(FMarginLeft / NScale, GTK_UNIT_MM);
      PageSetup^.set_top_margin(FMarginTop / NScale, GTK_UNIT_MM);
      PageSetup^.set_right_margin(FMarginRight / NScale, GTK_UNIT_MM);
      PageSetup^.set_bottom_margin(FMarginBottom / NScale, GTK_UNIT_MM);
    end;
  end;

  { Show GTK4 native page setup dialog.
    Note: gtk_print_run_page_setup_dialog always returns a non-nil
    GtkPageSetup — a copy of the input on Cancel, the modified setup on OK.
    GTK4 does not expose a response code from this dialog, so we cannot
    distinguish Cancel from OK-without-changes. We always return True. }
  ParentWin := GetGtk4DialogParentWindow;
  NewSetup := gtk_print_run_page_setup_dialog(ParentWin, PageSetup, Settings);

  if NewSetup <> nil then
  begin
    { Read orientation }
    case NewSetup^.get_orientation of
      GTK_PAGE_ORIENTATION_PORTRAIT:
        Printer.Orientation := poPortrait;
      GTK_PAGE_ORIENTATION_LANDSCAPE:
        Printer.Orientation := poLandscape;
      GTK_PAGE_ORIENTATION_REVERSE_PORTRAIT:
        Printer.Orientation := poReversePortrait;
      GTK_PAGE_ORIENTATION_REVERSE_LANDSCAPE:
        Printer.Orientation := poReverseLandscape;
    end;

    { Read margins back }
    if FUnits = pmInches then
    begin
      FMarginLeft := Round(NewSetup^.get_left_margin(GTK_UNIT_MM) / 25.4 * NScale);
      FMarginTop := Round(NewSetup^.get_top_margin(GTK_UNIT_MM) / 25.4 * NScale);
      FMarginRight := Round(NewSetup^.get_right_margin(GTK_UNIT_MM) / 25.4 * NScale);
      FMarginBottom := Round(NewSetup^.get_bottom_margin(GTK_UNIT_MM) / 25.4 * NScale);
    end else
    begin
      FMarginLeft := Round(NewSetup^.get_left_margin(GTK_UNIT_MM) * NScale);
      FMarginTop := Round(NewSetup^.get_top_margin(GTK_UNIT_MM) * NScale);
      FMarginRight := Round(NewSetup^.get_right_margin(GTK_UNIT_MM) * NScale);
      FMarginBottom := Round(NewSetup^.get_bottom_margin(GTK_UNIT_MM) * NScale);
    end;

    { Read paper size }
    PaperSize := NewSetup^.get_paper_size;
    if PaperSize <> nil then
    begin
      if FUnits = pmInches then
      begin
        FPageWidth := Round(PaperSize^.get_width(GTK_UNIT_MM) / 25.4 * NScale);
        FPageHeight := Round(PaperSize^.get_height(GTK_UNIT_MM) / 25.4 * NScale);
      end else
      begin
        FPageWidth := Round(PaperSize^.get_width(GTK_UNIT_MM) * NScale);
        FPageHeight := Round(PaperSize^.get_height(GTK_UNIT_MM) * NScale);
      end;

      { Apply paper to printer }
      try
        Printer.PaperSize.PaperName := string(PaperSize^.get_name);
      except
        { Paper might not exist in CUPS - ignore }
      end;
    end;

    { Store page setup for future use }
    if Gtk4StoredPageSetup <> nil then
      g_object_unref(PGObject(Gtk4StoredPageSetup));
    Gtk4StoredPageSetup := NewSetup^.copy;

    g_object_unref(PGObject(NewSetup));
    Result := True;
  end;

  g_object_unref(PGObject(Settings));
  g_object_unref(PGObject(PageSetup));
end;

{ Cleanup stored GTK4 print settings on unit finalization }
procedure Gtk4PrintDialogsFinalize;
begin
  if Gtk4StoredPrintSettings <> nil then
  begin
    g_object_unref(PGObject(Gtk4StoredPrintSettings));
    Gtk4StoredPrintSettings := nil;
  end;
  if Gtk4StoredPageSetup <> nil then
  begin
    g_object_unref(PGObject(Gtk4StoredPageSetup));
    Gtk4StoredPageSetup := nil;
  end;
end;
