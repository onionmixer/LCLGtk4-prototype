# PLAN: GTK4 Standard Button Controls Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TStaticText`, `TButton`, `TCheckBox`, `TToggleBox`, and `TRadioButton` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 22.8.

Primary source findings:

1. GTK4 implements these controls with real wrappers: `TGtk4StaticText`, `TGtk4Button`, `TGtk4CheckBox`, `TGtk4ToggleButton`, and `TGtk4RadioButton`.
2. `TStaticText.SetStaticBorderStyle` calls `TGtk4StaticText.SetStaticBorderStyle`, but the GTK4 wrapper setter is empty because GTK4 removed `GtkFrame.set_shadow_type`.
3. `TButton.SetDefault` only calls `set_can_default`; it does not prove active default/grab-default behavior.
4. Widget-level shortcuts are intentionally disabled by `GTK4_ENABLE_WIDGET_SHORTCUTS = False`, so `TButton.ShortCut`, checkbox shortcuts, and radio shortcuts should not be considered GTK4-active without changing that constant.
5. `TCheckBox` supports checked/unchecked/grayed through GTK4 check-button active/inconsistent state.
6. `TToggleBox` maps `cbGrayed` to checked because `GtkToggleButton` has no tri-state.
7. `TRadioButton` grouping is implemented by joining an existing sibling or a `TRadioGroup` radio button, but dynamic grouping/order cases need runtime validation.

Important source references:

- Baseline methods: `lcl/widgetset/wsstdctrls.pp:206`, `lcl/widgetset/wsstdctrls.pp:226`
- GTK4 shortcut disabled constant/helper: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:330`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:347`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:379`
- GTK4 static text methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1526`, `lcl/interfaces/gtk4/gtk4widgets.pas:6190`, `lcl/interfaces/gtk4/gtk4widgets.pas:6232`
- GTK4 button default/shortcut methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1562`, `lcl/interfaces/gtk4/gtk4widgets.pas:10884`
- GTK4 checkbox methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1602`, `lcl/interfaces/gtk4/gtk4widgets.pas:10923`
- GTK4 toggle grayed mapping: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:488`
- GTK4 radio grouping: `lcl/interfaces/gtk4/gtk4widgets.pas:10992`
- GTK2 button/default/radio references: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2605`, `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2811`
- Qt5 button/default/radio references: `lcl/interfaces/qt5/qtwsstdctrls.pp:1173`, `lcl/interfaces/qt5/qtwsstdctrls.pp:1305`

## Validation Questions

1. Does GTK4 build and run a focused standard-button example without exceptions?
2. Does `TStaticText.BorderStyle` change the native/static wrapper state?
3. Does `TButton.Default=True` reach native `can_default` state?
4. Does `TCheckBox.State=cbGrayed` reach native wrapper state as grayed?
5. Does `TToggleBox.State=cbGrayed` become checked, confirming the documented backend limitation?
6. Do sibling `TRadioButton` controls uncheck each other after programmatic and click-like state changes?
7. Does a `TRadioGroup` item selection stay coherent with the hidden/internal radio-button implementation?
8. Are widget shortcuts still source-disabled?

## Focused Test Program

Created directory:

- `example_gtk4_stdctrls_validation/`

The example should:

- create a static text, default button, checkbox, toggle box, sibling radio buttons, and radio group;
- log native `GtkWidget.can_default`, static border style, checkbox/toggle/radio states, and LCL states;
- toggle/check/radio controls programmatically and through `Click` where practical;
- keep the window open for manual shortcut/default-button visual verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `STDCTRLS_VALIDATION_AUTO=1`: runs automated state checks and exits;
- `STDCTRLS_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_stdctrls_validation/stdctrls_validation.lpi
```

Build result:

- succeeded;
- compiled 243 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env STDCTRLS_VALIDATION_AUTO=1 ./example_gtk4_stdctrls_validation/stdctrls_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- GTK critical warnings were printed during startup:
  - `gtk_widget_set_direction: assertion 'GTK_IS_WIDGET (widget)' failed`
  - `gtk_widget_get_size_request: assertion 'GTK_IS_WIDGET (widget)' failed`
  - `gtk_widget_set_size_request: assertion 'GTK_IS_WIDGET (widget)' failed`
- no exception was raised by the validation program.

Observed state results:

| Case | Static LCL/native | Button default/native | Check LCL/native | Toggle LCL/native | Radio1 LCL/native | Radio2 LCL/native | RadioGroup |
| --- | --- | --- | --- | --- | --- | --- | --- |
| initial | `sbsNone` / `sbsNone` | `True` / `False` | `cbGrayed` / `cbGrayed` | `cbChecked` / active `True` | `True` / `cbChecked` | `False` / `cbUnchecked` | 0 |
| after programmatic changes | `sbsSingle` / `sbsNone` | `True` / `False` | `cbGrayed` / `cbGrayed` | `cbChecked` / active `True` | `True` / `cbChecked` | `True` / `cbChecked` | 1 |
| after second changes | `sbsSingle` / `sbsNone` | `True` / `False` | `cbGrayed` / `cbGrayed` | `cbUnchecked` / active `False` | `True` / `cbChecked` | `True` / `cbChecked` | -1 |

Additional observations:

- `TStaticText.BorderStyle := sbsSingle` changed the LCL property, but GTK4 wrapper/native state remained `sbsNone`. This confirms the source-level no-op setter.
- `TButton.Default=True` did not result in native `GtkWidget.can_default=True` in this run. This is stronger than the initial source concern: the intended GTK4 setter path did not produce the queried native state.
- The GTK4 binding method for `TGtkWidget.set_can_default` should be rechecked before any fix plan, because the reviewed generated binding output suggests it may call the wrong GTK function.
- `TCheckBox.State := cbChecked` after an initial `cbGrayed` state still reported `cbGrayed`. Source review explains the likely cause: `TGtk4CheckBox.SetState` sets `inconsistent=True` for `cbGrayed`, but does not explicitly clear inconsistent when switching to checked/unchecked.
- `TToggleBox.State := cbGrayed` was reported by LCL as `cbChecked` and native active `True`, confirming the documented backend limitation.
- Programmatically setting `FRadio2.Checked := True` left both sibling radio buttons checked (`radio1=True`, `radio2=True`) at LCL and native levels in this test. This shows sibling radio grouping is not reliable for the tested programmatic path.
- `TRadioGroup.ItemIndex := -1` completed, but startup GTK criticals suggest the hidden/internal radio path still needs focused investigation. The criticals are likely related to a widget-less hidden radio or related control during group setup, but this is an inference and must be verified before planning a fix.
- Widget shortcuts remain source-disabled: `GTK4_ENABLE_WIDGET_SHORTCUTS = False`.

Interpretation:

- StaticText border style is confirmed backend-limited/no-op.
- Default button native state is not confirmed usable; current runtime evidence shows native `can_default=False`.
- Checkbox grayed-to-checked/unchecked transitions are likely defective because native inconsistent state is not cleared.
- ToggleBox grayed behavior is confirmed as backend-limited and maps to checked.
- RadioButton grouping requires a dedicated follow-up validation because this run shows both sibling radios can remain checked after programmatic changes.
- The GTK critical warnings should be treated as real evidence and investigated with a narrower RadioGroup/hidden-radio example before implementation work.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect static borders, default button visuals, shortcuts, tri-state checkbox, toggle grayed behavior, and radio grouping.
4. If practical, run the same example under GTK2 and Qt5 for default button, shortcut, and radio grouping comparison.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not treat shortcut behavior as runtime-tested unless `GTK4_ENABLE_WIDGET_SHORTCUTS` changes or key input is explicitly tested.
- Do not assume `can_default=True` means active default button behavior; visual/default activation still needs manual key tests.

## Implementation Fix (2026-07-10)

1. `TGtk4Button.SetDefault` focusability trap: GTK4 removed can-default
   and the binding's `set_can_default` helper redirects to
   `set_can_focus`. LCL `WSSetDefault` passes the runtime active-default
   (`FActive`), so whenever another control became the active default the
   Default button received `SetDefault(False)` → `can_focus(False)` and
   dropped out of the tab order until it regained active-default. Now
   maps to `set_receives_default` (the real GTK4 property, no focus side
   effects). Return-key activation stays LCL-driven
   (`TApplication.DoReturnKey` / `TCustomForm.DefaultControl`) — gtk2
   parity, whose own native `grab_default` call is commented out.
   Runtime: `Default=True → native receives_default=True` (the example
   probe previously read the binding's `get_can_default`, a
   constant-False stub — probe fixed too).
