# 기존(pre-existing) GTK4 위젯셋 IDE 문제

> **항목 1(옵션 대화상자 리사이즈 오버플로 크래시): 2026-07-11 해결됨.**
> 근본원인=스크롤 컨테이너의 `set_size_request`가 `gtk_widget_measure`를 통해
> 위젯셋 preferred로 새어나와 스크롤 range 자기강화 루프를 형성.
> 수정=`TGtk4Widget.preferredSize`에서 'lcl-scroll-fixed' 태그 컨테이너의
> 오염된 측정값을 무시하고 0 보고. 상세는 아래 "### 해결" 참조.

실기 테스트에서 발견됐으나 **세션 이전 코드(888b1b1)에서도 동일 재현**되어
이번 세션의 수정과 무관함이 격리 빌드 대조로 확정된 항목들.

**중요 정정**: 초기엔 "LCL 코어 버그"로 봤으나, **Qt5 대조로 GTK4 위젯셋
고유 문제임이 확정됨**. 크래시가 공유 LCL 코어(wincontrol.inc 등)에서
검출되지만, 잘못된 크기/위치를 거기에 먹이는 근본 원인은 GTK4 위젯셋의
preferredSize/measure/layout 경로에 있음. 순수 코어 버그였다면 Qt5도 동일
크래시해야 하는데 그렇지 않음.

## 검증 방법 (3중 배제 + 근본원인 국소화)
1. **세션 배제(회귀 아님)**: 세션에서 변경한 gtk4 위젯셋 8개 파일을 888b1b1로
   checkout → 증분 재빌드 → 동일 절차. 두 항목 모두 세션 이전 빌드에서
   동일하게 재현(항목1: `Left=33322` 동일 크래시, 항목2: 음수라벨 35건).
2. **개별 배제**: 스크롤 자식 오프셋 무력화 테스트에서도 크래시 지속.
   constraints 변경은 옵션 대화상자가 Min만 설정(Max 없음)+메뉴바 없음이라
   완전 no-op → 배제.
3. **근본원인 국소화(코어 vs 위젯셋)**: 같은 IDE를 **Qt5로 빌드**(`make
   bigide LCL_PLATFORM=qt5`)해 동일 절차(Tools→Options→리사이즈) 실행 →
   **Qt5는 크래시 0건**. 따라서 공유 LCL 코어가 아니라 GTK4 위젯셋 문제.

## 1. 옵션 대화상자 리사이즈 시 autosize 위치 오버플로 (크래시)
- 증상: Tools→Options 연 뒤 창을 작게/크게 반복 리사이즈하면
  `TApplication.HandleException: ELayoutException` →
  `Position range overflow in FppkgConfigurationFileButton.SendMoveSizeMessages:
  Left=33322, Top=449` (Left가 SmallInt 범위 초과).
  사용자 실기에서는 `InvalidatePreferredSize loop detected EditorsPanel:TScrollBox`
  형태로도 나타남(같은 autosize 불안정의 다른 표출).
- 위치: `ide/ideoptionsdlg.pas` EditorsPanel:TScrollBox 안의 Fppkg 설정 옵션
  프레임. 크래시 스택은 LCL 코어 레이아웃(wincontrol.inc/control.inc/
  scrollingwincontrol.inc)에서 **검출**되지만, Qt5는 동일 코어를 쓰고도
  크래시 안 함 → 근본 원인은 GTK4 위젯셋의 크기/위치 보고에 있음.
- 성격: GTK4 위젯셋에서 자식 Left가 폭주(수렴 실패)해 크래시. Qt5/gtk2 무발생.
- 재현 절차(Xvfb, gtk4): 1600x1000 화면에서 IDE 기동 → Tools(x≈434,y≈14) →
  Options(x≈470,y≈49) → 옵션 창을 600x480/900x700/500x400 등으로 반복 리사이즈.
  (Qt5 대조: `make bigide LCL_PLATFORM=qt5` 후 `QT_QPA_PLATFORM=xcb`로 동일
  절차 — Start IDE 버튼 좌표 x≈1070,y≈745, 크래시 없음.)

### 해결 (2026-07-11) — 근본원인 확정 및 수정

