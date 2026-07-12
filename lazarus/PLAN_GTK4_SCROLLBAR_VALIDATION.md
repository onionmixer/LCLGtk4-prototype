# PLAN: GTK4 TCustomScrollBar Validation and Fix Scope

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: standalone `TCustomScrollBar` / `TScrollBar` under LCL GTK4
- Policy: no code changes until the runtime validation confirms the source-level diagnosis

## Problem Statement

The full widgetset audit identified GTK4 `TCustomScrollBar` as a high-priority follow-up because source review shows two concrete risks:

1. GTK4 standalone scrollbar `value-changed` callback appears to use the wrong callback signature.
2. GTK4 adjustment `upper` / `page_size` values may be fed back into LCL `Max` incorrectly.

This plan is for validation and narrowly scoped follow-up only. It does not apply an implementation change by itself.

## Source Evidence

### LCL baseline behavior

`TCustomScrollBar.SetParams` stores `Min`, `Max`, `PageSize`, clamps `Position`, sends native scrollbar info, then calls `TWSScrollBar.SetParams`.

References:

- `lcl/include/scrollbar.inc:93`
- `lcl/include/scrollbar.inc:146`
- `lcl/include/scrollbar.inc:172`
- `lcl/widgetset/wsstdctrls.pp:52`
- `lcl/widgetset/wsstdctrls.pp:296`

Important LCL facts:

- `AMax < AMin` raises `EInvalidOperation`.
- `APageSize < 0` is normalized to `0`.
- `Position` is clamped to `Min..Max`.
- `OnScroll` is delivered through `DoScroll` when the widgetset sends `LM_HSCROLL` / `LM_VSCROLL`.
- `OnChange` is delivered through `Change` when `Position` changes.

### GTK4 implementation under review

References:

- `TGtk4WSScrollBar.CreateHandle`: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:523`
- `TGtk4WSScrollBar.SetParams`: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:534`
- `TGtk4WSScrollBar.ShowHide`: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:552`
- `TGtk4ScrollBar.value_changed`: `lcl/interfaces/gtk4/gtk4widgets.pas:5966`
- `TGtk4ScrollBar.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:5997`
- `TGtk4ScrollBar.SetParams`: `lcl/interfaces/gtk4/gtk4widgets.pas:6017`
- GTK4 binding for `GtkAdjustment.value_changed`: `lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas:2900`

Observed source facts:

- `CreateWidget` creates a GTK4 scrollbar and obtains its `GtkAdjustment`.
- `CreateWidget` configures the adjustment as `Position, Min, Max + PageSize, SmallChange, LargeChange, PageSize`.
- `SetParams` repeats the same `Max + PageSize` upper configuration.
- `CreateWidget` connects `AAdj` signal `'value-changed'` to `TGtk4ScrollBar.value_changed` with `Self` as user data.
- The GTK4 binding declares `GtkAdjustment.value_changed` as receiving `adjustment: PGtkAdjustment`.
- Current `TGtk4ScrollBar.value_changed` is declared with one parameter: `bar: TGtk4Scrollbar`.

Consequence by source logic:

- A `GtkAdjustment::value-changed` signal callback receives the adjustment object first, not the Pascal `Self` user data.
- The current callback treats that first argument as a `TGtk4ScrollBar`.
- Therefore `Gtk4IsLiveWidgetPointer(bar)` is expected to fail or the callback may read the wrong object type.
- If the callback is corrected, it must also guard `InUpdate`, otherwise programmatic `SetParams` may emit `value-changed` and re-enter LCL state updates.

### GTK4 scrollable-control reference path

GTK4 already has a better pattern for scrolled-window scrollbar adjustment callbacks:

- `Gtk4ScrollAdjChangedCB(AAdj: PGtkAdjustment; AData: TGtk4ScrollableWin)`: `lcl/interfaces/gtk4/gtk4widgets.pas:7470`
- It checks `AAdj`, `AData`, `Gtk4IsLiveWidgetPointer(AData)`, `LCLObject`, and `AData.InUpdate`.
- It identifies whether the adjustment belongs to the horizontal or vertical scrollbar.
- It clamps native value to `upper - page_size`.
- It delivers `LM_HSCROLL` / `LM_VSCROLL`.

This is not directly reusable for standalone `TScrollBar`, but it is the closest existing GTK4 pattern.

### GTK2 and Qt5 reference behavior

GTK2:

- `TGtk2WSScrollBar.SetParams`: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2742`
- It configures GTK adjustment with `Position, Min, Max, SmallChange, LargeChange, PageSize`.
- GTK2 generic callbacks deliver scroll messages through GTK2 callback infrastructure.

