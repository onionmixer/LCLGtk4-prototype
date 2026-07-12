# GTK4 WSControls Runtime Validation

Rollback point: recorded in repository history before the broader LCL widgetset audit work; no implementation files are changed by this validation pass.

## Scope

This document tracks focused runtime validation for `lcl/widgetset/wscontrols.pp` and the GTK4 implementation in `lcl/interfaces/gtk4/gtk4wscontrols.pp`.

The validation is intentionally limited to observation. It must not modify LCL-GTK4 implementation code.

## Source Review Targets

- Generic `TWinControl` handle path: `TGtk4WSWinControl.CreateHandle`, `DestroyHandle`.
- Generic bounds/text/client/preferred-size path: `SetBounds`, `SetPos`, `SetSize`, `GetClientRect`, `GetPreferredSize`.
- Painting path: `Invalidate`, `Repaint`, `PaintTo`.
- Visibility path: `ShowHide`.
- Scroll path: `ScrollBy`.
- Z-order path: `SetChildZPosition`.
- Known source-risk points from `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`:
  - `DefaultWndHandler` is a no-op in GTK4, but follow-up source tracing shows
    the generic GTK2/Qt5 paths also do not provide a non-empty fallback.
  - `AddControl` casts to `TWinControl` without the defensive guard used by Qt5,
    but source tracing found the normal LCL call path is
    `TWinControl.AddControl(Self)`.
  - `ScrollBy` casts the handle to `TGtk4ScrollingWinControl` before checking
    whether the native widget is a scrolled window. Follow-up source/runtime
    checks validate the normal `TScrollBox` and `TMemo` paths, but the cast
    remains less defensive than GTK2/Qt5 source style.
  - `SetBounds` has a debug-only reference to an undeclared `AWidget` when GTK4 debug defines compile that block.
  - `SetShape` is intentionally unsupported on GTK4/Wayland.

## Example

- Directory: `example_gtk4_wscontrols_validation/`
- Project: `wscontrols_validation.lpi`
- Program: `wscontrols_validation.lpr`

The example records:

1. `TCustomControl` handle creation, client rectangle, preferred size, paint count.
2. `Invalidate` and `Repaint` on a custom control.
3. `PaintTo` into a bitmap canvas.
4. Runtime `SetBounds` on a custom control and child inside a `TScrollBox`.
5. `ScrollBy` on a `TScrollBox`.
6. `ScrollBy` on a non-scrolling `TPanel`.
7. Overlapping child `BringToFront` ordering.
8. Hidden control show/hide.
9. Form and child-control constraints, including min-only, max-only, and
   min=max/fixed-size programmatic bounds cases.
10. GTK4 native `GtkScrolledWindow` adjustment values for the `TScrollBox`
    scroll path, in addition to public LCL scrollbar positions.
11. Runtime `TButton` reparenting between two `TPanel` parents, with native GTK
    parent pointer comparison against the expected parent `GetContainerWidget`.
12. A `TLabel` graphic-control case to confirm ordinary non-windowed controls
    stay outside the `TWinControl` handle path.
13. `TMemo.ScrollBy` with native GTK adjustment logging, covering a scrollable
    handle that is `TGtk4Memo` rather than `TGtk4ScrollingWinControl`.
14. `PaintTo` bitmap non-white pixel counts for a visible parent with child
    controls, a hidden-at-startup panel, a temporarily shown hidden panel, and
    an unparented panel.
15. GTK4 native size-request, allocation, and window default-size logging for
    the focused constraints cases.
16. LCL accessible object handle creation and accessible
    name/description/value setter paths for a `TButton` and a non-windowed
    `TLabel`.
17. Drag-image public API result and LCL drag message/cursor dispatch paths.
18. Separate menu-form and hidden-startup-form constraint cases, including
    GTK4 menu-bar/non-client overhead logging.

## Commands

Build:

```sh
./lazbuild --ws=gtk4 example_gtk4_wscontrols_validation/wscontrols_validation.lpi
```

Auto run:

```sh
WSCONTROLS_VALIDATION_AUTO=1 xvfb-run -a example_gtk4_wscontrols_validation/wscontrols_validation
```

Manual run:

```sh
WSCONTROLS_VALIDATION_CLOSE_MS=30000 xvfb-run -a example_gtk4_wscontrols_validation/wscontrols_validation
```

