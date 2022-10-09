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

ifneq ($(FILELIST),)
VCS_FLAGS += -F $(FILELIST)
endif

$(VCS_TARGET):
	vcs $(VCS_FLAGS)

vcs-sim: $(VCS_TARGET)

vcs-clean:
	rm -rf $(VCS_TARGET) $(VCS_BUILD_DIR) simv.daidir DVEfiles ucli.key
