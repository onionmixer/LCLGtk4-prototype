# PLAN: 힌트(툴팁) 미표시 + GtkEventMouseMove 좌표계 가드 수정

작성: 2026-07-02 (Session 76 후속). 배경: `PLAN_X11_SIZEHINTS_WAR.md`(완료된 깜박임
수정)의 조사 과정에서 발견된 별건 결함 1(힌트 미표시), 2(mousemove 가드)의 수정 계획.

**상태 (2026-07-03): Part A + B0 + B1(연쇄 5건) + B2(a/b/c) 구현 및 Xvfb 검증
완료, 진단 코드 제거, 빌드 3종 통과. 사용자 실기(Mutter) 검증 대기.**
Xvfb 최종 실측: 팔레트/툴바 힌트가 커서 하단 정위치에 표시(114x49+592+297),
_NET_WM_WINDOW_TYPE_TOOLTIP + WM_TRANSIENT_FOR 확인, 긴 힌트(122px)→짧은
힌트(114px) 폭 축소 확인, 팔레트 탭 클릭 전환 정상.
변경 파일: gtk4widgets.pas, gtk4winapi.inc, gtk4wscomctrls.pp, gtk4wsforms.pp
(+254/-21). B1 상세는 §B1, 탭 hit-test 정합(codex 2회 지적 반영)은
gtk4wscomctrls.pp GetTabIndexAtPos/GetTabRect.

## 0. 배경 — S76에서 확정된 사실

- **힌트는 현재 GTK4에서 전혀 표시되지 않음.** 실기 계측에서
  `TGtk4WSHintWindow.ShowHide` 호출 0회 — LCL 힌트 활성화 체인
  (DoOnMouseMove → ActivateHint → 타이머 → ShowHintWindow → ActivateSub →
  Visible:=True)의 어딘가에서 끊김. **끊긴 지점은 아직 미확정** — 본 계획의
  Phase B0가 확정한다.
- 표시 경로에도 별도의 확정 결함 3개가 있음(끊긴 지점과 무관하게 수리 필요):
  D1. 위치 미전달: 최초 표시 시 unrealized라 `TGtk4Window.SetBounds`의
      XMoveWindow 스킵(gtk4widgets.pas, `Widget^.get_realized` 조건) +
      WM_NORMAL_HINTS에 PPosition/USPosition 미설정 +
      `TGtk4WSHintWindow.ShowHide`의 set_transient_for가 GDK4 X11에서
      _NET_WM_WINDOW_TYPE_DIALOG를 유발(gtk-4.6.9/gdk/x11/gdksurface-x11.c:2682)
      → Mutter가 위치 힌트 없는 dialog를 자체 배치(부모 중앙).
  D2. `TGtk4Window.SetBounds`의 폭 보존 로직(`if CurW > AWidth then
      AWidth := CurW`)이 모든 toplevel에 적용 → 힌트 창 폭이 역대 최대로
      단조 증가(GTK는 hide 후에도 realized/크기 기억 유지 — gtkwindow.c 확인).
  D3. `TGtk4HintWindow.CreateWidget`의 `FCentralWidget.set_size_request(W,H+1)`가
      생성 시 1회뿐 → non-resizable 힌트 창의 최소 크기가 최초 힌트 크기로 고정.
- **결함 2**: `TGtk4Widget.GtkEventMouseMove`(gtk4widgets.pas:2703)의
  `if Mouse.CursorPos=MousePos then exit` — Mouse.CursorPos(스크린 좌표)와
  MousePos(OffsetMousePos 적용된 위젯 로컬 좌표)의 **서로 다른 좌표계 비교**.
  GTK2 원본은 x_root(스크린) 기준 dedup이었음. 창이 (0,0) 부근이면 두 값이
  일치해 mousemove 전멸(Xvfb에서 실측 — 합성 워프 이벤트가 전부 폐기,
  자동화 GUI 테스트 불가의 원인). 실사용에서도 이벤트 좌표와 실시간 커서
  좌표가 우연히 일치하면 move 소실 + mousemove마다 XQueryPointer 왕복 비용.
