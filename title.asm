.p02
.org $8000



TitleReset:
    sei
    ldx #$FF
    stx $8000
    txs

    ; set title screen bank
    lda #0
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000

    ; enable bank switching
    lda #$02
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000
    lsr
    sta $8000

    jsr MoveHardReset
    jsr InitializeWRAM

    ; setup
    ldx #$00
    stx PPU_CTRL_REG1
    stx PPU_CTRL_REG2
wait_vbl0:
    lda PPU_STATUS
    bpl wait_vbl0
wait_vbl1:
    lda PPU_STATUS
    bpl wait_vbl1
    ldx #0
clear_memory:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne clear_memory
    ldx #$00
    stx PPU_SCROLL_REG
    stx PPU_SCROLL_REG
    lda #$80
    sta PPU_CTRL_REG1
:   jmp :-




TitleNMI:
    ldx #$FF
    txs
    ;bit PPU_STATUS
    ;lda #%10010000
    ;sta PPU_CTRL_REG1
    ;lda #%00001110
    ;sta PPU_CTRL_REG2
:   jsr TitleJumpEngine
    jmp :-

InitializeWRAM:
    lda WInitialized
    cmp #$9a
    beq InitializeWRAM_Done
    lda #$9a
    sta WInitialized
    lda #1
    sta WPlayerSize
InitializeWRAM_Done:
    rts



TitleJumpEngine:
    lda OperMode_Task
    jsr JumpEngineCore
    .word Title_Setup
    .word Title_Main


Title_Setup:
    bit PPU_STATUS
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    sta PPU_CTRL_REG2

    lda #$3F
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
    ldx #0
@WRITE_PAL:
    clc
    lda PALETTE,x
    sta PPU_DATA
    inx
    cpx #4
    bne @WRITE_PAL


    ldx #0
    lda #$20
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
    lda #$24
@WRITE_L1:
    lda BG_L1, x
    sta PPU_DATA
    inx
    bne @WRITE_L1
@WRITE_L2:
    lda BG_L2, x
    sta PPU_DATA
    inx
    bne @WRITE_L2
@WRITE_L3:
    lda BG_L3, x
    sta PPU_DATA
    inx
    bne @WRITE_L3
@WRITE_L4:
    lda BG_L4, x
    sta PPU_DATA
    inx
    bne @WRITE_L4

    ldy #30 ; Height
@RepeatY:
    ldx #32 ; Width
@RepeatX:
    clc
    sta PPU_DATA
    dex
    bne @RepeatX
    dey
    bne @RepeatY
    clc

    jsr RenderMenu

    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG

    lda #%10010000
    sta PPU_CTRL_REG1
    lda #%00001110
    sta PPU_CTRL_REG2
    inc OperMode_Task
    rts






WInitialized = $60FE
WSelection = $60FF
WSelections = $6100
WWorldNumber = $6100
WAreaNumber = $6101
WPlayerStatus = $6102
WPlayerSize = $6103

Title_Main:
    jsr TReadJoypads
    lda SavedJoypad2Bits
    clc
    ldy WSelection

@RIGHT:
    cmp #%00000001
    bne @LEFT
    lda #0
    adc WSelections,y
    sta WSelections,y
    jmp Rerender


@LEFT:
    cmp #%00000010
    bne @DOWN
    lda #$FE
    adc WSelections,y
    sta WSelections,y
    jmp Rerender


@DOWN:
    cmp #%00000100
    bne @UP
    lda #$EF
    adc WSelections,y
    sta WSelections,y
    jmp Rerender


@UP:
    cmp #%00001000
    bne @SELECT
    lda #$F
    adc WSelections,y
    sta WSelections,y
    jmp Rerender

@SELECT:
    cmp #%00100000
    bne @START
    inc WSelection
    lda WSelection
    cmp #4
    bne @SELECT2
    lda #0
    sta WSelection
@SELECT2:
    jmp Rerender


@START:
    cmp #%00010000
    bne @DONE
    jmp TStartGame
@DONE:
    : jmp :-

