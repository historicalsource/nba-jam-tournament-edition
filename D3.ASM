**************************************************************
*
* Software:		Shawn Liptak
* Initiated:		Jan 31,1992
*
* Modified:		!
*
* COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 3/22/93 20:50
**************************************************************
      	.file	"3d.asm"
	.title	"Mega 3d polygon code"
	.width	132
	.option	b,d,l,t
	.mnolist

	.include	gsp.equ
	.include	sys.equ
	.include	mproc.equ
	.include	disp.equ
	.include	shawn.hdr
	.include	game.equ
	.include	imgtbl.glo


;sound headers used

tankexpsnd	.word	>fcc0,15,>8153,0	;Tank explosion
plfiresnd	.word	>f450,20,>8129,0	;Player cannon
enfiresnd	.word	>f460,20,>811d,0	;Enemy cannon
plhit_snd	.word	>fcf5,05,>8138,0	;Hit backboard

;symbols externally defined

	.ref	_3dstat,gndstat
	.ref	IRQSKYE
	.ref	pal_getf,osgfont_t,STRCNRMO_1
	.ref	game_over


;symbols defined in this file

;	.def	rocketptx_t	;For TV


;uninitialized ram definitions

D3NUMO	.equ	200

*struct APTR
OBJPTR	.equ	0	;UHL
*endstruct
*struct WORD
OBJPTR	.equ	0	;UHW
*endstruct
*struct XYZ
PTX	.equ	0	;SDW
PTY	.equ	>10	;SDW
PTZ	.equ	>20	;SDW
*endstruct

*struct D3OBJ
D3LINK	.equ	0		;UHL *Next object or 0
D3X	.equ	>20		;SHL X pos 24:8
D3Y	.equ	>40		;SHL Y ^
D3Z	.equ	>60		;SHL Z ^
D3XV	.equ	>80		;SHL X vel 24:8
D3YV	.equ	>a0		;SHL Y ^
D3ZV	.equ	>c0		;SHL Z ^
D3XA	.equ	>e0		;UHW X angle 0-255
D3YA	.equ	>f0		;UHW Y ^
D3ZA	.equ	>100		;UHW Z ^
D3ID	.equ	>110		;UHW Type ID
D3PTS	.equ	>120		;UHL *Points array (Cnt, XYZ,XYZ..)
D3XPTS	.equ	>140		;UHL *Xformed points array (Cnt, XYZ,XYZ..)
D3FACE	.equ	>160		;UHL *Face data
D3ZTEMP	.equ	>180		;SHW View relative Z for sorting
D3PLINK	.equ	>190		;UHL *Process that owns
D3HDSZ	.equ	>1b0
*endstruct


XPTMSZ	.equ	(16*3*11*D3NUMO/4)&>fffff0

	BSSX	d3vis_p		,32		;*1st in chain of visable objs
	BSSX	d3free_p	,32		;*1st in chain of free objs

	STRUCT	>1100000
	STRUC	d3objmem	,D3HDSZ*D3NUMO	;Object header mem
	STRUC	d3xptmem	,XPTMSZ		;Xformed pts mem

	BSSX	d3world_t	,32*(D3NUMO+1)	;World_t of * to polygon objs
	BSSX	d3gnd_t		,32*100		;Ground_t of * to polygon objs


	BSSX	viewx		,32		;X view position (24:8)
	BSSX	viewy		,32		;Y ^
	BSSX	viewz		,32		;Z ^

	BSSX	viewxa		,16		;X view angle 0-255
	BSSX	viewya		,16		;Y ^
	BSSX	viewza		,16		;Z ^

	.bss	d3collstop	,16		;!0=Stop scan on current obj
	.bss	pcoll_t		,32*(D3NUMO+1)	;List of objs of class player
	.bss	ncoll_t		,32*(D3NUMO+1)	;List of objs of class neutral
	.bss	ecoll_t		,32*(D3NUMO+1)	;List of objs of class enemy

	.bss	shield		,16		;Shield strength


TYPPSHOT	.equ	0200h		;Players shots
TYPGND		.equ	0300h		;Ground obstacle
TYPTANK		.equ	0400h		;Tank
TYPSHELL	.equ	0500h		;Type shell


BOGRATE	.equ	4

	.text


********************************
* 3D point format. Label is shown on + end of axis.
*	+---------+
*	|    Y /  | Z goes negative into screen
*	|    |/   |
*	| ---+--X |
*	|   /|    |
*       |  Z |    |
*	+---------+

********************************
* Test 3D code (Process)

 SUBR	_3d_test


	clr	a1			;All procs
	calla	KILALL
	movi	-1,a1			;All objs
	calla	obj_delc


	movk	6,a0
	move	a0,@IRQSKYE


	movi	d3objmem,a1		;>Init free list
	move	a1,@d3free_p,L
	movi	D3NUMO,b0		;# of object blocks

#olp	move	a1,a14
	addi	D3HDSZ,a1
	move	a1,*a14,L		;link em up
	dsj	b0,#olp

	clr	a0
	move	a0,*a14,L		;Null end
	move	a0,@d3world_t,L
	move	a0,@d3gnd_t,L




	movi	#init_t,a10		;>Get objects and init
	jruc	dt40

dtlp	callr	_3d_getobj
	movi	CLSNEUT|TYPGND,a0
	move	a0,*a8(D3ID)
	move	a6,*a8(D3PTS),L
	move	*a10+,a1,L
	move	a1,*a8(D3FACE),L

	move	a8,a1
	addk	D3X,a1
	movk	3,a7
#cxyz	move	*a10+,a3		;Copy starting XYZ
	sll	8,a3
	move	a3,*a1+,L
	dsj	a7,#cxyz

	clr	a2
	movk	3*2+3,a7
#clrva	move	a2,*a1+			;Clr XYZ vel & angle
	dsj	a7,#clrva

dt40	move	*a10+,a6,L
	jrnz	dtlp



	movi	#gndinit_t,a10		;>Get ground objects and init
	jruc	#gndi

#gndlp	callr	_3d_getgndobj
	move	a6,*a8(D3PTS),L
	move	*a10+,a1,L
	move	a1,*a8(D3FACE),L

	move	a8,a1
	addk	D3X,a1
	movk	3,a7
#cxyz2	move	*a10+,a0,L		;Copy starting XYZ
	sll	8,a0
	move	a0,*a1+,L
	dsj	a7,#cxyz2

	clr	a2
	movk	3*2+3,a7
#cva	move	a2,*a1+			;Clr XYZ vel & angle
	dsj	a7,#cva

#gndi	move	*a10+,a6,L
	jrnz	#gndlp





	clr	a0
;	movi	d3xptmem,a11
;	move	a0,*a11
	move	a0,@d3vis_p		;Null visable list
	move	a0,@gndstat		;Off
	movk	1,a0
	move	a0,@_3dstat		;On



	CREATE0	plyr_readbut
	movi	-8000<<8,a10		;X
	movi	-8000<<8,a11		;Z
	CREATE0	en_tank
	CREATE0	en_tank
	movi	8000<<8,a10
	movi	-8000<<8,a11
	CREATE0	en_tank
	CREATE0	en_tank
	movi	-8000<<8,a10
	movi	8000<<8,a11
	CREATE0	en_tank
	CREATE0	en_tank
	movi	8000<<8,a10
	movi	8000<<8,a11
	CREATE0	en_tank
	CREATE0	en_tank

	CREATE0	en_spawner

	movi	100<<8,a0
	move	a0,@viewy,L
	clr	a0
	move	a0,@viewx,L
	move	a0,@viewz,L
	move	a0,@viewxa
	move	a0,@viewya
	move	a0,@viewza

	movk	7,a0
	move	a0,@shield

	SLEEPK	2
	clr	a0
	move	a0,@_3dstat		;Off
	JSRP	scrn_scalein
	movk	1,a0
	move	a0,@_3dstat		;On


	SLEEP	TSEC*7/BOGRATE


	move	@SWITCH,a0
	andi	>5808,a0		;P1/2 sticks rgt and P2 but 1&3 down
	jrnz	#slp

	CREATE0	copyright_prtmsg
#slp
	SLEEP	TSEC*70/BOGRATE


	movi	GOLD,a0
	calla	pal_getf
	move	a0,a6

	movi	#surv_s,a8
	clr	a0
	movi	[80,200],a9
	movk	1,a10
	movi	osgfont_t,a11
	JSRP	STRCNRMO_1


	SLEEP	TSEC*3/BOGRATE

	movk	1,a0
	move	a0,@show_shot

	movi	>eaea,a0
	move	a0,@plyrbighead

	movk	8,a0
	move	a0,@p1taps
	move	a0,@p1taps+16
	move	a0,@p1taps+32
	move	a0,@p1taps+48

	.ref	show_shot
	.ref	from_3d
	.ref	p1taps
	.ref	plyrbighead


