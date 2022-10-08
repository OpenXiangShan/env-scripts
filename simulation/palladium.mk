PLDM_BUILD_DIR = pldm-build

AXIS_HOME = /opt/CDNS_tools/VXE185_ISR11/share/vxe

# CXX_SRCS = $(abspath $(shell find ./src/csrc -name "*.c"))
# CXX_SRCS += $(abspath $(shell find ./src/csrc -name "*.cpp"))
# INC_HEADER = $(abspath $(shell find ./src/csrc -name "*.h"))
# LIBS = $(abspath $(shell find ./src/libs -name "*.so"))

# VSRCS = $(abspath $(shell find ./src/vsrc -name "*.v"))

PLDM_BUILD_FLAGS += -64 +1xua -ua +sv +ignoreSimVerCheck
PLDM_BUILD_FLAGS += -xecompile compilerOptions=$(REPO_PATH)/scripts/compilerOptions.qel
PLDM_BUILD_FLAGS += -v ${AXIS_HOME}/etc/ixcom/IXCclkgen.sv
# PLDM_BUILD_FLAGS += +tb_import_systf+fopen +tb_import_systf+fread +tb_import_systf+fclose
PLDM_BUILD_FLAGS += +tb_import_systf+fwrite +tb_import_systf+fflush
PLDM_BUILD_FLAGS += +dut+tb_top
PLDM_BUILD_FLAGS += +define+PALLADIUM $(MACRO_FLAGS)

ifneq ($(FILELIST),)
PLDM_BUILD_FLAGS += -F $(FILELIST)
endif

PLDM_RUN_FLAGS   += -64 -R -l run-$$(date +%Y%m%d%H%M%S).log

$(PLDM_BUILD_DIR):
	mkdir -p $(PLDM_BUILD_DIR)

# libtb: ${CXX_SRCS} $(INC_HEADER) ${LIBS}
# 	cd tmp && \
# 	${CXX} -std=c++11 -fPIC -shared -o libtb.so \
# 	-I${AXIS_HOME}/etc/ixcom -I${IES_HOME}/include \
# 	-I../src/csrc/common $^

palladium-build: $(PLDM_BUILD_DIR)
	cd $(PLDM_BUILD_DIR) &&	\
		ixcom $(PLDM_BUILD_FLAGS)

palladium-run: $(PLDM_BUILD_DIR)
	cd $(PLDM_BUILD_DIR) &&	                      \
		xrun $(PLDM_RUN_FLAGS)                    \
		-input $(REPO_PATH)/scripts/run.tcl
# -sv_lib libtb.so

palladium-debug: $(PLDM_BUILD_DIR)
	cd $(PLDM_BUILD_DIR) &&                       \
		xrun $(PLDM_RUN_FLAGS)                    \
		-xedebug -xedebugargs -vcd                \
		-input $(REPO_PATH)/scripts/run_debug.tcl
# -sv_lib libtb.so

clean-run: palladium-build palladium-run

# xdbg: libtb
# 	(cd tmp && xrun -64 -R -xedebug -input ../xdbg.tcl -sv_lib libtb.so)

palladium-clean:
	rm -rf $(PLDM_BUILD_DIR)
