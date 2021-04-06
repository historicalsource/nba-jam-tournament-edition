**************************************************************************
*	GSP DMA OBJECT HANDLER
*
*	Version 1.0  By Warren Davis 9/1/87
*	Version 2.01 By Eugene Jarvis 10/25/87
*	Version 3.0  By Eugene Jarvis 12/20/87
*	Version 3.1  By Eugene Jarvis 7/4/88
*	Version 3.2  By Eugene Jarvis 8/8/88
*	Version 3.21 By Shawn Liptak 7/24/91 - Minor improvements (Total carnage)
*	Version 3.3  By Shawn Liptak 9/13/91 - More improvements
*	Version 4.0  By Shawn Liptak 1/27/92 - Basketball started
*	Version 4.1  By Shawn Liptak 3/23/92 - DMA 2 version
*	Version 4.2  By Shawn Liptak 7/23/92 - Faster
*	Version 4.3  By Shawn Liptak 10/2/92 - Added dtype
*
*	COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 10/5/93 18:53
**************************************************************************
	.file	"ndsp1.asm"
	.title	"GSP display processor V 4.3"
	.width	132
	.option	b,d,l,t
	.mnolist


	.include	gsp.equ
	.include	sys.equ
	.include	mproc.equ
	.include	disp.equ
	.include	shawn.hdr
	.include	court.tbl
	.include	imgtbl.glo


	.if	DEBUG
;	.include	GAME.EQU
	.ref	SLDEBUG
	.endif



	.ref	HALT,pal_getf,FRANIMQ
;	.ref	_3d_build
;	.ref	d3vis_p
	.ref	PCNT
	.ref	crt_colors
	.ref	dirq_wait
	.ref	SYSCOPY,IRQSKYE

	.def	scale74f_t,scale59_t,scale61f_t,scale63f_t
	.def	scale57_t,scale58_t,scale60_t
	.def	scale61_t,scale61t_t,scale62_t
	.def	scale62t_t,scale63_t,scale64_t,scale64t_t
	.def	scale65_t,scale65t_t,scale65f_t
	.def	scale66_t,scale66t_t,scale66f_t
	.def	scale67_t,scale67t_t,scale67f_t
	.def	scale68_t,scale68t_t,scale68f_t
	.def	scale69_t,scale69f_t
	.def	scale610_t,scale610t_t,scale610f_t
	.def	scale611_t,scale611t_t,scale611f_t
	.def	scale70_t,scale70t_t,scale70f_t
	.def	scale71_t,scale72_t,scale72f_t
	.def	scale74_t,scale76et_t


;global variables

	.sect	"OFIXED"

OBJLST		.long	0	;*Active object list
OFREE		.long	0	;*Free object block
BAKLST		.long	0	;*Background list



GND_Y		.equ	116-40
GNDI_Y		.equ	116
GNDI_W		.equ	1277
GNDI_H		.equ	138
GND_H		.equ	GNDI_H+40
GZBASE		.equ	894

	.bss	SCROLLX		,32	;X scroll value
	.bss	SCROLLY		,32	;Y scroll value
					;/ Must stay in order
	.bss	WORLDTLX	,32	;Left X screen coord (16:16)
	.bss	WORLDTLY	,32	;Top Y screen coord (16:16)
	.bss	WORLDTL		,32	;Top left world Y:X

	.bss	SCRNTL		,32	;TOP LEFT [Y,X] SCREEN (SCRN COORD.)
	.bss	SCRNLR		,32	;LOWER RIGHT [Y,X] SCREEN (SCRN COORD.)

	.bss	dpage		,16	;Display page; 0=Page0, -1=Page1
	.bss	dtype		,16	;Display type; 0=2D, 1=3D, -=Special
	.bss	dcode_p		,32	;!0=*Special code (^ must = neg)
	.bss	DMAQCUR		,32	;Misc DMAQ position

	.bss	OBJSTR,NOBJ*OBSIZ	;Object structure mem

QSIZE	.set	(NOBJ+GNDI_H)*BQCELL
QMSIZE	.set	NOBJ*BQCELL
	.bss	dmaq0		,QSIZE	;Main DMA queue
	BSSX	DMAQ		,QMSIZE	;Misc DMA queue

	BSSX	gndstat		,16	;!0=Show ground
	BSSX	gndpos_t	,16*GND_H
	BSSX	gndx		,32
	.bss	DISPLAYON	,16	;!0=Do display processing
;	BSSX	QDMAFLG		,16	;!0=Misc DMAQ being updated

	BSSX	_3dstat		,16	;!0=Show polygons


	.text


********************************
* NO CODE BEFORE DMA INT!!! (Cache aligned)

********************************
* DMA interrupt
* B12=*End of DMA regs
* B13=DMAQ count-1 or Neg
* B14=*Next DMAQ fetch

 SUBR	dma_irq

	move	-*b14,-*b12,L
	move	-*b14,-*b12,L
	move	-*b14,-*b12,L
	move	-*b14,-*b12,L
	move	-*b14,-*b12,L
	move	-*b14,-*b12,L		;DMA go!

	addi	>c0,b12			;DMAREGS (End of DMA)
	subk	1,b13
	jrn	dmaint1			;Queue empty?
	reti

dmaint1
	setf	1,0,0			;>Disable dma interrupt
	move	b12,@INTENB+1		;Clr X1E
	clr	b13			;For safety!
	subk	1,b13			;-1
	reti


********************************
* Load DMA Q from obj list (3D type)
* A0=*Obj list
* A4=*DMAQ next free spot
* A13=Screen BR, A14=Screen TL
* B2=Y offset for top of page : XPad offset
* B4=World Y:X
* B5=OFLAGS offset
* B6=World center scrn X * 64K
* B7=Default scale
* B11=*DMACTRL

	.align

#lp
	move	b5,a3
	add	a0,a3
	move	*a3+,a1			;Get OFLAGS
	mmfm	a3,a12,a11,a9,a8
	move	*a0(OYVAL),a10,L	;Get int Y

	btst	B_3DQ,a1
	jrz	#chk3d

	move	b4,a6			;World TL Y:X
	subxy	a6,a10			;-world coord to get screen coord
	move	*a0(OXPOS),a2		;X
	move	*a0(ODATA_p),a3,L	;*gndpos_t
	move	*a3,a3			;Get X shift
	sub	a3,a2
	movx	a2,a10			;A10=Obj Y:X
	jruc	#noscl


#chk3d	btst	B_3D,a1
	jrnz	#3d

	move	*a0(OXPOS),a2		;X
	movx	a2,a10			;A10=Obj Y:X
	btst	B_SCRNREL,a1
	jrnz	#noscl			;Screen relative XY?
	move	b4,a6			;World TL Y:X
	subxy	a6,a10			;-world coord to get screen coord
#noscl	move	b7,a5			;A5=Y:X scale

					;A8=Const:PAL
					;A9=VSize:HSize
					;A10=Dest Y:X
					;A11=*SAG
					;A12=Offset:Ctrl

;Check for flipping, clipping, adjust offset, sag

				;>Calc top,bot,lft,rgt clips
	clr	a3		;A3=TL clip size
	move	a10,a2
	addxy	a9,a2		;BR Y:X
	subxy	a13,a2		;A2=BR clip size
	JRYGE	#10
	movy	a3,a2		;Clr bclip if y neg
#10	JRXGE	#20
	movx	a3,a2		;Clr rclip if x neg

#20	move	a14,a6
	subxy	a10,a6		;tc : lc
	JRYLT	#30
	movy	a6,a3		;Top clip size
	movy	a14,a10		;Adjust start position to window edge

#30	JRXLT	#35
	movx	a6,a3		;Left clip size
	movx	a14,a10		;Adjust start position to window edge

#35	move	a2,b0		;Save
	add	a3,a2		;TL clip+BR clip
	jrz	#noclip		;Zero clip?


	movx	a9,a6		;HSize

	subxy	a2,a9		;Get clipped size
	JRXLE	#nxt		;Totally clipped?
	JRYLE	#nxt

	clr	a1
	movx	a2,a1
	move	a1,a1
	jrz	#xclipzero
	movx	a9,a1
	subk	8,a1
	jrle	#nxt		;<=8 wide? Skip so DMA doesn't lockup

#xclipzero
	movx	a6,a9		;Restore hsize

	movx	a3,a1		;A1=Left clip


	btst	B_FLIPH,a12
	jrz	#nofh

	subxy	a1,a10		;Original X

	move	b0,a1		;LClip=RClip
	zext	a1
	subxy	a1,a10		;X-RClip


#nofh	btst	B_FLIPV,a12
	jrz	#nofv

	move	b0,a3		;Bot clip

#nofv	srl	16,a3		;A3=Top or bot clip
	jrz	#t0
	zext	a6
	mpyu	a6,a3		;T or B clip * total hsize


#t0
	add	a1,a3		;Add left clip + tc*ths
	move	a12,a1
	sll	32-15,a1	;Get bits 12-14
	srl	32-15+12,a1
	jrnz	#not8
	movk	8,a1
#not8	mpys	a1,a3		;# of bits to skip
	add	a3,a11		;Add to SAG
	sll	16,a2
	addxy	a2,a12		;Add clip offset to offset


#noclip
	btst	B_FLIPV,a12
	jrz	#nofv2

	movy	a9,a1			;VSize
	srl	16,a1
	subk	1,a1
	sll	16,a1
	addxy	a1,a10
#nofv2
#chkhflip
	btst	B_FLIPH,a12
	jrz	#nofh2

	movx	a9,a1			;HSize
	subk	1,a1
	zext	a1
	addxy	a1,a10
#nofh2

	move	b2,a1
	addxy	a1,a10			;Add the page y offset : XPad
	rl	16,a12			;Flip ctrl & offset
	mmtm	a4,a5,a8,a9,a10,a11,a12	;Save the dma regs
	addk	1,b13			;+1 Q cnt
	jrle	#strtdma		;DMA not going?

#nxt
dma_objlst
	move	*a0,a0,L		;Get next link
	jrnz	#lp			;More?
	rets



#3d					;>3D
	move	*a0(OXVAL),a7,L		;X
	move	b4,a2
	subxy	a2,a10			;-World Y
	move	b6,a2
	sub	a2,a7			;-World center X
	move	*a0(OXANI),a5,L		;X anipt
	add	a5,a7
	sra	16-5,a7			;/2048 (leave 5 bits frac)

	move	*a0(OZPOS),a2		;894 to 1379 (Z range 486)
	move	*a0(OMISC),a3		;Z offset
	add	a3,a2
	move	a2,a6

	addi	(819-GZBASE),a2		;768 to ?
	mpys	a2,a7
	move	a7,a3
	sra	2,a3			;/4
	sub	a3,a7
	sra	1,a3			;/2
	sub	a3,a7
	sra	14,a7			;/16k
	addi	200,a7
	sra	16,a5
	sub	a5,a7			;-X anipt
	movx	a7,a10

	subi	GZBASE,a6		;-Base
	jrge	#zok
	clr	a6
#zok	move	a6,a2
	move	a6,a3
	sra	1,a6			;Z/2
	sra	3,a3			;Z/8
	sub	a3,a6			;=Z/2.667

	addi	GND_Y,a6
	sll	16,a6
	addxy	a6,a10			;+Z

	btst	B_NOSCALE,a1
	jrnz	#noscl			;Scale off?

	btst	B_SHAD,a1
	jrz	#nots
	srl	1,a10
	move	@PCNT,a5		;Set X to even or odd
	srl	1,a5
	addc	a10,a10
	jruc	#noscl

