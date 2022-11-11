%include "init.inc"

[org 0]
            jmp 07C0h:start     

%include "a20.inc"

start:
            
            mov ax, cs
            mov ds, ax
            mov es, ax

            mov ax, 0xB800	    	
	    mov es, ax	    	
	    mov di, 0		
	    mov ax, word [msgBack] 	
	    mov cx, 0x7FF 		    	
paint:
	    mov word [es:di], ax
	    add di,2		
	    dec cx		    
	    jnz paint	   	


read_setup:
            mov ax, 0x9000      ; ES:BX = 9000:0000
            mov es, ax          ;
            mov bx, 0           ;

            mov ah, 2           ; ��ũ�� �ִ� �����͸� es:bx �� �ּҷ�  
            mov al, 2           ; 2 ���͸� ���� ���̴�.
            mov ch, 0           ; 0��° Cylinder
            mov cl, 2           ; 2��° ���ͺ��� �б� �����Ѵ�. 
            mov dh, 0           ; Head=0
            mov dl, 0           ; Drive=0  A:����̺�
            int 13h             ; Read!

            jc read_setup            ; ������ ����, �ٽ� ��. 


read_kernel:
            mov ax, 0x8000      ; ES:BX = 8000:0000
            mov es, ax          ;
            mov bx, 0           ;

            mov ah, 2           ; ��ũ�� �ִ� �����͸� es:bx �� �ּҷ�  
            mov al, NumKernelSector ; Ŀ���� ���� �� ��ŭ �д´�.
            mov ch, 0           ; 0��° Cylinder
            mov cl, 4           ; 4��° ���ͺ��� �б� �����Ѵ�. 
            mov dh, 0           ; Head=0
            mov dl, 0           ; Drive=0  A:����̺�
            int 13h             ; Read!

            jc read_kernel      ; ������ ����, �ٽ� ��. 

	    mov dx, 0x3F2	; �÷��� ��ũ ����̺���
	    xor al, al          ; ���͸� ����.
	    out dx, al

	    cli

            call a20_try_loop

            mov	al, 0x11		; PIC�� �ʱ�ȭ
	    out	0x20, al		; ������ PIC
	    dw	0x00eb, 0x00eb		; jmp $+2, jmp $+2
	    out	0xA0, al		; �����̺� PIC
	    dw	0x00eb, 0x00eb

	    mov	al, 0x20		; ������ PIC ���ͷ�Ʈ ������
	    out	0x21, al
	    dw	0x00eb, 0x00eb
	    mov	al, 0x28		; �����̺� PIC ���ͷ�Ʈ ������
   	    out	0xA1, al
	    dw	0x00eb, 0x00eb

	    mov	al, 0x04		; ������ PIC�� IRQ2���� 
	    out	0x21, al		; �����̺� PIC�� ����Ǿ� �ִ�.
	    dw	0x00eb, 0x00eb
	    mov	al, 0x02		; �����̺� PIC�� ������ PIC��
	    out	0xA1, al		; IRQ2���� ����Ǿ� �ִ�.
	    dw	0x00eb, 0x00eb

	    mov	al, 0x01		; 8086 ��带 ����Ѵ�.
	    out	0x21, al
	    dw	0x00eb, 0x00eb
	    out	0xA1, al
	    dw	0x00eb, 0x00eb

	    mov	al, 0xFF		; �����̺� PIC�� ��� ���ͷ�Ʈ�� 
	    out	0xA1, al		; ���� �д�.
  	    dw	0x00eb, 0x00eb
	    mov	al, 0xFB		; ������ PIC�� IRQ2���� ������
	    out	0x21, al		; ��� ���ͷ�Ʈ�� ���� �д�.

	    jmp 0x9000:0000   

	    msgBack db '.', 0x67



	    times 510-($-$$) db 0
            dw 0AA55h

