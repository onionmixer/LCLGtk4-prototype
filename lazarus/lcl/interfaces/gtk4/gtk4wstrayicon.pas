{
 *****************************************************************************
 *                               gtk4WSTrayIcon.pas                          *
 *                               ------------------                          *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
  This file is part of the Lazarus Component Library (LCL)

  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  StatusNotifierItem (SNI) D-Bus implementation for GTK4 TrayIcon.
  (Linux only - requires D-Bus session bus and SNI-compatible desktop
  environment: GNOME with AppIndicator extension, KDE Plasma, XFCE,
  MATE, Cinnamon, Ubuntu desktop)

  Uses GDBus (GIO) to implement the org.kde.StatusNotifierItem D-Bus
  protocol directly, without dependency on libappindicator or GTK3.
  Context menus are provided via libdbusmenu-glib (dynamically loaded).

  Replaces the previous libappindicator3-based implementation which had
  GTK3/GTK4 ABI incompatibility issues (GtkMenu removed in GTK4).
}

unit Gtk4WSTrayIcon;

interface

{$mode objfpc}{$H+}

uses
  LazGLib2, LazGObject2, LazGio2, LazGdkPixbuf2,
  Classes, SysUtils, dynlibs,
  Graphics, Controls, Forms, ExtCtrls, Menus, WSExtCtrls, LCLType;

type

  { TGtk4WSTrayIcon }
  { (Linux only) SNI D-Bus tray icon backend for GTK4 }

  TGtk4WSTrayIcon = class(TWSCustomTrayIcon)
  published
    class function Hide(const ATrayIcon: TCustomTrayIcon): Boolean; override;
    class function Show(const ATrayIcon: TCustomTrayIcon): Boolean; override;
    class procedure InternalUpdate(const ATrayIcon: TCustomTrayIcon); override;
    class function ShowBalloonHint(const ATrayIcon: TCustomTrayIcon): Boolean; override;
    class function GetPosition(const {%H-}ATrayIcon: TCustomTrayIcon): TPoint; override;
  end;

{ (Linux only) Returns True if D-Bus session bus is available for SNI }
function Gtk4SNITrayIconInit: Boolean;

implementation

uses gtk4objects;

const
  { SNI D-Bus constants }
  SNI_OBJECT_PATH       = '/StatusNotifierItem';
  SNI_MENU_OBJECT_PATH  = '/MenuBar';
  SNI_WATCHER_BUS_NAME  = 'org.kde.StatusNotifierWatcher';
  SNI_WATCHER_OBJ_PATH  = '/StatusNotifierWatcher';
  SNI_WATCHER_INTERFACE = 'org.kde.StatusNotifierWatcher';
  SNI_INTERFACE         = 'org.kde.StatusNotifierItem';

  { Icon file type }
  IconType = 'png';

  { libdbusmenu-glib library name (Linux only) }
  libdbusmenu_glib = 'libdbusmenu-glib.so.4';

  { libdbusmenu property constants }
  DBUSMENU_MENUITEM_PROP_LABEL       = 'label';
  DBUSMENU_MENUITEM_PROP_ENABLED     = 'enabled';
  DBUSMENU_MENUITEM_PROP_VISIBLE     = 'visible';
  DBUSMENU_MENUITEM_PROP_TYPE        = 'type';
  DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE = 'toggle-type';
  DBUSMENU_MENUITEM_PROP_TOGGLE_STATE = 'toggle-state';
  DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY = 'children-display';
  DBUSMENU_MENUITEM_TYPE_SEPARATOR   = 'separator';
  DBUSMENU_MENUITEM_CHILD_DISPLAY_SUBMENU = 'submenu';

  { SNI D-Bus introspection XML (Linux only) }
  SNI_INTROSPECTION_XML =
    '<node>' +
    '  <interface name="org.kde.StatusNotifierItem">' +
    '    <method name="Activate">' +
    '      <arg type="i" name="x" direction="in"/>' +
    '      <arg type="i" name="y" direction="in"/>' +
    '    </method>' +
    '    <method name="ContextMenu">' +
    '      <arg type="i" name="x" direction="in"/>' +
    '      <arg type="i" name="y" direction="in"/>' +
    '    </method>' +
    '    <method name="SecondaryActivate">' +
    '      <arg type="i" name="x" direction="in"/>' +
    '      <arg type="i" name="y" direction="in"/>' +
    '    </method>' +
    '    <method name="Scroll">' +
    '      <arg type="i" name="delta" direction="in"/>' +
    '      <arg type="s" name="orientation" direction="in"/>' +
    '    </method>' +
    '    <property name="Category" type="s" access="read"/>' +
    '    <property name="Id" type="s" access="read"/>' +
    '    <property name="Title" type="s" access="read"/>' +
    '    <property name="Status" type="s" access="read"/>' +
    '    <property name="WindowId" type="u" access="read"/>' +
    '    <property name="IconName" type="s" access="read"/>' +
    '    <property name="IconThemePath" type="s" access="read"/>' +
    '    <property name="IconPixmap" type="a(iiay)" access="read"/>' +
    '    <property name="ToolTip" type="(sa(iiay)ss)" access="read"/>' +
    '    <property name="ItemIsMenu" type="b" access="read"/>' +
    '    <property name="Menu" type="o" access="read"/>' +
    '    <signal name="NewIcon"/>' +
    '    <signal name="NewToolTip"/>' +
    '    <signal name="NewStatus">' +
    '      <arg type="s" name="status"/>' +
    '    </signal>' +
    '  </interface>' +
    '</node>';

