# GTK4 WS Class Implementation Analysis

Comparison of GTK4, GTK2, and Qt5 widgetset implementations.
Generated: 2026-03-06, Updated: 2026-07-02 (Sessions 61-75. Session 75: **X11 override-redirect 팝업** (코드 완성 팝업 위치/사라짐 수정 — GTK4가 제거한 gtk_window_move+GTK_WINDOW_POPUP 대체): TGtk4Window.PreparePopupShow/RaiseX11Popup + XChangeWindowAttributes/XRaiseWindow 바인딩(TX11SetWindowAttributes+X11_CWOverrideRedirect), Gtk4FormIsPopup(csNoFocus 또는 bsNone+stayOnTop; 일반 THintWindow 제외 — OR 툴팁 pointer enter/leave 루프=팔레트 hover 깜박임 방지), Wayland는 transient_for 폴백. **디자인 모드 입력 라우팅**: Gtk4DesignKeyPressedCB(CAPTURE 단계 키 컨트롤러 — 선택 위젯에서 Delete가 컴포넌트를 삭제하도록; 네이티브 GtkText의 TARGET 단계 키 선점을 우회, 런타임 no-op), 디자인 모드 클릭 시 상태 변경 방지 csDesigning 가드 6종(Gtk4Toggled 체크/라디오, Gtk4EntryChanged 스핀, 콤보 3콜백, Gtk4RangeChanged 트랙바, Gtk4Calendar* 캘린더, 리스트/체크리스트/리스트뷰 4콜백; 노트북 switch-page는 의도적 유지). 커밋 bc63c63. Session 74: **좌표계 화면 절대좌표화** (X11): ClientToScreen/ScreenToClient/GetCursorPos가 Gtk4X11GetWindowOrigin+gtk4_native_get_surface_transform로 화면 절대좌표 반환(팝업 SetBounds 위치 기반). **SetMaxSize CSS max-width/max-height 제거** (GTK4 미지원 GTK3 전용 속성, FMaxCssProvider 삭제; 최대크기는 X11 WM_NORMAL_HINTS+notify::default-size 스냅백으로만). 커밋 fa64186. Session 73: **ScrollBar 수정** (GtkScrolledWindow/GtkViewport): getClientRect가 GtkFixed 대신 viewport 크기 반환, LCLGtkFixedSnapshot cairo_translate로 GtkViewport 물리 스크롤 상쇄(SW 스크롤과 중복 방지), SetScrollInfo content_size 보정. Session 72: **SynEdit 한글 IME + 캐럿 가시성/깜박임** 수정 (커밋 7ce7771). Session 71: **GtkFixed snapshot vfunc 패치** (PatchGtkFixedSnapshotClass — LCL 커스텀 페인팅이 자식 위젯보다 먼저 렌더링되도록 z-order 수정 → OI 내장 에디터 TEdit/TComboBox 가시성), Entry 타이트 레이아웃 CSS, SetBorderStyle 배선. Session 70: **PrintOperation 다이얼로그 통합**: printersdlgs.pp에 `{$IFDEF LCLGtk4}` 조건 추가 → 기존 gtk4prndialogs.inc (426줄, 네이티브 GtkPrintOperation/PageSetup 다이얼로그) 활성화. CUPS 프린터 백엔드는 GTK2와 동일하게 폴스루 사용. finalization 섹션 추가 (Gtk4StoredPrintSettings/PageSetup 해제). 조사 결과: lazgtk4.pas에 127개 인쇄 바인딩 이미 존재, 다이얼로그 구현 이미 완료 — 누락된 것은 printersdlgs.pp 연결뿐이었음. **SelectionModel/Filter 바인딩 완료**: lazgtk4_compat.pas에 GtkFilter/GtkCustomFilter/GtkFilterListModel/GtkSortListModel/GtkSorter 바인딩 22개 함수 + enum 5개 + 콜백 타입 추가. **Drag & Drop 바인딩 완료**: lazgtk4_compat.pas에 42개 DnD 함수 바인딩 (GtkDragSource 8, GtkDropTarget 6, GtkDropTargetAsync 4, GdkDrop 10, GdkDrag 7, GdkContentProvider 1, GdkContentFormats 5, gtk_drag_check_threshold 1) + 타입 4개. 인트라앱 DnD+파일 드롭 이미 동작, DragImageList는 Wayland 제한. **GtkShortcutController 완성**: 기존 8개 + S70 추가 10개 (trigger parse_string/mnemonic/alternative/never, action signal/named/nothing/mnemonic, set_mnemonics_modifiers) = 총 18개. **Gesture 바인딩 완료**: 생성자 6종 (Drag/LongPress/Swipe/Rotate/Zoom/Stylus) + 헬퍼 5개 + GestureSingle 3개 = 14개. **GtkExpression 바인딩 완료**: 생성자 3개 + evaluate/watch/bind/ref 등 11개 + PGtkExpressionWatch 타입. **열 헤더 컨텍스트 메뉴**: 이미 바인딩 확인. **GdkTexture/MemoryTexture 바인딩 완료**: 9함수+TGdkMemoryFormat enum (get_width/height, download, save_to_png/png_bytes, memory_texture_new, new_from_file/filename/resource). **ANAYLIZE 전체 바인딩 카테고리 완료** — 모든 §23b 항목 바인딩 완료 또는 이미 동작 확인. Session 69: **TGtk4ScrollBar.DetachEvents** (Adjustment value-changed 자식 GObject 시그널 해제), **콜백 안전성 13건 추가** (Gtk4CloseRequestCB, Gtk4ListBoxSelectionChanged, Gtk4LB_SelectionChanged, Gtk4CLB_FactoryBind/CheckToggled, Gtk4CV_CheckToggled/SelectionChanged/SorterChanged, Gtk4WS_ListViewItemSelected/ItemCheckedChanged, Gtk4MemoBufferInsertText, Gtk4WindowVScrollPinCB/HScrollPinCB). **IMContext pre-edit 구현**: preedit-start/end/changed 시그널 연결, LM_IM_COMPOSITION 메시지 전달, gtk_im_multicontext_new (시스템 IM 자동 선택), 포커스 아웃 시 reset. **IMContext set_cursor_location**: SetCaretPosEx에서 캐럿 위치 변경 시 IMContext^.set_cursor_location 호출 (CJK 후보창 커서 추적), IMContext public property 추가. **GTK4 Accessibility 구현**: TGtk4WSLazAccessibleObject 8/8 메서드 (CreateHandle/SetName/SetDescription/SetValue/SetRole/SetPosition/SetSize), RegisterWSLazAccessibleObject 활성화, GTK4 Accessible API 6함수+4enum 바인딩. Session 68: **Gtk4ScrollCB 버그 수정** (modifier key 상태 미추출 → `GdkModifierStateToShiftState(gdk4_event_get_modifier_state())` 추가, CSD 좌표 오프셋 미적용 → `gtk4_native_get_surface_transform` + `gtk4_widget_translate_coordinates` 적용). **레거시 데드코드 제거 ~420줄**: `Gtk4WidgetEvent` 전체 (~210줄, GTK3 opaque GdkEvent 접근=GTK4 크래시, 미연결 콜백), `GtkEventMouseWheel` (선언+구현+호출 42줄), `Gtk4ScrolledWindowScrollEvent` (미연결 67줄), `SubtractScroll` (미호출 12줄), `GtkEventResize` (선언+구현, 유일한 호출자=Gtk4WidgetEvent 12줄), `Gtk4ActivateWindow` (선언+구현, 동일 32줄), `Gtk4EventToStr` (GTK3 이벤트 열거 47줄, 유일한 호출자=Gtk4WidgetEvent). **Calendar GtkFrame 불필요 래핑 제거**: TGtk4Calendar.CreateWidget에서 빈 GtkFrame 래퍼 삭제 → GtkCalendar를 FWidget으로 직접 반환. FCentralWidget 미사용 → DetachEvents override 불필요 → 삭제. 시그널은 이제 FWidget에 직접 연결되어 base DestroyWidget이 자동 해제. **런타임 안전성 수정 (15건)**: g_idle_remove_by_data 오용 2건(PostMessage+BackNoteBook), TGtk4MemoStrings 타이머 미해제(g_source_remove 추가), Gtk4WindowAfterPaintCB Gtk4IsWidget 검증, 콜백 Gtk4IsLiveWidgetPointer 검증 12건(ComboBox 5+DropDown 1+Entry 1+Range 1+ListView Column 1+Toggle 1+Calendar 3+ScrollAdj 1 — 자식 GObject 시그널 콜백 전수 점검). **Pixbuf 메모리 누수 8건 수정**: Gtk4BitmapToPixbuf 반환 pixbuf g_object_unref 누락 전수 수정(menus/buttons/page/CV/GV/TreeView/ColumnHeader). **CSSProvider 누수**: ColumnView per-cell CSSProvider g_object_set_data→g_object_set_data_full(@g_object_unref). **WSCheckHandleAllocated 오류 문자열 3건 수정**: SetCaretPos, SetNumbersOnly, UpdateProperties. `result`→`Result` 대소문자 2건 수정. Session 67: **TGtk4WSWinControl.CreateHandle 구현** (STUB→IMPL, TGtk4Panel 범용 컨테이너), 비가드 DebugLn 4건 `{$IFDEF GTK4DEBUGCORE}` 가드 추가, 잔여 주석코드 정리 ~20줄 8파일, SetFormStyle ANAYLIZE 오보정 수정, **시그널 안전성 3건** DetachEvents 추가 (TGtk4Widget base — FIMContext 'commit' 해제+unref, TGtk4Memo — PGtkTextBuffer 'insert-text', TGtk4Calendar — FCentralWidget 6 시그널). 주석 `// DebugLn()` **~103줄** 삭제 (12파일), gtk4wsfactory.pas 주석 등록 14줄 삭제, gtk4private.pas 주석 선언 5줄 삭제, gtk4widgets.pas 오래된 서명 주석 1줄 삭제. **코드 품질 스윕 완료**: 0 경고, Notes=inline-not-inlined만, Hints=WS 파라미터만. Session 66: 주석 처리된 코드 정리 **~90줄** 15파일 — gtk4widgets.pas(GTK3 색상 override, 미사용 타입/변수/조건, 주석코드 5건), gtk4wscomctrls.pp(// inherited 20건), gtk4wsfactory.pas(GTK2 RegisterWSComponent 16건), gtk4boxes.pas(GTK2 변수/주석 10줄), gtk4cellrenderer.pas(미사용 변수/주석), gtk4winapi.inc(미사용 변수/주석/RGN_DIFF 데드 주석), gtk4lclintf.inc(주석코드 2건), gtk4wsdialogs.pp(미사용 absolutevar), gtk4wssplitter.pas(주석코드 2건), gtk4object.inc(주석코드), gtk4wsimglist.pp(주석코드), gtk4wscalendar.pp(GTK2 클래스명), gtk4wstrayicon.pas(중첩 주석 경고 3건), gtk4wscontrols.pp(미초기화 변수), ANAYLIZE 문서 오보정 수정(RGN_DIFF 완전, RawImage 정리완료, CheckListBox 범위검사/데드코드 완료). Session 65: 메모리 누수 4건 수정 + 미사용 유닛 30건 제거 + 미사용 변수 5건 제거 + **시그널 안전성 6건** DetachEvents 추가 (TGtk4ScrollableWin (base), TGtk4ComboBox, TGtk4DropDown, TGtk4ListBox, TGtk4ListView — adjustment/FSelectionModel/FEntry/FButton/FPopover/FFactory/CVSorter 시그널 해제). 누수: gtk_css_provider_to_string, pango_font_description_from_string(2), gtk_font_chooser_get_font. Session 64: 데드코드 정리 **~120줄** 7파일 — SetScrollInfo GTK2 UpdatePolicy 27줄, gtk4boxes GTK2 StockImage 26줄, GetRawImageFromDevice GTK2 Drawable 24줄, gdk_drawable_get_size 7줄, ComboBox Enter/Leave 디버그 30줄, ShowScrollBar 디버그 6줄, FontDialog/ColorDialog/FileDialog GTK2 주석, RadioButton GTK2 get_group, gtk4private WidgetInfo 주석. 오보정 3건: SetSelText (base class 구현), SelectDirectoryDialog (LCL dispatch 정상), Repaint (S61 수정 미반영). **TRUE GAPS: 0** — 모든 gap 해결됨. Session 63: ~400줄 8파일. Session 62: 다수 수정. Session 61: 20건 수정+4건 오보정+4건 구현+~300줄 삭제.)

Legend:
- `IMPL` = Fully implemented
- `IMPL*` = Implemented but with quality issues (see §22 notes)
- `STUB` = Declared but stub/no-op body
- `MISS` = Not declared (missing override)
- `N/A` = Not applicable / not implemented in reference either

---

## 1. WSButtons

### TWSBitBtn

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | MISS | MISS |
| SetGlyph | IMPL | IMPL | IMPL |
| SetLayout | IMPL | IMPL | IMPL |
| SetMargin | IMPL | IMPL | IMPL |
| SetSpacing | IMPL | IMPL | IMPL |
| SetText | MISS | IMPL | MISS |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |

**GTK4 gaps**: SetText, SetColor, SetFont (GTK2 has these, Qt5 does not — likely handled by TWSWinControl base)
**GTK4 품질 이슈**:
- `SetGlyph`: RebuildButtonChild가 SetLayout/SetMargin/SetSpacing 매 호출 시 GtkBox+GtkImage+GtkLabel **전체 재생성** — 포인터 캐싱 없음
- ~~`SpeedButton`~~: **오보정** — TGraphicControl (non-windowed), WS 구현 불필요. GTK2/Qt5/Win32도 동일 빈 클래스

#### TWSBitBtn 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | `TGtk4Button.Create` 래퍼 (11줄) | `gtk_button_new` + show + size_allocate + g_object_ref | `TQtBitBtn.Create` + AttachEvents | 완전 |
| GetPreferredSize | `TGtk4Button.preferredSize()` 위임 | MISS | MISS | ✅ GTK4 고유 |
| SetGlyph | `gtk_image_new_from_pixbuf` + GtkBox(H/V) 구성 (**90줄**, 4방향 레이아웃 분기) | `gtk_image_new` + gtk_box_pack_start/end (**유사 복잡도**) | `QIcon_addPixmap` + `setIcon` (**단순**) | 완전 (GTK4≈GTK2 복잡도, Qt5가 단순) |
| SetLayout | `RebuildButtonChild` → **GtkBox 전체 재생성** | `BuildWidget` → 유사 재생성 | `Update` → 단순 리렌더링 | ⚠️ 비효율 (재생성 vs Qt5 리렌더) |
| SetMargin | `RebuildButtonChild` → 재생성 | `gtk_alignment_set_padding` **직접 API** | `Update` | ⚠️ GTK2보다 비효율 (GTK4에서 GtkAlignment 제거) |
| SetSpacing | `RebuildButtonChild` → 재생성 | `gtk_box_set_spacing` **직접 API** | `Update` | ⚠️ GTK2보다 비효율 (재생성 vs 직접 API) |

---

## 2. WSCalendar

### TWSCustomCalendar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | MISS | IMPL | MISS |
| GetDateTime | IMPL | IMPL | IMPL |
| HitTest | IMPL | IMPL | IMPL |
| SetDateTime | IMPL | IMPL | IMPL |
| SetDisplaySettings | IMPL | IMPL | IMPL |
| SetFirstDayOfWeek | STUB | MISS | IMPL |
| SetMinMaxDate | IMPL | MISS | IMPL |
| RemoveMinMaxDates | IMPL | MISS | IMPL |
| GetCurrentView | MISS | MISS | MISS |
| GetPreferredSize | IMPL | IMPL | MISS |

**GTK4 gaps**: DestroyHandle (GTK2 has custom cleanup)
**ALL MISS**: GetCurrentView (base returns cvMonth — adequate default)
**GTK4 IMPL* 이슈**:
- ~~`SetDateTime` 🔴 **BUG**~~: ✅ **수정됨 (Session 61)** — `SetDate(Year, Month - 1, Day)`로 교정 (gtk4wscalendar.pp:291). ClampDate(5692)와 동일한 0-based 변환 적용
- `SetFirstDayOfWeek`: GTK4 GtkCalendar는 로케일 기반만 — API 부재 (의도적 stub)
- ~~`GetPreferredSize`~~: ✅ **수정됨 (Session 61)** — preferredSize 래퍼 위임으로 구현 (gtk4wscalendar.pp:328-333)
- ~~month/year/day 변경 콜백 미등록~~: ✅ **수정됨 (Session 62)** — day-selected/month-changed/next-month/prev-month/next-year/prev-year 6개 시그널 연결, LM_DAYCHANGED/LM_MONTHCHANGED/LM_YEARCHANGED 메시지 전달

#### TWSCustomCalendar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **39줄** (gtk4wscalendar.pp:113-151) WS: `TGtk4Calendar.Create` 래퍼 + 래퍼 **9줄** (gtk4widgets.pas:5623-5631): `GtkCalendar.new` → GtkFrame 래핑 → day-selected 시그널 연결. **총 48줄** | `gtk_frame_new` + `gtk_calendar_new` + `gtk_container_add` + size_request (~33줄) | `TQtCalendar.Create` + AttachEvents | 완전 — WS 코드가 길지만 필터/시그널 설정 포함 |
| GetDateTime | **15줄** (gtk4wscalendar.pp:153-167): `TGtk4Calendar.GetDate` → EncodeDate. 0-based month 올바르게 **+1** 처리 | `gtk_calendar_get_date` 직접 | `DateTime` 프로퍼티 | 완전 |
| SetDateTime | **9줄** (gtk4wscalendar.pp:284-292): `TGtk4Calendar.SetDate(Y,M-1,D)` — ✅ **수정됨 (Session 61)** | `gtk_calendar_select_month(M-1)` + `select_day(D)` | `DateTime` 프로퍼티 | ✅ 완전 |
| HitTest | **114줄** (gtk4wscalendar.pp:169-282): `gtk4_widget_pick` + `g_type_name` + GObject 프로퍼티 쿼리 (현대적 위젯 트리 순회). GtkLabel/Button 타입 분기 → pchCalTitle/pchWeekday/pchWeek/pchDayNumber 판정 | **~84줄**: GtkCalendarPrivate **직접 구조체 접근** (취약) | `TQtCalendar.HitTest` 위임 | ✅ GTK4 > GTK2 (안전한 공개 API 사용) |
| SetDisplaySettings | **30줄** (gtk4wscalendar.pp:294-323): `g_object_get_property` + SetBoolProperty 헬퍼. **GObject 프로퍼티 패턴**: `show-heading`, `show-week-numbers`, `show-day-names` 개별 설정 | `gtk_calendar_display_options` + **g_timeout_add 워크어라운드** (타이밍 이슈) | `setHorizontalHeaderFormat` + `setVerticalHeaderFormat` 열거형 | ✅ GTK4 > GTK2 (워크어라운드 불필요) |
| SetFirstDayOfWeek | **STUB** (gtk4wscalendar.pp:335-340) — GtkCalendar 로케일 기반만 (API 부재) | MISS | `QLocale` + SetFirstDayOfWeek **완전** | ❌ GTK4 제한 (Qt5만 동작) |
| SetMinMaxDate | **6줄** WS (gtk4wscalendar.pp:342-347) + 래퍼 **14줄** `TGtk4Calendar.SetMinMaxDate` (gtk4widgets.pas:5699-5712 ~~5685-5698~~ R32 정정): `day-selected` 시그널 콜백으로 클램핑 — `ClampDate`에서 범위 이탈 시 `SetDate(Y, M-1, D)` 강제 | MISS | min/max DateTime 프로퍼티 | ✅ GTK4 > GTK2 (GTK2 미구현) |
| RemoveMinMaxDates | **6줄** (gtk4wscalendar.pp:349-354): 시그널 해제 + min/max 클리어 | MISS | min/max 리셋 | ✅ GTK4 > GTK2 |
| GetPreferredSize | **6줄** (gtk4wscalendar.pp:328-333): ✅ **S61 구현** — `TGtk4Widget.preferredSize` 래퍼 위임 | `GetGTKDefaultWidgetSize` | MISS (상속) | ✅ 완전 |

---

## 3. WSCheckLst

### TWSCustomCheckListBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetItemEnabled | IMPL | IMPL | IMPL |
| GetState | IMPL | IMPL | IMPL |
| SetItemEnabled | IMPL | IMPL | IMPL |
| SetState | IMPL | IMPL | IMPL |
| GetCheckWidth | MISS | MISS | MISS |
| GetHeader | MISS | MISS | MISS |
| SetHeader | MISS | MISS | MISS |

**GTK4 gaps**: None — full parity
**ALL MISS**: GetCheckWidth (base returns 0), GetHeader/SetHeader (header items — base defaults adequate)

#### TWSCustomCheckListBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **54줄** `TGtk4CheckListBox.CreateWidget` (gtk4widgets.pas:7756-7809): GtkScrolledWindow → GtkListView (GtkStringList 모델 + GtkSignalListItemFactory). `setup` 콜백: GtkBox + GtkCheckButton + GtkLabel 생성. `bind` 콜백: 체크 상태/텍스트 바인딩. **모던 GTK4 패턴** (factory pattern) | `gtk_list_store_new(4, [G_TYPE_UCHAR, G_TYPE_STRING, ...])` + `gtk_tree_view_new_with_model` + `gtk_cell_renderer_toggle_new` (~50줄, **deprecated** GtkTreeView API) | `TQtCheckListBox.Create()` + CheckBox delegate | ✅ 완전 — **GTK2보다 아키텍처적으로 우수** (모던 factory pattern vs deprecated TreeView) |
| GetItemEnabled | **LCL 캐시 직접 읽기** (gtk4wschecklst.pp:115-140): `TCheckListBoxCracker.GetCachedData(AIndex)` → `PGtk4CLBCacheData.Disabled` 필드. 재귀 방지: WS→LCL→WS 무한루프 회피를 위해 Cracker 패턴 + try/except 가드 | GtkListStore 모델에서 직접 읽기 | `QListWidgetItem_flags` 체크 | ⚠️ **캐시 의존** — 플랫폼 위젯 상태가 아닌 LCL 캐시에서 읽음 |
| GetState | **LCL 캐시 직접 읽기** (gtk4wschecklst.pp:142-162): `GetCachedData(AIndex)` → `PGtk4CLBCacheData.State` 필드. **GTK2도 캐시 기반** (동일 원칙) | GtkListStore 체크 컬럼 직접 읽기 (캐시 기반) | `QListWidgetItem_checkState` | ⚠️ **캐시 의존** — GTK2도 동일 원칙 |
| SetItemEnabled | `queue_draw()` (gtk4wschecklst.pp:164-172) — LCL에 상태 저장, factory bind 콜백에서 그리기 시 읽음 | GtkListStore 모델 직접 업데이트 | `QListWidgetItem_setFlags` | ⚠️ **queue_draw만** — 실제 위젯 비활성화가 아닌 시각적 표현만 |
| SetState | `queue_draw()` (gtk4wschecklst.pp:174-182) — LCL에 상태 저장, factory bind 콜백에서 그리기 시 읽음 | GtkListStore 체크 컬럼 직접 업데이트 | `QListWidgetItem_setCheckState` | ⚠️ **queue_draw만** — 실제 위젯 상태가 아닌 시각적 표현만 |

**GTK4 CheckListBox 아키텍처 특이사항:**
- **위젯 계층**: GtkScrolledWindow → GtkListView (GtkStringList + GtkSignalListItemFactory)
- 체크/활성 상태를 **LCL 캐시**(TCheckListBoxCracker)에 저장하고, factory `bind` 콜백에서 읽어서 GtkCheckButton/GtkLabel에 표시
- GTK2는 GtkListStore 모델 컬럼에 직접 저장 (deprecated GtkTreeView), Qt5는 QListWidgetItem 플래그/상태에 직접 저장
- `GetItemEnabled`/`GetState`에 **재귀 방지 로직**: WS→LCL→WS 콜백 루프 회피를 위해 Cracker 패턴 사용
- `SetItemEnabled`/`SetState`는 `queue_draw()`만 호출 — factory `bind` 재바인딩으로 시각 갱신
- **GTK4 vs GTK2 비교**: 동일 복잡도 (~50줄) but GTK4가 **아키텍처적으로 우수** (GtkListView factory는 GTK4 표준 패턴, GtkTreeView는 deprecated)
- ~~⚠️ **데드 코드**~~: ✅ **수정됨 (Session 61)** — `Gtk4WS_CheckListBoxDataFunc` + `GTK4WS_CheckListBoxToggle` 60줄 삭제
- ~~⚠️ **범위 검사 누락**~~: ✅ **수정됨 (Session 61)** — `SetItemEnabled`/`SetState`에 AIndex 범위 검사 추가

---

## 4. WSComCtrls

### TWSCustomPage

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | MISS | MISS | IMPL |
| UpdateProperties | IMPL | IMPL | IMPL |
| SetBounds | IMPL | IMPL | MISS |
| SetFont | IMPL | IMPL | IMPL |
| ShowHide | IMPL | IMPL | MISS |
| GetDefaultClientRect | IMPL | IMPL | MISS |

**GTK4 gaps**: None — exceeds Qt5

#### TWSCustomPage 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **5줄** (gtk4wscomctrls.pp:2062-2066): `TGtk4Page.Create(AWinControl, AParams)` 래퍼 위임 | `gtk_hbox_new` + `CreateFixedClientWidget` + `SetCallbacks` + `gtk_widget_show_all` | `TQtPage.Create` + `TabIndex := -1` | 완전 |
| SetBounds | **6줄** (gtk4wscomctrls.pp:2075-2080): LCL 바운드 **의도적 무시** (주석 처리된 inherited 호출) — 노트북이 자동 크기 배정 | `gtk_widget_set_size_request` (마찬가지로 노트북 관리) | 미구현 | 완전 — 의도적 무시 (정상 동작) |
| SetFont | **49줄** (gtk4wscomctrls.pp:2082-2130): TFont→CSS 변환 (`font-family`, `font-size`, `font-weight`, `font-style`, `color`) → `gtk_css_provider_load_from_data` → 탭 라벨 위젯에 CSS 프로바이더 적용. **CSS 기반 폰트 설정** (GTK2의 직접 API 대비 간접적이나 유연) | `gtk_notebook_get_tab_label` + 폰트 적용 | `setFont` | ✅ 완전 — CSS 기반 (가장 유연) |
| UpdateProperties | **6줄** (gtk4wscomctrls.pp:2068-2073): `TGtk4Page.UpdateTabImage` 위임 — 탭 아이콘 갱신 | `gtk_notebook` 페이지 프로퍼티 갱신 | 미표시 | 완전 |
| ShowHide | **5줄** (gtk4wscomctrls.pp:2132-2136): `inherited` 호출 (가시성 상태 변경) | `gtk_widget_show/hide` | 미구현 | 완전 |
| GetDefaultClientRect | **17줄** (gtk4wscomctrls.pp:2138-2154): 부모 할당 상태 확인 → 미할당 시 부모 ClientRect 반환, 할당 완료 시 False 반환 (위젯 자체 크기 사용) | 클라이언트 영역 반환 | 미구현 | 완전 |
| DestroyHandle | ❌ **MISS** | `gtk_widget_destroy` | `TQtPage.Destroy` | ⚠️ 미구현이나 TGtk4Widget.DestroyWidget 메커니즘으로 대체 처리 |

### TWSCustomTabControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetDefaultClientRect | IMPL | IMPL | IMPL |
| GetDesignInteractive | IMPL | MISS | IMPL |
| AddPage | IMPL | IMPL | IMPL |
| MovePage | IMPL | IMPL | IMPL |
| RemovePage | IMPL | MISS | IMPL |
| GetCapabilities | IMPL | IMPL | IMPL |
| GetNotebookMinTabHeight | IMPL | IMPL | IMPL |
| GetNotebookMinTabWidth | IMPL | IMPL | IMPL |
| GetTabIndexAtPos | IMPL | IMPL | IMPL |
| GetTabRect | IMPL | IMPL | IMPL |
| SetPageIndex | IMPL | IMPL | IMPL |
| SetTabCaption | IMPL | MISS | IMPL |
| SetTabPosition | IMPL | IMPL | IMPL |
| SetTabSize | IMPL | MISS | IMPL |
| ShowTabs | IMPL | IMPL | IMPL |
| UpdateProperties | IMPL | IMPL | IMPL |
| SetImageList | MISS | MISS | MISS |

**GTK4 gaps**: None — full parity
**ALL MISS**: SetImageList (tab image lists — base default adequate)

#### TWSCustomTabControl 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | TTabControl→TGtk4CustomControl, TPageControl→TGtk4NoteBook | `gtk_notebook_new` | TQtTabWidget | 완전 (타입별 분기) |
| AddPage | **WS 17줄** (gtk4wscomctrls.pp:1734-1750): `TGtk4Notebook.InsertPage` + SetBounds + ShowHide | gtk_notebook 페이지 조작 | `insertTab` | 완전 |
| MovePage | **WS 10줄** (gtk4wscomctrls.pp:1752-1761): `gtk_notebook_reorder_child` | `reorder_child` | `moveTab` | 완전 |
| RemovePage | **13개 파괴 상태 체크** 후 `TGtk4Notebook.RemovePage` | 단순 제거 | `removeTab` | 완전 (방어적 코드 우수) |
| GetDefaultClientRect | **WS 27줄** (gtk4wscomctrls.pp:1693-1719): `gtk_widget_get_allocated_height` 기반 탭 영역 제외 계산 | `gtk_notebook_get_tab_label` 할당 | `currentWidget.rect` | 완전 |
| GetDesignInteractive | **WS 12줄** (gtk4wscomctrls.pp:1721-1732): `gtk_notebook_get_current_page` 디자인 시 탭 클릭 인터랙션 | `get_current_page` | `tabBar.tabAt` | 완전 |
| GetTabIndexAtPos | `get_nth_page` + `get_tab_label` + `gtk_widget_get_allocation` 순회, `PtInRect` | `gtk_notebook_get_tab_label` | `tabAt(QPoint)` | 완전 (수동 순회) |
| GetTabRect | **35줄** (gtk4wscomctrls.pp:1946-1985): `get_nth_page` → `get_tab_label` → `gtk_widget_get_allocation` + `gtk4_widget_translate_coordinates`로 탭→노트북 좌표 변환. ✅ **수정됨 (S62)**: translate_coordinates 사용으로 모든 TabPosition 정확 | `gtk_notebook_get_tab_label` 할당 | `tabRect(index)` | ✅ 완전 |
| SetPageIndex | `TGtk4Notebook.SetPageIndex` + BeginUpdate/EndUpdate | `gtk_notebook_set_current_page` | `setCurrentIndex` | 완전 |
| SetTabCaption | **WS 10줄** (gtk4wscomctrls.pp:1989-1998): `TGtk4NoteBook.SetTabLabelText` | 직접 라벨 설정 | `setTabText` | 완전 |
| SetTabPosition | **WS 9줄** (gtk4wscomctrls.pp:2000-2008): `TGtk4NoteBook.SetTabPosition` | `gtk_notebook_set_tab_pos` | `setTabPosition` | 완전 |
| SetTabSize | **23줄** (gtk4wscomctrls.pp:2010-2032): CSS 규칙 동적 생성 `'notebook tab { min-width: Npx; min-height: Mpx; }'` → `gtk_css_provider_load_from_data` → `add_provider(APPLICATION 우선순위)`. **min-width/height 사용** (최소 크기, 고정 크기 아님). `g_object_unref(CSSProvider)` 정상 해제 | ❌ 미지원 (GtkNotebook에 탭 크기 API 없음) | 미표시 | ✅ **GTK4 고유** — CSS 기반 모던 접근 |
| ShowTabs | **WS 9줄** (gtk4wscomctrls.pp:2034-2042): `TGtk4NoteBook.SetShowTabs` | `gtk_notebook_set_show_tabs` | `setTabBarVisible` | 완전 |
| UpdateProperties | **WS 14줄** (gtk4wscomctrls.pp:2044-2057): notebook `popup_enable/disable` 토글 | `gtk_notebook_popup_enable/disable` | 프로퍼티 설정 | 완전 |

### TWSStatusBar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | MISS | MISS | IMPL |
| PanelUpdate | IMPL | IMPL | IMPL |
| SetPanelText | IMPL | IMPL | IMPL |
| Update | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| SetSizeGrip | STUB | IMPL | IMPL |

**GTK4 gaps**: SetSizeGrip is stub (GTK4 removed GtkStatusBar)

#### TWSStatusBar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **8줄** (gtk4wscomctrls.pp:1626-1633): `TGtk4StatusBar.Create` 래퍼 위임. `CreateWidget` **8줄** (gtk4widgets.pas:4781-4788): `GtkBox(vertical)` → `GtkBox(horizontal, spacing=1)` 계층. GTK2의 `GtkEventBox`+`GtkHBox` 대비 간결 | `gtk_event_box_new` + `gtk_hbox_new` + UpdateStatusBarPanels | `TQtStatusBar.Create` + RecreatePanels | ✅ 완전 — 모던 GtkBox 계층 |
| PanelUpdate | **12줄** (gtk4wscomctrls.pp:1635-1646): **인덱스 부호로 단일/전체 분기** — idx≥0→`UpdatePanel(idx)` **59줄** (gtk4widgets.pas:4721-4779) 인플레이스 업데이트 (패널 수 변경 시 자동 RecreatePanels 전환), idx<0→`RecreatePanels` **54줄** (gtk4widgets.pas:4666-4719) 전체 GtkLabel 재생성 + 정렬/너비/hexpand 설정 | GList nth_data로 개별 패널 접근 | 패널별 QLabel 텍스트/정렬/너비 업데이트 | ✅ 완전 — 듀얼 모드 (단일 59줄/전체 54줄) |
| SetPanelText | **9줄** (gtk4wscomctrls.pp:1648-1656): `AWidget.UpdatePanel(idx)` — PanelUpdate와 달리 **항상 단일 패널만** 업데이트. `gtk_label_set_text` + xalign + width + hexpand 일괄 갱신 | PanelUpdate 위임 | `QLabel_setText` 직접 | 완전 |
| Update | **8줄** (gtk4wscomctrls.pp:1658-1665): `AWidget.RecreatePanels` — `ClearPanels` **11줄** (gtk4widgets.pas:4654-4664) `gtk4_box_remove` 루프 후 GtkLabel 전체 재생성. SimplePanel 분기 + Panels[i].Alignment 3단 정렬 + Width>0 가시성 + 마지막 패널 hexpand | UpdateStatusBarPanels | RecreatePanels | 완전 |
| SetSizeGrip | **6줄** (gtk4wscomctrls.pp:1675-1680) **NO-OP** — GTK4에서 GtkStatusBar 위젯 **완전 제거**. 리사이즈 그립은 Wayland/X11 WM이 처리. **아키텍처 제한, 버그 아님** | `gtk_statusbar_set_has_resize_grip` 직접 API | `setSizeGripEnabled` | ⚠️ 의도적 no-op (GTK4 아키텍처 변경) |

### TWSCustomListView

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | MISS | IMPL | MISS |
| ColumnDelete | IMPL | IMPL | IMPL |
| ColumnGetWidth | IMPL | IMPL | IMPL |
| ColumnInsert | IMPL | IMPL | IMPL |
| ColumnMove | IMPL | IMPL | IMPL |
| ColumnSetAlignment | IMPL | IMPL | IMPL |
| ColumnSetAutoSize | IMPL | IMPL | IMPL |
| ColumnSetCaption | IMPL | IMPL | IMPL |
| ColumnSetImage | IMPL | IMPL | IMPL |
| ColumnSetMaxWidth | IMPL | IMPL | MISS |
| ColumnSetMinWidth | IMPL | IMPL | IMPL |
| ColumnSetWidth | IMPL | IMPL | IMPL |
| ColumnSetVisible | IMPL | IMPL | IMPL |
| ColumnSetSortIndicator | IMPL | IMPL | IMPL |
| ItemDelete | IMPL | IMPL | IMPL |
| ItemDisplayRect | IMPL | IMPL | IMPL |
| ItemExchange | IMPL | IMPL | IMPL |
| ItemMove | IMPL | IMPL | IMPL |
| ItemGetChecked | IMPL | IMPL | IMPL |
| ItemGetState | IMPL | IMPL | IMPL |
| ItemInsert | IMPL | IMPL | IMPL |
| ItemSetChecked | IMPL | IMPL | IMPL |
| ItemSetImage | IMPL | IMPL | IMPL |
| ItemSetState | IMPL | IMPL | IMPL |
| ItemSetStateImage | IMPL | MISS | IMPL |
| ItemSetText | IMPL | IMPL | IMPL |
| ItemShow | IMPL | IMPL | IMPL |
| ItemGetPosition | IMPL | IMPL | IMPL |
| ItemUpdate | IMPL | IMPL | MISS |
| BeginUpdate | IMPL | IMPL | IMPL |
| EndUpdate | IMPL | IMPL | IMPL |
| GetBoundingRect | IMPL | IMPL | IMPL |
| GetDropTarget | IMPL | IMPL | MISS |
| GetFocused | IMPL | IMPL | IMPL |
| GetHitTestInfoAt | IMPL | MISS | IMPL |
| GetHoverTime | STUB | IMPL | MISS |
| GetItemAt | IMPL | IMPL | IMPL |
| GetSelCount | IMPL | IMPL | IMPL |
| GetSelection | IMPL | IMPL | IMPL |
| GetTopItem | IMPL | IMPL | IMPL |
| GetViewOrigin | IMPL | IMPL | IMPL |
| GetVisibleRowCount | IMPL | IMPL | IMPL |
| SelectAll | IMPL | IMPL | IMPL |
| SetAllocBy | STUB | IMPL | IMPL |
| SetColor | IMPL | IMPL | MISS |
| SetDefaultItemHeight | IMPL | IMPL | MISS |
| SetFont | IMPL | IMPL | MISS |
| SetHotTrackStyles | STUB | IMPL | MISS |
| SetHoverTime | STUB | MISS | MISS |
| SetImageList | IMPL | IMPL | IMPL |
| SetItemsCount | IMPL | IMPL | IMPL |
| SetProperty | IMPL | IMPL | IMPL |
| SetProperties | IMPL | IMPL | IMPL |
| SetScrollBars | IMPL | IMPL | IMPL |
| SetSort | IMPL | IMPL | IMPL |
| SetIconArrangement | STUB | MISS | IMPL |
| SetOwnerData | STUB | MISS | IMPL |
| SetViewOrigin | IMPL | IMPL | MISS |
| SetViewStyle | IMPL | IMPL | IMPL |
| RestoreItemCheckedAfterSort | IMPL | MISS | IMPL |
| GetNextItem | MISS | MISS | MISS |
| ItemGetStates | MISS | MISS | MISS |
| ItemSetPosition | MISS | MISS | MISS |
| MustHideEditor | MISS | MISS | MISS |
| InitMultiSelList | MISS | MISS | MISS |
| UpdateMultiSelList | MISS | MISS | MISS |
| GetFirstSelected | MISS | MISS | MISS |

**GTK4 gaps**: SetAllocBy/SetHotTrackStyles/SetHoverTime/SetIconArrangement/SetOwnerData/GetHoverTime are stubs (platform-specific concepts)
**GTK4 quality**: ~~SetSort=`IMPL*`~~ ✅ **수정됨 (Session 61)**: `ModelNotifyItemsChanged`로 모델 갱신 구현. ColumnView에서 ColumnMove/GetDropTarget/lvpColumnClick/lvpShowColumnHeaders 미동작 (GTK4.6 API 부재). ItemShow/ItemGetPosition/GetTopItem은 ColumnView/GridView에서 근사치 반환 (위젯 재활용으로 정확한 위치 불가).
**ALL MISS**: GetNextItem, ItemGetStates, ItemSetPosition, MustHideEditor, InitMultiSelList, UpdateMultiSelList, GetFirstSelected (base defaults adequate)

#### TWSCustomListView 구현 수준 상세

GTK4 ListView는 **모든 메서드를 `TGtk4ListView` Pascal 래퍼 클래스에 위임**. GTK2는 GtkTreeView/GtkListStore 직접 API 호출. Qt5는 TQtTreeWidget/TQtListWidget 래퍼.

**아키텍처 비교**:
| 관점 | GTK4 | GTK2 | Qt5 |
|------|------|------|-----|
| 뷰 타입 | GtkTreeView (Report) + GtkColumnView/GtkGridView (Icon/SmallIcon) | GtkTreeView (Report) + GtkIconView (Icon) | QTreeWidget (Report) + QListWidget (Icon) |
| 데이터 모델 | GtkTreeModel + 커스텀 CellRendererFactory | GtkListStore 직접 조작 | QTreeWidgetItem 트리 노드 |
| 뷰 전환 | `RecreateWnd` (위젯 재생성 필수) | `RecreateWnd` | `RecreateWnd` |
| 체크 상태 | TListItem에 저장 + `queue_draw` (렌더러가 읽음) | GtkListStore 컬럼에 저장 | QTreeWidgetItem.checkState |

**주요 메서드 품질 비교**:

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 9줄** (gtk4wscomctrls.pp:438-446) + **CreateWidget 131줄** (gtk4widgets.pas:8341-8471): Report→GtkTreeView, Icon→ColumnView/GridView 자동 분기. 멀티뷰 초기화 | TTVWidgets 레코드 구성 (ItemCache, TreeModel, TreeSelection, WidgetInfo) | QTreeWidget (Report) / QListWidget (Icon) 분기 + `setRootIsDecorated(False)` | 완전 |
| ColumnInsert | **WS 9줄** (gtk4wscomctrls.pp:591-599) + **래퍼 91줄** (gtk4widgets.pas:8704-8794): 렌더러 생성, 시그널 연결, factory 설정 | GtkTreeViewColumn 직접 조작 | `QTreeWidgetItem_setText(headerItem, AIndex, ACaption)` | 완전 |
| ColumnDelete | **WS 8줄** (gtk4wscomctrls.pp:573-580) + **래퍼 25줄** (gtk4widgets.pas:8529-8553): ColumnView→`gtk4_column_view_remove_column`, TreeView→`remove_column` | GtkTreeViewColumn 직접 제거 | **`RecreateWnd(ALV)`** — Qt protected API 제한으로 전체 재생성 | ✅ GTK4가 Qt5보다 우수 |
| ColumnGetWidth | **WS 8줄** (gtk4wscomctrls.pp:582-589) + **래퍼 148줄** (gtk4widgets.pas:8555-8702): 복잡한 너비 해석 로직 (최대 래퍼) | `get_width` 직접 | `columnWidth` | 완전 |
| ColumnMove | **WS 18줄** (gtk4wscomctrls.pp:601-618): TreeView→`move_column_after`, CV/GridView skip (래퍼 없음) | `move_column_after` | `moveColumn` | ⚠️ CV/GridView 미지원 |
| ColumnSetAlignment | **WS 10줄** (gtk4wscomctrls.pp:620-629) + **래퍼 36줄** (gtk4widgets.pas:8796-8831): cell renderer alignment | `set_alignment` | `setTextAlignment` | 완전 |
| ColumnSetAutoSize | **WS 10줄** (gtk4wscomctrls.pp:631-640) + **래퍼 32줄** (gtk4widgets.pas:8833-8864): TreeView expand/resizable, CV API 제한 | `set_resizable` + `set_sizing` | `setResizeMode` | 완전 |
| ColumnSetCaption | **WS 10줄** (gtk4wscomctrls.pp:642-651) + **래퍼 32줄** (gtk4widgets.pas:8866-8897): 헤더 라벨 업데이트 | `set_title` | `setText` | 완전 |
| ColumnSetImage | **WS 8줄** (gtk4wscomctrls.pp:653-660) + **래퍼 45줄** (gtk4widgets.pas:8899-8943): pixbuf 렌더러 범위 체크 | 직접 pixbuf 설정 | `setIcon` | 완전 |
| ColumnSetMaxWidth | **WS 10줄** (gtk4wscomctrls.pp:662-671) + **래퍼 18줄** (gtk4widgets.pas:8945-8962): TreeView API; CV 미지원 | `set_max_width` | `setMaximumWidth` | ⚠️ CV 미지원 |
| ColumnSetMinWidth | **WS 10줄** (gtk4wscomctrls.pp:673-682) + **래퍼 19줄** (gtk4widgets.pas:8964-8982): TreeView API; CV 제한 | `set_min_width` | `setMinimumWidth` | ⚠️ CV 제한 |
| ColumnSetWidth | **WS 10줄** (gtk4wscomctrls.pp:684-693) + **래퍼 20줄** (gtk4widgets.pas:8984-9003): CV/TV 모두 `set_fixed_width` | `set_fixed_width` | `setColumnWidth` | 완전 |
| ColumnSetVisible | **WS 10줄** (gtk4wscomctrls.pp:695-704) + **래퍼 21줄** (gtk4widgets.pas:9005-9025): `set_visible` 양 백엔드 | `set_visible` | `setColumnHidden` | 완전 |
| ColumnSetSortIndicator | **WS 16줄** (gtk4wscomctrls.pp:706-721) + **래퍼 33줄** (gtk4widgets.pas:9027-9059): CV→`set_sorter`, TV→`set_sort_column_id` | `set_sort_indicator` + `set_sort_order` 직접 API (gtk2wscustomlistview.inc:1100-1128) | Header setSortIndicator | ⚠️ 래퍼 의존 — GTK2는 직접 API |
| ItemInsert | **WS 8줄** (gtk4wscomctrls.pp:864-871) + **래퍼 35줄** (gtk4widgets.pas:9077-9111): text/image/state 초기화 포함 | `gtk_list_store_insert` 모델 직접 조작 | Report: `QTreeWidgetItem_create` + `insertTopLevelItem` | 완전 |
| ItemDelete | **WS 9줄** (gtk4wscomctrls.pp:723-731) + **래퍼 15줄** (gtk4widgets.pas:9061-9075): 모델에서 제거 | `gtk_list_store_remove` | `takeTopLevelItem` | 완전 |
| ItemDisplayRect | **WS 58줄** (gtk4wscomctrls.pp:733-790): `Gtk4_FindItemWidget` (Session 54 수정) CV/GridView용 특수 탐색 | `gtk_tree_view_get_cell_area` 정확한 API | `visualItemRect` | ⚠️ CV/GridView 근사치 |
| ItemExchange | **WS 23줄** (gtk4wscomctrls.pp:792-814): TreeView splice; CV→`queue_draw` | `splice` / `swap` | `exchange` | 완전 |
| ItemMove | **WS 28줄** (gtk4wscomctrls.pp:816-843): TreeView splice 이동 | 모델 splice | `takeTopLevelItem` + `insertTopLevelItem` | 완전 |
| ItemGetChecked | **WS 8줄** (gtk4wscomctrls.pp:845-852): TListItem에서 체크 상태 읽기 | GtkListStore 컬럼 값 직접 변경 | `ItemChecked[AIndex]` | ⚠️ 플랫폼 수준 저장 없음 (렌더러 의존) |
| ItemGetState | **WS 9줄** (gtk4wscomctrls.pp:854-862) + **래퍼 67줄** (gtk4widgets.pas:9259-9325): lsSelected/lsCut/lsDropTarget/lsFocused 5종 상태 머신 | `get_iter` + 모델 읽기 | `currentItem().isSelected` | 완전 (깊은 상태 처리) |
| ItemSetChecked | **WS 11줄** (gtk4wscomctrls.pp:873-883): 체크 설정 + TreeView `queue_draw` | GtkListStore 컬럼 값 변경 | `ItemChecked := Checked` | ⚠️ 플랫폼 저장 없음 |
| ItemSetImage | **WS 10줄** (gtk4wscomctrls.pp:885-894) + **래퍼 30줄** (gtk4widgets.pas:9163-9192): BeginUpdate 래핑 | pixbuf 설정 | `setIcon` | 완전 |
| ItemSetState | **WS 12줄** (gtk4wscomctrls.pp:896-907) + **래퍼 64줄** (gtk4widgets.pas:9194-9257): CV/TV 분기 상태 설정 | 모델 값 설정 | `setSelected/setHidden` | 완전 |
| ItemSetText | **WS 9줄** (gtk4wscomctrls.pp:919-927) + **래퍼 32줄** (gtk4widgets.pas:9130-9161): (row,column) 텍스트 업데이트 | `set_value` | `setText` | 완전 |
| ItemShow | **WS 29줄** (gtk4wscomctrls.pp:929-957): CV→Gtk4_FindItemWidget; TV→`scroll_to_cell` | `scroll_to_cell` | `scrollToItem` | ⚠️ ColumnView 근사치 |
| ItemGetPosition | **WS 36줄** (gtk4wscomctrls.pp:959-994): 복잡한 좌표 계산 | `get_cell_area` | `visualItemRect` | 완전 |
| ItemUpdate | **WS 6줄** (gtk4wscomctrls.pp:996-1001) + **래퍼 16줄** (gtk4widgets.pas:9113-9128): 아이템 렌더링 새로고침 | `queue_draw` | `update` | 완전 |
| ItemSetStateImage | **WS 9줄** (gtk4wscomctrls.pp:909-917): **No-op** — GTK4에 state image 네이티브 개념 없음 | GTK2도 **stub** (미지원) | QTreeWidgetItem decoration role | ⚠️ GTK4/GTK2 모두 미지원 |
| GetFocused | **WS 32줄** (gtk4wscomctrls.pp:1048-1079): CV→`gtk4_bitset_get_minimum` (근사치), TV→`get_cursor` | GtkTreeView cursor API | `currentItem` + `isSelected` | ⚠️ CV **근사치** (GTK4.6 focus API 부재) |
| GetItemAt | **WS 41줄** (gtk4wscomctrls.pp:1089-1129): 좌표→아이템 인덱스 변환 | `get_path_at_pos` | `itemAt` | 완전 |
| GetSelCount | **WS 27줄** (gtk4wscomctrls.pp:1131-1157): CV→`gtk4_bitset_get_size`, TV→`count_selected_rows` | `count_selected_rows` | `selectedItems.length` | 완전 |
| GetSelection | **WS 37줄** (gtk4wscomctrls.pp:1159-1195): CV→`gtk4_bitset_get_minimum`, TV→`get_selected_rows` | `get_selected_rows` | 첫 번째 selectedItem | 완전 |
| GetTopItem | **WS 45줄** (gtk4wscomctrls.pp:1197-1241): CV→adjustment, TV→`get_path_at_pos` | `get_path_at_pos` | `indexOfTopLevelItem` | 완전 |
| GetViewOrigin | **WS 19줄** (gtk4wscomctrls.pp:1243-1261): 스크롤 위치 (X,Y) | `get_vadjustment/hadjustment` | `getViewOrigin` | 완전 |
| GetVisibleRowCount | **WS 62줄** (gtk4wscomctrls.pp:1263-1324): 복잡한 뷰포트 행 계산 | `get_visible_range` | `visibleRowCount` | 완전 |
| SelectAll | **WS 15줄** (gtk4wscomctrls.pp:1326-1340): `gtk4_selection_model_select_all` / `unselect_all` | `gtk_tree_selection_select_all` | `selectAll` | 완전 |
| SetSort | **WS 6줄** (gtk4wscomctrls.pp:1493-1500): ✅ **S61 구현** — `ModelNotifyItemsChanged` 호출 (ColumnView: `g_list_model_items_changed`, TreeView: model 재구축). LCL이 미리 정렬한 FListItems를 모델에 반영 | GTK2도 **queue_draw만** | **실구현**: sort role + indicator | ✅ 완전 — 래퍼 `ModelNotifyItemsChanged` 위임 |
| SetImageList | **WS 33줄** (gtk4wscomctrls.pp:1388-1420): 2 시그니처 (smState 포함/미포함) | 이미지 리스트 설정 | `setIconSize` | 완전 |
| SetProperties | **WS 10줄** (gtk4wscomctrls.pp:1469-1478) + **SetPropertyInternal 117줄** (455-571): 전체 프로퍼티 case 문 | 개별 프로퍼티 설정 | `setProperty` | 완전 |
| SetScrollBars | **WS 12줄** (gtk4wscomctrls.pp:1480-1491): `Gtk4TranslateScrollStyle` → `set_policy` | `gtk_scrolled_window_set_policy` | `setScrollBarPolicy` | 완전 |
| SetViewStyle | **WS 9줄** (gtk4wscomctrls.pp:1529-1537): `RecreateWnd` — vsReport→ColumnView, vsIcon→GridView | `RecreateWnd` | `RecreateWnd` | 완전 (모든 플랫폼 동일) |
| SetItemsCount | **WS 37줄** (gtk4wscomctrls.pp:1422-1458): 가상 아이템 (owner-data) | 모델 크기 설정 | `setItemCount` | 완전 |
| SetAllocBy | **WS 6줄** (gtk4wscomctrls.pp:1342-1347): **No-op** (Windows 전용 개념) | No-op | No-op | 완전 (모든 플랫폼 동일) |
| GetBoundingRect | **WS 8줄** (gtk4wscomctrls.pp:1015-1022): 위젯 할당 크기 반환 | `get_allocation` | `boundingRect` | 완전 |
| RestoreItemCheckedAfterSort | **WS 6줄** (gtk4wscomctrls.pp:1617-1622): `False` 반환 — GTK4가 체크 상태 자동 보존 | 재정렬 후 복원 | 복원 | 완전 |
| GetHitTestInfoAt | **WS 65줄** (gtk4wscomctrls.pp:1539-1603): TV→cell_get_position 아이콘/라벨 구분. CV/GridView→`GetItemAt>=0` 단순 반환 | TreeView cell 위치 계산 | `hitTestInfoAt` 직접 API | ⚠️ TV **완전**, CV **간소화** |
| BeginUpdate/EndUpdate | **WS 각 5줄** (gtk4wscomctrls.pp:1003-1013): InUpdate 플래그만. **`setUpdatesEnabled()` 동등 API 없음** | 플래그만 (GTK2도 동일) | **Qt5 실구현**: `setUpdatesEnabled(False/True)` | ⚠️ 플래그만 — Qt5 대비 미흡 |

**GTK4 ListView 아키텍처 특이사항**:
- 60+ 메서드 모두 TGtk4ListView Pascal 래퍼에 위임 (WS 코드는 1줄 위임문)
- ColumnView (GTK4.6): lvpColumnClick, lvpShowColumnHeaders, ColumnMove, GetDropTarget가 API 부재로 미동작
- 체크 상태를 TListItem에 저장하는 방식은 GtkListStore 컬럼 방식보다 가벼우나 플랫폼 독립적이지 않음
- ColumnView/GridView에서 위젯 재활용(virtualization) 때문에 정확한 위치/포커스 API 제한

### TWSProgressBar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| ApplyChanges | IMPL | IMPL | IMPL |
| SetPosition | IMPL | IMPL | IMPL |
| SetStyle | IMPL | IMPL | IMPL |

**GTK4 gaps**: None

#### TWSProgressBar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | WS **8줄** (gtk4wscomctrls.pp:392-399) → 래퍼 **CreateWidget 12줄** (gtk4widgets.pas:5943-5955): GtkBox(V) → GtkProgressBar + `set_hexpand/vexpand(True)` + `set_can_focus(True)`. **InitializeWidget 7줄** (5957-5964): `set_size_request` 크기 오버라이드. **`get_progress_preferred_width` 18줄** (5924-5941): GType 커스텀 preferred width — GTK4 CSS 최소 크기 무시하여 LCL 크기 제어 | `gtk_progress_bar_new()` + WidgetInfo + SetCallbacks (**16줄**) | `TQtProgressBar.Create` | ✅ 완전 — **총 37줄** (WS+래퍼+vfunc) |
| ApplyChanges | WS **13줄** (gtk4wscomctrls.pp:401-413): BeginUpdate/EndUpdate 래핑 → `SetPosition` + `SetStyle` + `ShowText` + `Orientation` 4개 프로퍼티 원자적 동기화. 래퍼 `SetOrientation` **17줄** (5852-5869): 4방향 분기 (H/V × inverted) + `PGtkOrientable.set_orientation` + `set_inverted`. 래퍼 `SetShowText` **3줄** (5886-5890): `PGtkProgressBar.set_show_text` | `gtk_progress_bar_set_bar_style` + `set_orientation` + SetPosition (**32줄**) | `setTextVisible` + SetRangeStyle + `setValue` | ✅ 완전 — 래퍼 포함 **총 33줄** |
| SetPosition | WS **9줄** (gtk4wscomctrls.pp:415-423) → 래퍼 **14줄** (gtk4widgets.pas:5871-5884): `fraction = (AValue - ABar.Min) / (ABar.Max - ABar.Min)` 수학 → `PGtkProgressBar.set_fraction(fraction)`. 0-division 가드 포함 | `gtk_progress_bar_set_fraction` + UpdateProgressBarText (**21줄**) | `setValue` + BeginUpdate/EndUpdate | ✅ 완전 — **GTK2와 동등한 fraction 수학** |
| SetStyle | WS **10줄** (gtk4wscomctrls.pp:425-434) → 래퍼 **16줄** (gtk4widgets.pas:5906-5921): `g_object_set_data('lclprogressbarstyle')` + Normal: Position 복원 / Marquee: **`g_timeout_add(100, @ProgressPulseTimeout)` 타이머** + `g_object_set_data_full('timeout', ..., @ProgressDestroy)` GLib 파괴자. `ProgressPulseTimeout` **8줄** (5892-5899): 타이머 콜백 → `PGtkProgressBar.pulse`. `ProgressDestroy` **4줄** (5901-5904): `g_source_remove` 타이머 정리 | `g_timeout_add(100, ProgressPulseTimeout)` → `gtk_progress_bar_pulse` (**8줄** 타이머) | `reset` + SetRangeStyle | ✅ 완전 — **GTK2와 동일 pulse 패턴**, GLib 파괴자 안전 |

### TWSToolBar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |

**GTK4 gaps**: None

#### TWSToolBar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 8줄** (gtk4wscomctrls.pp:381-388) → **래퍼 총 50줄**: `CreateWidget` **23줄** (gtk4widgets.pas:5982-6004) GtkOverlay + GtkFixed + GtkDrawingArea(paint용) 3-depth 위젯 구성. `ButtonClicked` 콜백, `ClearGlyphs` 리소스 정리, `Destroy` 래퍼 해제. **GtkOverlay 패턴**: ToolBar는 커스텀 그리기 영역(GtkDrawingArea)을 overlay 위에 배치하여 LCL 수준 렌더링과 GTK4 위젯 배치를 결합. | `gtk_toolbar_new()` + `gtk_toolbar_set_style` + `gtk_toolbar_set_icon_size` 네이티브 API (~12줄) | `TQtCustomControl.Create` 범용 컨트롤 (~8줄) | 완전 — GTK4는 GtkToolbar 제거 대응 (GtkOverlay+DrawingArea), GTK2보다 복잡하나 기능 동등 |

### TWSTrackBar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| ApplyChanges | IMPL | IMPL | IMPL |
| GetPosition | IMPL | IMPL | IMPL |
| SetPosition | IMPL | IMPL | IMPL |
| SetOrientation | IMPL | MISS | IMPL |
| SetTick | MISS | MISS | MISS |
| SetTickStyle | MISS | MISS | MISS |
| GetPreferredSize | IMPL | IMPL | MISS |

**GTK4 gaps**: ~~GetPreferredSize~~ ✅ **S61 구현** — `preferredSize` 래퍼 위임
**ALL MISS**: SetTick, SetTickStyle (base defaults adequate)

#### TWSTrackBar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| ApplyChanges | **WS 20줄** (gtk4wscomctrls.pp:330-349): `TGtk4TrackBar` 프로퍼티 일괄 설정 — Range + Position + Step + ScalePos + **SetTickMarks** + Reversed. **SetTickMarks 래퍼 44줄** (gtk4widgets.pas:5468-5511): `gtk_scale_clear_marks` → `for i:=0 to TickCount do gtk_scale_add_mark(scale, pos, GTK_POS_*)` 눈금 재생성. 눈금 간격 = `(Max-Min)/TickCount`, 위치별 GTK_POS_TOP/BOTTOM (수평) 또는 LEFT/RIGHT (수직) 자동 선택 | `gtk_adjustment` 필드 직접 조작 + draw_value enable/disable 워크어라운드 (~15줄) | `setRange` + `setPageStep` + `setTickInterval` + `setOrientation` (~12줄) | 완전 — **TickMarks 네이티브 렌더링** (GTK2/Qt5 대비 가장 정교) |
| GetPosition | **WS 10줄** (gtk4wscomctrls.pp:350-359): `TGtk4TrackBar.Position` 프로퍼티 → `Trunc(gtk_range_get_value)` | `Trunc(gtk_range_get_value)` | `getSliderPosition` | 완전 |
| SetPosition | **WS 18줄** (gtk4wscomctrls.pp:361-377): `Position` 프로퍼티 + BeginUpdate/EndUpdate 래핑 | `gtk_range_set_value` + ChangeLock | `setSliderPosition` + BeginUpdate/EndUpdate | 완전 |
| SetOrientation | **MISS** — `RecreateWnd` (**LCL 수준 전체 재생성**). gtk4wscomctrls.pp에 override 없음 — LCL 기본 동작 | MISS (상속 — GTK2도 RecreateWnd) | `Hide → setOrientation → setInverted → Show` (재생성 불필요) | ⚠️ Qt5보다 비효율 (GTK4≡GTK2 동일 제약) |

**TGtk4Range 부모 클래스 인프라** (gtk4widgets.pas:5395-5489, **95줄**):
- `TGtk4Range` = TGtk4TrackBar/TGtk4ScrollBar의 공통 부모 클래스. GtkScale/GtkScrollbar의 공통 GtkRange 기반 기능 제공
- `CreateWidget` (**15줄**, 5417-5431): `gtk_scale_new_with_range(orientation, min, max, step)` + `set_draw_value(True)` + `set_digits(0)` 정수 표시
- `ValueChanged` 콜백 (**12줄**, 5395-5406): `value-changed` 시그널 → LCL `LM_CHANGED` 메시지 발생 + BeginUpdate/EndUpdate 재진입 방지
- `Position` 프로퍼티 (**8줄**, 5433-5440): `Trunc(gtk_range_get_value(FRange))` / `gtk_range_set_value(FRange, val)`
- `SetTickMarks` (**44줄**, 5468-5511): §4 상세 참조
- GTK2에는 이 수준의 공통 추상화 없음 — 각 위젯이 gtk_adjustment를 직접 조작

### TWSCustomUpDown

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| SetIncrement | MISS | MISS | MISS |
| SetMaxPosition | MISS | MISS | MISS |
| SetMinPosition | MISS | MISS | MISS |
| SetOrientation | MISS | MISS | MISS |
| SetPosition | MISS | MISS | MISS |
| SetUseArrowKeys | MISS | MISS | MISS |
| SetWrap | MISS | MISS | MISS |

**Note**: No platform implements any TWSCustomUpDown methods. Registration is commented out in ALL platforms (`// RegisterWSComponent(TCustomUpDown, TWSCustomUpDown)`). UpDown is handled entirely at the LCL level via TCustomUpDown emulation.

**R32 §4 ComCtrls 크로스플랫폼 코드 깊이 비교:**

| 메서드 | GTK4 (WS줄) | GTK2 (줄) | Qt5 (줄) | GTK4 접근법 | 비고 |
|--------|------------|----------|---------|-----------|------|
| ListView.CreateHandle | **9줄** → 래퍼 위임 | — (상속) | **50줄** (뷰 분기) | TGtk4ListView.Create 멀티뷰 디스패치 | Qt5가 가장 상세, GTK4 가장 간결 |
| ListView.ItemInsert | **8줄** → 래퍼 위임 | — (모델 내부) | **60줄** (서브아이템 처리) | GtkStringList/TreeView 모델 관리 | Qt5 7.5배 — 직접 QTreeWidgetItem 생성 |
| StatusBar.CreateHandle | **8줄** → 래퍼 위임 | **19줄** (인라인 API) | **16줄** (크기 그립+패널) | TGtk4StatusBar 인스턴스 생성 | GTK2 가장 직접적 |
| StatusBar.PanelUpdate | **12줄** → 래퍼 위임 | **23줄** (GList 순회) | **30줄** (SimplePanel 이중 모드) | UpdatePanel/RecreatePanels | Qt5 가장 복잡 (듀얼 모드) |

---

## 5. WSControls

### TWSControl (base for all controls)

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| GetDefaultColor | IMPL | IMPL | IMPL |
| AddControl | IMPL | IMPL | IMPL |
| GetCanvasScaleFactor | MISS | MISS | MISS |
| GetConstraints | MISS | MISS | MISS |
| ConstraintWidth | MISS | MISS | MISS |
| ConstraintHeight | MISS | MISS | MISS |

**Note**: `TGtk4WSControl` is an **empty class** (gtk4wscontrols.pp:65-68) — no method overrides. GetDefaultColor is overridden by subclasses (TWSButtonControl→`clBtnFace`, TWSCustomPanel→`clBackground`, TWSCustomForm→`clForm`). AddControl is dispatched in wincontrol.inc → TWSWinControl.AddControl(19줄). GetCanvasScaleFactor/GetConstraints/ConstraintWidth/ConstraintHeight use working base defaults.

### TWSDragImageListResolution

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| BeginDrag | STUB | IMPL | IMPL |
| DragMove | STUB | IMPL | IMPL |
| EndDrag | STUB | IMPL | IMPL |
| HideDragImage | STUB | IMPL | IMPL |
| ShowDragImage | STUB | IMPL | IMPL |

**GTK4 gaps**: All 5 methods are stubs — drag image support not implemented. GTK4에 GtkDragSource/GtkDropTarget 바인딩은 존재하나 LCL 이벤트 시스템에 미연결 (§22c). Drag-and-Drop 전체 기능 미동작.

#### TWSDragImageListResolution 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| BeginDrag | `True` 반환만 (NO-OP) | **52줄**: GDIObject 타입 분기(bitmap/pixmap/pixbuf) → pixmap/mask ref → `Gtk2Widgetset.DragImageList_BeginDrag` + DragMove | TBitmap → `TQtImage.Handle` → `TQtWidgetset.DragImageList_BeginDrag` + DragMove | ❌ **STUB** — Wayland 화면 위치 제어 불가 |
| DragMove | `True` 반환만 | `Gtk2Widgetset.DragImageList_DragMove()` | `TQtWidgetset.DragImageList_DragMove()` | ❌ **STUB** |
| EndDrag | 빈 구현 | `Gtk2Widgetset.DragImageList_EndDrag` | `TQtWidgetset.DragImageList_EndDrag` | ❌ **STUB** |
| HideDragImage | `True` 반환만 | `DragImageList_SetVisible(False)` | `DragImageList_SetVisible(False)` | ❌ **STUB** |
| ShowDragImage | `True` 반환만 | `DragMove() AND SetVisible(True)` | 잠금 상태 체크 + `DragMove() AND SetVisible(True)` | ❌ **STUB** |

**GTK4 DragImage STUB 사유**: Wayland는 `gtk_window_move()` 제거로 임의 화면 좌표에 드래그 이미지 윈도우 배치 불가. LCL 드래그 메시지/커서 변경은 정상 동작하나, **시각적 드래그 오버레이는 표시 불가**. GTK2는 GdkPixmap 기반 드래그 팝업 완전 구현.

### TWSWinControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| AddControl | IMPL | IMPL | IMPL |
| CanFocus | IMPL | IMPL | IMPL |
| ConstraintsChange | IMPL | IMPL | IMPL |
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | IMPL | IMPL | IMPL |
| GetClientBounds | IMPL | MISS | IMPL |
| GetClientRect | IMPL | MISS | IMPL |
| GetDefaultClientRect | IMPL | MISS | MISS |
| GetDesignInteractive | IMPL | MISS | IMPL |
| GetPreferredSize | IMPL | MISS | IMPL |
| GetText | IMPL | IMPL | IMPL |
| GetTextLen | IMPL | MISS | MISS |
| Invalidate | IMPL | IMPL | IMPL |
| PaintTo | IMPL | IMPL | IMPL |
| Repaint | IMPL | IMPL | IMPL |
| SetBiDiMode | IMPL | IMPL | IMPL |
| SetBorderStyle | IMPL | IMPL | IMPL |
| SetBounds | IMPL | IMPL | IMPL |
| SetChildZPosition | IMPL | IMPL | IMPL |
| SetColor | IMPL | IMPL | IMPL |
| SetCursor | IMPL | IMPL | IMPL |
| SetFont | IMPL | IMPL | IMPL |
| SetPos | IMPL | IMPL | IMPL |
| SetSize | IMPL | IMPL | IMPL |
| SetText | IMPL | IMPL | IMPL |
| SetShape | STUB | IMPL | IMPL |
| ShowHide | IMPL | IMPL | IMPL |
| ScrollBy | IMPL | IMPL | IMPL |
| AdaptBounds | STUB | MISS | MISS |
| DefaultWndHandler | STUB | MISS | MISS |
| GetDoubleBuffered | MISS | MISS | MISS |

**GTK4 gaps**: SetShape stub (GTK4 removed window shapes — Wayland 제한)
**ALL MISS**: GetDoubleBuffered (base default adequate)

#### TWSWinControl 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| AddControl | **WS 19줄** (gtk4wscontrols.pp:257-275) + **래퍼 SetParent ~60줄** (gtk4widgets.pas:4564+): `gtk4_fixed_move` GtkFixed reparent. GTK2 42줄 대비 **가장 간결** | `gtk_widget_reparent` 42줄 | `Child.setParent(Container)` 17줄 | ✅ 완전 — 모던 API |
| CanFocus | **WS 10줄** (gtk4wscontrols.pp:277-286) + **래퍼 6줄** (gtk4widgets.pas:4110-4115): `Widget^.get_can_focus` 프로퍼티. **GTK2보다 엄격**: visible/sensitive 미검사 | `GTK_WIDGET_CAN_FOCUS` **매크로**: visible+sensitive+can_focus 복합 체크 | `getFocusPolicy!=QtNoFocus` | ⚠️ **엄격** — 프로퍼티만 체크 |
| ConstraintsChange | **WS 89줄** (gtk4wscontrols.pp:138-226): Window 경로(64줄) `set_size_request` + `set_default_size` + CSS max-w/h via `SetMaxSize()`. Non-window(8줄): `set_size_request`. **`gtk_window_set_geometry_hints()` 제거**로 수동 에뮬레이션 | **4줄** (gtk2wscontrols.pp:566-569) | **6줄** (qt5wscontrols.pp:410-415) | ⚠️ GTK4 **~15배 복잡** — API 제거에 의한 수동 에뮬레이션 |
| CreateHandle | **5줄** `TGtk4Panel.Create` — GtkOverlay+GtkFixed 범용 컨테이너 (S67 구현) | `GTK2WidgetSet.CreateAPIWidget` 75+줄 | `TQtWidget.Create` 8줄 | ✅ 완전 — 범용 TWinControl 핸들 |
| DestroyHandle | `gtk_window_destroy` (toplevel) / `gtk_widget_unparent` (child) 이중경로 | `gtk_widget_destroy` 단일 | `TQtWidget.Release` | 완전 (Session 58 수정) |
| GetClientBounds | **WS 13줄** (gtk4wscontrols.pp:288-300) + **래퍼 19줄** (gtk4widgets.pas:4261-4279): `gtk_widget_get_allocation` | MISS (상속) | `QWidget_contentsRect` | 완전 |
| GetClientRect | **WS 13줄** (gtk4wscontrols.pp:302-314) + **래퍼 20줄** (gtk4widgets.pas:4240-4259): `gtk_widget_get_allocation` 원점(0,0) 오프셋 | MISS (상속) | 원점 오프셋 | 완전 |
| GetPreferredSize | **WS 6줄** (gtk4wscontrols.pp:359-364) + **래퍼 54줄** (gtk4widgets.pas:4489-4542): `gtk4_widget_measure` + `gtk4_widget_compute_bounds` GType 오버플로 메트릭 캐싱 | `gtk_widget_size_request` (deprecated) | `QWidget::sizeHint()` 7줄 | ✅ 완전 — GTK4≡Qt5 동일 패턴 |
| GetText | **WS 11줄** (gtk4wscontrols.pp:323-333) + **래퍼 4줄** (gtk4widgets.pas:3804-3807): fText 프로퍼티 | `gtk_entry/label_get_text` 직접 | `QWidget_windowTitle` | 완전 |
| Invalidate | **WS 9줄** (gtk4wscontrols.pp:385-393) + **래퍼 16줄** (gtk4widgets.pas:4635-4650): `gtk_widget_queue_draw` | `gtk_widget_queue_draw` | `QWidget_update` | 완전 |
| PaintTo | **WS 44줄** (gtk4wscontrols.pp:395-438): `gtk4_widget_paintable_new` → `GtkSnapshot.new` → `gdk4_paintable_snapshot` → `gtk4_snapshot_to_node` → `gsk4_render_node_draw(node, cairo)`. **모던 GSK 파이프라인** | **23줄**: 레거시 GdkPixmap 복사 | **7줄**: `QPixmap.grabWidget()` | ✅ **GTK4 가장 정교** — GPU 렌더링 캡처 |
| SetBorderStyle | **WS 6줄** (gtk4wscontrols.pp:454-459) + **래퍼 12줄** (gtk4widgets.pas:3693-3704): CSS `border: 1px solid` / `border: none` | 직접 GTK 호출 | 타입별 (TQtFrame/IQtEdit) | 완전 |
| SetBounds | **WS 13줄** (gtk4wscontrols.pp:440-452) + **래퍼 69줄** (gtk4widgets.pas:4281-4349): `gtk4_widget_measure` + `gtk4_widget_size_allocate` + `set_size_request`, BeginUpdate/EndUpdate 래핑 | 직접 `gtk_*` | 스크롤 오프셋 포함 | 완전 |
| SetChildZPosition | **WS 38줄** (gtk4wscontrols.pp:461-498): `gtk4_widget_insert_before`/`gtk4_widget_insert_after` GtkFixed 형제 순서 조작. 모든 자식 순회 후 정확한 위치 삽입 | `gdk_window_lower/raise/restack` | `QWidget.stackUnder` | 완전 |
| SetColor | **WS 9줄** (gtk4wscontrols.pp:500-508) + **래퍼 15줄** (gtk4widgets.pas:3677-3691): CSS `background-color: rgb(...)` | 복잡한 상태 컬러링 ~10줄 | RGB→QColor ~30줄 | 완전 (CSS 기반, 가장 간결) |
| SetCursor | **WS 6줄** (gtk4wscontrols.pp:510-515) + **래퍼 10줄** (gtk4widgets.pas:4544-4553): `gtk4_widget_set_cursor` | `gdk_window_set_cursor` | `QWidget_setCursor` | 완전 |
| SetFont | **WS 14줄** (gtk4wscontrols.pp:524-537) + **래퍼 36줄** (gtk4widgets.pas:3624-3659): Pango→CSS font (family, size, weight, style) | `gtk_widget_modify_font` (deprecated) | `setFont + QColor` | ⚠️ Font.Color CSS 분리 |
| SetPos | **WS 7줄** (gtk4wscontrols.pp:539-545) + **래퍼 13줄** (gtk4widgets.pas:4462-4474): `gtk4_fixed_move` | 직접 GTK | `TQtWidget.move` | 완전 |
| SetSize | **WS 8줄** (gtk4wscontrols.pp:547-554): `SetBounds` 위임 (래퍼 69줄 공유) | 별도 호출 | `resize(W,H)` 직접 | ⚠️ 위치 재쿼리 오버헤드 |
| SetText | **WS 9줄** (gtk4wscontrols.pp:564-572) + **래퍼 5줄** (gtk4widgets.pas:3809-3813): fText 프로퍼티 | `gtk_entry/label_set_text` | `QWidget_setWindowTitle` | 완전 |
| SetShape | **WS 6줄** (gtk4wscontrols.pp:517-522): **의도적 STUB** `Result := False`. GTK4/Wayland에서 shape API 완전 제거 | `gdk_window_shape_combine_region` 완전 | `QWidget_setMask` 완전 | ❌ **의도적 STUB** — Wayland 제한 |
| ShowHide | `ShowAll() + realize()` 비-스크롤 위젯 실현 | `gtk_widget_show_all` | 폰트 동기화 포함 | 완전 |
| ScrollBy | **46줄** (gtk4wscontrols.pp:597-642): `gtk_scrolled_window_get_h/vadjustment` → `NewPos = value - Delta` 클램핑 `[0, upper-page_size]` → `set_value(NewPos)` + `ScrollX/ScrollY` 캐싱 + `Invalidate()` | **32줄**: GtkLayout adjustment, idle deferred redraw 최적화 포함 | **52줄**: 이중경로 (TQtCustomControl + TQtAbstractScrollArea) + tracking 모드 인식 | ✅ 완전 — GTK2에 idle deferred redraw 최적화 없으나 기능 동일. ScrollX/Y 캐싱은 내부용 |
| SetBiDiMode | `Widget^.set_direction(GTK_TEXT_DIR_*)` | `gtk_widget_set_direction` | `QWidget_setLayoutDirection` | 완전 |

### TWSCustomControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | IMPL |

**GTK4 gaps**: None

#### TWSCustomControl 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | `TGtk4CustomControl.Create()` Pascal 래퍼 — GtkOverlay + GtkFixed + PaintArea 위젯 트리 구성 | ❌ 미구현 (TWSWinControl 상속) | `TQtCustomControl.Create()` 래퍼 | 완전 — GTK2는 상속으로 처리 |

**R32 §5 WinControl 크로스플랫폼 코드 깊이 비교:**

| 메서드 | GTK4 (WS줄) | GTK2 (줄) | Qt5 (줄) | 접근법 차이 | 비고 |
|--------|------------|----------|---------|-----------|------|
| SetBounds | **13줄** → 래퍼 69줄 | **110줄** (constraint+geometry) | **51줄** (스크롤 오프셋) | GTK4: 래퍼 위임. GTK2: `gtk_window_set_geometry_hints` + TGdkGeometry. Qt5: scroll-aware resize | GTK2 가장 복잡 (geometry API) |
| PaintTo | **44줄** GSK RenderNode | **84줄** GdkPixbuf raster | **40줄** QPixmap render | GTK4: GtkWidgetPaintable→GskRenderNode→cairo. GTK2: gdk_pixbuf_get_from_drawable+3 헬퍼. Qt5: QWidget_render→drawPixmap | GTK4 현대 벡터, GTK2 레거시 래스터 |
| SetFont | **14줄** → 래퍼 36줄 CSS | **19줄** (4 상태 설정) | **25+줄** (palette 폴백) | GTK4: CSS `font:` 속성. GTK2: GTK state별 SetWidgetFont. Qt5: 팔레트 + ForceColor | 3플랫폼 모두 다른 접근 |
| GetPreferredSize | **6줄** → 래퍼 54줄 | — (상속) | **7줄** → 래퍼 | GTK4: gtk_widget_measure + GType 캐싱. Qt5: sizeHint() | GTK4 ≡ Qt5 패턴 (래퍼 위임) |

---

## 6. WSDIalogs

### TWSCommonDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | STUB | IMPL | IMPL |
| ShowModal | IMPL | IMPL | IMPL |
| DestroyHandle | IMPL | IMPL | IMPL |
| QueryWSEventCapabilities | MISS | MISS | MISS |

**GTK4 gaps**: CreateHandle is stub (subclasses override)
**ALL MISS**: QueryWSEventCapabilities at TWSCommonDialog level (overridden by specific dialog subclasses: TWSOpenDialog, TWSFontDialog, etc.)

#### Dialog WS Classes 구현 수준 상세

| Class.Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|-------------|----------|----------|---------|----------|
| CommonDialog.ShowModal | **34줄** (gtk4wsdialogs.pp:1317-1350): `set_application` + `set_modal(True)` + `set_transient_for` + `present()` + **DoExecute 중첩 이벤트 루프** (`Application.HandleMessage` while 루프). `gtk_dialog_run()` 제거 대응 — GTK4 패턴 정확 | **17줄**: `GtkWindowShowModal()` 블로킹 (`gtk_dialog_run` 1줄) | **1줄**: `TQtDialog.exec` | ✅ 완전 — `gtk_dialog_run` 제거 정확 대응 |
| CommonDialog.DestroyHandle | `TGtk4Dialog.Free` (래퍼 해제) | `DestroyLCLComponent` | `TQtDialog.Release` | 완전 |
| FileDialog.CreateHandle | **6줄 live** (gtk4wsdialogs.pp:1196-1233, 주석 GTK2 코드 ~26줄). 실제 로직은 `TGtk4FileDialog.Create` (gtk4widgets.pas:11977-12049, **73줄**): `gtk_file_chooser_dialog_new` + GTK4 GFile API + `gtk4_file_chooser_set_current_folder` (GFile 경유) + **TGtk4DialogBtnInfo** 버튼→응답 브릿지 | `gtk_file_chooser_dialog_new` + 문자열 API (~49줄) | `TQtFileDialog.Create` (~23줄) | ⚠️ WS 코드 얕으나 **래퍼 73줄 깊음** — GFile API 정확 사용 |
| OpenDialog.CreateHandle | **75줄** (gtk4wsdialogs.pp:1106-1180): GFile API(`gtk4_file_chooser_set_file`), 멀티선택(`gtk4_file_chooser_set_select_multiple`), 히스토리(`gtk4_file_chooser_set_current_folder` GFile 경유), 필터(`gtk4_file_chooser_add_filter`), 프리뷰(`CreatePreviewDialogControl`), 초기 파일명(`gtk4_file_chooser_set_current_name`) | **92줄**: 문자열 기반 API, 유사 기능 + 숨김파일 옵션 | **22줄**: TQtFilePreviewDialog 또는 TQtFileDialog | ✅ 완전 — 현대적 GFile API 사용 |
| OpenDialog.QueryWSEventCap | `[cdecWSPerformsDoShow]` | `[cdecWSPerformsDoShow]` | `[cdecWSNoCanCloseSupport]` | 완전 |
| SaveDialog.QueryWSEventCap | `[cdecWSPerformsDoShow, cdecWSNoCanCloseSupport]` — ✅ S61 수정 | `[cdecWSPerformsDoShow]` | `[cdecWSNoCanCloseSupport]` | ✅ 완전 |
| ColorDialog.CreateHandle | `TGtk4newColorSelectionDialog.Create` 래퍼 (4줄). **래퍼 84줄** (gtk4widgets.pas:12226-12309): `gtk_color_chooser_dialog_new` + GdkRGBA(float) ↔ LCL TColor 변환 정확 + 알파 비활성(`gtk_color_chooser_set_use_alpha(False)`). **TGtk4DialogBtnInfo** 버튼→응답 브릿지 (GTK4 4.10+ 대응) | `gtk_color_selection_dialog_new` + WidgetInfo + 콜백 (8줄) | `return 0` (ShowModal에서 처리) | ✅ 완전 — RGBA float 변환 정확 |
| FontDialog.CreateHandle | `TGtk4FontSelectionDialog.Create` 래퍼 (4줄). **래퍼 115줄** (gtk4widgets.pas:12053-12166): `gtk_font_chooser_dialog_new` + Pango font description 설정(`pango_font_description_set_family/size/weight/style`) + **strikeout/underline 보존** (PangoAttrList 읽기→설정) + **TGtk4DialogBtnInfo** 버튼→응답 브릿지 | `gtk_font_selection_dialog_new` + apply_button 시그널 + preview_text (~57줄) | `return 0` (ShowModal에서 처리) | ⚠️ IMPL* — strikeout/underline **편집 불가** (보존만), fdApplyButton/PreviewText 미지원 |
| FontDialog.ShowModal | **상속** — CommonDialog.ShowModal 로직. 폰트 추출은 래퍼 `DoClose` 콜백에서 Pango description → TFont 변환 (Family, Size, Weight, Slant, Strikeout, Underline 전부 매핑) | **상속** + SetCallbacks에서 apply_button 시그널 연결 | **74줄**: QFont 생성 → `QFontDialog_getFont` → TFont 매핑 | ⚠️ 폰트 추출 로직이 래퍼에 숨김 (WS 코드에서 추적 어려움) |
| SelectDir.QueryWSEventCap | **5줄** (gtk4wsdialogs.pp:1398-1402): `[cdecWSPerformsDoShow]` | `[cdecWSPerformsDoShow]` | `[cdecWSNoCanCloseSupport]` | 완전 |
| ColorDialog.QueryWSEventCap | **5줄** (gtk4wsdialogs.pp:1406-1410): `[cdecWSPerformsDoShow]` | `[cdecWSPerformsDoShow]` | `[cdecWSNoCanCloseSupport]` | 완전 |
| FontDialog.QueryWSEventCap | **5줄** (gtk4wsdialogs.pp:1374-1378): `[cdecWSPerformsDoShow]` | `[cdecWSPerformsDoShow]` | `[cdecWSNoCanCloseSupport]` | 완전 |

**GTK4 Dialog 아키텍처 특성:**
- 모든 다이얼로그 생성이 **래퍼 클래스로 위임** (TGtk4FileDialog, TGtk4newColorSelectionDialog 등) → WS 레벨 코드 **투명성 낮음**
- `gtk_dialog_run()` 제거 → `Application.HandleMessage` 루프로 모달 구현 (정확하지만 복잡)
- GFile 기반 파일 경로 처리 (gtk4_file_chooser_set_file) → GTK2의 문자열 기반보다 현대적
- **TGtk4DialogBtnInfo 버튼→응답 브릿지** (GTK4 4.10+ 대응): GTK4 4.10에서 `gtk_dialog_add_button`의 button→response 시그널 자동 연결이 깨짐. `TGtk4DialogBtnInfo` 클로저 패턴으로 각 버튼의 `clicked` 시그널을 수동 연결 → `gtk_dialog_response(ResponseId)` 호출. **모든 다이얼로그** (File/Color/Font)에 적용
- **PopupMenu.Popup** (gtk4wsmenus.pp:656-715, **60줄**): `Gtk4RebuildMenuModel()` → `GtkPopoverMenu` 생성 → `gtk4_popover_set_pointing_to(ARect)` + `gtk4_popover_popup()` → **중첩 `g_main_loop_run()` 블로킹 이벤트 루프**. `closed` 시그널에서 `g_main_loop_quit()` 호출로 탈출. ⚠️ `g_main_loop_run()` 중첩은 **deprecated 패턴** 이나 동작은 정상

### TWSFileDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |

### TWSOpenDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| QueryWSEventCapabilities | IMPL | IMPL | IMPL |

### TWSSaveDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| QueryWSEventCapabilities | IMPL | IMPL | IMPL |

~~**GTK4 IMPL* 이슈**~~: ✅ **수정됨 (Session 61, Bug#3)**: `cdecWSNoCanCloseSupport` 추가 완료. 5개 다이얼로그 모두 `[cdecWSPerformsDoShow, cdecWSNoCanCloseSupport]` 반환

### TWSSelectDirectoryDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | MISS | MISS | IMPL |
| ShowModal | MISS | MISS | IMPL |
| QueryWSEventCapabilities | IMPL | IMPL | IMPL |

**GTK4 gaps**: CreateHandle, ShowModal (Qt5 has custom directory dialog)

### TWSColorDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| ShowModal | MISS | MISS | IMPL |
| QueryWSEventCapabilities | IMPL | IMPL | IMPL |

### TWSFontDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL* | IMPL | IMPL |
| ShowModal | MISS | MISS | IMPL |
| QueryWSEventCapabilities | IMPL | IMPL | IMPL |

**GTK4 IMPL* 이슈**:
- `CreateHandle` — GtkFontChooserDialog 사용. **fdApplyButton 미동작**: Apply 버튼 없음, `OnApplyClicked` 절대 발동 안됨. **PreviewText 미지원**: `set_preview_text()` API 제거됨. **Strikeout/Underline 편집 불가** (보존만 — 텍스트 속성, 폰트 속성 아님)

### TWSTaskDialog

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| Execute | MISS | MISS | MISS |

**Note**: Only Win32 has a platform-specific override (native Windows TaskDialog API). GTK4 registers base TWSTaskDialog class in wsfactory (LCL emulation via `TLCLTaskDialog`), no platform-specific Execute.

**R32 §6 Dialogs 크로스플랫폼 코드 깊이 비교:**

| 메서드 | GTK4 (줄) | GTK2 (줄) | Qt5 (줄) | 접근법 차이 | 비고 |
|--------|----------|----------|---------|-----------|------|
| CommonDialog.ShowModal | **34줄** (application modal loop) | **18줄** (gtk_dialog_run 패턴) | **4줄** (`exec` 블로킹) | GTK4: `present()` + DoExecute 루프 (gtk_dialog_run 제거됨). GTK2: gtk_dialog_run. Qt5: `TQtDialog.exec` | Qt5 가장 간결, GTK4 가장 복잡 (API 변경 대응) |
| FileDialog.CreateHandle | **75줄** (GFile+히스토리+필터+프리뷰) | **93줄** (UTF-8 변환 오버헤드) | **25-50줄** (네이티브 다이얼로그) | GTK4: TGtk4FileDialog 래퍼. GTK2: 인라인 + UTF8ToSys. Qt5: 옵션 설정 위주 | GTK2 가장 긴 (UTF-8 처리) |
| ColorDialog.CreateHandle | **5줄** (생성자 위임) | **14줄** (인라인 초기화) | **4줄** (모달 전용) | GTK4/Qt5: 생성자 한 줄. GTK2: WidgetInfo + SetCallbacks 인라인 | Qt5 핸들 없음 (modal-only 패턴) |
| FontDialog.CreateHandle | **4줄** (생성자 위임) | **40+줄** (XLFD 폰트 포맷) | **5줄** (모달 전용) | GTK4: TGtk4FontSelectionDialog.Create. GTK2: XLFD 설정 + ApplyButton + preview | GTK2 10배 — 레거시 폰트 포맷 처리 |

---

## 7. WSExtCtrls

### TWSCustomSplitter

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | MISS |

**GTK4 advantage**: Has splitter CreateHandle. GTK2/Qt5는 TWSCustomSplitter 재정의 없음 — LCL 수준 드래그 처리.

#### TWSCustomSplitter 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | `TGtk4Splitter.Create()` — **TGtk4Panel 상속** (GtkPaned 아님). LCL 수동 드래그 로직 사용 | ❌ 재정의 없음 | ❌ 재정의 없음 | ⚠️ **네이티브 분할선 미사용** — GtkPanel + LCL 드래그 |

**아키텍처 주의**: `TGtk4Splitter extends TGtk4Panel` (단일 컨테이너) vs `TGtk4Paned` (PairSplitter용, GtkPaned). 두 분할 시스템이 분리됨.

### TWSCustomPanel

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetDefaultColor | IMPL | IMPL | IMPL |
| SetBorderStyle | IMPL | IMPL | MISS |
| SetColor | MISS | IMPL | MISS |

**GTK4 gaps**: SetColor (GTK2-specific, usually handled by TWSWinControl)

#### TWSCustomPanel 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **16줄** `TGtk4Panel.CreateWidget` (gtk4widgets.pas:4797-4817): GtkOverlay(메인) → [GtkFixed(자식 레이아웃) + GtkDrawingArea(LCL 페인트)]. `SetupPaintArea` 호출로 커스텀 드로잉 지원. **GTK2와 위젯 다름**: GTK4=GtkOverlay, GTK2=GtkFrame | **39줄**: `gtk_frame_new()` + `gtk_frame_set_shadow_type(BorderStyleShadowMap[])` + `gtk_widget_modify_style(Style^.xthickness/ythickness)` + `CreateFixedClientWidget()` + `gtk_container_add` — **3D 베벨 보더 지원** | `TQtFrame.Create()` + `setFrameShape(TBorderStyleToQtFrameShapeMap[])` | ⚠️ GTK2 대비 기능 축소 (3D 보더 없음) |
| GetDefaultColor | **10줄** (gtk4wsextctrls.pp:208-217): 정적 배열 `clBackground`(Brush), `clBtnText`(Font) | **10줄** (gtk2wsextctrls.pp:244-253): 동일 | **10줄** (qt5wsextctrls.pp:182-191): 동일 | ✅ 완전 — **모든 플랫폼 100% 동일 코드** |
| SetBorderStyle | **8줄** (gtk4wsextctrls.pp:219-226): `TGtk4Panel.BorderStyle` 프로퍼티 위임 → CSS 기반 (gtk4widgets.pas:3693-3704): `bsSingle` → `'border: 1px solid; '`, `bsNone` → `'border: none; '`. `DoBeforeLCLPaint` (4819-4842, 24줄)에서 커스텀 보더 렌더링 | `gtk_frame_set_shadow_type()` + `gtk_widget_modify_style(xthickness, ythickness)` — **두께+그림자 재구성** | Qt5는 **SetBorderStyle override 없음** — CreateHandle에서 `setFrameShape` 1회만 | ⚠️ **최소** — CSS flat border만. GTK2의 3D shadow + 두께 조절 없음. 커스텀 페인트로 보완 |
| SetColor | ❌ **WS MISS** — 래퍼 `TGtk4Panel.SetColor` (gtk4widgets.pas:4792-4795, 4줄)은 `inherited` 호출만. **그러나** `DoBeforeLCLPaint` (4819-4842, **24줄**)에서 `LCLObject.Color` → `fillRect(0,0,W,H)` 로 실질 배경색 렌더링 수행 — **커스텀 페인트 경로**로 색상 반영됨 | **13줄** (gtk2wsextctrls.pp:255-268): `GetMainWidget` → `SetWidgetColor` 상태별 색상 전파 — **GTK2 스타일 시스템 직접 API** | ❌ MISS (inherited) | ⚠️ **간접적 동작**: SetColor 호출 → invalidate → 다음 paint에서 반영. GTK2는 즉시 반영. 실질 기능은 동등 |

### TWSCustomRadioGroup / TWSCustomCheckGroup

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | IMPL |

#### TWSCustomRadioGroup/CheckGroup 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| RadioGroup.CreateHandle | **9줄** (gtk4wsextctrls.pp:160-168): `TGtk4GroupBox.Create()` 래퍼 → GtkFrame + GtkOverlay + [GtkFixed + GtkDrawingArea]. Caption 텍스트 설정 | ❌ 미구현 (stub 클래스) | **16줄** (qt5wsextctrls.pp:203-218): `TQtGroupBox.Create()` + `GroupBoxType := tgbtRadioGroup` + `AttachEvents` | ✅ GTK4/Qt5 동등 — GTK2 미구현 |
| CheckGroup.CreateHandle | **9줄** (gtk4wsextctrls.pp:172-180): `TGtk4GroupBox.Create()` — RadioGroup과 **동일 래퍼 클래스** 재사용 | ❌ 미구현 (stub 클래스) | **16줄** (qt5wsextctrls.pp:229-244): `TQtGroupBox.Create()` + `GroupBoxType := tgbtCheckGroup` + `AttachEvents` | ✅ 동등 |

**GTK4 GroupBox 래퍼 구현** (gtk4widgets.pas):
- `TGtk4GroupBox.CreateWidget` (4860-4879, 20줄): GtkFrame → GtkOverlay → [GtkFixed + GtkDrawingArea]. GtkFrame 라벨 정렬 설정
- `TGtk4GroupBox.setText` (4892-4906, 15줄): GtkFrame 라벨 위젯 생성/갱신, 빈 캡션 시 nil 처리
- **RadioGroup/CheckGroup 구분 없음**: 동일한 `TGtk4GroupBox` 래퍼 사용. 개별 라디오/체크 버튼은 LCL이 자식 컨트롤로 관리

### TWSCustomTrayIcon / TGtk4WSTrayIcon

Note: gtk4wsextctrls.pp declares stub TGtk4WSCustomTrayIcon. The actual implementation is in **gtk4wstrayicon.pas** as TGtk4WSTrayIcon using D-Bus/SNI (StatusNotifierItem) protocol.

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| Hide | IMPL | IMPL | IMPL |
| Show | IMPL | IMPL | IMPL |
| InternalUpdate | IMPL | IMPL | IMPL |
| GetPosition | IMPL* | IMPL | IMPL |
| ShowBalloonHint | IMPL | MISS | IMPL |
| GetCanvas | MISS | MISS | IMPL |

**GTK4 gaps**: GetCanvas only (Qt5-specific). All other methods fully implemented via D-Bus SNI in gtk4wstrayicon.pas.
**GTK4 IMPL* 이슈**:
- `GetPosition`: **항상 (0,0) 반환** — SNI 프로토콜에 트레이 아이콘 위치 개념 없음. 패널/DE가 위치 결정
- **보안**: 아이콘 PNG를 `/tmp/lcl-sni-$USER/`에 world-readable로 저장. `XDG_RUNTIME_DIR` 사용 권장
- **안정성**: `RegisterWithWatcher`에서 무한 타임아웃 D-Bus 블로킹 호출 — Watcher 미응답 시 앱 중단

#### TWSCustomTrayIcon 구현 수준 상세

gtk4wsextctrls.pp의 TGtk4WSCustomTrayIcon는 모든 메서드를 `inherited`로 패스스루. 실제 구현은 **gtk4wstrayicon.pas**의 TGtk4WSTrayIcon에서 SNI D-Bus 프로토콜로 구현.

| Method | GTK4 (gtk4wstrayicon.pas) | GTK2 | Qt5 | GTK4 품질 |
|--------|--------------------------|------|-----|----------|
| Show | `g_bus_get_sync(G_BUS_TYPE_SESSION)` + `g_dbus_node_info_new_for_xml()` + `g_dbus_connection_register_object()` + `dbusmenu_server_new()` 전체 SNI 등록 | `inherited` 패스스루 | `inherited` 패스스루 | ✅ **매우 깊음** — 전체 D-Bus SNI 등록 |
| Hide | D-Bus 객체 해제 + `g_dbus_connection_unregister_object()` | `inherited` 패스스루 | `inherited` 패스스루 | ✅ 완전 |
| InternalUpdate | `gdk_pixbuf_save_to_bufferv()` PNG 인코딩 → `g_bytes_icon_new()` + D-Bus 프로퍼티 변경 시그널 | `inherited` 패스스루 | `inherited` 패스스루 | ✅ **깊음** — 아이콘 픽셀 완벽 인코딩 |
| GetPosition | 항상 `(0,0)` 반환 | `inherited` 패스스루 | `inherited` 패스스루 | ⚠️ **제한** — SNI에 위치 개념 없음 |
| ShowBalloonHint | `g_notification_new()` + `g_application_send_notification()` GNotification API | 미구현 | QSystemTrayIcon balloon | ✅ 완전 — GTK2보다 우수 |

**GTK4 TrayIcon 아키텍처 특이사항**:
- **dbusmenu-glib 의존**: `dbusmenu_server_new()` / `dbusmenu_menuitem_*` 함수로 컨텍스트 메뉴 D-Bus 노출
- **Activate/ContextMenu/Scroll**: D-Bus 메서드 콜백으로 직접 처리
- **아이콘 인코딩**: pixbuf → PNG → GBytesIcon → D-Bus 전송 (SNI 스펙 준수)
- **GTK2/Qt5 대비 매우 깊은 구현**: GTK2는 GtkStatusIcon (deprecated), Qt5는 QSystemTrayIcon에 위임

---

## 8. WSForms

### TWSScrollingWinControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | MISS |
| ScrollBy | IMPL | MISS | MISS |
| SetColor | MISS | IMPL | MISS |

#### TWSScrollingWinControl 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **33줄** `TGtk4ScrollingWinControl.CreateWidget` (gtk4widgets.pas:10492-10524): GtkScrolledWindow → GtkOverlay → [GtkFixed + GtkDrawingArea]. `'lcl-scroll-fixed'` 태그 (GtkFixed minimum size 0 유지, GTK2 GtkLayout 동작 호환). `POLICY_NEVER` + 오버레이/키네틱 비활성 | **40줄**: `gtk_scrolled_window_new` + shadow_type + POLICY_NEVER + **8개 시그널 콜백** (change-value, value-changed, button-press 등) | `TQtMainWindow` 프레임리스 + ScrollArea(조건부, QTSCROLLABLEFORMS) | ✅ GTK2와 동등 복잡도, **GtkOverlay paint 계층 추가** (LCL 커스텀 드로잉 지원) |
| ScrollBy | **45줄** `TGtk4WSWinControl.ScrollBy` (gtk4wscontrols.pp:597-642): `gtk_scrolled_window_get_hadjustment` → `NewPos = value - DeltaX` 클램핑 `[0, upper-page_size]` → `gtk_adjustment_set_value(NewPos)`. 수직 동일. `ScrollX/ScrollY` 내부 캐싱 + `Invalidate()` 호출 | **24줄**: GtkLayout adjustment 사용, 동일 클램핑 로직. idle deferred redraw (GTK2 paint blocking 워크어라운드) | **8줄**: `Widget.ScrollArea.scroll(DeltaX, DeltaY)` 위임 (ScrollArea 없으면 NO-OP) | ✅ **완전** — 양축 경계 검사, 조정값 캐싱, Qt5보다 깊은 구현 |
| SetColor | ❌ MISS — TWSWinControl에서 처리 | **14줄**: ScrolledWindow → GtkLayout 자식 위젯에 명시적 색상 전파 | MISS | ⚠️ GTK2만 자식 위젯에 명시적 색상 전파 |

### TWSCustomFrame

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | MISS | MISS | IMPL |
| ScrollBy | MISS | MISS | IMPL |

**GTK4 note**: Inherits from TGtk4WSScrollingWinControl which has both. Qt5는 별도 TQtWSCustomFrame.ScrollBy 구현 (`Widget.ScrollArea.scroll` 위임).

### TWSCustomForm

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CanFocus | IMPL | IMPL | IMPL |
| CreateHandle | IMPL | IMPL | IMPL |
| GetDefaultClientRect | IMPL | MISS | IMPL |
| GetDefaultColor | IMPL | MISS | MISS |
| SetBounds | IMPL | MISS | MISS |
| ShowHide | IMPL | IMPL | IMPL |
| CloseModal | IMPL | MISS | IMPL |
| DestroyHandle | MISS | MISS | IMPL |
| SetAllowDropFiles | IMPL | IMPL | IMPL |
| SetAlphaBlend | IMPL | IMPL | IMPL |
| SetBorderIcons | IMPL | IMPL | IMPL |
| SetFormBorderStyle | IMPL | IMPL | IMPL |
| SetFormStyle | STUB | IMPL | IMPL |
| SetIcon | IMPL | IMPL | IMPL |
| ShowModal | IMPL | IMPL | IMPL |
| SetRealPopupParent | IMPL | IMPL | IMPL |
| SetShowInTaskbar | IMPL | IMPL | IMPL |
| SetZPosition | IMPL | MISS | MISS |
| ScrollBy | IMPL | IMPL | IMPL |
| SetColor | MISS | IMPL | MISS |
| ActiveMDIChild | STUB | MISS | IMPL |
| Cascade | STUB | MISS | IMPL |
| GetClientHandle | STUB | MISS | IMPL |
| GetMDIChildren | STUB | MISS | IMPL |
| Next | STUB | MISS | IMPL |
| Previous | STUB | MISS | IMPL |
| Tile | STUB | MISS | IMPL |
| MDIChildCount | STUB | MISS | IMPL |
| SetModalResult | MISS | MISS | MISS |
| ArrangeIcons | MISS | MISS | MISS |
| GetDefaultDoubleBuffered | MISS | MISS | MISS |

**GTK4 gaps**: SetFormStyle stub (no set_keep_above in GTK4 4.6), MDI stubs (platform limitation), DestroyHandle
**GTK4 quality**: SetBounds=IMPL — `gtk_window_set_default_size`만 사용 가능 (GTK4에서 `gtk_widget_size_allocate` 직접 호출 금지). Wayland에서 윈도우 위치 제어 불가 (`gtk_window_move` 제거됨).
**ALL MISS**: SetModalResult (base default adequate), ArrangeIcons (MDI), GetDefaultDoubleBuffered (base returns False)

#### TWSCustomForm 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CanFocus | **8줄** (gtk4wsforms.pp:171-178): `AWinControl.HandleAllocated` 체크 → `Widget^.get_can_focus` 프로퍼티 반환. **GTK2보다 보수적**: GTK2는 `GTK_WIDGET_VISIBLE` 매크로 (visible+mapped 체크), GTK4는 프로퍼티만 | `GTK_WIDGET_VISIBLE` 검사 | 포커스 정책 검사 | 완전 |
| CreateHandle | **10줄** WS (gtk4wsforms.pp:191-200 ~~180-189~~ R32 정정 — 180-189는 GetDefaultClientRect) + `TGtk4Window.Create` 래퍼 위임 (**43줄**). 실제 `CreateWidget` **144줄** (gtk4widgets.pas:10920-11063): 6-depth 위젯 트리 + GMenu + adjustment 시그널 + CSS | 직접 gtk_window_new (~120줄) | TQtMainWindow/TQtWidget + UpdateWindowFlags (~90줄) | 완전 — WS 가장 간결, 래퍼에 로직 집중 |
| GetDefaultClientRect | **12줄** (gtk4wsforms.pp:191-202): 위젯 할당 크기 + `GetNonClientOverhead` 보정. 메뉴바 높이 3단 폴백 계산 포함 | MISS | `QWidget_contentsRect` | 완전 (GTK4 고유) |
| SetBounds | **10줄** WS (gtk4wsforms.pp:204-213) + 래퍼 **46줄** `TGtk4Window.SetBounds` (gtk4widgets.pas): `gtk_window_set_default_size` (위치 아닌 크기만). GTK4에서 `gtk_widget_size_allocate` 직접 호출 금지. **Wayland에서 위치 이동 불가** | MISS (상속) | MISS (상속) | 완전 (GTK4 고유) — 크기만, 위치는 Wayland 제한 |
| ShowHide | **100줄** (gtk4wsforms.pp:246-345): `set_transient_for(GetTransientParent)` + 상태별 분기: **Visible=True**: `Minimize`→`minimize()`, `ShowInTaskbar` 처리 → `present()` + `realize()`. **Visible=False**: `withdraw()` + `unrealize()`. **모달 체인**: transient parent 설정으로 WM 스태킹 순서 보장 | **150+줄**: 복잡 포커스 추적 (Compiz/Mutter WM 감지 포함) | **260줄**: 플랫폼별 분기 (Darwin/Windows/X11) | ⚠️ 중간 — non-modal-over-modal 미구현, fsStayOnTop 미동작 |
| CloseModal | **6줄** (gtk4wsforms.pp:348-353): `TGtk4Window.Close` 래퍼 위임 — `DoClose` 내부 메서드 호출 | MISS | `QtCloseModal` | 완전 |
| SetAlphaBlend | **8줄** (gtk4wsforms.pp:356-363): `Widget^.set_opacity(Value/255)` (widget-level float). 0=투명, 255=불투명 | `gtk_window_set_opacity` | `setWindowOpacity` | 완전 |
| SetBorderIcons | **12줄** (gtk4wsforms.pp:365-376): `TGtk4Window.SetBorderIcons` 래퍼 위임 — `set_deletable(biSystemMenu in Icons)`. **GTK4 고유**: `deletable`만 제어 가능 (minimize/maximize는 WM 관리) | 직접 GDK hints (biMinimize/biMaximize/biHelp 포함) | Qt window flags 조작 | ⚠️ GTK4는 deletable만 — GTK2보다 제한적 |
| SetFormBorderStyle | **18줄** (gtk4wsforms.pp:378-395): `TGtk4Window` 프로퍼티 위임 → `set_decorated(bsNone 제외)` + `set_resizable(bsSizeable/bsSizeToolWin)` | 직접 GDK hints | Qt window flags | 완전 |
| SetFormStyle | **STUB** (gtk4wsforms.pp:484-491): 빈 begin/end + 주석. GTK4 4.6에서 `gtk_window_set_keep_above` 제거됨. `present()` 사용 시 focus bouncing 발생하므로 의도적 no-op | `gtk_window_set_keep_above`/`below` 직접 API | `QtWindowStaysOnTopHint` 플래그 | ❌ **의도적 STUB** — GTK4 4.6 API 부재 |
| SetIcon | **9줄** (gtk4wsforms.pp:397-405): `TGtk4Window.Icon` 프로퍼티 → pixbuf → `gtk_window_set_icon_name` (단일 사이즈) | 복잡 멀티사이즈 설정 (60+줄) | 단일 아이콘 핸들 (9줄) | 완전 (멀티사이즈 미지원) |
| ShowModal | **15줄** (gtk4wsforms.pp:407-421): `TGtk4Window.ShowModal` 래퍼 위임 — `set_modal(True)` + `present()` + DoExecute 블로킹 이벤트 루프 | `gtk_dialog_run` 기반 | Qt modal loop | 완전 |
| SetRealPopupParent | **8줄** (gtk4wsforms.pp:423-430): `set_transient_for(Parent.Widget)` | `set_transient_for_window` | Qt parent widget 설정 | 완전 |
| SetShowInTaskbar | **10줄** (gtk4wsforms.pp:432-441): `TGtk4Window` 프로퍼티 → `skip_taskbar_hint` 에뮬레이션 | `gdk_window_set_skip_taskbar_hint` | Qt window hint 조작 | 완전 |
| SetAllowDropFiles | **32줄** (gtk4wsforms.pp:405-436 ~~443-474~~ R32 정정): GtkDropTarget 이벤트 컨트롤러 + `'drop'` 시그널 연결 — `GdkFileList` 타입 수신 → LCL `WM_DROPFILES` 메시지 발생 | `gtk_drag_dest_set/unset` 단순 | 미구현 | ✅ 완전 — GTK4가 가장 정교 (이벤트 컨트롤러 아키텍처) |
| ScrollBy | `TGtk4WSWinControl.ScrollBy` 위임 (§5 상세 참조, 46줄) | GtkLayout 사용 (200+줄) | QScrollArea 사용 | 완전 |
| MDI 8개 메서드 | 모두 **STUB** (nil/0/False 반환, gtk4wsforms.pp:504-570) | 모두 MISS | **완전 구현** (QMdiArea) | ❌ MDI 미지원 (GTK4 제한) |

**GTK4 Forms 핵심 차이:**
- `ConstraintsChange` **~190줄** 워크어라운드 (3개 프로시저) — GTK4에서 `gtk_window_set_geometry_hints` 제거됨 → CSS max-w/h + FrameClock after-paint + X11 `XSetWMNormalHints`로 대체 (§22b 상세)
- `ShowHide`에서 non-modal-over-modal, stay-on-top 미처리 → GTK2/Qt5 대비 모달 대화상자 워크플로 취약
- X11 포커스 워크어라운드 미구현 (GTK2는 Compiz/Mutter 감지 포함)
- `CreateHandle`은 WS 수준 43줄이나, 실제 `TGtk4Window.CreateWidget`은 **144줄** (§22b 상세)

**R31 크로스플랫폼 비교 (코드 깊이):**

| 메서드 | GTK4 | GTK2 | Qt5 | 비고 |
|--------|------|------|-----|------|
| SetFormStyle | **19줄** CSS class 기반 (`always_on_top`/`always_on_bottom`) | **9줄** `gtk_window_set_keep_above/below` 직접 API | **~15줄** QtWindowStaysOnTopHint 플래그 | GTK4 CSS 방식은 compositor 의존 — GTK2 API가 더 신뢰성 높음 |
| SetAllowDropFiles | **32줄** (gtk4wsforms.pp:405-436) GtkDropTarget 이벤트 컨트롤러 + GdkFileList + `WM_DROPFILES` 메시지 생성 | **8줄** `gtk_drag_dest_set/unset` 단순 on/off | **미구현** | ✅ **GTK4가 가장 정교** — 이벤트 컨트롤러 아키텍처로 타입 안전성 확보 (GTK2의 4배 코드) |
| CloseModal | **6줄** `TGtk4Window.Close` 래퍼 위임 | **MISS** (GTK2 미구현) | **~8줄** `QtCloseModal` | GTK4 > GTK2 (GTK2 누락 메서드) |
| SetBorderIcons | **12줄** `set_deletable` 만 | **18줄** GDK hints (minimize/maximize/help 포함) | **~12줄** Qt flags | ⚠️ GTK4 < GTK2 (deletable만 제어 가능) |
| ShowHide | **100줄** | **150+줄** (WM 감지 포함) | **260줄** (플랫폼 분기) | GTK4 가장 간결하나 기능 불완전 |

### TWSHintWindow

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| ShowHide | IMPL | IMPL | IMPL |

#### TWSHintWindow 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **5줄** (gtk4wsforms.pp:665-669): `TGtk4HintWindow.Create(AWinControl, AParams)` 래퍼 위임. `CreateWidget` **24줄** (gtk4widgets.pas:11736-11759): `gtk4_window_new` (GTK4에서 `GTK_WINDOW_POPUP` 제거됨) → GtkBox(vertical) → GtkFixed 컨테이너. `set_focusable(False)` 설정. GTK4에서 팝업은 GtkPopover 사용 권장이나 HintWindow는 기존 GtkWindow 유지 | GtkWindow(GTK_WINDOW_POPUP) + 전용 스타일 설정 | `TQtHintWindow.Create` + Qt 힌트 윈도우 플래그 | 완전 — GTK4 팝업 타입 변경 대응 |
| ShowHide | **7줄** (gtk4wsforms.pp:671-677): `BeginUpdate` → `Widget.Visible := HandleObjectShouldBeVisible` → `EndUpdate` — 힌트 전용 가시성 토글. **GTK2와 차이**: GTK2는 포커스 제어 포함, GTK4는 단순 Visible 프로퍼티 위임 | GTK2 윈도우 관리 (포커스 제어 포함) | Qt 힌트 윈도우 표시/숨김 | 완전 |

**참고**: TWSHintWindow는 TWSCustomForm을 상속. SetBounds, SetBorderIcons, SetFormBorderStyle 등 주요 폼 메서드는 부모 클래스에서 처리. HintWindow 자체는 CreateHandle (팝업 타입 윈도우 생성)과 ShowHide (힌트 전용 표시 동작)만 재정의 필요.

**TGtk4HintWindow 래퍼 총 30줄** (gtk4widgets.pas:11734-11766):
- `CreateWidget` **24줄** (11736-11759): `gtk4_window_new` → GtkBox(vertical) → GtkFixed. `set_focusable(False)` + `set_decorated(False)` — GTK4에서 `GTK_WINDOW_POPUP` 제거됨, GtkWindow를 비장식 모드로 사용
- `InitializeWidget` **6줄** (11761-11766): GTK4에서 `GdkWindow` 제거로 인해 `set_transient_for` 경로 변경 대응 (주석 문서화)
- **GTK2 비교**: `GTK_WINDOW_POPUP` 타입으로 직접 팝업 윈도우 생성 (~25줄). GTK4는 이 타입이 없어 `GtkWindow + set_decorated(False)` 워크어라운드
- **Qt5 비교**: `TQtHintWindow.Create` + Qt 힌트 윈도우 플래그 (~15줄). 플랫폼 차이가 가장 적음

---

## 9. WSGrids

### TWSCustomGrid

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| GetEditorBoundsFromCellRect | IMPL | IMPL | IMPL |
| Invalidate | IMPL | IMPL | MISS |
| SendCharToEditor | MISS | MISS | MISS |
| InvalidateStartY | MISS | MISS | MISS |

**Note**: SendCharToEditor only implemented by Win32. InvalidateStartY only by old GTK1. No GTK4/GTK2/Qt5 override exists.

#### TWSCustomGrid 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| GetEditorBoundsFromCellRect | **19줄** (gtk4wsgrids.pp:40-58): L+1, R-2, B-1 인셋 → `ACanvas.TextHeight(' ')` 측정 → `constCellPadding` 사용 → tlTop/tlCenter/tlBottom 정렬 → `EditorTop > Result.Top` 경계 체크 | **19줄** (gtk2wsgrids.pp:49-67): GTK4와 **문자 단위 100% 동일 코드** | **18줄** (qt5wsgrids.pp:44-61): ⚠️ **2가지 차이**: ① `Inc(Result.Left)` 누락 (좌측 인셋 없음), ② `varCellPadding` (변수) 사용 vs `constCellPadding` (상수) | ✅ GTK2와 **완전 동일**. Qt5에 좌측 인셋 버그 |
| Invalidate | **4줄** (gtk4wsgrids.pp:60-63): `Sender.Invalidate()` 위임 | **4줄** (gtk2wsgrids.pp:69-72): 동일 | ❌ 미구현 (override 없음) | ✅ GTK4/GTK2 동일. **Qt5만 Invalidate 미구현** |

---

## 10. WSImgList

### TWSCustomImageListResolution

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| Clear | STUB | MISS | MISS |
| CreateReference | STUB | MISS | MISS |
| Delete | STUB | MISS | MISS |
| DestroyReference | STUB | MISS | MISS |
| Draw | STUB | MISS | MISS |
| Insert | STUB | MISS | MISS |
| Move | STUB | MISS | MISS |
| Replace | STUB | MISS | MISS |

**GTK4 note**: All stubs — calls inherited. GTK2 and Qt5 also have no overrides. ImageList 로직은 LCL 수준에서 처리 (TCustomImageListResolution). 플랫폼 WS 재정의가 필요 없는 구조.
**R31 래퍼 검증**: gtk4wsimglist.pp (67-119줄) 확인 — 8개 메서드 모두 `inherited` 반환만. 래퍼 클래스도 존재하지 않음 (TGtk4ImageList 없음). **3플랫폼 모두 WS 수준 구현 없음** — ImageList draw/manage 로직은 TCustomImageListResolution (lcl/imglist.pp)에서 비트맵 연산으로 순수 LCL 수준 처리.

#### TWSCustomImageListResolution 구현 수준 상세

| Method | GTK4 구현 | GTK2 | Qt5 | GTK4 품질 |
|--------|----------|------|-----|----------|
| Clear | `inherited Clear(AList)` — 순수 위임 | ❌ 미등록 | ❌ 미등록 | STUB (LCL 베이스 처리) |
| CreateReference | `inherited CreateReference(...)` — 순수 위임 | ❌ | ❌ | STUB |
| Delete | `inherited Delete(AList, AIndex)` — 순수 위임 | ❌ | ❌ | STUB |
| DestroyReference | `inherited DestroyReference(AComponent)` — 순수 위임 | ❌ | ❌ | STUB |
| Draw | `inherited Draw(...)` — **주석 처리된 GTK4 구현** 존재: `TGtk4DeviceContext.drawImglistRes()` (gtk4wsimglist.pp:98-100) | ❌ | ❌ | STUB — 향후 네이티브 렌더링 가능 |
| Insert | `inherited Insert(AList, AIndex, AData)` — 순수 위임 | ❌ | ❌ | STUB |
| Move | `inherited Move(AList, ACurIndex, ANewIndex)` — 순수 위임 | ❌ | ❌ | STUB |
| Replace | `inherited Replace(AList, AIndex, AData)` — 순수 위임 | ❌ | ❌ | STUB |

- **전체 STUB**: 8개 메서드 모두 `inherited` 호출만 수행. LCL 베이스 `TWSCustomImageListResolution` 기본 구현이 플랫폼 독립적으로 동작하므로 실제 기능 문제 없음.
- **Draw 주석 코드**: `TGtk4DeviceContext.drawImglistRes()` 호출이 주석 처리됨 — 네이티브 Cairo 렌더링 경로가 계획되었으나 미완성. 현재 LCL 기본 렌더링 사용.
- **GTK2/Qt5**: WSFactory 등록 자체가 없음. GTK4만 유일하게 등록하나 구현은 모두 inherited 호출.

---

## 11. WSMenus

### TWSMenuItem

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| AttachMenu | IMPL | IMPL | IMPL |
| CreateHandle | IMPL | IMPL | IMPL |
| DestroyHandle | IMPL | IMPL | IMPL |
| SetCaption | IMPL | IMPL | IMPL |
| SetShortCut | IMPL | IMPL | IMPL |
| SetVisible | IMPL | IMPL | IMPL |
| SetCheck | IMPL | IMPL | IMPL |
| SetEnable | IMPL | IMPL | IMPL |
| SetRadioItem | IMPL | IMPL | IMPL |
| SetRightJustify | IMPL | IMPL | IMPL |
| UpdateMenuIcon | IMPL | IMPL | IMPL |
| OpenCommand | MISS | MISS | MISS |
| CloseCommand | MISS | MISS | MISS |

**GTK4 gaps**: None — full parity
**ALL MISS**: OpenCommand/CloseCommand (command ID management — base defaults adequate)
**GTK4 품질 이슈**:
- `SetCaption`/`SetVisible`/`UpdateMenuIcon`: 모든 속성 변경 시 `Gtk4RebuildMenuModel` 호출 → **전체 GMenu 모델 리빌드 O(n)**. n개 아이템 초기화 시 O(n²). GTK2/Qt5는 개별 위젯 업데이트 O(1)
- `SetRadioItem`: GAction 타입 변경 필요 → **핸들 전체 재생성** (RecreateHandle)
- ~~콜백명 `Gtk2FileChooserResponseCB`/`Gtk2FileChooserNotifyCB`~~: ✅ **수정됨 (Session 61)** — `Gtk4` 접두사로 변경

#### TWSMenuItem 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| AttachMenu | **WS 18줄** (gtk4wsmenus.pp:394-411): `Gtk4RebuildMenuModel()` 전체 GMenu 트리 리빌드 | `gtk_menu_bar_insert` / `gtk_menu_insert` O(1) | `TQtMenuBar.insertMenu` O(1) | ⚠️ **깊지만 비효율** — 삽입 시 O(n) 리빌드 |
| CreateHandle | **WS 7줄** (gtk4wsmenus.pp:413-419) + **래퍼 Create 63줄** (gtk4widgets.pas:6712-6774): GSimpleAction 생성 (normal/stateful), GMenuItem + label + accel, separator 처리 | 아이템 타입별 위젯 + **6 시그널 콜백** | `TQtMenu.Create` + 속성 설정 | ⚠️ WS 얕으나 래퍼 깊음 (63줄 GAction+GMenuItem 구성) |
| DestroyHandle | **WS 14줄** (gtk4wsmenus.pp:421-434) + **래퍼 Destroy 30줄** (gtk4widgets.pas:6776-6805): GAction 시그널 해제, FSubMenu/FGMenuItem/FAction unref | `DestroyLCLComponent()` | `TQtMenu.Release` | 완전 — GObject ref 정리 포함 |
| SetCaption | **WS 14줄** (gtk4wsmenus.pp:436-449): `g_menu_item_set_label` + `&`→`_` 변환 + `Gtk4RebuildMenuModel()` | `UpdateInnerMenuItem()` O(1) | `setText()` O(1) | ⚠️ **전체 리빌드** O(n) |
| SetCheck | **WS 15줄** (gtk4wsmenus.pp:512-526) + **래퍼 SetCheck 12줄** (gtk4widgets.pas:6852-6863): `g_simple_action_set_state` + Lock 재진입 방지 | `gtk_check_menu_item_set_active` + 라디오 그룹 잠금 | `setChecked` | 완전 — stateful GAction 토글 |
| SetEnable | **WS 15줄** (gtk4wsmenus.pp:528-542) + **래퍼 SetEnabled 5줄** (gtk4widgets.pas:6865-6869): `g_simple_action_set_enabled` | `gtk_widget_set_sensitive` | `setEnabled` | 완전 |
| SetRadioItem | **WS 7줄** (gtk4wsmenus.pp:544-550): `RecreateHandle` (GAction 타입 변경 필요) | `RecreateHandle` | Qt5만 인플레이스 변경 | ⚠️ GTK4/GTK2 모두 재생성 필요 |
| SetRightJustify | **WS 9줄** (gtk4wsmenus.pp:552-560): `False` 반환 — GtkPopoverMenuBar 미지원 ✅ S61 수정 | `gtk_menu_item_set_right_justified` + `queue_resize` | `setAttribute(RightToLeft)` | ✅ 정확한 상태 보고 (False=미지원) |
| SetShortCut | **WS 51줄** (gtk4wsmenus.pp:451-501): `LCLKeyToGdkKeyval` → `ShiftStateToGdkMods` → `gtk_accelerator_name` → `g_menu_item_set_attribute_value('accel')` + 리빌드. 빈 shortcut 처리 포함 | `UpdateInnerMenuItem` — 텍스트만 ("Temporary" 주석) | `setShortcut(K1, K2)` | ✅ **가장 완전** — 실제 GDK 가속키 바인딩 |
| SetVisible | **WS 8줄** (gtk4wsmenus.pp:503-510): `Gtk4RebuildMenuModel()` (비가시 아이템 모델에서 제외) | `gtk_widget_show/hide` O(1) | `setVisible` O(1) | ⚠️ **전체 리빌드** O(n) |
| UpdateMenuIcon | **WS 26줄** (gtk4wsmenus.pp:562-587): pixbuf→PNG→`g_bytes_icon_new` → `g_menu_item_set_icon` + 리빌드 | `RecreateHandle` | `RecreateHandle` | ⚠️ 인코딩 정교하나 리빌드 비용 |

**GTK4 Menu 아키텍처 주요 차이점**:
- **GMenu 선언적 모델**: GTK2/Qt5의 직접 위젯 조작과 달리, GTK4는 GMenu + GAction 모델을 사용. 속성 변경마다 전체 모델 리빌드 필요
- **O(n²) 초기화 비용**: n개 아이템을 순차 추가 시 매번 리빌드 → O(n²). 배치 업데이트 캐싱 권장
- **SetShortCut 3단계 변환 검증**: `LCLKeyToGdkKeyval(Key)` → `ShiftStateToGdkMods(ShiftState)` → `gtk_accelerator_name(keyval, mods)` → `g_menu_item_set_attribute_value('accel', accstr)` + `Gtk4RebuildMenuModel()`. **실제 GDK 가속키 바인딩** — GTK2는 텍스트 표시만 ("Temporary" 주석)

**Gtk4RebuildMenuModel 함수 구조** (총 **159줄**, 3개 서브루틴):
- `Gtk4RebuildMenuModel` (gtk4wsmenus.pp:365-390, **26줄**): 진입점. **재귀 방지 가드**: `FRebuildPending` 플래그로 중복 리빌드 차단 + `PendingQueue`에 대기 후 순차 처리. 메뉴 모델 교체: `g_menu_remove_all` → `BuildMenuItems` 호출 → `gtk_popover_menu_bar_set_menu_model`
- `BuildMenuItems` (내부, **91줄**): LCL 메뉴 아이템 트리 O(N) 단일 순회. Visible 체크 → Separator/Submenu/Normal 분기 → `g_menu_item_new` + `g_menu_append_item`. Submenu: `g_menu_new` → 재귀 `BuildMenuItems` → `g_menu_item_set_submenu`
- `DoRebuild` (내부, **42줄**): GAction 그룹 관리. 기존 action 제거 → 새 action 추가 (`g_simple_action_new` / `g_simple_action_new_stateful`). 체크/라디오 아이템에 대한 stateful action + `change-state` 시그널 연결

### TWSMenu

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| SetBiDiMode | IMPL | IMPL | IMPL |

#### TWSMenu 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 21줄** (gtk4wsmenus.pp:591-611): TMainMenu→`TGtk4MenuBar.Create(AMenu, AWin.GetMenuBar())` FMenuModel/FActionGroup 공유. 기타→`TGtk4MenuBar.Create(AMenu, nil)`. **래퍼 CreateWidget 7줄** (gtk4widgets.pas:6667-6673): `gtk4_popover_menu_bar_new_from_model` | `gtk_menu_bar_new` + `gtk_box_pack_start` + pack_direction | TMainMenu: `TQtMainWindow.MenuBarNeeded`. 기타: `TQtMenu.Create` | 완전 |
| SetBiDiMode | **WS 16줄** (gtk4wsmenus.pp:613-628): `gtk_widget_set_direction(GTK_TEXT_DIR_RTL/LTR)` 단순 방향 설정 | pack 방향 + 자식 **재귀** Switch() 전체 업데이트 | `setLayoutDirection` | ⚠️ **얕음** — GTK2는 재귀적 자식 업데이트 |

### TWSPopupMenu

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | MISS |
| Popup | IMPL | IMPL | IMPL |

#### TWSPopupMenu 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 4줄** (gtk4wsmenus.pp:651-654) + **래퍼 CreateWidget 7줄** (gtk4widgets.pas:6677-6683): `gtk4_popover_menu_new_from_model`, arrow 비활성, FActionGroup 삽입 | `gtk_menu_new` + `CreateWidgetInfo` + `SetCallbacks` | `TQtMenu.Create` + `AttachEvents` | ⚠️ WS 얕으나 래퍼가 GtkPopoverMenu 구성 |
| Popup | **WS 67줄** (gtk4wsmenus.pp:656-722): `Gtk4RebuildMenuModel` → `gtk4_popover_set_pointing_to(ARect)` → `gtk4_popover_popup` → **중첩 `g_main_loop_run()`** 블로킹 + `g_signal_connect_data('closed')` → `gtk4_popover_unparent` + `APopupMenu.Close`. **GTK2 비교**: `gtk_menu_popup` + 커스텀 위치 콜백 (~35줄) — GTK4는 2배 코드량. **Qt5 비교**: `TQtMenu.Exec(@Point)` (~10줄) | `gtk_menu_popup` + 커스텀 위치 콜백 + 블로킹 루프 (~35줄) | `TQtMenu.Exec(@Point)` 블로킹 (~10줄) | ⚠️ **매우 깊음** (67줄) — GtkPopover + 중첩 이벤트 루프 (GTK2의 2배) |

**GTK4 PopupMenu 아키텍처**:
- GTK4는 GtkMenu가 제거되어 **GtkPopoverMenu**로 대체. `Popup()`은 GMenu 모델을 리빌드 후 popover로 표시
- 블로킹 구현: `g_main_loop_run()` 중첩 이벤트 루프 → `closed` 시그널에서 `g_main_loop_quit()` 호출로 탈출
- GTK2의 `gtk_menu_popup()` + 커스텀 위치 콜백과 기능적으로 동등하나 구현 방식 전혀 다름

**R32 §11 Menus 크로스플랫폼 코드 깊이 비교:**

| 메서드 | GTK4 (줄) | GTK2 (줄) | Qt5 (줄) | 아키텍처 차이 |
|--------|----------|----------|---------|-------------|
| MenuItem.CreateHandle | **WS 7줄** + 래퍼 63줄 (GAction+GMenuItem) | **52줄** (인라인 위젯 생성, separator/radio/check 분기) | **54줄** (Menu 분기+AttachEvents) | GTK4: 선언적 GMenu 모델. GTK2/Qt5: 명령형 위젯 생성 |
| Gtk4RebuildMenuModel / 초기화 | **159줄** (3개 서브루틴) | N/A (아이템별 O(1)) | N/A (아이템별 O(1)) | GTK4만 전체 모델 리빌드 필요 (GMenu 선언적 제약) |
| PopupMenu.Popup | **67줄** (GtkPopover+g_main_loop) | **~35줄** (gtk_menu_popup) | **~10줄** (Menu.Exec) | GTK4: 2배 코드 (GtkPopoverMenu+중첩 이벤트 루프) |
| 전체 파일 크기 | **727줄** (gtk4wsmenus.pp) | **701줄** | **531줄** | GTK4 ≈ GTK2 > Qt5 (GMenu 리빌드 오버헤드) |

**핵심**: GTK4 메뉴는 **선언적 GMenu 모델** — 속성 변경마다 O(n) 리빌드. GTK2/Qt5는 **명령형 위젯** — 개별 O(1) 업데이트. 파일 크기는 비슷하나 런타임 비용 구조가 다름.

---

## 12. WSSpin

### TWSCustomFloatSpinEdit

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | MISS | MISS |
| GetSelStart | IMPL | IMPL | MISS |
| GetSelLength | IMPL | IMPL | MISS |
| GetValue | IMPL | IMPL | IMPL |
| SetSelStart | IMPL | IMPL | MISS |
| SetSelLength | IMPL | IMPL | MISS |
| SetReadOnly | IMPL | IMPL | IMPL |
| SetAlignment | IMPL | MISS | IMPL |
| SetEditorEnabled | IMPL | IMPL | IMPL |
| UpdateControl | IMPL | IMPL | IMPL |
| SetIncrement | MISS | MISS | MISS |
| SetMinValue | MISS | MISS | MISS |
| SetMaxValue | MISS | MISS | MISS |
| SetValueEmpty | MISS | MISS | MISS |

**GTK4 gaps**: None — exceeds both GTK2 and Qt5
**ALL MISS**: SetIncrement, SetMinValue, SetMaxValue, SetValueEmpty (all platforms use UpdateControl for bulk updates; Qt5 source has these as commented-out TODO)
~~**GTK4 IMPL* 이슈**~~: ✅ **전부 수정됨**
- ~~`GetValue` — 로케일 변환 누락~~ ✅ **수정됨 (Session 61, Bug#6)**: `PGtkSpinButton^.update` 호출로 텍스트→값 동기화 보장
- ~~`SetReadOnly` — adjustment 미잠금~~ ✅ **수정됨 (Session 62)**: ReadOnly 시 `SetRange(Value, Value)`로 min=max=current 잠금, 해제 시 원래 범위 복원 + EditorEnabled 상태 보존

#### TWSCustomFloatSpinEdit 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 8줄** (gtk4wsspin.pp:56-63): `TGtk4SpinEdit.Create` 래퍼 위임 | `gtk_adjustment_new` + `gtk_spin_button_new` (~30줄) | decimals>0→`TQtFloatSpinBox`, else→`TQtSpinBox` | 완전 |
| GetPreferredSize | **WS 8줄** (gtk4wsspin.pp:65-72): `gtk_widget_measure` | MISS | MISS | ✅ GTK4 고유 |
| GetValue | **8줄** (gtk4wsspin.pp:92-99): `TGtk4SpinEdit.Value` → `PGtkSpinButton^.update` + `get_value`. ✅ **S61 수정**: `update` 호출로 텍스트→내부값 동기화 보장 | `gtk_spin_button_get_value` + **StrToValue 로케일 변환** (구조체 직접 접근) | `getValue` 인터페이스 | ✅ 완전 |
| GetSelStart | **WS 8줄** (gtk4wsspin.pp:74-81): `gtk_editable_get_selection_bounds` | `gtk_editable_get_selection_bounds` | MISS | 완전 (GTK4 > Qt5) |
| GetSelLength | **WS 8줄** (gtk4wsspin.pp:83-90): `Abs(AEnd-AStart)` | `Abs(AEnd-AStart)` | MISS | 완전 (GTK4 > Qt5) |
| SetSelStart | **WS 9줄** (gtk4wsspin.pp:101-109): `gtk_editable_set_position` + BeginUpdate/EndUpdate | `gtk_editable_set_position` | MISS | 완전 (GTK4 > Qt5) |
| SetSelLength | **WS 9줄** (gtk4wsspin.pp:111-119): `gtk_editable_select_region` + BeginUpdate/EndUpdate | `gtk_entry_select_region` | MISS | 완전 (GTK4 > Qt5) |
| SetReadOnly | **18줄** (gtk4wsspin.pp:122-159): ReadOnly 시 `SetRange(Value, Value)` adjustment 범위 잠금 + 해제 시 원래 범위 복원 + EditorEnabled 상태 보존. ✅ **S62 수정**: GTK2 패턴과 동일한 adjustment bounds lock 구현 | `set_editable` + **adjustment range lock** (min=max=current, 40줄) | `QLineEdit_setReadOnly` + EditorEnabled 가드 | ✅ 완전 |
| SetAlignment | **WS 7줄** (gtk4wsspin.pp:141-147): `gtk_entry_set_alignment` (xalign 0.0/0.5/1.0). **R31 비교**: GTK4는 GtkSpinButton이 GtkEntry 상속 → xalign float 직접 설정 가능. **GTK2 MISS** — GtkSpinButton이 xalign API 미지원 (GTK2 구조적 제한). Qt5는 QAlignment enum 매핑 (7줄) | MISS (GTK2 구조적 제한) | QAlignment 매핑 (~7줄) | ✅ GTK4 > GTK2 |
| SetEditorEnabled | **WS 13줄** (gtk4wsspin.pp:149-161): `gtk_editable_set_editable` + ReadOnly 조건부 가드 | `gtk_editable_set_editable` (ReadOnly 가드 없음) | `QLineEdit_setReadOnly` + OR 가드 | ✅ GTK4 > GTK2 (ReadOnly 상호작용) |
| UpdateControl | **WS 33줄** (gtk4wsspin.pp:163-195): SetRange + SetNumeric + SetNumDigits + SetStep + Value — GtkSpinButton 프로퍼티 동기화 | adjustment 직접 조작 + `set_digits/value` (44줄) | InternalUpdateControl 조건 분기 | 완전 |

---

## 13. WSStdCtrls

### TWSScrollBar

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| SetParams | IMPL | IMPL | IMPL |
| SetKind | IMPL | IMPL | IMPL |
| ShowHide | IMPL | IMPL | IMPL |
| ScrollBy | MISS | IMPL | MISS |

**GTK4 gaps**: ScrollBy (GTK2 only)

#### TWSScrollBar 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **10줄** (gtk4wsstdctrls.pp:1482-1491): `TGtk4ScrollBar.Create(AWinControl, AParams)` 래퍼 위임. 래퍼 `CreateWidget` (gtk4widgets.pas:5584-5618, **35줄**): `gtk_scrollbar_new(orientation, adjustment)` + `value-changed` 시그널 연결 → `LM_HSCROLL`/`LM_VSCROLL` LCL 메시지 발생 | `gtk_adjustment_new` + `gtk_hscrollbar_new/gtk_vscrollbar_new` + `set_update_policy` (~30줄) | `TQtScrollBar.Create` + SetOrientation (~12줄) | 완전 |
| SetKind | **RecreateWnd** (gtk4wsstdctrls.pp:1493-1498) — LCL 수준 **전체 재생성**. GtkScrollbar orientation은 생성 시 결정 → 런타임 변경 불가 | `RecreateWnd` (동일 제약) | `SetOrientation()` **직접 변경** (재생성 불필요) | ⚠️ Qt5보다 비효율 (GTK4≡GTK2 동일 제약) |
| SetParams | **18줄** (gtk4wsstdctrls.pp:1500-1517): `TGtk4ScrollBar.SetParams` + BeginUpdate/EndUpdate. 래퍼에서 `gtk_adjustment_configure(value, lower, upper, step_inc, page_inc, page_size)` 일괄 설정 | `gtk_adjustment_configure` (GTK 2.14+) 또는 수동 필드 조작 | `setRange` + `setPageStep` + `setSingleStep` + `setValue` | 완전 |
| ShowHide | **8줄** (gtk4wsstdctrls.pp): SetParams 재적용 → `TGtk4WSWinControl.ShowHide` 위임 — 표시 전 파라미터 동기화 | SetParams 재적용 → `Gtk2WidgetSet.SetVisible` | SetParams → 상속 ShowHide | 완전 (3플랫폼 동일 패턴) |

### TWSCustomGroupBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetDefaultClientRect | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | IMPL |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| SetText | MISS | IMPL | MISS |
| SetBounds | MISS | IMPL | MISS |

**GTK4 gaps**: SetColor, SetFont, SetText, SetBounds (GTK2-specific; handled by TWSWinControl base in GTK4)

#### TWSCustomGroupBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **7줄** (gtk4wsstdctrls.pp:421-427): `TGtk4GroupBox.Create(AWinControl, AParams)`. 래퍼 `CreateWidget` **20줄** (gtk4widgets.pas:4860-4879): GtkFrame → GtkOverlay → [GtkFixed + GtkDrawingArea]. `gtk_frame_set_label_align(0.0)` 라벨 좌측 정렬 | `gtk_frame_new` + 2개 EventBox + Fixed 중첩 (~45줄) | `TQtGroupBox.Create` (5줄) | 완전 (GTK4가 가장 간결) |
| GetDefaultClientRect | **15줄** (gtk4wsstdctrls.pp:429-443): **하드코딩**: `cGroupBoxTopMargin=20`, `cGroupBoxPadding=2`. `Result := Rect(Padding, TopMargin, Width-Padding, Height-Padding)` | `GetStyleGroupboxFrameBorders()` **테마 인식** | `GetPixelMetric(PM_Layout*Margin)` **테마 인식** | ⚠️ 테마 미지원 (GTK2/Qt5는 테마 인식) |
| GetPreferredSize | **6줄** (gtk4wsstdctrls.pp:445-450): `TGtk4GroupBox.preferredSize()` 위임 → `gtk_widget_get_preferred_size` | `GetGTKDefaultWidgetSize()` | `TQtGroupBox.PreferredSize()` | 완전 |
| SetBounds | MISS (상속) — TWSWinControl.SetBounds에서 처리 | **테마 최소 너비** 체크 + 라벨 숨김 처리 (~15줄) | MISS (상속) | GTK2만 고유 구현 (테마 최소 너비 보장) |
| SetColor | MISS (상속) — TWSWinControl.SetColor에서 처리 | EventBox + CoreWidget 색상 설정 (~8줄) | MISS (상속) | GTK2만 고유 구현 |
| SetFont | MISS (상속) | 라벨 위젯 폰트 + 색상 설정 (~12줄) | MISS (상속) | GTK2만 고유 구현 |
| SetText | MISS (상속) — 래퍼 `TGtk4GroupBox.setText` (gtk4widgets.pas:4892-4906, 15줄)에서 GtkFrame 라벨 위젯 생성/갱신, 빈 캡션 시 nil 처리 | `SetLabel()` 헬퍼 | MISS (상속) | ⚠️ WS override 없으나 래퍼에서 처리 |

### TWSCustomComboBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| CanFocus | MISS | IMPL | MISS |
| DestroyHandle | MISS | IMPL | MISS |
| GetPreferredSize | IMPL | IMPL | IMPL |
| GetDroppedDown | IMPL | IMPL | IMPL |
| GetSelStart | IMPL | IMPL | IMPL |
| GetSelLength | IMPL | IMPL | IMPL |
| GetItemIndex | IMPL | IMPL | IMPL |
| GetMaxLength | IMPL | IMPL | IMPL |
| GetText | MISS | IMPL | MISS |
| GetItems | IMPL | IMPL | IMPL |
| SetArrowKeysTraverseList | STUB | STUB | STUB |
| SetDropDownCount | IMPL | MISS | IMPL |
| SetDroppedDown | IMPL* | IMPL | IMPL |
| SetSelStart | IMPL | IMPL | IMPL |
| SetSelLength | IMPL | IMPL | IMPL |
| SetItemIndex | IMPL | IMPL | IMPL |
| SetMaxLength | IMPL | IMPL | IMPL |
| SetStyle | IMPL | IMPL | IMPL |
| SetReadOnly | IMPL | IMPL | IMPL |
| SetTextHint | IMPL | MISS | IMPL |
| Sort | IMPL | IMPL | IMPL |
| GetItemHeight | IMPL | MISS | IMPL |
| SetItemHeight | IMPL | MISS | IMPL |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| SetText | MISS | IMPL | MISS |
| ShowHide | MISS | IMPL | MISS |
| FreeItems | MISS | MISS | MISS |

**GTK4 gaps**: SetColor/SetFont/SetText/ShowHide (GTK2-specific widget-level overrides)
**GTK4 quality**: SetDroppedDown=`IMPL*` — TGtk4ComboBox(에디터블)에서만 동작. GtkDropDown(csDropDownList 스타일)에서 프로그래매틱 열기/닫기 불가 (GtkDropDown API 부재, §22d).
**ALL MISS**: FreeItems (base default adequate — items freed by component)

#### TWSCustomComboBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **WS 19줄** (gtk4wsstdctrls.pp:800-818): **듀얼 위젯** — `HasEditBox=True`→`TGtk4ComboBox` (GtkComboBoxText), `False`→`TGtk4DropDown` (GtkDropDown). csDropDown/csSimple→ComboBox, csDropDownList/csOwnerDraw→DropDown | `gtk_combo_box_entry_new_text` 단일 위젯 | `TQtComboBox.Create` + `setEditable` | ⚠️ 2개 위젯 클래스 (GTK2/Qt5는 단일) |
| GetPreferredSize | **WS 9줄** (gtk4wsstdctrls.pp:820-828): `gtk_widget_measure` | `GetGTKDefaultWidgetSize` | `sizeHint` | 완전 |
| GetDroppedDown | **WS 10줄** (gtk4wsstdctrls.pp:830-839): ComboBox→`DroppedDown` 프로퍼티. **DropDown: 불가** (popup-shown 없음) | `gtk_combo_box` 상태 조회 | `getDroppedDown` | ⚠️ GtkDropDown 미동작 |
| GetItemIndex | **WS 11줄** (gtk4wsstdctrls.pp:873-883): 위젯 타입 분기 DropDown vs ComboBox `ItemIndex` | `gtk_combo_box_get_active` | `currentIndex` | 완전 |
| GetItemHeight | **WS 28줄** (gtk4wsstdctrls.pp:1021-1048): Pango `pango_font_metrics_get_ascent/descent` + 4px padding | `GetGTKDefaultWidgetSize` | `getRowHeight` | 완전 |
| GetItems | **WS 15줄** (gtk4wsstdctrls.pp:987-1001): `g_object_get_data(GtkListItemLCLListTag)` → TGtkStringListStrings | `gtk_combo_box_get_model` | `FList` | 완전 |
| SetDroppedDown | **WS 9줄** (gtk4wsstdctrls.pp:913-921): ComboBox만 `popup/popdown`. **GtkDropDown: API 없음** | `gtk_combo_box_popup/popdown` | `showPopup/hidePopup` | ⚠️ IMPL* — GtkDropDown 미지원 |
| SetDropDownCount | **WS 7줄** (gtk4wsstdctrls.pp:905-911): ComboBox→`DropDownCount`. DropDown: 미지원 | MISS | `setMaxVisibleItems` | 부분 |
| SetItemIndex | **WS 17줄** (gtk4wsstdctrls.pp:961-977): 위젯 타입 분기 + BeginUpdate/EndUpdate | `gtk_combo_box_set_active` | `setCurrentIndex` | 완전 |
| SetItemHeight | **WS 17줄** (gtk4wsstdctrls.pp:1050-1066): CSS `listview > row {min-height}` via `gtk_css_provider_new` (ComboBox만) | MISS | `setUniformItemSizes` / `RecreateWnd` | ✅ GTK4 고유 CSS |
| SetReadOnly | **WS 11줄** (gtk4wsstdctrls.pp:1068-1078): ComboBox→`PGtkEditable.set_editable` | `gtk_editable_set_editable` | `setEditable` | 완전 (DropDown 항상 읽기전용) |
| SetTextHint | **WS 11줄** (gtk4wsstdctrls.pp:1080-1090): ComboBox→`PGtkEntry.set_placeholder_text` | MISS | `QLineEdit.setPlaceholderText` | ✅ GTK4 > GTK2 |
| SetStyle | **주석만** "RecreateWnd 필요" (LCL 처리) | `ReCreateCombo()` 실행 | 주석만 (LCL 처리) | 완전 (LCL 위임) |
| Sort | **17줄** (gtk4wsstdctrls.pp:1003-1019): `g_object_get_data(GtkListItemLCLListTag)` → `TGtkStringListStrings(Strings).Sorted := True`. **Pascal 레벨 정렬** (FItems: TStringList 내부 Sort). GTK 모델 직접 정렬 아님 | `gtk_tree_sortable_set_sort_column` **모델 정렬** | `TQtListStrings.Sort` Pascal 레벨 | 완전 (GTK2가 네이티브, GTK4/Qt5는 Pascal) |
| GetSelStart | **16줄** (gtk4wsstdctrls.pp:841-856): `PGtkEditable.get_selection_bounds(@AStart, @AEnd)` → 선택 있으면 AStart, 없으면 `get_position` 반환. DropDown 가드 포함 | `gtk_editable_get_selection_bounds` + `Min(AStart,AEnd)` (역선택 처리) | `getSelectionStart` | 완전 — GTK2는 역선택 Min 처리 추가 |
| GetSelLength | **14줄** (gtk4wsstdctrls.pp:858-871): `get_selection_bounds` → `AEnd - AStart`. DropDown 가드 | `ABS(AStart - AEnd)` (역선택 ABS) | `getSelectionLength` | 완전 — GTK2는 ABS (더 안전) |
| GetMaxLength | **12줄** (gtk4wsstdctrls.pp:885-896): `PGtkEntry.get_max_length`. DropDown 가드 | `gtk_entry_get_max_length` + **g_object_get_data 폴백** (비편집 콤보) | `maxLength` | 완전 — GTK2 폴백 불필요 (DropDown 별도 클래스) |
| SetSelStart | **11줄** (gtk4wsstdctrls.pp:935-945): `PGtkEditable.set_position(NewStart)` — 캐럿 이동만 (선택 생성 안 함). DropDown 가드 | `gtk_editable_set_position` (동일) | `setSelectionStart` | 완전 (GTK4≡GTK2 동일) |
| SetSelLength | **13줄** (gtk4wsstdctrls.pp:947-959): `get_position` → `select_region(AStart, AStart+NewLength)`. DropDown 가드 | `GetSelStart` + `gtk_editable_select_region` (동일 패턴) | `setSelectionLength` | 완전 (GTK4≡GTK2 동일) |
| SetMaxLength | **11줄** (gtk4wsstdctrls.pp:923-933): `PGtkEntry.set_max_length(NewLength)`. DropDown 가드 | `gtk_entry_set_max_length` + **g_object_set_data 저장** (비편집 콤보) | `setMaxLength` | 완전 — GTK4 단순화 (g_object_set_data 불필요) |
| SetArrowKeysTraverseList | STUB ("GtkComboBox 내장, 비활성 불가") | STUB ("TODO") | **구현됨**: `setFocusProxy` | ❌ GTK4/GTK2 모두 미지원 |

### TWSCustomListBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetIndexAtXY | IMPL | IMPL | IMPL |
| GetItemIndex | IMPL | IMPL | IMPL |
| GetItemRect | IMPL | IMPL | IMPL |
| GetScrollWidth | IMPL | IMPL | IMPL |
| GetSelCount | IMPL | IMPL | IMPL |
| GetSelected | IMPL | IMPL | IMPL |
| GetStrings | IMPL | IMPL | IMPL |
| GetTopIndex | IMPL | IMPL | IMPL |
| SelectItem | IMPL | IMPL | IMPL |
| SetBorder | IMPL | IMPL | IMPL |
| SetColumnCount | STUB | MISS | IMPL |
| SetItemIndex | IMPL | IMPL | IMPL |
| SetScrollWidth | IMPL | IMPL | IMPL |
| SetSelectionMode | IMPL | IMPL | IMPL |
| SetStyle | IMPL | IMPL | IMPL |
| SetSorted | IMPL | IMPL | IMPL |
| SetTopIndex | IMPL | IMPL | IMPL |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| ShowHide | MISS | IMPL | MISS |
| DragStart | MISS | MISS | MISS |
| FreeStrings | MISS | MISS | MISS |
| SelectRange | MISS | MISS | MISS |

**GTK4 gaps**: SetColor/SetFont/ShowHide (GTK2-specific)
**GTK4 quality**: SetColumnCount=STUB — GTK4에 다중 컬럼 ListBox 없음 (의도적). GetIndexAtXY/GetItemRect는 adjustment 기반 **근사치** 반환 (§22d). SetSelectionMode 변경 시 RecreateWnd 필요.
**ALL MISS**: DragStart, FreeStrings, SelectRange (base defaults adequate)

#### TWSCustomListBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **14줄** (gtk4wsstdctrls.pp:560-573): `TGtk4ListBox.Create` + `BorderStyle` + `MultiSelect` 프로퍼티 설정. 래퍼: GtkScrolledWindow → GtkListView + GtkSingleSelection/GtkMultiSelection + GtkSignalListItemFactory | GtkScrolledWindow + GtkTreeView + CellRenderer (~80줄) | `TQtListWidget.Create` + FList (~33줄) | 완전 |
| GetIndexAtXY | **24줄** (gtk4wsstdctrls.pp:575-598): **(Y+scroll_offset)/row_height** 근사치 계산. `gtk_scrolled_window_get_vadjustment` → `value + Y` → `Trunc(total/row_height)`. 범위 체크 포함 | `gtk_tree_view_get_path_at_pos` **정확** | `indexAt(QPoint)` **정확** | ⚠️ 근사치 (GTK4 ListView에 아이템 위치→인덱스 API 없음) |
| GetItemRect | **28줄** (gtk4wsstdctrls.pp:600-627): **row_height × index - scroll_offset** 계산. 행 높이를 Pango 폰트 메트릭에서 추정. 보이지 않는 행은 빈 Rect 반환 | `gtk_tree_view_get_cell_area` **정확** | `getVisualItemRect` **정확** | ⚠️ 근사치 |
| GetScrollWidth | **8줄** (gtk4wsstdctrls.pp:629-636): `gtk4_widget_measure` natural width 쿼리 | MISS | `horizontalScrollBar.getMax` | 완전 (GTK4 고유) |
| GetSelCount | **6줄** (gtk4wsstdctrls.pp:638-643): `TGtk4ListBox.GetSelCount` 래퍼 위임 → selection model bitset 카운트 | TreeSelection 복잡 조회 | `getSelCount` | 완전 |
| GetTopIndex | **8줄** (gtk4wsstdctrls.pp:645-652): **Trunc(adjustment.value/row_height)** 근사치 | `gtk_tree_view_get_top_path` **정확** (`gtk_tree_view_get_visible_range`) | `IndexAt(0,0)` **정확** | ⚠️ 근사치 |
| SelectItem | **10줄** (gtk4wsstdctrls.pp:654-663): `TGtk4ListBox.SelectItem` + BeginUpdate/EndUpdate. Multi: `select_item`/`unselect_item`, Single: `set_selected` | `gtk_tree_view_set_cursor` + selection model | `Selected[idx] := val` | 완전 |
| SetColumnCount | **STUB** (gtk4wsstdctrls.pp:665-668): "GTK4 다중 컬럼 ListBox 없음" 주석 | MISS ("TODO") | MISS ("TODO") | 3플랫폼 모두 미지원 |
| SetItemIndex | **8줄** (gtk4wsstdctrls.pp:670-677): `ItemIndex` 프로퍼티 + BeginUpdate/EndUpdate. selection model 직접 조작 | `gtk_tree_view_set_cursor` | `setCurrentRow` | 완전 |
| SetScrollWidth | **12줄** (gtk4wsstdctrls.pp:679-690): ScrollPolicy 조건 분기 — Width>0 → `POLICY_AUTOMATIC`, 0 → `POLICY_NEVER` | `gtk_tree_view_set_headers_visible` + 크기 계산 | `setHorizontalScrollBarPolicy` | 완전 |
| SetSelectionMode | **RecreateWnd 필요** (gtk4wsstdctrls.pp:692-700): GtkListView 선택 모델이 **생성 시 결정** (GtkSingleSelection vs GtkMultiSelection). 런타임 전환 불가 → `RecreateWnd` | `gtk_tree_selection_set_mode` **동적** | `setSelectionMode` **동적** | ⚠️ GTK2/Qt5보다 비효율 (재생성 필요) |
| SetSorted | **8줄** (gtk4wsstdctrls.pp:702-709): `TGtkStringListStrings.Sorted` Pascal 레벨 정렬 (FItems: TStringList.Sort) | `gtk_tree_sortable` **모델 정렬** | `TQtListStrings.Sorted` Pascal 레벨 | 완전 (GTK2가 네이티브) |
| SetStyle | **10줄** (gtk4wsstdctrls.pp:711-720): Style 변경 시 `RecreateWnd` — factory 패턴이 생성 시 결정 | `gtk_tree_view_column_set_visible` **동적** | "TODO" | ⚠️ 재생성 필요 |
| SetTopIndex | **8줄** (gtk4wsstdctrls.pp:722-729): `TGtk4ListBox.SetTopIndex` → adjustment `set_value(index * row_height)` | `gtk_tree_view_scroll_to_cell` | `scrollToItem` | 완전 |

### TWSCustomEdit

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| GetCanUndo | IMPL | MISS | IMPL |
| GetCaretPos | IMPL | IMPL | IMPL |
| GetSelStart | IMPL | IMPL | IMPL |
| GetSelLength | IMPL | IMPL | IMPL |
| SetAlignment | IMPL | IMPL | IMPL |
| SetCaretPos | IMPL | IMPL | IMPL |
| SetCharCase | IMPL | IMPL | MISS |
| SetEchoMode | IMPL | IMPL | IMPL |
| SetHideSelection | IMPL | MISS | MISS |
| SetMaxLength | IMPL | IMPL | IMPL |
| SetNumbersOnly | IMPL | MISS | IMPL |
| SetPasswordChar | IMPL | IMPL | MISS |
| SetReadOnly | IMPL | IMPL | IMPL |
| SetSelStart | IMPL | IMPL | IMPL |
| SetSelLength | IMPL | IMPL | IMPL |
| SetTextHint | IMPL | MISS | IMPL |
| SetText | MISS | IMPL | MISS |
| SetSelText | base | IMPL | base |
| SetColor | MISS | IMPL | MISS |
| Cut | IMPL | IMPL | IMPL |
| Copy | IMPL | IMPL | IMPL |
| Paste | IMPL | IMPL | IMPL |
| Undo | IMPL | IMPL | IMPL |

**GTK4 gaps**: SetText/SetColor (GTK2-specific overrides). ~~SetSelText~~: **오보정 (S64)** — base TWSCustomEdit.SetSelText (wsstdctrls.pp:605-618) 이미 완전 구현: Text/SelStart/SelLength 프로퍼티 위임으로 정상 동작. GTK2 override는 최적화일 뿐

#### TWSCustomEdit 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **8줄** (gtk4wsstdctrls.pp:1094-1101): `TGtk4Entry.Create` 래퍼 위임. `CreateWidget` **8줄** (gtk4widgets.pas:5153-5160): `TGtkEntry.new` + 커서 위치 초기화. `InitializeWidget` **17줄** (5167-5183): `set_size_request` + `set_text` + `'changed'`/`'insert-text'` 시그널 연결 | `gtk_entry_new` + `set_editable` + `show/hide` + WidgetInfo + 시그널 (~37줄) | `TQtLineEdit.Create` + 프로퍼티 설정 (~12줄) | 완전 — 래퍼 33줄 합산 |
| Copy | **5줄** (gtk4wsstdctrls.pp:1258-1262): Clipboard.AsText, EchoMode 체크 **LCL 레벨** | `gtk_editable_copy_clipboard` / `gtk_text_buffer_copy_clipboard` **GTK API** | `QtEdit.Copy()` 인터페이스 | 완전 (GTK2와 다른 접근 — LCL 수준) |
| Cut | **5줄** (gtk4wsstdctrls.pp:1252-1256): `CopyToClipboard` + `ClearSelection` **LCL 레벨** | `gtk_editable_cut_clipboard` / `gtk_text_buffer_cut_clipboard` | `QtEdit.Cut()` | 완전 |
| Paste | **5줄** (gtk4wsstdctrls.pp:1264-1268): Clipboard CF_TEXT 체크 → SelText 설정 **LCL 레벨** | `gtk_editable_paste_clipboard` / `gtk_text_buffer_paste_clipboard` | `QtEdit.Paste()` | 완전 |
| Undo | **7줄** (gtk4wsstdctrls.pp:1270-1276): `gtk4_widget_activate_action(Widget, 'text.undo', nil)` **GTK4 Action 시스템** — GtkEntry 내장 undo 스택 활용 (GTK4.2+ undoable text buffer) | ❌ **미구현** (TODO 주석만) | `QtEdit.Undo()` 인터페이스 | ✅ **GTK4 유일 구현** — GTK2 미구현 |
| GetCanUndo | **8줄** (gtk4wsstdctrls.pp:1112-1119): **항상 True** — GtkEntry에 can_undo 쿼리 API 없음 | ❌ MISS | `isUndoAvailable` **정확** | ⚠️ 부정확 (Qt5만 정확) |
| GetCaretPos | **7줄** (gtk4wsstdctrls.pp:1121-1127): `TGtk4Editable.CaretPos` 프로퍼티 | `Entry^.current_pos` **직접 구조체 접근** (취약) | `getCursorPosition` | 완전 |
| GetSelStart | **7줄** (gtk4wsstdctrls.pp:1129-1135): `TGtk4Editable.getSelStart` | `gtk_editable_get_selection_bounds` | `getSelStart` | 완전 |
| GetSelLength | **7줄** (gtk4wsstdctrls.pp:1137-1143): `TGtk4Editable.getSelLength` | `Abs(AEnd-AStart)` | `getSelLength` | 완전 |
| SetAlignment | **9줄** (gtk4wsstdctrls.pp:1145-1153): `TGtk4Entry.Alignment` 프로퍼티 → `set_alignment(float)` — 래퍼 **13줄** (gtk4widgets.pas:5075-5087) `taLeftJustify→0.0`, `taCenter→0.5`, `taRightJustify→1.0` | `gtk_entry_set_alignment` | `setAlignment(QAlignment)` | 완전 |
| SetCaretPos | **8줄** (gtk4wsstdctrls.pp:1155-1162): `TGtk4Editable.CaretPos` 프로퍼티 설정 | `gtk_editable_set_position` | `setCursorPosition` | 완전 |
| SetEchoMode | **13줄** (gtk4wsstdctrls.pp:1172-1184): `TGtk4Entry.SetEchoMode(bool)` 래퍼 **5줄** (gtk4widgets.pas:5239-5243) `set_visibility` + SetPasswordChar 연동 | `gtk_entry_set_visibility` + `set_invisible_char` | `setEchoMode(enum)` | 완전 |
| SetPasswordChar | **6줄** (gtk4wsstdctrls.pp:1212-1217): `TGtk4Entry.SetPasswordChar(Char)` 래퍼 **12줄** (gtk4widgets.pas:5196-5207) `set_invisible_char` (기본: bullet 9679) | `gtk_entry_set_invisible_char(guint)` + Unicode 변환 | ❌ MISS (비활성) | GTK4 > Qt5 |
| SetHideSelection | **10줄** (gtk4wsstdctrls.pp:1186-1195): `gtk4_widget_add_css_class('lcl-hide-sel')` / `gtk4_widget_remove_css_class` **CSS 기반** | ❌ MISS | ❌ MISS | ✅ GTK4 고유 구현 |
| SetMaxLength | **6줄** (gtk4wsstdctrls.pp:1197-1202): `TGtk4Entry.SetMaxLength` 래퍼 **9줄** (gtk4widgets.pas:5245-5253) `set_max_length` + `set_width_chars` | `gtk_entry_set_max_length` | `setMaxLength` | 완전 |
| SetReadOnly | **6줄** (gtk4wsstdctrls.pp:1219-1224): `TGtk4Editable.ReadOnly` 프로퍼티 | `gtk_editable_set_editable` | `QLineEdit_setReadOnly` | 완전 |
| SetSelStart | **8줄** (gtk4wsstdctrls.pp:1226-1233): `TGtk4Editable.SetSelStart` + BeginUpdate/EndUpdate | `gtk_editable_set_position` | `setSelection(start, 0)` | 완전 |
| SetSelLength | **8줄** (gtk4wsstdctrls.pp:1235-1242): `TGtk4Editable.SetSelLength` + BeginUpdate/EndUpdate | `gtk_entry_select_region` + WidgetInfo 캐시 | `setSelection(start, len)` | 완전 |
| SetCharCase | **7줄** (gtk4wsstdctrls.pp:1164-1170): WS에서 직접 동작 없음 — `TGtk4Entry.InsertText` 콜백 **42줄** (gtk4widgets.pas:5094-5135)에서 `insert-text` 시그널 가로채기 → 대소문자 변환 후 재삽입 | `insert-text` 시그널 콜백 | ❌ MISS | 완전 (콜백 기반) |
| SetNumbersOnly | **7줄** (gtk4wsstdctrls.pp:1204-1210): `TGtk4Entry.SetNumbersOnly` 래퍼 **8줄** (gtk4widgets.pas:5209-5216) `set_input_purpose(GTK_INPUT_PURPOSE_NUMBER)` + InsertText 콜백 이중 검증 | MISS | `inputMethodHints` | 완전 — 이중 검증 (IME 힌트+콜백) |
| SetTextHint | **7줄** (gtk4wsstdctrls.pp:1244-1250): `TGtk4Entry.SetTextHint` 래퍼 **5줄** (gtk4widgets.pas:5218-5222) `set_placeholder_text` | MISS | `setPlaceholderText` | 완전 (GTK4 > GTK2) |

**R31 크로스플랫폼 비교 (Edit 구현 접근법 차이):**

| 관점 | GTK4 | GTK2 | Qt5 | 승자 |
|------|------|------|-----|------|
| Copy/Cut/Paste | **LCL 수준** — Clipboard.AsText/SelText 직접 조작 (5줄) | **GTK API** — `gtk_editable_copy_clipboard` 등 (20줄) | **위젯 메서드** — `QtEdit.Copy()` (9줄) | GTK4 가장 간결, GTK2 가장 네이티브 |
| GetCanUndo | **항상 True** — GtkEntry에 `can_undo` 쿼리 API 없음 | ❌ MISS | `isUndoAvailable` **정확한 상태 쿼리** | ⚠️ Qt5만 정확 — GTK4는 부정확 |
| Undo | `activate_action('text.undo')` **GTK4 액션 시스템** — GTK4.2+ 내장 undo 스택 | ❌ **미구현** (TODO만) | `QtEdit.Undo()` | ✅ GTK4 > GTK2 (유일 구현) |
| SetHideSelection | **CSS 기반** `lcl-hide-sel` 클래스 토글 (10줄) | ❌ MISS | ❌ MISS | ✅ **GTK4 고유** |
| SetCharCase | **insert-text 콜백** 42줄 (대소문자 변환 후 재삽입) | **insert-text 콜백** (유사 패턴) | ❌ MISS | GTK4 ≡ GTK2, Qt5 미지원 |
| SetNumbersOnly | **이중 검증**: `set_input_purpose(NUMBER)` IME 힌트 + `InsertText` 콜백 필터링 | ❌ MISS | `inputMethodHints` (단일) | ✅ GTK4 가장 안전 (이중 필터) |
| SetTextHint | `set_placeholder_text` (7줄) | ❌ MISS | `setPlaceholderText` (9줄) | GTK4 ≡ Qt5, GTK2 미지원 |

### TWSCustomMemo

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| AppendText | IMPL | MISS | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| GetStrings | IMPL | IMPL | IMPL |
| GetCanUndo | IMPL | MISS | MISS |
| GetSelStart | IMPL | IMPL | MISS |
| GetSelLength | IMPL | IMPL | MISS |
| GetCaretPos | IMPL | IMPL | MISS |
| SetAlignment | IMPL | IMPL | IMPL |
| SetCaretPos | IMPL | IMPL | IMPL |
| SetCharCase | IMPL | IMPL | MISS |
| SetEchoMode | IMPL | IMPL | MISS |
| SetHideSelection | IMPL | MISS | MISS |
| SetMaxLength | IMPL | IMPL | MISS |
| SetPasswordChar | IMPL | IMPL | MISS |
| SetReadOnly | IMPL | IMPL | MISS |
| SetSelStart | IMPL | IMPL | MISS |
| SetSelLength | IMPL | IMPL | MISS |
| SetScrollbars | IMPL | IMPL | IMPL |
| SetWantTabs | IMPL | IMPL | IMPL |
| SetWantReturns | IMPL | MISS | IMPL |
| SetWordWrap | IMPL | IMPL | IMPL |
| Undo | IMPL | MISS | MISS |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| SetSelText | base | IMPL | base |
| SetText | MISS | IMPL | MISS |
| FreeStrings | MISS | MISS | MISS |

**GTK4 gaps**: SetColor, SetFont, SetText only (GTK2-specific overrides). ~~SetSelText~~: **오보정 (S64)** — base TWSCustomMemo.SetSelText (wsstdctrls.pp:664-673) 이미 완전 구현: Lines.BeginUpdate 래핑 + TWSCustomEdit.SetSelText 위임. GTK4 Memo has 23 method overrides — exceeds both GTK2 and Qt5.
**ALL MISS**: FreeStrings (base default adequate)

#### TWSCustomMemo 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **9줄** (gtk4wsstdctrls.pp:1280-1288): `TGtk4Memo.Create` + BorderStyle 설정. `CreateWidget` **56줄** (gtk4widgets.pas:7146-7201): GtkScrolledWindow → GtkTextView 생성 + GtkTextBuffer 초기화 + scroll policy + WordWrap 설정 + `InitializeWidget` **10줄** (7203-7212): `insert-text` 시그널→`Gtk4MemoBufferInsertText` 콜백 연결 | `$I gtk2wscustommemo.inc` 별도 파일 | `TQtTextEdit.Create` + 8개 프로퍼티 설정 | 완전 — 래퍼 75줄 합산 |
| GetStrings | **5줄** (gtk4wsstdctrls.pp:1312-1316): `TGtk4MemoStrings.Create` **매 호출 새 객체** | 캐싱된 래퍼 | `FList` 프로퍼티 **캐싱** | ⚠️ 비효율 (매번 새 객체 생성, Qt5는 캐싱) |
| GetCanUndo | **12줄** (gtk4wsstdctrls.pp:1352-1363): `PGtkTextView.get_buffer` → `gtk4_text_buffer_get_can_undo(ABuffer)` **정확한 쿼리** | MISS | MISS | ✅ GTK4 고유 (GTK4.2+ undo API) |
| Undo | **10줄** (gtk4wsstdctrls.pp:1365-1374): `PGtkTextView.get_buffer` → `gtk4_text_buffer_undo(ABuffer)` can_undo 체크 후 | MISS | MISS | ✅ GTK4 고유 |
| GetCaretPos | **15줄** (gtk4wsstdctrls.pp:1376-1390): `get_buffer` → `get_insert` → `get_iter_at_mark` → `get_line` + `get_line_offset` → `Point(col, line)` | `get_buffer` + iter 유사 | MISS | 완전 |
| GetSelStart | **14줄** (gtk4wsstdctrls.pp:1392-1405): `get_buffer` → `get_insert` → `get_iter_at_mark` → `get_offset` (바이트 오프셋) | `get_selection_bounds` | MISS | 완전 |
| GetSelLength | **12줄** (gtk4wsstdctrls.pp:1407-1418): `get_buffer` → `get_selection_bounds` → offset 차이 계산 | `get_selection_bounds` | MISS | 완전 |
| SetAlignment | **7줄** (gtk4wsstdctrls.pp:1420-1426): `TGtk4Memo.Alignment` 프로퍼티 → 래퍼 **5줄** (gtk4widgets.pas:7280-7284) `set_justification(GTK_JUSTIFY_*)` | `gtk_text_view_set_justification` | `setAlignment` | 완전 |
| SetCaretPos | **13줄** (gtk4wsstdctrls.pp:1428-1440): `get_buffer` → `get_iter_at_offset` → `set_line` + `set_line_offset` → `place_cursor(iter)` | `get_iter_at_line_offset` + `place_cursor` | `setTextCursor` | 완전 |
| SetCharCase | **6줄** (gtk4wsstdctrls.pp:1442-1447): WS에서 직접 동작 없음 — `Gtk4MemoBufferInsertText` 콜백에서 대소문자 강제 | 콜백 기반 | MISS | 완전 (콜백 위임) |
| SetEchoMode | **5줄** (gtk4wsstdctrls.pp:1449-1453): 빈 구현 — GtkTextView에 echo 모드 없음 | 유사 제한 | MISS | GTK 제한 |
| SetHideSelection | **10줄** (gtk4wsstdctrls.pp:1455-1464): `gtk4_widget_add_css_class('lcl-hide-sel')` / `remove_css_class` CSS 기반 | MISS | MISS | ✅ GTK4 고유 |
| SetMaxLength | **6줄** (gtk4wsstdctrls.pp:1466-1471): WS에서 직접 동작 없음 — `Gtk4MemoBufferInsertText` 콜백에서 길이 제한 강제 | 콜백 기반 | MISS | 완전 (콜백 위임) |
| SetPasswordChar | **5줄** (gtk4wsstdctrls.pp:1473-1477): 빈 구현 — GtkTextView에 패스워드 모드 없음 | 콜백 기반 | MISS | GTK 제한 (TextView 특성) |
| SetReadOnly | **7줄** (gtk4wsstdctrls.pp:1479-1485): `TGtk4Memo.ReadOnly` 프로퍼티 → 래퍼 **5줄** (gtk4widgets.pas:7286-7290) `set_editable(not AValue)` | `set_editable` | MISS | 완전 |
| SetScrollbars | **12줄** (gtk4wsstdctrls.pp:1318-1329): `Gtk4TranslateScrollStyle` → H/V ScrollBarPolicy 개별 설정 | `gtk_scrolled_window_set_policy` | `setScrollStyle` | 완전 |
| SetSelStart | **11줄** (gtk4wsstdctrls.pp:1487-1497): `get_buffer` → `get_iter_at_offset` → `place_cursor(iter)` | `get_iter_at_offset` + `place_cursor` | MISS | 완전 |
| SetSelLength | **16줄** (gtk4wsstdctrls.pp:1499-1514): `get_buffer` → `get_insert` → `select_range(start_iter, end_iter)` 범위 선택 | `select_range` | MISS | 완전 |
| SetWordWrap | **6줄** (gtk4wsstdctrls.pp:1345-1350): `TGtk4Memo.WordWrap` 프로퍼티 → 래퍼 **10줄** (gtk4widgets.pas:7298-7307) `set_wrap_mode(GTK_WRAP_WORD/NONE)` | `gtk_text_view_set_wrap_mode` | `setLineWrapMode` | 완전 |
| SetWantTabs | **6줄** (gtk4wsstdctrls.pp:1331-1336): `TGtk4Memo.WantTabs` 프로퍼티 → 래퍼 **5줄** (gtk4widgets.pas:7292-7296) `set_accepts_tab` | 시그널 콜백 기반 | `setTabChangesFocus` | 완전 |
| SetWantReturns | **6줄** (gtk4wsstdctrls.pp:1338-1343): `TGtk4Memo.WantReturns` 프로퍼티 (FWantReturns 필드) | MISS | `setAcceptRichText` | 완전 |
| AppendText | **12줄** (gtk4wsstdctrls.pp:1290-1301): `get_buffer` → `get_end_iter` → `insert(iter, text)` 직접 버퍼 삽입 | MISS | `QTextEdit_append` | 완전 (GTK4 > GTK2) |
| GetPreferredSize | **8줄** (gtk4wsstdctrls.pp:1303-1310): `TGtk4Memo.preferredSize()` 위임 | `GetGTKDefaultWidgetSize` | MISS | 완전 |

### TWSButtonControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| GetDefaultColor | IMPL | MISS | MISS |

**GTK4 advantage**: Provides proper default color for button controls. GTK2/Qt5 모두 미구현 — 시스템 기본값 사용.

#### TWSButtonControl 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| GetDefaultColor | 정적 배열: `dctBrush=clBtnFace`, `dctFont=clBtnText` 반환 | ❌ 미구현 (기본 clDefault) | ❌ 미구현 (기본 clDefault) | ✅ **GTK4 유일** — 버튼 컨트롤에 적절한 기본색 제공 |

### TWSButton

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| GetText | MISS | IMPL | MISS |
| SetDefault | IMPL | IMPL | IMPL |
| SetShortCut | IMPL | IMPL | IMPL |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| SetText | MISS | IMPL | MISS |

**GTK4 gaps**: SetColor, SetFont, SetText (GTK2-specific; handled by TWSWinControl base). GetPreferredSize is now IMPL.

#### TWSButton 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **14줄** (gtk4wsstdctrls.pp:1554-1567): `TGtk4Button.Create(AWinControl, AParams)` + debug 출력. `CreateWidget` **17줄** (gtk4widgets.pas:10184-10200): `GtkButton` 생성 + `'clicked'` 시그널→`ButtonClicked` 콜백 + `set_use_underline(True)` + FMargin/FLayout/FSpacing 초기화. `setText` **29줄** (10154-10182): Box 레이아웃 내 GtkLabel 탐색 + underline 변환 | `gtk_button_new_with_label` + `g_signal_connect(clicked)` + `CreateWidgetInfo` | `TQtButton.Create(AWinControl, AParams)` | 완전 — 래퍼 합산 60줄 |
| GetPreferredSize | **7줄** (gtk4wsstdctrls.pp:1569-1575): `TGtk4Button.preferredSize()` 위임 → `gtk_widget_get_preferred_size` | `gtk_widget_size_request` | 미구현 | ✅ GTK4 우수 (Qt5 미구현) |
| SetDefault | **6줄** (gtk4wsstdctrls.pp:1577-1582): `TGtk4Button.SetDefault` 래퍼 **5줄** (gtk4widgets.pas:10213-10217) `set_can_default(ADefault)` | `gtk_widget_set_can_default` + `gtk_widget_grab_default` | `setDefault(True)` + `setAutoDefault(True)` | 완전 |
| SetShortCut | **7줄** (gtk4wsstdctrls.pp:1584-1590): `Gtk4SetWidgetShortCut()` — mnemonic + 가속키 설정 | `gtk_button_set_label` (mnemonic 포함) | 미구현 | ✅ **GTK4 유일 구현** — GTK2는 라벨에 포함, Qt5는 미구현 |
| SetColor/SetFont/SetText/GetText | ❌ MISS — TWSWinControl에서 처리 | `gtk_widget_modify_color/font`, `gtk_button_set_label/get_label` | ❌ MISS | ⚠️ GTK2만 위젯 수준 재정의 (아키텍처 차이, 기능 차이 아님) |

### TWSCustomCheckBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| RetrieveState | IMPL | IMPL | IMPL |
| SetShortCut | IMPL | IMPL | IMPL |
| SetState | IMPL | IMPL | IMPL |
| SetAlignment | IMPL | MISS | IMPL |
| SetFont | MISS | IMPL | MISS |
| SetText | MISS | IMPL | MISS |
| ShowHide | IMPL | IMPL | IMPL |

**GTK4 gaps**: SetFont/SetText (GTK2-only overrides). GetPreferredSize, SetAlignment and ShowHide are fully implemented.

#### TWSCustomCheckBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **7줄** (gtk4wsstdctrls.pp:1594-1600): `TGtk4CheckBox.Create(AWinControl, AParams)` 래퍼 위임. 래퍼 `CreateWidget` (gtk4widgets.pas): `gtk4_check_button_new` → `set_label(Caption)` → `toggled` 시그널 연결 | `gtk_check_button_new_with_label` + size_allocate + 시그널 (~20줄) | `TQtCheckBox.Create` + TriState 설정 | 완전 |
| RetrieveState | **8줄** (gtk4wsstdctrls.pp:1602-1609): `TGtk4CheckBox.State` 프로퍼티 → `gtk4_check_button_get_inconsistent` → `cbGrayed`, `gtk4_check_button_get_active` → `cbChecked`/`cbUnchecked`. **매핑 순서**: inconsistent 우선 체크 후 active 체크 | `gtk_toggle_button_get_inconsistent` + `get_active` 조합 | `CheckState` → LCL 매핑 | 완전 |
| SetState | **12줄** (gtk4wsstdctrls.pp:1611-1622): `TGtk4CheckBox.State := NewState` — 래퍼에서 `BeginUpdate` → `set_inconsistent(cbGrayed)` + `set_active(cbChecked)` → `EndUpdate`. **Tri-state 완전 지원** | `LockOnChange` + `set_inconsistent` + `set_active` 수동 | `setTriState` + `setCheckState` + BeginUpdate/EndUpdate | 완전 |
| SetAlignment | **8줄** (gtk4wsstdctrls.pp:1624-1631): `Widget^.set_direction(GTK_TEXT_DIR_RTL/LTR)` — `taRightJustify`→RTL(체크박스 오른쪽 배치) | MISS | `QWidget_setLayoutDirection` | 완전 (GTK4≡Qt5 방식 동일) |
| ShowHide | **10줄** (gtk4wsstdctrls.pp:1633-1642): 정렬 방향 재설정 (`set_direction`) → `TGtk4WSWinControl.ShowHide` 위임. GTK2는 폰트 재적용 워크어라운드 필요 (#21172, #23152) | 폰트 재적용 (#21172, #23152 이슈) + AdjustSize (~40줄) | 폰트 동기화 (r53365 회귀 방지) | ✅ 완전 — GTK4가 가장 간결 (GTK2 버그 워크어라운드 불필요) |
| SetShortCut | **5줄** (gtk4wsstdctrls.pp:1644-1648): `TGtk4CheckBox.ShortCut` 프로퍼티 위임 → mnemonic 라벨 파싱 | `gtk_check_button_set_label` + mnemonic | `TQtCheckBox.setShortcut` | 완전 |

### TWSToggleBox

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | MISS | MISS |
| RetrieveState | IMPL | MISS | IMPL |
| SetState | IMPL | MISS | IMPL |
| SetShortCut | MISS | MISS | IMPL |
| SetFont | MISS | IMPL | MISS |

**GTK4 gaps**: SetShortCut (Qt5 only). GetPreferredSize, RetrieveState and SetState are GTK4 advantages.

#### TWSToggleBox 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **5줄** (gtk4wsstdctrls.pp:467-471): `TGtk4ToggleButton.Create()` 래퍼 위임. 래퍼 `CreateWidget` (gtk4widgets.pas): `gtk_toggle_button_new_with_label(Caption)` → `toggled` 시그널 연결 | `gtk_toggle_button_new_with_label()` + size_allocate + RC_Name + SetCallbacks (20줄) | `TQtToggleBox.Create()` + setCheckable + AttachEvents (6줄) | 완전 — OOP 래퍼 (GTK2보다 간결) |
| GetPreferredSize | **6줄** (gtk4wsstdctrls.pp:473-478): `TGtk4ToggleButton.preferredSize()` 위임 — **주석**: "TGtk4ToggleButton is a TGtk4Button, not a TGtk4CheckBox" → GtkToggleButton의 고유 intrinsic size 반환 | ❌ 미구현 (상속) | ❌ 미구현 (상속) | ✅ **GTK4 유일** — ToggleButton/CheckBox 크기 분리 |
| RetrieveState | **8줄** (gtk4wsstdctrls.pp:480-487): `gtk_toggle_button_get_active()` → `cbChecked`/`cbUnchecked`. **Tri-state 미지원** (주석 명시: "binary only") — `cbGrayed` 반환 안됨 | ❌ 미구현 (상속) | `TQtToggleBox.isChecked()` → cbChecked/cbUnchecked (동일 바이너리) | ✅ GTK4 ≡ Qt5 동등 |
| SetState | **10줄** (gtk4wsstdctrls.pp:489-498): `gtk_toggle_button_set_active(widget, NewState <> cbUnchecked)`. `cbGrayed`→checked로 매핑 (downgrade). **BeginUpdate/EndUpdate 없음** — GTK2도 상속에서 미사용 | ❌ 미구현 (상속) | `TQtToggleBox.setChecked()` + BeginUpdate/EndUpdate 시그널 가드 | 완전 — Qt5는 시그널 가드 추가 (더 안전) |
| SetFont | ❌ 미구현 (상속) | `inherited SetFont` + `gtk_label_set_justify(JUSTIFY_CENTER)` 라벨 중앙 정렬 (10줄) | ❌ 미구현 (상속) | GTK4/Qt5는 CSS/기본 정렬로 처리 |

### TWSRadioButton

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| SetShortCut | MISS | MISS | IMPL |
| SetState | MISS | MISS | IMPL |
| RetrieveState | MISS | MISS | IMPL |

**GTK4 gaps**: SetShortCut/SetState/RetrieveState (Qt5 has custom overrides). GTK4/GTK2는 TWSCustomCheckBox 상속으로 처리.

#### TWSRadioButton 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **7줄** (gtk4wsstdctrls.pp:456-462): `TGtk4RadioButton.Create(AWinControl, AParams)` 래퍼 위임. 래퍼 `CreateWidget` **48줄** (gtk4widgets.pas): `gtk4_check_button_new` → **join_group 로직**: 부모 컨테이너 자식 순회 → 첫 번째 라디오 버튼 발견 → `gtk4_check_button_set_group(FirstRadio)`. `toggled` 시그널 연결. **GTK4 GtkCheckButton 기반** (GTK2 GtkRadioButton 삭제됨) | `gtk_radio_button_new_with_label` + GSList 라디오 그룹 관리 (~25줄) | `TQtRadioButton.Create()` (~8줄) | 완전 — GTK4 join_group 패턴 정확 |
| SetShortCut | ❌ MISS — TWSCustomCheckBox.SetShortCut 상속 (동작은 정상: mnemonic 라벨 파싱) | ❌ MISS — 상속 | `setShortcut()` 직접 재정의 | ⚠️ Qt5만 독자 구현 (GTK4/GTK2는 상속으로 동작) |
| SetState | ❌ MISS — TWSCustomCheckBox.SetState 상속 (바이너리 체크/언체크로 동작) | ❌ MISS — 상속 | `setChecked()` + `BeginUpdate/EndUpdate` | ⚠️ Qt5만 독자 구현 |
| RetrieveState | ❌ MISS — TWSCustomCheckBox.RetrieveState 상속 (active→cbChecked, !active→cbUnchecked) | ❌ MISS — 상속 | `TQtRadioButton.isChecked()` → cbChecked/cbUnchecked | ⚠️ Qt5만 독자 구현 |

### TWSCustomStaticText

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | IMPL | IMPL |
| GetPreferredSize | IMPL | IMPL | MISS |
| SetAlignment | IMPL | IMPL | IMPL |
| SetStaticBorderStyle | IMPL | IMPL | IMPL |
| GetText | MISS | IMPL | MISS |
| SetColor | MISS | IMPL | MISS |
| SetFont | MISS | IMPL | MISS |
| SetText | MISS | IMPL | MISS |

**GTK4 gaps**: SetColor/SetFont/SetText (GTK2-specific; handled by TWSWinControl in GTK4). GetPreferredSize is now IMPL.

#### TWSCustomStaticText 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | **7줄** (gtk4wsstdctrls.pp:1518-1524): `TGtk4StaticText.Create(AWinControl, AParams)` 래퍼 위임. 래퍼 `CreateWidget`: GtkLabel 생성 → GtkOverlay 래핑 + GtkDrawingArea (LCL 커스텀 드로잉) | `gtk_label_new` + `gtk_frame_new` + `gtk_frame_set_shadow_type` + `gtk_misc_set_alignment` (~20줄) | `TQtStaticText.Create` + `setFrameShape` | 완전 |
| GetPreferredSize | **6줄** (gtk4wsstdctrls.pp:1526-1531): `TGtk4StaticText.preferredSize()` 위임 → `gtk_widget_get_preferred_size` | `gtk_widget_size_request` | 미구현 | ✅ GTK4 우수 (Qt5 미구현) |
| SetAlignment | **8줄** (gtk4wsstdctrls.pp:1533-1540): `TGtk4StaticText.Alignment` 프로퍼티 → `gtk_label_set_xalign(0.0/0.5/1.0)` — GTK4는 `xalign` 프로퍼티 사용 (deprecated `gtk_misc_set_alignment` 대체) | `gtk_misc_set_alignment(xalign, 0.5)` | `setAlignment` | 완전 |
| SetStaticBorderStyle | **6줄** (gtk4wsstdctrls.pp:1542-1547): `TGtk4StaticText.BorderStyle` 프로퍼티 (CSS 기반). 래퍼에서 `sbsSunken`→`'border: 1px inset; '`, `sbsSimple`→`'border: 1px solid; '`, `sbsNone`→`'border: none; '`. **GTK4는 `gtk_frame_set_shadow_type()` 제거** → CSS border로 에뮬레이션 | `gtk_frame_set_shadow_type(sbsNone→NONE, sbsSunken→ETCHED_IN, sbsSimple→ETCHED_OUT)` 네이티브 3D shadow | `setFrameShape(NoFrame/StyledPanel/Panel)` | ⚠️ CSS flat border — GTK2의 3D shadow 효과와 시각적 차이 |
| SetColor/SetFont/SetText/GetText | ❌ MISS — TWSWinControl에서 처리. 래퍼 `TGtk4StaticText.setText` (gtk4widgets.pas)에서 `gtk_label_set_text` 호출 | `gtk_label_set_text`, 폰트/색 직접 설정 (~15줄) | ❌ MISS | ⚠️ GTK2만 위젯 수준 재정의 (아키텍처 차이, 래퍼에서 대응) |

---

## 14. WSSplitter (gtk4wssplitter.pas)

### TWSPairSplitterSide

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | IMPL |

### TWSCustomPairSplitter

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | MISS |
| AddSide | IMPL | MISS | MISS |
| RemoveSide | IMPL | MISS | MISS |
| SetPosition | IMPL | MISS | MISS |
| GetSplitterCursor | IMPL | MISS | MISS |
| SetSplitterCursor | IMPL | MISS | MISS |
| GetPosition | MISS | MISS | MISS |

**GTK4 advantage**: Full PairSplitter implementation with 6 methods. Qt5 has TQtWSPairSplitterSide.CreateHandle only. GTK2 has empty class declarations.
**ALL MISS**: GetPosition (base default adequate — declared in wspairsplitter.pp but no platform overrides it)

#### TWSCustomPairSplitter 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| CreateHandle | `TGtk4Paned.Create()` (gtk4wssplitter.pas:56-59) → `TGtk4Paned.CreateWidget` (gtk4widgets.pas:2847-2855, 9줄): `TGtkPaned.new(ornt[SplitterType])` — orientation 매핑 테이블 | ❌ 빈 클래스 | ❌ 빈 클래스 | ✅ **GTK4 유일** — GtkPaned 네이티브 위젯 |
| AddSide | **28줄** (gtk4wssplitter.pas:69-96): 에러 체크 (handle 할당, side 범위) → `set_parent(nil)` 리페어런트 → `paned^.add1()` (Side=0) / `paned^.add2()` (Side=1). ~~타이포~~ ✅ S61 수정 | ❌ 미구현 | ❌ 미구현 | ✅ **GTK4 유일** |
| RemoveSide | ❌ **STUB** — `Result := False` 반환 (gtk4wssplitter.pas:98-102) | ❌ 미구현 | ❌ 미구현 | ❌ 미구현 — 동적 분할 제거 불가 |
| SetPosition | **14줄** (gtk4wssplitter.pas:104-117): `paned^.set_position(NewPosition)` GtkPaned 네이티브 API 직접 호출 | ❌ 미구현 | ❌ 미구현 | ✅ **GTK4 유일** |
| GetSplitterCursor | SplitterType에 따라 crVSplit/crHSplit 반환 (gtk4wssplitter.pas:129-137) | ❌ 미구현 | ❌ 미구현 | ✅ **수정됨 (S61)** — 수직/수평 커서 올바르게 반환 |
| SetSplitterCursor | ❌ **STUB** — `Result := False` (gtk4wssplitter.pas:126-131). 코드에 `ASplitter.Cursor := ACursor` 가 **주석 처리**됨 | ❌ 미구현 | ❌ 미구현 | ❌ 커서 변경 불가 |

**GTK4 PairSplitter 아키텍처:**
- GTK4가 **유일하게 실구현** (6개 메서드 중 4개). GTK2 빈 클래스, Qt5는 PairSplitterSide.CreateHandle만
- GtkPaned 네이티브 위젯 사용 — 네이티브 드래그 분할선 지원, 사용자 리사이즈 가능
- **2개 STUB** (RemoveSide, SetSplitterCursor) — 동적 패널 제거와 커서 변경 미구현

**R31 래퍼 검증**: `TGtk4Paned` 래퍼 (gtk4widgets.pas:2847-2855, **9줄**) — 최소 래퍼. `CreateWidget`에서 `TGtkPaned.new(orientation)` 한 줄이 핵심. 나머지 WS 메서드(AddSide/SetPosition 등)는 gtk4wssplitter.pas에서 GtkPaned API 직접 호출 (래퍼 경유하지 않음). 이는 §22i WS→래퍼 패턴의 **예외**: PairSplitter WS는 래퍼에 위임하지 않고 직접 GTK4 API 사용.
- ~~**GetPosition 미구현**~~: ✅ **오보정 (S63)** — 실제 구현됨 (gtk4wssplitter.pas:105-112): `paned^.get_position` 호출
- TWSPairSplitterSide.CreateHandle: GTK4 `TGtk4Window.Create()` (gtk4wssplitter.pas:52-56, 5줄), Qt5 `TQtWidget.Create()` + `QtWA_NoMousePropagation`

---

## 14b. WSExtDlgs (gtk4wsextdlgs.pp)

### TWSPreviewFileControl

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | IMPL | MISS | MISS |

### Other classes (empty declarations)

- TGtk4WSPreviewFileDialog
- TGtk4WSOpenPictureDialog
- TGtk4WSSavePictureDialog
- TGtk4WSCalculatorDialog, TGtk4WSCalculatorForm
- TGtk4WSCalendarDialogForm, TGtk4WSCalendarDialog

**GTK4 note**: Only TWSPreviewFileControl has actual implementation; others are empty class stubs. GTK2 registers TGtk2WSPreviewFileControl but the class has no overrides (empty).

#### TWSPreviewFileControl 구현 수준 상세

| Method | GTK4 | GTK2 | Qt5 | 비고 |
|--------|------|------|-----|------|
| CreateHandle | ✅ `TGtk4CustomControl.Create()` 위임 (3줄) | ❌ 클래스 등록만, override 없음 | ❌ 미구현 | GTK4 유일 구현 |

- **GTK4**: `TGtk4WSPreviewFileControl.CreateHandle` → `TGtk4CustomControl.Create(AWinControl, AParams)` — 표준 CustomControl 위임 패턴. 프리뷰 영역용 GtkDrawingArea 기반 위젯 생성.
- **GTK2/Qt5**: 모두 미구현. 프리뷰 기능은 LCL 레벨에서 TCustomControl 베이스로 처리됨.

---

## 15. WSControls — TWSLazAccessibleObject (wscontrols.pp)

Accessibility support class. Base defines 8 virtual methods. Only Qt5 provides overrides.

### TWSLazAccessibleObject

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | MISS | MISS | IMPL |
| DestroyHandle | MISS | MISS | IMPL |
| SetAccessibleName | MISS | MISS | MISS |
| SetAccessibleDescription | MISS | MISS | MISS |
| SetAccessibleValue | MISS | MISS | MISS |
| SetAccessibleRole | MISS | MISS | IMPL |
| SetPosition | MISS | MISS | MISS |
| SetSize | MISS | MISS | MISS |

**GTK4 gaps**: All 8 methods missing. Qt5 implements 3/8 via TQtWSLazAccessibleObject (CreateHandle creates QAccessibleBridge, DestroyHandle, SetAccessibleRole). GTK4 factory registration is commented out (`// RegisterWSLazAccessibleObject(TGtk4WSLazAccessibleObject)` in gtk4wsfactory.pas). GTK2 also has no implementation.

#### TWSLazAccessibleObject 구현 수준 상세

| Method | GTK4 | GTK2 | Qt5 | 비고 |
|--------|------|------|-----|------|
| CreateHandle | ❌ | ❌ | ✅ QAccessibleBridge 생성 | Qt5 고유 |
| DestroyHandle | ❌ | ❌ | ✅ Bridge 해제 | Qt5 고유 |
| SetAccessibleRole | ❌ | ❌ | ✅ QAccessible.Role 매핑 | Qt5 고유 |
| SetAccessibleName | ❌ | ❌ | ❌ | 전체 미구현 |
| SetAccessibleDescription | ❌ | ❌ | ❌ | 전체 미구현 |
| SetAccessibleValue | ❌ | ❌ | ❌ | 전체 미구현 |
| SetPosition | ❌ | ❌ | ❌ | 전체 미구현 |
| SetSize | ❌ | ❌ | ❌ | 전체 미구현 |

- **GTK4**: WSFactory 등록 자체가 주석 처리됨. GTK4는 `GtkAccessible` 인터페이스를 제공하며, ATK(GTK2/3) 대신 `GtkAccessibleRole` 기반 접근성 모델 사용. 향후 구현 시 `gtk_accessible_update_property()` API 활용 가능.
- **Qt5**: 3/8 구현. `QAccessibleBridge` 기반으로 역할(role) 설정까지 지원. 이름/설명/값 설정은 미구현.
- **GTK2**: 전체 미구현. ATK 바인딩은 존재하나 WS 레벨 접근성 구현 없음.

---

## 16. WSDesigner (Qt5 only)


### TWSCustomRubberBand

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| CreateHandle | MISS | MISS | IMPL |
| SetShape | MISS | MISS | IMPL |

**GTK4 note**: RubberBand handled via LCLIntf (CreateRubberBand/DestroyRubberBand/SetRubberBandRect)

#### TWSCustomRubberBand 구현 수준 상세

| Method | GTK4 | GTK2 | Qt5 | 비고 |
|--------|------|------|-----|------|
| CreateHandle | ❌ | ❌ | ✅ `TQtWidget.Create` + `QRubberBand_create` | Qt5 고유 |
| SetShape | ❌ | ❌ | ✅ `QRubberBand_setShape` | Qt5 고유 |

- **Qt5**: `TQtWsCustomRubberBand` — `QRubberBand` 네이티브 위젯 사용. 디자이너에서 컴포넌트 선택 영역 표시용.
- **GTK4/GTK2**: WS 클래스 미구현. GTK4는 `LCLIntf.CreateRubberBand` → `TGtk4RubberBand` (gtk4winapi.inc)에서 `GtkDrawingArea` 기반 커스텀 구현 제공. WS 경로가 아닌 WinAPI 경로로 처리됨.

---

## 16b. WSShellCtrls (wsshellctrls.pp — Win32 only)

### TWSCustomShellTreeView

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| DrawBuiltInIcon | MISS | MISS | MISS |
| GetBuiltinIconSize | MISS | MISS | MISS |

### TWSCustomShellListView

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| GetBuiltInImageIndex | MISS | MISS | MISS |

**Note**: Only Win32 has platform-specific implementations (win32wsshellctrls.pp). All other platforms use base class defaults. Shell icon rendering is a Windows-specific feature using SHGetFileInfo.

#### TWSCustomShellTreeView / TWSCustomShellListView 구현 수준 상세

| Method | GTK4 | GTK2 | Qt5 | Win32 | 비고 |
|--------|------|------|-----|-------|------|
| DrawBuiltInIcon | ❌ | ❌ | ❌ | ✅ SHGetFileInfo | Win32 전용 |
| GetBuiltinIconSize | ❌ | ❌ | ❌ | ✅ GetSystemMetrics | Win32 전용 |
| GetBuiltInImageIndex | ❌ | ❌ | ❌ | ✅ SHGetFileInfo | Win32 전용 |

- **Win32 전용**: 셸 아이콘은 Windows `SHGetFileInfo` API로만 네이티브 조회 가능. Linux/macOS에서는 freedesktop.org 아이콘 테마를 LCL 레벨에서 직접 처리.
- **GTK4/GTK2/Qt5**: 모두 미구현. WSFactory 등록 자체가 없거나 빈 클래스. 파일 아이콘은 `TShellTreeView`/`TShellListView` LCL 코드에서 `TCustomImageList`로 직접 관리.

---

## 16c. WSLazDeviceAPIs (wslazdeviceapis.pas — Mobile only)

### TWSLazDeviceAPIs

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| RequestPositionInfo | MISS | MISS | MISS |
| SendMessage | MISS | MISS | MISS |
| StartReadingAccelerometerData | MISS | MISS | MISS |
| StopReadingAccelerometerData | MISS | MISS | MISS |
| GetDeviceManufacturer | MISS | MISS | MISS |
| GetDeviceModel | MISS | MISS | MISS |
| GetScreenRotation | MISS | MISS | MISS |
| Vibrate | MISS | MISS | MISS |

**Note**: Mobile device API class. WSFactory registration is commented out in ALL desktop platforms (`//RegisterWSLazDeviceAPIs(...)` in gtk4/gtk2/qt5 wsfactory.pas). Only CustomDrawn (Android) provides actual implementations. These 8 methods are mobile-only and not relevant to desktop GTK4/GTK2/Qt5.

#### TWSLazDeviceAPIs 구현 수준 상세

| Method | GTK4 | GTK2 | Qt5 | Android (CD) | 비고 |
|--------|------|------|-----|-------------|------|
| RequestPositionInfo | ❌ | ❌ | ❌ | ✅ GPS | 모바일 전용 |
| SendMessage | ❌ | ❌ | ❌ | ✅ SMS | 모바일 전용 |
| StartReadingAccelerometerData | ❌ | ❌ | ❌ | ✅ Sensor | 모바일 전용 |
| StopReadingAccelerometerData | ❌ | ❌ | ❌ | ✅ Sensor | 모바일 전용 |
| GetDeviceManufacturer | ❌ | ❌ | ❌ | ✅ Build.MANUFACTURER | 모바일 전용 |
| GetDeviceModel | ❌ | ❌ | ❌ | ✅ Build.MODEL | 모바일 전용 |
| GetScreenRotation | ❌ | ❌ | ❌ | ✅ Display | 모바일 전용 |
| Vibrate | ❌ | ❌ | ❌ | ✅ Vibrator | 모바일 전용 |

- **전체 데스크톱 미구현**: GPS, SMS, 가속도계, 진동 등 모바일 하드웨어 API. 데스크톱 플랫폼(GTK4/GTK2/Qt5/Win32/Cocoa)에서는 해당 하드웨어 자체가 없으므로 구현 불가.
- **Android (CustomDrawn)**: JNI를 통해 Android Java API 호출. `customdrawnwslazdeviceapis.pas`에서 8/8 구현.

---

## 17. LCLIntf Methods (gtk4lclintfh.inc)

| Method | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| AddEventHandler | IMPL | IMPL | IMPL |
| AddPipeEventHandler | IMPL | IMPL | IMPL |
| AddProcessEventHandler | IMPL | IMPL | IMPL |
| AskUser | IMPL | IMPL | IMPL |
| CreateRubberBand | IMPL | IMPL | IMPL |
| CreateStandardCursor | IMPL | IMPL | IMPL |
| DestroyRubberBand | IMPL | IMPL | IMPL |
| DrawDefaultDockImage | IMPL | IMPL | IMPL |
| DrawGrid | IMPL | IMPL | IMPL |
| ExtUTF8Out | IMPL | IMPL | IMPL |
| FontIsMonoSpace | IMPL | IMPL | IMPL |
| GetAcceleratorString | IMPL | IMPL | IMPL |
| GetControlConstraints | IMPL | IMPL | IMPL |
| GetDesignerDC | IMPL | MISS | IMPL |
| GetLCLOwnerObject | IMPL | IMPL | IMPL |
| IsDesignerDC | IMPL | MISS | IMPL |
| PromptUser | IMPL | IMPL | IMPL |
| RadialPie | IMPL | IMPL | IMPL |
| RawImage_CreateBitmaps | IMPL | IMPL | IMPL |
| RawImage_DescriptionFromBitmap | IMPL | IMPL | IMPL |
| RawImage_DescriptionFromDevice | IMPL | IMPL | IMPL |
| RawImage_FromBitmap | IMPL | IMPL | IMPL |
| RawImage_FromDevice | IMPL | IMPL | IMPL |
| RawImage_QueryDescription | IMPL | IMPL | IMPL |
| ReleaseDesignerDC | MISS | MISS | IMPL |
| RemoveEventHandler | IMPL | IMPL | IMPL |
| RemovePipeEventHandler | IMPL | IMPL | IMPL |
| RemoveProcessEventHandler | IMPL | IMPL | IMPL |
| SetComboMinDropDownSize | IMPL* | IMPL | IMPL |
| SetEventHandlerFlags | IMPL | IMPL | IMPL |
| SetRubberBandRect | IMPL* | IMPL | IMPL |
| TextUTF8Out | IMPL | IMPL | IMPL |
| DCSetAntialiasing | IMPL | IMPL | IMPL |
| SetCursorPos | IMPL* | IMPL | IMPL |

**GTK4 gaps**: ReleaseDesignerDC (Qt5-only). ~~GetDesignerDC~~ R26 정정: IMPL (gtk4winapi.inc:2705-2710)
**GTK4 IMPL* 이슈**:
- ~~`RawImage_CreateBitmaps`~~: ✅ **오보정 (S62)** — DataOwner=True 무조건 전달이 정확 (Bug#10). NewData는 항상 GetMem 할당
- ~~`RawImage_FromBitmap`~~: ✅ **수정됨 (S61)** — 70+줄 주석 코드 삭제 완료
- `SetRubberBandRect` (gtk4lclintf.inc:1518-1530): Wayland에서 위치 설정 불가 — 크기만 동작 (플랫폼 제한)
- `SetComboMinDropDownSize` (gtk4lclintf.inc:1430-1449): GTK4 팝업 내부 관리로 제한적 제어 (플랫폼 제한)
- `SetCursorPos` (gtk4winapi.inc:4809-4864): X11 전용 — Wayland 미지원 (보안 정책)

#### LCLIntf 구현 수준 상세

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| AddEventHandler | **23줄** (gtk4lclintf.inc:1465-1487): `g_io_channel_unix_new` + `g_io_add_watch`. `PWaitHandleEventHandler` 이중연결리스트 + GSourceID 관리 | GTK4와 동일 구현 | QSocketNotifier 기반 (다른 아키텍처) | 완전 |
| AddPipeEventHandler | **15줄** (gtk4lclintf.inc:1540-1554): `TPipeEventInfo` 할당 + AddEventHandler 래핑, `G_IO_IN\|G_IO_HUP\|G_IO_OUT` 플래그 | GTK4와 동일 | ❌ STUB (`// todo` 주석) | ✅ GTK4 > Qt5 |
| AddProcessEventHandler | **18줄** (gtk4lclintf.inc:1585-1602): UNIX `PChildSignalEventHandler` 이중연결리스트 + PID 관리. Non-UNIX nil 반환 | GTK4와 동일 | ❌ STUB (nil 반환) | ✅ GTK4 > Qt5 |
| AskUser | **13줄** (gtk4lclintf.inc:1399-1411): `TGtk4DialogFactory.CreateAsk` → `dialog.run()` → `factory.lcl_result` | 직접 GTK2 API (233줄, 수동 버튼 매핑) | `TQtMessageBox` 클래스 | 완전 — GTK4 가장 간결 |
| PromptUser | **15줄** (gtk4lclintf.inc:1413-1427): `TGtk4DialogFactory.CreatePrompt` → 커스텀 버튼 배열 + 기본 인덱스 | GTK2 다이얼로그 직접 구성 | `TQtMessageBox` | 완전 |
| CreateRubberBand | **23줄** (gtk4lclintf.inc:17-39): `gtk4_window_new` + `gtk_window_set_decorated(False)` + `gtk_widget_set_opacity(0.25)` | pixmap 패턴 채움 지원 (48줄) | `QRubberBand_create` 네이티브 | 완전 — GTK2 ABrush 지원 부재 |
| DestroyRubberBand | **5줄** (gtk4lclintf.inc:41-45): `gtk_window_close` | 윈도우 파괴 | `QRubberBand.Destroy` | 완전 |
| SetRubberBandRect | **13줄** (gtk4lclintf.inc:1518-1530): ⚠️ 크기만 설정 (`gtk_window_set_default_size`), **위치 설정 불가** (Wayland) | `gdk_window_move_resize` 완전 | `QRubberBand_setGeometry` 완전 | ❌ Wayland 제한 |
| CreateStandardCursor | **49줄** (gtk4object.inc:724-772): LCL 커서 상수 (crLow=-30..crHigh=0) → GTK4 CSS 이름 26종 매핑 via `gdk4_cursor_new_from_name` | GDK 커서 타입 매핑 | Qt 커서 shape 매핑 (226줄) | 완전 |
| DrawDefaultDockImage | **28줄** (gtk4lclintf.inc:47-74): ⚠️ `FDockImage` 반투명 윈도우 재사용, show/hide + `gtk_window_set_default_size` — Wayland에서 **위치 지정 불가** | 셰이프 마스크 + 위치 지정 완전 | `QRubberBand` + geometry | ⚠️ Wayland 제한 |
| DrawGrid | **16줄** (gtk4lclintf.inc:76-91): Cairo `cairo_rectangle(1×1)` + `cairo_fill` 이중 루프 (Y×X). `SetSourceColor(CurrentPen.Color)` | ExcludeClipRect 기반 접근 (27줄) | QPainter drawPoint | 완전 |
| ExtUTF8Out | **6줄** (gtk4lclintf.inc:113-118): `ExtTextOut()` 위임 | 동일 위임 | 동일 위임 | 위임 (UTF8 특별 처리 불필요) |
| TextUTF8Out | **5줄** (gtk4lclintf.inc:120-124): `TextOut()` 위임 | 동일 위임 | 동일 위임 | 위임 |
| FontIsMonoSpace | **23줄** (gtk4lclintf.inc:131-153): Pango 레이아웃 `pango_layout_get_pixel_size` — 'm' vs 'i' 문자 너비 비교 | `FontIsMonoSpaceFont()` 래퍼 (5줄) | `QFontInfo.fixedPitch()` 네이티브 (13줄) | 완전 |
| GetAcceleratorString | **5줄** (gtk4lclintf.inc:162-166): `inherited` 위임 | 동일 위임 | 동일 위임 | 위임 |
| GetControlConstraints | **47줄** (gtk4lclintf.inc:1339-1385): 스크롤바 `gtk4_widget_measure` + 페이지 컨트롤 탭 위치별 최소치 20px. `SizeConstraints.SetInterfaceConstraints` | 유사 구현 | 구현 확인 불분명 | 완전 |
| GetDesignerDC | **6줄** (gtk4winapi.inc:2705-2710): `GetDC(WindowHandle)` 위임 — 디자이너용 DC 반환 | ❌ MISS | 디자이너 DC 생성 | ✅ GTK4 > GTK2 |
| IsDesignerDC | **12줄** (gtk4lclintf.inc:94-105): `csDesigning` + Context=DC 3중 검사 | ❌ MISS | `TQtDesignWidget` 타입 체크 | ✅ GTK4 > GTK2 |
| ReleaseDesignerDC | ❌ MISS — GTK4/GTK2 미구현 | ❌ MISS | DC 해제 | Qt5 전용 |
| GetLCLOwnerObject | **7줄** (gtk4lclintf.inc:1391-1397): `TGtk4Widget(Handle).LCLObject` 직접 접근 | `GetNearestLCLObject()` 래퍼 | 유사 접근 | 완전 |
| RadialPie | **14줄** (gtk4lclintf.inc:177-190): `ctx.drawPie(x1,y1,x2,y2,Angle1,Angle2,bFill,bBorder)` — 네이티브 Cairo 파이 | 유사 Cairo 구현 | `QPainter_drawPie()` | 완전 |
| SetComboMinDropDownSize | **20줄** (gtk4lclintf.inc:1430-1449): ⚠️ `gtk_widget_set_size_request` + `set_popup_fixed_width(False)` — 최소 너비만, GTK4 팝업 내부 관리로 높이 제어 제한 | 내부 메뉴 위젯에 `size_request` 직접 설정 | 최소 치수 + 최대 가시 항목 수 설정 | ⚠️ 부분적 |
| SetEventHandlerFlags | **9줄** (gtk4lclintf.inc:1508-1516): `g_source_remove` + `g_io_add_watch` — IOChannel 플래그 재등록 | GTK4와 동일 | 다른 아키텍처 | 완전 |
| RemoveEventHandler | **17줄** (gtk4lclintf.inc:1490-1506): `g_source_remove(GSourceID)` + `g_io_channel_unref` + 이중연결리스트 해제 | GTK4와 동일 | QSocketNotifier 해제 | 완전 |
| RemovePipeEventHandler | **9줄** (gtk4lclintf.inc:1574-1582): `RemoveEventHandler` 호출 + `TPipeEventInfo` 해제 | GTK4와 동일 | 미확인 | 완전 |
| RemoveProcessEventHandler | **14줄** (gtk4lclintf.inc:1604-1617): 이중연결리스트에서 제거 (UNIX). Non-UNIX 2줄 stub | GTK4와 동일 | ❌ MISS | ✅ GTK4 > Qt5 |
| DCSetAntialiasing | **9줄** (gtk4object.inc:798-806): `IsValidDC` 검사 → `TGtk4DeviceContext.set_antialiasing(AEnabled)` Cairo 안티앨리어싱 | 유사 구현 | 유사 구현 | 완전 |
| SetCursorPos | **56줄** (gtk4winapi.inc:4809-4864): 동적 X11 `XWarpPointer` (`libX11.so.6` dlopen). Wayland는 False 반환 (보안 정책) | X11 `XWarpPointer` 직접 | 플랫폼 네이티브 | ⚠️ X11 전용 |

**RawImage 함수 상세:**

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | GTK4 품질 |
|--------|----------|----------|---------|----------|
| RawImage_CreateBitmaps | **333줄** (gtk4lclintf.inc:201-533): 1bpp→24bpp→32bpp 변환, RGB565 16bit 해제, 팔레트 확장, 알파 감지 (all-zero→0xFF 강제). `TGtk4Image.Create` + cairo_format 매핑 | GdkPixbuf 추상화 (160줄) — 단순 | 최소 직접 복사 (57줄) | ✅ GTK4 가장 완전. ⚠️ DataOwner=True 무조건 |
| RawImage_DescriptionFromBitmap | **103줄** (gtk4lclintf.inc:542-644): TGtk4Image → cairo 포맷 매핑 (A1/A8/ARGB32/RGB24/RGB16_565). Gray/RGBA shift 값 완전 기재 | ⚠️ GTK2 **대부분 주석 처리** — 불완전 | QImage 포맷 매핑 | ✅ GTK4 완전 (GTK4 > GTK2) |
| RawImage_DescriptionFromDevice | **31줄** (gtk4lclintf.inc:654-684): `FillStandardDescription` 위임 (GDK visual API 제거됨). 고정 RGBA32 반환 | 동일 위임 (구현 시도 주석 처리) | 동일 위임 | 위임 (전 플랫폼 동일) |
| RawImage_FromBitmap | **167줄** (gtk4lclintf.inc:996-1162): `TGtk4Image.CopyFrom` + `Move` 바이트 복사. 서브렉트 추출, 마스크 데이터 별도 복사. ✅ 주석 코드 정리 완료 (S61) | `RawImage_FromDrawable` 위임 (64줄) | 마스크 반전 로직 포함 (88줄) | 완전 |
| RawImage_FromDevice | **161줄** (gtk4lclintf.inc:1169-1329): `gtk4_widget_paintable_new` → `gdk4_paintable_snapshot` → `gsk4_render_node_draw` → cairo ARGB32 표면. BGRA→RGBA 채널 스왑 포함 | `RawImage_FromDrawable` 위임 (29줄) | QPixmap grab + HiDPI (71줄) | ✅ GTK4 가장 네이티브 |
| RawImage_QueryDescription | **11줄** (gtk4lclintf.inc:980-990): BitsPerPixel 정규화 (>8→32, else 8) + `RawImage_DescriptionFromDrawable` 마스크 헬퍼 | 복잡한 플래그 처리 (42줄) | GTK4와 유사 (9줄) | 완전 |

**LCLIntf 품질 요약** (Round 26 — 34메서드 전체 file:line 기재 완료):
- **GTK4 강점**: 이벤트 핸들러 3종(Qt5 STUB), RawImage_CreateBitmaps 최정교(333줄, :201-533), RawImage_FromDevice 네이티브 GskRenderNode(161줄, :1169-1329), GetDesignerDC 구현(GTK2 MISS)
- **GTK4 약점**: SetRubberBandRect/DrawDefaultDockImage Wayland 위치 제한, RawImage_FromBitmap 불완전(70+줄 주석), SetComboMinDropDownSize 부분적, SetCursorPos X11 전용
- **GTK4 > Qt5**: AddPipeEventHandler, AddProcessEventHandler, RemoveProcessEventHandler (Qt5 STUB/MISS)
- **GTK4 > GTK2**: RawImage_DescriptionFromBitmap (GTK2 주석 처리), AskUser 간결성(13줄 vs 233줄), GetDesignerDC(GTK2 MISS), IsDesignerDC(GTK2 MISS)

---

## 18. WinAPI Function Declarations (gtk4winapih.inc)

Comparison of WinAPI functions across platforms. Only methods with differences shown (~200+ functions are identical across all three).

| Method | GTK4 | GTK2 | Qt5 | Notes |
|--------|------|------|-----|-------|
| ClipboardFormatNeedsNullByte | Y | Y | N | |
| CreatePatternBrush | Y | N | Y | |
| CreateRoundRectRgn | Y | N | N | GTK4 unique |
| DestroyCursor | Y | Y | N | |
| EqualRgn | Y | Y | N | |
| GetDesignerDC | Y | Y | N | |
| GetDpiForMonitor | Y | N | N | GTK4 unique |
| GetFontLanguageInfo | Y | Y | N | |
| GetTextExtentExPoint | **N** | Y | N | GTK2 only |
| GradientFill | Y | N | Y | |
| InitStockFont | Y | N | Y | |
| IntersectClipRect | Y | N | Y | |
| PaintRgn | Y | Y | N | |
| RadialArc | Y | Y | N | |
| RadialChord | Y | Y | N | |
| RectInRegion | Y | Y | N | |
| RectVisible | Y | Y | N | |
| RegroupMenuItem | Y | Y | N | |
| RemoveProp | Y | Y | N | |
| SetMenu | N | N | **Y** | Qt5 only |
| SetRectRgn | Y | Y | N | |
| SetSysColors | Y | Y | N | |
| SetTextCharacterExtra | Y | Y | N | |
| SetWindowRgn | Y | Y | Y | |

### WinAPI Summary

| Metric | Count |
|--------|-------|
| GTK4 unique (not in GTK2 or Qt5) | 2 (CreateRoundRectRgn, GetDpiForMonitor) |
| GTK4 extras vs GTK2 | 4 (CreatePatternBrush, GradientFill, InitStockFont, IntersectClipRect) |
| GTK4 extras vs Qt5 | 17 (ClipboardFormatNeedsNullByte, DestroyCursor, EqualRgn, etc.) |
| Missing vs GTK2 | 1 (GetTextExtentExPoint) |
| Missing vs Qt5 | 1 (SetMenu) |

### WinAPI / LCLIntf Function Counts

| Category | GTK4 | GTK2 | Qt5 |
|----------|------|------|-----|
| WinAPI functions (winapih.inc) | **196** | 185 | 175 |
| LCLIntf functions (lclintfh.inc) | **35** | 35 | 33 |
| **Total** | **231** | **220** | **208** |

**Conclusion**: GTK4 WinAPI coverage is excellent — most implementations of any platform. Only 1 gap vs GTK2 (`GetTextExtentExPoint`) and 1 vs Qt5 (`SetMenu`). Neither is critical. **Round 27 품질 검증**: 핵심 함수 15개 중 14개 완전(93%), SetWindowRgn GTK4 API 제거로 stub 회귀 발견.

**GTK4 WinAPI 품질 이슈 (Round 16, 코드 검증 완료):**
- **StretchMaskBlt ROP 코드**: Rop 파라미터를 받지만 **완전 무시** (gtk4winapi.inc:5570-5673). 펜 모드는 pmCopy(OVER)/pmXor(XOR) 2개만 구현, 11개 모드 주석 처리 (gtk4objects.pas:1634-1645). GTK2는 StretchCopyArea에 ROP 전달
- ~~**SaveDC/RestoreDC**: 필드 존재(gtk4objects.pas:213 SaveDCCount)하나 구현 없음~~ → ✅ **실제 구현됨**: SaveDC(gtk4winapi.inc:4587-4598) cairo_save + 카운터, RestoreDC(gtk4winapi.inc:4550-4576) cairo_restore + 음수 인덱스 지원. GTK2와 동등
- **GetCharABCWidths**: stub — `Result := False` (gtk4winapi.inc:2487-2492). Win32 전용, GTK2/Qt5도 동일
- ~~**Brush create_stipple(w,w)**~~: ✅ **수정됨 (Session 61)** — `create_stipple(PByte(pat_buf),w,h)`로 교정
- 🔴 **pmNotXor BUG**: XOR과 동일 매핑 `CAIRO_OPERATOR_XOR` (gtk4objects.pas:1632-1633) — 시맨틱적 오류. Cairo에 직접적 NotXor 연산자 없음
- **Clip rect 반올림**: Trunc(좌상단)/Ceil(우하단) 혼용 (gtk4widgets.pas:2961-2964) — 올바른 방식은 `width=Ceil(cx2-cx1)` 사용
- ~~🔴 **마우스 modifier 반전 BUG**~~: ✅ **수정됨 (Session 61)** — GDK_BUTTON2_MASK→ssMiddle, GDK_BUTTON3_MASK→ssRight로 올바르게 교정 (gtk4procs.pas:837-841)
- ~~**RGN_DIFF**~~: ✅ **오보정 (S61)** — 실제 구현됨 (gtk4winapi.inc:2019-2051, CombineRGN 경유)
- **ROP2 미적용**: GetROP2/SetROP2 존재하나 R2_COPYPEN 초기화 후 실제 드로잉에 반영 안됨
- **삼각형 GradientFill**: `Result := False` (gtk4winapi.inc:2194) — GTK2/Qt5도 동일

#### WinAPI 품질 이슈 구현 수준 상세

| 이슈 | GTK4 실제 코드 | GTK2 비교 | 심각도 |
|------|--------------|----------|--------|
| StretchMaskBlt ROP | Rop:DWORD 파라미터 수신 후 **미사용** (gtk4winapi.inc:5570-5673). cairo_mask_surface 고정 사용 | `StretchCopyArea`에 Rop 전달 → 처리됨 | ⚠️ 중간 |
| SaveDC | `cairo_save(Ctx.pcr)` + `SaveDCCount += 1` (gtk4winapi.inc:4587-4598) | 유사 cairo_save 구현 (gtk2winapi.inc:2764-2819) | ✅ 완전 |
| RestoreDC | 음수 인덱스 지원 (`SaveDCCount + SavedDC`), while 루프로 다단계 복원 (gtk4winapi.inc:4550-4576) | 유사 구현 | ✅ 완전 |
| GetCharABCWidths | `Result := False` (gtk4winapi.inc:2487-2492) — Win32 전용 | GTK2도 동일 stub | ℹ️ 낮음 |
| create_stipple | `create_stipple(PByte(pat_buf), w, w)` — 2번째 파라미터 w (gtk4objects.pas:1486). 함수 시그니처는 `(stipple_data, width, height)` | GTK2에 직접 동등 없음 | ⚠️ 낮음 (해치 패턴 정방형) |
| pmNotXor | `CAIRO_OPERATOR_XOR` — pmXor와 동일 매핑 (gtk4objects.pas:1632-1633) | GTK2는 `GDK_EQUIV` 사용 가능. Cairo는 비트 ROP 미지원 → **플랫폼 한계** | ⚠️ 한계 |
| Clip rect | `Trunc(cx1)`, `Ceil(cx2)-Trunc(cx1)` (gtk4widgets.pas:2961-2964). 혼합 사용이나 결과적으로 올바른 확장 방향 | GTK2 유사 구조 | ⚠️ 낮음 |
| ~~마우스 modifier~~ | ~~`GDK_BUTTON2_MASK→ssRight`(❌), `GDK_BUTTON3_MASK→ssMiddle`(❌)~~ | ✅ **수정됨 (Session 61)**: BUTTON2→ssMiddle, BUTTON3→ssRight | ~~🔴 BUG~~ ✅ |
| RGN_DIFF | ExtSelectClipRgn에서 `RGN_DIFF` 분기 비어있음 (gtk4winapi.inc:2021) | GTK2 구현 확인 필요 | ⚠️ 중간 |
| ROP2 | `GetROP2`/`SetROP2` API 존재, `R2_COPYPEN` 기본값 설정. **실제 드로잉 연산에 미반영** | GTK2도 유사 제한 | ⚠️ 중간 |
| GradientFill 삼각형 | `GRADIENT_FILL_TRIANGLE` → `Result := False` (gtk4winapi.inc:2194) | GTK2/Qt5도 동일 미구현 | ℹ️ 낮음 (전 플랫폼 동일) |
| ~~펜 모드 11종~~ | ~~pmNop~pmNotMask 11개 모드 주석 처리~~ **수정됨**: pmNop→CAIRO_OPERATOR_DEST 추가. 나머지 10종 Cairo 한계 (GTK3도 동일) | ✅ 플랫폼 한계 | ~~⚠️ 중간~~ ✅ |

#### WinAPI 차별 메서드 구현 수준 상세 (Round 27)

§18 상태표에서 플랫폼 간 차이가 있는 메서드 25개의 실구현 품질:

| Method | GTK4 구현 | GTK2 구현 | Qt5 구현 | 품질 |
|--------|----------|----------|---------|------|
| CreateRoundRectRgn | **4줄** (gtk4winapi.inc:691-694): `TGtk4Region.Create()` 위임 — 모서리 둥근 사각형 리전 | ❌ 없음 | ❌ 없음 | ✅ GTK4 유니크 |
| GetDpiForMonitor | **30줄** (gtk4winapi.inc:2877-2906): `gtk4_display_get_monitors` → `g_list_model_get_item` → `gdk_monitor_get_scale_factor` → DPI=96×scale. try/finally+g_object_unref | ❌ 없음 | ❌ 없음 | ✅ GTK4 유니크 — 완전 |
| CreatePatternBrush | **38줄** (gtk4winapi.inc:552-589): `cairo_image_surface_create` + `gdk_cairo_set_source_pixbuf` → `cairo_pattern_create_for_surface(CAIRO_EXTEND_REPEAT)` 타일 패턴 | ❌ 없음 | `QPainter` 패턴 브러시 | ✅ GTK4 > GTK2 |
| GradientFill | **119줄** (gtk4winapi.inc:2176-2294): `cairo_pattern_create_linear` + `cairo_pattern_add_color_stop_rgb` — H/V 그래디언트 완전. ⚠️ `GRADIENT_FILL_TRIANGLE → False` | ❌ 없음 | 유사 구현 | ✅ GTK4 > GTK2 (삼각형 미구현은 전 플랫폼 동일) |
| InitStockFont | **69줄** (gtk4winapi.inc:3907-3975): `gtk_settings_get_default` → `'gtk-font-name'` → `pango_font_description_from_string` → family/size/weight/style 추출. sfMenu→clMenuText, sfHint→clInfoText 색상 매핑 | ❌ 없음 | 유사 구현 | ✅ GTK4 > GTK2 — 완전 |
| IntersectClipRect | **12줄** (gtk4winapi.inc:1879-1890): `CreateRectRgn` + `GetClipRGN` + `CombineRgn(RGN_AND)` + `SelectClipRGN` — LCL 리전 추상화 사용 | ❌ 없음 | 유사 구현 | ✅ GTK4 > GTK2 |
| ClipboardFormatNeedsNullByte | **5줄** (gtk4winapi.inc:131-135): `Result := False` — GTK4 클립보드는 null-byte 불필요 | 동일 stub | ❌ 없음 | stub (동작 정확) |
| DestroyCursor | **7줄** (gtk4winapi.inc:920-926): `g_object_unref(PGdkCursor(Handle))` — GObject 참조 해제 | `gdk_cursor_destroy` | ❌ 없음 | 완전 |
| EqualRgn | **9줄** (gtk4winapi.inc:1869-1877): 포인터 비교 → GDI 검증 → `cairo_region_equal()` 3단 비교 | 유사 구현 | ❌ 없음 | 완전 |
| GetFontLanguageInfo | **23줄** (gtk4winapi.inc:2956-2978): Pango 레이아웃 'm' vs #0'm' 너비 비교 → GCP_DBCS 플래그 반환 (DBCS 폰트 감지) | 유사 구현 | ❌ 없음 | 완전 |
| PaintRgn | **38줄** (gtk4winapi.inc:4227-4264): `cairo_region_num_rectangles` → 루프: `cairo_region_get_rectangle` → `cairo_rectangle` + `cairo_fill`. try/finally | 유사 구현 | ❌ 없음 | 완전 |
| RadialArc | **6줄** (gtk4winapi.inc:4381-4386): `inherited RadialArc` 위임 — 라디알→앵글 좌표 변환 | 유사 구현 | ❌ 없음 | 위임 |
| RadialChord | **6줄** (gtk4winapi.inc:4388-4393): `inherited RadialChord` 위임 | 유사 구현 | ❌ 없음 | 위임 |
| RectInRegion | **6줄** (gtk4winapi.inc:4417-4422): `TGtk4Region.ContainsRect()` 위임 | 유사 구현 | ❌ 없음 | 완전 |
| RectVisible | **22줄** (gtk4winapi.inc:4424-4445): `cairo_region_create_rectangle` + `cairo_region_contains_rectangle`. GTK4 `gdk_window_get_visible_region` 제거 대응 | 유사 구현 | ❌ 없음 | 완전 — GTK4 API 변경 대응 |
| RegroupMenuItem | **9줄** (gtk4winapi.inc:4486-4494): stub `Result := True` — GTK4에서 라디오 그룹은 GAction stateful 레벨에서 처리 | 유사 stub | ❌ 없음 | stub (플랫폼 구조 차이) |
| RemoveProp | **21줄** (gtk4winapi.inc:4528-4548): `g_object_set_data(nil)` — Widget + ContainerWidget 양쪽에서 프로퍼티 제거 | 유사 구현 | ❌ 없음 | 완전 |
| SetRectRgn | **26줄** (gtk4winapi.inc:4969-4994): `cairo_region_destroy` + `cairo_region_create_rectangle` — 기존 리전 교체 | 유사 구현 | ❌ 없음 | 완전 |
| SetSysColors | **14줄** (gtk4winapi.inc:5252-5265): `SysColorMap[]` 배열 직접 업데이트 루프 | 유사 구현 | ❌ 없음 | 완전 |
| SetTextCharacterExtra | **7줄** (gtk4winapi.inc:5267-5273): stub `Result := 0` — Pango 폰트 속성으로 관리, 직접 제어 불가 | 유사 stub | ❌ 없음 | stub (플랫폼 제한) |
| SetWindowRgn | **7줄** (gtk4winapi.inc:5453-5459): stub `Result := 0` — GTK4에서 `gtk_widget_shape_combine_region` **제거됨** | `gdk_window_shape_combine_region` | 유사 구현 | ⚠️ 회귀 (GTK4 API 제거) |
| GetDesignerDC | **6줄** (gtk4winapi.inc:2705-2710): `GetDC(WindowHandle)` 위임 | ❌ 없음 | 디자이너 전용 DC | ✅ GTK4 > GTK2 |
| StretchMaskBlt | **104줄** (gtk4winapi.inc:5570-5673): `cairo_mask_surface` + pixbuf→A8 마스크 변환 + cairo 스트레칭. ⚠️ **ROP 파라미터 무시** | `StretchCopyArea`에 Rop 전달 | 유사 구현 | ⚠️ ROP 미적용 |
| ExtSelectClipRgn | **97줄** (gtk4winapi.inc:1957-2053): 5모드 지원 (COPY/OR/XOR/AND/DIFF). `cairo_clip_extents` (GTK4 API 변경). ✅ RGN_DIFF 완전 구현 (S61 확인, S66 데드코드 정리) | 유사 구현 | 유사 구현 | 완전 |
| GetROP2/SetROP2 | **6+7줄** (gtk4winapi.inc:3244-3249/4996-5002): `TGtk4DeviceContext.Rop2` 읽기/쓰기만 — **실제 드로잉에 미반영** | GTK2도 유사 제한 | 유사 구현 | ⚠️ 비기능적 |

#### WinAPI 핵심 함수 품질 검증 (Round 27)

§18 상태표에서 전 플랫폼 공통(Y/Y/Y)인 핵심 WinAPI 함수 15개의 GTK4 실구현 품질:

| Method | GTK4 구현 | 줄 수 | 품질 |
|--------|----------|-------|------|
| BitBlt | gtk4winapi.inc:71-83 — `StretchBlt` 위임 (동일 크기) | 13줄 | 위임 (정상) |
| StretchBlt | gtk4winapi.inc:5561-5673 — `StretchMaskBlt` 위임, cairo 표면+픽스버프 렌더링, 스트레칭 매트릭스 | 113줄 | ✅ 완전 |
| SelectObject | gtk4winapi.inc:4670-4679 — `TGtk4ContextObject.Select()` 위임, 이전 GDI 객체 반환 | 10줄 | ✅ 완전 |
| DeleteObject | gtk4winapi.inc:887-907 — GDI 검증 + `Shared` 플래그 보호 + `TGtk4ContextObject.Free` | 21줄 | ✅ 완전 |
| CreateBitmap | gtk4winapi.inc:483-527 — cairo 포맷 선택(1/8/24/32bpp) + 행 스트라이드 DWORD 정렬 + `TGtk4Image.Create` | 45줄 | ✅ 완전 |
| CreateCompatibleBitmap | gtk4winapi.inc:640-679 — DC 깊이/포맷 추출 + cairo 포맷 매핑 + 32bit 폴백 (GTK4 `gdk_window_get_visual` 제거) | 40줄 | ✅ 완전 |
| CreateCompatibleDC | gtk4winapi.inc:681-684 — `TGtk4DeviceContext.Create(nil)` 오프스크린 DC | 4줄 | ✅ 완전 |
| DeleteDC | gtk4winapi.inc:874-885 — DC 검증 + `TGtk4DeviceContext.Free` | 12줄 | ✅ 완전 |
| GetDC | gtk4winapi.inc:2659-2671 — 위젯 컨텍스트 → `Gtk4DefaultContext` → `Gtk4ScreenContext` 3단 폴백 | 13줄 | ✅ 완전 |
| ReleaseDC | gtk4winapi.inc:4517-4526 — DC 검증 + `CanRelease` 플래그 확인 (영구 DC 보호) | 10줄 | ✅ 완전 |
| DCGetPixel | gtk4object.inc:774-780 — `TGtk4DeviceContext.getPixel(X,Y)` 위임. ~~Bug #23~~ ✅ S61 수정 | 7줄 | ✅ 완전 |
| DCSetPixel | gtk4object.inc:782-786 — `TGtk4DeviceContext.drawPixel(X,Y,Color)` 위임 | 5줄 | ✅ 완전 |
| CreateFontIndirectEx | gtk4winapi.inc:702-706 — `TGtk4Font.Create(LogFont, LongFontName)` | 5줄 | ✅ 완전 |
| GetTextMetrics | gtk4winapi.inc:3651-3731 — Pango font metrics 캐싱 + ascent/descent/height + 문자 너비('M','W') 측정 + weight/style 감지 | 81줄 | ✅ 완전 |
| GetTextExtentPoint | gtk4winapi.inc:3633-3649 — `pango_layout_set_text` + `pango_layout_get_pixel_size` | 17줄 | ✅ 완전 |

**핵심 함수 품질 요약**: 15개 중 **15개 완전** (100%). DCGetPixel 메모리 누수 S61 수정. GTK4 DC/비트맵/텍스트 인프라 견고.

---

## 19. WSFactory Class Registrations (gtk4wsfactory.pas)

Comparison of `RegisterWSComponent` calls. Only classes with differences shown.

| LCL Class | GTK4 | GTK2 | Qt5 |
|-----------|------|------|-----|
| TCustomImageListResolution | TGtk4WSCustomImageListResolution | NOT registered | NOT registered |
| TDragImageListResolution | **NOT registered** | TGtk2WSDragImageListResolution | TQtWSDragImageListResolution |
| TCustomControl | TGtk4WSCustomControl | NOT registered | TQtWSCustomControl |
| TSaveDialog | TGtk4WSSaveDialog | NOT registered | NOT registered |
| TSelectDirectoryDialog | TGtk4WSSelectDirectoryDialog | NOT registered | TQtWSSelectDirectoryDialog |
| TCustomSplitter | TGtk4WSCustomSplitter | NOT registered | NOT registered |
| TCustomCheckGroup | TGtk4WSCustomCheckGroup | NOT registered | TQtWSCustomCheckGroup |
| TCheckGroup | TGtk4WSCheckGroup | NOT registered | NOT registered |
| TCustomRadioGroup | TGtk4WSCustomRadioGroup | NOT registered | TQtWSCustomRadioGroup |
| TRadioGroup | TGtk4WSRadioGroup | NOT registered | NOT registered |
| TScrollBox | TGtk4WSScrollBox | NOT registered | TQtWSScrollBox |
| TCustomFrame | TGtk4WSCustomFrame | NOT registered | TQtWSCustomFrame |
| TPreviewFileControl | TGtk4WSPreviewFileControl | TGtk2WSPreviewFileControl | NOT registered |
| TCustomPairSplitter | TGtk4WSCustomPairSplitter | TGtk2WSCustomPairSplitter | NOT registered |
| TCustomRubberBand | NOT registered | NOT registered | TQtWSCustomRubberBand |
| TLazAccessibleObject | **NOT registered** | NOT registered | TQtWSLazAccessibleObject |

### WSFactory Summary

| Metric | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| Total RegisterWSComponent calls | **52** | 47 | 46 |
| Distinct LCL classes registered | **51** | 42 | 45 |
| Missing vs GTK2 | 1 (TDragImageListResolution) | - | - |
| Missing vs Qt5 | 3 (TDragImageListResolution, TCustomRubberBand, TLazAccessibleObject) | - | - |
| Extra vs GTK2 | 12 | - | - |
| Extra vs Qt5 | 8 | - | - |

**Conclusion**: GTK4 has the most WSFactory registrations (52 calls, 51 distinct classes). `TDragImageListResolution` is a true gap (drag-and-drop visual feedback). `TLazAccessibleObject` is a gap for accessibility support (Qt5 only). `TCustomRubberBand` is Qt5-only; GTK4 handles rubber bands via LCLIntf (CreateRubberBand/SetRubberBandRect).

---

## 20. Base WS Virtual Method Coverage

Analysis of which base WS class virtual methods are overridden per platform.

### Coverage by Class (corrected after source verification)

| Base WS Class | GTK2 | GTK4 | Qt5 | Status |
|---------------|------|------|-----|--------|
| TWSWinControl (31 methods) | 71.0% | **93.5%** | 83.9% | GTK4 BEST |
| TWSCustomForm (23 methods) | 39.1% | **87.0%** | 78.3% | GTK4 BEST |
| TWSCustomEdit (21 methods) | 81.0% | **95.2%** | 81.0% | GTK4 BEST |
| TWSCustomMemo (27 methods) | 74.1% | **85.2%** | 29.6% | GTK4 BEST |
| TWSCustomComboBox (20 methods) | 75.0% | **95.0%** | 95.0% | GTK4 = Qt5 |
| TWSCustomListBox (20 methods) | 80.0% | **85.0%** | 85.0% | GTK4 = Qt5 |
| TWSCustomCheckBox (5 methods) | 60.0% | **100%** | 100% | GTK4 = Qt5 |
| TWSButton (4 methods) | 75.0% | **100%** | 50.0% | GTK4 BEST |
| TWSCustomStaticText (4 methods) | 100% | **100%** | 50.0% | GTK4 = GTK2 |
| TWSScrollBar (2 methods) | 100% | 100% | 100% | All complete |
| **AVERAGE** | **75.5%** | **~94%** | **75.5%** | **GTK4 FAR AHEAD** |

### TRUE GAPS (GTK2 or Qt5 override but GTK4 does NOT)

| Class | Method | GTK2 | Qt5 | Impact |
|-------|--------|------|-----|--------|
| ~~TWSWinControl~~ | ~~Repaint~~ | ~~default~~ | ~~IMPL~~ | ✅ **수정됨 (S61)**: `TGtk4WSWinControl.Repaint` 구현 (gtk4wscontrols.pp:396-401) |
| ~~TWSCustomEdit~~ | ~~SetSelText~~ | ~~IMPL~~ | ~~MISS~~ | ✅ **오보정 (S64)**: base class 구현 존재 (wsstdctrls.pp:605-618) |

**TRUE GAPS: 0** — 모든 gap 해결됨.

### GTK4 EXTRAS (GTK4 overrides but neither GTK2 nor Qt5 does)

| Class | Method |
|-------|--------|
| TWSWinControl | AdaptBounds |
| TWSWinControl | DefaultWndHandler |
| TWSWinControl | GetDefaultClientRect |
| TWSWinControl | GetTextLen |
| TWSCustomEdit | SetHideSelection |
| TWSCustomForm | GetDefaultColor |
| TWSCustomForm | SetZPosition |
| TWSButton | SetShortCut |

**Conclusion**: GTK4 has the highest virtual method coverage at ~94%, far ahead of Qt5 (~75.5%) and GTK2 (~75.5%). Only 2 true gaps found, both minor. GTK4 has 8+ extra overrides.

---

## 21. IDE WS Method Usage Analysis

Analysis of what the Lazarus IDE (lazarus/ide/) directly calls from the widgetset layer.

### IDE Direct WinAPI/LCLIntf Calls

| Function | Files | GTK4 Status |
|----------|-------|-------------|
| LCLIntf.ShowWindow | main.pp, customformeditor.pp, sourcefilemanager.pas | **IMPL** |
| LCLIntf.IsIconic | main.pp | **IMPL** |
| LCLIntf.GetTextMetrics | editor_display_options.pas | **IMPL** |

### IDE Direct WidgetSet Calls

| Method | File | GTK4 Status |
|--------|------|-------------|
| WidgetSet.SetDesigning | main.pp | **IMPL** |
| WidgetSet.GetLCLCapability | window_options.pas | **IMPL** |

### LCL WidgetSetClass Dispatch Points

Comprehensive search of lazarus/lcl/include/*.inc found **300+ dispatch calls** across **32 include files** dispatching to **28 unique WS class types**. All dispatched methods are either:
1. **IMPL** in GTK4 (major methods) — covered in Sections 1-16
2. **ALL MISS** across all platforms (base defaults adequate) — documented in each section

**Conclusion**: The Lazarus IDE has **zero WS method gaps** from the GTK4 perspective. All WinAPI, LCLIntf, and WidgetSet methods called by the IDE are fully implemented in GTK4.

---

## Summary: Actionable GTK4 Gaps

### Overall Statistics

| Metric | GTK4 | GTK2 | Qt5 |
|--------|------|------|-----|
| WS Class Method Coverage | **~90%** | ~73% | ~80% |
| WSFactory Registrations (distinct classes) | **51** | 42 | 45 |
| WinAPI Functions | **196** | 185 | 175 |
| LCLIntf Functions | **35** | 35 | 33 |
| WinAPI+LCLIntf Total | **231** | 220 | 208 |
| WinAPI Unique Methods | 2 | 0 | 0 |
| True WS Method Gaps | **2** | many | some |
| ALL MISS Methods (base defaults) | **61** | 61 | 61 |
| WS Source Files | **17** | ~15 | ~16 |
| IDE WS Method Gaps | **0** | - | - |

### Corrections from Source Verification (2026-03-06)

The following items were incorrectly marked in initial analysis and have been corrected:

| Item | Was | Actual | File |
|------|-----|--------|------|
| TrayIcon (Hide/Show/InternalUpdate/GetPosition/ShowBalloonHint) | STUB/MISS | **IMPL** | gtk4wstrayicon.pas (D-Bus SNI) |
| TWSCustomCheckBox.SetAlignment | MISS | **IMPL** | gtk4wsstdctrls.pp:286 |
| TWSCustomCheckBox.ShowHide | MISS | **IMPL** | gtk4wsstdctrls.pp:289 |
| TWSToggleBox.RetrieveState | MISS | **IMPL** | gtk4wsstdctrls.pp:310 |
| TWSToggleBox.SetState | MISS | **IMPL** | gtk4wsstdctrls.pp:311 |
| TWSButton.GetPreferredSize | MISS | **IMPL** | gtk4wsstdctrls.pp:269 |
| TWSCustomStaticText.GetPreferredSize | MISS | **IMPL** | gtk4wsstdctrls.pp:243 |
| TWSCustomMemo (15 methods) | MISS | **IMPL** | gtk4wsstdctrls.pp:193-221 |
| PairSplitter (6 methods) | Not documented | **IMPL** | gtk4wssplitter.pas |
| ExtDlgs (PreviewFileControl) | Not documented | **IMPL** | gtk4wsextdlgs.pp |
| LazAccessibleObject (8 methods) | Not documented | **MISS** | wscontrols.pp (Qt5 only: 3/8 IMPL) |
| WinAPI function count | "~200+" | **196/185/175** | gtk4/gtk2/qt5 winapih.inc |
| TWSCustomUpDown (7 methods) | Not documented | **MISS** (all platforms) | wscomctrls.pp (registration commented out) |
| TWSTaskDialog.Execute | Not documented | **MISS** (all platforms) | wsdialogs.pp (Win32 only) |
| TWSCustomGrid (2 methods) | Not documented | **MISS** (all platforms) | wsgrids.pp (Win32/GTK1 only) |
| WSFactory registration counts | "~35/~31/~32" | **51/42/45** | gtk4/gtk2/qt5 wsfactory.pas |
| WSFactory missing rows | 3 rows missing | **+3 rows** added | TCustomImageListResolution, TRadioGroup, TCheckGroup |
| LCL dispatch: TWSControl (5 methods) | Not documented | **ALL MISS** | GetCanvasScaleFactor, GetConstraints, ConstraintWidth/Height |
| LCL dispatch: TWSWinControl.GetDoubleBuffered | Not documented | **ALL MISS** | Base default adequate |
| LCL dispatch: TWSCustomCalendar.GetCurrentView | Not documented | **ALL MISS** | Base returns cvMonth |
| LCL dispatch: TWSCustomCheckListBox (3 methods) | Not documented | **ALL MISS** | GetCheckWidth, GetHeader, SetHeader |
| LCL dispatch: TWSCustomListView (6 methods) | Not documented | **ALL MISS** | GetNextItem, ItemGetStates, ItemSetPosition, MustHideEditor, InitMultiSelList, UpdateMultiSelList |
| LCL dispatch: TWSCustomTabControl.SetImageList | Not documented | **ALL MISS** | Base default adequate |
| LCL dispatch: TWSTrackBar (2 methods) | Not documented | **ALL MISS** | SetTick, SetTickStyle |
| LCL dispatch: TWSCustomForm (3 methods) | Not documented | **ALL MISS** | SetModalResult, ArrangeIcons, GetDefaultDoubleBuffered |
| LCL dispatch: TWSMenuItem (2 methods) | Not documented | **ALL MISS** | OpenCommand, CloseCommand |
| LCL dispatch: TWSCustomComboBox.FreeItems | Not documented | **ALL MISS** | Base default adequate |
| LCL dispatch: TWSCustomListBox (3 methods) | Not documented | **ALL MISS** | DragStart, FreeStrings, SelectRange |
| LCL dispatch: TWSCustomMemo.FreeStrings | Not documented | **ALL MISS** | Base default adequate |
| LCL dispatch: WSShellCtrls (3 methods) | Not documented | **ALL MISS** | Win32 only (DrawBuiltInIcon, GetBuiltinIconSize, GetBuiltInImageIndex) |
| IDE WS usage analysis | Not analyzed | **0 gaps** | ShowWindow, IsIconic, GetTextMetrics, SetDesigning, GetLCLCapability — all IMPL |
| TWSCustomListView.GetFirstSelected | Not documented | **ALL MISS** | wscomctrls.pp:183 — base returns nil, no platform overrides |
| TWSCustomPairSplitter.GetPosition | Not documented | **ALL MISS** | wspairsplitter.pp — base default, gtk4wssplitter.pas has 6 methods but not GetPosition |
| TWSCustomFloatSpinEdit (4 methods) | Not documented | **ALL MISS** | SetIncrement, SetMinValue, SetMaxValue, SetValueEmpty — all handled by UpdateControl bulk method |
| TWSToolBar (3 methods) | Not counted | **Dead code** | GetButtonCount, InsertToolButton, DeleteToolButton — inside `{$ifdef OldToolbar}` (never defined) |
| TWSCustomCheckBox.GetPreferredSize | **MISS** | **IMPL** | gtk4wsstdctrls.pp:282 — multi-line override missed by initial analysis |
| TWSPairSplitterSide.CreateHandle Qt5 | **MISS** | **IMPL** | qtwspairsplitter.pp — Qt5 has TQtWSPairSplitterSide.CreateHandle override |
| TWSPreviewFileControl.CreateHandle GTK2 | **IMPL** | **MISS** | gtk2wsextdlgs.pp — TGtk2WSPreviewFileControl is empty class (no overrides) |
| TWSCommonDialog.QueryWSEventCapabilities | Not in base table | **ALL MISS** | wsdialogs.pp:56 — virtual at base, overridden only in subclasses (OpenDialog, FontDialog, etc.) |
| TWSLazDeviceAPIs (8 methods) | Not documented | **ALL MISS** | wslazdeviceapis.pas — mobile only, registration commented out in all desktop platforms |
| TWSToggleBox.GetPreferredSize | Not documented | **IMPL** | gtk4wsstdctrls.pp — TGtk4WSToggleBox.GetPreferredSize override (GTK2/Qt5 MISS) |
| SaveDC/RestoreDC | **"미구현"** | ✅ **실제 구현됨** | SaveDC(gtk4winapi.inc:4587-4598) cairo_save+카운터, RestoreDC(4550-4576) 음수인덱스 지원 |
| ~~StretchMaskBlt ROP~~ | ~~"2/16 구현"~~ | ✅ **수정됨 (S61)** | BLACKNESS/WHITENESS/SRCINVERT 3개 ROP 코드 지원 추가. SRCCOPY는 기본 동작 |
| ~~RawImage_FromBitmap~~ | ~~**IMPL***~~ | ✅ **수정됨 (S61)** | ~85줄 주석 코드 삭제 — 구현 완전 |
| GdkKeyToLCLKey 키 매핑 수 | **"22개"** | **304+ 키** | ASCII $00-$FF 통과(256) + 18 case 항목 + F1-F30. "22개" 기재는 오류 — case 항목만 세고 passthrough 미고려 |
| ConstraintsChange 코드량 | **"88줄"** | **~190줄** (3개 프로시저) | ConstraintsChange(89줄) + SetMaxSize(49줄) + ApplyX11SizeHints(53줄). "88줄"은 1개 프로시저만 계산 |
| GetPixel | **IMPL** | ~~🔴 메모리 누수~~ ✅ S61 수정 | gtk4objects.pas:1882-1897 — try/finally + g_object_unref 추가 |
| ~~TRANSPARENT 브러시 모드~~ | ~~미기재~~ | ✅ **수정됨 (S61+S62)** | ~~gtk4objects.pas bkTransparent STUB~~ ApplyBrush 항상 brush color 설정 (S61) + drawText BkMode 가드 (S62) |
| TGtk4Window.CreateWidget | 미기재 | **144줄** | gtk4widgets.pas:10920-11063 — 위젯 트리 조립, 시그널 연결, CSS 초기화 종합 |
| SetFormStyle | "stub 의심" | **플랫폼 제한** | gtk4wsforms.pp:484-502 — 빈 stub 아님, always_on_top/bottom 설정하나 Wayland compositor 무시 가능 |
| Font Quality 매핑 | 미기재 | **5단계 완전** | gtk4objects.pas:897-935 — DEFAULT/DRAFT/PROOF/NONANTIALIASED/CLEARTYPE → CAIRO_ANTIALIAS 매핑 |
| SetRubberBandRect | **IMPL** | **IMPL*** | 크기만 동작, Wayland 위치 설정 불가 |
| RawImage_DescriptionFromBitmap GTK2 | **IMPL** | ⚠️ **대부분 주석 처리** | gtk2lclintf.inc에서 구현 시도 코드 주석 처리됨 |
| LCLIntf.AddPipeEventHandler Qt5 | **IMPL** | **STUB** | Qt5 `// todo` 주석만 — nil 반환 |
| LCLIntf.RemoveProcessEventHandler Qt5 | **IMPL** | **MISS** | Qt5에서 완전 누락 |
| ~~ListView SetSort~~ (GTK2 비교) | ~~**"미구현"**~~ | ✅ **수정됨 (Session 61)**: `ModelNotifyItemsChanged` — ColumnView `g_list_model_items_changed`, TreeView model 재구축 | ~~gtk2wscustomlistview.inc:2353-2371도 queue_draw만~~ **GTK4 > GTK2** |
| ListView BeginUpdate/EndUpdate | **"완전"** | **플래그만** | GTK4/GTK2 모두 InUpdate 플래그만 설정. Qt5만 `setUpdatesEnabled(False/True)` 실제 페인트 억제 |
| Panel.CreateWidget 위젯 타입 | 미기재 | **GtkOverlay** | GTK4=GtkOverlay→[GtkFixed+DrawingArea] (커스텀 드로잉). GTK2=GtkFrame (3D shadow 지원). 위젯 타입 다름 |
| CheckListBox.CreateWidget 아키텍처 | 미기재 | **모던 GtkListView+factory** | 54줄 gtk4widgets.pas:7756-7809. GTK2는 deprecated GtkTreeView+GtkListStore. GTK4 아키텍처 우수 |
| ~~PairSplitter.AddSide 타이포~~ | ~~미기재~~ | ✅ **수정됨 (S61)**: `PGtkWidget`로 교정 | gtk4wssplitter.pas:87 |
| ~~PairSplitter.GetPosition~~ | ~~**"IMPL"**~~ | ✅ **수정됨 (S61)**: `paned^.get_position` override 추가 | gtk4wssplitter.pas:104-112 |
| StatusBar.SetSizeGrip | **"STUB"** | **의도적 no-op** | GTK4에서 GtkStatusBar 위젯 완전 제거. WM이 리사이즈 처리. 아키텍처 변경에 의한 의도적 no-op, 버그 아님 |
| ~~TabControl.GetTabRect~~ | ~~**"완전"**~~ | ✅ **수정됨 (S62)** | gtk4wscomctrls.pp: `gtk4_widget_translate_coordinates`로 교체 — 모든 TabPosition에서 정확 |
| ComboBox.CreateHandle HasEditBox 로직 | **반전됨** | HasEditBox=True→**TGtk4ComboBox**(GtkComboBoxText), False→**TGtk4DropDown**(GtkDropDown) | gtk4wsstdctrls.pp:800-818 |
| WinControl.CanFocus 설명 | **"위젯 상태 미검사"** | 2단계 검사: TGtk4Widget.CanFocus(gtk4widgets.pas:4110) `get_can_focus` + WS 가드(gtk4wscontrols.pp:277-286). GTK2보다 **엄격** (property-only) | gtk4widgets.pas + gtk4wscontrols.pp |
| SpinEdit.GetValue 설명 | **잘못된 메서드명** | `gtk_spin_button_get_value` 호출 (8줄). GTK2의 StrToValue 로케일 변환 누락 | gtk4wsspin.pp:92-99 |
| Dialog ShowModal 코드량 | **미기재** | **34줄** DoExecute 블로킹 루프 (gtk4wsdialogs.pp:1317-1350) | gtk4wsdialogs.pp |
| Dialog FileDialog 래퍼 | **미기재** | WS 6줄 + TGtk4FileDialog.Create **73줄** (gtk4widgets.pas:11977-12049) | gtk4widgets.pas |
| Dialog ColorDialog 래퍼 | **미기재** | **84줄** RGBA float 변환 (gtk4widgets.pas:12226-12309) | gtk4widgets.pas |
| Dialog FontDialog 래퍼 | **미기재** | **115줄** Pango + TGtk4DialogBtnInfo (gtk4widgets.pas:12053-12166) | gtk4widgets.pas |
| SpinEdit.SetReadOnly 비교 | **미기재** | 18줄 (gtk4wsspin.pp:122-139). GTK2는 GtkAdjustment bounds 잠금, GTK4는 editable만 | gtk4wsspin.pp |
| WinControl.PaintTo 코드량 | **미기재** | **45줄** GSK render node 파이프라인 (gtk4wscontrols.pp:395-438). GTK4 아키텍처 우수 | gtk4wscontrols.pp |
| WinControl.AddControl 코드량 | **미기재** | **19줄** (gtk4wscontrols.pp:257-275). GTK2 42줄 대비 간결 — 모던 API | gtk4wscontrols.pp |
| WinControl.ConstraintsChange 코드량 | **"88줄"** | **89줄** (gtk4wscontrols.pp:138-226). GTK2 4줄, Qt5 6줄 대비 **~15배 복잡** — `gtk_window_set_geometry_hints()` 제거에 의한 수동 에뮬레이션 | gtk4wscontrols.pp |
| WinControl.ScrollBy 코드량 | **미기재** | **46줄** (gtk4wscontrols.pp:597-642). GTK2 32줄, Qt5 52줄 — 중간 복잡도, 양축 경계 검사 완전 | gtk4wscontrols.pp |
| WinControl.GetPreferredSize 코드량 | **미기재** | **6줄** (gtk4wscontrols.pp:359-364). GTK4≡Qt5 동일 패턴 (래퍼 위임) | gtk4wscontrols.pp |
| Grids.GetEditorBoundsFromCellRect | **미기재** | **19줄** (gtk4wsgrids.pp:40-58) — GTK2와 **문자 단위 100% 동일 코드**. Qt5에 좌측 인셋 누락 버그 | gtk4wsgrids.pp |
| Panel.GetDefaultColor 코드량 | **미기재** | **10줄** (gtk4wsextctrls.pp:208-217) — **3개 플랫폼 100% 동일 코드** | gtk4wsextctrls.pp |
| RadioGroup/CheckGroup 구현 | **미기재** | 각 **9줄** (gtk4wsextctrls.pp:160-180) + `TGtk4GroupBox` 래퍼 (gtk4widgets.pas:4860-4906, 47줄). GTK2 미구현 | gtk4wsextctrls.pp |
| ~~CheckListBox 데드 코드~~ | ~~미기재~~ | ✅ **수정됨 (S61)** | ~60줄 삭제 + 상수 3개 삭제 |
| ~~PairSplitter.GetSplitterCursor~~ | ~~**미기재**~~ | ✅ **수정됨 (S61)**: `pstVertical→crVsplit` 분기 추가 | gtk4wssplitter.pas:119-127 |
| PairSplitterSide.CreateHandle 래퍼 | **"TGtk4Panel"** | **TGtk4Window** (gtk4wssplitter.pas:52-56, 5줄) | gtk4wssplitter.pas |
| **(R22)** Calendar 품질 테이블 | shallow | **deep** — 8메서드 file:line+줄 수 완전 기재: HitTest 114줄, SetDisplaySettings 30줄, SetMinMaxDate 래퍼 14줄 ClampDate | gtk4wscalendar.pp |
| **(R22)** TrackBar 품질 테이블 | shallow | **deep** — ApplyChanges 20줄+SetTickMarks 40줄+, GetPosition 10줄, SetPosition 18줄, SetOrientation MISS 확인 | gtk4wscomctrls.pp |
| **(R22)** StatusBar 품질 테이블 | shallow | **deep** — RecreatePanels **54줄** (gtk4widgets.pas:4666-4719) GtkLabel 정렬/너비/hexpand, UpdatePanel **59줄** 인플레이스+자동 리빌드, ClearPanels **11줄** | gtk4widgets.pas |
| **(R22)** Forms 품질 테이블 | shallow | **deep** — 17메서드 file:line 완전: ShowHide **100줄** modal chain+present/minimize/withdraw, CreateWidget **144줄**, SetAllowDropFiles **32줄** GdkFileList→WM_DROPFILES, SetBounds 래퍼 **46줄** Wayland 제한 | gtk4wsforms.pp+gtk4widgets.pas |
| **(R22)** CheckBox 품질 테이블 | shallow | **deep** — 6메서드: CreateHandle 7줄, RetrieveState 8줄 inconsistent→cbGrayed, SetState 12줄 tri-state, SetAlignment 8줄, ShowHide 10줄, SetShortCut 5줄 | gtk4wsstdctrls.pp |
| **(R22)** GroupBox 품질 테이블 | shallow | **deep** — CreateHandle 7줄 WS+래퍼 20줄, GetDefaultClientRect 15줄 하드코딩, SetText 래퍼 15줄 | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R22)** RadioButton 품질 테이블 | shallow | **deep** — CreateWidget **48줄** join_group: 부모 컨테이너 자식 순회→첫 라디오→`gtk4_check_button_set_group` (GtkRadioButton 제거) | gtk4widgets.pas |
| **(R22)** StaticText 품질 테이블 | shallow | **deep** — SetStaticBorderStyle CSS border 에뮬레이션 (sbsSunken→`border:1px inset`), SetAlignment `gtk_label_set_xalign` | gtk4wsstdctrls.pp |
| **(R22)** ToggleBox 품질 테이블 | shallow | **deep** — 5메서드 file:line 완전 기재 | gtk4wsstdctrls.pp |
| **(R22)** ListBox 품질 테이블 | shallow | **deep** — 14메서드 file:line+줄 수: GetIndexAtXY 24줄 계산식, GetItemRect 28줄, SetSelectionMode 런타임 전환 불가 | gtk4wsstdctrls.pp |
| **(R22)** ScrollBar 품질 테이블 | shallow | **deep** — CreateHandle 10줄 WS+래퍼 35줄, SetParams 18줄 gtk_adjustment_configure | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R23)** Page 품질 테이블 | shallow | **deep** — 7메서드: SetFont **49줄** TFont→CSS 변환, GetDefaultClientRect **17줄**, SetBounds **6줄** LCL 바운드 의도적 무시, UpdateProperties 6줄 | gtk4wscomctrls.pp |
| **(R23)** HintWindow 품질 테이블 | shallow | **deep** — CreateHandle 5줄 WS + CreateWidget **24줄** (gtk4_window_new, GTK_WINDOW_POPUP 제거 대응), ShowHide 7줄, InitializeWidget 6줄 | gtk4wsforms.pp+gtk4widgets.pas |
| **(R23)** Edit 품질 테이블 | shallow | **deep** — 22메서드 file:line+줄 수: SetCharCase **42줄** InsertText 콜백 (시그널 차단→대문자 변환→재삽입), SetNumbersOnly **8줄** 이중 검증, SetHideSelection **10줄** CSS, Cut/Copy/Paste 각 5줄, Undo **7줄** activate_action, GetCanUndo 7줄, 전체 Get/Set 메서드 완전 기재 | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R23)** Memo 품질 테이블 | shallow | **deep** — 23메서드 file:line+줄 수: CreateWidget **56줄** GtkTextView+ScrolledWindow+CSS, AppendText **12줄** get_buffer→get_end_iter→insert, GetCanUndo/Undo **GTK4 네이티브** (gtk4_text_buffer_get_can_undo/undo), GetCaretPos **15줄** line+offset, SetScrollbars 17줄, SetWordWrap 10줄, SetWantTabs 5줄 | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R23)** Button 품질 테이블 | shallow | **deep** — 4메서드: CreateHandle **14줄** WS + setText **29줄** 멀티라인+아이콘 GtkBox 래퍼, GetPreferredSize 7줄, SetDefault **6줄** + 래퍼 5줄 CSS default class, SetShortCut 7줄 | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R24)** ListView 품질 테이블 | shallow | **deep** — **51메서드** file:line+줄 수: CreateWidget **131줄** 멀티뷰 초기화, ColumnGetWidth 래퍼 **148줄** (최대 래퍼), SetPropertyInternal **117줄** case문, ColumnInsert 래퍼 **91줄** factory+시그널, ItemGetState 래퍼 **67줄** 상태머신, GetVisibleRowCount **62줄** 뷰포트 계산, ItemDisplayRect **58줄** Gtk4_FindItemWidget | gtk4wscomctrls.pp+gtk4widgets.pas |
| **(R24)** TabControl 품질 테이블 | 부분 | **deep** — 10메서드 추가: GetDefaultClientRect **27줄**, GetDesignInteractive **12줄**, AddPage **17줄**, MovePage **10줄**, SetTabCaption 10줄, SetTabPosition 9줄, ShowTabs 9줄, UpdateProperties 14줄 | gtk4wscomctrls.pp |
| **(R24)** WinControl 품질 테이블 | shallow | **deep** — **19메서드** file:line+줄 수: SetBounds 래퍼 **69줄** measure+allocate, GetPreferredSize 래퍼 **54줄** GType 캐싱, PaintTo **44줄** GSK, SetChildZPosition **38줄**, SetFont 래퍼 **36줄** CSS, AddControl 19줄+래퍼 60줄, Invalidate 9줄+래퍼 16줄 | gtk4wscontrols.pp+gtk4widgets.pas |
| **(R24)** MenuItem 품질 테이블 | shallow | **deep** — **11메서드** file:line+줄 수: Create 래퍼 **63줄** GAction+GMenuItem 구성, SetShortCut **51줄** 3단계 변환, Destroy 래퍼 **30줄** ref 정리, UpdateMenuIcon **26줄** pixbuf→PNG→GBytesIcon, AttachMenu **18줄**, SetCheck 래퍼 **12줄** Lock 재진입방지 | gtk4wsmenus.pp+gtk4widgets.pas |
| **(R24)** Menu+PopupMenu 품질 테이블 | shallow | **deep** — Menu: CreateHandle **21줄** PopoverMenuBar, SetBiDiMode **16줄**. PopupMenu: Popup **67줄** 중첩 g_main_loop, CreateHandle 4줄+래퍼 7줄 | gtk4wsmenus.pp+gtk4widgets.pas |
| **(R24)** SpinEdit 품질 테이블 | 부분 | **deep** — 10메서드 추가: CreateHandle 8줄, GetPreferredSize 8줄, GetSelStart/Length 각 8줄, SetSelStart/Length 각 9줄, SetAlignment **7줄** xalign, SetEditorEnabled **13줄** ReadOnly 가드, UpdateControl **33줄** 프로퍼티 동기화 | gtk4wsspin.pp |
| **(R24)** ComboBox 품질 테이블 | shallow | **deep** — **12메서드** file:line+줄 수: CreateHandle **19줄** 듀얼 위젯 (GtkComboBoxText/GtkDropDown), GetItemHeight **28줄** Pango ascent+descent, SetItemHeight **17줄** CSS min-height, SetItemIndex **17줄** 타입 분기, GetItems **15줄** GtkListItemLCLListTag, SetReadOnly 11줄, SetTextHint 11줄 GTK4>GTK2 | gtk4wsstdctrls.pp |
| **(R25)** ComboBox 선택/길이 메서드 | 품질 테이블 누락 | **deep** — **6메서드 추가**: GetSelStart **16줄** (841-856) GtkEditable.get_selection_bounds, GetSelLength **14줄** (858-871) AEnd-AStart, GetMaxLength **12줄** (885-896) GtkEntry.get_max_length, SetSelStart **11줄** (935-945) set_position, SetSelLength **13줄** (947-959) select_region, SetMaxLength **11줄** (923-933) — 전부 **DropDown 타입 가드** 포함 | gtk4wsstdctrls.pp |
| **(R25)** Dialog QueryWSEventCap 3건 | 품질 테이블 누락 | **deep** — SelectDir/ColorDialog/FontDialog 각 **5줄** `[cdecWSPerformsDoShow]` (gtk4wsdialogs.pp:1374-1410). 3플랫폼 동일 프로토콜 | gtk4wsdialogs.pp |
| **(R25)** TGtk4WSControl 클래스 | IMPL (상태표) | **빈 클래스** — GetDefaultColor/AddControl 미override. 서브클래스(Panel/Form/ButtonControl)에서 각각 재정의. AddControl은 TWSWinControl에서 실구현 | gtk4wscontrols.pp:65-68 |
| **(R26)** §17 LCLIntf 품질 테이블 file:line | 설명만 (file:line 없음) | **34메서드 전체** file:line+줄 수 완전 기재. AddEventHandler 23줄(1465-1487), AskUser 13줄(1399-1411), CreateRubberBand 23줄(17-39), FontIsMonoSpace 23줄(131-153), GetControlConstraints 47줄(1339-1385), RadialPie 14줄(177-190), SetComboMinDropDownSize 20줄(1430-1449) 등 | gtk4lclintf.inc, gtk4object.inc, gtk4winapi.inc |
| **(R26)** RawImage 6메서드 file:line | 줄 수만 (일부) | **전체 file:line 기재**: CreateBitmaps 333줄(201-533), DescFromBitmap 103줄(542-644), DescFromDevice 31줄(654-684), FromBitmap 167줄(996-1162), FromDevice 161줄(1169-1329), QueryDesc 11줄(980-990) | gtk4lclintf.inc |
| **(R31)** §4 ToolBar 래퍼 심층 분석 | "최소 인터페이스" | WS 8줄 + **래퍼 50줄**: CreateWidget 23줄 (GtkOverlay+GtkFixed+GtkDrawingArea 3-depth), ButtonClicked 콜백, ClearGlyphs, Destroy. GTK4에서 GtkToolbar 제거 대응 | gtk4wscomctrls.pp+gtk4widgets.pas:5982-6027 |
| **(R31)** §4 TrackBar TGtk4Range 분석 | SetTickMarks "40줄+" | **TGtk4Range 부모 클래스 95줄** (5395-5489): CreateWidget 15줄, ValueChanged 콜백 12줄, Position 프로퍼티 8줄. **SetTickMarks 44줄** (5468-5511) 정확 측정. GTK2에 없는 공통 추상화 | gtk4widgets.pas:5395-5511 |
| **(R31)** §8 Forms 크로스플랫폼 비교 | 개별 메서드 기술 | **비교표 추가**: SetFormStyle CSS vs API, SetAllowDropFiles GTK4=32줄/GTK2=8줄 (4배), CloseModal GTK4>GTK2, SetBorderIcons GTK4<GTK2, ShowHide 코드량 비교 | gtk4wsforms.pp |
| **(R31)** §13 Edit 크로스플랫폼 비교 | 개별 메서드 기술 | **비교표 추가**: Copy LCL vs API 접근법, GetCanUndo 정밀도 (GTK4 부정확/Qt5 정확), Undo GTK4 유일 구현, SetHideSelection GTK4 고유, SetNumbersOnly 이중 검증 | gtk4wsstdctrls.pp+gtk4widgets.pas |
| **(R31)** §8 HintWindow 래퍼 분석 | CreateWidget 줄 수만 | **TGtk4HintWindow 래퍼 총 30줄** 상세: CreateWidget 24줄 + InitializeWidget 6줄. GTK2(GTK_WINDOW_POPUP)/Qt5(힌트 플래그) 비교 추가 | gtk4widgets.pas:11734-11766 |
| **(R31)** §12 SpinEdit SetAlignment 비교 | "✅ GTK4 > GTK2" | **GTK2 MISS 이유**: GtkSpinButton이 xalign API 미지원 (GTK2 구조적 제한). Qt5는 QAlignment enum 매핑 (7줄). GTK4는 GtkEntry 상속으로 xalign 직접 설정 가능 | gtk4wsspin.pp:141-147 |
| **(R32)** SetMinMaxDate 라인 정정 | 5685-5698 | **5699-5712** — ClampDate 프로시저 끝 이후. 14줄 시프트 | gtk4widgets.pas |
| **(R32)** SetAllowDropFiles 라인 정정 | 443-474 (68줄) | **405-436 (32줄)** — 38줄 시프트. 68줄 기재는 오류 | gtk4wsforms.pp |
| **(R32)** Forms CreateHandle 라인 정정 | 180-189 (CreateHandle) | **191-200 (CreateHandle)** — 180-189는 GetDefaultClientRect. 라벨 혼동 | gtk4wsforms.pp |
| **(R32)** §4/§5/§6/§11 비교표 추가 | 개별 메서드 기술 | **4개 크로스플랫폼 코드 깊이 비교표** 신규: ComCtrls (ListView/StatusBar), WinControl (SetBounds/PaintTo/SetFont/GetPreferredSize), Dialogs (ShowModal/FileDialog/ColorDialog/FontDialog), Menus (MenuItem/RebuildMenuModel/PopupMenu) | 전체 |
| **(R32)** §23b-13 GtkSettings | 미문서화 | **이미 바인딩 완료** 확인 — lazgtk4.pas TGtkSettings + get_default + g_object_get_property 3곳 사용 중. 추가 바인딩 불필요 | lazgtk4.pas, gtk4winapi.inc, gtk4object.inc |
| **(R32)** §23b-14 GtkExpression | 미문서화 | **최소 바인딩** (PGtkExpression=Pointer). 생성자/평가 함수 미바인딩. ~12개 바인딩 Phase 2 대기 | lazgtk4_compat.pas |
| **(R32)** 버그 4건 재검증 | S56-60 영향 가능성 | Bug#1/#4/#10/#23 **전부 미수정 확인** — S56-60 수정과 독립 영역. 34건 중 1건만 수정 (Bug#29) | gtk4procs.pas, gtk4objects.pas, gtk4lclintf.inc |
| **(R32)** Session 55 패리티 의미 정리 | "full functional parity" | **API 커버리지 패리티** ≠ **기능 동작 패리티**. DnD/SetSort/IMContext/Print은 메서드 존재하나 기능 미동작. §23c 우선순위표는 기능 관점에서 유효 | §23c |
| **(R26)** GetDesignerDC 정정 | ❌ MISS (오류) | **IMPL** — gtk4winapi.inc:2705-2710 발견. `GetDC(WindowHandle)` 위임 6줄. GTK4>GTK2 (GTK2도 MISS) | gtk4winapi.inc |
| **(R26)** DCSetAntialiasing/SetCursorPos 추가 | 품질 테이블 미기재 | **DCSetAntialiasing** 9줄 (gtk4object.inc:798-806) cairo 안티앨리어싱, **SetCursorPos** 56줄 (gtk4winapi.inc:4809-4864) X11 XWarpPointer dlopen | gtk4object.inc, gtk4winapi.inc |
| **(R27)** §18 WinAPI 차별 메서드 품질 | 상태표 Y/N만 (품질 미기재) | **25메서드** file:line+줄 수+API 완전 기재. GTK4 유니크 2개: CreateRoundRectRgn 4줄(691), GetDpiForMonitor **30줄**(2877). GTK4>GTK2 4개: CreatePatternBrush **38줄**(552) cairo 타일, GradientFill **119줄**(2176) linear gradient, InitStockFont **69줄**(3907) Pango 시스템 폰트, IntersectClipRect 12줄(1879) | gtk4winapi.inc |
| **(R27)** §18 WinAPI 핵심 함수 품질 | 검증 없음 | **15메서드** 품질 검증: 14/15 완전(93%). StretchBlt 113줄(5561) 완전, GetTextMetrics **81줄**(3651) Pango 캐싱, CreateBitmap **45줄**(483) 4포맷. DCGetPixel **Bug#23 확인** (gdk_pixbuf 메모리 누수) | gtk4winapi.inc, gtk4object.inc |
| **(R27)** SetWindowRgn GTK4 회귀 발견 | IMPL (상태표) | **stub** `Result := 0` (5453-5459) — GTK4에서 `gtk_widget_shape_combine_region` API 제거됨. GTK2는 `gdk_window_shape_combine_region` 사용 | gtk4winapi.inc |
| **(R28)** §23 GTK4 개발 가이드 신규 | 미존재 | **§23a**: 제거/변경 API 24개 대응 현황 (19개 완전/79%), **§23b**: 7개 미활용 API 영역 (DnD/Accessible/Scroll/ColumnView/CSS/Gestures/Shortcuts), **§23c**: 3단계 우선순위, **§23d**: 문서 레퍼런스 | `/usr/share/doc/libgtk-4-doc` |
| **(R29)** Bug#29 수정 확인 | MEDIUM 버그 (메모리 누수) | ✅ **수정됨**: `g_signal_connect_data` + `Gtk4DialogBtnInfoFreeCB` (destroy_notify). GLib 자동 Dispose | gtk4widgets.pas:11972-11975 |
| **(R29)** §22b Session 58-60 현행화 | 미기재 | DetachEvents, Destroy 보강, DestroyCaret, PostMessage 검증, Gtk4IsLiveWidgetPointer, CSD 좌표 보정, 디자이너 선택 수정 — **7건 품질 개선** 문서화 | gtk4widgets.pas, gtk4winapi.inc |
| **(R29)** §22j Session 56-60 현행화 | 미기재 | GdkRGBA float 수정, DrawGrid 재작성, IsDesignerDC 구현, DoBeforeLCLPaint Form 배경 — **4건 품질 개선** 문서화 | lazgdk4.pas, gtk4lclintf.inc, gtk4widgets.pas |
| **(R29)** ApplyX11SizeHints 라인 정정 | 11460-11512 | **11589-11641** (Session 58-59 삽입으로 ~129줄 이동) | gtk4widgets.pas |
| **(R29)** §23b API 상세 레퍼런스 | 개요만 | DnD 메서드/시그널 테이블, Accessible 역할/상태 enum 매핑, ColumnView 정렬 아키텍처, Scroll 시그널 상세, CSS 의사클래스 매핑, ShortcutController Trigger/Action 상세. 바인딩 수 합계 ~111개 추정 | `/usr/share/doc/libgtk-4-doc` |
| **(R29)** Bug#13 패딩값 정정 | left=5 하드코딩 | **cGroupBoxPadding=2** (left=2, not 5). 핸들 할당 전 폴백 추정치로만 사용됨 | gtk4wsstdctrls.pp:434-435 |
| **(R30)** §22i WS→래퍼 아키텍처 분석 | 미존재 | **신규 섹션**: WS→래퍼 위임 패턴 설명, 코드 분포 통계 (ProgressBar WS 42줄+래퍼 117줄=159줄, Window ~750줄), 품질 판독 지침 5항, ProgressBar 전체 구현 맵 | gtk4widgets.pas |
| **(R30)** §4 ProgressBar deep 보강 | 래퍼 미기재 | **CreateWidget** 12줄+InitializeWidget 7줄+preferred_width 18줄 = **37줄** 래퍼, **SetPosition** 래퍼 14줄 fraction 수학, **SetStyle** 래퍼 16줄+pulse 타이머 12줄 | gtk4widgets.pas:5805-5964 |
| **(R30)** §7 Panel SetColor 정정 | MISS (no-op) | **간접 동작**: DoBeforeLCLPaint (4819-4842, 24줄)에서 `LCLObject.Color` → `fillRect` 실질 배경색 렌더링. SetColor 호출 → invalidate → paint 반영 | gtk4widgets.pas:4792, 4819-4842 |
| **(R30)** §23b API 5개 영역 추가 | 7개 영역 (R28-29) | **12개 영역**: +IMContext §23b-8 (~8 바인딩), +SelectionModel §23b-9 (~15), +Clipboard §23b-10 (~10), +PrintOperation §23b-11 (~20), +GdkTexture §23b-12 (~12). 총 ~176 바인딩 | `/usr/share/doc/libgtk-4-doc` |
| **(R30)** 라인 번호 전수 검증 | 미검증 | **31건 참조 검증 완료**: 30/31 정확 (96.8%). Session 58-60 삽입에도 라인 이동 없음 확인 (코드가 순차 삽입되었으므로 기존 참조에 영향 없음) | 전체 소스 |

### Priority 1 — Critical Bugs & Functional Gaps (즉시 수정 필요)

| Category | Issue | Impact | 난이도 |
|----------|-------|--------|--------|
| ~~🔴 마우스 modifier 반전 BUG~~ | ~~GDK_BUTTON2→ssRight, GDK_BUTTON3→ssMiddle 반전~~ | ✅ **수정됨 (Session 61)** | ~~2줄~~ |
| ~~🔴 Calendar month BUG~~ | ~~SetDateTime에서 1-based month를 0-based SetDate에 전달~~ | ✅ **수정됨 (Session 61)** | ~~1줄~~ |
| DragImageList + Drag-n-Drop | ~~All 5 stubs + GtkDragSource/DropTarget 미연결~~ **S70 바인딩 완료**: 42개 DnD 함수 (GtkDragSource 8 + GtkDropTarget 6 + GtkDropTargetAsync 4 + GdkDrop 10 + GdkDrag 7 + GdkContentProvider 1 + GdkContentFormats 5 + 유틸 1). **인트라앱 DnD 이미 동작** (LCL TDragManagerDefault 마우스캡처 방식, WS 관여 불필요). 파일 드롭도 동작 (SetAllowDropFiles). DragImageList 5 stub은 Wayland 제한 (gtk_window_move 제거). | **바인딩 완료, 크로스앱 DnD 연결만 잔여** | 바인딩 완료 |
| ~~ListView SetSort~~ | ~~queue_draw만 호출~~ | ✅ **수정됨 (Session 61)**: `ModelNotifyItemsChanged` 구현 | ~~중간~~ 완료 |
| ~~NumPad 키코드 변환~~ | ~~GdkKeyToLCLKey 테이블 22개+ 누락~~ | ✅ **수정됨 (Session 61)**: KP_0-9, 산술키, 탐색키, NumLock 등 22개+ 추가 | ~~낮음~~ |
| ~~WinControl.Repaint~~ | ~~Missing override~~ | ✅ **수정됨 (Session 61)**: queue_draw 기반 구현 추가 | ~~낮음~~ |
| SetFormStyle | ~~Stub~~ | **플랫폼 제한**: gtk4wsforms.pp:484-502는 빈 stub 아님 — `always_on_top/bottom` CSS class 설정. `gtk_window_set_keep_above`는 GTK4 4.6에 존재 안 함 (`nm -D` 확인). Wayland compositor 의존 | 플랫폼 |

### Priority 2 — Medium Bugs & Usability Issues

| Category | Issue | Impact | 난이도 |
|----------|-------|--------|--------|
| ~~SaveDialog EventCapabilities~~ | ~~cdecWSNoCanCloseSupport 미반환~~ | ✅ **수정됨 (Session 61)**: 5개 다이얼로그 전부 cdecWSNoCanCloseSupport 추가 | ~~1줄~~ |
| ~~create_stipple 파라미터~~ | ~~(w,w) → (w,h) 오류~~ | ✅ **수정됨 (Session 61)**: `create_stipple(PByte(pat_buf),w,h)` | ~~1줄~~ |
| pmNotXor 매핑 | XOR과 동일 (gtk4objects.pas:1633) | **Cairo 한계**: GTK2는 `GDK_EQUIV`(=NOT(src XOR dst)) 사용 가능했으나, Cairo는 비트연산 operator 없음. `CAIRO_OPERATOR_XOR`은 alpha compositing XOR. 수정 불가 | 플랫폼 |
| ~~SpinEdit GetValue 국제화~~ | ~~소수점 구분자 변환 없음~~ | ✅ **수정됨 (Session 61)**: `update` 호출 후 `get_value` — 텍스트→값 동기화 보장. GTK4 get_value는 C locale double 반환이므로 별도 로케일 변환 불필요 | ~~중간~~ |
| ~~SpinEdit SetReadOnly~~ | ~~adjustment bounds 미조작~~ | ✅ **수정됨 (S62)**: GTK2 패턴 적용 — ReadOnly 시 adjustment range를 현재값으로 축소 (min=max=value), 해제 시 원래 범위 복원 | ~~중간~~ |
| FontDialog fdApplyButton | Apply 버튼 없음 → OnApplyClicked 절대 발동 안됨 | 실시간 미리보기 불가 | GTK제한 |
| ComboBox SetDroppedDown | GtkDropDown(csDropDownList)에서 미동작 (IMPL*) | 드롭다운 프로그래매틱 제어 불가 | GTK제한 |
| ~~LoadCursor/LoadIcon~~ | ~~WinAPI 미구현~~ | ✅ **오보정 (S62)**: GTK2/Qt5도 미구현. 유일한 호출은 Windows 전용 (ide/raw_window.pas) | — |
| ColumnView headers_clickable | GTK4.6 API 부재 | 컬럼 헤더 클릭 정렬 불가 | GTK제한 |
| SetCursorPos (Wayland) | X11만 동작, Wayland 무음 실패 | Wayland에서 포인터 이동 불가 | 플랫폼 |
| GetCursorPos (Wayland) | 신뢰할 수 없는 좌표 | Wayland에서 글로벌 커서 위치 미제공 | 플랫폼 |
| ~~Alt 키 감지~~ | ~~ssCaps/ssNum/ssScroll 누락~~ | ✅ **수정됨 (Session 61)**: GDK_LOCK_MASK→ssCaps, GDK_MOD2→ssNum, MK_ALT 추가 | ~~낮음~~ |
| ~~Clip rect 반올림~~ | ~~Trunc/Ceil 비일관~~ | ✅ **수정됨 (Session 61)**: Floor/Ceil 일관 적용 | ~~2줄~~ |
| ROP 코드 | 2/16만 구현 (COPY, XOR) | Windows 포팅 코드 호환성 | 높음 |

### Priority 3 — Code Quality / Cleanup / Advanced

| Category | Issue | Impact |
|----------|-------|--------|
| TWSLazAccessibleObject (8 methods) | All missing + WSFactory not registered | Accessibility support (screen readers) |
| ~~GetDesignerDC/ReleaseDesignerDC~~ | ~~Missing (Qt5 only)~~ | ✅ **실제 구현됨 (R26)**: gtk4winapi.inc:2705-2710 GetDC(WindowHandle) 위임 6줄 |
| MDI (8 methods) | All stubs | MDI not supported (platform limitation) |
| SetShape | Stub | Window shaping (GTK4 removed this) |
| ~~TWSCustomEdit.SetSelText~~ | ~~Missing (GTK2 only)~~ | ✅ **오보정 (S64)**: base TWSCustomEdit.SetSelText 이미 완전 구현 (wsstdctrls.pp:605-618) |
| ~~Dialog dead code~~ | ~~GTK2 주석 26줄 + 미사용 TGtk4ColorSelectionDialog 54줄~~ | ✅ **수정됨 (Session 61)**: TGtk4ColorSelectionDialog 클래스+구현 ~60줄 삭제, GTK2 주석 ~30줄 삭제 |
| ~~콜백명 오류~~ | ~~Gtk2FileChooserResponseCB/NotifyCB~~ | ✅ **수정됨 (Session 61)**: Gtk4FileChooserResponseCB/NotifyCB로 변경 |
| ~~Calendar GetPreferredSize~~ | ~~주석 처리됨 (gtk4wscalendar.pp:326-333)~~ | ✅ **수정됨 (Session 61)**: preferredSize 패턴으로 구현 |
| ~~Calendar GtkFrame 래핑~~ | ~~불필요한 빈 프레임 위젯 중첩~~ | ✅ **수정됨 (S68)**: GtkFrame 래퍼 삭제, GtkCalendar 직접 반환 |
| ~~Menu O(n²) 리빌드~~ | ~~모든 속성 변경 시 전체 GMenu 모델 리빌드~~ | ✅ **수정됨 (Session 62)**: AttachMenu → g_idle_add 지연 리빌드 |
| ~~TrayIcon /tmp 보안~~ | ~~world-readable PNG~~ | ✅ **수정됨 (S61)**: XDG_RUNTIME_DIR 우선 사용 |
| ~~TrayIcon D-Bus 블로킹~~ | ~~무한 타임아웃~~ | ✅ **수정됨 (S61)**: 5초 타임아웃 적용 |
| ~~RawImage DataOwner~~ | ~~DataOwner=True 무조건~~ | ✅ **오보정 (S62)**: 정상 동작 확인 |
| ~~RawImage_FromBitmap~~ | ~~70+줄 주석 코드~~ | ✅ **수정됨 (S61)**: ~85줄 삭제 |
| ~~SaveDC/RestoreDC~~ | ~~필드 존재하나 미구현~~ | ✅ **실제 구현됨** (gtk4winapi.inc:4550-4598) cairo_save/restore + 카운터 |
| BitBtn RebuildButtonChild | 매번 GtkBox 전체 재생성 — 캐싱 없음 | 속성 변경 시 비효율 |
| FontDialog PreviewText | set_preview_text() API 제거됨 | 미리보기 텍스트 불가 |
| ~~SelectDirectoryDialog~~ | ~~CreateHandle 명시적 override 부재~~ | ✅ **오보정 (S64)**: LCL WS dispatch가 TGtk4WSOpenDialog.CreateHandle로 정상 해결. TGtk4FileDialog.Create (line 11771)에서 `FileDialog is TSelectDirectoryDialog` → `GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER` 설정. 의도된 설계 패턴 |

### Priority 4 — GTK2-Specific Overrides (not in Qt5 either)

Many GTK2 methods override SetColor/SetFont/SetText/ShowHide at the widget-specific level (GroupBox, ListBox, ComboBox, Edit, Memo, Button, CheckBox, StaticText). GTK4 typically handles these through the TWSWinControl base class. These are NOT true gaps — GTK2 needed per-widget overrides due to its widget architecture, while GTK4 and Qt5 handle them generically.

### Priority 5 — Platform Limitations (no fix possible)

| Issue | Reason |
|-------|--------|
| SetSizeGrip (StatusBar) | GTK4 removed GtkStatusBar |
| SetFirstDayOfWeek | GTK4 Calendar uses locale |
| SetHotTrackStyles | Windows-specific |
| SetAllocBy | Windows-specific |
| SetIconArrangement | Managed by GtkGridView |
| FontDialog strikeout/underline | GtkFontChooserDialog에 컨트롤 없음 (텍스트 속성, 폰트 속성 아님) |
| TrayIcon GetPosition | SNI 프로토콜에 위치 개념 없음 → 항상 (0,0) |
| GTK 4.10+ deprecated | GtkDialog, GtkFileChooserDialog deprecated → GTK 5.0에서 제거 예정 |
| ComboBox SetDroppedDown (DropDown) | GtkDropDown에 프로그래매틱 열기/닫기 API 없음 |
| SetOwnerData | Handled by LCL callbacks |
| MDI support | GTK4 has no MDI |
| GetTextExtentExPoint (WinAPI) | GTK2 only, rarely needed |
| SetMenu (WinAPI) | Qt5 only, GTK4 uses GMenu model |

### GTK4 Advantages

GTK4 has several unique implementations beyond GTK2/Qt5:
- **WinAPI**: CreateRoundRectRgn, GetDpiForMonitor (unique to GTK4)
- **WSFactory**: 51 distinct classes registered (GTK2: 42, Qt5: 45) — 12 extra vs GTK2, 8 extra vs Qt5
- **WS Methods**: 8+ extra overrides (AdaptBounds, GetDefaultClientRect, SetZPosition, etc.)
- **PairSplitter**: 6 fully implemented methods (GTK2/Qt5 have empty stubs only)
- **Memo**: 23 method overrides — exceeds both GTK2 and Qt5
- **TrayIcon**: Full D-Bus/SNI implementation including ShowBalloonHint
- **WinAPI**: 196 functions (GTK2: 185, Qt5: 175) — most implementations of any platform
- **Coverage**: ~90% average method coverage vs GTK2's ~73% and Qt5's ~80%

### Previously Incorrect — Now Resolved

The following items were initially listed as GTK4 gaps but have been verified as fully implemented:
- ~~TrayIcon (4 methods are stubs)~~ → All 5 methods IMPL via gtk4wstrayicon.pas
- ~~TWSCustomCheckBox.ShowHide (Missing)~~ → IMPL at gtk4wsstdctrls.pp:289
- ~~TWSCustomMemo has fewer direct overrides~~ → 23 method overrides, exceeds GTK2/Qt5

---

## 22. Implementation Quality Deep Analysis (per-method 분석 반영)

Round 14까지는 메서드 존재 여부(IMPL/MISS/STUB)만 확인했다. Round 15-18에서 10개 영역의 **실제 코드 품질**을 심층 분석하고, **45개 WS 클래스 + LCLIntf 35개 + WinAPI 196개 = 총 340+ 메서드**에 대해 GTK4/GTK2/Qt5 API 수준 비교를 수행했다. 총 **34건의 버그/이슈** 발견. Round 18: Event Handling 키 매핑 정정 (22→304+), ConstraintsChange 정정 (88줄→~190줄), Graphics DC 심층 검증. Round 19: ComCtrls 심층 검증, CheckListBox 아키텍처, PairSplitter 검증. Round 20: Dialog 심층 검증 (ShowModal 34줄, FileDialog 6+73줄, FontDialog 115줄 Pango, ColorDialog 84줄 RGBA, TGtk4DialogBtnInfo 4.10+ 대응), Menu+Spin 심층 검증 (Gtk4RebuildMenuModel 159줄 3서브루틴 구조, SetShortCut 3단계 변환 확인, GetValue 로케일 누락, SetReadOnly bounds 미잠금), WinControl+ComboBox 심층 검증 (CanFocus 프로퍼티 엄격 검증, PaintTo 45줄 GSK 파이프라인 GTK4 최정교, SetShape 의도적 stub, ComboBox HasEditBox 로직 검증, Edit.Undo 정확 확인). Round 21: 잔여 shallow 섹션 보강 — CheckListBox 데드코드/범위검사 발견, ExtCtrls RadioGroup/CheckGroup/Panel 심층 비교, Grids GTK4=GTK2 100% 동일 코드 확인 (Qt5 좌측 인셋 버그), ScrollingWinControl 46줄 완전 검증, PairSplitter GetSplitterCursor 수직 무시 발견. 전체 커버리지 달성. **Round 22**: §2 Calendar/§4 ComCtrls/§8 Forms/§13 StdCtrls 전체 품질 테이블에 **file:line, 줄 수, 래퍼 크기** 완전 기재. 5개 병렬 에이전트 투입: Calendar 8메서드 (HitTest 114줄, SetDisplaySettings 30줄), TrackBar 4메서드, StatusBar 6메서드 (RecreatePanels 54줄, UpdatePanel 59줄, ClearPanels 11줄), Forms 17메서드 (ShowHide 100줄, CreateWidget 144줄, SetAllowDropFiles 32줄), StdCtrls CheckBox 6메서드/GroupBox 3메서드/RadioButton join_group 48줄/StaticText CSS border/ToggleBox 5메서드/ListBox 14메서드/ScrollBar 4메서드 — **77개 shallow 항목을 deep 수준으로 승격**. **Round 23**: 잔여 shallow 품질 테이블 보강 — §4 Page 7메서드 (SetFont **49줄** CSS 변환, GetDefaultClientRect 17줄), §8 HintWindow 2메서드 (CreateWidget 24줄 + InitializeWidget 6줄), §13 Edit 22메서드 (SetCharCase **42줄** InsertText 콜백, SetNumbersOnly **8줄** 이중 검증, SetHideSelection 10줄 CSS, Undo 7줄 activate_action), §13 Memo 23메서드 (CreateWidget **56줄** GtkTextView+ScrolledWindow, AppendText 12줄 buffer iterator, GetCanUndo/Undo GTK4 네이티브), §13 Button 4메서드 (CreateHandle 14줄+setText 29줄, SetDefault 6줄) — **~58개 shallow 항목을 deep 수준으로 승격**. **Round 24**: 4개 병렬 에이전트로 대규모 shallow 테이블 6개 보강 — §4 ListView **51메서드** file:line 완전 기재 (CreateWidget 131줄, ColumnGetWidth 래퍼 148줄, SetPropertyInternal 117줄 case문, ItemDisplayRect 58줄 Gtk4_FindItemWidget, GetVisibleRowCount 62줄, ItemGetState/ItemSetState 각 64-67줄), §4 TabControl 10메서드 (GetDefaultClientRect 27줄, GetDesignInteractive 12줄, AddPage 17줄, MovePage 10줄), §5 WinControl **19메서드** file:line 완전 기재 (PaintTo 44줄 GSK, SetBounds 래퍼 69줄, SetChildZPosition 38줄, GetPreferredSize 래퍼 54줄), §11 MenuItem **11메서드** (Create 래퍼 63줄 GAction+GMenuItem, Destroy 래퍼 30줄 ref 정리, SetShortCut 51줄 3단계 변환, Popup 67줄 중첩 이벤트 루프), §12 SpinEdit **10메서드** (UpdateControl 33줄, SetReadOnly 18줄 3분기), §13 ComboBox **12메서드** (CreateHandle 19줄 듀얼 위젯, GetItemHeight 28줄 Pango, SetItemHeight 17줄 CSS) — **~117개 shallow 항목을 deep 수준으로 승격**. **Round 25**: 전체 §1-§16 품질 테이블 완전성 검증 (4개 병렬 에이전트). 결과: §13 ComboBox **6메서드 추가** (GetSelStart **16줄** GtkEditable.get_selection_bounds, GetSelLength **14줄** AEnd-AStart, GetMaxLength **12줄** GtkEntry.get_max_length, SetSelStart **11줄** set_position, SetSelLength **13줄** select_region, SetMaxLength **11줄** set_max_length — 전부 DropDown 가드 포함), §6 Dialog **QueryWSEventCapabilities 3건 추가** (SelectDir/ColorDialog/FontDialog — 모두 `[cdecWSPerformsDoShow]` 5줄). TWSControl.GetDefaultColor/AddControl은 TGtk4WSControl **빈 클래스** (override 없음, 서브클래스에서 재정의) 확인. **전체 per-method quality 100% 커버리지 달성**. **Round 26**: §17 LCLIntf 품질 테이블 전체 **34메서드** file:line 완전 기재 (기존 26개 + DCSetAntialiasing 9줄/SetCursorPos 56줄 신규 2개). **GetDesignerDC MISS→IMPL 정정** 발견 (gtk4winapi.inc:2705-2710 — `GetDC` 위임 6줄). RawImage 6메서드 file:line 보강 (CreateBitmaps 201-533, DescFromBitmap 542-644, DescFromDevice 654-684, FromBitmap 996-1162, FromDevice 1169-1329, QueryDesc 980-990). §17 전체 per-method quality file:line 100% 달성. **Round 27**: §18 WinAPI per-method 품질 테이블 **40메서드** 신규 생성. 차별 메서드 25개 file:line 기재: GTK4 유니크 (CreateRoundRectRgn 4줄:691, GetDpiForMonitor 30줄:2877 — `gtk4_display_get_monitors`+GListModel), GTK4>GTK2 (CreatePatternBrush 38줄 cairo 타일, GradientFill **119줄** linear 그래디언트, InitStockFont **69줄** Pango 시스템 폰트, IntersectClipRect 12줄 리전 추상화). SetWindowRgn **GTK4 회귀** 발견 (`gtk_widget_shape_combine_region` 제거 → stub). 핵심 함수 15개 품질 검증: 14/15 완전(93%), DCGetPixel Bug#23 메모리 누수 확인. StretchBlt **113줄** 완전, GetTextMetrics **81줄** Pango 캐싱, CreateBitmap **45줄** 4포맷 지원. §1-§18 전체 per-method quality 100% 달성. **Round 28**: §23 GTK4 공식 문서 기반 개발 가이드 신규 추가 (`/usr/share/doc/libgtk-4-doc`, `/usr/share/doc/libgtk-4-dev` 참조). §23a: GTK4 제거/변경 API **24개 대응 현황** 검증 — 19개 완전 대응(79%), gtk_widget_destroy/show_all/GtkContainer/GdkWindow/GtkRadioButton/GtkMenu 등 완전 교체, SetWindowRgn 1건 회귀(대체 불가), gdk_pixbuf_get_from_surface/gdk_cairo_set_source_pixbuf 2건 deprecated 동작 중. §23b: 미활용 GTK4 신규 API **7개 영역**: (1) DnD — GtkDropTarget/DragSource (최우선, 전체 기능 회복), (2) Accessible — 위젯 역할/상태 미설정 (낮은 난이도/높은 효과), (3) EventControllerScroll — 터치패드 개선, (4) ColumnView 고급 (헤더 메뉴/러버밴드/정렬기), (5) CSS 테마 (변수/의미색상/의사클래스), (6) 제스처 입력 (터치/태블릿), (7) ShortcutController 현대화. §23c: 3단계 개발 우선순위 정리. §23d: GTK4 공식 문서 레퍼런스 경로 표. **Round 29**: 3개 병렬 에이전트 — (1) **버그 34건 전수 검증**: Bug#29 TGtk4DialogBtnInfo 수정 확인 (g_signal_connect_data destroy_notify), 29건 미수정, Bug#13 패딩값 정정(5→2). (2) **§22 Session 56-60 현행화**: §22j GdkRGBA float fix/DrawGrid/IsDesignerDC 4건 추가, §22b DetachEvents/Destroy/DestroyCaret/PostMessage/CSD좌표 7건 추가, §22a GetCursorPos CSD 보정 반영, ApplyX11SizeHints 라인 정정(11460→11589). (3) **§23b GTK4 API 상세화**: DnD 구체적 메서드/시그널 테이블 (GtkDragSource 7+GtkDropTarget 8), Accessible 역할/상태/관계 enum 전체 매핑, ColumnView 정렬 3단계 아키텍처 + GtkCustomSorter, Scroll 시그널/플래그 상세, CSS 의사클래스-상태 매핑 + 프로퍼티 목록, ShortcutController Trigger/Action/Scope 상세. §23c 우선순위에 바인딩 수 추가 (합계 ~111개). 33 bugs (1 fixed). **Round 30**: 3개 병렬 에이전트 — (1) **라인 번호 전수 검증**: 31건 참조 확인 (30/31 정확 = 96.8%). (2) **래퍼 포함 deep 분석**: §22i WS→래퍼 위임 아키텍처 분석 신규 추가 — 코드 분포 통계 (WS+래퍼 합산 시 GTK4가 GTK2의 1.5-2배), ProgressBar 전체 구현 맵 (WS 42줄+래퍼 117줄=159줄), Panel SetColor 간접 동작 경로 (DoBeforeLCLPaint). (3) **§23b GTK4 API 5개 영역 추가**: IMContext pre-edit (§23b-8, ~8 바인딩), SelectionModel & 필터/정렬 (§23b-9, ~15), Clipboard 비동기 (§23b-10, ~10), PrintOperation (§23b-11, ~20), GdkTexture (§23b-12, ~12). 총 바인딩 추정 111→176개. 33 bugs (1 fixed).

### 22a. Mouse / Cursor 구현 품질

**전체 평가: 7/10** — 핵심 동작하지만 Wayland 제약과 일부 누락 있음

| 기능 | 상태 | 세부사항 |
|------|------|----------|
| SetCursor (per-widget) | **완전** | `gtk4_widget_set_cursor(PGdkCursor)` 사용, 올바름 |
| SetCursor (global) | **완전** | `SetGlobalCursor()` — 모든 toplevel 순회 |
| CreateStandardCursor | **완전** | CSS 커서명 26종 매핑 (`gdk4_cursor_new_from_name`) |
| SetCursorPos | **부분** | X11만 동작 (`XWarpPointer` via dlopen). **Wayland 미지원** (False 반환) |
| GetCursorPos | **부분** | **S60 수정**: CSD 오프셋 차감으로 콘텐츠 상대 좌표 반환 (`gtk4_native_get_surface_transform`). X11 정상. **Wayland에서 global 좌표 의도적 미제공** (보안 정책) |
| SetCapture/ReleaseCapture | **완전** | 소프트웨어 `Gtk4CapturedWidget` + `gdk_seat_grab()` |
| GetCapture | **완전** | 소프트웨어 추적 변수 |
| DestroyCursor | **완전** | `g_object_unref(PGdkCursor)` — 올바른 refcount 관리 |
| ~~LoadCursor~~ | ~~미구현~~ | ✅ **오보정 (S62)**: GTK2/Qt5도 미구현. 유일한 호출은 Windows 전용 (ide/raw_window.pas) |
| ~~LoadIcon~~ | ~~미구현~~ | ✅ **오보정 (S62)**: 동일 |
| ~~TGtk4Cursor constructor~~ | ~~Dead code~~ | ✅ **수정됨 (S61)**: 클래스 선언+구현 ~45줄 삭제 |
| Mouse Event Controllers | **완전** | GtkEventControllerLegacy(capture phase)로 click/motion/enter/leave 모두 처리 |
| Deferred Mouse Events | **완전** | button click은 큐잉 후 g_idle에서 dispatch (re-entrancy 방지) |

**주요 이슈:**
1. `SetCursorPos()` — Wayland에서 완전 미동작 (GTK4/Wayland 정책적 제한)
2. `GetCursorPos()` — Wayland에서 신뢰할 수 없는 좌표 반환
3. ~~`LoadCursor()`/`LoadIcon()` — 미구현~~ ✅ **오보정 (S62)**: GTK2/Qt5도 미구현
4. ~~`TGtk4Cursor` 생성자 dead code~~ ✅ **수정됨 (S61)**: ~45줄 삭제

---

### 22b. Form / Widget Layout 구현 품질

**전체 평가: 9/10** — 핵심 레이아웃 견고, GtkFixedLayout 패치가 핵심. **Session 58-59**: 윈도우 파괴 안전성 대폭 개선 (DetachEvents, DestroyCaret, PostMessage 검증, GObject unref). **Session 60**: CSD 좌표 보정으로 디자이너 좌표계 정상화

| 기능 | 상태 | 세부사항 |
|------|------|----------|
| SetBounds (widget) | **완전** | `set_size_request` + `gtk4_widget_size_allocate` + `gtk4_fixed_move` |
| SetBounds (window) | **완전** | `gtk_window_set_default_size` (GTK4: 직접 allocate 금지) |
| SetPos / Move | **완전** | `gtk4_fixed_move`로 GtkFixed 내 재배치 |
| SetSize | **완전** | SetBounds 위임 |
| GtkFixedLayout 패치 | **완전** | 3-pass 알고리즘: 자식수집 → 오버랩감지 → 할당+클리핑. **GTK4 LCL의 가장 중요한 수정** |
| ClientToScreen / ScreenToClient | **완전** | `gtk4_widget_translate_coordinates` (double 좌표). CSD 오프셋 보정 |
| GetClientRect | **완전** | 위젯: `get_allocation`, 윈도우: `get_default_size` 우선 |
| GetNonClientOverhead | **완전** | CSS margin + 메뉴바 높이 3단 폴백 계산 |
| Z-ordering | **부분** | `gtk4_widget_insert_before/after` 사용하나, GtkFixed의 z-order 모델이 LCL과 다름 |
| preferredSize | **완전** | `gtk_widget_measure` + CSS overflow 보상 (GType별 캐싱) |
| overflow:HIDDEN 클리핑 | **완전** | FCentralWidget, FPaintArea, 제약 자식에 설정 |

**TGtk4Window.CreateWidget (gtk4widgets.pas:10920-11063) — 144줄 종합 초기화:**
- 6-depth 위젯 트리 조립 (아래 구조)
- GMenu/GAction 그룹 초기화 (메뉴 지원)
- GtkScrolledWindow 정책/adjustment 설정 + value-changed 시그널 연결
- GtkDrawingArea 오버레이 + draw_func 연결
- close-request, notify::maximized 등 윈도우 시그널 연결
- GtkCssProvider 기본 스타일 적용

```
GtkWindow (FWidget)
  └─ GtkBox (FBox, vertical)
     ├─ GtkPopoverMenuBar (FMenuBar, if menu)
     └─ GtkOverlay (FOverlay)
        ├─ GtkScrolledWindow (FScrollWin)
        │  └─ GtkViewport → GtkFixed (FCentralWidget)
        └─ GtkDrawingArea (FPaintArea, overlay)
```

**ConstraintsChange 구현 ~190줄** (3개 프로시저에 걸친 복합 워크어라운드):
- `TGtk4WSWinControl.ConstraintsChange` (gtk4wscontrols.pp:138-226): **89줄**, `set_size_request` + 범위 클리핑
- `TGtk4Window.SetMaxSize` (gtk4widgets.pas:11512-11560): **49줄**, CSS `max-width/max-height` 룰 + FrameClock `after-paint` 연결 + X11 size hints
- `ApplyX11SizeHints` (gtk4widgets.pas:**11589-11641**): **53줄**, X11 전용 `XSetWMNormalHints` 경로 *(R29 라인 정정: Session 58-59 삽입으로 11460→11589 이동)*
- 비교: GTK2는 `gdk_window_set_geometry_hints()` **1줄** 호출로 완료

#### Session 58-60 안전성 개선 (R29 추가)

| 수정 | 세션 | 세부사항 | 라인 |
|------|------|----------|------|
| **TGtk4Window.DetachEvents** | S58-59 | FScrollWin의 VAdjustment/HAdjustment `value-changed` 시그널 + FrameClock `after-paint` 시그널 해제. 이들은 FWidget이 아닌 **별도 GObject**에 연결되어 base `DestroyWidget`의 `g_signal_handlers_disconnect_matched(FWidget)`로 해제 불가. 미해제 시 `FWidget^.destroy_()` 중 adjustment emit → 파괴된 메모리 접근 → SIGSEGV | gtk4widgets.pas:11350-11381 |
| **TGtk4Window.Destroy 보강** | S58-59 | FMenuModel, FMenuActionGroup, FMaxCssProvider `g_object_unref` (ref-counted GObject, 위젯 트리 외부). inherited 후 FBox/FScrollWin/FOverlay/FMenuBar `nil` 처리 (stale pointer 방지) | gtk4widgets.pas:11383-11409 |
| **DestroyCaret 안전** | S58-59 | `TGtk4Widget.Destroy`에서 `DestroyCaret(HWND(Self))` 호출 → 캐럿 타이머 콜백이 해제된 메모리 접근 방지. `InvalidateCaret`는 `Gtk4IsLiveWidgetPointer` 검증 | gtk4widgets.pas:4099-4108 |
| **PostMessage 안전** | S58-59 | `Gtk4ProcessPostMessage` (g_idle_add 콜백)에서 `Gtk4IsLiveWidgetPointer`로 대상 검증 후 `DeliverMessage`. 위젯 파괴 전 큐에 넣은 메시지가 해제된 TGtk4Widget에 전달되는 SIGSEGV 방지 | gtk4winapi.inc:4322-4348 |
| **Gtk4IsLiveWidgetPointer** | S58-59 | 인터페이스 섹션으로 이동 (gtk4widgets.pas:1066) — gtk4object.inc, gtk4winapi.inc에서 접근 가능. LiveWidget 딕셔너리로 Pascal 객체 생존 검증 | gtk4widgets.pas:1066 |
| **CSD 좌표 보정** | S60 | `GetCursorPos`에서 `gtk4_native_get_surface_transform` 오프셋 차감 → 콘텐츠 상대 좌표. `Gtk4LegacyEventCB` 모든 마우스 이벤트(BUTTON/MOTION/ENTER)에서 CSD 오프셋 차감. 새 바인딩: `gtk4_native_get_for_surface` | gtk4winapi.inc:2614-2657, gtk4widgets.pas:1430-1590 |
| **디자이너 선택 수정** | S60 | `csDesigning` 체크: Gtk4LegacyEventCB(1462), Gtk4ClickPressedCB(1712), Gtk4ClickReleasedCB(1753), TGtk4Button.ButtonClicked(10135). 디자이너 모드에서 버튼 클릭 이벤트 정상 전달 | gtk4widgets.pas |
| **TGtk4Widget.DetachEvents** | S67 | FIMContext(PGtkIMContext)의 `commit` 시그널 해제 + `g_object_unref`. FIMContext는 독립 GObject (위젯 트리 밖), InitializeWidget에서 생성되나 어디서도 해제되지 않았음. 미해제 시 위젯 파괴 후 IME commit → 해제된 Self 접근 가능 + 메모리 누수 | gtk4widgets.pas:3897-3909 |
| **TGtk4Memo.DetachEvents** | S67 | PGtkTextBuffer의 `insert-text` 시그널 해제. InitializeWidget에서 `ABuffer`(FCentralWidget의 TextBuffer)에 연결 — FWidget이 아닌 별도 GObject. 미해제 시 위젯 파괴 중 TextBuffer emit → 해제된 Self 접근 가능 | gtk4widgets.pas |
| ~~**TGtk4Calendar.DetachEvents**~~ | ~~S67~~ S68 삭제 | ~~FCentralWidget 시그널 해제~~ → **S68에서 GtkFrame 래퍼 자체 삭제**: GtkCalendar가 FWidget으로 직접 반환 → 시그널이 FWidget에 연결 → base DestroyWidget이 자동 해제 → DetachEvents override 불필요 | gtk4widgets.pas |

#### Session 68 런타임 안전성 개선

| 수정 | 세부사항 | 파일 |
|------|----------|------|
| **g_idle_remove_by_data 오용 수정 (2건)** | `Gtk4ProcessPostMessage`: idle 콜백 내에서 `g_idle_remove_by_data` 호출(무효) + `Result := True`(계속 호출=해제 후 메모리 접근) → 삭제, `Result := False` 유지. `BackNoteBookSignal`: 불필요 `g_idle_remove_by_data` 호출 → 삭제 (`Result := False`로 자동 제거) | gtk4winapi.inc, gtk4widgets.pas |
| **TGtk4MemoStrings 타이머 정리** | 소멸자에서 `FTimerMove`/`FTimerSel` 미해제 → `g_source_remove` 추가. 콜백에서 타이머 ID를 0으로 초기화 (소멸자 이중 제거 방지). 미해제 시 객체 파괴 후 콜백이 해제된 메모리 접근 → SIGSEGV | gtk4private.pas |
| **Gtk4WindowAfterPaintCB 검증** | `AData` (PGtkWidget)에 `Gtk4IsWidget` 검사 추가. 위젯 파괴 후 FrameClock 콜백이 발동하면 해제된 GObject에 `g_object_get_data` 호출 → 크래시 | gtk4widgets.pas |
| **ComboBox 콜백 안전 (5건)** | `Gtk4ECB_ButtonClicked`, `Gtk4ECB_SelectionChanged`, `Gtk4ECB_EntryChanged`, `Gtk4ECB_PopoverNotifyVisible`, `Gtk4DropDownSelectedChanged` — AData에 `Gtk4IsLiveWidgetPointer` 검증 추가. 자식 GObject(FButton/FSelectionModel/FEntry/FPopover) 시그널은 base DestroyWidget으로 해제 안됨 → 파괴 중 콜백 발동 시 해제된 Pascal 객체 접근 가능 | gtk4widgets.pas |
| **Gtk4ScrollAdjChangedCB 검증** | AData(TGtk4ScrollableWin)에 `Gtk4IsLiveWidgetPointer` 검증 추가. Adjustment 시그널은 자식 GObject → base 해제 불가 | gtk4widgets.pas |
| **추가 콜백 안전 (5건)** | `Gtk4EntryChanged` (PGtkEntryBuffer 자식 GObject, 검증 없음→추가), `Gtk4RangeChanged` (nil→LiveWidgetPointer), `Gtk4WS_ListViewColumnClicked` (PGtkTreeViewColumn 자식 GObject, nil→LiveWidgetPointer), `Gtk4Toggled` (FWidget이나 검증 없음→추가), Calendar 콜백 3건 (`Gtk4CalendarDaySelected/MonthChanged/YearChanged`, nil→LiveWidgetPointer) | gtk4widgets.pas |
| **Pixbuf 메모리 누수 수정 (8건)** | `Gtk4BitmapToPixbuf` 반환값 `g_object_unref` 누락: gtk4wsmenus.pp(Gtk4CreateMenuIconFromBitmap), gtk4wsbuttons.pp(SetGlyph+RebuildButtonChild), gtk4widgets.pas(TGtk4Page.SetImage, Gtk4CV_FactoryBind, Gtk4GV_FactoryBind, TreeView cell renderer, ListView ColumnHeader). 매 아이콘/글리프 업데이트마다 pixbuf 누적 | gtk4wsmenus.pp, gtk4wsbuttons.pp, gtk4widgets.pas |
| **CSSProvider 누수 수정** | ColumnView per-cell CSSProvider: `g_object_set_data` → `g_object_set_data_full(@g_object_unref)` — Box 파괴 시 초기 ref 자동 해제. `gtk_css_provider_new`의 ref 1개가 Box 생존 동안 누적되지 않음 | gtk4widgets.pas |
| **TGtk4ScrollBar.DetachEvents (S69)** | value-changed 시그널이 Adjustment (자식 GObject)에 연결됨 → base DestroyWidget 해제 불가. DetachEvents override 추가하여 소멸 전 해제 | gtk4widgets.pas |
| **추가 콜백 안전 (11건, S69)** | `Gtk4CloseRequestCB`, `Gtk4ListBoxSelectionChanged`, `Gtk4LB_SelectionChanged`, `Gtk4CLB_FactoryBind`, `Gtk4CLB_CheckToggled`, `Gtk4CV_CheckToggled`, `Gtk4CV_SelectionChanged`, `Gtk4CV_SorterChanged`, `Gtk4WS_ListViewItemSelected`, `Gtk4WS_ListViewItemCheckedChanged`, `Gtk4MemoBufferInsertText` — `Gtk4IsLiveWidgetPointer` 검증 추가. `Gtk4WindowVScrollPinCB`/`Gtk4WindowHScrollPinCB` — `IsWidgetOk` 전에 `Gtk4IsLiveWidgetPointer` 추가 | gtk4widgets.pas |
| **IMContext pre-edit 지원 (S69)** | `preedit-start`/`preedit-end`/`preedit-changed` 시그널 연결: `Gtk4IMPreeditStartCB`/`EndCB`/`ChangedCB` 콜백 추가. `get_preedit_string` → `LM_IM_COMPOSITION` + `GTK_IM_FLAG_PREEDIT`/`START`/`END`/`COMMIT`/`REPLACE` 전달. `gtk_im_context_simple_new` → `gtk_im_multicontext_new` 전환 (시스템 IM 자동 선택: ibus/fcitx 등). 포커스 아웃 시 `FIMContext^.reset` 호출하여 진행 중 조합 중단. `FIMPreeditActive`/`FIMSkipDelete` 상태 필드 추가 | gtk4widgets.pas |
| **IMContext set_cursor_location (S69)** | `SetCaretPosEx`에서 캐럿 위치 변경 시 `IMContext^.set_cursor_location(@GdkRectangle)` 호출 — CJK/한글 후보창이 커서 근처에 표시됨. `IMContext` public read property 추가 (gtk4widgets.pas) — gtk4winapi.inc (gtk4int.pas 포함)에서 접근 가능 | gtk4winapi.inc, gtk4widgets.pas |
| **GTK4 Accessibility 구현 (S69)** | `TGtk4WSLazAccessibleObject` 8/8 메서드 구현: `CreateHandle` (위젯 핸들 재사용), `SetAccessibleName` (LABEL property), `SetAccessibleDescription` (DESCRIPTION), `SetAccessibleValue` (VALUE_TEXT), `SetAccessibleRole`/`SetPosition`/`SetSize` (GTK4 자동 관리 no-op). `RegisterWSLazAccessibleObject` 등록 활성화. GTK4 Accessible API 바인딩 6함수 + 4 enum (lazgtk4_compat.pas): `gtk4_accessible_update_state_value`/`property_value`/`relation_value` + `reset_state`/`property`/`relation` + `TGtkAccessibleState`/`Property`/`Relation`/`Tristate`/`InvalidState` | gtk4wscontrols.pp, gtk4wsfactory.pas, lazgtk4_compat.pas |

**주요 이슈:**
1. **TGtk4Button 4px 감산 hack** (gtk4widgets.pas:4302-4306) — 원인 미규명, GTK2에 없던 코드
2. **Wayland 윈도우 위치 제어 불가** — `gtk_window_move()` 제거됨 (GTK4 정책)
3. **RecreateWnd 필요 상황** — 선택 모델 변경(ListBox/ListView), View 스타일 전환 등에서 전체 위젯 재생성
4. **SetFormStyle 플랫폼 제한** — NOT empty stub (gtk4wsforms.pp:484-502), `always_on_top/bottom` 설정하나 Wayland compositor가 무시할 수 있음. 코드 내 플랫폼 제한 문서화됨

---

### 22c. Event Handling 구현 품질

**전체 평가: 8.0/10** — 핵심 이벤트 완전, Drag-and-Drop 미구현이 주요 감점 요인

| 이벤트 종류 | 컨트롤러 | 상태 | 세부사항 |
|-------------|----------|------|----------|
| Mouse Click | Legacy (capture) | **완전** | GDK4_BUTTON_PRESS/RELEASE → LM_LBUTTONDOWN 등. 버튼 번호 매핑 정확 (GTK4_LEFT=1, GTK4_MIDDLE=2, GTK4_RIGHT=3) |
| Mouse Motion | Legacy (capture) | **완전** | GDK_MOTION_NOTIFY → WM_MOUSEMOVE |
| Mouse Enter/Leave | Legacy (capture) | **완전** | GDK_ENTER/LEAVE_NOTIFY |
| Double/Triple Click | Legacy (capture) | **완전** | `n_press==2` → GDK_2BUTTON_PRESS |
| Mouse Wheel | GtkEventControllerScroll | **완전** | V/H 스크롤, WheelDelta=±120 |
| Key Press/Release | GtkEventControllerKey | **완전** | GdkKeyToLCLKey 변환, UTF-8 문자 전달 |
| IME Input | GtkIMContext | **완전** | 비-Entry/Memo 위젯에 commit+preedit-start/end/changed 콜백 (S69). `gtk_im_multicontext_new` — 시스템 IM (ibus/fcitx) 자동 연동. `LM_IM_COMPOSITION` 메시지 전달 |
| Focus In/Out | GtkEventControllerFocus | **완전** | 앱 활성화/비활성화 추적 포함 |
| Paint/Draw | GtkDrawingArea draw_func | **완전** | `Gtk4PaintAreaDrawFunc` → `GtkEventPaint`. **네이티브 더블 버퍼링** (GTK4 자동 제공) |
| Drag Source | GtkGestureDrag | **미구현** | 바인딩 존재하나 연결 안됨 |
| Drop Target | GtkDropTarget | **미구현** | 바인딩 존재하나 연결 안됨 |

**키보드 변환 테이블 GdkKeyToLCLKey (gtk4procs.pas:736-762) — 구조 분석:**

GTK4 키 매핑 **304+ 키 지원**: AValue<=0xFF 통과 (ASCII/Latin-1 전체 256문자) + case문 **18 항목** (Tab, Return, Escape, BackSpace, Up/Down/Left/Right, Home, End, Prior, Next, Insert, Delete, F1-F30, Shift_L/R, Control_L/R, Alt_L/R). GTK2는 50+ 명시적 case 항목으로 접근이 다르나 실질적 커버리지 유사.

**⚠️ 이전 기재 정정**: "22개 키만 매핑"은 오류. ASCII passthrough($00-$FF)가 대부분의 키를 커버하므로 실제 304+ 키 매핑됨. 단, 아래 GDK 고유 키심볼은 0xFF 초과 값이므로 passthrough에 포함되지 않아 별도 case 항목이 필요하지만 누락됨.

| GDK 키심볼 | VK_ 코드 | GTK4 | GTK2 | 영향 |
|-----------|----------|------|------|------|
| GDK_KEY_KP_0..KP_9 | VK_NUMPAD0..9 | **누락** | 매핑 | 숫자패드 숫자 |
| GDK_KEY_KP_Multiply | VK_MULTIPLY | **누락** | 매핑 | 숫자패드 * |
| GDK_KEY_KP_Add | VK_ADD | **누락** | 매핑 | 숫자패드 + |
| GDK_KEY_KP_Subtract | VK_SUBTRACT | **누락** | 매핑 | 숫자패드 - |
| GDK_KEY_KP_Decimal | VK_DECIMAL | **누락** | 매핑 | 숫자패드 . |
| GDK_KEY_KP_Divide | VK_DIVIDE | **누락** | 매핑 | 숫자패드 / |
| GDK_KEY_KP_Separator | VK_SEPARATOR | **누락** | 매핑 | 숫자패드 구분자 |
| GDK_KEY_Caps_Lock | VK_CAPITAL | **누락** | 매핑 | CapsLock |
| GDK_KEY_Num_Lock | VK_NUMLOCK | **누락** | 매핑 | NumLock |
| GDK_KEY_Scroll_Lock | VK_SCROLL | **누락** | 매핑 | ScrollLock |
| GDK_KEY_Pause | VK_PAUSE | **누락** | 매핑 | Pause/Break |
| GDK_KEY_Sys_Req | VK_SNAPSHOT | **누락** | 매핑 | PrintScreen |
| GDK_KEY_Print | VK_PRINT | **누락** | 매핑 | Print |
| GDK_KEY_Alt_L/R | VK_MENU | **부분** | 완전 | Alt (L만, R 누락) |
| GDK_KEY_Super_L/R | VK_LWIN/RWIN | **누락** | 매핑 | Windows/Super 키 |
| GDK_KEY_Clear | VK_CLEAR | **누락** | 매핑 | Clear |
| GDK_KEY_Cancel/Break | VK_CANCEL | **누락** | 매핑 | Ctrl+Break |
| GDK_KEY_Select | VK_SELECT | **누락** | 매핑 | Select |
| GDK_KEY_Execute | VK_EXECUTE | **누락** | 매핑 | Execute |
| GDK_KEY_Help | VK_HELP | **누락** | 매핑 | Help |
| GDK_KEY_Mode_switch | VK_MODECHANGE | **누락** | 매핑 | AltGr/ISO Level3 |
| GDK_KEY_KP_Home/End/Page_Up/Down | VK_HOME/END/PRIOR/NEXT | **누락** | 매핑 | NumPad 방향키 (NumLock off) |
| GDK_KEY_KP_Delete/Insert | VK_DELETE/INSERT | **누락** | 매핑 | NumPad Del/Ins |

**Modifier 변환 (gtk4procs.pas:806-857):**
- `GdkModifierStateToLCL`: MK_LBUTTON/MBUTTON/RBUTTON/XBUTTON1/2/SHIFT/CONTROL 매핑 완전. **MK_ALT 누락** (GDK_META_MASK 미매핑)
- `GdkModifierStateToShiftState`: ssLeft/Right/Middle/Extra1/Extra2/Shift/Ctrl/ssAlt 매핑됨 (GDK_META_MASK→ssAlt). **ssCaps/ssNum/ssScroll 누락**
- `ShiftStateToGdkMods`: ssShift/ssCtrl/ssAlt만 (역방향)

**주요 이슈:**
1. **Drag-and-Drop 완전 미구현** — BeginDrag/DragMove/EndDrag는 True/noop stub. GtkDragSource/GtkDropTarget 바인딩 존재하나 연결 안됨. **GTK4 DnD API (GtkDragSource/GtkDropTarget)는 GtkDragContext 기반 GTK2/3 API와 완전히 다른 새 설계** — 단순 포팅 불가
2. ~~**숫자패드 GDK 키심볼 미변환**~~ ✅ **수정됨 (Session 61)** — GdkKeyToLCLKey + LCLKeyToGdkKeyval 양방향에 KP_0..9 → VK_NUMPAD0..9, KP_Multiply/Add/Separator/Subtract/Decimal/Divide, KP_Home/End/Page_Up/Page_Down/Insert/Delete, KP_Space/Begin → VK_CLEAR, KP_Tab, KP_F1..F4, Num_Lock → VK_NUMLOCK 추가 (GTK2 gtk2proc.inc:2741-2862과 동일 매핑)
3. **GtkEventControllerLegacy 의존** — GTK4 권장 GtkGestureClick 대신 legacy controller 사용 (gtk4widgets.pas:4034-4036). 코드 주석에 GestureClick이 불안정한 이유 설명
4. ~~**Modifier 불완전**~~ ✅ **수정됨 (Session 61)** — `GdkModifierStateToLCL`에 `MK_ALT` 추가, `GdkModifierStateToShiftState`에 `GDK_LOCK_MASK→ssCaps`, `GDK_MOD2_MASK→ssNum` 추가 (ssScroll은 GTK4에 대응 mask 없음 — X11 Scroll Lock은 비표준 modifier)
5. ~~**🔴 BUG: 마우스 버튼 Modifier 매핑 반전**~~ ✅ **수정됨 (Session 61)** (gtk4procs.pas:837-841)
   - 수정: `GDK_BUTTON2_MASK` → `ssMiddle`, `GDK_BUTTON3_MASK` → `ssRight`로 교정
   - GTK2(gtk2proc.pp:1009-1010) 올바른 매핑과 동일하게 변경
6. ~~**IME pre-edit 미지원**~~ ✅ **수정됨 (S69)** — `preedit-start`/`preedit-end`/`preedit-changed` 시그널 연결, `LM_IM_COMPOSITION` + `GTK_IM_FLAG_*` 메시지 전달, `gtk_im_multicontext_new` 사용

---

### 22d. StdCtrls (Edit/Memo/ComboBox/ListBox/CheckBox) 구현 품질

**전체 평가: 9/10** — 거의 완벽한 구현, 일부 근사치/비효율 발견

| 컨트롤 | 메서드 수 | 상태 | 비고 |
|--------|----------|------|------|
| TGtk4WSCustomEdit | 16 | **완전** | GtkEditable 인터페이스 정확 사용. **Undo**: GTK4만 `gtk4_widget_activate_action('text.undo')` 구현 — GTK2 미구현! |
| TGtk4WSCustomMemo | 12 | **대부분 완전** | GtkTextBuffer/GtkTextView 완전 활용. **GetStrings**: 매 호출마다 `TGtk4MemoStrings.Create` 새 객체 생성 (비효율) |
| TGtk4WSCustomComboBox | 14 | **완전** | 듀얼 위젯 전략 (TGtk4ComboBox[editable] + TGtk4DropDown[readonly]). GTK2/Qt5 대비 **유일한 듀얼 아키텍처** |
| TGtk4WSCustomListBox | 14 | **대부분 완전** | GtkListView + GtkStringList 기반. **근사치 API 3건** (아래 참조) |
| TGtk4WSCustomCheckBox | 6 | **완전** | GtkCheckButton 래핑. GTK4가 가장 간결 (ShowHide 6줄 vs GTK2 40줄) |
| TGtk4WSCustomGroupBox | 7 | **대부분 완전** | **GetDefaultClientRect 하드코딩** (top=20, left=5 — 테마 미인식) |
| TGtk4WSScrollBar | 4 | **완전** | **SetKind**: RecreateWnd 필요 (Qt5는 동적 변경 가능) |
| TGtk4WSButton | 5 | **완전** | **SetShortCut**: GTK4 유일 구현 (GTK2는 라벨에 포함, Qt5 미구현) |
| TGtk4WSCustomStaticText | 5 | **완전** | CSS 기반 SetStaticBorderStyle |

**시그널 연결 완전성:**
- Edit: `changed` + `insert-text` (CharCase/NumbersOnly 강제)
- Memo: GtkTextBuffer `insert-text` (MaxLength/CharCase)
- ComboBox: 4개 시그널 (entry.changed, button.clicked, model.selection-changed, popover.notify::visible)
- DropDown: `notify::selected`
- ListBox: selection-changed (CreateWidget에서 연결)

**ListBox 근사치 API (GTK4 플랫폼 제한):**
- `GetIndexAtXY`: `(Y + scroll_offset) / row_height` 공식 — GTK2는 `gtk_tree_view_get_path_at_pos` 정확 API
- `GetItemRect`: `Index * row_height - scroll_offset` 계산 — GTK2는 `gtk_tree_view_get_cell_area` 정확 API
- `GetTopIndex`: `Round(scroll_offset / row_height)` 근사 — GTK2는 TreePath 정확 변환
- **영향**: 가변 높이 행이나 스크롤 바운더리에서 1행 오차 가능

**ComboBox 듀얼 위젯 아키텍처 상세 (gtk4wsstdctrls.pp:800-818 코드 검증):**
- `HasEditBox=True` (`csDropDown`/`csSimple`) → `TGtk4ComboBox` (GtkComboBoxText 래핑, 편집 가능) — GtkEntry 내장
- `HasEditBox=False` (`csDropDownList`/`csOwnerDrawFixed/Variable`) → `TGtk4DropDown` (GtkDropDown 래핑, 읽기 전용) — 선택 전용
- **RecreateWnd 필요**: 스타일 변경 시 위젯 타입 전환 → 핸들 재생성 불가피 (SetStyle 주석: "RecreateWnd required")
- GTK2/Qt5: 단일 위젯으로 모든 스타일 처리 (editable 플래그 토글)
- **GtkDropDown API 제한**: `SetDroppedDown` (프로그래매틱 열기/닫기), `GetDroppedDown` (팝업 상태 조회), `SetDropDownCount` (최대 표시 항목 수) 모두 GtkDropDown에서 미동작

**알려진 제한 (GTK4 플랫폼):**
1. **ListBox SetColumnCount**: 빈 구현 — GTK4에 다중 컬럼 ListBox 없음
2. **ComboBox SetDroppedDown**: GtkDropDown에서 프로그래매틱 열기/닫기 불가 (API 부재)
3. **Memo SetEchoMode**: GtkTextView에 패스워드 모드 없음
4. **Memo GetStrings 비효율**: 매 호출 시 새 TGtk4MemoStrings 객체 생성 → 빈번 호출 시 GC 부담
5. **GroupBox GetDefaultClientRect**: 하드코딩 top=20, left=5 → 테마/DPI별 편차 가능

---

### 22e. WinAPI / LCLIntf 구현 품질

**전체 평가: 9/10** — 193개 중 183개 실제 구현

| 카테고리 | 구현율 | 세부사항 |
|----------|--------|----------|
| Drawing/Graphics | 95% | Cairo 통합 완전, StretchMaskBlt 실제 구현 |
| Regions/Clipping | 90% | Cairo region, 복잡 클립 보존 (`GetClipRGN` ExcludeClipRect 대응) |
| Device Context | 98% | Cairo save/restore, 좌표 변환 완전 |
| Window Management | 92% | Wayland 제한 주석 |
| Focus/Activation | 85% | GTK4 엄격 포커스 모델 |
| Caret Management | 100% | **완전** — Session 59 안전성 수정 포함 |
| Keyboard/Input | 80% | Wayland 제약 |
| Mouse/Cursor | 95% | CSD 오프셋 보정 |
| Clipboard | 90% | async→sync 래핑 (g_main_loop_run) |
| System Metrics | 95% | 모니터 열거 완전 |
| Font/Text | 98% | Pango 완전 통합 |
| Messages/Events | 85% | PostMessage 안전성 확보 (Session 59) |
| LCL-Specific | 92% | RawImage 복잡 형식 변환 포함 |
| GDI Objects | 90% | ref-counted 객체 관리 |

**Stub 함수 목록 (10개):**
1. `CallNextHookEx` — Windows 훅 체인 N/A
2. `EnableScrollBar` — 미지원 (GTK2/Qt5도 동일)
3. `CreatePatternBrush` — 패턴 시맨틱 차이
4. `CreatePalette` — 8비트 팔레트 레거시
5. `RealizePalette` — 팔레트 관리 (0 반환)
6. `PeekMessage` — GTK4에 TMsg 큐 없음
7. `GetAsyncKeyState` — 상속 stub
8. `SelectPalette` — 최소 구현
9. `GetDpiForMonitor` — 하드코딩 가능
10. `DestroyIcon` — 부분적

---

### 22f. ComCtrls (ListView/TabControl/StatusBar/ToolBar/Page) 구현 품질

**전체 평가: 8/10** — TabControl 완전, ListView 대부분 동작하나 정렬/DnD 미완

| 컨트롤 | 메서드 | 구현율 | 핵심 이슈 |
|--------|--------|--------|----------|
| TabControl/Notebook | 15 | **100%** | CSS 기반 SetTabSize (GTK4 고유, GTK2 미지원) |
| CustomPage | 7 | **86%** | **DestroyHandle MISS** (TGtk4Widget 메커니즘으로 대체) |
| ListView | 60+ | **~92%** | SetSort 미구현, ColumnView 제약 |
| StatusBar | 5 | **80%** | SetSizeGrip NO-OP (GTK4에서 GtkStatusBar 제거), **SetPanelText 가드레일 3중 nil 체크** |
| ProgressBar | 3 | **100%** | 이슈 없음 |
| TrackBar | 4 | **100%** | WS 48줄 + **TGtk4Range 래퍼 95줄** (부모 클래스) + **SetTickMarks 44줄** (네이티브 눈금). SetOrientation: RecreateWnd (Qt5는 동적 변경) |
| ToolBar | 1 | **100%** | WS 8줄 + **래퍼 50줄** (GtkOverlay+DrawingArea 3-depth 위젯) — GTK4에서 GtkToolbar 제거 대응 |

**ListView 핵심 품질 이슈:**

| 이슈 | 심각도 | 세부사항 |
|------|--------|----------|
| ~~**SetSort() 미구현**~~ | ~~**높음**~~ | ✅ **수정됨 (Session 61)**: `ModelNotifyItemsChanged` — ColumnView: `g_list_model_items_changed(0, N, N)`, TreeView: model clear+re-insert. **GTK4 > GTK2** (GTK2는 여전히 queue_draw만) |
| **ColumnMove (ColumnView)** | 중간 | ColumnView에서 early exit — 컬럼 재배치 불가 |
| **GetDropTarget (ColumnView/GridView)** | 중간 | Drag-drop 미지원으로 exit |
| **ItemSetChecked 플랫폼 비저장** | 낮음 | TListItem에 상태 저장 + queue_draw (렌더러가 읽음). GTK2는 GtkListStore 컬럼에 직접 저장 |
| **ItemSetStateImage** | 낮음 | ColumnView에서 state image 미지원 |
| **GetFocused (ColumnView) 근사치** | 중간 | `gtk4_bitset_get_minimum` = 첫 번째 선택 → 포커스 근사치 (GTK4.6에 focus/cursor API 부재) |
| **ItemShow/ItemGetPosition/GetTopItem** | 낮음 | ColumnView/GridView: adjustment 기반 **근사치** (위젯 재활용으로 정확한 위치 불가) |
| **SetViewStyle** | 주의 | vsReport↔vsIcon 전환 시 항상 RecreateWnd (모든 플랫폼 동일) |
| **lvpColumnClick/lvpShowColumnHeaders** | 중간 | GTK4.6 ColumnView에 headers_clickable/headers_visible API 부재 |

**ListView 아키텍처 비교 (§4 상세 테이블 참조):**

| 관점 | GTK4 | GTK2 | Qt5 |
|------|------|------|-----|
| WS 코드 패턴 | 1줄 위임문 → TGtk4ListView 래퍼 | GtkTreeView/GtkListStore 직접 API | TQtTreeWidget/TQtListWidget 래퍼 |
| 데이터 모델 | GtkTreeModel + CellRendererFactory | GtkListStore 직접 조작 | QTreeWidgetItem 노드 |
| 체크 상태 | TListItem 저장 + 렌더러 의존 | GtkListStore 컬럼 저장 | QTreeWidgetItem.checkState |
| ColumnDelete | 래퍼 위임 (효율적) | TreeViewColumn 직접 제거 | **RecreateWnd 강제** (Qt 제한) |

**ColumnView vs TreeView API 차이:**

GTK4는 GtkColumnView(신규, 제한적)와 GtkTreeView(레거시, 완전) 두 모델을 사용:
- vsReport → GtkColumnView (GTK4.2+): headers_clickable, drag-reorder, sort 미지원
- vsIcon/vsList → GtkGridView: 단순 그리드, 근사치 위치 계산
- TreeView (레거시): 모든 기능 완전
- **ColumnView 위젯 재활용**: GTK4 virtualization으로 인해 정확한 위치/포커스 API 제공 불가

---

---

### 22i. Dialog 구현 품질

**전체 평가: 7/10** — 핵심 다이얼로그 동작하나 dead code, deprecated API, 취약한 설계 있음. §6 상세 테이블 참조.

| 다이얼로그 | 점수 | 상태 | 세부사항 |
|-----------|------|------|----------|
| CommonDialog | 8/10 | **실구현** | ShowModal: `present()` + **DoExecute 중첩 이벤트 루프** (gtk_dialog_run 대체). GTK2는 `gtk_dialog_run` 한 줄 |
| FileDialog | 6/10 | **최소** | ~26줄 dead GTK2 코드. **실제 로직은 TGtk4FileDialog 래퍼 클래스에 위임** |
| OpenDialog | 8/10 | **포괄적** | 필터 파싱, 멀티선택, 히스토리, 프리뷰 지원. GTK4 `gtk4_file_chooser_get_files` (GListModel) 사용 |
| SaveDialog | 7/10 | **최소** | TGtk4FileDialog 생성자의 `is TSaveDialog` 타입 체크로 동작 |
| SelectDirectoryDialog | 6/10 | **불완전** | **CreateHandle 명시적 override 없음** — 암묵적 상속+타입체크 의존 |
| ColorDialog | 8/10 | **완전** | GtkColorChooserDialog. GTK4의 GdkRGBA(float) 변환 정확. 알파 비활성 (LCL 설계) |
| FontDialog | 7/10 | **대부분 완전** | GtkFontChooserDialog. **Strikeout/Underline 편집 불가** (보존만 — 텍스트 속성이지 폰트 속성 아님) |

**GTK4 API 마이그레이션 상태:**

| GTK3/2 API | GTK4 대체 | 상태 |
|-----------|----------|------|
| `gtk_dialog_run()` | `present()` + DoExecute 루프 | ✓ 완료 |
| GTK_STOCK_* | 일반 텍스트 라벨 | ✓ 완료 |
| `gtk_file_chooser_get_filename` | `gtk4_file_chooser_get_file` (GFile*) | ✓ 완료 |
| `gtk_file_chooser_list_filters()` | `gtk4_file_chooser_get_filters()` (GListModel) | ✓ 완료 |
| GtkColorSelectionDialog | GtkColorChooserDialog | ✓ 완료 |
| GtkFontSelectionDialog | GtkFontChooserDialog | ✓ 완료 |
| GtkDialog button→response | 수동 `gtk_dialog_response()` 브릿지 (4.10+) | ✓ 완료 |

**주요 이슈:**
1. ~~**🔴 BUG: SaveDialog.QueryWSEventCapabilities**~~ ✅ **수정됨 (Session 61)** — 5개 다이얼로그(Font/Open/Save/SelectDir/Color) 모두 `cdecWSNoCanCloseSupport` 추가. Qt5/Win32와 동일
2. **🔴 FontDialog fdApplyButton 미동작** — GtkFontChooserDialog에 Apply 버튼 없음. `OnApplyClicked` 이벤트 절대 발동 안됨
3. **FontDialog PreviewText 미지원** — GtkFontChooserDialog에서 `set_preview_text()` API 제거됨
4. ~~**Dead code**~~ ✅ **수정됨 (S61)** — Dialog 데드코드 ~90줄 삭제, TGtk4ColorSelectionDialog ~55줄 삭제
5. **Deprecated API (GTK 4.10)** — `GtkDialog`, `GtkFileChooserDialog` deprecated, GTK 5.0에서 제거 예정
6. **SelectDirectoryDialog 명시적 override 부재** — 암묵적 상속 의존으로 향후 변경 시 깨질 위험
7. **FontDialog strikeout/underline** — GtkFontChooserDialog에 해당 컨트롤 없음 (텍스트 속성, 폰트 속성 아님)
8. **프리뷰 구현 취약** — `CreatePreviewDialogControl`이 `GroupBox → Image` 계층 가정 (다른 레이아웃에서 실패)
9. ~~TGtk4DialogBtnInfo 메모리 누수~~ **✅ R29 수정 확인** — `g_signal_connect_data` + `Gtk4DialogBtnInfoFreeCB` destroy_notify로 GLib 자동 해제
10. ~~**콜백 함수명 오류**~~ ✅ **수정됨 (S61)** — `Gtk4FileChooserResponseCB`/`Gtk4FileChooserNotifyCB`로 변경

---

### 22j. Graphics / Painting 구현 품질

**전체 평가: 9/10** — Cairo+Pango 통합 완전, 네이티브 더블 버퍼링 10/10, StretchBlt GTK2보다 우수. **Session 56**: TGdkRGBA gdouble→gfloat 수정으로 시스템 색상 100% 정상화. **Session 60**: DrawGrid cairo 재작성, IsDesignerDC 구현, DoBeforeLCLPaint Form 배경 채움. **Session 61**: GetPixel 메모리 누수/create_stipple/클립 반올림 수정. **Session 62**: drawText BkMode TRANSPARENT 가드 + Pango AttrList double-free/leak 수정. ~~감점 요인: TRANSPARENT 브러시 STUB~~ ✅ 완료

#### Device Context (TGtk4DeviceContext)

| 기능 | 상태 | 세부사항 | 라인 |
|------|------|----------|------|
| Create(AWidget) | **완전** | Cairo image surface 폴백 포함 | gtk4objects.pas:1696-1752 |
| Create(AWindow) | **부분 stub** | GTK4에서 gdk_cairo_create 제거 → 1x1 image surface 폴백 | 1754-1781 |
| CreateFromCairo | **완전** | cairo_clip_extents로 클립 추출 | 1783-1812 |
| Save/Restore | **완전** | cairo_save/restore + SaveDCCount 카운터. 음수 인덱스(-1,-2..) 지원 | gtk4winapi.inc:4587-4598, 4550-4576 |
| Clipping | **완전** | cairo_region_t 기반, 직사각형/복합 클립 | 291+ |
| Text rendering | **완전** | Pango layout, 색상 변환 정확. S62: AttrList double-free/leak 수정, BkMode+배경 속성 보존 (underline/strikeout 유실 방지) | |
| SelectObject/DeleteObject | **완전** | Pen/Brush/Font/Bitmap 타입 분기, refcount 이슈 없음 | |
| ~~**GetPixel**~~ | ~~🔴 메모리 누수~~ ✅ **수정됨 (Session 61)** | try/finally + `g_object_unref(PGObject(pixbuf))` 추가 | gtk4objects.pas:1882-1897 |
| **StretchBlt** | **GTK2보다 우수** | Cairo matrix transformation으로 확대/축소/뒤집기 일괄 처리. GTK2는 개별 경우 분기 | |
| **DoubleBuffering** | **네이티브 10/10** | GTK4 compositor가 자동 제공 (GtkSnapshot→GskRenderer→GPU). 수동 버퍼 관리 불필요 | |

**🔴 클립 사각형 반올림 문제** (gtk4widgets.pas:2960-2964):
```
Trunc(cx1/cy1) + Ceil(cx2/cy2) → 우하단에서 1-2 px 오차 가능
올바른 방법: Floor(top-left), Ceil(bottom-right)
```

#### Brush (TGtk4Brush) — 85% 완전

| 패턴 | 지원 | 크기 | 비고 |
|------|------|------|------|
| BS_SOLID | ✓ | N/A | |
| BS_NULL | ✓ | N/A | |
| BS_HATCHED (6종) | ✓ | 4x4 / 8x8 stipple | |
| BS_PATTERN | ✗ | 미구현 | |
| BS_DIBPATTERN | ✗ | stub | |
| ~~**TRANSPARENT 모드**~~ | ~~**🔴 STUB**~~ | ✅ **수정됨 (S61+S62)** | S61: `ApplyBrush`에서 TRANSPARENT와 무관하게 brush color 설정 (solid fill 정상). S62: `drawText`에서 `UseBack := (FBkMode <> TRANSPARENT)` 가드 추가 — TRANSPARENT 시 텍스트 배경 미표시 |

~~**🔴 BUG: create_stipple 파라미터**~~ (gtk4objects.pas:1486): ✅ **수정됨 (S61)**: `create_stipple(PByte(pat_buf), w, h)` — w,w → w,h 교정 완료.

**Byte order 우려** (gtk4objects.pas:1480-1481):
- Cairo ARGB 네이티브 바이트 순서 가정, 명시적 검증 없음
- Little-endian에서 해치 색상 반전 가능성

#### Pen (TGtk4Pen) — 100% 완전

| 기능 | 상태 | 라인 |
|------|------|------|
| psSolid/psDash/psDot/psDashDot/psDashDotDot | **완전** | 1660-1673 |
| psPattern (custom dash) | **완전** | GetDashArray/GetDashCount |
| EndCap (Round/Square/Flat) | **완전** | 1675-1687 |
| JoinStyle (Round/Bevel/Miter) | **완전** | 1689-1693 |
| Cosmetic (1px) vs Geometric | **완전** | 1650-1658 |
| PenMode (Copy/XOR/Black/White) | **부분** | pmNotXor=XOR로 매핑 (잘못됨, 1633) |

#### Font (TGtk4Font) — 95% 완전

| 기능 | 상태 | 라인 | 비고 |
|------|------|------|------|
| Family/Size/Weight/Style | **완전** | PangoFontDescription | |
| Strikeout/Underline | **완전** | PangoAttrList로 적용 (937-952) | |
| Quality (antialiasing) | **완전** | cairo_set_antialias 매핑 (897-935) | 5단계: DEFAULT→CAIRO_ANTIALIAS_DEFAULT, DRAFT→GOOD, PROOF→BEST, NONANTIALIASED→NONE, CLEARTYPE→SUBPIXEL |
| Escapement (회전) | **완전** | Pango rotation | |
| CharSet | **보존만** | Pango에 직접 적용 불가 | |

#### RawImage 변환

| 입력 형식 | 상태 | 라인 | 비고 |
|----------|------|------|------|
| 1-bit | **완전** | gtk4lclintf.inc:237-241 | CAIRO_FORMAT_A1 직접 |
| 8-bit (팔레트) | **완전** | 242-295 | TLazIntfImage 경유 확장 |
| 8-bit (그레이스케일) | **완전** | 242-295 | G→RGBA 확장 |
| 16-bit (RGB565) | **완전** | 297-320 | Little-endian 가정 |
| 24-bit | **완전** | 322-350 | 32bpp 정규화, RGB 인덱스 순서 존중 |
| 32-bit (α=0 검출) | **완전** | 383-428 | 별도 마스크 시나리오: α=$FF 채움 |
| 마스크 (1-bit/8-bit) | **완전** | 458-531 | A8 알파로 변환 |

**🔴 CRITICAL: RawImage_CreateBitmaps DataOwner** (gtk4lclintf.inc:450):
```pascal
ABitmap := HBitmap(TGtk4Image.Create(NewData, ..., true));  // DataOwner=True 무조건
```
- NewData가 TGtk4Image destructor에서 FreeMem됨
- Cairo surface가 이미 데이터 참조 해제한 후이므로 현재는 정상이나, 수명 관리 취약

#### Session 56-60 품질 개선 (R29 추가)

| 수정 | 세션 | 세부사항 | 라인 |
|------|------|----------|------|
| **TGdkRGBA gdouble→gfloat** | S56 | GTK4는 GdkRGBA 필드를 float로 변경 (GTK3: double). 바인딩 수정으로 전체 시스템 색상(clWindow, clBtnFace 등) 정상 해석. `get_color`/`get_border`/`get_margin`/`get_padding` 서명도 state 파라미터 제거 | lazgdk4.pas:4474-4478, lazgtk4.pas:7559-7564 |
| **DrawGrid 재작성** | S60 | 기존 ExcludeClipRect+LineTo → `cairo_rectangle` + `cairo_fill` 개별 도트 그리기로 교체. 디자이너 그리드 정상 렌더링 | gtk4lclintf.inc:76-91 |
| **IsDesignerDC 구현** | S60 | `csDesigning` 검사 + Context 매칭 검증. 없으면 ALL 위젯이 True 반환 → 아이콘 사라짐. `override` 키워드 필수 | gtk4lclintf.inc:94-105 |
| **Form DoBeforeLCLPaint** | S60 | TGtk4Window.DoBeforeLCLPaint override — `LCLObject.Color`로 Form 배경 채움. 디자이너에서 Form 배경색 정상 표시 | gtk4widgets.pas:11333 |

#### Paint Cycle

| 단계 | 상태 | 세부사항 |
|------|------|----------|
| Double-buffering | **네이티브** | GTK4 컴포지터가 자동 제공 — GTK2보다 우수 |
| GtkDrawingArea draw_func | **완전** | Gtk4PaintAreaDrawFunc → GtkEventPaint |
| 클립 영역 전달 | **완전** | cairo_clip_extents → PaintStruct |
| DoBeforeLCLPaint | **완전** | 배경 채움, 보더 그리기. **S60**: Form/Panel 각각 Color 기반 배경 채움 |
| 캐럿 표시 | **완전** | 소프트웨어 캐럿, paint 후 그리기 |
| WM_ERASEBKGND | **미전달** | GTK4 설계 — 배경은 GTK가 처리 |

**추가 품질 이슈:**

| 이슈 | 상태 | 영향 |
|------|------|------|
| **ROP 코드 지원** | StretchMaskBlt에서 Rop 파라미터 **완전 무시** (gtk4winapi.inc:5570-5673). 펜 모드 pmCopy/pmXor만 구현, 11개 주석 처리 | Windows 포팅 코드 그리기 모드 오류 |
| ~~**SaveDC/RestoreDC 스태킹**~~ | ✅ **실제 구현됨** — SaveDC(gtk4winapi.inc:4587-4598) cairo_save+카운터, RestoreDC(4550-4576) 음수 인덱스 지원 | ~~중첩 DC 상태 관리 불가~~ → 정상 동작 |
| **getPixel** | 단일 픽셀에 임시 pixbuf 생성 | 성능 비효율 |
| **GetCharABCWidths** | stub — `Result := False` (gtk4winapi.inc:2487-2492). Win32 전용, GTK2/Qt5도 동일 | ABC 문자 너비 미제공 |
| ~~**TRANSPARENT 모드**~~ | ~~stub~~ | ✅ **수정됨 (S61+S62)** |
| **ROP2 미적용** | GetROP2/SetROP2 존재하나 R2_COPYPEN 초기화 후 드로잉에 반영 안됨 | 래스터 연산 미동작 |
| ~~**RGN_DIFF**~~ | ~~미구현~~ | ✅ **오보정 (S61)**: 실제 구현됨 (gtk4winapi.inc:2019-2051) |

**GTK2 대비 비교:**

| 기능 | GTK2 | GTK4 | 결과 |
|------|------|------|------|
| Double-buffering | GdkPixmap 수동 | 컴포지터 네이티브 | GTK4 **우수** |
| Device Context | GdkGC + GdkDrawable | Cairo + GtkWidget | **동등** |
| Brush 패턴 | GdkBitmap stipple | Cairo pattern surface | **동등** |
| Font 메트릭 | GdkFont (deprecated) | Pango + Cairo | GTK4 **우수** |
| RawImage | GdkPixbuf 직접 | Cairo surface → GdkPixbuf | GTK4 **더 느림** (안전) |
| ROP 코드 | 완전 (16종) | 2종만 | GTK4 **부족** |
| SaveDC/RestoreDC | 완전 | ✅ 구현됨 (cairo_save+카운터, 음수인덱스) | **동등** |

---

### 22k. Buttons / Calendar / SpinEdit 구현 품질

**전체 평가: 8/10** — 견고한 구현, Calendar 버그 1건, BitBtn 리빌드 비효율. §1, §2, §12, §13 상세 테이블 참조.

#### BitBtn

| 메서드 | 점수 | 세부사항 | 라인 |
|--------|------|----------|------|
| CreateHandle | 9/10 | TGtk4Button 래핑, 정상 | gtk4wsbuttons.pp:82-105 |
| GetPreferredSize | 10/10 | 테마 인식 preferredSize 위임 | 107-113 |
| SetGlyph | 8/10 | GtkBox(GtkImage+GtkLabel) 구성. **Pixbuf 수명 관리 주의** | 115-204 |
| SetLayout | 8/10 | RebuildButtonChild 호출 | 254-264 |
| SetMargin | 9/10 | halign/valign + margin 방향별 설정 | 266-276, TGtk4Button:10031-10091 |
| SetSpacing | 9/10 | 방향별 마진 적용 | 278-288, TGtk4Button:10093-10126 |
| RebuildButtonChild | 6/10 | **매번 GtkBox 재생성** — 성능 비효율 | 206-252 |

**BitBtn 위젯 트리:**
```
GtkButton
  └── GtkBox (H/V, Spacing=FSpacing)
      ├── GtkImage (from Pixbuf)
      └── GtkLabel (underline 지원)
```

**이슈:**
1. `RebuildButtonChild` — SetLayout/SetMargin/SetSpacing 매 호출 시 GtkBox+GtkImage+GtkLabel **전체 재생성**. 기존 위젯 포인터 재사용 안됨 → O(변경횟수) 재할당
2. Pixbuf refcount — `Gtk4BitmapToPixbuf` → `gtk_image_new_from_pixbuf` 소유권 이전 시맨틱 불명확

#### Button

| 메서드 | 점수 | 라인 |
|--------|------|------|
| CreateHandle | 9/10 | TGtk4Button 래핑 |
| SetDefault | 8/10 | gtk_widget_set_can_default (10213-10217) |
| SetShortcut | 8/10 | accelerator 매핑 |

#### Calendar

| 메서드 | 점수 | 세부사항 | 라인 |
|--------|------|----------|------|
| CreateHandle | 7/10 | GtkCalendar를 불필요한 GtkFrame으로 래핑 | gtk4wscalendar.pp:113-151 |
| GetDateTime | 9/10 | 0-based month 올바르게 처리 | 153-167 |
| **SetDateTime** | **🔴 5/10** | **Month off-by-one 버그!** | 284-292 |
| HitTest | 10/10 | gtk4_widget_pick 기반 포괄적 위젯 트리 순회 | 169-282 |
| SetDisplaySettings | 9/10 | GObject properties 사용 (show-heading 등) | 294-323 |
| SetFirstDayOfWeek | STUB | GTK4 로케일 기반만 — API 부재 (의도적) | 335-340 |
| SetMinMaxDate | 8/10 | day-selected 시그널 콜백으로 클램핑 | 342-347 |
| RemoveMinMaxDates | 8/10 | 시그널 해제 + 제한 클리어 | 349-354 |
| GetPreferredSize | 9/10 | ✅ **S61 구현**: preferredSize 래퍼 위임 | 328-333 |

~~**🔴 CRITICAL BUG: Calendar SetDateTime month off-by-one**~~ ✅ **수정됨 (Session 61)** (gtk4wscalendar.pp:291):
```pascal
DecodeDate(ADateTime, Year, Month, Day);  // Month는 1-based
TGtk4Calendar(ACalendar.Handle).SetDate(Year, Month - 1, Day);  // ✅ 0-based 변환 적용
```
- `ClampDate` (gtk4widgets.pas:5692)와 동일한 `M - 1` 패턴 적용

#### SpinEdit

| 메서드 | 점수 | 세부사항 | 라인 |
|--------|------|----------|------|
| CreateHandle | 9/10 | GtkSpinButton.new_with_range | gtk4wsspin.pp:56-63 |
| GetPreferredSize | 8/10 | preferredSize 위임 | 65-72 |
| GetSelStart/Length | 9/10 | gtk_editable_get_selection_bounds | 74-90 |
| SetSelStart/Length | 8/10 | BeginUpdate/EndUpdate 래핑 | 101-119 |
| SetReadOnly | 9/10 | EditorEnabled 상호작용 처리 | 122-139 |
| SetAlignment | 8/10 | TGtk4Entry.Alignment 위임 | 141-147 |
| SetEditorEnabled | 9/10 | ReadOnly 상태 존중 | 149-161 |
| UpdateControl | 10/10 | 범위/자릿수/증감/numeric 플래그 포괄적 | 163-195 |

#### SpinEdit 추가 이슈 (GTK2 대비)

| 이슈 | GTK4 | GTK2 | 영향 |
|------|------|------|------|
| **소수점 구분자 처리** | **누락** | 국제화 변환 있음 (gtk2wsspin.pp:103-112) | 로케일별 소수점 표시 오류 가능 |
| **ReadOnly adjustment bounds** | **누락** | bounds 조작으로 버튼 비활성 | ReadOnly spinbox에서 증감 버튼 클릭 가능 |
| **LockOnChange 패턴** | **누락** | BeginUpdate/EndUpdate 래핑 | UpdateControl 중 spurious change 이벤트 |

#### Panel / Splitter

| 컨트롤 | 점수 | 세부사항 |
|--------|------|----------|
| Panel CreateHandle | 9/10 | GtkOverlay → [GtkFixed(자식) + GtkDrawingArea(paint)] |
| Panel GetDefaultColor | 8/10 | clBackground/clBtnText 상수 반환 |
| Panel SetBorderStyle | 8/10 | DoBeforeLCLPaint에서 보더 그리기 |
| **Splitter** | **6/10** | **GtkPaned 미사용** — GtkPanel + LCL 수동 드래그 로직. 네이티브 분할선 드래그 불가 |

#### Calendar 추가 이슈

| 이슈 | 상태 | 라인 |
|------|------|------|
| ~~GetPreferredSize~~ | ~~주석 처리됨~~ | ✅ **수정됨 (Session 61)**: preferredSize 래퍼 위임 구현 |
| ~~month/year/day 변경 콜백~~ | ~~미등록~~ | ✅ **수정됨 (S62)**: CreateWidget에서 day-selected/month-changed/prev-month/next-month/prev-year/next-year 6개 시그널 연결 → LM_DAYCHANGED/LM_MONTHCHANGED/LM_YEARCHANGED 메시지 전달 + dead code ~50줄 삭제 |
| GtkFrame 불필요 래핑 | 빈 프레임, 불필요한 위젯 중첩 | gtk4widgets.pas:5623 |
| ~~SpeedButton~~ | ~~완전 stub~~ | **오보정**: TGraphicControl (non-windowed) — WS 구현 불필요. GTK2/Qt5/Win32도 동일 빈 클래스. WSFactory 등록도 주석 |

---

### 22l. Menu / TrayIcon 구현 품질

**전체 평가: 7.5/10** — GMenu 모델 정확 구현, 성능/보안 우려 있음. §11 상세 테이블 참조.

#### Menu (gtk4wsmenus.pp)

| 메서드 | 점수 | GTK4 구현 | GTK2 비교 | Qt5 비교 |
|--------|------|----------|----------|---------|
| MenuItem.CreateHandle | 7/10 | `TGtk4MenuItem.Create()` 래퍼만 | **GTK2: 아이템 타입별 위젯 + 6 콜백** | 중간 |
| MenuItem.SetCaption | 6/10 | `g_menu_item_set_label` + **전체 리빌드** | `UpdateInnerMenuItem` O(1) | `setText` O(1) |
| MenuItem.SetCheck | 8/10 | GAction state toggle 정확 | `gtk_check_menu_item_set_active` + 라디오 잠금 | `setChecked` |
| MenuItem.SetEnable | 8/10 | GAction enabled 속성 | `gtk_widget_set_sensitive` | `setEnabled` |
| MenuItem.SetRadioItem | 5/10 | **RecreateHandle** (GTK4=GTK2 동일) | **RecreateHandle** | Qt5만 인플레이스 변경 |
| MenuItem.**SetShortCut** | **9/10** | GDK keyval + accel 속성 + 리빌드. **실제 가속키 바인딩** | 텍스트 표시만 ("Temporary" 주석) | `setShortcut` 위임 |
| MenuItem.SetVisible | 6/10 | **전체 리빌드** (비가시 아이템 모델에서 제외) | `gtk_widget_show/hide` O(1) | `setVisible` O(1) |
| MenuItem.**SetRightJustify** | **2/10** | `True` 반환하나 **NO-OP** (GtkPopoverMenuBar 제한) | `gtk_menu_item_set_right_justified` 완전 | Qt attribute 설정 |
| MenuItem.AttachMenu | 7/10 | `Gtk4RebuildMenuModel` + 서브메뉴 섹션 연결 | 개별 삽입 O(1) | `insertMenu` O(1) |
| MenuItem.UpdateMenuIcon | 7/10 | pixbuf→PNG→GBytesIcon + **전체 리빌드** | `RecreateHandle` | `RecreateHandle` |
| Menu.CreateHandle | 8/10 | TGtk4MenuBar + form GMenu/GActionGroup 공유 | GtkMenuBar + pack_direction 설정 | TQtMenuBar 래핑 |
| Menu.**SetBiDiMode** | **5/10** | `Widget^.set_direction` 단순 설정 | **재귀** pack 방향 + 자식 전체 업데이트 | 방향 속성 설정 |
| PopupMenu.Popup | 8/10 | GtkPopoverMenu + **중첩 g_main_loop_run()** 블로킹 | **커스텀 위치 콜백** + 블로킹 루프 | `Exec(@Point)` 블로킹 |

**GMenu 모델 아키텍처 문제:**

GTK4는 선언적 GMenu 모델 + GAction을 사용하므로, 개별 아이템 속성 변경이 불가하고 매번 전체 모델을 리빌드해야 함:
- `Gtk4RebuildMenuModel` (gtk4wsmenus.pp:365-390): 모든 메뉴 아이템 순회 → 새 GMenu 구성
- `SetCaption`/`SetVisible`/`UpdateMenuIcon` 호출 시마다 **O(n) 리빌드**
- n개 아이템 초기화 시 총 비용: **O(n²)**
- **영향**: 대규모 메뉴(100+ 아이템)에서 느린 초기화/업데이트
- **GTK2/Qt5 대비**: 개별 위젯 속성 변경 O(1) — 근본적 아키텍처 차이

**SetRadioItem 비용:** (gtk4wsmenus.pp:544)
- GAction을 stateful 토글로 변경해야 하므로 **핸들 전체 재생성** (`RecreateHandle`)
- Radio→Normal 또는 Normal→Radio 전환 시 GMenuModel+GAction 재구성
- **Qt5만** `removeActionGroup` + `setCheckable` 인플레이스 변경 가능

**SetShortCut — GTK4가 최고 품질:**
- GTK4: `LCLKeyToGdkKeyval` → `gtk_accelerator_name` → `g_menu_item_set_attribute_value('accel')` — 실제 GDK 가속키 바인딩
- GTK2: `UpdateInnerMenuItem` — 주석에 "Temporary: At least it writes the names" → 텍스트 표시만, 바인딩 미구현
- Qt5: `setShortcut` — 프레임워크 위임

#### TrayIcon (gtk4wstrayicon.pas) — StatusNotifierItem D-Bus 구현

§7 상세 테이블 참조. GTK4 TrayIcon은 **전체 SNI D-Bus 프로토콜 구현** — GTK2(GtkStatusIcon deprecated)/Qt5(QSystemTrayIcon) 대비 **가장 깊은 구현**.

| 메서드 | 점수 | 세부사항 |
|--------|------|----------|
| Show | 8/10 | `g_bus_get_sync` + `g_dbus_node_info_new_for_xml` + `g_dbus_connection_register_object` 전체 SNI 등록 |
| Hide | 8/10 | D-Bus 객체 해제 + `g_dbus_connection_unregister_object` |
| InternalUpdate | 8/10 | pixbuf→PNG→GBytesIcon 인코딩 + D-Bus 프로퍼티 변경 시그널 |
| GetPosition | **3/10** | **항상 (0,0) 반환** — SNI 스펙에 위치 정보 없음 |
| ShowBalloonHint | 9/10 | `g_notification_new` + `g_application_send_notification` GNotification API. **GTK2 미구현** |
| GetCanvas | 8/10 | 아이콘 캔버스 반환 |

**주요 이슈:**
1. **GetPosition 항상 (0,0)** — SNI 프로토콜에 트레이 아이콘 위치 개념 없음. 패널/데스크톱 환경에 따라 위치 결정됨
2. **아이콘 저장 보안** — PNG를 `/tmp`에 world-readable로 저장. `XDG_RUNTIME_DIR` 사용 권장
3. **블로킹 D-Bus 호출** — `RegisterWithWatcher`에서 무한 타임아웃 블로킹 호출. Watcher가 응답 안하면 앱 중단
4. **SNI 가용성** — KDE Plasma, GNOME(appindicator 확장), XFCE는 지원. 일부 WM에서 미동작
5. **dbusmenu-glib 의존** — 컨텍스트 메뉴를 D-Bus로 노출하기 위해 libdbusmenu-glib 필요

---

### 22i. GTK4 WS→래퍼 위임 아키텍처 분석 (R30 신규)

GTK4 LCL은 GTK2/Qt5와 **근본적으로 다른 코드 구조**를 사용한다. 이를 이해하지 않으면 WS 코드만으로 품질을 오판할 수 있다.

#### 아키텍처 비교

| 구분 | GTK2 | Qt5 | GTK4 |
|------|------|-----|------|
| **WS 코드 위치** | WS 클래스에서 직접 `gtk_*` API 호출 | WS 클래스에서 직접 `Q*` API 호출 | WS 클래스 → **TGtk4* 래퍼 클래스** 위임 |
| **실제 구현 파일** | gtk2ws*.pp (분산) | qt5ws*.pp (분산) | **gtk4widgets.pas** (집중) |
| **WS 메서드 평균 줄수** | 15-40줄 (직접 API) | 5-15줄 (프레임워크 위임) | **3-8줄** (래퍼 위임문) |
| **래퍼 메서드 평균 줄수** | N/A | N/A | **10-50줄** (실제 GTK4 API 호출) |

#### 코드 분포 통계 (R30 측정)

| 위젯 클래스 | WS 코드 (줄) | 래퍼 코드 (줄) | **실질 총합** | GTK2 WS 코드 (줄) |
|------------|------------|-------------|-------------|------------------|
| ProgressBar | 42줄 | **160줄** (5805-5964) | **202줄** | 77줄 |
| ToolBar | 8줄 | **50줄** (5982-6027) | **58줄** | 12줄 |
| TrackBar | 48줄 | **95줄** TGtk4Range (5395-5489) + **44줄** SetTickMarks (5468-5511) | **187줄** | ~50줄 |
| Panel | 32줄 | **68줄** (4790-4857) | **100줄** | 115줄 |
| HintWindow | 12줄 | **30줄** (11734-11766) | **42줄** | ~25줄 |
| ScrollingWinControl | 10줄 | **35줄** (10490-10524) | **45줄** | 70줄 |
| Window | ~50줄 | **~700줄** (10526-11409+) | **~750줄** | ~300줄 |
| ListView | ~350줄 | **~1200줄** | **~1550줄** | ~800줄 |

#### 품질 판독 지침

1. **WS 코드만으로 품질 판단 금지**: WS 클래스에서 `TGtk4*.Property := Value` 1줄은 래퍼에서 **10-50줄**의 실제 GTK4 API 호출을 감추고 있음
2. **래퍼 코드 참조 방법**: WS 메서드의 `TGtk4*(Handle)` 캐스트 → gtk4widgets.pas에서 해당 클래스 검색
3. **GTK4 실질 코드량**: WS+래퍼 합산 시 GTK2보다 **평균 1.5-2배** 많음 (추상화 오버헤드 포함)
4. **장점**: 중앙 집중 유지보수 (래퍼 수정 → 모든 WS 호출자 자동 반영), 공통 패턴 재사용 (BeginUpdate/EndUpdate, IsWidgetOk 검증)
5. **단점**: 감사(audit) 어려움 (WS 코드만 읽으면 구현 깊이 오판), 래퍼 버그 시 광범위 영향
6. **(R32) 예외**: PairSplitter (gtk4wssplitter.pas)는 래퍼에 위임하지 않고 WS에서 GtkPaned API 직접 호출. TGtk4Paned 래퍼는 9줄 최소 구현 (CreateWidget만). ImageList은 WS/래퍼 모두 없음 (LCL 수준 순수 처리)

#### ProgressBar 전체 구현 맵 (R30 심층 분석 예시)

```
WS 계층 (gtk4wscomctrls.pp)           래퍼 계층 (gtk4widgets.pas)
─────────────────────────────         ─────────────────────────────────
CreateHandle(8줄)  ──────────→  TGtk4ProgressBar.CreateWidget(12줄)
  TGtk4ProgressBar.Create              GtkBox(V) → GtkProgressBar
                                        set_hexpand/vexpand(True)
                                      InitializeWidget(7줄)
                                        set_size_request(W,H)
                                      get_progress_preferred_width(18줄)
                                        GType vfunc 패치

ApplyChanges(13줄)  ─────────→  SetPosition(14줄): fraction 계산
  BeginUpdate/EndUpdate               SetOrientation(17줄): 4방향 분기
  4개 프로퍼티 일괄                    SetShowText(3줄): 직접 API
                                      SetStyle(16줄): pulse 타이머

SetPosition(9줄)  ───────────→  SetPosition(14줄)
  BeginUpdate/EndUpdate               (Max-Min)/fraction 수학
                                      PGtkProgressBar.set_fraction

SetStyle(10줄)  ─────────────→  SetStyle(16줄)
  BeginUpdate/EndUpdate               Normal: Position 복원
                                      Marquee: g_timeout_add(100ms)
                                      + ProgressPulseTimeout(8줄)
                                      + ProgressDestroy(4줄)
                                합계: WS 42줄 + 래퍼 117줄 = 159줄
```

---

### 22g. 전체 구현 품질 종합 (per-method 분석 반영)

45개 WS 클래스 + LCLIntf 35개 + WinAPI 196개 = **340+ 메서드**의 GTK4/GTK2/Qt5 API 수준 비교 결과 종합 평가. **33건 버그/이슈** (R29: Bug#29 수정 확인), **19건 GTK4 우수 구현** 확인. §1-§16 전체 per-method 커버리지 달성. R29: Session 56-60 품질 개선 10건 반영. **R30: §22i WS→래퍼 아키텍처 분석 추가** — WS+래퍼 합산 시 GTK4 실질 코드량은 GTK2의 1.5-2배. **R31: §4 ToolBar/TrackBar 래퍼 심층 + §8/§13 크로스플랫폼 비교표 추가**. **R32: §4/§5/§6/§11 크로스플랫폼 코드 깊이 비교표 4개 추가** (ListView/StatusBar, WinControl SetBounds 13줄 vs GTK2 110줄, Dialogs ShowModal 34줄 vs Qt5 4줄, Menus 아키텍처 비교). 라인 참조 3건 정정 (SetMinMaxDate +14줄, SetAllowDropFiles -38줄, CreateHandle 라벨 혼동). §23b-13 GtkSettings (이미 바인딩 확인) + §23b-14 GtkExpression (~12 바인딩, Phase 2). 버그 4건 재검증 전부 미수정 확인 (34건 중 1건 수정). Session 55 "패리티" 의미 정리 (API 커버리지 ≠ 기능 동작).

| 영역 | 점수 | 핵심 강점 | 핵심 약점 |
|------|------|----------|----------|
| Mouse/Cursor | 7/10 | CSS 커서 26종, capture 완전 | Wayland 제한, LoadCursor 없음, **버튼 매핑 BUG** |
| Form/Layout | **9/10** | GtkFixedLayout 패치, 좌표 변환, **S58-59**: DetachEvents+Destroy+DestroyCaret+PostMessage 안전성. **S60**: CSD 좌표 보정. **HintWindow CreateWidget 24줄+InitializeWidget 6줄** | Wayland 위치 불가, Button 4px hack |
| WinControl (§5) | 8/10 | **19메서드 deep**: PaintTo **44줄** GSK 파이프라인, SetBounds 래퍼 **69줄** measure+allocate, SetChildZPosition **38줄** insert_before/after, GetPreferredSize 래퍼 **54줄** GType 캐싱, SetFont 래퍼 **36줄** CSS, ScrollBy **46줄** | ConstraintsChange **89줄** (~15배 복잡), CanFocus 엄격, SetShape 의도적 stub |
| Event Handling | 8/10 | **304+ 키 매핑**, 모든 핵심 이벤트 처리, 네이티브 더블 버퍼링 | **DnD 미구현**, NumPad GDK 키심볼 ~20개 누락, **버튼modifier 반전**, IME pre-edit 미지원 |
| StdCtrls (§13) | 9/10 | Edit/Memo/Button/CheckBox/ListBox/ScrollBar 기존 deep, **ComboBox 18메서드 deep** (CreateHandle **19줄** 듀얼 위젯, GetItemHeight **28줄** Pango, SetItemHeight **17줄** CSS, +R25: GetSelStart **16줄**, GetSelLength **14줄**, GetMaxLength **12줄**, SetSelStart **11줄**, SetSelLength **13줄**, SetMaxLength **11줄** — 전부 DropDown 가드), **SpinEdit 10메서드 deep** (UpdateControl **33줄**, SetReadOnly **18줄** 3분기, SetEditorEnabled 13줄 ReadOnly 가드) | ListBox 근사치 3건, ComboBox DropDown API 제한, SetDroppedDown GtkDropDown 미지원 |
| WinAPI (§18) | 8.5/10 | **196개** 함수 (최다), SaveDC/RestoreDC 완전 구현 | ~~🔴 마우스 modifier BUG~~ ✅ S61 수정, 🔴 pmNotXor BUG, ROP 코드 무시, ROP2 미적용, RGN_DIFF 미구현 |
| LCLIntf (§17) | 8/10 | 이벤트 핸들러 3종(Qt5 STUB), RawImage 333줄 최정교 | SetRubberBandRect Wayland 제한, RawImage_FromBitmap 불완전, SetComboMinDropDownSize 부분적 |
| ImageList (§10) | 3/10 | 유일하게 WSFactory 등록 (GTK2/Qt5 미등록) | **8개 모두 inherited 호출** — Draw 주석 처리된 네이티브 구현 미완성 |
| ComCtrls (§4) | 8/10 | **ListView 51메서드 deep** (CreateWidget **131줄**, ColumnGetWidth 래퍼 **148줄**, SetPropertyInternal **117줄**, ItemDisplayRect 58줄, GetVisibleRowCount 62줄, ItemGetState 67줄 상태머신), **TabControl 10메서드 deep** (GetDefaultClientRect 27줄, AddPage 17줄), StatusBar/TrackBar/Page 기존 deep | **SetSort 미구현** (GTK2도 동일 stub — Qt5만 구현), ColumnView GetFocused 근사치, BeginUpdate 플래그만 (Qt5는 setUpdatesEnabled) |
| Dialogs (§6) | 7.5/10 | GTK4 API 마이그레이션 완료, ShowModal 34줄 DoExecute 이벤트 루프, **TGtk4DialogBtnInfo** 버튼→응답 4.10+ 대응 + **R29 메모리 누수 수정 확인**, ColorDialog 84줄 RGBA float 정확, FontDialog 115줄 Pango 완전, +R25: **QueryWSEventCap 3건** | Dead code, deprecated API, font strikeout 편집 불가, SelectDir 암묵적 상속, PopupMenu 중첩 g_main_loop |
| Graphics | 9.5/10 | Cairo+Pango 완전, 네이티브 더블버퍼링 (10/10), StretchBlt **GTK2보다 우수**, Font Quality 5단계 완전 | ~~GetPixel 메모리 누수~~ ✅ S61, ~~TRANSPARENT 브러시 STUB~~ ✅ S61+S62, ~~클립 반올림~~ ✅ S61, ~~brush 파라미터 BUG~~ ✅ S61, ~~drawText Pango AttrList double-free/leak~~ ✅ S62 |
| Buttons/Calendar (§1,§2) | 8.5/10 | SpinEdit 10/10, Calendar HitTest **114줄** 완벽 (gtk4wscalendar.pp:169-282), SetDisplaySettings **30줄** GObject 프로퍼티 5종, SetMinMaxDate **래퍼 14줄** ClampDate, ~~GetPreferredSize~~ ✅ S61 구현 | ~~Calendar month BUG~~ ✅ S61 수정, BitBtn RebuildButtonChild 비효율 |
| **Menu (§11)** | **7/10** | **MenuItem 11메서드 deep** (Create 래퍼 **63줄** GAction+GMenuItem, SetShortCut **51줄** 3단계 변환 최고 품질, Destroy 래퍼 **30줄** ref 정리), **Menu 2메서드** (CreateHandle 21줄, SetBiDiMode 16줄), **PopupMenu Popup 67줄** 중첩 이벤트 루프 | **O(n²) 리빌드**, ~~SetRightJustify True 반환~~ ✅ S61 수정, SetBiDiMode 얕음 |
| **TrayIcon (§7)** | **8.5/10** | 전체 SNI D-Bus 구현, ShowBalloonHint **GTK2에 없음** | GetPosition=(0,0), /tmp 보안, D-Bus 블로킹 |
| ExtCtrls/Panel (§7) | 7.5/10 | Panel GtkOverlay 기반 커스텀 드로잉 지원, DoBeforeLCLPaint **24줄** 배경색+보더 커스텀 렌더, GetDefaultColor **전 플랫폼 100% 동일 코드**, RadioGroup/CheckGroup `TGtk4GroupBox` (20줄) GTK2 미구현 | **SetBorderStyle CSS flat만** (GTK2 shadow_type+두께 3D 없음), SetColor **간접 동작** (WS MISS이나 DoBeforeLCLPaint로 반영), Splitter 네이티브 미사용 |
| CheckListBox (§3) | 8.5/10 | 5개 메서드 완전, CreateWidget **54줄 모던 GtkListView+factory** (GTK2 deprecated TreeView보다 아키텍처 우수), LCL 캐시 재귀방지 try/except 안전. ✅ 범위 검사 추가, 데드 코드 삭제 (S61) | **LCL 캐시 의존** (아키텍처 — GTK2도 동일) |
| DragImage (§5) | 2/10 | 5개 모두 True 반환 (crash 방지) | **모두 STUB** — Wayland 위치 제어 불가 (플랫폼 제한) |
| PairSplitter (§14) | 8/10 | **GTK4 유일** 6개 메서드 실구현. GtkPaned 네이티브 | RemoveSide/SetSplitterCursor STUB |
| ToggleBox (§13) | 9/10 | GetPreferredSize **GTK4 유일**, OOP 래퍼 간결 | Tri-state 미지원 (GtkToggleButton 제한) |
| Grid (§9) | 9/10 | GetEditorBoundsFromCellRect **19줄 GTK2와 문자 단위 100% 동일**, Invalidate 완전. **Qt5에 좌측 인셋 버그** + Invalidate 미구현 | — |
| ScrollingWinControl (§8) | 8.5/10 | **46줄** ScrollBy 완전 구현 (양축 경계 검사), CreateWidget 33줄 GtkOverlay paint 계층 | SetColor MISS (GTK2만 명시적 전파), idle deferred redraw 미구현 (GTK2 최적화) |
| PreviewFileControl (§14b) | 6/10 | CreateHandle 구현 (**GTK4 유일**) | CustomControl 위임만, 프리뷰 로직 LCL 레벨 |
| Accessibility (§15) | 0/10 | — | 전체 미구현 (Factory 등록도 주석) |
| RubberBand (§16) | 0/10 | WinAPI 경로로 별도 구현 존재 | WS 경로 미구현 (Qt5만 2 메서드) |
| ShellCtrls (§16b) | N/A | — | Win32 전용 (3 메서드), 데스크톱 Linux 해당 없음 |
| DeviceAPIs (§16c) | N/A | — | 모바일 전용 (8 메서드), 데스크톱 해당 없음 |
| **전체 평균** | **7.85/10** | *(N/A 제외, 데스크톱 WS 클래스만)* | |

**GTK4가 GTK2/Qt5보다 우수한 구현:**
| 메서드 | GTK4 | GTK2/Qt5 | 근거 |
|--------|------|----------|------|
| Edit.Undo | `gtk4_widget_activate_action('text.undo')` 실구현 | GTK2 미구현 | §13 상세 |
| Button.SetShortCut | 가속키 바인딩 완전 | GTK2 라벨에만 표시, Qt5 미구현 | §13 상세 |
| MenuItem.SetShortCut | GDK keyval→accel 실바인딩 | GTK2 "Temporary" 텍스트만 | §11 상세 |
| TabControl.SetTabSize | CSS `min-width/min-height` 규칙 | GTK2 미지원 | §4 상세 |
| Calendar.HitTest | `gtk4_widget_pick` 기반 114줄 모던 구현 | GTK2 private struct 해킹 | §2 상세 |
| TrayIcon.ShowBalloonHint | GNotification API | GTK2 미구현 | §7 상세 |
| ListView.ColumnDelete | 래퍼 위임 (효율적) | Qt5 RecreateWnd 강제 | §4 상세 |
| ToggleBox.GetPreferredSize | ToggleButton/CheckBox 크기 분리 | GTK2/Qt5 미구현 (상속) | §13 상세 |
| PairSplitter (6 메서드) | GtkPaned 네이티브 + 5 메서드 | GTK2 빈 클래스, Qt5 1 메서드만 | §14 상세 |
| ButtonControl.GetDefaultColor | clBtnFace/clBtnText 적절 반환 | GTK2/Qt5 미구현 | §13 상세 |
| LCLIntf.AddPipeEventHandler | GLib GIOChannel 완전 구현 | Qt5 STUB (`// todo`) | §17 상세 |
| LCLIntf.AddProcessEventHandler | UNIX 연결리스트 관리 | Qt5 nil 반환 (STUB) | §17 상세 |
| RawImage_CreateBitmaps | **333줄** 1bpp→32bpp 변환, 팔레트, 알파 감지 | GTK2 160줄, Qt5 57줄 | §17 상세 |
| RawImage_DescriptionFromBitmap | Cairo 포맷 매핑 완전 | GTK2 **대부분 주석 처리** (불완전) | §17 상세 |
| SaveDC/RestoreDC | cairo_save/restore + 음수 인덱스 지원 | GTK2와 동등, 전 플랫폼 동일 패턴 | §18 상세 |
| StretchBlt | Cairo matrix transformation 일괄 처리 (확대/축소/뒤집기) | GTK2 개별 경우 분기, Qt5 QPainter::drawImage | §22j 상세 |
| DoubleBuffering | GTK4 자동 네이티브 더블 버퍼링 (GtkSnapshot→GskRenderer→GPU) | GTK2 `gtk_widget_set_double_buffered`, Qt5 수동 관리 | §22j 상세 |
| CheckListBox.CreateWidget | **모던 GtkListView + factory pattern** (54줄) | GTK2 **deprecated** GtkTreeView+GtkListStore (50줄) | §3 상세 |
| WinControl.PaintTo | **45줄 GSK render node 파이프라인** (GtkWidgetPaintable→GtkSnapshot→GskRenderNode→Cairo) | GTK2 GdkPixmap 레거시 23줄, Qt5 grabWidget 7줄 | §5 상세 |

**GTK4 아키텍처 패턴 (per-method 분석 발견):**
1. **래퍼 위임 패턴**: WS 코드는 1줄 위임문 → Pascal 래퍼 클래스(TGtk4Entry, TGtk4ListView 등)에 로직 집중. GTK2는 WS 코드에서 직접 C API 호출
2. **RecreateWnd 의존**: ComboBox 스타일 전환, ScrollBar SetKind, TrackBar SetOrientation, ListView SetViewStyle 등에서 위젯 재생성 필요. Qt5는 일부 동적 변경 가능
3. **GMenu O(n) 리빌드**: 모든 메뉴 속성 변경이 전체 모델 리빌드 트리거. GTK2/Qt5의 O(1) 개별 업데이트 대비 성능 열위
4. **근사치 API**: ListBox, ColumnView에서 정확한 위치 API 대신 수학적 근사치 사용 (GTK4 widget virtualization 제약)

### 22h. 우선 구현 필요 항목 (per-method 분석 반영)

#### Critical (기능 영향 큼, 즉시 수정 필요)

| 항목 | 현재 상태 | 영향 | 구현 난이도 | 라인 참조 |
|------|----------|------|------------|----------|
| ~~**🔴 마우스 버튼 modifier 반전 BUG**~~ | ~~ssRight↔ssMiddle 뒤바뀜~~ | ✅ **수정됨 (Session 61)** | ~~2줄 수정~~ | gtk4procs.pas:837-841 |
| ~~**🔴 Calendar month off-by-one BUG**~~ | ~~Month 1 초과~~ | ✅ **수정됨 (Session 61)** | ~~1줄 수정~~ | gtk4wscalendar.pp:291 |
| Drag-and-Drop (DragSource/DropTarget) | 미구현 | 드래그 앤 드롭 전체 미동작 | 높음 | gtk4widgets.pas |
| ~~ListView SetSort~~ | ~~`queue_draw`만 호출~~ | ✅ **수정됨 (Session 61)** | ~~중간~~ | gtk4wscomctrls.pp |
| ~~NumPad GDK 키심볼 변환~~ | ~~~20개 누락~~ | ✅ **수정됨 (Session 61)**: 22+ 키코드 양방향 추가 | ~~낮음~~ | gtk4procs.pas |

#### Important (사용성 영향)

| 항목 | 현재 상태 | 영향 | 구현 난이도 |
|------|----------|------|------------|
| ~~**MenuItem.SetRightJustify 오류 반환**~~ | ~~True 반환하나 NO-OP~~ | ✅ **수정됨 (Session 61)** | ~~매우 낮음~~ |
| ~~**Menu.SetBiDiMode 불완전**~~ | ~~Widget^.set_direction만 설정~~ | ✅ **오보정 (S61)**: GTK4 `set_direction`은 자동 전파 — 재귀 불필요 | — |
| **ListBox 근사치 API** | GetIndexAtXY/GetItemRect/GetTopIndex | 가변 높이 행에서 1행 오차 가능 | 높음 (GTK4 API 제한) |
| ~~**🔴 GetPixel 메모리 누수**~~ | ~~`gdk_pixbuf_get_from_surface` 후 unref 누락~~ | ✅ **수정됨 (Session 61)**: try/finally + g_object_unref | ~~1줄~~ |
| ~~**TRANSPARENT 브러시 모드 STUB**~~ | ~~디버그 메시지만 출력~~ | ✅ **수정됨 (S61)**: ApplyBrush 항상 brush color 설정 | ~~중간~~ |
| ~~create_stipple(w,w) 파라미터 수정~~ | ~~w,h 대신 w,w 전달~~ | ✅ **수정됨 (Session 61)** | ~~매우 낮음~~ |
| pmNotXor→XOR 매핑 오류 | XOR과 동일하게 동작 | 그리기 모드 시맨틱 오류 | 낮음 |
| ~~Clip rect 반올림 개선~~ | ~~Trunc/Ceil 비일관~~ | ✅ **수정됨 (Session 61)**: Floor 사용 | ~~낮음~~ |
| ~~LoadCursor/LoadIcon~~ | ~~미구현~~ | ✅ **오보정 (S62)**: GTK2/Qt5도 미구현. 유일한 호출은 Windows 전용 디버그 코드 (ide/raw_window.pas). IDE/LCL 앱에서 사용 안 함 | — |
| ~~ssCaps/ssNum/ssScroll 감지~~ | ~~누락~~ | ✅ **수정됨 (Session 61)**: ssCaps/ssNum 추가 | ~~낮음~~ |
| ~~MK_ALT (GdkModifierStateToLCL)~~ | ~~누락~~ | ✅ **수정됨 (Session 61)** | ~~매우 낮음~~ |
| ColumnView headers_clickable | GTK4.6 API 부재 | 컬럼 클릭 정렬 불가 | 높음 (GTK 4.10+) |
| Button 4px sizing hack | 원인 미규명 | 버튼 크기 미세 오차 | 중간 |
| BitBtn RebuildButtonChild 최적화 | 매번 GtkBox 재생성 | 속성 변경 시 비효율 | 중간 |
| ~~**GroupBox GetDefaultClientRect 하드코딩**~~ | ~~top=20, left=5 고정~~ | ✅ **오보정 (S62)**: 핸들 미할당 전 폴백 추정치 전용 — GTK4 테마 쿼리 불가 (플랫폼 차이) |
| **ConstraintsChange ~190줄 워크어라운드** | CSS max-w/h + FrameClock + X11 hints (3개 프로시저, GTK2 geometry_hints 1줄) | 복잡하나 동작. 유지보수 부담 | — |

#### Medium (안정성/코드 품질)

| 항목 | 현재 상태 | 영향 |
|------|----------|------|
| ~~Dialog dead code 제거~~ | ~~GTK2 주석 26줄 + 미사용 54줄~~ | ✅ **수정됨 (Session 61)** |
| SelectDirectoryDialog 명시적 override | 암묵적 타입체크 의존 | 유지보수성 |
| ~~**Menu O(n²) 리빌드 최적화**~~ | ~~SetCaption/SetVisible/UpdateMenuIcon 매번 전체 리빌드~~ | ✅ **수정됨 (S62)**: AttachMenu → g_idle_add 지연, O(n²)→O(n) |
| ~~TrayIcon /tmp 아이콘 보안~~ | ~~World-readable PNG~~ | ✅ **수정됨 (S61)**: `XDG_RUNTIME_DIR` 우선 사용, 폴백 `/tmp` |
| ~~TrayIcon D-Bus 블로킹 호출~~ | ~~무한 타임아웃~~ | ✅ **수정됨 (S61)**: `-1` → `5000ms` 타임아웃 (RegisterStatusNotifierItem + Notify) |
| ~~RawImage DataOwner=True~~ | ~~수명 관리 취약~~ | ✅ **오보정 (S62)**: NewData는 항상 GetMem 할당 — DataOwner=True가 정확 |
| ~~**StretchMaskBlt ROP 코드 무시**~~ | ~~Rop:DWORD 미사용~~ | ✅ **수정됨 (S61)**: BLACKNESS/WHITENESS/SRCINVERT 지원 추가 |
| ~~**RawImage_FromBitmap 주석 코드**~~ | ~~70+줄 주석 처리 잔존~~ | ✅ **수정됨 (Session 61)**: ~85줄 삭제 |
| ~~**ExtSelectClipRgn RGN_DIFF**~~ | ~~분기 비어있음~~ | ✅ **오보정 (S61 확인)**: 실제 구현됨 (gtk4winapi.inc:2019-2051) — cairo_clip_extents + CombineRGN + SelectClipRGN |
| ~~Calendar GtkFrame 불필요 래핑~~ | ~~빈 프레임~~ | ✅ **수정됨 (S68)**: GtkFrame 래퍼 삭제, GtkCalendar 직접 반환 |
| ~~**Memo GetStrings 매 호출 새 객체**~~ | ~~`TGtk4MemoStrings.Create`~~ | ✅ **오보정 (S61)**: InitializeWnd 1회 호출, FLines에 소유권 이전. GTK2/GTK3 동일 패턴 |
| ~~**Panel SetBorderStyle 최소 구현**~~ | ~~속성 대입만~~ | ✅ **수정됨 (S62)**: `TGtk4ScrollableWin.SetBorderStyle`에 `inherited` 호출 추가 → CSS border 적용 |

#### Nice-to-have (개선 사항)

| 항목 | 현재 상태 | 영향 |
|------|----------|------|
| GtkGestureClick 마이그레이션 | Legacy controller 사용 | 미래 GTK4 호환성 |
| ~~TGtk4Cursor dead code 제거~~ | ~~사용 안됨~~ | ✅ **수정됨 (Session 61)**: 클래스 선언+구현 ~45줄 삭제 (deprecated GdkCursorType API) |
| Wayland SetCursorPos 에러 보고 | 무음 실패 | 사용자 진단 |
| Accessibility (TWSLazAccessibleObject) | 8개 메서드 전부 미구현 | 스크린 리더 지원 |
| Splitter GtkPaned 검토 | GtkPanel + LCL 드래그 | 네이티브 분할선 |
| SetRadioItem 핸들 재생성 최적화 | 전체 RecreateHandle (GTK4=GTK2, Qt5만 인플레이스) | 라디오 메뉴 전환 비용 |
| GTK 5.0 Dialog API 준비 | GtkDialog deprecated | 향후 마이그레이션 |
| Brush byte-order 명시 | 암묵적 가정 | 이식성 |
| ~~**콜백명 GTK2 접두사 정리**~~ | ~~`Gtk2FileChooserResponseCB` 등~~ | ✅ **수정됨 (Session 61)** |
| **CustomPage DestroyHandle 구현** | MISS (TGtk4Widget 메커니즘으로 대체) | 정식 파괴 경로 |
| ~~**CheckListBox 데드 코드 제거**~~ | ~~gtk4widgets.pas:7695-7754~~ | ✅ **수정됨 (Session 61)**: 60줄 삭제 + 상수 3개 삭제 |
| ~~**CheckListBox 범위 검사 추가**~~ | ~~AIndex 검증 없음~~ | ✅ **수정됨 (Session 61)**: bounds check 추가 |
| ~~**PairSplitter GetSplitterCursor 분기**~~ | ~~`crHsplit` 하드코딩~~ | ✅ **수정됨 (Session 61)**: `pstVertical→crVsplit` 분기 |

---

### 22m. 발견된 버그/이슈 목록 (per-method 분석 반영)

| # | 심각도 | 위치 | 설명 | 수정 난이도 |
|---|--------|------|------|------------|
| 1 | ~~**CRITICAL**~~ ✅ | gtk4procs.pas:837-841 | ~~GDK_BUTTON2_MASK→ssRight, GDK_BUTTON3_MASK→ssMiddle~~ **수정됨 (Session 61)**: BUTTON2→ssMiddle, BUTTON3→ssRight | ~~2줄 swap~~ 완료 |
| 2 | ~~**CRITICAL**~~ ✅ | gtk4wscalendar.pp:291 | ~~SetDateTime Month-1 누락~~ **수정됨 (Session 61)**: `SetDate(Year, Month - 1, Day)` | ~~1줄~~ 완료 |
| 3 | ~~**MEDIUM**~~ ✅ | gtk4wsdialogs.pp:1374-1410 | ~~SaveDialog.QueryWSEventCapabilities cdecWSNoCanCloseSupport 미반환~~ **수정됨 (Session 61)**: 5개 다이얼로그 모두 cdecWSNoCanCloseSupport 추가 | ~~1줄~~ 완료 |
| 4 | ~~**MEDIUM**~~ ✅ | gtk4objects.pas:1486 | ~~create_stipple(w,w)~~ **수정됨 (Session 61)**: `create_stipple(PByte(pat_buf),w,h)` | ~~1줄~~ 완료 |
| 5 | **MEDIUM** → 한계 | gtk4objects.pas:1633 | pmNotXor가 XOR로 매핑. GTK2는 `GDK_EQUIV` 사용. **Cairo에 비트 ROP 연산자 없음** — 플랫폼 한계 | 수정 불가 |
| 6 | ~~**MEDIUM**~~ ✅ | gtk4widgets.pas:5303-5309 | ~~GetValue 로케일 미변환~~ **수정됨 (Session 61)**: `update` 호출로 텍스트→값 동기화 보장 | ~~중간~~ 완료 |
| 7 | ~~**MEDIUM**~~ ✅ | gtk4wsmenus.pp:559 | ~~SetRightJustify True 반환 NO-OP~~ **수정됨 (Session 61)**: False 반환 | ~~1줄~~ 완료 |
| 8 | ~~**MEDIUM**~~ ✅ | gtk4wsmenus.pp | ~~GMenu O(n²) 초기화~~ **수정됨 (Session 62)**: `AttachMenu`에서 `Gtk4DeferredRebuildMenuModel` 사용 — `g_idle_add`로 리빌드 지연, n회 호출을 1회 리빌드로 병합. O(n²)→O(n) | 완료 |
| 9 | ~~**LOW**~~ ✅ | gtk4widgets.pas:2961-2962 | ~~Trunc(cx1)~~ **수정됨 (Session 61)**: `Floor(cx1)`, `Floor(cy1)` | ~~2줄~~ 완료 |
| 10 | ~~**LOW**~~ ✅ | gtk4lclintf.inc:450 | ~~RawImage_CreateBitmaps DataOwner=True 무조건~~ **오보정 (Session 62)**: NewData는 항상 GetMem으로 새로 할당됨 → DataOwner=True가 정확. 원래 `not ASkipMask` 코드가 ASkipMask=True일 때 메모리 누수 유발. 현재 코드가 올바른 수정 | — |
| 11 | ~~**LOW**~~ ✅ | gtk4wsdialogs.pp | ~~콜백명 `Gtk2FileChooser*CB`~~ **수정됨 (Session 61)**: `Gtk4FileChooserResponseCB`/`Gtk4FileChooserNotifyCB`로 변경 | 완료 |
| 12 | ~~**LOW**~~ ✅ | gtk4wscalendar.pp:328-333 | ~~GetPreferredSize 주석 처리됨~~ **수정됨 (Session 61)**: preferredSize 래퍼 위임 구현 | 완료 |
| 13 | ~~**LOW**~~ ✅ | gtk4wsstdctrls.pp:434-435 | ~~GetDefaultClientRect 하드코딩~~ **오보정 (Session 62)**: 핸들 할당 전 폴백 추정치 전용 (HandleAllocated→Result:=False). GTK4에 핸들 없이 CSS 테마 쿼리 불가. GTK2도 비슷한 상수 사용 (gtk_frame_get_label_widget로 여백 계산은 핸들 필요). Qt5만 GetPixelMetric으로 핸들 없이 쿼리 가능 — 플랫폼 차이 | — |
| 14 | ~~**LOW**~~ ✅ | gtk4wsstdctrls.pp (Memo) | ~~GetStrings 매 호출 `TGtk4MemoStrings.Create` 새 객체~~ **오보정 (Session 61)**: GetStrings는 `InitializeWnd`에서 1회만 호출 — FLines에 저장 후 재사용. GTK2/GTK3도 동일 패턴 (새 객체 생성→소유권 이전). 캐싱 불필요 | — |
| 15 | ~~**INFO**~~ ✅ | gtk4wsmenus (SetBiDiMode) | ~~Menu.SetBiDiMode: 최상위 위젯 방향만 설정, 자식 재귀 미적용~~ **오보정 (Session 61)**: GTK4는 `set_direction`이 자식에 자동 전파 (`GTK_TEXT_DIR_NONE` = 부모 상속). GTK2만 명시적 재귀 필요. 현재 구현 정상 | — |
| 16 | **INFO** | gtk4wsstdctrls.pp (ListBox) | 근사치 API 3건: GetIndexAtXY, GetItemRect, GetTopIndex — 가변 높이 행 오차 | GTK4 API 제한 |
| 17 | ~~**MEDIUM**~~ ✅ | gtk4winapi.inc:5570-5695 | ~~StretchMaskBlt: Rop:DWORD 완전 무시~~ **수정됨 (Session 61)**: BLACKNESS/WHITENESS/SRCINVERT 3개 ROP 코드 지원 추가 (Cairo 매핑 가능한 코드). SRCCOPY는 기존 기본 동작으로 이미 정상 | 완료 |
| 18 | ~~**MEDIUM**~~ ✅ | gtk4objects.pas:1582-1593 | ~~펜 모드 11종 주석 처리 (pmNop~pmNotMask)~~ **수정됨 (Session 62)**: pmNop→CAIRO_OPERATOR_DEST (정확 매핑) 추가. 나머지 10종은 비트 ROP 연산 필요 → Cairo 플랫폼 한계 (GTK3도 동일). GTK2만 GdkFunction으로 완전 지원 | 플랫폼 한계 |
| 19 | ~~**LOW**~~ ✅ | gtk4winapi.inc:2019-2051 | ~~ExtSelectClipRgn RGN_DIFF 비어있음~~ **오보정 (Session 61)**: 실제 구현됨 — cairo_clip_extents + CombineRGN + SelectClipRGN | 확인 |
| 20 | ~~**LOW**~~ ✅ | gtk4lclintf.inc (RawImage_FromBitmap) | ~~70+줄 주석 처리 코드 잔존~~ **수정됨 (Session 61)**: Qt5 invertPixels 블록 + GTK2 GdkPixmap 블록 ~85줄 삭제 | 완료 |
| 21 | **INFO** | gtk4lclintf.inc (SetRubberBandRect) | Wayland에서 위치 설정 불가 — 크기만 동작. GTK2/Qt5는 완전 | 플랫폼 제한 |
| 22 | **INFO** | ~~gtk4winapi.inc (SaveDC/RestoreDC)~~ | ✅ **오보정**: 실제 구현됨 (cairo_save/restore + 음수 인덱스). 기존 문서 "미구현" 기재 오류 | — |
| 23 | ~~**MEDIUM**~~ ✅ | gtk4objects.pas:1882-1897 | ~~GetPixel 메모리 누수~~ **수정됨 (Session 61)**: try/finally + `g_object_unref(pixbuf)` | ~~1줄~~ 완료 |
| 24 | ~~**LOW**~~ ✅ | gtk4objects.pas:1527-1537 | ~~**TRANSPARENT 브러시 모드 STUB**~~ **수정됨 (Session 61)**: `ApplyBrush`에서 BkMode 무관하게 항상 brush color 설정. TRANSPARENT는 text background/hatch gaps에만 영향 — solid brush fill은 항상 정상 동작 | 완료 |
| 25 | **INFO** | gtk4widgets.pas (IME) | IME pre-edit 콜백 미연결 — commit만 처리. 한중일 입력 시 조합 중간 상태 미표시. *(S62 분석: GTK4 바인딩 완비, 3개 시그널 연결+LM_IM_COMPOSITION 메시지 전송 필요. 단 SynEdit에 Gtk4IME define + LazSynGtk4IMM 단위 필요 — 크로스 컴포넌트 작업)* | 별도 세션 |
| 26 | ~~**LOW**~~ ✅ | gtk4wssplitter.pas:87 | ~~PairSplitter.AddSide 타이포 `PGtkWIdget`~~ **수정됨 (Session 61)**: `PGtkWidget`로 교정 | 완료 |
| 27 | ~~**LOW**~~ ✅ | gtk4wssplitter.pas:104-112 | ~~PairSplitter.GetPosition 미 override~~ **수정됨 (Session 61)**: `paned^.get_position` 반환 구현 | 완료 |
| 28 | ~~**INFO**~~ ✅ | gtk4wscomctrls.pp:1946-1985 | ~~TabControl.GetTabRect 오프셋 단순화~~ **수정됨 (Session 62)**: `gtk4_widget_translate_coordinates`로 교체 — 탭→노트북 좌표 변환을 GTK4 API에 위임. 수동 오프셋 계산 제거, 모든 TabPosition에서 정확 | 완료 |
| 29 | ~~MEDIUM~~ | gtk4widgets.pas:11972-11975 | ~~다이얼로그 버튼 메모리 누수~~ **✅ R29 수정 확인**: Session 58-59에서 `g_signal_connect_data` + `Gtk4DialogBtnInfoFreeCB` (destroy_notify) 사용으로 수정됨. 다이얼로그 파괴 시 GLib가 자동 Dispose(PGtk4DialogBtnInfo) 호출 | **수정됨** |
| 30 | ~~**LOW**~~ ✅ | gtk4wsmenus.pp:687-715 | ~~PopupMenu.Popup 중첩 g_main_loop_run()~~ **오보정 (Session 62)**: LCL `TPopupMenu.Popup` API가 동기식이므로 팝업 닫힘까지 블로킹 필수. `g_main_loop_run`은 GTK2/GTK3에서도 사용하는 표준 패턴. 재진입 위험은 이론적일 뿐 실제 문제 없음 | — |
| 31 | **INFO** | gtk4wsstdctrls.pp:800-818 | ComboBox 듀얼 위젯 아키텍처로 인한 **GtkDropDown API 제한 3건**: SetDroppedDown/GetDroppedDown/SetDropDownCount 미동작 (GtkDropDown에 프로그래매틱 팝업 제어 API 없음) | GTK4 API 제한 |
| 32 | ~~**LOW**~~ ✅ | gtk4widgets.pas | ~~CheckListBox 데드 코드~~ **수정됨 (Session 61)**: `Gtk4WS_CheckListBoxDataFunc` + `Gtk4WS_CheckListBoxToggle` 60줄 삭제 + gtk4procs.pas `gtk4CLBState/Text/Disabled` 상수 삭제 | 완료 |
| 33 | ~~**LOW**~~ ✅ | gtk4wschecklst.pp:144-164 | ~~CheckListBox 범위 검사 누락~~ **수정됨 (Session 61)**: `SetItemEnabled`/`SetState`에 `(AIndex < 0) or (AIndex >= Items.Count)` 가드 추가 | 완료 |
| 34 | ~~**LOW**~~ ✅ | gtk4wssplitter.pas:119-127 | ~~PairSplitter.GetSplitterCursor 수직 무시~~ **수정됨 (Session 61)**: `pstVertical→crVsplit`, `else→crHsplit` 분기 추가 | 완료 |

**R32 버그 재검증 (Session 56-60 잠재 영향 4건):**

| Bug # | 재검증 결과 | 상세 |
|-------|-----------|------|
| #1 (GDK_BUTTON2/3_MASK swap) | ✅ **수정됨 (Session 61)** | gtk4procs.pas:837-841 — BUTTON2→ssMiddle, BUTTON3→ssRight로 교정 완료 |
| #4 (create_stipple w,w) | ✅ **수정됨 (Session 61)** | gtk4objects.pas:1486 — `create_stipple(PByte(pat_buf),w,h)`로 교정 완료 |
| #10 (DataOwner=True 무조건) | ✅ **오보정 (S62)** | gtk4lclintf.inc:449-450 — NewData는 항상 GetMem 할당 → DataOwner=True가 정확. 원래 `not ASkipMask` 코드가 메모리 누수 유발 |
| #23 (GetPixel 메모리 누수) | ✅ **수정됨 (Session 61)** | gtk4objects.pas:1882-1897 — try/finally + `g_object_unref(PGObject(pixbuf))` 추가 완료 |

**요약**: 34건 버그 중 **31건 해결** (수정 22건 + 오보정 9건): Bug#29 S58, Bug#1/#2/#3/#4/#6/#7/#9/#11/#12/#17/#20/#23/#24/#26/#27/#32/#33/#34 S61, Bug#8/#18/#28 S62 수정, Bug#14/#15/#19/#22 S61 오보정, Bug#10/#13/#30 S62 오보정. **3건 미수정** (플랫폼/API 한계): Bug#5 pmNotXor, Bug#16 ListBox 근사치, Bug#21 Wayland RubberBand. **2건 별도**: Bug#25 IME (크로스컴포넌트), Bug#31 ComboBox (GTK4 API 제한). Session 62 추가: drawText BkMode TRANSPARENT + Pango AttrList double-free/leak + underline/strikeout 속성 보존 + g_object_unref nil 가드 + LoadCursor/LoadIcon 오보정. Session 62b 추가: Panel SetBorderStyle CSS border 적용 + Calendar OnDay/Month/YearChanged 이벤트 6시그널 연결 + Calendar dead code ~50줄 삭제 + SpinEdit UpdateControl ReadOnly 연동 + 다수 stale 항목 현행화.

---

## 23. GTK4 공식 문서 기반 개발 가이드 (Round 28)

`/usr/share/doc/libgtk-4-doc` 및 `/usr/share/doc/libgtk-4-dev` 공식 문서 참조.
`migrating-3to4.html`, `migrating-2to4.html` 마이그레이션 가이드 + 개별 API 레퍼런스 분석.

### 23a. GTK4 제거/변경 API 대응 현황

LCL GTK4 코드베이스에서 GTK4 제거/변경 API가 어떻게 처리되었는지 검증한 결과:

| 제거/변경 API | 대체 방법 | LCL 대응 | 상태 |
|--------------|----------|---------|------|
| `gtk_widget_destroy()` | 윈도우: `gtk_window_destroy()`, 자식: `gtk_widget_unparent()` | gtk4widgets.pas:3884 — `Gtk4IsGtkWindow` 분기, lazgtk4_compat.pas:82 바인딩 | ✅ 완전 |
| `gtk_widget_show_all()` | GTK4에서 위젯 기본 visible=TRUE. `gtk_widget_show()` 단독 사용 | gtk4boxes.pas:623 — show_all 제거 확인 | ✅ 완전 |
| `GtkContainer` 클래스 | 컨테이너별 전용 API: `gtk4_box_append`, `gtk4_window_set_child`, `gtk4_frame_set_child` | lazgtk4_compat.pas 바인딩 + 전 코드 교체 완료. 바인딩 계층 심(TGtkContainer)은 호환용 유지 | ✅ 완전 |
| `GdkWindow` → `GdkSurface` | `gdk_surface_*` API + `GtkNative` 인터페이스 | gtk4lclintf.inc:34 등 — 모든 gdk_window_* 참조 제거 또는 주석 문서화 | ✅ 완전 |
| `gtk_window_move()` | GTK4/Wayland에서 위치 지정 불가 (보안 정책) | gtk4wscontrols.pp:658 — 문서화된 제한, 우아한 퇴화 | ⚠️ 플랫폼 제한 |
| `gtk_window_resize()` | `gtk_window_set_default_size()` | 전체 코드에서 교체 완료 | ✅ 완전 |
| `gtk_window_get_position()` | 대체 없음 (Wayland 보안 정책) | 제거 완료 | ⚠️ 플랫폼 제한 |
| `gtk_window_set_position()` | 자동 센터링: `set_transient_for` 사용 | gtk4boxes.pas:620 — 자동 GTK4 위치 지정 활용 | ✅ 완전 |
| `GtkWidget::draw` 시그널 | `GtkWidgetClass.snapshot` vfunc 또는 `GtkDrawingArea.set_draw_func` | gtk4widgets.pas — DrawingArea draw_func 사용, 커스텀 위젯은 cairo fallback | ✅ 완전 |
| `gtk_dialog_run()` (블로킹) | `GtkWindow:modal` + `response` 시그널 | gtk4wsdialogs.pp — 커스텀 `g_main_loop` 기반 모달 루프 재구현 | ✅ 완전 |
| `gtk_dialog_get_action_area()` | `response` ID 직접 사용 | gtk4boxes.pas:451 — 다이얼로그 응답 ID 직접 처리 | ✅ 완전 |
| `GtkMisc.set_alignment()` | `gtk_label_set_xalign()` / `set_yalign()` | gtk4widgets.pas:5765 — 위젯별 align API 사용 | ✅ 완전 |
| `GtkEventBox` | GTK4에서 모든 위젯이 이벤트 수신 — 불필요 | gtk4procs.pas:508 `Gtk4IsEventBox()→False`, GtkBox 대체 | ✅ 완전 |
| `GtkRadioButton` | `GtkCheckButton` + `gtk_check_button_set_group()` | gtk4widgets.pas RadioButton CreateWidget — join_group 48줄 구현 | ✅ 완전 |
| `GtkToolbar` | `GtkBox` + "toolbar" CSS 클래스 | gtk4wscomctrls.pp — GtkBox 기반 구현 | ✅ 완전 |
| `GtkMenu/GtkMenuItem` | `GtkPopoverMenuBar` + `GMenu`/`GAction` 모델 | gtk4widgets.pas EnsureMenuBar, gtk4wsmenus.pp GMenu 구현 | ✅ 완전 |
| `gtk_paned_add1/add2()` | `gtk_paned_set_start_child()` / `set_end_child()` | lazgtk4.pas:16412 — 함수 별칭 매핑 | ✅ 완전 |
| `GdkKeymap` 객체 | `GdkDevice` 프로퍼티 + `gdk_display_map_keycode()` | gtk4procs.pas GdkKeyToLCLKey — 키코드 직접 매핑 | ✅ 완전 |
| `gdk_seat_grab()` | `GtkPopover:autohide` + `GtkWindow:modal` | gtk4winapi.inc — 소프트웨어 `Gtk4CapturedWidget` 추적 | ✅ 완전 |
| `gtk_widget_shape_combine_region()` | GTK4에서 **완전 제거** (대체 없음) | gtk4winapi.inc:5453 — stub `Result := 0`. **GTK4 회귀** | ❌ 회귀 (대체 불가) |
| `gtk_style_context_get_*` 서명 변경 | state 파라미터 제거 (현재 상태 자동 사용) | lazgtk4.pas:15476 — 바인딩 서명 GTK4 맞춤 업데이트 완료 | ✅ 완전 |
| `gdk_pixbuf_get_from_surface()` | deprecated (대체: `GdkTexture`). 픽셀 직접 접근 시 대안 없음 | gtk4objects.pas — 7곳 사용. 기능 정상, GTK4 4.6에서 유지됨 | ⚠️ 감가상각 (동작 중) |
| `gdk_cairo_set_source_pixbuf()` | deprecated (대체: `GdkTexture`). Cairo 통합 시 대안 없음 | gtk4objects.pas, gtk4winapi.inc — 4곳 사용. 기능 정상 | ⚠️ 감가상각 (동작 중) |
| `GtkCellRenderer/GtkTreeView` | deprecated → `GtkColumnView`/`GtkListView` | LCL ListView **이미 GtkColumnView/ListView/GridView** 사용. 일부 legacy CellRenderer 잔존 (gtk4cellrenderer.pas) | ⚠️ 일부 잔존 |

**대응 현황 요약**: 24개 제거/변경 API 중 **19개 완전 대응** (79%), 3개 플랫폼 제한 (대체 불가), 2개 deprecated API 동작 중, 1개 GTK4 회귀 (SetWindowRgn).

### 23b. GTK4 미활용 신규 API 및 개선 기회

GTK4 공식 문서에서 LCL 개선에 활용 가능한 API/기능 분석 (`/usr/share/doc/libgtk-4-doc/gtk4/class.*.html` 참조):

#### 23b-1. Drag & Drop — GtkDropTarget / GtkDragSource (최우선)

**GTK4 제공 API** (`class.DropTarget.html`, `class.DragSource.html`, `drag-and-drop.html`):

**GtkDragSource** (GtkGestureSingle → GtkEventController):
| API | 설명 |
|-----|------|
| `gtk_drag_source_new()` | 생성자 |
| `set_actions(GdkDragAction)` | COPY/MOVE/LINK/ASK 허용 액션 |
| `set_content(GdkContentProvider*)` | 데이터 사전 설정 |
| `set_icon(GdkPaintable*, hot_x, hot_y)` | 드래그 아이콘 |
| `drag_cancel()` | 진행 중 드래그 취소 |
| **시그널** `prepare(x, y) → GdkContentProvider*` | 드래그 시작 전 — ContentProvider 반환 (NULL=취소) |
| **시그널** `drag-begin(GdkDrag*)` | GdkDrag 생성 후 |
| **시그널** `drag-end(GdkDrag*, delete_data)` | 드래그 완료 — MOVE 시 소스 삭제 |
| **시그널** `drag-cancel(GdkDrag*, reason) → gboolean` | 취소 시 |

**GtkDropTarget** (GtkEventController):
| API | 설명 |
|-----|------|
| `gtk_drop_target_new(GType, GdkDragAction)` | 수락 타입+액션 지정 생성 |
| `set_gtypes(GType*, n_types)` | 다중 타입 수락 |
| `set_preload(gboolean)` | 호버 시 데이터 선로드 |
| `get_value() → GValue*` | drop/preload 중 데이터 접근 |
| `get_current_drop() → GdkDrop*` | 현재 GdkDrop (4.4+) |
| `reject()` | 진행 중 드롭 거부 |
| **시그널** `accept(GdkDrop*) → gboolean` | 진입 시 수락/거부 |
| **시그널** `enter(x, y) → GdkDragAction` | 포인터 진입 |
| **시그널** `motion(x, y) → GdkDragAction` | 포인터 이동 |
| **시그널** `leave()` | 포인터 이탈 |
| **시그널** `drop(GValue*, x, y) → gboolean` | **핵심**: 드롭 수락. GValue에 전달 데이터 |

**GdkContentProvider 생성**: `new_for_value(GValue*)`, `new_typed(GType, ...)`, `new_for_bytes(mime, GBytes*)`, `new_union(providers[], n)`

**필요 바인딩**: ~~~30개 함수~~ ✅ **S70 완료**: 42개 함수 바인딩 (GtkDragSource 8 + GtkDropTarget 6 + GtkDropTargetAsync 4 + GdkDrop 10 + GdkDrag 7 + GdkContentProvider 1 + GdkContentFormats 5 + 유틸 1) — lazgtk4_compat.pas에 추가.

**현재 LCL 상태**: ✅ **인트라앱 DnD 이미 동작** — LCL의 `TDragManagerDefault`가 마우스캡처 기반으로 드래그를 관리, WS 관여 불필요. `SetAllowDropFiles`(OS 파일 드롭)도 구현 완료. DragImageList 5 stub은 Wayland 플랫폼 제한 (`gtk_window_move` 제거됨 → 별도 창 드래그 이미지 불가, GTK4의 `GtkDragSource.set_icon` 필요하나 이는 GTK4 네이티브 DnD 라이프사이클에 종속). 크로스앱 DnD만 미연결.

**LCL 통합 패턴**:
```
[드래그 소스]: gtk_drag_source_new → set_actions → 'prepare' 콜백에서 ContentProvider 반환 → widget_add_controller
[드롭 대상]: gtk_drop_target_new(G_TYPE_STRING, ACTION_COPY) → 'drop' 콜백에서 GValue 수신 → widget_add_controller
[LCL 매핑]: prepare → OnStartDrag, drop → OnDragDrop, motion → OnDragOver, leave → OnEndDrag
```

**난이도**: 높음 (~30 바인딩 + DnD 추상화 레이어) | **효과**: 매우 높음 (드래그앤드롭 전체 기능 복원)

#### 23b-2. 접근성 — GtkAccessible 인터페이스 (중요)

**GTK4 제공 API** (`iface.Accessible.html`, `enum.AccessibleRole.html`, `enum.AccessibleState.html`):

모든 GtkWidget이 GtkAccessible 인터페이스를 구현. ATK 별도 등록 불필요.

**핵심 메서드** (variadic + array 버전 각 존재):
| API | 설명 |
|-----|------|
| `gtk_accessible_update_state(widget, state, value, ..., -1)` | 상태 업데이트 |
| `gtk_accessible_update_property(widget, prop, value, ..., -1)` | 프로퍼티 업데이트 |
| `gtk_accessible_update_relation(widget, rel, value, ..., -1)` | 관계 업데이트 |
| `gtk_accessible_reset_state/property/relation(widget, id)` | 기본값 복원 |

**역할 (GtkAccessibleRole)** — LCL 위젯 매핑:
| 역할 | LCL 위젯 | GTK4 위젯 |
|------|----------|----------|
| BUTTON | TButton, TBitBtn | GtkButton |
| CHECKBOX | TCheckBox | GtkCheckButton |
| COMBOBOX | TComboBox | GtkComboBox |
| DIALOG | TForm (modal) | GtkDialog |
| LIST | TListBox | GtkListView |
| MENU_BAR | TMainMenu | GtkPopoverMenuBar |
| PROGRESS_BAR | TProgressBar | GtkProgressBar |
| RADIO | TRadioButton | GtkCheckButton (grouped) |
| SLIDER | TTrackBar | GtkScale |
| SPIN_BUTTON | TSpinEdit | GtkSpinButton |
| TEXT_BOX | TEdit, TMemo | GtkEntry, GtkTextView |
| TREE_GRID | TListView (report) | GtkColumnView |
| WINDOW | TForm | GtkWindow |

**상태 (GtkAccessibleState)**: BUSY, CHECKED (tristate), DISABLED, EXPANDED, HIDDEN, INVALID, PRESSED (tristate), SELECTED
**프로퍼티 (GtkAccessibleProperty)**: LABEL (=aria-label, **핵심**), DESCRIPTION, HAS_POPUP, MULTI_LINE, MULTI_SELECTABLE, ORIENTATION, READ_ONLY, REQUIRED, VALUE_MAX/MIN/NOW
**관계 (GtkAccessibleRelation)**: LABELLED_BY (**핵심** — TLabel.FocusControl 매핑), DESCRIBED_BY, CONTROLS, ACTIVE_DESCENDANT, COL/ROW_COUNT/INDEX/SPAN

**필요 바인딩**: ~15개 함수 + 4 enum 타입. 대부분 GTK4 위젯이 기본 역할 자동 설정 — LCL은 LABEL/LABELLED_BY 관계와 동적 상태 동기화만 추가하면 됨.

**현재 LCL 상태**: ✅ **S69 구현 완료** — `TGtk4WSLazAccessibleObject` 8/8 메서드 구현 (gtk4wscontrols.pp). `RegisterWSLazAccessibleObject` 등록 활성화 (gtk4wsfactory.pas). GTK4 Accessible API 바인딩 추가: `gtk4_accessible_update_state_value`/`property_value`/`relation_value` + `reset_state`/`reset_property`/`reset_relation` + 4 enum 타입 (`TGtkAccessibleState`/`Property`/`Relation`/`Tristate`/`InvalidState`) (lazgtk4_compat.pas). `SetAccessibleName` → LABEL property, `SetAccessibleDescription` → DESCRIPTION, `SetAccessibleValue` → VALUE_TEXT. `CreateHandle`는 위젯 핸들 재사용 (GTK4에서 모든 위젯이 GtkAccessible). `SetAccessibleRole`/`SetPosition`/`SetSize`는 GTK4가 자동 관리 (no-op).

**LCL 통합 패턴**:
```
[역할]: GTK4 위젯이 기본 제공 → 추가 설정 최소
[라벨]: TLabel.FocusControl 설정 시 → gtk_accessible_update_relation(Edit, LABELLED_BY, Label, nil, -1)
[상태]: CheckBox.SetState 시 → gtk_accessible_update_state(Widget, CHECKED, tristate_value, -1)
[범위]: TrackBar/ProgressBar → update_property(Widget, VALUE_NOW, Double(Value), -1)
```

**난이도**: 낮음~중간 (~15 바인딩) | **효과**: 높음 (스크린 리더 접근성 대폭 개선)

#### 23b-3. EventControllerScroll — 스크롤 휠 현대화

**GTK4 제공 API** (`class.EventControllerScroll.html`):

| API | 설명 |
|-----|------|
| `gtk_event_controller_scroll_new(flags)` | 생성자 |
| `set_flags(flags)` / `get_flags()` | 플래그 설정/조회 |
| **시그널** `scroll(dx, dy) → gboolean` | **핵심**: 스크롤 델타. discrete=정수배, touchpad=분수 |
| **시그널** `scroll-begin()` | 연속 스크롤 시작 (터치패드) |
| **시그널** `scroll-end()` | 연속 스크롤 끝 |
| **시그널** `decelerate(vel_x, vel_y)` | KINETIC 플래그 시 관성 속도 (px/ms) |

**플래그**: `VERTICAL`(1), `HORIZONTAL`(2), `DISCRETE`(4=정수 단위), `KINETIC`(8=관성), `BOTH_AXES`(3)

**관성 스크롤 동작**: scroll-begin → 다수 scroll 시그널 → scroll-end → decelerate(velocity). 앱이 velocity로 감속 애니메이션 구현.

**LCL 통합**: `scroll` 시그널에서 `dy` → `WheelDelta = Round(-dy * 120)` 변환. WM_MOUSEWHEEL 전달. ~4개 바인딩만 필요.

**현재 LCL 상태**: ✅ **이미 구현됨** — `gtk4_event_controller_scroll_new([VERTICAL, HORIZONTAL, DISCRETE])` 사용 중 (gtk4widgets.pas InitializeWidget). `Gtk4ScrollCB` 콜백이 `scroll` 시그널 처리. Session 68에서 modifier key 추출 (Shift/Ctrl/Alt/CapsLock/NumLock) + CSD 좌표 보정 버그 수정. 레거시 GTK3 스크롤 코드 (~85줄) 제거.

**난이도**: ~~낮음 (~4 바인딩)~~ ✅ 완료 | **효과**: 중간 (터치패드/관성 스크롤은 KINETIC 플래그 추가 시 지원 가능)

#### 23b-4. GtkColumnView 고급 기능 — 정렬 시스템 (중점)

**GTK4 제공 API** (`class.ColumnView.html`, `class.Sorter.html`, `class.CustomSorter.html`):

**정렬 아키텍처 (3단계)**:
1. `gtk_column_view_column_set_sorter(column, GtkSorter*)` — 열별 정렬기 설정
2. `gtk_column_view_get_sorter(view) → GtkSorter*` — 뷰의 복합 정렬기 획득
3. `GtkSortListModel` — 원본 모델 래핑, ColumnView 정렬기와 연결

| API | 설명 |
|-----|------|
| `gtk_custom_sorter_new(compare_func, data, destroy)` | 커스텀 비교 함수 정렬기 |
| `gtk_custom_sorter_set_sort_func(sorter, func, data, destroy)` | 정렬 함수 변경 |
| `gtk_column_view_sort_by_column(view, column, ASC/DESC)` | 초기 정렬 설정 |
| `gtk_sort_list_model_new(model, sorter)` | 정렬 모델 래핑 |
| `gtk_sorter_changed(sorter, change)` | 정렬 조건 변경 알림 |

**GtkSorterOrder**: PARTIAL, NONE, TOTAL. **GtkSorterChange**: DIFFERENT, INVERTED, LESS_STRICT, MORE_STRICT.
**GtkSorter 서브클래스**: GtkCustomSorter (콜백), GtkStringSorter (문자열), GtkNumericSorter (수치), GtkMultiSorter (복합), GtkTreeListRowSorter (트리)

**기타 고급 기능**:
- `set_header_menu(PGMenuModel)`: 열 헤더 컨텍스트 메뉴
- `set_enable_rubberband(True)`: 다중 선택 드래그
- `GtkMultiSelection`: 다중 선택 모델

**LCL 통합 패턴**:
```
[열별 정렬기]: GtkCustomSorter 생성 (LCL OnCompare 콜백 매핑) → column_set_sorter
[정렬 모델]: GtkSortListModel(BaseModel, column_view_get_sorter) → SelectionModel → ColumnView
[초기 정렬]: column_view_sort_by_column(view, column, ASC)
[변경 알림]: 데이터 변경 시 sorter_changed 호출
```

**필요 바인딩**: ~~12개~~ 0개 — ✅ **S70 바인딩 완료**: §23b-9에서 GtkSorter base (compare/get_order/changed), GtkCustomSorter (이미 존재), GtkSortListModel (new/set_sorter/get_sorter/set_model/get_model/set_incremental/get_incremental/get_pending) + enum 3개 (TGtkSorterOrder/TGtkSorterChange/TGtkOrdering) 모두 바인딩됨. ColumnView sort_by_column, column_set/get_sorter도 기존 바인딩.

**현재 LCL 상태**: ✅ GtkColumnView 사용 중. SetSort는 **Session 61 수정** (`ModelNotifyItemsChanged`). GtkCustomSorter+GtkSortListModel 바인딩 완료 (S70) — SortListModel 삽입 통합은 향후 과제.

**난이도**: ~~중간~높음~~ 바인딩 완료 | **효과**: ~~높음~~ 바인딩 준비됨

#### 23b-5. CSS 테마 고급 활용

**GTK4 제공 API** (`css-overview.html`, `css-properties.html`):

**CSS 의사 클래스 → GTK4 상태 플래그 매핑**:
| 의사 클래스 | GTK4 상태 | LCL 상태 |
|------------|----------|---------|
| `:hover` | PRELIGHT | 마우스 오버 |
| `:active` | ACTIVE | 버튼 누름 |
| `:focus` | FOCUSED | 키보드 포커스 |
| `:focus-visible` | (위젯+조상) | 키보드 포커스 시각화 |
| `:disabled` | INSENSITIVE | Enabled=False |
| `:checked` | CHECKED | CheckBox/Radio 선택 |
| `:indeterminate` | INCONSISTENT | CheckBox 3상태 |
| `:backdrop` | BACKDROP | 비활성 윈도우 |
| `:selected` | SELECTED | 항목 선택 |
| `:drop(active)` | DROP_ACTIVE | DnD 호버 대상 |
| `:dir(ltr/rtl)` | — | BiDiMode |

**LCL 관련 핵심 CSS 프로퍼티**:
- 텍스트: `color` (Font.Color), `font-family/size/style/weight` (Font.*), `text-decoration-line` (fsUnderline/fsStrikeOut), `caret-color`
- 배경: `background-color` (Color), `background-image` (그래디언트)
- 테두리: `border-*-width/style/color`, `border-radius` (둥근 모서리)
- 박스: `margin-*`, `padding-*`, `min-width/height`
- 효과: `opacity`, `box-shadow`, `filter`, `transition-*`, `animation-*`
- GTK 전용: `-gtk-icon-source`, `-gtk-icon-size`, `-gtk-dpi`
- 색상 함수: `@define-color Name Color`, `lighter()`, `darker()`, `shade()`, `alpha()`, `mix()`
- 위젯 CSS 클래스: `.flat`, `.suggested-action`, `.destructive-action`, `.linked`, `.circular`, `.osd`

**현재 LCL 상태**: 기본 CSS 제공자 사용 (FMaxCssProvider). 의사 클래스/변수 미활용. `gtk_css_provider_load_from_data` 이미 광범위 사용 중.

**개선 방안**: 새 바인딩 불필요 (기존 CssProvider로 충분). 점진적 CSS 규칙 추가로 테마 일관성 향상.

**난이도**: 낮음 (0 바인딩) | **효과**: 중간 (테마 일관성, 시각 피드백)

#### 23b-6. 제스처 입력 (터치/태블릿)

**GTK4 제공 API** (`class.Gesture*.html`):
- `GtkGestureDrag`: 드래그 추적 (시작점+오프셋)
- `GtkGestureLongPress`: 길게 누르기 (컨텍스트 메뉴)
- `GtkGestureSwipe`: 스와이프 (속도 벡터)
- `GtkGestureRotate`: 2점 회전 (멀티터치)
- `GtkGestureZoom`: 2점 줌 (멀티터치)
- `GtkGestureStylus`: 스타일러스/태블릿 입력 (압력, 기울기)

**현재 LCL 상태**: ✅ **S70 바인딩 완료**: GestureClick 외에 GtkGestureDrag/LongPress/Swipe/Rotate/Zoom/Stylus 생성자 6개 + 헬퍼 5개 + GestureSingle 3개 = 14개 함수 바인딩 (lazgtk4_compat.pas). 이벤트 컨트롤러 통합(widget_add_controller + 시그널 연결)만 필요.

**난이도**: ~~중간~높음~~ 바인딩 완료 | **효과**: 중간 (터치/태블릿 UX)

#### 23b-7. GtkShortcutController — 현대적 단축키 시스템

**GTK4 제공 API** (`class.ShortcutController.html`, `class.Shortcut.html`, `class.ShortcutTrigger.html`, `class.ShortcutAction.html`):

**GtkShortcutController** (GtkEventController, GListModel 구현):
| API | 설명 |
|-----|------|
| `gtk_shortcut_controller_new()` | 빈 컨트롤러 생성 |
| `add_shortcut(GtkShortcut*)` | 단축키 추가 |
| `remove_shortcut(GtkShortcut*)` | 단축키 제거 |
| `set_scope(GtkShortcutScope)` | LOCAL/MANAGED/GLOBAL |
| `set_mnemonics_modifiers(GdkModifierType)` | 니모닉 수정자 |

**GtkShortcut** = Trigger + Action:
| API | 설명 |
|-----|------|
| `gtk_shortcut_new(trigger, action)` | 생성자 |
| **Trigger** `gtk_shortcut_trigger_parse_string("<Control>s")` | 키 조합 파싱 (Primary=Ctrl/Cmd) |
| **Action** `gtk_callback_action_new(func, data, destroy)` | 콜백 액션 |
| **Action** `gtk_signal_action_new("clicked")` | 시그널 발동 |
| **Action** `gtk_named_action_new("win.save")` | GAction 활성화 |
| **Action** `gtk_activate_action_get()` | widget_activate() |

**GtkShortcutScope**: `LOCAL` (위젯 자체), `MANAGED` (GtkShortcutManager=GtkWindow/GtkPopover까지 전파), `GLOBAL` (루트)

**현재 LCL 상태**: ✅ **S70 바인딩 완료**: 기존 8개 (new, add/remove_shortcut, set_scope, shortcut_new, keyval_trigger_new, activate_action_get, callback_action_new) + S70 추가 10개 (parse_string, mnemonic/alternative/never trigger, signal/named/nothing/mnemonic action, set_mnemonics_modifiers) = 총 18개. 메뉴 가속키는 GMenu `accel` 속성 기반으로 동작 중. ShortcutController 통합은 향후 과제.

**필요 바인딩**: ~~20개~~ 0개 (18개 완료)

**난이도**: ~~중간~~ 바인딩 완료 | **효과**: 중간 (단축키 관리 현대화, GtkAccelGroup 대체)

#### 23b-8. IMContext — 입력 메서드 프레임워크 (R30 신규)

**GTK4 제공 API** (`class.IMContext.html`, `class.IMContextSimple.html`, `class.IMMulticontext.html`):

**GtkIMContext** (모든 텍스트 위젯의 입력 메서드 기반):
| API | 설명 |
|-----|------|
| `gtk_im_context_set_client_widget(widget)` | IMContext를 위젯에 연결 |
| `gtk_im_context_filter_keypress(event)` | 키 이벤트를 IM으로 전달 → gboolean (소비 여부) |
| `gtk_im_context_get_preedit_string(&str, &attrs, &cursor)` | **핵심**: 조합 중 문자열 + PangoAttrList + 커서 위치 |
| `gtk_im_context_set_cursor_location(GdkRectangle*)` | pre-edit 표시 위치 설정 (커서 근처) |
| `gtk_im_context_set_surrounding(text, len, cursor_index)` | 주변 텍스트 제공 (IM이 문맥 기반 제안에 활용) |
| `gtk_im_context_focus_in()` / `focus_out()` | IM 활성/비활성 |
| `gtk_im_context_reset()` | 조합 상태 초기화 |
| **시그널** `commit(str)` | 확정 입력 — LCL에 UTF-8 문자열 전달 |
| **시그널** `preedit-start()` / `preedit-end()` | 조합 시작/종료 |
| **시그널** `preedit-changed()` | **핵심**: 조합 중간 상태 변경 — `get_preedit_string` 호출 후 표시 갱신 |

**GtkIMMulticontext**: 시스템 IM 설정에 따라 적절한 IM 모듈 자동 선택 (ibus, fcitx, scim 등)

**현재 LCL 상태**: ✅ **S69 구현 완료** — `commit` + `preedit-start`/`preedit-end`/`preedit-changed` 4종 시그널 연결. `gtk_im_multicontext_new` 사용 (시스템 IM 자동 선택). `LM_IM_COMPOSITION` 메시지로 LCL 컨트롤에 전달. `set_cursor_location` 구현 완료 — `SetCaretPosEx`에서 캐럿 위치 변경 시 `IMContext^.set_cursor_location` 호출 (gtk4winapi.inc). `IMContext` public property 추가 (gtk4widgets.pas).

**LCL 통합 패턴**:
```
[preedit 표시]: preedit-changed → get_preedit_string → 커서 위치에 오버레이 문자열 렌더링
[커서 위치]: focus_in → set_cursor_location(GdkRect(CaretX, CaretY, 0, FontHeight))
[주변 텍스트]: surrounding → set_surrounding(편집 컨트롤 텍스트, 커서 인덱스)
[확정]: commit → LM_CHAR/UTF8KeyPress 전달 (현재 동작)
```

**필요 바인딩**: ~8개 (get_preedit_string, set_cursor_location, set_surrounding, focus_in/out, 시그널 3종)

**난이도**: 중간 (IM 프로토콜 이해 필요) | **효과**: **매우 높음** (한중일 입력 완전 지원 — 현재 Bug#25)

#### 23b-9. SelectionModel & 필터/정렬 모델 (R30 신규)

**GTK4 제공 API** (`iface.SelectionModel.html`, `class.FilterListModel.html`, `class.SortListModel.html`):

**GtkSelectionModel** (인터페이스 — GtkListView/GtkColumnView/GtkGridView가 사용):
| API | 설명 |
|-----|------|
| `gtk_selection_model_get_selection() → GtkBitset*` | 전체 선택 상태 비트셋 |
| `gtk_selection_model_get_selection_in_range(pos, n)` | 범위 내 선택 |
| `gtk_selection_model_select_item(pos, unselect_rest)` | 단일 선택 |
| `gtk_selection_model_select_range(pos, n, unselect_rest)` | 범위 선택 |
| `gtk_selection_model_select_all()` / `unselect_all()` | 전체 선택/해제 |
| **시그널** `selection-changed(pos, n_items)` | 선택 변경 알림 |

**구현체**: `GtkSingleSelection` (단일), `GtkMultiSelection` (다중), `GtkNoSelection` (선택 없음)

**GtkFilterListModel** (모델 필터링):
| API | 설명 |
|-----|------|
| `gtk_filter_list_model_new(model, filter)` | 필터 적용 모델 |
| `gtk_custom_filter_new(match_func, data, destroy)` | 커스텀 필터 |
| `gtk_string_filter_new(expression)` | 문자열 필터 |
| `gtk_bool_filter_new(expression)` | 불리언 필터 |

**모델 체이닝 패턴** (GTK4 데이터 파이프라인):
```
GtkStringList (원본)
  → GtkFilterListModel (검색)
    → GtkSortListModel (정렬)
      → GtkSingleSelection (선택)
        → GtkListView / GtkColumnView (표시)
```

**현재 LCL 상태**: ✅ **S70 바인딩 완료**. SelectionModel 인터페이스+3개 구현체 이미 완전 바인딩 (S55). S70 추가: GtkFilter 기반 (match/get_strictness/changed), GtkCustomFilter (new/set_filter_func), GtkFilterListModel (new/set_filter/get_filter/set_model/get_model/set_incremental/get_incremental/get_pending), GtkSorter 기반 (compare/get_order/changed), GtkSortListModel (new/set_sorter/get_sorter/set_model/get_model/set_incremental/get_incremental/get_pending), enum 5개 (TGtkOrdering, TGtkSorterOrder, TGtkSorterChange, TGtkFilterMatch, TGtkFilterChange), TGtkCustomFilterFunc 콜백 타입. 총 22개 함수 + 5 enum + 1 콜백 타입. ListView 통합(모델 체이닝)은 향후 필요 시 추가.

**필요 바인딩**: 0개 (22개 완료)

**난이도**: ~~중간~~ 바인딩 완료 | **효과**: ~~높음~~ **바인딩 완료** — ListView 필터/정렬 통합은 향후 과제

#### 23b-10. 클립보드 — GdkClipboard 비동기 시스템 (R30 신규)

**GTK4 제공 API** (`class.Clipboard.html`, `class.ContentProvider.html`):

**GTK4 클립보드 핵심 변경**: GTK4에서 클립보드는 **완전 비동기**. GTK2의 `gtk_clipboard_get/set_text` 동기 API 제거.

| API | 설명 |
|-----|------|
| `gdk_display_get_clipboard(display) → GdkClipboard*` | 시스템 클립보드 |
| `gdk_display_get_primary_clipboard(display)` | X11 primary selection |
| `gdk_clipboard_set_content(GdkContentProvider*)` | **핵심**: 클립보드에 데이터 설정 |
| `gdk_clipboard_read_text_async(clipboard, cancellable, callback, data)` | **비동기** 텍스트 읽기 |
| `gdk_clipboard_read_text_finish(clipboard, result) → char*` | 비동기 결과 수신 |
| `gdk_clipboard_read_value_async(clipboard, GType, ...)` | 범용 타입 비동기 읽기 |
| **시그널** `changed()` | 클립보드 내용 변경 알림 |
| `gdk_clipboard_get_formats() → GdkContentFormats*` | 사용 가능 MIME 타입 |

**GdkContentProvider** (클립보드/DnD 공용 데이터 공급):
| API | 설명 |
|-----|------|
| `gdk_content_provider_new_for_value(GValue*)` | GValue 래핑 |
| `gdk_content_provider_new_for_bytes(mime, GBytes*)` | 원시 바이트 |
| `gdk_content_provider_new_typed(GType, ...)` | 타입 지정 |
| `gdk_content_provider_new_union(providers[], n)` | 다중 형식 |

**현재 LCL 상태**: ✅ **S69 확인 — 이미 완전 구현**. `ClipboardGetData` (gtk4winapi.inc:196-272): 텍스트는 `gdk4_clipboard_read_text_async`, 기타 MIME은 `gdk4_clipboard_read_async` + GInputStream 4KB 청크 읽기. `ClipboardGetOwnerShip` (gtk4winapi.inc:317-381): 모든 포맷을 `gdk4_content_provider_new_for_bytes` + `gdk4_content_provider_new_union`. `ClipboardGetFormats`: `gdk4_content_formats_get_mime_types`로 전체 포맷 열거. 제네릭 바이너리 경로가 image/png, image/jpeg 등 모든 MIME 지원.

**필요 바인딩**: ~10개 (ContentProvider 4 + read_value_async 2 + ContentFormats 2 + 기타)

**난이도**: 중간 (비동기 패턴 + MIME 타입 매핑) | **효과**: 중간 (이미지/RTF 클립보드 지원)

#### 23b-11. PrintOperation — 인쇄 시스템 (R30 신규)

**GTK4 제공 API** (`class.PrintOperation.html`, `class.PrintContext.html`):

| API | 설명 |
|-----|------|
| `gtk_print_operation_new()` | 인쇄 작업 생성 |
| `gtk_print_operation_set_n_pages(n)` | 총 페이지 수 설정 |
| `gtk_print_operation_run(action, parent) → result` | 인쇄 실행 (대화상자 표시) |
| **시그널** `begin-print(PrintContext)` | 인쇄 시작 — 페이지 수 계산 |
| **시그널** `draw-page(PrintContext, page_nr)` | **핵심**: 페이지 렌더링 — Cairo context 제공 |
| **시그널** `end-print(PrintContext)` | 인쇄 완료 |
| **시그널** `paginate(PrintContext) → gboolean` | 선택적 페이지네이션 |

**GtkPrintContext** (Cairo 기반 렌더링):
| API | 설명 |
|-----|------|
| `gtk_print_context_get_cairo_context() → cairo_t*` | **핵심**: Cairo DC — LCL 캔버스와 직접 연결 가능 |
| `get_width()` / `get_height()` | 인쇄 가능 영역 (포인트 단위) |
| `get_dpi_x()` / `get_dpi_y()` | 프린터 DPI |
| `get_page_setup() → GtkPageSetup*` | 용지/여백 설정 |

**관련 클래스**: `GtkPageSetup` (용지 크기/방향/여백), `GtkPrintSettings` (프린터/양면/매수), `GtkPrintUnixDialog` (Linux 인쇄 대화상자)

**현재 LCL 상태**: ✅ **S70 완료**. `lazgtk4.pas`에 127개 인쇄 관련 바인딩 이미 존재 (TGtkPrintOperation, TGtkPrintSettings, TGtkPageSetup, TGtkPrintContext, gtk_print_run_page_setup_dialog 등). `gtk4prndialogs.inc` (426줄)에 네이티브 GTK4 다이얼로그 구현 완료 (TPageSetupDialog → gtk_print_run_page_setup_dialog, TPrintDialog → GtkPrintOperation + PRINT_DIALOG action, TPrinterSetupDialog → CUPS LCL form 재사용). `printersdlgs.pp`에 `{$IFDEF LCLGtk4}` 조건 추가하여 활성화. 프린터 백엔드는 `osprinters.pas`에서 CUPS 폴스루 (GTK2와 동일 패턴). finalization에서 Gtk4StoredPrintSettings/Gtk4StoredPageSetup 해제.

**필요 바인딩**: 0개 (127개 이미 존재)

**난이도**: ~~높음~~ 완료 | **효과**: ~~높음~~ **완료** — 네이티브 GTK4 인쇄/페이지설정 다이얼로그 + CUPS 백엔드

#### 23b-12. GdkTexture — GdkPixbuf 현대적 대체 (R30 신규)

**GTK4 제공 API** (`class.Texture.html`, `class.MemoryTexture.html`, `class.GLTexture.html`):

GTK4에서 `GdkPixbuf`는 **deprecated**. `GdkTexture`가 공식 대체.

| API | 설명 |
|-----|------|
| `gdk_texture_new_for_pixbuf(pixbuf)` | GdkPixbuf → GdkTexture 변환 (호환 레이어) |
| `gdk_memory_texture_new(width, height, format, bytes, stride)` | 원시 픽셀 → 텍스처 |
| `gdk_texture_download(texture, data, stride)` | 텍스처 → 원시 픽셀 (GTK4 4.6) |
| `gdk_texture_get_width/height(texture)` | 크기 조회 |
| `gdk_texture_save_to_png(texture, filename)` | PNG 저장 |
| `gdk_texture_save_to_tiff(texture, filename)` | TIFF 저장 (4.6+) |

**GdkMemoryFormat**: `B8G8R8A8_PREMULTIPLIED`, `A8R8G8B8_PREMULTIPLIED`, `R8G8B8A8`, `B8G8R8A8`, `R8G8B8`, `B8G8R8` 등

**현재 LCL 상태**: ✅ **S70 바인딩 완료**: lazgtk4_compat.pas에 GdkTexture/GdkMemoryTexture API 10개 함수 + TGdkMemoryFormat enum (19값) 추가:
- `gdk4_texture_new_for_pixbuf` (기존), `gdk4_texture_get_width/height`, `gdk4_texture_download`, `gdk4_texture_save_to_png/png_bytes`, `gdk4_memory_texture_new`, `gdk4_texture_new_from_file/filename/resource`
- `gdk_pixbuf_get_from_surface` 7곳 + `gdk_cairo_set_source_pixbuf` 4곳은 GTK 4.6에서 deprecated이지만 정상 동작. 실제 마이그레이션 (Cairo surface→pixel data→GdkMemoryTexture)은 향후 GTK5 대비 시 수행.

**마이그레이션 패턴**:
```
[이전] gdk_pixbuf_get_from_surface(surface, 0, 0, w, h)
[이후] GdkTexture는 cairo_surface에서 직접 생성 불가 → cairo_surface → pixel data → gdk_memory_texture_new

[이전] gdk_cairo_set_source_pixbuf(cr, pixbuf, x, y)
[이후] gdk_texture → gtk_snapshot_append_texture 또는 GdkPaintable → draw()
```

**필요 바인딩**: ~~12개~~ 0개 (10개 완료)

**난이도**: ~~중간~~ 바인딩 완료 | **효과**: 바인딩 준비됨 — 실제 마이그레이션은 GTK5 대비 시 수행

#### 23b-13. GtkSettings — 시스템 설정 통합 (R32 신규)

**GTK4 제공 API** (`class.Settings.html`):

GtkSettings는 디스플레이별 글로벌 설정 싱글톤. X11/Wayland 세션 매니저 또는 DConf에서 테마/폰트/커서 등 시스템 설정을 읽는다.

| API | 설명 |
|-----|------|
| `gtk_settings_get_default()` | 기본 디스플레이 설정 싱글톤 반환 |
| `gtk_settings_get_for_display(display)` | 특정 디스플레이 설정 |
| `gtk_settings_reset_property(name)` | 시스템 기본값으로 복원 |

**핵심 프로퍼티** (47개 중 주요):

| 프로퍼티 | 타입 | 용도 |
|---------|------|------|
| `gtk-font-name` | string | 시스템 기본 폰트 (예: "Noto Sans 10") |
| `gtk-theme-name` | string | GTK 테마명 (예: "Adwaita") |
| `gtk-icon-theme-name` | string | 아이콘 테마명 |
| `gtk-cursor-theme-name` | string | 커서 테마명 |
| `gtk-cursor-theme-size` | int | 커서 크기 |
| `gtk-xft-dpi` | int | DPI × 1024 (예: 98304 = 96 DPI) |
| `gtk-double-click-time` | int | 더블클릭 간격 (ms) |
| `gtk-enable-animations` | bool | 애니메이션 활성화 |
| `gtk-application-prefer-dark-theme` | bool | 다크 테마 선호 |
| `gtk-overlay-scrolling` | bool | 오버레이 스크롤바 |

**현재 LCL GTK4 상태**: ✅ **이미 바인딩됨** — lazgtk4.pas에 `TGtkSettings` 타입 + `get_default()`/`get_for_screen()`/`reset_property()` 3개 메서드 존재. 사용처 3곳:
- `gtk4winapi.inc`: `GetDoubleClickTime()` — `g_object_get_property('gtk-double-click-time')`
- `gtk4object.inc`: `SetDefaultAppFontName()` — `g_object_get_property('gtk-font-name')`
- `gtk4object.inc`: `LoadCSSTheme()` — `g_object_get_property('gtk-theme-name')`

**결론**: 핵심 함수 이미 바인딩되어 동작 중. 프로퍼티 접근은 `g_object_get_property` 제네릭 API 사용 (타입화된 접근자 없어도 충분). **추가 바인딩 불필요** (~0개).

**난이도**: N/A (이미 완료) | **효과**: N/A (기존 동작 중)

#### 23b-14. GtkExpression — 속성 바인딩 시스템 (R32 신규)

**GTK4 제공 API** (`class.Expression.html`, `class.PropertyExpression.html`):

GtkExpression은 GTK4 4.0에서 도입된 **속성 참조 + 지연 평가 + 변경 추적** 시스템. 주로 GtkDropDown, GtkListView, GtkColumnView의 **동적 데이터 바인딩**에 사용된다.

| API | 설명 |
|-----|------|
| `gtk_constant_expression_new(type, value)` | 상수 표현식 |
| `gtk_property_expression_new(type, expr, property)` | 속성 참조 체이닝 (예: `item→label→text`) |
| `gtk_closure_expression_new(type, closure, params)` | 커스텀 변환 함수 |
| `gtk_object_expression_new(object)` | 객체 참조 |
| `gtk_expression_evaluate(expr, this, value)` | 표현식 평가 |
| `gtk_expression_bind(expr, target, property)` | 라이브 바인딩 생성 |
| `gtk_expression_watch(expr, data, notify)` | 변경 감시 |
| `gtk_expression_ref/unref(expr)` | 참조 카운팅 |

**현재 LCL GTK4 상태**: ✅ **S70 바인딩 완료**: lazgtk4_compat.pas에 GtkExpression API 11개 함수 + PGtkExpressionWatch 타입 추가:
- `gtk4_constant_expression_new_for_value` — 상수 표현식 (GValue)
- `gtk4_property_expression_new` — 속성 체이닝 (type+expr+property)
- `gtk4_cclosure_expression_new` — 커스텀 C 클로저 표현식
- `gtk4_expression_evaluate` — 표현식 평가
- `gtk4_expression_watch/watch_unwatch/watch_evaluate` — 변경 감시
- `gtk4_expression_ref/unref` — 참조 카운팅
- `gtk4_expression_get_value_type/is_static` — 메타데이터
- `gtk4_expression_bind` — 라이브 프로퍼티 바인딩
기존 GtkDropDown 관련 (`new`, `get/set_expression`)과 합산하면 모든 핵심 Expression API가 바인딩됨.

**필요 바인딩**: ~~12-15개~~ 0개 (11개 완료)

**LCL 영향 평가**: ✅ **바인딩 완료** — 향후 GtkColumnView 고급 기능, GtkDropDown 커스텀 모델에 즉시 활용 가능.

**난이도**: ~~중간~~ 바인딩 완료 | **효과**: 중간 — 향후 Phase 2에 활용 가능

### 23c. 향후 개발 우선순위

**R32 "패리티" 의미 정리**: Session 55에서 "GTK4 at full functional parity with Qt5"로 선언한 것은 **WS 메서드 API 커버리지** 기준 (IMPL/MISS/STUB 개수 — 메서드 존재 여부). 아래 Priority 1/1b 항목은 **기능 동작** 기준에서 여전히 실질적 갭:
- **Drag & Drop**: WS에 STUB 메서드 존재하나 기능 미동작
- ~~**ListView SetSort**~~: ✅ **수정됨 (Session 61)** — `ModelNotifyItemsChanged` 구현
- ~~**IMContext**~~: ✅ **수정됨 (S69)** — preedit-changed/start/end + LM_IM_COMPOSITION 전달
- **PrintOperation**: GTK4 프린터 통합 코드 전무

즉 "API 패리티" ≠ "기능 패리티". 아래 우선순위는 **기능 패리티** 관점에서 잔여 작업을 정리한 것이다.

GTK4 문서 분석 결과를 반영한 개발 우선순위:

#### Priority 1 — 기능 회복 (GTK4 전환 시 손실된 기능)

| 항목 | 현재 상태 | GTK4 대체 API | 바인딩 수 | 난이도 | 효과 |
|------|----------|-------------|----------|--------|------|
| ~~**Drag & Drop**~~ | ~~5 STUB (DragImageList) + 미구현~~ ✅ **S70 바인딩 완료**: 42개 함수. 인트라앱 DnD+파일드롭 이미 동작. DragImage=Wayland 제한. 크로스앱 연결만 잔여 | `GtkDropTarget` + `GtkDragSource` + `GdkContentProvider` (§23b-1 상세) | ~~30개~~ **42개 완료** | ~~높음~~ 바인딩 완료 | ~~매우 높음~~ |
| **SetWindowRgn** (비직사각 윈도우) | stub — `gtk_widget_shape_combine_region` 제거됨 | GTK4에서 **대체 불가** — CSK/렌더 노드 기반 접근 필요 | N/A | 매우 높음 | 낮음 |
| ~~**ListView SetSort**~~ | ~~`queue_draw`만 호출~~ ✅ **S61 수정**: `ModelNotifyItemsChanged` | ~~`GtkCustomSorter` + `GtkSortListModel`~~ 불필요 — LCL 레벨 정렬 + 모델 갱신으로 해결 | 0 | ~~중간~높음~~ 완료 | ✅ |

#### Priority 1b — 주요 기능 미구현 (R30 추가)

| 항목 | 현재 상태 | GTK4 대체 API | 바인딩 수 | 난이도 | 효과 |
|------|----------|-------------|----------|--------|------|
| ~~**IMContext pre-edit**~~ | ~~commit만 연결, preedit 미연결~~ | ✅ **수정됨 (S69)**: `preedit-start`/`end`/`changed` 시그널 연결 + `LM_IM_COMPOSITION` 전달 + `gtk_im_multicontext_new` | ~~~8개~~ | ~~중간~~ | ~~매우 높음~~ |
| ~~**PrintOperation**~~ | ~~GTK4 프린터 통합 없음~~ | ✅ **수정됨 (S70)**: printersdlgs.pp에 LCLGtk4 조건 추가 → gtk4prndialogs.inc (네이티브 GtkPrintOperation 다이얼로그) 활성화. 바인딩 127개 이미 존재 (lazgtk4.pas). CUPS 백엔드 정상 폴스루. | ~~~20개~~ 0 | ~~높음~~ | ~~높음~~ **완료** |

#### Priority 2 — 품질 개선 (동작하지만 개선 필요)

| 항목 | 현재 상태 | GTK4 활용 방안 | 바인딩 수 | 난이도 | 효과 |
|------|----------|--------------|----------|--------|------|
| ~~**접근성 역할/상태**~~ ✅ | ~~미설정~~ **S69 구현**: TGtk4WSLazAccessibleObject 8/8 메서드, 바인딩 6함수+4enum, factory 등록 활성화 | ~~`update_property/state/relation`~~ 완료 | ~~~15+enum~~ 0 | ~~낮음~중간~~ | ~~높음~~ **완료** |
| ~~**SelectionModel/Filter**~~ | ~~GtkSingleSelection 기본만~~ | ✅ **S70 바인딩 완료**: SelectionModel 이미 완전 구현 (S55). S70 추가: GtkFilter/GtkCustomFilter/GtkFilterListModel/GtkSortListModel/GtkSorter 기반 바인딩 22개 + enum 5개 (lazgtk4_compat.pas). ListView 통합은 향후 필요 시 추가. | ~~~15개~~ 0 | ~~중간~~ | ~~높음~~ **바인딩 완료** |
| ~~**EventControllerScroll**~~ ✅ | ~~Legacy fallback~~ **이미 구현+S68 버그수정** | ~~`scroll`/`decelerate` 시그널 + KINETIC 플래그 (§23b-3 상세)~~ | ~~~4개~~ 0 | ~~낮음~~ | ~~중간~~ **완료** |
| ~~**CSS 테마 고급**~~ ✅ | ~~하드코딩 SysColorMap~~ **오보정 (S69 확인)**: SysColorMap은 `UpdateSysColorMap`에서 `gtk_style_context_lookup_color`로 테마 동적 쿼리. 위젯별 CSS Provider, 글로벌 앱 CSS, user theme.css 지원. SetColor/SetFont 모두 CSS 기반. 의사 클래스는 GTK4가 자동 처리 (`:hover`/`:focus`/`:disabled`) | 0개 | 없음 | 없음 — **이미 완료** |
| ~~**Clipboard 멀티 형식**~~ ✅ | ~~텍스트만 동작~~ **오보정 (S69 확인)**: 제네릭 바이너리 경로 이미 존재 — `ClipboardGetData`가 임의 MIME 타입(image/png 등)을 `gdk4_clipboard_read_async` + GInputStream으로 읽음. `ClipboardGetOwnerShip`가 `gdk4_content_provider_new_for_bytes`로 모든 MIME 제공. 텍스트 전용이 아님 | ~~10개~~ 0 | ~~중간~~ | ~~중간~~ **이미 동작** |
| ~~**GdkTexture 마이그레이션**~~ ✅ | ~~`gdk_pixbuf_get_from_surface` 7곳 deprecated~~ **S70 바인딩 완료**: GdkMemoryFormat enum (19값) + gdk4_texture_get_width/height + download + save_to_png/png_bytes + memory_texture_new + new_from_file/filename/resource = 9개 함수 + 1 enum. 기존 texture_new_for_pixbuf 포함 총 10개. 실제 마이그레이션(Cairo→pixel→Texture 변환)은 GTK5 대비 향후 과제 | ~~12개~~ **10개 완료** | ~~중간~~ 바인딩 완료 | 낮음 (동작 중, 바인딩 준비됨) |
| ~~**CellRenderer 잔존 코드**~~ ✅ | ~~gtk4cellrenderer.pas 43줄~~ **오보정 (S69 확인)**: 773줄, TreeView/ComboBox/ListView에 의해 활발히 사용 중. 데드 코드 아님 | 해당 없음 | 0개 | 없음 | 없음 |

#### Priority 3 — 신기능 (현재 없지만 있으면 좋은 기능)

| 항목 | GTK4 API | 바인딩 수 | 난이도 | 효과 |
|------|---------|----------|--------|------|
| ~~열 헤더 컨텍스트 메뉴~~ ✅ | ~~`gtk4_column_view_column_set_header_menu`~~ **이미 바인딩됨**: `gtk4_column_view_column_get/set_header_menu` (lazgtk4_compat.pas). 통합만 필요 | ~~2개~~ 0 | ~~중간~~ **바인딩 완료** | 중간 |
| ~~다중 선택 모델~~ ✅ | ~~`GtkMultiSelection`~~ **오보정 (S69 확인)**: 이미 완전 구현됨 — TGtk4ListBox/ListView/CheckListBox에서 MultiSelect=True 시 `gtk4_multi_selection_new` 사용, 바인딩 4개 완료 (new/get_type/get_model/set_model) | ~~3개~~ 0 | ~~낮음~~ | ~~낮음~~ **완료** |
| ~~GtkShortcutController~~ ✅ | ~~`ShortcutController` + `Shortcut` + `Trigger/Action`~~ **S70 바인딩 완료**: 기존 8개 + S70 추가 10개 (parse_string, mnemonic/alternative/never trigger, signal/named/nothing/mnemonic action, set_mnemonics_modifiers) = 총 18개. 통합만 필요 | ~~20개~~ **18개 완료** | ~~중간~~ 바인딩 완료 | 중간 |
| ~~제스처 입력 (터치/태블릿)~~ ✅ | ~~`GtkGestureDrag/LongPress/Swipe/Zoom/Rotate/Stylus`~~ **S70 바인딩 완료**: 생성자 6개 (Drag/LongPress/Swipe/Rotate/Zoom/Stylus) + 헬퍼 5개 (get_start_point/get_offset/get_velocity/get_angle_delta/get_scale_delta) + GestureSingle 3개 (set_exclusive/touch_only/button) = 총 14개. 통합만 필요 | ~~25개~~ **14개 완료** | ~~높음~~ 바인딩 완료 | 중간 |
| GtkConstraintLayout | 선언적 레이아웃 (GtkFixedLayout 대체) | 매우 많음 | 매우 높음 | 높음 (위험도 높음) |

**R30 바인딩 수 총 추정**: Priority 1 = ~42개, Priority 1b = ~28개 (IMContext 8 + Print 20), Priority 2 = ~56개+enum (기존 19 + SelectionModel 15 + Clipboard 10 + GdkTexture 12), Priority 3 = ~50개+Expression 12. 합계 **~188개 신규 바인딩** 필요 (lazgtk4_compat.pas 추가). **R32 참고**: GtkSettings는 이미 바인딩 완료 (추가 불필요), GtkExpression ~12개 → Priority 3 합산, GtkRoot 3-5개 → Priority 3 합산.

### 23d. GTK4 API 레퍼런스 요약 (개발자 참조용)

`/usr/share/doc/libgtk-4-doc/` 기준 핵심 문서 위치:

| 카테고리 | 문서 경로 | 설명 |
|---------|----------|------|
| **마이그레이션** | `gtk4/migrating-3to4.html` | GTK3→GTK4 마이그레이션 완전 가이드 |
| **마이그레이션** | `gtk4/migrating-2to4.html` | GTK2→GTK4 직접 마이그레이션 가이드 |
| **위젯 레퍼런스** | `gtk4/class.{WidgetName}.html` | 개별 위젯 API (메서드, 시그널, 프로퍼티) |
| **이벤트 컨트롤러** | `gtk4/class.EventController*.html` | 이벤트 처리 API (Key, Motion, Focus, Scroll, Legacy) |
| **제스처** | `gtk4/class.Gesture*.html` | 제스처 API (Click, Drag, LongPress, Swipe, Rotate, Zoom) |
| **DnD** | `gtk4/class.DropTarget.html`, `class.DragSource.html` | 드래그앤드롭 API |
| **접근성** | `gtk4/iface.Accessible.html` | GtkAccessible 인터페이스 |
| **렌더링** | `gsk4/class.RenderNode.html` | GskRenderNode 렌더링 파이프라인 |
| **CSS** | `gtk4/css-overview.html`, `css-properties.html` | CSS 테마 시스템 |
| **GDK 표면** | `gdk4/class.Surface.html`, `iface.Toplevel.html` | GdkSurface/Toplevel/Popup |
| **입력 메서드** | `gtk4/class.IMContext.html`, `class.IMMulticontext.html` | IMContext pre-edit/commit 시스템 (R30) |
| **선택 모델** | `gtk4/iface.SelectionModel.html`, `class.SingleSelection.html` | ListView/ColumnView 선택 관리 (R30) |
| **필터/정렬 모델** | `gtk4/class.FilterListModel.html`, `class.SortListModel.html` | 모델 파이프라인 체이닝 (R30) |
| **클립보드** | `gdk4/class.Clipboard.html`, `class.ContentProvider.html` | 비동기 클립보드 + MIME 타입 (R30) |
| **인쇄** | `gtk4/class.PrintOperation.html`, `class.PrintContext.html` | 인쇄 시스템 Cairo 기반 (R30) |
| **텍스처** | `gdk4/class.Texture.html`, `class.MemoryTexture.html` | GdkPixbuf 대체 (R30) |
| **디바이스/시트** | `gdk4/class.Device.html`, `class.Seat.html` | 입력 장치 (마우스, 터치, 스타일러스) |
| **모니터/디스플레이** | `gdk4/class.Monitor.html`, `class.Display.html` | DPI/스케일/새로고침률 |
| **Editable 인터페이스** | `gtk4/iface.Editable.html` | 텍스트 편집 공통 인터페이스 (Entry/Text) |
| **스냅샷/렌더** | `gtk4/class.Snapshot.html`, `gsk4/class.RenderNode.html` | 커스텀 위젯 드로잉 |
| **텍스트 위젯** | `/usr/share/doc/libgtk-4-dev/text_widget_internals.txt.gz` | GtkTextView 내부 구조 (Memo 개선용) |
| **트리 열 크기** | `/usr/share/doc/libgtk-4-dev/tree-column-sizing.txt` | TreeView/ColumnView 열 크기 조정 알고리즘 |
| **시스템 설정** | `gtk4/class.Settings.html` | GtkSettings — 테마/폰트/커서/DPI 전역 설정 (R32 — 이미 바인딩 완료) |
| **표현식** | `gtk4/class.Expression.html`, `class.PropertyExpression.html` | GtkExpression — 동적 속성 바인딩 (R32 — ColumnView/DropDown 미래용) |
| **Root 인터페이스** | `gtk4/iface.Root.html` | GtkRoot — 톱레벨 위젯 인터페이스 (R32 — 현재 GtkWindow 직접 사용으로 충분) |
