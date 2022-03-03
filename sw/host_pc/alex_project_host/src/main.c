/*
 * main.c (Host PC)
 *
 * Sends configuration data to the nodes and starts the algorithm
 *
 * Author: Alex Clifton
 * Based on code written by mr589
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/time.h>
#include <string.h>

/* required for Centurion functions */
#include "centurion_lib.h"

// Parameters for the algorithm
int population_size; // The number of individuals on each island
int generations; // How many generations the algorithm runs for

// Gets the next config variable from a file
int readConfigLine(FILE* file, char* line, size_t len) {
	if (getline(&line, &len, file) == -1) {
		printf("Invalid config file, defaulting to -1\n");
		return -1;
	}

	// Remove the comment from the start of the string
	char* ptr = strchr(line, ':') + 1;

	// Convert to int and return
	return atoi(ptr);
}

// Read config data from a file
void readConfig() {
	FILE* file;
	char* line = NULL;
	size_t len = 0;

	file = fopen("../config", "r");
	if (file) {
		// Read each variable in turn
		population_size = readConfigLine(file, line, len);
		generations = readConfigLine(file, line, len);

		printf("Populations size: %d\n", population_size);
		printf("Generations: %d\n", generations);

	} else {
		printf("Couldn't open config file\n");
	}
}

int main(int argc, char *argv[])
{
    /* set up the driver for the NoC interface*/
	Centurion_Lib_init();

    /* clear the NoC to a known state */
	Centurion_Reset_NoC();

    /* Allow the nodes to progress beyond " Init_Barrier_Sync()" */
	Centurion_Debug_Node_Broadcast(0xFE);

	// See if a seed was given as an argument
	int seed;
	if (argc == 2) {
		seed = atoi(argv[1]);
	} else {
		// Generate a seed from the current time
		struct timeval tp;
		gettimeofday(&tp, 0);
		seed = (tp.tv_sec * 1000) + (tp.tv_usec / 1000);
	}
	printf("Seed: %d\n", seed);

	// Read the config data
	readConfig();

	// Send config data to each node
	int data_size = 5;
	Xuint8 config[data_size];
	// First 3 bytes are for the seed which is set inside the loop
	// Next bytes are the algorithm parameters
	config[3] = population_size;
	config[4] = generations;

	int i;
	for (i = 0; i<64; i++) {
		// Set the seed for this node
		config[0] = (seed >> 16) & 0xFF;
		config[1] = (seed >> 8) & 0xFF;
		config[2] = seed & 0xFF;

		// Send the data to the node
		Centurion_Write_Sys_Packet(i, config, data_size, 0, 0x00);

		// Increment the seed for the next node
		seed ++;
	}

	printf("Started\n");

	// Receive messages
	/*Xuint8 data[10];
	Xuint16 header;
	Xuint8 node;
	Xuint8 packetLength;
	while (1) {
		packetLength = Centurion_Read_Blocking(data, 10, &header, &node) - 1;

		printf("Packet from %d, length %d\n", node, packetLength);

		int i;
		for (i=0; i<packetLength; i++) {
			printf("[%2d]: %x\n", i, data[i]);
		}
	}*/

    /* close the centurion driver*/
	close(cent_fd);

	return 0;
}
