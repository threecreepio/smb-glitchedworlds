.p02
.org $8000

ColdTitleReset:
    jsr InitializeWRAM
    jsr CopySettingsToMemory
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
    jsr CopyMemoryToSettings
    jsr MInitializeMemory
    jsr CopySettingsToMemory
    ldx #$00
    stx OperMode_Task
    stx PPU_SCROLL_REG
    stx PPU_SCROLL_REG
    lda #$80
    sta PPU_CTRL_REG1
:   jmp :-


MInitializeMemory:
    ldx #0
@clear:
    lda #$00
    sta $0000, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne @clear
    rts


TitleNMI:
    ldx #$FF
    txs
:   jsr TitleJumpEngine
    jmp :-

TitleJumpEngine:
    lda OperMode_Task
    jsr JumpEngineCore
    .word Title_Setup
    .word Title_Main

Title_Setup:
    inc OperMode_Task
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
    cpx #(PALETTEEND-PALETTE)
    bne @WRITE_PAL

    ldx #0
    lda #$20
    sta PPU_ADDRESS
    lda #$00
    sta PPU_ADDRESS
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

    jsr RenderMenu
    lda #%00001110
    sta PPU_CTRL_REG2
    lda #0
    sta PPU_SCROLL_REG
    sta PPU_SCROLL_REG

    lda #%10010000
    sta PPU_CTRL_REG1
    rts


Title_Main:
    jsr TReadJoypads
    lda SavedJoypad2Bits
    clc
    cmp #0
    bne @READINPUT
    : jmp :-

@READINPUT:
    ldy WSelection
    ldx SettablesLow,y
    stx $3
    ldx SettablesHi,y
    stx $4
    ldy #0

@RIGHT:
    cmp #%00000001
    bne @LEFT

    lda #$0
    adc ($3),y
    sta ($3),y
    jmp Rerender

@LEFT:
    cmp #%00000010
    bne @DOWN
    lda #$FE
    adc ($3),y
    sta ($3),y
    jmp Rerender

@DOWN:
    cmp #%00000100
    bne @UP
    lda #$EF
    adc ($3),y
    sta ($3),y
    jmp Rerender

@UP:
    cmp #%00001000
    bne @SELECT
    lda #$F
    adc ($3),y
    sta ($3),y
    jmp Rerender

@SELECT:
    cmp #%00100000
    bne @START
    inc WSelection
    lda WSelection
    cmp #(SettablesLowEnd-SettablesLow)
    bne @SELECT2
    lda #0
    sta WSelection
@SELECT2:
    jmp Rerender

@START:
    cmp #%00010000
    bne @DONE
    ldx SavedJoypadBits
    cpx #%10000000
    lda #0
    bcc @START2
    lda #1
@START2:
    sta PrimaryHardMode
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
    lda #$20
    sta $1
    lda #$92
    sta $2

    lda #0
    sta $0
@RenderMenu:
    ldy $0

    clc
    lda $2
    adc #$40
    sta $2
    bcc @NoOverflow
    inc $1
@NoOverflow:
    lda $1
    sta PPU_ADDRESS
    lda $2
    sta PPU_ADDRESS

    ldy $0
    ldx SettablesLow,y
    stx $3
    ldx SettablesHi,y
    stx $4
    ldy #0

    lda ($3),y
    clc
    jsr print_hexbyte

    lda #$24
    sta PPU_DATA

    ldy $0
    cpy WSelection
    bne @RenderSelectionTick
    adc #3
@RenderSelectionTick:
    sta PPU_DATA
    inc $0
    lda $0
    cmp #(SettablesLowEnd-SettablesLow)
    bne @RenderMenu
    rts


InitializeWRAM:
    lda WInitialized
    cmp #$59
    beq @InitializeWRAM_Done
    lda #$59
    sta WInitialized
    lda #1
    sta SettingsFileStart + (SettablesLowPlayerSize - SettablesLow) + 1
@InitializeWRAM_Done:
    rts

WSelection = $60F0
WInitialized = (SettingsFileStart - 1)
SettingsFileStart = $60FF

CopySettingsToMemory:
    ldy #0
    ldx #(SettablesLowEnd-SettablesLow)
@CopySetting:
    lda SettablesLow-1,x
    sta $0
    lda SettablesHi-1,x
    sta $1
    lda SettingsFileStart,x
    sta ($0),y
    dex
    bne @CopySetting
    rts

CopyMemoryToSettings:
    ldy #0
    ldx #(SettablesLowEnd-SettablesLow)
@CopySetting:
    lda SettablesLow-1,x
    sta $0
    lda SettablesHi-1,x
    sta $1
    lda ($0),y
    sta SettingsFileStart,x
    dex
    bne @CopySetting
    rts

SettablesLow:
    .byte <WorldNumber
    .byte <AreaNumber
    .byte <PlayerStatus
SettablesLowPlayerSize:
    .byte <PlayerSize
SettablesLowEnd:

SettablesHi:
    .byte >WorldNumber
    .byte >AreaNumber
    .byte >PlayerStatus
    .byte >PlayerSize


TStartGame:
    lda #%10000000
    sta PPU_CTRL_REG1
    lda #%00011110
    sta PPU_CTRL_REG2

    lda #$00
    sta $4015
    lda #Silence             ;silence music
    sta EventMusicQueue

    lda AreaNumber
    sta LevelNumber

    lda #$7F
    sta NumberofLives

    ; set the startup mode to enter the game immediately
    lda #1
    sta OperMode
    lda #0
    sta OperMode_Task
    lda #0
    sta GameEngineSubroutine

    lda #4
    sta GameTimerDisplay

    lda #$00                  ;game timer from header
    sta TimerControl          ;also set flag for timers to count again

    ; jump to a spot in the startup code where the game won't clear out memory
    ldx #$FF
    txs
    lda #>(GL_ENTER - 1)
    pha
    lda #<(GL_ENTER - 1)
    pha
    lda #>(LoadAreaPointer - 1)
    pha
    lda #<(LoadAreaPointer - 1)
    pha
    jmp TitleBankSwitch


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
TitleBankSwitch:
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
.word ColdTitleReset
.word ColdTitleReset
