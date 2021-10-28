#include "experiment_setup.h"
#include "centurion_lib.h"

Application_Graph current_app;

void Experiment_Broadcast_Task_profiles()
{
	int i;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_RDO_Write(i, C_NODE_RDO_TASK_PROFILES, sizeof(Task_Profile) * current_app.num_tasks, current_app.tasks);
	}
}


void Experiment_Broadcast_Task_profiles_flat()
{
	int i;
	current_app.app_id = 0xA;
	current_app.num_tasks = 3;
	current_app.tasks[0].task_id = 1;
	current_app.tasks[0].rate = 4000;
	current_app.tasks[0].ratio =1;
	current_app.tasks[0].CPU_time_min = 1000;
	current_app.tasks[0].CPU_time_max = 1000;
	current_app.tasks[0].hw_acc_CPU_time = 10;
	current_app.tasks[0].packet_size_min = 100;
	current_app.tasks[0].packet_size_max = 100;
	current_app.tasks[0].num_destn_tasks = 1;
	current_app.tasks[0].destn_tasks[0] = 2;
	current_app.tasks[0].destn_packets[0] = 1;
	current_app.tasks[0].num_packets_RX = 1;

	current_app.tasks[1].task_id = 2;
	current_app.tasks[1].rate = 0;
	current_app.tasks[1].ratio =1;
	current_app.tasks[1].CPU_time_min = 1000;
	current_app.tasks[1].CPU_time_max = 1000;
	current_app.tasks[1].hw_acc_CPU_time = 10;
	current_app.tasks[1].packet_size_min = 100;
	current_app.tasks[1].packet_size_max = 100;
	current_app.tasks[1].num_destn_tasks = 1;
	current_app.tasks[1].destn_tasks[0] = 3;
	current_app.tasks[1].destn_packets[0] = 1;
	current_app.tasks[1].num_packets_RX = 1;

	current_app.tasks[2].task_id = 3;
	current_app.tasks[2].rate = 0;
	current_app.tasks[2].ratio =1;
	current_app.tasks[2].CPU_time_min = 1000;
	current_app.tasks[2].CPU_time_max = 1000;
	current_app.tasks[2].hw_acc_CPU_time = 10;
	current_app.tasks[2].packet_size_min = 100;
	current_app.tasks[2].packet_size_max = 100;
	current_app.tasks[2].num_destn_tasks = 1;
	current_app.tasks[2].destn_tasks[0] = 1;
	current_app.tasks[2].destn_packets[0] = 1;
	current_app.tasks[2].num_packets_RX = 1;

	Experiment_Broadcast_Task_profiles();
}



void Experiment_Broadcast_Task_profiles_in_tree()
{
	int i;
	current_app.app_id = 0xA;
	current_app.num_tasks = 3;
	current_app.tasks[0].task_id = 1;
	current_app.tasks[0].rate = 4000;
	current_app.tasks[0].ratio =3;
	current_app.tasks[0].CPU_time_min = 1000;
	current_app.tasks[0].CPU_time_max = 1000;
	current_app.tasks[0].hw_acc_CPU_time = 10;
	current_app.tasks[0].packet_size_min = 100;
	current_app.tasks[0].packet_size_max = 100;
	current_app.tasks[0].num_destn_tasks = 1;
	current_app.tasks[0].destn_tasks[0] = 2;
	current_app.tasks[0].destn_packets[0] = 1;
	current_app.tasks[0].num_packets_RX = 1;

	current_app.tasks[1].task_id = 2;
	current_app.tasks[1].rate = 0;
	current_app.tasks[1].ratio =1;
	current_app.tasks[1].CPU_time_min = 1000;
	current_app.tasks[1].CPU_time_max = 1000;
	current_app.tasks[1].hw_acc_CPU_time = 10;
	current_app.tasks[1].packet_size_min = 100;
	current_app.tasks[1].packet_size_max = 100;
	current_app.tasks[1].num_destn_tasks = 1;
	current_app.tasks[1].destn_tasks[0] = 3;
	current_app.tasks[1].destn_packets[0] = 1;
	current_app.tasks[1].num_packets_RX = 2;

	current_app.tasks[2].task_id = 3;
	current_app.tasks[2].rate = 0;
	current_app.tasks[2].ratio =1;
	current_app.tasks[2].CPU_time_min = 1000;
	current_app.tasks[2].CPU_time_max = 1000;
	current_app.tasks[2].hw_acc_CPU_time = 10;
	current_app.tasks[2].packet_size_min = 100;
	current_app.tasks[2].packet_size_max = 100;
	current_app.tasks[2].num_destn_tasks = 1;
	current_app.tasks[2].destn_tasks[0] = 1;
	current_app.tasks[2].destn_packets[0] = 1;
	current_app.tasks[2].num_packets_RX = 2;

	Experiment_Broadcast_Task_profiles();
}


