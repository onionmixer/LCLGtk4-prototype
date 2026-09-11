# PLAN: `TGtk4Widget.SetBounds` 의 강제 FCentralWidget 할당과 스크롤 컨테이너 — 계획서

작성: 2026-09-11 (세션 Claude Fable 5.1). 요청: `REQUEST_2026-09-11_SCROLLFIXED_ALLOCATION.md`.
대상 트리: `lazarus/` @ `d65073f`, GTK 4.6.9 (`gtk-4.6.9/` 소스로 대조). 상태: **계획(저장소 코드 변경 없음)**.
실험은 `lcl/interfaces/gtk4` 를 스크래치에 복사해 패치한 뒤 별도 유닛 디렉터리로 컴파일한 하네스 바이너리로만 수행했다
(저장소 소스·유닛 디렉터리 무변경, `git status` 확인).
교차검토: codex CLI `gpt-6-astra` read-only → 회신은 전건 코드 대조로 재검증(`codex-review-verify` 절차). 결과는 §9.

---

## 0. 요약과 범위 결정

- **요청의 결함(R1)**: KMemo(`TCustomControl`)가 리사이즈된 뒤 세로로 크게 스크롤하면 빈 화면. 원인은 요청서 §3 대로
  `TGtk4Widget.SetBounds` 가 스크롤용 GtkFixed(`'lcl-scroll-fixed'`)를 **클라이언트 크기로 강제 할당**하는 것이다.
  요청서의 사용자 재현 스크립트(`test_entry_return/run_scroll_blank.sh`)로 헤드리스 재현을 확인했다(§4.4).
- **실측으로 바로잡은 점**: 강제 할당은 "요청값이 안 바뀔 때만" 남는 것이 아니라 **SetBounds 가 불릴 때마다 항상**
  GtkFixed 를 stale 상태로 만든다(첫 표시 직후 포함). 평소에 멀쩡해 보이는 것은 LCL 이 그 뒤에 `SetScrollInfo` 로
  `set_size_request` 값을 **바꿔** GTK 가 스스로 `queue_resize` 를 걸어 주는 우연에 기대고 있기 때문이다(§3.3).
  LCL 의 리사이즈 경로에서는 `Resize`(→`SetScrollInfo`) **다음에** 위젯셋 `SetBounds` 가 오므로(§2.6, 실측 1건 + LCL
  구조), 리사이즈 뒤에는 이 우연이 성립하지 않는다 → 요청서의 증상.
- **같은 구조의 결함군**: 같은 줄(`gtk4widgets.pas:5290`)이 `FCentralWidget` 을 가진 16개 클래스 중 12개에 적용된다
  (§2.2). 실측 결과 GtkScrolledWindow 안에 있는 중앙 위젯은 **모두** 같은 방식으로 어긋난다:
  - 스크롤용 GtkFixed(태그): `TGtk4CustomControl`(KMemo, **TTreeView, TSynEdit, Object Inspector 그리드** 등 LCL 이
    직접 그리는 모든 스크롤 컨트롤), `TGtk4ScrollingWinControl`(**TScrollBox**). 리사이즈 뒤 스크롤하면 빈 화면(§4).
  - GtkScrolledWindow 의 직접 자식(태그 없음): `TGtk4ListView`(GtkColumnView) — 보이는 스크롤바 폭만큼 **과대 할당**
    (600×300 vs 정답 585×285)이 리사이즈 뒤 그대로 남는다. `TGtk4Memo`/`TGtk4ListBox`/`TGtk4CheckListBox` 는 오늘
    overlay 스크롤바라 값이 우연히 일치하지만 메커니즘은 동일하다(§5-B).
- **범위 제안**: 필수 범위 = **GtkScrolledWindow 가 소유하는 중앙 위젯 전부**(`wtScrollingWin`)에 대해 강제 할당을
  건너뛴다(§6 A안). 한 줄짜리 조건 추가이며 실험 바이너리로 전 행렬을 검증했다(§4.5). 스크롤과 무관한 나머지
  불일치(`TStaticText`/`TStatusBar`/`TProgressBar`/`TPairSplitterSide`, §5-C)는 근거만 기록하고 **사용자가 범위를
  정한다**(§10). 요청서가 지키라고 한 "일반 컨테이너의 stale 0x0 경로는 그대로 둔다"는 원칙을 유지한다.

## 1. 확정 사실 — GTK 4.6.9 소스 (추측 아님, 파일:줄; 전부 직접 대조)

1. **`gtk_widget_allocate` 는 부모에게 아무것도 알리지 않는다.** 저장 할당(`allocated_width/height/transform`)을
   덮어쓰고(`gtk/gtkwidget.c:3975-3986`), 자기 layout manager/vfunc 로 **자식들을** 할당한 뒤(`:4069-4081`), **자기**
   `alloc_needed`/`alloc_needed_on_child` 를 지운다(`:4094-4096`). 부모의 플래그는 건드리지 않고 `queue_draw` 만 건다
   (`:4103-4107`). 즉 부모 사이클 밖에서 자식만 재할당하면 **부모는 그 사실을 모른다.** 위젯 자신이 비가시
   (`!visible`, root 제외)이면 즉시 반환(`:3938-3941`) — 실현(realize)/맵 여부는 검사하지 않는다.
2. **건너뛰기 조건**: `if (!alloc_needed && !size_changed && !baseline_changed) goto skip_allocate;`
   (`:4060-4063`). 위치(transform)만 바뀐 경우는 재배치 사유가 아니다. `skip_allocate`/`out` 뒤에는
   `alloc_needed_on_child` 일 때만 자식으로 내려간다(`:4109-4111`).
3. **`gtk_widget_queue_resize`** 는 위젯과 조상들에 `resize_needed`+`alloc_needed` 를 세운다
   (`gtk_widget_queue_resize_internal`, `:3600-3634`, 조상 재귀 `:3631`; 이미 `resize_needed` 인 조상에서 멈추고
   `:3605-3606`, 비가시 위젯은 위로 올리지 않으며 `:3623`, native 경계에서는 부모에 `queue_allocate` `:3628-3629`). **`gtk_widget_queue_allocate`** 는 위젯
   자신에게만 `alloc_needed`(`:3558-3582` → `gtk_widget_set_alloc_needed :10532-10558` 은 조상에 `alloc_needed_on_child`
   만 전파). `gtk_widget_ensure_allocate` 는 `alloc_needed` 인 위젯을 **저장된 할당값 그대로** 재할당한다
   (`:10575-10610`, `:10592-10596`). → 강제로 600×400 을 넣어 둔 GtkFixed 에 `queue_allocate(fixed)` 를 걸면
   600×400 이 다시 재생될 뿐 고쳐지지 않는다. `queue_resize(fixed)` 가 고치는 이유는 **부모(GtkOverlay)에도**
   `alloc_needed` 가 서서 2번 조건을 깨기 때문이다. 같은 이유로 `queue_allocate(overlay)` 도 고친다(오버레이의 저장
   할당은 정답이므로 재생 시 `gtk_overlay_layout_allocate` 가 다시 돌아 GtkFixed 를 재할당, `gtkoverlaylayout.c:421-425`).
4. **`gtk_widget_set_size_request`** 는 값이 바뀌고 **가시** 상태일 때만 `queue_resize` (`:7002-7030`, `:7023-7025`).
   같은 값을 다시 넣는 것은 완전한 no-op. 요청값은 `gtk_widget_measure` 의 minimum 에 `MAX` 로 합쳐진다
   (`:7753-7756`).
5. **뷰포트/오버레이/스크롤창 할당**: GtkViewport 는 자식을 `(-hvalue, -vvalue, MAX(뷰포트, 자식 min))` 로 할당
   (`gtk/gtkviewport.c:505-548`; 기본 scroll policy MINIMUM). 스크롤 값 변경은 뷰포트에 `queue_allocate` 만 건다
   (`:554-559`) → 오버레이는 위치만 바뀌므로 2번 조건으로 건너뛴다 → **스크롤은 stale 을 고치지 못한다.**
   GtkOverlay 는 메인 자식을 자기 전체 크기 `(0,0,w,h)` 로 할당(`gtk/gtkoverlaylayout.c:412-426`). GtkScrolledWindow 는
   scrollable 자식을 자기 콘텐츠 영역에서 **보이는 비-overlay 스크롤바 폭/높이를 뺀** 크기로 할당
   (`gtk/gtkscrolledwindow.c:3104-3151`).
6. **외부에서 `gtk_widget_size_allocate` 를 부르는 것을 막는 검사는 없다.** 디버그 빌드에서만 "Allocating size to %s
   without calling gtk_widget_measure()" 경고(`gtk/gtkwidget.c:3944-3950`). 조용히 부모와 어긋난 상태가 된다.
7. 윈도우 레이아웃 진입: `gtk_window_native_layout` 이 `gtk_widget_needs_allocate` 면 `gtk_widget_allocate`, 아니면
   `gtk_widget_ensure_allocate` (`gtk/gtkwindow.c:2145-2153`).

## 2. 확정 사실 — LCL gtk4 코드

### 2.1 `TGtk4Widget.SetBounds` (`gtk4widgets.pas:5231-5308`)

```
5261-5262  gtk4_widget_measure ×2 (결과 버림)
5264       Widget^.set_size_request(AWidth, AHeight)          -- 값이 바뀌면 GTK 가 queue_resize(Widget)
5267       gtk4_widget_size_allocate(Widget, @ARect, -1)      -- 외부 위젯을 직접 할당: 이때 SW→Viewport→Overlay→Fixed
                                                                 사슬이 **한 번 올바르게** 할당되고 alloc_needed 가 지워진다
5278-5291  if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) and not (LCLObject is TCustomGroupBox) then
             gtk4_widget_size_allocate(FCentralWidget, (0,0,AWidth,AHeight))   -- ★ 문제의 강제 할당
5292-5301  FPaintArea 도 같은 크기로 강제 할당
5303-5304  Move(ALeft, ATop)
```

주석(`:5269-5273`)의 근거는 "GtkOverlay 가 overlay 자식에 할당을 전파하지 않아 GtkFixed 가 0×0 으로 남을 수 있다".
도입 커밋 `ae41ff1`(2026-03-08, Sessions 56-70 스쿼시)에는 이 줄만의 사유 기록이 없다. 그룹박스 예외는
`d999333d`(2026-07-11)가 추가 — **같은 종류의 문제로 이미 한 번 잘라낸 전례**(프레임 inset 을 덮어씀).

### 2.2 `FCentralWidget` 을 만드는 클래스 (탐색 에이전트 보고를 `gtk4widgets.pas` 에서 확인)

