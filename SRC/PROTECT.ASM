;==========================================================================
; AVATAR.EXE copy-protection wrapper (appended after the EXEPACK stub)
;
; Reconstructed from the shipped (GOG) AVATAR.EXE; assembles byte-exact
; with MASM 3.00 (tools/wrapbuild.sh). tools/wrap.py appends it to the
; EXEPACKed game, XOR-encrypts bytes 23h..1F0h with 0BCh (what CRYPT
; undoes at run time) and points the MZ entry at offset 0.
;
; Layout:
;   0000-0022  crack stub (not original): sets up registers and far-jumps
;              straight to the EXEPACK unpacker at image seg 1772h:0012h,
;              skipping the disk check. The bytes it replaced (the
;              protection's saved header words and entry code, encrypted
;              from 12h) are lost; 0023h is the last byte of one of them.
;   0024-0126  key-disk check: patch the diskette parameter table (INT 1Eh
;              vector at 0:78h), FORMAT/VERIFY sectors on track 6 of A:/B:
;   0127-01A3  messages
;   01A4-020F  read the key sector, restore SS:SP/CS:IP of the packed
;              program from it, re-encrypt and jump on
;   0210-023A  CRYPT, XORs 12h..1F0h with 0BCh
;   0255-0313  BIOS-tick timing checks (anti-debugging)
;   0318-051F  sector buffer
; Encodings MASM 3.00 does not produce (the crack's register moves, RETF,
; LEA with an absolute non-label offset) are spelled as DB.
;==========================================================================
WRAP	SEGMENT
	ASSUME CS:WRAP, DS:WRAP, ES:WRAP

;---- crack stub

	mov ax,ds
L_0002:	mov es,ax
	add ax,01847H
START_EXE:	mov ss,ax
	mov sp,080H
	sub ax,0C5H
	push ax
	mov ax,012H
	push ax
	db	031H,0C0H	; xor ax,ax
	db	089H,0C3H	; mov bx,ax
	db	089H,0C1H	; mov cx,ax
	db	089H,0C2H	; mov dx,ax
	db	089H,0C5H	; mov bp,ax
	db	089H,0C6H	; mov si,ax
	db	089H,0C7H	; mov di,ax
	db	0CBH	; retf
	db	0D0H		; tail of an overwritten instruction
;---- key-disk check
	call CHKTRACK
	cmp ah,0
	jz L_002F
	jmp FAIL_MSG
L_002F:	jmp READKEY
	mov dl,0
	call CHKTRACK
	cmp ah,0
	jz L_002F
	mov dl,1
	call CHKTRACK
	cmp ah,0
	jz L_002F
	lea dx,MSG_INSERT
	mov ah,9
	int 021H
	mov ah,0
	int 016H
	mov dl,0
	call CHKTRACK
	cmp ah,0
	jz L_002F
	mov dl,1
	call CHKTRACK
	cmp ah,0
	jz L_002F
	jmp FAIL_MSG
	jmp L_00F5
CHKTRACK:	mov ax,0
	mov es,ax
	mov dh,0
	mov bx,078H
	mov ax,es:[bx]
	mov cx,ax
	mov bx,07AH
	mov ax,es:[bx]
	mov es,ax
	mov bx,cx
	mov al,3
	mov es:[bx+3],al
	mov al,080H
	mov es:[bx+5],al
	mov bx,cs
	mov ds,bx
	mov es,bx
	mov bx,0
	mov cx,5
L_009D:	push cx
	mov cl,2
	mov ch,6
	mov al,4
	mov ah,4
	int 013H
	pop cx
	cmp ah,0
	jz L_00B3
	loop L_009D
	jmp short L_00F5
	nop
L_00B3:	mov ax,0
	mov es,ax
	mov bx,078H
	mov ax,es:[bx]
	mov cx,ax
	mov bx,07AH
	mov ax,es:[bx]
	mov es,ax
	mov bx,cx
	mov al,2
	mov es:[bx+3],al
	mov al,01AH
	mov es:[bx+5],al
	mov bx,cs
	mov es,bx
	mov dh,0
	mov bx,0
	mov cx,5
L_00E2:	push cx
	mov cl,0BBH
	mov ch,6
	mov al,4
	mov ah,4
	int 013H
	pop cx
	cmp ah,0
	jz L_00F5
	loop L_00E2
L_00F5:	ret
FAIL_MSG:	mov bx,cs
	mov ds,bx
	lea dx,MSG_ORIGONLY
	mov ah,9
	int 021H
FAIL:	mov bx,0
	mov es,bx
	mov bx,078H
	mov ax,es:[bx]
	mov cx,ax
	mov bx,07AH
	mov ax,es:[bx]
	mov es,ax
	mov al,2
	mov es:[bx+2],al
	mov al,02AH
	mov es:[bx+5],al
	mov ah,04CH
	int 021H
