# PLAN: GTK4 TCustomListView Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TCustomListView` / `TListView` under LCL GTK4
- Policy: no GTK4 implementation changes until runtime validation confirms each source-level finding

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, sections 4.6 and 4.7.

Primary findings:

1. `vsSmallIcon` image-list routing appears wrong in GTK4: `SetImageList` routes by `IsTreeView`, while GTK4 `vsSmallIcon` uses `GtkGridView`, so it accepts `lvilLarge`. GTK2 and Qt5 use `SmallImages` for `vsSmallIcon`.
2. State images appear missing in GTK4: `ItemSetStateImage` has only a comment, and reviewed GTK4 factories do not reference `StateImages` or `StateIndex`.
3. `ItemDisplayRect`, `ItemGetPosition`, `ItemShow`, `TopItem`, and `VisibleRowCount` use visible-widget or adjustment approximations for `GtkColumnView` / `GtkGridView`.
4. Focused item is approximated as first selected item for `GtkColumnView` / `GtkGridView`.
5. Column header visibility/clickability and several property paths are limited by GTK 4.6 APIs or no-op paths.

Important source references:

- GTK4 creation paths: `lcl/interfaces/gtk4/gtk4widgets.pas:8876`, `lcl/interfaces/gtk4/gtk4widgets.pas:8959`
- GTK4 `SetImageList`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1395`
- GTK4 `ItemSetStateImage`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:924`
- GTK4 factories: `lcl/interfaces/gtk4/gtk4widgets.pas:8273`, `lcl/interfaces/gtk4/gtk4widgets.pas:8668`
- GTK4 geometry methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:765`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:973`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1211`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1277`
- GTK4 focus approximation: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1062`
- GTK2 image-list reference: `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:1488`, `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:2234`
- Qt5 image/state reference: `lcl/interfaces/qt5/qtwscomctrls.pp:1471`, `lcl/interfaces/qt5/qtwscomctrls.pp:2181`

## Validation Questions

1. In `vsSmallIcon`, does the visible icon come from `SmallImages` or `LargeImages`?
2. Are `StateImages` visible in `vsReport`, `vsList`, `vsIcon`, and `vsSmallIcon`?
3. Does `DisplayRect` return nonzero bounds for visible items?
4. What does `DisplayRect` return for off-screen items before and after `MakeVisible`?
5. Do `TopItem` and `VisibleRowCount` update after `MakeVisible` / scroll?
6. Can `Focused` differ from `Selected`, or does GTK4 report first selected item as focused?
7. Does `GetHitTestInfoAt` distinguish icon/state-icon/label areas or only item/label?
8. Do `ShowColumnHeaders=False` and `ColumnClick=False` affect GTK4 `GtkColumnView` behavior?

## Focused Test Program

Created directory:

- `example_gtk4_listview_validation/`

The example should:

- create one `TListView`;
- provide `LargeImages`, `SmallImages`, and `StateImages` with distinct colors/sizes;
- populate report/list/icon/smallicon modes with many items;
- set `StateIndex` on alternating rows;
- exercise visible and off-screen `DisplayRect`;
- call `MakeVisible`;
- log `TopItem`, `VisibleRowCount`, `Focused`, `Selected`, `SelCount`, `GetHitTestInfoAt`;
- stay open for manual visual verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `LISTVIEW_VALIDATION_AUTO=1`: runs automated public-API checks and exits.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_listview_validation/listview_validation.lpi
```

Build result:

- succeeded;
- compiled 330 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env LISTVIEW_VALIDATION_AUTO=1 ./example_gtk4_listview_validation/listview_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- no exception was raised by the ListView test program.

Observed public-API results:

| View | Initial/after configure `TopItem` | `VisibleRowCount` | `MakeVisible(Item 080)` effect | Focused |
| --- | --- | ---: | --- | --- |
| `vsReport` | `Item 000` | 11 | `TopItem` became `Item 080`; item 80 rect moved to visible top `(0,25,835,57)` | `nil` |
| `vsList` | `Item 000` | 11 | `TopItem` became `Item 080`, but item 80 rect remained off-screen `(0,2585,835,2617)` | `nil` |
| `vsIcon` | `nil` | 0 | no visible geometry/top-item change after `MakeVisible`; item 80 stayed at `(357,814,476,888)` | `nil` |
| `vsSmallIcon` | `nil` | 0 | no visible geometry/top-item change after `MakeVisible`; item 80 stayed at `(357,506,476,552)` | `nil` |

Additional observations:

- `GetHitTestInfoAt(5,5)` returned `htNowhere` in all four view styles, even when item 0 had a nonzero display rectangle starting at or near the origin.
- `DisplayRect` returned nonzero rectangles for visible and off-screen items, so geometry is not simply unimplemented. However, the semantics differ by view style.
- `TopItem` and `VisibleRowCount` are meaningful for `vsReport` and partially meaningful for `vsList`, but are not meaningful for `vsIcon` / `vsSmallIcon` in this run.
- `Focused` remained `nil` even with two selected items. This run does not confirm the source-level concern that focused item is approximated as first selected item; it shows that this scenario did not produce a focused item at all.
- The auto run cannot prove visual image routing or state-image drawing. The source-level findings for `vsSmallIcon` image-list selection and `StateImages` still require manual visual inspection or screenshot/pixel validation.

Interpretation:

- The source-level concern about ListView geometry/scroll approximations is supported by runtime evidence. `vsReport` behaves best; `vsList`, `vsIcon`, and `vsSmallIcon` do not show GTK2/Qt5-equivalent `MakeVisible`, `TopItem`, and visible-row behavior in the public API output.
- This validation does not yet prove or disprove visual image-list routing or state-image rendering because the automated log only records LCL image-list object sizes and `StateIndex` values, not rendered pixels.
- No implementation change should be made from this run alone for image/state rendering. A second validation pass should keep the window open for manual inspection or capture screenshots for pixel comparison.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect icon/state-image visibility.
4. If practical, run the same example under GTK2 and Qt5 for comparison.
5. Re-test all four view styles after any image-list, state-image, geometry, or selection/focus change.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during validation.
- Do not infer visual image routing from LCL image-list object state alone; visual inspection or pixel/screenshot validation is required.
- Do not treat GTK 4.6 API limitations as fixable without checking GTK4 binding/API availability.

## Implementation Fix 1 (2026-07-10): `SetImageList` vsSmallIcon routing

Scope: one condition in `TGtk4WSCustomListView.SetImageList`
(`lcl/interfaces/gtk4/gtk4wscomctrls.pp`).

Confirmed defect (source re-review): the routing predicate was widget-kind
based — `(lvilLarge and not IsTreeView) or (lvilSmall and IsTreeView)`.
With the current creation paths (`FIsTreeView := True` for the ColumnView
"WS layer compat" flag, `False` for GridView), the acceptance matrix was:

| ViewStyle | Widget | Old accepted list | Baseline (gtk2/qt5/win32) |
| --- | --- | --- | --- |
| vsIcon | GridView | lvilLarge | LargeImages — correct |
| vsSmallIcon | GridView | lvilLarge | **SmallImages — defect** |
| vsReport | ColumnView | lvilSmall | SmallImages — correct |
| vsList | ColumnView | lvilSmall | SmallImages — correct |

Only `vsSmallIcon` was mis-routed (the audit §4.6 judgment). The fix makes
routing ViewStyle-based, identical to gtk2
(`TGtk2WSCustomListView.SetImageList`):
`(lvilLarge and ViewStyle = vsIcon) or (lvilSmall and ViewStyle <> vsIcon)`.

Equivalence for the unchanged styles: `ViewStyle <> vsIcon` with `lvilSmall`
is exactly the old ColumnView acceptance (`FIsTreeView = True` only for
vsReport/vsList; the only two `FIsTreeView` assignments are in
`TGtk4ListView.CreateWidget`). `UpdateImageCellsSize` remains guarded
(`FIsColumnView` exit) and is correctly skipped for GridView. `lvilState`
was and still is not consumed here (separate known state-image gap,
audit §4.6/4.7 — unchanged by this fix). Handle recreation
(`InitializeWnd` reapplies all image lists; `SetViewStyle` → `RecreateWnd`)
re-routes automatically on style switches.

Validation:

- Builds: `make lcl LCL_PLATFORM=gtk4`, `make lcl LCL_PLATFORM=gtk2` — clean.
- Auto run (`LISTVIEW_VALIDATION_AUTO=1`, Xvfb): all four view styles pass,
  geometry outputs unchanged from the pre-fix baseline run.
- Pixel screenshot test (Xvfb + xdotool + ImageMagick histogram over the
  ListView area): vsSmallIcon now renders SmallImages colors
  (lime `#00FF00` 4800 px, aqua `#00FFFF` 4608 px; zero red/blue),
  vsIcon still renders LargeImages colors (red `#FF0000` 2232 px,
  blue `#0000FF` 2108 px) — routing verified end-to-end with no vsIcon
  regression.
- Cross-review: codex (read-only) checked equivalence for vsReport/vsList,
  `UpdateImageCellsSize` interaction, `lvilState` neutrality, the
  `TListView` cast pattern, and dpi/resolution path — no findings; its
  citations were re-verified directly against the source.

Remaining manual (real-hardware) check before commit: visual icon check in
all four view styles (report/list rows show 16px small icons, icon view
shows 32px large icons, small-icon view shows 16px small icons).