Qt5:

- `TQtWSScrollBar.SetParams`: `lcl/interfaces/qt5/qtwsstdctrls.pp:362`
- It sets native range to `Min .. Max - PageSize`.
- It clamps native value to the native max when needed.
- Qt5 widget event code delivers `LM_HSCROLL` / `LM_VSCROLL`.

Important comparison:

- GTK2 and Qt5 do not feed `Max + PageSize` back into the LCL `Max`.
- GTK4 currently configures `upper = Max + PageSize`, but `value_changed` calls `scr.SetParams(..., round(AAdj^.get_upper), round(AAdj^.get_page_size))`. If the callback is made functional without correcting this, LCL `Max` can become `Max + PageSize`.

## Validation Questions

The runtime test must answer these before code is changed:

1. Does dragging/clicking GTK4 standalone `TScrollBar` currently fire `OnScroll`?
2. Does it fire `OnChange`?
3. Does `Position` update after user interaction?
4. Does `Max` change unexpectedly after user interaction when `PageSize > 0`?
5. What is the native effective maximum with GTK4's current `upper = Max + PageSize` setup?
6. If `upper` is changed to `Max`, does the user-reachable max match GTK2/Qt5/LCL expectations?
7. If callback feedback uses `upper - page_size` as LCL max, does it preserve expected `Max`?
8. Does programmatic `Position`, `Min`, `Max`, or `PageSize` change emit duplicate `OnChange` or `OnScroll` after callback correction?

## Validation Run 1

Date: 2026-07-09

Commands:

```bash
./lazbuild --ws=gtk4 example_gtk4_scrollbar_validation/scrollbar_validation.lpi
xvfb-run -a env SCROLLBAR_VALIDATION_AUTO=1 ./example_gtk4_scrollbar_validation/scrollbar_validation
```

Build result:

- GTK4 build succeeded.
- The first build attempt without `--ws=gtk4` used the user's default gtk2 target and failed to find GTK4-internal units. The successful command explicitly passed `--ws=gtk4`.

Runtime result:

- Initial LCL state `Min=0 Max=100 PageSize=10` produced native `lower=0 upper=110 page=10`.
- Setting native horizontal adjustment to `25` produced `OnChange`, but no `OnScroll`.
- After that native change, LCL state changed to `Position=25 Min=0 Max=110 PageSize=10`.
- The following native state became `upper=120 page=10`, showing feedback growth.
- Setting native vertical adjustment to `40` also produced `OnChange`, no `OnScroll`, and changed LCL `Max` from `100` to `110`.
- Setting `Min=50 Max=150 PageSize=20` after handle creation produced repeated `OnChange` events during programmatic setup. LCL `Max` grew to `170`, then native `upper` grew to `190`.
- Subsequent native values caused further growth: LCL `Max` reached `190`, then native `upper` reached `210`.

Observed evidence:

```text
initial horizontal kind=0 pos=0 min=0 max=100 page=10 ... native value=0.00 lower=0.00 upper=110.00 page=10.00
native-set request kind=0 value=25.00
EVENT OnChange sender-kind=0
during OnChange kind=0 pos=25 min=0 max=110 page=10 ... native value=25.00 lower=0.00 upper=110.00 page=10.00
after native h=25 kind=0 pos=25 min=0 max=110 page=10 ... native value=25.00 lower=0.00 upper=120.00 page=10.00
```

Validation answers so far:

| Question | Answer from run 1 |
| --- | --- |
| Does native adjustment movement update LCL `Position`? | Yes, when the adjustment is changed directly in the example. |
| Does it fire `OnChange`? | Yes. |
| Does it fire `OnScroll`? | No event occurred in the automatic native-adjustment test. |
| Does `Max` change unexpectedly when `PageSize > 0`? | Yes. `Max` grows by `PageSize` through feedback. |
| Does programmatic setup emit duplicate callbacks? | Yes. `SetBoth(75, 50, 150, 20)` after handle creation produced multiple `OnChange` events and `Max` feedback growth. |

Interpretation update:

- The runtime result confirms the `Max + PageSize` feedback defect.
- The runtime result also confirms missing `OnScroll` delivery for the tested adjustment-change path.
- The source-level callback signature concern needs one more check before being stated as the sole cause, because the automatic test did reach LCL `OnChange`. The callback may be invoked through a Pascal/GLib calling convention that still passes the user data in the observed build, or another path may be involved. The fix plan must therefore be based on observed behavior:
  - preserve or intentionally correct native adjustment callback delivery;
  - add an `InUpdate` guard;
  - prevent `upper` from being fed back as LCL `Max`;
  - deliver `LM_HSCROLL` / `LM_VSCROLL` or otherwise invoke the LCL scroll path when user/native scrolling occurs.

## Validation Run 2: X11 Pointer / Key Input

Date: 2026-07-09

Purpose:

- Confirm whether the defects from run 1 are limited to direct native
  `GtkAdjustment.set_value`, or whether they also occur through real pointer/key
  input delivered to the GTK4 scrollbar widget.
- This run does not modify GTK4 implementation code.

Example-only change:

- `CloseTimer` now dumps final horizontal and vertical scrollbar state before
  terminating. This makes no-input and input runs comparable.

Build:

```bash
./lazbuild --ws=gtk4 example_gtk4_scrollbar_validation/scrollbar_validation.lpi
```

Build result:

- GTK4 build succeeded.

No-input control run:

```bash
xvfb-run -a env SCROLLBAR_VALIDATION_CLOSE_MS=1000 \
  ./example_gtk4_scrollbar_validation/scrollbar_validation
```

Control result:

- With no external input, `Position`, `Max`, and native `upper` stayed stable:
  `Max=100`, `PageSize=10`, native `upper=110`.
- No `OnScroll` or `OnChange` occurred.

Pointer/key input run:

```bash
xvfb-run -a bash -lc 'env SCROLLBAR_VALIDATION_CLOSE_MS=3500 \
  ./example_gtk4_scrollbar_validation/scrollbar_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 ScrollBar validation"); \
  echo XTEST_WINDOW:$wid; sleep 0.5; \
  xdotool mousemove --window "$wid" 350 36 click 1; sleep 0.3; \
  xdotool key --window "$wid" Right Page_Down End; sleep 0.3; \
  xdotool mousemove --window "$wid" 422 240 click 1; sleep 0.3; \
  xdotool key --window "$wid" Down Page_Down End; \
  wait $app'
```

Pointer/key result:

- The horizontal click/key sequence fired `OnChange`, not `OnScroll`.
- The vertical click/key sequence fired `OnChange`, not `OnScroll`.
- Horizontal state changed from `Position=0 Max=100` to
  `Position=97 Max=120`, with native `upper=130`.
- Vertical state changed from `Position=0 Max=100` to
  `Position=100 Max=110`, with native `upper=120`.
- Total events were `scroll=0 change=2`.

Observed evidence:

```text
EVENT OnChange sender-kind=0
during OnChange kind=0 pos=97 min=0 max=110 page=10 events scroll=0 change=1 native value=97.00 lower=0.00 upper=110.00 page=10.00
EVENT OnChange sender-kind=1
during OnChange kind=1 pos=100 min=0 max=110 page=10 events scroll=0 change=2 native value=100.00 lower=0.00 upper=110.00 page=10.00
final horizontal kind=0 pos=97 min=0 max=120 page=10 events scroll=0 change=2 native value=97.00 lower=0.00 upper=130.00 page=10.00
final vertical kind=1 pos=100 min=0 max=110 page=10 events scroll=0 change=2 native value=100.00 lower=0.00 upper=120.00 page=10.00
```

Run 2 interpretation:

- The `OnScroll` omission is not limited to the artificial native-adjustment
  path. It is also observed with pointer/key input under Xvfb/X11.
- The `Max + PageSize` feedback problem is also not limited to direct
  adjustment writes. Real input changes the LCL public `Max` and then expands
  native `upper` again.
- The no-input control run proves that the final-state dump itself does not
  change `Max` or native `upper`.

Validation answers updated:

| Question | Answer after run 2 |
| --- | --- |
| Does dragging/clicking/key input fire `OnScroll`? | No in the Xvfb/X11 pointer/key run. |
| Does user-like input fire `OnChange`? | Yes. |
| Does `Position` update after user-like input? | Yes. |
| Does `Max` change unexpectedly after user-like input when `PageSize > 0`? | Yes. |
| Is the direct-native result representative of actual input? | Yes for the two confirmed defects: missing `OnScroll` and `Max` feedback growth. |

