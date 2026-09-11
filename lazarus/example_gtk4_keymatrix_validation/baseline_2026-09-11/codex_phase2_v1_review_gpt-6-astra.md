The capture approach is sound, but **§15 is not ready as written**: release tracking, event-pointer lifetime, reentrancy, and the design-mode helper need corrections. This was a source-only review; no files were changed. Citations use the current checkout’s lines, which differ from the plan’s approximate numbers.

1. **Claim: recording first does not affect insert-text/deferral. → Evidence → Verdict: plan wrong as an unconditional claim; ordinary deferral is OK.**

   The recorder sets `FDelegateKeyPending := True` for any press without Ctrl/Alt, including Return/Escape/arrows, and leaves `FPendingKeyText = ''` for these nonprinting keys ([gtk4widgets.pas:6216](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6216)). Only the release recorder clears both ([gtk4widgets.pas:6228](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6228)); GtkText processing does not clear these Pascal fields.

   Therefore, returning TRUE leaves the pending flag set until release or another press. An unrelated, unsuppressed delegate insertion during that interval passes the key-origin gate and generates U8/KP ([gtk4widgets.pas:6361](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6361)). Focus-leave only flushes deferred text; it does not clear pending state ([gtk4widgets.pas:6310](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6310)).

   This loose gate already exists, but pre-dispatch exposes additional LCL callbacks while it is armed. Ordinary `Text := ...` is protected by `FSuppressInsertFeedback` ([gtk4widgets.pas:6494](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6494)). **No direct deferral corruption was found:** nonempty inserted text cannot equal the empty pending-key text, and active preedit bypasses pre-dispatch. The plan nevertheless needs an explicit pending-state policy for consumed presses and insertions triggered during LCL delivery.

2. **Claim: FALSE presses permit release propagation; TRUE presses stop release at capture. → Evidence → Verdict: plan OK, with qualifications.**

   GTK emits `key-released` regardless of whether that controller consumed the press, then looks up/removes the release **keyval** in `pressed_keys`; that lookup determines propagation ([gtkeventcontrollerkey.c:120](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:120)). The signal is explicitly void ([gtkeventcontrollerkey.c:223](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:223)).

   Thus, for an ordinary matching pair on the same controller:

   - Capture press FALSE: release leaves that controller; bubble dedup is required **if it reaches bubble**.
   - Capture press TRUE: release callback runs, then GTK returns TRUE and stops propagation. Outer `Gtk4KeyReleasedCB` does not run.

   FALSE does **not guarantee** arrival at outer bubble: GtkText’s IM or another intervening controller may consume the release. IM filtering precedes key signals ([gtkeventcontrollerkey.c:99](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:99)). The outer Pascal callback’s Boolean return cannot control a void signal.

3. **Claim: one `FPreDispKeyval` correctly tracks release obligations. → Evidence → Verdict: plan wrong.**

   Every eligible press overwrites the slot, and release delivery requires equality with that single slot ([PLAN_GTK4_KEY_PREDISPATCH.md:589](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:589), [line 599](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:599)).

   A concrete failure needs neither IM nor layout changes:

   `Return down → F3 down → Return up`

   Return was consumed and remains in GTK’s `pressed_keys`; F3 overwrote the plan’s slot. Return release fails the plan’s comparison, so capture sends no KU, but GTK still swallows it. **Return KU, default-button activation, and EditingDone are lost.**

   Keyval mismatch is also real: X11 translates both press and release using each event’s current modifier/group state ([gdkdevicemanager-xi2.c:1524](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/x11/gdkdevicemanager-xi2.c:1524)); Wayland obtains the symbol from current XKB state ([gdkdevice-wayland.c:2123](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/wayland/gdkdevice-wayland.c:2123)). For example, a pre-dispatched Ctrl+Shift+A press can release as lowercase `a` after Shift is released.

   That mismatch alone usually lets release continue; it does **not permanently block all later releases**. However, both the plan’s old keyval and GTK’s consumed-keyval entry can remain stale, creating later misclassification/swallowing. Track outstanding presses by physical key identity, separately from propagation dedup, and account explicitly for GTK’s keyval-based bookkeeping.

