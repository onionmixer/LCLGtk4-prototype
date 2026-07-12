# PLAN: GTK4 LCL UpDown and ListView Support

Date: 2026-07-08
Branch: main
Rollback point: 45d2bcafe3a9a54eb4bffe88c7d461906bb0b120
Scope: LCL GTK4 only; KControls direct validation is deferred to a separate task.
Status: implementation in progress; first GTK4 `TListView` parity fixes applied and verified by standalone matrix.

## Problem Statement

KControls mostly builds its visible controls on LCL classes that already have GTK4 widgetset registration. The specific gap found in the current review is `TKNumberEdit`: it inherits from `TCustomEdit`, but it creates and manages a `TUpDown` when the `neoUseUpDown` option is active.

The GTK4 widgetset currently returns `False` from `WSRegisterCustomUpDown`, so `TCustomUpDown` does not get a GTK4-native widgetset class. Instead, LCL uses its fallback implementation with two `TUpDownButton` children. The next work must determine whether that fallback satisfies KControls under GTK4 before implementing a native GTK4 up/down control.

`TListView` must also be rechecked. This is a different category from `TUpDown`: GTK4 already registers `TCustomListView` and provides a substantial `TGtk4WSCustomListView` implementation, but some properties are intentionally no-op or limited by GTK4 APIs. The work must validate which behavior is sufficient, which behavior is incomplete, and which behavior is an acceptable GTK4 limitation.

## Source Facts

- KControls registers visual components including `TKGrid`, `TKMemo`, `TKHexEditor`, `TKBitBtn`, `TKColorButton`, `TKSpeedButton`, `TKNumberEdit`, `TKFileNameEdit`, `TKLog`, `TKPercentProgressBar`, `TKLinkLabel`, `TKGradientLabel`, `TKSplitter`, `TKPageControl`, `TKPrintPreview`, and related dialog classes.
- Most custom KControls visual controls derive through `TKCustomControl = class(TCustomControl)`.
- GTK4 registers `TCustomControl` to `TGtk4WSCustomControl` in `lcl/interfaces/gtk4/gtk4wsfactory.pas`.
- `TKCustomNumberEdit` derives from `TCustomEdit`, which is covered by GTK4 edit support, but it owns `FUpDown: TUpDown`.
- `TKCustomNumberEdit` creates `FUpDown := TUpDown.Create(Self)` and attaches it to the same parent when `neoUseUpDown` is enabled.
- GTK4 `RegisterCustomUpDown` currently returns `False` in `lcl/interfaces/gtk4/gtk4wsfactory.pas`.
- `TCustomUpDown` has an LCL fallback path: when the widgetset does not register `TWSCustomUpDown`, it creates two `TUpDownButton` controls.
- GTK2 and Qt5 also return `False` for `RegisterCustomUpDown`, so the absence of native registration is not automatically a GTK4-only defect.
- GTK4 declares `TGtk4WSCustomUpDown` and `TGtk4WSUpDown`, but they are currently empty and not registered.
- GTK2 registers `TCustomListView` to `TGtk2WSCustomListView` and Qt5 registers `TCustomListView` to `TQtWSCustomListView`.
- GTK2 and Qt5 both leave `RegisterCustomUpDown=False`, so their `TUpDown` behavior is an LCL fallback baseline rather than a native-widget baseline.
- KControls demos use `TListView` in `demos/kicon/Main.pas` as `LVMain: TListView`.
- The KControls `kicon` demo configures `LVMain` as `ViewStyle=vsReport`, `ReadOnly=True`, `RowSelect=True`, `HideSelection=False`, with five columns and `OnSelectItem`.
- GTK4 registers `TCustomListView` to `TGtk4WSCustomListView` in `lcl/interfaces/gtk4/gtk4wsfactory.pas`.
- `TGtk4WSCustomListView` overrides many `TWSCustomListView` operations, including column operations, item insert/delete/update/text/image/state, selection, hit test, scroll origin, view style, image lists, and owner-data hooks.
- GTK4 `TListView` code uses different GTK paths depending on view style: `GtkColumnView` for report/list-style paths and `GtkGridView` for icon/small-icon paths, with older `GtkTreeView` handling still present in some branches.
- Some `TListView` properties are intentionally limited or no-op in the GTK4 implementation, including API-limited column header click/visibility behavior on `GtkColumnView`, live full-drag behavior, flat scrollbars, work areas, and some wrapping behavior.

