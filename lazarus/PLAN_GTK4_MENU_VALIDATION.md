# PLAN: GTK4 Menu / PopupMenu Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TMenuItem`, `TMainMenu`, and `TPopupMenu` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 16.

Primary source findings:

1. GTK4 menu support is substantial: menu bars and popup menus are model/action based (`GMenu`, `GMenuItem`, `GSimpleAction`, `GtkPopoverMenuBar`, `GtkPopoverMenu`).
2. GTK4 activation dispatches `LM_ACTIVATE` through `GAction` callbacks.
3. Check/radio items are created as separate boolean stateful `GSimpleAction` objects.
4. Source comments mention radio grouping through stateful actions, but reviewed code does not show a shared action/target structure equivalent to GTK2/Qt5 radio groups.
5. `SetShortCut` writes the `accel` attribute to `GMenuItem`, but source review did not show a separate GTK shortcut controller.
6. GTK4 popup positioning currently anchors a popover to form content and does not implement GTK2/Qt5 `TPopupMenu.Alignment` adjustment or monitor-edge clamping.
7. Menu item hover/select hint behavior appears missing; GTK2 connects menu item `select`, and Qt5 hooks action hover.

Important source references:

- Baseline menu methods: `lcl/widgetset/wsmenus.pp:37`, `lcl/widgetset/wsmenus.pp:61`, `lcl/widgetset/wsmenus.pp:68`
- GTK4 menu shell/item wrappers: `lcl/interfaces/gtk4/gtk4widgets.pas:7067`, `lcl/interfaces/gtk4/gtk4widgets.pas:7127`, `lcl/interfaces/gtk4/gtk4widgets.pas:7137`, `lcl/interfaces/gtk4/gtk4widgets.pas:7147`
- GTK4 action activation/change-state: `lcl/interfaces/gtk4/gtk4widgets.pas:7269`, `lcl/interfaces/gtk4/gtk4widgets.pas:7288`
- GTK4 menu model rebuild and icons: `lcl/interfaces/gtk4/gtk4wsmenus.pp:273`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:340`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:389`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:441`
- GTK4 item setters: `lcl/interfaces/gtk4/gtk4wsmenus.pp:605`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:624`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:676`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:685`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:701`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:717`
- GTK4 popup path: `lcl/interfaces/gtk4/gtk4wsmenus.pp:829`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:869`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:907`
- GTK2 select/radio/popup references: `lcl/interfaces/gtk2/gtk2wsmenus.pp:245`, `lcl/interfaces/gtk2/gtk2wsmenus.pp:309`, `lcl/interfaces/gtk2/gtk2wsmenus.pp:575`
- Qt5 hover/popup references: `lcl/interfaces/qt5/qtwidgets.pas:16625`, `lcl/interfaces/qt5/qtwidgets.pas:16683`, `lcl/interfaces/qt5/qtwsmenus.pp:483`

## Validation Questions

Automated:

1. Do menu items receive GTK4 wrapper handles and unique action names?
2. Are normal, check, radio, disabled, hidden, and shortcut items represented by expected action/menu-item state?
3. Does `SetShortCut` set a nonempty `accel` GMenuItem attribute?
4. Does activating a normal GAction dispatch the LCL `OnClick`?
5. Does changing a check GAction state update LCL `Checked` and dispatch `OnClick`?
6. Does changing one radio GAction state uncheck same-group sibling radio items?

Manual:

1. Does the main menu visually show labels, shortcuts, disabled state, checks, radio state, hidden items, and icons?
2. Does hovering a menu item update `Application.Hint` / status hint behavior?
3. Does `TPopupMenu.Alignment` visibly affect popup location for `paLeft`, `paCenter`, and `paRight`?
4. Does popup location stay on-screen near monitor edges?
5. Do keyboard mnemonics and shortcuts activate items through normal user input?

## Focused Test Program

Created directory:

- `example_gtk4_menu_validation/`

The example should:

- create a main menu and popup menu with normal, check, radio, disabled, hidden, shortcut, and icon-capable items;
- force handle creation and log GTK4 action name, enabled state, state variant, and accel attribute;
- invoke GTK4 GAction activation/change-state paths directly in auto mode;
- log LCL click counts and radio/check state after each action;
- provide buttons to open left/center/right aligned popup menus in manual mode;
- keep the window open for manual hover/alignment/shortcut verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `MENU_VALIDATION_AUTO=1`: runs automated native-action checks and exits;
- `MENU_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_menu_validation/menu_validation.lpi
```