Rerender:
    jsr RenderMenu
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG
    : jmp :-


RenderMenu:
    ldx WSelection
    lda #$20
    sta PPU_ADDRESS
    lda #$D2
    sta PPU_ADDRESS
    lda WWorldNumber
    jsr print_hexbyte
    lda #$24
    sta PPU_DATA
    lda #$24
    cpx #0
    bne R1
    adc #3
    R1:
    sta PPU_DATA
    
    lda #$21
    sta PPU_ADDRESS
    lda #$12
    sta PPU_ADDRESS
    lda WAreaNumber
    jsr print_hexbyte
    lda #$24
    sta PPU_DATA
    lda #$24
    cpx #1
    bne R2
    adc #3
    R2:
    sta PPU_DATA
    
    lda #$21
    sta PPU_ADDRESS
    lda #$52
    sta PPU_ADDRESS
    lda WPlayerStatus
    jsr print_hexbyte
    lda #$24
    sta PPU_DATA
    lda #$24
    cpx #2
    bne R3
    adc #3
    R3:
    sta PPU_DATA

    lda #$21
    sta PPU_ADDRESS
    lda #$92
    sta PPU_ADDRESS
    lda WPlayerSize
    jsr print_hexbyte
    lda #$24
    sta PPU_DATA
    lda #$24
    cpx #3
    bne R4
    adc #3
    R4:
    sta PPU_DATA
    rts







print_hexchar:
    cmp #10
    bcc @after1
@after1:
    sta PPU_DATA
    rts
print_hexbyte:
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr print_hexchar
    pla
    and #$0F
    jsr print_hexchar
    rts

TReadJoypads:
        lda #0
        sta SavedJoypad2Bits
        lda #$01
        sta JOYPAD_PORT
        lsr
        sta JOYPAD_PORT
        ldy #$08
TPortLoop:
        pha
        lda JOYPAD_PORT
        sta $00
        lsr
        ora $00
        lsr
        pla
        rol
        dey
        bne TPortLoop
        cmp SavedJoypadBits
        beq TPortLoop2
        sta SavedJoypad2Bits
TPortLoop2:
        sta SavedJoypadBits
        rts


JumpEngineCore:
       asl          ;shift bit from contents of A
       tay
       pla          ;pull saved return address from stack
       sta $04      ;save to indirect
       pla
       sta $05
       iny
       lda ($04),y  ;load pointer from indirect
       sta $06      ;note that if an RTS is performed in next routine
       iny          ;it will return to the execution before the sub
       lda ($04),y  ;that called this routine
       sta $07
       jmp ($06)    ;jump to the address we loaded


TStartGame:
    lda #%10000000
    sta PPU_CTRL_REG1
    lda #%00011110
    sta PPU_CTRL_REG2

    clc
    lda WPlayerSize
    sta PlayerSize
    lda WPlayerStatus
    sta PlayerStatus
    lda WWorldNumber
    sta WorldNumber
    lda WAreaNumber
    sta AreaNumber
    sta LevelNumber

    ; set the startup mode to enter the game immediately
    lda #0
    sta OperMode
    lda #1
    sta OperMode_Task
    lda #0
    sta ScreenRoutineTask
    lda #6
    sta GameEngineSubroutine

    ; jump to a spot in the startup code where the game won't clear out memory
    clc
    ldx #$FF
    txs
    lda #>GL_ENTER
    pha
    lda #<GL_ENTER
    pha
    jmp ConstructReturn

InGameCodeLocation = $6200
MoveHardReset:
    clc
    ldy #40
:   lda HardReset_Start,y
    sta $61FF,y
    dey
    bne :-
    rts
HardReset_Start:
    .byte $FF
    lda #0
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    jmp TitleReset

;; This will line up properly with an RTS in the SMB rom.
.res $F908 - * - $15, $00
ConstructReturn:
    lda #2
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
    lsr
    sta $E000
.res $F908 - *, $FF
    rts

.include "titlebg.asm"

.res $FFFA - *, $FF
.word TitleNMI
.word TitleReset
.word TitleReset
