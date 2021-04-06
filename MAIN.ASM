**************************************************************
*
* Software:		Shawn Liptak and ?
* Initiated:		?
*
* Modified:		Shawn Liptak, 8/?/91	-Clean up
* 			Shawn Liptak, 1/27/92	-Basketball start
* 			Shawn Liptak, 3/19/93	-Clean up
*
* COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 3/24/93 14:58
**************************************************************
	.file	"main.asm"
	.title	"initialization and interrupts"
	.width	132
	.option	b,d,l,t
	.mnolist


	.include	"mproc.equ"
	.include	"disp.equ"
	.include	"gsp.equ"
	.include	"sys.equ"
	.include	"game.equ"
	.include	"shawn.hdr"
	.include	dipequ.asm
			

;external

	.ref	init_prog
	.ref	display_init
	.ref	process_init
	.ref	snd_reset
	.ref	pal_transfer
	.ref	dma_irq

	.ref	GAMSTATE
	.ref	C_FRAC,C_FLAGS,COINCNTR
	.ref	COLRTEMP
	.ref	swstack_p,swstackbot, swstacktop
	.ref	READ_DIP
	

;ram

	BSSX	SYSCOPY		,16	;Copy of SYSCTRL latch

	BSSX	WDOGRAM		,32	;INITIALIZED LONG FOR WATCH DOG DETECT

	BSSX	IRQSKYE		,16	;Erase color
	BSSX	dpageflip	,16	;1=Enable page flip and erasure, -1=No erasure

	BSSX	dirqtimer	,16	;+1 by dirq, cleared by mproc
	.bss	dirqcnt		,16	;+1 each dirq
	.bss	dirqdraw	,16	;!0=Still drawing last frame

	.bss	swtemp1		,32
	.bss	swtemp2		,32


	.bss	FSWITCH		,64
	BSSX	switches_old	,64
	BSSX	switches_cur	,64
	BSSX	switches_down	,64

	BSSX	NPLAYERS	,16	;NUMBER OF PLAYERS ALLOWED - GNP 1/17/93
	BSSX	COUNTER_MODE	,16	;COIN COUNTER MODE - GNP 1/17/93
	BSSX	VALIDATOR	,16	;VALIDATOR FLAG 0 = NONE, 1 = INSTALLED - GNP 1/22/93

	BSSX	TWOPLAYERS	,16	;0 = NO, 1 = YES 2 players
	.text


********************************
* Init hardware, IO, RAM
* Trashes scratch, A2-A7

 SUBR	init_all

	clr	a0			;>Clr scratch mem
	movi	SCRATCH,a1
	movi	>8000-20,a2		;128K minus some stack
#lp	move	a0,*a1+,L
	dsjs	a2,#lp


	movi	WDOGNUM,a0
	move	a0,@WDOGRAM,L		;Mark system as initialized

	movi	SYSCINIT,a0
	move	a0,@SYSCTRL
	move	a0,@SYSCOPY		;Copy

	callr	io_init			;Initialize the I/O regs

	calla	snd_reset		;Sound board reset (makes sound!)

	calla	display_init		;Init display system

	calla	process_init		;Init process list

	movk	INAMODE,a0
	move	a0,@GAMSTATE
	movi	81261A8CH,a0		;Random seed
	move	a0,@RAND,L

	movi	swstacktop,a0		;Initialize switch stack
	move	a0,@swstack_p,L

	callr	dip_init		;Initialize the dipswitches

	movk	1,a0
	move	a0,@DISPLAYON

	eint

	rets


********************************
* Initialize options via dip switch settings

