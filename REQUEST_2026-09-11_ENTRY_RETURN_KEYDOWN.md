# 수정 요청: GTK4 TEdit 에서 `Return` 키의 `OnKeyDown` 이 전달되지 않음

작성일: 2026-09-11
요청 출처: tomboy-ng `gtk4-build-editor-fallback` 브랜치 (`0.42c+onion3` 패키지) 의 노트 내 검색창 동작 분석
대상 트리: `lazarus/` (`a90e6d2`, `lcl/interfaces/gtk4/gtk4widgets.pas` 는 `49195ea` 이후 변경 없음), 설치본 `lcl-gtk4 4.4+dfsg-4` 와 동일
관련 기존 결정: `TODO.md` "이 포트에서 결정된 비작업 항목" — 일반 **문자 키** 의 `OnKeyDown` 미전달은 작업하지 않기로 함(2026-09-02).
**이 요청은 문자 키가 아니라 `Return`(및 GtkText 가 소비하는 편집 키) 에 한정한다.** IM 경로는 건드리지 않는 수정을 요청한다.

---

## 1. 증상

tomboy-ng 노트 창에서 `Ctrl+F` 로 검색 패널을 열고 검색어를 입력한 뒤 `Enter` 를 누르면
다음 일치 위치로 이동해야 한다(`TEditBoxForm.EditFindKeyDown` 이 `VK_RETURN` 을 받아 `SpeedRightClick` 호출).

| 위젯셋 | 검색어 입력 시 첫 일치로 이동 | `Enter` 로 다음 일치 | `F3` 로 다음 일치 | 화살표 버튼 클릭 |
| --- | --- | --- | --- | --- |
| Qt5 (`tomboy-ng-qt5`) | 정상 | **정상** (40행 ↔ 200행 번갈아 이동) | 정상 | 정상 |
| GTK4 (`tomboy-ng-gtk4-dbg`) | 정상 | **무반응** (세 번 눌러도 화면 동일) | 정상 | 정상 |

스크롤·강조 그리기 자체는 GTK4 에서도 정상이었다(cairo, GL 렌더러 모두). 문제는 키 전달이다.

## 2. 증거

gdb 로 `EditFindKeyDown`, `SpeedRightClick`, `EditFindChange` 에 브레이크포인트를 걸고
`z e b r a`, `Return`, `KP_Enter`, `F3` 를 xdotool 로 보냈다.

```
### EditFindChange     × 7   (문자 입력마다 OnChange 는 정상)
### EditFindKeyDown    × 0   (문자, Return, KP_Enter, F3 모두 한 번도 호출되지 않음)
### SpeedRightClick    × 0
```

- `EditFindKeyDown` 은 문자 키, `Return`, `KP_Enter` 에 호출되지 않는다.
- `F3` 는 동작한다. GtkText 가 소비하지 않는 키라서 바깥 GtkEntry 의 bubble 컨트롤러까지 올라와
  `EditFindKeyDown(114)` 로 정상 전달된다(메뉴 단축키 경로가 아니다 — 수정 후 추적에서
  `MenuFindNextClick` 은 호출되지 않았다).
- `Return` 은 그 bubble 컨트롤러까지 올라오지 않는다. GtkText 의 `activate` 키 바인딩이 먼저 소비한다.

(정정: 최초 추적 스크립트가 gdb Pascal 모드에서 `*(unsigned short*)$rdx` 식 오류로 첫 KeyDown 히트 시
종료되는 바람에 "F3 도 OnKeyDown 미전달"로 잘못 읽혔다. `test_entry_return/run.sh` 는 `dprintf` 와
Pascal 변수 `Key` 를 쓰도록 고쳤다.)

재현 스크립트: `test_entry_return/run.sh <tomboy-ng-gtk4-dbg 경로>` (Xvfb + xdotool + gdb, 아래 §6).

## 3. 원인 (코드 위치는 `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas`)

1. **LCL 키 컨트롤러가 bubble 단계로 바깥 GtkEntry 에 붙어 있다.**
   `TGtk4Widget.InitializeWidget` (약 4722–4740): `gtk4_event_controller_key_new` 후 propagation phase 를
   지정하지 않고(`GTK_PHASE_BUBBLE` 기본) `GetContainerWidget` 에 추가한다. `wtEntry` 는 IM 컨텍스트를
   붙이지 않는다(GtkEntry 가 자체 IM 을 가짐).
