ENV_SCRIPTS_HOME ?= $(CURDIR)
VIVADO_SCRIPT_DIR ?= $(ENV_SCRIPTS_HOME)/vivado

CORE_DIR ?=
CHI_DIR ?=
FPGA_BIT_HOME ?=
WORKLOAD ?=
AXI_WIDTH ?= 64
PLATFORM ?= U2.2
# Host-trigger ILA capture is opt-in. Keep the trigger mark_debug net in RTL,
# but avoid instantiating the ILA core by default to reduce routing pressure.
ENABLE_ILA ?= 0
ILA_DEPTH ?= 16384
XDMA_LINK_WIDTH ?= X4
XDMA_ENABLE_PF0_BAR1 ?= 1
# Expected values for the checked Hejian XDMA EP x4 DCP used by the UVHS flow:
# BAR0 512 KiB, BAR1 64 KiB, endpoint 10ee:9048. They are carried into the
# Hejian scripts and host probes; do not treat them as a request to patch the
# Vivado xdma_ep Tcl source.
XDMA_AXILITE_MASTER_SCALE ?= Kilobytes
XDMA_AXILITE_MASTER_SIZE ?= 512
XDMA_EXPECTED_VENDOR ?= 0x10ee
XDMA_EXPECTED_DEVICE ?= 0x9048
XDMA_EXPECTED_BAR0_SIZE ?= 0x80000
XDMA_EXPECTED_BAR1_SIZE ?= 0x10000
UVHS_XDMA_EP_EXAMPLE_DIR ?= $(abspath $(CURDIR)/../../uvhs_1ep_test_0417_x4_xdma_loopback)
UVHS_XDMA_EP_DEFAULT_DCP ?= $(firstword $(wildcard $(UVHS_XDMA_EP_EXAMPLE_DIR)/rtl/xdma_ep.dcp))
UVHS_XDMA_EP_DEFAULT_DCP_SHA256 ?= e40002b4ccab73d4d7a1398630f59428add0a64b9f33d284d3789595bb791b32
UVHS_XDMA_EP_DEFAULT_DCP_VIVADO ?= 2024.2
UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT ?= $(firstword $(wildcard $(UVHS_XDMA_EP_EXAMPLE_DIR)/script/1B_4F_HGC_assemble.tcl))
UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256 ?= 0e44f3ced8e5628a6f9b60a36d15194f03f6eddefcf29d0221a8abf140ecb18b
UVHS_BASE_ASSEMBLE_FILE ?=
UVHS_BASE_ASSEMBLE_SHA256 ?=
UVHS_XDMA_EP_DCP ?=
UVHS_XDMA_EP_DCP_SHA256 ?=
UVHS_ALLOW_DCP_VIVADO_MISMATCH ?= 0
UVHS_DESIGN_NAME ?= VU19P_X4
UVHS_TARGET_BOARD ?= B0
UVHS_TARGET_PACK ?= $(UVHS_TARGET_BOARD)
UVHS_TARGET_FPGA ?= F2
UVHS_TARGET_FPGA_LOWER ?= $(shell printf '%s.%s' '$(UVHS_TARGET_PACK)' '$(UVHS_TARGET_FPGA)' | tr '[:upper:]' '[:lower:]')
UVHS_FPGA_COUNT ?= 1
UVHS_CPU_CLK_PERIOD_NS ?= 40
UVHS_CPU_DEBUG_CLK ?= 1
UVHS_PNR_STRATEGY ?= Strategy_uv_high_fanout_explore
UVHS_COMPILE_STRATEGY_NUM ?= 1
UVHS_COMPILE_STRATEGY0 ?= uv_high_fanout_explore
UVHS_COMPILE_STRATEGY1 ?=
UVHS_COMPILE_STRATEGY2 ?=
VIVADO_JOBS ?=
DDR_RANK_WIDTH ?= 2
export PLATFORM ENABLE_ILA ILA_DEPTH XDMA_LINK_WIDTH XDMA_ENABLE_PF0_BAR1 XDMA_AXILITE_MASTER_SCALE XDMA_AXILITE_MASTER_SIZE XDMA_EXPECTED_VENDOR XDMA_EXPECTED_DEVICE XDMA_EXPECTED_BAR0_SIZE XDMA_EXPECTED_BAR1_SIZE UVHS_XDMA_EP_EXAMPLE_DIR UVHS_XDMA_EP_DEFAULT_DCP UVHS_XDMA_EP_DEFAULT_DCP_SHA256 UVHS_XDMA_EP_DEFAULT_DCP_VIVADO UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256 UVHS_BASE_ASSEMBLE_FILE UVHS_BASE_ASSEMBLE_SHA256 UVHS_XDMA_EP_DCP UVHS_XDMA_EP_DCP_SHA256 UVHS_ALLOW_DCP_VIVADO_MISMATCH UVHS_DESIGN_NAME UVHS_TARGET_BOARD UVHS_TARGET_PACK UVHS_TARGET_FPGA UVHS_TARGET_FPGA_LOWER UVHS_FPGA_COUNT UVHS_CPU_CLK_PERIOD_NS UVHS_CPU_DEBUG_CLK UVHS_PNR_STRATEGY UVHS_COMPILE_STRATEGY_NUM UVHS_COMPILE_STRATEGY0 UVHS_COMPILE_STRATEGY1 UVHS_COMPILE_STRATEGY2 VIVADO_JOBS DDR_RANK_WIDTH
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

