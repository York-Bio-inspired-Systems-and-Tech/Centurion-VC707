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


#define TASK_MAX_destns 5
typedef struct {
	Xuint8 task_id;
	Xuint8 ratio;
	Xuint8 num_packets_RX;
	Xuint8 num_destn_tasks;
	Xuint8 destn_tasks[TASK_MAX_destns];
	Xuint8 destn_packets[TASK_MAX_destns];
	Xuint16 hw_acc_CPU_time;
	Xuint16 packet_size_min;
	Xuint16 packet_size_max;
	Xuint32 rate;
	Xuint32 CPU_time_min;
	Xuint32 CPU_time_max;

}__attribute__ ((__packed__)) Task_Profile;
#define MAX_NUM_TASK_PROFILES 3
Task_Profile task_profiles[MAX_NUM_TASK_PROFILES];


Xuint32 current_task =0;

volatile Xuint8 in_experiment = 0;
volatile Xuint32 experiment_start_time = 0;
volatile Xuint32 experiment_stop_time = 0;
//experiment data
Xuint16 num_packets_sent = 0;
Xuint16 num_packets_RX = 0;
Xuint16 num_packets_RX_deadlock = 0;
Xuint32 experiment_CPU_time = 0;
Xuint16 experiment_packet_size = 0;
Xuint32 packet_last_sent_time = 0;
Xuint32 num_packets_recieved_delta = 0;
Xuint32 num_packets_to_send = 0;
Xuint32 CCR = 100;
Xuint8 HW_ACCEL = 0;

Xuint8 task_dirs[16];
Xuint8 task_switch_enable = 0;

Xuint32 Packet_latency_sum = 0;
Xuint32 CPU_time = 0;
Xuint32 CPU_time_HW_ACCEL = 0;

Xuint32 num_task_switches =0;

Xuint8 is_faulty =0;

void Experiment_Thread();
void NoC_TX_Ready_Spinlock_sinkable();
void write_int_to_TX_buff(Xuint32 data, volatile Xuint32* buff);
Task_Profile* get_Current_Task_Profile();

Xuint16 DEBUG_OUT_int = 0;

typedef enum __attribute__ ((__packed__)) {	C_NODE_RDO_TASK_PROFILES,
											C_NODE_RDO_CURRENT_TASK,
											C_NODE_RDO_EXPERIMENT_START_TIME,
											C_NODE_RDO_EXPERIMENT_STOP_TIME,
											C_NODE_RDO_CCR,
											C_NODE_RDO_NUM_TX,
											C_NODE_RDO_NUM_RX,
											C_NODE_RDO_NUM_RX_DEADLOCK,
											C_NODE_RDO_BUFF,
											C_NODE_RDO_TASK_ROUTING_DIR,
											C_NODE_RDO_TASK_SWITCH_EN,
											C_NODE_RDO_HW_ACCEL,
											C_NODE_RDO_CPU_TIME,
											C_NODE_RDO_CPU_TIME_HW_ACCEL,
											C_NODE_RDO_TOTAL_RX_LATENCY
} Centurion_Remote_Data_Objects;
//lookup table for remotely accessible data
void* remote_data_offsets[] = {	task_profiles,
								&current_task,
								&experiment_start_time,
								&experiment_stop_time,
								&CCR,
								&num_packets_sent,
								&num_packets_RX,
								&num_packets_RX_deadlock,
								&num_task_switches,
								task_dirs,
								&task_switch_enable,
								&HW_ACCEL,
								&CPU_time,
								&CPU_time_HW_ACCEL,
								&Packet_latency_sum
};



Xuint8 RDO_test = 0xCC;

typedef enum __attribute__ ((__packed__)) {	CENTURION_NODE_CMD_NULL,
											CENTURION_SET_NODE_RDO,
											CENTURION_GET_NODE_RDO,
											CENTURION_GET_LOGS_HS,
											CENTURION_NODE_DEBUG_ACK,
											CENTURION_NODE_STOP_EXPERIMENT,
											CENTURION_NODE_GET_TX_BUSY,
											CENTURION_NODE_GET_NUM_TX,
											CENTURION_NODE_GET_NUM_RX,
											CENTURION_ENABLE_TASK_SWITCH,
											CENTURION_DISABLE_TASK_SWITCH,
											CENTURION_ENABLE_FAULT,
											CENTURION_DISABLE_FAULT
} Centurion_Remote_CMDs;




