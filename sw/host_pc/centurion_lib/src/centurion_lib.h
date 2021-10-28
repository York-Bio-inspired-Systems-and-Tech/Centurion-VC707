#ifndef SRC_CENTURION_LIB_H_
#define SRC_CENTURION_LIB_H_

/** @file */

#ifdef __cplusplus
extern "C" {
#endif


/** @brief Height of the NoC*/
#define NOC_HEIGHT 8 
/** @brief Width of the NoC*/
#define NOC_WIDTH 8
/** @brief Number of nodes in the NoC*/
#define NOC_NUM_NODES 64


/**
* @defgroup CENTURION_INTERNALS Internal Helper Functions and Types
* 
* For convenience and to match the data sizes used on the nodes, typedefs to the Xilinx types are defined
* here and used throughout this library. 
* 
* @{
*/
typedef unsigned char	Xuint8;		/**< unsigned 8-bit */
typedef char		Xint8;		/**< signed 8-bit */
typedef unsigned short	Xuint16;	/**< unsigned 16-bit */
typedef short		Xint16;		/**< signed 16-bit */
typedef unsigned int	Xuint32;	/**< unsigned 32-bit */
typedef int		Xint32;		/**< signed 32-bit */
typedef float		Xfloat32;	/**< 32-bit floating point */
typedef double		Xfloat64;	/**< 64-bit double precision FP */
/** @} */



/**
* @defgroup CENTURION_ADDRS Centurion PC Address Space
*  
* @brief Addresses of the registers and memory spaces within the Centurion AXI address range. 
* 
* The driver handles the upper 16 bits of the AXI address space (i.e. 0xAAAAxxxx) depending on
* the type of access and uses the larger addresses within this space to set the page access. 
* @{
*/
#define CENT_REG_NOC_CNTRL 0x00             /**< NoC Control -> [0]: NoC Reset [1]: RTC Reset*/
#define CENT_REG_NOC_STATUS 0x04            /**< NoC Status -> [0]: HS Log Busy */ 
#define CENT_REG_NOC_IF_CNTRL 0x08          /**< NoC IF Control -> [0]: TX Start [1]: RX Ack */ 
#define CENT_REG_NOC_IF_STATUS 0x0C         /**< NoC IF Status -> [0]: RX Done [1]: TX Busy */ 
#define CENT_REG_NOC_IF_TX_LEN 0x10         /**< NoC IF TX Length (12 bits)*/ 
#define CENT_REG_NOC_IF_RX_LEN 0x14         /**< NoC IF RX Length (12 bits)*/
#define CENT_REG_RTC_VALUE 0x18             /**< Read: RTC Value, Write: RTC Prescaler (150MHz)*/
#define CENT_REG_NODE_UART_SEL 0x1C         /**< Debug UART node select*/
#define CENT_REG_NODE_DEBUG_SEL 0x20        /**< Debug bus node select*/
#define CENT_REG_NODE_DEBUG_SRC_SEL 0x24    /**< Debug bus source/endpoint select. 0: Node Broadcast, 1: Single Node, 2: Single Router PB, 3: Single Intelligence PB*/
#define CENT_REG_NODE_DEBUG_CMD 0x28        /**< Read/Write: Debug bus value*/
#define CENT_REG_NOC_DEBUG_DATA 0x28        /**< Read/Write: Debug bus value*/
#define CENT_REG_NODE_DEBUG_CMD_VALID 0x2C  /**< Raises Debug interrupt on Node/router/intel/Broadcast*/
#define CENT_REG_NODE_LOG_HS_LEN 0x30       /**< Number of bytes to fetch from HS buffer*/


#define CENT_NOC_TX_BASE 0x10000            /**< Address of the NoC TX data buffer */
#define CENT_NOC_RX_BASE 0x10000            /**< Address of the NoC RX data buffer */

#define CENT_NODE_LOG_DATA 0x20000          /**< Address of the HS data buffer */

#define CENT_PCI_TEST_BRAM 0x40000          /**< Address of the PCIe test BRAM */
#define CENT_PCI_TEST_DIP 0x50000           /**< Address of the board DIP switches (for PCIe test)*/
#define CENT_PCI_TEST_LED 0x50008           /**< Address of the board LEDs (for PCIe test)*/

/** @} */





/**
* @defgroup CENTURION_CONFIG Setup and Low Level Configuration 
* 
* @brief Functions to setup up the driver and configure ancillary parts of the NoC.
* 
* This module contains the functions that sets up the driver and configure parts of Centurion
* that are not related to the NoC or debug interfaces. It also includes the functions for 
* accessing Centurion's AXI registers via IOCTL calls to the kernel driver, these can be used
* by a user application to control Centurion directly if preferred to the library functions.
* 
* Remember that all of these functions require a kernel mode access to write/read to the device.
* So bear in mind that accesses will incur a non-deterministic operating system latency.
* 
* @{
*/

/**
 * @brief Initialise the driver for use, call before using any of the Centurion functions.
 *
 * Connects to the PCIe device and checks for connection by setting the LEDs and 
 * reading the DIP switches. 
 * If there any issues with the driver/FPGA board will cause this function to exit
 * the program immediately. This function also clears the state of all of the 
 * node's debug registers.  
 *
 */
void Centurion_Lib_init();


/**
 * @brief Resets the NoC, including routers and intelligence. 
 * 
 * Issues and clears the NoC reset signal. This causes all router PicoBlazes, intelligence
 * PicoBlazes and state within the NoC to be reset. As the clock enable signals for the
 * nodes are set by the intelligence, this function will also stop the nodes and reset the
 * clock dividers to their reset values (150MHz).
 *
 */
void Centurion_Reset_NoC();

/**
 * @brief Sets the RTC tick prescaler from the 150MHz reference.
 * 
 * The RTC is incremented at every tick of the 32-bit prescaler (which runs free at 150MHz). So set
 * to 150 for a 1us tick, 150000 for a 1ms tick etc. Be aware that this function also resets the 
 * RTC after writing the new scaler value so that the change is applied.
 * 
 * @param value new prescaler value (32 bit).
 */
void Centurion_Set_RTC_Scaler(Xuint32 value);


/**
 * @brief Resets the RTC tick value and reloads prescaler with prescaler value.
 * 
 * Clears the RTC value back to 0 and reloads prescaler with prescaler value.
 */
void Centurion_Restart_RTC();

/**
 * @brief Returns the current RTC tick value
 *
 * Reads the CENT_REG_RTC_VALUE register.
 * @return The current RTC count value (32-bit unsigned).
 */
Xuint32 Centurion_Read_RTC();


/**
 * @brief Writes to a register on the Centurion AXI interface.
 * 
 * Writes a 32-bit value to the registers described in \ref CENTURION_ADDRS. The driver handles the
 * upper 16 bits of the AXI address space (i.e. 0xAAAAxxxx) for us.
 *  
 * @param reg Address of the register to write to (word aligned)
 * @param data 32-bit data to write to the register
 */
void Centurion_Write_Reg(Xuint32 reg, Xuint32 data);


/**
 * @brief Reads from a register on the Centurion AXI interface.
 * 
 * Reads a 32-bit value from the registers described in \ref CENTURION_ADDRS. The driver handles the
 * upper 16 bits of the AXI address space (i.e. 0xAAAAxxxx) for us.
 *  
 * @param reg Address of the register to write to (word aligned)
 * @return 32-bit data read from the register
 */
Xuint32 Centurion_Read_Reg(Xuint32 reg);

/**
 * @brief Access to the FD connected to the Centurion driver.
 * 
 * For low level access to the drive using the Linux char device functions i.e. \a ioctl(), 
 * \a read(), or \a write(). Not expected to be used in normal usage, but is exposed here 
 * should you wish to extend the driver.
 */
extern int cent_fd;
/** @} */


/**
* @defgroup CENTURION_NOC_PACKET Sending/Receiving data via the NoC
*  
* @brief Functions to write packets into the NoC and receive packets from the NoC.
* 
* Currently only blocking writes are supported but blocking and non-blocking reads are supported. 
* There is no technical reason for having other write/read schemes, they just need creating!
* 
* The data sides of these functions write to the NoC buffer memory spaces. The driver does not 
* currently check for out of bounds access so be careful with overrunning the buffer (both TX 
* and RX buffers are 4096 bytes long). If you do overrun the buffer then an invalid memory access
* will occur and the PC will crash. The system is OK to carry on using once restarted without 
* reprogramming the FPGA as the OS has stopped the invalid access before it happens.
* 
* @{
*/


/**
 * @brief Writes a "Sys" packet into the NoC
 * 
 * "Sys" packets use a deterministic routing path that is achieved by prepending directional tokens
 * to the data packet. The packet is first routed a number of hops south (0x1C2) and then a number 
 * of hops east (0x1C1) to reach the destination node. 
 * 
 * A directional token is then added that determines if the packet is for the node (0x1C4) or for 
 * the intelligence (RCAP, 0x1C5).
 * 
 * A 9-bit header then follows that the user can set. This is the first word to be delivered to the 
 * node/intelligence.
 * 
 * A marker byte is then added to show that this packet is from the PC. This value is "0xFF"
 *
 * The user data now follows, up to 4074 8-bit words. (n.b. the driver does not check for out of
 * bounds access so be careful with overrunning the buffer)
 *
 * Finally an EOP token (0x17F) is append to the end of the message.
 * 
 * The function then waits for the TX interface to be free (in user mode so as to not hang the kernel).
 * Once free the message is sent into the NoC. Due to the wormhole nature it may take a while before
 * the TX interface is free again for far away destinations in highly conjestion applications.
 *  
 * @param node Node ID of the destination node
 * @param data Pointer to the 8-bit user data
 * @param length Number of bytes to send (remote node RX buffers are 2048 bytes long)
 * @param is_RCAP_packet 0 -> data is sent to Node, 1 -> data is sent to Intelligence PicoBlaze
 * @param header 9-bit word that is the first data recieved by the endpoint
 * 
 * 
 */
void Centurion_Write_Sys_Packet(int node, Xuint8* data, Xuint32 length, Xuint32 is_RCAP_packet, Xuint32 header);


/**
 * @brief Reads a packet from the NoC, blocks until a packet is avaiable.
 * 
 * Waits for a packet to arrive. Once the packet arrives copies the length of the packet or until
 * max_length into the buffer provided.
 *  
 * @param data Pointer to the 8-bit data buffer
 * @param max_length Size of the 8-bit data buffer
 * @return Size of the recieved packet/number of bytes copied into data
 *
 * \todo{SW: add support for node + header}
 */
Xuint32 Centurion_Read_Blocking(Xuint8* data, Xuint32 max_length, Xuint16 *header, Xuint8 *node);



/**
 * @brief Reads a packet from the NoC, does not block if a packet is not avaliable.
 * 
 * If a packet is ready to be read then the function copies the length of the packet or until
 * max_length into the buffer provided. 
 * 
 * If a packet is not avaliable then the function returns immeatiatdly with a return of 0 to 
 * indicate no data has been read from the NoC RX buffer.
 *  
 * @param data Pointer to the 8-bit data buffer
 * @param max_length Size of the 8-bit data buffer
 * @return Size of the recieved packet/number of bytes copied into data, or 0 if a packet was 
 * not avaiable.
 *
 * \todo{SW: add support for node + header}
 */
Xuint32 Centurion_Read_Non_Blocking(Xuint8* data, Xuint32 max_length);



/** @} */


/**
* @defgroup CENTURION_DEBUG Debug Interface
* 
* @brief Functions that communicate via the node/router/intel debug interface 
* 
* Communication via the debug bus has four main purposes:
*       1. Broadcast a value to all nodes/router/intel
*       2. Monitoring the state of all nodes/router/intel 
*       3. Bi-directional communication directly with a single node
*       4. Issuing an interrupt to a single node/router/intel
*
* but also
*       5. High speed download of node logs (covered in \ref CENTURION_LOGGING).
* 
* The debug bus consists of a 8-bit PC->NoC signal, a 8-bit NoC->PC signal and a single bit interrupt.
* These are multiplexed within each node and CENT_REG_NODE_DEBUG_SRC_SEL is set to 
* reach/source the following endpoints:
*       0: Broadcast to all node MicroBlazes (stored within a register at each node)
*       1: Reach a single node MicroBlazes
*       2: Sent to all router PicoBlazes
*       3: Sent to all intelligence PicoBlazes
* 
* For the single node endpoint, CENT_REG_NODE_DEBUG_SEL is used to select the node. This 
* register is also used to determine which node receives the interrupt when CENT_REG_NODE_DEBUG_CMD_VALID
* is set to '1'.
* 
* This interrupt when routed to the PicoBlazes via CENT_REG_NODE_DEBUG_SRC_SEL can be used to selectively 
* send commands and data to individual PicoBlazes with use of their ISR, despite the global nature 
* of CENT_REG_NODE_DEBUG_SRC_SEL 2 and 3.
* 
* Some of the functions in this module are only used internally and their direct use is discouraged,
* however their documentation has been added in \ref CENTURION_DEBUG2 for reference as they may
* be handy when devising a particular experiment case. 
* 
* @{
*/


/** Centurion Interrupt commands. These are set when an interrupt is sent from the PC to the node
 *  Add you own here! Ensure that this list and the node software list match up.*/
typedef enum {  CENTURION_NODE_CMD_NULL,    /*!< 0 - Null command*/
                CENTURION_SET_NODE_RDO,     /*!< 1 - Set a Remote Data Object (RDO) on a node*/
                CENTURION_GET_NODE_RDO,     /*!< 2 - Get a Remote Data Object (RDO) from a node*/
                CENTURION_GET_LOGS_HS       /*!< 3 - Fetch the logs from a node using the high-speed interface  */
    
} Centurion_Remote_CMDs;




/**
 * @brief Writes an 9-bit value to all nodes
 * 
 * This value is stored in the nodes debug broadcast register. This ensures that even if a data
 * transfer via the debug bus is occurring on a different node, the node sees this value. 
 * This allows nodes to spinlock on the debug in without issue.
 * 
 * @param value 9-bit value to broadcast to all nodes

 */
void Centurion_Debug_Node_Broadcast(Xuint16 value);


/**
 * @brief Waits for the input debug bus to equal the value given
 * 
 * Make sure to set CENT_REG_NODE_DEBUG_SEL and CENT_REG_NODE_DEBUG_SRC_SEL using 
 * Centurion_node_sel(Xuint8 node) and Centurion_debug_src_sel(Xuint8 src) so that you 
 * are spinlocking on the required node and interface.
 * 
 * @param value 9-bit value to wait for debug input to match
 */
void Centurion_Debug_spinlock(Xuint32 value);


/**
 * @brief Writes a byte to a node using valid-flag handshaking
 * 
 * A software handshaking protocol between the node and PC allows data to be transferred via the 
 * debug bus despite the node running at a different clock frequency to the NoC. This function
 * transfers from the PC to the node. 
 * 
 * In the case that the node is not performing the handshake correctly, this function/read function
 * on the node may hang.
 * 
 * @param data 8-bit byte to transfer to the node
 */
void Centurion_Node_Write_Debug_Safe(Xuint8 data);


/**
 * @brief Reads a byte from a node using valid-flag handshaking
 * 
 * A software handshaking protocol between the node and PC allows data to be transferred via the 
 * debug bus despite the node running at a different clock frequency to the NoC. This function
 * transfers from the node to the PC. 
 * 
 * In the case that the node is not performing the handshake correctly, this function/write function
 * on the node may hang.
 * 
 * @return 8-bit byte to transferred from the node 
 * 
 */
Xuint8 Centurion_Node_Read_Debug_Safe();


/**
 * @brief Raises an interrupt on the node and sets the interrupt type
 *
 * Sets an interrupt on a node and uses Centurion_Node_Write_Debug_Safe() to write a command 
 * vector into the ISR. The command is to be one of the ::Centurion_Remote_CMDs options to allow the
 * \c switch-case in the node ISR to perform the correct action.
 * 
 * In the case that the node does not enter the interrupt (interrupts disabled?) this function
 * will hang due to the handshake failing.
 * 
 * @param node Node to interrupt
 * @param command Command to issue to the ISR
 * 
 */
void Centurion_Node_Interrupt(Xuint8 node, Centurion_Remote_CMDs command);

/**
 * @brief Writes to a node's memory (using a Remote Data Object address)
 *
 * Interrupts a node and enters the write RDO ISR. The ISR looks the selected address up from 
 * the RDO table and then reads the required number of bytes from the debug interface and writes them to 
 * the selected memory address. The MicroBlazes are configured to be little endian, so no byte-swapping
 * should be required for setting ints/floats/long longs from x64 machines.
 * 
 * In the case that the node does not enter the interrupt or incorrect handshaking this function
 * will hang due to the handshake failing.
 * 
 * @param node Node to set the RDO for
 * @param object_index RDO to set
 * @param size Number of bytes to write to the RDO location
 * @param data Pointer to data to write to the RDO
 * 
 */
void Centurion_Node_RDO_Write(Xuint8 node, Xuint8 object_index, Xuint8 size, Xuint8 *data);

/**
 * @brief Reads from a node's memory (using a Remote Data Object address)
 *
 * Interrupts a node and enters the read RDO ISR. The ISR looks the selected address up from 
 * the RDO table and then writes the required number of bytes to the debug interface from the
 * selected memory address. The MicroBlazes are configured to be little endian, so no byte-swapping
 * should be required for reading ints/floats/long longs from x64 machines.
 * 
 * In the case that the node does not enter the interrupt or incorrect handshaking this function
 * will hang due to the handshake failing.
 * 
 * @param node Node to get the RDO from
 * @param object_index RDO to get
 * @param size Number of bytes to read from the RDO location
 * @param data Pointer to location to write the RDO data to
 */
void Centurion_Node_RDO_Read(Xuint8 node, Xuint8 object_index, Xuint8 size, Xuint8 *data);

/**
 * @breif Reads a single byte from the debug interface of a node
 * 
 * The value of the PC debug interface can be set by the nodes by writing to the \c DEBUG_OUT
 * port on the node. This function will read this value for the given node
 * 
 * @param node Node to read the debug value from
 * @return 8-bit debug data
 */
Xuint8 Centurion_Read_Debug(Xuint8 node);


/**
 * @breif Waits for all nodes to output a certain value on their debug interface
 * 
 * Loops through all nodes in sequence and will keep reading from the node's debug interface
 * until it equals the given value.
 * 
 * @param value The 8-bit value that all nodes must output on their debug interface for
 * execution to progess beyond this function.
 */
void Centurion_Read_Debug_Barrier_Sync(Xuint8 value);

/**
 * @brief Raises an interrupt on a given PicoBlaze and issues a command for it to read
 * 
 * Either the router or the intelligence PicoBlaze can be the destination for the interrupt. 
 * The router or the intelligence debug interface is set to the value of command so the 
 * interrupted PicoBlaze can read the PC debug interface to find out what it should do 
 * with the interrupt.
 * 
 * @param node Node ID of the PicoBlaze to interrupt
 * @param intel_sel 0: Router PicoBlaze 1: Intelligence PicoBlaze
 * @param command 8-bit value that is set on the debug interface
 */
void Centurion_Picoblaze_Interrupt(Xuint8 node, Xuint8 intel_sel, Xuint8 command);


/**
* @defgroup CENTURION_DEBUG2 Debug Internal Functions
* 
* @brief Functions that support the debug intefaces
* 
* These functions are used internally by the debug functions. They could be of use if 
* a user wants to write their own protocols on top of the debug interface or do anything 
* more complex than currently offered by the libray functions.
* 
* @{
*/

/**
 * @brief Writes a byte to the debug register
 * 
 * A raw write to the debug interface, use of Centurion_Node_Sel(Xuint8 node) and 
 * void Centurion_Debug_Src_Sel(Xuint8 src) is required prior to this function to ensure
 * the correct debug interface is written to (registered on the PE side)
 * 
 * @param data 8-bit value to write
 */
void Centurion_Write_Debug(Xuint8 data);


/**
 * @brief Selects the node that is connected to the debug interface
 *
 * Depending on the debug endpoint this function will have different effects. For endpoint 1 
 * it will select the node used for direct communication between PC and a node.
 * 
 * For other endpoints it sets which node recieves the interrupt and also what debug interface 
 * is connected to the debug input to the PC.
 *  
 * @param node Node ID of node to interface with
 */
inline void Centurion_Node_Sel(Xuint8 node);


/**
 * @brief Selects the debug interface endpoint that PC will communicate with
 *
* These are multiplexed within each node and CENT_REG_NODE_DEBUG_SRC_SEL is set to 
* reach/source the following endpoints:
*       0: Broadcast to all node MicroBlazes (stored within a register at each node)
*       1: Reach a single node MicroBlazes
*       2: Sent to all router PicoBlazes
*       3: Sent to all intelligence PicoBlazes
* 
 * @param src 2-bit signal that selects the debug enpoint
 */
inline void Centurion_Debug_Src_Sel(Xuint8 src);


/**
 * @brief Spinlocks on the 9th bit of the debug command (valid bit)
 *
 * The spinlock continously reads from the debug interface until the value of this bit
 * matches the given value (i.e. 0 or 1). The debug value (bits 7-0) is masked out of the 
 * valid check. 
 * 
 * @param value 9-bit value that is comparted to the active debug interface. Only the 
 * 9th bit is checked against the debug interface (e.g. use 0x100 to spinlock on '1' or 
 * 0x000 to spinlock on '0').
 */
void Centurion_Debug_Valid_spinlock(Xuint32 value);




/** @} */
/** @} */


/**
* @defgroup CENTURION_LOGGING Logging and HS Buffer Functions
* 
* @brief Functions that support downloading of node logs via the high-speed debug interface.
* 
* To download data from the 4KB high-speed buffer on each node, first the PC must interrupt 
* the node to find out how much data needs to be transferred (using Centurion_Node_RDO_Read() )
* It then starts the high-speed transfer by setting the high-speed transfer length register
* and monitors to high-speed transfer status bit in \c CENT_REG_NOC_STATUS. Once this has been
* cleared the data is ready to be read from the PC HS buffer address space via the kernel
* driver.
* 
* This module also contains a few functions for printing the logs and storing them to a file
* 
* @{
*/


/**
 * @brief Sets the driver to use the HS buffer address space (as opposed to the NoC buffer)
 * 
 * The HS buffer is on a different memory space and so the PCIe driver needs to set the upper
 * address bits to access this address space. Once this function is called \c read() can be
 * used to read data from the HS buffer.
 * 
 */
void Centurion_Set_IO_HS();


/**
 * @brief Reads a number of 32-bit words from the HS buffer (max 4KB, 1K words)
 *
 * Issues the \c read() function to the driver which fetches a number of 32-bit words from 
 * the HS buffer.
 * 
 * @param buff Address of a 32-bit data buffer to store the fetched data
 * @param size Number of 32 bit words to read (max size 1K words)
 */
void Centurion_Read_HS(Xuint32 *buff, int size);

/**
 * @brief fetches the avaiable log data from a node and stores in a buffer
 * 
 * Implements the procedure for fetching log data from a node. Gets the log length 
 * and then loads this value into the HS debug interface. The interface moves the node log
 * data into the PC HS buffer. The driver then copies this data into the user specified 
 * buffer and returns the number of logs downloaded.
 * 
 * If there are no logs to fetch from the node then the function will still query the node 
 * but will not transfer any data and will simply return 0. Thus it is safe to call this
 * function even if there are no data to be collected from the node.
 * 
 * @param node Node ID of the node where the data should be fetched from
 * @param buff Address of a 32-bit data buffer to store the fetched data, ensure that this 
 * is large enough to contain the largest number of logs (4KB, 1K 32-bit words).
 * @return Number of log entries fetched from the node (size bytes / 8).
 */
Xuint16 Centurion_Fetch_Node_Logs_HS(Xuint8 node, Xuint32 *data_buff);

/**
 * @brief Prints the logs to the console or a file
 * 
 * Given a log buffer this function will either print the log information in a CSV format
 * to the console or append the log file given. 
 *
 * @param log_data Address of the log buffer
 * @param filename Name of the file to output to. A \c NULL here will result in the log 
 * information being printed to the console
 * @param num_to_print The number of log entries to print to the console or append to the file.
 */
void Centurion_Print_Logs(Xuint32* log_data, char *filename, int num_to_print);


/** @} */










#ifdef __cplusplus
}
#endif

#endif /* SRC_CENTURION_LIB_H_ */
