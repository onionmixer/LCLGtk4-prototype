{
 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4Boxes;

{$mode objfpc}{$H+}

interface

uses
  System.UITypes,
  // LCL
  LCLType, LCLStrConsts,LCLProc, InterfaceBase,
  LazGtk4, LazGLib2, LazGObject2, LazGdk4, LazGtk4_Compat, gtk4objects,
  gtk4procs;


type
  TBtnListfunction=function(ndx:integer):longint of object;

  { TGtk4DialogFactory }

  TGtk4DialogFactory = class
    btn_def: PGtkButton;
    DefaultNdx: Integer;
    fButtons: TDialogButtons;
    pButtons: PLongint;
    fCaption: string;
    fDialogType:longint;
    Dialog: PGtkDialog;
    DialogResult: Integer;
    constructor CreateAsk(const DialogCaption, DialogMessage: string;
       DialogType: LongInt; Buttons: TDialogButtons; HelpCtx: Longint);
    constructor CreatePrompt(const DialogCaption, DialogMessage: string;
       DialogType: LongInt; Buttons: PLongInt;
       ButtonCount: LongInt; DefaultIndex: LongInt; EscapeResult: LongInt);
    constructor CreateMsgBox(hWnd: HWND; lpText, lpCaption: PChar;
       uType: Cardinal);
    constructor CreateMsgBox1(hWnd: HWND; lpText, lpCaption: PChar;
       uType: Cardinal);
    class function tr(UseWidgetStr: boolean; const TranslatedStr, WidgetStr: String): string;
    destructor Destroy;override;
    procedure run;
    function btn_coll_info(ndx:integer):longint;
    function btn_ptr_info(ndx:integer):longint;
    procedure set_message_text(const msg:string;const is_pango_markup:boolean=false);
    procedure update_widget_list(const func:TBtnListFunction);
    procedure CreateButton(const ALabel : String; const AResponse: Integer);
    procedure CreateButton(const ALabel : String; const AResponse: TGtkResponseType;
      const AImageHint: Integer = -1);
    function lcl_result:integer;
    function btn_result:integer;
    class function ResponseID(const AnID: Integer): TGtkResponseType;
    class function gtk_resp_to_lcl(const gtk_resp:TGtkResponseType):integer;
    class function gtk_resp_to_btn(const gtk_resp:TGtkResponseType):integer;
    class function MessageType(ADialogType:longint):TGtkMessageType;
  end;


implementation

procedure Gtk4DialogFactoryDestroyCB(widget: PGtkWidget; data: gpointer); cdecl;
var
  F: TGtk4DialogFactory;
begin
  if widget=nil then ;
  F := TGtk4DialogFactory(data);
  if F<>nil then
    F.Dialog:=nil;
end;

// fake GTK button responses
const
  GTK_RESPONSE_LCL_ALL = TGtkResponseType(-15);
  GTK_RESPONSE_LCL_YESTOALL = GTK_RESPONSE_ACCEPT;
  GTK_RESPONSE_LCL_RETRY = TGtkResponseType(-12);
  GTK_RESPONSE_LCL_IGNORE = TGtkResponseType(-13);
  GTK_RESPONSE_LCL_NOTOALL = TGtkResponseType(-14);


{ GTK4: gtk_dialog_run replacement using nested GMainLoop }
type
  TGtk4DialogRunInfo = record
    Loop: PGMainLoop;
    ResponseId: gint;
    Done: Boolean;
    Destroyed: Boolean;
  end;
  PGtk4DialogRunInfo = ^TGtk4DialogRunInfo;

procedure Gtk4DialogResponseCB(dialog: PGtkDialog; response_id: gint;
  user_data: gpointer); cdecl;
var
  Info: PGtk4DialogRunInfo;
begin
  Info := PGtk4DialogRunInfo(user_data);
  Info^.ResponseId := response_id;
  Info^.Done := True;
  if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
    g_main_loop_quit(Info^.Loop);
end;

function Gtk4DialogCloseCB(dialog: PGtkWidget; user_data: gpointer): gboolean; cdecl;
var
  Info: PGtk4DialogRunInfo;
begin
  Info := PGtk4DialogRunInfo(user_data);
  if not Info^.Done then
  begin
    Info^.ResponseId := gint(GTK_RESPONSE_DELETE_EVENT);
    Info^.Done := True;
    if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
      g_main_loop_quit(Info^.Loop);
  end;
  // Emulate gtk_dialog_run behavior: closing the window returns
  // GTK_RESPONSE_DELETE_EVENT without destroying the dialog object.
  Result := True;
end;

procedure Gtk4DialogDestroyCB(widget: PGtkWidget; user_data: gpointer); cdecl;
var
  Info: PGtk4DialogRunInfo;
begin
  Info := PGtk4DialogRunInfo(user_data);
  Info^.Destroyed := True;
  if not Info^.Done then
  begin
    Info^.Done := True;
    if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
      g_main_loop_quit(Info^.Loop);
  end;
end;

function Gtk4DialogRun(dialog: PGtkDialog): gint;
var
  Info: TGtk4DialogRunInfo;
  ResponseHandler, CloseHandler, DestroyHandler: gulong;
begin
  FillChar(Info, SizeOf(Info), 0);
  Info.Loop := g_main_loop_new(nil, False);
  Info.ResponseId := gint(GTK_RESPONSE_DELETE_EVENT);

  ResponseHandler := g_signal_connect_data(dialog, 'response',
    TGCallback(@Gtk4DialogResponseCB), @Info, nil, G_CONNECT_DEFAULT);
  CloseHandler := g_signal_connect_data(dialog, 'close-request',
    TGCallback(@Gtk4DialogCloseCB), @Info, nil, G_CONNECT_DEFAULT);
  DestroyHandler := g_signal_connect_data(dialog, 'destroy',
    TGCallback(@Gtk4DialogDestroyCB), @Info, nil, G_CONNECT_DEFAULT);

  gtk_window_set_modal(PGtkWindow(dialog), True);
  PGtkWidget(dialog)^.show;

  if not Info.Done then
    g_main_loop_run(Info.Loop);

  g_main_loop_unref(Info.Loop);
  if (not Info.Destroyed) and (dialog <> nil) then
  begin
    g_signal_handler_disconnect(dialog, ResponseHandler);
    g_signal_handler_disconnect(dialog, CloseHandler);
    g_signal_handler_disconnect(dialog, DestroyHandler);
    PGtkWidget(dialog)^.hide;
  end;
  Result := Info.ResponseId;
end;

{ callbacks }
function BoxClosed(Widget : PGtkWidget; {%H-}Event : PGdkEvent;
  data: gPointer) : GBoolean; cdecl;
var
  ModalResult : PtrUInt;
begin
  { We were requested by window manager to close so return EscapeResult}
  if PInteger(data)^ = 0 then
  begin
    ModalResult:= {%H-}PtrUInt(g_object_get_data(PGObject(Widget), 'modal_result'));
    { Don't allow to close if we don't have a default return value }
    Result:= (ModalResult = 0);
    if not Result then
      PInteger(data)^:= Integer(ModalResult);
  end else
    Result:= false;
end;

function ButtonClicked(Widget : PGtkWidget; data: gPointer) : GBoolean; cdecl;
var
  ModalResult : PtrUInt;
begin
  ModalResult := {%H-}PtrUInt(g_object_get_data(PGObject(Widget), 'modal_result'));
  PInteger(data)^ := Integer(ModalResult);
  Result := False;
end;


class function TGtk4DialogFactory.ResponseID(const AnID: Integer): TGtkResponseType;
begin
  case AnID of
    idButtonOK       : Result := GTK_RESPONSE_OK;
    idButtonCancel   : Result := GTK_RESPONSE_CANCEL;
    idButtonHelp     : Result := GTK_RESPONSE_HELP;
    idButtonYes      : Result := GTK_RESPONSE_YES;
    idButtonNo       : Result := GTK_RESPONSE_NO;
    idButtonClose    : Result := GTK_RESPONSE_CLOSE;
    idButtonAbort    : Result := GTK_RESPONSE_REJECT;
    idButtonRetry    : Result := GTK_RESPONSE_LCL_RETRY;
    idButtonIgnore   : Result := GTK_RESPONSE_LCL_IGNORE;
    idButtonAll      : Result := GTK_RESPONSE_LCL_ALL;
    idButtonNoToAll  : Result := GTK_RESPONSE_LCL_NOTOALL;
    idButtonYesToAll : Result := GTK_RESPONSE_LCL_YESTOALL;
  else
    Result:=TGtkResponseType(AnID);
  end;
end;

class function TGtk4DialogFactory.gtk_resp_to_lcl(const gtk_resp:TGtkResponseType):integer;
begin
  { Map GTK response IDs to TModalResult values (mrXxx).
    AskUser callers compare against mrXxx, not idButtonXxx. }
  case gtk_resp of
  GTK_RESPONSE_OK: Result:=mrOK;
  GTK_RESPONSE_CANCEL: Result:=mrCancel;
  GTK_RESPONSE_CLOSE: Result:=mrClose;
  GTK_RESPONSE_YES: Result:=mrYes;
  GTK_RESPONSE_NO: Result:=mrNo;

  GTK_RESPONSE_NONE: Result:=mrNone;
  GTK_RESPONSE_DELETE_EVENT: Result:=mrCancel;
  GTK_RESPONSE_REJECT: Result:=mrAbort;
  GTK_RESPONSE_ACCEPT: Result:=mrYesToAll; { = GTK_RESPONSE_LCL_YESTOALL }

  GTK_RESPONSE_LCL_RETRY: Result:=mrRetry;
  GTK_RESPONSE_LCL_IGNORE: Result:=mrIgnore;
  GTK_RESPONSE_LCL_ALL: Result:=mrAll;
  GTK_RESPONSE_LCL_NOTOALL: Result:=mrNoToAll;
  else
    Result:=Integer(gtk_resp);
  end;
end;

class function TGtk4DialogFactory.gtk_resp_to_btn(const gtk_resp:TGtkResponseType):integer;
begin
  case gtk_resp of
  GTK_RESPONSE_OK {-5} : Result:=  idButtonOk;
  GTK_RESPONSE_CANCEL {-6} :  Result := idButtonCancel;
  GTK_RESPONSE_CLOSE {-7} : Result:=idButtonClose;
  GTK_RESPONSE_YES {-8} : Result:=idButtonYes;
  GTK_RESPONSE_NO {-9} : Result:=idButtonNo;

  GTK_RESPONSE_NONE {-1} : Result:=0;
  GTK_RESPONSE_REJECT {-2} : Result:=idButtonAbort;
  GTK_RESPONSE_ACCEPT {-3} : Result:=idButtonYesToAll;

  GTK_RESPONSE_LCL_RETRY: Result:=idButtonRetry;
  GTK_RESPONSE_LCL_IGNORE:  Result:=idButtonIgnore;
  GTK_RESPONSE_LCL_ALL:  Result:=idButtonAll;
  GTK_RESPONSE_LCL_NOTOALL: Result:=idButtonNoToAll;
  else
    Result:=Integer(gtk_resp);
  end;
end;

procedure TGtk4DialogFactory.CreateButton(const ALabel : String; const AResponse: Integer);
begin
   CreateButton(ALabel, TGtkResponseType(AResponse));
end;

procedure TGtk4DialogFactory.CreateButton(
    const ALabel : String;
    const AResponse: TGtkResponseType;
    const AImageHint: Integer = -1);
var
  NewButton: PGtkWidget;
begin

  NewButton := gtk_dialog_add_button(Dialog,
    PgChar(ReplaceAmpersandsWithUnderscores(ALabel)), AResponse);
  gtk_button_set_use_underline(PGtkButton(NewButton), True);
  g_object_set_data(PGObject(NewButton), 'modal_result',
        {%H-}Pointer(PtrInt(AResponse)));
end;

function TGtk4DialogFactory.lcl_result: integer;
begin
  Result:=gtk_resp_to_lcl(TGtkResponseType(DialogResult));
end;

function TGtk4DialogFactory.btn_result: integer;
begin
  Result:=gtk_resp_to_btn(TGtkResponseType(DialogResult));
end;

class function TGtk4DialogFactory.MessageType(ADialogType:longint):TGtkMessageType;
begin
  case ADialogType of
    idDialogWarning: Result := GTK_MESSAGE_WARNING;
    idDialogError: Result := GTK_MESSAGE_ERROR;
    idDialogInfo : Result := GTK_MESSAGE_INFO;
    idDialogConfirm : Result := GTK_MESSAGE_QUESTION;
  else
    Result := GTK_MESSAGE_INFO;
  end;
end;


const
  ButtonResults : array[mrNone..mrYesToAll] of Longint = (
    -1, idButtonOK, idButtonCancel, idButtonAbort, idButtonRetry,
    idButtonIgnore, idButtonYes,idButtonNo, idButtonAll, idButtonNoToAll,
    idButtonYesToAll);

constructor TGtk4DialogFactory.CreateAsk(const DialogCaption,
       DialogMessage: string; DialogType: LongInt;
       Buttons: TDialogButtons; HelpCtx: Longint);
var
  GtkDialogType: TGtkMessageType;
  Btns: TGtkButtonsType;
  i, BtnIdx, BtnID: Integer;
  dbtn:TDialogButton;
begin
  DialogResult := mrNone;
  fDialogType := DialogType;
  GtkDialogType := MessageType(fDialogType); // map LCLINTF -> GTK
  fButtons:=Buttons;
  fCaption:=DialogCaption;

  Btns := GTK_BUTTONS_NONE;
  DefaultNdx := 0;
  for i := 0 to Buttons.Count - 1 do
  begin
    if Buttons[i].Default then
      DefaultNdx := i;

    if (DialogResult = mrNone) and
      (Buttons[i].ModalResult in [mrCancel, mrAbort, mrIgnore, mrNo, mrNoToAll])
    then
      DialogResult := Buttons[i].ModalResult;
  end;

  Dialog := gtk_message_dialog_new(nil, [GTK_DIALOG_MODAL], GtkDialogType, Btns, nil , []);
  g_signal_connect_data(Dialog, 'destroy',
    TGCallback(@Gtk4DialogFactoryDestroyCB), Self, nil, G_CONNECT_DEFAULT);

  set_message_text(DialogMessage);

  { GTK4: 'delete-event' removed. Our gtk_dialog_run handles close via response signal. }

  if Btns = GTK_BUTTONS_NONE then
  begin
    // gtk4 have reverted buttons eg. No, Yes
    for BtnIdx := Buttons.Count - 1 downto 0 do
    begin
      dbtn:=Buttons[BtnIdx];
      if (dbtn.ModalResult >= Low(ButtonResults)) and (dbtn.ModalResult <= High(ButtonResults)) then
      begin
        BtnID := ButtonResults[dbtn.ModalResult];
        case BtnID of
          idButtonOK       : CreateButton(dbtn.Caption, GTK_RESPONSE_OK, BtnID);
          idButtonCancel   : CreateButton(dbtn.Caption, GTK_RESPONSE_CANCEL, BtnID);
          idButtonHelp     : CreateButton(dbtn.Caption, GTK_RESPONSE_HELP, BtnID);
          idButtonYes      : CreateButton(dbtn.Caption, GTK_RESPONSE_YES, BtnID);
          idButtonNo       : CreateButton(dbtn.Caption, GTK_RESPONSE_NO, BtnID);
          idButtonClose    : CreateButton(dbtn.Caption, GTK_RESPONSE_CLOSE, BtnID);
          idButtonAbort    : CreateButton(dbtn.Caption, GTK_RESPONSE_REJECT, BtnID);
          idButtonRetry    : CreateButton(dbtn.Caption, GTK_RESPONSE_LCL_RETRY, BtnID);
          idButtonIgnore   : CreateButton(dbtn.Caption, GTK_RESPONSE_LCL_IGNORE, BtnID);
          idButtonAll      : CreateButton(dbtn.Caption, GTK_RESPONSE_LCL_ALL, BtnID);
          idButtonNoToAll  : CreateButton(dbtn.Caption, GTK_RESPONSE_LCL_NOTOALL, BtnID);
          idButtonYesToAll : CreateButton(dbtn.Caption, GTK_RESPONSE_LCL_YESTOALL, BtnID);
        end;
      end else
         CreateButton(dbtn.Caption, TGtkResponseType(dbtn.ModalResult), 0);

    end;
  end;

  update_widget_list(@btn_coll_info);

end;


function TGtk4DialogFactory.btn_coll_info(ndx:integer):longint;
begin
  Result:=fButtons[ndx].ModalResult; // get modal result for button
end;

function TGtk4DialogFactory.btn_ptr_info(ndx:integer):longint;
begin
  Result:=pButtons[ndx];
end;

procedure TGtk4DialogFactory.set_message_text(const msg: string;const is_pango_markup:boolean=false);
var
  ma, child: PGtkWidget;
begin
  if is_pango_markup then
    gtk_message_dialog_set_markup(PGtkMessageDialog(Dialog), PGChar(msg))
  else
  begin
    { GTK4: gtk_container_get_children removed. Use gtk_widget_get_first_child
      to find the label inside the message area. }
    ma := PGtkMessageDialog(Dialog)^.get_message_area();
    if ma <> nil then
    begin
      child := gtk4_widget_get_first_child(ma);
      if (child <> nil) and g_type_check_instance_is_a(PGTypeInstance(child), gtk_label_get_type) then
        PGtkLabel(child)^.set_label(PGChar(msg));
    end;
  end;
end;

procedure TGtk4DialogFactory.update_widget_list(const func:TBtnListFunction);
var
  BtnID, BtnRes: integer;
begin
  { GTK4: gtk_dialog_get_action_area and gtk_container_get_children were removed.
    With our gtk_dialog_run reimplementation (nested GMainLoop + response signal),
    DialogResult is set directly from the response ID, so individual button
    clicked handlers are no longer needed. Just set up the default response. }
  btn_def := nil;

  if DefaultNdx >= 0 then
  begin
    BtnRes := func(DefaultNdx);
    if (BtnRes >= Low(ButtonResults)) and (BtnRes <= High(ButtonResults)) then
      BtnID := ButtonResults[BtnRes]
    else
      BtnID := BtnRes;
    gtk_dialog_set_default_response(Dialog, ResponseID(BtnID));
  end;
end;

procedure TGtk4DialogFactory.run;
var
  Title:string;
begin
  if not Assigned(Dialog) then exit;

  if fCaption <> '' then
    Title:=fCaption
  else
  begin
    Title := '';
    case fDialogType of
      idDialogWarning: Title := rsMtWarning;
      idDialogError: Title := rsMtError;
      idDialogInfo : Title := rsMtInformation;
      idDialogConfirm : Title := rsMtConfirmation;
    end;
  end;

  gtk_window_set_title(PGtkWindow(Dialog), PGChar(Title));
  { Keep dialog execution in Pascal side where we can robustly handle
    close-request/destroy ordering for GTK4. }
  DialogResult := Gtk4DialogRun(Dialog);
end;

class function TGtk4DialogFactory.tr(UseWidgetStr: boolean; const TranslatedStr, WidgetStr: String): string;
begin
  { GTK4: Stock IDs like 'gtk-yes', 'gtk-no' etc. are no longer supported.
    Always use the translated string regardless of UseWidgetStr. }
  Result := TranslatedStr;
end;

destructor TGtk4DialogFactory.Destroy;
begin
  if Assigned(Dialog) then
  begin
    { GTK4: gtk_widget_destroy was removed.
      Close the toplevel window and release the object reference. }
    if Gtk4IsGtkWindow(PGObject(Dialog)) then
      gtk_window_close(PGtkWindow(Dialog));
    if Gtk4IsObject(PGObject(Dialog)) then
      g_object_unref(PGObject(Dialog));
    Dialog := nil;
  end;
end;


constructor TGtk4DialogFactory.CreatePrompt(const DialogCaption,
  DialogMessage: string; DialogType: LongInt; Buttons: PLongInt;
  ButtonCount: LongInt; DefaultIndex: LongInt; EscapeResult: LongInt);
var
  i:integer;
  GtkDialogType: TGtkMessageType;
  Btns: TGtkButtonsType;
begin
  DialogResult := EscapeResult;
  fDialogType := DialogType;
  GtkDialogType := MessageType(fDialogType); // map LCLINTF -> GTK
  pButtons:=Buttons;
  fCaption:=DialogCaption;

  Btns := GTK_BUTTONS_NONE;

  Dialog := gtk_message_dialog_new(nil, [GTK_DIALOG_MODAL], GtkDialogType, Btns, nil , []);
  g_signal_connect_data(Dialog, 'destroy',
    TGCallback(@Gtk4DialogFactoryDestroyCB), Self, nil, G_CONNECT_DEFAULT);

  set_message_text(DialogMessage);

  { GTK4: 'delete-event' removed. Our gtk_dialog_run handles close via response signal. }

  if Btns = GTK_BUTTONS_NONE then
  begin
    for i := ButtonCount-1 downto 0 do
    begin
      case Buttons[i] of
        idButtonOK       : CreateButton(tr(rsmbOK='&OK',rsmbOK, 'gtk-ok'), GTK_RESPONSE_OK);
        idButtonCancel   : CreateButton(tr(rsmbCancel='Cancel',rsmbCancel,'gtk-cancel'), GTK_RESPONSE_CANCEL);
        idButtonHelp     : CreateButton(tr(rsmbHelp='&Help',rsmbHelp,'gtk-help'), GTK_RESPONSE_HELP);
        idButtonYes      : CreateButton(tr(rsmbYes='&Yes',rsmbYes,'gtk-yes'), GTK_RESPONSE_YES);
        idButtonNo       : CreateButton(tr(rsmbNo='&No',rsmbNo,'gtk-no'), GTK_RESPONSE_NO);
        idButtonClose    : CreateButton(tr(rsmbClose='&Close',rsmbClose,'gtk-close'), GTK_RESPONSE_CLOSE);
        idButtonAbort    : CreateButton(rsMBAbort, GTK_RESPONSE_REJECT);
        idButtonRetry    : CreateButton(rsMBRetry, GTK_RESPONSE_LCL_RETRY);
        idButtonIgnore   : CreateButton(rsMBIgnore, GTK_RESPONSE_LCL_IGNORE);
        idButtonAll      : CreateButton(rsMbAll, GTK_RESPONSE_LCL_ALL);
        idButtonNoToAll  : CreateButton(rsMBNoToAll, GTK_RESPONSE_LCL_NOTOALL);
        idButtonYesToAll : CreateButton(rsMBYesToAll, GTK_RESPONSE_LCL_YESTOALL);
      end;
    end;
  end;
  update_widget_list(@btn_ptr_info);
end;


constructor TGtk4DialogFactory.CreateMsgBox1(hWnd: HWND; lpText, lpCaption: PChar;
  uType: Cardinal);
var
  ALabel : PGtkWidget;
begin
  fCaption:=lpCaption;

  DialogResult:= 0;
  Dialog := gtk_dialog_new;
  g_signal_connect_data(Dialog, 'destroy',
    TGCallback(@Gtk4DialogFactoryDestroyCB), Self, nil, G_CONNECT_DEFAULT);
  { GTK4: 'delete-event' removed. Our gtk_dialog_run handles close via response signal. }
  gtk_window_set_default_size(PGtkWindow(Dialog), 100, 100);
  ALabel:= gtk_label_new(lpText);
  { GTK4: gtk_container_add removed. Content area is a GtkBox; use gtk4_box_append. }
  gtk4_box_append(PGtkBox(PGtkDialog(Dialog)^.get_content_area), ALabel);
  fDialogType:= (uType and $0000000F);
  if fDialogType = MB_OKCANCEL
  then begin
    CreateButton(PChar(rsMbOK), IDOK);
    CreateButton(PChar(rsMbCancel), IDCANCEL);
  end
  else begin
    if fDialogType = MB_ABORTRETRYIGNORE
    then begin
      CreateButton(PChar(rsMbAbort), IDABORT);
      CreateButton(PChar(rsMbRetry), IDRETRY);
      CreateButton(PChar(rsMbIgnore), IDIGNORE);
    end
    else begin
      if fDialogType = MB_YESNOCANCEL
      then begin
        CreateButton(PChar(rsMbYes), IDYES);
        CreateButton(PChar(rsMbNo), IDNO);
        CreateButton(PChar(rsMbCancel), IDCANCEL);
      end
      else begin
        if fDialogType = MB_YESNO
        then begin
          CreateButton(PChar(rsMbYes), IDYES);
          CreateButton(PChar(rsMbNo), IDNO);
        end
        else begin
          if fDialogType = MB_RETRYCANCEL
          then begin
            CreateButton(PChar(rsMbRetry), IDRETRY);
            CreateButton(PChar(rsMbCancel), IDCANCEL);
          end
          else begin
            { We have no buttons to show. Create the default of OK button }
            CreateButton(PChar(rsMbOK), IDOK);
          end;
        end;
      end;
    end;
  end;
  gtk_window_set_title(PGtkWindow(Dialog), lpCaption);
  { GTK4: gtk_window_set_position was removed. Dialog centering is automatic
    when set_transient_for is used (GTK4 handles positioning). }
  gtk_window_set_modal(PGtkWindow(Dialog), true);
  { GTK4: gtk_widget_show_all removed. Widgets visible by default; show dialog. }
  gtk_widget_show(Dialog);
end;

constructor TGtk4DialogFactory.CreateMsgBox(hWnd: HWND; lpText,
  lpCaption: PChar; uType: Cardinal);
var
  AType,AButtons,DefIndex:integer;
  btns:array of integer;

  procedure AddBtn(btn_res:integer);
  begin
    setlength(btns,length(btns)+1);
    btns[high(btns)]:=btn_res;
  end;

begin
  // icons
  case uType and $000000F0 of
//  MB_ICONEXCLAMATION:
  MB_ICONWARNING: AType:=idDialogWarning;
  MB_ICONINFORMATION: AType:=idDialogInfo;
  MB_ICONQUESTION: Atype:=idDialogConfirm;
  MB_ICONERROR: Atype:=idDialogError;
  end;
  // default button
  DefIndex:=(uType and $00000F00) shr 8;

  // buttons requested
  AButtons:= (uType and $0000000F);
  if AButtons = MB_OKCANCEL
  then begin
    AddBtn(idButtonOk);
    AddBtn(idButtonCancel);
  end
  else begin
    if AButtons = MB_ABORTRETRYIGNORE
    then begin
      AddBtn(idButtonAbort);
      AddBtn(idButtonRetry);
      AddBtn(idButtonIgnore);
    end
    else begin
      if AButtons = MB_YESNOCANCEL
      then begin
        AddBtn(idButtonYes);
        AddBtn(idButtonNo);
        AddBtn(idButtonCancel);
      end
      else begin
        if AButtons = MB_YESNO
        then begin
          AddBtn(idButtonYes);
          AddBtn(idButtonNo);
        end
        else begin
          if AButtons = MB_RETRYCANCEL
          then begin
            AddBtn(idButtonRetry);
            AddBtn(idButtonCancel);
          end
          else begin
            { We have no buttons to show. Create the default of OK button }
            AddBtn(idButtonOK);
          end;
        end;
      end;
    end;
  end;
  Self.CreatePrompt(lpCaption,lpText,AType,@btns[0],length(btns),DefIndex,0);
end;


end.
