# InitialSetupDialog "Start IDE" 버튼 비가시 문제 — 분석 및 수정 계획 (v6)

## 1. Context

GTK4 Lazarus IDE의 InitialSetupDialog에서 "Start IDE" TBitBtn이 보이지 않는다 (Qt5에서는 정상 표시됨).
이전 세션에서 FCentralWidget 할당 + overflow=VISIBLE 수정을 시도했으나 해결되지 않았다.

---

## 2. 테스트 프로그램에 의한 실증 분석

### 2.1 테스트 프로그램

`test_setup_dialog/` — InitialSetupDialog의 LFM 레이아웃을 정확히 재현한 독립 LCL 애플리케이션.
Qt5 및 GTK4 widgetset으로 빌드하여 비교.

### 2.2 LCL 레이아웃 비교 (AfterShow-Idle)

| 컨트롤 | Qt5 | GTK4 | 차이 |
|--------|-----|------|------|
| Form | 640x520, CL=640x520 | 640x520, CL=640x520 | 동일 |
| WelcomePaintBox | 0,0,640x48 | 0,0,640x48 | 동일 |
| **BtnPanel** | 10,481,620x**29** | 10,471,620x**39** | H+10, Y-10 |
| StartIDEBitBtn | 520,0,100x29 | 503,0,117x39 | W+17, H+10 |
| PropertiesTreeView | 6,54,159x**417** | 6,54,159x**407** | H-10 |
| Splitter1 | 165,54,5x417 | 165,54,5x**421** | H+4 (앵커 불일치) |
| PropertiesPageControl | 170,54,464x**417** | 170,54,464x**421** | H+4 |

**핵심**: LCL 레이아웃 자체는 양쪽 모두 합리적. BtnPanel Visible=TRUE, 유효한 Handle 할당. **진동 사이클 없음** — 안정적.

### 2.3 스크린샷 결과

- **Qt5**: "Start IDE" 버튼이 우하단에 정상 표시 ✓
- **GTK4**: BtnPanel 영역(y=471~510)에 **버튼이 보이지 않음** ✗

### 2.4 GTK4 위젯 트리 (실측)

```
GtkWindow (640x520, overflow=HIDDEN)
  └── GtkBox (640x520)
        └── GtkOverlay (640x520)
              ├── GtkScrolledWindow (640x520) [base child]
              │     └── GtkViewport (640x520, overflow=HIDDEN)
              │           └── GtkFixed (FCentralWidget, 640x520, overflow=VISIBLE)
              │                 ├── child[0]: TreeView  (159x407) @6,54     ← LCL=159x407 ✓
              │                 ├── child[1]: Splitter   (5x421)  @165,54   ← LCL=5x421 ✓
              │                 ├── child[2]: BtnPanel  (620x39)  @10,471   ← LCL=620x39 ✓
              │                 ├── child[3]: PageCtrl  (466x460) @170,54   ← LCL=464x421 ✗✗✗
              │                 └── child[4]: PaintBox  (640x48)  @0,0      ← LCL=640x48 ✓
              └── GtkDrawingArea (FPaintArea, 640x520) [overlay]
```

모든 위젯: **visible=TRUE, mapped=TRUE**. 위치도 정확. 하지만 **PageControl의 GTK 할당이 LCL 요청과 다름**.

---

## 3. 근본 원인: GtkFixed 최소 크기 재할당에 의한 컨트롤 겹침

### 3.1 문제 메커니즘

1. LCL이 `SetBounds(170, 54, 464, 421)` → `set_size_request(464, 421)` + `size_allocate(464, 421)` 호출
2. `Form.Widget.show` → GTK4 layout engine 실행
3. **GtkFixed layout**: 자식을 `gtk_widget_measure()` → **minimum size**로 재할당
4. PageControl의 GtkNotebook CSS 최소 높이 = **460** (탭 영역 + 패널 최소값)
5. GtkFixed가 PageControl을 **466x460**으로 할당 (LCL 요청 464x421 대신)
6. PageControl 하단: 54 + 460 = **514** > BtnPanel 상단: **471**
7. **GtkFixed child 순서**: child[2]=BtnPanel, child[3]=PageControl → PageControl이 나중에 그려짐
8. **PageControl이 BtnPanel 영역을 완전히 덮음** → 버튼 비가시

### 3.2 수치 검증

```
PageControl (LCL):  170, 54, 464x421  → bottom = 475
PageControl (GTK4): 170, 54, 466x460  → bottom = 514  ← 39px 초과!

BtnPanel (LCL/GTK4): 10, 471, 620x39  → top=471, bottom=510

겹침 영역: y=471~510, x=170~636  ← Start IDE 버튼(x=503) 포함!
460 - 421 = 39 = BtnPanel 높이  ← 정확히 BtnPanel 만큼 초과!
```

