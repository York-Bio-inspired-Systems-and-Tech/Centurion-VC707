#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

Xuint8 test[] = {1,2,3,4,5};


int main(int argc, char **argv)
{

	Centurion_Lib_init();
	Centurion_Write_Debug_Sys(0x000);
	//reset the NoC
	Centurion_Reset_NoC();

	close(cent_fd);

	return 0;

}
