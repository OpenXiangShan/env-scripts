PRJ ?=
ENV_SCRIPTS_HOME ?= $(CURDIR)

CORE_DIR ?= ""
CHI_DIR ?= ""
FPGA_BIT_HOME ?=
WORKLOAD ?=
# Supported CPU parameters:
#   kmh
#   nutshell
#   nanhu
CPU ?= ""

.PHONY: bitstream vivado

# Get Vivado version
VIVADO_VERSION := $(shell vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown")

check_vivado_version:
	@vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown"

# Run synthesis using Vivado
synth:
	vivado -mode batch -source ./tools/gen_synth.tcl -tclargs $(PRJ)

# Generate FPGA bitstream
bitstream:
	vivado -mode batch -source ./tools/gen_bitstream.tcl -tclargs $(PRJ)

# Update file list for core RTL files
update_core_flist:
	rm -rf $(CORE_DIR)/rtl/verification
	find "$(CORE_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./core_flist.awk > ./src/tcl/cpu_files.tcl

# Update file list for CHI interface files
update_chi_flist:
	find "$(CHI_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./chi_flist.awk > ./src/tcl/chi_files.tcl;

# Launch Vivado with FPGA project configuration
vivado: check_vivado_version
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name fpga_$(CPU) --vivado_version $(VIVADO_VERSION)

# Check Vivado version compatibility
check_version:
	vivado -mode batch -source src/tcl/common/check_version.tcl -tclargs --vivado_version $(VIVADO_VERSION) --cpu $(CPU) --project_name fpga_$(CPU)

# Write bitstream to FPGA via PCIe
write_bitstream:
	sh tools/pcie-remove.sh
	vivado -mode tcl -source tools/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sh tools/pcie-rescan.sh

# Write workload to FPGA DDR via JTAG
write_jtag_ddr:
	vivado -mode tcl -source tools/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	vivado -mode tcl -source tools/jtag_write_ddr.tcl -tclargs $(WORKLOAD)

# Reset CPU on FPGA
reset_cpu:
	vivado -mode tcl -source tools/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

# Add system options for memory optimization
add_sys_option:
	sed -i "s/reg \(\[[0-9]*:[0-9]*\]\) ram \[\([4-9][0-9]\{3,\}\|[1-9][0-9]\{4,\}\):0\];/(\* ram_style = \"ultra\" \*)\treg \1 ram \[\2:0\];/g" $(CORE_DIR)/rtl/array_*.v

# Display implementation log
get_impl_log:
	cat fpga_$(CPU)/fpga_$(CPU).runs/impl_1/runme.log

# Display synthesis log
get_synth_log:
	cat fpga_$(CPU)/fpga_$(CPU).runs/synth_1/runme.log

# Build complete FPGA project
all:
	$(MAKE) update_chi_flist CHI_DIR="$(CHI_DIR)"
	$(MAKE) update_core_flist CORE_DIR=$(CORE_DIR)
	$(MAKE) vivado CPU=$(CPU)