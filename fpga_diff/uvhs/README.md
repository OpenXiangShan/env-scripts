# UVHS FPGA-Diff Flow

This directory contains the UVHS build and runtime flow for FPGA-Diff. UVHS
commands use the `uvhs_*` prefix and do not replace the existing Vivado, PCIe,
or JTAG commands.

## RTL Input

Generate an FPGA release before entering `env-scripts`. `CORE_DIR` is the
release `build` directory, not the design source checkout:

```text
design RTL -> difftest fpga-release -> <release>/build -> env-scripts
```

The release step owns FPGA clock-gate replacement and generated RAM-style
conversion. The UVHS flow only consumes that result.

`RTL_INCLUDE` accepts RTL files, directories, and nested `.f`, `.flist`, or
`.list` files. Relative entries are resolved from the file list that contains
them. Both build flows call `tools/generate_rtl_filelist.sh`, which uses
`tools/rtl_filelist_lib.sh` for parsing. Vivado mode generates
`cpu_files.tcl`; UVHS mode combines the parsed additions with release RTL and
FPGA-Diff wrappers in `filelist.f`.

| File-list stage | Vivado | UVHS |
| --- | --- | --- |
| Shared input | `CORE_DIR` and optional `RTL_INCLUDE` | `CORE_DIR` and optional `RTL_INCLUDE` |
| Core files | Scans the complete release build, excluding `rtl/verification` | Reads release `rtl/` and optional `generated-src/` headers |
| Board wrappers and IP | Added later by `xs_uart.tcl` from Tcl lists | Written directly into the complete UVHS `filelist.f` |
| Output | Tcl variables in `src/tcl/cpu_files.tcl` | Flat uvsyn input in `<work>/rtl/filelist.f` |
| Consumer | Vivado project creation | UVHS `read_verilog -f` |

## Build

```sh
make uvhs CPU=<design> CORE_DIR=/path/to/release/build \
  RTL_INCLUDE=/path/to/extra.f SUFFIX=<tag>
make uvhs_bitstream CPU=<design> SUFFIX=<tag>
```

`RTL_INCLUDE` is optional. These are the two stable build entry points intended
for an upper-level build system: `uvhs` prepares and synthesizes the UVHS
database, while `uvhs_bitstream` runs backend implementation, checks timing,
and publishes `fpga_top_debug.bit`. The lower-level `uvhs_frontend` and
`uvhs_backend` targets remain available for stage reuse and debugging.

`uvhs_frontend` performs these steps:

1. Copies the vendor board template into an isolated work directory.
2. Prepares repository-owned Vivado IP and the 64-bit generalBus DCP.
3. Imports the selected DDR DCP and validates its AXI width.
4. Builds the complete RTL file list and checks the expected top module.
5. Elaborates and synthesizes the design with uvsyn.
6. Registers the DDR instance used by runtime `writemem`.

`uvhs_backend` follows the vendor implementation sequence: clock inference and
transformation, remap, partition, localization, system routing, FPGA PnR,
timing signoff, bitstream generation, and runtime database commit. Fill-rate
validation and automatic partitioning are kept next to that sequence in
`backend_run.tcl`.

The default XiangShan partition limits are 80% LUT and 30% LUT6. They can be
changed with `UVHS_LUT_FILL_RATE` and `UVHS_LUT6_FILL_RATE` for placement
experiments. `UVHS_EXPORT_IP_FORCE=1` regenerates cached Vivado and generalBus
IP. `uvhs_clean` removes only the selected work directory and refuses to run
while its runtime session is active.

## Runtime

```sh
make uvhs_write_bitstream CPU=<design> SUFFIX=<tag>
make uvhs_runtime_status CPU=<design> SUFFIX=<tag>
make uvhs_halt_soc CPU=<design> SUFFIX=<tag>
make uvhs_write_ddr CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.txt
make uvhs_write_flash CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.bin
make uvhs_reset_cpu CPU=<design> SUFFIX=<tag>
make uvhs_runtime_stop CPU=<design> SUFFIX=<tag>
```

`uvhs_write_bitstream` downloads the completed runtime database, initializes
the hardware, and keeps a detached UVHS session alive. Later reset and memory
commands must use that same session. Its PID, command files, and log are stored
under `runtime-work` in the selected build directory.

`uvhs_write_ddr` converts the Vivado address/data-pair format to the DDR DCP
word width and calls `writemem -rtl`. It leaves the CPU halted until
`uvhs_reset_cpu` is issued.

`uvhs_write_flash` writes through the 64-bit generalBus and the existing
32-bit AXI flash bridge. The generalBus view starts at offset zero; the CPU and
normal JTAG address map are unchanged. A complete readback match is required
before the command succeeds.

## Compatibility Boundary

The retained compatibility code is limited to observed tool behavior:

- `shell_compat.sh` selects Bash in generated synthesis and PnR launchers that
  contain Bash syntax.
- `uv_shell_exec_compat.sh` restores runtime libraries after the vendor launcher
  sanitizes `LD_LIBRARY_PATH`.
- The generalBus export uses a private generator copy and makes its DCP copy
  synchronous so the project is not removed before the copy finishes.
- `vivado_pre_opt.tcl` preserves the XDMA GT reference clock and marks the
  validated XDMA CDC registers.

The flow does not patch generated timing XDC, hierarchy names, VIO/ILA logic,
or DDR pins.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | Build, packaging, and runtime targets. |
| `../tools/generate_rtl_filelist.sh` | Shared Vivado/UVHS RTL file-list entry point. |
| `../tools/rtl_filelist_lib.sh` | Nested file-list parsing and path resolution. |
| `flow_common.tcl` | Shared UVHS path, environment, and source helpers. |
| `frontend_run.tcl` | RTL/IP import, elaboration, and uvsyn frontend. |
| `backend_run.tcl` | Fill-rate setup, partition, routing, PnR, and database commit. |
| `topology.tcl` | Selects the FPGA set from the vendor board assembly. |
| `assign_pin.tcl` | B0/F2 clock, PCIe, UART, JTAG, SD, and control pins. |
| `timing_common.tcl` | External clock constraints. |
| `async_clocks.tcl` | Asynchronous clock groups used by backend and Vivado PnR. |
| `vivado_pre_opt.tcl` | XDMA refclock and CDC constraints. |
| `export_vivado_ip.tcl` | Repository-owned Vivado IP export. |
| `shell_compat.sh` | Generated launcher shell correction. |
| `uv_shell_exec_compat.sh` | Runtime library wrapper. |
| `hw_run_download.tcl` | Download, reset sequencing, and command service. |
| `runtime_command.tcl` | Reset, DDR, and flash operations. |
| `runtime_session.sh` | Runtime lifecycle, command submission, and status. |
