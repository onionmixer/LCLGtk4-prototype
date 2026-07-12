# PLAN: GTK4 TTrayIcon Support

Rollback point: 45d2bcafe3a9a54eb4bffe88c7d461906bb0b120
Branch: main
Created: 2026-07-08

Scope: LCL GTK4 `TTrayIcon` implementation only. Do not modify Lazarus IDE code.

## Goal

Bring the GTK4 `TTrayIcon` backend closer to the LCL contract and to the practical behavior of the GTK2 and Qt5 widgetsets, while respecting GTK4's lack of `GtkStatusIcon` and the SNI/DBusMenu model used by modern Linux desktop environments.

The first priority is correctness of the tray icon image itself: a tray item that registers but displays no icon image is not acceptable if the source `TTrayIcon.Icon` or `Application.Icon` contains a usable image.

## Current Facts

- GTK4 tray support is implemented in `lcl/interfaces/gtk4/gtk4wstrayicon.pas` as a direct `org.kde.StatusNotifierItem` D-Bus backend.
- GTK4 registers `TCustomTrayIcon` only if a session D-Bus connection is available, via `Gtk4SNITrayIconInit` in `gtk4wsfactory.pas`.
- The current machine has a user-session `org.kde.StatusNotifierWatcher` and `org.freedesktop.Notifications` service, confirmed with `busctl --user list`.
- The GTK4 backend saves the selected icon to a PNG file under `$XDG_RUNTIME_DIR/lcl-sni-$USER/` or `/tmp/lcl-sni-$USER/`.
- GTK4 exposes the saved file through SNI `IconName` and `IconThemePath`.
- GTK4 now exports non-empty SNI `IconPixmap` data when a usable tray or
  application icon pixbuf is available.
- GTK4 exports `Hint` through the SNI `ToolTip` property and emits `NewToolTip`,
  but visible hover tooltip rendering is host-dependent. Ubuntu's GNOME
  AppIndicator extension disables `ToolTip` and `NewToolTip` in its bundled
  `StatusNotifierItem.xml`, so the hint is not shown as a hover tooltip there
  even when the D-Bus property is present.
- GTK4 now checks icon save failure, reports mandatory D-Bus setup failure
  through `Show = False`, and uses per-instance bus/object/menu paths so
  multiple tray icons can coexist.
- GTK4 maps SNI `Activate`, `SecondaryActivate`, and `ContextMenu` to measured
  LCL click/mouse down/up behavior where SNI provides a method path. It still
  does not provide `OnMouseMove` or `OnDblClick`.
- GTK4 `Scroll` remains effectively no-op because no LCL tray event equivalent
  has been identified.
- GTK4 does not override `GetCanvas`; it falls back to the default `ATrayIcon.Icon.Canvas`.
- GTK4 `GetPosition` always returns `(0,0)` because SNI does not expose tray icon coordinates.
- GTK3 AppIndicator has documented local limitations in the source comments: menu-only, one icon only. GTK4 should not inherit avoidable limitations if SNI can support better behavior.

## Required Comparisons

Every behavior change must be compared against:

- GTK2 `gtk2trayicon.inc`
- Qt5 `qtwsextctrls.pp` and `qtsystemtrayicon.pas`
- GTK3 `gtk3wstrayicon.pas` where the limitation is relevant
- LCL common contract in `customtrayicon.inc` and `wsextctrls.pp`

The GTK4 result does not need to reproduce impossible GTK2 XEmbed behavior, but it must fail explicitly or degrade predictably when SNI cannot provide an equivalent feature.

## Work Principles

- Do not guess. Each implementation step needs a measured failing case or a clearly identified code-path gap.
- Prefer small, independently verifiable changes.
- Keep all changes inside LCL GTK4 unless a common LCL contract bug is proven.
- Do not add a hard dependency on libappindicator, GTK3, or a specific desktop shell.
- Keep DBusMenu dependency dynamic, as the current implementation does.
- Preserve compatibility with desktops that only support the SNI `IconName` path.
- Add `IconPixmap` support as a fallback/improvement, not as a replacement for `IconName`.

## Phase 1: Measurement Harness

Create a standalone tray icon test example, likely `example_gtk4_trayicon_matrix`, with no dependency on Lazarus IDE.

The example should:

- Create a `TTrayIcon` with an embedded icon.
- Optionally set `Application.Icon`.
- Toggle `Visible`.
- Update `Icon` while visible.
- Update `Hint` while visible.
- Use `PopUpMenu` with normal, disabled, hidden, checked, radio, separator, and submenu items.
- Exercise `ShowBalloonHint`.
- Log `OnClick`, `OnDblClick`, `OnMouseDown`, `OnMouseUp`, `OnMouseMove`.
- Optionally create two tray icons to expose object-path or bus-name collisions.
- The manual run duration can be extended with `TRAY_MATRIX_CLOSE_MS=<ms>`.
  This is useful for checking shell-rendered menus, notifications, and hover
  behavior without rebuilding the example.

The test must include a D-Bus inspection mode:

- Discover the exported `org.kde.StatusNotifierItem-*` bus name.
- Inspect `/StatusNotifierItem` properties.
- Verify `IconName`, `IconThemePath`, `IconPixmap`, `ToolTip`, `Menu`, `Status`, and `Title`.
- Verify the icon file exists, is non-empty, and can be loaded by `gdk-pixbuf`.
- Verify `NewIcon` and `NewToolTip` signals after runtime updates.

Manual desktop verification remains necessary because tray rendering is controlled by the desktop shell or extension.

## Phase 2: Icon Reliability

Target problem: tray item exists but icon image is missing.

Planned investigation:

- Confirm whether `TTrayIcon.Icon.HandleAllocated` is true for embedded LFM icons in the GTK4 test.
- Confirm the concrete handle object is `TGtk4Image` and contains a non-nil `PGdkPixbuf`.
- Check `gdk_pixbuf_save` return value and `GError`.
- Check whether the generated PNG path exists and can be loaded.
- Inspect SNI `IconName` and `IconThemePath` as consumed by the watcher.
- Determine whether the shell displays icons from `IconThemePath` reliably.

Candidate implementation:

- Store icon save success/failure in the tray handle.
- Use `gdk_pixbuf_savev` or a correctly terminated save API call if the current varargs wrapper is unreliable.
- Preserve the file-based `IconName`/`IconThemePath` path.
- Add non-empty SNI `IconPixmap` from the current `PGdkPixbuf` so SNI hosts can render directly without resolving the temporary theme path.
- Emit `NewIcon` only after icon state was updated successfully, or still emit with a clearly defined fallback if no icon exists.
- If both tray icon and application icon are unavailable, expose an empty icon state deliberately instead of pretending a saved icon exists.

Acceptance criteria:

- Embedded `TTrayIcon.Icon` appears in the tray on a session with `org.kde.StatusNotifierWatcher`.
- Updating `TTrayIcon.Icon` while visible changes both D-Bus properties/signals and the visible tray image where the shell supports updates.
- If file export fails, the failure is detectable by the backend and `IconPixmap` still provides a valid fallback when a pixbuf exists.

## Phase 3: D-Bus Registration Correctness

Target problem: `Show` reports success when the SNI item is not actually registered.

Planned investigation:

- Track success/failure for session bus connection, introspection parse, object registration, bus-name ownership, and watcher registration.
- Confirm whether watcher registration must happen after name acquisition rather than immediately after `g_bus_own_name_on_connection`.
- Check whether current synchronous registration can race with bus-name acquisition.

Candidate implementation:

- Add explicit handle state for setup success.
- Make `TGtk4WSTrayIcon.Show` return `False` when mandatory setup fails.
- Use unique per-handle bus names and object paths, for example including an instance counter.
- Keep cleanup matched to the specific owned name and object path.

Acceptance criteria:

- `Visible := True` reports failure when no session bus or watcher is available.
- Two `TTrayIcon` instances do not collide on object path or bus name.
- Hide removes only the relevant item.

## Phase 4: Menu and DBusMenu Behavior

Target problem: popup menu support is partial and may not update after `PopUpMenu` changes.

Planned investigation:

- Confirm libdbusmenu availability on the target system.
- Confirm exported `/MenuBar` object and menu tree with `busctl`/`gdbus`.
- Compare LCL menu item properties against DBusMenu properties.
- Check whether current item activation callback is sufficient for submenu and checked/radio state updates.

Candidate implementation:

- Rebuild DBusMenu root on `InternalUpdate`.
- Add stable item ids if required by DBusMenu clients.
- Support enabled, visible, checked, radio, separator, submenu, and caption changes.
- If DBusMenu is unavailable, expose a predictable no-menu state and document that SNI-host popup display is unavailable.

Acceptance criteria:

- Right-click or shell context-menu gesture shows the LCL popup menu where DBusMenu is available.
- Menu item clicks call the LCL `OnClick`.
- Runtime menu changes are reflected after `InternalUpdate`.

## Phase 5: Events

Target problem: GTK4 does not match GTK2/Qt5 event coverage.

Planned investigation:

- Record which SNI methods the current shell sends for left click, middle click, double click, context menu, and scroll.
- Determine whether coordinates passed to SNI methods are usable for LCL mouse events.
- Compare with Qt5 `QSystemTrayIconActivationReason` behavior.

Candidate implementation:

- On `Activate`, call `OnMouseDown`, `OnClick`, and `OnMouseUp` in a Qt5-compatible order if the shell activation semantics match a left click.
- On `SecondaryActivate`, map to middle click if verified by the shell, not to `OnDblClick` by assumption.
- On `ContextMenu`, call right-button `OnMouseDown`/`OnMouseUp` where appropriate and rely on DBusMenu for actual menu display.
- Keep `OnMouseMove` unsupported unless the SNI protocol or shell provides a measured path.
- Treat double-click as unsupported unless a measured SNI event path exists.

Acceptance criteria:

- Event order is documented and verified in the standalone example.
- Unsupported events are explicitly recorded as protocol/desktop limitations, not silent implementation omissions.

## Phase 6: Balloon Notifications

Target problem: notification behavior is implemented separately from the tray handle and does not expose result details.

Planned investigation:

- Verify `org.freedesktop.Notifications.Notify` calls with the standalone example.
- Check return values and `GError`.
- Compare timeout and flag mapping with Qt5 behavior.

Candidate implementation:

- Keep current freedesktop notification path.
- Add better error handling.
- Consider using the tray icon's current icon name or exported icon path as notification icon when possible.

Acceptance criteria:

- `ShowBalloonHint` returns `True` only when the notification call succeeded.
- Failure falls back to LCL `TPopupNotifier` as the common code expects.

## Phase 7: Build and Validation

Clean build:

```sh
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
```

Example build:

```sh
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
```

Runtime validation:

```sh
./example_gtk4_trayicon_matrix/trayicon_matrix
busctl --user list --no-pager
busctl --user introspect <exported-bus-name> /StatusNotifierItem org.kde.StatusNotifierItem --no-pager
```

Cross-widgetset comparison:

```sh
./lazbuild --ws=gtk2 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
./lazbuild --ws=qt5 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
```

Tray icon rendering must be checked in a real desktop session. `xvfb-run` is insufficient for final tray rendering validation because it does not provide the user's shell tray host.

## Open Questions

- Which SNI hosts used by the target desktops prefer `IconPixmap` over `IconName`?
- Does the current `gdk_pixbuf_save` varargs binding behave reliably for PNG in this build?
- Should missing `org.kde.StatusNotifierWatcher` make `Show` fail immediately, or should the backend wait for a watcher to appear?
- How much of GTK2 mouse-event behavior can be honestly represented through SNI?
- Is `GetCanvas` fallback to `Icon.Canvas` sufficient for LCL, or should GTK4 override it for consistency with Qt5?

## Initial Priority Order

1. Build the measurement example and D-Bus inspection workflow.
2. Fix icon export reliability and implement non-empty `IconPixmap`.
3. Make `Show`/setup success reflect actual D-Bus registration state.
4. Make object paths and bus names per-instance.
5. Improve DBusMenu update behavior.
6. Improve click/mouse event mapping only after measuring actual SNI method calls.
7. Recheck balloon notification error handling.

## Implementation Log

### 2026-07-08: Measurement Harness and First Icon Export Fix

Added standalone example:

- `example_gtk4_trayicon_matrix/trayicon_matrix.lpi`
- `example_gtk4_trayicon_matrix/trayicon_matrix.lpr`

The example creates a `TTrayIcon` programmatically, logs expected SNI bus/object/icon paths, updates icon and hint while visible, and keeps the process alive long enough for `busctl --user` inspection.

