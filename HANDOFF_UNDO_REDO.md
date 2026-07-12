# GTK4 LCL - Form Designer Undo/Redo Handoff

작성/갱신: 2026-07-08

이 문서는 GTK4 form designer의 menu 없이 Ctrl+Z undo가 동작하지 않던 문제에 대한
최종 인수인계 문서다. 전체 프로젝트 상태는 `HANDOFF_NEXT_SESSION.md`를 함께 볼 것.

## 0. 최종 상태

- 완료 커밋: `45d2bca GTK4: fix designer undo redo shortcuts`
- rollback point: `c69a34a GTK4: deliver form activation to LCL`
- 작업 브랜치 `gtk4-form-designer-undo-redo`는 커밋 후 삭제됨.
- 현재 기본 브랜치: `master` (`main` 브랜치는 없음)
- 수정 범위:
  - `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas`
  - `PLAN_GTK4_FORM_DESIGNER_UNDO_REDO.md`는 handoff 반영 후 삭제됨
- Lazarus core(`ide/`, `components/ideintf/`, LCL 공용 코드)는 수정하지 않았다.

## 1. 확정 원인

초기 가설은 두 층이었다.

1. GTK4 form activation 전달 누락
2. 컴포넌트 배치 후 IDE command enabled 상태가 idle 전에 stale로 남는 타이밍 문제

최종 계측으로 확인된 핵심 실패 조건은 다음과 같다.

- Ctrl+Z key event는 `Gtk4DesignKeyPressedCB`까지 정상 도달했다.
- `CN_KEYDOWN`/`LM_KEYDOWN`도 form designer control로 전달됐다.
- `Screen.ActiveCustomForm=Form1`이었지만 `Application.Active=False`였다.
- 이 상태에서는 undo/redo shortcut 직전 `Application.Idle(False)` 보정이 실행되지 않아
  IDE command enabled 상태가 갱신되지 않았다.

따라서 단순 key delivery 실패가 아니라, GTK4 focus owner 상태와 LCL application
activation bookkeeping이 어긋난 것이 실제 실패 조건이었다.

## 2. 최종 수정 내용

`lazarus/lcl/interfaces/gtk4/gtk4widgets.pas`에만 수정이 들어갔다.

- `Gtk4HasDeferredMouseEvents`
  - GTK4 deferred mouse queue가 남아 있는지 확인한다.
- `Gtk4IsUndoRedoShortcut`
  - Ctrl+Z/Ctrl+Shift+Z/Ctrl+Y 계열 undo/redo 후보 shortcut만 제한적으로 판정한다.
- `Gtk4FlushDesignInputBeforeCommandKey`
  - undo/redo shortcut dispatch 직전에 pending deferred mouse event를 먼저 flush한다.
  - modal 상태가 아니고 `Application.Active=True`이면 `Application.Idle(False)`를 1회 실행해
    IDE command enabled 상태를 갱신한다.
  - command를 직접 실행하지 않고 기존 designer/IDE command path에 맡긴다.
- `Gtk4EnsureAppActive`
  - GTK4 focus-widget notify에서 LCL focus owner가 확인될 때
    `Application.IntfAppActivate()` 상태를 보정한다.
  - menu/popover focus churn은 기존처럼 global app active state 변경에서 제외한다.
- `Gtk4DeliverFocusChange`
  - 새 LCL focus owner가 확인될 때 `Gtk4EnsureAppActive`를 호출한다.

임시 trace helper와 `LAZ_GTK4_DESIGN_TRACE` 출력은 최종 코드에서 제거됐다.

## 3. 계측으로 확인한 동작

수정 전 trace:

- `design key pressed ... keyval=122 state=ctrl`
- `screen.active=Form1:TForm1`
- `app.active=False`
- `CN_KEYDOWN`/`LM_KEYDOWN` 전달 결과가 undo 실행으로 이어지지 않음

수정 후 trace:

- `before undo/redo prep ... app.active=True ... screen.active=Form1:TForm1`
- `CN_KEYDOWN result=1`
- `TComponentWalker.Walk: Button... is Destroying.`

사용자 실기 확인:

- Edit menu를 열지 않은 상태에서 form designer `Ctrl+Z` undo 동작 확인.

아직 별도 수동 확인이 남은 항목:

- `Ctrl+Y` 또는 `Ctrl+Shift+Z` redo
- Delete key component 삭제 회귀 여부
- source editor Ctrl+Z/Ctrl+Y 회귀 여부
- Object Inspector와 form designer 전환 후 undo/redo menu enabled 상태

## 4. 검증 완료

다음 검증은 모두 통과했다.

- `git diff --check -- lazarus/lcl/interfaces/gtk4/gtk4widgets.pas`
- trace 문자열 잔존 확인: `rg "Gtk4DesignTrace|LAZ_GTK4_DESIGN_TRACE|before undo/redo prep|key CN|key LM"` 결과 없음
- `make lcl LCL_PLATFORM=gtk4`
- `make bigide LCL_PLATFORM=gtk4`
- `make lcl LCL_PLATFORM=gtk2`
- `./cbuild` (`== done ==`, `lazarus` 바이너리 생성 확인)

## 5. 주의사항

- 이 문제는 Lazarus core 수정 없이 LCL GTK4에서 해결했다.
- `main.pp`의 `ProcessIDECommand` enabled gate를 직접 우회하거나 command enabled 값을 직접
  변경하는 접근은 금지한다.
- 향후 관련 회귀가 나면 먼저 `Application.Active`, `Screen.ActiveCustomForm`,
  `Gtk4CurrentFocusCtl`, `Gtk4ProcessingDeferredEvents`, deferred mouse queue 상태를
  계측한다.
- `git add .` 금지. 이 저장소에는 미추적 벤더 파일과 빌드 산출물이 많다.

## 6. 관련 커밋

- `45d2bca GTK4: fix designer undo redo shortcuts`
- `c69a34a GTK4: deliver form activation to LCL`
- `4a9cadf GTK4: receive designer keys at the window - Del deletes components again`