## Result

Build/run date: 2026-07-09.

Normal build:

```sh
./lazbuild --ws=gtk4 example_gtk4_wscontrols_validation/wscontrols_validation.lpi
```

Result: succeeded.

Auto run:

```sh
xvfb-run -a env WSCONTROLS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wscontrols_validation/wscontrols_validation
```

Result: completed without Pascal exception. A direct `WSCONTROLS_VALIDATION_AUTO=1 xvfb-run -a ...` run failed with `Gtk-WARNING **: cannot open display`; forcing `GDK_BACKEND=x11` was required in this environment.

Debug-size build:

```sh
./lazbuild --ws=gtk4 -B -r --opt=-dGTK4DEBUGSIZE example_gtk4_wscontrols_validation/wscontrols_validation.lpi
```

Result: succeeded. The previously noted `SetBounds` debug block concern is not a compile failure on the current source and compiler configuration.

Observed runtime facts:

- `TCustomControl` handle allocation succeeded after show.
- Initial `ClientRect` and preferred size matched the assigned bounds for the probe control.
- The probe `Paint` method ran after initial show.
- `Invalidate` plus `Repaint` did not synchronously increase the paint count in the immediate log step, but a later step showed an additional paint.
- `PaintTo` into a bitmap canvas completed and caused the probe paint count to increase from `1` to `2`.
- `PaintTo` into a visible parent panel with child controls produced nonblank
  bitmap output (`nonwhite=7899` for a 150x54 bitmap). This confirms the GTK4
  paintable path can draw visible composite controls in the focused run.
- `PaintTo` on the hidden-at-startup panel while hidden had
  `handle=False`, `alloc=unallocated`, and `nonwhite=0`; this is consistent
  with `TWinControl.PaintTo` doing nothing when no handle exists.
- The same hidden-at-startup panel, after `Visible := True`,
  `Application.ProcessMessages`, and `Repaint`, had `handle=True`,
  `alloc=(180,54)`, but still produced `nonwhite=0`. A later capture after the
  handle persisted also produced `nonwhite=0`. This confirms a GTK4 runtime
  limitation for this hidden-at-startup/late-shown panel scenario, not merely
  a zero-allocation result.
- `PaintTo` on an unparented panel had `handle=False`, `alloc=unallocated`,
  and `nonwhite=0`, matching the no-handle path.
- Runtime `SetBounds` on the probe changed its bounds from `(16,32,226,104)` to `(30,44,210,108)` and its preferred size from `(210,72)` to `(180,64)`.
- Runtime `SetBounds` on a child inside `TScrollBox` completed and updated the child bounds to `(80,90,540,350)`.
- `TScrollBox.ScrollBy(-40,-50)` completed without exception, but the logged scroll-bar positions stayed `(0,0)`.
- A follow-up run added GTK4 native adjustment logging. In that run,
  `TScrollBox.ScrollBy(-40,-50)` changed native horizontal/vertical adjustment
  values from `0/0` to `40/50`, while public
  `HorzScrollBar.Position` / `VertScrollBar.Position` still logged as `0/0`.
- A second scroll call, `TScrollBox.ScrollBy(20,25)`, changed the native
  adjustment values from `40/50` to `20/25`; public scrollbar positions again
  remained `0/0`. This proves the GTK4 scrolled-window path does move the
  native viewport in this focused case, and the earlier public-position result
  is not evidence that native scrolling failed.
- Source tracing corrected the non-scrolling panel assumption: public
  `TWinControl.ScrollBy` moves child controls and does not call widgetset
  `ScrollBy`. The widgetset `ScrollBy` path is reached via `ScrollBy_WS`, for
  example from `TScrollingWinControl.ScrollBy` and `TCustomMemo.ScrollBy`.
- `TMemo.ScrollBy(0,-40)` completed without exception and changed the memo
  native vertical adjustment from `0` to `40`; `TMemo.ScrollBy(0,20)` changed
  it back from `40` to `20`. This validates the GTK4 memo path even though the
  handle is `TGtk4Memo`, not `TGtk4ScrollingWinControl`.
- `TPanel.ScrollBy(12,18)` completed without exception and moved the probe child bounds from `(30,44,210,108)` to `(42,62,222,126)`. Source review confirms this path is the inherited `TWinControl.ScrollBy`, which moves child controls and does not call the GTK4 widgetset `ScrollBy`.
- Source tracing found the normal LCL `AddControl` path at
  `TWinControl.AddControl`, which passes `Self` to the widgetset. No normal
  LCL call path was found where a `TGraphicControl` directly reaches GTK4
  `AddControl`.