#nots
	cmpxy	a13,a10
	JRXGE	#nxt			;Left edge past rclip?

	move	a10,a3
	addxy	a9,a3
	cmpxy	a14,a3
	JRXLT	#nxt			;Rgt edge past lclip?

	srl	4,a2			;/16
	sll	6,a2			;*64

	move	*a0(ODATA_p),a5,L	;*Scale_t
	add	a2,a5
	move	*a5,a5,L		;A5=Y:X scale

	jruc	#chkhflip		;Visable



#strtdma				;>Start DMA if necessary
	dint

	setf	1,0,0			;Enable DMA int
	movk	1,a1
	move	a1,@INTENB+1		;X1E
	setf	16,1,0

	move	*b11,b0
	jrn	#dmaok			;DMA busy?

	move	b13,b13
	jrn	#dmaok			;DMA int done?

	trap	1			;Cause DMA int

#dmaok	eint
	.if	DEBUG
	addk	1,b3			;Restart cnt
	.endif
	jruc	#nxt




SCLT	.macro	sx,sy,sxa,sya
	.eval	:sx:*1048,X	;Convert (has slight error)
	.eval	:sy:*1048,Y
	.eval	:sxa:*1048,XA
	.eval	:sya:*1048,YA
	.loop	10
	.word	>10000000/X,>10000000/Y
	.word	>100000/(>10000000/X),>100000/(>10000000/Y)
	.eval	X+XA*1/4,X
	.eval	Y+YA*1/4,Y
	.endloop
	.loop	10
	.word	>10000000/X,>10000000/Y
	.word	>100000/(>10000000/X),>100000/(>10000000/Y)
	.eval	X+XA*2/4,X
	.eval	Y+YA*2/4,Y
	.endloop
	.loop	10
	.word	>10000000/X,>10000000/Y
	.word	>100000/(>10000000/X),>100000/(>10000000/Y)
	.eval	X+XA*3/4,X
	.eval	Y+YA*3/4,Y
	.endloop
	.loop	10
	.word	>10000000/X,>10000000/Y
	.word	>100000/(>10000000/X),>100000/(>10000000/Y)
	.eval	X+XA,X
	.eval	Y+YA,Y
	.endloop
	.loop	10
	.word	>10000000/X,>10000000/Y
	.word	>100000/(>10000000/X),>100000/(>10000000/Y)
	.eval	X+XA*5/4,X
	.eval	Y+YA*5/4,Y
	.endloop
	.endm


				;>Generate scale tables
scale57_t
scale58_t
scale59_t
	SCLT	594,594,37,37	;5'8 (68)
	SCLT	507,507,31,31
	SCLT	360,360,20,20
scale60_t
scale61_t
scale61t_t
	SCLT	629,629,39,39	;6'0 (72)
	SCLT	537,537,34,34
	SCLT	360,360,20,20
scale61f_t
scale62_t
scale63f_t
scale63_t
	SCLT	646,646,41,41	;6'2 (74)
	SCLT	552,552,35,35
	SCLT	360,360,20,20
scale62t_t
	SCLT	607,646,39,41	;6'2 (74) thin (.94)
	SCLT	519,552,33,35
	SCLT	360,360,20,20
scale64_t
scale65_t
	SCLT	664,664,42,42	;6'4 (76)
	SCLT	567,567,35,35
	SCLT	360,360,20,20
scale64t_t
scale65t_t
	SCLT	624,664,39,42	;6'4 (76) thin (.94)
	SCLT	533,567,33,35
	SCLT	360,360,20,20
scale65f_t
	SCLT	730,664,46,42	;6'4 (76) fat (1.10)
	SCLT	624,567,39,35
	SCLT	360,360,20,20
scale66_t
scale67_t
	SCLT	681,681,43,43	;6'6 (78)
	SCLT	582,582,36,36
	SCLT	360,360,20,20
scale66t_t
scale67t_t
	SCLT	640,681,40,43	;6'6 (78) thin (.94)
	SCLT	547,582,34,36
	SCLT	360,360,20,20
scale66f_t
scale67f_t
	SCLT	749,681,47,43	;6'6 (78) fat (1.10)
	SCLT	640,582,40,36
	SCLT	360,360,20,20
scale68_t
scale69_t
	SCLT	698,698,44,44	;6'8 (80)
	SCLT	597,597,37,37
	SCLT	360,360,20,20
scale68t_t
scale69t_t
	SCLT	656,698,41,44	;6'8 (80) thin (.94)
	SCLT	561,597,35,37
	SCLT	360,360,20,20
scale68f_t
scale69f_t
	SCLT	768,698,48,44	;6'8 (80) fat (1.10)
	SCLT	657,597,41,37
	SCLT	360,360,20,20
scale610_t
scale611_t
	SCLT	715,715,45,45	;6'10 (82)
	SCLT	611,611,38,38
	SCLT	360,360,20,20
scale610t_t
scale611t_t
	SCLT	672,715,42,45	;6'10 (82) thin (.94)
	SCLT	574,611,36,38
	SCLT	360,360,20,20
scale610f_t
scale611f_t
	SCLT	801,715,50,45	;6'10 (82) fat (1.12)
	SCLT	684,611,43,38
	SCLT	360,360,20,20
scale70_t
	SCLT	733,733,46,46	;7'0 (84)
	SCLT	627,627,39,39
	SCLT	360,360,20,20
scale70t_t
	SCLT	689,733,43,46	;7'0 (84) thin (.94)
	SCLT	589,627,37,39
	SCLT	360,360,20,20
scale70f_t
	SCLT	806,733,51,46	;7'0 (84) fat (1.10)
	SCLT	690,627,43,39
	SCLT	360,360,20,20
scale71_t
scale72_t
	SCLT	751,751,47,47	;7'2 (86)
	SCLT	642,642,40,40
	SCLT	360,360,20,20
scale72f_t
	SCLT	841,751,53,47	;7'2 (86) fat (1.12)
	SCLT	719,642,45,40
	SCLT	360,360,20,20
scale74_t
scale74f_t
	SCLT	768,768,49,49	;7'4 (88)
	SCLT	657,657,41,41
	SCLT	360,360,20,20
scale76et_t
	SCLT	628,786,40,50	;7'6 (90) extra thin (.80)
	SCLT	538,672,34,42
	SCLT	360,360,20,20



#*******************************
* Load DMA Q from obj list (2D type)
* A0=*Obj list
* A4=*DMAQ next free spot
* A13=Screen BR, A14=Screen TL
* B2=Y offset for top of page : XPad offset
* B4=World Y:X
* B5=OFLAGS offset
* B6=World center scrn X * 64K
* B11=*DMACTRL

dma_objlst2d
	movi	>1000100,a5		;A5=Y:X scale
	jruc	#nxt

	.align

#lp
	move	b5,a3
	add	a0,a3
	move	*a3+,a1			;Get OFLAGS
	mmfm	a3,a12,a11,a9,a8

	move	*a0(OYVAL),a10,L	;Get int Y

	move	*a0(OXPOS),a2		;X
	movx	a2,a10			;A10=Obj Y:X
	btst	B_SCRNREL,a1
	jrnz	#noscl			;Screen relative XY?
	move	b4,a6			;A6=World TL Y:X
	subxy	a6,a10			;-world coord to get screen coord
#noscl
					;A8=Const:PAL
					;A9=VSize:HSize
					;A10=Dest Y:X
					;A11=*SAG
					;A12=Offset:Ctrl

;Check for flipping, clipping, adjust offset, sag

				;>Calc top,bot,lft,rgt clips
	clr	a3		;A3=TL clip size
	move	a10,a2
	addxy	a9,a2		;BR Y:X
	subxy	a13,a2		;A2=BR clip size
	JRYGE	#10
	movy	a3,a2		;Clr bclip if y neg
#10	JRXGE	#20
	movx	a3,a2		;Clr rclip if x neg

#20	move	a14,a7
	subxy	a10,a7		;wstart - pt -> a7 (tc : lc)
	JRYLT	#30
	movy	a7,a3		;Top clip size
	btst	7,a12
	jrnz	#30		;Zero compression on?
	movy	a14,a10		;Adjust start position to window edge

#30	JRXLT	#35
	movx	a7,a3		;Left clip size
	btst	7,a12
	jrnz	#35		;Zero compression on?
	movx	a14,a10		;Adjust start position to window edge

#35	move	a2,b0		;Save
	add	a3,a2		;TL clip+BR clip
	jrz	#noclip		;Zero clip?


	move	a9,a6		;Save VSize:HSize

	subxy	a2,a9		;Get clipped size
	JRXLE	#nxt		;Totally clipped?
	JRYLE	#nxt

	btst	7,a12
	jrz	#nozc		;Zero compression off?
	move	a6,a9		;Restore v:h size
	jruc	#noclip

#nozc
	clr	a1
	movx	a2,a1
	move	a1,a1
	jrz	#xclipzero
	movx	a9,a1
	subk	8,a1
	jrle	#nxt		;<=8 wide? Skip so DMA doesn't lockup

#xclipzero
	movx	a6,a9		;Restore hsize

	movx	a3,a1		;A1=Left clip


	btst	B_FLIPH,a12
	jrz	#nofh

	subxy	a1,a10		;Original X

	move	b0,a1		;LClip=RClip
	zext	a1
	subxy	a1,a10		;X-RClip


#nofh	btst	B_FLIPV,a12
	jrz	#nofv

	move	b0,a3		;Bot clip

#nofv	srl	16,a3		;A3=Top or bot clip
	jrz	#t0
	zext	a6
	mpyu	a6,a3		;T or B clip * total hsize


#t0
	add	a1,a3		;Add left clip + tc*ths
	move	a12,a1
	sll	32-15,a1	;Get bits 12-14
	srl	32-15+12,a1
	jrnz	#not8
	movk	8,a1
#not8	mpys	a1,a3		;# of bits to skip
	add	a3,a11		;Add to SAG
	sll	16,a2
	addxy	a2,a12		;Add clip offset to offset


#noclip
	btst	B_FLIPH,a12
	jrz	#300

	movx	a9,a1			;HSize
	subk	1,a1
	zext	a1
	addxy	a1,a10

#300	btst	B_FLIPV,a12
	jrz	#400

	movy	a9,a1			;VSize
	srl	16,a1
	subk	1,a1
	sll	16,a1
	addxy	a1,a10

#400
	move	b2,a1
	addxy	a1,a10			;Add the page y offset : XPad
	rl	16,a12			;Flip ctrl & offset
	mmtm	a4,a5,a8,a9,a10,a11,a12	;Save the dma regs
	addk	1,b13			;+1 Q cnt
	jrgt	#nxt			;DMA going?

	dint

	setf	1,0,0			;>Enable DMA int
	movk	1,a1
	move	a1,@INTENB+1		;X1E
	setf	16,1,0

	move	*b11,b0
	jrn	#dmaok			;DMA busy?

	move	b13,b13
	jrn	#dmaok			;DMA int done?

	trap	1			;Cause DMA int

#dmaok	eint
#nxt
	move	*a0,a0,L		;Get next link
	jrnz	#lp			;More?
	rets



#*******************************
* Load DMA Q from obj list (2D type)
* A0=*Obj list
* A4=*DMAQ next free spot
* A13=Screen BR, A14=Screen TL
* B2=Y offset for top of page : XPad offset
* B4=World Y:X
* B5=OFLAGS offset
* B6=World center scrn X * 64K
* B11=*DMACTRL

dma_objlst2dscl

;	movi	>1000100,a5		;A5=Y:X scale
	jruc	#nxt

	.align

#lp
	move	b5,a3
	add	a0,a3
	move	*a3+,a1			;Get OFLAGS
	mmfm	a3,a12,a11,a9,a8

	move	*a0(ODATA_p),a5,L	;Get scale value

	move	*a0(OYVAL),a10,L	;Get int Y

	move	*a0(OXPOS),a2		;X
	movx	a2,a10			;A10=Obj Y:X
	btst	B_SCRNREL,a1
	jrnz	#noscl			;Screen relative XY?
	move	b4,a6			;A6=World TL Y:X
	subxy	a6,a10			;-world coord to get screen coord