dip_init
	PUSH	a0,a1

	calla	READ_DIP		;Get the current dip switch bits
	move	a0,a1

	andi	DPPLAYERS,a0		;AQUIRE THE NUMBER OF PLAYERS
	sll	3,a0
	addi	#pnum_t,a0
	movb	*a0,a0
	move	a0,@NPLAYERS

	move	a1,a0
	andi	DPCOUNTER,a0
	srl	DPCOUNTER_SRL-3,a0
	addi	#cntr_t,a0
	movb	*a0,a0			;Match eugene's old shit
	move	a0,@COUNTER_MODE

	move	a1,a0
	andi	DPVALIDATOR,a0		;AQUIRE THE VALIDATOR STATUS
	srl	DPVALIDATOR_SRL,a0
	move	a0,@VALIDATOR		;SAVE IT

	move	a1,a0
	andi	DPPLAYERS,a0
	move	a0,@TWOPLAYERS		;0=4 plyrs, 1=2 plyrs

	PULL	a0,a1
	rets

;Translate dipswitch into number of players allowed

#pnum_t	.byte	4,2

;Translate dipswitch coin counter adjustment to what the old cmos values were

#cntr_t	.byte	2,3,1,2
	.even


**************************************************************************
* Initialize GSP I/O registers

 SUBR	io_init

	PUSH	b2,b6
	movi	INTIO,b6
	exgpc	b6
	PULL	b2,b6
	rets


#*******************************
* Initialize GSP I/O registers
* B6=*Return address
* Trashes B0-B2

 SUBR	INTIO

	movi	HESYNC,b2
	movi	gspioinit_t,b0
	movi	(giiend-gspioinit_t)/16,b1
#lp	move	*b0+,*b2+
	dsj	b1,#lp

	exgpc	b6


#*******************************
* Watch dog disable
* Note: Call while interrupts are turned off

 SUBR	WDOGDIS

	.if	TUNIT=0

	PUSH	a0,a1,a2,a3,a4

	pushst
	setf	16,1,0

	movi	#dis_t,a1
	move	@SYSCOPY,a2
	movk	1,a3
	movi	SYSCTRL,a4
	move	*a1+,a0

#lp	or	a2,a0
	move	a0,*a4
	xor	a3,a0
	move	a0,*a4
	move	*a1+,a0
	jrnn	#lp

	move	a2,*a4

	popst
	PULL	a0,a1,a2,a3,a4
	rets


#dis_t	.word	0,0,0,0, 2,0,2,0, -1	;WATCH DOG DISABLE TABLE

	.else

	rets

	.endif


****************************************************************
* Display IRQ

DIRQ
	mmtm	sp,b0,b1,b2,b3,b4,b5,b6,b7,b11
	mmtm	sp,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14


	setf	1,0,0
	move	sp,@INTPEND+DIP		;Clear int pending
	move	sp,@INTENB+DIP		;Disable display int

	eint				;Let DMA int run

	setf	16,1,0			;Word sign extend

	movi	DPYCTL,a8

	move	*a8,a7			;>Shift register read to restart DMA
	movi	NIL|DXV|SRT|>10,a0
	move	a0,*a8
	movi	510*>1000,a2		;*Autoerase lines
	pixt	*a2,a2			;Mem to shift reg xfer


	move	@dirqdraw,a0
	jrnz	di50			;In draw code?

	move	b13,b0
	jrn	#chkmp			;DMA done?


	move	@GAMSTATE,a0
	jrn	#chkmp			;In diagnostics? (B13 invalid)

	movi	26000/4,a1		;>Make sure DMA is OK
#dqwait	cmp	b13,b0
	jrne	di50			;DMAQ changed?
	dsj	a1,#dqwait

	.if	DEBUG
	trap	29
	.endif

	clr	a1
	move	a1,@DMACTRL		;Timed out
	move	a1,@DMACTRL
	subk	1,a1
	move	a1,b13

di50	move	a7,*a8			;Restore
	jruc	#60hzcode		;Skip flip


#chkmp	move	@dirqtimer,a1
	jrnz	di50			;Mproc not done?

	move	@dpageflip,a2
	jrz	di400			;Flipping off?


	movi	-4,a0			;Page0
	movi	PAGE1YO*>1000,b2	;*Page1
	move	@dpage,a1
	jrnz	#onp1
	movi	->1004,a0		;Page1
	clr	b2			;*Page0
#onp1	move	a0,@DPYADR		;Override DPYSTRT
	move	a0,@DPYSTRT		;If we don't page flip next time
	not	a1			;Flip
	move	a1,@dpage


	dint
	movi	26000/8,a1		;>Wait on last DMA
