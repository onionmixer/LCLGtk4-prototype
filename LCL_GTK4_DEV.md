# LCL GTK4 Backend 개발 계획서

## 1. 프로젝트 개요

### 1.1 목표
Lazarus Component Library(LCL)에 GTK4 위젯셋 백엔드를 구축하여, Lazarus 애플리케이션이 GTK4 네이티브 위젯을 사용할 수 있도록 한다.

### 1.2 현재 상태 (2026-07-02 Session 75 갱신)
- **IDE 실사용 단계** — 폼 디자이너/코드 에디터/자동완성 실동작 검증 중. 최근(S71~75): GtkFixed z-order 패치, SynEdit 한글 IME, ScrollBar/Viewport, 좌표계 화면 절대좌표화, X11 override-redirect 팝업, 디자인 모드 입력 라우팅. (상세 §5.2 세션 로그 및 MEMORY.md)
- **Phase 0~6 완료** — GTK3 포크 기반 빌드 성공 (0 에러), 24개 위젯 headless 검증, 정상 종료
- **Phase 7.1~7.3 완료** — Lazarus 빌드 시스템 등록 + **IDE 자체 빌드 성공** (136MB ELF, `libgtk-4.so.1` 링크)
- **Session 33 종합 점검 완료** — GTK2/Qt5 교차 비교로 식별된 7개 구현 갭 **전체 완료**
- **Session 34~35 안정성 점검 완료** — 버그 수정(Double Free, Dialog 콜백), 콜백 안전성 강화(6개 핸들러), GTK2 패리티(QueryWSEventCapabilities, ClipboardFormatNeedsNullByte) **(완성도 ~98%)**
- **시스템 GTK4**: `libgtk-4-dev 4.6.9`
- **GTK4 Modern Widget 마이그레이션 완료**: ComboBox(GtkDropDown), ListView(GtkColumnView+GtkGridView), ListBox/CheckListBox(GtkListView), Sort Indicator
- **GTK4 상속 변경 수정**: ScrollBar(GtkScrollbar≠GtkRange), SpinEdit(GtkSpinButton≠GtkEntry), CheckListBox(WS GetState 캐시 직접 접근)
- **GTK3 잔재 정리 완료**: `gtk3_stubs.c` 삭제(1388줄), `UpdateSysColorMap_GTK3` 삭제(171줄), lazgtk4.pas GTK3 Menu/Container 스텁 정리, 바인딩 순 1,331줄 감소
- **코드 품질**: 경고 0개, 조치 가능 노트 1개 (FPC 제한)
- **Session 32**: 모니터 열거 API 수정 + **GTK3 잔재 전면 정리**:
  1. `GetMonitorInfo`: `gdk_monitor_is_primary`/`gdk_monitor_get_workarea` 스텁 호출 제거 → index 0 = primary, rcWork = rcMonitor. g_list_model_get_item nil 시 synthetic fallback(GetSystemMetrics 기반)
  2. `MonitorFromPoint`: **double g_object_unref 버그** 수정 (Exit 전 unref + finally unref = over-release → GdkMonitor 파괴 → 후속 g_list_model_get_item nil 반환). 이 버그가 수백 개 `g_object_ref` assertion 경고의 근본 원인이었음
  3. `GetPrimaryMonitorGeometry`: geometry width/height 0 체크 추가, 1920x1080 fallback
  4. `EnumDisplayMonitors`: 0개 모니터 시 synthetic HMONITOR(1) 발행
  5. **GTK3 정리**: `gtk3_stubs.c` 삭제, `UpdateSysColorMap_GTK3` 죽은 코드 삭제, `Gtk4MainEventLoop` 미사용 스텁 제거, lazgtk4.pas TGtkMenuBar 스텁/gtk_container_resize_children 제거 + GTK3 COMPAT 주석, ScrollBox/CustomFrame Factory 등록 활성화
  - **결과**: IDE 15초 런타임(xvfb) — 0 exception, 0 GLib assertion, GtkDialog 생성 확인. **순 1,331줄 코드 감소**

### 1.3 기본 전략
**GTK3 백엔드를 기반(fork)으로 GTK4로 마이그레이션**하는 전략을 채택한다.
- GTK3 → GTK4 간 API 유사성이 높아 가장 효율적
- GTK3 백엔드: 약 30,000줄 코드 + 103,000줄 바인딩
- GTK2 및 Qt5 백엔드의 설계 패턴도 참조

---

## 2. 아키텍처

### 2.1 LCL 위젯셋 등록 구조

```
LCL 핵심 (lcl/)
  ├── interfacebase.pp     → TWidgetSet 추상 기본 클래스
  ├── lclplatformdef.pas   → TLCLPlatform 열거형 (lpGtk, lpGtk2, lpGtk3, ...)
  ├── forms.pp             → CreateWidgetset() / FreeWidgetset()
  └── widgetset/           → WSClasses 추상 기본 클래스들

인터페이스 구현 (lcl/interfaces/<backend>/)
  ├── interfaces.pp        → 진입점: CreateWidgetset(TXxxWidgetSet)
  ├── <backend>int.pas     → TXxxWidgetSet 클래스 정의
  ├── <backend>widgets.pas → 위젯 래퍼 클래스 계층
  ├── <backend>objects.pas → GDI 객체 래퍼 (Font, Brush, Pen, DC, Region)
  ├── <backend>wsfactory.pas → RegisterXxx 팩토리 함수들
  ├── <backend>ws*.pp      → 각 컴포넌트별 WS 구현
  └── <backend>bindings/   → 네이티브 라이브러리 바인딩 (GTK3 패턴)
```

### 2.2 아키텍처 결정 사항

**C 스텁 패턴** (`gtk3_stubs.c`): ~~GTK3에서 제거된 함수를 void no-op으로 스텁. ~650개 스텁 중 활성 호출 1개만 잔존.~~ **Session 32에서 삭제됨** — 1388줄의 C 스텁 전체 제거. GTK4 네이티브 API로 완전 전환 완료.

**GTK4 호환 바인딩** (`lazgtk4_compat.pas`): GTK4 전용 함수의 Pascal 바인딩. `gtk4_` 접두사로 충돌 방지.

**소프트웨어 캡처 추적** (`Gtk4CapturedWidget`): `gtk_grab_add/remove` 제거 대응, Pascal 글로벌 변수로 마우스 캡처 추적.

> Sections 2.2~7의 초기 계획 (GTK3 구조, API 변경, 개발 단계, 마이그레이션 가이드, 기술적 도전, 일정) — git `ba068a2` 참조.

---

## 3. 개발 환경

```bash
# 작업 디렉터리
/usr/src/lazarus4_build/LCL_GTK4/

# C 스텁 컴파일 (gtk3_stubs.c → gtk3_stubs.o)
cd gtk4test/
gcc -c -o gtk3_stubs.o ../lazarus/lcl/interfaces/gtk4/gtk3_stubs.c \
    $(pkg-config --cflags gtk4 pangocairo)

# Pascal 프로젝트 빌드
ppcx64 -B \
    -Fi../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl \
    -Fu../lazarus/lcl/forms \
    -Fu../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl/interfaces/gtk4/gtk4bindings \
    -Fu../lazarus/lcl/widgetset \
    -Fu../lazarus/lcl/units/x86_64-linux \
    -Fu../lazarus/components/lazutils \
    -Fu../lazarus/packager/units/x86_64-linux \
    -Fu../lazarus/components/freetype/lib/x86_64-linux \
    -dgtk4 gtk4test.lpr
```

