/*
 * EA.c (Node)
 *
 * Main functions for running the Evolutionary Algorithm
 *
 * Author: Alex Clifton
 */

// Struct for individuals
typedef struct {
	Xuint32 gene;
	Xuint8 fitness;
} Individual;

// Parameters for the algorithm
#define MAX_POPULATION_SIZE 500
extern Xuint16 population_size;
extern Xuint8 generations;

extern Individual population[MAX_POPULATION_SIZE];

void beginEA();
