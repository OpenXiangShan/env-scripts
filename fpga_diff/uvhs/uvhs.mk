UVHS_ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

PLATFORM ?= U2.2
UVHS_TEMPLATE_DIR ?=
UVHS_UVW_AXI4_TO_DDR4_SRC ?=
UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5 ?=
UVHS_WORK_DIR ?= $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
UVHS_TOP ?= fpga_top_debug
UVHS_FILELIST ?= $(UVHS_WORK_DIR)/rtl/filelist.f

UVHS_EXPORT_IP_FORCE ?= 0
UVHS_EXPORT_IP_JOBS ?= 8
UVHS_EXPORT_IP_VIVADO_VERSION ?=
UVHS_EXPORT_IP_ONLY ?=
UVHS_SKIP_VIVADO_EXPORT ?= vio_0 jtag_ddr_subsys

UVHS_DESIGN_NAME ?= VU19P_X4
UVHS_TARGET_PACK ?= B0
UVHS_TARGET_FPGA ?= F2
UVHS_TARGET_FPGA_LOWER ?= b0.f2
UVHS_KEEP_FPGAS ?= $(UVHS_TARGET_FPGA_LOWER)
UVHS_ASSIGN_PIN_FILE ?= $(UVHS_ROOT_DIR)/uvhs/assign_pin_u22_f2.tcl
UVHS_TIMING_FILE ?= $(UVHS_ROOT_DIR)/uvhs/timing_common.tcl
UVHS_ASSEMBLE_FILE ?= $(UVHS_ROOT_DIR)/uvhs/assemble_uvhs.tcl
UVHS_CPU_CLK_PERIOD_NS ?= 40
UVHS_CPU_DEBUG_CLK ?= 1
UVHS_USE_LSF ?= 0
UVHS_FRONTEND_THREADS ?= 4
UVHS_FRONTEND_PROCESSES ?= 16
UVHS_FPGA_THREADS ?= 4
UVHS_FPGA_PROCESSES ?= 8
UVHS_PNR_STRATEGY ?= Strategy_uv_high_fanout_explore
UVHS_COMPILE_STRATEGY_NUM ?= 1
UVHS_COMPILE_STRATEGY0 ?= uv_high_fanout_explore
UVHS_LUT_FILL_RATE ?= $(if $(filter kmh,$(CPU)),80,)
UVHS_LUT6_FILL_RATE ?= $(if $(filter kmh,$(CPU)),30,)
UVHS_ROUTE_ENABLE_HOLD_EXPN_BAILOUT ?= $(if $(filter kmh,$(CPU)),0,)

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
UVHS_REQUIRED_DCP_MODULES := blk_mem_gen_0 AXI_bridge data_bridge xdma_ep uvw_axi4_to_ddr4
UVHS_REQUIRED_MODULES ?= $(if $(filter nanhu,$(CPU)),XlnFpgaTop,$(if $(filter kmh nutshell,$(CPU)),SimTop,))
UVHS_DDR_RTL_INST := $(UVHS_TOP).core_def.U_UVHS_UVW_AXI4_TO_DDR4
UVHS_RUNTIME_LIB_DIR ?= $(UVHS_WORK_DIR)/.uvhs-runtime-lib