> **주의**: `-Fu` 경로가 소스 디렉터리를 가리켜야 LCL PPU가 리빌드됨. `units/x86_64-linux` 경로만 사용하면 기존 PPU 재활용.

### 필수 패키지
- Free Pascal Compiler (FPC) 3.2.2+, Lazarus 4.x 소스 트리
- `libgtk-4-dev` (4.6.9), `libglib2.0-dev`, `libcairo2-dev`, `libpango1.0-dev`

### 테스트 명령
```bash
GTK_DEBUG=interactive ./myapp    # GTK 인스펙터
GDK_BACKEND=x11 ./myapp         # X11 강제
GDK_BACKEND=wayland ./myapp     # Wayland 강제

# Headless 테스트 (xvfb-run, TTimer 3초 자동종료)
timeout 30 xvfb-run -a -s "-screen 0 1280x1024x24" ./gtk4test
cat /tmp/gtk4test_events.log   # 이벤트 로그

# Heaptrc 메모리 누수 점검
ppcx64 -B -gh -gl \
    -Fi../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl -Fu../lazarus/lcl/forms \
    -Fu../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl/interfaces/gtk4/gtk4bindings \
    -Fu../lazarus/lcl/widgetset \
    -Fu../lazarus/lcl/units/x86_64-linux \
    -Fu../lazarus/components/lazutils \
    -Fu../lazarus/packager/units/x86_64-linux \
    -dgtk4 gtk4test.lpr
timeout --signal=KILL 30 xvfb-run -a -s "-screen 0 1280x1024x24" \
    ./gtk4test 2>/tmp/gtk4test_stderr.log
cat /tmp/gtk4test_heap.log     # heaptrc 출력
```

---

## 4. 참고 자료
- GTK4 API: `https://docs.gtk.org/gtk4/` | 마이그레이션: `https://docs.gtk.org/gtk4/migrating-3to4.html`
- GTK2 백엔드: `lcl/interfaces/gtk2/` (WinAPI 매핑 참고)
- GTK3 백엔드: `lcl/interfaces/gtk3/` (기반 코드)
- Qt5 백엔드: `lcl/interfaces/qt5/` (이벤트 처리, 액션 기반 메뉴 참고)

---

## 5. 구현 진행 현황

> 최종 갱신: 2026-02-25 (Session 35) | 빌드: **0 에러** (136MB ELF) | 런타임: **24 위젯 검증 완료, exit 0** | IDE: **빌드 성공 + 런타임 15초 xvfb — 0 exception, 0 GLib assertion** | GTK3 잔재: **정리 완료** | GTK2/Qt5 교차 비교: **7개 갭 전체 구현 완료** | Session 34~35 안정성 점검: **버그 수정 + 콜백 안전성 강화 + GTK2 패리티 (완성도 ~98%)**

### 5.1 Phase 진행 요약

| Phase | 상태 | 설명 |
|-------|------|------|
| Phase 0: 기반 인프라 | **완료** | GTK3 포크, GTK4 바인딩, C 스텁 체계, 빌드 시스템 |
| Phase 1: 최소 실행 | **완료** | 빈 폼 표시, 이벤트 컨트롤러, 기본 렌더링 |
| Phase 2: 기본 컨트롤 | **완료** | 위젯, 이벤트, 페인팅, 기본 위젯 동작 |
| Phase 3: 그래픽/DC | **완료** | cairo 기반 DC, GDI 객체 |
| Phase 4: 다이얼로그/메뉴 | **완료** | GMenu/GAction 메뉴, gtk_dialog_run 대체, 파일 다이얼로그 |
| Phase 5: 고급 기능 | **완료** | 클립보드, 커서, ListView WS pick-based hit-test |
| Phase 6: 런타임 검증 | **완료** | 24개 위젯 headless 검증, GTK4 상속 수정(ScrollBar/SpinEdit), CheckListBox WS 캐시 수정, ColumnInsert 누수 해소, GTK assertion 8건 방어, **AppTerminate hang 해결**, 정상 종료 |
| Phase 7: Lazarus IDE 통합 | **진행 중** | ✅ 7.1 플랫폼 등록, ✅ 7.2 패키지 등록, ✅ 7.3 IDE 자체 빌드 성공 (142MB), ✅ 7.3.1 모니터 API 수정 (IDE 런타임 AV 해소), 미시작: 7.4 LCL 테스트 스위트 |
| Phase 8: 배포 준비 | 미시작 | X11/Wayland 듀얼 테스트, 멀티 배포판 호환성 |

### 5.2 세션 로그

