{
 *****************************************************************************
 *                              Gtk4WSMenus.pp                               *
 *                              --------------                               *
 *                                                                           *
 *   GTK4 implementation using GMenu model + GtkPopoverMenuBar/PopoverMenu   *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************
}
unit Gtk4WSMenus;

{$mode objfpc}{$H+}
{$i gtk4defines.inc}

interface

uses
  Classes, SysUtils,
  LazGObject2, LazGlib2, LazGio2, LazGdk4, LazGtk4, LazGtk4_Compat, LazGdkPixbuf2,
  gtk4procs,
  LazLoggerBase,
  WSLCLClasses, WSMenus,
  LCLType, Graphics, Menus, Forms, Controls, ImgList, LCLIntf;

type

  { TGtk4WSMenuItem }

  TGtk4WSMenuItem = class(TWSMenuItem)
  published
    class procedure AttachMenu(const AMenuItem: TMenuItem); override;
    class function CreateHandle(const AMenuItem: TMenuItem): HMENU; override;
    class procedure DestroyHandle(const AMenuItem: TMenuItem); override;
    class procedure SetCaption(const AMenuItem: TMenuItem; const ACaption: string); override;
    class procedure SetShortCut(const AMenuItem: TMenuItem; const ShortCutK1, ShortCutK2: TShortCut); override;
    class procedure SetVisible(const AMenuItem: TMenuItem; const Visible: boolean); override;
    class function SetCheck(const AMenuItem: TMenuItem; const Checked: boolean): boolean; override;
    class function SetEnable(const AMenuItem: TMenuItem; const Enabled: boolean): boolean; override;
    class function SetRadioItem(const AMenuItem: TMenuItem; const {%H-}RadioItem: boolean): boolean; override;
    class function SetRightJustify(const AMenuItem: TMenuItem; const Justified: boolean): boolean; override;
    class procedure UpdateMenuIcon(const AMenuItem: TMenuItem; const HasIcon: Boolean; const {%H-}AIcon: TBitmap); override;
  end;

  { TGtk4WSMenu }

  TGtk4WSMenu = class(TWSMenu)
  published
    class function CreateHandle(const AMenu: TMenu): HMENU; override;
    class procedure SetBiDiMode(const AMenu: TMenu; UseRightToLeftAlign, {%H-}UseRightToLeftReading : Boolean); override;
  end;

  { TGtk4WSMainMenu }

  TGtk4WSMainMenu = class(TWSMainMenu)
  published
  end;

  { TGtk4WSPopupMenu }

  TGtk4WSPopupMenu = class(TWSPopupMenu)
  published
    class function CreateHandle(const AMenu: TMenu): HMENU; override;
    class procedure Popup(const APopupMenu: TPopupMenu; const X, Y: integer); override;
  end;

{ Helper: rebuild the GMenu model for a TMenu from the LCL TMenuItem tree }
procedure Gtk4RebuildMenuModel(AMenu: TMenu);

implementation
uses Types, gtk4widgets, gtk4objects;

{ LCLKeyToGdkKeyval and ShiftStateToGdkMods are in gtk4procs.pas }

var
  Gtk4MenuRebuildInProgress: Boolean = False;
  Gtk4PendingMenuRebuilds: TFPList = nil;
  Gtk4DeferredRebuildId: guint = 0;
  { The popup menu currently displayed by TGtk4WSPopupMenu.Popup's nested
    loop — its model must not be rebuilt while shown. }
  Gtk4ActivePopupMenu: TMenu = nil;
  { Menus whose rebuild was postponed because their popover is on screen.
    Kept SEPARATE from Gtk4PendingMenuRebuilds: re-queueing into the same
    list would spin the drain loop in Gtk4RebuildMenuModel forever. }
  Gtk4RetryRebuilds: TFPList = nil;
  Gtk4RetryTimerId: guint = 0;

{ True when any popover in W's subtree is currently mapped (an open
  menubar dropdown or submenu).  Rebuilding a menu model with remove_all
  while its popover is open destroys the open dropdown's widgets and
  leaves GtkPopoverMenuBar's active state stuck — after a few open/hover/
  click cycles the menu bar (and with a broken grab, all popups) stops
  opening entirely. }
function Gtk4SubtreeHasMappedPopover(W: PGtkWidget): Boolean;
var
  Child: PGtkWidget;
begin
  Result := False;
  if W = nil then Exit;
  Child := gtk4_widget_get_first_child(W);
  while Child <> nil do
  begin
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_popover_get_type) then
    begin
      if Child^.get_mapped then
        Exit(True);
    end;
    if Gtk4SubtreeHasMappedPopover(Child) then
      Exit(True);
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

procedure Gtk4DeferredRebuildMenuModel(AMenu: TMenu); forward;
procedure Gtk4ScheduleRebuildRetry(AMenu: TMenu); forward;



procedure Gtk4SafeUnref(AObj: PGObject); inline;
begin
  if (AObj <> nil) and Gtk4IsObject(AObj) then
    g_object_unref(AObj);
end;

function Gtk4CreateMenuIconFromPixbuf(const APixbuf: PGdkPixbuf): PGIcon;
var
  Encoded: Pgchar;
  EncodedSize: gsize;
  GErr: PGError;
  GBytes: PGBytes;
  BytesIcon: PGBytesIcon;
begin
  Result := nil;
  if APixbuf = nil then
    Exit;

  Encoded := nil;
  EncodedSize := 0;
  GErr := nil;
  if not gdk_pixbuf_save_to_bufferv(APixbuf, @Encoded, @EncodedSize, 'png', nil, nil, @GErr) then
  begin
    {$IFDEF GTK4DEBUGMENUS}
    DebugLn('Gtk4CreateMenuIconFromPixbuf: PNG encode failed');
    {$ENDIF}
    if GErr <> nil then
      g_error_free(GErr);
    Exit;
  end;

  try
    if (Encoded = nil) or (EncodedSize = 0) then
      Exit;

    GBytes := glib2_bytes_new(Encoded, EncodedSize);
    if GBytes = nil then
      Exit;
    try
      BytesIcon := g_bytes_icon_new(GBytes);
      if BytesIcon <> nil then
      begin
        Result := PGIcon(BytesIcon);
        {$IFDEF GTK4DEBUGMENUS}
        DebugLn('Gtk4CreateMenuIconFromPixbuf: created icon bytes=', dbgs(EncodedSize));
        {$ENDIF}
      end;
    finally
      g_bytes_unref(GBytes);
    end;
  finally
    if Encoded <> nil then
      g_free(Encoded);
  end;
