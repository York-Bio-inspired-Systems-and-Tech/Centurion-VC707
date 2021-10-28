#include<errno.h>
#include<stdio.h>
#include<stdlib.h>
#include<fcntl.h>
#include <linux/ioctl.h>

#include "centurion_lib.h"

//PCI driver interface

typedef struct {
	int reg;
	void * data;

}cent_PCI_cmd;

#define CENT_IOC_MAGIC '@' //64d is our major number, don't plug any radeon devices in!
#define CENT_IOC_NULL _IO(CENT_IOC_MAGIC, 0)
#define CENT_IOC_READ_DIP _IOR(CENT_IOC_MAGIC, 1, char)
#define CENT_IOC_WRITE_LEDS _IOW(CENT_IOC_MAGIC, 2, char)

#define CENT_IOC_RESET_NOC _IOW(CENT_IOC_MAGIC, 3, char)
#define CENT_IOC_RESET_RTC _IOW(CENT_IOC_MAGIC, 4, char)

#define CENT_IOC_NODE_DEBUG_READ _IOR(CENT_IOC_MAGIC, 5, char)

#define CENT_IOC_WRITE_REG32 _IOW(CENT_IOC_MAGIC, 6, char)
#define CENT_IOC_READ_REG32 _IOW(CENT_IOC_MAGIC, 7, char)

#define CENT_IOC_SAVE_PCI_STATE _IOW(CENT_IOC_MAGIC, 8, char)
#define CENT_IOC_RESTORE_PCI_STATE _IOW(CENT_IOC_MAGIC, 9, char)
#define CENT_IOC_REPROG_FLASH _IOW(CENT_IOC_MAGIC, 10, char)

#define CENT_IOC_NOC_BUFF_EN _IOW(CENT_IOC_MAGIC, 11, char)
#define CENT_IOC_HS_BUFF_EN _IOW(CENT_IOC_MAGIC, 12, char)
#define CENT_IOC_WR_BUFF_OFFSET_SET _IOW(CENT_IOC_MAGIC, 13, char)
#define CENT_IOC_RD_BUFF_OFFSET_SET _IOW(CENT_IOC_MAGIC, 14, char)

#define CENT_IOC_MAXNR 14



int cent_fd; 



void Centurion_Lib_init()
{
	cent_fd = open("/dev/centurion", O_RDWR);
	int err = errno;
	if(cent_fd < 0)
		{printf("centurion open failed... %d\n", errno); exit(-1);}
	printf("Cent fd: %x\n", cent_fd);

	//test by reading the DIPs
	int res;
	ioctl(cent_fd, CENT_IOC_READ_DIP, &res);
	err = errno;
	printf("value DIPS: %x, %x\n", res, err);
	if(res != 0xac)
		{printf("centurion DIP value ERROR... %x\n", res); }

	//clear all pending debug signals
	Centurion_Debug_Src_Sel(1);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);
	int i=0;
	for(i=0; i<NOC_NUM_NODES; i++)
	{
		Centurion_Node_Sel(i);
		Centurion_Write_Debug_Sys(0);
	}

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



Xuint32 Centurion_Read_Blocking(Xuint8* data, Xuint32 max_length, Xuint16 *header, Xuint8 *node)
{

	//wait for data to arrive
	while((Centurion_Read_Reg(CENT_REG_NOC_IF_STATUS) & 0x01 ) == 0);
	//TODO: move node and header into the kernel driver

	Xuint32 *data_tmp = malloc((max_length*4) + 2);

	//get the amount RX data in the buffer
	int RX_size = (Centurion_Read_Reg(CENT_REG_NOC_IF_RX_LEN)) ;
	//printf("Data received %d bytes\n", RX_size);

	if(RX_size > max_length +2)
		RX_size = max_length +2;

	read(cent_fd, data_tmp, RX_size);
	int i;
	//TODO: kernel driver currently copies data in 32-bit words when should be 16 or even 8.
	*header = data_tmp[0];
	*node = data_tmp[1];
	for(i=0; i<RX_size-3; i++)
	{
		//printf("Data %x:%x \n", data_tmp[i],data_tmp[i+2]);
		data[i] = data_tmp[i+2];
	}

	//ack the RX
	Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 0x2);
	Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 0x0);

	free(data_tmp);

	return RX_size-2;
}

