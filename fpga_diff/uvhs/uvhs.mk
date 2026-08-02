UVHS_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

PLATFORM ?= U2.2
UVHS_TEMPLATE_DIR ?=
UVHS_UVW_AXI4_TO_DDR4_SRC ?=
UVHS_DDR_AXI_WIDTH := $(if $(filter nutshell,$(CPU)),64,256)
UVHS_WORK_DIR ?= $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
UVHS_FILELIST := $(UVHS_WORK_DIR)/rtl/filelist.f
UVHS_RTL_INCLUDE_FILELIST := $(UVHS_WORK_DIR)/rtl/rtl_include.f
UVHS_CORE_RTL_DIR := $(CORE_DIR)/rtl
UVHS_CORE_GENERATED_SRC_DIR := $(CORE_DIR)/generated-src

UVHS_EXPORT_IP_FORCE ?= 0
UVHS_EXPORT_IP_JOBS := $(if $(strip $(VIVADO_JOBS)),$(VIVADO_JOBS),8)
UVHS_GBUS_IP_DIR := $(UV_ROOT)/platform/$(PLATFORM)/Prototype/ips/uvw_gbus.3.1
UVHS_GBUS_GENERATOR := $(UVHS_GBUS_IP_DIR)/gen_generalbus_ip.py
UVHS_GBUS_JSON := $(UVHS_GBUS_IP_DIR)/uvw_axi3_generalbus.json
UVHS_GBUS_GEN_DIR := $(UVHS_WORK_DIR)/ip-gen/generalbus

UVHS_TARGET_PACK ?= B0
UVHS_TARGET_FPGA ?= F2
UVHS_KEEP_FPGAS ?=
UVHS_CPU_CLK_PERIOD_NS ?= 40
UVHS_FRONTEND_THREADS ?= 4
UVHS_FRONTEND_PROCESSES ?= 16
UVHS_FPGA_THREADS ?= 4
UVHS_FPGA_PROCESSES ?= 8
UVHS_COMPILE_STRATEGY ?= uv_high_fanout_explore
UVHS_LUT_FILL_RATE ?= $(if $(filter kmh,$(CPU)),80,)
UVHS_LUT6_FILL_RATE ?= $(if $(filter kmh,$(CPU)),30,)

XDMA_LINK_WIDTH ?= X4
XDMA_ENABLE_PF0_BAR1 ?= 1
XDMA_AXILITE_MASTER_SCALE ?= Kilobytes
XDMA_AXILITE_MASTER_SIZE ?= 512

UVHS_UVW_AXI4_TO_DDR4_FILES := \
	rtl/soc/uvw_axi4_to_ddr4.dcp \
	rtl/soc/uvw_axi4_to_ddr4_Stub.v \
	script/uvw_axi4_to_ddr4_pblock.tcl \
	script/custom_parts_ddr4_KSM26SES8_2666.csv
UVHS_UVW_AXI4_TO_DDR4_REQUIRED_FILES := \
	rtl/soc/uvw_axi4_to_ddr4.dcp \
	rtl/soc/uvw_axi4_to_ddr4_Stub.v \
	script/uvw_axi4_to_ddr4_pblock.tcl
UVHS_REQUIRED_MODULES := $(if $(filter nanhu,$(CPU)),XlnFpgaTop,$(if $(filter kmh nutshell,$(CPU)),SimTop,))
UVHS_DDR_RTL_INST := fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4
UVHS_RUNTIME_LIB_DIR := $(UVHS_WORK_DIR)/.uvhs-runtime-lib
UVHS_RUNTIME_DB := $(UVHS_WORK_DIR)/hw.dat
UVHS_RUNTIME_WORK_DIR := $(UVHS_WORK_DIR)/runtime-work
UVHS_RUNTIME_COMMAND_FILE := $(UVHS_RUNTIME_WORK_DIR)/command.tcl
UVHS_RUNTIME_TMP_DIR := $(UVHS_RUNTIME_WORK_DIR)/tmp
UVHS_RUNTIME_PID_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.pid
UVHS_RUNTIME_READY_FILE := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.ready
UVHS_RUNTIME_LOG := $(UVHS_RUNTIME_WORK_DIR)/uv_shell.log
UVHS_RUNTIME_TIMEOUT ?= 600
UVHS_COMPAT_PCRE_LIB ?=

