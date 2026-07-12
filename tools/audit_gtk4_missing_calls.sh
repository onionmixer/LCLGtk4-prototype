#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

GTK_LIB="$(ldconfig -p | awk '/libgtk-4\.so(\.|$)/{print $NF; exit}')"
if [[ -z "${GTK_LIB}" ]]; then
  GTK_LIB="$(pkg-config --variable=libdir gtk4 2>/dev/null)/libgtk-4.so"
fi

if [[ -z "${GTK_LIB}" || ! -r "${GTK_LIB}" ]]; then
  echo "ERROR: could not locate readable libgtk-4 shared library" >&2
  exit 2
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

DECL_FILE="$TMP_DIR/declared.txt"
EXPORTED_FILE="$TMP_DIR/exported.txt"

nm -D --defined-only "$GTK_LIB" | awk '{print $3}' | sort -u > "$EXPORTED_FILE"

audit_unit() {
  local unit_path="$1"
  local lib_const="$2"
  local call_ns="$3"
  local sym_prefix="$4"
  local label="$5"

  local missing_decl_file="$TMP_DIR/missing_decl_${label}.txt"
  local called_file="$TMP_DIR/called_${label}.txt"
  local missing_called_file="$TMP_DIR/missing_called_${label}.txt"

  rg "external ${lib_const} name '" "$unit_path" \
    | sed -E "s/.*name '([^']+)'.*/\1/" \
    | sort -u > "$DECL_FILE"

  comm -23 "$DECL_FILE" "$EXPORTED_FILE" > "$missing_decl_file"

  rg -n "${call_ns}\\.(${sym_prefix}[a-zA-Z0-9_]+)\\(" "$unit_path" \
    | sed -E "s#^([0-9]+):.*${call_ns}\\.(${sym_prefix}[a-zA-Z0-9_]+)\\(.*#\\1 \\2#" > "$called_file"

  awk 'NR==FNR{m[$1]=1;next} m[$2]{print $0}' "$missing_decl_file" "$called_file" > "$missing_called_file"

  local miss_decl_count miss_called_count
  miss_decl_count="$(wc -l < "$missing_decl_file")"
  miss_called_count="$(wc -l < "$missing_called_file")"

  echo "${label}_declared_symbols_missing_in_libgtk4: ${miss_decl_count}"
  echo "${label}_runtime_calls_to_missing_symbols: ${miss_called_count}"

  if [[ "$miss_called_count" -gt 0 ]]; then
    echo
    echo "Calls to symbols not exported by libgtk4 in ${label}:"
    sed -n '1,120p' "$missing_called_file"
    return 10
  fi

  if [[ "$miss_decl_count" -gt 0 ]]; then
    echo
    echo "Declared-but-missing symbols remain in ${label} (showing up to 120):"
    sed -n '1,120p' "$missing_decl_file"
    return 11
  fi

  return 0
}

echo "libgtk4: $GTK_LIB"

audit_unit \
  "lazarus/lcl/interfaces/gtk4/gtk4bindings/lazgtk4.pas" \
  "LazGtk4_library" \
  "LazGtk4" \
  "gtk_" \
  "lazgtk4"

audit_unit \
  "lazarus/lcl/interfaces/gtk4/gtk4bindings/lazgdk4.pas" \
  "LazGdk4_library" \
  "LazGdk4" \
  "gdk_" \
  "lazgdk4"

exit 0
