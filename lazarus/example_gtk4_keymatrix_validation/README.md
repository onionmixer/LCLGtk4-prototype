# example_gtk4_keymatrix_validation — 키 전달 행렬 하네스 (2026-09-11)

컨트롤 하나에 포커스를 두고 xdotool 로 키 19개를 보내, OnKeyDown/OnKeyUp/OnKeyPress/OnUTF8KeyPress/폼 KeyPreview/
네이티브 효과(OnChange·기본/취소 버튼·EditingDone)를 시각 로그로 남긴다. gtk4(프로토타입 유닛), gtk2(프로토타입 유닛),
qt5(시스템 /usr/lib/lazarus/4.4 유닛) 세 위젯셋을 같은 소스로 빌드해 대조한다.

- `./build.sh gtk4|gtk2|qt5`  → `keymatrix_<ws>` (fpc 직접 호출, 유닛 재컴파일 없이 링크만)
- `./run.sh <ws> <control> [eatlist]` → `out/<ws>_<control>.log`(+ `.keys`). `KEYS="..." SUFFIX=_x` 로 키 목록/파일명 변경.
  eatlist = OnKeyDown 에서 `Key := 0` 으로 지울 VK 목록(예: `13,27`) — 억제 경로 검증용.
- `./runall.sh` → 14 컨트롤 × 3 위젯셋 전체. `python3 analyze.py [control...]` → 키별 gtk4/qt5/gtk2 대조표
  (`!!` = gtk4≠qt5, `~` = qt5≠gtk2). 시간 정렬 오프셋은 READY+1240ms(하네스 sleep 1.2s 기준).
- `baseline_2026-09-11/` : 수정 전 원본 로그와 `matrix_full.txt`, 스핀 재귀 크래시 gdb 백트레이스.
  `gtk4_edit.log`/`gtk4_spin.log` 는 포커스 이탈·크래시를 피한 축약 키 목록 실행본이고 원본은 `*_orig.log`.
컨트롤: edit spin comboedit combolist memo listbox checklist listview treeview button checkbox radio trackbar grid.

## 기준선 디렉터리
- `baseline_2026-09-11/` : 최초(순차 모드만, 14컨트롤) 원본 로그·행렬·codex 회신.
- `baseline_2026-09-11_pre_phase0/` : 격리(`_iso`)+순차, 3 위젯셋, Phase 0 수정 전. `signatures_{iso,seq}.json`.
- `baseline_2026-09-11_post_phase0/` : Phase 0(스핀 수정, 커밋 참조 HANDOFF) 후 gtk4 재측정 + 명령 키 시나리오(`*_cmd`, `*_empty`).
- 대조: `python3 compare.py <before.json> <after.json> [ws]`. 격리 모드의 Tab/shift+Tab 목적지는 재포커스 타이머(120ms)와
  경합하므로 **포커스 이동 판정은 순차 모드**로, 키별 전달 판정은 격리 모드로 본다.
