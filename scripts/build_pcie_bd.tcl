# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
source -notrace $thisDir/utils.tcl



# create source directories to package the IP cleanly
if {![file exists ./centurion_VC707]} {
   file mkdir ./centurion_VC707
}

if {![file exists ./centurion_VC707/hdl]} {
   file mkdir ./centurion_VC707/hdl
}

foreach f [glob ../hdl/VC707/*.vhd] {
   file copy -force $f ./centurion_VC707/hdl/
}

# create source directories to package the IP cleanly
if {![file exists ./dcp]} {
   file mkdir ./dcp
}


# Create project
create_project -force centurion_VC707 ./centurion_VC707/ -part xc7vx485tffg1761-2

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vc707:part0:1.4" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property target_language VHDL [current_project]


#build the list of source files
add_files [glob ./centurion_VC707/hdl/*.vhd]

#add source files to centurion library
#set_property library centurion [get_files *.vhd]

#add the constraint files
#add_files [glob ../xdc/*.xdc]

# setup up custom ip repository location
set_property ip_repo_paths "./centurion_IP" [current_fileset]
update_ip_catalog

#build the BD
source ../scripts/pcie_bd.tcl

set_param general.maxThreads 4
set_property synth_checkpoint_mode Singular [get_files */pcie_bd.bd]
#create_fileset -blockset -define_from zynq_bd zynq_bd
generate_target all [get_files */pcie_bd.bd]
create_ip_run [get_files */pcie_bd.bd]
launch_runs pcie_bd_synth_1
wait_on_run pcie_bd_synth_1 


write_checkpoint -force VC707_synth.dcp
opt_design
place_design
route_design
write_checkpoint -force VC707_impl.dcp

#disable combinatorial loop check (reqd for ring oscs)
set_property IS_ENABLED 0 [get_drc_checks {LUTLP-1}]
write_bitstream top


# If successful, "touch" a file so the make utility will know it's done 
touch {.build.done}

