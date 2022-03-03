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

#include "EA.h"

Individual population[MAX_POPULATION_SIZE];
Individual* bestIndividual;
Xuint16 totalFitness;

// Forward declaration of functions
void generatePopulation();
void evaluatePopulation();
void evaluateIndividual(Individual* individual);
void generateNewPopulation();
Individual* selectParent();
void crossoverParents(Individual* A, Individual* B, Xuint32* genes, Xuint16 index);

// Begin the algorithm
void beginEA() {
	// Generate the initial population
	generatePopulation();

	// Run for a pre-determined number of generations
	for (Xuint8 generation = 1; generation <= generations; generation++) {
		// Evaluate the fitness of the population
		evaluatePopulation();
		xil_printf("Generation %d\tAverage fitness: %d\tBest individual: %d (%d)\n", generation, totalFitness / population_size, bestIndividual->gene, bestIndividual->fitness);

		// Generate the population for the next iteration
		generateNewPopulation();
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
void evaluatePopulation() {
	totalFitness = 0;
	bestIndividual = NULL;

	// Loop through each individual
	for (Xuint16 i = 0; i < population_size; i++) {
		evaluateIndividual(&population[i]);

		// Keep track of best individual
		if (bestIndividual == NULL || population[i].fitness > bestIndividual->fitness) {
			bestIndividual = &population[i];
		}

		// Keep track of total fitness, use for roulette wheel selection and average fitness
		totalFitness += population[i].fitness;
	}
}

// Evaluates the fitness function for an individual
// This function is specific to the problem being solved
void evaluateIndividual(Individual* individual) {
	// Evaluate based on the Ones Max problem
	individual->fitness = 0;

	Xuint32 gene = individual->gene;

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
	Xuint32 genes[population_size];

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
void crossoverParents(Individual* A, Individual* B, Xuint32* genes, Xuint16 index) {
	// Pick a random point at which to perform the crossover
	Xuint8 n = rand() % (sizeof(A->gene) * 32);

	// Generate bit masks for this
	Xuint32 lastBits = (1 << n) - 1; // E.g. 00000111 if n = 3
	Xuint32 firstBits = ~lastBits; // E.g. 11111000 if n = 3

	// Select the first bits of parent A and the last bits of parent B
	genes[index] = (A->gene & firstBits) | (B->gene & lastBits);
	// Do the reverse to generate another child
	genes[index + 1] = (B->gene & firstBits) | (A->gene & lastBits);
}