## Initial Conclusion

The current shortage is not a missing GTK4 parent class for most KControls components. The concrete risk is the `TUpDown` dependency used by `TKNumberEdit`.

Because LCL already provides a fallback and other widgetsets also rely on that fallback, the first task is empirical validation. A native GTK4 `TUpDown` implementation should be added only if the fallback is proven insufficient for GTK4/KControls behavior.

For `TListView`, the initial question is not whether a GTK4 implementation exists. It does exist and is registered. The question is whether its behavior satisfies normal LCL requirements and the KControls `kicon` demo requirements, especially `vsReport`, columns, item text/subitems, selection events, row selection, read-only behavior, scrolling, and item focus.

## Work Principles

- Keep the work inside LCL GTK4 unless a later explicit request changes the scope.
- Do not change KControls source as part of this work.
- Do not build, run, or validate KControls in this task; that work is tracked separately.
- Do not change Lazarus IDE code for this task.
- Base changes on measured behavior and source facts, not assumptions.
- Every component covered by this plan must be brought to a GTK2 or Qt5 comparable support level, unless a GTK4 toolkit limitation is proven and documented.
- GTK4 behavior must not be judged in isolation. Each failing or suspicious behavior must be compared against GTK2 and Qt5 source implementation and, where practical, runtime behavior.
- For `TUpDown`, GTK2 and Qt5 fallback behavior is the primary compatibility baseline.
- For `TListView`, both GTK2 `TGtk2WSCustomListView` and Qt5 `TQtWSCustomListView` are implementation baselines. Qt5 is especially useful for broad LCL method coverage, while GTK2 is useful for GTK-family behavior and historical LCL expectations.
- If GTK2 and Qt5 differ, document the difference and choose the behavior that best matches the LCL contract in `comctrls.pp` and `wscomctrls.pp`.

## Comparison Baseline

Before implementation work, build a comparison matrix for each covered component.

For `TUpDown`:

- Compare GTK4 LCL fallback with GTK2 fallback.
- Compare GTK4 LCL fallback with Qt5 fallback.
- Verify whether any observed GTK4 defect is actually in the shared LCL fallback path or in GTK4 lower-level control, button, paint, mouse, keyboard, bounds, or focus handling.
- Do not implement a native GTK4 `TUpDown` merely because `RegisterCustomUpDown=False`; that matches GTK2 and Qt5.

For `TListView`:

- Compare each `TWSCustomListView` method implemented by GTK4 with the GTK2 and Qt5 implementations.
- For methods implemented by GTK2/Qt5 but missing, partial, or no-op in GTK4, classify the item as: required fix, acceptable GTK4 API limitation, or not relevant to KControls.
- Compare runtime behavior for `vsReport`, `vsList`, `vsIcon`, and `vsSmallIcon`.
- Compare column, item, subitem, selection, focus, checkbox, image-list, state-image, scrolling, hit-test, custom draw, owner draw, and owner-data behavior.
- Record any intentional GTK4 limitation with the exact GTK4 API reason and the GTK2/Qt5 behavior it differs from.

## Phase 1: Static Contract Review

Review the LCL `TCustomUpDown` contract and GTK4 fallback dependencies before editing code:

- `Min`, `Max`, `Position`, and `Increment` behavior.
- `Wrap` behavior at range boundaries.
- `Orientation` behavior.
- `Associate` behavior with an edit control.
- Arrow-key and mouse-wheel behavior.
- Enabled, visible, bounds, reparenting, and DPI/scale behavior.
- `TUpDownButton` painting, click, and repeat behavior.
- GTK4 `TCustomControl`, graphic-control, speed-button, paint, mouse, and keyboard event paths used by the fallback implementation.
- GTK2 and Qt5 fallback behavior for the same `TCustomUpDown` scenarios.

Review the GTK4 `TListView` contract and implementation before editing code:

- `TCustomListView` expectations in `lcl/comctrls.pp`.
- `TWSCustomListView` virtual method contract in `lcl/widgetset/wscomctrls.pp`.
- GTK2 implementation in `lcl/interfaces/gtk2/gtk2wscomctrls.pp`.
- Qt5 implementation in `lcl/interfaces/qt5/qtwscomctrls.pp`.
- GTK4 registration in `lcl/interfaces/gtk4/gtk4wsfactory.pas`.
- `TGtk4WSCustomListView` methods in `lcl/interfaces/gtk4/gtk4wscomctrls.pp`.
- `TGtk4ListView` implementation in `lcl/interfaces/gtk4/gtk4widgets.pas`.
- View-style path selection: `vsReport`, `vsList`, `vsIcon`, and `vsSmallIcon`.
- GTK4 API limitations already documented in comments, separated from real defects.

## Phase 2: Minimal Validation Tests

Create small validation programs or examples before deciding on implementation:

1. Standalone `TUpDown` fallback test.
   - Vertical and horizontal orientation.
   - Min/max/increment/position changes.
   - `Wrap=True` and `Wrap=False`.
   - Enabled and visible toggles.
   - Resize and reparent behavior.
   - Mouse click and press-repeat behavior if supported.
   - Mouse wheel and arrow-key behavior with an associated edit.

2. KControls `TKNumberEdit` test.
   - Build KControls against the local Lazarus/LCL GTK4 tree.
   - Create a form containing `TKNumberEdit` with `neoUseUpDown`.
   - Verify that the up/down control appears beside the edit.
   - Verify that it follows movement, resizing, enable/disable, and visibility changes.
   - Verify that clicks update the numeric value.
   - Verify min/max/increment/wrap behavior.

3. GTK2 comparison baseline.
   - Run equivalent tests under GTK2 when available.
   - Treat GTK2 fallback behavior as an important compatibility reference, since GTK2 also does not register native `TCustomUpDown`.

3B. Qt5 comparison baseline.
   - Run equivalent tests under Qt5 when available.
   - Treat Qt5 fallback behavior as an important compatibility reference for `TUpDown`.
   - Treat Qt5 native `TListView` behavior as a broad LCL behavior reference for list view method coverage.

4. Standalone `TListView` matrix test.
   - `vsReport`, `vsList`, `vsIcon`, and `vsSmallIcon`.
   - Column add/delete/move/caption/width/visible/sort-indicator behavior.
   - Item add/delete/update, caption, subitems, image index, state image index, checked state, selected state, focused state.
   - `ReadOnly`, `RowSelect`, `HideSelection`, `MultiSelect`, `GridLines`, `ShowColumnHeaders`, and `Checkboxes`.
   - `OnSelectItem`, `OnChange`, column click, custom draw, and owner draw where GTK4 claims support.
   - `GetItemAt`, `GetHitTestInfoAt`, `ItemDisplayRect`, `ItemFocused`, `Selected`, `SelCount`, `TopItem`, `VisibleRowCount`, and `ViewOrigin`.
   - Scrolling and `ItemShow`.
   - Image list rendering for small, large, and state image lists.
   - Record GTK4, GTK2, and Qt5 results for every matrix item.

5. KControls `kicon` demo `TListView` validation.
   - Build the KControls `demos/kicon` project against the local Lazarus/LCL GTK4 tree.
   - Load or synthesize icon data that fills `LVMain`.
   - Verify `vsReport` columns: `Image`, `Width`, `Height`, `Resolution`, and `PNG`.
   - Verify `LVMain.Items.Add`, caption/subitem display, row selection, `ItemFocused`, and `OnSelectItem`.
   - Verify that `ReadOnly=True`, `RowSelect=True`, and `HideSelection=False` match GTK2 or expected LCL behavior.

## Phase 3: Decision Gate

Proceed based on measured results:

- If GTK4 fallback matches GTK2 behavior and satisfies `TKNumberEdit`, do not implement native GTK4 `TUpDown`. Document that KControls is supported through the LCL fallback.
- If GTK4 fallback differs from GTK2 or Qt5 fallback for `TUpDown`, locate whether the difference is in shared LCL code or GTK4 lower-level widget behavior before changing GTK4 code.
- If fallback fails because GTK4 generic control, graphic-control, speed-button, paint, mouse, or keyboard paths are incomplete, fix those lower-level GTK4 paths instead of adding a special `TUpDown` implementation.
- If fallback is inherently insufficient for KControls under GTK4, implement and register `TGtk4WSCustomUpDown`.
- If GTK4 `TListView` satisfies the standalone matrix and KControls `kicon` demo, document the verified support level without changing code.
- If GTK4 `TListView` failures are limited to GTK4 API constraints already documented in source comments, document them as known limitations instead of forcing incompatible emulation.
- If GTK4 `TListView` behavior is below both GTK2 and Qt5 for a required LCL feature, fix the narrow failing path in `TGtk4WSCustomListView` or `TGtk4ListView`.
- If GTK2 and Qt5 implement a behavior differently, use `TCustomListView` and `TWSCustomListView` contract analysis to choose the GTK4 target behavior and record the reason.

## Phase 3B: TListView Implementation Candidates

Only enter this phase for behavior proven defective by tests.

Potential work areas:

- `vsReport` path using `GtkColumnView`: column headers, column sizing, item/subitem binding, selection model synchronization, and sort indicator behavior.
- `vsIcon` and `vsSmallIcon` path using `GtkGridView`: item position, hit testing, selection, image rendering, and scroll behavior.
- Selection and focus synchronization between GTK4 selection models and LCL `TListItem` states.
- `ItemDisplayRect`, `GetItemAt`, and `GetHitTestInfoAt` coordinate conversions.
- Image list and state image rendering.
- OwnerData and model notification behavior.
- Custom draw or owner draw event delivery, if tests show missing LCL callbacks.
- Method-by-method parity gaps against `TGtk2WSCustomListView` and `TQtWSCustomListView`.

Risks:

- GTK4 `GtkColumnView` and `GtkGridView` are model/factory based, so some LCL `TListView` operations may require model notification or widget recreation.
- Some Win32-style `TListView` features have no direct GTK4 equivalent.
- Changing selection-model behavior can affect both `TListView` and other GTK4 list-like widgets if shared helper code is touched.

## Phase 4: Native GTK4 UpDown Design

Only enter this phase if Phase 3 proves it necessary.

Potential implementation direction:

- Implement `TGtk4WSCustomUpDown` in `lcl/interfaces/gtk4/gtk4wscomctrls.pp`.
- Register `TCustomUpDown` to `TGtk4WSCustomUpDown` in `lcl/interfaces/gtk4/gtk4wsfactory.pas`.
- Use a GTK4 container with two button-like child widgets rather than `GtkSpinButton`, because LCL `TUpDown` is a separate associate-able control and not a complete edit/spin composite.
- Implement the virtual methods from `TWSCustomUpDown`: `SetIncrement`, `SetMaxPosition`, `SetMinPosition`, `SetOrientation`, `SetPosition`, `SetUseArrowKeys`, and `SetWrap`.
- Preserve LCL semantics for focus, associated edit behavior, position changes, bounds, scaling, and event ordering.
- Verify that native GTK4 behavior is not worse than the existing LCL fallback or GTK2 fallback baseline.

Risks:

- GTK4 does not provide a direct standalone `TUpDown` equivalent.
- A custom native implementation may duplicate behavior already covered by the LCL fallback.
- Registering a native widgetset class changes the `FUseWS` path in `TCustomUpDown`, so all property handling must be complete before enabling it.

## Verification Plan

- Build LCL for GTK4: `make lcl LCL_PLATFORM=gtk4`.
- Build or use GTK2 LCL as a comparison baseline when available: `make lcl LCL_PLATFORM=gtk2`.
- Build or use Qt5 LCL as a comparison baseline when available: `make lcl LCL_PLATFORM=qt5`.
- Rebuild Lazarus/IDE only if changed LCL GTK4 units require it.
- Compile and run the standalone `TUpDown` validation program.
- Compile and run the standalone `TListView` matrix validation program.
- Run automated checks under `xvfb-run -a` where possible.
- Perform a real-display visual check for positioning and click behavior.
- Save the GTK4/GTK2/Qt5 comparison result table in this plan document or a linked result document after implementation.