| Session | 주요 변경 |
|---------|----------|
| 1~3 | Phase 0~4: GTK3 포크, GTK4 바인딩, 이벤트 컨트롤러, 위젯 계층(44개), 메뉴(GMenu/GAction), 다이얼로그(Gtk4DialogRun), WinAPI 기본 |
| 4 | 클립보드(GdkClipboard API), WinAPI 4개(GetCursorPos, IsZoomed 등), gtk_button_set_image→set_child |
| 5 | 파일 다이얼로그 GFile API 전면 마이그레이션 (set/get_current_folder, get/set_filename → GFile) |
| 6 | 커서 API(GdkTexture), 파일 다이얼로그 필터(GListModel), 마우스 캡처(소프트웨어), ComboBox priv3 제거(14개), GTK_STOCK 제거 |
| 7 | ToolBar(GtkBox), PaintTo(GtkSnapshot→cairo), RawImage 캡처, CSS 스타일링(Font/FgColor/BgColor), StatusBar 패널, Memo 선택/캐럿, Edit CharCase |
| 8 | 모니터 API(GListModel), SendMessage, 소프트웨어 캐럿(9개 WinAPI), SetWindowPos, WindowFromPoint(gtk4_widget_pick), 이벤트 핸들러(GIOChannel) |
| 9 | FontIsMonoSpace, 메뉴 단축키(GMenu accel), 메뉴 아이콘(GBytesIcon), DrawEdge(cairo), 좌표 매핑(DPtoLP/ViewPort), 리전 함수 |
| 10 | Memo MaxLength/CharCase 콜백, Phase 2 완료 확인 |
| 11 | ListView 체크박스(CellRenderer), 미사용 변수 정리, DebugLn 조건부 래핑(17개), InitializeWidget 가시성 수정 |
| 12 | 컴파일러 노트 해결(5개), ExcludeClipRect, RawImage 비트심도(1/8/16bit) |
| 13 | 전체 위젯 페인팅(FPaintArea→TGtk4Widget), 파일 드롭(GtkDropTarget), TreeView 키바인딩 수정 |
| 14 | ListView HideSelection/HotTrack, Button/CheckBox 키보드 단축키(GtkShortcutController), Edit/Memo HideSelection(CSS), Memo WantReturns |
| 15 | CopyFrom 메모리 버그 수정, 커서 30종 매핑, Z-order(insert_before/after), ColumnMove, UpdateImageCellsSize |
| 16 | 시스템 색상(UpdateSysColorMap), OwnerDraw(CN_DRAWITEM), StayOnTop, 탭 이미지, DrawFocusRect, GTK4DEBUGNOTIMPLEMENTED 전체 제거 |
| 17 | ColumnSetImage(커스텀 헤더 위젯), **시스템 트레이(SNI D-Bus 직접 구현, libappindicator3 제거)** |
| 18 | TPreviewFileDialog(content area), 파일 다이얼로그 History(GtkComboBoxText), 플랫폼 한계 정리 |
| 19 | **GTK4 Modern Widget 바인딩 108개** (GtkDropDown/GtkColumnView/GtkListView/GtkStringList 등 11개 클래스) |
| 20 | **GtkComboBox→GtkDropDown 마이그레이션** (TGtk4DropDown + TGtkStringListStrings, csDropDownList) |
| 21 | **ComboBox OwnerDraw** (GtkSignalListItemFactory), graphene_rect_t + gtk_snapshot_append_cairo 바인딩 |
| 22 | **GtkTreeView→GtkColumnView Phase 1** (vsReport/vsList: GtkStringList+SelectionModel+Factory, 17개 메서드 분기), GtkBitset 5개, 행 색상 분석(4방안) |
| 23 | **GtkColumnView Phase 2** — Checkbox(GtkCheckButton factory), IntfCustomDraw(Per-Cell CssProvider), OwnerDraw(GtkDrawingArea+CN_DRAWITEM) |
| 24 | **GtkIconView→GtkGridView** (vsIcon/vsSmallIcon), **Sort Indicator** (GtkCustomSorter+열 헤더 클릭/정렬 화살표+ColumnSetSortIndicator) |
| 25 | **ListBox/CheckListBox→GtkListView** (GtkStringList+SelectionModel+Factory, TGtkStringListStrings 재활용), **ColorDialog Palette/Color** (GtkColorChooser set_rgba+add_palette) |
| 26 | **ListView WS pick-based hit-test** — GetItemAt/GetTopItem/GetVisibleRowCount: gtk4_widget_pick+factory metadata로 근사치→정밀값 개선, ItemGetPosition adjustment 추정 추가, GridView/OwnerDraw factory에 lcl-list-view 메타데이터 추가. **IsIconic 구현** — GdkToplevel.get_state + GDK_TOPLEVEL_STATE_MINIMIZED (gtk4_native_get_surface+gdk4_toplevel_get_state 바인딩 추가) |
| 27 | **Phase 6: 런타임 검증** — gtk4test 23개 위젯 headless 테스트 (xvfb-run, TTimer 3초 자동종료). **GTK4 상속 변경 발견/수정**: (1) GtkScrollbar≠GtkRange — PGtkRange 캐스트→gtk4_scrollbar_get_adjustment 전면 교체 (gtk4widgets.pas, gtk4winapi.inc, lazgtk4_compat.pas). (2) CheckListBox WS GetState 무한재귀 — 클래스 크래커로 LCL 캐시 직접 접근 (gtk4wschecklst.pp). (3) GetCachedData 유효성 가드(try/except). **검증 결과**: Label, Button×3, Edit, CheckBox, Memo, Menu, PageControl+TabSheet×2, ComboBox(csDropDown+csDropDownList), ListBox, CheckListBox, ScrollBar, GroupBox, Panel, TrackBar, StatusBar, ListView(vsReport+Checkboxes), ProgressBar, ToolBar — FormShow/FormPaint/TimerAutoExit/FormClose 전체 라이프사이클 정상 |
| 28 | SpinEdit GTK4 상속 수정(Gtk4IsEntry 가드), ColumnInsert factory 누수 해소(@Gtk4CV_FactoryDataDestroy), 24개 위젯 headless 검증 |
| 29 | **TTimer 미발동 근본 원인 수정** — OnShow 미발동(FVisible=True→SetVisible 즉시 반환) 발견, 타이머를 FormShow→FormCreate로 이동. **GTK assertion 방어 코드 8건 적용 + LCL full rebuild 검증**: (1) TGtk4CustomControl scrollbar nil 가드, (2) SetScrollBarsSignalHandlers nil 가드, (3) CSS 빈 문자열→`'* {}'`, (4) ApplyWidgetCss 빈 문자열 가드, (5) LoadCSSTheme 빈 경로 수정, (6) Gtk4PollFunction 반환값 캡처, (7) Gtk4CV_FactoryDataDestroy TGClosureNotify 시그니처 수정, (8) SetColumnImage FIsColumnView 가드. **검증 결과**: `gtk_editable_insert_text` ✅해소, `g_object_set_data` ✅해소, `gtk_tree_view_get_column` ✅해소, `g_regex_match_full` 1건 잔존(GTK4 내부). **발견**: `ppcx64 -B gtk4test.lpr`는 LCL PPU를 리빌드하지 않음. **Application.Terminate hang**: 테스트에서 Halt(0) 우회 |
| 30 | **Application.Terminate hang 근본 수정** — AppTerminate→no-op, GtkApplication 해제를 Destroy로 이동, `Halt(0)`→`Close` 복원. **Phase 7.1/7.2 — lpGtk4 플랫폼 등록 + 패키지 등록** — `lcl.lpk` BuildMacros에 `gtk4` 추가(Item15), Files 섹션에 47개 파일 항목(Item549~595), PackageVariants에 `_Item13` gtk4 변형, IncludePath 등록. `Makefile.fpc` dirs에 `gtk4` 추가. `fpmake.pp`에 Dependencies/ImplicitUnit 66개 등록 |
| 31 | **Phase 7.3 — Lazarus IDE 자체 빌드 성공** — `make all LCL_PLATFORM=gtk4` 전체 빌드 체인 구동. (1) `fpcmake -Tall`로 `interfaces/Makefile` 재생성 (2) PPU 충돌 해소 (전체 클린 빌드) (3) `gtk3_stubs.o` GCC 컴파일 (4) `lclextensions/include/gtk4/` 플랫폼 스텁 4개 생성 (5) `virtualtreeview/include/intf/gtk4/` + `units/gtk4/` 플랫폼 파일 7개 생성. **결과**: 142MB ELF, `libgtk-4.so.1` 동적 링크 확인. **IDE 런타임 발견**: `TMonitor.GetInfo` AV (monitor.inc:21) — 모니터 열거 API 미구현 |
| 32 | **모니터 열거 API 수정 + GTK3 잔재 전면 정리** — (A) 모니터: GetMonitorInfo 스텁 호출 제거+fallback, MonitorFromPoint double-unref 근본 버그 수정, GetPrimaryMonitorGeometry 유효성 체크, EnumDisplayMonitors synthetic HMONITOR. (B) GTK3 정리: **`gtk3_stubs.c` 삭제**(1388줄), `UpdateSysColorMap_GTK3` 삭제(171줄), `Gtk4MainEventLoop` 스텁 제거, lazgtk4.pas TGtkMenuBar 스텁 6개 제거+`gtk_container_resize_children` 제거+TGtkContainer/TGtkBin/TGtkMenuShell/TGtkMenuItem GTK3 COMPAT 주석. (C) Factory 활성화: **ScrollBox, CustomFrame 등록**. (D) lazgtk4.pas/lazgdk4.pas 바인딩 정리. **결과**: IDE 15초 xvfb — 0 exception, 0 GLib assertion. **24파일, +3,858/-5,189 (순 -1,331줄)** |
| 33 | **GTK2/Qt5 교차 비교 종합 점검 + 7개 구현 갭 전체 완료** — (1) gtk4wsdialogs.pp GTK3 죽은 코드 ~100줄 제거 (TFileSelHistoryEntry, gtkDialogSelectRowCB, GTKDialogMenuActivateCB). (2) ListView SelectAll 구현 (gtk4_selection_model_select_all/unselect_all). (3) RegisterCustomGrid 활성화 + gtk4wsgrids.pp 신규 생성 (GetEditorBoundsFromCellRect+Invalidate). (4) GetBitmapBits/GetDIBits 구현 (TGtk4Image.bits→System.Move). (5) SetSysColors 구현 (SysColorMap[] 직접 업데이트). (6) SpinEdit SetEditorEnabled 구현 (gtk_editable_set_editable). (7) GetFontLanguageInfo 구현 (Pango DBCS 휴리스틱). 교차 검증으로 12개 오탐 확인 (실제로는 상속/구현 완료). **빌드 0 에러 (136MB ELF)** |
| 34 | **2차 종합 점검 — 버그 수정 + 구현 보완 + GTK3 잔재 정리** — (A) **버그 수정**: TGtk4Dialog.InitializeWidget에서 `inherited` 미호출 → SetCallbacks 추가, Font/Color/newColor 다이얼로그 중복 SetCallbacks 제거. TGtk4WSCommonDialog.SetCallbacks GTK3 시그널(`delete-event`, `key-press-event`) → GTK4(`close-request`)로 수정. (B) **구현**: SetCursorPos 구현 (X11: dynlibs→XWarpPointer, Wayland: 미지원), GetCmdLineParamDescForInterface 구현 (GTK4 옵션 5개). (C) **GTK3 정리**: gtk4cellrenderer.pas `gtk_object_get_class` 주석 3건, gtk4private.pas `gtk_timeout_remove` 주석 2건, gtk4widgets.pas `gtk_main_level` 주석 2건, lazgtk4.pas deprecated 외부선언 5건 제거, gtk4wsdialogs.pp GTKDialogKeyUpDownCB 함수 삭제(31줄). **빌드 0 에러** |
| 35 | **3차 종합 점검 — 크리티컬 버그 수정 + 콜백 안전성 강화 + GTK2 패리티** — (A) **크리티컬 버그**: `TGtk4DeviceContext.SetvImage` Double Free 수정 (`FvImage.Free` 이중 호출 → `FvImage := AValue` 할당 누락). (B) **콜백 안전성**: `Gtk4PaintAreaDraw`/`Gtk4MapWidget`/`Gtk4WidgetHide`/`Gtk4WidgetShow`에 `Gtk4IsLiveWidgetPointer` 검증 추가, `ProgressPulseTimeout`에 `Gtk4IsWidget` 검증 추가, `UpdateMemoCursorCB`/`UpdateMemoSelLengthCB`에 nil 가드 추가. (C) **GTK2 패리티**: `QueryWSEventCapabilities` 5개 다이얼로그 클래스에 `[cdecWSPerformsDoShow]` 구현 (Open/Save/SelectDirectory/Color/Font), `ClipboardFormatNeedsNullByte` 선언+구현 추가. **빌드 0 에러** |
| 36~73 | (이 표는 S35 이후 갱신되지 않음 — 상세 세션 로그는 `ANAYLIZE_gtk4_need_implementation.md` 헤더(S61~) 및 프로젝트 메모리 MEMORY.md 참조. 주요 항목: 코드 품질 스윕(S64~68), 메모리/시그널 안전성(S65~69), IMContext pre-edit·접근성(S69), 바인딩 카테고리 완료(S70), GtkFixed snapshot vfunc z-order 패치(S71), SynEdit 한글 IME/캐럿(S72), ScrollBar/Viewport 수정(S73)) |
| 74 | **좌표계 화면 절대좌표화(X11)** — ClientToScreen/ScreenToClient/GetCursorPos가 `Gtk4X11GetWindowOrigin`+`gtk4_native_get_surface_transform`로 화면 절대좌표 반환. **SetMaxSize CSS max-width/max-height 제거** (GTK4 미지원 GTK3 전용, FMaxCssProvider 삭제; 최대크기는 X11 WM_NORMAL_HINTS+notify::default-size 스냅백으로만). 커밋 `fa64186` |
| 75 | **X11 override-redirect 팝업** (코드 완성 팝업 위치/사라짐 수정 — GTK4가 제거한 gtk_window_move+GTK_WINDOW_POPUP 대체): `TGtk4Window.PreparePopupShow`/`RaiseX11Popup` + `XChangeWindowAttributes`/`XRaiseWindow` 바인딩, `Gtk4FormIsPopup`(csNoFocus 또는 bsNone+stayOnTop; 일반 THintWindow 제외 — OR 툴팁 pointer enter/leave 루프=팔레트 hover 깜박임 방지), Wayland는 transient_for 폴백. **디자인 모드 입력 라우팅**: `Gtk4DesignKeyPressedCB`(CAPTURE 단계 키 컨트롤러 — 선택 위젯에서 Delete가 컴포넌트를 삭제; 네이티브 GtkText의 TARGET 단계 선점 우회, 런타임 no-op), 디자인 모드 클릭 시 상태 변경 방지 `csDesigning` 가드 6종(체크/라디오·스핀·콤보·트랙바·캘린더·리스트류; 노트북 탭전환 제외). 커밋 `bc63c63` |

