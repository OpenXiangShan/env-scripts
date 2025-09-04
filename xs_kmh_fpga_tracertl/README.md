Core RTL to FPGA Steps
======================

1. modify Makefile.kmh, assign CORE_DIR

2. make kmh
  (this step compile a project named xs_kmh)
  (from this step on, you may use vivado gui)

3. make bitstream
  (start background bitstream gen)

4. wait
  (watch "xs_kmh/xs_kmh.runs/xxxx/runme.log")
  (wait for bitstream gen to finish)

5. run wudizzf script 