#noscl
					;A8=Const:PAL
					;A9=VSize:HSize
					;A10=Dest Y:X
					;A11=*SAG
					;A12=Offset:Ctrl

;Check for flipping, clipping, adjust offset, sag

				;>Calc top,bot,lft,rgt clips
	clr	a3		;A3=TL clip size
	move	a10,a2
	addxy	a9,a2		;BR Y:X
	subxy	a13,a2		;A2=BR clip size
	JRYGE	#10
	movy	a3,a2		;Clr bclip if y neg
#10	JRXGE	#20
	movx	a3,a2		;Clr rclip if x neg

#20	move	a14,a7
	subxy	a10,a7		;wstart - pt -> a7 (tc : lc)
	JRYLT	#30
	movy	a7,a3		;Top clip size
	movy	a14,a10		;Adjust start position to window edge

#30	JRXLT	#35
	movx	a7,a3		;Left clip size
	movx	a14,a10		;Adjust start position to window edge

#35	move	a2,b0		;Save
	add	a3,a2		;TL clip+BR clip
	jrz	#noclip		;Zero clip?


	movx	a9,a6		;HSize

	subxy	a2,a9		;Get clipped size
	JRXLE	#nxt		;Totally clipped?
	JRYLE	#nxt

	clr	a1
	movx	a2,a1
	move	a1,a1
	jrz	#xclipzero
	movx	a9,a1
	subk	8,a1
	jrle	#nxt		;<=8 wide? Skip so DMA doesn't lockup

#xclipzero
	movx	a6,a9		;Restore hsize

	movx	a3,a1		;A1=Left clip


	btst	B_FLIPH,a12
	jrz	#nofh

	subxy	a1,a10		;Original X

	move	b0,a1		;LClip=RClip
	zext	a1
	subxy	a1,a10		;X-RClip


#nofh	btst	B_FLIPV,a12
	jrz	#nofv

	move	b0,a3		;Bot clip

#nofv	srl	16,a3		;A3=Top or bot clip
	jrz	#t0
	zext	a6
	mpyu	a6,a3		;T or B clip * total hsize


#t0
	add	a1,a3		;Add left clip + tc*ths
	move	a12,a1
	sll	32-15,a1	;Get bits 12-14
	srl	32-15+12,a1
	jrnz	#not8
	movk	8,a1
#not8	mpys	a1,a3		;# of bits to skip
	add	a3,a11		;Add to SAG
	sll	16,a2
	addxy	a2,a12		;Add clip offset to offset


#noclip
	btst	B_FLIPH,a12
	jrz	#300

	movx	a9,a1			;HSize
	subk	1,a1
	zext	a1
	addxy	a1,a10

#300	btst	B_FLIPV,a12
	jrz	#400

	movy	a9,a1			;VSize
	srl	16,a1
	subk	1,a1
	sll	16,a1
	addxy	a1,a10

#400
	move	b2,a1
	addxy	a1,a10			;Add the page y offset : XPad
	rl	16,a12			;Flip ctrl & offset
	mmtm	a4,a5,a8,a9,a10,a11,a12	;Save the dma regs
	addk	1,b13			;+1 Q cnt
	jrgt	#nxt			;DMA going?

	dint

	setf	1,0,0			;>Enable DMA int
	movk	1,a1
	move	a1,@INTENB+1		;X1E
	setf	16,1,0

	move	*b11,b0
	jrn	#dmaok			;DMA busy?

	move	b13,b13
	jrn	#dmaok			;DMA int done?

	trap	1			;Cause DMA int

#dmaok	eint
#nxt
	move	*a0,a0,L		;Get next link
	jrnz	#lp			;More?
	rets




#*******************************
* Display object lists, called by DIRQ

DISPLAY
	movi	DMACTRL,b11		;B11=*DMACTRL


	movi	SCRNXP,b2		;B2=Page y offset : XPad offset
	movi	[253,0],b3
	move	@dpage,a1
	jrnz	#p1
	movi	[PAGE1YO,SCRNXP],b2
	movi	[509,256],b3
#p1
	movi	dmaq0+QSIZE,a4		;A4=*DMAQ for new data (Top)
	clr	b13			;Kill DMA
	move	b13,*b11
	move	b13,*b11
	movi	DMAREGS,b12		;B12=*DMAREGS
	subk	1,b13			;B13=Q count (-1)
	move	a4,b14			;B14=*DMAQ for next fetch (Top)

	movi	>30,b0
	move	b0,*b12(30h)		;DMACONF (Top/Bottom)
	move	b3,*b12,L		;DMAWINDOW



	move	@DISPLAYON,a0
	jrz	#doff			;Stop DMA of objects except for score?


	movi	WORLDTLX,b0		;>Scroll world
;	move	@SCROLLX,b6,L
;	move	@SCROLLY,b7,L
;	move	*b0,b3,L
;	add	b6,b3
;	move	b3,*b0+,L		;TLX
;	move	*b0,b4,L
;	add	b7,b4
;	move	b4,*b0+,L		;TLY

	move	*b0+,b3,L		;Quick version of ^
	move	*b0+,b4,L

	srl	16,b3
	movx	b3,b4			;B4=World top left Y:X
	move	b4,*b0,L		;WORLDTL

	movi	OFLAGS,b5		;B5=Obj data offset
	move	b4,b6
	addi	200,b6
	sll	16,b6			;B6=World center scrn X * 64K
	move	@SCRNLR,a13,L		;A13=Screen BR
	move	@SCRNTL,a14,L		;A14=Screen TL

	.if	DEBUG
	clr	b3			;trap1 cnt
	.endif

	move	@gndstat,a0
	jrz	#70			;Off?
	callr	gnd_dodma
#70
	move	@_3dstat,a0
	jrz	#80			;Off?
;	calla	_3d_build
;	callr	_3d_draw
#80

	move	@dtype,a1
	jrnz	#3dtype


	movi	BAKLST,a0
	callr	dma_objlst2d

	.if	DEBUG
	move	@SLDEBUG,a0
	jrnn	#nol2d
	movi	31<<10+10<<5,a0		;Proc usage
	move	a0,@ERASELOC
#nol2d
	.endif

	movi	OBJLST,a0
	callr	dma_objlst2d
	jruc	#doff


#3dtype
	jrgt	#3dgame

	move	@dcode_p,a0,L
	jrnn	#3dgame			;No special code?
	call	a0
	jruc	#x


#3dgame
;	movi	BAKLST,a0
;	movi	>1000100,b7		;Original scale
;	callr	dma_objlst

	.if	DEBUG
	move	@SLDEBUG,a0
	jrnn	#nol3d
	movi	31<<10+10<<5,a0		;Proc usage
	move	a0,@ERASELOC
#nol3d
	.endif

	movi	OBJLST,a0
	movi	>1000100,b7		;Original scale
	callr	dma_objlst



#doff
;	move	@QDMAFLG,a2
;	jrnz	#noman			;Q being modified?
	move	@DMAQCUR,a2,L
	movi	DMAQ+QMSIZE,a1
	cmp	a1,a2
	jrhs	#noman			;Empty?
	move	a1,@DMAQCUR,L		;Reset top of queue

	move	b2,a5

#lp	move	-*a1,-*a4,L		;>Copy manual DMAQ to end of Q
	move	-*a1,-*a4,L
	move	-*a1,-*a4,L
	move	-*a1,a0,L
	addxy	a5,a0			;+Y
	move	a0,-*a4,L
	move	-*a1,-*a4,L
	move	-*a1,-*a4,L
	addk	1,b13
	cmp	a2,a1
	jrhi	#lp


	move	*b11,b0
	jrn	#noman			;DMA busy?

	move	b13,b13
	jrn	#noman			;DMA int done?

	setf	1,0,0			;>Enable DMA int
	movk	1,a1
	move	a1,@INTENB+1		;X1E
	setf	16,1,0

	trap	1			;Cause DMA int

#noman
;	movi	nulldma,a0		;>Put null DMA at end of Q
;	mmfm	a0,a7,a8,a9,a10,a11,a12
;	mmtm	a4,a7,a8,a9,a10,a11,a12


	move	@HALT,a0
	jrnz	#novel			;Skip vel update?
	movi	OBJLST,a0
	callr	vel_add
#novel
#x
;	.if	DEBUG
;	move	@SLDEBUG,a0
;	jrnn	#noline
;
;	movi	31<<10+31<<5,a0		;Proc usage
;	move	a0,@ERASELOC
;
;#dqwt	move	b13,b13
;	jrge	#dqwt			;DMA busy?
;
;	movi	20<<10,a0		;DMA usage
;	move	a0,@ERASELOC
;
;#noline
;	.endif


	rets


;Null dma data
nulldma	.long	>80000000,IROM,0,>00010001,0,>1000100


#*******************************
* Velocity add loop
* A0=*Obj list
* Trashes A0-A7

#lp	move	a0,a1
	addk	OXVEL,a1

	mmfm	a1,a2,a3,a4,a5,a6,a7	;A7=XV, A6=YV, A5=ZV, A4=X, A3=Y, A2=Z

	add	a5,a2			;Add ZVEL to Z
	move	a2,-*a1,L
	add	a6,a3			;Add YVEL to Y (Uses hidden cycle!)
	move	a3,-*a1,L
	add	a7,a4			;Add XVEL to X ^
	move	a4,-*a1,L

vel_add	move	*a0,a0,L
	jrnz	#lp			;!End?
	rets



#*******************************
* Fill DMAQ with ground data for each line
* A4=*DMAQ next free spot
* B2=Y offset for top of page : XPad offset
* B4=World Y:X
* B11=*DMACTRL
* Trashes A0-A3,A5-A12,B0-B1
* >A4=*DMAQ next free spot

 SUBRP	gnd_dodma

	PUSH	a13,a14


;	movb	@IROM,a0
;	cmpi	>3f,a0
;	jreq	nofix			;Already fixed?
;
;	dint
;
;	move	@crt1+ISAG,a1,L
;	move	a1,a10			;A10=*Dest
;	move	a1,a2
;	addi	>1800000,a2
;	move	a2,a6
;	movi	GNDI_W*GNDI_H/4,a7
;copy	move	*a1+,*a2+,L
;	dsj	a7,copy
;
;
;	move	@crt2+ISAG,a7,L
;	addi	>1800000,a7
;	move	@crt2f+ISAG,a8,L
;	addi	>1800000,a8
;	move	@crt1f+ISAG,a9,L
;	addi	>1800000,a9
;	move	@crt1+ISIZEY,a2
;
;	setf	6,1,1			;Field1
;
;copylp	move	@crt1,a1		;ISIZEX
;copy2	move	*a6+,*a10+,1
;	dsj	a1,copy2
;
;	move	@crt2,a1		;ISIZEX
;copy3	move	*a7+,*a10+,1
;	dsj	a1,copy3
;
;	move	@crt2f,a1		;ISIZEX
;copy4	move	*a8+,*a10+,1
;	dsj	a1,copy4
;
;	move	@crt1f,a1		;ISIZEX
;copy5	move	*a9+,*a10+,1
;	dsj	a1,copy5
;
;	dsj	a2,copylp
;
;	setf	32,0,1			;Field1
;
;
;;	movi	IROM+(GNDI_W/2-100)*8,a6
;;	movi	IROM+GNDI_W/2*8,a7	;A7=*Middle of img line
;;	movi	IROM+(GNDI_W/2+100)*8,a8
;;	movk	1,a0
;;	movi	GNDI_H,a1
;;fill2	movb	a0,*a6
;;	movb	a0,*a7
;;	movb	a0,*a8
;;	addi	GNDI_W*6,a6		;Next line
;;	addi	GNDI_W*6,a7		;Next line
;;	addi	GNDI_W*6,a8		;Next line
;;	btst	0,a1
;;	jrnz	fill2b
;;	subk	8,a6
;;	addk	8,a8
;;fill2b	dsj	a1,fill2
;
;
;	movi	>3f,a0
;	move	a0,@IROM
;
;	eint
;nofix



	move	@gndx,a14,L		;16:16


	movi	gndpos_t,a0		;>Calc gnd x positions
	movi	GND_H,a7
	move	a14,a1
	movi	>120,a2
	divs	a2,a1
