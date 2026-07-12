# PLAN: GTK4 ToolBar Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TToolBar` / `TToolButton` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 4.11.

Primary source findings:

1. GTK4 registers `TToolBar` and creates `TGtk4ToolBar`.
2. GTK4, GTK2, and Qt5 do not register a direct native `TCustomToolButton` widgetset class.
3. GTK4 toolbar rendering is intentionally kept in LCL on top of a GTK4 host control.
4. Runtime validation must check whether the LCL-managed button list, layout, painting, image-list update, and click/check/dropdown event paths work under GTK4.

Important source references:

- Baseline toolbar classes: `lcl/widgetset/wscomctrls.pp`
- LCL toolbar implementation: `lcl/include/toolbar.inc`
- LCL toolbutton implementation: `lcl/include/toolbutton.inc`
- GTK4 toolbar host: `lcl/interfaces/gtk4/gtk4wscomctrls.pp`, `lcl/interfaces/gtk4/gtk4widgets.pas`

## Validation Questions

1. Does GTK4 build and run a focused toolbar example without exceptions?
2. Does `TToolBar` allocate a GTK4 handle and preserve LCL `ButtonCount`/child control ordering?
3. Do button, check button, separator, dropdown, buttondrop, and disabled buttons retain plausible bounds and state?
4. Do `OnClick`, `OnArrowClick`, and `OnPaintButton` fire through LCL toolbar paths?
5. Do runtime changes to `ShowCaptions`, `List`, `ButtonWidth`, `ButtonHeight`, `Wrapable`, and image lists survive without exceptions?

## Focused Test Program

Created directory:

- `example_gtk4_toolbar_validation/`

Runtime modes:

- default: opens a visual test window for manual inspection;
- `TOOLBAR_VALIDATION_AUTO=1`: runs automated state checks and exits;
- `TOOLBAR_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

- Date: 2026-07-09
- Build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- Build result: succeeded.
- Auto run command: `xvfb-run -a env TOOLBAR_VALIDATION_AUTO=1 ./example_gtk4_toolbar_validation/toolbar_validation`
- Auto run result: completed without Pascal exception.

Observed facts:

1. `TToolBar.HandleAllocated=True`, `ButtonCount=6`, and `ControlCount=6` after show.
2. LCL-managed child button bounds were plausible:
   - normal button `(1,2,76,44)`;
   - check button `(77,2,76,44)`;
   - separator `(153,2,8,44)`;
   - dropdown `(161,2,88,44)`;
   - buttondrop `(249,2,86,44)`;
   - disabled button `(335,2,76,44)`.
3. `OnPaintButton` fired after the initial paint pass; the auto run observed `paints=6`.
4. Programmatic `Click` and `ArrowClick` calls fired events:
   - normal/check/dropdown/buttondrop clicks produced `clicks=4`;
   - dropdown/buttondrop arrow clicks produced `arrows=2`.
5. Programmatic `TToolButton.Click` on the check-style button did not toggle `Down`; it remained `False`. Later Run 3 confirmed that the real mouse path does toggle the check button.
6. Runtime image-list replacement, `ShowCaptions := False`, `List := True`, `SetButtonSize(52,36)`, and `Wrapable := False` completed and updated button bounds.
7. The attempted narrow-wrap pass set `FToolBar.Width := 220`, but the toolbar stayed at form width (`size=(860,72)`) because `TToolBar.Align` defaults to `alTop`. This run therefore did not validate wrapping under constrained width.
8. `RowCount` reported `0` throughout the run despite visible button layout. This should be treated as a runtime finding requiring comparison with expected LCL `TToolBar.RowCount` behavior.

Conclusion:

GTK4 `TToolBar` is usable as an LCL-managed toolbar host for basic button creation, painting, image-list replacement, button sizing, captions/list mode, disabled state storage, and programmatic click/arrow events. Run 1 did not prove mouse interaction, dropdown popup placement, check-button toggle by real user click, wrapping under constrained width, or hot/disabled image rendering. Later runs resolved constrained-width wrapping and real normal/check mouse behavior; dropdown popup placement and hot/disabled image rendering remain follow-up items.

## Validation Run 2

- Date: 2026-07-10
- Example update: added an independent narrow toolbar inside a panel, with `Align := alNone`, so wrapping can be measured without the default `alTop` form-width behavior.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 auto run command: `xvfb-run -a env TOOLBAR_VALIDATION_AUTO=1 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation`
- GTK2 comparison command: `./lazbuild --ws=gtk2 example_gtk4_toolbar_validation/toolbar_validation.lpi` and the same auto run under `xvfb-run`.
- Qt5 comparison command: `./lazbuild --ws=qt5 example_gtk4_toolbar_validation/toolbar_validation.lpi` and `xvfb-run -a env TOOLBAR_VALIDATION_AUTO=1 QT_QPA_PLATFORM=xcb ./example_gtk4_toolbar_validation/toolbar_validation`.
- Result: all three widgetsets built and completed the auto run without a Pascal exception.

Observed GTK4 facts:

1. The independent narrow toolbar allocated a handle and retained `ButtonCount=6` / `ControlCount=6`.
2. With size `(220,144)`, button bounds were distributed across three rows:
   - `N1` `(1,2,76,44)`, `N2` `(77,2,76,44)`, separator `(153,2,8,44)`;
   - dropdown `N3` `(1,46,88,44)`, buttondrop `N4` `(89,46,86,44)`;
   - disabled `Off` `(1,90,76,44)`.
3. `RowCount` still reported `0` for both the full-width toolbar and the independent narrow toolbar.
4. GTK2 and Qt5 produced the same practical pattern: narrow toolbar buttons wrapped into multiple rows, while `RowCount=0`.
5. Source review of `lcl/include/toolbar.inc` shows `FRowCount` is LCL-owned and is reset inside `TToolBar.WrapButtons`; in the reviewed code path it is incremented for forced `TToolButton.Wrap` line breaks when `Wrapable=False`, not for the ordinary automatic fit/wrap case validated here.

Updated conclusion:

Constrained-width wrapping itself is confirmed for GTK4 in the focused example and is comparable to GTK2/Qt5 for this scenario. `RowCount=0` should no longer be treated as proven GTK4-specific evidence; it is a common LCL toolbar semantic/implementation question and should be reviewed at the LCL toolbar layer before any GTK4-specific fix is considered.

## Validation Run 3

- Date: 2026-07-10
- Example update: added `OnMouseDown` / `OnMouseUp` logging and final manual-close state logging.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 mouse-input command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=5500 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool ...'`
- GTK2 and Qt5 comparison: rebuilt the same example with `--ws=gtk2` and `--ws=qt5`, then replayed the same X11 click sequence.