UVHS_TOOL_ENV = \
	PATH="$$UV_ROOT/bin:$$UV_ROOT/lib/venv3.8/bin:$$UV_ROOT/lib/gcc10.3/bin:$$PATH" \
	MAKEFLAGS="$${MAKEFLAGS:+$$MAKEFLAGS }SHELL=/bin/bash" \
	LD_LIBRARY_PATH="$(UVHS_RUNTIME_LIB_DIR):$${LD_LIBRARY_PATH:-}" \
	UVHS_RUNTIME_LIB_DIR="$(UVHS_RUNTIME_LIB_DIR)" \
	UVSHELL_EXEC_NAME="$(UVHS_ROOT_DIR)/uvhs/uv_shell_exec_compat.sh"

UVHS_FLOW_ENV = \
	$(UVHS_TOOL_ENV) \
	UVHS_FLOW=1 \
	PLATFORM="$(PLATFORM)" \
	XDMA_LINK_WIDTH="$(XDMA_LINK_WIDTH)" \
	XDMA_ENABLE_PF0_BAR1="$(XDMA_ENABLE_PF0_BAR1)" \
	XDMA_AXILITE_MASTER_SCALE="$(XDMA_AXILITE_MASTER_SCALE)" \
	XDMA_AXILITE_MASTER_SIZE="$(XDMA_AXILITE_MASTER_SIZE)" \
	UVHS_TARGET_PACK="$(UVHS_TARGET_PACK)" \
	UVHS_TARGET_FPGA="$(UVHS_TARGET_FPGA)" \
	UVHS_KEEP_FPGAS="$(UVHS_KEEP_FPGAS)" \
	UVHS_CPU_CLK_PERIOD_NS="$(UVHS_CPU_CLK_PERIOD_NS)" \
	UVHS_COMPILE_STRATEGY="$(UVHS_COMPILE_STRATEGY)" \
	UVHS_LUT_FILL_RATE="$(UVHS_LUT_FILL_RATE)" \
	UVHS_LUT6_FILL_RATE="$(UVHS_LUT6_FILL_RATE)"

UVHS_PNR_DIR := $(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir/Strategy_$(UVHS_COMPILE_STRATEGY)
UVHS_BITSTREAM_DIR := $(UVHS_PNR_DIR)/bitstream
UVHS_BIT_HOME ?= $(UVHS_WORK_DIR)/ready-to-program

.PHONY: uvhs_preflight uvhs_prepare \
	uvhs_export_vivado_ip uvhs_export_generalbus uvhs_normalize_rtl_include \
	uvhs_sync_uvw_axi4_to_ddr4 uvhs_filelist uvhs_check_modules \
	uvhs_frontend uvhs_backend uvhs_all uvhs_check_timing \
	uvhs_package_bitstream uvhs_tools_check uvhs_clean uvhs_write_bitstream \
	uvhs_halt_soc uvhs_reset_cpu uvhs_write_ddr uvhs_write_flash \
	uvhs_runtime_status uvhs_runtime_check uvhs_runtime_stop

uvhs_preflight:
	test -n "$$UV_ROOT"
	test -x "$$UV_ROOT/bin/uv_shell"
	test -n "$$UV_XILINX_VIVADO"
	test -x "$$UV_XILINX_VIVADO/bin/vivado"
	test -n "$$UV_LICENSE"
	test -x "$$UV_ROOT/bin/uv_shell_exec"
	test -x "$(UVHS_ROOT_DIR)/uvhs/uv_shell_exec_compat.sh"
	test -x "$(UVHS_ROOT_DIR)/uvhs/shell_compat.sh"
	test -f "$(UVHS_ROOT_DIR)/uvhs/vivado_pre_opt.tcl"
	test -f "$(UVHS_GBUS_GENERATOR)"
	test -f "$(UVHS_GBUS_JSON)"
	command -v python3 >/dev/null
	command -v gzip >/dev/null
	test -d "$(UVHS_TEMPLATE_DIR)/script"
	test -f "$(UVHS_TEMPLATE_DIR)/Makefile"
	test -f "$(UVHS_TEMPLATE_DIR)/script/1B_4F_HGC_assemble.tcl"
	test -d "$(UVHS_UVW_AXI4_TO_DDR4_SRC)"
	mkdir -p "$(UVHS_RUNTIME_LIB_DIR)"
	bash -c 'set -euo pipefail; \
		ffi="$$(ldconfig -p | awk '\''/libffi[.]so[.]6 / { print $$NF; exit } /libffi[.]so[.]8 / { fallback = $$NF } END { if (fallback != "") print fallback }'\'')"; \
		test -n "$$ffi"; \
		ln -sfn "$$ffi" "$(UVHS_RUNTIME_LIB_DIR)/libffi.so.6"; \
		pcre="$(UVHS_COMPAT_PCRE_LIB)"; \
		if [ -z "$$pcre" ] && ldd "$$UV_ROOT/bin/uv_shell_exec" 2>/dev/null | grep -q "libpcre[.]so[.]1 => not found"; then \
			for candidate in "$$UV_ROOT/shlib_install/libpcre.so.1" "$$UV_ROOT/shlib/libpcre.so.1"; do \
				if [ -f "$$candidate" ]; then pcre="$$candidate"; break; fi; \
			done; \
			if [ -z "$$pcre" ]; then \
				echo "ERROR: uv_shell_exec needs libpcre.so.1; set UVHS_COMPAT_PCRE_LIB" >&2; \
				exit 1; \
			fi; \
		fi; \
		if [ -n "$$pcre" ]; then test -f "$$pcre"; ln -sfn "$$pcre" "$(UVHS_RUNTIME_LIB_DIR)/libpcre.so.1"; fi'

