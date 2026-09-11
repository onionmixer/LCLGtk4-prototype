The getter change removes the reported recursion, and both `>=` comparisons should become `>`. However, leaving `CreateWidget` unchanged is unsafe for `Max < Min` and fractional increments. The verification gate also misses consequences of letting entry text and the GTK adjustment diverge.

This was a source-only review; no files changed and no runtime tests were run. Links below refer to the current sources.

1. **The parsed-text getter breaks the reported recursion.**

   **Evidence:** [gtk4widgets.pas:6683](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6683) calls `update` before `get_value`. GTK’s [gtkspinbutton.c:2397](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:2397) parses and calls `set_value`; [gtkspinbutton.c:1688](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1688) rewrites differing text. [gtkeditable.c:607](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeditable.c:607) implements replacement as deletion followed by insertion, explaining the transient empty text.

   The return path is `Gtk4EntryChanged → CM_TEXTCHANGED → TextChanged → Value`: [gtk4widgets.pas:6106](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6106), [spinedit.inc:70](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:70). `StrToValue` only parses and limits; it does not write the widget ([spinedit.inc:240](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:240)).

   **Verdict: plan OK.** The source supports the cycle and its removal. The reported 118 cycles were not independently reproduced.

2. **Return, focus-out and `EditingDone` retain explicit synchronization paths; native key release and mnemonic activation do not themselves call `update`.**

   **Evidence:** LCL Return handling invokes `EditingDone` in [customedit.inc:460](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:460). Focus loss invokes it when the parent form is active and the control is outside loading/destruction/design mode ([wincontrol.inc:6824](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:6824)). Spin `EditingDone` calls `UpdateControl` before inherited processing ([spinedit.inc:46](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:46)); the widgetset then assigns the LCL value to GTK ([gtk4wsspin.pp:205](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4wsspin.pp:205)).

   GTK 4.6.9 calls `gtk_spin_button_update` at:
   - Editable button press: `gtkspinbutton.c:929`.
   - Editable focus-out: `gtkspinbutton.c:999`.
   - Keyboard `change-value`, before and after spinning: `gtkspinbutton.c:1383,1460`.
   - Editable entry activation: `gtkspinbutton.c:1493`.
   - Enabling snap-to-ticks while editable: `gtkspinbutton.c:2251`.

   These are the call sites found in [gtkspinbutton.c](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c). Its key-release handler only resets acceleration counters (`984–992`); mnemonic activation only grabs entry focus (`339–344`).

   **Verdict: plan OK for these commit paths.** I found no requirement that an LCL value read must perform native `update`. Exact event ordering and invalid-text results still require runtime verification.

3. **The proposed getter is equivalent to GTK2 for floating-point text and comma separators, provided both separator replacements are copied.**

   **Evidence:** [gtk2wsspin.pp:95](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk2/gtk2wsspin.pp:95) reads text, replaces both `.` and `,` with `DefaultFormatSettings.DecimalSeparator` where necessary, and calls `StrToValue`. It explicitly documents the distinction between float text and native value. GTK4’s virtual [getText at gtk4widgets.pas:6452](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6452) reads the editable text without modifying it.

   `StrToValue` does not round to `DecimalPlaces`; it parses and applies LCL limits. Empty/invalid text falls back to cached `FValue`, then applies limits. Consequently, “FINAL is the text parsing value” in §12.3 needs an explicit fallback expectation.

   GTK’s parser instead uses `g_strtod` ([gtkspinbutton.c:1648](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1648)); its numeric insertion filter uses C `localeconv()` (`1518`, `1581`). Getter equivalence therefore does **not** prove that all typing, paste and native commit paths accept the same separator, especially if Pascal and C locale settings differ.

   **Verdict: plan OK for getter equivalence; end-to-end locale behavior unverifiable without execution.**

