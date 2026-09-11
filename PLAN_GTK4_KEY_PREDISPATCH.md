# PLAN: GTK4 네이티브 위젯이 선점하는 키의 LCL 전달 (pre-dispatch) — 계획서

작성: 2026-09-11 (세션 Claude Fable 5.1). 요청: `REQUEST_2026-09-11_ENTRY_RETURN_KEYDOWN.md`.
대상 트리: `lazarus/` @ `a90e6d2`, GTK 4.6.9 (`gtk-4.6.9/` 소스로 대조). 상태: **계획(코드 변경 없음)**.
교차검토: codex CLI `gpt-6-astra` read-only → 회신은 전건 코드 대조로 재검증(`codex-review-verify` 절차). 결과는 §9.

---

## 0. 요약과 범위 결정

- **요청의 결함(R1)**: GTK4 `TEdit` 에서 `Return`/`KP_Enter` 의 `OnKeyDown` 이 오지 않는다. 실측으로 확인했고,
  같은 이유로 **기본 버튼(`Default=True`) 이 Enter 로 실행되지 않는다**(LCL 의 `DoReturnKey` 는 KeyUp 에서
  돌지만 KeyDown 에 기록된 키가 있어야 동작, `application.inc:1734-1775`). tomboy-ng 검색창 증상과 일치.
- **같은 구조의 결함군**: 원인은 "LCL 키 컨트롤러가 실제 포커스 위젯 위에 있지 않다"(§3-A)이며 `TEdit` 뿐 아니라
  `TSpinEdit`, 편집형 `TComboBox`, `TComboBox(csDropDownList)` 가 같다. 리스트류는 Return 은 도착하지만 `space`
  가 행 위젯에 먹힌다. 별개 원인(§3-B, §3-C)으로 **모든 비텍스트 위젯에서 문자 키의 OnKeyDown 이 없고
  `TCheckBox`/`TRadioButton` 이 space 로 토글되지 않으며**, `TTrackBar` 화살표가 동작하지 않고, `Tab` 의
  OnKeyDown 이 어디서도 오지 않는다.
- **범위 제안**: 이 계획의 **필수 범위 = R1 + 같은 구조(§3-A) 의 편집 계열 3종(TEdit/TSpinEdit/편집 콤보)** 이다.
  §3-B/§3-C 와 별건 결함(§4 D1–D4)은 **근거와 수정 방향을 이 문서에 확정해 두되 사용자가 범위를 정한다**
  (§10). 요청 문서의 원칙(IM 경로 무간섭, TODO.md 의 문자 키 OnKeyDown 비작업 결정 유지)은 그대로 지킨다.

## 1. 확정 사실 — GTK 4.6.9 소스 (추측 아님, 파일:줄)

1. **전파 순서**: 키 이벤트는 포커스 위젯을 대상으로 CAPTURE(root→target) → TARGET → BUBBLE(target→root).
   `gtk/gtkmain.c:1857-1938`, `gtk/gtkwidget.c:4732-4760`. 한 컨트롤러가 TRUE 를 돌려주면 같은 위젯의 나머지와
   상위 전파가 **모두 중단**된다(`gtkwidget.c:4522-4597`, `gtkmain.c:1929-1932`).
2. **같은 위젯·같은 단계에서는 나중에 추가한 컨트롤러가 먼저 실행**(`g_list_prepend`, `gtkwidget.c:11461`).
   클래스 키 바인딩(`gtk_widget_class_add_binding*`)은 인스턴스 init 에서 `gtk-widget-class-shortcuts`
   컨트롤러로 설치되며 **BUBBLE 단계, 그 위젯 자신**에서 돈다(`gtkwidget.c:2401-2406`, 기본 phase BUBBLE
   `gtkeventcontroller.c:256`).
3. **GtkText**: 키 컨트롤러는 **TARGET 단계**이고 IM 컨텍스트가 붙어 있어 IM 필터가 먼저 돈다
   (`gtktext.c:1943-1952`, `gtkeventcontrollerkey.c:99-104`). `Return`/`ISO_Enter`/`KP_Enter` → `activate`
   시그널 바인딩(`gtktext.c:1423-1431`), 그 외 Left/Right/Home/End/BackSpace/Delete/Ctrl+A/X/C/V/Z/Y/Insert 등
   33개 바인딩(`gtktext.c:1341-1544`). **Escape/Tab/Up/Down/PageUp/PageDown 바인딩은 없다.**
   `activate` 는 void 시그널이라 단축키 액션이 항상 handled=TRUE 로 끝난다 → 부모(GtkEntry)의 BUBBLE 컨트롤러는
   Return 을 절대 못 본다.
4. **GtkEntry** 자체는 바인딩·키 컨트롤러가 없고 포커스를 내부 GtkText 로 넘긴다(`gtkentry.c:436-441`).
   **GtkSpinButton** 도 내부 GtkText 가 포커스(`gtkspinbutton.c:1024`), Up/Down/PageUp/PageDown → `change-value`
   바인딩(`:594-603`), Return 은 GtkText 의 `activate` 를 받아 값 갱신(`:1030`, `:1485-1493`).
5. **GtkTextView**: 키 컨트롤러 BUBBLE(`gtktextview.c:2023-2032`), Return/Tab 은 바인딩이 아니라 핸들러가 삽입
   (`:5446-5499`). LCL 컨트롤러가 같은 위젯에 나중에 붙어 먼저 돈다 → 메모는 현재 구조가 맞다(실측도 일치).
6. **리스트**: 이동 바인딩은 GtkListBase(`gtklistbase.c:1053-1107`), **Return/Space 는 행 위젯
   GtkListItemWidget**(`gtklistitemwidget.c:286-310`)에 있다. 포커스는 행에 있다(`:441`).
7. **GtkButton/GtkCheckButton**: `space/KP_Space/Return/ISO_Enter/KP_Enter` 를 자기 클래스 단축키로 `activate`
   (`gtkbutton.c:194-195, 315-324`, `gtkcheckbutton.c:508-514, 640-649`). 창 레벨이 아니다.
8. **GtkWindow**: 자기 클래스 바인딩(BUBBLE, 맨 마지막)에 `Return/KP_Enter → activate-default`,
   `space → activate-focus`, **화살표·Tab → move-focus**(`gtkwindow.c:1232-1256`). Escape 바인딩 없음.
   → 포커스 위젯과 그 조상이 아무도 소비하지 않은 Up/Down/Tab 은 GTK 가 포커스를 옮긴다.
9. **`gdk_keyval_to_unicode`**: `Return`→`\r`, `Tab`→`\t`, `Escape`→27, `BackSpace`→8, `Delete`→127,
   **`KP_Enter`→0, `ISO_Enter`→0**(`gdk/gdkkeyuni.c:835-871, 888-920`).
10. `key-pressed` 시그널은 RUN_LAST + boolean 누적기(첫 TRUE 에서 중단)(`gtkeventcontrollerkey.c:203-212`).
    `gtk_event_controller_key_forward` 는 **한 위젯**에만 CAPTURE/TARGET/BUBBLE 순으로 재전달(`:343-367`).

## 2. 확정 사실 — LCL gtk4 코드 (`lazarus/lcl/interfaces/gtk4/gtk4widgets.pas`)

- 컨트롤러 설치 `TGtk4Widget.InitializeWidget` 4700-4770: ① 디자인 CAPTURE 키 컨트롤러(창은 GtkWindow, 그 외
  `GetContainerWidget`), ② **LCL 키 컨트롤러 = BUBBLE, `GetContainerWidget`**, IM 컨텍스트는 `wtEntry/wtMemo`
  가 아니면 부착(4728-4740) — 즉 **버튼·체크·리스트·트랙바·그리드·스핀·콤보 모두 GtkIMMulticontext 가 LCL
  컨트롤러에 붙는다**, ③ 창 전용 bare 컨트롤러(4763-4770). `GetContainerWidget` 는 `FCentralWidget` 또는
  `FWidget`(5245-5251)이며 오버라이드가 없다.
- `Gtk4KeyPressedCB` 1862-1923: keyval→`gdk_keyval_to_unicode` 로 `string_` 생성 → `GtkEventKey(…, True)`.
  `Gtk4FormKeyBelongsToChild` 1855: 폼 컨트롤러는 `ActiveControl<>nil` 이면 통째로 건너뜀.
