######################################################################
#
# File name : centurion_axi_compile.do
# Created on: Tue Mar 19 14:42:36 +0000 2019
#




set REPO_ROOT_PATH ..
set CENT_SRC ../hdl
set BD_DIR $REPO_ROOT_PATH/build/centurion_IP/centurion_axi.ip_user_files/bd/centurion_node


set ROUTER_PSM_FILE $REPO_ROOT_PATH/sw/router_PSM/router.psm
set INTEL_PSM_FILE $REPO_ROOT_PATH/sw/intel_PSM/intel.psm

set SIM_ELF_FILE node_sw_sim/centurion_hello_world/Debug/centurion_hello_world.elf 


#generate the router PSM BRAM
opbasm -6 -d -m 1024 -s 256 -e 384 $ROUTER_PSM_FILE

#generate the intel PSM BRAM
opbasm -6 -d -m 1024 -s 256 -e 384 $INTEL_PSM_FILE


#generate the .mem file for loading the ELF into the node's BRAMs
data2mem -bm centurion_node.bmm -bd $SIM_ELF_FILE -bx . -u




if {[exec uname] == "Linux"} { 
    echo "Linux detected" 
    if {[exec hostname] == "elecpc279.its"} {
        set SIM_LIB_DIR "/opt/Xilinx/Vivado/2018.3/sim_libs"
        set VIVADO_ROOT "/opt/Xilinx/Vivado/2018.3"    
    } else {
        set SIM_LIB_DIR "/eda/xilinx/RHELx86/Vivado/2018.3/sim_libs/QUESTA-CORE-PRIME_10.6c-1/"
        set VIVADO_ROOT "/eda/xilinx/RHELx86/Vivado/2018.3"    
    }
} else {
    set SIM_LIB_DIR "C:/Xilinx/sim_libs"
    set VIVADO_ROOT "C:/Xilinx/Vivado/2018.3"
}


rm -rf questa_lib
mkdir questa_lib

vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xil_defaultlib
vlib questa_lib/msim/centurion

vlib questa_lib/msim/xpm

vmap unisim "$SIM_LIB_DIR/unisim"
vmap iomodule_v3_1_4  "$SIM_LIB_DIR/iomodule_v3_1_4"
vmap microblaze_v11_0_0  "$SIM_LIB_DIR/microblaze_v11_0_0"
vmap lmb_bram_if_cntlr_v4_0_15  "$SIM_LIB_DIR/lmb_bram_if_cntlr_v4_0_15"
vmap lmb_v10_v3_0_9  "$SIM_LIB_DIR/lmb_v10_v3_0_9"
vmap blk_mem_gen_v8_4_2  "$SIM_LIB_DIR/blk_mem_gen_v8_4_2"
vmap lib_cdc_v1_0_2  "$SIM_LIB_DIR/lib_cdc_v1_0_2"
vmap proc_sys_reset_v5_0_13  "$SIM_LIB_DIR/proc_sys_reset_v5_0_13"

vmap xil_defaultlib questa_lib/msim/xil_defaultlib
vmap centurion questa_lib/msim/centurion

vlog  -incr -sv -work centurion  \
"$VIVADO_ROOT/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom  -93 -work xpm  \
"$VIVADO_ROOT/data/ip/xpm/xpm_VCOMP.vhd" \


vcom -64 -93 -work xil_defaultlib  \
"$BD_DIR/ip/centurion_node_iomodule_0_0/sim/centurion_node_iomodule_0_0.vhd" \
"$BD_DIR/ip/centurion_node_microblaze_0_0/sim/centurion_node_microblaze_0_0.vhd" \
"$BD_DIR/ip/centurion_node_dlmb_bram_if_cntlr_0/sim/centurion_node_dlmb_bram_if_cntlr_0.vhd" \
"$BD_DIR/ip/centurion_node_dlmb_v10_0/sim/centurion_node_dlmb_v10_0.vhd" \
"$BD_DIR/ip/centurion_node_ilmb_bram_if_cntlr_0/sim/centurion_node_ilmb_bram_if_cntlr_0.vhd" \
"$BD_DIR/ip/centurion_node_ilmb_v10_0/sim/centurion_node_ilmb_v10_0.vhd" \

vlog -64 -incr -work xil_defaultlib  \
"$BD_DIR/ip/centurion_node_lmb_bram_0/sim/centurion_node_lmb_bram_0.v" \

vcom -64 -93 -work xil_defaultlib  \
"$BD_DIR/ip/centurion_node_proc_sys_reset_0_0/sim/centurion_node_proc_sys_reset_0_0.vhd" \

vlog -64 -incr -work xil_defaultlib  \
"$BD_DIR/sim/centurion_node.v" \


vcom  -64 -93 -work centurion  \
"$CENT_SRC/router/centurion_pkg.vhd" \
"$CENT_SRC/router/ring_osc.vhd" \
"$CENT_SRC/router/RO_temp_sensor.vhd" \
"$CENT_SRC/router/dynamic_node_clock.vhd" \
"$CENT_SRC/node/dual_port_RAM.vhd" \
"$CENT_SRC/node/dual_port_RAM_asymmetric_A32WR_B8R.vhd" \
"$CENT_SRC/node/many_core_node.vhd" \
"$CENT_SRC/router/switch.vhd" \
"$CENT_SRC/router/picoblaze_BRAM.vhd" \
"$CENT_SRC/router/router_cntrl.vhd" \
"$CENT_SRC/router/output_port_reg.vhd" \
"$CENT_SRC/router/router_config_port.vhd" \
"$CENT_SRC/router/input_fifo.vhd" \
"$CENT_SRC/router/kcpsm6.vhd" \
"$CENT_SRC/router/router_intelligence.vhd" \
"$CENT_SRC/router/centurion_router.vhd" \
"$CENT_SRC/noc/centurion_PE.vhd" \
"$CENT_SRC/noc/centurion_V2.vhd" \
"$CENT_SRC/axi_infrastructure/dual_port_ram_36.vhd" \
"$CENT_SRC/axi_infrastructure/noc_if.vhd" \
"$CENT_SRC/axi_infrastructure/dual_port_RAM_asymmetric_A32_B8.vhd" \
"$CENT_SRC/axi_infrastructure/noc_if_axi.vhd" \
"$CENT_SRC/centurion_axi.vhd" \

#compile sim helper module
vcom -64  -93 -work centurion "hdl/centurion_axi_sim_pkg.vhd"

#compile top module
vcom -64  -93 "hdl/centurion_VC707_tb.vhd"

vopt -64 +acc=npr -L blk_mem_gen_v8_4_2 centurion_axi_tb  -o centurion_axi_opt



# Call vsim to invoke simulator
vsim  -64 -t 1ps  -L unisim +notimingchecks -lib work centurion_axi_opt

view structure
view signals

#
# Source the user do file
do {wave.do}

#run 10us

proc rr {} {
    reload_and_restart 
}

proc reload_and_restart {} {
    global ROUTER_PSM_FILE
    global INTEL_PSM_FILE
    global SIM_ELF_FILE

    #generate the router PSM BRAM
    exec opbasm -6 -d $ROUTER_PSM_FILE

    #generate the intel PSM BRAM
    exec opbasm -6 -d $INTEL_PSM_FILE
    
    #generate the .mem file for loading the ELF into the node's BRAMs
    exec data2mem -bm centurion_node.bmm -bd $SIM_ELF_FILE -bx . -u
    
    restart -force
    
    run 10us

}