### 5.3 남은 작업 — Session 35 종합 점검 (완성도 ~98%)

#### A. 해결된 이슈

| 이슈 | 세션 | 설명 |
|------|------|------|
| ~~SpinEdit GTK4 상속~~ | 28 | ✅ `Gtk4IsEntry(Widget)` 가드 추가 |
| ~~ListView ColumnInsert 누수~~ | 28 | ✅ `@Gtk4CV_FactoryDataDestroy` 연결 |
| ~~TTimer 미발동~~ | 29 | ✅ 타이머를 FormCreate로 이동 |
| ~~GTK assertion 8건~~ | 29 | ✅ LCL full rebuild 검증, 잔존 1건(GTK4 내부) |
| ~~Application.Terminate hang~~ | 30 | ✅ AppTerminate→no-op, Destroy에서 해제 |
| ~~TMonitor.GetInfo AV~~ | 32 | ✅ MonitorFromPoint double-unref 근본 버그 수정 + GetMonitorInfo fallback |
| ~~ChangeBounds 좌표 이상~~ | 32 | ✅ 모니터 API 수정으로 자동 해소 (정상 좌표 제공) |
| ~~GTK3 C 스텁 잔존~~ | 32 | ✅ `gtk3_stubs.c` 전체 삭제 (1388줄). GTK4 네이티브 API로 완전 전환 |
| ~~GTK3 죽은 코드~~ | 32 | ✅ `UpdateSysColorMap_GTK3` 171줄 삭제, `Gtk4MainEventLoop` 스텁 제거 |
| ~~GTK3 바인딩 잔재~~ | 32 | ✅ lazgtk4.pas TGtkMenuBar 스텁 제거, gtk_container_resize_children 제거, GTK3 COMPAT 주석 |
| ~~ScrollBox/Frame 미등록~~ | 32 | ✅ `gtk4wsfactory.pas`에서 ScrollBox, CustomFrame Factory 등록 활성화 |
| ~~Dialog.InitializeWidget~~ | 34 | ✅ SetCallbacks 누락 수정, GTK3→GTK4 시그널 수정 (`delete-event`→`close-request`) |
| ~~SetCursorPos 미구현~~ | 34 | ✅ X11: dynlibs→XWarpPointer 구현 (Wayland: 미지원 — 플랫폼 제한) |
| ~~GetCmdLineParamDescForInterface~~ | 34 | ✅ GTK4 CLI 옵션 5개 등록 |
| ~~SetvImage Double Free~~ | 35 | ✅ `FvImage := AValue` 할당 누락으로 이중 해제 → 수정 |
| ~~콜백 안전성 6건~~ | 35 | ✅ Gtk4PaintAreaDraw/MapWidget/WidgetHide/Show에 `Gtk4IsLiveWidgetPointer`, ProgressPulseTimeout에 `Gtk4IsWidget`, UpdateMemoCursorCB/SelLengthCB에 nil 가드 |
| ~~QueryWSEventCapabilities~~ | 35 | ✅ Open/Save/SelectDirectory/Color/Font 다이얼로그 5개 클래스에 `[cdecWSPerformsDoShow]` |
| ~~ClipboardFormatNeedsNullByte~~ | 35 | ✅ 선언+구현 추가 (GTK2 패리티, `Result := False`) |

