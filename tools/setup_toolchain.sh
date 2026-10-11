#!/bin/sh
# setup_toolchain.sh: assemble toolchain/msc40 (what tools/dosrun.sh mounts as D:) from WinWorld archives:
#   Microsoft C 4.0 (all disks, flat), MASM.EXE from MASM 3.00, EXEPACK.EXE 4.05 from MASM 5.0 as EP405.EXE.
# usage: setup_toolchain.sh [MSC40_7Z]   (default ~/Downloads/Microsoft C Compiler 4.0 (5.25-360k).7z)
# needs: 7z, curl
cd "$(dirname "$0")/.." || exit 1
MSC=${1:-"$HOME/Downloads/Microsoft C Compiler 4.0 (5.25-360k).7z"}
T=toolchain; DL=$T/dl; mkdir -p $DL
get() {  # get WINWORLD_ID NAME: download and unpack one WinWorld release into $DL/x_NAME
  [ -f $DL/$2.7z ] || {
    m=$(curl -sL "https://winworldpc.com/download/$1" | grep -o -E "/download/$1/from/[^\"]*" | head -1)
    curl -sL -A "Mozilla/5.0" -o $DL/$2.7z "https://winworldpc.com$m"; }
  rm -rf $DL/x_$2; mkdir -p $DL/x_$2/files; 7z x -y -o$DL/x_$2 $DL/$2.7z > /dev/null
  find $DL/x_$2 -name '*.img' | while read i; do 7z x -y -o$DL/x_$2/files "$i" > /dev/null; done
}
get 45e280b9-1b68-18c3-9a11-c3a4e284a2ef masm300   # Microsoft Macro Assembler 3.0 (5.25)
get 2ec3843c-c381-5a70-11c3-a5c28fc2a3ef masm50    # Microsoft Macro Assembler 5.0 (5.25)
mkdir -p $T/msc40/x && 7z x -y -o$T/msc40/x "$MSC" > /dev/null &&
  find $T/msc40/x -name '*.img' | while read i; do 7z x -y -o$T/msc40 "$i" > /dev/null; done
rm -rf $T/msc40/x
cp $DL/x_masm300/files/MASM.EXE $T/msc40/MASM.EXE
cp $DL/x_masm50/files/EXEPACK.EXE $T/msc40/EP405.EXE
strings -n 8 $T/msc40/MASM.EXE | grep -q 'Version 3.00' && strings -n 8 $T/msc40/EP405.EXE | grep -q 'Version' &&
  [ -f $T/msc40/C1.EXE ] && [ -f $T/msc40/LINK.EXE ] && [ -f $T/msc40/SLIBC.LIB ] && echo "toolchain ready: $T/msc40"
