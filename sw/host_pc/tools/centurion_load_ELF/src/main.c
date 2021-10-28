#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"


Xuint8 test[] = {1,2,3,4,5};


int main(int argc, char **argv)
{
	char* ELF_mem;
	if(argc < 2)
	{
		printf("Error: ELF File not specified\n");
		exit(-1);
	}

	printf("Uploading %s to all nodes\n", argv[1]);
	Centurion_Lib_init();

	//choose the NoC IO space
	Centurion_Set_IO_NoC();

	//set to broadcast
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 0);


	//reset the NoC
	Centurion_Reset_NoC();

	//set the debug to BE to enter program mode
	Centurion_Write_Debug_Sys(0x1BE);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);


	Load_ELF_into_memory(argv[1], &ELF_mem);


	int i;
	if(argc < 3)
	{
		for(i=0; i< NOC_NUM_NODES; i++)
		{
			Program_Node(i, ELF_mem);
		}
	}
	else
	{
		Program_Node(0, ELF_mem);
	}

	//allow the nodes to reset
	Centurion_Write_Debug_Sys(0x130);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 1);
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);
	free(ELF_mem);
	close(cent_fd);

	return 0;

}