## Focused Test Program

Created focused example:

- `example_gtk4_scrollbar_validation/`

Tracked source/config files:

- `example_gtk4_scrollbar_validation/scrollbar_validation.lpi`
- `example_gtk4_scrollbar_validation/scrollbar_validation.lpr`
- `example_gtk4_scrollbar_validation/.gitignore`

Ignored build outputs:

- `scrollbar_validation`
- `*.compiled`
- `*.o`
- `*.or`
- `*.res`

The example contains:

- one horizontal `TScrollBar`;
- one vertical `TScrollBar`;
- labels showing `Position`, `Min`, `Max`, `PageSize`;
- counters for `OnScroll` and `OnChange`;
- buttons to set:
  - `Min=0, Max=100, PageSize=0`;
  - `Min=0, Max=100, PageSize=10`;
  - `Min=50, Max=150, PageSize=20`;
  - `Min=0, Max=10, PageSize=20`;
  - `Kind` horizontal/vertical changes;
  - programmatic `Position` changes.

Console logging should print:

- event type: `OnScroll` or `OnChange`;
- scroll code;
- scroll position argument;
- current LCL `Position`, `Min`, `Max`, `PageSize`;
- if accessible, native adjustment lower/upper/page/value through GTK4-specific debug helper code.

Run under GTK4 first. If practical, compile the same example under GTK2 and Qt5 for behavior comparison.

## Expected Diagnosis Outcomes

### Outcome A: Current GTK4 user scroll does not update LCL state

Likely cause:

- wrong `GtkAdjustment::value-changed` callback signature.

Candidate fix plan:

- Change callback shape to receive both adjustment and user data:
  - `class procedure value_changed(AAdj: PGtkAdjustment; AData: TGtk4ScrollBar); cdecl;`
- Validate `AData` with `Gtk4IsLiveWidgetPointer`.
- Exit when `AData.InUpdate`.
- Use `AData.LCLObject` only after nil/type checks.

### Outcome B: Current or corrected GTK4 changes LCL `Max`

Likely cause:

- callback feeds native `upper` directly into `TScrollBar.SetParams`, while GTK4 configured upper as `Max + PageSize`.

Candidate fix options to validate:

1. Keep native `upper = Max + PageSize`, but feed LCL max as `upper - page_size`.
2. Change native adjustment to match GTK2 (`upper = Max`) and test native effective maximum.
3. Change native adjustment to match Qt5 visible range (`upper = Max`, or native max equivalent `Max - PageSize`) only if runtime proves GTK4 semantics require it.

No option should be implemented until the focused example confirms the expected user-reachable position range.

### Outcome C: Programmatic changes cause duplicate events

Likely cause:

- corrected callback lacks `InUpdate` guard.

Candidate fix plan:

- Mirror `Gtk4ScrollAdjChangedCB` and exit while `AData.InUpdate`.

## Clean Build Requirement

After any future implementation change:

1. Clean build LCL GTK4.
2. Build Lazarus or the affected package set if the change touches shared standard controls.
3. Build and run `example_gtk4_scrollbar_validation`.
4. If practical, build and run the same example under GTK2 and Qt5.
5. Confirm no regression in:
   - `TScrollBar` standalone controls;
   - scrolled controls that use `Gtk4ScrollAdjChangedCB`;
   - `TCustomScrollBox`;
   - `TListBox`/`TMemo`/`TListView` scrolling paths.

## Do Not Change Yet

- Do not edit Lazarus IDE code.
- Do not alter GTK4 scrolled-window callbacks unless the standalone scrollbar fix requires shared helper extraction and the scrolled-control tests pass.
- Do not change LCL common `TCustomScrollBar` semantics unless GTK2/Qt5 comparison proves the common behavior is wrong.
- Do not assume GTK4 adjustment `upper` semantics from source alone; verify with the focused runtime example.

## Implementation Fix (2026-07-10)

Validation runs 1-2 confirmed both defects, so the fix was applied. Scope:
`lcl/interfaces/gtk4/gtk4widgets.pas` only.

