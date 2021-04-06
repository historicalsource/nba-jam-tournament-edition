**************************************************************
*
* Software:		George Petro, Todd Allen
* Initiated:		1989?
*
* Modified:		Mark Turmell, 7/17/90	-Total Carnage
* 			Shawn Liptak, 7/?/91	-Speed improvements
* 			Shawn Liptak, 7/?/91	-SL type stuff
* 			Shawn Liptak, 8/30/91	-New collision loop
* 			Shawn Liptak, 9/18/91	-Pixscan improvements
* 			Shawn Liptak, 2/11/92	-Started basketball
*
* COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 5/5/92 10:40
**************************************************************
	.file	"coll2.asm"
	.title	"collision routines"
	.width	132
	.option	b,d,l,t
	.mnolist


	.include	"mproc.equ"
	.include	"disp.equ"
	.include	"sys.equ"
	.include	"gsp.equ"
	.include	"game.equ"
	.include	"imgtbl.glo"
	.include	"shawn.hdr"

;sounds



;refs
	.ref	PCNT
	.ref	ball_hit

;defs


;ram

	BSSX	coll_stop	,16		;!0=Stop scan on current obj
	.bss	PList		,32*(NOBJ+1)	;List of objs of class player
	.bss	NList		,32*(NOBJ+1)	;List of objs of class neutral
	.bss	EList		,32*(NOBJ+1)	;List of objs of class enemy

;NOBJ=# objects to display



****************************************************************************
* When writing collision routines which are to be called from the collision
* scanner in this file, the following things should be taken into
* consideration:
*   The collision routines are called, not created..
*   The collision routine receives a ptr to the victims OBJ in A8
*   The collision routine receives a ptr to the killers OBJ in A0
*   The collision routine can destroy A0,A8,A14,B0,B1.
*   Other registers must be preserved!
*
*   When OBJ1,OBJ2 collide, two routines are called, one with
*    OBJ1 in A8 and the other with OBJ2 in A8.  A collision routine
*    should only affect the victim, and not the killer.
*   If a victim object is deleted, it will not be scanned futher.
*   If any other object is deleted, the collision scan will be aborted.
*   To prevent multiple simultaneous collisions of the same victim
*   object, the object ID of the victim object should be modified
*   by the collision routine, if the victims nature is changed.



****************************************************************************
* Old collision loop

	.if	0			;Not used!!
	.def	debugtime
	.def	debugtimem
	.bss	debugtime	,16
	.bss	debugtimem	,16

 SUBR	COLLISIONS

	SLEEPK	1
	move	@VCOUNT,b5

	move	@WORLDTLX+16,A6	;* COLLISION SCAN FOR OBJECTS ON SCREEN
	movi	400,A14		;End of Scan area

coll1	move	A6,A7		;A7 Sector Xmin
	addi	128,A6		;A6 Sector Xmax

	subi	128,A14
	jrnn	XmaxOk
	add	A14,A6

XmaxOk	movi	OBJLST,a0	;Object list to check
	callr	cscnrng

	move	A14,A14
	jrp	coll1


	move	@VCOUNT,b0
	sub	b5,b0
	jrhs	coll10
	addi	>120,b0		;VTOTAL
coll10	move	@debugtime,b1
	add	b0,b1
	srl	1,b1
	move	b1,@debugtime
	move	@debugtimem,b2
	cmp	b1,b2
	jrge	coll20
	move	b1,@debugtimem	;New max
coll20	jruc	COLLISIONS


********************************
*A0 * to obj list to scan
*A6 Xmax
*A7 Xmin
*Scan OBJ list, any collideable OBJ overlapping Xmin-Xmax put on
*either EList,PList or NList depending on class
*Call ColLists with each pair of lists

cscnrng
	mmtm	sp,a6,a7,a14
	
	movi	PList,A9		;Build collision lists
	move	a9,a4
	movi	EList,A10
	movi	NList,A11
	jruc	MkLists

csr20	move	a0,*a10+,L		;Insert obj on enemy list
MkLists	move	*a0,a0,L		;Get next obj
	jrz	GotLists

	move	*a0(OXPOS),a1		;OBJ CAN LIE ON max/min boundary
	cmp	a6,a1
	jrhi	MkLists

	move	*a0(OSIZEX),a2
	add	a2,a1
	cmp	a7,a1
	jrlo	MkLists			;Out of range?

	movb	*a0(OFLAGS+B_NOCOLL-7),a2
	jrn	MkLists			;Not collideable?

	move	*a0(OID),a2		;Check Class
	jrn	csr20			;Enemy?
	btst	14,a2
	jrnz	csr40			;Player?

	move	a0,*a11+,L		;Insert obj on neutral list
	jruc	MkLists