end;

function Gtk4CreateMenuIconFromBitmap(const AIcon: TBitmap): PGIcon;
var
  APixbuf: PGdkPixbuf;
begin
  Result := nil;
  if (AIcon = nil) or AIcon.Empty then
    Exit;

  APixbuf := Gtk4BitmapToPixbuf(AIcon);
  if APixbuf = nil then Exit;
  try
    Result := Gtk4CreateMenuIconFromPixbuf(APixbuf);
  finally
    g_object_unref(APixbuf);
  end;
end;

function Gtk4CreateMenuIconFromMenuItem(const AMenuItem: TMenuItem): PGIcon;
var
  AImageList: TCustomImageList;
  ABmp: TBitmap;
begin
  Result := nil;
  if (AMenuItem = nil) or (not AMenuItem.HasIcon) then
    Exit;

  AImageList := AMenuItem.GetImageList;
  if (AImageList <> nil) and (AMenuItem.ImageIndex >= 0) and
     (AMenuItem.ImageIndex < AImageList.Count) then
  begin
    ABmp := TBitmap.Create;
    try
      AImageList.GetBitmap(AMenuItem.ImageIndex, ABmp);
      Result := Gtk4CreateMenuIconFromBitmap(ABmp);
      if Result <> nil then
        Exit;
    finally
      ABmp.Free;
    end;
  end;

  if (AMenuItem.Bitmap <> nil) and (not AMenuItem.Bitmap.Empty) then
    Result := Gtk4CreateMenuIconFromBitmap(AMenuItem.Bitmap);
end;

procedure Gtk4QueuePendingMenuRebuild(AMenu: TMenu);
var
  i: Integer;
begin
  if AMenu = nil then
    Exit;
  if Gtk4PendingMenuRebuilds = nil then
    Gtk4PendingMenuRebuilds := TFPList.Create;
  for i := 0 to Gtk4PendingMenuRebuilds.Count - 1 do
    if Gtk4PendingMenuRebuilds[i] = Pointer(AMenu) then
      Exit;
  Gtk4PendingMenuRebuilds.Add(Pointer(AMenu));
end;

{ ---- Helper to find the GMenu and GSimpleActionGroup for a menu item ---- }

procedure GetMenuModelAndActionGroup(const AMenuItem: TMenuItem;
  out AModel: PGMenu; out AActionGroup: PGSimpleActionGroup);
var
  AMenu: TMenu;
  AForm: TCustomForm;
  AWin: TGtk4Window;
begin
  AModel := nil;
  AActionGroup := nil;
  AMenu := AMenuItem.GetParentMenu;
  if AMenu = nil then exit;

  if (AMenu is TMainMenu) and (AMenu.Owner is TCustomForm) then
  begin
    AForm := TCustomForm(AMenu.Owner);
    if AForm.HandleAllocated then
    begin
      AWin := TGtk4Window(AForm.Handle);
      AModel := AWin.GetMenuModel;
      AActionGroup := AWin.GetMenuActionGroup;
    end;
  end
  else if AMenu.HandleAllocated then
  begin
    AModel := TGtk4MenuShell(AMenu.Handle).FMenuModel;
    AActionGroup := TGtk4MenuShell(AMenu.Handle).FActionGroup;
  end;
end;

{ ---- Recursively build a GMenu from LCL TMenuItem children ---- }

procedure BuildMenuItems(AParentModel: PGMenu; AActionGroup: PGSimpleActionGroup;
  AParent: TMenuItem);
var
  i: Integer;
  Child: TMenuItem;
  Item: TGtk4MenuItem;
  AMenuIcon: PGIcon;
  ASubMenu: PGMenu;
  ASection: PGMenu;
  InSection: Boolean;
begin
  {$IFDEF GTK4DEBUGMENUS}
  DebugLn('BuildMenuItems: parent="', AParent.Caption, '" children=', IntToStr(AParent.Count));
  {$ENDIF}
  ASection := nil;
  InSection := False;

  for i := 0 to AParent.Count - 1 do
  begin
    Child := AParent.Items[i];
    if not Child.Visible then
      Continue;

    if not Child.HandleAllocated then
      Continue;

    Item := TGtk4MenuItem(Child.Handle);

    { Register the action in the action group.
      Keep existing action objects alive across model rebuilds (GTK2/Qt5-like
      behavior) to avoid stale-object churn while menus are opening/updating. }
    if (AActionGroup <> nil) and (Item.Action <> nil) and (Item.ActionName <> '') then
    begin
      if not Gtk4IsObject(PGObject(Item.Action)) then
        Continue;
      if g_action_map_lookup_action(PGActionMap(AActionGroup), PgChar(Item.ActionName)) = nil then
        g_action_map_add_action(PGActionMap(AActionGroup), PGAction(Item.Action));
    end;

    if Child.Caption = cLineCaption then
    begin
      { Separator: start a new section in the parent.
        Flush the current section if we have one, then start fresh. }
      if InSection and (ASection <> nil) then
      begin
        g_menu_append_section(AParentModel, nil, PGMenuModel(ASection));
        Gtk4SafeUnref(PGObject(ASection));
      end;
      ASection := PGMenu(g_menu_new);
      InSection := True;
      Continue;
    end;

    if Child.Count > 0 then
    begin
      { Item has children - create a submenu }
      ASubMenu := PGMenu(g_menu_new);
      BuildMenuItems(ASubMenu, AActionGroup, Child);
      if InSection then
        g_menu_append_submenu(ASection, PgChar(ReplaceAmpersandsWithUnderscores(Child.Caption)), PGMenuModel(ASubMenu))
      else
        g_menu_append_submenu(AParentModel, PgChar(ReplaceAmpersandsWithUnderscores(Child.Caption)), PGMenuModel(ASubMenu));
      Gtk4SafeUnref(PGObject(ASubMenu));
    end
    else
    begin
      { Leaf item - add with action reference }
      if Item.FGMenuItem <> nil then
      begin
        AMenuIcon := Gtk4CreateMenuIconFromMenuItem(Child);
        try
          g_menu_item_set_icon(Item.FGMenuItem, AMenuIcon);
        finally
          Gtk4SafeUnref(PGObject(AMenuIcon));
        end;

        if InSection then
          g_menu_append_item(ASection, Item.FGMenuItem)
        else
          g_menu_append_item(AParentModel, Item.FGMenuItem);
      end;
    end;
  end;

  { Flush remaining section }
  if InSection and (ASection <> nil) then
  begin
    g_menu_append_section(AParentModel, nil, PGMenuModel(ASection));
    Gtk4SafeUnref(PGObject(ASection));
  end;