| 클래스 | FWidget → FCentralWidget | 태그 | 강제 할당 적용? | 스크롤 소유자 |
|---|---|---|---|---|
| `TGtk4CustomControl` :13654 | ScrolledWindow > (Viewport) > Overlay > **GtkFixed** | `lcl-scroll-fixed` | **적용 ← R1** | SW/Viewport(콘텐츠 크기 = `set_size_request`) |
| `TGtk4ScrollingWinControl` :13850 | 위와 동일 | `lcl-scroll-fixed` | **적용 ← R1** | 동일 |
| `TGtk4Window` :14395 | Window > Box > Overlay > ScrolledWindow > (Viewport) > **GtkFixed** | `lcl-scroll-fixed` | 아님(자체 SetBounds :14730, inherited 없음) | — |
| `TGtk4Memo` :9232 | ScrolledWindow > **GtkTextView** | 없음 | 적용 | SW(콘텐츠 − 보이는 스크롤바) |
| `TGtk4ListBox` :9795 / `TGtk4CheckListBox` :10034 | ScrolledWindow > **GtkListView/GridView** | 없음 | 적용 | SW |
| `TGtk4ListView` :10720 | ScrolledWindow > **GtkColumnView/GridView** | 없음 | 적용(실측 어긋남) | SW |
| `TGtk4Panel`(+`TGtk4Splitter`) :5863, `TGtk4ToolBar` :7914, `TGtk4SplitterSide` :3260 | Overlay > **GtkFixed** | 없음 | 적용(실측 일치) | Overlay(= 외부 크기) |
| `TGtk4GroupBox` :5926 | Frame > Overlay > **GtkFixed** | 없음 | **예외** | Frame inset |
| `TGtk4Page` :7952 | Box > **GtkFixed** | 없음 | WS 층이 SetBounds 를 무시(`gtk4wscomctrls.pp:2140`) | — |
| `TGtk4StaticText` :7670 | Frame > **GtkLabel** | 없음 | 적용(프레임 border 1px 만큼 과대) | Frame |
| `TGtk4ProgressBar` :7846 | Box > **GtkProgressBar** | 없음 | 적용(`InitializeWidget` 의 `set_size_request` 와 충돌) | Box |
| `TGtk4StatusBar` :5847 | Box(V) > **GtkBox(H)** | 없음 | 적용(GTK 정답은 높이 0) | Box |
| `TGtk4HintWindow` :15389 | Window > Box > GtkFixed | 없음 | `TGtk4Window.SetBounds` 경유 + 자체 `set_size_request` | — |

`wtScrollingWin` 을 가진 클래스 = 위 표의 "스크롤 소유자 = SW" 행 전부 + `TGtk4Window`(:9245, :9806, :10044,
:10747, :10807, :13661, :13858, :14421, :14426). `SetScrollInfo` 도 같은 플래그로 스크롤 컨테이너를 식별한다
(`gtk4winapi.inc:5091`).

### 2.3 스크롤 컨테이너의 콘텐츠 크기와 그리기

- `SetScrollInfo`(`gtk4winapi.inc:5052-5338`): `bRedraw` 이고 `wtWindow` 가 아니면 `GetContainerWidget`(=태그된 GtkFixed)
  에 `set_size_request(ContentSize, ...)`, 스크롤바를 숨길 때 `-1`(`:5284-5318`). 이것이 GTK2 `gtk_layout_set_size` 의
  대체이며 **뷰포트가 GtkFixed 를 콘텐츠 크기로 할당하게 만드는 유일한 입력**이다.
- `LCLFixedLayoutMeasure`(`gtk4widgets.pas:2763-2787`): 태그된 GtkFixed 는 min=nat=0 → 측정값 = `set_size_request` 그대로.
- `LCLGtkFixedSnapshot`(`:3037-3108`): `w/h := gtk_widget_get_allocated_width/height(fixed)` 로 cairo 노드를 만들고
  `cairo_translate(ScrollX, ScrollY)` 로 뷰포트의 물리 스크롤을 되돌린다(`:3053-3054`, `:3082-3092`). **할당이 콘텐츠
  크기일 때만 성립** — 할당이 뷰포트 크기면 `value > 0` 인 순간 그릴 영역이 화면 밖이다. GtkFixed 에는
  `overflow=hidden`(`SetupPaintArea :5682`)이라 GTK 자식 위젯(TScrollBox 의 자식 컨트롤)도 할당 밖은 잘린다.
- `TGtk4CustomControl.getClientRect`(`:13727-13760`)는 일부러 **FWidget(ScrolledWindow)** 할당에서 계산하므로 GtkFixed
  할당이 어긋나도 LCL 클라이언트 크기는 정상(하네스 `client=` 열이 항상 `lcl=` 와 같음). 즉 LCL 쪽 상태는 멀쩡하고
  GTK 그리기/클리핑만 깨진다 — 요청서 §2 의 관찰과 일치.

### 2.4 `queue_resize`/`size_allocate` 호출처(위젯셋 전체)

`gtk4widgets.pas:5267/5290/5300`(SetBounds) 과 `:12005`(ListView 컬럼 `queue_resize`), `:2981`(`LCLFixedLayoutAllocate`
안의 `gtk4_widget_allocate`) 뿐. `gtk_widget_queue_allocate` 호출은 없다. 창은 `set_default_size` 만 쓴다(`:14744-14746`).

### 2.5 실험 패치(스크래치, §4.5)

`SetBounds :5278` 조건에 한 항을 추가:
- **A**: `and not (wtScrollingWin in FWidgetType)` — GtkScrolledWindow 가 소유하는 중앙 위젯 전부 제외.
- **B**: `and (g_object_get_data(PGObject(FCentralWidget), 'lcl-scroll-fixed') = nil)` — 태그된 GtkFixed 만 제외(요청서 A안에서 `queue_resize` 를 뺀 것).

### 2.6 LCL 호출 순서 (gdb 추적, `example_gtk4_allocmatrix_validation/order_custom_hv.txt`)

`Target.Height := Height-100` 한 번에 대해:

```
SetScrollInfo ×4 (LCL Resize → UpdateScrollRange)  → set_size_request(fixed, 1385×12085) → queue_resize(fixed)  [요청값 바뀜]
SetBounds (위젯셋)                                  → set_size_request(SW, 600×300) → queue_resize(SW)
                                                    → [직접 size_allocate(SW): 사슬 전체가 올바르게 할당되고 alloc_needed 소거]
                                                    → [강제 size_allocate(fixed, 600×300)]  ← 여기서 stale
```

즉 **요청값이 바뀌어도** 그 `queue_resize` 는 강제 할당 **앞**에서 이미 소비되므로 고쳐지지 않는다.
`SetBounds` 뒤에 GtkFixed 자체나 조상에 `queue_resize` 를 거는 코드는 없다. (실측은 이 컨트롤 1건이다.
`TWinControl.RealizeBounds` 가 autosize 트랜잭션 끝에서 불리는 LCL 구조상 `Resize` 핸들러 → 위젯셋 `SetBounds` 순서는
일반적이지만, 어느 순서든 강제 할당이 **마지막**에 오면 stale 이 남는다는 점이 본질이다. 하네스 `same` 단계는 `Resize`
없이 위젯셋 `SetBounds` 만 직접 부른다.)

## 3. 메커니즘 (§1 + §2 로부터)

3.1 `SetBounds :5267` 이 SW 를 직접 할당하면 (SW 가 dirty 이거나 크기가 바뀐 경우) GtkScrolledWindow→GtkViewport→
    GtkOverlay→GtkFixed 가 정상 할당된다(오버레이 = GtkFixed = 콘텐츠 크기, 뷰포트가 `set_size_request` 를 min 으로
    읽음, §1.5). 크기가 같고 dirty 도 아니면 `:5267` 은 사슬을 건드리지 않고(§1.2) **이미 올바른 사슬을 그대로 둔다** —
    즉 A안은 "매번 재구성"이 아니라 "올바른 사슬을 보존"하는 것이다(하네스 `same` 단계가 이 경우).
3.2 `:5290` 이 GtkFixed 만 `(0,0,클라이언트)` 로 덮어쓴다. GtkFixed 의 dirty 플래그는 지워지고(§1.1), 오버레이는
    아무것도 모른다.
3.3 이후 프레임 레이아웃에서 오버레이는 "크기 그대로 + alloc_needed 아님" 이라 건너뛰고(§1.2), 자식으로 내려가도
    GtkFixed 는 dirty 가 아니라 아무 일도 없다. 스크롤(뷰포트 `queue_allocate`)도 위치만 바꾸므로 마찬가지(§1.5).
    **회복 경로는 GtkFixed 나 그 조상에 `queue_resize`(또는 오버레이에 `queue_allocate`)가 걸리는 것뿐**이며, 실제로는 나중에 `SetScrollInfo` 가
    **다른 값**의 `set_size_request` 를 넣을 때(§1.4) 우연히 일어난다. TTreeView/TSynEdit 는 스크롤할 때마다
    콘텐츠 크기 계산값이 조금씩 달라져 이 우연이 자주 일어나고(§4.2 `scroll` 행 ok), KMemo 는 긴 줄이 있으면 값이
    고정되어 일어나지 않는다(요청서 §3 의 추정은 이 한 조각에 대해서만 맞다).
3.4 `TGtk4ListView` 등 SW 의 직접 자식도 동일: SW 는 자식을 콘텐츠−스크롤바 로 할당하는데(§1.5) `:5290` 이 외부
    크기로 덮어쓴다. 스크롤바가 overlay(indicator)이면 두 값이 같아 티가 나지 않는다.

## 4. 실측 (하네스 `lazarus/example_gtk4_allocmatrix_validation/`, gtk4 전용)

### 4.1 방법

`allocmatrix <control> [hv|v|none] [notruth|late|hidden]` — 컨트롤 하나를 폼(800×600)에 600×400 으로 놓고
`show → scroll → shrink(-100h) → same(위젯셋 SetBounds 를 같은 값으로 직접 호출) → grow(+100h) → wider(+50w) → scroll2`
각 단계마다 `SNAP`(외부 위젯/중앙 위젯/중앙의 부모 할당, `size_request`, 스크롤 adjustment, LCL 크기)을 찍고,
바로 `gtk_widget_queue_resize(FCentralWidget)` 후 다시 찍은 **`t-*` = GTK 레이아웃이 계산한 정답**과 비교한다
(`analyze.py`: 중앙 할당 ≠ 정답 → `STALE`). `notruth` 는 정답 단계에서 `queue_resize` 를 하지 않아 GTK 가 스스로
회복하는지 본다. `late` = 폼 표시 후 생성(검색 패널 케이스), `hidden` = Visible=False 로 만들고 나중에 표시.
`custom` = KMemo 와 같은 방식(`ShowScrollBar`+`SetScrollInfo`, `Resize` 마다 재설정)의 `TCustomControl` 파생.
`run.sh` 는 Xvfb + `GSK_RENDERER=cairo`, 5번째 인자로 `scroll` 단계 스크린샷.

### 4.2 기준선(현재 코드, `out/`, `out_modes/`) — STALE 단계 수 / 7단계

| 컨트롤 | hv | v | none | late | hidden | notruth 에서 자력 회복? |
|---|---|---|---|---|---|---|
| custom (KMemo형) | **5** (show,shrink,same,grow,wider) | **5** | 0 | **5** | **5** | 아니오 — 스크롤해도 600×400 유지 |
| scrollbox (TScrollBox) | **5** | **5** | 0 | **5** | **5** | 아니오 |
| treeview (TTreeView) | **5** | | | | | 스크롤하면 요청값이 5980→5985 로 바뀌어 회복(우연) |
| synedit (TSynEdit) | **4** (show 는 정상: 스크롤 정보가 SetBounds 뒤에 옴) | | | | | 스크롤로 회복(우연) |
| listview | **4** (shrink,same,grow,wider: 600×300 vs 585×285) | | | | | 아니오 |
| memo / listbox / checklist | 0 (overlay 스크롤바라 값이 우연히 같음) | | | | | — |
| panel / toolbar / groupbox / page / form | 0 | | | | | — |
| statictext | 4 (598×298 vs 600×300, 프레임 border) | | | | | 아니오 (범위 밖) |
| statusbar | 3 (GTK 정답 높이 0 vs 25) | | | | | (범위 밖) |
| progressbar | 2 (`InitializeWidget` 의 요청 600×400 이 남아 GTK 정답이 400) | | | | | (범위 밖) |
| splitterside | 1 (`same` 단계만: 직접 호출이 GtkPaned 배치와 어긋남) | | | | | (범위 밖) |

대표 행(custom hv): `show` 중앙 `600x400` / 정답 `1400x12000` / 부모 GtkOverlay `1400x12000`;
`shrink` 중앙 `600x300` / 정답·부모 `1385x12085` / vadj 11600 → 화면에는 콘텐츠 y∈[11600,11900] 이 보여야 하는데
GtkFixed 는 [0,300] 만 차지.

