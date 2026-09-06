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
them. `uvhs_project` combines those inputs with the release RTL and FPGA-Diff
wrappers in `<work>/rtl/filelist.f`, which the UVHS frontend reads directly.

## Build

```sh
make uvhs CPU=<design> CORE_DIR=/path/to/release/build \
  RTL_INCLUDE=/path/to/extra.f SUFFIX=<tag>
```

`RTL_INCLUDE` is optional. `uvhs` is the stable build entry point: it runs the
frontend and backend in order, generates the per-FPGA bitstreams, and commits
the runtime database.

`uvhs_project` performs these steps:

1. Copies the vendor board template into an isolated work directory.
2. Prepares repository-owned Vivado IP and the 64-bit generalBus DCP.
3. Imports the selected DDR DCP and validates its AXI width.
4. Builds the complete RTL file list and checks the expected top module.

`uvhs_frontend` then:

1. Sources an optional `UVHS_PROBE_TCL`, then elaborates and synthesizes the
   design with uvsyn.
2. Registers the DDR instance used by runtime `writemem`.

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

The default topology keeps the XiangShan CHI/CMN memory path, configuration
bridge, runtime flash interface, syscfg, and boot ROM with user DDR on B0/F0.
The physical UV_FMCH_FLASH USB-UART remains on B0/F1, while the core, DiffTest
endpoint, and XDMA host path stay on B0/F2. The timer source/sink CDC boundary
also stays with the CPU-side path, while the 65-bit `syscnt` time bus and the
DiffTest clock-enable signal use explicit direct F2-to-F0 routes. This avoids
per-bit TDM skew on the time value. The remaining logic is partitioned
automatically. XiangShan uses these path constraints together with high
partition effort and the `uv_placer_balance_slrs` PnR strategy.

UVHS drives the AXI UART16550 from `clk6_p` at a fixed 50 MHz. The CPU/SoC
`clk5_p` frequency comes from the system sign-off result committed in the
selected runtime database, so each partition and PnR result runs at its own
reported frequency. The fixed UART clock matches the 50 MHz clock declared by
the XiangShan FPGA device tree and keeps UART baud timing independent of CPU
clock gating.

At runtime, `clk5_p` is restored to the sign-off frequency stored in the
selected runtime database. `clk8_p` is then derived at a fixed 50:1 CPU-to-TMCLK
ratio, so a 14 MHz CPU clock uses approximately 280 kHz TMCLK. The optional
`UVHS_TMCLK_CPU_RATIO` environment variable is retained only for controlled
clock-sweep experiments. Update the Linux device-tree `timebase-frequency` to
the derived TMCLK value before treating Linux timestamps as wall-clock time.
The DDR reference `clk7_p` and the DDR IP user clock are not runtime PLL
outputs and remain fixed by the selected DDR DCP.

## Runtime

```sh
make uvhs_write_bitstream CPU=<design> SUFFIX=<tag>
make uvhs_runtime_status CPU=<design> SUFFIX=<tag>
make uvhs_halt_soc CPU=<design> SUFFIX=<tag>
make uvhs_write_ddr CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.txt
make uvhs_write_flash CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.bin
make uvhs_reset_cpu CPU=<design> SUFFIX=<tag>
make uvhs_ila_arm CPU=<design> SUFFIX=<tag> TRIGGER=/path/to/trigger.ini
make uvhs_ila_upload CPU=<design> SUFFIX=<tag>
make uvhs_vcd CPU=<design> SUFFIX=<tag>
make uvhs_ila_clear CPU=<design> SUFFIX=<tag>
make uvhs_runtime_stop CPU=<design> SUFFIX=<tag>
```

`uvhs_write_bitstream` downloads the completed runtime database, initializes
the hardware, and keeps a detached UVHS session alive. Later reset and memory
commands must use that same session. Its PID, command files, and log are stored
under `runtime-work` in the selected build directory. The session has no idle
timeout; use `uvhs_runtime_stop` after testing to release it cleanly.
`uvhs_stage_bitstream` copies `hw.dat` into
`runtime/<derived-project-name>/` inside the bit archive. It prints both the
source artifact and its relative destination under `env-scripts/fpga_diff` so
the runtime checkout can locate it without another path variable.
After the session stops, the released FPGA reports link down; loading the same
database and calling `initialize` without `download` fails. Start the next
runtime session with `uvhs_write_bitstream` so it reloads and downloads
`hw.dat`.

