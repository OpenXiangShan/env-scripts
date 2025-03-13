PLDM_BUILD_DIR = pldm-build
PLDM_CC_OBJ_DIR = $(abspath $(PLDM_BUILD_DIR)/cc_obj)

AXIS_HOME = $(shell cds_root ixcom)/share/uxe/

PLDM_SIMTOOL = $(shell cds_root xrun)/tools/include
PLDM_IXCOM 	 = $(shell cds_root ixcom)/share/uxe/etc/ixcom

PLDM_CLOCK = clock_gen
PLDM_CLOCK_DEF = $(REPO_PATH)/scripts/$(PLDM_CLOCK).xel
PLDM_CLOCK_SRC = $(REPO_PATH)/$(PLDM_BUILD_DIR)/$(PLDM_CLOCK).sv

PLDM_BUILD_FLAGS += -64 -ua +1xua +sv +ignoreSimVerCheck +xe_alt_xlm -xecompile
PLDM_BUILD_FLAGS += compilerOptions=$(REPO_PATH)/scripts/compilerOptions.qel
PLDM_BUILD_FLAGS += +tb_import_systf+fwrite +tb_import_systf+fflush
PLDM_BUILD_FLAGS += +define+PALLADIUM $(MACRO_FLAGS)
PLDM_BUILD_FLAGS += +dut+$(TB_TOP)
PLDM_BUILD_FLAGS += +dut+$(PLDM_CLOCK) $(PLDM_CLOCK_SRC)
PLDM_BUILD_FLAGS += -v $(AXIS_HOME)/etc/ixcom/IXCclkgen.sv

PLDM_BUILD_FLAGS += +incdir+$(REPO_PATH)/src/build

PLDM_CSRC_DIR  = $(abspath ./src/csrc)
PLDM_CXXFILES  = $(shell find $(VCS_CSRC_DIR) -name "*.cpp")
DPILIB_EMU     = $(PLDM_BUILD_DIR)/libdpi_emu.so
PLDM_CXXFLAGS  = -m64 -c -fPIC -g -std=c++11 -I$(PLDM_IXCOM) -I$(PLDM_SIMTOOL) -I$(PLDM_CSRC_DIR)/include

XMSIM_FLAGS = --xmsim -64 +xcprof -profile -PROFTHREAD
XMSIM_FLAGS += -sv_lib ${DPILIB_EMU}
XMSIM_FLAGS += $(PLDM_EXTRA_ARGS)
XMSIM_FLAGS += --

ifneq ($(FILELIST),)
PLDM_BUILD_FLAGS += -F $(FILELIST)
endif

PLDM_RUN_FLAGS += -64 -R -l run-$$(date +%Y%m%d-%H%M%S).log

$(PLDM_BUILD_DIR):
	mkdir -p $(PLDM_BUILD_DIR)

$(PLDM_CC_OBJ_DIR):
	mkdir -p $(PLDM_CC_OBJ_DIR)

$(PLDM_CLOCK_SRC): $(PLDM_CLOCK_DEF)
	ixclkgen -input $(PLDM_CLOCK_DEF)             \
		-output $(PLDM_CLOCK_SRC)                 \
		-module $(PLDM_CLOCK)                         \
		-hierarchy "$(TB_TOP)."

palladium-build: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC) $(DPILIB_EMU)
	cd $(PLDM_BUILD_DIR) &&	                      \
		ixcom $(PLDM_BUILD_FLAGS)

$(DPILIB_EMU): $(PLDM_CC_OBJ_DIR)
	cd $(PLDM_CC_OBJ_DIR) 					&& \
	$(CC) $(PLDM_CXXFLAGS) $(PLDM_CXXFILES)			&& \
	$(CC) -o $@ -m64 -shared *.o $(PLDM_LD_LIB)

palladium-run: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC)
	cd $(PLDM_BUILD_DIR) &&	                      \
		xeDebug $(XMSIM_FLAGS) -input $(REPO_PATH)/scripts/run.tcl

palladium-debug: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC)
	cd $(PLDM_BUILD_DIR) &&                       \
		xrun $(PLDM_RUN_FLAGS)                    \
		-xedebug -xedebugargs -vcd                \
		-input $(REPO_PATH)/scripts/run_debug.tcl

clean-run: palladium-build palladium-run

palladium-clean:
	rm -rf $(PLDM_BUILD_DIR)
