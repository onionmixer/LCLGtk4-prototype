# PLAN: GTK4 PairSplitter Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TPairSplitter` / `TPairSplitterSide` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 17.

Primary source findings:

1. GTK2 and Qt5 do not implement a native pair splitter. They register the side class only, or otherwise rely on the common `TWSCustomPairSplitter` fallback behavior.
2. The common fallback implements `AddSide` by using LCL alignment and an internal `TSplitter`.
3. The common fallback `SetPosition` has an important `var NewPosition` contract: when `NewPosition < 0`, it does not move the splitter and writes the actual side width or height back into `NewPosition`.
4. `TCustomPairSplitter.UpdatePosition` depends on that contract by calling `SetPosition(Self, CurPosition)` with `CurPosition := -1`, then assigning `FPosition := CurPosition`.
5. GTK4 implements a native `GtkPaned` pair splitter with `TGtk4Paned`, `GtkPaned.set_position`, and start/end children.
6. GTK4 `SetPosition` currently calls native `set_position(NewPosition)` and returns `True`, but does not write the actual native position back to `NewPosition`.
7. GTK4 `RemoveSide` returns `False`.
8. GTK4 `SetSplitterCursor` returns `False`, while `GetSplitterCursor` returns a default cursor based on `SplitterType`.
9. GTK4 native orientation is fixed when `TGtk4Paned.CreateWidget` creates the handle; `TCustomPairSplitter.SetSplitterType` recreates the handle.

Important source references:

- Baseline declarations and fallback: `lcl/widgetset/wspairsplitter.pp`
- LCL control contract: `lcl/pairsplitter.pas`
- GTK2 reference: `lcl/interfaces/gtk2/gtk2wspairsplitter.pp`
- Qt5 reference: `lcl/interfaces/qt5/qtwspairsplitter.pp`
- GTK3 native reference: `lcl/interfaces/gtk3/gtk3wssplitter.pas`
- GTK4 implementation: `lcl/interfaces/gtk4/gtk4wssplitter.pas`
- GTK4 native widget creation: `lcl/interfaces/gtk4/gtk4widgets.pas`
- GTK4 GtkPaned compatibility bindings: `lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas`

## Validation Questions

1. Does GTK4 build and run a focused PairSplitter example without exceptions?
2. Are two auto-created `TPairSplitterSide` controls present after handle creation?
3. Does `Position := N` update both LCL and native `GtkPaned` position?
4. Does reading `Position` preserve the current position, or does it trigger the `UpdatePosition`/`SetPosition(-1)` path and corrupt LCL/native state?
5. Does changing `SplitterType` recreate the native handle with the expected GTK orientation?
6. Does removing and re-adding a side keep LCL side tracking and native paned children coherent?
7. Does setting `Cursor` preserve the requested cursor value through LCL fallback handling?

## Focused Test Program

Created directory:

- `example_gtk4_pairsplitter_validation/`

The example should:

- create a `TPairSplitter` with its auto-created sides;
- place visible child labels into both sides when they are available;
- log LCL `Position`, native `GtkPaned` position, native orientation, side assignment, side parent state, and cursor;
- set `Position := 120`, then read `Position` to trigger the LCL getter path;
- change `SplitterType` to `pstVertical` and verify native orientation after handle recreation;
- detach and reattach side 1 to exercise `RemoveSide`/`AddSide`;
- keep the window open for manual drag/visual checks when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `PAIRSPLITTER_VALIDATION_AUTO=1`: runs automated state checks and exits;
- `PAIRSPLITTER_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_pairsplitter_validation/pairsplitter_validation.lpi
```

Build result:

- succeeded;
- compiled 297 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env PAIRSPLITTER_VALIDATION_AUTO=1 ./example_gtk4_pairsplitter_validation/pairsplitter_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- GTK critical warnings were printed:
  - `gtk_widget_set_parent: assertion 'GTK_IS_WIDGET (parent)' failed`
  - `gtk_window_get_default_size: assertion 'GTK_IS_WINDOW (window)' failed`
  - `gtk_widget_unparent: assertion 'GTK_IS_WIDGET (widget)' failed` during side detach/re-attach
- no Pascal exception was raised by the validation program.

Observed state results:

| Case | LCL `Position` read | Native position | Native orientation | Cursor | Side state |
| --- | --- | --- | --- | --- | --- |
| after show, before reading `Position` | not read | 180 | horizontal | `crHSplit` | both sides assigned and parented |
| first explicit `Position` read | -1 | 180 | horizontal | `crHSplit` | both sides assigned and parented |
| after `Position := 120`, before reading | not read | 120 | horizontal | `crHSplit` | both sides assigned and parented |
| after reading `Position` following set | -1 | 120 | horizontal | `crHSplit` | both sides assigned and parented |
| after `Cursor := crSize` | not read | 120 | horizontal | `crHSplit` | both sides assigned and parented |
| after `SplitterType := pstVertical` | not read | 130 | vertical | `crVSplit` | both sides assigned and parented |
| after vertical `Position := 90`, before reading | not read | 90 | vertical | `crVSplit` | both sides assigned and parented |
| after reading `Position` following vertical set | -1 | 90 | vertical | `crVSplit` | both sides assigned and parented |
| after side 1 detach | not read | 90 | vertical | `crVSplit` | side 1 no longer assigned |
| after side 1 reattach | not read | 90 | vertical | `crVSplit` | both sides assigned and parented |