### 4.3 스크린샷 (`shots/`)

- `scrollbox_hv_notruth_scroll.png`: 스크롤 끝에서 **빈 상자**(자식 패널 40개가 전부 잘림). `scrollbox_hv_truth_scroll.png`
  (queue_resize 후): 패널이 보인다.
- `custom_hv_notruth_scroll.png`: 빈 상자. `custom_hv_truth_scroll.png`: `11600 … 11960` 줄 번호가 보인다.

### 4.4 tomboy-ng 재현 (사용자 키트, 현재 `tomboy-ng-gtk4` 0.42c+onion4 = LCL dfsg-5)

`test_entry_return/run_scroll_blank.sh` 를 Xvfb :83 으로 실행: `pgdn-3`, `ctrl-end` 스크린샷이 밝은 회색 단색(빈 화면),
`ctrl-home` 은 `1-clicked` 와 같은 digest(내용 복귀). 요청서 §1 표와 일치. 결과는 스크래치 `tomboy_baseline/`.

### 4.5 실험 바이너리 (`out_expA/`, `out_expB/`; 저장소 무변경)

| 컨트롤 (STALE 단계 수) | 기준선 | **A**(`wtScrollingWin` 제외) | **B**(태그만 제외) |
|---|---|---|---|
| custom hv / v / none / late / hidden | 5 / 5 / 0 / 5 / 5 | **0 / 0 / 0 / 0 / 0** | **0 / 0 / 0 / 0 / 0** |
| scrollbox hv / v / none / late / hidden | 5 / 5 / 0 / 5 / 5 | **0 / 0 / 0 / 0 / 0** | **0 / 0 / 0 / 0 / 0** |
| treeview hv / synedit hv | 5 / 4 | **0 / 0** | **0 / 0** |
| listview hv | 4 | **0** | 4 (태그가 없어 그대로) |
| memo / listbox / checklist | 0 | 0 | 0 |
| panel / toolbar / groupbox / page / form | 0 | 0 | 0 |
| statictext / statusbar / progressbar / splitterside | 4 / 3 / 2 / 1 | 4 / 3 / 2 / 1 (**기준선과 동일**) | 4 / 3 / 2 / 1 (동일) |
| notruth 스크린샷(scrollbox, 스크롤 끝) | 빈 상자 | **패널이 보임**(`shots/scrollbox_hv_notruth_scroll_expA.png`) | 동일 |

- 두 변형 모두 **강제 할당을 건너뛰기만 해도** `queue_resize`/`queue_allocate` 추가 없이 모든 단계·모든 시나리오(`late`,
  `hidden` 포함)에서 중앙 할당 = GTK 정답이다. 근거: `SetBounds :5267` 의 직접 할당이 이미 사슬을 올바르게 놓고(§3.1),
  그것을 덮어쓰는 것이 `:5290` 뿐이기 때문. `notruth` 실행에서도 전 단계 중앙 할당 = 부모 오버레이 크기(자력 회복 불필요).
- A 와 B 의 차이는 `TGtk4ListView` 한 행뿐이며, 그 밖의 모든 행(비스크롤 클래스 포함)은 세 실행의 분석기 정규화 행이 같다.

### 4.6 실행 완료 (2026-09-11) — §4.5 의 표가 최종값. 로그: `out_expA/`, `out_expB/`(각 33개 로그), 스크린샷 `shots/`.

### 4.7 2차 실측 (codex 1차 검토 반영: `runexp3.sh` → `out_v2/`, `out_v2_expA/`, `out_v2_expB/`, `shots_v2/`, `out_v3*/`)

하네스 확장: SW 직접 자식은 GTK vadjustment 로 실제 스크롤(`NOSCROLL` 검사), `rehide`/`inactivepage`/`zero` 시나리오,
`listboxgrid`(GtkGridView)/`listviewicon`(GtkGridView)/`memowrap`, 스크린샷은 모든 리사이즈 **뒤**의 `scroll2`, `rss=`,
`wsclient=`(위젯셋 `getClientRect` 직접 질의), `GSK=gl`. 분석기 `--strict`(STALE/FILL/NOSCROLL/NOSNAP/INCOMPLETE).

| 시나리오(문제 단계 수) | 기준선 | **A** | **B** |
|---|---|---|---|
| custom: truth / notruth / late / hidden / **rehide** / **inactivepage** / **zero** | 5 / 7 / 5 / 5 / 8(STALE 7 + 숨긴 채 FILL 1) / 7 / 7 | **0 전부** | 0 전부 |
| scrollbox: 같은 7개 시나리오 | 5 / 7 / 5 / 5 / 8 / 7 / 7 | **0 전부** | 0 전부 |
| treeview / synedit (truth, notruth) | 5,6 / 4,5 | **0** | 0 |
| listview / listviewicon (truth) | 4 / 4 | **0** | 4 / 4 (600×300 vs 585×285, 아이콘 모드 600×300 vs 585×300) |
| memo / memowrap / listbox / listboxgrid / checklist | 0 | 0 | 0 |
| `analyze.py --strict --include=<스크롤 클래스>` | 실패 | **exit 0** | 실패(listview 두 건) |
| `compare.py 기준선 A`: 차이 행이 있는 로그 | — | **스크롤 클래스 로그뿐** (custom/scrollbox/treeview/synedit/listview*; memo/listbox/checklist 는 차이 없음) | — |

세부:
- **rehide**(표시→숨김→숨긴 채 -100h→다시 표시): 기준선은 숨긴 채의 `SetBounds` 에서도 강제 할당이 실행되어(`hid-shr`
  600×300 = FILL, codex §9-1 대로) 다시 표시된 뒤(`reshown`/`regrow`) STALE. A 는 숨긴 동안 1400×12000 을 유지하고 `reshown`/`regrow` 모두 정답.
- **inactivepage**(비활성 탭 안에서 -100h → 탭 활성화): 기준선은 활성화 시 우연히 정답, 그 다음 `act-grow` 부터 STALE.
  A 는 비활성 상태에서도 직접 할당(`:5267`)으로 사슬이 갱신되어(`inact-shr` custom 1385×12085, scrollbox 1400×12000) 활성화 후 전부 정답.
- **zero**(높이 0 → 400): LCL 은 1 로 클램프(`client=600x1`); A 는 `zero`/`unzero` 모두 정답, 기준선 STALE.
- **wsclient**(`out_v3*/`, shrink 단계): ListView 기준선 `600x300` → A `585x285`(GTK 정답 = 스크롤바 제외, 다른 위젯셋과 같은
  의미). Memo/memowrap/ListBox 는 overlay 스크롤바라 `600x300` 그대로. LCL 캐시 `client=` 는 모두 불변.
- **GL 렌더러 RSS**(`custom_hv_notruth_gl.txt`, `GSK=gl`, Xvfb/llvmpipe): 기준선(stale 600×400 GtkFixed) 201–210MB, A(콘텐츠
  1400×12000) 266–339MB → 표본 대응 **+63–128MB**. cairo 렌더러는 132 vs 135MB. RSS 는 원인을 직접 증명하지 않지만 codex
  §9-11 의 렌더러 소스 계산(장당 67MB ×2)과 크기가 맞는다. 이 비용은 수정 전에도 요청값이 바뀐 직후의 정상 상태(예: tomboy-ng
  의 리사이즈 전 paint 1417×12767)에 있던 것이며 stale 상태에서만 사라졌다. **별건 후보 §10-2(a)** 의 근거.
- 스크린샷 `shots_v2/custom_scroll2_base.png`(리사이즈 3회 뒤 스크롤 끝: 빈 상자) vs `custom_scroll2_expA.png`(11600…11960).
  `scrollbox_scroll2_*`, `treeview_scroll2_*` 도 같은 대비.

## 5. 원인 분류와 유사 사례

- **A. 태그된 스크롤용 GtkFixed** — `TGtk4CustomControl`, `TGtk4ScrollingWinControl`. LCL 쪽 대표 사용자:
  KMemo/KControls, `TTreeView`(LCL 자체 구현, `treeview.inc:4533-4543`), `TSynEdit`(IDE 소스 편집기), `TOICustomPropertyGrid`
  (`objectinspector.pp:272, :1225, :1283`), `TScrollBox`(`controlscrollbar.inc:233-242`), IDE 메시지 창(`etmessageframe.pas`).
  증상: 리사이즈(창 크기 변경 포함) 뒤 스크롤 위치 > 0 이면 빈 화면. 자식 GTK 위젯(TScrollBox 안 컨트롤)은 잘려서
  안 보이고 클릭도 안 된다(overflow hidden + 할당 밖).
- **B. GtkScrolledWindow 의 직접 자식(태그 없음)** — `TGtk4ListView`(실측), `TGtk4Memo`/`TGtk4ListBox`/`TGtk4CheckListBox`
  (동일 메커니즘, 오늘은 overlay 스크롤바라 무증상). 증상: 비-overlay 스크롤바가 보일 때 리사이즈 뒤 자식이 스크롤바
  아래까지 과대 할당(`TGtk4ListView` 는 `set_overlay_scrolling(False)` :10789/:10871). 실제 화면 영향은 작지만(스크롤바가
  위에 그려짐) GTK 정답 할당보다 15px 넓다(헤더/컬럼 표시에 미치는 영향은 실기 확인, 하네스는 할당만 잰다). A안이 함께 고친다.
- **C. 스크롤과 무관한 불일치(범위 밖, 기록만)**:
  - `TGtk4StaticText`: GtkLabel 을 프레임 border 안쪽이 아니라 외부 크기로 강제(2px 과대).
  - `TGtk4StatusBar`: 내부 GtkBox(H) 의 GTK 정답 높이가 0 — 강제 할당이 오히려 지금의 표시를 유지하고 있을 수 있음.
    **건드리면 안 되는 이유**로 기록.
  - `TGtk4ProgressBar`: `InitializeWidget :7861-7870` 이 GtkProgressBar 에 `set_size_request(W,H)` 를 넣은 채 SetBounds 가
    갱신하지 않아, 줄어들면 GTK 정답(400)과 강제 할당(300)이 어긋남. 별건.
  - `TGtk4SplitterSide`: 위젯셋 `SetBounds` 를 직접 부를 때만(`same`) GtkPaned 의 배치와 어긋남 — LCL 경로에서는
    `TGtk4Paned.SyncSideSizes` 가 되돌리므로 무증상.
  - `FPaintArea` 강제 할당(`:5292-5301`)도 스크롤 컨테이너에서는 오버레이 크기(콘텐츠)와 어긋나지만 `draw_func=nil`,
    `can_target=False` 라 LCL 그리기·피킹에는 관여하지 않는다(GTK 의 CSS 배경 그리기 경로만 남음, 테마 의존·미검증; §6.1).

## 6. 설계

### 6.1 채택안 A — GtkScrolledWindow 가 소유하는 중앙 위젯은 강제 할당하지 않는다

`gtk4widgets.pas:5278` 조건에 한 항 추가(§2.5 A 와 동일):

```pascal
    if Assigned(FCentralWidget) and (FCentralWidget <> FWidget)
       and not (LCLObject is TCustomGroupBox)
       and not (wtScrollingWin in FWidgetType) then
```

주석은 왜 제외하는지(§3: SW→Viewport→Overlay 가 자식 할당을 소유하고, 콘텐츠 크기는 `SetScrollInfo` 의
`set_size_request` 가 준다; 강제 할당은 오버레이 몰래 GtkFixed 만 줄여 놓아 회복되지 않는다)와 §1 의 GTK 근거를 적는다.