pldead
	clr	a1			;All procs
	move	a1,@_3dstat		;Off
	calla	KILALL
	movi	-1,a1			;All objs
	calla	obj_delc

	jauc	from_3d


#surv_s	.byte	"ALL PLAYERS POWERUP!",0
	.even



#init_t	;World init
	.long	rocket_pts,rocketline_t
	.word	0,200,0

	.long	cube_pts,cubeline_t
	.word	-5000,400,-5000
	.long	cube_pts,cubeline_t
	.word	5000,400,-5000
	.long	cube_pts,cubeline_t
	.word	-5000,400,5000
	.long	cube_pts,cubeline_t
	.word	5000,400,5000
	.long	cube_pts,cubeline_t
	.word	-10000,400,-10000
	.long	cube_pts,cubeline_t
	.word	10000,400,-10000
	.long	cube_pts,cubeline_t
	.word	-10000,400,10000
	.long	cube_pts,cubeline_t
	.word	10000,400,10000
	.long	cube_pts,cubeline_t
	.word	-3000,400,-3000
	.long	cube_pts,cubeline_t
	.word	3000,400,-3000
	.long	cube_pts,cubeline_t
	.word	-3000,400,3000
	.long	cube_pts,cubeline_t
	.word	3000,400,3000
	.long	cube_pts,cubeline_t
	.word	-5000,400,-5000
	.long	cube_pts,cubeline_t
	.word	2000,400,-2000
	.long	cube_pts,cubeline_t
	.word	-2000,400,2000
	.long	cube_pts,cubeline_t
	.word	2000,400,2000
	.long	pyr_pts,pyrline_t
	.word	-8000,300,-8000
	.long	pyr_pts,pyrline_t
	.word	8000,300,-8000
	.long	pyr_pts,pyrline_t
	.word	-8000,300,8000
	.long	pyr_pts,pyrline_t
	.word	8000,300,8000

	.long	pyr_pts,pyrline_t
	.word	0,300,-5000
	.long	pyr_pts,pyrline_t
	.word	0,300,5000
	.long	pyr_pts,pyrline_t
	.word	-5000,300,0
	.long	pyr_pts,pyrline_t
	.word	5000,300,0

	.long	0



rocket_pts
	.word	17
	.word	-200,200,800
	.word	200,200,800
	.word	300,100,800
	.word	300,-100,800
	.word	200,-200,800
	.word	-200,-200,800
	.word	-300,-100,800
	.word	-300,100,800
	.word	-200,200,-600
	.word	200,200,-600
	.word	300,100,-600
	.word	300,-100,-600
	.word	200,-200,-600
	.word	-200,-200,-600
	.word	-300,-100,-600
	.word	-300,100,-600
	.word	0,0,-1100

rocketline_t
	.word	>101,0,1*48,2*48,3*48,4*48,5*48,6*48,7*48,-1
	.word	>202,0,8*48,9*48,1*48,-1
	.word	>303,1*48,9*48,10*48,2*48,-1
	.word	>202,2*48,10*48,11*48,3*48,-1
	.word	>303,3*48,11*48,12*48,4*48,-1
	.word	>202,4*48,12*48,13*48,5*48,-1
	.word	>303,5*48,13*48,14*48,6*48,-1
	.word	>202,6*48,14*48,15*48,7*48,-1
	.word	>303,7*48,15*48,8*48,0*48,-1
	.word	>404,9*48,8*48,16*48,-1
	.word	>504,10*48,9*48,16*48,-1
	.word	>404,11*48,10*48,16*48,-1
	.word	>504,12*48,11*48,16*48,-1
	.word	>404,13*48,12*48,16*48,-1
	.word	>504,14*48,13*48,16*48,-1
	.word	>404,15*48,14*48,16*48,-1
	.word	>504,8*48,15*48,16*48,-1
	.word	-1	;End


cube_pts
	.word	8
	.word	400,400,200
	.word	400,-400,200
	.word	-400,-400,200
	.word	-400,400,200
	.word	400,400,-200
	.word	400,-400,-200
	.word	-400,-400,-200
	.word	-400,400,-200

cubeline_t
	.word	>101,0,1*48,2*48,3*48,-1
	.word	>202,7*48,6*48,5*48,4*48,-1
	.word	>303,3*48,2*48,6*48,7*48,-1
	.word	>303,4*48,5*48,1*48,0,-1
	.word	>404,5*48,6*48,2*48,1*48,-1
	.word	>404,7*48,4*48,0,3*48,-1
	.word	-1	;End


pyr_pts				;Pyramid
	.word	5
	.word	-200,-300,200	;Base
	.word	-200,-300,-200
	.word	200,-300,-200
	.word	200,-300,200
	.word	0,300,0		;Tip

pyrline_t
	.word	>2626,0,4*48,3*48,-1
	.word	>2a2a,1*48,4*48,0,-1
	.word	>2626,2*48,4*48,1*48,-1
	.word	>2a2a,3*48,4*48,2*48,-1
	.word	-1	;End


pmsl_pts
	.word	5
	.word	-40,40,200	;Back
	.word	40,40,200
	.word	40,-40,200
	.word	-40,-40,200
	.word	0,0,-200	;Tip

pmslline_t
	.word	>f0f,0,1*48,2*48,3*48,-1
	.word	>1111,0,4*48,1*48,-1
	.word	>1313,1*48,4*48,2*48,-1
	.word	>1111,2*48,4*48,3*48,-1
	.word	>1313,3*48,4*48,0*48,-1
	.word	-1	;End


enmsl_pts
	.word	9
	.word	0,50,200	;Back
	.word	35,35,200
	.word	50,0,200
	.word	35,-35,200
	.word	0,-50,200
	.word	-35,-35,200
	.word	-50,0,200
	.word	-35,35,200
	.word	0,0,-200	;Tip

enmslline_t
	.word	>0f0f,0,1*48,2*48,3*48,4*48,5*48,6*48,7*48,-1
	.word	>1111,0*48,8*48,1*48,-1
	.word	>1313,1*48,8*48,2*48,-1
	.word	>1111,2*48,8*48,3*48,-1
	.word	>1313,3*48,8*48,4*48,-1
	.word	>1111,4*48,8*48,5*48,-1
	.word	>1313,5*48,8*48,6*48,-1
	.word	>1111,6*48,8*48,7*48,-1
	.word	>1313,7*48,8*48,0*48,-1
	.word	-1	;End


tanklow_pts
	.word	8
	.word	-100,40,200
	.word	100,40,200
	.word	100,-40,200
	.word	-100,-40,200
	.word	-100,5,-200
	.word	100,5,-200
	.word	100,-40,-200
	.word	-100,-40,-200

tanklowline_t
	.word	>505,0,1*48,2*48,3*48,-1	;Back
	.word	>202,1*48,5*48,6*48,2*48,-1	;R
	.word	>303,5*48,4*48,7*48,6*48,-1	;F
	.word	>202,4*48,0,3*48,7*48,-1	;L
	.word	>404,4*48,5*48,1*48,0,-1	;Top
	.word	>101,3*48,2*48,6*48,7*48,-1	;Bot
	.word	-1	;End



tanktur_pts
	.word	8
	.word	-80,40,100
	.word	80,40,100
	.word	80,-40,100
	.word	-80,-40,100
	.word	-80,5,-100
	.word	80,5,-100
	.word	80,-40,-100
	.word	-80,-40,-100

tankturline_t
	.word	>2626,0,1*48,2*48,3*48,-1	;Back
	.word	>2a2a,1*48,5*48,6*48,2*48,-1	;R
	.word	>2626,5*48,4*48,7*48,6*48,-1	;F
	.word	>2a2a,4*48,0,3*48,7*48,-1	;L
	.word	>404,4*48,5*48,1*48,0,-1	;Top
	.word	>101,3*48,2*48,6*48,7*48,-1	;Bot
	.word	-1	;End


#gndinit_t	;Ground init
	.long	gnd_pts,gndline_t,0,0,0
	.long	gnd_pts,gndline_t,0,0,-21000
	.long	gnd_pts,gndline_t,-21000,0,0
	.long	gnd_pts,gndline_t,21000,0,0
	.long	gnd_pts,gndline_t,0,0,21000

	.long	0

gnd_pts
	.word	8
	.word	-9000,0,-9000
	.word	9000,0,-9000
	.word	9000,0,9000
	.word	-9000,0,9000
	.word	-1000,0,-1000
	.word	1000,0,-1000
	.word	1000,0,1000
	.word	-1000,0,1000

gndline_t
	.word	>2020,0,1*48,2*48,3*48,-1
	.word	>2323,4*48,5*48,6*48,7*48,-1
	.word	-1	;End



#*******************************
* DEBUG

check_vislist

	movi	d3vis_p,a1
	move	*a1,a0,L
	jrz	#x
#debug	move	a1,a0
	move	*a0,a1,L
	jrnz	#debug
	move	*a0(D3PTS),a1,L
	jrz	#err			;ERROR!!!