Additional observations:

- `Position := 120` and vertical `Position := 90` reached native `GtkPaned` state exactly before any later LCL getter read.
- Reading `TPairSplitter.Position` returned `-1` in both horizontal and vertical cases. This confirms the source-level issue: GTK4 `SetPosition(var NewPosition)` does not write the actual current position back to the var parameter when `TCustomPairSplitter.UpdatePosition` calls it with `-1`.
- Native `GtkPaned.set_position(-1)` did not visibly change the native position in this run; native position stayed `120` or `90`. The LCL cached/logical `Position` value is still wrong because the getter returns `-1`.
- `Cursor := crSize` did not change the effective reported splitter cursor; `GetSplitterCursor` continued to report the orientation default (`crHSplit`). This is consistent with GTK4 `SetSplitterCursor=False` and `GetSplitterCursor` ignoring custom cursor.
- `SplitterType := pstVertical` recreated the handle with native `GTK_ORIENTATION_VERTICAL`, so orientation recreation is usable in this focused path.
- Side detach/re-attach updated LCL side assignment, but emitted GTK critical warnings. Because GTK4 `RemoveSide` returns `False`, native child removal/coherence needs a narrower follow-up before any implementation fix.
- Side controls were present and parented, but reported `1x1` sizes in the automatic xvfb run. Manual visual validation is still needed before classifying side layout as usable.

Interpretation:

- The strongest confirmed defect is `Position` getter semantics. Native writes work, but LCL readback is incorrect because the GTK4 widgetset method violates the common `SetPosition(var NewPosition)` contract used by `UpdatePosition`.
- Custom cursor behavior is not GTK2/Qt5-equivalent for the tested property path.
- Remove/re-add paths are not proven safe because GTK critical warnings occurred during reparenting and the source has no GTK4 `RemoveSide` implementation.
- Orientation mapping itself is usable for the tested handle-recreation path.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect splitter drag behavior, child visibility, side layout, cursor shape, and orientation changes.
4. If practical, run the same example under GTK2 and Qt5 to compare fallback behavior, especially `Position` getter stability and side removal/re-addition.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not assume GTK3 parity is sufficient, because GTK3 appears to share the same native-position write-back omission.
- Do not classify `RemoveSide` solely from source without a runtime side detach/re-attach check, because LCL side tracking can still mask native child state issues.

## Validation Run 2: Close-Time State and X11 Drag

Date: 2026-07-09

Purpose:

- Confirm whether the `Position` readback defect also applies after real
  user-like splitter dragging, not only after programmatic `Position := N`.
- Capture final native/LCL state in manual close mode.
- This run does not modify GTK4 implementation code.

Example-only change:

- `CloseTimer` now logs:
  - `close-native-only` without reading LCL `Position`;
  - `close-read-lcl-position` after forcing `TPairSplitter.Position` read.

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_pairsplitter_validation/pairsplitter_validation.lpi
```

Build result:

- Succeeded.
- Hints only: unused `Sender` parameters.

Auto control command:

```sh
xvfb-run -a env PAIRSPLITTER_VALIDATION_AUTO=1 GDK_BACKEND=x11 \
  ./example_gtk4_pairsplitter_validation/pairsplitter_validation
```

Auto control result:

- Existing run-1 findings reproduced.
- GTK critical warnings around side/widget parent paths reproduced.
- Programmatic native position writes still worked; LCL `Position` readback
  still returned `-1`.

No-drag manual control:

```sh
xvfb-run -a env PAIRSPLITTER_VALIDATION_CLOSE_MS=1200 GDK_BACKEND=x11 \
  ./example_gtk4_pairsplitter_validation/pairsplitter_validation
```

No-drag result:

- Native position stayed at `180`.
- Reading LCL `Position` returned `-1`.

Observed evidence:

```text
close-native-only ... native.position=180 ...
close-read-lcl-position ... lcl.position=-1 native.position=180 ...
```

X11 drag command:

```sh
xvfb-run -a bash -lc 'env PAIRSPLITTER_VALIDATION_CLOSE_MS=2200 GDK_BACKEND=x11 \
  ./example_gtk4_pairsplitter_validation/pairsplitter_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 PairSplitter validation"); \
  xdotool mousemove 204 150; \
  xdotool mousedown 1; \
  xdotool mousemove 230 150; \
  xdotool mousemove 260 150; \
  xdotool mousemove 300 150; \
  xdotool mousemove 340 150; \
  xdotool mouseup 1; \
  wait $app'