- **왜 `wtScrollingWin` 인가**: 스크롤 컨테이너를 식별하는 위젯셋 내부의 기존 술어(`SetScrollInfo` 가 같은 플래그를 씀).
  태그(`lcl-scroll-fixed`)는 GtkFixed 계열만 표시하고 §5-B 를 놓친다. 위젯 트리 검사(`Gtk4IsScrolledWindow(FWidget)`)도
  같은 집합이지만 의도가 덜 드러난다. `TGtk4Window` 도 플래그를 갖지만 자체 `SetBounds` 라 영향 없음.
- **왜 `queue_resize`/`queue_allocate` 를 추가하지 않는가**: 실측(§4.5)에서 불필요. 추가하면 SetBounds 마다 조상 전체
  재측정이 걸려 `preferredSize` 주석(`:5517-5532`)이 경고한 autosize 루프 위험을 새로 만든다. `queue_allocate(fixed)` 는
  §1.3 대로 오히려 잘못된 값을 재생한다. 단 §6.3 의 안전망 검토 항목으로 남긴다.
- **FPaintArea(`:5292-5301`)는 그대로 둔다**: LCL 그리기 노드는 GtkFixed 에서 나오고 DrawingArea 는 `draw_func=nil`,
  `can_target=False` 라 그리기/피킹에 관여하지 않는다(§5-C). GTK 가 위젯 CSS 배경을 그리는 경로는 남지만 DrawingArea 의
  기본 CSS 배경은 없다(테마 의존, 미검증). 오늘도 같은 상태이므로 최소 변경 원칙.

### 6.2 기각안

- **B(태그만)**: R1 은 고치지만 §5-B(ListView 과대 할당)를 남긴다. 사용자가 범위를 A 보다 좁게 잡으면 이것.
- **C(요청서 A안: 건너뛰고 `queue_resize(fixed)`)**: 동작은 하지만 위 이유로 불필요한 재측정. 실측상 이득 없음.
- **D(요청서 B안: `Max(클라이언트, size_request)`)**: 오버레이가 이미 정답을 갖고 있는데 다시 계산해 넣는 것. (요청서가
  말한 "위치도 `-adjustment.value` 여야 한다"는 틀렸다 — 스크롤 이동은 뷰포트가 **오버레이**에 주는 위치이고
  GtkFixed 는 오버레이 안에서 항상 `(0,0)` 이다, `gtkoverlaylayout.c:423-425`, `gtkviewport.c:543-546`.) 기각.
- **E(강제 할당 전면 삭제)**: 비스크롤 클래스에서 정답이 "GTK 계산값"이 맞는지 불명(`TGtk4StatusBar` 는 0 높이,
  `TGtk4ProgressBar` 는 stale 요청). 원 주석의 "stale 0x0" 사례를 재현하지 못했으므로 삭제 근거가 없다. 범위 밖.

### 6.3 코딩 전 확인/방어 항목 (codex 검토 대상)

1. **SW 사슬이 GtkFixed 를 할당하지 않는 경우가 있는가**: 외부 위젯(SW)이 숨겨진 상태에서 `SetBounds` 가 불리면 직접 할당은
   no-op(`gtk_widget_allocate` 는 자기 `visible` 만 검사, `gtk/gtkwidget.c:3938`; LCL 은 FWidget 만 숨김 `:4584-4588`)이지만
   **강제 할당은 실행된다**(GtkFixed 자신은 visible) — 즉 기존 코드는 숨긴 채로도 stale 을 만들고, A안은 직전의 올바른 할당을
   유지한다. 다시 표시될 때·비활성 탭 활성화 때·0 크기 복귀 때 GTK 가 사슬을 다시 놓는지는 `rehide`/`inactivepage`/`zero`
   시나리오로 실측(§4.7: A 전부 정답). 실현(realize)/맵 여부는 할당기가 검사하지 않는다.
2. 스크롤바 정책 토글(`HScrollBarPolicy := POLICY[...]`)이 SW 재배치를 유발하는 경로는 `SetScrollInfo` 안에 있고
   SetBounds 와 무관 — 변경 없음.
3. `TGtk4CustomControl.getClientRect`(:13727) 가 SW 할당을 쓰므로 스크롤 컨테이너의 LCL 클라이언트 크기·좌표는 이 변경에
   영향받지 않는다. 단 **Memo/ListBox/ListView 는 기본 `TGtk4Widget.getClientRect`(:5174-5177)** 가 중앙 위젯 할당을 읽으므로
   비-overlay 스크롤바가 보일 때 위젯셋 클라이언트 사각형이 스크롤바 폭만큼 줄어든다(다른 위젯셋의 의미와 같아짐).
   하네스의 `client=`(LCL 캐시)는 변화가 없었고, 위젯셋 직접 질의(`wsclient=`)는 §4.7 에서 실측한다.
4. GtkFixed 가 콘텐츠 크기가 되면 `LCLGtkFixedSnapshot` 의 cairo 노드가 콘텐츠 크기(예 1400×12000)가 된다 — 이것이
   원래 설계이며 정상 상태에서는 늘 그랬다(요청서 §2 "리사이즈 직전 paint: fixed 1417×12767"). **비용 주의(codex 지적,
   소스 확인)**: GL 렌더러는 cairo 노드를 노드 bounds 크기의 ARGB32 이미지 표면 2장으로 래스터라이즈해 텍스처로 올린다
   (`gsk/gl/gskglrenderjob.c:1187-1190`, `:1225-1242`) — 1400×12000 이면 장당 67MB. 이 비용은 **수정으로 새로 생기는 것이
   아니라 위젯셋의 기존 설계**(정상 상태의 비용)이고 stale 상태는 "싸지만 빈 화면"이었을 뿐이다. 실측(`rss=`, `GSK=gl`)은
   §4.7. 근본 개선(cairo 노드를 뷰포트 가시 영역으로 한정)은 별건 후보로 §10 에 올린다.
5. `TGtk4ListView`: 강제 할당 제거 후 GtkColumnView 할당(과 위젯셋 클라이언트 사각형)이 스크롤바 폭(15px)만큼 좁아지는 것이
   **정상**(GTK 정답; qt5 도 `TQtAbstractScrollArea.getClientBounds` 가 보이는 스크롤바를 뺀다, `qtwidgets.pas:17878-17890`).
   LCL 소비처(`customlistview.inc:1621` 마지막 컬럼 폭, `customlistbox.inc:871/889` 가시 항목, `wincontrol.inc:4202` 자식
   사각형)는 모두 스크롤바를 뺀 클라이언트를 기대한다(codex 2차 확인, 직접 대조는 qt5 만). 헤더 표시는 실기 확인 항목.

## 7. 단계별 작업 (각 단계 = rollback 커밋 1개 이상)

**Phase 0 — 기준선 보존(코드 변경 없음)**
- 하네스·스크립트·분석기·기준선 로그(`out/`, `out_modes/`, `out_expA/`, `out_expB/`, `shots/`, `order_custom_hv.txt`)를
  `baseline_2026-09-11/` 로 정리해 커밋(README 포함). 요청서에 사용자 재현 결과(§4.4)를 추기.

**Phase 1 — 수정 (`gtk4widgets.pas` 한 줄 + 주석)**
- §6.1 적용. 빌드: `./cbuild`(LCL gtk4 + IDE) 또는 최소 `make lcl LCL_PLATFORM=gtk4` 상당 + 하네스 재빌드(`build.sh gtk4`).
- 게이트 G1: `runall.sh out_fixed` + `runexp3.sh` 의 전체 시나리오(late/hidden/rehide/inactivepage/zero, 9개 스크롤
  컨트롤 변형) → `analyze.py --strict --include='^(custom|scrollbox|treeview|synedit|listview|listbox|checklist|memo)'`
  가 **exit 0**(STALE/STALE-X(notruth 로그를 같은 이름의 truth 로그 정답과 대조)/FILL/ORIGIN/NOSCROLL/NOSNAP/INCOMPLETE(모드별
  기대 단계 순서 불일치) 모두 0). 나머지 클래스는 `compare.py 기준선 out_fixed` 로 정규화 행(외부/중앙/부모 할당·요청·adjustment·
  lcl·client; 타임스탬프·포인터·rss 제외) 비교 → 차이는 스크롤 클래스 행에만 있어야 한다. 비스크롤 클래스도 `runall.sh` 로
  같은 회차에 다시 돌린다(2차 회차는 스크롤 클래스만 돌렸음).
- 게이트 G2: `scrollbox`/`custom`/`treeview`/`synedit` notruth 의 **리사이즈 뒤 스크롤(`scroll2`)** 스크린샷에 내용이 보임.
- 게이트 G3: 키 행렬 하네스(`example_gtk4_keymatrix_validation/runall.sh`) gtk4 재실행 → 이전 기준선과 signature 동일
  (스크롤 컨테이너 포커스/키 경로 회귀 없음 확인).

**Phase 2 — tomboy-ng 종단 검증(격리 빌드)**
- `tomboy-ng/` 를 스크래치에 복사하고 `LAZARUS_DIR=<이 저장소>/lazarus BUILD_ROOT=<스크래치> ./build_gtk4_clean.sh`
  (스크립트는 기본으로 `/usr/lib/lazarus/4.4` = 설치본을 먼저 잡으므로 **반드시 `LAZARUS_DIR` 지정**). 사용자 트리·바이너리는 건드리지 않는다.
- `test_entry_return/run_scroll_blank.sh <스크래치 tomboy-ng-gtk4>`: `pgdn-4~6`, `ctrl-end` 가 내용을 보여야 함(§4.4 와 대조).
- `test_entry_return/run.sh <스크래치 dbg>` 검색 시나리오(요청서 §5-2)와 짧은 줄 노트 회귀.

**Phase 3 — 문서·패키지**
- `LCL_GTK4_DEV.md` §9(신규), `HANDOFF_NEXT_SESSION.md`(2-pre0000, §0c, 실기 확인 항목), `TODO.md`(§5-C 후보), 메모리.
- deb `4.4+dfsg-6`(`deb_build/4.4/`, quilt 패치 재생성 절차는 `gtk4-deb-packaging` 메모리) — 사용자 요청 시.
- **사용자 실기 확인(필수)**: ① tomboy-ng `onion5`(사용자 빌드) 로 요청서 §1 표 재확인 ② IDE: 소스 편집기 스크롤 후
  창 크기 변경(수정 전에는 다음 스크롤 정보 갱신 전까지 편집기가 비어 보일 **수 있고**, 후에는 항상 정상) ③ Project Inspector/Code Explorer(TTreeView) 스크롤
  후 리사이즈 ④ Object Inspector 스크롤 후 리사이즈 + in-place editor 위치 ⑤ TScrollBox 폼 리사이즈 ⑥ TListView(비-overlay
  스크롤바)의 헤더/컬럼 표시 — GTK 정답 할당이 스크롤바 폭(15px)만큼 좁아지는 것이 정상 ⑦ 그룹박스 안 컨트롤(변경
  없어야 함) ⑧ 디자이너에서 TScrollBox/TTreeView 를 놓은 폼의 스크롤·리사이즈·선택 핸들.

## 8. 위험과 금지 사항

- `gtk4widgets.pas` 이외 파일 무변경. `TGtk4Window.SetBounds`, `SetScrollInfo`, `LCLFixedLayout*`, snapshot 은 건드리지 않는다.
- 비스크롤 클래스(§5-C)의 강제 할당은 이 계획에서 바꾸지 않는다(정답이 불명한 사례가 있음).
- `queue_resize` 를 SetBounds 에 넣지 않는다(autosize 루프 위험, §6.1).
- 하네스는 `TGtk4Widget(Handle).SetBounds` 를 직접 호출하는 `same` 단계를 포함하므로 LCL 경로와 다른 결과
  (`splitterside`)가 있을 수 있다 — LCL 경로 판정은 `shrink/grow/wider` 행으로 한다.
