# GTK4 No-Stubs Migration Plan

> ## ✅ STATUS: COMPLETE (verified 2026-07-11)
>
> This plan is done; kept for history. Verified state:
> - **C-level `gtk3_stubs.c` / `{$L gtk3_stubs.o}`** — already removed from the
>   LCL GTK4 backend in Sessions 32 (`225b2f4`) and 35b (`82a0eba`). The LCL
>   `lcl/interfaces/gtk4/` tree has zero `gtk3_stubs` references and no `{$L}`
>   object-link directive; clean `make bigide` builds link with no undefined
>   symbols. The `gtk4test/gtk3_stubs.c/.o` files are orphaned artifacts of a
>   standalone test project (referenced by nothing) and can be deleted.
> - **Pascal binding-stub hygiene** — the GTK4 Binding Stub Hazard Registry in
>   `lazarus/LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md` (2026-07-10) catalogued all
>   135 stubs and fixed every one with a live caller. A re-sweep on 2026-07-11
>   (recorded in that doc) confirmed no new stub caller was introduced; the
>   remaining caller-less stubs are intentional/self-documented.
> - The "Icon/Modal Stability" sprint below is done — IDE toolbar/palette icons
>   render correctly (user-confirmed).
>
> The historical plan text follows unchanged.

## Goal
Remove `lazarus/lcl/interfaces/gtk4/gtk3_stubs.c` and `{$L gtk3_stubs.o}` from the GTK4 backend, replacing all remaining GTK3-era symbol dependencies with real GTK4 implementations or explicit dead-code removal.

## Current Sprint (Icon/Modal Stability in Pure GTK4)
- Constraint: do not modify Lazarus IDE sources; fix in `lcl/interfaces/gtk4` only.
- Target symptoms:
  - toolbar/component-palette/menu-window icons intermittently not visible
  - modal close/cleanup path regressions after About dialog interactions
- Plan of action:
1. Remove GTK3/GTK4 type-assumption paths that trigger runtime criticals.
2. Use GTK4-native widget APIs in icon attach paths (`GtkMenuButton` child handling).
3. Stabilize bitmap->pixbuf ownership semantics to avoid borrowed-handle lifetime issues.
4. Rebuild GTK4 IDE target and verify with fresh runtime log (`error_56.log+`).
5. Only then continue no-stubs symbol reduction to keep regressions isolated.

### Sprint Progress
- [x] Replaced toolbar dropdown icon attach from `gtk_button_set_child` cast path to `GtkMenuButton.set_child`.
- [x] Added missing GTK4 binding entries for `gtk_menu_button_get_child/set_child`.
- [x] Hardened `Gtk4BitmapToPixbuf` handle path to return ref-counted pixbuf.
- [x] Rebuilt `make ide LCL_PLATFORM=gtk4` successfully after changes.
- [ ] Validate runtime result with new user test log and continue remaining icon paths if needed.

## Scope
- Target tree: `lazarus/lcl/interfaces/gtk4/`
- Main removal targets:
  - `lazarus/lcl/interfaces/gtk4/gtk3_stubs.c`
  - `lazarus/lcl/interfaces/gtk4/gtk4int.pas:24` (`{$L gtk3_stubs.o}`)
- Validation targets:
  - IDE startup/shutdown
  - Main menu behavior
  - toolbar/icon rendering
  - About modal/image rendering
  - core dialogs (`Open/Save/Color/Font`)

## Local Context Incorporated
- `lazarus/lcl/interfaces/gtk4/README.txt` still contains legacy TODO/problem notes (GTK3 wording remains), confirming backend is transitional.
- GTK4 backend currently mixes:
  - GTK4-specific compat wrappers (`lazgtk4_compat.pas`)
  - GTK3-derived bindings (`gtk4bindings/lazgtk4.pas`)
  - link-time no-op stubs (`gtk3_stubs.c`)
- Existing code comments explicitly mention stubs are temporary until bindings are fully GTK4-clean.

## Execution Strategy
1. Inventory every stub symbol and where it is referenced.
2. Prioritize non-binding runtime call sites first (actual behavior risk).
3. Then clean binding layer usage paths (declarations/wrappers still pointing to removed GTK3 APIs).
4. Replace with GTK4 APIs or remove unreachable code.
5. Delete stubs and re-run build + smoke scenarios.

## Detailed Work Plan

### Phase 0: Baseline & Guardrails
- Capture baseline logs/screens:
  - `report_02.png` (qt5), `report_03.png` (gtk4)
  - `error_*.log` known warnings
- Define acceptance gates:
  - No link dependency on `gtk3_stubs.o`
  - No unresolved GTK3-only symbols at link
  - No regression in startup/menu/dialog scenarios

### Phase 1: Symbol Census (Stub Side)
- Parse all functions from `gtk3_stubs.c`.
- Produce canonical symbol list and count.
- Output artifact:
  - `output/gtk4_stub_audit/stub_symbols.txt`

### Phase 2: Reference Mapping (Consumer Side)
- For each stub symbol, map:
  - binding references (`gtk4bindings/*`)
  - non-binding references (`gtk4ws*`, `gtk4widgets.pas`, `gtk4*.inc`, etc.)
- Distinguish likely real call paths using `symbol(` pattern.
- Output artifacts:
  - `output/gtk4_stub_audit/stub_symbol_call_counts.tsv`
  - `output/gtk4_stub_audit/nonbinding_call_refs_tagged.tsv`
  - `output/gtk4_stub_audit/summary_calls.txt`

### Phase 3: Triage & Prioritization
- Classify each non-binding reference:
  - `P0` runtime-critical (executed on normal IDE paths)
  - `P1` feature-specific
  - `P2` dead/legacy/commented
- Map each to one action:
  - replace with GTK4 API
  - remove legacy code path
  - keep as TODO with isolation if unreachable

### Phase 4: Runtime Path Replacement (Non-Binding First)
- Fix non-binding call sites in this order:
1. menu/dialog/widget lifecycle APIs
2. image/icon APIs (`gtk_button_set_image`, old pixbuf/menu paths)
3. window/screen/visual APIs (`gdk_window_*`, `gdk_screen_*`)
4. calendar/file dialog leftovers
- Add targeted debug logs where needed to verify path execution.

### Phase 5: Binding Layer Cleanup
- Audit `gtk4bindings/lazgtk4.pas` for GTK3-only exports still consumed.
- Move necessary corrected declarations to `lazgtk4_compat.pas` (GTK4 signatures only).
- Remove or stop using wrappers that rely on non-existent GTK4 symbols.

### Phase 6: Stub Detach
- Remove `{$L gtk3_stubs.o}` from `gtk4int.pas`.
- Exclude `gtk3_stubs.c` from build and delete file.
- Rebuild GTK4 interface and confirm link succeeds without fallback stubs.

### Phase 7: Verification & Regression Pass
- Smoke run scenarios:
  - IDE start/exit
  - menu open/shortcuts
  - toolbar/icon visibility
  - About modal logo/image
  - standard dialogs
- Compare warnings against baseline and note deltas.

### Phase 8: Hardening
- Add CI grep/check step to prevent reintroduction of:
  - `{$L gtk3_stubs.o}`
  - `gtk3_stubs.c`
- Add check for direct GTK3-only symbol use in GTK4 backend.

