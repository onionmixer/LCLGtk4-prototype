

## 14. Phase 3 상세 설계 — F: 입력 소유 판정, B: ListView 헤더 (2026-09-12, 코딩 전; codex 7차 반영 v2)

Phase 2 = ba98e2e. 둘 다 `Gtk4LegacyEventCB` 의 Phase-1 블록(§12.1-3) 안에서 끝난다.

### 14.1 F — 자손 컨트롤의 입력은 그 컨트롤만 받는다 (v2)

현상(`out_p2`): 자식 위 press/drag 의 motion 이 폼(21행)·스크롤박스/페이지컨트롤(3행)에도 배달된다. 추가 실측(하네스 `button`, 2026-09-12): 런타임
TButton 클릭에서 gtk4 는 **폼이 D1/U1** 을 받고 버튼은 0(`:1691` 의 TButtonControl exit → 조상만 큐잉 → dedup 이 조상에 배달), qt5/gtk2 는 버튼 D1/U1·폼 0.
즉 버튼 이벤트도 "가장 깊은 **큐잉된**" 컨트롤이지 소유자가 아니다(codex 7차 #3).

1. 소유 판정 = 시퀀스 단위, press·release·motion **모두**에 적용(v1 의 "motion 만" 철회 — 버튼/motion 스트림의 수신자가 어긋나면 안 됨):
   `TGtk4Widget` private 필드 `FSeqOtherOwner: Boolean;`(기본 False = 배달, 보수적). 헬퍼:
```pascal
{ True when the GTK target W belongs to an LCL control other than ACtl (a descendant
  control's widget tree): Gtk4WidgetFromGtkWidget (gtk4int.pas:233) = direct 'lclwidget'
  tag or the nearest tagged ancestor, validated against the live registry. nil target or
  no owner -> False (deliver). Note: an untagged subtree parented under a form (popup
  menu popover, gtk4wsmenus.pp:1083) resolves to the form - transient GTK popups are
  not distinguished (same as today). }
function Gtk4TargetOwnedByOther(ACtl: TGtk4Widget; W: PGtkWidget): Boolean;
var
  Owner: TGtk4Widget;
begin
  Result := False;
  if W = nil then Exit;
  Owner := Gtk4WidgetFromGtkWidget(W);
  Result := (Owner <> nil) and (Owner <> ACtl);
end;
```
2. Phase-1 블록 변경(pick 은 `PickW` 에 한 번):
   - PRESS 첫 press 분류: `ACtl.FChromeSeq := ...; ACtl.FSeqOtherOwner := HavePos and Gtk4TargetOwnedByOther(ACtl, PickW);`
     그리고 `if ACtl.FChromeSeq or ACtl.FSeqOtherOwner then exit`(더블클릭 전역 무효화는 chrome 일 때만 — 소유자가 다른 press 는 소유자 컨트롤러가 정상 처리하므로 전역은 그대로).
     → 조상은 큐잉하지 않는다. dedup(`ProcessGtk4DeferredMouseEvents`)은 안전망으로 그대로. `DoFocus` 도 소유자 항목만 남는다(종전: TButton 클릭이
     조상의 DoFocus 항목으로 LCL 포커스를 조상에 옮길 수 있었음).
   - RELEASE: `Latched := ACtl.FChromeSeq or ACtl.FSeqOtherOwner`; 마지막 버튼에서 둘 다 False; `if Latched then exit`.
   - MOTION:
```pascal
        Captured := (Gtk4CapturedWidget <> nil) and (Gtk4CapturedWidget = ACtl.GetContainerWidget);
        if BtnState <> [] then
        begin
          if ACtl.FChromeSeq then exit;
          if ACtl.FSeqOtherOwner and not Captured then exit;
        end
        else if HavePos then
        begin
          PickW := gtk4_widget_pick(AWidget, PX, PY, GTK_PICK_DEFAULT);
          if Gtk4IsChromeTarget(PickW, AWidget) then exit;
          if not Captured and Gtk4TargetOwnedByOther(ACtl, PickW) then exit;
        end;
```
     **캡처 우회**(codex 7차 #1): LCL `SetCaptureControl(부모)`(예: 디자이너 `designer.pp:2275` 의 `SetCaptureControl(ParentForm)`, 자식 MouseDown 에서 부모를
     캡처하는 사용자 코드)는 위젯셋이 `Gtk4CapturedWidget := GetContainerWidget`(`:3968`)로만 기록하고 라우팅하지 않으므로, 캡처 컨트롤의 컨트롤러는
     소유와 무관하게 motion 을 배달한다(오늘의 "누출"이 캡처를 구현하고 있던 부분을 보존). 자식(소유자)도 종전대로 받는다(win32 는 캡처 컨트롤만 받지만
     현재 상태 유지 — 축소 없음). press/release 는 캡처와 무관(시퀀스 시작·종료; 캡처 컨트롤이 release 를 못 받는 것은 종전과 같은 한계, 아래).
3. **디자인 모드**(codex 7차 #2): `csDesigning in ACtl.LCLObject.ComponentState` 이면 chrome 판정(스크롤바·헤더)을 하지 않는다 — 디자이너는 헤더/스크롤바 클릭으로
   컨트롤을 선택·이동해야 하고(`:1691` 의 TButtonControl 예외와 같은 이유), Phase 1 이 디자이너에서 스크롤바 클릭 선택을 막고 있던 것도 함께 복원.
   F 는 디자인 모드에도 적용(자식의 자기 메시지가 `Designer.IsDesignMsg` 로 가고, 폼은 캡처 우회로 motion 을 받는다).
4. 성질/한계
   - TGraphicControl·합성 위젯 내부·드래그가 컨트롤 밖으로 나가는 경우·부모에서 시작한 드래그: v1 과 같음(§6.3).
   - 런타임 TButtonControl: 버튼은 종전대로 press 를 받지 않고(`:1691`, OnClick 은 'clicked'), 조상도 이제 받지 않는다(qt5/gtk2 의 "폼 0" 과 일치;
     "버튼 D1" 은 gtk4 의 기존 한계로 기록 — 후보 P).
   - 캡처 컨트롤(부모)이 자식 press 의 release 를 받지 못하는 것은 종전과 같다(dedup 이 자식 항목을 택함; win32 는 캡처 컨트롤이 받음) — 후보 Q.
   - `button` 실측의 부수 발견: TButton 의 motion 좌표가 (283,195) 로 qt5/gtk2 (300,200) 와 (17,5) 어긋남 — `getClientOffset` 이 버튼 내부 라벨(중앙 위젯)을
     원점으로 삼기 때문. 이 요청 범위 밖(스크롤·chrome 무관), 후보 O 로 기록.

### 14.2 B — ListView 헤더(GtkColumnView header) 를 chrome 으로

현상(`out_p2` listview/header): gtk4 는 헤더 press 를 D1(100,8)·M5·U1·C1 로 배달, qt5 는 배달 없음(정렬은 sorter 시그널 → `CN_NOTIFY/LVN_COLUMNCLICK :10894`), gtk2 는 motion 만.
GTK 4.6.9 `gtkcolumnview.c:1279-1282`: 헤더 = `gtk_list_item_widget_new(NULL, "header", ROW)`, `gtk_widget_set_parent(self->header, self)` 가 listview(`:1317`)보다
먼저 → GtkColumnView 의 **첫 자식**(DnD 는 헤더 안에서 제목을 재배치, `:1139`, 첫 자식 불변). `Gtk4IsChromeTarget` 확장(바인딩 추가 없음, `g_type_name_from_instance` 는 `:2423` 과 같은 용법):
```pascal
    P := gtk_widget_get_parent(W);
    if (P <> nil) and (g_type_name_from_instance(PGTypeInstance(P)) = 'GtkColumnView') and
       (W = gtk4_widget_get_first_child(P)) then Exit(True);   { column header row }
```
   런타임에만(§14.1-3): 헤더 press/release/버튼 든 motion/hover 미배달; 정렬 클릭·열 폭 조절·헤더 DnD 는 GTK 가 처리(종전과 같음). B''(client 원점이 헤더 포함)는 범위 밖.

### 14.3 게이트 (§7.1 Phase 3)
- `analyze.py --gate` v7(+`button`): 기존 규칙 + `listview/header` chrome 규칙 + `button/client`: 폼 D0M0U0(대상 D 는 요구하지 않음, 후보 P) → **실패 0**.
- 키 행렬 300/300, 할당 행렬 strict 0 + P2 와 차이 0, tomboy-ng 4 시나리오 digest 불변.
- 실기(§7-4, 디자인 모드는 하네스가 못 봄): 디자이너에서 TScrollBox 스크롤바·TListView 헤더 클릭으로 선택, 컨트롤 드래그 이동·러버밴드·그래버 리사이즈, 스플리터 드래그,
  자식 MouseDown 에서 `SetCaptureControl(Parent)` 하는 코드(있다면), 그룹박스 안 TLabel 힌트, 런타임 ListView 열 정렬 클릭·열 폭 조절, TButton 클릭 뒤 포커스.

### 14.4 codex Phase-3 판정 (`codex_mouse/review7.md` v1 대상, `review8.md` v2 대상; gpt-6-astra, 모두 소스 대조)

| # | 주장 | 대조 | 처리 |
|---|---|---|---|
| 50 | (7차, must-fix) 자식 MouseDown 에서 `SetCaptureControl(부모)` 한 부모의 motion 을 F 가 끊는다; 디자이너도 `SetCaptureControl(ParentForm)`(`designer.pp:2275`); 위젯셋 캡처는 기록만(`:3968`), qt5 는 `grabMouse` | `controls.pp:3515-3555`, `designer.pp:2275`, `:3952-3990`(seat grab 은 surface 라우팅만; `gtkmain.c:1405` 대상은 implicit grab/pick) 확인 | **채택**: 캡처 컨트롤의 컨트롤러는 소유와 무관하게 motion 배달(§14.1-2) |
| 51 | (7차, must-fix) 헤더 chrome 이 디자인 모드에서 TListView 선택/드래그 시작을 막음(`:1649` 의 exit 가 `IsDesignMsg` 보다 앞) | `control.inc:2248` 확인; Phase 1 의 스크롤바 규칙도 같은 문제 | **채택**: 디자인 모드는 chrome 판정 제외(스크롤바 포함, §14.1-3) |
| 52 | (7차, should-fix) 런타임 TButtonControl 은 자기 press 를 큐잉하지 않아(`:1691`) 조상이 dedup 으로 press/release 를 받는데 F(v1)는 motion 만 끊어 스트림이 어긋남 | 하네스 `button` 실측: gtk4 폼 D1/U1, qt5/gtk2 폼 0 | **채택**: 소유 판정을 press/release 에도 적용(v2) |
| 53 | (7차, note) 태그 없는 팝오버(팝업 메뉴, `gtk4wsmenus.pp:1083`)는 조상 walk 로 폼이 소유자 | `gtk4int.pas:261` 확인 | 문구 정정(헬퍼 주석) |
| 54 | (8차, must-fix) v2 에서 조상이 큐잉하지 않으면 런타임 버튼 press 가 더블클릭 이력을 갱신하지 않음(버튼 자신은 `:1691` 에서 카운팅 전에 exit) → A 클릭·버튼 클릭·A 클릭(400ms 내)이 더블클릭 | `:1691` 이 `:1725` 카운팅보다 앞 확인 | **채택**: TButtonControl exit 에서 press 면 이력 무효화 |
| — | (자체 검증) 소유 오라클: `SetProp('lclwidget')`(`gtk4winapi.inc:5005-5013`)이 FWidget 과 컨테이너 **둘 다** 태깅 → 스크롤바/프레임 라벨 같은 비중앙 영역도 자기 wrapper 로 해석됨 | 확인 | v2 그대로 |

| 55 | (하네스 판정, codex 아님) Phase-3 뒤 `synedit/contentdrag` 에서 폼이 release 직전 **버튼 없는** motion 1회를 받음(`out_p3` 9372: `TMain Move x=680 y=220 btn=False`, 포인터는 이미 컨트롤 밖 폼 위) | 행 31/41 과 같은 GTK 합성 motion; 버튼 마스크가 비어 hover 경로 → fresh pick = 폼 자신 = 정당한 hover | **게이트 v7 로 수용**: client/contentdrag 행의 폼·조상은 버튼 0·버튼 든 motion 0·버튼 없는 motion ≤1 |

### 14.5 Phase 3 결과 (2026-09-12)

코드는 §14.1 v2 + §14.2 + 행 54(`./cbuild inc` 에러 0).

| 게이트 | 결과 |
|---|---|
| 마우스 행렬 gtk4(`button` 포함 18 컨트롤) → `analyze.py --gate` v7(`out_p3/`) | **0 실패**. 같은 v7 규칙으로 P0 80 → P1 52 → P2 28 → P3 0(P0–P2 는 `button` 로그가 없어 4건씩 포함) |
| 확인 행 | `button/client`: 폼 D0M0U0(P2: 폼 D1M4U1), 대상 D0(P); `listview/header`: D0·버튼 든 M0·U0(P2: D1M5U1); scrollbox/pagecontrol client 의 조상 이벤트 0; 21개 폼 motion 행 0 |
| 키 행렬 gtk4 순차(단독) | 300/300 unchanged vs Phase 2 |
| 할당 행렬 `rungate.sh _P3` | strict exit 0, `compare.py out_fixed_P2 out_fixed_P3` 0 differing rows |
| tomboy-ng 격리 빌드(Phase 3) | drag 2/3-after-drag 5b49f5d9/f2f39683(불변), trace 프로브 3·발화 0, scroll_blank 10/10, 검색 5/5 + 핸들러 동일 |
| 실기 대기 | §14.3 의 디자인 모드 항목(하네스 범위 밖) |
