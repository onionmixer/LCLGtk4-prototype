# GTK4 LCL - 다음 세션 인수인계 (작성 2026-07-02 S75, 갱신 2026-09-11 scroll-fixed allocation 세션)

이 문서 하나로 다른 세션에서 작업을 이어갈 수 있도록 정리했습니다.
상세 이력은 프로젝트 메모리(`MEMORY.md` 및 그 색인이 가리키는 파일들 — 특히
`gtk4-key-input-architecture.md`, `gtk4-recurring-pitfalls.md`,
`gtk4-deb-packaging.md`)와 저장소 문서(`LCL_GTK4_DEV.md`, `TODO.md`,
`ANAYLIZE_gtk4_need_implementation.md`)에 있습니다.
(이전 판이 가리키던 `session74.md`/`session75.md` 는 더 이상 존재하지 않습니다.)

## 0. 저장소 / 빌드 / 테스트

- **Repo root**: `/mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4`
  (2026-09-02 이전 경로 `/mnt/USERS/onion/DATA_ORIGN/Workspace/LCL_GTK4` 와 bind mount
  `/home/onion/Workspace/LCL_GTK4` 는 더 이상 없다. KControls, tomboy-ng 등 Lazarus 관련
  작업 트리도 모두 `/mnt/STORAGE16T/Workspace_STORAGE16T/` 아래로 옮겨졌다.)
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

### 0b. 공개 저장소 (스냅샷)

- **원격**: `https://github.com/onionmixer/LCLGtk4-prototype` — 작업 저장소에는
  원격이 **없다**. 공개용 클론은 저장소 안 `lcl_gtk4/` 이며, 여기서만 push 한다.
- 공개 스냅샷은 작업 저장소 추적 파일 169개의 사본이다. 규칙:
  - `lazarus/README.md`(초안)는 **제외**, 최상위 `README.md`(확장판)는 **유지**.
  - 갱신 방법: 작업 저장소의 추적 파일을 `lcl_gtk4/` 로 복사 → 커밋 → push.
    복사 후 blob 해시 전수 대조로 일치 확인할 것.
- 무시 규칙 분리: 일반 빌드 산출물 패턴만 `.gitignore`(공개됨), 이 기계에만
  해당하는 것(`lcl_gtk4/`, `gtk-4.6.9*`, `deb_build/`, 세션 로그·스크린샷)은
  `.git/info/exclude`(커밋 안 됨).

### 0c. 데비안 패키지(deb) 빌드

- **빌드 위치(사용자 지시)**: 저장소 안 `deb_build/<버전>/`. 현재 `deb_build/4.4/`.
  저장소 밖에 새 빌드 디렉터리를 만들지 말 것. `.git/info/exclude` 로 무시됨.
- **현재 리비전**: `4.4+dfsg-8`(2026-09-12, 스크롤바 드래그/좌표/소유 판정 24d1d09; 빌드 결과는 `REBUILD-2026-09-02.md` "-8" 절).
  설치 스크립트 `deb_build/4.4/install-4.4-dfsg8.sh`. 이전: `-7`(가시 영역 cairo 노드 670a720), `-6`(강제 할당 7289a76), `-5`(TEdit pre-dispatch·TSpinEdit), `-4`(close-request), `-3`.
- **정본 기록**: `/usr/src/lazarus4_build/4.4/PLAN_GTK4_PACKAGE.md`(2026-07-21, `-2` 리비전).
  이 경로는 root 소유이고 `sudo` 가 비밀번호를 요구해 **에이전트가 쓸 수 없다**.
- **재빌드 절차/함정**: `deb_build/4.4/REBUILD-2026-09-02.md`.
- GTK4 델타는 quilt 패치 `add-gtk4-widgetset.patch`(74파일)로 관리된다. 갱신은
  orig tarball 2벌 추출 → series 선행 8개 패치를 양쪽 적용 → 기존 패치의 `+++`
  목록대로 한쪽에 작업본을 덮어쓰기 → `diff -urN` 재생성(헤더 유지).
- **함정**: `lcl/interfaces/Makefile.fpc` 는 프로토타입에 `carbon` 이 남아 있는데
  데비안 `drop_carbon_from_Makefiles.patch` 가 이를 제거한다. 그대로 덮으면
  carbon 이 되살아나 빌드가 깨진다 → 이 파일만 데비안 패치본 유지.
