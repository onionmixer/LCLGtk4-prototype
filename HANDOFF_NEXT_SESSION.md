# GTK4 LCL - 다음 세션 인수인계 (작성 2026-07-02 S75, 갱신 2026-07-12 S82)

이 문서 하나로 다른 세션에서 작업을 이어갈 수 있도록 정리했습니다.
상세 이력은 프로젝트 메모리(`MEMORY.md`, `session74.md`, `session75.md`)와
저장소 문서(`ANAYLIZE_gtk4_need_implementation.md`, `LCL_GTK4_DEV.md`)에 있습니다.

## 0. 저장소 / 빌드 / 테스트

- **Repo root**: `/mnt/USERS/onion/DATA_ORIGN/Workspace/LCL_GTK4`
- **GTK4 위젯셋**: `lazarus/lcl/interfaces/gtk4/` (핵심 파일 `gtk4widgets.pas`,
  `gtk4wsforms.pp`, `gtk4winapi.inc` 등)
- **바인딩**: `lazarus/lcl/interfaces/gtk4/gtk4bindings/`
  (`lazgtk4.pas`, `lazgtk4_compat.pas`, `lazgdk4.pas`, `lazglib2.pas` 등)
- **Qt5 레퍼런스**: `lazarus/lcl/interfaces/qt5/` (동작 비교 기준)
- **빌드** (cwd = `.../LCL_GTK4/lazarus`):
  - `make lcl LCL_PLATFORM=gtk4`
  - `make bigide LCL_PLATFORM=gtk4` (IDE 바이너리 = `lazarus/lazarus`)
  - `make lcl LCL_PLATFORM=gtk2` (회귀 확인용)
- **GUI 테스트는 사람이 직접** 실행해 확인해야 함(에이전트가 실행 불가).
  변경 후 항상 세 빌드를 통과시키고 사용자에게 구체적 테스트 항목을 요청할 것.
- **빌드 주의**: `make lcl` 첫 시도에서 드물게 `undefined reference to 'main'`
  링크 에러가 뜰 수 있는데(중간 빌드 상태 아티팩트), **재실행하면 정상**.
  실제 컴파일 에러는 `.pas(line,col) Error:` 형태로 나옴.

## 1. 현재 브랜치 상태

```
7c6a8a9 GTK4: repair IM commit ordering in TMemo — Hangul+space transpose    <- 현재 HEAD (S82)
1e32daa GTK4: enforce TEdit.NumbersOnly for typed and pasted input
59c8bd1 docs: mark HANDOFF follow-ups 1 and 4 as user-verified complete
e31efe9 GTK4: repair IM commit ordering — Hangul+space transpose in TEdit
0ac8fcd GTK4: fire OnKeyPress/UTF8KeyPress + form KeyPreview for typed TEdit chars
31f4581 GTK4: stop Form.OnKeyDown firing twice (child-unconsumed keys)
f9d9ebb docs: mark PROBLEM_LAST.md icon analysis as resolved
5e902ab docs: record 2026-07-12 GTK4 fixes in the implementation audit
5442f80 GTK4: approximate TEdit.CanUndo instead of always returning True
859a8d4 GTK4: fix TEdit.Undo — activate text.undo on the GtkText delegate
798f660 GTK4: deliver menu hover/select hints (status-bar hints) like gtk2/qt5
186a2fc GTK4: preserve a custom TPairSplitter cursor instead of masking it
d999333 GTK4: make TGroupBox client rect reflect the frame chrome and caption
--- (이전: 4e089b0 multi-column TListBox, ... 45d2bca designer undo/redo, S81 이하) ---
```
- 브랜치: `main` (S82 시점 확인 — 이전 기록의 "master"는 stale)
- 커밋 메시지 말미 규칙: `Co-Authored-By: <세션의 Claude 모델> <noreply@anthropic.com>`
  (S82는 Claude Opus 4.8)
- 작업 브랜치 `gtk4-form-designer-undo-redo`는 `45d2bca` 커밋 후 삭제됨.
- 코드 기준 워킹 트리는 깨끗함. `gtk-4.6.9/`, `lazarus/`의
  다수 벤더 `.md`는 미추적이니 **절대 `git add .` 금지** — 필요한 파일만 명시적 add.
