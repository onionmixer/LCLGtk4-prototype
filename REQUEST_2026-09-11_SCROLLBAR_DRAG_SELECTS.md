# 수정 요청: GtkScrolledWindow 의 스크롤바를 드래그하면 그 마우스 이벤트가 LCL 컨트롤(KMemo)에 전달되어 본문이 선택됨

작성일: 2026-09-11 (같은 날의 ENTRY_RETURN_KEYDOWN, SCROLLFIXED_ALLOCATION 요청과 별개 건)
대상: `lazarus/lcl/interfaces/gtk4/gtk4widgets.pas` — `Gtk4LegacyEventCB` (약 1537–1760행, 설치본 `lcl-gtk4 4.4+dfsg-6`)
증상 출처: tomboy-ng GTK4 (`0.42c+onion5`) 사용자 보고 — "검색과 상관없이 오른쪽 스크롤바를 마우스로 위아래로 크게
움직이면 어느 순간 노트 본문이 선택된 상태가 된다."
재현 키트: `test_entry_return/run_scrollbar_drag.sh`, `test_entry_return/run_scrollbar_drag_trace.sh` (+ `scrollbar_drag.gdb`)

---

## 1. 증상

| | GTK4 | Qt5 |
| --- | --- | --- |
| 세로 스크롤바 썸을 누른 채 위아래로 크게 드래그 | 본문 여러 줄이 **선택**되고 가로로도 스크롤됨 (스크린샷 `2-after-drag`, `3-after-drag2`) | 스크롤만 됨 |

## 2. 증거 (gdb dprintf, `tomboy-ng-gtk4-dbg`, 창 900×700, 세로 스크롤바 x≈892)

```
### KMemo.MouseMove x=892 y=20
### KMemo.MouseDown x=892 y=20        <- 스크롤바 위의 버튼 누름이 KMemo.MouseDown 으로 전달됨
### KMemo.MouseMove x=892 y=110
### KMemo.MouseMove x=892 y=2070      <- 드래그 중 MouseMove 좌표가 스크롤 오프셋을 포함해 커짐
### KMemo.MouseMove x=912 y=9820
### KMemo.MouseMove x=1032 y=12370
### KMemo.MouseMove x=1192 y=9520
### KMemo.MouseMove x=1410 y=5790
### KMemo.MouseUp x=892 y=110
```

- KMemo 는 `MouseDown` 으로 선택을 시작하고 `MouseMove` 마다 선택을 넓힌다(드래그 선택). 포인터가 클라이언트
  밖(x=892)이라 KMemo 의 자동 스크롤도 함께 돈다 → 가로 스크롤까지 움직인다.
- 비교: 본문 안 클릭은 스크롤 전후 모두 `MouseDown x=400 y=260` 으로 정상이다(클라이언트 좌표). 즉 버튼 이벤트의
  좌표 변환은 맞고, 문제는 **스크롤바 위의 이벤트가 컨트롤에 전달된다는 것**이다.
- 드래그 중 `MouseMove` 의 y 가 2070, 9820, 12370 처럼 커지는 것은 별도 점검 대상이다. 값이 (포인터 y + 세로
  스크롤량), (포인터 x + 가로 스크롤량) 과 일치하므로 motion 분기의 `gtk4_widget_translate_coordinates(NativeW,
  AWidget, …)` 가 콘텐츠 크기(스크롤로 이동한) GtkFixed 기준 좌표를 돌려주는 것으로 보인다. 버튼 분기는
  지연 디스패치(`Gtk4DeferredMouseEvents`)를 거치므로 경로가 다르다.

## 3. 원인

`TGtk4Widget.InitializeWidget` 은 `gtk4_event_controller_legacy_new` 를 **CAPTURE 단계**로 `FWidget` 에 붙인다
(주석: "GestureClick doesn't work reliably on GtkWindow with child widgets"). `TGtk4CustomControl` 의 `FWidget` 은
GtkScrolledWindow 이므로, 그 자식인 **GtkScrollbar 위에서 일어나는 press/motion/release 도 capture 단계에서
먼저 이 콜백에 들어와** LCL 마우스 메시지로 배달된다. GTK2 에서는 스크롤바가 별도 GdkWindow 였고 Qt5 에서는
QScrollBar 가 이벤트를 자체 처리하므로 컨트롤이 받지 않는다.