Measured pre-fix behavior with no forced `Icon.Handle` access:

- `IconName` was `""`.
- `IconPixmap` was `a(iiay) 0`.
- Expected PNG file under `/run/user/1000/lcl-sni-onion/` did not exist.
- `ToolTip`, `Status`, `Title`, and SNI object registration were present.

Control measurement with the example forcing `FTrayIcon.Icon.Handle` before `Visible := True`:

- `IconName` became non-empty.
- PNG file was created and identified as `PNG image data, 32 x 32, 8-bit/color RGBA`.

Root cause confirmed:

- `TRasterImage.HandleAllocated` only reports whether a widgetset handle already exists.
- `TRasterImage.Handle` calls `HandleNeeded` and creates the widgetset handle.
- GTK2/GTK3 tray code uses `Icon.Handle` directly, forcing handle creation.
- GTK4 `TSNITrayIconHandle.SaveIcon` only checked `HandleAllocated`, so valid icons without a pre-created handle were skipped.

Applied GTK4 fix:

- Updated `lcl/interfaces/gtk4/gtk4wstrayicon.pas`.
- `SaveIcon` now converts `TIcon` to `PGdkPixbuf` by requesting `AIcon.Handle` when the icon is non-empty.
- The helper verifies that the resulting handle is a `TGtk4Image`.
- If neither `TTrayIcon.Icon` nor `Application.Icon` produces a pixbuf, stale icon file/name state is cleared.
- `gdk_pixbuf_save` result is now checked; on failure, stale `FIconPath` and `FIconName` are cleared.

Measured post-fix behavior with no forced handle access:

- Example logged `pre-show icon-handle-allocated=false`.
- After `Visible := True`, example logged `icon-handle-allocated=true`.
- SNI `IconName` was non-empty.
- SNI `IconThemePath` pointed to `/run/user/1000/lcl-sni-onion/`.
- PNG file existed during runtime.
- PNG file was identified as `PNG image data, 32 x 32, 8-bit/color RGBA`.
- Runtime hint update changed `ToolTip` and `Title`.

Verification commands run:

```sh
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
./example_gtk4_trayicon_matrix/trayicon_matrix
busctl --user get-property <bus-name> /StatusNotifierItem org.kde.StatusNotifierItem IconName
busctl --user get-property <bus-name> /StatusNotifierItem org.kde.StatusNotifierItem IconThemePath
busctl --user get-property <bus-name> /StatusNotifierItem org.kde.StatusNotifierItem IconPixmap
```

Note: the top-level `cleanlcl` target does not exist in this checkout. The LCL-scoped clean command used for validation is `make -C lcl clean LCL_PLATFORM=gtk4`.

Remaining work after this step:

- `IconPixmap` is still empty. GNOME AppIndicator extension source confirms icon names are preferred over pixmaps, and pixmaps are fallback. Implement this only after carefully converting GTK pixbuf RGBA data to the SNI ARGB byte format.
- `Show` still needs explicit D-Bus setup failure reporting.
- Multi-instance object path and bus-name uniqueness still need work.
- DBusMenu update behavior and click/mouse event mapping still need separate measured passes.

### 2026-07-08: IconPixmap, Registration Correctness, Multi-Instance, and Events

Additional facts checked before modifying code:

- GNOME AppIndicator `StatusNotifierItem.xml` defines `IconPixmap` as `a(iiay)` and notes that names are preferred over pixmaps.
- GNOME AppIndicator `appIndicator.js` converts pixmap bytes from ARGB to RGBA before creating a `GdkPixbuf`.
- GTK `GdkPixbuf` exposes RGB/RGBA bytes through `gdk_pixbuf_get_pixels`, `gdk_pixbuf_get_n_channels`, `gdk_pixbuf_get_rowstride`, `gdk_pixbuf_get_width`, and `gdk_pixbuf_get_height`.
- GNOME AppIndicator watcher accepts either a bus name or an object path. If an object path is passed to `RegisterStatusNotifierItem`, it uses the D-Bus invocation sender plus that path. This is the measured local path to supporting multiple tray icons on one process connection.
- Qt5 tray event order is:
  - trigger: left `OnMouseDown`, `OnClick`, `OnMouseUp`
  - middle click: middle `OnMouseDown`, `OnMouseUp`
  - context: right `OnMouseDown`, `OnMouseUp`

