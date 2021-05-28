EMU_VCS := simv

RTL_DIR = $(abspath ./rtl)
LIB_DIR = $(abspath ./nanshan_sram_317)
VCS_SRC_FILE = $(shell find $(RTL_DIR) -name "*.v")

VCS_TB_DIR = $(abspath ./testbench)
VCS_TB_FILE = $(shell find $(VCS_TB_DIR) -name "*.c") \
              $(shell find $(VCS_TB_DIR) -name "*.v")
VCS_OTHER_FILE = $(shell find $(VCS_TB_DIR) -name "*.h")

VCS_OPTS := -full64 +v2k -timescale=1ns/1ns \
  -LDFLAGS -Wl,--no-as-needed \
  -j200 -sverilog \
  -debug_access+all \
  +lint=TFIPC-L \
  +define+UNIT_DELAY \
  +define+no_warning \
  -f nanshan.f \
  -f sram.f

$(EMU_VCS): $(VCS_SRC_FILE) $(VCS_TB_FILE) $(VCS_OTHER_FILE)
	export RTL_PATH=$(RTL_DIR) && export LIB_PATH=$(LIB_DIR) && export LIB_PREFIX="tt1v25c.v" && vcs $(VCS_OPTS) $(VCS_TB_FILE)

clean:
	rm -rf simv csrc DVEfiles simv.daidir stack.info.* ucli.key

