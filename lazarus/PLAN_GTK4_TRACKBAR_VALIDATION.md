# PLAN: GTK4 TTrackBar Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TCustomTrackBar` / `TTrackBar` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 4.10.

Primary source findings:

1. GTK4 creates a real `GtkScale` wrapper through `TGtk4TrackBar`.
2. GTK4 applies range, position, steps, scale position, tick marks/style, and reversed state in `TGtk4WSTrackBar.ApplyChanges`.
3. GTK4 `SetPosition` and `GetPosition` use `GtkRange` value directly.
4. GTK4 passes `Min` and `Max` directly to `GtkRange.set_range`. GTK2 explicitly guards `Min >= Max` by setting upper to `Min + 1` and disabling the widget.
5. GTK4 uses `GtkScale.set_inverted(Reversed)` for both horizontal and vertical orientations. Qt5 uses `not Reversed` for vertical orientation to match Delphi/MSDN compatibility.
6. GTK4 tick marks are added with `GtkScale.add_mark` only when a density guard allows it; dense tick intervals can result in no marks.
7. GTK4 does not override `SetTickStyle`; it relies on the baseline recreate path after `ApplyChanges`.

Important source references:

- Baseline widgetset methods: `lcl/widgetset/wscomctrls.pp:246`, `lcl/widgetset/wscomctrls.pp:951`
- LCL trackbar property dispatch: `lcl/include/trackbar.inc:128`, `lcl/include/trackbar.inc:159`, `lcl/include/trackbar.inc:239`, `lcl/include/trackbar.inc:254`, `lcl/include/trackbar.inc:333`, `lcl/include/trackbar.inc:362`
- GTK4 widgetset methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:386`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:406`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:414`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:424`
- GTK4 range/scale wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas:5784`, `lcl/interfaces/gtk4/gtk4widgets.pas:5809`, `lcl/interfaces/gtk4/gtk4widgets.pas:5828`, `lcl/interfaces/gtk4/gtk4widgets.pas:5845`, `lcl/interfaces/gtk4/gtk4widgets.pas:5880`, `lcl/interfaces/gtk4/gtk4widgets.pas:5916`
- GTK2 reference: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:330`
- Qt5 reference: `lcl/interfaces/qt5/qtwscomctrls.pp:331`

## Validation Questions

1. Does GTK4 build and run a focused `TTrackBar` example without exceptions?
2. Does `Min < Max` produce matching native lower/upper/value and LCL position?
3. Does `Min = Max` produce warnings, crashes, disabled state, adjusted upper bound, or a direct equal native range?
4. Does native orientation match LCL `Orientation` after creation and runtime changes?
5. Does native `inverted` match LCL `Reversed`, and how does that compare with GTK2/Qt5 references?
6. Does changing `TickStyle` at runtime preserve range, position, orientation, reversed state, and handle stability expectations?
7. Does `TickStyle` affect native `GtkScale.draw_value` and `value_pos`?

## Focused Test Program

Created directory:

- `example_gtk4_trackbar_validation/`

The example should:

- create horizontal, horizontal reversed, vertical, vertical reversed, and equal-range track bars;
- set explicit `Min`, `Max`, `Position`, `LineSize`, `PageSize`, `Frequency`, `TickStyle`, `TickMarks`, and `ScalePos`;
- read native GTK4 state from `TGtk4TrackBar.GetContainerWidget`;
- log native orientation, inverted flag, value, adjustment lower/upper/step/page, draw-value flag, and value-position;
- change `TickStyle`, orientation, reversed state, and equal-range params at runtime;
- stay open for manual visual verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `TRACKBAR_VALIDATION_AUTO=1`: runs automated native-state checks and exits;
- `TRACKBAR_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_trackbar_validation/trackbar_validation.lpi
```

Build result:

- succeeded;
- compiled 324 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env TRACKBAR_VALIDATION_AUTO=1 ./example_gtk4_trackbar_validation/trackbar_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- no exception was raised by the trackbar test program.

Observed native-state results:

| Case | LCL orientation | Reversed | LCL min/max/pos | Native orientation | Native inverted | Native lower/upper/value | Draw value | Wrapper position |
| --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| horizontal initial | `trHorizontal` | `False` | `0/100/25` | horizontal | `False` | `0/100/25` | `True` | 25 |
| horizontal reversed initial | `trHorizontal` | `True` | `0/100/40` | horizontal | `True` | `0/100/40` | `True` | 40 |
| vertical initial | `trVertical` | `False` | `0/100/60` | vertical | `False` | `0/100/60` | `True` | 60 |
| vertical reversed initial | `trVertical` | `True` | `0/100/70` | vertical | `True` | `0/100/70` | `True` | 70 |
| equal initial | `trVertical` | `False` | `10/50/50` | vertical | `False` | `10/50/50` | `True` | 50 |
| equal after `SetParams(50,50,50)` | `trVertical` | `False` | `50/50/50` | vertical | `False` | `50/50/50` | `True` | 50 |
| horizontal `TickStyle=tsNone` | `trHorizontal` | `False` | `0/100/33` | horizontal | `False` | `0/100/33` | `False` | 33 |
| horizontal changed to vertical | `trVertical` | `False` | `0/100/33` | vertical | `False` | `0/100/33` | `False` | 33 |

