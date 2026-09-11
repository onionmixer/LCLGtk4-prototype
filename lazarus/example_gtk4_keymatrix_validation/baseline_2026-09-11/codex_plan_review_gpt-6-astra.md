The capture location is sound, but the plan is **not sound as written**. The main blockers are release suppression, existing CN_KEYDOWN consumption semantics, IM preedit handling, and the proposed spin-edit type flag.

I made no file changes. The plan changed externally during review; the latest version I read has SHA-256 prefix `f5139565455a` and already corrects the original arrow-navigation explanation.

1. **Claim: the existing delegate capture controller runs before GtkText’s IM and bindings.**

   **Evidence:** GTK traverses ancestors toward the target for capture, then processes target/bubble: [gtkmain.c:1867](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1867), [gtkwidget.c:4753](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwidget.c:4753). GtkText’s IM key controller is explicitly TARGET: [gtktext.c:1943](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1943). The existing LCL recorder is CAPTURE on that delegate: [gtk4widgets.pas:6542](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6542).

   Controllers are prepended, but execution filters by phase; adding another controller does not move TARGET ahead of CAPTURE: [gtkwidget.c:4555](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwidget.c:4555), [gtkwidget.c:11461](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwidget.c:11461).

   `gtk_entry_grab_focus_without_selecting` still focuses the inner GtkText, which calls its parent widget’s focus implementation: [gtkentry.c:1907](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkentry.c:1907), [gtktext.c:3337](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:3337). Key targeting uses root focus: [gtkmain.c:1514](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1514).

   **Verdict: plan OK.** I found nothing in controller ordering or the normal entry focus paths that defeats this placement.

2. **Claim: capture may consume Return while KeyUp remains in the existing bubble controller.**

   **Evidence:** When `key-pressed` returns TRUE, GtkEventControllerKey records the keyval in `pressed_keys`. On release it emits `key-released`, then returns handled when that keyval was recorded: [gtkeventcontrollerkey.c:120](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:120). The release signal itself returns **void**, so returning FALSE from a Pascal callback cannot override this: [gtkeventcontrollerkey.c:223](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:223).

   Consequently, a Return press consumed by the delegate controller normally causes its release to stop there too. LCL needs the release for `ControlKeyUp`/`DoReturnKey`: [application.inc:1751](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/application.inc:1751). EditingDone also depends on that route: [customedit.inc:460](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:460).

   **Verdict: plan wrong.** The fallback in §6.1/§10—capture handles presses, release remains record-only—is incompatible with consumed presses. Capture release delivery must accompany capture consumption. If moved, preserve **CN_KEYUP and LM_KEYUP**, not merely LM_KEYUP.

