Core RTL to FPGA Steps
======================

1. modify Makefile.nanhu, assign CORE_DIR

2. make nanhu
  (this step compile a project named xs_nanhu)
  (from this step on, you may use vivado gui)

3. make bitstream
  (start background bitstream gen)

4. wait
  (watch "xs_nanhu/xs_nanhu.runs/xxxx/runme.log")
  (wait for bitstream gen to finish)

5. run wudizzf script 

