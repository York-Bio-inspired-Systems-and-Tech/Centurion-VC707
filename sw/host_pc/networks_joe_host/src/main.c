#include <stdlib.h>
#include <stdio.h>

/* required for Centurion functions */
#include "centurion_lib.h"


int main()
{
    /* buffer to store received packets */
	unsigned char buff[10000];

    /* set up the driver for the NoC interface*/
	Centurion_Lib_init();

    /* clear the NoC to a known state */
	Centurion_Reset_NoC();

    /* Allow the nodes to progress beyond " Init_Barrier_Sync()" */
	Centurion_Debug_Node_Broadcast(0xFE);

    Xuint16 header;
	Xuint8 node;
	node = 0;
	buff[0] = 0xAB;
	/* Write a packet to node 0 to start the example message chain! (content is not important)*/
    Centurion_Write_Sys_Packet(node, buff, 1, 0, 0xAA);

    /* wait for a packet to arrive*/
	Xuint8 packet_len = Centurion_Read_Blocking(&buff, 1000, &header, &node);
	printf("Packet RX, node %d size %d\n", node,packet_len);

    /* print out the packet contents*/
    int i;
	for(i=0; i<packet_len; i++)
	{
		printf("  D[%2d]: %x\n",i, buff[i]);
	}

    /* close the centurion driver*/
	close(cent_fd);

	return 0;

}