#x	rets

#err
	LOCKUP
	jruc	#x

#*******************************
* Get a object from 3D free list
* >A8=*Object or 0
* Trashes scratch

 SUBRP	_3d_getobj

	movi	d3free_p,a0
	move	*a0,a8,L
	jrz	#err
	move	*a8,*a0,L	;Unlink

	movi	d3world_t,a0	;>Add to end
#lp	move	*a0+,a1,L
	jrnz	#lp
	move	a1,*a0,L
	move	a8,-*a0,L

#x	rets

#err
	LOCKUP
	jruc	#x


#*******************************
* Get a object from 3D free list
* >A8=*Object or 0
* Trashes scratch

 SUBRP	_3d_getgndobj

	movi	d3free_p,a0
	move	*a0,a8,L
	jrz	#err
	move	*a8,*a0,L	;Unlink

	movi	d3gnd_t,a0	;>Add to end
#lp	move	*a0+,a1,L
	jrnz	#lp
	move	a1,*a0,L
	move	a8,-*a0,L

#x	rets

#err
	LOCKUP
	jruc	#x


#*******************************
* Put an object on 3D free list
* A8=*Object
* Trashes scratch

 SUBRP	_3d_freeobj

	movi	d3world_t,a0		;>Find
#lp	move	*a0+,a1,L
	jrz	#free
	cmp	a1,a8
	jrne	#lp			;No match?

#lp3	move	*a0+,a1,L		;>Move end up
	move	a1,*a0(-64),L
	jrnz	#lp3


#free	move	@d3free_p,*a8+,L
	subk	32,a8
	move	a8,@d3free_p,L
	rets


#*******************************
* Get object from 3D free list and init
* A0=X (24:8)
* A1=Y
* A2=Z
* A3=XA
* A4=YA
* A5=ZA
* A6=*Points
* A7=*Face data
* >A8=*Object or 0
* Trashes scratch

 SUBRP	_3d_beginobj

	movi	d3free_p,a14
	move	*a14,a8,L
	jrz	#error
	move	*a8,*a14,L	;Unlink

	move	a8,a14
	addk	D3X,a14
	move	a0,*a14+,L	;X
	move	a1,*a14+,L	;Y
	move	a2,*a14+,L	;Z
	clr	a0
	move	a0,*a14+,L	;XV
	move	a0,*a14+,L	;YV
	move	a0,*a14+,L	;ZV
	move	a3,*a14+	;XA
	move	a4,*a14+	;YA
	move	a5,*a14+	;ZA
	move	a6,*a8(D3PTS),L
	move	a7,*a8(D3FACE),L
	move	a13,*a8(D3PLINK),L

	movi	d3world_t,a14	;>Add to end
#lp	move	*a14+,a1,L
	jrnz	#lp
	move	a1,*a14,L
	move	a8,-*a14,L

#x	rets


#error	LOCKUP
	jruc	#x




********************************
* Build 3D view, called by display interrupt

 SUBR	_3d_build

	PUSH	a4,a13,a14
	PUSH	b2,b3,b4,b5,b6,b7,b8,b9,b10

	movi	d3world_t,a7		;>Add velocity to position
	jruc	#move

#lpmv	addk	D3X,a0
	mmfm	a0,a1,a2,a3,a4,a5,a6	;A6-A4=XYZ, A3-A1=XYZV

	subi	32*3,a0			;Flip POS & VEL ???
	add	a1,a4			;Add ZVEL to Z
	move	a4,-*a0,L
	add	a2,a5			;Add YVEL to Y (Uses hidden cycle!)
	move	a5,-*a0,L
	add	a3,a6			;Add XVEL to X ^
	move	a6,-*a0,L

#move	move	*a7+,a0,L
	jrnz	#lpmv			;More?


	PUSH	a11
	callr	_3d_buildvislist
	callr	_3d_addgndvislist
	PULL	a11


	move	@viewx,b2,L		;24:8
	move	@viewy,b3,L
	move	@viewz,b4,L

	movi	d3vis_p,b8		;>Xform objs about center
	jruc	dt500

dtlp5	move	b8,a8
	move	*a8(D3PTS),a0,L
	move	*a8(D3XPTS),a1,L
	move	a8,a2
	addk	D3X,a2

	move	*a2+,a12,L		;XPos (24:8)
	move	*a2+,a13,L		;YPos
	move	*a2+,a14,L		;ZPos
	addi	32*3,a2
	move	*a2+,a9			;XAngle
	move	*a2+,a10		;YA
	move	*a2+,a8			;ZA

	move	b2,a3
	sub	a3,a12
	move	b3,a3
	sub	a3,a13
	move	b4,a3
	sub	a3,a14

	sra	8,a12			;Remove fraction
	sra	8,a13
	sra	8,a14
	callr	_3d_xformoffset

dt500	move	*b8,b8,L
	jrnz	dtlp5



	callr	_3d_xformrelview	;Could do with step above???


					;>Scale for display
	movi	d3vis_p,b8
	jruc	#2000

#lp9	move	b8,a4
	move	*a4(D3XPTS),a0,L
	callr	_3d_scalexy
#2000	move	*b8+,b8,L
	jrnz	#lp9



	callr	_3d_collide



	.if	TUNIT

	.if	DEBUG
	move	@SWITCH,a7
	move	@SWITCH2,a0
	sll	24,a0
	movy	a0,a7
	.else
	move	@SWITCH,a7
	sll	24,a7
	.endif

	.else
	move	@SWITCH,a7,L
	.endif


	move	@viewza,a0		;>Turn z view angle
	btst	10,a7
	jrnz	dt6000			;!L joy2?
	addk	1,a0
dt6000	btst	11,a7
	jrnz	dt6100			;!R joy2?
	subk	1,a0
dt6100	move	a0,@viewza

	move	@viewya,a0		;>Turn y view angle
	btst	26,a7
	jrnz	dt6300			;!L joy3?
	subk	1,a0
	btst	30,a7
	jrnz	dt6300			;!But3?
	subk	1,a0

dt6300	btst	27,a7
	jrnz	dt6400			;!R joy3?
	addk	1,a0
	btst	30,a7
	jrnz	dt6400			;!But3?
	addk	1,a0
dt6400	move	a0,@viewya

	move	@viewxa,a0		;>Turn x view angle
	btst	8,a7
	jrnz	dt6600			;!U joy2?
	addk	1,a0
dt6600	btst	9,a7
	jrnz	dt6700			;!D joy2?
	subk	1,a0
dt6700	move	a0,@viewxa


	btst	24,a7
	jrnz	dt7000			;!Up joy3?

	move	@viewya,a0		;>Move forward
	callr	sinecos_get

	btst	30,a7
	jrnz	#noturb			;!P3 but3
	sll	1,a0			;*2
	sll	1,a1

#noturb	move	@viewx,a2,L
	add	a0,a2
	move	a2,@viewx,L

	move	@viewz,a2,L
	sub	a1,a2
	move	a2,@viewz,L


dt7000	btst	25,a7
	jrnz	dt7500			;!Dn joy3?

	move	@viewya,a0		;>Move back
	callr	sinecos_get

	move	@viewx,a2,L
	sub	a0,a2
	move	a2,@viewx,L

	move	@viewz,a2,L
	add	a1,a2
	move	a2,@viewz,L
dt7500

	PULL	b2,b3,b4,b5,b6,b7,b8,b9,b10
	PULL	a4,a13,a14
	rets




#*******************************
* Check distance and visability of objs center point
* Adds to d3vis_p if visable
* >A11=*Next free xform mem
* Trashes A0-A7,B0-B1

;x=x*cos(az)-y*sin(az)
;y=x*sin(az)+y*cos(az)

;y=y*cos(ax)-z*sin(ax)
;z=y*sin(ax)+z*cos(ax)

;z=z*cos(ay)-x*sin(ay)
;x=z*sin(ay)+x*cos(ay)

COSAZ	.equ	b0
SINAZ	.equ	b1
COSAX	.equ	b2
SINAX	.equ	b3
COSAY	.equ	b4
SINAY	.equ	b5


 SUBR	_3d_buildvislist

	PUSH	a8,a9,a10
	PUSH	b2,b3,b4,b5,b6


	move	@viewza,a0
	callr	sinecos_get
	move	a1,COSAZ	;B0=Cos AZ
	move	a0,SINAZ	;B1=Sine AZ

	move	@viewxa,a0
	callr	sinecos_get
	move	a1,COSAX	;B2=Cos AX
	move	a0,SINAX	;B3=Sine AX

	move	@viewya,a0
	callr	sinecos_get
	move	a1,COSAY	;B4=Cos AY
	move	a0,SINAY	;B5=Sine AY



	move	@viewx,a12,L		;24:8
	move	@viewy,a13,L
	move	@viewz,a14,L

	movi	d3world_t,a4		;>Build table of visable objs
	clr	a0
	move	a0,@d3vis_p,L		;Null end
	movi	>600000,a10		;A10=Range limit
	movi	d3xptmem,a11
	jruc	#next