csr40	move	a0,*a9+,L		;Insert obj on player list
	jruc	MkLists

GotLists
	clr	a0			;Null terminate each list
	move	a0,*a9,L
	move	a0,*a10,L
	move	a0,*a11,L

	move	*A4,A0,L
	jrz	NoPList			;Nothing on player list?

	movi	EList,A3		;E/P
	callr	ColLists

	movi	NList,A3		;N/P
	movi	PList,A4
	callr	ColLists

NoPList

ScnRngX	mmfm	sp,a6,a7,a14
	rets
	.endif



****************************************************************************
* Collision loop (New version)

 SUBR	collisions

	SLEEPK	1

	move	@WORLDTLX+16,a6		;A6=Xmin
	move	a6,a7
	addi	100,a7			;A7=Xmax
	move	a7,b3
	callr	collx

	move	b3,a6
	move	a6,a7
	addi	100,a7
	move	a7,b3
	callr	collx

	move	b3,a6
	move	a6,a7
	addi	100,a7
	move	a7,b3
	callr	collx

	move	b3,a6
	move	a6,a7
	addi	100,a7
	callr	collx

	jruc	collisions

********************************
* Build lists and collide based on X
* A6=XMin
* A7=XMax (+1)

collx
	movi	OBJLST,a0		;Object list to check

	movi	PList,a9		;Build collision lists
	move	a9,b4			;Set A5/B4 for 1st collision call
	movi	EList,a10
	move	a10,a5
	movi	NList,a11
	jruc	mklists

csr20	move	a0,*a10+,L		;Insert on enemy list
mklists	move	*a0,a0,L		;Get next obj
	jrz	gotlists

	movb	*a0(OFLAGS+B_NOCOLL-7),a2
	jrn	mklists			;Not collideable?

	move	*a0(OXPOS),a1		;Obj can lie on max/min boundary
	cmp	a7,a1
	jrge	mklists			;Out of range?

	move	*a0(OSIZEX),a2
	add	a2,a1
	cmp	a6,a1
	jrle	mklists			;Out of range?

	move	*a0(OID),a2		;Check Class
	jrn	csr20			;Enemy?
	btst	14,a2
	jrnz	csr40			;Player?

	move	a0,*a11+,L		;Insert on neutral list
	jruc	mklists

csr40	move	a0,*a9+,L		;Insert on player list
	jruc	mklists

gotlists
	move	a0,*a9,L		;Null terminate each list
	move	a0,*a10,L
	move	a0,*a11,L

	callr	ColLists		;Collide enemy to player

	movi	NList,a5
	movi	PList,b4
;	jruc	ColLists		;Collide neutral to player
					;Fall through

********************************
* Collide objects on list A5 with those on LIST B4
* A5,B4=ptrs to null terminated tables of object ptrs

ColLists
CLstsLp0
	move	*a5+,a1,L
	jrz	scndone
					;Load up coors of obj from first list
	move	*a1(OXPOS),a9		;A9=OBJ1 Xmin
	jrz	CLstsLp0		;Deleted?
	move	*a1(OSIZEX),a10		;A10=OBJ1 Xmax (+1)
	add	a9,a10
	move	*a1(OYPOS),a7		;A7=OBJ1 Ymin
	move	*a1(OSIZEY),a11		;A11=OBJ1 Ymax (+1)
	add	a7,a11

	move	b4,a6			;Load head of second list

PScnLp1	move	*a6+,a2,L
	jrz	CLstsLp0

	movb	*a2(OFLAGS+B_3D-7),a0
	jrn	#3d			;3D mode? (Maybe all????)

	move	*a2(OYPOS),a0		;Check objs A1,A2 for intersection
	cmp	a11,a0
	jrge	PScnLp1			;Y2Min >= Y1Max?
	move	*a2(OSIZEY),a14
	add	a14,a0
	cmp	a7,a0
	jrle	PScnLp1			;Y2Max <= Y1Min?