4. **The two `>` changes correctly implement LCL range semantics, but are not the complete construction fix.**

   **Evidence:** LCL limits only when `FMaxValue > FMinValue` ([spinedit.inc:223](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:223)). GTK2 follows this in both `SetReadOnly` and `UpdateControl` (`gtk2wsspin.pp:160,206`).

   The complete spin-range inventory found in GTK4 is:
   - `gtk4wsspin.pp:144–153`: derive and restore editable bounds.
   - `gtk4wsspin.pp:196–211`: derive and apply update bounds.
   - `gtk4wsspin.pp:141,216`: intentional ReadOnly collapse to `Value..Value`.
   - `gtk4widgets.pas:6740`: constructor passes raw control bounds.
   - `gtk4widgets.pas:6753–6758`: `SetRange` forwards its arguments without normalization.

   I found **nothing in `gtk4wsstdctrls.pp` deriving spin bounds or calling spin `set_range`**. Its generic edit ReadOnly setter merely delegates to the editable wrapper (`1285–1290`). Other range-related search results concern scrollbars/ranges, not spin controls.

   **Verdict: plan OK for both comparisons and intentional ReadOnly collapse; plan wrong if described as complete across construction.**

5. **Default `0..0` does not reject construction or defeat the normal first explicit `SetValue`; “immediately overwritten” nevertheless needs qualification.**

   **Evidence:** GTK accepts equal bounds and creates an adjustment initially equal to `min` ([gtkspinbutton.c:1834](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1834)). There is no spin `set_value` in `CreateWidget`.

   LCL keeps `wcfCreatingHandle` set across handle creation and `InitializeWnd` ([wincontrol.inc:7573](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7573)); spin `GetValue` avoids native reads during that interval (`spinedit.inc:173–181`). Inherited edit initialization invokes widgetset `SetReadOnly` **before** spin `UpdateControl` ([customedit.inc:41](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:41), `spinedit.inc:108–112`). With the proposed comparison fix, editable initialization already expands the range; ReadOnly initialization collapses it to cached `Value`. `UpdateControl` subsequently sets the range before assigning the value (`gtk4wsspin.pp:211–212`).

   However, core `UpdateControl` defers widgetset work while loading/destroying, and `Loaded` processes `FUpdatePending` ([spinedit.inc:13](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:13), `114–118`). `FUpdatePending` is **not** itself a native-read guard in `GetValue`.

   **Verdict: plan OK for ordinary default initialization.** I found no first explicit value assignment preceding range setup in that path. Universal safety during early handle creation/loading is **unverifiable from the cited measurement**.

6. **Leaving `CreateWidget` unchanged fails valid LCL configurations.**

   **Evidence:** [gtk4widgets.pas:6730](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6730) casts the control to `TCustomSpinEdit`, then reads its integer properties. Those getters round the underlying double increment and bounds ([spinedit.inc:257](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/spinedit.inc:257)).

   Two concrete failures follow:
   - `MinValue=10, MaxValue=0`: LCL treats this as unrestricted, but GTK rejects `min > max`.
   - `TFloatSpinEdit.Increment=0.25`: the constructor sees zero, and GTK rejects `step == 0`.

   Both constructor checks return `NULL` (`gtkspinbutton.c:1834–1835`), before any later `UpdateControl` can repair the widget. Fractional bounds also arrive rounded.

   **Verdict: plan wrong.** Construction needs the float base type and valid initial GTK bounds. A `5.25` round-trip using the default increment of `1` will miss this defect.

7. **Removing getter-side synchronization changes native wheel behavior.**

   **Evidence:** GTK’s [scroll handler at gtkspinbutton.c:859](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:859) calls `real_spin` directly, without `update`. `real_spin` adds the increment to the **adjustment value** (`1607`). Swipe handling likewise calls `real_spin` directly (`855`).

   After the proposed change, typing can update LCL `FValue` while leaving the adjustment unchanged. Thus, with adjustment `5` and edited text `12`, a native upward wheel step can produce `6` instead of `13`, if scrolling reaches GTK before a commit. Button presses and keyboard spin actions have explicit pre-update calls; scrolling does not.

   **Verdict: plan wrong if it claims no synchronization behavior changes.** This is a source-derived consequence; actual LCL scroll delivery needs runtime verification. Add edit-then-wheel coverage.