void Experiment_Broadcast_Task_profiles_out_tree()
{
	int i;
	current_app.app_id = 0xA;
	current_app.num_tasks = 3;
	current_app.tasks[0].task_id = 1;
	current_app.tasks[0].rate = 4000;
	current_app.tasks[0].ratio =1;
	current_app.tasks[0].CPU_time_min = 1000;
	current_app.tasks[0].CPU_time_max = 1000;
	current_app.tasks[0].hw_acc_CPU_time = 10;
	current_app.tasks[0].packet_size_min = 100;
	current_app.tasks[0].packet_size_max = 100;
	current_app.tasks[0].num_destn_tasks = 1;
	current_app.tasks[0].destn_tasks[0] = 2;
	current_app.tasks[0].destn_packets[0] = 2;
	current_app.tasks[0].num_packets_RX = 1;

	current_app.tasks[1].task_id = 2;
	current_app.tasks[1].rate = 0;
	current_app.tasks[1].ratio =1;
	current_app.tasks[1].CPU_time_min = 1000;
	current_app.tasks[1].CPU_time_max = 1000;
	current_app.tasks[1].hw_acc_CPU_time = 10;
	current_app.tasks[1].packet_size_min = 100;
	current_app.tasks[1].packet_size_max = 100;
	current_app.tasks[1].num_destn_tasks = 1;
	current_app.tasks[1].destn_tasks[0] = 3;
	current_app.tasks[1].destn_packets[0] = 2;
	current_app.tasks[1].num_packets_RX = 1;

	current_app.tasks[2].task_id = 3;
	current_app.tasks[2].rate = 0;
	current_app.tasks[2].ratio =1;
	current_app.tasks[2].CPU_time_min = 1000;
	current_app.tasks[2].CPU_time_max = 1000;
	current_app.tasks[2].hw_acc_CPU_time = 10;
	current_app.tasks[2].packet_size_min = 100;
	current_app.tasks[2].packet_size_max = 100;
	current_app.tasks[2].num_destn_tasks = 1;
	current_app.tasks[2].destn_tasks[0] = 1;
	current_app.tasks[2].destn_packets[0] = 1;
	current_app.tasks[2].num_packets_RX = 1;

	Experiment_Broadcast_Task_profiles();
}



