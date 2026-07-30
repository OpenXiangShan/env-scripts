# UVHS FPGA-Diff Flow

This directory contains the UVHS implementation flow for FPGA-Diff designs on
the U2.2 B0/F2 target. Its targets use the `uvhs_*` prefix; the normal Vivado,
PCIe, and JTAG targets retain their original names and recipes.

## Environment

Configure the runtime host shell before invoking `make`, for example directly
in `.bashrc`. The following values are the validated Hejian runtime
installation; `UVHS_TEMPLATE_DIR` and
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

Complete UVHS installations resolve their own runtime libraries. If a shared
installation reports a missing `libpcre.so.1`, point
`UVHS_COMPAT_PCRE_LIB` at a compatible copy supplied with another installation;
the preflight stages it in the selected work directory without modifying the
shared tool tree.

`UVHS_TEMPLATE_DIR` supplies the board assembly skeleton. The flow regenerates
the repository-owned Vivado IP DCPs and consumes the vendor DDR DCP separately;
the source tree does not carry generated DCPs, bitstreams, or machine paths.
`UVHS_UVW_AXI4_TO_DDR4_SRC` must select a vendor DDR DCP whose AXI width matches
the design. The default is 64 bits for `CPU=nutshell` and 256 bits for the other
designs; `uvhs_sync_uvw_axi4_to_ddr4` checks the copied stub before frontend
starts.

## Build

```sh
make uvhs_tools_check
make uvhs_preflight CPU=<design>
make uvhs_frontend CPU=<design> CORE_DIR=/path/to/generated/core SUFFIX=<tag>
make uvhs_backend CPU=<design> SUFFIX=<tag>
make uvhs_package_bitstream CPU=<design> SUFFIX=<tag>
```

`uvhs_frontend` creates `hw.dat`, imports the generated Vivado IP DCPs and the
vendor DDR DCP, elaborates the RTL, and records board/clock constraints.
`uvhs_backend` partitions and localizes that database, generates the vendor
implementation scripts, then runs placement, routing, timing signoff, and
bitstream generation. Thus frontend is close to synthesis/elaboration and
backend is close to physical implementation, but the boundary is UVHS's
database handoff rather than a direct Vivado `synth_design` boundary.
All designs use the B0/F2 `clk5_p` 25 MHz input as the CPU clock; its default
timing period is 40 ns.

`uvhs_all` runs frontend then backend. `UVHS_EXPORT_IP_FORCE=1` rebuilds the
source-generated Vivado DCPs; the default reuses an existing DCP in the chosen
work directory. `uvhs_clean` removes only the explicitly selected
`UVHS_WORK_DIR`.

### XiangShan

Use the same entry points with `CPU=kmh` and an AXI-based XiangShan RTL tree:

```sh
make uvhs_all CPU=kmh CORE_DIR=/path/to/XiangShan SUFFIX=<tag>
```

The file-list step detects whether `SimTop` exposes DMA and enables the H2C
path accordingly. XiangShan keeps the B0/F2 and x4 defaults, while using 80%
LUT and 30% LUT6 fill limits and disabling the hold-expansion route bailout.

## Runtime

UVHS runtime targets are separate from the normal Vivado LabTools targets:

```sh
# Keep this foreground process attached to the board.
make uvhs_write_bitstream CPU=<design> SUFFIX=<tag>

# Run these from another shell with the same CPU/SUFFIX or UVHS_WORK_DIR.
make uvhs_halt_soc CPU=<design> SUFFIX=<tag>
make uvhs_write_ddr CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.txt
make uvhs_write_flash CPU=<design> SUFFIX=<tag> WORKLOAD=/path/to/image.bin
make uvhs_reset_cpu CPU=<design> SUFFIX=<tag>
make uvhs_runtime_stop CPU=<design> SUFFIX=<tag>
```

`uvhs_write_bitstream` loads the completed `hw.dat`, configures the connector and
clocks, holds `rstn_sw6/rstn_sw5/rstn_sw4` low across `download`, calls
`initialize`, then releases system/DDR reset before CPU reset. The process
polls an atomic command file while it owns the runtime session. The other
runtime targets wait for command completion and propagate errors to Make.
`uvhs_halt_soc` and `uvhs_reset_cpu` control `rstn_sw5`; the other two reset
names remain reserved for the system and external DDR IP.

`uvhs_write_ddr` accepts the same address/data-pair text file as the Vivado Tcl,
converts each segment to the selected DCP word width, and writes the DDR IP
through the UVHS `writemem` runtime backdoor. It holds CPU reset low after the
write; run `uvhs_reset_cpu` when the image is ready. H2C remains available for
the normal FPGA-Diff host workflow and is independent of this loader.

The BRAM-backed flash is inside an imported Vivado DCP and is not exposed as a
UVHS runtime memory. The flow therefore generates a 64-bit UVHS generalBus IP
and connects it to the existing 32-bit flash path through `AXI_bridge`'s width
converter. `uvhs_write_flash` holds CPU reset, pads the raw binary to the
generalBus 8-byte transfer alignment, writes at `0x10000000`, reads the entire
transfer back, and releases CPU reset only after a byte-for-byte match. The
maximum image size is the flash BRAM capacity, 32 KiB. The normal
`write_jtag_flash` target continues to use its dedicated 32-bit JTAG AXI. A
database built before this generalBus path was added cannot use
`uvhs_write_flash` and must be rebuilt.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | UVHS-only Make targets, prerequisites, DCP export, and stage invocation. |
| `export_vivado_ip.tcl` | Regenerates repository-owned Vivado IP/BD DCPs; `uvhs.mk` separately invokes the vendor generalBus generator. |
| `frontend_run.tcl` | Creates the UVHS database, imports DCPs, reads RTL, and runs frontend. |
| `backend_run.tcl` | Applies implementation-stage clock/constraint compatibility patches and runs P&R. |
| `assemble_uvhs.tcl` | Reduces the four-FPGA vendor template to the selected FPGA and its daughter cards. |
| `assign_pin_u22_f2.tcl` | Assigns target-board clocks, PCIe, UART, and low-speed I/O; DDR pins remain owned by the vendor IP. |
| `timing_common.tcl`, `async_clocks.tcl` | Declare clocks and asynchronous clock-domain relationships. |
| `check_modules.sh`, `check_flow_tools.sh` | Validate the generated RTL file list and checked-in flow sources. |
| `make_compat/` | Supplies the Bash-compatible commands required by UVHS-generated Makefiles and its `csh -fc limit` probe. |
| `patch_uvsyn_shell.sh` | Patches the generated worker Makefile to run the vendor `uv_shell` script through Bash. |
| `enqueue_runtime_command.sh`, `runtime_command.tcl` | Atomically submit reset and memory operations to the attached runtime process. |
| `uv_shell_exec_compat.sh` | Restores staged compatibility libraries after the vendor launcher sanitizes `LD_LIBRARY_PATH`. |
| `../src/rtl/common/core_def_xdma.sv` | Instantiates the width-matched vendor DDR IP directly for UVHS builds. |
| `../user_script/hw_run_download.tcl` | Downloads and initializes a completed UVHS database, then services runtime commands. |
