# get the directory where this script resides
set thisDir [file dirname [info script]]
# source common utilities
source -notrace $thisDir/utils.tcl
set build_dir $thisDir/../build/
set dcp_dir ./centurion_VC707/dcp

# Create project
set_part xc7vx485tffg1761-2
# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:vc707:part0:1.4" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property target_language VHDL [current_project]


#add the constraint files
add_files [glob ../xdc/*.xdc]

set_param general.maxThreads 32

open_checkpoint $dcp_dir/post_synth.dcp

# STEP#3: run placement and logic optimzation, report utilization and timing estimates, write checkpoint design
#
opt_design -directive Explore
write_checkpoint -force $dcp_dir/post_opt

place_design -directive Explore
phys_opt_design -directive Explore
write_checkpoint -force $dcp_dir/post_place
report_timing_summary -file $dcp_dir/post_place_timing_summary.rpt

# STEP#4: run router, report actual utilization and timing, write checkpoint design, run drc, write verilog and xdc out
#
route_design -directive Explore
write_checkpoint -force $dcp_dir/post_route
report_timing_summary -file $dcp_dir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $dcp_dir/post_route_timing.rpt
report_clock_utilization -file $dcp_dir/clock_util.rpt
report_utilization -file $dcp_dir/post_route_util.rpt
report_power -file $dcp_dir/post_route_power.rpt
report_drc -file $dcp_dir/post_imp_drc.rpt
write_verilog -force $dcp_dir/bft_impl_netlist.v
write_xdc -no_fixed_only -force $dcp_dir/bft_impl.xdc

#write MMI info to files
source ../scripts/MMI_nodes.tcl


# STEP#5: generate a bitstream
# 
write_bitstream -force ./centurion_VC707.bit 



# 
# 
# # Out-Of-Context synthesis for IPs
# foreach ip [get_ips] {
#   set ip_filename [get_property IP_FILE $ip]
#   set ip_dcp [file rootname $ip_filename]
#   append ip_dcp ".dcp"
#   set ip_xml [file rootname $ip_filename]
#   append ip_xml ".xml"
#   
#   
# 
#    if {([file exists $ip_dcp] == 0) || [expr {[file mtime $ip_filename ] > [file mtime $ip_dcp ]}]} {
#         puts $ip_dcp
# #     # remove old files of IP, if still existing
# #    reset_target all $ip
#      file delete $ip_xml
# # 
# #     # re-generate the IP
#      generate_target all $ip
#      set_property generate_synth_checkpoint true [get_files $ip_filename]
#      synth_ip $ip
#    }
# }
# 
# synth_design -top pcie_bd_wrapper
# write_checkpoint -force VC707_synth.dcp
# opt_design
# place_design
# route_design
# write_checkpoint -force VC707_impl.dcp
# 
# #disable combinatorial loop check (reqd for ring oscs)
# set_property IS_ENABLED 0 [get_drc_checks {LUTLP-1}]
# write_bitstream top


# If successful, "touch" a file so the make utility will know it's done 
touch {.build.done}

