**************************************************************
*
* Software:		Shawn Liptak
* Initiated:		June 6,1991 (Total Carnage)
*
* Modified:		Shawn Liptak, 2/11/92	-Started basketball
*
* COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 7/23/92 18:42
**************************************************************
      	.file	"rackup.asm"
	.title	"total carnage game program"
	.width	132
	.option	b,d,l,t
	.mnolist

	.include	"mproc.equ"
	.include	"disp.equ"
	.include	"sys.equ"
	.include	"game.equ"
	.include	"imgtbl.glo"
	.include	"audit.equ"
	.include	"shawn.hdr"		;My macros



;sound headers used

	.ref	GLSEXP,NOWAY,SETDWN,TUNE3,TUNE2,STATSND

CVSDOFF .word	>F0F0,10,>807D,0		;SPEECH OFF
TUNE4	.word	>f3fe,10,>8007,0		;Rackup tune
racksup	.word	>f280,1,>80b3,0			;Rackup bonus sweep up
rackoff	.word	>fa81,1,>80a7,0			;Rackup bonus off
kilfgnd	.word	>f000,1,>807f,0			;Kill foregnd snds
rackp1p	.word	>fa80,1,>80b4,0			;Rackup P1 gets 1000 pts
rackp2p	.word	>fa80,1,>80b5,0			;^ P2
stats1	.word	>f280,1,>8100,0			;Rackup stat line snd
stats2	.word	>f280,1,>8101,0			;^
stats3	.word	>f280,1,>8102,0			;^
stats4	.word	>f280,1,>8103,0			;^
stats5	.word	>f280,1,>8104,0			;^
stats6	.word	>f280,1,>8105,0			;^
stats7	.word	>f280,1,>8106,0			;^
stats8	.word	>f280,1,>8107,0			;^
stats9	.word	>f280,1,>8108,0			;^
stats10	.word	>f280,1,>8109,0			;^
stats11	.word	>f280,1,>810a,0			;^
stats12	.word	>f280,1,>810b,0			;^
txtssnd	.word	>f3f7,8,>80b1,0			;Text shrink
shout	.word	>f1a0,60,>80fe,0		;Rackup victory shout
rackgun	.word	>fca0,4,>8030,0			;Player shoots gun
gigle1	.word	>f9a0,60,>80f3,0		;Rackup winner laughs
ahkb1	.word	>f9a0,10,>80eb,0		;Akhboob speech
ahkb2	.word	>f9a0,10,>80ec,0		;^
ahkb3	.word	>f9a0,10,>80ed,0		;^
ahkbsta	.word	>f9a0,10,>80ee,0		;^ start angry
ahkbang	.word	>f9a0,10,>80ef,0		;^ angry
DOLLAR	.WORD	>F9F7,>50,>814E,0		;BUY 4 DOLLAR
yousuck	.word	>f9a0,10,>80c5,0		;You suck at this game!
fisthit	.word	>fca0,10,>803c,0		;Ahkboob hits desk
ermtune	.word	>f3f0,10,>8004,0		;Electrocution tune
fshock	.word	>f540,20,>80bb,0		;Electric chair shocks
fburn	.word	>f048,30,>80d7,0		;^ burn
fpain1	.word	>f965,20,>80f6,0		;Player in pain
fpain2	.word	>f160,20,>80f7,0		;^
fpain3	.word	>f160,20,>80fd,0		;^
fskullb	.word	>f460,20,>8040,0		;Skull bounce
fryexp	.word	>fc50,6,>803e,0			;Fry explosion
fryexp2	.word	>fd50,8,>80d9,0			;^
totcarn	.word	>f980,30,>80cf,0		;Total carnage!
gluck	.word	>f1f7,>40,>80e5,0		;"Good luck"
TXTSND1	.WORD	>F3F7,>8,>80AE,0


;symbols externally defined

	.ref	anim_script,anim_kilslp,animscnt,anim_killall,anim_wait
	.ref	CYCLE_TABLE,AIRSCRM
	.ref	pal_set,pal_find,pal_getf,PCNT,WAVE
	.ref	IRQSKYE,ERASE_TXT,HEXTOASC,FRANIM,HALT
	.ref	CRMP,BCDBIN,BINBCD
	.ref	WSPEED,PSTATUS
	.ref	COLCYC,BGND_UD1,BAKMODS,WNDWON,WNDWOFF,NO_START,WRLD
	.ref	KILBGND
	.ref	STRCNRMO,STRCNRMO_1,STRCNRM,LOWZ
	.ref	RD15FONT,RD7FONT

	.ref	P1DATA,P2DATA

	.if	DEBUG
	.ref	SLDEBUG
	.endif

	.ref	timerp1,timerp2
	.ref	palfmin
	.ref	RNDRNG,RNDRNG0
	.ref	FRANIMQ
	.ref	CYCSPECT
	.ref	GET_ADJ,aud_addnumplyrs,AUD
	.ref	ZERO_BITS
	.ref	wbmcolor_t

;symbols defined in this file

	.def	DEATHS

;uninitialized ram definitions

	.bss	cycmem		,5*16*2	;Allocate 2 x color area in ram
	.bss	statspal	,31*16 	;Statistics palette
	.bss	boanimdeath1	,16    	;CntDn for bonus anim procs to die
	.bss	boanimdeath2	,16    	;^
	.bss	scoredie	,16	;>0=Score processes die
	.bss	hitpercent1	,16	;Player1 %
	.bss	hitpercent2	,16	;Player2 %
	.bss	hitsmin1	,16	;Player1 hits per minute
	.bss	hitsmin2	,16	;Player2 ^
	.bss	score1old	,32	;P1 score before bonuses
	.bss	score2old	,32	;P2 ^

	.bss	bonusstat	,16	;Status of bonus

	.bss	fryp1palmem	,65*16	;P1 mem for pallette pulse
	.bss	fryp2palmem	,65*16	;P2 ^

	.bss	DEATHS		,16	;DEATH STATUS 0,1,2, OR 3 WHEN DONE


	.text



********************************
* Print incoming trans text

 SUBR	INCOM_TRAN		;A1=Rackup # (0-2)

       	PUSH	a1
	move	a1,a2
	movi	incom_st,a0 		;*Text
	subk	1,a2
	jrlt	it20			;0?
	jreq	it10			;1?
	movi	[0,>fcbd],a1		;Fix X for purple guy eating
	jruc	it20
it10	movi	[0,-40],a1		;Fix X
it20	clr	a2
	move	a2,@WRLD		;Do world adj
	callr	prt_xy

	PULL	A1
	move	a1,a2
	movi	incom_st2,a0 		;*Text
	subk	1,a2
	jrlt	Mit20			;0?
	jreq	Mit10			;1?
	movi	[0,>fcbd],a1		;Fix X for purple guy eating
	jruc	Mit20
Mit10	movi	[0,-40],a1		;Fix X
Mit20	clr	a2
	move	a2,@WRLD		;Do world adj
	callr	prt_xy
	RETS

incom_st
	XYTXT	PRTF15,652,55,1,"INCOMING TRANSMISSION"
	.word	-1

incom_st2
	XYTXT	0,652,45,1,"UNITED NATIONS"
	.word	-1


********************************
* Rack it up!

 SUBR	DO_RACKUP

	calla	STOPOBJS		;Keep all objs still

	movk	1,a0			;Delay start of a 2nd plyr flag
	move	a0,@NO_START
	clr	a0
	move	a0,@IRQSKYE

	movi	TUNE4,a0
	calla	snd_play1

	SLEEP	96

	clr	a0
	move	a0,@HALT
					;>Make tiles
;	movk	8*4,a1			;# Panels
;	movi	-4*>25800+>12c00,a2	;Velocity
;	movk	10,a3
;	movi	200,a5
;rp20	movi	panel_t,a14
;	calla	GPALOBJ			;Get palette & obj
;	calla	STFOBJ			;Stuff object data
;	move	a2,*a0(OXVEL),L		;Set XVEL
;	move	a3,*a0(OYPOS)		;New Y
;	addi	46,a3
;	move	a5,*a0(OZPOS)
;	movk	3,a4
;	and	a1,a4
;	subk	1,a4
;	jrne	rp30
;	addi	>25800,a2
;	movk	10,a3
;	movk	1,a4
;	xor	a4,a5			;Toggle 0 Bit
;rp30	calla	ADJSTWTL		;Adjust into world
;	calla	INSOBJ			;Insert obj
;	dsj	a1,rp20
;
;	SLEEPK	20

	calla	STOPOBJS		;Stop tiles

	callr	scores_bcdbin