## Acceptance Criteria

- Up/down clicks change the associated numeric value.
- Min, max, increment, and wrap behavior are correct.
- Resize, reparent, enabled, and visible states behave correctly.
- GTK4 `TUpDown` behavior is no worse than GTK2 or Qt5 fallback behavior for the same validation cases.
- `TListView` `vsReport` displays columns, captions, subitems, row selection, and focus correctly.
- GTK4 `TListView` behavior is comparable to GTK2 or Qt5 for every required matrix item.
- Any unsupported `TListView` property is documented with a source-level GTK4 limitation, a GTK2/Qt5 comparison note, or an explicit follow-up issue.
- No Lazarus IDE or KControls source changes are made unless separately approved.

## Deferred External Validation

KControls-specific validation is intentionally deferred to a separate task per user direction.
This includes:

- Building KControls against the local LCL GTK4 tree.
- Validating `TKNumberEdit` with `neoUseUpDown`.
- Validating the KControls `demos/kicon` `TListView` path.

The current task continues with standalone LCL GTK4 behavior only.

## Implementation Log: 2026-07-08

### Static Comparison Completed

- `TUpDown` registration was compared across GTK4, GTK2, and Qt5.
- GTK4, GTK2, and Qt5 all leave `RegisterCustomUpDown=False`; therefore all three use the shared LCL fallback in `TCustomUpDown`.
- The current evidence does not justify implementing a native GTK4 `TUpDown`; the fallback is the GTK2/Qt5 parity baseline.
- `TListView` registration and implementation were compared across GTK4, GTK2, and Qt5.
- GTK4 uses `GtkColumnView` for `vsReport`/`vsList` and `GtkGridView` for `vsIcon`/`vsSmallIcon`.
- GTK2 has explicit default-column behavior for non-report styles. GTK4 did not create an equivalent display column for `vsList` when no LCL columns exist.
- GTK4 `ItemDisplayRect` for `GtkColumnView`/`GtkGridView` was returning the factory child/cell geometry instead of the list item row/tile geometry.

### Validation Example Added

Added `example_gtk4_kcontrols_componenttest/` with a standalone LCL program:

- `kcontrols_component_matrix.lpr`
- `kcontrols_component_matrix.lpi`

Covered checks:

- `TUpDown` fallback: initial position, associated edit text, increment, max clamp, wrap behavior, horizontal orientation, enabled/visible propagation from associated edit.
- `TListView` `vsReport`: columns, item/subitem storage, column width, selected/focused item, `ItemIndex`, visible row count, top item, `DisplayRect`, `GetItemAt`, multiselect select-all, selection clear.
- `TListView` `vsList`, `vsIcon`, `vsSmallIcon`: item count, selected/focused item, valid display rect.

### Baseline Results Before Fix

- GTK4 standalone matrix:
  - `TUpDown`: pass.
  - `TListView`: failed `listview.report-getitemat-center` and `listview.list.displayrect-valid`.
- GTK2 standalone matrix:
  - `SUMMARY pass=39 fail=0`.
- Qt5 standalone matrix:
  - `SUMMARY pass=38 fail=1`.
  - The Qt5 failure was `listview.report-clear-selection`; it is not a GTK4 regression target for this step.

### Measured GTK4 Root Causes

- `vsList` without explicit LCL columns had no GTK4 display column, unlike GTK2/Qt5-compatible behavior. This made `DisplayRect` invalid because no visible item widget existed.
- `GetItemAt` used the outer scrolled-window widget for `GtkColumnView`/`GtkGridView` hit testing. The coordinates supplied by LCL are expected relative to the list view container widget, so GTK4 picking must use `GetContainerWidget`.
- `ItemDisplayRect` found the factory-created child widget carrying `lcl-item-position` metadata. For `GtkColumnView`, that child is inside `GtkColumnViewCell`, which is inside `GtkListItemWidget`; the row geometry is on `GtkListItemWidget`.
- Runtime instrumentation showed for the third report row:
  - `GtkListItemWidget` allocation carried row position `y=66` inside `GtkColumnListView`.
  - `GtkColumnListView` allocation contributed the header offset `y=25`.
  - The correct accumulated item rectangle was therefore `0,91,455,124`, not the previous `0,0,...` rectangle.
