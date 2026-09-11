v2 still needs changes, particularly around timestamps, stale GTK state, and reentrancy. This was a read-only source review; no files changed.

1. **The keycode list fixes pairing for releases that reach the delegate.**  
   **Evidence:** GTK emits `key-released` **before** checking/removing its keyval entry ([gtkeventcontrollerkey.c:129](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:129)). Consequently, v2’s keycode lookup delivers Return↑ after Return↓ F3↓, and finds a tracked Ctrl+Shift+A press even when its release keyval changes to lowercase ([plan:620](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:620)). Ordinary repeat presses can replace one outstanding entry and finish with one release.

   Plain Shift↓ A↓ Shift↑ A↑ is **excluded** from pre-dispatch: neither the modifier nor unmodified printable A enters the list ([plan:596](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:596)). No new coverage for that literal sequence was found; its existing path remains.

   **Verdict: plan OK for tracked presses and arriving releases**, subject to the following defects.

2. **A changed release keyval leaves GTK state behind and can swallow a later, unrelated release.**  
   **Evidence:** GTK adds the consumed press’s keyval and removes only the release’s keyval ([gtkeventcontrollerkey.c:120](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:120)).

   Concrete sequence: LCL consumes Ctrl+Shift+A↓; Shift↑ occurs before A↑, whose keyval is now `a`. v2 delivers that release correctly, but GTK retains `A`. Later, plain Shift+A is excluded from pre-dispatch. Its `A` release finds no outstanding v2 entry, then GTK’s stale `A` entry consumes it before bubble. The new capture controller has lost that later LCL KeyUp.

   **Verdict: plan wrong.** Keycode pairing fixes immediate delivery but does not repair GTK’s independent keyval state. The design needs an explicit solution for that state, including modifier/keymap changes.

3. **Focus loss has no automatic release cleanup; clearing only the Pascal list is insufficient.**  
   **Evidence:** `handle_crossing` only updates focus state and calls IM focus-in/out; it neither emits synthetic key releases nor clears `pressed_keys` ([gtkeventcontrollerkey.c:144](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:144)). The inspected X11 focus path constructs a focus event, not releases ([gdkdevicemanager-xi2.c:1452](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/x11/gdkdevicemanager-xi2.c:1452)). Wayland likewise stops repeat and emits focus-out ([gdkdevice-wayland.c:2032](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/wayland/gdkdevice-wayland.c:2032)). **No synthetic-release or pressed-key cleanup was found.**

   Clear outstanding entries, dedup state, and repeat bookkeeping on delegate focus-leave. Do this **before** the existing `FDeferredText = ''` early exit ([gtk4widgets.pas:6315](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6315)); the controller is already connected ([gtk4widgets.pas:6582](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6582)). Invalidate in-flight dispatches too, so returning callbacks cannot restore canceled entries.

   GTK’s private table needs separate treatment. `gtk_event_controller_reset()` merely invokes a reset vfunc, and this key controller installs none ([gtkeventcontroller.c:436](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:436), [gtkeventcontrollerkey.c:183](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:183)). Define focus loss as cancellation; blindly synthesizing Return KeyUp could activate the default button through [application.inc:1770](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/application.inc:1770).

   **Verdict: plan wrong/incomplete.**

4. **The timestamp retransmission test breaks real autorepeat on GTK 4.6.9 Wayland.**  
   **Evidence:** `gdk_event_get_time` exists, works on key events, and returns their stored `guint32` timestamp ([gdkevents.c:1291](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:1291), [gdkevents.c:1562](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:1562)). X11 passes through `xev->time`; GTK adds no uniqueness guarantee ([gdkdevicemanager-xi2.c:1592](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/x11/gdkdevicemanager-xi2.c:1592)).

   More decisively, Wayland’s repeat callback calls:
   `deliver_key_event(seat, seat->keyboard_time, seat->repeat_key, 1, TRUE)` ([gdkdevice-wayland.c:2236](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/wayland/gdkdevice-wayland.c:2236)). `keyboard_time` is updated by incoming keyboard events, not each generated repeat ([gdkdevice-wayland.c:2279](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/wayland/gdkdevice-wayland.c:2279)).

   Thus [plan:606](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:606) classifies genuine repeated Left/Return presses as retransmissions and skips their LCL delivery. Ordinary X11 repeat timestamps generally advance, but millisecond resolution and 32-bit wraparound still do not provide event identity.

   **Verdict: plan wrong.** Remove the assumption that repeat presses necessarily have different timestamps.

