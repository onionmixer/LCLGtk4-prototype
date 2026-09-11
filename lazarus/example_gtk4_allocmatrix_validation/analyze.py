#!/usr/bin/env python3
"""analyze.py [dir] [--strict] [--include=<regex on log name>]
For each log: every non-truth step is compared with the following truth step (central alloc differs -> STALE).
Additional checks (always reported, fatal with --strict):
  FILL   : central widget's parent is a GtkOverlay but central alloc != parent alloc (main child must fill the overlay)
  NOSNAP : no SNAP lines (crashed / display race)      INCOMPLETE : the SNAP step sequence differs from the mode's expected one
  ORIGIN : central widget of an overlay-parented class not at 0,0 (position is part of the FILL contract)
  STALE-X: notruth log whose central alloc differs from the t-<step> value of the matching truth log (<name>_truth.txt)
  NOSCROLL: a 'scroll' step of a scrolling class left the vertical adjustment at 0 (the step did not scroll)
notruth logs: STALE is never flagged (no repair happens), but FILL/NOSCROLL still are.
Exit status 1 with --strict when any STALE/FILL/NOSNAP/INCOMPLETE/NOSCROLL exists."""
import re, sys, glob, os
from collections import Counter
args = [a for a in sys.argv[1:] if not a.startswith('--')]
strict = '--strict' in sys.argv
inc = [a.split('=',1)[1] for a in sys.argv[1:] if a.startswith('--include=')]
inc = re.compile(inc[0]) if inc else None
d = args[0] if args else os.path.join(os.path.dirname(os.path.abspath(__file__)), 'out')
rx = re.compile(r'SNAP (\S+)\s+cls=(\S+) widget=(\S+) alloc=\[([^\]]*)\] req=(\S+)(?: central=(\S+)(?: alloc=\[([^\]]*)\] req=(\S+) parent=(\S+) alloc=\[([^\]]*)\])?)?(?: hadj=(\S+) vadj=(\S+))? lcl=(\S+) client=(\S+)')
def wh(a):
    m = re.match(r'(-?\d+),(-?\d+) (\d+)x(\d+)', a or '')
    return (int(m.group(3)), int(m.group(4))) if m else None
def xy(a):
    m = re.match(r'(-?\d+),(-?\d+) ', a or '')
    return (int(m.group(1)), int(m.group(2))) if m else None
BASE = ['show', 'scroll', 'shrink', 'same', 'grow', 'wider', 'scroll2']
EXTRA = {'rehide': ['hid', 'hid-shr', 'reshown', 'regrow'], 'inactivepage': ['inact-shr', 'activated', 'act-grow'], 'zero': ['zero', 'unzero']}
NOTRUTH_STEPS = {'hid', 'hid-shr', 'inact-shr', 'mid', 'mid-shr', 'mid-grow'}
def expected(name):
    mode = name.split('_')[-1]
    if mode == 'growmid': steps = ['show', 'mid', 'mid-shr', 'mid-grow']   # the mode ends after the grow
    elif mode == 'gtkscroll': steps = BASE
    else: steps = [BASE[0]] + EXTRA.get(mode, []) + BASE[1:]
    out = []
    for t in steps:
        out.append(t)
        if t not in NOTRUTH_STEPS: out.append('t-' + t)   # notruth logs still print t-* (without the repair)
    return out
def truth_map(f):
    """t-<step> -> central alloc of the matching *_truth.txt log (for notruth logs)"""
    g = f.replace('_notruth.txt', '_truth.txt').replace('_notruth_gl.txt', '_truth.txt')
    if g == f or not os.path.exists(g): return {}
    m = {}
    for line in open(g, encoding='utf-8', errors='replace'):
        r = rx.search(line)
        if r and r.group(1).startswith('t-'): m[r.group(1)[2:]] = r.group(7)
    return m
rows, problems = [], Counter()
for f in sorted(glob.glob(os.path.join(d, '*.txt'))):
    name = os.path.basename(f)[:-4]
    if inc and not inc.search(name): continue
    snaps = []
    for line in open(f, encoding='utf-8', errors='replace'):
        m = rx.search(line)
        if m: snaps.append(m.groups())
    if not snaps:
        rows.append((name, '-', 'NOSNAP', '', '')); problems[name] += 1; continue
    steps = [s[0] for s in snaps]
    notruth = name.endswith('_notruth') or name.endswith('_notruth_gl')
    tmap = truth_map(f) if notruth else {}
    for i, s in enumerate(snaps):
        tag, cls, wt, walloc, wreq, ct, calloc, creq, pt, palloc, hadj, vadj, lcl, client = s
        if tag.startswith('t-'): continue
        truth = snaps[i+1] if i+1 < len(snaps) and snaps[i+1][0] == 't-' + tag else None
        c = wh(calloc); t = wh(truth[6]) if truth else None
        flags = []
        if ct == 'SAME' or ct is None: verdict = 'n/a'
        elif notruth: verdict = 'notruth'
        elif truth is None and tag in NOTRUTH_STEPS: verdict = 'info'   # deliberately no truth step (hidden / inactive page / growmid)
        elif truth is None: verdict = 'NOTRUTH-MISSING'; flags.append('INCOMPLETE')
        elif c != t: verdict = 'STALE'
        else: verdict = 'ok'
        if pt == 'GtkOverlay' and c and wh(palloc) and c != wh(palloc): flags.append('FILL')
        if pt == 'GtkOverlay' and c and xy(calloc) != (0, 0): flags.append('ORIGIN')
        if notruth and tag in tmap and c and wh(tmap[tag]) and c != wh(tmap[tag]): flags.append('STALE-X')
        if tag.startswith('scroll') and vadj and vadj != 'nil' and vadj.split('/')[0] == '0' and vadj.split('/')[1] != vadj.split('/')[2]:
            flags.append('NOSCROLL')
        if verdict == 'STALE' or flags: problems[name] += 1
        rows.append((name, tag, verdict, ' '.join(flags), 'central=%s truth=%s req=%s parent=%s vadj=%s client=%s widget=%s wreq=%s hadj=%s lcl=%s' % (calloc, truth[6] if truth else '-', creq, palloc, vadj, client, walloc, wreq, hadj, lcl)))
    exp = expected(name)
    if steps != exp: rows.append((name, '-', 'INCOMPLETE', '', 'steps %s != expected %s' % (steps, exp))); problems[name] += 1
w = max(len(r[0]) for r in rows)
for r in rows:
    print('%-*s %-9s %-8s %-14s %s' % (w, r[0], r[1], r[2], r[3], r[4]))
print('\nSUMMARY (problem steps per log: STALE/FILL/NOSCROLL/NOSNAP/INCOMPLETE):')
names = sorted(set(r[0] for r in rows))
for n in names: print('  %-*s %s' % (w, n, problems.get(n, 0)))
if strict and sum(problems.values()): sys.exit(1)
