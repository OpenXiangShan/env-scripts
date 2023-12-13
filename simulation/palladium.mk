PLDM_BUILD_DIR = pldm-build

AXIS_HOME = /nfs/tools/Cadence/IXCOM22.04.s003/share/vxe

PLDM_CLOCK = clock_gen
PLDM_CLOCK_DEF = $(REPO_PATH)/scripts/$(PLDM_CLOCK).xel
PLDM_CLOCK_SRC = $(REPO_PATH)/$(PLDM_BUILD_DIR)/$(PLDM_CLOCK).sv

PLDM_BUILD_FLAGS += -clean
PLDM_BUILD_FLAGS += -64 -ua +1xua +sv +ignoreSimVerCheck +xe_alt_xlm
PLDM_BUILD_FLAGS += -xecompile compilerOptions=$(REPO_PATH)/scripts/compilerOptions.qel
PLDM_BUILD_FLAGS += +tb_import_systf+fwrite +tb_import_systf+fflush
#PLDM_BUILD_FLAGS += +define+PALLADIUM +define+SYNTHESIS $(MACRO_FLAGS)
PLDM_BUILD_FLAGS += +define+PALLADIUM +define+SYNTHESIS $(MACRO_FLAGS)
PLDM_BUILD_FLAGS += +dut+$(TB_TOP)
PLDM_BUILD_FLAGS += +dut+$(PLDM_CLOCK) $(PLDM_CLOCK_SRC)
PLDM_BUILD_FLAGS += -v $(AXIS_HOME)/etc/ixcom/IXCclkgen.sv
PLDM_BUILD_FLAGS += +iscdisp+Rob +iscdisp+tb_top +iscdisp+WBU +iscdisp+MemRWHelper

ifneq ($(FILELIST),)
PLDM_BUILD_FLAGS += -F $(FILELIST)
endif

PLDM_RUN_FLAGS += -64 -R -l run-$$(date +%Y%m%d-%H%M%S).log

$(PLDM_BUILD_DIR):
	mkdir -p $(PLDM_BUILD_DIR)

$(PLDM_CLOCK_SRC): $(PLDM_CLOCK_DEF)
	ixclkgen -input $(PLDM_CLOCK_DEF)             \
		-output $(PLDM_CLOCK_SRC)                 \
		-module $(PLDM_CLOCK)                         \
		-hierarchy "$(TB_TOP)."

un_gzzip:
	gzip -d images/gcpt.gz && ln images/gcpt images/ram.bin

palladium-build: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC)
	cd $(PLDM_BUILD_DIR) &&	                      \
		ixcom $(PLDM_BUILD_FLAGS)

palladium-build-gcpt: 
	make un_gzzip
	make palladium-build

palladium-run: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC)
	cd $(PLDM_BUILD_DIR) &&	                      \
		xeDebug -input $(REPO_PATH)/scripts/run.tcl

palladium-debug: $(PLDM_BUILD_DIR) $(PLDM_CLOCK_SRC)
	cd $(PLDM_BUILD_DIR) &&                       \
		xeDebug -gui $(PLDM_RUN_FLAGS)                    \
		-xedebugargs -fsdb                \
		-input $(REPO_PATH)/scripts/run_debug.tcl

clean-run: palladium-build palladium-run

palladium-clean:
	rm -rf $(PLDM_BUILD_DIR)
