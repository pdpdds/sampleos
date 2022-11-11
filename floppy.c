#include "floppy.h"

#define READ_SECTOR_HEAD_DRIVE 1
#define READ_SECTOR_TRACK 2
#define READ_SECTOR_HEAD 3
#define READ_SECTOR 4

#define SEEK_HEAD_DRIVE 1
#define SEEK_CYLINDER 2

unsigned int floppy_code_read_sector[9] =   // �� ���͸� �б� ���� ���α׷� �ڵ�
{ 0x66, 0x00, 0x00, 0x00, 0x00, 0x02, 18, 0x1b, 0x00 };

unsigned int floppy_code_calibrate[2] =     // Calibrate ���α׷� �ڵ�
{ 0x07, 0x00 }; 

unsigned int floppy_code_seek[3] =          // Seek ���α׷� �ڵ�
{ 0x0F, 0x00, 0x00 };

unsigned int floppy_code_interrupt_status = 0x08;
                                            // ���ͷ�Ʈ Ȯ�� ���α׷� �ڵ�
int g_FloppyInterrupted = 0;
int cont = 0;

static int interrupt_count = 1;

char result_seek[7];

void ReadIt();

void ReadSector(int head, int track, int sector, unsigned char* source, unsigned char* destinity)
{
	int i;
	int page, offset;
	unsigned int src, dest;
	char result[7];

	src = (unsigned int) source;
	dest = (unsigned int) destinity;

	page = (int) (src >> 16);            // ������ ��ȣ
	offset = (int) (src & 0x0FFFF);      // ������ �ȿ����� ������

	FloppyMotorOn();                     // ����̺� ���� ON
	delay(20);

	for(i=0; i<5; i++)
	{
		/* 5���� �õ����� �ΰ��� ������ ��� 
		 * �������� �Ѵ�.
		 * �ϳ��� �����ϸ� �ٽ� �ϸ�,
		 * �� ������ ���ļ� 5�� �õ��� �Ͽ�
		 * �ȵǸ� �׳� �Ѿ */

		if(!FloppyCalibrateHead())   // Calibrate 
			continue;

		if(!FloppySeek(head, track)) // Seek
			continue;
		else 
			break;
	}

	initializeDMA(page, offset);     // DMA�� �ʱ�ȭ

	// head, track, sector ���� �����Ѵ�.
	floppy_code_read_sector[READ_SECTOR_HEAD_DRIVE] = head << 2;
	floppy_code_read_sector[READ_SECTOR_TRACK] = track;
	floppy_code_read_sector[READ_SECTOR_HEAD] = head;
	floppy_code_read_sector[READ_SECTOR] = sector;


	g_FloppyInterrupted = 0;
	
	for(i=0; i<9; i++)     
	{
		WaitFloppy();            // FDC�� �غ� �������� Ȯ��
		FloppyCode(floppy_code_read_sector[i]);
		                         // �� ���͸� �д´�.
	}

	while(!g_FloppyInterrupted);     // ���ͷ�Ʈ�� �ɸ� �� ���� 
	g_FloppyInterrupted = 0;         // ��ٸ���.
	
	delay(20);
	
	for(i=0; i<7; i++) 
	{
		WaitFloppy();
		result[i] = ResultFhase(); // ��� ���� Ȯ���Ѵ�.
	}

	WaitFloppy();
	FloppyMotorOff();                 // ���͸� ����.	

	for(i=0; i<512; i++)
		destinity[i] = source[i]; // DMA �� �о� ���� �����͸� 
                                          // ����ϱ� ���� ������ 
					  // �ű��.
	return 1;
}

int FloppyCalibrateHead()
{
	int i;
	char result[2];

	for(i=0; i<2; i++)
	{
		WaitFloppy();
		FloppyCode(floppy_code_calibrate[i]);
		                           // Calibrate �Ѵ�.
	}
	delay(20);

	WaitFloppy();
	FloppyCode(floppy_code_interrupt_status);
	                                   // ���ͷ�Ʈ�� �ɷȴ���
					   // Ȯ���Ѵ�.

	WaitFloppy();
	result[0] = ResultFhase();         // ��� ���� Ȯ���Ѵ�.
	WaitFloppy();
	result[1] = ResultFhase();
	
	if(result[0] != 0x20)              // 0x20�� ���;� �Ѵ�. 
		return 0;
	else
		return 1;

}

int FloppySeek(int head, int cylinder)
{
	int i, j;
	char result[7];

	// cylinder�� head�� �����Ѵ�.
	floppy_code_seek[SEEK_CYLINDER] = cylinder;
	floppy_code_seek[SEEK_HEAD_DRIVE] = head << 2;

	g_FloppyInterrupted = 0;

	for(i=0; i<3; i++)
	{
		WaitFloppy();
		FloppyCode(floppy_code_seek[i]);
		                          // Seek �Ѵ�.
	}
	
	while(!g_FloppyInterrupted);      // ���ͷ�Ʈ�� ��ٸ���.

	delay(20);

	WaitFloppy();
	FloppyCode(floppy_code_interrupt_status);
	                                  // FDC �������ͷ� 
					  // ���ͷ�Ʈ�� Ȯ���Ѵ�.

	WaitFloppy();
	result[0] = ResultFhase();        // ��� ���� Ȯ���Ѵ�.
	WaitFloppy();
	result[1] = ResultFhase();

	if(result[0] != 0x20)             // 0x20 �� ���;� �Ѵ�.
		return 0;

	WaitFloppy();
	FloppyCode(0x4a);                 // Sector ID�� �д´�.
	WaitFloppy();
	FloppyCode((head << 2));
	for(i=0; i<7; i++)
	{
		WaitFloppy();
		result_seek[i] = ResultFhase();
	}


	if(result_seek[3] != cylinder)
		return 0;
	else
		return 1;

}

void FloppyCode(unsigned int code)
{
	outb(0x3F5, code);          // 0x3F5 �������Ϳ� �� ����Ʈ�� 
	                            // ���α׷� �Ѵ�.
}

void WaitFloppy()                   // FDC�� �غ���� ���θ� Ȯ��.
{
	unsigned int result;

	while(1)
	{
		result = inb(0x3F4);  

		if((result & 0x80) == 0x80)
			break;
	}
}

void FloppyHandler()                // IRQ6�� ���ͷ�Ʈ �ڵ鷯
{
	g_FloppyInterrupted = 1;	
}