void UKDF_Experiment_Broadcast_Task_profiles_fork_join()
{
	int i;
	current_app.app_id = 0xA;
	current_app.num_tasks = 3;
	current_app.tasks[0].task_id = 1;
	current_app.tasks[0].rate = 4000;
	current_app.tasks[0].ratio =1;
	current_app.tasks[0].CPU_time_min = 1000;
	current_app.tasks[0].CPU_time_max = 1000;
	current_app.tasks[0].hw_acc_CPU_time = 10;
	current_app.tasks[0].packet_size_min = 100;
	current_app.tasks[0].packet_size_max = 100;
	current_app.tasks[0].num_destn_tasks = 1;
	current_app.tasks[0].destn_tasks[0] = 2;
	current_app.tasks[0].destn_packets[0] = 3;
	current_app.tasks[0].num_packets_RX = 1;

	current_app.tasks[1].task_id = 2;
	current_app.tasks[1].rate = 0;
	current_app.tasks[1].ratio =1;
	current_app.tasks[1].CPU_time_min = 1000;
	current_app.tasks[1].CPU_time_max = 1000;
	current_app.tasks[1].hw_acc_CPU_time = 10;
	current_app.tasks[1].packet_size_min = 100;
	current_app.tasks[1].packet_size_max = 100;
	current_app.tasks[1].num_destn_tasks = 1;
	current_app.tasks[1].destn_tasks[0] = 3;
	current_app.tasks[1].destn_packets[0] = 1;
	current_app.tasks[1].num_packets_RX = 1;

	current_app.tasks[2].task_id = 3;
	current_app.tasks[2].rate = 0;
	current_app.tasks[2].ratio =1;
	current_app.tasks[2].CPU_time_min = 1000;
	current_app.tasks[2].CPU_time_max = 1000;
	current_app.tasks[2].hw_acc_CPU_time = 10;
	current_app.tasks[2].packet_size_min = 100;
	current_app.tasks[2].packet_size_max = 100;
	current_app.tasks[2].num_destn_tasks = 1;
	current_app.tasks[2].destn_tasks[0] = 1;
	current_app.tasks[2].destn_packets[0] = 1;
	current_app.tasks[2].num_packets_RX = 3;

	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Experiment_RDO_set(i, C_NODE_RDO_TASK_PROFILES, 0, current_app.tasks, sizeof(Task_Profile) * current_app.num_tasks);
	}
}



void Experiment_Task_Mapping()
{
	int i,j;
	Xuint32 task = 0;
	Xuint32 num_tasks = 3;
	Xuint8 task_array[128];
	switch (experiment_setup.topology)
	{
		case TOPO_UKDF_RANDOM:
		{
			//build up a flag array of tasks
			Xuint32 iterator = NOC_NUM_NODES / num_tasks;
			task = 1;
			for(i=0; i<NOC_NUM_NODES; i++)
			{
				task_array[i] = task;
				if(i == (iterator * task))
				{
					task++;
				}
			}

			//shuffle
			int num_permutations = 1000;
			int perm;
			for(perm=0; perm< num_permutations; perm++)
			{
				int x1 = rand() % 128;
				int x2 = rand() % 128;
				Xuint8 temp_task = task_array[x1];
				task_array[x1] = task_array[x2];
				task_array[x2] = temp_task;
			}


			for(i=0; i<NOC_NUM_NODES; i++)
			{
				//task = (rand() % num_tasks) + 1;
				task = task_array[i];
				nodes[i].task = task;
				Centurion_Node_RDO_Write(i, C_NODE_RDO_CURRENT_TASK, 4, &task);
			}
			break;
		}
		case TOPO_UKDF_FLAG:
		{
			Xuint32 iterator = NOC_NUM_NODES / num_tasks;
			task = 1;
			for(i=0; i<NOC_NUM_NODES; i++)
			{
				nodes[i].task = task;
				Centurion_Node_RDO_Write(i, C_NODE_RDO_CURRENT_TASK, 4, &task);
				if(i == iterator)
				{
					task++;
					iterator *= task;
				}
			}
			break;
		}
		case TOPO_UKDF_OPTIMAL:
		{
			for(i=0; i<NOC_HEIGHT-1; i++)
			{
				if((i%3) == 0)
					task = 1;
				if((i%3) == 1)
					task = 2;
				if((i%3) == 2)
					task = 3;
				for(j=0; j<NOC_WIDTH; j++)
				{
					nodes[(i * NOC_WIDTH) + j].task = task;
					Centurion_Node_RDO_Write((i * NOC_WIDTH) + j, C_NODE_RDO_CURRENT_TASK, 4, &task);
				}

			}
			//last rows are all task 2
			for(j=0; j<NOC_WIDTH; j++)
			{
				nodes[(15 * NOC_WIDTH) + j].task = 2;
				task = 2;
				Centurion_Node_RDO_Write((15 * NOC_WIDTH) + j, C_NODE_RDO_CURRENT_TASK, 4, &task);
			}

			break;
		}
		case TOPO_UKDF_STRIPES:
		{
			Xuint8 t1_count = 44;
			Xuint8 t2_count = 42;
			Xuint8 t3_count = 42;
			for(i=0; i<NOC_NUM_NODES; i++)
			{
				if(t1_count > 0)
					task =1;
				else if(t2_count >0)
					task=2;
				else
					task=3;

				if(((i % NOC_WIDTH) == 1 ) || ((i % NOC_WIDTH) == 5 ))
				{
					task = 2;

				}
				if(((i % NOC_WIDTH) == 2 ) || ((i % NOC_WIDTH) == 6 ))
				{
					task = 3;
				}

				if(task==1)
					t1_count--;
				else if(task==2)
					t2_count--;
				else
					t3_count--;

				task_array[i] = task;
			}
			//shuffle
			int num_permutations = 1000;
			int perm;
			for(perm=0; perm< num_permutations; perm++)
			{
				int x1 = rand() % 128;
				int x2 = rand() % 128;
				if(((x1 % NOC_WIDTH) == 1 ) || ((x1 % NOC_WIDTH) == 5 ))
					continue;
				if(((x1 % NOC_WIDTH) == 2 ) || ((x1 % NOC_WIDTH) == 6 ))
					continue;
				if(((x2 % NOC_WIDTH) == 1 ) || ((x2 % NOC_WIDTH) == 5 ))
					continue;
				if(((x2 % NOC_WIDTH) == 2 ) || ((x2 % NOC_WIDTH) == 6 ))
					continue;

				Xuint8 temp_task = task_array[x1];
				task_array[x1] = task_array[x2];
				task_array[x2] = temp_task;
			}

			for(i=0; i<NOC_NUM_NODES; i++)
			{
				task = task_array[i];
				nodes[i].task = task;
				Centurion_Node_RDO_Write(i, C_NODE_RDO_CURRENT_TASK, 4, &task);
			}
			break;
		}


		default:
			break;
	}
}