uvhs_tools_check:
	bash "$(UVHS_ROOT_DIR)/uvhs/check_flow_tools.sh"

uvhs_prepare: uvhs_preflight
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)/script"
	mkdir -p "$(UVHS_WORK_DIR)"
	cp -a "$(UVHS_TEMPLATE_DIR)/script" "$(UVHS_WORK_DIR)/"
	cp -f "$(UVHS_TEMPLATE_DIR)/Makefile" "$(UVHS_WORK_DIR)/Makefile"
	mkdir -p "$(UVHS_WORK_DIR)/rtl/soc" "$(UVHS_WORK_DIR)/rtl/device/pcie"

uvhs_export_vivado_ip: uvhs_prepare
	bash -c 'set -euo pipefail; \
		export VIVADO_HOME="$$UV_XILINX_VIVADO" XILINX_VIVADO="$$UV_XILINX_VIVADO"; \
		version="$$("$$UV_XILINX_VIVADO/bin/vivado" -version | sed -n "s/^Vivado v\\([^ ]*\\).*/\\1/p" | head -n 1)"; \
		test -n "$$version"; \
		$(UVHS_FLOW_ENV) "$$UV_XILINX_VIVADO/bin/vivado" -mode batch \
		-source "$(UVHS_ROOT_DIR)/uvhs/export_vivado_ip.tcl" -tclargs \
		--origin_dir "$(UVHS_ROOT_DIR)" --out_dir "$(UVHS_WORK_DIR)" \
		--vivado_version "$$version" --core_dir "$(CORE_DIR)" \
		--jobs "$(UVHS_EXPORT_IP_JOBS)" \
		$(if $(filter 1,$(UVHS_EXPORT_IP_FORCE)),--force,)'

