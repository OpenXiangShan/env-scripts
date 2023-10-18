TB_TOP = tb_top
REPO_PATH = $(realpath $(shell pwd))

MACRO_FLAGS =

# Top module
TOP_MODULE ?= SimTop
ifneq ($(TOP_MODULE),)
MACRO_FLAGS += +define+TOP_MODULE=$(TOP_MODULE)
endif

# Verilog filelist
FILELIST ?= $(REPO_PATH)/src/hw.f

# Memory image
MEMORY_IMAGE ?= $(REPO_PATH)/images/ram.bin
ifneq ($(MEMORY_IMAGE),)
MACRO_FLAGS += +define+MEMORY_IMAGE=$(MEMORY_IMAGE)
endif

# Flash image
FLASH_IMAGE ?=
ifneq ($(FLASH_IMAGE),)
MACRO_FLAGS += +define+FLASH_IMAGE=$(FLASH_IMAGE)
endif

# UART simulation
SIM_UART ?= 1
ifeq ($(SIM_UART),1)
MACRO_FLAGS += +define+SIM_UART
endif

# nanhu or Southlake
NANHU ?= 1
ifeq ($(NANHU),1)
MACRO_FLAGS += +define+NANHU
endif

include vcs.mk
include palladium.mk

default: vcs-sim

clean: vcs-clean palladium-clean