Applied GTK4 changes:

- Added a shared `CurrentIconPixbuf` helper so PNG export and `IconPixmap` use the same source order: `TTrayIcon.Icon`, then `Application.Icon`.
- Added non-empty SNI `IconPixmap` generation.
  - Converts GTK pixbuf RGB/RGBA to SNI ARGB bytes.
  - Exposes one `(width, height, bytes)` entry through `a(iiay)`.
  - Also uses the same pixmap payload in the SNI `ToolTip` tuple.
- Made tray handle setup explicit.
  - `SetupDBus` now returns `Boolean`.
  - `RegisterWithWatcher` now returns `Boolean`.
  - `TGtk4WSTrayIcon.Show` returns `False` and frees the handle when session bus, object registration, or watcher registration fails.
- Added per-instance SNI identity.
  - First item keeps `/StatusNotifierItem` and `/MenuBar`.
  - Subsequent items use `/StatusNotifierItem/ItemN` and `/MenuBar/ItemN`.
  - Each handle also owns `org.kde.StatusNotifierItem-<pid>-<N>` for inspection and compatibility.
  - Watcher registration uses the object path to avoid collisions on the default SNI path.
- Updated SNI method event mapping.
  - `Activate` now fires left `OnMouseDown`, `OnClick`, `OnMouseUp`.
  - `SecondaryActivate` now fires middle `OnMouseDown`, `OnMouseUp`.
  - `ContextMenu` now fires right `OnMouseDown`, `OnMouseUp`.
  - `OnDblClick` and `OnMouseMove` remain unsupported because SNI does not provide a measured method/signal path for them.
- Extended `example_gtk4_trayicon_matrix` to create two `TTrayIcon` instances and log both expected SNI identities.

Measured post-change behavior:

- `IconPixmap` is now non-empty:

```text
a(iiay) 1 32 32 4096 ...
```

- Two tray icons in one process registered without object-path collision.
- Watcher `RegisteredStatusNotifierItems` included both:
  - `:1.x/StatusNotifierItem`
  - `:1.x/StatusNotifierItem/Item2`
- Both well-known bus names were inspectable:
  - `org.kde.StatusNotifierItem-<pid>-1 /StatusNotifierItem`
  - `org.kde.StatusNotifierItem-<pid>-2 /StatusNotifierItem/Item2`
- Second item properties verified:
  - `IconName = "lcl-<pid>-2-icon"`
  - `Menu = "/MenuBar/Item2"`
  - `IconPixmap = a(iiay) 1 32 32 4096 ...`
- Failure path verified by running the example with an invalid `DBUS_SESSION_BUS_ADDRESS`.
  - `Visible` became `false`.
  - `Handle` remained `0`.
- Event mapping verified by direct D-Bus method calls:

```text
TRAY event mouse-down button=0 x=11 y=22
TRAY event click elapsed-ms=4916
TRAY event mouse-up button=0 x=11 y=22
TRAY event mouse-down button=2 x=33 y=44
TRAY event mouse-up button=2 x=33 y=44
TRAY event mouse-down button=1 x=55 y=66
TRAY event mouse-up button=1 x=55 y=66
```

Verification commands run after this step:

```sh
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
```

Remaining work after this step:

- DBusMenu behavior still needs deeper manual and D-Bus-level testing for menu item activation and runtime menu mutation.
- `ShowBalloonHint` still uses freedesktop notifications and already reports D-Bus call failure, but notification icon selection and returned notification id are not yet improved.
- `GetPosition` still returns `(0,0)`. This remains an SNI protocol limitation unless a specific host exposes a measured coordinate path.
- `GetCanvas` remains the inherited `Icon.Canvas` behavior and has not been changed.
- `OnDblClick` and `OnMouseMove` remain unsupported through SNI.

### 2026-07-08: DBusMenu and Balloon Notification Follow-up

Additional facts checked before modifying code:

- Local `dbusmenu-glib-0.4` version is `16.04.0`.
- Local DBusMenu XML defines:
  - `GetLayout(parentId, recursionDepth, propertyNames) -> revision, layout`
  - `Event(id, eventId, data, timestamp)`
  - `LayoutUpdated(revision, parent)`
