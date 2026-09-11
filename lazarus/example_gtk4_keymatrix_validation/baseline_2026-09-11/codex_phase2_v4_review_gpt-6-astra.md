**V4 is not acceptable to implement verbatim.** The S+H approach is viable, but replay exits and reentrant release handling currently break its invariants. No files were changed. `gtk4widgets.pas` changed externally during the review; references below use the latest read.

1. **Claim: GTK’s set has exactly the stated mutation paths. → Evidence:** [gtkeventcontrollerkey.c:99](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:99) filters IM events before emitting signals; lines 120–133 add only after a handled press and remove after every release emission. The only other accesses are initialization and finalization. `handle_crossing` changes IM focus, without touching the set; the key controller installs no reset implementation. Base [gtkeventcontroller.c:436](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:436) calls reset only when implemented.

   The recorder has exactly one press handler and one release handler, with **no IM context assigned**, at [gtk4widgets.pas:6603](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:6603). The other key handlers belong to separately constructed controllers. The accumulator stops at the first TRUE ([gtkprivate.c:130](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkprivate.c:130)); an earlier FALSE cannot override our TRUE, and an earlier TRUE would prevent our handler from running.

   **Verdict: plan OK for these GTK facts.** Keeping S across focus changes is correct. The implementation ordering below prevents the stronger “exact mirror” claim from holding.

2. **Claim: replay exits preserve S. → Evidence:** [Plan:711](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:711) returns the cached press result before adding to S; line 717 returns for a cached release before removing from S. GTK still performs its normal post-signal mutation.

   Two counterexamples, entirely within H’s window:

   - Consumed press P → release R → replay P. The replay returns TRUE, so GTK adds the keyval again; S remains empty. A subsequent fresh release is swallowed without capture delivering KeyUp.
   - Consumed press P → release R → new consumed press Q with the same keyval → replay R. GTK removes the keyval; S incorrectly retains it.

   The replay press also bypasses pending-field cleanup after the recorder has just set those fields. Furthermore, checking the mutable preedit guard before H can return FALSE for a previously consumed event.

   **Verdict: plan wrong.** Replay suppression must skip **LCL delivery**, not GTK-mirroring bookkeeping. Route every TRUE press return through one finalizer that adds S and clears pending fields; route every release return through removal from S. Check H before the preedit eligibility decision for previously delivered events.

3. **Claim: removing S before release delivery exactly predicts GTK swallowing. → Evidence:** [Plan:718](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:718) removes before calling LCL, whereas [gtkeventcontrollerkey.c:129](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontrollerkey.c:129) checks/removes only **after the callback returns**.

   Start with S = GTK = `{k}`. Outer release removes `k` from S and delivers KeyUp. Its handler pumps messages:

   - A nested consumed press of `k` adds it to both sets. Outer release then returns; GTK removes `k`, leaving S incorrectly populated.
   - Alternatively, a distinct nested release of `k` sees empty S and gets no capture KeyUp, but GTK still has `k` and swallows that nested release. The outer release subsequently is **not** swallowed.

   **Verdict: plan wrong.** Keep S unchanged while delivering the release; remove its keyval immediately before returning, on every exit path. This mirrors GTK at callback boundaries. Even then, membership **at callback entry** cannot unconditionally predict swallowing **after nested dispatch**.

   A capture-delivered outer KeyUp reaching bubble is not automatically duplicated: H suppresses it while retained. Thus H remains necessary even with corrected S.

4. **Claim: owned refs make event-pointer identity exact. → Evidence:** [gdkevents.c:855](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:855) increments the refcount and returns the same pointer; destruction happens only on the final unref. [gdkdisplay.c:484](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkdisplay.c:484) queues that same object by reference.

   **Verdict: plan OK for object identity while retained.** Address reuse cannot cause false matches. This proves identity of objects, not identity of all logical redispatches.

5. **Claim: GTK never replaces a queued key event before capture. → Evidence:** [gtkmain.c:1053](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1053) explicitly constructs a new key event when the original surface has a parent, rewriting it to the ancestor toplevel. Lines 1573–1580 replace the event before focus targeting and propagation. There is no `gdk_event_copy`/`rewrite_key_event` call here; the relevant constructor is `gdk_key_event_new`.

   [gtkeventcontroller.c:365](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:365) stores a ref to the event actually being dispatched, and its getter at line 606 returns that pointer. Capture and bubble therefore see the **same rewritten object** during one propagation.

   Requeuing that controller/IM-visible, already rewritten object preserves identity: its surface is already the toplevel. Requeuing the **original popup-surface object** causes another rewrite and another pointer, which H cannot recognize.

   **Verdict: plan OK for bubble identity and replay of the controller-visible object; plan wrong if claiming universal queued-event replay identity.**

