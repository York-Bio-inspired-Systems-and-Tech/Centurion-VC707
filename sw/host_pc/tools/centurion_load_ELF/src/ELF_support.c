/*
 * ELF_support.c
 *
 *  Created on: 20 Jan 2019
 *      Author: mr589
 */

#include "centurion_lib.h"
#include <stdio.h>

#define ELF_DEBUG
#define DATA_PACKET_SIZE_BYTES 512

typedef void (* Target_Fn) ( void ) ;
typedef Xuint16 Elf32_Half;
typedef Xuint32 Elf32_Word;
typedef Xuint32 Elf32_Addr;
typedef Xuint32 Elf32_Off;
#define PHEAD_SIZE 5

/* ELF File Header */
typedef struct
{
  unsigned char e_ident[16];     /* Magic number and other info */
  Elf32_Half    e_type;                 /* Object file type */
  Elf32_Half    e_machine;              /* Architecture */
  Elf32_Word    e_version;              /* Object file version */
  Elf32_Addr    e_entry;                /* Entry point virtual address */
  Elf32_Off     e_phoff;                /* Program header table file offset */
  Elf32_Off     e_shoff;                /* Section header table file offset */
  Elf32_Word    e_flags;                /* Processor-specific flags */
  Elf32_Half    e_ehsize;               /* ELF header size in bytes */
  Elf32_Half    e_phentsize;            /* Program header table entry size */
  Elf32_Half    e_phnum;                /* Program header table entry count */
  Elf32_Half    e_shentsize;            /* Section header table entry size */
  Elf32_Half    e_shnum;                /* Section header table entry count */
  Elf32_Half    e_shstrndx;             /* Section header string table index */
} __attribute__((packed))  Elf32_Ehdr;

typedef struct {
    Elf32_Word  p_type;
    Elf32_Off   p_offset;
    Elf32_Addr  p_vaddr;
    Elf32_Addr  p_paddr;
    Elf32_Word  p_filesz;
    Elf32_Word  p_memsz;
    Elf32_Word  p_flags;
    Elf32_Word  p_align;
} __attribute__((packed))  Elf32_Phdr;

/* Section header.  */
typedef struct
{
  Elf32_Word    sh_name;                /* Section name (string tbl index) */
  Elf32_Word    sh_type;                /* Section type */
  Elf32_Word    sh_flags;               /* Section flags */
  Elf32_Addr    sh_addr;                /* Section virtual addr at execution */
  Elf32_Off     sh_offset;              /* Section file offset */
  Elf32_Word    sh_size;                /* Section size in bytes */
  Elf32_Word    sh_link;                /* Link to another section */
  Elf32_Word    sh_info;                /* Additional section information */
  Elf32_Word    sh_addralign;           /* Section alignment */
  Elf32_Word    sh_entsize;             /* Entry size if section holds table */
} __attribute__((packed))  Elf32_Shdr;


int Load_ELF_into_memory(char * ELF_path, char** addr)
{
	//read the file size
	//read ELF header from FILE into memory
	FILE *f = fopen(ELF_path, "r");
	if(f > 0)
	{
		//get the elf file size
		fseek(f, 0L, SEEK_END);
		int elf_size = ftell(f);
		rewind(f);

		*addr = malloc(elf_size);
		printf("ELF %s opened, size %d bytes\n");
		fread(*addr, 1, elf_size, f);
		printf("ELF copied to %x\n", *addr);
		return elf_size;
	}
	printf("Error opening file %s\n", ELF_path);
	exit(-2);

}


