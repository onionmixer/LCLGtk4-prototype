# FIX: GTK4 Startup Hide During OnShow

Date: 2026-07-08
Rollback point: 34fa6d063eee34516659c4d0a98b16284eecec08
Branch: main

Scope: LCL GTK4 form visibility handling only. Do not modify Lazarus IDE code.

## External Report Reviewed

Reviewed document:

```text
/mnt/STORAGE16T/Workspace_STORAGE16T/tomboy-ng/doc/lcl-gtk4-startup-hide-issue.md
(original location before the 2026-09-02 workspace move:
 /mnt/USERS/onion/DATA_ORIGN/Workspace/tomboy-ng/tomboy-ng/doc/... — the file was
 not found under the moved tomboy-ng tree when the paths were updated)
```

Conclusion: the report is logically valid. The issue is reproducible outside
tomboy-ng with a minimal LCL GTK4 main form that calls `Hide` from `OnShow`.
The application-level workaround described in that document is reasonable, but
the underlying behavior should be fixed in LCL GTK4.

## User-Visible Symptom

In tomboy-ng GTK4 builds, the startup splash/status main window remains visible
even when startup preferences or command line request it to be hidden.

Known tomboy-ng path:

- `Tomboy_NG.lpr` creates `TMainForm` first, making it `Application.MainForm`.
- `TApplication.Run` calls `FMainForm.Show`.
- `TMainForm.FormShow` calls `ButtonDismissClick(Self)` when `--no-splash` is
  present or `ShowSplash=false`.
- `ButtonDismissClick` calls `Hide()` on non-Cocoa widgetsets.

Relevant source facts:

```text
source/Tomboy_NG.lpr:
  Application.CreateForm(TMainForm, MainForm);

source/mainunit.pas:
  if Application.HasOption('no-splash') or (not Sett.CheckShowSplash.Checked) then
      ButtonDismissClick(Self);

  procedure TMainForm.ButtonDismissClick(Sender: TObject);
  begin
      {$ifdef LCLCOCOA}
      width := 0;
      height := 0;
      {$else}
      hide();
      {$endif}
  end;
```

## Local Minimal Reproduction

A temporary minimal test was built under:

```text
/tmp/lcl_gtk4_hide_onshow_test/
```

Test behavior:

- Main form caption: `lcl-gtk4-hide-onshow-test`
- `OnShow` logs current `Visible`, calls `Hide`, logs `Visible` again.
- A timer keeps the application alive for 4 seconds.

Build command used:

```sh
fpc -MObjFPC -Scghi -Cg -O1 -g -gl -l -vewnhibq -dLCL -dLCLgtk4 \
  -Fu/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/units/x86_64-linux/gtk4 \
  -Fu/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/units/x86_64-linux \
  -Fu/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/components/lazutils/lib/x86_64-linux \
  -Fu/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/components/freetype/lib/x86_64-linux \
  -Fu/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/packager/units/x86_64-linux \
  -FU/tmp/lcl_gtk4_hide_onshow_test/lib/x86_64-linux \
  -FE/tmp/lcl_gtk4_hide_onshow_test \
  -o/tmp/lcl_gtk4_hide_onshow_test/hide_onshow \
  /tmp/lcl_gtk4_hide_onshow_test/hide_onshow.lpr
```

Runtime command used:

```sh
xvfb-run -a bash -lc '
  set -e
  /tmp/lcl_gtk4_hide_onshow_test/hide_onshow >/tmp/lcl_gtk4_hide_onshow_test/run.out 2>&1 &
  pid=$!
  sleep 1
  ids=$(xdotool search --name lcl-gtk4-hide-onshow-test 2>/dev/null || true)
  echo IDS1:$ids
  for id in $ids; do
    xwininfo -id $id | sed -n "/xwininfo:/p;/Map State:/p;/Width:/p;/Height:/p"
  done
  sleep 2
  ids=$(xdotool search --name lcl-gtk4-hide-onshow-test 2>/dev/null || true)
  echo IDS3:$ids
  for id in $ids; do
    xwininfo -id $id | sed -n "/xwininfo:/p;/Map State:/p;/Width:/p;/Height:/p"
  done
  wait $pid
  cat /tmp/lcl_gtk4_hide_onshow_test/run.out
'
```

