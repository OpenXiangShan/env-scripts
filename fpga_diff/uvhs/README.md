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
them. Both build flows call `tools/update_core_flist.sh`, which uses
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
```

`RTL_INCLUDE` is optional. `uvhs` is the stable build entry point: it runs the
frontend and backend in order, generates the per-FPGA bitstreams, and commits
the runtime database. The lower-level `uvhs_frontend` and `uvhs_backend`
targets remain available for stage reuse and debugging. `ENV_SCRIPTS_HOME`
defaults to the current `fpga_diff` directory; it only needs to be overridden
when build outputs should live elsewhere.

`uvhs_frontend` performs these steps:

1. Copies the vendor board template into an isolated work directory.
2. Prepares repository-owned Vivado IP and the 64-bit generalBus DCP.
3. Imports the selected DDR DCP and validates its AXI width.
4. Builds the complete RTL file list and checks the expected top module.
5. Sources an optional `UVHS_PROBE_TCL`, then elaborates and synthesizes the
   design with uvsyn.
6. Registers the DDR instance used by runtime `writemem`.

`uvhs_preflight` is an early prerequisite check, not a synthesis or hardware
test. Its loops check the three required environment variables, host commands,
the selected CPU and release directory, UVHS/Vivado executables, repository
helper scripts, board-template files, and the external DDR directory. This
keeps a missing input from being discovered after a multi-hour run has started.

IP preparation intentionally retains two files. `prepare_ip.sh` is the outer
orchestrator for three different sources: repository Vivado IP, the vendor
Python generalBus generator, and an external DDR checkpoint. The child
`export_vivado_ip.tcl` must run inside Vivado because it uses project, IP, BD,
and checkpoint commands. Merging them would require Vivado to launch a nested
Vivado process or embedding a generated Tcl file in shell, neither of which
simplifies the execution model.

`uvhs_backend` follows the vendor implementation sequence: clock inference and
transformation, remap, partition, localization, system routing, FPGA PnR,
timing signoff, bitstream generation, and runtime database commit. Fill-rate
validation and automatic partitioning are kept next to that sequence in
`compilation/backend_run.tcl`.

`compilation/timing.tcl` supplies the external clocks and asynchronous groups
to the frontend. The groups are applied again after UVHS has inferred and
transformed clocks, then once more to each linked FPGA netlist before Vivado
optimization.

The default XiangShan partition limits are 70% LUT and 35% LUT6. They can be
changed with `UVHS_LUT_FILL_RATE` and `UVHS_LUT6_FILL_RATE` for placement
experiments. `UVHS_EXPORT_IP_FORCE=1` regenerates cached Vivado and generalBus
IP. `uvhs_clean` removes only the selected work directory and refuses to run
while its runtime session is active.

XiangShan leaves all four B0 FPGAs available to the automatic partitioner;
the validated 70/35 result used F2 and F3. NutShell keeps the single F2 FPGA.

## Runtime

```sh
make uvhs_write_bitstream CPU=<design> SUFFIX=<tag>
make uvhs_runtime_status CPU=<design> SUFFIX=<tag>
make uvhs_halt_soc CPU=<design> SUFFIX=<tag>
make uvhs_write_ddr CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.txt
make uvhs_write_flash CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.bin
make uvhs_reset_cpu CPU=<design> SUFFIX=<tag>
make uvhs_capture CPU=<design> SUFFIX=<tag> TRIGGER=/path/to/trigger.ini
make uvhs_runtime_stop CPU=<design> SUFFIX=<tag>
```

`uvhs_write_bitstream` downloads the completed runtime database, initializes
the hardware, and keeps a detached UVHS session alive. Later reset and memory
commands must use that same session. Its PID, command files, and log are stored
under `runtime-work` in the selected build directory. The session has no idle
timeout; use `uvhs_runtime_stop` after testing to release it cleanly.
After the session stops, the released FPGA reports link down; loading the same
database and calling `initialize` without `download` fails. Start the next
runtime session with `uvhs_write_bitstream` so it reloads and downloads
`hw.dat`.

`uvhs_write_ddr` converts the Vivado address/data-pair format to the DDR DCP
word width and calls `writemem -rtl`. It leaves the CPU halted until
`uvhs_reset_cpu` is issued.

`uvhs_write_flash` writes through the 64-bit generalBus and the existing
32-bit AXI flash bridge. The generalBus view starts at offset zero; the CPU and
normal JTAG address map are unchanged. A complete readback match is required
before the command succeeds.

The runtime implementation has two control layers:

- `runtime_server.tcl` is loaded once by the `uv_shell` process that owns the
  downloaded database. It implements reset, DDR, flash, waveform capture, and
  a small command-file service. Hardware operations therefore remain in the
  same UVHS process for the whole board session.
- `runtime_session.sh` runs outside UVHS. `start` detaches `uv_shell` and waits
  for its ready marker; `check` verifies the process and, when requested, its
  ready marker; `enqueue` writes one Tcl argument list atomically and waits for
  its result; and `wait` removes session state after the server handles `stop`.
  The one-argument `check` also protects `uvhs_clean`. It contains no board
  commands.

The old `runtime_command.tcl` layer was merged into the server. It previously
redeclared all memory helpers on every command and depended on reset procedures
from the server's global Tcl scope.

## UVHS Waveform Capture

The reference probe scripts describe compile-time instrumentation, not a
runtime dump. A probe file contains `probe_net` signals to sample and
`trigger_net` signals that may participate in a trigger condition:

```tcl
probe_net -clock fpga_top_debug.core_def.inter_soc_clk -add {
    fpga_top_debug.core_def.cpu_rstn_io
    fpga_top_debug.core_def.difftest_startup_ready_pcie
}
trigger_net -add -group boot -clock \
    fpga_top_debug.core_def.inter_soc_clk -signal {
    fpga_top_debug.core_def.cpu_rstn_io
}
```

Signal hierarchy must match the selected generated RTL. Build a new database
and bitstream with the file supplied explicitly:

```sh
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=probe \
  UVHS_PROBE_TCL=/path/to/probe.tcl