- `gtk4_widget_translate_coordinates` did not provide usable row offsets for this `GtkColumnView` internal hierarchy in the measured GTK 4.6.9 environment, so GTK4 list item bounds now use allocation accumulation for this narrow path.

### GTK4 Fixes Applied

- In `lcl/interfaces/gtk4/gtk4widgets.pas`:
  - Added a widgetset-only default `GtkColumnViewColumn` for `TListView.ViewStyle=vsList` when `Columns.Count=0`.
  - The default column uses the same GTK4 column-view factory path as normal item caption columns.

- In `lcl/interfaces/gtk4/gtk4wscomctrls.pp`:
  - `GetItemAt` now uses `AWidget.GetContainerWidget` for `GtkColumnView`/`GtkGridView` pick-based hit testing.
  - Added a helper to locate the internal `GtkListItemWidget` ancestor for a factory-created item child.
  - Added a helper to compute a widget rectangle by accumulating GTK allocation coordinates up to the GTK4 list container.
  - `ItemDisplayRect` now returns the row/tile bounds for `GtkColumnView`/`GtkGridView`, matching the LCL expectation better than returning the factory child bounds.

### Verification Results After Fix

- `make lcl LCL_PLATFORM=gtk4`: passed.
- `./lazbuild --ws=gtk4 example_gtk4_kcontrols_componenttest/kcontrols_component_matrix.lpi`: passed.
- `xvfb-run -a example_gtk4_kcontrols_componenttest/kcontrols_component_matrix`: passed.
- Final GTK4 matrix result:
  - `SUMMARY pass=39 fail=0`.

### Scope Update

- KControls direct validation was removed from the active scope by user direction.
- KControls build/run work remains deferred to a separate task.
- The active task now continues with standalone LCL GTK4 behavior only.

### Matrix Expansion: Column Operations and Hit Test

Added standalone `TListView` matrix checks for:

- Report-view hit testing at the center of a valid item display rectangle.
- Column caption set/change.
- Column width set/change.
- Column visible property false/true transitions.
- Column move by changing `TListColumn.Index`.
- Column delete and insertion after delete.

Comparison results before the GTK4 hit-test fix:

- GTK4:
  - Column operation checks passed.
  - `listview.report-hittest-center-onitem` failed with `htNowhere`.
- GTK2:
  - Column operation checks passed.
  - `listview.report-hittest-center-onitem` also failed, returning an empty hit-test set.
- Qt5:
  - `listview.report-hittest-center-onitem` passed.
  - The known unrelated `listview.report-clear-selection` failure remained.

Measured GTK4 root cause:

- `TGtk4ListView` sets `FIsTreeView := True` for the `GtkColumnView` path as a widgetset compatibility flag.
- `TGtk4WSCustomListView.GetHitTestInfoAt` checked `IsTreeView` before checking `IsColumnView`/`IsGridView`.
- As a result, the method attempted to use `GtkTreeView.get_path_at_pos` against a `GtkColumnView` container, while `GetItemAt` already used the correct GTK4 factory-widget hit-test path.

GTK4 fix applied:

- `GetHitTestInfoAt` now handles `IsColumnView`/`IsGridView` before the real `GtkTreeView` path.
- For GTK4 factory views, it uses the already verified `GetItemAt` result and returns `[htOnItem, htOnLabel]` for item hits or `[htNowhere]` otherwise.

Verification after the hit-test fix:

- `make lcl LCL_PLATFORM=gtk4`: passed.
- `./lazbuild --ws=gtk4 example_gtk4_kcontrols_componenttest/kcontrols_component_matrix.lpi`: passed.
- `xvfb-run -a example_gtk4_kcontrols_componenttest/kcontrols_component_matrix`: passed.
- Final expanded GTK4 matrix result:
  - `SUMMARY pass=51 fail=0`.

### Remaining Work

- Expand the `TListView` matrix for image lists, state images, checkboxes, owner/custom draw, owner-data, item show/scrolling, and deeper hit-test details beyond item/label detection.
- Re-run GTK2/Qt5 comparison for each expanded matrix group before applying additional GTK4 changes.