2. **실제 키는 안쪽 GtkText(delegate)가 받는다.** GtkEntry 는 GtkText 를 감싸는 컨테이너이고 포커스는
   GtkText 에 있다. GtkText 의 shortcut controller 가 `Return`/`KP_Enter` 를 `activate` 바인딩으로
   처리하고 이벤트를 claim 하므로 바깥 GtkEntry 의 bubble 컨트롤러(1번)까지 올라오지 않는다.
   문자 키는 GtkText 의 IM 컨텍스트가 소비한다(TODO.md 의 기존 항목).
3. **GtkText 에 붙어 있는 capture 컨트롤러는 "기록 전용"이다.**
   `TGtk4Entry.InitializeWidget` (6501–6550) 이 delegate 에 `GTK_PHASE_CAPTURE` 키 컨트롤러를 붙이지만,
   콜백 `Gtk4EntryDelegateKeyPressCB` (6173–6193) 는 `FDelegateKeyPending`/`FPendingKeyText` 만 기록하고
   LCL 로 아무 메시지도 보내지 않는다(`Result := False; { record only }`).
4. 결과: `TGtk4Widget.GtkEventKey` (3778–) 의 `CN_KEYDOWN`/`LM_KEYDOWN` 전달 경로가 TEdit 의
   `Return` 에 대해 한 번도 실행되지 않는다. `wtEntry` 분기(3922–3937)는 LCL 이 `CharCode := 0` 으로
   지우면 `True` 를 반환해 GTK 기본 처리를 막도록 이미 설계돼 있지만, 그 코드에 도달하지 못한다.

참고로 `TGtk4Widget` 생성자의 `FKeysToEat := [VK_TAB, VK_RETURN, VK_ESCAPE]` (4596) 은 KeyPress(문자)
단계에서만 쓰이므로 이 문제와 직접 관계는 없다.

## 4. 영향 범위

- LCL 일반: GTK4 에서 `TEdit`(및 delegate 를 쓰는 `TComboBox` 편집부 — `Gtk4ComboDelegateKeyReleaseCB` 12245 부근,
  같은 구조이므로 **확인 필요**) 의 `OnKeyDown` 에 `VK_RETURN`/`VK_ESCAPE` 등 GtkText 가 소비하는 키가 오지 않는다.
  "Enter 로 확인" 패턴을 쓰는 모든 LCL 앱이 영향을 받는다. GTK2/GTK3/Qt5 에서는 LCL 이 먼저 받는다.
- tomboy-ng: `editbox.pas` `EditFindKeyDown` (검색창 Enter, Ctrl+F/G/N 도 같은 핸들러),
  `notebook.pas` `EditNewNotebookKeyDown` (노트북 이름 Enter → OK).
  `searchunit.pas` `EditSearchKeyUp` 은 `OnKeyUp` 을 쓴다. key-release 가 전달되는지는 **미확인**이며
  `Gtk4EntryDelegateKeyReleaseCB` (6195) 도 기록 전용이므로 함께 확인해 달라.

## 5. 수정 제안

**A안 (권장, GTK2/3 과 같은 순서):** GtkText 에 이미 붙어 있는 capture 키 컨트롤러에서
비문자 키를 LCL 로 전달한다.

- `Gtk4EntryDelegateKeyPressCB` 에서 `gdk_keyval_to_unicode(keyval)` 이 0 인 키(`Return`, `KP_Enter`,
  `Escape`, `Tab`, 기능키, 방향키 등) 에 한해 `Gtk4KeyPressedCB` 와 같은 경로(`GtkEventKey(..., True)`) 로
  `CN_KEYDOWN`/`LM_KEYDOWN` 을 전달한다. 문자 키는 지금처럼 기록만 하고 IM 에 맡긴다(TODO.md 결정 유지).
- LCL 핸들러가 `Key := 0` 으로 지웠으면 `True` 를 반환해 GtkText 의 `activate` 바인딩이 실행되지 않게 한다.
  지우지 않았으면 `False` 를 반환해 GTK 기본 동작(activate 등)을 유지한다.
