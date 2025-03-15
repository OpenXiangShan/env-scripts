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

BOOST_DIR      = $(abspath ../boost)
VCS_CSRC_DIR  = $(abspath ./src/csrc)
VCS_CXXFILES  = $(shell find $(VCS_CSRC_DIR) -name "*.cpp")
VCS_CXXFLAGS  = -I$(VCS_CSRC_DIR)/include

# VCS_FLAGS += -CFLAGS "$(VCS_CXXFLAGS)"
VCS_CXXFLAGS += -m64 -c -fPIC -g -std=c++14 -static
VCS_FLAGS += +incdir+$(REPO_PATH)/src/build

ifneq ($(FILELIST),)
VCS_FLAGS += -F $(FILELIST)
endif

VCS_CC_OBJ_DIR = $(abspath $(REPO_PATH)/cc_obj)
DPILIB_VCS     = $(REPO_PATH)/libdpi_emu.so

$(VCS_CC_OBJ_DIR):
	mkdir -p $(VCS_CC_OBJ_DIR)

$(DPILIB_VCS): $(VCS_CC_OBJ_DIR)
	cd $(VCS_CC_OBJ_DIR) 					&& \
	g++ $(VCS_CXXFLAGS) $(VCS_CXXFILES)			&& \
	g++ -o $@ -m64 -shared -fPIC *.o -lboost_filesystem

$(VCS_TARGET): $(DPILIB_VCS)
	vcs $(VCS_FLAGS) $(DPILIB_VCS)

vcs-sim: $(VCS_TARGET)

vcs-clean:
	rm -rf $(VCS_TARGET) $(VCS_BUILD_DIR) simv.daidir DVEfiles ucli.key $(DPILIB_VCS) $(VCS_CC_OBJ_DIR)