- 커밋/푸시는 사용자가 요청할 때만.

## 2-pre0. 최근 완료 작업 (S82, 2026-07-11~12) - 최신

**정본 disposition 문서**: `lazarus/PLAN_GTK4_IMPLEMENTATION_CANDIDATE_RECHECK.md`
상단 "RE-AUDIT DISPOSITION" + "KEY-INPUT WORK" 절이 항목별 최종 판정의 정본.
키 입력 아키텍처 지식은 메모리 `gtk4-key-input-architecture.md`에 정리됨.

### S82-A. RECHECK 백로그 재감사 + 완결

- **재감사(4-병렬 코드/커밋 대조)**: RECHECK의 confirmed_fix_candidate 다수가
  이미 이전 커밋으로 해결돼 있었음(stale 문서). 아이콘 미표시(`de4145d`),
  ListView vsSmallIcon/StateImages, Popup Alignment, radio 메뉴, TextHint clear,
  PairSplitter SetPosition/RemoveSide, ProgressBar.GetPosition, 파일다이얼로그
  Escape, FontDialog PreviewText 등 — 문서만 정정. 진짜 미해결 2건만 남았었음.
- **`d999333`**: TGroupBox client rect가 프레임 chrome/캡션 반영 (5부 수정:
  SetupPaintArea expand/fill, SetBounds skip-force, getClientRect overlay
  fallback, Gtk4MapWidget invalidate, setText idle 재동기화). 실기 152↔178 확인.
- **`186a2fc`**: TPairSplitter 커스텀 커서 보존 — Get/SetSplitterCursor 둘 다
  False 반환("no internal splitter" 계약)으로 inherited 커서 라운드트립.
- **`798f660`**: 메뉴 hover/select 힌트(상태바 힌트) 구현. GTK4 모델 메뉴는
  per-item 식별자가 없음(GtkModelButton의 action-name이 전 생명주기 null —
  GtkMenuTrackerItem private 구동; gtk-4.6.9 소스+codex 교차검토로 확정) →
  렌더된 버튼의 caption label 매칭 + motion/focus 컨트롤러 + popover map 훅.
  한계: 중복 caption은 첫 매칭. order-매핑은 section box 분할로 자체 취약해 기각.
- **`859a8d4`**: TEdit.Undo가 무동작이던 **버그** 수정 — `text.undo` 액션은 내부
  GtkText delegate에 설치되는데 외부 GtkEntry에 activate하고 있었음.
  `gtk_editable_get_delegate`(신규 바인딩) 경유로 수정.
- **`5442f80`**: TEdit.CanUndo를 baseline 근사로(마지막 프로그램적 setText와
  비교; pristine=False). 정확한 조회는 GTK 구조상 불가(gtktext.c에서 확정).
- **`f9d9ebb`**: PROBLEM_LAST.md(아이콘 미표시)에 해결 배너 — `de4145d`가 기해결.
- FontDialog: OK 흐름 정상 실증(헤드리스로 폰트 선택→OK→적용 확인).
  `fdApplyButton`만 backend 제약(GtkFontChooserDialog에 apply 버튼 없음) —
  다이얼로그 자체 preview가 있어 실용 가치도 낮음. 사용자 인정으로 종결.

### S82-B. 텍스트/키 입력 개선 시리즈 (qt5 모델 교차 참고)

- **`31f4581`**: Form.OnKeyDown 이중발화 수정 — 자식이 미소비한 키(F1 등)가
  버블돼 폼 컨트롤러가 재전달하던 것을 ActiveControl 가드로 억제.
- **`0ac8fcd`**: **TEdit 문자키 OnKeyPress/OnUTF8KeyPress/폼 KeyPreview 구현**.
  GtkText가 printable press를 TARGET에서 소비해 버블 LCL 컨트롤러가 못 받고,
  wrapper GtkEntry의 editable 시그널은 타이핑에 발화 안 함(GTK 규정: delegate
  시그널은 delegate에 연결) → **delegate의 insert-text에서 키 이벤트 도출**
  (qt5의 commitString-유래 모델). 기록전용 capture 키 컨트롤러로 키-유발
  삽입만 게이트(Ctrl/Alt 코드·paste·프로그램 setText 제외). LM_CHAR Result는
  소비 의미 아님(CharCode=0만 소비) — 이걸 오해하면 전 문자가 삼켜짐.
