
################################################################
# This is a generated script based on design: centurion_node
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2018.3
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source centurion_node_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7vx485tffg1761-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name centurion_node

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:iomodule:3.1\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:lmb_v10:3.0\
xilinx.com:ip:blk_mem_gen:8.4\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB
  create_bd_intf_pin -mode MirroredSlave -vlnv xilinx.com:interface:lmb_rtl:1.0 LMB_Sl_1

  # Create pins
  create_bd_pin -dir I -type clk Clk
  create_bd_pin -dir I -type rst SYS_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]
  set_property -dict [ list \
   CONFIG.C_LMB_NUM_SLAVES {2} \
 ] $dlmb_v10

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create instance: lmb_bram, and set properties
  set lmb_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 lmb_bram ]
  set_property -dict [ list \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $lmb_bram

  # Create interface connections
  connect_bd_intf_net -intf_net dlmb_v10_iomodule_0 [get_bd_intf_pins LMB_Sl_1] [get_bd_intf_pins dlmb_v10/LMB_Sl_1]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_cntlr [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_cntlr [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins lmb_bram/BRAM_PORTB]

  # Create port connections
  connect_bd_net -net SYS_Rst_1 [get_bd_pins SYS_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]
  connect_bd_net -net microblaze_0_Clk [get_bd_pins Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set Clk [ create_bd_port -dir I -type clk Clk ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {150000000} \
 ] $Clk
  set GPI1 [ create_bd_port -dir I -from 31 -to 0 GPI1 ]
  set GPI2 [ create_bd_port -dir I -from 8 -to 0 GPI2 ]
  set GPO1 [ create_bd_port -dir O -from 8 -to 0 GPO1 ]
  set INTC_Interrupt [ create_bd_port -dir I -from 4 -to 0 -type intr INTC_Interrupt ]
  set_property -dict [ list \
   CONFIG.PortWidth {5} \
 ] $INTC_Interrupt
  set IO_Addr_Strobe [ create_bd_port -dir O IO_Addr_Strobe ]
  set IO_Address [ create_bd_port -dir O -from 31 -to 0 IO_Address ]
  set IO_Byte_Enable [ create_bd_port -dir O -from 3 -to 0 IO_Byte_Enable ]
  set IO_Read_Data [ create_bd_port -dir I -from 31 -to 0 IO_Read_Data ]
  set IO_Read_Strobe [ create_bd_port -dir O IO_Read_Strobe ]
  set IO_Ready [ create_bd_port -dir I IO_Ready ]
  set IO_Write_Data [ create_bd_port -dir O -from 31 -to 0 IO_Write_Data ]
  set IO_Write_Strobe [ create_bd_port -dir O IO_Write_Strobe ]
  set Reset [ create_bd_port -dir I -type rst Reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $Reset
  set UART_Tx [ create_bd_port -dir O UART_Tx ]

  # Create instance: iomodule_0, and set properties
  set iomodule_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:iomodule:3.1 iomodule_0 ]
  set_property -dict [ list \
   CONFIG.C_GPI2_SIZE {9} \
   CONFIG.C_GPO1_INIT {0x000000AA} \
   CONFIG.C_GPO1_SIZE {9} \
   CONFIG.C_INTC_IRQ_CONNECTION {0} \
   CONFIG.C_INTC_USE_EXT_INTR {1} \
   CONFIG.C_UART_BAUDRATE {921600} \
   CONFIG.C_USE_GPI1 {1} \
   CONFIG.C_USE_GPI2 {1} \
   CONFIG.C_USE_GPO1 {1} \
   CONFIG.C_USE_GPO2 {0} \
   CONFIG.C_USE_IO_BUS {1} \
   CONFIG.C_USE_UART_TX {1} \
 ] $iomodule_0

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_TAG_BITS {0} \
   CONFIG.C_DCACHE_ADDR_TAG {0} \
   CONFIG.C_DEBUG_ENABLED {0} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_USE_BARREL {1} \
   CONFIG.C_USE_BRANCH_TARGET_CACHE {0} \
   CONFIG.C_USE_DIV {1} \
   CONFIG.C_USE_HW_MUL {1} \
   CONFIG.C_USE_PCMP_INSTR {1} \
 ] $microblaze_0

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create interface connections
  connect_bd_intf_net -intf_net dlmb_v10_iomodule_0 [get_bd_intf_pins iomodule_0/SLMB] [get_bd_intf_pins microblaze_0_local_memory/LMB_Sl_1]
  connect_bd_intf_net -intf_net iomodule_0_INTC_Irq [get_bd_intf_pins iomodule_0/INTC_Irq] [get_bd_intf_pins microblaze_0/INTERRUPT]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]

  # Create port connections
  connect_bd_net -net GPI1_1 [get_bd_ports GPI1] [get_bd_pins iomodule_0/GPI1]
  connect_bd_net -net GPI2_1 [get_bd_ports GPI2] [get_bd_pins iomodule_0/GPI2]
  connect_bd_net -net INTC_Interrupt_1 [get_bd_ports INTC_Interrupt] [get_bd_pins iomodule_0/INTC_Interrupt]
  connect_bd_net -net IO_Read_Data_1 [get_bd_ports IO_Read_Data] [get_bd_pins iomodule_0/IO_Read_Data]
  connect_bd_net -net IO_Ready_1 [get_bd_ports IO_Ready] [get_bd_pins iomodule_0/IO_Ready]
  connect_bd_net -net Reset_1 [get_bd_pins iomodule_0/Rst] [get_bd_pins microblaze_0_local_memory/SYS_Rst] [get_bd_pins proc_sys_reset_0/bus_struct_reset]
  connect_bd_net -net Reset_2 [get_bd_ports Reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net iomodule_0_GPO1 [get_bd_ports GPO1] [get_bd_pins iomodule_0/GPO1]
  connect_bd_net -net iomodule_0_IO_Addr_Strobe [get_bd_ports IO_Addr_Strobe] [get_bd_pins iomodule_0/IO_Addr_Strobe]
  connect_bd_net -net iomodule_0_IO_Address [get_bd_ports IO_Address] [get_bd_pins iomodule_0/IO_Address]
  connect_bd_net -net iomodule_0_IO_Byte_Enable [get_bd_ports IO_Byte_Enable] [get_bd_pins iomodule_0/IO_Byte_Enable]
  connect_bd_net -net iomodule_0_IO_Read_Strobe [get_bd_ports IO_Read_Strobe] [get_bd_pins iomodule_0/IO_Read_Strobe]
  connect_bd_net -net iomodule_0_IO_Write_Data [get_bd_ports IO_Write_Data] [get_bd_pins iomodule_0/IO_Write_Data]
  connect_bd_net -net iomodule_0_IO_Write_Strobe [get_bd_ports IO_Write_Strobe] [get_bd_pins iomodule_0/IO_Write_Strobe]
  connect_bd_net -net iomodule_0_UART_Tx [get_bd_ports UART_Tx] [get_bd_pins iomodule_0/UART_Tx]
  connect_bd_net -net microblaze_0_Clk [get_bd_ports Clk] [get_bd_pins iomodule_0/Clk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_local_memory/Clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins proc_sys_reset_0/mb_reset]

  # Create address segments
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] SEG_dlmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x00008000 -offset 0x00000000 [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] SEG_ilmb_bram_if_cntlr_Mem
  create_bd_addr_seg -range 0x10000000 -offset 0xC0000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs iomodule_0/SLMB/IO] SEG_iomodule_0_IO
  create_bd_addr_seg -range 0x00010000 -offset 0x80000000 [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs iomodule_0/SLMB/Reg] SEG_iomodule_0_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