- `libdbusmenu-glib/menuitem.h` defines:
  - activation signal name `item-activated`
  - click event id `clicked`
  - submenu property `children-display`
  - submenu property value `submenu`
  - toggle properties `toggle-type` and `toggle-state`
- GNOME AppIndicator `dbusMenu.js` creates a submenu only when `children-display = "submenu"`.
- LCL `TMenuItem.Click` handles enabled checks, `AutoCheck`, direct `OnClick`, and action execution. Calling only `OnClick` is not equivalent.
- LCL `TMenuItem.IsCheckItem` is the common checkable predicate and includes `Checked`, `RadioItem`, `AutoCheck`, and `ShowAlwaysCheckable`.

Applied GTK4 changes:

- DBusMenu submenu items now export `children-display = "submenu"`.
- DBusMenu item activation now calls `TMenuItem.Click` instead of calling `OnClick` directly.
- DBusMenu checkable export now uses `TMenuItem.IsCheckItem`, so unchecked `AutoCheck` and `ShowAlwaysCheckable` items are exported as checkable.
- Balloon notification now:
  - passes the tray icon's exported PNG file path as `app_icon` when the tray handle has a saved icon;
  - falls back to the previous `dialog-information`, `dialog-warning`, or `dialog-error` icon names;
  - reads the returned freedesktop notification id;
  - returns `True` only when the returned id is non-zero;
  - unrefs the returned `GVariant`, temporary `GVariantType` objects, and the temporary session bus connection.
- The standalone example now includes:
  - an `AutoCheck` item;
  - a mutable item whose caption/enabled state changes during `InternalUpdate`;
  - balloon notification request logging.

Measured post-change behavior:

- DBusMenu layout before runtime update included:

```text
"children-display" s "submenu"
"toggle-state" i 0 "toggle-type" s "checkmark" "label" s "AutoCheck item"
"children-display" s "submenu" "label" s "Submenu"
```

- DBusMenu layout after `InternalUpdate` included:

```text
"toggle-state" i 0 "toggle-type" s "checkmark" "label" s "AutoCheck item"
"enabled" b false "label" s "Mutable item updated"
"children-display" s "submenu" "label" s "Submenu"
```

- Direct DBusMenu `Event(id, "clicked", ...)` against the AutoCheck item produced:

```text
TRAY event menu-click caption=AutoCheck item checked=true
```

- The standalone example requested a balloon notification after the runtime icon/menu/hint update.
- Manual visual verification on the current GNOME/AppIndicator environment found:
  - both tray icons are visible;
  - both tray icon images are visible and distinct;
  - popup menu contents, disabled/hidden items, submenu, check/radio items,
    `AutoCheck`, mutable menu update, and notification behavior are normal;
  - hover tooltip text is not rendered by the shell.
- D-Bus inspection during that manual run confirmed the tooltip data is exported:

```text
first ToolTip:  "trayicon_matrix" "GTK4 tray matrix updated hint"
second ToolTip: "trayicon_matrix" "GTK4 tray matrix second hint"
```

- Local host-side evidence for the missing visible tooltip:
  `/usr/share/gnome-shell/extensions/ubuntu-appindicators@ubuntu.com/interfaces-xml/StatusNotifierItem.xml`
  comments out both `ToolTip` and `NewToolTip` with a note that tooltip support
  is disabled. Therefore the observed missing hover tooltip is a host/extension
  limitation, not a failure to export the LCL `Hint`.

Verification commands run after this step:

```sh
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
```

Runtime validation used the real user session bus:

```sh
busctl --user --no-pager call <bus-name> /MenuBar com.canonical.dbusmenu GetLayout iias 0 10 0
busctl --user --no-pager call <bus-name> /MenuBar com.canonical.dbusmenu Event isvu <autocheck-id> clicked i 0 0
```

Remaining work after this step:

- `GetPosition` still returns `(0,0)`. No SNI coordinate path has been identified.
- `GetCanvas` remains inherited `Icon.Canvas`.
- `OnDblClick` and `OnMouseMove` remain unsupported because the measured SNI method set does not expose them.
- Desktop-rendered tray image, popup menu appearance, notification display, and
  hover tooltip behavior remain shell-specific and require manual visual
  confirmation in each target shell. In the current GNOME/AppIndicator host,
  hover tooltip display is not supported even though SNI `ToolTip` is exported.