void Set_Debug(Xuint8 val)
{
	DEBUG_OUT_int = val;
	DEBUG_OUT = val;
}

//TODO: THESE ALL NEED SORTING

//set all packets internal
void NoC_Sink_All_internal_On()
{
	//noc_cntrl_reg_shadow |= 0x08;
	//*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

//set all packets internal
void NoC_Sink_All_internal_Off()
{
	//noc_cntrl_reg_shadow &= ~0x08;
	//*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

void NoC_Watchdog_On()
{
	//noc_cntrl_reg_shadow |= 0x04;
	//*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

void NoC_Watchdog_Off()
{
	//noc_cntrl_reg_shadow &= ~0x04;
	//*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}





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
		Xuint8 *RDO_addr = RDO_addr[RDO_index];
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
		Xuint8 *RDO_addr = remote_data_offsets[RDO_index];
		//bytes
		Xuint8 RDO_size = Debug_Read_Safe();
		//set data
		for (i = 0; i < RDO_size; i++) {
			Debug_Write_Safe(RDO_addr[i]);
		}
		break;
	}
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



	case CENTURION_NODE_STOP_EXPERIMENT:
			in_experiment = 0;
			experiment_start_time = 0;
			break;

	case CENTURION_NODE_GET_TX_BUSY:
		Debug_Write_Safe(*NOC_STATUS_IF & 0x2);
		Debug_Write_Safe((*NOC_TX_SENT_LEN_IF) & 0xFF);
		Debug_Write_Safe(((*NOC_TX_SENT_LEN_IF) >> 8) & 0xFF);
		break;

	case CENTURION_NODE_GET_NUM_TX:
		Debug_Write_Safe(num_packets_sent & 0xFF);
		Debug_Write_Safe((num_packets_sent >> 8) & 0xFF);
		break;
	case CENTURION_NODE_GET_NUM_RX:
		Debug_Write_Safe(num_packets_RX & 0xFF);
		Debug_Write_Safe((num_packets_RX >> 8) & 0xFF);
		Debug_Write_Safe(num_packets_RX_deadlock & 0xFF);
		Debug_Write_Safe((num_packets_RX_deadlock >> 8) & 0xFF);

		break;

	case CENTURION_ENABLE_TASK_SWITCH:
		task_switch_enable = 1;
		break;

	case CENTURION_DISABLE_TASK_SWITCH:
		task_switch_enable = 0;
		break;

	case CENTURION_ENABLE_FAULT:
		is_faulty = 1;
		break;

	case CENTURION_DISABLE_FAULT:
		is_faulty = 0;
		break;

	default:
		//bad command...
		LEDS = 0xEE;
		while(1);
		break;
	}
	DEBUG_OUT = DEBUG_OUT_int;

}


Xuint32 count = 0;
void Timer_Tick()
{
	count++;
	DEBUG_OUT = count;
}



void main()
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


	/*xil_printf("Centurion VC707 Base\n");
	xil_printf("Built: %s %s \n", __DATE__, __TIME__);
	xil_printf("Node %d\n", node_id);

	xil_printf("Waiting at barrier sync #1 for 0x%X\n", 0xFE);*/
		Init_Barrier_Sync(0xFE, 0);

	DEBUG_OUT = 0x54;

	microblaze_enable_interrupts();

	//while(1)
	//	xil_printf("RDO test: %d %d\n", RDO_test, i++);

	//xil_printf("Sinking all packets: \n");
	Xuint16 cmd =0;
	Xuint32 RX_size;


	while(1)
	{

		NoC_Sink_All_internal_On();
		Set_Debug(0x7A);
		RX_size = NoC_Read_Non_Blocking();
		if(RX_size > 0)
		{
			num_packets_RX_deadlock++;
			//	Log_Action(ERROR_BAD_RX, NOC_RX_BUFF[0] & 0x7, NOC_RX_BUFF[1], NOC_RX_BUFF[2]);
				////Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0xAA, 0xBB);

			}
			//no longer need RX buffer now
			ACK_RX();
		}

		if((experiment_start_time !=0) && (Read_RTC() > experiment_start_time))
		{
			Task_Profile *tp = get_Current_Task_Profile();
			Xuint32 CCR_divisor = 100 / CCR;
			num_packets_sent = 0;
			packet_last_sent_time = 0;
			num_packets_recieved_delta = 0;
			num_packets_to_send = 0;
			num_task_switches =0;
			//experiment_log_index = 0;

			experiment_CPU_time = ((tp->CPU_time_max - tp->CPU_time_min) / CCR_divisor) + tp->CPU_time_min;
			CCR_divisor = 100 / (100-CCR);
			experiment_packet_size = ((tp->packet_size_max - tp->packet_size_min) / CCR_divisor) + tp->packet_size_min;
			experiment_packet_size = 50;

			num_packets_RX = 0;
			num_packets_RX_deadlock =0;
			Packet_latency_sum = 0;
			CPU_time=0;
			CPU_time_HW_ACCEL  =0;
			Log_Action(LOG_PACKET_SIZE, experiment_packet_size >> 16, experiment_packet_size >> 8, experiment_packet_size);
			Log_Action(LOG_CPU_TIME, experiment_CPU_time >> 16, experiment_CPU_time >> 8, experiment_CPU_time);

			Log_Action(TASK_SWTICHED, current_task, 0xAA, 33);
			NoC_Sink_All_internal_Off();
			NoC_Set_Current_Task(current_task);
			Set_Debug(current_task);
			in_experiment = 1;
			Experiment_Thread();
			NoC_Sink_All_internal_On();
			NoC_Watchdog_Off();
			is_faulty = 0;
		}
	while(1);
}








