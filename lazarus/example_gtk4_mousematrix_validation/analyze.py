#!/usr/bin/env python3
"""analyze.py [--dir=out] [--gate] [control...] -> per (control, region) one line per widgetset:
   --gate: exit 1 when a gated row fails: scrollbar rows (vthumb/vtrough/hthumb/multibtn where the widgetset has the bar)
           must deliver no press/release/click and no button-held motion to target/form/child on gtk4 (at most one button-free
           hover motion per receiver, gate v6; the listview header row likewise, v7); incomplete logs (no DONE) fail; client-row press coordinates of
           gtk4 must be within 12 px of qt5's and scroll-container Move y must stay inside the client height.
   target: D=<n>(x,y) M=<n>[xmin..xmax,ymin..ymax] U=<n>(x,y) C<clicks> | form: D M U | child: D M U | state deltas | drift delta
Flags: '!!' gtk4 target D/M/U counts differ from qt5; '~' qt5 != gtk2; 'nobar' the widgetset reports no scroll range on that axis
(so a scrollbar region there is really a client press and is not a baseline)."""
import re, sys, os, glob
from collections import OrderedDict
args=[a for a in sys.argv[1:] if not a.startswith('--')]
d=[a.split('=',1)[1] for a in sys.argv[1:] if a.startswith('--dir=')]
d=d[0] if d else os.path.join(os.path.dirname(os.path.abspath(__file__)),'out')
rxev=re.compile(r'^\s*\d+ EV (\S+) (Down|Move|Up|Click|DblClick)(?: btn=(\d+))?(?: x=(-?\d+) y=(-?\d+))?')
rxheld=re.compile(r' btn=(True|False)\s*$')   # Move lines: ssLeft in Shift (button 1 held)
rxreg=re.compile(r'^\s*\d+ --- region (\S+) at local (-?\d+),(-?\d+)')
rxst=re.compile(r'^\s*\d+ STATE (\S+) (.*)$')
CONTROLS=['custom','scrollbox','memo','listbox','listview','treeview','treeviewnohint','synedit','spin','combo','pagecontrol','groupbox','trackbar','panel','button','edit','formscroll','formmenu']
SCROLLERS=['custom','scrollbox','memo','listbox','listview','treeviewnohint','synedit']
GATE_SKIP={'treeview': 'H (tooltip window eats the press)', 'formscroll': 'J (gtk4 forms have no AutoScroll bars)'}
def who(name):
    if name.startswith('target:'): return 'target'
    if name.startswith(':TMain') or name == 'target:TMain': return 'form'
    return 'child'
def parse(f):
    regions=OrderedDict(); cur=None; states={}; done=False
    for line in open(f,encoding='utf-8',errors='replace'):
        m=rxreg.match(line)
        if m: cur=m.group(1); regions[cur]={w:{'D':[], 'M':[], 'U':[], 'C':0} for w in ('target','form','child')}; continue
        m=rxst.match(line)
        if m: states[m.group(1)]=dict(kv.split('=',1) for kv in m.group(2).split() if '=' in kv); continue
        if re.match(r'^\s*\d+ DONE', line): done=True
        if line.startswith('PROCEXIT'): states['__exit__']=line.split()[1] if len(line.split())>1 else '?'
        m=rxev.match(line)
        if m and cur:
            w=who(m.group(1)); k=m.group(2)
            if k in ('Click','DblClick'): regions[cur][w]['C']+=1
            elif k=='Move':
                h=rxheld.search(line); regions[cur][w]['M'].append((int(m.group(4)),int(m.group(5)),bool(h and h.group(1)=='True')))
            else: regions[cur][w][{'Down':'D','Up':'U'}[k]].append((int(m.group(4)),int(m.group(5))))
    states['__done__']=done
    return regions, states
def rng(pts):
    if not pts: return ''
    xs=[p[0] for p in pts]; ys=[p[1] for p in pts]
    return '[%d..%d,%d..%d]'%(min(xs),max(xs),min(ys),max(ys))
def summ(r):
    t=r['target']
    s='D=%d%s M=%d%s U=%d%s%s'%(len(t['D']), ('(%d,%d)'%t['D'][0]) if t['D'] else '', len(t['M']), rng(t['M']), len(t['U']), ('(%d,%d)'%t['U'][-1]) if t['U'] else '', ' C%d'%t['C'] if t['C'] else '')
    o=[]
    for w in ('form','child'):
        x=r[w]
        if x['D'] or x['M'] or x['U']: o.append('%s:D%dM%dU%d'%(w,len(x['D']),len(x['M']),len(x['U'])))
    return s+(' '+' '.join(o) if o else '')
def sig(r): t=r['target']; return (len(t['D']),len(t['M'])>0,len(t['U']))
def delta(states, reg, prevreg):
    a=states.get(prevreg,{}); b=states.get(reg,{}); out=[]
    for k in b:
        if k=='c2sdrift':
            if a.get(k)!=b.get(k): out.append('DRIFT-CHANGED:%s->%s'%(a.get(k),b.get(k)))
        elif a.get(k)!=b.get(k): out.append('%s:%s->%s'%(k,a.get(k),b.get(k)))
    return ' '.join(out)