5. **The dedup tuple is not guaranteed unique, and the marker is not actually propagation-local.**  
   **Evidence:** A marker is cleared only by a matching bubble callback, yet v2 explicitly permits releases that never bubble ([plan:624](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:624)). Native-consumed presses also leave their markers behind. GTK frees an event when its last reference disappears ([gdkevents.c:865](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:865)); timestamps can repeat, as above.

   Therefore `(address, time, keycode, type)` cannot prove that a later event is the original event. Never dereferencing the stored pointer prevents one kind of invalid access; it does not establish identity.

   **Verdict: plan wrong as a uniqueness claim.** Use owned event references or an explicit dispatch identity/lifetime scheme, with cleanup for events whose propagation stops before bubble.

6. **Setting the marker after LCL delivery is correct for the specific nested-delivery scenario.**  
   **Evidence:** GTK synchronously completes the capture loop before entering upward propagation ([gtkmain.c:1899](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1899), [gtkmain.c:1913](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1913)). Target/bubble execution is likewise synchronous ([gtkwidget.c:4753](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwidget.c:4753)).

   An inner event processed inside outer `DeliverMessage` can complete first; assigning the outer marker afterward restores the correct marker for the outer continuation. **No normal path was found where the outer event’s own bubble executes before its capture callback returns.** Explicit forwarding/repropagation is another propagation invocation.

   Also, obtaining `Ev/T` before LCL delivery is appropriate: the controller’s current-event field is overwritten/cleared during recursive handling rather than stack-restored ([gtkeventcontroller.c:365](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:365)).

   **Verdict: plan OK for this ordering question.** This does not resolve findings 4–5 or the remaining shared-state issues.

7. **Outstanding-press updates and retransmission early exits remain reentrancy-unsafe.**  
   **Evidence:** v2 inserts an entry with `Consumed=False`, calls LCL, then updates the entry afterward ([plan:608](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:608)). During that call, a nested release can remove it, another press can replace it, or focus-leave can cancel it. Removing release entries before delivery is correct, but does not protect the outer press’s later update.

   A nested retransmission can also observe the provisional `Consumed=False` and reach GTK before the outer callback decides to consume it. Separately, the retransmission early exit bypasses both pending-text cleanup and marker assignment. A consumed Return retransmission first sets `FDelegateKeyPending=True` in the existing recorder ([gtk4widgets.pas:6216](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6216)), then exits before v2 clears it.

   **Verdict: plan wrong/incomplete.** Use an entry generation plus an explicit in-progress state, re-find/revalidate after callbacks, and make replay exits perform the required bookkeeping.

8. **The proposed outer liveness checks are too late for an existing access inside `GtkEventKey`.**  
   **Evidence:** After CN delivery reports handled, `GtkEventKey` reads `WidgetType` before its next liveness gate ([gtk4widgets.pas:3928](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3928)). A handler that consumes the key and destroys the entry can therefore leave the function reading a freed wrapper before v2 reaches its post-call check. The unhandled `LM_CONTEXTMENU` continuation also lacks an immediate check ([gtk4widgets.pas:3897](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3897)).

   Existing `CanSendLCLMessage` is registry-first and useful where called ([gtk4widgets.pas:4429](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4429)); the problem is the missing checks before these accesses.

   **Verdict: plan wrong as written.** Check inside `GtkEventKey`, immediately after potentially destructive callbacks and before accessing wrapper fields.

