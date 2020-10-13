# This work for latest vivado (2020.1)
# It might not work on old or newer ones in the future.
FPGA_BOARD_PART = xilinx.com:vcu118:part0:2.3
FPGA_PART = xcvu9p-flga2104-2L-e

FPGA_TOP = fpga
FPGA_ARCH = virtexuplus

# Files for synthesis
SYN_FILES = rtl/fpga.v
SYN_FILES += rtl/fpga_core.v
SYN_FILES += rtl/debounce_switch.v
SYN_FILES += rtl/sync_signal.v
SYN_FILES += rtl/common/cmac_pad.v
SYN_FILES += lib/axis/rtl/axis_adapter.v
SYN_FILES += lib/axis/rtl/axis_async_fifo.v
SYN_FILES += lib/axis/rtl/axis_fifo.v
SYN_FILES += lib/axis/rtl/axis_register.v
SYN_FILES += lib/axis/rtl/sync_reset.v

# XDC files
XDC_FILES = fpga.xdc
XDC_FILES += lib/axis/syn/axis_async_fifo.tcl
XDC_FILES += lib/axis/syn/sync_reset.tcl
XDC_FILES += ../../../common/syn/tdma_ber_ch.tcl

# IP
IP_TCL_FILES = ip/cmac_usplus_0.tcl
IP_TCL_FILES += ip/cmac_usplus_1.tcl
IP_TCL_FILES += ip/create_sysctl_bd.tcl

# Patch directory (if any)
SYN_FILES_REL = $(patsubst %, %, $(SYN_FILES))
INC_FILES_REL = $(patsubst %, %, $(INC_FILES))
XCI_FILES_REL = $(patsubst %, %, $(XCI_FILES))
IP_TCL_FILES_REL = $(patsubst %, %, $(IP_TCL_FILES))
XDC_FILES_REL = $(patsubst %, %, $(XDC_FILES))

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and project files
###################################################################

# phony targets
.PHONY: clean all

.DEFAULT_GOAL := all

VIVADO_PROJECT_NAME=supernic_fpga
VIVADO_PROJECT_FOLDER=generated_vivado_project
TCL_CREATE_PROJECT=$(VIVADO_PROJECT_FOLDER)/create_project.tcl
TCL_SYNTHESIS=$(VIVADO_PROJECT_FOLDER)/run_synth.tcl
TCL_IMPL=$(VIVADO_PROJECT_FOLDER)/run_impl.tcl

clean:
	rm -rf *.bit program.tcl generate_mcs.tcl *.mcs *.prm flash.tcl
	rm -rf .Xil
	rm -rf $(VIVADO_PROJECT_FOLDER)

# Create the Vivado project.
# We will not run Synthesis and Implementation here.
all:
	mkdir -p $(VIVADO_PROJECT_FOLDER)
	echo "create_project $(VIVADO_PROJECT_NAME) "./$(VIVADO_PROJECT_FOLDER)" -part $(FPGA_PART) $*" > $(TCL_CREATE_PROJECT)
	echo "set_property -name "board_part" -value $(FPGA_BOARD_PART)"
	for x in $(SYN_FILES_REL); do echo "import_files -fileset sources_1 $$x" >> $(TCL_CREATE_PROJECT); done
	for x in $(XDC_FILES_REL); do echo "import_files -fileset constrs_1 $$x" >> $(TCL_CREATE_PROJECT); done
	for x in $(XCI_FILES_REL); do echo "import_ip $$x" >> $(TCL_CREATE_PROJECT); done
	for x in $(IP_TCL_FILES_REL); do echo "source $$x" >> $(TCL_CREATE_PROJECT); done
	echo "exit" >> $(TCL_CREATE_PROJECT)
	vivado -nojournal -nolog -mode batch -source $(TCL_CREATE_PROJECT)

# Open GUI
g:
	vivado -nojournal -nolog $(VIVADO_PROJECT_FOLDER)/$(VIVADO_PROJECT_NAME)

# Run synthesis
syn:  $(SYN_FILES_REL) $(INC_FILES_REL) $(XDC_FILES_REL)
	echo "open_project $(VIVADO_PROJECT_FOLDER)/$(VIVADO_PROJECT_NAME).xpr" > $(TCL_SYNTHESIS)
	echo "reset_run synth_1" >> $(TCL_SYNTHESIS)
	echo "launch_runs synth_1" >> $(TCL_SYNTHESIS)
	echo "wait_on_run synth_1" >> $(TCL_SYNTHESIS)
	echo "exit" >> $(TCL_SYNTHESIS)
	vivado -nojournal -nolog -mode batch -source $(TCL_SYNTHESIS)

