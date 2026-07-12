# PLAN: 메인 창 hover 깜박임 수정 — X11 WM_NORMAL_HINTS 전쟁 제거

작성: 2026-07-02 (Session 76). 관련 분석: 프로젝트 메모리 `palette-hover-flicker-analysis`,
진단 로그 `/tmp/laz_diag_s76b.log`.

## 1. 확정된 원인 (계측 로그 + GTK 소스로 입증)

증상: X11(GNOME Shell/Mutter)에서 메인 IDE 창의 팔레트/메뉴바 hover 시 창 폭 전체의
"가로 스크롤바"처럼 보이는 띠가 고속 깜박이고 창 전체가 껌벅임. 툴바(LCL 자체
그리기 영역) hover는 무증상.

인과 사슬:
1. `TMainIDEBar.DoSetMainIDEHeight`(AutoAdjustIDEHeight 기본 on)가
   `Constraints.MinHeight=MaxHeight`를 설정 → 백엔드 `TGtk4Window.SetMaxSize`
   → `ApplyX11SizeHints`가 WM_NORMAL_HINTS에 **PMaxSize**(max_height=창높이) 기록.
2. GTK4의 `compute_toplevel_size`(gtk-4.6.9/gdk/x11/gdksurface-x11.c:297-309)는
   **레이아웃 패스마다 무조건** `XSetWMNormalHints`를 호출하며 resizable 창엔
   **PMinSize만** 기록 → 우리가 쓴 PMaxSize가 매번 삭제됨.
3. 이를 보완하려고 붙인 frame clock **after-paint 콜백**(`Gtk4WindowAfterPaintCB`)이
   매 프레임 PMaxSize를 재기록 → WM_NORMAL_HINTS 내용이
   `min만(16)` ↔ `min+max(48)`로 **프레임 단위 토글** (로그 s76b에서 실측).
4. Mutter는 힌트 변경마다 창 기능을 재평가: max_height==min_height면 세로
   고정(리사이즈 보더 없음), max 없으면 세로 리사이즈 가능(보이지 않는 리사이즈
   보더 부여) → **프레임 창 geometry가 1100x129+…916 ↔ 1100x145+…909로 반복 점프**
   (실측: 69회/77초, 최소 90ms 간격) = 사용자가 본 깜박임.
5. 펌프: hover가 GTK CSS :hover 상태 변화(메뉴바 GtkPopoverMenuBar, 팔레트
   GtkNotebook = 네이티브 위젯)로 리페인트 프레임을 만들 때만 2-3이 반복됨.
   LCL 자체 그리기 영역(툴바)은 GTK 레이아웃 패스를 만들지 않아 무증상 —
   비대칭까지 정합.

배제된 것(같은 세션에서 실측): LCL 높이 재계산 루프(`CalcMainIDEHeight`/
`DoSetMainIDEHeight`)는 시작 1초 내 3회뿐, hover 중 침묵. 힌트 창은 아예 표시
자체가 안 됨(`TGtk4WSHintWindow.ShowHide` 0회) — 힌트 관련 가설 기각.

## 2. 수정 방안

원칙: PMaxSize를 GTK와 경쟁하며 유지하는 것은 구조적으로 불가능(GTK가 매
레이아웃마다 덮어씀). 최대 크기 강제는 **이미 구현되어 있는
`Gtk4WindowNotifyDefaultSizeCB`의 default-size 스냅백**(gtk4widgets.pas
constraint enforcement 블록)에 일원화하고, X11 힌트 전쟁을 중단한다.

변경 (모두 `lcl/interfaces/gtk4/`):

C1. `Gtk4WindowAfterPaintCB`(gtk4widgets.pas:11091-11097): `ApplyX11SizeHints`
    호출 제거. `CheckSendLMMove`는 유지(LM_MOVE 추적 용도 — NotifyDefaultSizeCB는
    size notify 시에만 호출하므로 move-only 추적은 after-paint가 담당).
    콜백 연결/해제 로직은 변경하지 않음. 함수 상단 주석(11078-11080,
    "reapply X11 hints" 설명)을 "constrained window move polling" 용도로 재기술.

C2. `Gtk4WindowNotifyDefaultSizeCB`(gtk4widgets.pas:11046): 재기록
    `AWindow.ApplyX11SizeHints` 호출 제거(11039 주석 포함). 같은 블록의
    default-size 스냅백(NeedFix → set_default_size)은 유지 — 이것이 실질적
    max 강제 수단.

C3. `TGtk4Window.SetMaxSize` 말미(gtk4widgets.pas:11826)의
    `ApplyX11SizeHints` 호출 제거. FMaxWidth/FMaxHeight 저장과
    `ConnectComputeSize`/after-paint 연결은 유지. 함수 내 주석(11813 부근,
    "reapply X11 size hints AFTER GTK4's layout phase")을 스냅백 일원화로 재기술.

C4. `TGtk4WSCustomForm.ShowHide`(gtk4wsforms.pp:421)의
    `ApplyX11SizeHints` 호출 제거 + 해당 블록 주석(410-414) 정리.

