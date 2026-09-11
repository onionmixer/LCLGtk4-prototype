#!/usr/bin/env python3
"""compare.py before.json after.json [ws] -> per control/key signature changes (python-only arithmetic)."""
import json, sys
a = json.load(open(sys.argv[1])); b = json.load(open(sys.argv[2])); ws = sys.argv[3] if len(sys.argv) > 3 else 'gtk4'
sa, sb = a['signatures'].get(ws, {}), b['signatures'].get(ws, {})
ra, rb = a['run_ok'].get(ws, {}), b['run_ok'].get(ws, {})
changed = 0; same = 0
for ctl in sorted(set(sa) | set(sb)):
    ka, kb = sa.get(ctl, {}), sb.get(ctl, {})
    for k in sorted(set(ka) | set(kb)):
        if ka.get(k, []) != kb.get(k, []):
            changed += 1
            print(f"CHANGED {ctl:10} {k:9} before: {' '.join(ka.get(k, [])) or '·'}\n{'':29} after:  {' '.join(kb.get(k, [])) or '·'}")
        else:
            same += 1
    if ra.get(ctl) != rb.get(ctl):
        print(f"RUN_OK  {ctl:10} before={ra.get(ctl)} after={rb.get(ctl)}")
print(f"summary [{ws}]: {same} unchanged, {changed} changed key rows")
