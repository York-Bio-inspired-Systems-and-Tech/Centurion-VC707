/*
 * EA.c (Node)
 *
 * Main functions for running the Evolutionary Algorithm
 *
 * Author: Alex Clifton
 */

#include "xbasic_types.h"
#include "stdio.h"
#include "stdlib.h"
#include "NoC_lib.h"

#include "EA.h"

Individual population[MAX_POPULATION_SIZE];
Individual* bestIndividual;
Individual* worstIndividual;
Individual* idealIndividual;
Xuint16 totalFitness;
Xuint16 islandController; // Node ID of the island controller
Xuint16 agentNumber; // Which agent this is within an island

// Forward declaration of functions
void generatePopulation();
Xboolean evaluatePopulation(Xboolean showDetails);
void evaluateIndividual(Individual* individual);
void generateNewPopulation();
Individual* selectParent();
void crossoverParents(Individual* A, Individual* B, Gene* genes, Xuint16 index);
Gene mutateGene(Gene gene);
void sendIndividuals();
void receiveIndividuals();
void sendFitness();
Xboolean receiveFitness();

// Begin the algorithm as an island controller
void beginAsController() {
	xil_printf("Running as island controller\n");

	// Generate the initial population
	generatePopulation();
	xil_printf("Initial population generated\n");

	// Record start time
	Xuint32 startTime = Read_RTC();

	// Run for a pre-determined number of generations
	for (Xuint8 generation = 1; generation <= generations; generation++) {
		//xil_printf("Generation %d\n", generation);

		// Send some individuals to each agent
		//xil_printf("Sending individuals to agents\n");
		sendIndividuals();

		// Evaluate the fitness of the population
		//xil_printf("Evaluating individuals\n");
		Xboolean idealFound = evaluatePopulation(XFALSE);

		// Receive fitness values from the other agents
		//xil_printf("Receiving fitness values from agents\n");
		for (Xuint8 i = 0; i < (island_size * island_size) - 1; i++) {
			idealFound |= receiveFitness();
		}

		/*for (Xuint8 i = 0; i < population_size; i++) {
			xil_printf("[%d]%d-%d\n", i, population[i].gene, population[i].fitness);
		}*/

		xil_printf("Generation %d\tAverage fitness: %d\t", generation, totalFitness / population_size);
		xil_printf("Best: %u (%d)\tWorst: %u (%d)\n", bestIndividual->gene, bestIndividual->fitness, worstIndividual->gene, worstIndividual->fitness);

		// See if an ideal individual was found
		if (idealFound) {
			xil_printf("Ideal individual found\n");

			// Send a message to the host PC
			Xuint8 data[2];
			data[0] = idealIndividual->gene >> 8;
			data[1] = idealIndividual->gene;
			NoC_Write_Sys_Packet(data, 2, 1, 0);

			xil_printf("Ideal sent\n");

			// No need to continue the loop
			break;
		}

		// Generate the population for the next iteration
		generateNewPopulation();
	}

	// Calculate run time
	Xuint32 runTime = Read_RTC() - startTime;
	xil_printf("Runtime: %u\n", runTime);
}

// Begin the algorithm as an agent
void beginAsAgent() {
	xil_printf("Running as agent\n");

	// Run continuously, processing individuals from the controller
	while (1) {
		// Wait for individuals from the controller
		xil_printf("Waiting for individuals from controller...\n");
		receiveIndividuals();

		// Evaluate the performance of these individuals
		Xboolean idealFound = evaluatePopulation(XTRUE);
		xil_printf("%d individuals evaluated\n", populationPerIsland);

		if (idealFound) {
			xil_printf("Ideal found!!\n");
		}

		// Return the fitness to the controller
		// If an ideal individual was found, the controller will handle this
		sendFitness();
	}
}

// Generate a random population
void generatePopulation() {
	for (Xuint16 i = 0; i < population_size; i++) {
		// Create a random individual
		population[i].gene = rand();
	}
}

// Evaluates the fitness of the population
// Returns true if the target fitness is found
Xboolean evaluatePopulation(Xboolean showDetails) {
	totalFitness = 0;
	bestIndividual = NULL;
	worstIndividual = NULL;
	Xboolean idealFound = XFALSE;

	// Loop through each individual
	for (Xuint16 i = 0; i < populationPerIsland; i++) {
		evaluateIndividual(&population[i]);
		
		if (showDetails) {
			xil_printf("[%d] %d - %d\n", i, population[i].gene, population[i].fitness);
		}

		// See if the individual has the target fitness
		if (population[i].fitness == target_fitness) {
			idealIndividual = &population[i];
			idealFound = XTRUE;
		}

		// Keep track of best individual
		if (bestIndividual == NULL || population[i].fitness > bestIndividual->fitness) {
			bestIndividual = &population[i];
		}

		// Keep track of worst individual
		if (worstIndividual == NULL || population[i].fitness < worstIndividual->fitness) {
			worstIndividual = &population[i];
		}

		// Keep track of total fitness, used for roulette wheel selection and average fitness
		totalFitness += population[i].fitness;
	}

	return idealFound;
}

// Evaluates the fitness function for an individual
// This function is specific to the problem being solved
void evaluateIndividual(Individual* individual) {
	// Evaluate based on the Ones Max problem
	individual->fitness = 0;

	Gene gene = individual->gene;

	// Loop until all bits are 0
	while (gene > 0) {
		// See if the final bit is a one
		if ((gene & 1) == 1) {
			individual->fitness ++;
		}
		// Shift to the right
		gene >>= 1;
	}
}

