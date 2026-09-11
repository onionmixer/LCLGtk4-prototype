# TODO — LCL_GTK4 프로젝트 미결 항목

이 문서는 GTK4 위젯셋 작업 중 발견됐지만 이 프로젝트 밖(업스트림 LCL의 다른 위젯셋, 환경)에 있거나
아직 착수하지 않은 항목을 모은다. 항목 번호는 KControls 저장소의
`CLIPBOARD_MULTIBYTE_REPORT.md`와 같다.

---

## B9. [LCL Qt5 업스트림] 포커스 없는 편집 콤보에서 `SelStart`/`SelLength` 설정이 유지되지 않는다

- 상태: **미수정(업스트림)**. GTK4 위젯셋과 무관. QT5 하네스 기준선(`baseline_qt5.txt`)에 2건 등록.
- 발견: 2026-09-02, GTK4 콤보 선택 트랜잭션(Phase 7 ②) 검증의 QT5 대조군에서.
- 환경: Lazarus 4.4 (`lcl-utils 4.4+dfsg-2`, `/usr/lib/lazarus/4.4`), Qt 5.15.3, X11(xcb).

### 증상
`TComboBox`(csDropDown, 편집 가능)가 **포커스를 갖지 않은 상태**에서:

| 조작 | 기대(GTK2/Win32/GTK4) | Qt5 실측 |
|---|---|---|
| `SelStart := 1; SelLength := 3` | `SelText = '력 텍'`(1..3) | `SelText = '입력 '`(0..2) |
| `SelStart := 5` (단독) | `SelStart = 5` | 200ms 뒤 `SelStart = 0` |

포커스된 콤보와 `TEdit`(포커스 유무 모두)은 정상.

### 재현
KControls 저장소 `tests/kmemo_cliptest/run_cliptest.sh qt5` → `TestComboSelection`의
`combo unfocused SelStart := 1; SelLength := 3: SelText`, `combo unfocused SelStart := 5 alone: SelStart after 200ms`
(텍스트 `입력 텍스트 선택`, 두 번째 콤보 `C2`에 포커스를 주지 않고 설정).

### 원인(소스 확인, `/usr/lib/lazarus/4.4/lcl/interfaces/qt5/`)
1. `qtwsstdctrls.pp` `TQtWSCustomComboBox.SetSelStart`(1558-1574): `QtEdit.setSelection(NewStart, 0)`.
2. `qtwidgets.pas` `TQtComboBox.setSelection`(11568) → `TQtLineEdit.setSelection`: `ALength > 0`이면
   `QLineEdit_setSelection`, 아니면 **`setCursorPosition(AStart)`** — 커서만 옮기고
   `CachedSelectionStart`는 갱신하지 않는다.
3. `qtwidgets.pas` `TQtLineEdit.getSelectionStart`: 선택이 없고 **포커스가 없으면**
   `CachedSelectionStart <> -1`일 때 그 캐시를 돌려준다(커서 위치가 아니라).
   → 비포커스 상태에서 `SelStart := 5` 뒤 `SelStart`를 읽으면 stale 캐시(0).
4. `TQtWSCustomComboBox.SetSelLength`(1576-1590): `AStart := GetSelStart(...)` = stale 0 →
   `setSelection(0, 3)` → 0..2 선택.

포커스가 있으면 3의 분기가 커서 위치를 돌려주므로 정상이다. `TEdit`(`TQtWSCustomEdit`)은 다른 경로라
증상이 없다.

### 수정 방향(업스트림 제안용)
- `TQtLineEdit.setSelection`/`setCursorPosition`에서 비포커스일 때 `CachedSelectionStart`(및 길이 캐시)를
  함께 갱신하거나, `getSelectionStart`가 비포커스에서도 실제 `cursorPosition`을 우선하도록 변경.
- 회귀 확인: 위 하네스 2건 + 포커스된 콤보/`TEdit` 시나리오(`TestNativeSelection`, `TestComboSelection`).

---

## B7 / B8. [LCL Qt5 업스트림] 클립보드 관련 (참고)

- **B7**: 외부 소유자가 `text/rtf`만 제공하면 LCL Qt5 클립보드가 이를 인지하지 못한다. 하네스는 GTK4 헬퍼로
  `text + text/rtf`를 함께 제공해 우회.
- **B8**: `TMemo.SelectAll`+`CopyToClipboard`에서 마지막 문자(`é`)가 누락 — Qt5 `SelectAll`이 UTF-16 코드
  유닛이 아니라 코드포인트 수로 길이를 잡는 문제. 기준선 2건.
