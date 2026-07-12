# PLAN: GTK4 Font CharSet Support

Date: 2026-07-08
Branch: main
Scope: LCL GTK4 only
Status: first canvas-font patch implemented and build-verified

## System Pango Baseline

Checked on 2026-07-08:

```text
pkg-config --modversion pango pangocairo gtk4
pango      1.50.6
pangocairo 1.50.6
gtk4       4.6.9
```

The implementation must target the installed Pango 1.50.6 API, not only the latest online `docs.gtk.org` API. The local version-matched sources of truth are:

- `/usr/include/pango-1.0/pango/pango-font.h`
- `/usr/include/pango-1.0/pango/pango-context.h`
- `/usr/include/pango-1.0/pango/pango-attributes.h`
- `/usr/include/pango-1.0/pango/pango-language.h`
- `/usr/include/pango-1.0/pango/pango-fontmap.h`
- `/usr/share/doc/libpango-1.0-0/NEWS.gz`

Relevant 1.50.6 NEWS facts:

- 1.50.6 fixes `pango_attr_list_change` ordering.
- 1.50.6 fixes a use-after-free in `pango_attr_list_change`.

This matters because the proposed implementation will merge a language attribute with existing underline/strikeout attributes on a `PangoLayout`.

## Goal

Improve the GTK4 widgetset so `TFont.CharSet` / `TLogFont.lfCharSet` affects GTK4/Pango font handling as much as GTK4 can reasonably support.

The goal is not legacy byte encoding conversion. LCL text in GTK4 is UTF-8/Unicode. The practical goal is to translate WinAPI-style charset requests into Pango language/script hints so font fallback, shaping, and metrics can better match the requested writing system.

## Source Facts

Pango 1.50.6 API facts from installed headers:

- `PangoFontDescription` is an opaque type. The public setters/getters in `pango-font.h` cover family, style, variant, weight, stretch, size, absolute size, gravity, variations, set-fields, merge, and string conversion. There is no public charset setter/getter.
- `pango_context_set_language` and `pango_context_get_language` are present in `pango-context.h` and marked `PANGO_AVAILABLE_IN_ALL`.
- `pango_context_get_metrics(context, desc, language)` is present in `pango-context.h` and accepts a `PangoLanguage`.
- `pango_context_load_fontset(context, desc, language)` is present in `pango-context.h`.
- `pango_font_map_load_fontset(fontmap, context, desc, language)` is present in `pango-fontmap.h`.
- `pango_attr_language_new(language)` is present in `pango-attributes.h` and marked `PANGO_AVAILABLE_IN_ALL`.
- `pango_attr_iterator_get_font(..., language, ...)` can expose the language resolved from an attribute iterator.
- `pango_language_from_string`, `pango_language_to_string`, `pango_language_matches`, and `pango_language_includes_script` are present in `pango-language.h`.

Latest online API references remain useful for semantics, but implementation decisions should be checked against the installed 1.50.6 headers:

- https://docs.gtk.org/Pango/method.Context.set_language.html
- https://docs.gtk.org/Pango/type_func.AttrLanguage.new.html
- https://docs.gtk.org/Pango/method.Context.get_metrics.html
- https://docs.gtk.org/Pango/method.FontMap.load_fontset.html

Local LCL GTK4 facts:

- `TGtk4Widget.SetLclFont` in `lcl/interfaces/gtk4/gtk4widgets.pas` currently applies name, size, style, weight, and color, but does not read `AFont.CharSet`.
- `TGtk4Font.Create(ALogFont, ALongFontName)` in `lcl/interfaces/gtk4/gtk4objects.pas` stores `ALogFont.lfCharSet` in `FLogFont`, but does not apply it to `PangoContext` or `PangoLayout`.
- `TGtk4Font.UpdateLogFont` preserves `lfCharSet` because Pango cannot represent it in `PangoFontDescription`.
- `CreateDefaultCharsetEncodings` in `lcl/interfaces/gtk4/gtk4procs.pas` already has WinAPI charset mapping data for enumeration-era X font charset names.
- `Gtk4GetFontFamilies(... AWritingSystem ...)` in `lcl/interfaces/gtk4/gtk4winapi.inc` accepts the charset argument but does not use it.
- `GetTextMetrics` and `GetTextExtentIgnoringAmpersands` currently pass `AFont.Layout^.get_context^.get_language` to Pango metrics, so applying the language to the layout context can affect metrics.

## Design Direction

