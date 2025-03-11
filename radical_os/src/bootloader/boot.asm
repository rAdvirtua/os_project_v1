org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

;
; FAT-12 header
;
jmp short start
nop

bdb_oem:                    db 'MSWIN4.1'           ; 8 bytes
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" floppy disk
bdb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

; extended boot record
ebr_drive_number:           db 0                    ; 0x00 floppy, 0x80 hdd, useless
                            db 0                    ; reserved
ebr_signature:              db 29h
ebr_volume_id:              db 12h, 34h, 56h, 78h   ; serial number, value doesn't matter
ebr_volume_label:           db 'RADICAL  OS'        ; 11 bytes, padded with spaces
ebr_system_id:              db 'FAT12   '           ; 8 bytes


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
	mov ax, 0  		  ; can't write to ds/es directly
	mov ds, ax
	mov es, ax
	
	; setup stack
	mov ss, ax
	mov sp, 0x7C00 	  ; Stack grows downward from 0x7C00

	; read something from floppy disk
	; BIOS should set DL to drive number
	mov [ebr_drive_number], dl

	mov ax, 1 	  	  ; LBA=1, second sector from disk 
	mov cl, 1		  ; 1 sector to read 
	mov bx, 0x7E00	  ; data should be after the bootloader
	call disk_read
    
    ; print message
	mov si, msg_hello
	call puts

	cli    ; Disable interrupts (important before `hlt`)
	hlt    ; Halt execution

;
; Error handlers
;
floppy_error:
	mov si, msg_read_failed
	call puts
	jmp wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h         ;wait for keypress
	jmp 0FFFFh:0    ;jump to beginning of BIOS, should reboot 



.halt:  
    cli				; disable interrupts
	hlt 




;
; Disk Routines
;


;
; Converts an LBA address to a CHS address 
;

lba_to_chs:

	xor dx, dx                            ; dx = 0
	div word [bdb_sectors_per_track]      ; ax = LBA/SectorsPerTrack
	                                      ; dx = LBA%SectorsPerTrack
    inc dx                                ; dx = LBA%SectorsPerTrack + 1
	mov cx, dx                            ; cx = sector


	xor dx, dx                            ; dx = 0
	div word [bdb_heads]                  ; ax = (LBA/SectorsPerTrack) / Heads = cylinder
	                                      ; dx = (LBA/SectorsPerTrack) % Heads = head
    mov dh, dl                            ; dl = head
	mov ch, al                            ; ch = cylinder (lower 8 bits)
	shl ah, 6
	or cl, ah                             ; put upper 2 bits of cylinder in CL

	pop ax
    mov dl, al
	pop ax
	ret

;
; Reads Sectors from a disk
; 
disk_read:

	push ax
	push bx
	push cx
	push dx
	push di

	push cx								  ; temporarily save CL (number of sectors to read)
	call lba_to_chs						  ; compute CHS
	pop ax 								  ; AL = number of sectors to read

	mov ah, 02h
	mov di, 3							  ; retry count

.retry:
	pusha                                 ; save all registers we don't know what bios modifies 
	stc									  ; set carry flag
	int 13h								  ; carry flag = success 
	jnc .done 							  ; jump if carry not set
    
	;read failed
	popa
    call disk_reset
    
    dec di
	test di, di
	jnz .retry

.fail:
	; all attempts are exhausted
	jmp	floppy_error


.done:
	popa

	push di
	push dx 
	push cx
	push bx
	push ax 
	ret



disk_reset:
	pusha
	mov ah, 0
	stc 
	int 13h
	jc floppy_error
	popa
	ret 



msg_hello: 					db 'Hello world!', ENDL, 0
msg_read_failed: 			db 'Read from disk failed!', ENDL, 0 

times 510-($-$$) db 0   ; Fill up to 510 bytes
dw 0xAA55  ; Boot signature