type
  { libdbusmenu-glib function types (Linux only) }
  PDbusmenuServer = Pointer;
  PDbusmenuMenuitem = Pointer;

var
  { libdbusmenu-glib dynamic loading (Linux only) }
  DbusmenuModule: TLibHandle = 0;
  DbusmenuLoaded: Boolean = False;
  DbusmenuAvailable: Boolean = False;
  SNITrayIconInstanceCounter: PtrUInt = 0;

  dbusmenu_server_new: function(object_path: PGChar): PDbusmenuServer; cdecl;
  dbusmenu_server_set_root: procedure(server: PDbusmenuServer; root: PDbusmenuMenuitem); cdecl;
  dbusmenu_menuitem_new: function: PDbusmenuMenuitem; cdecl;
  dbusmenu_menuitem_child_append: function(parent: PDbusmenuMenuitem; child: PDbusmenuMenuitem): gboolean; cdecl;
  dbusmenu_menuitem_property_set: function(item: PDbusmenuMenuitem; prop: PGChar; value: PGChar): gboolean; cdecl;
  dbusmenu_menuitem_property_set_bool: function(item: PDbusmenuMenuitem; prop: PGChar; value: gboolean): gboolean; cdecl;
  dbusmenu_menuitem_property_set_int: function(item: PDbusmenuMenuitem; prop: PGChar; value: gint): gboolean; cdecl;

type

  { TSNITrayIconHandle }
  { (Linux only) Manages a single SNI tray icon instance via D-Bus }

  TSNITrayIconHandle = class
  private
    FTrayIcon: TCustomTrayIcon;
    FConnection: PGDBusConnection;
    FNodeInfo: PGDBusNodeInfo;
    FRegistrationId: guint;
    FBusNameId: guint;
    FIconDir: string;
    FIconPath: string;
    FIconName: string;
    FAppId: string;
    FBusName: string;
    FObjectPath: string;
    FMenuObjectPath: string;
    FMenuServer: PDbusmenuServer;
    FReady: Boolean;
    function BuildIconPixmapsVariant: PGVariant;
    function CurrentIconPixbuf: PGdkPixbuf;
    function SetupDBus: Boolean;
    procedure TeardownDBus;
    function RegisterWithWatcher: Boolean;
    procedure SaveIcon;
    procedure BuildMenu;
    procedure BuildMenuItems(AParent: PDbusmenuMenuitem; AMenuItem: TMenuItem);
    procedure EmitSignal(const ASignalName: string);
  public
    constructor Create(ATrayIcon: TCustomTrayIcon);
    destructor Destroy; override;
    procedure Update;
  end;

{ Forward declarations for GDBus callbacks }
procedure SNIMethodCall(
  {%H-}connection: PGDBusConnection;
  {%H-}sender: PGChar;
  {%H-}object_path: PGChar;
  {%H-}interface_name: PGChar;
  method_name: PGChar;
  {%H-}parameters: PGVariant;
  invocation: PGDBusMethodInvocation;
  user_data: gpointer); cdecl; forward;

function SNIGetProperty(
  {%H-}connection: PGDBusConnection;
  {%H-}sender: PGChar;
  {%H-}object_path: PGChar;
  {%H-}interface_name: PGChar;
  property_name: PGChar;
  {%H-}error: PPGError;
  user_data: gpointer): PGVariant; cdecl; forward;

var
  { Global VTable for SNI D-Bus interface (Linux only) }
  SNIVTable: TGDBusInterfaceVTable;

{ (Linux only) Try to load libdbusmenu-glib dynamically }
function LoadDbusmenu: Boolean;

  function TryLoad(const ProcName: string; var Proc: Pointer): Boolean;
  begin
    Proc := GetProcAddress(DbusmenuModule, ProcName);
    Result := Proc <> nil;
  end;

