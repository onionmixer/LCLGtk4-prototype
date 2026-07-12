# LCLGtk4-prototype

A **GTK4 widgetset for the Lazarus Component Library (LCL)** — a working,
substantially complete prototype.

This repository contains the delta files to be applied on top of a
**Lazarus 4.4** source tree: the GTK4 widgetset itself (with its own
GTK4/GDK4/GLib Pascal bindings), the LCL core changes and build registration
it needs, GTK4 support units for bundled components, and the implementation
audit / validation documents and example projects produced during development.

## Status

**Prototype — largely functional.** The full Lazarus IDE (`make bigide
LCL_PLATFORM=gtk4`) builds and runs on GTK4: the form designer, source editor
(SynEdit), component palette, menus, popup menus, tooltips, common dialogs
(file/color/font via native choosers), drag & drop, tray icon (StatusNotifier),
and the standard/common controls have all been implemented and validated
per-widget (see `lazarus/LCL_WIDGETSET_IMPLEMENTATION_AUDIT.md` and the
`lazarus/PLAN_GTK4_*_VALIDATION.md` documents, each backed by an
`lazarus/example_gtk4_*` runtime validation project).

Text input received particular attention: typed-character key events
(`OnKeyPress`/`OnUTF8KeyPress`/form `KeyPreview`) are delivered following the
Qt5 widgetset's model, and CJK input-method handling was verified with real
Korean (Hangul) composition — including a local repair for an IM commit-ordering
quirk of the fcitx5 GTK4 frontend that transposed a trailing space with the
final committed syllable.

## Environment

Developed and tested on:

| Component | Version |
| --- | --- |
| OS | **Ubuntu 22.04** (x86_64) |
| GTK | **4.6.9** (the Ubuntu 22.04 system GTK4) |
| Lazarus | 4.4 source tree |
| FPC | 3.2.2 |
| Display server | **X11** (GNOME session) |
| Input method | fcitx5 + fcitx5-frontend-gtk4 (Korean/Hangul verified) |

Newer GTK4 releases are expected to work but have not been the primary target;
a few workarounds in the widgetset are keyed to GTK 4.6-era behavior.

## Known limitations

- **Wayland is untested / incomplete.** Development and validation were done
  on X11 only. In particular, popup placement (code-completion windows, hint
  windows) relies on X11 `override_redirect`; on Wayland it falls back to
  `transient_for`, which may position popups incorrectly. A proper
  Wayland-native popup backend has not been designed yet.
- A small number of items are inherent GTK4 backend limits (documented in the
  audit), e.g. `TFontDialog.fdApplyButton` (GtkFontChooserDialog has no apply
  button) and font underline/strikeout round-trips (not part of
  `PangoFontDescription`).

## Layout

```
lazarus/lcl/interfaces/gtk4/    the widgetset + Pascal bindings (gtk4bindings/)
lazarus/lcl/                    LCL core deltas and widgetset build
                                registration (Makefile, fpmake.pp, lcl.lpk)
lazarus/components/             GTK4 support units: SynEdit (incl. CJK IME),
                                VirtualTreeView, lclextensions, printers, ideintf
lazarus/*.md                    implementation audit + per-widget validation docs
lazarus/example_gtk4_*/         runtime validation example projects
HANDOFF_NEXT_SESSION.md         development handoff notes
```

## Building

1. Obtain a Lazarus 4.4 source tree.
2. Copy the contents of `lazarus/` in this repository over it, preserving paths.
3. Build:

```sh
make bigide LCL_PLATFORM=gtk4     # full IDE (binary: ./lazarus)
make lcl    LCL_PLATFORM=gtk4     # LCL only
```

Applications are then built with `--ws=gtk4` / `LCL_PLATFORM=gtk4` as usual.

## License

The widgetset and the modified files are derived from the Lazarus Component
Library and follow its license: **modified LGPL** (LGPL with the linking
exception), as published in the Lazarus source tree (`COPYING.modifiedLGPL.txt`).
