UVHS_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
UVHS_COMPILATION_DIR := $(UVHS_ROOT_DIR)/uvhs/compilation
UVHS_RUNTIME_DIR := $(UVHS_ROOT_DIR)/uvhs/runtime

UVHS_TEMPLATE_DIR ?=
UVHS_UVW_AXI4_TO_DDR4_SRC ?=
UVHS_PROBE_TCL ?= $(UVHS_COMPILATION_DIR)/probe_ila.tcl
UVHS_PROBE_PATH := $(if $(strip $(UVHS_PROBE_TCL)),$(abspath $(UVHS_PROBE_TCL)),)
UVHS_DDR_AXI_WIDTH := $(if $(filter nutshell,$(CPU)),64,256)
UVHS_WORK_DIR := $(ENV_SCRIPTS_HOME)/$(PRJ_NAME)
UVHS_FILELIST := $(UVHS_WORK_DIR)/rtl/filelist.f

UVHS_EXPORT_IP_FORCE ?= 0
UVHS_EXPORT_IP_JOBS := $(if $(strip $(VIVADO_JOBS)),$(VIVADO_JOBS),8)
UVHS_KEEP_FPGAS ?= b0.f0 b0.f1 b0.f2
UVHS_LUT_FILL_RATE ?= $(if $(filter kmh,$(CPU)),70,)
UVHS_LUT6_FILL_RATE ?= $(if $(filter kmh,$(CPU)),35,)

UVHS_DDR_RTL_INST := fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4
UVHS_RUNTIME_LIB_DIR := $(UVHS_WORK_DIR)/.uvhs-runtime-lib
UVHS_COMPAT_BIN := $(UVHS_WORK_DIR)/.uvhs-compat-bin
UVHS_RUNTIME_DB := $(UVHS_WORK_DIR)/hw.dat
UVHS_RUNTIME_WORK_DIR := $(UVHS_WORK_DIR)/runtime-work
UVHS_RUNTIME_COMMAND_FILE := $(UVHS_RUNTIME_WORK_DIR)/command.tcl
UVHS_RUNTIME_PID_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.pid
UVHS_RUNTIME_READY_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.ready
UVHS_RUNTIME_LOG := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.log
UVHS_RUNTIME_TIMEOUT ?= 600
# Derive clk8_p from the sign-off clk5_p runtime frequency.
UVHS_TMCLK_CPU_RATIO ?= 50

UVHS_ILA_TIMEOUT ?= 60
UVHS_ILA_DEPTH ?= 1000000
UVHS_ILA_POSITION ?= 0
UVHS_ILA_CLOCK ?= clk5_p
UVHS_ILA_GATED_CLOCK ?=
# Settings used to construct fpga-host hooks.
UVHS_RUNTIME ?=
# This must name the fpga_diff checkout visible on UVHS_RUNTIME; it cannot be
# inferred when the runtime host has multiple checkouts.
UVHS_ILA_DIR ?= $(UVHS_ROOT_DIR)
UVHS_ILA_ENV ?= source ~/.bashrc &&
UVHS_ILA_TRIGGER ?= $(UVHS_ILA_DIR)/uvhs/runtime/trigger.ini
# uv_shell writes UHD output below its project-local runtime work directory.
UVHS_ILA_OUTPUT_DIR := $(UVHS_RUNTIME_WORK_DIR)/UHD/uvhs_ila
UVHS_ILA_USDB := $(UVHS_ILA_OUTPUT_DIR)/UvData.usdb
UVHS_ILA_VCD := $(UVHS_ILA_OUTPUT_DIR)/UvData.vcd

UVHS_TOOL_ENV = \
	PATH="$$UV_ROOT/bin:$$UV_ROOT/lib/venv3.8/bin:$$UV_ROOT/lib/gcc10.3/bin:$$PATH" \
	MAKEFLAGS="$${MAKEFLAGS:+$$MAKEFLAGS }SHELL=/bin/bash" \
	UVHS_RUNTIME_LIB_DIR="$(UVHS_RUNTIME_LIB_DIR)" \
	UVHS_COMPAT_BIN="$(UVHS_COMPAT_BIN)" \
	UVHS_TMCLK_CPU_RATIO="$(UVHS_TMCLK_CPU_RATIO)" \
	UVSHELL_EXEC_NAME="$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh"

UVHS_FLOW_ENV = \
	$(UVHS_TOOL_ENV) \
	UVHS_FLOW=1 \
	UVHS_PROBE_TCL="$(UVHS_PROBE_PATH)" \
	XDMA_LINK_WIDTH="$(XDMA_LINK_WIDTH)" \
	UVHS_KEEP_FPGAS="$(UVHS_KEEP_FPGAS)" \
	UVHS_LUT_FILL_RATE="$(UVHS_LUT_FILL_RATE)" \
	UVHS_LUT6_FILL_RATE="$(UVHS_LUT6_FILL_RATE)"