Measured result:

```text
IDS1:2097156
xwininfo: Window id: 0x200004 "lcl-gtk4-hide-onshow-test"
  Width: 360
  Height: 180
  Map State: IsViewable
IDS3:2097156
xwininfo: Window id: 0x200004 "lcl-gtk4-hide-onshow-test"
  Width: 360
  Height: 180
  Map State: IsViewable

EVENT OnShow before-hide visible=TRUE
EVENT OnShow after-hide visible=FALSE
EVENT close-timer visible=FALSE
```

Important interpretation:

- LCL state becomes `Visible=False`.
- The native GTK4/X11 toplevel remains mapped and viewable.
- Therefore the bug is not merely a tomboy-ng configuration issue.

The recurring startup warning:

```text
GLib-CRITICAL **: g_regex_match_full: assertion 'string != NULL' failed
```

also appears in this minimal test, but it does not explain the visibility
state mismatch.

## Repository Regression Example

The reproducible example has been added to the Lazarus tree:

```text
example_gtk4_hide_onshow/
  hide_onshow.lpi
  hide_onshow.lpr
```

Supported modes:

- `--hide-on-show`: main form calls `Hide` in `OnShow`.
- `--normal`: main form remains visible.
- `--secondary-hide-on-show`: main form remains visible and a secondary form
  hides itself in its own `OnShow`.
- `--maximized` / `--fullscreen`: request visible window states for smoke
  testing.

The example prints its selected mode, requested window state, `OnShow`
visibility before and after `Hide`, and close-timer visibility. Use
`HIDE_ONSHOW_CLOSE_MS=<ms>` to keep the process alive longer or shorter for
manual inspection.

## Pre-Fix LCL/GTK4 Control Flow

Common LCL startup:

```pascal
procedure TApplication.Run;
begin
  if (FMainForm <> nil) and FShowMainForm then
  begin
    WidgetSet.AppSetupMainForm(FMainForm);
    FMainForm.Show;
  end;
  WidgetSet.AppRun(@RunLoop);
end;
```

Common form show path:

```pascal
procedure TCustomForm.Show;
begin
  ...
  Visible := True;
  if (not (csDesigning in ComponentState)) and Showing then
    ShowWindow(Handle, ShowCommands[WindowState]);
  BringToFront;
end;
```

Common hide path:

```pascal
procedure TCustomForm.Hide;
begin
  Visible := False;
end;
```

GTK4 `ShowHide` path:

```pascal
ShouldBeVisible := AForm.HandleObjectShouldBeVisible;
AGtk4Widget.Visible := ShouldBeVisible;
if AGtk4Widget.Visible then
begin
  Gtk4WidgetSet.AddWindow(AWindow);
  if AWindow^.get_decorated then
    AWindow^.present
  else
    PGtkWidget(AWindow)^.show;
end;
```

GTK4 `ShowWindow` path:

```pascal
if nCmdShow = SW_HIDE then
  TGtk4Widget(hWnd).Hide
else if TObject(hWnd) is TGtk4Window then
  Result := TGtk4Window(hWnd).ShowState(nCmdShow)
else
  TGtk4Widget(hWnd).Show;
```

GTK4 `ShowState` path:

```pascal
SW_SHOWNORMAL:
  begin
    PGtkWindow(fWidget)^.unmaximize;
    PGtkWindow(fWidget)^.present;
  end;

SW_RESTORE:
  begin
    PGtkWindow(fWidget)^.unmaximize;
    gtk_window_unminimize(PGtkWindow(fWidget));
    PGtkWindow(fWidget)^.unfullscreen;
    PGtkWindow(fWidget)^.present;
  end;
```

GTK4 form z-order path:

```pascal
class procedure TGtk4WSCustomForm.SetZPosition(...);
begin
  ...
  if APosition = wszpFront then
    PGtkWidget(AWindow)^.show;
end;
```

This is relevant because common `TCustomForm.Show` calls `BringToFront` after
`ShowWindow`, and `BringToFront` calls `SetZOrder(true)`.

## Root Cause Assessment

The observed bug is a mismatch between final LCL visibility and later native
GTK4 show/present calls.

Measured sequence:

1. `Application.Run` calls `MainForm.Show`.
2. `TCustomForm.Show` sets `Visible := True`.
3. The form enters its show/update path and fires `OnShow`.
4. Application code calls `Hide`, so LCL state becomes `Visible=False`.
5. The outer `TCustomForm.Show` continues after `Visible := True`.
6. `TCustomForm.Show` calls `BringToFront`.
7. For a top-level form, `TCustomForm.SetZOrder(True)` calls
   `SetForegroundWindow(Handle)`.
8. GTK4 `TGtk4WidgetSet.SetForegroundWindow` called
   `TGtk4Window.Activate`, which called `gtk_window_present()` even though
   the LCL form was already hidden.
9. GTK then emitted a native show path, setting the GTK widget visible while
   LCL state remained hidden.

Temporary trace used during implementation showed the decisive ordering:

```text
EVENT main OnShow before-hide visible=TRUE
EVENT main OnShow after-hide visible=FALSE
GTK4-HIDE-TRACE window activate ctl=:THideOnShowForm visible=False showing=False handle-visible=False
GTK4-HIDE-TRACE widget set_visible ctl=:THideOnShowForm value=True
```

Interpretation:

- The `Hide` call inside `OnShow` succeeded at the LCL level.
- The failing remap was not caused by `ShowHide` failing to hide the form.
- The remap was caused by a later foreground/activation path presenting a
  form whose `HandleObjectShouldBeVisible` was already false.

The important invariant for the fix:

```text
After application code calls Hide or sets Visible := False during OnShow,
no GTK4 backend path may show/present/map that form again unless the LCL form
state has become visible again.
```

## Why LCL GTK4 Needs a Fix

The application behaved correctly on at least the user's installed Qt build.
The minimal GTK4 test proves the visible native window can remain viewable while
LCL `Visible=False`.

This violates the expected LCL contract: final LCL visibility should control
the native widget visibility.

An application workaround using `QueueAsyncCall` or a one-shot timer would avoid
the specific startup path, but it would leave the LCL GTK4 backend with a
general state mismatch for any application that hides a form from `OnShow`.

## Non-Goals

- Do not change tomboy-ng.
- Do not change Lazarus IDE code.
- Do not alter common LCL `TCustomForm.Show` unless a GTK4-only fix proves
  impossible.
- Do not remove GTK4 `present()` usage globally; it was added for layout,
  activation, and focus behavior in other GTK4 paths.
- Do not change popup/completion behavior without a separate measured reason.

## Fix Plan

### Phase 1: Add a Focused Regression Example

Create a small LCL GTK4 example in the Lazarus tree, for example:

```text
example_gtk4_hide_onshow/
  hide_onshow.lpi
  hide_onshow.lpr
```

The example should include at least these modes:

- `--hide-on-show`: main form calls `Hide` in `OnShow`.
- `--normal`: main form stays visible.
- `--secondary-hide-on-show`: main form stays visible and a secondary form
  calls `Hide` in its own `OnShow`.
- Optional `--maximized` and `--fullscreen` modes to ensure normal visible
  window-state application is not broken.

The example should print:

- `OnShow` entry visibility
- visibility after `Hide`
- final timer visibility
- process id and caption used for `xdotool`/`xwininfo`

Reason for adding this first: the bug is timing/order dependent. A reproducible
small example is needed before changing show/present code.

### Phase 2: Guard GTK4 ShowWindow Against Hidden LCL Forms

Candidate change location:

```text
lcl/interfaces/gtk4/gtk4winapi.inc
TGtk4WidgetSet.ShowWindow
```

Before calling `TGtk4Window.ShowState(nCmdShow)` for non-hide commands:

1. Check whether `hWnd` is a `TGtk4Window`.
2. Check whether `TGtk4Window(hWnd).LCLObject` is a `TCustomForm`.
3. If the form exists and `not TCustomForm(...).HandleObjectShouldBeVisible`,
   then do not call `ShowState`.
4. Ensure the native widget is hidden or remains hidden, then return success.

The intended behavior:

```text
ShowWindow(SW_SHOWNORMAL/SW_RESTORE/etc.) must not present a native GtkWindow
when the owning LCL form has already become hidden.
```

Important risk:

- Some code may call `LCLIntf.ShowWindow(Form.Handle, SW_SHOW...)` directly
  while `Form.Visible=False`. Guarding this path means GTK4 will prefer LCL
  state consistency over direct native forcing. This should be documented and
  tested. Normal LCL code should use `Form.Show` or `Form.Visible := True`.

Mitigation:

- Apply the guard only to `TGtk4Window` with `LCLObject is TCustomForm`.
- Do not affect non-form controls.
- Do not affect visible forms.
- Keep `SW_HIDE` behavior unchanged.

### Phase 3: Guard GTK4 Form BringToFront/Z-Order Path

Candidate change location:

```text
lcl/interfaces/gtk4/gtk4wsforms.pp
TGtk4WSCustomForm.SetZPosition
```

Current behavior calls `show()` when `APosition = wszpFront`.

Required guard:

```text
If AWinControl.HandleObjectShouldBeVisible is false, SetZPosition must not
call gtk_widget_show or gtk_window_present for that form.
```

Reason:

- `TCustomForm.Show` calls `BringToFront` after `ShowWindow`.
- `BringToFront` can reach `SetZPosition`.
- Even if `ShowWindow` is guarded, this later z-order path can remap a form
  that was hidden in `OnShow`.

Important risk:

- Z-order requests for already hidden forms will become no-op. This is the
  expected LCL behavior because hidden forms should not be raised visibly.

### Phase 4: Audit Other GTK4 present/show Paths for Hidden Forms

Audit and only change if a measured test proves a path can remap a hidden form:

- `TGtk4Window.Activate`
- `TGtk4WidgetSet.AppBringToFront`
- focus activation paths that call `present`
- any idle callback scheduled after show

Do not preemptively rewrite these paths. They have focus and activation side
effects and may be needed for normal GTK4 behavior.

Minimum audit rule:

```text
Any GTK4 path that calls gtk_window_present or gtk_widget_show for a TCustomForm
must either be reached only when LCL state is visible, or explicitly check
HandleObjectShouldBeVisible first.
```

### Phase 5: Rebuild and Run Regression Tests

Run after each implementation step:

```sh
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_hide_onshow/hide_onshow.lpi
```

After the final implementation:

```sh
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_hide_onshow/hide_onshow.lpi
```

## Implementation Result

Implemented on 2026-07-08 in LCL GTK4 only.

Changed files:

- `lcl/interfaces/gtk4/gtk4widgets.pas`
- `lcl/interfaces/gtk4/gtk4winapi.inc`
- `lcl/interfaces/gtk4/gtk4object.inc`
- `lcl/interfaces/gtk4/gtk4wsforms.pp`
- `example_gtk4_hide_onshow/hide_onshow.lpr`
- `example_gtk4_hide_onshow/hide_onshow.lpi`

Implementation details:

- Added `Gtk4WindowCanPresent(AWidget: TGtk4Widget): Boolean`.
- For `TCustomForm` owners, the helper returns
  `TCustomForm.HandleObjectShouldBeVisible`.
- For non-form GTK4 windows/widgets, the helper leaves existing behavior
  unchanged.
- `TGtk4WidgetSet.SetForegroundWindow` now exits before activation when the
  target form should not be visible. This is the trace-confirmed root-cause
  path for `Hide` inside `OnShow`.
- `TGtk4Window.Activate` now avoids `present()` for hidden LCL forms.
- `TGtk4Window.ShowState` now avoids `present()/show()` for hidden LCL forms
  and explicitly hides the native widget.
- `TGtk4WidgetSet.ShowWindow`, `TGtk4WidgetSet.SetActiveWindow`, and
  `TGtk4WidgetSet.AppBringToFront` now use the same present guard.
- `TGtk4WSCustomForm.SetZPosition` no longer calls `show()` when
  `HandleObjectShouldBeVisible` is false.

The final code does not keep the temporary `LAZ_GTK4_HIDE_TRACE` instrumentation;
that trace was used only to identify the remapping call site.

## Verification Result

Builds run:

```sh
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_hide_onshow/hide_onshow.lpi
make -C lcl clean LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk4
./lazbuild --ws=gtk4 example_gtk4_hide_onshow/hide_onshow.lpi
```

All completed with exit code 0.

Xvfb regression results after implementation:

```text
CASE hide
MAIN_IDS

RUNOUT hide
EVENT mode=0 window-state=0 close-ms=2200
EVENT main OnShow before-hide visible=TRUE
EVENT main OnShow after-hide visible=FALSE
EVENT close-timer main-visible=FALSE
```