void write_int_to_TX_buff(Xuint32 data, volatile Xuint32*  buff)
{
	buff[0] = (data >> 24) & 0xFF;
	buff[1] = (data >> 16) & 0xFF;
	buff[2] = (data >> 8) & 0xFF;
	buff[3] = (data >> 0) & 0xFF;
}

Task_Profile *get_Current_Task_Profile()
{
	int i;
	for(i=0; i < MAX_NUM_TASK_PROFILES; i++)
	{
		if(task_profiles[i].task_id == current_task)
			return &task_profiles[i];
	}
	//Log_Actionction(ERROR, 0x01, 0x01, 0x01);
	return &task_profiles[0];
}

/*void Send_Experiment_Packet()
{
	int i, task_index, packet_index;
	LEDS_int |= 0x08;
	LEDS = LEDS_int;

	Task_Profile* tp = get_Current_Task_Profile();
	for(task_index = 0; task_index < tp->num_destn_tasks; task_index++)
	{
		for(packet_index=0; packet_index < tp->destn_packets[task_index]; packet_index++)
		{
			Xuint16 packet_index = 0;
			////Log_Actionction(START_TX, tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
			//Log_Actionction(START_TX,  0x180 + tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0xCC, 0xDD);
			//packet header of task
			unsigned int current_time = Read_RTC();
			//wait for TX to be free
			NoC_TX_Ready_Spinlock_sinkable();
			if((in_experiment == 0))
				return;
			//set packet
			NOC_TX_BUFF[0] = 0x180 + tp->destn_tasks[task_index];

			//anti-deadlock packet header
			NOC_TX_BUFF[1] = node_id;
			NOC_TX_BUFF[2] = num_packets_sent & 0xFF;
			write_int_to_TX_buff(current_time, &NOC_TX_BUFF[3]);
			packet_index = 3 + 4;
			//fill the packet with dummy data
			for(i=0; i < experiment_packet_size; i++)
			{
				NOC_TX_BUFF[packet_index] = i & 0xFF;
				packet_index++;
			}

			//add the EOP
			NOC_TX_BUFF[packet_index] = 0x17F;
			packet_index++;

			//write the packet size to send the packet
			*NOC_TX_LEN_IF = (packet_index);



			//wait for TX to be free
			//NoC_TX_Ready_Spinlock_sinkable();

			packet_last_sent_time = current_time;

			//Log_Actionction(END_TX, task_index, packet_index, experiment_packet_size &0xFF);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0x00, 0x11);
			num_packets_sent++;
		}
	}
	if(num_packets_to_send > 0 )
		num_packets_to_send--;

	LEDS_int &= ~0x08;
	LEDS = LEDS_int;
}*/



