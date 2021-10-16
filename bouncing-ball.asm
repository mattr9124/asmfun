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

; The ball will have 4 possible trajectories using first 2 bits
; Bit 0 off is left, on is right
; Bit 1 off is down, on is up
; which works out to
; Down-Left 00    0
; Down-Right 01   1 
; Up-Left 10      2
; Up-Right 11     3

; We'll store trajectory in memory address $02

JSR initBall
JSR initTrajectory

loop:
    JSR drawBall
    JSR detectBorder
    JSR update
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
    ;LDA #$a9 ;DEBUG ONLY - force value
    STA $00
    ; now load Y which is a page from 2-5
    LDA $fe
    ; now let's bitmask this
    ; so really we want random 0-3, then we can shift it over? ot just add 2
    ; bitmask is % 0000 0011
    AND #$02
    ADC #02

    ;LDA #5 ;DEBUG ONLY - force value

    STA $01

    ; set last location empty
    ; will set just $0200 for now - first pixel of screen memory
    LDX #$00
    STX $03
    LDX #$02
    STX $04

    ; init color
    LDX #1
    STX $05

    RTS

initTrajectory:
    ; random from 0-3
    LDA $fe
    AND #02
    ;LDA #0 ; DEBUG ONLY - force value
    STA $02

    RTS    

drawBall:
    ;clear the Y register
    LDY #0
    ; clear any previous position
    ; set color black
    LDA #0
    STA ($03),Y

    ; draw the ball
    ;set color
    LDA $05

    STA ($00),Y
    RTS

update:
    ;store the last position
    LDX $00
    STX $03
    LDX $01
    STX $04

    ; determine direction and branch 
    LDX $02
    CPX #0
    BEQ downLeft
    CPX #1
    BEQ downRight
    CPX #2
    BEQ upLeft
    CPX #3
    BEQ upRight

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
    JSR checkLeft
    JSR checkBottom
    JSR checkRight
    JSR checkTop
    RTS

checkLeft:
    ; left borders are 
    ; $0x00
    ; $0x20 
    ; $0x40 
    ; ...
    ; $0xe0 
    LDX $00  ; load current value to X, we'll need to again soon
    TXA
    AND #$0f ; And with lower 4 bits, checking if the last digit is 0
    BEQ continueLeftCheck ; if last is 0 we continue the check
    RTS
    continueLeftCheck:
        TXA ; transfer value back since it was modified
        ; we know it ends in 0
        ; now we can check for even in the high bits
        ; shift this 4 times to the right
        LSR A
        LSR A
        LSR A
        LSR A
        ; now we logical AND with 1 to see if it's even or not
        AND #01
        ; if it's a border we change direction
        BEQ flipLeftRight
        RTS

checkRight:
    ; right border will be the odd ones finish in f
    ; $0x1f
    ; $0x3f
    ; ...
    ; $0xff
    ; basically the opposite of the above
    LDX $00
    TXA
    AND #$f
    CMP #$0f
    BEQ continueRightCheck
    RTS
    continueRightCheck:
        TXA
        LSR A
        LSR A
        LSR A
        LSR A
        AND #1
        BNE flipLeftRight
        RTS

checkBottom:
    ; we need to see if we are on page 5
    LDX $01
    CPX #5
    BEQ continueBottomCheck
    RTS    
    continueBottomCheck:
        ; position e0-ff will be the bottom left corner
        ; if you do $01 minus e0, the result should be > 0, otherwise we're at the bottom
        LDA $00
        SBC #$e0
        BCS flipUpDown
        RTS

checkTop:
    ; check if we are on page 2
    LDX $01
    CPX #2
    BEQ continueTopCheck
    RTS
    continueTopCheck:
        LDA $00
        ; 0 - 1f is top row
        SBC #$1e
        BCC  flipUpDown
        RTS

flipLeftRight:
    ; we need to flip left right
    ; XOR bit
    LDX #1
    STX $06
    JMP doFlip

flipUpDown:
    ; same as above but on second bit
    LDX #2
    STX $06
    ; don't need to jump since it's already next instruction
doFlip:
    ; load direction
    LDA $02
    ; XOR with first bit to flip
    EOR $06
    ; store it back
    STA $02
    ;change color
    LDX $05
    INX
    TXA
    AND #$0f
    STA $05
    BEQ skipColor ; avoid black since backgroun is black
    RTS
    skipColor:
        INC $05
        RTS

; from that Gist
spinWheels:
  ;slow the game down by wasting cycles
  ldx #$50       ;load zero in the X register
spinloop:
  ;nop          ;no operation, just skip a cycle
  nop          ;no operation, just skip a cycle
  dex          ;subtract one from the value stored in register x
  bne spinloop ;if the zero flag is clear, loop. The first dex above wrapped the
               ;value of x to hex $ff, so the next zero value is 255 (hex $ff)
               ;loops later.
  rts          ;return
