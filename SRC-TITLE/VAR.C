/*
 * Ultima IV - Quest Of The Avatar
 * (c) Copyright 1987 Lord British
 * reverse-coded by Ergonomy Joe in 2012
 */

/* c_common: uninitialized globals, emitted as communals (COMDEF). MS LINK places them
   after _BSS in its symbol-hash order and does not write them into the EXE file. */
#include "title.h"

unsigned /*D_6E80*/D_6E80;
struct tParty /*D_6E82*/Party;
unsigned /*D_7078*/D_7078;	/*graphic adapter*/
void far /*D_707A*/*pShapes;
void far /*D_707E*/*pAnim;
unsigned /*D_7082*/D_7082;
void far /*D_7084*/*pCharset;
unsigned /*D_7088*/txt_X;
unsigned /*D_708A*/txt_Y;
void far /*D_708C*/*pTitle;