UVHS_FLOW_ENV = \
	PATH="$(UVHS_ROOT_DIR)/uvhs/make_compat:$$UV_ROOT/bin:$$UV_ROOT/lib/venv3.8/bin:$$UV_ROOT/lib/gcc10.3/bin:$$PATH" \
	LD_LIBRARY_PATH="$(UVHS_RUNTIME_LIB_DIR):$${LD_LIBRARY_PATH:-}" \
	UVHS_FLOW=1 \
	PLATFORM="$(PLATFORM)" \
	XDMA_LINK_WIDTH="$(XDMA_LINK_WIDTH)" \
	XDMA_ENABLE_PF0_BAR1="$(XDMA_ENABLE_PF0_BAR1)" \
	XDMA_AXILITE_MASTER_SCALE="$(XDMA_AXILITE_MASTER_SCALE)" \
	XDMA_AXILITE_MASTER_SIZE="$(XDMA_AXILITE_MASTER_SIZE)" \
	UVHS_DESIGN_NAME="$(UVHS_DESIGN_NAME)" \
	UVHS_TARGET_PACK="$(UVHS_TARGET_PACK)" \
	UVHS_TARGET_FPGA="$(UVHS_TARGET_FPGA)" \
	UVHS_TARGET_FPGA_LOWER="$(UVHS_TARGET_FPGA_LOWER)" \
	UVHS_KEEP_FPGAS="$(UVHS_KEEP_FPGAS)" \
	UVHS_CPU_CLK_PERIOD_NS="$(UVHS_CPU_CLK_PERIOD_NS)" \
	UVHS_CPU_DEBUG_CLK="$(UVHS_CPU_DEBUG_CLK)" \
	UVHS_PNR_STRATEGY="$(UVHS_PNR_STRATEGY)" \
	UVHS_COMPILE_STRATEGY_NUM="$(UVHS_COMPILE_STRATEGY_NUM)" \
	UVHS_COMPILE_STRATEGY0="$(UVHS_COMPILE_STRATEGY0)" \
	UVHS_LUT_FILL_RATE="$(UVHS_LUT_FILL_RATE)" \
	UVHS_LUT6_FILL_RATE="$(UVHS_LUT6_FILL_RATE)" \
	UVHS_ROUTE_ENABLE_HOLD_EXPN_BAILOUT="$(UVHS_ROUTE_ENABLE_HOLD_EXPN_BAILOUT)"

UVHS_PNR_DIR ?= $(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir/$(UVHS_PNR_STRATEGY)
UVHS_BITSTREAM_DIR ?= $(UVHS_PNR_DIR)/bitstream
UVHS_BIT_HOME ?= $(UVHS_WORK_DIR)/ready-to-program

.PHONY: uvhs_preflight uvhs_prepare uvhs_export_vivado_ip \
	uvhs_sync_uvw_axi4_to_ddr4 uvhs_filelist uvhs_check_modules \
	uvhs_frontend uvhs_backend uvhs_all uvhs_check_timing \
	uvhs_package_bitstream uvhs_tools_check uvhs_clean

uvhs_preflight:
	test -n "$$UV_ROOT"
	test -x "$$UV_ROOT/bin/uv_shell"
	test -n "$$UV_XILINX_VIVADO"
	test -x "$$UV_XILINX_VIVADO/bin/vivado"
	test -n "$$UV_LICENSE"
	test -d "$(UVHS_TEMPLATE_DIR)/script"
	test -f "$(UVHS_TEMPLATE_DIR)/Makefile"
	test -f "$(UVHS_TEMPLATE_DIR)/script/1B_4F_HGC_assemble.tcl"
	test -d "$(UVHS_UVW_AXI4_TO_DDR4_SRC)"
	mkdir -p "$(UVHS_RUNTIME_LIB_DIR)"
	bash -c 'set -euo pipefail; \
		ffi="$$(ldconfig -p | awk '\''/libffi[.]so[.]6 / { print $$NF; exit } /libffi[.]so[.]8 / { fallback = $$NF } END { if (fallback != "") print fallback }'\'')"; \
		test -n "$$ffi"; \
		ln -sfn "$$ffi" "$(UVHS_RUNTIME_LIB_DIR)/libffi.so.6"'

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
		version="$(UVHS_EXPORT_IP_VIVADO_VERSION)"; \
		if [ -z "$$version" ]; then version="$$("$$UV_XILINX_VIVADO/bin/vivado" -version | sed -n "s/^Vivado v\\([^ ]*\\).*/\\1/p" | head -n 1)"; fi; \
		$(UVHS_FLOW_ENV) "$$UV_XILINX_VIVADO/bin/vivado" -mode batch \
		-source "$(UVHS_ROOT_DIR)/uvhs/export_vivado_ip.tcl" -tclargs \
		--origin_dir "$(UVHS_ROOT_DIR)" --out_dir "$(UVHS_WORK_DIR)" \
		--vivado_version "$$version" --cpu "$(CPU)" --core_dir "$(CORE_DIR)" \
		--jobs "$(UVHS_EXPORT_IP_JOBS)" \
		$(if $(strip $(UVHS_EXPORT_IP_ONLY)),--only "$(UVHS_EXPORT_IP_ONLY)",) \
		$(foreach ip,$(UVHS_SKIP_VIVADO_EXPORT),--skip "$(ip)") \
		$(if $(filter 1,$(UVHS_EXPORT_IP_FORCE)),--force,)'

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
		if [ -n "$(UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5)" ]; then \
			echo "$(UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5)  $$work/rtl/soc/uvw_axi4_to_ddr4.dcp" | md5sum -c -; \
		fi'