void Send_Experiment_Packet_non_blocking()
{
	int i, task_index, packet_index;
	DEBUG_OUT_int |= 0x08;
	DEBUG_OUT = DEBUG_OUT_int;

	Task_Profile* tp = get_Current_Task_Profile();
	for(task_index = 0; task_index < tp->num_destn_tasks; task_index++)
	{
		for(packet_index=0; packet_index < tp->destn_packets[task_index]; packet_index++)
		{
			if(*NOC_STATUS_IF & 0x2)
				return;

			Xuint16 packet_index = 0;
		//	Log_Action(START_TX, tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
//			Log_Action(START_TX,  0x180 + tp->destn_tasks[task_index],  num_packets_sent & 0xFF, node_id);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0xCC, 0xDD);
			//packet header of task
			unsigned int current_time = Read_RTC();
			//wait for TX to be free

			if((in_experiment == 0))
				return;
			//set packet
			NOC_TX_BUFF[0] = 0x180 + tp->destn_tasks[task_index];

			//anti-deadlock packet header
			NOC_TX_BUFF[1] = node_id;
			NOC_TX_BUFF[2] = num_packets_sent & 0xFF;
			write_int_to_TX_buff(current_time, &NOC_TX_BUFF[3]);
			packet_index = 3 + 4;
			//fill the packet with dummy data
			for(i=0; i < experiment_packet_size; i++)
			{
				NOC_TX_BUFF[packet_index] = i & 0xFF;
				packet_index++;
			}

			//add the EOP
			NOC_TX_BUFF[packet_index] = 0x17F;
			packet_index++;

			//write the packet size to send the packet
			*NOC_TX_LEN_IF = (packet_index);



			//wait for TX to be free
			//NoC_TX_Ready_Spinlock_sinkable();

			packet_last_sent_time = current_time;

			//Log_Actionction(END_TX, task_index, packet_index, experiment_packet_size &0xFF);
		//	//Log_Actionction(DEADLOCK_STATE, NoC_Read_Deadlock_State(), 0x00, 0x11);
			num_packets_sent++;
		}
	}
	if(num_packets_to_send > 0 )
		num_packets_to_send--;

	DEBUG_OUT_int &= ~0x08;
	DEBUG_OUT = DEBUG_OUT_int;
}


void NoC_TX_Ready_Spinlock_sinkable()
{
	while(*NOC_STATUS_IF & 0x2)
	{
		if((in_experiment == 0))
			return;
	}
}

void Evaluate_Task_Switch()
{
	Xuint8 intel_task = Read_Intel_Task();
	if((intel_task == 0) || ((task_switch_enable & 0x01) == 0))
		return;
	switch (intel_task)
	{
		case 0x01:
			intel_task = 1;
			break;
		case 0x02:
			intel_task = 2;
			break;
		case 0x04:
			intel_task = 3;
			break;
		default:
			intel_task = 5;
			break;
	}

	if(intel_task == current_task)
		return;

	num_task_switches++;


	//otherwise change the routing to reflect the task change
	Log_Action(TASK_SWTICHED, current_task, num_task_switches, intel_task);
	current_task = intel_task;
	NoC_Set_Current_Task(current_task);

	num_packets_recieved_delta = 0;
	packet_last_sent_time  = Read_RTC();

}