- 셸 함정: 백틱 든 마크다운은 `<<'EOF'`; codex 는 `< /dev/null`; `cd` 잔류 → 절대경로.

## 9. codex 교차검토 판정표 (gpt-6-astra)

1차 회신: 스크래치 `codex_alloc/review1.md`. 판정 원칙: 회신의 모든 주장을 소스/로그로 대조, 근거 없는 것은 기각.

| # | codex 주장 | 대조 결과 | 판정·반영 |
|---|---|---|---|
| 1 | 숨겨진 컨트롤: LCL 은 FWidget 만 숨기고(`:4584-4588`) `gtk_widget_allocate` 는 자기 `visible` 만 검사(`:3938`) → 숨긴 채 SetBounds 하면 SW 직접 할당은 no-op, 강제 할당은 실행. A안에서 GtkFixed 가 이전 할당을 유지 | 소스 일치. 단 이전 할당은 (A안에서) 정답이었고, 기존 코드는 이때 stale 을 만든다. 다시 보일 때 GTK 가 재배치하는지는 실측 필요 | **채택(실측 추가)**: `rehide` 시나리오 §4.7 |
| 2 | "미실현이면 no-op" 은 틀림 — 할당기는 실현/맵을 검사하지 않음 | 소스 일치(`:3938` 은 visible 만) | **채택**: §1.1, §6.3.1 문구 수정 |
| 3 | 비활성 노트북 페이지: GtkStack 은 비활성 자식을 할당하지 않지만 직접 호출은 가시 자손을 할당함; 프레임클럭의 회복은 미증명 | 구조 설명은 타당; 결과는 실측 필요 | **채택(실측 추가)**: `inactivepage` 시나리오 §4.7 |
| 4 | 0 크기 조기 반환 없음, 0→양수 회복 미검증 | 소스 일치 | **채택(실측 추가)**: `zero` 시나리오 §4.7 |
| 5 | `:5267` 이 항상 사슬을 재구성하지는 않음(깨끗하고 크기 같으면 건너뜀) → "보존" 논리로 서술해야 | 소스 일치(§1.2) | **채택**: §3.1 수정 |
| 6 | `queue_resize` 조상 표시는 이미 dirty/비가시/native 경계에서 멈춤 | 소스 일치(`:3605-3606`, `:3623-3631`) | **채택**: §1.3 문구 |
| 7 | `queue_allocate(overlay)` 도 회복 경로 | 소스 일치 | **채택**: §1.3 추가(설계에는 불필요) |
| 8 | 할당기는 자식을 할당하므로 "자기만 갱신" 은 부정확 | 일치 | **채택**: §1.1 문구 |
| 9 | 술어 범위: `wtScrollingWin` 7개 클래스 전부 SW 소유, 누락/오적용 없음; ListBox grid 모드·ListView 아이콘 모드·줄바꿈 Memo 미측정; Memo 의 `scroll` 단계가 실제로 스크롤 안 됨(vadj 0) | 로그 확인(`out_expA/memo_hv.txt` vadj=0) | **채택**: 하네스에 `listboxgrid`/`listviewicon`/`memowrap` 추가, SW 직접 자식은 GTK adjustment 로 스크롤, `NOSCROLL` 검사 |
| 10 | ListView "헤더 15px 좁아짐" 은 미검증(컬럼 폭을 측정하지 않음) | 맞음 | **채택**: "GTK 정답 할당이 15px 좁음"으로 한정, 헤더는 실기 확인 |
| 11 | 성능: GL 렌더러는 cairo 노드를 노드 크기 이미지 표면 2장으로 처리 → 1400×12000 은 134MB; "비용 불변" 은 근거 없음 | 소스 일치(`gskglrenderjob.c:1187-1190`, `:1225-1242`) | **채택**: §6.3.4 수정, `GSK=gl` + `rss=` 실측 §4.7, 근본 개선은 §10 후보 |
| 12 | 콘텐츠 크기 GtkFixed 는 그리기와 피킹(overflow hidden 위젯의 hit-test) 을 함께 고침 | 타당 | 참고(설계 지지) |
| 13 | 좌표: STALE 은 위치를 비교하지 않음; GtkFixed 는 오버레이 안 `(0,0)` 이고 스크롤 이동은 오버레이 위치 → 요청서 B안의 "-adjustment" 는 틀림 | 소스 일치 | **채택**: §6.2 D 문구, 분석기에 `FILL`(중앙=오버레이) 검사 |
| 14 | Memo/ListBox/ListView 의 위젯셋 `getClientRect` 는 중앙 할당을 읽으므로 A안이 클라이언트 사각형을 바꿀 수 있음; 하네스 `client=` 는 LCL 캐시 | 소스 일치(`:5174-5177`); 로그의 `client=` 는 두 변형에서 동일 | **채택(실측 추가)**: `wsclient=` 필드 §4.7, §6.3.3 서술 |
| 15 | FPaintArea: GTK 는 draw_func 이 nil 이어도 CSS 배경을 그림 → "영향 없음" 은 과함 | 원리 일치, 테마 의존 | **채택(문구)**: §6.1 |
| 16 | 게이트: notruth 는 STALE 이 못 됨, 위치 미비교, NOSNAP 도 0 — STALE=0 만으로 부족 | 맞음 | **채택**: `analyze.py --strict`(FILL/NOSCROLL/NOSNAP/INCOMPLETE), `compare.py` 정규화 비교 |
| 17 | 스크린샷이 리사이즈 **전** 스크롤 시점 | 맞음 | **채택**: `scroll2`(모든 리사이즈 뒤) 로 이동 |
| 18 | "문자 단위 동일" 게이트는 타임스탬프/포인터 때문에 무효 | 맞음 | **채택**: `compare.py` |
| 19 | `late` 케이스의 adjustment upper 11601 ≠ 12000 은 별개 관찰(첫 SetScrollInfo 가 미할당 SW 를 기준으로 변환) | 로그 일치(기준선·A 동일) | **참고**: 수정과 무관, §10 후보로 기록 |
| 20 | SetScrollInfo 의 조기 종료(`gtk4winapi.inc:5260-5263`)·`bRedraw=False` 때문에 "요청값이 옳다" 는 보장은 없음 | 소스 일치 | **참고**: 범위 밖(요청값 정확성은 별건) |
| 21 | 실기 게이트 "수정 전 편집기는 반드시 빈 화면" 은 과함 | 맞음(스크롤 정보 갱신으로 회복될 수 있음) | **채택**: §7 문구 |
| 22 | BeginUpdate/csDesigning 은 할당 경로에 분기 없음; 디자이너 그리기는 미측정 | 일치 | **참고**: 디자이너는 실기 확인 항목에 추가 |

2차 회신(`codex_alloc/review2.md`, 수정된 계획서·2차 로그 대상): "A안 유지 지지, 기존 강제 할당이 필요한 생애주기 상태 없음(task 3),
스크롤바 제외 클라이언트 사각형이 틀리는 LCL 소비처 없음(task 4, qt5 도 같은 의미)". 1차 판정표 22행 전부 확인. 추가 지적과 처리:

| # | codex 2차 주장 | 대조 | 처리 |
|---|---|---|---|
| 23 | §6.3.1 에 "미실현이면 no-op", "둘 다 no-op" 문구가 남아 있음(1·2행 반영 누락) | 맞음 | **반영**: §6.3.1 재작성 |
| 24 | §3.3 "회복은 queue_resize 뿐" 에 오버레이 `queue_allocate` 누락(7행) | 맞음 | **반영** |
| 25 | §5-B/§6.3.5 에 "헤더/컬럼 15px" 단정 잔존(10행) | 맞음 | **반영**: 할당·클라이언트 사각형으로 한정, qt5 근거 추가 |
| 26 | §5-C FPaintArea "영향 없음" 잔존(15행) | 맞음 | **반영** |
| 27 | §4.7: rehide 기준선 셈법을 STALE/FILL 로 분리; memo 는 차이 로그가 아님; inactivepage 값은 custom 전용; "첫 표시도 정상" 은 로그와 불일치(기준선 GL show 는 stale) | 로그 대조 일치 | **반영**: 표·본문 수정 |
| 28 | 분석기: 단계 수만 세어 잘린 로그가 통과, 위치(x,y) 미검사, notruth 의 SW 직접 자식 오류를 못 잡음(`listview_hv_notruth` 0) | 맞음 | **반영**: 모드별 기대 단계 순서, `ORIGIN`, `STALE-X`(truth 로그와 교차 대조) — 기준선 notruth 에서 42건 검출, A 는 0 |
| 29 | `compare.py` 가 일부 필드만 비교 | 맞음 | **반영**: 외부 할당/요청·hadj·lcl 포함 |
| 30 | `build_exp.sh` 가 실패해도 옛 바이너리를 재사용(`\|\| true`) | 맞음 | **반영**: 실패 시 exit 1, 옛 바이너리 삭제 |
| 31 | 2차 회차는 스크롤 클래스만 돌렸고 memowrap 텍스트는 끊기지 않는 토큰 | 맞음 | **반영**: 게이트 문구(비스크롤 클래스도 재실행), memowrap 텍스트를 띄어쓰기 있는 단어로 교체(Phase 1 게이트에서 재측정) |
| 32 | `zero` 는 LCL 이 1 로 클램프하므로 GTK 0 할당 자체는 미검증 | 맞음 | 참고(LCL 경로에서는 0 이 오지 않음) |

## 10. 사용자 결정 필요

1. 범위: **A(`wtScrollingWin` 전체, 권장)** vs B(태그만).
2. §5-C 항목을 `TODO.md` 후보로만 남길지(권장) 별건 요청으로 올릴지. 추가 후보(이번 조사에서 발견, 수정과 무관):
   (a) `LCLGtkFixedSnapshot` 의 cairo 노드를 콘텐츠 전체가 아니라 뷰포트 가시 영역으로 한정(GL 렌더러 메모리, §6.3.4);
   (b) 폼 표시 후 생성된 스크롤 컨트롤의 첫 `SetScrollInfo` 가 미할당 SW 기준으로 콘텐츠 크기를 변환해 범위가 어긋남
   (`late` 시나리오 upper 11601 vs 12000, §9-19).
3. deb `-6` 패키징과 공개 스냅샷 동기화 시점.

## 11. 부록 — 도구

- `lazarus/example_gtk4_allocmatrix_validation/`: `allocmatrix.lpr`, `build.sh gtk4`, `build_exp.sh <패치복사본> <접미사>`,
  `run.sh <control> [range] [mode] [display] [shot.png]`(`BIN=` 로 바이너리 선택), `runall.sh [outdir]`, `analyze.py [dir]`,
  `order.gdb`/`run_order.sh`(호출 순서 추적).
- 사용자 키트: `test_entry_return/run_scroll_blank.sh`, `run_queue_resize_check.sh`, `queue_resize.gdb`, `synth_long_only.note`.
- 탐색 에이전트 보고(GTK 할당 의미론, 위젯셋 조사)는 세션 스크래치에 있으며 본문에 인용한 줄 번호는 전부 직접 대조했다.

## 12. Phase 1 상세 설계 — 정확한 변경 (2026-09-11, 코딩 전; codex 3차 검토 대상)

사용자 결정(2026-09-11): "가장 안전하고 확실한 방법으로 진행" → §10-1 은 **A안**(측정으로 가장 넓게 검증된 쪽이며 §5-B 까지 같은
메커니즘). B 는 A 의 부분집합이므로 필요하면 조건을 태그 검사로 좁히는 한 줄 변경으로 되돌릴 수 있다.

