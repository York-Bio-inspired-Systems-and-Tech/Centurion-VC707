write_cfgmem -force -format mcs -interface bpix16 -size 128  -loadbit "up 0x0 centurion_VC707_bootloader.bit" -file centurion_flash.mcs
open_hw
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7vx485t_0]
create_hw_cfgmem -hw_device [lindex [get_hw_devices xc7vx485t_0] 0] [lindex [get_cfgmem_parts {mt28gu01gaax1e-bpi-x16}] 0]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
refresh_hw_device [lindex [get_hw_devices xc7vx485t_0] 0]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.FILES [list "centurion_flash.mcs" ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.BPI_RS_PINS {none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
startgroup
create_hw_bitstream -hw_device [lindex [get_hw_devices xc7vx485t_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7vx485t_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7vx485t_0] 0]; refresh_hw_device [lindex [get_hw_devices xc7vx485t_0] 0];
program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7vx485t_0] 0]]
endgroup
boot_hw_device [current_hw_device]

