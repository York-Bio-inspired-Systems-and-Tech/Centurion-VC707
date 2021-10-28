#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

void Write_PB_IO_byte_interrupt(Xuint8 node, Xuint8 data, Xuint8 reg_addr);
int destn = 0;

int main(int argc, char **argv)
{
	Xuint32* MEM_buff;
	Xuint32 mem_len;
	if(argc < 5)
	{
		printf("Error: not enough arguments\n");
		printf("Usage: centurion_pb_io_write node(-1, all nodes) intel(0)/router(1) address data \n");
		exit(-1);
	}

	int node = atoi(argv[1]);
	int destn = atoi(argv[2]);
	if(destn)
		printf("Destination router\n");
	else
		printf("Destination intel\n");

	int address = atoi(argv[3]);
	int data = atoi(argv[4]);

	if(node < 0)
		printf("writing %x to address %x on all nodes\n", data, address);
	else
		printf("writing %x to address %x on node %d\n", data, address, node);

	Centurion_Lib_init();

	//select intel or router as destination
	if(destn)
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 2);
	else
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 3);

	if(node < 0)
	{
		//loop over all nodes
		int i;
		for(i=0; i< NOC_NUM_NODES; i++)
		{
			Write_PB_IO_byte_interrupt(i, data, address);
		}
	}
	else
	{
		//only write to one node
		Write_PB_IO_byte_interrupt(node, data, address);
	}

	//select node broadcast mode
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 0);

	close(cent_fd);

	return 0;
}

void PB_valid_spinlock(Xuint32 value)
{
	Xuint16 debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	while((debug_data & 0x100) != value)
	{
		debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	}
}

void Write_PB_IO_byte_interrupt(Xuint8 node, Xuint8 data, Xuint8 reg_addr)
{
	//select the node
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, node);
	//raise the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	//clear the interrupt flag
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);

	//write the IO address.
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, reg_addr | 0x100);
	printf("waiting at valid raise spinlock\n");
	PB_valid_spinlock(0x100);



	//target data with valid cleared
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, data);
	printf("waiting at valid drop spinlock\n");
	PB_valid_spinlock(0x000);
}