# The vendor generator starts an asynchronous DCP copy before deleting its
# project. Make that copy synchronous in the private work-directory copy.
uvhs_export_generalbus: uvhs_prepare
	bash -c 'set -euo pipefail; \
		source_ip_dir="$(UVHS_GBUS_IP_DIR)"; generator="$(UVHS_GBUS_GENERATOR)"; \
		gen_dir="$(UVHS_GBUS_GEN_DIR)"; release="$$gen_dir/uvw_general_bus"; \
		test -f "$$generator"; test -f "$(UVHS_GBUS_JSON)"; \
		if [ "$(UVHS_EXPORT_IP_FORCE)" = 1 ] || \
		   [ ! -s "$$release/uvw_general_bus.dcp" ] || \
		   [ ! -s "$$release/uvw_general_bus_Stub.v" ] || \
		   ! grep -Eq "output[[:space:]]+\\[63:0\\][[:space:]]*dut_axi_wdata" \
		     "$$release/uvw_general_bus_Stub.v" || \
		   ! grep -Eq "input[[:space:]]+\\[63:0\\][[:space:]]*dut_axi_rdata" \
		     "$$release/uvw_general_bus_Stub.v"; then \
			rm -rf "$$gen_dir"; mkdir -p "$$gen_dir"; \
			ip_dir="$$gen_dir/ip-src"; \
			cp -a "$$source_ip_dir" "$$ip_dir"; \
			gen_script="$$ip_dir/gen_generalbus_ip.py"; \
			sed -i "/os[.]popen.*f_dcp_in.*f_dcp_out/c\\    shutil.copy2(f_dcp_in, f_dcp_out)" \
			  "$$gen_script"; \
			grep -Fq "shutil.copy2(f_dcp_in, f_dcp_out)" "$$gen_script"; \
			json="$$gen_dir/uvw_axi3_generalbus.json"; \
			cp -f "$(UVHS_GBUS_JSON)" "$$json"; \
			sed -i -E \
			  "s|(\"IP_LOCATION\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"$$ip_dir\"|; \
			   s|(\"DATA_WIDTH\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"|\1\"64\"|" \
			  "$$json"; \
			export VIVADO_HOME="$$UV_XILINX_VIVADO" XILINX_VIVADO="$$UV_XILINX_VIVADO"; \
			cd "$$gen_dir"; \
			PATH="$$UV_XILINX_VIVADO/bin:$$PATH" python3 "$$gen_script" -j "$$json"; \
		fi; \
		test -s "$$release/uvw_general_bus.dcp"; \
		test -s "$$release/uvw_general_bus_Stub.v"; \
		rm -rf "$(UVHS_WORK_DIR)/rtl/soc/uvw_general_bus"; \
		mkdir -p "$(UVHS_WORK_DIR)/rtl/soc" "$(UVHS_WORK_DIR)/rtl/stubs"; \
		cp -a "$$release" "$(UVHS_WORK_DIR)/rtl/soc/uvw_general_bus"; \
		cp -f "$$release/uvw_general_bus_Stub.v" \
		  "$(UVHS_WORK_DIR)/rtl/stubs/uvw_general_bus.v"; \
		grep -Eq "output[[:space:]]+\\[63:0\\][[:space:]]*dut_axi_wdata" \
		  "$(UVHS_WORK_DIR)/rtl/stubs/uvw_general_bus.v"; \
		grep -Eq "input[[:space:]]+\\[63:0\\][[:space:]]*dut_axi_rdata" \
		  "$(UVHS_WORK_DIR)/rtl/stubs/uvw_general_bus.v"; \
		echo "INFO: prepared 64-bit UVHS generalBus DCP"'

uvhs_normalize_rtl_include: uvhs_prepare
	mkdir -p "$(dir $(UVHS_RTL_INCLUDE_FILELIST))"
	bash "$(UVHS_ROOT_DIR)/tools/update_core_flist.sh" "$(CORE_DIR)" \
		--output-filelist "$(UVHS_RTL_INCLUDE_FILELIST)" \
		-- $(RTL_INCLUDE)

uvhs_sync_uvw_axi4_to_ddr4: uvhs_prepare
	bash -c 'set -euo pipefail; \
		src="$(UVHS_UVW_AXI4_TO_DDR4_SRC)"; work="$(UVHS_WORK_DIR)"; \
		for rel in $(UVHS_UVW_AXI4_TO_DDR4_FILES); do \
			base="$${rel##*/}"; dst="$$work/$$rel"; found=""; \
			for candidate in "$$src/$$rel" "$$src/$$base"; do \
				if [ -f "$$candidate" ]; then found="$$candidate"; break; fi; \
			done; \
			if [ -z "$$found" ]; then found="$$(find "$$src" -type f -name "$$base" -size +0c -print -quit)"; fi; \
			if [ -n "$$found" ]; then mkdir -p "$$(dirname "$$dst")"; cp -f "$$found" "$$dst"; fi; \
		done; \
		for rel in $(UVHS_UVW_AXI4_TO_DDR4_REQUIRED_FILES); do test -s "$$work/$$rel"; done; \
		expected_width="$(UVHS_DDR_AXI_WIDTH)"; last_bit="$$((expected_width - 1))"; \
		stub="$$work/rtl/soc/uvw_axi4_to_ddr4_Stub.v"; \
		if gzip -t "$$stub" 2>/dev/null; then \
			gzip -dc "$$stub" > "$$stub.decompressed"; \
			mv -f "$$stub.decompressed" "$$stub"; \
		fi; \
		grep -Eq "input[[:space:]]+\\[$$last_bit:0\\][[:space:]]*ddr4ip_dut_axi_wdata" "$$stub"; \
		grep -Eq "output[[:space:]]+\\[$$last_bit:0\\][[:space:]]*ddr4ip_dut_axi_rdata" "$$stub"; \
		echo "INFO: verified UVHS DDR DCP AXI data width: $$expected_width"'