- **중복 방지:** GtkText 가 소비하지 않은 키(`F3` 등)는 바깥 GtkEntry 의 bubble 컨트롤러(`Gtk4KeyPressedCB`)와
  폼 컨트롤러까지 다시 올라온다. delegate capture 에서 전달한 이벤트는 `TGtk4Entry` 에 플래그(예:
  `FDelegateKeyDelivered` + keyval/keycode) 로 표시하고, 같은 위젯의 bubble 콜백에서는 건너뛴다.
  폼 쪽은 이미 `Gtk4FormKeyBelongsToChild` (1855) 가 ActiveControl 이 있으면 무시하므로 추가 조치가 없어도 되지만 확인 필요.
- key-release 도 대칭으로: `Gtk4EntryDelegateKeyReleaseCB` 에서 같은 조건으로 `LM_KEYUP` 을 전달하고 중복을 막는다.

**B안 (최소 수정):** GtkEntry 의 `activate` 시그널에 콜백을 연결해 `VK_RETURN` KeyDown/KeyUp 을 합성한다.

- `Gtk4KeyPressedCB(controller, GDK_KEY_Return, 36, state=0, Self)` 를 직접 호출하는 형태.
- 장점: 컨트롤러 순서를 건드리지 않는다. 단점: LCL 이 GTK 의 activate **이후**에 키를 받으며, `Return` 만
  해결되고 `Escape`/`KP_Enter`(GtkText 는 KP_Enter 도 activate 로 매핑하므로 사실상 포함) 외의 키는 그대로다.
  `Key := 0` 으로 GTK 기본 동작을 막을 수도 없다.

어느 안이든 `TMemo` 경로(`wtMemo`, `WantReturns=False` 처리 3932–3937)는 변경하지 않는다.

## 6. 검증 방법

1. `test_entry_return/run.sh /path/to/tomboy-ng-gtk4-dbg` 실행. 수정 후 기대 출력:
   ```
   ### EditFindKeyDown Key=13    (Return)
   ### SpeedRightClick
   ### EditFindKeyDown Key=13    (KP_Enter)
   ### SpeedRightClick
   ### EditFindKeyDown Key=114   (F3, 한 번만 — 중복 전달이면 두 번 찍힌다)
   ### SpeedRightClick
   ```
   **2026-09-11 결과 (`lcl-gtk4 4.4+dfsg-5`, LCL 커밋 `057dd09`, tomboy-ng `0.42c+onion4`): 위 기대 출력과
   정확히 일치. 스크린샷 digest 도 200행 → 40행 → 200행으로 번갈아 이동. 해결 확인.**
   스크린샷 digest 는 `2-typed` → `3-return` → `4-kpenter` → `5-f3` 가 40행/200행을 번갈아 보여야 한다.
   같은 스크립트를 Qt5 바이너리로 돌리면 기준선이 된다(Enter 두 번 = 원위치).
2. 문자 키 회귀 확인: 검색창에 한글을 fcitx5 로 입력해 `EditFindChange` 가 계속 오고 조합이 깨지지 않는지
   (TODO.md 의 문자 키 결정과 KMemo IME 작업이 영향을 받지 않아야 한다).
3. `Escape` 를 OnKeyDown 에서 `Key := 0` 으로 먹는 폼에서 GtkText 의 기본 동작이 실제로 억제되는지.
4. `TComboBox`(편집 가능) 의 `Return` OnKeyDown 도 같은 방식으로 동작하는지.
5. LCL 재빌드 후 `lcl-gtk4 4.4+dfsg-5` 로 패키징하고, `objdump -dr` 로 설치 유닛에 변경이 들어갔는지 확인
   (dfsg-4 의 close-request 수정 확인 절차와 동일, tomboy-ng `HANDOFF.md` 참고).

## 7. 후속

- LCL 수정 패키지가 설치되면 tomboy-ng 는 `WIDGETSET=gtk4 LOCAL_VERSION_SUFFIX=onion4 ./build_widgetset_clean.sh`
  로 재빌드하고 이 시나리오를 다시 돌린다(tomboy-ng `BUILD_MANIFEST.md` 절차).
- tomboy-ng 쪽 임시 우회(검색창 Enter 를 `OnKeyUp`/`OnEditingDone` 으로 옮기기)는 key-release 전달이
  확인되기 전에는 채택하지 않는다.