// Generates the population for the next generation
void generateNewPopulation() {
	// Temporarily store the genes for the new population
	Gene genes[population_size];

	// Each iteration creates 2 children
	// So only loop population_size / 2 times
	for (Xuint16 i = 0; i < population_size / 2; i++) {
		// Select a parent to mate
		Individual* parent1 = selectParent();

		// Select a second, different parent
		Individual* parent2 = selectParent();
		while (parent1 == parent2) {
			parent2 = selectParent();
		}

		// Generate a new individual from the parents
		crossoverParents(parent1, parent2, genes, i * 2);
	}

	// Overwrite the old population with the new one
	for (Xuint16 i = 0; i < population_size; i++) {
		population[i].gene = genes[i];
	}
}

// Selects a parent using roulette wheel selection
Individual* selectParent() {
	// Choose a random number between 0 and the total fitness
	Xuint16 random = rand() % totalFitness;

	// Loop through until this value is reached
	Xuint8 count = 0;
	Xuint16 sum = 0;
	while (sum < random) {
		count += 1;
		sum += population[count].fitness;
	}

	return &population[count];
}

// Uses crossover to produce a new individual from 2 parents
void crossoverParents(Individual* A, Individual* B, Gene* genes, Xuint16 index) {
	// Pick a random point at which to perform the crossover
	Xuint8 n = rand() % (sizeof(Gene) * 8);

	// Generate bit masks for this
	// Bit masks are the same size as the gene
	Gene lastBits = (1 << n) - 1; // E.g. 00000111 if n = 3
	Gene firstBits = ~lastBits; // E.g. 11111000 if n = 3

	// Select the first bits of parent A and the last bits of parent B
	Gene childA = (A->gene & firstBits) | (B->gene & lastBits);
	// Do the reverse to generate another child
	Gene childB = (B->gene & firstBits) | (A->gene & lastBits);

	// Perform mutation on the new children
	childA = mutateGene(childA);
	childB = mutateGene(childB);

	// Insert into array
	genes[index] = childA;
	genes[index + 1] = childB;
}

// Flips some bits in the gene, according to the mutation rate
Gene mutateGene(Gene gene) {
	// Don't mutate if mutation rate is zero
	if (mutation_rate == 0) {
		return gene;
	}

	// Create a bit mask for the mutation
	Gene mask = 0;

	for (Xuint8 i = 0; i < sizeof(Gene) * 8; i++) {
		// Shift the mask across to generate the next bit
		mask <<= 1;

		// Decide if the bit should be set
		if ((rand() % 100) < mutation_rate) {
			// Set the bit to one
			mask |= 1;
		}
	}

	// Flip the bits in the individual based on the mask
	gene ^= mask;
	return gene;
}

// As a controller, Send a subset of the population to each agent
void sendIndividuals() {
	Xuint16 dataSize = populationPerIsland * sizeof(Individual);
	Individual* dataStart = &population[0];

	// Loop through each node in the island
	Xuint8 count = 1;
	for (Xuint8 y = 0; y < island_size; y++) {
		for (Xuint8 x = 0; x < island_size; x++) {
			// Don't send to self, i.e. when x and y are 0
			if (x == 0 && y == 0) {
				continue;
			}

			// Work out node to send to based on x and y offsets
			Xuint8 node = node_id + x + (y * 8);

			// Advance the pointer to the start of the data for this island
			dataStart += populationPerIsland;

			// Send some individuals
			// Send the count as the header - i.e. the node number within the island
			NoC_Write_Node_Packet(node, (Xuint8*) dataStart, dataSize, count);

			count ++;
		}
	}
}

// As an agent, receive individuals from the controller
void receiveIndividuals() {
	Xuint8* data = (Xuint8*) population; // Pointer to population, cast to uint pointer
	Xuint16 length = populationPerIsland * sizeof(Individual);

	// Receive the packet
	// The head is the position of the agent within the island
	Xuint16 packet_size = NoC_Recieve_Packet_Blocking(&agentNumber, data, length + 1);

	// The first byte is the island controller ID, store this for later
	islandController = data[0];

	// Shift elements left to remove the first byte
	for (Xuint16 i = 0; i < packet_size - 1; i++) {
		data[i] = data[i + 1];
	}
}

// As an agent, send fitness values back to the controller
void sendFitness() {
	// Create a buffer to send
	Xuint8 buffer[populationPerIsland];
	for (Xuint8 i = 0; i < populationPerIsland; i++) {
		buffer[i] = population[i].fitness;
	}

	// Send to the controller
	// Set head to the position in the island
	NoC_Write_Node_Packet(islandController, buffer, populationPerIsland, agentNumber);
}

// As a controller, receive fitness values
// Returns true if an ideal individual was returned
Xboolean receiveFitness() {
	Xuint16 agentNumber;
	Xuint8 data[populationPerIsland + 1];
	Xboolean idealReceived = XFALSE;

	// Receive the data
	// The head contains which agent this is
	Xuint16 packet_size = NoC_Recieve_Packet_Blocking(&agentNumber, data, populationPerIsland + 1);

	// The agent only has a subset of the data
	// So calculate the offset from the agent number
	Xuint16 offset = agentNumber * populationPerIsland;

	for (Xuint8 i = 0; i < packet_size - 1; i++) {
		// Load the fitness into the population array
		population[offset + i].fitness = data[i+1];

		// See if this is the target fitness
		if (population[offset + i].fitness == target_fitness) {
			idealIndividual = &population[offset +i];
			xil_printf("Ideal received\n");
			idealReceived = XTRUE;
		}

		// Keep track of stats
		totalFitness += data[i+1];
		if (bestIndividual == NULL || population[offset + i].fitness > bestIndividual->fitness) {
			bestIndividual = &population[offset + i];
		}
		if (worstIndividual == NULL || population[offset + i].fitness < worstIndividual->fitness) {
			worstIndividual = &population[offset + i];
		}
	}

	return idealReceived;
}
