# Remote XDMA relay

The optional DiffTest XDMA relay lets a compute host run fpga-host and its
reference checkers while another machine owns the physical XDMA endpoint.
Build the companion daemon with make fpga-xdma-relay in DiffTest (no generated
CPU profile required), and install it on the board host. The compute executable
must also include the matching relay implementation.

Use the separate `relay_host_env` target on the compute host. Only
`XDMA_RELAY_BOARD` is required; the other settings have these defaults and can
be overridden through environment variables:

    XDMA_RELAY_BOARD=<xdma-board-ssh-alias>
    XDMA_RELAY_DAEMON=fpga-xdma-relay
    XDMA_RELAY_LISTEN=  # derive the compute IPv4 address from SSH
    XDMA_RELAY_PORT=55273
    XDMA_RELAY_ZSTD=1

Evaluate relay_host_env output and register FPGA_HOST_CLEANUP_CMD as the
exit trap, as shown below. XDMA_RELAY_BOARD selects only the physical XDMA
machine. FPGA_RUNTIME continues to select programming, DDR/ILA control, and
optional UART; these endpoints may be the same machine but are independent.
Use BIND_UART=0 if UART is already captured separately. Both Vivado and UVHS
relay_host_env support the relay; DIFFTEST_HOSTIF must be XDMA.

By default both hosts use the compute IPv4 address reported by the board's
`SSH_CONNECTION`. Set `XDMA_RELAY_LISTEN` to a reachable compute IPv4 address
when using a jump host.
XDMA_RELAY_PORT is the compute-side listening port. Board-to-compute TCP carries
the data, while SSH starts and supervises the daemon. XDMA_RELAY_DAEMON is found
in the board host's PATH, or accepts an explicit executable path.
C2H compression is enabled by default; set XDMA_RELAY_ZSTD=0 for raw data.
SSH uses noninteractive authentication.

Startup checks existing XDMA device users with board-side fuser. Coordinate
board ownership externally as usual; this check is not a hardware lock.
Each invocation creates private random token files on both hosts. The token
travels over SSH stdin, and is never printed or placed in process arguments.
The TCP stream is unencrypted: use a trusted internal network or an independently
secured tunnel. Tokens reject an unrelated relay session.

FPGA_HOST_CLEANUP_CMD stops only this SSH-supervised daemon, removes its token
files, and preserves the existing UART cleanup command. The daemon also exits
when the transport disconnects. Its connection deadline is 120 seconds,
allowing relay_host_env to run before fpga-host starts listening. Diagnostics
are in XDMA_RELAY_LOG until cleanup; copy the log before cleanup if needed.
The existing host_env target never starts a relay, even when relay variables
are set. Select this feature explicitly through relay_host_env or the script.

The standalone tools/relay/host_env.sh entrypoint accepts the same variables
and prints sourceable settings without ILA/UART setup. Use it when a caller
already manages the runtime. Existing hardware reset and workload-loading
ordering still applies; this helper does not program or reset the FPGA.
For example, when managing runtime hooks separately, run this on the compute
host (replace the illustrative address and executable path):

    eval "$(XDMA_RELAY_BOARD=fpga \
      XDMA_RELAY_DAEMON=/opt/difftest/fpga-xdma-relay \
      XDMA_RELAY_LISTEN=192.0.2.10 XDMA_RELAY_PORT=55273 \
      bash tools/relay/host_env.sh)"
    trap "${FPGA_HOST_CLEANUP_CMD:-:}" EXIT
    /path/to/fpga-host ...

## Integration boundary

`relay.mk`, `host_env.sh` and this document contain the complete relay feature.
The main FPGA Makefile only includes `tools/relay/relay.mk`. The `relay_host_env` target
wraps the existing backend-neutral `host_env` target and composes its cleanup
hook. Vivado/UVHS targets and their UART, ILA and DDR setup do not depend on
relay. `XDMA_RELAY_BOARD` is required for the explicit relay target.

For combined runtime and relay setup, run from `fpga_diff`:

    eval "$(make -s relay_host_env FPGA_BACKEND=uvhs CPU=boom BIND_UART=0 \
      XDMA_RELAY_BOARD=fpga XDMA_RELAY_DAEMON=/opt/difftest/fpga-xdma-relay \
      XDMA_RELAY_LISTEN=192.0.2.10 XDMA_RELAY_PORT=55273)"
    trap "${FPGA_HOST_CLEANUP_CMD:-:}" EXIT
    /path/to/fpga-host ...