Observed GTK4 facts:

1. Real mouse click on the normal button delivered `OnMouseDown`, `OnMouseUp`, and `OnClick`.
2. Real mouse click on the check button delivered `OnMouseDown`, `OnMouseUp`, and `OnClick`; the final state had `Check.Down=True`. This confirms the earlier programmatic `Click` non-toggle is not evidence of failed user-click toggle behavior.
3. Real mouse click on the main area of the `tbsDropDown` button delivered `OnClick`.
4. Real mouse click on the arrow area of the `tbsDropDown` button opened the dropdown/menu handling path: no `OnClick` or `OnArrowClick` was logged, and GTK4 produced a second `OnMouseUp` from the LCL `SendButtonUpMsg` path.
5. GTK2 and Qt5 produced the same practical result for a precise `tbsDropDown` arrow-area click: mouse down/up was logged, but no `OnClick` or `OnArrowClick` was logged.
6. Source review of `lcl/include/toolbutton.inc` shows `PointInArrow` returns true only for `Style = tbsDropDown`; `tbsButtonDrop` is not part of that helper. Do not classify missing real-mouse `OnArrowClick` for `tbsButtonDrop` as GTK4-specific based on this run.

Updated conclusion:

GTK4 toolbar real mouse delivery is confirmed for normal button click and check-button toggle in the focused X11/Xvfb run. The dropdown arrow behavior observed here matches GTK2/Qt5 for the same precise arrow-area test and follows common LCL `TToolButton` menu handling, so it is not a confirmed GTK4-specific toolbar defect. Remaining toolbar validation is visual/integration focused: popup placement, repeated open/close UX, hot/disabled image rendering, and IDE component-palette/main-toolbar behavior.

## Validation Run 4

- Date: 2026-07-10
- Example update: added a separate `visual` toolbar that does not assign `OnPaintButton`, so it exercises the default `TToolButton.Paint` path.
- The visual toolbar has three buttons:
  - enabled normal button using `Images`;
  - enabled hover target using `Images` / `HotImages`;
  - disabled button using `DisabledImages`.
- Added optional internal snapshot support: `TOOLBAR_VISUAL_SNAPSHOT=/tmp/file.bmp` saves `FVisualToolBar.PaintTo(...)` during the close timer.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 run command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=2500 TOOLBAR_VISUAL_SNAPSHOT=/tmp/toolbar_visual_gtk4_internal_hover.bmp GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool ...'`

Observed GTK4 facts:

1. The visual toolbar allocated a handle and reported three LCL-managed buttons:
   - normal `(1,2,44,36)`;
   - hover target `(45,2,44,36)`;
   - disabled `(89,2,44,36)`.
2. Internal `PaintTo` snapshot of the visual toolbar contained exact normal image-list red pixels: `512` pixels of `#FF0000`.
3. The same snapshot contained exact disabled image-list gray pixels: `256` pixels of `#808080`.
4. No hot image-list green/yellow pixels were observed in the GTK4 snapshot.
5. The pointer replay did produce `OnMouseEnter VisualHot`, but `OnMouseLeave VisualHot` followed before the close-timer snapshot. Therefore this run does not prove whether GTK4 fails to draw `HotImages`; it proves only that the tested Xvfb/xdotool hover state did not remain stable long enough for a hot-image snapshot.
6. External `import` and `xwd` window captures also failed to preserve a stable hot state and are not reliable evidence for `HotImages` in this setup.

