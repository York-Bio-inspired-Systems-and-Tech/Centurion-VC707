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
Xuint8 island_size;
Xuint16 population_size;
Xuint8 generations;
Xuint8 mutation_rate;
Xuint8 migration_frequency;
Xuint8 migration_quantity;
Xuint8 target_fitness;
Xuint16 populationPerIsland;

// Receive config data from the host
void receiveConfig() {
    // Wait to receive a packet from the host with the seed
    Xuint8 data_size = 12;
    Xuint16 head;
    Xuint8 data[data_size];
    NoC_Recieve_Packet_Blocking(&head, data, data_size + 1);

    // The first 3 bytes are the seed
    Xuint32 seed = (data[1] << 16) | (data[2] << 8) | data[3];
    // Seed the PRNG with this number
    srand(seed);

    // The next bytes are the config data
    island_size = data[4];
    population_size = (data[5] << 8) | data[6]; // Population size is 2 bytes
    generations = data[7];
    mutation_rate = data[8];
    migration_frequency = data[9];
	migration_quantity = data[10];
	target_fitness = data[11];

    // Output the config
    xil_printf("**Algorithm Config:\n");
    xil_printf("*Random seed:\t\t%d\n", seed);
    xil_printf("*Island size:\t\t%d\n", island_size);
    xil_printf("*Population size:\t%d\n", population_size);
    xil_printf("*Generations:\t\t%d\n", generations);
    xil_printf("*Mutation rate:\t\t%d%%\n", mutation_rate);
    xil_printf("*Migration Frequency:\t%d\n", migration_frequency);
    xil_printf("*Migration Quantity:\t%d\n", migration_quantity);
    xil_printf("*Target Fitness:\t%d\n", target_fitness);

    // Calculate population per island
    // Island size refers to side length, e.g. island size 2 has 2x2=4 nodes
	  populationPerIsland = population_size / (island_size * island_size);
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

    // Receive config data from the host
    receiveConfig();

    // Check the config
    // Limit population size
    if (population_size > MAX_POPULATION_SIZE) {
    	xil_printf("Error: Population size can't be greater than %d\n", MAX_POPULATION_SIZE);
    	return 0;
    }

    // Work out which island this node is on
    Xuint8 column = node_id % 8;
    Xuint8 row = node_id / 8;
    // Each island is a square
    // Island number = island column + island row * islands per row
    Xuint8 island = (column / island_size) + (row / island_size) * (8 / island_size);

    // see if this node is a controller for the island
    Xboolean controller = (column % island_size == 0) && (row % island_size == 0);

    DEBUG_OUT = controller;

    // Begin the EA
    if (controller == 1) {
    	beginAsController();
    } else {
    	beginAsAgent();
    }

    /*// Send the data to the host
    Xuint8 data[2];
    data[0] = individual;
    data[1] = fitness;
    Xuint16 header = 0xab;
    NoC_Write_Sys_Packet(data, 2, header, 0);*/

    while(1) {}
}
