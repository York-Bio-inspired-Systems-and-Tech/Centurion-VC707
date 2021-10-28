#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

Xuint8 test[] = {1,2,3,4,5};


int main(int argc, char **argv)
{
	Centurion_Lib_init();

	int i;
	int j;
	if(argc < 2)
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC, 0);
	else
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC, atoi(argv[1]));

	for(i=0; i<NOC_HEIGHT; i++)
	{
		for(j=0; j< NOC_WIDTH; j++)
		{
			int node = (i*NOC_WIDTH) + j;
			Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, node);
			if (argc > 2)
				printf(" %2d", Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA));
			else
				printf(" %2x", Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA));
		}
		printf("\n");
	}
	close(cent_fd);
	return 0;

}
