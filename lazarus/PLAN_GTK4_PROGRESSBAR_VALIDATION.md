# PLAN: GTK4 TProgressBar Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TCustomProgressBar` / `TProgressBar` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 4.8.

Primary source findings:

1. GTK4 has a real progress-bar backend: `TGtk4WSProgressBar` creates `TGtk4ProgressBar` and wires `ApplyChanges`, `SetPosition`, and `SetStyle`.
2. GTK4 maps `Position` to GTK fraction in the same broad way as GTK2: `(Position - Min) / (Max - Min)`.
3. GTK4 implements marquee by storing a style flag and adding a timeout that calls `GtkProgressBar.pulse`, similar in shape to GTK2.
4. GTK4 does not implement `Smooth`; the property is ignored in `ApplyChanges`. Qt5 also explicitly does not support `Smooth`; GTK2 maps it to discrete/continuous style.
5. GTK4 orientation mapping needs verification. `SetOrientation` maps `pbVertical` to GTK vertical plus `inverted=True`, while Qt5 maps `pbVertical` to vertical plus `inverted=False`. GTK2 maps `pbVertical` to `GTK_PROGRESS_BOTTOM_TO_TOP` and `pbTopDown` to `GTK_PROGRESS_TOP_TO_BOTTOM`.
6. `TGtk4ProgressBar.GetOrientation` appears internally inconsistent with `SetOrientation`: vertical plus `inverted=True` returns `pbTopDown`, while `SetOrientation(pbVertical)` sets that exact native state.
7. `TGtk4ProgressBar.GetPosition` returns `Round(GtkProgressBar.fraction)`, not a scaled LCL position. `TCustomProgressBar.GetPosition` returns `FPosition`, so this may be unused by public LCL `Position`, but it is still a backend quality concern if any GTK4 path reads the wrapper property.

Important source references:

- Baseline widgetset methods: `lcl/widgetset/wscomctrls.pp:198`, `lcl/widgetset/wscomctrls.pp:916`
- LCL progress-bar properties and setters: `lcl/comctrls.pp:1808`, `lcl/include/progressbar.inc:111`, `lcl/include/progressbar.inc:170`, `lcl/include/progressbar.inc:203`, `lcl/include/progressbar.inc:212`, `lcl/include/progressbar.inc:269`
- GTK4 widgetset methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:454`
- GTK4 wrapper methods: `lcl/interfaces/gtk4/gtk4widgets.pas:6269`, `lcl/interfaces/gtk4/gtk4widgets.pas:6293`, `lcl/interfaces/gtk4/gtk4widgets.pas:6314`, `lcl/interfaces/gtk4/gtk4widgets.pas:6333`, `lcl/interfaces/gtk4/gtk4widgets.pas:6368`, `lcl/interfaces/gtk4/gtk4widgets.pas:6405`
- GTK2 reference: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:471`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:528`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:562`
- Qt5 reference: `lcl/interfaces/qt5/qtwscomctrls.pp:456`, `lcl/interfaces/qt5/qtwscomctrls.pp:474`, `lcl/interfaces/qt5/qtwscomctrls.pp:528`

## Validation Questions

1. Does GTK4 build and run a focused `TProgressBar` example without exceptions?
2. Does native GTK fraction match LCL `Min`, `Max`, and `Position` after creation and after runtime updates?
3. Does `BarShowText` reach the native `GtkProgressBar.show_text` property?
4. Does each LCL orientation produce the expected GTK native orientation and inverted state?
5. Does `pbstMarquee` install an active pulse style state without breaking return to `pbstNormal`?
6. Does `Smooth=True/False` produce any observable native difference, or should it remain documented as unsupported for GTK4?

## Focused Test Program

Created directory:

- `example_gtk4_progressbar_validation/`

The example should:

- create horizontal, right-to-left, vertical, top-down, and marquee progress bars;
- set different positions and `BarShowText=True`;
- read native GTK4 wrapper state from `TGtk4ProgressBar.GetContainerWidget`;
- log native orientation, inverted flag, fraction, and show-text state;
- update position/style at runtime and log the native state again;
- stay open for manual visual verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `PROGRESSBAR_VALIDATION_AUTO=1`: runs automated native-state checks and exits;
- `PROGRESSBAR_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_progressbar_validation/progressbar_validation.lpi
```

Build result:

- succeeded;
- compiled 254 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env PROGRESSBAR_VALIDATION_AUTO=1 ./example_gtk4_progressbar_validation/progressbar_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- no exception was raised by the progress-bar test program.

Observed native-state results:

| Case | LCL orientation | LCL position | Native orientation | Native inverted | Native fraction | Wrapper orientation | Wrapper position |
| --- | --- | ---: | --- | --- | ---: | --- | ---: |
| horizontal initial | `pbHorizontal` | 25 | horizontal | `False` | 0.250 | `pbHorizontal` | 0 |
| right-to-left initial | `pbRightToLeft` | 50 | horizontal | `True` | 0.500 | `pbRightToLeft` | 0 |
| vertical initial | `pbVertical` | 70 | vertical | `True` | 0.700 | `pbTopDown` | 1 |
| top-down initial | `pbTopDown` | 70 | vertical | `False` | 0.700 | `pbVertical` | 1 |
| marquee initial | `pbHorizontal` | 0 | horizontal | `False` | 0.000 | `pbHorizontal` | 0 |
| horizontal updated | `pbHorizontal` | 40 | horizontal | `False` | 0.400 | `pbHorizontal` | 0 |
| right-to-left updated | `pbRightToLeft` | 60 | horizontal | `True` | 0.600 | `pbRightToLeft` | 1 |
| vertical updated | `pbVertical` | 80 | vertical | `True` | 0.800 | `pbTopDown` | 1 |
| top-down updated | `pbTopDown` | 80 | vertical | `False` | 0.800 | `pbVertical` | 1 |
| marquee switched to normal | `pbHorizontal` | 35 | horizontal | `False` | 0.350 | `pbHorizontal` | 0 |

Additional observations:

- Native GTK fraction matches LCL `Position / 100` for all normal-style cases. The GTK4 setter path for `Position` is therefore functional in this basic range.
- Native `show_text` was `True` for every bar, matching `BarShowText=True`.
- Runtime style switching from `pbstMarquee` to `pbstNormal` restored the normal fraction path and set the native fraction to 0.350 for `Position=35`.
- The wrapper `TGtk4ProgressBar.Position` getter returned `Round(fraction)`, producing only `0` or `1` for the tested fractional values. This confirms the source-level finding. It does not currently prove a public LCL `Position` bug because `TCustomProgressBar.GetPosition` returns `FPosition`.
- The wrapper `TGtk4ProgressBar.Orientation` getter reported `pbVertical` and `pbTopDown` reversed relative to the LCL property after `SetOrientation`. This confirms the source-level inconsistency between the GTK4 wrapper setter and getter.

Interpretation:

- The basic GTK4 `Position` setter, `BarShowText`, and normal-style fraction handling are usable in this test.
- `TGtk4ProgressBar.GetPosition` is not LCL-value equivalent and should be treated as a backend wrapper defect/risk, even if public `TProgressBar.Position` does not currently call it.
- `TGtk4ProgressBar.GetOrientation` is internally inconsistent with `SetOrientation` for vertical modes. Before a later fix, manually verify the visual direction expected by LCL for `pbVertical` and `pbTopDown` against GTK2/Qt5 so the setter, not just the getter, is corrected if needed.
- `Smooth=True` produced no logged native distinction. This remains unsupported/ignored in GTK4 and should be documented as a limitation unless a GTK4-compatible equivalent is identified.

## Validation Run 2: Range Edge Cases and Marquee State Data

Date: 2026-07-09

Purpose:

- Extend the focused runtime check beyond the original `0..100` range.
- Verify `BarShowText=False`.
- Inspect GTK4 object data used by the marquee timeout path.
- This run does not modify GTK4 implementation code.

Example-only changes:

- Log `Min` and `Max` with every bar.
- Log native object data keys `lclprogressbarstyle` and `timeout`.
- Add checks for:
  - non-zero range: `Min=-50 Max=50 Position=0`;
  - equal min/max: `Min=10 Max=10 Position=10`;
  - `BarShowText=False`;
  - switching marquee back to active after a normal-style interval.

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_progressbar_validation/progressbar_validation.lpi
```

Build result:

- Succeeded.
- Hints only:
  - pointer-to-integer conversion for validation-only `g_object_get_data` logging;
  - unused `Sender` parameters.

Runtime command:

```sh
xvfb-run -a env PROGRESSBAR_VALIDATION_AUTO=1 \
  ./example_gtk4_progressbar_validation/progressbar_validation
