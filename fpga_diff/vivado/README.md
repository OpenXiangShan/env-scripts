# Legacy Vivado Helpers

This directory contains the non-UVHS project-generation entry points for the
standalone Vivado flow:

- `xs_uart.tcl`: recreate the CPU-specific Vivado project.
- `gen_synth.tcl`: launch and wait for `synth_1`.
- `gen_bitstream.tcl`: launch and wait for `impl_1` through bitstream write.
- `generate_reports.sh` and `generate_reports.tcl`: collect reports from a
  generated Vivado project.

The root `fpga_diff/Makefile` keeps the historical `vivado`, `synth`, and
`bitstream` targets, but now invokes these files from this directory. Shared
RTL, constraints, AXI/IP Tcl, and board-control helpers remain in their
existing locations because the UVHS flow uses them for source provenance and
signoff checks.

Do not use these helpers for Hejian board programming or UVHS DDR workload
loading. Use `uvhs/Makefile`, `user_script/`, and `uvhs/uvhs_tagged_runtime.sh`
for that flow.