- Runtime `TButton` reparenting from `ReparentLeft` to `ReparentRight` and back
  completed without exception. Public `Parent` and bounds matched the
  assignments, and native GTK parent pointer comparison matched the expected
  parent container in both directions.
- The validation `TLabel` logged as non-`TWinControl` and remained parented to
  `ReparentLeft`, supporting the source conclusion that ordinary graphic
  controls are not direct widgetset `AddControl` inputs.
- Overlapping child `BringToFront` changed `ControlAtPos` at the overlap point from `FrontPanel` to `BackPanel`, then back to `FrontPanel`.
- Hidden panel `Visible := True` and `Visible := False` completed and public visibility state matched the assignment.
- Setting `ReparentLeft.Constraints.MinWidth=180` and `MinHeight=72`
  changed the GTK native size request/allocation from `150x54` to `180x72`.
  This confirms the non-window child-control min-constraints path updates GTK4
  `size_request` and allocation in the focused run.
- Resetting the same child-control constraints to `0` did not restore the
  logged native size request/allocation to the previous `150x54` during the
  same run; it remained `180x72`. This is a measured caveat of the current
  GTK4 non-window constraint path and should be checked before any fix design.
- Setting the form below `Constraints.MinWidth=500` and `MinHeight=420`
  completed. The logged client size became `(0,0,860,420)`, and native logging
  showed `request=500x420 default=860x420`; the minimum height was reflected,
  while width did not shrink from the previous `860` in this run.
- Setting form max constraints to `700x500` and then assigning bounds
  `900x700` completed. The logged client size/default size became `700x500`,
  while the immediate native allocation still logged as `860x620`. This
  validates the focused programmatic max/default-size path but records a GTK
  allocation-lag observation at the immediate log point.
- Setting form min=max constraints to `640x480` and then assigning bounds
  `760x560` completed. The logged client size/default size became `640x480`,
  while the immediate native allocation still logged as `860x620`. This
  validates the focused fixed-size programmatic path with the same allocation
  timing caveat.
- Restoring the form to min-only `500x420`, max `0`, and bounds `860x620`
  restored the logged client/default size to `860x620`.
- Setting `AccessibleName`, `AccessibleDescription`, and `AccessibleValue` on
  `ReparentButton:TButton` completed without exception. The accessible object
  became handle-allocated, its accessible handle matched the button's GTK4
  owner widget handle, and the LCL stored values logged as
  `"Accessible Move Button"`, `"Button used by GTK4 WSControls validation"`,
  and `"ready"`.
- Setting the same accessible fields on `GraphicLabel:TLabel` completed
  without exception. Because `TLabel` is non-windowed, GTK4 mapped its
  accessible handle to the owner wincontrol `ReparentLeft`; the logged handle
  comparison matched that expected owner handle.
- Resetting the button accessible name/description/value to empty strings
  completed without exception and left the accessible object handle allocated.
  This exercises GTK4's `gtk4_accessible_reset_property` path from the LCL
  setter path.
- Source tracing found that GTK4 defines `TGtk4WSDragImageListResolution`, but
  `lcl/interfaces/gtk4/gtk4wsfactory.pas` currently returns `False` from
  `RegisterDragImageListResolution`. Therefore the active public
  `TDragImageList` path falls back to the base
  `TWSDragImageListResolution`, whose `BeginDrag` returns `False`.
- The focused runtime run confirmed that `TDragImageList.BeginDrag` returned
  `False`, `Dragging` stayed `False`, and the validation skipped
  `DragMove`/show/hide/end calls to avoid the nil dragging-resolution path.
  This is a measured active-path result, not just a source inference.
- LCL drag-message dispatch was tested separately through a small validation
  panel exposing `DoDragMsg`. `dmDragEnter` and `dmDragMove` both returned `1`,
  the target `OnDragOver` handler ran twice, and `dmDragDrop` ran the target
  `OnDragDrop` handler once.
