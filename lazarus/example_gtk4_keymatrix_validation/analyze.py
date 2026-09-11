#!/usr/bin/env python3
"""Summarize keymatrix logs.
  analyze.py [--iso] [--json out.json] [--expect expect.json] [--dir DIR] [control...]
Per (ws, control, key) -> compact event signature; prints gtk4 | qt5 | gtk2 table (!! gtk4!=qt5, ~ qt5!=gtk2).
--json writes {ws: {control: {key: [tokens]}}} plus run status; --expect compares gtk4 against an expectation file
of the same shape (only keys present in the expectation are checked) and exits 1 on mismatch."""
import re, sys, os, json, argparse
S = os.path.dirname(os.path.abspath(__file__))
KEYS = "Return KP_Enter Escape Up Down Left Right Home End Prior Next Delete BackSpace Insert F3 space a ctrl+a Tab shift+Tab".split()
CTLS = "edit spin fspin comboedit combolist memo listbox checklist listview treeview button checkbox radio trackbar grid".split()
ABBR = {'KEYDOWN':'KD','KEYUP':'KU','KEYPRESS':'KP','UTF8KEY':'U8','FORMKD':'fKD','FORMKU':'fKU','EDITINGDONE':'ED','DEFAULTBTN':'DEF','CANCELBTN':'CAN','EFFECT':'E','REFOCUS':'RF'}
def load(d, ws, ctl, suffix):
    lp = f"{d}/{ws}_{ctl}{suffix}.log"; kp = lp + ".keys"
    if not os.path.exists(lp): return None
    ev = []; ready = None; final = None; crash = False; exit_normal = False; procexit = None
    for line in open(lp, errors='replace'):
        if line.startswith('PROCEXIT'): procexit = int(line.split()[1]); continue
        m = re.match(r'\s*(\d+) (\S+)\s+(.*)', line)
        if not m:
            if 'Segmentation' in line or '세그멘테이션' in line or 'Access violation' in line or 'Runtime error' in line: crash = True
            continue
        t, kind, rest = int(m.group(1)), m.group(2), m.group(3)
        if kind == 'READY': ready = t; continue
        if kind == 'FINAL': final = rest; continue
        if kind == 'EXIT': exit_normal = True; continue
        ev.append((t, kind, rest))
    keys = []
    if os.path.exists(kp):
        for line in open(kp):
            m = re.match(r'(\d+) --- key (\S+)', line)
            if m: keys.append((int(m.group(1)), m.group(2)))
    ok = (final is not None) and exit_normal and (procexit == 0) and not crash
    return dict(ready=ready, final=final, crash=crash, exit_normal=exit_normal, procexit=procexit, ok=ok, ev=ev, keys=keys)
def sig(d):
    if not d or d['ready'] is None: return {}
    off = d['ready'] + 1240
    out = {k: [] for _, k in d['keys']}
    bounds = [(t + off, k) for t, k in d['keys']]
    for t, kind, rest in d['ev']:
        owner = None
        for bt, k in bounds:
            if t >= bt - 60: owner = k
        if owner is None or kind == 'REFOCUS': continue
        tok = ABBR.get(kind, kind)
        parts = rest.split()
        if kind in ('KEYDOWN','KEYUP','KEYPRESS','UTF8KEY'):
            who = parts[0]; val = parts[1] if len(parts) > 1 else ''
            tok = f"{tok}:{who}:{val.split('=')[-1]}"
            if kind == 'KEYDOWN' and 'shift=[' in rest and 'shift=[]' not in rest: tok += rest[rest.index('shift='):].replace('shift=','')
        elif kind in ('FORMKD','FORMKU'): tok = f"{tok}:{rest.split('=')[-1]}"
        elif kind == 'EFFECT': tok = f"E:{parts[0]}"
        elif kind == 'EDITINGDONE': tok = f"ED:{rest}"
        out[owner].append(tok)
    return out
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--iso', action='store_true'); ap.add_argument('--json'); ap.add_argument('--expect'); ap.add_argument('--dir', default=f"{S}/out"); ap.add_argument('--quiet', action='store_true'); ap.add_argument('controls', nargs='*')
    a = ap.parse_args(); suffix = '_iso' if a.iso else ''
    ctls = a.controls or CTLS; allsig = {}; status = {}; bad = 0
    for ctl in ctls:
        data = {ws: load(a.dir, ws, ctl, suffix) for ws in ('gtk4','qt5','gtk2')}
        sigs = {ws: sig(d) for ws, d in data.items()}
        for ws in sigs: allsig.setdefault(ws, {})[ctl] = sigs[ws]; status.setdefault(ws, {})[ctl] = (data[ws] or {}).get('ok')
        if not a.quiet:
            print(f"\n===== {ctl}{' [iso]' if a.iso else ''}  run ok: " + ", ".join(f"{ws}={'YES' if d and d['ok'] else ('NO' if d else 'n/a')}" for ws, d in data.items()))
            for ws, d in data.items():
                if d and d['final']: print(f"  final[{ws}]: {d['final']}")
            print(f"  {'key':9} | {'gtk4':45} | {'qt5':45} | gtk2")
            for k in KEYS:
                row = [" ".join(sigs[ws].get(k, [])) or "·" for ws in ('gtk4','qt5','gtk2')]
                mark = "  " if row[0] == row[1] == row[2] else ("!!" if row[0] != row[1] else "~ ")
                print(f"{mark}{k:9} | {row[0]:45} | {row[1]:45} | {row[2]}")
    if a.json:
        json.dump({'signatures': allsig, 'run_ok': status}, open(a.json, 'w'), indent=1, ensure_ascii=False)
    if a.expect:
        exp = json.load(open(a.expect))
        for ctl, keys in exp.items():
            for k, want in keys.items():
                got = allsig.get('gtk4', {}).get(ctl, {}).get(k, [])
                if got != want:
                    bad += 1; print(f"EXPECT MISMATCH {ctl}/{k}: want {want} got {got}")
        print(f"expectation check: {'OK' if bad == 0 else str(bad) + ' mismatches'}")
    sys.exit(1 if bad else 0)
main()