## Current Status
- [x] Plan established and localized to current repository state.
- [x] Phase 1 started.
- [x] Phase 2 started (initial audit artifacts generated).
- [x] Phase 2 non-binding call candidates eliminated (14 -> 0 in non-binding scan).
- [x] Phase 3 triage started with no-stubs link audit.
- [ ] Phase 4 implementation.
- [ ] Phase 5 binding cleanup.
- [ ] Phase 6 stub removal.
- [ ] Phase 7 verification.
- [ ] Phase 8 hardening.

## Phase 2 Initial Findings (Started)
- Stub symbol count: `1331` (`output/gtk4_stub_audit/stub_symbols.txt`)
- Symbols with non-binding call refs: `14` (`output/gtk4_stub_audit/summary_calls.txt`)
- Initial non-binding candidates:
  - `gtk_menu_get_active`
  - `gtk_color_selection_get_current_rgba`
  - `gtk_file_chooser_set_show_hidden`
  - `gtk_file_chooser_set_do_overwrite_confirmation`
  - `gtk_widget_get_style`
  - `gtk_calendar_get_display_options`
  - `gdk_window_set_events`
  - `gdk_window_get_events`
  - `gtk_button_set_image`
  - `gtk_widget_destroy`
  - `gdk_keymap_get_modifier_mask`
  - `gdk_window_get_visual`
  - `gdk_screen_get_root_window`
  - `gtk_window_set_keep_above`

## Next Immediate Actions
1. Freeze current non-binding audit baseline (`0` candidates) and keep it as regression gate.
2. Move to binding-layer cleanup (GTK3-era declarations still present in `gtk4bindings/*`).
3. Prepare `{$L gtk3_stubs.o}` detachment patch and validate link/build.

## Phase 3 Deep Findings (No-Stubs Link Audit)
- Artifacts:
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols.count`
  - `output/gtk4_stub_audit/no_stubs_undefined_categories.count`
- Current `-dGTK4_NO_STUBS` build unresolved symbols: `1331`
  - after initial runtime cuts: `1330` (`gtk_false` dependency removed)
  - after `TGtkPaned.add1/add2` GTK4 remap: `1328` (`gtk_paned_add1/2` removed)
  - after widget lifecycle/allocation cuts: `1325` (`gtk_widget_destroy/is_toplevel/set_allocation` removed)
  - after entry/adjustment/calendar cuts: `1320`
  - after container/misc/frame/radio/window(부분) cuts: `1304`
  - after gdk visual/display/cursor/window/drag/keymap partial cuts: `1281`
  - after gdk window/seat additional cuts: `1226`
  - after gdk window getter/state large cuts: `1143`
  - after display/screen/cursor/device legacy wrapper cuts: `1027`
  - after toolpalette/toolbar/treeview/viewport/textview/toolshell/toolitemgroup cuts: `880`
  - after `gtk4winapi.inc` `gdk_pango_context_get` 제거: `879`
- Top buckets:
  - `gtk_widget` (`125`)
  - `gtk_window` (`63`)
  - `gtk_container` (`31`)
  - `gtk_entry` (`19`)
  - `gtk_color_selection` (`19`)
  - `gdk_keymap` (`14`)
  - `gdk_visual` (`10`)
  - `gtk_radio_button` (`9`)
  - `gtk_calendar` (`8`)
  - `gtk_paned` (`7`)
- Interpretation:
  - Main blocker is not only runtime call-sites.
  - `gtk4bindings/lazgtk4.pas` and `gtk4bindings/lazgdk4.pas` still emit many GTK3-era external symbol references, so link fails even before runtime verification.

## Phase 4 Started (Targeted Runtime/Callsite Cuts)
- Applied GTK4-native replacements that directly reduced legacy dependency surface:
  - `gtk4private.pas`: replaced `gtk_false` timer return with `False`.
  - `gtk4widgets.pas`: migrated `TGtk4ColorSelectionDialog.InitializeWidget` from `GtkColorSelectionDialog` to `GtkColorChooserDialog`.
  - `gtk4bindings/lazgtk4.pas`: remapped `gtk_paned_add1/add2` declarations to GTK4
    `gtk_paned_set_start_child/end_child`.
  - `gtk4bindings/lazgtk4.pas`: made `TGtkWidget.destroy_` use `gtk_widget_unparent`,
    made `is_toplevel` conservative (`False`), and turned `set_allocation` into GTK4-safe no-op.
  - `gtk4bindings/lazgtk4.pas`: neutralized legacy Entry/Adjustment/Calendar wrapper calls
    (`set_width_chars`, `set_max_width_chars`, `changed`, `select_month`, `set_display_options`).
  - `gtk4bindings/lazgtk4.pas`: neutralized legacy container and window/widget/radio/misc/frame wrappers.
  - `gtk4bindings/lazgdk4.pas`: neutralized high-impact legacy visual/display/cursor/window/drag/keymap wrappers.
  - `gtk4objects.pas`: replaced `gdk_pango_context_get` usage with `pango_context_new`.
  - `gtk4widgets.pas` / `gtk4wsforms.pp`: replaced direct `set_allocation` usage with size-request path.
  - Verified via rebuild log: `/tmp/gtk4test_build_no_stubs_after.log`
  - Re-verified after paned remap: `/tmp/gtk4test_build_no_stubs_after2.log`
  - Re-verified after widget allocation/lifecycle cuts: `/tmp/gtk4test_build_no_stubs_after3.log`
  - Re-verified after entry/adjustment/calendar cuts: `/tmp/gtk4test_build_no_stubs_after6.log`
  - Re-verified after container/misc/frame/radio/window cuts: `/tmp/gtk4test_build_no_stubs_after8.log`
  - Re-verified after gdk partial cuts: `/tmp/gtk4test_build_no_stubs_after9b.log`, `/tmp/gtk4test_build_no_stubs_after10b.log`

## Current Remaining Blockers
- Main unresolved cluster is now concentrated in additional legacy `gdk_window_*`,
  `gdk_seat_*`, `gdk_device_manager_*`, `gdk_monitor_is_primary` wrappers still emitted by
  `gtk4bindings/lazgdk4.pas`.
- Remaining dominant block is still `gtk4bindings/lazgdk4.pas` `TGdkWindow` legacy methods
  (create/draw/geometry/device getters and window-state controls). Next batch should neutralize
  the rest of `TGdkWindow` wrapper bodies in one pass.
- Current dominant unresolved buckets moved to broad GTK3-only wrapper sets in
  `gtk4bindings/lazgtk4.pas`: `gtk_accel_*`, `gtk_clipboard_*`, `gtk_container/box/button*`,
  `gtk_recent_*`, `gtk_socket_*`, `gtk_text_*`, and related accessibility/tooling APIs.
- Latest verification logs:
  - `/tmp/gtk4test_build_no_stubs_after17.log`
  - `/tmp/gtk4test_build_no_stubs_after18.log`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after17.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after18.txt`

## Updated Priority for Phase 5
1. Reduce direct GTK3 symbol imports in `gtk4bindings/lazgtk4.pas`/`gtk4bindings/lazgdk4.pas` by replacing high-impact methods with `LazGtk4_Compat` equivalents.
2. Isolate/remove legacy wrapper methods that force unresolved external references when `GTK4_NO_STUBS` is enabled.
3. Rebuild with `-dGTK4_NO_STUBS` after each batch and track unresolved count delta.

