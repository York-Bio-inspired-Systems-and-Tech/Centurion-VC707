/*
 * application.c
 *
 *  Created on: Feb 14, 2017
 *      Author: mr589
 */

#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"
#include "experiments.h"
#include "experiment_setup.h"




many_core_node nodes[NOC_NUM_NODES];

experiment_log (*nodes_experiment_log)[NOC_NUM_NODES][MAX_NODE_LOGS];
Xuint32* experiment_log_indexes;


Application_Graph current_app;
Experiment_Remote_Setup current_experiment;
experiment_params current_params;


experiment experiment_setup;
centurion_commands experiment_cmd;

int repeat_runs = 1;
int application_runs = 1;
int intel_runs = 1;
int NoC_runs = 1;
unsigned char node_update_bitmask[128] ={0};
#define UPDATE_NODE_APP 1
#define UPDATE_NODE_INTEL 2


Xuint8* db_name;
Xuint8* db_desc;
Xuint8* db_sweep;
Xuint32 sweep_value;
Xuint32 sweep_max;




Xuint32 Experiment_Get_Num_TX()
{
	int i;
	Xuint32 buff;
	Xuint32 Num_TX = 0;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_RDO_Read(i, C_NODE_RDO_NUM_TX, 4, &buff);
		printf("Node %d, tx %d\n", i, buff);
		Num_TX += buff;
	}
	return Num_TX;
}

Xuint32 Experiment_Get_Num_RX()
{
	int i;
	Xuint32 buff;
	Xuint32 Num_RX = 0;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_RDO_Read(i, C_NODE_RDO_NUM_RX, 4, &buff);
		printf("Node %d, rx %d\n", i, buff);
		Num_RX += buff;
	}
	return Num_RX;
}