;	move	@P1DATA+THITS,a1	;>Calc P1 % & hitsmin
;	move	a1,a3
;	movi	100,a0
;	mpyu	a0,a1
;	move	@P1DATA+TSHOTS,a2
;	divu	a2,a1
;	move	a1,@hitpercent1
;
;	movi	60,a0
;	mpyu	a0,a3
;	move	@timerp1,a2
;	divu	a2,a3
;	move	a3,@hitsmin1
;
;	move	@P2DATA+THITS,a1	;>Calc P2 % & hitsmin
;	move	a1,a3
;	movi	100,a0
;	mpyu	a0,a1
;	move	@P2DATA+TSHOTS,a2
;	divu	a2,a1
;	move	a1,@hitpercent2
;
;	movi	60,a0
;	mpyu	a0,a3
;	move	@timerp2,a2
;	divu	a2,a3
;	move	a3,@hitsmin2

	movi	[2,30],a8		;Color 2, 30 colors
	movi	SCOREPAL,a9
	movi	wbmcolor_t,a10		;Color table
	movk	7,a11			;Rate of cycle
	CREATE	CYCPID,CYCLE_TABLE
	movi	[1,1],a8
	movi	SCOREPAL,a9
	movi	statscolor_t,a10
	movk	3,a11
	CREATE	CYCPID,CYCLE_TABLE
	movi	[32,2],a8
	movi	SCOREPAL,a9
	movi	statscolor_t,a10
	movk	5,a11
	CREATE	CYCPID,CYCLE_TABLE

	CREATE0	score_prt
	SLEEPK	1
	CREATE0	scorebonus_prt

;	JSRP	bonus_main

;	JSRP	player_showstats

	movk	1,a0
	move	a0,@scoredie		;Kill score processes
	SLEEPK	8

	movk	5,a11
	JSRP	text_shrink

;	JSRP	player_bonuswin		;Show bonus winner!


	movi	60*7,a0
	callr	sleep_var


	callr	scores_binbcd

	movi	CYCPID,a0
       	calla	KIL1C

debug
	movi	TUNE3,a0		;Turn on dictator taunt music
	calla	snd_play1
	
	SLEEPK	25

	movi	SCOREPAL,a0		;*Color
	clr	a1			;Palette 0, Color 0
	move	*a0+,a2			;# Colors
	calla	pal_set
;	movi	DESRTPL,a0		;*Color
;	move	*a0,a2			;# Colors
;	calla	pal_getf
;	srl	8,a0
;	sll	8,a0
;	move	a0,a1
;	movi	DESRTPL+16,a0		;*Color
;	calla	pal_set

	movi	2*32*32+2*32+2,a0
	move	a0,@IRQSKYE		;Dark grey background behind dictator

	calla	ERASE_TXT
	calla	anim_killall

	movk	3,a0
;	move	a0,@TAUNTOUT		;Taunt over
	DIE



;panel_t	.long	[177,0],[0,0],RACKBLK		;x,y,img name
;	.word	200,DMAWNZ+M_NOCOLL,CLSDEAD	;zpos,flags,oid
;	.long	0,0				;xvel,yvel

statscolor_t
	COLORW	16,0,0
	COLORW	20,00,08, 24,00,12, 28,00,16, 31,00,20
	COLORW	28,00,24, 24,00,28, 20,00,31, 16,00,28
	COLORW	08,20,00, 16,24,00, 24,28,00, 31,31,00
	COLORW	20,28,00, 12,24,00, 08,20,00, 02,16,00
	COLORW	00,08,20, 00,16,24, 00,24,28, 00,31,31
	COLORW	00,20,28, 00,10,24, 00,00,20, 00,00,16
	COLORW	16,0,0
	.word	-1

engtran_s
	.byte	"ENGLISH TRANSLATION",0
	.even


********************************
* Print XY sting set if player in game
* Trashes A2-A6

 SUBRP	printifp_xy	;A0=*Plyr1 string, A1=*Plyr2 string

	PUSH	a8
	move	a1,a8

	move	@PSTATUS,a1
	btst	0,a1
	jrz	pipx10
	calla	prt0_xy		;P1

pipx10	move	@PSTATUS,a1
	btst	1,a1
	jrz	pipx20
	move	a8,a0
	calla	prt0_xy		;P2

pipx20	PULL	a8
	rets

********************************
* Print an XY string set
* A0=*XY text
* A1=Y:X offset
* Trashes A1-A5
* Rets: A0=*Next XY or End

 SUBR	prt0_xy

	clr	a1		;No offset

 SUBRP	prt_xy

	PUSH	a6,a7,a8,a9,a10,a11

	move	a0,a8			;A8=*Txt data
	move	a1,a3			;A3=Y:X offset
prtxy5	move	*a8+,a1			;Mode word
	move	*a8+,a9,L		;Scrn Y:X
	addxy	a3,a9			;+Offset
	btst	PRTOBJB,a1
	jrnz	pxy300

	movk	[0,1],a10		;Char Y:X spacing
	movi	RD7FONT,a11		;*Font
	btst	PRTF15B,a1
	jrz	prtxy10
	movi	RD15FONT,a11		;*Font
prtxy10	move	*a8+,a6			;Color
	move	a6,a0
	sll	8,a6
	or	a0,a6

	btst	PRTDECB,a1
	jrz	prtxy30
	move	*a8+,a2,L		;Binary mode
	PUSH	a8
	move	*a2,a8			;Get word
	btst	PRTLB,a1
	jrz	prtxy20
	move	*a2,a8,L		;Get long
prtxy20	calla	HEXTOASC
	jruc	prtxy40

prtxy30	btst	PRTBCDB,a1
	jruc	prtxy70
;	jrz	prtxy70
;	move	*a8+,a0,L		;BCD mode
;	move	*a0,a0,L
;	callr	bcdtoasc
;	PUSH	a8
;	move	a0,a8
prtxy40	clr	a0
	JSRP	STRCNRMO
	PULL	a8
	jruc	pxy80

prtxy70					;>String mode
	btst	PRTF8B,a1
	jrz	prtxy74
	LOCKUP
;	movi	BLLNP5,a0
;	calla	pal_find
;	move	a0,a6
;	movi	RD8FONT,a11
;	clr	a0
;	JSRP	STRCNRMO_1		;Full color font
	jruc	prtxy77

prtxy74	clr	a0			;Sleep time
	JSRP	STRCNRMO		;Print string, objects
prtxy77	addk	8,a8			;Round up
	srl	4,a8
	sll	4,a8
pxy80	move	*a8,a0			;-=End
	jrge	prtxy5

	move	a8,a0
	PULL	a6,a7,a8,a9,a10,a11
	rets

pxy300	move	a3,a10			;>Print obj
	move	*a8+,a3			;Z
	move	*a8+,a2,L		;*Img
	move	*a2,a1			;Get ISIZEX
	srl	1,a1			;/2
	move	a9,a0
	sub	a1,a0			;Center
	sll	16,a0			;X
	clr	a1
	movy	a9,a1			;Y
	movi	DMAWNZ+M_NOCOLL,a4
	movi	CLSNEUT|TYPTEXT|SUBTXT,a5
	clr	a6
	clr	a7
	move	a8,a9
	calla	BEGINOBJ
	move	a9,a8
	move	a10,a3
	jruc	pxy80


********************************
* Print an XY string set number with no objects
* Trashes A2-A7

	NOTINUSE
 SUBRP	prtnobj_xy		;A0=*XY Text

	PUSH	a8,a9,a10,a11

	move	a0,a8
pdnox5	movk	[0,1],a10		;Char y,x spacing
	movi	RD7FONT,a11		;*Font
	move	*a8+,a1			;Mode word
	btst	PRTF15B,a1
	jrz	pdnox10
	movi	RD15FONT,a11		;*Font
pdnox10	move	*a8+,a9,L		;Scrn y/x
	move	*a8+,a6			;Color
	move	a6,a2
	sll	8,a6
	or	a2,a6

	btst	PRTDECB,a1
	jrz	pdnoxx
	move	*a8+,a2,L		;Binary mode
	move	*a2,a0			;Get word
	btst	PRTLB,a1
	jrz	pdnox20
	move	*a2,a0,L		;Get long
pdnox20	PUSH	a8
	move	a0,a8
	calla	HEXTOASC
	clr	a0
	JSRP	STRCNRM
	PULL	a8

	move	*a8,a0			;-=End
	jrge	pdnox5

pdnoxx	PULL	a8,a9,a10,a11
	rets
	.endif

********************************
* Vertically shrink text
* Trashes A0-A10

 SUBRP	text_shrink		;A11=Sleep time

	movi	txtssnd,a0
	calla	snd_play1

	movk	8,a10			;Size for x2 shrinkage
txs20	move	a11,a0
	calla	PRCSLP
	clr	a8
	move	@OBJLST,a9,L		;>Find and shrink
txs40	move	*a9(OID),a0
	cmpi	CLSNEUT|TYPTEXT|SUBTXT,a0
	jrne	txs70
	move	*a9(OSIZEY),a0
	subk	1,a0			;Shrink
	jrz	txs70			;Min of 1
	cmp	a10,a0
	jrlt	txs50
	subk	1,a0			;Shrink again
	cmpi	15,a0
	jrlt	txs50
	subk	5,a0			;Shrink x7