Updated conclusion:

GTK4 default toolbar painting uses the assigned normal `Images` and `DisabledImages` in the focused visual toolbar. `HotImages` remains unresolved: source review says `TToolButton.GetCurrentIcon` should select `HotImages` when `Enabled and FMouseInControl`, but this automated X11/Xvfb replay could not keep `FMouseInControl` stable for the visual button. This needs either a manual visual check or a more controlled event-state probe before being classified as a GTK4 rendering defect.

## Validation Run 5

- Date: 2026-07-10
- Example update: added `TPopupMenu.OnPopup`, `TPopupMenu.OnClose`, and menu item `OnClick` counters/logging.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 repeated open/close command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=5000 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool ... Escape ...'`
- GTK4 menu item activation command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=4000 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool ... click ...'`
- GTK2 and Qt5 comparison: rebuilt the same example with `--ws=gtk2` and `--ws=qt5`, then clicked the popup item at the corresponding scaled toolbar/popup location.

Observed GTK4 facts:

1. Two repeated `tbsDropDown` arrow-area clicks followed by Escape produced:
   - `menuPopup=2`;
   - `menuClose=2`;
   - no Pascal exception.
2. The popup point logged by LCL for the GTK4 toolbar dropdown was `(161,46)` for the tested button whose bounds were `(161,2,88,44)`.
3. Clicking below that popup point activated the menu item:
   - `OnMenuPopup popupPoint=(161,46) alignment=0 items=1`;
   - `OnMenuItemClick Menu item`;
   - `OnMenuClose popupPoint=(161,46)`;
   - final `menuPopup=1`, `menuClose=1`, `menuItemClick=1`.
4. GTK2 and Qt5 comparison runs also activated the same menu item through the same focused example.
5. GTK2/Qt5 logged popup points as `(267,148)` in the Xvfb setup, while GTK4 logged `(161,46)`. Despite that coordinate-log difference, the GTK4 popup item was clickable at the expected toolbar-local popup location. This should be treated as an observed coordinate-reporting difference, not as proof of a user-visible placement defect.

Updated conclusion:

GTK4 toolbar dropdown popup open/close and basic item activation are confirmed in the focused example. Repeated open/close by Escape is stable in the tested path, and clicking the popup item dispatches the LCL menu item handler. At this point the remaining dropdown validation was visual popup placement/screenshots near monitor edges, submenu behavior, menu mutation while open, and IDE component-palette/main-toolbar integration. Run 6 below resolves the submenu and mutation items for the focused example.

## Validation Run 6

- Date: 2026-07-10
- Source review before run:
  - `TPopupMenu.PopUp` calls `DoPopup`, destroys/recreates the handle, then delegates to the widgetset popup path.
  - GTK4 `TGtk4WSPopupMenu.Popup` performs `Gtk4RebuildMenuModel` after LCL `OnPopup` and creates a fresh `GtkPopoverMenu` from the final model.
  - GTK4 menu item property changes schedule deferred model rebuilds; this is the path that needs mutation-while-open validation.
- Example update: added a dynamic item, a hidden item, a submenu/subitem, popup-open mutation timer, and counters for mutation and submenu item click.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 popup/mutation command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=5000 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool ... Escape ...'`
- GTK4 submenu command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=7000 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... xdotool mousemove 132 128 click 1 ... xdotool mousemove 132 100 click 1 ...'`
- GTK2 comparison command: rebuilt with `--ws=gtk2`, then used the same popup with adjusted root coordinates.
- Qt5 comparison command: rebuilt with `--ws=qt5`, then opened the same popup with `QT_QPA_PLATFORM=xcb`.

Observed GTK4 facts:

1. Opening the toolbar dropdown ran `OnMenuPopup`, then the timer changed menu state while the popup was open:
   - `OnMenuMutation mutation=1`;
   - hidden item changed to `Visible=True`;
   - dynamic item and submenu item captions changed to `Dynamic mutated 1` / `Sub item mutated 1`;
   - closing by Escape produced `OnMenuClose ... mutation=1`;
   - no Pascal exception occurred.
2. Screenshot `/tmp/gtk4_toolbar_submenu_after_click.png` showed the GTK4 submenu page after clicking the submenu row.
3. Clicking the submenu page item produced:
   - `OnSubMenuItemClick Sub item mutated 1`;
   - `OnMenuClose ... mutation=1`;
   - final toolbar state had `submenuClick=1`, `menuMutation=1`.
4. GTK4 printed a GTK warning during one post-close snapshot path: `Trying to snapshot GtkGizmo ... without a current allocation`. The application still completed and the LCL event path succeeded. This is recorded as a warning to watch, not as a confirmed toolbar failure.