Xuint32 Experiment_Inner_Loop(Xuint32 num_runs)
{
	int i;
	int run;

	printf("Experiment loop entered\n");

	for(run=0;run<num_runs;run++)
	{

		printf("Task mapping\n");
		srand(run * 100);
		Experiment_Task_Mapping();
		srand(run * 100);
		printf("Routing\n");
		Experiment_Routing_Setup();


		if (experiment_setup.enable_intel)
		{
/*			//write the intel config string
			for(i=0;i<NOC_NUM_NODES; i++)
			{
				if(experiment_setup.ex_1_3 == 1)
				{
					//work out the ratio of 2 vs 45 thresholds
					Xuint8 ratio = (sweep_value-1) * 10;

					//choose random number from 0 - 99
					Xuint8 rand_100 = rand() % 100;
					Xuint8 thresh;
					if(rand_100 < ratio)
						thresh = 45;
					else
						thresh = 2;

					Update_CIB_Threshold(1,0, thresh);
					Update_CIB_Threshold(1,1, thresh);
					Update_CIB_Threshold(2,0, thresh);

				}

				if(experiment_setup.ex_2_3 == 1)
				{
					//work out the ratio of 2 vs 45 thresholds
					Xuint8 ratio = (sweep_value-1) * 10;

					//choose random number from 0 - 99
					Xuint8 rand_100 = rand() % 100;
					Xuint8 thresh;
					if(rand_100 < ratio)
						thresh = 45;
					else
						thresh = 5;

					Update_CIB_Threshold(5,2, thresh);

				}
/*				if(UKDF_experiment_setup.varied_thresholds == 1)
				{
					//random for each node
					Update_CIB_Threshold(1,0,((rand() % 63) + 1));
					Update_CIB_Threshold(1,1,((rand() % 63) + 1));
					Update_CIB_Threshold(2,0,((rand() % 63) + 1));
					//Update_CIB_Threshold(1,0,(rand() % 8) + 8);
					//Update_CIB_Threshold(1,1,(rand() % 8) + 8);
					//Update_CIB_Threshold(2,0,(rand() % 8) + 8);

					if(UKDF_experiment_setup.HW_accel_learnt == 1)
					{
						//let the HW accel nodes know that they are great!
						if(((i % NOC_WIDTH) == 1 ) || ((i % NOC_WIDTH) == 5 ))
						{
							Update_CIB_Threshold(1,1, 2);
						}
						if(((i % NOC_WIDTH) == 2 ) || ((i % NOC_WIDTH) == 6 ))
						{
							Update_CIB_Threshold(2,0, 2);
						}
					}
				}

				load_intel(i);
			}
			*/
		}


		for(i=0; i<NOC_NUM_NODES; i++)
		{

			Centurion_Node_RDO_Write(i, C_NODE_RDO_TASK_SWITCH_EN, 1, &experiment_setup.task_switch);
		}

		printf("run %d\n", run);

//		xil_printf("Experiment starting\n");
		Centurion_Restart_RTC();
		Xuint32 now = Centurion_Read_RTC();
		Xuint32 start = now + 500000;
		Xuint32 stop = start + 1000000;

		Experiment_Broadcast_Start_Time(start);
		Experiment_Broadcast_Stop_Time(stop);
//		xil_printf("Started\n");
/*
		if(experiment_setup.enable_intel)
		{
			for(i=0; i< NOC_NUM_NODES; i++)
			{
				NoC_Enable_Intel(i);
			}
		}*/

		Xuint8 FI_done =0;
		while(Read_RTC() < stop)
		{

			//keep checking nodes for logs filling up
			for(i=0;i<NOC_NUM_NODES;i++)
			{
				Xuint8 status = Centurion_Read_Debug(i);
				if(status & 0x80)
				{
					//Xuint32 t1 = Centurion_Read_RTC();

//TODO:					Experiment_Fetch_Log_HS(i, 0);

					//Xuint32 t2 = Centurion_Read_RTC();
					//xil_printf("Node %d fetched %d, %d\n", i, experiment_log_indexes[i], t2-t1);
				}

			}

			/*if(FI_done == 0 && UKDF_experiment_setup.fault_injection && (Read_RTC() > start + 500000))
			{
				//inject faults
				for(i=0; i<UKDF_experiment_setup.fault_injection; i++)
				{
					Xuint8 node;
					if(UKDF_experiment_setup.fault_type == 0)
						node= rand() % NOC_NUM_NODES;
					else
					{
						//task 2 based
						node= rand() % NOC_NUM_NODES;
						while(nodes[node].task != 2)
							node= rand() % NOC_NUM_NODES;
					}
					NoC_Debug_Send_Command_With_ACK(node, CENTURION_ENABLE_FAULT);
				}

				FI_done = 1;
			}*/

		}

//		xil_printf("Stopping...\n");
		//ask all of the nodes to stop
		for(i=0; i<NOC_NUM_NODES; i++)
		{
			//xil_printf("Node %d\n", i);
			Centurion_Node_Interrupt(i, CENTURION_STOP_EXPERIMENT);
		}

		//wait for of the nodes to stop
		for(i=0; i<NOC_NUM_NODES; i++)
		{
			Xuint8 value;
			while((value = (Centurion_Read_Debug(i) & 0xFF)) != 0x7A)
			{
				printf("Node %d has not stopped: %x\n", i, value);
			}
		}
//		xil_printf("All nodes have stopped\n");

		if(experiment_setup.enable_intel)
		{
			for(i=0; i< NOC_NUM_NODES; i++)
			{
//TODO:				NoC_Disable_Intel(i);
			}
		}

		Xuint32 cpu_time=0;
		Xuint32 packet_latency=0;
		Xuint32 cpu_accel_time=0;
		Xuint32 num_packets =0;
		Xuint32 num_deadlock =0;
		Xuint32 num_TS =0;

		for(i=0;i<NOC_NUM_NODES; i++)
		{
			Xuint32 temp;
			Xuint16 temp16;
			//get number of packets sent
			Centurion_Node_RDO_Read(i, C_NODE_RDO_NUM_RX, 2, &temp16);
//			xil_printf("num packets RX %d, %d\n",i,temp16);
			num_packets += temp16;

			Centurion_Node_RDO_Read(i, C_NODE_RDO_NUM_RX_DEADLOCK, 2, &temp16);
			//			xil_printf("num packets RX %d, %d\n",i,temp16);
			num_deadlock += temp16;

			//get CPU time
			Centurion_Node_RDO_Read(i, C_NODE_RDO_CPU_TIME, 4, &temp);
//			xil_printf("num packets CPU %d, %d\n",i,temp);
			cpu_time += temp;

			//get CPU accel time
			Centurion_Node_RDO_Read(i, C_NODE_RDO_CPU_TIME_HW_ACCEL, 4, &temp);
//			xil_printf("num packets CPU accel %d, %d\n",i,temp);
			cpu_accel_time += temp;

			Centurion_Node_RDO_Read(i, C_NODE_RDO_TOTAL_RX_LATENCY, 4, &temp);
//			xil_printf("num packets CPU accel %d, %d\n",i,temp);
			packet_latency += temp;

			//get num task switches
			Centurion_Node_RDO_Read(i, C_NODE_RDO_BUFF, 4, &temp);
//			xil_printf("num packets CPU accel %d, %d\n",i,temp);
			num_TS += temp;

		}

		float avg_latency = packet_latency / num_packets;
		printf("\rRun %d, %d, %d, %d, %d, %d.%d\n", run, num_packets, num_deadlock, cpu_time, num_TS,  (int)avg_latency, (int)((avg_latency - ((int)avg_latency))*1000));

		//print TX/RX ratio
	//	xil_printf("Num RX %d\n", num_packets);
	//	xil_printf("Num Deadlock %d\n", num_deadlock);
	//	xil_printf("Num TS %d\n", num_TS);


		//fetch the logs
//		xil_printf("Fetching logs\n");
		for(i=0; i<NOC_NUM_NODES;i++)
		{
			//xil_printf("Node %d\n", i);
			//NoC_Debug_Fetch_log(i, 0);
//TODO:			NoC_Debug_Fetch_Log_HS(i, 0);
			//xil_printf("Node %d fetched %d\n", i, experiment_log_indexes[i]);
		}

//		xil_printf("Uploading logs\n");
		//UART_Upload_logs(run_num);
//TODO:		Upload_Results_LVDS(run, db_name, db_desc, db_sweep, sweep_max, sweep_value);
		for(i=0; i<NOC_NUM_NODES; i++)
				experiment_log_indexes[i] = 0;

		printf("Results Upload done\n");

		while(Read_RTC() < 2000000);

		/*
		xil_printf("resetting nodes to 100MHz\n");
		//speed them all up again
		for(i=0; i<NOC_NUM_NODES; i++)
		{
			NoC_Disable_Intel(i);
			NoC_Set_Node_clk_freq(i, NOC_NODE_CLK_100MHZ);
		}
		xil_printf("All nodes reset to 100MHz\n");*/
	}



}