def nobar(states, reg):
    st=states.get('start',{})
    axis='h' if reg=='hthumb' else ('v' if reg in ('vthumb','vtrough','multibtn') else None)
    if not axis: return False
    vis=st.get(axis+'bar')                 # GetScrollBarVisible (harness v4); authoritative when present
    if vis is not None: return vis=='False'
    v=st.get(axis+'range')
    if not v: return False                 # unknown: judge the row (conservative)
    mx,pg=v.split('/'); return int(mx)<=int(pg)
gate='--gate' in sys.argv; failures=[]
wss=['gtk4','qt5','gtk2']; data={}
if gate and not os.path.isdir(d): print('GATE: 1 failure(s)\n  output dir missing: '+d); sys.exit(1)
for ws in wss:
    for f in sorted(glob.glob(os.path.join(d,'%s_*.log'%ws))):
        ctl=os.path.basename(f)[len(ws)+1:-4]
        if ctl not in CONTROLS: continue          # diagnostic logs (e.g. *_gdb.log) are not part of the matrix
        if args and ctl not in args: continue
        data.setdefault(ctl,{})[ws]=parse(f)
if gate:
    want=[c for c in CONTROLS if (not args or c in args)]
    for c in want:
        for ws in wss:
            if ws=='gtk2' and c=='synedit': continue
            if c not in data or ws not in data[c]: failures.append('%s: %s log missing'%(c,ws)); continue
            st=data[c][ws][1]; regs_done=list(data[c][ws][0].keys())
            ok = st.get('__done__') and st.get('__exit__')=='0'
            if not ok and not (ws=='qt5' and regs_done and regs_done[-1]=='multibtn'):   # known qt5 stop after the button-3 press
                failures.append('%s: %s log incomplete (done=%s exit=%s)'%(c,ws,st.get('__done__'),st.get('__exit__')))
