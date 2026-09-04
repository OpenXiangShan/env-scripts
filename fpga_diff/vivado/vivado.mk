VIVADO_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
VIVADO_SCRIPT_DIR := $(VIVADO_ROOT_DIR)/vivado/scripts
VIVADO_TCL_DIR := $(VIVADO_ROOT_DIR)/vivado/tcl

PRJ_DIR ?= $(ENV_SCRIPTS_HOME)/$(PRJ_NAME)
PRJ ?= $(PRJ_DIR)/$(PRJ_NAME).xpr
CPU_FILES_TCL ?= $(PRJ_DIR)/cpu_files.tcl

# Host-trigger ILA is enabled by default for XiangShan/KMH. Other CPU targets
# retain the timing-friendly opt-in default and can override this variable.
ENABLE_ILA ?= $(if $(filter kmh xiangshan,$(CPU)),1,0)
ILA_DEPTH ?= 16384
DDR_RANK_WIDTH ?= 2
export ENABLE_ILA ILA_DEPTH DDR_RANK_WIDTH

ILA_OUT ?= $(ENV_SCRIPTS_HOME)/ila-dump
TIMEOUT_MIN ?= 2
VIVADO_VERSION := $(shell vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown")

.PHONY: vivado_bitstream vivado_project vivado_stage_bitstream \
	vivado_write_bitstream vivado_halt_soc vivado_write_ddr \
	vivado_write_flash vivado_reset_cpu vivado_runtime_status \
	vivado_runtime_stop vivado_ila_arm vivado_ila_upload vivado_ila_clear \
	vivado_ila_host_env vivado synth check_vivado_version check_version \
	update_core_flist get_impl_log get_synth_log

check_vivado_version:
	@vivado -version 2>/dev/null | head -1 | grep -o '[0-9]\{4\}\.[0-9]' || echo "unknown"

synth:
	vivado -mode batch -source "$(VIVADO_SCRIPT_DIR)/gen_synth.tcl" -tclargs $(PRJ)

vivado_bitstream: vivado_project
	vivado -mode batch -source "$(VIVADO_SCRIPT_DIR)/gen_bitstream.tcl" -tclargs $(PRJ) impl_1 $(VIVADO_JOBS)

vivado_stage_bitstream:
	@test -n "$(FPGA_BIT_ARTIFACT_DIR)" && test "$(FPGA_BIT_ARTIFACT_DIR)" != "/" || { \
		echo "ERROR: please set a safe FPGA_BIT_ARTIFACT_DIR=..." >&2; exit 2; \
	}
	@mkdir -p "$(FPGA_BIT_ARTIFACT_DIR)"
	@find "$(PRJ_DIR)" -type f \( -name "*.bit" -o -name "*.ltx" \) \
		-exec cp -f {} "$(FPGA_BIT_ARTIFACT_DIR)/" \;

# RTL_INCLUDE accepts RTL files, directories, and .f/.flist/.list file lists.
update_core_flist:
	@"$(VIVADO_ROOT_DIR)/tools/update_core_flist.sh" vivado \
		"$(CORE_DIR)" "$(CPU_FILES_TCL)" -- $(RTL_INCLUDE)

vivado: check_vivado_version
	vivado -mode batch -source "$(VIVADO_TCL_DIR)/common/xs_uart.tcl" \
		-tclargs --origin_dir "$(VIVADO_ROOT_DIR)" --cpu $(CPU) \
		--project_name $(PRJ_NAME) --project_dir "$(PRJ_DIR)" \
		--cpu_files "$(CPU_FILES_TCL)" \
		--vivado_version $(VIVADO_VERSION)

check_version:
	vivado -mode batch -source "$(VIVADO_TCL_DIR)/common/check_version.tcl" \
		-tclargs --vivado_version $(VIVADO_VERSION) --cpu $(CPU) \
		--project_name $(PRJ_NAME)

vivado_write_bitstream:
	@test -n "$(FPGA_BIT_HOME)" || { echo "ERROR: please set FPGA_BIT_HOME=..." >&2; exit 2; }
ifneq ($(NO_DIFF),1)
	sh "$(VIVADO_ROOT_DIR)/tools/pcie-remove.sh"
endif
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/write_bitstream.tcl" -tclargs $(FPGA_BIT_HOME)
ifneq ($(NO_DIFF),1)
	sh "$(VIVADO_ROOT_DIR)/tools/pcie-rescan.sh"
endif
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/reset_ddr.tcl" \
		-tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx
	$(MAKE) reset_cpu

vivado_halt_soc:
	@test -n "$(FPGA_BIT_HOME)" || { echo "ERROR: please set FPGA_BIT_HOME=..." >&2; exit 2; }
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/halt_soc.tcl" \
		-tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

vivado_write_ddr:
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/jtag_write_ddr.tcl" \
		-tclargs $(WORKLOAD) $(AXI_WIDTH)

vivado_write_flash:
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/jtag_write_flash.tcl" \
		-tclargs $(WORKLOAD)

vivado_reset_cpu:
	@test -n "$(FPGA_BIT_HOME)" || { echo "ERROR: please set FPGA_BIT_HOME=..." >&2; exit 2; }
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/reset_cpu.tcl" \
		-tclargs $(FPGA_BIT_HOME)/fpga_top_debug.ltx

vivado_runtime_status vivado_runtime_stop vivado_ila_arm:
	@echo "ERROR: $(@:vivado_%=%) requires FPGA_BACKEND=uvhs" >&2
	@exit 2

vivado_ila_host_env:
	@:

vivado_ila_upload:
	@test -n "$(FPGA_BIT_HOME)" || { echo "ERROR: please set FPGA_BIT_HOME=..." >&2; exit 2; }
	mkdir -p "$(ILA_OUT)"
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/ila.tcl" \
		-tclargs upload "$(FPGA_BIT_HOME)/fpga_top_debug.ltx" \
		"$(ILA_OUT)" "$(TIMEOUT_MIN)"

vivado_ila_clear:
	@test -n "$(FPGA_BIT_HOME)" || { echo "ERROR: please set FPGA_BIT_HOME=..." >&2; exit 2; }
	vivado -mode tcl -source "$(VIVADO_SCRIPT_DIR)/ila.tcl" \
		-tclargs clear "$(FPGA_BIT_HOME)/fpga_top_debug.ltx"

get_impl_log:
	cat $(PRJ_DIR)/$(PRJ_NAME).runs/impl_1/runme.log

get_synth_log:
	cat $(PRJ_DIR)/$(PRJ_NAME).runs/synth_1/runme.log

vivado_project: check_project_name
	$(MAKE) update_core_flist CORE_DIR="$(CORE_DIR)" RTL_INCLUDE="$(RTL_INCLUDE)"
	$(MAKE) vivado CPU=$(CPU) SUFFIX="$(SUFFIX)"