void Program_Node(Xuint8 node, char* ELF_buff)
{
	int i, j;
	Target_Fn jump;
	Elf32_Ehdr *elf_header;
	Elf32_Phdr p_headers[PHEAD_SIZE];

	//wait for node to report 0xA1 (entered upload mode)
	printf("Waiting for node %d to output 0xA1\n", node);
	while(Centurion_Read_Debug(node) != 0xA1);

	//read ELF header
	elf_header = (Elf32_Ehdr*)ELF_buff;
	Xuint16 num_section_headers = elf_header->e_shnum;
	Elf32_Shdr *section_header_offset = (Xuint32)ELF_buff +  elf_header->e_shoff;
	Elf32_Phdr *program_header_offset = (Xuint32)ELF_buff +  elf_header->e_phoff;

#ifdef ELF_DEBUG
	printf("Number of program headers: %d\n", elf_header->e_phnum);
	printf("Size of program headers: %d\n", elf_header->e_phentsize);
	printf("Number of section headers: %d\n", elf_header->e_shnum);
	printf("Size of section headers: %d\n", elf_header->e_shentsize);
	printf("Section headers offset: %X\n", elf_header->e_shoff);
	printf("Sections headers at: %X , %X\n", ELF_buff, section_header_offset);
#endif

	//get the section strings section
	Xuint16 shstrtab = elf_header->e_shstrndx;
	Xuint8 *string_address = (Xuint32)ELF_buff + section_header_offset[shstrtab].sh_offset;
	printf("Section headers strings offset section %d : %X\n", shstrtab, string_address);
	//look for reload section
	Xuint32 reloader_header_offset = 0;
	Xuint32 stack_header_offset = 0;
	for (i = 0; i < num_section_headers; i++)
	{
		char * section_string = (char*)((Xuint32)string_address + section_header_offset[i].sh_name);
		printf("Section %d name: %s\n", i, section_string);
		if(strcmp(section_string, ".reloader") == 0)
			reloader_header_offset = section_header_offset[i].sh_offset;
		if(strcmp(section_string, ".stack") == 0)
			stack_header_offset = section_header_offset[i].sh_offset;
	}
	printf("Reloader section offset: %x\n", reloader_header_offset);
	printf("Stack section offset: %x\n", stack_header_offset);



	//send the reconfig command, number of segements and packet size


	Xuint8 buff[128];
	buff[0] = elf_header->e_phnum - 2;
	buff[1] = DATA_PACKET_SIZE_BYTES >> 8;
	buff[2] = DATA_PACKET_SIZE_BYTES & 0xFF;
//	NoC_if_Send_Data(0, node,1, 0, buff, 0, 3);
	Centurion_Write_Sys_Packet(node, buff, 3, 0, node);

	//send all of the program headers aside from the one with the section offset!
	for(i=0; i<elf_header->e_phnum; i++)
	{
		Elf32_Word p_offset = program_header_offset[i].p_offset;
		Elf32_Word p_address = program_header_offset[i].p_paddr;
		Elf32_Word p_size = program_header_offset[i].p_filesz;
		if(p_offset != reloader_header_offset && p_offset != stack_header_offset)
		{
			printf("Program header %d offset: %x\n", i, p_offset);
			printf("Program header %d size: %x\n", i, p_size);
			printf("Program header %d address: %x\n", i, p_address);

			printf("Sending segment to node %d \n", node);
			Xuint8 num_packets = (p_size / DATA_PACKET_SIZE_BYTES) + 1;
			printf("Number of packets %d \n", num_packets);

			//send segment addr
			buff[0] = p_address >> 8;
			buff[1] = p_address;

			//send segment size
			buff[2] = p_size >> 8;
			buff[3] = p_size;

			//send num packets
			buff[4] = num_packets;

			//NoC_if_Send_Data(0, node,1, 0, buff, 0, 5);
			Centurion_Write_Sys_Packet(node, buff, 5, 0, 0);

			Xuint8 *data_addr =  (Xuint32)ELF_buff + p_offset;
			for(j=0; j<num_packets; j++)
			{
				int num_bytes;
				if(j == num_packets -1)
					num_bytes = p_size;
				else
					num_bytes = DATA_PACKET_SIZE_BYTES;

				//NoC_if_Send_Data(0, node,1, 0, data_addr, 0, num_bytes);
				Centurion_Write_Sys_Packet(node, data_addr, num_bytes, 0, 0);

				data_addr += num_bytes;
				p_size -= num_bytes;
			}
		}
	}


/*
	//read program headers
	for (i = 0; i < elf_header.e_phnum; i++)
	{
		for (j = 0; j < elf_header.e_phentsize; j++)
		{
			((char*) &(p_headers[i]))[j] = address[i];
		}
	}


	//now load program sections
#ifdef ELF_DEBUG
	for (i = 0; i < elf_header.e_phnum; i++)
	{
		xil_printf("Header Load Address: %X\n", p_headers[i].p_paddr);
		xil_printf("Program header size: %X\n", p_headers[i].p_memsz);
	}
#endif

	for (i = 0; i < elf_header.e_phnum; i++)
	{
		address = p_headers[i].p_offset;
		for (j = 0; j < p_headers[i].p_filesz; j++)
		{
			((volatile char *) p_headers[i].p_paddr)[j] = address[i];
		}
	}

#ifdef ELF_DEBUG
	xil_printf("Program Loaded\n\n");
	xil_printf("Entry Point: %X\n", elf_header.e_entry);
	print ( "Program Loaded\n" ) ;
#endif

*/
}