uvhs_filelist:
	mkdir -p "$(dir $(UVHS_FILELIST))"
	{ \
		printf '+define+SYNTHESIS\n+define+XIANGSHAN_FPGA\n'; \
		printf '+define+RANDOMIZE_GARBAGE_ASSIGN\n+define+RANDOMIZE_REG_INIT\n'; \
		printf '+define+RANDOMIZE_MEM_INIT\n+define+RANDOMIZE_DELAY=1\n'; \
		printf '+define+UVHS_SOC_ADAPT\n+define+UVHS_UVW_AXI4_TO_DDR4\n'; \
		printf '+define+DDR4_16G_X8\n+define+DQ64\n+define+DDR4_2400\n'; \
		printf '+define+DQ=64\n+define+MICRON_DDR\n+define+DDR4_16Gbx8\n'; \
		printf '+define+DDR4\n+define+SRAM_SYN\n+define+DATA_VERSION=0\n'; \
		if [ "$(CPU)" = nutshell ]; then printf '+define+CPU_NUTSHELL\n'; fi; \
		if [ "$(CPU)" = kmh ]; then \
			simtop=""; \
			for candidate in "$(CORE_DIR)/build/rtl/SimTop.sv" \
				"$(CORE_DIR)/rtl/SimTop.sv" "$(CORE_DIR)/SimTop.sv"; do \
				if [ -f "$$candidate" ]; then simtop="$$candidate"; break; fi; \
			done; \
			if [ -n "$$simtop" ] && \
				grep -Eq '^[[:space:]]*(input|output)[[:space:]].*dma_awready' "$$simtop"; then \
				printf '+define+CONFIG_SIMTOP_HAS_DMA\n'; \
			fi; \
		fi; \
		if [ "$(UVHS_CPU_DEBUG_CLK)" = 1 ]; then printf '+define+UVHS_CPU_DEBUG_CLK\n'; fi; \
		if [ -n "$(CHI_DIR)" ]; then printf '+define+MSI_MODE\n+define+CONFIG_USE_XSCORE_CHI\n'; \
		else printf '+define+CONFIG_USE_XSCORE_AXI\n'; fi; \
		if [ -d "$(CORE_DIR)/build" ]; then printf '+incdir+%s/build\n' "$(CORE_DIR)"; fi; \
		if [ -d "$(CORE_DIR)/build/rtl" ]; then printf '+incdir+%s/build/rtl\n' "$(CORE_DIR)"; fi; \
		if [ -d "$(CORE_DIR)/build/generated-src" ]; then printf '+incdir+%s/build/generated-src\n' "$(CORE_DIR)"; fi; \
		printf '+incdir+%s/src/rtl/common\n' "$(UVHS_ROOT_DIR)"; \
		find "$(UVHS_ROOT_DIR)/src/rtl/common" -type f \
			\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) \
			! -name 'u0_xdma.v' -print | sort; \
		test ! -d "$(UVHS_WORK_DIR)/rtl/stubs" || \
			find "$(UVHS_WORK_DIR)/rtl/stubs" -type f -name '*.v' -print | sort; \
		test ! -d "$(UVHS_ROOT_DIR)/src/rtl/$(CPU)" || \
			find "$(UVHS_ROOT_DIR)/src/rtl/$(CPU)" -type f \
			\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		if [ -d "$(CORE_DIR)/build/rtl" ]; then \
			find "$(CORE_DIR)/build/rtl" -type f \
				\( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		elif [ -n "$(CORE_DIR)" ] && [ -d "$(CORE_DIR)" ]; then \
			find "$(CORE_DIR)" \( -path '*/rtl/verification' -o -path '*/out' \) -prune -o \
				-type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		fi; \
		test ! -f "$(CORE_DIR)/difftest/src/test/vsrc/common/DifftestClockGate.v" || \
			printf '%s\n' "$(CORE_DIR)/difftest/src/test/vsrc/common/DifftestClockGate.v"; \
		if [ -n "$(CHI_DIR)" ] && [ -d "$(CHI_DIR)" ]; then \
			find "$(CHI_DIR)" -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
		fi; \
		for item in $(RTL_INCLUDE); do \
			if [ -d "$$item" ]; then find "$$item" -type f \( -name '*.v' -o -name '*.sv' -o -name '*.vh' -o -name '*.svh' \) -print | sort; \
			elif [ -f "$$item" ]; then case "$$item" in *.f|*.flist|*.list) cat "$$item";; *) printf '%s\n' "$$item";; esac; fi; \
		done; \
	} | awk -f "$(UVHS_ROOT_DIR)/uvhs/filelist.awk" > "$(UVHS_FILELIST)"

