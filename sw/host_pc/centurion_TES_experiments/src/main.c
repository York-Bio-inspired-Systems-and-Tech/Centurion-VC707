#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

Xuint8 test[] = {1,2,3,4,5};



int main()
{
	unsigned int buff[10000];
	Centurion_Lib_init();

	Centurion_Reset_NoC();

	Centurion_Set_RTC_Scaler(150); //1us tick as RTC is @ 150MHz
	Centurion_Debug_Node_Broadcast(0xFE);

	/*
	Xuint8 test = 11;
	Centurion_Node_RDO_Write(0, 0, 1, &test);
	Centurion_Node_RDO_Read(0, 0, 1, &test);
	printf("RDO: %x\n", test);
	*/

	//wait for nodes to enter 0x54 debug location
	Centurion_Debug_spinlock(0x54);
	Xuint32 total_num_logs =0;
	int node =0;
	Xuint32 *buff_addr = buff;
	for(node =0; node<64; node++)
	{
		//add a placeholder to show which node we are reading
		buff_addr[0] = 0;
		buff_addr[1] = node;
		buff_addr += 2;
		Xuint16 num_logs = Centurion_Fetch_Node_Logs_HS(node, buff_addr);
		total_num_logs += num_logs + 1;
		buff_addr += num_logs * 2;
		printf("Logs: %d %d\n",node, num_logs);
	}

	printf("Logs: %d\n",total_num_logs);
	Centurion_Print_Logs(buff, "test_logs.txt", total_num_logs);
	return 0;

	//try fetching from HS
	Centurion_debug_src_sel(1);
	Centurion_node_sel(1);

	int rtc = Centurion_Read_Reg(CENT_REG_RTC_VALUE);
	Centurion_Node_Interrupt(1, 3);
	Xuint16 num_logs = Centurion_Node_Read_Debug_Safe();
	num_logs |= Centurion_Node_Read_Debug_Safe() << 8;

	Centurion_Write_Reg(CENT_REG_NODE_LOG_HS_LEN, 4092);
	//wait for HS busy flag to drop
	while(Centurion_Read_Reg(CENT_REG_NOC_STATUS) & 0x01);

	//tell the node we are done (value not important)
	Centurion_Node_Write_Debug_Safe(0xDD);

	Centurion_Set_IO_HS();

	Centurion_Read_HS(buff, 512);
	int t = Centurion_Read_Reg(CENT_REG_RTC_VALUE);
	printf("%d\n", t - rtc);

	printf("Num logs: %d\n", num_logs);

	int i;
	for(i=0; i< 4; i++)
	{
		Xuint8 *data_addr = &buff[i*2];
		Xuint32 *time_addr = &buff[(i*2) + 1];
		printf("%d, %x, %x, %x, %d\n", data_addr[0], data_addr[1], data_addr[2], data_addr[3], *time_addr);
	}

/*
	printf("HS0: %x\n", buff[0]);
	printf("HS1: %x\n", buff[1]);
	printf("HS2: %x\n", buff[2]);
	printf("HS3: %x\n", buff[3]);
	printf("HS4: %x\n", buff[4]);
	printf("HS5: %x\n", buff[5]);
	printf("HS6: %x\n", buff[6]);
*/

	Centurion_debug_src_sel(0);
	return 0;



}
