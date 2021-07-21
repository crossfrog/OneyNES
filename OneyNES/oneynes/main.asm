PPUCTRL = $2000
PPUMASK = $2001
PPUSTATUS = $2002
OAMADDR = $2003
OAMDATA = $2004
PPUSCROLL = $2005
PPUADDR = $2006
PPUDATA = $2007
OAMDMA = $4014

GAMEPADINPUT = $4016

SprObjMemory = $0300

	.inesprg 1 ; prg bank count
	.ineschr 1 ; chr bank count
	.inesmap 0 ; mapper
	.inesmir 1 ; vram mirroring

	.rsset $0000

	.org $0000

Variables:

PassedTime:
	.byte $00
ScrollX:
	.byte $00
ScrollY:
	.byte $00

PlayerPosX:
	.byte $00
PlayerPosY:
	.byte $00
PlayerFlipped:
	.byte $00

PlayerVelocityX:
	.byte $00
PlayerVelocityY:
	.byte $00

GamepadBitShift:
	.byte $00
Gamepad1:
	.byte $00

	.bank 0
	.org $C000

RESET:
	LDA #%10100000 ; define ppu flags
	STA PPUCTRL
	LDA #%00011110 ; define sprite and background rendering
	STA PPUMASK

	JSR LoadPalettes
	JSR ResetSprites
	JSR SetPlayerSprites
	JSR LoadText

LoopForever:
	JMP LoopForever

LoadText:
	LDA PPUSTATUS
	LDA #$3C
	STA PPUADDR
	LDA #$62
	STA PPUADDR
	
	LDX #$00
.Loop:
	LDA LookTomarItsYou, x
	STA PPUDATA
	INX
	CPX #$1C
	BNE .Loop

LoadPalettes:
	LDA PPUSTATUS ; reset ppu address latch
	LDA #$3F ; load memory from $3f00 onward with palette data
	STA PPUADDR
	LDA #$00
	STA PPUADDR

	LDX #$00
.Loop:
	LDA Palettes, x
	STA PPUDATA
	INX
	CPX #$20
	BNE .Loop
	RTS

ResetSprites:
	LDA #$00
	LDX #$00
.Loop:
	STA SprObjMemory, x
	INX
	CPX #$FF ; loop through 64 sprites * 4 bytes = 256 bytes
	BNE .Loop
	RTS

SetPlayerSprites:
	LDA #$09
	STA SprObjMemory + 1
	LDA #$0b
	STA SprObjMemory + 4 + 1

	LDA #120
	STA PlayerPosX
	LDA #104
	STA PlayerPosY

	RTS

ReadGamepads:
	LDA #$00 ; reset gamepad byte
	STA Gamepad1

	LDA #$01 ; latch shift register
	STA $4016
	LDA #$00
	STA $4016

	LDA #$01 ; reset gamepad bitshift
	STA GamepadBitShift

	LDX #$00
.Loop:
	LDA GAMEPADINPUT ; get next bit of register
	AND #%00000001
	BEQ .Continue

	LDA Gamepad1 ; apply button's bit in place to the gamepad byte
	ORA GamepadBitShift
	STA Gamepad1
.Continue:
	LDA GamepadBitShift ; rotate button bitshift
	ROL A
	STA GamepadBitShift

	INX
	CPX #$08
	BNE .Loop

	RTS

NMI:
	INC PassedTime

	LDA PlayerFlipped
	BEQ SkipPlayerFlip

	LDA PlayerPosX
	STA SprObjMemory + 4 + 3
	STA SprObjMemory + 12 + 3
	ADC #$07
	STA SprObjMemory + 3
	STA SprObjMemory + 8 + 3

	LDA #%01000000
	ORA SprObjMemory + 2
	STA SprObjMemory + 2

	LDA #%01000000
	ORA SprObjMemory + 4 + 2
	STA SprObjMemory + 4 + 2

	LDA #%01000000
	ORA SprObjMemory + 8 + 2
	STA SprObjMemory + 8 + 2

	LDA #%01000000
	ORA SprObjMemory + 12 + 2
	STA SprObjMemory + 12 + 2
	JMP AfterPlayerFlip

	JMP AfterPlayerFlip

SkipPlayerFlip:
	LDA PlayerPosX
	STA SprObjMemory + 3
	STA SprObjMemory + 8 + 3
	ADC #$07
	STA SprObjMemory + 4 + 3
	STA SprObjMemory + 12 + 3

	LDA #%10111111
	AND SprObjMemory + 2
	STA SprObjMemory + 2

	LDA #%10111111
	AND SprObjMemory + 4 + 2
	STA SprObjMemory + 4 + 2

	LDA #%10111111
	AND SprObjMemory + 8 + 2
	STA SprObjMemory + 8 + 2

	LDA #%10111111
	AND SprObjMemory + 12 + 2
	STA SprObjMemory + 12 + 2

AfterPlayerFlip:
	LDA PlayerPosY
	STA SprObjMemory
	STA SprObjMemory + 4

	ADC #$10
	STA SprObjMemory + 8
	STA SprObjMemory + 12

	JSR ReadGamepads

CheckButtonLeft:
	LDA Gamepad1
	AND #$40
	BEQ CheckButtonRight
	DEC PlayerPosX
	LDA #$FF
	STA PlayerFlipped;
	JMP DoneMovement

CheckButtonRight:
	LDA Gamepad1
	AND #$80
	BEQ DoneMovement
	INC PlayerPosX
	LDA #$00
	STA PlayerFlipped;

DoneMovement:

AnimatePlayer:
	LDA Gamepad1
	AND #%11000000
	BEQ SetPlayerStandingFrame

	LDA PassedTime
	AND #$08
	BEQ SetPlayerStandingFrame

SetPlayerWalkingFrame:
	LDA #$11
	STA SprObjMemory + 8 + 1
	LDA #$13
	STA SprObjMemory + 12 + 1

	LDA PlayerPosY
	ADC #$00
	STA SprObjMemory
	STA SprObjMemory + 4

	JMP AnimatePlayerDone

SetPlayerStandingFrame:
	LDA #$0D
	STA SprObjMemory + 8 + 1
	LDA #$0F
	STA SprObjMemory + 12 + 1

AnimatePlayerDone:
	JSR HandleGraphics
	RTI

	.bank 1
	.org $E000

HandleGraphics:
	LDA #$00
	STA OAMADDR
	LDA #$03
	STA OAMDMA

	LDA PPUSTATUS
	LDA ScrollX
	STA PPUSCROLL
	LDA ScrollY
	STA PPUSCROLL
	RTS

Palettes:
	.incbin "colors.pal"
LookTomarItsYou:
	.incbin "tomar.txt"

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

	.bank 2
	.org $0000
	.incbin "gameplay.chr"
