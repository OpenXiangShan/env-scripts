UVHS_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
UVHS_COMPILATION_DIR := $(UVHS_ROOT_DIR)/uvhs/compilation
UVHS_RUNTIME_DIR := $(UVHS_ROOT_DIR)/uvhs/runtime

UVHS_TEMPLATE_DIR ?=
UVHS_UVW_AXI4_TO_DDR4_SRC ?=
UVHS_DDR_AXI_WIDTH := $(if $(filter nutshell,$(CPU)),64,256)
UVHS_WORK_DIR := $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
UVHS_FILELIST := $(UVHS_WORK_DIR)/rtl/filelist.f

UVHS_EXPORT_IP_FORCE ?= 0
UVHS_EXPORT_IP_JOBS := $(if $(strip $(VIVADO_JOBS)),$(VIVADO_JOBS),8)

UVHS_KEEP_FPGAS ?= $(if $(filter kmh,$(CPU)),b0.f0 b0.f1 b0.f2 b0.f3,)
UVHS_LUT_FILL_RATE ?= $(if $(filter kmh,$(CPU)),70,)
UVHS_LUT6_FILL_RATE ?= $(if $(filter kmh,$(CPU)),35,)

UVHS_DDR_RTL_INST := fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4
UVHS_RUNTIME_LIB_DIR := $(UVHS_WORK_DIR)/.uvhs-runtime-lib
UVHS_RUNTIME_DB := $(UVHS_WORK_DIR)/hw.dat
UVHS_RUNTIME_WORK_DIR := $(UVHS_WORK_DIR)/runtime-work
UVHS_RUNTIME_COMMAND_FILE := $(UVHS_RUNTIME_WORK_DIR)/command.tcl
UVHS_RUNTIME_TMP_DIR := $(UVHS_RUNTIME_WORK_DIR)/tmp
UVHS_RUNTIME_PID_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.pid
UVHS_RUNTIME_READY_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.ready
UVHS_RUNTIME_LOG := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.log
UVHS_RUNTIME_TIMEOUT := 600

UVHS_TOOL_ENV = \
	PATH="$$UV_ROOT/bin:$$UV_ROOT/lib/venv3.8/bin:$$UV_ROOT/lib/gcc10.3/bin:$$PATH" \
	MAKEFLAGS="$${MAKEFLAGS:+$$MAKEFLAGS }SHELL=/bin/bash" \
	LD_LIBRARY_PATH="$(UVHS_RUNTIME_LIB_DIR):$${LD_LIBRARY_PATH:-}" \
	UVHS_RUNTIME_LIB_DIR="$(UVHS_RUNTIME_LIB_DIR)" \
	UVSHELL_EXEC_NAME="$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh"

UVHS_FLOW_ENV = \
	$(UVHS_TOOL_ENV) \
	UVHS_FLOW=1 \
	XDMA_LINK_WIDTH="$(XDMA_LINK_WIDTH)" \
	UVHS_KEEP_FPGAS="$(UVHS_KEEP_FPGAS)" \
	UVHS_LUT_FILL_RATE="$(UVHS_LUT_FILL_RATE)" \
	UVHS_LUT6_FILL_RATE="$(UVHS_LUT6_FILL_RATE)"

.PHONY: uvhs uvhs_preflight uvhs_prepare \
	uvhs_prepare_ip uvhs_filelist \
	uvhs_frontend uvhs_backend uvhs_clean uvhs_write_bitstream \
	uvhs_halt_soc uvhs_reset_cpu uvhs_write_ddr uvhs_write_flash \
	uvhs_runtime_status uvhs_runtime_check uvhs_runtime_stop

uvhs_preflight:
	test -n "$$UV_ROOT"
	test -x "$$UV_ROOT/bin/uv_shell"
	test -n "$$UV_XILINX_VIVADO"
	test -x "$$UV_XILINX_VIVADO/bin/vivado"
	test -n "$$UV_LICENSE"
	test -x "$$UV_ROOT/bin/uv_shell_exec"
	test -x "$(UVHS_RUNTIME_DIR)/uv_shell_exec_compat.sh"
	test -x "$(UVHS_COMPILATION_DIR)/shell_compat.sh"
	test -x "$(UVHS_COMPILATION_DIR)/prepare_ip.sh"
	test -x "$(UVHS_ROOT_DIR)/tools/update_core_flist.sh"
	test -f "$(UVHS_COMPILATION_DIR)/vivado_pre_opt.tcl"
	test -d "$(UVHS_TEMPLATE_DIR)/script"
	test -f "$(UVHS_TEMPLATE_DIR)/Makefile"
	test -f "$(UVHS_TEMPLATE_DIR)/script/1B_4F_HGC_assemble.tcl"
	test -d "$(UVHS_UVW_AXI4_TO_DDR4_SRC)"
	mkdir -p "$(UVHS_RUNTIME_LIB_DIR)"
	bash -c 'set -euo pipefail; \
		ffi="$$(ldconfig -p | awk '\''/libffi[.]so[.]6 / { print $$NF; exit } /libffi[.]so[.]8 / { fallback = $$NF } END { if (fallback != "") print fallback }'\'')"; \
		test -n "$$ffi"; \
		ln -sfn "$$ffi" "$(UVHS_RUNTIME_LIB_DIR)/libffi.so.6"; \
		pcre=""; \
		if ldd "$$UV_ROOT/bin/uv_shell_exec" 2>/dev/null | grep -q "libpcre[.]so[.]1 => not found"; then \
			for candidate in "$$UV_ROOT/shlib_install/libpcre.so.1" "$$UV_ROOT/shlib/libpcre.so.1"; do \
				if [ -f "$$candidate" ]; then pcre="$$candidate"; break; fi; \
			done; \
			if [ -z "$$pcre" ]; then \
				echo "ERROR: uv_shell_exec needs libpcre.so.1 under UV_ROOT" >&2; \
				exit 1; \
			fi; \
		fi; \
		if [ -n "$$pcre" ]; then test -f "$$pcre"; ln -sfn "$$pcre" "$(UVHS_RUNTIME_LIB_DIR)/libpcre.so.1"; fi'