**근본원인(런타임 계측으로 확정)**: 스크롤 컨테이너(TScrollBox/TCustomControl/
TForm)의 `GetContainerWidget`는 GtkScrolledWindow 내부의 GtkFixed
(`FCentralWidget`, `'lcl-scroll-fixed'` 태그)를 반환한다. `LCLFixedLayoutMeasure`
는 이 태그 컨테이너에 대해 **의도적으로 0**을 반환한다(LCL이 스크롤 범위를
자체 관리). 그러나 `TGtk4Widget.preferredSize`가 호출하는 `gtk_widget_measure`는
`MAX(layout측정=0, set_size_request)`를 반환하는데, LCL의 SetScrollInfo/SetBounds
(`gtk4winapi.inc`)가 이 GtkFixed에 **논리클라이언트(뷰포트+수평 range) 크기를
`set_size_request`로 설정**한다. 그 값이 preferredSize를 통해 위젯셋 preferred로
새어나와:

  `WSGetPreferredSize(scrollbox)` = set_size_request(폭주값)
  → `TWinControl.CalculatePreferredSize`
  → `CalculateAutoRanges` (`GetPreferredSize(...,true,false)`)
  → `HorzScrollBar.Range` 증가
  → `GetLogicalClientRect`가 alTop 자식을 Range로 확장
  → 자식이 커지며 `set_size_request` 재증가 → **자기강화 루프**

런타임 계측(`preferredSize`에 임시 로깅)에서 스크롤박스 measuredW가 매 스텝
**+225씩 단조증가하여 33245까지 폭주**하는 것을 직접 포착. qt5는
`gtk_widget_measure`/`set_size_request` 구조가 없어 이 누수가 없음(무발생 설명).

**핵심 반증**: 처음엔 컨테이너 measure(LCLFixedLayoutMeasure)나 LCL 코어
ComputePreferredClientArea를 의심했으나, fresh 값에서도 `FContent.pref=636`(유계)
인데 `scroll.pref=33245`(폭주)로 갈렸다. 임시 로깅으로 33245가 `preferredSize`의
`gtk_widget_measure(scroll-fixed)` 반환값임을 확정 → LCLFixedLayoutMeasure는
0을 반환하지만 `gtk_widget_measure`가 set_size_request와 MAX를 취한 것이 원인.

**수정** (`lcl/interfaces/gtk4/gtk4widgets.pas`, `TGtk4Widget.preferredSize`):
두 `gtk_widget_measure` 호출 직후, CW가 `'lcl-scroll-fixed'` 태그면
`PreferredWidth:=0; PreferredHeight:=0`. **`set_size_request`는 clear하지 않고**
(clear하면 `queue_resize`로 preferredSize↔autosize 무한루프 — 기존 주석 경고)
오염된 **측정값만 무시**한다. WithThemeSpace overflow 보정도 이 태그 컨테이너에
대해선 건너뛰어 preferred가 정확히 0으로 유지되게 함(codex 검토 반영). 이러면
스크롤 컨테이너의 preferred는 LCL의 앵커 인식 `ComputePreferredClientArea`(실제
자식 기준)에서만 나온다. 세로 range(콘텐츠 높이)도 ComputePreferredClientArea가
보존하므로 세로 스크롤은 정상.

**검증**:
- 결정론적 재현(`example_gtk4_autosize_repro`, 40행): 수정 전 **8/8 크래시** →
  수정 후 **0/10** (maxbtnleft 유계, `scroll.pref==content.pref`로 발산 소멸,
  hrange가 실제 콘텐츠 폭을 유계 추종).
- 전체 IDE(`make bigide`) clean 빌드, Xvfb 기동 스모크 예외/크래시 0.
- codex 적대적 검토: 수정 방향·태그 스코프 타당 확인, 지적(WithThemeSpace)
  직접 재검증 후 반영.
- gtk4 고유 수정(qt5/gtk2 무관, 코어/ide 미변경).
- **사용자 실기 GUI 최종 확인 대기**: Tools→Options 반복 리사이즈 크래시 소멸.

---

### (참고) 해결 이전 조사 기록 — 심층 분석 (2026-07-11)
결정론적 재현 하네스: `example_gtk4_autosize_repro/`
(TScrollBox → alTop 패널 → 16행 [늘어나는 콤보(akLeft+akRight) + 우측앵커
'...' 버튼]. 실제 files_options.lfm의 크래시 패턴 미러링.)

확정된 사실:
1. **TScrollBox가 필수 트리거**: `NO_SCROLL=1`(패널을 폼에 직접)이면 크래시
   전무. 스크롤박스 안일 때만 폭주. → alTop/alClient 자식이 스크롤박스의
   **수평 스크롤 범위**로 사이징되고, 그 범위가 우측앵커 자식을 통해 순환.
2. **Qt5는 hrange(HorzScrollBar.Range)=195로 안정**, content.width=뷰포트폭
   추종. gtk4는 content.width가 32795+로 폭주(부모 scroll.client=400인데도).
