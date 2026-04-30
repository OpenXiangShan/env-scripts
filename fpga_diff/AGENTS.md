# FpgaDiff Agent Guidelines

Before doing anything FPGA-related, read the [README](README.md).

## FPGA Board Occupancy

The VU19P board is shared across users. Any FPGA operation that touches the board MUST go through the occupancy script to avoid conflicts.

Script: [`tools/fpga_usage.sh`](tools/fpga_usage.sh)

### Usage

```sh
# Check current board status
./tools/fpga_usage.sh status

# Acquire lock before FPGA work
./tools/fpga_usage.sh acquire "reason for locking"

# Release lock after FPGA work
./tools/fpga_usage.sh release

# Run a command with automatic lock/unlock
./tools/fpga_usage.sh with-lock "reason" <command> [args...]
```

### Board-touching targets

The following targets in `Makefile` touch the FPGA board directly. Before calling them, ensure the lock is acquired (either manually or via `with-lock`):

| Target | What it does |
|--------|--------------|
| `write_bitstream` | Programs bitstream via PCIe, resets DDR and CPU |
| `halt_soc` | Halts the FPGA SoC via JTAG |
| `write_jtag_ddr` | Writes workload to DDR via JTAG |
| `reset_cpu` | Resets CPU via JTAG |
| `dump_ila` | Dumps ILA data via JTAG |

### Rules

1. **Before** any FPGA operation, check status and acquire the lock with a descriptive reason.
2. **After** work completes, release the lock.
3. Prefer `with-lock` for operations that should auto-release on exit.
4. If the board is already in use by another user, do NOT proceed — report the conflict.
