/*
 * main.c
 *
 *  Created on: 10 Jan 2019
 *      Author: mr589
 */
#include "xbasic_types.h"
#include "NoC_lib.h"
#include "xiomodule_l.h"

//interrupt settings
#define NUM_EXTERNAL_INTERRUPTS 4
void (*ISR_table[NUM_EXTERNAL_INTERRUPTS])();
volatile Xuint8 external_int_en_mask = 0;



volatile Xuint8 node_id =0;

Xuint8 test[] = {1,2,3,4,5,6,7};
__attribute__ ((section (".noinit"))) Xuint8 buff[1000];

__attribute__ ((section (".noinit"))) experiment_log router_log[2048];
Xuint16 router_log_index =0;

Xuint8 RDO_test = 0xCC;

typedef enum {CENTURION_NODE_CMD_NULL, CENTURION_SET_NODE_RDO, CENTURION_GET_NODE_RDO} Centurion_Remote_CMDs;
void *RDO_addrs[] = { &RDO_test };


void ISR()
{
        //currently we only check external interrupt bus
        //these start at bit 16
 //       Xuint32 int_mask = 0x10000;
       Xuint32 int_status = XIOModule_GetIntrStatus(XPAR_IOMODULE_0_BASEADDR);

        DEBUG_OUT = 0xAB;
        /*int i;

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
        }*/
        if(int_status & 0x10000)
        {
        	ISR_table[0]();
        	XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x10000);
        }
        if(int_status & 0x20000)
        {
        	//router
        	XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x20000);
            ISR_table[1]();
        }
        if(int_status & 0x40000)
        {
            ISR_table[2]();
            XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x40000);
        }
        if(int_status & 0x80000)
        {
            ISR_table[3]();
            XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x80000);
        }


}

void MB_cmd_ISR() {
	int i;
	DEBUG_OUT = 0xAE;

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

	}
	default:
		//bad command...
		DEBUG_OUT = 0xEE;
		while (1)
			;
		break;
	}
}

volatile Xuint32 Read_RTC()
{
	return *(volatile Xuint32*)0x80000020;
}

void Intel_Int()
{
	DEBUG_OUT = 0xBB;
}

void Router_Int()
{
	//be careful with your clock cycles - back to back task packet routing will only leave ~150 cycles between interrupts
	//DEBUG_OUT = 0xCC;/*
	register Xuint16 router_log_index_reg = router_log_index;
	register Xuint16 router_data = ROUTER_IN;
	router_log[router_log_index_reg].param_0 = router_data;
	router_data >>= 8;
	router_log[router_log_index_reg].param_1 = router_data;
	router_log[router_log_index_reg].param_2 = 0xAA;
	router_log[router_log_index_reg].time = Read_RTC();
	router_log_index++;
	DEBUG_OUT = router_log_index;
}


Xuint32 count = 0;
void Timer_Tick()
{
	count++;
	DEBUG_OUT = count;
}

void write_int_to_TX_buff(Xuint32 data, volatile Xuint32*  buff)
{
	buff[0] = (data >> 24) & 0xFF;
	buff[1] = (data >> 16) & 0xFF;
	buff[2] = (data >> 8) & 0xFF;
	buff[3] = (data >> 0) & 0xFF;
}


void Router_Interrupt()
{
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow | 0x20;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}


void Router_Write(Xuint8 data)
{
	while(ROUTER_IN != 0xDE);
	ROUTER_OUT = 0xDE;
	ROUTER_OUT = data;
	ROUTER_OUT = data;
	ROUTER_OUT = data;
	ROUTER_OUT = 0x00;
}


Xuint8 router_settings = 0;
void Router_Set_Task(Xuint8 task)
{
	router_settings &= 0xF;
	router_settings |= task;

	Router_Interrupt();
	Router_Write(0x03);
	Router_Write(router_settings);
}

void Router_Set_SPM(Xuint8 address, Xuint8 data)
{
	Router_Interrupt();
	Router_Write(0x02);
	Router_Write(address);
	Router_Write(data);
}