UVHS_FORWARD_TARGETS := \
	uvhs_prepare uvhs_export_vivado_ip uvhs_fetch_uvw_axi4_to_ddr4 \
	uvhs_show_uvw_axi4_to_ddr4 uvhs_filelist uvhs_check_modules \
	uvhs_tools_check uvhs_frontend uvhs_backend uvhs_all \
	vivado_frontend vivado_backend vivado_all \
	uvhs_vivado_frontend uvhs_vivado_backend uvhs_vivado_all \
	uvhs_clean uvhs_env uvhs_preflight uvhs_hejian_pcie_x4_env \
	uvhs_hejian_pcie_x4_preflight uvhs_hejian_pcie_x4_nutshell_all \
	uvhs_status uvhs_check_timing_clean uvhs_export_ltx \
	uvhs_package_bitstream

.PHONY: bitstream vivado dump_ila write_jtag_flash $(UVHS_FORWARD_TARGETS)

# Get Vivado version
VIVADO_VERSION := $(shell vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown")

check_vivado_version:
	@vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown"

# Run synthesis using Vivado
synth:
	vivado -mode batch -source "$(VIVADO_SCRIPT_DIR)/gen_synth.tcl" -tclargs $(PRJ)

# Generate FPGA bitstream
bitstream:
	vivado -mode batch -source "$(VIVADO_SCRIPT_DIR)/gen_bitstream.tcl" -tclargs $(PRJ) impl_1 $(VIVADO_JOBS)

# Update file list for core RTL files
update_core_flist:
	rm -rf $(CORE_DIR)/rtl/verification
	find "$(CORE_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./core_flist.awk > ./src/tcl/cpu_files.tcl

# Update file list for CHI interface files
update_chi_flist:
	find "$(CHI_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.svh" \) -printf '%p\n' | \
	awk -f ./chi_flist.awk > ./src/tcl/chi_files.tcl;

$(UVHS_FORWARD_TARGETS):
	$(UVHS_SUBMAKE) $@

# Launch Vivado with FPGA project configuration
vivado: check_vivado_version
	vivado -mode batch -source "$(VIVADO_SCRIPT_DIR)/xs_uart.tcl" -tclargs --origin_dir "$(ENV_SCRIPTS_HOME)" --cpu $(CPU) --project_name $(PRJ_NAME) --vivado_version $(VIVADO_VERSION)

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

# Write a raw binary image to the BRAM-backed flash via the flash-only JTAG AXI
write_jtag_flash:
	vivado -mode tcl -source tools/jtag_write_flash.tcl -tclargs $(WORKLOAD)

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