4. **Claim: `FKeyEventLCLHandled` captures precisely the otherwise-hidden LCL consumption. → Evidence → Verdict: placement intent OK; shared-field implementation unsafe.**

   Required placements in current `GtkEventKey`:

   - Initialize at entry, beside `Result := False` ([gtk4widgets.pas:3816](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3816)).
   - At the combined CN condition, evaluate `DeliverMessage` once into a local result; record  
     `(CNResult <> 0) or (Msg.CharCode = VK_UNKNOWN)` **separately from** `IsArrowKey` ([gtk4widgets.pas:3928](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3928)). An arrow actually zeroed/handled by LCL must still set the flag; an arrow-only shortcut must not.
   - Native LM branch: set True at `if Msg.CharCode = 0 then exit(True)` ([gtk4widgets.pas:3962](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3962)).
   - Other LM branch: set it according to `Msg.CharCode = 0`, **not merely a nonzero delivery result** ([gtk4widgets.pas:3972](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3972)).

   A reset-at-entry per-widget field is not invocation-local. `DeliverMessage` calls application `WindowProc` ([gtk4widgets.pas:5091](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:5091)); `ProcessMessages` drains the GLib context ([gtk4object.inc:544](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4object.inc:544)). A nested handled key can leave True for an otherwise unhandled outer key. Use a local outcome returned through an out parameter/result record, or a properly stacked call context.

5. **Claim: unconditional Up/Down consumption is harmless for plain entries. → Evidence → Verdict: plan OK for unmodified focus prevention; broader no-regression claim unverifiable.**

   No Up/Down binding exists in GtkText’s binding block ([gtktext.c:1341](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1341)). GtkWindow installs arrow focus bindings ([gtkwindow.c:1250](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwindow.c:1250)). The original log shows edit Down KD, EditingDone, then **spin** KU ([gtk4_edit_orig.log:25](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/gtk4_edit_orig.log:25)). Together with the entry’s arrow `exit(False)`, this supports the stated focus-movement mechanism; the log itself does not trace the GTK binding invocation.

   No built-in LCL requirement for plain Up/Down to scroll an enclosing TScrollBox was found. Arrow processing already exits before LM delivery, where parent `ChildKey` and LCL navigation run ([wincontrol.inc:5925](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5925)).

   However, the proposed condition also eats **Ctrl+Up/Down**, which GtkScrolledWindow binds to scrolling ([gtkscrolledwindow.c:905](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkscrolledwindow.c:905)). TScrollBox uses that native ancestor ([gtk4widgets.pas:13553](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:13553)). Existing ancestor LCL controllers can already intercept arrows, so this is not proof of a newly working-to-broken TScrollBox path. It does mean the unmodified matrix cannot justify consuming every modifier combination.

   Combo scope is correct: `TGtk4ComboBox` is a separate `TGtk4Bin` descendant ([gtk4widgets.pas:824](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:824)).

6. **Claim: moving Escape earlier preserves all native behavior when preedit is empty. → Evidence → Verdict: LCL sequence OK; blanket native-equivalence claim wrong; external IM behavior unverifiable.**

   Escape is in `FKeysToEat` and is consumed on the normal fallthrough ([gtk4widgets.pas:4629](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4629), [line 4076](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4076)). Moving that delivery to capture retains the ordinary KD/KP/KU/CAN sequence, subject to the release defects above.

   But GtkText previously received Escape first. Besides IM reset, its handler resets cursor blinking, dismisses the selection bubble, disables text handles, and obscures the pointer ([gtktext.c:3218](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:3218)). Capture consumption skips these actions.

   IM reset depends on `need_im_reset`, **not on preedit-string emptiness** ([gtktext.c:4847](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:4847)). For an idle GtkIMContextSimple, Escape has no composition to cancel and returns FALSE ([gtkimcontextsimple.c:1009](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkimcontextsimple.c:1009)); skipping reset is acceptable in that narrow case. Empty visible preedit does not establish that every external IM is idle. Nonempty preedit correctly protects the IM path; fcitx behavior remains unverified.

7. **Claim: current-event pointer equality identifies the same capture/bubble propagation. → Evidence → Verdict: plan OK within one uninterrupted propagation.**

   The compatibility function directly binds GTK’s accessor ([lazgtk4_compat.pas:289](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4bindings/lazgtk4_compat.pas:289)). More precisely, that accessor reads the **base controller’s `priv->event`**, set before `handle_event`, rather than the key subclass’s separate `current_event` field ([gtkeventcontroller.c:365](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:365), [line 606](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:606)).

   GTK passes the same `event` to capture and bubble throughout the ancestor chain ([gtkmain.c:1899](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1899), [line 1931](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1931)). Therefore the delegate and outer GtkEntry controller see the same pointer.

   Design-controller ordering is unchanged: its capture controller is attached to the outer container/window, before propagation reaches the delegate ([gtk4widgets.pas:4747](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4747)). No ordering defect was found there. The form guard works while `ActiveControl <> nil`; it is a current-focus check, not durable event provenance.