Implement charset support as a language/script hint layer:

1. Add a GTK4 helper that maps LCL charset values to stable Pango language tags using Pango 1.50.6 APIs.
2. Apply that language tag to GTK4 canvas fonts created from `TLogFont`.
3. Preserve current `lfCharSet` roundtrip behavior.
4. Avoid changing text encoding semantics.
5. Keep widget font CSS behavior separate from canvas layout behavior; CSS cannot express WinAPI charset.

Initial charset-to-language mapping:

| LCL charset | Pango language tag | Notes |
| --- | --- | --- |
| `DEFAULT_CHARSET` | none | keep locale/default behavior |
| `ANSI_CHARSET` | none | avoid forcing Western scripts unless proven needed |
| `RUSSIAN_CHARSET` | `ru` | Cyrillic hint |
| `GREEK_CHARSET` | `el` | Greek hint |
| `HEBREW_CHARSET` | `he` | Hebrew hint |
| `ARABIC_CHARSET` | `ar` | Arabic hint |
| `THAI_CHARSET` | `th` | Thai hint |
| `SHIFTJIS_CHARSET` | `ja` | Japanese hint |
| `HANGEUL_CHARSET` | `ko` | Korean hint |
| `GB2312_CHARSET` | `zh-cn` | Simplified Chinese hint |
| `CHINESEBIG5_CHARSET` | `zh-tw` | Traditional Chinese hint |
| `TURKISH_CHARSET` | `tr` | Turkish localized glyph behavior may differ |
| `BALTIC_CHARSET` | none initially | region covers multiple languages |
| `EASTEUROPE_CHARSET` | none initially | region covers multiple languages |
| `VIETNAMESE_CHARSET` | `vi` | Vietnamese Latin hint |

Ambiguous regional charsets should start as no-op unless a concrete language mapping is justified by tests. A wrong language hint is worse than no hint.

## Proposed Implementation Steps

### Phase 1: Helper and Unit-Level Support

Target: `lcl/interfaces/gtk4/gtk4procs.pas`

- Add a helper similar to:
  - `function Gtk4CharSetToPangoLanguageTag(ACharSet: Byte): PgChar;`
  - or `function Gtk4CharSetToPangoLanguage(ACharSet: Byte): PPangoLanguage;`
- Prefer returning a language object only for unambiguous mappings.
- Keep `DEFAULT_CHARSET`, `ANSI_CHARSET`, ambiguous regional charsets as `nil`.
- Use `pango_language_from_string` for non-nil mappings. It is available in Pango 1.50.6.
- Do not allocate or free `PangoLanguage`; Pango language objects are interned/static from Pango's perspective.
- Add a small debug-only helper if needed to log charset/tag decisions during manual tests.

### Phase 2: Canvas Font Path

Target: `lcl/interfaces/gtk4/gtk4objects.pas`

- In `TGtk4Font.Create(ALogFont, ALongFontName)`:
  - after creating/binding `AContext`, derive `APangoLanguage` from `ALogFont.lfCharSet`;
  - call `AContext^.set_language(APangoLanguage)` when non-nil;
  - after `FLayout := pango_layout_new(AContext)`, apply a layout language attribute with `pango_attr_language_new`;
  - preserve existing underline/strikeout attributes by merging into the same `PangoAttrList`.
- Use `pango_attr_list_change` for language/underline/strikeout attribute insertion. Pango 1.50.6 includes fixes for order preservation and a use-after-free in this function.
- Ensure `FLogFont.lfCharSet` remains unchanged for `GetObject`.
- Clear or invalidate cached metrics when language-affecting data changes. A newly created font has clean metrics, but any future setter path must not reuse stale `CachedMetrics`.

### Phase 3: Metrics Consistency

Targets:

- `lcl/interfaces/gtk4/gtk4winapi.inc`
- `lcl/interfaces/gtk4/gtk4objects.pas`

Checks:

- `GetTextMetrics` should continue using the layout context language.
- `GetTextExtentIgnoringAmpersands` should use the same language context.
- If a path calls `pango_context_get_metrics(..., nil)` or default language directly, route it through the font/layout language where possible.
- Because Pango 1.50.6 exposes `pango_context_load_fontset` and `pango_font_map_load_fontset`, optional diagnostics can check whether a charset-derived language produces a non-nil fontset for the current description. This should be diagnostic only in the first patch, not a hard failure path.

### Phase 4: Widget `SetLclFont` Path

