;
; Fullscreen vertical scroll
; 

                clr.l   -(sp)		supervisor mode on
                move.w  #$20,-(sp)
                trap    #1
                move.l  d0,savereg

                move.l  #$70000,a7

                move.l  #moff,-(sp)	mouse off
                clr.w   -(sp)
                move.w  #25,-(sp)
                trap    #14
                addq.l  #8,sp
                dc.w    $a00a

                move.w  #4,-(sp)	get resolution        
                trap    #14
                addq.l  #2,sp
                move.w  d0,oldrez
                move.l  $44e,oldscr
                move.l  #$70000,screen

                movem.l $ffff8240.w,d0-d7	set colors
                movem.l d0-d7,oldpal

                bsr     prepare		put some graphics on screen
                bsr     hblon		enable interrupts

                move.w  #1,-(sp)	wait for a key
                trap    #1
                addq.l  #2,sp

                bsr     hbloff		disable interrupts

                movem.l oldpal,d0-d7	old colors back
                movem.l d0-d7,$ffff8240.w
                move.w  oldrez,-(sp)	old resolution back
                move.l  oldscr,-(sp)
                move.l  oldscr,-(sp)
                move.w  #5,-(sp)
                trap    #14
                add.l   #12,sp

                move.l  #mon,-(sp)	mouse on
                clr.w   -(sp)
                move.w  #25,-(sp)
                trap    #14
                addq.l  #8,sp
                dc.w    $a009

                move.l  savereg,-(sp)	leave supervisor
                move.w  #$20,-(sp)
                trap    #1
                addq.l  #6,sp

                clr.w   -(sp)		sayonara!
                trap    #1

oldrez:         dc.w    0
oldscr:         dc.l    0
savereg:        dc.l    0
screen:         dc.l    0
oldpal:         ds.w    16
mon:            dc.b    $08
moff:           dc.b    $12

                even

; see the article for comments about these addresses
hblon:          move.l  $120,oldtb
                move.l  $70,old4
                move.l  $70,new4b+2
                move.b  $fffffa07,old07
                move.b  $fffffa09,old09
                move.b  $fffffa0f,old0f
                move.b  $fffffa11,old11
                move.b  $fffffa1b,old1b
                and.b   #$df,$fffa09
                and.b   #$fe,$fffa07 
                move.l  #new4,$70
                or.b    #1,$fffffa07
                or.b    #1,$fffffa13
                rts

hbloff:         move.w  sr,-(sp)
                move.w  #$2700,sr
                move.b  old07(pc),$fffffa07
                move.b  old09(pc),$fffffa09
                move.b  old0f(pc),$fffffa0f
                move.b  old11(pc),$fffffa11
                move.b  old1b(pc),$fffffa1b
                move.l  oldtb,$120
                move.l  old4,$70
                move.w  (sp)+,sr
                rts

old4:           dc.l    0
oldtb:          dc.l    0
old07:          dc.b    0
old09:          dc.b    0
old0f:          dc.b    0
old11:          dc.b    0
old1b:          dc.b    0

                even

; This is the new VBL handler
new4:           
                movem.l d0-a7,-(sp)

                lea    currentscreen,a0
                move.l (a0),d0

                cmp.l  #8,d0
                blt update_screen

                clr.l  d0

update_screen:
                move.l  d0,d1

                add.l   #1,d1
                lea     currentscreen,a0
                move.l  d1,(a0)                

                lsl.l   #2,d0
                lea     screenptr,a0
                add.l   d0,a0
                move.l  (a0),d0

		lsr.l	#8,d0
		move.b	d0,$ff8203
		lsr 	#8,d0
		move.b	d0,$ff8201                

                movem.l (sp)+,d0-a7
                rte 

new4b:          jmp     $12345678

; now some routines to set the graphics

prepare:        move.w  #0,-(sp)        ;set low res
                move.l  screen(pc),-(sp)
                move.l  screen(pc),-(sp)
                move.w  #5,-(sp)
                trap    #14
                add.l   #12,sp

		lea	screens,a0
		move.l  a0,d0
		add.l   #$ff,d0

		move.l  #$ffffff00,d1

		and.l   d1,d0

		lea     screenptr,a1
		move.l  #4-1,d1
setscreens:
		move.l  d0,(a1)+
		add.l	#(320*200*4)/8,d0
		dbra    d1,setscreens

                clr.l   d5

                lea     screenptr,a1
                move.l  (a1),a0

                lea     graphic,a2

                moveq   #8-1,d3        ; 4 screens make up the animation

screen_loop:
                move.w  #25-1,d2       ;25 tiles fill the whole screen

line: 
                moveq   #8-1,d1        ;tiles are 8 pixel high
                move.l  a2,a1

tile:
                moveq   #10-1,d0        ;10 32 pixel wide tiles per scanline
                movem.w (a1),d6-d7 

fill:           move.w  d6,(a0)+
		move.w  d5,(a0)+
		move.w  d5,(a0)+
		move.w  d5,(a0)+

                move.w  d7,(a0)+
		move.w  d5,(a0)+
		move.w  d5,(a0)+
		move.w  d5,(a0)+                
                dbf     d0,fill

                add.l   #4,a1         ; move to the next line in the tile
                dbf     d1,tile
                
                dbf     d2,line

                add.l   #4,a2          ; move down one lines in the tile

                dbf     d3,screen_loop

                movem.l pal1(pc),d0-d3
                movem.l d0-d3,$ffff8240.w


                clr.l  d0
                lea    currentscreen,a0
                move.l d0,(a0)
                rts

graphic:        ; Logo, 32 by 8 pixels by 1 bitplane
         	dc.w    $FEFE,$FEFE
                dc.w    $0602,$8202
                dc.w    $0C02,$8202
                dc.w    $18FE,$82FE
                dc.w    $6002,$8202
                dc.w    $C002,$8202
                dc.w    $FEFE,$FEFE
                dc.w    $0000,$0000

 	        dc.w    $FEFE,$FEFE
                dc.w    $0602,$8202
                dc.w    $0C02,$8202
                dc.w    $18FE,$82FE
                dc.w    $6002,$8202
                dc.w    $C002,$8202

pal1:           dc.w    $777,$000,$222,$333
                dc.w    $444,$555,$666,$777
                dc.w    $666,$555,$444,$333
                dc.w    $222,$111,$001,$002

currentscreen   dc.l    1
screenptr       dc.l    4

screens		ds.b    256+(((320*200*4)/8)*8)