- 참고: S75가 "OR 툴팁의 pointer enter/leave 루프"로 귀속했던 팔레트 hover
  깜박임은 실제로는 WM_NORMAL_HINTS 전쟁이었음이 S76에서 판명. 단 본 계획은
  OR 재도입을 하지 않는다(TOOLTIP 타입 접근이 우선, OR은 fallback 옵션).

## 1. Part A — 결함 2: GtkEventMouseMove 가드 수정 (선행)

선행 이유: 작고 독립적이며, 수정되면 Xvfb에서 합성 마우스 이동이 동작
→ Part B의 진단·검증을 에이전트가 자동화할 수 있음(사용자 부담 감소).

A1. gtk4widgets.pas:2703의 `Mouse.CursorPos=MousePos` 비교를 제거하고
    **위젯별 직전 모션 좌표 dedup**으로 대체:
    - 필드 추가 위치: TGtk4Widget **protected** 필드 블록(gtk4widgets.pas:95
      부터 시작, FWidgetType 근처 100-110)에 `FLastMotionPos: TPoint;` +
      `FLastMotionValid: Boolean;` 추가. validity 플래그 필수 —
      (0,0) 초기값만 쓰면 첫 모션이 (0,0)일 때 오폐기.
    - 삽입 위치: GtkEventMouseMove의 기존 2703 가드 자리를 그대로 대체
      (OffsetMousePos(2698)와 Msg.XPos/YPos 설정(2700-2701) 이후).
      **dedup 키에 modifier state 포함**(좌표 동일 + state만 바뀐 모션이
      버려지면 Msg.Keys 갱신(2705)이 늦어 Shift/Ctrl 드래그 의미가 다음 픽셀
      이동까지 지연됨 — control.inc:4518 MouseMove(Shift,...) 전달 경로):
      필드에 `FLastMotionState: TGdkModifierType;` 추가하고
      `if FLastMotionValid and (MousePos.X = FLastMotionPos.X) and
       (MousePos.Y = FLastMotionPos.Y) and
       (Event^.motion.state = FLastMotionState) then exit;`
      `FLastMotionPos := MousePos; FLastMotionState := Event^.motion.state;
       FLastMotionValid := True;`
      exit 위치는 기존 가드와 동일(NO_PROPAGATION 마크(2710-2711) 이전) —
      CAPTURE 전파 의미는 현행과 불변.
    - 리셋 위치: GtkEventMouseEnterLeave(gtk4widgets.pas:2651-2667)에서
      Msg.Msg 결정 직후, NotifyApplicationUserInput(2659) 호출 **전에**
      enter/leave 공통으로 `FLastMotionValid := False`. 근거: enter/leave도
      NotifyApplicationUserInput을 호출하고 LM_MOUSEMOVE 외 메시지는
      CancelHint를 유발(application.inc:1663-1667) → enter 직후 첫 모션이
      폐기되면 힌트 타이머가 재시작되지 못함.
    - 캡처(SetCapture/ReleaseCapture, gtk4winapi.inc:4614/4376) 시 리셋은
      **이번 변경에서 하지 않음**(확정) — dedup은 "동일 좌표 반복"만
      스킵하므로 캡처 중에도 의미가 보존됨. 회귀 관찰 시에만 재론.
    - 효과: GTK2의 의도(동일 좌표 중복 이벤트 스킵)를 좌표계 일관되게 재현,
      mousemove당 XQueryPointer 왕복 제거, 합성 이벤트 정상 처리.

A2. 검증: Part A 빌드는 B0의 `-dDebugHintWindow` 빌드와 겸용한다(빌드 1회).
    판정: Xvfb에서 xdotool로 팔레트 아이콘 위 워프 후, stdout 로그에
    `TApplication.DoOnMouseMove Info.ControlHasHint=...`(application.inc:203-205
    의 ifdef 출력)가 나타나면 합성 모션이 LCL에 도달한 것 — Part A 통과.
    (수정 전에는 동일 시나리오에서 이 로그가 0건임을 S76에서 실측.)
    회귀(사용자 실기 1회): 마우스 이동/클릭/더블클릭 + **폼 디자이너에서
    컴포넌트 선택·이동·리사이즈 핸들 드래그**(LM_MOUSEMOVE 유량 증가가
    디자이너 라우팅(control.inc:2243 IsDesignMsg)에 주는 영향 확인) +
    SynEdit 드래그 선택/Shift·Ctrl 조합 드래그.

(기록만, 범위 밖) GetKeyState의 VK_RBUTTON→GDK_BUTTON2_MASK,
VK_MBUTTON→GDK_BUTTON3_MASK 매핑(gtk4winapi.inc:2971-2976)은 X11 관례
(button2=middle, button3=right)와 반대로 스왑되어 있음 — 별건 결함으로
후속 과제 목록에 추가. 단 B0 진단에서 힌트 억제 원인으로 판명되면
Part B1에서 함께 수정.

## 2. Part B — 결함 1: 힌트 미표시

### Phase B0 — 진단: 활성화 체인의 끊긴 지점 확정 (수정 금지)

- LCL을 `-dDebugHintWindow`로 재빌드(기존 LCL 내장 디버그 로그 활성화):
  `make lcl LCL_PLATFORM=gtk4 OPT=-dDebugHintWindow` (bigide도 동일 OPT).
- 내장 로그 지점(application.inc의 {$ifdef DebugHintWindow} 5곳):
  203(ActivateHint — ControlHasHint/FHintControl/Info.Control 출력),
  831/920(ShowHintWindow), 929(StartHintTimer), 951(OnHintTimer).
  **내장 로그로 추적 가능한 마지막 지점은 ShowHintWindow까지** —
  ActivateSub와 TGtk4WSHintWindow.ShowHide는 로그가 없으므로, 체인이
  ShowHintWindow 이후에서 끊긴 것으로 나오면 그 두 지점에 TEMP-DIAG 1줄씩
  추가(S76 방식, 진단 후 제거 — "LCL 공용 코드 수정 없음" 원칙의
  임시 진단 한정 예외로 허용).
- 판별표(로그 패턴 → 용의자):
  | 관찰 | 판정 |
  |---|---|
  | ActivateHint 로그 자체가 없음 | 모션 미도달(Part A 회귀) |
  | `Info.Control=nil` | (ii) FindControlAtPosition 좌표 문제 |
  | Control≠nil, `ControlHasHint=False` | 병합 게이트 — 내장 로그로 구분 불가.
    GetHintInfoAt(application.inc:57-61)에 게이트별 값(ShowHint/GetCapture/
    GetKeyState 3종)을 찍는 TEMP-DIAG 1줄 추가 후 재실행 → (i)/(iii) 판별 |
  | StartHintTimer 있음, OnHintTimer 없음 | (iv) 타이머 미발화 |
  | ShowHintWindow 있음, (TEMP-DIAG) ShowHide 없음 | ActivateSub/WS 경로 |
- GetHintInfoAt(application.inc:53-70)의 억제 게이트별 용의자:
  (i) `GetCapture <> 0` — 소프트웨어 캡처(Gtk4CapturedWidget)가 클릭 후
      해제되지 않고 잔존하는 경우.
  (ii) `FindControlAtPosition` 좌표 불일치 — LCL이 아는 폼 위치와 실제
      X 위치의 어긋남(LM_MOVE 추적 누락).
  (iii) Application.ShowHint / 컨트롤 ShowHint 전파.
  (iv) LCL 타이머(StartHintTimer)가 GTK4에서 발화하지 않는 경우.
  (v) enter/leave의 CancelHint(application.inc:1663-1667)와 기존 2703 가드의
      상호작용 — enter 직후 모션 폐기로 타이머 미시작 (Part A가 해소;
      B0는 Part A 이후 실행하므로 이 요인은 자동 배제됨).
  (참고) `GetKeyState(VK_LBUTTON)`은 키보드 디바이스의
      `gdk_device_get_modifier_state`를 읽는데, GDK4 소스상 keyboard는
      keymap modifier만 반환하고 버튼 비트는 없음(gdkdevice.c:1324-1332;
      버튼 마스크는 XI2 이벤트 경로 gdkdevice-xi2.c:649에서만 생성).
      즉 버튼이 **항상 '안 눌림'**으로 나와 힌트 게이트는 오히려 통과 —
      힌트 미표시의 주범이 아니라 "드래그 중 힌트 억제 실패" 쪽 별건 결함.
      B0에서 원인으로 판명될 가능성 낮음(우선순위 하향).
