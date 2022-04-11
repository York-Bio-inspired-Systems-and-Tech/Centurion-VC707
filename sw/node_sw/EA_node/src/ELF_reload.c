
#include "xbasic_types.h"
#include "ELF_reload.h"

#define LOADER_TX_BUFF_SIZE 2048
#define LOADER_RX_BUFF ((volatile unsigned int*)(0xC1000000 + (4*LOADER_TX_BUFF_SIZE)))
#define LOADER_NOC_CNTRL_IF (volatile unsigned int*)(0xC0000000)
#define LOADER_NOC_STATUS_IF (volatile unsigned int*)(0xC0000004)
#define LOADER_NOC_RX_LEN_IF (volatile unsigned int*)(0xC000000C)


Xuint32 data_counter __attribute__ ((section (".reloader_vars")));
void Loader_ACK_RX() __attribute__ ((section (".reloader")));
Xuint32 Loader_NoC_Read_Blocking() __attribute__ ((section (".reloader")));

//

#define MAX_SECTIONS 4
Xuint8 num_sections __attribute__ ((section (".reloader_vars")));
Xuint16 reconf_packet_data_size __attribute__ ((section (".reloader_vars")));

#define LEDS *(volatile Xuint32*)0x80000010
#define LOADER_DEBUG_IN *(volatile Xuint32*)0x80000024
#define NOC_NODE_ID_REG (volatile Xuint32*)(0xC0000014)

//the init barrier sync waits for either the sync value of the magic byte "BE" in which case it enters the reload loop
void Init_Barrier_Sync(Xuint8 sync_value, Xuint32 timeout)
{
	if(timeout)
	{
		Xuint32 start = *(volatile Xuint32*)0x80000020;
		while((*(volatile Xuint32*)0x80000020) - start < timeout)
		{
			Xuint16 debug_CMD = LOADER_DEBUG_IN & 0x1FF;
			if(debug_CMD == sync_value)
				break;
			if(debug_CMD == 0x1BE)
				reload_elf();
		}
		return;

	}

	while(1)
	{
		Xuint16 debug_CMD = LOADER_DEBUG_IN & 0x1FF;
		if(debug_CMD == sync_value)
			break;
		if(debug_CMD == 0x1BE)
			reload_elf();
	}
	return;
}


void reload_elf()
{
	//the reloader works by receiving ELF sections from the host.
	//it then overwrites all sections aside from itself.
	//it then resets the processor
	//This does mean you cannot call ANY functions that are not "protected"
	//within the reloader section
//	xil_printf("reloading \n");
	LEDS = 0xA1;

	Loader_NoC_Read_Blocking();
	//get segments header from host
	if(LOADER_RX_BUFF[0] != *NOC_NODE_ID_REG)
	{
		LEDS = 0xF5;
		while(1);
	}

	num_sections = LOADER_RX_BUFF[2];
	LEDS = 0xA2;

//	xil_printf("Num sections: %d\n", num_sections);
	reconf_packet_data_size = (LOADER_RX_BUFF[3] << 8) | LOADER_RX_BUFF[4];
	//xil_printf("Data size: %d\n", reconf_packet_data_size);
	Loader_ACK_RX();

	int i;

	for(i=0; i<num_sections; i++)
	{
		Loader_NoC_Read_Blocking();
		Xuint16 seg_addr = (LOADER_RX_BUFF[2] << 8) | LOADER_RX_BUFF[3];
//	xil_printf("Segment %d address : %x\n", i, seg_addr);
		Xuint16 seg_size = (LOADER_RX_BUFF[4] << 8) | LOADER_RX_BUFF[5];
	//	xil_printf("Segment %d size : %d\n", i,seg_size);
		Xuint8 num_packets = LOADER_RX_BUFF[6];
//		xil_printf("Segment %d num_packets : %d\n", i,num_packets);

		Xuint8 *data_wr_addr = seg_addr;
		Loader_ACK_RX();
		int j;
		for(j=0; j<num_packets; j++)
		{
	//		xil_printf("Packet %d/%d waiting\n", j,num_packets);
			Loader_NoC_Read_Blocking();
	//		xil_printf("Header %x\n", LOADER_RX_BUFF[0]);

			int k, num_bytes;
			if(j == num_packets -1)
				num_bytes = seg_size;
			else
				num_bytes = reconf_packet_data_size;
			for(k=0; k < num_bytes; k++)
			{
				*data_wr_addr = (Xuint8)(LOADER_RX_BUFF[k+2] & 0xFF);
				data_wr_addr++;
			}
			seg_size -= num_bytes;
			Loader_ACK_RX();
		}
	}
	LEDS = 0xA3;
	//wait for new status to proceed
	while(1)
	{
		Xuint16 debug_CMD = LOADER_DEBUG_IN & 0x1FF;
		if(debug_CMD == 0x130)
			break;
	}


//	(*((void (*)())(0x00)))(); // restart

	void (*func)() = (*((void (*)())(0x00)));
	func();

}


void Loader_ACK_RX()
{
	*LOADER_NOC_CNTRL_IF = 0x02;
	*LOADER_NOC_CNTRL_IF = 0x00;
}

Xuint32 Loader_NoC_Read_Blocking()
{
	while(((*LOADER_NOC_STATUS_IF) & 0x01) ==0 );
	Xuint32 RX_size = *LOADER_NOC_RX_LEN_IF;
	return RX_size;
}