#### B. Session 33 종합 점검 결과 — 구현 필요 항목 (✅ 전체 완료)

> GTK2/Qt5 교차 비교 + 교차 검증으로 오탐 제거 후 확정된 실제 갭 목록. **7개 항목 모두 Session 33에서 구현 완료.**

| 우선순위 | 항목 | 파일 | 설명 | 상태 |
|----------|------|------|------|------|
| **1** | gtk4wsdialogs.pp GTK3 죽은 코드 제거 | `gtk4wsdialogs.pp` | TFileSelHistoryEntry 삭제, gtkDialogSelectRowCB/GTKDialogMenuActivateCB 삭제 (~100줄) | ✅ |
| **2** | ListView SelectAll 구현 | `gtk4wscomctrls.pp` | `gtk4_selection_model_select_all`/`unselect_all` 사용 | ✅ |
| **3** | RegisterCustomGrid 활성화 + WS 클래스 구현 | `gtk4wsfactory.pas`, 신규 `gtk4wsgrids.pp` | GetEditorBoundsFromCellRect + Invalidate 구현 | ✅ |
| **4** | GetBitmapBits/GetDIBits 구현 | `gtk4winapi.inc` | TGtk4Image.bits에서 System.Move로 픽셀 데이터 복사 | ✅ |
| **5** | SetSysColors 구현 | `gtk4winapi.inc` | SysColorMap[] 배열 직접 업데이트 | ✅ |
| **6** | SpinEdit SetEditorEnabled 구현 | `gtk4wsspin.pp` | `gtk_editable_set_editable` 사용 | ✅ |
| **7** | GetFontLanguageInfo 구현 | `gtk4winapi.inc` | Pango 레이아웃 DBCS 휴리스틱 (GTK2 패턴 동일) | ✅ |

#### B-1. 교차 검증으로 확인된 오탐 (실제로는 구현됨)

| 항목 | 초기 보고 | 실제 확인 |
|------|-----------|-----------|
| SpinEdit GetSelStart/Length | "미구현" | ✅ gtk4wsspin.pp:72-117에 완전 구현 |
| ListBox SetColor/SetFont | "미구현" | ✅ TGtk4WSWinControl에서 상속 (gtk4wscontrols.pp) |
| GroupBox SetColor/SetFont/SetText | "미구현" | ✅ TGtk4WSWinControl에서 상속 |
| ScrollBar ShowHide | "미구현" | ✅ TGtk4WSWinControl에서 상속 |
| Form ScrollBy | "미구현" | ✅ TGtk4WSWinControl에서 상속 (gtk4wscontrols.pp:522-567) |
| Memo SetAlignment | "미구현" | ✅ gtk4wsstdctrls.pp:1252-1258에 구현 |
| CreateBrushIndirect 해치 | "미지원" | ✅ TGtk4Brush로 lbStyle/LogBrush 전체 보존 |
| IntersectClipRect | "스텁" | ✅ CreateRectRgn+CombineRgn(RGN_AND)+SelectClipRGN 실제 구현 |
| CallWindowProc | "스텁" | ✅ g_object_get_data('lclwndproc') → TWndMethod 디스패치 |
| StatusBar SetSizeGrip | "빈 구현" | ✅ 의도적 no-op (GTK4가 GtkStatusBar 제거, WM이 처리) |
| ComboBox GetText | "미구현" | 기본 클래스 위임으로 동작 |
| Memo AppendText | "미구현" | TStrings 인터페이스로 동작 |

#### C. 현재 남은 작업

**C-1. IDE 런타임 안정화 (Phase 7.4~7.6)**

| 우선순위 | 이슈 | 파일/영역 | 설명 |
|----------|------|-----------|------|
| **높음** | IDE xvfb 기능 테스트 | IDE 전체 | xvfb 환경에서 IDE 초기화 완료 여부 확인 — 폼 생성, 에디터, 프로젝트 로드 |
| **높음** | GtkDialog transient parent 경고 | `gtk4wsdialogs.pp` | `GtkDialog mapped without a transient parent` |
| **중간** | IDE GUI 환경 테스트 | IDE 전체 | 실제 X11/Wayland 디스플레이에서 IDE 구동, GtkInspector 디버그 |
| **중간** | LCL 테스트 스위트 | `lazarus/test/` | 기존 LCL 테스트를 GTK4 백엔드로 실행 |
| **낮음** | g_regex_match_full 1건 | GTK4 내부 | GTK4 CSS 파싱 내부 assertion — 코드 외부 원인, 기능 영향 없음 |

**C-2. 코드 품질 — 잠재 개선 항목**

| 우선순위 | 이슈 | 파일/영역 | 설명 |
|----------|------|-----------|------|
| **낮음** | lazgtk4.pas GTK3 호환 스텁 198개 | `lazgtk4.pas` | "Not supported in GTK4" 프로시저. API 호환 shim으로 기능 영향 없음. 제거 시 외부 코드 호환성 문제 가능 |
| **낮음** | TGtkContainer/TGtkBin 타입 계층 | `lazgtk4.pas` | GTK3 상속 shim. 20+ 타입 의존으로 제거 불가, GTK3 COMPAT 주석 유지 |
| **낮음** | DragImageListResolution 스텁 | `gtk4wscontrols.pp` | BeginDrag/DragMove/EndDrag 등 전체 스텁. GTK4/Wayland에서 팝업 위치 지정 불가 (GTK2/Qt5도 제한적) |

#### A-1. GTK assertion 방어 코드 — ✅ LCL full rebuild 검증 완료

Session 29에서 8건의 방어 코드를 적용하고 **LCL full rebuild로 검증 완료**.

빌드 명령 (LCL 소스 경로 사용, PPU 리빌드 포함):
```bash
cd /usr/src/lazarus4_build/LCL_GTK4/gtk4test
ppcx64 -B -dgtk4 \
    -Fi../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl \
    -Fu../lazarus/lcl/forms \
    -Fu../lazarus/lcl/interfaces/gtk4 \
    -Fu../lazarus/lcl/interfaces/gtk4/gtk4bindings \
    -Fu../lazarus/lcl/widgetset \
    -Fu../lazarus/lcl/units/x86_64-linux \
    -Fu../lazarus/components/lazutils \
    -Fu../lazarus/packager/units/x86_64-linux \
    -Fu../lazarus/components/freetype/lib/x86_64-linux \
    gtk4test.lpr
# 결과: 211,770 lines, 0 errors, 47 warnings, 240 notes
```

적용된 수정:

| # | 파일:위치 | 수정 내용 | 대상 assertion | 결과 |
|---|-----------|----------|---------------|------|
| 1 | `gtk4widgets.pas:9118-9134` | `getHorizontalScrollbar`/`getVerticalScrollbar`에 `if Result <> nil then` 가드 | `g_object_set_data: G_IS_OBJECT` | ✅ 해소 |
| 2 | `gtk4widgets.pas:5806-5814` | `SetScrollBarsSignalHandlers`에 scrollbar nil 체크 | `g_signal_connect_data(nil, ...)` | ✅ 해소 |
| 3 | `gtk4widgets.pas:6739,6759` | CSS `PgChar('')` → `PgChar('* {}')` | `g_regex_match_full: string != NULL` | ✅ 기여(3→1) |
| 4 | `gtk4widgets.pas:2791-2805` | `ApplyWidgetCss` 빈 문자열 → `'* {}'` 폴백 | `g_regex_match_full: string != NULL` | ✅ 기여(3→1) |
| 5 | `gtk4object.inc:457-458` | `LoadCSSTheme` 빈 경로 → `load_from_data('* {}')` | `g_regex_match_full: string != NULL` | ✅ 기여(3→1) |
| 6 | `gtk4object.inc:8-20` | `Gtk4PollFunction` 반환값 `Gtk4MPF` 캡처 | 정확성 수정 (assertion 아님) | ✅ 적용 |
| 7 | `gtk4widgets.pas:6808` | `Gtk4CV_FactoryDataDestroy` TGClosureNotify 시그니처 수정(+PGClosure) | 컴파일 에러 | ✅ 해소 |
| 8 | `gtk4widgets.pas:7665` | `SetColumnImage` FIsColumnView 가드 추가 | `gtk_tree_view_get_column` ×3 | ✅ 해소 |

검증 결과 (headless, xvfb-run):
```
# gtk4test (Session 29):
EXIT=0, 24 widgets, TimerAutoExit fired, COMPLETE
g_regex_match_full ×1 — GTK4 내부 CSS 파싱 (코드 외부 원인, 기능 영향 없음)
gtk_editable_insert_text — ✅ 완전 해소
g_object_set_data — ✅ 완전 해소
gtk_tree_view_get_column — ✅ 완전 해소

# IDE (Session 32 — MonitorFromPoint double-unref 수정 후):
EXIT=124 (timeout 15초), 0 exception, 0 GLib assertion
g_object_ref assertion — ✅ 완전 해소 (근본 원인: MonitorFromPoint double g_object_unref)
gdk_monitor_get_geometry assertion — ✅ 완전 해소
GtkDialog mapped without transient parent ×1 — 경미 (기능 영향 없음)
```

#### A-2. Application.Terminate hang — ✅ Session 30에서 해결

**증상**: `Application.Terminate` 호출 후 프로세스 미종료 (timeout 30초 후 exit 124).

**원인**: `AppTerminate`가 `g_main_context_iteration` 콜 스택 내부(타이머 콜백)에서 `FGtk4Application`을 해제 → GLib main context가 orphaned source 참조 → `AppProcessMessages`의 `while g_main_context_pending` 루프 hang.

**해결 (Session 30)**:
1. `AppTerminate`를 no-op으로 변경 — GtkApplication 해제 코드 제거
2. GtkApplication quit+release+unref를 `Destroy`로 이동 — RunLoop 종료 후 안전 실행
3. gtk4test에서 `Halt(0)` → `Close` 복원 — 정상 LCL 종료 경로 사용

**종료 경로**: `Close` → `CloseQuery` → `Terminate` (FTerminated:=True) → `AppTerminate` (no-op) → `AppProcessMessages` 정상 반환 → `RunLoop` `until Terminated` 탈출 → `Destroy` → GtkApplication cleanup.

#### B. 낮은 우선순위

| 이슈 | 파일 | 설명 |
|------|------|------|
| MDI 지원 | `gtk4wsforms.pp` | 8개 메서드 미구현. GTK는 MDI 미지원 — GTK2/Qt5도 동일 |
| ComboBox DropDownCount/ItemHeight | `gtk4wsstdctrls.pp` | GtkComboBox/GtkDropDown에 해당 API 없음 |
| ListBox ColumnCount/ScrollWidth | `gtk4wsstdctrls.pp` | GtkTreeView에 해당 개념 없음 |
| PeekMessage / EnableScrollBar / SetTextCharacterExtra | `gtk4winapi.inc` | GTK2/Qt5도 동일 미구현 |
| AdaptBounds | `gtk4wscontrols.pp:130` | 빈 구현 |

#### C. 플랫폼 한계 (구현 불가)

| 이슈 | 설명 |
|------|------|
| SetWindowRgn | GTK4가 shaped window 아키텍처 수준 제거 |
| 드래그 이미지 시각화 | GTK4/Wayland에서 팝업 위치 지정 불가 (드래그 기능 자체는 정상) |
| SetCursorPos (Wayland) | GTK4/Wayland 커서 워프 API 제거. X11에서는 XWarpPointer로 동작 (Session 34) |
| MenuItemSetRightJustify | GTK4 GtkPopoverMenuBar 우측 정렬 미지원 |

#### D. 장기 / 최적화

| 이슈 | 설명 |
|------|------|
| GtkSnapshot 네이티브 렌더링 | 현재 cairo 폴백. GPU 가속 GskRenderNode 직접 사용 검토 |
| 고성능 행 색상 | Per-Cell CssProvider 완료. Custom GType+Snapshot 옵션 |
| gtk4wsextctrls.pp 빈 클래스 | 15개 빈 WS 클래스. LCL 기본 구현으로 동작하나 네이티브 최적화 여지 |

#### E. Deprecated GTK3 API 잔존

**Session 32에서 대폭 정리 완료:**
- ~~`gtk3_stubs.c`~~ — **삭제** (1388줄 C 스텁 전체 제거)
- ~~`UpdateSysColorMap_GTK3`~~ — **삭제** (171줄 `{$IF 0}` 죽은 코드)
- ~~`Gtk4MainEventLoop`~~ — **삭제** (미사용 스텁 프로시저)
- ~~`TGtkMenuBar` 스텁 메서드~~ — **삭제** (new/new_from_model/get/set_pack_direction 등 6개)
- ~~`gtk_container_resize_children`~~ — **삭제** (external 선언)
- `TGtkContainer`/`TGtkBin` — GTK3 COMPAT 주석 추가 (상속 계층 shim으로 유지, 20+ 타입 의존)

듀얼 패스 아키텍처로 의도적 유지:
- **GtkTreeView/GtkListStore/GtkCellRenderer**: ComboBox(편집 가능) 경로
- **GtkIconView**: ListView fallback 참조 (실질 호출은 GtkGridView로 대체 완료)

### 5.4 Phase 6~8 로드맵

#### Phase 6: 런타임 검증 및 안정화 (Session 27~30) — ✅ 전체 완료