Pre-fix mechanism correction (refines the audit's callback-signature claim):
FPC non-static `class procedure` methods receive a hidden `Self` (class
reference) as the first parameter. Under cdecl the C arguments
`(adjustment, user_data)` therefore mapped as `Self <- adjustment`,
`bar <- user_data`, so the old callback *accidentally worked* — which is why
run 1/2 observed `OnChange` and the active `Max + PageSize` feedback growth,
rather than a dead callback.

Changes:

1. Removed `class procedure TGtk4ScrollBar.value_changed(bar: TGtk4Scrollbar)`.
   Added unit-level `Gtk4ScrollBarAdjChangedCB(AAdj: PGtkAdjustment;
   AData: TGtk4ScrollBar); cdecl;` — the same shape as the existing
   `Gtk4ScrollAdjChangedCB` scrolled-window pattern. Guards: nil checks,
   `Gtk4IsLiveWidgetPointer`, `LCLObject = nil`, `InUpdate`, `csDesigning`.
2. The callback no longer calls `TScrollBar.SetParams` (which fed native
   `upper` back into LCL `Max`). It clamps the value to
   `[lower, upper - page_size]` (when `page_size > 0`) and delivers
   `LM_HSCROLL`/`LM_VSCROLL` with `ScrollCode = SB_THUMBPOSITION`, so
   `TCustomScrollBar.DoScroll` runs: `OnScroll` fires, then `SetPosition`
   fires `OnChange`. `SB_THUMBPOSITION` is the only honest code because
   `GtkAdjustment::value-changed` carries no scroll-type detail (GTK4
   `GtkScrollbar` is not a `GtkRange`, so gtk2's `change-value` +
   `GtkScrollType` mapping is unavailable).
3. Adjustment `upper` changed from `Max + PageSize` to `Max` in both
   `TGtk4ScrollBar.CreateWidget` and `TGtk4ScrollBar.SetParams` — gtk2 parity
   (`TGtk2WSScrollBar.CreateHandle`/`SetParams` use `upper = Max`). The
   user-reachable native maximum is now `Max - PageSize`, below the LCL
   `DoScroll` clamp `(Max - PageSize) + 1`, so no end-of-drag snap-back.
   `TGtk4WidgetSet.GetScrollInfo` reports `nMax := Round(Adjustment^.Upper)`
   directly (`gtk4winapi.inc`), so `upper = Max` is also the correct value to
   expose there.

Post-fix validation:

- Builds: `make lcl LCL_PLATFORM=gtk4`, `make lcl LCL_PLATFORM=gtk2`,
  `make bigide LCL_PLATFORM=gtk4` — no errors.
- Auto run (`SCROLLBAR_VALIDATION_AUTO=1`, Xvfb): `OnScroll` fires
  (`scPosition`), `Max` stays `100`, native `upper` stays `= Max`,
  over-max native set (160 with Max=150 Page=20) clamps to 130
  (= Max - PageSize), programmatic `SetBoth` produces no scroll-event
  feedback (scroll count unchanged during setup).
- Pointer/key run (Xvfb + xdotool, same script as run 2): `OnScroll` fired
  3x, `OnChange` 2x, final `Max=100` both bars, native `upper=100.00` —
  pre-fix this run inflated `Max` to 120/110 with `scroll=0`.
- One extra `OnScroll` with an unchanged position can occur at
  interaction end (GTK emits a final value-changed); `DoScroll` then calls
  `Scroll()` but `SetPosition` is a no-op, so no duplicate `OnChange`.
  Cross-widgetset precedent: gtk2/qt also deliver multiple scroll messages
  per gesture (`SB_THUMBPOSITION` + `SB_ENDSCROLL`).

Cross-review: codex (read-only sandbox) reviewed the diff against the GObject
value-changed ABI, the InUpdate/BeginUpdate re-entrancy path
(`gtk4wsstdctrls.pp` `TGtk4WSScrollBar.SetParams`), other
`gtk4_scrollbar_get_adjustment` consumers, and TTrackBar/scrolled-window
paths; no defects found. Its citations (GetScrollInfo upper exposure, gtk2
upper=Max, wtScrollBar exclusion in TGtk4Range.InitializeWidget) were
re-verified directly against the source.

Remaining manual (real-hardware) checks before commit:

1. Drag/click/wheel a standalone `TScrollBar` — `OnScroll` + `OnChange` fire,
   `Position` tracks, `Max` never changes.
2. Thumb reaches the right/bottom end without snap-back; reachable max is
   `Max - PageSize` (gtk2-equal).
3. IDE regression: source editor / listbox / memo / scrollbox scrolling
   unchanged (these use `Gtk4ScrollAdjChangedCB`, untouched).
4. Designer: placing/dragging a `TScrollBar` on a form does not corrupt
   `Position` (csDesigning guard).
