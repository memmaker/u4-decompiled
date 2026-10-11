Lots of information/tools/remakes about "Ultima IV - Quest Of The Avatar" have been made, but so far, no one really gave an insight of the binary itself. To be more precise, of the executables of the PC version of the game (ported by James Van Artsdalen).
There are two of them: AVATAR.EXE and TITLE.EXE

Basically, what I did is reverse engineer them to obtain a list of source files, that, when compiled and linked, produce new executables very close to the original ones (there are maybe 10 bytes difference for each executable).

Some of the source files are in assembly code.
The biggest chunk is in C language, which means that it should be easier to read it.
Of course, since this is a reverse-engineered from binary, files|variables|functions names were lost and I had to come up with new naming. I hope you like it.

Concerning the compiler, I used "Microsoft C Compiler 4.00". Which is certainly the version that was used to build the original game.

Very good remakes of the game exist already; this project is not intended to compete with them at all. Instead, interested people can take a look at the code to understand some algorithms, coding technics from another age, ...

I hope you enjoy browsing the code !
ergonomy_joe

## Byte-exact build (AVATAR.EXE and TITLE.EXE)

`tools/build.sh` rebuilds both executables from `SRC/` and `SRC-TITLE/` so that they are **byte-identical to the
files shipped in the GOG release** (`setup_ultima_iv_-_quest_of_the_avatar_1.0_cs_(28045).exe`):

| file | SHA-1 |
|---|---|
| AVATAR.EXE | e8b5d4231e3cba60773e2e20851a90a043d5263a |
| TITLE.EXE  | d7ae41c2f398c8d4ee935bfb861b12030c9bf262 |

Requirements: DOSBox-X, 7z, curl, python3, and the Microsoft C 4.0 disk set from WinWorld.

    tools/setup_toolchain.sh ["path/to/Microsoft C Compiler 4.0 (5.25-360k).7z"]   # once
    tools/build.sh                     # -> build/avatar/AVATAR.EXE, build/title/TITLE.EXE

If the shipped files are put in `gog/` (e.g. `innoextract` the GOG installer), the build compares against them.
Nothing from the original executables is used to build.

Pipeline (what the shipped files went through):
- MSC 4.0 `/Ox /Zp /Gc` (`/J` for some modules), MASM 3.00 `/Mx`, LINK 3.51 (small model).
- The uninitialized globals are communals (`u4_var.c`, `SRC-TITLE/var.c`). MS LINK places them by its symbol-name
  hash and does not write them into the file; the link names in `u4.h`/`title.h` reproduce the original order
  (`tools/namefit.py`, `tools/comdef.py`).
- EXEPACK 4.05 (from MASM 5.0).
- AVATAR.EXE: a key-disk copy-protection wrapper is appended (`SRC/PROTECT.ASM`, XOR-encrypted by `tools/wrap.py`).
  In the shipped file its entry code is overwritten by a crack stub that jumps straight to the game.
- TITLE.EXE: the shipped file was unpacked again (`tools/unpack_exepack.py --compact`) and its disk-swap prompt
  patched out (`tools/title_crack.py`).
