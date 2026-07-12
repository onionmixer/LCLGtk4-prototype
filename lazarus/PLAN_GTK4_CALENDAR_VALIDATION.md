# PLAN: GTK4 Calendar Validation

## Rollback / Reference Point

- Rollback commit: `592e97e7d32b415946b84519dc7ed89520b3ef8e`
- Created: 2026-07-09
- Scope: `TCalendar` / `TCustomCalendar` under LCL GTK4
- Policy: no GTK4 implementation changes during this validation pass

## Source Findings To Validate

This plan follows `LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md`, section 2.

Primary source findings:

1. GTK4 registers `TCustomCalendar` and creates `TGtk4Calendar`.
2. GTK4 date get/set maps zero-based GTK months to one-based LCL months.
3. GTK4 `SetDisplaySettings` sets native boolean properties `show-heading`, `show-day-names`, and `show-week-numbers`.
4. GTK4 does not implement `dsNoMonthChange`.
5. GTK4 `SetFirstDayOfWeek` is an explicit no-op because `GtkCalendar` is locale-based in the reviewed code.
6. GTK4 `HitTest` uses `gtk4_widget_pick` and internal `GtkCalendar` child type/geometry heuristics.
7. GTK4 min/max dates are stored and the selected date is clamped; the native calendar does not disable out-of-range UI dates.

Important source references:

- Baseline widgetset methods: `lcl/widgetset/wscalendar.pp`
- LCL `TCustomCalendar`: `lcl/calendar.pp`
- GTK2 reference: `lcl/interfaces/gtk2/gtk2wscalendar.pp`
- Qt5 reference: `lcl/interfaces/qt5/qtwscalendar.pp`
- GTK4 implementation: `lcl/interfaces/gtk4/gtk4wscalendar.pp`
- GTK4 wrapper: `lcl/interfaces/gtk4/gtk4widgets.pas`

## Validation Questions

1. Does GTK4 build and run a focused Calendar example without exceptions?
2. Does date set/get round trip preserve the requested date?
3. Do `DisplaySettings` flags reach the native GTK4 boolean properties?
4. Does `dsNoMonthChange` have no native effect, as source review indicates?
5. Does `FirstDayOfWeek` have no observable native property path?
6. Does `HitTest` return meaningful parts for title/body/week-number coordinates?
7. Does min/max clamp the selected date when a programmatic out-of-range date is applied through the widget wrapper/LCL property paths?

## Focused Test Program

Created directory:

- `example_gtk4_calendar_validation/`

The example should:

- create a `TCalendar`;
- log LCL date, native GTK date, display properties, and LCL `GetCalendarView`;
- test several `DisplaySettings` combinations;
- test `HitTest` at representative title/body/week-number points;
- test `MinDate`/`MaxDate` clamp behavior;
- keep the window open for manual navigation and hit-test inspection when not in auto mode.

Runtime modes:

- default: opens a visual test window for manual inspection;
- `CALENDAR_VALIDATION_AUTO=1`: runs automated state checks and exits;
- `CALENDAR_VALIDATION_CLOSE_MS=<milliseconds>`: closes the manual window after the requested interval.

## Validation Run 1

- Date: 2026-07-09
- Build command: `./lazbuild --ws=gtk4 example_gtk4_calendar_validation/calendar_validation.lpi`
- Build result: succeeded.
- Auto run command: `xvfb-run -a env CALENDAR_VALIDATION_AUTO=1 ./example_gtk4_calendar_validation/calendar_validation`
- Auto run result: failed with `APPLICATION_EXCEPTION EAccessViolation: Access violation`.
- GDB command: `xvfb-run -a gdb -batch -ex run -ex bt --args ./example_gtk4_calendar_validation/calendar_validation`

Observed facts:

1. Creating/showing the focused `TCalendar` example fails before normal validation logs are emitted.
2. GTK emits `signal 'month-changed' is invalid for instance ... of type 'GtkCalendar'` during `TGtk4Calendar.CreateWidget`.
3. The crash stack is:
   - `g_date_time_get_ymd`
   - `g_date_time_get_year`
   - `g_date_time_get_day_of_month`
   - `gtk_calendar_select_day`
   - `TGtk4Calendar.SetDate` at `gtk4/gtk4widgets.pas:6129`
   - `TGtk4WSCustomCalendar.SetDateTime` at `gtk4/gtk4wscalendar.pp:205`
   - `TCustomCalendar.SetProps` at `calendar.pp:425`
   - `TCustomCalendar.InitializeWnd` at `calendar.pp:245`
4. Local GTK headers for GTK 4.6.9 show:
   - `gtk_calendar_select_day(GtkCalendar *self, GDateTime *date)`
   - `gtk_calendar_get_date(GtkCalendar *self): GDateTime *`
5. Current GTK4 Pascal bindings still declare the older GTK2/GTK3-style API:
   - `procedure get_date(year: Pguint; month: Pguint; day: Pguint)`
   - `procedure select_day(day: guint)`
   - `procedure select_month(month: guint; year: guint)`

Conclusion:

GTK4 `TCalendar` cannot be classified as usable on the current system. The current wrapper/binding calls do not match the installed GTK4 Calendar API and can crash during ordinary LCL handle initialization. Display settings, hit testing, min/max, and event delivery still need follow-up validation after the date API binding/wrapper path is corrected.

Additional public API note:

The initial example tried to clear limits by assigning `MinDate := 0` and `MaxDate := 0`; that is not a valid public LCL path because `TCustomCalendar.SetMinDate/SetMaxDate` call `CheckRange`, and `0` is below `SysUtils.MinDateTime`. `RemoveLimits` is private in `TCustomCalendar`, so remove-limits behavior cannot be directly driven from the public `TCalendar` API in this focused example.

## Implementation Fix (2026-07-10)

Scope: date-API ABI mismatch only (crash + garbage reads). Display settings,
first-day-of-week, hit-test refinement stay unchanged in this pass.

Changes:

1. `lcl/interfaces/gtk4/gtk4bindings/lazgtk4_compat.pas` — added correctly
   typed externals for the installed GTK 4.6.9 ABI:
   - `procedure gtk4_calendar_select_day(calendar: PGtkCalendar; date: PGDateTime)`
   - `function gtk4_calendar_get_date(calendar: PGtkCalendar): PGDateTime`
2. `lcl/interfaces/gtk4/gtk4widgets.pas` — `TGtk4Calendar.GetDate/SetDate`
   rewritten on GDateTime (`g_date_time_new_local` / `get_year` /
   `get_month` / `get_day_of_month` / `unref`). The wrapper keeps its
   ZERO-BASED month contract; `gtk4wscalendar.pp` continues to apply
   `Month±1` (SetDate line ~205, GetDateTime line ~80).
3. `lcl/interfaces/gtk4/gtk4widgets.pas` `TGtk4Calendar.CreateWidget` —
   removed the `'month-changed'` signal connect: GTK4 `GtkCalendar` has no
   such signal (GTK3 leftover; it only produced the GLib "signal is invalid"
   warning). Month/year change delivery switched from the
   `prev/next-month/year` signals to `notify::month` / `notify::year`:
   codex review + GTK 4.6.9 source (`gtkcalendar.c`) showed the arrow
   signals fire ONLY for the header arrow buttons, while every month/year
   change (arrows, adjacent-month day cells, DnD, programmatic
   `select_day`) funnels through `gtk_calendar_select_day`, which emits the
   property notifications. Runtime-confirmed: a programmatic cross-month
   date set now delivers `LM_DAYCHANGED` + `LM_MONTHCHANGED` (previously
   day only).
4. `lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas` — legacy
   `TGtkCalendar.get_date/select_day` wrappers AND their raw
   `gtk_calendar_get_date/select_day` external declarations marked with
   ABI-TRAP warning comments (no remaining callers; `select_month` was
   already a documented no-op stub).

### Validation Run 2 (post-fix, 2026-07-10)

- Build: `make lcl LCL_PLATFORM=gtk4` — 0 errors; gtk2 regression build — 0
  errors; `make bigide LCL_PLATFORM=gtk4` — 0 errors, fresh binary.
- Auto run: `xvfb-run -a env CALENDAR_VALIDATION_AUTO=1 GTK_IM_MODULE=gtk-im-context-simple ./example_gtk4_calendar_validation/calendar_validation`
- Codex adversarial review: memory management confirmed correct
  (`select_day` is transfer-none and refs internally; `get_date` is
  transfer-full and is unrefed on the non-nil path); zero-based month
  contract confirmed against `gtk4wscalendar.pp:205/:80`; one Medium
  finding (month-change signal coverage) verified against GTK source and
  fixed via the `notify::month/year` switch above; one Low finding (raw
  external declarations lacked trap warnings) fixed with comments.
- Result: no `EAccessViolation`, no invalid-signal warning. Observed:
  - round trip: `lcl.date=2026-07-09 native.date=2026-07-09` after show;
  - date change: `after-date-2026-12-25 lcl.date=2026-12-25 native.date=2026-12-25` (month AND year moved — select_day via GDateTime covers select_month's job);
  - display settings reach native `show-heading/day-names/week-numbers` (`display=none` → all False);
  - `dsNoMonthChange` confirmed no native effect (finding 4 upheld);
  - `firstday` log reflects locale only (finding 5 upheld);
  - hit-test returns `cpTitleMonth/cpTitle/cpTitleYear/cpDate` at expected points, `cpNoWhere` when headings hidden;
  - min/max clamp: `after-minmax-2026-07-10-20 lcl.date=2026-07-20`, and out-of-range set raises LCL-side `EInvalidDate` (native stays clamped).

Remaining (deferred to final real-hardware round): manual navigation feel,
week-number hit points, GTK2/Qt5 side-by-side comparison.

## Clean Build Requirement

After any future GTK4 implementation change:

1. Build the focused example with `./lazbuild --ws=gtk4`.
2. Run auto mode under `xvfb-run`.
3. Run manually and inspect navigation buttons, day cells, week numbers, first-day-of-week behavior, and min/max date navigation.
4. If practical, run the same example under GTK2 and Qt5 for display settings and first-day/min-max comparison.
5. Before those runtime checks, correct or regenerate the GTK4 Calendar binding/wrapper date API usage for the installed GTK4 API and verify that `TCalendar` creation no longer crashes.

## Do Not Change Yet

- Do not edit `lcl/interfaces/gtk4` during this validation pass.
- Do not assume `HitTest` is correct without runtime points because it depends on GTK4 internal widget layout.
- Do not classify `FirstDayOfWeek` as implemented unless a native or fallback behavior is observed.
- Do not continue Calendar behavior classification from source review alone while the date API mismatch still crashes handle initialization.