#glp	move	a14,a8
	sra	16,a8
;	sra	15,a8
;	addk	1,a8			;Round off
;	sra	1,a8
	move	a8,*a0+
	add	a1,a14
	dsj	a7,#glp


	move	@crt_colors,a0,L
	calla	pal_getf
	move	a0,a8			;A8=Const:palette

	movi	gndpos_t+40*16,a0	;Start on 1st court pos
	movi	GNDI_H,a7
	move	b4,a1
	sra	16,a1
	add	a1,a7
	jrle	#x			;No lines visable?
	movi	[1,400],a9		;A9=VSIZE:HSIZE
	move	b2,a10
	sll	16,a1
	subxy	a1,a10
	addi	[GNDI_Y,0],a10		;A10=Dest Y:X

	movi	>1000100,a5		;A5=Y:X scale
	movi	COURT+(GNDI_W/2-200)*8,a6 ;A6=*Middle of img line
;	movi	COURT+(GNDI_W/2-200)*6,a6 ;A6=*Middle of img line
	movi	(>8000|DMAWNZ)<<16,a12	;A12=OFFSET:CONTROL
;	movi	(>e000|DMAWNZ)<<16,a12	;A12=OFFSET:CONTROL


	movi	GNDI_W*8,a2		;Const: Next line
;	movi	GNDI_W*6,a2		;Const: Next line
	movi	[1,0],a3		;Const: Next Y

#lp	move	*a0+,a11
	sll	3,a11			;*8
;	sll	1,a11			;>*6
;	move	a11,a1
;	sll	1,a11
;	add	a1,a11
	add	a6,a11			;A11=*Image data

	mmtm	a4,a5,a8,a9,a10,a11,a12	;Save the dma regs
	addk	1,b13			;+1 Q cnt
	jrle	#strtdma		;DMA not going?

#next
	add	a2,a6			;SAG+1 line
	add	a3,a10			;Next Y

;	addi	>1,a5			;Scale DEBUG

	dsj	a7,#lp


#x	PULL	a13,a14
	rets


	.align
#strtdma				;>Start DMA if necessary
	dint
	setf	1,0,0			;Enable DMA int
	movk	1,a1
	move	a1,@INTENB+1		;X1E
	setf	16,1,0

	move	*b11,b0
	jrn	#dmaok			;DMA busy?

	move	b13,b13
	jrn	#dmaok			;DMA int done?

	trap	1			;Cause DMA int
#dmaok	eint
	.if	DEBUG
	addk	1,b3			;DEBUG cnt
	.endif
	jruc	#next



	.if	0

#*******************************
* Dump 3D data to DMA
* B2=Y offset for top of page : XPad offset
* B11=*DMACTRL
* B12=*End of DMA regs
* Trashes A0-A3,A5-A12,B0-B1


	.bss	linelsxy	,32
	.bss	linersxy	,32

D3XPTS	.equ	>140		;UHL *Xformed points array (Cnt, XYZ,XYZ..)

 SUBRP	_3d_draw	;B1 Free (B14)

	PUSH	a4,a13,a14
	PUSH	b3,b4,b5,b6,b7,b8,b9,b10,b13,b14


	setf	1,0,0			;>Disable DMA interrupt
	move	sp,@INTENB+1		;Clr X1E
	setf	16,1,0

	movi	[1,1],b13		;B13=Const 1:1

;	clr	b14			;DEBUG

	movi	>1000100,b5		;B5=1:1 scale
	movi	IROM,b9			;B9=*IROM
	movi	>800c<<16,b10		;B10=OFFSET:CONTROL

	movi	d3vis_p,a12		;A12=*3D object


;D3PTS	.equ	>120		;UHL *Points array (Cnt, XYZ,XYZ..)
;
;	PUSH	a0,a1			;DEBUG
;	movi	d3vis_p,a1
;	move	*a1,a0,L
;	jrz	#dx
;#debug	move	a1,a0
;	move	*a0,a1,L
;	jrnz	#debug
;	move	*a0(D3PTS),a1,L
;	jrz	$			;ERROR!!!
;#dx	PULL	a0,a1



	.align

#lpobj	move	*a12,a12,L
	jrz	#x			;End?
	move	a12,a14
	addi	D3XPTS,a14
	move	*a14+,a13,L		;A13=*Base of points_t
	move	*a14+,a14,L		;A14=*1st entry of face line_t

	move	*a13+,a0		;# pts
	jrz	#lpobj			;Not visable?


#facelp
	move	*a14+,a0
	move	a0,b6			;B6=Const:Pal for face
	sll	16,b6
	move	a14,a4
	movi	>7fff,a8		;>Find lowest/highest X Y

;DO BETTER
	move	a8,a9
	not	a9			;>8000
	move	a8,a10
	move 	a9,a11
	jruc	dd150

#lp2	add	a13,a1			;+Base
	move	*a1+,a2			;Get X
	cmp	a8,a2
	jrge	#xbig			;Bigger X?
	move	a2,a8			;New low
#xbig	cmp	a9,a2
	jrle	#xsml			;Smaller X?
	move	a2,a9			;New high
#xsml
	move	*a1,a1			;Get Y
	cmp	a10,a1
	jrge	#ybig			;Bigger Y?
	move	a1,a10			;New low
	move	a4,a5			;A5=*Left line line table
#ybig	cmp	a11,a1
	jrle	dd150
	move	a1,a11			;New high

dd150	move	*a4+,a1
	jrnn	#lp2			;Good offset?


	subk	16,a4			;A4=*Null end entry of line_t


	cmpi	200,a8
	jrge	#nextf			;Face off screen?
	cmpi	-200,a9
	jrle	#nextf			;Face off screen?


	move	a11,a0
	sub	a10,a11
	jreq	#nextf			;Height of 1?

	cmpi	254,a10
	jrge	#nextf			;Off screen bottom?
	cmpi	-400,a10
	jrle	#nextf			;Way off screen top?

	subi	253,a0
	jrle	dd300
	sub	a0,a11
dd300	addk	1,a11			;A11=Main loop cnt


	sll	16,a10			;A10=Dest Y:X

	move	a5,a6			;A6=*Rgt line line table
	subk	16,a6

	move	-*a5,a0			;Get offset
	add	a13,a0
	cmp	a14,a5
	jrhi	dd500			;!At start?
	move	a4,a5			;Put at end

dd500	move	*a6+,a1			;Get offset
	add	a13,a1
	cmp	a4,a6
	jrlo	dd550			;!Past end
	move	a14,a6			;Put at start
dd550
	move	*a0,a2,L
	move	*a1,a3,L
	move	a2,@linelsxy,L		;Needed???
	move	a3,@linersxy,L

	movk	1,b3			;B3=Y cntdn till end of left line
	movk	1,b4			;B4=Y cntdn till end of rgt line


	;A8 Free
	movi	[1,0],a8		;A8=Const 1:0

#linelp

	dsj	b3,dd750

dd700	move	-*a5,a0			;Get offset
	add	a13,a0
	cmp	a14,a5
	jrhi	dd720			;!At start?
	move	a4,a5			;Put at end
dd720
	move	*a0,a1,L
	move	@linelsxy,a2,L		;Start XY
	move	a1,@linelsxy,L
	subxy	a2,a1
	move	a1,a7
	jrn	#nextf			;Neg Y?
	srl	16,a1
	jrz	dd700			;Same Y?

	move	a1,b3			;New Y cnt
	sll	16,a7			;A7=Delta X
	divs	a1,a7			;Divide DeltaX into Y increments

	sll	16,a2			;A2=Left line X (16:16)


dd750	dsj	b4,dd850

dd800	move	*a6+,a0			;Get offset
	add	a13,a0
	cmp	a4,a6
	jrlo	dd820			;!Past end
	move	a14,a6			;Put at start
dd820
	move	*a0,a1,L
	move	@linersxy,a3,L		;Start XY
	move	a1,@linersxy,L
	subxy	a3,a1
	move	a1,a9
	jrn	#nextf			;Neg Y?
	srl	16,a1
	jrz	dd800			;Different Y?

dd840	move	a1,b4			;New Y cnt
	sll	16,a9			;A9=Delta X
	divs	a1,a9			;Divide DeltaX into Y increments

	sll	16,a3			;A3=Rgt line X (16:16)


dd850	add	a7,a2			;+Offset to left X
	add	a9,a3			;^ rgt X

	cmp	a3,a2
	jrgt	#nextf			;X flipped?

	move	a10,a10
	jrn	#nextl			;Off screen top?

	move	a2,a0
	sra	16,a0			;Int (0=Screen center)
	cmpi	200,a0
	jrge	#nextl			;L line to rgt of screen?
	addi	200,a0
	jrge	dd1000			;On screen?
	clr	a0
dd1000	movx	a0,a10			;X pos

	move	a3,a1			;>Calc HSize
	sra	16,a1			;Int
	addi	200,a1
	jrlt	#nextl			;R line to left of screen?
	sub	a0,a1			;Width

	add	a1,a0			;Rgt X
	subi	400,a0
	jrlt	dd1500			;On screen?
	subxy	a0,a1			;-difference

dd1500
;	move	a1,a0			;DEBUG chk VS:HS
;	srl	16,a0
;	jrnz	$
;	move	a1,a0
;	sll	16,a0
;	jrlt	$
	move	a1,b7
	addxy	b13,b7			;B7=VSIZE:HSIZE

	move	a10,b8
	addxy	b2,b8			;Add the page y offset

;	move	*b11,b0
;	jrnn	#dfree
;	addk	1,b14			;DEBUG

#dwait	move	*b11,b0
	jrn	#dwait			;DMA busy?


#dfree	mmtm	b12,b5,b6,b7,b8,b9,b10	;Set the dma regs
	addi	>c0,b12			;Fix DMAREGS


#nextl
	add	a8,a10			;Next Y
	dsj	a11,#linelp


#nextf	move	a4,a14
	addk	16,a14
	move	*a14,a0
	jrnn	#facelp			;Another set of lines?

	jruc	#lpobj


#x	PULL	b3,b4,b5,b6,b7,b8,b9,b10,b13,b14
	PULL	a4,a13,a14
	rets

	.endif


#*******************************
* Manual DMA
* A1=Constant color:Palette
* A2=Vsize:Hsize
* A3=Dest Y:X
* A4=SAG
* A5=Offset:Control
* Trashes A0,A14

QDMAN
;	movk	1,a0
;	move	a0,@QDMAFLG		;Q being modified

	move	@DMAQCUR,a14,L
	cmpi	DMAQ,a14
	jrls	#x			;Q full?

	movi	>1000100,a0		;No scale
	rl	16,a5			;Flip DMA & offset
	mmtm	a14,a0,a1,a2,a3,a4,a5
	rl	16,a5			;Flip DMA & offset
	move	a14,@DMAQCUR,L

#x
;	clr	a0
;	move	a0,@QDMAFLG
	rets


