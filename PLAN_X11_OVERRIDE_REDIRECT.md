# PLAN: X11 Override-Redirect 팝업 창 구현 (GTK2 GTK_WINDOW_POPUP 대응)

> ## ⚠️ ROLLBACK POINT: `fa64186` (branch: master)
>
> "Session 74: screen-absolute coordinates, popup show() path, CSS max-size removal"
>
> 문제 발생 시 복원:
> ```
> git checkout fa64186 -- lazarus/lcl/interfaces/gtk4/
> make lcl LCL_PLATFORM=gtk4 && make bigide LCL_PLATFORM=gtk4
> ```

**Rev 3** — Rev 2: 코드 대조 검토 4건 수정. Rev 3: Sonnet 교차검토 라운드 1에서
인용 오류 2건 수정 (XMoveWindow 행 번호 11402→11423, Phase 4 case 분기 상수
GDK_BUTTON_PRESS→GDK4_BUTTON_PRESS/1314행)

## 구현 상태 (2026-07-02)
- **Phase 1~3 구현 완료** — gtk4widgets.pas(X11 바인딩 + TX11SetWindowAttributes
  구조체 + PreparePopupShow/RaiseX11Popup 메서드), gtk4wsforms.pp(Gtk4FormIsPopup
  판별 + TGtk4WSCustomForm.ShowHide & TGtk4WSHintWindow.ShowHide 양쪽 적용)
- **빌드**: lcl/gtk4, bigide/gtk4, lcl/gtk2(회귀) 모두 통과
- **Phase 4 (닫힘 경로 보완)**: 미착수 — 계획대로 사용자 테스트 후 필요 시 진행
  (IDE 내 다른 곳 클릭 시 팝업이 닫히지 않으면 그때 구현)
- **1차 테스트 피드백 반영**: 완성 팝업은 정위치 표시 확인. 그러나 판별 기준의
  `(AForm is THintWindow)` 절이 일반 IDE 툴팁까지 override-redirect로 만들어
  컴포넌트 팔레트 hover 시 pointer enter/leave 피드백 루프(깜박임) 발생 →
  해당 절 제거. 완성 팝업과 long-line 힌트(FHint)는 fsSystemStayOnTop을 명시
  설정하므로 `bsNone + stay-on-top` 절로 계속 override-redirect 유지. 일반
  툴팁은 이전 transient_for 동작으로 복귀.
- **디자인 모드 입력 라우팅 추가** (같은 브랜치): (1) Delete가 선택된 TEdit의
  텍스트를 지우던 문제 → CAPTURE 단계 `Gtk4DesignKeyPressedCB`로 디자인 모드
  키를 디자이너에 전달·소비. (2) 디자인 모드에서 위젯 클릭이 상태를 바꾸던 문제
  6종(체크/라디오·스핀·콤보·트랙바·캘린더·리스트류) → 콜백에 `csDesigning` 가드
  추가 (노트북 탭 전환은 의도적 유지). 사용자 테스트 정상 확인.
- **커밋 완료**: `bc63c63` "GTK4: X11 override-redirect popups + design-mode
  key/click routing". 이후 rollback point는 이 커밋.

## 문제 정의

SynCompletion 팝업(코드 자동완성)이 GTK4에서:
1. **엉뚱한 위치에 표시됨** — GTK4는 `gtk_window_move()`와 `GTK_WINDOW_POPUP` 창
   타입을 모두 삭제. 토플레벨 창의 배치는 전적으로 WM이 결정하며, XMoveWindow를
   호출해도 WM이 재배치할 수 있음.
2. **잠깐 보였다가 즉시 사라짐** — 팝업이 WM으로부터 X 포커스를 받으면 에디터
   창에 focus-out 발생 → `Gtk4HandleAppFocusOut`(gtk4widgets.pas:1856)이 포커스
   타이머 시작 → 팝업의 focus-in이 앱 활성 상태 추적에 등록되지 않음 →
   `Application.IntfAppDeactivate` 발화 → SynCompletion의 `AppDeactivated` 핸들러가
   팝업을 닫음 (syncompletion.pas:1023 → `Deactivate` → `Visible := False`).

## 해결 원리 (Qt5가 동작하는 이유와 동일)

Qt5 LCL은 X11에서 힌트 창에 `QtBypassWindowManagerHint`(= override-redirect) +
`QtWA_ShowWithoutActivating`을 사용 (qtwidgets.pas:18964, 18968).
GTK2 LCL은 `GTK_WINDOW_POPUP`(= override-redirect)을 사용.

X11 `override_redirect=True` 속성을 설정하면 WM이 그 창을 완전히 무시:
- 위치: XMoveWindow / 생성 좌표가 그대로 유지됨 (WM 재배치 없음)
- 포커스: WM이 절대 포커스를 주지 않음 → 에디터가 포커스 유지
  → focus-out 연쇄가 발생하지 않음 → 팝업이 사라지지 않음
