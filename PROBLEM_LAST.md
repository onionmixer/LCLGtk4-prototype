# LCL GTK4 아이콘 미표시 최종 분석 (현재 시점)

> **✅ 해결됨 (2026-07-11 확인).** 이 문서에 기술된 근본원인(마스크 없는 케이스에
> 투명 A8 마스크를 생성해 `StretchMaskBlt`가 이미지를 전부 투명 처리)은 커밋
> **`de4145d` "Fix invisible toolbar/palette icons caused by spurious transparent mask"**
> 에서 이미 해결되었다. `RawImage_CreateBitmaps`의 마스크 생성이 `NewData <> nil`
> (현재 코드 `gtk4lclintf.inc:456` `if (ARawImage.Mask <> nil) and (ARawImage.MaskSize > 0)`)로
> 가드되어 마스크 없는 이미지는 `cairo_paint` 무마스크 경로를 탄다. 실기에서 IDE
> 툴바/팔레트/About 아이콘이 모두 표시됨을 사용자가 확인. 아래 내용은 이력 보존용.

---


## 현상
- 메뉴가 있는 Lazarus IDE 창에서 툴바/컴포넌트 팔레트 아이콘이 표시되지 않음.
- `Help -> About Lazarus` 모달의 `Version` 탭에서도 이미지가 표시되지 않고, 이미지가 있어야 할 작은 영역만 보임 (`report_04.png`의 붉은 박스).
- 동일 IDE 코드가 GTK2/Qt5에서는 정상 동작.

## 로그 관찰 (`error_59` ~ `error_64`)
- 아이콘 경로를 직접 가리키는 런타임 에러/크래시는 없음.
- 반복적으로 보이는 유의미 항목은 아래 1건:
  - `GLib-CRITICAL: g_regex_match_full: assertion 'string != NULL' failed`
- 결론: 본 문제는 로그 기반 예외가 아니라 GTK4 LCL 내부 렌더링/마스크 처리의 무음(silent) 실패 성격.

## 현재까지 확인된 핵심 원인

### 1) 마스크가 없는 경우에도 `AMask`가 생성되는 경로
- 파일: `lazarus/lcl/interfaces/gtk4/gtk4lclintf.inc`
- 함수: `TGtk4WidgetSet.RawImage_CreateBitmaps`
- 구간: `if ASkipMask then Exit;` 이후 마스크 생성 코드
- 문제:
  - `ARawImage.Mask = nil`이어도 `NewData := nil` 상태로
    `TGtk4Image.Create(..., CAIRO_FORMAT_A8, True)`를 호출해 `AMask`를 생성함.

### 2) `NewData=nil` A8 마스크 생성 시 완전 투명(0)으로 초기화
- 파일: `lazarus/lcl/interfaces/gtk4/gtk4objects.pas`
- 생성자: `TGtk4Image.Create(AData..., bytesPerLine..., format...)`
- 문제:
  - `FData=nil` 경로에서 `gdk_pixbuf_fill(FHandle, 0)` 실행.
  - `CAIRO_FORMAT_A8` 기준 alpha 0 마스크가 만들어짐(완전 투명).

### 3) 그 마스크가 실제 블릿 단계에서 강제 적용됨
- 파일: `lazarus/lcl/interfaces/gtk4/gtk4winapi.inc`
- 함수: `TGtk4WidgetSet.StretchMaskBlt`
- 문제:
  - `Mask <> 0`이면 마스크 경로(`cairo_mask_surface`)를 사용.
  - 완전 투명 마스크가 들어오면 원본 이미지가 사실상 전부 사라짐.

## 증상과 원인 매칭
- “이미지 영역은 잡히지만 내부 픽셀이 안 보임”은 위 1~3 경로와 정확히 일치.
- 즉, 이미지 로딩 실패가 아니라 **마스크 적용 로직이 이미지를 투명 처리하는 구조적 문제**.

## 추가 관찰 (부원인 후보)
- 8bpp/팔레트 변환 경로에서도 색상 해석 문제가 있을 수 있어 일부 보정 작업을 진행했으나,
  현재 가장 치명적인 주원인은 “기본/빈 마스크 생성 -> 투명 마스크 적용” 경로임.

## 최종 결론
- IDE 코드는 원인이 아님.
- GTK4 LCL의 `RawImage_CreateBitmaps -> TGtk4Image(A8) -> StretchMaskBlt` 연계에서
  **마스크가 없어야 할 케이스까지 투명 마스크를 만들어 적용하는 로직**이
  툴바/About 이미지 미표시의 핵심 원인.