Comparison facts:

1. GTK2 showed the mutated hidden item in the open menu and activated the mutated submenu item: final state had `submenuClick=1`, `menuMutation=1`.
2. Qt5 showed the mutated hidden item in the open menu, proving the mutation timer and menu state update ran. The attempted Xvfb root-coordinate submenu activation did not produce `OnSubMenuItemClick`; this is recorded as an input-replay limitation or unresolved Qt5 comparison point, not as evidence of a GTK4 defect.

Updated conclusion:

GTK4 toolbar dropdown submenu construction, submenu page navigation by mouse, mutated submenu item activation, and menu mutation while the popup is open are confirmed in the focused example. The remaining toolbar dropdown validation is now narrower: edge/screen-boundary popup placement and IDE component-palette/main-toolbar integration.

## Validation Run 7

- Date: 2026-07-10
- Scope: X11/Xvfb screen-boundary popup placement for toolbar dropdowns. Wayland was not tested.
- Xvfb root size: `1280x1024`.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 right-edge command: moved the test window to `(1030,0)`, opened the dropdown, and captured `/tmp/gtk4_toolbar_popup_right_edge.png`.
- GTK4 bottom-edge command: moved the test window to `(0,930)`, opened the dropdown, and captured `/tmp/gtk4_toolbar_popup_bottom_edge.png`.
- GTK4 bottom-right command: moved the test window to `(1030,930)`, opened the dropdown, captured `/tmp/gtk4_toolbar_popup_bottom_right_edge.png`, then clicked the visible menu item.
- GTK2/Qt5 comparison: rebuilt the same example with `--ws=gtk2` and `--ws=qt5`, then repeated the bottom-right window move and screenshot.

Observed GTK4 facts:

1. Right edge:
   - window geometry after move: `X=1030`, `Y=0`, `WIDTH=860`, `HEIGHT=760`;
   - dropdown popup point: `(1191,46)`;
   - screenshot showed the popup fully visible inside the right screen boundary.
2. Bottom edge:
   - window geometry after move: `X=0`, `Y=930`, `WIDTH=860`, `HEIGHT=760`;
   - dropdown popup point: `(161,976)`;
   - screenshot showed the popup placed upward inside the bottom screen boundary.
3. Bottom-right edge:
   - window geometry after move: `X=1030`, `Y=930`, `WIDTH=860`, `HEIGHT=760`;
   - dropdown popup point: `(1191,976)`;
   - screenshot showed the popup visible inside both right and bottom screen boundaries;
   - clicking the visible first menu item produced `OnMenuItemClick Menu item`;
   - final state had `menuPopup=1`, `menuClose=1`, `menuItemClick=1`, `menuMutation=1`.
4. GTK4 printed `Trying to snapshot GtkGizmo ... without a current allocation` during some screenshot runs. The popup remained visible, item activation succeeded in the bottom-right case, and the application completed; this remains a warning to watch, not a confirmed toolbar dropdown failure.

Comparison facts:

1. GTK2 bottom-right:
   - popup point: `(1197,978)`;
   - screenshot showed the popup clipped at the bottom edge;
   - open/close and mutation ran, but the GTK4 click coordinate did not activate the item.
2. Qt5 bottom-right:
   - popup point: `(1197,978)`;
   - screenshot showed the popup clipped at the bottom edge;
   - open/close and mutation ran, but the GTK4 click coordinate did not activate the item.

Updated conclusion:

GTK4 toolbar dropdown placement at the tested X11/Xvfb right, bottom, and bottom-right screen boundaries is confirmed usable. In the bottom-right case, the popup was both visible and clickable. This removes the focused edge/screen-boundary toolbar dropdown item from the GTK4 fix-candidate list for the tested X11 path.

## Validation Run 8

- Date: 2026-07-10
- Scope: stable `HotImages` validation for the visual toolbar. Wayland was not tested.
- Source review before run:
  - `TToolButton.GetCurrentIcon` is common LCL code.
  - It selects `FToolBar.HotImages` when `Enabled and FMouseInControl` and `ImageIndex < HotImages.Count`.
  - `TToolButton.MouseEnter` sets `FMouseInControl=True`; `MouseLeave` clears it unless dropdown-menu state prevents that.
- Example update:
  - added `TProbeToolButton` in the focused example only;
  - the probe exposes `MouseEnter`/`MouseLeave` as `ProbeMouseEnter`/`ProbeMouseLeave`;
  - added `TOOLBAR_FORCE_HOT_ON_SHOW=1` to force a stable hot state after `DoShow`;
  - added `GetCurrentIcon` logging for the visual hot button.
