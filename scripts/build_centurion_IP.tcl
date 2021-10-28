# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
source -notrace $thisDir/utils.tcl

# create source directories to package the IP cleanly
if {![file exists ./centurion_IP]} {
   file mkdir ./centurion_IP
}

#Vivado insists that the IP sources are accessible in a sub dir...
if {![file exists ./centurion_IP/hdl]} {
   file mkdir ./centurion_IP/hdl
}
if {![file exists ./centurion_IP/hdl/axi_infrastructure]} {
   file mkdir ./centurion_IP/hdl/axi_infrastructure
}
if {![file exists ./centurion_IP/hdl/noc]} {
   file mkdir ./centurion_IP/hdl/noc
}
if {![file exists ./centurion_IP/hdl/node]} {
   file mkdir ./centurion_IP/hdl/node
}
if {![file exists ./centurion_IP/hdl/router]} {
   file mkdir ./centurion_IP/hdl/router
}

foreach f [glob ../hdl/*.vhd] {
   file copy -force $f ./centurion_IP/hdl/
}
foreach f [glob ../hdl/axi_infrastructure/*.vhd] {
   file copy -force $f ./centurion_IP/hdl/axi_infrastructure/
}
foreach f [glob ../hdl/noc/*.vhd] {
   file copy -force $f ./centurion_IP/hdl/noc/
}
foreach f [glob ../hdl/node/*.vhd] {
   file copy -force $f ./centurion_IP/hdl/node/
}
foreach f [glob ../hdl/router/*.vhd] {
   file copy -force $f ./centurion_IP/hdl/router/
}

# Create project
create_project -force centurion_axi ./centurion_IP/ -part xc7vx485tffg1761-2
set_property target_language VHDL [current_project]

#build the list of source files
add_files [glob ./centurion_IP/hdl/*.vhd]
add_files [glob ./centurion_IP/hdl/axi_infrastructure/*.vhd]
add_files [glob ./centurion_IP/hdl/noc/*.vhd]
add_files [glob ./centurion_IP/hdl/node/*.vhd]
add_files [glob ./centurion_IP/hdl/router/*.vhd]

#add source files to centurion library
set_property library centurion [get_files *.vhd]

#build the BD
source ../scripts/centurion_node_BD.tcl

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

#generate simulation IP files
launch_simulation -scripts_only

set_param general.maxThreads 4
#set TIME_start [clock clicks -milliseconds]
#synth_design -top centurion_axi -mode out_of_context 
#set TIME_taken [expr [clock clicks -milliseconds] - $TIME_start]

#write_checkpoint -force ./centurion_IP/centurion_IP_synth.dcp
#puts "INFO:  Synthesis took $TIME_taken ms"

set_property synth_checkpoint_mode Singular [get_files */centurion_node.bd]
#create_fileset -blockset -define_from zynq_bd zynq_bd
generate_target all [get_files */centurion_node.bd]
create_ip_run [get_files */centurion_node.bd]
launch_runs centurion_node_synth_1
wait_on_run centurion_node_synth_1 

#make the wrapper for the IP
make_wrapper -files [get_files ./centurion_IP/centurion_axi.srcs/sources_1/bd/centurion_node/centurion_node.bd] -fileset [get_filesets centurion_node] -inst_template
add_files -norecurse ./centurion_IP/centurion_axi.srcs/sources_1/bd/centurion_node/hdl/centurion_node_wrapper.vhd
update_compile_order -fileset sources_1

launch_runs synth_1 -jobs 4

wait_on_run synth_1

ipx::package_project -root_dir ./centurion_IP -library centurion -vendor mr589

# If successful, "touch" a file so the make utility will know it's done 
touch {.centurion_IP.done}
touch {.centurion_IP_sim.done}