3. **컨테이너 preferredSize(LCLFixedLayoutMeasure)는 원인이 아님**: 그 measure를
   0으로 만들어(모든 컨테이너 preferred 프로브가 qt5처럼 안정화) 재빌드해도
   크래시 지속. 즉 폭주는 위젯셋 컨테이너 preferred가 아니라 **스크롤박스
   client 크기/범위 경로**에 있음.
4. 크래시는 **타이밍 의존적**(focused 하네스에서 0~3/N 간헐, IDE에선 더 안정적
   재현). preferredSize 프로브는 결정론적.

### 2차 심층 분석 (2026-07-11) — 루프 정밀 국소화, 신뢰 재현 확보

**신뢰 재현 확보**: `example_gtk4_autosize_repro`를 40행(ROWS env) + 매
리사이즈 후 `Disable/EnableAutoSizing` churn으로 강화 → gtk4 **8/8 결정론적
크래시**(이전엔 간헐 0~1/N). 이제 수정 검증 가능.

**크래시 시점 계측(스모킹건)**:
`content.width=32795 content.pref=(636,..) scroll.pref=(33245,..)
scroll.hrange=33020 scroll.clientw=400`
→ FContent 자체 preferred는 **유계(636)**인데 스크롤박스 preferred가 **33245로
폭주**. 즉 스크롤박스가 FContent의 preferred(636)가 아니라 **현재폭(32795)**을 씀.

**정밀 배제**:
- 컨테이너 measure(LCLFixedLayoutMeasure)는 원인 아님: **measure=0으로도
  8/8 크래시**(신뢰재현으로 재확인). offset/intrinsic 실험 2건 폐기(재현율만 올림).
- `getClientRect`는 **이미 뷰포트(FWidget 할당-스크롤바)를 정확히 반환**(코드
  주석대로) → getClientBounds도 뷰포트(~400). getClientBounds가 fixed를
  반환한다는 1차 가설은 오류였음.

**루프 위치**: `TScrollingWinControl.CalculateAutoRanges` →
`GetPreferredSize` → `TWinControl.CalculatePreferredSize` →
`TAutoSizeCtrlData.ComputePreferredClientArea`(**LCL 코어**)가 alTop 자식
FContent의 현재폭(32795)으로 스크롤박스 needed를 계산 → `HorzScrollBar.Range`
폭주 → AlignControls가 alTop 자식을 논리클라이언트(뷰포트+range)로 사이징 →
FContent.Width 증가 → 반복. **유일한 위젯셋 입력(getClientRect=400)은 정확·유계**.

**미해결 이유**: 루프가 전부 **LCL 코어 스크롤박스 autoscroll(qt5와 공유)** 안에
있는데도 qt5는 수렴(hrange=195). 아직 완전히 격리 안 된 미묘한 차이(위젯셋의
어떤 값이 FContent를 논리클라이언트로 키우게 하는지, 혹은 수렴 타이밍)가 남음.
**모든 TScrollBox(IDE 소스에디터 포함)에 영향**을 주는 경로라, 확신 없는 수정은
회귀 위험이 큼 → 이번엔 미수정.

**핵심 코어 게이트(확인)**: `scrollingwincontrol.inc GetLogicalClientRect`는
`ClientRect`에서 시작해 **`HorzScrollBar.Visible AND HorzScrollBar.Range >
ClientRect.Right`일 때만** `Result.Right := HorzScrollBar.Range`로 확장한다.
즉 alTop 자식(FContent)이 뷰포트를 넘어 커지는 조건은 **수평 스크롤바가 visible
이고 Range가 ClientWidth를 넘을 때**뿐. `Range = CalculateAutoRanges의
NeededClientW = TWinControl.CalculatePreferredSize → ComputePreferredClientArea`.
따라서 폭주 여부 = 이 NeededClientW가 수렴(qt5: 636 근처 안정)하느냐 발산
(gtk4: 32795+)하느냐로 갈린다.

**미해결 모순(다음 세션의 첫 계측 대상)**: 크래시 시점 `FContent.GetPreferredSize=
636`(유계)인데 스크롤박스 NeededClientW는 33245(발산). FContent가 alTop이라
그 폭은 부모가 정하므로 스크롤박스 NeededClientW는 FContent.pref(636)를 써야
하는데 실제로는 FContent.CurrentWidth(32795)를 쓰는 것으로 보임. 이 636 vs 32795
불일치의 정확한 지점(ComputePreferredClientArea가 alTop 자식에서 preferred가
아닌 current bounds를 참조하는지, 혹은 FContent의 WSGetPreferredSize가 실제로는
32795를 반환하는데 캐시로 636이 찍혔는지)을 **루프 내부 런타임 로깅**으로 규명해야
함.