#lp
	move	a6,a0
	addk	D3X,a0

	move	*a0+,a1,L		;XPos (24:8)
	sub	a12,a1
	move	a1,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?

	move	*a0+,a5,L		;YPos
	sub	a13,a5
	move	a5,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?

	move	*a0+,a9,L		;ZPos
	sub	a14,a9
	move	a9,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?


	sra	8,a1			;Remove fraction
	sra	8,a5
	sra	8,a9


	move	a1,a3
	move	COSAZ,a0
	mpys	a0,a1			;Cos*X

	move	a5,a7
	move	SINAZ,a2
	mpys	a2,a5			;Sine*Y
	sub	a5,a1
	sra	16,a1			;X about Z

	mpys	a2,a3			;Sine*X
	mpys	a0,a7			;Cos*Y
	add	a7,a3
	sra	16,a3			;Y about Z


	move	a3,a7
	move	COSAX,a0
	move	SINAX,a2
	mpys	a0,a3			;Cos*Y
	mpys	a2,a7			;Sin*Y

	move	a9,a5
	mpys	a2,a9			;Sin*Z
	mpys	a0,a5			;Cos*Z
	
	sub	a9,a3
	sra	16,a3			;Y about X
	add	a5,a7
	sra	16,a7			;Z about X


	move	COSAY,a0
	move	SINAY,a2
	move	a7,a9
	move	a1,a5
	mpys	a0,a7			;Cos*Z
	mpys	a2,a5			;Sin*X
	sub	a5,a7
	jrgt	#next			;Z behind me?
	sra	16,a7			;Z about Y

	mpys	a2,a9			;Sin*Z
	mpys	a0,a1			;Cos*X
	add	a9,a1
	sra	16,a1			;X about Y


	move	a7,*a6(D3ZTEMP)
	move	a11,*a6(D3XPTS),L
	addk	16,a11
	move	*a6(D3PTS),a2,L
	move	*a2,a2			;#Pts
	sll	4,a2			;*16
	add	a2,a11			;*48
	add	a2,a11
	add	a2,a11

	movi	d3vis_p,a8		;>Find spot in list based on Z
#lp2	move	a8,a2
	move	*a8,a8,L
	jrz	#atend			;End?
	move	*a8(D3ZTEMP),a1
	cmp	a1,a7
	jrgt	#lp2			;Higher?

#atend	move	a6,*a2,L		;Point last to me
	move	a8,*a6,L		;Point me to next


#next	move	*a4+,a6,L
	jrnz	#lp


	PULL	b2,b3,b4,b5,b6
	PULL	a8,a9,a10
	rets





#*******************************
* Check distance and visability of gnd objs
* Adds to d3vis_p if visable
* A11=*Next free xform mem
* Trashes A0-A7,B0-B1


 SUBR	_3d_addgndvislist

	PUSH	a8,a9,a10
	PUSH	b2,b3,b4,b5,b6


	move	@viewza,a0
	callr	sinecos_get
	move	a1,COSAZ		;B0=Cos AZ
	move	a0,SINAZ		;B1=Sine AZ

	move	@viewxa,a0
	callr	sinecos_get
	move	a1,COSAX		;B2=Cos AX
	move	a0,SINAX		;B3=Sine AX

	move	@viewya,a0
	callr	sinecos_get
	move	a1,COSAY		;B4=Cos AY
	move	a0,SINAY		;B5=Sine AY


	move	@viewx,a12,L		;24:8
	move	@viewy,a13,L
	move	@viewz,a14,L

	movi	d3gnd_t,a4		;>Build table of visable objs
	movi	>600000,a10		;A10=Range limit
	jruc	#next

#lp
	move	a6,a0
	addk	D3X,a0

	move	*a0+,a1,L		;XPos (24:8)
	sub	a12,a1
	move	a1,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?

	move	*a0+,a5,L		;YPos
	sub	a13,a5
	move	a5,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?

	move	*a0+,a9,L		;ZPos
	sub	a14,a9
	move	a9,a3
	abs	a3
	cmp	a10,a3
	jrhs	#next			;Out of range?


;	sra	8,a1			;Remove fraction
;	sra	8,a5
;	sra	8,a9
;
;
;	move	a1,a3
;	move	COSAZ,a0
;	mpys	a0,a1			;Cos*X
;
;	move	a5,a7
;	move	SINAZ,a2
;	mpys	a2,a5			;Sine*Y
;	sub	a5,a1
;	sra	16,a1			;X about Z
;
;	mpys	a2,a3			;Sine*X
;	mpys	a0,a7			;Cos*Y
;	add	a7,a3
;	sra	16,a3			;Y about Z
;
;
;	move	a3,a7
;	move	COSAX,a0
;	move	SINAX,a2
;	mpys	a0,a3			;Cos*Y
;	mpys	a2,a7			;Sin*Y
;
;	move	a9,a5
;	mpys	a2,a9			;Sin*Z
;	mpys	a0,a5			;Cos*Z
;	
;	sub	a9,a3
;	sra	16,a3			;Y about X
;	add	a5,a7
;	sra	16,a7			;Z about X
;
;
;	move	COSAY,a0
;	move	SINAY,a2
;	move	a7,a9
;	move	a1,a5
;	mpys	a0,a7			;Cos*Z
;	mpys	a2,a5			;Sin*X
;	sub	a5,a7
;	jrgt	#next			;Z behind me?
;	sra	16,a7			;Z about Y
;
;	mpys	a2,a9			;Sin*Z
;	mpys	a0,a1			;Cos*X
;	add	a9,a1
;	sra	16,a1			;X about Y


;	move	a7,*a6(D3ZTEMP)
	move	a11,*a6(D3XPTS),L
	addk	16,a11
	move	*a6(D3PTS),a2,L
	move	*a2,a2			;#Pts
	sll	4,a2			;*16
	add	a2,a11			;*48
	add	a2,a11
	add	a2,a11

	movi	d3vis_p,a8
	move	*a8,*a6,L		;Point me to next
	move	a6,*a8,L		;Point head to me


#next	move	*a4+,a6,L
	jrnz	#lp


	PULL	b2,b3,b4,b5,b6
	PULL	a8,a9,a10
	rets






#*******************************
* Xform objects on visable list relative to view point


 SUBRP	_3d_xformrelview

	PUSH	a8,a9,a10
	PUSH	b2,b3,b4,b5,b6,b7,b8


	move	@viewx,a12,L
	move	@viewy,a13,L
	move	@viewz,a14,L
	sra	8,a12
	sra	8,a13
	sra	8,a14


	move	@viewza,a0
	callr	sinecos_get
	move	a1,COSAZ	;B0=Cos AZ
	move	a0,SINAZ	;B1=Sine AZ

	move	@viewxa,a0
	callr	sinecos_get
	move	a1,COSAX	;B2=Cos AX
	move	a0,SINAX	;B3=Sine AX

	move	@viewya,a0
	callr	sinecos_get
	move	a1,COSAY	;B4=Cos AY
	move	a0,SINAY	;B5=Sine AY


	movi	d3vis_p,b8
	jruc	#next



#lp	move	b8,a4
	move	*a4(D3XPTS),a4,L ;A4=*Orig pts
	move	*a4+,a0		;Get # points
	move	a4,a6		;A6=*Dest pts
	move	a0,b6


#objlp
	move	*a4+,a1		;X
	move	a1,a3
	move	COSAZ,a0
	mpys	a0,a1		;Cos*X

	move	*a4+,a5		;Y
	move	a5,a7
	move	SINAZ,a2
	mpys	a2,a5		;Sine*Y
	sub	a5,a1
	sra	16,a1		;X about Z

	mpys	a2,a3		;Sine*X
	mpys	a0,a7		;Cos*Y
	add	a7,a3
	sra	16,a3		;Y about Z


	move	a3,a7
	move	COSAX,a0
	move	SINAX,a2
	mpys	a0,a3		;Cos*Y
	mpys	a2,a7		;Sin*Y

	move	*a4+,a9		;Z
	move	a9,a5
	mpys	a2,a9		;Sin*Z
	mpys	a0,a5		;Cos*Z
	
	sub	a9,a3
	sra	16,a3		;Y about X
	add	a5,a7
	sra	16,a7		;Z about X


	move	COSAY,a0
	move	SINAY,a2
	move	a7,a9
	move	a1,a5
	mpys	a0,a7		;Cos*Z
	mpys	a2,a5		;Sin*X
	sub	a5,a7
	sra	16,a7		;Z about Y
	mpys	a2,a9		;Sin*Z
	mpys	a0,a1		;Cos*X
	add	a9,a1
	sra	16,a1		;X about Y


	move	a1,*a6+		;New X
	move	a3,*a6+		;New Y
	move	a7,*a6+		;New Z

	dsj	b6,#objlp