## GTK4 종료(cleanup) 상세 비교 분석 (GTK2/QT5 참조)

### 관찰 대상
- 재현 로그: `error_46.log`, `error_47.log`
- 공통 증상:
  - 기능은 정상(About/modal/menu/종료)
  - 종료 시 `gtk_stack_remove` 경고 14회 고정
  - `error_46.log`: 14회, `error_47.log`: 14회 (변화 없음)

### 코드 비교 핵심

1. GTK2 경로 (DestroyHandle 주도형)
- `TGtk2WSCustomTabControl`는 `RemovePage` override가 없음
  - 선언부: `lazarus/lcl/interfaces/gtk2/gtk2wscomctrls.pp:84`
  - 구현은 `AddPage/MovePage`만 존재: `lazarus/lcl/interfaces/gtk2/gtk2pagecontrol.inc:345`, `lazarus/lcl/interfaces/gtk2/gtk2pagecontrol.inc:436`
- 실제 파괴는 공통 destroy 파이프라인이 책임:
  - `TGtk2WSWinControl.DestroyHandle -> Gtk2WidgetSet.DestroyLCLComponent`
  - `lazarus/lcl/interfaces/gtk2/gtk2wscontrols.pp:571`
  - 내부 순서: callbacks 해제 -> destroy flag -> widget destroy
  - `lazarus/lcl/interfaces/gtk2/gtk2widgetset.inc:4873`, `lazarus/lcl/interfaces/gtk2/gtk2widgetset.inc:4951`

2. QT5 경로 (정리 순서/업데이트 경계 명시형)
- 기본 생명주기:
  - `DeInitializeWidget: RemoveHandle -> DetachEvents -> DestroyWidget`
  - `lazarus/lcl/interfaces/qt5/qtwidgets.pas:2279`
- 탭 위젯은 hook를 명시 해제:
  - `TQtTabWidget.DetachEvents`
  - `lazarus/lcl/interfaces/qt5/qtwidgets.pas:11136`
- 페이지 destroy는 parent 업데이트 경계를 둠:
  - `TQtWSCustomPage.DestroyHandle`에서 `Parent.BeginUpdate/EndUpdate` + page release
  - `lazarus/lcl/interfaces/qt5/qtpagecontrol.inc:50`
- 탭 제거는 `removeTab` 1회 호출, 이후 page handle release는 별도 단계
  - `lazarus/lcl/interfaces/qt5/qtpagecontrol.inc:303`

3. GTK4 현재 경로 (혼합형, 불일치 지점 존재)
- 탭 제거 WS 구현 존재:
  - `TGtk4WSCustomTabControl.RemovePage`
  - `lazarus/lcl/interfaces/gtk4/gtk4wscomctrls.pp:1554`
- 노트북 제거도 수행:
  - `TGtk4NoteBook.RemovePage`
  - `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:5598`
- 페이지 destroy는 parent가 notebook일 때만 `FOwnWidget := False` 처리
  - `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas:5216`
- 페이지 WS destroy override가 없고, `TGtk4WSWinControl.DestroyHandle`는 즉시 `Free`
  - `lazarus/lcl/interfaces/gtk4/gtk4wscontrols.pp:166`
  - `TGtk4WSCustomPage.DestroyHandle` 미구현 상태
    (`gtk4wscomctrls.pp` 선언부에서 override 없음)

### 원인 가설 (확률순)
1. `RemovePage` + `DestroyHandle(Free)`가 teardown 중첩으로 동일 child를 두 번 remove 시도.
2. `TGtk4Page.DestroyWidget`의 notebook-parent 판정이 GTK4 내부 parent 구조(GtkStack 경유)에서 누락되어 일부 page가 직접 destroy 경로로 진입.
3. QT5처럼 page 파괴 시 parent 업데이트 경계(Begin/EndUpdate)가 없어 종료 시점 re-entrancy를 허용.

## GTK4 종료 개선 계획 (IDE 코드 미수정)

### Step A: 경로 계측(Instrumentation)으로 원인 확정
- 목적: `gtk_stack_remove` 14회가 어느 경로(WS RemovePage vs page DestroyWidget vs notebook destroy)에서 발생하는지 식별.
- 방법:
  - `TGtk4WSCustomTabControl.RemovePage` 진입/스킵 사유 로그 추가
  - `TGtk4NoteBook.RemovePage`에서 child ptr, parent type, page_num 로그 추가
  - `TGtk4Page.DestroyWidget`에서 `FWidget parent g_type_name` 로그 추가
- 완료 조건:
  - 경고 1건당 선행 코드 경로를 대응시킬 수 있어야 함.

### Step B: 소유권 모델 정리 (GTK2/QT5 참고)
- 원칙:
  - teardown 시 child 분리는 한 경로만 담당 (single owner rule)
  - remove/destroy 동시 수행 금지
- 후보 정책:
  1) GTK2형: WS `RemovePage`를 teardown 상황에서는 no-op화하고 `DestroyHandle` 주도로 일원화
  2) QT5형: page destroy에 parent update 경계 도입(`BeginUpdate/EndUpdate` 유사)

### Step C: `TGtk4WSCustomPage.DestroyHandle` 명시 구현
- QT5 `TQtWSCustomPage.DestroyHandle` 패턴 반영:
  - parent notebook handle 존재 시 업데이트 경계 진입
  - page release 수행
  - 경계 종료
- 기대효과:
  - page 파괴 중 tab/notebook side-effect 이벤트 억제

### Step D: page destroy parent 판정 강화
- 현재: parent가 notebook일 때만 `FOwnWidget := False`
- 보강:
  - GTK4 notebook 내부 parent chain(예: GtkStack)까지 확인
  - notebook 소유 child면 직접 destroy 금지

### Step E: 검증 기준
- 기능 회귀 없음:
  - splash / about / menu click / menu 종료 정상
- 로그 기준:
  - `gtk_stack_remove` 14 -> 0(목표), 최소 유의미 감소
  - 기존 해소 항목 재발 금지:
    - `g_object_set_data` invalid object
    - `g_signal_handlers_disconnect_matched` invalid instance
    - `gtk_window_is_active` invalid object

## Phase 5 Progress Update (after18 -> after34)
- Build command baseline kept fixed (`gtk4test/ppcx64 ... -dGTK4_NO_STUBS`).
- Unresolved unique symbol trend:
  - `after24`: `690`
  - `after27`: `589`
  - `after28`: `550`
  - `after31`: `511`
  - `after32`: `472`
  - `after33`: `433`
  - `after34`: `408`
- Major completed cleanup batches:
  - `TGtkImageMenuItem`, `TGtkInfoBar`, `TGtkInvisible`, `TGtkLayout` legacy wrappers removed from active calls.
  - `TGtkIconInfo`/`TGtkIconTheme` GTK3-only loaders and scale/screen APIs neutralized.
  - `TGtkStyleContext` removed remaining GTK3-only screen/path/junction/frame-clock legacy calls.
  - `TGtkPaned`, `TGtkHSV`, `TGtkRange` legacy-only methods neutralized.
  - `TGtkFileChooser*`, `TGtkFileFilter`, `TGtkFileChooserButton`, `TGtkFontButton`, `TGtkGLArea`, `TGtkGesture*` partial legacy sets neutralized.
  - `TGtkTargetList`, `TGtkEventBox`, `TGtkEventController.handle_event`, `TGtkIMContext.set_client_window`, `TGtkExpander.label_fill` legacy calls neutralized.
  - `TGtkStyleProvider`/`TGtkCssProvider.get_named`/`TGtkCssSection` partial legacy getters neutralized.