#*******************************
* Turn on the 2d with scaling display mode
* Trashes scratch

 SUBRP	display_2dsclmodeon

	movi	#drawcode,a0
	move	a0,@dcode_p,L
	movi	-1,a0
	move	a0,@dtype

	rets

#drawcode
	movi	BAKLST,a0
	callr	dma_objlst2d

	movi	OBJLST,a0
	jruc	dma_objlst2dscl


#*******************************
* Turn on the 2d, with scaling and stars, display mode
* Trashes scratch

	.asg	SCRATCH+8*128*1024,STARBUF
NSTARS	.equ	900
STARSIZE .equ	32*6+16

 SUBRP	display_2dsclstarmodeon

	movi	NSTARS,b0		;>Init star array
	movi	STARBUF,a1
	movi	-1,a0
#silp	move	a0,*a1,L		;X
	addi	STARSIZE,a1
	dsj	b0,#silp

	movi	#drawcode,a0
	move	a0,@dcode_p,L
	movi	-1,a0
	move	a0,@dtype

	rets

********************************
* B2=Y offset for top of page : XPad offset
* Trashes A0-A3,A5-A12,B0-B3

CFRAC	.equ	2

	.bss	starcolor	,16

#drawcode
	PUSH	a13,a14
	PUSH	b4

	movk	3,a0
	callr	rnd
	move	@starcolor,a6
	add	a0,a6
	move	a6,@starcolor
	sll	32-3-6,a6
	srl	32-3,a6			;Remove fraction
	sll	5+CFRAC,a6


	movi	NSTARS,a5		;>Find a free star
	movi	STARBUF,a2
	movk	3,a3
#flp	move	*a2,a0,L		;X
	jrn	#found
	addi	STARSIZE,a2
#fnxt	dsj	a5,#flp
	jruc	#nofree

#found	movi	[200,0],a0		;>Create star
	move	a0,*a2+,L		;X
	movi	[252,0],a0
	move	a0,*a2+,L		;Y

	clr	a0
	move	a0,*a2+,L		;XV
	movi	->3e000,a0
	move	a0,*a2+,L		;YV

	movi	>7ff,a0
	callr	rnd
	subi	>3ff,a0
	move	a0,*a2+,L		;XA
	movi	>3ff,a0
	callr	rnd
	addi	>7ff,a0
	move	a0,*a2+,L		;YA

	move	a6,*a2+			;Color type
	dsj	a3,#fnxt
#nofree

	movi	#star_p,a0		;>Update stars
	calla	pal_getf
	move	a0,@DMACMAP

	movi	512*8,b3
	lmo	b3,b0
	move	b0,@CONVDP
	clr	b4

	movi	1<<(32-5-CFRAC),a11
	movi	[400,0],a13		;A13=X max+1
	movi	[254,0],a14		;A14=Y max+1
	move	b2,a12
	movi	NSTARS,b0
	movi	STARBUF,a8
#lp
;	move	*a8+,a2,L		;X
;	move	*a8+,a3,L		;Y
;	move	*a8+,a5,L		;XV
;	move	*a8+,a6,L		;YV
;	move	*a8+,a9,L		;XA
;	move	*a8+,a10,L		;YA
	mmfm	a8,a2,a3,a5,a6,a9,a10	;YA,XA,YV,XV,Y,X
	move	*a8+,a1			;Color
	move	a10,a10
	jrn	#nxt

	add	a2,a5
	add	a3,a6
	add	a5,a9
	add	a6,a10
	cmp	a13,a10
	jrhs	#offscr			;X off screen?
	cmp	a14,a9
	jrlo	#plot			;Y on screen?
#offscr
	movi	-1,a0
	move	a0,*a8(-STARSIZE),L
	jruc	#nxt
#plot
	move	a10,*a8(-STARSIZE),L
	move	a9,*a8(-STARSIZE+32),L
	move	a6,*a8(-STARSIZE+32*2),L
	move	a5,*a8(-STARSIZE+32*3),L

	move	a1,a0
	sll	32-5-CFRAC,a0
	add	a11,a0
	jrc	#maxc			;Overflow?
;	cmpi	32*4,a1
;	jrge	#offscr
	addk	1,a1
	move	a1,*a8(-16)
#maxc	srl	CFRAC,a1		;Remove fraction
	srl	16,a10
	movx	a10,a9
	addxy	a12,a9
	pixt	a1,*a9.XY
#nxt
	dsj	b0,#lp

	PULL	b4
	PULL	a13,a14

	movi	BAKLST,a0
	callr	dma_objlst2d

	movi	OBJLST,a0
	jruc	dma_objlst2dscl

#star_p
	.word	256
	COLORW	01,01,01, 02,02,02, 03,03,03, 04,04,04	;Grey
	COLORW	05,05,05, 06,06,06, 07,07,07, 08,08,08
	COLORW	09,09,09, 10,10,10, 11,11,11, 12,12,12
	COLORW	13,13,13, 14,14,14, 15,15,15, 16,16,16
	COLORW	17,17,17, 18,18,18, 19,19,19, 20,20,20
	COLORW	21,21,21, 22,22,22, 23,23,23, 24,24,24
	COLORW	25,25,25, 26,26,26, 27,27,27, 28,28,28
	COLORW	29,29,29, 30,30,30, 31,31,31, 31,31,31
	COLORW	01,01,00, 02,02,00, 03,03,00, 04,04,00	;Yellow
	COLORW	05,05,00, 06,06,00, 07,07,00, 08,08,00
	COLORW	09,09,00, 10,10,00, 11,11,00, 12,12,00
	COLORW	13,13,00, 14,14,00, 15,15,00, 16,16,00
	COLORW	17,17,00, 18,18,00, 19,19,00, 20,20,00
	COLORW	21,21,00, 22,22,00, 23,23,00, 24,24,00
	COLORW	25,25,00, 26,26,00, 27,27,00, 28,28,00
	COLORW	29,29,00, 30,30,00, 31,31,00, 31,31,00
	COLORW	01,00,00, 02,00,00, 03,00,00, 04,00,00	;Red
	COLORW	05,00,00, 06,00,00, 07,00,00, 08,00,00
	COLORW	09,00,00, 10,00,00, 11,00,00, 12,00,00
	COLORW	13,00,00, 14,00,00, 15,00,00, 16,00,00
	COLORW	17,00,00, 18,00,00, 19,00,00, 20,00,00
	COLORW	21,00,00, 22,00,00, 23,00,00, 24,00,00
	COLORW	25,00,00, 26,00,00, 27,00,00, 28,00,00
	COLORW	29,00,00, 30,00,00, 31,00,00, 31,00,00
	COLORW	00,01,00, 00,02,00, 00,03,00, 00,04,00	;Green
	COLORW	00,05,00, 00,06,00, 00,07,00, 00,08,00
	COLORW	00,09,00, 00,10,00, 00,11,00, 00,12,00
	COLORW	00,13,00, 00,14,00, 00,15,00, 00,16,00
	COLORW	00,17,00, 00,18,00, 00,19,00, 00,20,00
	COLORW	00,21,00, 00,22,00, 00,23,00, 00,24,00
	COLORW	00,25,00, 00,26,00, 00,27,00, 00,28,00
	COLORW	00,29,00, 00,30,00, 00,31,00, 00,31,00
	COLORW	00,00,01, 00,00,02, 00,00,03, 00,00,04	;Blue
	COLORW	00,00,05, 00,00,06, 00,00,07, 00,00,08
	COLORW	00,00,09, 00,00,10, 00,00,11, 00,00,12
	COLORW	00,00,13, 00,00,14, 00,00,15, 00,00,16
	COLORW	00,00,17, 00,00,18, 00,00,19, 00,00,20
	COLORW	00,00,21, 00,00,22, 00,00,23, 00,00,24
	COLORW	00,00,25, 00,00,26, 00,00,27, 00,00,28
	COLORW	00,00,29, 00,00,30, 00,00,31, 00,00,31
	COLORW	00,00,01, 00,00,02, 00,00,03, 00,00,04	;Lt blue
	COLORW	00,00,05, 00,00,06, 00,00,07, 00,00,08
	COLORW	00,00,09, 01,01,10, 02,02,11, 03,03,12
	COLORW	04,04,13, 05,05,14, 06,06,15, 07,07,16
	COLORW	08,08,17, 09,09,18, 10,10,19, 11,11,20
	COLORW	12,12,21, 14,14,22, 16,16,23, 18,18,24
	COLORW	20,20,25, 22,22,26, 24,24,27, 26,26,28
	COLORW	28,28,29, 30,30,30, 30,30,31, 31,31,31
	COLORW	01,00,01, 02,00,02, 03,00,03, 04,00,04	;Purple
	COLORW	05,00,05, 06,00,06, 07,00,07, 08,00,08
	COLORW	09,00,09, 10,00,10, 11,00,11, 12,00,12
	COLORW	13,00,13, 14,00,14, 15,00,15, 16,00,16
	COLORW	17,00,17, 18,00,18, 19,00,19, 20,00,20
	COLORW	21,00,21, 22,00,22, 23,00,23, 24,00,24
	COLORW	25,00,25, 26,00,26, 27,00,27, 28,00,28
	COLORW	29,00,29, 30,00,30, 31,00,31, 31,00,31
	COLORW	00,01,01, 00,02,02, 00,03,03, 00,04,04	;Cyan
	COLORW	00,05,05, 00,06,06, 00,07,07, 00,08,08
	COLORW	00,09,09, 00,10,10, 00,11,11, 00,12,12
	COLORW	00,13,13, 00,14,14, 00,15,15, 00,16,16
	COLORW	00,17,17, 00,18,18, 00,19,19, 00,20,20
	COLORW	00,21,21, 00,22,22, 00,23,23, 00,24,24
	COLORW	00,25,25, 00,26,26, 00,27,27, 00,28,28
	COLORW	00,29,29, 00,30,30, 00,31,31, 00,31,31


********************************
* Get random # with mask
* A0=Mask
* >A0=Rnd # (Pass CC)
* Trashes scratch

 SUBRP	rnd

	move	@RAND,a1,L
	rl	a1,a1
	move	@HCOUNT,a14
	rl	a14,a1
	add	sp,a1
	move	a1,@RAND,L

	and	a1,a0
	rets


********************************
* Zeros velocities for all objects on OBJLST

STOPOBJS
	clr	a0
	movi	OBJLST,a1
	jruc	so20

so10	move	a0,*a1(OXVEL),L
	move	a0,*a1(OYVEL),L
	move	a0,*a1(OZVEL),L
so20	move	*a1,a1,L
	jrnz	so10

	rets


********************************
* Sort object list in Z:Y priority
* Trashes A0-A7

	.align

 SUBR	obj_yzsort

	movi	OBJLST,a0
	movk	1,a1			;Lowest Z
	sll	31,a1			;Make >80000000
	jruc	yzlp

yz0	move	*a2(OZPOS),a6		;Get Z
	move	*a2(OYPOS),a7		;Get Y
	cmp	a1,a6
	jrgt	priok			;Next Z > Current Z?
	jrlt	priswap

	cmp	a5,a7
	jrge	priok			;Next Y > Current Y?

priswap	dint				;>Make current after next
	move	a2,*a4,L		;Point last to next
	move	*a2,*a0,L		;Point current to block after next
	move	a0,*a2,L		;Point next to current
	eint
	move	a2,a4
	jruc	yzlp			;Continue sort of current obj

priok	move	a0,a4			;A4=*Last obj
	move	a2,a0			;A0=*Current obj
	move	a6,a1			;A1=Current Z
	move	a7,a5			;A5=Current Y

yzlp	move	*a0,a2,L		;A2=*Next obj
	jrnz	yz0

	rets


**************************************************************************
* TEST IF OBJECT ON SCREEN
* A8=OBJECT
* RETURNS Z IF ON SCREEN

