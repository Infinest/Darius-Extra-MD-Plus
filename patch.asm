; Constants: ---------------------------------------------------------------------------------
	MD_PLUS_OVERLAY_PORT:			equ $0003F7FA
	MD_PLUS_CMD_PORT:				equ $0003F7FE
	MD_PLUS_RESPONSE_PORT:			equ $0003F7FC

	RESET_VECTOR_ORIGINAL:			equ $00000200

	OFFSET_RESET_VECTOR:				equ $00000004
	OFFSET_FADEOUT_BOSS_ALERT:			equ $0004722E
	OFFSET_FADEOUT_STAGE_TRANSITION:	equ $000502DC
	OFFSET_PLAY:						equ $0005BF7E
	OFFSET_PAUSE_MUSIC_PLAYER:			equ $0003F7D4
	OFFSET_RESUME_GAME:					equ $0005451A
	OFFSET_PAUSE_GAME:					equ $00054438
	OFFSET_GAME_OVER_NAME_ENTRY_MUSIC:	equ $00058986
	OFFSET_RESUME_MUSIC_PLAYER:			equ $0003FEBE
	OFFSET_STOP_PLAYBACK:				equ $0005C25A

	REGISTER_Z80_BUS_REQ:	equ $A11100 

; Overrides: ---------------------------------------------------------------------------------

	org OFFSET_RESET_VECTOR
	dc.l DETOUR_RESET_VECTOR

	org OFFSET_FADEOUT_BOSS_ALERT
	jsr DETOUR_FADEOUT_BOSS_ALERT
	nop

	org OFFSET_FADEOUT_STAGE_TRANSITION
	jsr DETOUR_FADEOUT_STAGE_TRANSITION

	org OFFSET_PLAY
	jmp DETOUR_PLAY
	nop

	org OFFSET_PAUSE_MUSIC_PLAYER
	jsr DETOUR_PAUSE_MUSIC_PLAYER

	org OFFSET_RESUME_GAME
	jsr DETOUR_RESUME_GAME

	org OFFSET_PAUSE_GAME
	jsr DETOUR_PAUSE_GAME

	org OFFSET_GAME_OVER_NAME_ENTRY_MUSIC
	jmp DETOUR_GAME_OVER

	org OFFSET_RESUME_MUSIC_PLAYER
	jsr DETOUR_RESUME_MUSIC_PLAYER

	org OFFSET_STOP_PLAYBACK
	jsr DETOUR_STOP_PLAYBACK

; Detours: -----------------------------------------------------------------------------------

	org $003FB1A0

DETOUR_RESET_VECTOR:
	move.w	#$1300,D0
	jsr WRITE_MD_PLUS_FUNCTION
	incbin	"intro.bin"				; Show MD+ intro screen
	jmp		RESET_VECTOR_ORIGINAL	; Return to game's original entry point

DETOUR_FADEOUT_BOSS_ALERT:
	move.w D0,-(A7)
	move.w #$13A0,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
	move.b #$24,($A00190)
	rts

DETOUR_FADEOUT_STAGE_TRANSITION:
	cmpi.b #$24,D2
	bne .notFadeOut
	move.w D0,-(A7)
	move.w #$13C0,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
.notFadeOut
	move.b D2,($A00190)
	rts

DETOUR_GAME_OVER:
	move.w D0,-(A7)
	cmpi.w #$0,D3			; Function is also called upon pause, ensure this is an actual game over call
	bne .EXIT_GAME_OVER

	move.w #$1600,D0
	move.w #$CD54,(MD_PLUS_OVERLAY_PORT)
	move.w D0,(MD_PLUS_CMD_PORT)
	move.w (MD_PLUS_RESPONSE_PORT),D0
	move.w #$0000,(MD_PLUS_OVERLAY_PORT)
    tst.w D0
    beq .EXIT_GAME_OVER
	move.w (A7)+,D0

	move.w ($FF13B8),D1
    subq.w #$1,D1
    move.w D1,($FF13B8)

    jmp $589BE
.EXIT_GAME_OVER
	move.w (A7)+,D0
    movea.l #$A11100,A0
    jmp $5898C

DETOUR_STOP_PLAYBACK:
    move.w #$1300,D0
	jsr WRITE_MD_PLUS_FUNCTION
    move.w ($FF303A),D0
    rts

DETOUR_RESUME_GAME:
	move.w D0,-(A7)
	move #$1400,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
	jsr $587CC
	rts

DETOUR_PAUSE_GAME:
	move.w D0,-(A7)
    move #$1300,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
	jsr $58952
    rts

DETOUR_RESUME_MUSIC_PLAYER:
	move.w D0,-(A7)
	move #$1400,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
	jsr $59E30
    rts

DETOUR_PAUSE_MUSIC_PLAYER:
	move.w D0,-(A7)
	move #$1300,D0
	jsr WRITE_MD_PLUS_FUNCTION
	move.w (A7)+,D0
    jsr $4FFE4
    rts

DETOUR_PLAY:
    jsr PRESERVE_REGISTERS
    clr.l D0
    ori.w #$1200,D0
    cmpi.b #$14,D1
    blt.b TEST_PLAYABLE_TRUE
    jsr RESTORE_REGISTERS
	lea (-$fc,A7),A7
	movem.l D2-D4/A2-A3/A6,-(A7)
    jmp $5bf7e
TEST_PLAYABLE_TRUE
    addq.b #$1,D1
	cmpi.b #$9,D1
    or.b D1,D0
	jsr WRITE_MD_PLUS_FUNCTION
    jsr RESTORE_REGISTERS
    jmp $5c1e2


PRESERVE_REGISTERS:
    lea (-$fc,A7),A7
    move.w SR,(A7)
    movem.l D0-D6/A0-A7,-(A7)
    lea (A7),A0
    lea ($138,A7),A7
    clr.l D0
    clr.l D1
    clr.l D2
    clr.l D3
    clr.l D4
    clr.l D5
    move.w ($A,A7),D1 ;Get the track number from the stack
    rts

RESTORE_REGISTERS:
    lea (A0),A7
    movem.l (A0)+,A0-A7/D0-D6
    move.w (A7),SR
    lea ($fc,A7),A7
    rts


; Helper Functions: --------------------------------------------------------------------------

WRITE_MD_PLUS_FUNCTION:
	move.w  #$CD54,(MD_PLUS_OVERLAY_PORT)			; Open interface
	move.w  D0,(MD_PLUS_CMD_PORT)					; Send command to interface
	move.w  #$0000,(MD_PLUS_OVERLAY_PORT)			; Close interface
	rts