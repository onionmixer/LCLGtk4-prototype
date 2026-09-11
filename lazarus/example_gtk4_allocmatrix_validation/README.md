# FCentralWidget 할당 행렬 하네스 (gtk4 전용)

`PLAN_GTK4_SCROLLFIXED_ALLOCATION.md` 의 실측 도구. `TGtk4Widget.SetBounds` 가 `FCentralWidget` 에 강제하는
클라이언트 크기 할당이 GTK 레이아웃의 정답과 어긋나는지(stale) 컨트롤별·단계별로 잰다.

## 파일

- `allocmatrix.lpr` — 하네스. `allocmatrix <control> [hv|v|none] [mode]`
  - control: `panel groupbox scrollbox custom memo memowrap listbox listboxgrid checklist listview listviewicon
    statictext progressbar toolbar page statusbar splitterside form treeview synedit`
    (`custom` = KMemo 방식의 `TCustomControl` 파생: `ShowScrollBar`+`SetScrollInfo`, `Resize` 마다 재설정)
  - range: `hv`(가로+세로 범위, 기본) `v`(세로만) `none`(범위 없음)
  - mode: 없음(정답 비교) `notruth`(정답 단계에서 `queue_resize` 안 함 — GTK 가 자력 회복하는지) `late`(폼 표시 후 생성)
    `hidden`(Visible=False 로 생성 후 표시) `rehide`(표시→숨김→숨긴 채 리사이즈→재표시) `inactivepage`(비활성 탭 안에서
    리사이즈 → 탭 활성화) `zero`(높이 0 → 400)
  - 단계: `show → scroll → shrink(-100h) → same(위젯셋 SetBounds 직접 호출, 같은 값) → grow(+100h) → wider(+50w) → scroll2`.
    각 단계 뒤 `t-<단계>` = `gtk_widget_queue_resize(FCentralWidget)` 후 다시 잰 **GTK 정답**.
  - SNAP 필드: 외부 위젯/중앙 위젯/중앙의 부모 할당·`size_request`, 스크롤 adjustment(value/upper/page), LCL 크기,
    LCL `ClientRect`(캐시), 포인터, `rss=`(VmRSS kB), `wsclient=`(위젯셋 `getClientRect` 직접 질의).
- `build.sh gtk4` — 저장소 유닛으로 링크만(재컴파일 없음) → `allocmatrix_gtk4`.
- `build_exp.sh <패치된 gtk4 인터페이스 복사본> <접미사>` — 복사본의 gtk4 인터페이스 유닛만 별도 디렉터리로 재컴파일해
  `allocmatrix_gtk4_<접미사>` 생성(저장소 유닛 디렉터리 무변경). 계획서 §4.5 의 A/B 실험이 이것.
- `run.sh <control> [range] [mode] [display] [shot.png]` — Xvfb(+`GSK=gl` 로 GL 렌더러) 로 실행. 5번째 인자를 주면 `scroll2`
  (모든 리사이즈 뒤 스크롤) 시점 스크린샷. `BIN=allocmatrix_gtk4_expA` 로 바이너리 선택.
- `runall.sh [outdir]` — 1차 행렬(15 컨트롤 + 범위 변형 + notruth). `runexp.sh`/`runexp2.sh`/`runexp3.sh` — 실험 바이너리 행렬
  (`out_expA/`, `out_expB/`, `out_v2*/`, `shots_v2/`).
- `analyze.py [dir] [--strict] [--include=<regex>]` — 단계별 판정: `STALE`(중앙 ≠ 정답), `FILL`(GtkOverlay 안 중앙 ≠ 오버레이),
  `NOSCROLL`(scroll 단계에서 vadj 0), `NOSNAP`, `INCOMPLETE`. `--strict` 는 문제가 있으면 exit 1.
- `compare.py <dirA> <dirB>` — 두 출력 디렉터리의 정규화 행(타임스탬프·포인터·rss 제외) 비교.
- `order.gdb` / `run_order.sh` — `SetBounds`/`SetScrollInfo`/`set_size_request`/`queue_resize` 호출 순서 추적(gdb).

## 게이트(계획서 §7)

```
python3 analyze.py out_fixed --strict --include='^(custom|scrollbox|treeview|synedit|listview|listviewicon|listbox|listboxgrid|checklist|memo|memowrap)'
python3 compare.py out_v2 out_fixed      # 차이는 스크롤 클래스 로그에만 있어야 한다
```

## 함정

- Xvfb 는 `xdpyinfo` 로 준비를 확인하고 종료 뒤 `wait` 한다(연속 실행 시 display 잠금 경합으로 `NOSNAP` 이 났었음).
- `same` 단계는 LCL `Resize` 없이 위젯셋 `SetBounds` 를 직접 부르므로 LCL 경로와 다를 수 있다(`splitterside`).
- `notruth` 로그에서는 `STALE` 이 나올 수 없다(정답 단계가 수리하지 않음) — `FILL` 열로 본다.
