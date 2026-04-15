Core RTL to FPGA Steps
======================

1. modify Makefile, assign CORE_DIR

2. make vivado CPU=XXX
  (this step compile a project,CPU Parameter support "kmh" "nutshell" "nanhu")
  (from this step on, you may use vivado gui)

3. make bitstream
  (start background bitstream gen)

4. wait
  (watch "fpga_$cpu/$cpu$.runs/xxxx/runme.log")
  (wait for bitstream gen to finish)

5. (first) Add file execution permission
  chmod u+x tools/pcie-remove.sh
  chmod u+x tools/pcie-rescan.sh

6. make write_bitstream

7. write DDR and run with diff/no-diff
```shell
case 1: No fpga-host
stty -F /dev/ttyUSB0 raw 115200 ...
<New terminal>
make halt_soc
make write_jtag_ddr
make reset_cpu

case 2: With fpga-host (no-diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_jtag_ddr \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --no-diff

case 3: With fpga-host (diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_jtag_ddr \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --diff <nemu> -i <workload>.bin
```