#next	move	*b8+,b8,L
	jrnz	#lp


	PULL	b2,b3,b4,b5,b6,b7,b8
	PULL	a8,a9,a10
	rets



#*******************************
* Transform a set of XYZ points then add offset
* A0=*Obj 3D Points
* A1=*Mem for xformed pts
* A8=Angle 0-255 about Z
* A9=Angle 0-255 about X
* A10=Angle 0-255 about Y
* A12-A14=XYZ offsets after xform
* Trashes A0-A7,B0-B1

;x=x*cos(az)-y*sin(az)
;y=x*sin(az)+y*cos(az)

;y=y*cos(ax)-z*sin(ax)
;z=y*sin(ax)+z*cos(ax)

;z=z*cos(ay)-x*sin(ay)
;x=z*sin(ay)+x*cos(ay)

;COSAZ	.equ	b0
;SINAZ	.equ	b1
;COSAX	.equ	b2
;SINAX	.equ	b3
;COSAY	.equ	b4
;SINAY	.equ	b5


 SUBR	_3d_xformoffset

	PUSH	a8,a9
	PUSH	b2,b3,b4,b5,b6

	move	a0,a4		;A4=*Orig pts
	move	a1,a6		;A6=*Dest pts
	move	*a4+,a0		;Get # points
	move	a0,*a6+		;Copy #
	move	a0,b6


;Quicker!!
	move	a8,a0
	callr	cos_get
	move	a0,COSAZ	;B0=Cos AZ
	move	a8,a0
	callr	sine_get
	move	a0,SINAZ	;B1=Sine AZ
	move	a9,a0
	callr	cos_get
	move	a0,COSAX	;B2=Cos AX
	move	a9,a0
	callr	sine_get
	move	a0,SINAX	;B3=Sine AX
	move	a10,a0
	callr	cos_get
	move	a0,COSAY	;B4=Cos AY
	move	a10,a0
	callr	sine_get
	move	a0,SINAY	;B5=Sine AY

#lp
	move	*a4+,a1		;X
	move	a1,a3
	move	COSAZ,a0
	mpys	a0,a1		;Cos*X

	move	*a4+,a5		;Y
	move	a5,a7
	move	SINAZ,a2
	mpys	a2,a5		;Sine*Y
	sub	a5,a1
	sra	16,a1		;X about Z

	mpys	a2,a3		;Sine*X
	mpys	a0,a7		;Cos*Y
	add	a7,a3
	sra	16,a3		;Y about Z


	move	a3,a7
	move	COSAX,a0
	move	SINAX,a2
	mpys	a0,a3		;Cos*Y
	mpys	a2,a7		;Sin*Y

	move	*a4+,a9		;Z
	move	a9,a5
	mpys	a2,a9		;Sin*Z
	mpys	a0,a5		;Cos*Z
	
	sub	a9,a3
	sra	16,a3		;Y about X
	add	a5,a7
	sra	16,a7		;Z about X


	move	COSAY,a0
	move	SINAY,a2
	move	a7,a9
	move	a1,a5
	mpys	a0,a7		;Cos*Z
	mpys	a2,a5		;Sin*X
	sub	a5,a7
	sra	16,a7		;Z about Y
	mpys	a2,a9		;Sin*Z
	mpys	a0,a1		;Cos*X
	add	a9,a1
	sra	16,a1		;X about Y


	add	a12,a1		;>Add position offset
	add	a13,a3
	add	a14,a7
	move	a1,*a6+		;New X
	move	a3,*a6+		;New Y
	move	a7,*a6+		;New Z


	dsj	b6,#lp


	PULL	b2,b3,b4,b5,b6
	PULL	a8,a9
	rets




#*******************************
* Transform a set of XYZ points relative to 0,0,0
* A0=*Obj 3D Points
* A1=*Mem for xformed pts
* A8=Angle 0-255 about Z
* A9=Angle 0-255 about X
* A10=Angle 0-255 about Y
* Trashes A0-A7,B0-B1


 SUBR	_3d_xformrel0

	PUSH	a8,a9
	PUSH	b2,b3,b4,b5,b6

	move	a0,a4		;A4=*Orig pts
	move	a1,a6		;A6=*Dest pts
	move	*a4+,a0		;Get # points
	move	a0,*a6+		;Copy #
	move	a0,b6


;Quicker!!
	move	a8,a0
	callr	cos_get
	move	a0,COSAZ	;B0=Cos AZ
	move	a8,a0
	callr	sine_get
	move	a0,SINAZ	;B1=Sine AZ
	move	a9,a0
	callr	cos_get
	move	a0,COSAX	;B2=Cos AX
	move	a9,a0
	callr	sine_get
	move	a0,SINAX	;B3=Sine AX
	move	a10,a0
	callr	cos_get
	move	a0,COSAY	;B4=Cos AY
	move	a10,a0
	callr	sine_get
	move	a0,SINAY	;B5=Sine AY

#lp

	move	*a4+,a1		;X
	move	a1,a3
	move	COSAZ,a0
	mpys	a0,a1		;Cos*X

	move	*a4+,a5		;Y
	move	a5,a7
	move	SINAZ,a2
	mpys	a2,a5		;Sine*Y
	sub	a5,a1
	sra	16,a1		;X about Z

	mpys	a2,a3		;Sine*X
	mpys	a0,a7		;Cos*Y
	add	a7,a3
	sra	16,a3		;Y about Z


	move	a3,a7
	move	COSAX,a0
	move	SINAX,a2
	mpys	a0,a3		;Cos*Y
	mpys	a2,a7		;Sin*Y

	move	*a4+,a9		;Z
	move	a9,a5
	mpys	a2,a9		;Sin*Z
	mpys	a0,a5		;Cos*Z
	
	sub	a9,a3
	sra	16,a3		;Y about X
	add	a5,a7
	sra	16,a7		;Z about X


	move	COSAY,a0
	move	SINAY,a2
	move	a7,a9
	move	a1,a5
	mpys	a0,a7		;Cos*Z
	mpys	a2,a5		;Sin*X
	sub	a5,a7
	sra	16,a7		;Z about Y
	mpys	a2,a9		;Sin*Z
	mpys	a0,a1		;Cos*X
	add	a9,a1
	sra	16,a1		;X about Y


	move	a1,*a6+		;New X
	move	a3,*a6+		;New Y
	move	a7,*a6+		;New Z


	dsj	b6,#lp


	PULL	b2,b3,b4,b5,b6
	PULL	a8,a9
	rets



********************************
* Transform a set of XYZ points relative to an XYZ pt
* A0=*Obj 3D Points
* A1=*Mem for xformed pts
* A8=Angle 0-255 about Z
* A9=Angle 0-255 about X
* A10=Angle 0-255 about Y
* A12-A14=XYZ relative pt
* Trashes A0-A7,B0-B1



 SUBR	_3d_xformrel

	PUSH	a8,a9
	PUSH	b2,b3,b4,b5,b6

	move	a0,a4		;A4=*Orig pts
	move	a1,a6		;A6=*Dest pts
	move	*a4+,a0		;Get # points
	move	a0,*a6+		;Copy #
	move	a0,b6


;Quicker!!
	move	a8,a0
	callr	cos_get
	move	a0,COSAZ	;B0=Cos AZ
	move	a8,a0
	callr	sine_get
	move	a0,SINAZ	;B1=Sine AZ
	move	a9,a0
	callr	cos_get
	move	a0,COSAX	;B2=Cos AX
	move	a9,a0
	callr	sine_get
	move	a0,SINAX	;B3=Sine AX
	move	a10,a0
	callr	cos_get
	move	a0,COSAY	;B4=Cos AY
	move	a10,a0
	callr	sine_get
	move	a0,SINAY	;B5=Sine AY

dxrlp

	move	*a4+,a1		;X
	sub	a12,a1		;-Base X
	move	a1,a3
	move	COSAZ,a0
	mpys	a0,a1		;Cos*X

	move	*a4+,a5		;Y
	sub	a13,a5		;-Base Y
	move	a5,a7
	move	SINAZ,a2
	mpys	a2,a5		;Sine*Y
	sub	a5,a1
	sra	16,a1		;X about Z

	mpys	a2,a3		;Sine*X
	mpys	a0,a7		;Cos*Y
	add	a7,a3
	sra	16,a3		;Y about Z


	move	a3,a7
	move	COSAX,a0
	move	SINAX,a2
	mpys	a0,a3		;Cos*Y
	mpys	a2,a7		;Sin*Y

	move	*a4+,a9		;Z
	sub	a14,a9		;-Base Z
	move	a9,a5
	mpys	a2,a9		;Sin*Z
	mpys	a0,a5		;Cos*Z
	
	sub	a9,a3
	sra	16,a3		;Y about X
	add	a5,a7
	sra	16,a7		;Z about X


	move	COSAY,a0
	move	SINAY,a2
	move	a7,a9
	move	a1,a5
	mpys	a0,a7		;Cos*Z
	mpys	a2,a5		;Sin*X
	sub	a5,a7
	sra	16,a7		;Z about Y
	mpys	a2,a9		;Sin*Z
	mpys	a0,a1		;Cos*X
	add	a9,a1
	sra	16,a1		;X about Y


	move	a1,*a6+		;New X
	move	a3,*a6+		;New Y
	move	a7,*a6+		;New Z


	dsj	b6,dxrlp


	PULL	b2,b3,b4,b5,b6
	PULL	a8,a9
	rets