void Experiment_Broadcast_Start_Time(Xuint32 start_time)
{
	int i;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_RDO_Write(i, C_NODE_RDO_EXPERIMENT_START_TIME, 4, &start_time);
	}
}

void Experiment_Broadcast_Stop_Time(Xuint32 stop_time)
{
	int i;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_RDO_Write(i, C_NODE_RDO_EXPERIMENT_STOP_TIME, 4, &stop_time);
	}
}




void Experiment_Broadcast_Stop()
{
	int i;
	int value=0;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		//xil_printf("Node %d\n", i);
		Centurion_Node_Interrupt(i, CENTURION_STOP_EXPERIMENT);
	}


	for(i=0; i<NOC_NUM_NODES; i++)
	{
		while((value = (Centurion_Read_Debug(i) & 0xFF)) != 0x7A)
		{
			printf("Node %d has not stopped: %x\n", i, value);
		}
	}


	//lets see if any nodes are stuck TX'ing
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		//xil_printf("Node stopped %d\n", i);
		Xuint32 tx_len;
		Centurion_Node_RDO_Read(i, C_NODE_RDO_TX_STATE, 4, &tx_len);
		if(tx_len)
		{
			printf("Node %d task %d has probably deadlocked... TX len: %d\n", i, nodes[i].task, tx_len);
		}

	}
}



void Experiment_HW_Accel_Mapping_Stripes()
{
	//stripe of task 2 hw accels at columns 2 and 6
	//and stripe of task 3 hw accels at columns 3 and 7
	int i;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Xuint8 hw_accel = 0;
		if(((i % NOC_WIDTH) == 1 ) || ((i % NOC_WIDTH) == 5 ))
		{
			hw_accel = 2;
		}
		if(((i % NOC_WIDTH) == 2 ) || ((i % NOC_WIDTH) == 6 ))
		{
			hw_accel = 3;
		}
		Centurion_Node_RDO_Write(i, C_NODE_RDO_HW_ACCEL, 1, &hw_accel);

	}

}

