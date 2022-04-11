
#ifndef NOC_LIB_H_
#define NOC_LIB_H_

#include "xbasic_types.h"

#define NOC_WIDTH 8
#define NOC_HEIGHT 8

//typedef enum __attribute__ ((__packed__)) {LOG_TEST,TASK_SWTICHED, START_PROCESSING, END_PROCESSING, START_RX, END_RX, START_TX, END_TX, LOG_FULL, TX_4, PID_LOG, START_FAULT, LOG_PACKET_SIZE, LOG_CPU_TIME, ERROR, RDO_WRITE,ERROR_BAD_RX, NODE_RESET, DEADLOCK_STATE, NODE_IS_FAULTY} Node_Action;

typedef enum  __attribute__ ((__packed__)) {LOG_NULL, LOG_FULL, LOG_NODE_ID, LOG_TX, LOG_RX} Node_Action;

typedef struct{
        Xuint8 param_0;
        Xuint8 param_1;
        Xuint8 param_2;
        Node_Action type_of_action;
        Xuint32 time;
} __attribute__ ((__packed__)) experiment_log;

#define LOG_ACTIONS

#define LOG_BUFF_SIZE_BYTES 4096
#define MAX_LOG_ENTRIES 512 //LOG_BUFF_SIZE_BYTES/sizeof(experiment_log)
extern volatile experiment_log *log_buff;
extern volatile Xuint16 experiment_log_index;



extern volatile Xuint8 node_id;
extern volatile Xuint32 noc_cntrl_reg_shadow;
void NoC_Init();

void NoC_Init();

void ACK_RX();

volatile Xuint32 Read_RTC();

//Thanks to the ECC bit in the Virtex BRAMs, we have a 9-bit fifo buffer for
//sending/recieving with the NoC



#define NOC_TX_BUFF_SIZE 2048
#define NOC_TX_BUFF ((volatile Xuint32*)(0xC1000000))
#define NOC_RX_BUFF ((volatile Xuint32*)(0xC1000000 + (4*NOC_TX_BUFF_SIZE)))
#define NOC_CNTRL_IF (volatile Xuint32*)(0xC0000000)
#define NOC_STATUS_IF (volatile Xuint32*)(0xC0000004)
#define NOC_TX_LEN_IF (volatile Xuint32*)(0xC0000008)
#define NOC_RX_LEN_IF (volatile Xuint32*)(0xC000000C)
#define NOC_RX_BASE_IF (volatile Xuint32*)(0xC0000010)
#define NOC_NODE_ID_REG (volatile Xuint32*)(0xC0000014)

//clear the control reg and set the TX/RX buffer divide at half way
void NoC_Init();

//Thanks to the ECC bit in the Virtex BRAMs, we have a 9-bit fifo buffer for
//sending/recieving with the NoC
Xuint32 NoC_Read_Blocking();
//reads a token/word - i.e. a 9-bit chunk of data from the network
Xuint32 NoC_Read_Token_Blocking();

//reads a byte - i.e. an 8-bit chunk of data from the network
Xuint8 NoC_Read_Byte_Blocking();

//reads an int - i.e. an 32-bit chunk of data from the network and treats it as an int
Xuint32 NoC_Read_Int_Blocking();

//reads a token in a non blocking way.
//Returns 0 if there is no data available, or 1 if there is a token via the data pointer
Xuint32 NoC_Read_Token_Non_Blocking(Xuint32 *data);

//sends a packet to the host microblaze node
void NoC_Write_Sys_Packet(Xuint8* data, int length, Xuint16 header, Xuint8 destn_id);
//sends a packet to a neighbouring node
void NoC_Write_Node_Packet(int node, Xuint8* data, int length, Xuint32 header);

void NoC_Send_ACK();

void NoC_Dump_RX_Buff(int num_words);

Xuint32 NoC_Recieve_Packet_Non_Blocking(Xuint16 *header, Xuint8 *data, int max_packet_length);
Xuint32 NoC_Recieve_Packet_Blocking(Xuint16 *header, Xuint8 *data, int max_packet_length);
Xuint32 NoC_Read_Non_Blocking();

//Debug interface
#define DEBUG_OUT *(volatile Xuint32*)0x80000010
#define DEBUG_IN *(volatile Xuint32*)0x80000024

#define INTEL_OUT *(volatile Xuint32*)0xC000001C
#define ROUTER_OUT *(volatile Xuint32*)0xC0000018

#define HS_BUFF ((volatile Xuint32*)0xC5000000)

void Debug_Write_Safe(Xuint8 data);
Xuint8 Debug_Read_Safe();

void Log_Action(Node_Action action, Xuint8 p0, Xuint8 p1, Xuint8 p2);


Xuint8 NoC_Get_Intel_Task();
void NoC_Set_Task(Xuint8 task);
#endif /* NOC_LIB_H_ */
