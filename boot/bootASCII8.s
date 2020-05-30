		.globl __sdcc_banked_call

		.area _BOOT

ENASLT		.equ 0x0024
RSLREG		.equ 0x0138
EXPTBL		.equ 0xfcc1
ASCII8_PAGE1	.equ 0x6800
ASCII8_PAGE2    .equ 0x7000
ASCII8_PAGE3	.equ 0x7800

		.db "A"
		.db "B"
		.dw bootstrap
		.dw 0,0,0,0,0,0

		; At this point the BIOS has detected the cartridge AB signature and
		; jumped here; we have the rom bios in bank 0, ram in bank 3, and rom
		; in bank 1 (this code).

		; Support for nested banked calls on ASCII8_PAGE3
		;   0x8000-0x9FFF
		;
__sdcc_banked_call:
		; save caller and current bank
		pop 	bc
		ld	a,(cur_page)
		ld	iy,#0
		add	iy,sp
		ld 	sp,(banked_sp)
		push	bc
		push	af
		ld 	(banked_sp), sp
		ld 	sp,iy

		ld	iy,#0
		add	iy,bc

		; push return adrress
		ld	hl, #__sdcc_banked_ret
		push 	hl

		; read jump address and target page
		ld	l,(iy)
		ld 	h,1(iy)
		ld	a,2(iy)
		ld 	(cur_page),a

		; switch bank and perform call
		ld 	(ASCII8_PAGE2),a
		jp	(hl)
__sdcc_banked_ret:
		ld	iy,#0
		add	iy,sp
		ld 	sp, (banked_sp)
		pop 	af
		pop 	hl
		ld 	(banked_sp), sp
		ld 	sp,iy

		; restore bank
		ld 	(ASCII8_PAGE2),a
		ld 	(cur_page),a
		inc 	hl
		inc	hl
		inc	hl
		push	hl
		ret

		; The following code sets bank 2 to the same slot as bank 1 and continues
		; execution.
bootstrap:
		ld	a,#2
		ld	(cur_page),a
		ld	hl,#0xf000
		ld	(banked_sp),hl
		ld 	sp,#0xf379
		ld	a,#0xc9
		ld 	(nopret),a
nopret:		nop
		call 	#RSLREG
		call 	getslot
		ld	(biosslot),a
		call 	#RSLREG
		rrca
		rrca
		call 	getslot
		ld	(romslot),a
		ld	h,#0x80
		call 	#ENASLT
		jp 	done
getslot:
		and	#0x03
		ld	c,a
		ld	b,#0
		ld	hl,#EXPTBL
		add	hl,bc
		ld	a,(hl)
		and	#0x80
		jr	z,exit
		or	c
		ld	c,a
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		ld	a,(hl)
		and	#0x0C
exit:
		or	c
		ret
done:
		; Now make sure ASCII8 pages are set properly
		ld 	a,#1
		ld 	(ASCII8_PAGE1),a
		ld 	a,#2
		ld 	(ASCII8_PAGE2),a
		ld 	a,#3
		ld 	(ASCII8_PAGE3),a

		; initialize banked call stack



		.area _DATA
romslot:	.ds 1
biosslot:	.ds 1
cur_page:	.ds 1
banked_sp:	.ds 2
