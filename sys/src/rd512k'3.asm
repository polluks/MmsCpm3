VERS EQU '2 ' ; Sep  9, 2017  17:07  drm  "RD512K'3.ASM"
;*********************************************************
;	Disk I/O module for MMS CP/M 3.1
;	for RAM disk on the 512K RAM board
;	Copyright (c) 2017 Douglas Miller
;*********************************************************
	MACLIB Z80

	extrn	@trk,@sect,@dma,@dbnk,@cbnk
	extrn	@dircb,@dtacb
	extrn	@m512k
	extrn	?bnksl

;---------------------------------------------------------
;
;	Physical drives are assigned as follows:
;
;	40 - 1st drive
;
;---------------------------------------------------------
;	Ports and Constants
;---------------------------------------------------------
;  PORT ASSIGNMENTS
rd	equ	0	;
wr	equ	4	;
map	equ	080h	;

driv0	equ	40		; first drive in system
ndriv	equ	1		; # of drives is system

false	equ	0
true	equ	not false
;-------------------------------------------------------
;	Start of relocatable disk I/O module.
;-------------------------------------------------------
	cseg

	dw	thread
	db	driv0,ndriv
	jmp	init$rd
	jmp	login$rd
	jmp	read$rd
	jmp	write$rd
	dw	string
	dw	dphtbl,modtbl

string: DB	'RAM512K',0,' 256K RAM Disk ',0,'v3.10'
	DW	VERS
	DB	'$'

modtbl: db	10000000b,00000000b,00000000b,00000000b ; drive 40, like HDD
	  db	11111111b,11111111b,11111111b,11111111b

rddpb:	dw	128	; SPT - arbitrary
	db	3,7,0
	dw	255,63
	db	11000000b,0
	dw	08000h,0
	db	0,0	; PSH,PSM = 128byte sectors

r$port:	db	0,0	; mmu,mmu+wr

rd$map:
	db	0	; map value, not bank number
rd$addr:
	dw	0	; always in low 16K
usr$map:
	db	0	; map value, not bank number, from @dbnk + @dma
usr$addr:
	dw	0	; always in low 16K, from @dma

; common memory routines to copy to/from ramdisk
; Interrupts must be disabled before calling.
; Caller must restore bank 0 mapping on return.
rd$read:
	lbcd	r$port
	lda	rd$map	; source mapping
	outp	a
	mov	c,b
	lda	usr$map	; dest mapping
	outp	a
	inr	a	; in case of overlap
	inr	c	;
	outp	a	;
	lhld	usr$addr; DATA BUFFER ADDRESS (dest)
	xchg
	lhld	rd$addr	; source addr
	lxi	b,128
	ldir
	ret

rd$write:
	lbcd	r$port
	lda	usr$map	; source mapping
	outp	a
	inr	a	; in case of overlap
	inr	c	;
	outp	a	;
	mov	c,b
	lda	rd$map	; dest mapping
	outp	a
	lhld	rd$addr	; dest addr
	xchg
	lhld	usr$addr; DATA BUFFER ADDRESS (source)
	lxi	b,128
	ldir
	ret

thread	equ	$

	dseg

dphtbl: dw	0,0,0,0,0,0,rddpb,0,alv40,@dircb,0ffffh,0
	db 0

alv40:	ds	(256)/4 	; max blocks: 256

label:	db	020h,'RAMDISK3LBL'
lblen	equ	$-label
	db	00000001b,0,0,0	; no modes (yet)
	db	0,0,0,0,0,0,0,0	; password
	db	0,0,0,0		; ctime
	db	0,0,0,0		; utime

init$rd:	; interrupts are disabled - leave them that way
	; Check if a valid directory already exists...
	lda	@m512k
	sta	r$port
	mov	c,a
	adi	wr
	sta	r$port+1
	mov	b,a
	mvi	a,16+map	; first page of upper 256K
	outp	a
	mov	c,b
	outp	a
	lxi	h,0	; first sector... first dirent (label)
	lxi	d,label
	mvi	b,lblen
ird2:	ldax	d
	cmp	m
	jnz	ird1
	inx	d
	inx	h
	djnz	ird2
	jr	ird3
ird1:	; must re-initialize directory (to empty)
	lxi	d,0
	lxi	h,label
	lxi	b,32
	ldir
	xchg	; make rest empty
	lxi	d,32	; bytes/dirent
	mvi	b,63	; DRM (one already done)
	mvi	a,0e5h	; empty entry
ird0:	mov	m,a
	dad	d
	djnz	ird0
ird3:
	lda	@cbnk
	call	?bnksl
	ret

login$rd:
	xra	a
	ret

setup$rw:
	lhld	@dma
	mov	a,h
	ani	0c0h
	rlc
	rlc
	mov	b,a
	mov	a,h
	ani	03fh
	mov	h,a
	shld	usr$addr
	lda	@dbnk
	add	a
	add	a
	ora	b	; this makes assumptions...
	ori	map
	sta	usr$map
	lda	@sect	; 0-127
	ora	a
	rar	; * 128
	mov	h,a
	mvi	a,0
	rar
	mov	l,a
	shld	rd$addr
	lda	@trk	; 0-15
	adi	16+map	; upper 256K, enable mapping
	sta	rd$map
	ret

read$rd:
	call	setup$rw
	di
	call	rd$read
	lda	@cbnk
	call	?bnksl
	ei
	ret

write$rd:
	call	setup$rw
	di
	call	rd$write
	lda	@cbnk
	call	?bnksl
	ei
	ret

	end
