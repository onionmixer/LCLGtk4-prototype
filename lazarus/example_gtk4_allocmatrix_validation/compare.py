#!/usr/bin/env python3
"""compare.py <dirA> <dirB>: diff the normalized analyzer rows (no timestamps/pointers/rss) of two output dirs.
Prints rows that differ; exit 1 if any."""
import sys, subprocess, os
here = os.path.dirname(os.path.abspath(__file__))
def rows(d):
    out = subprocess.run([sys.executable, os.path.join(here, 'analyze.py'), d], capture_output=True, text=True).stdout
    return {l.split()[0] + ' ' + l.split()[1]: ' '.join(l.split()) for l in out.splitlines() if l and not l.startswith('SUMMARY') and not l.startswith('  ') and len(l.split()) > 2}   # whitespace-normalized
a, b = rows(sys.argv[1]), rows(sys.argv[2])
diff = 0
for k in sorted(set(a) | set(b)):
    if a.get(k) != b.get(k):
        diff += 1
        print('- ' + (a.get(k) or '(missing) ' + k)); print('+ ' + (b.get(k) or '(missing) ' + k))
print('%d differing rows' % diff); sys.exit(1 if diff else 0)