- Part A 완료 후에는 Xvfb에서 에이전트가 hover를 합성해 로그를 직접 수집
  (사용자 개입 불필요). 결론은 사용자 실기 로그로 1회 교차 확인.

### Phase B1 — 활성화 체인 수정 (B0 진단 완료 — 결함 확정됨)

**B0 결과 (2026-07-02 Xvfb 실측)**: 게이트류 용의자 (i)(iii)(iv)는 전원 무혐의 —
SynEdit 히트 케이스에서 StartHintTimer→OnHintTimer→ShowHintWindow까지 정상
진행함을 로그로 확인(해당 컨트롤은 Hint 텍스트가 비어 표시만 생략됨).
확정 결함은 (ii)의 실체인 **TGtk4WidgetSet.WindowFromPoint**
(gtk4winapi.inc:5716-5749):
- toplevel 순회 시 `get_allocation()`의 x/y를 화면 원점으로 사용하는데
  GTK4 toplevel 위젯의 allocation은 항상 (0,0) → 사실상 "화면 좌표가
  (0,0)~(창폭,창높이) 안인가"를 검사 → **화면 좌상단에 있지 않은 창은
  영구 미스** (사용자 메인 바는 (1120,909) → 힌트 절대 불가).
- 부수: 겹친 창에서 gtk_window_list_toplevels 리스트 순서(스태킹 아님)로
  첫 매치를 반환 → 오히트(실측: 소스 에디터가 메인 바 좌표를 가로챔).
- 비가시(unmapped) 창도 걸러지지 않음.

**B1 수정 내용 — 구현·검증 완료 (2026-07-03, 연쇄 결함으로 총 5건)**:
1. `WindowFromPoint`: `Gtk4X11GetWindowOrigin`+surface transform으로 화면
   원점 보정(Wayland는 allocation 폴백), `get_mapped` 필터, O(n²) 순회
   제거. [계획대로]
2. (진단 중 신규 확정) 폼 ClientOrigin: `TWinControl.GetClientOrigin`은
   `LCLIntf.ClientToScreen(Handle,(0,0))`(wincontrol.inc:4010-4030)인데
   GTK4 구현이 창 원점(메뉴 위)을 반환 → ControlAtPos 전멸.
   → TGtk4Widget에 가상 `GetClientAreaOffset: TPoint`(기본 0,0) 신설,
   ClientToScreen/ScreenToClient에서 일괄 가감. TGtk4Window override =
   (0, GetNonClientOverhead).
3. (신규 확정) 노트북 ClientOrigin: ControlAtPos 재귀가 자식의 인터페이스
   ClientOrigin을 사용(wincontrol.inc:5316-5320) — 노트북도 탭바 오프셋
   미보고로 TabSheet가 물리적 탭바 영역으로 해석됨(y-프로브 실측).
   → TGtk4NoteBook.GetClientAreaOffset = (0, TabBarH). GTK_POS_TOP 한정,
   탭바 unmapped(ShowTabs=False/미realize) 시 0 (37 fallback 미적용 —
   codex 지적 반영).
4. (codex 지적 반영) 탭 hit-test API 정합: `GetTabIndexAtPos`는 입력을
   클라이언트→위젯 좌표로 +offset, `GetTabRect`는 출력을 -offset
   (gtk4wscomctrls.pp) — IndexOfPageAt(ScreenToClient(...)) 관례 유지.
5. 검증(Xvfb 실측): 팔레트 SpeedButton 히트 + 힌트 창 "TMainMenu
   (Menus, LCLBase)" 114x48 맵, 툴바 힌트 "Open ... [Ctrl+O]" 맵,
   팔레트 탭 클릭 전환 정상. 겹친 창 스태킹 순서 문제는 범위 밖(기존 한계).

