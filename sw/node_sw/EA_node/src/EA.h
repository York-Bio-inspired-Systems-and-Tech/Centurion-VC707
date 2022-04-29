/*
 * EA.h (Node)
 *
 * Main functions for running the Evolutionary Algorithm
 *
 * Author: Alex Clifton
 */

#ifndef SRC_EA_H_
#define SRC_EA_H_

extern volatile Xuint8 node_id;

// Typedef for gene so that it can easily be changed
typedef Xuint16 Gene;

// Struct for individuals
typedef struct {
	Gene gene;
	Xuint8 fitness;
} Individual;

// Parameters for the algorithm
#define MAX_POPULATION_SIZE 500
extern Xuint8 island_size;
extern Xuint16 population_size;
extern Xuint8 generations;
extern Xuint8 mutation_rate;
extern Xuint8 migration_frequency;
extern Xuint8 migration_quantity;
extern Xuint8 target_fitness;
extern Xuint16 populationPerIsland;

extern Individual population[MAX_POPULATION_SIZE];

void beginAsController();
void beginAsAgent();

#endif /* SRC_COMMS_H_ */
