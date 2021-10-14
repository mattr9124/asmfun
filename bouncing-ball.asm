; Bouncing ball by Matthew B Rossner
; October 13 2021
;
; This is just a little learning project.
; I had done some assembly programming on Motorola 6809
; back in the day but haven't done much since then.
; Thanks to YouTube I've become interested in the 6502
; and decided I want to learn how to program for that, just because...
;
; My goal was to make a sort of Arkanoid/Breakout clone but I
; thought I would start with something simple. So this will just
; be some kind of ball that has a trajectory and velocity and should
; bounce off the wall changing trajectory. For now velocity will be
; a constant set at the start

; Using this simulator by Nick Morgan as a starting point
; https://skilldrick.github.io/easy6502
; Will then see about getting it to run on eiter a C64 or NES emulator

; For the simulator we're dealing with a 16x16 pixel screen
; and will use a single pixel for the ball - yes keeping it simple
; Using this as a reference: https://gist.github.com/wkjagt/9043907

; The screen memory is $0200 - $05ff

; Row 1: $0200 - $021f
; Row 2: $0220 - $023f
; etc...

; The ball will have 4 possible trajectories:
; 0 - Up-Left 
; 1 - Up-Right 
; 2 - Down-Right 
; 3 - Down-Left 

; Since this is simply a matter of plotting X/Y coordinates, given the
; trajectory it will simply be a matter of inc/dec X and Y
; We'll store trajectory in memory address $02

game:
    JSR initBall
    JSR initTrajectory
    JSR loop

loop:
    JSR drawBall
    JSR update
    JSR detectBorder
    JSR spinWheels
    ; infinite loop
    JMP loop


initBall:
    ; we'll store the X/Y coordiantes in memory locations $00 and $01 respectively
    ; let's give it a random starting position within the boundaries of $0200 - $05ff
    ; why is loading $fe random? Not sure... TBC
    ; Since we actually have 4 pages of 00-ff, then 2-5 (see the Gist above)
    ; we can generate a position and a page
    ; First random is any single byye
    LDA $fe
    LDA #$a7 ;DEBUG ONLY - force value
    STA $00
    ; now load Y which is a page from 2-5
    LDA $fe
    ; now let's bitmask this
    ; so really we want random 0-3, then we can shift it over? ot just add 2
    ; bitmask is % 0000 0011
    AND #$02
    ADC #02

    LDA #3 ;DEBUG ONLY - force value

    STA $01

    ; set last location empty
    LDX #0
    STX $03
    LDX #2
    STX $04

    RTS

initTrajectory:
    ; random from 0-3
    LDA $fe
    AND #02
    LDA #3 ; DEBUG ONLY - force value
    STA $02

    RTS    

drawBall:
    ;clear the Y register
    LDY #0
    ; clear any previous position
    LDA #0
    STA ($03),Y

    ; draw the ball
    ;set color
    LDA #01

    STA ($00),Y
    RTS

update:
    ;store the last position
    LDX $00
    STX $03
    LDX $01
    STX $04
    ; TODO need todetermine collisions
    ; TODO change direction to use 2 bits
    LDX $02
    CPX #0
    BEQ upLeft
    CPX #1
    BEQ upRight
    CPX #2
    BEQ downRight
    CPX #3
    BEQ downLeft

    upLeft:
        DEC $00 ; move x 1 to the left
        ; move y 1 up
        JSR decPage
        RTS

    upRight:
        INC $00
        JSR decPage
        RTS

    downRight:
        INC $00
        JSR incPage
        RTS

    downLeft:

        DEC $00
        JSR incPage
        RTS

        incPage:
            ; we need to add 32/0x20 in this case
            ; if carry flag is set we need to move to the next page
            LDA $00 ; we still load 00 into memory
            CLC ; clear carry first
            ADC #$20
            STA $00 ; store it back
            BCS nextPage
            RTS
            nextPage:
                INC $01 ; next page
                RTS

        decPage:
            LDA $00 ; we still load 00 into memory
            SBC #$20
            STA $00 ; store it back
            BCC prevPage
            RTS
            prevPage:
                DEC $01 ; preivous page
                RTS


detectBorder:
    ; hopefully we can figure this out with some bit masking
    ; left borders are 
    ; $0x00
    ; $0x20 
    ; $0x40 
    ; ...
    ; $0xe0 
    ; so actually we only about the least significant part which is stored in $00
    ; We can already mask way the lowest 4 bits % 11110000 / $f0
    LDX $00
    TXA
    AND #$0f
    BEQ checkFurther
    RTS
    checkFurther:
        AND #$f0
        ; now we can check for even
        ; we can shift this 4 times to the right
        LSR A
        LSR A
        LSR A
        LSR A
        ; now we logical AND with 1 to see if it's even or not
        AND #01
        ; if it's a border we change direction
        BEQ changeDirLR
        RTS

        changeDirLR:
            DEC $02 
            RTS
;    changeDirLR:
;        LDX $02 ; direction stored in memory 2



; from that Gist
spinWheels:
  ;slow the game down by wasting cycles
  ldx #0       ;load zero in the X register
spinloop:
  nop          ;no operation, just skip a cycle
  nop          ;no operation, just skip a cycle
  dex          ;subtract one from the value stored in register x
  bne spinloop ;if the zero flag is clear, loop. The first dex above wrapped the
               ;value of x to hex $ff, so the next zero value is 255 (hex $ff)
               ;loops later.
  rts          ;return