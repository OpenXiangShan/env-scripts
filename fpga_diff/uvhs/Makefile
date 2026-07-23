ROOT_DIR ?= $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
ENV_SCRIPTS_HOME ?= $(ROOT_DIR)

CORE_DIR ?=
CHI_DIR ?=
CPU ?=
SUFFIX ?=
VIVADO ?= vivado
PLATFORM ?= U2.2
XDMA_LINK_WIDTH ?= X4
XDMA_ENABLE_PF0_BAR1 ?= 1
# Expected values for the checked Hejian XDMA EP x4 DCP used by this UVHS
# flow. They guide script preflight; xdma_ep itself comes from
# UVHS_XDMA_EP_DCP, not from patching the Vivado xdma_ep Tcl source.
XDMA_AXILITE_MASTER_SCALE ?= Kilobytes
XDMA_AXILITE_MASTER_SIZE ?= 512
XDMA_EXPECTED_VENDOR ?= 0x10ee
XDMA_EXPECTED_DEVICE ?= 0x9048
XDMA_EXPECTED_BAR0_SIZE ?= 0x80000
XDMA_EXPECTED_BAR1_SIZE ?= 0x10000
UVHS_XDMA_EP_EXAMPLE_DIR ?= $(abspath $(ROOT_DIR)/../../uvhs_1ep_test_0417_x4_xdma_loopback)
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
export XDMA_LINK_WIDTH XDMA_ENABLE_PF0_BAR1 XDMA_AXILITE_MASTER_SCALE XDMA_AXILITE_MASTER_SIZE XDMA_EXPECTED_VENDOR XDMA_EXPECTED_DEVICE XDMA_EXPECTED_BAR0_SIZE XDMA_EXPECTED_BAR1_SIZE UVHS_XDMA_EP_EXAMPLE_DIR UVHS_XDMA_EP_DEFAULT_DCP UVHS_XDMA_EP_DEFAULT_DCP_SHA256 UVHS_XDMA_EP_DEFAULT_DCP_VIVADO UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256 UVHS_BASE_ASSEMBLE_FILE UVHS_BASE_ASSEMBLE_SHA256 UVHS_XDMA_EP_DCP UVHS_XDMA_EP_DCP_SHA256 UVHS_ALLOW_DCP_VIVADO_MISMATCH UVHS_DESIGN_NAME