- The tested `TDragControlObject` cursor path returned the source control's
  `DragCursor` for accepted drags and `crNoDrop` for rejected drags
  (`cursor-accept=-21`, `cursor-reject=-13`, `source-dragcursor=-21` in the
  run). This validates LCL cursor selection logic, not actual GTK pointer
  cursor rendering during a real mouse drag.
- A separate menu form with submenu-backed `TMainMenu` completed without
  Pascal exception. GTK4 reported `menubar-height=24` and `overhead=24`.
  With constraints `Min=320x180`, `Max=400x220`, the shown client rect logged
  as `400x196`, while native `request/default` logged as `400x220`.
  This proves the menu/non-client overhead path is active in the focused run:
  the native window height includes the 24-pixel menu overhead, and LCL client
  height is reported after subtracting that overhead.
- The same menu form stayed at client `400x196` / native `400x220` after both
  too-large and too-small programmatic bounds assignments. This matches the
  current GTK4 constraint logic that treats max dimensions as effective
  minimum request/default dimensions for windows.
- A hidden-startup form created with no handle and constraints
  `Min=420x260`, `Max=480x320` logged client `420x260` before show after a
  below-min `SetBounds`. After `Show`, it logged client/native/default
  `480x320`, and a later too-large `SetBounds` stayed at `480x320`.
  This confirms constraints are applied when a hidden-at-startup form is later
  shown in the focused run, with the same max-as-effective-minimum caveat.
- GTK emitted the existing startup warning `g_regex_match_full: assertion 'string != NULL' failed`; no new Pascal exception was observed.

## Implementation Fix (2026-07-10)

Scope decision after re-review of every §5 candidate:

- `DefaultWndHandler` — NO CODE CHANGE. Source tracing (see Remaining checks
  below) proved the GTK4 no-op is net-equivalent to GTK2/Qt5: neither
  overrides the method, and both fall through to the EMPTY base
  `TWidgetSet.CallDefaultWndHandler` (`lcl/include/intfbaselcl.inc:55`).
  GTK3 is also an explicit no-op. Reclassified `shared_baseline`.
- `AddControl` — NO CODE CHANGE. The only LCL call site is
  `TWinControl.AddControl` (`lcl/include/wincontrol.inc:6185`), which passes
  `Self`, so the argument is always a handle-checked `TWinControl`; the hard
  cast cannot receive a graphic control through any normal path
  (runtime-validated with button reparenting + label control).
- `SetShape` / `ConstraintsChange` / `PaintTo` — NO CODE CHANGE this pass.
  Backend limitation, needs-fix-design, and hidden-late-shown blank case
  respectively; all documented, none is a safe minimal fix.

Changes:

1. `lcl/interfaces/gtk4/gtk4wsfactory.pas` `RegisterDragImageListResolution`
   — now registers `TGtk4WSDragImageListResolution` (gtk2/qt5 factory
   pattern) instead of returning `False`. The class is the intended
   no-visual implementation: GTK4/Wayland cannot position a drag-image
   overlay, but its methods return `True` so the public
   `TDragImageList.BeginDrag`/`Dragging` state machine behaves like the
   other widgetsets.
2. `lcl/interfaces/gtk4/gtk4wscontrols.pp` `TGtk4WSWinControl.ScrollBy` —
   replaced the unverified hard cast to `TGtk4ScrollingWinControl` with an
   `is TGtk4ScrollableWin` guard + cast to that common ancestor, which is
   the class that actually declares `GetScrolledWindow`/`ScrollX`/`ScrollY`.
   `ScrollBy_WS` is reachable with a `TGtk4Memo` handle
   (`TCustomMemo.ScrollBy`), which is a `TGtk4ScrollableWin` but NOT a
   `TGtk4ScrollingWinControl`; the old code worked only because the members
   happen to live in the shared ancestor. Behavior is unchanged for all
   real callers (runtime-confirmed below).

### Validation Run (post-fix, 2026-07-10)

- Builds: `make lcl LCL_PLATFORM=gtk4`, gtk2 regression, and
  `make bigide LCL_PLATFORM=gtk4` — all 0 errors.
- Auto run (43 steps, no exception): drag-image step went from
  `begin=False ... skip move/show/end` to
  `begin=True dragging-after-begin=True move=True end=True
  dragging-after-end=False`; the full lifecycle now runs through the GTK4
  class. ScrollBox/Memo native adjustment values are identical to the
  pre-fix baseline (scrollbox 40/50 → 20/25 round trip, memo 40 → 20), so
  the ScrollBy hardening changed no behavior.