**다음 착수 방향**: 신뢰재현(`AUTOSIZE_REPRO_AUTO=1`, 40행)으로
① 매 반복에서 `HorzScrollBar.Visible/Range`, `FContent.Width`,
`ComputePreferredClientArea`의 NeededClientW를 로깅해 발산 첫 스텝을 포착,
② FContent의 WSGetPreferredSize(위젯셋 fixed measure)가 크래시 시점에 실제
반환하는 값을 로깅(636 vs 32795 규명), ③ 위 게이트에서 gtk4만 스크롤바가
visible/Range 발산하는 원인을 qt5와 대조한 뒤, 위젯셋 측에서 뷰포트 경계를
정확히 보고하도록 최소 수정. **코어(scrollingwincontrol/wincontrol) 및 ide/ 는
수정 금지 — qt5 무발생이 근본원인이 위젯셋임을 증명.**

## 2. GtkLabel 음수 폭 할당 경고 (비치명적)
- 증상: `gtk_widget_size_allocate(): attempt to allocate GtkLabel ... with
  width -9/-13/-15 and height 20/16` 다수. 옵션 대화상자/폼 레이아웃 중 라벨이
  중간 할당 단계에서 음수 폭을 받음. GTK4의 엄격한 할당 assertion이 노출.
- 성격: 비치명적(경고만), 렌더는 복구됨. 세션 이전 빌드에서도 35건 발생.

## 3. Editor Toolbar 옵션 페이지 — WordWrap 라벨 콘텐츠 오른쪽 밀림 (보류)
- 증상: main menu → Options → Editor Toolbar 페이지에서 우측앵커
  "Restore defaults" 버튼과 긴 안내 라벨이 뷰포트 오른쪽으로 밀려나 가짜
  수평 스크롤바가 생기고 화면 밖으로 사라짐.
- 위치: `ide/frames/editortoolbar_options.lfm`의 `lblNoAutoSaveActiveDesktop`
  (WordWrap=True, Anchors=[akTop,akLeft,akRight]). 이 라벨이 **줄바꿈하지 않고
  미줄바꿈 preferred 폭을 보고**하여 스크롤박스(EditorsPanel:TScrollBox)의
  autosize 수평 범위를 팽창시키고, alClient 프레임과 우측앵커 자식을 뷰포트
  밖으로 밀어냄. 폼 폭을 키워도(700/900/1100) 라벨 폭이 같이 커져 항상 초과.
- **성격: GTK4 고유 아님.** 격리 재현(`example_gtk4_autosize_repro/
  toolbarpage_repro.lpr`, editortoolbar_options.lfm 레이아웃 미러링)을 gtk4/qt5
  양쪽으로 빌드해 대조 → **bounds·스크린샷이 픽셀 단위로 동일**. 즉 위젯셋
  결함이 아니라 **autosize 컨테이너 안 WordWrap 라벨의 폭 팽창**이라는 기존
  LCL 코어/LFM 레이아웃 함정. (scroll-fixed preferred 수정 1f82c7f 와도 무관 —
  수정 전/후 동일 확인.)
- **처리: 보류(문서화만, 2026-07-11 사용자 결정)**. 고치려면 LCL 코어(autosize의
  WordWrap 라벨 min-width 처리) 또는 `ide/` LFM 수정이 필요 — gtk4 위젯셋 범위
  밖이며 사용자 승인 전제. 착수 시 gtk4만 고치면 qt5와 동작이 갈리므로 코어/LFM
  레벨에서 다뤄야 함.
- 참고: 같은 페이지의 **버튼 이미지만 나오고 캡션 안 나옴**은 GTK4 고유
  버그였고 이번 세션에 수정됨(a503fa5, `TGtk4Button.getText` 박스 라벨 대칭 처리).

## 향후 작업 시 유의
- **항목 1·2는 GTK4 위젯셋 문제**(Qt5 대조로 확정). 따라서
  `lcl/interfaces/gtk4`에서 고칠 수 있음 — 코어/`ide/` 수정 불필요.
- 유력 원인 후보: GTK4 위젯셋의 `preferredSize`/`getPreferredSize`/measure가
  앵커드 자식 오토사이즈 반복에서 값이 진동/폭주하도록 보고하는 것. 음수 폭
  라벨(항목2)과 위치 폭주(항목1)가 같은 measure 경로의 다른 증상일 가능성.
- 착수 시: Qt5의 `preferredSize` 보고와 GTK4의 것을 같은 옵션 페이지에서
  런타임 비교 → 어느 컨트롤에서 GTK4가 이상 값을 내는지 국소화.
