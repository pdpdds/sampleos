%include "init.inc"

PAGE_DIR        equ 0x100000
PAGE_TAB_KERNEL equ 0x101000
PAGE_TAB_USER   equ 0x102000
PAGE_TAB_LOW    equ 0x103000

[org 0x90000]
[bits 16]
start:
	cld			
	mov	ax,cs
	mov	ds,ax
	xor	ax,ax
	mov	ss,ax

	xor eax, eax
   	lea eax,[tss]          ; EAX�� tss�� �����ּҸ� �ִ´�.
	add eax, 0x90000
    	mov [descriptor4+2],ax
    	shr eax,16
   	mov [descriptor4+4],al
    	mov [descriptor4+7],ah

	cli
        lgdt[gdtr]

        mov eax, cr0
        or eax, 0x00000001
        mov cr0, eax

      
        jmp dword SysCodeSelector:PM_Start



[bits 32]

PM_Start:
	
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx

	lea esp, [PM_Start]

        mov esi, 0x80000              ; Ŀ���� �����ּ� 0x200000 �� �ű��.
        mov edi, 0x200000
        mov cx, 512*NumKernelSector
kernel_copy:
        mov al, byte [ds:esi]
        mov byte [es:edi], al
        inc esi
        inc edi
        dec cx
        jnz kernel_copy



	mov edi, PAGE_DIR
	mov eax, 0                 ; not present
	mov ecx, 1024              ; ������ ����
	cld
	rep stosd

        mov edi, PAGE_DIR
        mov eax, 0x103000
        or  eax, 0x01
        mov [es:edi], eax        
	
	mov edi, PAGE_DIR+0x200*4  ; 0x80000000 �� ���� 10��Ʈ*4
	mov eax, 0x102000
	or eax, 0x07               ; ���� �������� ǥ��
	mov [es:edi], eax

	mov edi, PAGE_DIR+0x300*4  ; 0xC0000000 �� ���� 10��Ʈ*4
        mov eax, 0x101000
        or eax, 0x01               ; Ŀ�� �������� ǥ��
        mov [es:edi], eax

        mov edi, PAGE_TAB_KERNEL   ; 0x101000 ~ 0x101FFF ���� not present �� �ʱ�ȭ �Ѵ�.
	mov eax, 0                 ; not present
	mov ecx, 1024              ; ������ ����
	cld
	rep stosd	

        mov edi, PAGE_TAB_KERNEL+0x000*4
        mov eax, 0x200000          ; Ŀ���� 2���� �������� ����Ѵ�.
        or  eax, 1                 ; 0x200000 ���� 4096*2 ����Ʈ�� �����̴�.
        mov [es:edi], eax          ; ���� �޸� 0xC0000000 ���� 4096*2 ����Ʈ�� ����

        mov edi, PAGE_TAB_KERNEL+0x001*4
        mov eax, 0x201000
        or  eax, 1
        mov [es:edi], eax

        mov edi, PAGE_TAB_KERNEL+0x002*4
        mov eax, 0x202000          ; IDT�� ����ϴ� ������ 
        or  eax, 1                 ; ������忡���� �����ϸ� �ȵ�.
        mov [es:edi], eax

        mov edi, PAGE_TAB_USER     ; 0x102000 ~ 0x102FFF ���� not present �� �ʱ�ȭ �Ѵ�.
	mov eax, 0x00              ; not present
	mov ecx, 1024              ; ������ ����
	cld
	rep stosd	

        mov edi, PAGE_TAB_USER+0x000*4
        mov eax, 0x300000          ; ���� ���α׷�1�� ����
        or  eax, 0x07              ; ���� �޸� 0x300000 ���� 4096 ����Ʈ ��ŭ�� ����
        mov [es:edi], eax          ; ���� �޸� 0x80000000 ���� 4066 ����Ʈ ��ŭ�� ����

        mov edi, PAGE_TAB_USER+0x001*4
        mov eax, 0x301000          ; ���� ���α׷�2�� ����
        or  eax, 0x07              
        mov [es:edi], eax

        mov edi, PAGE_TAB_USER+0x002*4
        mov eax, 0x302000          ; ���� ���α׷�3�� ����
        or  eax, 0x07
        mov [es:edi], eax

        mov edi, PAGE_TAB_USER+0x003*4
        mov eax, 0x303000          ; ���� ���α׷�4�� ����
        or  eax, 0x07
        mov [es:edi], eax

        mov edi, PAGE_TAB_USER+0x004*4
        mov eax, 0x304000          ; ���� ���α׷�5�� ����
        or  eax, 0x07
        mov [es:edi], eax

        mov edi, PAGE_TAB_LOW      ; 1MB ������ ������  
        mov eax, 0x00000           ; 256 ���� �������� ������.
        or  eax, 0x01              ; 256*4096 = 1048576 = 0x100000  
        mov cx, 256