### Codex review (2026-07-10)

- ScrollBy change: no findings — ancestor declarations, descent of both
  wrappers, and non-shadowing of `ScrollX/ScrollY` verified.
- One Medium finding on the drag registration, verified directly and
  dispositioned as a PRE-EXISTING SHARED LCL-CORE asymmetry, not a GTK4
  regression: `TDockPerformer.DragStop`
  (`lcl/include/dragmanager.inc:555`) never calls `FDragImageList.EndDrag`,
  while `TDragPerformer.DragStop` (`:230`) does. A CUSTOM dock object that
  overrides `GetDragImages` could therefore leak `Dragging=True` and the
  temp cursor after a dock drag — on EVERY widgetset that registers a drag
  image resolution (gtk2/qt5/win32 behave identically; base
  `TDragObject.GetDragImages` returns nil and `TDragDockObject` does not
  override it, so default dock drags are unaffected; `TCustomTreeView`'s
  drag images go through `TDragPerformer`, which cleans up correctly).
  Fixing this would require editing LCL core (`dragmanager.inc`), which was
  initially out of scope for the GTK4 work; recorded here as an upstream
  note. RESOLVED 2026-07-10 after the user authorized careful LCL-core
  review — see "LCL Core Fix — dock drag-image release" below.

## LCL Core Fix — dock drag-image release (2026-07-10)

The upstream note above was runtime-proven and fixed in LCL core with the
user's explicit approval for careful core changes.

Reproduction (`example_lcl_dockdrag_validation/`, self-asserting — exits
nonzero on failure): a custom `TDragDockObject` overriding `GetDragImages`,
`BeginDrag(True)` then `CancelDrag`, two rounds, plus a default dock object
round. Pre-fix, on gtk4, gtk2 AND qt5 alike: `Dragging=True` leaked after
every cancel (and each next dock drag stacked another
`Screen.BeginTempCursor`), proving a shared LCL-core defect, not a
widgetset one.

Fix (`lcl/include/dragmanager.inc`, `TDockPerformer.DragStop`): call
`FDragImageList.EndDrag` right after `SetCaptureControl(nil)` — the exact
mirror of `TDragPerformer.DragStop`. `EndDrag` guards on `Dragging`, so the
call is idempotent with the `DragMove` early-`EndDrag` path.

Post-fix: `Dragging=False` after cancel on gtk4/gtk2/qt5; the default dock
object round is unaffected (`GetDragImages=nil` keeps the call a no-op);
gtk4 wscontrols drag probes and the wsdialogs suite unchanged; bigide
builds clean. Codex review of the core change: placement precedent
(`TDragPerformer` releases equally early, before `dmDragLeave`),
double-EndDrag idempotence, ldocktree/anchordocking non-dependence on
drag-image state, and win32 `ImageList_EndDrag` ordering all verified; no
findings on the core hunk. Its one Low finding (the example passed
vacuously on exit code) was fixed by making the example self-asserting
(`FAIL` log + `ExitCode := 1`). Pre-existing, unrelated:
`TDragManagerDefault.Destroy` does not stop an in-flight drag on shutdown —
affects the normal drag performer equally and is left as a documented
upstream observation.

Remaining checks:

- `TWSWinControl.DefaultWndHandler` source tracing is complete for the generic
  GTK2/Qt5/GTK3/GTK4 comparison. `TWinControl.DefaultHandler` reaches the
  widgetset method only after normal message `Dispatch` has no handler. GTK4 is
  no-op here, GTK3 is also an explicit no-op, and GTK2/Qt5 have no reviewed
  generic non-empty fallback beyond the base empty `TWidgetSet`
  implementation. This is no longer a GTK4-specific fix candidate unless a
  concrete message path is later proven to have GTK2/Qt5 fallback behavior.
- `TScrollBox.ScrollBy` and `TMemo.ScrollBy` now both have native GTK
  adjustment evidence under Xvfb/X11. The remaining `ScrollBy` concern is
  limited to source hardening: the GTK4 method still performs a less defensive
  hard cast than GTK2/Qt5, but no normal non-scrollable `ScrollBy_WS` caller has
  been proven in this pass.
- `AddControl` ordinary runtime reparenting is now validated for a `TButton`,
  and ordinary graphic-control parenting is source/runtime checked as outside
  the direct widgetset handle path. Design-time/IDE reparenting remains
  untested.