- `GtkEventKey` 3778-4045 흐름: `VK_TAB` 이면 **CN/LM 전달 없이** `SelectNext` 후 exit(False)(3846-3851) →
  CN_KEYDOWN(3884-3906): 처리/`VK_UNKNOWN`/**`IsArrowKey`** 면 entry·memo 는 `exit(False)`, 그 외는
  **`exit(True)`** → LM_KEYDOWN(3910-3946): `[wtListBox,wtListView,wtEntry,wtMemo]` 는 전달 후 `CharCode=0`
  일 때만 True(memo WantReturns 예외), 그 외는 `Result := CharCode=0` → 문자 블록(3954-4034, `string_` 비었으면
  건너뜀) → 마지막 `Result := Msg.CharCode in FKeysToEat`(4043). `FKeysToEat` 기본 `[VK_TAB,VK_RETURN,VK_ESCAPE]`
  (4596), memo 만 `[]`(8895).
- 편집 계열 delegate 기록기: `TGtk4Entry.InitializeWidget` 6520-6553 이 **내부 GtkText 에 CAPTURE 키 컨트롤러**
  (`Gtk4EntryDelegateKeyPressCB` 6173, 기록 전용, `Result := False`)와 insert-text/preedit/clipboard/focus-leave
  훅을 단다. `TGtk4SpinEdit` 는 이를 그대로 상속하지만 `FWidgetType=[wtWidget, wtSpinEdit]` 로 **`wtEntry` 가 없어**
  GtkEventKey 의 entry 분기를 타지 않고, 4728 조건으로 **중복 IM 컨텍스트**까지 받는다(6737). 편집 콤보는
  `FEntry` 의 delegate 에 같은 기록기(`Gtk4ComboDelegateKeyPressCB` 12225, 12529-12535).
- 문자 입력은 delegate `insert-text` 에서 OnKeyPress/UTF8KeyPress/KeyPreview 를 도출(`0ac8fcd`,
  `Gtk4EntryDelegateInsertTextCB` 6289-6398). **LM_KEYDOWN/CN_KEYDOWN 을 합성하는 곳은 GtkEventKey 밖에 없다.**
- `'activate'` 시그널을 GtkEntry/GtkText/GtkSpinButton 에 연결한 곳은 **없다**(연결은 메뉴 액션 8468, 콤보 팝오버
  리스트 12551 둘뿐).

## 3. 원인 분류 (실측 행렬 §4 와 대응)

- **A. 컨트롤러 위젯 ≠ 포커스 위젯** — 포커스 위젯(GtkText / GtkListItemWidget / 드롭다운 내부 토글버튼)의
  클래스 바인딩이 자기 BUBBLE 에서 먼저 소비. 해당: `TGtk4Entry`(GtkEntry↔GtkText), `TGtk4SpinEdit`
  (GtkSpinButton↔GtkText), `TGtk4ComboBox`(GtkBox↔FEntry 의 GtkText, 두 단계), `TGtk4DropDown`(GtkDropDown↔토글버튼),
  `TGtk4ListBox/CheckListBox/ListView`(GtkListView/ColumnView↔행: space 만). 증상: Return/KP_Enter/Left/Right/
  Home/End/BackSpace/Delete/Ctrl+A 등의 **KeyDown 부재**(KeyUp 은 옴 — release 는 아무도 소비하지 않음).
- **B. LCL 컨트롤러의 IM 컨텍스트가 press 를 삼킴** — 비텍스트 위젯에 붙은 GtkIMMulticontext 가 문자·space 를
  `filter_keypress` 로 소비해 commit 만 남김 → `key-pressed` 미발생 → OnKeyDown 없음, `UTF8KeyPress` 만 옴
  (`Gtk4IMCommitCB` 1834-1837 폴백). 근거: 키 컨트롤러는 IM 필터가 TRUE 면 시그널을 내지 않음
  (`gtkeventcontrollerkey.c:99-104`); GtkIMContextSimple 은 조합 중이 아니어도 **제어문자가 아닌 모든 keyval 을
  commit 하고 TRUE 를 돌려줌**(`gtkimcontextsimple.c:730-737`, Ctrl/Alt 조합만 FALSE `:906-935`). **부작용**: GtkCheckButton/GtkButton 의 space 단축키까지 못 받아
  **체크박스·라디오가 space 로 토글되지 않음**(실측). Ctrl+A 의 KeyPress 가 #1 이 아니라 #97 로 옴.
- **C. `GtkEventKey` 정책** — (C1) `VK_TAB` 을 CN/LM 전달 없이 자체 `SelectNext` 후 False 반환 → **Tab 의
  OnKeyDown 이 전 위젯에서 부재**, 게다가 GTK 창의 move-focus 도 이어서 실행될 수 있음(이중 이동 여부는 §4 Tab 행
  참조). (C2) `IsArrowKey` 단락: entry/memo 이외는 `exit(True)` → **TTrackBar 화살표가 슬라이더를 못 움직임**
  (실측 E 부재), 버튼류에서도 GTK 이동 차단 + LCL `DoArrowKey` 도 안 옮김(실측: qt5/gtk2 는 이동). entry 는
  `exit(False)` → Up/Down 이 GTK 창의 move-focus 로 **TEdit 에서 포커스를 다음 컨트롤로 옮김**(qt5/gtk2 는 유지).
  (C3) `KP_Enter` 는 `string_` 이 비어 KeyPress #13 이 안 옴(qt5/gtk2 는 옴).
- **D. 별건 결함**(키 전달 아님) — §4 D1–D4.

## 4. 실측 행렬 (하네스: `lazarus/example_gtk4_keymatrix_validation/`, 기준선 `baseline_2026-09-11/`)

같은 소스를 gtk4(프로토타입)/gtk2(프로토타입)/qt5(시스템 4.4) 로 빌드, Xvfb+xdotool 로 키 19개 전송.
표기: KD=OnKeyDown KU=OnKeyUp KP=OnKeyPress U8=OnUTF8KeyPress DEF=기본버튼 ED=EditingDone E=네이티브 효과.

| 컨트롤 | gtk4 에서 qt5/gtk2 와 다른 점 (핵심만) | 원인 |
|---|---|---|
| edit | Return/KP_Enter: KU+ED 만, **KD·KP·DEF 없음**. Left/Right/Home/End/Delete/Insert: KU 만. BackSpace: E+KU (KP #8 없음). 문자: U8/KP/E 는 오지만 KD 없음(TODO 결정). Ctrl+A: KD 17 만, 65[ssCtrl] 없음. **Down → 포커스가 spin 으로 이동**. Tab: KD 없음 | A, C2, C3 |
| spin | edit 와 동일 + Up/Down 에 아무 이벤트도 없음(값도 불변, D2 와 얽힘). **편집 키(Delete/BackSpace/문자) 입력 시 세그폴트**(D1). Prior/Next 는 KD 만(E 없음) | A, D1, D2 |
| comboedit | edit 와 동일(Return/KP_Enter KD 없음, Ctrl+A 65 없음). Down 이 항목을 바꾸지 않음(qt5 는 바꿈) | A |
| combolist | Return/KP_Enter: KU 만(**KD 없음**). space: KU 만(팝업이 열려 이후 키를 삼킴). Up/Down: KD 는 오나 항목 불변 | A |
| memo | 키 전달은 일치. **OnChange 가 키 입력에 발화하지 않음**(삽입은 됨) | D3 |
| listbox/checklist/listview/treeview | Return/KP_Enter: KD+DEF 정상. **space: KU 만**(행의 `listitem.select` 가 소비). 문자 `a`: U8 만(KD/KP 없음). Ctrl+A: KP #97(qt5 #1). Tab KD 없음. KP_Enter KP #13 없음 | A(space), B, C1, C3 |
| button | Return: KD+KP+E 정상. **space: U8 만(클릭 안 됨)**. 문자: U8 만. 화살표: KD 오지만 포커스 이동 없음(qt5/gtk2 는 인접 컨트롤로 이동) | B, C2 |
| checkbox/radio | **space 로 토글되지 않음**(gtk4 FINAL checkbox=False, qt5 True). 화살표 이동 없음. 그 외 button 과 동일 | B, C2 |
| trackbar | **Up/Down/Left/Right 가 슬라이더를 안 움직임**(Home/End/PageDown 은 됨). space/문자: U8 만 | C2, B |
| grid | 문자 `a`: U8 만(KD/KP 없음 — 에디터 시작은 U8 로 가능). space 동일 | B |

공통: `KP_Enter` 에 KP #13 없음(C3); `Delete` 에 KP #127 없음(qt5 만 보냄, gtk2 도 안 보냄 → 비작업).

**별건 결함(이번에 발견, 키 전달과 무관)**
- **D1** `TSpinEdit` 키보드 편집 시 무한 재귀 크래시: `TextChanged → Value(GetValue) → gtk_spin_button_set_value
  → gtk_editable_set_text → changed → CM_TEXTCHANGED → TextChanged …` 118회 반복 후 스택 오버플로
  (`baseline_2026-09-11/gdb_spin_recursion.log`, `spinedit.inc:76`, `gtk4widgets.pas:6119`, `gtk4wsspin.pp:92`).
- **D2** `TSpinEdit.Value := 5`(핸들 생성 전) 가 gtk4 에서 0 으로 읽힘(모든 실행의 FINAL `spin=0`, qt5/gtk2 는 5).
- **D3** `TMemo.OnChange` 가 키 입력에 발화하지 않음(qt5/gtk2 는 매 키마다 발화).
- **D4** `TComboBox(csDropDownList)`: space 로 팝업이 열린 뒤 키가 팝업에 갇힘, Up/Down 이 항목을 바꾸지 않음
  (qt5/gtk2 는 바꿈). 편집 콤보도 Down 이 항목을 바꾸지 않음.

## 5. 기준 의미론 (무엇이 "정상"인가)

- **LCL 코어 계약**: 위젯셋은 키를 **네이티브 처리보다 먼저** CN_KEYDOWN/LM_KEYDOWN 으로 넘기고, LCL 이
  `CharCode := 0`(VK_UNKNOWN) 으로 지우면 네이티브 처리를 막는다. Return→기본 버튼, Escape→취소 버튼,
  Tab/화살표 내비게이션은 **LCL(`TApplication.DoReturnKey/DoEscapeKey/DoTabKey/DoArrowKey`)** 이 담당한다
  (`application.inc:1704-1775, 2167-2240`). `DoReturnKey/DoEscapeKey` 는 **KeyUp** 에서 돌되 같은 키의 KeyDown
  기록이 있어야 한다. `TCustomEdit.KeyUpAfterInterface` 가 VK_RETURN 에 `EditingDone`(`customedit.inc:461-471`).
- **gtk2**(`gtk2proc.inc:1838-2420`): `key-press-event` 를 클래스 핸들러 전(before)과 후(after) 두 번 연결. before 에서
  CN_KEYDOWN, LCL 이 바꾸면 `StopKeyEvent`. GtkEntry/TextView/TreeView 가 Return/Tab 을 먹어 after 가 안 오므로
  **`EmulateEatenKeys` 가 before 단계에서 LM_KEYDOWN 을 직접 합성**(2095-2180: "gtk2 gtkentry handles the return
  key and emits an activate signal. The LCL does not use that and needs the return key event => emulate it").
  스핀버튼은 release 에서 down+up 합성, 버튼은 Return release 합성.
- **qt5**(`qtwidgets.pas:3153-3680`): 이벤트 필터가 QLineEdit 보다 먼저 SlotKey 로 CN/LM/CHAR 전달, 끝에
  `Result := KeyMsg.CharCode in KeysToEat`(3675) — 기본 `[VK_TAB, VK_RETURN, VK_ESCAPE]`(2098) 이므로 **편집
  위젯의 Return/Tab/Escape 는 항상 LCL 이 먹고 Qt 위젯은 받지 않는다**(TextEdit 만 `[]`, 10226).
  Ctrl 조합·화살표·Delete 등 모든 키가 KD(=CN_KEYDOWN, OnKeyDown) 로 온다. **화살표 규칙**: `EatArrowKeys`
  (3202-3210) 가 `not ProcessArrowKeys` 인 위젯에서 **LM_KEYDOWN 만 생략**(3565) — `ProcessArrowKeys` 는 기본
  False(5553, 디자인 모드 제외), 버튼류(6114)와 TCustomControl(18186)만 True. 즉 편집·리스트·트랙바에서는
  OnKeyDown 은 오되 LCL 의 `DoArrowKey` 내비게이션은 돌지 않고 Qt 위젯이 화살표를 처리하며, 버튼류에서만 LCL
  이 인접 컨트롤로 이동한다(§4 실측과 일치).
- **LCL 내비게이션의 위치**: `DoTabKey/DoArrowKey`(`Application.ControlKeyDown`) 는 **LM_KEYDOWN 경로**
  (`TWinControl.DoRemainingKeyDown`, `wincontrol.inc:5925-5940`) 에서 돌고, `DoReturnKey/DoEscapeKey` 는
  KeyUp 에서 돈다. CN_KEYDOWN 만 보내면 OnKeyDown 은 발화하지만 LCL 내비게이션은 실행되지 않는다.
  `TCustomEdit`/`TCustomComboBox` 는 `DLGC_WANTARROWS` 를 요구하지 않고(`CMWantSpecialKey` 는 darwin 만 1,
  `customedit.inc:509`, `customcombobox.inc:1238`; `DLGC_WANTARROWS` 는 리스트박스와 그리드만) — 편집 위젯에서
  화살표 내비게이션이 안 일어나는 것은 위젯셋이 LM_KEYDOWN 을 생략하기 때문이다.
- **주의(교차검토 반영)**: gtk2 의 `EmulateEatenKeys` 는 LM_KEYDOWN 을 합성할 뿐 네이티브 처리를 무조건 막지는
  않고(`gtk2proc.inc:2159`, 최종 소비는 `EventStopped` 2553), qt5 의 `KeysToEat` 도 앞선 LM 처리에서 빠져나오지
  않았을 때의 **폴스루 규칙**(3572, 3665 `SendChangedKey`)이다. "항상 네이티브를 우회" 가 아니라 "LCL 이 처리하지
  않은 Return/Tab/Escape 를 편집 위젯이 네이티브로 넘기지 않는다" 가 정확한 기준이다. 또 gtk2 는 IM 필터
  (`CheckDeadKey` → `gtk_im_context_filter_keypress`, 결과 무시, 2199-2212/2305-2308)를 **CN_KEYDOWN 보다 먼저**
  돌린다 — "LCL 먼저, IM 나중" 이 gtk2 순서라는 초안의 서술은 틀렸다(§6.3 정정).
- 결론: gtk4 의 목표 의미론은 "**LCL 먼저(비문자 키), 지우면 차단, 아니면 네이티브 계속**" + "LCL 이 처리하지 않은
  편집 위젯의 Return/Tab/Escape 는 LCL 이 소유(qt5 규칙)" 이다. §4 의 `!!` 행 대부분은 이 계약 위반이다.

## 6. 설계

### 6.1 통합 기제: "pre-dispatch" CAPTURE 컨트롤러 (원인 A)

포커스 위젯 위(또는 그 조상)에 **CAPTURE 단계** LCL 키 컨트롤러를 두면 대상 위젯의 TARGET/BUBBLE 바인딩보다
먼저 돈다(§1-1). 편집 계열은 **이미 delegate 에 CAPTURE 기록기가 있다** — 여기서 LCL 로 전달하면 된다(요청의 A안).

- **위치**: `TGtk4Entry`/`TGtk4SpinEdit`(상속) → delegate GtkText 의 기존 기록기(6542). `TGtk4ComboBox` → `FEntry`
  delegate 의 기존 기록기(12529). 리스트/드롭다운(2차 범위) → `GetContainerWidget` 에 새 CAPTURE 컨트롤러.
  창의 디자인 CAPTURE 컨트롤러(GtkWindow) 는 더 바깥에서 먼저 돌므로 영향 없음.
- **전달 내용**: 기록 후, **비문자 키**에 한해 `GtkEventKey` 의 **KeyDown 부분**(CN_KEYDOWN → LM_KEYDOWN) 을
  실행한다. 문자 키(`gdk_keyval_to_unicode ≥ 32 且 ≠127` 이고 Ctrl/Alt 없음)는 지금처럼 기록만(IM 무간섭,
  TODO.md 결정 유지). Ctrl/Alt 조합은 문자여도 전달한다(Ctrl+A 등, qt5/gtk2 동등; IM 이 뒤에서 보되 LCL 이
  지우지 않는 한 영향 없음).
- **문자 블록**: 편집 계열에서 Return/BackSpace/Escape 의 OnKeyPress(#13/#8/#27) 는 qt5/gtk2 가 보내므로
  **KeyDown 을 전달한 키에 한해 문자 블록도 CAPTURE 에서 실행**한다. 문자 키는 delegate insert-text 가 이미
  담당하므로 중복이 없다(Return/BackSpace 는 insert-text 를 발화하지 않음). `KP_Enter`/`ISO_Enter` 는 `string_`
  을 `#13` 으로 보정한다(C3, `Gtk4KeyPressedCB` 의 keyval→string 변환에 예외 추가).
- **소비 규칙**: LCL 이 CN_KEYDOWN 에서 처리했거나(`DeliverMessage<>0` 또는 `CharCode=VK_UNKNOWN`) LM_KEYDOWN 에서
  `CharCode=0` 으로 지웠으면 TRUE(GtkText 바인딩·IM 모두 차단). **주의**: 현행 CN 분기는 entry/memo 에서 처리됐어도
  `exit(False)` 를 돌려준다(3896-3905) — 그대로 추출하면 `Key:=0` 억제가 편집 계열에서 동작하지 않으므로,
  pre-dispatch 의 판정은 "CN 처리됨/지워짐 → 소비" 로 별도 정의한다(화살표 우회 `IsArrowKey` 와 구분).
  아니면 `FKeysToEat` 규칙을 적용: Return/Tab/Escape 는 TRUE(qt5 와 동일하게 LCL 소유 — GtkText `activate` 는 실행되지 않고
  기본 버튼은 LCL `DoReturnKey` 가, EditingDone 은 KeyUp 이 처리), 그 외 FALSE(GtkText 가 커서 이동·삭제 수행).
  **스핀버튼 예외**: Return 을 먹으면 GTK 의 `gtk_spin_button_update`(activate 경유, `gtkspinbutton.c:1030,
  1485-1493` — editable 일 때만) 가 안 돌므로, **정책상 먹은 경우에만**(LCL 이 `Key:=0` 으로 거부한 경우는 제외)
  editable 조건을 지켜 `update` 를 명시 호출하고, 호출 전후 `CanSendLCLMessage` 로 수명을 확인한다.
- **프리에딧 가드(교차검토 반영)**: delegate 에서 관측하는 `FPreeditText <> ''`(6255-6257, `preedit-changed` 훅)
  동안은 **pre-dispatch 를 하지 않는다**(기록만). 조합 중의 Return/Escape/화살표/BackSpace 는 IM 이 받아야 한다
  (fcitx-hangul 은 Return 으로 후보 확정·프리에딧 flush; GtkIMContextSimple 도 Ctrl+Shift+U 16진 입력을
  Return/space 로 종료 `gtkimcontextsimple.c:881-885`; GtkText 는 필터 뒤 Return/Escape 에 IM reset
  `gtktext.c:3226-3230`). 프리에딧이 비면 다음 키부터 정상 pre-dispatch.
- **Tab 은 pre-dispatch 대상에서 제외**(교차검토 반영): 현행 3846 분기는 `Sender^.is_focus` 로 `SelectNext` 를
  결정하는데 `is_focus` 는 "루트 포커스 == 그 위젯"(`gtkwidget.c:5336-5346`) 이라 지금은 GtkEntry 가 포커스가
  아니어서 LCL 이동이 실행되지 않고 GTK 창 move-focus 만 돈다. delegate(GtkText) 에서 부르면 `is_focus` 가
  TRUE 가 되어 **LCL 이동 + GTK 이동의 이중 이동**이 된다. Tab 은 C1(2차)에서 LCL `DoTabKey` 경로로 통째로
  재설계할 때까지 현행 유지(Shift+Tab 포함 실측 게이트).
- **스핀 옵트인 게이트**(교차검토 반영): `TGtk4SpinEdit` 는 `TGtk4Entry.InitializeWidget` 의 콜백을 `Self` 로 그대로
  상속하므로(6544) Phase 2 의 pre-dispatch 가 스핀에 자동 적용된다. 가상 메서드(예: `KeyPreDispatchEnabled`)
  로 Phase 2 는 `TGtk4Entry` 만 켜고 스핀은 Phase 3 에서 Return→`update`·화살표 예외와 함께 켠다.
- **`wtEntry` 를 스핀에 추가하지 않는다**(교차검토 반영): 1541-1546 의 마우스 캡처 경로가 `wtEntry` 면
  `gtk_entry_grab_focus_without_selecting(PGtkEntry(AWidget))` 를 부르는데 스핀의 `FWidget` 은 GtkSpinButton 이라
  `GTK_IS_ENTRY` 단언 위반이 된다. 대신 "편집 계열" 판정용 별도 술어(예: `IsTextEntryLike` = wtEntry 또는
  wtSpinEdit)를 두고 GtkEventKey 의 entry 분기(3901, 3922)와 4728 의 IM 컨텍스트 제외 조건을 그 술어로 바꾼다.
- **중복 억제**: CAPTURE 에서 전달했으나 FALSE 로 흘려보낸 키(Up/Down/Escape/F-키/Insert/PageUp/Down 등 GtkText
  가 소비하지 않는 키)는 GtkEntry/GtkBox 의 기존 BUBBLE 컨트롤러(`Gtk4KeyPressedCB`)에 다시 도착한다.
  **같은 GdkEvent 포인터**(`gtk4_event_controller_get_current_event`, 바인딩 `lazgtk4_compat.pas:289`)를
  `TGtk4Widget` 에 기록해 두고 BUBBLE 쪽은 일치하면 **KeyDown 부분을 건너뛴다**(문자 블록도 CAPTURE 에서 이미
  했으므로 통째로 skip, FALSE 반환). 한 전파 동안 GTK 는 같은 포인터를 넘긴다(`gtkmain.c:1899, 1931`).
  포인터는 빌린 값이라(`gtkeventcontroller.c:365, 595`) **수명 규칙**을 둔다: 기록은 "마지막으로 전달한 press 의
  포인터+keyval" 하나이며, 다음 press 기록 시·해당 keyval 의 release 처리 시·`DestroyWidget` 시 지운다; 기록만 한
  키(문자 키)는 기록하지 않는다. **재전송(replay) 방어**: fcitx5-gtk 는 비동기 처리 후 같은 GdkEvent 를
  `gdk_display_put_event` 로 다시 큐에 넣을 수 있다(참조, 복사 아님 — `gdkdisplay.c:484`; 설치된 fcitx 소스는
  이 저장소에 없어 **미검증**). 따라서 CAPTURE 쪽도 "같은 포인터+keyval 을 이미 전달했으면 건너뜀" 검사를 두고,
  fcitx 활성 실기에서 Return/화살표 이중 발화 여부를 **필수 실기 항목**으로 검증한다(§7 게이트).
  폼 컨트롤러는 `Gtk4FormKeyBelongsToChild` 가 이미 막는다(1855).
- **편집 콤보의 팝오버**: 팝업이 열린 동안 키는 팝오버(별도 GtkNative) 로 간다 — Return 은 리스트 행 활성화로
  `Gtk4ECB_ListActivate`(12000, 연결 12552) 가 확정하고, Escape 는 팝오버가 닫히며 `notify::visible` 핸들러
  (12555, 11972)가 취소·복원한다. 또 콤보의 delegate insert-text 훅(12270)은 deferral 만 하고 OnKeyPress 를
  만들지 않으므로 "문자 키는 insert-text 가 담당" 이라는 설명은 TEdit 에만 해당한다(콤보 문자 OnKeyPress 부재는
  기존 상태 그대로, 이 계획 범위 밖). 엔트리 delegate 의 CAPTURE 컨트롤러는 다른 native 의
  이벤트를 받지 않으므로(`GTK_LIMIT_SAME_NATIVE`, `gtkeventcontroller.c:257-274`) 트랜잭션과 겹치지 않는다 —
  Phase 4 에서 실측으로 확인.
- **Release 는 CAPTURE 전달이 필수**(교차검토 반영, 초안의 "release 는 BUBBLE 유지" 후퇴안 폐기):
  GtkEventControllerKey 는 `key-pressed` 가 TRUE 를 돌려준 keyval 을 `pressed_keys` 에 넣고, 그 release 는
  `key-released`(void 시그널) 를 낸 뒤 **자동으로 handled=TRUE 를 반환해 전파를 멈춘다**
  (`gtkeventcontrollerkey.c:120-140`, 시그널 정의 `:223-229`). 즉 CAPTURE 에서 Return 을 소비하면 그 release 는
  delegate 컨트롤러에서 끝나고 GtkEntry BUBBLE 의 `Gtk4KeyReleasedCB` 는 오지 않는다 → KeyUp 이 없으면
  `DoReturnKey`(기본 버튼)와 `EditingDone` 이 사라진다. 따라서 delegate CAPTURE 의 `key-released` 에서
  **CN_KEYUP + LM_KEYUP**(`GtkEventKey(…, False)` 전체 경로)을 전달하고, BUBBLE 쪽은 포인터 동일성으로 중복을
  막는다(소비되지 않은 키의 release 는 BUBBLE 까지 올라오므로).
- **`GtkEventKey` 분리**: 현재 한 함수가 KeyDown/Up 전달과 문자 블록을 함께 한다. `GtkEventKeyDown`(CN/LM)과
  `GtkEventChar`(UTF8/CN_CHAR/LM_CHAR/memo 치환 기록) 로 나누고 기존 `GtkEventKey` 는 둘을 순서대로 호출하는
  껍데기로 남긴다. **계약(교차검토 반영)**: 현행 코드의 `False` 는 "계속 진행" 과 "여기서 중단하되 GTK 는 계속"
  두 뜻으로 쓰이므로 Boolean 하나로는 보존이 안 된다. KeyDown 부는 3상태 `(krContinue, krStopConsumed,
  krStopPassthrough)` 를 돌려주고, 껍데기는 `krContinue` 일 때만 문자 블록으로 진행한다. 보존해야 할 결합점:
  Tab 조기 종료(3846), 컨텍스트 메뉴 TRUE 종료(3855-3869), VK_UNKNOWN 키가 CN/LM 은 건너뛰고 문자 블록엔
  도달(3882/3954), CN 분기의 entry/memo `False`·그 외 `True`(3896-3905, release 도 동일), LM 의 CharCode/KeyData
  재구성(3914-3915), 네이티브 분기의 결과 무시·`CharCode=0` 소비·memo WantReturns(3922-3937), 그 외 분기의
  nonzero 결과 조기 종료(3940-3946), 문자 블록 진입 조건(3954-3960), `IntfUTF8KeyPress` TRUE 종료(3963-3973),
  CN_CHAR 결과/CharCode 종료(3976-3997), LM_CHAR 결과 무시와 memo 치환 기록(4008-4033), 마지막 `FKeysToEat` 는
  press 폴스루에서만·`Msg`(키 메시지) 기준(4035-4043), 그리고 `CanSendLCLMessage` 실패 시 현재 결과로 즉시 종료
  (3893, 3907, 3919, 3929, 3949, 3965, 3984, 3989, 4005, 4010). **순수 추출 커밋과 변환 변경 커밋을 분리**해
  "동작 불변" 을 행렬로 증명한다.
- **`TGtk4SpinEdit`**: `wtEntry` 를 `FWidgetType` 에 추가하고(6737) 4728 조건이 그대로 중복 IM 컨텍스트를 막게
  한다. 이 변경만으로 GtkEventKey 의 entry 분기(`exit(False)`, `CharCode=0` 만 소비)가 스핀에도 적용된다.
  **D1/D2 는 별도 커밋**으로 먼저 고친다(스핀 실측이 크래시로 막혀 있음, §7 Phase 0).

### 6.2 검토했으나 채택하지 않은 대안

- **B안(요청 문서): GtkEntry `activate` 시그널로 VK_RETURN 합성** — Return 만 해결, `activate` 이후라
  `Key:=0` 로 막을 수 없음, KeyUp 순서와 기본 버튼 계약(KeyDown 기록 필요)이 어긋남, spin/콤보/리스트로 일반화
  불가. 기각.
- **BUBBLE 컨트롤러 자체를 delegate 로 이관** — IM 컨텍스트가 붙은 컨트롤러 이관은 창에서 hang 전례
  (`8c1516b` 주석, 메모리 `gtk4-key-input-architecture`). GtkText 의 IM/TARGET 컨트롤러와 같은 위젯에서 순서
  경합. 기각.
- **`gtk_event_controller_key_forward`** 로 부모에서 잡아 자식에 조건부 재전달 — 부모 BUBBLE 은 Return 을
  애초에 못 받으므로(§1-3) 출발점이 성립하지 않음. 기각.
- **모든 위젯의 LCL 컨트롤러를 CAPTURE 로 전환** — 메모의 검증된 순서(버블 char 블록이 삽입보다 먼저, IM
  deferral)를 흔든다. 위젯별 옵트인(§6.1)만 채택.

### 6.3 원인 B: 비텍스트 위젯의 IM 컨텍스트 (2차 범위, 사용자 결정)

- 현상 재확인: LCL 컨트롤러에 붙은 GtkIMMulticontext 가 문자/space press 를 소비 → key-pressed 미발생.
  체크박스/라디오 space 토글 불능, 버튼 space 클릭 불능, 모든 비텍스트 위젯 문자 KD 없음.
- 수정 방향(교차검토로 정정): gtk2 는 IM 필터를 **CN_KEYDOWN 보다 먼저** 돌리되 그 결과를 무시한다
  (`CheckDeadKey`, 2199-2212/2305-2308) — 즉 "IM 이 commit 하든 말든 KeyDown 은 항상 LCL 에 간다". gtk4 재현안:
  IM 컨텍스트를 키 컨트롤러에 `set_im_context` 로 붙이지 않고, `Gtk4KeyPressedCB` 에서 ① 필터를 먼저 호출해
  commit/preedit 시그널(기존 `Gtk4IMCommitCB` 경로)을 살리고 ② 그 결과와 무관하게 CN/LM_KEYDOWN 을 전달한 뒤
  ③ **반환값은 필터 결과가 아니라 LCL 소비 여부**로 정한다(필터 TRUE 를 그대로 돌려주면 체크박스 space 단축키가
  여전히 막힘; 반대로 조합 중 키를 네이티브로 흘리면 프리에딧이 깨질 수 있으므로 "프리에딧 활성 중이면 필터
  결과를 존중" 예외를 둔다). release 도 대칭. **텍스트 입력이 없는 위젯**(버튼·체크·라디오·트랙바·리스트) 은
  IM 컨텍스트를 아예 붙이지 않는 것이 더 단순하나 TCustomControl 계열은 유지해야 하므로 클래스별 결정이 필요. focus-in/out 은 기존
  `Gtk4FocusEnterCB/LeaveCB` 에서 `gtk_im_context_focus_in/out` 호출로 유지(현재 컨트롤러가 대신 하던 것 —
  `handle_crossing` 의 is_focus 조건 주석 4700 참조, 실측 필요).
- 이 변경은 **TCustomControl 계열(그리드·KMemo 등 IM 을 실제로 쓰는 LCL 자체 그리기 위젯)** 의 한글 입력에
  직접 영향을 준다. KControls 하네스(`.../KControls/tests/kmemo_cliptest`) 와 사용자 실기(fcitx5) 회귀 검증 없이는
  진행하지 않는다. 필수 범위에서 제외하고 §10 결정 사항으로 둔다.

### 6.4 원인 C: `GtkEventKey` 정책 (2차 범위, 일부는 필수 범위에 포함)

- **C3(KP_Enter/ISO_Enter)** — 필수 범위에 포함: `Gtk4KeyPressedCB` 의 `string_` 을 KP_Enter/ISO_Enter 에서 `#13`
  으로 보정하고, **`GdkKeyToLCLKey` 에 `GDK_KEY_ISO_Enter → VK_RETURN` 을 추가**(현재 Return/KP_Enter/3270_Enter 만
  매핑, `gtk4procs.pas:666-672`; 빠지면 CN/LM 을 건너뛰어 Return 소유가 성립하지 않음). 이 변환은 공용이라 memo·
  리스트 등 모든 위젯의 KP_Enter 행에 KP #13 이 추가된다(기대 변화로 등록).
- **C4(Ctrl+문자 KeyPress, 교차검토 반영)** — gtk4 는 `gdk_keyval_to_unicode` 만 써서 Ctrl+A 의 문자가 `'a'`(#97)
  로 가고(1886), gtk2 는 `^A..^Z` 를 #1..#26 으로 변환한다(`gtk2proc.inc:1918-1927`), qt5 도 #1. Phase 1 의 변환
  커밋에 Ctrl(Alt 제외) 조합의 a..z → #1..#26 변환을 넣는다. 공용 변환이므로 전 위젯의 ctrl+a 행이 바뀐다(기대
  변화로 등록).
- **C2(IsArrowKey)** — gtk4 의 현재 규칙(`3896-3906`): 화살표는 CN_KEYDOWN 뒤 LM_KEYDOWN 없이 종료하되
  entry/memo 는 FALSE(네이티브 계속), **그 외는 TRUE(네이티브 차단)**. qt5 규칙(§5)과 두 군데가 다르다:
  ① 비편집 위젯에서 TRUE 를 돌려줘 GtkScale 의 슬라이더 이동·GtkWindow 의 포커스 이동이 모두 막힘(트랙바
  불능, 버튼류 내비게이션 부재), ② 편집 계열에서 FALSE 를 돌려주는데 GtkText 가 Up/Down 을 소비하지 않아 창의
  move-focus 가 포커스를 옮김(qt5/gtk2 는 QLineEdit/GtkEntry 가 무시하고 포커스 유지).
  **필수 범위**: ②만 — pre-dispatch 가 편집 계열(TEdit/편집 콤보)의 Up/Down 을 전달한 뒤 **TRUE 로 소비**해 창의
  move-focus 를 막는다(LCL 내비게이션은 LM_KEYDOWN 생략으로 원래 안 돎). 스핀은 `change-value` 바인딩이 필요하므로
  FALSE. Left/Right 는 FALSE(GtkText 커서 이동).
  **2차 범위**: ① — qt5 규칙으로 정렬: 버튼류·TCustomControl(그리드 등) 은 LM_KEYDOWN 까지 전달해 LCL
  `DoArrowKey` 가 이동(지우면 TRUE), 나머지는 LM_KEYDOWN 생략 + **FALSE**(GtkScale/리스트/노트북이 처리, 아무도
  안 받으면 창 move-focus). 현재 죽은 코드인 `EatArrowKeys` 오버라이드 10개(4510, 6151, 6743, 9160, 9518, 10545,
  12095, 12803, 13362, 14200 — `GTK4DEBUGKEYPRESS` 안에서만 호출됨)가 바로 이 정책의 자리이므로 이를 살려 쓴다.
- **C1(Tab 선점)** — LCL 이 Tab 을 CN_KEYDOWN(OnKeyDown)과 LM_KEYDOWN 으로 받고 `DoTabKey`(LM 경로, §5)
  가 `PerformTab` 으로 이동한 뒤 키를 지우는 것이 계약. gtk4 는 GtkEventKey 가
  선점하고 GTK 창 move-focus 도 살아 있어 이중 이동 가능성이 있다. 실측(§4 Tab 행) 에서 gtk4 의 다음 포커스는
  qt5/gtk2 와 대체로 같았으나(edit→spin 등) KD 부재는 확실. 2차 범위. 단, pre-dispatch 가 편집 계열의 Tab 을
  받게 되면 기존 3846 분기가 그대로 실행되므로 동작은 변하지 않는다(회귀 없음 확인 항목).

## 7. 단계별 작업 (각 단계 = rollback 커밋 1개 이상, 세 빌드 + 행렬 게이트)

**게이트(모든 단계 공통)**: `make lcl LCL_PLATFORM=gtk4` / `make bigide LCL_PLATFORM=gtk4` / `make lcl
LCL_PLATFORM=gtk2` 통과 → 하네스 `runall.sh` + `analyze.py` 로 **단계별 기대 시그니처표**와 대조(단순 `!!` 개수
비교가 아니라 키별 기대 이벤트열을 명시; 프로세스가 정상 종료해 FINAL 이 있어야 유효) → codex(gpt-6-astra,
read-only) 교차검토 → 지적 전건 코드 대조 재검증 → 문서 갱신 → 커밋. **하네스 보강(교차검토 반영, Phase 1
전에)**: 키마다 대상 컨트롤에 포커스를 되돌리는 "격리 모드"(내비게이션 검증은 별도 순차 모드), 소비된 키의
release 도착 여부, `Key:=0`(eatlist)·폼 KeyPreview 거부, 자동 반복(xdotool `key --repeat`), Shift+Tab, 스핀
마우스 클릭 후 포커스, 종료 코드/FINAL 검사. **프리에딧 활성 중 Return/Escape/화살표**와 **fcitx 재전송 이중
발화**는 Xvfb 에 fcitx 가 없어 사용자 실기(fcitx5 한글) 로만 검증 가능 — Phase 2 의 CAPTURE 소비를 확정하기
전에 반드시 통과해야 한다.

- **Phase 0 — 별건 선행(스핀 크래시)**: D1 재귀 차단 — getter `TGtk4SpinEdit.GetValue`(6683) 가
  `gtk_spin_button_update` 를 부르고 그것이 텍스트를 재기록해 `changed` → `CM_TEXTCHANGED` → `TextChanged` →
  `Value` 로 되돌아온다. 후보: `Gtk4EntryChanged` 재진입 가드 또는 getter 에서 `update` 제거(값 동기화는 activate/
  focus-out 시점으로). + D2 초기값. 스핀 행렬이 크래시 없이 끝나야 이후 단계의 스핀 검증이
  가능하다. 원인 분석은 별도 소절로 기록. (사용자가 D1/D2 를 별도 세션으로 미루면 스핀 검증만 보류.)
- **Phase 1 — 기반**: (1a) `GtkEventKey` 를 3상태 계약으로 분리하는 **순수 추출 커밋**(기대: 행렬 완전 동일),
  (1b) 변환 커밋: `KP_Enter/ISO_Enter` 문자열 `#13` + `ISO_Enter→VK_RETURN` 매핑(C3), Ctrl+문자 → #1..#26(C4),
  이벤트 포인터 중복 억제 필드/헬퍼(사용처 없음). 기대(1b): 전 위젯 KP_Enter 행에 KP #13 추가(memo 포함 —
  memo 코드는 손대지 않지만 공용 변환의 영향), 전 위젯 ctrl+a 행의 KP 가 #97→#1.
- **Phase 2 — TEdit 만**(스핀은 옵트인 게이트로 제외): `Gtk4EntryDelegateKeyPressCB/ReleaseCB` 에 pre-dispatch
  (press: KeyDown 부 + 비문자 키 문자 블록; release: CN/LM_KEYUP) 추가, 프리에딧 가드, Tab 제외, BUBBLE 중복 억제,
  Up/Down 소비. 기대(edit 행): Return/KP_Enter → KD+KP#13+KU+ED+**DEF**; Left/Right/Home/End/Delete/Insert/
  BackSpace → KD(+KP #8) 추가; Ctrl+A → KD 65[ssCtrl]+KP #1; Down 후 포커스 유지; 문자 키 행은 **불변**(KD 없음,
  U8/KP/E 동일); Escape 행 불변; Tab 행 불변. tomboy-ng 스크립트(`test_entry_return/run.sh`) 기대 출력 일치.
  억제 검증: eatlist `13` 으로 Return 을 지우면 DEF 도 GtkText activate 도 없고 **KU 는 와야** 함(release 경로);
  `27` 로 Escape 지우면 CANCELBTN 없음. 사용자 실기: fcitx5 한글 조합 중 Return/Escape/BackSpace 가 IM 에 그대로
  가는지, 조합 없이 Return 이 한 번만 KD 로 오는지(재전송 이중 발화 없음).
- **Phase 3 — TSpinEdit**: `IsTextEntryLike` 술어 도입(wtEntry 를 스핀에 넣지 않음) + 옵트인 켜기 + 정책상 먹은
  Return 뒤 editable 조건부 `update` + 화살표는 FALSE(`change-value`). 기대: edit 와 같은 개선, Up/Down 에
  KD+E(값 변경), 중복 IM 컨텍스트 소멸(코드 확인), 마우스 클릭 포커스 경로(1541) 무회귀.
- **Phase 4 — 편집 TComboBox**: 콤보 delegate 기록기에 동일 적용. 드롭다운 트랜잭션(`7bde741`) 의 Return/Esc
  확정·취소 경로와 충돌 여부를 먼저 코드로 확인(팝오버 열림 중 Return 은 팝오버 리스트가 받으므로 delegate
  CAPTURE 와 무관해야 함 — 실측으로 확인).
- **Phase 5 — 문서·패키징**: `LCL_GTK4_DEV.md` §8, HANDOFF, TODO.md(2차 범위 항목 이관), 메모리
  `gtk4-key-input-architecture` 갱신. deb `4.4+dfsg-5` 재빌드(패치 갱신 절차 §0c) 및 `.o` 디스어셈블로 반영 확인.
  공개 스냅샷 동기화·push 는 사용자 요청 시.
- **2차(사용자 결정, §10)**: Phase 6 리스트/드롭다운 pre-dispatch(space, Return), Phase 7 IM 컨텍스트 분리(§6.3),
  Phase 8 IsArrowKey/Tab 정책(§6.4), D3 memo OnChange, D4 콤보 항목 이동.

## 8. 위험과 금지 사항

- IM 경로(delegate insert-text, preedit deferral `e31efe9`/`7c6a8a9`) 는 **한 줄도 바꾸지 않는다**. pre-dispatch
  는 기록기 뒤에 추가되고 문자 키에는 아무것도 하지 않는다.
- `Gtk4DesignKeyPressedCB` 순서 불변(창 CAPTURE 가 가장 바깥). 폼 컨트롤러 이관 금지(hang 전례).
- 중복 억제는 **이벤트 포인터 동일성**으로만 한다. keyval+시간 추정 금지(자동 반복과 충돌).
- `FKeysToEat` 의미(Return/Tab/Escape 소유) 를 편집 계열에서 되살리는 것이므로, GtkText `activate` 에 의존하던
  동작이 있는지 확인: 코드에 `activate` 연결이 없음(§2)을 확인했고, `activates-default` 도 쓰지 않음.
- 메모(`wtMemo`) 는 어떤 단계에서도 건드리지 않는다(검증된 구조).
- 각 단계는 독립 커밋이며, 행렬 게이트 실패 시 그 단계만 되돌린다.

## 9. codex 교차검토 판정표 (gpt-6-astra) — §9 는 검토 후 채움

회신 원문: `lazarus/example_gtk4_keymatrix_validation/baseline_2026-09-11/codex_plan_review_gpt-6-astra.md`(27KB, 18항목). 아래는 주장별 판정(검증은 모두 소스 열람).

| # | codex 주장 | 검증 | 판정 |
|---|---|---|---|
| 1 | delegate CAPTURE 는 GtkText TARGET IM/바인딩보다 먼저 돈다 | `gtkmain.c:1867`, `gtkwidget.c:4753`, `gtktext.c:1943` 확인 | ✅ 사실(계획 유지) |
| 2 | CAPTURE 에서 press 를 TRUE 로 소비하면 그 release 는 delegate 에서 자동 handled 로 끝나 BUBBLE 의 KeyUp 이 사라진다 | `gtkeventcontrollerkey.c:120-140`: `pressed_keys` 등록 → release 시 lookup 으로 handled 반환, `key-released` 는 void | ✅ **채택** — release 도 CAPTURE 에서 CN/LM_KEYUP 전달(§6.1), 초안의 "release 는 BUBBLE 유지" 후퇴안 폐기 |
| 3 | 이벤트 포인터 동일성은 한 전파 안에서만 보장; 저장 수명 규칙 필요; fcitx 는 같은 이벤트를 재큐잉할 수 있음 | `gtkmain.c:1899/1931`, `gtkeventcontroller.c:365/595`, `gdkdisplay.c:484` 확인; fcitx 소스는 저장소에 없어 미검증 | ⚖️ 부분채택 — 수명 규칙과 CAPTURE 측 재전송 검사 추가, fcitx 는 실기 게이트 |
| 4 | 현행 CN 분기는 entry/memo 에서 처리됐어도 `exit(False)` 라 그대로 추출하면 `Key:=0` 억제가 안 된다 | `gtk4widgets.pas:3896-3905` 확인 | ✅ 채택 — 소비 판정을 "CN 처리/지움 → 소비" 로 별도 정의 |
| 5 | Tab 조기 종료를 delegate 에서 부르면 `is_focus` 가 TRUE 가 되어 LCL `SelectNext` + GTK move-focus 이중 이동 | `gtkwidget.c:5336-5346`(is_focus = 루트 포커스와 동일), `gtk4widgets.pas:3846-3851`, `gtkwindow.c:1255` | ✅ 채택 — Tab 을 pre-dispatch 에서 제외, C1 은 2차 |
| 6 | 조합(프리에딧) 중 Return/Escape 를 CAPTURE 에서 소비하면 IM 이 못 받는다 | `gtktext.c:3226-3230`, `gtkimcontextsimple.c:881-885`; fcitx-hangul 동작은 미검증 | ✅ 채택 — 프리에딧 가드(`FPreeditText<>''` 동안 pre-dispatch 중지) |
| 7 | 백엔드는 GtkEntry/GtkText activate·activates-default 에 의존하지 않음; 스핀은 editable 조건·LCL 거부 구분 필요 | `gtkspinbutton.c:1030, 1485-1493`, 백엔드 grep(8468, 12551 뿐) | ✅ 채택(스핀 update 조건 명시) |
| 8 | 스핀에 `wtEntry` 를 넣으면 1541-1546 의 `gtk_entry_grab_focus_without_selecting(PGtkEntry(GtkSpinButton))` 이 잘못된 호출이 됨 | `gtk4widgets.pas:1533-1548` 확인, `gtkentry.c:1911` `GTK_IS_ENTRY` | ✅ 채택 — 별도 술어 `IsTextEntryLike` 로 대체 |
| 9 | 팝오버 격리는 맞지만 "Escape 도 ListActivate 로 확정" 은 틀림(Escape 는 취소) | `gtk4widgets.pas:12000, 12555, 11972`, `gtkpopover.c:781` | ✅ 채택(문구 정정) |
| 10 | 기록기/deferral 은 전달 추가로 깨지지 않음; 단 콤보 insert 훅은 OnKeyPress 를 만들지 않음 | `gtk4widgets.pas:6183, 6195, 6328, 12270` | ✅ 사실(콤보 문구 정정) |
| 11 | GtkEventKey 분리는 Boolean 하나로는 보존 불가, 결합점 목록 | 3846-4043 전 결합점 대조 | ✅ 채택 — 3상태 계약 + 순수 추출/변환 커밋 분리 |
| 12 | 편집 컨트롤 DLGC_WANTARROWS 주장은 틀림(darwin 만), qt5 는 LM 화살표 생략 | 이미 자체 검증으로 정정(§5) | ✅ 사실(정정 완료) |
| 13 | GtkIMContextSimple 은 프리에딧 없이도 space/문자를 commit 하고 TRUE | `gtkimcontextsimple.c:729-737` | ✅ 사실 |
| 14 | gtk2 는 IM 필터를 CN_KEYDOWN 보다 먼저 돌리고 결과를 무시; "필터 결과 그대로 반환" 은 체크박스 space 를 여전히 막음 | `gtk2proc.inc:2199-2212, 2305-2308, 2368` | ✅ 채택 — §6.3 정정(반환값은 LCL 소비 여부, 프리에딧 예외) |
| 15 | Ctrl+A KeyPress #1 은 변환 추가 없이는 안 나옴; ISO_Enter 는 VK 매핑도 없음 | `gtk4widgets.pas:1886`, `gtk4procs.pas:666-672`, `gtk2proc.inc:1918-1927` | ✅ 채택 — C4 신설, ISO_Enter 매핑 추가 |
| 16 | gtk2/qt5 가 Return/Tab/Escape 를 "무조건 우회" 한다는 서술은 과함 | `gtk2proc.inc:2159, 2553`, `qtwidgets.pas:3572, 3665` | ⚖️ 부분채택 — §5 문구를 폴스루 규칙으로 정정, 정책은 유지 |
| 17 | Phase 2 가 스핀에 자동 적용됨(콜백 상속); GetValue 는 `update` 를 부름 | `gtk4widgets.pas:296, 6544, 6683` | ✅ 채택 — 옵트인 게이트, Phase 0 문구 정정 |
| 18 | 게이트가 `!!` 개수 비교라 부족; 포커스 이탈·크래시 로그를 기준선으로 쓰면 안 됨; Phase 1 변환이 memo 행도 바꿈 | 하네스 `run.sh:13`, `analyze.py:60`, 기준선 edit/spin 원본 | ✅ 채택 — 게이트 재정의(§7), 하네스 보강 항목, 기대 변화 명시 |

기각한 항목: 없음. 미검증으로 남긴 것: fcitx5-gtk 재전송 동작과 fcitx-hangul 의 Return 처리(저장소에 소스 없음 →
사용자 실기 게이트로 이관).

## 10. 사용자 결정 필요

1. 필수 범위(§0) 승인 여부: TEdit/TSpinEdit/편집 콤보 + KP_Enter 문자열 + 편집 계열 Up/Down 포커스 유지.
2. D1/D2(스핀 크래시·초기값) 를 이 시리즈의 Phase 0 로 넣을지, 별도 세션으로 뺄지.
3. 2차 범위 착수 여부와 순서: (a) 리스트 space / 드롭다운 Return, (b) 비텍스트 위젯 IM 분리(체크박스 space 토글
   포함, 한글 회귀 검증 필수), (c) 화살표·Tab 정책(트랙바·버튼 내비게이션), (d) memo OnChange, (e) 콤보 항목 이동.
4. ~~release 를 CAPTURE 로 옮길지~~ — 교차검토로 **필수**로 확정(§6.1, §9-2). 결정 불필요.
5. Phase 2 의 CAPTURE 소비를 확정하려면 fcitx5 한글 실기(조합 중 Return/Escape/BackSpace, 재전송 이중 발화)가
   필요하다. 이 실기를 누가 언제 하는지(사용자 실기 필수) 합의.
6. C4(Ctrl+문자 → 제어문자 KeyPress) 를 Phase 1 에 넣을지 — 전 위젯 공용 변환이라 기대 변화가 넓다.

## 11. 부록 — 재현·검증 도구

- 하네스: `lazarus/example_gtk4_keymatrix_validation/` (README 참조). 원본 행렬 `baseline_2026-09-11/matrix_full.txt`.
- tomboy-ng 재현: `test_entry_return/run.sh <tomboy-ng-gtk4-dbg>` (요청 문서 §6).
- codex CLI 교차검토 명령(MCP 서버가 이번 세션에 연결되지 않아 CLI 사용):
  `codex exec -m gpt-6-astra -s read-only -C /mnt/STORAGE16T/Workspace_STORAGE16T/LCL_GTK4 "<프롬프트>"`.


---

## 12. Phase 0 상세 설계 — TSpinEdit 재귀 크래시(D1)와 초기값(D2) (2026-09-11, 코딩 전)

### 12.1 실측으로 확정한 원인 (gdb, `keymatrix_gtk4 spin`)
- **D2**: LCL 기본값은 `DefMaxValue = 0`(`spin.pp:37`), `MinValue = 0`. LCL 코어는 "Max = Min 이면 제한 없음"
  (`GetLimitedValue`, `spinedit.inc`: `if FMaxValue > FMinValue then` 클램프, 주석 "Delphi does not constrain when
  MinValue = MaxValue"). gtk2 도 `MaxValue > MinValue` 일 때만 범위를 걸고 아니면 `-MaxDouble..MaxDouble`
  (`gtk2wsspin.pp:206-213`). **gtk4 는 두 곳에서 `>=`** 를 써서(`gtk4wsspin.pp:143`(SetReadOnly), `:196`(UpdateControl))
  기본값에서 `SetRange(0,0)` 이 걸리고 `set_value(5)` 가 0 으로 클램프된다. gdb: `SetRange(0,0)` 두 번 → `SetValue(5)`
  직후 adjustment 0.
- **D1**: `TGtk4SpinEdit.GetValue`(`gtk4widgets.pas:6683-6692`) 가 `gtk_spin_button_update` 를 호출한다. `update`
  는 텍스트를 파싱해 `set_value` 하고 `default_output` 으로 **텍스트를 다시 쓴다**(`gtkspinbutton.c` update/
  set_value/default_output). 사용자가 텍스트를 지워 "" 가 되면 `changed` → `CM_TEXTCHANGED` → LCL
  `TCustomFloatSpinEdit.TextChanged` → `Value` → `GetValue` → `update` → "" 파싱 실패 → val=0 → `set_text("0")` →
  `changed` → … 로 무한 재귀(gdb 프레임 4,834개, 118 사이클, 각 단계에서 텍스트 "" 관측). gtk2 의 `GetValue` 는
  **엔트리 텍스트를 파싱만** 하고(`gtk2wsspin.pp:95-113`, `StrToValue`), `update` 는 `SetReadOnly` 안에서
  `LockOnChange` 로 감싸 호출한다(`:172-176`, `UpdateControl` 이 234 에서 호출).
- **D5(교차검토로 발견)**: `TGtk4SpinEdit.CreateWidget`(6730-6741) 이 `LCLObject` 를 `TCustomSpinEdit` 로 캐스팅해
  **정수 getter**(`spinedit.inc:257-270`, `round(FIncrement)` 등)로 `new_with_range(Min, Max, Increment)` 를 부른다.
  `TFloatSpinEdit` 의 Increment 0.25 → 0 → GTK 가 `g_return_val_if_fail(step != 0.0, NULL)` 로 **NULL 위젯**을
  돌려주고, `MinValue > MaxValue`(LCL 은 "무제한") 도 `min <= max` 단언 실패로 NULL 이다(`gtkspinbutton.c` 생성자).
  소수 경계값도 반올림된다.

### 12.2 변경 (최소, gtk2 정렬; 교차검토 §9 반영)
1. `gtk4wsspin.pp` `UpdateControl`(196)과 `SetReadOnly`(143): `>=` → `>`(LCL `GetLimitedValue`·gtk2 와 동일).
2. `TGtk4SpinEdit.CreateWidget`(6730-6741): `TCustomFloatSpinEdit` 로 캐스팅해 **double** 경계/증분을 읽고, GTK
   생성자 전제조건을 만족하는 초기값을 준다 — `Max > Min` 이면 `(Min, Max)`, 아니면 `(-MaxDouble, MaxDouble)`;
   `Increment <= 0` 이면 step 1(`UpdateControl` 이 곧 실제 step 을 다시 설정). NULL 위젯 방지(D5).
3. `TGtk4WSCustomFloatSpinEdit.GetValue`(`gtk4wsspin.pp:92-99`): gtk2 와 같이 **엔트리 텍스트를 읽어 '.'/',' 를
   `DefaultFormatSettings.DecimalSeparator` 로 치환한 뒤 `ACustomFloatSpinEdit.StrToValue`**(빈/무효 텍스트는
   LCL 캐시 `FValue` 로 폴백 후 범위 제한 — 기대값에 명시). 텍스트는 `TGtk4Entry.getText`(6452, GtkEditable
   get_text) 사용.
4. `TGtk4SpinEdit.GetValue`(6683): `update` 와 `ApplyPendingSelStart` 를 제거해 **순수 getter**(`get_value`) 로.
   호출처는 `gtk4wsspin.pp:98` 하나(→ 3번으로 대체)뿐. `gtk_spin_button_update` 호출은 저장소에 남지 않는다 —
   GTK 자체가 화살표 버튼 press(929)·focus-out(999)·change-value(1383/1460)·activate(1493) 에서 `update` 한다.
5. `UpdateControl`: 자릿수/step/범위를 바꾸기 **전에** `ACustomFloatSpinEdit.Value` 를 지역 변수로 읽어 둔다.
   자릿수 변경은 GTK 가 어저스트먼트 값으로 텍스트를 다시 써 `changed` 를 내므로(`gtkspinbutton.c:1910`),
   그 알림이 LCL `FValue` 를 덮어쓴 뒤에 읽으면 편집 중 값이 유실된다(교차검토 §9-8; 기존 코드도 같은 위험).
6. `Gtk4EntryChanged` 재진입 가드는 **넣지 않는다**(근본 원인 제거로 충분). `OnChange` 핸들러가 Value/범위를
   다시 쓰는 재진입은 LCL 공통 경로라 이번 범위 밖.
7. **알려진 동작(gtk2 와 동일, 변경 아님)**: 텍스트를 편집한 뒤 커밋(Return/focus-out/버튼) 전에 마우스 휠을
   굴리면 GTK 는 `update` 없이 어저스트먼트에 증분을 더한다(`gtkspinbutton.c:855-859`, `real_spin`). LCL 값은
   텍스트를 따르므로 휠 결과가 편집 값 기준이 아닐 수 있다. gtk2 도 같은 구조(getter 가 텍스트 파싱). 문서화.

### 12.3 검증 게이트 (교차검토 §9-11 반영)
- 하네스 `spin`/`fspin` 격리·순차 실행이 FINAL/EXIT 까지 정상 종료(크래시 없음), FINAL `spin=5`, `fspin=5.25`
  (qt5/gtk2 와 동일). `fspin` 은 **Increment 0.25, MinValue 10 > MaxValue 0(무제한)** 으로 만들어 D5 를 직접 친다.
- 키별 기대: Up/Down → `KD+E`(spin ±1, fspin ±0.25), Prior/Next → KD(+E), Delete/BackSpace 로 텍스트를 비워도
  크래시 없음(빈 텍스트의 FINAL = LCL 캐시값 폴백). Return 행은 Phase 3 전까지 현행(KU+ED 만) 유지.
- 추가 시나리오(하네스 명령 키): F5 = fspin DecimalPlaces 2↔3 토글(편집 후 자릿수 변경 시 값 보존), F6 = ReadOnly
  토글(잠금·해제 후 값·범위), 휠 = xdotool 로 fspin 위에서 button 4/5(편집 후 휠 — 문서화된 동작 확인). 로케일은
  현재 환경(`.`)만 실측하고 ',' 로케일은 gtk2 와 같은 치환 논리로 대체(실행 미검증으로 기록).
- 세 빌드 통과 → 커밋 "GTK4: TSpinEdit — pure GetValue (parse text like gtk2), Max=Min means unlimited, float construction".


### 12.4 Phase 0 결과 (2026-09-11 구현·검증 완료)
- 커밋: 작업 저장소 HEAD(`git log` 참조, "GTK4: TSpinEdit - pure GetValue ...").
- 게이트: gtk4 `spin`/`fspin` 격리·순차 모두 FINAL/EXIT 정상(크래시 0), `spin=5`, `fspin=5.25`(qt5/gtk2 동일).
  명령 키 시나리오: "12.5" 입력 → F5(자릿수 3) 후 12.500 유지 → F6 ReadOnly on/off 후 유지. 빈 텍스트 시 값은 캐시
  폴백(5). 세 빌드 통과. 수정 전후 gtk4 전 컨트롤 대조(`compare.py`): 순차 모드 변화는 edit/spin 행뿐(모두 크래시
  전 미측정 구간의 데이터 출현). 격리 모드의 Tab 목적지 변화는 fspin 삽입·재포커스 타이머 산물.
- **Phase 0 에서 드러나 Phase 3 로 넘긴 스핀 관찰**: ① Up/Down 이 값을 바꾸지 않음(`IsArrowKey → exit(True)`,
  C2) ② PageUp/PageDown·Tab(포커스 아웃)처럼 GTK 가 텍스트를 다시 쓰는 키에서 delegate insert-text 훅이 그 재기록을
  타이핑으로 오인해 OnKeyPress('1','5','0')를 만든다(`0ac8fcd` 의 키-유발 게이트가 keyval 무관) ③ 빈 텍스트에 Return/
  포커스 아웃 → GTK `update` 가 0 으로 확정(gtk2 도 동일한 GTK 동작, qt5 는 이전 값 유지) — 위젯셋 차이로 기록.


---

## 13. Phase 1a 상세 설계 — `GtkEventKey` 의 부분 실행(동작 불변) (2026-09-11, 코딩 전)

### 13.1 목표
pre-dispatch(Phase 2)가 "KeyDown 부분만" 또는 "KeyDown+문자 블록" 을 골라 실행할 수 있어야 한다. 현행
`TGtk4Widget.GtkEventKey(Sender, Event, AKeyPress): Boolean`(3778-4045)은 한 함수 안에서 (P) 전처리 → (K) Tab/
컨텍스트메뉴/CN_KEYDOWN/LM_KEYDOWN → (C) UTF8/CN_CHAR/LM_CHAR/memo 치환 기록 → (T) `FKeysToEat` 꼬리를 수행하며,
`False` 가 "계속 진행"과 "여기서 끝내되 GTK 는 계속" 두 뜻으로 쓰인다(교차검토 §9-11).

### 13.2 변경: 함수를 쪼개지 않고 **부분 선택 매개변수**를 추가한다
- `type TGtk4KeyPart = (kpKeyDown, kpChar); TGtk4KeyParts = set of TGtk4KeyPart;`
- `function GtkEventKey(Sender: PGtkWidget; Event: PGdkEvent; AKeyPress: Boolean; AParts: TGtk4KeyParts = [kpKeyDown, kpChar]): Boolean;`
  기본값이 현행과 같으므로 **기존 호출 3곳(1921, 1955, 1987) 은 무변경**이고 결과 값·부작용도 동일하다.
- 본문 구조(현행 코드를 블록째 옮기고 조건만 씌움):
  1. (P) 전처리는 항상 실행. 단 **자동 반복 상태 갱신**(`FLastKeyVal/FLastKeyPress`, 3830-3833)은 `kpKeyDown in
     AParts` 일 때만 — 같은 이벤트에 대해 KeyDown 부와 문자 부를 두 번 부르는 Phase 2 에서 두 번째 호출이 반복으로
     오인되지 않게 한다(기본 호출에서는 동일 동작).
  2. (K) 블록 전체를 `if kpKeyDown in AParts then begin … end` 로 감싼다. 내부의 모든 `exit`/`exit(True)`/
     `exit(False)` 는 **그대로 둔다** — 현행과 동일하게 함수 전체를 끝낸다(C 와 T 도 건너뜀). 즉 3상태는 별도
     열거형이 아니라 "블록 안의 exit = 중단, 블록 통과 = 계속" 으로 구현한다(계약: 중단 시 Result 가 곧 소비 여부).
  3. (C) 블록을 `if kpChar in AParts then begin … end` 로 감싼다. 내부 exit 도 그대로.
  4. (T) 꼬리 `if AKeyPress then Result := Msg.CharCode in FKeysToEat` 는 `kpKeyDown in AParts` 일 때만.
     문자 전용 호출에서는 꼬리를 건너뛰므로 반환값은 (C) 블록이 정한 값(UTF8/CN_CHAR 가 소비하면 True) 이다.
  5. **문자 전용 호출의 KeyData(교차검토 §9 Phase 1a-2 반영)**: `TCustomEdit.WMChar`/`TCustomComboBox.WMChar` 는
     `KeyDataToShiftState(Message.KeyData)` 로 Ctrl/Alt 를 판정하고(`customedit.inc:474`, `customcombobox.inc:512`),
     `MsgKeyDataToShiftState` 는 Alt 를 KeyData 에서만 얻는다(`lclintf.pas:198`). 현행 흐름에서 `CharMsg.KeyData` 는
     (K) 가 채운 `Msg.KeyData` 를 복사한다(3979). 따라서 `kpKeyDown ∉ AParts` 이고 `ACharCode <> VK_UNKNOWN` 이면 (P)
     직후에 (K) 와 같은 식으로 `Msg.CharCode := ACharCode; Msg.KeyData := (KeyValue shl 16) or (LCLModifiers shl 16)
     or $0001` 을 채운다. 기본 호출 경로에는 이 대입이 없으므로 현행과 동일하다(VK_UNKNOWN 키는 현행처럼 0 유지).
- `AEventString`(문자 블록 입력) 은 (P) 에서 채워지므로 문자 전용 호출도 그대로 쓴다.
- 결과: `AParts = [kpKeyDown, kpChar]` 이면 실행 경로·반환값·부작용이 현행과 **의미상 동일**하다(코드 이동 없이
  들여쓰기와 조건문만 추가; 시그니처가 바뀌므로 이진 호환 주장은 하지 않음). `[kpKeyDown]` 은 (P)(K)(T),
  `[kpChar]` 는 (P)(+KeyData)(C) 만. 선언은 `virtual; cdecl;` 을 유지한다(164). 호출처 3곳은 기본 인수 사용.

### 13.3 다루지 않는 것
- Tab 조기 종료(3846), `IsArrowKey`, entry/memo 의 CN `exit(False)` 의미(§9-4)는 **이번 커밋에서 바꾸지 않는다**.
  Phase 2 의 pre-dispatch 는 자신의 소비 판정을 위해 CN 처리 여부를 알아야 하므로, 그때 `out AConsumedByLCL:
  Boolean` 같은 관측 매개변수를 추가한다(별도 커밋, 별도 검토).
- 호출자 변경 없음. 바인딩 변경 없음.

### 13.4 게이트
- 세 빌드 통과. 하네스 gtk4 격리+순차 전 컨트롤 재측정 → `compare.py baseline_2026-09-11_post_phase0/…` 대비
  **변경 0 행**(격리 모드 Tab 목적지의 타이밍 산물만 허용, 순차 모드는 완전 동일). `example_gtk4_editmemo_validation`
  류 기존 검증 예제 중 키 관련 것이 있으면 12초 실행으로 무회귀 확인.
- 커밋 "GTK4: GtkEventKey - optional key-down / char parts (no behaviour change)".


---

## 14. Phase 1b 상세 설계 — KP_Enter / ISO_Enter 보정 (C3) (2026-09-11, 코딩 전)

### 14.1 근거
- `gdk_keyval_to_unicode(GDK_KEY_KP_Enter)` = 0, `ISO_Enter` = 0(§1-9). `Gtk4KeyPressedCB`(1886-1919)는 이 값으로
  `Event.key.string_` 을 만들므로 KP_Enter 는 문자 블록에 들어가지 못해 OnKeyPress(#13)·UTF8KeyPress 가 없다
  (행렬: 전 위젯 KP_Enter 행에 `KP #13` 부재, qt5/gtk2 는 있음).
- `GdkKeyToLCLKey`(`gtk4procs.pas:672`)는 `GDK_KEY_Return, GDK_KEY_KP_Enter, GDK_KEY_3270_Enter` 만 `VK_RETURN` 으로
  매핑하고 **`GDK_KEY_ISO_Enter`(0xFE34) 가 빠져** 있다 → ISO_Enter 는 VK_UNKNOWN 으로 CN/LM 을 건너뛴다.

### 14.2 변경 (2곳, 최소)
1. `gtk4procs.pas` `GdkKeyToLCLKey`: `GDK_KEY_ISO_Enter` 를 `VK_RETURN` 케이스에 추가(`LCLKeyToGdkKeyval` 역방향은
   `VK_RETURN → GDK_KEY_Return` 그대로).
2. `gtk4widgets.pas` `Gtk4KeyPressedCB`: `UChar := gdk_keyval_to_unicode(keyval)` 직후
   `if (UChar = 0) and ((keyval = GDK_KEY_KP_Enter) or (keyval = GDK_KEY_ISO_Enter)) then UChar := 13;`
   (FPC 의 set 생성자는 0..255 만 허용하므로 `in [...]` 은 쓸 수 없음 — 교차검토 지적) — 이후 기존 UTF-8 변환이
   `#13` 한 바이트를 만든다. `Gtk4KeyReleasedCB` 는 `string_ := ''` 이라 무변경.
- C4(Ctrl+문자 → #1..#26)는 이 커밋에 **넣지 않는다**(§10-6 사용자 결정 대기).

### 14.3 영향과 게이트
- 공용 경로라 모든 위젯의 KP_Enter 행이 Return 행과 같아진다(기대 변화). 다른 행은 무변화. **소비 의미도 Return 과
  같아진다**: 앱의 OnUTF8KeyPress/OnKeyPress 가 KP_Enter 를 비우면 이제 Return 처럼 소비·치환된다(교차검토 §9 1b-5, 6;
  지금까지는 문자열이 비어 문자 블록을 타지 않아 불가능했음 — 의도된 동등성). 핸들러가 없으면 메모 줄바꿈 등 네이티브
  동작 불변. qt5 는 KP_Enter 에 U8 "\r" + KP #13, gtk2 는 KP #13 만 보낸다(1b-7) — 목표는 qt5.
- ISO_Enter 는 하네스 기본 키 목록에 없으므로 별도 실행(`KEYS="ISO_Enter"`; Xvfb 키맵에 keysym 이 없으면 미검증으로
  기록).
- 게이트: 세 빌드; gtk4 격리+순차 재측정 후 `compare.py` 로 **KP_Enter 행 외 변화 0**(순차 모드 기준); KP_Enter 행의
  새 시그니처가 같은 컨트롤의 Return 행과 동일(python 검사).
- 커밋 "GTK4: treat KP_Enter/ISO_Enter like Return for the LCL char path".


---

## 15. Phase 2 상세 설계 v2 — TEdit delegate pre-dispatch (2026-09-11, 코딩 전; v1 은 codex 검토로 폐기)

v1 의 결함(codex gpt-6-astra 검토, 전건 소스 대조로 확인): ① 단일 keyval 슬롯 → `Return↓ F3↓ Return↑` 에서 Return 의
KeyUp 유실(GTK 는 keyval 별 `pressed_keys` 로 release 를 삼킴) ② 이벤트 포인터를 전파 뒤까지 보관 → 주소 재사용·
재진입 시 오억제 ③ `FKeyEventLCLHandled` 공유 필드는 재진입(DeliverMessage → ProcessMessages)에 안전하지 않음
④ 디자인 콜백은 `string_ := ''` 이라 공용 헬퍼가 문자열을 채우면 동작 변화 ⑤ Up/Down 무조건 소비는 Ctrl+Up/Down
(GtkScrolledWindow 스크롤 바인딩) 까지 먹음 ⑥ LCL 전달 뒤 필드 접근에 수명 검사 없음 ⑦ Escape 를 CAPTURE 에서 먹으면
GtkText 의 부수 처리(커서 깜박임 리셋, 선택 버블 닫기, 텍스트 핸들, 포인터 숨김, IM reset)가 생략됨.

### 15.1 커밋 2a — 키 이벤트 합성 헬퍼 추출 (동작 불변)
`procedure Gtk4BuildKeyEvent(keyval, keycode: guint; state: TGdkModifierType; APress, AWithText: Boolean;
out AEvent: TGdkEvent; var AUTF8Buf: array[0..6] of char)`. `Gtk4KeyPressedCB` 는 `(True, True)`, `Gtk4KeyReleasedCB` 는
`(False, False)`, `Gtk4DesignKeyPressedCB` 는 `(True, False)`(현행 `string_ := ''` 유지, 1990). 결과 필드는 현행과 동일.
게이트: 순차 행렬 변화 0.

### 15.2 커밋 2b-1 — `GtkEventKey` 관측 출력(동작 불변)
시그니처에 `AHandled: PBoolean = nil` 추가(기존 호출 3곳 무변경). nil 이 아니면 진입 시 `AHandled^ := False` 로 두고,
- CN 분기(현행 3928 부근): `DeliverMessage` 결과를 지역 변수에 받아 `(CNResult <> 0) or (Msg.CharCode = VK_UNKNOWN)`
  일 때 `AHandled^ := True` — **`IsArrowKey` 와 분리**해 판정(화살표 우회만으로는 True 가 되지 않음; LCL 이 화살표를
  지웠으면 True).
- 네이티브 LM 분기의 `CharCode = 0 → exit(True)`(3962) 와 그 외 분기의 `Result := Msg.CharCode = 0`(3972) 에서
  `AHandled^ := Msg.CharCode = 0`.
호출별 지역 변수에 쓰므로 재진입에 안전. 흐름·반환값 불변. 게이트: 순차 행렬 변화 0.

### 15.3 커밋 2b-2 — pre-dispatch (TGtk4Entry 만; 스핀은 `KeyPreDispatchEnabled = False` 오버라이드)

**상태(TGtk4Entry)**
- 미해결 press 목록 `FPreDispKeys: array of record Keycode, Keyval: guint; Time: guint32; Consumed: Boolean end`
  (물리 키 = **hardware keycode** 로 식별; 보통 0~2개).
- 전파-국소 중복 억제 마커 `FDedupEvent: PGdkEvent; FDedupTime: guint32; FDedupKeycode: guint; FDedupPress: Boolean`
  — "CAPTURE 에서 LCL 에 이미 전달했고 BUBBLE 까지 올라올 수 있는 마지막 이벤트". 포인터만이 아니라 **이벤트 시각
  (`gdk_event_get_time`)·keycode·종류** 를 함께 비교해 주소 재사용을 배제한다. BUBBLE 에서 일치 처리 후 nil 로.
  포인터는 역참조하지 않는다(비교 전용).

**대상 키 판정 `Gtk4EntryWantsPreDispatch(keyval, state): Boolean`**
- `UChar := gdk_keyval_to_unicode(keyval)`; 문자 키(`UChar >= 32, <> 127`, Ctrl/Alt 없음) → False(IM 경로, TODO 결정).
- 제외(현행 경로 유지, GtkText 가 소비하지 않아 오늘도 BUBBLE 에 도달하는 키): `VK_TAB`, **`VK_ESCAPE`**(⑦), 수정자 키
  (`VK_SHIFT/VK_CONTROL/VK_MENU/VK_LWIN/VK_RWIN/VK_CAPITAL/VK_NUMLOCK`), `VK_UNKNOWN`.
- 그 외 비문자 키(Return/KP_Enter/ISO_Enter, Left/Right/Home/End, Up/Down, PageUp/Down, Insert, Delete, BackSpace,
  F-키, Menu, Ctrl/Alt 조합 문자 등) → True. GtkText 가 소비하지 않는 키(Up/Down/PageUp/F-키…)가 포함돼도 BUBBLE
  중복 억제로 무해하고, 소비하는 키를 빠뜨리는 쪽이 손실이므로 **포함 우선**.

**press — `Gtk4EntryDelegateKeyPressCB`** (기존 기록 로직을 먼저 실행한 뒤)
1. `if not Entry.KeyPreDispatchEnabled then exit(False)`; `if Entry.FPreeditText <> '' then exit(False)`;
   `if not Gtk4EntryWantsPreDispatch(keyval, state) then exit(False)`.
2. `Ev := get_current_event; T := gdk_event_get_time(Ev)`. **재전송 방어**: `FPreDispKeys` 에 같은 keycode 와 같은 Time
   의 항목이 있으면 `exit(항목.Consumed)`(fcitx 가 같은 이벤트를 다시 큐잉한 경우; 자동 반복은 Time 이 다르므로 새 press).
3. 목록에 항목 추가/교체(keycode 기준, `Consumed := False` 로 선기록).
4. `Gtk4BuildKeyEvent(keyval, keycode, state, True, True, Event, Buf)`;
   `Consumed := Entry.GtkEventKey(delegate, @Event, True, [kpKeyDown, kpChar], @Handled)`.
5. **수명 검사**: `if not Gtk4IsLiveWidgetPointer(Entry) then exit(Consumed)`.
6. `Consumed := Consumed or Handled or ((VK in [VK_UP, VK_DOWN]) and (state * [GDK_CONTROL_MASK, GDK_MOD1_MASK] = []))`
   (⑤: Ctrl/Alt 조합 화살표는 통과 → GtkScrolledWindow 등 상위 바인딩 유지).
7. 목록 항목 갱신 `Consumed`; `if Consumed then begin Entry.FDelegateKeyPending := False; Entry.FPendingKeyText := '' end`
   (① 기록 정책: GtkText 가 이 키를 보지 않으므로 키-유발 삽입은 있을 수 없음 — 게이트를 닫는다).
8. `if not Consumed then 마커 := (Ev, T, keycode, press)`(**전달 뒤에** 기록 — 재진입한 내부 이벤트가 마커를 덮어써도
   바깥 이벤트가 전파를 이어갈 때는 자기 마커가 다시 서 있다). `Result := Consumed`.

**release — `Gtk4EntryDelegateKeyReleaseCB`** (기존 기록 초기화는 그대로)
1. `if not Entry.KeyPreDispatchEnabled then exit`. 목록에서 **keycode** 로 항목 검색; 없으면 exit(현행: BUBBLE 이 처리).
2. **항목을 먼저 제거**(⑥: 재진입한 새 press 가 목록을 바꿔도 안전), `Ev/T` 확보.
3. `Gtk4BuildKeyEvent(keyval, keycode, state, False, False, …)`; `Entry.GtkEventKey(delegate, @Event, False)`
   — release 의 keyval 로 VK 를 계산(press 와 다를 수 있음: Shift 먼저 뗀 경우 등; gtk2 도 release 이벤트의 값 사용).
4. 수명 검사 후 마커 := (Ev, T, keycode, release). GTK 가 (press 를 소비한 keyval 의) release 를 delegate 컨트롤러에서
   멈추면 BUBBLE 은 오지 않고, 멈추지 않으면(미소비, 또는 keyval 불일치) BUBBLE 이 마커로 건너뛴다.

**BUBBLE 중복 억제 — `Gtk4KeyPressedCB`/`Gtk4KeyReleasedCB`**: `Data is TGtk4Entry` 이고
`(get_current_event = FDedupEvent) and (gdk_event_get_time(ev) = FDedupTime) and (keycode = FDedupKeycode) and
(종류 일치)` 이면 마커를 지우고 `exit(False)`. 폼 컨트롤러는 `Gtk4FormKeyBelongsToChild` 가 이미 막는다.

**설계 CAPTURE 컨트롤러**: 창/컨테이너에 붙어 delegate 보다 먼저 돌며 디자인 모드에서 무조건 소비 → pre-dispatch 는
실행되지 않음(순서 불변).

### 15.4 기대 행렬(edit, Phase 1b 결과 대비; 격리·순차 공통)
- Return/KP_Enter: `fKD:13 KD:edit:13 U8:edit:#13 KP:edit:#13 fKU:13 KU:edit:13 ED:edit E:defbtn`(qt5 와 동일).
- Escape: **불변**(제외). Up: 불변(KD/KU). **Down: `fKD:40 KD:edit:40 fKU:40 KU:edit:40`** 로 포커스 유지.
- Left/Right/Home/End: `fKD KD fKU KU`(CN 만, LM 은 화살표 우회로 생략 — release 도 동일 경로라 KU 는 CN_KEYUP).
  Insert: `fKD KD:45 fKU KU`. Delete: `fKD KD:46 fKU KU`(문자 블록은 VK_INSERT..VK_DELETE 제외 조건으로 미진입 — gtk2 동일).
  BackSpace: `fKD KD:8 U8:#8 KP:#8 E fKU KU`. Ctrl+A: `fKD:17 KD:17 fKD:65 KD:65[ssCtrl] U8:"a" KP:#97 fKU… `(C4 미적용).
  F3/Tab/shift+Tab/문자(space, a)/Prior/Next: **불변**(Prior/Next 는 오늘도 BUBBLE 도달 → 이제 CAPTURE 전달+중복 억제로
  같은 시그니처).
- 다른 컨트롤·spin: 변화 0(순차). eatlist `13`: Return 행에 DEF 없음, 텍스트 불변(activate 미실행), **KU 있음**.
- 추가 시나리오(KEYS): `Return↓ F3↓ Return↑`(xdotool `keydown Return`, `key F3`, `keyup Return`) → Return KU 1회·DEF 1회;
  `REPEAT:Left` 3회 → KD 3회(KF_REPEAT), KU 1회; 편집 후 Ctrl+A → 네이티브 전체 선택 유지(FINAL 전 F7 로 SelLength).
- 사용자 실기(fcitx5): 조합 중 Return/BackSpace 가 IM 에 감, 조합 없이 Return KD 1회(재전송 이중 발화 없음).

### 15.5 커밋 순서·되돌리기
2a(헬퍼) → 2b-1(AHandled) → 2b-2(pre-dispatch). 각각 세 빌드 + 순차 행렬 게이트(2a/2b-1 은 변화 0). 2b-2 실패 시 2b-2 만 되돌림.


### 15.6 v3 보정 (codex 2차 검토 반영, 2026-09-11)
2차 검토(`baseline_2026-09-11/codex_phase2_v2_review_gpt-6-astra.md`)에서 사실로 확인된 결함과 보정:

- **(R2-2) GTK `pressed_keys` 잔류**: LCL 이 소비한 press 의 keyval(예: Ctrl+Shift+A 의 `A`)이 GTK 표에 남고,
  release 가 다른 keyval(`a`)로 오면 지워지지 않아 **나중의 무관한 `A` release** 를 GTK 가 삼킨다(그 키가 pre-dispatch
  제외 대상인 문자 키면 KeyUp 유실). 보정: `FStaleGtkKeyvals: array of guint` — 소비한 press 의 keyval 을 기록해 두고
  release 가 **다른 keyval** 로 도착해 짝이 안 맞으면 그 press keyval 을 잔류 집합에 넣는다. 이후 CAPTURE release 핸들러는
  (pre-dispatch 대상 여부와 무관하게) keyval 이 잔류 집합에 있으면 **LCL KeyUp 을 직접 전달**하고 집합에서 지운다
  (GTK 는 그 뒤 삼키지만 LCL 은 이미 받음). 포커스 이탈 시 미해결 소비 항목의 keyval 도 잔류 집합으로 옮긴다.
- **(R2-3) 포커스 상실**: GTK 는 합성 release 도, `pressed_keys` 정리도 하지 않는다(`gtkeventcontrollerkey.c:144`
  `handle_crossing`). delegate 포커스 이탈 컨트롤러(`Gtk4EntryDelegateFocusLeaveCB` 6310, 기존 `FDeferredText`
  조기 종료 **앞에서**) 에서 미해결 목록·마커·진행 중 표시를 **취소**(합성 KeyUp 은 보내지 않음 — Return 합성은 기본
  버튼을 오발할 수 있음)하고 소비 항목의 keyval 을 잔류 집합으로 옮긴다.
- **(R2-4) 타임스탬프로 재전송 판별 불가**: Wayland 자동 반복은 `keyboard_time` 을 재사용(`gdkdevice-wayland.c:2236`)
  하므로 (keycode, time) 동일 = 재전송이라는 가정은 틀렸다. 보정: **이벤트 참조를 소유**한다. 미해결 항목에
  `gdk_event_ref(Ev)` 로 참조를 잡고 항목 제거(release/교체/포커스 이탈) 시 `gdk_event_unref`. 참조를 잡고 있는 동안
  그 주소는 재사용될 수 없으므로 **같은 포인터 = 같은 이벤트 객체**(fcitx 재전송) 가 정확히 성립하고, 자동 반복(새
  객체)은 새 press 로 처리된다. 시각 비교는 쓰지 않는다.
- **(R2-5) 마커 유일성**: 마커도 참조를 소유한다(`FDedupEvent` 에 ref; BUBBLE 일치 시·다음 CAPTURE 이벤트 도착 시·
  포커스 이탈 시 unref). "포인터+시각+keycode" 튜플은 폐기하고 **포인터 동일성(소유 참조)+종류** 로 판정.
- **(R2-7) 재진입**: 항목에 세대 번호 `Gen` 을 두고, LCL 전달 뒤 **keycode 로 다시 찾아 Gen 이 같을 때만** 갱신한다.
  재전송 조기 종료(같은 이벤트 객체)도 기록 정리(`FDelegateKeyPending` 해제 등)를 수행한 뒤 저장된 결과를 돌려준다.
  진행 중(`InProgress`) 표시는 두되, 진행 중 항목에 대한 중첩 재전송은 저장된 잠정값(False) 을 돌려준다(문서화).
- **(R2-8) `GtkEventKey` 내부 수명 검사**: CN `DeliverMessage` 직후 `WidgetType` 을 읽기 전과 `LM_CONTEXTMENU` 미처리
  분기 뒤에 `CanSendLCLMessage` 검사가 없다(기존 결함, BUBBLE 경로도 동일). 2b-1 커밋에서 그 두 곳에 검사를 추가한다
  (파괴된 래퍼면 `exit(False)`; 살아 있는 경우 흐름 불변).
- **(R2-12) KF_REPEAT 단일 슬롯**은 기존 동작(BUBBLE 경로와 동일)으로 두고 기록만 한다(범위 밖).
- (R2-1, 6, 9, 10, 11) 은 설계 OK 로 확인: keycode 목록으로 `Return↓ F3↓ Return↑` 해결, 마커는 전달 뒤 설정이 맞음,
  Escape 제외 안전, 기본 LCL 핸들러의 이중 동작 없음(단축키는 CN 에서 판정돼 `AHandled` 로 소비), Return 의존
  deferral flush 없음.
- 바인딩: `gdk_event_get_time`/`gdk_event_get_event_type` 존재(`lazgdk4.pas:4634-4637`); **`gdk_event_ref/unref` 는 바인딩에
  없음**(grep 확인) → `lazgtk4_compat.pas` 에 `gdk4_event_ref(event: PGdkEvent): PGdkEvent` / `gdk4_event_unref(event)` 외부 선언
  추가(GDK 4.6.9 `gdk/gdkevents.c:855, 873`). X11 은 detectable autorepeat 를 켜므로(`gdkdisplay-x11.c:1591`) 자동 반복은
  release 없는 연속 press 로 온다.


### 15.7 v4 — 구조 단순화 (codex 3차 검토 반영, 2026-09-11; **이 판이 구현 기준**)
3차 검토(`baseline_2026-09-11/codex_phase2_v3_review_gpt-6-astra.md`)는 keycode 목록 방식이 "Ctrl+Shift+A 소비 →
Shift 뗌 → Ctrl+a 자동 반복 소비 → a 뗌" 처럼 GTK 표(keyval 기준)와 어긋나는 사례, release 재전송, 재진입 뒤 소비
확정 누락을 지적했다(모두 소스로 확인). 사례별 보정 대신 **두 구조로 단순화**한다.

**(S) GTK `pressed_keys` 의 거울 `FGtkPressedShadow: array of guint`(keyval 집합)** — GTK 는 "press 콜백이 TRUE 를
돌려준 keyval" 을 표에 넣고, release 콜백 뒤 그 keyval 을 찾으면 지우고 release 를 삼킨다
(`gtkeventcontrollerkey.c:120-140`). 우리 press 핸들러가 TRUE 를 돌려줄 때마다 keyval 을 집합에 넣고(중복 없음), 모든
release 콜백에서 keyval 이 집합에 있으면 지운다 → **그 release 는 GTK 가 삼킨다** 는 사실을 정확히 안다. 포커스 이탈로
비우지 않는다(GTK 표도 안 비워짐; 계속 거울). 이것으로 §15.6 의 잔류 집합·keycode 목록·포커스 취소가 모두 필요
없어진다: `Return↓ F3↓ Return↑`(Return ∈ S → 전달), Ctrl+Shift+A 소비 후 `a` 뗌(`a` ∉ S → GTK 안 삼킴 → BUBBLE 이 평소대로
KeyUp), 나중 `A` 뗌(`A` ∈ S → 우리가 전달, GTK 삼킴 → 정확히 1회), 자동 반복 소비(집합 멱등), 위 3차 사례(S = {A, a}
→ 각 release 1회씩) 모두 GTK 와 동일하게 맞는다.

**(H) 전달 이력 `FDeliveredEvents: array of record Ev: PGdkEvent(소유 참조); Consumed: Boolean end`, 최대 8개 FIFO** —
CAPTURE 에서 LCL 에 전달한 press/release 이벤트를 `gdk4_event_ref` 로 잡아 넣는다(가장 오래된 것부터 `gdk4_event_unref`).
참조를 잡고 있는 동안 주소 재사용이 불가능하므로 **포인터 동일성 = 같은 이벤트 객체**. 용도 두 가지:
- BUBBLE 중복 억제: `Gtk4KeyPressedCB/ReleasedCB` 진입 시 `Data is TGtk4Entry` 이고 현재 이벤트 ∈ H 면 `exit(False)`.
- 재전송(fcitx `gdk_display_put_event` 는 같은 객체를 ref 해 재큐잉, `gdkdisplay.c:490`) 방어: CAPTURE press/release 진입
  시 현재 이벤트 ∈ H 면 전달하지 않고 press 는 저장된 `Consumed` 를, release 는 아무것도 하지 않고 반환. 마커 "교체"
  개념이 없으므로 3차 지적(미소비 재전송이 BUBBLE 에 재전달)도 해소된다. 8개를 넘는 뒤늦은 재전송은 실질적으로 불가
  (문서화). 래퍼 소멸 시(`DetachEvents` 오버라이드 또는 소멸자) 전부 unref.

**press 핸들러(`Gtk4EntryDelegateKeyPressCB`)** — 기존 기록 로직 실행 후: 활성화/프리에딧/대상 키/Tab·Escape·수정자
제외 판정(§15.3 그대로) → `Ev := get_current_event`; `Ev ∈ H` 면 `exit(H[Ev].Consumed)` → `Gtk4BuildKeyEvent(…True, True…)`
→ `Consumed := GtkEventKey(delegate, @Event, True, [kpKeyDown, kpChar], @Handled)` → **수명 검사**(`Gtk4IsLiveWidgetPointer`)
→ `Consumed := Consumed or Handled or (VK ∈ {Up, Down} and no Ctrl/Alt)` → H 에 추가(`Consumed`) → `if Consumed then`
S 에 keyval 추가, `FDelegateKeyPending := False; FPendingKeyText := ''` → `Result := Consumed`. 재진입으로 내부 이벤트가
먼저 H 에 들어가도 바깥 이벤트는 자기 포인터로 추가되므로 마커 덮어쓰기 문제가 없다.

**release 핸들러(`Gtk4EntryDelegateKeyReleaseCB`)** — 기존 기록 초기화 후: 활성화 확인 → `Ev ∈ H` 면 exit(재전송) →
keyval ∈ S 면 S 에서 **먼저 제거**하고 `GtkEventKey(delegate, @Event(release, 문자열 없음), False)` 전달 → 수명 검사 →
H 에 추가. keyval ∉ S 면 아무것도 하지 않는다(현행: BUBBLE 이 처리; GtkText/IM 이 release 를 삼키면 오늘도 오지 않음).

**AHandled(2b-1)** — 3차 검토 #4 대로: `CNResult := DeliverMessage(Msg, True); if AHandled<>nil then AHandled^ :=
(CNResult <> 0) or (Msg.CharCode = VK_UNKNOWN); if not CanSendLCLMessage then Exit(False);` 뒤에 기존 분기(`IsArrowKey`
포함) 유지. LM 분기의 `CharCode = 0` 지점 두 곳도 `AHandled^ := True`. `LM_CONTEXTMENU` 미처리 뒤에도 수명 검사 추가.

**기타** — `KeyPreDispatchEnabled` 가상 메서드(스핀 False), Up/Down 소비는 Ctrl/Alt 없을 때만, Escape/Tab/수정자 제외,
프리에딧 가드, 소비 시 pending 해제 — §15.3 과 동일. 게이트는 §15.4(+`Return↓ F3↓ Return↑`, `REPEAT:Left`, 편집 후
Ctrl+A). fcitx 실기는 사용자.


### 15.8 v4 최종 보정 (codex 4차 검토 반영, 2026-09-11) — **구현 기준은 §15.7 + 이 절**
4차 검토(`baseline_2026-09-11/codex_phase2_v4_review_gpt-6-astra.md`)의 채택 항목(모두 GTK 소스·현행 코드로 확인):
1. **재전송 조기 종료도 거울(S) 갱신을 한다.** GTK 는 우리 콜백 반환값에 따라 항상 표를 바꾸므로(`gtkeventcontrollerkey.c:120-133`)
   재전송 press 가 저장된 TRUE 를 돌려주면 S 에도 keyval 을 넣고, 재전송 release 도 S 에서 지운다. 구현: press 의 모든
   TRUE 반환은 단일 마무리 루틴(`S 추가 + pending 해제`)을 거치고, release 는 **모든 종료 경로에서** S 제거를 수행한다.
   H 검사는 프리에딧 가드보다 **먼저**(이미 전달된 이벤트는 가드와 무관하게 저장 결과를 돌려준다).
2. **S 제거는 콜백 종료 시점에**(GTK 와 같은 경계). 진입 시 `WasInS := keyval ∈ S` 로 전달 여부를 정하고, 전달 뒤 종료
   직전에 제거한다. 중첩 dispatch 가 있어도 GTK 표와 경계마다 일치한다.
3. **H 항목은 전달 전에 등록**(`InProgress := True`, 잠정 `Consumed := False`), 진행 중 항목은 퇴출하지 않는다(용량 16, 퇴출은
   완료 항목 중 가장 오래된 것). 전달 뒤 **포인터로 다시 찾아** 결과를 기록하고 `InProgress := False`. 잠정값(False)을
   돌려받는 중첩 재전송은 문서화된 한계.
4. **수명 검사 전에 결과 합산**: `Consumed := Result or Handled or (UpDown and no Ctrl/Alt)` 를 지역 변수로 먼저 계산한 뒤
   `Gtk4IsLiveWidgetPointer` 검사, 살아 있을 때만 S/H/pending 필드를 만진다. 죽었으면 `exit(Consumed)`.
5. **현재 이벤트 포인터는 전달 전에 확보**해 두고 전달 뒤 다시 조회하지 않는다(`priv->event` 는 중첩 시 덮어쓰고 지움,
   `gtkeventcontroller.c:365`).
6. **해제**: delegate 기록기 컨트롤러 핸들을 `FDelegateKeyCtl` 에 보관하고 `TGtk4Entry.DetachEvents` 오버라이드에서
   `g_signal_handlers_disconnect_matched(컨트롤러, G_SIGNAL_MATCH_DATA, …, Self)` 후 H 의 이벤트를 모두 unref, S 를 비운다
   (기본 `DetachEvents` 는 `FIMContext` 만, `DestroyWidget` 은 `FWidget` 시그널만 끊음 — 4881/4602). 뒤늦게 언ref 하는
   것은 안전(이벤트가 surface/device 를 소유, `gdkevents.c:139, 413`).
7. 팝업 surface 의 키 이벤트는 GTK 가 재작성해 다른 객체가 되지만(`gtkmain.c:1053`) 엔트리는 toplevel 안에 있어 해당 없음.
   H 용량 16 은 "제한된 재전송 캐시"이며 정합성 보장이 아님(문서화).
- codex 는 이 보정으로 S+H 접근을 "구현 가능" 으로 판정. 구현 후 diff 에 대해 codex 코드 검토를 한 번 더 받고 전건 대조한다.


### 15.9 Phase 2 결과 (2026-09-11 구현·검증 완료)
- 커밋: 2a `11a7655`(헬퍼 추출), 2b-1 `4d2d136`(AHandled·수명 검사), 2b-2 = 작업 저장소 HEAD("GTK4: deliver non-text
  keys of TEdit to the LCL before the inner GtkText"). codex 코드 검토 1건(컨트롤러 소유 참조 누락) 채택·반영.
- 게이트: edit 격리 행이 qt5 와 일치 — Return/KP_Enter `fKD KD U8 KP#13 fKU KU ED DEF`, Escape 불변, Up/Down 포커스 유지,
  Left/Right/Home/End/Prior/Next/Insert/Delete/BackSpace/F3 에 KD 추가. 남은 차이는 예고대로 Delete 의 KP#127(qt5 만),
  문자 키 KD 없음(TODO 결정), Ctrl+A 의 KP #97(C4 미적용), Tab(제외). eatlist 13: DEF 없음·텍스트 불변·KU 있음; eatlist 27:
  CAN 없음; `Return↓ F3↓ Return↑`: Return KU 도착(qt5 동일); 반복 Left: qt5 동일. 다른 컨트롤·spin: 순차 변화 0.
- 세 빌드 통과. 기준선 `baseline_2026-09-11_post_phase2/`.
- 미검증(사용자 실기 필요): fcitx5 한글 조합 중 Return/BackSpace 가 IM 에 가는지, 조합 없이 Return 이 한 번만 KD 인지(재전송);
  tomboy-ng `test_entry_return/run.sh` 실제 실행.