begin
  if DbusmenuLoaded then
    Exit(DbusmenuAvailable);
  DbusmenuLoaded := True;
  DbusmenuModule := LoadLibrary(libdbusmenu_glib);
  if DbusmenuModule = 0 then
    Exit(False);
  Result :=
    TryLoad('dbusmenu_server_new', Pointer(dbusmenu_server_new)) and
    TryLoad('dbusmenu_server_set_root', Pointer(dbusmenu_server_set_root)) and
    TryLoad('dbusmenu_menuitem_new', Pointer(dbusmenu_menuitem_new)) and
    TryLoad('dbusmenu_menuitem_child_append', Pointer(dbusmenu_menuitem_child_append)) and
    TryLoad('dbusmenu_menuitem_property_set', Pointer(dbusmenu_menuitem_property_set)) and
    TryLoad('dbusmenu_menuitem_property_set_bool', Pointer(dbusmenu_menuitem_property_set_bool)) and
    TryLoad('dbusmenu_menuitem_property_set_int', Pointer(dbusmenu_menuitem_property_set_int));
  DbusmenuAvailable := Result;
end;

{ libdbusmenu-glib menu item activated callback (Linux only) }
procedure DbusmenuItemActivated({%H-}menuitem: PDbusmenuMenuitem;
  {%H-}timestamp: guint; user_data: gpointer); cdecl;
var
  LCLItem: TMenuItem;
begin
  if user_data <> nil then
  begin
    LCLItem := TMenuItem(user_data);
    LCLItem.Click;
  end;
end;

{ ---- TSNITrayIconHandle ---- }

constructor TSNITrayIconHandle.Create(ATrayIcon: TCustomTrayIcon);
var
  AInstanceId: PtrUInt;
begin
  inherited Create;
  FTrayIcon := ATrayIcon;
  Inc(SNITrayIconInstanceCounter);
  AInstanceId := SNITrayIconInstanceCounter;
  FAppId := 'lcl-' + IntToStr(GetProcessID) + '-' + IntToStr(AInstanceId);
  FBusName := 'org.kde.StatusNotifierItem-' + IntToStr(GetProcessID) + '-' +
    IntToStr(AInstanceId);
  if AInstanceId = 1 then
  begin
    FObjectPath := SNI_OBJECT_PATH;
    FMenuObjectPath := SNI_MENU_OBJECT_PATH;
  end
  else
  begin
    FObjectPath := SNI_OBJECT_PATH + '/Item' + IntToStr(AInstanceId);
    FMenuObjectPath := SNI_MENU_OBJECT_PATH + '/Item' + IntToStr(AInstanceId);
  end;
  FIconDir := GetEnvironmentVariable('XDG_RUNTIME_DIR');
  if FIconDir = '' then
    FIconDir := '/tmp';
  FIconDir := FIconDir + '/lcl-sni-' + GetEnvironmentVariable('USER') + '/';
  FConnection := nil;
  FNodeInfo := nil;
  FRegistrationId := 0;
  FBusNameId := 0;
  FMenuServer := nil;
  FReady := False;
  SaveIcon;
  FReady := SetupDBus;
end;

destructor TSNITrayIconHandle.Destroy;
begin
  TeardownDBus;
  { Clean up temp icon file }
  if (FIconPath <> '') and FileExists(FIconPath) then
    DeleteFile(FIconPath);
  inherited Destroy;
end;

function TSNITrayIconHandle.CurrentIconPixbuf: PGdkPixbuf;

  function IconToPixbuf(AIcon: TIcon): PGdkPixbuf;
  var
    AHandle: HICON;
  begin
    Result := nil;
    if (AIcon = nil) or AIcon.Empty then
      Exit;

    AHandle := AIcon.Handle;
    if (AHandle <> 0) and (TObject(AHandle) is TGtk4Image) then
      Result := TGtk4Image(AHandle).Handle;
  end;

begin
  Result := nil;
  if FTrayIcon <> nil then
    Result := IconToPixbuf(FTrayIcon.Icon);
  if Result = nil then
    Result := IconToPixbuf(Application.Icon);
end;

function TSNITrayIconHandle.BuildIconPixmapsVariant: PGVariant;
var
  APixbuf: PGdkPixbuf;
  AWidth, AHeight, ARowStride, AChannels, X, Y: gint;
  ASrcRow, ASrcPixel: PByte;
  ABytes: array of guint8;
  ADestIndex: SizeInt;
  AArrayType, ABytesType: PGVariantType;
  AArrayBuilder, ABytesBuilder: PGVariantBuilder;
  AByteVariant, APixmapVariant: PGVariant;
  ATupleChildren: array[0..2] of PGVariant;
