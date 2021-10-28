
#include "experiments.h"

#define TASK_MAX_destns 5
typedef struct {
	Xuint8 task_id;
	Xuint8 ratio;
	Xuint8 num_packets_RX;
	Xuint8 num_destn_tasks;
	Xuint8 destn_tasks[TASK_MAX_destns];
	Xuint8 destn_packets[TASK_MAX_destns];
	Xuint16 hw_acc_CPU_time;
	Xuint16 packet_size_min;
	Xuint16 packet_size_max;
	Xuint32 rate;
	Xuint32 CPU_time_min;
	Xuint32 CPU_time_max;

}__attribute__ ((__packed__)) Task_Profile;

#define APP_MAX_TASKS 20
#define APP_MAX_DESC_LEN 300
typedef struct{
	int app_id;
	int num_tasks;
	char desc[APP_MAX_DESC_LEN];
	Task_Profile tasks[APP_MAX_TASKS];
}Application_Graph;

extern Application_Graph current_app;