#3d	move	*a2(OXPOS),a0		;Signed compares because objs may lie on 0
	jrz	PScnLp1			;Deleted?
	cmp	a10,a0
	jrge	PScnLp1			;X2Min >= X1Max?
	move	*a2(OSIZEX),a14
	add	a14,a0
	cmp	a9,a0
	jrle	PScnLp1			;X2Max <= X1Min?

	callr	ColFunc			;>Call colfunc for obj A1 and A2
	move	b0,b1			;B1=*Collision routine for obj A1
	SWAP	a1,a2
	callr	ColFunc
	SWAP	a1,a2
	move	b0,b2			;B2=*Collision routine for obj A2
	or	b1,b0			;Set z flag if both are zero
	jrz	PScnLp1

	movb	*a1(OFLAGS+B_PIXSCAN-7),a14 ;Is PIXSCAN ON
	jrn	DoPScn0
	movb	*a2(OFLAGS+B_PIXSCAN-7),a14 ;Is PIXSCAN ON
	jrnn	SkPxScn0
DoPScn0	callr	PIXSCAN
	jrnc	PScnLp1			;BR=THIS WASN'T REALLY A COLLISION
SkPxScn0

	clr	a0
	move	a0,@coll_stop		;Clr flag

	move	b1,b1
	jrz	PObj2Col
	move	a1,a8
	move	a2,a0
	call	b1			;Call collision for A1

PObj2Col
	move	b2,b2
	jrz	PCkFree
	move	a2,a8
	move	a1,a0
	call	b2			;Call collision for A2

PCkFree	move	@coll_stop,a0
	jrz	PScnLp1			;Continue scan?
	jruc	CLstsLp0

scndone	rets


****************************************************************************
* Return in B0 routine for obj A1 struck by obj A2
* Trashes A3-A4

ColFunc
	movb	*a1(OID+8),a3
	movb	*a2(OID+8),a4
	sll	32-5,a3
	srl	17,a3		;32 Long Word Align
	sll	32-5,a4
	srl	22,a4		;Long Align
	add	a4,a3
	addi	TypeTbl,a3

	move	*a3,a3,L
	jump	a3		;Routine can trash A0/A3/A4/A8/A14


****************************************************************************
* These are the COLLISION FUNCTIONS
* A collision function is selected by the routine ColFunc
* which uses the TYPE field of the victims OID to select a subtable
* and indexes the subtable with the TYPE field of the killer.
* This gives a ptr to a COLLISION FUNCTION which returns
* the COLLISION ROUTINE to be called for the victim in B0.
* The COLLISION FUNCS can destroy registers A0,A3,A4,A8
****************************************************************************

TypeTbl
;0000
;NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;100
;Player
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;200
;Basketball
	.LONG	NULL, BBPL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;300
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;400
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;500
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;600
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;700
;Text
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;800
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;900
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;a00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;b00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;c00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;d00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;e00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;f00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1000
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1100
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1200
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1300
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1400
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1500
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1600
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1700
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1800
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1900
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1a00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1b00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1c00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1d00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1e00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;1f00
;Free
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL


********************************
* Shawn's enemy type collisons

;SLPL	movb	*a1(OID),a0
;	cmpi	SUBSHRAP,a0
;	jreq	NULL			;Shrapnel?
;	subk	SUBMSL,a0
;	jreq	slpl5			;Missile?
;	movb	*a2(OID),a0		;Player ring
;	subk	3,a0
;	jrne	NULL
;slpl5
;;	movi	slt_ringhit,b0
;	rets
;
;SLBL	movb	*a1(OID),a0
;	subk	SUBSHRAP,a0
;	jreq	NULL			;Shrapnel?
;;	movi	slt_hit,b0		;Bullet
;	rets
;
;SLBB	movb	*a1(OID),a0
;	subk	SUBSHRAP,a0
;	jreq	NULL			;Shrapnel?
;;	movi	slt_bbhit,b0		;Blade, bomb
;	rets
;
;BLSL	movb	*a2(OID),a0
;	subk	SUBMSL,a0
;;	jrne	BLHU			;!Missile?
;;	movi	KILL_BULL2,b0
;	rets




NULL	clr	b0
	rets


BBPL
	move	*a1(OZPOS),a0
	move	*a2(OZPOS),a14
	sub	a14,a0
	move	a0,a3
	abs	a3
	cmpi	30,a3
	jrhi	NULL			;Not in range?

	movi	ball_hit,b0
	rets