#dwait	move	@DMACTRL,a0
	jrnn	#dmaoff			;DMA stopped?
	dsj	a1,#dwait
	move	a1,@DMACTRL		;Timed out
	.if	DEBUG
	trap	29
	.endif
#dmaoff

	move	a2,a2
	jrn	#noerase		;Erase off?

	movi	CONTROL,a9		;>Clear whole page
	move	*a9,a6
	movk	8,a0
	move	a0,*a9			;Transparency off
	movk	16,a0
	move	a0,@PSIZE
	movi	SCRN_PTCH*2,b3		;Pitch (2 lines)
	PUSH	b10,b11,b12,b13,b14
	movi	[127,1],b7		;Rows:Columns
	fill	l
	PULL	b10,b11,b12,b13,b14

	move	a6,*a9			;Restore
	movk	PXSIZE,a0
	move	a0,@PSIZE		;Normal
#noerase

di400	move	a7,*a8			;Restore
	eint


	calla	pal_transfer		;Copy new PALs

	move	@IRQSKYE,@ERASELOC	;Copy bkgnd color
;	move	@COLRTEMP,a0,L
;	jrz	#notindiag
;	movi	CYCOLORS,a1
;	move	a0,*a1+,L		;Copy diagnostics color cycler
;	move	@COLRTEMP+32,*a1,L
;#notindiag

	callr	switch_stack		;Scan misc switches

	movk	1,a0

	move	a0,@dirqdraw

	setf	1,0,0			;Enable display int
	move	a0,@INTENB+DIP
	setf	16,1,0


	calla	DISPLAY			;Build DMAQ, update XYPOS

	dint
	clr	a0
	move	a0,@dirqdraw		;Draw done




#60hzcode				;*** This code must run at 60HZ

	movi	SWITCH,a2
	movi	FSWITCH,a3

	move	*a2+,a0,L
	not	a0
	move	a0,*a3+,L
	move	*a2,a1,L
	not	a1
	move	a1,*a3,L

	move	@TWOPLAYERS,a14		;if 2-player kit then fudge
	jrz	#not_2			;the switches

	clr	a14
	move	a14,*a3,L

	move	a0,a1			;copy player 2 switches -> player 3
	zext	a0
	srl	8,a0
	move	a0,*a3

	subk	32,a3
	sll	8,a1			;copy player 1 switches -> player 2
	move	a1,*a3

#not_2

	movi	switches_cur,a2
	movi	switches_old,a3
	movi	switches_down,a4

	move	*a2,a1,L
	move	a1,*a3+,L
	move	@FSWITCH,a0,L
	move	a0,*a2+,L
	xor	a0,a1			;bits that have changed
	and	a0,a1			;down transitions
	move	a1,*a4+,L

	move	*a2,a1,L
	move	a1,*a3+,L
	move	@FSWITCH+20h,a0,L
	move	a0,*a2+,L
	xor	a0,a1			;bits that have changed
	and	a0,a1			;down transitions
	move	a1,*a4+,L




	move	@dirqtimer,a1		;Tell mproc to run
	addk	1,a1
	move	a1,@dirqtimer

	callr	switch_stack		;Scan misc switches


	move	@C_FLAGS,a0,L		;>Coin timers
	jrz	#ctoff
	movi	C_FLAGS+24,a2
#ctlp
	move	a0,a1
	srl	32-8,a1
	jrz	ctim1			;Inactive?
	subk	1,a1
	movb	a1,*a2
ctim1
	subk	8,a2
	sll	8,a0
	jrnz	#ctlp			;More?
#ctoff

	dint
	setf	1,0,0			;Enable display int
	movk	1,a1
	move	a1,@INTENB+DIP
	setf	16,1,0


	move	@dirqcnt,a0
	addk	1,a0
	move	a0,@dirqcnt
	sll	32-3,a0
	jrnz	dirqx			;Skip?


					;>Do every 8 ticks
	.if	DEBUG
	.else
	move	@dirqtimer,a0
	cmpi	400,a0
	jahs	init_prog		;Reset?
	.endif


	move	@C_FRAC,a0		;>Count down coin fraction timer
	jrz	#nfrc			;No frac?
	sll	32-8,a0
	srl	32-8,a0
	subk	1,a0
	move	a0,@C_FRAC
#nfrc

					;>Coin counters
	move	@COINCNTR,a0,L
	jrz	l_dog			;Counters, timers inactive?

	movk	2,a4			;do both counters
	movi	COINCNTR,a5
ccntr0l
	movb	*a5,a1			;more counts for counter ?
	jrz	c_cntr0			;no
	movb	*a5(16),a2		;previous pulse time out?
	jrnz	c_cntr0			;no
	movk	2,a2
	movb	a2,*a5(16)		;start new pulse
	dec	a1			;decrement counts
	movb	a1,*a5
c_cntr0
	addk	8,a5
	dsjs	a4,ccntr0l

*GNP START 1/16/93
	clr	a2			;counter on mask
;	movi	>100,a3
	MOVK	>1,a3
	movk	2,a4
c_cntr1l
	movb	*a5,a0			;counter timer active?
	jreq	c_cntr1			;no
	dec	a0			;yes, dec it and store
	movb	a0,*a5
	jreq	c_cntr1			;done
	add	a3,a2			;turn counter solenoid on
c_cntr1
	sll	1,a3
	addk	8,a5
	dsjs	a4,c_cntr1l


	.if	YUNIT
;	clr	a1
;	move	a1,@SECCHIP
;	move	a2,@SECCHIP		;Refresh counters in hardware
	MOVE	A2,@COIN_COUNTERS,W	;STICK IT TO 'EM
	.endif
*GNP END 1/16/93
l_dog
	.if	TUNIT2
	move	a0,@WATCHDOG		;Hit

	.else

	movi	wdogbone_t,a1		;>Clock watchdog
	move	@SYSCOPY,a2
	movk	1,a3
	movi	SYSCTRL,a4
	move	*a1+,a0

roverl	or	a2,a0
	move	a0,*a4
	xor	a3,a0
	move	a0,*a4
	move	*a1+,a0
	jrnn	roverl			;More?

	move	a2,*a4			;Restore
	.endif


dirqx	mmfm	sp,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14
	mmfm	sp,b0,b1,b2,b3,b4,b5,b6,b7,b11
	reti


wdogbone_t
	.word	0,2,0,2,2,-1	;Watchdog feed table


#*******************************
* Scan switches

 SUBRP	switch_stack

	move	@SWITCH,a0,L

	.if	TUNIT
	ori	>f800ffff,a0	;Set ignore bits
	.else
	ori	>ff007f7f,a0	;Set ignore bits
	movb	@COINS+16,a1
	jrn	swst30		;No P4 start?
	subk	1,a0		;Clr bit 0
swst30
	.endif
	move	@swtemp1,a1,L	;previous state t=n-1
	move	@swtemp2,a2,L	;previous previous t=n-2
	move	a1,@swtemp2,L	;new previous previous
	move	a0,@swtemp1,L	;new previous
	and	a1,a2
	andn	a0,a2		;look for 110
	jrz	#x		;No switches?

	move	@swstack_p,a3,L

#lp	cmpi	swstackbot,a3
	jreq	#x		;Switch stack overflow?
	lmo	a2,a0		;1's comp leftmost bit
	rl	a0,a2		;get rid of bit
	sll	1,a2
	movk	31,a1		;calc true bit #
	sub	a0,a1
	move	a1,-*a3		;Stack switch number (0-31)
	rl	a1,a2		;Restore switch word without bit
	jrnz	#lp

	move	a3,@swstack_p,L	;restore switch stack

#x	rets



**************************************************************************
* badtrapx - Come here when a trap is hit that is not defined and log it

badtrap31
badtrap30
badtrap28
badtrap27
badtrap26
badtrap25
badtrap24
badtrap23
badtrap22
badtrap21
badtrap20
badtrap19
badtrap18
badtrap17
badtrap16
badtrap15
badtrap14
badtrap13
badtrap12
badtrap11
badtrap9
badtrap8
badtrap7
badtrap6
badtrap5
badtrap4
badtrap3
badtrap2

