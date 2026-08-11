# UVHS FPGA-Diff Flow

This directory is the source flow for the Hejian UVHS FPGA-Diff target. It is
separate from the legacy standalone Vivado targets in `fpga_diff/`.

## Entry Points

- `../Makefile`: public `uvhs_*` forwarding targets.
- `Makefile`: UVHS frontend, backend, packaging, and preflight implementation.
- `setenv.sh`: repository-generic tool and license setup.
- `setenv.local.example.sh`: template for machine-local settings. Copy it to
  `setenv.local.sh`; the local file is ignored by Git.
- `flow.md`: detailed build, signoff, runtime, and troubleshooting runbook.

## Build Stages

Run the stages explicitly so frontend, backend, packaging, and board runtime
failures remain distinguishable:

```sh
make uvhs_tools_check
make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/generated/core SUFFIX=<tag>
make uvhs_backend CPU=nutshell SUFFIX=<tag>
make uvhs_package_bitstream CPU=nutshell \
  UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_nutshell-<tag>
```

`uvhs_all` is available for a full build. `UVHS_USE_LSF=0` is the local-run
override when no scheduler is available. Keep `UVHS_WORK_DIR` outside the
source tree when possible; generated `fpga_diff_uvhs_*` directories are
ignored.

## Runtime And Workload

The minimal runtime stage contains `hw.dat` and the download script under
`../user_script/`:

- `hw_run_download.tcl`: load the database, download the bitstream, initialize
  the board, and release the software resets.

For repeated experiments use `uvhs_tagged_runtime.sh`. Every run must have a
unique `UVHS_RUN_TAG`, stage directory, command file, work directory, tmux
session, and log path. Cleanup is exact-tag only:

```sh
UVHS_RUN_TAG=<tag> \
UVHS_STAGE_DIR=/path/to/runtime-stage \
  bash uvhs_tagged_runtime.sh cleanup
```

Do not add DDR writes or manual reset toggles to `hw_run_download.tcl`. The
normal `fpga-host` flow writes its workload through H2C.

For a bitstream built with the standard probe template, queue the one supported
runtime capture flow before starting `fpga-host`:

```sh
UVHS_RUN_TAG=<tag> UVHS_STAGE_DIR=/path/containing/<tag> \
  bash uvhs/uvhs_queue_uhd_capture.sh
```

This arms the `difftest_to_host_axis_tvalid_io` condition, uploads the existing
15-signal stations, and runs `wavegen`. It writes `UvData.usdb` under the same
tagged runtime work directory. The helper does not program the board, write the
workload, or declare another probe/capture implementation.

## Supporting Tools

Tracked supporting helpers live under `tools/build/` and contain generated-RTL
fixes applied while constructing the file list. `probe_template.tcl` is the
standard CPU-independent Hejian `probe_net`/`trigger_net` template. It covers
reset, host control, XDMA link, DiffTest startup, and C2H handshakes. More
focused CPU hierarchy, BAR, XDMA, strace, and backdoor-DDR debug scripts remain
local tools.

The standard template is deliberately opt-in. It does not change CPU/SoC RTL
or the functional AXI-to-DDR connection. On a board verified to have
PDDR4DME cards at both F2/FMC3 and F3/FMC3, build the validated two-FPGA
waveform topology with:

```sh
make uvhs_hejian_pcie_x4_nutshell_probe_all \
  CORE_DIR=/path/to/NutShell SUFFIX=<wave-tag>
```

This keeps the F2/FMC3 capture DDR with the single F2 probe implementation and
moves only the complete functional AXI-to-DDR IP to F3/FMC3. The target keeps
F2 and F3, selects `partition_capture_ddr_f3.tcl`, and localizes the gated SoC
clock used by the CPU side of the cross-FPGA memory path.

For passive NutShell commit tracing into two dedicated DDR channels, use:

```sh
make uvhs_hejian_pcie_x4_nutshell_trace_all \
  CORE_DIR=/path/to/NutShell SUFFIX=<trace-tag>
```

This three-FPGA target keeps the CPU, XDMA, and trace channel 0 on F2, places
trace channel 1 on F1, and moves the unchanged functional DDR IP to F3. Trace
FIFO readiness is deliberately not connected back to NutShell: a full FIFO
drops the current record, whose sequence number exposes the gap, instead of
stalling CPU execution. The two trace DDRs retain the accepted records for
UVHS runtime `readmem` access.

For XiangShan `FpgaDiffDefaultConfig`, build the corresponding passive ROB
snapshot target with:

```sh
make uvhs_hejian_pcie_x4_xiangshan_trace_all \
  CORE_DIR=/path/to/XiangShan/FpgaDiffDefaultConfig/generated-release \
  SUFFIX=<trace-tag>
```

This target uses the same F2/F1 trace-channel placement. XiangShan exposes a
256-bit functional DDR AXI interface, so a lossless 80-bit ready/valid packet
link keeps XiangShan, XDMA, and trace channel 0 on F2 while placing the
functional DDR controller on F3. AXI backpressure is preserved by the link;
trace readiness remains passive and cannot stall the CPU. The wrapper's ROB
hierarchy is specific to generated `FpgaDiffDefaultConfig` RTL.

The template creates the `uvhs_control` and `uvhs_c2h` trigger groups in their
respective clock domains. Set `UVHS_ENABLE_TRIGGER_NET=0` for probes without
trigger groups. These groups expose trigger-capable signals; runtime capture
still selects the comparison condition and arms the trigger. `UVHS_PROBE_TOP`
defaults to `UVHS_TOP`. A specialized local template can explicitly override
the default with `UVHS_PROBE_FILE=/path/to/local/probe.tcl`.

There is one supported probe/trigger definition: the standard template selected
by `UVHS_ENABLE_PROBE_NET`. Do not add a second probe flow. UHD uses a capture
DDR controller in addition to the probe/trigger instrumentation; it does not
replace that instrumentation or reduce its LUT cost. Board programming must
stop unless the generated binding report and physical inventory prove that UHD
capture and functional AXI-to-DDR each have usable memory hardware.

## Useful Checks

```sh
make uvhs_preflight
make uvhs_check_modules CPU=nutshell CORE_DIR=/path/to/generated/core
make uvhs_status CPU=nutshell \
  UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_nutshell-<tag>
```

The generated database, bitstream, reports, logs, local debug helpers, and
temporary runtime files are not tracked. The source of truth is the Makefile,
frontend/backend Tcl, RTL wrapper, constraints, and download runtime listed
above.
