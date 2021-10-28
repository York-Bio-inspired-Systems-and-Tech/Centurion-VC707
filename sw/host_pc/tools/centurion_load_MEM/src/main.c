#include <stdlib.h>
#include <stdio.h>
#include "centurion_lib.h"

void Write_PB_instruction_broadcast(Xuint32 instuction, Xuint32 address);
int Load_MEM_into_memory(char * MEM_path, Xuint32** MEM_buff);

Xuint8 test[] = {1,2,3,4,5};
int destn = 0;

int main(int argc, char **argv)
{
	Xuint32* MEM_buff;
	Xuint32 mem_len;
	if(argc < 3)
	{
		printf("Error: Destination (0 - intel, 1 - router) or Mem File not specified\n");
		exit(-1);
	}

	int destn = atoi(argv[1]);
	if(destn)
		printf("Destination router\n");
	else
		printf("Destination intel\n");

	Centurion_Lib_init();
	//clear the interrupt flag (just in case!)
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD_VALID, 0);

	//select intel or router as destination
	if(destn)
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 2);
	else
		Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 3);







	//write the magic code to make the picoblazes enter bootloader mode
	Centurion_Write_Debug_Sys(0xF5);

	//reset the NoC
	Centurion_Reset_NoC();
	//select node 0 for sync
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SEL, 0);


	mem_len = Load_MEM_into_memory(argv[2], &MEM_buff);
	printf("Read %d picoblaze instructions\n", mem_len);

	int i;
	for(i=0; i<mem_len; i++)
	{
		printf("Writing instruction %d, to address %d\n", MEM_buff[i], i);
		Write_PB_instruction_broadcast(MEM_buff[i], i);
	}


	//remove bootloader magic code
	Centurion_Write_Debug_Sys(0x00);
	//select node broadcast mode
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_SRC_SEL, 0);

	//reset the NoC
	Centurion_Reset_NoC();

	free(MEM_buff);
	close(cent_fd);

	return 0;

}

int Load_MEM_into_memory(char * MEM_path, Xuint32** MEM_buff)
{
	//read the file size
	//read ELF header from FILE into memory
	FILE *f = fopen(MEM_path, "r");
	if(f > 0)
	{
		//get the elf file size
		fseek(f, 0L, SEEK_END);
		int mem_size = ftell(f);
		rewind(f);

		char *buff = malloc(mem_size);
		*MEM_buff = malloc(mem_size);

		int i=0;
		if(f != NULL)
		{
		    while (fgets (buff, mem_size, f))
		    {
		    	int instr;
		        /* Process buff here. */
		    	if(fscanf(f, "%x", &instr))
		    	{
		    		//printf("mem %d: %x\n",i, instr);
		    		(*MEM_buff)[i] = instr;
		    		i++;
		    	}

		    }
		    fclose (f);
		}
		free(buff);





		//printf("MEM %s opened, size %d bytes\n", MEM_path, mem_size);
		//fread(*buff, 1, mem_size, f);
		//printf("ELF copied to %x\n", *buff);
		return i-1;
	}
	printf("Error opening file %s\n", MEM_path);
	exit(-2);

}

void PB_valid_spinlock(Xuint32 value)
{
	Xuint16 debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	while((debug_data & 0x100) != value)
	{
		debug_data = Centurion_Read_Reg(CENT_REG_NOC_DEBUG_DATA);
	}
}

void Write_PB_IO_byte_broadcast(Xuint8 data, Xuint8 reg_addr)
{
	//target address with valid raised
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, reg_addr | 0x100);
	PB_valid_spinlock(0x100);
	//target data with valid cleared
	Centurion_Write_Reg(CENT_REG_NODE_DEBUG_CMD, data);
	PB_valid_spinlock(0x000);
}


void Write_PB_instruction_broadcast(Xuint32 instuction, Xuint32 address)
{
	//technically only writes to 1 node, but all nodes will copy the input data as data bus is global.
	//Synchronisation is not a problem as they are all clocked at the same speed.

	//write the address (l and h)
	Write_PB_IO_byte_broadcast(address, 0x60);
	Write_PB_IO_byte_broadcast(address >> 8, 0x61);

	//write the instruction (l, m and h)
	Write_PB_IO_byte_broadcast(instuction, 0x62);
	Write_PB_IO_byte_broadcast(instuction >> 8, 0x63);
	Write_PB_IO_byte_broadcast(instuction >> 16, 0x64);

	//strobe the write signal
	Write_PB_IO_byte_broadcast(1, 0x06);
	Write_PB_IO_byte_broadcast(0, 0x06);

}
