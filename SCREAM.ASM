scream_snd
	movi	scrm1_snd,a0
	calla	snd_play1
	SLEEP	85
	movi	scrm2_snd,a0
	calla	snd_play1
	SLEEP	85
	movi	scrm3_snd,a0
	calla	snd_play1
	SLEEP	85
	movi	scrm4_snd,a0
	calla	snd_play1
	SLEEP	85
	jruc	scream_snd

;scrm1_snd	.word	>f898,10,>8144,0	;Quick cheer
;scrm2_snd	.word	>fd84,80,>810f,0	;Long cheer
;scrm3_snd	.word	>f894,80,>8144,0	;Long cheer
;scrm4_snd	.word	>fc84,120,>814e,0	;Long cheer
;boo1_snd	.word	>f884,120,>814a,0	;Boo

;RJR	scrm1_snd	.word	>f380,10,>810c,0
scrm1_snd	.word	>f380,10,>813d,0

scrm2_snd	.word	>f080,10,>814b,0
scrm3_snd	.word	>f480,10,>815e,0
scrm4_snd	.word	>f180,10,>815f,0

