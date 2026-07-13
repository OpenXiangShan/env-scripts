ENV_SCRIPTS_HOME ?= $(CURDIR)

CORE_DIR ?=
CHI_DIR ?=
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

.PHONY: bitstream route vivado dump_ila write_jtag_flash incremental-flow cpu-dcp-interface

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

# Run implementation through route_design without writing a bitstream
route:
	vivado -mode batch -source ./tools/run_impl_route.tcl -tclargs $(PRJ) impl_1 $(VIVADO_JOBS)

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
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name $(PRJ_NAME) --vivado_version $(VIVADO_VERSION)

# Check Vivado version compatibility
check_version:
	vivado -mode batch -source src/tcl/common/check_version.tcl -tclargs --vivado_version $(VIVADO_VERSION) --cpu $(CPU) --project_name $(PRJ_NAME)

# Write bitstream to FPGA via PCIe
write_bitstream:
	sh tools/pcie-remove.sh
	vivado -mode tcl -source tools/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sh tools/pcie-rescan.sh
	vivado -mode tcl -source tools/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	$(MAKE) reset_cpu

# Halt the FPGA SoC (for Write Jtag DDR)
halt_soc:
	vivado -mode tcl -source tools/halt_soc.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

# Write workload to FPGA DDR via JTAG
write_jtag_ddr:
	vivado -mode tcl -source tools/jtag_write_ddr.tcl -tclargs $(WORKLOAD) $(AXI_WIDTH)

# Write a raw binary image to the BRAM-backed flash via the flash-only JTAG AXI
write_jtag_flash:
	vivado -mode tcl -source tools/jtag_write_flash.tcl -tclargs $(WORKLOAD)

# Reset CPU on FPGA
reset_cpu:
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

INCREMENTAL_BASELINE_RELEASE ?=
INCREMENTAL_MODIFIED_RELEASE ?=
INCREMENTAL_OUT_DIR ?=
INCREMENTAL_EXTRA_ARGS ?=

# Run whole-project incremental synthesis and implementation.
incremental-flow:
	tools/cpu_dcp_split/run_incremental_flow.py \
	  --baseline-release "$(INCREMENTAL_BASELINE_RELEASE)" \
	  --modified-release "$(INCREMENTAL_MODIFIED_RELEASE)" \
	  --cpu "$(CPU)" \
	  $(if $(strip $(INCREMENTAL_OUT_DIR)),--out-dir "$(INCREMENTAL_OUT_DIR)",) \
	  $(if $(strip $(VIVADO_JOBS)),--jobs "$(VIVADO_JOBS)",) \
	  $(INCREMENTAL_EXTRA_ARGS)


CPU_DCP_MODIFIED_RELEASE ?=
CPU_DCP_CPU_MODULE ?=
CPU_DCP_PARTITION_MODULE ?=
CPU_DCP_INTERFACE_MODE ?= stub
CPU_DCP_INTERFACE_OUT ?=
CPU_DCP_INTERFACE_JSON ?=

# Copy the generated CPU RTL port contract onto a CpuDcpTop-style partition
# module. This is useful for inspecting or regenerating only the DCP shell
# interface without running Vivado.
cpu-dcp-interface:
	tools/cpu_dcp_split/sync_cpu_dcp_interface.py \
	  --release "$(CPU_DCP_MODIFIED_RELEASE)" \
	  $(if $(strip $(CPU_DCP_CPU_MODULE)),--cpu-module "$(CPU_DCP_CPU_MODULE)",) \
	  --partition-module "$(or $(strip $(CPU_DCP_PARTITION_MODULE)),CpuDcpTop)" \
	  --mode "$(CPU_DCP_INTERFACE_MODE)" \
	  $(if $(strip $(CPU_DCP_INTERFACE_OUT)),--out "$(CPU_DCP_INTERFACE_OUT)" --force,) \
	  $(if $(strip $(CPU_DCP_INTERFACE_JSON)),--json-out "$(CPU_DCP_INTERFACE_JSON)",)

# Display synthesis log
get_synth_log:
	cat $(PRJ_DIR)/$(PRJ_NAME).runs/synth_1/runme.log

# Build complete FPGA project
all:
ifneq ($(strip $(CHI_DIR)),)
	$(MAKE) update_chi_flist CHI_DIR="$(CHI_DIR)"
endif
	$(MAKE) update_core_flist CORE_DIR=$(CORE_DIR)
	$(MAKE) vivado CPU=$(CPU) SUFFIX="$(SUFFIX)"
