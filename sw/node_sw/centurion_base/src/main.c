/*
 * main.c
 *
 *  Created on: 10 Jan 2019
 *      Author: mr589
 */
#include "xbasic_types.h"
#include "stdio.h"
#include "NoC_lib.h"
#include "ELF_reload.h"
#include "xiomodule_l.h"

#define LEDS *(volatile Xuint32*)0x80000010
#define DEBUG_IN *(volatile Xuint32*)0x80000024
volatile Xuint8 node_id =0;

//interrupt settings
#define NUM_EXTERNAL_INTERRUPTS 2
void (*ISR_table[NUM_EXTERNAL_INTERRUPTS])();
volatile Xuint8 external_int_en_mask = 0;



Xuint8 RDO_test = 0xCC;

typedef enum {CENTURION_NODE_CMD_NULL, CENTURION_SET_NODE_RDO, CENTURION_GET_NODE_RDO, CENTURION_GET_LOGS_HS} Centurion_Remote_CMDs;
void *RDO_addrs[] = { &RDO_test };

void ISR()
{
        //currently we only check external interrupt bus
        //these start at bit 16
        Xuint32 int_mask = 0x10000;
        Xuint32 int_status = XIOModule_GetIntrStatus(XPAR_IOMODULE_0_BASEADDR);
        int i;

        for(i=0; i<NUM_EXTERNAL_INTERRUPTS; i++)
        {
                //check the interrupt pending reg
                if(int_status & int_mask)
                {
                        //call the ISR
                        ISR_table[i]();
                        //ack the interrupt
                        XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, int_mask);
                }
                int_mask <<= 1;
        }
}

void MB_cmd_ISR() {
	int i;
	DEBUG_OUT = 0xAB;

	//read the command and do an action as required
	Centurion_Remote_CMDs cmd = Debug_Read_Safe();
	switch (cmd) {
	case CENTURION_SET_NODE_RDO: {
		//index
		Xuint8 RDO_index = Debug_Read_Safe();
		Xuint8 *RDO_addr = RDO_addrs[RDO_index];
		//bytes
		Xuint8 RDO_size = Debug_Read_Safe();
		//set data
		for (i = 0; i < RDO_size; i++) {
			RDO_addr[i] = Debug_Read_Safe();
		}
		break;
	}

	case CENTURION_GET_NODE_RDO: {
		//index
		Xuint8 RDO_index = Debug_Read_Safe();
		Xuint8 *RDO_addr = RDO_addrs[RDO_index];
		//bytes
		Xuint8 RDO_size = Debug_Read_Safe();
		//set data
		for (i = 0; i < RDO_size; i++) {
			Debug_Write_Safe(RDO_addr[i]);
		}
		break;

	case CENTURION_GET_LOGS_HS: {
		//Tell the PC how many logs are available
		//may as well do this as bytes as we have 16 bits for the number
		Xuint16 logsize_bytes = experiment_log_index * 8;
		Debug_Write_Safe(logsize_bytes);
		Debug_Write_Safe(logsize_bytes >> 8);
		//wait for the PC to finish collecting
		Debug_Read_Safe();
		experiment_log_index = 0;
		break;

		}
	default:
		//bad command...
		DEBUG_OUT = 0xEE;
		while (1)
			;
		break;
		}
	}
}


Xuint32 count = 0;
void Timer_Tick()
{
	count++;
	DEBUG_OUT = count;
}



int main()
{
    microblaze_register_handler(ISR, 0);

    ISR_table[0] = MB_cmd_ISR;
    ISR_table[1] = Timer_Tick;

    XIOModule_EnableIntr(XPAR_IOMODULE_0_BASEADDR, 0x30000);
    XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x30000);

	NoC_Init();



	DEBUG_OUT = 0x53;
	INTEL_OUT = 0x54;
	ROUTER_OUT = 0x55;


	xil_printf("Centurion VC707 MOSAR\n");
	xil_printf("Built: %s %s \n", __DATE__, __TIME__);
	xil_printf("Node %d\n", node_id);

	xil_printf("Waiting at barrier sync #1 for 0x%X\n", 0xFE);
		Init_Barrier_Sync(0xFE, 0);


	DEBUG_OUT = 0x54;

	microblaze_enable_interrupts();

	//while(1)
	//	xil_printf("RDO test: %d %d\n", RDO_test, i++);

	xil_printf("Sinking all packets: \n");
	while(1)
	{
		Xuint16 head;
		static Xuint8 buff[1000];

		NoC_Recieve_Packet_Blocking(&head, buff, 1000);

	}
}
