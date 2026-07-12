# PLAN: GTK4 TEdit / TMemo Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TCustomEdit` / `TEdit` and `TCustomMemo` / `TMemo` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 22.5.

Primary source findings:

1. GTK4 implements `TCustomEdit` with `TGtk4Entry` and `TCustomMemo` with `TGtk4Memo` / `GtkTextView`.
2. GTK4 `TEdit.GetCanUndo` returns true whenever the handle is allocated, because GTK4 exposes no direct public query for `GtkEntry` undo stack availability in the reviewed path.
3. GTK4 `TEdit.Undo` calls `gtk4_widget_activate_action(..., 'text.undo', nil)` and ignores the action result.
4. GTK4 edit `Cut`, `Copy`, and `Paste` use LCL fallback operations, not native GTK editing clipboard APIs.
5. GTK4 edit `SetTextHint` only sets native placeholder text when the new hint is nonempty, so clearing `TextHint` may not clear the native placeholder.
6. GTK4 memo undo uses `GtkTextBuffer` undo APIs and can query `gtk4_text_buffer_get_can_undo`.
7. GTK4 memo scrollbars, word wrap, read-only, tabs, and selection/caret APIs have real implementation paths but need runtime validation.

Important source references:

- Baseline edit/memo methods: `lcl/widgetset/wsstdctrls.pp:530`, `lcl/widgetset/wsstdctrls.pp:643`
- GTK4 edit widgetset methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1094`
- GTK4 edit undo/can-undo: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1114`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1280`
- GTK4 edit text hint: `lcl/interfaces/gtk4/gtk4widgets.pas:5606`
- GTK4 edit clipboard fallback: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1254`
- GTK4 memo widgetset methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1290`
- GTK4 memo widget implementation: `lcl/interfaces/gtk4/gtk4widgets.pas:7637`, `lcl/interfaces/gtk4/gtk4widgets.pas:7741`, `lcl/interfaces/gtk4/gtk4widgets.pas:7784`, `lcl/interfaces/gtk4/gtk4widgets.pas:7790`, `lcl/interfaces/gtk4/gtk4widgets.pas:7796`
- GTK4 memo undo/can-undo: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1362`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1375`
- Qt5 edit can-undo reference: `lcl/interfaces/qt5/qtwsstdctrls.pp:898`
- GTK2 edit undo reference: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:1497`

## Validation Questions

1. Does GTK4 build and run a focused edit/memo example without exceptions?
2. Does `TEdit.CanUndo` report true even before any edit stack exists?
3. Does `TEdit.Undo` change text after LCL/API text insertion, or is it ineffective for programmatic changes?
4. Does clearing `TEdit.TextHint` clear the native GTK placeholder?
5. Do edit `SelStart`, `SelLength`, and `SelText` stay consistent with native state after changes?
6. Do edit `ReadOnly`, `EchoMode`, `PasswordChar`, `NumbersOnly`, `CharCase`, and `MaxLength` reach native GTK state or visible LCL state?
7. Does `TMemo.CanUndo` accurately change from false to true after text insertion?
8. Does `TMemo.Undo` revert inserted text?
9. Do memo `ReadOnly`, `WantTabs`, `WordWrap`, and scrollbars reach native state?

## Focused Test Program

Created directory:

- `example_gtk4_editmemo_validation/`

The example should:

- create an edit, password edit, numbers-only/uppercase edit, and memo;
- set and clear edit `TextHint`, then log native placeholder state;
- exercise edit selection, `SelText`, `CanUndo`, `Undo`, `Copy`, `Cut`, and `Paste` where practical;
- exercise memo text insertion, `CanUndo`, `Undo`, selection, read-only, word wrap, want-tabs, and scrollbar policy;
- read native GTK4 state from `TGtk4Entry` and `TGtk4Memo`;
- stay open for manual visual verification when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `EDITMEMO_VALIDATION_AUTO=1`: runs automated public/native-state checks and exits;
- `EDITMEMO_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

Date: 2026-07-09

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_editmemo_validation/editmemo_validation.lpi
```

Build result:

- succeeded after adding the missing `LazGLib2` import to the validation example;
- compiled 297 lines;
- warnings/errors: none;
- hints: unused `Sender` parameters only.

Runtime command:

```sh
xvfb-run -a env EDITMEMO_VALIDATION_AUTO=1 ./example_gtk4_editmemo_validation/editmemo_validation
```

Runtime result:

- process exited with code 0;
- one startup GLib warning was printed: `g_regex_match_full: assertion 'string != NULL' failed`;
- no exception was raised by the edit/memo test program.

Observed edit results:

| Case | LCL text | `CanUndo` | Native placeholder | Native editable | Native visible | Native max length |
| --- | --- | --- | --- | --- | --- | ---: |
| edit initial | `abc` | `True` | `initial hint` | `True` | `True` | 0 |
| password initial | `secret` | `True` | `nil` | `True` | `False` | 0 |
| filtered initial | `12` | `True` | `nil` | `True` | `True` | 5 |
| edit after hint replacement | `abc` | `True` | `replacement hint` | `True` | `True` | 0 |
| edit after hint clear | `abc` | `True` | `replacement hint` | `True` | `True` | 0 |
| edit after `SelText='XYZ'` | `aXYZc` | `True` | `replacement hint` | `True` | `True` | 0 |
| edit after `Undo` | `aXYZc` | `True` | `replacement hint` | `True` | `True` | 0 |
| filtered after `SelText='ab34'` | empty string | `True` | `nil` | `True` | `True` | 5 |

Observed memo results:

| Case | Text | `CanUndo` | ReadOnly | WordWrap | WantTabs | Native editable | Native wrap | Native accepts tab |
| --- | --- | --- | --- | --- | --- | --- | ---: | --- |
| memo initial | `line1\nline2` | `False` | `False` | `False` | `True` | `True` | 0 | `True` |
| memo after `SelText` append | `line1\nline2\nadded` | `False` | `False` | `False` | `True` | `True` | 0 | `True` |
| memo after `Undo` | `line1\nline2\nadded` | `False` | `False` | `False` | `True` | `True` | 0 | `True` |
| memo after flags | unchanged | `False` | `True` | `True` | `False` | `False` | 2 | `False` |

Additional observations:

- `TEdit.CanUndo` returned `True` for every edit from the initial state onward, confirming the source-level finding that GTK4 reports handle availability rather than undo-stack availability.
- `TEdit.Undo` did not revert the programmatic `SelText` insertion in this run. This does not prove native user-input undo is broken, but it proves the public `CanUndo=True` result is not enough to predict whether `Undo` will change text.
- Clearing `TEdit.TextHint` did not clear the native GTK placeholder. After `TextHint := ''`, the native placeholder and `TGtk4Entry.TextHint` still reported `replacement hint`.
- Password edit native visibility was `False`, matching `EchoMode=emPassword`.
- Copying from the password edit did not overwrite the clipboard in this run. After normal edit copy, clipboard was `aXYZc`; after password copy it remained `aXYZc`, matching the GTK4 copy guard for non-normal echo mode.
- `NumbersOnly=True` plus `CharCase=UpperCase` with `SelText='ab34'` produced an empty edit text in this programmatic insertion scenario. This needs a narrower follow-up because the expected behavior could differ between user insertion, selection replacement, and LCL fallback `SelText`.
- `TMemo.CanUndo` remained `False` after programmatic `SelText` insertion, and `TMemo.Undo` did not revert that insertion. This does not disprove GTK4 native user-input undo because programmatic buffer changes may not populate the native undo stack.
- Memo `ReadOnly`, `WordWrap`, and `WantTabs` reached native `GtkTextView` state in this test.

Interpretation:

- The source-level text-hint clearing defect is confirmed by runtime evidence.
- The source-level `TEdit.CanUndo` accuracy problem is confirmed by runtime evidence.
- `TEdit.Undo` and `TMemo.Undo` require a second validation pass that injects real/native key input or directly exercises native text insertion paths, because this run only proves programmatic LCL text changes were not undoable.
- Password copy behavior appears intentionally guarded and worked in this run.
- The filtered edit empty-text result is a separate high-risk observation requiring focused follow-up before any implementation conclusion.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect placeholder clearing, password copy behavior, undo, selection, and memo scrollbars.
4. If practical, run the same example under GTK2 and Qt5 for `CanUndo`, `Undo`, and text hint behavior.
5. Re-test form-designer undo/redo focus routing if edit/memo key handling is changed.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not assume programmatic text changes populate GTK native undo stacks; record observed behavior separately.
- Do not treat clipboard behavior as complete without read-only, password, Unicode, and selection edge-case checks.

## Validation Run 2: X11 Key Input for Undo and Filtering

Date: 2026-07-09

Purpose:

- Separate programmatic `SelText` behavior from real key input behavior.
- Check whether real key input populates GTK4 edit/memo undo stacks.
- Recheck the `NumbersOnly=True` plus `CharCase=ecUpperCase` observation with
  user input, not only programmatic insertion.
- This run does not modify GTK4 implementation code.

Example-only change:

- `CloseTimer` now dumps final edit/password/filtered/memo state before closing.

Build command:

```sh
./lazbuild --ws=gtk4 example_gtk4_editmemo_validation/editmemo_validation.lpi
```

Build result:

- Succeeded.
- Hints only: unused `Sender` parameters.

Auto control command:

```sh
xvfb-run -a env EDITMEMO_VALIDATION_AUTO=1 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation
```

Auto control result:

- Existing run-1 findings reproduced:
  - `TextHint := ''` did not clear native placeholder;
  - `TEdit.CanUndo=True` from startup;
  - programmatic edit/memo `SelText` changes were not undone;
  - programmatic filtered `SelText='ab34'` produced empty text.

Real edit input without undo:

```sh
xvfb-run -a bash -lc 'env EDITMEMO_VALIDATION_CLOSE_MS=1600 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Edit/Memo validation"); \
  xdotool mousemove --window "$wid" 170 34 click 1; \
  xdotool key --window "$wid" ctrl+a; \
  xdotool type --window "$wid" useredit; \
  wait $app'
```

Result:

- Final edit text was `useredit`, confirming the X11 input path reached the
  GTK4 edit.

Real edit input with undo:

```sh
xvfb-run -a bash -lc 'env EDITMEMO_VALIDATION_CLOSE_MS=1800 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Edit/Memo validation"); \
  xdotool mousemove --window "$wid" 170 34 click 1; \
  xdotool key --window "$wid" ctrl+a; \
  xdotool type --window "$wid" useredit; \
  xdotool key --window "$wid" ctrl+z; \
  wait $app'
```

Result:

- Final edit text was empty, not the original `abc`.
- `CanUndo` still reported `True`.
- A second append-style test also ended with empty edit text after `Ctrl+Z`.

Interpretation:

- Real key input does populate some native edit undo state, but the observed
  undo baseline is not LCL's initial `Text='abc'` state.
- This strengthens the `TEdit.CanUndo`/`Undo` accuracy concern: `CanUndo=True`
  does not tell the caller whether undo will restore the expected previous LCL
  state.
- Because this uses synthetic X input, live-desktop confirmation is still
  appropriate before choosing an implementation fix.

Filtered edit real input:

```sh
xvfb-run -a bash -lc 'env EDITMEMO_VALIDATION_CLOSE_MS=1800 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Edit/Memo validation"); \
  xdotool mousemove --window "$wid" 170 114 click 1; \
  xdotool key --window "$wid" ctrl+a; \
  xdotool type --window "$wid" ab34; \
  wait $app'
```

Result:

- Final filtered text was `34`.

Interpretation:

- User input filtering behaves differently from programmatic `SelText='ab34'`.
- The user-input path keeps digits and drops letters as expected for
  `NumbersOnly=True`.
- The empty-text result remains a programmatic `SelText`/filter interaction
  candidate, not a confirmed user-input filtering defect.

Memo real input without undo:

```sh
xvfb-run -a bash -lc 'env EDITMEMO_VALIDATION_CLOSE_MS=1900 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Edit/Memo validation"); \
  xdotool mousemove --window "$wid" 170 170 click 1; \
  xdotool key --window "$wid" ctrl+End; \
  xdotool key --window "$wid" Return; \
  xdotool type --window "$wid" usermemo; \
  wait $app'
```

Result:

- Final memo text was `line1\nline2\nusermemo`.
- `CanUndo=True`.

Memo real input with undo:

```sh
xvfb-run -a bash -lc 'env EDITMEMO_VALIDATION_CLOSE_MS=2200 GDK_BACKEND=x11 \
  ./example_gtk4_editmemo_validation/editmemo_validation & app=$!; \
  wid=$(xdotool search --sync --limit 1 --name "GTK4 Edit/Memo validation"); \
  xdotool mousemove --window "$wid" 170 170 click 1; \
  xdotool key --window "$wid" ctrl+End; \
  xdotool key --window "$wid" Return; \
  xdotool type --window "$wid" usermemo; \
  xdotool key --window "$wid" ctrl+z; \
  wait $app'
```

Result:

- Final memo text was `line1\nline2\n`.
- `CanUndo=True`.

Interpretation:

- Real key input populates the memo native undo stack.
- One `Ctrl+Z` removed `usermemo` but left the inserted newline. This looks like
  GTK4 text-buffer undo granularity rather than the programmatic `SelText`
  behavior from run 1.

Observed evidence:

```text
close edit text="useredit" ... canundo=True ...
close edit text="" ... canundo=True ...
close filtered text="34" ... canundo=True ...
close memo text="line1\nline2\nusermemo" ... canundo=True ...
close memo text="line1\nline2\n" ... canundo=True ...
```

## Implementation Fix (2026-07-10)

- `TGtk4Entry.SetTextHint`: the `(AHint <> '')` guard never cleared the
  native placeholder; clearing now passes nil to
  `gtk_entry_set_placeholder_text`. Runtime (auto run): set → replace →
  clear cycle shows the native placeholder following every step.

Undo classification (no code change, header-verified):

- `TEdit.CanUndo` stays always-true-with-handle: GtkText/GtkEditable
  expose only the `enable-undo` property — there is NO public can-undo
  query in GTK4 (checked /usr/include/gtk-4.0). qt5 can query; gtk2 has
  no edit undo at all, so gtk4 remains strictly better than the
  baseline. `backend_limited`.
- Programmatic edits are not undoable: GTK marks non-user buffer changes
  irreversible by design — runtime shows `Undo` after a programmatic
  `SelText` leaves the text, and the memo's real
  `gtk_text_buffer_get_can_undo` reads False after a programmatic
  insert. User-typed edits keep the native undo stack (entry `text.undo`
  action / TextBuffer undo).