- GTK4 build command: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi`
- GTK4 run command: `xvfb-run -a bash -lc 'TOOLBAR_VALIDATION_CLOSE_MS=4000 TOOLBAR_FORCE_HOT_ON_SHOW=1 GDK_BACKEND=x11 ./example_gtk4_toolbar_validation/toolbar_validation & ... import -window root /tmp/toolbar_visual_gtk4_forced_hot_screen.png ...'`
- GTK2/Qt5 comparison: rebuilt with `--ws=gtk2` and `--ws=qt5`, then repeated the same forced-hot screen capture.

Observed GTK4 facts:

1. Before forcing hot state, the visual hot button logged:
   - `show-before-force-hot visual-hot-current-icon list=Images index=0 effect=0 enabled=True`.
2. After `ProbeMouseEnter`, it logged:
   - `OnMouseEnter VisualHot down=False`;
   - `show-after-force-hot visual-hot-current-icon list=HotImages index=0 effect=0 enabled=True`.
3. The actual Xvfb screen capture contained exact hot-image pixels:
   - `#00FF00 256`;
   - `#808080 256`;
   - `#0000FF 256`;
   - `#FF0000 0`.
4. The earlier toolbar-internal `PaintTo` snapshot path is not reliable for hot-state proof: after forced `MouseEnter`, the toolbar snapshot became all background in this run. This is recorded as a snapshot-method limitation, not as a GTK4 rendering failure, because the real screen capture showed the hot image.

Comparison facts:

1. GTK2 also logged `GetCurrentIcon=HotImages` after `ProbeMouseEnter`; its screen capture had `#00FF00 256`.
2. Qt5 also logged `GetCurrentIcon=HotImages` after `ProbeMouseEnter`; its screen capture had `#00FF00 256`.

Updated conclusion:

GTK4 `HotImages` rendering is confirmed usable in the focused visual toolbar on the tested X11/Xvfb path. The previous unresolved status came from an unstable pointer replay and an unsuitable internal snapshot method, not from a confirmed GTK4 hot-image rendering defect.

## Validation Run 9

- Date: 2026-07-10
- Scope: real Lazarus IDE toolbar/component-palette integration under GTK4. Wayland was not tested.
- Safety setup:
  - used a temporary primary config path only: `/tmp/laz_gtk4_ide_validation_pcp`;
  - launched with `--pcp=/tmp/laz_gtk4_ide_validation_pcp --skip-last-project --skip-checks=All --force-new-instance --nsc`;
  - did not use or modify `/home/onion/.lazarus`.
- Source review before run:
  - `ide/componentpalette.pas` creates palette pages as `TPageControl` pages containing `TScrollBox` and LCL-managed `TSpeedButton` component buttons.
  - Component selection is handled by `ComponentBtnMouseDown`, component creation by the form designer after selection, component-button popup by `Btn.PopupMenu := Pal.PopupMenu`, and page/control popup by `FPageControl.PopupMenu := PalettePopupMenu`.
  - `ide/mainbar.pas` embeds the palette in `TMainIDEBar.ComponentPageControl`.
- IDE launch command shape: `xvfb-run -a -s "-screen 0 1600x1000x24" bash -lc 'GDK_BACKEND=x11 ./lazarus ...'`.
- Captures produced during the run:
  - `/tmp/laz_gtk4_ide_main.png`;
  - `/tmp/laz_gtk4_ide_dialogs_tab.png`;
  - `/tmp/laz_gtk4_ide_button_selected.png`;
  - `/tmp/laz_gtk4_ide_button_placed.png`;
  - `/tmp/laz_gtk4_ide_component_popup.png`;
  - `/tmp/laz_gtk4_ide_palette_popup.png`;
  - `/tmp/laz_gtk4_ide_palette_hint.png`.

Observed GTK4 facts:

1. The IDE reached the real main-window state with `Source Editor`, `Form1`, and `project1 - Lazarus IDE v4.4` visible.
2. Component palette page hit testing worked: clicking the `Dialogs` page tab changed the active page and showed the page's component icons.
3. Returning to `Standard`, clicking the `TButton` palette icon and then the form designer created a real `Button1`.
4. The form/source side effects matched a successful design-time component insertion:
   - the form designer showed `Button1` selected;
   - `unit1.pas` showed `StdCtrls` added to the uses list;
   - `TForm1` contained `Button1: TButton;`;
   - the editor status changed to `Modified`.
5. Right-clicking the `TButton` palette icon opened the component-button popup with package/unit entries and the common component list/options entries:
   - `Open Package LCLBase 4.4`;
   - `Open Unit /usr/lib/lazarus/4.4/lcl/stdctrls.pp`;
   - `View All`;
   - `Options ...`.
6. Right-clicking the component palette page/control area opened the page popup with:
   - `View All`;
   - `Options ...`.
7. A three-second hover over the component palette `TButton` icon did not show a tooltip in the Xvfb capture. Source review shows the option default is true (`EnvironmentOptions/ShowHintsForComponentPalette/Value`, default `true`) and the palette sets `Btn.ShowHint` from that option, so this run does not prove hints are disabled by IDE configuration. Treat tooltip display as a remaining narrower hint-window/runtime validation item, not as failed palette hit testing.

Updated conclusion:

GTK4 real IDE component-palette integration is usable for the tested X11/Xvfb paths: palette tab hit testing, component button hit testing, design-time component placement, source/form side effects, component-button popup, and page popup all worked. The only unresolved item from this IDE pass is hover tooltip visibility for palette/toolbutton controls; that should be tracked under GTK4 hint-window/tooltip behavior rather than as evidence that the toolbar/component-palette host is unusable.

## Validation Run 10

- Date: 2026-07-10
- Scope: separate hint-window path validation for controls related to the IDE component palette. Wayland was not tested.
- Source review before run:
  - GTK4 registers `THintWindow` through `TGtk4WSHintWindow`.
  - `TGtk4WSHintWindow.ShowHide` prepares non-popup hint windows with `PrepareTooltipShow`, which sets `_NET_WM_WINDOW_TYPE_TOOLTIP` on X11 and moves the X window to the LCL hint position.
  - IDE component palette buttons are `TSpeedButton` instances, with `ShowHint` set from `EnvironmentGuiOpts.ShowHintsForComponentPalette`.
- Existing example validation:
  - built `examples/controlhint/Project1.lpi` with `--ws=gtk4`;
  - hovering its custom control showed a real hint window with text `Red` / `aaaaa_bbbbb_ccccc_dddddd_eeeeee`;
  - this confirms ordinary GTK4 `THintWindow` display is working.
- Toolbar validation example update:
  - added `Application.OnShowHint` logging;
  - added `Hint`/`ShowHint=True` to selected `TToolButton` instances;
  - added a standalone `TSpeedButton` with `Hint='Standalone speed button hint'`.

Observed GTK4 facts:

1. `TToolButton` hint path worked in the focused toolbar example:
   - log contained `OnShowHint hint="Visual hot hint" canShow=True cursor=(23,16) pos=(384,489)`;
   - `xwininfo` showed a top-level hint window named `Visual hot hint`, size `102x26`, at `+384+489`;
   - screenshot `/tmp/gtk4_toolbar_hint_visual_hot2.png` showed the hint text on screen.
2. Standalone `TSpeedButton` hint path worked:
   - log contained `OnShowHint hint="Standalone speed button hint" canShow=True cursor=(60,16) pos=(608,489)`;
   - `xwininfo` showed a top-level hint window named `Standalone speed button hint`, size `199x26`, at `+608+489`;
   - screenshot `/tmp/gtk4_speedbutton_hint.png` showed the hint text on screen.
3. These results mean the IDE component-palette hint miss from Run 9 is not explained by a general GTK4 hint-window failure, a general `TToolButton` hint failure, or a general `TSpeedButton` hint failure.

Updated conclusion:

GTK4 hint windows and the relevant LCL button hint paths are usable in focused X11/Xvfb tests. The remaining IDE component-palette hint question is now narrowed to IDE/palette-specific conditions: the real palette button may not be the active hint target at the tested coordinates, the IDE may cancel hints during focus/design-state transitions, or palette button `ShowHint`/`Hint` state may differ from the source default at runtime. Do not change GTK4 `THintWindow`, generic `TToolButton`, or generic `TSpeedButton` code based on the Run 9 IDE hover result alone.

## Validation Run 11

- Date: 2026-07-10
- Scope: real Lazarus IDE hover-hint recheck for main toolbar and component palette, still without modifying IDE or GTK4 implementation code. Wayland was not tested.
- Source/config facts checked before run:
  - `TApplication.Create` sets `FShowHint := true`.
  - `TIDEToolBar.Create` sets the IDE toolbar `TToolBar.ShowHint := True`.
  - `TComponentPage.CreateSelectionButton` and `CreateOrDelButton` set component-palette `TSpeedButton.ShowHint` from `EnvironmentGuiOpts.ShowHintsForComponentPalette`.
  - `EnvironmentOptions/ShowHintsForComponentPalette/Value` and `ShowHintsForMainSpeedButtons/Value` default to true when missing.
  - `TMainIDEBar.SetupHints` is called from IDE startup/options paths, but its main-toolbar branch is still a source-level TODO/comment.
- Runtime scan:
  - launched real IDE with temporary `--pcp=/tmp/laz_gtk4_ide_validation_pcp`;
  - scanned main toolbar coordinates and component-palette coordinates using `xdotool mousemove`, `xwininfo -root -tree`, and screenshots;
  - repeated the scan with a copied temporary PCP where both hint options were explicitly written as true:
    - `<ShowHintsForComponentPalette Value="True"/>`;
    - `<ShowHintsForMainSpeedButtons Value="True"/>`.

Observed facts:

1. With default/missing hint options, no extra top-level hint window appeared for:
   - main toolbar coordinates: `(20,39)`, `(68,39)`, `(104,68)`;
   - component palette coordinates: `(248,76)`, `(288,76)`, `(316,76)`, `(344,76)`, `(398,76)`, `(478,76)`.
