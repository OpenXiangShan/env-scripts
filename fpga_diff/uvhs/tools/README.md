# UVHS Flow Tools

These helpers support the main UVHS flow. Build and tagged-runtime entry points
remain in the parent `uvhs/` directory.

- `build/`: build-time generated-RTL fixes required by the UVHS integration.

Public Makefile targets in `fpga_diff/Makefile` remain the stable build and
preflight entry points. Local board-debug helpers are intentionally not tracked.