begin
  APixbuf := CurrentIconPixbuf;
  if (APixbuf = nil) or (gdk_pixbuf_get_bits_per_sample(APixbuf) <> 8) then
  begin
    AArrayType := g_variant_type_new('a(iiay)');
    AArrayBuilder := g_variant_builder_new(AArrayType);
    Result := g_variant_builder_end(AArrayBuilder);
    g_variant_builder_unref(AArrayBuilder);
    g_variant_type_free(AArrayType);
    Exit;
  end;

  AWidth := gdk_pixbuf_get_width(APixbuf);
  AHeight := gdk_pixbuf_get_height(APixbuf);
  AChannels := gdk_pixbuf_get_n_channels(APixbuf);
  if (AWidth <= 0) or (AHeight <= 0) or not (AChannels in [3, 4]) then
  begin
    AArrayType := g_variant_type_new('a(iiay)');
    AArrayBuilder := g_variant_builder_new(AArrayType);
    Result := g_variant_builder_end(AArrayBuilder);
    g_variant_builder_unref(AArrayBuilder);
    g_variant_type_free(AArrayType);
    Exit;
  end;

  ABytes := nil;
  ARowStride := gdk_pixbuf_get_rowstride(APixbuf);
  SetLength(ABytes, AWidth * AHeight * 4);
  ADestIndex := 0;
  ASrcRow := PByte(gdk_pixbuf_get_pixels(APixbuf));
  for Y := 0 to AHeight - 1 do
  begin
    ASrcPixel := ASrcRow;
    for X := 0 to AWidth - 1 do
    begin
      if AChannels = 4 then
        ABytes[ADestIndex] := (ASrcPixel + 3)^
      else
        ABytes[ADestIndex] := 255;
      ABytes[ADestIndex + 1] := ASrcPixel^;
      ABytes[ADestIndex + 2] := (ASrcPixel + 1)^;
      ABytes[ADestIndex + 3] := (ASrcPixel + 2)^;
      Inc(ADestIndex, 4);
      Inc(ASrcPixel, AChannels);
    end;
    Inc(ASrcRow, ARowStride);
  end;

  ABytesType := g_variant_type_new('ay');
  ABytesBuilder := g_variant_builder_new(ABytesType);
  for ADestIndex := 0 to High(ABytes) do
  begin
    AByteVariant := g_variant_new_byte(ABytes[ADestIndex]);
    g_variant_builder_add_value(ABytesBuilder, AByteVariant);
  end;
  ATupleChildren[0] := g_variant_new_int32(AWidth);
  ATupleChildren[1] := g_variant_new_int32(AHeight);
  ATupleChildren[2] := g_variant_builder_end(ABytesBuilder);
  g_variant_builder_unref(ABytesBuilder);
  g_variant_type_free(ABytesType);

  APixmapVariant := g_variant_new_tuple(@ATupleChildren[0], 3);

  AArrayType := g_variant_type_new('a(iiay)');
  AArrayBuilder := g_variant_builder_new(AArrayType);
  g_variant_builder_add_value(AArrayBuilder, APixmapVariant);
  Result := g_variant_builder_end(AArrayBuilder);
  g_variant_builder_unref(AArrayBuilder);
  g_variant_type_free(AArrayType);
end;

procedure TSNITrayIconHandle.SaveIcon;
var
  APixbuf: PGdkPixbuf;
  AError: PGError;

begin
  APixbuf := CurrentIconPixbuf;
  if APixbuf = nil then
  begin
    if (FIconPath <> '') and FileExists(FIconPath) then
      DeleteFile(FIconPath);
    FIconPath := '';
    FIconName := '';
    Exit;
  end;

  FIconName := FAppId + '-icon';
  ForceDirectories(FIconDir);
  if (FIconPath <> '') and FileExists(FIconPath) then
    DeleteFile(FIconPath);
  FIconPath := FIconDir + FIconName + '.' + IconType;
  AError := nil;
  if not gdk_pixbuf_save(APixbuf, PChar(FIconPath), IconType, @AError, [nil]) then
  begin
    if AError <> nil then
      g_error_free(AError);
    FIconPath := '';
    FIconName := '';
  end;
end;

function TSNITrayIconHandle.SetupDBus: Boolean;
var
  AError: PGError;
begin
  Result := False;
  AError := nil;

  { 1. Connect to session D-Bus (Linux only) }
  FConnection := g_bus_get_sync(G_BUS_TYPE_SESSION, nil, @AError);
  if FConnection = nil then
  begin
    if AError <> nil then
      g_error_free(AError);
    Exit;
  end;

  { 2. Parse introspection XML }
  FNodeInfo := g_dbus_node_info_new_for_xml(PGChar(SNI_INTROSPECTION_XML), @AError);
  if FNodeInfo = nil then
  begin
    if AError <> nil then
      g_error_free(AError);
    Exit;
  end;

  { 3. Register SNI object on D-Bus }
  SNIVTable.method_call := @SNIMethodCall;
  SNIVTable.get_property := @SNIGetProperty;
  SNIVTable.set_property := nil;
  FillChar(SNIVTable.padding, SizeOf(SNIVTable.padding), 0);

  FRegistrationId := g_dbus_connection_register_object(
    FConnection,
    PGChar(FObjectPath),
    FNodeInfo^.interfaces^,  { first interface = org.kde.StatusNotifierItem }
    @SNIVTable,
    Self,   { user_data }
    nil,    { user_data_free_func }
    @AError);
  if FRegistrationId = 0 then
  begin
    if AError <> nil then
      g_error_free(AError);
    Exit;
  end;

  { 4. Setup libdbusmenu for context menu (Linux only) }
  if LoadDbusmenu then
  begin
    FMenuServer := dbusmenu_server_new(PGChar(FMenuObjectPath));
    BuildMenu;
  end;

  { 5. Own a per-instance well-known bus name for inspection and hosts that
    resolve items by service name. The watcher registration below uses the
    object path, so setup correctness does not depend on async name acquisition. }
  FBusNameId := g_bus_own_name_on_connection(
    FConnection,
    PGChar(FBusName),
    G_BUS_NAME_OWNER_FLAGS_NONE,
    nil,  { name_acquired_handler }
    nil,  { name_lost_handler }
    Self,
    nil);

  { 6. Register with StatusNotifierWatcher }
  Result := RegisterWithWatcher;