- **한글 "한글이 "→"한글 이" 근본원인 확정**: 순수 C GTK4 + PyGObject 대조앱
  (Entry/TextView 모두)에서 동일 재현 → **LCL 결함 아닌 fcitx5-frontend-gtk4 +
  GTK4.6 스택의 전달 순서**(조합 외 키를 커밋보다 먼저 forward). GNOME 정상
  체감은 GTK3 앱(이 시스템 nautilus=GTK3) 출처. GTK4에 XIM 경로는 존재 자체가
  불가(코드에도 없음)를 확인. delegate 계측으로 시퀀스 실측
  (insert " " pos=2 → commit "이" pos=3).
- **`e31efe9`**: 위 IM 순서를 LCL이 국소 복구 — **deferral**(추측 재정렬 금지).
  capture 레코더가 대기 키의 문자를 기록, preedit 활성 중 그 문자와 동일한
  삽입만 보류 → 커밋 AFTER insert-text 핸들러에서 갱신된 position^에 flush
  (fallback: preedit-empty/focus-leave; 최악=기존 동작). 정상 순서 IM·변환형
  커밋(일본어 등)엔 no-op(codex 적대검토 반영 설계). 실기 "한글이 " 정상.
- **`1e32daa`**: TEdit.NumbersOnly를 타이핑/paste에 적용(기준선 테스트로 버그
  실증 후). CharCase는 LCL core(TCustomEdit.TextChanged)가 범용 처리라 무수정.
- **`7c6a8a9`**: **TMemo에 IM 순서 복구 이식(deferral만)**. 중요 발견:
  GtkTextView는 GtkText와 반대로 press를 버블보다 먼저 소비하지 않아
  memo의 OnKeyPress/KeyPreview/소비/Enter=#13은 **원래 작동 중**이었음 —
  이벤트 전달을 이식했더니 이중발화(계측으로 적발) → deferral만 남김.
  실기 memo/entry 한글 모두 정상, MaxLength/CharCase 무회귀.

### S82에서 실패해 되돌린 접근 (재시도 금지)

- 폼 **런타임** 키 컨트롤러의 GtkWindow 이관: 컨트롤 없는 폼에서 **먹통(hang)**.
  (디자인 컨트롤러만 window에 두는 기존 구조 유지. 컨트롤 없는 폼의 KeyPreview
  유실은 미해결 엣지케이스로 문서화.)
- entry 문자 이벤트를 raw keyval/char 블록에서 생성: IM과 경합(한글 깨짐).
- wrapper GtkEntry의 insert-text 훅: 타이핑에 발화 자체가 안 됨.
- memo에 entry식 이벤트 전달: 이중발화(버블 경로가 이미 전달 중).
- `삽입≠preedit` 판별식 deferral: 변환형 커밋(일본어) 오분류 — 대기 키 문자
  동일성 판별로 대체(codex 지적).



- **S81 `45d2bca`**: GTK4 form designer undo shortcut 수정. menu를 열기 전에는
  Ctrl+Z가 동작하지 않던 문제를 LCL GTK4 범위에서 해결했다. 계측 결과 key delivery는
  정상이고 `Screen.ActiveCustomForm=Form1`이었지만 `Application.Active=False`로 남아
  undo/redo 직전 idle 기반 command enabled 갱신이 실행되지 않는 것이 실제 실패 조건이었다.
  `Gtk4EnsureAppActive`로 focus owner 확인 시 application active 상태를 보정하고,
  undo/redo shortcut 직전 pending deferred mouse event flush + `Application.Idle(False)`
  1회 실행을 제한적으로 수행한다. 사용자 실기에서 menu 없이 Ctrl+Z undo 동작 확인.
  검증: `make lcl LCL_PLATFORM=gtk4`, `make bigide LCL_PLATFORM=gtk4`,
  `make lcl LCL_PLATFORM=gtk2`, `./cbuild` 통과. 상세: `HANDOFF_UNDO_REDO.md`.