for ctl in sorted(data):
    regs=[]
    for ws in wss:
        if ws in data[ctl]:
            for r in data[ctl][ws][0]:
                if r not in regs: regs.append(r)
    print('== %s'%ctl); prev='start'
    for reg in regs:
        cells=[]; sigs={}
        for ws in wss:
            if ws not in data[ctl]: cells.append('%-5s (no run)'%ws); sigs[ws]=None; continue
            regions,states=data[ctl][ws]; r=regions.get(reg)
            if r is None: cells.append('%-5s (no region)'%ws); sigs[ws]=None; continue
            sigs[ws]=None if nobar(states,reg) else sig(r)
            cells.append('%-5s %-52s %s%s'%(ws, summ(r), 'nobar ' if nobar(states,reg) else '', delta(states, reg, prev)))
        flag=''
        if sigs.get('gtk4') is not None and sigs.get('qt5') is not None and sigs['gtk4']!=sigs['qt5']: flag+='!!'
        if sigs.get('qt5') is not None and sigs.get('gtk2') is not None and sigs['qt5']!=sigs['gtk2']: flag+='~'
        print('  %-11s %-3s %s'%(reg, flag, cells[0]))
        for c in cells[1:]: print('  %-11s %-3s %s'%('', '', c))
        if gate and 'gtk4' in data[ctl] and ctl not in GATE_SKIP:
            g=data[ctl]['gtk4']; r=g[0].get(reg); t=r['target'] if r else None
            stprev=g[1].get(prev,{}); stnow=g[1].get(reg,{})
            def changed(k): return stprev.get(k)!=stnow.get(k)
            if r is None: failures.append('%s/%s: gtk4 region missing'%(ctl,reg))
            elif reg in ('vthumb','vtrough','hthumb','multibtn'):
                if not nobar(g[1],reg) and ctl not in ('memo','listbox','checklist'):   # N: overlay scrollbars — GTK targets the text/list view unless the indicator is revealed; judged by hand (plan N, L)
                    fm=r['form']; ch=r['child']
                    # gate v6 (plan §12.5, row 41): no press/release/click and no button-held motion may reach any LCL control;
                    # at most one button-free motion per receiver is tolerated — GTK synthesizes a hover motion at the pointer
                    # (then over the client) after the grab ends, and hover is client input by the §7 input contract.
                    def held(x): return [p for p in x['M'] if p[2]]
                    def free(x): return [p for p in x['M'] if not p[2]]
                    bad=[w for w,x in (('target',t),('form',fm),('child',ch)) if x['D'] or x['U'] or x['C'] or held(x) or len(free(x))>1]
                    if bad:
                        failures.append('%s/%s: chrome events delivered (target D%dM%d/%dU%d form D%dM%d/%dU%d child D%dM%d/%dU%d; M=held/free)'%(ctl,reg,len(t['D']),len(held(t)),len(free(t)),len(t['U']),len(fm['D']),len(held(fm)),len(free(fm)),len(fm['U']),len(ch['D']),len(held(ch)),len(free(ch)),len(ch['U'])))
                    if changed('sellen') or stnow.get('sel')=='True': failures.append('%s/%s: selection changed by chrome drag'%(ctl,reg))
                    if changed('c2sdrift'): failures.append('%s/%s: ClientToScreen drift changed with scrolling'%(ctl,reg))
                    # scroll progress: any observable position (widgetset GetScrollPos is not reliable for every native class, plan M)
                    if reg!='multibtn' and not any(changed(k) for k in ('vpos','hpos','top','topline','itemindex','vsb','hsb')):
                        failures.append('%s/%s: scrollbar drag did not scroll'%(ctl,reg))
            elif reg=='header' and ctl=='listview':
                # gate v7 (plan §14.2, B): the GtkColumnView header row is chrome like a scrollbar - no press/release/click,
                # no button-held motion, at most one button-free motion per receiver; no scroll-progress requirement
                fm=r['form']; ch=r['child']
                def held(x): return [p for p in x['M'] if p[2]]
                def free(x): return [p for p in x['M'] if not p[2]]
                bad=[w for w,x in (('target',t),('form',fm),('child',ch)) if x['D'] or x['U'] or x['C'] or held(x) or len(free(x))>1]
                if bad: failures.append('%s/%s: header events delivered (target D%dM%d/%dU%d form D%dM%d/%dU%d; M=held/free)'%(ctl,reg,len(t['D']),len(held(t)),len(free(t)),len(t['U']),len(fm['D']),len(held(fm)),len(free(fm)),len(fm['U'])))
            elif reg in ('client','contentdrag'):
                deepest = r['child'] if ctl in ('scrollbox','pagecontrol') else t
                if len(deepest['D'])!=1 and ctl!='button': failures.append('%s/%s: press count %d (expected 1)'%(ctl,reg,len(deepest['D'])))   # P: runtime TButtonControl press is not delivered on gtk4 (gtk4widgets.pas TButtonControl exit); only the form-0 rule applies
                if not deepest['M']: failures.append('%s/%s: no motion delivered'%(ctl,reg))
                if len(deepest['U'])!=1 and not (ctl=='memo' and reg=='contentdrag') and ctl!='button': failures.append('%s/%s: release count %d (expected 1)'%(ctl,reg,len(deepest['U'])))   # I: memo
                if ctl in ('scrollbox','pagecontrol') and (t['D'] or t['U'] or t['M']): failures.append('%s/%s: ancestor got child events (F)'%(ctl,reg))
                # F: the form must not receive the child's buttons or button-held motion. One button-free motion is tolerated:
                # GTK synthesizes a motion from the queried pointer state before a pending release (plan §9 row 31/41) and, with the
                # pointer already outside the child, it is the form's own hover (v7, plan row 55).
                fmm=r['form']
                if fmm['D'] or fmm['U'] or [p for p in fmm['M'] if p[2]] or len([p for p in fmm['M'] if not p[2]])>1:
                    failures.append('%s/%s: form got events of a child (F)'%(ctl,reg))
                if reg=='client' and t['D']:
                    if not t['M']: failures.append('%s/client: no motion to compare with the press'%ctl)
                    elif abs(t['D'][0][0]-t['M'][0][0])>1 or abs(t['D'][0][1]-t['M'][0][1])>1:
                        failures.append('%s/client: press (%d,%d) != first motion (%d,%d) (press/motion offset mismatch)'%(ctl,t['D'][0][0],t['D'][0][1],t['M'][0][0],t['M'][0][1]))
                    if 'qt5' in data[ctl] and ctl not in ('listview',):   # B'': listview origin includes the header on gtk4
                        q=data[ctl]['qt5'][0].get(reg)
                        if q and q['target']['D']:
                            dx=abs(t['D'][0][0]-q['target']['D'][0][0]); dy=abs(t['D'][0][1]-q['target']['D'][0][1])
                            if dx>12 or dy>12: failures.append('%s/client: gtk4 press (%d,%d) vs qt5 (%d,%d)'%(ctl,t['D'][0][0],t['D'][0][1],q['target']['D'][0][0],q['target']['D'][0][1]))
                st=g[1].get('start',{})
                if 'vrange' in st and t['M']:
                    ch=int(st['vrange'].split('/')[1]) if '/' in st['vrange'] else 0
                    ys=[p[1] for p in t['M']]; xs=[p[0] for p in t['M']]
                    if ch and (max(ys)>ch+40 or min(ys)<-40): failures.append('%s/%s: Move y %d..%d outside client height %d'%(ctl,reg,min(ys),max(ys),ch))
                    cw=int(st['hrange'].split('/')[1]) if '/' in st.get('hrange','') else 0
                    if cw and (max(xs)>cw+140 or min(xs)<-40): failures.append('%s/%s: Move x %d..%d outside client width %d'%(ctl,reg,min(xs),max(xs),cw))   # contentdrag ends 60px outside
                if changed('c2sdrift'): failures.append('%s/%s: ClientToScreen drift changed'%(ctl,reg))
        prev=reg

if gate:
    print('\nGATE: %d failure(s)'%len(failures))
    for f in failures: print('  '+f)
    sys.exit(1 if failures else 0)