uvhs_prepare: uvhs_preflight
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)/script"
	mkdir -p "$(UVHS_WORK_DIR)"
	cp -a "$(UVHS_TEMPLATE_DIR)/script" "$(UVHS_WORK_DIR)/"
	cp -f "$(UVHS_TEMPLATE_DIR)/Makefile" "$(UVHS_WORK_DIR)/Makefile"
	mkdir -p "$(UVHS_WORK_DIR)/rtl/soc" "$(UVHS_WORK_DIR)/rtl/device/pcie"

uvhs_prepare_ip: uvhs_prepare
	$(UVHS_FLOW_ENV) bash "$(UVHS_COMPILATION_DIR)/prepare_ip.sh" \
		"$(UVHS_ROOT_DIR)" "$(UVHS_WORK_DIR)" "$(CORE_DIR)" \
		"$(UVHS_EXPORT_IP_JOBS)" "$(UVHS_EXPORT_IP_FORCE)" \
		"$(UVHS_UVW_AXI4_TO_DDR4_SRC)" "$(UVHS_DDR_AXI_WIDTH)"

uvhs_filelist: uvhs_prepare_ip
	bash "$(UVHS_ROOT_DIR)/tools/update_core_flist.sh" uvhs \
		"$(CORE_DIR)" "$(UVHS_WORK_DIR)" "$(CPU)" "$(UVHS_FILELIST)" \
		-- $(RTL_INCLUDE)

uvhs_frontend: uvhs_filelist
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_COMPILATION_DIR)/frontend_run.tcl" |& tee frontend_run.log; \
		grep -Fxq UVHS_FRONTEND_SUCCESS frontend_run.log'

# Stable build entry point. Keep the stages serialized even under parallel make.
uvhs: uvhs_frontend
	$(MAKE) uvhs_backend

uvhs_backend:
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_COMPILATION_DIR)/backend_run.tcl" |& tee backend_run.log; \
		grep -Fxq UVHS_BACKEND_SUCCESS backend_run.log'

# The UVHS API requires one session to retain ownership of the downloaded
# database. Detach that session after programming and track it in runtime-work.
uvhs_write_bitstream:
	test -d "$(UVHS_RUNTIME_DB)"
	test -f "$(UVHS_RUNTIME_DIR)/runtime_server.tcl"
	test -x "$(UVHS_RUNTIME_DIR)/runtime_session.sh"
	mkdir -p "$(UVHS_RUNTIME_WORK_DIR)" "$(UVHS_RUNTIME_TMP_DIR)"
	$(UVHS_TOOL_ENV) UVHS_DB_PATH="$(UVHS_RUNTIME_DB)" \
	UVHS_COMMAND_FILE="$(UVHS_RUNTIME_COMMAND_FILE)" \
	UVHS_RUNTIME_READY_FILE="$(UVHS_RUNTIME_READY_FILE)" \
	UVHS_RUNTIME_TMP_DIR="$(UVHS_RUNTIME_TMP_DIR)" \
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" start \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_LOG)" "$(UVHS_RUNTIME_COMMAND_FILE)" \
		"$(UVHS_RUNTIME_TIMEOUT)" \
		bash "$$UV_ROOT/bin/uv_shell" -rt_shell \
		-workdir "$(UVHS_RUNTIME_WORK_DIR)" \
		-script "$(UVHS_RUNTIME_DIR)/runtime_server.tcl"

uvhs_runtime_check:
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" check \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)"

uvhs_runtime_status: uvhs_runtime_check
	@echo "UVHS_RUNTIME_LOG=$(UVHS_RUNTIME_LOG)"

define uvhs_runtime_command
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" enqueue \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_RUNTIME_DIR)/runtime_command.tcl" \
		"$(UVHS_RUNTIME_TIMEOUT)" $(1)
endef

uvhs_halt_soc: uvhs_runtime_check
	$(call uvhs_runtime_command,halt_soc)

uvhs_reset_cpu: uvhs_runtime_check
	$(call uvhs_runtime_command,reset_cpu)

uvhs_write_ddr: uvhs_runtime_check
	test -f "$(WORKLOAD)"
	$(call uvhs_runtime_command,write_ddr "$(WORKLOAD)" "$(UVHS_DDR_RTL_INST)" "$(UVHS_DDR_AXI_WIDTH)")

uvhs_write_flash: uvhs_runtime_check
	test -f "$(WORKLOAD)"
	$(call uvhs_runtime_command,write_flash "$(WORKLOAD)" B0 F2 0 0 0x0 0x8000)

uvhs_runtime_stop: uvhs_runtime_check
	$(call uvhs_runtime_command,stop)
	bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" wait \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_RUNTIME_TIMEOUT)"

uvhs_clean:
	@! bash "$(UVHS_RUNTIME_DIR)/runtime_session.sh" active \
		"$(UVHS_RUNTIME_PID_FILE)" >/dev/null 2>&1 || \
		{ echo "ERROR: stop the UVHS runtime before cleaning" >&2; exit 1; }
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)"