page_low_loop:
        mov [es:edi], eax
        add eax, 0x1000
	add edi, 4
        dec cx
        jnz page_low_loop

	mov eax, PAGE_DIR          ; ������ ���丮�� �� �� �ּҸ�
	mov cr3, eax               ; CR3 �������Ϳ� ����Ѵ�.

	mov eax, cr0               ; CR0 �������Ϳ� 
	or eax, 0x80000000         ; ���� ���� ����¡ ������ ����Ѵٴ�
	mov cr0, eax               ; ǥ�ø� �Ѵ�.

        lea eax, [tss]             ; C���� �̷���� kernel.bin ���� 
        mov [TSS_WHERE], eax       ; TSS�� ����ϹǷ�, TSS��  
                                   ; �ּҸ� ����� �д�.
	mov esp, 0xC0001FFF        ; Ŀ�� ����� �����ּҸ�
                                   ; Ŀ���� ��ġ�� �������� ���� ������ �κ���
                                   ; ����Ű�� �صд�.

        jmp 0xC0000000             ; Ŀ�η� �����Ѵ�.


;***************************************
;**********   Data Area   **************
;***************************************
gdtr:	
	dw gdt_end-gdt-1
    dw	gdt_end-gdt
	dd	gdt
gdt:
	dd 0, 0
	dd 0x0000FFFF, 0x00CF9A00
	dd 0x0000FFFF, 0x00CF9200
	dd 0x8000FFFF, 0x0040920B

descriptor4:				;TSS ��ũ����
	dw 104
	dw 0
	db 0
	db 0x89
	db 0
	db 0

	dd	0x0000FFFF, 0x00FCFA00  ;���� �ڵ� ���׸�Ʈ
	dd	0x0000FFFF, 0x00FCF200  ;���� ������ ���׸�Ʈ
gdt_end:




tss: 
   	 dw 0, 0                ; ���� �½�ũ���� back link
tss_esp0:
    	dd 0xC0001FFF           ; ESP0
        dw SysDataSelector, 0   ; SS0, ������
        dd 0                    ; ESP1
        dw 0, 0                 ; SS1, ������
   	dd 0                    ; ESP2
    	dw 0, 0                 ; SS2, ������
   	dd 0x100000
tss_eip:
        dd 0, 0                 ; EIP, EFLAGS
        dd 0, 0, 0, 0
tss_esp:
        dd 0, 0, 0, 0           ; ESP, EBP, ESI, EDI
        dw 0, 0                 ; ES, ������
        dw 0, 0                 ; CS, ������
        dw UserDataSelector, 0 	; SS, ������
        dw 0, 0                 ; DS, ������
        dw 0, 0                 ; FS, ������
        dw 0, 0                 ; GS, ������
        dw 0, 0                 ; LDT, ������
        dw 0, 0                 ; ����׿� T��Ʈ, IO �㰡 ��Ʈ��


times 1024-($-$$) db 0