txs50	move	a0,*a9(OSIZEY)
	movk	1,a8
txs70	move	*a9,a9,L
	jrnz	txs40

	subk	1,a10			;Lower x2 min
	move	a8,a8
	jrnz	txs20

	calla	ERASE_TXT

	RETP


********************************
* Delete text at a ZPOS
* Trashes A0-A3,A14

 SUBRP	text_delz		;A0=ZPOS

	move	a0,a2

	move	@OBJLST,a0,L
tdz40	move	*a0(OID),a1
	cmpi	CLSNEUT|TYPTEXT|SUBTXT,a1
	jrne	tdz70
	move	*a0(OZPOS),a1
	cmp	a2,a1
	jrne	tdz70
	move	*a0,a3,L	;Get * next
	calla	DELOBJ
	move	a3,a0
	jruc	tdz80
tdz70	move	*a0,a0,L
tdz80	jrnz	tdz40		;Continue?
	rets


********************************
* Delete text in a Y range
* Trashes A0-A3,A14

 SUBRP	text_delyrng		;A0=Lower Y, A1=Upper Y

	move	@WORLDTLY+16,a2
	add	a2,a1		;A1=World adjusted upper Y
	add	a0,a2		;A2=^ lower Y

	move	@OBJLST,a0,L
tdy40	move	*a0(OID),a3
	cmpi	CLSNEUT|TYPTEXT|SUBTXT,a3
	jrne	tdy70
	move	*a0(OYPOS),a3
	cmp	a2,a3
	jrlt	tdy70
	cmp	a1,a3
	jrgt	tdy70
	move	*a0,a3,L	;Get * next
	calla	DELOBJ
	move	a3,a0
	jruc	tdy80
tdy70	move	*a0,a0,L
tdy80	jrnz	tdy40		;Continue?
	rets


********************************
* Print text in rackup window (Process)

 SUBR	prt_inrackwin	;A8=*Text, A9=#Loops

	move	a9,*a13(PDATA)
	SLEEPK	30
	movk	1,a10			;Y:X spacing
	movi	RD7FONT,a11		;font table

pirw10	SLEEPK	10
	movi	-210,a0
	move	a0,@LOWZ
	movi	[187,198],a9		;Y:X
	movi	>2525,a6
	clr	a0
	PUSH	a8
	JSRP	STRCNRMO
	PULL	a8
	SLEEPK	10
	movi	20000-210,a0
	callr	text_delz
	move	*a13(PDATA),a0
	subk	1,a0
	move	a0,*a13(PDATA)
	jrgt	pirw10
	DIE

********************************
* Convert scores to binary

 SUBRP	scores_bcdbin

	move	@P1DATA+PSCORE,a0,L
	calla	BCDBIN
	move	a0,@P1DATA+PSCORE,L
	move	a0,@score1old,L
	move	@P2DATA+PSCORE,a0,L
	calla	BCDBIN
	move	a0,@P2DATA+PSCORE,L
	move	a0,@score2old,L
	rets

********************************
* Convert scores to BCD

 SUBRP	scores_binbcd

	move	@P1DATA+PSCORE,a0,L
	calla	BINBCD
	move	a0,@P1DATA+PSCORE,L
	move	@P2DATA+PSCORE,a0,L
	calla	BINBCD
	move	a0,@P2DATA+PSCORE,L
	rets


********************************
* Print players score (Process)

	LONGPD	scorecopy1	,0	;Last P1 score
	LONGPD	scorecopy2	,2	;^ P2

 SUBRP	score_prt

	clr	a0
	move	a0,@scoredie
	subk	1,a0
	move	a0,*a13(scorecopy1),L	;-1
	move	a0,*a13(scorecopy2),L

scp20	move	@PSTATUS,a8

	btst	0,a8
	jrz	scp50
	move	*a13(scorecopy1),a0,L
	move	@P1DATA+PSCORE,a1,L
	cmp	a0,a1
	jreq	scp50
	move	a1,*a13(scorecopy1),L
	movi	305,a0
	callr	text_delz
	movi	305-20000,a0
	move	a0,@LOWZ
	movi	score1_st,a0
	calla	prt0_xy		;P1

scp50	SLEEPK	3
	btst	1,a8
	jrz	scp80
	move	*a13(scorecopy2),a0,L
	move	@P2DATA+PSCORE,a1,L
	cmp	a0,a1
	jreq	scp80
	move	a1,*a13(scorecopy2),L
	movi	306,a0
	callr	text_delz
	movi	306-20000,a0
	move	a0,@LOWZ
	movi	score2_st,a0
	calla	prt0_xy		;P2

scp80	SLEEPK	3
	move	@scoredie,a0
	jrle	scp20
	DIE

score1_st
	XYNUM	PRTDEC+PRTL+PRTF15,85,16,32,P1DATA+PSCORE
	.word	-1
score2_st
	XYNUM	PRTDEC+PRTL+PRTF15,315,16,33,P2DATA+PSCORE
	.word	-1


********************************
* Print players bonus score (Process)

 SUBRP	scorebonus_prt

	movi	-1,a0
	move	a0,*a13(scorecopy1),L
	move	a0,*a13(scorecopy2),L

	movk	[0,1],a10		;Spacing
	movi	RD7FONT,a11

scbp20	move	@PSTATUS,a2
	btst	0,a2
	jrz	scbp50
	move	@P1DATA+PSCORE,a8,L	;>Calc bonus score
	move	*a13(scorecopy1),a0,L
	cmp	a0,a8
	jreq	scbp50
	move	a8,*a13(scorecopy1),L
	movi	300,a0
	callr	text_delz
	move	@score1old,a0,L
	movi	300-20000,a1
	movi	>2020,a6
	movi	[35,85],a9		;Scrn y/x
	callr	scoreb_prt2

scbp50	SLEEPK	3
	move	@PSTATUS,a2
	btst	1,a2
	jrz	scbp80
	move	@P2DATA+PSCORE,a8,L	;>Calc bonus score
	move	*a13(scorecopy2),a0,L
	cmp	a0,a8
	jreq	scbp80
	move	a8,*a13(scorecopy2),L
	movi	301,a0
	callr	text_delz
	move	@score2old,a0,L
	movi	301-20000,a1
	movi	>2121,a6
	movi	[35,315],a9		;Scrn y/x
	callr	scoreb_prt2

scbp80	SLEEPK	3
	move	@scoredie,a0
	jrle	scbp20
	DIE


scoreb_prt2
	move	a1,@LOWZ
	sub	a0,a8
	calla	HEXTOASC
	clr	a0			;No sleep
	JSRP	STRCNRMO		;Print
	rets


********************************
* Variable sleep (call it)

 SUBR	sleep_var	;A0=Sleep time

	PUSHP	a8,a9
	PULL	a8
	move	a0,a9
sv20	SLEEPK	1
	move	@SWITCH+16,a1	;Chk for impatience
	not	a1
	andi	>24,a1
	jrnz	sv50
	dsj	a9,sv20	
sv50	move	a8,a0
	PULLP	a8,a9
	jump	a0





********************************


	NOTINUSE


********************************
* Give collection bonus


	.bss	bonuscnt	,32	;P1/P2 item cnt (word*2)

 SUBRP	bonus_main

;	movk	3,a0
;	move	a0,@PSTATUS	;DEBUG
;
;	movi	200,a0		;>DEBUG
;	calla	RNDRNG0
;	move	a0,@P1DATA+TFLAGS
;	movi	200,a0
;	calla	RNDRNG0
;	move	a0,@P2DATA+TFLAGS
;
;	movi	200,a0
;	calla	RNDRNG0
;	move	a0,@P1DATA+CASHCNT
;	movi	200,a0
;	calla	RNDRNG0
;	move	a0,@P2DATA+CASHCNT
;
;	movi	200,a0
;	calla	RNDRNG0
;	move	a0,@P1DATA+THSTGS
;	movi	200,a0
;	calla	RNDRNG0
;	move	a0,@P2DATA+THSTGS

	movi	collectb_s,a8
	movi	100,a9
	CREATE0	prt_inrackwin
	move	a0,-*a12,L

	movi	-1,a0
	move	a0,@bonusstat

	movi	bonus_st,a0
	calla	prt0_xy

	move	@PSTATUS,a6
	cmpi	3,a6
	jreq	bm15			;Two plyrs?

	movi	115,a1
	btst	0,a6
	jrz	bm10			;P1 off?
	movi	285,a1
bm10	movi	joinin_st,a0
	calla	prt_xy

bm15	btst	0,a6
	jrz	bm20
	movi	bonusp1_as,a8
	CREATE	ANIMPID,anim_script	;P1

bm20	btst	1,a6
	jrz	bm40
	movi	bonusp2_as,a8
	CREATE	ANIMPID2,anim_script	;P2
bm40
	movi	bonus1p1_st,a0
	movi	bonus1p2_st,a1
	movi	210,a2
	movi	[70,116],a9		;YX
	movi	60,a10
	movi	TFLAGS,a11
	JSRP	bonus_cntup		;Flags

	clr	a0
	move	a0,@bonusstat

	movi	bonus2p1_st,a0
	movi	bonus2p2_st,a1
	movi	211,a2
	movi	[108,116],a9		;YX
	movi	40,a10
	movi	CASHCNT,a11
	JSRP	bonus_cntup		;Crystals

	movk	1,a0
	move	a0,@bonusstat

	movi	bonus3p1_st,a0
	movi	bonus3p2_st,a1
	movi	212,a2
	movi	[146,116],a9		;YX
	movi	100,a10
	movi	THSTGS,a11
	JSRP	bonus_cntup		;Hostages

	movi	60*2,a0			;4
	callr	sleep_var

	move	*a12+,a0,L
	clr	a1
	move	a1,*a0(PDATA)		;Stop window text

	movk	2,a0
	move	a0,@bonusstat
	movi	55,a0
	movi	200,a1
	callr	text_delyrng
	SLEEPK	30

	RETP

collectb_s
	.byte	"COLLECTION BONUS",0
	.even
joinin_st		       
	XYTXT	PRTF15,0,104,3,"HELP!"
	XYTXT	PRTF15,0,86,3,"JOIN IN!"
;	XYTXT	PRTF15,0,86,3,"JOIN IN"
;	XYTXT	PRTF15,0,104,3,"SCUM!"
	.word	-1



 SUBRP	bonus_cntup	;A0=*P1_st, A1=*P2_st, A2=Z
			;A9=Base YX, A10=Pts each, A11=Plyr data offset
	move	@PSTATUS,a3
	subk	3,a3
	jrnz	bcu10
	sll	1,a10			;*2 pts for two players

bcu10	PUSH	a2
	callr	printifp_xy

	movi	bonuscnt,a8
	CREATE0	bonus_prtitem		;Display
	move	a0,-*a12,L
	PULL	a2
	move	a2,*a0(bonusz)

	clr	a0
	move	a0,*a8,L		;Cnt=0

	movi	racksup,a0
	calla	snd_play1

bcu20	move	@SWITCH+16,a1		;Chk for impatience
	not	a1
	andi	>24,a1
	jrnz	bcu25
	SLEEPK	1

bcu25	move	@PSTATUS,a2
	clr	a3

	btst	0,a2
	jrz	bcu30
	move	*a8,a0
	movi	P1DATA,a1
	add	a11,a1
	move	*a1,a1
	cmp	a1,a0
	jrge	bcu30			;Count maxed?
	addk	1,a0
	move	a0,*a8
	movk	1,a3
	move	@P1DATA+PSCORE,a0,L
	add	a10,a0
	move	a0,@P1DATA+PSCORE,L

bcu30	btst	1,a2
	jrz	bcu60
	move	*a8(16),a0
	movi	P2DATA,a1
	add	a11,a1
	move	*a1,a1
	cmp	a1,a0
	jrge	bcu60			;Count maxed?
	addk	1,a0
	move	a0,*a8(16)
	movk	1,a3
	move	@P2DATA+PSCORE,a0,L
	add	a10,a0
	move	a0,@P2DATA+PSCORE,L

bcu60	move	a3,a3
	jrnz	bcu20			;More to do?

	movi	rackoff,a0		;End
	calla	snd_play1
	SLEEPK	5

	move	*a8+,a1			;P1
	move	*a8,a2			;P2
	move	@WORLDTLX+16,a10
	cmp	a2,a1
	jrhi	bcu200			;P1 won?
	jrlo	bcu180			;P2 won?
	move	@P1DATA+PSCORE,a0,L	;Tie!
	move	@P2DATA+PSCORE,a1,L
	cmp	a1,a0
	jrhs	bcu200			;P1 won?
bcu180	addi	190,a10			;Min X of tiles
bcu200	movi	190,a11			;X range of tiles
	movk	3,a8
bcu220	movi	DMACNZ+M_NOCOLL,a3
	callr	bonus_flashblk
	SLEEPK	2
	movi	DMAWNZ+M_NOCOLL,a3
	callr	bonus_flashblk
	SLEEPK	8
	dsj	a8,bcu220

	move	*a12+,a0,L
	calla	KILL
	movi	60*1,a0
	callr	sleep_var

	RETP


********************************
* Print bonus item count & score (Process)

	WORDPD	bonusz	,0	;ZPOS for text, set by creator


 SUBRP	bonus_prtitem	;A8=*P1/2 item cnt, A9=Y:X, A10=Pts each

	movi	RD7FONT,a11

bpilp	move	*a13(bonusz),a0
	callr	text_delz

	move	@PSTATUS,a2
	move	a10,a4			;A4=Pts
	movk	[0,1],a10		;Spacing

	btst	0,a2
	jrz	bpi50

	PUSH	a8,a9
	move	*a8,a8			;Get P1 cnt
	move	a8,a3
	movi	>2525,a6
	callr	strcnrmo_nosleep	;Print cnt
	callr	strcnrmo_nosleep2	;Print score
	PULL	a8,a9

bpi50	btst	1,a2
	jrz	bpi80

	PUSH	a8,a9
	addi	160,a9			;+X
	move	*a8(16),a8		;Get P2 cnt
	move	a8,a3
	movi	>2525,a6
	callr	strcnrmo_nosleep	;Print cnt
	callr	strcnrmo_nosleep2	;Print score
	PULL	a8,a9

bpi80	move	a4,a10
	SLEEPK	2
	jruc	bpilp


 SUBRP	strcnrmo_nosleep2
	mpyu	a4,a3
	move	a3,a8
	addi	45,a9			;+X

 SUBRP	strcnrmo_nosleep

	PUSH	a9
	calla	HEXTOASC
	move	*a13(bonusz),a0
	subi	20000,a0
	move	a0,@LOWZ
	clr	a0			;No sleep
	JSRP	STRCNRMO
	PULL	a9
	rets


bonusp2_as				;Scripts
	ASBXY	160,0
bonusp1_as
	ASADDW	1,animscnt
	ASNEW	bonusflag_t
	ASFRA	flag_l,>20,100

bas10	ASSLP	2
	ASJMPEQ	-1,bonusstat,bas10

	ASNEW	bonusgem_t
	ASFRA	gems_l,>21,100

bas20	ASSLP	2
	ASJMPEQ	0,bonusstat,bas20

	ASNEW	bonushstg_t

bas30	ASSLP	2
	ASJMPEQ	1,bonusstat,bas30

	ASKIL	0,>ff
	ASDELM	0,>ff

	ASADDW	-1,animscnt
	ASEND

bonus_st
	XYOBJ	PRTOBJ,200,16,500,TSCORE
	.word	-1

bonus1p1_st
	XYTXT	0,116,70,35,"X     ="
	.word	-1
bonus1p2_st
	XYTXT	0,276,70,35,"X     ="
	.word	-1

bonus2p1_st
	XYTXT	0,116,108,35,"X     ="
	.word	-1
bonus2p2_st
	XYTXT	0,276,108,35,"X     ="
	.word	-1

bonus3p1_st
	XYTXT	0,116,146,35,"X     ="
	.word	-1
bonus3p2_st
	XYTXT	0,276,146,35,"X     ="
	.word	-1

bonusflag_t
	ASITEMN	50,55,FLG1,220,DMAWNZ,>20
	.word	-1000
bonusgem_t
	ASITEMN	50,90,GEMS1,220,DMAWNZ,>21
	.word	-1000
bonushstg_t
	ASITEMN	50,130,HSTGHD,220,DMAWNZ,>21
	.word	-1000


flag_l	LW	FLG1,5
	LW	FLG2,5
	LW	FLG3,5
	LW	FLG4,5
	LWL0	FLG5,5

gems_l	LW	GEMS1,4
	LW	GEMS2,4
	LW	GEMS3,4
	LW	GEMS4,4
	LW	GEMS3,4
	LW	GEMS2,4
	LWL0	GEMS1,4


 SUBRP	bonus_flashblk		;A3=OFLAGS, A10=XMin, A11=XWidth

	rets

	move	@OBJLST,a1,L
bfb20	move	*a1(OZPOS),a0
	subi	200,a0
	subk	1,a0
	jrhi	bfb30			;Not 200-201?
	move	*a1(OXPOS),a0
	sub	a10,a0
	cmp	a11,a0
	jrhi	bfb30
	move	a3,*a1(OCTRL)	;FIX
	movi	>909,a0
	move	a0,*a1(OCONST)
bfb30	move	*a1,a1,L
	jrnz	bfb20
	rets


********************************
* Show player stats and give bonuses

 SUBRP	player_showstats

	movi	gamestat_s,a8
	movi	100,a9
	CREATE0	prt_inrackwin
	move	a0,-*a12,L

	clr	a7			;A7=Bonus pts Y:X offset

	move	@PSTATUS,a0
	subk	3,a0
	jrne	pst20
	movi	statsbo_st,a0
	calla	prt0_xy

