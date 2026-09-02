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