Build result:

- succeeded;
- compiled 350 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env MENU_VALIDATION_AUTO=1 ./example_gtk4_menu_validation/menu_validation
```

Runtime result:

- process exited with code 0 after the example was adjusted to avoid reading `Handle` from an invisible item;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- no exception was raised in the final auto run.

Observed native-action results:

| Item | Initial action state | Initial LCL state | After triggered action | After LCL state |
| --- | --- | --- | --- | --- |
| normal | `nil` | checked `False` | `nil` | checked `False`; click logged |
| shortcut | `nil`, accel `'<Control>n'` | shortcut `16462` | not triggered | unchanged |
| check | `false` | checked `False` | `true` after `g_action_change_state(True)` | checked `True`; click logged |
| radio1 | `true` | checked `True` | still `true` after radio2 action | checked `False` |
| radio2 | `false` | checked `False` | `true` after `g_action_change_state(True)` | checked `True`; click logged |
| disabled | `nil`, enabled `False` | enabled `False` | not triggered | unchanged |
| hidden | no handle | visible `False` | not triggered | unchanged |

Additional observations:

- Normal item GAction activation dispatched LCL `OnClick`.
- Check item GAction state change dispatched LCL `OnClick` and synchronized LCL `Checked=True`.
- Shortcut item had a nonempty GTK4 `accel` attribute: `'<Control>n'`.
- Disabled item had `action_enabled=False`, matching LCL `Enabled=False`.
- Hidden item had no allocated handle in the final auto path. The example was corrected to check `HandleAllocated` before reading `Handle`; directly reading a hidden item's `Handle` during the earlier run caused an `EDivByZero` exception in the validation program path.
- Radio item behavior confirms the source-level concern: after selecting radio2 through its GAction, LCL sibling state became correct (`radio1.Checked=False`, `radio2.Checked=True`), but GTK4 native action states became inconsistent (`radio1 action_state=true`, `radio2 action_state=true`). This shows GTK4 radio actions are independent boolean stateful actions, not a shared native radio group.

Interpretation:

- Basic GTK4 menu item handle creation, normal activation, check state activation, disabled state, and shortcut display attribute are usable in this focused action-level test.
- GTK4 radio group native state is not GTK2/Qt5-equivalent. LCL state is corrected by the LCL radio logic after activation, but native GAction state for the unchecked sibling remains stale. This can affect visual radio marks or future action-state-driven model rebuilds.
- Hidden item behavior should be treated carefully in future validation examples: use `HandleAllocated` before reading `Handle`.
- Popup alignment, hover/select hint behavior, shortcut key delivery from real keyboard input, and visual menu marks still require manual or screenshot-based validation.

## Clean Build Requirement

## Validation Re-run

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_menu_validation/menu_validation.lpi
```

Build result:

- succeeded on the current tree.

Runtime command:

```sh
xvfb-run -a env MENU_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_menu_validation/menu_validation
```

Runtime result:

- process exited with code 0;
- startup emitted the recurring `g_regex_match_full: assertion 'string != NULL' failed` warning;
- normal activation, check state change, disabled state, hidden no-handle behavior, and shortcut `accel='<Control>n'` matched the previous validation run;
- radio group native action state mismatch remains: after activating radio2, LCL state was `radio1.Checked=False`, `radio2.Checked=True`, but native action states were both `true`.

## Validation Run 2: Real Shortcut, Popup Events, and Hint Probe

Date: 2026-07-09

Purpose:

- Verify real key-event shortcut delivery separately from the stored
  `GMenuItem` `accel` attribute.
- Verify `TPopupMenu.OnPopup` / `OnClose` delivery through real button-triggered
  popup calls.
- Probe `Application.OnHint` while attempting menu and popup hover paths.
- This run does not modify GTK4 implementation code.

Example-only changes:

- Add popup open/close counters and log `Alignment`, `PopupPoint`, and whether
  `PopupComponent` is assigned.
- Add `Application.OnHint` logging.
- Dump click/hint/popup summary on close.

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_menu_validation/menu_validation.lpi
```

Build result:

- Succeeded.
- Hints only: unused `Sender` parameters.

Auto control run:

```sh
xvfb-run -a env MENU_VALIDATION_AUTO=1 GDK_BACKEND=x11 \
  ./example_gtk4_menu_validation/menu_validation
