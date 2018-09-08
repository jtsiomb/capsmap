; DOS caps lock remapper
; Author: John Tsiombikas <nuclear@member.fsf.org>
; This program is public domain. Do whatever you like with it
; build with: nasm -o capsmap.com -f bin capsmap.asm

; ---------------------------------------------------------------------
; Configuration section
; ---------------------------------------------------------------------
; You can either map caps lock to a modifier key, such as ctrl, shift,
; and alt, or you can map it to a regular key.
;
; To map caps lock to modifier keys you first need to define MAP_MODKEY.
%define MAP_MODKEY
; And then define the bit to set/clear in the BIOS keyboard flag bytes.
; Here is a list of values to use as KBF0_BIT and KBF1_BIT:
;   - left CTRL   04h and 01h
;   - right CTRL  04h and 0
;   - left ALT    08h and 02h
;   - right ALT   08h and 0
;   - left SHIFT  02h and 0
;   - right SHIFT 01h and 0
KBF0_BIT equ 04h
KBF1_BIT equ 01h

; To map caps lock to regular keys, comment out the MAP_MODKEY above,
; and define the 16bit number to append to the BIOS keyboard buffer
; when caps lock is pressed. The high order byte should be the set 1
; scancode, and the low order byte should be the ASCII value.
; For instance for the escape key, use 011bh (scancode 01h, ASCII 27).
SCANCODE equ 011bh
; You can use the accompanying testkeys tool, to figure out exactly
; which scancode/ascii combination to use for any particular key.
; ---------------------------------------------------------------------

	org 100h
	bits 16

	; jump over resident part to the init code at the end
	jmp init

KB_INTR equ 09h
KB_PORT equ 60h
PIC1_CMD_PORT equ 20h
OCW2_EOI equ 20h

KBFLAGS0 equ 17h
KBFLAGS1 equ 18h

SCAN_CAPS_PRESS equ 03ah
SCAN_CAPS_RELEASE equ 0bah

kbintr:
	push ax
	in al, KB_PORT
	cmp al, SCAN_CAPS_PRESS
	jz .caps_press
	cmp al, SCAN_CAPS_RELEASE 
	jz .caps_release
	; otherwise jump to the original handler
	pop ax
	push word [cs:orig_seg]
	push word [cs:orig_off]
	retf

	; key press
.caps_press:
%ifdef MAP_MODKEY
	; set ctrl flags
	mov ax, es
	push word 40h
	pop es
	or byte [es:KBFLAGS0], KBF0_BIT
	or byte [es:KBFLAGS1], KBF1_BIT
	mov es, ax
%else
	mov ax, SCANCODE
	call append_key
%endif
	jmp .end

	; key release
.caps_release:
%ifdef MAP_MODKEY
	; clear ctrl flags
	mov ax, es
	push word 40h
	pop es
	and byte [es:KBFLAGS0], ~KBF0_BIT
	and byte [es:KBFLAGS1], ~KBF1_BIT
	mov es, ax
%endif

	; signal end of interrupt to the PIC and return
.end:	mov al, OCW2_EOI
	out PIC1_CMD_PORT, al
	pop ax
	iret


%ifndef MAP_MODKEY

BHEAD_OFF equ 1ah
BTAIL_OFF equ 1ch
KBUF_BEG equ 1eh
; mask indices with 1f (to wrap around the 32 byte buffer)
KBUF_MASK equ 1fh

	; append scancode in ax to BIOS keyboard buffer
append_key:
	pusha
	mov cx, ax
	push word 40h
	pop es
	mov dx, [es:BTAIL_OFF]
	mov di, dx
	sub dx, KBUF_BEG

	; find tail pos after append, if equal to head then overflow
	mov ax, dx
	add ax, 2
	and ax, KBUF_MASK
	cmp ax, [es:BHEAD_OFF]
	jz .end

	mov word [es:di], cx	; write scancode to buffer
	add ax, KBUF_BEG
	mov [es:BTAIL_OFF], ax	; update tail pointer

.end:	popa
	ret
%endif

orig_seg dw 0
orig_off dw 0
resident_end:

	; init code, anything from this point on will not stay resident
init:
	mov ax, 0900h
	mov dx, msg
	int 21h

	; get current keyboard interrupt handler
	mov ax, 3509h
	int 21h
	mov [orig_seg], es
	mov [orig_off], bx

	; set our own interrupt handler in its place
	mov ax, 2509h
	mov dx, kbintr
	int 21h

	mov ax, 0900h
	mov dx, msg_done
	int 21h

	; terminate and stay awesome
	mov dx, resident_end
	int 27h


msg db 'Installing capslock remapper... $'
msg_done db 'done.',13,10,'$'
; vi:set filetype=nasm ts=8:
