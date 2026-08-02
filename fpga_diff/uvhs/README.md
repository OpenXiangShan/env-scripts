# UVHS FPGA-Diff Flow

This directory contains the UVHS build and runtime flow for FPGA-Diff on the
U2.2 B0/F2 target. UVHS targets use the `uvhs_*` prefix; the existing Vivado,
PCIe, and JTAG targets keep their original behavior.

## Environment

Configure the runtime host shell directly, for example in `.bashrc`:

```sh
export UV_ROOT=/home/data/UVHS/2506p4_0210
export UV_XILINX_VIVADO=/home/data/test/tools/vivado_2024/Vivado/2024.2
export XILINX_HLS=
export UV_LICENSE=8273@localhost
export UVHS_TEMPLATE_DIR=/path/to/uvhs-template
export UVHS_UVW_AXI4_TO_DDR4_SRC=/path/to/uvw_axi4_to_ddr4
```

`UVHS_TEMPLATE_DIR` provides the U2.2 board assembly files. The flow regenerates
the repository-owned Vivado IP and imports the vendor DDR DCP selected by
`UVHS_UVW_AXI4_TO_DDR4_SRC`. That DCP must expose a 64-bit AXI interface for
`CPU=nutshell` and a 256-bit interface for other designs; the stub is checked
before frontend starts.

Some shared UVHS installations need a local `libpcre.so.1`. Set
`UVHS_COMPAT_PCRE_LIB` to a compatible library when preflight reports that
dependency. The flow stages the library in its work directory and does not
modify the shared installation.

## Build

```sh
make uvhs_tools_check
make uvhs_preflight CPU=<design>
make uvhs_frontend CPU=<design> CORE_DIR=/path/to/core SUFFIX=<tag>
make uvhs_backend CPU=<design> SUFFIX=<tag>
make uvhs_package_bitstream CPU=<design> SUFFIX=<tag>
```

`uvhs_frontend` creates `hw.dat`, applies board and timing constraints, imports
the fixed IP DCPs, elaborates the RTL, and runs UVHS synthesis. It also records
the DDR instance used by runtime `writemem`.

`uvhs_backend` reads that database and runs clock inference, remap, partition,
localization, system routing, FPGA placement/routing, timing signoff, and
bitstream generation. Its implementation sequence follows the vendor reference
flow. The only custom Vivado stage is `vivado_pre_opt.tcl`, which preserves the
XDMA GT reference-clock input and marks the known XDMA synchronizer registers.

`uvhs_all` runs both stages. `UVHS_EXPORT_IP_FORCE=1` regenerates Vivado and
generalBus DCPs even when the selected work directory already contains them.
`uvhs_clean` removes only the selected `UVHS_WORK_DIR` and refuses to run while
its runtime session is active.

### XiangShan And External RTL

For `CPU=kmh`, `uvhs_prepare_core_rtl` runs the upstream `difftest`
`fpga-release` target and synthesizes the extracted release instead of the raw
`build/rtl`. This keeps the normal FPGA clock-gate replacement,
`DifftestClockGate.v`, and generated RAM-style conversion.

`RTL_INCLUDE` accepts RTL files, directories, and nested `.f`, `.flist`, or
`.list` files. `tools/update_core_flist.sh` resolves every relative entry
against its containing file list before writing the UVHS input list. For
example:

```sh
make uvhs_all CPU=kmh CORE_DIR=/path/to/XiangShan \
  RTL_INCLUDE=/path/to/external_llc.f SUFFIX=<tag>
```

The default XiangShan partition limits are 80% LUT and 30% LUT6. They remain
overridable through `UVHS_LUT_FILL_RATE` and `UVHS_LUT6_FILL_RATE`; changing
them is a placement experiment, not a functional requirement.

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

`uvhs_write_bitstream` loads the completed database, configures the connector
and clocks, holds the three named resets across `download`, initializes the
hardware, and releases the resets in system/DDR/CPU order. It then detaches the
session because later UVHS memory operations must use the process that owns the
downloaded database. Runtime PID, readiness, commands, and logs are under
`runtime-work`.

`uvhs_write_ddr` converts the address/data-pair format used by the Vivado DDR
loader to the selected 64-bit or 256-bit DCP word width, then calls UVHS
`writemem -rtl`. It leaves the CPU halted; call `uvhs_reset_cpu` after loading.

`uvhs_write_flash` uses the 64-bit UVHS generalBus master and the existing
32-bit `AXI_bridge` flash path. GeneralBus sees the flash at offset `0x0`; the
CPU and the normal JTAG path retain their `0x10000000` mapping. The command pads
the binary to an 8-byte transfer, writes at offset zero, and requires a complete
readback match before releasing the CPU. The maximum image is 32 KiB.

## Compatibility Boundary

Only compatibility workarounds observed as necessary on the validated UVHS
installation remain:

- `make_compat/` supplies Bash-backed `make` and the limited `csh -fc limit`
  query emitted by UVHS. The host does not provide `csh` or `tcsh`.
- `shell_compat.sh` selects Bash in generated synthesis and PnR launchers. Those
  launchers use Bash syntax but are generated with `/bin/sh` invocation paths.
- `uv_shell_exec_compat.sh` restores staged runtime libraries after the vendor
  launcher sanitizes `LD_LIBRARY_PATH`.
- The private generalBus generator copy replaces its asynchronous DCP copy with
  `shutil.copy2`; otherwise it can delete the project before the copy finishes.

No generated clock, timing XDC, VIO/ILA, DDR pin, or hierarchy-version text
patching remains in the backend flow.

## Files

| File | Role |
| --- | --- |
| `uvhs.mk` | UVHS targets, inputs, stage invocation, packaging, and runtime commands. |
| `frontend_run.tcl` | Builds the synthesized UVHS database from RTL and imported DCPs. |
| `backend_run.tcl` | Runs the standard partition, localization, PnR, and commit sequence. |
| `vivado_pre_opt.tcl` | Applies the two required XDMA physical/CDC constraints. |
| `assemble_uvhs.tcl` | Reduces the vendor four-FPGA assembly to the selected FPGA set. |
| `assign_pin_u22_f2.tcl` | Assigns B0/F2 clocks, PCIe, UART, JTAG, SD, and low-speed pins. |
| `timing_common.tcl` | Declares the external clocks consumed by frontend. |
| `async_clocks.tcl` | Declares asynchronous relationships after clocks are available. |
| `export_vivado_ip.tcl` | Regenerates repository-owned XCI and block-design DCPs. |
| `check_modules.sh` | Confirms required RTL modules exist in the final file list. |
| `check_flow_tools.sh` | Performs source, shell, Tcl, and local-path checks. |
| `shell_compat.sh`, `make_compat/` | Contain the generated-launcher Bash compatibility. |
| `uv_shell_exec_compat.sh` | Supplies the staged runtime library path to `uv_shell_exec`. |
| `hw_run_download.tcl` | Downloads the database and starts its runtime command service. |
| `runtime_control.tcl` | Defines reset sequencing and command polling. |
| `runtime_command.tcl` | Implements reset, DDR, and flash operations. |
| `runtime_session.sh` | Starts, checks, waits for, and stops the detached session. |
| `enqueue_runtime_command.sh` | Submits one command and returns its completion status. |