```

The frontend records the probe and trigger declarations. The backend already
runs `trigger_probe -check` after runtime-data initialization and
`trigger_probe -group` after clock transformation, which inserts and groups the
debug hardware before partitioning.

At runtime, write a trigger condition file using the group and signal names
reported by `query -trigger`:

```ini
[boot]
LOGIC = OR
fpga_top_debug.core_def.cpu_rstn_io = 1

[UHD_FINAL_CONDITIONS_LOGIC]
LOGIC = OR
boot
```

After `uvhs_write_bitstream`, `uvhs_capture` checks the condition file, enables
capture and trigger logic, resets the CPU, waits for the trigger, uploads the
UHD data, and reconstructs the waveform. It creates both files below the
selected build directory:

```text
runtime-work/UHD/uvhs_capture/UvData.usdb
runtime-work/UHD/uvhs_capture/UvData.vcd
```

The USDB-to-VCD step is equivalent to:

```sh
USDB=/path/to/UvData.usdb
$UV_ROOT/uvd/uvs/bin/usdb2vcd \
  -i "$USDB" -o "${USDB%.usdb}.vcd"
```

`UVHS_CAPTURE_TIMEOUT` defaults to 60 seconds and `UVHS_CAPTURE_DEPTH` to one
million samples. This is the UVHS UHD path; the normal Vivado flow continues to
use `make dump_ila` and a `.ltx` file.

## Compatibility Boundary

The retained compatibility code is limited to observed tool behavior:

- `shell_compat.sh` selects Bash in generated synthesis and PnR launchers that
  contain Bash syntax.
- `uv_shell_exec_compat.sh` prepares the required libffi/libpcre compatibility
  links and restores runtime libraries after the vendor launcher sanitizes
  `LD_LIBRARY_PATH`.
- The generalBus export uses a private generator copy and makes its DCP copy
  synchronous so the project is not removed before the copy finishes.
- `vivado_pre_opt.tcl` preserves the XDMA GT reference clock and marks the
  validated XDMA CDC registers.

The flow does not patch generated timing XDC, hierarchy names, VIO/ILA logic,
or DDR pins.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | Build and runtime target wiring. |
| `../tools/update_core_flist.sh` | Shared Vivado/UVHS RTL file-list entry point. |
| `../tools/rtl_filelist_lib.sh` | Nested file-list parsing and path resolution. |
| `compilation/flow_common.tcl` | Shared UVHS path, environment, and source helpers. |
| `compilation/frontend_run.tcl` | RTL/IP import, elaboration, and uvsyn frontend. |
| `compilation/backend_run.tcl` | Fill-rate setup, partition, routing, PnR, and database commit. |
| `compilation/topology.tcl` | Selects the FPGA set from the vendor board assembly. |
| `compilation/assign_pin.tcl` | B0/F2 clock, PCIe, UART, JTAG, SD, and control pins. |
| `compilation/timing.tcl` | External clock constraints registered by the frontend. |
| `compilation/async_clocks.tcl` | Shared asynchronous groups for frontend, backend, and PnR. |
| `compilation/vivado_pre_opt.tcl` | XDMA refclock and CDC constraints. |
| `compilation/prepare_ip.sh` | Coordinates Vivado, generalBus, and external DDR IP preparation. |
| `compilation/export_vivado_ip.tcl` | Runs repository-owned XCI/BD exports inside Vivado. |
| `compilation/shell_compat.sh` | Generated launcher shell correction. |
| `runtime/uv_shell_exec_compat.sh` | Runtime library wrapper used by build and runtime shells. |
| `runtime/runtime_server.tcl` | Download, reset, DDR, flash, capture, and command service. |
| `runtime/runtime_session.sh` | Process lifecycle and atomic command/result transport. |