end;

{ GTK4's GtkModelButton.update_visibility() hides GtkImage when text is
  present in non-iconic mode (gtkmodelbutton.c:638). After model rebuild,
  walk the popover widget tree and force-show all GtkImage widgets that
  have content. get_first_child/get_next_sibling include hidden widgets,
  so we find the hidden images. Recursion traverses into nested popover
  submenus (popovers are children of GtkModelButton). }
procedure Gtk4ForceMenuIconsVisible(AWidget: PGtkWidget);
var
  Child: PGtkWidget;
begin
  Child := gtk4_widget_get_first_child(AWidget);
  while Child <> nil do
  begin
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_image_get_type()) then
    begin
      if gtk_image_get_storage_type(PGtkImage(Child)) <> GTK_IMAGE_EMPTY then
        Child^.set_visible(True);
    end
    else
      Gtk4ForceMenuIconsVisible(Child);
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

{ ---- Menu hover hint delivery ----------------------------------------------
  GTK4 menus are GMenu-model based and rendered by GtkPopoverMenu/Bar into
  internal GtkModelButtons, which (unlike gtk2's GtkMenuItem or qt5's QAction)
  the widgetset does not own and which expose no queryable action name or
  hover/select signal. So there is no clean per-item identity: we instead attach
  motion (mouse) + focus (keyboard) controllers to each rendered button and, on
  enter, read the button's own caption label and match it back to a TMenuItem to
  deliver the hint the way gtk2/qt5 do (TMenuItem.IntfDoSelect -> Application.
  Hint). Caption matching is robust for the normal case; two items with the same
  caption resolve to the first match (a documented limitation). }

function Gtk4NormMenuCaption(const S: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(S) do
    if not (S[i] in ['&', '_']) then    { strip LCL '&' and GTK '_' mnemonics }
      Result := Result + S[i];
  Result := Trim(Result);
end;

{ First non-empty GtkLabel text in AWidget's subtree — a GtkModelButton's
  caption label (its accelerator label, if any, is separate and comes later). }
function Gtk4FindFirstLabelText(AWidget: PGtkWidget): string;
var
  Child: PGtkWidget;
begin
  Result := '';
  Child := gtk4_widget_get_first_child(AWidget);
  while Child <> nil do
  begin
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_label_get_type()) then
    begin
      Result := string(gtk_label_get_text(PGtkLabel(Child)));
      if Result <> '' then
        Exit;
    end;
    Result := Gtk4FindFirstLabelText(Child);
    if Result <> '' then
      Exit;
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

{ Depth-first search for the first visible, non-separator menu item whose
  normalized caption equals ANorm. }
function Gtk4FindMenuItemByCaption(AParent: TMenuItem; const ANorm: string): TMenuItem;
var
  i: Integer;
  Child: TMenuItem;
begin
  Result := nil;
  if AParent = nil then
    Exit;
  for i := 0 to AParent.Count - 1 do
  begin
    Child := AParent.Items[i];
    if Child.Visible and (Child.Caption <> cLineCaption)
       and (Gtk4NormMenuCaption(Child.Caption) = ANorm) then
      Exit(Child);
    if Child.Count > 0 then
    begin
      Result := Gtk4FindMenuItemByCaption(Child, ANorm);
      if Result <> nil then
        Exit;
    end;
  end;
end;

{ Shared: resolve the controller's button to a TMenuItem and deliver its hint.
  user_data is the owning TMenu's root TMenuItem (it outlives the button, so it
  is safe here — destroying the menu destroys this button and its controller). }
procedure Gtk4MenuHintDeliver(AController: PGtkEventController; user_data: gpointer);
var
  W: PGtkWidget;
  Cap: string;
  Item: TMenuItem;
begin
  if user_data = nil then
    Exit;
  W := gtk_event_controller_get_widget(AController);
  if W = nil then
    Exit;
  Cap := Gtk4NormMenuCaption(Gtk4FindFirstLabelText(W));
  if Cap = '' then
    Exit;
  Item := Gtk4FindMenuItemByCaption(TMenuItem(user_data), Cap);
  if Item <> nil then
    Item.IntfDoSelect;
end;

procedure Gtk4MenuMotionEnterCB(controller: PGtkEventControllerMotion;
  {%H-}x, {%H-}y: gdouble; user_data: gpointer); cdecl;
begin
  Gtk4MenuHintDeliver(PGtkEventController(controller), user_data);
end;

procedure Gtk4MenuFocusEnterCB(controller: PGtkEventController; user_data: gpointer); cdecl;
begin
  Gtk4MenuHintDeliver(controller, user_data);
end;

