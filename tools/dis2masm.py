"""dis2masm.py BIN REGIONS OUT.ASM [BADLIST]: turn a small flat binary into MASM 3.00 source using ndisasm.
REGIONS: comma list of start-end:kind (hex, end exclusive, kind c=code d=data). Branch targets and direct
memory references become labels L_xxxx. Offsets listed in BADLIST (file of hex offsets, one per line) are emitted
as db with the instruction as a comment (for encodings MASM picks differently)."""
import re, subprocess, sys, tempfile
b = open(sys.argv[1], 'rb').read()
regions = []
for r in sys.argv[2].split(','):
    se, k = r.split(':'); s, e = (int(x, 16) for x in se.split('-')); regions.append((s, e, k))
bad = set()
if len(sys.argv) > 4:
    bad = {int(x, 16) for x in open(sys.argv[4]).read().split()}
ins = []  # (off, len, text)
for s, e, k in regions:
    if k != 'c': continue
    t = tempfile.mktemp(); open(t, 'wb').write(b[s:e])
    out = subprocess.run(['ndisasm', '-b16', '-o', str(s), t], capture_output=True, text=True).stdout
    for l in out.splitlines():
        a, hx, txt = l.split(None, 2); ins.append((int(a, 16), len(hx) // 2, txt))
labels = {}
def lab(v, kind):
    labels.setdefault(v, kind); return 'L_%04X' % v
def hexn(v): return ('0%XH' % v) if v > 9 else str(v)
def conv(off, n, t):
    m = re.match(r'(j\w+|loop|call) (0x[0-9a-f]+)$', t)
    if m:
        op, tgt = m.group(1), int(m.group(2), 16); L = lab(tgt, 'near')
        if op == 'jmp':
            return ('jmp short ' if n == 2 else 'jmp ') + L
        return '%s %s' % (op, L)
    t = t.replace('int byte', 'int')
    # memory operands
    def mem(mo):
        seg, body = mo.group(1), mo.group(2)
        sz = ''
        pre = (seg + ':') if seg else ''
        if re.fullmatch(r'0x[0-9a-f]+', body):
            v = int(body, 16)
            if seg == 'es': return 'es:[%s]' % hexn(v)
            return pre + lab(v, 'data')
        body = re.sub(r'0x[0-9a-f]+', lambda x: hexn(int(x.group(0), 16)), body)
        return pre + '[' + body + ']'
    t = re.sub(r'\[(?:(cs|es|ds|ss):)?([^\]]+)\]', mem, t)
    t = re.sub(r'\b0x([0-9a-f]+)\b', lambda x: hexn(int(x.group(1), 16)), t)
    if not t.startswith('lea') and re.search(r'\b[a-d]x|[sd]i|bp|sp\b', t) and re.search(r'L_[0-9A-F]{4}', t):
        t = re.sub(r'((?:cs:)?L_[0-9A-F]{4})', r'word ptr \1', t)
    return t
lines = []
code = {o: (n, conv(o, n, t), t) for o, n, t in ins}
# word/byte typing for data labels: decide from the instruction using them
out = ['WRAP\tSEGMENT', '\tASSUME CS:WRAP, DS:WRAP, ES:WRAP', '']
pos = 0
allstarts = sorted(set([s for s, e, k in regions]))
def emit_data(s, e):
    i = s
    while i < e:
        if i in labels or i == s or (i - s) % 16 == 0 or (i + 1) in labels:
            pass
        j = i + 1
        while j < e and j not in labels and (j - i) < 16: j += 1
        # zero runs
        chunk = b[i:j]
        lbl = ('L_%04X' % i) if i in labels else ''
        if len(set(chunk)) == 1 and len(chunk) > 3:
            out.append('%s\tdb\t%d dup(%s)' % (lbl, len(chunk), hexn(chunk[0])))
        else:
            out.append('%s\tdb\t%s' % (lbl, ','.join(hexn(c) for c in chunk)))
        i = j
for s, e, k in regions:
    if k == 'd': emit_data(s, e); continue
    o = s
    while o < e:
        n, txt, raw = code[o]
        lbl = ('L_%04X:' % o) if o in labels else ''
        if o in bad or raw == 'retf':  # MASM 3.00 has no RETF mnemonic
            out.append('%s\tdb\t%s\t; %s' % (lbl, ','.join(hexn(c) for c in b[o:o + n]), raw))
        else:
            out.append('%s\t%s' % (lbl, txt))
        o += n
# labels inside data that point mid-region are handled by emit_data; labels that point inside an instruction:
starts = set(code) | {i for s, e, k in regions if k == 'd' for i in range(s, e)}
missing = [v for v in labels if v not in starts]
out += ['', 'WRAP\tENDS', '\tEND']
src = '\r\n'.join(out) + '\r\n'
for v in missing:  # target inside an instruction or outside: define as EQU offset
    src = src.replace('WRAP\tSEGMENT\r\n', 'WRAP\tSEGMENT\r\nL_%04X\tEQU\tTHIS BYTE + %s\r\n' % (v, hexn(v)), 1) if False else src
if missing: print('labels not on instruction boundary:', [hex(v) for v in missing], file=sys.stderr)
open(sys.argv[3], 'w', newline='').write(src)