### 3.3 Qt5와의 차이

| 항목 | Qt5 | GTK4 |
|------|-----|------|
| PageControl GTK/Qt 할당 높이 | 417 (=LCL) | **460 (>LCL 421)** |
| 겹침 | 없음 | **39px** |
| 원인 | Qt5 sizeHint ≈ LCL 크기 | GtkNotebook CSS min > LCL 크기 |

### 3.4 v5 계획의 오류

v5에서는 **BtnPanel의 25 vs 34 높이 불일치**를 핵심 원인으로 분석했으나:
- 테스트 결과 BtnPanel은 정상 할당됨 (620x39, visible, mapped)
- 진동 사이클 없음 — LCL이 39를 수용하고 안정적
- **실제 원인은 PageControl의 GTK 최소 크기 초과로 인한 z-order 겹침**

---

## 4. 수정 전략

### Fix A (최우선): SetBounds에서 GtkFixed 재할당 방지

**문제**: `Form.Widget.show` 후 GtkFixed layout이 자식을 minimum size로 재할당하여 LCL의 `size_allocate` 결과를 덮어씀.

**접근 1: GtkFixed layout 억제**

GtkFixed의 레이아웃 관리자가 자식 크기를 변경하지 않도록, `size_allocate`를 다시 한번 호출하여 LCL 크기를 강제.

```pascal
// TGtk4Window — ShowHide 또는 AfterPaint 콜백에서:
// Form.show 후 GTK layout이 실행된 다음,
// 모든 자식의 LCL bounds를 GTK에 다시 적용
procedure ReapplyChildBounds(AForm: TCustomForm);
var
  i: Integer;
  C: TControl;
  WC: TWinControl;
  Wgt: TGtk4Widget;
begin
  for i := 0 to AForm.ControlCount - 1 do
  begin
    C := AForm.Controls[i];
    if (C is TWinControl) and TWinControl(C).HandleAllocated then
    begin
      WC := TWinControl(C);
      Wgt := TGtk4Widget(WC.Handle);
      Wgt.SetBounds(WC.Left, WC.Top, WC.Width, WC.Height);
    end;
  end;
end;
```

**장점**: GTK layout이 LCL 크기를 존중하도록 강제
**단점**: 매번 show 후 추가 작업. GtkFixed가 다음 layout cycle에서 다시 minimum으로 할당할 수 있음

**접근 2: GtkFixedLayout custom allocate**

GTK4의 GtkFixed는 `GtkFixedLayout`을 사용. 이 layout manager의 `allocate` 함수가 자식을 minimum size로 할당하는 것이 문제. GTK4 API로 layout manager를 커스텀으로 대체하면 해결 가능하지만 복잡도 높음.

**접근 3 (권장): `set_size_request`를 LCL 크기로 강제 설정**

`set_size_request(W, H)`는 위젯의 **minimum size**를 설정. GtkFixed layout은 minimum size 이상으로 할당하므로, `set_size_request`를 LCL 크기로 설정하면 GtkFixed가 정확히 그 크기로 할당.

**문제**: 현재 SetBounds에서 이미 `set_size_request`를 호출하고 있지만, GTK layout이 이를 무시하고 위젯 자체의 CSS minimum으로 할당하는 것으로 보임. 실제로 `set_size_request(464, 421)`이 호출되었다면 minimum은 421이어야 하고, GtkFixed는 421로 할당해야 함.

**가설**: `set_size_request`가 올바르게 전달되지 않거나, GtkNotebook의 내재적 minimum이 `set_size_request`를 override하거나, 타이밍 문제.

### Fix B: PageControl의 `set_size_request` 검증 및 강화

```pascal
// TGtk4Widget.SetBounds — GtkBox 래퍼가 있는 경우:
// PageControl의 Widget은 GtkBox인데, set_size_request가 GtkBox에 설정되는지
// 또는 내부 GtkNotebook에 설정되는지 확인 필요.
// 만약 GtkBox에만 설정되고 GtkNotebook에는 설정되지 않으면,
// GtkFixed가 GtkNotebook의 minimum으로 GtkBox를 확장할 수 있음.
```

### Fix C: show 후 idle에서 LCL bounds 재적용