3. **Claim: a stored GdkEvent pointer safely identifies the bubble duplicate.**

   **Evidence:** During one propagation, GTK passes the same event pointer throughout: [gtkmain.c:1899](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1899), [gtkmain.c:1931](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1931). `get_current_event` returns a borrowed pointer; the controller references it only while handling the event: [gtkeventcontroller.c:365](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:365), [gtkeventcontroller.c:595](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:595). Event instances are allocated and freed normally, with no permanent address uniqueness guarantee: [gdkevents.c:139](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:139), [gdkevents.c:395](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:395).

   **Verdict: plan OK for identity within one dispatch; unverifiable for the proposed stored-field lifetime.** Specify ownership, clearing on events that remain record-only, cleanup when bubble never occurs, and reentrant delivery. A dangling “last delivered pointer” is insufficient.

   Also, upstream fcitx’s asynchronous path can requeue the **same** event; GTK’s `gdk_display_put_event` references rather than copies it. Bubble-only deduplication would not suppress a second capture delivery. This requires a replay test; I could not verify the installed fcitx version’s implementation. Evidence: [gdkdisplay.c:484](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkdisplay.c:484), [upstream fcitximcontext.cpp:470–498](https://github.com/fcitx/fcitx5-gtk/blob/master/gtk4/fcitximcontext.cpp#L470).

4. **Claim: extracting the current KeyDown code automatically implements “LCL zeroes the key ⇒ TRUE.”**

   **Evidence:** The current CN branch explicitly returns **FALSE for entry/memo**, even when `DeliverMessage` reports handled or `Msg.CharCode = VK_UNKNOWN`: [gtk4widgets.pas:3896](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3896). OnKeyDown runs in this CN path, through `KeyDownBeforeInterface`; setting `Key := 0` makes CN_KEYDOWN handled: [wincontrol.inc:5883](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5883), [wincontrol.inc:7251](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7251).

   The later LM zero-key check at line 3930 cannot repair an earlier CN exit. A handled shortcut can also return a nonzero result without zeroing the key.

   **Verdict: plan wrong/incomplete.** A behavior-preserving extraction retains this bug. The capture policy must distinguish CN consumption from the arrow bypass and stop native processing for handled shortcuts as well as zeroed keys. The proposed Return eatlist test directly exercises this problem.

5. **Claim: retaining the Tab early exit preserves behavior while applying Return/Tab/Escape ownership.**

   **Evidence:** Tab exits FALSE before any CN/LM/CHAR delivery and before `FKeysToEat`: [gtk4widgets.pas:3846](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3846). Its behavior depends on `Sender^.is_focus`; the existing callback supplies the outer controller widget, whereas delegate capture supplies GtkText: [gtk4widgets.pas:1921](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1921). GTK window Tab bindings remain available: [gtkwindow.c:1255](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwindow.c:1255).

   **Verdict: plan wrong.** Retaining that exit cannot also deliver Tab and consume it through `FKeysToEat`. Changing `Sender` also invalidates the blanket “no behavior change” argument. Actual focus movement needs verification, including Shift+Tab.

6. **Claim: consuming nonprintable keys before TARGET leaves IM behavior untouched.**

   **Evidence:** TRUE from capture prevents the TARGET controller from running, including its IM filter: [gtkwidget.c:4581](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkwidget.c:4581), [gtkeventcontrollerkey.c:99](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:99).

   Return is an IM composition key. GtkIMContextSimple explicitly recognizes Return/ISO_Enter/KP_Enter as Unicode-input terminators and commits a pending character in its hex-input path: [gtkimcontextsimple.c:881](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkimcontextsimple.c:881), [gtkimcontextsimple.c:1049](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkimcontextsimple.c:1049). GtkText also conditionally resets its IM on Return/Escape after filtering: [gtktext.c:3226](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:3226).

   Upstream fcitx-hangul selects candidates on Return and processes otherwise-unused keys through its preedit flush path: [engine.cpp:339–447](https://github.com/fcitx/fcitx5-hangul/blob/master/src/engine.cpp#L339). Thus an active composition can need Return to reach the IM. Merely leaving `insert-text` code unchanged does not preserve that behavior.

   **Verdict: plan wrong.** An IM-aware exception/order is missing. Exact behavior of the installed fcitx packages remains **unverifiable without matching sources/runtime testing**; the GTK source alone already disproves unconditional IM noninterference.

7. **Claim: suppressing GtkText/GtkEntry activation removes no backend dependency, apart from spin update.**

   **Evidence:** GtkText’s Return bindings emit `activate`; void signal actions count as handled: [gtktext.c:1423](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:1423), [gtkshortcutaction.c:825](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkshortcutaction.c:825). GtkEntry forwards that signal: [gtkentry.c:1428](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkentry.c:1428). `activates-default` defaults FALSE: [gtktext.c:799](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtktext.c:799).

   I found **no backend GtkEntry/GtkText activate connection or activates-default setter**. The backend’s actual activate connections are the menu action and combo list: [gtk4widgets.pas:8468](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:8468), [gtk4widgets.pas:12551](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:12551).

   Spin’s GTK-internal connection is real, and its handler updates only when editable: [gtkspinbutton.c:1030](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1030), [gtkspinbutton.c:1487](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1487).

   **Verdict: plan OK for plain entry activation; incomplete for spin.** Explicit spin update must preserve the editable condition and distinguish policy-owned Return from Return explicitly vetoed by LCL. Updating unconditionally after a veto defeats the veto. It also requires post-callback lifetime checks.

8. **Claim: adding `wtEntry` to TGtk4SpinEdit safely supplies entry key semantics and removes its extra IM context.**

   **Evidence:** It does change the intended key/IM branches. But the same flag controls a mouse capture path that calls `gtk_entry_grab_focus_without_selecting(PGtkEntry(AWidget))`: [gtk4widgets.pas:1541](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1541). That controller is attached to `FWidget`: [gtk4widgets.pas:4774](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4774). Spin creates a GtkSpinButton: [gtk4widgets.pas:6740](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6740). GTK’s entry function requires `GTK_IS_ENTRY`: [gtkentry.c:1911](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkentry.c:1911).

   **Verdict: plan wrong.** The flag also introduces an invalid GtkSpinButton→GtkEntry API call. Audit/update that path or use a separate key/IM capability condition.

9. **Claim: delegate capture interferes with the open editable-combo transaction.**

   **Evidence:** The entry and popover are separate branches beneath the combo box: [gtk4widgets.pas:12032](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:12032), [gtk4widgets.pas:12082](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:12082). The popover takes child focus/grab: [gtkpopover.c:1051](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkpopover.c:1051). SAME_NATIVE filters controllers outside the target’s native: [gtkeventcontroller.c:289](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:289).

   Return activates a list row and reaches `CommitSelection`; Escape closes the popover, allowing the visibility handler to restore the committed selection: [gtklistitemwidget.c:286](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtklistitemwidget.c:286), [gtk4widgets.pas:12000](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:12000), [gtkpopover.c:781](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkpopover.c:781), [gtk4widgets.pas:11972](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:11972).

   **Verdict: plan OK for isolation; I found no direct conflict in the normal open-popup path.** The latest plan’s wording that Return/**Escape** both confirm through `Gtk4ECB_ListActivate` is wrong: Escape cancels. Retain the runtime gate for popup opening/closing and focus transitions.

10. **Claim: leaving printable presses record-only preserves the existing recorder and deferral.**

    **Evidence:** Every press overwrites the recorder; Ctrl/Alt presence controls pending status, while only printable Unicode fills pending text: [gtk4widgets.pas:6183](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6183). Therefore a modifier-only press can legitimately produce `Pending=True, Text=''`; pending does **not** mean printable. Every release clears both fields: [gtk4widgets.pas:6195](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6195).

    Deferral depends on the pending gate and exact text/preedit comparisons, not key delivery state: [gtk4widgets.pas:6328](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6328). Repeated presses refresh the recorder; repeat detection separately updates `FLastKeyVal/FLastKeyPress`: [gtk4widgets.pas:3829](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3829).

    **Verdict: plan OK for direct field preservation.** I found no inherent modifier-only or repeat corruption if recording remains unconditional and dispatch state stays separate. Do not clear pending merely because the key was delivered, or update repeat state twice. Overall IM preservation is still false for the reasons in finding 6.

    Also, the combo insert hook only performs deferral—it does **not** generate entry-style OnKeyPress events: [gtk4widgets.pas:12270](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:12270). The plan’s “delegate insert-text already handles characters” explanation must not be generalized to combo character notifications.

11. **Claim: GtkEventKey can be split using a simple handled Boolean without altering behavior.**

    **Evidence:** These are the control-flow couplings in [GtkEventKey, gtk4widgets.pas:3778](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3778):

    | Source lines | Behavior the split must preserve |
    |---|---|
    | 3800–3844 | Initial FALSE result; string-derived modifier repair; system-key selection; repeat-state mutation; key translation. These must happen once. |
    | 3846–3851 | Tab exits FALSE and skips all subsequent processing. |
    | 3855–3869 | Handled context menu exits TRUE before CN/LM/CHAR. |
    | 3882–3952 | Unknown translated keys skip CN/LM but can still reach CHAR; their zero-initialized key message supplies CHAR KeyData and final eat-key input. |
    | 3896–3905 | CN handled/zero/arrow exits the entire function; entry/memo return FALSE, others TRUE. This applies to releases too. |
    | 3914–3915 | LM CharCode/KeyData are rebuilt from the original translation; a nonzero CN key replacement is not simply propagated. |
    | 3922–3937 | Native-control LM result is ignored; zero CharCode consumes. Memo `WantReturns=False` consumes Return before CHAR. |
    | 3940–3946 | Other controls’ nonzero LM result exits even with FALSE return, skipping CHAR and FKeysToEat. |
    | 3954–3960 | CHAR requires a press, nonempty string, and exclusion of navigation/Insert/Delete/F-key ranges. |
    | 3963–3973 | IntfUTF8KeyPress TRUE exits. Its modified UTF8 string is not used to construct the subsequent classic character; that uses original `AEventString`. |
    | 3976–3997 | CN_CHAR nonzero result or zero CharCode exits TRUE; otherwise its modified CharCode continues into LM_CHAR. |
    | 4008–4033 | LM_CHAR’s return value is ignored. Memo replacement recording uses the original character and surviving changed CharCode, including CR↔LF conversion. |
    | 4035–4043 | Only fallthrough presses assign `Result := Msg.CharCode in FKeysToEat`; this is the **key** message, not CharMsg. Empty event strings can still reach it. Releases do not execute it. |
    | 3893, 3907, 3919, 3929, 3949, 3965, 3984, 3989, 4005, 4010 | Lifetime checks terminate the function with its current result. A wrapper must not continue into CHAR afterward. |

    **Verdict: unverifiable until the helper contract is specified.** A behavior-preserving split is possible, but FALSE currently means both “continue” and “stop processing while allowing GTK.” A Boolean alone cannot encode that distinction.

12. **Claim: TEdit/TComboBox request DLGC_WANTARROWS, so LCL would not navigate after full CN+LM delivery.**

    **Evidence:** Their `CMWantSpecialKey` arrow overrides are **Darwin-only**: [customedit.inc:509](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:509), [customcombobox.inc:1238](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customcombobox.inc:1238). Neither supplies the claimed ordinary-edit LM_GETDLGCODE behavior; GTK4’s default handler is empty: [gtk4wscontrols.pp:394](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4wscontrols.pp:394).

    `DoArrowKey` can navigate when its remaining conditions hold: [application.inc:2114](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/application.inc:2114). It is reached through LM_KEYDOWN: [wincontrol.inc:5937](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5937). Qt normally skips that LM arrow delivery: [qtwidgets.pas:3202](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:3202), [qtwidgets.pas:3565](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:3565), [qtwidgets.pas:5553](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:5553).

    **Verdict: original plan wrong; latest correction OK.** Preserve CN-only arrow delivery. Consuming unhandled Up/Down in a plain edit prevents GTK window focus movement; spin must allow its change-value bindings unless LCL vetoed the key. Combo focus retention alone is not complete Qt/GTK2 equivalence: the matrix records native selection changes, notably [matrix_full.txt:60](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:60).

13. **Claim: GtkIMContextSimple consumes plain space/letters without preedit, preventing checkbox shortcuts.**

    **Evidence:** For a single ordinary printable key, `no_sequence_matches` converts it to Unicode, emits commit, and returns TRUE: [gtkimcontextsimple.c:729](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkimcontextsimple.c:729). Space satisfies this condition. The controller then exits before emitting `key-pressed`: [gtkeventcontrollerkey.c:99](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:99). The LCL controller is added after class shortcuts and runs first; checkbox activation shortcuts are installed by the class: [gtk4widgets.pas:4722](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4722), [gtkcheckbutton.c:640](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkcheckbutton.c:640).

    The measured checkbox space row shows U8 without toggle: [matrix_full.txt:272](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:272).

    **Verdict: plan OK.** No preedit is required for this failure.

14. **Claim: manually filtering after LCL delivery reproduces GTK2 and resolves native space activation.**

    **Evidence:** GTK2 calls `CheckDeadKey` at line 2308, before its CN_KEYDOWN delivery at 2368–2382. `CheckDeadKey` calls `gtk_im_context_filter_keypress` without using its Boolean result: [gtk2proc.inc:2199](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:2199), [gtk2proc.inc:2305](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:2305), [gtk2proc.inc:2368](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:2368).

    **Verdict: plan wrong about GTK2 order; incomplete as a fix.** Moving the filter after LCL may restore KeyDown, but returning its TRUE result still blocks the checkbox’s space shortcut. Conversely, ignoring all IM results can leak composition keys into native actions. The plan must specify that distinction.

15. **Claim: the proposed conversion changes produce Ctrl+A KeyPress #1 and full ISO_Enter support.**

    **Evidence:** GTK4 obtains character text solely from `gdk_keyval_to_unicode(keyval)`, without Ctrl conversion: [gtk4widgets.pas:1886](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1886). Ctrl+A therefore supplies `"a"` to CHAR, as the existing checkbox matrix confirms: [matrix_full.txt:274](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:274). GTK2 has separate control-character conversion: [gtk2proc.inc:1918](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:1918).

    `GdkKeyToLCLKey` maps Return/KP_Enter/3270_Enter, but **not ISO_Enter**: [gtk4procs.pas:666](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4procs.pas:666).

    **Verdict: plan wrong/incomplete.** Capture delivery alone gives Ctrl+A KD65 but not KP#1. ISO_Enter needs virtual-key mapping as well as `string_ := #13`; otherwise it skips CN/LM and misses Return ownership/default-button bookkeeping.

16. **Claim: GTK2/Qt5 establish unconditional shared ownership of Return/Tab/Escape.**

    **Evidence:** GTK2’s `EmulateEatenKeys` synthesizes LM_KEYDOWN for Return/Tab but does not unconditionally stop the native event: [gtk2proc.inc:2159](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:2159). Final consumption is `EventStopped`: [gtk2proc.inc:2553](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2proc.inc:2553).

    Qt’s `KeysToEat` assignment is a **fallthrough** rule. Earlier LM handling can exit FALSE, and changed keys can be sent through `SendChangedKey`: [qtwidgets.pas:3572](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:3572), [qtwidgets.pas:3665](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/qt5/qtwidgets.pas:3665).

    **Verdict: plan wrong as an unconditional reference claim.** Normal Qt Return ownership supports the intended policy; neither reference proves “all these keys always bypass native processing.”

17. **Claim: Phase 2 changes only TEdit; spin adjustments can wait until Phase 3.**

    **Evidence:** `TGtk4SpinEdit` inherits `TGtk4Entry`: [gtk4widgets.pas:296](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:296). Entry initialization attaches the shared callbacks using `Self`: [gtk4widgets.pas:6544](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6544).

    **Verdict: plan wrong unless Phase 2 explicitly excludes spin.** Otherwise capture delivery/consumption starts affecting spin before its Return update and arrow exceptions exist. Move those dependencies together or specify an opt-in gate.

    Phase 0’s priority is justified, but its description should identify the actual getter side effect: `GetValue` calls **update**, not directly `set_value`: [gtk4widgets.pas:6683](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6683).

18. **Claim: the phase gates establish behavior preservation and allow each stage to be rolled back independently.**

    **Evidence:** The baseline “edit” run moves focus to spin on Down; subsequent rows explicitly name spin, and its FINAL is missing: [matrix_full.txt:3](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:3), [matrix_full.txt:11](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:11). The runner sends keys sequentially without restoring the target between keys: [run.sh:13](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/run.sh:13). The analyzer’s crash detection is textual, and `!!` compares compact signatures rather than correctness: [analyze.py:13](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/analyze.py:13), [analyze.py:60](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/analyze.py:60).

    Phase 1 also changes shared character conversion and therefore memo KP_Enter behavior despite the “memo untouched” statement; its current row lacks the character notifications that the change would add: [matrix_full.txt:108](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/matrix_full.txt:108).

    **Verdict: plan wrong/incomplete as a verification gate.** Require successful process completion and FINAL, isolated per-key target tests alongside navigation sequences, and explicit expected signatures. Add gates for consumed-key releases, CN/KeyPreview vetoes, repeat, Shift+Tab, spin mouse focus, and active-preedit Return/Escape/arrows. IM verification must precede accepting capture consumption. Separate the pure extraction from conversion changes so “behavior unchanged” has a meaningful baseline. The plan already provides rollback commits; I found no missing rollback statement.