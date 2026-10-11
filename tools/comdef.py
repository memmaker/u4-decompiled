"""comdef.py OBJDIR RSP [MAP]: predict MS LINK 3.x c_common layout from COMDEFs (see ~/notes/how-to-decompile.md:
hash = len + sum((c|0x20) << (i&3)) over the name, i=1..len; bucket = hash & 0xff; buckets 0..255, each newest-first;
symbols are created on first sight (any EXTDEF/COMDEF/PUBDEF) in link order; even sizes word-aligned).
With MAP, compares against the linker's map."""
import os, re, struct, sys
sys.path.insert(0, os.path.dirname(__file__))
from omf import records, idx

def lhash(name):
    b = name.encode('latin1')
    return (len(b) + sum((c | 0x20) << (i & 3) for i, c in enumerate(b, 1))) & 0xff

def scan(path):
    """yield (kind, name, size) in record order"""
    for t, d in records(open(path, 'rb').read()):
        if t in (0x8c, 0xb4, 0xb0, 0x90):
            p = 0
            if t == 0x90:
                gi, p = idx(d, p); si, p = idx(d, p)
                if si == 0: p += 2
            while p < len(d):
                n = d[p]; name = d[p + 1:p + 1 + n].decode('latin1'); p += 1 + n
                if t == 0x90: p += 2; _, p = idx(d, p); yield 'pub', name, 0; continue
                _, p = idx(d, p)
                if t != 0xb0: yield 'ext', name, 0; continue
                dt = d[p]; p += 1
                def clen(p):
                    b = d[p]
                    if b < 0x80: return b, p + 1
                    k = {0x81: 2, 0x84: 3, 0x88: 4}[b]
                    return int.from_bytes(d[p + 1:p + 1 + k], 'little'), p + 1 + k
                sz, p = clen(p)
                if dt == 0x61: el, p = clen(p); sz *= el
                yield 'com', name, sz

def layout(objs):
    seen = []; size = {}; pub = set()
    for o in objs:
        for k, n, s in scan(o):
            if n not in seen: seen.append(n)
            if k == 'com': size[n] = max(size.get(n, 0), s)
            if k == 'pub': pub.add(n)
    coms = [n for n in seen if n in size and n not in pub]
    order = sorted(coms, key=lambda n: (lhash(n), -seen.index(n)))
    off = 0; out = []
    for n in order:
        if size[n] % 2 == 0: off = (off + 1) & ~1
        out.append((off, n, size[n])); off += size[n]
    return out, off

if __name__ == '__main__':
    d, rsp = sys.argv[1], sys.argv[2]
    mods = [m.strip().rstrip('+') for m in open(rsp).read().replace('\r', '').split('\n')]
    mods = [m for m in mods if m and ';' not in m][:-0 or None]
    objs = [os.path.join(d, m.upper() + '.OBJ') for m in mods if os.path.exists(os.path.join(d, m.upper() + '.OBJ'))]
    out, total = layout(objs)
    mp = {}
    if len(sys.argv) > 3:
        for l in open(sys.argv[3]).read().replace('\r', '').split('\n'):
            m = re.match(r'\s*[0-9A-F]{4}:([0-9A-F]{4})\s+(\S+)$', l)
            if m: mp[m.group(2)] = int(m.group(1), 16)
    base = None; bad = 0
    for off, n, s in out:
        a = mp.get(n.upper())
        if base is None and a is not None: base = a - off
        ok = '' if a is None else ('ok' if a - base == off else 'MAP %04x' % (a - base)); bad += ok.startswith('MAP')
        print('%04x %-20s %4x h=%02x %s' % (off, n, s, lhash(n), ok))
    print('total %x, mismatches %d' % (total, bad))