#*******************************
* Scale XY by Z and adjust for display
* A0=*Xformed XYZ Points
* Trashes A0-A7
 
 SUBRP	_3d_scalexy

	PUSH	a8,a9

	move	*a0+,a7		;Get # points
	jrle	#x		;Necessary???

	move	a0,a2
	move	a7,a3
#lp	addk	16*2,a2
	move	*a2+,a1		;Z
	jrlt	#avis		;Any visable?
	dsj	a3,#lp
	move	a3,-*a0		;Set # pts 0 so it won't be shown
	jruc	#x		;No pts visable

#avis
	movi	>7fff,a8
	movi	->7fff,a9
#lp2
	move	a0,a6
	move	*a0+,a1		;X
	move	*a0+,a3		;Y
	neg	a3		;Flip Y
	move	*a0+,a2		;Z
	jrn	#vis		;Visable?

	addi	512,a2
	mpys	a2,a1
	mpys	a2,a3
	sra	9,a1		;/512, make big
	sra	9,a3
	cmp	a8,a1
	jrle	#xhok		;Not maxed?
	move	a8,a1
#xhok
	cmp	a9,a1
	jrge	#xlok		;Not mined?
	move	a9,a1
#xlok
	jruc	#set

#vis	abs	a2
	addi	512,a2

	sll	9,a1		;*512
	sll	9,a3

	divs	a2,a1		;Scale down for Z distance
	divs	a2,a3

#set	addi	127,a3		;Center Y

	move	a1,*a6+		;New X
	move	a3,*a6+		;New Y


	dsj	a7,#lp2


#x	PULL	a8,a9
	rets



;	movi	4000,a4		;Vanishing pt
;	add	a2,a4
;	jrgt	dsxy50
;	clr	a1
;	clr	a3
;	jruc	dsxy100
;dsxy50
;	mpys	a4,a1		;Scale down for Z distance
;	mpys	a4,a3
;	sra	10,a1		;/4096
;	sra	10,a3







#*******************************
* Read players button (Process)

 SUBRP	plyr_readbut

#lp	SLEEPK	1
	move	@shield,a0
	jrn	#dead

	.if	TUNIT
	move	@SWITCH,a0
	btst	4,a0
	.else
	move	@SWITCH+16,a0
	btst	12,a0
	.endif
	jrnz	#lp			;No joy1 but1?


	CREATE0	plyr_msl

	SLEEPK	5
	jruc	#lp

#dead
	movi	REDPAL,a0
	calla	pal_getf
	move	a0,a6

	movi	#dead_s,a8
	clr	a0
	movi	[100,200],a9
	movk	1,a10
	movi	osgfont_t,a11
	JSRP	STRCNRMO_1


	SLEEP	TSEC*3/BOGRATE

	jruc	pldead


#dead_s	.byte	"YOU ARE DEAD!",0
	.even


#*******************************
* Fire a missile from player (Process)

 SUBRP	plyr_msl

	movi	plfiresnd,a0
	calla	snd_play1

	move	@viewx,a0,L		;24:8
	move	@viewy,a1,L
	move	@viewz,a2,L
	move	@viewxa,a3
	move	@viewya,a4
	not	a4
	move	@viewza,a5
	movi	pmsl_pts,a6
	movi	pmslline_t,a7
	callr	_3d_beginobj		;Get shell


	movi	CLSPLYR|TYPPSHOT,a0
	move	a0,*a8(D3ID)

	move	@viewya,a0		;>Move forward
	callr	sinecos_get
	move	a0,*a8(D3XV),L
	neg	a1
	move	a1,*a8(D3ZV),L


	SLEEP	60*2

	callr	_3d_freeobj


	DIE

#*******************************
* Player shot hit an obj
* A8=*3D object

 SUBRP	pl_shot_hit

	move	*a8(D3PLINK),a14,L
	movk	1,a0
	move	a0,*a14(PTIME)		;Wake it up so it can die

	rets


#*******************************
* Create random enemies (Process)

 SUBRP	en_spawner

#lp
	movi	-1000<<8,a10
	movi	12000<<8,a11
	CREATE0	en_tank

	SLEEP	TSEC*8/BOGRATE
	jruc	#lp


#*******************************
* Enemy fire randomly (Process)

 SUBRP	en_fire

;#lp	SLEEPK	5
;	movk	2,a0
;	callr	rndrng0
;	move	a0,a0
;	jrnz	#lp		;Wait?
;
;
;	CREATE0	en_msl
;
;	SLEEPK	5
;	jruc	#lp


#*******************************
* Fire a shell from an enemy (Process)
* A8=*3D object
* A10=Dir (0-255)

	STRUCTPD
	WORD	ens_hit		;!0=Shell collided with obj

HITRNG	.equ	450<<8

 SUBRP	en_shell

	movi	enfiresnd,a0
	calla	snd_play1

	clr	a0
	move	a0,*a13(ens_hit)

	move	*a8(D3X),a0,L
	move	*a8(D3Y),a1,L
	move	*a8(D3Z),a2,L
	clr	a3
	move	a10,a4
	not	a4
	clr	a5
	movi	enmsl_pts,a6
	movi	enmslline_t,a7
	callr	_3d_beginobj		;Get shell

	movi	CLSENMY|TYPSHELL,a0
	move	a0,*a8(D3ID)

	move	a10,a0
	callr	sinecos_get

	sll	1,a0			;*2
	move	a0,*a8(D3XV),L

	neg	a1
	sll	1,a1			;*2
	move	a1,*a8(D3ZV),L


	movi	TSEC*2/2,a11

#slp	SLEEPK	2

	move	*a13(ens_hit),a0
	jrnz	#xpld			;Hit something?

	move	*a8(D3X),a0,L
	move	@viewx,a1,L
	sub	a0,a1
	abs	a1
	cmpi	HITRNG,a1
	jrgt	#nxt

	move	*a8(D3Z),a0,L
	move	@viewz,a1,L
	sub	a0,a1
	abs	a1
	cmpi	HITRNG,a1
	jrle	#hitpl			;Nail player
#nxt
	dsj	a11,#slp

#xpld
	callr	_3d_freeobj


	DIE

#hitpl
	callr	_3d_freeobj

	move	@shield,a0
	subk	1,a0
	move	a0,@shield

	movi	plhit_snd,a0
	calla	snd_play1

	movi	-1,a0
	move	a0,@IRQSKYE
	SLEEPK	3
	movk	6,a0
	move	a0,@IRQSKYE

	DIE


#*******************************
* Enemy shell hit an obj
* A8=*3D object

 SUBRP	en_shell_hit

	move	*a8(D3PLINK),a14,L
	movk	1,a0
;	move	a0,*a14(PTIME)		;Wake it up so it can die
	move	a0,*a14(ens_hit)

	rets


#*******************************
* Enemy tank (Process)
* A10=X (24:8)
* A11=Z

	STRUCTPD
	WORD	tnk_dir		;Dir 0-255
	WORD	tnk_sdir	;Seek dir 0-255


 SUBRP	en_tank

	move	a10,a0
	movi	80<<8,a1
	move	a11,a2
	clr	a3
	clr	a4
	clr	a5
	movi	tanktur_pts,a6
	movi	tankturline_t,a7
	callr	_3d_beginobj		;Get turret
	move	a8,a9

	movi	CLSENMY|TYPTANK,a0
	move	a0,*a8(D3ID)

	move	a10,a0
	movi	40<<8,a1
	movi	tanklow_pts,a6
	movi	tanklowline_t,a7
	callr	_3d_beginobj		;Get chassie

	movi	CLSENMY|TYPTANK,a0
	move	a0,*a8(D3ID)

	movk	3,a0
	callr	rndrng0
	addk	1,a0
	move	a0,a11			;A11=Turn speed
#lp
	movi	>1f,a0
	callr	rnd
	jrnz	#noseek

	move	@viewx,a6,L		;24:8
	move	@viewz,a7,L
	callr	seekob_dir256
	move	a0,*a13(tnk_sdir)

#noseek
	move	*a13(tnk_sdir),a0
	move	*a13(tnk_dir),a7

	sub	a7,a0			;A0=Difference
	jrz	#noturn

	move	a0,a1
	abs	a0
	move	a0,a14
	subi	128,a0
	jrle	#350
	neg	a1