2. Xvfb's window manager does not support `_NET_ACTIVE_WINDOW`; attempted `xdotool windowactivate` failed. Re-running the scan after those attempts still produced no hint window.
3. With explicit true hint options in `/tmp/laz_gtk4_ide_hints_true_pcp`, no extra top-level hint window appeared for:
   - main toolbar run-button area `(104,68)`;
   - component palette selection/tool/component areas `(248,76)`, `(344,76)`, `(398,76)`.
4. These scans contrast with Run 10, where focused examples produced real top-level hint windows for `THintWindow`, `TToolButton`, and standalone `TSpeedButton`.

Updated conclusion:

The real IDE hover-hint issue is narrower than GTK4 hint support and narrower than component-palette configuration defaults. Run 12 below adds non-invasive gdb observation and resolves the component-palette case: when Xvfb top-level overlap is removed, the palette `TButton` hint reaches `ActivateHintData` and a real hint window is created.

## Validation Run 12

- Date: 2026-07-10
- Scope: real Lazarus IDE hover-hint runtime path with gdb breakpoints only; no Lazarus IDE source or LCL-GTK4 implementation code was modified. Wayland was not tested.
- Source facts used:
  - `GetHintInfoAt` calls `GetHintControl(FindControlAtPosition(MousePos, True))`.
  - `FindControlAtPosition` calls `FindLCLWindow`, then `ControlAtPos` within that top-level LCL window.
  - `FindLCLWindow` uses `WindowFromPoint`.
  - `ShowHintWindow` creates a hint window only if `CanShow=True`, `FHintControl<>nil`, and `HintInfo.HintStr<>''`.
  - `TMainIDEBar.SetupHints` still has a source-level TODO/comment for updating main IDE toolbar hints.
- Runtime method:
  - ran `./lazarus --pcp=/tmp/laz_gtk4_ide_hints_true_pcp --skip-last-project --skip-checks=All --force-new-instance --nsc --quiet` under `xvfb-run`;
  - used gdb breakpoints at `include/application.inc:856`, `873`, and `909`;
  - used `xdotool` for hover coordinates and `xwininfo -root -tree` for top-level hint windows.

Observed facts:

1. With the default Xvfb IDE layout, hovering palette coordinate `(344,76)` reached `ShowHintWindow`, but gdb showed `HintInfo.HintStr=0x0` immediately after `GetControlShortHint`. Field inspection showed the target control was `SynEdit1`, not a palette button: `FName='SynEdit1'`, `FHint=0x0`, `FShowHint=True`, bounds `1370x594`.
2. Moving the `Source Editor` top-level window to `+0+140` changed the same palette coordinate into the expected component-palette target. gdb showed `HintInfo.HintStr='TButton'#10'(StdCtrls, LCLBase)'` immediately after assignment, the same string after handlers, and the flow reached `ActivateHintData`.
3. In that corrected palette run, `xwininfo` showed a top-level hint window named `TButton\n(StdCtrls, LCLBase)` at `+336+89`, size `132x43`.
4. With `Source Editor` moved out of the top toolbar area, hovering main toolbar coordinate `(104,68)` did not reach the `ShowHintWindow` breakpoints and produced no top-level hint window. This matches the source-level `TMainIDEBar.SetupHints` main-toolbar TODO and is not evidence of a GTK4 hint-window defect.

Updated conclusion:

Component-palette hover hints work in the tested GTK4 X11/Xvfb path when the tested coordinate actually resolves to the component-palette control. The earlier failed palette scans were caused by the source editor top-level window being returned by the LCL `WindowFromPoint`/`FindControlAtPosition` path at the same root coordinates in the automated Xvfb layout. Main-toolbar hints remain an IDE mainbar hint-assignment/configuration topic, not a demonstrated LCL-GTK4 `THintWindow`, `TToolButton`, `TSpeedButton`, or component-palette failure.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect images, captions, disabled state, separators, dropdown arrows, wrap/layout, hints, and mouse interaction.
4. Launch Lazarus IDE with a temporary `--pcp` and verify component palette tab hit testing, component placement, component-button popup, page popup, and hover hints.
5. If practical, run the same focused example under GTK2 and Qt5 to compare LCL-managed toolbar behavior.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not infer native toolbutton support from `TToolBar` registration; validate LCL-managed buttons directly.

## Validation Run 13 — destruction during click handler (2026-07-10)

The last unchecked item from the required ToolBar tests: freeing tool buttons
from inside their own `OnClick` handlers. This must be driven by REAL X11
clicks — programmatic `.Click` skips the widgetset mouse-up chain where a
use-after-free would live (the GTK4 gesture callback still holds the wrapper
pointer while user code runs).

Example update: `TOOLBAR_DESTRUCTION_PROBE=1` creates a dedicated toolbar with
four buttons and writes each button's absolute screen center to
`TOOLBAR_DESTRUCTION_COORDS=<file>` after layout, so an external driver can
click precisely:

- `SELF` — handler calls `Application.ReleaseComponent(Sender)` (the
  LCL-sanctioned deferred free);
- `SIB` — handler synchronously frees the live sibling button `DOOM`;
- `HARD` — handler synchronously frees the SENDER itself (formally
  unsupported by LCL/VCL, but real code does it).

Driver: run the app under `xvfb-run`, poll the coords file, click
`HARD -> SIB -> SELF` (right-to-left, because freeing a button re-wraps the
toolbar and shifts the remaining buttons left — a first left-to-right attempt
proved this by hitting the wrong buttons after the first free).

GTK4 result: all three handlers ran to completion through the real mouse
chain (`direct free BEGIN`/`END` logged around the harsh self-free), no
Pascal exception, no GTK criticals in the filtered output, final state
`clicks=3 buttons=1 survived=True`, clean exit code 0.

GTK2 result: identical sequence, identical final state, exit 0 — full parity.

Codex methodology review caught an overstatement: `TToolButton` is a
`TGraphicControl` (comctrls.pp) with NO GTK4 handle of its own, so the three
toolbar cases never free a `TGtk4Widget` wrapper while its own mouse callback
is running — they validate LCL-level teardown only. The wrapper-lifetime case
needs a WINDOWED control. Two `TButton` cases were added:

- `WBTN` — `Application.ReleaseComponent(Sender)` from its own `OnClick`
  (the supported pattern for windowed controls);
- `WHARD` — synchronous `TButton(Sender).Free` from its own `OnClick`
  (formally unsupported on every widgetset — the LCL WndProc unwind already
  runs through freed frames before the widgetset regains control).

Both windowed cases also completed on GTK4 AND GTK2 (final
`clicks=5 buttons=1 survived=True`, exit 0 on both) — full parity again.

Source review during this run found a by-construction dangling-Self window
in `TGtk4Widget.GtkEventMouse` (`gtk4widgets.pas`): the `LM_*UP` delivery
runs user code, after which the release path still touches `Self`
(`FWidget` for the context-menu origin, and `DeliverMessage` for
`LM_CONTEXTMENU`/`LM_CLICKED`). The `WHARD` run survived only because the
freed heap block was not reused. Hardening applied: after the first
`DeliverMessage`, bail out if `Gtk4IsLiveWidgetPointer(Pointer(Self))` is
false — the live-widget registry is registered in both `TGtk4Widget`
constructors and unregistered in the destructor, and it outlives the
wrapper, so a pointer-value check is safe. All destruction cases, the
toolbar auto suite, the 43-step wscontrols suite, and the calendar suite
re-ran clean with the guard; gtk2 and bigide builds are clean.

Conclusion: destruction-during-click is confirmed safe on GTK4 for deferred
self-release, synchronous sibling free, synchronous graphic-control
self-free, deferred windowed release, and (empirically, now also guarded at
the widgetset layer) synchronous windowed self-free — with GTK2 parity in
every case. Combined with runs 1-12, the §4.11 required-test list has no
remaining untested widgetset-level item; main-toolbar hint assignment
remains an IDE `mainbar.pas` topic outside the widgetset.

## LCL Core Fix — TToolBar.RowCount (2026-07-10)

The `RowCount=0` observation from runs 1-2 (identical on GTK4, GTK2 and
Qt5) was reviewed at the LCL toolbar layer with the user's approval for
careful core changes and fixed in `lcl/include/toolbar.inc`.

Root cause: `TToolBar.WrapButtons` reset `FRowCount` to 0 and incremented
it ONLY in the user-forced-wrap branches (`Wrapable=False` +
`TToolButton.Wrap=True`). The automatic wrap in `CalculatePosition`
("try next row") never touched it, and a plain single-row toolbar never
incremented — so `RowCount` was 0 for essentially every real toolbar,
against the Delphi semantic of "number of rows" (>=1 when buttons exist).

Fix: derive the row from each placed control's offset — rows advance from
`StartY`/`StartX` in exact `RealButtonHeight`/`Width` steps for both
automatic and forced wraps, so
`FRowCount := Max(FRowCount, (y - StartY) div RealButtonHeight + 1)`
(horizontal; x/width for vertical), guarded against zero button size and
`Simulate` mode. The old forced-wrap `inc(FRowCount)` lines were removed;
their position stepping is unchanged.

Runtime results (all three widgetsets identical): single-row toolbars now
report `rowcount=1`; the 220px Wrapable toolbar with six buttons in three
visual rows reports `rowcount=3`; every button bounds line in the
validation logs is unchanged from baseline (layout untouched). bigide
builds and the IDE startup smoke test are clean; the only in-tree
consumer (`lazcontrols` `TToolbarWrapper.GetRowCount` passthrough) now
receives correct values. Codex review: row-index invariant verified for
obstacle avoidance, RTL, vertical symmetric case and Simulate guards; no
findings; trailing `Wrap=True` no longer counts an empty row (judged
closer to Delphi semantics).
