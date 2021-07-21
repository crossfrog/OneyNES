	.inesprg 1    ; Defines the number of 16kb PRG banks
	.ineschr 1    ; Defines the number of 8kb CHR banks
	.inesmap 0    ; Defines the NES mapper
	.inesmir 1    ; Defines VRAM mirroring of banks

	.rsset $0000

	.org $0200
Scroll:
	.byte $00

	.org $0F00
	.byte $80, $02, $00, $80

	.bank 0
	.org $C000

RESET:
	LDA #%10100000
	STA $2000
	LDA #%00011110
	STA $2001
	JSR LoadPalettes

InfiniteLoop:
	JMP InfiniteLoop

LoadPalettes:
	BIT $2002
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006

	LDX #$00
.Loop:
	LDA palettes, x
	STA $2007
	INX
	CPX #$20
	BNE .Loop
LoadSprites:
  LDX #$00              ; start at 0
LoadSpritesLoop:
  LDA sprites, x        ; load data from address (sprites +  x)
  STA $0300, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$10              ; Compare X to hex $10, decimal 16
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero
                        ; if compare was equal to 16, keep going down
	RTS

NMI:
	LDA #$00
	STA $2003
	LDA #$03
	STA $4014
	
	BIT $2002
	INC Scroll
	LDA Scroll
	STA $2005
	LDA #$00
	STA $2005

	RTI

	.bank 1
	.org $E000

	palettes:
	.incbin "colors.pal"
	sprites:
		 ;vert tile attr horiz
	  .db $C0, $81, $00, $C0   ;sprite 0
	  .db $00, $00, $00, $00   ;sprite 1
	  .db $00, $00, $00, $00   ;sprite 2
	  .db $00, $00, $00, $00   ;sprite 3

	.org $FFFA
	.dw NMI
	.dw RESET
	.dw 0

	.bank 2
	.org $0000
	.incbin "gameplay.chr"