#350
	cmp	a11,a14
	jrge	#big
	add	a1,a7
	jruc	#mskt
#big
	move	a1,a1
	jrnn	#360
	sub	a11,a7
	jruc	#mskt
#360	add	a11,a7
#mskt
	sll	32-8,a7			;Make 0-255
	srl	32-8,a7
	move	a7,*a13(tnk_dir)

	move	a7,a0

	callr	sinecos_get
	sra	1,a0			;/2
	move	a0,*a8(D3XV),L
	move	a0,*a9(D3XV),L

	sra	1,a1			;/2
	neg	a1
	move	a1,*a8(D3ZV),L
	move	a1,*a9(D3ZV),L

	not	a7
	move	a7,*a8(D3YA)
	move	a7,*a9(D3YA)


#noturn
	movk	>7,a0
	callr	rnd
	jrnz	#nofire

	move	@viewx,a6,L		;24:8
	move	@viewz,a7,L
	callr	seekob_dir256
	move	*a13(tnk_dir),a10
	cmp	a0,a10
	jrne	#nofire			;!Facing player?
	CREATE0	en_shell

#nofire	SLEEPK	1

	jruc	#lp


#*******************************
* Kill enemy tank (Process)
* A8=*Tank chassie obj
* A9=*Tank turret obj

 SUBRP	en_tank_die

	movi	tankexpsnd,a0
	calla	snd_play1

	movi	130<<8,a0
	move	a0,*a8(D3YV),L
	movi	150<<8,a0
	move	a0,*a9(D3YV),L

	movk	30,a11

#lp	move	*a8(D3XA),a0
	addk	30,a0
	move	a0,*a8(D3XA)
	move	*a8(D3YA),a0
	addk	20,a0
	move	a0,*a8(D3YA)
	move	*a8(D3ZA),a0
	addk	15,a0
	move	a0,*a8(D3ZA)

	move	*a8(D3YV),a0,L
	subi	10<<8,a0
	move	a0,*a8(D3YV),L
	move	*a9(D3YV),a0,L
	subi	10<<8,a0
	move	a0,*a9(D3YV),L

	SLEEPK	1

	dsj	a11,#lp


	callr	_3d_freeobj
	move	a9,a8
	callr	_3d_freeobj

	DIE


#*******************************
* Enemy tank hit an obj
* A8=*Tank object

 SUBRP	en_tank_hit

	move	*a8(D3PLINK),a14,L
	movi	en_tank_die,a0
	move	a0,*a14(PWAKE),L	;Death routine
	clr	a0
	move	a0,*a14(PROCID)

	rets



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
* Quickly produce a random # in range 0-X
* A0=X
* >A0=Random # (0 to A0) (No CC)
* Trashes scratch

 SUBRP	rndrng0

	move	@RAND,a1,L
	rl	a1,a1
	move	@HCOUNT,a14
	rl	a14,a1
	add	sp,a1
	move	a1,@RAND,L

	addk	1,a0
	mpyu	a1,a0		;Condition codes not valid!

	rets


********************************
* Get velocity to move towards an object

 SUBRP	seekob_vel	;A0=*Dest obj, A3=Vel, A8=*Src obj

	PUSH	a0

	move	*a0(OXPOS),a6		;Get X
	move	*a0(OSIZEX),a2
	srl	1,a2
	add	a2,a6			;Center X
	move	*a0(OYPOS),a7		;Get Y
	move	*a0(OSIZEY),a2
	srl	1,a2
	add	a2,a7			;Center Y
	sll	16,a6
	sll	16,a7

	move	*a8(OXPOS),a0		;Get X
	move	*a8(OSIZEX),a2
	srl	1,a2
	add	a2,a0			;Center X
	move	*a8(OYPOS),a1		;Get Y
	move	*a8(OSIZEY),a2
	srl	1,a2
	add	a2,a1			;Center Y
	sll	16,a0
	sll	16,a1

	sub	a0,a6			;DestX-SrcX
	sub	a1,a7			;DestY-SrcY


sov60	sra	1,a6			;>Scale down to A3
	sra	1,a7
	move	a6,a2
	abs	a2
	cmp	a3,a2			;A6&A7 < A3
	jrgt	sov60
	move	a7,a2
	abs	a2
	cmp	a3,a2
	jrgt	sov60

	move	a6,a4			;>Fine scale up to A3
	move	a7,a5
	sra	4,a4			;/16
	sra	4,a5
	jrnz	sov150
	move	a4,a4
	jrz	sov200			;Both 0 then skip
sov150	add	a4,a6
	add	a5,a7
	move	a6,a2
	abs	a2
	cmp	a3,a2
	jrgt	sov200
	move	a7,a2
	abs	a2
	cmp	a3,a2
	jrle	sov150

sov200
	PULL	a0
	rets				;>A6=XV, A7=YV


#*******************************
* Get dir to face an object
* A6=Dest X
* A7=Dest Z
* A8=*Source 3D obj
* >A0=0-255
* Trashes A0-A2,A14

 SUBRP	seekob_dir256

	move	*a8(D3X),a0,L		;Get SX
	move	*a8(D3Z),a1,L		;Get SZ

	clr	a2			;Octant 0-1
	sub	a6,a0			;A0=SrcX-DestX
	jrgt	#100
	abs	a0
	sub	a7,a1			;A1=SrcY-DestY
	jrnn	#oct01
	movk	8,a2			;Oct 2-3
	abs	a1
	jruc	#160

#100	movk	16,a2			;Oct 4-5
	sub	a7,a1			;A1=SrcY-DestX
	abs	a1
	jrnn	#200
	movk	16+8,a2			;Oct 6-7
#160	SWAP	a0,a1

#200	sll	3,a2			;Oct*8
#oct01	clr	a14
	cmp	a1,a0			;>Cmp slope
	jrhs	#300

	srl	2+3,a1			;Bigger/32
	jruc	#250
#lp1	addk	1,a2			;Next 1/32 oct
	add	a1,a14			;+1/32
#250	cmp	a0,a14
	jrlo	#lp1
	jruc	#x

#300	addi	63,a2			;End of next octant
	srl	2+3,a0			;Bigger/32
	jruc	#350
#lp2	subk	1,a2			;Next 1/32 oct
	add	a0,a14			;+1/32
#350	cmp	a1,a14
	jrlo	#lp2


#x	movi	>ff,a0
	and	a2,a0
	rets


********************************
* Get sine or cosine
* A0=Angle (0-255)
* >A0=0-16384*4

 SUBRP	cos_get

	sll	32-8,a0
	srl	32-8-4,a0	;*16
	addi	cos_t,a0
	move	*a0,a0
	sll	2,a0		;*4
	rets

 SUBRP	sine_get

	sll	32-8,a0
	srl	32-8-4,a0	;*16
	addi	sine_t,a0
	move	*a0,a0
	sll	2,a0		;*4
	rets


********************************
* Get sine and cosine
* A0=Angle (0-255)
* >A0=Sine (0-16384*4)
* >A1=Cos (0-16384*4)

 SUBRP	sinecos_get

	sll	32-8,a0
	srl	32-8-4,a0		;*16
	addi	sine_t,a0
	move	*a0(cos_t-sine_t),a1
	move	*a0,a0
	sll	2,a0			;*4
	sll	2,a1			;*4
	rets



sine_t
	.word	0,402,803,1205,1605,2005,2404,2801
	.word	3196,3589,3981,4369,4756,5139,5519,5896
	.word	6270,6639,7005,7366,7723,8075,8423,8765
	.word	9102,9434,9760,10080,10394,10701,11003,11297
	.word	11585,11866,12140,12406,12665,12916,13160,13395
	.word	13623,13842,14053,14255,14449,14635,14811,14978
	.word	15137,15286,15426,15557,15678,15790,15893,15986
	.word	16069,16143,16207,16261,16305,16340,16364,16379
