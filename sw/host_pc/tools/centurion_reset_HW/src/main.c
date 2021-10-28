#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"


int main(int argc, char **argv)
{

	Centurion_Lib_init();
/*
	//check if we are an admin
	if(system("touch /sys/bus/pci/devices/0000:01:00.0/config") != 0)
	{
		printf("This tool needs to be run as an admin\n");
		return -1;
	}



	printf("Saving PCI state\n");
	system("cp /sys/bus/pci/devices/0000:01:00.0/config /tmp/centPCIConfig");*/

	Centurion_Reprogram_FPGA_from_Flash();

	printf("FPGA reloaded from flash!\n");
	printf("Reboot the PC now\n");

	//printf("Loading PCI state\n");
	//system("cp /tmp/centPCIConfig /sys/bus/pci/devices/0000:01:00.0/config");

/*	printf("PCI reload success\n");

	Centurion_Lib_init();
	Centurion_Write_Debug_Sys(0x000);
	//reset the NoC
//	Centurion_Reset_NoC();

	close(cent_fd);*/

	return 0;

}