- Remaining dominant blockers as of `after34`:
  - `TGtkWidgetPath*` legacy methods.
  - `TGtkContainerCellAccessible*` legacy methods.
  - `TGtkEntry*` legacy GTK3 symbols (`gtk_entry_get_text`, `gtk_entry_set_text`, icon pixbuf/layout/hadjustment APIs, etc.).
- Verification artifacts:
  - `/tmp/gtk4test_build_no_stubs_after27.log` ... `/tmp/gtk4test_build_no_stubs_after34.log`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after27.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after28.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after29.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after31.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after32.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after33.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after34.txt`
- `after35/36/37/38/39/40` progression:
  - `after36`: `379`
  - `after37`: `339`
  - `after38`: `310`
  - `after39`: `286`
  - `after40`: `271`
- Latest dominant unresolved clusters (`after40`):
  - `TGtkCellAccessibleParent*`
  - `TGtkCellRenderer/TGtkCellArea/TGtkCellView*`
  - `TGtkToggleButton` legacy inconsistent/mode accessors

## Phase 5 Progress Update (after51 -> after55)
- Unresolved unique symbol trend:
  - `after52`: `166`
  - `after53`: `160`
  - `after54`: `143`
  - `after55`: `121`
- This batch completed:
  - `TGtkBox`: disabled legacy `reorder_child`, `set_center_widget`, `set_child_packing`, `get_center_widget`, `pack_*`, `query_child_packing`.
  - `TGtkMenuShell`: disabled legacy `activate_item`, `append`, `bind_model`.
  - `TGtkBuildable`: disabled GTK3-only builder hook wrappers.
  - `TGtkBin` / `TGtkAccessible`: replaced legacy wrappers with safe defaults.
  - `TGtkDialog` / `TGtkLabel` / `TGtkComboBox`: disabled GTK3-only wrapper calls (`run`, old wrap/title/span APIs, etc.).
- Verification artifacts:
  - `/tmp/gtk4test_build_no_stubs_after53.log`
  - `/tmp/gtk4test_build_no_stubs_after54.log`
  - `/tmp/gtk4test_build_no_stubs_after55.log`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after53.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after54.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after55.txt`
- Dominant remaining clusters as of `after55`:
  - `gtk_drag_*` source/dest APIs.
  - `gtk_container_class_*` child-property helpers.
  - Broad legacy `gtk_widget_*` compatibility calls.

## Phase 5 Progress Update (after56 -> after60)
- Unresolved unique symbol trend:
  - `after56`: `90`
  - `after57`: `0` (link 단계 심볼 기준)
  - `after58`: `0` (컴파일 타입 교정 필요)
  - `after59`: `1` (`gtk_widget_ensure_style`)
  - `after60`: `0` (`-dGTK4_NO_STUBS` 빌드 성공, RC=0)
- This batch completed:
  - `TGtkWidget`의 legacy `drag_*`, `grab_*`, 다수 `widget_*` 래퍼를 no-op/default로 전환.
  - `TGtkContainerClass` child-property legacy 래퍼 제거.
  - `TGtkWidgetClass` legacy style/accessibility/connect 래퍼 중 GTK3 의존 호출 제거.
  - `TGtkWindow.get_default_icon_list` 등 남은 GTK3 의존 getter를 안전 기본값으로 교체.
  - 타입 보정(`Boolean32`, pointer, set type) 및 마지막 `ensure_style` 잔여 심볼 정리.