- 키 입력: SynCompletion이 에디터에 `RegisterBeforeKeyDownHandler` 등을 등록해
  두므로 (syncompletion.pas:1260-1263, "Some Widgetset may report keys to the
  editor" 주석) 에디터가 포커스를 유지해도 자동완성 키 처리가 동작함
- 마우스: X11은 OR 창에도 버튼 이벤트를 정상 전달 → 항목 클릭/더블클릭 동작

## 구현 단계

### Phase 1: X11 바인딩 추가 (gtk4widgets.pas)

기존 동적 로딩 인프라(`InitX11SizeHints` ~10770행, libX11.so.6)에 추가.
구조체는 기존 `TX11SizeHints`(10734행)와 동일한 스타일: 일반 record +
"Must match Xlib layout" 주석 (FPC objfpc 기본 정렬 = C ABI 호환, x86_64 확인).

```pascal
const
  CWOverrideRedirect = culong(1) shl 9;   { X.h }

type
  { Must match Xlib XSetWindowAttributes layout (x86_64: XID/ulong=8, int/Bool=4,
    long=8; 컴파일러가 C와 동일하게 정렬). override_redirect만 사용. }
  TXSetWindowAttributes = record
    background_pixmap: PtrUInt;    { Pixmap (XID) }
    background_pixel: culong;
    border_pixmap: PtrUInt;        { Pixmap (XID) }
    border_pixel: culong;
    bit_gravity: cint;
    win_gravity: cint;
    backing_store: cint;
    backing_planes: culong;
    backing_pixel: culong;
    save_under: cint;              { Bool }
    event_mask: clong;
    do_not_propagate_mask: clong;
    override_redirect: cint;       { Bool }
    colormap: PtrUInt;             { Colormap (XID) }
    cursor: PtrUInt;               { Cursor (XID) }
  end;
  PXSetWindowAttributes = ^TXSetWindowAttributes;

  TX11ChangeWindowAttributes = function(display: Pointer; w: PtrUInt;
    valuemask: culong; attributes: PXSetWindowAttributes): cint; cdecl;
  TX11RaiseWindow = function(display: Pointer; w: PtrUInt): cint; cdecl;
```

- `X11pChangeWindowAttributes`, `X11pRaiseWindow` 함수 포인터 + `InitX11SizeHints`에
  GetProcAddress 로딩 추가 (기존 `X11pMoveWindow` 패턴과 동일, 10784행 인근)
- `XRaiseWindow`는 보조용 (OR 창은 WM 스태킹 관리를 받지 않으므로 표시 직후
  최상위 보장용)

### Phase 2: TGtk4Window 메서드 (gtk4widgets.pas)

**[Rev 2 수정]** 독립 헬퍼 함수가 아니라 `TGtk4Window`의 public 메서드로 구현.
이유: 힌트 창(`TGtk4WSHintWindow.ShowHide`)과 일반 폼(`TGtk4WSCustomForm.ShowHide`)의
표시 경로가 분리되어 있어 (아래 Phase 3), 양쪽에서 호출 가능해야 함.
`TGtk4HintWindow`는 `TGtk4Window`의 서브클래스(gtk4widgets.pas:964)이므로 메서드
하나로 양쪽 커버.

```pascal
procedure TGtk4Window.PreparePopupShow;
{ map 되기 전에 호출해야 함. realize → override_redirect 설정 → 초기 위치 배치. }
```
동작:
1. `gtk_widget_realize(FWidget)` — X 윈도우(GdkSurface) 생성, 아직 unmapped.
   GTK4에서 show 전 realize는 공식 지원 패턴 (GtkWindow는 자기 자신이 GtkRoot라
   anchored 조건 충족).
2. `gtk4_native_get_surface` → `X11pGetXid` → XID 획득
3. `XChangeWindowAttributes(dpy, xid, CWOverrideRedirect, @attrs)` —
   attrs.override_redirect := 1
4. `XMoveWindow(dpy, xid, LCLObject.Left, LCLObject.Top)` — LCL 좌표는 화면
   절대좌표 (SynCompletion이 `Form.SetBounds(screen_x, screen_y, ...)`로 설정,
   Session 74에서 ClientToScreen이 절대좌표를 반환하도록 수정 완료)
5. 전 과정을 X11 함수 포인터 `Assigned()` 가드로 감쌈 — **Wayland에서는 2~4단계
   전체가 no-op** (realize만 수행돼도 무해). XID 획득 실패 시에도 조용히 반환.

- **중요**: `override_redirect`는 X 서버가 **map 시점에 평가** — 반드시 map 전에
  설정. 이미 map된 창은 unmap → 변경 → remap이 필요하므로 이 메서드는 표시
  직전에만 호출.
- SynCompletion은 팝업을 show/hide 반복 재사용. GTK4의 hide는 unmap만 하고
  unrealize하지 않아 X 윈도우가 유지되지만, GTK가 surface를 재생성하는 경우를
  대비해 **표시 경로마다 매번 호출** (realize는 이미 realize된 경우 no-op,
  XChangeWindowAttributes 중복 설정 무해).

### Phase 3: 팝업 판별 + 두 ShowHide 경로에 적용 (gtk4wsforms.pp)

판별 함수 (gtk4wsforms.pp 내 지역 함수):
```pascal
function Gtk4FormIsPopup(AForm: TCustomForm): Boolean;
begin
  Result := (not (csDesigning in AForm.ComponentState)) and
    ((AForm is THintWindow)
     or (csNoFocus in AForm.ControlStyle)
     or ((AForm.BorderStyle = bsNone)
         and (AForm.FormStyle in [fsStayOnTop, fsSystemStayOnTop])));
end;
```
- SynCompletion 폼: bsNone + fsSystemStayOnTop → 해당 ✓ (syncompletion.pas:697-698)
- 힌트 창(THintWindow, 에디터 파라미터 힌트 등) → 해당 ✓
- 스플래시(fsSplash), 일반 bsNone 폼, csDesigning → 미해당 (WM 관리 유지)
- Qt5 기준 참고: csNoFocus → QtWindowDoesNotAcceptFocus (qtwsforms.pp:1009-1012)

**[Rev 2 수정 — 호출 위치가 핵심]** 첫 map은 `present()`/`show()` 분기가 아니라
`AGtk4Widget.Visible := ShouldBeVisible` (**gtk4wsforms.pp:324**)에서 발생함
(`TGtk4Widget.SetVisible` → `FWidget^.set_visible(True)`, gtk4widgets.pas:3589).
따라서 OR 설정은 이 줄 **앞**에 넣어야 함:

```pascal
{ TGtk4WSCustomForm.ShowHide — 324행 직전 }
if ShouldBeVisible and (AWindow <> nil) and Gtk4FormIsPopup(AForm)
   and (AGtk4Widget is TGtk4Window) then
  TGtk4Window(AGtk4Widget).PreparePopupShow;
AGtk4Widget.Visible := ShouldBeVisible;   // 여기서 map됨 (OR 상태로)
```

이후 기존 표시 분기(~370행)는:
- 팝업이면 `show()` 경로 유지 (Session 74 수정 — 이미 visible이므로 사실상 no-op)
  + map 후 `X11pRaiseWindow` 호출 (최상위 보장)
- `Gtk4PostShowResizeCB`는 decorated 전용 유지 (Session 74 수정 그대로)

**힌트 창 별도 경로**: `TGtk4WSHintWindow.ShowHide`(gtk4wsforms.pp:729)는
TGtk4WSCustomForm.ShowHide를 경유하지 않고 `AWidget.Visible := ...`로 직접
표시함. 여기에도 동일하게 `Visible := True` 직전에 `PreparePopupShow` 호출 추가.
기존 `set_transient_for(MainForm)` 로직은 유지 (OR 창에서 WM 힌트는 무시되지만
Wayland 폴백 경로에서 여전히 필요).

**기존 코드 유지**: `TGtk4Window.SetBounds`의 XMoveWindow 경로(미장식+realized
가드 11413-11414행, `X11pMoveWindow` 호출 gtk4widgets.pas:11423)는 그대로 —
표시 중 위치 갱신(팝업 위치 추적) 담당.

### Phase 4: 닫힘 경로 보완 (위험 항목 — 테스트 후 필요 시)

OR 팝업은 포커스를 받지 않으므로 `Form.Deactivate`가 발생하지 않음.
SynCompletion의 닫힘 경로별 상태:

| 닫힘 트리거 | 동작 여부 | 비고 |
|---|---|---|
| Enter/Tab/Escape/항목 선택 | ✓ | 에디터 키 핸들러 경유 |
| 다른 앱으로 전환 | ✓ | 진짜 앱 비활성 → AppDeactivated |
| 에디터 스크롤 | ✓ | EditorStatusChanged(scTopLine) |
| **IDE 내 다른 곳 클릭 (에디터 포함)** | ✗ 예상 | Deactivate 미발생 — 보완 필요 |

보완 설계 (필요 확인 후 구현):
- gtk4widgets.pas에 전역 `Gtk4VisiblePopupWindow: TGtk4Window` 추적
  (PreparePopupShow에서 등록, SetVisible(False)/DestroyWidget에서 해제)
- **[Rev 2 수정]** 마우스 이벤트 진입점은 `Gtk4LegacyEventCB`(gtk4widgets.pas:1286,
  legacy event controller CAPTURE 단계 — `Gtk4ClickPressedCB`라는 콜백은 존재하지
  않음). case 분기는 `GDK4_BUTTON_PRESS, GDK4_BUTTON_RELEASE:`(1314행) —
  **주의**: 네이티브 이벤트 타입 상수는 `GDK4_BUTTON_PRESS = 2`
  (lazgtk4_compat.pas:31)이며, `GDK_BUTTON_PRESS = 4`(lazgdk4.pas:2811)는
  합성 SynEvent.type_ 대입용 GTK3 스타일 별개 상수 — case 디스패치에 사용하면
  안 됨. 이 분기에서: OR 팝업이 표시 중이고 이벤트 대상 토플레벨 ≠ 팝업이면,
  팝업 폼에 `LM_ACTIVATE(WA_INACTIVE)` 전달 → LCL이 `Form.Deactivate` 호출 →
  SynCompletion 닫힘 (GTK2의 팝업 그랩 동작 대체)

### Phase 5: 빌드 + 검증

빌드: `make lcl LCL_PLATFORM=gtk4` → `make bigide LCL_PLATFORM=gtk4` →
`make lcl LCL_PLATFORM=gtk2` (회귀 확인)

테스트 체크리스트:
1. **자동완성 팝업**: 코드 에디터에서 `'문자열'.` 입력 → 캐럿 바로 아래 표시,
   사라지지 않음, 방향키/Enter/Escape 동작, 항목 클릭/더블클릭 동작,
   계속 타이핑 시 필터링 동작
2. **파라미터 힌트**: `Function(` 입력 시 힌트 창 위치
3. **에디터 툴팁/식별자 힌트**: 마우스 오버 힌트 위치 (TGtk4WSHintWindow 경로 검증)
4. **IDE 내 다른 곳 클릭 시 팝업 닫힘** (Phase 4 필요 여부 판정)
5. **회귀**: 일반 폼/다이얼로그 표시·포커스 정상, 메인 창 위치 드리프트 없음,
   스플래시 정상, 모달 다이얼로그 정상, Object Inspector 콤보 드롭다운
   (GtkPopover 경유 — 영향 없어야 함)
6. **Wayland 폴백**: X11 함수 미로딩 시 기존 경로로 동작 (크래시 없음)

## 위험 요소

1. **GDK4 X11 백엔드와 OR 창의 상호작용 (최대 리스크)**: GDK4는 WM과의
   `_NET_WM_SYNC_REQUEST` 프레임 동기화를 전제로 함. OR 창은 WM이 관여하지
   않으므로 GDK의 configure/frame 처리가 예상과 다르게 동작할 가능성. 다만 X
   서버는 OR 창에 ConfigureNotify를 직접 전달하고, GDK는 WM 없는 X 환경도
   지원해야 하므로 동작할 가능성이 높음. **테스트에서 창이 그려지지 않거나
   프리즈하면 이 원인** — 그 경우 GtkPopover 백엔드(옵션 2)로 전환 판단.
2. **realize 시점**: `gtk_widget_realize`를 show 전에 호출하는 것은 GTK4 공식
   패턴이나, LCL 쪽에서 realize가 예상보다 일찍 일어나며 발생하는 부작용
   (surface 이벤트, 크기 계산) 가능성. 회귀 테스트 항목 5로 검증.
3. **AddWindow(gtk_application_add_window)**: 팝업도 현재 GTK 앱 윈도우 목록에
   등록됨 (gtk4wsforms.pp:354). OR 창 등록이 문제를 일으키면 팝업은 등록 스킵
   검토 (관찰 항목).

## 검토에서 발견된 수정사항 (Rev 1 → Rev 2)

1. **호출 위치 오류 (치명적)**: Rev 1은 OR 설정을 `present()/show()` 분기에
   배치했으나, 실제 첫 map은 그보다 앞의 `AGtk4Widget.Visible := ShouldBeVisible`
   (gtk4wsforms.pp:324)에서 발생 → OR이 map 이후에 설정되어 **무효**가 됐을 것.
   `Visible := True` 직전 호출로 수정.
2. **힌트 창 경로 누락**: `TGtk4WSHintWindow.ShowHide`는 TGtk4WSCustomForm의
   표시 경로를 경유하지 않는 별도 구현 → Rev 1대로면 힌트 창에 OR 미적용.
   `TGtk4Window.PreparePopupShow` 메서드로 승격해 양쪽에서 호출.
3. **존재하지 않는 콜백 인용**: Phase 4의 `Gtk4ClickPressedCB`는 코드에 없음
   (과거 세션 메모의 잔재). 실제 진입점은 `Gtk4LegacyEventCB`(1286행)의
   GDK_BUTTON_PRESS 분기.
4. **Wayland 가드 불명확**: Rev 1 스니펫은 XMoveWindow를 무조건 호출.
   PreparePopupShow 내부에서 X11 함수 포인터 가드로 전체를 감싸도록 명시.