```pascal
// gtk4wsforms.pp — ShowHide에서 show 후:
function Gtk4ReapplyBoundsIdle(Data: gpointer): gboolean; cdecl;
var
  Wgt: TGtk4Widget;
  LCL: TWinControl;
  i: Integer;
  C: TWinControl;
begin
  Result := G_SOURCE_REMOVE;
  Wgt := TGtk4Widget(Data);
  if not Gtk4IsLiveWidgetPointer(Data) then exit;
  LCL := Wgt.LCLObject;
  // Re-apply all child bounds
  for i := 0 to LCL.ControlCount - 1 do
    if (LCL.Controls[i] is TWinControl) and TWinControl(LCL.Controls[i]).HandleAllocated then
    begin
      C := TWinControl(LCL.Controls[i]);
      TGtk4Widget(C.Handle).SetBounds(C.Left, C.Top, C.Width, C.Height);
    end;
end;
```

---

## 5. 진단 필요 사항

Fix 적용 전에 확인해야 할 사항:

### 5.1 PageControl의 Widget 구조 (확인 완료)

```pascal
// TGtk4NoteBook.CreateWidget (gtk4widgets.pas:6006):
Result := TGtkBox.new(GTK_ORIENTATION_VERTICAL, 0);   // Widget = GtkBox
FCentralWidget := TGtkNotebook.new;                     // FCentralWidget = GtkNotebook
gtk4_box_append(PGtkBox(Result), FCentralWidget);       // GtkNotebook inside GtkBox
```

**Widget = GtkBox, FCentralWidget = GtkNotebook**

### 5.2 SetBounds에서 size_request 전달 경로 (확인 완료)

```pascal
// SetBounds (gtk4widgets.pas:3977):
Widget^.set_size_request(AWidth, AHeight);  // GtkBox에 set_size_request(464, 421)

// 그리고 (line 3991-3996):
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
  gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
  // GtkNotebook에 size_allocate(464, 421)
  // 하지만 set_size_request는 호출하지 않음! (주석: "preferredSize에 영향을 줄 수 있으므로")
```

**문제**: `set_size_request`는 GtkBox에만 설정됨. GtkNotebook에는 설정되지 않음.

- GtkBox의 `set_size_request(464, 421)` → GtkBox 자체 minimum = 421
- GtkNotebook의 CSS minimum height = ~460 (탭 + 콘텐츠 패딩)
- GtkBox의 **실제 minimum = max(421, child_minimum) = max(421, 460) = 460**
- `set_size_request`가 자식 minimum보다 작으면 효과 없음

**해결**: GtkNotebook(FCentralWidget)에도 `set_size_request` 적용 필요.
단, 주석의 우려 ("preferredSize에 영향") 는 FCentralWidget이 GetContainerWidget에서 반환되고
`preferredSize`가 `GetContainerWidget`을 measure하므로, `set_size_request`가 preferredSize를 왜곡할 수 있음.
따라서 **선택적으로** FCentralWidget에 `set_size_request`를 적용하되, `preferredSize`에서
measure 전에 `set_size_request(-1,-1)`로 리셋하는 방안 고려.

### 5.3 GtkFixed의 allocate 동작 (확인 완료)

GtkFixed가 자식을 `gtk_widget_measure` → minimum으로 할당하는 동작은 GTK4 소스에서 확인됨 (v5 §3.6).
SetBounds에서 `size_allocate`를 호출하지만, `Form.show` → GTK layout engine → GtkFixed `allocate` →
자식을 다시 minimum size로 할당. **LCL의 size_allocate가 GTK layout에 의해 덮어써짐**.

---

## 6. 실행 순서

### Phase 1: 진단 (완료)

- DP1 ✅: PageControl Widget = GtkBox, FCentralWidget = GtkNotebook
- DP2 ✅: `set_size_request`는 GtkBox에만 설정. GtkNotebook에는 미설정
- DP3 ✅: Form.show 후 GtkFixed가 PageControl을 466x460으로 재할당 (LCL 요청 464x421)
- DP4: GtkNotebook minimum height 확인 필요 (추정 ~460)

### Phase 2: 수정

**Fix D (권장): SetBounds에서 FCentralWidget에도 set_size_request 적용**

```pascal
// TGtk4Widget.SetBounds (gtk4widgets.pas:3991-3996):
// 기존:
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
  gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);  // size_allocate만

// 수정:
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
begin
  FCentralWidget^.set_size_request(AWidth, AHeight);  // ← 추가!
  gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
end;
```

**효과**: GtkNotebook의 minimum이 LCL 크기(421)로 설정됨.
→ GtkBox measure → min=max(421, 421) = 421
→ GtkFixed allocate → 421로 할당
→ 겹침 해소