- Verification artifacts:
  - `/tmp/gtk4test_build_no_stubs_after56.log`
  - `/tmp/gtk4test_build_no_stubs_after57.log`
  - `/tmp/gtk4test_build_no_stubs_after58.log`
  - `/tmp/gtk4test_build_no_stubs_after59.log`
  - `/tmp/gtk4test_build_no_stubs_after60.log`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after56.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after57.txt`
  - `output/gtk4_stub_audit/no_stubs_undefined_symbols_after60.txt`

## Phase 6: No-op to GTK4 Fallback Remap (started)
- Objective:
  - Replace selected no-op compatibility wrappers with closest GTK4-native behavior where safe.
- Completed remap batch A:
  - `TGtkWidget.grab_default` -> `gtk_widget_grab_focus`.
  - `TGtkWidget.queue_draw_area`/`queue_draw_region` -> `gtk_widget_queue_draw`.
  - `TGtkWidget.queue_resize_no_redraw` -> `gtk_widget_queue_resize`.
  - `TGtkWidget.set_margin_left/right` -> `gtk_widget_set_margin_start/end`.
  - `TGtkWidget.show_all`/`show_now` -> `gtk_widget_show`.
- Completed remap batch B:
  - `TGtkWidget.has_grab` -> `gtk_widget_has_focus` fallback.
  - `TGtkWidget.has_screen` -> `gtk_widget_get_display(@self) <> nil` fallback.
  - `TGtkWidget.hide_on_delete` -> `gtk_widget_hide` + `True`.
  - `TGtkWidget.queue_compute_expand` -> `gtk_widget_queue_allocate`.
- Verification:
  - `/tmp/gtk4test_build_no_stubs_after61.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after62.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after63.log` (RC=0)
- Completed remap batch C:
  - `TGtkWidget.get_toplevel` -> parent-chain traversal fallback.
  - `TGtkWidget.is_toplevel` -> `gtk_widget_get_parent(@self) = nil`.
- Completed remap batch D:
  - `TGtkWidget.get_no_show_all`/`set_no_show_all` -> visibility 기반 fallback.
  - `TGtkWidget.get_has_window` -> `gtk_widget_get_realized` fallback.
  - `TGtkWidget.intersect` -> allocation 기반 수동 교집합 계산.
- Completed remap batch E:
  - `TGtkWidget.set_mapped` -> `gtk_widget_set_visible`.
  - `TGtkWidget.set_realized` -> `gtk_widget_realize/unrealize`.
  - `TGtkWidget.set_redraw_on_allocate` -> redraw 요청 fallback.
  - `TGtkWidget.size_allocate_with_baseline` -> `gtk_widget_size_allocate`.
- Verification:
  - `/tmp/gtk4test_build_no_stubs_after64.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after65.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after66.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after67.log` (RC=0)
- Completed remap batch F:
  - `TGtkWidget.child_notify` -> `g_object_notify`.
  - `TGtkWidget.freeze_child_notify`/`thaw_child_notify` -> `g_object_freeze_notify`/`g_object_thaw_notify`.
  - `TGtkWidget.destroyed` -> widget pointer nil-out compatibility behavior.
  - `TGtkWidget.draw` -> redraw request fallback.
  - `TGtkContainer.child_get_property` -> `g_object_get_property`.
  - `TGtkContainer.child_notify`/`child_notify_by_pspec` -> `g_object_notify*`.
- Completed remap batch G:
  - Added GTK4 `gtk_widget_measure` binding and migrated:
    - `TGtkWidget.get_preferred_height*`
    - `TGtkWidget.get_preferred_width*`
  - `TGtkWidget.get_allocated_size` restored via `get_allocation + get_allocated_baseline`.
  - `TGtkWidget.get_clip` restored with allocation-based fallback.
- Completed remap batch H:
  - Added GTK4 `gtk_box_append/prepend` bindings.
  - `TGtkBox.pack_end` -> `gtk_box_append`.
  - `TGtkBox.pack_start` -> `gtk_box_prepend`.
- Verification:
  - `/tmp/gtk4test_build_no_stubs_after68.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after69.log` (RC=0)
- `lazgtk4.pas` residual `Not supported in GTK4.` markers: `245`.

## Phase 6 Progress Update (continued)
- Completed remap batch I:
  - Added GTK4 `gtk_label_get_wrap/get_wrap_mode/set_wrap/set_wrap_mode` bindings.
  - `TGtkLabel.get_line_wrap/get_line_wrap_mode` now use GTK4 wrap APIs.
  - `TGtkLabel.set_line_wrap/set_line_wrap_mode` now use GTK4 wrap APIs.
- Completed remap batch J:
  - `TGtkWidget.get_allocated_size` restored via allocation/baseline path.
  - `TGtkWidget.get_clip` restored with allocation-based fallback.
  - Added GTK4 `gtk_widget_measure` binding and migrated `get_preferred_*` wrappers.
  - `TGtkWidget.reset_style` -> redraw fallback.
  - `TGtkWidget.set_app_paintable` -> redraw fallback.
  - `TGtkWidget.style_get_property` -> `g_object_get_property`.
- Verification:
  - `/tmp/gtk4test_build_no_stubs_after70.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after71.log` (RC=0)
- `lazgtk4.pas` residual `Not supported in GTK4.` markers: `240`.

## Phase 6 Progress Update (menu/check item fallback)
- Completed remap batch K:
  - `TGtkMenuShell` partial fallback behavior:
    - `activate_item`, `append/insert/prepend`, `get_parent_shell`, `get_take_focus`,
      `select_item`, `set_take_focus` migrated to widget activation/parent/focus helpers.
    - `cancel/deactivate/deselect` -> hide fallback.
  - `TGtkMenu` partial fallback behavior:
    - `attach/detach`, `popup*`, `popdown`, `reposition` now map to generic widget parent/show/hide/queue paths.
  - `TGtkMenuItem` partial fallback behavior:
    - `activate/select`, `set_label`, `deselect`, `set_submenu` fallback wiring.
- Completed remap batch L:
  - `TGtkCheckMenuItem.get_active/set_active` -> `GTK_STATE_FLAG_CHECKED` bridge.
  - `TGtkCheckMenuItem.get_inconsistent/set_inconsistent` -> `GTK_STATE_FLAG_INCONSISTENT` bridge.
- Verification:
  - `/tmp/gtk4test_build_no_stubs_after72.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after73.log` (RC=0)
  - `/tmp/gtk4test_build_no_stubs_after74.log` (RC=0)
- `lazgtk4.pas` residual `Not supported in GTK4.` markers: `200`.

## Direction Update (final goal alignment)
- Final objective is **not** to keep fallback wrappers; it is to complete migration to
  **GTK4-native implementation without gtk3 stubs**.
- Therefore, from this point:
  - Do **not** re-enable GTK3-only symbols (even if declarations exist in bindings).
  - Do **not** treat no-op fallback as final completion.
  - Replace GTK3-style LCL/WS call paths with GTK4-native APIs and models.

## Phase 7 (start): Remove GTK3 API surface
- Work policy:
  - Priority 1: migrate call sites in `gtk4ws*`, `gtk4widgets.pas`, `gtk4objects.pas`
    away from GTK3 concepts (`GtkMenuShell`, `GtkMenuItem`, `gtk_dialog_run`,
    old DnD/selection model, etc.).
  - Priority 2: after call-site migration, delete or isolate legacy wrappers in
    `gtk4bindings/lazgtk4.pas` so they are no longer part of active GTK4 path.
  - Priority 3: verify functional scenarios (menu, about modal, image loading),
    then keep `-dGTK4_NO_STUBS` build green.

## Immediate technical targets
1. `gtk4wsmenus.pp` / menu-related widgets:
   - Move from GTK3 menu shell/item assumptions to GTK4 menu model/popover path.
2. Dialog flow:
   - Replace blocking GTK3-style run semantics with GTK4 response/signal flow.
3. Image path verification:
   - Ensure menu/about/image rendering path uses GTK4 paintable/texture-capable APIs.

## Phase 7 Milestone: Stub Detachment Completed
- Removed linker dependency in `lazarus/lcl/interfaces/gtk4/gtk4int.pas`:
  - deleted `{$L gtk3_stubs.o}` path.
- Removed file:
  - `lazarus/lcl/interfaces/gtk4/gtk3_stubs.c` (deleted).
- Validation:
  - default build (without `-dGTK4_NO_STUBS`): `/tmp/gtk4test_build_default_after_stubs_remove.log` (RC=0)
  - strict build (with `-dGTK4_NO_STUBS`): `/tmp/gtk4test_build_no_stubs_after77.log` (RC=0)

## Audit Guard Added
- New guard script:
  - `tools/audit_gtk4_missing_calls.sh`
- Purpose:
  - Compare `lazgtk4.pas` declared external symbols vs `libgtk-4` exported symbols.
  - Fail if implementation still calls any symbol missing from `libgtk-4`.
- Current result:
  - `declared_symbols_missing_in_libgtk4: 1249`
  - `runtime_calls_to_missing_symbols: 0`
- Implication:
  - Remaining migration target is now API surface cleanup (declaration/class legacy removal),
    not active runtime symbol dependency.

## API Surface Prune (initial)
- Removed 12 unused legacy external declarations from `lazgtk4.pas`
  (symbols absent in GTK4 and no active runtime call path), including:
  - `gtk_editable_*_clipboard` set
  - `gtk_header_bar_set_*` legacy setters
  - `gtk_toggle_button_* (mode/inconsistent)` legacy entries
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_decl_prune1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after78.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (pass)
- Audit delta:
  - `declared_symbols_missing_in_libgtk4: 1249 -> 1237`
  - `runtime_calls_to_missing_symbols: 0` (unchanged)

## API Surface Prune (batch 2)
- Removed additional unused legacy external declarations from `lazgtk4.pas`:
  - `gtk_accel_group_*` block
  - `gtk_accel_label_*` block
  - `gtk_accel_map_*` block
  - `gtk_accelerator_set_default_mod_mask`
  - `gtk_accessible_get_widget` / `gtk_accessible_set_widget`
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_decl_prune2.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after79.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (pass)
- Audit delta:
  - `declared_symbols_missing_in_libgtk4: 1237 -> 1202`
  - `runtime_calls_to_missing_symbols: 0` (unchanged)

## API Surface Prune (batch 3, complete for lazgtk4.pas)
- Removed all remaining declarations in `lazgtk4.pas` that referred to symbols not
  exported by `libgtk-4`.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_decl_prune4.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after81.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (pass)
- Final audit state:
  - `declared_symbols_missing_in_libgtk4: 0`
  - `runtime_calls_to_missing_symbols: 0`

## API Surface Prune (lazgdk4)
- Performed the same declaration-surface cleanup for `lazgdk4.pas`.
- Batch results:
  - prune 1: singleton missing-symbol declarations removed (331 symbols)
  - prune 2: remaining missing-symbol declarations removed (final 25 symbols)
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_lazgdk_prune1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after82.log` (RC=0)
  - default build: `/tmp/gtk4test_build_default_after_lazgdk_prune2.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after83.log` (RC=0)