### 12.1 변경 (유일한 코드 변경, `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas` `TGtk4Widget.SetBounds`)

```pascal
    { ... 기존 주석(GtkOverlay / stale 0x0) 유지 ... }
    Alloc.x := 0;
    Alloc.y := 0;
    Alloc.width := AWidth;
    Alloc.height := AHeight;
    if Assigned(FCentralWidget) and (FCentralWidget <> FWidget)
       and not (LCLObject is TCustomGroupBox)
       and not (wtScrollingWin in FWidgetType) then
    begin
      { ... 기존 주석(set_size_request 를 쓰지 않는 이유, 그룹박스 예외) 유지 ...

        Skipped for scrolling widgets (wtScrollingWin: TCustomControl/TScrollBox
        with the tagged scroll GtkFixed, and Memo/ListBox/ListView whose central
        widget is the GtkScrolledWindow's scrollable child): the scrolled window
        chain owns that allocation. For the scroll GtkFixed the right size is the
        CONTENT size that SetScrollInfo pushes via set_size_request (GtkViewport
        allocates the GtkOverlay/GtkFixed at MAX(viewport, request)); for a
        scrollable child it is the scrolled window's content area minus the
        visible non-overlay scrollbars. Forcing the outer size here overwrote
        that: gtk_widget_allocate updates only the child (and its descendants)
        and clears the child's own dirty flags (gtkwidget.c:4094), the parent is
        never told, so while its own size is unchanged it skips re-allocating
        (gtkwidget.c:4062), and a viewport scroll only moves the overlay whose
        measured size is unchanged. The GtkFixed then stayed at the LCL outer
        size, so LCLGtkFixedSnapshot's content-sized painting and the overflow
        clip went blank once scrolled (KMemo/TTreeView/TSynEdit/TScrollBox after
        any resize). The direct size_allocate(Widget) above already keeps the
        chain correct; nothing else is needed (PLAN_GTK4_SCROLLFIXED_ALLOCATION.md). }
      gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
    end;
```

- `FPaintArea` 블록(`:5292-5301`)과 `Move` 는 그대로. `wtScrollingWin` 은 `FWidgetType` 에 이미 있는 플래그(§2.2) — 새 필드·새
  술어 없음. `TGtk4Window` 는 자체 `SetBounds` 라 이 블록을 지나지 않는다.
- 이 변경은 §2.5 의 실험 패치 **A 와 동일한 조건**이며, 주석만 추가된다. 실험 바이너리(`build_exp.sh`)로 검증한 코드와 저장소
  코드가 같음을 Phase 1 게이트에서 `out_fixed` 로 다시 확인한다.

### 12.2 실행 순서

0. Phase 0 커밋(rollback point): 계획서·요청서·하네스(소스/스크립트/README/.gitignore/기준선 로그·스크린샷)·사용자 재현 키트.
1. 위 변경 적용 → `lazarus/` 에서 `./cbuild inc`(`make lcl` + `make bigide`, `Error:|Fatal:` 무출력) → **두 하네스 모두 재링크**
   (`example_gtk4_allocmatrix_validation/build.sh gtk4`, `example_gtk4_keymatrix_validation/build.sh gtk4`; 두 스크립트는 실패 시
   exit 1 + 옛 바이너리 삭제로 고침). 새 코드가 들어갔는지는 `gtk4widgets.ppu/.o` 와 하네스 바이너리의 mtime 이 소스 편집 뒤인지,
   그리고 행렬 결과 자체(기준선 STALE → 0)로 확인한다(`nm` 은 한 줄 조건을 보여주지 못함).
2. 게이트 G1: (a) `runexp3.sh` 와 같은 시나리오 집합을 고정 빌드 바이너리로 → `out_fixed/`; `analyze.py out_fixed --strict
   --include=<스크롤 클래스>` exit 0; `compare.py out_v2 out_fixed` 차이 = 스크롤 클래스 로그뿐. (b) `runall.sh out_fixed_all`
   (1차 행렬과 같은 집합) → `compare.py out out_fixed_all` 차이 = 스크롤 클래스 로그뿐(비스크롤 클래스 행 차이 0).
3. 게이트 G2: `scroll2` 스크린샷(custom/scrollbox/treeview/synedit) 에 내용.
4. 게이트 G3: 키 행렬 하네스를 **재링크한 뒤** gtk4 재실행(`runall.sh gtk4`) → 변경 전 `out/` 에서 만든 signatures
   (`km_before_{seq,iso}.json`, 2026-09-11 13:47 실행본) 와 `compare.py` 비교, 변경 0.
5. Phase 2: tomboy-ng 를 스크래치 복사본에서 `LAZARUS_DIR=<repo>/lazarus BUILD_ROOT=<scratch>` 로 격리 빌드 →
   `run_scroll_blank.sh` 재실행: `pgdn-4..6`, `ctrl-end` 가 내용(§4.4 기준선은 빈 화면).
6. 커밋(수정 1개) → 문서(LCL_GTK4_DEV.md §9, HANDOFF, TODO, 메모리) → deb `4.4+dfsg-6`.

## 13. Phase 1–2 결과 (2026-09-11)

- codex 3차(§12 대상, `codex_alloc/review3.md`): 컴파일·타 경로 의존에 대한 결함 보고 없음. 지적 5건 모두 반영 — G3 는 키 행렬
  하네스를 재링크한 뒤 실행, G1 명령의 디렉터리 인자·비교 집합, 두 하네스 `build.sh` 실패 시 exit 1(옛 바이너리 삭제), 주석 문구
  ("visible non-overlay scrollbars", "updates only the child (and its descendants)", "while its own size is unchanged", "LCL outer size").
- 커밋: 0067452(Phase 0) → **7289a76**(§12.1 그대로). 빌드 `./cbuild inc` 에러 0, `gtk4widgets.ppu/.o` 16:54:01 > 소스 16:54:00.
- G1: `rungate.sh` → `out_fixed/` strict exit 0(33 로그 전부 0); `compare.py out_v2 out_fixed` 차이 로그 = custom/scrollbox/treeview/
  synedit/listview/listviewicon/memowrap(텍스트 교체) 뿐; `compare.py out out_fixed_all` 차이 = 스크롤 클래스(+ memo/checklist 는
  scroll 단계가 실제로 스크롤하게 된 vadj 차이뿐), 비스크롤 9 클래스 차이 0.
- G2: `shots_fixed/` custom/scrollbox/treeview/synedit `scroll2` 에 내용.
- G3: 키 행렬 gtk4 재실행(재링크 후) — 순차 300/300 불변; 격리 7행(button Tab, comboedit/grid/radio/spin/trackbar/treeview shift+Tab)
  변화는 알려진 재포커스 타이밍 노이즈(재실행 2회에서 서로 다른 행이 흔들림, README 의 판정 규칙대로 순차 모드가 정본).
- Phase 2: tomboy-ng 스크래치 복사본을 `LAZARUS_DIR=<repo>/lazarus` 로 격리 빌드(사용자 트리·바이너리 무변경) →
  `run_scroll_blank.sh`: `pgdn-1..6`, `ctrl-end` 모두 내용 표시(기준선 §4.4 는 `pgdn-3` 부터 빈 화면); `run.sh` 검색 시나리오
  `SEARCH_TERM=ubi` + `synth_long_only.note`: `2-typed` 에 578–581행 사이 `ubi` 강조.
- 사용자 실기 확인 항목은 `HANDOFF_NEXT_SESSION.md` 2-pre0000.

### 13.1 성능 검토 (2026-09-11 저녁, 사용자 요청; 하네스 `perf`/`perfstale` 모드, `out_perf/`, 수정 전 바이너리는 `exp_gtk4_base`)

40회 스크롤(1/4↔3/4 위치, 매번 Invalidate 후 paint 대기), custom hv(1400×12000), Xvfb(GL 은 llvmpipe 소프트웨어):

| 상태 | 렌더러 | wall ms/step | cpu ms/step | RSS |
|---|---|---|---|---|
| 수정 전, 리사이즈 뒤(stale 600×300, 화면은 빈 상태) | cairo | 16.3 | 4.8 | 132MB |
| 수정 전, 리사이즈 뒤(stale) | gl | 16.6 | 14.0 | 211MB |
| 수정 후(콘텐츠 1385×12085) | cairo | 16.5 | 8.0 | 134MB |
| 수정 후(콘텐츠) | gl | 119.0 | 132.0 | 342MB |
| 수정 전, 리사이즈 없음(정상 상태 = 콘텐츠 크기) | gl | 118.6 | 131.0 | 342MB |

- 수정 전 정상 상태와 수정 후는 **같은 수치**(마지막 두 행) — 수정은 새 비용을 만들지 않고, stale 상태(싸지만 빈 화면)를 없앤다.
- 비용의 원인은 `LCLGtkFixedSnapshot` 이 GtkFixed 할당(콘텐츠) 크기의 cairo 노드를 만드는 기존 설계: GL 렌더러는 이 노드를 노드 크기의
  이미지 표면으로 래스터라이즈해 텍스처로 올린다(§6.3.4). cairo 렌더러는 클립 밖을 그리지 않아 차이가 작다.
- **1400×60000 콘텐츠 + GL**: cairo 이미지 표면 한계(32767px)를 넘어 `gdk_texture_new_for_surface` 실패 →
  `gsk_gl_driver_cache_texture` 단언 → abort(exit 134). 수정 전 바이너리도 첫 표시부터 동일(정상 상태가 콘텐츠 크기이므로). cairo 렌더러는
  정상. → `TODO.md` H2 를 우선순위 높음으로.
- 키 pre-dispatch(057dd09) 쪽: 키 1회당 추가 작업은 길이 ≤16 배열의 선형 탐색·이벤트 ref 1회·`SetLength` 1회뿐(`gtk4widgets.pas:6796-6860`),
  LCL 메시지 수는 이전과 같다(capture 전달분은 bubble 에서 중복 제거). 측정 불필요 수준.

## 14. H2 상세 설계 — `LCLGtkFixedSnapshot` 의 cairo 노드를 뷰포트 가시 영역으로 한정 (2026-09-11 저녁, 코딩 전; codex 검토 대상)

사용자 요청: §13.1 의 성능 검토 뒤 "해결 가능한가" → 시제품(스크래치 `exp_gtk4_H2`)으로 확인, 이제 정식 작업. 상태: **저장소 코드 변경 없음**.

### 14.1 확정 사실 (GTK 4.6.9 소스, 직접 대조)

1. `gtk_snapshot_append_cairo(snapshot, bounds)` (`gtk/gtksnapshot.c:1890-1911`): bounds 를 현재 affine 으로 변환해
   `gsk_cairo_node_new(real_bounds)` 를 만들고, 돌려주는 `cr` 에는 `cairo_scale(scale)`·`cairo_translate(dx,dy)` 만 건다
   (`:1902-1910`) — 즉 **cr 의 좌표계는 bounds 의 origin 과 무관하게 위젯 좌표**이고, bounds 는 클립/노드 크기만 정한다.
2. `gsk_cairo_node_get_draw_context` (`gsk/gskrendernodeimpl.c:2529-2560`): 노드 bounds 를 extents 로 하는 **recording surface**
   (`:2548-2554`) — origin 이 (ScrollX,ScrollY) 여도 그 위치의 그림이 기록된다. cairo 렌더러는 이 surface 를 `cairo_paint`
   (`:2458-2468`), 화면 클립 밖은 그리지 않는다.