### Phase B2 — 표시 경로 수정 (D1~D3, B0 결과와 무관하게 적용)

B2a. **위치 전달 — X11 window type TOOLTIP + map 후 위치 보정**:
  - 신규 메서드: `TGtk4Window.PrepareTooltipShow` — 선언은 TGtk4Window
    public 블록의 `PreparePopupShow`(gtk4widgets.pas:956) 바로 뒤에
    `procedure PrepareTooltipShow;` 추가, 구현은 PreparePopupShow 구현
    직후 배치(동일한 {$IFDEF UNIX} 구조).
    내용: `gtk_widget_realize(Widget)` → XID 획득(PreparePopupShow와 동일한
    Display/Surface/XID 시퀀스) → `_NET_WM_WINDOW_TYPE` 속성을
    `_NET_WM_WINDOW_TYPE_TOOLTIP`으로 교체 → `X11pMoveWindow(XDisplay,
    XWindow, LCLObject.Left, LCLObject.Top)` (좌표 소스는
    PreparePopupShow:11948-11949와 동일 — THintWindow bounds는 스크린 절대).
  - X11 바인딩 추가(기존 로더 패턴: 타입 10858-10893 부근, 함수포인터 변수
    10901-10911, GetProcAddress 로딩은 InitX11SizeHints:10914):
    `TX11InternAtom = function(display: Pointer; name: PChar;
      only_if_exists: LongBool): PtrUInt; cdecl;`  ('XInternAtom')
    `TX11ChangeProperty = function(display: Pointer; w: PtrUInt;
      prop, proptype: PtrUInt; format: LongInt; mode: LongInt;
      data: Pointer; nelements: LongInt): LongInt; cdecl;` ('XChangeProperty')
    상수: `X11_PropModeReplace = 0`, `X11_XA_ATOM = PtrUInt(4)`(사전정의 아톰).
    호출: atom값(_NET_WM_WINDOW_TYPE_TOOLTIP를 XInternAtom으로 획득)을
    담은 PtrUInt 변수의 주소를 data로, format=32, nelements=1.
  - **순서가 핵심** (1차 검토에서 확인된 현재 코드의 함정): 현
    TGtk4WSHintWindow.ShowHide는 `Visible:=True`(map)가 먼저이고
    `set_transient_for`는 **map 후**에 호출됨(gtk4wsforms.pp:771→783) —
    GDK4는 set_transient_for 시점에 _NET_WM_WINDOW_TYPE_DIALOG를 기록하므로
    (gdksurface-x11.c:2679-2691), map 전에 TOOLTIP을 써도 map 후 transient
    설정이 DIALOG로 되덮음. 따라서 ShowHide의 **show 분기만** 다음 순서로
    재구성(hide 분기는 기존 `Visible := False` 그대로, BeginUpdate/EndUpdate
    래핑 범위도 현행 유지):
    1) `gtk_widget_realize` (unmapped surface/XID 생성 —
       PreparePopupShow:11925와 동일 패턴, 바인딩 lazgtk4.pas:16870 존재)
    2) `set_transient_for` (이 시점에 GDK가 DIALOG 기록; Wayland 폴백 겸용.
       현재의 "map 후 + transient_for=nil 가드" 블록을 map 전으로 이동 —
       nil 가드는 유지하되 realize 후이므로 surface가 존재)
    3) `PrepareTooltipShow` 호출 (TOOLTIP 덮어쓰기 + XMoveWindow;
       GDK는 transient 변경 시에만 타입을 재기록하므로 이후 유지됨)
    4) `Visible := True` (map)
    5) map 직후 **`TGtk4Window(AWidget).PrepareTooltipShow`를 한 번 더 호출**
       (안전망 — 실제 위치를 읽어 비교하지 않는다: realize/속성 재기록은
       idempotent, XMoveWindow는 위치가 이미 맞으면 no-op ConfigureRequest.
       X11pMoveWindow 등 X11p* 심볼은 gtk4widgets.pas **implementation
       스코프(1087 이후)라 gtk4wsforms.pp에서 직접 호출 불가** — 메서드
       재호출로 우회). 기존 RaiseX11Popup 호출 지점(IsPopup 분기)과 같은
       자리에 non-popup(wtHintWindow) 분기로 추가.
  - 적용 조건: `(AWidget is TGtk4Window) and (wtHintWindow in
    AWidget.WidgetType) and (not IsPopup)` — 완성 팝업 등 기존 OR 경로
    (PreparePopupShow/RaiseX11Popup)는 불변.
  - Mutter는 TOOLTIP 타입을 자동 배치·포커스 부여 대상에서 제외 →
    요청 위치가 유지되고 포커스를 뺏지 않음(앱 비활성화→힌트 숨김 루프 차단).
  - Wayland: X11 로더 미해결 시 PrepareTooltipShow는 realize만 수행하고
    조기 반환(PreparePopupShow와 동일한 가드 패턴).

