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
	{
		printf("Node ID required!\n");
		exit(-1);
	}
	int node = atoi(argv[1]);
	Centurion_Write_Reg(CENT_REG_NODE_UART_SEL, node);
	printf("Centurion UART node set to %d\n", node);

	close(cent_fd);
	return 0;

}