Additional observations:

- Native lower, upper, step, page, and value matched LCL state for the normal `Min < Max` cases.
- `Reversed` mapped directly to native `GtkRange.inverted` for both horizontal and vertical orientations.
- This confirms the source-level comparison: GTK4 matches GTK2's direct inverted mapping and differs from Qt5's vertical compatibility mapping (`not Reversed` for vertical).
- `SetParams(50,50,50)` produced a native equal range with lower=50 and upper=50. It did not crash in this run and did not print a GTK range warning beyond the unrelated startup GLib warning. GTK2 deliberately avoids this state by using upper=`Min+1` and disabling the widget.
- The first attempt to create an equal-range bar through separate `Min := 50; Max := 50` did not stay equal because LCL `ApplyChanges` clamps `Min` down to the current default `Max` before `Max` is changed. The explicit `SetParams(50,50,50)` path is the meaningful equal-range validation.
- `TickStyle=tsNone` changed native `GtkScale.draw_value` from `True` to `False` and preserved range/position.
- Changing orientation at runtime updated native orientation to vertical and preserved range/position. The logged wrapper pointer value was unchanged before/after `TickStyle` and orientation changes, so pointer logging alone is not sufficient evidence for or against full `RecreateWnd` behavior.
- `change_count=4`, matching the four programmatic `Position` updates in the runtime update phase.

Interpretation:

- Basic GTK4 TrackBar range, position, step/page increment, tick-style draw-value, orientation, and direct reversed state are usable in this test.
- Equal `Min = Max` is confirmed as a real GTK4 native state. It is not immediately crashing, but it is not GTK2-equivalent because GTK2 guards and disables the widget. Manual interaction must verify whether dragging/key input is stable in this state.
- Vertical reversed behavior remains a compatibility question rather than a proven crash/defect: GTK4 follows GTK2 direct inversion, while Qt5 intentionally flips vertical inversion for Delphi/MSDN compatibility.
- Tick mark count/placement still needs visual validation because the reviewed GTK4 binding path does not expose a simple mark count getter.

## Validation Run 2: Equal-Range Initial State and X11 Input

Date: 2026-07-09

Purpose:

- Make the focused equal-range case start as a true `Min=Max` range.
- Add user-input logging and final-state dumps.
- Check whether pointer/key input against the equal-range area crashes, emits
  GTK warnings, changes position unexpectedly, or destabilizes native state.
- This run does not modify GTK4 implementation code.

Example-only changes:

- `ConfigureTrack` now uses `SetParams(APosition, AMin, AMax)` so the
  equal-range test is initialized through the same path that previously proved
  `SetParams(50,50,50)` can create a native equal range.
- `OnChange` now logs sender pointer, position, min/max, and total count.
- `CloseTimer` now dumps final state for all trackbars.

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_trackbar_validation/trackbar_validation.lpi
```

Build result:

- Succeeded.
- Hints only: unused `Sender` parameters.

Auto runtime command:

```sh
xvfb-run -a env TRACKBAR_VALIDATION_AUTO=1 \
  ./example_gtk4_trackbar_validation/trackbar_validation
```

Auto runtime result:

- Process exited with code `0`.
- `equal initial` now starts as a real equal range:
  `lcl.min=50 lcl.max=50 lcl.position=50`,
  native `lower=50 upper=50 value=50`.
- Existing normal range, reversed, tick-style, and orientation-change checks
  still pass.

Pointer/key input command:

```sh
xvfb-run -a bash -lc 'env TRACKBAR_VALIDATION_CLOSE_MS=3500 \
  ./example_gtk4_trackbar_validation/trackbar_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 TrackBar validation"); \
  echo XTEST_WINDOW:$wid; sleep 0.5; \
  xdotool mousemove --window "$wid" 664 234 click 1; sleep 0.2; \
  xdotool key --window "$wid" Up Down Page_Up Page_Down Home End; sleep 0.4; \
  xdotool mousemove --window "$wid" 168 210 click 1; sleep 0.2; \
  xdotool key --window "$wid" Up Page_Up; \
  wait $app'
