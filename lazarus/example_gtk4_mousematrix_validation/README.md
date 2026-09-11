# 마우스 전달 행렬 하네스 (gtk4 / qt5 / gtk2)

`PLAN_GTK4_SCROLLBAR_DRAG_SELECTS.md` 의 실측 도구. 컨트롤의 어느 영역(클라이언트·스크롤바·헤더·버튼 등)에서 press→드래그→release
했을 때 그 컨트롤(과 폼·자식)이 어떤 `OnMouseDown/Move/Up/Click` 을 어떤 좌표로 받는지, 스크롤 위치·선택·`ClientToScreen` 드리프트가
어떻게 변하는지를 세 위젯셋에서 같은 소스로 잰다.

- `mousematrix.lpr` — `mousematrix <control>`; 하네스가 **직접 xdotool 을 실행**하므로 `--- region` 마커와 이벤트가 한 로그에 정확히
  정렬된다. 컨트롤: `custom`(KMemo 방식 TCustomControl) `scrollbox memo listbox listview treeview treeviewnohint synedit(gtk2 제외)
  spin combo pagecontrol groupbox trackbar panel button edit formscroll formmenu`(`button` = 런타임 TButton: 조상이 그 press/motion 을 받는지). 영역: `client vthumb vtrough hthumb` + 컨트롤별 chrome
  (`spinup combobutton tab2 caption header slider`) + 시퀀스 `contentdrag`(클라이언트 press → 스크롤바 위 → 컨트롤 밖 release),
  `multibtn`(스크롤바 버튼1 press → 클라이언트에서 버튼3 → 버튼1 release; **qt5 는 이 뒤 프로세스가 멈추므로 마지막에 둠**).
  각 영역: press → +60 → +120 아래로 드래그 → 클라이언트 중앙으로 이동 → release → `STATE`(스크롤 위치·범위, 선택, `c2sdrift`,
  gtk4 는 `wsoff` = getClientOffset).
- `build.sh gtk4|gtk2|qt5|gtk4sys` — 저장소 유닛(gtk4/gtk2), 설치본 `/usr/lib/lazarus/4.4`(qt5, gtk4sys) 에 링크만.
- `run.sh <ws> <control> [display]` → `out/<ws>_<control>.log`. `runall.sh [ws...]`, `runsubset.sh`(계획서용 부분집합), `rungtk4.sh`.
- `analyze.py [--gate] [control...]` — (컨트롤, 영역)별로 gtk4/qt5/gtk2 한 줄씩: 대상 `D=<n>(x,y) M=<n>[x범위,y범위] U=<n>(x,y) C<클릭>`,
  `form:`/`child:` 개수, 상태 변화(`DRIFT-CHANGED` = ClientToScreen 드리프트가 영역 사이에 바뀜), `nobar` = 그 축에 스크롤 범위 없음.
  `!!` = gtk4 와 qt5 의 대상 D/M/U 개수가 다름, `~` = qt5 와 gtk2 가 다름. `--gate` 는 계획서 §7 의 판정(chrome 행과 `listview/header`: press/release/click 0·버튼 든 motion 0·수신자별
  버튼 없는 motion ≤1[v6/v7, 계획서 §12 행 41·§14]; client/contentdrag 행: 가장 깊은 컨트롤 press 1·release 1(`button` 은 P 로 제외), 폼·조상
  버튼 0·버튼 든 motion 0·버튼 없는 motion ≤1(행 55), press = 첫 motion ±1, qt5 press ±12px, Move 범위, 드리프트 불변; 미완료 로그; 예외 formscroll/listview client)으로 exit 1/0.
- 기준선: `out_run1/`(1차, 폼/자식 훅 없음), `out_run2/`(2차 전체), `out/`(v3 하네스 부분집합 + 나머지는 2차 복사, 2026-09-11 밤),
  `out_p0/`(Phase 0 = 수정 전 gtk4 전체), `out_p1/`(Phase 1 = chrome 제외), `out_p2/`(Phase 2 = 뷰포트 좌표), `out_p3/`(Phase 3 = 소유 판정·헤더; gtk4 만,
  `button` 은 p3 부터; `GATE_v*.txt` 는 그 게이트 출력). `out*/` 는 `.gitignore`(`*.log`)로 커밋되지 않는다.

함정: TTreeView 는 노드 툴팁(THintWindow)이 gtk4 에서 press 를 가로채므로 `treeviewnohint`(ToolTips=False) 로 스크롤바 행을 본다
(그 자체가 별개 결함 H). Xvfb 는 `xdpyinfo` 로 준비 확인. 자기 셸을 죽이는 `pkill -f` 패턴 금지.
