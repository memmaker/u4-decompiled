/*
 * Ultima IV - Quest Of The Avatar
 * (c) Copyright 1987 Lord British
 * reverse-coded by Ergonomy Joe in 2012
 */

/* c_common: uninitialized globals, emitted by the compiler as communals (COMDEF).
   MS LINK places them after _BSS in its symbol-hash order and does not write them
   into the EXE file; the link names in u4.h fix the order. Even-sized communals are
   word-aligned, which produces the original's padding bytes. */
#include "u4.h"

unsigned char D_9140;
unsigned char D_9141;
int D_9142;
struct tParty /*D_9144*/Party;
tMap32x32 far *D_933A[8][8];
int D_943A;	/* graphic adaptater type */
unsigned char /*D_943C*/tile_forward;
int D_943E;
unsigned D_9440;
unsigned char /*D_9442,D_9443*/ship_x, ship_y;
unsigned char /*D_9444*/tile_cur;
char D_9445;
unsigned D_9446;
char D_9448;
char D_944A[8];
unsigned char D_9452;
void far /*D_9454*/*pShapes;
jmp_buf D_9458;
unsigned /*D_946A*/CurMode;
unsigned char D_946C;
unsigned /*D_946E*/spell_cnt;
struct tCombat /*D_9470*/Combat;
struct t_68 /*D_9530*/Fighters;
int /*D_9598*/File_DNG;
int /*D_959A*/activeChara;
struct aStruct D_959C;
unsigned char /*D_959E*/tile_east;
void far /*D_95A0*/*pCharset;
char /*D_95A4*/spell_sta;
struct aStruct3 D_95A5;
int /*D_95A8*/txt_X;
char /*D_95AA*/tile_north;
unsigned /*D_95AC*/activeCharaY;
unsigned /*D_95AE*/hit_tile;
unsigned char /*D_95B0,D_95B1*/hit_x, hit_y;
unsigned char D_95B2[16];
unsigned char /*D_95C2*/tile_west;
unsigned char /*D_95C3*/tile_south;
int /*D_95C4*/txt_Y;
unsigned D_95C6;
int D_95C8;
unsigned char /*D_95CA*/tile_back;
int D_95CC;
unsigned char D_95CE[0x120];
char D_96EE;
int /*D_96F0*/File_MAP;
unsigned /*D_96F2*/WindDir;
char D_96F4;
int /*D_96F6*/File_TLK;
unsigned char D_96F8;
unsigned char D_96F9[11*11];
unsigned char D_9772;
