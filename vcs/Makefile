EMU_VCS := simv

RTL_DIR = $(abspath ./rtl)
VCS_SRC_FILE = $(shell find $(RTL_DIR) -name "*.v")


VCS_TB_DIR = $(abspath ./testbench)
VCS_TB_FILE = $(shell find $(VCS_TB_DIR) -name "*.c") \
              $(shell find $(VCS_TB_DIR) -name "*.v")

VCS_OPTS := -full64 +v2k -timescale=1ns/1ns \
  -LDFLAGS -Wl,--no-as-needed \
  -sverilog \
  -debug_access+all \
  +lint=TFIPC-L \
  +define+RANDOMIZE_GARBAGE_ASSIGN \
  +define+RANDOMIZE_INVALID_ASSIGN \
  +define+RANDOMIZE_MEM_INIT \
  +define+RANDOMIZE_DELAY=0 \
  +define+RANDOMIZE_REG_INIT
 
$(EMU_VCS): $(VCS_SRC_FILE) $(VCS_TB_FILE)
	vcs $(VCS_OPTS) $(VCS_SRC_FILE) $(VCS_TB_FILE)

clean:
	rm -rf simv csrc DVEfiles simv.daidir stack.info.* ucli.key