.PHONY: uvhs uvhs_project uvhs_preflight uvhs_prepare \
	uvhs_frontend uvhs_backend uvhs_clean uvhs_write_bitstream \
	uvhs_halt_soc uvhs_reset_cpu uvhs_write_ddr uvhs_write_flash \
	uvhs_ila_arm uvhs_ila_upload uvhs_vcd uvhs_ila_clear \
	uvhs_runtime_status uvhs_runtime_stop uvhs_bitstream \
	uvhs_stage_bitstream uvhs_ila_host_env

# Validate host tools and external inputs before starting a multi-hour build.
uvhs_preflight: check_project_name
	@bash -c 'set -euo pipefail; \
		for variable in UV_ROOT UV_XILINX_VIVADO UV_LICENSE; do \
			[[ -n "$${!variable:-}" ]] || { echo "ERROR: $$variable is not set" >&2; exit 1; }; \
		done; \
		[[ -n "$(CPU)" ]] || { echo "ERROR: CPU is not set" >&2; exit 1; }; \
		for command in bash python3 gzip ldconfig; do \
			command -v "$$command" >/dev/null || { echo "ERROR: command not found: $$command" >&2; exit 1; }; \
		done; \
		for executable in \
			"$$UV_ROOT/bin/uv_shell" "$$UV_ROOT/bin/uv_shell_exec" \
			"$$UV_XILINX_VIVADO/bin/vivado" \
			"$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh" \
			"$(UVHS_COMPILATION_DIR)/shell_compat.sh" \
			"$(UVHS_COMPILATION_DIR)/prepare_ip.sh" \
			"$(UVHS_ROOT_DIR)/tools/update_core_flist.sh"; do \
			[[ -x "$$executable" ]] || { echo "ERROR: executable not found: $$executable" >&2; exit 1; }; \
		done; \
		for file in \
			"$(UVHS_COMPILATION_DIR)/vivado_pre_opt.tcl" \
			"$(UVHS_COMPILATION_DIR)/partition.tcl" \
			"$(UVHS_TEMPLATE_DIR)/Makefile" \
			"$(UVHS_TEMPLATE_DIR)/script/1B_4F_HGC_assemble.tcl"; do \
			[[ -f "$$file" ]] || { echo "ERROR: file not found: $$file" >&2; exit 1; }; \
		done; \
		for directory in "$(CORE_DIR)" "$(UVHS_TEMPLATE_DIR)/script" "$(UVHS_UVW_AXI4_TO_DDR4_SRC)"; do \
			[[ -d "$$directory" ]] || { echo "ERROR: directory not found: $$directory" >&2; exit 1; }; \
		done; \
		if [[ -n "$(UVHS_PROBE_PATH)" && ! -f "$(UVHS_PROBE_PATH)" ]]; then \
			echo "ERROR: UVHS probe script not found: $(UVHS_PROBE_PATH)" >&2; exit 1; \
		fi'

uvhs_prepare: uvhs_preflight
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)/script"
	mkdir -p "$(UVHS_WORK_DIR)"
	mkdir -p "$(UVHS_COMPAT_BIN)"
	ln -sfn "$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh" \
		"$(UVHS_COMPAT_BIN)/python"
	ln -sfn "$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh" \
		"$(UVHS_COMPAT_BIN)/python3"
	cp -a "$(UVHS_TEMPLATE_DIR)/script" "$(UVHS_WORK_DIR)/"
	cp -f "$(UVHS_TEMPLATE_DIR)/Makefile" "$(UVHS_WORK_DIR)/Makefile"
	mkdir -p "$(UVHS_WORK_DIR)/rtl/soc" "$(UVHS_WORK_DIR)/rtl/device/pcie"
	$(UVHS_FLOW_ENV) bash "$(UVHS_COMPILATION_DIR)/prepare_ip.sh" \
		"$(UVHS_ROOT_DIR)" "$(UVHS_WORK_DIR)" "$(CORE_DIR)" \
		"$(UVHS_EXPORT_IP_JOBS)" "$(UVHS_EXPORT_IP_FORCE)" \
		"$(UVHS_UVW_AXI4_TO_DDR4_SRC)" "$(UVHS_DDR_AXI_WIDTH)"

uvhs_project: uvhs_prepare
	bash "$(UVHS_ROOT_DIR)/tools/update_core_flist.sh" uvhs \
		"$(CORE_DIR)" "$(UVHS_WORK_DIR)" "$(CPU)" "$(UVHS_FILELIST)" \
		-- $(RTL_INCLUDE)

uvhs_frontend: uvhs_project
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_COMPILATION_DIR)/frontend_run.tcl" |& tee frontend_run.log; \
		grep -Fxq UVHS_FRONTEND_SUCCESS frontend_run.log'

# Keep frontend and backend serialized even when the caller enables parallel make.
uvhs: uvhs_frontend
	$(MAKE) uvhs_backend

uvhs_bitstream: uvhs

uvhs_backend:
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_COMPILATION_DIR)/backend_run.tcl" |& tee backend_run.log; \
		grep -Fxq UVHS_BACKEND_SUCCESS backend_run.log'

