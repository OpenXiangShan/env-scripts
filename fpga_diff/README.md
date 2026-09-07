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

fpga-host environment
=====================

Run `host_env` on the XDMA host immediately before `fpga-host`:

    eval "$(make -s host_env FPGA_BACKEND=uvhs CPU=<design> \
      FPGA_RUNTIME=<user@fpga-runtime> WORKLOAD=/path/to/workload.txt)"
    trap 'eval "${FPGA_HOST_CLEANUP_CMD:-:}"' EXIT
    /path/to/fpga-host ...

- Exports ILA arm/upload hooks; upload always follows with `ila_clear`.
- Exports a DDR fallback hook when `WORKLOAD` is set; H2C-enabled hosts ignore it.
- By default, bridges runtime `/dev/ttyUSB0` to a host PTY and exports
  `FPGA_UART_PORT`; set `BIND_UART=0` to skip it.
- Exports `FPGA_HOST_CLEANUP_CMD` for the caller to release the UART bridge.

`FPGA_RUNTIME` may be an SSH alias or `user@hostname` resolvable from the FPGA
host. UART binding requires `socat` on both machines.

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
