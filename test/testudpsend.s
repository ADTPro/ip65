.include "../inc/common.i"
.include "../inc/petscii.i"

	.import dbgout16


	.import ip65_init
	.import ip65_process

	.import udp_add_listener
	.import udp_callback
	.import udp_send

	.import udp_inp
	.import udp_outp

	.importzp udp_data
	.importzp udp_len
	.importzp udp_src_port
	.importzp udp_dest_port

	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len

	.importzp ip_src
	.import ip_inp


	.zeropage

pptr:		.res 2


	.bss

cnt:		.res 1
replyaddr:	.res 4
replyport:	.res 2
idle		= 1
recv		= 2
resend		= 3


	.segment "STARTUP"

	.word basicstub		; load address

basicstub:
	.word @nextline
	.word 2003
	.byte $9e
	.byte <(((init / 1000) .mod 10) + $30)
	.byte <(((init / 100 ) .mod 10) + $30)
	.byte <(((init / 10  ) .mod 10) + $30)
	.byte <(((init       ) .mod 10) + $30)
	.byte 0
@nextline:
	.word 0


	.code

init:
	jsr ip65_init
	bcc :+

	ldax #failmsg
	jmp print

:	ldax #startmsg
	jsr print

	ldax #udp_in
	stax udp_callback
	ldax #3172
	jsr udp_add_listener
	bcc main

	ldax #udpfailmsg
	jsr print
	rts

main:
	jsr ip65_process

	;lda $c6
	;beq main
	;dec $c6

send:
	ldx #3
:	lda serverip,x			; set destination
	sta udp_send_dest,x
	dex
	bpl :-

	ldax #3172			; set source port
	stax udp_send_src_port

	ldax #3172			; set dest port
	stax udp_send_dest_port

	ldax #udpsendend - udpsendmsg	; set length
	stax udp_send_len

	ldax #udpsendmsg
	jsr udp_send

	jmp main


udp_in:
	lda udp_inp + udp_src_port + 1
	sta replyport
	lda udp_inp + udp_src_port
	sta replyport + 1

	ldx #3
:	lda ip_inp + ip_src,x
	sta replyaddr,x
	dex
	bpl :-

	lda udp_inp + udp_len + 1
	sec
	sbc #8
	sta cnt
	ldax #udp_inp + udp_data
	stax pptr
	ldy #0
@print:
	lda (pptr),y
	cmp #10
	bne :+
	lda #13
:	jsr $ffd2
	iny
	cpy cnt
	bne @print

	rts


print:
	sta pptr
	stx pptr + 1
	ldy #0
:	lda (pptr),y
	beq :+
	jsr $ffd2
	iny
	bne :-
:	rts


	.rodata

startmsg:
	.byte petscii_clear, petscii_lower, "LISTENING FOR REPLIES ON PORT 3172", 13, 0

failmsg:
	.byte petscii_lower, "rr-nET INIT FAILED", 13, 0

udpfailmsg:
	.byte "udp LISTEN FAILED", 13, 0

udpsendmsg:
	.byte "Hello, world!", 13, 10
udpsendend:

serverip:
	.byte 192, 168, 0, 2