end;

procedure TSNITrayIconHandle.TeardownDBus;
begin
  if FMenuServer <> nil then
  begin
    g_object_unref(FMenuServer);
    FMenuServer := nil;
  end;
  if (FRegistrationId <> 0) and (FConnection <> nil) then
  begin
    g_dbus_connection_unregister_object(FConnection, FRegistrationId);
    FRegistrationId := 0;
  end;
  if FBusNameId <> 0 then
  begin
    g_bus_unown_name(FBusNameId);
    FBusNameId := 0;
  end;
  if FNodeInfo <> nil then
  begin
    g_dbus_node_info_unref(FNodeInfo);
    FNodeInfo := nil;
  end;
  { Connection is owned by GIO, don't unref }
  FConnection := nil;
end;

function TSNITrayIconHandle.RegisterWithWatcher: Boolean;
var
  AError: PGError;
  AParam: PGVariant;
  AReply: PGVariant;
begin
  Result := False;
  if FConnection = nil then Exit;
  AError := nil;

  { Register by object path so multiple tray icons on one D-Bus connection do
    not collide on the SNI default /StatusNotifierItem path. }
  AParam := g_variant_new_string(PGChar(FObjectPath));
  AParam := g_variant_new_tuple(@AParam, 1);

  { Call org.kde.StatusNotifierWatcher.RegisterStatusNotifierItem(object_path) }
  AReply := g_dbus_connection_call_sync(
    FConnection,
    PGChar(SNI_WATCHER_BUS_NAME),
    PGChar(SNI_WATCHER_OBJ_PATH),
    PGChar(SNI_WATCHER_INTERFACE),
    'RegisterStatusNotifierItem',
    AParam,
    nil,  { reply_type }
    G_DBUS_CALL_FLAGS_NONE,
    5000,  { timeout ms — avoid infinite block if D-Bus service unresponsive }
    nil,  { cancellable }
    @AError);
  if AError <> nil then
  begin
    g_error_free(AError);
    Exit;
  end;
  if AReply <> nil then
    g_variant_unref(AReply);
  Result := True;
end;

procedure TSNITrayIconHandle.BuildMenu;
var
  ARoot: PDbusmenuMenuitem;
begin
  if (FMenuServer = nil) or not DbusmenuAvailable then Exit;

  ARoot := dbusmenu_menuitem_new();
  if (FTrayIcon.PopUpMenu <> nil) and (FTrayIcon.PopUpMenu.Items.Count > 0) then
    BuildMenuItems(ARoot, FTrayIcon.PopUpMenu.Items);
  dbusmenu_server_set_root(FMenuServer, ARoot);
  { server takes ownership of root, but root is a GObject — no explicit free }
end;

procedure TSNITrayIconHandle.BuildMenuItems(AParent: PDbusmenuMenuitem;
  AMenuItem: TMenuItem);
var
  i: Integer;
  LCLItem: TMenuItem;
  DItem: PDbusmenuMenuitem;
begin
  for i := 0 to AMenuItem.Count - 1 do
  begin
    LCLItem := AMenuItem.Items[i];
    DItem := dbusmenu_menuitem_new();

    if LCLItem.Caption = '-' then
    begin
      { Separator }
      dbusmenu_menuitem_property_set(DItem, DBUSMENU_MENUITEM_PROP_TYPE,
        PGChar(DBUSMENU_MENUITEM_TYPE_SEPARATOR));
    end else
    begin
      { Normal menu item }
      dbusmenu_menuitem_property_set(DItem, DBUSMENU_MENUITEM_PROP_LABEL,
        PGChar(LCLItem.Caption));
      dbusmenu_menuitem_property_set_bool(DItem, DBUSMENU_MENUITEM_PROP_ENABLED,
        LCLItem.Enabled);
      dbusmenu_menuitem_property_set_bool(DItem, DBUSMENU_MENUITEM_PROP_VISIBLE,
        LCLItem.Visible);

      { Checkbox / radio items }
      if LCLItem.IsCheckItem then
      begin
        if LCLItem.RadioItem then
          dbusmenu_menuitem_property_set(DItem, DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE,
            'radio')
        else
          dbusmenu_menuitem_property_set(DItem, DBUSMENU_MENUITEM_PROP_TOGGLE_TYPE,
            'checkmark');
        if LCLItem.Checked then
          dbusmenu_menuitem_property_set_int(DItem, DBUSMENU_MENUITEM_PROP_TOGGLE_STATE, 1)
        else
          dbusmenu_menuitem_property_set_int(DItem, DBUSMENU_MENUITEM_PROP_TOGGLE_STATE, 0);
      end;

      { Connect click callback }
      g_signal_connect_data(DItem, 'item-activated',
        TGCallback(@DbusmenuItemActivated), LCLItem, nil, G_CONNECT_DEFAULT);

      { Recurse for submenus }
      if LCLItem.Count > 0 then
      begin
        dbusmenu_menuitem_property_set(DItem, DBUSMENU_MENUITEM_PROP_CHILD_DISPLAY,
          PGChar(DBUSMENU_MENUITEM_CHILD_DISPLAY_SUBMENU));
        BuildMenuItems(DItem, LCLItem);
      end;
    end;

    dbusmenu_menuitem_child_append(AParent, DItem);
  end;
end;

procedure TSNITrayIconHandle.EmitSignal(const ASignalName: string);
begin
  if FConnection = nil then Exit;
  g_dbus_connection_emit_signal(
    FConnection,
    nil,  { destination — broadcast }
    PGChar(FObjectPath),
    PGChar(SNI_INTERFACE),
    PGChar(ASignalName),
    nil,  { parameters }
    nil); { error }
end;

procedure TSNITrayIconHandle.Update;
begin
  SaveIcon;
  EmitSignal('NewIcon');

  if DbusmenuAvailable and (FMenuServer <> nil) then
    BuildMenu;

  EmitSignal('NewToolTip');
end;

{ ---- GDBus Callbacks (Linux only) ---- }

procedure SNIMethodCall(
  connection: PGDBusConnection;
  sender: PGChar;
  object_path: PGChar;
  interface_name: PGChar;
  method_name: PGChar;
  parameters: PGVariant;
  invocation: PGDBusMethodInvocation;
  user_data: gpointer); cdecl;
var
  Handle: TSNITrayIconHandle;
  ATrayIcon: TCustomTrayIcon;
  AX, AY: gint32;
  AChild: PGVariant;

  procedure ReadPoint;
  begin
    AX := 0;
    AY := 0;
    if parameters = nil then
      Exit;
    AChild := g_variant_get_child_value(parameters, 0);
    if AChild <> nil then
    begin
      AX := g_variant_get_int32(AChild);
      g_variant_unref(AChild);
    end;
    AChild := g_variant_get_child_value(parameters, 1);
    if AChild <> nil then
    begin
      AY := g_variant_get_int32(AChild);
      g_variant_unref(AChild);
    end;
  end;

begin
  Handle := TSNITrayIconHandle(user_data);
  if Handle = nil then
  begin
    g_dbus_method_invocation_return_value(invocation, nil);
    Exit;
  end;
  ATrayIcon := Handle.FTrayIcon;

  if StrComp(method_name, 'Activate') = 0 then
  begin
    { Left click activation; follow Qt5 tray event order. }
    ReadPoint;
    if Assigned(ATrayIcon) then
    begin
      if Assigned(ATrayIcon.OnMouseDown) then
        ATrayIcon.OnMouseDown(ATrayIcon, mbLeft, [], AX, AY);
      if Assigned(ATrayIcon.OnClick) then
        ATrayIcon.OnClick(ATrayIcon);
      if Assigned(ATrayIcon.OnMouseUp) then
        ATrayIcon.OnMouseUp(ATrayIcon, mbLeft, [], AX, AY);
    end;
  end
  else if StrComp(method_name, 'SecondaryActivate') = 0 then
  begin
    { Middle click activation; SNI has no double-click method. }
    ReadPoint;
    if Assigned(ATrayIcon) then
    begin
      if Assigned(ATrayIcon.OnMouseDown) then
        ATrayIcon.OnMouseDown(ATrayIcon, mbMiddle, [], AX, AY);
      if Assigned(ATrayIcon.OnMouseUp) then
        ATrayIcon.OnMouseUp(ATrayIcon, mbMiddle, [], AX, AY);
    end;
  end
  else if StrComp(method_name, 'ContextMenu') = 0 then
  begin
    { Right-click/context activation; menu display is handled by DBusMenu host. }
    ReadPoint;
    if Assigned(ATrayIcon) then
    begin
      if Assigned(ATrayIcon.OnMouseDown) then
        ATrayIcon.OnMouseDown(ATrayIcon, mbRight, [], AX, AY);
      if Assigned(ATrayIcon.OnMouseUp) then
        ATrayIcon.OnMouseUp(ATrayIcon, mbRight, [], AX, AY);
    end;
  end;
  { Scroll has no LCL tray event equivalent; MouseMove/DblClick are unsupported
    unless a host provides a separate measurable SNI path. }

  g_dbus_method_invocation_return_value(invocation, nil);
end;

function SNIGetProperty(
  connection: PGDBusConnection;
  sender: PGChar;
  object_path: PGChar;
  interface_name: PGChar;
  property_name: PGChar;
  error: PPGError;
  user_data: gpointer): PGVariant; cdecl;
var
  Handle: TSNITrayIconHandle;
  ATrayIcon: TCustomTrayIcon;
  AHint: string;
  ATitle: string;
  TupleChildren: array[0..3] of PGVariant;
begin
  Result := nil;
  Handle := TSNITrayIconHandle(user_data);
  if Handle = nil then Exit;
  ATrayIcon := Handle.FTrayIcon;

  if StrComp(property_name, 'Category') = 0 then
    Result := g_variant_new_string('ApplicationStatus')
  else if StrComp(property_name, 'Id') = 0 then
    Result := g_variant_new_string(PGChar(Handle.FAppId))
  else if StrComp(property_name, 'Title') = 0 then
  begin
    if Assigned(ATrayIcon) then
      ATitle := ATrayIcon.Hint
    else
      ATitle := '';
    if ATitle = '' then
      ATitle := Application.Title;
    Result := g_variant_new_string(PGChar(ATitle));
  end
  else if StrComp(property_name, 'Status') = 0 then
    Result := g_variant_new_string('Active')
  else if StrComp(property_name, 'WindowId') = 0 then
    Result := g_variant_new_uint32(0)
  else if StrComp(property_name, 'IconName') = 0 then
    Result := g_variant_new_string(PGChar(Handle.FIconName))
  else if StrComp(property_name, 'IconThemePath') = 0 then
    Result := g_variant_new_string(PGChar(Handle.FIconDir))
  else if StrComp(property_name, 'IconPixmap') = 0 then
    Result := Handle.BuildIconPixmapsVariant
  else if StrComp(property_name, 'ToolTip') = 0 then
  begin
    { ToolTip type: (sa(iiay)ss) = (icon_name, icon_pixmaps, title, body).
      Some SNI hosts ignore this property; for example Ubuntu's GNOME
      AppIndicator extension disables ToolTip/NewToolTip support in its
      bundled StatusNotifierItem.xml. Keep exporting it for hosts that do
      support SNI tooltips. }
    if Assigned(ATrayIcon) then
      AHint := ATrayIcon.Hint
    else
      AHint := '';

    TupleChildren[0] := g_variant_new_string(PGChar(Handle.FIconName));
    TupleChildren[1] := Handle.BuildIconPixmapsVariant;
    TupleChildren[2] := g_variant_new_string(PGChar(Application.Title));  { title }
    TupleChildren[3] := g_variant_new_string(PGChar(AHint));  { body }
    Result := g_variant_new_tuple(@TupleChildren[0], 4);
  end
  else if StrComp(property_name, 'ItemIsMenu') = 0 then
    Result := g_variant_new_boolean(gboolean(0))
  else if StrComp(property_name, 'Menu') = 0 then
    Result := g_variant_new_object_path(PGChar(Handle.FMenuObjectPath));
end;

{ ---- TGtk4WSTrayIcon (Linux only) ---- }

class function TGtk4WSTrayIcon.Hide(const ATrayIcon: TCustomTrayIcon): Boolean;
var
  H: TSNITrayIconHandle;
begin
  if ATrayIcon.Handle <> 0 then
  begin
    H := TSNITrayIconHandle(ATrayIcon.Handle);
    ATrayIcon.Handle := 0;
    H.Free;
  end;
  Result := True;
end;

class function TGtk4WSTrayIcon.Show(const ATrayIcon: TCustomTrayIcon): Boolean;
var
  H: TSNITrayIconHandle;
begin
  Result := True;
  if ATrayIcon.Handle = 0 then
  begin
    H := TSNITrayIconHandle.Create(ATrayIcon);
    if not H.FReady then
    begin
      H.Free;
      Exit(False);
    end;
    ATrayIcon.Handle := HWND(H);
  end;
end;

class procedure TGtk4WSTrayIcon.InternalUpdate(const ATrayIcon: TCustomTrayIcon);
var
  H: TSNITrayIconHandle;
begin
  if ATrayIcon.Handle <> 0 then
  begin
    H := TSNITrayIconHandle(ATrayIcon.Handle);
    H.Update;
  end;
end;

class function TGtk4WSTrayIcon.ShowBalloonHint(const ATrayIcon: TCustomTrayIcon): Boolean;
var
  AConn: PGDBusConnection;
  AError: PGError;
  AParams: PGVariant;
  AReply: PGVariant;
  AReplyChild: PGVariant;
  AIcon: string;
  ATimeout: gint32;
  ANotificationId: guint32;
  AActionsType, AHintsType: PGVariantType;
  ActionsBuilder, HintsBuilder: PGVariantBuilder;
  TupleChildren: array[0..7] of PGVariant;
  H: TSNITrayIconHandle;
begin
  Result := False;
  if ATrayIcon = nil then Exit;

  AError := nil;
  AConn := g_bus_get_sync(G_BUS_TYPE_SESSION, nil, @AError);
  if AConn = nil then
  begin
    if AError <> nil then
      g_error_free(AError);
    Exit;
  end;

  AIcon := '';
  if ATrayIcon.Handle <> 0 then
  begin
    H := TSNITrayIconHandle(ATrayIcon.Handle);
    if (H.FIconPath <> '') and FileExists(H.FIconPath) then
      AIcon := H.FIconPath;
  end;
  if AIcon = '' then
  begin
    { Map BalloonFlags to freedesktop notification icon }
    case ATrayIcon.BalloonFlags of
      bfInfo:    AIcon := 'dialog-information';
      bfWarning: AIcon := 'dialog-warning';
      bfError:   AIcon := 'dialog-error';
    else
      AIcon := '';
    end;
  end;

  { Timeout: BalloonTimeout is in ms, notification spec uses ms too.
    -1 means server default, 0 means never expire }
  ATimeout := ATrayIcon.BalloonTimeout;
  if ATimeout <= 0 then
    ATimeout := -1;

  // Build Notify parameters tuple: (susssasa{sv}i)
  // app_name, replaces_id, app_icon, summary, body, actions, hints, expire_timeout
  TupleChildren[0] := g_variant_new_string(PGChar(Application.Title));
  TupleChildren[1] := g_variant_new_uint32(0);
  TupleChildren[2] := g_variant_new_string(PGChar(AIcon));
  TupleChildren[3] := g_variant_new_string(PGChar(ATrayIcon.BalloonTitle));
  TupleChildren[4] := g_variant_new_string(PGChar(ATrayIcon.BalloonHint));

  { Empty actions array: as }
  AActionsType := g_variant_type_new('as');
  ActionsBuilder := g_variant_builder_new(AActionsType);
  TupleChildren[5] := g_variant_builder_end(ActionsBuilder);
  g_variant_builder_unref(ActionsBuilder);
  g_variant_type_free(AActionsType);

  // Empty hints dict: a{sv}
  AHintsType := g_variant_type_new('a{sv}');
  HintsBuilder := g_variant_builder_new(AHintsType);
  TupleChildren[6] := g_variant_builder_end(HintsBuilder);
  g_variant_builder_unref(HintsBuilder);
  g_variant_type_free(AHintsType);

  TupleChildren[7] := g_variant_new_int32(ATimeout);

  AParams := g_variant_new_tuple(@TupleChildren[0], 8);

  AError := nil;
  AReply := g_dbus_connection_call_sync(
    AConn,
    PGChar('org.freedesktop.Notifications'),
    PGChar('/org/freedesktop/Notifications'),
    PGChar('org.freedesktop.Notifications'),
    PGChar('Notify'),
    AParams,
    nil,
    G_DBUS_CALL_FLAGS_NONE,
    5000,  { timeout ms — avoid infinite block }
    nil,
    @AError
  );

  if AError <> nil then
  begin
    g_error_free(AError);
    g_object_unref(AConn);
    Exit;
  end;

  if AReply = nil then
  begin
    g_object_unref(AConn);
    Exit;
  end;

  ANotificationId := 0;
  AReplyChild := g_variant_get_child_value(AReply, 0);
  if AReplyChild <> nil then
  begin
    ANotificationId := g_variant_get_uint32(AReplyChild);
    g_variant_unref(AReplyChild);
  end;
  g_variant_unref(AReply);
  g_object_unref(AConn);

  Result := ANotificationId <> 0;
end;

class function TGtk4WSTrayIcon.GetPosition(const ATrayIcon: TCustomTrayIcon): TPoint;
begin
  { SNI protocol does not expose icon position (Linux only) }
  Result := Point(0, 0);
end;

{ ---- Initialization (Linux only) ---- }

var
  SNILoaded: Boolean = False;
  SNIAvailable: Boolean = False;

{ (Linux only) Check if D-Bus session bus is available }
function Gtk4SNITrayIconInit: Boolean;
var
  AConn: PGDBusConnection;
  AError: PGError;
begin
  if SNILoaded then
    Exit(SNIAvailable);
  SNILoaded := True;

  AError := nil;
  AConn := g_bus_get_sync(G_BUS_TYPE_SESSION, nil, @AError);
  if AConn = nil then
  begin
    if AError <> nil then
      g_error_free(AError);
    Exit(False);
  end;
  { Connection is cached by GIO, no need to unref }
  SNIAvailable := True;
  Result := True;
end;

finalization
  if DbusmenuModule <> 0 then
    FreeLibrary(DbusmenuModule);

end.
