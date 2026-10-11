"""exediff.py A.EXE B.EXE: compare load images, relocation sets and key header fields of two MZ files."""
import struct, sys
def load(p):
    d = open(p, 'rb').read()
    h = struct.unpack_from('<14H', d)
    size = (h[2] - (h[1] != 0)) * 512 + h[1]
    img = d[h[4] * 16:size]
    rel = [struct.unpack_from('<HH', d, h[12] + 4 * i) for i in range(h[3])]
    return h, img, rel
ha, a, ra = load(sys.argv[1]); hb, b, rb = load(sys.argv[2])
names = 'magic cblp cp crlc cparhdr minalloc maxalloc ss sp csum ip cs lfarlc ovno'.split()
for n, x, y in zip(names, ha, hb):
    if x != y and n not in ('cblp', 'cp', 'cparhdr', 'lfarlc', 'csum'): print('hdr %-8s %04x %04x' % (n, x, y))
print('image sizes %x %x' % (len(a), len(b)))
print('relocs', len(ra), len(rb), 'order-equal' if ra == rb else ('set-equal' if sorted(ra) == sorted(rb) else 'DIFFERENT'))
n = min(len(a), len(b)); diffs = [i for i in range(n) if a[i] != b[i]]
print('differing bytes', len(diffs) + abs(len(a) - len(b)))
runs = []
for i in diffs:
    if runs and i - runs[-1][1] <= 8: runs[-1][1] = i
    else: runs.append([i, i])
for s, e in runs[:int(sys.argv[3]) if len(sys.argv) > 3 else 40]:
    print('%05x-%05x  %s | %s' % (s, e, a[s:e+1][:16].hex(), b[s:e+1][:16].hex()))
print(len(runs), 'runs')
