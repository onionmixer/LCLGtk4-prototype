# 수정 요청: 리사이즈 후 스크롤 컨테이너(GtkFixed)가 클라이언트 크기로 고정되어 스크롤하면 빈 화면

작성일: 2026-09-11 (같은 날의 `REQUEST_2026-09-11_ENTRY_RETURN_KEYDOWN.md` 와 별개 건)
대상: `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas` — `TGtk4Widget.SetBounds` (설치본 `lcl-gtk4 4.4+dfsg-5`, 트리 `ed0cd8c` 기준 약 5231–5305행)
증상 출처: tomboy-ng GTK4 (`0.42c+onion4`) — 사용자가 "노트 내 검색 시 화면이 이상하다"고 보고한 노트.
재현 키트: `test_entry_return/synth_long_only.note`, `test_entry_return/run_scroll_blank.sh`, `test_entry_return/run_queue_resize_check.sh`

---

## 1. 증상

긴 줄(가로 스크롤 범위가 생기는 줄)이 있는 노트를 연 뒤 **KMemo 가 리사이즈되는 조작**(tomboy-ng 에서는
`Ctrl+F` 로 검색 패널이 열리며 KMemo 높이가 39px 줄어듦)을 하고 나서 세로로 크게 스크롤하면
KMemo 영역이 **밝은 회색 단색**으로만 그려진다. 스크롤바는 정상 위치에 있다.

| 조작 | 짧은 줄만 있는 노트 | 긴 줄(가로 스크롤)이 있는 노트 |
| --- | --- | --- |
| 열자마자 PageDown ×8, Ctrl+End | 정상 | 정상 |
| `Ctrl+F`(리사이즈) 후 검색으로 580행 이동 | 정상 | **빈 화면** |
| `Ctrl+F`(리사이즈) 후 PageDown ×6, Ctrl+End | 정상 | **빈 화면** (PageDown 4회째부터) |
| 빈 화면에서 창 크기 변경 / 클릭 / PageDown | — | 여전히 빈 화면 |
| 빈 화면에서 `Ctrl+Home` | — | 내용 복귀 (top=0) |

Qt5 는 같은 노트·같은 조작에서 정상. 검색 로직(tomboy-ng `FindInNote`)과는 무관하다 — 검색 없이 수동 스크롤만으로 재현된다.

## 2. 증거 (gdb, `tomboy-ng-gtk4-dbg`, Xvfb)

빈 화면 시점에 KMemo(`TKCustomMemo`, `TGtk4CustomControl`)의 스크롤 컨테이너 GtkFixed(`FCentralWidget`,
`'lcl-scroll-fixed'` 태그) 에 GTK 로 직접 질의:

```
gtk_widget_measure(fixed, H)      min=1403 nat=1403
gtk_widget_measure(fixed, V)      min=12791 nat=12791
gtk_widget_get_size_request       1403 x 12791     <- SetScrollInfo 가 준 콘텐츠 크기, 정상
gtk_widget_get_allocated_*        900 x 620        <- 뷰포트(클라이언트) 크기!
parent = GtkOverlay               allocated 1403 x 12791   <- 부모는 콘텐츠 크기로 정상 할당
parent.parent = GtkViewport
vadjustment value=8730 upper=12791 page=605
```

- KMemo 내부 상태는 정상(`FTopPos=8730`, 캐럿 y=577 로 화면 안). LCL 은 자기 오프셋으로 그리지만,
  GtkViewport 가 **620px 짜리** 자식을 8730px 위로 밀어 올리므로 자식이 통째로 화면 밖 → 아무것도 안 그려진다.
  (`LCLGtkFixedSnapshot` 의 `cairo_translate(ScrollX, ScrollY)` 보정은 자식이 콘텐츠 크기일 때만 성립한다.)
- 리사이즈 직전 마지막 paint: `fixed w=1417 h=12767` (정상). 리사이즈 직후 paint: `fixed w=900 h=620`.
  그 사이 이 위젯에 대한 `gtk_widget_set_size_request` 호출은 `(1403,12767)`, `(1403,12791)` 뿐이며
  (SetScrollInfo, 값 정상), 다른 곳에서 요청을 줄인 적이 없다.
- **검증:** 빈 화면 상태에서 gdb 로 `gtk_widget_queue_resize(fixed)` 한 번만 호출하고 continue 하니
  할당이 `620 → 12791` 로 돌아오고 내용과 검색 강조가 정상 위치에 나타났다
  (`run_queue_resize_check.sh`). 즉 크기 요청/측정은 맞고, **강제된 stale 할당**이 문제다.

## 3. 원인

`TGtk4Widget.SetBounds` 는 `FCentralWidget` 이 있는 모든 위젯(그룹박스 제외)에 대해

```pascal
Alloc := (0, 0, AWidth, AHeight);           // LCL 바운드 = 클라이언트 크기
gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
```