- Final audit state for lazgdk4:
  - `declared_symbols_missing_in_libgtk4: 0`
  - `runtime_calls_to_missing_symbols: 0`

## Audit Guard Upgrade
- `tools/audit_gtk4_missing_calls.sh` now audits both:
  - `lazgtk4.pas` (`LazGtk4`, `gtk_*`)
  - `lazgdk4.pas` (`LazGdk4`, `gdk_*`)
- Current integrated output:
  - `lazgtk4_declared_symbols_missing_in_libgtk4: 0`
  - `lazgtk4_runtime_calls_to_missing_symbols: 0`
  - `lazgdk4_declared_symbols_missing_in_libgtk4: 0`
  - `lazgdk4_runtime_calls_to_missing_symbols: 0`

## Runtime Behavior Migration (post-stub removal)
- `TGtkWindow.iconify/deiconify` migrated from no-op to GTK4 native behavior:
  - `gtk_window_minimize`
  - `gtk_window_unminimize`
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_window_minimize.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after84.log` (RC=0)

## Image ABI Fix (GTK4 Signature Alignment)
- Fixed `TGtkImage`/`LazGtk4` image icon APIs to GTK4 real signatures:
  - `gtk_image_new_from_gicon(icon)`
  - `gtk_image_new_from_icon_name(icon_name)`
  - `gtk_image_set_from_gicon(image, icon)`
  - `gtk_image_set_from_icon_name(image, icon_name)`
  - `gtk_image_get_gicon(image): GIcon*`
  - `gtk_image_get_icon_name(image): const char*`
- Kept `TGtkImage` method signatures source-compatible; legacy `size` arguments are
  now ignored or returned as `GTK_ICON_SIZE_INVALID`.
- Why this matters:
  - previous bindings used GTK3-style prototypes with extra size parameters,
    creating ABI mismatch risk on GTK4 and likely contributing to unstable icon/image behavior.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_image_sigfix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after85.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all four counters remain `0`)

## About Dialog Logo Fix (Paintable/Pixbuf Bridge)
- Root mismatch identified:
  - GTK4 `gtk_about_dialog_get_logo/set_logo` uses `GdkPaintable*`
  - existing binding used `GdkPixbuf*` directly (GTK3-era signature)
- Applied fix in `lazgtk4.pas`:
  - binding declarations updated to `gpointer` for about logo getter/setter.
  - added GTK4 helpers:
    - `gdk_texture_new_for_pixbuf`
    - `gdk_pixbuf_get_from_texture`
    - `gdk_texture_get_type`
  - `TGtkAboutDialog.set_logo` now converts `Pixbuf -> Texture` then passes as logo paintable.
  - `TGtkAboutDialog.get_logo` now converts `Texture -> Pixbuf` when possible.
- Expected impact:
  - About modal logo path now follows GTK4 object model instead of type-unsafe cast path.
  - reduces probability of missing/broken logo rendering and runtime warnings in about/image flows.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_about_logo_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after86.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Menu Icon Path Reactivation (GTK4 GMenuItem icon)
- Previous state:
  - `TGtk4WSMenuItem.UpdateMenuIcon` was intentional no-op, so menu icon updates were
    dropped even when LCL provided valid bitmaps.
- Implemented:
  - Added `Gtk4CreateMenuIconFromBitmap` in `gtk4wsmenus.pp`.
  - Converts `TBitmap -> stream bytes -> GBytes -> GBytesIcon` and applies via
    `g_menu_item_set_icon`.
  - Clears icon cleanly by passing `nil` when icon is absent.
  - Keeps menu rebuild flow intact (`Gtk4RebuildMenuModel`).
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_menuicon_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after87.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Image Readback Fix (`TGtkImage.get_pixbuf`)
- Previous behavior:
  - `TGtkImage.get_pixbuf` always returned `nil`, so callers that read back image
    content from `GtkImage` failed even when paintable content existed.
- Implemented:
  - Added GTK4 binding `gtk_image_get_paintable`.
  - In `TGtkImage.get_pixbuf`, convert paintable to pixbuf when the paintable is a
    `GdkTexture` (`gdk_pixbuf_get_from_texture`).
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_image_getpixbuf_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after88.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## TGtk4Image Constructor Safety Fix (stride/base init)
- Fixed `TGtk4Image.Create(AData, width, height, format, ...)`:
  - added missing `inherited Create;`
  - replaced invalid `rowstride=0` with `cairo_format_stride_for_width(...)`
  - set `has_alpha` explicitly from cairo format.
- Why this matters:
  - raw-data image creation with invalid stride can produce broken image decoding and
    unstable icon rendering paths.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_tgtk4image_stride_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after89.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Surface-Based Image Path Fix (`TGtkImage`)
- Fixed two surface path no-op behaviors:
  - `TGtkImage.new_from_surface` now converts cairo surface -> pixbuf and creates image.
  - `TGtkImage.set_from_surface` now converts cairo surface -> pixbuf and assigns image.
- Previous state:
  - both methods effectively cleared/returned empty image.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_image_surface_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after90.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Menu Icon Encoding Hardening (PNG bytes path)
- Refined menu icon conversion in `gtk4wsmenus.pp`:
  - from ad-hoc bitmap stream bytes
  - to explicit `PGdkPixbuf -> gdk_pixbuf_save_to_bufferv('png') -> GBytesIcon`.
- This avoids format ambiguity and improves GTK icon loader compatibility for menu models.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_menuicon_png_fix1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after91.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Menu Rebuild Icon Injection (initial render coverage)
- Added icon injection during `BuildMenuItems` itself:
  - each leaf `GMenuItem` now gets icon assigned from `TMenuItem.Bitmap` while model is rebuilt.
- Why:
  - ensures icons appear on first render, not only when `UpdateMenuIcon` callback is triggered later.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_menu_rebuild_icon_inject1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after92.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Robustness Pass (image handle safety + menu icon diagnostics)
- `TGtk4Image.Create(vHandle)` now handles `nil` input safely (fallback 1x1 pixbuf),
  preventing nil dereference risk in edge image/icon paths.
- Menu icon conversion helper now emits guarded debug diagnostics under
  `GTK4DEBUGMENUS` for PNG encode and icon creation outcomes.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_image_nil_guard_and_logs1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after93.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Menu Shortcut Null-String Guard (`accel` attribute)
- Added guard in `TGtk4WSMenuItem.SetShortCut`:
  - when shortcut is absent or keyval conversion fails, set `accel` to empty string
    instead of leaving a nullable path.
- Target issue:
  - reduces likelihood of `g_regex_match_full: assertion 'string != NULL' failed`
    warnings during menu popup/accelerator label parsing.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_accel_null_guard1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after94.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Menu Object Lifetime Guard (GObject safety)
- Added `Gtk4SafeUnref` helper in `gtk4wsmenus.pp` and switched menu cleanup paths
  to guarded unref calls (`Gtk4IsObject` check before `g_object_unref`).
- Cleaned menu icon creation flow:
  - removed unnecessary extra `g_object_ref` on newly created icon
  - simplified PNG encode failure branch.
- Goal:
  - reduce `g_object_unref: assertion 'G_IS_OBJECT (object)' failed` risk under
    frequent menu rebuilds.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_menu_unref_guard1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after95.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Image Blit Guard (`drawImage1`) Hardening
- Added defensive guards in `TGtk4DeviceContext.drawImage1`:
  - validate `image` / `targetRect`
  - clamp invalid source/target sizes
  - handle `sourceRect=nil` with full-pixbuf fallback.
- Goal:
  - prevent invalid matrix setup/division paths that can cause broken image rendering.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_drawimage1_guard1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after96.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## Unref Guard Expansion (`gtk4procs` / `gtk4widgets`)
- Added `Gtk4IsObject` guarded unref checks in additional high-frequency paths:
  - `gtk4procs.pas`: temporary `GMenuModel` unref and `StyleObject.Owner` unref.
  - `gtk4widgets.pas`: `TGtk4MenuShell` and `TGtk4MenuItem` destroy paths.
  - `TGtk4MenuItem` constructor now guards `g_object_ref` on `FGMenuItem`.
- Goal:
  - further reduce `g_object_ref/unref` critical warnings under menu/style churn.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_unref_guard2.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after97.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## `g_object_set_data` Guard (menu action path)
- Hardened menu-action data wiring in `TGtk4MenuItem`:
  - gate `g_object_set_data` and signal disconnect by `Gtk4IsObject(FAction)`.
- Target issue:
  - mitigates `g_object_set_data: assertion 'G_IS_OBJECT (object)' failed` seen in logs.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_setdata_guard1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after98.log` (RC=0)
  - audit: `tools/audit_gtk4_missing_calls.sh` (all counters `0`)

