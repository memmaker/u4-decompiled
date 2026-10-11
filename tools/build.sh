#!/bin/sh
# build.sh [avatar|title]...: build the Ultima IV executables from source in DOSBox-X with
# MSC 4.0 + MASM 3.00 + LINK 3.51 + EXEPACK 4.05 (toolchain/msc40), then apply the post-link steps
# that the shipped files went through. Outputs build/avatar/AVATAR.EXE and build/title/TITLE.EXE;
# compared against gog/ when the originals are present (the build itself never reads them).
cd "$(dirname "$0")/.." || exit 1
CF='/Ox /Zp /Gc'
rc=0

prep() {  # prep DIR SRCDIR: fresh build dir with upper-case 8.3 names
  rm -rf "$1" && mkdir -p "$1" && cp "$2"/*.C "$2"/*.H "$2"/*.ASM "$1"/ || exit 1
  ( cd "$1" && for f in *; do u=$(echo "$f" | tr a-z A-Z); [ "$f" != "$u" ] && mv "$f" "$u.tmp" && mv "$u.tmp" "$u"; done )
}
compile() {  # compile MODULES JMODULES: batch lines for each module, .ASM -> MASM, .C -> MSC (/J if listed)
  for m in $1; do
    if [ -f "$B/$m.ASM" ]; then echo "MASM /Mx $m; >> LOG.TXT"
    else case " $2 " in *" $m "*) j=' /J';; *) j='';; esac; echo "MSC $CF$j $m; >> LOG.TXT"; fi
  done
}
check() {  # check BUILT ORIGINAL
  if [ -f "$2" ]; then
    if cmp -s "$1" "$2"; then echo "$(basename "$1"): byte-identical to the original"
    else echo "$(basename "$1"): DIFFERS from the original ($(cmp -l "$1" "$2" 2>/dev/null | wc -l) bytes)"; rc=1; fi
  else echo "$(basename "$1"): built ($2 not present for comparison)"; fi
}
fail() { echo "$1 build failed, see $B/LOG.TXT"; grep -a -i -E "error" "$B/LOG.TXT" | grep -v Errors | head; exit 1; }

avatar() {
  B=build/avatar; prep $B SRC
  # link order of the original (code/data layout follows it)
  MODS="ERRMSG LOW U4_USE U4_FILE U4_UTIL UTIL2 U4_MAIN U4_SOUND U4_MAIN2 U4_DOS U4_GRAPH U4_MAP U4_END U4_ANIM
  U4_EXPLO U4_Z U4_CSTES U4_NPC U4_COMBA U4_SPELL U4_Q_N_V U4_GET U4_LOCAT U4_COMBB U4_COMBC U4_DNG U4_HOLE U4_MIX
  U4_SRCH U4_EVT U4_AI U4_TALK U4_3D U4_SRCH2 U4_PEER U4_INIT U4_SHOPS U4_LB U4_SHRIN U4_VAR"
  # modules compiled with /J (char is unsigned)
  JMODS="U4_USE U4_FILE U4_MAIN U4_MAIN2 U4_MAP U4_END U4_ANIM U4_COMBA U4_SPELL U4_Q_N_V U4_COMBB"
  { echo 'echo build > LOG.TXT'; compile "$MODS" "$JMODS"
    echo 'LINK /MAP @U4.RSP >> LOG.TXT'
    echo 'EP405 AVATAR.EXE PACKED.EXE >> LOG.TXT'
    echo 'MASM /Mx PROTECT; >> LOG.TXT'
    echo 'LINK PROTECT; >> LOG.TXT'
  } | perl -pe 's/\r?\n/\r\n/' > $B/B.BAT
  { echo $MODS | tr ' ' '\n' | sed '$!s/$/+/'; echo AVATAR; echo 'AVATAR;'; } | perl -pe 's/\r?\n/\r\n/' > $B/U4.RSP
  tools/dosrun.sh $B B.BAT
  [ -f $B/PACKED.EXE ] && [ -f $B/PROTECT.EXE ] || fail AVATAR
  mv $B/AVATAR.EXE $B/AVATAR_U.EXE   # as linked, before EXEPACK
  python3 -I tools/wrap.py $B/PACKED.EXE $B/PROTECT.EXE $B/AVATAR.EXE || exit 1
  check $B/AVATAR.EXE gog/AVATAR.EXE
}

title() {
  B=build/title; prep $B SRC-TITLE
  MODS="TITLE_X FILE TITLE_0 GRAPH BEEP INFLATE LOW TITLE_1 UTIL2 VAR DATA ERRMSG"
  { echo 'echo build > LOG.TXT'; compile "$MODS" ""
    echo "LINK /MAP $(echo $MODS | sed 's/ DATA / D:\\BINMODE DATA /'),TITLE; >> LOG.TXT"
    echo 'EP405 TITLE.EXE PACKED.EXE >> LOG.TXT'
  } | perl -pe 's/\r?\n/\r\n/' > $B/B.BAT
  tools/dosrun.sh $B B.BAT
  [ -f $B/PACKED.EXE ] || fail TITLE
  mv $B/TITLE.EXE $B/TITLE_U.EXE
  # the shipped TITLE.EXE was unpacked again and cracked
  python3 -I tools/unpack_exepack.py --compact $B/PACKED.EXE $B/UNPACKED.EXE > /dev/null || exit 1
  python3 -I tools/title_crack.py $B/UNPACKED.EXE $B/TITLE.EXE || exit 1
  check $B/TITLE.EXE gog/TITLE.EXE
}

[ $# -eq 0 ] && set -- avatar title
for t in "$@"; do $t; done
exit $rc