****************************************************************************
*COLLISION ROUTINE
*A1=OBJECT ONE
*A2=OBJECT TWO
*RETURNS: CS= COLLISION, CC= NO COLLISION
*
* CLOBBERS A14
*CREATE TIME SLICE WHILE LOCKING OUT INTERRUPTS

PIXSCAN
	mmtm	sp,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
	mmtm	sp,b0,b1

	move	a1,a10			;A10=*Obj0
	move	a2,a8			;A8=*Obj1
	dint
	move	*a10(OXPOS),a3		;Set up object box TLX,TLY
	move	*a10(OYVAL),a14,L
	movy	a14,a3			;A3=Obj0 Y:X

	move	*a8(OXPOS),a4
	move	*a8(OYVAL),a14,L
	movy	a14,a4			;A4=Obj1 Y:X

	move	*a10(OCTRL),a6
	move	a6,b0			;B0=flags object 0
	move	*a8(OCTRL),a6
	move	a6,b1			;B1=flags object 1

	move	*a10(OIMG),a9,L		;A9=*Image 0
	move	*a8(OIMG),a7,L		;A7=*Image 1
	eint

	move	*a9,a5,L		;ISIZE
	move	*a7,a6,L		;ISIZE
	addxy	a3,a5			;A5=Obj0 lower rgt Y:X
	addxy	a4,a6			;A6=Obj1 lower rgt Y:X
	cmpxy	a6,a3			;compare (lrx1,lry1) to (tlx0,tly0)
	JRXGE	CSFAIL
	JRYGE	CSFAIL
	cmpxy	a4,a5			;compare (tlx1,tly1) to (lrx0,lry0)
	JRXLE	CSFAIL
	JRYLE	CSFAIL


*A11=XOFF0
*A12=XOFF1
	move	a3,a2		;>Calc XOFF0,XOFF1,XSCAN
	subxy	a4,a2
	sext	a2
	jrnn	clx1	
	neg	a2
	move	a2,a11		;object 1 to the right
	clr	a12
	move	a4,a13		;rightmost top left
	jruc	clx2

clx1	move	a2,a12		;object 0 to the right
	clr	a11
	move	a3,a13		;rightmost top left
clx2	cmpxy	a5,a6		;find leftmost lower right
	jrxn	clx3
	subxy	a5,a13
	jruc	clx4

clx3	subxy	a6,a13
clx4	sext	a13
	neg	a13		;A13=XSCAN

				;>Calc YOFF0,YOFF1,YSCAN
	sra	16,a3		;Kill X half
	sra	16,a4
	sra	16,a5
	sra	16,a6
	move	a3,a2		;A3=YOFF1
	sub	a4,a2		;A2=YOFF0
	jrnn	cly1	
	neg	a2
	clr	a3		;object 1 to the right
	move	a4,a14		;rightmost top left
	jruc	cly2

cly1	move	a3,a14		;object 0 to the right
	move	a2,a3
	clr	a2
cly2	cmp	a5,a6		;find leftmost lower right
	jrn	cly3
	sub	a5,a14
	jruc	cly4
cly3	sub	a6,a14
cly4	neg	a14		;A14=YSCAN

*A2=YOFF0
*A3=YOFF1
*A4=IMAGE SOURCE ADDRESS TEMP
*A5=WIDTH TEMP
*A7=IMAGE 1 DATA HEADER POINTER
*A8=IMAGE 1 OBJECT POINTER
*A9=IMAGE 0 DATA HEADER POINTER
*A10=IMAGE 0 OBJECT POINTER
*A11=XOFF0
*A12=XOFF1
*A13=XSCAN
*A14=YSCAN

*CALCULATE OBJECT 0 STARTAD, HINC0, VINC0

	move	*a9(ISAG),a4,L	;Get image source address
	move	*a9,a5		;Get ISIZEX
	addk	3,a5		;correct erroneous width (thanx, warren)
	srl	2,A5
	sll	2,A5
	