Xuint32 num_packets_sent = 0;
void Send_Experiment_Packet_non_blocking(Xuint8 task)
{
	int i, task_index, packet_index;
	DEBUG_OUT = 0x80;

	if(*NOC_STATUS_IF & 0x2)
		return;

		//	Log_Action(START_TX, tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
//			Log_Action(START_TX,  0x180 + tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0xCC, 0xDD);
			//packet header of task
	unsigned int current_time = Read_RTC();
			//wait for TX to be free

	//set packet
	NOC_TX_BUFF[0] = 0x180 + task;

			//anti-deadlock packet header
	NOC_TX_BUFF[1] = node_id;
	NOC_TX_BUFF[2] = num_packets_sent & 0xFF;
	write_int_to_TX_buff(current_time, &NOC_TX_BUFF[3]);
	packet_index = 3 + 4;

	//fill the packet with dummy data

	for(i=0; i < 10; i++)
	{
		NOC_TX_BUFF[packet_index] = i & 0xFF;
		packet_index++;
	}

	//add the EOP
	NOC_TX_BUFF[packet_index+100] = 0x17F;
	packet_index++;

	//write the packet size to send the packet
	*NOC_TX_LEN_IF = (packet_index +100);



			//wait for TX to be free
			//NoC_TX_Ready_Spinlock_sinkable();

			//Log_Actionction(END_TX, task_index, packet_index, experiment_packet_size &0xFF);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0x00, 0x11);
			num_packets_sent++;
	DEBUG_OUT = 0x00;
}


void NoC_TX_Ready_Spinlock_sinkable()
{
	while(*NOC_STATUS_IF & 0x2);
}



int main()
{
    microblaze_register_handler(ISR, 0);

    ISR_table[0] = MB_cmd_ISR;
    ISR_table[1] = Router_Int;
    ISR_table[2] = Intel_Int;
    ISR_table[3] = Timer_Tick;

    XIOModule_EnableIntr(XPAR_IOMODULE_0_BASEADDR, 0x30000);
    XIOModule_AckIntr(XPAR_IOMODULE_0_BASEADDR, 0x30000);

	NoC_Init();

	HS_BUFF[0] = 0x01;
	HS_BUFF[1] = 0x02;
	HS_BUFF[2] = 0x03;
	HS_BUFF[3] = 0x04;
	HS_BUFF[4] = 0x05;
	HS_BUFF[5] = 0x06;

	DEBUG_OUT = 0x53;
	INTEL_OUT = 0x54;
	ROUTER_OUT = 0x55;




	if(node_id == 0)
	{
		Router_Set_Task(2);
		Router_Set_SPM(0x31, 0x99);
		Router_Set_SPM(0x32, 0x66);
	}
	if(node_id == 1)
	{
		Router_Set_Task(3);
		Router_Set_SPM(0x31, 0xEE);
		Router_Set_SPM(0x32, 0xBB);
	}

	if(node_id == 2)
	{
		Router_Set_Task(3);
		Router_Set_SPM(0x31, 0x44);
		Router_Set_SPM(0x32, 0x22);
	}

	if(node_id == 3)
	{
		Router_Set_Task(3);
		Router_Set_SPM(0x31, 0x33);
		Router_Set_SPM(0x32, 0xCC);
	}


	microblaze_enable_interrupts();
	Init_Barrier_Sync(0xFE);


	int packet_count = 0;
	DEBUG_OUT = packet_count;

	if(node_id == 0)
	{
		//Send_Experiment_Packet_non_blocking(1);
		NoC_Write_Node_Packet(3, test, 7, 0xCC, 0,0);

	}

	/*if(node_id == 1)
	{
		while(1)
		{
			//NoC_Write_Node_Packet(0, test, 7, 0xCD, 0,0);
		}
	}

	if(node_id == 2)
	{
		while(1)
		{
			//NoC_Write_Node_Packet(0, test, 7, 0xCC, 0,0);
		}
	}
*/
	if(node_id == 3)
	{
		Send_Experiment_Packet_non_blocking(2);
	}

	while(1)
	{

		Xuint16 head;
		NoC_Read_Blocking();
		head = NOC_RX_BUFF[0];
		ACK_RX();
		if(head == 0xAB)
			packet_count++;
		else
			packet_count--;
		//DEBUG_OUT = packet_count;


	}
}