| 단계 | 작업 | 상태 | 결과 |
|------|------|------|------|
| 6.1 | gtk4test 실제 실행 | ✅ 완료 | 24개 위젯 headless 검증 (xvfb-run + TTimer 3초 자동종료), exit code 0 |
| 6.2 | 위젯별 기능 테스트 | ✅ 완료 | FormCreate → FormPaint → TimerAutoExit 전체 라이프사이클 정상 |
| 6.3 | 메모리 누수 점검 | ✅ 완료 | heaptrc: ColumnInsert factory 누수 해소 (`@Gtk4CV_FactoryDataDestroy` 연결) |
| 6.4 | GtkInspector 디버그 | ⏭ 보류 | headless 환경에서 불가, 향후 GUI 세션에서 수행 |
| 6.5 | 버그 수정 사이클 | ✅ 완료 | ScrollBar PGtkRange SEGFAULT, CheckListBox WS GetState 무한재귀, SpinEdit Gtk4IsEntry, ColumnInsert 누수, TTimer 미발동 — 총 5건 |
| 6.6 | GTK assertion 해소 | ✅ 검증 완료 | 방어 코드 8건 적용, LCL full rebuild 검증 — 원래 3건 중 2건 해소, TreeView 3건 추가 해소, 잔존 1건(GTK4 내부) |
| 6.7 | AppTerminate hang | ✅ 완료 | AppTerminate→no-op, GtkApplication 해제를 Destroy로 이동 (Session 30) |

#### Phase 7: Lazarus IDE 통합 (Session 30~)

| 단계 | 작업 | 상태 | 결과 |
|------|------|------|------|
| 7.1 | lpGtk4 플랫폼 등록 | ✅ 완료 | `lclplatformdef.pas`에 `lpGtk4` 이미 존재, `Makefile.fpc` dirs에 `gtk4` 추가 |
| 7.2 | 패키지 등록 | ✅ 완료 | `lcl.lpk`: BuildMacros Item15, Files 47개(Item549~595), Variant `_Item13`, IncludePath. `fpmake.pp`: Dependencies+ImplicitUnit 66개 |
| 7.3 | Lazarus IDE 자체 빌드 | ✅ 완료 | `make all LCL_PLATFORM=gtk4` 성공 (142MB ELF, `libgtk-4.so.1`) |
| 7.3.1 | 모니터 열거 API 수정 | ✅ 완료 | MonitorFromPoint double-unref 근본 버그 수정, GetMonitorInfo/EnumDisplayMonitors/GetPrimaryMonitorGeometry fallback. IDE 15초 xvfb — 0 exception, 0 GLib assertion |
| 7.4 | IDE 런타임 안정화 (headless) | 미시작 | xvfb 환경에서 IDE 기능 테스트 — 폼 생성, 에디터, 프로젝트 로드 등 |
| 7.5 | IDE 런타임 안정화 (GUI) | 미시작 | 실제 디스플레이 환경에서 IDE 기능 테스트 — GtkInspector, 이벤트, 위젯 상호작용 |
| 7.6 | LCL 테스트 스위트 | 미시작 | `lazarus/test/` 기존 테스트를 GTK4 백엔드로 실행 |

#### Phase 8: 배포 준비

| 단계 | 작업 | 설명 |
|------|------|------|
| 8.1 | X11/Wayland 듀얼 테스트 | `GDK_BACKEND=x11`과 `GDK_BACKEND=wayland` 양쪽에서 전체 위젯 동작 확인. Wayland 특이사항: 창 위치 지정 제한(`gtk_window_move` 제거), 팝업 좌표계 차이, 클립보드 포커스 요구, DnD 프로토콜 차이. X11 특이사항: GdkX11Surface 타입 캐스트, XWayland 폴백 경로 |
| 8.2 | 멀티 배포판 테스트 | Ubuntu, Fedora, Arch 등에서 GTK4 버전별(4.6~4.14) 호환성 확인. 버전별 API 가용성 차이(4.12+ scroll_to, GtkColumnViewRow 등) 대응 |

### 5.5 수정된 파일 목록

| 파일 | 주요 변경 |
|------|----------|
| `lazgtk4_compat.pas` | GTK4 전용 바인딩 200+개 (Modern Widget 108개 + GtkBitset/GtkGridView/GtkCustomSorter/graphene + GdkToplevel state + gtk4_scrollbar_get/set_adjustment + gtk4_spin_button_get/set_text 등) |
| `lazgsk4.pas` | GskRenderNode/GskRenderer/GskTransform 타입 |
| `gtk4widgets.pas` | 위젯 계층(44개), TGtk4DropDown, GtkColumnView/GtkGridView 마이그레이션, Sort Indicator, ListBox/CheckListBox→GtkListView, CSS 스타일링, 캐럿, Factory pick 메타데이터(GridView/OwnerDraw), IsIconic(GdkToplevel), **ScrollBar GTK4 상속 수정**(PGtkRange→gtk4_scrollbar_get_adjustment), **Range ScrollBar 가드**, **Scrollbar nil 가드**(g_object_set_data/g_signal_connect_data), **CSS 빈 문자열 가드**(`'* {}'`), **ApplyWidgetCss 빈 문자열 가드**, **FactoryDataDestroy TGClosureNotify 시그니처 수정**, **SetColumnImage FIsColumnView 가드**, **콜백 안전성**(Session 35: Gtk4PaintAreaDraw/MapWidget/WidgetHide/Show에 Gtk4IsLiveWidgetPointer, ProgressPulseTimeout에 Gtk4IsWidget) |
| `gtk4objects.pas` | ApplyFont, eraseRect, **SetvImage Double Free 수정**(Session 35) |
| `gtk4procs.pas` | 키 변환 유틸, 스타일 프로빙, SetGlobalCursor |
| `gtk4int.pas` | TGtk4CaretInfo, FCaret/FWaitHandles |
| `gtk4private.pas` | TGtkListStoreStringList, TGtkStringListStrings, **타이머 콜백 nil 가드**(Session 35: UpdateMemoCursorCB/UpdateMemoSelLengthCB) |
| `gtk4winapi.inc` | WinAPI 호환 레이어 (캐럿, 리전, 좌표 매핑, **SetScrollInfo/GetScrollInfo gtk4_scrollbar_get_adjustment 수정**, **모니터 API 전면 수정**: GetMonitorInfo(fallback+primary), MonitorFromPoint(double-unref 해소), EnumDisplayMonitors(synthetic), GetPrimaryMonitorGeometry(validation), **ClipboardFormatNeedsNullByte**(Session 35)) |
| `gtk4lclintf.inc` | RawImage, 이벤트 핸들러, 프로세스 핸들러 |
| `gtk4object.inc` | 캐럿 블링크, 시스템 색상, **Gtk4PollFunction 반환값 수정**, **LoadCSSTheme 빈 경로 수정**, **AppTerminate→no-op + Destroy에서 GtkApplication 해제** |
| `gtk4wscomctrls.pp` | StatusBar, ListView WS (GtkColumnView/GtkGridView 분기, pick-based hit-test) |
| `gtk4wschecklst.pp` | CheckListBox WS (GtkListView factory: state→LCL, queue_draw), **GetState/GetItemEnabled 캐시 직접 접근**(클래스 크래커, try/except 가드) |
| `gtk4wsstdctrls.pp` | ComboBox WS (GtkDropDown 분기), Edit/Memo, ListBox WS (GtkListView+TGtkStringListStrings) |
| `gtk4wscontrols.pp` | PaintTo(GtkSnapshot), SetPos/SetSize |
| `gtk4wsdialogs.pp` | 파일 다이얼로그(GFile), TPreviewFileDialog, History, ColorDialog(GtkColorChooser set_rgba+add_palette), **QueryWSEventCapabilities 5개 클래스**(Session 35) |
| `gtk4wsforms.pp` | 파일 드롭(GtkDropTarget) |
| `gtk4wsmenus.pp` | GMenu/GAction 메뉴 시스템 |
| `gtk4wstrayicon.pas` | SNI D-Bus 직접 구현 |
| `gtk4wsfactory.pas` | TrayIcon 등록, **ScrollBox/CustomFrame 등록 활성화** |
| `lazgtk4.pas` | GTK4 바인딩. **Session 32**: TGtkMenuBar 스텁 6개 제거, `gtk_container_resize_children` 제거, TGtkContainer/TGtkBin/TGtkMenuShell/TGtkMenuItem에 GTK3 COMPAT 주석, phantom field 경고. 순 ~1000줄 감소 |
| `lazgdk4.pas` | GDK4 바인딩 정리. Session 32에서 최적화 |

