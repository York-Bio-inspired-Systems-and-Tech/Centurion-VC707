#include<errno.h>
#include<stdio.h>
#include<stdlib.h>
#include<fcntl.h>
#include <linux/ioctl.h>

#include "centurion_lib.h"


int cent_fd;



void Centurion_Lib_init()
{
	cent_fd = open("/dev/centurion", O_RDWR);
	int err = errno;
	if(cent_fd < 0)
		{printf("centurion open failed... %d\n", errno); exit(-1);}

	//test by reading the DIPs
	int res;
	ioctl(cent_fd, CENT_IOC_READ_DIP, &res);
	err = errno;
	if(res != 0xac)
		{printf("centurion DIP value failed... %x\n", res); exit(-1);}

	return;
}


void Centurion_Barrier_Sync(Xuint8 sync_value)
{
	//loop through all the nodes and wait until all of them match the sync value
	int i=0;
	int matched = 0;
	while(!matched)
	{
		if(Centurion_Read_Debug(i) == sync_value)
			i++;
		if(i == NOC_NUM_NODES)
			matched = 1;
	}
}

Xuint8 Centurion_Read_Debug(Xuint8 node)
{
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, node);
	return Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA) & 0xFF;
}

void Centurion_Write_Debug(Xuint8 data)
{
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, data);
}

void Centurion_Write_Debug_Sys(Xuint16 data)
{
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, data);
}

void Centurion_Write_Sys_Packet(int node, Xuint8* data, int length, int is_RCAP_packet, int header)
{

	int node_x = node % NOC_WIDTH;
	int node_y = node / NOC_WIDTH;
	int buff_index = 0;
	int i;
	//buffer to build the packet in
	Xuint16 data_buff[length + 20];

printf("Sending Message to node %d... ", node);
	//add a south for every i
	for(i=0; i < node_y; i++)
	{
		data_buff[buff_index] = 0x1C2;
		buff_index++;
	}
	//add a east for every j
	for(i=0; i < node_x; i++)
	{
		data_buff[buff_index] = 0x1C1;
		buff_index++;
	}

	if(is_RCAP_packet)
	{
		data_buff[buff_index] = 0x1C5;
		buff_index++;
	}
	else
	{
		//add internal
		data_buff[buff_index] = 0x1C4;
		buff_index++;
	}


	//add header
	data_buff[buff_index] = header;
	buff_index++;

	//add source node (0xFF for PC)
	data_buff[buff_index] = 0xFF;
	buff_index++;


	//payload

	for(i=0; i< length; i++)
	{
		data_buff[buff_index] = (Xuint16)data[i];
		buff_index++;

	}
	//add eop
	data_buff[buff_index] = 0x17F;
	buff_index++;

	//wait for the interface to be free
	while((Centurion_Read_Reg(CENT_REG_NOC_IF_STATUS) & 0x02 )!= 0);
	//write the data to the TX NoC buffer
	write(cent_fd, data_buff, buff_index);
	//write the packet length
	Centurion_Write_Reg(CENT_REG_NOC_IF_TX_LEN, buff_index);

	//send the packet
	Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 1);
	Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 0);

	Centurion_Read_Reg(CENT_REG_NOC_IF_STATUS);
	printf("message sent\n");
}


void Centurion_Write_Reg(Xuint32 reg, Xuint32 data)
{
	cent_PCI_cmd cmd;
	cmd.reg = reg;
	cmd.data = &data;

	ioctl(cent_fd, CENT_IOC_WRITE_REG32, &cmd);

}

Xuint32 Centurion_Read_Reg(Xuint32 reg)
{
	cent_PCI_cmd cmd;
	Xuint32 data;
	cmd.reg = reg;
	cmd.data = &data;

	ioctl(cent_fd, CENT_IOC_READ_REG32, &cmd);
	return data;

}


void Centurion_Reset_NoC()
{
	ioctl(cent_fd, CENT_IOC_RESET_NOC, NULL);
}

void Centurion_Suspend_PCI()
{
	ioctl(cent_fd, CENT_IOC_SAVE_PCI_STATE, NULL);
}

void Centurion_Resume_PCI()
{
	ioctl(cent_fd, CENT_IOC_RESTORE_PCI_STATE, NULL);
}

void Centurion_Reprogram_FPGA_from_Flash()
{
	ioctl(cent_fd, CENT_IOC_REPROG_FLASH, NULL);
}