No X window id was found for `lcl-gtk4-hide-onshow-test`; this is the expected
fixed behavior.

```text
CASE normal
MAIN_IDS
2097156
Map State: IsViewable
EVENT mode=1 window-state=0 close-ms=2200
EVENT main OnShow before-hide visible=TRUE
EVENT close-timer main-visible=TRUE
```

The normal visible main form still maps correctly.

```text
CASE secondary
MAIN_IDS
2097156
Map State: IsViewable
SECONDARY_IDS

EVENT mode=2 window-state=0 close-ms=2200
EVENT main OnShow before-hide visible=TRUE
EVENT secondary OnShow before-hide visible=TRUE
EVENT secondary OnShow after-hide visible=FALSE
EVENT close-timer main-visible=TRUE
EVENT close-timer secondary-visible=FALSE
```

The main form stays visible and the secondary form that hides in `OnShow` is
not viewable.

Final clean-build retest:

```text
MAIN_IDS

EVENT mode=0 window-state=0 close-ms=2200
EVENT main OnShow before-hide visible=TRUE
EVENT main OnShow after-hide visible=FALSE
EVENT close-timer main-visible=FALSE
```

The recurring startup warning remains visible in the minimal test:

```text
GLib-CRITICAL **: g_regex_match_full: assertion 'string != NULL' failed
```

This warning existed before the fix and is not the visibility-remap cause.

Not run in this pass:

- tomboy-ng end-to-end startup command from Test 5.
- tray icon and font smoke examples from Test 6.
- manual maximized/fullscreen visual inspection.

## Test Plan

### Test 1: Minimal Hide In OnShow Must Stay Hidden

Command shape:

```sh
xvfb-run -a bash -lc '
  set -e
  ./example_gtk4_hide_onshow/hide_onshow --hide-on-show >/tmp/gtk4-hide-onshow.out 2>&1 &
  pid=$!
  sleep 1
  ids=$(xdotool search --name lcl-gtk4-hide-onshow-test 2>/dev/null || true)
  for id in $ids; do
    xwininfo -id $id | sed -n "/xwininfo:/p;/Map State:/p;/Width:/p;/Height:/p"
  done
  sleep 2
  ids=$(xdotool search --name lcl-gtk4-hide-onshow-test 2>/dev/null || true)
  for id in $ids; do
    xwininfo -id $id | sed -n "/xwininfo:/p;/Map State:/p;/Width:/p;/Height:/p"
  done
  wait $pid
  cat /tmp/gtk4-hide-onshow.out
'
```

Expected after fix:

- LCL log includes `after-hide visible=FALSE`.
- No matching X window is `Map State: IsViewable`.
- If an X window id still exists, it should be unmapped, not viewable.

Current failing result before fix:

```text
Map State: IsViewable
EVENT OnShow after-hide visible=FALSE
```

### Test 2: Normal Main Form Must Still Show

Command:

```sh
xvfb-run -a bash -lc '
  ./example_gtk4_hide_onshow/hide_onshow --normal >/tmp/gtk4-normal-show.out 2>&1 &
  pid=$!
  sleep 1
  ids=$(xdotool search --name lcl-gtk4-hide-onshow-test 2>/dev/null || true)
  for id in $ids; do
    xwininfo -id $id | sed -n "/Map State:/p;/Width:/p;/Height:/p"
  done
  kill "$pid" 2>/dev/null || true
  cat /tmp/gtk4-normal-show.out
'
```

Expected:

- One visible window.
- `Map State: IsViewable`.
- Correct requested size.

### Test 3: Secondary Form Hide In OnShow

Command:

```sh
xvfb-run -a bash -lc '
  ./example_gtk4_hide_onshow/hide_onshow --secondary-hide-on-show >/tmp/gtk4-secondary-hide.out 2>&1 &
  pid=$!
  sleep 1
  echo MAIN
  xdotool search --name lcl-gtk4-hide-main 2>/dev/null || true
  echo SECONDARY
  ids=$(xdotool search --name lcl-gtk4-hide-secondary 2>/dev/null || true)
  for id in $ids; do xwininfo -id $id | sed -n "/Map State:/p"; done
  kill "$pid" 2>/dev/null || true
  cat /tmp/gtk4-secondary-hide.out
'
```