### 5.6 GTK4 상속 변경 참조표

Phase 6 런타임 검증에서 발견된 GTK3→GTK4 위젯 상속 변경:

| 위젯 | GTK3 상속 | GTK4 상속 | 영향 | 수정 |
|------|-----------|-----------|------|------|
| GtkScrollbar | GtkRange → GtkWidget | GtkWidget 직접 | `PGtkRange` 캐스트 SEGFAULT | ✅ `gtk4_scrollbar_get_adjustment` 전면 교체 (`gtk4widgets.pas`, `gtk4winapi.inc`, `lazgtk4_compat.pas`) |
| GtkSpinButton | GtkEntry → GtkEditable → GtkWidget | GtkWidget 직접 (GtkEditable 인터페이스) | `PGtkEntry` assertion 실패 | ✅ `TGtk4Entry` 메서드에 `Gtk4IsEntry(Widget)` 가드 추가, SpinEdit 재활성화 |

**CheckListBox WS GetState 무한재귀**: `checklst.pas:307` → WS `GetState` → `ACheckListBox.State[AIndex]` → `checklst.pas:307` (무한 루프 → 스택 오버플로). 해결: 클래스 크래커(`TCheckListBoxCracker`)로 LCL 캐시(`GetCachedData`) 직접 접근, `try/except` 가드 추가 (`gtk4wschecklst.pp`).

### 5.7 Phase 6 검증 위젯 목록

Session 27~30 headless 테스트 (xvfb-run, TTimer 3초 자동종료, exit code 0, 정상 종료):

| # | LCL 위젯 | GTK4 네이티브 | 상태 |
|---|----------|--------------|------|
| 1 | TMainMenu | GMenu / GAction / GtkPopoverMenuBar | ✅ |
| 2 | TLabel | GtkLabel | ✅ |
| 3 | TButton (BtnClick) | GtkButton | ✅ |
| 4 | TEdit | GtkEntry | ✅ |
| 5 | TCheckBox | GtkCheckButton | ✅ |
| 6 | TMemo | GtkTextView | ✅ |
| 7 | TButton (Button2) | GtkButton | ✅ |
| 8 | TButton (DialogButton) | GtkButton | ✅ |
| 9 | TPageControl | GtkNotebook | ✅ |
| 10 | TTabSheet ("StdCtrls") | GtkNotebook page | ✅ |
| 11 | TTabSheet ("ComCtrls") | GtkNotebook page | ✅ |
| 12 | TComboBox (csDropDown) | GtkComboBox (GtkTreeView 경로) | ✅ |
| 13 | TComboBox (csDropDownList) | GtkDropDown (GtkStringList) | ✅ |
| 14 | TListBox | GtkListView | ✅ |
| 15 | TCheckListBox | GtkListView (GtkCheckButton factory) | ✅ |
| 16 | TScrollBar | GtkScrollbar (GtkWidget 직접) | ✅ |
| 17 | TGroupBox | GtkFrame | ✅ |
| 18 | TPanel | GtkBox | ✅ |
| 19 | TTrackBar | GtkScale (GtkRange) | ✅ |
| 20 | TStatusBar | GtkBox + panels | ✅ |
| 21 | TListView (vsReport, Checkboxes) | GtkColumnView | ✅ |
| 22 | TProgressBar | GtkProgressBar | ✅ |
| 23 | TToolBar (3 buttons + separator) | GtkBox | ✅ |
| 24 | TSpinEdit | GtkSpinButton (GtkEditable 인터페이스) | ✅ |

## 6. 2026-09-02 세션 — `gtk4-clipboard` 브랜치 (KControls 멀티바이트 클립보드/선택/IM 협업)

KControls(`/mnt/USERS/onion/DATA_ORIGN/Workspace/KControls`, 브랜치 `integration-fixes`)의 GTK4/QT5
클립보드·선택·IME 검증(하네스 `tests/kmemo_cliptest`, Xvfb + xdotool 실제 키 입력)에서 드러난 GTK4 위젯셋
결함을 고쳤다. 설계·codex 교차검토·판정표·결과는 KControls의 `PHASE4_LCLGTK4_DESIGN.md`,
`PHASE6_GTK4_PASTEMSG_DESIGN.md`, `PHASE7_GTK4_SELSTART_DESIGN.md`(§0–22)에 있다.

| 커밋 | 내용 | 파일 |
|---|---|---|
| f438aa0 | 클립보드: 소유권 상실 감지(`changed`), UTF-8 텍스트 프로바이더(bare `text/plain`=ASCII 문제), `text/plain` 별칭 | `gtk4winapi.inc` |
| b5ee8e7 | 네이티브 에디트의 cut/copy/paste 액션 → `LM_CUT/LM_COPY/LM_PASTE`(GTK2 동등) | `gtk4widgets.pas` |
| 6800df4 | TEdit/TSpinEdit `SelStart`+`SelLength`를 한 번의 `select_region`으로(X11 PRIMARY 해제/재획득 race로 `SelectAll` 소실); 선택 없을 때 `getSelStart`=커서 | `gtk4widgets.pas` |
| 2e3c84c | 편집 콤보에 같은 트랜잭션 | `gtk4widgets.pas`, `gtk4wsstdctrls.pp` |
| d646a38 | 편집 콤보 엔트리에 IM 커밋 순서 보정(fcitx5 raw 키 선삽입) — `TGtk4Entry`와 동일 기제 복제 | `gtk4widgets.pas` |
| 7bde741 | 콤보 드롭다운 트랜잭션: hover/화살표=미리보기, 클릭/Return=확정(`LM_CHANGED`+`LM_SELCHANGE`), Esc/바깥 클릭=취소·복원 | `gtk4widgets.pas` |
| db38c86 | `CBN_DROPDOWN` 1회 전송(`notify::visible`, GTK2 `popup-shown` 동일) | `gtk4widgets.pas` |
| e66660e | `TODO.md`(업스트림 Qt5 B9/B7/B8, 환경 E1) | `TODO.md` |

- 검증: 각 커밋마다 `make -C lcl intf LCL_PLATFORM=gtk4`(경고 0 신규), KControls 하네스(최종 GTK4 248/0, QT5
  226/4 기준선), `example_gtk4_editmemo_validation`/`example_gtk4_stdctrls_validation` 12초 실행, `make ide` +
  xvfb 15초 실행, 사용자 실 X11+fcitx5 수동 검증(TEdit/콤보/TKMemo/TMemo).
- 미작업(결정): 일반 문자 키 `OnKeyDown` 미전달(IM 컨텍스트가 press 소비). `TODO.md` 참조.
