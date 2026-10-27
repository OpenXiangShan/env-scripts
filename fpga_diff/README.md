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

Remote XDMA relay
=================

The optional DiffTest XDMA relay lets a compute host run fpga-host and its
reference checkers while another machine owns the physical XDMA endpoint.
Build the companion daemon with make fpga-xdma-relay in DiffTest (no generated
CPU profile required), and install it on the board host. The compute executable
must also include the matching relay implementation.

Add these settings to the existing host_env command on the compute host:

    XDMA_RELAY_BOARD=<xdma-board-ssh-alias>
    XDMA_RELAY_DAEMON=/absolute/board/path/fpga-xdma-relay
    XDMA_RELAY_LISTEN=<compute-ipv4-address>
    XDMA_RELAY_PORT=55273
    XDMA_RELAY_ZSTD=1

Continue to evaluate host_env output and register FPGA_HOST_CLEANUP_CMD as the
exit trap, as shown above. XDMA_RELAY_BOARD selects only the physical XDMA
machine. FPGA_RUNTIME continues to select programming, DDR/ILA control, and
optional UART; these endpoints may be the same machine but are independent.
Use BIND_UART=0 if UART is already captured separately. Both Vivado and UVHS
host_env support the relay; DIFFTEST_HOSTIF must be XDMA.

XDMA_RELAY_LISTEN must be an IPv4 address reachable from the board host.
XDMA_RELAY_PORT is the compute-side listening port. Board-to-compute TCP carries
the data, while SSH starts and supervises the daemon. XDMA_RELAY_DAEMON is an
absolute executable path on the board host. XDMA_RELAY_ZSTD=1 enables optional
C2H compression; its default is raw. SSH uses noninteractive authentication.

Startup checks existing XDMA device users with board-side fuser. Coordinate
board ownership externally as usual; this check is not a hardware lock.
Each invocation creates private random token files on both hosts. The token
travels over SSH stdin, and is never printed or placed in process arguments.
The TCP stream is unencrypted: use a trusted internal network or an independently
secured tunnel. Tokens reject an unrelated relay session.

FPGA_HOST_CLEANUP_CMD stops only this SSH-supervised daemon, removes its token
files, and preserves the existing UART cleanup command. The daemon also exits
when the transport disconnects. Its connection deadline is 120 seconds,
allowing host_env to run before fpga-host starts listening. Diagnostics are in
XDMA_RELAY_LOG until cleanup; copy the log before cleanup if needed. No relay
variables or processes are added when XDMA_RELAY_BOARD is unset.

The standalone tools/xdma_relay_env.sh entrypoint accepts the same variables
and prints sourceable settings without ILA/UART setup. Use it when a caller
already manages the runtime. Existing hardware reset and workload-loading
ordering still applies; this helper does not program or reset the FPGA.
For example, when managing runtime hooks separately, run this on the compute
host (replace the illustrative address and executable path):

    eval "$(XDMA_RELAY_BOARD=fpga \
      XDMA_RELAY_DAEMON=/opt/difftest/fpga-xdma-relay \
      XDMA_RELAY_LISTEN=192.0.2.10 XDMA_RELAY_PORT=55273 \
      bash tools/xdma_relay_env.sh)"
    trap "${FPGA_HOST_CLEANUP_CMD:-:}" EXIT
    /path/to/fpga-host ...