- 상세: KControls `CLIPBOARD_MULTIBYTE_REPORT.md` §B7/B8.

---

## E1. [환경] GTK4 앱의 PRIMARY 선택을 gnome-terminal 3.44(VTE)에 가운데 클릭으로 붙여넣기 실패

- 순수 GTK4 `GtkEntry`에서도 동일, GTK3는 정상 → 이 포트와 무관(GTK 4.6.9 X11 소유자 ↔ VTE 0.68 요청 방식).
- 소유자 쪽 검증: PRIMARY 타깃(`UTF8_STRING`, `TEXT`, `STRING`, `text/plain;charset=utf-8`, `text/plain`)과
  GTK3 클립보드 API 읽기는 정상. 배포판 GTK4가 `G_ENABLE_DEBUG` 없이 빌드되어 `GDK_DEBUG=clipboard` 불가 →
  귀책 확정에는 X 프로토콜 추적 필요.

---

## 이 포트에서 결정된 비작업 항목

- 일반 문자 키에 대한 `OnKeyDown` 미전달(키 컨트롤러의 IM 컨텍스트가 press를 소비 → `key-pressed` 미발생,
  문자는 IM commit으로만 전달): 사용자 결정으로 **작업하지 않음**(2026-09-02). `OnKeyPress`/`OnUTF8KeyPress`는 정상.


---

## G. [GTK4] 키 전달 2차 범위 (2026-09-11, 계획서 `PLAN_GTK4_KEY_PREDISPATCH.md` §3-B/§3-C/§4 D3–D4, §10)

TEdit Return 수정(§15) 과정에서 실측된 같은 계열 결함. 근거와 수정 방향은 계획서에 확정돼 있고 착수는 사용자 결정 대기.
- **G1** 리스트류(TListBox/TCheckListBox/TListView) space, 드롭다운 콤보 Return/space: 행 위젯·토글버튼이 먼저 소비 → 컨테이너에
  CAPTURE pre-dispatch(§6.1).
- **G2** 비텍스트 위젯의 IM 컨텍스트가 문자/space press 를 삼킴 → 모든 비텍스트 위젯 문자 OnKeyDown 부재, **TCheckBox/
  TRadioButton space 토글 불능**, 버튼 space 클릭 불능(§6.3; TCustomControl 한글 회귀 검증 필수).
- **G3** `IsArrowKey`/Tab 정책: TTrackBar 화살표 불능, 버튼류 화살표 내비게이션 부재, Tab OnKeyDown 부재(§6.4).
- **G4** TMemo.OnChange 가 키 입력에 발화하지 않음(D3). **G5** 콤보 Up/Down 항목 이동 불능, 드롭다운 space 후 키 갇힘(D4).
- **G6** Ctrl+문자 KeyPress 가 #1..#26 이 아니라 문자(#97)(C4; gtk2/qt5 는 제어문자).
- **G7** TSpinEdit: PageUp/PageDown·포커스 아웃 시 GTK 가 텍스트를 다시 쓰면 insert-text 훅이 타이핑으로 오인해 OnKeyPress 발생
  (§12.4 ②); Phase 3 에서 스핀 pre-dispatch 와 함께 처리.

## H. [GTK4] 강제 FCentralWidget 할당 — 범위 밖 잔여 (2026-09-11, 계획서 `PLAN_GTK4_SCROLLFIXED_ALLOCATION.md` §5-C, §10)

수정(7289a76)은 `wtScrollingWin` 위젯만 다룬다. 하네스로 드러났지만 스크롤과 무관해 남긴 것(사용자 결정):
- **H1** 비스크롤 클래스의 강제 할당 불일치: `TGtk4StaticText`(GtkLabel 이 프레임 border 만큼 2px 과대), `TGtk4ProgressBar`
  (`InitializeWidget` 의 `set_size_request` 가 남아 줄일 때 GTK 정답과 어긋남), `TGtk4StatusBar`(GTK 정답 높이 0 — 강제 할당이
  오히려 표시를 유지하는 듯, 건드리지 말 것), `TGtk4SplitterSide`(위젯셋 SetBounds 직접 호출 시만).