pst20	movi	statssnd_t,a8
	movi	stats_st,a9
	movi	statsp1_st,a10
	movi	statsp2_st,a11

pst50	move	*a8+,a0,L
	calla	snd_play1
	move	@PSTATUS,a6
	move	a9,a0
	calla	prt0_xy
	move	a0,a9
	btst	0,a6			;P1
	jrz	pst300
	move	a10,a0
	calla	prt0_xy
	move	a0,a10
pst300	btst	1,a6			;P2
	jrz	pst310

	movi	-400,a0			;So general is above number
	move	a0,@LOWZ

	move	a11,a0
	calla	prt0_xy
	move	a0,a11

pst310	cmpi	3,a6
	jrne	pst400			;Not 2 plyrs?
	move	*a10(-32),a2,L
	move	*a11(-32),a3,L
	cmpi	P1DATA+TMINEDTH,a2
	jrne	pst330			;Normal compare?
	SWAP	a2,a3
pst330	move	*a2,a2
	move	*a3,a3
	movi	P1DATA+PSCORE,a4
;	movi	rackp1p,a0
	clr	a1
	cmp	a3,a2
	jrz	pst380			;Same stats?
	jrhi	pst350			;P1 higher?
	movi	P2DATA+PSCORE,a4
;	movi	rackp2p,a0
	addi	300,a7			;P2 offset
pst350	move	*a4,a2,L		;Give points
	addi	1000,a2
	move	a2,*a4,L
;	calla	snd_play1
	movi	statspts_st,a0
	move	a7,a1
	calla	prt_xy
pst380	srl	16,a7			;X=0
	addk	10,a7			;Y=Y+10
	sll	16,a7

pst400	move	a7,-*a12,L
	SLEEPK	4
	movk	9,a0
	callr	sleep_var
	move	*a12+,a7,L
	move	*a9,a0
	addk	1,a0
	jrnz	pst50			;End?

	movi	60*6,a0
	callr	sleep_var

	move	*a12+,a0,L
	clr	a1
	move	a1,*a0(PDATA)		;Stop window text

	RETP


gamestat_s
	.byte	"GAME STATISTICS",0
	.even
statssnd_t	
	.long	stats1,stats2,stats3,stats4,stats5,stats6,stats7,stats8
	.long	stats9,stats10,stats11,stats12

SY	.equ	55

statsbo_st
	XYOBJ	PRTOBJ,50,45,280,BWORD
	XYOBJ	PRTOBJ,350,45,280,BWORD
	.word	-1
statspts_st
	XYOBJ	PRTOBJ,50,SY,280,FIVE
	.word	-1
stats_st
	XYTXT	0,200,SY,2,"SHOTS FIRED"
	XYTXT	PRTE,200,SY+10,3,"ENEMY HITS"
	XYTXT	PRTE,200,SY+20,4,"HIT PERCENTAGE"
;	XYTXT	PRTE,200,SY+30,5,"HITS PER MINUTE"
	XYTXT	PRTE,200,SY+30,5,"WEAPONS PICKED UP"
	XYTXT	PRTE,200,SY+40,6,"BOMBS USED"
	XYTXT	PRTE,200,SY+50,7,"MISSILE STRIKES"
	XYTXT	PRTE,200,SY+60,8,"BIG STUFF DESTROYED"
	XYTXT	PRTE,200,SY+70,9,"EXTRA MEN COLLECTED"
	XYTXT	PRTE,200,SY+80,10,"MINES STEPPED ON"
	XYTXT	PRTE,200,SY+90,11,"KEYS COLLECTED"
	.word	-1	;End

statsp1_st
	XYNUM	PRTDEC,95,SY,2,P1DATA+TSHOTS
	XYNUM	PRTDEC+PRTE,95,SY+10,3,P1DATA+THITS
	XYNUM	PRTDEC+PRTE,95,SY+20,4,hitpercent1
;	XYNUM	PRTDEC+PRTE,95,SY+30,5,hitsmin1
	XYNUM	PRTDEC+PRTE,95,SY+30,5,P1DATA+TWPNS
	XYNUM	PRTDEC+PRTE,95,SY+40,6,P1DATA+BMBSUSED
	XYNUM	PRTDEC+PRTE,95,SY+50,7,P1DATA+TMISLS
	XYNUM	PRTDEC+PRTE,95,SY+60,8,P1DATA+TBIGSTF
	XYNUM	PRTDEC+PRTE,95,SY+70,9,P1DATA+TEARNED
	XYNUM	PRTDEC+PRTE,95,SY+80,10,P1DATA+TMINEDTH
	XYNUM	PRTDEC+PRTE,95,SY+90,11,P1DATA+TKEYS
	.word	-1

statsp2_st
	XYNUM	PRTDEC,305,SY,2,P2DATA+TSHOTS
	XYNUM	PRTDEC+PRTE,305,SY+10,3,P2DATA+THITS
	XYNUM	PRTDEC+PRTE,305,SY+20,4,hitpercent2
;	XYNUM	PRTDEC+PRTE,305,SY+30,5,hitsmin2
	XYNUM	PRTDEC+PRTE,305,SY+30,5,P2DATA+TWPNS
	XYNUM	PRTDEC+PRTE,305,SY+40,6,P2DATA+BMBSUSED
	XYNUM	PRTDEC+PRTE,305,SY+50,7,P2DATA+TMISLS
	XYNUM	PRTDEC+PRTE,305,SY+60,8,P2DATA+TBIGSTF
	XYNUM	PRTDEC+PRTE,305,SY+70,9,P2DATA+TEARNED
	XYNUM	PRTDEC+PRTE,305,SY+80,10,P2DATA+TMINEDTH
	XYNUM	PRTDEC+PRTE,305,SY+90,11,P2DATA+TKEYS
	.word	-1


********************************
* Player bonus winner animations


 SUBRP	player_bonuswin

	movi	plbwp1o_as,a8		;P1 only initial script
	clr	a9			;A9=Winner message #
	move	@PSTATUS,a0
	btst	1,a0
	jrz	pbw90

	movi	plbwp2o_as,a8		;P2 only initial script
	movk	1,a9
	btst	0,a0
	jrz	pbw90

	movi	plbwp1w_as,a8		;P1 win initial script
	movk	2,a9

	move	@P1DATA+PSCORE,a0,L
	move	@P2DATA+PSCORE,a1,L
	cmp	a1,a0			;P1 score > P2 score?
	jrhi	pbw90
	jrlo	pbw80			;P1sc < P2sc
	move	@score1old,a3,L
	move	@score2old,a4,L
	cmp	a4,a3			;Score same!
	jrlo	pbw90			;P1 old < P2 old?

pbw80	movi	plbwp2w_as,a8		;P2 win initial script
	movk	3,a9

pbw90	CREATE	ANIMPID,prt_winnertxt
	CREATE	ANIMPID,anim_script

	movi	1*32*32+15*32+27,a0	;Bkgnd color
	move	a0,@IRQSKYE

	move	@OBJLST,a1,L		;>Tiles fly away
pbw200	move	*a1(OZPOS),a0
	subi	200,a0
	subk	1,a0
	jrhi	pbw230
	movk	8,a2			;Vel
	btst	0,a0
	jrnz	pbw220
	neg	a2			;-Vel
pbw220	move	a2,*a1(OYVEL+16)

pbw230	move	*a1,a1,L
	jrnz	pbw200

	SLEEP	60

	move	@OBJLST,a0,L		;>Delete tiles
pbw300	move	*a0(OZPOS),a2
	subi	200,a2
	subk	1,a2
	jrhi	pbw330
	move	*a0,a2,L		;Get * to next obj
	calla	DELOBJ			;Kill
	move	a2,a0
	jruc	pbw340
pbw330	move	*a0,a0,L
pbw340	jrnz	pbw300

	movi	200,a0
	callr	sleep_var

;	movi	plbwpal_t,a0		;*Palette list
;	movk	5,a1
;	movi	>40,a2
;	move	a2,@palfmin
;	calla	FADEOUT2
;
;	SLEEPK	30

	RETP


********************************
* A9=Message # 0-3 (Process)
* 0=PLYR 1 ONLY
* 1=PLYR 2 ONLY
* 2=PLYR 1 WINS OVER PLYR 2
* 3=PLYR 2 WINS OVER PLYR 1

 SUBRP	prt_winnertxt

	sll	5,a9
	addi	winmsgs,a9
	move	*a9,a8,L		;*Message
	movi	34,a9
	jruc	prt_inrackwin

winmsgs	.long	win0_s,win1_s,win2_s,win3_s

;COME UP WITH MORE CLEVER TEXT HERE!
win0_s	.byte	"PLAYER ONE IS GREAT!",0
win1_s	.byte	"PLAYER TWO IS GREAT!",0
win2_s	.byte	"PLAYER ONE KICKED BUTT!",0
win3_s	.byte	"PLAYER TWO KICKED BUTT!",0
	.even


