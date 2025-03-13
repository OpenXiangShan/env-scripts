VCS_TARGET     = simv
VCS_BUILD_DIR  = simv-compile

VCS_FLAGS += -full64 +v2k -timescale=1ns/1ns -sverilog -debug_access+all +lint=TFIPC-L
VCS_FLAGS += -j200
# Parallel simulation
VCS_FLAGS += -fgp
# DiffTest
# VCS_FLAGS += +define+DIFFTEST
# X prop
# VCS_FLAGS += -xprop
# build files put into $(VCS_BUILD_DIR)
VCS_FLAGS += -Mdir=$(VCS_BUILD_DIR)
VCS_FLAGS += +define+VCS $(MACRO_FLAGS)

VCS_CSRC_DIR  = $(abspath ./src/csrc)
VCS_CXXFILES  = $(shell find $(VCS_CSRC_DIR) -name "*.cpp")
VCS_CXXFLAGS  = -I$(VCS_CSRC_DIR)/include

VCS_FLAGS += -CFLAGS "$(VCS_CXXFLAGS)"
VCS_CXXFLAGS += -std=c++11 -static
VCS_FLAGS += +incdir+$(REPO_PATH)/src/build

ifneq ($(FILELIST),)
VCS_FLAGS += -F $(FILELIST)
endif

$(VCS_TARGET):
	vcs $(VCS_FLAGS) $(VCS_CXXFILES)

vcs-sim: $(VCS_TARGET)

vcs-clean:
	rm -rf $(VCS_TARGET) $(VCS_BUILD_DIR) simv.daidir DVEfiles ucli.key