- **H2 — 해결(670a720, 2026-09-11 밤, 계획서 §14–15)** `LCLGtkFixedSnapshot` 의 cairo 노드를 뷰포트 가시 영역으로 한정 + adjustment 변경 시 재snapshot.
  (아래는 착수 전 기록) 실측(2026-09-11 저녁,
  하네스 `perf`/`perfstale` 모드, `out_perf/`): GL 렌더러(GTK 4.6 기본)에서 1400×12000 콘텐츠는 스크롤 1단계당 CPU 14→132ms,
  wall 17→119ms, RSS +130MB(cairo 렌더러는 5→8ms). **콘텐츠 높이가 cairo 이미지 표면 한계 32767px 를 넘으면(1400×60000)
  GL 렌더러가 `gsk_gl_driver_cache_texture` 단언으로 프로세스를 abort** — 수정 전(첫 표시 상태)에도 같음, 수정과 무관한 기존 설계
  결함. 긴 노트(약 2000줄 이상)의 tomboy-ng-gtk4 가 GL 렌더러에서 죽을 수 있다. 계획서 §13 참조.
- **H3** 폼 표시 후 생성된 스크롤 컨트롤의 첫 `SetScrollInfo` 가 미할당 SW 기준으로 콘텐츠 크기를 변환해 범위가 어긋남
  (`late` 시나리오 upper 11601 vs 12000; `gtk4winapi.inc:5197-5222`).
- **H4** `FPaintArea` 강제 할당은 스크롤 컨테이너에서 오버레이 크기와 어긋나지만 `draw_func=nil`·`can_target=False` 라 무증상.

## I. [GTK4] 마우스 배달 — 범위 밖 잔여 (2026-09-12, 계획서 `PLAN_GTK4_SCROLLBAR_DRAG_SELECTS.md` §4, §10-2, §13.5, §14.1-4)

수정(ba78585/ba98e2e/24d1d09)은 chrome·좌표·소유 판정을 다룬다. 하네스로 드러났지만 범위 밖으로 남긴 것:

- **H** `TGtk4HintWindow`(override-redirect GtkWindow)가 포인터 아래에 떠서 press 를 가로챔 — TTreeView 노드 툴팁이 켜져 있으면 스크롤바 클릭이 먹힌다(qt5 툴팁은 입력 투명).
  후보: `gtk_widget_set_can_target(False)` 또는 press 시 숨김. 하네스 `treeviewnohint` 로 우회.
- **B'/B''** TListView 의 client 원점이 헤더를 포함(gtk4 y=200 vs qt5 170), 노트북 탭 press 가 notebook-local(y=9 vs qt5 -28).
- **I** `TMemo`(GtkTextView) 클라이언트 드래그의 release 가 컨트롤 밖에서 놓이면 `OnMouseUp` 없음(qt5/gtk2 는 있음).
- **J** gtk4 폼 `AutoScroll` 스크롤바가 만들어지지 않음(`TGtk4Window` adjustment pin; 부모 있는 폼만 정책 토글 허용).
- **L** `TListBox` 가로 정책 NEVER 인데 `GetScrollBarVisible(SB_HORZ)` 가 True. **M** `TMemo`/`TListBox` 의 `GetScrollPos` 가 스크롤을 반영하지 않음.
- **N** overlay 스크롤바(TMemo/TListBox/TCheckListBox): indicator 가 드러나지 않은 상태의 press 는 GTK 대상이 텍스트/리스트뷰라 chrome 으로 걸러지지 않음(실기 확인 항목).
- **O** TButton 의 motion 좌표가 qt5/gtk2 보다 (17,5) 작음 — `getClientOffset` 이 버튼 내부 라벨(중앙 위젯)을 원점으로 삼음(하네스 `button`).
- **P** 런타임 TButtonControl 은 LM_LBUTTONDOWN/UP 을 받지 않음(`gtk4widgets.pas` TButtonControl exit, 'clicked' 로 OnClick); qt5/gtk2 는 받음. 24d1d09 로 조상 누출은 사라짐.
- **Q** 자식 MouseDown 에서 `SetCaptureControl(부모)` 한 부모는 motion 은 받지만(캡처 우회) release 는 못 받음(dedup 이 자식 항목을 택함; win32 는 캡처 컨트롤이 받음).
- 스크롤 계열(`TGtk4CustomControl` 파생)의 `SetBorderStyle` CSS border 가 GtkFixed 에 붙어 paint 원점(overlay)과 자식 원점(fixed content)이 1px 어긋남(기존; FWidget 에 붙여야 함).
  `getClientRect` 도 CSS border·왼쪽/위 스크롤바 placement 를 반영하지 않음.
- LCL `ControlAtPos` 재귀(`wincontrol.inc` "ClientOrigin contains the scroll offset")는 중첩 스크롤 자식에서 qt5/gtk2 와 같은 가정 불일치(LCL 수준).
