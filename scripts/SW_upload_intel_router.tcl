
if {[info exists intel_mem_filename] == 0} {
    puts "ERROR: intel_mem_filename not set"
    return
}

if {[info exists router_mem_filename] == 0} {
    puts "ERROR: router_mem_filename not set"
    return
}


#load the intel
set mem_filename $intel_mem_filename
set BRAM_LENGTH_WORDS 1024
set BRAM_inst_name intel_picoblaze_BRAM

source ../scripts/SW_load_picoblaze.tcl

#load the router
set mem_filename $router_mem_filename
set BRAM_LENGTH_WORDS 1024
set BRAM_inst_name cntrl_picoblaze_BRAM

source ../scripts/SW_load_picoblaze.tcl