`ila_host_env` exports ILA arm/upload/clear commands and the runtime stop
command. The upload command clears ILA after an upload; the separate clear
command lets the caller clean up an interrupted or non-upload path before it
optionally invokes the stop command.

`$FPGA_RUNTIME` does not control the Linux PCIe endpoint on `$FPGA_HOST`.
Around every runtime download, the caller runs `pcie_remove` on `$FPGA_HOST`,
runs `write_bitstream` on `$FPGA_RUNTIME`, and then runs `pcie_rescan` on
`$FPGA_HOST`. The rescan waits for
`xdma-chr`, prints the endpoint and device nodes, and verifies access; an
installed XDMA udev rule avoids a separate `sudo chmod`.

`uvhs_write_ddr` converts the Vivado address/data-pair format to the DDR DCP
word width and calls `writemem -rtl`. It leaves the CPU halted until
`uvhs_reset_cpu` is issued.

`uvhs_write_flash` locates the compiled generalBus endpoint with
`query -ipinfo -tclobj`, then writes through its 64-bit AXI port and the
existing 32-bit AXI flash bridge. The generalBus view starts at offset zero;
the CPU and normal JTAG address map are unchanged. A complete readback match
is required before the command succeeds. The command holds the CPU while the
boot image changes and releases it after the verified write; callers do not
need a separate `uvhs_halt_soc` command.

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

## UVHS ILA Waveform Capture

The probe scripts describe compile-time instrumentation, not a runtime dump.
For XiangShan/KMH builds, the frontend sources `compilation/probe_kmh.tcl` by
default. CPU and L2 signals are sampled on
`core_def.inter_soc_clk`, the gated clock connected to `SimTop.clock`. DDR and
host-trigger signals remain on their free-running `core_def.sys_clk_i` domain,
so the host trigger remains observable after the CPU clock stops. Its generated
hierarchy must be checked before it is reused with a different XiangShan RTL
revision. The braces preserve hierarchy indexes such as `[0]`.
Other CPU builds continue to use the minimal `compilation/probe_ila.tcl`
profile by default.
Set `UVHS_PROBE_TCL` to select a profile or an external file; an override must
retain the XDMA host trigger if host-controlled capture is required. Set it to
an empty value for a build with no UHD instrumentation. The scripts call
`probe_net` for sampled signals and `trigger_net` for signals that may
participate in a trigger condition.

```tcl
set uvhs_ila_clock_path [string trim {
    fpga_top_debug.core_def.sys_clk_i
}]
set uvhs_ila_probe_paths {
    fpga_top_debug.core_def.cpu_rstn_io
    fpga_top_debug.core_def.io_host_ila_trigger
}
set uvhs_ila_trigger_paths {
    fpga_top_debug.core_def.io_host_ila_trigger
}
```

Signal hierarchy must match the selected generated RTL. After adding probes to
the default file, build a new database and bitstream normally:

```sh
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=probe
```

Select the repository KMH profile, an external profile, or no ILA as follows:

```sh
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=probe \
  UVHS_PROBE_TCL=/path/to/env-scripts/fpga_diff/uvhs/compilation/probe_kmh.tcl
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=probe \
  UVHS_PROBE_TCL=/path/to/probe.tcl
make uvhs CPU=<design> CORE_DIR=/path/to/release/build SUFFIX=noila \
  UVHS_PROBE_TCL=
```

The frontend records the probe and trigger declarations. The backend already
runs `trigger_probe -check` after runtime-data initialization and
`trigger_probe -group` after clock transformation, which inserts and groups the
debug hardware before partitioning.

At runtime, `runtime/trigger.ini` matches the `test0` group in
`probe_kmh.tcl`. Use another condition file for another probe profile, based
on the group and signal names reported by `query -trigger`:

```ini
[test0]
LOGIC = OR
fpga_top_debug.core_def.io_host_ila_trigger = R

[UHD_FINAL_CONDITIONS_LOGIC]
LOGIC = OR
test0
```

Waveform capture is split around the host run. `uvhs_ila_arm` validates and
installs the trigger condition, starts capture, and returns immediately. It
does not reset or release the CPU. `uvhs_ila_upload` waits for an armed
trigger, uploads the UHD data, reconstructs the waveform database, calls
`uvhs_vcd`, and restores any clock reduced for capture bandwidth. The
host-generated upload hook then calls `uvhs_ila_clear`, including after an
upload failure. The standalone `uvhs_vcd` target repeats only the USDB-to-VCD
conversion. The commands create both files below the selected build directory:

```text
runtime-work/UHD/uvhs_ila/UvData.usdb
runtime-work/UHD/uvhs_ila/UvData.vcd
```

The corresponding UVHS runtime sequence is:

```tcl
trigger -ini_check /path/to/trigger.ini
query -capture
config -clock -name clk5_p -frequency <bandwidth-limited-frequency>
config -clock -commit
trigger -set -gatedclk fpga_top_debug.core_def.inter_soc_clk \
  -frequency <bandwidth-limited-frequency> -polarity H
trigger -set -condition /path/to/trigger.ini -position 0
capture -enable
trigger -enable
trigger -status -wait 1 -timeout 60
upload_uhd -depth 1000000 -position 0 -clock clk5_p -out uvhs_ila
```

The FPGA host clears `HOST_IO_ILA_TRIGGER`, invokes `FPGA_ILA_ARM_CMD`, and then
releases the CPU. It raises that signal at Good Trap or DiffTest failure, then
invokes `FPGA_ILA_UPLOAD_CMD` during normal host cleanup. Generate both hooks
with `ila_host_env` so capture starts before CPU release and upload is followed
by trigger/capture cleanup:

```sh
eval "$(make -s ila_host_env FPGA_BACKEND=uvhs \
  CPU=<design> SUFFIX=<tag> FPGA_RUNTIME=$FPGA_RUNTIME)"

/path/to/fpga-host <host arguments>
```

The arm command must use the same runtime work directory as
`uvhs_write_bitstream`. If `$FPGA_HOST` and `$FPGA_RUNTIME` name the same
machine, omit the generated SSH wrapper. The trigger signal must be listed in
the compile-time `trigger_net` group; adding it to RTL with `mark_debug` alone
is not sufficient.

The generated upload hook clears the trigger after a normal host-triggered
capture. Clear it explicitly after an interrupted or independently armed
capture with:

```sh
make uvhs_ila_clear CPU=<design> SUFFIX=<tag>
```

This runs the prototyping command `trigger -clear`; it removes the configured
conditions so the trigger is no longer armed. Omitting probes at compile time
avoids their resource and timing cost entirely; leaving compiled probes idle
avoids capture and upload traffic but does not recover those implementation
resources. In HSP, capture runs in hardware without stopping the DUT clock.
The upload, waveform generation, and USDB-to-VCD conversion increase
debug-command latency rather than DUT cycle time. A large probe set can still
lower the achievable clock frequency indirectly by adding routing and timing
pressure during compilation.
The runtime command service is serial, so `uvhs_ila_clear` is handled after an
in-flight `uvhs_ila_upload` wait reaches its trigger or timeout; it is not an
asynchronous interrupt for the current wait.

The USDB-to-VCD step is equivalent to:

```sh
USDB=/path/to/UvData.usdb
$UV_ROOT/uvd/uvs/bin/usdb2vcd \
  -i "$USDB" -o "${USDB%.usdb}.vcd"
```

The upload window is controlled when starting the capture:

```sh
make uvhs_ila_arm CPU=<design> SUFFIX=<tag> TRIGGER=/path/to/trigger.ini \
  UVHS_ILA_POSITION=0
make uvhs_ila_upload CPU=<design> SUFFIX=<tag> UVHS_ILA_DEPTH=1000000
```

`UVHS_ILA_DEPTH` is the total uploaded sample count. `UVHS_ILA_POSITION` is the
percentage after the trigger, from 0 through 100. Position 0, the default,
keeps the window before the trigger; 50 centers it; 100 keeps the window after
the trigger. Position 0 requests no intentional post-trigger allocation, but
the trigger-recognition and capture-stop pipeline can still leave a small tail
after the sampled trigger edge. `UVHS_ILA_CLOCK` selects the global clock used
to count upload depth and defaults to the CPU parent `clk5_p`.

Before arming, the runtime counts enabled capture stations on each FPGA. It
limits `UVHS_ILA_CLOCK` to 90 percent of the documented 102.336 Gbit/s per-FPGA
UHD bandwidth, using 512 bits per capture station and clock cycle. The original
sign-off frequency is restored after upload, after an arm failure, or by
`uvhs_ila_clear`.