를 호출한다(주석: "GtkOverlay does not always propagate allocation to overlay children ... a GtkFixed
inside a GtkOverlay may retain a stale 0x0 allocation"). `TGtk4CustomControl` / `TGtk4ScrollingWinControl`
에서는 `FCentralWidget` 이 **GtkScrolledWindow > GtkViewport > GtkOverlay 안의 스크롤용 GtkFixed** 이고,
그 올바른 할당은 클라이언트 크기가 아니라 `SetScrollInfo` 가 `set_size_request` 로 준 **콘텐츠 크기**다.
리사이즈 때 이 강제 할당이 GtkFixed 를 900×620 으로 덮어쓰고, 이후 아무것도 `queue_resize` 를 걸지 않으면
GtkOverlay 가 다시 배치하지 않아 stale 할당이 남는다.

짧은 줄만 있는 노트에서 재현되지 않는 이유(추정, 미검증): 가로 범위가 0 이면 `SetScrollInfo(SB_HORZ)` 가
`set_size_request(-1, OldH)` 로 요청값을 **바꾸므로** GTK 가 `queue_resize` 를 걸어 곧바로 재배치된다.
긴 줄이 있으면 요청값이 `(1403, 12791)` 로 **변함이 없어** `queue_resize` 가 발생하지 않는다.

## 4. 수정 제안

`TGtk4Widget.SetBounds` 에서 `FCentralWidget` 이 `'lcl-scroll-fixed'` 태그를 가진 경우:

- **A안 (권장):** 강제 `size_allocate` 를 건너뛰고 `gtk_widget_queue_resize(FCentralWidget)` (또는
  `queue_allocate`) 만 호출한다. 뷰포트/오버레이가 `size_request`(콘텐츠 크기) 기준으로 재배치한다.
  gdb 검증이 바로 이 동작이다.
- **B안:** 강제 할당을 유지하되 크기를 `max(클라이언트, get_size_request)` 로 준다. 즉
  `Alloc.width := Max(AWidth, ReqW); Alloc.height := Max(AHeight, ReqH)` (`ReqW/ReqH` 가 -1 이면 클라이언트).
  단, 뷰포트가 스크롤 중이면 위치(x,y)도 `-adjustment.value` 여야 하므로 A안보다 취약하다.
- 주석이 언급한 "stale 0x0 allocation" 사례(GtkFixed 가 오버레이 안에서 0×0 으로 남는 문제)는
  스크롤 컨테이너가 아닌 일반 컨테이너의 문제이므로 그 경로는 그대로 둔다.
- `TGtk4ScrollingWinControl`(TScrollBox) 도 같은 태그를 쓰므로 함께 영향을 받는다. 거기서는 뷰포트 이동이
  곧 스크롤이므로 A안이 자연스럽다.

## 5. 검증 방법

1. `test_entry_return/run_scroll_blank.sh <tomboy-ng-gtk4>`: `Ctrl+F` → PageDown ×6 → `Ctrl+End` 의 스크린샷이
   모두 내용을 보여야 한다(현재는 4회째부터 밝은 회색 단색).
2. `test_entry_return/run.sh <tomboy-ng-gtk4-dbg>` 에 `SEARCH_TERM=ubi` 와 `synth_long_only.note` 로 검색 시나리오:
   `2-typed` 스크린샷에 580행 `ubi` 가 강조되어야 한다.
3. 회귀: 짧은 줄 노트(`bigsearch.note`)의 검색/스크롤, TScrollBox 가 있는 폼의 리사이즈, 그룹박스 안 컨트롤,
   IDE Object Inspector(주석의 in-place editor 위치)가 그대로인지.
4. 수정 후 `lcl-gtk4 4.4+dfsg-6` 로 패키징하고 tomboy-ng 를 `onion5` 로 재빌드해 위 1·2 를 다시 돌린다.

## 5a. 결과 (2026-09-11 17:2x, `lcl-gtk4 4.4+dfsg-6`, LCL 커밋 `7289a76`, tomboy-ng `0.42c+onion5`)

`TGtk4Widget.SetBounds` 가 `wtScrollingWin` 위젯에서는 `FCentralWidget` 강제 할당을 건너뛰도록 수정됨(A안 취지).
tomboy-ng GTK4 디버그 빌드로 §5 의 1·2 와 회귀 항목을 다시 실행:

| 시나리오 | 결과 |
| --- | --- |
| `run_scroll_blank.sh` (Ctrl+F → PageDown ×6 → Ctrl+End) | 모든 스크린샷에 내용 표시, 빈 화면 digest 없음 |
| `run.sh` + `SEARCH_TERM=ubi`, `synth_long_only.note` | 580행 `ubi` 강조·스크롤 정상, Enter/KP_Enter/F3 전달 정상 |
| `run.sh` + `SEARCH_TERM=ubi`, `synth_ubi_urls.note` (URL+긴 줄) | 정상 |
| `run.sh`, `bigsearch.note` (짧은 줄, zebra) | 이전 정상 결과와 동일한 digest (회귀 없음) |

**해결 확인.** TScrollBox / TTreeView / TSynEdit 쪽 회귀는 LCL 측 harness(`example_gtk4_allocmatrix_validation`) 결과를 따른다.

## 6. 관련

- tomboy-ng 쪽에는 우회할 방법이 마땅치 않다(LCL 에서 GTK `queue_resize` 를 걸 수단이 없다). LCL 수정이 필요하다.
- 같은 세션에서 발견된 tomboy-ng 자체 버그(wrap-around 검색 시 강조 한 줄 밀림, `FindInNote` 의
  `SearchString` 미초기화)는 별개이며 tomboy-ng `HANDOFF.md` 에 기록돼 있다.
