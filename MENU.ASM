**************************************************************
*
* Software:		LARRY DEMAR and DR. J
* Initiated:		?
*
* Modified:		Shawn Liptak, 11/1/91	-Total carnage
* 			Shawn Liptak, 1/20/92	-Coinage from T2, Dipswitch
* 			Shawn Liptak, 1/24/92	-Coinage corrections
* 			Shawn Liptak, 3/4/92	-Basketball mods
* 			Shawn Liptak, 10/2/92	-TUNIT sound mods
*	 		GEORGE PETRO, 1/17/93	-NBA JAM
*
* COPYRIGHT (C) 1992 WILLIAMS ELECTRONICS GAMES, INC.
*
*.Last mod - 3/24/93 18:27
**************************************************************
	.file	"menu.asm"
	.title	"test menus"
	.width	132
	.option	b,d,l,t
	.mnolist


	.include	"mproc.equ"
	.include	"disp.equ"
	.include	"sys.equ"
	.include	"imgtbl.glo"
	.include	"imgtbl2.glo"
	.include	"game.equ"
	.include	"link.equ"
	.include	"menu.equ"
	.include	"shawn.hdr"		;Macros

	.text

;	 IN THIS MODULE

	.DEF	MEN_MAIN,GET_CSPT
	.DEF	MESS_FAC
	.DEF	ANY_BUT,MEN_YN
	.DEF	STR_OBJ
	.DEF	STR_FREE
	.DEF	CKPROMPT
	.DEF	GO_DIAG		;ROUTINE FOR DIAGNOSTIC MENU
	.DEF	RTR_LEV,ROM_LEV
	.DEF	MESS_MM
	.DEF	CS_ENTS		;NUMBER OF HIGHEST IN COIN TABLE
	.DEF	TWO_TS,TWO_TP
	.DEF	FAC_STUF
	.DEF	BUILD_ST
	.DEF	SCODE		;SYNTH CODE CURRENTLY BEING MADE
	.DEF	DCODE		;DIG CODE CURRENTLY BEING MADE
	.DEF	HID_P
	.DEF	SNDTST
	.DEF	USA_1, USA_2, USA_3, USA_4, USA_ELECTITLE
	.DEF	GERMAN_1, GERMAN_2, GERMAN_3, GERMAN_4, GERMAN_ELECTITLE
	.DEF	FRENCH_1, FRENCH_2, FRENCH_3, FRENCH_4, FRENCH_ELECTITLE
	.DEF	DIPCOINTAB

;	IN SOUNDS.ASM
	.ref	snd_reset, QSNDRST

;	 IN TEST.ASM

	.ref	fudge_switches,fudge_switches2
	.ref	fswitches_cur,fswitches_last,fswitches_down
	.REF	WDOGDIS,pal_getf
	.REF	GEN_MENU,B_MENU
	.REF	L_MESS,TOP_BOX
	.REF	GET_AUD
	.REF	LM_FINIS
	.REF	BAD_AUD
	.REF	MAIN_RET
	.REF	AREUSURE
	.REF	F_TITLE
	.REF	ST_STICK
	.REF	GETSTICK
	.REF	FAC_SET
	.REF	SUR_MESS
	.REF	SURE_BOX
	.REF	GET_FAC
	.REF	WAIT_BUT
	.REF	DIGSRT
	.REF	DIAG_EX
;	.REF	GET_ADV
	.REF	STD_BORD
	.REF	SND_MADE
	.REF	NO_CLEAR
	.REF	LAST_BUT
	.REF	G_BORDER
	.ref	opmsg_main

;	IN AUDIT.ASM

	.REF LM_SETUP
;	.REF ROM_NAME
	.REF GET_ADJ
	.REF STRCAT
;	.REF CLR_SUBS
	.REF NO_CREDS
	.REF CLR_AUDR
	.REF CLR_AUD
	.REF CAT_A0
	.REF CK_MAX
	.REF ADJ_PAGE
	.REF F_ADC_S
	.REF WC_BYTEI
	.REF RC_WORD
	.REF DEF_PAGE
	.REF WAIT_MUT
	.REF STORE_AUDIT

;	IN HSTD.ASM

	.REF	INIT_TB,FORM_ADC,WC_WORD,CMOS_VAL
	.REF	P_FORK,GET_HSC,INIT_HSR

;	IN ADJUST.ASM

	.REF	GO_ADJ


;	IN UTIL.ASM

	.ref	FILLAREA
	.ref	CLR_SCRN
	.ref	dpageflip_off

;	IN ATT.ASM

	.ref	amode_start

;DIAG STUFF

	.ref	show_player_records
	.ref	SWITCHTEST
	.REF	COL_BARS,CROSS_H,BURN_IN,STRNEW1

	.REF	RD15FONT,SCRCLR,display_init,STRCNRM,GAMSTATE
	.REF	STRNGRAM,BLNKAREA,STRLNRM,RD7FONT,HEXTOASC
	.REF	CLR_SCRN,STRRNRM
	.REF	WARMSET, DIAGCPUTEST

	.BSS	FAC_FLAG,16		;FLAG SAYS CLEAR AUDITS AND HSTABLE
					;IF FACTORY SETTINGS SUCCEED.
	.BSS	SCODE,16		;SYNTH CODE LAST MADE!
	.BSS	DCODE,16		;DIG CODE LAST MADE!
	.BSS	TMPOBJ,32		;TEMPORARY OBJECT FROM STR_OBJ

	BSSX	octopus2,16



**************************************************************************
*									 *
*	   COIN TABLE							 *
*									 *
**************************************************************************
*
*	The coin table is made up of the normal entries from
*	the pinball system, as well as some new ones that
*	determine start and buy-in cost, and others that
*	aid in the determination of a "total collection".
*
*	Left Slot Multiplier		word
*	Center Slot Multiplier		word
*	Right Slot Multiplier		word
*	Units for Credit		word
*	Units for Bonus			word
*	Minimum Units			word
*	Credits to start		word
*	Credits to Continue		word
*	Divisor in money calculation	word   0 means "OFF"
*
* --------------------------------------------------------------
* The above value get copied as adjustments (and are adjustable).
* In addition, the coin table contains help on how to arrive at
* the "Total Collection" for the coin audits.
* --------------------------------------------------------------
*
*	Count for each Left coin		word
*	Count for each Center coin		word
*	Count for each Right coin		word
*	Pointer to Leading text string		long
*	Pointer to Following text string	long
*
**************************************************************************
*
*	GET_CSPT
*
*	THIS IS CALLED TO RETURN IN A6 THE CURRENT
*	CSELCT LINE AS STORED IN THE ADJUSTMENT TABLE.
*
**************************************************************************
GET_CSPT
	PUSH	a0
	movk	ADJPRICE,a0
	CALLA	GET_ADJ 	;GET THE COIN SELECT NUMBER BEING USED.
	CALLR	CS_POINT
	PULL	a0
	RETS
	
**************************************************************************
* CS_POINT - Point at selected entry in the coinage select table
* A0=Offset #
* Rets: A6=*Coinage table
**************************************************************************
CS_POINT
	MMTM	SP,A0,A1
	MOVE	A0,A0		;ZERO?
	JRZ	CS1		;YEP...RETURN FIRST LINE

	CMPI	CS_ENTS,A0	;IN RANGE?
	JRLS	CS2		;YEP...CONTINUE
	MOVK	1,A0		;TOO LARGE.......USE 1ST LINE.

CS2	DEC	A0		;INDEX INTO TABLE
CS1	MOVI	CS_SIZE,A1	;SIZE PER ENTRY
	MPYU	A0,A1		;OFFSET INTO TABLE
	ADDI	CSELCT,A1
	MOVE	A1,A6		;RETURN THE POINTER
	MMFM	SP,A0,A1
	RETS