## GtkButton Icon API ABI Fix (GTK4)
- Fixed GTK4 ABI mismatch in `lazgtk4.pas`:
  - `gtk_button_new_from_icon_name` external declaration changed to 1-arg form
    (`icon_name`) to match GTK4.
  - kept `TGtkButton.new_from_icon_name(icon_name, size)` compatibility method and
    ignored legacy `size` parameter internally.
- Why:
  - previous 2-arg external declaration was GTK3-style and risked stack/ABI misuse
    on icon-button creation paths.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_button_sig_accel_init1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after_button_sig_accel_init2.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_button_sig_accel_init1.log` (all counters `0`)

## Menu `accel` Initialization Guard (constructor-time)
- Added constructor-time accel initialization in `TGtk4MenuItem.Create`:
  - set `GMenuItem` attribute `accel` to empty string immediately on item creation.
- Why:
  - `error_23.log`~`error_27.log` shows `g_regex_match_full: assertion 'string != NULL' failed`
    around `SetupMainMenu`; this change prevents a null accel string during early
    menu model assembly before shortcut updates run.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_button_sig_accel_init1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after_button_sig_accel_init2.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_button_sig_accel_init1.log` (all counters `0`)

## Teardown Safety: remove destroy-time `g_object_set_data` writeback
- In `TGtk4Widget.destroy_event`, removed destroy-time data writeback to
  `g_object_set_data(widget, 'lclwidget', nil)`.
