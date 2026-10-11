#!/bin/sh
# wrapbuild.sh ASM OUTBIN: assemble a flat wrapper source with MASM 3.00 + LINK and strip the MZ header.
cd "$(dirname "$0")/.." || exit 1
W=build/wrap; rm -rf $W; mkdir -p $W; cp "$1" $W/WRAP.ASM
printf 'MASM /Mx WRAP,,WRAP; > LOG.TXT\r\nLINK WRAP; >> LOG.TXT\r\n' > $W/B.BAT
DOSTIMEOUT=100 tools/dosrun.sh $W B.BAT
grep -a -B1 "E r r o r" $W/LOG.TXT | tr -d '\r'
python3 -I - "$W/WRAP.EXE" "$2" <<'P'
import struct, sys
d = open(sys.argv[1], 'rb').read(); h = struct.unpack_from('<14H', d)
size = (h[2] - (h[1] != 0)) * 512 + h[1]
assert h[3] == 0, 'wrapper must have no relocations'
open(sys.argv[2], 'wb').write(d[h[4] * 16:size])
P