*ENTER HERE AND PROVIDE YOUR OWN SCREEN BOUNDRIES
SCRTSTG
	mmtm	sp,a1,a2,a3
	jruc	scrtst1

*NORMAL SCREEN BOUNDRIES
SCRTST
	mmtm	sp,a1,a2,a3
	move	@SCRNTL,a2,L		;Get screen top left
	move	@SCRNLR,a3,L		;Get screen lower rgt

scrtst1	move	*a8(OYPOS),a0
	move	*a8(OXPOS),a1
	sll	16,a0
	movx	a1,a0			;get top left of object
	move	@WORLDTL,a1,L
	subxy	a1,a0			;subtract out world base
	move	*a8(OSIZE),a1,L
	addxy	a0,a1			;get lower rt of object

	cmpxy	a3,a0			;is it lower than lower rt?
	JRYGE	scrtf_d			;lower
	JRXGE	scrtf_r			;to the right

	cmpxy	a2,a1
	JRYLE	scrtf_u			;above...
	JRXLE	scrtf_l			;to the left..

	mmfm	sp,a1,a2,a3
	clr	a0			;On screen Z
	rets
scrtf_l	movi	1,a0			;Pass NZ
	mmfm	sp,a1,a2,a3
	rets

scrtf_r	movi	2,a0
	mmfm	sp,a1,a2,a3
	rets

scrtf_u	movi	3,a0
	mmfm	sp,a1,a2,a3
	rets

scrtf_d	movi	4,a0
	mmfm	sp,a1,a2,a3
	rets



#*******************************
* Initialize display system
* Trashes scratch

 SUBR	display_init

	pushst
	dint
	movi	DIE+X2E,a0
	move	a0,@INTENB		;Display int on, DMA int off

	clr	a0
	move	a0,@DMACTRL		;>Init DMA
	move	a0,@DMACTRL
	move	a0,@CMAPSEL		;Clear color map select
	move	a0,@DMATEST
	move	a0,@DMACONF
	movi	[511,0],a1		;L/R (full width to fix glitch)
	move	a1,@DMAWINDOW,L
	movi	>30,a1
	move	a1,@DMACONF		;Top/Bottom
	movi	[509,0],a1
	move	a1,@DMAWINDOW,L
	movi	>1000100,a1
	move	a1,@DMASCALEX,L

	movi	-1,b13			;DMAQ cnt

	clr	a1			;>Clr video mem
	movi	(SCRNE-512*8*2)/64,b0
#clp	move	a0,*a1+,L
	move	a0,*a1+,L
	dsj	b0,#clp
					;>Set autoerase lines
	movi	510*512*8,a1		;Store to last 2 lines of bitmap
	movi	ERASECOL,a14		;Color pair
	movi	512*8*2/16,b0
#lp	move	a14,*a1+
	dsj	b0,#lp


	movi	SCRNST,a1		;Screen top left [Y,X]
	move	a1,@SCRNTL,L
	movi	SCRNEND,a1		;Screen lower right [Y,X]
	move	a1,@SCRNLR,L

	move	a0,@WORLDTLX,L
	move	a0,@WORLDTLY,L
	move	a0,@WORLDTL,L
	move	a0,@SCROLLX,L
	move	a0,@SCROLLY,L

	move	a0,@BAKLST,L		;Null backgnd object list
	move	a0,@OBJLST,L		;Null object list

	move	a0,@dcode_p,L

	movi	DMAQ+QMSIZE,a1
	move	a1,@DMAQCUR,L		;Init misc DMA queue

	movi	OBJSTR,a1,L		;>Init free list
	move	a1,@OFREE,L
	movi	NOBJ,b0			;# of object blocks

#olp	move	a1,a14
	addi	OBSIZ,a1
	move	a1,*a14,L		;link em up
	dsj	b0,#olp

	move	a0,*a14,L		;Null end

	popst

	rets


********************************
* Get a free object block
* Trashes scratch
* >A0=*Object or 0 (Z)

GETOBJ
	move	@OFREE,a0,L
	jrz	nonelft			;None free?

	move	*a0,a1,L
	move	a1,@OFREE,L		;Unlink
	clr	a1
	move	a1,*a0(OPLINK),L
	move	a1,*a0(ODATA_p),L
getox
	move	a0,a0
	rets

nonelft
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	3,0
	.endif
	jruc	getox