- **S81 `c69a34a`**: GTK4 form activation 전달. toplevel form activate/inactivate를
  LCL에 전달해 form designer active state가 stale로 남는 문제를 보정했다.
- **S76 `306096f`**: 메인 창 깜박임(가로 스크롤바 외관) = X11 WM_NORMAL_HINTS 전쟁.
  프레임별 PMaxSize 재기록 제거, max 강제는 notify::default-size 스냅백으로 일원화.
- **S77 `c53f75d`**: 툴팁 표시 — WindowFromPoint 화면원점, GetClientAreaOffset
  (폼 메뉴바/노트북 탭바), 모션 dedup, _NET_WM_WINDOW_TYPE_TOOLTIP+XMoveWindow.
- **S77 `9374240`**: 팝업 메뉴 — Popup마다 fresh GtkPopoverMenu(FBox 부모),
  win32 이벤트 순서(CONTEXTMENU는 RBUTTONUP 후), setter 리빌드 idle 병합(1.1s→0.1s).
- **S78 `0f895e5`**: 메뉴 먹통(1차) — 열린 popover의 모델 리빌드 금지 가드+150ms 재시도.
- **S79 `040fc8c`**: 물리 버튼 이벤트를 최심 위젯에 1회만 딜리버(dedup).
- **S80 `4a9cadf`**: 디자이너 Del 키 컴포넌트 삭제 — 디자인 CAPTURE 키 컨트롤러를
  폼의 GtkFixed가 아닌 GtkWindow에 부착(포커스가 GtkScrolledWindow에 있으면
  키 체인이 fixed까지 안 내려가는 GTK4 디스패치 기하 문제). 상세: 메모리
  `designer-del-key-analysis.md`. 후속(별건): 폼 자체 포커스 시 런타임
  KeyPreview/OnKeyDown도 같은 기하로 유실 가능 — bubble 컨트롤러는 미이동.
- **S80 `7487e7b`**: 메뉴 먹통(2차, 간헐 폭풍/영구 프리즈) — **포커스 전달 재설계**.
  containment enter/leave의 LM 오전달 제거, 창 notify::focus-widget 단일 소스,
  popover/GtkPopoverMenuBar 내 포커스는 transient(win32 시맨틱), is-active grab-플랩
  억제+120ms 디바운스, 팝업 해제 시 포커스 save/restore, 클릭 시 GTK-실측 재동기화.
  Qt5 TQtWidgetSet.FocusChanged(qtobject.inc:958)를 참조 아키텍처로 정렬.
  상세 이력·함정: 메모리 `palette-hover-flicker-analysis.md`.
- **S80에서 실패해 롤백한 접근(재시도 금지)**: 메뉴 in-place 단일항목 모델 교체
  최적화(실기 회귀), F=nil 포커스 힐(폭풍 펌프), popover 중 focus-widget 전면 동결
  (영구 진동). Xvfb는 WM 부재로 Mutter grab/포커스 재현 불가 — 실기 계측 로그 필수.

## 2. 최근 완료 작업 (S74–75) — 이어갈 때 알아야 할 핵심

### 2a. 좌표계 (S74, `fa64186`)
`ClientToScreen`/`ScreenToClient`/`GetCursorPos`가 **X11에서 화면 절대좌표**를
반환한다. `Gtk4X11GetWindowOrigin`(XTranslateCoordinates) + CSD 오프셋
(`gtk4_native_get_surface_transform`)을 더함. Wayland에선 이 함수가 False →
toplevel-content-relative로 폴백. **마우스 EVENT 좌표(`Gtk4LegacyEventCB`의
x_root)는 여전히 content-relative** — 혼동 주의.

### 2b. X11 override-redirect 팝업 (S75, `bc63c63`)
GTK4는 `gtk_window_move`와 `GTK_WINDOW_POPUP`을 모두 제거 → 토플레벨 배치를
WM이 좌우. 코드 완성 팝업이 엉뚱한 위치에 떴다 사라지던 문제를 GTK2의
`GTK_WINDOW_POPUP` / Qt5의 `QtBypassWindowManagerHint`와 동일한 X11
`override_redirect=True`로 해결.
- `TGtk4Window.PreparePopupShow` (gtk4widgets.pas): realize → override_redirect
  설정(**반드시 map 전** — X가 map 시점에 평가) → `XMoveWindow`로 배치.