**부작용 우려**: `preferredSize`에서 `gtk4_widget_measure(GetContainerWidget, ...)`를 호출하므로,
FCentralWidget의 `set_size_request`가 `preferredSize` 결과에 영향.
→ AutoSize 컨트롤에서 preferredSize가 LCL 요청 크기를 반환하게 됨 (내재적 크기 대신)

**부작용 완화**: `preferredSize` 호출 전에 `set_size_request(-1, -1)` 리셋:
```pascal
// TGtk4Widget.preferredSize (gtk4widgets.pas:4168-4170):
// 측정 전에 size_request 초기화하여 내재적 크기를 측정
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
  FCentralWidget^.set_size_request(-1, -1);  // ← 추가

gtk4_widget_measure(GetContainerWidget, GTK_ORIENTATION_VERTICAL, ...);
gtk4_widget_measure(GetContainerWidget, GTK_ORIENTATION_HORIZONTAL, ...);

// 측정 후 다시 LCL 크기로 설정
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
  FCentralWidget^.set_size_request(LCLObject.Width, LCLObject.Height);  // ← 추가
```

**대안 Fix E: preferredSize 변경 없이, Widget(GtkBox)도 minimum 강제**

GtkBox에 `set_size_request` 대신 GtkNotebook에 직접 설정하되,
preferredSize 코드는 변경하지 않음 (measure 시 `-1,-1`로 항상 초기화):

```pascal
// SetBounds에서:
if Assigned(FCentralWidget) and (FCentralWidget <> FWidget) then
begin
  // GtkFixed가 re-allocate할 때 minimum이 LCL 크기를 초과하지 않도록 강제
  FCentralWidget^.set_size_request(AWidth, AHeight);
  gtk4_widget_size_allocate(FCentralWidget, @Alloc, -1);
end;
```

### Phase 3: 검증

1. 테스트 프로그램: `test_setup_dialog/test_setup_dialog_gtk4` — Start IDE 버튼 표시 확인
2. 테스트 프로그램 스크린샷 비교 (Qt5 vs GTK4)
3. GTK4 위젯 트리 재확인: PageControl alloc = 464x421 (LCL 요청과 일치)
4. 실제 IDE: `./lazarus --pcp=/tmp/laztest` — InitialSetupDialog 확인
5. 일반 폼: 다른 폼에서 PageControl, ComboBox 등이 정상 동작하는지 확인
6. AutoSize 컨트롤: preferredSize가 올바른 내재적 크기를 반환하는지 확인
7. GTK2 회귀: `make lcl LCL_PLATFORM=gtk2`

### Phase 4: 정리

1. `{DBG}` 진단 로깅 제거
2. 테스트 프로그램 보존 (향후 회귀 테스트용)

---

## 7. 핵심 통찰 요약

1. **v5의 "앵커가 AutoSize를 덮어씀" 분석은 부정확** — 실측에서 BtnPanel은 39px로 정상 할당됨
2. **v5의 "진동 사이클" 우려는 해당 없음** — LCL 레이아웃 안정적, 진동 없음
3. **근본 원인: GtkFixed가 PageControl을 GTK minimum size(460)로 재할당** → LCL 요청(421) 초과
4. **PageControl이 BtnPanel 영역을 z-order에서 덮음** → 버튼 비가시
5. **핵심 차이**: GtkNotebook CSS minimum > LCL 요청 크기. Qt5에서는 sizeHint ≈ LCL 크기
6. **수정 방향**: GtkFixed 자식의 GTK minimum size를 LCL 크기로 강제하거나, show 후 재적용
7. **이 문제는 InitialSetupDialog에만 국한되지 않을 수 있음** — 모든 GtkFixed 기반 폼에서 GTK minimum > LCL 크기인 컨트롤이 있으면 동일 문제 발생 가능

---

## 8. 테스트 환경

- 테스트 프로그램: `test_setup_dialog/` (lpr, lfm, pas, lpi)
- Qt5 바이너리: `test_setup_dialog/test_setup_dialog_qt5`
- GTK4 바이너리: `test_setup_dialog/test_setup_dialog_gtk4`
- Qt5 스크린샷: `test_setup_dialog/screenshot_qt5.png`
- GTK4 스크린샷: `test_setup_dialog/screenshot_gtk4.png`
- 빌드: `./lazarus/lazbuild --lazarusdir="$(pwd)/lazarus" --ws=<qt5|gtk4> test_setup_dialog/test_setup_dialog.lpi`
- 실행: `DISPLAY=:1 XAUTHORITY=/run/user/1000/gdm/Xauthority test_setup_dialog/test_setup_dialog_<qt5|gtk4>`