Target: `lcl/interfaces/gtk4/gtk4widgets.pas`

This phase needs a short experiment before code:

- Verify whether setting language on `GetContainerWidget^.get_pango_context` affects GTK-managed child text rendering in GTK4.
- If it is stable, apply `AFont.CharSet` as a context language hint in `SetLclFont`.
- If GTK4 recreates or ignores widget Pango contexts after CSS updates, do not pretend this path is supported. Document that widget text uses CSS font selection and GTK/Pango locale fallback, while LCL canvas fonts support charset language hints.

Do not add fake CSS properties for charset. GTK CSS has font-family/font-size/font-style/font-weight, not WinAPI charset.

### Phase 5: Font Enumeration

Target: `lcl/interfaces/gtk4/gtk4winapi.inc`

- Review `Gtk4GetFontFamilies(... AWritingSystem ...)`, which currently ignores the charset argument.
- Compare Qt implementation's `CharsetToQtCharSet` filtering behavior.
- Decide whether GTK4 should:
  - leave enumeration broad but report charset roundtrip values, or
  - use Pango fontset/coverage APIs to filter families by representative sample characters.
- Prefer a conservative separate change. Filtering font enumeration can affect font dialogs and installed-font visibility.

## Test Plan

Build checks:

- `make lcl LCL_PLATFORM=gtk4`
- `make bigide LCL_PLATFORM=gtk4`
- `make lcl LCL_PLATFORM=gtk2` for regression awareness

Behavior checks:

- Create a small GTK4 LCL app that draws sample Unicode text on `Canvas` with the same font name/size but different `Font.CharSet`.
- Compare `GetTextMetrics`, `TextWidth`, and rendered output for:
  - `DEFAULT_CHARSET`
  - `RUSSIAN_CHARSET` with Cyrillic sample
  - `GREEK_CHARSET` with Greek sample
  - `SHIFTJIS_CHARSET` with Japanese sample
  - `HANGEUL_CHARSET` with Korean sample
  - `GB2312_CHARSET` / `CHINESEBIG5_CHARSET` with Chinese samples
- Confirm that `GetObject(Font.Handle, ...)` still returns the requested `lfCharSet`.
- Confirm underline/strikeout attributes still work after adding language attributes.
- Confirm normal Latin/default rendering is unchanged when `CharSet = DEFAULT_CHARSET`.

Optional manual app:

- Add a temporary local test program under `/tmp` or a scratch directory, not committed, that logs:
  - `Font.CharSet`
  - resolved language tag
  - `GetTextMetrics.tmHeight/tmAveCharWidth/tmMaxCharWidth`
  - `Canvas.TextWidth(sample)`

## Risks

- Language hints are not legacy encoding conversion. Applications expecting byte-level charset conversion will still need explicit text conversion before LCL drawing.
- Some charsets map to regions, not languages. Applying a wrong language can change shaping/localized glyphs incorrectly.
- Widget text and canvas text are different paths in GTK4. Canvas can be controlled through `PangoLayout`; GTK widget internal text may ignore context language changes.
- Font enumeration filtering by coverage can be expensive and may change font dialog behavior.

## Acceptance Criteria

- GTK4 builds cleanly.
- Existing font properties continue to work: family, size, bold, italic, underline, strikeout, color.
- `lfCharSet` continues to roundtrip through GTK4 font objects.
- Non-default unambiguous charsets produce a Pango language hint on canvas font layouts.
- Metrics retrieval uses the same language hint as the layout.
- No Lazarus IDE core code is changed.

## Recommended First Patch

Start with the canvas font path only:

1. Add `Gtk4CharSetToPangoLanguage` helper.
2. Use it inside `TGtk4Font.Create(ALogFont, ALongFontName)`.
3. Merge language attribute with existing underline/strikeout attributes.
4. Verify build and a scratch drawing/metrics test.

Only after this passes should `SetLclFont` widget context behavior and `EnumFontFamiliesEx` be changed.

## Implementation Status

Updated on 2026-07-08.

Completed first patch:

- Added `Gtk4CharSetToPangoLanguage` in `lcl/interfaces/gtk4/gtk4procs.pas`.
- Mapped only unambiguous LCL charset values to Pango language tags:
  - `RUSSIAN_CHARSET` -> `ru`
  - `GREEK_CHARSET` -> `el`
  - `HEBREW_CHARSET` -> `he`
  - `ARABIC_CHARSET` -> `ar`
  - `THAI_CHARSET` -> `th`
  - `SHIFTJIS_CHARSET` -> `ja`
  - `HANGEUL_CHARSET` -> `ko`
  - `GB2312_CHARSET` -> `zh-cn`
  - `CHINESEBIG5_CHARSET` -> `zh-tw`
  - `TURKISH_CHARSET` -> `tr`
  - `VIETNAMESE_CHARSET` -> `vi`
- Kept `DEFAULT_CHARSET`, `ANSI_CHARSET`, `BALTIC_CHARSET`, `EASTEUROPE_CHARSET`, and other ambiguous values as no-op mappings.
- Applied the charset-derived `PangoLanguage` in `TGtk4Font.Create(ALogFont, ALongFontName)` by setting the new font context language.
- Added a matching `PANGO_ATTR_LANGUAGE` attribute to the new canvas `PangoLayout`.
- Merged the language attribute with existing underline and strikeout attributes in a single `PangoAttrList`.
- Preserved existing `FLogFont.lfCharSet` roundtrip behavior.

Files changed for implementation:

- `lcl/interfaces/gtk4/gtk4procs.pas`
- `lcl/interfaces/gtk4/gtk4objects.pas`

Not changed in the first patch:

- `TGtk4Widget.SetLclFont` in `lcl/interfaces/gtk4/gtk4widgets.pas`.
- `Gtk4GetFontFamilies(... AWritingSystem ...)` / font enumeration filtering.
- Lazarus IDE core code.

Verification performed:

```text
git diff --check -- lcl/interfaces/gtk4/gtk4procs.pas lcl/interfaces/gtk4/gtk4objects.pas
make lcl LCL_PLATFORM=gtk4
make bigide LCL_PLATFORM=gtk4
make lcl LCL_PLATFORM=gtk2
```

All four checks completed successfully.

Behavior verification still required:

- Confirm with runtime inspection that the layout/context language is present for non-default unambiguous charsets.
- Confirm underline and strikeout rendering with non-default charset language attributes.

Behavior verification added:

- Created `example_gtk4_setlclfonttest/gtk4_setlclfonttest.lpi`.
- The example creates visible `TLabel` controls with per-label `Font.CharSet` values and uses a `TPaintBox` canvas to draw the same samples.
- The example also runs an automated console check that logs:
  - requested `Font.CharSet`;
  - `GetObject(Canvas.Font.Handle, ...)` / `lfCharSet` roundtrip;
  - `GetTextMetrics` values;
  - `Canvas.TextWidth` values.
- The example supports `--stay-open` for manual visual inspection. Without that parameter it logs results and exits automatically.

Example build/run performed on 2026-07-08:

```text
./lazbuild --ws=gtk4 --lazarusdir=. example_gtk4_setlclfonttest/gtk4_setlclfonttest.lpi
xvfb-run -a ./example_gtk4_setlclfonttest/gtk4_setlclfonttest
```

Both commands completed successfully.

Observed automated output summary:

| Charset | Requested | `lfCharSet` roundtrip | Metrics height | TextWidth |
| --- | ---: | ---: | ---: | ---: |
| `DEFAULT_CHARSET` | 1 | 1 | 19 | 222 |
| `RUSSIAN_CHARSET` | 204 | 204 | 19 | 167 |
| `GREEK_CHARSET` | 161 | 161 | 19 | 190 |
| `SHIFTJIS_CHARSET` | 128 | 128 | 24 | 179 |
| `HANGEUL_CHARSET` | 129 | 129 | 24 | 179 |
| `GB2312_CHARSET` | 134 | 134 | 24 | 252 |
| `CHINESEBIG5_CHARSET` | 136 | 136 | 24 | 288 |

The automated result confirms `lfCharSet` roundtrip for the tested values and shows distinct Pango metrics for CJK charset/sample combinations. It does not, by itself, prove that GTK-managed widget text honors `SetLclFont` charset language hints, because the first implementation patch intentionally changed only the LCL canvas font path.

## Next Work

1. Add runtime instrumentation or GTK/Pango inspection to prove whether the canvas layout context has the expected language for non-default unambiguous charsets.
2. Run the example with `--stay-open` on a real display for visual inspection of widget labels and canvas drawing.
3. Separately investigate whether GTK4 widget text can reliably honor `AFont.CharSet` through widget Pango contexts.
4. Treat font enumeration filtering as a separate change after coverage and performance behavior are measured.
