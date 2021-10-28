

#include "NoC_lib.h"

#define RTC_GPI_ADDR (volatile Xuint32*)0x80000020

volatile Xuint8 node_id;
volatile Xuint32 noc_cntrl_reg_shadow;

//clear the control reg and set the TX/RX buffer divide at half way
void NoC_Init()
{
	//*NOC_RX_BASE_IF = 2048;
	noc_cntrl_reg_shadow = 0x00;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
	node_id = *NOC_NODE_ID_REG;
}

//acknowledge a RX when we are done with the data in the buffer
void ACK_RX()
{
	noc_cntrl_reg_shadow |= 0x02;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
	noc_cntrl_reg_shadow &= ~0x02;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

//set all packets internal
void NoC_Sink_All_internal_On()
{
	noc_cntrl_reg_shadow |= 0x08;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

//set all packets internal
void NoC_Sink_All_internal_Off()
{
	noc_cntrl_reg_shadow &= ~0x08;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

void NoC_Watchdog_On()
{
	noc_cntrl_reg_shadow |= 0x04;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

void NoC_Watchdog_Off()
{
	noc_cntrl_reg_shadow &= ~0x04;
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}

Xuint8 NoC_Get_Intel_Task()
{
	Xuint8 task_bitmap =	(*NOC_STATUS_IF >> 7) & 0xF;
	int i;
	for(i=0; i<4; i++)
	{
		if( (1 << i) == task_bitmap)
			return i+1;
	}
	return 0;
}

void NoC_Set_Task(Xuint8 task)
{
	noc_cntrl_reg_shadow &= ~((0x3 << 10));
	noc_cntrl_reg_shadow |= ((task & 0xF) << 10);
	*NOC_CNTRL_IF = noc_cntrl_reg_shadow;
}


//Thanks to the ECC bit in the Virtex BRAMs, we have a 9-bit fifo buffer for
//sending/recieving with the NoC
Xuint32 NoC_Read_Blocking()
{
	while(((*NOC_STATUS_IF) & 0x01) ==0 );
	Xuint32 RX_size = *NOC_RX_LEN_IF;
	return RX_size;
}

Xuint32 NoC_Read_Non_Blocking()
{
	if(((*NOC_STATUS_IF) & 0x01) ==0 )
		return 0;

	Xuint32 RX_size = *NOC_RX_LEN_IF;
		return RX_size;
}

//reads a token/word - i.e. a 9-bit chunk of data from the network
Xuint32 NoC_Read_Token_Blocking()
{
	NoC_Read_Blocking();
	Xuint32 value = NOC_RX_BUFF[0];
	ACK_RX();
	return value;
}

//reads a byte - i.e. an 8-bit chunk of data from the network
Xuint8 NoC_Read_Byte_Blocking()
{
	NoC_Read_Blocking();
	Xuint32 value = NOC_RX_BUFF[0];
	ACK_RX();
	return (Xuint8)(value & 0xFF);
}


//reads an int - i.e. an 32-bit chunk of data from the network and treats it as an int
Xuint32 NoC_Read_Int_Blocking()
{
	NoC_Read_Blocking();
	Xuint32 value;
	//NoC_Dump_NOC_RX_BUFF(6);
	unpack_int(&value,&NOC_RX_BUFF[0]);

	ACK_RX();
	return value;
}

//reads a token in a non blocking way.
//Returns 0 if there is no data available, or 1 if there is a token via the data pointer
Xuint32 NoC_Read_Token_Non_Blocking(Xuint32 *data)
{
	if(((*NOC_STATUS_IF) & 0x01) ==0 )
		return 0;

	Xuint32 value = NOC_RX_BUFF[0];
	ACK_RX();
	*data = value;
	return 1;
}


Xuint32 NoC_Recieve_Packet_Non_Blocking(Xuint16 *header, Xuint8 *data, int max_packet_length)
{
	//wait for data to be received...
	if(((*NOC_STATUS_IF) & 0x01) ==0 )
		return 0;

	Xuint32 rx_len = *NOC_RX_LEN_IF - 2; ///(minus 2 for header and EOP)
	if(header != NULL)
		*header = NOC_RX_BUFF[0];
	//print out some info
//	xil_printf("Node packet received at %d, header %X, length %d\n", node_id, NOC_RX_BUFF[0], rx_len);
	//copy the data into the buff
	int i;
	for(i=0; i < rx_len && i < max_packet_length; i++)
	{
		data[i] = NOC_RX_BUFF[i+1];
	//	xil_printf("data %d: %X\n", i, NOC_RX_BUFF[i+1]);
	}
	ACK_RX();
	return rx_len;
}

Xuint32 NoC_Recieve_Packet_Blocking(Xuint16 *header, Xuint8 *data, int max_packet_length)
{
	//wait for data to be received...
	while(((*NOC_STATUS_IF) & 0x01) ==0 )//;
	{
		//xil_printf("status %X, %d\n", (*NOC_STATUS_IF), (*NOC_RX_LEN_IF));
		int j;
		//for(j=0; j< 10; j++)
			//xil_printf("%X ",NOC_RX_BUFF[j]);
		//xil_printf("\n");
	}

	Xuint32 rx_len = *NOC_RX_LEN_IF - 2; ///(minus 2 for header and EOP)
	if(header != NULL)
		*header = NOC_RX_BUFF[0];
	//print out some info
	//xil_printf("Node packet received at %d, header %X, length %d\n", node_id, NOC_RX_BUFF[0], rx_len);

	//copy the data into the buff
	if(rx_len > max_packet_length)
		rx_len = max_packet_length;

	int i;
	for(i=0; i < rx_len; i++)
	{
		//~~34 clock cycles here, expected ~15...
		data[i] = NOC_RX_BUFF[i+1];
		//xil_printf("data %d: %X\n", i, NOC_RX_BUFF[i+1]);
	}

	ACK_RX();
	return rx_len;
}



//sends a packet to the host microblaze node
void NoC_Write_Sys_Packet(Xuint8* data, int length, Xuint16 header, Xuint8 destn_id)
{
	int node_x = node_id % NOC_WIDTH;
	int node_y = node_id / NOC_WIDTH;
	int i;
	int buff_index = 0;
	//wait for TX to be free
	while(*NOC_STATUS_IF & 0x2);
	//add route back
	//add a west for every j
	for(i=0; i<node_x; i++)
	{
		//Write_NoC_Blocking(0x1C4);
		NOC_TX_BUFF[buff_index] = 0x1C3;
		buff_index++;
	}

	//add a north for every i
	for(i=0; i<node_y; i++)
	{
		NOC_TX_BUFF[buff_index] = 0x1C0;
		buff_index++;
	}

	//add a North to reach the MB from node (0,0)
	NOC_TX_BUFF[buff_index] = 0x1C0;
	buff_index++;

	//sys packet header
	if(destn_id == 0)
	{
		NOC_TX_BUFF[buff_index] = 0x1F0;
		buff_index++;

		//size
		NOC_TX_BUFF[buff_index] = length;
		buff_index++;
	}
	else
	{
		NOC_TX_BUFF[buff_index] = destn_id;
		buff_index++;
	}

	//node id
	NOC_TX_BUFF[buff_index] = node_id;
	buff_index++;


	if(header)
	{
		NOC_TX_BUFF[buff_index] = header;
		buff_index++;
	}

	//now send the payload
	for(i=0; i< length; i++)
	{
		NOC_TX_BUFF[buff_index] = data[i];
		buff_index++;
	}
	//add eop
	NOC_TX_BUFF[buff_index] = 0x17F;
	//write to length reg to start the transaction
	*NOC_TX_LEN_IF = buff_index + 1;

}

//sends a packet to a neighbouring node
//TODO: header/packet etc
void NoC_Write_Node_Packet(Xuint32 node, Xuint8* data, Xuint32 length, Xuint32 header, Xuint32 RCAP_packet, Xuint32 high_priority)
{
	int node_x = node_id % NOC_WIDTH; //TODO: a lookup table is probably worth doing here
	int node_y = node_id / NOC_WIDTH; //TODO: Divide is even worse than modulus....
	int destn_node_x = node % NOC_WIDTH; //TODO: a lookup table is probably worth doing here
	int destn_node_y = node / NOC_WIDTH; //TODO: Divide is even worse than modulus....
	int delta_x = destn_node_x - node_x;
	int delta_y = destn_node_y- node_y;

	Xuint32 HP_mask = 0;
	if(high_priority)
		HP_mask = 0x20;

	int i;
	int buff_index = 0;
	//wait for TX to be free
	while(*NOC_STATUS_IF & 0x2);
	//add route back
	//add a west for every -ve delta
	if(delta_x < 0)
	{
		for(i=0; i>delta_x; i--)
		{
			NOC_TX_BUFF[buff_index] = 0x1C3 | HP_mask;
			buff_index++;
		}
	}
	else
	{
		//add a east for every +ve delta
		for(i=0; i<delta_x; i++)
		{
			NOC_TX_BUFF[buff_index] = 0x1C1 | HP_mask;
			buff_index++;
		}
	}

	//add a north for every -ve delta
	if(delta_y < 0)
	{
		for(i=0; i>delta_y; i--)
		{
			NOC_TX_BUFF[buff_index] = 0x1C0 | HP_mask;
			buff_index++;
		}
	}
	else
	{
		//add a south for every +ve delta
		for(i=0; i<delta_y; i++)
		{
			NOC_TX_BUFF[buff_index] = 0x1C2 | HP_mask;
			buff_index++;
		}
	}

	if(RCAP_packet)
	{
		//add an SOPR to reach the intel port
		NOC_TX_BUFF[buff_index] = 0x1C5 | HP_mask;
		buff_index++;

	}
	else
	{
		//add an internal to reach the node
		NOC_TX_BUFF[buff_index] = 0x1C4 | HP_mask;
		buff_index++;

	}

	if(header)
	{
		NOC_TX_BUFF[buff_index] = header;
		buff_index++;
	}

	/*//send the node we have sent from?
	NOC_TX_BUFF[buff_index] = node_id;
	buff_index++;*/

	//now send the payload
	for(i=0; i< length; i++)
	{
		NOC_TX_BUFF[buff_index] = data[i];
		buff_index++;
	}
	//add eop
	NOC_TX_BUFF[buff_index] = 0x17F;
	//write to length reg to start the transaction
	*NOC_TX_LEN_IF = buff_index + 1;

}


void NoC_Send_ACK()
{
	Xuint8 ack = 0xAA;
	NoC_Write_Sys_Packet(&ack, 1, 0, 0);
}


void pack_int(int* buff, unsigned int data)
{
	buff[0] = (data >> 24) & 0xFF;
	buff[1] = (data >> 16) & 0xFF;
	buff[2] = (data >> 8) & 0xFF;
	buff[3] = (data >> 0) & 0xFF;
}

void unpack_int(unsigned int* data, int* buff)
{
	*data = buff[3];
	*data |= (buff[2] << 8);
	*data |= (buff[1] << 16);
	*data |= (buff[0] << 24);
}

void NoC_Dump_NOC_RX_BUFF(int num_words)
{
	int i;
	//for(i=0; i<num_words;i++)
		//xil_printf("NOC_RX_BUFF %d: %x\n", i, NOC_RX_BUFF[i]);
}

void NoC_TX_Ready_Spinlock()
{
	while(*NOC_STATUS_IF & 0x2);
}

void Debug_Write_Safe(Xuint8 data)
{
        //wait for the valid flag to clear (host is ready to accept)
        while(DEBUG_IN & 0x100);
        //first set the bus to the value
        DEBUG_OUT = data;
        //then set the valid flag
        DEBUG_OUT = 0x100 | data;
        //wait for the node to respond
        while((DEBUG_OUT & 0x1FF) != (0x100 | data));
        //clear the valid flag
        DEBUG_OUT = data;
        //wait for other end to clear
        while(DEBUG_IN & 0x100);
}

Xuint8 Debug_Read_Safe()
{
        Xuint8 value;
        //wait for the valid flag
        while((DEBUG_IN & 0x100) == 0);

        value = DEBUG_IN & 0xFF;
        //set the bus to the value to show we have RX'd it
        DEBUG_OUT = value;
        DEBUG_OUT = 0x100 | value;
        //wait for the valid flag to clear
        while(DEBUG_IN & 0x100);
        //clear our valid flag
        DEBUG_OUT = value;
        return value;
}

volatile experiment_log *log_buff = (volatile experiment_log*) 0xC5000000;
volatile Xuint16 experiment_log_index = 0;


void Log_Action(Node_Action action, Xuint8 p0, Xuint8 p1, Xuint8 p2)
{
        volatile experiment_log * log_entry = &(log_buff[experiment_log_index]);
        microblaze_disable_interrupts();
#ifdef LOG_ACTIONS
        if(experiment_log_index < MAX_LOG_ENTRIES-1)
        {
                log_entry->type_of_action = action;
                log_entry->param_0 = p0;
                log_entry->param_1 = p1;
                log_entry->param_2 = p2;
                log_entry->time = Read_RTC();
                experiment_log_index++;
        }
        else
        {
                log_entry->type_of_action = LOG_FULL;
                log_entry->time = Read_RTC();
                //Inform PC that logs need hoovering up.
                DEBUG_OUT = 0xAA;
        }
#endif
        microblaze_enable_interrupts();
        if(experiment_log_index > 400)
        {
                //Inform PC that logs need hoovering up.
        		DEBUG_OUT = 0xAA;
        }


}


