ENV_SCRIPTS_HOME ?= $(CURDIR)

CORE_DIR ?=
RTL_INCLUDE ?=
FPGA_BIT_HOME ?=
WORKLOAD ?=
AXI_WIDTH ?= 64
# Host-trigger ILA capture is opt-in. Keep the trigger mark_debug net in RTL,
# but avoid instantiating the ILA core by default to reduce routing pressure.
ENABLE_ILA ?= 0
ILA_DEPTH ?= 16384
XDMA_LINK_WIDTH ?= X4
VIVADO_JOBS ?=
DDR_RANK_WIDTH ?= 2
export ENABLE_ILA ILA_DEPTH XDMA_LINK_WIDTH VIVADO_JOBS DDR_RANK_WIDTH
# Supported CPU parameters:
#   kmh
#   nutshell
#   nanhu
CPU ?=
SUFFIX ?=
PRJ_NAME = fpga_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
PRJ_DIR ?= $(ENV_SCRIPTS_HOME)/$(PRJ_NAME)
PRJ ?= $(PRJ_DIR)/$(PRJ_NAME).xpr

FPGA_WRITE_BITSTREAM_IMPL ?= vivado_write_bitstream
FPGA_HALT_SOC_IMPL ?= vivado_halt_soc
FPGA_WRITE_DDR_IMPL ?= vivado_write_jtag_ddr
FPGA_WRITE_FLASH_IMPL ?= vivado_write_jtag_flash
FPGA_RESET_CPU_IMPL ?= vivado_reset_cpu

ifeq ($(UVHS),1)
include uvhs/uvhs.mk
endif

.PHONY: bitstream vivado dump_ila update_core_flist \
	write_bitstream halt_soc write_jtag_ddr write_jtag_flash reset_cpu \
	vivado_write_bitstream vivado_halt_soc vivado_write_jtag_ddr \
	vivado_write_jtag_flash vivado_reset_cpu

# Get Vivado version
VIVADO_VERSION := $(shell vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown")

check_vivado_version:
	@vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown"

# Run synthesis using Vivado
synth:
	vivado -mode batch -source ./tools/gen_synth.tcl -tclargs $(PRJ)

# Generate FPGA bitstream
bitstream:
	vivado -mode batch -source ./tools/gen_bitstream.tcl -tclargs $(PRJ) impl_1 $(VIVADO_JOBS)

# RTL_INCLUDE accepts RTL files, directories, and .f/.flist/.list file lists.
update_core_flist:
	@./tools/update_core_flist.sh "$(CORE_DIR)" -- $(RTL_INCLUDE)

# Launch Vivado with FPGA project configuration
vivado: check_vivado_version
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name $(PRJ_NAME) --vivado_version $(VIVADO_VERSION)

# Check Vivado version compatibility
check_version:
	vivado -mode batch -source src/tcl/common/check_version.tcl -tclargs --vivado_version $(VIVADO_VERSION) --cpu $(CPU) --project_name $(PRJ_NAME)

# Program the selected FPGA backend.
write_bitstream: $(FPGA_WRITE_BITSTREAM_IMPL)

vivado_write_bitstream:
	sh tools/pcie-remove.sh
	vivado -mode tcl -source tools/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sh tools/pcie-rescan.sh
	vivado -mode tcl -source tools/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	$(MAKE) vivado_reset_cpu

# Halt the FPGA SoC before loading memory.
halt_soc: $(FPGA_HALT_SOC_IMPL)

vivado_halt_soc:
	vivado -mode tcl -source tools/halt_soc.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

# Load a workload into FPGA DDR.
write_jtag_ddr: $(FPGA_WRITE_DDR_IMPL)

vivado_write_jtag_ddr:
	vivado -mode tcl -source tools/jtag_write_ddr.tcl -tclargs $(WORKLOAD) $(AXI_WIDTH)

# Load a raw binary image into the BRAM-backed flash.
write_jtag_flash: $(FPGA_WRITE_FLASH_IMPL)

vivado_write_jtag_flash:
	vivado -mode tcl -source tools/jtag_write_flash.tcl -tclargs $(WORKLOAD)

# Reset the CPU on the selected FPGA backend.
reset_cpu: $(FPGA_RESET_CPU_IMPL)

vivado_reset_cpu:
	vivado -mode tcl -source tools/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

ILA_OUT ?= $(ENV_SCRIPTS_HOME)/ila-dump
TIMEOUT_MIN ?= 2

# Dump host-trigger ILA data to ila/csv/vcd files
dump_ila:
	mkdir -p $(ILA_OUT)
	vivado -mode tcl -source tools/dump_ila.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx $(ILA_OUT) $(TIMEOUT_MIN)

# Add system options for memory optimization
add_sys_option:
	sed -i "s/reg \(\[[0-9]*:[0-9]*\]\) ram \[\([4-9][0-9]\{3,\}\|[1-9][0-9]\{4,\}\):0\];/(\* ram_style = \"ultra\" \*)\treg \1 ram \[\2:0\];/g" $(CORE_DIR)/rtl/array_*.v

# Display implementation log
get_impl_log:
	cat $(PRJ_DIR)/$(PRJ_NAME).runs/impl_1/runme.log

# Display synthesis log
get_synth_log:
	cat $(PRJ_DIR)/$(PRJ_NAME).runs/synth_1/runme.log

# Build complete FPGA project
all:
	$(MAKE) update_core_flist CORE_DIR="$(CORE_DIR)" RTL_INCLUDE="$(RTL_INCLUDE)"
	$(MAKE) vivado CPU=$(CPU) SUFFIX="$(SUFFIX)"
