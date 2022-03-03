/*
 * main.c (Node)
 *
 * Receives configuration from the host PC then starts the EA
 *
 * Author: Alex Clifton
 * Based on code written by mr589
 */

#include "xbasic_types.h"
#include "stdio.h"
#include "stdlib.h"
#include "NoC_lib.h"
#include "ELF_reload.h"
#include "xiomodule_l.h"

#include "EA.h"

#define LEDS *(volatile Xuint32*)0x80000010
#define DEBUG_IN *(volatile Xuint32*)0x80000024
volatile Xuint8 node_id =0;

// Parameters for the algorithm
Xuint16 population_size;
Xuint8 generations;

// Receive config data from the host
void receiveConfig() {
    // Wait to receive a packet from the host with the seed
	Xuint8 data_size = 5;
    Xuint16 head;
    Xuint8 data[data_size];
    NoC_Recieve_Packet_Blocking(&head, data, data_size + 1);

    // The first 3 bytes are the seed
    Xuint32 seed = (data[1] << 16) | (data[2] << 8) | data[3];
    // Seed the PRNG with this number
    srand(seed);

    // The next bytes are the config data
    population_size = data[4];
    generations = data[5];

    // Output the config
    xil_printf("**Algorithm Config:\n");
    xil_printf("*Random seed:\t\t%d\n", seed);
    xil_printf("*Population size:\t%d\n", population_size);
    xil_printf("*Generations:\t%d\n", generations);
}

int main()
{
    /* Set up the Centurion NoC interface, node_id is set here */
  	NoC_Init();
    /* GPIO to PC, Intel picoblaze and Router picoblaze */
  	DEBUG_OUT = 0;
	INTEL_OUT = 0x54;
	ROUTER_OUT = 0x55;

	xil_printf("*******************\n");
	xil_printf("Node %d\n", node_id);

    xil_printf("Waiting at barrier sync #1 for host to start\n");
    /* wait for PC to tell us to proceed, this line MUST be included to reprogram node SW*/
    Init_Barrier_Sync(0xFE, 0);

	// Only run on node 0
	if (node_id != 0) {
		xil_printf("Not running on this node\n");
		return 0;
	}

    // Receive config data from the host
    receiveConfig();

    // Check the config
    // Limit population size
    if (population_size > MAX_POPULATION_SIZE) {
    	xil_printf("Error: Population size can't be greater than %d\n", MAX_POPULATION_SIZE);
    	return 0;
    }

    // Begin the EA
    beginEA();

    /*DEBUG_OUT = 0;

    // Send the data to the host
    Xuint8 data[2];
    data[0] = individual;
    data[1] = fitness;
    Xuint16 header = 0xab;
    NoC_Write_Sys_Packet(data, 2, header, 0);*/

    while(1) {}
}
