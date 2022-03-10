EMU_VCS := simv

VCS_SRC_DIR  = $(abspath ./xs_nh_release/rtl/XSTop)
VCS_SRC_FILE = $(shell find $(VCS_SRC_DIR) -name "*.v")

VCS_TB_DIR   = $(abspath ./testbench)
VCS_TB_FILE  = $(shell find $(VCS_TB_DIR) -name "*.c") \
               $(shell find $(VCS_TB_DIR) -name "*.v")

VCS_OTHER_FILE = $(shell find $(VCS_TB_DIR) -name "*.h")

VCS_OPTS := -full64 +v2k -timescale=1ns/1ns \
  -LDFLAGS -Wl,--no-as-needed               \
  -j200 -sverilog +error+1                  \
  -debug_access+all                         \
  +lint=TFIPC-L                             \
  +define+UNIT_DELAY                        \
  +define+no_warning                        \
  +define+SYNTHESIS                         \
  +define+SNPS_FAST_SIM_FFV                 \
  +vcs+initreg+random                       \
  -F xs_nh_release/flist_emu.f

$(EMU_VCS): $(VCS_SRC_FILE) $(VCS_TB_FILE) $(VCS_OTHER_FILE)
	vcs $(VCS_OPTS) $(VCS_TB_FILE)

clean:
	rm -rf simv csrc DVEfiles simv.daidir stack.info.* ucli.key