B2b. **폭 보존 로직 한정**: gtk4widgets.pas TGtk4Window.SetBounds의
  realized 분기(11539) `if Widget^.get_realized then`을
  `if Widget^.get_realized and not (wtHintWindow in FWidgetType) then`으로
  치환(블록 전체가 폭 보존 전용이므로 통째로 건너뜀; 블록이 읽는 CurW/CurH는
  함수 서두에서 0으로 초기화되어 있고 이후 사용처는 별도 재조회함).
  (get_decorated 조건보다 보수적 — bsNone 일반 폼과 완성 팝업(OR)의 기존
  동작을 건드리지 않음. 팝업류에서 같은 증상이 보고되면 그때 decorated
  조건으로 확장 재론.)

B2c. **힌트 크기 추종**: `TGtk4HintWindow`에 `SetBounds` override 신설
  (현재 이 클래스는 CreateWidget/InitializeWidget만 override —
  gtk4widgets.pas:964-971 선언에 `procedure SetBounds(...); override;` 추가):
  `inherited SetBounds(ALeft, ATop, AWidth, AHeight);` 후
  `if IsWidgetOk and Assigned(FCentralWidget) then
     FCentralWidget^.set_size_request(AWidth, AHeight+1);`
  **+1은 생성 시 정책(gtk4widgets.pas:12103, `AForm.Height+1`)과 동일하게
  유지** — 임의로 제거하면 힌트 텍스트 하단 1px 클리핑/여백 차이가 생길 수
  있음. non-resizable 창의 자연 크기가 현재 힌트 내용 크기를 따라가도록 함.
  (set_default_size는 inherited가 이미 호출 — min 하한이 문제였으므로
  min을 함께 갱신하는 것이 핵심.) inherited→set_size_request 순서는 안전:
  두 호출 모두 GTK 레이아웃 패스 이전에 동기 실행되고, inherited의
  min clamp(11534-11536)는 **창(FWidget)의 size_request**를 읽는데 힌트
  창은 이를 설정하지 않으므로(-1, CreateWidget은 FCentralWidget에만 설정)
  clamp가 작동하지 않음.

### 변경하지 않는 것 (확대판단 금지)

- override-redirect 재도입 없음(B2a 실패 시에만 fallback으로 재론).
- SynEdit 완성 팝업/FHint 경로(fsSystemStayOnTop, 기존 OR) 불변.
- Wayland 동작 변경 없음(X11 전용 경로는 기존 로더 패턴대로 가드).
- LCL 공용 코드(application.inc, hintwindow.inc)의 **동작** 수정 없음
  (B0의 TEMP-DIAG 임시 로그 1-2줄은 예외 — 진단 후 반드시 제거).
- GetKeyState 버튼 매핑 스왑은 B0에서 원인으로 판명될 때만 수정.

## 3. 리스크

R1. TOOLTIP 타입의 WM별 배치 정책 차이 — Mutter 기준 설계. 대부분의 EWMH
    WM은 TOOLTIP을 자동 배치에서 제외하므로 일반화 가능성 높음. 실패 시
    map 후 XMoveWindow 보정이 안전망, 최후 fallback은 OR화 재론.
