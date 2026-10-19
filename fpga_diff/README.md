Core RTL to FPGA Steps
======================

XDMA remains the default DiffTest host interface. For the optional UVHS GBus
path, see [the SRAM C2H interface and build flow](uvhs/README.md).
`DIFFTEST_HOSTIF=GBUS` keeps DiffTest output in the GBS1 on-chip SRAM window
and feeds workload H2C through the existing DifftestMemCtrl AXI-stream engine.
The two interfaces are compile-time exclusive: RTL uses
`` `ifdef DIFFTEST_HOST_GBUS `` / `` `elsif DIFFTEST_HOST_XDMA `` / `` `endif ``.
`Makefile` maps `DIFFTEST_HOSTIF` to one of those defines
(`DIFFTEST_HOST_DEFINE`). The UVHS file list gets that define; the Vivado
project always defines `DIFFTEST_HOST_XDMA` because GBus is UVHS-only.
Host selection is CPU-independent: `core_def` instantiates either the XDMA
endpoint or the GBus host wrapper (`uvhs/common/uvhs_gbus_host_wrapper.sv`), so
the same KMH, NutShell, and Nanhu wrappers serve both modes.

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
  FPGA_BIT_HOME=/path/to/vivado-bitstream
```

For a split-host backend, env-scripts also exposes local `pcie_remove` and
`pcie_rescan` targets. The caller runs them on the XDMA host before and after
`write_bitstream` on the runtime host. Rescan rejects an all-`ff` PCI
configuration read even if stale device nodes still exist.

`PRJ_NAME` is derived from `FPGA_BACKEND`, `CPU`, and `SUFFIX`. A staged UVHS
runtime artifact must be copied to the printed relative destination under this
checkout so the derived project directory contains `hw.dat`.

7. write DDR and run with diff/no-diff
```shell
case 1: No fpga-host
stty -F /dev/ttyUSB0 raw 115200 ...
<New terminal>
make halt_soc
make write_ddr FPGA_BACKEND=vivado
make reset_cpu

case 2: With fpga-host (no-diff mode)
./fpga-host --no-diff

case 3: With fpga-host (diff mode)
./fpga-host --diff <nemu> -i <workload>.bin
```

Clock configuration
===================

- `CPU_CLK_IN` is `clk6_p` (board 200MHz, 5.000ns), declared in
  `vivado/constr/common/cpu_clock.xdc`.
- `DEBUG_CLK_IN` is `clk5_p`. Pick 25MHz (default, `debug_clock_25.xdc`) or
  50MHz (`debug_clock_50.xdc`) with `TIMING_DEBUG_CLK_PERIOD_NS=40.000` /
  `20.000`.
- The CPU/SoC core clock is derived from `clk6_p` by a divider in
  `src/rtl/common/fpga_top_debug.sv`. Set `FPGA_CORE_CLK_MHZ=<n>` to choose the
  running frequency in MHz. `n` must divide 200 evenly and be in `[1, 100]`
  (clk6_p/2 .. clk6_p/200), i.e. 100, 50, 40, 25, 20, 10, 8, 5, 4, 2 or 1.
  200MHz is not reachable because the clock is produced by a register
  divider. The matching `CORE_CLK` generated clock is created by
  `vivado/tcl/common/constraints.tcl` from the same value, and the debounce
  counter in `button_debounce.v` is scaled to the same frequency:

  ```shell
  make bit FPGA_CORE_CLK_MHZ=100 TIMING_DEBUG_CLK_PERIOD_NS=20.000
  ```

  `FPGA_CORE_CLK_100M=1` is kept as a legacy alias for `FPGA_CORE_CLK_MHZ=100`.
  Without either variable `sys_clk_i` runs directly on the debug clock.
- The UART (the AXI bridge that hosts the 16550) always runs on a fixed
  50MHz `clk6_p/4` clock (`bufg_uart_clk`), independent of `FPGA_CORE_CLK_MHZ`
  and of the debug clock, so the console baud rate stays calibrated at 50MHz.

fpga-host environment
=====================

Run `host_env` on the XDMA host immediately before `fpga-host`:

    eval "$(make -s host_env FPGA_BACKEND=uvhs CPU=<design> \
      FPGA_RUNTIME=<user@fpga-runtime> WORKLOAD=/path/to/workload.txt)"
    trap "${FPGA_HOST_CLEANUP_CMD:-:}" 0
    /path/to/fpga-host ...

- Exports ILA arm/upload hooks; upload always follows with `ila_clear`.
- Exports a DDR fallback hook when `WORKLOAD` is set; H2C-enabled hosts ignore it.
- By default, bridges runtime `/dev/ttyUSB0` to a host PTY and exports
  `FPGA_UART_PORT`; it fails if another process is already reading the physical
  UART. Set `BIND_UART=0` to skip it.
- Exports `FPGA_HOST_CLEANUP_CMD` for the caller to release the UART bridge.

`FPGA_RUNTIME` may be an SSH alias or `user@hostname` resolvable from the FPGA
host. UART binding requires `socat` on both machines and `fuser` on the runtime.

`runtime_stop` releases the UVHS runtime session and is a no-op for Vivado, so
callers can invoke the backend-neutral target after `fpga-host` exits.

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

For optional remote XDMA sessions, use the separate relay_host_env target.
See [the relay feature](tools/relay/README.md) for setup and cleanup.