*CHECK OBJECT 0 FLIPS

	btst	B_FLIPH,b0
	jrnz	CL0HF		;HORIZONTAL FLIP
	btst	B_FLIPV,b0
	jrnz	CL0VF		;VERTICAL FLIP
	
				;NO FLIP CASE
	move	a5,a1		;Get width
	mpyu	a2,a1		;Mult width x yoff
	add	a11,a1		;Add in x offset
	sll	3,a1		;Correct for byte addressing
	add	a1,a4		;A4=STARTAD0=IMAGEAD0+(YOFF0 X W0) + XOFF
	sub	a13,a5		;A5=VINC0=W0-XScan
	sll	3,a5		;Correct for pixel addressing
	movk	8,a2		;A2=HINC0
	jruc	CLOBJ1


CL0HF	BTST	B_FLIPV,B0	;VERT FLIP TOO?
	JRNE	CL0HVF		;HORIZ AND VERT FLIP
				;HORIZONTAL FLIP
	MOVE	A5,A1		;GET WIDTH
	MPYU	A2,A1		;MULT WIDTH X Y OFFSET
	ADD	A5,A1		;ADD IN WIDTH
	SUB	A11,A1		;SUBTRACT X OFFSET
	DEC	A1		;-1 MORE
	SLL	3,A1		;CORRECT FOR BYTE ADDRESSING
	ADD	A1,A4		;A4=STARTAD0=IMAGEAD0+(YOFF0*W0)+W0-XOFF0-1
	MOVI	-8,A2		;A2=HINC0
	ADD	A13,A5		;A5=VINC0=W0+XSCAN
	SLL	3,A5		;CORRECT FOR PIXEL ADDRESSING
	JRUC	CLOBJ1

				;VERTICAL FLIP
CL0VF	MOVE	*A9(ISIZEY),A1	;GET HEIGHT
	SUB	A2,A1		;SUBTRACT YOFF0
	DEC	A1
	MPYU	A5,A1		;MULTIPLY BY WIDTH
	ADD	A11,A1		;ADD IN X OFFSET
	SLL	3,A1		;CORRECT FOR PIXEL ADDRESSING
	ADD	A1,A4		;A4=STARTAD0=IMAGEAD0+(H0-YOFF0-1)W0+XOFF0
	NEG	A5		;-W0
	SUB	A13,A5		;-XSCAN
	SLL	3,A5		;A5=VINC0=-W0-XSCAN
	MOVK	8,A2		;A2=HINC0
	JRUC	CLOBJ1

				;VERTICAL AND HORIZONTAL FLIP
CL0HVF	MOVE	*A9(ISIZEY),A1	;GET HEIGHT
	SUB	A2,A1		;SUBTRACT YOFF0
	DEC	A1
	MPYU	A5,A1		;MULTIPLY BY WIDTH
	ADD	A5,A1		;ADD IN WIDTH (W0)
	SUB	A11,A1		;SUBTRACT XOFF0
	DEC	A1
	SLL	3,A1		;CORRECT FOR PIXEL ADDRESSING
	ADD	A1,A4		;A4=STARTAD0=(H0-YOFF0-1)W0+W0-XOFF0-1
	NEG	A5		;-W0
	ADD	A13,A5		;+XSCAN
	SLL	3,A5		;A5=VINC0=-W0-XSCAN
	MOVI	-8,A2		;A2=HINC0


*CALCULATE OBJECT 1 STARTAD, HJUMP, VJUMP		

*A2=HINC0
*A3=YOFF1, HINC1
*A4=STARTAD0
*A5=VINC0
*A6=STARTAD1
*A7=IMAGE 1 DATA HEADER POINTER
*A8=IMAGE 1 OBJECT POINTER
*A9=IMAGE 0 DATA HEADER POINTER
*A10=IMAGE 0 OBJECT POINTER
*A11=W1, VINC1
*A12=XOFF1
*A13=XSCAN
*A14=YSCAN

CLOBJ1	move	*a7(ISAG),a6,L	;Get image source address
	move	*a7,a11		;Get ISIZEX
	addk	3,a11		;correct erroneous width (thanx, warren)
	srl	2,A11
	sll	2,A11
	
	BTST	B_FLIPH,B1	;CHECK OBJECT 1 FLIPS
	JRNE	CL1HF		;HORIZONTAL FLIP
	BTST	B_FLIPV,B1
	JRNE	CL1VF		;VERTICAL FLIP
	
