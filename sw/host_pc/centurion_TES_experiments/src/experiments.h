/*
 * experiments.h
 *
 *  Created on: 19 Aug 2019
 *      Author: Matt
 */

#ifndef SRC_EXPERIMENTS_H_
#define SRC_EXPERIMENTS_H_


#include "centurion_lib.h"

#define MAX_NODE_LOGS 128 * 1024




typedef enum __attribute__ ((__packed__)) {LOG_TEST,TASK_SWTICHED, START_PROCESSING, END_PROCESSING, START_RX, END_RX, START_TX, END_TX, LOG_FULL, TX_4, PID_LOG, START_FAULT} Node_Action;
typedef struct{
	Xuint8 param_0;
	Xuint8 param_1;
	Xuint8 param_2;
	Node_Action type_of_action;
	Xuint32 time;
} __attribute__ ((__packed__)) experiment_log;






typedef struct{
	Xuint32 id;
	Xuint32 routing;
	Xuint32 task_mapping;
	Xuint32 experiment_en_flags;
	Xuint32 seed;
	Xuint32 runtime_ms;
	Xuint32 runtime_packets;
}Experiment_Remote_Setup;


typedef enum {
	ROUTING_RANDOM_ONCE,
	ROUTING_RANDOM_REPEAT,
	ROUTING_ALL_INTERNAL
}enum_experiment_routing;

typedef enum {
	TASK_MAP_RANDOM_ONCE,
	TASK_MAP_RANDOM_REPEAT
}enum_experiment_task_mapping;

typedef enum {
	FLAGS_NULL,
	FLAGS_TASK_SWITCH
}enum_experiment_flags;



typedef struct{
	Xuint32 APP_param;
	Xuint32 APP_value;
	Xuint32 NOC_param;
	Xuint32 NOC_value;
	Xuint32 FT_param;
	Xuint32 FT_value;
	Xuint32 INTEL_param;
	Xuint32 INTEL_value;
	Xuint32 num_runs;
	Xuint32 default_measure;
}experiment_params;

typedef enum{
	EXPERIMENT_NULL,
	EXPERIMENT_PARAM_SETTINGS,
	EXPERIMENT_NODE_EVENT_LOG,
	EXPERIMENT_NODE_UPLOAD_EVENT_LOG,
	EXPERIMENT_DONE
}enum_experiment_tokens;


typedef enum{TOPO_UKDF_RANDOM, TOPO_UKDF_FLAG, TOPO_UKDF_RANDOM_GAPS, TOPO_UKDF_STRIPES, TOPO_UKDF_OPTIMAL} UKDF_TOPOs;
typedef enum{ROUTING_UKDF_RANDOM, ROUTING_UKDF_MANHATTEN, ROUTING_UKDF_OPTIMAL} UKDF_ROUTING;

typedef struct{
	UKDF_TOPOs topology;
	UKDF_ROUTING routing;

	Xuint8 enable_intel;
	Xuint8 task_switch;
	Xuint8 task_switch_threshold;
	Xuint8 varied_thresholds;
	Xuint8 HW_accel_learnt;
	Xuint8 fault_injection;
	Xuint8 fault_type;
	Xuint8 ex_1_3;
	Xuint8 ex_2_3;
}experiment;

typedef enum  {	CENTURION_ERR,
				CENTURION_SET_TTY,
				CENTURION_GET_STATUS,
				CENTURION_PROGRAM_NODE,
				CENTURION_PROGRAM_FILE_SLOT,
               CENTURION_PROGRAM_NODES,
               CENTURION_SEND_NODE_CMD_ACK,
               CENTURION_SET_NODE_CE,
               CENTURION_RESET_NODE,
               CENTURION_SET_NODE_FREQ,
               CENTURION_FAULT_INJECT,
               CENTURION_UPLOAD_APPLICATION_GRAPH,
               CENTURION_UPLOAD_EXPERIMENT_SETUP,
               CENTURION_UPLOAD_INTEL,
               CENTURION_UPLOAD_EXPERIMENT_SCRIPT,
               CENTURION_EXPERIMENT_ACK,
               CENTURION_START_EXPERIMENT,
               CENTURION_RESET_EXPERIMENT,
               CENTURION_SET_TOPO,
               CENTURION_SET_TASK_SWITCH,
               CENTURION_SET_TASK_SWITCH_THRESHOLD,
			   CENTURION_STOP_EXPERIMENT

} centurion_commands;

extern experiment experiment_setup;
extern centurion_commands experiment_cmd;

extern experiment_log (*nodes_experiment_log)[NOC_NUM_NODES][MAX_NODE_LOGS];
extern Xuint32 *experiment_log_indexes;

typedef enum __attribute__ ((__packed__))  {CENTURION_NODE_CMD_NULL, CENTURION_NODE_CMD_DATA_SET, CENTURION_NODE_CMD_DATA_GET} Centurion_Remote_CMDs;
typedef enum __attribute__ ((__packed__)) {	C_NODE_RDO_TASK_PROFILES,
											C_NODE_RDO_CURRENT_TASK,
											C_NODE_RDO_EXPERIMENT_START_TIME,
											C_NODE_RDO_EXPERIMENT_STOP_TIME,
											C_NODE_RDO_CCR,
											C_NODE_RDO_NUM_TX,
											C_NODE_RDO_NUM_RX,
											C_NODE_RDO_NUM_RX_DEADLOCK,
											C_NODE_RDO_BUFF,
											C_NODE_RDO_TASK_ROUTING_DIR,
											C_NODE_RDO_TASK_SWITCH_EN,
											C_NODE_RDO_HW_ACCEL,
											C_NODE_RDO_CPU_TIME,
											C_NODE_RDO_CPU_TIME_HW_ACCEL,
											C_NODE_RDO_TOTAL_RX_LATENCY,
											C_NODE_RDO_TX_STATE
} Centurion_Remote_Data_Objects;
typedef struct{
	int task;
	int id;
	//Direction routing_dir[NUMBER_OF_TASKS][4];
} many_core_node;

extern many_core_node nodes[NOC_NUM_NODES];

#endif /* EXPERIMENT_H */

void Experiment_main();


#endif /* SRC_EXPERIMENTS_H_ */