- `PaintTo` visible-parent-with-children is now validated as nonblank, but
  hidden-at-startup/late-shown panel output is confirmed blank despite native
  allocation. Broader visual parity and root-cause analysis remain separate
  follow-up work.
- `ConstraintsChange` now has focused runtime evidence for non-window
  child-control minimum constraints, programmatic form min/max/fixed
  constraints, menu-bar/non-client overhead, and hidden-startup form show.
  Remaining coverage is narrower: interactive window-manager resize behavior
  is not covered by this example, and the max-as-effective-minimum behavior
  needs explicit fix-design review before changing constraints code.
- Accessibility now has internal LCL-to-GTK4 handle/setter-path evidence for
  button and graphic-label cases. External AT-SPI/tooling visibility remains
  unvalidated.
- Drag-message event dispatch and LCL cursor selection now have focused
  internal evidence. The active GTK4 `TDragImageList` public path is confirmed
  to return `BeginDrag=False` because the GTK4 drag-image resolution class is
  not registered. Real mouse drag behavior and actual pointer-cursor rendering
  remain unvalidated by this example.

## Implementation Fix 2 — scrolled custom-control child placement (2026-07-10)

Origin: the user-reported IDE symptom "selecting ScrollBar PageSize in the
Object Inspector jumps to another item". Reproduced in the real GTK4 IDE
under Xvfb (`--pcp` scratch config, TScrollBar placed, OI window enlarged):
selecting a property row in a SCROLLED Object Inspector rendered the value
editor exactly scroll-offset pixels ABOVE the selected row (3 rows off after
a 3-row scroll; correct at scroll 0; linear in the offset). The designed
TScrollBar itself was a red herring — the earlier standalone-scrollbar fix
(0b5cd16) is unrelated; a focused PageSize-only probe added to
`example_gtk4_scrollbar_validation` confirms Position/Max stay put when
PageSize changes.

Root cause: `TGtk4CustomControl` hosts `TCustomControl` descendants (OI
property grid, grids, SynEdit) as GtkScrolledWindow → Viewport → GtkOverlay
→ [GtkFixed children + paint]. These controls scroll LCL-side — the
scrollbar is an indicator, the LCL repaints with its own offset and places
in-place editors at CLIENT coordinates. The GtkViewport, however, also
physically shifts the GtkFixed by the adjustment value. The PAINT side was
already compensated (`cairo_translate(+adj)` in `LCLGtkFixedSnapshot`);
child-widget placement was not, so every child rendered `adjustment`
pixels above its LCL position.

Fix (`gtk4widgets.pas`), mirroring the existing paint compensation:

1. `Gtk4ParentScrollOffset` — returns the scrolled-window adjustment values
   for parents that are `TGtk4CustomControl` but NOT
   `TGtk4ScrollingWinControl`. TScrollBox and forms are excluded: there the
   viewport shift IS the scrolling mechanism and children must move with
   the content.
2. `TGtk4Widget.Move` and `TGtk4Container.AddChild` add the offset to the
   `gtk4_fixed_move/put` coordinates; `TGtk4Widget.GetPosition` subtracts
   it symmetrically (codex finding — keeps LCL coordinate readback clean).
3. `Gtk4ScrollAdjChangedCB` re-pins all windowed children after delivering
   `LM_H/VSCROLL` (`Gtk4RepinScrolledChildren`), so statically placed
   children stay at their client position when the user scrolls natively.

Validation (real IDE, fixed binary): the OI value editor lands exactly on
the selected row at any scroll offset and tracks its row during further
wheel scrolling; property row selection never jumps. Regression: the
43-step wscontrols auto suite is identical (TScrollBox native adjustment
values byte-identical to baseline — scrollbox children still scroll
natively), toolbar and calendar suites clean, LCL gtk4+gtk2 and bigide
builds clean. Codex review: predicate/descendant analysis, reentrancy,
idempotence verified; its one Low finding (GetPosition symmetry) applied.

## Implementation Fix 3 — PaintTo of hidden-then-shown controls (2026-07-10)

The blank-output limitation recorded above (a panel created hidden then
shown via `Visible:=True` produced `nonwhite=0` despite handle+allocation)
is fixed.

