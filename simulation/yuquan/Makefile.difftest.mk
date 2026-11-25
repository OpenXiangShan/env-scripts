# YuQuan memory-controller backend for difftest.

YUQUAN_ADAPTER_HOME ?= $(abspath $(DESIGN_DIR)/env-scripts/simulation/yuquan)
YUQUAN_RTL_DIR ?= $(abspath $(DESIGN_DIR)/scripts/yuquan/rtl)
ifeq ($(WITH_EXTERNAL_MEMORY_BACKEND),1)
ifeq ($(wildcard $(YUQUAN_RTL_DIR)/ddr_wrapper_yuquan.sv),)
$(error YUQUAN_RTL_DIR is invalid: $(YUQUAN_RTL_DIR))
endif
YUQUAN_HOME ?= $(abspath $(DESIGN_DIR)/YuQuan)
YUQUAN_BUILD_DIR = $(YUQUAN_HOME)/build
YUQUAN_VSRC = $(shell find $(YUQUAN_BUILD_DIR) \( -name "*.v" -o -name "*.sv" \) 2> /dev/null)
ifeq ($(wildcard $(YUQUAN_HOME)/Makefile),)
$(error YUQUAN_HOME is invalid: $(YUQUAN_HOME))
endif
ifeq ($(wildcard $(YUQUAN_BUILD_DIR)/mc_top.sv)$(wildcard $(YUQUAN_BUILD_DIR)/BY_mc_top.sv),)
$(error YuQuan generated RTL is missing. Run: make -C $(YUQUAN_HOME) verilog)
endif
SIM_VSRC += $(YUQUAN_RTL_DIR)/yuquan_axi_async_bridge.sv $(YUQUAN_RTL_DIR)/ddr_wrapper_yuquan.sv $(YUQUAN_VSRC)
SIM_CXXFLAGS += -DYUQUAN_DFI_CHANNELS=2 -DYUQUAN
YUQUAN_ADDRESS_MAPPING ?= $(YUQUAN_ADAPTER_HOME)/config/address_mapping_yuquan_dual.ini
SIM_VFLAGS += -I$(YUQUAN_RTL_DIR) -I$(YUQUAN_BUILD_DIR)
YUQUAN_DFI_CSRC_DIR = $(YUQUAN_ADAPTER_HOME)/src/dfi
SIM_CXXFILES += $(shell find $(YUQUAN_DFI_CSRC_DIR) -name "*.cpp")
SIM_CXXFLAGS += -DWITH_EXTERNAL_MEMORY_BACKEND -I$(YUQUAN_ADAPTER_HOME)/include
SIM_CXXFLAGS += -DYUQUAN_ADDRESS_MAPPING=\\\"$(YUQUAN_ADDRESS_MAPPING)\\\"
DIFFTEST_FIRST_COMMIT_LIMIT ?= 2000000ULL
SIM_VFLAGS += -Wno-PINMISSING -Wno-IMPLICIT -Wno-WIDTHCONCAT -Wno-UNOPTFLAT
endif