uvhs_filelist: uvhs_export_generalbus uvhs_normalize_rtl_include
	test -d "$(UVHS_CORE_RTL_DIR)"
	mkdir -p "$(dir $(UVHS_FILELIST))"
	{ \
		printf '+define+SYNTHESIS\n+define+XIANGSHAN_FPGA\n'; \
		printf '+define+UVHS\n'; \
		printf '+define+DDR4_16G_X8\n+define+DQ64\n+define+DDR4_2400\n'; \
		printf '+define+DQ=64\n+define+MICRON_DDR\n+define+DDR4_16Gbx8\n'; \
		printf '+define+DDR4\n+define+SRAM_SYN\n+define+DATA_VERSION=0\n'; \
		if [ "$(CPU)" = nutshell ]; then printf '+define+CPU_NUTSHELL\n'; fi; \
		if [ "$(CPU)" = kmh ]; then \
			simtop=""; \
			for candidate in "$(UVHS_CORE_RTL_DIR)/SimTop.sv"; do \
				if [ -f "$$candidate" ]; then simtop="$$candidate"; break; fi; \
			done; \
			if [ -n "$$simtop" ] && \
				grep -Eq '^[[:space:]]*(input|output)[[:space:]].*dma_awready' "$$simtop"; then \
				printf '+define+CONFIG_SIMTOP_HAS_DMA\n'; \
			fi; \
		fi; \
		printf '+incdir+%s\n' "$(CORE_DIR)"; \
		if [ -d "$(UVHS_CORE_RTL_DIR)" ]; then printf '+incdir+%s\n' "$(UVHS_CORE_RTL_DIR)"; fi; \
		if [ -d "$(UVHS_CORE_GENERATED_SRC_DIR)" ]; then printf '+incdir+%s\n' "$(UVHS_CORE_GENERATED_SRC_DIR)"; fi; \
		printf '+incdir+%s/src/rtl/common\n' "$(UVHS_ROOT_DIR)"; \
		find "$(UVHS_ROOT_DIR)/src/rtl/common" -type f \
			\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
			! -name 'u0_xdma.v' -print | sort; \
		test ! -d "$(UVHS_WORK_DIR)/rtl/stubs" || \
			find "$(UVHS_WORK_DIR)/rtl/stubs" -type f -name '*.v' -print | sort; \
		test ! -d "$(UVHS_ROOT_DIR)/src/rtl/$(CPU)" || \
			find "$(UVHS_ROOT_DIR)/src/rtl/$(CPU)" -type f \
			\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		find "$(UVHS_CORE_RTL_DIR)" -type f \
			\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		test ! -f "$(UVHS_RTL_INCLUDE_FILELIST)" || cat "$(UVHS_RTL_INCLUDE_FILELIST)"; \
	} | awk 'NF' > "$(UVHS_FILELIST)"

uvhs_check_modules: uvhs_filelist
	bash "$(UVHS_ROOT_DIR)/uvhs/check_modules.sh" "$(UVHS_FILELIST)" "$(UVHS_REQUIRED_MODULES)"

uvhs_frontend: uvhs_export_vivado_ip uvhs_export_generalbus \
	uvhs_sync_uvw_axi4_to_ddr4 uvhs_check_modules
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		UVHS_FRONTEND_THREADS="$(UVHS_FRONTEND_THREADS)" UVHS_FRONTEND_PROCESSES="$(UVHS_FRONTEND_PROCESSES)" \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_ROOT_DIR)/uvhs/frontend_run.tcl" |& tee frontend_run.log; \
		grep -Fxq UVHS_FRONTEND_SUCCESS frontend_run.log'

