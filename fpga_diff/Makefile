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
export ENABLE_ILA ILA_DEPTH XDMA_LINK_WIDTH VIVADO_JOBS
# Supported CPU parameters:
#   kmh
#   nutshell
#   nanhu
CPU ?=
SUFFIX ?=
PRJ_NAME = fpga_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
PRJ_DIR ?= $(ENV_SCRIPTS_HOME)/$(PRJ_NAME)
PRJ ?= $(PRJ_DIR)/$(PRJ_NAME).xpr

UVHS_SUBMAKE = $(MAKE) -f $(CURDIR)/uvhs/Makefile ROOT_DIR="$(CURDIR)"

.PHONY: bitstream vivado dump_ila uvhs_prepare uvhs_filelist uvhs_check_modules uvhs_export_vivado_ip uvhs_fetch_uvw_axi4_to_ddr4 uvhs_frontend uvhs_backend uvhs_all vivado_frontend vivado_backend vivado_all uvhs_vivado_frontend uvhs_vivado_backend uvhs_vivado_all uvhs_clean uvhs_env uvhs_preflight uvhs_status uvhs_check_timing_clean uvhs_export_ltx uvhs_package_bitstream

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

# Update file list for core RTL files
update_core_flist:
	rm -rf $(CORE_DIR)/rtl/verification
	find "$(CORE_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./core_flist.awk > ./src/tcl/cpu_files.tcl

# Update file list for CHI interface files
update_chi_flist:
	find "$(CHI_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./chi_flist.awk > ./src/tcl/chi_files.tcl;

uvhs_prepare:
	$(UVHS_SUBMAKE) uvhs_prepare

uvhs_export_vivado_ip:
	$(UVHS_SUBMAKE) uvhs_export_vivado_ip

uvhs_fetch_uvw_axi4_to_ddr4:
	$(UVHS_SUBMAKE) uvhs_fetch_uvw_axi4_to_ddr4

uvhs_filelist:
	$(UVHS_SUBMAKE) uvhs_filelist

uvhs_check_modules:
	$(UVHS_SUBMAKE) uvhs_check_modules

uvhs_frontend:
	$(UVHS_SUBMAKE) uvhs_frontend

uvhs_backend:
	$(UVHS_SUBMAKE) uvhs_backend

uvhs_all:
	$(UVHS_SUBMAKE) uvhs_all

vivado_frontend:
	$(UVHS_SUBMAKE) vivado_frontend

vivado_backend:
	$(UVHS_SUBMAKE) vivado_backend

vivado_all:
	$(UVHS_SUBMAKE) vivado_all

uvhs_vivado_frontend:
	$(UVHS_SUBMAKE) uvhs_vivado_frontend

uvhs_vivado_backend:
	$(UVHS_SUBMAKE) uvhs_vivado_backend

uvhs_vivado_all:
	$(UVHS_SUBMAKE) uvhs_vivado_all

uvhs_clean:
	$(UVHS_SUBMAKE) uvhs_clean

uvhs_env:
	$(UVHS_SUBMAKE) uvhs_env

uvhs_preflight:
	$(UVHS_SUBMAKE) uvhs_preflight

uvhs_status:
	$(UVHS_SUBMAKE) uvhs_status

uvhs_check_timing_clean:
	$(UVHS_SUBMAKE) uvhs_check_timing_clean

uvhs_export_ltx:
	$(UVHS_SUBMAKE) uvhs_export_ltx

uvhs_package_bitstream:
	$(UVHS_SUBMAKE) uvhs_package_bitstream

# Launch Vivado with FPGA project configuration
vivado: check_vivado_version
	vivado -mode batch -source src/tcl/common/xs_uart.tcl -tclargs --cpu $(CPU) --project_name $(PRJ_NAME) --vivado_version $(VIVADO_VERSION)

# Check Vivado version compatibility
check_version:
	vivado -mode batch -source src/tcl/common/check_version.tcl -tclargs --vivado_version $(VIVADO_VERSION) --cpu $(CPU) --project_name $(PRJ_NAME)

# Write bitstream to FPGA via PCIe
write_bitstream:
ifeq ($(strip $(FPGA_SKIP_PCIE_RESCAN)),0)
	sh tools/pcie-remove.sh
endif
	vivado -mode tcl -source tools/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
ifeq ($(strip $(FPGA_SKIP_PCIE_RESCAN)),0)
	sh tools/pcie-rescan.sh
endif
	vivado -mode tcl -source tools/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	$(MAKE) reset_cpu

# Halt the FPGA SoC (for Write Jtag DDR)
halt_soc:
	vivado -mode tcl -source tools/halt_soc.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

# Write workload to FPGA DDR via JTAG
write_jtag_ddr:
	vivado -mode tcl -source tools/jtag_write_ddr.tcl -tclargs $(WORKLOAD) $(AXI_WIDTH)

# Reset CPU on FPGA
reset_cpu:
	vivado -mode tcl -source tools/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

ILA_OUT ?= $(ENV_SCRIPTS_HOME)/ila-dump
TIMEOUT_MIN ?= 2
FPGA_SKIP_PCIE_RESCAN ?= 0

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
ifneq ($(strip $(CHI_DIR)),)
	$(MAKE) update_chi_flist CHI_DIR="$(CHI_DIR)"
endif
	$(MAKE) update_core_flist CORE_DIR=$(CORE_DIR)
	$(MAKE) vivado CPU=$(CPU) SUFFIX="$(SUFFIX)"