Expected:

- Main form remains viewable.
- Secondary form is not viewable after hiding from `OnShow`.

### Test 4: Window State Still Applies For Visible Forms

Run the example in visible maximized/fullscreen modes:

```sh
xvfb-run -a ./example_gtk4_hide_onshow/hide_onshow --normal --maximized
xvfb-run -a ./example_gtk4_hide_onshow/hide_onshow --normal --fullscreen
```

Expected:

- Visible forms still become visible.
- No regression in maximize/fullscreen application.

### Test 5: tomboy-ng Scenario

From tomboy-ng tree after rebuilding with the local LCL GTK4:

```sh
xvfb-run -a bash -lc '
  cfg=$(mktemp -d /tmp/tng-nosplash-cfg.XXXXXX)
  notes=$(mktemp -d /tmp/tng-nosplash-notes.XXXXXX)
  printf "[BasicSettings]\nNotesPath=%s/\nShowSplash=false\nShowSearchAtStart=false\n" "$notes" > "$cfg/tomboy-ng.cfg"
  ./source/tomboy-ng-64 --no-splash --config-dir="$cfg" >/tmp/tng-nosplash.out 2>&1 &
  pid=$!
  sleep 4
  ids=$(xdotool search --name tomboy-ng 2>/dev/null || true)
  for id in $ids; do
    xwininfo -id "$id" | sed -n "/xwininfo:/p;/Map State:/p;/Width:/p;/Height:/p"
  done
  kill "$pid" 2>/dev/null || true
  cat /tmp/tng-nosplash.out
'
```

Expected after fix:

- No `tomboy-ng` main window remains `IsViewable`.
- If other helper/dialog windows appear, classify them separately by title.

### Test 6: Existing GTK4 Smoke Tests

Run existing GTK4 examples already used in this workspace:

```sh
./lazbuild --ws=gtk4 example_gtk4_trayicon_matrix/trayicon_matrix.lpi
./lazbuild --ws=gtk4 example_gtk4_setlclfonttest/gtk4_setlclfonttest.lpi
```

Run tray icon matrix manually if needed, because it exercises startup, hidden
state, popup menu, notification, and multiple GTK4 toplevel/application paths.

## Failure Triage

If Test 1 still fails after the `ShowWindow` guard:

- Re-run with temporary GTK4 trace around:
  - `TGtk4WidgetSet.ShowWindow`
  - `TGtk4WSCustomForm.SetZPosition`
  - `TGtk4Window.Activate`
  - `TGtk4WidgetSet.AppBringToFront`
- Confirm which path calls `show()` or `present()` after LCL `Visible=False`.
- Do not add broader guards until the remapping call site is identified.

If Test 2 fails:

- The guard is too broad and is suppressing valid visible form show paths.
- Check that the guard only triggers when `LCLObject is TCustomForm` and
  `not HandleObjectShouldBeVisible`.

If maximize/fullscreen tests fail:

- Check whether `ShowWindow` guard is blocking visible form state application.
- Window state should still be applied when `HandleObjectShouldBeVisible=True`.

## Risk Assessment

High-risk areas:

- `ShowWindow` is a general widgetset API. Guarding it changes behavior for
  direct callers that try to show a hidden form without updating LCL `Visible`.
- GTK4 `present()` is used to fix layout/focus behavior elsewhere. Removing it
  broadly would regress existing behavior.
- `BringToFront` and z-order paths are compositor-dependent on GTK4/Wayland.
  They should become no-op for hidden forms, but must still work for visible
  forms.

Lower-risk, preferred direction:

- Add narrow guards based on final LCL visibility.
- Keep all normal visible form paths unchanged.
- Keep `SW_HIDE` behavior unchanged.
- Add regression coverage before applying the behavioral fix.

## Current Status

The LCL GTK4 backend has been updated to preserve this invariant:

```text
Native GTK4 form visibility must not become visible when the owning LCL
TCustomForm.HandleObjectShouldBeVisible is false.
```

The final implementation covers the trace-confirmed activation/foreground path
and the related GTK4 present/show paths for `TCustomForm` owners. Local
regression tests and a clean LCL GTK4 rebuild passed.