cos_t
	.word	16384,16379,16364,16340,16305,16261,16207,16143
	.word	16069,15986,15893,15791,15679,15557,15426,15286
	.word	15137,14978,14811,14635,14449,14256,14053,13842
	.word	13623,13395,13160,12916,12665,12406,12140,11866
	.word	11585,11297,11003,10702,10394,10080,9760,9434
	.word	9102,8765,8423,8076,7723,7366,7005,6639
	.word	6270,5896,5519,5139,4756,4370,3981,3590
	.word	3196,2801,2404,2005,1606,1205,804,402
	.word	0,-401,-803,-1205,-1605,-2005,-2403,-2800
	.word	-3196,-3589,-3980,-4369,-4755,-5139,-5519,-5896
	.word	-6269,-6639,-7005,-7366,-7723,-8075,-8423,-8765
	.word	-9102,-9434,-9760,-10080,-10394,-10701,-11002,-11297
	.word	-11585,-11866,-12139,-12406,-12665,-12916,-13160,-13395
	.word	-13623,-13842,-14053,-14255,-14449,-14634,-14811,-14978
	.word	-15137,-15286,-15426,-15557,-15678,-15790,-15893,-15986
	.word	-16069,-16143,-16207,-16261,-16305,-16340,-16364,-16379
	.word	-16384,-16379,-16364,-16340,-16305,-16261,-16207,-16143
	.word	-16069,-15986,-15893,-15791,-15679,-15557,-15426,-15286
	.word	-15137,-14979,-14811,-14635,-14449,-14256,-14053,-13842
	.word	-13623,-13395,-13160,-12916,-12665,-12406,-12140,-11866
	.word	-11585,-11298,-11003,-10702,-10394,-10080,-9760,-9434
	.word	-9103,-8765,-8423,-8076,-7723,-7366,-7005,-6640
	.word	-6270,-5897,-5520,-5139,-4756,-4370,-3981,-3590
	.word	-3196,-2801,-2404,-2006,-1606,-1205,-804,-402
	.word	0,402,803,1205,1605,2005,2404,2801
	.word	3196,3589,3981,4369,4756,5139,5519,5896
	.word	6270,6639,7005,7366,7723,8075,8423,8765
	.word	9102,9434,9760,10080,10394,10701,11003,11297
	.word	11585,11866,12140,12406,12665,12916,13160,13395
	.word	13623,13842,14053,14255,14449,14635,14811,14978
	.word	15137,15286,15426,15557,15678,15790,15893,15986
	.word	16069,16143,16207,16261,16305,16340,16364,16379






#*******************************
* Build lists and collide based on X
* A6=XMin
* A7=XMax (+1)

 SUBRP	_3d_collide

	movi	d3world_t,a3		;World table to check

	movi	pcoll_t,a9		;Build collision lists
	movi	ecoll_t,a10
	movi	ncoll_t,a11
	move	a9,b4			;Set A5/B4 for 1st collision call
	move	a10,a5
	jruc	#next

#enmy	move	a0,*a10+,L		;Insert on enemy list
#next	move	*a3+,a0,L		;Get next obj
	jrz	#end

	move	*a0(D3ID),a14
	jrz	#next			;Not collideable?

;	move	*a0(OXPOS),a1		;Obj can lie on max/min boundary
;	cmp	a7,a1
;	jrge	#next			;Out of range?
;
;	move	*a0(OSIZEX),a2
;	add	a2,a1
;	cmp	a6,a1
;	jrle	#next			;Out of range?

	move	a14,a14			;Check Class
	jrn	#enmy			;Enemy?
	btst	14,a14
	jrnz	#plyr			;Player?

	move	a0,*a11+,L		;Insert on neutral list
	jruc	#next

#plyr	move	a0,*a9+,L		;Insert on player list
	jruc	#next

#end	move	a0,*a9,L		;Null terminate each list
	move	a0,*a10,L
	move	a0,*a11,L

	callr	collidelists		;Collide enemy to player

	movi	ncoll_t,a5
	movi	ecoll_t,b4
	callr	collidelists		;Collide neutral to enemy

	movi	ncoll_t,a5
	movi	pcoll_t,b4
;	jruc	collidelists		;Collide neutral to player
					;Fall through

#*******************************
* Collide objects on list A5 with those on LIST B4
* A5,B4=ptrs to null terminated tables of object ptrs

collidelists

#lp	move	*a5+,a1,L
	jrz	#x
					;Load up coors of obj from first list
	move	*a1(D3X),a9,L		;A9=OBJ1 Xmin
;	jrz	#lp			;Deleted?
	subi	100<<8,a9
;	move	*a1(D3XS),a10		;A10=OBJ1 Xmax (+1)
	movi	200<<8,a10
	add	a9,a10
	move	*a1(D3Z),a7,L		;A7=OBJ1 Ymin
	subi	100<<8,a7
;	move	*a1(OSIZEY),a11		;A11=OBJ1 Ymax (+1)
	movi	200<<8,a11
	add	a7,a11

	move	b4,a6			;Load head of second list

#lp2	move	*a6+,a2,L
	jrz	#lp


	move	*a2(D3Z),a0,L		;Check objs A1,A2 for intersection
	subi	100<<8,a0
	cmp	a11,a0
	jrge	#lp2			;Y2Min >= Y1Max?
	movi	200<<8,a14
;	move	*a2(OSIZEY),a14
	add	a14,a0
	cmp	a7,a0
	jrle	#lp2			;Y2Max <= Y1Min?

	move	*a2(D3X),a0,L		;Signed compares because objs may lie on 0
;	jrz	#lp2			;Deleted?
	subi	100<<8,a0
	cmp	a10,a0
	jrge	#lp2			;X2Min >= X1Max?
	movi	200<<8,a14
;	move	*a2(OSIZEX),a14
	add	a14,a0
	cmp	a9,a0
	jrle	#lp2			;X2Max <= X1Min?

	callr	ColFunc			;>Call colfunc for obj A1 and A2
	move	b0,b1			;B1=*Collision routine for obj A1
	SWAP	a1,a2
	callr	ColFunc
	SWAP	a1,a2
	move	b0,b2			;B2=*Collision routine for obj A2
	or	b1,b0			;Set z flag if both are zero
	jrz	#lp2


	clr	a0
	move	a0,@d3collstop		;Clr flag

	move	b1,b1
	jrz	pobj2col
	move	a1,a8
	move	a2,a0
	call	b1			;Call collision for A1

pobj2col
	move	b2,b2
	jrz	pckfree
	move	a2,a8
	move	a1,a0
	call	b2			;Call collision for A2

pckfree	move	@d3collstop,a0
	jrz	#lp2			;Continue scan?
	jruc	#lp

#x	rets


****************************************************************************
* Return in B0 routine for obj A1 struck by obj A2
* Trashes A3-A4

ColFunc
	movb	*a1(D3ID+8),a3
	movb	*a2(D3ID+8),a4
	sll	32-5,a3
	srl	17,a3		;32 Long Word Align
	sll	32-5,a4
	srl	22,a4		;Long Align
	add	a4,a3
	addi	typetbl,a3

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

typetbl
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
;Player shot
	.LONG	NULL, NULL, NULL, PSGO, PSTK, PSSH, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;300
;Ground obstacle
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;400
;Tank
	.LONG	NULL, NULL, TKPS, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
	.LONG	NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
;500
;Shell
	.LONG	NULL, NULL, SHPS, SHGO, NULL, NULL, NULL, NULL
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


PSGO
PSTK
PSSH
	movi	pl_shot_hit,b0
	rets

TKPS
	movi	en_tank_hit,b0
	rets

SHPS
SHGO
	movi	en_shell_hit,b0
	rets


;	move	*a1(OZPOS),a0
;	move	*a2(OZPOS),a14
;	sub	a14,a0
;	move	a0,a3
;	abs	a3
;	cmpi	30,a3
;	jrhi	NULL			;Not in range?
;
;	movi	ball_hit,b0
;	rets




#***************************************************************
* Display secret embedded copyright notice (Process)

	STRUCTPD
	STRUC	cpm_s	,8*80

 SUBRP	copyright_prtmsg

	movi	#cr1_s,a1
	movi	[50,200],a9
	JSRP	copyright_prt

	movi	#cr2_s,a1
	movi	[80,200],a9
	JSRP	copyright_prt

	movi	#cr3_s,a1
	movi	[110,200],a9
	JSRP	copyright_prt

	movi	#cr4_s,a1
	movi	[140,200],a9
	JSRP	copyright_prt

	SLEEP	TSEC*20/BOGRATE

	jruc	pldead



copyright_prt

	movk	2,a3			;>Decode string
	move	a13,a2
	addi	cpm_s,a2
	setf	8,0,0
#lp
	move	*a1+,a0
	sub	a3,a0			;-encode value
	move	a0,*a2+
	addi	37,a3
	sll	32-8,a0
	jrnz	#lp

	setf	16,1,0

	movi	GOLD,a0			;>Print string
	calla	pal_getf
	move	a0,a6

	move	a13,a8
	addi	cpm_s,a8
	clr	a0
	movk	1,a10
	movi	osgfont_t,a11
	JSRP	STRCNRMO_1

	RETP



ASCIIE	.macro	str

	.var	i,c,e
	.eval	1,i
	.eval	2,e
	.loop	$symlen(str)
	.asg	:str(i):,c
	.byte	0ffh & (':c:'+e)
	.eval	i+1,i
	.eval	e+37,e
	.endloop
	.byte	0ffh & :e:

	.endm


#cr1_s	ASCIIE	"NBA-JAM"
#cr2_s	ASCIIE	"COPYRIGHT-1993"
#cr3_s	ASCIIE	"MIDWAY-MANUFACTURING-COMPANY"
#cr4_s	ASCIIE	"ALL-RIGHTS-RESERVED"




	.end