R2. B2b를 wtHintWindow 한정으로 좁혔으므로 bsNone 일반 폼·완성 팝업의
    동작은 불변 — 회귀 리스크 최소화. 단 팝업류의 폭 단조 증가 결함은
    잠재적으로 남음(미보고 상태이므로 관찰만).
R3. 힌트가 다시 표시되기 시작하면 과거 S75가 보고한 "툴팁 관련 깜박임"류의
    잠재 이슈가 새로 드러날 수 있음 — TOOLTIP 타입은 포커스를 받지 않으므로
    비활성화 루프는 구조적으로 차단되지만, 검증 항목에 palette hover 장시간
    유지를 포함.

## 4. 검증 계획 (각 항목: 실행 방법 + 판정 기준)

1. Part A(에이전트, Xvfb — -dDebugHintWindow 빌드 겸용):
   실행: Xvfb :99에서 IDE 기동(--pcp 격리 config) → xdotool로 팔레트 아이콘
   좌표에 워프·소폭 이동 → stdout 캡처.
   판정: `TApplication.DoOnMouseMove` 로그 ≥1건이면 통과(수정 전 0건 실측).
2. B0(에이전트 Xvfb + 사용자 실기 1회):
   실행: 1과 동일 시나리오에서 2초 이상 정지 hover 유지 → 로그 수집.
   판정: §B0 판별표에 따라 용의자 1개로 수렴하면 종료. 병합 게이트로
   판명되면 TEMP-DIAG 1줄 추가 후 1회 재실행.
3. B1+B2 후:
   a. (에이전트, Xvfb) 실행: hover 유지 → `xwininfo -root -children` 폴링.
      판정: 새 toplevel(힌트) 맵 + geometry가 (커서.x, 커서.y+커서높이) 부근,
      긴 힌트 hover 후 짧은 힌트 hover 시 폭이 **감소**하면 D2/D3 통과.
      추가: 힌트 map 1회당 ShowHide/LM_MOVE 발생 수를 로그로 확인 —
      map 후 PrepareTooltipShow 재호출(안전망)이 과다 Configure 이벤트를
      만들지 않는지 점검.
   b. (사용자, 실기/Mutter) 팔레트·툴바·에디터에서 힌트 표시 위치(커서 하단),
      메인 창 타이틀바 활성 유지(포커스 비탈취), hover 장시간(30초+) 유지 시
      깜박임 없음, 완성 팝업/스플래시 회귀 없음. **복합/렌더드 힌트도 확인**
      (소스 에디터 식별자 hover의 THintWindowRendered 계열 — 힌트 표시가
      재개되면 이 경로가 GTK4에서 처음 실행되므로 blank/크기 불일치가
      "새 오류"로 보일 수 있음; 발견 시 별건 등록, 본 계획 범위 아님).
   c. (에이전트, 실기 비침습, 사용자가 hover하는 동안):
      - `xdotool search --name <힌트 캡션 없음 → xwininfo -root -children
        폴링으로 신규 XID 획득>` 후 `xprop -id <XID> _NET_WM_WINDOW_TYPE`
        → 판정: `_NET_WM_WINDOW_TYPE_TOOLTIP` 포함.
      - `xprop -spy -root _NET_ACTIVE_WINDOW` → 판정: 힌트 map 전후 값 동일.
      - 힌트 XID의 xwininfo geometry ≈ LCL 목표(THintWindow.BoundsRect —
        b에서 사용자가 hover한 위치 기준 커서 하단 20-30px 이내) → 판정:
        오차 수 px 이내 (WM 정책 전제 R1의 실증).
4. 빌드 3종(gtk4 lcl/bigide, gtk2 lcl) + `-dDebugHintWindow`/TEMP-DIAG 제거
   후 최종 빌드 3종 재확인.

## 5. 진행 순서 / 롤백

1. 현재 워킹트리(S76 깜박임 수정)를 먼저 커밋해 rollback point 확보 권장.
2. Part A → 검증 → Part B0 → (계획 확정/필요 시 갱신) → B1 → B2 → 검증.
3. 각 Part는 별도 커밋 단위. codex 교차검토 → claude 재검증 사이클을
   Part A/B 각각의 구현 전후에 적용.
