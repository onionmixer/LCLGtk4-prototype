# GTK4 WSDialogs Runtime Validation

Rollback point: recorded in repository history before the broader LCL widgetset audit work; no implementation files are changed by this validation pass.

## Scope

This document tracks focused runtime validation for `lcl/widgetset/wsdialogs.pp` and GTK4 dialog lifecycle behavior.

The validation is observational only. It must not modify LCL-GTK4 implementation code.

## Source Review Targets

- Baseline dialog methods: `lcl/widgetset/wsdialogs.pp`.
- GTK4 common/file/color/font dialog implementations: `lcl/interfaces/gtk4/gtk4wsdialogs.pp`.
- GTK4 native file/color/font chooser wrappers: `lcl/interfaces/gtk4/gtk4widgets.pas`.
- GTK2 and Qt5 references: `lcl/interfaces/gtk2/gtk2wsdialogs.pp`, `lcl/interfaces/qt5/qtwsdialogs.pp`.

## Example

- Directory: `example_gtk4_wsdialogs_validation/`
- Project: `wsdialogs_validation.lpi`
- Program: `wsdialogs_validation.lpr`

The example opens these dialogs and uses a timer to send `Escape` through `/usr/bin/xdotool`:

1. `TOpenDialog`
2. `TSaveDialog`
3. `TSelectDirectoryDialog`
4. `TColorDialog`
5. `TFontDialog`
6. `TTaskDialog`

This checks modal lifecycle and cancel handling only. It does not validate accept/OK result data, file preview widgets, custom colors, font apply, or user-driven file selection.

The LCL dialog sequence also attaches an `OnCanClose` handler to Open, Save,
Select Directory, Color, and Font dialogs. The handler currently allows closing
and logs call counts. It deliberately does not veto file-dialog close in the
safe automated run because the GTK4 native file response has already closed the
native dialog by the time `TCommonDialog.DoExecute` calls `DoCanClose`; a veto
could leave the wait loop without a live native dialog to produce another
response.

When `WSDIALOGS_CANCLOSE_VETO_PROBE=1` is set, the example additionally checks
Color and Font dialog veto flow. The first `OnCanClose` call returns
`CanClose=False`, then repeated synthetic `Escape` input lets the second
`OnCanClose` call return `CanClose=True`.

When `WSDIALOGS_LCL_ACCEPT_PROBE=1` is set, the example additionally checks LCL
`TSaveDialog` and `TSelectDirectoryDialog` accept flow. It sends `Return` first
and only falls back to `Escape` if no response is produced.

When `WSDIALOGS_FILE_CANCLOSE_VETO_PROBE=1` is set, the example runs a guarded
GTK4 native file-dialog veto probe. This mode must be run under an external
`timeout`, because it intentionally checks a suspected wait-loop stall after a
native file dialog accept response is vetoed by `OnCanClose`.

When `WSDIALOGS_NATIVE_RESPONSE_PROBE=1` is set, the same program also opens raw
`GtkFileChooserNative` instances directly for Open, Save, and Select Folder and
logs the GTK `response_id` received from their native `response` signal. This is
an instrumentation path only; it bypasses the LCL dialog callback so the GTK
response can be compared with the LCL `Execute` result.

The raw native probe currently sends these UI stimuli:

- `Escape`
- `Alt+C` as a best-effort Cancel mnemonic stimulus
- `Return` as a best-effort accept stimulus after setting the relevant chooser state
- `Alt+O` / `Alt+S` as best-effort accept mnemonic stimuli based on the accept label
- coordinate-based best-effort clicks near the expected bottom-right accept and cancel button positions

The window-close stimulus is intentionally skipped by default. It is only enabled
with `WSDIALOGS_NATIVE_WINDOW_CLOSE_PROBE=1`, because the title-based
`xdotool windowclose` path produced a GDK/X11 `BadDrawable` process termination
under the current Xvfb environment.

## Commands

Build:

```sh
./lazbuild --ws=gtk4 example_gtk4_wsdialogs_validation/wsdialogs_validation.lpi
```

Auto run:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Auto run with raw native response probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_NATIVE_RESPONSE_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Auto run with Color/Font `OnCanClose` veto probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_CANCLOSE_VETO_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Auto run with LCL Save/SelectDirectory accept probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_LCL_ACCEPT_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Guarded native file-dialog `OnCanClose` veto probe:

```sh
xvfb-run -a timeout 35s env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_FILE_CANCLOSE_VETO_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Raw native response probe with explicit window-close automation:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_NATIVE_RESPONSE_PROBE=1 WSDIALOGS_NATIVE_WINDOW_CLOSE_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

The explicit window-close run is not part of the safe default validation because
it can terminate the process in the current Xvfb environment.

Manual run:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_CLOSE_MS=60000 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

## Result

Build/run date: 2026-07-09.

Build:

```sh
./lazbuild --ws=gtk4 example_gtk4_wsdialogs_validation/wsdialogs_validation.lpi
```

Result: succeeded.

Auto run:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result: completed without Pascal exception.

Auto run with raw native response probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_NATIVE_RESPONSE_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result: completed without Pascal exception.

Auto run with Color/Font `OnCanClose` veto probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_CANCLOSE_VETO_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result: completed without Pascal exception.

Auto run with LCL Save/SelectDirectory accept probe:

```sh
xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_LCL_ACCEPT_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result: completed without Pascal exception.

Guarded native file-dialog `OnCanClose` veto probe:

```sh
xvfb-run -a timeout 35s env WSDIALOGS_VALIDATION_AUTO=1 WSDIALOGS_FILE_CANCLOSE_VETO_PROBE=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result: timed out with exit code `124`.

Wayland environment check:

```sh
printf 'XDG_SESSION_TYPE=%s\nWAYLAND_DISPLAY=%s\nDISPLAY=%s\n' "$XDG_SESSION_TYPE" "$WAYLAND_DISPLAY" "$DISPLAY"
xvfb-run -a timeout 15s env WSDIALOGS_VALIDATION_AUTO=1 GDK_BACKEND=wayland example_gtk4_wsdialogs_validation/wsdialogs_validation
```

Result:

- Current shell reports `XDG_SESSION_TYPE=x11`, `WAYLAND_DISPLAY=` and `DISPLAY=:1`.
- `GDK_BACKEND=wayland` under Xvfb failed with `Gtk-WARNING **: cannot open display`.
- Wayland backend behavior is therefore not validated in this environment.

Portal environment check:

```sh
gdbus call --session --dest org.freedesktop.portal.Desktop --object-path /org/freedesktop/portal/desktop --method org.freedesktop.DBus.Properties.Get org.freedesktop.portal.FileChooser version
```

Result: `(<uint32 3>,)`.

The FileChooser portal service exists, but portal UI automation is not part of
the safe automated run. A portal file picker may be shown by the user desktop
session rather than the Xvfb display used by the validation harness.

Observed raw native response facts:

- Raw `GtkFileChooserNative` Open received synthetic `Escape` and emitted `response=-4`, `GTK_RESPONSE_DELETE_EVENT`.
- Raw `GtkFileChooserNative` Save received synthetic `Escape` and emitted `response=-4`, `GTK_RESPONSE_DELETE_EVENT`.
- Raw `GtkFileChooserNative` Select Folder received synthetic `Escape` and emitted `response=-4`, `GTK_RESPONSE_DELETE_EVENT`.
- Raw `GtkFileChooserNative` Save received `Return` after setting the proposed file name and emitted `response=-3`, `GTK_RESPONSE_ACCEPT`.
- Raw `GtkFileChooserNative` Select Folder received `Return` after setting the current directory as the selected file and emitted `response=-3`, `GTK_RESPONSE_ACCEPT`.
- Raw `GtkFileChooserNative` Open received `Return` after `gtk_file_chooser_set_file(...)=True`, but no response was emitted before timeout. This means the current automation did not validate the Open accept path.
- Raw `GtkFileChooserNative` Open, Save, and Select Folder received `Alt+C` best-effort Cancel mnemonic stimuli, but no response was emitted before timeout. This means the current automation did not validate the Cancel button path.
- Raw `GtkFileChooserNative` Open, Save, and Select Folder received accept mnemonic stimuli (`Alt+O` or `Alt+S`), but no response was emitted before timeout. This means mnemonic automation did not validate the accept button path.
- Raw `GtkFileChooserNative` Open, Save, and Select Folder received coordinate-based click stimuli near the expected accept button location, but no response was emitted before timeout.
- Raw `GtkFileChooserNative` Open, Save, and Select Folder received coordinate-based click stimuli near the expected cancel button location, but no response was emitted before timeout.
- The coordinate-click result does not prove native buttons are broken. It only proves the current Xvfb/xdotool coordinate heuristic did not reliably click the native dialog buttons.
- The safe default run logged `native-window-close-probe-skipped reason=requires-explicit-env`.
- The raw native probe emitted `GtkDialog mapped without a transient parent` warnings because the probe intentionally creates native dialogs without an LCL owner/transient parent. This warning is not part of the file-dialog result classification.

Unsafe raw native window-close finding:

- A title-search based `xdotool windowclose` attempt reached the dialog window but terminated the process with a GDK/X11 `BadDrawable` error under Xvfb.
- The earlier active-window based `xdotool getactivewindow windowclose` attempt did not reach the dialog because the Xvfb window manager reported no `_NET_ACTIVE_WINDOW` support.
- Therefore window-manager close button behavior remains unvalidated by safe automation and should be checked manually or with a different controlled GUI harness.

Observed runtime facts:

- `TOpenDialog` received one synthetic `Escape`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with `FileName=""`, `Files.Count=0`, `FilterIndex=1`.
- `TSaveDialog` received one synthetic `Escape`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with `FileName="/mnt/USERS/onion/DATA_ORIGN/Workspace/LCL_GTK4/lazarus/wsdialogs_validation_output.txt"`.
- `TSelectDirectoryDialog` received one synthetic `Escape`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with `FileName` equal to the initial working directory.
- `TColorDialog` received one synthetic `Escape`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=False`; the initial color value remained `255`.
- `TFontDialog` received one synthetic `Escape`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=False`; the initial font family/size/style were preserved.
- `TColorDialog` veto probe called `OnCanClose` twice: first `CanClose=False`, then `CanClose=True`; the dialog stayed open after the first Escape and returned `Execute=False` after the second Escape.
- `TFontDialog` veto probe called `OnCanClose` twice: first `CanClose=False`, then `CanClose=True`; the dialog stayed open after the first Escape and returned `Execute=False` after the next Escape.
- `TSaveDialog` accept probe received one `Return`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with `FileName="/mnt/USERS/onion/DATA_ORIGN/Workspace/LCL_GTK4/lazarus/wsdialogs_lcl_accept_probe.txt"`. No fallback Escape was needed.
- `TSelectDirectoryDialog` accept probe received one `Return`, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with `FileName` equal to the initial working directory. No fallback Escape was needed.
- `TOpenDialog` accept probe with a preselected existing file received three `Return` attempts with no response; fallback `Escape` then produced `Execute=True` with the preselected `FileName`, zero `Files`, and one `OnCanClose` call. This is not a confirmed accept path; it is the known Escape misclassification path after preselection.
- `TOpenDialog` multiselect accept probe with a preselected existing file received three `Return` attempts with no response; fallback `Escape` then produced `Execute=True` with empty `FileName`, zero `Files`, and one `OnCanClose` call. This is not a confirmed accept path.
- `TSaveDialog` overwrite probe created an existing target file, sent `Return` twice, called `OnCanClose` once with `CanClose=True`, and returned `Execute=True` with the existing filename. The second `Return` is consistent with accepting the overwrite confirmation path.
- Native file-dialog veto probe sent `Return` to `TSaveDialog`, received one `OnCanClose` call with `CanClose=False`, then further `Return`/`Escape` attempts produced X focus errors and no new response; the external timeout killed the process with exit code `124`.
- During `TFontDialog`, GTK emitted two warnings: `Failed to set property GtkEventControllerScroll.flags to ... Unknown flag`. The flag string was localized in the output.
- `TTaskDialog` received one synthetic `Escape` and returned `Execute=True` with `ModalResult=2`.
- The existing startup warning `g_regex_match_full: assertion 'string != NULL' failed` was emitted.

Source correlation for file-dialog cancel behavior:

- `Gtk4FileChooserResponseCB` in `lcl/interfaces/gtk4/gtk4wsdialogs.pp` only treats `arg1 = GTK_RESPONSE_CANCEL` as cancel.
- For all other response IDs, the callback proceeds to collect files and then sets `theDialog.UserChoice := mrOK`.
- The raw native response probe shows the tested Escape-close path arrives as `GTK_RESPONSE_DELETE_EVENT`, not `GTK_RESPONSE_CANCEL`.
- The raw native response probe shows confirmed accept paths arrive as `GTK_RESPONSE_ACCEPT` for Save and Select Folder.
- The LCL dialog run then maps the same Escape path to `Execute=True` for Open/Save/SelectDirectory because `GTK_RESPONSE_DELETE_EVENT` falls through the non-cancel branch.
- `OnCanClose` is not missing in the tested path. It is called once after the
  native response has been mapped to `UserChoice`; for file dialogs that means
  `OnCanClose` is called after the erroneous OK classification.

Current conclusion:

- Basic nonblocking modal lifecycle did not hang.
- GTK4 file dialogs have a confirmed cancel/close response classification problem in this Escape-close path.
- Save and Select Folder accept responses are confirmed as `GTK_RESPONSE_ACCEPT` in the current X11/Xvfb run.
- LCL `TSaveDialog` and `TSelectDirectoryDialog` accept flows are confirmed with `Return`: both return `Execute=True` and call `OnCanClose` once.
- LCL `TSaveDialog` overwrite accept flow is confirmed in the automated run.
- File-dialog `OnCanClose=False` veto-flow is confirmed unsafe in the current GTK4 native-file-dialog path: after veto, the dialog does not produce another response and the run times out.
- Open accept, Open multiselect accept, Cancel button, accept-button mnemonic, coordinate-click button automation, window-manager close button responses, Wayland backend behavior, and portal UI behavior remain unconfirmed by safe automation.
- `OnCanClose` allow-flow is confirmed for Open, Save, Select Directory, Color,
  and Font in the Escape run. Veto-flow remains intentionally untested in safe
  automation for GTK4 native file dialogs.
- `OnCanClose` veto-flow is confirmed for GTK4 Color and Font dialogs in the
  current X11/Xvfb run.
- Color and Font dialogs handled Escape as cancel in this focused run.
- The test does not validate reliable direct Cancel/accept button clicks, window-manager close button clicks, Open accept, real multi-select item selection, filters after user change, preview controls, custom colors, or font apply/preview.

## Implementation Fix (2026-07-10)

Scope: the two runtime-proven file-dialog defects only. Preview/history/help
absence stays a documented `GtkFileChooserNative` backend limitation; font
apply/preview and underline/strikeout parity remain documented follow-ups.

Changes (`lcl/interfaces/gtk4/gtk4wsdialogs.pp`):

1. `Gtk4FileChooserResponseCB` — response classification. GTK 4.6.9 emits
   exactly three responses for `GtkFileChooserNative`
   (`gtkfilechoosernative.c:151-153`, portal path
   `gtkfilechoosernativeportal.c:167-174`): `GTK_RESPONSE_ACCEPT`,
   `GTK_RESPONSE_CANCEL`, `GTK_RESPONSE_DELETE_EVENT`. The old code mapped
   only `CANCEL` to cancel and turned `DELETE_EVENT` (Escape/window close)
   into a false OK. Now anything that is not `GTK_RESPONSE_ACCEPT` /
   `GTK_RESPONSE_OK` is cancel.
2. `TGtk4WSCommonDialog.ShowModal`, `TGtk4FileDialog` branch — veto stall.
   `GtkFileChooserNative` hides itself after emitting `response`, but
   `TCommonDialog.DoExecute`'s veto flow assumed the dialog outlives the
   check: `OnCanClose=False` reset `UserChoice` to `mrNone` and pumped for a
   response that could never arrive (runtime-proven stall, exit code 124).
   `ShowModal` now runs the wait loop itself for the native file-dialog
   branch: on accept it calls the public `TCommonDialog.DoCanClose`; a veto
   resets `UserChoice` and re-presents the still-live native dialog with
   `gtk_native_dialog_show` (re-show after response is legal:
   `gtknativedialog.c` clears visibility before emitting `response`).
   Handshake with LCL core: our `DoCanClose` call sets `FDoCanCloseCalled`,
   so `DoExecute` skips its own loop on the accept path (no double
   `OnCanClose` — runtime-confirmed exactly one call per accept attempt);
   the cancel path never calls `DoCanClose` here, so `DoExecute` keeps its
   standard cancel bookkeeping. Guards: loop exits on
   `Application.Terminated` / handle destruction, and `Dlg` is re-acquired
   after `DoCanClose` because user code may call `Close` (codex finding).

### Validation Run 2 (post-fix, 2026-07-10)

- Builds: LCL gtk4, gtk2 regression, bigide — all 0 errors.
- Escape run: Open/Save/SelectDirectory now return `Execute=False` with
  `canclose-count=0` (VCL semantics: `OnCanClose` fires only for accepted
  dialogs); Color/Font unchanged (`False`).
- LCL accept probe: Save / Save-overwrite / SelectDirectory still
  `Execute=True` with exactly one `OnCanClose` call each. Open `Return`
  stimulus remains unanswered at the raw-GTK level (pre-existing harness
  limitation, unrelated to the fix); its trailing Escape now correctly
  yields `False` — the pre-fix `True` for this path was the misclassified
  Escape, not a real accept.
- Guarded file veto probe (previously stalled until killed): now completes —
  first accept vetoed (`CanClose=False`) → dialog re-presented → second
  accept allowed → `Execute=True`, `canclose-count=2`, probe end + `DONE`.
- Color/Font veto probe (GtkDialog path, untouched): unchanged, still passes.
- Codex adversarial review: response-code completeness, re-show legality,
  `FDoCanCloseCalled` handshake, and reentrancy verified clean; one Medium
  finding (stale `Dlg` if `OnCanClose` calls `Close`) fixed with re-validate
  + re-acquire before the re-show.

Remaining (unchanged by this fix): Open accept via real button click,
Wayland/portal behavior, preview/history/help absence UX, font
apply/preview, color options — see the pre-fix conclusion list above.

## Implementation Fix — FontDialog PreviewText (2026-07-10)

Audit §7.4 follow-up. `TGtk4FontSelectionDialog.InitializeWidget` now applies
`TFontDialog.PreviewText` to the GtkFontChooserDialog via
`gtk_font_chooser_set_preview_text`, mirroring GTK2 (set only when non-empty so
GTK's localized default sample is kept otherwise). The GtkFontChooser preview
entry still ships in GTK 4.6.

`fdApplyButton` is left unimplemented with a source comment: GTK4
GtkFontChooserDialog has no apply button (removed by GTK), so the option has no
native counterpart — documented backend limitation, not a stub.

### Validation

The example sets `PreviewText='LCL Preview 0123'`; a timer reads
`gtk_font_chooser_get_preview_text` back while the dialog is modal:
`font-preview-probe lcl="LCL Preview 0123" native="LCL Preview 0123" match=True`.
A screenshot of the open dialog shows the custom sample in the preview entry
(rendered in the selected font). Full wsdialogs auto suite (6 dialog results),
the guarded file-veto probe, and gtk2 + bigide builds are clean. Codex review:
binding signature, GtkFontChooser cast, PGChar lifetime (GTK g_strdups the
value), and empty-string GTK2 parity verified; its one Low finding (the probe
leaked the transfer-full get_preview_text result) fixed with g_free.

## Font underline/strikeout — backend limitation (documented 2026-07-10)

Classified `backend_limited`, not a fix candidate. `GtkFontChooser` exposes
no underline/strikeout controls, and the `PangoFontDescription` it returns
has no such fields: underline and strikeout are Pango TEXT attributes
(`PangoAttribute`), not font-description properties, so there is nothing to
read back from the chooser. Qt5 can map them only because `QFontDialog`'s
`QFont` carries `underline`/`strikeOut`. The GTK4 `response_handler`
preserves the incoming `TFont` state (`fsUnderline`/`fsStrikeOut` survive the
dialog round-trip), which is the correct behavior given the limitation. A
real fix would require replacing GtkFontChooserDialog with a custom chooser
UI that adds the two toggles — out of scope for the widgetset. Source comment
updated at `TGtk4FontSelectionDialog.response_handler`.