- **공간**: 전체 빌드는 약 4.3G 가 필요하다. 저장소가 `/mnt/STORAGE16T`(여유 약 2.5T)로
  옮겨져 옛 `/mnt/USERS` 시절의 사전 정리 요구는 사라졌다.

## 1. 현재 브랜치 상태

```
(이 문서 커밋) docs: 2026-09-11 key pre-dispatch session                          <- 현재 HEAD
057dd09 GTK4: deliver non-text keys of TEdit to the LCL before the inner GtkText (delegate pre-dispatch)
4d2d136 GTK4: GtkEventKey - report LCL consumption to the caller, liveness checks (no behaviour change)
11a7655 GTK4: extract Gtk4BuildKeyEvent from the key callbacks (no behaviour change)
5315056 GTK4: treat KP_Enter/ISO_Enter like Return for the LCL char path
d37a9b8 GTK4: GtkEventKey - optional key-down / char parts (no behaviour change)
d7b7330 GTK4: TSpinEdit - pure GetValue (parse text like gtk2), Max=Min means unlimited, float construction
a90e6d2 HANDOFF: final update for the 2026-09-02 close-request session
cf48e78 HANDOFF: record the 4.4+dfsg-4 deb rebuild (close-request fix)
9a004d9 LCL_GTK4_DEV.md / HANDOFF: record the close-request contract fix (49195ea)
49195ea GTK4: stop the close-request default handler - LCL owns hide/free after LM_CLOSEQUERY
4698a83 docs: update paths for the workspace move to /mnt/STORAGE16T
42b9da8 .gitignore: cover FPC/Lazarus compiler output and session state
a80f5a0 LCL_GTK4_DEV.md: record the 2026-09-02 gtk4-clipboard session
e66660e Add TODO.md: upstream LCL Qt5 items (B9 unfocused combo selection, B7/B8), E1
db38c86 GTK4: send CBN_DROPDOWN for the combo box once, from the popover show notification
7bde741 GTK4: combo box dropdown as a transaction - hover/arrows preview, click/Return commit
d646a38 GTK4: IM commit-order deferral for the editable combo box entry
2e3c84c GTK4: deferred SelStart transaction for the editable combo box entry
6800df4 GTK4: defer SelStart so SelStart+SelLength is one select_region (X11 PRIMARY race)
b5ee8e7 GTK4: deliver LM_CUT/LM_COPY/LM_PASTE from the native edit clipboard actions
f438aa0 GTK4: clipboard ownership loss, UTF-8 text provider, text/plain aliases
35032e5 Add LCL-GTK4 prototype README
dafb5f3 docs: mark handoff items 3b and 3c as fixed
--- (S82 이하) ---
7c6a8a9 GTK4: repair IM commit ordering in TMemo — Hangul+space transpose
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
- 브랜치: `main` (원격 없음 — push 는 `lcl_gtk4/` 클론에서만. 0b 참조)
- 커밋 메시지 말미 규칙: `Co-Authored-By: <세션의 Claude 모델> <noreply@anthropic.com>`
  (S82는 Claude Opus 4.8, 2026-09-02 배포/패키징 세션은 Claude Opus 5,
  2026-09-02 close-request 세션은 Claude Fable 5.1 — `Claude-Session:` 줄도 함께)
- 작업 브랜치 `gtk4-form-designer-undo-redo`는 `45d2bca` 커밋 후 삭제됨.
- 코드 기준 워킹 트리는 깨끗함. `gtk-4.6.9/`, `lazarus/`의
  다수 벤더 `.md`는 미추적이니 **절대 `git add .` 금지** — 필요한 파일만 명시적 add.
- 커밋/푸시는 사용자가 요청할 때만.

## 2-pre00000. 최근 완료 작업 (2026-09-12 스크롤바 드래그 세션) — 최신

요청 `REQUEST_2026-09-11_SCROLLBAR_DRAG_SELECTS.md`(tomboy-ng KMemo: 스크롤바 썸 드래그가 텍스트 선택). **정본: `PLAN_GTK4_SCROLLBAR_DRAG_SELECTS.md`**,
요약 `LCL_GTK4_DEV.md` §11. 사용자 지시: 한 컴포넌트가 아니라 같은 구조의 모든 케이스를 종합, codex gpt-6-astra 교차검토(불신), 계산은 python.

- 커밋 4개(각각 rollback point): 5636fbf(계획서·하네스) → **ba78585 Phase 1**(스크롤바 chrome 시퀀스 제외) → **ba98e2e Phase 2**(뷰포트 기준 클라이언트
  좌표: motion/press/휠/ClientToScreen) → **24d1d09 Phase 3**(입력 소유 판정: 조상은 자손의 버튼/motion 을 받지 않음, 캡처 우회, 디자인 모드 chrome 제외,
  ListView 헤더 chrome). 모두 `gtk4widgets.pas`.
- 게이트(계획서 §12.5/§13.6/§14.5): 마우스 행렬 gtk4 `analyze.py --gate` v7 P0 80 → P1 52 → P2 28 → **P3 0**; 키 행렬 300/300(단독 실행 — 병렬 실행은 타이밍
  잡음); 할당 행렬 strict 0·차이 0; tomboy-ng 격리 빌드(스크래치 `tomboy-ng`, `tomboy-buildN`) 4 시나리오 digest 불변, gdb 프로브 0 발화(670a720 은 9).
- 하네스 `lazarus/example_gtk4_mousematrix_validation/`(README): 18 컨트롤 × 영역, 3 위젯셋 동일 소스, 자체 xdotool 구동, `out_p0..p3/` 기준선(`*.log` 는 미커밋).
- deb `4.4+dfsg-8` 빌드(§0c, `install-4.4-dfsg8.sh`).
- **사용자 실기 대기**(계획서 §7-4·§14.3, deb -8 설치 후): ① tomboy-ng KMemo 스크롤바 드래그(선택 없음)·본문 클릭/드래그 선택(스크롤 전후)·더블클릭·휠·
  우클릭 팝업 위치 ② IDE 소스 편집기/OI/TreeView 스크롤바 드래그 ③ **디자이너**: TScrollBox 스크롤바·TListView 헤더 클릭으로 선택, 컨트롤 드래그 이동·
  러버밴드·그래버 리사이즈, 스플리터 드래그 ④ 그룹박스 안 TSpeedButton/TLabel 클릭·힌트 ⑤ 메뉴바 폼의 클릭 좌표 ⑥ 런타임 ListView 열 정렬 클릭·열 폭 조절
  ⑦ TButton 클릭 뒤 포커스·더블클릭 ⑧ 자식 MouseDown 에서 `SetCaptureControl(Parent)` 하는 코드가 있으면 그 드래그 ⑨ HiDPI 가 있으면 클릭 좌표.
- 범위 밖 기록: `TODO.md` I(H, B'/B'', I, J, L, M, N, O, P, Q, fixed 의 CSS border).
- 함정(추가): codex MCP 는 이 세션에서 연결 실패 상태였고 CLI(`codex exec -m gpt-6-astra -s read-only`)로 진행(사용자가 세션 중 MCP 복구를 알림 — 다음 세션은 MCP 우선).
  키 행렬은 다른 하네스와 병렬로 돌리면 타이밍 잡음으로 행이 바뀐다(단독 재실행에서 0).

## 2-pre0000. 최근 완료 작업 (2026-09-11 scroll-fixed allocation 세션)

요청 `REQUEST_2026-09-11_SCROLLFIXED_ALLOCATION.md`(tomboy-ng KMemo: 리사이즈 뒤 스크롤하면 빈 화면). **정본:
`PLAN_GTK4_SCROLLFIXED_ALLOCATION.md`**(GTK 4.6.9 할당 의미론·위젯셋 조사·실측 행렬 2회·codex 판정표 3회·정확한 변경 §12),
요약은 `LCL_GTK4_DEV.md` §9.

- 커밋 2개: 0067452(계획서·하네스·재현 키트, rollback point) → **7289a76(`TGtk4Widget.SetBounds` 한 줄: `wtScrollingWin` 위젯은
  FCentralWidget 강제 할당 건너뜀)**. 게이트: 할당 행렬 strict exit 0, 비스크롤 클래스 불변, 키 행렬 순차 300/300 불변,
  tomboy-ng 격리 빌드로 사용자 스크립트 통과(스크래치에서 빌드, 사용자 트리 무변경).
- 하네스 `lazarus/example_gtk4_allocmatrix_validation/`(README): 컨트롤별 FCentralWidget 할당 vs GTK 정답(queue_resize 후) 행렬,
  `rungate.sh` 가 Phase 1 게이트 전체. 기준선 `out*/`, 고정 후 `out_fixed*/`.
- deb `4.4+dfsg-6` 빌드 완료(`deb_build/4.4/`, `install-4.4-dfsg6.sh`; 파일 목록 -5 와 동일, `gtk4widgets.o` 만 변경) — §0c 참조.
- **같은 날 밤, 성능 후속(H2) 완료 — 670a720**: 사용자 성능 검토 요청 → 콘텐츠 크기 cairo 노드가 GL 렌더러에서 스크롤당 132ms/+130MB,
  32767px 초과 시 abort(기존 설계) → `LCLGtkFixedSnapshot` 노드를 뷰포트 가시 영역으로 + adjustment 변경 시 재snapshot
  (`Gtk4ScrollFixedRedrawCB`, idle 병합). 계획서 §14–15, `LCL_GTK4_DEV.md` §10. deb `-7`(§0c). 실기 항목은 §14.5-7/§15.
- **사용자 실기 대기**: ① tomboy-ng `onion5`(사용자 빌드, 설치본 -6 기준) 로 요청서 §1 표 ② IDE 소스 편집기·Project Inspector·
  Object Inspector 를 스크롤한 채 창 리사이즈(수정 전엔 다음 스크롤 정보 갱신까지 비어 보일 수 있었음) ③ TListView 헤더/컬럼
  (GTK 정답대로 스크롤바 폭만큼 좁아짐) ④ 그룹박스 안 컨트롤 불변 ⑤ 디자이너의 TScrollBox/TTreeView.
- 범위 밖 기록: `TODO.md` H1–H4(비스크롤 클래스 강제 할당 불일치, cairo 노드 가시 영역 한정, 늦게 생성된 컨트롤의 첫
  SetScrollInfo 범위, FPaintArea).
- 함정(추가): `pgrep -f "codex exec"` 는 자기 셸 명령줄에도 매치돼 자기 셸이 죽는다(2026-09-11 실제 발생, exit 144) — `^node
  /usr/bin/codex` 처럼 앵커된 패턴을 쓸 것. 하네스 Xvfb 는 `xdpyinfo` 로 준비 확인 + 종료 `wait`(경합 시 NOSNAP).

## 2-pre000. 최근 완료 작업 (2026-09-11 key pre-dispatch 세션)

요청 `REQUEST_2026-09-11_ENTRY_RETURN_KEYDOWN.md`(tomboy-ng 검색창 Enter). **정본: `PLAN_GTK4_KEY_PREDISPATCH.md`**
(사실·실측 행렬·원인 분류·설계 v1→v4·codex 판정표·단계 결과), 요약은 `LCL_GTK4_DEV.md` §8.

- 커밋 6개(d7b7330 … 057dd09): TSpinEdit 크래시/초기값/float 생성(Phase 0), GtkEventKey 부분 실행·AHandled·헬퍼(1a/2a/2b-1,
  동작 불변), KP_Enter/ISO_Enter(1b), **TEdit delegate pre-dispatch(2b-2)**. 각 단계 세 빌드 + 행렬 게이트 통과.
- 하네스 `lazarus/example_gtk4_keymatrix_validation/`(README) — gtk4/gtk2/qt5 3 위젯셋 키 전달 행렬. 기준선 디렉터리별로
  단계 전후 로그·`signatures_*.json`·codex 회신 보관. **포커스 이동 판정은 순차 모드, 키별 전달 판정은 격리 모드**.
- deb `4.4+dfsg-5` 빌드(`deb_build/4.4/`, `install-4.4-dfsg5.sh`) — §0c 참조.
- **사용자 실기 대기(다음 착수 전 필수)**: ① fcitx5 한글 조합 중 Return/BackSpace 가 IM 에 그대로 가는지, 조합 없이 Return
  이 KD 1회인지(IM 재전송 이중 발화) ② tomboy-ng `test_entry_return/run.sh <gtk4-dbg 바이너리>` 기대 출력 ③ IDE 에서
  TEdit Enter 로 기본 버튼, Up/Down 포커스 유지.
- **다음 단계**: Phase 3 TSpinEdit(옵트인 켜기 + Return 후 editable 조건부 `update` + 화살표 FALSE + `IsTextEntryLike`
  술어), Phase 4 편집 콤보(delegate 기록기에 동일 적용, 팝오버 격리 확인). 2차 범위는 `TODO.md` G1–G7(사용자 결정).
- codex 교차검토는 이번 세션에 MCP 서버가 연결되지 않아 CLI(`codex exec -m gpt-6-astra -s read-only`)로 수행. 회신은
  전건 코드 대조 후 채택(계획서 판정표). **codex 를 신뢰하지 말 것**(매 회신에 틀린 주장이 섞여 있었음).
- **에이전트 셸 함정(추가)**: 백틱이 든 마크다운을 heredoc 으로 쓸 때는 `<<'EOF'` 로 따옴표를 붙일 것(따옴표 없는 heredoc 은
  백틱을 명령 치환해 문서가 깨지고 엉뚱한 프로세스까지 뜬다 — 2026-09-11 실제 발생). `pkill -f` 패턴이 자기 명령줄에
  매치되면 자기 셸이 죽으니 PID 로 죽일 것.

## 2-pre00. 최근 완료 작업 (2026-09-02 close-request 세션)

외부 보고("close-request 콜백이 항상 FALSE 라 폼을 숨겨도 GTK4 가 창을 파괴")를 코드 대조 + Xvfb
재현으로 확인하고 수정했다.

- **`49195ea`**: `TGtk4Window.Gtk4CloseQuery` — `LM_CLOSEQUERY` 전달 후 `Result := DeliverMessage(Msg) = 0`
  (gtk2 `gtkdeleteCB`, qt5 `QEventClose`+`QEvent_ignore` 와 같은 계약). `TCustomForm.WMCloseQuery` 가
  스스로 `Close` 를 돌리고 항상 0 을 돌려주므로 위젯셋은 GTK 기본 파괴를 항상 막아야 한다.
  LCL 수신자가 없을 때(`LCLObject=nil` 또는 핸들 미할당 — 후자는 codex 교차검토 지적을 코드로
  재검증해 채택)만 FALSE. 커먼 다이얼로그의 두 close-request 콜백은 gtk2 와 같은 의미론이라 대상 아님.
- 검증: Xvfb 에서 네이티브 `gtk_window_close` 로 caHide 숨김→재표시(같은 X11 창), caFree 해제,
  caNone 유지, 모달 `ShowModal`=mrCancel, 메인 폼 닫기→종료. GTK CRITICAL 0. 3 빌드 통과.
  테스트 프로그램은 저장소 밖(세션 스크래치)이라 남아 있지 않음 — 재작성 시 `TGtk4Widget(Handle).Widget`
  에 `gtk_window_close` 를 직접 호출하면 WM 닫기와 같은 경로(`gtk_window_emit_close_request`)를 탄다.
- 상세: `LCL_GTK4_DEV.md` §7. 공개 스냅샷 `lcl_gtk4/` 는 `909d9ab` 로 동기화·push 완료(해시 전수 대조).
- **사용자 실기 확인 대기**: IDE 에서 미저장 상태로 창 닫기 → "취소" 시 IDE 창 유지, OnClose=caHide
  앱(tomboy-ng 류)의 닫기 후 재표시, 일반 폼/모달 다이얼로그의 WM 닫기 버튼 정상 종료.
- 저장소 이동(`/mnt/USERS` → `/mnt/STORAGE16T/Workspace_STORAGE16T`) 경로 갱신은 `4698a83`.

## 2-pre0. 최근 완료 작업 (2026-09-02 배포/패키징 세션)

코드 변경 없음. 배포와 패키징만 처리했다.

1. **공개 스냅샷 동기화 + push** (`lcl_gtk4/`, `e2b73fe`)
   2026-07-12 이후 상류 8커밋(아래 2-pre1)을 스냅샷에 반영해 GitHub 에 올렸다.
   작업 저장소에는 원격이 없어서 push 대상은 `lcl_gtk4/` 뿐이다. 복사 후
   공통 파일 169개 blob 해시 전수 대조로 일치를 확인했다.
2. **무시 규칙 정리** (`42b9da8`, 스냅샷 `ea4e102`)
   `.gitignore` 에 일반 빌드 산출물(`lib/`, `*.rsj`, `*.a`, `*.dbg`, `*.lps`,
   `*.old`, `*~`) 추가. 이 기계 사정(`lcl_gtk4/`, `gtk-4.6.9*`, `deb_build/`,
   세션 로그·스크린샷)은 `.git/info/exclude` 로 분리해 공개 저장소를 오염시키지
   않게 했다. 루트 미추적 91개 → 0개, 미추적 파일 34,863 → 19,300개.
   추적 파일 170개는 그대로이고 새 패턴에 걸리는 추적 파일은 없음을 확인했다.
3. **deb 패키지 재빌드 `4.4+dfsg-3`** (`deb_build/4.4/`)
   GTK4 quilt 패치를 현재 프로토타입 소스로 갱신하고 28개 패키지를 다시 만들었다.
   `-2` 대비 실제 코드 변경은 `gtk4widgets.pas`, `gtk4winapi.inc`,
   `gtk4wsstdctrls.pp` 3개뿐이고 패키징 설정은 건드리지 않았다.
   검증: gtk2/qt5/nogui 패키지 파일 목록이 `-2` 와 동일(회귀 없음),
   `lazarus-gtk4`(41MB)가 `libgtk-4.so.1` 링크, `lcl-gtk4-4.4` 1569파일,
   `gtk4widgets.ppu` 571,293 → 579,563 바이트.
4. **설치** (`deb_build/4.4/install-4.4-dfsg3.sh`, 사용자 실행 완료)
   구성: **LCL 위젯셋 = gtk4 + qt5**, **IDE = gtk4 하나만**. gtk2 위젯셋,
   gtk2/qt5 IDE, `lazarus-doc` 은 설치하지 않는다. 17개 패키지가 `4.4+dfsg-3`
   으로 설치된 것을 확인했다.

## 2-pre1. 최근 완료 작업 (2026-09-02 `gtk4-clipboard` 세션)

KControls(`/mnt/STORAGE16T/Workspace_STORAGE16T/KControls`, 브랜치 `integration-fixes`)의 GTK4/QT5
클립보드·선택·IME 검증에서 드러난 위젯셋 결함 수정. 커밋별 표와 검증 내역은
`LCL_GTK4_DEV.md` §6, 설계·판정표는 KControls 의 `PHASE4/6/7_*.md` 가 정본.

- 클립보드 소유권 상실 감지, UTF-8 텍스트 프로바이더, `text/plain` 별칭 (`f438aa0`)
- 네이티브 에디트 cut/copy/paste → `LM_CUT/LM_COPY/LM_PASTE` (`b5ee8e7`)
- `SelStart`+`SelLength` 를 한 번의 `select_region` 으로 (X11 PRIMARY race) (`6800df4`)
- 편집 콤보에 같은 트랜잭션 (`2e3c84c`), IM 커밋 순서 보정 (`d646a38`)
- 콤보 드롭다운 트랜잭션: hover/화살표=미리보기, 클릭/Return=확정, Esc=취소 (`7bde741`)
- `CBN_DROPDOWN` 1회 전송 (`db38c86`)
- **비작업 결정**: 일반 문자 키 `OnKeyDown` 미전달(IM 컨텍스트가 press 소비).
  사용자 결정으로 작업하지 않음. `TODO.md` 참조.

## 2-pre2. 최근 완료 작업 (S82, 2026-07-11~12)

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
6. **(2026-09-02 추가) 업스트림 LCL Qt5 결함 3건** — `TODO.md` 정본.
   B9 비포커스 편집 콤보의 `SelStart`/`SelLength` 미유지(원인·수정 방향까지 분석 완료,
   업스트림 제안만 남음), B7 `text/rtf` 전용 소유자 미인지, B8 `SelectAll` 마지막
   문자 누락. **모두 GTK4 위젯셋과 무관**하며 이 저장소에서 고칠 항목이 아니다.
7. **(2026-09-02 추가) 환경 E1** — GTK4 앱의 PRIMARY 를 gnome-terminal 3.44(VTE)에
   가운데 클릭 붙여넣기 실패. 순수 GTK4 `GtkEntry` 에서도 재현되어 이 포트와 무관.
   귀책 확정에는 X 프로토콜 추적이 필요(배포판 GTK4 가 `G_ENABLE_DEBUG` 없이 빌드됨).
8. ~~**(2026-09-02 추가) 디스크 공간**~~ — **해소**: 저장소가 `/mnt/STORAGE16T`(여유 약 2.5T)로
   이동해 옛 `/mnt/USERS` 의 1.7G 제약이 없어졌다. `deb_build/4.4/lazarus-4.4/`(1.8G),
   `build_gtk4_*.log`, `report_*.png`, `gtk-4.6.9/` 는 그대로 두었다(정리는 선택).
9. **(2026-09-02 추가) 패키징 산출물 원위치 복사** — `deb_build/4.4/` 의 `-4` deb 28개와
   갱신된 `debian/patches/add-gtk4-widgetset.patch`, `debian/changelog` 를
   `/usr/src/lazarus4_build/4.4/` 로 옮기려면 `sudo` 가 필요하다. 명령은
   `deb_build/4.4/REBUILD-2026-09-02.md` 말미에 적어 두었다.
13. **(2026-09-12 추가) 스크롤바 드래그/좌표/소유 판정 실기 확인** — 2-pre00000 의 "사용자 실기 대기" 아홉 항목(deb -8 설치 후). 특히 디자이너 항목은 하네스가 못 본다.
12. **(2026-09-11 추가) scroll-fixed allocation + H2 실기 확인** — 2-pre0000 의 "사용자 실기 대기" 다섯 항목 + 계획서 §15 의 H2 항목(deb -7 설치 후).
11. **(2026-09-11 추가) TEdit pre-dispatch 실기 확인** — 2-pre000 의 "사용자 실기 대기" 세 항목. 통과 후 Phase 3/4 착수.
10. **(2026-09-02 추가) close-request 수정 실기 확인** — 2-pre00 의 "사용자 실기 확인 대기" 항목.
   deb `4.4+dfsg-4` 설치(`deb_build/4.4/install-4.4-dfsg4.sh`, sudo 필요) 후 확인하면 된다.

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
- **키 전파 순서**(2026-09-11 확정, GTK 4.6.9 소스): CAPTURE(root→target) → TARGET → BUBBLE(target→root). 같은 위젯·같은
  단계에선 **나중에 추가한 컨트롤러가 먼저**(`g_list_prepend`). 클래스 키 바인딩은 그 위젯의 BUBBLE. GtkText 의 키/IM 컨트롤러는
  TARGET. 포커스가 내부 자식(GtkText/행 위젯/토글버튼)에 있으면 부모의 BUBBLE 컨트롤러는 자식이 소비한 키를 못 받는다 →
  자식 위에 CAPTURE 컨트롤러로 선점(TEdit 는 delegate 기록기 재사용). **press 를 TRUE 로 소비하면 그 keyval 의 release 는
  같은 컨트롤러에서 GTK 가 자동으로 멈춘다**(`pressed_keys`) — KeyUp 을 직접 전달해야 함. `gdk_keyval_to_unicode` 는
  KP_Enter/ISO_Enter 에 0. `gtk_event_controller_get_current_event` 는 전달 뒤 재조회 금지(중첩 시 덮어씀).
- **자식 GObject 시그널**(selection model, adjustment, factory, IMContext 등)은
  base `DestroyWidget`의 `g_signal_handlers_disconnect_matched(FWidget)`가 못
  잡음 → 각 클래스가 `DetachEvents` override로 직접 해제.

## 5. 작업 방식 메모 (사용자 선호)

- 계획/구현 시 **확대판단 금지**, 불필요한 문서/코드 변경 금지.
- 큰 결정 전 계획서를 만들고, 별도 모델(예: sonnet)로 **교차 검토 → 재검증**
  사이클을 돌린 뒤 지적사항이 없을 때까지 반복 (지적은 코드 대조로 직접 확인).
- 상세 정본은 프로젝트 메모리에 두고, 저장소 추적 문서엔 요약만 (중복 최소화).
- rollback point 커밋을 먼저 확보한 뒤 위험한 변경 진행.
- **`git add .` 금지** — 벤더 소스가 미추적으로 대량 존재한다. 필요한 파일만 명시적 add.
- 패키지 빌드는 저장소 안 `deb_build/<버전>/` 에서. 저장소 밖에 만들지 말 것.
- 공개 저장소 push 는 `lcl_gtk4/` 클론에서만. 작업 저장소에는 원격이 없다.
- **에이전트 셸 함정**: 작업 디렉터리가 명령 사이에 유지된다. `cd lcl_gtk4` 로 끝난 뒤 상대 경로로
  편집하면 스냅샷 쪽 파일을 고치게 된다(2026-09-02 실제 발생, 편집 유실). 파일 편집은 절대 경로로.