3. GL 렌더러 `gsk_gl_render_job_visit_as_fallback` (`gsk/gl/gskglrenderjob.c:1184-1290`): 노드 bounds 크기(×scale)의 ARGB32 이미지
   표면 2장(`:1225`, `:1240`)에 노드를 그려 `gdk_texture_new_for_surface`(`:1275`) 로 올린다. 텍스처 캐시 키는 노드 포인터
   (`:1208`)이고 노드는 snapshot 마다 새로 만들어지므로 **프레임마다 전량 재래스터라이즈·재업로드**. 표면이 cairo 한계
   (32767px, `CAIRO_STATUS_INVALID_SIZE`)를 넘으면 `gsk_render_node_draw` 단언 → 텍스처 생성 실패 →
   `gsk_gl_driver_cache_texture`(`gsk/gl/gskgldriver.c:705-713`) 단언으로 **abort**(§13.1 실측 exit 134).
4. 뷰포트가 보여 주는 GtkFixed 영역 = 오버레이 위치 `(-hvalue,-vvalue)`(`gtkviewport.c:543-546`) 의 역, 크기 = adjustment
   `page_size`(= 뷰포트 크기, `viewport_set_adjustment_values`). GtkFixed 는 오버레이 안 `(0,0)`(§9-13).

### 14.2 확정 사실 (위젯셋)

- `LCLGtkFixedSnapshot`(`gtk4widgets.pas:3037-3108`): `w/h := get_allocated_width/height(fixed)`(= 7289a76 이후 항상 콘텐츠 크기),
  bounds `(0,0,w,h)`, `cairo_translate(ScrollX, ScrollY)` 뒤 `GtkEventPaint`(→ LCL 은 클라이언트 좌표로 그림).
- `GtkEventPaint`(`:3576-3636`)는 `cairo_clip_extents` 로 `rcPaint` 를 만든다(`:3604-3610`) → 현재 값은 `(0,-ScrollY, w, h)`
  (실측 `PAINTCLIP 0,-8700 1400x12000`, 클라이언트 600×400). qt5/gtk2 에서는 rcPaint 가 클라이언트 영역이다.
- `TGtk4Window`(폼의 스크롤 GtkFixed): adjustment 가 0 에 고정(`Gtk4WindowV/HScrollPinCB :14006/:14023`), 실측 `vadj=0/600/600`
  → ScrollX=ScrollY=0, page_size = 할당 → 이 변경은 폼에서 **동작 불변**(스크린샷 md5 동일 `6547f1e6`).
- 디자이너: `GtkEventDesignerPaint`(`:3096-3097`)가 같은 cr 에 그린다(선택 핸들·그리드). 디자인 폼은 `TGtk4Window` 라 불변;
  디자인 중인 TScrollBox 안 컨트롤의 핸들은 스크롤된 뷰포트 안에만 보이면 되므로 가시 영역 노드로 충분(실기 확인 항목).

### 14.3 변경 (유일한 코드 변경, `LCLGtkFixedSnapshot`; 시제품과 동일)

```pascal
var
  ...
  ScrollX, ScrollY: gint;
  VisW, VisH: gint;          { + }
  ...
      ScrollX := 0;
      ScrollY := 0;
      VisW := w;                                   { + }
      VisH := h;                                   { + }
      if g_object_get_data(PGObject(widget), 'lcl-scroll-fixed') <> nil then
      begin
        if LCLWidget is TGtk4ScrollableWin then
        begin
          sw := TGtk4ScrollableWin(LCLWidget).getScrolledWindow;
          if (sw <> nil) and Gtk4IsScrolledWindow(PGObject(sw)) then
          begin
            adj := sw^.get_hadjustment;
            if adj <> nil then
            begin
              ScrollX := Trunc(adj^.get_value);   { * Round→Trunc: GTK stores -value in an int allocation,
                                                     truncation toward zero, gtkviewport.c:543-544 }
              VisW := Round(adj^.get_page_size);   { + }
            end;
            adj := sw^.get_vadjustment;
            if adj <> nil then
            begin
              ScrollY := Trunc(adj^.get_value);   { * }
              VisH := Round(adj^.get_page_size);   { + }
            end;
          end;
        end;
      end;

      { The cairo node covers only the part of the (content-sized) scroll GtkFixed
        that the viewport shows: origin = scroll offset, size = viewport page size.
        The LCL paints its client area at that origin (translate below), so nothing
        visible is lost, GtkEventPaint's rcPaint becomes the client area (as on
        qt5/gtk2), and the GL renderer no longer rasterizes/uploads the whole
        content per frame (gskglrenderjob.c:1225 sizes its surfaces by the node;
        content taller than cairo's 32767px limit aborted there). Clamped to the
        allocation; full node when the page size is not known yet or the
        adjustment is outside the allocation. }
      if (VisW <= 0) or (VisH <= 0) or (ScrollX < 0) or (ScrollY < 0)
         or (ScrollX >= w) or (ScrollY >= h) then
      begin
        ScrollX := Max(ScrollX, 0); ScrollY := Max(ScrollY, 0);
        bounds.origin.x := 0;
        bounds.origin.y := 0;
        bounds.size.width := w;
        bounds.size.height := h;
      end
      else
      begin
        bounds.origin.x := ScrollX;
        bounds.origin.y := ScrollY;
        bounds.size.width := Min(VisW, w - ScrollX);
        bounds.size.height := Min(VisH, h - ScrollY);
      end;
      cr := gtk4_snapshot_append_cairo(snapshot, @bounds);
      { 이하 기존: translate(ScrollX, ScrollY) → GtkEventPaint → (디자인) GtkEventDesignerPaint }
```

- 비태그 GtkFixed(패널·툴바 등)는 `VisW/VisH = w/h`, ScrollX/Y = 0 → bounds `(0,0,w,h)` 그대로 → **동작 불변**.
- `Round`→`Trunc`(codex 4차 §14.6-2): adjustment 값이 소수(휠 smooth scroll)일 때 GTK 는 `-value` 를 int 로 잘라(0 방향)
  오버레이를 옮기므로(`gtkviewport.c:543-544`) 노드 origin 과 translate 도 같은 값을 써야 0번 행/열이 잘리지 않는다. 기존 translate
  의 `Round` 도 함께 고침(1px 불일치 해소).

### 14.3b 두 번째 hunk (v3) — adjustment 가 바뀌면 스크롤 GtkFixed 를 다시 snapshot 하게 함

GTK 는 부모(오버레이)만 움직이거나 커진 자식의 **캐시된 render node 를 재사용**한다(`gtk_widget_queue_draw` 는 자기+조상만
`draw_needed`, `gtkwidget.c:3538-3549`; `gtk_widget_snapshot` 은 `render_node` 가 있으면 그대로 붙임 `:11636-11647`). 전체 콘텐츠
노드였을 때는 어느 위치·크기로 보여도 맞는 그림이었지만, 가시 영역 노드는 **위치(value)나 크기(page_size)가 바뀔 때마다 다시
snapshot** 되어야 한다. 실제 컨트롤은 LM_VSCROLL 에서 Invalidate 하지만 예외가 있다(codex 4차: `TScrollBox` 의 `Tracking=False`
썸 드래그·`csDesigning` 은 스크롤 메시지 무시 `controlscrollbar.inc:286/301`; codex 5차: 위치는 그대로고 뷰포트만 커지는 리사이즈는
`value-changed` 가 나지 않음 — `gtk_adjustment_configure` 는 값이 바뀔 때만 `value-changed`, 그 외는 `changed`,
`gtkadjustment.c:847-860`). 실측: 스크롤 메시지를 처리하지 않는 컨트롤을 GTK adjustment 로 직접 스크롤(`gtkscroll`)하면 v1 시제품이
빈 화면(`shots_gtkscroll/custom_H2.png`); 아래 v2 로는 `gtkscroll`·`growmid`(가운데로 스크롤 → -100h → +100h) 모두 현재 수정본과 md5 동일.

- 전용 콜백 `Gtk4ScrollFixedRedrawCB` 를 두 adjustment 의 **`changed` 와 `value-changed`** 에 연결(`SetScrollBarsSignalHandlers`,
  기존 `Gtk4ScrollAdjChangedCB` 는 손대지 않음 → LM_*SCROLL 전달 의미 불변). 하는 일: 소유자가 살아 있고 `GetContainerWidget` 이
  태그된 GtkFixed 이면 `queue_draw`. `InUpdate` 와 무관(SetScrollInfo 는 BeginUpdate 안에서 configure 한다, `gtk4winapi.inc:5268`;
  `ScrollBy` 는 wrapper 없이 `set_value` 후 Invalidate, `gtk4wscontrols.pp:807-839`).
- **snapshot 중 무효화 유실 방지**(codex 5차): LCL 그리기 코드가 그리는 도중 스크롤 상태를 바꾸면 `queue_draw` 는 이미 선
  `draw_needed` 에 막혀 무시되고(`gtkwidget.c:3545`) snapshot 이 끝나며 플래그가 지워진다(`:11629`) → 노드가 그리기 전 bounds 로 캐시.
  `LCLGtkFixedSnapshot` 이 LCL 그리기 구간에서 `Gtk4ScrollFixedSnapshotDepth` 를 올리고, 콜백은 그 안이면 `g_idle_add` 로
  미룬다. idle 은 `TGtk4Paned` 패턴(`:3378-3384`, `:3404`, `:3421`)대로 **소스 id 를 필드(`FRedrawIdleId`)에 보관해 병합**하고
  `DetachEvents` 에서 `g_source_remove`; idle 콜백은 `Gtk4IsLiveWidgetPointer` 검사 뒤 **깊이를 다시 확인**해 아직 snapshot 안이면
  (LCL 그리기 중 `Application.ProcessMessages` 가 중첩 루프로 idle 을 돌린 경우, `gtk4object.inc:559`) `G_SOURCE_CONTINUE` 로
  남는다(codex 6차).

```pascal
var  { 구현부 상단, OrigFixedLayoutAllocate 옆 }
  { >0 while LCLGtkFixedSnapshot runs LCL painting (see Gtk4ScrollFixedRedrawCB) }
  Gtk4ScrollFixedSnapshotDepth: Integer = 0;

function Gtk4ScrollFixedRedrawIdleCB(AData: gpointer): gboolean; cdecl;
begin
  Result := G_SOURCE_REMOVE_;
  if (AData = nil) or not Gtk4IsLiveWidgetPointer(AData) then Exit;
  { still inside the fixed's snapshot (a nested main loop is pumping while LCL
    paint code runs): a queue_draw now would be discarded, try again later }
  if Gtk4ScrollFixedSnapshotDepth > 0 then Exit(G_SOURCE_CONTINUE);
  TGtk4ScrollableWin(AData).FRedrawIdleId := 0;
  if TGtk4Widget(AData).GetContainerWidget <> nil then
    TGtk4Widget(AData).GetContainerWidget^.queue_draw;
end;

procedure Gtk4ScrollFixedRedrawCB(AAdj: PGtkAdjustment; AData: TGtk4ScrollableWin); cdecl;
var
  CW: PGtkWidget;
begin
  if (AAdj = nil) or (AData = nil) then Exit;
  if not Gtk4IsLiveWidgetPointer(AData) then Exit;
  if AData.LCLObject = nil then Exit;
  CW := AData.GetContainerWidget;
  if (CW = nil) or (g_object_get_data(PGObject(CW), 'lcl-scroll-fixed') = nil) then Exit;
  if Gtk4ScrollFixedSnapshotDepth > 0 then
  begin
    if AData.FRedrawIdleId = 0 then     { coalesce; removed in DetachEvents }
      AData.FRedrawIdleId := g_idle_add(@Gtk4ScrollFixedRedrawIdleCB, AData);
  end
  else
    CW^.queue_draw;
end;

{ TGtk4ScrollableWin: private field FRedrawIdleId: guint; DetachEvents 첫머리에서
  if FRedrawIdleId <> 0 then begin g_source_remove(FRedrawIdleId); FRedrawIdleId := 0; end; }

{ SetScrollBarsSignalHandlers: 가로/세로 각 adjustment 의 기존 value-changed 연결 뒤에 }
      g_signal_connect_data(AAdj, 'changed', TGCallback(@Gtk4ScrollFixedRedrawCB), Self, nil, G_CONNECT_DEFAULT);
      g_signal_connect_data(AAdj, 'value-changed', TGCallback(@Gtk4ScrollFixedRedrawCB), Self, nil, G_CONNECT_DEFAULT);

{ LCLGtkFixedSnapshot: LCL 그리기 구간 }
          Inc(Gtk4ScrollFixedSnapshotDepth);
          LCLWidget.GtkEventPaint(widget, cr);
          if csDesigning in LCLWidget.LCLObject.ComponentState then
            LCLWidget.GtkEventDesignerPaint(widget, cr);
        finally
          Dec(Gtk4ScrollFixedSnapshotDepth);
          cairo_destroy(cr);
```

