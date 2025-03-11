org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

#
# FAT-12 header
#
jmp short start
nop

bdb_oem:					db 'MSWIN4.1'			; 8 bytes
bdb_bytes_per_sector:		dw 512 
bdb_sectors_per_cluster:	db 1
bdb_reserved_sectors:		dw 1
bdb_fat_count:				db 2
bdb_dir_entries_count:		dw 0E0h
bdb_total_sectors:			dw 2880
bdb_media_descriptor_type:	db 0F0h
bdb_sectors_per_fat:		dw 9
bdb_sectors_per_track:		dw 18
bdb_heads:					dw 2
bdb_hidden_sectors:			dd 0
bdb_large_sector_count:		dd 0

# extended boot record
ebr_drive_number:			db 0 
							db 0
ebr_signature:				db 29h
ebr_volume_id:				db 12h, 34h, 56h, 78h
ebr_volume_label:			db 'RADICAL OS '  ; 11 characters including spaces
ebr_system_id:				db 'FAT12   '  ; Fixed: 8 characters (padded with spaces)

start:
	jmp main

; 
; Prints a string to the screen
; Params:
;    - ds:si points to the string
puts:
	; save registers we will modify
	push si
	push ax

.loop:
	lodsb	    ; Load next character in AL
	or al, al	; Check if null
	jz .done

	mov ah, 0x0E	; BIOS Teletype (TTY) print
	int 0x10

    jmp .loop 

.done:
	pop ax
	pop si
	ret 

main:
    ; setup data segments
	mov ax, 0  		; can't write to ds/es directly
	mov ds, ax
	mov es, ax
	
	; setup stack
	mov ss, ax
	mov sp, 0x7C00 	; Stack grows downward from 0x7C00
    
    ; print message
	mov si, msg_hello
	call puts

	cli    ; Disable interrupts (important before `hlt`)
	hlt    ; Halt execution

.halt: 
	jmp .halt

msg_hello: db 'Hello world!', ENDL, 0

times 510-($-$$) db 0   ; Fill up to 510 bytes
dw 0xAA55  ; Boot signature