;plbwpal_t
;	.long	0,BIGPL1,GUNSP1,CLDS9,DESRTPL,BIGPL2,GUNSP2,0


plbwp1o_as
	ASNEW	plyr1wnew_t
	ASXY	>40,>1f,70,0
	ASJMP	plbw_as

plbwp2o_as
	ASNEW	plyr2wnew_t
	ASXY	>40,>1f,-50,0
	ASSVL	BIGPL2
	ASPAL	>41
	ASPAL	>54
	ASPAL	>55
	ASSVL	GUNSP2
	ASPAL	>42
	ASPAL	>48
	ASJMP	plbw_as

plbwp1w_as
	ASNEW	plyr1wnew_t
	ASNEW	plyr2lnew_t
	ASSVL	BIGPL2
	ASPAL	>81
	ASSVL	GUNSP2
	ASPAL	>82
	ASPAL	>88
	ASRUN	plbw2txt_as
	ASJMP	plbw_as

plbwp2w_as
	ASNEW	plyr1lnew_t
	ASNEW	plyr2wnew_t
	ASSVL	BIGPL2
	ASPAL	>41
	ASPAL	>54
	ASPAL	>55
	ASSVL	GUNSP2
	ASPAL	>42
	ASPAL	>48
	ASRUN	plbw1txt_as

plbw_as
	ASADDW	1,animscnt
	ASNEW	plyrbgnew_t
	ASFRA	ribbonb_l,>48,-1
	ASFRA	ribbonl_l,>88,-1

	ASRUN	pbwcloud1_as
	ASRUN	pbwcloud2_as
	ASRUN	pbwcloud3_as
	ASRUN	pbwsnd_as
	ASSLP	90
	ASFRA	plhdcc_l,>4c,1
	ASFRA	plhdmm_l,>4d,1
	ASLAB	5
	ASXY	0,>ff,0,1	;Pan up
	ASDSJS1
	ASLAB	20
	ASXY	0,>ff,0,2
	ASDSJS1
	ASLAB	5
	ASXY	0,>ff,0,1
	ASDSJS1

	ASANI	LBOW2,>54
	ASANI	WRISTBND2,>50
	ASANI	HAND2,>55
	ASANI	GUN2,>51
	ASXY	>44,1,-1000,0	;Put middle strap on screen
	ASSLP	4
	ASANI	LBOW1,>54
	ASANI	WRISTBND1,>50
	ASANI	HAND1,>55
	ASANI	GUN1,>51
	ASXY	>44,1,-1000,0	;Straps off screen

	ASLAB	40
	ASSND	rackgun
	ASLAB	2
	ASXY	>50,>7,0,1	;Shake gun
	ASXY	>56,0,-1000,0	;Show flame
	ASDSJS1
	ASLAB	2
	ASXY	>50,>7,0,-1
	ASXY	>56,0,1000,0	;Hide flame
	ASDSJS1
	ASDSJ

	ASSLP	30
	ASLAB	5
	ASXY	0,>ff,0,-1	;Pan down
	ASDSJS1
	ASLAB	20
	ASXY	0,>ff,0,-2
	ASDSJS1
	ASLAB	5
	ASXY	0,>ff,0,-1
	ASDSJS1

	ASSLP	20
	ASANI	LBOW2,>54
	ASANI	WRISTBND2,>50
	ASANI	HAND2,>55
	ASANI	GUN2,>51
	ASXY	>44,1,1000,0	;Middle strap on screen
	ASSLP	4
	ASANI	LBOW3,>54
	ASANI	WRISTBND3,>50
	ASANI	HAND3,>55
	ASANI	GUN3,>51
	ASXY	>44,1,1000,0	;1st strap on screen
	ASADDW	-1,animscnt
	ASEND


pbwcloud1_as
	ASLAB	4
	ASLAB	188
	ASXY	>10,0,1,0
	ASSLP	4
	ASDSJ
	ASXY	>10,0,-188,0
	ASDSJ
	ASEND
pbwcloud2_as
	ASLAB	4
	ASLAB	188
	ASXY	>11,0,1,0
	ASSLP	5
	ASDSJ
	ASXY	>11,0,-188,0
	ASDSJ
	ASEND
pbwcloud3_as
	ASLAB	4
	ASLAB	188
	ASXY	>12,0,1,0
	ASSLP	6
	ASDSJ
	ASXY	>12,0,-188,0
	ASDSJ
	ASEND


pbwsnd_as			;Sounds
	ASSLP	130
	ASSND	shout
	ASSLP	170
	ASSND	gigle1
	ASEND


CLY	.equ	142

plyrbgnew_t	;X,Y,img name,Z,flags,oid

	ASITEMN	12,-40,CLOUD,25,DMAWNZ+M_FLIPH,>10
	ASITEMN	200,-40,CLOUD,25,DMAWNZ+M_FLIPH,>10
	ASITEMN	388,-40,CLOUD,25,DMAWNZ+M_FLIPH,>10
	ASITEMN	12,-10,CLOUD,24,DMAWNZ+M_FLIPH,>11
	ASITEMN	200,-10,CLOUD,24,DMAWNZ+M_FLIPH,>11
	ASITEMN	388,-10,CLOUD,24,DMAWNZ+M_FLIPH,>11
	ASITEMN	-178,20,CLOUD,23,DMAWNZ,>12
	ASITEMN	10,20,CLOUD,23,DMAWNZ,>12
	ASITEMN	198,20,CLOUD,23,DMAWNZ,>12
	ASITEMN	10,CLY,CLIFF3A,30,DMAWNZ,8
	ASITEMN	128,CLY,CLIFF3A,30,DMAWNZ+M_FLIPH,8
	ASITEMN	129,CLY+6,CLIFF2A,30,DMAWNZ,8
	ASITEMN	186,CLY-1,CLIFF3A,30,DMAWNZ,8
	ASITEMN	304,CLY-1,CLIFF3A,30,DMAWNZ+M_FLIPH,8
	ASITEMN	355,CLY+7,CLIFF2A,30,DMAWNZ+M_FLIPH,8
	ASITEMN	356,CLY+1,CLIFF3A,30,DMAWNZ,8
	.word	-1000

P1X	.equ	120
P1Y	.equ	23
P1LX	.equ	70
P1LY	.equ	30
P2X	.equ	260
P2Y	.equ	23
P2LX	.equ	305
P2LY	.equ	30

plyr1wnew_t
	ASITEMN	P1X,P1Y,CCHED1,51,DMAWNZ,>4c
	ASITEMN	P1X,P1Y,RIB1,45,DMAWNZ,>48
	ASITEMN	P1X,P1Y,BDBOD1,50,DMAWNZ,>40
	ASITEMN	P1X,P1Y,BDBOD2,50,DMAWNZ,>40
	ASITEMN	P1X,P1Y,RTARMBND,51,DMAWNZ,>40
	ASITEMN	P1X,P1Y,RTLBOW1,52,DMAWNZ,>40
	ASITEMN	P1X,P1Y,RTWRISTBND,53,DMAWNZ,>40
	ASITEMN	P1X,P1Y,RTHAND1,53,DMAWNZ,>40
	ASITEMN	P1X,P1Y,LFTARMBND,52,DMAWNZ,>40
	ASITEMN	P1X,P1Y,LBOW3,51,DMAWNZ,>54
	ASITEMN	P1X,P1Y,WRISTBND3,52,DMAWNZ,>50
	ASITEMN	P1X,P1Y,HAND3,54,DMAWNZ,>55
	ASITEMN	P1X,P1Y,GUN3,53,DMAWNZ,>51
	ASITEMN	P1X,P1Y,STRAP,51,DMAWNZ,>44
	ASITEMN	P1X+1000,P1Y,STRAPA,51,DMAWNZ,>45
	ASITEMN	P1X+1054,P1Y-33,T72BLAST1,55,DMAWNZ+M_FLIPV,>56
	ASITEMN	P1X+2054,P1Y-33,T72BLAST2,55,DMAWNZ+M_FLIPV,>56
	.word	-1000

plyr2wnew_t
	ASITEMN	P2X,P2Y,MMHED1,51,DMAWNZ+M_FLIPH,>4d
	ASITEMN	P2X,P2Y-5,RIB1,45,DMAWNZ,>48
	ASITEMN	P2X,P2Y,BDBOD1,50,DMAWNZ+M_FLIPH,>41
	ASITEMN	P2X,P2Y,BDBOD2,50,DMAWNZ+M_FLIPH,>42
	ASITEMN	P2X,P2Y,RTARMBND,51,DMAWNZ+M_FLIPH,>40
	ASITEMN	P2X,P2Y,RTLBOW1,52,DMAWNZ+M_FLIPH,>41
	ASITEMN	P2X,P2Y,RTWRISTBND,53,DMAWNZ+M_FLIPH,>40
	ASITEMN	P2X,P2Y,RTHAND1,53,DMAWNZ+M_FLIPH,>41
	ASITEMN	P2X,P2Y,LFTARMBND,52,DMAWNZ+M_FLIPH,>40
	ASITEMN	P2X,P2Y,LBOW3,51,DMAWNZ+M_FLIPH,>54
	ASITEMN	P2X,P2Y,WRISTBND3,52,DMAWNZ+M_FLIPH,>50
	ASITEMN	P2X,P2Y,HAND3,54,DMAWNZ+M_FLIPH,>55
	ASITEMN	P2X,P2Y,GUN3,53,DMAWNZ+M_FLIPH,>51
	ASITEMN	P2X,P2Y,STRAP,51,DMAWNZ+M_FLIPH,>44
	ASITEMN	P2X+1000,P2Y,STRAPA,51,DMAWNZ+M_FLIPH,>45
	ASITEMN	P2X+945,P2Y-33,T72BLAST1,55,DMAWNZ+M_FLIPV,>56
	ASITEMN	P2X+1945,P2Y-33,T72BLAST2,55,DMAWNZ+M_FLIPV,>56
	.word	-1000

