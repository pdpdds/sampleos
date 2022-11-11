#include "init.h"
#include "process.h"
#include "interrupt.h"
#include "floppy.h"

extern TSS *tss;
extern UserRegisters uRegisters[NUM_MAX_TASK];
extern int CurrentTask;
void printk(int x, int y, char* str);
void print_hex(int x, int y, int num);
void interrupt_A();
void LoadUserPrograms();


void start_kernel()
{
	unsigned int* FirstTaskURegisters = 
		(unsigned int*) &(uRegisters[0]);

	init_task();        // �½�ũ���� �ʱ�ȭ�Ѵ�.
	SetInterrupts();    // IDT ���� ������ �Ѵ�.

	LoadUserPrograms(); // ���� ���α׷��� 
	                    // ��ũ�� ���� �о� ���δ�.

	// ù ��° ���� ���α׷��� ���� ��Ų��.
	__asm__ __volatile__ (
			"cli                    \n\t"
	                "mov $0x20, %%ax        \n\t"
	                "ltr %%ax               \n\t"
			"mov %%esp, %0          \n\t"
			"mov %1, %%esp          \n\t"
			"popal                  \n\t"
			"pop %%ds               \n\t"
			"pop %%es               \n\t"
			"pop %%fs               \n\t"
			"pop %%gs               \n\t"
			"sti                    \n\t"
			"iret                   \n\t"
			: "=m"(tss->esp0)	
		       	: "m"(FirstTaskURegisters));

	// �̰����δ� ������ �ʾƾ� �Ѵ�.
	while(1);

}

	
void LoadUserPrograms()
{
	// floppy.c �� �ִ� ReadSector() �Լ��� ����Ѵ�.

	ReadSector( 0, 0, 15,
		(unsigned char*)0x10000, (unsigned char*)0x80000000);	

	ReadSector( 0, 0, 16,
		(unsigned char*)0x10000, (unsigned char*)0x80000200);	

	ReadSector( 0, 0, 17,
		(unsigned char*)0x10000, (unsigned char*)0x80001000);	

	ReadSector( 0, 0, 18,
		(unsigned char*)0x10000, (unsigned char*)0x80001200);	

	ReadSector( 1, 0, 1,
		(unsigned char*)0x10000, (unsigned char*)0x80002000);	

	ReadSector( 1, 0, 2,
		(unsigned char*)0x10000, (unsigned char*)0x80002200);	

	ReadSector( 1, 0, 3,
		(unsigned char*)0x10000, (unsigned char*)0x80003000);	

	ReadSector( 1, 0, 4,
		(unsigned char*)0x10000, (unsigned char*)0x80003200);	
}

void printk(int x, int y, char* str)  // ȭ�鿡 ���ڸ� ����ϴ� �Լ�
{
	if(x >= 80 || y >= 25)
		return;

	 unsigned char * p = ( unsigned char *) 0xB8000+x*2+80*y*2;

	while(*str != 0)
	{
		*p = *str;
		p++;
		*p = 0x06;
		p++;
		str++;
	}
}

void print_hex(int x, int y, int num)  // ȭ�鿡 16���� ���ڸ� ����ϴ� �Լ�
{
	unsigned char vc[9];
	int count;
	unsigned char temp;

	count = 0;
	
	while(count < 8)
	{
		temp = (char) (num >> (4*count)); 
		temp &= 0x0F;
		temp += 0x30;
		if(temp >= ':')
			temp += 7;
		vc[7-count] = temp; 	
		count++;
	}		

	vc[8] = 0;

	printk(x, y, vc);
}