6. **Claim: H covers nested replay and cannot lose the outer dedup marker. → Evidence:** The actual [v4 sequence:712](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:712) appends **after** delivery. It does not currently specify the “look up again and update” sequence in the question. Consequently, eight nested events cannot evict that not-yet-added outer entry—but a nested replay during delivery finds no entry and delivers again.

   With the proposed append-before-delivery variant, relookup by event pointer avoids stale array indexes, but an evicted entry means lost outcome storage and deduplication. Holding only another event ref prevents object destruction; it does not preserve H membership.

   **Verdict: plan wrong for full reentrancy protection.** Minimal correction: register an owned entry before delivery, mark it in progress, pin it against eviction, update by event pointer, and retain/reinsert it as newest on completion. Never retain an array-element address across delivery.

   Document the provisional press outcome: a nested replay cannot know the unfinished outer call’s eventual result. Returning provisional FALSE prevents duplicate LCL delivery but may permit native processing before the outer call eventually consumes.

   Also, pinning only until capture returns does not prove protection through bubble: native processing or another controller can reenter between those phases ([gtkmain.c:1912](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkmain.c:1912)). A strict guarantee requires retention through propagation completion, or an explicit bounded limitation. A hard eight-entry ceiling cannot guarantee arbitrary nesting. Modal/message-pumping handlers make eight intervening events plausible; their frequency is not established by these sources.

7. **Claim: `get_current_event` can safely be fetched again after nested delivery. → Evidence:** [gtkeventcontroller.c:365](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gtk/gtkeventcontroller.c:365) assigns one `priv->event` slot and clears it after handling; it does not save and restore the outer slot. Same-controller nested dispatch overwrites and then clears it.

   **Verdict: plan OK only with the stated pre-delivery lookup.** Capture and own the event before calling LCL; use that saved pointer afterward. Do not refetch it after delivery. Any separate active-call reference must be released without dereferencing a destroyed wrapper.

8. **Claim: replays arriving after eight delivered events are practically impossible. → Evidence:** [gdkdisplay.c:490](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkdisplay.c:490) appends the reference to the queue. It provides no eight-event deadline or relationship to LCL deliveries. GTK’s source alone does not establish the installed fcitx module’s asynchronous timing.

   **Verdict: unverifiable.** Describe eight as a bounded replay cache, not a correctness guarantee. Ownership still prevents false identity matches; eviction permits missed replays.

9. **Claim: inherited teardown has stopped recorder callbacks before H is cleared. → Evidence:** [gtk4widgets.pas:4881](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4881) calls `DetachEvents` before `DestroyWidget`. Base detach disconnects only `FIMContext`; [DestroyWidget:4602](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:4602) disconnects signals on `FWidget`, not its delegate controller. The destructor unregisters wrapper liveness before this sequence, at line 4921, but that guards callbacks rather than disconnecting them.

   **Verdict: plan wrong if “override or destructor” means simply clearing H there.** Retain a safely managed recorder-controller handle; explicitly disconnect its callbacks in the entry detach override, then clear H/S. Disconnect other delegate callbacks carrying `Self` as appropriate. Already executing callbacks still need the post-delivery liveness check and independently owned local-reference cleanup.

   **Late event unref itself is plan OK:** events own their surface/device ([gdkevents.c:413](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdkevents.c:413)); key events use the base finalizer, which releases those references at line 139. The surface owns its display ([gdksurface.c:761](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/gtk-4.6.9/gdk/gdksurface.c:761)). Native-surface destruction or display closure does not invalidate these owned GObjects.

10. **Claim: the liveness exit preserves the press outcome. → Evidence:** [Plan:712](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/PLAN_GTK4_KEY_PREDISPATCH.md:712) checks liveness before combining `Consumed`, `Handled`, and forced Up/Down consumption. Current [GtkEventKey:3944](/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4/lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:3944) can set `Handled=True`, detect destruction, and return FALSE. The outer early exit then loses that observed consumption.

    **Verdict: plan wrong.** Combine the local outcome values before the outer liveness exit; touch S/H/pending fields only afterward if alive. Similarly, the native LM branch currently checks liveness before observing zeroed `CharCode` at lines 3982–3987; observe that local result first if consumption must survive destruction.

    The round-3 CN `AHandled` ordering itself is correct in the latest file. The enabled/spin policy, exclusions, preedit guard for **new** events, and Ctrl/Alt restriction on forced Up/Down consumption need no further change from this review.