plyr1lnew_t
	ASITEMN	P1LX,P1LY,SMHEAD1,40,DMAWNZ+M_FLIPH,>80
	ASITEMN	P1LX-10,P1LY,LILRIB1,35,DMAWNZ,>88
	ASITEMN	P1LX,P1LY,SMBOD1,40,DMAWNZ+M_FLIPH,>81
	ASITEMN	P1LX,P1LY,SMBOD2,40,DMAWNZ+M_FLIPH,>82
	ASITEMN	P1LX,P1LY,SMARMBND,41,DMAWNZ+M_FLIPH,>80
	ASITEMN	P1LX,P1LY,SMWRISTS,41,DMAWNZ+M_FLIPH,>80
	.word	-1000

plyr2lnew_t
	ASITEMN	P2LX,P2LY,SMHEAD2,40,DMAWNZ,>80
	ASITEMN	P2LX-1,P2LY-3,LILRIB1,35,DMAWNZ,>88
	ASITEMN	P2LX,P2LY,SMBOD1,40,DMAWNZ,>81
	ASITEMN	P2LX,P2LY,SMBOD2,40,DMAWNZ,>82
	ASITEMN	P2LX,P2LY,SMARMBND,41,DMAWNZ,>80
	ASITEMN	P2LX,P2LY,SMWRISTS,41,DMAWNZ,>80
	.word	-1000


ribbonb_l
	LW	RIB1,4
	LW	RIB2,4
	LW	RIB3,4
	LW	RIB4,4
	LWL0	RIB5,4

ribbonl_l
	LW	LILRIB1,3
	LW	LILRIB2,4
	LW	LILRIB3,3
	LW	LILRIB4,4
	LWL0	LILRIB5,4

plhdcc_l
	LW	CCHED1,30
	LW	CCHED2,8
	LW	CCHED3,8
	LW	CCHED4,60
	LW	CCHED3,5
	LW	CCHED2,5
	LW	CCHED1,70
	LW	CCHED5,5
	LWL0	CCHED6,15

plhdmm_l
	LW	MMHED1,30
	LW	MMHED2,8
	LW	MMHED3,8
	LW	MMHED4,60
	LW	MMHED3,5
	LW	MMHED2,5
	LW	MMHED1,70
	LW	MMHED5,5
	LWL0	MMHED6,15

plbw1txt_as
	ASSLP	140
	ASNEW	plbw1balloon_t
	ASTXTR	plbw1ltxt_t
	ASJMP	plbw280

plbw2txt_as
	ASSLP	140
	ASNEW	plbw2balloon_t
	ASTXTR	plbw2ltxt_t
plbw280	ASSLP	140
	ASDEL	2
	ASTXTK
	ASEND

plbw1balloon_t
	ASITEMN	P1LX+0,P1LY+8-20,BLLN1,46,DMAWNZ,2
	ASITEMN	P1LX+20,P1LY+8-20,BLLN2,46,DMAWNZ,2
	ASITEMN	P1LX+40,P1LY+8-20,BLLN2,46,DMAWNZ,2
	ASITEMN	P1LX+80,P1LY+8-20,BLLN1,46,DMAWNZ+M_FLIPH,2
	ASITEMN	P1LX+40,P1LY+40-20,BOON2B,47,DMAWNZ+M_FLIPH,2
	.word	-1000

plbw2balloon_t
	ASITEMN	P2LX-80,P2LY+8-20,BLLN1,46,DMAWNZ,2
	ASITEMN	P2LX-60,P2LY+8-20,BLLN2,46,DMAWNZ,2
	ASITEMN	P2LX-40,P2LY+8-20,BLLN2,46,DMAWNZ,2
	ASITEMN	P2LX+0,P2LY+8-20,BLLN1,46,DMAWNZ+M_FLIPH,2
	ASITEMN	P2LX-40,P2LY+40-20,BOON2B,47,DMAWNZ,2
	.word	-1000

plbw1ltxt_t	;Lost
	.word	10
	.long	plbw1l1_st,plbw1l2_st,plbw1l3_st,plbw1l4_st
	.long	plbw1l5_st,plbw1l6_st,plbw1l7_st
	.long	plbw1l8_st,plbw1l9_st,plbw1l10_st
plbw1l1_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I SUCK AT"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"THIS GAME"
	.word	-1
plbw1l2_st				   
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I WILL"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"FEAST NOW"
	.word	-1
plbw1l3_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I NEED"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"MORE CASH."
	.word	-1
plbw1l4_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"HE IS A"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"DOG"
	.word	-1
plbw1l5_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"PLAYER 2"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"IS A JERK"
	.word	-1
plbw1l6_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"THAT SCUM"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"CHEATED"
	.word	-1
plbw1l7_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"HOW DOES"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"HE DO IT?"
	.word	-1
plbw1l8_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"PUNCH"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"PLAYER 2"
	.word	-1
plbw1l9_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I NEED"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"A DRINK..."
	.word	-1
plbw1l10_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I WANT MY"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"MOMMY"
	.word	-1
plbw1l11_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I SWEAT"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"LIKE A PIG"
	.word	-1

plbw2ltxt_t	;Lost
	.word	10
	.long	plbw2l1_st,plbw2l2_st,plbw2l3_st,plbw2l4_st
	.long	plbw2l5_st,plbw2l6_st,plbw2l7_st
	.long	plbw2l8_st,plbw2l9_st,plbw2l10_st
plbw2l1_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"PLAYER 1"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"IS A DORK"
	.word	-1
plbw2l2_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"THAT BOY"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"IS GOOD..."
	.word	-1
plbw2l3_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"HOW CAN I"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"BEAT HIM?"
	.word	-1
plbw2l4_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"I NEED"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"MUSCLES"
	.word	-1
plbw2l5_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"PLAYER 1"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"WAS LUCKY"
	.word	-1
plbw2l6_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"THAT GUY'S"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"A BIG JERK"
	.word	-1
plbw2l7_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"I SUCK AT"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"ALL GAMES"
	.word	-1
plbw2l8_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"I CAN'T"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"BEAT HIM"
	.word	-1
plbw2l9_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"I CAN"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"PLAY PONG"
	.word	-1
plbw2l10_st
	XYTXT	PRTF8,P2LX-40,P2LY+12-20,2,"I SUCK"
	XYTXT	PRTF8,P2LX-40,P2LY+22-20,2,"BIG TIME"
	.word	-1
plbw2l11_st
	XYTXT	PRTF8,P1LX+40,P1LY+12-20,2,"I SUCK AT"
	XYTXT	PRTF8,P1LX+40,P1LY+22-20,2,"THIS GAME"
	.word	-1




	.endif






********************************
********************************
* Extra junk!!!

	NOTINUSE

********************************
* Calls DO_RACKUP

	.ref	KILALL

 SUBRP	rackcaller

rc10	SLEEPK	30
	move	@SLDEBUG,a0
	btst	0,a0
	jrz	rc10


	calla	KILBGND
	clr	a0
	clr	a1
	calla	KILALL
	clr	a0
	clr	a1
	calla	KILOBJ
	clr	a0
	move	a0,@WORLDTLX+16
	movi	>35b,a0
	move	a0,@WORLDTLY+16
	jruc	DO_RACKUP



	movi	statspal,a0		;>Cycle color loop
	movk	31,a1
	clr	a2
rp45	move	a2,*a0+
	addk	16,a2
	dsj	a1,rp45

	movi	60*4,a8
	clr	a9
	clr	a10

rp50	move	@PCNT,a0
	sll	32-2,a0
	srl	32-2,a0
	jrnz	rp70			;Skip cycle

	movi	31*32*32+ 31*32+ 1,a0
	movi	colorbuf,a1
	move	a0,*a1+			;Set 1st color
	movi	statspal,a2
	movk	30,a4
rp55	move	*a2,a3			;Get color #
	addk	16,a3
	movi	statscolor_t,a0
	add	a3,a0
	move	*a0(16),a5		;Next is end?
	jrge	rp60
	clr	a3			;Restart