*NO FLIP CASE
*A3=HINC1=8 (BYTE AT A TIME)
*A11=VINC1=W1-XSCAN
*A6=STARTAD1=IMAGEAD1+(YOFF1 X W1) + XOFF1

	MOVE	A11,A1		;GET WIDTH
	MPYU	A3,A1		;MULT WIDTH X YOFF
	ADD	A12,A1		;ADD IN X OFFSET
	SLL	3,A1		;CORRECT FOR BYTE ADDRESSING
	ADD	A1,A6		;ADD TO SOURCE ADDRESS
	MOVK	8,A3		;HINC1
	SUB	A13,A11		;VINC1=W1-XSCAN
	SLL	3,A11		;CORRECT FOR PIXEL ADDRESSING
	JRUC	CSH

*HORIZONTAL FLIP
*A3=HINC1=-8
*A11=VINC1=W1+XSCAN
*A6=STARTAD1=IMAGEAD1+(YOFF1 X W1) + W1-XOFF1-1
CL1HF	BTST	B_FLIPV,B1	;VERT FLIP TOO?
	JRNE	CL1HVF		;HORIZ AND VERT FLIP
	MOVE	A11,A1		;GET WIDTH
	MPYU	A3,A1		;MULT WIDTH X Y OFFSET
	ADD	A11,A1		;ADD IN WIDTH
	SUB	A12,A1		;SUBTRACT X OFFSET
	DEC	A1		;-1 MORE
	SLL	3,A1		;CORRECT FOR BYTE ADDRESSING
	ADD	A1,A6
	MOVI	-8,A3		;HINC1
	ADD	A13,A11		;VINC1=W1+XSCAN
	SLL	3,A11		;CORRECT FOR PIXEL ADDRESSING
	JRUC	CSH

*VERTICAL FLIP
*A3=HINC1=8
*A11=VINC1=-W1-XSCAN
*A6=STARTAD1=IMAGEAD1+(H1-YOFF1-1)W1+XOFF1
CL1VF	MOVE	*A7(ISIZEY),A1	;GET HEIGHT
	SUB	A3,A1		;SUBTRACT YOFF1
	DEC	A1
	MPYU	A11,A1		;MULTIPLY BY WIDTH
	ADD	A12,A1		;ADD IN X OFFSET
	SLL	3,A1		;CORRECT FOR PIXEL ADDRESSING
	ADD	A1,A6		;ADD TO SOURCE ADDRESS
	NEG	A11		;-W1
	SUB	A13,A11		;-XSCAN
	SLL	3,A11		;CORRECT FOR PIXEL ADDRESSING
	MOVK	8,A3		;HINC1
	JRUC	CSH

*VERTICAL AND HORIZONTAL FLIP
*A3=HINC1=-8
*A11=VINC1=-W1-XSCAN
*A6=STARTAD1=(H1-YOFF1-1)W1+W1-XOFF1-1
CL1HVF	MOVE	*A7(ISIZEY),A1	;GET HEIGHT
	SUB	A3,A1		;SUBTRACT YOFF1
	DEC	A1
	MPYU	A11,A1		;MULTIPLY BY WIDTH
	ADD	A11,A1		;ADD IN WIDTH (W1)
	SUB	A12,A1		;SUBTRACT XOFF1
	DEC	A1
	SLL	3,A1		;CORRECT FOR PIXEL ADDRESSING
	ADD	A1,A6		;ADD TO SOURCE ADDRESS
	NEG	A11		;-W1
	ADD	A13,A11		;+XSCAN
	SLL	3,A11		;CORRECT FOR PIXEL ADDRESSING
	MOVI	-8,A3		;HINC1

*A1= WIDTH COUNTER XSCAN
*A2=H INCREMENT IMAGE 0
*A3=H INCREMENT IMAGE 1
*A4=INDEX TO IMAGE 0
*A5=V INCREMENT IMAGE 0
*A6=INDEX TO IMAGE 1
*A7=IMAGE 1 DATA HEADER POINTER
*A8=IMAGE 1 OBJECT POINTER
*A9=IMAGE 0 DATA HEADER POINTER
*A10=IMAGE 0 OBJECT POINTER
*A11=V INCREMENT IMAGE 1
*A13=WIDTH COUNT XSCAN
*A14=HEIGHT COUNT YSCAN

CSH	cmpi	>80,a14		;no scan if xscan, yscan values out of range
	jrhs	CSFAIL
	cmpi	>80,a13
	jrhs	CSFAIL

	dint
	move	@INTENB,a0
	andni	X1E,a0
	move	a0,@INTENB
	eint