8. **Claim: keeping borrowed pointers until later events safely extends dedup/replay protection. → Evidence → Verdict: plan wrong.**

   `FPreDispRelEvent` survives beyond its propagation, with no clearing on unmatched releases specified ([PLAN_GTK4_KEY_PREDISPATCH.md:602](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:602)). GTK releases its controller-held event reference after dispatch; event instances are eventually freed and newly allocated ([gtkeventcontroller.c:372](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:372), [gdkevents.c:139](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:139), [line 403](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:403)).

   Consequently, a later unrelated printable-key release can reuse the saved address and be incorrectly suppressed. Press replay comparisons have the same address-reuse problem; keyval does not distinguish a new autorepeat event from a replay at a reused address.

   Reentrancy independently breaks the singleton: an inner press overwrites `FPreDispEvent`, so the resumed outer FALSE press can reach bubble without matching its marker. The replay guard also runs **after** mutable preedit guards, and `FPreDispConsumed` is stored only after LCL delivery, leaving an in-progress replay without a completed outcome.

   Separate propagation-local dedup, outstanding physical presses, and retained replay identity. They have different lifetimes.

9. **Claim: §15.1’s helper extraction preserves all three callbacks. → Evidence → Verdict: plan wrong unless design mode explicitly retains an empty string.**

   Runtime press synthesizes UTF-8 text, including Enter normalization ([gtk4widgets.pas:1895](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1895)). **Design press explicitly sets `Event.key.string_ := ''`** ([gtk4widgets.pas:1990](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1990)).

   Calling the proposed helper with `APress=True` from the design callback changes that field and can enable character delivery. Preserve an explicit no-text option or restore the empty string before calling `GtkEventKey`. Keeping the caller-owned UTF-8 buffer alive through synchronous delivery is otherwise appropriate.

10. **Claim: the added callbacks can store fields immediately after `GtkEventKey`. → Evidence → Verdict: plan wrong without lifetime checks.**

    The proposed press reads/writes Entry fields after LCL dispatch, and release writes three fields afterward ([PLAN_GTK4_KEY_PREDISPATCH.md:591](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:591)). LCL handlers can destroy the wrapper. Existing editable delivery explicitly recognizes this and checks the live-widget registry before touching `Self` again ([gtk4widgets.pas:5990](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:5990)).

    Add equivalent lifetime validation before new post-dispatch field accesses. Also, release currently clears tracking **after** delivery: a nested new press can establish fresh state that the resumed outer release then erases. Retire the matching release obligation before invoking reentrant LCL code.

11. **Claim: §15.4’s expected matrix follows from the code. → Evidence → Verdict: mostly plan OK, with specific corrections.**

    - **Left/Right KD:** correct. CN delivery occurs before the arrow early exit; CN invokes the before-interface key handlers ([gtk4widgets.pas:3928](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3928), [wincontrol.inc:5883](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5883)). However, arrows also take that early exit on release: calling the “whole release path” does **not** actually deliver LM_KEYUP for arrows.
    - **Delete:** KD/KU, no U8/KP is correct. The `VK_INSERT..VK_DELETE` exclusion blocks the character section despite `string_ = #127` ([gtk4widgets.pas:3987](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3987)). Remove the tentative `KP:#127?`.
    - **Ctrl+A:** KD 65 with Ctrl, U8 `"a"`, KP #97 is correct for the unconsuming harness; no Ctrl-to-#1 conversion exists in the builder. Returning FALSE permits native select-all ([gtktext.c:1401](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1401)).
    - **BackSpace:** U8 is **one byte #8**, not an empty string. The character block passes the synthesized string directly to `IntfUTF8KeyPress` ([gtk4widgets.pas:3995](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3995)). A raw terminal log may render that control character invisibly.
    - **Return/KP_Enter:** the ordinary isolated sequence, including EditingDone before default action, is correct ([application.inc:2219](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/application.inc:2219)). Eating KD prevents the application’s down-key registration, so no DEF/CAN is expected, while KU can still fire. This depends on fixing release tracking.
    - **Tab, printable press handling, and spin opt-out:** no additional direct branch-selection defect found. Their blanket “unchanged” guarantee remains conditional on fixing stale dedup state and reentrancy.