## 4. 수정 제안

`Gtk4LegacyEventCB` 에서 포인터 이벤트(press/release/motion, 필요하면 enter/leave 도)에 대해:

- **A안 (권장):** `wtScrollingWin` 위젯이면 이벤트 위치로 `gtk_widget_pick(AWidget, x, y, GTK_PICK_DEFAULT)` 를 호출해
  얻은 대상 위젯이 GtkScrollbar 이거나 그 자손이면(`gtk_widget_get_ancestor(target, GTK_TYPE_SCROLLBAR) <> nil`)
  LCL 로 배달하지 않고 `False` 를 반환한다(GTK 가 스크롤바를 정상 처리). 드래그 중 포인터가 스크롤바 밖으로
  나가도 GTK 의 스크롤바 제스처가 implicit grab 을 가지므로, "press 가 스크롤바에서 시작했으면 release 까지
  무시" 플래그를 두는 편이 안전하다.
- **B안:** GtkScrolledWindow 의 콘텐츠 영역(뷰포트 allocation, 스크롤바 제외)을 벗어난 press 는 배달하지 않는다.
  overlay 스크롤바(콘텐츠 위에 겹치는 경우)에는 A안이 더 정확하다.
- 함께: motion 분기 좌표가 스크롤 오프셋을 포함하는 현상(§2)을 확인하고, press 분기와 같은 기준(스크롤드
  윈도우/클라이언트 기준)으로 맞춘다. 현재는 드래그 자동 스크롤 시 선택 범위가 실제 포인터와 무관하게 폭주한다.

## 5. 검증

1. `test_entry_return/run_scrollbar_drag.sh <tomboy-ng-gtk4>`: `2-after-drag`, `3-after-drag2` 에 선택 강조가 없어야
   하고 가로 스크롤 위치가 변하지 않아야 한다. Qt5 바이너리로 돌린 결과가 기준선.
2. `test_entry_return/run_scrollbar_drag_trace.sh <tomboy-ng-gtk4-dbg>`: 스크롤바 드래그 중 `KMemo.MouseDown` 이
   찍히지 않아야 한다.
3. 회귀: 본문 클릭/드래그 선택(스크롤 전후), 더블클릭 단어 선택, 마우스 휠, TScrollBox/TTreeView/TSynEdit 의 스크롤바.
4. 같은 세션의 다른 확인 사항(참고): 스크롤 후 본문 클릭 좌표 정상, `Escape` 는 TEdit(`EditFindKeyDown` 27)과
   KMemo(`KMemo1KeyDown` 27) 양쪽에 정상 전달됨 — "Esc 로 검색 패널이 안 닫힘"은 tomboy-ng 에 해당 로직이 없는
   것이라(Qt5 도 동일) LCL 건이 아니다.

## 6. 결과 (2026-09-12, `lcl-gtk4 4.4+dfsg-8`, LCL 커밋 `ba78585`/`ba98e2e`/`24d1d09`, tomboy-ng `0.42c+onion6`)

| 시나리오 | 결과 |
| --- | --- |
| `run_scrollbar_drag.sh` (세로 스크롤바 썸 드래그 2회) | 본문 선택 없음, 가로 스크롤 위치 불변, 세로 스크롤만 이동 (Qt5 와 동일) |
| `run_scrollbar_drag_trace.sh` (gdb) | 드래그 중 `KMemo.MouseDown/MouseMove/MouseUp` 0건 |
| 스크롤 후 본문 클릭 (gdb) | `MouseDown x=400 y=260` 로 전후 동일 (클라이언트 좌표 정상) |
| 회귀: 패널 열기 + PageDown/Ctrl+End, `ubi` 검색(URL+긴 줄), `zebra` 검색(짧은 줄), Enter/KP_Enter/F3/Esc 전달 | 모두 이전 정상 결과와 동일한 digest |

**해결 확인.** (이 절은 tomboy-ng 세션이 파일로만 추가함 — LCL_GTK4 저장소 커밋은 하지 않음.)