# Run implementation (Place and Route)
impl:
	echo "open_project $*.xpr" > $(TCL_IMPL)
	echo "reset_run impl_1" >> $(TCL_IMPL)
	echo "launch_runs impl_1" >> $(TCL_IMPL)
	echo "wait_on_run impl_1" >> $(TCL_IMPL)
	echo "exit" >> $(TCL_IMPL)
	vivado -nojournal -nolog -mode batch -source $(TCL_IMPL)

# bit file
%.bit: %.runs/impl_1/%_routed.dcp
	echo "open_project $*.xpr" > generate_bit.tcl
	echo "open_run impl_1" >> generate_bit.tcl
	echo "write_bitstream -force $*.bit" >> generate_bit.tcl
	echo "exit" >> generate_bit.tcl
	vivado -nojournal -nolog -mode batch -source generate_bit.tcl
	mkdir -p rev
	EXT=bit; COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.$$EXT ]; \
	do COUNT=$$((COUNT+1)); done; \
	cp $@ rev/$*_rev$$COUNT.$$EXT; \
	echo "Output: rev/$*_rev$$COUNT.$$EXT";

program: $(FPGA_TOP).bit
	echo "open_hw" > program.tcl
	echo "connect_hw_server" >> program.tcl
	echo "open_hw_target" >> program.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> program.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> program.tcl
	echo "set_property PROGRAM.FILE {$(FPGA_TOP).bit} [current_hw_device]" >> program.tcl
	echo "program_hw_devices [current_hw_device]" >> program.tcl
	echo "exit" >> program.tcl
	vivado -nojournal -nolog -mode batch -source program.tcl

%_primary.mcs %_secondary.mcs %_primary.prm %_secondary.prm: %.bit
	echo "write_cfgmem -force -format mcs -size 256 -interface SPIx8 -loadbit {up 0x0000000 $*.bit} -checksum -file $*.mcs" > generate_mcs.tcl
	echo "exit" >> generate_mcs.tcl
	vivado -nojournal -nolog -mode batch -source generate_mcs.tcl
	mkdir -p rev
	COUNT=100; \
	while [ -e rev/$*_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	COUNT=$$((COUNT-1)); \
	for x in _primary.mcs _secondary.mcs _primary.prm _secondary.prm; \
	do cp $*$$x rev/$*_rev$$COUNT$$x; \
	echo "Output: rev/$*_rev$$COUNT$$x"; done;

flash: $(FPGA_TOP)_primary.mcs $(FPGA_TOP)_secondary.mcs $(FPGA_TOP)_primary.prm $(FPGA_TOP)_secondary.prm
	echo "open_hw" > flash.tcl
	echo "connect_hw_server" >> flash.tcl
	echo "open_hw_target" >> flash.tcl
	echo "current_hw_device [lindex [get_hw_devices] 0]" >> flash.tcl
	echo "refresh_hw_device -update_hw_probes false [current_hw_device]" >> flash.tcl
	echo "create_hw_cfgmem -hw_device [current_hw_device] [lindex [get_cfgmem_parts {mt25qu01g-spi-x1_x2_x4_x8}] 0]" >> flash.tcl
	echo "current_hw_cfgmem -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM [current_hw_device]]" >> flash.tcl
	echo "set_property PROGRAM.FILES [list \"$(FPGA_TOP)_primary.mcs\" \"$(FPGA_TOP)_secondary.mcs\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.PRM_FILES [list \"$(FPGA_TOP)_primary.prm\" \"$(FPGA_TOP)_secondary.prm\"] [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ERASE 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CFG_PROGRAM 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.VERIFY 1 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.CHECKSUM 0 [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.ADDRESS_RANGE {use_file} [current_hw_cfgmem]" >> flash.tcl
	echo "set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [current_hw_cfgmem]" >> flash.tcl
	echo "create_hw_bitstream -hw_device [current_hw_device] [get_property PROGRAM.HW_CFGMEM_BITFILE [current_hw_device]]" >> flash.tcl
	echo "program_hw_devices [current_hw_device]" >> flash.tcl
	echo "refresh_hw_device [current_hw_device]" >> flash.tcl
	echo "program_hw_cfgmem -hw_cfgmem [current_hw_cfgmem]" >> flash.tcl
	echo "boot_hw_device [current_hw_device]" >> flash.tcl
	echo "exit" >> flash.tcl
	vivado -nojournal -nolog -mode batch -source flash.tcl