```

Auto control result:

- Existing action-level behavior remained unchanged.
- `popup_count=0`, `close_count=0`, and `hint_count=0` in auto mode.

No-key control run:

```sh
xvfb-run -a env MENU_VALIDATION_CLOSE_MS=900 GDK_BACKEND=x11 \
  ./example_gtk4_menu_validation/menu_validation
```

No-key result:

- `click_log_count=0`.

Real shortcut runs:

```sh
xvfb-run -a bash -lc 'env MENU_VALIDATION_CLOSE_MS=1800 GDK_BACKEND=x11 \
  ./example_gtk4_menu_validation/menu_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Menu validation"); \
  xdotool key --window "$wid" ctrl+n; wait $app'
```

Equivalent separated `keydown` / `keyup` sequences were also run.

Shortcut result:

- `Ctrl+N` did activate the shortcut item through real key input.
- In all tested Xvfb/xdotool shortcut sequences, one logical shortcut input
  produced two LCL click log entries for `&Shortcut`.
- Because this was measured with synthetic X input, treat it as a reproducible
  validation finding that still needs manual confirmation on a live desktop
  before editing shortcut handling.

Observed evidence:

```text
close summary popup_count=0 close_count=0 hint_count=0 last_hint= click_log_count=2
close summary click_log[0]=&Shortcut checked=False
close summary click_log[1]=&Shortcut checked=False
```

Popup event run:

```sh
xvfb-run -a bash -lc 'env MENU_VALIDATION_CLOSE_MS=6000 GDK_BACKEND=x11 \
  ./example_gtk4_menu_validation/menu_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Menu validation"); \
  xdotool mousemove --window "$wid" 72 60 click 1; \
  xdotool key --window "$wid" Escape; \
  xdotool mousemove --window "$wid" 186 60 click 1; \
  xdotool key --window "$wid" Escape; \
  xdotool mousemove --window "$wid" 320 60 click 1; \
  xdotool key --window "$wid" Escape; wait $app'