UVHS_TARBALL_CANDIDATES ?= $(abspath $(ROOT_DIR)/../uvhs.tar.gz) $(abspath $(ROOT_DIR)/../../../env-scripts/uvhs.tar.gz)
UVHS_TARBALL ?= $(firstword $(wildcard $(UVHS_TARBALL_CANDIDATES)))
UVHS_TEMPLATE ?= uvhs_1core_cpu0121_soc1229_iommu_1rc_19p
UVHS_WORK_DIR ?= $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
UVHS_TOP ?= fpga_top_debug
UVHS_FILELIST ?= $(UVHS_WORK_DIR)/rtl/filelist.f
UVHS_ROOT ?= $(shell bash -lc 'source "$(ROOT_DIR)/uvhs/setenv.sh" >/dev/null 2>&1 && printf "%s" "$$UV_ROOT"')
UVHS_UVW_AXI4_TO_DDR4_FETCH_DIR ?= $(ENV_SCRIPTS_HOME)/uvhs_uvw_axi4_to_ddr4_remote
UVHS_UVW_AXI4_TO_DDR4_SRC_CANDIDATES ?= $(ENV_SCRIPTS_HOME)/uvhs_nutshell-uvhs-ddr-uvw-ip-bind $(UVHS_UVW_AXI4_TO_DDR4_FETCH_DIR) $(ENV_SCRIPTS_HOME)/uvhs_nutshell-uvhs-ddr-uvw-ip
UVHS_UVW_AXI4_TO_DDR4_SRC ?=
UVHS_UVW_AXI4_TO_DDR4_FILES ?= rtl/soc/uvw_axi4_to_ddr4.dcp rtl/soc/uvw_axi4_to_ddr4_Stub.v script/uvw_axi4_to_ddr4_pblock.tcl script/custom_parts_ddr4_KSM26SES8_2666.csv
UVHS_UVW_AXI4_TO_DDR4_REQUIRED_FILES ?= rtl/soc/uvw_axi4_to_ddr4.dcp rtl/soc/uvw_axi4_to_ddr4_Stub.v script/uvw_axi4_to_ddr4_pblock.tcl
UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5 ?= bbd428f1fa2ede1628e11b7ab14d1072
UVHS_UVW_AXI4_TO_DDR4_ALLOW_TEMPLATE_FALLBACK ?= 0
UVHS_FETCH_UVW_AXI4_TO_DDR4 ?= 0
UVHS_UVW_AXI4_TO_DDR4_REMOTE_HOST ?= root@172.38.11.85
UVHS_UVW_AXI4_TO_DDR4_REMOTE_ROOTS ?= /home/data/test/nutshell-latest-ddr-runtime
UVHS_EXPORT_IP ?= 1
UVHS_EXPORT_IP_FORCE ?= 1
UVHS_EXPORT_IP_JOBS ?= 8
UVHS_EXPORT_IP_VIVADO_VERSION ?=
UVHS_EXPORT_IP_ONLY ?=
UVHS_SKIP_VIVADO_EXPORT ?=
UVHS_EFFECTIVE_SKIP_VIVADO_EXPORT = $(sort $(UVHS_SKIP_VIVADO_EXPORT) $(if $(strip $(UVHS_XDMA_EP_DCP)),xdma_ep,))
UVHS_PREBUILT_DCP_DIR ?=
UVHS_AXI_BRIDGE_DCP ?=
UVHS_AXI_BRIDGE_DCP_SHA256 ?=
UVHS_XDMA_STUB ?= 0
UVHS_XDMA_ST_LOOPBACK_SMOKE ?= 0
UVHS_REQUIRED_DCP_MODULES ?= blk_mem_gen_0 AXI_bridge data_bridge vio_0 xdma_ep jtag_ddr_subsys uvw_axi4_to_ddr4
UVHS_BLACKBOX_JTAG_DDR_SUBSYS ?= 1
UVHS_DDR_RTL_INST ?= $(UVHS_TOP).core_def.U_JTAG_DDR_SUBSYS
UVHS_UVW_AXI4_TO_DDR4_RTL_INST ?= $(UVHS_TOP).core_def.U_UVHS_UVW_AXI4_TO_DDR4
UVHS_OPTION_MEM_REFNAME ?=
UVHS_FRONTEND_TCL ?= $(ROOT_DIR)/uvhs/frontend_run.tcl
UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP ?= 0
UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_OVERRIDE ?=
UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_EFFECTIVE = $(if $(strip $(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_OVERRIDE)),$(strip $(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_OVERRIDE)),$(strip $(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP)))
UVHS_SKIP_BOARD_CONSTRAINTS ?= 0
UVHS_PIN_OVERRIDE_FILE ?=
UVHS_PROBE_FILE ?=
UVHS_CPU_CLK_PERIOD_NS ?= 40
UVHS_CPU_DEBUG_CLK ?= 1
UVHS_CPU_LIVENESS_GBD ?= 0
UVHS_GENERALBD_DCP ?= $(UVHS_ROOT)/doc/UVHS/example/gbd_demo/gBD_force_monitor/gbd_ip/generalBD.dcp
UVHS_GENERALBD_STUB ?= $(UVHS_ROOT)/doc/UVHS/example/gbd_demo/gBD_force_monitor/gbd_ip/generalBD_Stub.vp
UVHS_ASSIGN_PIN_FILE ?= $(if $(filter nutshell,$(CPU)),$(ROOT_DIR)/uvhs/assign_pin_nutshell_f2.tcl,)
UVHS_TIMING_FILE ?=
UVHS_PARTITION_FILE ?=
UVHS_ASSEMBLE_FILE ?=
UVHS_MEM_ARRAY_DC ?= UV_MEM_ARRAY_F
UVHS_MEM_ARRAY_INST ?= mem_array_inst0
UVHS_MEM_ARRAY_CONNECTOR ?= b0.F2_FMC1
UVHS_AUX_DDR_DC ?=
UVHS_AUX_DDR_INST ?= pddr4dme_f2_aux_inst
UVHS_AUX_DDR_CONNECTOR ?= b0.F2_FMC2
UVHS_AUX_DDR_SWAP_BASE_CONNECTOR ?=
UVHS_STOP_AFTER_PARTITION ?= 0
UVHS_STOP_AFTER_GENSCRIPT ?= 0
UVHS_VIVADO_DEBUG_FILE ?=
UVHS_USE_LSF ?= 0
UVHS_FRONTEND_THREADS ?= 4
UVHS_FRONTEND_PROCESSES ?= 16
UVHS_FPGA_THREADS ?= 4
UVHS_FPGA_PROCESSES ?= 8
UVHS_TARGET_BOARD ?= B0
UVHS_TARGET_PACK ?= $(UVHS_TARGET_BOARD)
UVHS_TARGET_FPGA ?= F2
UVHS_TARGET_FPGA_LOWER ?= $(shell printf '%s.%s' '$(UVHS_TARGET_PACK)' '$(UVHS_TARGET_FPGA)' | tr '[:upper:]' '[:lower:]')
UVHS_FPGA_COUNT ?= 1
UVHS_KEEP_FPGAS ?= $(UVHS_TARGET_FPGA_LOWER)
UVHS_UART0_CONNECTOR ?= b0.F2_APC16
UVHS_UART0_TX_INDEX ?= 117
UVHS_UART0_RX_INDEX ?= 57
UVHS_TIME_GROUP_IO_LOGIC ?= default
UVHS_STRATEGY_NUM_RETRY ?=
UVHS_REQUIRED_MODULES ?= $(if $(filter nanhu,$(CPU)),XlnFpgaTop,$(if $(filter kmh nutshell,$(CPU)),SimTop,))
# Match the enumerable Hejian XDMA EP x4 example, whose successful bitstream
# landed under Strategy_uv_high_fanout_explore.
UVHS_PNR_STRATEGY ?= Strategy_uv_high_fanout_explore
UVHS_COMPILE_STRATEGY_NUM ?= 1
UVHS_COMPILE_STRATEGY0 ?= uv_high_fanout_explore
UVHS_COMPILE_STRATEGY1 ?=
UVHS_COMPILE_STRATEGY2 ?=
export UVHS_PNR_STRATEGY UVHS_COMPILE_STRATEGY_NUM UVHS_COMPILE_STRATEGY0 UVHS_COMPILE_STRATEGY1 UVHS_COMPILE_STRATEGY2
UVHS_HEJIAN_FLOW_ENV = XDMA_LINK_WIDTH="$(XDMA_LINK_WIDTH)" XDMA_ENABLE_PF0_BAR1="$(XDMA_ENABLE_PF0_BAR1)" XDMA_AXILITE_MASTER_SCALE="$(XDMA_AXILITE_MASTER_SCALE)" XDMA_AXILITE_MASTER_SIZE="$(XDMA_AXILITE_MASTER_SIZE)" XDMA_EXPECTED_VENDOR="$(XDMA_EXPECTED_VENDOR)" XDMA_EXPECTED_DEVICE="$(XDMA_EXPECTED_DEVICE)" XDMA_EXPECTED_BAR0_SIZE="$(XDMA_EXPECTED_BAR0_SIZE)" XDMA_EXPECTED_BAR1_SIZE="$(XDMA_EXPECTED_BAR1_SIZE)" UVHS_BASE_ASSEMBLE_FILE="$(UVHS_BASE_ASSEMBLE_FILE)" UVHS_BASE_ASSEMBLE_SHA256="$(UVHS_BASE_ASSEMBLE_SHA256)" UVHS_XDMA_EP_DEFAULT_DCP_VIVADO="$(UVHS_XDMA_EP_DEFAULT_DCP_VIVADO)" UVHS_ALLOW_DCP_VIVADO_MISMATCH="$(UVHS_ALLOW_DCP_VIVADO_MISMATCH)" UVHS_DESIGN_NAME="$(UVHS_DESIGN_NAME)" PLATFORM="$(PLATFORM)" UVHS_TARGET_BOARD="$(UVHS_TARGET_BOARD)" UVHS_TARGET_PACK="$(UVHS_TARGET_PACK)" UVHS_TARGET_FPGA="$(UVHS_TARGET_FPGA)" UVHS_TARGET_FPGA_LOWER="$(UVHS_TARGET_FPGA_LOWER)" UVHS_FPGA_COUNT="$(UVHS_FPGA_COUNT)" UVHS_KEEP_FPGAS="$(UVHS_KEEP_FPGAS)" UVHS_UART0_CONNECTOR="$(UVHS_UART0_CONNECTOR)" UVHS_UART0_TX_INDEX="$(UVHS_UART0_TX_INDEX)" UVHS_UART0_RX_INDEX="$(UVHS_UART0_RX_INDEX)" UVHS_TIME_GROUP_IO_LOGIC="$(UVHS_TIME_GROUP_IO_LOGIC)" UVHS_CPU_CLK_PERIOD_NS="$(UVHS_CPU_CLK_PERIOD_NS)" UVHS_CPU_DEBUG_CLK="$(UVHS_CPU_DEBUG_CLK)" UVHS_MEM_ARRAY_DC="$(UVHS_MEM_ARRAY_DC)" UVHS_AUX_DDR_DC="$(UVHS_AUX_DDR_DC)" UVHS_PNR_STRATEGY="$(UVHS_PNR_STRATEGY)" UVHS_COMPILE_STRATEGY_NUM="$(UVHS_COMPILE_STRATEGY_NUM)" UVHS_COMPILE_STRATEGY0="$(UVHS_COMPILE_STRATEGY0)" UVHS_COMPILE_STRATEGY1="$(UVHS_COMPILE_STRATEGY1)" UVHS_COMPILE_STRATEGY2="$(UVHS_COMPILE_STRATEGY2)"
UVHS_PNR_DIR ?= $(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir/$(UVHS_PNR_STRATEGY)
UVHS_BITSTREAM_DIR ?= $(UVHS_PNR_DIR)/bitstream
UVHS_LTX ?= $(UVHS_BITSTREAM_DIR)/fpga_top_debug.ltx
UVHS_BIT_HOME ?= $(UVHS_WORK_DIR)/ready-to-program
UVHS_RESOLVED_BITSTREAM_DIR = $$(summary="$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"; if [ -f "$$summary" ]; then dirname "$$summary"; else pnr_root="$(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir"; find "$$pnr_root" -name ".Task_strategy_*.timingclean" -printf "%h\n" 2>/dev/null | sort -u | while read -r dir; do test -f "$$dir/bitstream/after_xtalk_fix_timing_summary.txt" && printf "%s\n" "$$dir/bitstream"; done | head -1; fi)

.PHONY: uvhs_prepare uvhs_filelist uvhs_check_modules uvhs_tools_check \
	uvhs_export_vivado_ip uvhs_fetch_uvw_axi4_to_ddr4 \
	uvhs_sync_uvw_axi4_to_ddr4 uvhs_show_uvw_axi4_to_ddr4 \
	vivado_frontend vivado_backend vivado_all \
	uvhs_frontend uvhs_backend uvhs_all \
	uvhs_vivado_frontend uvhs_vivado_backend uvhs_vivado_all \
	uvhs_clean uvhs_env uvhs_preflight uvhs_hejian_pcie_x4_env \
	uvhs_hejian_pcie_x4_preflight uvhs_hejian_pcie_x4_nutshell_all \
	uvhs_status uvhs_check_timing_clean uvhs_export_ltx uvhs_package_bitstream

uvhs_tools_check:
	bash "$(ROOT_DIR)/uvhs/check_flow_tools.sh"

uvhs_prepare:
	test -f "$(UVHS_TARBALL)"
	rm -rf "$(UVHS_WORK_DIR)/script"
	rm -rf "$(UVHS_WORK_DIR)/uvhs"
	mkdir -p "$(UVHS_WORK_DIR)"
	tar -xzf "$(UVHS_TARBALL)" -C "$(UVHS_WORK_DIR)" --strip-components=1 \
		"$(UVHS_TEMPLATE)/script" \
		"$(UVHS_TEMPLATE)/Makefile" \
		"$(UVHS_TEMPLATE)/rerun"
	mkdir -p "$(UVHS_WORK_DIR)/rtl" "$(UVHS_WORK_DIR)/rtl/soc" "$(UVHS_WORK_DIR)/rtl/device/pcie"
	if [ "$(strip $(UVHS_CPU_LIVENESS_GBD))" = "1" ]; then \
		test -f "$(UVHS_GENERALBD_DCP)"; \
		test -f "$(UVHS_GENERALBD_STUB)"; \
		mkdir -p "$(UVHS_WORK_DIR)/rtl/soc/generalBD"; \
		cp -f "$(UVHS_GENERALBD_DCP)" "$(UVHS_WORK_DIR)/rtl/soc/generalBD/generalBD.dcp"; \
		cp -f "$(UVHS_GENERALBD_STUB)" "$(UVHS_WORK_DIR)/rtl/soc/generalBD/generalBD_stub.vp"; \
	fi
	if ls "$(ROOT_DIR)"/uvhs/assign_pin_*.tcl >/dev/null 2>&1; then \
		mkdir -p "$(UVHS_WORK_DIR)/uvhs"; \
		cp "$(ROOT_DIR)"/uvhs/assign_pin_*.tcl "$(UVHS_WORK_DIR)/uvhs/"; \
	fi
	if [ -f "$(ROOT_DIR)/uvhs/partition.tcl" ]; then \
		cp "$(ROOT_DIR)/uvhs/partition.tcl" "$(UVHS_WORK_DIR)/script/partition.tcl"; \
	fi
	if [ -f "$(ROOT_DIR)/uvhs/probe.tcl" ]; then \
		cp "$(ROOT_DIR)/uvhs/probe.tcl" "$(UVHS_WORK_DIR)/script/probe.tcl"; \
	else \
		printf '# Intentionally empty for UVHS bring-up.\n' > "$(UVHS_WORK_DIR)/script/probe.tcl"; \
	fi
	for dcp in \
		rtl/soc/AXI_bridge.dcp \
		rtl/soc/blk_mem_gen_0.dcp \
		rtl/soc/uvw_axi4_to_ddr4.dcp \
		rtl/soc/uvw_axi4_to_ddr4_Stub.v; do \
		if [ ! -f "$(UVHS_WORK_DIR)/$$dcp" ]; then \
			tar -xzf "$(UVHS_TARBALL)" -C "$(UVHS_WORK_DIR)" --strip-components=1 "$(UVHS_TEMPLATE)/$$dcp"; \
		fi; \
	done
	if [ -n "$(strip $(UVHS_PREBUILT_DCP_DIR))" ]; then \
		test -d "$(UVHS_PREBUILT_DCP_DIR)"; \
		for dcp in \
			rtl/soc/AXI_bridge.dcp \
			rtl/soc/blk_mem_gen_0.dcp \
			rtl/soc/data_bridge.dcp \
			rtl/soc/vio_0.dcp \
			rtl/device/pcie/xdma_ep.dcp; do \
			if [ -f "$(UVHS_PREBUILT_DCP_DIR)/$$dcp" ]; then \
				mkdir -p "$$(dirname "$(UVHS_WORK_DIR)/$$dcp")"; \
				cp -f "$(UVHS_PREBUILT_DCP_DIR)/$$dcp" "$(UVHS_WORK_DIR)/$$dcp"; \
				echo "INFO: synced prebuilt DCP $$dcp from $(UVHS_PREBUILT_DCP_DIR)"; \
			fi; \
		done; \
	fi
	if [ -n "$(strip $(UVHS_AXI_BRIDGE_DCP))" ]; then \
		test -s "$(UVHS_AXI_BRIDGE_DCP)"; \
		if [ -n "$(strip $(UVHS_AXI_BRIDGE_DCP_SHA256))" ]; then \
			actual="$$(sha256sum "$(UVHS_AXI_BRIDGE_DCP)" | awk '{print $$1}')"; \
			if [ "$$actual" != "$(strip $(UVHS_AXI_BRIDGE_DCP_SHA256))" ]; then \
				echo "ERROR: UVHS_AXI_BRIDGE_DCP sha256 mismatch: $$actual != $(strip $(UVHS_AXI_BRIDGE_DCP_SHA256))" >&2; \
				exit 1; \
			fi; \
		fi; \
		cp -f "$(UVHS_AXI_BRIDGE_DCP)" "$(UVHS_WORK_DIR)/rtl/soc/AXI_bridge.dcp"; \
		echo "INFO: synced explicit AXI_bridge DCP from $(UVHS_AXI_BRIDGE_DCP)"; \
	fi
	if [ -n "$(strip $(UVHS_XDMA_EP_DCP))" ]; then \
		test -s "$(UVHS_XDMA_EP_DCP)"; \
		if [ -n "$(strip $(UVHS_XDMA_EP_DCP_SHA256))" ]; then \
			actual="$$(sha256sum "$(UVHS_XDMA_EP_DCP)" | awk '{print $$1}')"; \
			if [ "$$actual" != "$(strip $(UVHS_XDMA_EP_DCP_SHA256))" ]; then \
				echo "ERROR: UVHS_XDMA_EP_DCP sha256 mismatch: $$actual != $(strip $(UVHS_XDMA_EP_DCP_SHA256))" >&2; \
				exit 1; \
			fi; \
		fi; \
		mkdir -p "$(UVHS_WORK_DIR)/rtl/device/pcie"; \
		cp -f "$(UVHS_XDMA_EP_DCP)" "$(UVHS_WORK_DIR)/rtl/device/pcie/xdma_ep.dcp"; \
		echo "INFO: synced XDMA EP DCP from $(UVHS_XDMA_EP_DCP)"; \
	fi
	if [ -n "$(strip $(UVHS_BASE_ASSEMBLE_FILE))" ]; then \
		test -s "$(UVHS_BASE_ASSEMBLE_FILE)"; \
		if [ -n "$(strip $(UVHS_BASE_ASSEMBLE_SHA256))" ]; then \
			actual="$$(sha256sum "$(UVHS_BASE_ASSEMBLE_FILE)" | awk '{print $$1}')"; \
			if [ "$$actual" != "$(strip $(UVHS_BASE_ASSEMBLE_SHA256))" ]; then \
				echo "ERROR: UVHS_BASE_ASSEMBLE_FILE sha256 mismatch: $$actual != $(strip $(UVHS_BASE_ASSEMBLE_SHA256))" >&2; \
				exit 1; \
			fi; \
		fi; \
		echo "INFO: use Hejian base assembly from $(UVHS_BASE_ASSEMBLE_FILE)"; \
	fi

uvhs_export_vivado_ip: uvhs_prepare
ifeq ($(strip $(UVHS_EXPORT_IP)),1)
	bash -lc 'source "$(ROOT_DIR)/uvhs/setenv.sh" && if [ ! -x "$$UV_XILINX_VIVADO/bin/vivado" ]; then echo "ERROR: vivado not found at $$UV_XILINX_VIVADO/bin/vivado"; exit 1; fi; vivado_version="$(UVHS_EXPORT_IP_VIVADO_VERSION)"; if [ -z "$$vivado_version" ]; then vivado_version="$$("$$UV_XILINX_VIVADO/bin/vivado" -version | sed -n "s/^Vivado v\\([^ ]*\\).*/\\1/p" | head -n 1)"; fi; $(UVHS_HEJIAN_FLOW_ENV) "$$UV_XILINX_VIVADO/bin/vivado" -mode batch -source "$(ROOT_DIR)/uvhs/export_vivado_ip.tcl" -tclargs --origin_dir "$(ROOT_DIR)" --out_dir "$(UVHS_WORK_DIR)" --vivado_version "$$vivado_version" --cpu "$(CPU)" --core_dir "$(CORE_DIR)" --jobs "$(UVHS_EXPORT_IP_JOBS)" $(if $(strip $(UVHS_EXPORT_IP_ONLY)),--only "$(UVHS_EXPORT_IP_ONLY)",) $(foreach ip,$(UVHS_EFFECTIVE_SKIP_VIVADO_EXPORT),--skip "$(ip)") $(if $(filter 1,$(UVHS_EXPORT_IP_FORCE)),--force,)'
else
	@echo "Skip Vivado IP export because UVHS_EXPORT_IP=$(UVHS_EXPORT_IP)"
endif

uvhs_fetch_uvw_axi4_to_ddr4:
ifeq ($(strip $(UVHS_FETCH_UVW_AXI4_TO_DDR4)),1)
	bash "$(ROOT_DIR)/uvhs/fetch_uvw_axi4_to_ddr4.sh" \
		"$(UVHS_UVW_AXI4_TO_DDR4_REMOTE_HOST)" \
		"$(UVHS_UVW_AXI4_TO_DDR4_REMOTE_ROOTS)" \
		"$(UVHS_UVW_AXI4_TO_DDR4_FETCH_DIR)"
else
	@echo "Skip UVHS DDR IP remote fetch because UVHS_FETCH_UVW_AXI4_TO_DDR4=$(UVHS_FETCH_UVW_AXI4_TO_DDR4)"
endif

uvhs_sync_uvw_axi4_to_ddr4: uvhs_prepare uvhs_fetch_uvw_axi4_to_ddr4
	bash -lc 'src="$(UVHS_UVW_AXI4_TO_DDR4_SRC)"; candidates="$(UVHS_UVW_AXI4_TO_DDR4_SRC_CANDIDATES)"; work="$(UVHS_WORK_DIR)"; allow_template="$(UVHS_UVW_AXI4_TO_DDR4_ALLOW_TEMPLATE_FALLBACK)"; expected_md5="$(UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5)"; if [ -z "$$src" ]; then for cand in $$candidates; do if [ -d "$$cand" ]; then src="$$cand"; break; fi; done; fi; mkdir -p "$$work/rtl/soc" "$$work/script"; if [ -z "$$src" ] && [ "$$allow_template" != "1" ]; then echo "ERROR: UVHS DDR IP source is required for uvhs_frontend; run uvhs_fetch_uvw_axi4_to_ddr4 with UVHS_FETCH_UVW_AXI4_TO_DDR4=1 or set UVHS_UVW_AXI4_TO_DDR4_SRC" >&2; exit 1; fi; if [ -n "$$src" ]; then test -d "$$src"; echo "INFO: use UVW AXI4-to-DDR4 IP source $$src"; case "$$src" in *blackbox_test*) echo "ERROR: refusing blackbox_test UVW AXI4-to-DDR4 source: $$src" >&2; exit 1;; esac; for rel in $(UVHS_UVW_AXI4_TO_DDR4_FILES); do base="$${rel##*/}"; dst="$$work/$$rel"; found=""; for cand in "$$src/$$rel" "$$src/$$base"; do if [ -f "$$cand" ]; then found="$$cand"; break; fi; done; if [ -z "$$found" ]; then found="$$(find "$$src" -type f -name "$$base" ! -path "*blackbox_test*" -size +0c -print -quit)"; fi; if [ -n "$$found" ]; then case "$$found" in *blackbox_test*) echo "ERROR: refusing blackbox_test UVW AXI4-to-DDR4 asset: $$found" >&2; exit 1;; esac; mkdir -p "$$(dirname "$$dst")"; cp -f "$$found" "$$dst"; echo "INFO: synced UVW AXI4-to-DDR4 IP asset $$rel from $$found"; elif [ -f "$$dst" ] && [ "$$allow_template" = "1" ]; then echo "INFO: keep existing UVW AXI4-to-DDR4 IP asset $$rel"; else echo "INFO: optional UVW AXI4-to-DDR4 IP asset not found: $$rel"; fi; done; else echo "INFO: no UVW AXI4-to-DDR4 IP override source configured; template fallback enabled"; fi; for rel in $(UVHS_UVW_AXI4_TO_DDR4_REQUIRED_FILES); do if [ ! -s "$$work/$$rel" ]; then echo "ERROR: missing required UVW AXI4-to-DDR4 IP asset $$work/$$rel"; exit 1; fi; done; if [ -n "$$expected_md5" ]; then actual_md5="$$(md5sum "$$work/rtl/soc/uvw_axi4_to_ddr4.dcp" | awk "{print \$$1}")"; if [ "$$actual_md5" != "$$expected_md5" ]; then echo "ERROR: UVW AXI4-to-DDR4 DCP md5 mismatch: $$actual_md5 != $$expected_md5" >&2; echo "ERROR: override UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5 only when intentionally testing a different verified DDR IP" >&2; exit 1; fi; echo "INFO: verified UVW AXI4-to-DDR4 DCP md5 $$actual_md5"; fi'

uvhs_show_uvw_axi4_to_ddr4:
	bash -lc 'src="$(UVHS_UVW_AXI4_TO_DDR4_SRC)"; candidates="$(UVHS_UVW_AXI4_TO_DDR4_SRC_CANDIDATES)"; expected_md5="$(UVHS_UVW_AXI4_TO_DDR4_EXPECTED_MD5)"; if [ -z "$$src" ]; then for cand in $$candidates; do if [ -d "$$cand" ]; then src="$$cand"; break; fi; done; fi; if [ -z "$$src" ]; then echo "ERROR: no visible UVW AXI4-to-DDR4 IP source; set UVHS_UVW_AXI4_TO_DDR4_SRC or fetch it first" >&2; exit 1; fi; echo "UVHS_UVW_AXI4_TO_DDR4_SRC=$$src"; for rel in $(UVHS_UVW_AXI4_TO_DDR4_REQUIRED_FILES); do if [ ! -s "$$src/$$rel" ]; then found="$$(find "$$src" -type f -name "$${rel##*/}" ! -path "*blackbox_test*" -size +0c -print -quit)"; else found="$$src/$$rel"; fi; if [ -z "$$found" ]; then echo "ERROR: missing $$rel under $$src" >&2; exit 1; fi; echo "$$rel -> $$found"; done; actual_md5="$$(md5sum "$$src/rtl/soc/uvw_axi4_to_ddr4.dcp" | awk "{print \$$1}")"; echo "uvw_axi4_to_ddr4.dcp md5=$$actual_md5"; if [ -n "$$expected_md5" ] && [ "$$actual_md5" != "$$expected_md5" ]; then echo "ERROR: md5 mismatch: $$actual_md5 != $$expected_md5" >&2; exit 1; fi'

uvhs_filelist:
	if [ -n "$(strip $(CORE_DIR))" ]; then \
		bash "$(ROOT_DIR)/uvhs/tools/build/patch_nutshell_cdc.sh" "$(CORE_DIR)"; \
	fi
	mkdir -p "$(dir $(UVHS_FILELIST))"
	{ \
		printf '+define+SYNTHESIS\n'; \
		printf '+define+XIANGSHAN_FPGA\n'; \
		printf '+define+RANDOMIZE_GARBAGE_ASSIGN\n'; \
		printf '+define+RANDOMIZE_REG_INIT\n'; \
		printf '+define+RANDOMIZE_MEM_INIT\n'; \
		printf '+define+RANDOMIZE_DELAY=1\n'; \
		printf '+define+UVHS_SOC_ADAPT\n'; \
		printf '+define+UVHS_NO_XILINX_CLK_PRIMS\n'; \
		printf '+define+DDR4_16G_X8\n'; \
		printf '+define+DQ64\n'; \
		printf '+define+DDR4_2400\n'; \
		printf '+define+DQ=64\n'; \
		printf '+define+MICRON_DDR\n'; \
		printf '+define+DDR4_16Gbx8\n'; \
		printf '+define+DDR4\n'; \
		printf '+define+SRAM_SYN\n'; \
		printf '+define+DATA_VERSION=0\n'; \
		if [ "$(strip $(CPU))" = "nutshell" ]; then \
			printf '+define+CPU_NUTSHELL\n'; \
		fi; \
		if [ "$(strip $(UVHS_NUTSHELL_LEGACY_DIFFTEST_HOSTIF))" = "1" ]; then \
			printf '+define+NUTSHELL_LEGACY_DIFFTEST_HOSTIF\n'; \
		elif [ -n "$(strip $(CORE_DIR))" ]; then \
			nutshell_topmain=""; \
			for cand in "$(CORE_DIR)/rtl/TopMain.sv" "$(CORE_DIR)/build/rtl/TopMain.sv"; do \
				if [ -f "$$cand" ]; then nutshell_topmain="$$cand"; break; fi; \
			done; \
			if [ -n "$$nutshell_topmain" ] && grep -q 'difftest_to_host_axis_bits_last' "$$nutshell_topmain"; then \
				printf '+define+NUTSHELL_LEGACY_DIFFTEST_HOSTIF\n'; \
			fi; \
		fi; \
		if [ "$(strip $(UVHS_XDMA_STUB))" = "1" ]; then \
			printf '+define+UVHS_XDMA_STUB\n'; \
		fi; \
		if [ "$(strip $(UVHS_XDMA_ST_LOOPBACK_SMOKE))" = "1" ]; then \
			printf '+define+UVHS_XDMA_ST_LOOPBACK_SMOKE\n'; \
		fi; \
			if [ "$(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_EFFECTIVE)" = "1" ]; then \
				printf '+define+UVHS_EXTERNAL_UVW_AXI4_TO_DDR4\n'; \
				printf '+define+UVHS_UVW_AXI4_TO_DDR4\n'; \
			elif [ "$(strip $(UVHS_DDR_RTL_INST))" = "$(strip $(UVHS_UVW_AXI4_TO_DDR4_RTL_INST))" ]; then \
				printf '+define+UVHS_EXTERNAL_UVW_AXI4_TO_DDR4\n'; \
				printf '+define+UVHS_UVW_AXI4_TO_DDR4\n'; \
			fi; \
			if [ "$(strip $(UVHS_CPU_DEBUG_CLK))" = "1" ]; then \
				printf '+define+UVHS_CPU_DEBUG_CLK\n'; \
			fi; \
			if [ "$(strip $(UVHS_CPU_LIVENESS_GBD))" = "1" ]; then \
				printf '+define+UVHS_CPU_LIVENESS_GBD\n'; \
			fi; \
		if [ -n "$(strip $(CHI_DIR))" ]; then \
			printf '+define+MSI_MODE\n'; \
			printf '+define+CONFIG_USE_XSCORE_CHI\n'; \
		else \
			printf '+define+CONFIG_USE_XSCORE_AXI\n'; \
		fi; \
		printf '+incdir+%s/src/rtl/common\n' "$(ROOT_DIR)"; \
		if [ -n "$(strip $(CORE_DIR))" ] && [ -d "$(CORE_DIR)" ]; then \
			printf '+incdir+%s\n' "$(CORE_DIR)"; \
			test ! -d "$(CORE_DIR)/rtl" || printf '+incdir+%s/rtl\n' "$(CORE_DIR)"; \
			test ! -d "$(CORE_DIR)/build/generated-src" || printf '+incdir+%s/build/generated-src\n' "$(CORE_DIR)"; \
			test ! -d "$(CORE_DIR)/generated-src" || printf '+incdir+%s/generated-src\n' "$(CORE_DIR)"; \
		fi; \
		find "$(ROOT_DIR)/src/rtl/common" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" -o -name "*.svh" \) \
			! -name "u0_xdma.v" -printf '%p\n' | sort; \
		test -z "$(strip $(CPU))" || test ! -d "$(ROOT_DIR)/src/rtl/$(CPU)" || find "$(ROOT_DIR)/src/rtl/$(CPU)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" -o -name "*.svh" \) -printf '%p\n' | sort; \
		if [ -n "$(strip $(CORE_DIR))" ] && [ -d "$(CORE_DIR)" ]; then \
			if [ -d "$(CORE_DIR)/build/rtl" ]; then \
				test ! -d "$(CORE_DIR)/build/generated-src" || find "$(CORE_DIR)/build/generated-src" -type f \( -name "*.vh" -o -name "*.svh" \) -printf '%p\n' | sort; \
				find "$(CORE_DIR)/build/rtl" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" -o -name "*.svh" \) -printf '%p\n' | sort; \
			else \
				find "$(CORE_DIR)" \
					-path "$(CORE_DIR)/rtl/verification" -prune -o \
					-path "$(CORE_DIR)/20*" -prune -o \
					-path "$(CORE_DIR)/out" -prune -o \
					-type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" -o -name "*.svh" \) -printf '%p\n' | sort; \
			fi; \
		fi; \
		if [ -n "$(strip $(CHI_DIR))" ] && [ -d "$(CHI_DIR)" ]; then \
			find "$(CHI_DIR)" -type f \( -name "*.v" -o -name "*.sv" -o -name "*.vh" -o -name "*.svh" \) -printf '%p\n' | sort; \
		fi; \
	} | awk -f "$(ROOT_DIR)/uvhs/filelist.awk" > "$(UVHS_FILELIST)"

uvhs_check_modules: uvhs_filelist
	bash "$(ROOT_DIR)/uvhs/check_modules.sh" "$(UVHS_FILELIST)" "$(UVHS_REQUIRED_MODULES)"

vivado_frontend: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_vivado_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
vivado_frontend: uvhs_check_modules uvhs_export_vivado_ip
		bash -lc 'set -o pipefail; source "$(ROOT_DIR)/uvhs/setenv.sh" && cd "$(UVHS_WORK_DIR)" && $(UVHS_HEJIAN_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_FILELIST="./rtl/filelist.f" UVHS_REQUIRED_DCP_MODULES="$(UVHS_REQUIRED_DCP_MODULES)" UVHS_BLACKBOX_JTAG_DDR_SUBSYS="$(UVHS_BLACKBOX_JTAG_DDR_SUBSYS)" UVHS_DDR_RTL_INST="$(UVHS_DDR_RTL_INST)" UVHS_OPTION_MEM_REFNAME="$(UVHS_OPTION_MEM_REFNAME)" UVHS_SKIP_BOARD_CONSTRAINTS="$(UVHS_SKIP_BOARD_CONSTRAINTS)" UVHS_PROBE_FILE="$(UVHS_PROBE_FILE)" UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_TIMING_FILE="$(UVHS_TIMING_FILE)" UVHS_PARTITION_FILE="$(UVHS_PARTITION_FILE)" UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" UVHS_MEM_ARRAY_DC="$(UVHS_MEM_ARRAY_DC)" UVHS_MEM_ARRAY_INST="$(UVHS_MEM_ARRAY_INST)" UVHS_MEM_ARRAY_CONNECTOR="$(UVHS_MEM_ARRAY_CONNECTOR)" UVHS_USE_LSF="$(UVHS_USE_LSF)" UVHS_FRONTEND_THREADS="$(UVHS_FRONTEND_THREADS)" UVHS_FRONTEND_PROCESSES="$(UVHS_FRONTEND_PROCESSES)" UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check -s "$(UVHS_FRONTEND_TCL)" |& tee frontend_run.log'

vivado_backend: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_vivado_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
vivado_backend:
	bash -lc 'set -o pipefail; source "$(ROOT_DIR)/uvhs/setenv.sh" && cd "$(UVHS_WORK_DIR)" && $(UVHS_HEJIAN_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_SKIP_BOARD_CONSTRAINTS="$(UVHS_SKIP_BOARD_CONSTRAINTS)" UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_PIN_OVERRIDE_FILE="$(UVHS_PIN_OVERRIDE_FILE)" UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" UVHS_STOP_AFTER_PARTITION="$(UVHS_STOP_AFTER_PARTITION)" UVHS_STOP_AFTER_GENSCRIPT="$(UVHS_STOP_AFTER_GENSCRIPT)" UVHS_VIVADO_DEBUG_FILE="$(UVHS_VIVADO_DEBUG_FILE)" UVHS_USE_LSF="$(UVHS_USE_LSF)" UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" UVHS_STRATEGY_NUM_RETRY="$(UVHS_STRATEGY_NUM_RETRY)" bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check -s "$(ROOT_DIR)/uvhs/backend_run.tcl" |& tee backend_run.log'

vivado_all: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_vivado_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
vivado_all: vivado_frontend vivado_backend

uvhs_frontend: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
uvhs_frontend: UVHS_REQUIRED_DCP_MODULES = blk_mem_gen_0 AXI_bridge data_bridge vio_0 xdma_ep uvw_axi4_to_ddr4
uvhs_frontend: UVHS_BLACKBOX_JTAG_DDR_SUBSYS = 0
uvhs_frontend: UVHS_DDR_RTL_INST = $(UVHS_UVW_AXI4_TO_DDR4_RTL_INST)
uvhs_frontend: UVHS_OPTION_MEM_REFNAME =
uvhs_frontend: UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP = 1
uvhs_frontend: UVHS_SKIP_VIVADO_EXPORT = jtag_ddr_subsys
uvhs_frontend: UVHS_FRONTEND_TCL = $(ROOT_DIR)/uvhs/frontend_run_uvhs.tcl
uvhs_frontend: UVHS_MEM_ARRAY_DC = none
uvhs_frontend: UVHS_AUX_DDR_DC = none
uvhs_frontend: UVHS_ASSEMBLE_FILE = $(ROOT_DIR)/uvhs/assemble_uvhs.tcl
uvhs_frontend: uvhs_export_vivado_ip uvhs_sync_uvw_axi4_to_ddr4 uvhs_filelist uvhs_check_modules
	bash -lc 'set -o pipefail; source "$(ROOT_DIR)/uvhs/setenv.sh" && cd "$(UVHS_WORK_DIR)" && $(UVHS_HEJIAN_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_FILELIST="./rtl/filelist.f" UVHS_REQUIRED_DCP_MODULES="$(UVHS_REQUIRED_DCP_MODULES)" UVHS_BLACKBOX_JTAG_DDR_SUBSYS="$(UVHS_BLACKBOX_JTAG_DDR_SUBSYS)" UVHS_DDR_RTL_INST="$(UVHS_DDR_RTL_INST)" UVHS_OPTION_MEM_REFNAME="$(UVHS_OPTION_MEM_REFNAME)" UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP="$(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_EFFECTIVE)" UVHS_CPU_CLK_PERIOD_NS="$(UVHS_CPU_CLK_PERIOD_NS)" UVHS_CPU_LIVENESS_GBD="$(UVHS_CPU_LIVENESS_GBD)" UVHS_SKIP_BOARD_CONSTRAINTS="$(UVHS_SKIP_BOARD_CONSTRAINTS)" UVHS_PROBE_FILE="$(UVHS_PROBE_FILE)" UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_TIMING_FILE="$(UVHS_TIMING_FILE)" UVHS_PARTITION_FILE="$(UVHS_PARTITION_FILE)" UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" UVHS_MEM_ARRAY_DC="$(UVHS_MEM_ARRAY_DC)" UVHS_MEM_ARRAY_INST="$(UVHS_MEM_ARRAY_INST)" UVHS_MEM_ARRAY_CONNECTOR="$(UVHS_MEM_ARRAY_CONNECTOR)" UVHS_AUX_DDR_DC="$(UVHS_AUX_DDR_DC)" UVHS_AUX_DDR_INST="$(UVHS_AUX_DDR_INST)" UVHS_AUX_DDR_CONNECTOR="$(UVHS_AUX_DDR_CONNECTOR)" UVHS_AUX_DDR_SWAP_BASE_CONNECTOR="$(UVHS_AUX_DDR_SWAP_BASE_CONNECTOR)" UVHS_USE_LSF="$(UVHS_USE_LSF)" UVHS_FRONTEND_THREADS="$(UVHS_FRONTEND_THREADS)" UVHS_FRONTEND_PROCESSES="$(UVHS_FRONTEND_PROCESSES)" UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check -s "$(UVHS_FRONTEND_TCL)" |& tee frontend_run.log'

uvhs_backend: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
uvhs_backend: UVHS_MEM_ARRAY_DC = none
uvhs_backend: UVHS_AUX_DDR_DC = none
uvhs_backend: UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP = 1
uvhs_backend: UVHS_OPTION_MEM_REFNAME =
uvhs_backend: UVHS_ASSEMBLE_FILE = $(ROOT_DIR)/uvhs/assemble_uvhs.tcl
uvhs_backend:
	bash -lc 'set -o pipefail; source "$(ROOT_DIR)/uvhs/setenv.sh" && cd "$(UVHS_WORK_DIR)" && $(UVHS_HEJIAN_FLOW_ENV) UVHS_TOP="$(UVHS_TOP)" UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP="$(UVHS_UVW_AXI4_TO_DDR4_USE_SET_IP_EFFECTIVE)" UVHS_CPU_CLK_PERIOD_NS="$(UVHS_CPU_CLK_PERIOD_NS)" UVHS_SKIP_BOARD_CONSTRAINTS="$(UVHS_SKIP_BOARD_CONSTRAINTS)" UVHS_ASSIGN_PIN_FILE="$(UVHS_ASSIGN_PIN_FILE)" UVHS_PIN_OVERRIDE_FILE="$(UVHS_PIN_OVERRIDE_FILE)" UVHS_ASSEMBLE_FILE="$(UVHS_ASSEMBLE_FILE)" UVHS_MEM_ARRAY_DC="$(UVHS_MEM_ARRAY_DC)" UVHS_MEM_ARRAY_INST="$(UVHS_MEM_ARRAY_INST)" UVHS_MEM_ARRAY_CONNECTOR="$(UVHS_MEM_ARRAY_CONNECTOR)" UVHS_AUX_DDR_DC="$(UVHS_AUX_DDR_DC)" UVHS_AUX_DDR_INST="$(UVHS_AUX_DDR_INST)" UVHS_AUX_DDR_CONNECTOR="$(UVHS_AUX_DDR_CONNECTOR)" UVHS_AUX_DDR_SWAP_BASE_CONNECTOR="$(UVHS_AUX_DDR_SWAP_BASE_CONNECTOR)" UVHS_STOP_AFTER_PARTITION="$(UVHS_STOP_AFTER_PARTITION)" UVHS_STOP_AFTER_GENSCRIPT="$(UVHS_STOP_AFTER_GENSCRIPT)" UVHS_VIVADO_DEBUG_FILE="$(UVHS_VIVADO_DEBUG_FILE)" UVHS_USE_LSF="$(UVHS_USE_LSF)" UVHS_FPGA_THREADS="$(UVHS_FPGA_THREADS)" UVHS_FPGA_PROCESSES="$(UVHS_FPGA_PROCESSES)" UVHS_STRATEGY_NUM_RETRY="$(UVHS_STRATEGY_NUM_RETRY)" bash "$$UV_ROOT/bin/uv_shell" -bypass_vivado_version_check -s "$(ROOT_DIR)/uvhs/backend_run.tcl" |& tee backend_run.log'

uvhs_all: UVHS_WORK_DIR = $(ENV_SCRIPTS_HOME)/fpga_diff_uvhs_$(CPU)$(if $(strip $(SUFFIX)),-$(strip $(SUFFIX)),)
uvhs_all: uvhs_frontend uvhs_backend

uvhs_vivado_frontend: vivado_frontend

uvhs_vivado_backend: vivado_backend

uvhs_vivado_all: vivado_all

uvhs_clean:
	rm -rf "$(UVHS_WORK_DIR)"

uvhs_env:
	@echo "source $(ROOT_DIR)/uvhs/setenv.sh"

uvhs_hejian_pcie_x4_env:
	@bash -lc 'source "$(ROOT_DIR)/uvhs/setenv.sh" >/dev/null 2>&1 || true; ROOT_DIR="$(ROOT_DIR)" bash "$(ROOT_DIR)/uvhs/hejian_pcie_x4_env.sh" print'

uvhs_hejian_pcie_x4_preflight: UVHS_CPU_CLK_PERIOD_NS = 40
uvhs_hejian_pcie_x4_preflight: UVHS_CPU_DEBUG_CLK = 1
uvhs_hejian_pcie_x4_preflight: UVHS_MEM_ARRAY_DC = none
uvhs_hejian_pcie_x4_preflight: UVHS_AUX_DDR_DC = none
uvhs_hejian_pcie_x4_preflight:
	@bash -lc 'source "$(ROOT_DIR)/uvhs/setenv.sh" >/dev/null 2>&1 || true; $(UVHS_HEJIAN_FLOW_ENV) ROOT_DIR="$(ROOT_DIR)" bash "$(ROOT_DIR)/uvhs/hejian_pcie_x4_env.sh" check'

uvhs_hejian_pcie_x4_nutshell_all: CPU = nutshell
uvhs_hejian_pcie_x4_nutshell_all: XDMA_LINK_WIDTH = X4
uvhs_hejian_pcie_x4_nutshell_all: XDMA_ENABLE_PF0_BAR1 = 1
uvhs_hejian_pcie_x4_nutshell_all: XDMA_AXILITE_MASTER_SCALE = Kilobytes
uvhs_hejian_pcie_x4_nutshell_all: XDMA_AXILITE_MASTER_SIZE = 512
uvhs_hejian_pcie_x4_nutshell_all: XDMA_EXPECTED_VENDOR = 0x10ee
uvhs_hejian_pcie_x4_nutshell_all: XDMA_EXPECTED_DEVICE = 0x9048
uvhs_hejian_pcie_x4_nutshell_all: XDMA_EXPECTED_BAR0_SIZE = 0x80000
uvhs_hejian_pcie_x4_nutshell_all: XDMA_EXPECTED_BAR1_SIZE = 0x10000
uvhs_hejian_pcie_x4_nutshell_all: UVHS_XDMA_EP_DCP = $(UVHS_XDMA_EP_DEFAULT_DCP)
uvhs_hejian_pcie_x4_nutshell_all: UVHS_XDMA_EP_DCP_SHA256 = $(UVHS_XDMA_EP_DEFAULT_DCP_SHA256)
uvhs_hejian_pcie_x4_nutshell_all: UVHS_BASE_ASSEMBLE_FILE = $(UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT)
uvhs_hejian_pcie_x4_nutshell_all: UVHS_BASE_ASSEMBLE_SHA256 = $(UVHS_HEJIAN_X4_BASE_ASSEMBLE_DEFAULT_SHA256)
uvhs_hejian_pcie_x4_nutshell_all: UVHS_DESIGN_NAME = VU19P_X4
uvhs_hejian_pcie_x4_nutshell_all: PLATFORM = U2.2
uvhs_hejian_pcie_x4_nutshell_all: UVHS_TARGET_BOARD = B0
uvhs_hejian_pcie_x4_nutshell_all: UVHS_TARGET_PACK = B0
uvhs_hejian_pcie_x4_nutshell_all: UVHS_TARGET_FPGA = F2
uvhs_hejian_pcie_x4_nutshell_all: UVHS_TARGET_FPGA_LOWER = b0.f2
uvhs_hejian_pcie_x4_nutshell_all: UVHS_FPGA_COUNT = 1
uvhs_hejian_pcie_x4_nutshell_all: UVHS_CPU_CLK_PERIOD_NS = 40
uvhs_hejian_pcie_x4_nutshell_all: UVHS_CPU_DEBUG_CLK = 1
uvhs_hejian_pcie_x4_nutshell_all: UVHS_PNR_STRATEGY = Strategy_uv_high_fanout_explore
uvhs_hejian_pcie_x4_nutshell_all: UVHS_COMPILE_STRATEGY_NUM = 1
uvhs_hejian_pcie_x4_nutshell_all: UVHS_COMPILE_STRATEGY0 = uv_high_fanout_explore
uvhs_hejian_pcie_x4_nutshell_all: UVHS_MEM_ARRAY_DC = none
uvhs_hejian_pcie_x4_nutshell_all: UVHS_AUX_DDR_DC = none
uvhs_hejian_pcie_x4_nutshell_all: UVHS_ASSEMBLE_FILE = $(ROOT_DIR)/uvhs/assemble_uvhs.tcl
uvhs_hejian_pcie_x4_nutshell_all: UVHS_ASSIGN_PIN_FILE = $(ROOT_DIR)/uvhs/assign_pin_nutshell_f2.tcl
uvhs_hejian_pcie_x4_nutshell_all: uvhs_hejian_pcie_x4_preflight uvhs_all

uvhs_preflight:
	test -f "$(UVHS_TARBALL)"
	bash -lc 'source "$(ROOT_DIR)/uvhs/setenv.sh"; command -v uv_shell; command -v csh; test -x "$$UV_XILINX_VIVADO/bin/vivado"; "$$UV_XILINX_VIVADO/bin/vivado" -version | head -1'

uvhs_status:
	bash "$(ROOT_DIR)/uvhs/status.sh" "$(UVHS_WORK_DIR)"

uvhs_check_timing_clean:
	bash -lc 'set -euo pipefail; summary="$(UVHS_BITSTREAM_DIR)/after_xtalk_fix_timing_summary.txt"; if [ ! -f "$$summary" ]; then pnr_root="$(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir"; done_dirs="$$(find "$$pnr_root" -name ".Task_strategy_*.timingclean" -printf "%h\n" 2>/dev/null | sort -u || true)"; if [ -n "$$done_dirs" ]; then summary="$$(printf "%s\n" $$done_dirs | while read -r dir; do test -f "$$dir/bitstream/after_xtalk_fix_timing_summary.txt" && printf "%s\n" "$$dir/bitstream/after_xtalk_fix_timing_summary.txt"; done | head -1)"; fi; fi; if [ ! -f "$$summary" ]; then echo "ERROR: UVHS timing summary not found: $$summary" >&2; summaries="$$(find "$(UVHS_WORK_DIR)/hw.dat/Compile/PnR/$(UVHS_TARGET_PACK)/$(UVHS_TARGET_FPGA)/vivado/Rundir" -path "*/bitstream/after_xtalk_fix_timing_summary.txt" -print 2>/dev/null | sort || true)"; if [ -n "$$summaries" ]; then echo "Available timing summaries:" >&2; printf "  %s\n" $$summaries >&2; fi; exit 1; fi; if grep -q "Timing constraints are not met" "$$summary"; then echo "ERROR: UVHS timing is not clean: $$summary" >&2; sed -n "/^[[:space:]]*WNS(ns)/,+5p" "$$summary" >&2; exit 1; fi; awk '\''/^[[:space:]]*-?[0-9]+[.][0-9]+[[:space:]]+-?[0-9]+[.][0-9]+/ { found=1; if ($$1 < 0 || $$2 < 0) exit 1 } END { exit found ? 0 : 1 }'\'' "$$summary" || { echo "ERROR: UVHS WNS/TNS gate failed: $$summary" >&2; sed -n "/^[[:space:]]*WNS(ns)/,+5p" "$$summary" >&2; exit 1; }; echo "INFO: UVHS timing clean: $$summary"'

uvhs_export_ltx: uvhs_check_timing_clean
	bash -lc 'set -euo pipefail; script="$(ROOT_DIR)/tools/write_debug_probes.tcl"; if [ ! -f "$$script" ]; then echo "INFO: skip optional LTX export; local debug-probe script is absent"; exit 0; fi; bitstream_dir="$(UVHS_RESOLVED_BITSTREAM_DIR)"; test -n "$$bitstream_dir"; test -f "$$bitstream_dir/pnr_routed.dcp"; ltx="$${bitstream_dir}/fpga_top_debug.ltx"; if [ -f "$$ltx" ]; then echo "INFO: UVHS LTX already exists: $$ltx"; exit 0; fi; source "$(ROOT_DIR)/uvhs/setenv.sh"; "$$UV_XILINX_VIVADO/bin/vivado" -mode batch -source "$$script" -tclargs "$$bitstream_dir/pnr_routed.dcp" "$$ltx"'

uvhs_package_bitstream: uvhs_export_ltx
	bash -lc 'set -euo pipefail; bitstream_dir="$(UVHS_RESOLVED_BITSTREAM_DIR)"; test -n "$$bitstream_dir"; test -f "$$bitstream_dir/pnr.bit"; mkdir -p "$(UVHS_BIT_HOME)"; ln -sf "$$bitstream_dir/pnr.bit" "$(UVHS_BIT_HOME)/fpga_top_debug.bit"; if [ -f "$$bitstream_dir/fpga_top_debug.ltx" ]; then ln -sf "$$bitstream_dir/fpga_top_debug.ltx" "$(UVHS_BIT_HOME)/fpga_top_debug.ltx"; fi; echo "FPGA_BIT_HOME=$(UVHS_BIT_HOME)"; echo "FPGA_BITSTREAM_DIR=$$bitstream_dir"'