```

Pointer/key result:

- Process exited with code `0`.
- No additional GTK range warning or exception was observed beyond the known
  startup GLib warning.
- Final equal-range state remained stable:
  `lcl.min=50 lcl.max=50 lcl.position=50`,
  native `lower=50 upper=50 value=50`.
- `OnChange` events were delivered to the horizontal trackbar, not the
  equal-range trackbar. Therefore this run proves equal-range pointer/key
  probing did not crash and did not drift state, but it does not prove keyboard
  focus behavior for the equal-range trackbar itself.

Observed evidence:

```text
equal initial ... lcl.min=50 lcl.max=50 lcl.position=50 ... native.value=50.000 native.lower=50.000 native.upper=50.000 ...
EVENT OnChange sender=... position=30 min=0 max=100 total=1
EVENT OnChange sender=... position=20 min=0 max=100 total=2
EVENT OnChange sender=... position=0 min=0 max=100 total=3
EVENT OnChange sender=... position=100 min=0 max=100 total=4
final equal range ... lcl.min=50 lcl.max=50 lcl.position=50 ... native.value=50.000 native.lower=50.000 native.upper=50.000 ...
```

Run 2 interpretation:

- GTK4 equal native range is stable in the automated and X11 pointer/key probe
  used here.
- It remains non-GTK2-equivalent because GTK2 avoids equal native range and
  disables the widget for invalid/equal range paths.
- No urgent crash fix is proven by this run.
- A later manual visual/input pass is still required if the policy goal is
  exact GTK2/Qt5/Delphi behavior for equal-range focus and disabled-state
  semantics.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect horizontal/vertical, reversed, tick style, and equal-range behavior.
4. If practical, run the same example under GTK2 and Qt5 for vertical reversed comparison.
5. Re-test `OnChange`, runtime orientation changes, and `TickStyle` changes after any trackbar change.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not infer visual tick mark count from native `draw_value`; GTK4 bindings expose no simple mark count getter in the reviewed path.
- Do not mark vertical reversed behavior as wrong until GTK2/Qt5/manual visual expectations are compared.

## Implementation Fix (2026-07-10)

Scope: `TGtk4TrackBar.SetTickMarks` in `lcl/interfaces/gtk4/gtk4widgets.pas`
(one guard + Int64 hardening); example extended (dense-range track,
bounds/allocation logging, and an example-side ordering fix).

Code fix — tick-mark density guard unit mismatch: the guard compared
`cnt*Frequency` (the range span in RANGE UNITS, ≈ abs(Max-Min)) against
the widget's PIXEL size, so any track whose numeric range exceeded its
pixel width drew no marks at all. Screenshot-confirmed: 0..1000 with
Frequency=100 on a 420px track (11 marks due) drew none, while
0..100/Frequency=10 (same 11 marks) drew all. New guard compares the
mark COUNT against pixels (`cnt < fldw`, ≥ ~1px per mark), preserving
the anti-density intent (0..100000/Frequency=1 is still suppressed).
Codex review added an overflow hardening: span and loop tick values are
now Int64 so Max near High(Integer) cannot wrap the loop.

Re-review conclusions with NO code change (all verified):

- Equal Min=Max: GTK4 `gtk_range_set_range` accepts `min <= max`
  (gtkrange.c:1064) and slider geometry guards division by zero
  (gtkrange.c:2617, 2628) — the GTK2-era upper=Min+1+disable guard is
  unnecessary. Runtime: lower=upper=50 renders and round-trips with no
  CRITICAL.
- Vertical Reversed: GTK4 = gtk2 parity (direct `set_inverted`,
  gtk2wscomctrls.pp:346). qt5 deliberately negates vertical reversed for
  Delphi/MSDN compatibility (qtwscomctrls.pp:441) — documented
  divergence, baseline is gtk2. Screenshots: non-reversed = min at top,
  reversed = min at bottom.
- Runtime TickStyle/Orientation changes use the baseline RecreateWnd
  path; log shows state (value, draw_value) preserved across recreation.
- `SetTick` remains no-op — parity with gtk2/qt5 (wscomctrls.pp:972).

Example notes: the vertical tracks previously looked collapsed — that
was an EXAMPLE bug, not a widgetset one: LCL `TTrackBar.SetOrientation`
swaps Width/Height (trackbar.inc:128), and the example set
vertical-shaped bounds BEFORE the orientation, ending at 180x48
(logged `lcl.bounds=180x48`). Orientation is now set before bounds;
verticals render with full troughs and marks (48x180 allocation).

Validation: gtk4 lcl / gtk2 lcl / gtk4 bigide clean; auto run passes;
screenshots confirm dense marks appear, sparse tracks unchanged,
vertical directions correct, equal-range track healthy.

Real-hardware checks: tick marks on dense and sparse ranges; vertical
grow direction against a gtk2 build of the same example; keyboard
line/page stepping; runtime orientation/tickstyle toggling.