void Experiment_main()
{
	int i;
	//setup the logs
	nodes_experiment_log = malloc(sizeof(experiment_log) * NOC_NUM_NODES * MAX_NODE_LOGS, 32);
	//experiment_log_indexes = stalloc(sizeof(Xuint32) * NOC_NUM_NODES, 8);
	//this buffer also includes the experiment metadata
	experiment_log_indexes = stalloc((sizeof(Xuint32) * NOC_NUM_NODES) + 520, 8);
	for(i=0; i<NOC_NUM_NODES; i++)
		experiment_log_indexes[i] = 0;


/*	xil_printf("Fetching logs\n");
	for(i=0; i<NOC_NUM_NODES;i++)
	{
		//xil_printf("Node %d\n", i);
		//NoC_Debug_Fetch_log(i, 0);
		NoC_Debug_Fetch_Log_HS(i, 0);
		//xil_printf("Node %d fetched %d\n", i, experiment_log_indexes[i]);
	}

	xil_printf("Uploading logs\n");
	//UART_Upload_logs(run_num);
	Upload_Results_LVDS(0, "test_db", "desc of the test_db", "no params ta", 0x11223344, 0xAABBCCDD);
	//UART_Upload_logs(run_num);
	//while(1);
	xil_printf("Results Upload done\n");
	while(1);*/



<<<<<<< HEAD
	Experiment_Broadcast_Task_profiles();
=======
	UKDF_Experiment_Broadcast_Task_profiles();
>>>>>>> branch 'master' of mr589@git.york.ac.uk:/git/elec-mat-lab/mr589/centurion-VC7
	xil_printf("Task profiles broadcast\n");



	xil_printf("\n\n#########################\n     Run finished\n#########################\n");
	while(1);

	//test the highspeed log download
//	NoC_Debug_Fetch_Log_HS(0,1);


/*

	TEST_Experiment_Task_Routing_Setup(0);

	int CCR_TEST = 10;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Experiment_RDO_set(i, C_NODE_RDO_CCR, 0, CCR_TEST, 4);
	}
	Reset_RTC();

	Xuint32 now = Read_RTC();
	Xuint32 start = now + 1000000;
	Xuint32 end = start + 100000;
	xil_printf("TEST entering experiment\n");
	Experiment_Broadcast_Start_Time(start);
	while(Read_RTC() < start);
while(1);

*/
}


