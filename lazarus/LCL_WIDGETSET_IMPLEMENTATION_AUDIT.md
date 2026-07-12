# LCL Widgetset Implementation Manual Audit

This document tracks a manual source-level comparison of LCL widgetset behavior across GTK2, Qt5, and GTK4.

The purpose is to identify GTK4 work scope before implementation changes. This is not a mechanically generated coverage report. Every conclusion in this document must be based on direct source review.

## Related Working Documents

The following documents were created or used while checking the current LCL-GTK4 implementation. This audit document is the baseline index; focused validation details and older planning notes should be read through these linked documents when a topic needs reproduction steps or narrower evidence.

### Audit Scope And Rollup

- `PLAN_LCL_WIDGETSET_IMPLEMENTATION_MATRIX.md`
- `PLAN_GTK4_IMPLEMENTATION_CANDIDATE_RECHECK.md`

### Focused Validation Documents

- `PLAN_GTK4_BUTTONS_VALIDATION.md`
- `PLAN_GTK4_CALENDAR_VALIDATION.md`
- `PLAN_GTK4_CHECKLISTBOX_VALIDATION.md`
- `PLAN_GTK4_EDITMEMO_VALIDATION.md`
- `PLAN_GTK4_LISTVIEW_VALIDATION.md`
- `PLAN_GTK4_MENU_VALIDATION.md`
- `PLAN_GTK4_PAGE_STATUS_VALIDATION.md`
- `PLAN_GTK4_PAIRSPLITTER_VALIDATION.md`
- `PLAN_GTK4_PROGRESSBAR_VALIDATION.md`
- `PLAN_GTK4_SCROLLBAR_VALIDATION.md`
- `PLAN_GTK4_SPINEDIT_VALIDATION.md`
- `PLAN_GTK4_STDCTRLS_BUTTONS_VALIDATION.md`
- `PLAN_GTK4_STDCTRLS_LISTCOMBO_VALIDATION.md`
- `PLAN_GTK4_TOOLBAR_VALIDATION.md`
- `PLAN_GTK4_TRACKBAR_VALIDATION.md`
- `PLAN_GTK4_TREEVIEW_VALIDATION.md`
- `PLAN_GTK4_UPDOWN_VALIDATION.md`
- `PLAN_GTK4_WSCONTROLS_VALIDATION.md`
- `PLAN_GTK4_WSDESIGNER_VALIDATION.md`
- `PLAN_GTK4_WSDIALOGS_VALIDATION.md`
- `PLAN_GTK4_WSEXTCTRLS_VALIDATION.md`
- `PLAN_GTK4_WSEXTDLGS_VALIDATION.md`
- `PLAN_GTK4_WSFACTORY_VALIDATION.md`
- `PLAN_GTK4_WSFORMS_VALIDATION.md`
- `PLAN_GTK4_WSGRIDS_VALIDATION.md`
- `PLAN_GTK4_WSIMGLIST_VALIDATION.md`
- `PLAN_GTK4_WSLAZDEVICEAPIS_VALIDATION.md`
- `PLAN_GTK4_WSLCLCLASSES_VALIDATION.md`
- `PLAN_GTK4_WSPROC_VALIDATION.md`
- `PLAN_GTK4_WSREFERENCES_VALIDATION.md`
- `PLAN_GTK4_WSSHELLCTRLS_VALIDATION.md`

### Prior Planning And Fix Documents

- `FIX_GTK4_STARTUP_HIDE_ONSHOW.md`
- `PLAN_GTK4_FONT_CHARSET.md`
- `PLAN_GTK4_KCONTROLS_UPDOWN.md`
- `PLAN_GTK4_TRAYICON_SUPPORT.md`

### Focused Validation Example Directories

- `example_gtk4_buttons_validation/`
- `example_gtk4_calendar_validation/`
- `example_gtk4_checklistbox_validation/`
- `example_gtk4_editmemo_validation/`
- `example_gtk4_hide_onshow/`
- `example_gtk4_kcontrols_componenttest/`
- `example_gtk4_listview_validation/`
- `example_gtk4_menu_validation/`
- `example_gtk4_page_status_validation/`
- `example_gtk4_pairsplitter_validation/`
- `example_gtk4_progressbar_validation/`
- `example_gtk4_scrollbar_validation/`
- `example_gtk4_setlclfonttest/`
- `example_gtk4_spinedit_validation/`
- `example_gtk4_stdctrls_listcombo_validation/`
- `example_gtk4_stdctrls_validation/`
- `example_gtk4_toolbar_validation/`
- `example_gtk4_trackbar_validation/`
- `example_gtk4_trayicon_matrix/`
- `example_gtk4_treeview_validation/`
- `example_gtk4_updown_validation/`
- `example_gtk4_wscontrols_validation/`
- `example_gtk4_wsdesigner_validation/`
- `example_gtk4_wsdialogs_validation/`
- `example_gtk4_wsextctrls_validation/`
- `example_gtk4_wsextdlgs_validation/`
- `example_gtk4_wsfactory_validation/`
- `example_gtk4_wsforms_validation/`
- `example_gtk4_wsgrids_validation/`
- `example_gtk4_wsimglist_validation/`
- `example_gtk4_wslazdeviceapis_validation/`
- `example_gtk4_wslclclasses_validation/`
- `example_gtk4_wsproc_validation/`
- `example_gtk4_wsreferences_validation/`
- `example_gtk4_wsshellctrls_validation/`
- `examples/controlhint/`

## Reference Point

- Reference commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Audit scope: all baseline files listed in `PLAN_LCL_WIDGETSET_IMPLEMENTATION_MATRIX.md`
- Code-change policy for this audit: no GTK4 implementation changes until the scope is understood

## Scope Verification

Verified on 2026-07-09:

- `lcl/widgetset` contains 23 Pascal implementation/contract files plus `README.txt`.
- The 23 Pascal files are all listed in `Full Audit Progress`.
- `README.txt` is excluded from implementation-quality classification because it does not declare widgetset classes or methods.
- No `not_started` or `in_progress` file status remains in the progress table.

## Status Legend

- `usable`: GTK4 behavior appears sufficient for normal LCL use after source comparison.
- `usable_with_limits`: GTK4 implements the important behavior but has documented limitations.
- `partial`: GTK4 implements only part of the expected behavior compared with baseline and GTK2/Qt5.
- `stub_or_noop`: GTK4 method exists but is empty, fixed-result, base no-op delegation, or explicitly not implemented.
- `missing`: Required GTK4 class, registration, method, signal path, or backend support is absent.
- `backend_limited`: The gap is caused by a real GTK4/platform/API limitation and needs fallback or documentation.
- `needs_runtime_test`: Source review is insufficient; a focused runtime test is required.
- `unknown`: The code path is not yet understood safely.

## Manual Review Checklist

For each baseline class/method:

1. Read the baseline declaration and default method body.
2. Read related LCL control/component code when needed.
3. Read GTK2 implementation and factory registration.
4. Read Qt5 implementation and factory registration.
5. Read GTK4 implementation and factory registration.
6. Trace helper/private/include/signal/model code when behavior is delegated.
7. Compare actual behavior, not method existence.
8. Record exact source references and reasoning.

## Full Audit Progress

| Order | Baseline file | Status |
| ---: | --- | --- |
| 1 | `lcl/widgetset/wsbuttons.pp` | reviewed |
| 2 | `lcl/widgetset/wscalendar.pp` | reviewed |
| 3 | `lcl/widgetset/wschecklst.pp` | reviewed |
| 4 | `lcl/widgetset/wscomctrls.pp` | reviewed |
| 5 | `lcl/widgetset/wscontrols.pp` | reviewed |
| 6 | `lcl/widgetset/wsdesigner.pp` | reviewed |
| 7 | `lcl/widgetset/wsdialogs.pp` | reviewed |
| 8 | `lcl/widgetset/wsextctrls.pp` | reviewed |
| 9 | `lcl/widgetset/wsextdlgs.pp` | reviewed |
| 10 | `lcl/widgetset/wsfactory.pas` | reviewed |
| 11 | `lcl/widgetset/wsforms.pp` | reviewed |
| 12 | `lcl/widgetset/wsgrids.pp` | reviewed |
| 13 | `lcl/widgetset/wsimglist.pp` | reviewed |
| 14 | `lcl/widgetset/wslazdeviceapis.pas` | reviewed |
| 15 | `lcl/widgetset/wslclclasses.pp` | reviewed |
| 16 | `lcl/widgetset/wsmenus.pp` | reviewed |
| 17 | `lcl/widgetset/wspairsplitter.pp` | reviewed |
| 18 | `lcl/widgetset/wsproc.pp` | reviewed |
| 19 | `lcl/widgetset/wsreferences.pp` | reviewed |
| 20 | `lcl/widgetset/wsshellctrls.pp` | reviewed |
| 21 | `lcl/widgetset/wsspin.pp` | reviewed |
| 22 | `lcl/widgetset/wsstdctrls.pp` | reviewed |
| 23 | `lcl/widgetset/wstoolwin.pp` | reviewed |

## Reviewed Findings

### 1. `lcl/widgetset/wsbuttons.pp`

#### Baseline Expectation

`TWSBitBtn` declares four widgetset methods:

- `SetGlyph`
- `SetLayout`
- `SetMargin`
- `SetSpacing`

The baseline methods are empty defaults, so usable native behavior depends on widgetset overrides. Source references:

- Baseline declarations: `lcl/widgetset/wsbuttons.pp:50`
- Empty defaults: `lcl/widgetset/wsbuttons.pp:80`, `lcl/widgetset/wsbuttons.pp:85`, `lcl/widgetset/wsbuttons.pp:90`, `lcl/widgetset/wsbuttons.pp:95`
- LCL calls into these methods from `TCustomBitBtn.GlyphChanged`, property setters, and `InitializeWnd`: `lcl/include/bitbtn.inc:194`, `lcl/include/bitbtn.inc:235`, `lcl/include/bitbtn.inc:247`, `lcl/include/bitbtn.inc:270`, `lcl/include/bitbtn.inc:367`
- `TButtonGlyph.GetImageIndexAndEffect` defines state-aware glyph behavior for `bsUp`, `bsDisabled`, `bsDown`, `bsExclusive`, and `bsHot`: `lcl/include/buttonglyph.inc:94`

#### GTK2 Reference

GTK2 registers `TCustomBitBtn` with `TGtk2WSBitBtn` and implements all four methods. The implementation builds a GTK button child hierarchy, updates image/label layout, applies margin through `GtkAlignment`, applies spacing through `GtkBox`, updates label text/font/color, and connects state changes so glyphs can follow GTK button state.

Source references:

- Registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:530`
- `SetGlyph`: `lcl/interfaces/gtk2/gtk2wsbuttons.pp:221`
- `SetLayout`: `lcl/interfaces/gtk2/gtk2wsbuttons.pp:239`
- `SetMargin`: `lcl/interfaces/gtk2/gtk2wsbuttons.pp:255`
- `SetSpacing`: `lcl/interfaces/gtk2/gtk2wsbuttons.pp:269`
- state-aware `UpdateGlyph`: `lcl/interfaces/gtk2/gtk2wsbuttons.pp:343`

Manual judgment: GTK2 is the strongest reference for this file because it handles state-aware glyph updates and explicit margin/spacing/layout widget rebuilding.

#### Qt5 Reference

Qt5 registers `TCustomBitBtn` with `TQtWSBitBtn` and implements all four methods. `SetGlyph` builds a `QIcon` with multiple icon modes mapped from LCL button states. Layout, margin, and spacing trigger repaint/update on the custom Qt button.

Source references:

- Registration: `lcl/interfaces/qt5/qtwsfactory.pas:468`
- `SetGlyph`: `lcl/interfaces/qt5/qtwsbuttons.pp:77`
- state mapping to Qt icon modes: `lcl/interfaces/qt5/qtwsbuttons.pp:78`
- `SetLayout`: `lcl/interfaces/qt5/qtwsbuttons.pp:128`
- `SetMargin`: `lcl/interfaces/qt5/qtwsbuttons.pp:138`
- `SetSpacing`: `lcl/interfaces/qt5/qtwsbuttons.pp:147`

Manual judgment: Qt5 is usable for this file. The detailed layout rendering is delegated to `TQtBitBtn`, but the widgetset method surface is wired and state-aware glyph creation is explicit.

#### GTK4 Review

GTK4 registers `TCustomBitBtn` with `TGtk4WSBitBtn` and implements all four methods.

Source references:

- Registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:488`
- `SetGlyph`: `lcl/interfaces/gtk4/gtk4wsbuttons.pp:115`
- `RebuildButtonChild`: `lcl/interfaces/gtk4/gtk4wsbuttons.pp:210`
- `SetLayout`: `lcl/interfaces/gtk4/gtk4wsbuttons.pp:257`
- `SetMargin`: `lcl/interfaces/gtk4/gtk4wsbuttons.pp:269`
- `SetSpacing`: `lcl/interfaces/gtk4/gtk4wsbuttons.pp:281`
- `TGtk4Button.SetMargin`: `lcl/interfaces/gtk4/gtk4widgets.pas:10702`
- `TGtk4Button.SetSpacing`: `lcl/interfaces/gtk4/gtk4widgets.pas:10764`

GTK4 source-intended behavior, blocked by the date API mismatch until fixed:

- Basic handle creation exists through `TGtk4Button`.
- `SetGlyph` creates a GTK image from either `Images/ImageIndex` or the `TButtonGlyph.Glyph` raw image.
- `SetGlyph` creates a GTK box with image and label because GTK4 removed `gtk_button_set_image`.
- `SetLayout` rebuilds the image/label order for left/right/top/bottom layouts.
- `SetSpacing` is backed by GtkBox spacing plus `TGtk4Button.SetSpacing` image margins.
- Text-only fallback restores the GTK button label.

GTK4 limitations found by source review:

- `SetGlyph` does not use `TButtonGlyph.GetImageIndexAndEffect`. It reads only `ABitBtn.ImageIndex` or `AValue.Glyph.RawImage`, so state-specific `DisabledImageIndex`, `HotImageIndex`, `PressedImageIndex`, multi-glyph state images, and theme glyph effects are not handled at GTK2/Qt5 level.
- GTK2 updates glyphs on GTK state changes, and Qt5 builds a multi-mode `QIcon`; GTK4 has no equivalent state-aware path in the reviewed code.
- `SetMargin` stores the value and calls `RebuildButtonChild`, while `TGtk4Button.SetMargin` applies child alignment/margins. However, `RebuildButtonChild` creates a new child and does not itself call `TGtk4Button.SetMargin` after replacing the child. This needs runtime verification because margin may not be applied after rebuild in some call orders.
- `SetGlyph` builds the initial child but does not visibly call `TGtk4Button.SetMargin` after `gtk4_button_set_child`, so initial `Margin` handling also needs runtime verification.

GTK4 method judgments:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `SetGlyph` | `partial` | Basic glyph display exists, but state-aware glyph/effect behavior from `TButtonGlyph.GetImageIndexAndEffect` is not implemented. |
| `SetLayout` | `usable_with_limits` | Rebuilds child order for all four layout directions, but depends on rebuilt child interaction with margin/spacing. |
| `SetMargin` | `partial` | Focused GTK4 run confirmed `Margin := 12` did not reach the current rebuilt native child; margins/alignment stayed zero/fill. |
| `SetSpacing` | `usable_with_limits` | GtkBox spacing and image margins exist, but should be visually checked for all four layouts. |

Focused runtime validation:

- Document: `PLAN_GTK4_BUTTONS_VALIDATION.md`
- Example: `example_gtk4_buttons_validation/`
- Build/run date: 2026-07-09
- Result summary: build succeeded; raw glyph and image-list glyph create `GtkBox` children; layout changes update native orientation; spacing changes update `GtkBox` spacing; margin does not reach the rebuilt native child; caption was unexpectedly observed as empty in this focused run and needs a narrower follow-up before being classified.

#### Required Follow-Up Tests

Before deciding implementation work for `wsbuttons.pp`, create or extend a small GTK4/GTK2/Qt5 comparison example that verifies:

1. BitBtn glyph from `Glyph`.
2. BitBtn glyph from `Images/ImageIndex`.
3. `DisabledImageIndex`, `HotImageIndex`, and `PressedImageIndex`.
4. `Layout` values: left, right, top, bottom. Initial GTK4 run covered orientation changes; visual order still needs manual/pixel validation.
5. `Margin = -1`, `0`, and a positive value. Initial GTK4 run confirmed positive margin is not applied to the rebuilt child.
6. `Spacing = 0`, default `4`, and a larger value. Initial GTK4 run covered default `4` and larger `14`; zero still needs a quick follow-up.
7. Caption updates after glyph child creation. Initial GTK4 run observed empty caption and needs a narrower no-glyph/glyph comparison.

#### Scope Result

`wsbuttons.pp` reveals real GTK4 work scope. GTK4 is not missing the BitBtn implementation, but it is not yet GTK2/Qt5-equivalent for state-aware glyph behavior and needs runtime verification for margin handling.

### 2. `lcl/widgetset/wscalendar.pp`

#### Baseline Expectation

`TWSCustomCalendar` declares:

- `GetDateTime`
- `HitTest`
- `GetCurrentView`
- `SetDateTime`
- `SetDisplaySettings`
- `SetFirstDayOfWeek`
- `SetMinMaxDate`
- `RemoveMinMaxDates`

The baseline defaults return fixed/no-op values. `TCustomCalendar` calls these methods from `HitTest`, `GetCalendarView`, `SetProps`, and min/max date handling.

Source references:

- Baseline declarations: `lcl/widgetset/wscalendar.pp:45`
- Baseline defaults: `lcl/widgetset/wscalendar.pp:67`, `lcl/widgetset/wscalendar.pp:72`, `lcl/widgetset/wscalendar.pp:78`, `lcl/widgetset/wscalendar.pp:84`, `lcl/widgetset/wscalendar.pp:89`, `lcl/widgetset/wscalendar.pp:95`, `lcl/widgetset/wscalendar.pp:101`, `lcl/widgetset/wscalendar.pp:106`
- LCL `HitTest` / `GetCalendarView`: `lcl/calendar.pp:219`, `lcl/calendar.pp:227`
- LCL property propagation: `lcl/calendar.pp:286`, `lcl/calendar.pp:322`, `lcl/calendar.pp:341`, `lcl/calendar.pp:381`, `lcl/calendar.pp:400`, `lcl/calendar.pp:417`

#### GTK2 Reference

GTK2 registers `TCustomCalendar` and implements date get/set, hit testing, display settings, callbacks, and preferred size. It does not override `SetFirstDayOfWeek`, `SetMinMaxDate`, or `RemoveMinMaxDates` in the reviewed `gtk2wscalendar.pp`; those fall back to baseline behavior.

Source references:

- Registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:240`
- `GetDateTime`: `lcl/interfaces/gtk2/gtk2wscalendar.pp:170`
- `HitTest`: `lcl/interfaces/gtk2/gtk2wscalendar.pp:182`
- `SetDateTime`: `lcl/interfaces/gtk2/gtk2wscalendar.pp:268`
- `SetDisplaySettings`: `lcl/interfaces/gtk2/gtk2wscalendar.pp:283`
- GTK2 maps `dsNoMonthChange`: `lcl/interfaces/gtk2/gtk2wscalendar.pp:300`

Manual judgment: GTK2 is usable for traditional GTK calendar behavior but does not provide full baseline coverage for first-day/min-max methods.

#### Qt5 Reference

Qt5 registers `TCustomCalendar` and implements the full reviewed method set except `GetCurrentView`. It maps display headers/week numbers, first day of week, and min/max dates to `TQtCalendar`.

Source references:

- Registration: `lcl/interfaces/qt5/qtwsfactory.pas:223`
- `GetDateTime`: `lcl/interfaces/qt5/qtwscalendar.pp:65`
- `HitTest`: `lcl/interfaces/qt5/qtwscalendar.pp:73`
- `SetDateTime`: `lcl/interfaces/qt5/qtwscalendar.pp:85`
- `SetDisplaySettings`: `lcl/interfaces/qt5/qtwscalendar.pp:96`
- `SetFirstDayOfWeek`: `lcl/interfaces/qt5/qtwscalendar.pp:124`
- `SetMinMaxDate`: `lcl/interfaces/qt5/qtwscalendar.pp:148`

Manual judgment: Qt5 is the stronger reference for this file because it supports first-day-of-week and min/max date behavior through backend APIs.

#### GTK4 Review

GTK4 registers `TCustomCalendar` and has source paths for date get/set, hit testing, display settings, first-day placeholder, min/max clamp behavior, remove limits, preferred size, and calendar signals. Runtime validation on GTK 4.6.9 originally showed the date wrapper/binding path was not usable: ordinary `TCalendar` handle initialization crashed before the control was shown. Fixed 2026-07-10 (see `PLAN_GTK4_CALENDAR_VALIDATION.md`, "Implementation Fix"): the wrapper now uses GDateTime-typed `gtk4_calendar_select_day`/`gtk4_calendar_get_date` bindings from `lazgtk4_compat.pas`, and the invalid `month-changed` connect was removed. Post-fix runtime validation passes the full auto sequence (round trip, cross-month/year set, display settings, hit test, min/max clamp) without exceptions or GLib warnings.

Source references:

- Registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:226`
- `GetDateTime`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:68`
- `HitTest`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:83`
- `SetDateTime`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:198`
- `SetDisplaySettings`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:208`
- `SetFirstDayOfWeek`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:247`
- `SetMinMaxDate`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:254`
- `RemoveMinMaxDates`: `lcl/interfaces/gtk4/gtk4wscalendar.pp:261`
- GTK4 calendar signals: `lcl/interfaces/gtk4/gtk4widgets.pas:6036`
- GTK4 min/max clamp: `lcl/interfaces/gtk4/gtk4widgets.pas:6140`

GTK4 usable behavior:

- Date get/set uses GTK calendar date with zero-based month adjustment.
- Display settings use GTK4 GObject properties for heading, day names, and week numbers.
- Day/month/year signals are connected to LCL messages.
- Min/max values are stored and the selected date is clamped when changed.

GTK4 limitations found by source review:

- (fixed 2026-07-10) Local GTK 4.6.9 headers declare `gtk_calendar_select_day(GtkCalendar *self, GDateTime *date)` and `gtk_calendar_get_date(GtkCalendar *self): GDateTime *`, but `lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas` still declared the older GTK2/GTK3-style `select_day(day: guint)`, `select_month(month, year)`, and `get_date(year, month, day)` methods. The runtime crash stack confirmed this mismatch reached `g_date_time_get_ymd` through `gtk_calendar_select_day`. Fix: GDateTime-typed externals in `lazgtk4_compat.pas`; `TGtk4Calendar.GetDate/SetDate` rewritten on GDateTime; the legacy `lazgtk4.pas` wrappers are marked with ABI-TRAP warning comments and have no remaining callers.
- (fixed 2026-07-10) `TGtk4Calendar.CreateWidget` connected `month-changed`, but GTK4 `GtkCalendar` has no such signal (GLib emitted "signal 'month-changed' is invalid"). The connect was removed and month/year delivery now uses `notify::month`/`notify::year` — GTK 4.6.9 source shows every month/year change funnels through `gtk_calendar_select_day`, which emits these notifications, while the `prev/next-month/year` signals fire only for the header arrows (they would miss adjacent-month day clicks, DnD, and programmatic changes; codex-review finding, GTK-source-verified).
- `SetFirstDayOfWeek` is explicitly a no-op because GTK4 `GtkCalendar` is locale-based and exposes no direct override in the reviewed code.
- `SetDisplaySettings` does not implement `dsNoMonthChange`; GTK2 maps this flag and GTK4 ignores it.
- `GetCurrentView` is not overridden. Since GTK calendar appears month-view only, the baseline `cvMonth` default may be acceptable, but this should be documented as inherited-by-design rather than assumed.
- `HitTest` relies on GTK4 internal child widget shape and type names. This is plausible but fragile and should be runtime-tested under at least heading/day-name/week-number combinations.
- Min/max date support is not native UI disabling. GTK4 clamps after selection through signals, so users may still navigate/select out-of-range dates momentarily before correction.

GTK4 method judgments:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `GetDateTime` | `usable` (fixed 2026-07-10) | Wrapper reads `GDateTime *` via `gtk4_calendar_get_date` and unrefs it; zero-based month contract preserved. Runtime round trip confirmed. |
| `HitTest` | `usable_with_limits` (runtime-tested 2026-07-10) | Auto run returns `cpTitleMonth/cpTitle/cpTitleYear/cpDate` at expected points and `cpNoWhere` with headings hidden; still depends on GTK4 internal child heuristics, re-check on GTK upgrades. |
| `GetCurrentView` | `usable_with_limits` | Inherits baseline `cvMonth`; acceptable only if GTK4 calendar has no exposed alternate view. |
| `SetDateTime` | `usable` (fixed 2026-07-10) | Wrapper builds a `GDateTime` with `g_date_time_new_local` and calls `gtk4_calendar_select_day`; cross-month/year set runtime-confirmed (2026-07-09 → 2026-12-25). |
| `SetDisplaySettings` | `partial` | Implements headings/day names/week numbers but not `dsNoMonthChange`. |
| `SetFirstDayOfWeek` | `backend_limited` | Explicit no-op due to GTK4 locale-based behavior. |
| `SetMinMaxDate` | `usable_with_limits` | Clamp behavior exists but is not native disabled-range UI. |
| `RemoveMinMaxDates` | `usable` | Clears stored min/max values. |

Focused runtime validation:

- Document: `PLAN_GTK4_CALENDAR_VALIDATION.md`
- Example: `example_gtk4_calendar_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_calendar_validation/calendar_validation.lpi` succeeded.
- Auto run result: failed with `APPLICATION_EXCEPTION EAccessViolation: Access violation`.
- GDB stack: `g_date_time_get_ymd` -> `gtk_calendar_select_day` -> `TGtk4Calendar.SetDate` (`gtk4widgets.pas:6129`) -> `TGtk4WSCustomCalendar.SetDateTime` (`gtk4wscalendar.pp:205`) -> `TCustomCalendar.SetProps` (`calendar.pp:425`) -> `TCustomCalendar.InitializeWnd` (`calendar.pp:245`).
- Header confirmation: `/usr/include/gtk-4.0/gtk/gtkcalendar.h` for GTK 4.6.9 declares `gtk_calendar_select_day` with `GDateTime *date` and `gtk_calendar_get_date` returning `GDateTime *`.
- Post-fix run (2026-07-10): the same auto sequence completes without `EAccessViolation` or invalid-signal warnings; date round trip, cross-month/year set, display settings, hit test, and min/max clamp all confirmed. Details in `PLAN_GTK4_CALENDAR_VALIDATION.md`, "Validation Run 2".

#### Required Follow-Up Tests

Before behavioral parity testing, fix or regenerate the GTK4 Calendar binding/wrapper date API path so `TCalendar` can be created without crashing. Then run a focused calendar comparison example for GTK2, Qt5, and GTK4:

1. Date get/set round trip.
2. `DisplaySettings` combinations: headings, day names, week numbers, and no-month-change.
3. `FirstDayOfWeek` values, especially non-default Monday/Sunday behavior.
4. `MinDate`/`MaxDate` behavior when selecting/navigating outside limits.
5. `HitTest` for title, title buttons, month/year labels, date cells, and week-number cells.
6. Day/month/year event delivery.

#### Scope Result

`wscalendar.pp` had a confirmed GTK4 runtime blocker on the current GTK 4.6.9 system; the Calendar date API binding/wrapper mismatch and the invalid signal connection were fixed 2026-07-10 and runtime-validated. Remaining classification items: `dsNoMonthChange` (still ignored — GTK4 exposes no equivalent property in the reviewed code), first-day-of-week (locale-only), and min/max UX (clamp-after-select, not native disabling). These stay documented limitations rather than blockers.

### 3. `lcl/widgetset/wschecklst.pp`

#### Baseline Expectation

`TWSCustomCheckListBox` declares:

- `GetCheckWidth`
- `GetItemEnabled`
- `GetHeader`
- `GetState`
- `SetItemEnabled`
- `SetHeader`
- `SetState`

The baseline defaults make unchecked/enabled/no-header/no-op behavior. `TCustomCheckListBox` dispatches property getters and setters to these widgetset methods whenever the handle is allocated.

Source references:

- Baseline declarations: `lcl/widgetset/wschecklst.pp:45`
- Baseline defaults: `lcl/widgetset/wschecklst.pp:69`, `lcl/widgetset/wschecklst.pp:75`, `lcl/widgetset/wschecklst.pp:81`, `lcl/widgetset/wschecklst.pp:87`, `lcl/widgetset/wschecklst.pp:93`, `lcl/widgetset/wschecklst.pp:99`, `lcl/widgetset/wschecklst.pp:106`
- LCL getters: `lcl/checklst.pas:284`, `lcl/checklst.pas:292`, `lcl/checklst.pas:302`, `lcl/checklst.pas:312`
- LCL setters / WS dispatch: `lcl/checklst.pas:346`, `lcl/checklst.pas:356`, `lcl/checklst.pas:370`, `lcl/checklst.pas:400`, `lcl/checklst.pas:407`, `lcl/checklst.pas:414`
- LCL click callbacks: `lcl/checklst.pas:430`, `lcl/checklst.pas:435`

#### GTK2 Reference

GTK2 registers `TCustomCheckListBox`, uses a `GtkTreeView` with a toggle renderer, stores state and disabled flags in the GTK model, and delivers `LM_CHANGED` after toggles.

Source references:

- Registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:543`
- Toggle callback and message delivery: `lcl/interfaces/gtk2/gtk2wschecklst.pp:93`
- `GetItemEnabled`: `lcl/interfaces/gtk2/gtk2wschecklst.pp:237`
- `GetState`: `lcl/interfaces/gtk2/gtk2wschecklst.pp:258`
- `SetItemEnabled`: `lcl/interfaces/gtk2/gtk2wschecklst.pp:280`
- `SetState`: `lcl/interfaces/gtk2/gtk2wschecklst.pp:300`

Manual judgment: GTK2 is usable for check state and enabled state. It does not implement header/check-width overrides in the reviewed file.

#### Qt5 Reference

Qt5 registers `TCustomCheckListBox`, creates `TQtCheckListBox`, supports check states, enabled state, `AllowGrayed`, selection mode, and owner-draw flag propagation.

Source references:

- Registration: `lcl/interfaces/qt5/qtwsfactory.pas:480`
- create/setup: `lcl/interfaces/qt5/qtwschecklst.pp:58`
- `AllowGrayed`: `lcl/interfaces/qt5/qtwschecklst.pp:92`, `lcl/interfaces/qt5/qtwschecklst.pp:123`, `lcl/interfaces/qt5/qtwschecklst.pp:150`
- `GetItemEnabled`: `lcl/interfaces/qt5/qtwschecklst.pp:104`
- `GetState`: `lcl/interfaces/qt5/qtwschecklst.pp:115`
- `SetItemEnabled`: `lcl/interfaces/qt5/qtwschecklst.pp:127`
- `SetState`: `lcl/interfaces/qt5/qtwschecklst.pp:141`

Manual judgment: Qt5 is usable for check state and enabled state and is the cleaner reference for `AllowGrayed` support.

#### GTK4 Review

GTK4 registers `TCustomCheckListBox`, creates `TGtk4CheckListBox`, uses a `GtkListView` with `GtkCheckButton` rows, binds text/state/enabled from LCL, and toggles through `TCustomCheckListBox.Toggle`.

Source references:

- Registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:500`
- WS class methods: `lcl/interfaces/gtk4/gtk4wschecklst.pp:42`
- cache mirror used by GTK4 WS: `lcl/interfaces/gtk4/gtk4wschecklst.pp:61`
- `GetItemEnabled`: `lcl/interfaces/gtk4/gtk4wschecklst.pp:85`
- `GetState`: `lcl/interfaces/gtk4/gtk4wschecklst.pp:113`
- `SetItemEnabled`: `lcl/interfaces/gtk4/gtk4wschecklst.pp:142`
- `SetState`: `lcl/interfaces/gtk4/gtk4wschecklst.pp:154`
- factory toggle callback: `lcl/interfaces/gtk4/gtk4widgets.pas:7916`
- factory bind state/enabled: `lcl/interfaces/gtk4/gtk4widgets.pas:7941`
- GTK4 checklist widget creation: `lcl/interfaces/gtk4/gtk4widgets.pas:8218`

GTK4 source-intended behavior, not confirmed as working by runtime validation:

- Basic checked/unchecked/grayed visual binding exists through `GtkCheckButton`.
- Disabled items are reflected by `gtk_widget_set_sensitive` on the check button.
- User toggle calls `TCustomCheckListBox.Toggle` and delivers `LM_CHANGED`.
- MultiSelect chooses GTK multi/single selection model during widget creation.

GTK4 limitations found by source review and runtime validation:

- `GetHeader` and `SetHeader` are not overridden. This matches GTK2/Qt5 in the reviewed files, but it still means header behavior is not native-widgetset implemented.
- `GetCheckWidth` is not overridden. This also matches GTK2/Qt5, but owner-draw/header layout may depend on the baseline `0` value.
- `SetItemEnabled` and `SetState` only queue a redraw. Runtime validation confirmed this is insufficient: after handle creation, public `State[]`, `Checked[]`, and `ItemEnabled[]` getters continued to return default unchecked/enabled values after programmatic changes, `Toggle`, and `CheckAll`.
- Pre-handle checked/grayed/disabled/header values were also not reflected after handle creation in the focused GTK4 run.
- GTK4 uses a local mirror of `TCachedItemData` layout from `checklst.pas`. That is fragile if the LCL implementation-side cache record changes.
- The `GtkCheckButton` itself is disabled for disabled items, but row text sensitivity is not explicitly changed in the reviewed bind code.
- With `MultiSelect=True`, reading `ItemIndex` produced repeated GTK assertions because `TGtk4ListBox.GetItemIndex` calls `gtk4_single_selection_get_selected` even when the selection model is `GtkMultiSelection`.

GTK4 method judgments:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `GetCheckWidth` | `usable_with_limits` | Inherits baseline like GTK2/Qt5; not a GTK4-specific regression, but not a rich implementation. |
| `GetItemEnabled` | `partial` | Reads unchanged/default cache values in the focused run; disabled state did not persist after handle creation. |
| `GetHeader` | `usable_with_limits` | Inherits baseline like GTK2/Qt5; header feature is effectively not native-implemented. |
| `GetState` | `partial` | Reads unchanged/default cache values in the focused run; checked/grayed states did not persist after handle creation. |
| `SetItemEnabled` | `partial` | Runtime validation confirmed queue-draw-only implementation does not make public enabled-state changes persist. |
| `SetHeader` | `usable_with_limits` | Inherits baseline like GTK2/Qt5; header behavior remains limited. |
| `SetState` | `partial` | Runtime validation confirmed queue-draw-only implementation does not make public check-state changes persist; `Toggle` and `CheckAll` also stayed unchecked. |

Focused runtime validation:

- Document: `PLAN_GTK4_CHECKLISTBOX_VALIDATION.md`
- Example: `example_gtk4_checklistbox_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_checklistbox_validation/checklistbox_validation.lpi` succeeded.
- Auto run result: completed without Pascal exception, but confirmed state/enabled/header persistence failure and repeated `gtk_single_selection_get_selected` assertions under `MultiSelect=True`.
- Result summary: after show, all first six rows read back as `state=unchecked`, `checked=False`, `enabled=True`, `header=False` even though initial pre-handle setup had checked, grayed, disabled, and header rows. Post-handle `State[]`, `ItemEnabled[]`, `Header[]`, `Toggle`, and `CheckAll` operations did not change the public getter results.

#### Required Follow-Up Tests

Create a focused checklist comparison example for GTK2, Qt5, and GTK4:

1. Initial checked/unchecked/grayed states.
2. `AllowGrayed` toggle cycle.
3. Programmatic `State[i]` changes for visible and off-screen rows.
4. Programmatic `ItemEnabled[i]` changes and visual disabled text/check state.
5. User click delivery: `OnClickCheck`, deprecated `OnItemClick`, and `LM_CHANGED` effects.
6. MultiSelect and ExtendedSelect interaction with check toggling.
7. Header property behavior, documenting whether it is unsupported across all three references.

#### Scope Result

`wschecklst.pp` shows a confirmed GTK4 implementation gap, not just a runtime-test need. Basic check state and enabled state persistence currently fail in the focused GTK4 run because widgetset setters do not update a backend model or LCL cache after handle creation. Header/check-width support appears limited across GTK2, Qt5, and GTK4, but GTK4 also has a separate MultiSelect `ItemIndex` assertion path inherited from the listbox helper.

### 4. `lcl/widgetset/wscomctrls.pp`

`wscomctrls.pp` is large enough that it was reviewed in functional groups. This pass covers Page/TabControl, StatusBar, ListView, ProgressBar, UpDown, ToolBar, TrackBar, and TreeView. Runtime verification and deeper component-specific follow-up remain for several groups, especially ListView, ProgressBar, TrackBar, and ToolBar.

#### 4.1 Page/TabControl/StatusBar Baseline Expectation

The baseline declares widgetset methods for:

- `TWSCustomPage.UpdateProperties`
- `TWSCustomTabControl.AddPage`, `MovePage`, `RemovePage`, `GetNotebookMinTabHeight`, `GetNotebookMinTabWidth`, `GetTabIndexAtPos`, `GetTabRect`, `GetCapabilities`, `SetTabSize`, `SetImageList`, `SetPageIndex`, `SetTabCaption`, `SetTabPosition`, `ShowTabs`, `UpdateProperties`
- `TWSStatusBar.PanelUpdate`, `SetPanelText`, `SetSizeGrip`, `Update`, `GetDefaultColor`
- `TWSTabSheet.GetDefaultColor`

Most baseline method bodies are no-op/default behavior, so usable behavior depends on widgetset overrides and helper widget code.

Source references:

- Baseline declarations: `lcl/widgetset/wscomctrls.pp:43`, `lcl/widgetset/wscomctrls.pp:52`, `lcl/widgetset/wscomctrls.pp:78`
- Baseline defaults: `lcl/widgetset/wscomctrls.pp:403`, `lcl/widgetset/wscomctrls.pp:407`, `lcl/widgetset/wscomctrls.pp:427`, `lcl/widgetset/wscomctrls.pp:437`, `lcl/widgetset/wscomctrls.pp:464`
- LCL tab image/property propagation: `lcl/comctrls.pp:713`, `lcl/comctrls.pp:843`

#### 4.2 GTK2 Reference

GTK2 registers PageControl/TabControl and StatusBar and implements the reviewed methods through `gtk2pagecontrol.inc` and `gtk2wscomctrls.pp`.

Source references:

- Page/TabControl registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas`
- StatusBar registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas`
- `AddPage` / `MovePage`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:345`, `lcl/interfaces/gtk2/gtk2pagecontrol.inc:436`
- `GetCapabilities`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:449`
- `GetTabIndexAtPos`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:472`
- `GetTabRect`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:520`
- `SetPageIndex`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:550`
- `SetTabPosition`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:583`
- `ShowTabs` / `UpdateProperties`: `lcl/interfaces/gtk2/gtk2pagecontrol.inc:593`, `lcl/interfaces/gtk2/gtk2pagecontrol.inc:604`
- `SetSizeGrip`: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:674`

Manual judgment: GTK2 is broadly usable for PageControl and StatusBar. Its capabilities are narrower than GTK4's current reported capability set: GTK2 reports `[nbcPageListPopup, nbcShowCloseButtons]`. GTK2 also exits PageControl operations for `TTabControl`, which means `TTabControl` needs separate runtime evaluation rather than assuming native notebook behavior.

#### 4.3 Qt5 Reference

Qt5 registers PageControl/TabControl and StatusBar and implements the reviewed methods with `TQtTabWidget`, `TQtTabBar`, and `TQtStatusBar`.

Source references:

- `GetCapabilities`: `lcl/interfaces/qt5/qtpagecontrol.inc:360`
- `GetTabIndexAtPos`: `lcl/interfaces/qt5/qtpagecontrol.inc:376`
- `GetTabRect`: `lcl/interfaces/qt5/qtpagecontrol.inc:402`
- `SetPageIndex`: `lcl/interfaces/qt5/qtpagecontrol.inc:417`
- `SetTabCaption`: `lcl/interfaces/qt5/qtpagecontrol.inc:437`
- `SetTabPosition`: `lcl/interfaces/qt5/qtpagecontrol.inc:448`
- `SetTabSize`: `lcl/interfaces/qt5/qtpagecontrol.inc:454`
- `ShowTabs` / `UpdateProperties`: `lcl/interfaces/qt5/qtpagecontrol.inc:461`, `lcl/interfaces/qt5/qtpagecontrol.inc:475`
- StatusBar panel recreation/update: `lcl/interfaces/qt5/qtwscomctrls.pp:565`, `lcl/interfaces/qt5/qtwscomctrls.pp:611`
- `SetSizeGrip`: `lcl/interfaces/qt5/qtwscomctrls.pp:681`

Manual judgment: Qt5 is the strongest reference for tab hit testing and tab rectangle behavior because it explicitly handles all four `TTabPosition` values and bidirectional edge cases. Qt5 reports `[nbcShowCloseButtons, nbcTabsSizeable]`, not multiline/page-list/add-tab capability.

#### 4.4 GTK4 Review: StatusBar

GTK4 registers `TStatusBar` with `TGtk4WSStatusBar`, creates a `TGtk4StatusBar`, and implements panel rebuild/update through a `GtkBox` with `GtkLabel` children.

Source references:

- Registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:170`
- WS methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1628`
- `TGtk4StatusBar.RecreatePanels`: `lcl/interfaces/gtk4/gtk4widgets.pas:5105`
- `TGtk4StatusBar.UpdatePanel`: `lcl/interfaces/gtk4/gtk4widgets.pas:5160`
- `TGtk4StatusBar.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:5220`
- `SetSizeGrip` no-op rationale: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1681`

GTK4 usable behavior:

- Simple panel and multi-panel text are implemented.
- Panel alignment, positive width, hidden zero-width panels, and last-panel expansion are implemented.
- Panel count changes trigger full recreation.

GTK4 limitations found by source review:

- `SetSizeGrip` is intentionally a no-op because GTK4 removed the old `GtkStatusBar` resize grip path. This is a backend limitation when compared with GTK2/Qt5, both of which have explicit size-grip handling.
- Owner-draw status bar panels are not visible in the reviewed GTK4 implementation. Qt5 tracks `Panel.Style = psOwnerDraw` in `TQtStatusBarPanel`; GTK4 currently creates labels only.
- GTK4 does not use a native `GtkStatusBar` because GTK4 removed the old widget path, so exact theme parity with GTK2/Qt5 cannot be assumed.
- Focused runtime validation confirmed panel text, width, simple panel, size-grip property, owner-draw style assignment, and panel add operations completed without Pascal exceptions. The run did not prove owner-draw painting or exact visual panel layout.

GTK4 StatusBar judgments:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `PanelUpdate` | `usable_with_limits` | Rebuilds or updates labels, alignment, width, and expansion; owner-draw needs separate review/test. |
| `SetPanelText` | `usable` | Updates the target label text through `UpdatePanel`. |
| `SetSizeGrip` | `backend_limited` | Explicit no-op because GTK4 no longer exposes the GTK2 statusbar resize grip model. |
| `Update` | `usable_with_limits` | Recreates label panels; owner-draw/statusbar painting parity is not established. |

#### 4.5 GTK4 Review: PageControl and TabControl

GTK4 registers `TCustomPage` and `TCustomTabControl`. For `TPageControl`, it creates `TGtk4NoteBook` backed by `GtkNotebook`; for `TTabControl`, it creates a `TGtk4CustomControl` and many notebook-specific methods exit early.

Source references:

- Registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:379`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:385`
- `TGtk4WSCustomTabControl.CreateHandle`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1690`
- `AddPage` / `MovePage` / `RemovePage`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1745`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1760`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1769`
- `GetCapabilities`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1854`
- `GetTabIndexAtPos`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1884`
- `GetTabRect`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1972`
- `SetPageIndex` / `SetTabCaption` / `SetTabPosition` / `SetTabSize`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2017`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2028`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2038`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2048`
- `ShowTabs` / `UpdateProperties`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2070`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:2080`
- `TGtk4Page.UpdateTabImage`: `lcl/interfaces/gtk4/gtk4widgets.pas:6570`
- `TGtk4NoteBook.GetClientAreaOffset`: `lcl/interfaces/gtk4/gtk4widgets.pas:6813`
- `TGtk4NoteBook.getClientRect`: `lcl/interfaces/gtk4/gtk4widgets.pas:6838`
- `TGtk4NoteBook.SetTabPosition`: `lcl/interfaces/gtk4/gtk4widgets.pas:7017`

GTK4 usable behavior:

- Basic PageControl creation, page insertion, moving, removal, page index changes, caption changes, tab position assignment, show/hide tabs, popup enable/disable, and tab image updates are implemented.
- Page tab images are implemented through `TGtk4Page.UpdateTabImage`, using `TCustomTabControl.Images` and `GetImageIndex`.
- Selection notification paths exist for `TCN_SELCHANGING` and `TCN_SELCHANGE`.
- `RemovePage` includes extra destruction and expected-child guards compared with a minimal implementation.

GTK4 limitations found by source review:

- `TTabControl` does not use `GtkNotebook`; it creates `TGtk4CustomControl`, and notebook operations exit early. GTK2 and Qt5 also have special handling for `TTabControl`, so this is not automatically a GTK4-only defect, but GTK4 `TTabControl` drawing/hit behavior must be runtime-reviewed separately.
- `GetClientAreaOffset` explicitly handles only top tabs. `getClientRect` subtracts tab-bar height from total height and does not branch for left/right/bottom tab positions. Qt5 explicitly handles `tpTop`, `tpLeft`, `tpRight`, and `tpBottom` in both hit testing and tab rectangle calculation.
- `GetDefaultClientRect` also subtracts a top tab-bar height from height and does not adjust width for left/right tab positions.
- GTK4 reports `[nbcShowCloseButtons, nbcMultiLine, nbcPageListPopup, nbcShowAddTabButton]`, but the reviewed source only confirmed popup handling. Close buttons, multiline tabs, and add-tab button behavior were not found in the reviewed GTK4 PageControl code path, so the capability set may be overreported.
- `SetImageList` is not overridden in `TGtk4WSCustomTabControl`; tab image updates are delegated through page `UpdateProperties`. This may be enough when LCL calls page updates, but image-list changes require runtime confirmation.
- `TGtk4NoteBook.RemovePage` contains unconditional `DebugLn` trace calls in the reviewed helper body. This is not a functional implementation gap, but it is a quality issue if normal builds can emit trace output without `GTK4DEBUGCORE`.
- `SetTabSize` adds a new CSS provider on each call. Source review did not find provider reuse/removal, so repeated runtime changes should be tested for style stacking and stale size behavior.
- Focused runtime validation confirmed that `TTabControl` returns zero tab rectangles and `-1` hit results for all tabs under GTK4.
- Focused runtime validation confirmed `TPageControl.TabRect`/`IndexOfTabAt` instability: top tab rects changed from positive to negative Y coordinates after the delayed auto pass, bottom/left/right tab positions returned top-like horizontal coordinates, and `ShowTabs` transitions produced zero-sized tab rects until a later add/free page sequence forced recalculation.

GTK4 Page/TabControl judgments:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `AddPage` | `usable_with_limits` | Works for PageControl; exits for `TTabControl`; page sizing is delegated to client rect math that is top-tab biased. |
| `MovePage` | `usable_with_limits` | Works for PageControl; exits for `TTabControl`. |
| `RemovePage` | `usable_with_limits` | Has robust destruction guards, but helper has unconditional debug output and needs lifecycle stress tests. |
| `GetCapabilities` | `partial` | Reported capabilities exceed behavior confirmed by source review. Popup is implemented; close/multiline/add-tab need proof or correction. |
| `GetNotebookMinTabHeight` | `usable_with_limits` | Measures first tab label; only meaningful after handle/pages exist. |
| `GetNotebookMinTabWidth` | `usable_with_limits` | Same limitation as height. |
| `GetTabIndexAtPos` | `partial` | Implemented for PageControl, but coordinate conversion is top-tab biased. |
| `GetTabRect` | `partial` | Implemented for PageControl, but coordinate conversion is top-tab biased. |
| `SetImageList` | `needs_runtime_test` | No direct override; page `UpdateProperties` updates images, but image-list mutation/update timing must be verified. |
| `SetPageIndex` | `usable_with_limits` | Basic call exists; bounds are left to GtkNotebook/LCL path rather than checked in this method. |
| `SetTabCaption` | `usable` | Updates the tab label through page text. |
| `SetTabPosition` | `partial` | Calls GTK tab position, but client rect and hit-test support do not match all positions. |
| `SetTabSize` | `needs_runtime_test` | CSS-based size setting exists; repeated changes/provider stacking need verification. |
| `ShowTabs` | `usable` | Maps to `GtkNotebook.set_show_tabs`. |
| `UpdateProperties` | `usable_with_limits` | Popup option is handled; other reported capabilities are not confirmed. |
| `TWSCustomPage.UpdateProperties` | `usable_with_limits` | Updates tab image; depends on LCL update timing for image-list changes. |

Focused runtime validation:

- Document: `PLAN_GTK4_PAGE_STATUS_VALIDATION.md`
- Example: `example_gtk4_page_status_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_page_status_validation/page_status_validation.lpi` succeeded.
- Auto run result: completed without Pascal exception.
- PageControl result summary: basic creation, page index change, caption change, tab-size assignment, page add, and added-page free completed. `TabRect`/`IndexOfTabAt` remained problematic: top tab rects changed from positive to negative Y values after the delayed auto pass, bottom/left/right tab positions returned top-like horizontal rects, `ShowTabs=False` collapsed rects to zero-sized points, and rects stayed zero-sized after showing tabs again until an add/free page sequence forced recalculation.
- TabControl result summary: all tab rects were `(0,0,0,0)` and center hit tests returned `-1`, confirming that GTK4 `TTabControl` is not providing notebook-style tab geometry.
- StatusBar result summary: text, width, simple-panel mode, size-grip property, owner-draw style assignment, and panel add operations completed without exception; owner-draw painting is still unproven.

#### Required Follow-Up Tests

Create or extend a focused PageControl/StatusBar comparison example for GTK2, Qt5, and GTK4:

1. PageControl add/move/remove pages at runtime, including destruction while the form closes.
2. Tab positions `tpTop`, `tpBottom`, `tpLeft`, and `tpRight`: client area, `GetTabRect`, `GetTabIndexAtPos`, and mouse selection behavior.
3. `ShowTabs=False` hit testing and client area.
4. `Images` and per-page image index changes before and after handle creation.
5. `Options`: page-list popup, close buttons, multiline, add-tab button, and keyboard tab switch.
6. Repeated `TabWidth`/`TabHeight` changes.
7. `TTabControl` separately from `TPageControl`: drawing, selection, hit tests, and design-time interaction.
8. StatusBar simple panel, multiple panels, width zero, alignment, runtime panel count changes, and owner-draw panel behavior.
9. StatusBar `SizeGrip` should be documented as unsupported/backend-limited on GTK4 unless an alternate GTK4-compatible affordance is intentionally designed.

#### Scope Result

The reviewed `wscomctrls.pp` Page/TabControl/StatusBar group is functional for basic PageControl and StatusBar scenarios but not GTK2/Qt5-equivalent. Focused runtime validation confirmed PageControl tab geometry instability and confirmed that GTK4 `TTabControl` returns no usable tab rectangles/hit results. The most concrete GTK4 work candidates are tab-position-aware client geometry/hit testing, `TTabControl` tab rendering/geometry strategy, capability reporting correctness, tab-image update timing verification, and StatusBar owner-draw review.

#### 4.6 ListView Initial Manual Review

This subsection is not a complete `TWSCustomListView` audit yet. It records the first pass through creation, property dispatch, image-list routing, item geometry, selection/focus, and state image behavior. Column and item methods still require a method-by-method table.

Baseline source references:

- Baseline `TWSCustomListView` declarations: `lcl/widgetset/wscomctrls.pp:107`
- Baseline column/item/LV no-op defaults: `lcl/widgetset/wscomctrls.pp:515`
- Baseline `GetNextItem`, `GetFirstSelected`, and multi-selection list helpers: `lcl/widgetset/wscomctrls.pp:813`

Registration references:

- GTK2: `lcl/interfaces/gtk2/gtk2wsfactory.pas:194`
- Qt5: `lcl/interfaces/qt5/qtwsfactory.pas:183`
- GTK4: `lcl/interfaces/gtk4/gtk4wsfactory.pas:186`

GTK2 and Qt5 reference facts:

- GTK2 maps `vsSmallIcon`, `vsReport`, and `vsList` to `SmallImages`, while only `vsIcon` uses `LargeImages`: `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:1488`, `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:2234`
- Qt5 uses `LargeImages` only for `vsIcon`, and `SmallImages` for `vsSmallIcon`, `vsReport`, and `vsList`: `lcl/interfaces/qt5/qtwscomctrls.pp:2181`
- Qt5 has an explicit `StateImages` path in `ItemSetStateImage`: `lcl/interfaces/qt5/qtwscomctrls.pp:1471`
- Qt5 returns real visual item rectangles for icon/list and report modes through native widget APIs: `lcl/interfaces/qt5/qtwscomctrls.pp:1220`

GTK4 implementation shape:

- GTK4 creates `GtkGridView` for `vsIcon` and `vsSmallIcon`: `lcl/interfaces/gtk4/gtk4widgets.pas:8876`
- GTK4 creates `GtkColumnView` for `vsReport` and `vsList`: `lcl/interfaces/gtk4/gtk4widgets.pas:8959`
- `vsList` without explicit columns gets a widgetset-only display column: `lcl/interfaces/gtk4/gtk4widgets.pas:8959`
- Existing `GtkTreeView` branches remain in many methods, but the current `CreateWidget` path does not instantiate `GtkTreeView` for normal `vsReport`/`vsList`; GTK4's current primary paths are `GtkColumnView` and `GtkGridView`.
- GTK4 factories bind checkbox/image/label cells for ColumnView and icon/label cells for GridView: `lcl/interfaces/gtk4/gtk4widgets.pas:8280`, `lcl/interfaces/gtk4/gtk4widgets.pas:8565`
- GTK4 owner-draw for ColumnView uses a drawing-area factory and sends `CN_DRAWITEM`: `lcl/interfaces/gtk4/gtk4widgets.pas:8565`

GTK4 usable behavior found by source review:

- Basic `vsReport`/`vsList`/`vsIcon`/`vsSmallIcon` widget creation exists.
- Column insert/delete/caption/width/visible/sort-indicator paths exist for ColumnView.
- Basic item insert/delete/move/exchange/update paths exist.
- Selection count, selection get/set, and select-all use `GtkSelectionModel` for ColumnView/GridView.
- Checkboxes are shown in the first ColumnView column through a `GtkCheckButton` when `FCheckboxes` is set.
- ColumnView/GridView bind visible rows from LCL `TListItem`, with the GTK model storing placeholder strings.

GTK4 limitations found by source review:

- `SetImageList` routes image lists by `IsTreeView`, not by `ViewStyle`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1395`. Since `vsSmallIcon` is a `GtkGridView` and not `IsTreeView`, GTK4 accepts `lvilLarge` for `vsSmallIcon`; GTK2 and Qt5 use `SmallImages` for `vsSmallIcon`. This is a concrete behavior gap.
- `ItemSetStateImage` does not implement state image rendering. It contains only a comment claiming factory bind will render state images, but the reviewed GTK4 ListView factory code does not reference `StateImages` or `StateIndex`: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:924`, `lcl/interfaces/gtk4/gtk4widgets.pas:8280`, `lcl/interfaces/gtk4/gtk4widgets.pas:8565`. Qt5 has an explicit implementation.
- `lvpColumnClick` cannot toggle clickability for `GtkColumnView` because the code comments that GTK 4.6 lacks a `headers_clickable` API. Column click may still be generated via the sorter path, so the exact user-facing behavior needs runtime verification: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:507`, `lcl/interfaces/gtk4/gtk4widgets.pas:8765`.
- `lvpShowColumnHeaders` cannot be applied to `GtkColumnView` because the code comments that GTK 4.6 lacks a header-visible API: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:507`.
- `lvpReadOnly` is treated as effectively always true because GTK4 cell renderers/factory widgets are not editable in the reviewed implementation.
- `lvpRowSelect` is effectively always full-row selection in GTK4's current paths.
- `ItemDisplayRect` for ColumnView/GridView works only for visible item widgets because GTK4 recycles off-screen row widgets: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:765`.
- `ItemShow`, `ItemGetPosition`, `GetTopItem`, and `GetVisibleRowCount` use adjustment/pick approximations for ColumnView/GridView because GTK 4.6 lacks direct item scroll/focus geometry APIs in this code path: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:943`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:973`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1211`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1277`.
- `GetFocused` returns the first selected item for ColumnView/GridView because GTK 4.6 has no direct cursor/focus API in the reviewed code path: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1062`.
- `SetDefaultItemHeight`, `SetHotTrackStyles`, `SetHoverTime`, `SetIconArrangement`, and `SetOwnerData` are no-op or documented approximation/backend-limited paths in GTK4 and need comparison against GTK2/Qt5 before final judgment: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1367`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1385`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1390`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1611`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1617`.

Initial GTK4 ListView judgments:

| Area | GTK4 status | Reason |
| --- | --- | --- |
| Basic creation for all view styles | `usable_with_limits` | Current GTK4 paths exist, but use different GTK4 widget families with approximation gaps. |
| `vsSmallIcon` image-list routing | `usable` (fixed 2026-07-10) | Was `partial`: GridView path accepted `lvilLarge`. Fixed to ViewStyle-based routing (gtk2 parity); pixel-verified under Xvfb. See `PLAN_GTK4_LISTVIEW_VALIDATION.md` → Implementation Fix 1. |
| State images | `usable_with_limits` (implemented 2026-07-10) | Was `missing`. Implemented with qt5 semantics (state image occupies the item icon slot; column 0 / grid cell only, no subitem state icons). gtk2 never supported this (`gtk2/issues.xml`). Pixel-verified incl. runtime StateIndex changes and selection preservation. See `PLAN_GTK4_LISTVIEW_VALIDATION.md` → Implementation Fix 2. |
| Column headers visibility/clickability | `partial` | GTK4 comments document missing GTK 4.6 APIs for ColumnView header visibility/clickability control. |
| Item geometry for visible items | `usable_with_limits` | Visible widgets can be found/picked; off-screen rows cannot produce exact rects. |
| Item geometry/scroll for off-screen items | `partial` | Uses scroll adjustment estimates instead of direct native item geometry APIs. |
| Focused item | `partial` | ColumnView/GridView return first selected item as an approximation. |
| Selection | `usable_with_limits` | `GtkSelectionModel` paths exist, but focus/selection distinction is weakened. |

Required ListView follow-up tests:

1. `vsIcon` with `LargeImages`, and `vsSmallIcon` with `SmallImages`, verifying icon size and image source.
2. `StateImages`/`StateIndex` in `vsReport`, `vsList`, `vsIcon`, and `vsSmallIcon`.
3. `Item.DisplayRect` for visible and off-screen rows/items.
4. `Item.MakeVisible`, `TopItem`, and `VisibleRowCount` after scrolling.
5. `Focused` versus `Selected` item differences.
6. `ShowColumnHeaders`, `ColumnClick`, sort indicators, and `OnColumnClick`.
7. Checkboxes in `vsReport` and whether `Checkboxes` is intended to apply in non-report styles.
8. OwnerData with large item counts and runtime `Items.Count` changes.
9. OwnerDraw/CustomDraw for normal rows, selected rows, subitems, and icon drawing.

Current ListView scope result:

GTK4 ListView is not a simple stub; it has substantial current GTK4 implementation. However, the first manual pass already found concrete non-equivalence in `vsSmallIcon` image-list routing and state images, plus several geometry/focus/header behaviors implemented as GTK4 API-limited approximations. The next subsection records the method-group judgments from the manual comparison pass.

#### 4.7 ListView Method Group Judgments

This pass compares method behavior against GTK2 and Qt5 references. The GTK4 result must be interpreted with the current GTK4 creation paths in mind: normal `vsReport`/`vsList` use `GtkColumnView`, while `vsIcon`/`vsSmallIcon` use `GtkGridView`.

GTK2/Qt5 references used in this pass:

- GTK2 property dispatch: `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:549`
- GTK2 item geometry/selection/scroll helpers: `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:1565`, `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:1865`
- GTK2 image-list/view-style handling: `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:2220`, `lcl/interfaces/gtk2/gtk2wscustomlistview.inc:2393`
- Qt5 item insert/text/geometry helpers: `lcl/interfaces/qt5/qtwscomctrls.pp:1545`
- Qt5 geometry/selection/hit-test helpers: `lcl/interfaces/qt5/qtwscomctrls.pp:1835`
- Qt5 image/property/view-style handling: `lcl/interfaces/qt5/qtwscomctrls.pp:2181`
- GTK4 property dispatch: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:507`
- GTK4 item geometry/selection/scroll helpers: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:765`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1029`
- GTK4 image/property/view-style handling: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1395`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:1464`

Column method judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `ColumnInsert/Delete` | `usable_with_limits` | ColumnView column add/remove exists. Legacy TreeView branch also exists, but normal GTK4 report/list creation now uses ColumnView. Runtime tests must cover index stability after insert/delete. |
| `ColumnMove` | `partial` | GTK4 implementation exits for ColumnView/GridView and only moves legacy TreeView columns. Qt5 moves header sections; GTK2 moves columns for TreeView. |
| `ColumnGetWidth` | `usable_with_limits` | ColumnView fixed width is returned; autosize/natural width behavior needs runtime verification. |
| `ColumnSetAlignment` | `partial` | Legacy TreeView path updates renderer/header alignment. ColumnView path exits with comment that alignment is handled in factory cells, but the reviewed bind code does not show per-column alignment application. |
| `ColumnSetAutoSize` | `usable_with_limits` | ColumnView uses resizable plus fixed-width reset; not equivalent to Qt5 `ResizeToContents`. |
| `ColumnSetCaption` | `usable` | ColumnView title update exists. |
| `ColumnSetImage` | `partial` | Legacy TreeView header image exists. ColumnView path exits; Qt5 supports header icons through `QTreeWidgetItem_setIcon`. |
| `ColumnSetMaxWidth` | `partial` | GTK4 comments that `GtkColumnViewColumn` has no max-width API; legacy TreeView supports it. |
| `ColumnSetMinWidth` | `usable_with_limits` | ColumnView maps positive min width to fixed width, which is not the same as independent minimum width. |
| `ColumnSetWidth` | `usable` | ColumnView fixed width is set. |
| `ColumnSetVisible` | `usable` | ColumnView visible flag is set and constrained to list/report styles. |
| `ColumnSetSortIndicator` | `usable_with_limits` | ColumnView sort indicator is set via `gtk4_column_view_sort_by_column`; LCL still manages real sort order. |

Item method judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `ItemInsert/Delete` | `usable_with_limits` | ColumnView/GridView placeholder model insert/remove exists; actual data remains in LCL `TListItem`. |
| `ItemExchange/Move` | `usable_with_limits` | ColumnView/GridView queue redraw after LCL changes; legacy TreeView reorders model rows. Runtime tests must verify visual order after exchange/move. |
| `ItemGetChecked` | `usable_with_limits` | Reads `TListItem` internal checked state. This fits the placeholder-model design but is not native-state backed. |
| `ItemSetChecked` | `partial` | TreeView queues redraw. ColumnView/GridView path does not queue redraw in `ItemSetChecked`; it relies on later bind/draw. Programmatic checkbox changes need runtime verification. |
| `ItemGetState/ItemSetState` | `usable_with_limits` | Selected state is backed by `GtkSelectionModel`; focused state is not supported precisely for ColumnView/GridView. |
| `ItemSetStateImage` | `usable_with_limits` (implemented 2026-07-10) | Was `missing`. Renders via factory bind (qt5 icon-slot semantics) and refreshes the row through a GtkStringList splice (`ItemRebindRow`) because neither queue_draw nor a same-object items-changed rebinds. See `PLAN_GTK4_LISTVIEW_VALIDATION.md` → Implementation Fix 2. |
| `ItemSetImage` | `partial` | Basic redraw/rebind exists, but `vsSmallIcon` image-list routing is wrong and subitem image behavior needs deeper review. |
| `ItemSetText/ItemUpdate` | `usable_with_limits` | ColumnView/GridView queue redraw/rebind. This should update visible cells but needs runtime checks for off-screen rows and owner-data. |
| `ItemShow` | `partial` | GTK4 uses adjustment approximation for ColumnView/GridView because no direct scroll-to-item API is used. Qt5 has direct `scrollToItem`; GTK2 has `gtk_tree_view_scroll_to_cell`/`gtk_icon_view_scroll_to_path`. |
| `ItemDisplayRect` | `partial` | ColumnView/GridView can return visible item widget rects only; off-screen exact rectangles are unavailable in this code path. Qt5 can return native visual rects. |
| `ItemGetPosition` | `partial` | ColumnView/GridView uses adjustment-derived estimates; Qt5 returns visual item rect. |

ListView-level method judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `BeginUpdate/EndUpdate` | `usable_with_limits` | Delegates to `TGtk4ListView.BeginUpdate/EndUpdate`; needs event suppression tests around selection and item changes. |
| `GetBoundingRect` | `usable_with_limits` | Returns allocated container size, not a full content/model bounding rectangle. Qt5 returns frame geometry; GTK2 leaves this essentially TODO. |
| `GetDropTarget` | `usable_with_limits` | Implemented only for legacy TreeView path. Current ColumnView/GridView path returns `-1`. GTK2 also has TODO, so this is not uniquely GTK4-regressed but remains limited. |
| `GetFocused` | `partial` | ColumnView/GridView approximate focus as first selected item. Qt5 can query current item separately. |
| `GetHitTestInfoAt` | `partial` | ColumnView/GridView returns only item/label/nowhere; no state-icon/icon distinction. Qt5 distinguishes state icon and icon using image sizes. |
| `GetHoverTime/SetHoverTime` | `backend_limited` | GTK4 returns/defaults no-op like GTK2; Windows-specific concept. |
| `GetItemAt` | `usable_with_limits` | ColumnView/GridView pick metadata is implemented; needs tests with headers, scrolling, and recycled widgets. |
| `GetSelCount/GetSelection` | `usable` | Uses `GtkSelectionModel` bitsets for current GTK4 paths. |
| `GetTopItem/GetVisibleRowCount` | `partial` | Uses widget picking and adjustment fallback for ColumnView/GridView. Qt5/GTK2 have native visible-range paths for their widgets. |
| `GetViewOrigin/SetViewOrigin` | `usable_with_limits` | Uses scrolled-window adjustments; direct point scrolling is available only for legacy TreeView. |
| `SelectAll` | `usable` | Uses `GtkSelectionModel` select/unselect all. |
| `SetAllocBy` | `stub_or_noop` | Empty in GTK4. Qt5 maps non-report modes to batched layout; GTK2 is also empty. |
| `SetDefaultItemHeight` | `partial` | No ColumnView/GridView support; legacy TreeView can use fixed-height mode. |
| `SetHotTrackStyles` | `stub_or_noop` | Empty in GTK4, GTK2 also empty; Qt5 declaration remains virtual/fallback in reviewed section. |
| `SetIconArrangement` | `partial` | GTK4 comment says layout manages arrangement. Qt5 maps icon arrangement to list flow. |
| `SetImageList` | `partial` | Concrete `vsSmallIcon` routing bug and missing state-image path. |
| `SetItemsCount` | `usable_with_limits` | Resizes placeholder model for ColumnView/GridView; owner-data data delivery must be runtime-tested. |
| `SetOwnerData` | `needs_runtime_test` | GTK4 method is a comment/no-op saying LCL callbacks handle it. Qt5 explicitly sets `OwnerData`. |
| `SetProperty/SetProperties` | `partial` | Some properties are implemented, but ColumnView lacks header-visible/clickable control and several properties are no-op or approximations. |
| `SetScrollBars` | `usable` | Maps to `GtkScrolledWindow` policy. |
| `SetSort` | `usable_with_limits` | GTK4 notifies model that items changed after LCL sort; real sorting remains LCL-managed. |
| `SetViewStyle` | `usable_with_limits` | Recreates the widget. This matches the need to switch GTK widget families. |
| `RestoreItemCheckedAfterSort` | `needs_runtime_test` | GTK4 returns `False`, assuming model/factory preserves checked state from LCL items. This must be tested because Qt5 returns `True`. |

ListView work candidates confirmed by source review:

1. ~~Fix or redesign GTK4 `SetImageList` routing so `vsSmallIcon`, `vsReport`, and `vsList` use `SmallImages`, and `vsIcon` uses `LargeImages`, matching GTK2/Qt5 and LCL expectation.~~ Done 2026-07-10 (ViewStyle-based routing, gtk2 parity; only `vsSmallIcon` was actually mis-routed — vsReport/vsList already accepted `lvilSmall` via the ColumnView `FIsTreeView` compat flag). See `PLAN_GTK4_LISTVIEW_VALIDATION.md` → Implementation Fix 1.
2. ~~Implement or explicitly document unsupported `StateImages` behavior; current GTK4 code has a comment but no discovered rendering path.~~ Done 2026-07-10 (qt5 icon-slot semantics; gtk2 never supported it per `gtk2/issues.xml`; residual limits: no subitem state icons, focus edge on the spliced row). See `PLAN_GTK4_LISTVIEW_VALIDATION.md` → Implementation Fix 2.
3. Decide whether ColumnView header image, alignment, max width, header visibility, and column click options can be implemented with the available GTK4/Pango/widget-factory APIs, or must be documented as backend-limited.
4. Improve or document geometry/focus approximations for ColumnView/GridView: `ItemDisplayRect`, `ItemGetPosition`, `ItemShow`, `GetTopItem`, `GetVisibleRowCount`, and `GetFocused`.
5. Runtime-test checkbox redraw for programmatic `Item.Checked` changes in ColumnView.
6. Runtime-test `OwnerData`, sort, and checked-state preservation together because GTK4 and Qt5 intentionally report different `RestoreItemCheckedAfterSort` behavior.

#### 4.8 ProgressBar, UpDown, ToolBar, TrackBar, TreeView Initial Review

This is an initial registration and source-path review for the remaining `wscomctrls.pp` groups. A deeper runtime test matrix is still required for ProgressBar, ToolBar, and TrackBar.

Baseline source references:

- `TWSCustomUpDown` baseline methods: `lcl/widgetset/wscomctrls.pp:210`, `lcl/widgetset/wscomctrls.pp:290`
- `TWSProgressBar` baseline methods: `lcl/widgetset/wscomctrls.pp:201`, `lcl/widgetset/wscomctrls.pp:916`
- `TWSToolBar` baseline old-toolbar methods: `lcl/widgetset/wscomctrls.pp:235`, `lcl/widgetset/wscomctrls.pp:933`
- `TWSTrackBar` baseline methods: `lcl/widgetset/wscomctrls.pp:249`, `lcl/widgetset/wscomctrls.pp:951`
- `TWSCustomTreeView` baseline registration area: `lcl/widgetset/wscomctrls.pp:260`, `lcl/widgetset/wscomctrls.pp:1098`

Registration comparison:

| Component group | GTK2 registration | Qt5 registration | GTK4 registration | Initial conclusion |
| --- | --- | --- | --- | --- |
| `TCustomProgressBar` | registered | registered | registered | GTK4 has a real implementation path. |
| `TCustomUpDown` | not registered, common fallback | not registered, common fallback | not registered, common fallback | Not a GTK4-only gap; focused GTK4 runtime validation confirms common LCL fallback behavior, with layout limits. |
| `TToolBar` | registered | registered | registered | GTK4 has a real implementation path, but uses LCL-painted toolbar strategy. |
| `TCustomTrackBar` | registered | registered | registered | GTK4 has a real implementation path. |
| `TCustomTreeView` | not registered, common implementation | not registered, common implementation | not registered, common implementation | Not a GTK4-only gap; focused GTK4 runtime validation confirms the common LCL TreeView is active, with geometry/selection limits. |

Source references:

- GTK4 registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:192`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:198`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:204`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:210`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:216`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:220`
- GTK2 registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:200`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:206`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:212`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:218`
- Qt5 registration: `lcl/interfaces/qt5/qtwsfactory.pas:189`, `lcl/interfaces/qt5/qtwsfactory.pas:195`, `lcl/interfaces/qt5/qtwsfactory.pas:201`, `lcl/interfaces/qt5/qtwsfactory.pas:207`, `lcl/interfaces/qt5/qtwsfactory.pas:213`
- GTK4 ProgressBar methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:454`
- GTK4 ProgressBar widget: `lcl/interfaces/gtk4/gtk4widgets.pas:6405`
- GTK4 TrackBar methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:377`
- GTK4 TrackBar widget and ticks: `lcl/interfaces/gtk4/gtk4widgets.pas:5880`, `lcl/interfaces/gtk4/gtk4widgets.pas:5916`
- GTK4 ToolBar widget strategy: `lcl/interfaces/gtk4/gtk4widgets.pas:6468`
- Qt5 TrackBar/ProgressBar references: `lcl/interfaces/qt5/qtwscomctrls.pp:331`, `lcl/interfaces/qt5/qtwscomctrls.pp:456`
- GTK2 TrackBar/ProgressBar references: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:330`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:471`

ProgressBar initial judgment:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` | `usable` | Creates `TGtk4ProgressBar` wrapping a GTK4 progress bar in a box. |
| `ApplyChanges` | `usable_with_limits` | Updates position, style, text visibility, and orientation. Needs runtime comparison for marquee/pulse behavior and all orientations. |
| `SetPosition` | `usable` | Delegates to `TGtk4ProgressBar.Position`. |
| `SetStyle` | `usable_with_limits` | Delegates to `TGtk4ProgressBar.Style`; exact marquee behavior should be compared with GTK2 timeout pulse and Qt5 range style. |

TrackBar initial judgment:

| Method | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` | `usable` | Creates `TGtk4TrackBar` backed by `GtkScale`. |
| `ApplyChanges` | `usable_with_limits` | Applies min/max, position, line/page step, scale position, tick marks/style, and reversed state. |
| `GetPosition` | `usable` | Reads `TGtk4TrackBar.Position`. |
| `SetPosition` | `usable` | Writes `TGtk4TrackBar.Position` inside Begin/EndUpdate. |
| `SetOrientation` | `usable_with_limits` | Recreates the window when orientation changes, similar to baseline recreation logic. |
| `SetTick` | `stub_or_noop` | No GTK4 override found; baseline is no-op. Individual tick setting does not appear implemented. |
| `SetTickStyle` | `needs_runtime_test` | No GTK4 override found; baseline recreates the window. `ApplyChanges` does apply tick marks/style, so the property path may still work after recreate. |

ToolBar initial judgment:

| Area | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` | `usable_with_limits` | Creates `TGtk4ToolBar`; widget comment says toolbar rendering stays in LCL to preserve dynamic ImageList-driven IDE toolbar/component-palette updates. |
| Native toolbar buttons | `backend_limited` | GTK4 implementation does not create a native button-per-toolbutton toolbar in the reviewed path; it uses overlay/fixed/paint handling. This may be intentional for Lazarus IDE behavior but needs functional tests. |

UpDown and TreeView initial judgment:

| Component | GTK4 status | Reason |
| --- | --- | --- |
| `TCustomUpDown` | `usable_with_limits` | GTK4 factory returns `False`, matching GTK2 and Qt5, but common LCL fallback buttons are created and runtime validation confirms basic position/wrap/associate/event behavior. A layout anomaly remains. |
| `TCustomTreeView` | `usable_with_limits` | GTK4 factory returns `False`, matching GTK2 and Qt5, but the common LCL TreeView implementation is active; focused runtime validation confirmed basic node/expand/selection/hit-test behavior with geometry/selection limits. |

Required follow-up tests for this group:

1. ProgressBar: normal and marquee style, min/max edge cases, `BarShowText`, and all four orientations.
2. TrackBar: horizontal/vertical, reversed behavior, min/max edge cases, line/page step, `ScalePos`, `TickMarks`, `TickStyle`, and `Frequency`.
3. TrackBar: verify whether `SetTickStyle` property changes correctly recreate/apply tick marks through `ApplyChanges`.
4. ToolBar: IDE-like toolbar with dynamic image list updates, disabled/enabled buttons, separators, dropdown buttons, hints, and design-time hit testing.
5. UpDown/TreeView: document that they are not registered across GTK2/Qt5/GTK4 before treating them as GTK4-specific work candidates. UpDown and TreeView have now both been runtime-confirmed to use common LCL behavior under GTK4, with documented limits.

#### 4.9 ProgressBar Detailed Review

`TWSProgressBar` exposes only three widgetset hooks: `ApplyChanges`, `SetPosition`, and `SetStyle`. LCL-side `TCustomProgressBar` stores `Min`, `Max`, `Position`, `Step`, `Smooth`, `Orientation`, `BarShowText`, and `Style`, then calls `ApplyChanges` when most properties change. `SetStyle` is special: if the handle exists, it calls only `TWSProgressBar.SetStyle`.

Source references:

- baseline progressbar hooks: `lcl/widgetset/wscomctrls.pp:201`, `lcl/widgetset/wscomctrls.pp:916`
- LCL progressbar lifecycle and property dispatch: `lcl/include/progressbar.inc:37`, `lcl/include/progressbar.inc:62`, `lcl/include/progressbar.inc:123`, `lcl/include/progressbar.inc:170`, `lcl/include/progressbar.inc:203`, `lcl/include/progressbar.inc:212`, `lcl/include/progressbar.inc:269`, `lcl/include/progressbar.inc:289`, `lcl/include/progressbar.inc:310`
- GTK4 widgetset methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:454`
- GTK4 progressbar widget wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas:6405`, `lcl/interfaces/gtk4/gtk4widgets.pas:6269`
- GTK4 `GetContainerWidget` behavior: `lcl/interfaces/gtk4/gtk4widgets.pas:4800`
- GTK2 reference implementation: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:471`
- Qt5 reference implementation: `lcl/interfaces/qt5/qtwscomctrls.pp:456`

GTK4 usable behavior:

- `TGtk4WSProgressBar.CreateHandle` creates `TGtk4ProgressBar`.
- `TGtk4ProgressBar.CreateWidget` creates a `GtkBox` host and stores the actual `GtkProgressBar` in `FCentralWidget`.
- `TGtk4Widget.GetContainerWidget` returns `FCentralWidget` when assigned, so the GTK4 progress methods that cast `GetContainerWidget` to `PGtkProgressBar` are using the actual progress widget.
- `ApplyChanges` applies position, style, `BarShowText`, and orientation under `BeginUpdate`/`EndUpdate`.
- `SetPosition` maps LCL `Min`/`Max`/`Position` to GTK4 fraction.
- `SetStyle(pbstMarquee)` installs a 100 ms timeout and calls `pulse`.
- `SetStyle(pbstNormal)` restores the current LCL position.

GTK4 limitations and likely defects found by source review:

- `Smooth` is not applied in GTK4. GTK2 maps `Smooth` to `GTK_PROGRESS_DISCRETE` / `GTK_PROGRESS_CONTINUOUS`; Qt5 explicitly comments that `Smooth` is unsupported. GTK4 should be documented as unsupported or tested to confirm whether GTK4 has no practical equivalent.
- `TGtk4ProgressBar.GetPosition` returns `Round(get_fraction)`, which yields only `0` or `1` for normal fractions and does not map back through `Min`/`Max`. LCL `TCustomProgressBar.GetPosition` returns `FPosition` and does not appear to call the backend getter, so this may not affect normal LCL property reads. It remains an inaccurate wrapper getter if used internally or by future code.
- GTK4 orientation setter/getter are internally inconsistent for vertical modes. `SetOrientation(pbVertical)` sets GTK orientation vertical and `inverted=True`, while `GetOrientation` returns `pbTopDown` when vertical and inverted. Conversely, `SetOrientation(pbTopDown)` sets `inverted=False`, while `GetOrientation` returns `pbVertical` when vertical and not inverted. This is a source-level mismatch independent of runtime theme behavior.
- GTK4 `SetStyle` only handles style and position; it does not apply `BarShowText`, orientation, min/max, or smooth. This matches the narrow LCL `SetStyle` call path, but if style changes require native range/text updates, GTK4 relies on other property changes or later `ApplyChanges`.
- GTK4 text display only toggles `set_show_text`; no custom text format is applied. GTK2 sets a hard-coded format string when `BarShowText=True`; Qt5 uses native text visibility.
- GTK4 does not set an explicit native range. This is acceptable for `GtkProgressBar`, which uses a 0..1 fraction model, but all min/max semantics are carried only by the fraction calculation in `SetPosition`.

Comparison notes:

- GTK2 applies orientation, smooth, and position in `ApplyChanges`, and uses a timeout pulse for marquee.
- Qt5 applies orientation/inverted appearance, text visibility, range/style, and value in `ApplyChanges`; for marquee it sets range to `0..0` at runtime and `0..1` at design time.
- GTK4 is close to GTK2 for marquee timer strategy and close to Qt5 for text visibility simplicity, but it is weaker than GTK2 for `Smooth` and has a clear vertical orientation getter/setter mismatch.

ProgressBar detailed judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| create/basic display | `usable` | Real `GtkProgressBar` wrapper exists and is reached through `FCentralWidget`. |
| normal position/min/max | `usable_with_limits` | Fraction calculation is implemented; no native range exists. |
| backend `GetPosition` | `usable` (fixed 2026-07-10) | Was `partial` (rounded fraction). Now inverse of SetPosition through Min/Max; LCL-visible Position was never affected. See `PLAN_GTK4_PROGRESSBAR_VALIDATION.md` → Implementation Fix. |
| horizontal/right-to-left orientation | `usable_with_limits` | Source mapping is straightforward; runtime visual test still needed. |
| vertical/top-down orientation | `usable` (fixed 2026-07-10) | Getter vertical branch was swapped; setter was already correct per GTK4 inverted semantics (non-inverted grows top-to-bottom). Round-trip and visual growth directions verified. |
| marquee style | `usable` (fixed 2026-07-10) | Stale timer id after marquee→normal removed (data-clear fires the destroy notify on the live source); normal/marquee toggling runtime-tested with no GLib-CRITICAL. |
| smooth style | `backend_limited` | Not implemented in GTK4; Qt5 also does not support it, while GTK2 does. |
| `BarShowText` | `usable_with_limits` | Native show-text toggled; formatting parity with GTK2/other LCL expectations is limited. |

Required ProgressBar tests:

1. `Position`, `Min`, and `Max`: `0..100`, nonzero min such as `50..150`, equal min/max, position below min, and position above max.
2. All orientations: `pbHorizontal`, `pbRightToLeft`, `pbVertical`, `pbTopDown`; verify both visual growth direction and any backend getter behavior if exposed.
3. Switch orientation at runtime repeatedly, especially `pbVertical <-> pbTopDown`.
4. `pbstNormal <-> pbstMarquee` transitions during runtime; confirm no duplicate pulse timers or stale pulse after returning to normal.
5. `BarShowText` on/off, with normal and marquee style.
6. `Smooth` true/false; document GTK4 behavior as unsupported if no visual/native effect is confirmed.

#### 4.10 TrackBar Detailed Review

`TWSTrackBar` exposes hooks for `ApplyChanges`, `GetPosition`, `SetOrientation`, `SetPosition`, `SetTick`, and `SetTickStyle`. The baseline `SetOrientation` and `SetTickStyle` recreate the window; `SetTick` is no-op.

Source references:

- baseline trackbar hooks: `lcl/widgetset/wscomctrls.pp:246`, `lcl/widgetset/wscomctrls.pp:951`
- LCL orientation/parameter/property dispatch: `lcl/include/trackbar.inc:128`, `lcl/include/trackbar.inc:159`, `lcl/include/trackbar.inc:180`, `lcl/include/trackbar.inc:239`, `lcl/include/trackbar.inc:254`, `lcl/include/trackbar.inc:333`, `lcl/include/trackbar.inc:362`
- GTK4 widgetset methods: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:377`
- GTK4 range wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas:304`, `lcl/interfaces/gtk4/gtk4widgets.pas:5784`, `lcl/interfaces/gtk4/gtk4widgets.pas:5809`, `lcl/interfaces/gtk4/gtk4widgets.pas:5828`, `lcl/interfaces/gtk4/gtk4widgets.pas:5845`
- GTK4 trackbar widget wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas:5888`, `lcl/interfaces/gtk4/gtk4widgets.pas:5913`
- GTK2 reference: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:330`
- Qt5 reference: `lcl/interfaces/qt5/qtwscomctrls.pp:331`

GTK4 usable behavior:

- `TGtk4WSTrackBar.CreateHandle` creates `TGtk4TrackBar`.
- `TGtk4TrackBar.CreateWidget` creates a `GtkScale` with LCL orientation, sets digits to zero, and applies initial `Reversed`.
- `ApplyChanges` applies range, position, line/page step, scale position, tick marks/style, and reversed state.
- `GetPosition` reads the GTK range value.
- `SetPosition` writes the GTK range value under update lock.
- `SetOrientation` recreates the window when the wrapper's stored orientation differs from the requested orientation.
- `SetTickStyle` is not overridden by GTK4, so the baseline recreate path is used after LCL has already called `ApplyChanges`. The recreated widget should receive the current state through `InitializeWnd -> ApplyChanges`.

GTK4 limitations and risk points found by source review:

- `SetTick` remains baseline no-op. Individual tick insertion is not implemented in GTK4, GTK2, or Qt5 in the reviewed widgetset class methods.
- GTK4 `SetTickMarks` uses actual `GtkScale.add_mark` calls at `Frequency` intervals. This is more explicit than GTK2's reviewed path, which mainly toggles value drawing and value position, and roughly comparable to Qt5's tick interval/position path. Runtime visual parity still needs tests because GTK scale marks and Qt slider ticks are not identical.
- GTK4 has a density guard: marks are added only if `round(abs(Max-Min)/Frequency) * Frequency < widget_width_or_height`. Dense ranges can therefore silently draw no tick marks. This may be intentional to avoid excessive marks, but it is not the same as Qt5's `setTickInterval`.
- LCL `FixParams` allows `Min = Max`; it only changes `AMin` when `AMin > AMax`. GTK2 explicitly guards `Min < Max`, and if not, sets upper to `Min + 1` and disables the widget to avoid a crash. GTK4 passes the range directly to `GtkRange.set_range`. Equal min/max and reversed ranges therefore require GTK4 runtime validation.
- GTK4 applies `Reversed` directly to `GtkScale.set_inverted` for both horizontal and vertical orientations. GTK2 does the same. Qt5 has special vertical logic: for vertical orientation it sets inverted appearance to `not Reversed` to match Delphi/MSDN compatibility. GTK4 may therefore match GTK2 but differ from Qt5/Delphi-compatible vertical expectations.
- GTK4 does not override `SetTickStyle`; it relies on baseline recreate. This is probably valid but should be checked for state preservation, focus, event handlers, and size after recreation.

TrackBar detailed judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| create/basic range widget | `usable` | Real `GtkScale` wrapper exists. |
| min/max/position/steps | `usable` (verified 2026-07-10) | Equal min/max needs no GTK2-style guard in GTK4: `gtk_range_set_range` accepts `min <= max` and slider geometry guards zero division (gtkrange.c:1064, 2617, 2628). Runtime-verified. |
| `GetPosition` / `SetPosition` | `usable` | Reads/writes GTK range value. |
| horizontal orientation | `usable_with_limits` | Direct mapping; runtime layout/autosize tests needed. |
| vertical orientation and reversed | `usable` (verified 2026-07-10) | gtk2 parity kept (direct inverted flag); screenshots confirm non-reversed = min at top, reversed = min at bottom. qt5's Delphi-compat negation is a documented divergence. |
| tick style/marks/frequency | `usable` (fixed 2026-07-10) | Density guard compared the range span (range units) against pixels, silently suppressing marks whenever `abs(Max-Min)` exceeded the pixel size; now compares the mark COUNT against pixels, with Int64 span/loop hardening. See `PLAN_GTK4_TRACKBAR_VALIDATION.md` → Implementation Fix. |
| individual `SetTick` | `stub_or_noop` | No backend implementation found in GTK4/GTK2/Qt5 reviewed methods. |
| `SetTickStyle` runtime change | `usable` (verified 2026-07-10) | Baseline RecreateWnd path preserves value/draw_value state (runtime log); orientation recreate likewise. |

Required TrackBar tests:

1. `Min < Max`, `Min = Max`, negative ranges, and nonzero min ranges.
2. Horizontal and vertical orientation, with `Reversed=False` and `Reversed=True`.
3. Runtime orientation changes and size swapping/autosize behavior.
4. `TickStyle=tsNone`, visible tick styles, `TickMarks=tmTopLeft/tmBottomRight/tmBoth`, and `ScalePos`.
5. `Frequency=1`, sparse frequency, and dense frequency where the GTK4 guard may suppress marks.
6. `LineSize` and `PageSize` through keyboard/mouse interactions.
7. `SetTick` call behavior; document no-op if parity with GTK2/Qt5 is confirmed.

#### 4.11 ToolBar and ToolButton Detailed Review

`TWSToolButton` has no published widgetset methods. `TWSToolBar` also has no active published methods unless `OldToolbar` is defined. Therefore the practical toolbar behavior is mostly LCL-side code in `toolbar.inc` and `toolbutton.inc`, with the widgetset providing a host control.

Source references:

- baseline toolbar/toolbutton classes: `lcl/widgetset/wscomctrls.pp:228`
- GTK4 toolbar create handle: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:443`
- GTK4 toolbar widget wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas:554`, `lcl/interfaces/gtk4/gtk4widgets.pas:6468`
- GTK2 toolbar host: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:694`
- Qt5 toolbar host: `lcl/interfaces/qt5/qtwscomctrls.pp:313`
- toolbar LCL update/layout paths: `lcl/include/toolbar.inc:195`, `lcl/include/toolbar.inc:416`, `lcl/include/toolbar.inc:646`
- toolbutton click/dropdown/paint paths: `lcl/include/toolbutton.inc:85`, `lcl/include/toolbutton.inc:169`, `lcl/include/toolbutton.inc:316`, `lcl/include/toolbutton.inc:892`
- toolbar dropdown menu path: `lcl/include/toolbar.inc:1067`

GTK4 usable behavior:

- `TGtk4WSToolBar.CreateHandle` creates `TGtk4ToolBar`.
- `TGtk4ToolBar.CreateWidget` creates a `GtkOverlay` with a targetable `GtkFixed` central widget and paint area.
- The GTK4 source explicitly states that toolbar rendering is kept in LCL, like the GTK2/Qt5 path, to preserve dynamic `ImageList`-driven IDE toolbar/component-palette updates.
- LCL `TToolBar` owns button ordering, wrapping, image-list change handling, visible-bar updates, and dropdown menu coordination.
- LCL `TToolButton` owns mouse-down/up state, check/dropdown/buttondrop behavior, `OnPaintButton`, and destruction-safe click handling.

Comparison notes:

- GTK2 also creates a simple host (`gtk_hbox_new`) plus fixed client widget and generic callbacks. It does not register a native `TCustomToolButton` widgetset class in the reviewed factory.
- Qt5 registers `TToolBar` to `TQtWSToolBar`, but that class creates `TQtCustomControl`, not `TQtToolBar`. The source note says the LCL toolbar implementation is not a native toolbar mapping.
- GTK4 therefore is not uniquely non-native here. It follows the same practical architecture: a host widget for an LCL-managed toolbar surface.

GTK4 limitations and risk points found by source review:

- There is no direct GTK4-native `TCustomToolButton` widgetset registration. GTK2 and Qt5 also return false for direct `TCustomToolButton`, so this is not GTK4-only.
- Because toolbar buttons are LCL-painted/managed, fidelity depends on generic custom-control paint, mouse, hit-test, focus, hint, popup menu, and image-list behavior in GTK4. A defect in any of those lower layers will show up as a toolbar defect.
- `TGtk4ToolBar.ButtonClicked` exists and calls `TToolButton.Click`, but the reviewed create path does not create native GTK4 button children for every `TToolButton`; this callback does not prove native button-per-item behavior.
- Dynamic image updates are intentionally preserved by LCL painting, but this needs runtime validation for normal, disabled, hot, and changed image lists.
- Dropdown buttons rely on LCL `TToolButton.CheckMenuDropdown` / `TToolBar.CheckMenuDropdown` and GTK4 popup menu behavior. Any GTK4 menu limitations documented in `wsmenus.pp` can affect toolbar dropdowns.

ToolBar detailed judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| toolbar host creation | `usable_with_limits` | Real GTK4 overlay/fixed host exists. |
| native toolbar item model | `not_applicable` | GTK2/Qt5 reviewed paths also do not use direct native toolbutton registration for LCL toolbar behavior. |
| LCL-painted button layout/wrapping | `usable_with_limits` | Focused GTK4 runs confirmed basic button/separator/dropdown bounds, runtime button-size updates, and constrained-width automatic wrapping when the toolbar is not forced to full form width. |
| image-list update behavior | `usable_with_limits` | Focused GTK4 runs confirmed runtime `Images` replacement completed and button bounds survived. Default-paint validation confirmed normal `Images`, `DisabledImages`, and stable-state `HotImages` pixels; the hot-image proof uses an actual Xvfb screen capture because toolbar-internal `PaintTo` was not reliable after forced `MouseEnter`. |
| dropdown tool buttons | `usable_with_limits` | LCL path exists; focused mouse-input runs show the precise `tbsDropDown` arrow-area click follows the same no-`OnClick`/no-`OnArrowClick` menu path under GTK4, GTK2, and Qt5. Later GTK4 runs confirmed repeated popup open/close, basic menu item activation, submenu page navigation, mutated submenu item activation, popup-open menu mutation, and tested X11/Xvfb right/bottom/bottom-right edge placement; remaining popup validation is IDE integration. |
| design-time toolbar/component palette behavior | `usable_with_limits` | Real Lazarus IDE GTK4 run with a temporary `--pcp` confirmed component-palette page hit testing, component-button hit testing, `TButton` insertion into the form designer, source/form update side effects, component-button popup, and page/control popup. Focused tests confirmed GTK4 `THintWindow`, `TToolButton` hints, and standalone `TSpeedButton` hints work. A later gdb run showed earlier palette hint misses were caused by Xvfb top-level overlap selecting `SynEdit1`; after moving Source Editor out of the toolbar area, the palette `TButton` hint reached `ActivateHintData` and appeared as a top-level hint window. Main-toolbar hint absence matches an IDE `mainbar.pas` hint-assignment TODO and is not a demonstrated GTK4 hint-window/component-palette defect. |

Focused runtime validation:

- Document: `PLAN_GTK4_TOOLBAR_VALIDATION.md`
- Example: `example_gtk4_toolbar_validation/`
- Build/run date: 2026-07-09 and 2026-07-10
- Build result: `./lazbuild --ws=gtk4 example_gtk4_toolbar_validation/toolbar_validation.lpi` succeeded.
- Auto run result: completed without Pascal exception.
- Result summary: `TToolBar.HandleAllocated=True`, `ButtonCount=6`, `ControlCount=6`; normal/check/separator/dropdown/buttondrop/disabled buttons had plausible LCL child bounds; `OnPaintButton` fired for six buttons; programmatic `Click` and `ArrowClick` fired events; runtime image-list replacement and button-size/list/caption changes completed. A second run added an independent `Align=alNone` narrow toolbar; GTK4 placed its six buttons across three rows at width `220`, matching the practical GTK2/Qt5 comparison pattern. `RowCount=0` remained true under GTK4, GTK2, and Qt5, and source review shows this is maintained in common `toolbar.inc`, so it is not proven as a GTK4-specific defect. A third run replayed real X11 mouse clicks; GTK4 delivered normal-button clicks and check-button toggle (`Down=True`) through the user path. A precise `tbsDropDown` arrow-area click produced no `OnClick` or `OnArrowClick` under GTK4, GTK2, or Qt5, matching common LCL menu handling. A fourth run used a default-paint visual toolbar and internal `PaintTo` snapshot; GTK4 rendered normal image-list pixels and disabled image-list pixels. A fifth run added popup counters; GTK4 repeated dropdown open/close by Escape produced `menuPopup=2` and `menuClose=2` without exception, and menu item activation produced final `menuPopup=1`, `menuClose=1`, `menuItemClick=1`. GTK2 and Qt5 comparison runs also activated the same popup item in the same focused example. GTK4 logged popup point `(161,46)` while GTK2/Qt5 logged `(267,148)` in the Xvfb setup; because GTK4 item activation worked at the expected toolbar-local popup location, this is recorded as an observed coordinate-reporting difference rather than proof of a visible placement defect. A sixth run added popup-open mutation and submenu counters; GTK4 mutation while open produced `menuMutation=1`, submenu page navigation was visible in a screenshot, and clicking the mutated submenu item produced `submenuClick=1`. GTK2 also activated the mutated submenu item. Qt5 showed the mutated item in the open menu, but the attempted Xvfb root-coordinate submenu activation did not reproduce `OnSubMenuItemClick`; this is not evidence of a GTK4 defect. A seventh run moved the GTK4 test window to X11/Xvfb right, bottom, and bottom-right screen edges; popup points reached `(1191,46)`, `(161,976)`, and `(1191,976)` on a `1280x1024` root, screenshots showed the popup visible inside the screen, and the bottom-right visible item click produced `menuItemClick=1`. GTK2/Qt5 comparison screenshots for the same bottom-right window move showed the popup clipped at the bottom edge. An eighth run forced a stable hot state in the visual toolbar; GTK4 `GetCurrentIcon` changed from `Images` to `HotImages`, and the actual Xvfb screen capture contained `#00FF00 256` hot-image pixels. GTK2 and Qt5 comparison captures also contained `#00FF00 256`. A ninth run launched the real GTK4 Lazarus IDE with a temporary `--pcp`; component-palette tab hit testing, `TButton` palette selection, design-time insertion, source/form update side effects, component-button popup, and page/control popup worked. A tenth run confirmed ordinary GTK4 `THintWindow`, `TToolButton` hint, and standalone `TSpeedButton` hint display in focused examples. An eleventh run showed external X11 scans alone were insufficient for IDE hints. A twelfth gdb run showed default Xvfb palette coordinates resolved to `SynEdit1`; after moving Source Editor to `+0+140`, the palette `TButton` hint reached `ActivateHintData` and appeared as a top-level hint window. Main-toolbar hint absence remains an IDE mainbar hint-assignment/configuration topic.

Required ToolBar tests:

1. Normal toolbar with buttons, separators, check buttons, dropdown buttons, buttondrop buttons, and custom child controls.
2. `Images`, `DisabledImages`, and `HotImages`, including runtime image-list changes after handle creation. Normal `Images`, `DisabledImages`, and stable-state `HotImages` are pixel-confirmed in the focused GTK4 visual toolbar.
3. `ShowCaptions`, `List`, `Flat`, `Wrapable`, `ButtonWidth`, `ButtonHeight`, `Indent`, horizontal/vertical layout, RTL alignment, and autosize.
4. `OnClick`, `OnMouseDown/Up`, `OnPaintButton`, destruction during click handler, and checked-state transitions. Initial real mouse checks for normal/check buttons are complete. Destruction during click handler confirmed safe 2026-07-10 (Validation Run 13): deferred `ReleaseComponent`, synchronous sibling free, and synchronous self-free survive real X11 clicks for both graphic-control tool buttons AND windowed `TButton` cases, with GTK2 parity; `TGtk4Widget.GtkEventMouse` additionally gained a live-widget-registry guard so the post-`LM_*UP` `LM_CONTEXTMENU`/`LM_CLICKED` path can never run against a wrapper freed by user code.
5. Dropdown menu from `DropdownMenu` and `MenuItem`. Basic GTK4 repeated open/close, item activation, submenu page navigation, mutated submenu item activation, menu mutation while open, tested X11/Xvfb edge placement, and real IDE component-palette popup paths are confirmed.
6. Lazarus IDE component palette and main toolbar scenarios under GTK4. Component-palette hit testing, insertion, popups, and hover hints are confirmed in the tested X11/Xvfb path when the target coordinate resolves to the palette control. Main-toolbar hint absence is tracked as an IDE mainbar hint-assignment/configuration topic, not as a demonstrated GTK4 hint-window failure.

#### 4.12 UpDown and TreeView Registration Review

`wscomctrls.pp` declares `TWSCustomUpDown`, `TWSUpDown`, `TWSCustomTreeView`, and `TWSTreeView`. The baseline methods for `TWSCustomUpDown` are no-op setters. The fallback registration blocks for `TCustomUpDown` and `TCustomTreeView` are commented out, so the controls depend on the widgetset factory choosing to register them.

Source references:

- baseline updown declarations and no-op methods: `lcl/widgetset/wscomctrls.pp:208`, `lcl/widgetset/wscomctrls.pp:290`
- baseline treeview declarations: `lcl/widgetset/wscomctrls.pp:260`
- baseline registration delegates with commented fallback: `lcl/widgetset/wscomctrls.pp:1044`, `lcl/widgetset/wscomctrls.pp:1089`
- GTK4 class declarations and factory result: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:205`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:244`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:198`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:220`
- GTK2 class declarations and factory result: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:243`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:285`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:207`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:232`
- Qt5 class declarations and factory result: `lcl/interfaces/qt5/qtwscomctrls.pp:232`, `lcl/interfaces/qt5/qtwscomctrls.pp:268`, `lcl/interfaces/qt5/qtwsfactory.pas:195`, `lcl/interfaces/qt5/qtwsfactory.pas:217`

Registration comparison:

| Component | GTK2 | Qt5 | GTK4 | Judgment |
| --- | --- | --- | --- | --- |
| `TCustomUpDown` | not registered | not registered | not registered | Not a GTK4-specific gap in the reviewed widgetsets. |
| `TCustomTreeView` | not registered | not registered | not registered | Not a GTK4-specific gap in the reviewed widgetsets. |

Important distinction:

- The presence of `TGtk4WSCustomUpDown` / `TGtk4WSCustomTreeView` class declarations does not mean usable implementation exists, because the factories return `False` and no registration occurs.
- Since GTK2 and Qt5 also return `False`, these should not be used as examples of GTK4 falling behind GTK2/Qt5. They are common unregistered areas in the reviewed LCL widgetset paths.

Required checks:

1. Confirm whether LCL has non-widgetset/common fallback behavior for these controls in real applications before planning GTK4-only work. This is now confirmed for `TUpDown`; it still needs confirmation for `TTreeView`.
2. If a future task targets `TTreeView`, treat it as a larger cross-widgetset feature decision, not a GTK4 parity catch-up against GTK2/Qt5.
3. If a future task targets `TUpDown`, compare against actual user expectations and any platform-specific alternatives, because GTK2/Qt5 do not provide registered reference implementations here.

Focused UpDown runtime validation:

- Document: `PLAN_GTK4_UPDOWN_VALIDATION.md`
- Example: `example_gtk4_updown_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_updown_validation/updown_validation.lpi` succeeded.
- Auto run result: completed without Pascal exception.
- Result summary: `TUpDown` created two `TUpDownButton` fallback children. Position/increment/min/max/wrap behavior worked through fallback clicks; `Associate` updated edit text/caption; `OnChanging`, `OnChangingEx`, and `OnClick` fired; horizontal orientation changed child button layout to left/right halves. The run also showed an associated-layout anomaly where UpDown height grew from `35` to `53` across click/wrap state changes.

Focused TreeView runtime validation:

- Document: `PLAN_GTK4_TREEVIEW_VALIDATION.md`
- Example: `example_gtk4_treeview_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_treeview_validation/treeview_validation.lpi` succeeded.
- Auto run result: completed without Pascal exception.
- Result summary: `TTreeView.HandleAllocated=True` after show; `Items.Count=7`; expansion, single selection, multi-selection, visible-node `DisplayRect`, and visible-node `GetNodeAt(center)` worked through the common LCL implementation. Invisible child nodes retained stale/non-visible display rectangles before expansion and after parent collapse, and hit tests at those stale centers returned currently visible nodes. Multi-selection state also remained on collapsed/invisible nodes in the focused run.

### 5. `lcl/widgetset/wscontrols.pp`

This file is a foundation layer, not a leaf component file. The current pass covers registration, accessibility, drag-image behavior, generic `TWinControl` behavior, and the most visible GTK4 differences against GTK2/Qt5. A deeper follow-up is still needed for every helper path in `gtk4objects`.

#### 5.1 Baseline Expectation

`wscontrols.pp` declares the widgetset hooks for:

- `TWSDragImageListResolution`: drag image lifecycle.
- `TWSLazAccessibleObject`: accessible handle and accessible metadata.
- `TWSControl`: generic control registration, constraints, default color, canvas scale.
- `TWSWinControl`: focus, client geometry, preferred size, text, bidi, bounds, color, z-order, font, cursor, shape, handle lifecycle, paint/invalidate/show/scroll.
- `TWSCustomControl`: generic custom-control handle behavior.

Most baseline bodies are no-op/default behavior. Important defaults include:

- `TWSWinControl.CreateHandle` returns `0`.
- `TWSWinControl.GetText` returns `False`.
- `TWSWinControl.GetDefaultClientRect` returns `False`.
- `TWSWinControl.GetDesignInteractive` returns `False`.
- `TWSWinControl.SetShape`, `SetBounds`, `SetText`, `SetColor`, `SetFont`, and most setters are no-op.
- `TWSDragImageListResolution` returns `False` for drag image operations.

Source references:

- Baseline declarations: `lcl/widgetset/wscontrols.pp:45`, `lcl/widgetset/wscontrols.pp:61`, `lcl/widgetset/wscontrols.pp:78`, `lcl/widgetset/wscontrols.pp:96`
- Baseline `TWSWinControl` defaults: `lcl/widgetset/wscontrols.pp:260`
- Baseline drag image defaults: `lcl/widgetset/wscontrols.pp:370`
- Registration fallbacks: `lcl/widgetset/wscontrols.pp:406`

#### 5.2 Registration Comparison

| Class/group | GTK2 registration | Qt5 registration | GTK4 registration | Initial conclusion |
| --- | --- | --- | --- | --- |
| `TLazAccessibleObject` | not registered | not found in reviewed factory section | registered | GTK4 has more implementation here than GTK2 in reviewed sources. |
| `TControl` | not registered | not registered | not registered | Not a GTK4 gap. |
| `TWinControl` | registered | registered | registered | Core generic control path exists in all three. |
| `TGraphicControl` | not registered | not registered | not registered | Not a GTK4 gap. |
| `TCustomControl` | not registered | registered | registered | GTK4 matches Qt5 here and is more specific than GTK2. |
| `TDragImageListResolution` | implemented | implemented | implemented but visual image unavailable | GTK4 behavior differs materially. |

Source references:

- GTK4 factory registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:147`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:152`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:158`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:163`
- GTK2 factory registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:150`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:156`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:163`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:169`
- Qt5 factory registration: `lcl/interfaces/qt5/qtwsfactory.pas:144`, `lcl/interfaces/qt5/qtwsfactory.pas:149`, `lcl/interfaces/qt5/qtwsfactory.pas:155`
- GTK4 `TCustomControl` registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:163`
- Qt5 `TCustomControl` registration: `lcl/interfaces/qt5/qtwsfactory.pas:160`

#### 5.3 Accessibility

GTK4 registers `TGtk4WSLazAccessibleObject`. It uses the owning wincontrol's GTK widget handle as the accessible handle, and maps accessible name, description, and value to GTK4 accessible properties.

Source references:

- GTK4 accessible implementation: `lcl/interfaces/gtk4/gtk4wscontrols.pp:145`
- GTK4 registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:141`
- GTK2 reviewed factory returns false for accessible object registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:143`

GTK4 accessibility judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` / `DestroyHandle` | `usable_with_limits` | Uses the owning widget handle and destroys nothing separately, matching GTK4's built-in accessible model. |
| Name / description / value | `usable` | Updates GTK4 accessible properties. |
| Role | `backend_limited` | Source states GTK4 widget roles are construction-time defaults and cannot be changed after construction. |
| Position / size | `usable_with_limits` | Delegated to GTK4 widget geometry. Needs assistive-tech runtime validation. |

#### 5.4 Drag Image List

GTK2 and Qt5 implement visual drag images through widgetset-specific drag image managers. GTK4 contains a `TGtk4WSDragImageListResolution` implementation whose source comment cites GTK4/Wayland removal of arbitrary window positioning and returns success so the drag operation itself can continue. However, the active GTK4 factory currently returns `False` from `RegisterDragImageListResolution`, so the public `TDragImageList` path falls back to the base `TWSDragImageListResolution` implementation.

Source references:

- GTK2 drag image implementation: `lcl/interfaces/gtk2/gtk2wscontrols.pp:382`
- Qt5 drag image implementation: `lcl/interfaces/qt5/qtwscontrols.pp:800`
- GTK4 drag image implementation/comment: `lcl/interfaces/gtk4/gtk4wscontrols.pp:801`
- GTK4 drag image factory registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:136`

GTK4 drag image judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `BeginDrag` / `DragMove` / `ShowDragImage` / `HideDragImage` / `EndDrag` | `usable_with_limits` (fixed 2026-07-10) | The GTK4 no-visual implementation is now registered by the factory (gtk2/qt5 pattern). Runtime-confirmed: `BeginDrag=True`, `Dragging` toggles correctly across the full lifecycle. The visual overlay itself remains a documented GTK4/Wayland backend limitation. The previously recorded shared LCL-core caveat (custom dock objects: `TDockPerformer.DragStop` never called `FDragImageList.EndDrag` on any widgetset) was fixed in LCL core on 2026-07-10 with user approval, runtime-verified on gtk4/gtk2/qt5 — see `PLAN_GTK4_WSCONTROLS_VALIDATION.md`, "LCL Core Fix". |

Required runtime tests:

1. Drag from controls that use `TDragImageList`.
2. Confirm drag messages/cursor behavior continue normally.
3. Decide whether to register the existing no-visual GTK4 drag-image resolution class so `BeginDrag` succeeds, or document the current `BeginDrag=False` behavior as the supported GTK4 limitation.
4. Confirm no visual drag image appears on GTK4, and document that as intentional backend limitation unless a GTK4-safe overlay strategy is designed.

#### 5.5 Generic WinControl Review

GTK4 implements most of the same generic `TWSWinControl` method surface as Qt5. The implementation delegates to `TGtk4Widget` subclasses and `gtk4objects`.

Source references:

- GTK4 declarations: `lcl/interfaces/gtk4/gtk4wscontrols.pp:91`
- GTK4 generic handle creation: `lcl/interfaces/gtk4/gtk4wscontrols.pp:366`
- GTK4 `TCustomControl` handle creation: `lcl/interfaces/gtk4/gtk4wscontrols.pp:790`
- GTK4 geometry/text/font/color/cursor/shape methods: `lcl/interfaces/gtk4/gtk4wscontrols.pp:425`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:460`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:585`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:645`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:655`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:662`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:669`
- Qt5 generic handle/geometry/text/font/shape references: `lcl/interfaces/qt5/qtwscontrols.pp:232`, `lcl/interfaces/qt5/qtwscontrols.pp:298`, `lcl/interfaces/qt5/qtwscontrols.pp:346`, `lcl/interfaces/qt5/qtwscontrols.pp:530`, `lcl/interfaces/qt5/qtwscontrols.pp:714`, `lcl/interfaces/qt5/qtwscontrols.pp:756`
- GTK2 generic handle/geometry/text/font/shape references: `lcl/interfaces/gtk2/gtk2wscontrols.pp:168`, `lcl/interfaces/gtk2/gtk2wscontrols.pp:626`, `lcl/interfaces/gtk2/gtk2wscontrols.pp:876`, `lcl/interfaces/gtk2/gtk2wscontrols.pp:794`, `lcl/interfaces/gtk2/gtk2wscontrols.pp:996`

Generic GTK4 judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` | `usable_with_limits` | Generic `TWinControl` creates a `TGtk4Panel`; `TCustomControl` creates a `TGtk4CustomControl`. Specific controls override this where needed. |
| `DestroyHandle` | `usable` | Frees the `TGtk4Widget` handle object. |
| `AddControl` | `usable_with_limits` (validated 2026-07-10) | Reparents via `TGtk4Widget.SetParent`. The cast is safe: the only LCL call site passes a `TWinControl` (`Self`); runtime reparenting validated (see §5.7). |
| `CanFocus` | `usable` | Delegates to `TGtk4Widget.CanFocus` when handle is allocated. |
| `GetClientBounds` / `GetClientRect` | `usable_with_limits` | Delegates to `TGtk4Widget.getClientBounds/getClientRect`; correctness depends on each GTK4 widget subclass. |
| `GetDefaultClientRect` | `stub_or_noop` | Returns `False`, same as baseline. Many specific controls override where needed. |
| `GetDesignInteractive` | `stub_or_noop` | Returns `False`, same as Qt5 generic implementation; specific controls override when needed. |
| `GetPreferredSize` | `usable_with_limits` | Delegates to `TGtk4Widget.preferredSize`; runtime comparison is needed per widget type. |
| `GetText` / `GetTextLen` | `usable` | Delegates to `TGtk4Widget.Text`. |
| `SetText` | `usable` | Delegates to `TGtk4Widget.Text`. |
| `SetBiDiMode` | `usable_with_limits` | Maps `UseRightToLeftAlign` to GTK widget direction. It does not separately handle reading/scrollbar flags in the reviewed method. |
| `SetBounds` / `SetPos` / `SetSize` | `usable_with_limits` | Delegates to GTK4 widget move/size logic. Needs layout stress tests under scrolling parents and forms. |
| `SetBorderStyle` | `usable_with_limits` | Delegates to `TGtk4Widget.SetBorderStyle`; exact parity depends on subclass support. |
| `SetChildZPosition` | `usable_with_limits` | Implements raise/lower/stack-under similar to Qt5 logic. Requires overlap tests. |
| `SetColor` | `usable_with_limits` | Delegates to `TGtk4Widget.Color`; CSS/subclass behavior must be tested per control family. |
| `SetCursor` | `usable` | Delegates to `TGtk4Widget.SetCursor`. |
| `SetFont` | `usable_with_limits` | Delegates to `TGtk4Widget.SetLclFont`. Charset support was handled in the earlier SetLclFont work, but per-widget CSS inheritance still needs testing. |
| `SetShape` | `backend_limited` | Explicit no-op because GTK4 removed shape combine APIs and Wayland does not support this window-shape model. Qt5 implements masks. |
| `ConstraintsChange` | `usable_with_limits` | Contains substantial GTK4-specific window constraint emulation. This is important but high risk and needs form/window runtime tests. |
| `Invalidate` / `Repaint` | `usable_with_limits` | Both call `TGtk4Widget.Update(nil)`; timing and paint invalidation need tests for custom controls. |
| `PaintTo` | `usable_with_limits` | Uses `GtkWidgetPaintable`/snapshot/render-node drawing to cairo. This is GTK4-appropriate but should be tested for child rendering and hidden/unrealized controls. |
| `ShowHide` | `usable_with_limits` | Sets widget visibility and calls `ShowAll`; recent startup-hide work makes this area sensitive and needs regression tests. |
| `ScrollBy` | `usable` (fixed 2026-07-10) | Adjusts `GtkScrolledWindow` adjustments and invalidates; now guards with `is TGtk4ScrollableWin` and casts to that ancestor (see §5.7). |
| `DefaultWndHandler` | `shared_baseline` (traced 2026-07-10) | GTK4 no-op is net-equivalent to GTK2/Qt5 — both reach the empty base `TWidgetSet.CallDefaultWndHandler` (see §5.7). |

Source-quality notes:

- `TGtk4WSWinControl.SetShape` is a clear backend limitation rather than an accidental stub.
- `TGtk4WSWinControl.DefaultWndHandler` should be checked for message paths that expect default processing.
- `TGtk4WSWinControl.SetBounds` contains a debug-only reference to `AWidget` in the reviewed source. If `GTK4DEBUGSIZE` or related debug defines are enabled, this path should be compile-checked.
- `TGtk4WSWinControl.ScrollBy` casts the handle to `TGtk4ScrollingWinControl` before verifying that the handle type is scrollable; this should be runtime-reviewed with non-scrolling controls if LCL can call `ScrollBy` on them.

#### 5.6 `wscontrols.pp` Scope Result

GTK4's core `TWinControl` implementation is substantial and broadly comparable to Qt5 in method coverage, but several areas are not GTK2/Qt5-equivalent:

1. Visual drag images are unavailable by design on GTK4. (updated 2026-07-10: the no-visual GTK4 drag-image resolution class is now REGISTERED, so `TDragImageList.BeginDrag`/`Dragging` behave like other widgetsets; only the on-screen overlay remains a backend limitation.)
2. Window/control shape masks are unavailable by design on GTK4.
3. Generic default window handling is no-op in GTK4. (resolved 2026-07-10: traced as net-equivalent to GTK2/Qt5, which reach the empty base `CallDefaultWndHandler` — not a fix candidate.)
4. Constraint/window sizing code is GTK4-specific and high risk.
5. Generic client geometry and preferred size correctness depends heavily on individual `TGtk4Widget` subclasses.
6. Accessibility metadata is more implemented in GTK4 than in the reviewed GTK2 path, but still needs runtime validation with actual assistive tooling.

Required follow-up tests:

1. Generic `TCustomControl` painting, invalidation, repaint, and `PaintTo`.
2. Bounds/position/size changes under normal parents, scrolled parents, and forms.
3. Z-order with overlapping child controls.
4. `ScrollBy` on scrolling and non-scrolling controls.
5. `ShowHide` startup-hidden forms and controls, to guard the previous startup-hide fix.
6. `SetShape` expectation/documentation for GTK4.
7. Drag image behavior during drag-and-drop.
8. Accessibility name/description/value propagation on GTK4.

Focused runtime validation:

- Document: `PLAN_GTK4_WSCONTROLS_VALIDATION.md`
- Example: `example_gtk4_wscontrols_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wscontrols_validation/wscontrols_validation.lpi` succeeded.
- Auto run result: direct `WSCONTROLS_VALIDATION_AUTO=1 xvfb-run -a ...` failed to open the GTK display in this environment; `xvfb-run -a env WSCONTROLS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wscontrols_validation/wscontrols_validation` completed without Pascal exception.
- Result summary: generic GTK4 `TCustomControl` handle creation worked; initial client/preferred sizes matched assigned bounds; initial painting occurred; `PaintTo` into a bitmap canvas completed and increased the paint count; runtime `SetBounds` on the custom control and a child inside `TScrollBox` updated public bounds; hidden-panel show/hide completed; overlapping child `BringToFront` changed `ControlAtPos` results as expected. `TScrollBox.ScrollBy(-40,-50)` completed but public scrollbar positions stayed `(0,0)` in this run. `TPanel.ScrollBy(12,18)` moved child controls through inherited LCL `TWinControl.ScrollBy`, so it does not prove the GTK4 widgetset `ScrollBy` body.
- Debug build result: `./lazbuild --ws=gtk4 -B -r --opt=-dGTK4DEBUGSIZE example_gtk4_wscontrols_validation/wscontrols_validation.lpi` succeeded. The earlier debug-only `SetBounds` compile concern is not reproduced on the current source/compiler configuration.

#### 5.7 Method-Surface Second Pass

This pass rechecked the full `wscontrols.pp` method surface against the GTK4, GTK2, and Qt5 declarations and implementation bodies. The purpose was to separate real GTK4 gaps from shared baseline behavior.

Source references:

- baseline method declarations: `lcl/widgetset/wscontrols.pp:45`, `lcl/widgetset/wscontrols.pp:61`, `lcl/widgetset/wscontrols.pp:78`, `lcl/widgetset/wscontrols.pp:96`
- baseline method bodies: `lcl/widgetset/wscontrols.pp:180`
- GTK4 declarations: `lcl/interfaces/gtk4/gtk4wscontrols.pp:42`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:91`
- GTK2 declarations: `lcl/interfaces/gtk2/gtk2wscontrols.pp:35`, `lcl/interfaces/gtk2/gtk2wscontrols.pp:59`
- Qt5 declarations: `lcl/interfaces/qt5/qtwscontrols.pp:30`, `lcl/interfaces/qt5/qtwscontrols.pp:60`
- GTK4 core implementations: `lcl/interfaces/gtk4/gtk4wscontrols.pp:267`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:366`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:387`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:397`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:472`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:504`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:529`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:585`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:662`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:669`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:720`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:742`

Shared or non-GTK4-specific behavior:

- `TWSControl.GetConstraints`, `ConstraintWidth`, `ConstraintHeight`, `GetDefaultColor`, and `GetCanvasScaleFactor` have no meaningful GTK4-specific override in the reviewed class. GTK2 and Qt5 also expose empty `TWSControl` subclasses in the reviewed declarations, so this is not a GTK4-only omission.
- `GetDoubleBuffered` is not overridden by GTK4/GTK2/Qt5 in the reviewed declarations; all use the baseline return of `AWinControl.DoubleBuffered`.
- `AdaptBounds` is effectively no-op in GTK4, and no stronger GTK2/Qt5 generic implementation was found in the reviewed declarations. This is not a current GTK4-specific quality gap.
- `GetDefaultClientRect` and `GetDesignInteractive` remain generic false in GTK4, similar to Qt5's generic `GetDesignInteractive`; control-specific classes are expected to override where this matters.

GTK4 behavior that is comparable to Qt5/GTK2:

- `CreateHandle` creates a real GTK4 wrapper object (`TGtk4Panel`) for generic `TWinControl`, comparable in purpose to Qt5's generic `TQtWidget` creation and GTK2's API widget creation.
- `DestroyHandle`, `CanFocus`, client bounds/rect, text get/set, preferred size, bidi widget direction, bounds/pos/size, z-order, color, cursor, font, invalidate/repaint, `PaintTo`, and visibility are all implemented with real GTK4 wrapper calls.
- `SetChildZPosition` follows the same high-level algorithm as Qt5: simple raise/lower for edges and stack-under for middle positions. GTK2 uses its private widget z-order helper instead.
- `PaintTo` uses a GTK4-native render path (`GtkWidgetPaintable` -> snapshot -> `GskRenderNode` -> cairo), while Qt5 renders through `QWidget_render` and GTK2 captures/draws through GDK/GTK2 paths. The GTK4 approach is appropriate for GTK4 but needs runtime comparison because the rendering model is different.

GTK4-specific risks confirmed by source review:

- `DefaultWndHandler` is a no-op in GTK4. The baseline implementation calls `WidgetSet.CallDefaultWndHandler`, and Qt5/GTK2 do not override it in the reviewed declarations, so GTK4 is weaker for message paths that expect default processing.
- `AddControl` casts `AControl` to `TWinControl` before checking its type. Qt5 explicitly guards with `(AControl is TWinControl) and HandleAllocated`. GTK4 may be safe if only windowed controls reach this widgetset method, but the source itself is less defensive.
- `ScrollBy` casts `AWinControl.Handle` to `TGtk4ScrollingWinControl` before confirming the handle is actually a scrolled-window wrapper. The following `Gtk4IsScrolledWindow` check happens after this cast. Runtime testing must include accidental/non-scrolling call paths.
- `SetBounds` contains a debug-only log reference to `AWidget` after calling `SetBounds`, but no local `AWidget` variable is declared in that method. Normal builds do not compile that block unless GTK4 size/core debug defines are enabled; debug-build compile checks are required before relying on those defines.
- `ConstraintsChange` is a substantial GTK4-specific emulation because GTK4 removed `gtk_window_set_geometry_hints`. It uses `set_size_request`, `set_default_size`, menu-bar/non-client overhead compensation, and `TGtk4Window.SetMaxSize`. Focused runtime validation confirms the code path is active for normal forms, menu-bar forms, and hidden-at-startup forms, but it is not equivalent to GTK2's `gtk_window_set_geometry_hints` path or Qt5's `TQtWidget.ConstraintsChange`; user-driven window-manager resize and max-size semantics still need fix-design review.
- `SetShape` is intentionally no-op because GTK4/Wayland removed the old shape-combine model. GTK2 and Qt5 both implement shape masks. This is a real backend limitation, not a missing simple setter.

Second-pass judgments:

| Method group | GTK4 status | Reason |
| --- | --- | --- |
| `TWSControl` constraints/default color/canvas scale | `shared_baseline` | GTK4/GTK2/Qt5 do not materially improve this generic layer in the reviewed classes. |
| generic handle lifecycle | `usable_with_limits` | Real wrapper creation/destruction exists; correctness depends on subclass-specific wrappers and lifecycle tests. |
| generic text/client/preferred-size methods | `usable_with_limits` | Wrapper calls exist; per-control correctness must be verified where widgets override text/client concepts. |
| `DefaultWndHandler` | `shared_baseline` (traced 2026-07-10) | The GTK4 no-op is net-equivalent to GTK2/Qt5: neither overrides the method and both reach the EMPTY base `TWidgetSet.CallDefaultWndHandler` (`intfbaselcl.inc:55`); GTK3 is also an explicit no-op. Not a fix candidate unless a concrete message path is proven to have real fallback behavior elsewhere. |
| `AddControl` | `usable_with_limits` (validated 2026-07-10) | The only LCL call site is `TWinControl.AddControl` passing `Self` (`wincontrol.inc:6185`), so the argument is always a handle-checked `TWinControl`; runtime reparenting validated. Qt5's extra type guard is purely defensive. |
| `ConstraintsChange` | `usable` (fixed 2026-07-10) | Focused runtime tests validate normal forms, menu-bar overhead, fixed/min/max cases, and hidden-startup show. The max-as-effective-minimum coercion was removed (see §5.7 and `PLAN_GTK4_WSCONTROLS_VALIDATION.md` "Implementation Fix 4"): `set_size_request` now uses the real LCL Min only, Max is enforced by the snap-back; Min and Max both carry menu-bar overhead. Fixed-size (Min=Max) forms unaffected; real WM-drag resize still relies on the native path. |
| `SetShape` | `backend_limited` | GTK4/Wayland no longer support the old window-shape mechanism. |
| `PaintTo` | `usable` (fixed 2026-07-10) | Visible custom controls paint via GtkWidgetPaintable. A control created hidden then shown had a NULL cached render_node → blank output; now falls back to a live `gtk_widget_snapshot_child` snapshot (see §5.7 and `PLAN_GTK4_WSCONTROLS_VALIDATION.md` "Implementation Fix 3"), runtime-confirmed rendering real content including captions. |
| `ScrollBy` | `usable` (fixed 2026-07-10) | Native adjustment behavior runtime-proven for `TScrollBox` and `TMemo`; the unverified hard cast to `TGtk4ScrollingWinControl` was replaced with an `is TGtk4ScrollableWin` guard + ancestor cast (the class that declares `GetScrolledWindow`/`ScrollX`/`ScrollY`; a `TGtk4Memo` handle reaches this method via `TCustomMemo.ScrollBy`). |

Follow-up fix (2026-07-10, from the user-reported Object Inspector symptom): children of LCL-managed scrolled containers (`TGtk4CustomControl` — OI property grid, grids) were rendered adjustment-value pixels above their LCL client position, because the GtkViewport physically shifts the child GtkFixed while the LCL places in-place editors at plain client coordinates. The paint side already compensated (`cairo_translate` in `LCLGtkFixedSnapshot`); the same compensation is now applied to child placement (`Gtk4ParentScrollOffset` in `TGtk4Widget.Move`/`TGtk4Container.AddChild`, symmetric subtraction in `GetPosition`, and re-pinning of children on adjustment changes). `TGtk4ScrollingWinControl` (TScrollBox) and forms are excluded — there the viewport shift is the scrolling mechanism. Verified in the real IDE (OI editor lands on its row at any scroll offset) with the 43-step suite unchanged. Details: `PLAN_GTK4_WSCONTROLS_VALIDATION.md`, "Implementation Fix 2".

Additional required checks from this pass:

1. Build GTK4 with debug defines that enable the `SetBounds` debug block and confirm it still compiles. This was checked with `-dGTK4DEBUGSIZE` on 2026-07-09 and succeeded.
2. Trace LCL call sites for `TWSWinControl.DefaultWndHandler` under GTK4 and identify whether any messages lose required default processing.
3. Test `AddControl` with normal `TWinControl` children, graphic controls hosted by custom controls, and design-time reparenting.
4. Test `ScrollBy` only on controls that are known scrollable and then on representative non-scrolling controls if LCL can dispatch it there.
5. Validate real window-manager resize and fixed-height IDE-bar scenarios before changing constraints code. Focused automatic tests now cover menu-bar overhead, hidden-at-startup forms, min-only, max-only, and min=max programmatic bounds.

### 6. `lcl/widgetset/wsdesigner.pp`

#### 6.1 Baseline Expectation

`wsdesigner.pp` is narrow. It declares only the widgetset hook for `TCustomRubberBand`, with `TWsCustomRubberBand.SetShape` as an empty baseline method. Registration delegates to `WSRegisterCustomRubberBand`; the fallback `RegisterWSComponent(TCustomRubberBand, TWSCustomRubberBand)` is commented out, so widgetset registration must explicitly provide a class when native `TCustomRubberBand` support is expected.

Source references:

- Baseline declaration: `lcl/widgetset/wsdesigner.pp:43`
- Baseline empty `SetShape`: `lcl/widgetset/wsdesigner.pp:57`
- Registration delegate and commented fallback: `lcl/widgetset/wsdesigner.pp:64`

#### 6.2 GTK2 and Qt5 References

GTK2 does not register `TCustomRubberBand`; `WSRegisterCustomRubberBand` returns `False`. GTK2 still has widgetset-level `CreateRubberBand`, `DestroyRubberBand`, and `SetRubberBandRect` functions elsewhere for the older `WidgetSet.CreateRubberBand` path, but not the `TCustomRubberBand` WSDesigner class path.

Qt5 is the only reviewed widgetset with a dedicated `qtwsdesigner.pp`. It registers `TCustomRubberBand` with `TQtWSCustomRubberBand`, creates a `TQtRubberBand`, maps LCL `TRubberBandShape` to Qt `QRubberBandLine` / `QRubberBandRectangle`, and updates shape by calling `TQtRubberBand.setShape`. `TQtRubberBand.setShape` recreates and reattaches the widget when the shape changes.

Source references:

- GTK2 registration returns `False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:630`
- Qt5 registration: `lcl/interfaces/qt5/qtwsfactory.pas:563`
- Qt5 WSDesigner class and shape mapping: `lcl/interfaces/qt5/qtwsdesigner.pp:52`, `lcl/interfaces/qt5/qtwsdesigner.pp:60`
- Qt5 `CreateHandle` and `SetShape`: `lcl/interfaces/qt5/qtwsdesigner.pp:68`, `lcl/interfaces/qt5/qtwsdesigner.pp:81`
- Qt5 `TQtRubberBand.setShape`: `lcl/interfaces/qt5/qtwidgets.pas:19656`

#### 6.3 GTK4 Review

GTK4 does not have a `gtk4wsdesigner.pp` unit and `WSRegisterCustomRubberBand` returns `False`, matching GTK2 for the `TCustomRubberBand` class registration path. Therefore GTK4 currently does not provide Qt5-equivalent native `TCustomRubberBand` / `SetShape` support.

This does not mean all GTK4 designer support is absent. GTK4 has separate designer paint and key-handling paths in `gtk4widgets.pas` and `gtk4lclintf.inc`. The reviewed code performs two-phase painting for design surfaces: regular paint for grid dots, then designer paint with `FDesignerDC` set so designer items such as selection handles can paint. GTK4 also has `WidgetSet.CreateRubberBand`, but it creates an undecorated semi-transparent GTK window and `SetRubberBandRect` can only resize it; the source explicitly states that GTK4/Wayland cannot position windows arbitrarily.

Source references:

- GTK4 `WSRegisterCustomRubberBand` returns `False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:584`
- GTK4 `CreateRubberBand`: `lcl/interfaces/gtk4/gtk4lclintf.inc:17`
- GTK4 `SetRubberBandRect` Wayland position limitation: `lcl/interfaces/gtk4/gtk4lclintf.inc:1345`
- GTK4 two-phase designer paint call site: `lcl/interfaces/gtk4/gtk4widgets.pas:2904`
- GTK4 `GtkEventDesignerPaint`: `lcl/interfaces/gtk4/gtk4widgets.pas:3245`
- GTK4 `IsDesignerDC`: `lcl/interfaces/gtk4/gtk4lclintf.inc:94`

GTK4 judgments:

| Method/path | GTK4 status | Reason |
| --- | --- | --- |
| `TCustomRubberBand` WS registration | `missing` | `WSRegisterCustomRubberBand` returns `False`; no GTK4 `TWsCustomRubberBand` subclass was found. |
| `TWsCustomRubberBand.SetShape` equivalent | `confirmed_crash` | Focused GTK4 run reproduced `EAccessViolation` at `rubberband.inc:28` when changing `TRubberBand.Shape` after handle allocation. Qt5 maps LCL shapes to native `QRubberBand` shapes; GTK4 has no registered class and no shape method for `TCustomRubberBand`. |
| `WidgetSet.CreateRubberBand` path | `backend_limited` | Focused GTK4 run returned a nonzero handle and allowed `SetRubberBandRect`/destroy under Xvfb/X11, but the implementation uses an undecorated GTK window; position control is unavailable under GTK4/Wayland, so it is not equivalent to GTK2/Qt5 geometry behavior. |
| Designer grid/selection paint | `usable_with_limits` | GTK4 contains explicit two-phase designer paint support, but runtime verification is required for selection handles, grid dots, clipping, and scrolling forms. |

#### 6.4 `wsdesigner.pp` Scope Result

For the baseline file itself, GTK4 is behind Qt5 because `TCustomRubberBand` is not registered and `SetShape` has no GTK4 implementation. This should be treated as a missing `TCustomRubberBand` feature, not as a total absence of GTK4 form-designer support. GTK4's designer paint pipeline exists and has been worked on separately, but RubberBand behavior remains limited by both missing class registration and GTK4/Wayland window-position constraints.

Required follow-up tests:

1. Create a focused sample or IDE scenario that instantiates `TCustomRubberBand` directly and toggles `Shape` between line and rectangle.
2. Compare Qt5 behavior for the same scenario to establish expected LCL behavior.
3. On GTK4, verify whether the current unregistered path falls back, raises an unsupported-widgetset path, or is simply unused by the current Lazarus designer workflow.
4. Test `WidgetSet.CreateRubberBand` on X11 and Wayland separately, because the reviewed GTK4 source documents different practical constraints around arbitrary positioning.
5. Re-test form designer grid dots, selection handles, selection rectangles, scrolling forms, and drag-selection after any future RubberBand change, because these paths are adjacent but not identical.

Focused runtime validation:

- Document: `PLAN_GTK4_WSDESIGNER_VALIDATION.md`
- Example: `example_gtk4_wsdesigner_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsdesigner_validation/wsdesigner_validation.lpi` succeeded.
- Safe auto run: `xvfb-run -a env WSDESIGNER_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsdesigner_validation/wsdesigner_validation` completed without Pascal exception. `TRubberBand.HandleAllocated=True` after show; bounds changes with `Shape=rbsLine` worked; `WidgetSet.CreateRubberBand` returned a nonzero handle and `SetRubberBandRect`/destroy completed.
- Crash run: `xvfb-run -a env WSDESIGNER_VALIDATION_AUTO=1 WSDESIGNER_VALIDATION_CRASH_CASES=1 GDK_BACKEND=x11 example_gtk4_wsdesigner_validation/wsdesigner_validation` failed with `APPLICATION_EXCEPTION EAccessViolation Access violation` immediately after `FRubberBand.Shape := rbsRectangle`.
- GDB stack: top frames were null call, `TCustomRubberBand.SetShape` at `lcl/include/rubberband.inc:28`, then the validation program's `RunStep`. This confirms the crash is on the LCL `WidgetSetClass.SetShape` call path for an unregistered GTK4 `TWsCustomRubberBand`, not inside GTK's `WidgetSet.CreateRubberBand` path.

### 7. `lcl/widgetset/wsdialogs.pp`

#### 7.1 Baseline Expectation

`wsdialogs.pp` defines the widgetset hooks for common dialogs, file/open/save/select-directory dialogs, color dialog/button, font dialog, and task dialog. The baseline `TWSCommonDialog` methods return no handle, no modal behavior, and no event capabilities. `TWSFontDialog` has a special fallback: if a widgetset does not provide a font-dialog class, it can delegate to the registered `TCommonDialog` widgetset class. `TWSTaskDialog.Execute` uses `ExecuteLCLTaskDialog`, so task dialog has a cross-widgetset LCL emulation baseline.

Source references:

- Baseline dialog class surface: `lcl/widgetset/wsdialogs.pp:48`
- Baseline common-dialog no-op methods: `lcl/widgetset/wsdialogs.pp:129`
- FontDialog fallback to `TCommonDialog`: `lcl/widgetset/wsdialogs.pp:150`
- TaskDialog emulation baseline: `lcl/widgetset/wsdialogs.pp:201`
- `TCommonDialog.Execute` handle/capability flow: `lcl/include/commondialog.inc:27`
- `TCommonDialog.DoExecute` event loop and capability logic: `lcl/include/commondialog.inc:130`

#### 7.2 Factory Registration Comparison

GTK4 registers the same primary dialog families as GTK2/Qt5 for common/file/open/color/font/task dialogs. Like GTK2, GTK4 intentionally does not directly register `TSaveDialog` and `TSelectDirectoryDialog`; comments in `gtk4wsfactory.pas` state that those must remain on the `TOpenDialog` widgetset class because `TGtk4WSOpenDialog.CreateHandle` handles save/folder behavior by inspecting the actual LCL object type. Qt5 directly registers `TSelectDirectoryDialog` but not `TSaveDialog`.

`TColorButton` is not registered in GTK2, Qt5, or GTK4 in the reviewed factory sections.

Source references:

- GTK4 dialog registrations and comments: `lcl/interfaces/gtk4/gtk4wsfactory.pas:233`
- GTK4 direct `TSaveDialog` registration intentionally disabled: `lcl/interfaces/gtk4/gtk4wsfactory.pas:251`
- GTK4 direct `TSelectDirectoryDialog` registration intentionally disabled: `lcl/interfaces/gtk4/gtk4wsfactory.pas:266`
- GTK4 `TColorButton` registration returns `False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:282`
- GTK4 task dialog registers baseline `TWSTaskDialog`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:293`

GTK4 registration judgments:

| Dialog family | GTK4 status | Reason |
| --- | --- | --- |
| `TCommonDialog` | `usable_with_limits` | Registered; base `CreateHandle` still returns 0, but concrete subclasses provide real handles. |
| `TFileDialog` / `TOpenDialog` | `usable_with_limits` | Registered and implemented through `GtkFileChooserNative`. |
| `TSaveDialog` | `usable_with_limits` | Not directly registered by design; handled through the `TOpenDialog` class path using the actual LCL object type. |
| `TSelectDirectoryDialog` | `usable_with_limits` | Not directly registered by design; `TGtk4FileDialog.Create` selects folder action for the actual LCL type. |
| `TColorDialog` | `usable_with_limits` | Registered with GTK4 color chooser dialog. |
| `TColorButton` | `missing` | Not registered, matching GTK2/Qt5 factory behavior. |
| `TFontDialog` | `partial` | Registered and usable for basic font selection, but option parity is weaker than GTK2/Qt5. |
| `TTaskDialog` | `usable_with_limits` | Uses common LCL emulation, same broad strategy as GTK2/Qt5 in reviewed factory sections. |

#### 7.3 File/Open/Save/SelectDirectory Dialogs

GTK4 uses `GtkFileChooserNative` instead of the deprecated in-process `GtkFileChooserDialog`. The reviewed source explicitly says this is a portal/out-of-process dialog and cannot host custom widgets. Therefore history combo, preview widget, and Help button are not available in the GTK4 native file dialog path, and `ofShowHelp` is ignored. Multi-select and filters are still wired through the `GtkFileChooser` interface. Save and select-folder behavior are selected in `TGtk4FileDialog.Create` based on whether the actual dialog object is `TSaveDialog`, `TSavePictureDialog`, or `TSelectDirectoryDialog`.

Result collection is handled by `Gtk4FileChooserResponseCB`, which reads selected files with GTK4 `GFile` APIs, populates `FileName`/`Files`, and sets `UserChoice`. GTK4 capabilities intentionally return only `[cdecWSPerformsDoShow]` so LCL's `TCommonDialog.DoExecute` loop continues pumping messages and checking `CanClose`.

Source references:

- GTK4 `TGtk4WSOpenDialog.CreateHandle`: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1074`
- GTK4 native-dialog limitation comment: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1091`
- GTK4 file response result collection: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:405`
- GTK4 `GtkFileChooserNative` action selection: `lcl/interfaces/gtk4/gtk4widgets.pas:13016`
- GTK4 native-dialog lifecycle notes: `lcl/interfaces/gtk4/gtk4widgets.pas:13044`, `lcl/interfaces/gtk4/gtk4widgets.pas:13071`
- GTK4 capability choice: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1348`

GTK4 file-dialog judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Open/save/select-folder basic execution | `usable_with_limits` | Native dialog path exists, sets action by LCL object type, and collects selected paths. |
| Multi-select | `usable_with_limits` | `gtk_file_chooser_set_select_multiple` and `get_files` are used; needs runtime test for file ordering and `Files`/`FileName` semantics. |
| Filter and `FilterIndex` | `usable_with_limits` | Filters are added and notify updates `FilterIndex`; needs runtime test with invalid initial filename/filter combinations. |
| Initial directory / initial filename | `usable_with_limits` | Initial directory and save current name are applied before showing the native dialog; relative path behavior needs runtime comparison. |
| Preview controls | `backend_limited` | Source says `GtkFileChooserNative` cannot host custom widgets; preview path is not available in the native dialog. |
| History combo | `backend_limited` | Same native-dialog limitation; helper exists but is not used for native path. |
| Help button / `ofShowHelp` | `partial` | Source says Help button is not available and `ofShowHelp` is ignored. |
| cancel/close response classification | `usable` (fixed 2026-07-10) | `Gtk4FileChooserResponseCB` now treats everything that is not `GTK_RESPONSE_ACCEPT`/`GTK_RESPONSE_OK` as cancel (GTK 4.6.9 emits only ACCEPT/CANCEL/DELETE_EVENT). Runtime: Escape returns `Execute=False` on all three dialog types; Save/SelectDirectory accepts still return `True`. |
| `OnCanClose` flow | `usable` (fixed 2026-07-10) | Veto previously stalled the application forever (native dialog hides itself after `response`; LCL's wait loop pumped for a response that could never arrive — runtime-proven). `ShowModal` now runs the wait loop for the native file-dialog branch and re-presents the dialog on veto. Veto probe completes: first accept refused, dialog re-shown, second accept succeeds. |

#### 7.4 Color and Font Dialogs

GTK4 color dialog uses `TGtkColorChooserDialog`, initializes the current color, manually bridges OK/Cancel button clicks to responses, and writes the chosen color back on OK. Common-dialog code also has custom palette setup helpers, but runtime validation is needed because GTK4 color dialog behavior depends on `GtkColorChooserDialog` and palette UI exposure.

GTK4 font dialog uses `TGtkFontChooserDialog`, initializes family/size/bold/italic from the LCL font, manually bridges OK/Cancel button clicks, and writes family/size/bold/italic back on OK. The code explicitly notes that GTK font chooser does not provide strikeout/underline controls and preserves the incoming state for those styles. Unlike GTK2, reviewed GTK4 source did not show handling for `fdApplyButton` or `PreviewText` in the active `TGtk4FontSelectionDialog.InitializeWidget` path.

Source references:

- GTK4 color dialog create handle: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1324`
- GTK4 color initialization and response: `lcl/interfaces/gtk4/gtk4widgets.pas:13212`
- GTK4 font dialog create handle: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1332`
- GTK4 font initialization and response: `lcl/interfaces/gtk4/gtk4widgets.pas:13096`
- GTK4 font style limitation comment: `lcl/interfaces/gtk4/gtk4widgets.pas:13183`
- GTK4 color/font capabilities: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1337`, `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1383`
- GTK2 font apply/preview handling reference: `lcl/interfaces/gtk2/gtk2wsdialogs.pp:1339`
- Qt5 font dialog maps bold/italic/strikeout/underline/fixed pitch from `QFont`: `lcl/interfaces/qt5/qtwsdialogs.pp:962`

GTK4 color/font judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Color selection | `usable_with_limits` | Current color and result color are wired through `GtkColorChooserDialog`. Custom colors/palette should be runtime-tested. |
| Color dialog options | `partial` | No reviewed handling for the full `TColorDialog.Options` set; Qt5 also has a TODO-style comment for options. |
| Font family/size/bold/italic | `usable_with_limits` | Initial and result values are mapped through Pango/GtkFontChooser. |
| Font underline/strikeout | `backend_limited` (2026-07-10) | GtkFontChooser exposes no underline/strikeout controls, and the `PangoFontDescription` it returns has no such fields — they are Pango TEXT attributes, not font-description properties, so there is nothing to read back. GTK4 preserves the incoming `TFont` state (a caller's pre-set styles survive the dialog). Qt5 can map them because `QFont` carries underline/strikeOut. Not fixable at the widgetset without a custom chooser UI. |
| Font preview text | `usable` (fixed 2026-07-10) | `TGtk4FontSelectionDialog.InitializeWidget` now applies `TFontDialog.PreviewText` via `gtk_font_chooser_set_preview_text` (GTK2 parity: set only when non-empty). Runtime-verified — native `get_preview_text` reads back the LCL value; screenshot shows it in the chooser preview entry. |
| Font apply button | `backend_limited` (2026-07-10) | GTK4 `GtkFontChooserDialog` has no apply button (GTK removed it); `fdApplyButton` has no native counterpart, documented in the source. |

Focused runtime validation:

- Document: `PLAN_GTK4_WSDIALOGS_VALIDATION.md`
- Example: `example_gtk4_wsdialogs_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsdialogs_validation/wsdialogs_validation.lpi` succeeded.
- Auto run result: `xvfb-run -a env WSDIALOGS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsdialogs_validation/wsdialogs_validation` completed without Pascal exception.
- Result summary: synthetic Escape closed all tested dialogs without hanging. `TColorDialog.Execute` and `TFontDialog.Execute` returned `False` and preserved initial values. `TOpenDialog.Execute`, `TSaveDialog.Execute`, and `TSelectDirectoryDialog.Execute` all returned `True` after synthetic Escape; OpenDialog had empty filename/files, SaveDialog kept the proposed filename, and SelectDirectoryDialog returned the initial directory.
- Source correlation: `Gtk4FileChooserResponseCB` only handles `GTK_RESPONSE_CANCEL` as cancel and sets `UserChoice := mrOK` for every other response path. The focused run proves the Escape-close path observed here is not classified as `GTK_RESPONSE_CANCEL`, so it becomes a false OK result.
- Runtime warning: GTK emitted two `GtkEventControllerScroll.flags` property warnings during `TFontDialog`; this needs separate source/runtime follow-up if it appears outside the test environment.

#### 7.5 `wsdialogs.pp` Scope Result

GTK4 dialog support is not merely stubbed; the core Open/Save/SelectDirectory/Color/Font paths are implemented and use GTK4-appropriate APIs. The important differences from GTK2/Qt5 are:

1. File dialogs use `GtkFileChooserNative`, so custom in-dialog widgets such as preview, history combo, and help button are not available in the active GTK4 path.
2. Save and select-directory dialogs are intentionally handled via `TOpenDialog` widgetset registration rather than direct class registration.
3. Color button remains unimplemented, matching GTK2/Qt5 factory status rather than being a GTK4-only regression.
4. Font dialog is usable for basic font selection; `PreviewText` is now applied (fixed 2026-07-10). `fdApplyButton` and underline/strikeout result mapping are both backend-limited: GTK4 removed the apply button, and GtkFontChooser/`PangoFontDescription` carry no underline/strikeout (Pango text attributes, not font properties). GTK4 preserves the incoming state; neither is fixable at the widgetset without custom chooser UI.
5. Common dialog lifecycle is sensitive because GTK4 `ShowModal` is non-blocking and relies on LCL's `DoExecute` loop and `UserChoice` callbacks.
6. (fixed 2026-07-10) File dialog cancel/close classification was wrong for the Escape/window-close path (`GTK_RESPONSE_DELETE_EVENT` became a false OK), and an `OnCanClose` veto stalled the application because the self-hiding native dialog could never produce another response. Both fixed in `gtk4wsdialogs.pp`: accept-only response classification + a ShowModal-side wait loop that re-presents the native dialog on veto. See `PLAN_GTK4_WSDIALOGS_VALIDATION.md`, "Implementation Fix".

Required follow-up tests:

1. OpenDialog: initial dir, initial filename, filter index, filter change, cancel, accept, single file, multi-select, and selected directory filtering.
2. SaveDialog: proposed filename, overwrite prompt semantics, filter index, existing file, non-existing file, cancel, and `OnCanClose` veto.
3. SelectDirectoryDialog: initial dir, selected dir result, cancel, and file-vs-folder filtering.
4. PreviewFileDialog/OpenPictureDialog on GTK4: confirm preview absence or degraded behavior is documented rather than silently broken.
5. `ofShowHelp` on GTK4 file dialogs: confirm ignored behavior and decide whether LCL-level fallback is required.
6. ColorDialog: initial color, chosen color, custom colors, and option flags.
7. FontDialog: initial font, family/size/bold/italic result, underline/strikeout preservation, apply button, preview text, and option flags.
8. All dialogs: transient parent, modality, focus restoration, close button, Escape/Enter, and `OnCanClose`.

### 8. `lcl/widgetset/wsextctrls.pp`

#### 8.1 Baseline Expectation

`wsextctrls.pp` mostly declares thin widgetset classes for extended controls. Most classes have no methods of their own and rely on `TWSGraphicControl`, `TWSCustomControl`, `TWSCustomGroupBox`, or `TWSCustomEdit` behavior. The explicit method surface in this baseline file is concentrated in `TWSCustomTrayIcon`; its default behavior is mostly unsupported: `Show`/`Hide` return `False`, `InternalUpdate` is empty, `ShowBalloonHint` returns `False` to request popup-notifier fallback, `GetPosition` returns `(0,0)`, and `GetCanvas` returns the icon canvas.

Source references:

- Baseline extctrls class declarations: `lcl/widgetset/wsextctrls.pp:46`
- Baseline tray icon methods: `lcl/widgetset/wsextctrls.pp:188`
- `TCustomPage` / `TCustomTabControl` registration is driven from `comctrls.pp`, not from `wsextctrls.pp`: `lcl/comctrls.pp:4289`

#### 8.2 Registration Snapshot

GTK4 registration differs from GTK2 and Qt5 in a few important places:

- `TCustomPage` and `TCustomTabControl` are registered in all three reviewed widgetsets.
- `TCustomShape`, `TPaintBox`, `TCustomImage`, and `TBevel` return `False` in GTK2, Qt5, and GTK4 factory sections. This is not by itself a GTK4-only gap; it must be reviewed against graphic-control fallback painting before judging quality.
- `TCustomSplitter` is registered in GTK4, but not in GTK2/Qt5 factory sections reviewed here.
- `TCustomRadioGroup` and `TCustomCheckGroup` are registered in GTK4 and Qt5, but GTK2 factory returns `False`.
- `TCustomLabeledEdit` returns `False` in GTK2, Qt5, and GTK4.
- `TCustomPanel` is registered in GTK2, Qt5, and GTK4.
- `TCustomTrayIcon` is registered in GTK2, Qt5, and conditionally in GTK4. GTK4 registration depends on D-Bus session bus availability.

Source references:

- GTK4 extctrls registrations: `lcl/interfaces/gtk4/gtk4wsfactory.pas:377`
- GTK4 Shape/PaintBox/Image/Bevel false registrations: `lcl/interfaces/gtk4/gtk4wsfactory.pas:389`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:400`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:405`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:410`
- GTK4 Splitter/RadioGroup/CheckGroup/Panel registrations: `lcl/interfaces/gtk4/gtk4wsfactory.pas:394`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:415`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:422`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:434`
- GTK4 TrayIcon conditional registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:440`

Initial GTK4 registration judgments:

| Class/family | GTK4 status | Reason |
| --- | --- | --- |
| `TCustomPage` / `TCustomTabControl` | `usable_with_limits` | Registered; actual behavior overlaps with `wscomctrls.pp` PageControl/TabControl review and needs tab/page tests. |
| `TCustomShape` / `TPaintBox` / `TCustomImage` / `TBevel` | `usable_with_limits` | Factory returns `False` like GTK2/Qt5, but these are non-windowed graphic controls with LCL paint implementations. GTK4 paint/DC path still needs runtime validation. |
| `TCustomSplitter` | `usable_with_limits` | GTK4 registers a `TGtk4Splitter` handle, which is a `TGtk4Panel`; resize behavior is still LCL mouse/event logic and needs drag tests. |
| `TCustomRadioGroup` / `TCustomCheckGroup` | `usable_with_limits` | GTK4 creates `TGtk4GroupBox` handles; LCL creates child `TRadioButton` / `TCheckBox` items, so behavior depends on groupbox layout plus stdctrl child controls. |
| `TCustomLabeledEdit` | `usable_with_limits` | Factory returns `False` like GTK2/Qt5. This is not a GTK4-only gap; it relies on inherited edit/label composition and should be smoke-tested. |
| `TCustomPanel` | `usable_with_limits` | GTK4 creates `TGtk4Panel`, sets caption and border style, and queues redraw on border changes. Color/border/client-area behavior needs tests. |
| `TCustomTrayIcon` | `usable_with_limits` | GTK4 now has a real SNI backend, but it is Linux/D-Bus/SNI-host dependent. Tooltip and position are backend-limited. |

#### 8.3 GTK4 Concrete Implementations Reviewed So Far

GTK4 `TGtk4WSExtCtrls` implements concrete handle creation for splitter, radio group, check group, and panel. It declares placeholder widgetset classes for shape, paintbox, image, bevel, and labeled edit, but those families are not registered by the GTK4 factory in the reviewed source. The `TGtk4WSCustomTrayIcon` class inside `gtk4wsextctrls.pp` only calls inherited baseline behavior and is not the registered GTK4 tray backend; factory registration uses `TGtk4WSTrayIcon` from `gtk4wstrayicon.pas`.

Source references:

- GTK4 extctrls class declarations: `lcl/interfaces/gtk4/gtk4wsextctrls.pp:43`
- GTK4 group/splitter/panel handle creation: `lcl/interfaces/gtk4/gtk4wsextctrls.pp:169`, `lcl/interfaces/gtk4/gtk4wsextctrls.pp:181`, `lcl/interfaces/gtk4/gtk4wsextctrls.pp:192`
- GTK4 panel border redraw: `lcl/interfaces/gtk4/gtk4wsextctrls.pp:218`
- GTK4 factory uses `Gtk4WSTrayIcon`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:125`

#### 8.4 Graphic-Control Fallback Families

For `TCustomShape`, `TPaintBox`, `TCustomImage`, and `TBevel`, GTK4 factory methods return `False`, but GTK2 and Qt5 do the same in the reviewed factory sections. These controls are `TGraphicControl` descendants and paint through LCL-owned `Paint` methods rather than through a native widget handle.

The source path is:

1. Parent `TWinControl.PaintControls` iterates non-windowed child controls, moves the DC origin to the child bounds, clips to the child rectangle, and sends `LM_PAINT`.
2. `TGraphicControl.WMPaint` assigns the incoming DC to the control canvas and calls `Paint`.
3. Each concrete control paints in LCL: shape draws geometry, paintbox runs design frame or `OnPaint`, image draws picture/imagelist content, bevel draws bevel lines.
4. GTK4 uses a GtkFixed snapshot patch so LCL custom painting is injected before child widgets, preserving GTK2/Qt5-style paint-below-child z-order.

Source references:

- Parent paints graphic controls: `lcl/include/wincontrol.inc:4948`
- `TGraphicControl.WMPaint`: `lcl/include/graphiccontrol.inc:49`
- Shape LCL paint/register: `lcl/include/shape.inc:249`, `lcl/include/shape.inc:293`
- PaintBox LCL paint/register: `lcl/include/paintbox.inc:21`, `lcl/include/paintbox.inc:27`
- Image LCL paint/register: `lcl/include/customimage.inc:125`, `lcl/include/customimage.inc:275`
- Bevel LCL paint/register: `lcl/include/bevel.inc:54`, `lcl/include/bevel.inc:67`
- GTK4 GtkFixed snapshot paint-below-children path: `lcl/interfaces/gtk4/gtk4widgets.pas:2814`

Judgment: these controls are not missing on GTK4 solely because the factory returns `False`. They are `usable_with_limits`, with the remaining risk concentrated in GTK4 canvas/DC/clipping/scrolled-parent behavior. Runtime tests must cover normal parent, panel/groupbox parent, pagecontrol tabsheet, scrollbox, resize, and design mode.

#### 8.5 Splitter, Groups, and Panel

`TCustomSplitter` is mostly LCL logic: mouse down/move/up uses absolute mouse position and calls `MoveSplitter`; painting is also in LCL. GTK4's registered splitter handle is a `TGtk4Splitter`, currently a `TGtk4Panel` subclass. This should be adequate for receiving GTK4 mouse/paint events, but it is not a GTK2/Qt5-equivalent native splitter. Drag behavior and cursor feedback need runtime tests.

`TCustomRadioGroup` and `TCustomCheckGroup` create real child controls in LCL (`TRadioButton` and `TCheckBox`) and parent them to the group. GTK4's group implementation provides a `GtkFrame` container with an overlay/fixed child area and label. Therefore group correctness depends on GTK4 groupbox client rect/layout plus the already-reviewed stdctrl button/check paths.

`TCustomPanel` paints bevel and caption in LCL. GTK4 additionally fills color and draws a simple border in `TGtk4Panel.DoBeforeLCLPaint` before LCL `Paint`. This is broadly usable, but can differ from GTK2/Qt5 for bevel depth/colors, border/client rect interaction, and caption alignment/word wrap. The dual GTK4 pre-paint border plus LCL bevel paint is a specific runtime test target.

Source references:

- Splitter mouse drag logic: `lcl/include/customsplitter.inc:609`
- Splitter LCL paint: `lcl/include/customsplitter.inc:850`
- GTK4 splitter handle creation: `lcl/interfaces/gtk4/gtk4wsextctrls.pp:181`
- RadioGroup child radio creation: `lcl/include/radiogroup.inc:162`
- CheckGroup child checkbox creation: `lcl/include/customcheckgroup.inc:213`
- GTK4 groupbox widget: `lcl/interfaces/gtk4/gtk4widgets.pas:5299`
- Panel LCL paint: `lcl/include/custompanel.inc:135`
- GTK4 panel paint/background/border path: `lcl/interfaces/gtk4/gtk4widgets.pas:5229`

#### 8.6 GTK4 TrayIcon Current Quality

GTK4 tray icon is implemented as a Linux StatusNotifierItem over D-Bus. It creates a per-instance bus/object path, exports icon properties, writes icon data to a runtime icon path, provides `IconPixmap`, builds DBusMenu menu items, maps SNI Activate/SecondaryActivate/ContextMenu into LCL mouse/click events, and sends balloon hints via `org.freedesktop.Notifications`.

Limitations are explicit:

- Registration fails if no D-Bus session bus is available.
- `GetPosition` returns `(0,0)` because SNI does not expose icon position.
- Tooltip is exported via the SNI `ToolTip` property and `NewToolTip` signal, but source comments state some SNI hosts ignore this property. This matches the earlier runtime observation that hovering the tray icon did not show a tooltip.
- Mouse move, double click, and scroll have no current LCL-equivalent SNI event path in the reviewed implementation.
- Popup menu support depends on `libdbusmenu` availability and host support.

Source references:

- SNI handle setup and icon source selection: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:247`, `lcl/interfaces/gtk4/gtk4wstrayicon.pas:291`
- SNI watcher registration: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:522`
- DBusMenu construction: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:560`
- Update emits `NewIcon` and `NewToolTip`: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:645`
- SNI activation event mapping: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:702`
- SNI tooltip property and host limitation comment: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:790`
- Hide/show/update/balloon/get-position methods: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:816`
- D-Bus availability check: `lcl/interfaces/gtk4/gtk4wstrayicon.pas:989`

TrayIcon judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Show/hide | `usable_with_limits` | Real SNI handle is created/freed when D-Bus/SNI setup succeeds. |
| Icon image | `usable_with_limits` | Icon is exported via saved PNG and `IconPixmap`; earlier runtime test showed distinct icon images. |
| Multiple tray icons | `usable_with_limits` | Object path is per-instance to avoid collision; earlier runtime test showed two visible icons as expected. |
| Popup menu | `usable_with_limits` | DBusMenu tree is built, including enabled/visible/check/radio/submenus, but depends on dbusmenu and host support. |
| Click events | `usable_with_limits` | Activate/context methods map to LCL mouse/click events; double-click/mouse-move are not supported by current SNI path. |
| Balloon hints | `usable_with_limits` | Uses freedesktop notifications and returns success only if server replies with a notification id. |
| Tooltip/hint | `backend_limited` | SNI property is exported, but source and runtime observation show host may ignore tooltips. |
| Position | `backend_limited` | SNI protocol does not expose position; GTK4 returns `(0,0)`. |

#### 8.7 `wsextctrls.pp` Scope Result

GTK4 is broadly usable for the `wsextctrls.pp` surface, but much of that usability comes from LCL-level painting and child-control composition rather than from native GTK4 widgetset classes. The high-risk areas are therefore runtime integration points: GTK4 paint/DC/clipping for graphic controls, splitter mouse capture/dragging, groupbox client layout, panel bevel/caption drawing, and host-dependent tray icon behavior.

Required follow-up tests:

1. Shape/PaintBox/Image/Bevel under form, panel, groupbox, tabsheet, and scrollbox parents.
2. PaintBox `OnPaint`, Image `Picture`, ImageList/ImageIndex, stretch/center/proportional/transparent modes.
3. Splitter drag for left/right/top/bottom alignments, anchored splitters, min size, autosnap, cursor, and design mode.
4. RadioGroup/CheckGroup item creation/removal, columns/layout, keyboard navigation, tab stop, checked state, disabled state, and design selection.
5. Panel caption, alignment, vertical alignment, word wrap, bevel inner/outer/width/color, border style, parent color/background, client rect, and child clipping.
6. LabeledEdit baseline smoke test, because GTK4 relies on the non-native composition path like GTK2/Qt5.
7. TrayIcon SNI tests for show/hide, icon update, popup menu, checked/radio submenu items, balloon hints, click events, tooltip host behavior, and D-Bus absence fallback.

Focused runtime validation:

- Document: `PLAN_GTK4_WSEXTCTRLS_VALIDATION.md`
- Example: `example_gtk4_wsextctrls_validation/`
- Build/run date: 2026-07-09
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsextctrls_validation/wsextctrls_validation.lpi` succeeded.
- Auto run result: `xvfb-run -a env WSEXTCTRLS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsextctrls_validation/wsextctrls_validation` completed without Pascal exception.
- Result summary: `TShape`, `TPaintBox`, `TImage`, and `TBevel` ran through the expected non-windowed graphic-control path; `TPaintBox.OnPaint` fired after show and again after later updates; panel caption/border/bevel changes, image mode changes, RadioGroup item-index change, CheckGroup checked-state update, LabeledEdit text update, aligned Splitter host layout change, and ScrollBox position assignment completed without exception.
- Splitter observation: inside an aligned host panel, the splitter had bounds `(1,1,9,89)`. Increasing the left panel width from `130` to `180` moved the right panel from `Left=139` to `Left=189`, confirming aligned layout reacted to the width change. Real mouse drag behavior remains untested.
- Runtime warnings: startup emitted `gtk_widget_set_direction`, `gtk_widget_get_size_request`, and `gtk_widget_set_size_request` critical warnings against non-widget pointers. The focused run did not isolate which extended control caused them; a narrower incremental test is still required.

### 9. `lcl/widgetset/wsextdlgs.pp`

#### 9.1 Baseline Expectation

`wsextdlgs.pp` declares widgetset classes for preview-file dialogs, picture dialogs, calculator dialogs/forms, and calendar dialogs/forms. The baseline classes themselves contain no behavior; their registration functions call the widgetset factory and have commented-out generic fallback registration for most classes. `RegisterCalculatorPanel` is unusual: it does not call a widgetset factory function and returns `True` after its one-time guard.

Source references:

- Baseline class declarations: `lcl/widgetset/wsextdlgs.pp:46`
- Preview/picture/calculator/calendar registration functions: `lcl/widgetset/wsextdlgs.pp:110`
- `RegisterCalculatorPanel`: `lcl/widgetset/wsextdlgs.pp:176`

Baseline implication: factory `False` does not automatically mean the dialog is unusable, because several extended dialogs are implemented by LCL-level dialog/form composition or by the base `TOpenDialog` widgetset path.

#### 9.2 Factory Registration Comparison

GTK4 registers only `TPreviewFileControl` in this file's family. Preview-file dialog, open-picture dialog, save-picture dialog, calculator dialog, calculator form, and calendar dialog factory functions all return `False`. GTK2 is similar for `TPreviewFileControl` and returns `False` for the dialogs. Qt5 returns `False` for all `wsextdlgs` factory functions.

Source references:

- GTK4 `TPreviewFileControl` registration only: `lcl/interfaces/gtk4/gtk4wsfactory.pas:451`
- GTK4 dialog registrations return `False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:457`
- GTK2 `TPreviewFileControl` registration only: `lcl/interfaces/gtk2/gtk2wsfactory.pas:481`
- GTK2 dialog registrations return `False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:487`
- Qt5 all ext dialog registrations return `False`: `lcl/interfaces/qt5/qtwsfactory.pas:427`

Registration judgments:

| Class/family | GTK4 status | Reason |
| --- | --- | --- |
| `TPreviewFileControl` | `usable_with_limits` | GTK4 registers a concrete `TGtk4CustomControl` handle. Focused validation confirmed direct handle allocation on a visible form. Its usefulness in file dialogs is limited by whether the file dialog backend can embed custom preview widgets. |
| `TPreviewFileDialog` | `partial` | LCL creates the preview control before executing the inherited open dialog, but focused validation confirmed the control stayed `parent=nil`, `handle=False` on the GTK4 native file dialog path. |
| `TOpenPictureDialog` | `partial` | LCL creates a groupbox/image preview tree, and focused validation confirmed one child existed under `PreviewFileControl`; however the preview control stayed `parent=nil`, `handle=False`, so live preview depends on file dialog selection-change and preview-widget integration that GTK4 native path does not provide. |
| `TSavePictureDialog` | `usable_with_limits` | It inherits the picture/open-dialog setup and the save action is handled by the base file dialog path; preview behavior has the same GTK4 native limitation. |
| `TCalculatorDialog` / form | `usable_with_limits` | No native widgetset dialog class is registered, but `Execute` creates an LCL calculator form and uses `ShowModal`. Focused validation confirmed the modal form opens and can be closed programmatically with `mrCancel`; synthetic Escape alone did not close it in the run. |
| `TCalendarDialog` / form | `confirmed_crash` | No native widgetset dialog class is registered, but `Execute` creates an LCL form with `TCalendar`, `TPanel`, and buttons. Focused validation reproduced the known GTK4 `TCalendar` crash path through `gtk_calendar_select_day` / `gtk4widgets.pas:6129`. |

#### 9.3 Preview and Picture Dialog Path

`TPreviewFileDialog.DoExecute` always creates `TPreviewFileControl` before calling inherited `TOpenDialog` execution. `TOpenPictureDialog` adds an LCL `TGroupBox` and `TImage` under that preview control, clears the preview on show, and loads the selected image file in `UpdatePreview`.

GTK2 embeds the preview widget with `gtk_file_chooser_set_preview_widget` and calls `CreatePreviewDialogControl` when the open dialog is a `TPreviewFileDialog`. Qt5 has a special `TQtFilePreviewDialog` path and initializes preview when non-native Qt dialogs are used. GTK4 contains a `CreatePreviewDialogControl` helper that appends the preview widget to a GTK dialog content area because GTK4 removed `gtk_file_chooser_set_preview_widget`, but the currently reviewed `TGtk4WSOpenDialog.CreateHandle` uses `GtkFileChooserNative` and explicitly documents that native/portal dialogs cannot host custom widgets; history combo, preview widget, help button, and `selection-changed` are unavailable on that path.

Source references:

- LCL preview control creation before execute: `lcl/extdlgs.pas:294`, `lcl/extdlgs.pas:320`
- LCL picture preview control tree: `lcl/extdlgs.pas:363`, `lcl/extdlgs.pas:399`
- LCL picture preview load/update: `lcl/extdlgs.pas:375`
- GTK2 preview widget embedding: `lcl/interfaces/gtk2/gtk2wsdialogs.pp:961`, `lcl/interfaces/gtk2/gtk2wsdialogs.pp:1078`
- Qt5 preview dialog path: `lcl/interfaces/qt5/qtwsdialogs.pp:662`
- GTK4 preview helper: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1024`
- GTK4 native chooser limitation: `lcl/interfaces/gtk4/gtk4wsdialogs.pp:1091`

Judgment: GTK4 preview/picture dialogs are not GTK2-equivalent. Basic open/save dialog operation should work through the already-reviewed GTK4 file dialog path, but embedded preview, preview refresh on selection change, history combo, and help button behavior are backend-limited by `GtkFileChooserNative`. This should be treated as `partial` for preview-specific behavior, not as a missing class registration problem.

#### 9.4 Calculator and Calendar Dialogs

`TCalculatorDialog.Execute` directly creates a calculator form with `CreateCalculatorForm`, wires calculator events, applies position/scale/title/value/memory settings, and calls `ShowModal`. The widgetset factory returning `False` for `TCalculatorDialog` and `TCalculatorForm` is therefore not by itself a GTK4 functional gap.

`TCalendarDialog.Execute` directly creates a `TForm`, then constructs a `TCalendar`, `TPanel`, OK button, and cancel button, applies dialog position/caption/date/display settings, and calls `ShowModal`. This means GTK4 quality follows the underlying `TForm`, `TCalendar`, `TPanel`, and `TButton` implementations. Known calendar limits from the earlier `wscalendar.pp` review still apply, especially `FirstDayOfWeek` and min/max/date-view behavior.

Source references:

- Calculator dialog LCL form execution: `lcl/extdlgs.pas:626`
- Calculator modal result and state update: `lcl/extdlgs.pas:676`
- Calendar dialog LCL form/control creation: `lcl/extdlgs.pas:831`
- Calendar modal result and size update: `lcl/extdlgs.pas:920`

Judgment: `TCalculatorDialog` is `usable_with_limits` on GTK4 through LCL form composition, although the focused run did not prove Escape-key cancellation. `TCalendarDialog` is currently a confirmed GTK4 runtime crash because it depends on the existing broken `TCalendar` path. Source review and GDB do not identify a GTK4-specific missing widgetset class that must be implemented in `gtk4wsextdlgs.pp` for either dialog.

#### 9.5 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSEXTDLGS_VALIDATION.md`
- Example: `example_gtk4_wsextdlgs_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsextdlgs_validation/wsextdlgs_validation.lpi` succeeded.
- Safe auto run result: `xvfb-run -a env WSEXTDLGS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsextdlgs_validation/wsextdlgs_validation` completed with exit code 0.
- Direct `TPreviewFileControl` allocated a handle when parented to the validation form.
- `TPreviewFileDialog` and `TOpenPictureDialog` created preview controls before execute, but the controls were not parented and did not allocate handles on the GTK4 native file-dialog path.
- `TPreviewFileDialog` and `TOpenPictureDialog` returned `Execute=True` after synthetic Escape with empty filename, matching the already documented GTK4 file-dialog cancel/close classification bug.
- `TCalculatorDialog` opened `TCalculatorForm`; Escape did not close it in the focused run, but programmatically setting the active modal form `ModalResult` to `mrCancel` closed it and `Execute` returned `False`.
- Calendar crash-case run: `xvfb-run -a env WSEXTDLGS_VALIDATION_AUTO=1 WSEXTDLGS_VALIDATION_CALENDAR=1 GDK_BACKEND=x11 example_gtk4_wsextdlgs_validation/wsextdlgs_validation` reached `calendar-before`, emitted invalid `month-changed` signal warning for `GtkCalendar`, then raised `EAccessViolation`.
- GDB stack for the calendar crash: `gtk_calendar_select_day` -> `gtk4widgets.pas:6129 SetDate` -> `gtk4wscalendar.pp:205 SetDateTime` -> `calendar.pp:425 SetProps` -> `extdlgs.pas:889 Execute`.

#### 9.6 `wsextdlgs.pp` Scope Result

GTK4 is adequate for direct `TPreviewFileControl` creation and partly adequate for non-preview extended dialog operation through LCL composition and the base common/file dialog paths. It is weaker than GTK2 and non-native Qt5 for preview-file and open-picture dialog behavior. The main GTK4 preview gap is the use of `GtkFileChooserNative`, which intentionally cannot embed LCL preview widgets or provide the same selection-change hook. This is a backend/API limitation of the chosen GTK4 dialog path, not merely an absent `WSExtDlgs` registration.

`TCalendarDialog` is not currently usable on this GTK4 stack because it crashes through the same GTK4 `TCalendar` date API path already documented in `wscalendar.pp`.

Remaining follow-up tests:

1. `TPreviewFileDialog` on GTK4: perform manual visual confirmation that no preview control is embedded in the native chooser, then verify selection change, initial file, filter, OK, and cancel behavior after the file-dialog cancel classification bug is fixed.
2. `TOpenPictureDialog` on GTK4: verify image preview visibility/refresh for PNG/JPEG/BMP, invalid files, large images, and repeated selection changes after a preview-capable GTK4 path exists.
3. `TSavePictureDialog` on GTK4: verify save filename, filter/default extension behavior, overwrite confirmation, and whether preview limitations are acceptable.
4. `TCalculatorDialog` on GTK4: verify mouse input, keyboard input other than Escape, display precision, memory state, OK/cancel buttons, scaling, and dialog position persistence.
5. `TCalendarDialog` on GTK4: re-run only after the GTK4 `TCalendar` date/signal crash is fixed, then verify date selection, double-click, OK/cancel, display settings, first-day-of-week limitation, keyboard focus, and sizing.
6. Compare GTK4 preview behavior against GTK2 and Qt5 non-native dialog mode before deciding whether to add a non-native GTK4 fallback dialog for preview-capable extended file dialogs.

### 10. `lcl/widgetset/wsfactory.pas`

#### 10.1 Baseline Expectation

`wsfactory.pas` is not a widget implementation unit. It declares the external `WSRegister...` symbols that every widgetset must provide through its interface factory unit. The file comment explicitly frames missing symbols as a linker/configuration problem, not as per-control runtime behavior. The register functions span image lists, controls, common controls, calendar, dialogs, standard controls, extended controls, extended dialogs, buttons, checklist, forms, grids, menus, pair splitter, spin edit, rubber band, shell controls, and device APIs.

Source references:

- External registration contract and linker comment: `lcl/widgetset/wsfactory.pas:25`
- Function inventory starts at image lists/controls: `lcl/widgetset/wsfactory.pas:33`
- ExtCtrls/ExtDlgs registration contracts: `lcl/widgetset/wsfactory.pas:79`, `lcl/widgetset/wsfactory.pas:92`
- Forms/menus/pairsplitter/spin/rubberband/shell/device contracts: `lcl/widgetset/wsfactory.pas:106`

Baseline implication: a factory return value only tells whether a widgetset registered a WS class at that point. It does not by itself prove that a control is unusable, because LCL may use inherited WS classes, graphic-control painting, composed child controls, or higher-level dialog fallback paths.

#### 10.2 GTK4 Factory Policy Snapshot

GTK4 factory coverage is broad for core controls, common controls, dialogs, standard controls, forms, grids, menus, pair splitter, and spin edit. It also registers `TCustomImageListResolution`, unlike the reviewed GTK2 and Qt5 factories. GTK4 registers `TWinControl`, `TCustomControl`, `TCustomListView`, progress bar, toolbar, trackbar, calendar, common/file/open/color/font/task dialogs, most standard controls, page/notebook, splitter, radio/check groups, panel, tray icon when SNI initialization succeeds, preview file control, BitBtn, checklist, scrollbox/frame/form/hint/grid/menu/popup, pair splitter, and float spin edit.

Source references:

- GTK4 factory uses list: `lcl/interfaces/gtk4/gtk4wsfactory.pas:122`
- GTK4 image list/control registration examples: `lcl/interfaces/gtk4/gtk4wsfactory.pas:129`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:152`
- GTK4 file dialog registration and intentional save/select-folder non-registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:239`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:251`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:266`
- GTK4 extended-control registrations and non-registered graphic-control families: `lcl/interfaces/gtk4/gtk4wsfactory.pas:377`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:389`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:394`
- GTK4 tray icon conditional registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:440`
- GTK4 forms/menus/pairsplitter/spin/rubberband tail: `lcl/interfaces/gtk4/gtk4wsfactory.pas:525`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:543`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:566`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:584`

Factory-level GTK4 interpretation:

| Group | GTK4 factory status | Interpretation |
| --- | --- | --- |
| Image list | `usable_with_limits` | GTK4 registers `TCustomImageListResolution`; actual image-list quality is deferred to `wsimglist.pp`. |
| Base controls | `usable_with_limits` | `TWinControl`, accessibility, and `TCustomControl` are registered; `TControl`/`TGraphicControl` remain False like peer widgetsets and require fallback interpretation. |
| Common controls | `usable_with_limits` | Core registered controls exist, but `TabSheet`, `PageControl`, `UpDown`, `ToolButton`, and `TreeView` factory False values are known to require per-control review rather than immediate missing classification. |
| Dialogs | `usable_with_limits` | `TSaveDialog` and `TSelectDirectoryDialog` intentionally remain on the `TOpenDialog` WS path; this is documented in GTK4 source to avoid VClass virtual-slot crashes and is not a simple omission. |
| Graphic controls | `usable_with_limits` | Shape/PaintBox/Image/Bevel factory False is shared with GTK2/Qt5 and maps to LCL graphic-control paint fallback. |
| Ext controls | `usable_with_limits` | GTK4 registers more than GTK2 for splitter/groups/panel/scrollbox/frame, but those still need runtime validation because some behavior is LCL composition or painting. |
| Ext dialogs | `partial` | GTK4 registers only preview control. Dialog operation mostly follows LCL/base-dialog paths; preview-specific behavior is limited by `GtkFileChooserNative`. |
| Menus | `usable_with_limits` | Menu item/menu/popup registered; main menu False is shared with GTK2/Qt5 and should be reviewed in `wsmenus.pp`. |
| RubberBand | `backend_limited` | Qt5 registers `TCustomRubberBand`; GTK2 and GTK4 do not. GTK4 has a separate design-time rubber-band path already noted under `wsdesigner.pp`. |
| ShellCtrls/LazDeviceAPIs | `stub_or_noop` | GTK2, Qt5, and GTK4 return False in the reviewed factories, so this is not a GTK4-only gap. |

#### 10.3 Notable GTK4-vs-GTK2-vs-Qt5 Differences

GTK4 has some factory registrations that are absent in one or both peer factories:

- `TCustomImageListResolution`: GTK4 registers; GTK2 and Qt5 return `False`.
- `TCustomControl`: GTK4 and Qt5 register; GTK2 returns `False`.
- `TCustomSplitter`: GTK4 registers; GTK2 and Qt5 return `False`.
- `TCustomRadioGroup` / `TCustomCheckGroup`: GTK4 and Qt5 register; GTK2 returns `False`.
- `TCustomPanel`: GTK4 and Qt5 register and return `True`; GTK2 registers `TCustomPanel` but returns `False`, so the return value alone is misleading there.
- `TScrollBox` / `TCustomFrame`: GTK4 and Qt5 register; GTK2 returns `False`.
- `TCustomPairSplitter`: GTK4 and GTK2 register; Qt5 returns `False`.

GTK4 also has factory `False` values that match peer widgetsets and should normally be treated as inherited/fallback/composition candidates before being marked missing:

- `TControl`, `TGraphicControl`, `TCustomLabel`
- `TTabSheet`, `TPageControl`, `TCustomUpDown`, `TCustomToolButton`, `TCustomTreeView`
- `TSaveDialog` on GTK2/Qt5/GTK4; `TSelectDirectoryDialog` on GTK2/GTK4
- `TColorButton`
- `TButtonControl`, `TCustomSpeedButton`
- `TCustomShape`, `TPaintBox`, `TCustomImage`, `TBevel`, `TCustomLabeledEdit`
- extended dialog classes other than `TPreviewFileControl`
- `TMainMenu`
- shell controls and device APIs

Source references:

- GTK2 control/factory examples: `lcl/interfaces/gtk2/gtk2wsfactory.pas:130`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:156`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:169`
- GTK2 common/dialog examples: `lcl/interfaces/gtk2/gtk2wsfactory.pas:194`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:259`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:265`
- GTK2 extctrl examples, including misleading panel return: `lcl/interfaces/gtk2/gtk2wsfactory.pas:390`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:411`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:459`
- GTK2 forms/menus/tail examples: `lcl/interfaces/gtk2/gtk2wsfactory.pas:550`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:600`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:612`
- Qt5 control/dialog examples: `lcl/interfaces/qt5/qtwsfactory.pas:121`, `lcl/interfaces/qt5/qtwsfactory.pas:149`, `lcl/interfaces/qt5/qtwsfactory.pas:253`
- Qt5 extctrl/tail examples: `lcl/interfaces/qt5/qtwsfactory.pas:360`, `lcl/interfaces/qt5/qtwsfactory.pas:377`, `lcl/interfaces/qt5/qtwsfactory.pas:420`, `lcl/interfaces/qt5/qtwsfactory.pas:552`, `lcl/interfaces/qt5/qtwsfactory.pas:563`

#### 10.4 `wsfactory.pas` Scope Result

For this audit, `wsfactory.pas` should be treated as a routing map, not a final quality matrix. GTK4 does not show a broad factory-level absence compared with GTK2/Qt5. The remaining work scope must continue per baseline unit and per implementation path:

1. If GTK4 returns `True`, still inspect the registered class for method completeness and runtime integration.
2. If GTK4 returns `False` and GTK2/Qt5 also return `False`, first check for LCL fallback, inherited WS class behavior, graphic-control painting, or dialog composition.
3. If GTK4 returns `False` where Qt5/GTK2 register a real class, inspect whether GTK4 has an alternate path or a GTK4/backend limitation.
4. Treat conditional factories, especially tray icon, as runtime-environment dependent.
5. Do not count factory registration as quality parity; it is only the entry point for the detailed class/method review.

#### 10.5 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSFACTORY_VALIDATION.md`
- Example: `example_gtk4_wsfactory_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsfactory_validation/wsfactory_validation.lpi` succeeded.
- Run result: `xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wsfactory_validation/wsfactory_validation` completed with exit code 0.
- The validation called every non-commented external `WSRegister...` declaration in `wsfactory.pas`; all linked and executed.
- Runtime count: `True=49`, `False=30`.
- `WSRegisterCustomTrayIcon=True` in this run, meaning the GTK4 SNI tray factory initialized successfully in this runtime environment. This remains environment-dependent by source review.
- False-return groups matched the source-review routing model: fallback base controls, unregistered common-control families, inherited file-dialog paths, graphic-control fallbacks, extended dialogs except direct preview control, main menu, rubber band, shell controls, and device APIs.

Runtime interpretation: this confirms GTK4 provides the full active factory symbol set. It does not upgrade any component quality classification by itself.

### 11. `lcl/widgetset/wsforms.pp`

#### 11.1 Baseline Expectation

`wsforms.pp` defines the widgetset surface for scrolling window controls, scroll boxes, frames, custom forms, normal forms, hint windows, screen, and application-properties placeholders. The baseline form methods are mostly no-ops or fixed fallback values. In particular, modal close/show, file drop, alpha blend, border icons, form style, icon, show-in-taskbar, z-position, popup parent, and MDI operations require backend support for useful behavior.

Source references:

- Baseline classes and form method surface: `lcl/widgetset/wsforms.pp:47`, `lcl/widgetset/wsforms.pp:74`
- Baseline no-op form methods: `lcl/widgetset/wsforms.pp:159`
- Baseline MDI fallback methods: `lcl/widgetset/wsforms.pp:233`
- Registration functions: `lcl/widgetset/wsforms.pp:283`

#### 11.2 GTK4 Registration and Core Classes

GTK4 registers all five baseline families from this unit: `TScrollingWinControl`, `TScrollBox`, `TCustomFrame`, `TCustomForm`, and `THintWindow`. This is stronger than GTK2 for `TScrollBox` and `TCustomFrame`, where the reviewed factory returns `False`, and matches Qt5 for these registrations.

GTK4 `TGtk4WSScrollingWinControl` creates `TGtk4ScrollingWinControl` and delegates `ScrollBy` to `TGtk4WSWinControl.ScrollBy`. The underlying `TGtk4ScrollingWinControl` uses a `GtkScrolledWindow` with a `GtkOverlay`, `GtkFixed` child area, and drawing area, with scrollbars initially using `GTK_POLICY_NEVER` to match GTK2 policy. `ScrollBy` adjusts the GTK horizontal and vertical adjustments and invalidates the LCL control.

Source references:

- GTK4 forms class declarations: `lcl/interfaces/gtk4/gtk4wsforms.pp:53`, `lcl/interfaces/gtk4/gtk4wsforms.pp:82`, `lcl/interfaces/gtk4/gtk4wsforms.pp:133`
- GTK4 forms factory registrations: `lcl/interfaces/gtk4/gtk4wsfactory.pas:507`
- GTK2 forms factory comparison: `lcl/interfaces/gtk2/gtk2wsfactory.pas:550`
- Qt5 forms factory comparison: `lcl/interfaces/qt5/qtwsfactory.pas:487`
- GTK4 scrolling handle and `ScrollBy`: `lcl/interfaces/gtk4/gtk4wsforms.pp:157`, `lcl/interfaces/gtk4/gtk4wscontrols.pp:742`
- GTK4 scrolling widget structure: `lcl/interfaces/gtk4/gtk4widgets.pas:11246`

Judgment: scrolling win control, scrollbox, and frame are `usable_with_limits` on source review. The implementation is real, but layout, painting, focus, scrollbar policy changes, and child clipping need runtime coverage because GTK4 uses a different widget hierarchy than GTK2's `GtkLayout` and Qt5's main-window/scroll-area model.

#### 11.3 Custom Form Behavior

GTK4 `TGtk4WSCustomForm` implements core form behavior rather than inheriting baseline no-ops:

- `CreateHandle` creates `TGtk4Window`, applies caption/resizable defaults, records size request, and deliberately does not call `AddWindow` until `ShowHide`.
- `ShowHide` sets modal state when required, prepares undecorated popup forms before mapping, adds the GTK window to the application only when visible, uses `present` for decorated windows and `show` for undecorated windows, applies minimize/maximize/fullscreen state, reconnects constraint handling, and clears modal/transient state when hidden.
- `CloseModal` clears GTK modal state.
- `SetAllowDropFiles` installs/removes a GTK4 `GtkDropTarget` accepting `GdkFileList` and forwards paths to LCL/application drop handlers.
- `SetBorderIcons` can control only deletability/close behavior; minimize/maximize buttons are window-manager controlled.
- `SetFormBorderStyle` maps decoration and resizability.
- `SetFormStyle` explicitly does not implement stay-on-top for GTK4 4.6 because `gtk_window_set_keep_above` is not available there and `present` would steal focus.
- `SetIcon`, `SetShowInTaskbar`, `SetRealPopupParent`, `SetAlphaBlend`, and front z-position have concrete GTK4 implementations.

Source references:

- GTK4 create handle and delayed application-window registration rationale: `lcl/interfaces/gtk4/gtk4wsforms.pp:191`, `lcl/interfaces/gtk4/gtk4wsforms.pp:225`
- GTK4 show/hide modal/popup/application-window flow: `lcl/interfaces/gtk4/gtk4wsforms.pp:313`
- GTK4 close modal and file drop: `lcl/interfaces/gtk4/gtk4wsforms.pp:441`, `lcl/interfaces/gtk4/gtk4wsforms.pp:457`, `lcl/interfaces/gtk4/gtk4wsforms.pp:499`
- GTK4 border/style/icon/taskbar handling: `lcl/interfaces/gtk4/gtk4wsforms.pp:532`, `lcl/interfaces/gtk4/gtk4wsforms.pp:551`, `lcl/interfaces/gtk4/gtk4wsforms.pp:578`, `lcl/interfaces/gtk4/gtk4wsforms.pp:587`, `lcl/interfaces/gtk4/gtk4wsforms.pp:597`
- GTK4 z-position/modal/popup-parent/alpha handling: `lcl/interfaces/gtk4/gtk4wsforms.pp:621`, `lcl/interfaces/gtk4/gtk4wsforms.pp:655`, `lcl/interfaces/gtk4/gtk4wsforms.pp:663`, `lcl/interfaces/gtk4/gtk4wsforms.pp:687`
- GTK4 window size/position constraints and compositor limitation: `lcl/interfaces/gtk4/gtk4widgets.pas:12121`
- GTK4 size-constraint snap-back support: `lcl/interfaces/gtk4/gtk4widgets.pas:12463`

Form-method judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Basic form create/show/hide | `usable_with_limits` | Real implementation exists and includes startup-hide protection by deferring `AddWindow` to visible show. Needs runtime regression tests around hidden startup forms/dialogs. |
| Modal forms | `usable_with_limits` | Modal state is set in `ShowHide` like GTK2/Qt5, and `CloseModal` clears it. Nested-modal/transient ordering needs tests. |
| Border style and border icons | `usable_with_limits` | Decoration/resizability and close deletability are handled; minimize/maximize button control is WM-limited on GTK4. |
| Form style / stay-on-top | `backend_limited` | GTK4 4.6 path explicitly cannot implement keep-above without focus side effects. |
| Icon | `usable_with_limits` | Big icon or app icon is assigned to `TGtk4Window.Icon`, which copies the pixbuf and calls GTK window icon setter. Needs icon-size/multi-resolution tests. |
| ShowInTaskbar | `usable_with_limits` | Uses GTK skip-taskbar hint. Behavior remains WM/compositor dependent. |
| Z position | `backend_limited` | Front is approximated; sending to back is unsupported by GTK4/Wayland compositor-managed stacking. |
| Alpha blend | `usable_with_limits` | Uses GTK widget opacity because GTK4 removed window opacity. Needs decorated/undecorated tests. |
| Drop files | `usable_with_limits` | Uses `GtkDropTarget` and `GdkFileList`; needs real drag/drop tests from file managers. |

#### 11.4 Hint Windows and Popup Placement

GTK4 has a dedicated `TGtk4WSHintWindow` that creates `TGtk4HintWindow` and overrides `ShowHide`. The implementation distinguishes completion/system popup forms from normal hint windows. Popup forms can use X11 override-redirect before map and explicit raise; normal hint windows remain WM-managed but are prepared as tooltip windows and positioned through X11 where available. On Wayland, the code comments indicate only realization/transient placement remains because absolute window positioning is not available.

Source references:

- GTK4 hint window handle/showhide: `lcl/interfaces/gtk4/gtk4wsforms.pp:746`
- GTK4 popup preparation and X11 positioning: `lcl/interfaces/gtk4/gtk4widgets.pas:12535`
- GTK4 tooltip preparation and X11 positioning: `lcl/interfaces/gtk4/gtk4widgets.pas:12591`
- GTK4 popup raise path: `lcl/interfaces/gtk4/gtk4widgets.pas:12651`

Judgment: hint windows are `usable_with_limits` on X11 and `backend_limited` for absolute placement on Wayland. The implementation is careful and specific, but it must be tested against component hints, completion popups, long-line hints, modal dialogs, focus retention, and Wayland/X11 behavior.

#### 11.5 MDI Support

GTK4 overrides the MDI methods, but every reviewed implementation returns the baseline result: `nil`, `False`, or `0`. GTK2 also does not expose a comparable MDI implementation through its reviewed class declaration, while Qt5 implements MDI through `QMdiArea` paths for active child lookup, child enumeration, next/previous, tile, cascade, and count.

Source references:

- GTK4 MDI methods returning baseline values: `lcl/interfaces/gtk4/gtk4wsforms.pp:702`
- Qt5 MDI active child / enumeration / navigation: `lcl/interfaces/qt5/qtwsforms.pp:726`, `lcl/interfaces/qt5/qtwsforms.pp:800`, `lcl/interfaces/qt5/qtwsforms.pp:844`

Judgment: GTK4 MDI is `stub_or_noop`. This is not a GTK4 regression against GTK2, but it is below Qt5 and should be listed as unsupported unless a GTK4-specific MDI strategy is designed.

#### 11.6 `wsforms.pp` Scope Result

GTK4 has a substantial implementation for normal forms, scroll containers, frames, modal handling, file drop, alpha blend, hint windows, and popup handling. The major gaps are not broad class absence but platform/API limits and unimplemented MDI:

1. Form position and send-to-back z-order are compositor/Wayland limited.
2. Stay-on-top is not available in the reviewed GTK4 4.6 implementation.
3. Border icon control is limited mostly to close/deletable behavior.
4. MDI methods are stubs compared with Qt5.
5. ScrollBox/frame/form layout paths need runtime validation because GTK4 uses a custom `GtkScrolledWindow` + overlay + fixed + drawing-area structure.

#### 11.7 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSFORMS_VALIDATION.md`
- Example: `example_gtk4_wsforms_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsforms_validation/wsforms_validation.lpi` succeeded.
- Safe auto run result: `xvfb-run -a env WSFORMS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsforms_validation/wsforms_validation` completed with exit code 0.
- Hide-on-show auto run result: `xvfb-run -a env WSFORMS_VALIDATION_AUTO=1 WSFORMS_VALIDATION_HIDE_ON_SHOW=1 GDK_BACKEND=x11 example_gtk4_wsforms_validation/wsforms_validation` completed with exit code 0.
- Basic main form show allocated a handle, reported `Visible=True`, and had `ClientRect=(0,0,760,520)`.
- `TScrollBox` and `TFrame` handles allocated.
- Secondary form `Show`/`Hide` updated public visible state and did not raise exceptions.
- Timer-driven modal form returned `mrOK` from `ShowModal` and was not visible after close.
- Runtime border style/icons, alpha, taskbar, form style, `BringToFront`, and `SendToBack` calls completed without Pascal exception.
- `THintWindow.ActivateHint` allocated a handle, became visible, and hid cleanly.
- Hide-on-show run logged `Visible=True` before `Hide` and `Visible=False` after `Hide`; external X window absence remains covered by the earlier startup-hide document, not this example.
- MDI smoke confirmed current unsupported behavior at runtime: parent and child handles were created, but `MDIChildCount=0` and `ActiveMDIChild=nil`; `Cascade`, `Tile`, `Next`, and `Previous` calls completed without meaningful effect.
- Both runs emitted the recurring startup warning `g_regex_match_full: assertion 'string != NULL' failed`.

Remaining follow-up tests:

1. External-window verification for startup hidden forms, delayed show, nested modal, non-modal owner/transient ordering, and hidden modal cleanup edge cases.
2. Border styles, border icons, resizable/fixed forms, constraints, maximize/minimize/fullscreen, and client rect with menu bar overhead.
3. ShowInTaskbar, popup parent, z-position front/back expectations, stay-on-top behavior, and compositor-specific behavior under X11 and Wayland.
4. AlphaBlend/Alpha on decorated and undecorated forms.
5. AllowDropFiles with multiple files, non-ASCII paths, directories, and file-manager drag/drop.
6. ScrollBox and frame children under resizing, scrolling, focus traversal, wheel scroll, paint clipping, and design mode.
7. Hint windows and popup forms: normal component hints, completion windows, long-line hints, modal-parent hints, focus retention, and X11/Wayland placement.
8. Explicit MDI smoke test confirming current unsupported behavior so users see a documented limitation rather than a silent failure.

### 12. `lcl/widgetset/wsgrids.pp`

#### 12.1 Baseline Expectation

`wsgrids.pp` defines a small widgetset surface for `TCustomGrid`. It does not implement the grid's main painting, selection, sizing, or scrolling logic; those are mostly in `grids.pas`. The baseline widgetset methods cover:

- sending the first typed character into an active grid editor,
- calculating editor bounds inside a cell,
- selecting an invalidation start Y value,
- and an optional widgetset-level grid invalidation hook.

Source references:

- Baseline method declarations: `lcl/widgetset/wsgrids.pp:49`
- Baseline `SendCharToEditor`: `lcl/widgetset/wsgrids.pp:73`
- Baseline editor bounds / invalidation defaults: `lcl/widgetset/wsgrids.pp:112`, `lcl/widgetset/wsgrids.pp:120`, `lcl/widgetset/wsgrids.pp:126`
- Registration fallback to `TWSCustomGrid`: `lcl/widgetset/wsgrids.pp:133`

#### 12.2 GTK4 / GTK2 / Qt5 Comparison

GTK4, GTK2, and Qt5 all register `TCustomGrid` with a widgetset-specific class. GTK4 and GTK2 implement the same two overrides: `GetEditorBoundsFromCellRect` and `Invalidate`. Their editor bounds calculation increments the left edge, subtracts two pixels from the right edge, subtracts one pixel from the bottom, uses `constCellPadding`, and vertically aligns the editor according to the column text layout. Their `Invalidate` hook calls `Sender.Invalidate`.

Qt5 overrides only `GetEditorBoundsFromCellRect`. It does not add the left-edge increment used by GTK2/GTK4, subtracts one pixel from the right edge, and uses `varCellPadding`.

Source references:

- GTK4 grid registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:537`
- GTK2 grid registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:582`
- Qt5 grid registration: `lcl/interfaces/qt5/qtwsfactory.pas:517`
- GTK4 grid implementation: `lcl/interfaces/gtk4/gtk4wsgrids.pp:29`, `lcl/interfaces/gtk4/gtk4wsgrids.pp:40`, `lcl/interfaces/gtk4/gtk4wsgrids.pp:60`
- GTK2 grid implementation: `lcl/interfaces/gtk2/gtk2wsgrids.pp:38`, `lcl/interfaces/gtk2/gtk2wsgrids.pp:49`, `lcl/interfaces/gtk2/gtk2wsgrids.pp:69`
- Qt5 grid implementation: `lcl/interfaces/qt5/qtwsgrids.pp:33`, `lcl/interfaces/qt5/qtwsgrids.pp:44`

#### 12.3 LCL Call Sites and Actual Scope

`TCustomGrid.EditorPos` calls `GetEditorBoundsFromCellRect` only for the string editor when `EditorBorderStyle = bsNone`; otherwise it uses the grid's normal inner-cell adjustment. `TCustomGrid.EditorShowChar` and `TCompositeCellEditor.SendChar` call `SendCharToEditor` through the grid widgetset class.

Source references:

- Editor bounds call site: `lcl/grids.pas:8750`
- Single-character editor input call site: `lcl/grids.pas:9138`
- Composite editor input call site: `lcl/grids.pas:13901`

Judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Grid registration | `usable` | GTK4 registers `TCustomGrid` like GTK2/Qt5. |
| Editor bounds | `usable_with_limits` | GTK4 matches GTK2 exactly in reviewed code; runtime tests still need to check font metrics, DPI, borderless editor alignment, and top/center/bottom text layout. |
| SendCharToEditor | `usable_with_limits` | GTK4 inherits the baseline LCL implementation, which dispatches grid-editor messages or falls back to `TCustomEdit`/`TCustomComboBox`. This is not GTK4-specific but depends on GTK4 edit/combobox text update behavior. |
| Invalidate hook | `usable_with_limits` | GTK4 matches GTK2 and calls `Sender.Invalidate`; repaint correctness depends on the GTK4 custom-control paint path already tracked under `wscontrols.pp`. |
| Main grid paint/selection/sizing | `needs_runtime_test` | Mostly LCL-owned, outside `wsgrids.pp`; GTK4 risks are canvas, clipping, scroll, focus, and input integration rather than missing WS grid methods. |

#### 12.4 `wsgrids.pp` Scope Result

No GTK4-specific source-level gap was found in the `wsgrids.pp` surface. GTK4 is at least GTK2-equivalent for the widgetset-specific grid helpers reviewed here. The remaining risk is runtime integration with GTK4 custom painting, text metrics, editor controls, and event delivery.

#### 12.5 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSGRIDS_VALIDATION.md`
- Example: `example_gtk4_wsgrids_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsgrids_validation/wsgrids_validation.lpi` succeeded.
- Auto run result: `xvfb-run -a env WSGRIDS_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_wsgrids_validation/wsgrids_validation` completed with exit code 0.
- `TStringGrid` and `TDrawGrid` handles allocated.
- `TStringGrid.CellRect(1,1)` returned `(64,24,128,48)`, and `MouseToCell` inside that rect returned `1,1`.
- Programmatic selection to `Col=2`, `Row=3` worked, and cell text `edited-가` survived.
- `EditorMode := True` reported `True` with `goEditing` enabled and `EditorBorderStyle=bsNone`.
- Programmatic scroll state changed to `TopRow=10`, `LeftCol=3`.
- `TDrawGrid.OnDrawCell` fired during initial paint with `drawcount=50`.
- Explicit `Invalidate`, `ProcessMessages`, `Repaint`, and `ProcessMessages` did not increase `drawcount` in the short auto run; this is a focused repaint follow-up item.
- The recurring startup warning `g_regex_match_full: assertion 'string != NULL' failed` was emitted.

Remaining follow-up tests:

1. StringGrid/DrawGrid paint, fixed rows/cols, grid lines, selection, hot tracking, focus rectangle, and custom `OnDrawCell`.
2. Borderless string editor alignment for top/center/bottom layout, varied fonts, DPI scaling, and row heights.
3. Editor first-character handling for `TEdit`, `TComboBox`, pick lists, composite editors, backspace, and Unicode input.
4. Invalidate/repaint after scrolling, resizing, editing, column/row size changes, and fixed-cell changes.
5. Mouse selection, keyboard navigation, wheel scroll, drag sizing, and design-mode behavior under GTK4.

### 13. `lcl/widgetset/wsimglist.pp`

#### 13.1 Baseline Expectation

`wsimglist.pp` defines the widgetset backing store for `TCustomImageListResolution`. The baseline class supports clear, create/destroy reference, delete, draw, insert, move, and replace. Its default implementor stores `TBitmap` objects in a `TList`, converts incoming RGBA data to bitmap/mask handles with `CreateCompatibleBitmaps`, and draws the stored bitmap to the target canvas. For non-normal draw effects, it fetches a raw image, applies the effect, creates a temporary bitmap, and draws that.

Source references:

- Baseline method surface: `lcl/widgetset/wsimglist.pp:42`
- Default bitmap-list implementor: `lcl/widgetset/wsimglist.pp:72`
- Baseline draw and effect path: `lcl/widgetset/wsimglist.pp:98`
- Baseline RGBA-to-bitmap creation: `lcl/widgetset/wsimglist.pp:137`
- Baseline clear/create/delete/destroy/draw/insert/move/replace: `lcl/widgetset/wsimglist.pp:156`, `lcl/widgetset/wsimglist.pp:163`, `lcl/widgetset/wsimglist.pp:186`, `lcl/widgetset/wsimglist.pp:194`, `lcl/widgetset/wsimglist.pp:201`, `lcl/widgetset/wsimglist.pp:212`, `lcl/widgetset/wsimglist.pp:234`, `lcl/widgetset/wsimglist.pp:246`
- Registration fallback: `lcl/widgetset/wsimglist.pp:260`

Baseline limitation: the default `Draw` path passes through `ABkColor`, `ABlendColor`, `AStyle`, and `AImageType`, but the reviewed baseline implementation only uses `ADrawEffect` and bitmap drawing. That means drawing-style/image-type/blend behavior depends on higher-level image-list logic or other widgetset-specific implementations, not on this default backend.

#### 13.2 GTK4 / GTK2 / Qt5 Comparison

GTK4 registers `TCustomImageListResolution` with `TGtk4WSCustomImageListResolution`. GTK2 and Qt5 factories return `False`, causing `wsimglist.pp` to register the baseline `TWSCustomImageListResolution` fallback. The GTK4 class overrides every baseline method, but every method delegates directly to `inherited`, so GTK4 behavior is effectively the same baseline bitmap-list implementation with a GTK4 class name.

Source references:

- GTK4 image-list factory registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:129`
- GTK2 image-list factory returns `False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:130`
- Qt5 image-list factory returns `False`: `lcl/interfaces/qt5/qtwsfactory.pas:122`
- GTK4 class and inherited overrides: `lcl/interfaces/gtk4/gtk4wsimglist.pp:42`, `lcl/interfaces/gtk4/gtk4wsimglist.pp:66`
- GTK2 placeholder class only: `lcl/interfaces/gtk2/gtk2wsimglist.pp:34`
- Qt5 placeholder class only: `lcl/interfaces/qt5/qtwsimglist.pp:31`

Judgment: GTK4 image-list storage is `usable_with_limits`. It is not missing, but it is also not a GTK4-native optimized image-list implementation. It relies on baseline `TBitmap` storage, `TCanvas.Draw`, and GTK4 bitmap/mask conversion.

#### 13.3 GTK4 Bitmap Conversion Dependency

The GTK4 image-list fallback depends heavily on `TGtk4WidgetSet.RawImage_CreateBitmaps`. The reviewed GTK4 implementation is substantial: it handles 1-bit data, 8-bit palette or grayscale data, 16-bit conversion to 32-bit, 24-bit conversion to Cairo ARGB32, component reordering for 32-bit data, all-zero-alpha correction, and 1-bit/8-bit mask conversion to an A8 mask. It creates `TGtk4Image` bitmap handles with Cairo image formats.

Source references:

- GTK4 `RawImage_CreateBitmaps` entry: `lcl/interfaces/gtk4/gtk4lclintf.inc:202`
- GTK4 1/8/16/24/32-bit conversion branches: `lcl/interfaces/gtk4/gtk4lclintf.inc:238`, `lcl/interfaces/gtk4/gtk4lclintf.inc:251`, `lcl/interfaces/gtk4/gtk4lclintf.inc:298`, `lcl/interfaces/gtk4/gtk4lclintf.inc:323`, `lcl/interfaces/gtk4/gtk4lclintf.inc:353`
- GTK4 all-zero-alpha correction: `lcl/interfaces/gtk4/gtk4lclintf.inc:384`
- GTK4 bitmap handle creation: `lcl/interfaces/gtk4/gtk4lclintf.inc:435`, `lcl/interfaces/gtk4/gtk4lclintf.inc:450`
- GTK4 mask conversion: `lcl/interfaces/gtk4/gtk4lclintf.inc:456`
- LCL image-list draw entry and overlay use of WS draw: `lcl/include/imglist.inc:394`, `lcl/include/imglist.inc:417`
- LCL reference creation through widgetset class: `lcl/include/imglist.inc:1067`

Judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| Add/insert/replace/move/delete/clear | `usable_with_limits` | GTK4 inherits the baseline bitmap-list implementation. Functional, but not optimized and depends on correct handle ownership. |
| Normal draw | `usable_with_limits` | Stored `TBitmap` is drawn through GTK4 canvas. Needs alpha/mask/runtime tests. |
| Disabled/effect draw | `usable_with_limits` | Baseline applies `TRawImage.PerformEffect` and recreates a temporary bitmap. Needs effect visual tests. |
| DrawingStyle/ImageType/BlendColor | `partial` | Baseline WS draw receives these arguments but reviewed implementation does not use them directly. |
| Mask/alpha conversion | `usable_with_limits` | GTK4 conversion code is real and covers common formats, but icon transparency is historically fragile and must be tested across bit depths. |
| Native/host image-list integration | `missing` | No GTK4-native image-list cache beyond baseline `TBitmap` storage. This is not necessarily a functional blocker but may affect performance. |

#### 13.4 `wsimglist.pp` Scope Result

GTK4 does not have a source-level absence for `TCustomImageListResolution`; it registers a class and uses the baseline implementation. Compared with GTK2 and Qt5, GTK4 is not worse in the WS image-list class itself because GTK2/Qt5 also fall back to baseline. The main GTK4-specific risk is the lower-level Cairo/GTK4 bitmap conversion and canvas drawing path.

#### 13.5 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSIMGLIST_VALIDATION.md`
- Example: `example_gtk4_wsimglist_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsimglist_validation/wsimglist_validation.lpi` succeeded.
- Run result: `xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wsimglist_validation/wsimglist_validation` completed with exit code 0.
- A 16x16 `TImageList` started with `Count=0`.
- Three `Add` calls returned indices `0`, `1`, and `2`.
- `AddMasked` returned index `3` and count became `4`.
- `Insert`, `Move`, `Replace`, and `Delete` completed; count moved through `5`, `5`, `5`, and `4`.
- `GetBitmap(0, ...)` returned a non-empty `16x16` bitmap.
- Normal, disabled, selected-style, and disabled-effect draw calls completed on an offscreen `TBitmap`.
- Offscreen bitmap non-white pixel count after drawing was `1024`.
- `Clear` completed and final count became `0`.

Runtime interpretation: GTK4's baseline-backed image-list storage operations and simple offscreen drawing are usable for basic 16x16 bitmap inputs. This does not prove exact visual parity for masks, alpha, disabled effects, selected drawing style, blend color, overlays, DPI-scaled resolutions, or host-control integration.

Remaining follow-up tests:

1. ImageList add/insert/replace/delete/move/clear with 16x16, 24x24, 32x32, and scaled resolutions.
2. Draw normal/disabled/highlighted effects on form canvas, toolbar, buttons, listview, treeview, tabs, and menus.
3. Transparent icons with alpha-only, mask-only, alpha+mask, all-zero-alpha-with-mask, and palette images.
4. 1-bit, 8-bit palette, 8-bit grayscale, 16-bit, 24-bit, and 32-bit image sources.
5. Overlay drawing and multiple image-list resolutions under DPI scaling.
6. Memory/handle lifetime during repeated insert/delete/replace and form destruction.

### 14. `lcl/widgetset/wslazdeviceapis.pas`

#### 14.1 Baseline Expectation

`wslazdeviceapis.pas` defines the widgetset class behind `LazDeviceAPIs`: position requests, device messages, accelerometer start/stop, device manufacturer/model, screen rotation, and vibration. The baseline class is a fallback implementation with no real device integration: methods are empty, manufacturer/model return an empty string, screen rotation returns `srRotation_0`, and vibration is a no-op.

Source references:

- Baseline method surface: `lcl/widgetset/wslazdeviceapis.pas:49`
- Baseline registration fallback: `lcl/widgetset/wslazdeviceapis.pas:71`
- Baseline no-op/default implementations: `lcl/widgetset/wslazdeviceapis.pas:83`

#### 14.2 GTK4 / GTK2 / Qt5 Comparison

GTK4, GTK2, and Qt5 all return `False` from `WSRegisterLazDeviceAPIs`, so all three use the baseline fallback class. GTK2 and Qt5 contain commented references to a custom-drawn device API class, but do not register it in the reviewed factories. GTK4 has no separate `Gtk4WSLazDeviceAPIs` unit in the reviewed source.

Source references:

- GTK4 factory returns `False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:600`
- GTK2 factory returns `False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:647`
- Qt5 factory returns `False`: `lcl/interfaces/qt5/qtwsfactory.pas:580`
- LCL API calls dispatch through `GetWSLazDeviceAPIs`: `lcl/lazdeviceapis.pas:156`, `lcl/lazdeviceapis.pas:190`, `lcl/lazdeviceapis.pas:210`, `lcl/lazdeviceapis.pas:256`

Judgment: `wslazdeviceapis.pas` is `stub_or_noop` for GTK4, but this is not a GTK4-only gap relative to GTK2/Qt5 desktop widgetsets. Applications using `TLazDevice`, `TLazAccelerometer`, `TLazPositionInfo`, or `TLazMessaging` should not expect device functionality under the reviewed GTK4 implementation.

#### 14.3 `wslazdeviceapis.pas` Scope Result

No GTK4 implementation work should be inferred from this file unless a project explicitly targets device APIs on GTK4. For normal desktop LCL-gtk4 compatibility, this is a documented unsupported/fallback area shared with GTK2/Qt5.

#### 14.4 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSLAZDEVICEAPIS_VALIDATION.md`
- Example: `example_gtk4_wslazdeviceapis_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wslazdeviceapis_validation/wslazdeviceapis_validation.lpi` succeeded.
- Run result: `xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wslazdeviceapis_validation/wslazdeviceapis_validation` completed with exit code 0.
- `Device.Manufacturer` and `Device.Model` returned empty strings.
- `Device.GetScreenRotation(0)` returned ordinal `0`, matching `srRotation_0`.
- `Device.Vibrate(10)` completed without exception.
- `Accelerometer.StartReadingAccelerometerData` and `StopReadingAccelerometerData` completed without exception.
- `PositionInfo.RequestPositionInfo(pmGPS)` completed; `IsPositionDataAvailable=False`, latitude `0`, longitude `0`.
- `Messaging.CreateMessage`, `SendMessage`, and `FreeMessage` completed without exception.

Runtime interpretation: GTK4 is confirmed to use the documented desktop fallback behavior: quiet no-op/default results, not real device integration.

Remaining follow-up:

1. If a GTK4 device API implementation is ever planned, design it separately from the current widget/control parity work because it needs OS service integration rather than normal GTK widget implementation.

### 15. `lcl/widgetset/wslclclasses.pp`

#### 15.1 Baseline Expectation

`wslclclasses.pp` is not a visual widget implementation file. It is the shared LCL widgetset registration and dispatch infrastructure used by GTK2, Qt5, GTK4, and other widgetsets. It maps an LCL component class to a widgetset class, creates the runtime-adjusted virtual class used as `WidgetSetClass`, tracks registered class nodes, and stores optional widgetset-private classes.

Source references:

- Public registration and lookup API: `lcl/widgetset/wslclclasses.pp:77`
- `TClassNode` fields for LCL class, WS class, VClass, parent/child/sibling tree: `lcl/widgetset/wslclclasses.pp:113`
- `FindWSComponentClass` / `IsWSComponentInheritsFrom`: `lcl/widgetset/wslclclasses.pp:183`
- Runtime VClass creation and VMT adjustment: `lcl/widgetset/wslclclasses.pp:264`
- Unregistered intermediate-node handling: `lcl/widgetset/wslclclasses.pp:413`
- `RegisterWSComponent`: `lcl/widgetset/wslclclasses.pp:480`
- `RegisterNewWSComp`: `lcl/widgetset/wslclclasses.pp:534`
- Accessible/device API object registration: `lcl/widgetset/wslclclasses.pp:549`
- `FindWSRegistered`: `lcl/widgetset/wslclclasses.pp:569`
- `TWSLCLComponent.WSPrivate`: `lcl/widgetset/wslclclasses.pp:731`
- final VClass cleanup: `lcl/widgetset/wslclclasses.pp:749`

#### 15.2 LCL Call Path

`TLCLComponent.NewInstance` allocates the component, asks `FindWSRegistered(Self)` for an already-registered widgetset class, and only falls back to `GetWSComponentClass` / `WSRegisterClass` / `RegisterNewWSComp` when no direct registration exists. `TLCLReferenceComponent.WSDestroyReference` then dispatches destruction through the resolved `WidgetSetClass`.

Source references:

- Base registration of `TLCLComponent`: `lcl/lclclasses.pp:101`
- `TLCLComponent.GetWSComponentClass`: `lcl/lclclasses.pp:120`
- `TLCLComponent.NewInstance` lookup path: `lcl/lclclasses.pp:160`
- Reference destruction through widgetset class: `lcl/lclclasses.pp:273`

Judgment: this file explains why factory registrations, inherited widgetset classes, and fallback classes cannot be interpreted mechanically. If a GTK4 factory returns `False`, the LCL may still inherit a parent widgetset class or use a baseline fallback. If GTK4 registers a class, the actual runtime class may still be a synthesized VClass that merges the registered class with parent widgetset virtual methods.

#### 15.3 GTK4 / GTK2 / Qt5 Comparison

There is no GTK4-specific counterpart for this file in the reviewed `lcl/interfaces/gtk4` tree. GTK4, GTK2, and Qt5 all use this same registration infrastructure through their `*wsfactory.pas` units and component `WSRegisterClass` calls.

Important source facts:

- `CreateVClass` first copies the current widgetset class VMT, then finds the common ancestor between the current WS class and the parent WS class, and copies parent-overridden virtual methods into slots that the current class left at the common ancestor implementation: `lcl/widgetset/wslclclasses.pp:306`, `lcl/widgetset/wslclclasses.pp:336`, `lcl/widgetset/wslclclasses.pp:360`
- `CreateVClass` changes the generated class name, class parent, and clears the method table after VMT synthesis: `lcl/widgetset/wslclclasses.pp:404`
- Unregistered intermediate LCL classes can inherit the parent `WSClass` and `VClass`, marked with `(L)` or `(I)` VClass names: `lcl/widgetset/wslclclasses.pp:443`
- Registering or changing a parent node recreates affected child VClasses: `lcl/widgetset/wslclclasses.pp:484`
- `RegisterNewWSComp` intentionally avoids creating a new WS class and instead uses the normal Object Pascal class path after a failed registered lookup: `lcl/widgetset/wslclclasses.pp:534`

Manual judgment: `wslclclasses.pp` itself is `usable` as shared infrastructure. No GTK4-only missing implementation was found here. The implementation is high impact and fragile by design because it relies on runtime VMT synthesis, so it imposes constraints on future GTK4 work:

1. Factory registrations must preserve the expected LCL/WS inheritance relationship.
2. Adding a GTK4 class for a descendant may change inherited virtual methods through VClass synthesis, not only the methods explicitly overridden in the new class.
3. A `False` factory result can be correct when baseline or parent-class behavior is the intended implementation.
4. A registered GTK4 class is not proof of full feature parity; the actual methods must still be compared against GTK2/Qt5 and LCL call sites.

#### 15.4 `wslclclasses.pp` Scope Result

No direct GTK4 implementation work is identified from this file. Its main audit value is methodological: every future GTK4 widgetset change must be checked against the shared registration/VClass behavior before concluding that a class is missing, inherited, or safely replaceable.

#### 15.5 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSLCLCLASSES_VALIDATION.md`
- Example: `example_gtk4_wslclclasses_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wslclclasses_validation/wslclclasses_validation.lpi` succeeded.
- Run result: `xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wslclclasses_validation/wslclclasses_validation` completed with exit code 0.
- `TButton` received `WidgetSetClass=(V)TGtk4WSButton`; `FindWSComponentClass` and `FindWSRegistered` matched.
- Custom `TValidationButton` inherited `(V)TGtk4WSButton`.
- `TPanel` received `(V)TGtk4WSCustomPanel`; custom `TValidationPanel` inherited the same class.
- `TScrollBox` received `(V)TGtk4WSScrollBox`.
- `TStringGrid` received `(V)TGtk4WSCustomGrid`.
- `TImageList` itself received `TWSLCLComponent`; image-list backing storage is the separate `TCustomImageListResolution` path covered under `wsimglist.pp`.

Runtime interpretation: representative GTK4 controls receive widgetset classes through the shared lookup path, unregistered custom descendants inherit parent widgetset classes as expected, and `(V)` runtime VClass synthesis is active.

Required follow-up checks:

1. When adding or changing any GTK4 factory registration, verify the LCL ancestor chain and the parent widgetset class used by `CreateVClass`.
2. For dialogs and components with unusual inheritance, verify that registered GTK4 classes do not break parent virtual method inheritance. This is especially relevant to the already-reviewed `wsdialogs.pp` save/select-directory registration caution.
3. After any broad factory change, run a clean LCL build and a component smoke test that creates parent and descendant controls before and after handle allocation.

### 16. `lcl/widgetset/wsmenus.pp`

#### 16.1 Baseline Expectation

`wsmenus.pp` defines the widgetset surface for `TMenuItem`, `TMenu`, `TMainMenu`, and `TPopupMenu`. The baseline methods are mostly no-op/default methods: menu item creation returns `0`, property setters do nothing or return `False`, popup display does nothing, and icon updates fall back to `TMenuItem.RecreateHandle`.

Source references:

- Baseline method declarations: `lcl/widgetset/wsmenus.pp:51`, `lcl/widgetset/wsmenus.pp:72`, `lcl/widgetset/wsmenus.pp:87`
- Baseline command pool: `lcl/widgetset/wsmenus.pp:107`
- Baseline menu item no-op/default methods: `lcl/widgetset/wsmenus.pp:120`
- Baseline menu/popup defaults: `lcl/widgetset/wsmenus.pp:185`, `lcl/widgetset/wsmenus.pp:198`
- Registration helpers: `lcl/widgetset/wsmenus.pp:217`

LCL call-site facts:

- `TMenu.CreateHandle` calls `TWSMenuClass(WidgetSetClass).CreateHandle` and then creates/checks child item handles: `lcl/include/menu.inc:164`
- menu shortcuts are handled in LCL through `TMenu.IsShortcut`, which finds `ShortCut` and calls `Item.Click`: `lcl/include/menu.inc:259`
- menu image-list changes call `FItems.UpdateImages`: `lcl/include/menu.inc:41`, `lcl/include/menu.inc:92`
- `TMenuItem.CreateHandle` calls `TWSMenuItemClass.CreateHandle`, then `AttachMenu`, then shortcut setup: `lcl/include/menuitem.inc:132`
- caption/check/enabled/radio/right-justify/visible/icon/shortcut property changes dispatch to the widgetset methods: `lcl/include/menuitem.inc:1268`, `lcl/include/menuitem.inc:1284`, `lcl/include/menuitem.inc:1325`, `lcl/include/menuitem.inc:1408`, `lcl/include/menuitem.inc:1437`, `lcl/include/menuitem.inc:1599`, `lcl/include/menuitem.inc:1667`, `lcl/include/menuitem.inc:1689`
- `TMenuItem.IntfDoSelect` sets `Application.Hint` from the menu item hint: `lcl/include/menuitem.inc:468`

#### 16.2 Registration Comparison

GTK4, GTK2, and Qt5 all register `TMenuItem`, `TMenu`, and `TPopupMenu`. All three return `False` for direct `TMainMenu` registration. This is not a GTK4-only gap: `TMainMenu` uses the `TMenu` registration path and form/window-owned menu bar handling.

Source references:

- GTK4 registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:543`
- GTK2 registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:588`
- Qt5 registration: `lcl/interfaces/qt5/qtwsfactory.pas:523`
- GTK4 form creates a `GMenu` model and `GtkPopoverMenuBar` when a form has a menu: `lcl/interfaces/gtk4/gtk4widgets.pas:11824`
- GTK4 can create a menu bar on demand after form creation: `lcl/interfaces/gtk4/gtk4widgets.pas:12387`

Judgment: registration coverage is broadly present. The important differences are not factory-level absence, but the GTK4 backend model: GTK4 uses `GMenu` plus `GSimpleActionGroup` plus `GtkPopoverMenuBar`/`GtkPopoverMenu`, while GTK2 uses `GtkMenuBar`/`GtkMenuItem` widgets and Qt5 uses `QMenuBar`/`QMenu`/`QAction`.

#### 16.3 GTK2 and Qt5 Reference Behavior

GTK2 creates real GTK menu item widgets, connects `activate`, `select`, `deselect`, toggle, size-request, and button-press callbacks, attaches items into menu bars/submenus by widget insertion, and handles popup alignment/monitor clamping in the popup positioning callback.

Source references:

- GTK2 callbacks: `lcl/interfaces/gtk2/gtk2wsmenus.pp:242`
- GTK2 attach into menu bar/menu/submenu: `lcl/interfaces/gtk2/gtk2wsmenus.pp:262`
- GTK2 menu item creation and check/radio setup: `lcl/interfaces/gtk2/gtk2wsmenus.pp:313`
- GTK2 caption/shortcut/visible/check/enable/radio/right-justify/icon setters: `lcl/interfaces/gtk2/gtk2wsmenus.pp:372`
- GTK2 main menu creation: `lcl/interfaces/gtk2/gtk2wsmenus.pp:504`
- GTK2 popup alignment and monitor clamp: `lcl/interfaces/gtk2/gtk2wsmenus.pp:575`
- GTK2 popup nested loop: `lcl/interfaces/gtk2/gtk2wsmenus.pp:662`
- GTK2 radio regrouping: `lcl/interfaces/gtk2/gtk2winapi.inc:7357`

Qt5 creates `TQtMenu` wrappers over Qt menu/action objects, sets text/enabled/checkable/checked/shortcut/icon properties, inserts menus into `QMenuBar`/`QMenu`, hooks `triggered`, `hovered`, `aboutToShow`, and `aboutToHide`, and performs popup alignment before blocking `Exec`.

Source references:

- Qt5 menu item creation: `lcl/interfaces/qt5/qtwsmenus.pp:102`
- Qt5 attach into menu bar/menu: `lcl/interfaces/qt5/qtwsmenus.pp:86`
- Qt5 property setters: `lcl/interfaces/qt5/qtwsmenus.pp:265`, `lcl/interfaces/qt5/qtwsmenus.pp:292`, `lcl/interfaces/qt5/qtwsmenus.pp:314`, `lcl/interfaces/qt5/qtwsmenus.pp:330`, `lcl/interfaces/qt5/qtwsmenus.pp:349`, `lcl/interfaces/qt5/qtwsmenus.pp:366`, `lcl/interfaces/qt5/qtwsmenus.pp:392`, `lcl/interfaces/qt5/qtwsmenus.pp:402`
- Qt5 menu/main-menu handle creation: `lcl/interfaces/qt5/qtwsmenus.pp:424`
- Qt5 popup alignment and blocking exec: `lcl/interfaces/qt5/qtwsmenus.pp:483`
- Qt5 event hooks including hover/about-to-show/about-to-hide: `lcl/interfaces/qt5/qtwidgets.pas:16625`
- Qt5 hover dispatches `IntfDoSelect`: `lcl/interfaces/qt5/qtwidgets.pas:16683`
- Qt5 triggered path: `lcl/interfaces/qt5/qtwidgets.pas:16966`

Manual judgment: GTK2 and Qt5 both have mature direct menu-item/widget/action implementations. GTK2 is the stronger reference for GTK menu behavior and popup positioning. Qt5 is the stronger reference for action-driven menu behavior with hover/select callbacks.

#### 16.4 GTK4 Review

GTK4 implementation shape:

- `TGtk4MenuShell` owns or wraps a `GMenu` model and `GSimpleActionGroup`: `lcl/interfaces/gtk4/gtk4widgets.pas:7067`
- `TGtk4MenuBar` creates `GtkPopoverMenuBar` from a model: `lcl/interfaces/gtk4/gtk4widgets.pas:7127`
- `TGtk4Menu` creates `GtkPopoverMenu` from a model: `lcl/interfaces/gtk4/gtk4widgets.pas:7137`
- `TGtk4MenuItem` is not a GTK widget; it wraps a `GMenuItem` plus optional `GSimpleAction`: `lcl/interfaces/gtk4/gtk4widgets.pas:7147`
- GTK4 action activation dispatches `LM_ACTIVATE`: `lcl/interfaces/gtk4/gtk4widgets.pas:7269`
- GTK4 stateful check/radio actions use `change-state`: `lcl/interfaces/gtk4/gtk4widgets.pas:7288`
- GTK4 menu item `SetCheck` updates the action state: `lcl/interfaces/gtk4/gtk4widgets.pas:7314`
- GTK4 menu item `SetEnabled` updates the action enabled state: `lcl/interfaces/gtk4/gtk4widgets.pas:7327`

GTK4 model rebuild behavior:

- `BuildMenuItems` skips invisible or handle-less items and appends visible items/submenus to the `GMenu` model: `lcl/interfaces/gtk4/gtk4wsmenus.pp:273`
- menu icons are created from image list or bitmap and attached as `GIcon`: `lcl/interfaces/gtk4/gtk4wsmenus.pp:131`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:198`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:340`
- GTK4 forces hidden `GtkImage` children visible after model rebuild because `GtkModelButton` otherwise hides images with text: `lcl/interfaces/gtk4/gtk4wsmenus.pp:365`
- model rebuilds are deferred/coalesced and protected against rebuilding while a popover is mapped: `lcl/interfaces/gtk4/gtk4wsmenus.pp:389`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:451`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:478`, `lcl/interfaces/gtk4/gtk4wsmenus.pp:508`

GTK4 usable behavior found by source review:

- Basic main-menu and popup-menu creation exist through GTK4 menu models.
- Basic menu item activation exists through `GSimpleAction` and `LM_ACTIVATE`.
- Caption, shortcut display attribute, visibility, icon changes, and attach operations trigger a model rebuild.
- Checked and enabled state update the `GSimpleAction` state/enabled flag without needing a full rebuild.
- Popup menus are shown with a fresh `GtkPopoverMenu` and a nested loop, then call `APopupMenu.Close`.
- Popup focus is explicitly saved and restored around the nested loop.
- Menu icon support is implemented, including image-list and bitmap paths.

GTK4 limitations and gaps found by source review:

- `SetRightJustify` is explicitly unsupported for `GtkPopoverMenuBar`; GTK2 implements it and Qt5 approximates it with a right-to-left attribute.
- GTK4 popup positioning does not apply `TPopupMenu.Alignment` or RTL alignment flipping. GTK2 and Qt5 both adjust `X` for `paCenter` and `paRight`; GTK2 also clamps vertically to the monitor.
- GTK4 hover/select hint behavior — **implemented 2026-07-12 (`798f660`).** GTK4's model-based menu has no per-item select signal or queryable identity (GtkModelButton exposes no action name — confirmed vs `gtkmenusectionbox.c`/`gtkmodelbutton.c` + codex cross-review), unlike GTK2 (`GtkMenuItem::select`) and Qt5 (`QAction::hovered`). Worked around by attaching motion (mouse) + focus (keyboard) controllers to each rendered button and matching the hovered button's caption label back to a `TMenuItem` -> `IntfDoSelect` (leave clears, like gtk2 deselect); lazy GtkPopoverMenuBar dropdowns are covered via a popover `map` hook. Limitation: duplicate captions resolve to the first match.
- GTK4 radio-group handling is questionable. `RegroupMenuItem` claims grouping is handled by stateful GActions with string state and shared target semantics, but the reviewed `TGtk4MenuItem` code creates a separate boolean stateful action for each check/radio item and `BuildMenuItems` does not set radio target attributes or shared action state. Runtime verification is required; source review does not show GTK2/Qt5-equivalent radio grouping.
- `SetShortCut` sets the `accel` attribute on the `GMenuItem`, which should affect displayed accelerator text, but the reviewed code does not install a separate GTK accelerator controller. Actual shortcut activation still appears to rely on LCL `TMenu.IsShortcut`, so menu-label display and keyboard activation must both be tested.
- Popup display requires a form/content-box parent. Programmatic popups without a suitable active/main form exit; this may affect tray-icon or non-form-owned popup scenarios.
- `GMenu` model rebuild is necessarily asynchronous/deferred in several setters. This is justified by source comments and popup performance, but it creates timing-sensitive behavior for code that changes menu state immediately before showing or while a menu is open.

GTK4 method judgments:

| Method / area | GTK4 status | Reason |
| --- | --- | --- |
| `TWSMenuItem.CreateHandle` | `usable` | Creates `TGtk4MenuItem` wrapper with action/menu-item objects. |
| `AttachMenu` | `usable_with_limits` | Defers model rebuild to idle; efficient for bulk creation but timing-sensitive. |
| `DestroyHandle` | `usable_with_limits` | Removes action from action group and frees wrapper; rebuild timing must be tested when destroying visible/open menu items. |
| `SetCaption` | `usable_with_limits` | Updates `GMenuItem` label and defers rebuild. |
| `SetShortCut` | `usable_with_limits` | Updates `accel` attribute for display; actual shortcut activation relies on LCL path and needs runtime verification. |
| `SetVisible` | `usable_with_limits` | Rebuild omits invisible items; LCL then destroys hidden item handles. Needs tests around hide/show while menu is open. |
| `SetCheck` | `usable` (fixed 2026-07-10) | Radio sibling action states now synced (LCL TurnSiblingsOff never reaches WS SetCheck; gtk2/qt5 rely on native grouping we lack). See `PLAN_GTK4_MENU_VALIDATION.md` → Implementation Fix. |
| `SetEnable` | `usable` | Updates GAction enabled state. |
| `SetRadioItem` | `usable_with_limits` (state fixed 2026-07-10) | Native action states stay consistent now (sibling sync + LCL-owned change-state). Residual cosmetic gap: boolean actions render a check mark, not a radio dot (string-state+target redesign would be needed). |
| `SetRightJustify` | `backend_limited` | Explicitly unsupported by GtkPopoverMenuBar. |
| `UpdateMenuIcon` | `usable_with_limits` | GIcon conversion and forced visibility exist; image sizing/theme behavior needs visual tests. |
| `TWSMenu.CreateHandle` | `usable_with_limits` | Wraps form-owned menu bar or creates a menu bar wrapper; main-menu lifetime is tied to `TGtk4Window`. |
| `SetBiDiMode` | `usable_with_limits` | Sets widget text direction only; does not cover popup alignment behavior. |
| `TPopupMenu.CreateHandle` | `usable` | Creates `TGtk4Menu` model/action wrapper. |
| `TPopupMenu.Popup` | `usable_with_limits` (alignment fixed 2026-07-10) | Alignment implemented via contents measure + gtk_popover_set_offset with gtk2 RTL swap (GtkPopover centers on the pointing rect by default — screenshot-proven). Monitor clamp is covered by GDK popup slide/flip hints. Parent-form requirement remains. |
| menu item hover/select hints | `usable_with_limits` (fixed 2026-07-12, `798f660`) | GtkPopoverMenu has no per-item select signal or queryable identity, so motion+focus controllers on each rendered button match the hovered caption label back to a TMenuItem -> IntfDoSelect (lazy dropdowns covered via popover `map` hook). Verified: keyboard nav under Xvfb + mouse hover on real hardware. Limitation: duplicate captions resolve to the first match. |
| radio groups | `usable_with_limits` (fixed 2026-07-10) | Native action states now match the LCL after switching (runtime re-verified: radio1=false/radio2=true). Cosmetic: check-mark indicator instead of a radio dot. |

#### 16.5 `wsmenus.pp` Scope Result

GTK4 menu support is substantial and not a stub. Basic menu display, submenu construction, activation, checked/enabled state, icons, popup display, and focus restore all have real implementation. However, GTK4 is not GTK2/Qt5-equivalent in several concrete areas:

1. Popup alignment and monitor-bound positioning are below GTK2/Qt5.
2. Right-justified menu items are unsupported.
3. Menu item hover/select hint behavior — implemented 2026-07-12 (`798f660`) via caption-label matching (no per-item identity in GTK4's model menu).
4. Radio group native state is not GTK2/Qt5-equivalent; runtime validation confirmed stale native action state even though LCL sibling `Checked` state is corrected.
5. Deferred model rebuilds require focused runtime tests around menu mutation during popup/open menu interactions.

#### 16.6 Focused Runtime Validation

- Plan: `PLAN_GTK4_MENU_VALIDATION.md`
- Example: `example_gtk4_menu_validation/`
- Current build result: `./lazbuild --ws=gtk4 example_gtk4_menu_validation/menu_validation.lpi` succeeded.
- Current auto run result: `xvfb-run -a env MENU_VALIDATION_AUTO=1 GDK_BACKEND=x11 example_gtk4_menu_validation/menu_validation` completed with exit code 0.
- Normal menu item had a GTK4 wrapper/action and `g_action_activate` dispatched LCL `OnClick`.
- Check item state change through `g_action_change_state(True)` updated native state to `true`, LCL `Checked=True`, and dispatched LCL `OnClick`.
- Shortcut item exposed a nonempty GTK4 `accel` attribute: `'<Control>n'`.
- Disabled item exposed `action_enabled=False`, matching LCL `Enabled=False`.
- Hidden item had no allocated handle in the safe validation path.
- Radio validation confirmed the source-level concern: after activating radio2, LCL state was corrected (`radio1.Checked=False`, `radio2.Checked=True`), but native GTK4 action states were stale/inconsistent (`radio1 action_state=true`, `radio2 action_state=true`).
- Click log contained three entries: normal, check, and radio2.
- The recurring startup warning `g_regex_match_full: assertion 'string != NULL' failed` was emitted.

Runtime interpretation: basic GTK4 menu action wiring, check state, disabled state, hidden-item no-handle behavior, and shortcut display attribute are usable. Native radio action grouping is not GTK2/Qt5-equivalent. Popup alignment, hover hints, visual icon/mark correctness, and real keyboard shortcut delivery remain unproven by this action-level auto test.

Remaining follow-up tests:

1. Main menu creation before and after form handle creation; dynamic menu assignment to a form.
2. Top-level menu, submenu, separator, check item, radio group, disabled item, hidden item, and icon item display.
3. Menu item activation by mouse, keyboard, accelerator/shortcut, and mnemonic.
4. `Checked`, `RadioItem`, `GroupIndex`, and sibling radio state after user click and programmatic changes.
5. Runtime caption, shortcut, enabled, visible, icon, image-list, and menu-index changes before opening, while open, and after closing.
6. `TPopupMenu.Alignment` values `paLeft`, `paCenter`, `paRight`, RTL alignment, multi-monitor edge positions, and monitor-bound clamping.
7. `OnPopup` handlers that change many item states immediately before display.
8. Menu item `Hint` / `Application.Hint` behavior while hovering items.
9. Popup menus opened from controls, from form owner only, and from non-form contexts such as tray icons.

### 17. `lcl/widgetset/wspairsplitter.pp`

#### 17.1 Baseline Expectation

`wspairsplitter.pp` defines widgetset hooks for `TPairSplitterSide` and `TCustomPairSplitter`. The baseline/common implementation is already functional: it creates and positions an internal `TSplitter`, aligns side 0 left/top, aligns side 1 client, reads/writes position through side 0 width/height, and redirects splitter cursor handling to the internal `TSplitter`.

Source references:

- Baseline method declarations: `lcl/widgetset/wspairsplitter.pp:46`, `lcl/widgetset/wspairsplitter.pp:52`
- common internal splitter lookup: `lcl/widgetset/wspairsplitter.pp:74`
- common `AddSide`: `lcl/widgetset/wspairsplitter.pp:89`
- common `RemoveSide` default returns `False`: `lcl/widgetset/wspairsplitter.pp:131`
- common `GetPosition` / `SetPosition`: `lcl/widgetset/wspairsplitter.pp:137`, `lcl/widgetset/wspairsplitter.pp:149`
- common splitter cursor handling: `lcl/widgetset/wspairsplitter.pp:181`
- fallback registration for custom pair splitter when a widgetset does not register one: `lcl/widgetset/wspairsplitter.pp:220`

LCL call-site facts:

- `TPairSplitterSide.SetParent` removes/adds the side from/to its `TCustomPairSplitter`: `lcl/pairsplitter.pas:186`
- side design-time painting draws a dashed frame: `lcl/pairsplitter.pas:212`, `lcl/pairsplitter.pas:222`
- `Position` is synchronized through widgetset `GetPosition`/`SetPosition`: `lcl/pairsplitter.pas:262`, `lcl/pairsplitter.pas:269`
- side add/remove dispatches to widgetset methods: `lcl/pairsplitter.pas:304`, `lcl/pairsplitter.pas:327`
- splitter type changes recreate the window: `lcl/pairsplitter.pas:283`
- `CreateWnd` creates sides, adds them through the widgetset, sets position, and applies the stored cursor: `lcl/pairsplitter.pas:400`
- `UpdatePosition` calls `SetPosition` with `-1` and expects the widgetset to return the current position through the var parameter: `lcl/pairsplitter.pas:417`

#### 17.2 GTK2 / Qt5 Reference

GTK2 registers `TPairSplitterSide` and `TCustomPairSplitter`, but its `TGtk2WSPairSplitterSide` and `TGtk2WSCustomPairSplitter` classes do not override the baseline/common methods in the reviewed file. Therefore GTK2 effectively uses the common `TSplitter`-based implementation.

Source references:

- GTK2 registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:612`
- GTK2 pair splitter classes without overrides: `lcl/interfaces/gtk2/gtk2wspairsplitter.pp:36`

Qt5 registers `TPairSplitterSide` and returns `False` for `TCustomPairSplitter`. Because `wspairsplitter.pp` registers the common fallback for `TCustomPairSplitter` when `WSRegisterCustomPairSplitter` returns `False`, Qt5 uses a custom side handle plus the common `TSplitter`-based custom splitter logic.

Source references:

- Qt5 side registration and custom splitter fallback: `lcl/interfaces/qt5/qtwsfactory.pas:546`
- Qt5 side handle creation: `lcl/interfaces/qt5/qtwspairsplitter.pp:55`
- Qt5 custom pair splitter class has no overrides: `lcl/interfaces/qt5/qtwspairsplitter.pp:45`

Manual judgment: GTK2 and Qt5 are mostly baseline/common implementations. Qt5 only adds a side handle specialization. This means the common `wspairsplitter.pp` fallback is a legitimate reference behavior, not merely an unimplemented stub.

#### 17.3 GTK4 Review

GTK4 implements PairSplitter in `lcl/interfaces/gtk4/gtk4wssplitter.pas` rather than a file named `gtk4wspairsplitter.pp`. GTK4 registers both side and custom splitter, creates the custom splitter as `TGtk4Paned`, and backs it with `GtkPaned`.

Source references:

- GTK4 factory registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:566`
- GTK4 uses `gtk4wssplitter` in the factory unit: `lcl/interfaces/gtk4/gtk4wsfactory.pas:125`
- GTK4 pair splitter classes: `lcl/interfaces/gtk4/gtk4wssplitter.pas:25`, `lcl/interfaces/gtk4/gtk4wssplitter.pas:32`
- GTK4 side handle creation: `lcl/interfaces/gtk4/gtk4wssplitter.pas:52`
- GTK4 custom pair splitter `CreateHandle`: `lcl/interfaces/gtk4/gtk4wssplitter.pas:63`
- GTK4 `AddSide`: `lcl/interfaces/gtk4/gtk4wssplitter.pas:69`
- GTK4 `RemoveSide`: `lcl/interfaces/gtk4/gtk4wssplitter.pas:98`
- GTK4 `GetPosition` / `SetPosition`: `lcl/interfaces/gtk4/gtk4wssplitter.pas:104`, `lcl/interfaces/gtk4/gtk4wssplitter.pas:113`
- GTK4 splitter cursor methods: `lcl/interfaces/gtk4/gtk4wssplitter.pas:127`
- `TGtk4Paned.CreateWidget` orientation mapping: `lcl/interfaces/gtk4/gtk4widgets.pas:3076`

GTK4 usable behavior:

- `TCustomPairSplitter` has a real native GTK4 implementation using `GtkPaned`, not only the common fallback.
- Horizontal/vertical splitter type is mapped to GTK orientation during widget creation.
- `AddSide` attaches side widgets to pane 1 or pane 2 through `GtkPaned.add1/add2`.
- `GetPosition` reads the native `GtkPaned` position.
- `SetPosition` writes the native `GtkPaned` position.
- `GetSplitterCursor` returns default horizontal/vertical splitter cursors based on `SplitterType`.

GTK4 limitations found by source review:

- `RemoveSide` is unimplemented and returns `False`. This matters because `TPairSplitterSide.SetParent` and side deletion call the widgetset `RemoveSide` before clearing `FSides`.
- ~~`SetSplitterCursor` returns `False` ... Runtime verification is required.~~ **Fixed 2026-07-12 (`186a2fc`).** `GetSplitterCursor` also now returns False (it previously forced crVsplit/crHsplit and returning True masked the stored custom cursor); both defer to the inherited TControl cursor so a custom `Cursor` round-trips (Xvfb-verified), and the native GtkPaned handle keeps its own resize cursor.
- `SetPosition` does not read back the actual clamped native position into `NewPosition`. In contrast, LCL `CreateWnd` and `UpdatePosition` rely on the var parameter being updated to the current position in some paths. When `UpdatePosition` passes `-1`, GTK4 currently calls `GtkPaned.set_position(-1)` and leaves `NewPosition` as `-1` in source, so `FPosition` may become stale/invalid unless GTK/LCL call ordering masks it.
- `TPairSplitterSide` is created as `TGtk4Window`, while `TGtk4SplitterSide` also exists in `gtk4widgets.pas` but is not used by the reviewed registration path. This is not automatically wrong because `TGtk4Window.CreateWidget` creates a scrolled child widget when the LCL object has a parent, but the unused helper indicates the side implementation needs runtime validation.
- GTK4 uses native `GtkPaned`, while GTK2/Qt5 mostly use common `TSplitter` fallback. This may improve normal dragging, but it also means GTK4 behavior can diverge from the LCL common side-alignment/internal-splitter behavior.

GTK4 method judgments:

| Method / area | GTK4 status | Reason |
| --- | --- | --- |
| `TPairSplitterSide.CreateHandle` | `usable` (fixed 2026-07-10) | Was TGtk4Window (TCustomForm hard-cast + window-API misuse → 1x1 sides). Now TGtk4SplitterSide (overlay+fixed+paint); sides size correctly and children lay out. See `PLAN_GTK4_PAIRSPLITTER_VALIDATION.md` → Implementation Fix. |
| `TCustomPairSplitter.CreateHandle` | `usable_with_limits` | Real `GtkPaned` backend exists with orientation mapping. |
| `AddSide` | `usable` (fixed 2026-07-10) | set_parent(nil) misuse replaced with ref+unparent+set_*_child; recreate/detach/reattach runtime-tested clean. |
| `RemoveSide` | `usable` (implemented 2026-07-10) | gtk4-specific need: GtkPaned keeps a dangling slot pointer on external unparent (gdb-confirmed criticals at RecreateWnd). Slot now cleared through the paned API with survival-ref lifecycle; destroy paths that bypass RemoveSide self-detach. |
| `GetPosition` | `usable` | Reads native GtkPaned position when handle is allocated. |
| `SetPosition` | `usable` (fixed 2026-07-10) | Honors the base contract: negative = query-only (no longer unsets GtkPaned), actual native position always written back; Position round-trips runtime-verified. |
| `GetSplitterCursor` | `usable` (fixed 2026-07-12, `186a2fc`) | Was forcing crVsplit/crHsplit and returning True, which masked a custom `Cursor`. Now returns False (the "no internal splitter" contract, like gtk2/qt5), so `TCustomPairSplitter.GetCursor` falls back to the inherited TControl cursor. |
| `SetSplitterCursor` | `usable` (fixed 2026-07-12, `186a2fc`) | Returns False so `SetCursor` stores on the control; a custom `Cursor` now round-trips (crSizeAll/crSizeWE read back — Xvfb-verified), while the native GtkPaned handle keeps its own resize cursor. |

Focused runtime validation:

- Document: `PLAN_GTK4_PAIRSPLITTER_VALIDATION.md`
- Example: `example_gtk4_pairsplitter_validation/`
- Build/run date: 2026-07-09
- Result summary: build succeeded; auto run exited normally; native `GtkPaned` position accepted programmatic `Position` writes; LCL `Position` getter returned `-1`; vertical handle recreation produced `GTK_ORIENTATION_VERTICAL`; side detach/re-attach emitted GTK critical warnings.

#### 17.4 `wspairsplitter.pp` Scope Result

GTK4 PairSplitter is not missing. It has a native `GtkPaned` implementation and is more specialized than GTK2/Qt5 for the custom splitter itself. The concrete GTK4 work candidates are narrower:

1. ~~Implement or document `RemoveSide`.~~ Done 2026-07-10 (slot clearing with survival-ref lifecycle).
2. ~~Fix `SetPosition` var-parameter semantics...~~ Done 2026-07-10 (query-only for negative + write-back).
3. Verify and improve custom cursor behavior on the actual native divider.
4. ~~Decide whether `TPairSplitterSide` should continue using `TGtk4Window`...~~ Done 2026-07-10: switched to a completed `TGtk4SplitterSide` + new TGtk4Paned LM_MOVE/LM_SIZE feedback (drag runtime-verified). Custom divider cursor stays backend-limited (GtkPaned private handle provides the native resize cursor).

Required follow-up tests:

1. Manual visual validation of horizontal and vertical PairSplitter creation with both auto-created and streamed sides.
2. Programmatic `Position` set before handle creation, after handle creation, after resize, and after user drag.
3. Reading `Position` after user drag, after `UpdatePosition`, and after setting out-of-range values.
4. Deleting/removing a side at runtime and design time, then adding/recreating sides.
5. Runtime `SplitterType` changes that recreate the window.
6. Custom cursor assignment and hover over the native divider.
7. Child controls inside both sides, focus traversal, resizing, and paint/design-time dashed side frame.
8. Compare against the existing `test/bugs/8437` PairSplitter scenario under GTK2, Qt5, and GTK4.

### 18. `lcl/widgetset/wsproc.pp`

#### 18.1 Baseline Expectation

`wsproc.pp` is a small shared helper unit, not a widget implementation unit. It exposes three guard functions:

- `WSCheckReferenceAllocated`
- `WSCheckHandleAllocated(TWinControl, ...)`
- `WSCheckHandleAllocated(TMenu, ...)`

Each function returns whether the reference/handle is allocated and logs a warning through `LazLoggerBase.DebugLn` when called too early.

Source references:

- Public helper declarations: `lcl/widgetset/wsproc.pp:29`
- reference guard implementation: `lcl/widgetset/wsproc.pp:40`
- wincontrol handle guard implementation: `lcl/widgetset/wsproc.pp:53`
- menu handle guard implementation: `lcl/widgetset/wsproc.pp:66`

#### 18.2 GTK4 / GTK2 / Qt5 Comparison

There is no GTK4/GTK2/Qt5-specific implementation of `wsproc.pp`. The files named `gtk4procs.pas`, `gtk2proc.pp`, and `qtproc.pp` are backend-specific utility units with different scopes; they are not overrides or alternate implementations of `WSProc`.

All three reviewed widgetsets call `WSCheckHandleAllocated` throughout their widgetset methods to guard native handle access. Examples include GTK4 form/control/menu-adjacent code, GTK2 and Qt5 standard controls, and the common PairSplitter fallback.

Source references:

- common PairSplitter use: `lcl/widgetset/wspairsplitter.pp:98`, `lcl/widgetset/wspairsplitter.pp:139`, `lcl/widgetset/wspairsplitter.pp:155`
- GTK4 examples: `lcl/interfaces/gtk4/gtk4wsforms.pp:241`, `lcl/interfaces/gtk4/gtk4wsforms.pp:325`, `lcl/interfaces/gtk4/gtk4wsforms.pp:446`
- Qt5 examples: `lcl/interfaces/qt5/qtwscontrols.pp:261`, `lcl/interfaces/qt5/qtwsstdctrls.pp:479`
- GTK2 examples: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:456`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:371`

#### 18.3 `wsproc.pp` Scope Result

No GTK4 implementation work is identified from this file. `wsproc.pp` is `usable` shared infrastructure. Its audit relevance is diagnostic: warnings emitted by these helpers indicate call-order or handle-lifetime problems in the caller, not missing behavior in `wsproc.pp` itself.

#### 18.4 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSPROC_VALIDATION.md`
- Example: `example_gtk4_wsproc_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsproc_validation/wsproc_validation.lpi` succeeded.
- Run result: `xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wsproc_validation/wsproc_validation` completed with exit code 0.
- `WSCheckHandleAllocated(Button1, ...)` returned `False` before `Button1.HandleNeeded` and `True` after `Button1.HandleNeeded`.
- `WSCheckHandleAllocated(Menu1, ...)` returned `True` even before explicit `Menu1.HandleNeeded` in the validation sequence, and remained `True` afterward.
- `WSCheckReferenceAllocated(Images.Resolution[16], ...)` returned `False` before adding an image and still returned `False` after `Images.Add(Bitmap, nil)` plus re-fetching `Images.Resolution[16]`.
- The recurring startup warning `g_regex_match_full: assertion 'string != NULL' failed` was emitted.

Runtime interpretation: the control handle guard works as expected for a normal `TWinControl`. Menu and image-list-reference results reflect their actual LCL lifecycle state in this construction path; no GTK4 implementation gap is inferred from `wsproc.pp`.

Required follow-up checks:

1. If runtime logs show `called without handle/reference` warnings during GTK4 tests, trace the specific caller and component lifecycle rather than changing `wsproc.pp`.
2. Do not count backend-specific units such as `gtk4procs.pas` as comparable implementations of `wsproc.pp`; they belong to separate backend utility review when their call sites require it.

### 19. `lcl/widgetset/wsreferences.pp`

#### 19.1 Baseline Expectation

`wsreferences.pp` defines shared reference wrapper types used by LCL widgetset-backed objects. It does not create native resources by itself. `TWSReference` stores either a pointer or an integer handle in the same field, exposes `Allocated`, and provides temporary widgetset-only `_Init` / `_Clear` helpers.

Source references:

- `TLCLHandle` definition: `lcl/widgetset/wsreferences.pp:28`
- `TWSReference` storage and public API: `lcl/widgetset/wsreferences.pp:33`
- image-list/GDI/device/icon reference wrapper types: `lcl/widgetset/wsreferences.pp:71`
- `_Clear` / `_Init` implementations: `lcl/widgetset/wsreferences.pp:115`
- `Allocated` test: `lcl/widgetset/wsreferences.pp:130`

LCL reference lifecycle:

- `TLCLReferenceComponent.DestroyReference` calls `ReferenceDestroying`, dispatches to widgetset `DestroyReference`, clears the reference, and sets `FReferencePtr := nil`: `lcl/lclclasses.pp:204`
- `TLCLReferenceComponent.ReferenceNeeded` calls the descendant `WSCreateReference`, checks `ReferenceAllocated`, and then calls `ReferenceCreated`: `lcl/lclclasses.pp:234`
- the base `WSCreateReference` returns `nil` and must be overridden by reference-owning descendants: `lcl/lclclasses.pp:267`
- widgetset reference destruction dispatches through `TWSLCLReferenceComponentClass(WidgetSetClass).DestroyReference`: `lcl/lclclasses.pp:273`

#### 19.2 GTK4 / GTK2 / Qt5 Comparison

There are no GTK4/GTK2/Qt5-specific replacements for `wsreferences.pp`. The unit is shared by all widgetsets. Backend differences appear in the units that create or consume these references, for example image lists, graphics objects, device contexts, and icon/bitmap conversion paths.

Concrete reviewed example:

- baseline image-list `CreateReference` creates a `TDefaultImageListImplementor` and stores it with `Result._Init(impl)`: `lcl/widgetset/wsimglist.pp:163`
- baseline image-list `DestroyReference` frees `Reference.Ptr`: `lcl/widgetset/wsimglist.pp:194`
- GTK4 image-list overrides delegate to inherited reference creation/destruction: `lcl/interfaces/gtk4/gtk4wsimglist.pp:71`, `lcl/interfaces/gtk4/gtk4wsimglist.pp:85`

Judgment: `wsreferences.pp` is `usable` shared infrastructure. No GTK4-specific implementation gap was found in this file.

#### 19.3 `wsreferences.pp` Scope Result

No direct GTK4 work is identified from this file. Audit conclusions about reference-backed behavior must be made in the resource-specific units:

1. image-list behavior belongs under `wsimglist.pp` and GTK4 bitmap conversion,
2. font/pen/brush/region behavior belongs under graphics/device-context backend review,
3. control/window handles belong under `wscontrols.pp` and specific GTK4 widget classes.

#### 19.4 Focused Runtime Validation

- Plan: `PLAN_GTK4_WSREFERENCES_VALIDATION.md`
- Example: `example_gtk4_wsreferences_validation/`
- Build result: `./lazbuild --ws=gtk4 example_gtk4_wsreferences_validation/wsreferences_validation.lpi` succeeded.
- Run result: `example_gtk4_wsreferences_validation/wsreferences_validation` completed with exit code 0.
- Raw `TWSReference._Clear` produced `Allocated=False`, handle `0`.
- `_Init(@Value)` produced `Allocated=True` and `Ptr=@Value`.
- Re-clearing returned `Allocated=False`.
- `_Init(TLCLHandle(12345))` produced `Allocated=True`, handle `12345`.
- `TWSCustomImageListReference` initialized with handle `24680` and reported allocated; after `_Clear`, it reported `Allocated=False`.
- `TWSBitmapReference` initialized with handle `13579` and reported allocated.
- `TWSIconReference` initialized with handle `97531` and reported allocated.

Runtime interpretation: the shared reference wrappers behave as expected for pointer and handle storage. This does not validate native resource ownership or destruction; those remain the responsibility of owning widgetset units.

Required follow-up checks:

1. When a reference-backed resource leaks or is double-freed, inspect the owning `CreateReference` / `DestroyReference` implementation, not `wsreferences.pp` first.
2. For GTK4 image-list and graphics tests, verify that references are cleared after destruction and that stale `Ptr`/`Handle` values are not reused.

### 20. `lcl/widgetset/wsshellctrls.pp`

#### 20.1 Baseline Expectation

`wsshellctrls.pp` defines a very small widgetset surface for shell controls:

- `TWSCustomShellTreeView.DrawBuiltInIcon`
- `TWSCustomShellTreeView.GetBuiltinIconSize`
- `TWSCustomShellListView.GetBuiltInImageIndex`

The baseline implementations return no icon: zero size for tree icons and `-1` image index for list icons.

Source references:

- Baseline method declarations: `lcl/widgetset/wsshellctrls.pp:51`, `lcl/widgetset/wsshellctrls.pp:61`
- baseline tree icon defaults: `lcl/widgetset/wsshellctrls.pp:79`, `lcl/widgetset/wsshellctrls.pp:86`
- baseline list icon default: `lcl/widgetset/wsshellctrls.pp:95`
- fallback registration: `lcl/widgetset/wsshellctrls.pp:105`, `lcl/widgetset/wsshellctrls.pp:116`

#### 20.2 LCL Shell Control Behavior

Most shell-control behavior is implemented in `shellctrls.pas`, not in widgetset-specific units. The LCL code handles root/path validation, file enumeration, sorting, tree/list synchronization, delayed list population until handle creation, and list column content.

Source references:

- tree root setup and population: `lcl/shellctrls.pas:611`
- tree expand population: `lcl/shellctrls.pas:723`
- base path selection per platform: `lcl/shellctrls.pas:964`
- directory scanning: `lcl/shellctrls.pas:990`
- tree node population from files: `lcl/shellctrls.pas:1047`
- shell tree/list synchronization on selection: `lcl/shellctrls.pas:1141`
- tree built-in icon dispatch: `lcl/shellctrls.pas:1179`, `lcl/shellctrls.pas:1187`
- list root/mask/object-type updates: `lcl/shellctrls.pas:1723`, `lcl/shellctrls.pas:1762`, `lcl/shellctrls.pas:1783`
- list built-in image dispatch: `lcl/shellctrls.pas:1833`
- list population from directory files: `lcl/shellctrls.pas:1841`
- delayed population after list handle creation: `lcl/shellctrls.pas:1944`
- list refresh and tree synchronization: `lcl/shellctrls.pas:1990`

#### 20.3 GTK4 / GTK2 / Qt5 Comparison

GTK4, GTK2, and Qt5 all return `False` for `WSRegisterCustomShellTreeView` and `WSRegisterCustomShellListView`. Therefore all three use the baseline `TWSCustomShellTreeView` / `TWSCustomShellListView` fallback, whose built-in icon methods are effectively not implemented.

Source references:

- GTK4 shell factory returns `False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:590`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:595`
- GTK2 shell factory returns `False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:637`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:642`
- Qt5 shell factory returns `False`: `lcl/interfaces/qt5/qtwsfactory.pas:570`, `lcl/interfaces/qt5/qtwsfactory.pas:575`
- no GTK4/GTK2/Qt5 `*wsshellctrls*` implementation files were found in the reviewed interface directories.

Judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| ShellTreeView file/tree population | `usable_with_limits` | LCL-owned in `shellctrls.pas`; depends on underlying TreeView behavior and filesystem performance. |
| ShellListView file/list population | `usable_with_limits` | LCL-owned; depends on underlying ListView behavior. Existing GTK4 ListView gaps apply. |
| built-in tree icons | `stub_or_noop` | Baseline returns zero size and does not draw. Same for GTK2/Qt5 fallback. |
| built-in list icons | `stub_or_noop` | Baseline returns `-1`. Same for GTK2/Qt5 fallback. |
| GTK4-specific shell integration | `missing` | No GTK4 file/theme/icon-provider shell-control implementation found. |

#### 20.4 Focused Runtime Validation

Focused GTK4 validation was added in `PLAN_GTK4_WSSHELLCTRLS_VALIDATION.md` and `example_gtk4_wsshellctrls_validation/`.

Commands run:

```sh
./lazbuild --ws=gtk4 example_gtk4_wsshellctrls_validation/wsshellctrls_validation.lpi
xvfb-run -a env GDK_BACKEND=x11 example_gtk4_wsshellctrls_validation/wsshellctrls_validation
```

Observed runtime facts:

- `TShellTreeView` and `TShellListView` handles allocated under GTK4.
- A temporary root directory containing one subdirectory and one file produced `tree items=3` and `list items=2`.
- `TShellTreeView` built-in icon size returned `0x0`.
- `TShellTreeView.DrawBuiltInIcon` returned `0x0`.
- `TShellListView.GetBuiltInImageIndex` returned `-1` for both small and large image requests.

Result:

- Shell tree/list population is usable for the focused test directory through LCL-owned code.
- Built-in shell icons remain unimplemented through the shared fallback.
- The observed result matches the source-level diagnosis: GTK4 does not currently add a shell-icon implementation beyond the common fallback used by GTK2 and Qt5.

#### 20.5 `wsshellctrls.pp` Scope Result

No GTK4-only regression was found in `wsshellctrls.pp` relative to GTK2/Qt5 because all three widgetsets use the same fallback. However, shell controls are not GTK2/Qt5-equivalent to a platform-native file browser in the built-in icon area. For GTK4, the practical risk is split:

1. shell-specific built-in icons are absent through the shared fallback,
2. `TCustomShellListView` inherits all current GTK4 `TListView` limitations documented under `wscomctrls.pp`, including image-list routing, state images, geometry, and owner-data/runtime update concerns,
3. `TCustomShellTreeView` inherits the current TreeView registration/fallback situation documented under `wscomctrls.pp`.

Required follow-up tests:

1. ShellTreeView root `/`, custom root, hidden files, non-folders, sorting, expansion/collapse, refresh, and path selection on GTK4.
2. ShellListView root/mask/object-types, delayed handle population, refresh, selection preservation, and column auto-sizing on GTK4.
3. ShellTreeView + ShellListView synchronization in both directions.
4. `UseBuiltinIcons=True` behavior: document that built-in icons are absent unless user-provided image lists are supplied.
5. ShellListView with user-supplied `SmallImages`/`LargeImages`, checking GTK4 ListView image routing behavior.
6. Non-ASCII paths, permission-denied directories, symlinks, deleted folders during refresh, and large directory performance.

### 21. `lcl/widgetset/wsspin.pp`

#### 21.1 Baseline Expectation

`wsspin.pp` exposes the widgetset surface for `TCustomFloatSpinEdit` and `TSpinEdit`:

- `GetValue`
- `UpdateControl`
- `SetEditorEnabled`

The baseline implementation returns `0.0` for `GetValue` and leaves update/editor-enabled behavior as no-ops. A widgetset must therefore provide native handle creation and keep value, range, decimal places, increment, read-only state, text editing, and selection behavior coherent with `TCustomFloatSpinEdit`.

Source references:

- baseline method declarations: `lcl/widgetset/wsspin.pp:44`
- baseline defaults: `lcl/widgetset/wsspin.pp:71`, `lcl/widgetset/wsspin.pp:76`, `lcl/widgetset/wsspin.pp:81`
- fallback registration and `MaxLength` skip: `lcl/widgetset/wsspin.pp:92`, `lcl/widgetset/wsspin.pp:100`
- LCL `UpdateControl` clamps `FValue` through `GetLimitedValue` and dispatches to the widgetset: `lcl/include/spinedit.inc:13`
- `GetValue` reads through the widgetset only when the widget value changed: `lcl/include/spinedit.inc:173`
- LCL key filtering normalizes `.` and `,` to the locale decimal separator and blocks decimal separators when `DecimalPlaces = 0`: `lcl/include/spinedit.inc:125`
- LCL range semantics only constrain values when `MaxValue > MinValue`; equal min/max means unconstrained: `lcl/include/spinedit.inc:223`

#### 21.2 GTK2 / Qt5 Reference

GTK2 registers `TCustomFloatSpinEdit` and uses a native `GtkSpinButton`. It implements selection, value retrieval, read-only/editor-enabled state, handle creation, and bulk control updates. One important GTK2-specific behavior is that `GetValue` parses the entry text manually and normalizes both `.` and `,` to the current `DefaultFormatSettings.DecimalSeparator`, because the GTK2 code comments record a native spin-button value/text divergence for real `TFloatSpinEdit`.

Source references:

- GTK2 registration: `lcl/interfaces/gtk2/gtk2wsfactory.pas:624`
- GTK2 `GetValue` text parsing and decimal separator normalization: `lcl/interfaces/gtk2/gtk2wsspin.pp:95`
- GTK2 read-only/editor-enabled handling: `lcl/interfaces/gtk2/gtk2wsspin.pp:138`, `lcl/interfaces/gtk2/gtk2wsspin.pp:180`
- GTK2 `UpdateControl` uses `MaxValue > MinValue` for range validity: `lcl/interfaces/gtk2/gtk2wsspin.pp:192`
- GTK2 native handle creation: `lcl/interfaces/gtk2/gtk2wsspin.pp:237`

Qt5 registers `TCustomFloatSpinEdit` and chooses `TQtFloatSpinBox` for decimal spin edits and `TQtSpinBox` for integer spin edits. It recreates the native widget if `DecimalPlaces` crosses the integer/float boundary, updates min/max/step/value, supports alignment, and preserves `EditorEnabled=False` when read-only is cleared.

Source references:

- Qt5 registration: `lcl/interfaces/qt5/qtwsfactory.pas:557`
- Qt5 integer/float widget selection: `lcl/interfaces/qt5/qtwsspin.pp:106`
- Qt5 update range uses `MaxValue > MinValue`: `lcl/interfaces/qt5/qtwsspin.pp:68`
- Qt5 `SetEditorEnabled` and `SetReadOnly`: `lcl/interfaces/qt5/qtwsspin.pp:139`, `lcl/interfaces/qt5/qtwsspin.pp:154`
- Qt5 widget recreation on `DecimalPlaces` boundary change: `lcl/interfaces/qt5/qtwsspin.pp:170`

#### 21.3 GTK4 Review

GTK4 registers `TCustomFloatSpinEdit` with `TGtk4WSCustomFloatSpinEdit` and creates a `TGtk4SpinEdit`, which wraps a native GTK4 `GtkSpinButton`.

Source references:

- GTK4 registration: `lcl/interfaces/gtk4/gtk4wsfactory.pas:578`
- GTK4 widgetset class declarations: `lcl/interfaces/gtk4/gtk4wsspin.pp:31`
- GTK4 handle creation: `lcl/interfaces/gtk4/gtk4wsspin.pp:56`
- GTK4 selection methods: `lcl/interfaces/gtk4/gtk4wsspin.pp:74`, `lcl/interfaces/gtk4/gtk4wsspin.pp:83`, `lcl/interfaces/gtk4/gtk4wsspin.pp:101`, `lcl/interfaces/gtk4/gtk4wsspin.pp:111`
- GTK4 value retrieval: `lcl/interfaces/gtk4/gtk4wsspin.pp:92`
- GTK4 read-only/editor-enabled/alignment/update methods: `lcl/interfaces/gtk4/gtk4wsspin.pp:122`, `lcl/interfaces/gtk4/gtk4wsspin.pp:163`, `lcl/interfaces/gtk4/gtk4wsspin.pp:171`, `lcl/interfaces/gtk4/gtk4wsspin.pp:185`
- `TGtk4SpinEdit` wrapper properties and native `GtkSpinButton` calls: `lcl/interfaces/gtk4/gtk4widgets.pas:274`, `lcl/interfaces/gtk4/gtk4widgets.pas:5650`
- `TGtk4SpinEdit.GetValue` calls native `GtkSpinButton.update` before `get_value`: `lcl/interfaces/gtk4/gtk4widgets.pas:5691`
- `TGtk4SpinEdit.CreateWidget` uses `TGtkSpinButton.new_with_range`: `lcl/interfaces/gtk4/gtk4widgets.pas:5733`

GTK4 usable behavior:

- Native `GtkSpinButton` handle creation is present.
- Selection start/length is delegated through the GTK4 editable wrapper.
- `GetValue` forces a native spin-button update before reading the value.
- `SetReadOnly` follows the GTK2 pattern of collapsing the range to the current value to disable spin arrows.
- `SetEditorEnabled` keeps the entry non-editable when `ReadOnly=True`.
- Alignment is implemented, matching Qt5 coverage and exceeding the GTK2 method surface in this unit.
- Decimal places, step increment, range, value, and read-only state are all updated in `UpdateControl`.

GTK4 limitations and risks found by source review:

- GTK4 range validity uses `MaxValue >= MinValue` in `SetReadOnly` and `UpdateControl`, while LCL, GTK2, and Qt5 use `MaxValue > MinValue`. Because LCL explicitly states that `MinValue = MaxValue` means no constraint, GTK4 currently appears to impose a fixed native range in that case.
- GTK4 `GetValue` reads the native spin-button value after `GtkSpinButton.update`. GTK2 intentionally parses entry text and normalizes `.` / `,` because native value and entry text differed for float spin edits. GTK4 may be better because it calls `update`, but source review alone does not prove locale comma/dot and partially typed text behavior equals GTK2/LCL expectations.
- GTK4 uses a single `GtkSpinButton` for integer and float modes, while Qt5 recreates between integer and floating spin widgets. This is not automatically wrong for GTK4, but it requires focused testing when `DecimalPlaces` changes at runtime.
- `UpdateControl` sets `Numeric := DecimalPlaces > 0`. GTK's numeric property controls text filtering at the native entry level. LCL already filters keys and disallows decimal separators when `DecimalPlaces = 0`; setting native `numeric` to `False` for integer spin edits may allow text paths that LCL would normally reject, especially paste/input-method paths. This needs runtime verification.
- `ValueEmpty` is stored in LCL and triggers `UpdateControl`, but none of GTK2, Qt5, or GTK4 has a specific `SetValueEmpty` widgetset method. This is not a GTK4-only gap, but GTK4 must be tested for empty text/value synchronization because native `GtkSpinButton` may eagerly restore a numeric display.

GTK4 method judgments:

| Method / area | GTK4 status | Reason |
| --- | --- | --- |
| `CreateHandle` | `usable` | Creates a native GTK4 `GtkSpinButton` wrapper. |
| `GetPreferredSize` | `usable` | Delegates to the GTK4 widget preferred-size path. |
| selection start/length | `usable_with_limits` | Editable wrapper is wired; needs cursor/selection tests because spin buttons embed entry behavior. |
| `GetValue` | `needs_runtime_test` | Calls native update before reading, but GTK2's text-parsing workaround has no GTK4 equivalent. Focused run confirmed invalid programmatic text can crash before this can be fully evaluated. |
| `SetReadOnly` | `usable_with_limits` | Collapses range like GTK2, but uses `>=` range validity when restoring normal range. |
| `SetEditorEnabled` | `usable` | Preserves read-only dominance over editor-enabled state. |
| `SetAlignment` | `usable` | Delegates to the GTK4 entry alignment implementation. |
| `UpdateControl` | `partial` | Updates the important properties, but focused run confirmed `MinValue = MaxValue` can crash GTK4 and native `Numeric` is `False` for integer `TSpinEdit`. |

Focused runtime validation:

- Document: `PLAN_GTK4_SPINEDIT_VALIDATION.md`
- Example: `example_gtk4_spinedit_validation/`
- Build/run date: 2026-07-09
- Result summary: build succeeded; basic integer `TSpinEdit` state works; reversed min/max becomes unconstrained; equal min/max crashes at `MaxValue := 5`; invalid programmatic text crashes at `Text := 'abc123'`; creating `TFloatSpinEdit` currently follows a crash path with repeated GTK `step != 0.0` assertions, consistent with the reviewed `TCustomSpinEdit(LCLObject)` cast in `TGtk4SpinEdit.CreateWidget`.

#### 21.4 `wsspin.pp` Scope Result

GTK4 spin edit support is substantially implemented and not missing. The main work candidates are narrow but behavior-sensitive:

1. Align GTK4 range validity with LCL/GTK2/Qt5 by treating `MaxValue = MinValue` as unconstrained, not as a fixed range; this is runtime-confirmed because equality can crash.
2. Investigate and fix the `TFloatSpinEdit` creation path. `TGtk4SpinEdit.CreateWidget` currently treats the LCL object as `TCustomSpinEdit`, even though the widgetset registration is for `TCustomFloatSpinEdit`.
3. Verify whether GTK4 must follow GTK2 by parsing entry text in `GetValue`, especially for locale decimal separators, pasted values, and text that has not lost focus yet.
4. Verify whether `Numeric := DecimalPlaces > 0` is correct. If native numeric filtering is desired, integer mode may need `Numeric=True`, not `False`, while preserving LCL's decimal-separator filtering.
5. Test runtime `DecimalPlaces` changes between `0` and positive values after the `TFloatSpinEdit` creation crash is resolved.
6. Test `ValueEmpty` with native GTK4 display behavior before deciding whether a GTK4-specific workaround is needed.

Required follow-up tests:

1. `TSpinEdit` and `TFloatSpinEdit` with default range, `MinValue < MaxValue`, `MinValue = MaxValue`, and `MinValue > MaxValue`.
2. Values below min and above max, both before handle creation and after handle creation.
3. `DecimalPlaces = 0`, `1`, `2`, and runtime changes across `0 <-> positive`.
4. Typing and pasting digits, signs, exponent notation, letters, comma decimal, dot decimal, and partial invalid strings.
5. Locale where `DefaultFormatSettings.DecimalSeparator = ','`, checking text, `Value`, `OnChange`, and `EditingDone`.
6. `ReadOnly` and `EditorEnabled` combinations, including spin-arrow behavior while the text entry is non-editable.
7. Selection/caret APIs through `SelStart`, `SelLength`, `SelectAll`, and focus changes.
8. `ValueEmpty=True`, empty text, `RealSetText('')`, and transition back to numeric values.
9. Mouse wheel and keyboard up/down behavior with positive and negative increments.
10. Compare the same test form under GTK2, Qt5, and GTK4.

### 22. `lcl/widgetset/wsstdctrls.pp`

Status: reviewed. This file covers many core controls and is judged per control family, not as one yes/no result.

#### 22.1 Baseline Expectation

`wsstdctrls.pp` defines the widgetset contract for:

- `TCustomScrollBar`
- `TCustomGroupBox`
- `TCustomComboBox`
- `TCustomListBox`
- `TCustomEdit`
- `TCustomMemo`
- `TCustomStaticText`
- `TCustomButton`
- `TCustomCheckBox`
- `TToggleBox`
- `TRadioButton`

Most baseline methods are empty, fixed-result, or simple common fallback implementations. That means a usable widgetset needs real registration plus native behavior for text/selection, item models, popup/list state, scroll state, edit undo, clipboard, read-only, shortcut activation, and button/check/radio state.

Source references:

- baseline class declarations: `lcl/widgetset/wsstdctrls.pp:48`
- baseline listbox defaults: `lcl/widgetset/wsstdctrls.pp:306`
- baseline combobox defaults: `lcl/widgetset/wsstdctrls.pp:422`
- baseline edit defaults and fallback clipboard methods: `lcl/widgetset/wsstdctrls.pp:530`, `lcl/widgetset/wsstdctrls.pp:620`
- baseline memo defaults: `lcl/widgetset/wsstdctrls.pp:643`
- baseline static text defaults: `lcl/widgetset/wsstdctrls.pp:687`
- baseline button/check defaults: `lcl/widgetset/wsstdctrls.pp:706`, `lcl/widgetset/wsstdctrls.pp:717`
- LCL listbox handle initialization and interface `TStrings` replacement: `lcl/include/customlistbox.inc:134`
- LCL combobox handle initialization and interface `TStrings` replacement: `lcl/include/customcombobox.inc:23`
- LCL edit initialization dispatch: `lcl/include/customedit.inc:41`
- LCL memo initialization dispatch: `lcl/include/custommemo.inc:97`

#### 22.2 Registration Comparison

GTK4, GTK2, and Qt5 all register real widgetset classes for the major `StdCtrls` controls listed above, except `TButtonControl` and `TCustomLabel`, which all three leave unregistered or false in the reviewed factory paths.

Source references:

- GTK4 standard-control registrations: `lcl/interfaces/gtk4/gtk4wsfactory.pas:300`
- GTK2 standard-control registrations: `lcl/interfaces/gtk2/gtk2wsfactory.pas:301`
- Qt5 standard-control registrations: `lcl/interfaces/qt5/qtwsfactory.pas:282`
- GTK4 `ButtonControl=False`, `CustomLabel=False`: `lcl/interfaces/gtk4/gtk4wsfactory.pas:336`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:371`
- GTK2 `ButtonControl=False`, `CustomLabel=False`: `lcl/interfaces/gtk2/gtk2wsfactory.pas:344`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:383`
- Qt5 `ButtonControl=False`, `CustomLabel=False`: `lcl/interfaces/qt5/qtwsfactory.pas:319`, `lcl/interfaces/qt5/qtwsfactory.pas:354`

Judgment: registration coverage is broadly comparable for GTK4/GTK2/Qt5. The remaining audit is about behavior quality, not whether classes exist.

#### 22.3 GTK4 ListBox Review

GTK4 implements `TCustomListBox` using `TGtk4ListBox`, backed by `GtkScrolledWindow`, `GtkStringList`, `GtkSingleSelection` or `GtkMultiSelection`, and `GtkListView`.

Source references:

- GTK4 listbox widgetset class declarations: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:121`
- GTK4 listbox handle creation: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:562`
- `TGtk4ListBox.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:7994`
- GTK4 item model and selection model creation: `lcl/interfaces/gtk4/gtk4widgets.pas:8012`
- GTK4 selection changed signal: `lcl/interfaces/gtk4/gtk4widgets.pas:8037`
- GTK4 listbox `ItemIndex`, selection, and top index helpers: `lcl/interfaces/gtk4/gtk4widgets.pas:8093`, `lcl/interfaces/gtk4/gtk4widgets.pas:8123`, `lcl/interfaces/gtk4/gtk4widgets.pas:8151`, `lcl/interfaces/gtk4/gtk4widgets.pas:8197`

GTK4 usable behavior:

- Real model-backed listbox exists.
- Single and multi selection are represented by different GTK4 selection model types.
- Interface `TStrings` uses `TGtkStringListStrings`, matching the LCL expectation that `Items` becomes widgetset-owned while the handle exists.
- Selection change is delivered as `LM_SELCHANGE`, with design-time native selection changes suppressed.
- `SetSelectionMode` recreates the control when GTK4 must switch selection model types.

GTK4 limitations found by source review:

- `GetIndexAtXY`, `GetItemRect`, `GetTopIndex`, and `SetTopIndex` estimate row positions from scrollbar adjustment upper value divided by item count. GTK2 uses `GtkTreeView` path/cell area APIs and Qt5 uses `QListWidget.indexAt` / `visualItemRect`. GTK4 therefore has weaker geometry accuracy, especially with variable item height, owner-draw rows, font changes, DPI changes, and partially realized list items.
- `SetColumnCount` is explicitly a no-op with a comment that GTK4 `GtkTreeView` does not support multi-column listbox layout. The comment names `GtkTreeView`, but the implementation actually uses `GtkListView`; either way the LCL `Columns` feature is not implemented.
  - **Implemented 2026-07-11 via GtkGridView.** (`Columns` is otherwise win32-only
    in LCL — gtk2 has no listbox `SetColumns`, and qt5's `SetColumnCount` is a
    commented-out `{$note implement …}` stub — so gtk4 now exceeds the other
    non-win32 widgetsets here.) Key enabler: `GtkGridView` is a `GtkListBase`
    widget sharing the EXACT same selection-model + factory API as `GtkListView`,
    so the whole data path is reused; only the widget and the item geometry
    differ. `TGtk4ListBox`/`TGtk4CheckListBox` `CreateWidget` build a
    `GtkGridView` (min=max columns = `Columns`) when `Columns>0`, else the usual
    `GtkListView`. `GetIndexAtXY`/`GetItemRect`/`GetTopIndex` gained a row-major
    grid branch (`index = row*Cols + col`), and `SetColumnCount` recreates the
    handle on a mode/count change (design-time sets before handle allocation, so
    that only fires for runtime changes). Verified under Xvfb: single-column
    unaffected; 3-column grid lays out 3×100px cells, `ItemRect` and `ItemAtPos`
    correct; visually confirmed on hardware. Flow is row-major (win32's
    `LBS_MULTICOLUMN` is column-major, but no other widgetset implements it at
    all, so this is an improvement).
- `SetScrollWidth` toggles horizontal scrollbar policy based on current allocated width, but it does not set an adjustment upper/maximum equivalent to GTK2 or Qt5. This may make `ScrollWidth` less deterministic.
- `SetMultiSelect` in `TGtk4ListBox` itself is empty because selection model type is fixed; the widgetset class compensates by recreating the control. Runtime state preservation through that recreation needs testing.
- Owner-draw and variable-height listbox behavior is not proven from the reviewed standard listbox path; the simple factory creates a label per row.

ListBox judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| basic items and selection | `usable_with_limits` | Real GtkListView model and selection exist. |
| multi-select | `usable_with_limits` | Uses GtkMultiSelection but requires recreate on mode change. |
| item geometry APIs | `partial` | Uses average row-height approximation instead of native row rect/index APIs. |
| `Columns` | `stub_or_noop` | Explicit no-op. |
| horizontal `ScrollWidth` | `partial` | Policy changes exist, but no clear content-width/adjustment max behavior like GTK2/Qt5. |
| owner-draw/variable listbox | `needs_runtime_test` | Standard factory path is label-based; variable geometry paths are approximate. |

#### 22.4 GTK4 ComboBox Review

GTK4 splits combo boxes into two native wrapper paths:

- editable styles use `TGtk4ComboBox`, implemented as a `GtkBox` containing `GtkEntry`, button, `GtkPopover`, `GtkScrolledWindow`, and `GtkListView`;
- non-editable styles use `TGtk4DropDown`.

Source references:

- GTK4 combobox widgetset class declarations: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:78`
- GTK4 combobox handle path choice: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:802`
- editable `TGtk4ComboBox.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:10231`
- editable popover/dropdown handling: `lcl/interfaces/gtk4/gtk4widgets.pas:10064`, `lcl/interfaces/gtk4/gtk4widgets.pas:10148`, `lcl/interfaces/gtk4/gtk4widgets.pas:10423`
- non-editable `TGtk4DropDown.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:10547`
- non-editable selected index/text: `lcl/interfaces/gtk4/gtk4widgets.pas:10591`, `lcl/interfaces/gtk4/gtk4widgets.pas:10615`
- owner-draw dropdown factory callbacks: `lcl/interfaces/gtk4/gtk4widgets.pas:10448`

GTK4 usable behavior:

- Editable and non-editable combo styles are implemented with different GTK4-native wrappers.
- Editable combo supports selection APIs, max length, read-only, text hint, item index, item model, sorting wrapper, dropdown count, and programmatic popup through the custom popover.
- Non-editable/owner-draw dropdown supports item index, text from selection, and owner-draw callbacks for drawing and variable measuring.
- Dropdown/close-up events are emitted for the editable popover through `notify::visible`.

GTK4 limitations found by source review:

- `GtkDropDown` path has no popup-shown property and no programmatic popup/popdown API in this wrapper. `GetDroppedDown` returns false and `SetDroppedDown` exits for non-editable styles. GTK2 and Qt5 implement popup/popdown for their combo widgets.
  - **Update 2026-07-11 — fixed.** `GtkDropDown` is a final type (cannot be subclassed), but it opens/closes its popover purely from its internal `GtkToggleButton`'s active state (`gtkdropdown.c: button_toggled`). `TGtk4DropDown.SetDroppedDown`/`GetDroppedDown` now find that button (the dropdown's first child, per `gtkdropdown.ui`) and drive/read its active state, giving programmatic `DroppedDown` parity with GTK2/Qt5. Structure-guarded (no-op if the child is ever not a `GtkToggleButton`). Runtime-verified: `DroppedDown:=True` opens, `:=False` closes, `GetDroppedDown` tracks state (a manual click can't test close because the autohide popover dismisses on any outside click — verified with a timer instead).
- `SetDropDownCount` only applies to editable `TGtk4ComboBox`; non-editable `TGtk4DropDown` ignores it in the widgetset method.
- `SetItemHeight` only applies to `TGtk4ComboBox`, not `TGtk4DropDown`. Owner-draw dropdown item height is handled in the factory, but normal non-editable dropdown item height is not clearly controlled.
- `SetArrowKeysTraverseList` is unsupported; GTK2 and Qt5 also have TODO/no-op behavior, so this is not GTK4-only.
- Editable combo popup is custom-built with `GtkPopover`, not the platform `GtkDropDown` popup. This is workable but increases risk around focus, keyboard navigation, grab/close behavior, and accessibility.

ComboBox judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| editable combo | `usable_with_limits` | Custom popover/list model exists and covers core behavior. |
| non-editable combo | `usable_with_limits` | GtkDropDown covers selection but lacks programmatic popup state/control. |
| `DroppedDown` property/methods | `usable` (fixed 2026-07-11) | Was `partial` (editable only). Non-editable `GtkDropDown` now drives its internal toggle button for programmatic open/close — see Update above. |
| `DropDownCount` | `partial` | Works for editable path only. |
| owner-draw dropdown | `needs_runtime_test` | Draw/measure callbacks exist; event/state fidelity must be tested. |
| arrow-key traverse option | `backend_limited` | No-op in GTK4 and also not supported in GTK2/Qt5 references. |

#### 22.5 GTK4 Edit and Memo Review

GTK4 implements `TCustomEdit` with `TGtk4Entry` and `TCustomMemo` with `TGtk4Memo` wrapping `GtkTextView` inside `GtkScrolledWindow`.

Source references:

- GTK4 edit widgetset declarations: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:155`
- GTK4 edit create/update methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1094`
- `TGtk4Entry` insert filtering, char case, max length, text hint, echo mode: `lcl/interfaces/gtk4/gtk4widgets.pas:5483`, `lcl/interfaces/gtk4/gtk4widgets.pas:5564`, `lcl/interfaces/gtk4/gtk4widgets.pas:5584`
- GTK4 edit undo: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1114`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1280`
- GTK4 memo widgetset declarations: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:191`
- `TGtk4Memo.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:7637`
- GTK4 memo text/read-only/tabs/wrap methods: `lcl/interfaces/gtk4/gtk4widgets.pas:7741`, `lcl/interfaces/gtk4/gtk4widgets.pas:7784`, `lcl/interfaces/gtk4/gtk4widgets.pas:7790`, `lcl/interfaces/gtk4/gtk4widgets.pas:7796`
- GTK4 memo undo and can-undo: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1362`, `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1375`

GTK4 usable behavior:

- Basic edit/memo handle creation, text storage, caret/selection APIs, read-only, alignment, max length, password/echo mode for edit, text hint for edit, clipboard fallback, and memo scrollbars/wrap/tabs are implemented.
- `TGtk4Entry.InsertText` enforces `NumbersOnly` and `CharCase` during insertion.
- `TGtk4Memo` enforces char case/max length through a `GtkTextBuffer` insert callback.
- Memo undo uses GTK4 `GtkTextBuffer` undo APIs and can query whether undo is available.

GTK4 limitations found by source review:

- `TEdit.GetCanUndo`: GTK4 exposes no public query for the internal `GtkEntry`/`GtkText` undo stack (its history is private, and — confirmed in `gtktext.c` — the `text.undo` action's enabled state is never toggled). **Fixed 2026-07-12 (`5442f80`)** by approximating with a baseline: `TGtk4Entry` records the text at each programmatic `setText`, and `GetCanUndo` reports whether the current text differs from it (pristine/undone-to-baseline -> False, edited -> True) — a strict improvement over the old blanket True. Qt5 queries `IQtEdit.isUndoAvailable`; GTK2 leaves undo effectively unimplemented.
- `TEdit.Undo` **was a silent no-op** — it activated `text.undo` on the outer `GtkEntry`, but that action is installed on the inner `GtkText` delegate and GTK widget actions do not propagate parent->child. **Fixed 2026-07-12 (`859a8d4`)** by routing to the delegate via `gtk_editable_get_delegate`; runtime-verified with real key input (typing then Undo now steps the text back).
- `Cut`, `Copy`, and `Paste` use LCL-level fallback (`CopyToClipboard`, `ClearSelection`, `SelText`) rather than native GTK editing clipboard operations. This can be acceptable, but it needs tests for UTF-8, password/echo mode, read-only, and selection edge cases.
- `TGtk4Entry.SetTextHint` only sets placeholder text when `AHint <> ''`; clearing an existing text hint may not clear the native placeholder.
- `SetHideSelection` adds/removes a CSS class, but source review did not find the CSS definition in this pass. Visual behavior needs runtime verification.
- Memo `SetEchoMode` and `SetPasswordChar` are no-ops because `GtkTextView` has no password mode; this matches the practical Memo scope.

Edit/Memo judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| basic single-line edit | `usable_with_limits` | Core text/selection/read-only/path implemented. |
| `TEdit.CanUndo` | `usable_with_limits` (fixed 2026-07-12, `5442f80`) | No public can-undo query in GTK4 (history private; `text.undo` enabled never toggled). Approximated by comparing current text to the last programmatic `setText` baseline: pristine/undone-to-baseline -> False, edited -> True (was blanket True). Imprecise only when text differs from baseline yet the native stack is empty. qt5 can query exactly; gtk2 has no edit undo. |
| `TEdit.Undo` | `usable` (fixed 2026-07-12, `859a8d4`) | Was a silent no-op (activated `text.undo` on the outer GtkEntry, but the action lives on the inner GtkText delegate). Now routed via `gtk_editable_get_delegate`; runtime-verified with real key input. gtk2 baseline has no undo. |
| edit clipboard operations | `usable_with_limits` | Common LCL fallback, not native GTK clipboard operation. |
| text hint clearing | `usable` (fixed 2026-07-10) | Clearing now passes nil to the native placeholder; set/replace/clear cycle runtime-verified. See `PLAN_GTK4_EDITMEMO_VALIDATION.md`. |
| memo text/scroll/wrap/tabs | `usable_with_limits` | GTK4 TextView implementation exists; input policy needs tests. |
| memo undo | `usable` | Uses GTK4 TextBuffer can-undo/undo APIs. |

#### 22.6 GTK4 ScrollBar Review

GTK4 implements `TCustomScrollBar` with `TGtk4ScrollBar`, wrapping a GTK4 `GtkScrollbar` and its `GtkAdjustment`.

Source references:

- LCL scrollbar create/update/scroll flow: `lcl/include/scrollbar.inc:46`, `lcl/include/scrollbar.inc:93`, `lcl/include/scrollbar.inc:177`
- GTK4 scrollbar widgetset methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:523`
- GTK4 scrollbar wrapper implementation: `lcl/interfaces/gtk4/gtk4widgets.pas:5961`
- GTK4 adjustment setup in `CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:5997`
- GTK4 adjustment update in `SetParams`: `lcl/interfaces/gtk4/gtk4widgets.pas:6017`
- GTK2 reference `SetParams`: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2742`
- Qt5 reference `SetParams`: `lcl/interfaces/qt5/qtwsstdctrls.pp:362`

GTK4 usable behavior:

- Native scrollbar creation exists.
- Orientation changes recreate the control, like GTK2.
- `ShowHide` reapplies params before showing, like GTK2/Qt5.
- `SetParams` writes position/min/max/page/increments into the GTK adjustment.

GTK4 limitations and likely defects found by source review:

- The GTK4 adjustment `value-changed` signal is connected on the adjustment object, but the callback declaration only accepts one parameter and treats that first parameter as `TGtk4Scrollbar`. GTK signal callbacks receive the adjustment as the first parameter and user data as a later parameter. Therefore the current callback path is very likely not delivering native scroll changes back to the LCL scrollbar object correctly.
- GTK4 configures the adjustment upper as `Max + PageSize`, but `value_changed` reads `get_upper` and passes it directly as the LCL `AMax` to `TScrollBar.SetParams`. If that callback runs, the LCL `Max` can be expanded from `Max` to `Max + PageSize` after a native value change.
- GTK2/Qt5 do not have the same callback shape. GTK2 uses range scroll callbacks that deliver `LM_HSCROLL` / `LM_VSCROLL`; Qt5 uses `TQtScrollBar` event attachment and clamps max as `Max - PageSize` in the native range.
- `TGtk4Range.SetRange` explicitly does nothing for `wtScrollBar`, so the scrollbar depends completely on `TGtk4ScrollBar.SetParams` for native range sync.

ScrollBar judgments (original source review):

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| create/orientation | `usable_with_limits` | Native widget exists; kind changes recreate. |
| programmatic params | `partial` | Writes adjustment, but upper value uses `Max + PageSize`. |
| user scroll event delivery | `missing` | Callback signature/source object mismatch is visible in source. |
| LCL max/range preservation | `partial` | `get_upper` is fed back as LCL max if callback runs. |

Update 2026-07-10 — fixed after runtime validation. See
`PLAN_GTK4_SCROLLBAR_VALIDATION.md` (runs 1-2 pre-fix, Implementation Fix
section post-fix). Mechanism refinement: the one-parameter callback was a
non-static `class procedure`, whose hidden class `Self` absorbed the C
`adjustment` argument, so `bar` received the user data and the callback
*accidentally ran* — confirming the `Max + PageSize` feedback as an active
defect (measured `Max` 100→110→120) while `OnScroll` never fired. Fix in
`gtk4widgets.pas`: two-parameter unit-level adjustment callback delivering
`LM_HSCROLL`/`LM_VSCROLL` (`SB_THUMBPOSITION`) with
InUpdate/csDesigning/live-pointer guards, and adjustment `upper = Max`
(gtk2 parity) in `CreateWidget`/`SetParams`. Post-fix judgments:
create/orientation `usable_with_limits`; programmatic params `usable`;
user scroll event delivery `usable` (single scroll code — GTK4 adjustment
signal carries no scroll-type detail); LCL max/range preservation `usable`.

#### 22.7 GTK4 GroupBox Review

GTK4 implements `TCustomGroupBox` as a `GtkFrame` containing a `GtkOverlay`, a `GtkFixed` child area, and a drawing overlay.

Source references:

- LCL groupbox behavior: `lcl/include/customgroupbox.inc:11`
- GTK4 groupbox widgetset methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:421`
- GTK4 groupbox widget creation/text: `lcl/interfaces/gtk4/gtk4widgets.pas:5297`
- GTK2 groupbox create/client rect/text reference: `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2295`, `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2366`, `lcl/interfaces/gtk2/gtk2wsstdctrls.pp:2421`
- Qt5 groupbox client rect reference: `lcl/interfaces/qt5/qtwsstdctrls.pp:1387`

GTK4 usable behavior:

- Native frame-backed groupbox exists.
- Child controls are hosted through a fixed central widget.
- Caption text is mapped to the GTK frame label.
- Preferred size delegates to the GTK4 widget preferred-size path.

GTK4 limitations found by source review:

- `GetDefaultClientRect` uses fixed constants (`20` top margin and `2` padding) instead of style/theme metrics. GTK2 calculates from `GetStyleGroupboxFrameBorders`; Qt5 uses style pixel metrics.
- Runtime caption font/color treatment is weaker than GTK2, where label font/color is explicitly updated in `SetFont`.
- Empty/non-empty caption changes remove/create the label widget, but client rect recalculation after caption changes is only noted as a comment in `TGtk4GroupBox.setText`.

GroupBox judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| basic groupbox/container | `usable_with_limits` | GtkFrame + GtkFixed child area exists. |
| client rect/theme metrics | `usable` (fixed 2026-07-11) | Client rect now reflects the GtkFrame's inset and reacts to the caption — see FIXED note below. |
| caption update | `usable` (fixed 2026-07-11) | Text path plus client-rect refresh on caption change (idle re-sync). |

**FIXED 2026-07-11.** The five-part solution that finally worked (all verified
under Xvfb — metric reacts — and on hardware):
1. `SetupPaintArea` sets `hexpand/vexpand/halign=valign=FILL` on the GtkFixed so
   GtkOverlay allocates it to the overlay's actual (inset) content area instead
   of leaving it 0x0.
2. `SetBounds` skips its full-size force-allocation of the GtkFixed for a
   groupbox (the force was overriding the frame inset); the expand above drives
   it instead. Non-groupbox containers keep the force (no regression).
3. `getClientRect` falls back to the overlay parent's allocation when the
   GtkFixed reports unrealized/0x0 (the GtkFixed caches natural sizes; the
   overlay carries the real inset content size).
4. `Gtk4MapWidget` invalidates the client-rect cache (`InvalidateClientRectCache`
   + `DoAdjustClientRectChange`) on map — this is the replacement for GTK4's
   removed size-allocate signal, so LCL re-queries getClientRect once the frame
   has reserved its label space.
5. `TGtk4GroupBox.setText` schedules a `g_idle_add` re-sync so a runtime caption
   change (which re-lays-out the frame asynchronously) also refreshes the rect.
Result: a 300x180 groupbox reports client height 152 with a caption and 178
without, and children sit below the label. Historical investigation follows.

**Root-cause investigation 2026-07-11 (superseded by the fix above):**

The groupbox structure is `GtkFrame -> GtkOverlay -> [GtkFixed (children),
GtkDrawingArea (paint)]`; children go into the GtkFixed, which
`GetContainerWidget` returns. On real hardware the GtkFrame *does* reserve the
label+border area — instrumenting `TGtk4Widget.SetBounds` showed a 300x180
groupbox allocating the overlay to `(0,26) 298x152`. The defect is that
SetBounds then force-allocates the GtkFixed to the **full** outer size (its
comment: "GtkOverlay does not reliably propagate allocation to overlay
children ... a stale 0x0 clips children invisible"), which overrides the inset,
so children cover the title and `getClientRect` (which reads the GtkFixed
allocation) returns the full, un-inset rect that never reacts to the caption.

A first fix attempt — allocate the GtkFixed to the overlay's live content
allocation instead of the full size — works interactively (children move below
the title, client rect reacts to caption) but is **layout-timing-dependent**:
an auto-driven run (fast timer) reports the full `300x180` at every step
because the overlay isn't inset-allocated yet when SetBounds runs, and there is
no re-sync afterward. Two GTK4 realities make this unreliable:
1. The frame inset needs live font/theme metrics — it is 0 under Xvfb (headless
   has no metrics), so this item is **not testable under Xvfb**, only on real
   hardware.
2. **GTK4 removed the `size-allocate` signal** (it is a vfunc now; the
   referenced `Gtk4WidgetSizeAllocated` does not exist, and `notify::width/
   height` is dead before GTK 4.12). So nothing invalidates the cached LCL
   client rect once the frame finally settles its allocation.

A proper fix therefore needs BOTH: (a) deterministic frame-chrome measurement
(e.g. `gtk_widget_measure` on `gtk_frame_get_label_widget` for the label
height + the frame border) so `getClientRect`/`getClientOffset` return the
inset regardless of allocation timing, and (b) a re-sync trigger to replace the
removed size-allocate signal (e.g. a `map`/first-idle hook that calls
`InvalidateClientRectCache` + re-lays-out children once metrics exist). The
race-dependent SetBounds patch was reverted; ship only a measurement-based
solution.

#### 22.8 GTK4 StaticText, Button, CheckBox, ToggleBox, RadioButton Review

GTK4 implements these control families with real native wrappers:

- `TGtk4StaticText`
- `TGtk4Button`
- `TGtk4CheckBox`
- `TGtk4ToggleButton`
- `TGtk4RadioButton`

Source references:

- GTK4 static text widgetset methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1526`
- `TGtk4StaticText` implementation: `lcl/interfaces/gtk4/gtk4widgets.pas:6190`
- GTK4 button methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1562`
- GTK4 checkbox methods: `lcl/interfaces/gtk4/gtk4wsstdctrls.pp:1602`
- `TGtk4ToggleButton` implementation: `lcl/interfaces/gtk4/gtk4widgets.pas:10890`
- `TGtk4CheckBox` implementation: `lcl/interfaces/gtk4/gtk4widgets.pas:10923`
- `TGtk4RadioButton` grouping path: `lcl/interfaces/gtk4/gtk4widgets.pas:10992`

First-pass findings:

- `TStaticText` alignment works through label `xalign`, but `SetStaticBorderStyle` is effectively a no-op because GTK4 removed `GtkFrame.set_shadow_type`. The getter still reads frame shadow type, but the setter cannot change it in this code.
  - **Update 2026-07-11 — fixed.** GTK4 has no `set_shadow_type`, so the border
    is now driven by CSS classes on the frame (`lcl-static-none` /
    `lcl-static-sunken`, defined in the LoadCSSTheme display provider; `sbsSingle`
    keeps the theme's own frame border for a consistent, theme-coloured line).
    The getter no longer reads the removed shadow API — it returns the stored
    `FBorderStyle`, so `BorderStyle` round-trips. Get/set round-trip verified
    under Xvfb (all three states); border toggle visually confirmed on hardware.
- `TButton.SetDefault` delegates to `TGtk4Button.SetDefault`, which only calls `set_can_default`. It does not grab default or otherwise prove active default focus behavior. The LCL form default/cancel action logic still exists, but native default visual/activation behavior needs tests.
- `SetShortCut` for button/check controls calls `Gtk4SetWidgetShortCut`, but that helper exits early because `GTK4_ENABLE_WIDGET_SHORTCUTS = False`. Therefore widget-level shortcuts are currently disabled by source constant, even though the plumbing exists.
- `TCheckBox` supports checked/unchecked/grayed through GTK4 check-button active/inconsistent state.
  - **Update 2026-07-11 — fixed.** Leaving `cbGrayed` for `cbChecked`/`cbUnchecked`
    left `State` stuck at `cbGrayed`: `TGtk4CheckBox.SetState`'s non-grayed branch
    called `set_active` but not `set_inconsistent(False)`, and `GetState` checks
    inconsistent first. `active`/`inconsistent` are independent GtkCheckButton
    properties, so the branch now clears inconsistent explicitly. Verified (Xvfb,
    logical state) across all six grayed<->checked<->unchecked transitions.
- `TToggleBox` maps `cbGrayed` to checked because `GtkToggleButton` has no tri-state. Qt5 does the same for `TQtToggleBox`, so this is not a GTK4-only limitation.
- Radio button grouping is implemented by joining an existing sibling or first radio in a `TRadioGroup`. This is comparable to GTK2's sibling scan, but GTK4 has a special `HiddenRadioButton` early exit and assumes the first `TRadioGroup` control can be used as a radio handle. Dynamic parent/order/create-handle cases and `ItemIndex=-1` hidden-button behavior need runtime tests.

First-pass judgments:

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| StaticText alignment/text | `usable` | Label text and xalign are wired. |
| StaticText border style | `usable` (fixed 2026-07-11) | Was `backend_limited`. GTK4 removed the frame shadow API, so BorderStyle is now driven by CSS classes; getter returns the stored value. See Update above. |
| Button basic behavior | `usable` (fixed 2026-07-10) | SetDefault no longer routes through the set_can_default→set_can_focus binding stub (which made the Default button unfocusable when it lost active-default); now set_receives_default. Return stays LCL-driven (gtk2 parity). |
| widget shortcuts | `stub_or_noop` (intentional, documented 2026-07-10) | Disabled on purpose: the LCL processes TShortCut itself; GTK widget-level shortcuts would double-activate. |
| CheckBox state | `usable_with_limits` | Checked/unchecked/grayed transitions all work (grayed-exit fixed 2026-07-11, see above); alignment uses widget direction and needs RTL/layout tests. |
| ToggleBox grayed state | `backend_limited` | GtkToggleButton lacks tri-state; Qt5 also maps grayed to checked. |
| RadioButton grouping | `usable` (fixed 2026-07-10) | The join_group binding is an empty stub — radios were never natively grouped (runtime-proven: both stayed checked). Now grouped via new gtk4_check_button_set_group binding; both switch directions verified, ItemIndex=-1 deselect-all confirmed possible on GTK4 groups. |

#### 22.9 Focused Runtime Validation

Existing focused validation documents cover several `wsstdctrls.pp` families:

- `PLAN_GTK4_SCROLLBAR_VALIDATION.md` / `example_gtk4_scrollbar_validation/`
- `PLAN_GTK4_EDITMEMO_VALIDATION.md` / `example_gtk4_editmemo_validation/`
- `PLAN_GTK4_STDCTRLS_BUTTONS_VALIDATION.md` / `example_gtk4_stdctrls_validation/`
- `PLAN_GTK4_STDCTRLS_LISTCOMBO_VALIDATION.md` / `example_gtk4_stdctrls_listcombo_validation/`

The ListBox/ComboBox/GroupBox validation was run under GTK4, GTK2, and Qt5.

GTK4 observed facts:

- `TListBox`, editable `TComboBox`, non-editable `TComboBox`, and `TGroupBox` handles allocated.
- ListBox `ItemRect`, `ItemAtPos`, `TopIndex`, and runtime `MultiSelect` were coherent in the focused run.
- GTK emitted `gtk_single_selection_get_selected: assertion 'GTK_IS_SINGLE_SELECTION (self)' failed` during the GTK4 listbox run. This needs narrower attribution before implementation work.
- `Columns := 3` left public geometry unchanged in the focused run, matching the source-level no-op.
- Editable combo programmatic `DroppedDown` worked.
- Non-editable `csDropDownList` combo programmatic `DroppedDown` did not work: after `DroppedDown := True`, `DroppedDown=False`.
- Combo `OnDropDown`/`OnCloseUp` fired once each, matching only the editable combo path.
- GroupBox `ClientRect` did not change when caption was cleared/restored: all observed rects were `(0,0,300,130)`.

GTK2/Qt5 comparison facts from the same example:

- GTK2 and Qt5 both opened and closed the non-editable dropdown-list combo programmatically.
- GTK2 and Qt5 both fired combo dropdown/closeup events twice, covering editable and non-editable combos.
- GTK2 and Qt5 both changed `TGroupBox.ClientRect` when the caption was cleared/restored.

Validation result:

- GTK4 ListBox is usable for the focused basic path; `Columns` is now implemented via GtkGridView (2026-07-11, see above). The GTK critical warning remains unresolved.
- GTK4 non-editable ComboBox popup state/control is below GTK2/Qt5 behavior.
- GTK4 GroupBox client-rect behavior is below GTK2/Qt5 behavior for caption/no-caption transitions.

#### 22.10 `wsstdctrls.pp` Scope Result

GTK4 standard controls are not generally missing. The largest implementation risks found in this pass are concentrated in these areas:

1. `TCustomScrollBar` native value-change delivery and range feedback are likely defective by source inspection.
2. `TCustomListBox` geometry and multi-column behavior are below GTK2/Qt5 quality.
3. `TCustomComboBox` non-editable popup state/control is backend-limited or missing compared with GTK2/Qt5.
4. `TEdit.CanUndo`, text-hint clearing, and native edit clipboard/action behavior need targeted validation.
5. `TStaticText` border style and widget shortcuts are disabled/no-op by source.
6. `TCustomGroupBox` client rect uses hard-coded metrics rather than theme metrics.
7. `TRadioButton` grouping exists but needs tests for reparenting, `TRadioGroup`, and hidden-button uncheck behavior.

Required follow-up tests:

1. Standalone horizontal/vertical `TScrollBar`: drag thumb, line/page buttons, mouse wheel, min/max/page changes, and verify `Position`, `Min`, `Max`, `OnScroll`, and `OnChange`.
2. `TListBox`: `ItemAtPos`, `ItemRect`, `TopIndex`, `ScrollWidth`, `Columns`, multi-select, owner-draw fixed/variable, sorted items, object preservation, and handle recreation.
3. `TComboBox`: all styles, editable/non-editable `DroppedDown`, `DropDownCount`, sorted items, text/item-index sync, owner-draw fixed/variable, item objects, keyboard navigation, close-up/dropdown events.
4. `TEdit`: undo stack availability, `Undo`, `Cut/Copy/Paste`, `NumbersOnly`, `CharCase`, `TextHint` set/clear, password/echo mode, hide-selection CSS, read-only.
5. `TMemo`: text/line preservation across handle recreation, undo, max length, char case, WantTabs/WantReturns, scrollbars, word wrap, large text, UTF-8.
6. `TGroupBox`: caption changes, empty caption, font/color, child bounds/client rect at multiple themes/scales, parent background and custom painting.
7. `TButton`: default/cancel/modal result behavior with Enter/Escape, active default changes, native default visual, disabled/default transitions.
8. `TCheckBox`, `TToggleBox`, `TRadioButton`: state transitions, grayed state, alignment/RTL, accelerator keys, dynamic reparenting, `TRadioGroup.ItemIndex=-1`, and hidden radio behavior.

### 23. `lcl/widgetset/wstoolwin.pp`

#### 23.1 Baseline Scope

`wstoolwin.pp` is a narrow widgetset contract file for `TToolWindow`, not for the practical `TToolBar`/`TToolButton` API surface. It defines only:

- `TWSToolWindow = class(TWSCustomControl)`;
- no published methods;
- no active initialization registration for `TToolWindow`.

Source references:

- baseline `TWSToolWindow`: `lcl/widgetset/wstoolwin.pp:46`
- disabled baseline registration comment: `lcl/widgetset/wstoolwin.pp:60`
- LCL `TToolWindow` class declaration: `lcl/toolwin.pp:53`
- LCL `TToolWindow` implementation: `lcl/include/toolwindow.inc:17`
- `TToolBar = class(TToolWindow)`: `lcl/comctrls.pp:2262`
- `TCustomCoolBar = class(TToolWindow)`: `lcl/comctrls.pp:2556`
- `TWSToolBar = class(TWSToolWindow)`: `lcl/widgetset/wscomctrls.pp:238`

The LCL-side `TToolWindow` behavior is implemented in `toolwindow.inc`: constructor defaults, edge border/client rect adjustment, `Paint` using `DrawEdge`, and simple `BeginUpdate`/`EndUpdate` counters. There is no direct `TToolWindow.WSRegisterClass` path found in this review.

#### 23.2 GTK2, Qt5, GTK4 Registration Comparison

Search result: GTK2, Qt5, and GTK4 do not register a standalone `TToolWindow` widgetset class. The only related direct registration in these three widgetsets is for `TToolBar` through `wscomctrls.pp`.

| Component | GTK2 | Qt5 | GTK4 | Notes |
| --- | --- | --- | --- | --- |
| `TToolWindow` | not registered | not registered | not registered | No standalone widgetset implementation in the reviewed paths. |
| `TToolBar` | registered | registered | registered | Implemented in `wscomctrls.pp`, not `wstoolwin.pp`. |
| `TCustomToolButton` | not registered | not registered | not registered | Tool buttons use LCL drawing/control behavior, not a direct widgetset class. |

Source references:

- GTK4 factory: `lcl/interfaces/gtk4/gtk4wsfactory.pas:203`, `lcl/interfaces/gtk4/gtk4wsfactory.pas:208`
- GTK2 factory: `lcl/interfaces/gtk2/gtk2wsfactory.pas:214`, `lcl/interfaces/gtk2/gtk2wsfactory.pas:220`
- Qt5 factory: `lcl/interfaces/qt5/qtwsfactory.pas:200`, `lcl/interfaces/qt5/qtwsfactory.pas:205`
- GTK4 toolbar widgetset class/create handle: `lcl/interfaces/gtk4/gtk4wscomctrls.pp:223`, `lcl/interfaces/gtk4/gtk4wscomctrls.pp:443`
- GTK2 toolbar widgetset class/create handle: `lcl/interfaces/gtk2/gtk2wscomctrls.pp:261`, `lcl/interfaces/gtk2/gtk2wscomctrls.pp:694`
- Qt5 toolbar widgetset class/create handle: `lcl/interfaces/qt5/qtwscomctrls.pp:250`, `lcl/interfaces/qt5/qtwscomctrls.pp:313`

#### 23.3 GTK4 Toolbar Relationship

GTK4's actual `TToolBar` path is `TGtk4WSToolBar.CreateHandle`, which creates a `TGtk4ToolBar`. The reviewed `TGtk4ToolBar.CreateWidget` deliberately keeps toolbar rendering in LCL rather than creating native GTK4 buttons at handle creation time. The source comment says this preserves dynamic `ImageList`-driven icon updates used by IDE toolbars/component palette.

Source references:

- `TGtk4ToolBar` declaration: `lcl/interfaces/gtk4/gtk4widgets.pas:554`
- `TGtk4ToolBar.CreateWidget`: `lcl/interfaces/gtk4/gtk4widgets.pas:6468`
- GTK4 toolbar paint-area/fixed child setup: `lcl/interfaces/gtk4/gtk4widgets.pas:6476`

Comparison notes:

- GTK2 creates a `gtk_hbox_new` plus fixed client widget for `TToolBar`, then attaches generic callbacks.
- Qt5's registered `TToolBar` widgetset class actually creates `TQtCustomControl`, not `TQtToolBar`, with a source note that the LCL `TToolBar` implementation is not a native toolbar-like `TWinControl` mapping.
- GTK4 follows the same broad practical model as GTK2/Qt5 for LCL `TToolBar`: a host/control surface for LCL-managed toolbar/button behavior, not a full native toolbar item model.

#### 23.4 Usability Judgment

| Feature group | GTK4 status | Reason |
| --- | --- | --- |
| standalone `TToolWindow` widgetset | `not_applicable` | No reviewed widgetset registers standalone `TToolWindow`; behavior is LCL-level. |
| edge/client rect behavior | `usable_with_limits` | Implemented in LCL `TToolWindow.Paint`/`AdjustClientRect`; actual rendering depends on `DrawEdge` support through the active canvas/theme path. |
| `TToolBar` registration through this inheritance chain | `usable_with_limits` | GTK4 registers `TToolBar` in `wscomctrls.pp` and creates `TGtk4ToolBar`; deeper toolbar behavior belongs to the `wscomctrls.pp` audit. |
| direct `TCustomToolButton` widgetset | `not_applicable` | GTK2/Qt5/GTK4 all return false for direct `TCustomToolButton` registration. |

#### 23.5 Focused Runtime Validation

No standalone runtime example was created for `wstoolwin.pp` because the file exposes no published backend methods and no reviewed widgetset registers standalone `TToolWindow`.

The practical runtime validation for this inheritance branch is attached to the toolbar review:

- Document: `PLAN_GTK4_TOOLBAR_VALIDATION.md`
- Example: `example_gtk4_toolbar_validation/`

That focused validation confirmed GTK4 `TToolBar` handle allocation, LCL-managed button bounds, initial painting, image-list replacement, caption/list mode changes, button sizing, disabled state storage, programmatic click/arrow events, constrained-width automatic wrapping in an independent non-`alTop` toolbar, real mouse delivery for normal/check tool buttons, default-paint normal/disabled/hot image pixels, basic dropdown popup open/close plus item activation, submenu page navigation plus mutated submenu item activation, menu mutation while the popup is open, and tested X11/Xvfb right/bottom/bottom-right edge placement. A later real Lazarus IDE run also confirmed component-palette page hit testing, component-button hit testing, design-time component insertion, source/form side effects, component-button popup, and page/control popup under GTK4 with a temporary `--pcp`; focused hint tests then confirmed GTK4 `THintWindow`, `TToolButton`, and standalone `TSpeedButton` hint display. A gdb follow-up showed the earlier palette hint miss was an automated Xvfb coordinate/top-level-target artifact: default coordinates resolved to `SynEdit1`, while moving Source Editor out of the toolbar area let the palette `TButton` hint reach `ActivateHintData` and appear as a top-level hint window. Main-toolbar hint absence remains an IDE mainbar hint-assignment/configuration topic. `RowCount=0` is now classified as an LCL-common semantic review item because GTK2 and Qt5 matched the GTK4 result in the same focused example.

Result:

- No missing GTK4-only standalone `TToolWindow` implementation was found relative to GTK2/Qt5.
- Toolbar behavior remains tracked under `wscomctrls.pp` / `PLAN_GTK4_TOOLBAR_VALIDATION.md`, not under `wstoolwin.pp`.

#### 23.6 Follow-up Tests

The `wstoolwin.pp` file itself does not expose backend-specific methods to test. Practical tests should be attached to the `wscomctrls.pp` toolbar review:

1. `TToolWindow` edge rendering/client rect when used through `TToolBar` and `TCoolBar`, including `EdgeBorders`, `EdgeInner`, and `EdgeOuter`.
2. `TToolBar` button layout, wrapping, image updates, disabled/hot image lists, separators, dropdown buttons, right-to-left alignment, vertical alignment, and `ShowCaptions`.
3. `TToolButton` click/check/dropdown behavior, including `Style = tbsButton`, `tbsCheck`, `tbsDropDown`, `tbsButtonDrop`, menu lifetime, and destruction during click handlers.

#### 23.7 `wstoolwin.pp` Scope Result

GTK4 is not missing a standalone `TToolWindow` implementation relative to GTK2 or Qt5 because none of the three reviewed widgetsets registers one. The meaningful comparison target is `TToolBar`/`TToolButton` under `wscomctrls.pp`, where GTK4 has a deliberate LCL-painted toolbar host similar in intent to GTK2/Qt5 rather than a complete native toolbar item implementation.

## Audit Completion Summary

The full source-level audit pass is complete for the baseline files under `lcl/widgetset`. This does not mean GTK4 is complete or bug-free. It means the initial work-scope discovery pass has enough direct source evidence to move from broad comparison to focused validation and implementation planning.

Highest-priority GTK4 follow-up areas identified by source review:

1. `TCustomScrollBar`: GTK4 value-change callback signature/source-object mismatch and `Max + PageSize` feedback risk.
2. `TCustomListView`: missing state images, `vsSmallIcon` image-list routing, geometry/scroll approximations, and ColumnView/GridView property gaps.
3. `TProgressBar`: vertical/topdown orientation getter/setter mismatch and unsupported/undocumented `Smooth`.
4. `TTrackBar`: equal min/max handling, vertical reversed semantics, tick mark density behavior, and recreate path for `SetTickStyle`.
5. `TMenu` / `TPopupMenu`: popup alignment, hover/select hints, and radio-group behavior.
6. `TEdit` / `TMemo` / standard controls: edit undo accuracy, text hint clearing, scrollbar delivery, default button behavior, shortcuts, and radio grouping.
7. `TCustomPairSplitter`: `RemoveSide`, `SetPosition` var-parameter semantics, and custom cursor behavior.
8. GTK4 core `TWinControl`: `DefaultWndHandler`, `AddControl` type safety, `ScrollBy` cast order, debug-build `SetBounds`, constraints, `PaintTo`, drag images, and shape limitations. (worked 2026-07-10: drag-image resolution registered, `ScrollBy` cast hardened, hidden-late-shown `PaintTo` fixed via live snapshot fallback; `DefaultWndHandler`/`AddControl` traced as non-defects; shape = backend limitation; constraints max-as-minimum coercion removed so Max no longer forces the window minimum, see §5 and `PLAN_GTK4_WSCONTROLS_VALIDATION.md`.)
9. Dialogs: file preview/history/help limitations from `GtkFileChooserNative`, font dialog option parity, and native dialog veto behavior. (worked 2026-07-10: Escape/close false-OK classification fixed and the `OnCanClose` veto stall fixed with a ShowModal-side wait loop + re-present; preview/history/help stay backend-limited, font apply/preview parity remains a documented follow-up. See §7 and `PLAN_GTK4_WSDIALOGS_VALIDATION.md`.)
10. Toolbar/component palette: LCL-painted GTK4 toolbar host behavior, dynamic image lists, dropdowns, IDE design-time hit testing/insertion, and component-palette hover hints are validated in focused/current X11 paths; main-toolbar hint assignment is an IDE-side follow-up if needed. (closed 2026-07-10: the last untested item — destruction during click handler — is confirmed safe with real X11 clicks for graphic-control AND windowed cases, with GTK2 parity throughout; Validation Run 13 in `PLAN_GTK4_TOOLBAR_VALIDATION.md`. One widgetset hardening came out of it: `TGtk4Widget.GtkEventMouse` now bails out via the live-widget registry if the `LM_*UP` delivery freed the wrapper, closing a by-construction dangling-Self window on the `LM_CONTEXTMENU`/`LM_CLICKED` path.)

Recommended next stage:

1. Select one component family from the priority list.
2. Create a dedicated `FIX_` or `PLAN_` document for that family.
3. Build focused examples under `example_gtk4_*`.
4. Compare GTK4 against GTK2/Qt5 at runtime before editing code.
5. Apply GTK4-only fixes only after the runtime evidence confirms the source-level diagnosis.

## GTK4 Binding Stub Hazard Registry (2026-07-10)

`lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas` is a hand-patched binding: many
GTK2/GTK3-era method wrappers were kept compiling by replacing their bodies
with silent stubs instead of removing them. These stubs do not warn at build
or run time, so a widgetset method can "call GTK" and appear implemented while
nothing (or the wrong thing) happens. Standing rule for all future GTK4 work:
**before trusting any `lazgtk4.pas` method wrapper, read its implementation
body**; when the installed GTK 4.6.9 ABI differs, add a correctly typed
`gtk4_*` external to `lazgtk4_compat.pas` and call that instead.

Sweep methodology: regex body scan of all `TGtk*.` method implementations,
classified as constant-result stubs (27), redirect stubs (17), and no-op
parameter-touch stubs (91), then cross-referenced against live callers under
`lcl/interfaces/gtk4` (excluding the bindings themselves).

Trap families found with live callers, and their dispositions:

| Binding stub | Kind | Disposition |
| --- | --- | --- |
| `TGtkRadioButton.join_group` | empty body | fixed — `gtk4_check_button_set_group` in `lazgtk4_compat.pas` (StdCtrls item) |
| `TGtkWidget.set_can_default` | redirect to `set_can_focus` | fixed — callers use `set_receives_default` (StdCtrls item) |
| `TGtkPaned.get_child1/get_child2` | constant `nil` | fixed — `gtk4_paned_get_start_child/get_end_child` (PairSplitter item) |
| `TGtkCalendar.select_day` | ABI mismatch (guint vs `GDateTime *`) → crash | fixed — `gtk4_calendar_select_day` + GDateTime wrapper rewrite |
| `TGtkCalendar.get_date` | ABI mismatch (4-arg call to 1-arg+return) → outputs never written | fixed — `gtk4_calendar_get_date` + GDateTime wrapper rewrite |
| `TGtkCalendar.select_month` | no-op | closed — GTK4 removed the API; `select_day` with a full `GDateTime` moves month/year (runtime-confirmed) |
| `TGtkWindow.set_icon` | no-op | documented `backend_limited` — GTK4 removed per-pixbuf window icons (`set_icon_name` themed lookup only). Caller comment added at `TGtk4Window.SetIcon`; optional X11 `_NET_WM_ICON` export noted as follow-up |

The fixed legacy wrappers keep ABI-TRAP warning comments in `lazgtk4.pas` so
they are not re-adopted by future code. Remaining stubs without live callers
are left as-is; any new caller must consult this registry first.

### Re-sweep verification (2026-07-11)

Re-ran the sweep against the current tree to confirm no new live caller of a
stub had been introduced since the registry was written. Method: scanned all
2971 `lazgtk4.pas` method bodies, flagged 360 whose every same-named
implementation is a no-op/constant stub, and cross-referenced non-comment
callers under `lcl/interfaces/gtk4` (excluding the bindings). Nine names had
apparent code callers; each was checked by hand and cleared:

- `get_child1`, `join_group` — matches are the registry's own documentation
  comments, not calls.
- `get_children` / `child_type` — only caller is `EnumerateChildren`, an
  uncalled DebugLn-only diagnostic (dead code).
- `set_allocation` — caller line is commented out (`…set_allocation(@ARect);}`).
- `get_has_alpha`, `get_monitor` — false positives from name collision: the
  live callers are `PGdkPixbuf^.get_has_alpha` and `PGdkDisplay^.get_monitor`,
  which resolve to the REAL bindings in `lazgdkpixbuf2.pas` / `lazgdk4.pas`, not
  the same-named `TGtkGLArea` / `TGtkMenu` stubs in `lazgtk4.pas`. (The sweep
  only scans `lazgtk4.pas`, so cross-unit real bindings must be checked too.)
- `get_skip_taskbar_hint`, `resize_children` — genuine stubs but intentional
  and self-documented (`taskbar hint is backend/compositor managed`,
  `layout is managed automatically`); GTK4 removed both APIs. Not hazards.

Result: no new hazards; the registry above remains accurate. No code change.