KMH/XiangShan defaults `UVHS_ILA_GATED_CLOCK` to
`fpga_top_debug.core_def.inter_soc_clk`; other profiles default to no gated
capture clock. Override it with the exact comma-separated names shown by
`query -capture` when stations use additional post-partition clock replicas.
The runtime registers each clock at the automatically selected capture
frequency before installing the trigger. This makes the KMH capture stations
advance on actual `inter_soc_clk` edges, so clock-gated intervals do not consume
station samples.
The vendor documents gated-clock capture as approximate when the clock stops or
changes frequency; the trigger must also eventually receive a gated-clock edge.
Use the free-running parent clock for trigger-only profiles that must remain
observable while the CPU clock is stopped. `UVHS_ILA_TIMEOUT` defaults to 60
seconds.

UHD capture inserts its own external DDR wrapper on every FPGA containing a
probe group. The four PDDR4DME cards on the FPGA FMC3 connectors are reserved
for UHD. The DUT DDR controller is constrained to B0/F0, which owns the separate
`pddr4dme_user_inst`. The default topology also keeps B0/F1 for the USB-UART
daughter card and B0/F2 for CPU/XDMA. This avoids sharing an UHD card with the
DUT DDR controller.

## Compatibility Boundary

The retained compatibility code is limited to observed tool behavior:

- `shell_compat.sh` selects Bash in generated synthesis and PnR launchers and
  translates the observed Vivado-to-UVHS signoff differences for the DDR UI
  clock alias and multicycle reset syntax.
- `uv_shell_exec_compat.sh` prepares the required libffi/libpcre compatibility
  links and restores runtime libraries after the vendor launcher sanitizes
  `LD_LIBRARY_PATH`.
- The generalBus export uses a private generator copy and makes its DCP copy
  synchronous so the project is not removed before the copy finishes.
- `vivado_pre_opt.tcl` preserves the XDMA GT reference clock and marks the
  validated XDMA CDC registers.

The flow does not patch user timing constraints, hierarchy names, VIO/ILA
logic, or DDR pins. The generated signoff UDC is normalized only immediately
before the UVHS timing worker reads it.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | Build and runtime target wiring. |
| `../tools/update_core_flist.sh` | Shared Vivado/UVHS RTL file-list entry point. |
| `../tools/rtl_filelist_lib.sh` | Nested file-list parsing and path resolution. |
| `../src/tcl/common/{blk_mem_gen_0,AXI_bridge,data_bridge,xdma_ep}.tcl` | Shared Vivado IP/BD generators used by UVHS IP export and Vivado project creation. |
| `compilation/flow_common.tcl` | Shared UVHS path, environment, and source helpers. |
| `compilation/frontend_run.tcl` | RTL/IP import, elaboration, and uvsyn frontend. |
| `compilation/backend_run.tcl` | Fill-rate setup, partition, routing, PnR, and database commit. |
| `compilation/assemble.tcl` | Assembles the FPGA set from the vendor board description. |
| `compilation/partition.tcl` | Places memory/configuration on B0/F0 and the core/DiffTest/XDMA path on B0/F2. |
| `compilation/assign_pin.tcl` | Physical UART daughter-card, clock, PCIe, JTAG, SD, and control pins. |
| `compilation/timing.tcl` | External clock and asynchronous-group constraints. |
| `compilation/vivado_pre_opt.tcl` | XDMA refclock and CDC constraints. |
| `compilation/prepare_ip.sh` | Coordinates Vivado, generalBus, and external DDR IP preparation. |
| `compilation/export_vivado_ip.tcl` | Runs repository-owned XCI/BD exports inside Vivado. |
| `compilation/probe_ila.tcl` | Minimal host-trigger UHD probe profile. |
| `compilation/probe_kmh.tcl` | KMH debug UHD probe profile. |
| `compilation/shell_compat.sh` | Generated launcher and signoff-constraint compatibility. |
| `runtime/uv_shell_exec_compat.sh` | Runtime library wrapper for UVHS shells and generated Python workers. |
| `runtime/runtime_server.tcl` | Download, reset, DDR, flash, capture, and command service. |
| `runtime/runtime_session.sh` | Process lifecycle and atomic command/result transport. |
| `runtime/trigger.ini` | KMH rising-edge host trigger condition. |