badtrap
	.if	DEBUG
	LOCKUP
	eint
	.else
	CALLERR	9,0
	.endif

	reti

badtrap29
	.if	DEBUG
	reti
;	LOCKUP			;A write to ROM!
	.endif
	jruc	badtrap


;Initial GSP I/O register values

gspioinit_t
	.word	015h		;>C0000000 -- HESYNC
	.word	HEBLNKINIT	;>C0000010 -- HEBLNK
	.word	0fah		;>C0000020 -- HSBLNK
	.word	0fch		;>C0000030 -- HTOTAL
	.word	3		;>C0000040 -- VESYNC
	.word	20		;>C0000050 -- VEBLNK
	.word	274		;>C0000060 -- VSBLNK	;254 lines
	.word	288		;>C0000070 -- VTOTAL
	.word	>f010		;>C0000080 -- DPYCTL	ENV|NIL|DXV|SRE|>10
	.word	0fffch		;>C0000090 -- DPYSTRT
	.word	EOSINT		;>C00000A0 -- DPYINT 
	.word	2ch		;>C00000B0 -- CONTROL
	.word	0		;>C00000C0 -- HSTDATA
	.word	0		;>C00000D0 -- HSTADRL
	.word	0		;>C00000E0 -- HSTADRH
	.word	0		;>C00000F0 -- HSTCTLL
	.word	0		;>C0000100 -- HSTCTLH
	.word	0		;>C0000110 -- INTENBL
	.word	0		;>C0000120 -- INTPEND
	.word	0		;>C0000130 -- CONVSP
	.word	0		;>C0000140 -- CONVDP
	.word	PXSIZE		;>C0000150 -- PSIZE
	.word	0		;>C0000160 -- PMASK
	.word	0		;>C0000170 -- RESERVED
	.word	0		;>C0000180 -- RESERVED
	.word	0		;>C0000190 -- RESERVED
	.word	0		;>C00001A0 -- RESERVED
	.word	28		;>C00001B0 -- DPYTAP
giiend


;Initialize all 32 trap vectors

	.sect	"VECTORS"

	.long	badtrap31	;TRAP 31
	.long	badtrap30	;TRAP 30	ILLOP --- ILLEGAL OPCODE
	.long	badtrap29	;TRAP 29
	.long	badtrap28	;TRAP 28
	.long	badtrap27	;TRAP 27
	.long	badtrap26	;TRAP 26
	.long	badtrap25	;TRAP 25
	.long	badtrap24	;TRAP 24
	.long	badtrap23	;TRAP 23
	.long	badtrap22	;TRAP 22
	.long	badtrap21	;TRAP 21
	.long	badtrap20	;TRAP 20
	.long	badtrap19	;TRAP 19
	.long	badtrap18	;TRAP 18
	.long	badtrap17	;TRAP 17
	.long	badtrap16	;TRAP 16
	.long	badtrap15	;TRAP 15
	.long	badtrap14	;TRAP 14
	.long	badtrap13	;TRAP 13
	.long	badtrap12	;TRAP 12
	.long	badtrap11	;TRAP 11	WV --- WINDOW VIOLATION
	.long	DIRQ		;TRAP 10	DI --- DISPLAY INTERRUPT
	.long	badtrap9	;TRAP 9		HI --- HOST INTERRUPT
	.long	badtrap8	;TRAP 8		NMI -- NONMASKABLE INTERRUPT
	.long	badtrap7	;TRAP 7
	.long	badtrap6	;TRAP 6
	.long	badtrap5	;TRAP 5
	.long	badtrap4	;TRAP 4
	.long	badtrap3	;TRAP 3
	.long	badtrap2	;TRAP 2		INT2 --- EXTERNAL INTERRUPT 2
	.long	dma_irq		;TRAP 1		INT1 --- EXTERNAL INTERRUPT 1
	.long	init_prog	;TRAP 0		RESET


	.end