void Experiment_Thread()
{
	Xuint32 RX_size;
	int i;
	Task_Profile *tp;
	while(in_experiment)
	{
		//LEDS_int ^= 0x40;

		if(task_switch_enable & 0x04)
			NoC_Watchdog_On();

		NoC_Watchdog_Off();


		if(is_faulty)
		{
			Log_Action(NODE_IS_FAULTY, 0xAA, 11, 99);
			while(is_faulty)
			{
				if(in_experiment == 0)
					return;

				if((RX_size = NoC_Read_Non_Blocking()))
				{
					Log_Action(ERROR_BAD_RX, NOC_RX_BUFF[0] & 0x7, current_task, num_packets_RX_deadlock);
					ACK_RX();
					num_packets_RX_deadlock++;

				}

			}
		}
		//check to see if we need to change task
		Evaluate_Task_Switch();



		DEBUG_OUT_int &= ~0x07;
		DEBUG_OUT_int |= current_task & 0x07;
		DEBUG_OUT = DEBUG_OUT_int;




		tp = get_Current_Task_Profile();
		//check to see if there are packets ready to receive
		if((RX_size = NoC_Read_Non_Blocking()))
		{

			DEBUG_OUT_int |= 0x10;
			DEBUG_OUT = DEBUG_OUT_int;
			//log the packet received
			Xuint32 rx_time = Read_RTC();
			Xuint32 packet_latency = rx_time - ((NOC_RX_BUFF[3] << 24) + (NOC_RX_BUFF[4] << 16) + (NOC_RX_BUFF[5] << 8) + (NOC_RX_BUFF[6]));

			//Log_Action(START_RX, NOC_RX_BUFF[4], NOC_RX_BUFF[5], NOC_RX_BUFF[6]);
			Log_Action(START_RX, packet_latency & 0xFF, packet_latency >> 8, current_task);

			Packet_latency_sum += packet_latency;

			//simulate a transfer of the data
		/*	for(i=0; i<RX_size; i++)
				NOC_TX_BUFF[i] = NOC_RX_BUFF[i];*/



			if((NOC_RX_BUFF[0] & 0x7) != current_task)
			{
				Xuint8 temp_task = NOC_RX_BUFF[0] & 0x7;
				num_packets_RX_deadlock++;
				//process the task
				/*if(task_switch_enable)
				{
					current_task = temp_task;
					NoC_Set_Current_Task(current_task);
					num_packets_recieved_delta = 1;
					packet_last_sent_time  = Read_RTC();
				}*/
				Log_Action(ERROR_BAD_RX, NOC_RX_BUFF[0] & 0x7, current_task, num_packets_RX_deadlock);
			}
			else
			{

				num_packets_recieved_delta++;
				num_packets_RX++;
			}
			//Log_Actionction(END_RX, RX_size >> 8, RX_size & 0xFF, num_packets_recieved_delta);
			//ack the RX
			ACK_RX();

			DEBUG_OUT_int &= ~0x10;
			DEBUG_OUT = DEBUG_OUT_int;
		}

		//check to see if we are ready to process some data
		//if((num_packets_recieved_delta >= tp->num_packets_RX) && (tp->rate != 0))
		if((num_packets_recieved_delta >= tp->num_packets_RX))
		{
			if(task_switch_enable & 0x02)
				NoC_Watchdog_On();

			//process the task
			Xuint32 finish_time;
			if (HW_ACCEL == current_task)
			{
				finish_time = Read_RTC() + tp->hw_acc_CPU_time;
				CPU_time_HW_ACCEL += tp->hw_acc_CPU_time;
			}
			else
			{
				finish_time = Read_RTC() + tp->CPU_time_min;
				CPU_time += tp->CPU_time_min;
			}
			//log processing started
			//Log_Action(START_PROCESSING, finish_time >> 16, finish_time >> 8, finish_time);
			Log_Action(START_PROCESSING, HW_ACCEL, 0xAA, 0xBB);
			DEBUG_OUT_int |= 0x20;
			DEBUG_OUT = DEBUG_OUT_int;

			while(Read_RTC() < finish_time)
			{
				if(in_experiment == 0)
					return;

			}
			NoC_Watchdog_Off();
			DEBUG_OUT_int &= ~0x20;
			DEBUG_OUT = DEBUG_OUT_int;
			Log_Action(END_PROCESSING, current_task, experiment_CPU_time >> 8, (experiment_CPU_time & 0xFF));
			num_packets_recieved_delta -= tp->num_packets_RX;
			num_packets_to_send++;
		}


		//check to see if we can send a packet
		if(tp->rate == 0)
		{
			if(num_packets_to_send)
			{
				//Send_Experiment_Packet();
				Send_Experiment_Packet_non_blocking();
				if(in_experiment == 0)
					return;
			}
		}
		else
		{
			if((Read_RTC() > (packet_last_sent_time + tp->rate)) || (num_packets_to_send > 0))
			{
				//Send_Experiment_Packet();
				Send_Experiment_Packet_non_blocking();
				if(in_experiment == 0)
					return;
			}

		}

	}
	return;
}












