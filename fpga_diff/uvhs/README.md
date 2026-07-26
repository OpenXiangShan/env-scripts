# UVHS FPGA-Diff Flow

This directory contains the UVHS implementation flow for FPGA-Diff designs on
the U2.2 B0/F2 target. It is selected explicitly with `UVHS=1`; the top-level
Makefile otherwise retains the normal Vivado flow unchanged.

## Environment

Configure the runtime host shell before invoking `make`. The following values
are the validated Hejian runtime installation; `UVHS_TEMPLATE_DIR` and
`UVHS_UVW_AXI4_TO_DDR4_SRC` identify the locally installed base project and
vendor DDR IP and therefore remain site-specific.

```sh
export UV_ROOT=/home/data/UVHS/2506p4_0210
export UV_XILINX_VIVADO=/home/data/test/tools/vivado_2024/Vivado/2024.2
export XILINX_HLS=
export UV_LICENSE=8273@localhost
export UVHS_TEMPLATE_DIR=/path/to/uvhs-template
export UVHS_UVW_AXI4_TO_DDR4_SRC=/path/to/uvw_axi4_to_ddr4
```

`UVHS_TEMPLATE_DIR` supplies the board assembly skeleton. The source tree
regenerates its own Vivado DCPs and does not carry generated DCPs, bitstreams,
or machine paths.

## Build

```sh
make UVHS=1 uvhs_tools_check
make UVHS=1 uvhs_preflight CPU=<design>
make UVHS=1 uvhs_frontend CPU=<design> CORE_DIR=/path/to/generated/core SUFFIX=<tag>
make UVHS=1 uvhs_backend CPU=<design> SUFFIX=<tag>
make UVHS=1 uvhs_package_bitstream CPU=<design> SUFFIX=<tag>
```

`uvhs_frontend` creates `hw.dat`, imports the generated Vivado IP DCPs and the
vendor DDR DCP, elaborates the RTL, and records board/clock constraints.
`uvhs_backend` partitions and localizes that database, generates the vendor
implementation scripts, then runs placement, routing, timing signoff, and
bitstream generation. Thus frontend is close to synthesis/elaboration and
backend is close to physical implementation, but the boundary is UVHS's
database handoff rather than a direct Vivado `synth_design` boundary.

`uvhs_all` runs frontend then backend. `UVHS_EXPORT_IP_FORCE=1` rebuilds the
source-generated Vivado DCPs; the default reuses an existing DCP in the chosen
work directory. `uvhs_clean` removes only the explicitly selected
`UVHS_WORK_DIR`.

## Runtime

Use `user_script/hw_run_download.tcl` with the completed `hw.dat` database.
It downloads the design and releases the software resets. The host-side
FPGA-Diff flow loads the workload through H2C after download; the runtime Tcl
does not contain workload, debug, or command-file hooks.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | UVHS-only Make targets, prerequisites, DCP export, and stage invocation. |
| `export_vivado_ip.tcl` | Regenerates repository-owned Vivado IP/BD DCPs. |
| `frontend_run.tcl` | Creates the UVHS database, imports DCPs, reads RTL, and runs frontend. |
| `backend_run.tcl` | Applies implementation-stage clock/constraint compatibility patches and runs P&R. |
| `assemble_uvhs.tcl` | Adapts the template assembly to the selected B0/F2 board instance and DDR IP. |
| `assign_pin_u22_f2.tcl` | Assigns target-board clocks, PCIe, UART, and reset-visible top ports. |
| `timing_common.tcl`, `async_clocks.tcl` | Declare clocks and asynchronous clock-domain relationships. |
| `check_modules.sh`, `filelist.awk`, `check_flow_tools.sh` | Validate the generated RTL file list and checked-in flow sources. |
| `make_compat/` | Supplies the Bash-compatible commands required by UVHS-generated Makefiles and its `csh -fc limit` probe. |
| `patch_uvsyn_shell.sh` | Patches the generated worker Makefile to run the vendor `uv_shell` script through Bash. |
| `uvhs_axi64_to_axi256.sv` | Converts a 64-bit source AXI data path to the vendor DDR IP's 256-bit interface. |
| `uvhs_ddr4_wrapper.sv` | Isolates the vendor DDR AXI wiring from the common FPGA-Diff top-level RTL. |
| `../user_script/hw_run_download.tcl` | Downloads and initializes a completed UVHS database. |
