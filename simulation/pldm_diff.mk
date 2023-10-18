
HWFILES         = -F $(FILELIST)
CFILES          = $(shell find ./src/csrc/ -name "*.cpp") 
CFILES          += $(shell find ./src/build/generated-src/ -name "*.cpp")

PLDM_BUILD_DIR  = pldm_diff-build
DPILIB_EMU      = libdpi_emu.so
SIMULATOR       = xrun
EMU_SIM         = xmsim
SMLT            = $(SIMULATOR)
SIMTOOL_HOME    = $(shell cds_root $(SMLT))
IXCOM_HOME      = $(shell cds_root ixcom)
CHEAD_HOME      = -I$(REPO_PATH)/src/csrc \
                -I$(REPO_PATH)/src/csrc/common \
				-I$(REPO_PATH)/src/csrc/difftest \
				-I$(REPO_PATH)/src/build/generated-src

VLAN_FLAGS     += -64 -sv -incdir ../src -vtimescale 1ns/1ns
VLAN_FLAGS     += +define+DIFFTEST +define+VCS $(MACRO_FLAGS)

PLDM_CLOCK = clock_gen
PLDM_CLOCK_DEF = $(REPO_PATH)/scripts/$(PLDM_CLOCK).xel
PLDM_CLOCK_SRC = $(REPO_PATH)/$(PLDM_BUILD_DIR)/$(PLDM_CLOCK).sv

IXCOM_FLAGS = -clean -64 -ua +sv +iscDelay+tb_top +ignoreSimVerCheck +xe_alt_xlm
IXCOM_FLAGS += -xecompile compilerOptions=$(REPO_PATH)/scripts/compilerOptions.qel
IXCOM_FLAGS += +tb_import_systf+fwrite +tb_import_systf+fflush
IXCOM_FLAGS += +define+DIFFTEST +define+VCS $(MACRO_FLAGS)
IXCOM_FLAGS += +dut+$(TB_TOP)
#IXCOM_FLAGS += +dut+$(PLDM_CLOCK) $(PLDM_CLOCK_SRC)
IXCOM_FLAGS += -v $(AXIS_HOME)/etc/ixcom/IXCclkgen.sv
IXCOM_FLAGS += +iscdisp+Rob +iscdisp+tb_top +iscdisp+WBU +iscdisp+MemRWHelper +rtlCommentPragma +tran_relax -relativeIXCDIR -rtlNameForGenerate
ifneq ($(FILELIST),)
IXCOM_FLAGS += -F $(FILELIST)
endif

PLDM_RUN_FLAGS   = -64 +xcprof -profile -sv_lib ${DPILIB_EMU} 

################################# EMU ######################################
$(PLDM_BUILD_DIR):
	mkdir -p $(PLDM_BUILD_DIR)

$(PLDM_CLOCK_SRC): $(PLDM_CLOCK_DEF)
	ixclkgen -input $(PLDM_CLOCK_DEF)             \
		-output $(PLDM_CLOCK_SRC)                 \
		-module $(PLDM_CLOCK)                     \
		-hierarchy "$(TB_TOP)."

pldm-diff-build: $(PLDM_BUILD_DIR)
	cd $(PLDM_BUILD_DIR) &&	                      \
	vlan $(VLAN_FLAGS) $(HWFILES) -l vlan.log &&  \
	ixcom $(IXCOM_FLAGS) -l ixcom.log

pldm-diff-run: $(PLDM_BUILD_DIR) $(DPILIB_EMU)
	cd $(PLDM_BUILD_DIR) &&	                      \
	if [ -e $(DPILIB_EMU) ]; then rm $(DPILIB_EMU); fi &&  ln -sf ../$(DPILIB_EMU) . && \
	xeDebug --$(EMU_SIM) ${PLDM_RUN_FLAGS} -- -input $(REPO_PATH)/scripts/run.tcl -l run-$$(date +%Y%m%d-%H%M%S).log 

pldm-diff-debug: $(PLDM_BUILD_DIR) $(DPILIB_EMU)
	cd $(PLDM_BUILD_DIR) &&	                      \
	if [ -e $(DPILIB_EMU) ]; then rm $(DPILIB_EMU); fi &&  ln -sf ../$(DPILIB_EMU) . && \
	xeDebug --$(EMU_SIM) ${PLDM_RUN_FLAGS} -- -fsdb -input $(REPO_PATH)/scripts/run_debug.tcl

pldm-diff-clean: 
	rm -rf $(PLDM_BUILD_DIR) \
	rm libdpi_emu.so
	
################################# CTB ######################################
$(DPILIB_EMU) libdpi_emu: $(CFILES)
	$(CC) -m64 -c -fPIC -g -std=c++11  \
		-I${IXCOM_HOME}/share/uxe/etc/ixcom \
		-I${SIMTOOL_HOME}/tools/include \
		${CHEAD_HOME} \
		$(CFILES) 
	$(CC) -o $(DPILIB_EMU) -m64 -shared  *.o
	-rm -rf *.o