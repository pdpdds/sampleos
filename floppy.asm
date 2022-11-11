segment .text

[global _FloppyMotorOn]
[global _FloppyMotorOff]
[global _initializeDMA]
[global _FloppyCode]
[global _ResultFhase]
[global _inb]
[global _outb]

_FloppyMotorOn:
	push edx
	push eax

	mov al, 0x1c
	mov dx, 0x3f2
	out dx, al

	pop eax
	pop edx
ret




_FloppyMotorOff:
	push edx
	push eax

        mov dx, 0x3F2	; �÷��� ��ũ ����̺���
        xor al, al      ; ���͸� ����.
        out dx, al	
	
	pop eax
	pop edx
ret




_initializeDMA:
	push ebp
	mov ebp, esp

	push eax	

	mov al, 0x14
	out 0x08, al       ; DMA�� deactive �Ѵ�.

	mov al, 1
	out 0x0c, al       ; flip-flop �� �����Ѵ�.

	mov al, 0x56
	out 0x0b, al       ; mode register

	mov al, 1          ; flip-flop �� �����Ѵ�.
	out 0x0c, al       

	mov eax, dword [ebp+0x0C] 
	out 0x04, al       ; �������� Low byte
	mov al, ah
	out 0x04, al       ; �������� High byte 

	mov eax, dword [ebp+0x08]
	out 0x81, al       ; Page 

	mov al, 1
	out 0x0c, al       ; flip-flop �� �����Ѵ�.

	mov al, 0xff
	out 0x05, al       ; count �� Low byte

	mov al, 1
        out 0x05, al       ; count �� High byte

	mov al, 0x02
	out 0x0a, al       ; channel 2�� mask ����

	mov al, 0x10
	out 0x08, al       ; DMA active ���·� �Ѵ�.

	pop eax

	mov esp, ebp
	pop ebp
ret

; I/O ��Ʈ�� �о� ���δ�.
_inb:   
	push ebp
	mov ebp, esp

	push edx
	
	xor eax, eax
	mov edx, dword [ebp+0x08]
	in al, dx

	pop edx

	mov esp, ebp
	pop ebp
ret

; I/O ��Ʈ�� ����Ѵ�.
_outb:
	push ebp
	mov ebp, esp

	push eax
	push edx
	
	xor eax, eax
	mov eax, dword [ebp+0x0C]
	mov edx, dword [ebp+0x08]
	out dx, al

	pop edx
	pop eax

	mov esp, ebp
	pop ebp
ret

; FDC���� ��� ���� �����´�.
_ResultFhase:
	push edx

	mov dx, 0x3F5
	in al, dx

	pop edx
ret	







