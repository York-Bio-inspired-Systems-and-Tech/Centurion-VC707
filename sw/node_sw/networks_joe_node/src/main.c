/*
 * main.c
 *
 *  Created on: 10 Jan 2019
 *      Author: mr589
 */
#include "xbasic_types.h"
#include "stdio.h"
#include "NoC_lib.h"
#include "ELF_reload.h"
#include "xiomodule_l.h"

#define LEDS *(volatile Xuint32*)0x80000010
#define DEBUG_IN *(volatile Xuint32*)0x80000024
volatile Xuint8 node_id =0;



int main()
{
    /* Set up the Centurion NoC interface, node_id is set here */
  	NoC_Init();
    /* GPIO to PC, Intel picoblaze and Router picoblaze */
  	DEBUG_OUT = 0x53;
	INTEL_OUT = 0x54;
	ROUTER_OUT = 0x55;


	xil_printf("Node %d\n", node_id);

    xil_printf("Waiting at barrier sync #1 for 0x%X\n", 0xFE);
    /* wait for PC to tell us to proceed, this line MUST be included to reprogram node SW*/
    Init_Barrier_Sync(0xFE, 0);

    /* Set GPIO on PC */
	DEBUG_OUT = 0x54;
	Xuint8 num_packets_rx = 0;

    /* 8x8 NoC, last node is node 63 */
	if(node_id == 63)
	{
		xil_printf("Node %d: Sending all packets back to host PC\n", node_id);

	}
	else
	{
		xil_printf("Node %d: Add ID to packet and send to neighbour\n", node_id);
	}

	/* wait forever for packets */
	while(1)
	{
		Xuint16 head;
        /* buffer for recived packet data. Stack is very small, so this must be static or a global variable so that it is placed in BSS */
		static Xuint8 buff[1000];

        /* Blocking read for a packet */
		Xuint16 packet_size = NoC_Recieve_Packet_Blocking(&head, buff, 1000);
		xil_printf("Packet RX, size %d\n", packet_size);

        /* Print the packets contents*/
        int i;
		for(i=0; i<packet_size; i++)
			xil_printf("RX %3d: %x\n", i, buff[i]);

		num_packets_rx++;
		DEBUG_OUT = num_packets_rx;

        /* Add our node ID to the end of the packet*/
		buff[packet_size-1] = node_id;

		if(node_id == 63)
		{
            /* if we are the last node then send the packet to the PC */
			NoC_Write_Sys_Packet(buff, packet_size, head, 0);
		}
		else
		{
            /* otherwise, send it to the neighbouring node */
            /* (first byte in packet is source node, so chop that off by starting at buff[1]) */
			NoC_Write_Node_Packet(node_id + 1, &buff[1], packet_size, head);
		}

	}
}