rp60	move	*a0+,*a1+
	move	a3,*a2+
	dsj	a4,rp55

	callr	setpal0

rp70	SLEEPK	1			;Sleep 4??
	dsj	a8,rp50


********************************
* Set palette 0 from buffer

	.bss	colorbuf	,16*31		;31 Color buffer

 SUBRP	setpal0

	PUSH	a1,a2
	movi	colorbuf,a0		;*Color
	movk	1,a1			;Palette 0, Color 1
	movk	31,a2			;# Colors
	calla	pal_set
	PULL	a1,a2
	rets

********************************
* Convert BCD to ASCII

	.bss	scorebuf	,12*8	;11 char_s

 SUBRP	bcdtoasc		;A0.L=BCD

	PUSH	a1,a2,a3
	movi	scorebuf+11*8,a1
	clr	a2
	movb	a2,*a1
	movk	4,a3
bcd5	dsj	a3,bcd10		;Convert BCD
	movk	3,a3
	movi	',',a2
	subk	8,a1
	movb	a2,*a1
bcd10	movk	>f,a2
	and	a0,a2
	addi	'0',a2
	subk	8,a1
	movb	a2,*a1
	srl	4,a0
	jrne	bcd5
	move	a1,a0
	PULL	a1,a2,a3
	rets


********************************
* Read joysticks

 SUBRP	joy_read
	move	@SWITCH,a0
	not	a0
	rets			;Pass CC

********************************

;	movi	bonush_st,a0		;>Rackup items
;	movi	hostage_l,a1
;	move	@P1DATA+THSTGS,a2
;	move	@P2DATA+THSTGS,a3
;	movk	5,a4
;	JSRP	bonus_showrack
;
;	movi	bonusf_st,a0
;	movi	flag_l,a1
;	move	@P1DATA+TFLAGS,a2
;	move	@P2DATA+TFLAGS,a3
;	movk	6,a4
;	JSRP	bonus_showrack
;
;	movi	bonusg_st,a0
;	movi	gems_l,a1
;	move	@P1DATA+CASHCNT,a2
;	move	@P2DATA+CASHCNT,a3
;	movk	3,a4
;	JSRP	bonus_showrack



********************************
* Do a bonus rack

	APTRPD	BONUSLP,0	;*Bonus anim list
	WORDPD	BONUSC1,2	;Play 1 # items
	WORDPD	BONUSC2,3	;Play 2 ^
	WORDPD	BONUSPT,4	;Points per item


 SUBRP	bonus_showrack	;A0=*XY text, A1=*Anim list, A2=1Cnt, A3=2Cnt
			;A4=Points per item

	move	@PSTATUS,a8
	btst	0,a8
	jrnz	bsr20
	clr	a2
bsr20	btst	1,a8
	jrnz	bsr25
	clr	a3
bsr25
	move	a1,*a13(BONUSLP),L
	move	a2,*a13(BONUSC1)
	move	a3,*a13(BONUSC2)
	move	a4,*a13(BONUSPT)

	calla	prt0_xy

	movi	racksup,a0
	calla	snd_play1

	movk	10,a0
	move	a0,@boanimdeath1
	move	a0,@boanimdeath2

	movi	hostxy_t,a8		;A8=*Next XY
	clr	a9			;A9=Play1 cnt
	clr	a10			;A10=Play2 cnt
	clr	a11			;A11=P1/2 Death delay bits


bsr40	move	*a13(BONUSC1),a0
	cmp	a0,a9
	jrlo	bsr70			;Cnt up?
	move	@boanimdeath1,a0
	jrle	bsr90
	btst	0,a11
	jrnz	bsr60
	addk	1,a11			;Set bit 0
	PUSH	a0,a8,a9
	move	a13,a8
	clr	a9
	CREATE0	bonus_flashwinblk
	PULL	a0,a8,a9
	addk	14,a0			;Add delay
bsr60	subk	1,a0
	move	a0,@boanimdeath1
	jruc	bsr90

bsr70	addk	1,a9
	move	@P1DATA+PSCORE,a0,L
	move	*a13(BONUSPT),a1
	add	a1,a0			;Add bonus
	move	a0,@P1DATA+PSCORE,L
	movi	rack1it,a0
	calla	snd_play1
	move	*a8,a1			;Get X
	jrn	bsr90
	PUSH	a9,a10,a11
	move	*a13(BONUSLP),a9,L
	clr	a10
	movi	boanimdeath1,a11
	CREATE0	bonus_anim
	PULL	a9,a10,a11
bsr90
	move	*a13(BONUSC2),a0
	cmp	a0,a10
	jrlo	bsr120
	move	@boanimdeath2,a0
	jrle	bsr150
	btst	1,a11
	jrnz	bsr100
	addk	2,a11			;Set bit 1
	PUSH	a0,a8,a9
	move	a13,a8
	movk	1,a9
	CREATE0	bonus_flashwinblk
	PULL	a0,a8,a9
	addk	14,a0			;Add delay
bsr100	subk	1,a0
	move	a0,@boanimdeath2
	jruc	bsr150

bsr120	addk	1,a10
	move	@P2DATA+PSCORE,a0,L
	move	*a13(BONUSPT),a1
	add	a1,a0			;Add bonus
	move	a0,@P2DATA+PSCORE,L
	movi	rack1it,a0
	calla	snd_play1
	move	*a8,a1			;Get X
	jrn	bsr150
	PUSH	a9,a10,a11
	move	*a13(BONUSLP),a9,L
	movi	184,a10			;X offset
	movi	boanimdeath2,a11
	CREATE0	bonus_anim
	PULL	a9,a10,a11

bsr150
	move	*a8,a0
	jrn	bsr180
	addk	32,a8			;Next XY
bsr180	movk	3,a0
	callr	sleep_var
	move	@boanimdeath1,a0	;Both done?
	jrgt	bsr40
	move	@boanimdeath2,a0
	jrgt	bsr40

	movi	kilfgnd,a0
	calla	snd_play1

	calla	ERASE_TXT

	RETP

hostxy_t
	.word	30,45, 60,45, 90,45, 120,45, 150,45
	.word	45,65, 75,65, 105,65, 135,65
	.word	30,85, 60,85, 90,85, 120,85, 150,85
	.word	45,105, 75,105, 105,105, 135,105
	.word	-1



********************************
* Flash other players blocks if he won

 SUBRP	bonus_flashwinblk	;A8=*Creators process, A9=P1 or P2 (0-1)

	move	*a8(BONUSC1),a1
	move	*a8(BONUSC2),a2
	move	@WORLDTLX+16,a10
	move	a9,a9
	jrnz	bfwb70
	SWAP	a1,a2
	addi	190,a10			;A10=Min X of tiles
bfwb70	cmp	a2,a1
	jrlo	bfwbx			;Win round?
	movi	190,a11			;A11=X range of tiles

	movk	3,a8
bfwb80	movi	DMACNZ+M_NOCOLL,a3
	callr	bonus_flashblk
	SLEEPK	2
	movi	DMAWNZ+M_NOCOLL,a3
	callr	bonus_flashblk
	SLEEPK	8
	dsj	a8,bfwb80

bfwbx	DIE


 SUBRP	bonus_flashblk		;A3=OFLAGS, A10=XMin, A11=XWidth

	move	@OBJLST,a1,L
bfb20	move	*a1(OZPOS),a0
	subi	200,a0
	subk	1,a0
	jrhi	bfb30			;Not 200-201?
	move	*a1(OXPOS),a0
	sub	a10,a0
	cmp	a11,a0
	jrhi	bfb30
	move	a3,*a1(OFLAGS)
	movi	>909,a0
	move	a0,*a1(OCONST)
bfb30	move	*a1,a1,L
	jrnz	bfb20
	rets


********************************
* Animation of a bonus item (Process)

 SUBRP	bonus_anim		;A8=*XY, A9=*FRANIM table, A10=X offset
				;A11=*boanimdeath var
	move	*a8+,a0			;Get X
	move	*a8+,a1			;Get Y
	move	*a11,a2
	move	a2,*a13(PDATA)		;Save death #
	addk	1,a2			;+1
	move	a2,*a11
	add	a10,a0
	sll	16,a0
	sll	16,a1
	move	*a9,a2,L
	movi	220,a3
	movi	DMAWNZ+M_NOCOLL,a4
	clr	a5
	clr	a6
	clr	a7
	calla	BEGINOBJ
	move	a9,*a13(PDATA+16),L
bo40	movk	4,a1			;Do one, no sleep
	JSRP	FRANIM
	jrnc	bo60
	move	*a13(PDATA+16),a9,L
	jruc	bo40
bo60	move	a0,a10
bo80	SLEEPK	1
	move	*a11,a0			;Get death #
	move	*a13(PDATA),a1
	cmp	a0,a1
	jrgt	bo90
	dsj	a10,bo80
	jruc	bo40
bo90	move	a8,a0
	calla	DELOBJ
	DIE



********************************
	.endif


	.end

