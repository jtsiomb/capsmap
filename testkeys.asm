; DOS utility to print scancodes and keyboard flags
; Author: John Tsiombikas <nuclear@member.fsf.org>
; This program is public domain. Do whatever you like with it
; build with: nasm -o testkeys.com -f bin testkeys.asm
	org 100h
	bits 16

	; save original cursor size and hide cursor
	mov ah, 3
	xor bh, bh
	int 10h
	mov [orig_cursz], cx
	mov ah, 1
	mov cx, 2000h
	int 10h

	call clearscr
	mov ax, 0300h
	call setcursor

	mov ax, 0900h
	mov dx, msg
	int 21h

	; use es to access BIOS data area at segment 40h
	push word 40h
	pop es

mainloop:
	call get_scancode
	cmp ax, 2e03h
	jz .done
	cmp ax, 0
	jz .skip_print
	call print_hex	; print scancode
.skip_print:
	call print_flags
	jmp mainloop
.done:
	; restore cursor and exit
	mov ah, 1
	mov cx, [orig_cursz]
	int 10h
	mov ax, 4c00h
	int 21h

orig_cursz dw 0
msg db 'Press Ctrl-C to stop',13,10,'$'

BHEAD_OFF equ 1ah
BTAIL_OFF equ 1ch
KBUF_BEG equ 1eh
KBUF_END equ 3eh
KBUF_MASK equ 1fh

KBFLAGS0 equ 17h
KBFLAGS1 equ 18h


; returns scancode in ax, or 0 if there aren't any pending
get_scancode:
	xor ax, ax
	mov si, [es:BHEAD_OFF]
	cmp si, [es:BTAIL_OFF]
	jz .end
	mov ax, [es:si]
	add si, 2
	cmp si, KBUF_END
	jnz .nowrap
	mov si, KBUF_BEG
.nowrap:
	mov [es:BHEAD_OFF], si
.end:	ret

; expects a 16bit value in ax and prints it in hex
print_hex:
	rol ax, 4
	call print_hex_nibble
	rol ax, 4
	call print_hex_nibble
	rol ax, 4
	call print_hex_nibble
	rol ax, 4
	call print_hex_nibble

	push dx
	mov ax, 0900h
	mov dx, hex_suffix
	int 21h
	pop dx
	ret

hex_suffix db 'h  $'

; expects a nibble in al[0:4] and prints it
print_hex_nibble:
	push ax
	push dx
	and al, 0fh
	cmp al, 9
	ja .over9
	; nibble is 9 or less
	add al, '0'
	jmp .print
.over9: ; nibble is a or more
	add al, 'a'-10
.print: mov dl, al
	mov ah, 6
	int 21h
	pop dx
	pop ax
	ret

topline db 'FL: ins cap num scr alt ctl lsh rsh     FL: ins cap num scr sus sys lalt lctl$'
secline db 'G0: act act act act prs prs prs prs     G1: prs prs prs prs tog act prs prs$'
bitsep db '   $'
bytesep db '        $'

print_flags:
	call getcursor
	push ax
	xor ax, ax
	call setcursor
	mov ah, 9
	mov dx, topline
	int 21h
	mov ax, 100h
	call setcursor
	mov ah, 9
	mov dx, secline
	int 21h
	mov ax, 205h
	call setcursor

	mov al, [es:KBFLAGS0]
	call printbin

	mov ah, 9
	mov dx, bytesep
	int 21h

	mov al, [es:KBFLAGS1]
	call printbin

	pop ax
	call setcursor
	ret

printbin:
	mov cx, 8
.loop:
	rol al, 1
	push ax
	and al, 1
	add al, '0'
	mov dl, al
	mov ah, 6
	int 21h
	mov ah, 9
	mov dx, bitsep
	int 21h
	pop ax
	dec cx
	jnz .loop
	ret

; expects column in al, row in ah
setcursor:
	push bx
	push dx
	mov dx, ax
	xor bh, bh
	mov ah, 2
	int 10h
	pop dx
	pop bx
	ret

; returns column in al, row in ah
getcursor:
	push bx
	push cx
	mov ah, 3
	xor bh, bh
	int 10h
	mov ax, dx
	pop cx
	pop bx
	ret

clearscr:
	mov ax, 600h
	mov bh, 07h
	xor cx, cx
	mov dx, 184fh
	int 10h
	ret

; vi:set filetype=nasm ts=8:
