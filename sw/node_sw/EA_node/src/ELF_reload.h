/*
 * ELF_reload.h
 *
 *  Created on: 21 Jan 2019
 *      Author: mr589
 */

#ifndef SRC_ELF_RELOAD_H_
#define SRC_ELF_RELOAD_H_

//Init_Barrier_Sync MUST BE DECLARED FIRST so that it gets the 0x50 address
void Init_Barrier_Sync(Xuint8 sync_value, Xuint32 timeout) __attribute__ ((section (".reloader")));
void reload_elf() __attribute__ ((section (".reloader")));


#endif /* SRC_ELF_RELOAD_H_ */
