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

6. Program the FPGA. The Vivado backend removes and rescans its local XDMA
endpoint around programming:

```shell
make write_bitstream FPGA_BACKEND=<vivado-or-uvhs> \
  FPGA_BIT_HOME=/path/to/vivado-bitstream \
  FPGA_RUNTIME_HOME=/path/to/uvhs-runtime-artifact
```

For a split-host backend, env-scripts also exposes local `pcie_remove` and
`pcie_rescan` targets. The caller runs them on the XDMA host before and after
`write_bitstream` on the runtime host. Rescan rejects an all-`ff` PCI
configuration read even if stale device nodes still exist.

`PRJ_NAME` is derived from `FPGA_BACKEND`, `CPU`, and `SUFFIX`. For UVHS,
`FPGA_RUNTIME_HOME` optionally points to a copied project directory containing
`hw.dat`; otherwise the derived project directory under this checkout is used.

7. write DDR and run with diff/no-diff
```shell
case 1: No fpga-host
stty -F /dev/ttyUSB0 raw 115200 ...
<New terminal>
make halt_soc
make write_ddr FPGA_BACKEND=vivado
make reset_cpu

case 2: With fpga-host (no-diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_ddr FPGA_BACKEND=vivado \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --no-diff

case 3: With fpga-host (diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_ddr FPGA_BACKEND=vivado \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --diff <nemu> -i <workload>.bin
```

Remote UART for fpga-host
=========================

When `fpga-host` runs on a machine other than the FPGA USB-UART host, bridge
the remote UART to a local pseudo-terminal. `$FPGA_RUNTIME` owns the physical
UART while `$FPGA_HOST` owns XDMA and runs `fpga-host`. Install socat on both
hosts, then start the bridge from `$FPGA_HOST`:

    make bind_uart FPGA_RUNTIME=<user@fpga-runtime>

The target bridges remote /dev/ttyUSB0 at 115200 baud to
/tmp/fpga-remote-uart locally, exports FPGA_UART_PORT, and starts an
interactive shell. Run fpga-host in that shell; leaving it stops the bridge.
Replace the FPGA_RUNTIME placeholder with an SSH target resolvable from
$FPGA_HOST; it may be a configured alias or a user@hostname destination.
The FPGA host must also have a usable key or forwarded SSH agent for that
target.
Override REMOTE_UART_PORT, REMOTE_UART_BAUD, or FPGA_UART_PORT when needed.
For a scripted invocation, obtain the same environment assignment with:

    eval "$(make -s uart_env)"

The bridge is bidirectional, so interactive UART input is also forwarded. It
deliberately uses a /tmp pseudo-terminal rather than overwriting local
/dev/ttyUSB0.

UVHS Flow
=========

The Hejian UVHS flow uses separate `uvhs_*` targets and leaves the targets above
unchanged. Configure the UVHS tool environment in the runtime host shell, then
invoke:

```shell
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=<tag>
```

See [`uvhs/README.md`](uvhs/README.md) for the board-template and vendor-DDR
inputs, build stages, runtime commands, and the XDMA host refresh required for
each runtime download.