uvhs_backend:
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) \
		UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_ROOT_DIR)/uvhs/backend_run.tcl" |& tee backend_run.log; \
		grep -Fxq UVHS_BACKEND_SUCCESS backend_run.log'

uvhs_all: uvhs_frontend uvhs_backend

uvhs_check_timing:
	test -f "$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"
	! grep -q 'Timing constraints are not met' "$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"

uvhs_package_bitstream: uvhs_check_timing
	test -f "$(UVHS_BITSTREAM_DIR)/pnr.bit"
	mkdir -p "$(UVHS_BIT_HOME)"
	ln -sf "$(UVHS_BITSTREAM_DIR)/pnr.bit" "$(UVHS_BIT_HOME)/fpga_top_debug.bit"
	@echo "FPGA_BIT_HOME=$(UVHS_BIT_HOME)"

# The UVHS API requires one session to retain ownership of the downloaded
# database. Detach that session after programming and track it in runtime-work.
uvhs_write_bitstream:
	test -d "$(UVHS_RUNTIME_DB)"
	test -f "$(UVHS_ROOT_DIR)/uvhs/hw_run_download.tcl"
	test -f "$(UVHS_ROOT_DIR)/uvhs/runtime_control.tcl"
	test -x "$(UVHS_ROOT_DIR)/uvhs/runtime_session.sh"
	mkdir -p "$(UVHS_RUNTIME_WORK_DIR)" "$(UVHS_RUNTIME_TMP_DIR)"
	$(UVHS_TOOL_ENV) UVHS_DB_PATH="$(UVHS_RUNTIME_DB)" \
	UVHS_COMMAND_FILE="$(UVHS_RUNTIME_COMMAND_FILE)" \
	UVHS_RUNTIME_READY_FILE="$(UVHS_RUNTIME_READY_FILE)" \
	UVHS_RUNTIME_TMP_DIR="$(UVHS_RUNTIME_TMP_DIR)" \
	bash "$(UVHS_ROOT_DIR)/uvhs/runtime_session.sh" start \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_LOG)" "$(UVHS_RUNTIME_COMMAND_FILE)" \
		"$(UVHS_RUNTIME_TIMEOUT)" \
		bash "$$UV_ROOT/bin/uv_shell" -rt_shell \
		-workdir "$(UVHS_RUNTIME_WORK_DIR)" \
		-script "$(UVHS_ROOT_DIR)/uvhs/hw_run_download.tcl"

uvhs_runtime_check:
	bash "$(UVHS_ROOT_DIR)/uvhs/runtime_session.sh" check \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)"

uvhs_runtime_status: uvhs_runtime_check
	@echo "UVHS_RUNTIME_LOG=$(UVHS_RUNTIME_LOG)"

define uvhs_runtime_command
	UVHS_RUNTIME_COMMAND_TIMEOUT="$(UVHS_RUNTIME_TIMEOUT)" \
	bash "$(UVHS_ROOT_DIR)/uvhs/enqueue_runtime_command.sh" \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_ROOT_DIR)/uvhs/runtime_command.tcl" $(1)
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
	$(call uvhs_runtime_command,write_flash "$(WORKLOAD)" "$(UVHS_TARGET_PACK)" "$(UVHS_TARGET_FPGA)" 0 0 0x0 0x8000)

uvhs_runtime_stop: uvhs_runtime_check
	$(call uvhs_runtime_command,stop)
	bash "$(UVHS_ROOT_DIR)/uvhs/runtime_session.sh" wait \
		"$(UVHS_RUNTIME_PID_FILE)" "$(UVHS_RUNTIME_READY_FILE)" \
		"$(UVHS_RUNTIME_COMMAND_FILE)" "$(UVHS_RUNTIME_TIMEOUT)"

uvhs_clean:
	@! bash "$(UVHS_ROOT_DIR)/uvhs/runtime_session.sh" active \
		"$(UVHS_RUNTIME_PID_FILE)" >/dev/null 2>&1 || \
		{ echo "ERROR: stop the UVHS runtime before cleaning" >&2; exit 1; }
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)"