MSG_ORIGONLY	db	0DH,0AH
	db	0DH,0AH
	db	'PLEASE USE ORIGINAL DISK ONLY.',0DH,0AH
	db	'$'
MSG_INSERT	db	0DH,0AH
	db	0DH,0AH
	db	'PLEASE INSERT ORIGINAL DISK IN DRIVE A OR B',0DH,0AH
	db	'THEN PRESS ANY KEY TO CONTINUE . . .',0DH,0AH
	db	'$'

;---- read key sector, restart packed program
READKEY:	mov bx,cs
	mov ds,bx
	mov es,bx
	lea bx,SECBUF
	mov cx,5
L_01B1:	push cx
	mov cl,1
	mov ch,6
	mov al,1
	mov ah,2
	int 013H
	pop cx
	cmp ah,0
	jz L_01C7
	loop L_01B1
	jmp FAIL_MSG
L_01C7:	pop es
	pop ds
	mov si,bx
	add si,0100H
	add si,word ptr cs:L_0002
	push ds
	mov bx,ds
	add bx,010H
	mov ax,cs
	mov es,ax
	mov ds,ax
	mov di,8
	lodsw
	stosw
	lodsw
	add ax,bx
	stosw
	lodsw
	mov cx,ax
	lodsw
	add ax,bx
	pop bx
	pop si
	pop bp
	popf
CRYPT_END:	call CRYPT
	mov ds,bx
	mov es,bx
	mov ss,ax
	mov sp,cx
	mov ax,bp
	mov cx,si
	mov bx,0
	mov dx,bx
	mov bp,dx
	mov si,dx
	mov di,dx
	jmp START_EXE

;---- CRYPT: toggle the encryption of 12h..1F0h
CRYPT:	pushf
	push ds
	push es
	push ax
	push bx
	push cx
	push dx
	mov bx,cs
	mov ds,bx
	mov es,bx
	db	08DH,01EH,012H,0	; lea bx,[0x12]
	lea cx,CRYPT_END
	sub cx,2
	sub cx,bx
L_022A:	mov al,[bx]
	xor al,0BCH
	mov [bx],al
	inc bx
	loop L_022A
	pop dx
	pop cx
	pop bx
	pop ax
	pop es
	pop ds
	popf
HOOK_RET:	ret
	db	26 dup(0)
	pushf
	push cx
	push dx
	push ax
	call GETTICKS
	push dx
	push cx
	cmp al,0
	jz L_026E
	add dx,0B0H
	jnc L_0269
	inc cx
L_0269:	add cx,018H
	jc L_0298
L_026E:	sub dx,word ptr cs:TICK_LO
	jnc L_0276
	dec cx
L_0276:	sub cx,word ptr cs:TICK_HI
	jc L_0298
	mov word ptr cs:DELTA_HI,cx
	mov word ptr cs:DELTA_LO,dx
	pop cx
	pop dx
	mov word ptr cs:TICK_HI,cx
	mov word ptr cs:TICK_LO,dx
	pop ax
	pop dx
	pop cx
	popf
	ret
L_0298:	jmp FAIL
DELTA_HI	db	6,0
DELTA_LO	db	040H,0
	pushf
	push cx
	push dx
	mov cx,word ptr cs:DELTA_HI
	cmp cx,0
	jnz L_0298
	mov cx,word ptr cs:DELTA_LO
	cmp cx,word ptr cs:MAXDELTA
	jnc L_0298
	pop dx
	pop cx
	popf
	ret
MAXDELTA	db	090H,0
	call GETTICKS
	mov word ptr cs:TICK_HI,cx
	mov word ptr cs:TICK_LO,dx
	mov ax,0
	mov es,ax
	mov ax,es:[04EH]
	cmp ax,0BFFFH
	jng L_02DD
	mov ax,es:[012H]
L_02DD:	mov cx,ax
	mov ax,es:[6]
	cmp al,0F0H
	jnl L_02EE
	cmp cx,ax
	jz L_02EE
	jmp FAIL
L_02EE:	mov ax,es:[0EH]
	cmp al,0F0H
	jnl L_02FD
	cmp ax,cx
	jz L_02FD
	jmp FAIL
L_02FD:	lea bx,HOOK_RET
	mov ax,0C3H
	mov [bx],ax
	mov bx,cs
	mov ds,bx
	mov es,bx
	ret
GETTICKS:	mov ah,0
	pushf
	int 01AH
	popf
	ret
TICK_HI	db	020H,0
TICK_LO	db	0,2
SECBUF	db	520 dup(0)

WRAP	ENDS
	END