```

Drag result:

- Native position changed from `180` to `310`, proving the GTK4 native
  `GtkPaned` drag path is interactive under Xvfb/X11.
- Reading LCL `Position` after that drag still returned `-1`.
- Native position stayed `310` after the read.

Observed evidence:

```text
close-native-only ... native.position=310 ...
close-read-lcl-position ... lcl.position=-1 native.position=310 ...
```

Run 2 interpretation:

- User-like drag confirms the same readback defect as programmatic movement:
  GTK4 native splitter position changes, but the LCL `Position` getter remains
  wrong because the widgetset `SetPosition(var NewPosition)` path does not
  write back the actual native position.
- The native drag path itself is usable in this focused horizontal splitter
  case.
- The screenshot taken during the run showed side labels and the divider
  rendered, but the public side `Width`/`Height` values still logged as `1x1`.
  Side public sizing remains a separate layout/accounting concern.

## Implementation Fix (2026-07-10)

Scope: `lcl/interfaces/gtk4/gtk4wssplitter.pas`, `gtk4widgets.pas`
(TGtk4SplitterSide/TGtk4Paned), `lazgtk4_compat.pas` (two slot getters).
Every baseline defect was reproduced first and re-verified after.

Root causes found (three layers deep):

1. **AddSide misused set_parent(nil)** — not a GTK4 removal API. The side
   arrived as a plain (unmanaged) paned child from the generic
   TGtk4Widget.SetParent; the bogus call only emitted
   "assertion GTK_IS_WIDGET (parent)" criticals and add1/add2 could not
   adopt the still-parented widget. Fixed: temp ref → unparent() →
   set_start/end_child → unref.
2. **The side wrapper was TGtk4Window** — it hard-casts the LCLObject to
   TCustomForm (a side is a TWinControl!) and runs window-only APIs
   (get_default_size criticals). Replaced with a completed
   TGtk4SplitterSide: GtkOverlay + GtkFixed + paint area (the GroupBox
   client pattern, frameless).
3. **The LCL never learned pane sizes** — new TGtk4Paned feedback:
   notify::position + a SetBounds hook queue a one-shot idle that reads
   both sides' allocations and delivers LM_MOVE/LM_SIZE
   (Move/Size_SourceIsInterface) when the LCL bounds differ — the win32
   WM_SIZE/WM_MOVE equivalent. Re-entrancy converges (WMSize/WMMove
   honor the interface source; emission only on change).
4. **SetPosition contract**: negative NewPosition = query only
   (UpdatePosition passes -1 — writing it would unset GtkPaned's
   position); the actual native position is always written back
   (LCL Position was stuck at -1).
5. **RemoveSide implemented (gtk4-specific need)**: GtkPaned never nulls
   its start/end_child pointer when a child is unparented externally
   (gtkpaned.c clears them only in set_*_child and dispose), so
   destroying a side by plain unparent left the paned holding a DANGLING
   child pointer that its own dispose then unparented — gdb-confirmed at
   the SetSplitterType→RecreateWnd path. TGtk4SplitterSide.DetachFromPaned
   clears the slot through the paned API while holding a survival ref;
   DestroyWidget detaches automatically for destroy paths that bypass WS
   RemoveSide, releases the survival ref (or, when the side was
   re-adopted by another container, drops the ref and destroys through
   the normal unparent — codex round-2 finding); AddSide releases the
   survival ref on re-adoption.
6. **Fourth binding-stub trap**: the slot-match in DetachFromPaned never
   fired because TGtkPaned.get_child1/get_child2 are CONSTANT-NIL stubs
   in lazgtk4.pas. Added real gtk4_paned_get_start/end_child compat
   bindings. (Stub family so far: join_group — empty; set_can_default —
   redirects to set_can_focus; get_child1/2 — constant nil; and
   TGtkCalendar.select_month — no-op, breaks TGtk4Calendar.SetDate
   month/year: recorded as follow-up.)

Also incidentally attributed: the long-standing startup
`g_regex_match_full: assertion 'string != NULL'` critical comes from the
fcitx5 GTK4 IM module (gdb backtrace through libim-fcitx5.so), not from
LCL code.

Final validation (auto run, GTK_IM_MODULE=gtk-im-context-simple):
**zero CRITICALs**; side sizes 180x260/519x260 (was 1x1 — children now
lay out); LCL Position round-trips 180/120/90 (was -1);
SetSplitterType recreate clean; detach → reattach clean; real xdotool
divider drag moved the divider 204→298 px with the side child following
(screenshot pixel-measured). gtk4/gtk2 lcl + gtk4 bigide builds clean.

Documented (no change): SetSplitterCursor stays False — GtkPaned's
internal handle provides the native col/row-resize cursor; overriding it
would need private-widget access. Real-hardware checks: divider drag
feel, cursor over the divider, sides with many children, design-time
side frames, bugs/8437 scenario.
