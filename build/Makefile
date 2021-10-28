# these are the sources - everything depends upon them
ROOTDIR=..
RTL=$(ROOTDIR)/hdl/top/top.v $(ROOTDIR)/hdl/threeFlop/threeFlop.v $(ROOTDIR)/hdl/top/shift.v $(ROOTDIR)/hdl/top/iicWrapper.v
XDC=$(ROOTDIR)/xdc/top.xdc $(ROOTDIR)/xdc/top_io.xdc
IP=$(ROOTDIR)/ip/axi_iic_0/axi_iic_0.xci
DSP=$(ROOTDIR)/dsp/module_1_0/module_1_0.xci
BD=$(ROOTDIR)/bd/zynq_bd/zynq_bd.bd
CENTURION_IP=$(ROOTDIR)/hdl/router/*.vhd $(ROOTDIR)/hdl/node/*.vhd $(ROOTDIR)/hdl/axi_infrastructure/*.vhd  $(ROOTDIR)/hdl/noc/centurion_PE.vhd $(ROOTDIR)/hdl/noc/centurion_V2.vhd $(ROOTDIR)/hdl/centurion_axi.vhd

# compile options - do you want to reuse previous "golden" sources
# or rebuild everything from scratch locally from scripts
# set this TRUE to reuse sources from golden repo
# set this to anything else to rebuild everything from scripts
REUSEGOLDEN = FALSE

# if reusing golden data you do not need to wait for bd and ip generation
ifeq ($(REUSEGOLDEN), TRUE)
SETUPUDEPS =  $(RTL) $(XDC) $(IP) $(DSP) $(BD)
SETUPOPS = -source $(ROOTDIR)/scripts/setup.tcl -log setup.log -jou setup.jou -tclargs reuseGolden
CIPOPS = -source $(ROOTDIR)/scripts/cip.tcl -log cip.log -jou cip.jou -tclargs reuseGolden
else
SETUPDEPS =  $(RTL) $(XDC) $(DSP) .bd_gen.done .ip.done
SETUPOPS = -source $(ROOTDIR)/scripts/setup.tcl -log setup.log -jou setup.jou
CIPOPS = -source $(ROOTDIR)/scripts/build_centurion_IP.tcl -log cip.log -jou cip.jou
endif

# Common Vivado options
VIVADOCOMOPS = -mode batch

# # determine the OS shell - this make file should work on both linux and windows
# UNAME := $(shell uname)

# # on windows you have to prefix vivado call with a cmd shell with /c
# ifeq ($(UNAME), Linux)
# PREFIX = ""
# POSTFIX = ""
# else
# PREFIX = cmd /c "
# POSTFIX = "
# endif

# These are all the compilation targets, starting with "all"
all : centurion build 

# This setups up the top level project

build : .build.done
.build.done : .centurion_IP.done
	$(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/build_centurion_VC707.tcl -log build.log -jou build.jou $(POSTFIX)

centurion_sim : .centurion_IP_sim.done
.centurion_IP_sim.done : 
	$(PREFIX) vivado $(VIVADOCOMOPS) -source $(ROOTDIR)/scripts/build_centurion_IP_sim.tcl -log sim.log -jou sim.jou $(POSTFIX)

# This generates the packaged RTL for bft to be integrated into IPI
centurion : .centurion_IP.done
.centurion_IP.done : $(CENTURION_IP)
	$(PREFIX) vivado $(VIVADOCOMOPS) $(CIPOPS) $(POSTFIX)

# delete everything except this Makefile
clean :	
	ls -a | grep -v Makefile | xargs rm -rf