- `TGtk4Window.RaiseX11Popup`: map 후 `XRaiseWindow`(OR 창은 WM 스태킹 대상 아님).
- 바인딩: `XChangeWindowAttributes`/`XRaiseWindow` + `TX11SetWindowAttributes`
  구조체 + `X11_CWOverrideRedirect`, 기존 `InitX11SizeHints` 동적 로더에 추가.
- 판별 `Gtk4FormIsPopup` (gtk4wsforms.pp): `csNoFocus` 또는 `bsNone +
  fsStayOnTop/fsSystemStayOnTop`. **일반 THintWindow(bsNone+fsNormal)는 반드시
  제외** — OR + 항상위 툴팁이 커서 위에 뜨면 pointer enter/leave 루프 →
  컴포넌트 팔레트 hover 시 심한 깜박임. 완성 팝업과 long-line 힌트(FHint)는
  fsSystemStayOnTop을 명시하므로 stay-on-top 절로 커버됨.
- `TGtk4WSCustomForm.ShowHide`와 `TGtk4WSHintWindow.ShowHide` **두 경로 모두**에
  `Visible:=True` 직전 `PreparePopupShow` 호출, map 후 `RaiseX11Popup`.

### 2c. 디자인 모드 입력 라우팅 (S75, `bc63c63`)
- **키**: 네이티브 GtkEntry(GtkText)/GtkTextView가 GTK4 TARGET 단계에서 편집키
  (Delete 등)를 선점 → BUBBLE 단계 LCL 키 컨트롤러가 못 받아, 선택한 TEdit에서
  Delete가 컴포넌트 대신 텍스트를 지웠음. `Gtk4DesignKeyPressedCB`(CAPTURE 단계
  키 컨트롤러, `TGtk4Widget.InitializeWidget`에서 GetContainerWidget에 부착)가
  csDesigning일 때 키를 디자이너로 전달(GtkEventKey → LM_KEYDOWN →
  Designer.IsDesignMsg)하고 소비. 런타임 no-op.
- **클릭**: `Gtk4LegacyEventCB`(마우스)는 디자인 모드에서 이벤트를 소비하지
  않으므로 네이티브 위젯이 클릭 시 상태를 바꿈. 확립된 패턴(이미
  `TGtk4Button.ButtonClicked`에 있던)대로 상태변경 콜백에 `csDesigning` 가드
  추가: `Gtk4Toggled`(체크/라디오), `Gtk4EntryChanged`(스핀),
  `Gtk4ECB_EntryChanged/ButtonClicked/SelectionChanged`(콤보),
  `Gtk4RangeChanged`(트랙바), `Gtk4Calendar{Day,Month,Year}*`(캘린더),
  `Gtk4LB_SelectionChanged`/`Gtk4CLB_CheckToggled`/`Gtk4CV_SelectionChanged`/
  `Gtk4CV_CheckToggled`(리스트류). **노트북 switch-page는 의도적으로 미가드**
  (디자인 모드 탭 전환은 정상 동작, GTK2/Qt5 동일).

## 3. 미해결 / 선택 과제 (다음 세션 후보)

1. ~~**Form designer redo 및 회귀 실기 확인**~~ **완료 (2026-07-12, 사용자 실기 확인).**
   redo(`Ctrl+Y`/`Ctrl+Shift+Z`), Delete 컴포넌트 삭제, source editor undo/redo,
   Object Inspector↔form designer 전환 후 menu enabled 상태 모두 실기에서 정상 확인됨.
2. **디자인 모드 클릭의 시각 잔상** (한계): 현재 가드는 LCL 속성 오염만 막고,
   네이티브 위젯의 순간적 시각 변화(예: 체크박스가 잠깐 토글돼 보임)는 남음.
   완전 차단은 `Gtk4LegacyEventCB`에서 디자인 모드 시 마우스 이벤트를 소비
   (키 수정과 동일 방식)해야 하나, **노트북 탭 전환 예외 + 컨테이너 자식 선택
   경로 재검증**이 필요해 보류함. (PLAN_X11_OVERRIDE_REDIRECT.md의 Phase 4와
   유사한 접근.)