## Implementation Fix 2 (2026-07-10): StateImages rendering (qt5 parity)

Scope: `lcl/interfaces/gtk4/gtk4widgets.pas`,
`lcl/interfaces/gtk4/gtk4wscomctrls.pp`; example extended with
StateAll/StateNone runtime buttons and a `-1/0/1` StateIndex cycle.

Necessity re-review first: gtk2 does NOT implement StateImages
(`lcl/interfaces/gtk2/issues.xml` documents "StateImages property is not
supported"; zero code references), and neither the Lazarus IDE
(TListView usage) nor tomboy-ng references StateImages/StateIndex.
Implementation was chosen by explicit user decision for qt5/win32 parity.

Semantics (qt5 parity): Qt items have a single icon slot;
`TQtWSCustomListView.ItemSetStateImage` puts the state bitmap into it and
`ItemSetImage` preserves it while `StateIndex >= 0`. GTK4 mirrors this in
`Gtk4LVItemImageBitmap`: the state image occupies the item icon slot when
`StateImages` is assigned and `StateIndex` is valid; otherwise the normal
item image; otherwise hidden. Both factory binds (ColumnView column 0,
GridView) use the helper; the CustomDraw icon fallback branch and the
hide case are structurally unchanged.

Pieces:

1. Storage: `TGtk4ListView.FStateImages` (TBitmap list) +
   `ClearStateImages` + destructor cleanup — mirrors `FImages`.
   `SetImageList` accepts `lvilState` for every view style (qt5 renders
   state icons in both icon and report modes).
2. Rendering: `Gtk4LVItemImageBitmap` precedence helper used by
   `Gtk4CV_FactoryBind` / `Gtk4GV_FactoryBind`.
3. Refresh — the hard part, verified against local GTK 4.6.9 source:
   `queue_draw` never re-runs a factory bind, and even
   `g_list_model_items_changed` with an unchanged item object makes
   `GtkListItemManager.try_reacquire_list_item` reuse the released widget
   without rebinding (`gtk_list_item_widget_update` rebinds only when the
   item differs) — confirmed empirically (pixel histograms identical after
   StateIndex changes with a plain items-changed emission).
   `TGtk4ListView.ItemRebindRow` therefore SPLICES the GtkStringList row
   so the placeholder object is genuinely replaced, forcing fresh factory
   setup+bind, with per-row selection save/restore and BeginUpdate
   suppression (`Gtk4CV_SelectionChanged` honors InUpdate).
   `TGtk4WSCustomListView.ItemSetStateImage` calls it.
4. `TGtk4ListView.RebindAllRows` (bulk splice + selection save/restore)
   runs from the `lvilState` `SetImageList` path so a runtime StateImages
   (re)assignment refreshes already-bound rows (codex review finding);
   it is a no-op during InitializeWnd (model still empty).

Runtime evidence (Xvfb + xdotool + ImageMagick pixel histograms):

- Mixed `-1/0/1` StateIndex: state icons (purple `#800080` / maroon
  `#800000`) for 0/1 items, normal images (lime/aqua small, red/blue
  large) for `-1` items, in vsReport / vsSmallIcon / vsIcon.
- Runtime change: StateNone → only lime/aqua (960/784 px);
  StateAll → only purple/maroon (720/592 px). Screenshot inspection
  confirms row selection (blue highlight, LCL `sel=2`) and checkboxes
  survive the splices.
- Auto-run geometry checks unchanged from the pre-fix baseline.
- Builds: gtk4 lcl, gtk2 lcl, gtk4 bigide — clean.

Cross-review: codex confirmed callback equivalence, splice safety
(placeholder strings unused as data), multi/single-selection restore
semantics, creation-order safety (`WSCreateCacheItem` inserts the
placeholder before properties apply), memory ownership, and CustomDraw
chain equivalence. Its one Medium finding (stale rows on runtime
StateImages reassignment) is fixed by `RebindAllRows` above.

Known residual limitations (documented, not fixed):

- If keyboard focus is inside the exact row being spliced (e.g. its
  checkbox), the row widget replacement may move focus — rare, untested.
- Runtime reassignment of the NORMAL image lists (lvilSmall/lvilLarge)
  still only queues a draw (pre-existing behavior, out of scope here);
  the same `RebindAllRows` approach applies if it is ever needed.
- Subitem state icons (`ASubIndex > 0`) are not rendered (column 0 only);
  qt5 can set per-subitem icons.

Real-hardware checks before/with the next test round:

1. TListView with StateImages + StateIndex: state icon shows and swaps
   with the normal icon as StateIndex toggles at runtime.
2. Selection/checkbox/scroll position survive StateIndex changes.
3. No regression in plain ListViews (no StateImages assigned).