- Why:
  - shutdown logs (e.g. `error_27.log`) still show sporadic
    `g_object_set_data: assertion 'G_IS_OBJECT (object)' failed` while widgets are
    being destroyed; touching object data at this stage is not required and can race
    object finalization.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_destroy_event_setdata_remove2.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after_destroy_event_setdata_remove1.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_destroy_event_setdata_remove1.log` (all counters `0`)

## Crash Fix: shortcut activate-action singleton finalization
- Symptom from `error_28.log`:
  - `Gtk:ERROR ... gtkshortcutaction.c:455:gtk_activate_action_finalize: code should not be reached`
  - process abort (forced termination).
- Root cause:
  - `Gtk4SetWidgetShortCut` used `gtk_activate_action_get()` and passed that action
    into `gtk_shortcut_new(...)`.
  - `gtk_shortcut_new` takes ownership of the action; this can drive a singleton
    activate-action into finalize path, which GTK marks as unreachable and aborts.
- Fix:
  - replaced singleton usage with per-shortcut callback action:
    `gtk4_callback_action_new(@Gtk4ShortcutActivateActionCB, nil, nil)`
    where callback calls `gtk_widget_activate(widget)`.
  - added object-validity guards for shortcut controller teardown path:
    `if not Gtk4IsObject(PGObject(AWidget)) then Exit;`
    and guarded old-controller removal.
- Validation:
  - default build: `/tmp/gtk4test_build_default_after_shortcut_callback_action1.log` (RC=0)
  - strict build: `/tmp/gtk4test_build_no_stubs_after_shortcut_callback_action2.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_shortcut_callback_action1.log` (all counters `0`)

## Search->Find AV Fix: unsafe GTK4 parent traversal in coord mapping
- Symptom (`error_29.log`, `error_30.log`):
  - `LazFindReplaceDialog` gets invalid X (`Left=6716965`) during `ChangeBounds`
  - then `EAccessViolation` on Find dialog flow.
- Root cause:
  - `TGtk4Widget.ClientToScreen/ScreenToClient` traversed widget ancestry via
    direct struct field access (`w^.parent`), which is unsafe for GTK4 opaque
    widget internals and can produce corrupted pointers/coordinates.
- Fix:
  - replaced direct field traversal with GTK4 API traversal:
    `gtk_widget_get_parent()` loop to obtain top-level ancestor.
- Validation:
  - strict build: `/tmp/gtk4test_build_no_stubs_after_parent_api_fix1.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_parent_api_fix1.log` (all counters `0`)

## Error_31 Follow-up Hardening (Find crash + splash clipping)
- Symptoms:
  - `error_31.log`: `LazFindReplaceDialog` X becomes `6716965`, then `EAccessViolation`.
  - splash image appears clipped on startup.
- Additional GTK4-side root causes addressed:
  - top-level window `SetBounds` still called `gtk_widget_size_allocate()` directly,
    which is not a safe app-level path for GTK4 toplevel sizing/layout.
  - remaining runtime paths still used direct `Widget^.parent` field access.
  - `GetWindowRect` fallback path for GTK4 returned geometry without robust success/fallback handling.
- Fixes applied:
  - `gtk4widgets.pas`
    - added coordinate sanity guard in `ClientToScreen/ScreenToClient`
      (`GTK4_COORD_SANITY_LIMIT = 1000000`).
    - `TGtk4Window.SetBounds` changed to GTK4-safe toplevel sizing path:
      removed direct `gtk4_widget_size_allocate` use for toplevel; use
      `gtk_window_set_default_size` path and clamp min size.
  - `gtk4objects.pas`
    - replaced `pw:=pw^.parent` with `gtk_widget_get_parent(pw)`.
  - `gtk4wscomctrls.pp`
    - replaced `Widget^.parent` check with `gtk_widget_get_parent(...)`.
  - `gtk4cellrenderer.pas`
    - replaced menu-parent checks from `DCWidget^.parent` to `gtk_widget_get_parent(...)`.
  - `gtk4winapi.inc`
    - simplified GTK4 `GetWindowRect` to allocation-based path with
      LCL-bounds fallback and consistent success return.
- Validation:
  - build: `/tmp/gtk4test_build_after_error31_fix1.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_error31_fix1.log` (all counters `0`)

## Error_32 Analysis/Fix (About modal abort)
- Symptoms (`error_32.log`):
  - repeated `g_object_set_data: assertion 'G_IS_OBJECT (object)' failed` (7x)
  - hard abort: `gtk_activate_action_finalize: code should not be reached`
- Root-cause direction:
  - stale/invalid GTK object metadata writes in widgetset window-long path during
    modal lifecycle/teardown.
  - shortcut action/controller path remained a high-risk crash surface during
    About dialog interactions.
- Fixes (LCL GTK4 only):
  - `gtk4winapi.inc`
    - guarded `GetWindowLong/SetWindowLong` data access by `Gtk4IsObject(...)`
      before any `g_object_get_data/g_object_set_data` call.
  - `gtk4wsstdctrls.pp`
    - added conservative guard `GTK4_ENABLE_WIDGET_SHORTCUTS = False`
      to disable widget-local shortcut controller/action creation path for now
      (prevents shortcut-action finalize abort surface).
  - `gtk4widgets.pas`
    - improved toplevel sizing path for GTK4: keep `set_default_size`, add
      `set_size_request`, remove forced `set_resizable(true)` toggle in `SetBounds`.
- Validation:
  - build: `/tmp/gtk4test_build_after_error32_fix1.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_error32_fix1.log` (all counters `0`)

## Error_32 Follow-up Improvement (About close hang + splash clipping mitigation)
- Goal:
  - reduce post-modal-close unresponsive loop risk.
  - strengthen object-lifetime guards on generic property metadata paths.
  - improve splash-form sizing consistency.
- Fixes:
  - `gtk4object.inc`
    - `AppProcessMessages` now uses a bounded drain loop
      (`MAX_MAIN_CONTEXT_DRAIN = 10000`) to avoid unbounded pending-loop stalls.
  - `gtk4winapi.inc`
    - hardened `SetProp/RemoveProp` with:
      - `Handle/Str` validation
      - `IsValidHandle` check
      - local widget/container pointer validation before `g_object_set_data`.
  - `gtk4widgets.pas`
    - added splash-form (`fsSplash`) specific sizing/decor policy:
      - undecorated, non-resizable
      - explicit `set_size_request` + `set_default_size`
      - central widget size request synced to form params.
- Validation:
  - build: `/tmp/gtk4test_build_after_error32_fix2.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_error32_fix2.log` (all counters `0`)

## Error_34 Fix (About close path AV in legacy event callback)
- Symptom (`error_34.log`):
  - `EAccessViolation` after About modal close
  - stack includes `CanSendLCLMessage` and `GTK4LegacyEvent`
    (`gtk4widgets.pas`), during teardown.
- Root cause:
  - late GTK legacy event callbacks can run while widget teardown is in progress.
  - old `CanSendLCLMessage` called `IsWidgetOk` (`Gtk4IsWidget(FWidget)` type check),
    which can crash on stale widget pointers during destruction race.
- Fixes:
  - `gtk4widgets.pas`
    - `Gtk4LegacyEventCB` now exits early unless `Gtk4IsLiveWidgetPointer(Data)` is true.
    - `CanSendLCLMessage` now uses live-wrapper + non-nil checks only
      (`Gtk4IsLiveWidgetPointer(Self)`, `FWidget <> nil`, `LCLObject <> nil`)
      and avoids unsafe GTK type checks in teardown-sensitive path.
- Validation:
  - build: `/tmp/gtk4test_build_after_error34_fix1.log` (RC=0)
  - audit: `/tmp/gtk4_audit_after_error34_fix1.log` (all counters `0`)

## Shutdown Deep-Dive Plan (GTK2/QT5 vs GTK4)
- Goal:
  - remove remaining GTK4 shutdown instability/warnings without any IDE-side changes.
  - align GTK4 teardown behavior with proven GTK2/QT5 lifecycle patterns.
- Observed current state:
  - `error_39.log`, `error_40.log`: no fatal AV, but repeated
    `gtk_stack_remove: gtk_widget_get_parent(child) == stack` assertions during IDE exit.
  - warnings cluster around mass page/widget destruction timing.
- Cross-backend findings:
  - GTK4:
    - notebook signals are connected on `FCentralWidget` with callback data `Self`
      (`gtk4widgets.pas:5469`, `gtk4widgets.pas:5471`).
    - generic destroy disconnect currently targets only `FWidget`
      (`gtk4widgets.pas:3134`).
    - `TGtk4Widget.DeInitializeWidget` is empty (`gtk4widgets.pas:3294`).
    - explicit notebook remove path exists (`gtk4widgets.pas:5562`,
      `gtk4wscomctrls.pp:1554`).
  - GTK2:
    - notebook callbacks are connected with LCL object data (`AWidgetInfo^.LCLObject`)
      (`gtk2pagecontrol.inc:223`, `gtk2pagecontrol.inc:224`).
    - no GTK2 WS `RemovePage` override found in `gtk2wscomctrls.pp` (less explicit removal on teardown path).
  - QT5:
    - explicit `DeInitializeWidget -> DetachEvents -> DestroyWidget` lifecycle
      (`qtwidgets.pas:2279`, `qtwidgets.pas:2303`, `qtwidgets.pas:5994`).
    - tab removal is wrapped in update guards (`qtpagecontrol.inc:303`).

### Execution Plan
1. Add GTK4 notebook-specific detach phase:
   - implement `TGtk4NoteBook.DestroyWidget` override to disconnect `switch-page`
     handlers from `FCentralWidget` before inherited destroy.
   - include both callback symbols (`GtkNotebookSwitchPage`, `GtkNotebookAfterSwitchPage`)
     and `Self` data-matched disconnect.
2. Add explicit destruction-state guard for notebook callbacks:
   - set notebook/widget object data flag (e.g. `lcl-destroying`) before teardown.
   - make notebook switch callbacks exit immediately when flag is set.
3. Tighten GTK4 RemovePage policy during teardown:
   - keep `csDestroying` guard in WS layer.
   - add notebook-local guard to skip `remove_page` when notebook or page parent ownership
     is already changing (prevents duplicate remove against internal stack).
4. Introduce GTK4 DeInitializeWidget parity baseline:
   - create minimal detach-events path in GTK4 base class (no behavior changes, only signal/controller detachment).
   - follow QT5 ordering: detach first, then widget destroy.
5. Verification loop:
   - rebuild Lazarus GTK4.
   - run IDE startup -> About open/close -> menu interactions -> menu exit.
   - pass criteria: no hang/abort, and `gtk_stack_remove` warnings reduced to zero (or single known benign case with documented source).

### Acceptance Criteria
- IDE exit path completes without “app not responding”.
- `error_*.log` no longer shows repeated `gtk_stack_remove` assertion bursts.
- no regression in About modal open/close and Search/Find dialog open paths.
