/*
 * centurion_lib.h
 *
 *  Created on: 11 Jan 2019
 *      Author: mr589
 */

#ifndef SRC_CENTURION_LIB_H_
#define SRC_CENTURION_LIB_H_


#ifdef __cplusplus
extern "C" {
#endif

#define NOC_HEIGHT 8
#define NOC_WIDTH 8
#define NOC_NUM_NODES 64


//Xilinx types
typedef unsigned char	Xuint8;		/**< unsigned 8-bit */
typedef char		Xint8;		/**< signed 8-bit */
typedef unsigned short	Xuint16;	/**< unsigned 16-bit */
typedef short		Xint16;		/**< signed 16-bit */
typedef unsigned int	Xuint32;	/**< unsigned 32-bit */
typedef int		Xint32;		/**< signed 32-bit */
typedef float		Xfloat32;	/**< 32-bit floating point */
typedef double		Xfloat64;	/**< 64-bit double precision FP */
typedef unsigned long	Xboolean;	/**< boolean (XTRUE or XFALSE) */


//PCI driver interface

typedef struct {
	int reg;
	void * data;

}cent_PCI_cmd;

#define CENT_IOC_MAGIC '@' //64d is our major number, don't plug any radeon devices in!
#define CENT_IOC_NULL _IO(CENT_IOC_MAGIC, 0)
#define CENT_IOC_READ_DIP _IOR(CENT_IOC_MAGIC, 1, char)
#define CENT_IOC_WRITE_LEDS _IOW(CENT_IOC_MAGIC, 2, char)

#define CENT_IOC_RESET_NOC _IOW(CENT_IOC_MAGIC, 3, char)
#define CENT_IOC_RESET_RTC _IOW(CENT_IOC_MAGIC, 4, char)

#define CENT_IOC_NODE_DEBUG_READ _IOR(CENT_IOC_MAGIC, 5, char)

#define CENT_IOC_WRITE_REG32 _IOW(CENT_IOC_MAGIC, 6, char)
#define CENT_IOC_READ_REG32 _IOW(CENT_IOC_MAGIC, 7, char)

#define CENT_IOC_MAXNR 7



#define CENT_REG_NOC_CNTRL 0x00
#define CENT_REG_NOC_STATUS 0x04
#define CENT_REG_NOC_IF_CNTRL 0x08
#define CENT_REG_NOC_IF_STATUS 0x0C
#define CENT_REG_NOC_IF_TX_LEN 0x10
#define CENT_REG_NOC_IF_RX_LEN 0x14
#define CENT_REG_RTC_VALUE 0x18
#define CENT_REG_NODE_UART_SEL 0x1C
#define CENT_REG_NODE_DEBUG_SEL 0x20
#define CENT_REG_NODE_DEBUG_CMD 0x24
#define CENT_REG_NODE_DEBUG_CMD_VALID 0x28
#define CENT_REG_NODE_LOG_HS_LEN 0x2C
#define CENT_REG_NOC_DEBUG_DATA 0x30

#define CENT_NOC_TX_BASE 0x10000
#define CENT_NOC_RX_BASE 0x10000

#define CENT_NODE_LOG_DATA 0x20000

#define CENT_PCI_TEST_BRAM 0x40000
#define CENT_PCI_TEST_DIP 0x50000
#define CENT_PCI_TEST_LED 0x50008





void Centurion_Lib_init();
void Centurion_Reset_NoC();
void Centurion_Write_Sys_Packet(int node, Xuint8* data, Xuint32 length, Xuint32 is_RCAP_packet, Xuint32 header);
Xuint32 Centurion_Read_Blocking(Xuint8* data, Xuint32 max_length);
Xuint32 Centurion_Read_Non_Blocking(Xuint8* data, Xuint32 max_length);

void Centurion_Write_Reg(Xuint32 reg, Xuint32 data);
Xuint32 Centurion_Read_Reg(Xuint32 reg);
Xuint8 Centurion_Read_Debug(Xuint8 node);
void Centurion_Write_Debug(Xuint8 data);

double Centurion_benchmark_start();
double Centurion_benchmark_elapsed_us();

extern int cent_fd;

#ifdef __cplusplus
}
#endif

#endif /* SRC_CENTURION_LIB_H_ */