********************************
* Add object to free list
* Can trash A0-A1 (currently doesn't)

FREEOBJ
	move	@OFREE,*a0+,L
	subk	32,a0
	move	a0,@OFREE,L
	rets


#*******************************
* Unlink an object from object list
* A0=*Obj
* Trashes scratch

; SUBR	obj_unlink
;
;	movi	OBJLST,a14
;
;#lp	move	a14,a1		;A1=*Prev
;	move	*a14,a14,L	;A14=*Next
;	jrz	#err
;	cmp	a14,a0
;	jrne	#lp
;
;	move	*a0,*a1,L	;Unlink from obj list
;	rets
;
;#err
;	.if	DEBUG
;	LOCKUP
;	eint
;	.endif
;	rets


********************************
* Insert an object block into an object list
* List is sorted by increasing z and increasing y within constant z


#*******************************
* Insert background object
* A0=*Obj
* Trashes scratch

INSBOBJ
	movi	BAKLST,a14
	jruc	#strt

********************************
* Insert foreground object
* A0=*Obj
* Trashes scratch

INSOBJ

	movi	OBJLST,a14

#strt	PUSH	a2,a3,a4

	move	*a0(OZPOS),a1
	move	*a0(OYPOS),a4
#lp
	move	a14,a2			;A2=*prev
	move	*a14,a14,L		;A14=*next
	jrz	#x
	move	*a14(OZPOS),a3
	cmp	a3,a1
	jrgt	#lp
	jrlt	#x

	move	*a14(OYPOS),a3		;Test y position
	cmp	a3,a4
	jrgt	#lp


#x	move	a14,*a0,L		;Put *next in new block
	move	a0,*a2,L		;Put *new in prev block

	PULL	a2,a3,a4
	rets


#*******************************
* Delete background object
* A0=*Obj

DELBOBJ

	movi	BAKLST,a14
	jruc	#lp


********************************
* Delete foreground object
* A8=*Obj

DELOBJA8

	move	a8,a0

********************************
* Delete foreground object
* A0=*Obj
* Trashes scratch

DELOBJ
	movi	OBJLST,a14

#lp	move	a14,a1		;A1=*Prev
	move	*a14,a14,L	;A14=*Next
	jrz	delerr
	cmp	a14,a0
	jrne	#lp

	move	*a0,*a1,L	;Unlink from obj list

	clr	a1
	move	a1,*a0(OXPOS)	;Indicates not in use for collisions

	move	@OFREE,*a0+,L	;Add to free list
	subk	32,a0
	move	a0,@OFREE,L

#x	rets

delerr
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	1,0
	.endif
	jruc	#x



********************************
* FRANIM list an object, delete it and DIE
* A8=*Obj
* A9=*FRANIM list

FRQDELDIE

	JSRP	FRANIMQ

#*******************************
* Delete foreground object and DIE
* A8=*Obj

DELOBJDIE

	movi	OBJLST,a14

#lp	move	a14,a1		;A1=*Prev
	move	*a14,a14,L	;A14=*Next
	jrz	doderr
	cmp	a14,a8
	jrne	#lp

	move	*a8,*a1,L	;Unlink from obj list

	clr	a1
	move	a1,*a8(OXPOS)	;Indicates not in use for collisions

	move	@OFREE,*a8+,L	;Add to free list
	subk	32,a8
	move	a8,@OFREE,L

#x	jauc	SUCIDE

doderr
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	1,0
	.endif
	jruc	#x



#*******************************
* Delete one class from the obj list
* A0=OID
* Trashes scratch

obj_del1c

	clr	a1

********************************
* Delete a class from the obj list
* A0=OID
* A1=!Mask (Bits to remove)
* Trashes scratch

obj_delc
	move	a2,b0
	move	a3,b1

	movi	OBJLST,a14
	sext	a0
	andn	a1,a0		;Form match

#lp	move	a14,a3		;A3=*Prev
	move	*a14,a14,L	;A14=*Next
	jrz	#x
#cmp	move	*a14(OID),a2
	andn	a1,a2		;Mask
	cmp	a0,a2
	jrne	#lp

	move	*a14,*a3,L	;Unlink from obj list

	move	@OFREE,*a14+,L	;Add to free list
	subk	32,a14
	move	a14,@OFREE,L
	move	*a3,a14,L
	jrnz	#cmp

#x
	move	b1,a3
	move	b0,a2
	rets



#*******************************
* Check objlst for an object with a certain OID
* A0=OID
* A1=!Mask (Bits to remove)
* >A0=*Obj or 0 (Z)
* Trashes scratch

EXISTOBJ
	move	a2,b0

	movi	OBJLST,a14
	sext	a0
	andn	a1,a0		;Form match
#lp
	move	*a14,a14,L
	jrz	#x
	move	*a14(OID),a2
	andn	a1,a2		;Mask
	cmp	a0,a2
	jrne	#lp

#x	move	b0,a2
	move	a14,a0
	rets


#*******************************
* Check if object on free list
* A0=*Obj
* >A0=*Obj or 0 (Z)
* Trashes scratch

;ISFREE
;	movi	OFREE,a1
;	jruc	#lp


********************************
* Check if object on OBJLST
* A0=*Obj
* >A0=*Obj or 0 (Z)
* Trashes scratch

ISOBJ
	movi	OBJLST,a1

#lp	move	*a1,a1,L
	jrz	#x		;End?
	cmp	a0,a1
	jrne	#lp		;No match?

	move	a0,a0		;Clr Z
	rets

#x	clr	a0		;Set Z
	rets


********************************
* Add world coordinates to an object
* A0=*Obj
* Trashes scratch, !A0

 SUBR	obj_addworldxy

	move	@WORLDTLX,a14,L
	move	*a0(OXVAL),a1,L
	add	a14,a1
	move	a1,*a0(OXVAL),L

	move	@WORLDTLY,a14,L
	move	*a0(OYVAL),a1,L
	add	a14,a1
	move	a1,*a0(OYVAL),L

	rets


**************************************************************************
*									 *
* ADJNEWTL - ADJUST AN OBJECT TO A NEW SET OF X,Y WORLD COORDINATES	 *
*	   BEFORE THEY ARE STORED(TAKE EFFECT).				 *
* NOTE: CURRENT OBJECT COORDS. MUST BE ABSOLUTE WORLD.			 *
* A0 = PTR TO OBJECT							 *
* A4 = NEW WTLX, 32 BITS						 *
* A5 = NEW WTLY, 32 BITS						 *

ADJNEWTL
	PUSH	a1,a2
	CALLR	GSCRNREL		;SCREEN RELATIVE PLEASE
	ADD	A4,A1
	ADD	A5,A2			;ADJUST
	MOVE	A1,*A0(OXVAL),L
	MOVE	A2,*A0(OYVAL),L		;STORE
	PULL	a1,a2
	RETS


**************************************************************************
*									 *
* GSCRNREL - GET THE SCREEN RELATIVE X,Y COORDINATES OF AN OBJECT	 *
*	   IT IS ASSUMED THATE THE CURRENT X,Y COORDINATES ARE		 *
*	   WORLD ABSOLUTE.						 *
* A0 = PTR TO THE OBJECT BLOCK						 *
* RETURNS								 *
* A1 = X SCREEN RELATIVE, 32 BITS					 *
* A2 = Y SCREEN RELATIVE, 32 BITS					 *

GSCRNREL
	PUSH	a5
	MOVE	@WORLDTLX,A5,L
	MOVE	*A0(OXVAL),A1,L
	SUB	A5,A1
	MOVE	@WORLDTLY,A5,L
	MOVE	*A0(OYVAL),A2,L
	SUB	A5,A2
	PULL	a5
	RETS


**************************************************************************
*									 *
* SCRNRELV - MAKE THE X & Y VELOCITIES OF AN OBJECT RELATIVE TO THE	 *
*	   SCREEN. IN OTHER WORDS, ADJUST THEM SO THAT THE CURRENT	 *
*	   SCROLL RATE DOESN'T AFFECT THEM. 				 *
* A0 = PTR TO OBJECT							 *
*									 *
**************************************************************************

SCRNRELV
	PUSH	a1,a5
	MOVE	@SCROLLX,A5,L
	MOVE	*A0(OXVEL),A1,L
	ADD	A5,A1
	MOVE	A1,*A0(OXVEL),L
	MOVE	@SCROLLY,A5,L
	MOVE	*A0(OYVEL),A1,L
	ADD	A5,A1
	MOVE	A1,*A0(OYVEL),L
	PULL	a1,a5
	RETS


********************************
* Adjust current object image with respect to it's anipt and flip flags
* A0=*Object
* A2=New YVAL
* A3=New XVAL
* A4=New FLAGS (Only DMA bits)
* Trashes A1,A14,B0-B1
* >A2=Adjusted YVAL
* >A3=Adjusted XVAL

GANISAG
	PUSH	a4,a6,a7

	PUSH	a2
	move	*a0(OIMG),a1,L
	move	*a1,a2,L		;ISIZE
	move	a2,*a0(OSIZE),L
	callr	GANIOF
	PULL	a2

	sub	a6,a3
	sub	a7,a2			;adjust upper left corner
	move	a3,*a0(OXVAL),L
	move	a2,*a0(OYVAL),L

	move	*a1(ICTRL),a1		;Get DMA flags
	andi	>803f,a4		;Kill mode bits
	or	a1,a4
	move	a4,*a0(OCTRL),L		;&OFFSET

	PULL	a4,a6,a7
	rets


********************************
* Begin an object
* A0=XVAL, A1=YVAL, A2=*IMG, A3=ZPOS, A4=FLAGS, A5=OID, A6=XVEL, A7=YVEL
* >A8=*Obj
* Trashes scratch

BEGINOBJ
	move	@WORLDTLX,a8,L		;Adjust for world coord
	add	a8,a0
	btst	B_3D,a4
	jrnz	BEGINOBJ2		;No Y add for 3D?
	move	@WORLDTLY,a8,L
	add	a8,a1

BEGINOBJ2
	PUSH	a2,a3,a4,a6,a7,a9,a10
	move	a0,a9			;X
	move	a1,a10			;Y

	move	*a2(ICMAP),a0,L		;Get *palette
	.if	DEBUG
	jrnn	bopalerr		;No pallette?
	.endif
	calla	pal_getf

bo20	move	@OFREE,a8,L		;Pointer to next available obj block
	jrz	begobjerr		;No objs?
	move	*a8,a1,L
	move	a1,@OFREE,L		;Adjust pointer to free list

	move	a0,*a8(OPAL),L		;Set pallette & constant
	clr	a0
	move	a0,*a8(ODATA_p),L	;Clr stuff
	move	a0,*a8(OXANI),L
	move	a0,*a8(OZVEL),L
	move	a0,*a8(OMISC)

	move	a3,*a8(OZPOS)
	move	a5,*a8(OID)
	move	a6,*a8(OXVEL),L
	move	a7,*a8(OYVEL),L

	move	a2,a1			;*Img
	move	*a1,a2,L		;ISIZE
	callr	GANIOF			;Adjust animation offset
	move	*a1(ISAG),a3,L		;Get top left sag

	sub	a6,a9			;- x anioff
	sub	a7,a10			;- y anioff
	move	a9,*a8(OXVAL),L
	move	a10,*a8(OYVAL),L

	move	a1,*a8(OIMG),L
	move	a2,*a8(OSIZE),L
	move	a3,*a8(OSAG),L
	move	a4,*a8(OFLAGS)
	move	*a1(ICTRL),a0		;Get DMA flags
	andi	>803f,a4		;Kill mode bits
	or	a0,a4
	move	a4,*a8(OCTRL),L		;&OFSET

	PULL	a2,a3,a4,a6,a7,a9,a10

	move	a13,*a8(OPLINK),L
	move	a8,a0
	jruc	INSOBJ			;Insert object into list


	.if	DEBUG
bopalerr
	LOCKUP				;Object doesn't have pallette!
	eint
	clr	a0
	jruc	bo20
	.endif

begobjerr
	.if	DEBUG
	LOCKUP				;Out of objects!
	eint
	.else
	CALLERR	3,7
	.endif
	move	@OBJLST,a8,L		;Pass 1st obj on list
	PULL	a2,a3,a4,a6,a7,a9,a10
	rets



#*******************************
* Begin an object with specified palette
* A0=XVAL, A1=YVAL, A2=*IMG, A3=ZPOS, A4=FLAGS, A5=OID, A6=XVEL, A7=YVEL
* B0=*Palette
* >A8=*Obj
* Trashes scratch

BEGINOBJP
	move	@WORLDTLX,a8,L		;Adjust for world coord
	add	a8,a0
	btst	B_3D,a4
	jrnz	BEGINOBJP2		;No Y add for 3D?
	move	@WORLDTLY,a8,L
	add	a8,a1

BEGINOBJP2
	PUSH	a2,a3,a4,a6,a7,a9,a10
	move	a0,a9			;X
	move	a1,a10			;Y

	move	b0,a0			;Get *palette
	.if	DEBUG
	jrnn	#bopalerr		;No pallette?
	.endif
	calla	pal_getf

#bo20	move	@OFREE,a8,L		;Pointer to next available obj block
	jrz	begobjerr		;No objs?
	move	*a8,a1,L
	move	a1,@OFREE,L		;Adjust pointer to free list

	move	a0,*a8(OPAL),L		;Set pallette & constant
	clr	a0
	move	a0,*a8(ODATA_p),L	;Clr stuff
	move	a0,*a8(OXANI),L
	move	a0,*a8(OZVEL),L
	move	a0,*a8(OMISC)

	move	a3,*a8(OZPOS)
	move	a5,*a8(OID)
	move	a6,*a8(OXVEL),L
	move	a7,*a8(OYVEL),L

	move	a2,a1			;*Img
	move	*a1,a2,L		;ISIZE
	callr	GANIOF			;Adjust animation offset
	move	*a1(ISAG),a3,L		;Get top left sag

	sub	a6,a9			;- x anioff
	sub	a7,a10			;- y anioff
	move	a9,*a8(OXVAL),L
	move	a10,*a8(OYVAL),L

	move	a1,*a8(OIMG),L
	move	a2,*a8(OSIZE),L
	move	a3,*a8(OSAG),L
	move	a4,*a8(OFLAGS)
	move	*a1(ICTRL),a0		;Get DMA flags
	andi	>803f,a4		;Kill mode bits
	or	a0,a4
	move	a4,*a8(OCTRL),L		;&OFSET

	PULL	a2,a3,a4,a6,a7,a9,a10

	move	a13,*a8(OPLINK),L
	move	a8,a0
	jruc	INSOBJ			;Insert object into list


	.if	DEBUG
#bopalerr
	LOCKUP				;Object doesn't have pallette!
	eint
	clr	a0
	jruc	#bo20
	.endif


#*******************************
* Set new image for an object
* A1=*Image hdr
* A4=New FLAGS
* A8=*Obj
* Trashes A1,A14

 SUBR	ANI

	PUSH	a0,a2,a3,a4,a5,a6,a7

	cmpi	ROM,a1
	jrlo	anierr

	move	a1,a3
	move	a4,a5
	move	*a8(OIMG),a1,L
	move	*a8(OCTRL),a4
	cmp	a1,a3
	jrne	#1			;Different img?

	sext	a5
	cmp	a4,a5
	jreq	#x			;All the same?

#1	move	*a8(OSIZE),a2,L
	callr	GANIOF			;Get old animation offset
	move	a3,a1			;New OIMG
	srl	6,a4
	sll	6,a4
	or	a5,a4			;Set new OCTRL
	move	a6,a0
	move	a7,a5
	move	*a1(ISAG),a3,L		;Get top left sag
	move	*a1,a2,L		;ISIZE
	callr	GANIOF			;Get new animation offset
	move	a1,*a8(OIMG),L
	sub	a6,a0			;Subtract new from old
	sub	a7,a5
	zext	a4			;Zero offset in A4

	move	a8,a6			;Get push address of octrl,osag,osize
	addi	OCTRL+>60,a6
	mmtm	a6,a2,a3,a4		;Save new data

	subi	OCTRL-OXVAL,a6
	move	*a6,a7,L		;New OXVAL
	add	a0,a7
	move	a7,*a6+,L
	move	*a6,a7,L		;New OYVAL
	add	a5,a7
	move	a7,*a6,L

#x	PULL	a0,a2,a3,a4,a5,a6,a7
	rets

anierr
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	2,7
	.endif
	jruc	#x


#*******************************
* Change an objects image (Doesn't check VFLIP)
* A0=*New image
* A1=New flip flags & const
* A8=*Obj
* Trashes scratch

 SUBRP	obj_aniq


	PUSH	a2,a3

	cmpi	ROM,a0
	jrlo	#anierr

	move	a0,a2
	move	a1,a3

	callr	anipt_getxy

	move	a2,*a8(OIMG),L
	move	*a2(0),*a8(OSIZE),L
	move	*a2(ISAG),*a8(OSAG),L

	setf	5,0,0
	move	*a2(ICTRL+7),*a8(OCTRL+7) ;Write 5 z comp bits
	setf	6,0,0
	move	a3,*a8(OCTRL)		;Write 6 low bits
	setf	16,1,0

	move	a0,a2
	move	a1,a3
	callr	anipt_getxy

	sub	a0,a2			;Subtract new from old
	sub	a1,a3

	move	a8,a0			;Get base address
	addi	OXVAL,a0
	move	*a0,a14,L		;New OXVAL
	add	a2,a14
	move	a14,*a0+,L
	move	*a0,a14,L		;New OYVAL
	add	a3,a14
	move	a14,*a0,L

#x	PULL	a2,a3
	rets

#anierr 
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	2,2
	.endif
	jruc	#x


#*******************************
* Get an objects anipt XY (Doesn't check VFLIP)
* A8=*Obj
* >A0=Scaled Ani X (16:16)
* >A1=Scaled Ani Y
* Trashes scratch

 SUBRP	anipt_getxy

	move	a2,b0

	move	*a8(OIMG),a2,L

	move	*a2(IANIOFFX),a0
	sll	16,a0
	move	*a2(IANIOFFY),a1
	sll	16,a1

	move	*a8(OCTRL),a14
	btst	B_FLIPH,a14
	jrz	#x			;No flip?

	move	*a2,a2			;ISIZEX
	subk	1,a2
	sll	16,a2			;*64K
	neg	a0
	add	a2,a0			;+size


#x	move	b0,a2
	rets



#*******************************
* Change an objects image (doesn't check flip flags)
* A0=*New image
* A1=New OCTRL
* A8=*Obj
* Trashes scratch

 SUBRP	obj_aniq_cnoff

	move	a2,b0

	move	a1,*a8(OCTRL)		;Write new ctrl

	move	*a8(OIMG),a14,L
	move	*a14(IANIOFFX),a2
	move	*a14(IANIOFFY),a14

	move	a0,*a8(OIMG),L
	move	*a0(0),*a8(OSIZE),L
	move	*a0(ISAG),*a8(OSAG),L

	move	*a0(IANIOFFY),a1
	move	*a0(IANIOFFX),a0

	sub	a0,a2			;Subtract new from old
	sub	a1,a14
	sll	16,a2
	sll	16,a14

	move	a8,a0			;Get base address
	addi	OXVAL,a0
	move	*a0,a1,L		;New OXVAL
	add	a2,a1
	move	a1,*a0+,L
	move	*a0,a1,L		;New OYVAL
	add	a14,a1
	move	a1,*a0,L

	move	b0,a2
	rets



#*******************************
* Change an scaled objects image (Doesn't check VFLIP)
* A0=*New image
* A1=New OCTRL (low 8 bits)
* A8=*Obj
* Trashes scratch, A2,A3

	.ref	anipt_getsclxy

 SUBRP	obj_aniq_scld


	cmpi	ROM,a0
	jrlo	#anierr

	move	a0,a2
	move	a1,a3

	calla	anipt_getsclxy

	movb	a3,*a8(OCTRL)

	move	a2,*a8(OIMG),L
	move	*a2(0),*a8(OSIZE),L
	move	*a2(ISAG),*a8(OSAG),L

	move	a0,a2
	move	a1,a3
	calla	anipt_getsclxy

	sub	a0,a2			;Subtract new from old
	sub	a1,a3

	move	a0,*a8(OXANI),L		;Save scaled anipt

	move	a8,a0			;Get base address
	addi	OXVAL,a0
	move	*a0,a14,L		;New OXVAL
	add	a2,a14
	move	a14,*a0+,L
	move	*a0,a14,L		;New OYVAL
	add	a3,a14
	move	a14,*a0,L

#x	rets


#anierr 
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	2,0
	.endif
	jruc	#x



********************************
* Get the x and y positions of an objects animation point
* A8=*Object
* Trashes scratch
* >A2=Ani pt Y 16:16
* >A3=Ani pt X 16:16

GETANIXY
	PUSH	a4,a6,a7
	move	*a8(OIMG),a1,L
	move	*a8(OSIZE),a2,L
	move	*a8(OCTRL),a4
	callr	GANIOF
	move	*a8(OXVAL),a3,L
	move	*a8(OYVAL),a2,L
	add	a6,a3
	add	a7,a2
	PULL	a4,a6,a7
	rets


#********************************
* Get animation offset (Fast!)
* A1=*Image header, A2=H:W, A4=OCTRL
* Trashes A14
*Rets:
* A6=X ani offset * 64K
* A7=Y ani offset * 64K

GANIOF
	move	*a1(IANIOFF),a6,L
	cmpi	IROM,a6
	jrge	#err

#h	clr	a7
	movy	a6,a7
	sll	16,a6		;Move to upper word

	btst	B_FLIPH,a4
	jrz	#v
	move	a2,a14
	subk	1,a14
	sll	16,a14		;Move W to upper word
	neg	a6
	add	a14,a6		;Sub Width-1

#v	btst	B_FLIPV,a4
	jrz	#x
	move	a2,a14
	neg	a7
	srl	16,a14
	subk	1,a14
	sll	16,a14
	add	a14,a7		;Sub Hgt-1

#x	rets

#err	clr	a6
	jruc	#h


#*******************************
* Scale screen out (JSRP)

	.asg	SCRATCH+8*256*1024,SCRNBUF
	.asg	SCRNBUF+8*128*1024,PALBUF

	.bss	scrnscl		,16

 SUBR	scrn_scaleout

	movk	1,a0
	move	a0,@HALT

	move	@dtype,a0
	PUSHP	a0
	move	@gndstat,a0
	PUSHP	a0

	movi	>160,a0
	move	a0,@scrnscl

	movi	#initcode,a0
	move	a0,@dcode_p,L

	movi	-1,a0
	move	a0,@dtype
	clr	a0
	move	a0,@gndstat
	move	a0,@IRQSKYE

#lp	SLEEPK	1

	movi	scrnscl,a14
	move	*a14,a5
	move	a5,a0
	srl	3,a0
	add	a0,a5
	move	a5,*a14
	cmpi	>7000,a5
	jrlt	#lp

	clr	a0
	move	a0,@dcode_p,L

	PULLP	a0
	move	a0,@gndstat
	PULLP	a0
	move	a0,@dtype


	RETP

#initcode
	callr	scrn_copy
	movi	scrn_scale,a0
	move	a0,@dcode_p,L
	jump	a0


#*******************************
* Initialization for scrn_scalein (JSRP)

 SUBR	scrn_scaleininit

	dint
#lp	move	@VCOUNT,a0
	cmpi	EOSINT,a0
	jrlt	#lp
	move	@HSBLNK,a0	;Blank screen
	move	a0,@HEBLNK
	eint
	SLEEPK	2

	RETP

#*******************************
* Scale screen in (JSRP)

 SUBR	scrn_scalein

	PUSHP	a8

	move	@HALT,a0
	PUSHP	a0
	movk	1,a0
	move	a0,@HALT

	move	@dtype,a0
	PUSHP	a0
	move	@gndstat,a0
	PUSHP	a0
	move	@dcode_p,a0,L
	PUSHP	a0

	movi	>7000,a0
	move	a0,@scrnscl

	movi	#initcode,a0
	move	a0,@dcode_p,L
	movi	-1,a0
	move	a0,@dtype
	clr	a0
	move	a0,@gndstat


	.if	DEBUG
;	movi	>1a0,a0
;	move	a0,@scrnscl
;	SLEEP	TSEC*2
	.endif


#lp	SLEEPK	1

	movi	scrnscl,a14
	move	*a14,a5
	move	a5,a0
	srl	2,a0
	sub	a0,a5
	move	a5,*a14
	cmpi	>100,a5
	jrgt	#lp


	PULLP	a0
	move	a0,@dcode_p,L
	PULLP	a0
	move	a0,@gndstat
	PULLP	a0
	move	a0,@dtype

	PULLP	a0
	move	a0,@HALT


	PULLP	a8
	RETP


#initcode
	callr	scrn_copy
	movi	scrn_scaledison,a0
	move	a0,@dcode_p,L
	jruc	scrn_scale


#*******************************
* B2=Y offset for top of page : XPad offset
* Trashes A0-A3,A7

 SUBRP	scrn_copy

	move	b2,a0
	srl	16,a0
	xori	>100,a0			;Flip to the page being shown
	sll	12,a0			;*512*8
	addi	SCRNXP*8,a0		;A0=*Scrn mem
	PUSH	a0

	movi	SCRNBUF,a1
	movi	254,a3
	movi	(512-400)*8,a7
#cslp
	movi	400/16,a2
#cslp2	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	dsj	a2,#cslp2

	add	a7,a0
	add	a7,a1
	dsj	a3,#cslp

	move	@SYSCOPY,a0
	andni	100000b,a0
	move	a0,@SYSCOPY
	.if	DEBUG
	andni	1000000b,a0
	.endif
	move	a0,@SYSCTRL

	PULL	a0
	movi	PALBUF,a1
	movi	254,a3
#cplp
	movi	400/16,a2
#cplp2	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	move	*a0+,*a1+,L
	dsj	a2,#cplp2

	add	a7,a0
	add	a7,a1
	dsj	a3,#cplp

	move	@SYSCOPY,a0
	ori	100000b,a0
	move	a0,@SYSCOPY
	.if	DEBUG
	andni	1000000b,a0
	.endif
	move	a0,@SYSCTRL

	rets


#*******************************
* Copy screen data (throw out 1 in 5 pixels)
* B2=Y offset for top of page : XPad offset

 SUBRP	scrn_scale140

	PUSH	a4,a14

	movi	>140,a5

	move	b2,a1
	srl	16,a1
	addi	25,a1
	sll	12,a1			;*512*8
	addi	SCRNXP*8+40*8,a1	;A1=*Scrn mem

	movi	DMACMAP,a6
	clr	a7			;Y line 8:8
#lp
	move	a7,a2
	srl	8,a2
	sll	12,a2			;*512*8
	move	a2,a3

	addi	SCRNBUF,a2
	addi	PALBUF,a3
	movi	400/2/5,b0		;Copy 1 line
#cslp
	move	*a3,*a6			;Set pal latch
	addk	16,a3
	move	*a2+,*a1+		;Copy 2 pixels

	move	*a3,*a6
	addk	16,a3
	move	*a2+,*a1+

	move	*a3,*a6
	addk	16,a3
	move	*a2+,*a1+

	move	*a3,*a6
	addk	16,a3
	move	*a2+,*a1+

	addk	16,a3
	addk	16,a2

	dsj	b0,#cslp

	addi	(512-320)*8,a1

	add	a5,a7
	cmpi	254<<8,a7
	jrlt	#lp


#x	PULL	a4,a14
	rets



#*******************************
* Copy screen data (throw out 1 in 3 pixels)
* B2=Y offset for top of page : XPad offset

 SUBRP	scrn_scale180

	PUSH	a4,a14

	movi	>180,a5

	move	b2,a1
	srl	16,a1
	addi	42,a1
	sll	12,a1			;*512*8
	addi	SCRNXP*8+68*8,a1	;A1=*Scrn mem

	movi	DMACMAP,a6
	clr	a7			;Y line 8:8
#lp
	move	a7,a2
	srl	8,a2
	sll	12,a2			;*512*8
	move	a2,a3

	addi	SCRNBUF,a2
	addi	PALBUF,a3
	movi	400/2/3,b0		;Copy 1 line
#cslp
	move	*a3,*a6			;Set pal latch
	addk	16,a3
	move	*a2+,*a1+		;Copy 2 pixels

	move	*a3,*a6
	addk	16,a3
	move	*a2+,*a1+

	addk	16,a3
	addk	16,a2

	dsj	b0,#cslp

	addi	(512-264)*8,a1

	add	a5,a7
	cmpi	254<<8,a7
	jrlt	#lp


#x	PULL	a4,a14
	rets


********************************

 SUBRP	scrn_scaledison

	movi	HEBLNKINIT,a0		;Display on
	move	a0,@HEBLNK
	movi	scrn_scale,a0
	move	a0,@dcode_p,L


#*******************************
* Copy screen data with variable down scaling
* B2=Y offset for top of page : XPad offset

 SUBRP	scrn_scale

	move	@scrnscl,a5
	cmpi	>168,a5
	jrlt	scrn_scale140
	cmpi	>190,a5
	jrlt	scrn_scale180

	PUSH	a4,a14

	move	b2,a9
	srl	16,a9
	movi	127<<8,a3
	divu	a5,a3
	sub	a3,a9
	addi	127,a9
	sll	12,a9			;*512*8

	addi	(SCRNXP+200)*8,a9	;A9=*Scrn mem
	movi	100<<8,a3
	divu	a5,a3
	sll	4,a3			;*16
	sub	a3,a9

	movi	DMACMAP,a6
	clr	a7			;Y line 8:8
	movi	200<<8,a10
#lp
	move	a7,a2
	srl	8,a2
	sll	12,a2			;*512*8
	move	a2,a3

	move	a9,a1
	addi	SCRNBUF,a2
	addi	PALBUF,a3
	clr	a8			;X 8:8
#cslp
	move	*a3,*a6			;Set pal latch
	move	*a2,*a1			;Copy 2 pixels
	addk	16,a1

	move	a8,a0
	add	a5,a8
	sra	8,a0
	move	a8,a14
	sra	8,a14
	sub	a0,a14

#nxtp
	addk	16,a3
	addk	16,a2
	subk	1,a14
	jrgt	#nxtp

	cmp	a10,a8
	jrlt	#cslp


	addi	512*8,a9		;Next line

	add	a5,a7
	cmpi	254<<8,a7
	jrlt	#lp


#x	PULL	a4,a14
	rets





	.end
