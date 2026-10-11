"""namefit.py [VAR...]: choose link names for the c_common communals so MS LINK's hash order reproduces the original layout.
Keeps the longest possible set of plain names (asm-referenced ones forced), gives the rest NAME_xx link names.
Prints '#define C_NAME LINK_NAME' lines. VARs (address order) default to AVATAR.EXE's c_common."""
import itertools, string, sys, os
sys.path.insert(0, os.path.dirname(__file__))
from comdef import lhash
# address order of the original c_common (from the old U4_VAR.ASM)
VARS = '''D_9140 D_9141 D_9142 Party D_933A D_943A tile_forward D_943E D_9440 ship_x ship_y tile_cur D_9445 D_9446
D_9448 D_944A D_9452 pShapes D_9458 CurMode D_946C spell_cnt Combat Fighters File_DNG activeChara D_959C tile_east
pCharset spell_sta D_95A5 txt_X tile_north activeCharaY hit_tile hit_x hit_y D_95B2 tile_west tile_south txt_Y D_95C6
D_95C8 tile_back D_95CC D_95CE D_96EE File_MAP WindDir D_96F4 File_TLK D_96F8 D_96F9 D_9772'''.split()
if len(sys.argv) > 1: VARS = sys.argv[1:]
FORCED = {'D_943A', 'pShapes', 'pCharset', 'txt_X', 'txt_Y', 'Party'}  # referenced by name from .ASM modules
h = [lhash(v.upper()) for v in VARS]; n = len(VARS)
# DP over kept items: best[i] = (score, prev) with item i kept; virtual sentinels at -1 (hash -1) and n (hash 256)
H = [-1] + h + [256]; W = [0] + [3 if v in FORCED else 1 for v in VARS] + [0]
best = [None] * (n + 2); best[0] = (0, None)
for j in range(1, n + 2):
    for i in range(j):
        if best[i] is None: continue
        if H[j] - H[i] - 1 >= j - i - 1:   # room for the renamed items between
            s = best[i][0] + W[j]
            if best[j] is None or s > best[j][0]: best[j] = (s, i)
keep = []; j = n + 1
while j is not None: keep.append(j); j = best[j][1]
keep = sorted(keep)
kept = [VARS[k - 1] for k in keep[1:-1]]
alpha = string.ascii_uppercase + string.digits
def name_with(base, want):
    for k in (1, 2, 3):
        for suf in itertools.product(alpha, repeat=k):
            nm = base.upper() + '_' + ''.join(suf)
            if lhash(nm) == want: return nm
names = {}
for a, b in zip(keep, keep[1:]):
    mids = list(range(a + 1, b))
    lo, hi = H[a], H[b]
    for t, m in enumerate(mids):  # spread evenly in (lo, hi)
        want = lo + (t + 1) * (hi - lo) // (len(mids) + 1)
        names[VARS[m - 1]] = name_with(VARS[m - 1], want)
seq = [names.get(v, v.upper()) for v in VARS]
hs = [lhash(x) for x in seq]
assert hs == sorted(hs) and len(set(hs)) == len(hs), hs
print('/* kept %d of %d plain names */' % (n - len(names), n))
for v in VARS:
    if v in names: print('#define %-14s %s' % (v, names[v]))