2. Radio grouping was dead: `TGtkRadioButton.join_group` in lazgtk4.pas
   is an EMPTY STUB, so gtk4 radio buttons were never natively grouped —
   runtime-confirmed: programmatic `radio2.Checked := True` left BOTH
   radios checked (LCL and native). Added the
   `gtk4_check_button_set_group` binding (symbol nm-verified in
   libgtk-4) and `TGtk4RadioButton.CreateWidget` now joins the group
   through it for both the TRadioGroup and sibling-scan paths.
   Runtime post-fix: both switch directions fully exclusive, native and
   LCL in sync. Cross-review verified GTK4 grouped check buttons CAN be
   fully deselected programmatically, so `TRadioGroup.ItemIndex := -1`
   keeps working.
3. Hardening: the `HiddenRadioButton` early-exit left
   `CreateWidget`'s Result UNINITIALIZED; now `Result := nil` (defined
   behavior; skip paths and destruction handle nil).

Documented (no code change):

- `GTK4_ENABLE_WIDGET_SHORTCUTS = False` stays intentional: the LCL
  processes `TShortCut` itself; enabling GTK widget-level shortcuts
  would double-activate.
- The three `Gtk-CRITICAL` lines at TRadioGroup creation are attributed
  to the HiddenRadioButton nil-widget path (LCL applies
  direction/size-request to a nil native widget). Pre-existing noise,
  now defined-safe. Proper fix — a gtk2-style REAL hidden grouped
  widget — changes ItemIndex=-1 native semantics and is deferred as its
  own follow-up item with TRadioGroup native-state validation.

## Implementation Fix 2 — HiddenRadioButton real widget (2026-07-10)

The deferred follow-up above ("gtk2-style REAL hidden widget") is done.

Root cause of the three `Gtk-CRITICAL` lines at every TRadioGroup creation:
the HiddenRadioButton (LCL's ItemIndex=-1 helper, created with Visible=False
and forced `HandleNeeded`) got a NIL native widget by special-case, and the
generic WS calls that follow handle creation (`SetBiDiMode` set_direction,
`ConstraintsChange` get/set_size_request) ran against the nil GtkWidget
(gdb-confirmed at gtk4wscontrols.pp:494 and :359-362).

Changes (`gtk4widgets.pas`):

1. The hidden button now gets a REAL GtkCheckButton like every radio; the
   nil special-case and the `TGtk4RadioButton.InitializeWidget` early-exit
   override were removed. It deliberately stays OUT of the native
   check-button group — LCL drives every button's checked state explicitly
   (ItemIndex=-1 was already runtime-proven without a native group member),
   and an ungrouped hidden avoids a stale native group after TRadioGroup
   rebuilds its items. Per codex review, it is excluded both as a JOINER
   and as the group ANCHOR: after `Items.Clear` + re-Add the hidden can
   temporarily be `Controls[0]`, so the anchor is now the first REAL item
   button found by scan.
2. `TGtk4Widget.InitializeWidget` no longer leaves widgets shown when the
   LCL control is invisible: GTK4 widgets default to visible and LCL sends
   no ShowHide for a control whose showing state never changes, so the
   now-real hidden button initially PAINTED OVER the first radio item
   (screenshot-verified). After `show`, the widget is hidden again when
   `not LCLObject.IsControlVisible`. A first attempt used
   `HandleObjectShouldBeVisible` — wrong: it walks the parent chain, hid
   every pre-show child, and stormed `gtk_widget_measure 'for_size >= -1'`
   criticals during pre-show layout (also runtime-measured); the control's
   OWN flag (`IsControlVisible`) is the correct predicate, and it keeps
   design-time display intact (returns True under csDesigning unless
   csNoDesignVisible — which the hidden button has).

Validation (all on the final build): stdctrls suite — ZERO criticals
(was 3), RadioGroup semantics identical across ItemIndex 0→1→-1 with
per-child native logging (hidden at -1: `active=True visible=False`), a
new Items.Clear/re-Add rebuild scenario keeps native exclusivity in both
directions and the hidden stays invisible/ungrouped; screenshot confirms
no "HiddenRa..." overlay (the real-widget regression during development
was caught visually and fixed); wsextctrls suite 0 criticals after
rebuild; 43-step wscontrols suite (hidden-panel show/hide cases), toolbar
suite, gtk2 + bigide builds, and IDE startup smoke all clean. Codex
review: visibility flow, design-time behavior, toggled-signal isolation
and LCL hidden-state bookkeeping verified; its Medium finding (rebuild
group anchor) fixed and covered by the new scenario.