- 비용: adjustment 변경당 가시 영역 1회 재그리기 — 정상 컨트롤의 Invalidate 와 같은 프레임에 병합. `changed` 는 lower/upper/
  step/page 중 **실제로 바뀐** 속성이 있을 때만 난다(`gtkadjustment.c:348`, 세터는 값이 다를 때만 notify `:794`; SetScrollInfo 는
  값이 같으면 `gtk4winapi.inc:5262` 에서 조기 종료) → 같은 값을 반복해도 재그리기 루프는 닫히지 않는다(codex 6차). 비태그(Memo/ListBox/ListView)는 콜백 초입에서 제외. `TGtk4Window`(폼)은
  `SetScrollBarsSignalHandlers` 를 쓰지 않고 자체 pin 콜백이라 무관(0 고정, 폼 노드는 전체).
- 시그널 정리: `TGtk4ScrollableWin.DetachEvents` 는 두 adjustment 에서 **data=Self 인 모든 핸들러**를 끊으므로
  (`g_signal_handlers_disconnect_matched(..., G_SIGNAL_MATCH_DATA, ..., Self)`, `:9130/:9138`) 새 연결도 함께 정리된다(codex 6차).

### 14.4 시제품 실측 (스크래치 `exp_gtk4_H2`, `out_perf/*expH2*`, `shots_H2/`, `out_H2/`)

| | 렌더러 | cpu ms/step | wall ms/step | RSS | 비고 |
|---|---|---|---|---|---|
| 현재(7289a76) custom 1400×12000 | gl | 132 | 119 | 342MB | |
| **H2** | gl | **19** | **16** | **213MB** | |
| 현재 | cairo | 8 | 16 | 134MB | |
| H2 | cairo | 7 | 17 | 133MB | |
| 현재 1400×60000 | gl | abort(134) | | | cairo 한계 |
| **H2 1400×60000** | gl | 30 | 23 | 213MB | 정상 |
| scrollbox 현재 → H2 | gl | 99 → 27 | | | |

- 스크린샷(리사이즈 3회 뒤 스크롤 끝) custom/scrollbox/treeview/synedit/formscroll: 현재 수정본과 **PNG md5 동일**.
- 할당 게이트(`out_H2/`): strict exit 0, 분석기 행이 현재 수정본과 차이 0(할당은 건드리지 않으므로 당연).
- `PAINTCLIP`: 현재 `0,-8700 1400x12000` → H2 `0,0 585x385`(클라이언트에서 스크롤바 뺀 크기).

### 14.5 게이트 (Phase H2-1)

1. 변경 적용(14.3 + 14.3b) → `./cbuild inc` 에러 0 → 두 하네스 재링크.
2. `rungate.sh _H2`(접미사에 밑줄 포함; 실패 시 exit 1) → `out_fixed_H2/` strict exit 0, `compare.py out_fixed out_fixed_H2`
   차이 = `gtkscroll` 로그(새 시나리오)뿐 — 할당 불변.
3. 스크린샷 동일성(`shots_fixed_H2/` vs 기준): custom/scrollbox/treeview/synedit `scroll2`·`gtkscroll`·`growmid`, formscroll,
   panel/groupbox/toolbar/page/statictext — 모두 PNG md5 가 현재 수정본(`shots_fixed/`, `shots_gtkscroll/*_fixed.png`,
   `shots_nonscroll/`, `shots_H2/formscroll_scroll2_fixed.png`)과 동일.
4. perf: custom hv gl cpu/step ≤ 30ms, tall gl 정상 종료, `PAINTCLIP` = 클라이언트 크기.
5. 키 행렬 순차 300/300 불변(재링크 후).
6. tomboy-ng 격리 재빌드 → `run_scroll_blank.sh` digest 가 7289a76 빌드(`tomboy_fixed/`)와 **동일**, 검색 시나리오 동일.
7. 사용자 실기: 디자이너의 TScrollBox 안 컨트롤 선택 핸들, KMemo/SynEdit 부분 갱신(타이핑·캐럿·검색 강조), OI, TreeView,
   TScrollBox 썸 드래그(Tracking=False)·휠 스크롤.

### 14.6 codex 4차 판정표 (§14 초안 대상, `codex_alloc/review4.md`)

| # | 주장 | 대조 | 처리 |
|---|---|---|---|
| 1 | 네이티브 스크롤 시 GtkFixed 미무효화 → 가시 영역 노드가 옮겨지기만 해 새로 드러난 띠가 빔; TScrollBox `Tracking=False`·`csDesigning` 은 스크롤 메시지 무시 | `controlscrollbar.inc:286/301`, `gtkwidget.c:3538-3549`, `:11646` 일치; 하네스 `gtkscroll` 로 재현 | **채택**: §14.3b(adjustment 변경 시 queue_draw) |
| 2 | `Round(value)` 와 GTK 의 int 절단이 어긋나 소수 값에서 0번 행/열 손실 | `gtkviewport.c:543-544` 일치 | **채택**: `Trunc` |
| 3 | 게이트 2 의 디렉터리 접미사(`rungate.sh H2` → `out_fixedH2`), formscroll 스크린샷 생성 누락 | 맞음 | **채택**: `_H2`, rungate.sh 에 formscroll/비스크롤 스크린샷 추가 |
| 4 | rungate.sh 가 실패를 exit 코드로 전하지 않음 | 맞음 | **채택**: strict 실패 시 exit 1 |
| 5 | rcPaint 소비처 회귀 없음(TCustomControl/스크롤 배경/디자이너/KMemo/SynEdit 검토) | — | 참고 |

### 14.7 codex 5차 판정표 (§14 v1 대상, `codex_alloc/review5.md`)

| # | 주장 | 대조 | 처리 |
|---|---|---|---|
| 1 | 위치는 그대로고 뷰포트만 커지면 `value-changed` 가 없어 새로 드러난 띠가 빔 | `gtkadjustment.c:847-860`(value 가 바뀔 때만 value-changed), `gtkviewport.c:535` 일치; `growmid` 시나리오 추가 | **채택**: `changed` 에도 연결(§14.3b v2) |
| 2 | snapshot 중 adjustment 가 바뀌면 queue_draw 가 유실됨(`draw_needed` 선점 후 snapshot 끝에 소거) | `gtkwidget.c:3545`, `:11609-11629` 일치 | **채택**: 깊이 카운터 + idle 지연 |
| 3 | 주석의 "ScrollBy 가 BeginUpdate 안에서 값 설정" 은 틀림(래퍼는 SetScrollInfo) | `gtk4wscontrols.pp:807-839`, `gtk4winapi.inc:5268` 일치 | **채택**: 주석 수정 |

시제품 v2 실측: `growmid`/`gtkscroll`/`scroll2` 스크린샷 4~5종 모두 현재 수정본과 md5 동일, GL perf 17ms/step(v1 19), RSS 213MB.

### 14.8 codex 6차 판정표 (§14 v2 대상, `codex_alloc/review6.md`)

| # | 주장 | 대조 | 처리 |
|---|---|---|---|
| 1 | 시그널은 DetachEvents 의 `disconnect_matched(DATA=Self)` 로 이미 정리됨; idle 은 소스 id 를 버려 소유자 해제 뒤 실행 가능(주소 재사용 시 다른 위젯을 그림) → Paned 패턴(보관·병합·DetachEvents 에서 제거) | `:9130/:9138`, `:3404/:3421`, `:4959`, `:2154` 일치 | **채택**: `FRedrawIdleId` + `g_source_remove` |
| 2 | "changed 는 SetScrollInfo 마다" 는 틀림 — 실제로 바뀐 속성만; 자기유지 루프 경로 없음 | `gtkadjustment.c:348/:794/:859`, `gtk4winapi.inc:5262` 일치 | **채택**: 문구 수정 |
| 3 | snapshot 중 `g_idle_add` 는 허용되나, 그리기 중 `ProcessMessages` 중첩 루프가 idle 을 돌리면 여전히 유실 → idle 이 깊이를 재확인해야 | `gtk4object.inc:559`, `gtkwidget.c:3545/:11629` 일치; `G_SOURCE_CONTINUE = true` (`lazglib2.pas:130`) | **채택**: 깊이 재확인, `G_SOURCE_CONTINUE` |
| 4 | 깊이 카운터는 중첩·예외에 안전 | 일치 | 참고 |
| 5 | rungate.sh 에 `growmid` 없음, growmid 에 SynEdit 분기 없음 | 맞음 | **채택**: 둘 다 추가 |

시제품 v3 실측: growmid/scroll2/gtkscroll 스크린샷 custom/scrollbox/treeview 모두 md5 동일; **synedit growmid 만 1픽셀 차이**
(`compare -metric AE` = 1, 위치 `(74,404)` = 뷰포트 맨 아래 행의 거터 구분선 끝 — 노드 경계에서의 안티앨리어싱, 재실행 2회 모두
같은 값으로 안정). 스크롤 상태(`hadj=1/1543/585 vadj=200/660/385`)는 동일. 허용(경계 1px)으로 판정. GL perf 17ms/step, tall 정상.

## 15. H2 결과 (2026-09-11 밤)

- 커밋 **670a720**(§14.3 + §14.3b v3 그대로). `./cbuild inc` 에러 0(ppu 21:10:34 > 소스 21:10:33), 두 하네스 재링크.
- G1 `rungate.sh _H2`: strict exit 0(분석기에 growmid/gtkscroll 기대 순서 추가 뒤); `compare.py out_fixed out_fixed_H2` 차이 =
  새 시나리오 로그(growmid/gtkscroll)뿐 — 할당 불변.
- G2 스크린샷(`shots_fixed_H2/`): custom/scrollbox/treeview `scroll2`·`gtkscroll`·`growmid`, synedit `scroll2`·`gtkscroll`,
  formscroll, panel/groupbox/toolbar/page/statictext — 전부 기준 md5 동일. synedit `growmid` 만 §14.8 의 1픽셀.
- perf(저장소 빌드, `out_perf/*repoH2*`): custom 1400×12000 GL 18ms/step(cpu 710/40), wall 16, RSS 213MB; cairo 5.5ms; tall(60000) GL 정상
  종료 29ms/step; scrollbox GL 28ms/step. `PAINTCLIP 0,0 585x385`.
- G3 키 행렬 순차 300/300 불변. Phase 2 tomboy-ng 격리 재빌드: `run_scroll_blank.sh` 10장·검색 시나리오 5장 digest 가 7289a76 빌드와 **모두 동일**.
- 사용자 실기(§14.5-7): 디자이너 TScrollBox 안 선택 핸들, KMemo/SynEdit 부분 갱신(타이핑·캐럿·검색 강조), OI/TreeView,
  TScrollBox 썸 드래그(Tracking=False)·휠, 긴 노트(2000줄 이상)에서 GL 렌더러 크래시가 사라졌는지.