C4b. `TGtk4WSWinControl.ConstraintsChange`(gtk4wscontrols.pp:342-344)의 주석
    ("CSS max-height/max-width... after-paint callback reapplies
    WM_NORMAL_HINTS")을 실제 동작(notify::default-size 스냅백 단독 강제)으로
    수정. 코드 변경 없음, 주석만.

C5. `ApplyX11SizeHints` 함수 본체는 **삭제하지 않고 유지** (X11 힌트 로더
    `InitX11SizeHints` 등과 함께 다른 용도로 재사용 가능; 호출부만 제거).
    단, 유지 시 "호출부 없음" 상태가 되므로 함수 주석에 미사용 사유를 1줄 명기.

C6. TEMP-DIAG-S76 로깅 전부 제거 (mainbar.pas 2곳+uses, gtk4widgets.pas 4곳,
    gtk4wsforms.pp 1곳) — 수정 검증 완료 후.

변경하지 않는 것(확대판단 금지):
- 시작 시퀀스의 172→64 constraint cycling (증상과 무관, 기존 동작 유지).
- 힌트 창이 표시되지 않는 별건 버그(ShowHide 0회) — 후속 과제로 기록만.
- `GtkEventMouseMove`의 좌표계 혼합 가드(gtk4widgets.pas:2703) — 후속 과제.
- `TGtk4Window.SetBounds`의 폭 보존 로직 — 힌트 표시 버그 수정 시 함께 재검토.
- mainbar.pas / IDE 코드 — LCL 백엔드만으로 해결 가능.

## 3. 트레이드오프 / 리스크

R1. WM 차원의 인터랙티브 리사이즈 클램프(사용자가 드래그로 세로 확대 시 WM이
    커서를 멈춰주는 것)가 사라짐. 대신 스냅백이 드래그 종료 시점(또는 즉시)
    크기를 복원. GTK4에 max-size API가 없는 이상 근본 한계이며, 힌트 전쟁의
    깜박임보다 수용 가능한 동작. 참고: GTK의 자체 min 힌트(콘텐츠 최소 높이)가
    현재 max와 동일(90)이라 세로 축소는 여전히 WM 차원에서 막힘.
    이 트레이드오프는 메인 IDE 창뿐 아니라 Constraints.Max*가 설정된 모든
    bsSizeable 폼에 적용됨(드래그 중 일시 확대 후 복원 UX) — 검증 항목 2d에서
    확인. bsDialog/bsSingle/bsToolWindow/fsSplash는 GTK가 non-resizable로
    min=max 힌트를 스스로 유지하므로(gdksurface-x11.c compute_toplevel_size
    non-resizable 분기 + gtk4wsforms.pp:559 FormResizableMap) 무영향.
R2. after-paint 콜백이 힌트 재기록 목적을 잃고 CheckSendLMMove만 남음 —
    의도적 유지(LM_MOVE 경로 회귀 방지). 후속 정리 후보로만 기록.
R3. Wayland: ApplyX11SizeHints는 X11 전용이었으므로 영향 없음.
R4. 다른 폼(예: 고정 크기 대화상자)의 최대 크기 강제도 스냅백으로 일원화됨 —
    fsSplash처럼 `set_resizable(False)`를 쓰는 완전 고정 창은 GTK가 스스로
    min=max 힌트를 유지하므로(compute_toplevel_size의 non-resizable 분기) 무영향.

## 4. 검증 계획

1. 빌드 3종: `make lcl LCL_PLATFORM=gtk4`, `make bigide LCL_PLATFORM=gtk4`,
   `make lcl LCL_PLATFORM=gtk2`(회귀).
2. 사용자 GUI 확인 항목:
   a. 팔레트/메뉴바 hover 시 깜박임 소멸 (핵심).
   b. 창 높이가 팔레트 줄 수에 맞게 유지되는지 (AutoAdjustIDEHeight 동작).
   c. 메인 창 가로 리사이즈 정상.
   d. 메인 창 세로 드래그 시도 → 스냅백으로 복원되는지 (R1 확인).
   e. 소스 에디터 등 다른 창의 리사이즈/이동 정상 (LM_MOVE 회귀 확인).
3. (에이전트) 수정 빌드에서 :1 비침습 관찰 재실행:
   a. xwininfo 샘플링 → 프레임 geometry 토글(129↔145) 소멸 정량 확인.
   b. `xprop -spy -id <창XID> WM_NORMAL_HINTS` → hover 중에도 힌트가
      PMinSize 단일 상태로 안정(PMaxSize 재등장 없음)인지 원인 레벨 확인.
4. 검증 통과 후 C6(진단 로그 제거) → 최종 빌드 3종 재확인.

## 5. 롤백

rollback point: `02941dc`(현재 HEAD, 워킹트리에 TEMP-DIAG만 추가된 상태).
변경은 LCL gtk4 백엔드 3개 지점 호출 제거가 전부라 revert 용이.