9. **Excluding Escape preserves the current ordinary, non-composing path.**  
   **Evidence:** GtkIMContextSimple returns `FALSE` for Escape outside its hex/compose sequences ([gtkimcontextsimple.c:1009](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkimcontextsimple.c:1009)). GtkText performs its incidental handling and returns `FALSE` ([gtktext.c:3218](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:3218)). **No GtkText Escape binding was found.**

   The wrapper has the ordinary bubble controller ([gtk4widgets.pas:4755](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4755)), and Escape remains in default `FKeysToEat` ([gtk4widgets.pas:4629](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4629)), applied at [gtk4widgets.pas:4076](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4076). Existing earlier LCL exits remain possible.

   **Verdict: plan OK.**

10. **No default double editing action was found for the listed shortcuts.**  
    **Evidence:** GtkText supplies Ctrl+A selection, clipboard bindings and their Insert/Delete alternatives, Insert overwrite, Ctrl+Z/Y undo/redo, and Menu/Shift+F10 popup ([gtktext.c:1401](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1401), [gtktext.c:1475](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1475), [gtktext.c:1515](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1515), [gtktext.c:1535](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1535), [gtktext.c:1341](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1341)). None is in default `FKeysToEat`.

    Form/menu/action shortcuts are checked in **CN_KEYDOWN**, not default `ChildKey`: [wincontrol.inc:5810](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5810), [customform.inc:2615](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customform.inc:2615). A handled shortcut sets the CN result ([wincontrol.inc:7251](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7251)), which v2’s `AHandled` correctly turns into capture consumption. Thus a Ctrl+X menu action does not also fall through to GtkText’s cut.

    **No default TCustomEdit LM_KEYDOWN implementation performing these editing operations was found.** `DoRemainingKeyDown` performs parent/application processing; default `KeyDownAfterInterface` is empty ([wincontrol.inc:5925](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5925), [wincontrol.inc:5761](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5761)). Qt5’s QLineEdit uses the inherited key filter and the same CN→LM route ([qt5/qtwidgets.pas:10079](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:10079), [qt5/qtwidgets.pas:3530](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:3530)).

    Popup keys have an additional intentional consumption path: an LCL popup can handle `LM_CONTEXTMENU` before CN delivery ([gtk4widgets.pas:3887](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3887)). Otherwise GTK proceeds. Clipboard LM notifications remain attached to GtkText’s action signals ([gtk4widgets.pas:6568](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6568)).

    **Verdict: plan OK for default handlers.** Custom handlers performing an action without reporting consumption remain application behavior.

11. **No Return-dependent deferred-text flush was found.**  
    **Evidence:** Deferred text is created only while observed preedit is nonempty ([gtk4widgets.pas:6367](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6367)), when v2 bypasses pre-dispatch. It is flushed by preedit clearing, the insert-text AFTER callback, or focus-leave ([gtk4widgets.pas:6292](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6292), [gtk4widgets.pas:6300](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6300), [gtk4widgets.pas:6310](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6310)). The flush clears the stored text before callbacks ([gtk4widgets.pas:6258](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6258)).

    **No TGtk4Entry activation hook or `activates-default` dependency was found.** GtkText’s default activate handler only conditionally activates the default widget ([gtktext.c:4246](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:4246)); LCL EditingDone is on Return KeyUp ([customedit.inc:460](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:460)).

    **Verdict: plan OK for the inspected deferral mechanism.** No new “wait until focus-leave” path was found. Universal fcitx commit-order safety remains **unverifiable** from these sources: an empty observed preedit string is not proof that every external IM has no pending work.

12. **Repeat flags still use a single last-key slot.**  
    **Evidence:** `KF_REPEAT` depends on `FLastKeyVal` and `FLastKeyPress`, which every delivered key event overwrites ([gtk4widgets.pas:3845](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3845)). Left↓ F3↓ Left-repeat↓ therefore delivers the last press without `KF_REPEAT`, despite Left remaining physically down.

    **Verdict: plan wrong if autorepeat correctness includes interleaved-key repeat flags.** The consecutive-Left test passes this particular bookkeeping; use the outstanding physical-key state for broader repeat detection.