# The process that downloads the database must retain its runtime ownership.
uvhs_write_bitstream:
	test -d "$(UVHS_RUNTIME_DB)"
	test -f "$(UVHS_RUNTIME_DIR)/runtime_server.tcl"
	test -x "$(UVHS_RUNTIME_DIR)/runtime_session.sh"
	mkdir -p "$(UVHS_RUNTIME_WORK_DIR)"
	$(UVHS_TOOL_ENV) UVHS_DB_PATH="$(UVHS_RUNTIME_DB)" \
	UVHS_RUNTIME_WORK_DIR="$(UVHS_RUNTIME_WORK_DIR)" \
	UVHS_COMMAND_FILE="$(UVHS_RUNTIME_COMMAND_FILE)" \
	UVHS_RUNTIME_READY_FILE="$(UVHS_RUNTIME_READY_FILE)" \
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" start \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_LOG)" "$(UVHS_RUNTIME_COMMAND_FILE)" \
		"$(UVHS_RUNTIME_TIMEOUT)" \
		bash "$$UV_ROOT/bin/uv_shell" -rt_shell \
		-workdir "$(UVHS_RUNTIME_WORK_DIR)" \
		-script "$(UVHS_RUNTIME_DIR)/runtime_server.tcl"

uvhs_runtime_status:
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" check \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)"
	@echo "UVHS_RUNTIME_LOG=$(UVHS_RUNTIME_LOG)"

define uvhs_runtime_command
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" check \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)"
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" enqueue \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_RUNTIME_TIMEOUT)" $(1)
endef

uvhs_halt_soc:
	$(call uvhs_runtime_command,halt_soc)

uvhs_reset_cpu:
	$(call uvhs_runtime_command,reset_cpu)

uvhs_write_ddr:
	test -f "$(WORKLOAD)"
	$(call uvhs_runtime_command,write_ddr "$(abspath $(WORKLOAD))" "$(UVHS_DDR_RTL_INST)" "$(UVHS_DDR_AXI_WIDTH)")

uvhs_write_flash:
	test -f "$(WORKLOAD)"
	$(call uvhs_runtime_command,write_flash "$(abspath $(WORKLOAD))" 0x0 0x8000)

uvhs_stage_bitstream:
	@echo "UVHS implementation database: $(UVHS_RUNTIME_DB)"

uvhs_ila_arm:
	test -f "$(UVHS_ILA_TRIGGER)"
	$(call uvhs_runtime_command,ila_arm \
		"$(abspath $(UVHS_ILA_TRIGGER))" "$(UVHS_ILA_POSITION)" \
		"$(UVHS_ILA_CLOCK)" "$(UVHS_ILA_GATED_CLOCK)")

uvhs_ila_upload:
	$(call uvhs_runtime_command,ila_upload uvhs_ila \
		"$(UVHS_ILA_TIMEOUT)" "$(UVHS_ILA_DEPTH)" \
		"$(UVHS_ILA_CLOCK)")
	test -s "$(UVHS_ILA_USDB)"
	$(MAKE) uvhs_vcd
	@echo "UVHS_ILA_USDB=$(UVHS_ILA_USDB)"

# Print sourceable hooks for fpga-host. The generated commands use the public
# backend targets so callers do not depend on UVHS implementation names.
uvhs_ila_host_env:
	@bash "$(UVHS_RUNTIME_DIR)/ila_host_env.sh" \
		"$(UVHS_RUNTIME)" "$(UVHS_ILA_DIR)" \
		"$(UVHS_ILA_ENV)" "$(CPU)" "$(SUFFIX)" "$(PRJ_NAME)" \
		"$(UVHS_ILA_TRIGGER)" "$(UVHS_ILA_POSITION)" "$(UVHS_ILA_CLOCK)" \
		"$(UVHS_ILA_GATED_CLOCK)" "$(UVHS_ILA_TIMEOUT)" "$(UVHS_ILA_DEPTH)"

uvhs_vcd:
	test -x "$$UV_ROOT/uvd/uvs/bin/usdb2vcd"
	test -s "$(UVHS_ILA_USDB)"
	rm -f "$(UVHS_ILA_VCD)"
	$(UVHS_TOOL_ENV) "$$UV_ROOT/uvd/uvs/bin/usdb2vcd" \
		-i "$(UVHS_ILA_USDB)" -o "$(UVHS_ILA_VCD)"
	test -s "$(UVHS_ILA_VCD)"
	@echo "UVHS_ILA_VCD=$(UVHS_ILA_VCD)"

uvhs_ila_clear:
	$(call uvhs_runtime_command,ila_clear)

uvhs_runtime_stop:
	$(call uvhs_runtime_command,stop)
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" wait \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_RUNTIME_TIMEOUT)"

uvhs_clean: check_project_name
	@! bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" check \
		"$(UVHS_RUNTIME_PID_FILE)" >/dev/null 2>&1 || \
		{ echo "ERROR: stop the UVHS runtime before cleaning" >&2; exit 1; }
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)"