procedure Gtk4MenuHintClearCB({%H-}controller: Pointer; {%H-}user_data: gpointer); cdecl;
begin
  { Mirror gtk2's 'deselect'. Moving to an adjacent item fires leave(old) before
    enter(new), so the new item's hint is re-set immediately afterward. }
  Application.Hint := '';
end;

procedure Gtk4MenuPopoverMapCB(widget: PGtkWidget; user_data: gpointer); cdecl; forward;

{ Walk the rendered popover/menubar tree and attach hint controllers to each
  button once. GtkPopoverMenuBar builds dropdown buttons lazily, so we also hook
  each popover's 'map' to (re-)attach when its buttons appear; the popup-menu
  popover is built up front, so the initial walk covers it. ARootItem is the
  owning TMenu's root item, used to resolve captions. }
procedure Gtk4AttachMenuHintControllers(AWidget: PGtkWidget; ARootItem: TMenuItem);
var
  Child: PGtkWidget;
  MC, FC: PGtkEventController;
begin
  if (AWidget = nil) or (ARootItem = nil) then
    Exit;
  Child := gtk4_widget_get_first_child(AWidget);
  while Child <> nil do
  begin
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_actionable_get_type())
       and (g_object_get_data(PGObject(Child), 'lcl-menu-hint') = nil) then
    begin
      MC := gtk4_event_controller_motion_new;
      g_signal_connect_data(MC, 'enter', TGCallback(@Gtk4MenuMotionEnterCB), ARootItem, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(MC, 'leave', TGCallback(@Gtk4MenuHintClearCB), nil, nil, G_CONNECT_DEFAULT);
      gtk4_widget_add_controller(Child, MC);
      FC := gtk4_event_controller_focus_new;
      g_signal_connect_data(FC, 'enter', TGCallback(@Gtk4MenuFocusEnterCB), ARootItem, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(FC, 'leave', TGCallback(@Gtk4MenuHintClearCB), nil, nil, G_CONNECT_DEFAULT);
      gtk4_widget_add_controller(Child, FC);
      g_object_set_data(PGObject(Child), 'lcl-menu-hint', Pointer(1));
    end;
    if g_type_check_instance_is_a(PGTypeInstance(Child), gtk_popover_get_type())
       and (g_object_get_data(PGObject(Child), 'lcl-menu-hint-map') = nil) then
    begin
      g_signal_connect_data(PGObject(Child), 'map', TGCallback(@Gtk4MenuPopoverMapCB), ARootItem, nil, G_CONNECT_DEFAULT);
      g_object_set_data(PGObject(Child), 'lcl-menu-hint-map', Pointer(1));
    end;
    Gtk4AttachMenuHintControllers(Child, ARootItem);
    Child := gtk4_widget_get_next_sibling(Child);
  end;
end;

procedure Gtk4MenuPopoverMapCB(widget: PGtkWidget; user_data: gpointer); cdecl;
begin
  if (widget <> nil) and (user_data <> nil) then
    Gtk4AttachMenuHintControllers(widget, TMenuItem(user_data));
end;

procedure Gtk4DoRebuildMenuModel(AMenu: TMenu);
var
  AModel: PGMenu;
  AActionGroup: PGSimpleActionGroup;
  AForm: TCustomForm;
  AWin: TGtk4Window;
begin
  if AMenu = nil then
    Exit;
  AWin := nil;
  if AMenu is TMainMenu then
  begin
    if not (AMenu.Owner is TCustomForm) then exit;
    AForm := TCustomForm(AMenu.Owner);
    if not AForm.HandleAllocated then exit;
    AWin := TGtk4Window(AForm.Handle);
    AModel := AWin.GetMenuModel;
    AActionGroup := AWin.GetMenuActionGroup;
  end
  else if AMenu.HandleAllocated then
  begin
    AModel := TGtk4MenuShell(AMenu.Handle).FMenuModel;
    AActionGroup := TGtk4MenuShell(AMenu.Handle).FActionGroup;
  end
  else
    exit;

  if (AModel = nil) or (AActionGroup = nil) then
  begin
    {$IFDEF GTK4DEBUGMENUS}
    DebugLn('Gtk4RebuildMenuModel: model or action group is nil');
    {$ENDIF}
    exit;
  end;

  { NEVER rebuild a model that is currently on screen: g_menu_remove_all
    tears down the open dropdown/popup widgets mid-interaction and leaves
    GtkPopoverMenuBar (or the popup grab) in a stuck state.  Postpone and
    retry after the popover closes. }
  if (AMenu = Gtk4ActivePopupMenu) or
     ((AWin <> nil) and Gtk4SubtreeHasMappedPopover(AWin.GetMenuBar)) then
  begin
    Gtk4ScheduleRebuildRetry(AMenu);
    exit;
  end;

  { Clear existing model }
  g_menu_remove_all(AModel);
  { Rebuild from LCL menu items }
  {$IFDEF GTK4DEBUGMENUS}
  DebugLn('Gtk4RebuildMenuModel: rebuilding menu with ', IntToStr(AMenu.Items.Count), ' top-level items');
  {$ENDIF}
  BuildMenuItems(AModel, AActionGroup, AMenu.Items);

  { GTK4: Force menu icon visibility. GtkModelButton hides GtkImage when
    text is present. Walk the widget tree and force-show them. }
  if (AWin <> nil) and (AWin.GetMenuBar <> nil) then
  begin
    Gtk4ForceMenuIconsVisible(AWin.GetMenuBar);
    Gtk4AttachMenuHintControllers(AWin.GetMenuBar, AMenu.Items);
  end
  else if AMenu.HandleAllocated and (TGtk4MenuShell(AMenu.Handle).Widget <> nil) then
  begin
    Gtk4ForceMenuIconsVisible(TGtk4MenuShell(AMenu.Handle).Widget);
    Gtk4AttachMenuHintControllers(TGtk4MenuShell(AMenu.Handle).Widget, AMenu.Items);
  end;
end;

procedure Gtk4RebuildMenuModel(AMenu: TMenu);
var
  NextMenu: TMenu;
begin
  if AMenu = nil then
    Exit;
  if Gtk4MenuRebuildInProgress then
  begin
    Gtk4QueuePendingMenuRebuild(AMenu);
    Exit;
  end;

  Gtk4MenuRebuildInProgress := True;
  try
    Gtk4DoRebuildMenuModel(AMenu);
    while (Gtk4PendingMenuRebuilds <> nil) and (Gtk4PendingMenuRebuilds.Count > 0) do
    begin
      NextMenu := TMenu(Gtk4PendingMenuRebuilds[0]);
      Gtk4PendingMenuRebuilds.Delete(0);
      if (NextMenu <> nil) and not (csDestroying in NextMenu.ComponentState) then
        Gtk4DoRebuildMenuModel(NextMenu);
    end;
  finally
    Gtk4MenuRebuildInProgress := False;
  end;
end;

{ Idle callback: processes all deferred menu rebuilds in one pass }
function Gtk4DeferredRebuildIdleCB({%H-}data: gpointer): gboolean; cdecl;
var
  AMenu: TMenu;
begin
  Result := False; { G_SOURCE_REMOVE }
  Gtk4DeferredRebuildId := 0;
  if Gtk4PendingMenuRebuilds = nil then
    Exit;
  while Gtk4PendingMenuRebuilds.Count > 0 do
  begin
    AMenu := TMenu(Gtk4PendingMenuRebuilds[0]);
    Gtk4PendingMenuRebuilds.Delete(0);
    if (AMenu <> nil) and not (csDestroying in AMenu.ComponentState) then
      Gtk4RebuildMenuModel(AMenu);
  end;
end;

{ Queue a menu rebuild to run at idle time.
  Multiple calls with the same menu coalesce into a single rebuild.
  This turns O(n²) menu initialization into O(n). }
procedure Gtk4DeferredRebuildMenuModel(AMenu: TMenu);
begin
  if AMenu = nil then
    Exit;
  Gtk4QueuePendingMenuRebuild(AMenu);
  if Gtk4DeferredRebuildId = 0 then
    Gtk4DeferredRebuildId := g_idle_add(@Gtk4DeferredRebuildIdleCB, nil);
end;

{ Retry timer for rebuilds postponed while their popover was on screen.
  Timer-based (not idle) so a menu held open does not busy-spin the idle
  loop; each tick re-attempts, and Gtk4DoRebuildMenuModel re-postpones
  as long as the popover stays mapped. }
function Gtk4RebuildRetryCB({%H-}data: gpointer): gboolean; cdecl;
var
  AMenu: TMenu;
  Batch: TFPList;
  i: Integer;
begin
  Result := False; { G_SOURCE_REMOVE }
  Gtk4RetryTimerId := 0;
  if (Gtk4RetryRebuilds = nil) or (Gtk4RetryRebuilds.Count = 0) then
    Exit;
  { Detach the current batch: a menu still on screen gets re-postponed by
    the guard in Gtk4DoRebuildMenuModel INTO Gtk4RetryRebuilds — iterating
    the shared list directly would pop that re-added entry immediately and
    spin this callback forever while the menu stays open.  Re-postponed
    entries land in a fresh global list and run at the NEXT timer tick. }
  Batch := Gtk4RetryRebuilds;
  Gtk4RetryRebuilds := nil;
  try
    for i := 0 to Batch.Count - 1 do
    begin
      AMenu := TMenu(Batch[i]);
      if (AMenu <> nil) and not (csDestroying in AMenu.ComponentState) then
        Gtk4RebuildMenuModel(AMenu);
    end;
  finally
    Batch.Free;
  end;
end;

procedure Gtk4ScheduleRebuildRetry(AMenu: TMenu);
var
  i: Integer;
begin
  if AMenu = nil then
    Exit;
  if Gtk4RetryRebuilds = nil then
    Gtk4RetryRebuilds := TFPList.Create;
  for i := 0 to Gtk4RetryRebuilds.Count - 1 do
    if Gtk4RetryRebuilds[i] = Pointer(AMenu) then
    begin
      if Gtk4RetryTimerId = 0 then
        Gtk4RetryTimerId := g_timeout_add(150, @Gtk4RebuildRetryCB, nil);
      Exit;
    end;
  Gtk4RetryRebuilds.Add(Pointer(AMenu));
  if Gtk4RetryTimerId = 0 then
    Gtk4RetryTimerId := g_timeout_add(150, @Gtk4RebuildRetryCB, nil);
end;

{ ---- TGtk4WSMenuItem ---- }

class procedure TGtk4WSMenuItem.AttachMenu(const AMenuItem: TMenuItem);
begin
  {$IFDEF GTK4DEBUGMENUS}
  DebugLn('AttachMenu: "', AMenuItem.Caption, '"');
  {$ENDIF}
  if not AMenuItem.HandleAllocated then
  begin
    {$IFDEF GTK4DEBUGMENUS}
    DebugLn('WARNING: AttachMenu handle not allocated ', AMenuItem.Caption);
    {$ENDIF}
    exit;
  end;

  { GTK4: Defer the GMenu model rebuild to idle time.
    During menu initialization, AttachMenu is called once per item.
    Deferring coalesces n calls into a single rebuild → O(n) instead of O(n²). }
  Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
end;

class function TGtk4WSMenuItem.CreateHandle(const AMenuItem: TMenuItem): HMENU;
begin
  {$IFDEF GTK4DEBUGMENUS}
  DebugLn('TGtk4WSMenuItem.CreateHandle: "', AMenuItem.Caption, '"');
  {$ENDIF}
  Result := HMENU(TGtk4MenuItem.Create(AMenuItem));
end;

class procedure TGtk4WSMenuItem.DestroyHandle(const AMenuItem: TMenuItem);
var
  AModel: PGMenu;
  AActionGroup: PGSimpleActionGroup;
  Item: TGtk4MenuItem;
begin
  if not AMenuItem.HandleAllocated then
    Exit;
  Item := TGtk4MenuItem(AMenuItem.Handle);
  GetMenuModelAndActionGroup(AMenuItem, AModel, AActionGroup);
  if (AActionGroup <> nil) and (Item.ActionName <> '') then
    g_action_map_remove_action(PGActionMap(AActionGroup), PgChar(Item.ActionName));
  Item.Free;
end;

class procedure TGtk4WSMenuItem.SetCaption(const AMenuItem: TMenuItem;
  const ACaption: string);
var
  Item: TGtk4MenuItem;
begin
  if not WSCheckMenuItem(AMenuItem, 'SetCaption') then
    Exit;
  { GTK4: Update the GMenuItem label and rebuild the model.
    Deferred (idle-coalesced): popup OnPopup handlers update dozens of
    items in a row, and one immediate full rebuild per item made the
    context menu take ~1s to appear.  TGtk4WSPopupMenu.Popup performs a
    synchronous rebuild with the final state before showing. }
  Item := TGtk4MenuItem(AMenuItem.Handle);
  if Item.FGMenuItem <> nil then
    g_menu_item_set_label(Item.FGMenuItem,
      PgChar(ReplaceAmpersandsWithUnderscores(ACaption)));
  Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
end;

class procedure TGtk4WSMenuItem.SetShortCut(const AMenuItem: TMenuItem;
  const ShortCutK1, ShortCutK2: TShortCut);
var
  Item: TGtk4MenuItem;
  AKey: Word;
  AShift: TShiftState;
  AKeyval: guint;
  AMods: TGdkModifierType;
  AAccelStr: PgChar;
begin
  if not WSCheckMenuItem(AMenuItem, 'SetShortCut') then Exit;

  Item := TGtk4MenuItem(AMenuItem.Handle);
  if Item.FGMenuItem = nil then Exit;
  if not Gtk4IsObject(PGObject(Item.FGMenuItem)) then Exit;

  if ShortCutK1 = 0 then
  begin
    { Keep accel attribute non-NULL to avoid GTK regex warnings on popup. }
    g_menu_item_set_attribute_value(Item.FGMenuItem, 'accel',
      g_variant_new_string(''));
    Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
    Exit;
  end
  else
  begin
    { Convert TShortCut to VK key + shift state }
    ShortCutToKey(ShortCutK1, AKey, AShift);
    AKeyval := LCLKeyToGdkKeyval(AKey);
    if AKeyval = 0 then
    begin
      g_menu_item_set_attribute_value(Item.FGMenuItem, 'accel',
        g_variant_new_string(''));
      Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
      Exit;
    end;
    AMods := ShiftStateToGdkMods(AShift);

    { Build GTK accelerator string (e.g. "<Control>s") }
    AAccelStr := gtk_accelerator_name(AKeyval, AMods);
    if AAccelStr <> nil then
    begin
      g_menu_item_set_attribute_value(Item.FGMenuItem, 'accel',
        g_variant_new_string(AAccelStr));
      g_free(AAccelStr);
    end;
  end;

  { Rebuild the menu model so the shortcut label appears }
  Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
end;

class procedure TGtk4WSMenuItem.SetVisible(const AMenuItem: TMenuItem;
  const Visible: boolean);
begin
  if not WSCheckMenuItem(AMenuItem, 'SetVisible') then
    Exit;
  { GTK4: Rebuild the model - invisible items are simply not added }
  Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
end;

class function TGtk4WSMenuItem.SetCheck(const AMenuItem: TMenuItem;
  const Checked: boolean): boolean;
var
  Item: TGtk4MenuItem;
begin
  Result := False;
  if not WSCheckMenuItem(AMenuItem, 'SetCheck') then
    Exit;
  if AMenuItem.HandleAllocated then
  begin
    Item := TGtk4MenuItem(AMenuItem.Handle);
    Item.SetCheck(Checked);
    Result := True;
  end;
end;

class function TGtk4WSMenuItem.SetEnable(const AMenuItem: TMenuItem;
  const Enabled: boolean): boolean;
var
  Item: TGtk4MenuItem;
begin
  Result := False;
  if not WSCheckMenuItem(AMenuItem, 'SetEnable') then
    Exit;
  if AMenuItem.HandleAllocated then
  begin
    Item := TGtk4MenuItem(AMenuItem.Handle);
    Item.SetEnabled(Enabled and (AMenuItem.Caption <> cLineCaption));
    Result := True;
  end;
end;

class function TGtk4WSMenuItem.SetRadioItem(const AMenuItem: TMenuItem;
  const RadioItem: boolean): boolean;
var
  i: Integer;
  Sibling: TMenuItem;
begin
  { GTK4: radio items use STRING-state GActions with a target, check items
    boolean — a RadioItem flip changes the action shape, so the handle must
    be recreated. The LCL setter also flips same-group sibling FRadioItem
    fields DIRECTLY (no WS call for them), so recreate their handles too or
    they keep the old action shape and render the wrong indicator. }
  AMenuItem.RecreateHandle;
  if AMenuItem.Parent <> nil then
    for i := 0 to AMenuItem.Parent.Count - 1 do
    begin
      Sibling := AMenuItem.Parent.Items[i];
      if (Sibling <> AMenuItem) and (Sibling.GroupIndex = AMenuItem.GroupIndex) and
         (Sibling.GroupIndex <> 0) and Sibling.HandleAllocated and
         (Sibling.RadioItem = RadioItem) then
        Sibling.RecreateHandle;
    end;
  Result := True;
end;

class function TGtk4WSMenuItem.SetRightJustify(const AMenuItem: TMenuItem;
  const Justified: boolean): boolean;
begin
  Result := False;
  if not WSCheckMenuItem(AMenuItem, 'SetRightJustify') then
    Exit;
  { GTK4: Right-justify is not supported in GtkPopoverMenuBar }
  Result := False;
end;

class procedure TGtk4WSMenuItem.UpdateMenuIcon(const AMenuItem: TMenuItem;
  const HasIcon: Boolean; const AIcon: TBitmap);
var
  Item: TGtk4MenuItem;
  AMenuIcon: PGIcon;
begin
  if not WSCheckMenuItem(AMenuItem, 'UpdateMenuIcon') then
    Exit;

  if not (TObject(AMenuItem.Handle) is TGtk4MenuItem) then
    Exit;
  Item := TGtk4MenuItem(AMenuItem.Handle);
  if Item.FGMenuItem = nil then Exit;
  if not Gtk4IsObject(PGObject(Item.FGMenuItem)) then Exit;

  AMenuIcon := nil;
  if HasIcon then
    AMenuIcon := Gtk4CreateMenuIconFromMenuItem(AMenuItem);
  try
    g_menu_item_set_icon(Item.FGMenuItem, AMenuIcon);
  finally
    Gtk4SafeUnref(PGObject(AMenuIcon));
  end;

  Gtk4DeferredRebuildMenuModel(AMenuItem.GetParentMenu);
end;

{ ---- TGtk4WSMenu ---- }

class function TGtk4WSMenu.CreateHandle(const AMenu: TMenu): HMENU;
var
  AWin: TGtk4Window;
begin
  {$IFDEF GTK4DEBUGMENUS}
  DebugLn('TGtk4WSMenu.CreateHandle: ', AMenu.ClassName);
  {$ENDIF}
  if (AMenu is TMainMenu) and (AMenu.Owner is TCustomForm) then
  begin
    { For main menus, wrap the form's existing GtkPopoverMenuBar widget }
    AWin := TGtk4Window(TCustomForm(AMenu.Owner).Handle);
    Result := HMENU(TGtk4MenuBar.Create(AMenu, AWin.GetMenuBar));
    { Share the form's model and action group }
    TGtk4MenuBar(Result).FMenuModel := AWin.GetMenuModel;
    TGtk4MenuBar(Result).FActionGroup := AWin.GetMenuActionGroup;
  end
  else
  begin
    Result := HMENU(TGtk4MenuBar.Create(AMenu, nil));
  end;
end;

class procedure TGtk4WSMenu.SetBiDiMode(const AMenu : TMenu;
  UseRightToLeftAlign, UseRightToLeftReading : Boolean);
begin
  { GTK4: GtkPopoverMenuBar handles BiDi through GTK's own CSS direction.
    Set the text direction on the widget. }
  if (AMenu is TMainMenu) and AMenu.HandleAllocated then
  begin
    if TGtk4MenuBar(AMenu.Handle).Widget <> nil then
    begin
      if UseRightToLeftReading then
        TGtk4MenuBar(AMenu.Handle).Widget^.set_direction(GTK_TEXT_DIR_RTL)
      else
        TGtk4MenuBar(AMenu.Handle).Widget^.set_direction(GTK_TEXT_DIR_LTR);
    end;
  end;
end;

{ ---- TGtk4WSPopupMenu ---- }

type
  { Helper record for popup menu event loop }
  TPopupMenuInfo = record
    Loop: PGMainLoop;
    Menu: TGtk4Menu;
    Closed: Boolean;
  end;
  PPopupMenuInfo = ^TPopupMenuInfo;

procedure Gtk4PopupMenuClosed({%H-}popover: PGtkWidget; data: gpointer); cdecl;
var
  Info: PPopupMenuInfo;
begin
  Info := PPopupMenuInfo(data);
  Info^.Closed := True;
  if (Info^.Loop <> nil) and g_main_loop_is_running(Info^.Loop) then
    g_main_loop_quit(Info^.Loop);
end;

class function TGtk4WSPopupMenu.CreateHandle(const AMenu: TMenu): HMENU;
begin
  Result := HMENU(TGtk4Menu.Create(AMenu, nil));
end;

class procedure TGtk4WSPopupMenu.Popup(const APopupMenu: TPopupMenu; const X,
  Y: integer);
var
  AMenuObj: TGtk4Menu;
  APopover: PGtkWidget;
  ARect: TGdkRectangle;
  AForm: TCustomForm;
  AFormWidget: PGtkWidget;
  Info: TPopupMenuInfo;
  HandlerId: gulong;
  APos: TPoint;
  ASavedFocus: TObject;
  AAlignment: TPopupAlignment;
  AContents: PGtkWidget;
  AMinW, ANatW: gint;
begin
  if not APopupMenu.HandleAllocated then exit;
  AMenuObj := TGtk4Menu(APopupMenu.Handle);
  ASavedFocus := Gtk4SaveFocusOwner;

  { Rebuild model before showing }
  Gtk4RebuildMenuModel(APopupMenu);

  if AMenuObj.FMenuModel = nil then exit;

  { Create a FRESH GtkPopoverMenu from the (now final) model for every
    Popup.  The persistent popover created in TGtk4Menu.CreateWidget is
    bound to a model that gets remove_all+rebuilt on every item change —
    LCL's OnPopup handlers update dozens of items before this point, and
    each rebuild makes GtkPopoverMenu re-add submenu stack pages while the
    old ones are still registered ("duplicate child name in GtkStack"
    warnings), leaving the popover's internal stack broken (nothing is
    rendered).  A fresh popover syncs the finished model exactly once. }
  APopover := gtk4_popover_menu_new_from_model(PGMenuModel(AMenuObj.FMenuModel));
  if APopover = nil then exit;
  gtk4_popover_set_has_arrow(APopover, False);
  if AMenuObj.FActionGroup <> nil then
    gtk_widget_insert_action_group(APopover, PgChar('menu'),
      PGActionGroup(AMenuObj.FActionGroup));

  { GtkPopoverMenu needs a parent widget to position relative to.
    Find the form that owns this popup menu. }
  AForm := nil;
  if APopupMenu.PopupComponent is TControl then
    AForm := GetParentForm(TControl(APopupMenu.PopupComponent))
  else if APopupMenu.Owner is TCustomForm then
    AForm := TCustomForm(APopupMenu.Owner);

  { The popover parent must be a widget whose size_allocate runs through a
    GtkLayoutManager: popover children are presented ONLY by
    gtk_layout_manager_allocate -> allocate_native_children
    (gtklayoutmanager.c).  GtkWindow has a custom size_allocate that only
    allocates its set_child — a popover parented to the WINDOW is never
    presented (grab + Escape work, but nothing is drawn).  Use the form's
    content GtkBox (GtkBoxLayout) instead; gtk_widget_should_layout
    excludes surface-owning children, so the popover does not disturb the
    box layout. }
  { Fallback for programmatic popups (PopupComponent=nil, owner not a
    form — allowed by TPopupMenu.PopUp, e.g. tray icons). }
  if AForm = nil then
    AForm := Screen.ActiveCustomForm;
  if AForm = nil then
    AForm := Application.MainForm;

  if (AForm <> nil) and AForm.HandleAllocated then
  begin
    AFormWidget := PGtkWidget(TGtk4Window(AForm.Handle).GetBox);
    if AFormWidget = nil then
      AFormWidget := TGtk4Window(AForm.Handle).Widget;
  end
  else
    exit;


  { Set the popover parent to the form's content box }
  PGtkWidget(APopover)^.set_parent(AFormWidget);

  { Apply the menu icon visibility workaround to THIS popover (the rebuild
    path only walks the persistent one created in TGtk4Menu.CreateWidget). }
  Gtk4ForceMenuIconsVisible(APopover);
  Gtk4AttachMenuHintControllers(APopover, APopupMenu.Items);

  { Position the popover: TPopupMenu.PopUp passes SCREEN coordinates, but
    gtk_popover_set_pointing_to expects them relative to the popover's
    parent (the form content box).  ScreenToClient yields form CLIENT
    coordinates (below the menu bar); FBox starts at the window content
    origin, so add the client-area offset back. }
  APos := Point(X, Y);
  TGtk4Window(AForm.Handle).ScreenToClient(APos);
  with TGtk4Window(AForm.Handle).GetClientAreaOffset do
  begin
    Inc(APos.X, X);
    Inc(APos.Y, Y);
  end;
  ARect.x := APos.X;
  ARect.y := APos.Y;
  ARect.width := 1;
  ARect.height := 1;
  gtk4_popover_set_pointing_to(APopover, @ARect);

  { TPopupMenu.Alignment. GtkPopover CENTERS itself on the pointing-to
    rect, so unshifted popups behave like paCenter. Measure the popover's
    natural width (valid after set_parent) and shift by half of it via
    gtk_popover_set_offset: +w/2 puts the LEFT edge on the point (paLeft,
    the LCL default), -w/2 the RIGHT edge (paRight). RTL swaps left/right,
    same rule as gtk2's GtkWS_Popup. gtk2's vertical monitor clamp has no
    GTK4 equivalent duty: GDK popup slide/flip anchor hints already keep
    the surface visible. }
  begin
    AAlignment := APopupMenu.Alignment;
    if APopupMenu.UseRightToLeftAlignment then
    begin
      if AAlignment = paLeft then
        AAlignment := paRight
      else if AAlignment = paRight then
        AAlignment := paLeft;
    end;
    if AAlignment <> paCenter then
    begin
      { The popover itself is still visible=FALSE (popup() maps it later),
        and gtk_widget_measure reports 0 for invisible widgets. Its
        contents child IS visible, and its width is the visual menu box
        (padding included, shadow excluded) — exactly the edge Alignment
        must align. }
      AContents := gtk4_widget_get_first_child(APopover);
      if AContents <> nil then
      begin
        AMinW := 0;
        ANatW := 0;
        gtk4_widget_measure(AContents, GTK_ORIENTATION_HORIZONTAL, -1,
          @AMinW, @ANatW, nil, nil);
        case AAlignment of
          paLeft: gtk4_popover_set_offset(APopover, ANatW div 2, 0);
          paRight: gtk4_popover_set_offset(APopover, -(ANatW div 2), 0);
        end;
      end;
    end;
  end;

  { Prepare the nested loop and connect 'closed' BEFORE popup() — a popover
    that fails or closes synchronously must not leave the loop running. }
  FillChar(Info, SizeOf(Info), 0);
  Info.Menu := AMenuObj;
  Info.Closed := False;
  Info.Loop := g_main_loop_new(nil, False);
  HandlerId := g_signal_connect_data(APopover, 'closed',
    TGCallback(@Gtk4PopupMenuClosed), @Info, nil, G_CONNECT_DEFAULT);

  { Show the popover }
  gtk4_popover_popup(APopover);

  { Run a nested main loop until the popover closes.  While it runs, block
    model rebuilds for THIS menu (deferred rebuilds fire inside the nested
    loop and would destroy the open popup's widgets). }
  Gtk4ActivePopupMenu := APopupMenu;
  try
    if not Info.Closed then
      g_main_loop_run(Info.Loop);
  finally
    Gtk4ActivePopupMenu := nil;
  end;

  g_main_loop_unref(Info.Loop);
  { A menu action may have destroyed the owning form (and with it the
    parent box and this popover) — validate before touching the widget. }
  if Gtk4IsWidget(PGObject(APopover)) then
  begin
    g_signal_handler_disconnect(APopover, HandlerId);
    { Unparent the popover after closing — the parent held the only
      reference (new_from_model returned a floating ref sunk by
      set_parent), so this also disposes the per-popup popover. }
    PGtkWidget(APopover)^.unparent;
  end;

  { Restore keyboard focus to the pre-menu control (win32 semantics) —
    GTK's fallback focus after the popover disappears lands on an
    arbitrary widget otherwise.  Skipped if a menu action moved focus to
    another (now active) window. }
  Gtk4RestoreFocusOwner(ASavedFocus);

  { Notify LCL }
  APopupMenu.Close;
end;

finalization
  if Gtk4DeferredRebuildId <> 0 then
  begin
    g_source_remove(Gtk4DeferredRebuildId);
    Gtk4DeferredRebuildId := 0;
  end;
  if Gtk4RetryTimerId <> 0 then
  begin
    g_source_remove(Gtk4RetryTimerId);
    Gtk4RetryTimerId := 0;
  end;
  FreeAndNil(Gtk4PendingMenuRebuilds);
  FreeAndNil(Gtk4RetryRebuilds);

end.
