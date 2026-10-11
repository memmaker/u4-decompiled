"""title_crack.py IN.EXE OUT.EXE: the crack found in the shipped TITLE.EXE. The disk-swap prompt C_2F07
("Insert PLAYER disk ... press drive letter") is made to return at once: its prologue `push bp; mov bp,sp`
becomes `jmp` to its own `ret 4` (C_2F07 is at _TEXT:2F07, the ret at 2FB5)."""
import struct, sys
d = bytearray(open(sys.argv[1], 'rb').read())
o = struct.unpack_from('<H', d, 8)[0] * 16 + 0x2f07
assert d[o:o + 3] == b'\x55\x8b\xec' and d[o + 0xae:o + 0xb1] == b'\xc2\x04\x00', 'C_2F07 moved'
d[o:o + 3] = b'\xe9' + struct.pack('<h', 0x2fb5 - (0x2f07 + 3))
open(sys.argv[2], 'wb').write(d)
