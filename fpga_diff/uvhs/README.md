# UVHS FPGA-Diff Flow

This directory is the source flow for the Hejian UVHS FPGA-Diff target. It is
separate from the legacy standalone Vivado targets in `fpga_diff/`.

The legacy project-generation helpers are documented in
[`../vivado/README.md`](../vivado/README.md) and are intentionally outside this
directory.

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

## Supporting Tools

Tracked supporting helpers live under `tools/build/` and contain only
generated-RTL fixes applied while constructing the file list. Board-specific
probe, BAR, XDMA, strace, and backdoor-DDR debug scripts are kept as local
tools and intentionally excluded from Git.

The Makefile accepts `UVHS_PROBE_FILE=/path/to/local/probe.tcl`; without a
local probe file it generates an intentionally empty probe script.

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