uvhs_check_modules: uvhs_filelist
	bash "$(UVHS_ROOT_DIR)/uvhs/check_modules.sh" "$(UVHS_FILELIST)" "$(UVHS_REQUIRED_MODULES)"

uvhs_frontend: uvhs_export_vivado_ip uvhs_sync_uvw_axi4_to_ddr4 uvhs_check_modules
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_FILELIST=./rtl/filelist.f \
		UVHS_REQUIRED_DCP_MODULES="$(UVHS_REQUIRED_DCP_MODULES)" \
		UVHS_DDR_RTL_INST="$(UVHS_DDR_RTL_INST)" UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP=1 \
		UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_TIMING_FILE="$(UVHS_TIMING_FILE)" \
		UVHS_PARTITION_FILE=none UVHS_PROBE_FILE=none UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" \
		UVHS_MEM_ARRAY_DC=none UVHS_AUX_DDR_DC=none UVHS_USE_LSF="$(UVHS_USE_LSF)" \
		UVHS_FRONTEND_THREADS="$(UVHS_FRONTEND_THREADS)" UVHS_FRONTEND_PROCESSES="$(UVHS_FRONTEND_PROCESSES)" \
		UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_ROOT_DIR)/uvhs/frontend_run.tcl" |& tee frontend_run.log'

uvhs_backend:
	bash -c 'set -euo pipefail; cd "$(UVHS_WORK_DIR)"; \
		$(UVHS_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP=1 \
		UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" \
		UVHS_MEM_ARRAY_DC=none UVHS_AUX_DDR_DC=none UVHS_USE_LSF="$(UVHS_USE_LSF)" \
		UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" \
		bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check \
		-s "$(UVHS_ROOT_DIR)/uvhs/backend_run.tcl" |& tee backend_run.log'

uvhs_all: uvhs_frontend uvhs_backend

uvhs_check_timing:
	test -f "$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"
	! grep -q 'Timing constraints are not met' "$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"

uvhs_package_bitstream: uvhs_check_timing
	test -f "$(UVHS_BITSTREAM_DIR)/pnr.bit"
	mkdir -p "$(UVHS_BIT_HOME)"
	ln -sf "$(UVHS_BITSTREAM_DIR)/pnr.bit" "$(UVHS_BIT_HOME)/fpga_top_debug.bit"
	@echo "FPGA_BIT_HOME=$(UVHS_BIT_HOME)"

uvhs_clean:
	test -n "$(UVHS_WORK_DIR)"
	rm -rf "$(UVHS_WORK_DIR)"
