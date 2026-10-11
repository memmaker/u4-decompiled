"""wrap.py PACKED.EXE PROTECT.EXE OUT.EXE: append the copy-protection wrapper to the EXEPACKed game the way the
original protection tool did, giving the shipped AVATAR.EXE.
- the packed file is padded to a paragraph with bytes left over in the tool's buffer (' you have not')
- the wrapper image (PROTECT.ASM, linked) follows; its bytes 23h..1F0h are XOR-encrypted with 0BCh
  (12h..22h were encrypted too, but the crack stub that replaced them is plain)
- MZ header: CS:IP -> wrapper:0000, SS:SP -> wrapper+152h:0064h, size updated; minalloc/maxalloc/checksum kept."""
import struct, sys
packed = bytearray(open(sys.argv[1], 'rb').read())
w = open(sys.argv[2], 'rb').read(); h = struct.unpack_from('<14H', w)
assert h[3] == 0
wrap = bytearray(w[h[4] * 16:(h[2] - (h[1] != 0)) * 512 + h[1]])
for i in range(0x23, 0x1f1): wrap[i] ^= 0xbc
hdr = struct.unpack_from('<H', packed, 8)[0] * 16
pad = b' you have not'                      # stale buffer contents of the protection tool
n = (-len(packed)) % 16
assert n == len(pad), 'packed size changed: padding must be re-derived'
out = packed + pad[:n] + wrap
seg = (len(packed) + n - hdr) // 16
struct.pack_into('<HH', out, 2, len(out) % 512, (len(out) + 511) // 512)
struct.pack_into('<HH', out, 0x0e, seg + 0x152, 0x64)   # SS:SP
struct.pack_into('<HH', out, 0x14, 0, seg)              # IP, CS
open(sys.argv[3], 'wb').write(out)