3. **Wayland 팝업**: override-redirect는 X11 전용. Wayland에선 transient_for
   폴백(위치 부정확 가능). 필요 시 GtkPopover 백엔드로 별도 설계
   (PLAN_X11_OVERRIDE_REDIRECT.md "옵션 2" 참고).
3b. ~~**(S82 추가) 컨트롤 없는 폼의 KeyPreview/OnKeyDown 유실**~~ —
   **해결 (`8c1516b`)**: 이관 대신 **추가** bare 키 컨트롤러(IM 컨텍스트 없음)를
   GtkWindow에 부착; 자식 포커스 시 Gtk4FormKeyBelongsToChild 가드가 중복 억제.
   실기: 컨트롤 없는 폼 키 전달 + hang 없음, F1 단일발화 회귀 통과.
3c. ~~**(S82 추가) memo OnKeyPress의 Key 교체 미반영**~~ — **해결 (`e986632`)**:
   GtkEventKey char 블록(버블, 삽입 전 실행)이 교체 결과를 TGtk4Memo에 기록,
   버퍼 insert-text 핸들러가 삽입 시 치환(Enter #13↔#10 매핑, press마다 무효화).
   "axzb"→"aZb" 검증, 이벤트 단일발화·한글 무회귀.
4. ~~**툴바 아이콘 첫 실행 클리핑**~~ **완료 (2026-07-12, 사용자 실기 확인).**
   S74의 `Gtk4PostShowResizeCB`(gtk4wsforms.pp, decorated 창 전용 idle LM_SIZE)
   로 첫 실행 시 CoolBar/컴포넌트 팔레트 아이콘 클리핑이 해소됨을 실기에서 확인.
5. `PLAN_fix_InitialSetupDialog.md`, `PROBLEM_LAST.md`(아이콘 미표시),
   `PLAN_GTK4_NO_STUBS.md` — 이번 작업과 무관한 별건 계획서(미추적). 필요 시 참조.

## 4. 반복해서 물리는 GTK4 함정 (작업 전 숙지)

- **notify::width/height, size-allocate 시그널 없음** (GTK4 < 4.12). 창 리사이즈는
  `notify::default-width/height`로만 감지 (`Gtk4WindowNotifyDefaultSizeCB`).
- **CSS max-width/max-height 미지원**(GTK3 전용). 최대 크기는 X11
  WM_NORMAL_HINTS + notify::default-size 스냅백으로만.
- **창 파괴**: 토플레벨은 `gtk_window_destroy`, 그 외 `gtk_widget_unparent`.
  `TGtkWidget.destroy_`(unparent)는 토플레벨에서 hang.
- **이벤트 전파 단계**: 네이티브 위젯 내부 핸들러는 TARGET 단계 → LCL BUBBLE
  컨트롤러보다 먼저 실행. 선점 필요 시 CAPTURE 단계 컨트롤러 사용(위 2c 참고).
- **콜백 안전성**: Data→TGtk4Widget 캐스트 콜백은 반드시
  `Gtk4IsLiveWidgetPointer`/`CanSendLCLMessage`로 검증(파괴 중 freed 객체 접근 방지).
- **자식 GObject 시그널**(selection model, adjustment, factory, IMContext 등)은
  base `DestroyWidget`의 `g_signal_handlers_disconnect_matched(FWidget)`가 못
  잡음 → 각 클래스가 `DetachEvents` override로 직접 해제.

## 5. 작업 방식 메모 (사용자 선호)

- 계획/구현 시 **확대판단 금지**, 불필요한 문서/코드 변경 금지.
- 큰 결정 전 계획서를 만들고, 별도 모델(예: sonnet)로 **교차 검토 → 재검증**
  사이클을 돌린 뒤 지적사항이 없을 때까지 반복 (지적은 코드 대조로 직접 확인).
- 상세 정본은 프로젝트 메모리에 두고, 저장소 추적 문서엔 요약만 (중복 최소화).
- rollback point 커밋을 먼저 확보한 뒤 위험한 변경 진행.