**************************************************************************
*
*	CKPROMPT
*
*	IS THERE A PROMPT STRING FOR THE CREDITS PAGE.
*
*	A0 RETURNS:
*
*	YES.....RETURN POINTER TO SOMETHING
*	NO......RETURN ZERO
*
*	IF A0 HAS A POINTER THEN....
*
*	IF A1 = 0 THEN A0 IS AN L_MESS STRING THAT SHOULD
*		JUST BE SENT OUT.
*
*	IF A1 != 0 THEN A0 IS A POINTER LIST OF UP TO 2 MESSAGES.
*		THAT GIVE PRICING INFO
*
*	A1 = 0 PLOT THE A0 STRING OUTRIGHT USING L_MESS
*		(IT CONTAINS ALL DATA)
*
*	A1 = 1  PLOT ONLY THE STRING LIST (1 OR 2 POINTERS
*		CENTERED APPROPRIATELY
*
*	A1 = 2  PLOT THE 1ST LINE OF THE STRING LIST ALONG
*		WITH THE 2 CREDITS TO START...1 TO CONTINUE
*
*	A1 = 3  PLOT THE 2ND LINE OF THE STRING LIST ALONG
*		WITH THE 2 CREDITS TO START...1 TO CONTINUE
*
*	A1 = 4  PLOT THE 3RD LINE OF THE STRING LIST ALONG
*		WITH THE 2 CREDITS TO START...1 TO CONTINUE
*
*	A1 = 5  PLOT THE 1ST LINE OF THE STRING LIST ALONG
*		ALONG WITH 2 COINS PER PLAYER
*
*	A1 = 6  PLOT THE 2ND LINE OF THE STRING LIST ALONG
*		ALONG WITH 2 COINS PER PLAYER
*
*	A1 = 7  PLOT THE 3RD LINE OF THE STRING LIST ALONG
*		ALONG WITH 2 COINS PER PLAYER
*
*	A1 = 8  CUSTOM MESSAGE
*
**************************************************************************
								
CKPROMPT
	PUSH	a6
	movk	ADJFREPL,a0
	CALLA	GET_ADJ
	jrnz	RET_NO			;Free play?

	CALLA	CK_MAX			;ARE WE AT MAX CREDITS?
	JRHS	RET_MAX

	movk	ADJNOCPAG,a0
	CALLA	GET_ADJ 		;CHECK THE ADJUSTMENT
	JRNZ	CKSPCASE		;WE'RE SET TO SHUT UP.JUST START/CONT

	movk	ADJ1ST6,a0		;has operator messed around?
	CALLA	GET_ADJ
	JRZ	CKSPCASE		;YEP...GO FOR GENERIC "2 TO START"

*	OPERATOR IS USING CANNED COINAGE....WE NEED TO USE THE
*	CHECK IF ITS 2/1 OR 2/2

	CALLR	CK_2_CRED		;IS IT A 2 CREDIT MODE?
	JRZ	NOT_2_MODE		;NOPE...PRINT STOCK STUFF

	MOVE	A0,A1			;COPY 2/1	 2/2 CODE
	CALLR	GET_CSPT		;POINT A6 AT CSEL FOR US NOW.
	MOVE	*A6(CS_PICK),A0		;GET INDICATION OF WHICH LINE
	JRZ	CKSPCASE		;IT SAYS JUST ENUMERATE THE MODE!

*	NOW....IF ITS 2/1, A0 HAS THE CORRECT RETURN CODE
*	IF ITS 2/2 WE NEED TO ADD 2

	subk	1,a1
	JRZ	RET_A0_VAL		;2/1?

	addk	3,a0
	JRUC	RET_A0_VAL		;RETURN THIS!

NOT_2_MODE
	CALLR	GET_CSPT		;POINT A6 AT CSEL FOR US NOW.
	MOVE	*A6(CS_PROMPT),A0,L	;FETCH POINTER TO MESSAGE (IF ANY)
	JRZ	CKSPCASE
					;WE HAVE SOMETHING STORED AT THE PROMPT
	CMPI	CSM_LAST,A0		;IS IT LITTLE?
	JRHI	CKEXIT			;NOPE..ITS A POINTER..RETURN L_MESS STATUE

RET_A0_VAL
	MOVE	A0,A1			;ITS LITTLE...RETURN IT AS A CODE
	MOVE	*A6(CS_LIST),A0,L	;PASS BACK MESSAGE LIST FOR THIS MODE
	JRUC	CK_BYE

RET_NO	CLR	A0			;IT IS FREE PLAY.
CKEXIT	CLR	A1			;NO FANCIES YET
CK_BYE	PULL	a6
	move	a0,a0			;Pass Z
	rets

*	CONTROL COMES HERE IF IT LOOKS LIKE NO MESSAGE IS
*	APPROPRIATE....CHECK FOR 2 TO START 1 TO CONTINUE GENERIC NEEDED.

CKSPCASE
	CALLR	CK_2_CRED		;CHECK IF THERE ARE 2 CREDIT MODES.
	JRZ	RET_NO			;NOT A 2 CREDIT MODE.

	subk	1,a0
	JRZ	TWO_ONE			;YEP...RETURN 2/1

	MOVI	TWO_CRED_PER_PLAYER,A0
	JRUC	CKEXIT			;RETURN IT!


TWO_ONE	MOVI	TWO_TO_START_2C,A0


	JRUC	CKEXIT

RET_MAX	MOVI	MAX_C_M,A0
	JRUC	CKEXIT


**************************************************************************
* CK_2_CRED - Checks if in a 2-credit to start mode
*
* A0=0	NOT 2/1 OR 2/2 CREDIT MODE
* A0=1	2 TO START 1 TO CONTINUE
* A0=2	2 TO START 2 TO CONTINUE
*
* Z	NOT 2/1 OR 2/2 CREDIT MODE
* NZ	IS 2/1 OR 2/2 CREDIT MODE
**************************************************************************
CK_2_CRED
	MOVI	ADJCSTRT,A0
	CALLA	GET_ADJ 	;HOW MANY TO START
	subk	2,a0
	jrnz	c2c20		;!2 to start?

	MOVI	ADJCCONT,A0
	CALLA	GET_ADJ 	;GET CONTINUE NUMBER
	cmpi	2,a0		;1 or 2 is what we return
	jrhi	c2c20		;>2?
	move	a0,a0		;Return NZ (unless its 2/0)
	rets

c2c20	clr	a0		;Pass Z
	rets

**************************************************************************
*									 *
*	   MENU HANDLING SOFTWARE					 *
*									 *
**************************************************************************

**************************************************************************
*									 *
*	   FORCE_MAIN							 *
*									 *
*	   THIS IS CALLED TO GET TO MAIN MENU FROM LEVEL FURTHER	 *
*	   THAN 1 DOWN.  IT SETS THE GLOBAL FLAG "MAIN_RET"		 *
*	   NON ZERO.  GEN_MENU WILL KEEP RETURNING UNTIL		 *
*	   IT GETS BACK TO THE MAIN MENU.				 *
*									 *
**************************************************************************
FORCE_MAIN
	MOVK	1,A0		;POSITIVE NUMBER FORCES MAIN MENU.
	MOVE	A0,@MAIN_RET
	RETP			;NOW "RETURN TO THE MENU"

**************************************************************************
*									 *
*	  DIAGNOSTIC TESTS SELECTED......SHOW DIAGNOSTIC TEST MENU	 *
*									 *
**************************************************************************
GO_DIAG
	MOVI	MEN_DIAG,A8	;PUT UP THE MENU AND GO!
	JAUC	GEN_MENU	;THIS WILL RETURN TO LEVEL ABOVE US!

**************************************************************************
*									 *
*	  COIN BOOKKEEPING SELECTED					 *
*									 *
**************************************************************************
gb20	JSRP	DO_CLCOIN
GO_BOOK
	CALLA	CLR_SCRN
	MOVI	MES_BOOK,A2
	MOVI	ROBO_WHITE,A3
	JSRP	TOP_BOX 		;PRINT TITLE BOX.

	MOVI	COIN_AUDS,A0		;PUT TABLE UP.
	JSRP	PRNT_AUD
	MOVI	COIN1_AUDS,A0		;PUT TABLE UP.
	JSRP	PRNT_AUD

	MOVI	AUDLCOIN,A8		;NOW PRINT MONEY FOR 1ST 3
	JSRP	PRINT_COL

	MOVI	COIN2_AUDS,A0		;PUT TABLE UP.
	JSRP	PRNT_AUD



;	MOVI	COIN_A2,A0		;PUT PART 2 OF THE TABLE THERE.
;	JSRP	PRNT_AUD

	MOVI	MEN_DETAIL,A8
	MOVK	2,A9			;CURSOR ON 2nd ENTRY
	JSRP	B_MENU			;SEE IF THEY WANT PAGE 2.
	CMPI	1,A8			;DID WE GET 1'ST ENTRY?
	jreq	gb20

	RETP


;DETAIL_SCREEN
;	 CALLA	 CLR_SCRN		;CLEAR OUT FOR ACTION!
;
;	 MOVI	 DT_Y1,A0		;HEIGHT OF TOP TITLE
;	 MOVI	 ROBO_YELLOW,A9		;COLOR
;	 CALLA	 F_TITLE		;FRAME IT
;
;	 MOVI	 DT_Y2,A0		;HEIGHT OF 2ND TITLE
;	 CALLA	 F_TITLE		;FRAME IT
;
;	 MOVI	 DETAIL_TITLES,A8     ;NO ROOM FOR PRETTY TOP BOX...DO TITLES
;	 JSRP	 L_MESS 	      ;ESTABLISH THE TITLES.
;
;	 MOVI	 COIN_D1,A0	      ;DETAILED AUDIT 1
;	 JSRP	 PRNT_AUD	      ;PRINT IT
;
;	 MOVI	 AUDLCOIN,A8	      ;NOW PRINT MONEY FOR 1ST 3
;	 JSRP	 PRINT_COL	
;
;	 MOVI	 AUDLCSUB,A8	      ;SUB-TOTAL OF TOTAL MONEY
;	 JSRP	 PRINT_SUBTOTAL       ;PRINT IT.
;
;	 MOVI	 COIN_D2,A0	      ;DETAILED AUDIT 2
;	 JSRP	 PRNT_AUD
;
;	 MOVI	 AUDLCDC,A8	      ;NOW PRINT MONEY FOR DOOR CLOSED SET
;	 JSRP	 PRINT_COL
;
;	 MOVI	 AUDLCDCS,A8	      ;NOW PRINT SUB-TOTAL FOR DOOR CLOSED
;	 JSRP	 PRINT_SUBTOTAL       ;THATS IT!
;
;	 MOVI	 MEN_CLR_SUB,A8       ;CLEAR SUBTOTAL OR RETURN TO MAIN MENU
;	 MOVI	 2,A9		      ;CURSOR ON 2ND ENTRY
;	 JSRP	 B_MENU 	
;
;	 CMPI	 1,A8		      ;CHOICE 1 IS CLEAR.....
;	 JRNZ	 NO_CLEAR_SUB	      ;NOPE...RETURN TO CALLER!
;
;	 MOVI	 MESS_CLEAR_SUBS,A8   ;CLEAR COIN SUB-TOTALS...ARE YOU SURE
;	 MOVI	 CLR_SUBS,A9	      ;ROUTINE TO DO IT
;	 MOVI	 MESS_SUBS_CLEAR,A10  ;CONFIRMATION.
;	 JSRP	 AREUSURE	      ;ASK EM.
;	 JRUC	 DETAIL_SCREEN	      ;NOW PUT THIS SCREEN BACK UP.
;
;NO_CLEAR_SUB
;NO_DETAIL
;	 RETP			      ;AND RETURN TO OUR CALLER.
;
;PRINT_SUBTOTAL
;	  CALLR   ADD_AUDIT_DY	       ;PUSH THE Y 1 LEVEL
;	  MOVI	  T_SUB,A9	       ;USE "SUB-TOTAL" MESSAGE
;	  JAUC	  PRINT_MONEY	       ;AND NOW PRINT THE REQUESTED SUM.

**************************************************************************
*									 *
*	   GAME AUDITS SELECTED 					 *
*									 *
**************************************************************************

**************************************************************************
*									 *
*	   AUDITS TO BE SHOWN ON GAME AUDITS PAGE:			 *
*									 *
*	   EXTRA MEN							 *
*	   GAMES COMPLETED						 *
*	   1 PLAYER MINUTES						 *
*	   2 PLAYER MINUTES						 *
*	   TOTAL HOURS PLAYED						 *
*	   AVG "PLAYER" GAME TIME					 *
*	   AVG. ELAPSED TIME / PLAY					 *
*									 *
**************************************************************************

GO_AUD
	CALLA	CLR_SCRN
	MOVI	MES_AUD,A2
	MOVI	ROBO_CYAN,A3
	JSRP	TOP_BOX 	;PRINT TITLE BOX.

	MOVI	GAME_AUDS,A0	;PUT TABLE UP.
	JSRP	PRNT_AUD

	MOVI	MEN_AP1,A8	;AUDIT PAGE 1 MENU
	MOVK	1,A9		;CURSOR ON 1ST ENTRY
	JSRP	B_MENU		;SEE IF THEY WANT PAGE 2.

	CMPI	1,A8		;DID WE GET 1'ST ENTRY?
	JRNZ	NO_AP2		;NOPE...RETURN TO OUR CALLER


#page2
	CALLA	CLR_SCRN

	MOVI	MES_AUD,A2
	MOVI	ROBO_CYAN,A3
	JSRP	TOP_BOX 	;PRINT TITLE BOX.

	MOVI	GAME_AUDS1a,A0	;PUT TABLE UP.
	JSRP	PRNT_AUD

	MOVI	MEN_AP2,A8
	MOVK	1,A9		;CURSOR ON 1ST ENTRY
	JSRP	B_MENU		;SEE IF THEY WANT PAGE 2.
	cmpi	2,A8		;DID WE GET 2nd ENTRY (RETURN TO PAGE 1)
	jreq	GO_AUD		;YEP...PUT IT UP!




#page3
	CALLA	CLR_SCRN

	MOVI	MES_AUD,A2
	MOVI	ROBO_CYAN,A3
	JSRP	TOP_BOX 	;PRINT TITLE BOX.

	MOVI	GAME_AUD2a,A0	;PUT TABLE UP.
	JSRP	PRNT_AUD
	MOVI	GAME_AUD2b,A0	;PUT TABLE UP.
	JSRP	PRNT_AUD

	MOVI	MEN_AP3,A8
	MOVK	1,A9		;CURSOR ON 2ND ENTRY
	JSRP	B_MENU		;SEE IF THEY WANT PAGE 2.
	CMPI	2,A8		;DID WE GET 2nd ENTRY (RETURN TO PAGE 2)
	JRZ	#page2		;YEP...PUT IT UP!

NO_AP2
	RETP

GO_UTIL
	MOVI	MEN_UTIL,A8
	JAUC	GEN_MENU	;PROCESS THE UTILITY MENU!
*
*	INDIVIDUAL UTILITY PROGRAMS
*

DO_CLCRED
	MOVI	MESS_CLCRED,A8	;CLEAR COIN SUB-TOTALS...ARE YOU SURE
	MOVI	CLR_CREDITS,A9	;ROUTINE TO DO IT
	MOVI	MESS_CCCONF,A10	;CONFIRMATION.
	JAUC	AREUSURE	;ASK EM......THEN RETURN!

**************************************************************************
*									 *
*	   CLR_CREDITS							 *
*									 *
*	   ROUTINE TO CLEAR OUT THE CREDITS POSTED ON THE GAME. 	 *
*									 *
**************************************************************************
CLR_CREDITS
	CALLA	NO_CREDS		;CALL THE ROUTINE THAT DOES IT
	RETP

DO_CLCOIN
	MOVI	MESS_CLCOIN,A8		;CLEAR COIN SUB-TOTALS...ARE YOU SURE
	MOVI	CLR_COINS,A9		;ROUTINE TO DO IT
	MOVI	MESS_CCNCONF,A10	;CONFIRMATION.
	JAUC	AREUSURE		;ASK EM......THEN RETURN!

CLR_COINS
	MOVI	FRST_C,A0
	MOVI	LAST_C,A1
	CALLA	CLR_AUDR
	RETP

DO_CLAUD
	MOVI	MESS_CLAUD,A8		;CLEAR COIN SUB-TOTALS...ARE YOU SURE
	MOVI	CLR_AUDITS,A9		;ROUTINE TO DO IT
	MOVI	MESS_CAUDCONF,A10	;CONFIRMATION.
	JAUC	AREUSURE		;ASK EM......THEN RETURN!

DO_CLPLRECS
	movi	MESS_CLPLRECS,A8	;CLEAR PLAYER RECORDS
	movi	clr_plr_records,a9	;ROUTINE TO DO IT
	movi	MESS_CLPLRECSCONF,a10	;CONFIRMATION.
	jauc	AREUSURE		;ASK EM......THEN RETURN!

	.global	clear_player_records
clr_plr_records
	calla	clear_player_records
	RETP

CLR_AUDITS
	MOVI	FRSTGAUD,A0
	MOVI	LASTGAUD,A1
	CALLA	CLR_AUDR
;	CALLA	DUMP_FS 		;AND START THE "DUMP" RECORDS OVER
	RETP

DO_HSRES
	MOVI	MESS_HSRESET,A8
	MOVI	HSSOFT,A9
	MOVI	MESS_HSRCONF,A10
	JAUC	AREUSURE

HSSOFT
	CALLR	RES_ALL
	RETP				;PROGRAM TO DO THE JOB!

**************************************************************************
*
*	RES_ALL
*
*	RESET ALL TIME HIGH SCORE TABLE AND THE
*	HIGH SCORE RESET COUNTER.
*
**************************************************************************
RES_ALL
;	MOVI	ALL_TAB,A8		;ALWAYS CLEAR OUT TODAYS TABLE
;	CALLA	INIT_TB
	jauc	INIT_HSR		;RE-SET THE HIGH SCORE RESET COUNTER

DO_FACSET
	 MOVI	 MESS_FACSET,A8
	 MOVK	 1,A0
	 JRUC	 DEF_ADJ_PART

**************************************************************************
*									 *
*	   DO_DEF_ADJ	   THIS IS CALLED FROM UTILITY MENU TO		 *
*			   DO THE DEFAULT ADJUSTMENTS.			 *
*									 *
*	   DEF_ADJ_PART    THIS IS CALLED OUT OF THE FULL		 *
*			   FACTORY SETTING TO HANDLE THE		 *
*			   ADJUSTMENT PART.				 *
*									 *
*			   A8 MUST HAVE THE MESSAGE FOR "ARE YOU SURE"	 *
*			   A0 .NE. 0 FOR FULL FACTORY SETTINGS (ON	 *
*				     SUCCESS OF ADJUSTMENT PART 	 *
*									 *
**************************************************************************
DO_DEF_ADJ
	MOVI	MESS_DEF_ADJ,A8
	CLR	A0

DEF_ADJ_PART
	MOVE	A0,@FAC_FLAG,W		;INDICATE THIS IS ADJUSTMENTS ONLY
	MOVI	DEFADJSOFT,A9
	MOVI	NULL_ST,A10		;DON'T PRINT ANYTHING....ROUTINE WILL.
	JSRP	AREUSURE
	RETP

DEFADJSOFT
*
*	NOW SMASH THE CHECKSUM
*
	CALLA	FORM_ADC	       ;FORM THE CKSUM
	MOVE	A1,A0		       ;PUT IN CMOS WRITING REGGIE
	MOVI	ADJ_CKSUM,A7
	INC	A0		       ;THIS SMASHES ADJUSTMENTS
	CALLA	WC_WORD 	       ;AND STORE IT
*
*	NOW MAKE SURE ITS SMASHED
*
	CALLA	CMOS_VAL
	JRZ	AD_FAIL 	       ;WE CAN'T DO IT.....PRINT FAILURE.
*
*	NOW SET THE ADJUSTMENTS TO THE FACTORY VALUE.
*
	clr	a0		;Full
	CALLA	FAC_SET
	CALLA	CMOS_VAL	;IS IT OK NOW?
	JRNZ	AD_FAIL 	;NOPE...PRINT FAILURE

	MOVI	MESS_DEFCONF,A8 ;THIS IS SINGLE MESSAGE

	MOVE	@FAC_FLAG,A0,W	;DO WE NEED TO CLEAR THE TABLES?
	JRZ	DAX		;NOPE...POST SINGLE MESSAGE

	CALLA	CLR_SCRN	;CLEAR THE SCREEN FOR OUR MESSAGES.
	CALLR	FAC_STUF	;DO AUDITS AND HIGH SCORE TABLE

	MOVI	MESS_FFSCONF,A8 ;PRINT THE REST OF THE MESSAGES
	JSRP	L_MESS		;THAT DOES IT!

NOTABS
	RETP

*
*	ON A FULL FACTORY SETTING (EITHER REQUESTED OR
*	ADJUSTMENT FAILURE) THIS CLEARS THE AUDITS AND
*	HIGH SCORE TABLE.
*
FAC_STUF
	CALLA	CLR_AUD 	;CLEAR AUDITS TOO
	CALLR	RES_ALL 	;ALL TIME TABLE
	RETS

AD_FAIL
	MOVI	MESS_FACFAIL,A8
	JRUC	DAX

DEF_CAN
	MOVI	MESS_CANCELLED,A8
DAX
	CALLA	CLR_SCRN
	JSRP	SUR_MESS
	RETP
**************************************************************************
*									 *
*	   EXIST_LET							 *
*									 *
*	   IS THE E_INITS PROCESS RUNNING?				 *
*									 *
**************************************************************************
EXIST_LET
	MOVI	OPMES_PID,A0		       ;SETUP FOR THE EXISTP
	MOVI	0FFFFH,A1
	JAUC   EXISTP
**************************************************************************
*									 *
*	   BUILD_ST							 *
*									 *
*	   THIS IS CALLED TO TAKE THE STRING POINTED TO 		 *
*	   BY -A10- AND REMOVE LEADING AND TRAILING BLANKS		 *
*	   AND MOVE THE STRING TO "STRNGRAM".				 *
*									 *
*	   RETURN THE NUMBER OF TRAILING BLANKS IN A2.			 *
*	   RETURN .EQ. IF ALL BLANK!					 *
*									 *
**************************************************************************
BUILD_ST
	MMTM	SP,A0,A1,A3,A4,A5,A10
	CLR	A4		       ;A4 = ZERO UNTIL 1ST NON-BLANK
	MOVI	STRNGRAM-BYTE_SIZE,A5  ;LAST NON-SPACE CHAR
	MOVI	STRNGRAM,A1	     ;DESTINATION POINTER
	MOVI	CMESS_CHARS,A2	     ;CHAR COUNT

BSLOOP
	MOVB	*A10,A3 	     ;FETCH A BYTE
	ANDI	BYTE_MASK,A3	     ;KILL SIGN EXTEND.
	JRNZ	BS1		     ;NOT ZERO
	MOVI	SPACE,A3	     ;REPLACE ZERO WITH SPACE.

BS1
	CMPI	SPACE,A3	     ;IS IT A SPACE?
	JRZ	BS2		     ;IT IS...
*
*	NON-SPACE CHARACTER
*
	OR	A3,A4		     ;INDICATE 1ST NON-BLANK SEEN
	MOVE	A1,A5		     ;INDICATE THIS IS CURRENT TERMINATOR.
	JRUC	BS3

BS2
	MOVE	A4,A4		     ;HAS 1ST SPACE BEEN SEEN?
	JRZ	BS4		     ;NOT YET...DON'T STORE
BS3
	MOVB	A3,*A1		     ;STORE IT IN MEMORY
	ADDK	BYTE_SIZE,A1	     ;PUSH DESTINATION POINTER
BS4
	ADDK	BYTE_SIZE,A10	     ;PUSH SOURCE POINTER
	DSJS	A2,BSLOOP	     ;AND FINISH PARSE
*
*	 A5 NOW POINTS AT LAST NON-BLANK CHARACTER
*
	ADDK	BYTE_SIZE,A5	     ;THIS IS 1 BEYOND
	CLR	A2
	MOVB	A2,*A5		     ;TERMINATE WITH A ZERO.
*
*	FOR OUR RETURN, WE NEED TO COMPUTE THE NUMBER OF
*	TRAILING SPACES IGNORED.
*
	MOVE	A4,A4		     ;ALL BLANK?
	JRNZ	NOT_BLNK
	MOVI	CMESS_CHARS,A2	     ;ALL CHARS ARE TRAILING BLANKS
	JRUC	BL_EX		     ;RETURN THIS

NOT_BLNK
	MOVE	A1,A2		     ;THIS IS LAST CHAR WE WROTE
	SUB	A5,A2		     ;THIS IS NUMBER OF TRAILING SPACES (TIMES 8)
	SRL	3,A2		     ;DIVIDE BY 8 TO GET SPACES
BL_EX
	MOVE	A4,A4		     ;FLAG ZERO FOR ALL BLANK!
	MMFM	SP,A0,A1,A3,A4,A5,A10
	RETS

* A1 = <COLOR><PALETTE>
* A3 = DAG OF AREA [YPOS,XPOS]						
* A4 = [Y,X] SIZE OF AREA						

GO_RED
	MOVI	ROBO_RED,A1
	JAUC	SC_COL

GO_GREEN
	MOVI	ROBO_GREEN,A1
	JAUC	SC_COL

GO_BLUE
	MOVI	ROBO_BLUE,A1
SC_COL
	SLL	16,A1		;[color,palette]
	clr	a3		;[y,x] start
	movi	[256,399],a4	;[Y,X] SIZE OF AREA
	CALLA	FILLAREA	;THIS DOES THE SCREEN
	JAUC	WAIT_BUT	;NOW WAIT FOR ANY BUTTON!

GO_CPUTEST
	JAUC	DIAGCPUTEST

	
GO_CROSS
	CALLA	SCRCLR
	CALLA	CROSS_H
	JAUC	WAIT_BUT	     ;NOW WAIT FOR ANY BUTTON!
;	JSRP	WAIT_BUT
;	CALLA	SCRCLR
;	CALLA	display_init
;	RETP

GO_SWTEST
	CALLA	SCRCLR
	clr	a0
	JSRP	SWITCHTEST
;	CALLA	SCRCLR
;	CALLA	display_init
	RETP

dipsw_test
	CALLA	SCRCLR
	movk	1,a0			;DIP mode
	JSRP	SWITCHTEST
	RETP
	
;GO_ROMTEST
;	JAUC	ROM_CHK

GO_BARS
;	MOVI	8000H,A1
;	CLR	A0
;	CALLA	KILALL
	CALLA	SCRCLR
	MMTM	SP,A12,A13
	CALLA	COL_BARS
	MMFM	SP,A12,A13
	JAUC	WAIT_BUT	     ;NOW WAIT FOR ANY BUTTON!
;	JSRP	WAIT_BUT
;	CALLA	SCRCLR
;	CALLA	display_init
;	CALLA	COLRSTRT
;	RETP

DO_BURN
	MOVI	MESS_BURN,A8	     ;CLEAR COIN SUB-TOTALS...ARE YOU SURE
	MOVI	BURN_IN,A9	     ;ENTRY POINT
	MOVI	MESS_BURN,A10	     ;THIS WILL NEVER BE SEEN!
	JAUC	AREUSURE	     ;ASK EM.

ANY_BUT
	MOVI	ANY_MENU,A8	     ;ANY BUTTON TO CONTINUE
	MOVK	1,A9		     ;CURSOR ON ENTRY 1
	JAUC	B_MENU		     ;DO IT....RETURN WHEN PRESSED.


********************************
* DIAGNOSTIC TESTS
*
* SOUND TEST STUFF

NCHAN		EQU	6	;DECLARE NUMBER OF ALLOWED CHANNELS
MUSICHAN	EQU	3	;THIS CHANNEL IS FOR THE TUNES

RESETBIT	EQU	0FE00H	;Sound board reset bit

GO_STEST

	CALLA	CLR_SCRN

	movi	MEN_SOUNDTEST,a8
	movk	1,a9			;CURSOR ON 1st ENTRY

	JAUC	GEN_MENU	     	;THIS WILL RETURN TO LEVEL ABOVE US!

;	jsrp	B_MENU			;SEE IF THEY WANT PAGE 2.
;	cmpi	1,A8			;DID WE GET 1'ST ENTRY?
;	RETP

SNDTST
	MOVI	SNDMES,A8	;MESSAGE POINTER
SNDTLP
	CALLA	SCRCLR
	MOVI	M_STEST,A0	;SOUND TEST MESSAGE
	MOVI	>6080,A1
	CLR	A2
	MOVI	ROBO_WHITE,A3
	CALLA	STRNEW1
	MOVI	>B080,A1	;SCREEN ADDRESS
	MOVE	A8,A0
	CALLA	STRNEW1
	ADDK	8,A0
	MOVB	*A0,A5		;Channel
	ADDK	8,A0
	MOVB	*A0,A3		;Sound #
	sll	32-8,a3		;Kill sign extend
	srl	32-8,a3
	ADDK	8,A0
	CALLA	SNDSND
	MOVE	A0,A8
	MOVE	A13,A13		;AUTO-CYCLE?
	JRNE	SNDSLP		;NO
	CALLA	WDOGDIS
	MOVI	3000000,A13
SNDAUTO	DSJS	A13,SNDAUTO
	JRUC	SNDSLP1
SNDSLP
	SLEEP	120
SNDSLP1	
	MOVB	*A8,A5
	JRNE	SNDTLP
	MOVE	A13,A13		;AUTO CYCLE EXIT
	JREQ	SNDX1
	RETP

SNDX1	RETS

*SOUND TABLE
*MESSAGE,CHANNEL,SOUNDCODE
*
SNDMES	
	.byte	"TUNE 1 (1)",0
	.byte	MUSICHAN,1
	.byte	"NO WAY (E6)",0
	.byte	1,>e6
	.byte	"EXPL1 (30)",0
	.byte	4,>30
	.byte	"TUNE 2 (9)",0
	.byte	MUSICHAN,9
	.byte	"SPIDER BOUNCE (83)",0
	.byte	4,>83
	.byte	"MUSIC OFF (0)",0
	.byte	MUSICHAN,0
	.byte	0		;THE END OF TABLE
	.even
*******************************************************************************
DO_GENTEST
****	CALLA	SNDRESP 		;RESET IN CASE CRASHED!
	CLR	A3
;	CALLA	SEND_CODE_A3
	SLEEPK	4			;LET IT GO A SEC!
        CALLA   CLR_SCRN
        MOVI    M_DIGT,A2
        MOVI    ROBO_GREEN,A3
        JSRP    TOP_BOX			;PRINT TITLE BOX.

        CALLA   SURE_BOX		;PUT A NICE BOX UP!
	
	movi	SOUNDBIT,a0
	move	a0,@SOUND

	.if	TUNIT

	movk	8,a14
	dsj	a14,$			;Slow it down a bit

	.else

	movk	8,a14
	dsj	a14,$			;Slow it down a bit

	movi	0ff00h,a0
	move	a0,@SOUND		;PULL ON THE SOUND INTERRUPT

	movk	8,a14
	dsj	a14,$			;Slow it down a bit
	.endif

	movb	@SOUNDIRQ+B_SIRQ-7,A14	;ARE WE CONNECTED?
	jrnn	SOUND_IRQ_CONNECTED	;BR = YES SIRREE

	MOVI    SIRQ_ERR,A8
	JSRP    L_MESS			;PRINT ERROR

	JSRP    ANY_BUT			;AND TELL EM ANY BUTTON TO CONTINUE
	
	CALLR	BLNK_SURE_BOX
	
        MOVI    SIRQ_ERR2,A8
        JSRP    L_MESS			;REMIND THE GUY OF THE PREVIOUS ERROR
	JRUC	SOUND_DONGER
SOUND_IRQ_CONNECTED
        MOVI    SIRQ_DETECT,A8
        JSRP    L_MESS			;NOTIFY THAT SOUND IRQ WAS CHECKED
SOUND_DONGER

	calla	snd_reset		;RESET THAT PUPPY

        MOVI    DAC_ERR,A8
        JSRP    L_MESS		    ;PRINT ERROR
        JAUC    ANY_BUT		    ;AND TELL EM ANY BUTTON TO CONTINUE


*
*BLANK THE INSIDE OF THE "ARE YOU SURE BOX"
*
BLNK_SURE_BOX
	MOVI	[41H,29H],A3
	MOVI	[0F2H,166H]-[41H,29H],A4
	JAUC	BLNKAREA		;ITS BLANK!


M_DIGT
	.STRING	"GENERAL SOUND TEST",0,0
	.EVEN

SIRQ_DETECT
         MESS_MAC  RD7FONT,SPACING07,200,165,ROBO_GREEN,STRCNRM,0
	.STRING	"SOUND IRQ DETECT FUNCTIONAL.",0,0
	.EVEN

*
*MESSAGE FOR SOUND BOARD IRQ NOT WORKING
*
SIRQ_ERR
	MESS_MAC RD15FONT,SPACING07,200,95,COLOR_LF,STRCNRM,0
	.STRING	"** WARNING! **",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,200,120,COLOR_YELLOW,STRCNRM,0
	.STRING	"UNABLE TO DETECT SOUND BOARD IRQ.",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,200,135,COLOR_YELLOW,STRCNRM,0
	.STRING	"THIS MAY RESULT IN ERRANT SOUNDS.",0,0
	.EVEN

SIRQ_ERR2
         MESS_MAC  RD7FONT,SPACING07,200,165,ROBO_RED,STRCNRM,0
	.STRING	"ERROR - SOUND IRQ NOT DETECTED.",0,0
	.EVEN

DAC_LX	EQU	125
DAC_LX2	EQU     DAC_LX+52
DAC_ERR
	MESS_MAC RD7FONT,SPACING07,200,80,COLOR_LF,STRCNRM,0
	.STRING	"LISTEN FOR TONES:",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,DAC_LX,105,COLOR_YELLOW,STRLNRM,0
	.STRING	"0 TONES - CHECK HARDWARE",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,DAC_LX,117,COLOR_YELLOW,STRLNRM,0
	.STRING	"1 TONE",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,DAC_LX2,117,COLOR_YELLOW,STRLNRM,0
	.STRING	"- SOUND BOARD OK",0,1
	.EVEN
	MESS_MAC RD7FONT,SPACING07,DAC_LX,129,COLOR_YELLOW,STRLNRM,0
	.STRING	"2 TONES - RAM ERROR U2",0,1
	.EVEN
         MESS_MAC  RD7FONT,SPACING07,DAC_LX,141,COLOR_YELLOW,STRLNRM,0
	.STRING	"3 TONES - ROM ERROR U3",0,0
	.EVEN

**************************************************************************
DO_PLAYSOUNDS

	MOVI	SND_INST,A8
	JSRP	L_MESS				;PUT INSTRUCTION OUT.

	movi	[177,200-105],a4	;upper left
	movi	[238+16,200+104-1],a5	;bottom right
	MOVI	COLOR_WHITE,a9
	CALLR	STD_BORD

	CLR	A10
	movi	COLOR_LF,a0
	move	a10,a1
	callr	plot_sound
	move	a10,a3
	CALLR	MAKE_SOUND
#loop
	SLEEPK	1
;RJR
	calla	fudge_switches2
	move	@fswitches_down,a0,L
	andi	START_BITS,a0
	jrnz	#exit

	move	@fswitches_down,a0,L
	andi	ACTION_BITS,a0
	jrz	#no_play_sound
	move	a10,a3
	CALLR	MAKE_SOUND
	jruc	#loop
#no_play_sound

	move	a10,a2
	move	@fswitches_cur,a0,L
	andi	UP_BITS,a0
	jrz	#no_down
	inc	a2
#no_down
	move	@fswitches_cur,a0,L
	andi	DOWN_BITS,a0
	jrz	#no_up
	dec	a2
#no_up
	cmp	a2,a10
	jreq	#loop		;no change

	CALLA	QSNDRST
	push	a2
	movi	ROBO_BLACK,a0
	move	a10,a1
	callr	plot_sound
	pull	a10
	andi	7,a10
	SLEEPK	6
	movi	COLOR_LF,a0
	move	a10,a1
	callr	plot_sound
	move	a10,a3
	CALLR	MAKE_SOUND

	movi	30,a11
#wait_release
;RJR
	calla	fudge_switches2
	move	@fswitches_cur,a0,L
	andi	UP_BITS|DOWN_BITS,a0
	jrz	#loop
	SLEEPK	1
	dsj	a11,#wait_release
	jruc	#loop

#exit
	CALLA	QSNDRST
	RETP

**************************************************************************
* colour in a0
* sound number 0-3 passed in a1
plot_sound
	PUSH	a10
	sll	5,a1			;x 32 bits
	addi	sounds_tab,a1		;base addr
	move	*a1,a1,L
	PUSH	a0,a1
	movi	SND_SETUP,a8
	calla	LM_SETUP		;GET CONFIRMATION DATA READY.
	PULL	a6,a8			;colour,string
	JSRP	LM_FINIS		;plot strings
	PULL	a10
	rets
*
*MAKE_SOUND - MAKE A SOUND TEST SOUND
*A3 = INDEX INTO TEST SOUND LIST
*NOTE: TRASHES A3
MAKE_SOUND
	SLL	4,A3
	ADDI	TEST_SOUND_TAB,A3
	MOVE	*A3,A3,W
	JAUC	SNDSND

**************************************************************************
*									 *
*	   MONITOR PATTERNS						 *
*									 *
**************************************************************************
GO_PATTERNS
	MOVI	MEN_PATTERNS,A8      ;PUT UP THE MENU AND GO!
	JAUC	GEN_MENU	     ;THIS WILL RETURN TO LEVEL ABOVE US!

*******************************************************************************
*******************************************************************************
*******************************************************************************
*
*	       A   U   D   I   T	D   I	S   P	L   A	Y   S
*
*******************************************************************************
*******************************************************************************
*******************************************************************************
**************************************************************************
*									 *
*	   AUDIT TABLE STRUCTURE					 *
*									 *
**************************************************************************

	STRUCT	0
	APTR	AUD_MESS	;*Text
	APTR	AUD_ROUTINE	;*Code to call or 0
	WORD	AUD_NUMBER	;Audit number to show or 0
	WORD	AUD_COLOR	;Color for this line
	LABEL	AUD_T_SIZE	;Size of structure

AMAC	.macro	mess,rout,audit,color
	.long	:mess:,:rout:
	.word	:audit:,:color:
	.endm

TXTLINE	.macro	s
	.byte	":s:",0
	.even
	.endm


AUD_LM		EQU	TIT_ULX		;SQUARE OFF AUDITS W/ HEADER.
AUD_RM		EQU	TIT_LRX
AUD_Y_STRT	EQU	54
AUD_DY		EQU	14

CP2_Y		EQU	156		;PART 2 OF COIN AUDIT PAGE.

********************************
* (doesn't display dollar values)

COIN_OCTO_AUDS
	.word	AUD_Y_STRT+50,12+8		;Y start, Y spacing
	.word	AUD_LM+30,AUD_RM-30		;LFT/RGT margin X
	AMAC	M_LCOIN2,0,AUDLCOIN,ROBO_YELLOW
	AMAC	M_RCOIN2,0,AUDRCOIN,ROBO_YELLOW
	AMAC	M_CCOIN2,0,AUDCCOIN,ROBO_YELLOW
;;	AMAC	amst_s,0,AUDBEGIN,ROBO_GREEN	;On parachute
;;	AMAC	M_START,STARTS,0,ROBO_GREEN
;;	AMAC	M_PAIDC,0,AUDPAIDC,ROBO_WHITE
;;	AMAC	M_SERV,0,AUDSERV,>1212
;;	AMAC	M_PLAYS,DOPLAYS,0,ROBO_YELLOW
	.long	0



********************************
* TOP HALF OF COIN AUDIT PAGE 1 TABLE

COIN_AUDS
	.word	AUD_Y_STRT,12+5			;Y start, Y spacing
	.word	AUD_LM,AUD_RM			;LFT/RGT margin X
	AMAC	M_LCOIN,0,AUDLCOIN,ROBO_YELLOW
	AMAC	M_RCOIN,0,AUDRCOIN,ROBO_YELLOW
	AMAC	M_CCOIN,0,AUDCCOIN,ROBO_YELLOW
	AMAC	amst_s,0,AUDBEGIN,ROBO_GREEN	;On parachute
	AMAC	M_START,STARTS,0,ROBO_GREEN
;	AMAC	M_CONTO,0,AUD_CONTOFFERED,ROBO_GREEN
;	AMAC	M_CONT,0,AUD_CONTTAKEN,ROBO_GREEN
	.long	0

COIN1_AUDS
	.word	AUD_Y_STRT+14*6+2,AUD_DY
	.word	AUD_LM,AUD_RM
	AMAC	M_PAIDC,0,AUDPAIDC,ROBO_WHITE
	.long	0

COIN2_AUDS
	.word	CP2_Y+AUD_DY+5,AUD_DY		;Y start, Y spacing
	.word	AUD_LM,AUD_RM			;LFT/RGT margin X
	AMAC	M_SERV,0,AUDSERV,>1212
	AMAC	M_PLAYS,DOPLAYS,0,ROBO_YELLOW
;	AMAC	M_HSLEFT,DOHSLEFT,0,ROBO_YELLOW
	.long	0

amst_s	TXTLINE	"ATTRACT MODE STARTS"
M_START TXTLINE	"MID GAME STARTS"
M_CONTO	TXTLINE	"CONTINUES OFFERED"
M_CONT	TXTLINE	"CONTINUES TAKEN"
M_EXTRA	TXTLINE	"EXTRA MEN COLLECTED/EARNED"
M_P1MIN	TXTLINE	"HOURS OF SINGLE PLAY"
M_P2MIN	TXTLINE	"HOURS OF DUAL PLAY"
M_HOURS	TXTLINE	"TOTAL HOURS OF PLAY"
M_AVGT	.byte	"AVG. ",ASCII_DQ,"PLAYER",ASCII_DQ," GAME TIME (MIN.)",0
	.even


;*	  BOTTOM HALF OF COIN AUDIT PAGE 1 TABLE
;COIN_A2	.WORD CP2_Y 		;Y START
;	.WORD AUD_DY		;Y BETWEEN ENTRIES
;	.WORD AUD_LM		;LEFT MARGIN X
;	.WORD AUD_RM		;RIGHT MARGIN X
;	AMAC	M_START,STARTS,0,ROBO_YELLOW
;	AMAC	M_CONT,CONTINS,0,ROBO_YELLOW
;	AMAC	M_PLAYS,DOPLAYS,0,ROBO_YELLOW
;	AMAC	M_HSLEFT,DOHSLEFT,0,ROBO_YELLOW
;	.LONG 0

**************************************************************************
*									 *
*	   COIN_D1							 *
*									 *
*	   THIS IS TOP HALF OF DETAILED COIN AUDIT PAGE 		 *
*	   ITS THE SAME AS THE OTHER COIN PAGE WITH THE Y POSITIONING	 *
*	   A LITTLE DIFFERENT						 *
*									 *
**************************************************************************
;COIN_D1
;	  .WORD   39H			;Y START
;	  .WORD   11H			;Y BETWEEN ENTRIES
;	  .WORD   AUD_LM		;LEFT MARGIN X
;	  .WORD   AUD_RM		;RIGHT MARGIN X
;	  AMAC	  M_LCOIN,0,AUDLCOIN,ROBO_YELLOW
;	  AMAC	  M_CCOIN,0,AUDCCOIN,ROBO_YELLOW
;	  AMAC	  M_RCOIN,0,AUDRCOIN,ROBO_YELLOW
;	  .LONG   0
*
*	 DOOR CLOSED AUDITS.
*
;COIN_D2
;	  .WORD   090H			;Y START
;	  .WORD   11H			;Y BETWEEN ENTRIES
;	  .WORD   AUD_LM		;LEFT MARGIN X
;	  .WORD   AUD_RM		;RIGHT MARGIN X
;	  AMAC	  M_LCOIN,0,AUDLCDC,ROBO_YELLOW
;	  AMAC	  M_CCOIN,0,AUDCCDC,ROBO_YELLOW
;	  AMAC	  M_RCOIN,0,AUDRCDC,ROBO_YELLOW
;	  .LONG   0

**************************************************************************
*									 *
*	   GAME PLAY AUDIT SCREEN					 *
*									 *
**************************************************************************

	.asg	50,LM
	.asg	400-50,RM

GAME_AUDS
	.word	55-10,11,LM,RM ;Y start, Y spacing, L margin, R margin

	AMAC	str_totuptime,	prn_uptime,0,	ROBO_WHITE
	AMAC	str_totpltime,	prn_pltime,0,	ROBO_WHITE
	AMAC	str_totplys,	0,AUD_TOTPLYS,	ROBO_GREEN
	AMAC	str_totstarts,	0,AUD_TOTSTARTS,ROBO_GREEN
	AMAC	str_avginit,	prn_initpct,0,	ROBO_ORANGE
	AMAC	str_avgfulg,	prn_fullgmpct,0,ROBO_YELLOW
	AMAC	str_tot1plyt,	prn_1plpct,0,	ROBO_CYAN
	AMAC	str_tot2plyt,	prn_2plpct,0,	ROBO_CYAN
	AMAC	str_tot3plyt,	prn_3plpct,0,	ROBO_CYAN
	AMAC	str_tot4plyt,	prn_4plpct,0,	ROBO_CYAN
	AMAC	str_ply21st,	prn_1stqtrpct,0,ROBO_GREY
	AMAC	str_ply22nd,	prn_1sthlfpct,0,ROBO_GREY
	AMAC	str_ply23rd,	prn_3rdqtrpct,0,ROBO_GREY
	AMAC	str_ply2comp,	prn_comppct,0,	ROBO_GREY
	AMAC	str_2ovrtime,	prn_ovtmpct,0,	ROBO_BLUE
	AMAC	str_snderr,	0,AUD_SNDERR,	ROBO_RED
	.long	0


GAME_AUDS1a
	.word	55-10,11,LM,RM ;Y start, Y spacing, L margin, R margin

;;;	AMAC	str_snderr1,	0,AUD_SNDERR1,	ROBO_RED
	AMAC	str_lockups,	0,AUDLOCK,	ROBO_RED
	AMAC	str_lockups2,	0,AUD_LOCKUP,	ROBO_RED
;	AMAC	str_cliplock,	0,AUD_CLIPLOCK,	ROBO_RED
	AMAC	str_avgscr,	prn_avgscr,0,	ROBO_GREEN
	AMAC	str_avgplyscr,	prn_avghumscr,0,ROBO_GREEN
	AMAC	str_avgcpuscr,	prn_avgcpuscr,0,ROBO_GREEN
	AMAC	str_avgwin,	prn_avgwin,0,	ROBO_CYAN
	AMAC	str_avglos,	prn_avglos,0,	ROBO_CYAN
	AMAC	str_cpuvic,	prn_cpuwins,0,	ROBO_PINK
	AMAC	str_cpuwin,	0,AUD_CPUWINMARG,ROBO_ORANGE
	AMAC	str_cpulos,	0,AUD_CPULOSMARG,ROBO_ORANGE
	AMAC	str_scrdiff,	prn_avgdropdif,0,ROBO_YELLOW
;	AMAC	str_drpcpu,	prn_dropcpu,0,	ROBO_GREY
;	AMAC	str_drphum,	prn_drophum,0,	ROBO_GREY
	AMAC	str_humans,	prn_humans,0,	ROBO_GREY
	AMAC	str_leftwins,	prn_leftwins,0,	ROBO_GREY
	AMAC	str_numhotstrks,prn_numhot,0,	ROBO_BLUE
	AMAC	str_hotstrkpts,	prn_hotpts,0,	ROBO_BLUE

	.long	0



str_snderr	TXTLINE	"SND ERR (DAV & READ BACK)"
;str_snderr1	TXTLINE	"SND ERR #1 (IRQ)"
;str_snderr2	TXTLINE	"SND ERR #2 (DATA AVAILABLE)"
;str_snderr3	TXTLINE	"SND ERR #3 (READ BACK)"

str_lockups	TXTLINE	"DOGS"
str_lockups2	TXTLINE	"PROCESS KO"
;str_cliplock	TXTLINE	"CLIP KO"
str_totuptime	TXTLINE	"TOTAL GAME UPTIME (HRS:MINS)"
str_totpltime	TXTLINE	"TOTAL GAME PLAY TIME (HRS:MINS)"
str_totplys	TXTLINE	"GAMES STARTED"
str_totstarts	TXTLINE	"INDIVIDUAL PLAYER STARTS"
str_avginit	TXTLINE	"INITIALS ENTERED"
str_avgfulg	TXTLINE	"FULL GAMES PURCHASED"
str_tot1plyt	TXTLINE	"1 PLAYER PLAY"
str_tot2plyt	TXTLINE	"2 PLAYER PLAY"
str_tot3plyt	TXTLINE	"3 PLAYER PLAY"
str_tot4plyt	TXTLINE	"4 PLAYER PLAY"
str_ply21st	TXTLINE	"FINISHED 1ST QUARTER"
str_ply22nd	TXTLINE	"FINISHED 2ND QUARTER"
str_ply23rd	TXTLINE	"FINISHED 3RD QUARTER"
str_ply2comp	TXTLINE	"FINISHED 4TH QUARTER"
str_2ovrtime	TXTLINE	"GONE TO OVERTIME"
str_avgscr	TXTLINE	"AVERAGE SCORE"
str_avgplyscr	TXTLINE	"AVERAGE HUMAN SCORE"
str_avgcpuscr	TXTLINE	"AVERAGE CPU SCORE"
str_avgwin	TXTLINE	"AVERAGE WINNING SCORE"
str_avglos	TXTLINE	"AVERAGE LOSING SCORE"
str_cpuvic	TXTLINE	"CPU VICTORIES"
str_cpuwin	TXTLINE	"GREATEST CPU VICTORY MARGIN"
str_cpulos	TXTLINE	"GREATEST CPU LOSS MARGIN"
str_scrdiff	TXTLINE	"SCORE DIFFERENTIAL AT DROPOUT"
;str_drpcpu	TXTLINE	"DROPOUTS VS CPU"
;str_drphum	TXTLINE	"DROPOUTS VS HUMAN"
str_humans	TXTLINE	"HUMAN VS. HUMAN - GAMES PLAYED"
str_leftwins	TXTLINE	"LSW"
str_numhotstrks	TXTLINE	"TOTAL HOT STREAKS STARTED"
str_hotstrkpts	TXTLINE	"AVERAGE PTS. SCORED ON HOT STREAK"
str_pct		TXTLINE	"%"
	.even

	.asg	10,COL1
	.asg	COL1+200,COL2
	.asg	160,WIDTH


GAME_AUD2a
	.word	60-4,11,COL1,COL1+WIDTH ;Y start, Y spacing, L margin, R margin

	AMAC	str_atl,0,AUD_ATL,ROBO_GREEN
	AMAC	str_bos,0,AUD_BOS,ROBO_WHITE
	AMAC	str_cha,0,AUD_CHA,ROBO_BLUE
	AMAC	str_chi,0,AUD_CHI,ROBO_YELLOW
	AMAC	str_cle,0,AUD_CLE,ROBO_CYAN
	AMAC	str_dal,0,AUD_DAL,ROBO_PURPLE
	AMAC	str_den,0,AUD_DEN,ROBO_GREEN
	AMAC	str_det,0,AUD_DET,ROBO_WHITE
	AMAC	str_gld,0,AUD_GLD,ROBO_BLUE
	AMAC	str_hou,0,AUD_HOU,ROBO_YELLOW
	AMAC	str_ind,0,AUD_IND,ROBO_CYAN
	AMAC	str_lac,0,AUD_LAC,ROBO_PURPLE
	AMAC	str_lal,0,AUD_LAL,ROBO_GREEN
	AMAC	str_mi, 0,AUD_MI, ROBO_WHITE
	.long	0

GAME_AUD2b
	.word	60-4,11,COL2,COL2+WIDTH ;Y start, Y spacing, L margin, R margin

	AMAC	str_mil,0,AUD_MIL,ROBO_GREEN
	AMAC	str_min,0,AUD_MIN,ROBO_WHITE
	AMAC	str_nj, 0,AUD_NJ, ROBO_BLUE
	AMAC	str_jy, 0,AUD_JY, ROBO_YELLOW
	AMAC	str_orl,0,AUD_ORL,ROBO_CYAN
	AMAC	str_phi,0,AUD_PHI,ROBO_PURPLE
	AMAC	str_phx,0,AUD_PHX,ROBO_GREEN
	AMAC	str_por,0,AUD_POR,ROBO_WHITE
	AMAC	str_sac,0,AUD_SAC,ROBO_BLUE
	AMAC	str_san,0,AUD_SAN,ROBO_YELLOW
	AMAC	str_sea,0,AUD_SEA,ROBO_CYAN
	AMAC	str_uta,0,AUD_UTA,ROBO_PURPLE
	AMAC	str_was,0,AUD_WAS,ROBO_GREEN
	.long	0


 .if 0
ROBO_GREY       EQU     0101H	;[0E0H-223,0E0H-223]
ROBO_WHITE      EQU     0202H	;[0E1H-223,0E1H-223]
ROBO_RED        EQU     0303H	;[0E2H-223,0E2H-223]
ROBO_ORANGE     EQU     0404H	;[0E3H-223,0E3H-223]
ROBO_YELLOW     EQU     0505H	;[0E4H-223,0E4H-223]
ROBO_GREEN      EQU     0606H	;[0E5H-223,0E5H-223]
ROBO_BLUE       EQU     0707H	;[0E6H-223,0E6H-223]
ROBO_LF         EQU     03E3EH 
ROBO_CYAN       EQU     0E0EH	;[0EDH-223,0EDH-223]
ROBO_DECAY      EQU     03F3FH
ROBO_RGOLD      EQU     0A0AH	;[0E9H-223,0E9H-223]
ROBO_LASER      EQU     03E3EH
ROBO_LASER2	EQU	03F3FH
ROBO_BLUWH      EQU     0C0CH	;[0EBH-223,0EBH-223]
ROBO_PINK       EQU     0303H	;[0E2H-223,0E2H-223]
ROBO_SKY        EQU     0D0DH	;[0ECH-223,0ECH-223]  ;LAST COLOR IN ROBO IS "SKY" COLOR
ROBO_PURPLE     EQU     ROBO_SKY     ;PURPLE FOR TEST MODE
ROBO_BLACK	EQU	1414H	;BLACK AS COAL
 .endif


str_atl	TXTLINE	"ATLANTA"
str_bos	TXTLINE	"BOSTON"
str_cha	TXTLINE	"CHARLOTTE"
str_chi	TXTLINE	"CHICAGO"
str_cle	TXTLINE	"CLEVELAND"
str_dal	TXTLINE	"DALLAS"
str_den	TXTLINE	"DENVER"
str_det	TXTLINE	"DETROIT"
str_gld	TXTLINE	"GOLDEN STATE"
str_hou	TXTLINE	"HOUSTON"
str_ind	TXTLINE	"INDIANA"
str_lac	TXTLINE	"L.A. CLIPPERS"
str_lal	TXTLINE	"L.A. LAKERS"
str_mi	TXTLINE	"MIAMI"
str_mil	TXTLINE	"MILWAUKEE"
str_min	TXTLINE	"MINNESOTA"
str_nj	TXTLINE	"NEW JERSEY"
str_jy	TXTLINE	"NEW YORK"
str_orl	TXTLINE	"ORLANDO"
str_phi	TXTLINE	"PHILADELPHIA"
str_phx	TXTLINE	"PHOENIX"
str_por	TXTLINE	"PORTLAND"
str_sac	TXTLINE	"SACRAMENTO"
str_san	TXTLINE	"SAN ANTONIO"
str_sea	TXTLINE	"SEATTLE"
str_uta	TXTLINE	"UTAH"
str_was	TXTLINE	"WASHINGTON"
	.even

#*****************************************************************************
* total uptime
prn_uptime
	movi	AUD_UPTIME,a0
	calla	GET_AUD
					;* 5 sec incs / 60 (sec p/min) = /12
	movk	12,a0
	divu	a0,a1			;mins
	jruc	P_TIME


#*****************************************************************************
* actual play time
prn_pltime
	movi	AUD_PLTIME,a0
	calla	GET_AUD
					;* 5 sec incs / 60 (sec p/min) = /12
	movk	12,a0
	divu	a0,a1			;mins
	jruc	P_TIME


#*****************************************************************************
* percentage of players entering initials
prn_initpct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_INITENTRD,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK

#*****************************************************************************
* percentage of players purchasing full game
prn_fullgmpct
	movi	AUD_PRESTARTS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_PURCHASED,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK

#*****************************************************************************
* percentage of 1 player play
prn_1plpct
	movi	AUD_PLTIME,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_1PLAYTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK

#*****************************************************************************
* percentage of 2 player play
prn_2plpct
	movi	AUD_PLTIME,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_2PLAYTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of 3 player play
prn_3plpct
	movi	AUD_PLTIME,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_3PLAYTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of 4 player play
prn_4plpct
	movi	AUD_PLTIME,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_4PLAYTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of games finished 1st quarter
prn_1stqtrpct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_1STQUARTR,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of games finished 1st half
prn_1sthlfpct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_HALFTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of games finished 3rd quarter
prn_3rdqtrpct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_3RDQUARTR,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of games finished 4th quarter
prn_comppct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_COMPLETED,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
* percentage of games gone to overtime
prn_ovtmpct
	movi	AUD_TOTPLYS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_OVERTIME,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
*
prn_avgscr
	movi	AUD_COMPLETED,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_WIN_SCORE,a0
	calla	GET_AUD
	srl	1,a1			;/2
	PUSH	a1
	movi	AUD_LOS_SCORE,a0
	calla	GET_AUD
	srl	1,a1			;/2
	PULL	a3
	add	a1,a3
	move	a3,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK


#*****************************************************************************
*
prn_avgwin
	movi	AUD_COMPLETED,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_WIN_SCORE,a0
	calla	GET_AUD
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK


#*****************************************************************************
*
prn_avglos
	movi	AUD_COMPLETED,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_LOS_SCORE,a0
	calla	GET_AUD
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK


#*****************************************************************************
*
prn_cpuwins
	movi	AUD_COMPLETED,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_CPUWINS,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK


#*****************************************************************************
*
prn_leftwins
	movi	AUD_HUMANVSHUMAN,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_WINSONLEFT,a0
	calla	GET_AUD
	movi	100,a0
	mpyu	a0,a1
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	PERCENT_WORK

#*****************************************************************************
*
prn_humans
	movi	AUD_HUMANVSHUMAN,a0
	calla	GET_AUD
	move	a1,a3
	jruc	NUMBER_WORK

;#*****************************************************************************
;*
;prn_dropcpu
;	movi	AUD_NUMDROPOUT,a0
;	calla	GET_AUD
;	move	a1,a4
;
;	movi	AUD_DROPVSCPU,a0
;	calla	GET_AUD
;	movi	100,a0
;	mpyu	a0,a1
;	move	a1,a2
;	move	a4,a0
;	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
;	move	a2,a3
;	jruc	PERCENT_WORK
;
;
;#*****************************************************************************
;*
;prn_drophum
;	movi	AUD_NUMDROPOUT,a0
;	calla	GET_AUD
;	move	a1,a4
;
;	movi	AUD_DROPVSHUM,a0
;	calla	GET_AUD
;	movi	100,a0
;	mpyu	a0,a1
;	move	a1,a2
;	move	a4,a0
;	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
;	move	a2,a3
;	jruc	PERCENT_WORK


#*****************************************************************************
*
prn_avgcpuscr

	movi	AUD_CPUGAMES,a0		;a cpu team
	calla	GET_AUD
	move	a1,a4

	movi	AUD_CPUSCORES,a0
	calla	GET_AUD
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK


#*****************************************************************************
*
prn_avghumscr

	movi	AUD_HUMGAMES,a0		;a human team
	calla	GET_AUD
	move	a1,a4

	movi	AUD_HUMSCORES,a0
	calla	GET_AUD
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK


#*****************************************************************************
*	average score differential at dropout
prn_avgdropdif

	movi	AUD_NUMDROPOUT,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_DROPDIFF,a0
	calla	GET_AUD
	move	a1,a2
	move	a4,a0
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK

#*****************************************************************************
prn_numhot

	movi	AUD_NUMHOTSTRK,a0
	calla	GET_AUD
	move	a1,a3
	jruc	NUMBER_WORK

#*****************************************************************************
*	average # points scored per hot streak
prn_hotpts

	movi	AUD_HOTSTRKPTS,a0
	calla	GET_AUD
	move	a1,a4

	movi	AUD_NUMHOTSTRK,a0
	calla	GET_AUD
	move	a1,a0
	move	a4,a2
	callr	ROUNDED_A0_INTO_A2	;DIVIDES A0 INTO A2. RESULT IN A2
	move	a2,a3
	jruc	NUMBER_WORK

**************************************************************************
* NUMBER_WORK - Print audit number
* A3=#

PERCENT_WORK
	MOVI	MESS_AUD_NUM,A8 	;SETUP FOR AUDIT NUMBER
	CALLA	LM_SETUP

	MOVE	A3,A8			;NOW WE HAVE BINARY NUMBER
	CALLA	HEXTOASC		;NOW WE POINT TO THE STRING.

	PUSH	a8
	move	a8,a7
	movi	str_pct,a8
	CALLA	STRCAT
	PULL	a8

	PUSH	a0
	move	*a13(AT_RX),a0
	PUSHP	a0
	addi	13,a0
	move	a0,*a13(AT_RX)
	PULL	a0

	move	*a13(AT_PTR),a6,L	;Get *audit
	move	*a6(AUD_COLOR),a6

	JSRP	RIGHT_FINISH

	PULLP	a0
	move	a0,*a13(AT_RX)		;restore right margin
	RETP

#*****************************************************************************

MISC_AUD
	.word	50,18,AUD_LM,AUD_RM		;Y start, Y spacing, LMar, RMar
	AMAC	M_SECBON,0,AUDSURV,ROBO_YELLOW	;WARPS TAKEN
	AMAC	M_HIDB,0,AUDBONE,ROBO_YELLOW	;GAMES NOT FINISHED
	AMAC	M_PLAYS,DOPLAYS,0,ROBO_YELLOW	;PLAYS ON TOP
	AMAC	M_P1MIN,DO_P1MIN,0,ROBO_YELLOW
	AMAC	M_P2MIN,DO_P2MIN,0,ROBO_YELLOW
	AMAC	M_AVGT,DO_AVGT,0,ROBO_YELLOW
	AMAC	M_ELAPSE,DO_ELAPSE,0,ROBO_YELLOW
	AMAC	adiff_s,diff_prt,0,>1212
	.LONG	0

adiff_s	TXTLINE	"GAME DIFFICULTY LEVEL"


	.IF	0
********************************
* Display revision message
* Do coin DIP if enabled
* Check cmos, if bad reset to factory

FACCHECK
	calla	dpageflip_off

	CALLA	CLR_SCRN
	MOVI	DIAGP,A0
	CALLA	pal_getf

	MOVI	AUDSTAT,A0		;CLEAR GAME STATE AUDIT
	CLR	A1
	CALLA	STORE_AUDIT

	MOVI	ROM_NAME,A2
	MOVI	ROBO_LF,A3
	JSRP	TOP_BOX			;PRINT TITLE BOX.

	.if	YUNIT
	move	@SWITCH+30h,a0
	btst	6,a0
	jrnz	fc40			;No DIP coinage?

	movk	1,a0			;Just coinage
	calla	FAC_SET
	movi	dipcoinage_mess,a8
	JSRP	L_MESS
fc40
	.endif

	.if	DEBUG
	SLEEPK	1			;Show it DEBUG
	.else
	SLEEP	120			;Show it
	.endif

	CALLA	CMOS_VAL		;CMOS BOGUS?
	JRZ	FACC0			;NO

	MOVI	MESS_RESET,A8		;ERROR MESSAGE
	JSRP	L_MESS
	SLEEP	60

	CALLR	RES_ALL			;ALL TIME TABLE
	clr	a0			;Full
	CALLA	FAC_SET

	MOVI	MESS_FAC,A8
	CALLA	LM_SETUP		;GET CONFIRMATION DATA READY.
	JSRP	LM_FINIS
	SLEEP	60
	CALLA	CMOS_VAL		;CMOS BOGUS?
	JRZ	FACC00			;NO

	CALLA	SCRCLR
	MOVI	MESS_RESET,A8		;ERROR MESSAGE
	JSRP	L_MESS
FACC00
	SLEEP	240

FACC0	CALLA	SCRCLR
	jauc	amode_start


dipcoinage_mess
	MESS_MAC RD7FONT,SPACING20,200,65,ROBO_WHITE,STRCNRM,0
	.byte	"USING DIPSWITCH COINAGE",0,0
	.even

	.ENDIF

SECRET_NAME
	.byte	"SECRET MIDWAY MENU",0
	.even


********************************
* Octopuss sucessful, show stats

	.ref	show_designteam

HID_P
	clr	a0
	move	a0,@octopus2

	JSRP	show_designteam

	move	@octopus2,a0
	JAZ	DIAG_EX			;NOW GET OUT!

	CALLA	display_init 		;MAKE SURE A13 IS OK BEFORE ANY ACTIONS!
	CALLA	DIGSRT			;RE-INIT THE WORLD!

	MOVI	SECRET_NAME,A2
	MOVI	ROBO_LF,A3
	JSRP	TOP_BOX 		;PRINT TITLE BOX.

*	A4 = UPPER LEFT Y,X					      *
*	A5 = LOWER RIGHT Y,X					      *
*	A6 = NUMBER OF SLICES GOING IN. 			      *

;	MOVI	[4EH,TIT_ULX],A4
;	MOVI	[190H,TIT_LRX],A5
;	MOVK	16,A6
;	CALLA	G_BORDER

;	MOVI	M_TEAM,A8		;PUT UP THE DESIGN TEAM!
;	JSRP	L_MESS
;
;	JSRP	WAIT_BUT

	calla	CLR_SCRN		;Clr screen

	movi	COIN_OCTO_AUDS,a0
	JSRP	PRNT_AUD

	movi	AUD_Y_STRT,a0		;aud Y start
	MOVE	a0,*A13(AT_Y),W   	;set Y COORDINATE
	MOVI	AUDLCOIN,A8		;NOW PRINT MONEY FOR 1ST 3
	JSRP	PRINT_COL2


;	movi	COIN_AUDS,a0		;PUT TABLE UP
;	JSRP	PRNT_AUD
;	movi	COIN1_AUDS,a0		;PUT TABLE UP
;	JSRP	PRNT_AUD
;	movi	AUDLCOIN,a8		;NOW PRINT MONEY FOR 1ST 3
;	JSRP	PRINT_COL
;	movi	COIN2_AUDS,a0		;PUT TABLE UP
;	JSRP	PRNT_AUD

	JSRP	WAIT_BUT


	calla	CLR_SCRN		;Clr screen
	movi	GAME_AUDS,A0		;Show 1st screen
	JSRP	PRNT_AUD
	JSRP	WAIT_BUT

	calla	CLR_SCRN		;Clr screen
	movi	GAME_AUDS1a,A0		;Show 2nd screen
	JSRP	PRNT_AUD
	JSRP	WAIT_BUT

	calla	CLR_SCRN		;Clr screen
	movi	GAME_AUD2a,a0
	JSRP	PRNT_AUD
	movi	GAME_AUD2b,a0
	JSRP	PRNT_AUD
;	MOVI	AUDLCOIN,A8		;Prt money
;	JSRP	PRINT_COL
	JSRP	WAIT_BUT

;	JSRP	DISPDUMP
;	JSRP	WAIT_MUT		;Clrs dump if sticks down

;RJR
	JSRP	show_player_records

	JAUC	DIAG_EX			;NOW GET OUT!


**************************************************************************
* PRNT_AUD - THIS IS CALLED TO PRINT OUT AN AUDIT TABLE

AT_PTR	 EQU	PDATA			;LONG
AT_Y	 EQU	PDATA+LONG_SIZE		;WORD
AT_DY	 EQU	AT_Y+WORD_SIZE		;WORD
AT_LX	 EQU	AT_DY+WORD_SIZE		;WORD LEFT MARGIN X
AT_RX	 EQU	AT_LX+WORD_SIZE		;WORD RIGHT MARGIN X
AT_OBJ	 EQU	AT_RX+WORD_SIZE		;LONG OBJECT POINTER FOR COLLECTION ROUT
AT_MESS  EQU	AT_OBJ+LONG_SIZE	;LONG PRINT_MONEY MESSAGE STASH
	
PRNT_AUD
	MOVE	*A0+,A1			;GET STARTING HEIGHT
	MOVE	A1,*A13(AT_Y)	 	;STORE

	MOVE	*A0+,A1			;GET DY TO USE
	MOVE	A1,*A13(AT_DY)		;STASH IT AWAY

	MOVE	*A0+,A1			;GET LEFT MARGIN
	MOVE	A1,*A13(AT_LX)		;STORE

	MOVE	*A0+,A1			;GET RIGHT MARGIN
	MOVE	A1,*A13(AT_RX)		;STASH IT AWAY

	MOVE	A0,*A13(AT_PTR),L	;SAVE POINTER INTO AREA

PA1	JSRP	aud_prtone

	MOVE	*A13(AT_PTR),A0,L	;GET POINTER
	ADDI	AUD_T_SIZE,A0
	MOVE	A0,*A13(AT_PTR),L	;PUT BACK

	CALLR	ADD_AUDIT_DY

	MOVE	*A0,A1,L		;ARE WE DONE?
	JRNZ	PA1

	RETP

**************************************************************************
*									 *
*	   ADD_AUDIT_DY 						 *
*									 *
*	   THIS IS CALLED TO MOVE THE AUDIT Y (STORE IN 		 *
*	   PROCESS AREA) TO THE NEXT AUDIT BY ADDING THE		 *
*	   CURRENT DY (ALSO STORED IN PROCESS AREA).			 *
*									 *
**************************************************************************
ADD_AUDIT_DY
	MMTM	SP,A1,A2
	MOVE	*A13(AT_Y),A1,W
	MOVE	*A13(AT_DY),A2,W	;GET DELTA Y
	ADD	A2,A1			;MOVE THE Y DOWN
	MOVE	A1,*A13(AT_Y),W
	MMFM	SP,A1,A2
	RETS

BEGIN_AUDIT
	MMTM	SP,A0
	CLR	A0
	MOVE	A0,@BAD_AUD,W		;MONITOR CORRUPTION.
	MMFM	SP,A0
	RETS

********************************
* Print an audit line

 SUBRP	aud_prtone

	CALLR	BEGIN_AUDIT
	MOVE	*A13(AT_PTR),A3,L	;GET POINTER
	MOVE	*A3(AUD_ROUTINE),A4,L
	jrz	apo20			;No code?

	movi	apo50,a7
	MOVE	A7,-*A12,L		;PUSH RET ADDR
	JUMP	A4			;"CALL" THE ROUTINE

apo20	MOVE	*A3(AUD_NUMBER),A0	;FETCH THE AUDIT NUMBER
	CALLA	GET_AUD 		;TURN INTO AUDIT COUNT!
	MOVE	A1,A3			;PROTECT FOR A SECOND.
	JSRP	NUMBER_WORK		;GET THE NUMBER IN A3 UP THERE!

apo50
	movi	MESS_AUD_LINE,a8
	calla	LM_SETUP		;Setup for audit printing

	move	*a13(AT_PTR),a3,L	;Get *audit
	move	*a3(AUD_COLOR),a6
	move	*a3(AUD_MESS),a8,L	;Get *text

	jruc	LEFT_FINISH


********************************
* LEFT_FINISH AND RIGHT_FINISH
*
* THESE ARE CALLED TO PUT AUDIT INFO
* ON THE LEFT OR RIGHT SIDE ONCE A8 POINTS AT
* THE CORRECT DATA TO PRINT

LEFT_FINISH
	CALLR	TURN_RED_IF_NEC
	CALLR	SET_FOR_Y		;SET FOR AUDIT'S Y
	CALLR	SET_LEFT_X		;SET FOR LEFT X
	JSRP	LM_FINIS		;AND TYPE UP THE MESSAGE!
	RETP

RIGHT_FINISH
	CALLR	TURN_RED_IF_NEC 	;CHANGE COLOR IF CORRUPTED.
	CALLR	SET_FOR_Y		;SET FOR AUDIT'S Y
	CALLR	SET_RIGHT_X
	JSRP	LM_FINIS		;FINISH THE JOB!

	MOVE	@BAD_AUD,A0,W	       ;IS IT CORRUPTED?
	JRZ	RFX		       ;NOPE....RETURN

	MOVI	MESS_ERROR,A8
	CALLA	LM_SETUP	       ;SETUP "ERROR"

	CALLR	SET_FOR_Y	       ;SET FOR AUDIT'S Y
	ADDI	40000H,A9	       ;PUSH 4 Y UNITS TO CENTER
	CALLR	SET_RIGHT_X
	JSRP	LM_FINIS	       ;FINISH THE JOB!

RFX	RETP

TURN_RED_IF_NEC
	MMTM	SP,A3
	MOVE	@BAD_AUD,A3	;CHANGE TO RED?
	JRZ	DAA_1		;NOPE...ITS OK!
	MOVI	ROBO_RED,A6    ;CHANGE COLOR TO RED
DAA_1	MMFM	SP,A3
	RETS
			
SET_FOR_Y
	MMTM	SP,A3
	MOVE	*A13(AT_Y),A3,W   ;GET Y COORDINATE
	SLL	16,A3		  ;PUT IT IN POSITION
	MOVY	A3,A9		  ;PUT IT IN PLACE
	MMFM	SP,A3
	RETS

SET_LEFT_X
	MMTM	SP,A3
	MOVE	*A13(AT_LX),A3,W
	MOVX	A3,A9		  ;PUT THE X IN PLACE
	MMFM	SP,A3
	RETS

SET_RIGHT_X
	MMTM	SP,A3
	MOVE	*A13(AT_RX),A3,W
	MOVX	A3,A9		  ;PUT THE X IN PLACE
	MMFM	SP,A3
	RETS

**************************************************************************
* NUMBER_WORK - Print audit number
* A3=#

NUMBER_WORK
	MOVI	MESS_AUD_NUM,A8 	;SETUP FOR AUDIT NUMBER
	CALLA	LM_SETUP

	MOVE	A3,A8			;NOW WE HAVE BINARY NUMBER
	CALLA	HEXTOASC		;NOW WE POINT TO THE STRING.
	move	*a13(AT_PTR),a6,L	;Get *audit
	move	*a6(AUD_COLOR),a6
	jruc	RIGHT_FINISH

**************************************************************************
*									 *
*	   GET_STARTS							 *
*									 *
*	   TOTAL GAME STARTS IN A2.					 *
*									 *
**************************************************************************
GET_STARTS
	MMTM	SP,A0,A1
	MOVK	AUD1STRT,A0
	CALLA	GET_AUD
	MOVE	A1,A2

	MOVK	AUD2STRT,A0
	CALLA	GET_AUD
	ADD	A1,A2
	MMFM	SP,A0,A1
	RETS

**************************************************************************
*									 *
*	   GET_CONTS							 *
*									 *
*	   TOTAL GAME CONTINUES IN A2.					 *
*									 *
**************************************************************************
GET_CONTS
	MMTM	SP,A0,A1
	MOVK	AUD1CONT,A0
	CALLA	GET_AUD
	MOVE	A1,A2

	MOVK	AUD2CONT,A0
	CALLA	GET_AUD
	ADD	A1,A2
	MMFM	SP,A0,A1
	RETS


**************************************************************************
* Get total plays (Beginning+starts+continues)
* Rets: A2=#

GET_PLAYS
	PUSH	a0
	movk	AUDBEGIN,a0
	calla	GET_AUD
	move	a1,a0
	callr	GET_STARTS	;Actually middle starts
	add	a2,a0
	callr	GET_CONTS
	add	a0,a2
	PULL	a0
	rets

**************************************************************************
*									 *
*	   PRINT_MONEY							 *
*									 *
*	   THIS IS CALLED TO PRINT OUT THE "MONEY" ON THE MONEY 	 *
*	   LINE OF THE AUDIT TABLE.					 *
*									 *
*	   AUDIT X AND Y IS SET FOR THE LINE TO DISPLAY IT ON.		 *
*									 *
*	   A8 HAS THE 1ST OF 3 AUDITS TO USE FOR THE CALCULATION	 *
*	   A9 HAS THE MESSAGE TO LEFT JUSTIFY ON THE CURRENT LINE	 *
*									 *
**************************************************************************
PRINT_COL
	MOVI	T_MONEY,A9	     ;THIS ENTRYPOINT IS FOR COLLECTION MESSAGE
	
PRINT_MONEY
	MOVE	A9,*A13(AT_MESS),L   ;HOLD MESSAGE FOR WHEN WE NEED IT!
	MOVI	ADJCDIV,A0	     ;IF DIVISOR IS ZERO..THEN ITS OFF!
	CALLA	GET_ADJ
	JRZ	NO_MONEY	     ;THAT'S ALL FOLKS!

	CALLR	BEGIN_AUDIT	     ;KEEP TRACK OF SANITY OF CALC.
*
*	ROUTINE IN A2 FORMS STRING BASED ON 3 AUDITS STARTING
*	WITH THE NUMBER IN A8.
*
	CALLR	STR_OBJ 	     ;GET AN OBJECT FOR STRINGING
	JRC	NO_MONEY	     ;COULDN'T GET AN OBJECT!

	CALLR	SUM_COINS	     ;ADD UP THE COIN PARTS IN A2

*
*	WE'RE DOING A PREFIX STRING...NO PREFIX IF ITS BEEN TAMPERED
*
	CALLR	SIXP		     ;HAVE THE 6 BEEN TAMPERED
	JRZ	NO_PREFIX
	CALLR	GET_CSPT	     ;A6 POINTS AT CSECECT DATA.
	MOVE	*A6(CS_LMES),A8,L    ;LEFT STRING FOR MONEY TOTAL
	CALLA	STRCAT		     ;SHOVE THE STRING IN!

NO_PREFIX
	MOVK	1,A0		     ;DIVIDE COINS BY 1 IF ITS BEEN TAMPERED WITH
	CALLR	SIXP
	JRZ	DIV_BY_1	     ;TAMPERED WITH...DIVIDE BY 1 FOR "COINS"

	MOVI	ADJCDIV,A0	     ;GET THE COIN PARTS PLEASE
	CALLA	GET_ADJ
*
*	GET QUOTIENT IN A2
*	REMAINDER IN A3
*
DIV_BY_1
	MOVE	A2,A3		     ;SETUP <A2><A3> AS DIVIDEND
	CLR	A2
	DIVU	A0,A2		     ;DIVIDE UNITS/DIVISOR

	MOVE	A2,A8		     ;WE NEED TO PUT QUOTIENT IN STRING
	CALLA	HEXTOASC	     ;THIS FORMS STRING FOR QUOTIENT

	CALLA	STRCAT		     ;ADD QUOTIENT TO PRINTOUT

	CMPI	1,A0		     ;IS DIVISOR ONE??????
	JRZ	NOFRAC		     ;YEP.......NO DECIMAL!
*
*	WE HAVE A DIVISOR.....WE NEED TO DISPLAY CENTS.
*
	MOVI	ME_DECIMAL,A8	     ;ADD DECIMAL POINT
	CALLA	STRCAT		     ;ITS THERE!
*
*	REMAINDER IS IN A3....TURN IT TO 100THS.
*
	MOVI	100,A2
	MPYU	A2,A3		     ;REMAINDER TIMES 100
	MOVE	A3,A2		     ;DIVIDEND IN A2

	CALLR	ROUNDED_A0_INTO_A2
	CALLR	A2_100TH	     ;CAT THE 100THS IN A2 TO THE A7 STRING.

NOFRAC
	MOVI	COINS_TRAIL,A8		 ;ASSUME IT WILL BE "COINS"
	CALLR	SIXP		     ;TAMPERED?
	JRZ	COIN_SUF	     ;YEP....USE " COINS"
	MOVE	*A6(CS_RMES),A8,L    ;FINISH IT OFF WITH RIGHT STRING

COIN_SUF
	CALLA	STRCAT		     ;SHOVE THE STRING IN!
	MOVI	M_MONEY,A8		  ;MESSAGE FOR THIS LINE PASSED IN A9
	CALLA	LM_SETUP

	MOVE	@TMPOBJ,A8,L	     ;POINTER TO MONEY STRING
	JSRP	RIGHT_FINISH		;PUT ON RIGHT MARGIN

	CALLR	STR_FREE

	MOVE	*A13(AT_MESS),A8,L	;SETUP PASSED MESSAGE
	CALLA	LM_SETUP
	JSRP	LEFT_FINISH		;PUT UP PASSED MESSAGE.
NO_MONEY
	RETP

**************************************************************************
* prints up collection minus $$$
*

PRINT_COL2
	MOVI	T_MONEY2,A9	     ;THIS ENTRYPOINT IS FOR COLLECTION MESSAGE
	
	MOVE	A9,*A13(AT_MESS),L   ;HOLD MESSAGE FOR WHEN WE NEED IT!
	MOVI	ADJCDIV,A0	     ;IF DIVISOR IS ZERO..THEN ITS OFF!
	CALLA	GET_ADJ
	JRZ	NO_MONEY2	     ;THAT'S ALL FOLKS!

	CALLR	BEGIN_AUDIT	     ;KEEP TRACK OF SANITY OF CALC.
*
*	ROUTINE IN A2 FORMS STRING BASED ON 3 AUDITS STARTING
*	WITH THE NUMBER IN A8.
*
	CALLR	STR_OBJ 	     ;GET AN OBJECT FOR STRINGING
	JRC	NO_MONEY2	     ;COULDN'T GET AN OBJECT!

	CALLR	SUM_COINS	     ;ADD UP THE COIN PARTS IN A2

*
*	WE'RE DOING A PREFIX STRING...NO PREFIX IF ITS BEEN TAMPERED
*
;;	CALLR	SIXP		     ;HAVE THE 6 BEEN TAMPERED
;;	JRZ	NO_PREFIX2
;;	CALLR	GET_CSPT	     ;A6 POINTS AT CSECECT DATA.
;;	MOVE	*A6(CS_LMES),A8,L    ;LEFT STRING FOR MONEY TOTAL
	movi	M_VERINF,a8
	CALLA	STRCAT		     ;SHOVE THE STRING IN!

NO_PREFIX2
	MOVK	1,A0		     ;DIVIDE COINS BY 1 IF ITS BEEN TAMPERED WITH
	CALLR	SIXP
	JRZ	DIV_BY_12	     ;TAMPERED WITH...DIVIDE BY 1 FOR "COINS"

	MOVI	ADJCDIV,A0	     ;GET THE COIN PARTS PLEASE
	CALLA	GET_ADJ
*
*	GET QUOTIENT IN A2
*	REMAINDER IN A3
*
DIV_BY_12
	MOVE	A2,A3		     ;SETUP <A2><A3> AS DIVIDEND
	CLR	A2
	DIVU	A0,A2		     ;DIVIDE UNITS/DIVISOR

	MOVE	A2,A8		     ;WE NEED TO PUT QUOTIENT IN STRING
	CALLA	HEXTOASC	     ;THIS FORMS STRING FOR QUOTIENT

	CALLA	STRCAT		     ;ADD QUOTIENT TO PRINTOUT

	CMPI	1,A0		     ;IS DIVISOR ONE??????
	JRZ	NOFRAC2		     ;YEP.......NO DECIMAL!
*
*	WE HAVE A DIVISOR.....WE NEED TO DISPLAY CENTS.
*
;;	MOVI	ME_DECIMAL,A8	     ;ADD DECIMAL POINT
	MOVI	ME_DASH,A8	     ;ADD DASH
	CALLA	STRCAT		     ;ITS THERE!
*
*	REMAINDER IS IN A3....TURN IT TO 100THS.
*
	MOVI	100,A2
	MPYU	A2,A3		     ;REMAINDER TIMES 100
	MOVE	A3,A2		     ;DIVIDEND IN A2

	CALLR	ROUNDED_A0_INTO_A2
	CALLR	A2_100TH	     ;CAT THE 100THS IN A2 TO THE A7 STRING.

NOFRAC2
	MOVI	COINS_TRAIL,A8		 ;ASSUME IT WILL BE "COINS"
	CALLR	SIXP		     ;TAMPERED?
	JRZ	COIN_SUF2	     ;YEP....USE " COINS"
	MOVE	*A6(CS_RMES),A8,L    ;FINISH IT OFF WITH RIGHT STRING

COIN_SUF2
	CALLA	STRCAT		     ;SHOVE THE STRING IN!
	MOVI	M_MONEY,A8		  ;MESSAGE FOR THIS LINE PASSED IN A9
	CALLA	LM_SETUP

	MOVE	@TMPOBJ,A8,L	     ;POINTER TO MONEY STRING
	JSRP	RIGHT_FINISH		;PUT ON RIGHT MARGIN

	CALLR	STR_FREE

	MOVE	*A13(AT_MESS),A8,L	;SETUP PASSED MESSAGE
	CALLA	LM_SETUP
	JSRP	LEFT_FINISH		;PUT UP PASSED MESSAGE.
NO_MONEY2
	RETP

**************************************************************************
*									 *
*	   STR_OBJ							 *
*									 *
*	   THIS IS CALLED TO GET AN OBJECT FOR				 *
*	   CONCATONATING STRINGS TOGETHER.				 *
*									 *
*	   A7 POINTS AT NULL STRING					 *
*									 *
*	   NOTE THAT THIS IS NO LONGER RE-ENTRANT!			 *
*									 *
*	   YOU MUST CALL STR_FREE BEFORE SLEEPING!			 *
*									 *
**************************************************************************
STR_OBJ
	PUSH	a0,a1,a14
	CALLA	GETOBJ		     ;USE AN OBJECT BLOCK FOR STRING MANIPULATION
	JRNZ	STR_O1
*
*	NO OBJECTS DURING TEST MODE
*
	SETC	
	JRUC	STR_OFAIL

STR_O1
	MOVE	A0,@TMPOBJ,L	     ;SAVE TO FREE LATER
	MOVE	A0,A7		     ;THIS IS WHERE IT BELONGS.
	CLR	A0
	MOVB	A0,*A7		     ;MAKE STRING NULL
	CLRC			     ;RETURN SUCCESS
STR_OFAIL
	PULL	a0,a1,a14
	RETS

**************************************************************************
*									 *
*	   ROUNDED_A0_INTO_A2						 *
*									 *
*	   THIS DIVIDES A0 INTO A2.  IT LEAVES THE RESULT IN A2 	 *
*	   AND ROUNDS UP IF NECESSARY.					 *
*									 *
**************************************************************************
ROUNDED_A0_INTO_A2
	MMTM	SP,A3
	MOVE	A0,A0		     ;DIVIDE BY ZERO?
	JRNZ	NDZ
	MOVE	A0,A2		     ;RETURN ZERO
	JRUC	NOROUND
NDZ
	MOVE	A2,A3
	CLR	A2		     ;<A2> <A3> AS DIVIDEND
	DIVU	A0,A2		     ;DIVIDE AND A2 = PENNIES....A3 = REMAINDER
	SLL	1,A3		     ;SHIFT REMAINDER
	CMP	A0,A3		     ;COMPARE TO DIVISOR
	JRLO	NOROUND 	     ;TOO LOW TO ROUND UP
	INC	A2		     ;A2 HAS CORRECT PENNIES
NOROUND
	MMFM	SP,A3
	RETS

**************************************************************************
*									 *
*	   A2_100TH							 *
*									 *
*	   A7 HAS A STRING TO BE PRINTED.  WE HAVE THE			 *
*	   LAST TWO NUMBERS (NOT TO BE LEAD ZERO BLANKED) IN		 *
*	   A2.	CONCATONATE THEM ONTO THE A7 STRING.			 *
*									 *
*	   THIS IS USED FOR PENNIES, HOURS AND MINUTES. 		 *
*									 *
**************************************************************************
A2_100TH
	MMTM	SP,A8
	CMPI	9,A2		     ;9 OR LESS REQUIES LEAD ZERO.
	JRHI	NOLEAD

	MOVI	ME_ZERO,A8	     ;THROW IN THE LEAD ZERO
	CALLA	STRCAT		     ;THIS DOES IT!

NOLEAD
	MOVE	A2,A8
	CALLA	HEXTOASC	     ;MAKE STRING
	CALLA	STRCAT		     ;PUT IT IN!
	MMFM	SP,A8
	RETS

**************************************************************************
*									 *
*	   SUM_COINS							 *
*									 *
*	   A8 HAS FIRST OF THE 4 AUDIT NUMBERS OF INTEREST		 *
*									 *
*	   RETURN COINS TIMES THEIR FACTORS IN A2.			 *
*									 *
**************************************************************************
SUM_COINS
	MMTM	SP,A0,A1,A3,A6,A4

	MOVE	A8,A0			  ;POINT AT AUDIT NUMBER
	CLR	A2			  ;SUM = ZERO

	CALLR	GET_CSPT		  ;A6 POINTS AT CSELECT TABLE
	ADDI	CS_LVAL,A6		  ;POINT AT 1ST MULTIPLIER

	MOVI	CHUTES,A4		  ;NOW...ITERATE OVER THE CHUTES

NEXT_CHUTE
	MOVE	*A6+,A3,W		  ;GET MULTPLIER FOR THIS CHUTE
	CALLR	FIX_A3			  ;REPLACE A3 WITH 1 (MULTIPLIER) IF
					  ;ITS SOME CUSTOM MODE.
	CALLR	ADD_AUD_A0_TIMES_A3_TO_A2
	INC	A0			  ;NEXT AUDIT
	DSJS	A4,NEXT_CHUTE

	MMFM	SP,A0,A1,A3,A6,A4
	RETS

ADD_AUD_A0_TIMES_A3_TO_A2
	CALLA	GET_AUD 		  ;FETCH THE AUDIT
	MPYU	A1,A3			  ;TIME THE FACTOR
	ADD	A3,A2
	RETS

**************************************************************************
* FIX_A3
*
* THIS IS CALLED BY THE LOW LEVEL MONEY TOTALIZER.
* THE MULTIPLIER FOR THE COIN SLOT THAT ITS WORKING
* ON IS IN A3.  WE REPLACE IT WITH "1" TO SUM "TOTAL COINS"
* IF ITS IN A NON-STANDARD COIN MODE.
*
**************************************************************************
FIX_A3
	CALLR	SIXP		     ;HAS IT BEEN TAMPERED WITH?
	JRNZ	FIX_A3X 	     ;NOPE...LEAVE A3

	MOVK	1,A3
FIX_A3X
	RETS

**************************************************************************
* SIXP
*
* THIS IS CALLED TO SEE IF THE 1ST 6 COIN PARAMETERS HAVE
* BEEN TAMPERED WITH.
*
* Z=YES
*
**************************************************************************
SIXP
	MMTM	SP,A0
	MOVI	ADJ1ST6,A0
	CALLA	GET_ADJ		;HAS IT BEEN TAMPERED WITH?
	MMFM	SP,A0
	RETS

STARTS
	CALLR	GET_STARTS
	MOVE	A2,A3		;GET IN PRINTOUT REG.
	jruc	NUMBER_WORK	;AND PRINT IT

CONTINS
	CALLR	GET_CONTS
	MOVE	A2,A3		;GET IN PRINTOUT REG.
	jruc	NUMBER_WORK	;AND PRINT IT

DOPLAYS
	CALLR	GET_PLAYS
	MOVE	A2,A3		;PUT IN PLACE
	jruc	NUMBER_WORK

DOHSLEFT
	MOVI	ADJHSRES,A0
	CALLA	GET_ADJ 	;IS IF OFF?
	JRZ	DOHSOFF 	;YEP...PRINT IT

	CALLA	GET_HSC 	;GET THE COUNTER VALUE
	MOVE	A0,A3
	jruc	NUMBER_WORK	;AND SHOW IT!

DOHSOFF
	MOVI	MESS_AUD_NUM,A8
	CALLA	LM_SETUP	;SETUP FOR AUDIT PRINTING.

	MOVI	M_HSOFF,A8	;THIS EFFECTIVELY ERASES LINE!
	JAUC	RIGHT_FINISH

DO_P1MIN
	MOVI	AUD1TIME,A0
P1MJ
	CALLA	GET_AUD 	;TURN INTO NUMBER
	MOVE	A1,A4		;MOVE NUMBER TO "HOUR" COMPUTATION REGGIE
	JRUC	DH11		;AND DO LIKE THE HOURS!


DO_P2MIN
	MOVI	AUD2TIME,A0
	JRUC	P1MJ

DO_HOURS
	CALLR	TOT_TIME	;READ OUT THE TOTAL TIME.
DH11	MOVE	A4,A5		;A5 HAS RUNNING PLAY TIME
	CLR	A4		;<A4><A5> READY FOR DIVISION
	MOVK	12,A0
	DIVU	A0,A4		;A4 HAS MINUTES
	CMPI	6,A5		;ROUND PROPERLY
	JRLO	DH1		;NOT ENOUGH
	INC	A4
DH1
	MOVE	A4,A1		;NOW THIS DIVIDED BY 60 IS WHAT WE NEED
	jruc	P_TIME		;DO IT!

DO_AVGT
	CALLR	TOT_TIME	;A3 HAS WEIGHTED TIME

DOAVC	CALLR	GET_PLAYS	;GET TOTAL PLAYS IN A2
	MOVE	A2,A0		;STASH IN A0.
	MOVK	5,A1		;TURN INTO SECONDS
	MPYU	A1,A3		;A3 HAS SECONDS OF INTEREST
	MOVE	A3,A2
	CALLR	ROUNDED_A0_INTO_A2   ;DIVIDE A2 BY PLAYS (AND ROUND)
	MOVE	A2,A1		;NOW GET IN PLACE FOR P_TIME
	jruc	P_TIME		;DO IT!

DO_ELAPSE
	CALLR	TOT_TIME
	MOVE	A4,A3		;USE ELAPSED TIME
	JRUC	DOAVC		;AND THE REST IS IDENTICAL.


keyavg_prt
;	movi	AUDKEYTOT,a0
;	calla	GET_AUD
;	move	a1,a3
;	movi	AUDFULLGAMES,a0
;	calla	GET_AUD
;	divs	a1,a3
;	jruc	NUMBER_WORK	;Print it


diff_prt
	movk	ADJDIFF,a0
	calla	GET_ADJ
	move	a0,a3
	jruc	NUMBER_WORK	;Print it


**************************************************************************
*									 *
*	   P_TIME							 *
*									 *
*	   THIS IS CALLED TO DISPLAY AN AUDIT IN TIME (0:00)		 *
*	   FORMAT.  THE NUMBER TO BE USED IS PASSED IN A1.		 *
*									 *
**************************************************************************
P_TIME
	CALLR	STR_OBJ		;USE AN OBJECT BLOCK FOR STRING MANIPULATION
	JRC	NO_OBJS		;NO OBJECTS....PRINT NOTHING

	CLR	A0		;DIVIDEND IN <A0><A1>
	MOVI	60,A2
	DIVU	A2,A0		;A0 = "MINUTES"....A1 = "SECONDS

	CALLA	CAT_A0		;ADD A0 STRING TO A7 BUILD
	MOVI	ME_COLON,A8
	CALLA	STRCAT		;PUT THE COLON IN.

	MOVE	A1,A2		;GET "SECONDS" IN A2
	CALLR	A2_100TH	;AND GET THE 100THS IN.

	MOVI	MESS_AUD_NUM,A8	;SETUP FOR AUDIT NUMBER
	CALLA	LM_SETUP
	move	*a13(AT_PTR),a6,L	;Get *audit
	move	*a6(AUD_COLOR),a6

	MOVE	A7,A8		;PUT STRING CORRECT REGGIE
	JSRP	RIGHT_FINISH	;PRINT THE LINE

	CALLR	STR_FREE	;FREE UP THE OBJECT!

NO_OBJS
	RETP			;NOW RETURN TO CALLER

STR_FREE
	MOVE	@TMPOBJ,A0,L	;GET OBJECT BACK
	JRNZ	FREE_IT_NOW

	.IF	DEBUG
	JRUC	$
	.ENDIF
	RETS			;NO OBJECT...RETURN!

FREE_IT_NOW
	jauc	FREEOBJ 	;AND LET IT GO.
	
**************************************************************************
*									 *
*	TOT_TIME							 *
*									 *
*	(1 * P1TIME) + (2 * P2TIME) IN A3				 *
*	ELAPSED TIME IN A4						 *
*									 *
**************************************************************************
TOT_TIME
	MMTM	SP,A0,A1
	MOVI	AUD1TIME,A0
	CALLA	GET_AUD
	MOVE	A1,A3
	MOVE	A1,A4
	MOVI	AUD2TIME,A0
	CALLA	GET_AUD
	ADD	A1,A4		     ;A4 HAS SIMPLE SUM NOW
	SLL	1,A1		     ;DOUBLE THE PLAYER 2 TIME
	ADD	A1,A3
	MMFM	SP,A0,A1
	RETS


********************************
**** DATA SECTION BEGINS ****

	.DATA



********************************
* AUDIT TEXT

MESS_ERROR
	MESS_MAC RD7FONT,SPACING07,0,0,ROBO_RED,STRLNRM,0
	TXTLINE	"  ERROR"

MESS_AUD_NUM
	MESS_MAC RD7FONT,SPACING20,367,227,ROBO_YELLOW,STRRNRM,0

MESS_AUD_LINE
	MESS_MAC RD7FONT,SPACING20,23,227,ROBO_YELLOW,STRLNRM,0


MES_AUD	TXTLINE	"GAME AUDITS"

MES_BOOK
	TXTLINE	"COIN BOOKKEEPING"

M_LCOIN TXTLINE	"LEFT SLOT COINS"
M_CCOIN TXTLINE	"CENTER SLOT (3) COINS"
M_RCOIN TXTLINE	"RIGHT SLOT COINS"

M_LCOIN2 TXTLINE "JAMS FROM THE LEFT"
M_CCOIN2 TXTLINE "JAMS FROM THE CENTER"
M_RCOIN2 TXTLINE "JAMS FROM THE RIGHT"

M_XCOIN TXTLINE	"EXTRA SLOT (4) COINS"

M_PAIDC TXTLINE	"PAID CREDITS"

M_SERV	TXTLINE	"SERVICE CREDITS"


M_PLAYS TXTLINE	"TOTAL PLAYS"

M_HSLEFT
	TXTLINE	"PLAYS UNTIL H.S. RESET"

M_HSOFF TXTLINE	"OFF"

	.even
M_ELAPSE
	TXTLINE	"AVG. ELAPSED TIME/PLAY"

M_MONEY	MESS_MAC  RD15FONT,SPACING20,367,227,ROBO_WHITE,STRRNRM,0

T_MONEY MESS_MAC  RD15FONT,SPACING20,23,227,ROBO_WHITE,STRLNRM,0
	TXTLINE	"TOTAL COLLECTION"

T_MONEY2 MESS_MAC  RD15FONT,SPACING20,23,227,ROBO_WHITE,STRLNRM,0
	TXTLINE	"JAM INFO"

M_VERINF
	TXTLINE	"031-0"

M_LOCKUP
	TXTLINE	"LOCKUPS"
M_HIDB	TXTLINE	"GAMES NOT FINISHED"

M_SECBON
	TXTLINE	"WARPS"


**************************************************************************
*									 *
*	   MENU DESCRIPTORS						 *
*									 *
**************************************************************************
*
*	 MAIN TEST MENU
*
MEN_MAIN
	 .LONG	 RD7FONT	;FONT	
	 .LONG	 STRCNRM	;CENTER PLEASE
	 .LONG	 MESSMAIN	;TITLE
	 .WORD	 ROBO_WHITE	;COLOR OF TITLE
	 .WORD	 MENU_X 	;UL X
	 .WORD	 MENU_Y-3	;UL Y
	 .WORD	 MENU_DY	;VERTICAL SPACING
	 .WORD	 ROBO_WHITE	;COLOR WHEN NOT SELECTED
	 .WORD	 16		;HEIGHT OF SELECTION BAR
	 .WORD	 -4		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	 .WORD	 BAR_DX 	;EXTRA X ON EACH SIDE.
	 .WORD	 BAR_WID	;WIDTH OF BAR!
	 .WORD	 ROBO_DECAY	;TEXT COLOR OF SELECTED ITEM
	 .LONG	 MESS_DIAG,GO_DIAG,DIAG_HELP
	 .LONG	 MESS_COIN_AUD,GO_BOOK,COIN_HELP
	 .LONG	 MESS_GAME_AUD,GO_AUD,AUDIT_HELP
	 .LONG	 MESS_GAME_ADJ,GO_ADJ,ADJUST_HELP
	 .LONG	 MESS_UTIL,GO_UTIL,UTIL_HELP
	 .LONG	 MESS_EXIT,0,EXIT_HELP	;SPECIAL CASE!
	 .LONG	 0		;END

* UTILITES MENU GOES LEFT OF CENTER

UM_WID	 EQU	 206
UM_X	 EQU	 TIT_ULX+GAP+MB_XWID+(UM_WID/2)+C_KLUDGE

MEN_UTIL
	.LONG	RD7FONT		;FONT
	.LONG	STRCNRM		;CENTER PLEASE
	.LONG	MESSUTIL	;TITLE
	.WORD	COLOR_WHITE	;COLOR OF TITLE
	.WORD	UM_X		;UL X
	.WORD	MENU_Y-3	;UL Y
	.WORD	18		;VERTICAL SPACING
	.WORD	COLOR_WHITE	;COLOR WHEN NOT SELECTED
	.WORD	16		;HEIGHT OF SELECTION BAR
	.WORD	-4		;DISTANCE OF BAR FROM TOP OF TEXT (NEG)
	.WORD	BAR_DX 		;EXTRA X ON EACH SIDE.
	.WORD	UM_WID 		;WIDTH OF BAR!
	.WORD	COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	MESS_CLCRED,DO_CLCRED,CLCRED_HELP
	.LONG	MESS_CLCOIN,DO_CLCOIN,CLCOIN_HELP
	.LONG	MESS_CLAUD,DO_CLAUD,CLAUD_HELP
	.LONG	MESS_HSRES,DO_HSRES,HSRES_HELP
	.LONG	MESS_CLPLRECS,DO_CLPLRECS,CLPLRECS_HELP
	.LONG	MESS_DEF_ADJ,DO_DEF_ADJ,DEF_ADJ_HELP
	.LONG	MESS_FACSET,DO_FACSET,FACSET_HELP
	.LONG	opmsg_s,opmsg_main,OPMSG_HELP
	.LONG	MESS_MM,0,BLNK_HELP	;RETURN TO MAIN MENU
	.LONG	0			;END

* DIAGNOSTIC TESTS MENU

MEN_DIAG
	.LONG	RD7FONT		;FONT
	.LONG	STRCNRM		;CENTER PLEASE
	.LONG	MESSDIAG	;TITLE
	.WORD	COLOR_RED	;COLOR OF TITLE
	.WORD	200		;UL X
	.WORD	MENU_Y-3	;UL Y
	.WORD	20		;VERTICAL SPACING
	.WORD	COLOR_RED	;COLOR WHEN NOT SELECTED
	.WORD	16		;HEIGHT OF SELECTION BAR
	.WORD	-4		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	BAR_DX		;EXTRA X ON EACH SIDE.
	.WORD	195		;WIDTH OF BAR!  (A LITTLE FATTER)
	.WORD	COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	MESS_SWTEST,GO_SWTEST,BLNK_HELP
	.LONG	diptst_mess,dipsw_test,BLNK_HELP
ROM_LEV EQU	3		;TEST NUMBER FOLLOWING ROM TEST
	.LONG	MESS_CPUTEST,GO_CPUTEST,BLNK_HELP
RTR_LEV EQU	4		;TEST NUMBER FOLLOWING CPU TEST (FOR RETURN)
	.LONG	M_STEST,GO_STEST,BLNK_HELP
	.LONG	MESS_PATTERNS,GO_PATTERNS,BLNK_HELP
	.LONG	MESS_BURN,DO_BURN,BLNK_HELP
	.LONG	MESS_MM,0,BLNK_HELP	;RETURN TO MAIN MENU
	.LONG	0

STM_WID EQU	  250


* PRESS ANY BUTTON TO CONTINUE

ANY_MENU
	.LONG	RD7FONT		;FONT
	.LONG	STRCNRM		;CENTER PLEASE
	.LONG	0		;TITLE
	.WORD	0		;COLOR OF TITLE
	.WORD	200		;UL X
	.WORD	200		;UL Y
	.WORD	MENU_DY		;VERTICAL SPACING
	.WORD	COLOR_BLUE	;COLOR WHEN NOT SELECTED
	.WORD	BAR_HITE	;HEIGHT OF SELECTION BAR
	.WORD	-9		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	BAR_DX		;EXTRA X ON EACH SIDE.
	.WORD	234		;WIDTH OF BAR!
	.WORD	COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	MESS_ANY,0,NO_HELP
	.LONG	0

* MONITOR PATTERNS

MEN_PATTERNS
	.LONG	RD7FONT		;FONT
	.LONG	STRCNRM		;CENTER PLEASE
	.LONG	MESSPAT		;TITLE
	.WORD	COLOR_RED	;COLOR OF TITLE
	.WORD	200		;UL X	    (CENTER IT!)
	.WORD	MENU_Y-3	;UL Y
	.WORD	23		;VERTICAL SPACING
	.WORD	COLOR_YELLOW	;COLOR WHEN NOT SELECTED
	.WORD	16		;HEIGHT OF SELECTION BAR
	.WORD	-4		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	BAR_DX		;EXTRA X ON EACH SIDE.
	.WORD	234		;WIDTH OF BAR!
	.WORD	COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	MESS_RED,GO_RED,BLNK_HELP
	.LONG	MESS_GREEN,GO_GREEN,BLNK_HELP
	.LONG	MESS_BLUE,GO_BLUE,BLNK_HELP
	.LONG	MESS_BARS,GO_BARS,BLNK_HELP
	.LONG	MESS_CROSS,GO_CROSS,BLNK_HELP
	.LONG	MESS_DIAGM,0,BLNK_HELP
	.LONG	MESS_MM,FORCE_MAIN,NO_HELP	;RETURN TO MAIN MENU
	.LONG	0

* DETAILED COINAGE AVAILABLE (ON 1ST COINAGE PAGE)

MEN_DETAIL
	.LONG	RD7FONT	;FONT
	.LONG	STRCNRM	;CENTER PLEASE
	.LONG	MESSPAT	;TITLE
	.WORD	COLOR_YELLOW	;COLOR OF TITLE
	.WORD	200		;UL X	    (CENTER IT!)
	.WORD	224		;UL Y
	.WORD	12		;VERTICAL SPACING
	.WORD	COLOR_BLUE	;COLOR WHEN NOT SELECTED
	.WORD	10		;HEIGHT OF SELECTION BAR
	.WORD	-1		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	BAR_DX 	;EXTRA X ON EACH SIDE.
	.WORD	157		;WIDTH OF BAR!
	.WORD	COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	MESS_CLCOIN,0,NO_HELP		;Clr coins
	.LONG	MESS_MM,FORCE_MAIN,NO_HELP	;RETURN TO MAIN MENU
	.LONG	0

* YES/NO   (FOR ARE YOU SURE?)

MEN_YN	.LONG	 RD7FONT	;FONT
	.LONG	 STRCNRM	;CENTER PLEASE
	.LONG	 MESSDIAG	;TITLE
	.WORD	 COLOR_RED	;COLOR OF TITLE
	.WORD	 200		;UL X
	.WORD	 166		;UL Y
	.WORD	 19		;VERTICAL SPACING
	.WORD	 COLOR_YELLOW	;COLOR WHEN NOT SELECTED
	.WORD	 16		;HEIGHT OF SELECTION BAR
	.WORD	 -4		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	 BAR_DX 	;EXTRA X ON EACH SIDE.
	.WORD	 78		;WIDTH OF BAR!  (A LITTLE FATTER)
	.WORD	 COLOR_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	 MESS_YES,0,NO_HELP
	.LONG	 MESS_NO,0,NO_HELP
	.LONG	 0

* NEXT AUDIT PAGE

MEN_AP1 .LONG	 RD7FONT	;FONT
	.LONG	 STRCNRM	;CENTER PLEASE
	.LONG	 MESSPAT	;TITLE
	.WORD	 ROBO_YELLOW	;COLOR OF TITLE
	.WORD	 200		;UL X	    (CENTER IT!)
	.WORD	 226		;UL Y
	.WORD	 12		;VERTICAL SPACING
	.WORD	 COLOR_BLUE	;COLOR WHEN NOT SELECTED
	.WORD	 10		;HEIGHT OF SELECTION BAR
	.WORD	 -1		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	 BAR_DX 	;EXTRA X ON EACH SIDE.
	.WORD	 157		;WIDTH OF BAR!
	.WORD	 ROBO_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	 MESS_TOPAGE2,0,NO_HELP 	;DETAILED SECTION
	.LONG	 MESS_MM,FORCE_MAIN,NO_HELP;RETURN TO MAIN MENU
	.LONG	 0


* PREVIOUS AUDIT PAGE?  (ON 2ND GAME AUDIT PAGE)

MEN_AP2 .LONG	 RD7FONT	;FONT
	.LONG	 STRCNRM	;CENTER PLEASE
	.LONG	 MESSPAT	;TITLE
	.WORD	 ROBO_YELLOW	;COLOR OF TITLE
	.WORD	 200		;UL X	    (CENTER IT!)
	.WORD	 226		;UL Y
	.WORD	 12		;VERTICAL SPACING
	.WORD	 COLOR_BLUE	;COLOR WHEN NOT SELECTED
	.WORD	 10		;HEIGHT OF SELECTION BAR
	.WORD	 -1		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	 BAR_DX 	;EXTRA X ON EACH SIDE.
	.WORD	 157		;WIDTH OF BAR!
	.WORD	 ROBO_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	 MESS_TOPAGE2,0,NO_HELP
	.LONG	 MESS_BACKP1,0,NO_HELP		;DETAILED SECTION
	.LONG	 0



MEN_AP3 .LONG	 RD7FONT	;FONT
	.LONG	 STRCNRM	;CENTER PLEASE
	.LONG	 MESSPAT	;TITLE
	.WORD	 ROBO_YELLOW	;COLOR OF TITLE
	.WORD	 200		;UL X	    (CENTER IT!)
	.WORD	 226		;UL Y
	.WORD	 12		;VERTICAL SPACING
	.WORD	 COLOR_BLUE	;COLOR WHEN NOT SELECTED
	.WORD	 10		;HEIGHT OF SELECTION BAR
	.WORD	 -1		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	 BAR_DX 	;EXTRA X ON EACH SIDE.
	.WORD	 157		;WIDTH OF BAR!
	.WORD	 ROBO_DECAY	;TEXT COLOR OF SELECTED ITEM
	.LONG	 MESS_MM,FORCE_MAIN,NO_HELP;RETURN TO MAIN MENU
	.LONG	 MESS_BACKP1,0,NO_HELP		;DETAILED SECTION
	.LONG	 0


MEN_SOUNDTEST
	.LONG	RD7FONT	;FONT
	.LONG	STRCNRM	;CENTER PLEASE
	.LONG	MESS_SNDTST0	;TITLE
	.WORD	ROBO_YELLOW	;COLOR OF TITLE
	.WORD	200		;UL X	    (CENTER IT!)
	.WORD	MENU_Y-3	;UL Y
	.WORD	20		;VERTICAL SPACING
	.word	ROBO_RED	;colour when not selected
	.WORD	16		;HEIGHT OF SELECTION BAR
	.WORD	-4		;DISTANCE OF BAR FROM TOP OF TEXT (NEGATIVE)
	.WORD	BAR_DX 		;EXTRA X ON EACH SIDE.
	.WORD	192+6		;WIDTH OF BAR!
	.WORD	ROBO_DECAY	;TEXT COLOR OF SELECTED ITEM
	.long	MESS_SNDTST1,DO_GENTEST,NO_HELP
	.long	MESS_SNDTST2,DO_PLAYSOUNDS,NO_HELP
	.long	MESS_SNDTST3,0,NO_HELP
	.long	MESS_SNDTST4,FORCE_MAIN,NO_HELP
	.LONG	0

**************************************************************************
*									 *
*	  HELP MENUS FOR MAIN MENU					 *
*									 *
**************************************************************************
*	 HM_JUST	 0 = CENTER   1 = LEFT
*	 HM_COLOR
*	 HM_ENTS

DIAG_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	6		;# ENTRIES
	.LONG	MESS_SWTEST
	.long	diptst_mess
	.LONG	MESS_CPUTEST
	.LONG	M_STEST
	.LONG	MESS_PATTERNS
	.LONG	U_BURNIN

COIN_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	3		;2 ENTRIES
	.LONG	CH_0
	.LONG	CH_1
	.LONG	CH_2

AUDIT_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	2		;2 ENTRIES
	.LONG	AH_1
	.LONG	AH_2

ADJUST_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	3		;3 ENTRIES
	.LONG	AD_1
	.LONG	AD_2
	.LONG	AD_3

UTIL_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	6		;6 ENTRIES
	.LONG	U_CLR_CRED
	.LONG	U_CLR_COIN
	.LONG	U_CLR_AUD
	.LONG	U_HSRESET
	.LONG	U_CLRRECS
	.LONG	U_FACTORY

EXIT_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	1		;1 ENTRY
	.LONG	U_END


********************************
* HELP FOR UTILITY MENU

CLCRED_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	3		;# entries
	.LONG	MEH_CLCRED1
	.LONG	MEH_CLCRED2
	.LONG	MEH_CLCRED3

CLCOIN_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	4		;# entries
	.LONG	MEH_CLCOIN1
	.LONG	MEH_CLCOIN2
	.LONG	MEH_CLCOIN3
	.LONG	MEH_CLCOIN4

CLAUD_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	2		;# entries
	.LONG	MEH_CLAUD1
	.LONG	MEH_CLAUD2

CLPLRECS_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	2		;# entries
	.long	MEH_CLPLRECS1
	.long	MEH_CLPLRECS2

HSRES_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	3		;# entries
	.LONG	MEH_RESHS1
	.LONG	MEH_RESHS2
	.LONG	MEH_RESHS3

DEF_ADJ_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	4		;# entries
	.LONG	MEH_DEFA1
	.LONG	MEH_DEFA2
	.LONG	MEH_DEFA3
	.LONG	MEH_DEFA4

FACSET_HELP
	.WORD	0		;CENTER JUSTIFY
	.WORD	COLOR_BLUE	;COLOR
	.WORD	4		;# entries
	.LONG	MEH_FAC1
	.LONG	MEH_FAC2
	.LONG	MEH_FAC3
	.LONG	MEH_FAC4

OPMSG_HELP
	.word	0		;CENTER JUSTIFY
	.word	COLOR_BLUE	;COLOR
	.word	3		;# entries
	.long	opmsgh1_s
	.long	opmsgh2_s
	.long	opmsgh3_s


**************************************************************************
*									 *
*	   TEXT STRINGS 						 *
*									 *
**************************************************************************

SIY0	equ	190
SIY1	equ	212
SIY2	equ	224
SIY3	equ	236

SND_INST
	 MESS_MAC  RD7FONT,SPACING07,200,SIY1,ROBO_WHITE,STRCNRM,0
	.STRING   "UP AND DOWN TO SELECT SOUND",0,1
	.EVEN
	 MESS_MAC  RD7FONT,SPACING07,200,SIY2,ROBO_WHITE,STRCNRM,0
	.STRING   "PRESS ACTION BUTTON TO PLAY",0,1
	.EVEN
	 MESS_MAC  RD7FONT,SPACING07,200,SIY3,ROBO_WHITE,STRCNRM,0
	.STRING   "PRESS START BUTTON TO EXIT",0,0

SND_SETUP MESS_MAC  RD15FONT,SPACING20,200,SIY0,ROBO_WHITE,STRCNRM,0

sounds_tab	.long	SND_ST0,SND_ST1,SND_ST2,SND_ST3
		.long	SND_ST4,SND_ST5,SND_ST6,SND_ST7


SND_ST0	.string	"GAME START (U3)",0
SND_ST1	.string	"PERIOD END (U3)",0
SND_ST2	.string	"WHOOMP (U13)",0
SND_ST3	.string	"ALLEY OOP (U12)",0
SND_ST4	.string	"RANGE (U12)",0
SND_ST5	.string	"SHOWTIME (U13)",0
SND_ST6	.string	"SHOES? (U13)",0
;SND_ST6	.string	"RAIDEN (U13)",0
SND_ST7	.string	"WEBBER (U12)",0

	.EVEN
TEST_SOUND_TAB
	.WORD	01H,0aH,1abH,1b9H,01e3H,1CBH,1adh,69H
;	.WORD	01H,0aH,1abH,1b9H,01e3H,1CBH,0b0H,69H
;	.WORD	01H,92H,129H,11FH,0B2H,1CBH,1ADH,1EEH

MESS_SNDTST0	.string	"SOUND BOARD TEST",0
MESS_SNDTST1	.string	"GENERAL TEST",0
MESS_SNDTST2	.string	"PLAY SOUNDS",0
MESS_SNDTST3	.string	"BACK TO DIAGNOSTICS MENU",0
MESS_SNDTST4	.string	"RETURN TO MAIN MENU",0

MESS_YES
	.byte	 "YES",0
	.EVEN

MESS_NO .byte	 "NO",0
	.EVEN

;MESS_CLEAR_SUBS
;	  .byte	  "CLEAR SUBTOTALS"
;	  .BYTE 	  0
;	  .EVEN
;
;MESS_SUBS_CLEAR
;	  .byte	  "SUBTOTALS CLEARED"
;	  .BYTE 	  0
;	  .EVEN

MESS_TOPAGE2
	 .byte	 "NEXT AUDIT PAGE"
	 .BYTE		 0
	 .EVEN

MESS_BACKP1
	 .byte	 "PREVIOUS AUDIT PAGE"
	 .BYTE		 0
	 .EVEN

MESS_ANY
	 .byte	 "ANY BUTTON TO CONTINUE"
	 .BYTE		 0
	 .EVEN

MESS_MM
	 .byte	 "RETURN TO MAIN MENU"
	 .BYTE		 0
	 .EVEN

MESSDIAG				;THIS IS TITLE OF PAGE
MESS_DIAG
	 .byte	 "DIAGNOSTIC TESTS"
	 .BYTE	   0
	 .EVEN
MESS_COIN_AUD
	 .byte	 "COIN BOOKKEEPING"
	 .BYTE	   0
	 .EVEN
MESS_GAME_AUD
	 .byte	 "GAME AUDITS"
	 .BYTE	   0
	 .EVEN

MESS_GAME_ADJ
	 .byte	 "GAME ADJUSTMENT"
	 .BYTE	   0
	 .EVEN
MESS_UTIL
	 .byte	 "UTILITIES"
	 .BYTE	   0
	 .EVEN

MESS_EXIT
	 .byte	 "EXIT TO GAME OVER"
	 .BYTE	   0
	 .EVEN

CH_0	 .byte	 "VIEW COINBOX"
	 .BYTE	 0
	 .EVEN
CH_1	 .byte	 "TOTALS AND"
	 .BYTE	 0
	 .EVEN
CH_2	 .byte	 "GAMEPLAY COUNTERS"
	 .BYTE	 0
	 .EVEN

AH_1	 .byte	 "VIEW GAME"
	 .BYTE	 0
	 .EVEN
AH_2	 .byte	 "PLAY STATISTICS"
	 .BYTE	 0
	 .EVEN

AD_1	 .byte	 "MAKE CHANGES",0
	 .EVEN
AD_2	 .byte	 "TO PRICING AND",0
	 .EVEN
AD_3	 .byte	 "DRONE DIFFICULTY",0
	 .EVEN

MESS_CLCRED
U_CLR_CRED	 .byte "CLEAR CREDITS"
	 .BYTE	 0
	 .EVEN

MESS_CCCONF	 .byte "CREDITS CLEARED"
	 .BYTE	 0
	 .EVEN

MESS_CLCOIN
U_CLR_COIN	 .byte "CLEAR COIN COUNTERS"
	 .BYTE	 0
	 .EVEN

MESS_CLAUD
U_CLR_AUD	 .byte "CLEAR GAME AUDITS"
	 .BYTE	 0
	 .EVEN

MESS_CLPLRECS
U_CLRRECS
	.string	"CLEAR PLAYER STATISTICS",0

MESS_HSRESET
U_HSRESET	 .byte "RESET HIGH SCORES"
	 .BYTE	 0
	 .EVEN

MESS_HSRES
	 .byte "RESET HIGH SCORES"
	 .BYTE	 0
	 .EVEN

;M_OPMESS_TIT
;U_OPMESS	  .byte "OPERATOR MESSAGE"
;	  .BYTE   0
;	  .EVEN

;M_SET_OMESS
;;MESS_OPMESS	   .byte "SET OPERATOR MESSAGE"
;	  .BYTE   0
;	  .EVEN

U_BURNIN	.byte "BURN-IN TEST",0
	.even

MESS_BURN	.byte "RUN BURN-IN TEST",0
	.even

MESS_DEF_ADJ	TXTLINE	"DEFAULT ADJUSTMENTS"
U_FACTORY	TXTLINE	"FACTORY SETTINGS"
MESS_FACSET	TXTLINE	"FULL FACTORY RESTORE"

opmsg_s		TXTLINE	"OPERATOR MESSAGE"
opmsgh1_s	TXTLINE	"ENTER AN OPERATOR"
opmsgh2_s	TXTLINE	"MESSAGE TO"
opmsgh3_s	TXTLINE	"THE PLAYERS"


U_END	.byte "END TESTING",0
	.even

MESS_SWTEST	.byte "SWITCH TEST",0
	.even
diptst_mess	.byte "DIP SWITCH TEST",0
	.even
MESS_CPUTEST	.byte "CPU BOARD TEST",0
	.even
M_STEST	.byte	"SOUND BOARD TEST",0
	.even

MESSPAT 		;HEADER TITLE
MESS_PATTERNS	.byte "MONITOR PATTERNS",0
	.EVEN

MESS_RED	.byte "RED SCREEN",0
	.EVEN
MESS_GREEN	 .byte "GREEN SCREEN",0
	.EVEN
MESS_BLUE	 .byte "BLUE SCREEN",0
	.EVEN
MESS_BARS	 .byte "COLOR BARS",0
	.EVEN
MESS_CROSS	 .byte "CROSSHATCH  PATTERN",0
	.EVEN
MESS_DIAGM	 .byte "BACK TO DIAGNOSTICS MENU",0
	.EVEN

*	ON FULL RESTORE....THE FOLLOWING IS PRINTED.
	;0 = END OF STRING...1 = MORE MESSAGES!

MESS_RESET
	MESS_MAC  RD7FONT,SPACING20,200,80,ROBO_RED,STRCNRM,0
MESS_FACFAIL
	.byte  "FAILURE IN CMOS RAM",0,0
	.EVEN

MESS_FFSCONF
MESS_FAC MESS_MAC RD7FONT,SPACING20,200,96,COLOR_WHITE,STRCNRM,0
MESS_DEFCONF
	.byte   "ADJUSTMENTS RESTORED.",0,1
	.EVEN

	MESS_MAC RD7FONT,SPACING20,200,112,COLOR_YELLOW,STRCNRM,0
MESS_CCNCONF
	.byte  "COIN COUNTERS CLEARED.",0,1
	.EVEN

	MESS_MAC RD7FONT,SPACING20,200,128,COLOR_BLUE,STRCNRM,0
MESS_CAUDCONF
	.byte  "GAME AUDITS CLEARED.",0,1
	.EVEN

	MESS_MAC RD7FONT,SPACING20,200,144,COLOR_RED,STRCNRM,0
MESS_HSRCONF
	.byte  "HIGH SCORE TABLE RESET.",0,1
	.EVEN

	MESS_MAC RD7FONT,SPACING20,200,160,COLOR_CYAN,STRCNRM,0
MESS_CLPLRECSCONF
	.string	"PLAYER STATISTICS CLEARED.",0,0
	.EVEN

MESS_CANCELLED
	.byte "CANCELLED",0
	.EVEN

CIN_X	EQU	(TIT_ULX+TIT_LRX)/2
CR_X	EQU	CIN_X-34
CIN_Y	EQU	86

CIY1	EQU	CIN_Y+14
CIY2	EQU	CIY1+15
CIY3	EQU	CIY2+25
CIY4	EQU	CIY3+25

M_TEAM	MESS_MAC  RD7FONT,SPACING20,200,67,ROBO_WHITE,STRCNRM,0
	.byte	"TOTAL CARNAGE TEAM:",0,1
	MESS_MAC  RD7FONT,SPACING20,200,97,ROBO_WHITE,STRCNRM,0
	.byte	"MARK TURMELL",0,1
	MESS_MAC  RD7FONT,SPACING20,200,107,ROBO_WHITE,STRCNRM,0
	.byte	"JOHN TOBIAS",0,1
	MESS_MAC  RD7FONT,SPACING20,200,117,ROBO_WHITE,STRCNRM,0
	.byte	"JIM GENTILE",0,1
	MESS_MAC  RD7FONT,SPACING20,200,127,ROBO_WHITE,STRCNRM,0
	.byte	"SHAWN LIPTAK",0,1
	MESS_MAC  RD7FONT,SPACING20,200,137,ROBO_WHITE,STRCNRM,0
	.byte	"JON HEY",0,1
	MESS_MAC  RD7FONT,SPACING20,200,147,ROBO_WHITE,STRCNRM,0
	.byte	"TONY GOSKIE",0,0
	.even

**************************************************************************
*									 *
*	   STRINGS FOR UTILITY HELP MENUS				 *
*									 *
**************************************************************************
MEH_CLCRED1	 .byte "REMOVE ANY",0
		 .EVEN
MEH_CLCRED2	 .byte "POSTED CREDITS",0
		 .EVEN
MEH_CLCRED3	 .byte "FROM THE GAME",0
		 .EVEN

MEH_CLCOIN1	 .byte "CLEAR OUT PAID",0
		 .EVEN
MEH_CLCOIN2	 .byte "CREDITS TOTAL",0
		 .EVEN
MEH_CLCOIN3	 .byte "AND THE COIN",0
		 .EVEN
MEH_CLCOIN4	 .byte "SLOT COUNTERS",0
		 .EVEN

MEH_CLAUD1	 .byte "CLEAR GAMEPLAY",0
		 .EVEN
MEH_CLAUD2	 .byte "STATISTICS",0
		 .EVEN

MEH_CLPLRECS1	.string	"CLEAR PLAYER",0
		.even
MEH_CLPLRECS2	.string	"STATISTICS",0
		.even

MEH_RESHS1	 .byte "RESET HIGH SCORE",0
		 .EVEN
MEH_RESHS2	 .byte "TABLE TO FACTORY",0
		 .EVEN
MEH_RESHS3	 .byte "DEFAULT VALUES",0
		 .EVEN

MEH_DEFA1	 .byte "SET ALL GAME",0
		 .EVEN
MEH_DEFA2	 .byte "ADJUSTMENTS TO",0
		 .EVEN
MEH_DEFA3	 .byte "THEIR FACTORY",0
		 .EVEN
MEH_DEFA4	 .byte "DEFAULT VALUE",0
		 .EVEN


MEH_FAC1
	.STRING "RESET ALL AUDITS,",0
	.EVEN
MEH_FAC2
	.STRING "COUNTERS, ADJUSTMENTS,",0
	.EVEN
MEH_FAC3
	.STRING "HIGH SCORES AND",0
	.EVEN
MEH_FAC4
	.STRING "THE PLAYER STATISTICS.",0
	.EVEN


**************************************************************************
*									 *
*	  MAIN MENU NAMES						 *
*									 *
**************************************************************************
MESSMAIN
	.byte	"NBA JAM TEST MENU",0
	.even

MESSUTIL
	.byte	"UTILITY MENU",0
	.even



CSELCT
**************************************************************************
*											     *
*   USA 1: 1 COIN = 1 CREDIT								     *
* 											     *
*          2 TO START / 2 TO CONTINUE							     *
*											     *
**************************************************************************
	.WORD	1,4,1,0,1,0,0,2,2	;WILLY PRICING
	.WORD	4			;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1			;DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0			;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	;CHARACTER STRINGS.
	.LONG	OCOP			;ONE COIN ONE PLAY
	.LONG	USA_1			;TITLE OF COIN MODE
	.LONG	Q_Q		;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_NONE		;NO PRICING LINE ON 2/1
	.LONG	USA_QDQ			;QUARTER

**************************************************************************
*											     *
*   USA 2: 1 COIN = 1 CREDIT								     *
* 											     *
*          2 TO START / 1 TO CONTINUE							     *
*											     *
**************************************************************************
	.WORD	1,4,1,0,1,0,0,2,1	;WILLY PRICING
	.WORD	4			;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1			;DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0			;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	;CHARACTER STRINGS.
	.LONG	OCOP			;ONE COIN ONE PLAY
	.LONG	USA_2			;TITLE OF COIN MODE
	.LONG	Q_Q		;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_NONE		;NO PRICING LINE ON 2/1
	.LONG	USA_QDQ			;QUARTER


**************************************************************************
*											     *
* 	USA 3	 COINAGE IS 25 CENT		 					     *
*		 1 TO START / 1 TO CONTINUE						*
*											     *
**************************************************************************

	.WORD	1,4,1,0,1,0,0,1,1	   ;WILLY PRICING
	.WORD	4				;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1				;DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;ONE COIN ONE PLAY
	.LONG	USA_3			 ;TITLE OF COIN MODE
	.LONG	Q_Q			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_NONE		;NO PRICING LINE ON 2/1
	.LONG	USA_QDQ			;QUARTER

**************************************************************************
*											     *
* 	USA 4	 COINAGE IS 50 CENT	 3/$1.00					     *
*		 1 TO START / 1 TO CONTINUE						*
*											     *
**************************************************************************

	.WORD	1,4,1,0,2,4,0,1,1     ; WILLY PRICING
	.WORD	4		  	; 4 COINS PER DOLLAR (FOR CALC)
	.WORD	1		  	; DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0		   	; COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	; CHARACTER STRINGS.
	.LONG	CSM_LIST		; PRINT THE 2 THE OP SEES
	.LONG	USA_4			; TITLE OF COIN MODE
	.LONG	DOLLAR_3		; 1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			; SHOW LINE 2
	.LONG	USA_QDQ			; QUARTER
						

**************************************************************************
*											     *
*  ADDITION "FULL PRICE" COINAGES							     *
*											     *
**************************************************************************

	.IF	FULLPRICE

**************************************************************************
*											     *
* 	USA 5	 COINAGE IS 50 CENT	 4/$1.00					     *
*		 2 TO START / 1 TO CONTINUE						*
*											     *
**************************************************************************

	.WORD	3,12,3,0,4,12,6,2,1	 ;WILLY PRICING
	.WORD	4			;4 COINS PER DOLLAR (FOR CALC)
	.WORD	0				;NO COIN FRACTIONS
	.WORD	1,4,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;PRINT THE 2 THE OP SEES
	.LONG	USA_5			 ;TITLE OF COIN MODE
	.LONG	DOLLAR_4			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			;SHOW LINE 2
	.LONG	USA_QDQ			;QUARTER

*
*	USA 6	 50 PER CREDIT
*
	.WORD	1,4,1,0,2,0,0,1,1	; WILLY PRICING
	.WORD	4				;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1				;DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;2 COINS PER PLAYER
	.LONG	USA_6			 ;TITLE OF COIN MODE
	.LONG	F_F_1S1C		 ;2 COINS PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_1			;SHOW LINE 1
	.LONG	USA_QDQ			;QUARTER
*						
*	USA 7	 COINAGE IS 50 CENT	 3/$1.00
*
	.WORD	1,4,1,0,2,4,0,1,1	   ;WILLY PRICING
	.WORD	4				;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1				;DISPLAY COIN FRACTIONS
	.WORD	1,4,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;PRINT THE 2 THE OP SEES
	.LONG	USA_7			 ;TITLE OF COIN MODE
	.LONG	UFS3D			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			;SHOW LINE 2
	.LONG	USA_QDQ			;QUARTER

*						
*	USA 8	 COINAGE IS 50 CENT	 4/$1.00
*
	.WORD	3,12,3,0,4,12,6,2,2	 ;WILLY PRICING
	.WORD	4				;4 COINS PER DOLLAR (FOR CALC)
	.WORD	0				;NO COIN FRACTIONS
	.WORD	1,4,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;PRINT THE 2 THE OP SEES
	.LONG	USA_8			 ;TITLE OF COIN MODE
	.LONG	UFS4D			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			;SHOW LINE 2
	.LONG	USA_QDQ			;QUARTER

	.ENDIF
*
*	USA ELECTRONIC
*
	.WORD	20,2,5,1,5,0,0,2,2	; L,C,R,4,U/C,U/B,MINUNITS
	.WORD	20			; COINS/DOLLAR
	.WORD	1			; DISPLAY FRACTIONS
	.WORD	20,2,5,1		; L,C,R,4
	.LONG	DOLLAR_LEAD,NULL_ST	; CHARACTER STRINGS.
	.LONG	USA_ELECTRONIC		; SPECIAL MESSAGE
	.LONG	USA_ELECTITLE		; TITLE OF COIN MODE
	.LONG	USA_EL			; SETTINGS DESCRIPTION
	.WORD	SHOW_2			; LINES TO SHOW ON
	.LONG	USA_ESLOT		; QUARTER

*
*	GERMAN 1    COINAGE IS 6 PLAYS FOR 5 DM
*			 2 TO START, 2 TO CONTINUE
*
	.WORD	6,12,30,0,5,0,0,2,2	 ;WILLY PRICING
	.WORD	1		   	 ;DMS HAVE NO FRACTIONS
	.WORD	0			 ;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,2,5,0			 ;COIN VALUE
	.LONG	NULL_ST,DM_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	GERMAN_1			 ;TITLE OF COIN MODE
	.LONG	DM_6			  ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	GERMAN_15			;1 DM / 5 DM

G1SEL	EQU	($-CSELCT)/CS_SIZE	    ;COIN SELECT VALUE FOR GERMAN 1
*
*	GERMAN 2    COINAGE IS 7 PLAYS FOR 5 DM
*			 2 TO START, 1 TO CONTINUE
*
	.WORD	6,12,30,0,5,30,0,2,1		;WILLY PRICING
	.WORD	1				;DMS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,2,5,0			 ;COIN VALUE
	.LONG	NULL_ST,DM_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	GERMAN_2			 ;TITLE OF COIN MODE
	.LONG	DM_7			  ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	GERMAN_15			;1 DM / 5 DM
*
*	GERMAN 3    COINAGE IS 8 PLAYS FOR 5 DM
*			 2 TO START, 1 TO CONTINUE
*
	.WORD	7,14,35,0,5,35,0,2,1		;WILLY PRICING
	.WORD	1				;DMS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,2,5,0			 ;COIN VALUE
	.LONG	NULL_ST,DM_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	GERMAN_3			 ;TITLE OF COIN MODE
	.LONG	DM_8			  ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	GERMAN_15			;1 DM / 5 DM
*
*	GERMAN 4    COINAGE IS 5 PLAYS FOR 5 DM
*			 2 TO START, 1 TO CONTINUE
*
	.WORD	1,2,5,0,1,0,0,2,1	   ;WILLY PRICING
	.WORD	1				;DMS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,2,5,0			 ;COIN VALUE
	.LONG	NULL_ST,DM_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	GERMAN_4			 ;TITLE OF COIN MODE
	.LONG	DM_5			  ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	GERMAN_15			;1 DM / 5 DM

*
*	GERMAN 5    COINAGE IS 6 PLAYS FOR 5 DM
*			 2 TO START, 1 TO CONTINUE
*
	.WORD	6,12,30,0,5,0,0,2,1	 ;WILLY PRICING
	.WORD	1		   	 ;DMS HAVE NO FRACTIONS
	.WORD	0			 ;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,2,5,0			 ;COIN VALUE
	.LONG	NULL_ST,DM_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	GERMAN_5			 ;TITLE OF COIN MODE
	.LONG	DM_6			  ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	GERMAN_15			;1 DM / 5 DM

*
*	GERMAN ELECTRONIC
*			 2 TO START, 2 TO CONTINUE
*
	.WORD	60,12,24,0,10,0,0,2,2	; L,C,R,4,U/C,U/B,MINUNITS
	.WORD	1			; COINS/DOLLAR
	.WORD	0			; DISPLAY FRACTIONS
	.WORD	5,1,2,0			; L,C,R,4
	.LONG	NULL_ST,DM_TRAIL	;CHARACTER STRINGS.
	.LONG	GERMAN_ELECTRONIC	; SPECIAL MESSAGE
	.LONG	GERMAN_ELECTITLE	; TITLE OF COIN MODE
	.LONG	DM112265		; SETTINGS DESCRIPTION
	.WORD	SHOW_3			; LINES TO SHOW ON
	.LONG	GERMAN_ESLOT		; QUARTER

****************************************************************************
****************************************************************************
*******	THE FOLLOWING NUMBERS ARE FIGURED FOR THE FRENCH SETTINGS
*******	REQUESTED BY DIMITRI K. OF P.S.D.
*******
*******			 	1F   5F   10F   U/C   U/B  M/U
*******				--------------------------------
*******	1/2F  3/5F    7/10F	3	15	 30	  5	  30    0
*******	1/3F  2/5F    5/10F	2	10	 20	  5	  20    0
*******	1/5F  3/10F		1	 5	 10    5    10    0
*******	1/5F  3/10F   7/20F	3	15	 30	 10	  60   15
*******	2/5F  4/10F   9/20F	2	10	 20	  5	  40   10
*******	2/5F  5/10F  11/20F	1	 5	 10	  2	  20    5
*******
*
*
*	FRENCH 1	      2/5F	 5/10F
*
*
	.WORD	2,0,4,0,1,4,0,2,2		; 2/5F    5/10F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST			;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_1			;TITLE OF COIN MODE
	.LONG	FIVE_10				;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	FRENCH510

F1SEL	EQU	($-CSELCT)/CS_SIZE	    ;COIN SELECT VALUE FOR FRENCH 1

*
*	FRENCH 2	      2/5F	 4/10F
*
*
	.WORD	2,0,4,0,1,0,0,2,1	   ; 2/5F    4/10F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_2			 ;TITLE OF COIN MODE
	.LONG	FOUR_10			;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	FRENCH510
*
*	FRENCH 3	      1/5F  3/10F	
*
*
	.WORD	1,0,2,0,1,2,0,2,1	    ;1/5F  3/10F	
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_3			 ;TITLE OF COIN MODE
	.LONG	THREE_10			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2
	.LONG	FRENCH510
*
*	FRENCH 4	      1/5F  2/10F 
*
*
	.WORD	1,0,2,0,1,0,0,2,1	 ;1/5F  2/10F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_4			 ;TITLE OF COIN MODE
	.LONG	TWO_10			;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_1
	.LONG	FRENCH510

	.IF	FULLPRICE

*
*
*	FRENCH 5	      2/5F	 5/10F	11/2 X 10F
*
*
	.WORD	5,0,10,0,2,20,0,2,1		 ;2/5F  5/10F	11/20F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_5			 ;TITLE OF COIN MODE
	.LONG	FIVE_10_11		    ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 3 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH510
*
*	FRENCH 6	      2/5F	 4/10F	9/2 X 10F
*
*
	.WORD	2,0,4,0,1,8,0,2,1		   ;2/5F	4/10F   9/20F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_6			 ;TITLE OF COIN MODE
	.LONG	FOUR_10_9			;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 3 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH510
*
*	FRENCH 7	      1/5F	 3/10F	7/2 X 10F
*
*
	.WORD	3,0,6,0,2,12,0,2,1		  ;1/5F  3/10F   7/20F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_7			 ;TITLE OF COIN MODE
	.LONG	THREE_10_7		    ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 3 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH510
*
*	FRENCH 8	      1/5F	 2/10F	5/2 X 10F
*
*
	.WORD	1,0,2,0,1,4,0,2,1		   ;1/5F	2/10F  5/20F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_8			 ;TITLE OF COIN MODE
	.LONG	TWO_10_5			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 3 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH510

*
*	FRENCH 9	      1/3 X 1F	  2/5F
*
*	COIN SLOTS ARE	1F -- 5F
*
*
	.WORD	2,0,10,0,5,0,0,2,1		  ;1/3x1F  2/5F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_9			 ;TITLE OF COIN MODE
	.LONG	F1325			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			;USE LINE 2 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH1F5F
*
*	FRENCH 10	      1/2 X 1F	  3/5F
*
*	COIN SLOTS ARE	1F -- 5F
*
*
	.WORD	3,0,15,0,5,0,0,2,1		  ;1/2x1F  3/5F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_10			;TITLE OF COIN MODE
	.LONG	F1235			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_2			;USE LINE 2 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH1F5F
*
*	FRENCH 11	      1/3 X 1F	  2/5F	5/2 X 5F
*
*	COIN SLOTS ARE	1F -- 5F
*
*
	.WORD	2,0,10,0,5,20,0,2,1		 ;1/3x1F	2/5F  5/10F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_11			;TITLE OF COIN MODE
	.LONG	F13255			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 2 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH1F5F

*
*	FRENCH 12	      1/2 X 1F	  3/5F	  7 / 2 X 5F
*
*	COIN SLOTS ARE	1F -- 5F
*
*
	.WORD	3,0,15,0,5,30,0,2,1		 ;1/2x1F	3/5F  7/10F
	.WORD	1				;1 FRANC PER FRANC
	.WORD	0				;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST			 ;WAIT TILL HE SAYS "IF IT IS NOT POSSIBLE"
	.LONG	FRENCH_12			;TITLE OF COIN MODE
	.LONG	F12355			 ;1 COIN PER CREDIT (SERIES OF STRINGS)
	.WORD	SHOW_3			;USE LINE 2 WHEN ONLY 1 WILL FIT
	.LONG	FRENCH1F5F

	.ENDIF

*
*	FRANCE ELECTRONIC
*
	.WORD	1,15,6,0,3,0,0,2,2	; L,C,R,4,U/C,U/B,MINUNITS
	.WORD	1			; COINS/DOLLAR
	.WORD	0			;DON'T DISPLAY COIN FRACTIONS
	.WORD	1,10,5,0		; L,C,R,4
	.LONG	NULL_ST,FRANC_TRAIL	; CHARACTER STRINGS.
	.LONG	FRANCE_ELECTRONIC	; SPECIAL MESSAGE
	.LONG	FRENCH_ELECTITLE	; TITLE OF COIN MODE
	.LONG	F13255			;COIN PAGE DESCRIPTION
	.WORD	SHOW_3			;THREE LINES FOR THIS BABY
	.LONG	FRANCE_ESLOT		; QUARTER

*
*	CANADA    COINAGE IS 50 CENT   3/$1.00
*
	.WORD   1,0,4,0,2,4,0,2,2    ;WILLY PRICING
	.WORD	4			;4 COINS PER DOLLAR (FOR CALC)
	.WORD	1			;DISPLAY COIN FRACTIONS
	.WORD	1,0,4,0			;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	;CHARACTER STRINGS.
	.LONG	CSM_LIST		;PRINT THE 2 THE OP SEES
	.LONG   CANADA			;TITLE OF COIN MODE
	.LONG	CAN_1503D		;1 PLAY 50, 3 FOR A DOLLAR
	.WORD	SHOW_2			;SHOW LINE 2
	.LONG   CAN_QD			;QUARTER

	.IF	FULLPRICE

*	SWISS 1    COINAGE IS 6 PLAYS FOR 5 FRANC

	.WORD	6,0,30,0,5,0,0,2,2		 ;WILLY PRICING
	.WORD	1				;FRANCS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SWISS_1			;TITLE OF COIN MODE
	.LONG	SFRANC_6			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_2
	.LONG	SWISS15

*	SWISS 2    COINAGE IS 7 PLAYS FOR 5 FRANC

	.WORD	6,0,30,0,5,30,0,2,2		;WILLY PRICING
	.WORD	1				;FRANCS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SWISS_2			;TITLE OF COIN MODE
	.LONG	SFRANC_7			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_2
	.LONG	SWISS15

*	SWISS 3     COINAGE IS 8 PLAYS FOR 5 FRANC

	.WORD	7,0,35,0,5,35,0,2,2		;WILLY PRICING
	.WORD	1				;FRANCS HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	1,0,5,0				;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SWISS_3				;TITLE OF COIN MODE
	.LONG	SFRANC_8			;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_2
	.LONG	SWISS15

*	ITALY COINAGE IS 1 PLAYS FOR 500 LIRE

	.WORD	1,0,1,0,1,0,0,2,2		;WILLY PRICING
	.WORD	1				;LIRE HAVE NO FRACTIONS
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	500,0,500,0			 ;COIN VALUE
	.LONG	NULL_ST,LIRE_TRAIL		 ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	ITALY_1			;TITLE OF COIN MODE
	.LONG	P1500L			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	ITALYLIRE

*	U.K. 1	 COINAGE IS 1 PLAY FOR 20P   3 FOR 50P

	.WORD	6,0,15,0,5,0,0,2,2	;WILLY PRICING
	.WORD	10			;PENCE ARE FRACTIONS!
	.WORD	0			;DON'T DISPLAY COIN FRACTIO
	.WORD	2,0,5,0			;COIN VALUE
	.LONG	NULL_ST,POUND_TRAIL	;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	UK_1			;TITLE OF COIN MODE
	.LONG	UK_120			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	UK2050

*	U.K. 2	 COINAGE IS 2 PLAY FOR 20P   5 FOR 50P

	.WORD	2,0,5,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	10			    ;PENCE ARE FRACTIONS!
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	2,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,POUND_TRAIL	;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	UK_2			  ;TITLE OF COIN MODE
	.LONG	UK_220			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	UK2050

*	U.K. ELECTRONIC 1

*	CENTER = 20P  XTRA = 10P  LEFT = 1P  RIGHT = 50P
*	1 PLAY / 30 P
*	2 PLAY / 50 P
*	4 PLAY / 1 POUND

*		 L, C,	R, 4,U/C,U/B,MINUNITS
	.WORD	28, 4, 12, 2,  4,  0,0,2,2		;NUMBERS FOR 1L/20p/50p/10p
	.WORD	10					;PENCE SUCK!
	.WORD	0					;DON'T DISPLAY COIN FRACTIO
	.WORD	10,2,5,1				;COIN VALUE
	.LONG	NULL_ST,POUND_TRAIL	;CHARACTER STRINGS.
	.LONG	UK_ELECTRONIC				;SPECIAL TITLE W/ POUND
	.LONG	UK_3					;TITLE OF COIN MODE
	.LONG	UK_420					;.5/10p 1/20p	3/50p  7/1L
	.WORD	SHOW_2
	.LONG	UK_ELEC

*	U.K. ELECTRONIC 2  (CCU)

*	CREDITS ARE AWARDED 1 COIN / 1 PLAY.....

*	CCU ACCUMULATES 4 COINS AND STROKES US AS FOLLOWS:

*	1 PLAY / 30 P
*	2 PLAY / 50 P
*	4 PLAY / 1 POUND

	.WORD	1,0,0,0,1,0,0,2,2		   ;NUMBERS FOR
	.WORD	1				;PENCE ARE FRACTIONS!
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	1,0,0,0			 ;COIN VALUE
	.LONG	NULL_ST,COINS_TRAIL	   ;CHARACTER STRINGS.
	.LONG	UK_ELECTRONIC		 ;SPECIAL TITLE W/ POUND
	.LONG	UK_4			  ;TITLE OF COIN MODE
	.LONG	UK_320			;1/30P  2/50P	4/1L
	.WORD	SHOW_2
	.LONG	UK_CCU

*GNP START 7/16/92
*	DONE BECAUSE WE LEARNED SOME NEW SPANISH SHIT!

*	SPAIN 1     1 play / 100 Peseta   6 play / 500 Peseta

	.WORD	1,0,5,0,1,5,0,2,2		;WILLY PRICING
	.WORD	1				;no fractions
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	100,0,500,0			;COIN VALUE
	.LONG	NULL_ST,PESETA_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SP_1				;TITLE OF COIN MODE
	.LONG	SP_5100				;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	PESETA100


*	SPAIN 2     1 play / 25 Peseta   5 play / 100 Peseta

	.WORD	1,0,5,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;no fractions
	.WORD	0				;DON'T DISPLAY COIN FRACTIO
	.WORD	100,0,500,0			 ;COIN VALUE
	.LONG	NULL_ST,PESETA_TRAIL	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SP_2			  ;TITLE OF COIN MODE
	.LONG	SP_4100			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	PESETA100

*GNP END

*	AUSTRALIA 1   1 play / 3 X 20 CENTS	2 FOR $1.00

	.WORD	2,0,10,0,5,0,0,2,2		  ;WILLY PRICING
	.WORD	5				;DOLLARS
	.WORD	0				;DON'T SHOW FRACTIONS FOR T
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	AUS_1			 ;TITLE OF COIN MODE
	.LONG	AU_60			 ;1 COIN PER CREDIT (SERIES OF S
	.WORD	SHOW_2
	.LONG	AUST20C
*
*	AUSTRALIA 2   1 play / $1.00    2 plays for $2.00
*
	.WORD	1,0,5,0,5,0,0,1,1	 ; WILLY PRICING
	.WORD	5			 ; DOLLARS
	.WORD	1			 ; SHOW FRACTIONS FOR THE 3 C
	.WORD	1,0,5,0			 ; COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	 ; CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	AUS_2			 ; TITLE OF COIN MODE
	.LONG	AU_100			 ; 1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	AUST20C

	.ENDIF

*	JAPAN 1  1 play / 100 yen

	.WORD	1,1,1,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	100,100,100,0		   ;COIN VALUE
	.LONG	NULL_ST,YEN_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	JAP_1			 ;TITLE OF COIN MODE
	.LONG	JAP_100			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	YEN100

	.IF	FULLPRICE
*	JAPAN 2  2 play / 100 yen

	.WORD	2,2,2,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	100,100,100,0		   ;COIN VALUE
	.LONG	NULL_ST,YEN_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	JAP_2			 ;TITLE OF COIN MODE
	.LONG	JAP_200			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	YEN100

*	AUSTRIA  1   1 Play / 5 Schilling  2 Play / 10 Schilling

	.WORD	1,0,2,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,SHILL_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	ASTA_1			 ;TITLE OF COIN MODE
	.LONG	ASTA_15			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	SHILL510

*	AUSTRIA  2   1 Play / 2 X 5 Schilling	3 Play / 10 Schilling

	.WORD	1,0,2,0,2,4,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	5,0,10,0			;COIN VALUE
	.LONG	NULL_ST,SHILL_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	ASTA_2			 ;TITLE OF COIN MODE
	.LONG	ASTA_10			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	SHILL510

*	BELGIUM 1  1 play / 20F

	.WORD	1,0,1,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	20,0,20,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	BEL_1			 ;TITLE OF COIN MODE
	.LONG	BEL_120			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	FRANC20

*	BELGIUM 2  3 play / 20F

	.WORD	3,0,3,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	20,0,20,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	BEL_2			 ;TITLE OF COIN MODE
	.LONG	BEL_320			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	FRANC20

*	BELGIUM 3  2 play / 20F

	.WORD	2,0,2,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	1				;FRACTIONS OK
	.WORD	20,0,20,0			 ;COIN VALUE
	.LONG	NULL_ST,FRANC_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	BEL_3			 ;TITLE OF COIN MODE
	.LONG	BEL_220			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	FRANC20

*
*	BELGIUM ELECTRONIC
*
	.WORD	10,1,4,0,4,0,0,2,2		; L,C,R,4,U/C,U/B,MINUNITS
	.WORD	1			; COINS/DOLLAR
	.WORD	1			; DISPLAY FRACTIONS
	.WORD	50,5,20,0		; L,C,R,4
	.LONG	NULL_ST,FRANC_TRAIL		 ;CHARACTER STRINGS.
	.LONG	BELGIUM_ELECTRONIC		; SPECIAL MESSAGE
	.LONG	BELGIUM_ELECTITLE		; TITLE OF COIN MODE
	.LONG	BEL_ELEC			; SETTINGS DESCRIPTION
	.WORD	SHOW_2			; LINES TO SHOW ON
	.LONG	BELGIUM_ESLOT		; QUARTER

*	SWEDEN	1 play / 3 X 1 KRONA   2 PLAY	5 KRONA

	.WORD	2,0,10,0,5,0,0,2,2		 ;WILLY PRICING
	.WORD	1				;DOLLARS
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,KRONA_TRAIL	   ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	SWED_1			;TITLE OF COIN MODE
	.LONG	SWED_2X5			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_1
	.LONG	KRONA5

*	NEW ZEALAND 1	1 play / 3 X 20 CENT

	.WORD	1,0,1,0,3,0,0,1,1		   ;WILLY PRICING
	.WORD	5				;FIVE PER
	.WORD	1				;SHOW FRACTIONS
	.WORD	1,0,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	NZ_1			  ;TITLE OF COIN MODE
	.LONG	NZ_13			 ;1 COIN PER CREDIT (SERIES OF S
	.WORD	SHOW_1
	.LONG	NZ20


*	NEW ZEALAND 2	1 play / 2 X 20 CENT

	.WORD	1,0,1,0,2,0,0,1,1		   ;WILLY PRICING
	.WORD	5				;FIVE PER
	.WORD	1				;SHOW FRACTIONS
	.WORD	1,0,1,0			 ;COIN VALUE
	.LONG	DOLLAR_LEAD,NULL_ST	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	NZ_2			  ;TITLE OF COIN MODE
	.LONG	NZ_12			 ;1 COIN PER CREDIT (SERIES OF S
	.WORD	SHOW_1
	.LONG	NZ20

*	NETHERLANDS	1 PLAY / 1 HFL.	3 PLAY / 2.5 HFL.

	.WORD	1,0,3,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;FIVE PER
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,2,0			 ;COIN VALUE
	.LONG	NULL_ST,HFL_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	NETH			  ;TITLE OF COIN MODE
	.LONG	NETH_HF			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_2
	.LONG	HFSLOT


*	FINLAND	1 PLAY / 1 MARKKA

	.WORD	1,0,1,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;FIVE PER
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,1,0			 ;COIN VALUE
	.LONG	NULL_ST,MARKKA_TRAIL	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	FINLAND			;TITLE OF COIN MODE
	.LONG	FINMKA			;1 COIN PER CREDIT (SERIES OF ST
	.WORD	SHOW_1
	.LONG	MKSLOT

*	NORWAY	1 PLAY / 2 X 1 KRONE    3/ 5 X 1 KRONE

	.WORD	3,0,3,0,5,0,0,2,2		   ;WILLY PRICING
	.WORD	1				;FIVE PER
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,1,0			 ;COIN VALUE
	.LONG	NULL_ST,KRONE_TRAIL	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	NORWAY			;TITLE OF COIN MODE
	.LONG	KR_LIST			 ;1 COIN PER CREDIT (SERIES OF STRI
	.WORD	SHOW_2
	.LONG	NKRSLOT

*	DENMARK	1 PLAY / 2 X 1 KRONE    3/ 5 KRONE	  7 / 10 KRONE

	.WORD	3,0,15,0,5,30,0,2,2		 ;WILLY PRICING
	.WORD	1				;FIVE PER
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,5,0			 ;COIN VALUE
	.LONG	NULL_ST,KRONE_TRAIL	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	DENMARK			;TITLE OF COIN MODE
	.LONG	DKR_LIST			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_3
	.LONG	DKRSLOT


*	ANTILLES      1 PLAY / 25 CENTS	4 PLAYS / 1 GUILDER

	.WORD	1,0,4,0,1,0,0,2,2		   ;WILLY PRICING
	.WORD	4				;FIVE PER
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	1,0,4,0			 ;COIN VALUE
	.LONG	NULL_ST,GUILDER_TRAIL	  ;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	ANTILLES			 ;TITLE OF COIN MODE
	.LONG	ANT_LIST			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_1
	.LONG	ANTSLOT

*GNP START 7/16/92, ADDED HUNGARY
*	HUNGARY     1 CREDIT / 2x10 FORINT  3 CREDITS / 2x20 FORINT

	.WORD	1,0,2,0,2,4,0,2,2		;WILLY PRICING
	.WORD	1				;1 TO 1
	.WORD	0				;DON'T SHOW FRACTIONS
	.WORD	10,0,20,0			;COIN VALUE
	.LONG	NULL_ST,FORINT_TRAIL		;CHARACTER STRINGS.
	.LONG	CSM_LIST
	.LONG	HUNGARY				;TITLE OF COIN MODE
	.LONG	HUNG_LIST			 ;1 COIN PER CREDIT (SERIES
	.WORD	SHOW_1
	.LONG	HUNGSLOT

*GNP END 
	.ENDIF

CS_ENTS	EQU	($-CSELCT)/CS_SIZE	    ;NUMBER OF ENTRIES IN TABLE


;
;	DIP SWITCH TABLES
;

USABASE	EQU	1
GERBASE	EQU	G1SEL
FRABASE	EQU	F1SEL

	.IF	FULLPRICE

USADIP	.WORD	USABASE+0, USABASE+1, USABASE+2, USABASE+3, USABASE+8
	.WORD	USABASE+8, USABASE+8

GERDIP	.WORD	GERBASE+0, GERBASE+1, GERBASE+2, GERBASE+3, GERBASE+4
	.WORD	GERBASE+4, GERBASE+4

FRADIP	.WORD	FRABASE+0, FRABASE+1, FRABASE+2, FRABASE+3, FRABASE+12
	.WORD	FRABASE+12, FRABASE+12

	.ELSE

USADIP	.WORD	USABASE+0, USABASE+1, USABASE+2, USABASE+3, USABASE+4
	.WORD	USABASE+4, USABASE+4

GERDIP	.WORD	GERBASE+0, GERBASE+1, GERBASE+2, GERBASE+3, GERBASE+4
	.WORD	GERBASE+4, GERBASE+4

FRADIP	.WORD	FRABASE+0, FRABASE+1, FRABASE+2, FRABASE+3, FRABASE+4
	.WORD	FRABASE+4, FRABASE+4

	.ENDIF


DIPCOINTAB	.LONG	USADIP, GERDIP, FRADIP, USADIP


**************************************************************************
*									*
*	 COLLECTION MESSAGES					  *
*									*
**************************************************************************
ME_ZERO	 .STRING "0"
	.BYTE	0
	.EVEN

ME_DASH		.string	"-",0
	.even

ME_DECIMAL	.STRING "."
	.BYTE	0
	.EVEN

ME_COLON .STRING ":"
	.BYTE	0
	.EVEN

DOLLAR_LEAD	.STRING "$  "
	.BYTE	0
	.EVEN

POUND_LEAD
	.STRING FONT_EPOUND,"  ",0
	.EVEN
POUND_TRAIL
	.STRING	"  PND",0
	.EVEN

NULL_ST	
	.BYTE	0
	.EVEN

DM_TRAIL	.STRING "  DM"
	.BYTE	0
	.EVEN

FRANC_TRAIL	.STRING "  FRANC"
	.BYTE	0
	.EVEN
	
	.IF	FULLPRICE
LIRE_TRAIL	.STRING "  LIRE"
	.BYTE	0
	.EVEN

PESETA_TRAIL	.STRING "  PESETA"
	.BYTE	0
	.EVEN
	.ENDIF

YEN_TRAIL
	.STRING "  YEN"
	.BYTE	0
	.EVEN

	.IF	FULLPRICE
SHILL_TRAIL
	.STRING "  SCHILLINGS"
	.BYTE	0
	.EVEN

KRONA_TRAIL
	.STRING "  KRONA"
	.BYTE	0
	.EVEN
	.ENDIF

COINS_TRAIL
	.STRING "  COINS"
	.BYTE	0
	.EVEN

	.IF	FULLPRICE
HFL_TRAIL
	.STRING "  HFI."
	.BYTE	0
	.EVEN

MARKKA_TRAIL
	.STRING "  MARKKA"
	.BYTE	0
	.EVEN

KRONE_TRAIL
	.STRING "  KRONE"
	.BYTE 0
	.EVEN

GUILDER_TRAIL
	.STRING "  GUILDER"
	.BYTE 0
	.EVEN

FORINT_TRAIL
	.STRING	"  FT",0
	.ENDIF

*
*	FOR THE COINAGE ADJUSTMENT MODE:
*
*
*	THIS SET IS TITLES FOR THE CANNED MODES.
*
USA_1	.STRING "USA 1",0
	.EVEN
USA_2	.STRING "USA 2",0
	.EVEN
USA_3	.STRING "USA 3",0
	.EVEN
USA_4	.STRING "USA 4",0
	.EVEN

	.IF	FULLPRICE
USA_5	.STRING "USA 5",0
	.EVEN
USA_6	.STRING "USA 6",0
	.EVEN
USA_7	.STRING "USA 7",0
	.EVEN
USA_8	.STRING "USA 8",0
	.EVEN
	.ENDIF

USA_ELECTITLE
	.STRING	"USA ECA",0
	.EVEN

FRENCH_ELECTITLE
	.STRING	"FRANCE ECA",0
	.EVEN

GERMAN_ELECTITLE
	.STRING	"GERMAN ECA",0
	.EVEN


GERMAN_1 .STRING "GERMAN 1",0
	.EVEN
GERMAN_2 .STRING "GERMAN 2",0
	.EVEN
GERMAN_3 .STRING "GERMAN 3",0
	.EVEN
GERMAN_4 .STRING "GERMAN 4",0
	.EVEN
GERMAN_5 .STRING "GERMAN 5",0
	.EVEN

FRENCH_1 .STRING "FRANCE 1",0
	.EVEN
FRENCH_2 .STRING "FRANCE 2",0
	.EVEN
FRENCH_3 .STRING "FRANCE 3",0
	.EVEN
FRENCH_4 .STRING "FRANCE 4",0
	.EVEN

	.IF	FULLPRICE
FRENCH_5 .STRING "FRANCE 5",0
	.EVEN
FRENCH_6 .STRING "FRANCE 6",0
	.EVEN
FRENCH_7 .STRING "FRANCE 7",0
	.EVEN
FRENCH_8 .STRING "FRANCE 8",0
	.EVEN
FRENCH_9 .STRING "FRANCE 9",0
	.EVEN
FRENCH_10 .STRING "FRANCE 10",0
	.EVEN
FRENCH_11 .STRING "FRANCE 11",0
	.EVEN
FRENCH_12 .STRING "FRANCE 12",0
	.EVEN

CANADA
	.STRING	"CANADA",0
	.EVEN

SWISS_1 .STRING "SWISS 1"
	.BYTE	0
	.EVEN
SWISS_2 .STRING "SWISS 2"
	.BYTE	0
	.EVEN
SWISS_3 .STRING "SWISS 3"
	.BYTE	0
	.EVEN
ITALY_1 .STRING "ITALY"
	.BYTE	0
	.EVEN
UK_1	.STRING "U.K. 1"
	.BYTE	0
	.EVEN
UK_2	.STRING "U.K. 2"
	.BYTE	0
	.EVEN
UK_3	.STRING "U.K. ECA"
	.BYTE	0
	.EVEN
UK_4	.STRING "U.K. ELEC W/CCU"
	.BYTE	0
	.EVEN
SP_1	.STRING "SPAIN 1"
	.BYTE	0
	.EVEN
SP_2	.STRING "SPAIN 2"
	.BYTE	0
	.EVEN
AUS_1	.STRING "AUSTRALIA 1"
	.BYTE	0
	.EVEN
AUS_2	.STRING "AUSTRALIA 2"
	.BYTE	0
	.EVEN
	.ENDIF

JAP_1	.STRING "JAPAN 1"
	.BYTE	0
	.EVEN

	.IF	FULLPRICE
JAP_2	.STRING "JAPAN 2"
	.BYTE	0
	.EVEN
ASTA_1	.STRING "AUSTRIA 1"
	.BYTE	0
	.EVEN
ASTA_2	.STRING "AUSTRIA 2"
	.BYTE	0
	.EVEN
BEL_1	.STRING "BELGIUM 1"
	.BYTE	0
	.EVEN
BEL_2	.STRING "BELGIUM 2"
	.BYTE	0
	.EVEN
BEL_3	.STRING "BELGIUM 3"
	.BYTE	0
	.EVEN
BELGIUM_ELECTITLE
	.STRING	"BELGIUM ECA",0
	.EVEN
SWED_1	.STRING "SWEDEN"
	.BYTE	0
	.EVEN
NZ_1	.STRING "NEW ZEALAND 1"
	.BYTE	0
	.EVEN
NZ_2	.STRING "NEW ZEALAND 2"
	.BYTE	0
	.EVEN
NETH	.STRING "NETHERLANDS"
	.BYTE	0
	.EVEN

FINLAND	.STRING "FINLAND"
	.BYTE 0
	.EVEN

NORWAY	.STRING "NORWAY"
	.BYTE 0
	.EVEN

DENMARK	.STRING "DENMARK"
	.BYTE 0
	.EVEN

ANTILLES .STRING "ANTILLES"
	.BYTE 0
	.EVEN

HUNGARY
	.STRING "HUNGARY",0
	.EVEN

	.ENDIF
*
*	THIS SECTION IS A POINTER TO STRING LISTS
*	FOR THE "CURRENT SETTING" BOX.
*
USA_EL
	.LONG	EC1
	.LONG	DOLL4
	.LONG	0
*
*	1 COIN / 1 CREDIT
Q_Q
	.LONG	C11		 ;THIS POINTS AT MESSAGE
	.LONG	0		   ;THIS ENDS LIST
*
*	2 COINS / 1 CREDIT
*
F_F_1S1C
	.LONG	C21
	.LONG	0

*************************************************************************


*
*	2 COINS / 1 CREDIT
*	4 COINS / 3 CREDITS
*
DOLLAR_3 .LONG	C21
	.LONG	C43
	.LONG	0
*
*	2 COINS / 1 CREDIT
*	4 COINS / 4 CREDITS
*
DOLLAR_4 .LONG	C21
	.LONG	C44
	.LONG	0


********************************************************************


	.IF	FULLPRICE

U1Q4D	.LONG	C11		 ;THIS POINTS AT MESSAGE
	.LONG	DOLL4		;4 FOR A DOLLAR
	.LONG	0

;UFS2D	.LONG	C21		; THIS POINTS AT MESSAGE
;	.LONG	DOLL2		; 2 FOR A DOLLAR
;	.LONG	0

UFS3D	.LONG	C21		 ;THIS POINTS AT MESSAGE
	.LONG	DOLL3		;3 FOR A DOLLAR
	.LONG	0

UFS4D	.LONG	C21		 ;THIS POINTS AT MESSAGE
	.LONG	DOLL4		;4 FOR A DOLLAR
	.LONG	0

	.ENDIF

*
*	1 PLAY 1/DM
*	5 PLAY 5/DM
*
DM_5	.LONG	DM11
	.LONG	DM55
	.LONG	0

DM_6	.LONG	DM11
	.LONG	DM65
	.LONG	0

DM_7	.LONG	DM11
	.LONG	DM75
	.LONG	0

DM_8	.LONG	DM11
	.LONG	DM85
	.LONG	0

DM112265
	.LONG	DM11
	.LONG	DM22
	.LONG	DM65
	.LONG	0

SFRANC_6     .LONG   SFRANC11
	.LONG	SFRANC65
	.LONG	0

CAN_1503D
	.LONG   C15		;THIS POINTS AT MESSAGE
	.LONG   DOLL3		;3 FOR A DOLLAR
	.LONG   0

SFRANC_7     .LONG   SFRANC11
	.LONG	SFRANC75
	.LONG	0

SFRANC_8     .LONG   SFRANC11
	.LONG	SFRANC85
	.LONG	0
*
*	2 PLAYS 5F / 5 PLAYS 10F
*
FIVE_10	.LONG	F25
	.LONG	F510
	.LONG	0

FIVE_10_11
	.LONG	F25
	.LONG	F510
	.LONG	F1120
	.LONG	0

FOUR_10	.LONG	F25
	.LONG	F410
	.LONG	0

FOUR_10_9
	.LONG	F25
	.LONG	F410
	.LONG	F4109
	.LONG	0

THREE_10 .LONG	F15
	.LONG	F310
	.LONG	0

THREE_10_7
	.LONG	F15
	.LONG	F310
	.LONG	F4107
	.LONG	0

TWO_10	.LONG	F15
	.LONG	F210
	.LONG	0

TWO_10_5 .LONG	F15
	.LONG	F210
	.LONG	F4105
	.LONG	0

F1325	.LONG	F3X1F
	.LONG	F2F5
	.LONG	0

F13255	.LONG	F3X1F
	.LONG	F2F5
	.LONG	F52X5
	.LONG	0

F1235	.LONG	F2X1F
	.LONG	F3F5
	.LONG	0

F12355	.LONG	F2X1F
	.LONG	F3F5
	.LONG	F72X5
	.LONG	0

	.IF	FULLPRICE

*	500 LIRE

P1500L	.LONG	P1500L_P
	.LONG	0

*	1 PLAY / 20 P	 3 PLAYS 50 P

UK_120	.LONG	UK_1201
	.LONG	UK_1202
	.LONG	0

UK_220	.LONG	UK_2201
	.LONG	UK_2202
	.LONG	0

UK_320	.LONG	UK_3201
	.LONG	UK_3202
	.LONG	UK_3203
	.LONG	0

UK_420	.LONG	UK_4201
	.LONG	UK_4202
	.LONG	UK_4203
	.LONG	0

SP_4100	.LONG	SP_11
	.LONG	SP_44
	.LONG	0

SP_5100	.LONG	SP_11
	.LONG	SP_54
	.LONG	0

AU_60	.LONG	AU_36
	.LONG	AU_2D
	.LONG	0

AU_100	.LONG	AU_520
	.LONG	AU_1D
	.LONG	0

	.ENDIF

JAP_100	.LONG	JAP_101
	.LONG	0

	.IF	FULLPRICE

JAP_200	.LONG	JAP_201
	.LONG	0

ASTA_10	.LONG	ASTA101
	.LONG	ASTA102
	.LONG	0

ASTA_15	.LONG	ASTA151
	.LONG	ASTA152
	.LONG	0

BEL_120	.LONG	BEL_1201
	.LONG	0
BEL_220	.LONG	BEL_2201
	.LONG	0
BEL_320	.LONG	BEL_3201
	.LONG	0
BEL_ELEC
	.LONG	BEL_1201
	.LONG	0

SWED_2X5 .LONG	SWED_S51
	.LONG	SWED_S52
	.LONG	0

NZ_12	.LONG	NZ_121
	.LONG	0

NZ_13	.LONG	NZ_131
	.LONG	0

NETH_HF	.LONG	HF_11
	.LONG	HF_32
	.LONG	0

FINMKA	.LONG	FIN_1
	.LONG	0

KR_LIST	.LONG	NOR_12
	.LONG	NOR_35
	.LONG	0

DKR_LIST .LONG	DEN_12
	.LONG	DEN_35
	.LONG	DEN_710
	.LONG	0

ANT_LIST .LONG	ANT1P25
	.LONG	ANT4DOL
	.LONG	0

HUNG_LIST
	.LONG	HUNG2X10
	.LONG	HUNG2X20
	.LONG	0

	.ENDIF

EC1	.STRING	"1 CREDIT / 25 CENTS",0
	.EVEN
C11	.STRING  "1 CREDIT / 1 COIN"
	.BYTE 0
	.EVEN
C21	.STRING  "1 CREDIT / 2 COINS"
	.BYTE 0
	.EVEN
C43	.STRING  "3 CREDIT / 4 COINS"
	.BYTE 0
	.EVEN
C44	.STRING  "4 CREDITS / 4 COINS"
	.BYTE 0
	.EVEN
C15
	.STRING	"1 CREDIT / 2 X 25 CENTS",0
	.EVEN

DOLL2	.STRING  "2 CREDITS / $1.00"
	.BYTE 0
	.EVEN

DOLL3	.STRING  "3 CREDITS / $1.00"
	.BYTE 0
	.EVEN

DOLL4	.STRING  "4 CREDITS / $1.00"
	.BYTE 0
	.EVEN

DM11	.STRING  "1 CREDIT / 1 DM",0
	.EVEN
DM22	.STRING  "2 CREDITS / 2 DM",0
	.EVEN
DM55	.STRING  "5 CREDITS / 5 DM",0
	.EVEN
DM65	.STRING  "6 CREDITS / 5 DM",0
	.EVEN
DM75	.STRING  "7 CREDITS / 5 DM",0
	.EVEN
DM85	.STRING  "8 CREDITS / 5 DM",0
	.EVEN

F3F5	.STRING  "3 CREDITS / 5F"
	.BYTE 0
	.EVEN
F2F5
F25	.STRING  "2 CREDITS / 5F"
	.BYTE 0
	.EVEN
F15	.STRING  "1 CREDIT / 5F"
	.BYTE 0
	.EVEN
F510	.STRING  "5 CREDITS / 10F"
	.BYTE 0
	.EVEN
F1120	.STRING  "11 CREDITS / 2 X 10F"
	.BYTE 0
	.EVEN
F4109	.STRING  "9 CREDITS / 2 X 10F"
	.BYTE 0
	.EVEN
F4107	.STRING  "7 CREDITS / 2 X 10F"
	.BYTE 0
	.EVEN
F4105	.STRING  "5 CREDITS / 2 X 10F"
	.BYTE 0
	.EVEN
F410	.STRING  "4 CREDITS / 10F"
	.BYTE 0
	.EVEN
F310	.STRING  "3 CREDITS / 10F"
	.BYTE 0
	.EVEN
F210	.STRING  "2 CREDITS / 10F"
	.BYTE 0
	.EVEN

F3X1F	.STRING  "1 CREDIT / 3 X 1F"
	.BYTE	0
	.EVEN

F2X1F	.STRING  "1 CREDIT / 2 X 1F"
	.BYTE	0
	.EVEN

F52X5	.STRING  "5 CREDITS / 2 X 5F"
	.BYTE	0
	.EVEN

F72X5	.STRING  "7 CREDITS / 2 X 5F"
	.BYTE	0
	.EVEN

SFRANC11     .STRING  "1 CREDIT / 1F"
	.BYTE 0
	.EVEN
SFRANC65     .STRING  "6 CREDITS / 5F"
	.BYTE 0
	.EVEN
SFRANC75     .STRING  "7 CREDITS / 5F"
	.BYTE 0
	.EVEN
SFRANC85     .STRING  "8 CREDITS / 5F"
	.BYTE 0
	.EVEN

	.IF	FULLPRICE
P1500L_P .STRING      "1 CREDIT / 500 LIRE"
	.BYTE 0
	.EVEN

UK_1201	.STRING	"1 CREDIT / 20 P"
	.BYTE 0
	.EVEN
UK_1202	.STRING	"3 CREDITS / 50 P"
	.BYTE 0
	.EVEN

UK_2201	.STRING	"2 CREDITS / 20 P"
	.BYTE 0
	.EVEN
UK_2202	.STRING	"5 CREDITS / 50 P"
	.BYTE 0
	.EVEN

UK_3201	.STRING	"1 CREDIT / 30 P"
	.BYTE 0
	.EVEN
UK_3202	.STRING	"2 CREDITS / 50 P"
	.BYTE 0
	.EVEN
UK_3203	.STRING	"4 CREDITS / L1.00"
	.BYTE 0
	.EVEN

UK_4201	.STRING	"1 CREDIT / 20 P"
	.BYTE 0
	.EVEN
UK_4202	.STRING	"3 CREDITS / 50 P"
	.BYTE 0
	.EVEN
UK_4203	.STRING	"7 CREDITS / L1.00"
	.BYTE 0
	.EVEN

SP_11	.STRING	"1 CREDIT / 100 PESETA"
	.BYTE	0
	.EVEN

SP_44	.STRING	"5 CREDITS / 500 PESETA"
	.BYTE	0
	.EVEN

SP_54	.STRING	"6 CREDITS / 500 PESETA"
	.BYTE	0
	.EVEN
NZ_131
AU_36	.STRING	"1 CREDIT / 3 X 20 CENTS"
	.BYTE	0
	.EVEN
AU_2D	.STRING	"2 CREDITS / $ 1.00"
	.BYTE	0
	.EVEN
AU_520	.STRING	"1 CREDIT / 5 X 20 CENTS"
	.BYTE	0
	.EVEN
AU_1D	.STRING	"1 CREDIT / $ 1.00"
	.BYTE	0
	.EVEN
	.ENDIF

JAP_101	.STRING	"1 CREDIT / 100 YEN"
	.BYTE	0
	.EVEN

	.IF FULLPRICE

JAP_201	.STRING	"2 CREDITS / 100 YEN"
	.BYTE	0
	.EVEN
ASTA101	.STRING	"1 CREDIT / 2 X 5 SCHILLING"
	.BYTE	0
	.EVEN
ASTA102	.STRING	"3 CREDITS / 2 X 10 SCHILLING"
	.BYTE	0
	.EVEN
ASTA151	.STRING	"1 CREDIT / 5 SCHILLING"
	.BYTE	0
	.EVEN
ASTA152	.STRING	"2 CREDITS / 10 SCHILLING"
	.BYTE	0
	.EVEN

BEL_1201 .STRING	"1 CREDIT / 2OF"
	.BYTE	0
	.EVEN
BEL_2201 .STRING	"2 CREDITS / 2OF"
	.BYTE	0
	.EVEN
BEL_3201 .STRING	"3 CREDITS / 2OF"
	.BYTE	0
	.EVEN

SWED_S51 .STRING	"1 CREDIT / 3 X 1 KRONA"
	.BYTE	0
	.EVEN
SWED_S52 .STRING	"2 CREDITS / 5 KRONA"
	.BYTE	0
	.EVEN

NZ_121	.STRING	"1 CREDIT / 2 X 20 CENTS"
	.BYTE	0
	.EVEN

HF_11	.STRING	"1 CREDIT / 1 HFI"
	.BYTE	0
	.EVEN

HF_32	.STRING	"3 CREDITS / 2.5 HFI"
	.BYTE	0
	.EVEN

FIN_1	.STRING	"1 CREDIT / 1 MARKKA"
	.BYTE	0
	.EVEN

DEN_12
NOR_12	.STRING	"1 CREDIT / 2 X 1 KRONE"
	.BYTE 0
	.EVEN

NOR_35	.STRING	"3 CREDITS / 5 X 1 KRONE"
	.BYTE 0
	.EVEN

DEN_35	.STRING	"3 CREDITS / 5 KRONE"
	.BYTE 0
	.EVEN

DEN_710	.STRING	"7 CREDITS / 2 X 5 KRONE"
	.BYTE 0
	.EVEN

ANT1P25	.STRING	"1 CREDIT / 25 CENTS"
	.BYTE 0
	.EVEN

ANT4DOL	.STRING	"4 CREDITS / 1 GUILDER"
	.BYTE 0
	.EVEN

HUNG2X10
	.STRING	"1 CREDIT / 2 X 10 FORINT",0
	.EVEN

HUNG2X20
	.STRING	"3 CREDITS / 2 X 20 FORINT",0
	.EVEN

	.ENDIF

**************************************************************************
*									*
*	 COIN SLOT TITLES						*
*									*
**************************************************************************

USA_ESLOT	
	.STRING	"1 DOLLAR  10/25/5 CENT",0
	.EVEN

FRANCE_ESLOT
	.STRING	"1/10/5 FRANCS",0
	.EVEN

GERMAN_ESLOT
	.STRING	"5/1/2 DM",0
	.EVEN

BELGIUM_ESLOT
	.STRING	"50/5/20 FR",0
	.EVEN

USA_QQ	    .STRING   "25 CENT       25 CENT"
	    .BYTE 0
	    .EVEN

	.IF	FULLPRICE
USA_QDQ
	.STRING   "25 CENT     $1.00     25 CENT",0
	.EVEN
	.ENDIF

GERMAN_15    .STRING   "1 DM      5 DM"
	    .BYTE 0
	    .EVEN
FRENCH510    .STRING   "5 F       10 F"
	    .BYTE 0
	    .EVEN
FRENCH1F5F
	.STRING   "1 F       5 F",0
	.EVEN

CAN_QD
	.STRING	"25 CENT       $ 1.00",0
	.EVEN

	.IF	FULLPRICE
SWISS15	    .STRING   "1 F       5 F"
	    .BYTE 0
	    .EVEN
ITALYLIRE    .STRING   "500 LIRE      500 LIRE"
	    .BYTE 0
	    .EVEN
UK2050	    .STRING   "20 P      50 P"
	    .BYTE 0
	    .EVEN
UK_ELEC	    .STRING   "L1.00  20P  50P  10P"
	    .BYTE 0
	    .EVEN
UK_CCU	    .STRING   "CCU ON LEFT SLOT	   "
	    .BYTE 0
	    .EVEN
PESETA100
	.STRING   "100 PESETA     500 PESETA",0
	.EVEN
AUST20C
	.STRING   "20 CENT       $ 1.00",0
	.EVEN

	.ENDIF

YEN100	    .STRING   "100 YEN       100 YEN"
	    .BYTE 0
	    .EVEN

	.IF	FULLPRICE
SHILL510     .STRING   "5 SCHILLING   10 SCHILLING"
	    .BYTE 0
	    .EVEN
FRANC20	    .STRING   "20 F      20 F"
	    .BYTE 0
	    .EVEN
KRONA5	    .STRING   "1 KRONA       5 KRONA"
	    .BYTE 0
	    .EVEN
NZ20	.STRING   "20 CENT       20 CENT"
	    .BYTE 0
	    .EVEN
HFSLOT	    .STRING   "1 HFI     2.5 HFI"
	    .BYTE 0
	    .EVEN

MKSLOT	    .STRING   "1 MARKKA      1 MARKKA"
	    .BYTE 0
	    .EVEN

NKRSLOT	    .STRING   "1 KRONE       1 KRONE"
	    .BYTE 0
	    .EVEN

DKRSLOT	    .STRING   "1 KRONE       5 KRONE"
	    .BYTE 0
	    .EVEN

ANTSLOT	    .STRING   "25 CENTS      1 GUILDER"
	    .BYTE 0
	    .EVEN

HUNGSLOT
	.STRING	"10 FORINT     20 FORINT",0
	.EVEN

	.ENDIF

;;CP_CX	EQU	200
;;CP_11	EQU	11
;;CP_13	EQU	13
;;CP_23	EQU	23
;;CP_33	EQU	33




;TXT_2_TO_START
;	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_11,ROBO_YELLOW,STRCNRM,0
;	.byte	"2 CREDITS TO START",0,1
;	.even
;	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_23,ROBO_YELLOW,STRCNRM,0
;	.byte	"1 CREDIT TO CONTINUE",0,0
;	.even

;TWO_PER_PLAYER
;	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_11,ROBO_YELLOW,STRCNRM,0
;	.STRING   "2 COINS PER PLAYER"
;	.BYTE	  0,0
;	.EVEN

OCOP	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_11,ROBO_YELLOW,STRCNRM,0
	.STRING   "1 COIN / 1 PLAY"
	.BYTE	  0,0
	.EVEN

USA_ELECTRONIC:
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_13,ROBO_YELLOW,STRCNRM,0
	.STRING	"1 CREDIT  /  25 CENTS"	
	.STRING	"\n4 CREDITS /  1 DOLLAR",0,1
	.EVEN

FRANCE_ELECTRONIC:
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_13,ROBO_YELLOW,STRCNRM,0
	.STRING	"1 CREDIT  /  25 CENTS"	
	.STRING	"\n4 CREDITS /  1 DOLLAR",0,1
	.EVEN

GERMAN_ELECTRONIC:
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_13,ROBO_YELLOW,STRCNRM,0
	.STRING	"1 CREDIT  /  1 DM"	
	.STRING	"\n6 CREDITS /  5 DM",0,1
	.EVEN

	.IF	FULLPRICE
BELGIUM_ELECTRONIC:
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_13,ROBO_YELLOW,STRCNRM,0
	.STRING	"1 CREDIT  /  20 FR"	
	.EVEN

UK_ELECTRONIC
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_13,ROBO_YELLOW,STRCNRM,0
	.STRING   "1 CREDIT / 30 P"
	.BYTE	  0,1
	.EVEN
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_23,ROBO_YELLOW,STRCNRM,0
	.STRING   "2 CREDITS / 50 P"
	.BYTE	  0,1
	.EVEN
	MESS_MAC  RD7FONT,SPACING07,CP_CX,CP_33,ROBO_YELLOW,STRCNRM,0
	.STRING	"4 CREDITS / "
	.BYTE	  FONT_EPOUND
	.STRING	"1.00"
	.BYTE	  0,0
	.EVEN
	.ENDIF


*
*	THE FOLLOWING 2 MESSAGES ARE GENERIC AND WILL
*	BE DISPLAYED IF THE MODE MATCHES AND NO
*	APPROPRIATE MESSAGE EXISTS
*
*	THIS IS FOR THIS BEING THE ONLY MESSAGE DISPLAYED ON
*	THE SCREEN
*
TWO_TO_START
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_12,ROBO_LASER,STRCNRM,0
	.byte	"2 CREDITS TO START",0,1
	.even
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_22,ROBO_LASER,STRCNRM,0
	.byte	"1 CREDIT TO CONTINUE",0,0
	.even

TWO_TO_START_2C
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_12,ROBO_LASER,STRCNRM,0
	.byte	"2 CREDITS TO START",0,1
	.even
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_22,ROBO_LASER,STRCNRM,0
	.byte	"2 CREDITS TO CONTINUE",0,0
	.even
*
*	 THIS IS FOR LINES TWO AND 3 WITH AN ADDITIONAL LINE ABOVE
*

TWO_TS	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_23,ROBO_LASER,STRCNRM,0
	.byte   "2 CREDITS TO START",0,1
	.even
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_33,ROBO_LASER,STRCNRM,0
	.byte   "1 CREDIT TO CONTINUE",0,0
	.even

TWO_TP	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_22,ROBO_LASER,STRCNRM,0
	.byte   "2 CREDITS PER PLAYER",0,0
	.even

TWO_CRED_PER_PLAYER
	MESS_MAC RD15FONT,SPACING20,CP_CX,CP_11,ROBO_LASER,STRCNRM,0
	.byte   "2 CREDITS PER PLAYER",0,0
	.even

MAX_C_M MESS_MAC RD15FONT,SPACING20,CP_CX,CP_11,ROBO_LF,STRCNRM,0
	.byte   "MAXIMUM CREDITS!",0,0
	.even

	.end
