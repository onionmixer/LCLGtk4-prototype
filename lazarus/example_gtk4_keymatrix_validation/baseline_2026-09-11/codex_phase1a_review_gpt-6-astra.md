1. **Claim: the default argument preserves behavior. → Verdict: plan OK for runtime behavior.**

   The proposed guards are true for `[kpKeyDown, kpChar]`, so the existing statements retain their order, provided the repeat guard stays **at its current location**.

   The preamble initializes `Result := False`, zeroes `Msg`, copies the event/string, and normalizes keyval at [gtk4widgets.pas:3800][w3800]. Empty-string modifier repair remains unchanged—including the existing Alt-left-only repair—followed by `IsSysKey`, repeat detection/state updates, `KF_UP`, and keyval→VK translation at [gtk4widgets.pas:3812][w3812]. Wrapping these statements does not change their values under the default argument.

   Every exit retains its existing result and still exits the **whole function**:

   | Location in `gtk4widgets.pas` | Existing behavior preserved |
   |---|---|
   | [3850][w3846] | Tab optionally calls `SelectNext`, then returns `False`. |
   | [3868][w3855] | Handled context menu returns `True`. |
   | [3894, 3908][w3891] | Failed validity checks return initial `False`. |
   | [3902–3904][w3891] | Handled/zeroed CN key or arrow returns `False` for entry/memo, otherwise `True`. |
   | [3920, 3929][w3910] | Failed validity checks return `False`. |
   | [3931, 3937][w3928] | Zeroed native-widget key or memo Return with `WantReturns=False` returns `True`. |
   | [3946][w3940] | Other-widget LM handling returns exactly `Msg.CharCode = 0`; a nonzero delivery result alone can still return `False`. |
   | [3950][w3940] | Failed validity check returns `False`. |
   | [3966, 3973][w3954] | Returns the value assigned by `IntfUTF8KeyPress`. |
   | [3985][w3976] | Returns `False`, since successful continuation required an unhandled UTF8 result. |
   | [3990, 3997][w3987] | Returns the CN-character handled/zeroed result. |
   | [4006, 4011][w4000] | Returns `False`; the LM-character delivery result is not assigned to function `Result`. |

   On surviving keypress paths, [gtk4widgets.pas:4035][w4035] still overwrites `Result` with **`Msg.CharCode in FKeysToEat`**, using the possibly modified key message, not `ACharCode` or `CharMsg.CharCode`. Releases skip that assignment.

   `NotifyApplicationUserInput`, delivery, and `CanSendLCLMessage` checks retain their existing order throughout both blocks. **No default-path semantic difference found.** Literal “byte-identical” compiled code is a separate, unjustified claim: the signature and runtime conditions change.

2. **Claim: `[kpChar]` executes an independently usable character block. → Verdict: plan wrong if this implies equivalent character-message data.**

   | Character-block input | Initialization | Character-only outcome |
   |---|---|---|
   | `Msg.KeyData` | Zeroed in preamble; populated only inside K at [3889][w3882] and [3915][w3910] | Remains zero; copied into `CharMsg.KeyData` at [3979][w3976]. |
   | `IsSysKey` | Preamble, [3827][w3812] | Initialized correctly. |
   | `ACharCode` | Preamble translation, [3842][w3842] | Initialized correctly; filters at [3958–3960][w3954] remain valid. |
   | `AEventString` | Preamble, [3803][w3800] | Initialized correctly; K does not modify it. |
   | `UTF8Char`, `AChar`, `CharMsg` | Within C, [3962][w3954], [3977–3981][w3976] | Initialized before use. |

   Thus **`Msg.KeyData` is the missing dependency**, not an uninitialized-memory bug. Today, a known key reaching C normally carries the packed key/modifier/repeat information and low-word `1`; character-only supplies zero. Existing unknown-VK paths already leave it zero. Also, LM delivery receives `Msg` by reference, so today C can inherit handler modifications to `Msg.KeyData` ([gtk4widgets.pas:5049][w5049]).

   **LCL consumers were found:**

   - `TCustomEdit.WMChar` and `TCustomComboBox.WMChar` inspect `KeyDataToShiftState(Message.KeyData)` to choose whether to suppress accelerator processing: [customedit.inc:474][edit474], [customcombobox.inc:512][combo512].
   - Base `WMChar`/`WMSysChar` forward the message through `SendDialogChar`; `TCustomLabel.DialogChar` explicitly requires Alt from that message: [wincontrol.inc:7424][win7424], [wincontrol.inc:7343][win7343], [wincontrol.inc:5999][win5999], [customlabel.inc:281][label281].
   - Crucial nuance: `MsgKeyDataToShiftState` obtains Shift/Ctrl/Meta from live key state, but **Alt from `KeyData`**. Zero does not erase every modifier, but does erase Alt ([lclintf.pas:198][intf198]). An otherwise reachable Alt mnemonic path can consequently fail.
   - **No direct `KeyData` read found** in base `CNChar`, `DoKeyPress`, or `IntfUTF8KeyPress`: [wincontrol.inc:7305][win7305], [5962][win5962], [5119][win5119]. `IntfUTF8KeyPress` instead receives the independently computed `IsSysKey`.

   Guarding repeat detection plus state updates prevents a second call from updating repeat history, but does **not** transfer the original message/repeat metadata into C. That needs an explicit contract before split dispatch is used.

3. **Claim: `[kpKeyDown]` preserves the key portion’s return semantics and leaves current callers unaffected. → Verdict: plan OK, with a narrower return meaning.**

   K’s exits remain identical. If K falls through, skipping C removes its opportunities to consume the event; the return becomes the existing keypress `FKeysToEat` test, or `False` for a surviving release ([gtk4widgets.pas:3954][w3954], [4035][w4035]). For example, a character consumed by `IntfUTF8KeyPress` could return `True` today but `False` in key-only mode when its VK is outside `FKeysToEat`. That is expected partial-execution behavior, not full-event equivalence.

   Case-insensitive search across `lazarus/lcl/interfaces/gtk4/` found **exactly three calls**, with no overrides, method-address references, or additional callers:

   - Press callback assigns the result: [gtk4widgets.pas:1922][w1922].
   - Release callback assigns the result: [gtk4widgets.pas:1947][w1947].
   - Designer callback **ignores** the result and returns `True` unconditionally: [gtk4widgets.pas:1987][w1987].

   All omit the new argument and therefore retain full execution. **No current-caller regression found.** A future dispatcher still cannot distinguish K’s early `exit(False)` from K falling through using this Boolean alone; section 13 explicitly defers that issue ([plan:508][p508]).

4. **Claim: a defaulted set parameter is legal and ABI-safe on this `cdecl` method. → Verdict: plan OK for recompiled Pascal calls and existing GTK connections; plan wrong if “ABI-safe” means binary-compatible.**

   The declaration is **`virtual; cdecl`** ([gtk4widgets.pas:164][w164]); preserve both directives and update the implementation signature.

   Installed FPC 3.2.2 source supports this construction: default-parameter parsing accepts constant expressions without excluding sets ([pdecsub.pas:228][fdefault]); constant parsing explicitly handles `setconstn` ([pdecl.pas:127][fset]); the x86-64 parameter machinery handles small sets as integer arguments ([cpupara.pas:980][fabi]). `cdecl` does not itself make a method a GTK callback; it specifies its calling convention ([FPC documentation](https://docs.freepascal.org/docs-html/current/ref/refsu73.html)).

   Defaults are inserted **at the call site** ([ncal.pas:3821][fcall]). Adding a parameter therefore changes the method’s binary calling contract; previously compiled callers/overrides cannot safely be retained merely because a default exists.

   The actual `TGCallback` casts reference the three standalone Pascal callbacks, whose signatures remain unchanged: [gtk4widgets.pas:4716][w4716], [4723][w4723], [4766][w4766]. **No cast or signal connection to `GtkEventKey` found.**

5. **Claim: no other issue prevents treating Phase 1a as a behavior-preserving preparatory refactor. → Verdict: plan OK for existing callers; plan wrong in two explanatory details; build gates unverifiable.**

   **No hints-as-errors setting found** in the requested build definitions. Both Makefiles use `-vewnhibq`, which displays diagnostics; it is not `-Seh`/`-Sew`: [lcl/Makefile.fpc:80][make80], [gtk4/Makefile.fpc:17][make17]. The actual package is `lazarus/lcl/interfaces/lcl.lpk`; it ignores selected messages and imports `$(IDEBuildOptions)` ([lcl.lpk:128][lpk128]). LCLBase suppresses hints/notes ([lclbase.lpk:18][base18]). Externally supplied options remain unverified.

   **No mode-specific unused-`Msg` issue found.** `AParts` is a runtime parameter, not conditional compilation; `Msg` remains referenced—and C itself reads `Msg.KeyData`.

   Section 13’s tail explanation needs correction ([plan:501][p501]):

   - Skipping T does **not** force character-only `Result := False`; UTF8/CN character handling can already return `True`.
   - `0 in FKeysToEat = False` matches the current constructor default ([gtk4widgets.pas:4596][w4596]), but is not an invariant: `KeysToEat` is publicly writable ([gtk4widgets.pas:215][w215]).

   **No additional default-path defect found.** No files were changed or builds/harnesses run; section 13.4’s empirical acceptance gates remain **unverifiable in this review**.

[w164]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:164
[w215]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:215
[w1922]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1922
[w1947]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1947
[w1987]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:1987
[w3800]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3800
[w3812]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3812
[w3842]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3842
[w3846]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3846
[w3855]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3855
[w3882]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3882
[w3891]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3891
[w3910]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3910
[w3928]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3928
[w3940]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3940
[w3954]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3954
[w3976]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3976
[w3987]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3987
[w4000]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4000
[w4035]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4035
[w4596]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4596
[w4716]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4716
[w4723]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4723
[w4766]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4766
[w5049]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:5049
[edit474]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customedit.inc:474
[combo512]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customcombobox.inc:512
[win7424]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7424
[win7343]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7343
[win5999]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5999
[win7305]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:7305
[win5962]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5962
[win5119]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/wincontrol.inc:5119
[label281]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/include/customlabel.inc:281
[intf198]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/lclintf.pas:198
[p501]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:501
[p508]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:508
[make80]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/Makefile.fpc:80
[make17]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/Makefile.fpc:17
[lpk128]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/lcl.lpk:128
[base18]: /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/lclbase.lpk:18
[fdefault]: /usr/share/fpcsrc/3.2.2/compiler/pdecsub.pas:228
[fset]: /usr/share/fpcsrc/3.2.2/compiler/pdecl.pas:127
[fabi]: /usr/share/fpcsrc/3.2.2/compiler/x86_64/cpupara.pas:980
[fcall]: /usr/share/fpcsrc/3.2.2/compiler/ncal.pas:3821