csh0	move	@DMACTRL,a0
	jrn	csh0		;DMA busy?

	.if	YUNIT
	setf	6,0,0		;6 bit field
	.else
	setf	8,0,0		;8 bit field
	.endif

csh1	move	a13,a1		;load line countdown horiz counter

cshl	move	*a4,a0		;Check image 0 corresponding non zeroes
	jrz	csnxh		;No hit?

	move	*a6,a0		;check image 1
	jrnz	pshit		;Hit?

csnxh	add	a2,a4		;Add horiz increments
	add	a3,a6
	dsjs	a1,cshl		;Loop horizontal

	add	a5,a4		;Add vert increments
	add	a11,a6
	dsjs	a14,csh1	;Loop vert

	setf	16,1,0		;Normal field

CSFAIL	move	b13,b13
	jrz	psnodma		;Skip DMA restart?
	dint
	move	@INTENB,a0
	ori	X1E,a0
	move	a0,@INTENB
	eint
psnodma	clrc			;No hit
	jruc	psx		;Exit


pshit	setf	16,1,0		;Normal field
	move	b13,b13
	jrz	csflags		;Skip DMA restart?
	dint
	move	@INTENB,a0
	ori	X1E,a0
	move	a0,@INTENB
	eint
csflags	setc			;Hit

psx	mmfm	sp,b0,b1
	mmfm	sp,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
	rets



********************************
*PLAYER HAS BEEN COLLIDED WITH
*TELL THIS COLLISION CHECK THAT PLAYER IS REALLY SHORTER THAN HE IS
*THEN RETURN CARRY SET IF STILL A HIT, CARRY CLEAR IF THIS SHOULD NOT BE
*A COLLISION.
*A0=OBJECT THAT HIT PLAYER
*A8=PLAYER LEGS IMAGE PTR

;SHORT_PLYR
;	MOVE	*A8(OYPOS),A7		;A7 - OBJ1 Ymin
;	ADDK	3,A7			;ADDI 0
;	MOVE	*A0(OID),A11
;	zext	a11
;;	CMPI	CLSENMY|TYPORB,A11
;;	JRNE	SP0
;;	SUBK	5,A7
;;	MOVE	*A8(OSIZEY),A11,W	;A11 - OBJ1 Ymax
;;	SUBK	8,A11			;MAKE LEGS SHORTER IN LENGTH!
;;	JRUC	SP2
;;SP0
;	CMPI	CLSNEUT|TYPMINE,A11
;	JRNE	SP1
;	ADDK	12,A7			;15
;	MOVE	*A8(OSIZEY),A11		;A11 - OBJ1 Ymax
;	SUBK	19,A11			;MAKE LEGS SHORTER IN LENGTH! ;21
;	JRUC	SP2
;SP1
;	move	*A8(OSIZEY),A11		;A11 - OBJ1 Ymax
;	SUBK	20,A11	 ;19		;SUBI 13 16 ;MAKE LEGS SHORTER IN LENGTH!
;SP2	add	A7,A11
;	move	*A0(OYPOS),A6		;CHECK OBJS A0,A8 for intersection
;	cmp	A11,A6
;	jrgt	CLRCR			;Y2Min > Y1Max
;	move	*A0(OSIZEY),A11
;	add	A11,A6
;	cmp	A7,A6
;	jrlt	CLRCR			;Y2Max < Y1Min
;
;;NOW X CHECK
;
;	move	*A8(OXPOS),A7		;A9 - OBJ1 Xmin
;	addk	6,a7
;	move	*A8(OSIZEX),A11		;A10 - OBJ1 Xmax
;	subk	6,a11
;	add	A7,A11
;	move	*A0(OXPOS),A6		;USE SIGNED COMPARES BECAUSE OBJS MAY LIE ON ZERO
;	cmp	A11,A6
;	jrgt	CLRCR			;X2Min > X1Max
;	move	*A0(OSIZEX),A11
;	add	A11,A6
;	cmp	A7,A6
;	jrlt	CLRCR			;X2Max < X1Min
;
;	move	@PCNT,a6
;	btst	0,a6
;	JRZ	CLRCR
;	SETC				;GOT A BOX INTERSECTION
;	RETS
;CLRCR	CLRC
;	RETS





	.end