8. **`UpdateControl` can overwrite the parsed value before its final value assignment.**

   **Evidence:** [gtk4wsspin.pp:207](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4wsspin.pp:207) sets digits, step and range **before reading** `ACustomFloatSpinEdit.Value` for assignment. Changing GTK digits emits formatted output from the current adjustment ([gtkspinbutton.c:1910](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkspinbutton.c:1910)); clamping a range can also change the adjustment and output.

   `BeginUpdate` only increments a counter ([gtk4objects.pas:959](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4objects.pas:959)). Neither `Gtk4EntryChanged` nor `TGtk4Widget.DeliverMessage` checks that counter (`gtk4widgets.pas:6106,5049`).

   Consequently, after typing `12.34` while the native adjustment remains `5`, changing `DecimalPlaces` can output `5.000`; its notification replaces LCL `FValue` before line 212 reads it. The plan exposes this stale-adjustment case by separating parsing from native synchronization.

   **Verdict: plan wrong as a complete preservation claim.** The design needs explicit handling and verification of value preservation across native formatting/range changes.

9. **The pure getter does not intrinsically conflict with pending selection or IM deferral.**

   **Evidence:** Spin inherits `TGtk4Entry` (`gtk4widgets.pas:296`). `getText` neither flushes deferred input nor applies selection (`6452–6458`). Pending selection remains applied after LCL message delivery (`5957–5965`), by idle (`5924–5930`), before deferred IM insertion (`6228`), and before spin setters that rewrite text (`6698,6725,6757`).

   `ApplyPendingSelStart` itself can re-enter LCL through cursor-position notification (`5949–5954`), so retaining it in an otherwise pure getter would retain an unnecessary side effect. The IM queue has separate commit/preedit/focus-leave flush paths (`6247–6286`).

   **Verdict: plan OK.** I found no getter dependency requiring the old selection flush. Real IM ordering remains **unverifiable without execution**, particularly where native focus-out formatting meets deferred insertion.

10. **No second unconditional getter recursion was found, but nested setter notifications remain possible.**

    **Evidence:** Searching the implementation found one spin `update` call: `gtk4widgets.pas:6689`. After its removal, the remaining wrapper mutations are `set_value` (`6726`), `set_range` (`6758`), and formatting through `set_digits` (`6699`), reached from the widgetset setters above.

    Plain `TextChanged → GetValue` becomes non-mutating. However, inherited `TextChanged` calls `Change`, which invokes application `OnChange` handlers ([customedit.inc:611](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:611)). Such a handler can set `Value`, bounds or ReadOnly and re-enter native formatting; `BeginUpdate` does not suppress that route.

    Also, §12.1 misidentifies GTK2’s protected `update` location: lines `172–176` belong to **`SetReadOnly`**, called by `UpdateControl` at `234`.

    **Verdict: plan OK for removing the identified unconditional cycle.** I found no second built-in unconditional cycle of that form. A blanket claim that all reentrancy is eliminated would be **unverifiable**.

11. **§12.3 is insufficient to prove the full fix.**

    **Evidence:** [PLAN_GTK4_KEY_PREDISPATCH.md:443](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:443) covers crash-free key runs, final integer value, one float round-trip and ReadOnly locking. It does not cover the source-derived failures above.

    Add explicit assertions for:

    - `TFloatSpinEdit` fractional increments/bounds before handle creation.
    - Equal nonzero bounds, `Max < Min`, negative-only valid ranges, and loading/recreation.
    - Dot/comma locales, typing and paste, with values checked before and after Return/focus-out.
    - Empty, sign-only, invalid and out-of-range text, including the expected cached-value fallback.
    - Edit-then-wheel and edit-then-change-digits/range.
    - ReadOnly on/off after editing, programmatic value changes while ReadOnly, and `EditorEnabled=False`.
    - Pending `SelStart`/`SelLength` around value reads and IM commit/focus transitions.
    - Notification values/counts during native text replacement, not merely absence of crashes.

    **Verdict: plan wrong if this gate is treated as sufficient proof.** It is a useful smoke test, but misses construction failures and value-loss paths.