Root cause (verified against gtk-4.6.9 `gtkwidgetpaintable.c`): `PaintTo`
uses `GtkWidgetPaintable`, whose snapshot with `snapshot_count==0` draws
from the widget's cached `render_node` (its last on-screen frame). A
control that has never rendered a frame has `render_node==NULL`, so the
paintable yields an EMPTY node → blank.

Fix (`gtk4wscontrols.pp`, `TGtk4WSWinControl.PaintTo`): keep the paintable
path unchanged for the common case; ONLY when it yields a nil node, fall
back to `gtk_widget_snapshot_child(parent, widget, snapshot)`, which
`gtk_widget_do_snapshot`s the mapped child LIVE and populates its
`render_node`. `snapshot_child` wraps the node in the child's
parent-relative transform, so the child's origin
(`gtk_widget_compute_bounds(widget, parent)`) is cancelled at the cairo
stage (`cairo_translate(X - origin.x, Y - origin.y)`), keeping the passed
snapshot pristine (codex API-contract note). Guarded by `parent<>nil` and
`get_mapped`; a native or still-unrendered child yields a nil node and
draws nothing, exactly as before (no regression, no crash).

Runtime evidence: the hidden-then-shown panel now renders real content —
`nonwhite=9489`, center pixel via `Canvas.Pixels` = `(0,255,255)` = its
`clAqua` Color, and a flatten-over-white dump shows the full panel plus its
"hidden toggle" caption (the saved BMP's channel swap is a pre-existing LCL
SaveToFile BGR quirk; `Canvas.Pixels` reads correctly). The visible-from-
start case is unchanged (`nonwhite=7899`). 43-step suite, gtk2 and bigide
builds clean. Codex review: preconditions, transform cancellation,
nil-path handling, and ownership verified; its one Low finding (pristine-
snapshot API contract) applied by moving the offset to the cairo stage.

New binding: none retained (an initial `gtk4_snapshot_translate` was
reverted when the offset moved to the cairo stage).

## Implementation Fix 4 — window Max no longer acts as effective minimum (2026-07-10)

The `max-as-effective-minimum` caveat (a Max-only window could not be sized
below Max) is fixed.

Root cause: `TGtk4WSWinControl.ConstraintsChange` explicitly coerced the GTK
minimum to Max — `if MH < MaxH then MH := MaxH` / `if MW < MaxW then MW :=
MaxW` before `set_size_request` (the GTK minimum). So Max became the effective
minimum: LCL Width/Height changed but the native window stayed at Max, and LCL
and native disagreed (runtime-confirmed: A-shrink → LCL (200,150) but native
request=(400,300), client=(400,300)).

Fix: feed `set_size_request` the real LCL Min only; Max is enforced
independently by the `notify::default-size` snap-back and `SetBounds` clamping.
Both Min AND Max heights keep the menu-bar overhead add (LCL Min/Max are CLIENT
dimensions; `set_size_request`/`set_default_size` are full-window) — matching
gtk2/qt5/win32, which add the client->window height fix to both bounds (codex
Medium finding). A genuinely fixed-size window (TMainIDEBar, fixed dialogs)
sets Min=Max explicitly, so its minimum is unchanged.

### Validation (example_gtk4_constraints_validation, self-asserting)

- Max-only form (Max=400x300, Min=0): native `request` went from `(400,300)`
  [stuck] to `(-1,-1)`; a shrink to 200x150 now reduces height to 150 (width
  held by the pre-existing realized-width-preservation CoolBar guard in
  `SetBounds`, out of scope; real WM-drag bypasses SetBounds so users shrink
  both). Grow to 600x480 still clamps to (400,300) — max enforcement intact.
- Fixed form (Min=Max=360x260): stays 360x260 for shrink AND grow — no
  regression.
- wscontrols menu-form (Min=320x180, Max=400x220): native `request` went from
  `400x220` (max-as-min) to `320x180` (real min).
- IDE main bar (fixed-height CoolBar, Min=Max) renders correctly; the
  self-asserting example exits 0 (A/B/C asserts pass); gtk2 + bigide clean.

Codex review: no reliance on max-only-means-fixed found in LCL/IDE (TMainIDEBar
sets Min+Max together; the printers rawmode sample uses Min<Max, supporting the
separation); sequencing/overhead math verified; its Medium (min needs the same
menu overhead as max) applied, its Low (make the example asserting) applied.