Xuint32 Centurion_Read_Non_Blocking(Xuint8* data, Xuint32 max_length)
{
	//check if data is available and return 0 if not
	if((Centurion_Read_Reg(CENT_REG_NOC_IF_STATUS) & 0x01 ) == 0)
		return 0;
	//TODO: move node and header into the kernel driver
		Xuint8 *data_tmp = malloc(max_length + 2);

		//get the amount RX data in the buffer
		int RX_size = (Centurion_Read_Reg(CENT_REG_NOC_IF_RX_LEN)) ;
		printf("Data received %d bytes\n", RX_size);

		if(RX_size > max_length+2)
			RX_size = max_length+2;

		read(cent_fd, data_tmp, RX_size);
		int i;
		for(i=0; i<RX_size-2; i++)
		{
			data[i] = data_tmp[i+2];
		}

		//ack the RX
		Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 0x2);
		Centurion_Write_Reg(CENT_REG_NOC_IF_CNTRL, 0x0);

		free(data_tmp);

		return RX_size-2;
}


void Centurion_Write_Sys_Packet(int node, Xuint8* data, Xuint32 length, Xuint32 is_RCAP_packet, Xuint32 header)
{

	int node_x = node % NOC_WIDTH;
	int node_y = node / NOC_WIDTH;
	int buff_index = 0;
	int i;
	//buffer to build the packet in
	Xuint16 data_buff[length + 20];

//printf("Sending Message to node %d... \n", node);
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
	//printf("message sent\n");
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



void Centurion_Set_IO_HS()
{
	ioctl(cent_fd, CENT_IOC_HS_BUFF_EN, NULL);
}

void Centurion_Read_HS(Xuint32 *buff, int size)
{
	read(cent_fd, buff, size);
}

void Centurion_Set_RTC_Scaler(Xuint32 value)
{
	//RTC set scalar
	Centurion_Write_Reg(CENT_REG_RTC_VALUE, value);
	Centurion_Write_Reg(CENT_REG_NOC_CNTRL, 0x2);
	Centurion_Write_Reg(CENT_REG_NOC_CNTRL, 0x0);
}

void Centurion_Restart_RTC()
{
	Centurion_Write_Reg(CENT_REG_NOC_CNTRL, 0x2);
	Centurion_Write_Reg(CENT_REG_NOC_CNTRL, 0x0);
}

Xuint32 Centurion_Read_RTC()
{
	return Centurion_Read_Reg(CENT_REG_RTC_VALUE);
}


inline void Centurion_Node_Sel(Xuint8 node)
{
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, node);
}

inline void Centurion_Debug_Src_Sel(Xuint8 src)
{
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, src);
}

void Centurion_Debug_Valid_spinlock(Xuint32 value)
{
	Xuint16 debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	while((debug_data & 0x100) != value)
	{
		debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	}
}



void Centurion_Debug_spinlock(Xuint32 value)
{
	Xuint16 debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	while((debug_data) != value)
	{
		debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	}
}


void Centurion_Node_Write_Debug_Safe(Xuint8 data)
{
	//Write the data with SW valid raised
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, 0x100 | data);
	//wait for remote end to match
	Centurion_Debug_spinlock(0x100 | data);
	//Drop the valid flag to the data
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, data);
	//Wait for far end to drop their valid flag (PC is too slow for this part of the handshake now??!!)
	//Centurion_Debug_spinlock(data);
}

Xuint8 Centurion_Node_Read_Debug_Safe()
{
	//wait for remote end to raise valid flag
	Centurion_Debug_Valid_spinlock(0x100);
	//read the data
	Xuint8 data = Centurion_Read_Reg(CENT_REG_NODE_DEBUG_CMD);
	//Reply with the data and SW valid raised
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, 0x100 | data);
	//What for node to drop the valid flag to the data
	Centurion_Debug_Valid_spinlock(0x000);
	//clear data and valid flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, 0);

	return data;
}

void Centurion_Node_RDO_Write(Xuint8 node, Xuint8 object_index, Xuint8 size, Xuint8 *data)
{
	Centurion_Debug_Src_Sel(1);
	Centurion_Node_Sel(node);
	Centurion_Node_Interrupt(node, CENTURION_SET_NODE_RDO);

	//write the set RDO command
	//Centurion_Node_Write_Debug_Safe(CENTURION_SET_NODE_RDO);
	//write the RDO index
	Centurion_Node_Write_Debug_Safe(object_index);
	//write the RDO size in bytes
	Centurion_Node_Write_Debug_Safe(size);
	//write the data
	int i;
	for(i=0; i<size; i++)
	{
		Centurion_Node_Write_Debug_Safe(data[i]);
	}
	//Put the nodes back into broadcast mode
	Centurion_Debug_Src_Sel(0);
}

void Centurion_Picoblaze_Interrupt(Xuint8 node, Xuint8 intel_sel, Xuint8 command)
{
	//select either the router or intel end point
	if(intel_sel)
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 3);
	else
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 2);

	//write the command.
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, command | 0x100);

	//select the node
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, node);
	//raise the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	//clear the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);

	//select node broadcast mode
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 0);

}

void Centurion_Node_Interrupt(Xuint8 node, Centurion_Remote_CMDs command)
{
	Centurion_Debug_Src_Sel(1);
	Centurion_Node_Sel(node);
	//raise the interrupt on the node
	//raise the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	//wait for xAB to show that the node has entered the PC interrupt handler
	//write the set RDO command
	Centurion_Node_Write_Debug_Safe(command);
	//clear the interrupt on the node
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);


}

void Centurion_Node_RDO_Read(Xuint8 node, Xuint8 object_index, Xuint8 size, Xuint8 *data)
{
	Centurion_Debug_Src_Sel(1);
	Centurion_Node_Sel(node);
	//raise the interrupt on the node
	//raise the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	//wait for xAB to show that the node has entered the PC interrupt handler
	Centurion_Debug_spinlock(0xAB);
	//clear the interrupt on the node
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);
	//write the set RDO command
	Centurion_Node_Write_Debug_Safe(CENTURION_GET_NODE_RDO);
	//write the RDO index
	Centurion_Node_Write_Debug_Safe(object_index);
	//write the RDO size in bytes
	Centurion_Node_Write_Debug_Safe(size);
	//write the data
	int i;
	for(i=0; i<size; i++)
	{
		data[i] = Centurion_Node_Read_Debug_Safe();
	}
	//Put the nodes back into broadcast mode
	Centurion_Debug_Src_Sel(0);
}

void Centurion_Read_Debug_Barrier_Sync(Xuint8 value)
{
	int i;
	for(i=0; i < NOC_NUM_NODES; i++)
	{
		Xuint8 data = Centurion_Read_Debug(i);
		while(data != value)
			data = Centurion_Read_Debug(i);
	}
}

void Centurion_Debug_Node_Broadcast(Xuint16 value)
{
	Centurion_Debug_Src_Sel(0);
	Centurion_Write_Debug_Sys(value);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);
}

Xuint16 Centurion_Fetch_Node_Logs_HS(Xuint8 node, Xuint32 *data_buff)
{
	Centurion_Debug_Src_Sel(1);
	Centurion_Node_Sel(node);
	Centurion_Node_Interrupt(node, CENTURION_GET_LOGS_HS);

	Xuint16 num_logs_bytes = Centurion_Node_Read_Debug_Safe();
	num_logs_bytes |= Centurion_Node_Read_Debug_Safe() << 8;

	if(num_logs_bytes > 0)
	{
		Centurion_Write_Reg(CENT_REG_NODE_LOG_HS_LEN, num_logs_bytes-1); //TODO: validate this is -1
		//wait for HS busy flag to drop
		while(Centurion_Read_Reg(CENT_REG_NOC_STATUS) & 0x01);

	}
	//tell the node we are done (value not important)
	Centurion_Node_Write_Debug_Safe(0xDD);

	if(num_logs_bytes > 0)
	{

		//put the driver in HS mode
		Centurion_Set_IO_HS();

		Centurion_Read_HS(data_buff, num_logs_bytes/4);
	}
	//go back into broadcast mode
	Centurion_Debug_Src_Sel(0);

	return num_logs_bytes/8;

}

void Centurion_Print_Logs(Xuint32* log_data, char *filename, int num_to_print)
{
	if(filename != NULL)
	{
		FILE* f = fopen(filename, "a");
		if(f < 0)
			printf("ERROR OPENING %s for writing\n");
		else
		{
			int i;
			for(i=0; i<num_to_print; i++)
			{
				Xuint8 *data_addr = &log_data[i*2];
				Xuint32 *time_addr = &log_data[(i*2) + 1];
				fprintf(f,"%d, %x, %x, %x, %d\n", data_addr[0], data_addr[1], data_addr[2], data_addr[3], *time_addr);
			}
			fclose(f);
		}
	}
	else
	{
		int i;
		for(i=0; i<num_to_print; i++)
		{
			Xuint8 *data_addr = &log_data[i*2];
			Xuint32 *time_addr = &log_data[(i*2) + 1];
			printf("%d, %x, %x, %x, %d\n", data_addr[0], data_addr[1], data_addr[2], data_addr[3], *time_addr);
		}
	}
}