```

Runtime result:

- Process exited with code `0`.
- The same startup GLib warning appeared: `g_regex_match_full: assertion 'string != NULL' failed`.
- No exception was raised by the progress-bar test program.

Additional observed native-state results:

| Case | LCL state | Native result | Interpretation |
| --- | --- | --- | --- |
| `horizontal nonzero range` | `Min=-50 Max=50 Position=0` | `fraction=0.500` | GTK4 fraction calculation handles non-zero / negative range correctly. |
| `vertical equal minmax` | `Min=10 Max=10 Position=10` | `fraction=0.000` | GTK4 follows the guarded zero-denominator path. This matches the reviewed GTK2 calculation shape. |
| `rtl text hidden` | `BarShowText=False` | `native.show_text=False` | GTK4 `SetShowText` is functional for both true and false values. |
| `marquee initial` | `Style=pbstMarquee` | `native.styledata=1 native.timeout=14` | Marquee style installs style state and a timeout source. |
| `marquee normal` | `Style=pbstNormal` | `native.styledata=0 native.timeout=14` | Normal style clears the style flag but leaves the `timeout` object data value present. |
| `marquee active again` | `Style=pbstMarquee` | `native.styledata=1 native.timeout=189` | Re-entering marquee installs/replaces a timeout source. |

Observed evidence:

```text
horizontal nonzero range ... lcl.position=0 lcl.min=-50 lcl.max=50 ... native.fraction=0.500 ...
rtl text hidden ... lcl.text=False ... native.show_text=False ...
vertical equal minmax ... lcl.position=10 lcl.min=10 lcl.max=10 ... native.fraction=0.000 ...
marquee normal ... lcl.style=pbstNormal ... native.styledata=0 native.timeout=14 ...
marquee active again ... lcl.style=pbstMarquee ... native.styledata=1 native.timeout=189 ...
```

Run 2 interpretation:

- Normal progress fraction handling is stronger than the original run proved:
  non-zero ranges and equal `Min=Max` are handled in accordance with the source
  calculation.
- `BarShowText` is not just initialized correctly; runtime transition to
  `False` also reaches native GTK.
- The marquee implementation has a narrower lifecycle concern. It sets
  `lclprogressbarstyle=0` when switching to normal and the timeout callback
  then returns `False`, but the `timeout` object data value remains visible on
  the GTK object. A future implementation pass should decide whether this stale
  object data is harmless or should be cleared when leaving marquee style.
- This does not currently prove a user-visible marquee failure, but it is a
  concrete state-lifecycle cleanup candidate.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect horizontal, right-to-left, vertical, top-down, and marquee behavior.
4. If practical, run the same example under GTK2 and Qt5 for orientation comparison.
5. Re-test normal/marquee style switching, `BarShowText`, min/max/position clamping, and vertical orientation after any progress-bar change.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not claim a visual orientation bug from source mapping alone; confirm via native state and, where needed, manual visual inspection.
- Do not treat `Smooth` as a GTK4 regression unless GTK4 has a practical equivalent that GTK4 bindings expose.

## Implementation Fix (2026-07-10)

Scope: three hunks in `TGtk4ProgressBar` (`lcl/interfaces/gtk4/gtk4widgets.pas`).
All three defects were first confirmed by this example's native/wrapper
logging under Xvfb (pre-fix baseline), then fixed, then re-verified.

1. `GetOrientation` vertical branch was swapped. GTK4's own doc
   (gtkprogressbar.c, `set_inverted`): non-inverted bars grow top-to-bottom
   or left-to-right. `SetOrientation` was already correct
   (pbVertical → inverted=True, gtk2 `GTK_PROGRESS_BOTTOM_TO_TOP` parity);
   the getter returned pbTopDown for inverted vertical and vice versa.
   Post-fix: `lcl=pbVertical → wrapper=pbVertical`,
   `lcl=pbTopDown → wrapper=pbTopDown`; screenshot confirms bottom-up vs
   top-down growth visually.
2. `GetPosition` returned `Round(fraction)` (only 0/1). Now inverse of
   `SetPosition`: `Min + Round(fraction*(Max-Min))`. Post-fix log:
   50→50, 70→70, 35→35; nonzero range (-50..50, pos 0 → 0) and equal
   min/max (→ Min) exact. LCL-visible `Position` semantics unaffected
   (`TCustomProgressBar.GetPosition` reads `FPosition`).
3. Marquee stale timer id: switching pbstMarquee → pbstNormal left the
   dead g_timeout source id in the `'timeout'` object data (baseline log:
   `marquee normal ... native.timeout=14`), so the next marquee
   `set_data_full` — or widget destruction — ran `g_source_remove` on a
   stale id (GLib-CRITICAL). pbstNormal now clears the data
   (`g_object_set_data(..., 'timeout', nil)`), which fires the destroy
   notify while the source is still live → clean removal. Post-fix:
   `marquee normal ... native.timeout=0`, fresh timer on re-marquee, no
   Source-ID critical. Repeated pbstNormal with no timer is a no-op.

`Smooth` stays `backend_limited`: gtk4/gtkprogressbar.h has no
discrete/blocks API (gtk2's `GTK_PROGRESS_DISCRETE` is gone since GTK3);
qt5 documents the same limitation.

Validation: gtk4 lcl / gtk2 lcl / gtk4 bigide builds clean; auto run
passes all rows (orientation round-trips, position round-trips, marquee
normal/active-again transitions); screenshot confirms all four growth
directions and the marquee pulse block.

Cross-review: codex — no findings; confirmed no reader depended on the
old getter mapping, GLib replace-destroy semantics, no dual-pulse window
on repeated marquee, and the Smooth classification (gtk4 header check).

Real-hardware checks: vertical/top-down bars grow the right way with a
real theme; marquee animates and stops cleanly; no GLib-CRITICAL on
style toggling.