```

Popup event result:

- `OnPopup` and `OnClose` fired for all three popup buttons.
- The logged alignments were:
  - `Popup Left`: `alignment=0` (`paLeft`), `popup_point=200,220`;
  - `Popup Center`: `alignment=2` (`paCenter`), `popup_point=360,220`;
  - `Popup Right`: `alignment=1` (`paRight`), `popup_point=520,220`.
- This confirms LCL popup event delivery and requested alignment value storage.
- It does not prove GTK4 popup geometry correctness. The reviewed GTK4 popup
  source still sets a `1x1` anchor rectangle at the requested converted
  coordinate without using `TPopupMenu.Alignment`.

Observed evidence:

```text
EVENT OnPopup alignment=0 popup_point=200,220 component=False total=1
EVENT OnClose alignment=0 total=1
EVENT OnPopup alignment=2 popup_point=360,220 component=False total=2
EVENT OnClose alignment=2 total=2
EVENT OnPopup alignment=1 popup_point=520,220 component=False total=3
EVENT OnClose alignment=1 total=3
close summary popup_count=3 close_count=3 hint_count=0 last_hint= click_log_count=0
```

Hint probe:

- A main-menu hover probe using mouse and `Alt+F` did not produce
  `Application.OnHint`, but screenshots showed the submenu was not actually
  opened in that path. That run is not valid evidence for hover behavior.
- A `TPopupMenu` open/hover/Escape probe did produce `OnPopup` and `OnClose`,
  but no `Application.OnHint` events. The captured window image did not show
  the popover content because the GTK popover is not captured by `import
  -window` on the application X window in this setup.

Run 2 interpretation:

- Real shortcut delivery exists, but duplicate activation under Xvfb/xdotool is
  a new narrow validation concern.
- Popup event delivery is functional.
- Popup geometry remains a confirmed source-level gap rather than a measured
  geometry result: current GTK4 source does not apply `TPopupMenu.Alignment`.
- Hover/select hint behavior remains unconfirmed by runtime and still missing
  by GTK4 source comparison with GTK2/Qt5.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect main-menu/popup behavior.
4. If practical, run the same example under GTK2 and Qt5 for radio groups, hover hints, and popup alignment.
5. Re-test tray-icon popup menus if popup parent fallback is changed.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not claim popup alignment correctness from auto logs; it requires visual/manual or screenshot geometry validation.
- Do not infer hover hint support unless actual hover/select events update the LCL hint path.

## Implementation Fix (2026-07-10)

Scope: `lcl/interfaces/gtk4/gtk4widgets.pas` (menu item action state),
`lcl/interfaces/gtk4/gtk4wsmenus.pp` (popup alignment),
`lcl/interfaces/gtk4/gtk4bindings/lazgtk4_compat.pas` (one new binding);
example extended with a popup-point marker panel for screenshot geometry.
The prior menu surgery (fresh popover per Popup, no-rebuild-while-open
guard, focus save/restore) is untouched — both fixes operate purely on
GSimpleAction state and popover positioning, never on the GMenu model.

### Fix 1 — radio/check native state integrity (audit: radio `partial`)

Root cause chain (runtime-confirmed by this example pre-fix: after
activating radio2, BOTH radio actions read `true`):

- LCL `TMenuItem.TurnSiblingsOff` clears only the siblings' `FChecked`
  field and never calls WS `SetCheck` — gtk2 (`GtkRadioMenuItem`) and
  qt5 (`QActionGroup`) survive that through native grouping, which our
  per-item boolean `GSimpleAction`s do not have.
- `Gtk4MenuActionChangeState` blindly accepted GTK's proposed toggle, so
  a non-AutoCheck item's indicator could also drift from `Checked`.

Changes:

- `Gtk4MenuActionChangeState`: dispatch LM_ACTIVATE first (LCL Click
  applies AutoCheck before OnClick — menuitem.inc), then force the native
  state to `TMenuItem.Checked` (the LCL owns check state, gtk2 parity).
  `set_state` does not re-emit change-state, so no recursion. The action
  is g_object_ref'd across the dispatch (codex finding: the click can
  free the item, whose destructor unrefs the action — probing a freed
  GObject is itself UAF); the destructor clears the `lcl-menuitem` data
  first, which is the skip signal.
- `TGtk4MenuItem.SetCheck(True)` on a RadioItem syncs same-GroupIndex
  radio siblings' action states to false (mirrors TurnSiblingsOff at the
  native level). `ACheck=True`-only guard — no ping-pong.

Post-fix auto run: `radio1 action_state=false / radio2 action_state=true`
after switching; check/normal/disabled/hidden behavior and click_log
unchanged from baseline.

### Fix 2 — TPopupMenu.Alignment (audit: Popup `partial`)

Screenshot measurement (marker panel at the popup point) proved GtkPopover
CENTERS on the pointing-to rect: every popup behaved like paCenter.
Fix: measure the popover's contents (the popover itself is visible=FALSE
before popup() and gtk_widget_measure reports 0 for invisible widgets —
empirically confirmed; the contents child is GtkPopover's first child,
gtkpopover.c:926) and shift with the new `gtk4_popover_set_offset`
binding: +w/2 for paLeft (LCL default — menu opens right/below the
point), -w/2 for paRight, RTL swaps left/right (gtk2 GtkWS_Popup rule).
gtk2's vertical monitor clamp is not ported: GDK popup anchor hints
(FLIP_Y|SLIDE_X) already keep the surface visible, and a fixed-offset
probe confirmed set_offset takes effect at present time.

Post-fix screenshots: the marker lands exactly on the popover's top-left
corner (paLeft), top-center (paCenter), and top-right corner (paRight).

### Documented limitations (no code change)

- Hover/select hints stay `backend_limited`: GtkPopoverMenu's public API
  has only model/custom-child entry points (gtkpopovermenu.h) and the
  item widgets are private (`GtkModelButton`, gtkmodelbuttonprivate.h) —
  no public per-item select/hover signal exists in GTK 4.6. gtk2 hooks
  `GtkMenuItem::select`; qt5 hooks `QAction::hovered`.
- Radio items render with a CHECK mark, not a radio dot: boolean stateful
  actions map to GtkModelButton's toggle role; the radio role needs
  string-state + per-item target actions (a larger model redesign,
  possible follow-up).

Validation: gtk4 lcl / gtk2 lcl / gtk4 bigide builds clean; menu auto
run passes with the corrected radio states; alignment verified by
marker screenshots for all three alignments plus an offset probe.
Cross-review: codex confirmed the LCL click ordering (AutoCheck before
OnClick), no rebuild-path interaction, popover first-child structure and
fresh-popover lifetime, the hover-API claim against the local GTK source
— and found the action-lifetime issue fixed above.

Real-hardware checks: radio group switching from the menubar and from a
popup (reopen and check indicators); popup alignment for the three
values near window edges; non-AutoCheck check item keeps its indicator;
existing S77-80 behaviors (menu responsiveness, no lockups) unchanged.

## Fix 2 — radio items render a radio DOT (2026-07-10)

The documented follow-up ("radio items render with a CHECK mark, not a
radio dot") is done.

GTK rule (gtk-4.6.9 `gtkmenutrackeritem.c:339-349`): a menu item gets
ROLE_RADIO only when it carries a `target` AND its action is stateful,
with `toggled = (state == target)`; a boolean state without target renders
a CHECK mark. The old per-item BOOLEAN stateful actions therefore could
never produce a dot.

Change (`gtk4widgets.pas`), keeping per-item actions and LCL-driven
exclusivity — only the variant shape changes for radio items:

- Radio items get a STRING-state action (parameter type 's', state 'on'
  when checked, '' when not) and their GMenuItem carries a fixed target
  'on' via `g_menu_item_set_action_and_target_value`. Check items keep
  boolean state. Activation routing is unchanged: with only 'change-state'
  connected, `g_action_activate(action, 'on')` (what GtkMenuTracker sends)
  forwards to change-state, the LCL click runs, and the post-dispatch sync
  writes the LCL truth back.
- Codex finding hardened: `TMenuItem.RadioItem` can be flipped at runtime
  and the LCL setter changes sibling `FRadioItem` fields WITHOUT a WS call,
  so (a) the state-sync sites derive the variant type from the ACTION's
  actual state type (`Gtk4MenuCheckStateVariant`) instead of the LCL flag,
  and (b) `TGtk4WSMenuItem.SetRadioItem` (gtk4wsmenus.pp) now recreates the
  same-group siblings' handles too, giving them the matching action shape.
- The validation example's `TriggerAction` now activates radio actions
  with the real target parameter (the old boolean `change_state` would be
  type-mismatched and correctly rejected by GIO).

Runtime evidence: auto run — radio switch through the real activation path
flips both LCL and native states exclusively (`radio1='' / radio2='on'`),
check item unchanged (boolean `true`); SCREENSHOTS of the open File menu
show real radio dots (filled for the checked item, empty for the other)
that move after a real X11 click on "Radio Two" (`click_log[0]=Radio &Two
checked=True`); IDE main-menu smoke (File menu with icons/shortcuts/
separators) clean; toolbar dropdown suite, gtk2 and bigide builds clean.

Remaining known limitation in the same area (pre-existing, codex Low):
runtime `GroupIndex` changes still rely on LCL `TurnSiblingsOff`, which
mutates sibling `FChecked` without WS `SetCheck` — same LCL-driven model,
tracked as a follow-up if a real scenario surfaces. RESOLVED 2026-07-10 —
see "Fix 3" below.

## Fix 3 — runtime GroupIndex sibling indicator sync (2026-07-10)

The GroupIndex-change limitation noted above is fixed (GTK4-only, no
LCL-core change).

Reproduction (menu_validation groupmerge probe): radio1 checked in group 7,
radio2 checked alone in group 9, then `radio1.GroupIndex := 9` merges radio1
into radio2's group while checked. LCL `SetGroupIndex` runs `TurnSiblingsOff`
(clears radio2's `FChecked` directly, no WS `SetCheck`), then calls
`RegroupMenuItem` — which on GTK4 was a no-op. Pre-fix:
`groupmerge-after radio2 → action_state='on' checked=False` (stale native
'on' → two radio dots in group 9).

Fix: GTK4 `RegroupMenuItem` (gtk4winapi.inc) casts the item handle to
`TGtk4MenuItem` and calls the new `TGtk4MenuItem.SyncGroupToLCL`, which walks
the item's parent and sets every same-GroupIndex radio item's native action
state to its own LCL `Checked` (LCL already enforced exactly-one-checked, so
no sibling cascade — each item's own state is authoritative). Post-fix:
`groupmerge-after radio2 → action_state='' checked=False` (synced), radio1
stays `'on' checked=True`.

Validation: normal radio-switch path unchanged; IDE View menu
(icons/submenus/separators) renders correctly; menu + toolbar suites, gtk2
and bigide builds clean. Codex review: hndMenu validity, separator/nil-action
handling, Lock reentrancy, GroupIndex=0, and old-group correctness verified —
no findings; its minor style note (repeat the `is TGtk4MenuItem` guard inside
the sibling loop) applied.
