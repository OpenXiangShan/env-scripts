Core RTL to FPGA Steps
======================

The legacy standalone Vivado project-generation entry points are grouped under
[`vivado/`](vivado/). The UVHS flow remains under [`uvhs/`](uvhs/); its shared
SoC RTL, constraints, CDC reports, and runtime scripts stay at their existing
paths.

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

HJ/UVHS FPGA Flow
=================

The Hejian NutShell source-flow index is [uvhs/README.md](uvhs/README.md);
the canonical build, signoff, runtime, FPGA-host, and cleanup runbook is
[uvhs/flow.md](uvhs/flow.md).

A typical build starts with:

```shell
make uvhs_tools_check
make uvhs_hejian_pcie_x4_preflight CORE_DIR=/path/to/NutShell
make uvhs_hejian_pcie_x4_nutshell_all \
  CORE_DIR=/path/to/NutShell SUFFIX=<unique-tag>
make uvhs_package_bitstream CPU=nutshell \
  UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_nutshell-<unique-tag>
```

Copy `uvhs/setenv.local.example.sh` to the ignored `setenv.local.sh` for
machine-specific tools and licenses. The caller supplies `CORE_DIR`, verified
UVHS DDR/XDMA IP assets, and a unique build suffix. Program the resulting
`hw.dat` through the vendor runtime using `user_script/hw_run_download.tcl`.
The normal `fpga-host` path loads workloads through H2C. Use
`uvhs_tagged_runtime.sh` so runtime sessions and cleanup remain exact-tag
scoped; keep board-specific debug helpers local.
