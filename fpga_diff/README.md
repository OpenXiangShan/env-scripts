Core RTL to FPGA Steps
======================

1. modify Makefile, assign CORE_DIR

2. make vivado CPU=XXX
  (this step compile a project,CPU Parameter support "kmh" "nutshell" "nanhu")
  (from this step on, you may use vivado gui)

3. make bitstream
  (start background bitstream gen)

4. wait
  (watch "fpga_$cpu/$cpu$.runs/xxxx/runme.log")
  (wait for bitstream gen to finish)

5. (first) Add file execution permission
  chmod u+x tools/pcie-remove.sh
  chmod u+x tools/pcie-rescan.sh

6. make write_bitstream

7. write DDR and run with diff/no-diff
```shell
case 1: No fpga-host
stty -F /dev/ttyUSB0 raw 115200 ...
<New terminal>
make halt_soc
make write_jtag_ddr
make reset_cpu

case 2: With fpga-host (no-diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_jtag_ddr \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --no-diff

case 3: With fpga-host (diff mode)
FPGA_DDR_LOAD_CMD="bash -lc ' \
  source ~/.bash_profile && \
  make -C /path/to/fpga_diff write_jtag_ddr \
    FPGA_BIT_HOME=... \
    WORKLOAD=<workload>.txt \
'" \
./fpga-host --diff <nemu> -i <workload>.bin
```

HJ/UVHS FPGA Flow
=================

The UVHS flow is kept separate from the existing Vivado targets.

Target split:

- `make vivado_frontend ...`
  keeps the default Vivado path and exports the standard DCP-backed IP set.
- `make uvhs_frontend ...`
  runs the UVHS DDR frontend path that instantiates `uvw_axi4_to_ddr4` and
  registers it through `set_ip`.
- `make uvhs_fetch_uvw_axi4_to_ddr4 UVHS_FETCH_UVW_AXI4_TO_DDR4=1 ...`
  optionally fetches the verified UVHS DDR IP assets from the Hejian server
  before a fresh UVHS frontend run.

Compatibility aliases:

- `make uvhs_vivado_frontend ...` is an alias of `make vivado_frontend ...`

Its make targets live in `uvhs/Makefile`. The root `Makefile` only forwards
`uvhs_*` targets there, so both of these forms work:

```shell
make uvhs_frontend CPU=nanhu CORE_DIR=/path/to/core/build
make -f uvhs/Makefile uvhs_frontend CPU=nanhu CORE_DIR=/path/to/core/build
```

1. Prepare environment
```shell
cp uvhs/setenv.local.example.sh uvhs/setenv.local.sh
# edit uvhs/setenv.local.sh for the local UVHS/Vivado/license setup
source ./uvhs/setenv.sh
```

`uvhs/setenv.sh` is repository-generic. Keep machine-specific tool paths,
license servers, and hardware-server settings in `uvhs/setenv.local.sh`, which
is ignored by git.

2. Generate the UVHS working tree and frontend database
```shell
make uvhs_frontend CPU=<kmh|nutshell|nanhu> CORE_DIR=/path/to/core/build
```

`CORE_DIR` is intentionally supplied by the caller. It should point at a build
directory containing the generated CPU RTL and include files.

3. Run backend
```shell
make uvhs_backend CPU=<kmh|nutshell|nanhu>
```

4. Package the generated bitstream and probes
```shell
make uvhs_package_bitstream CPU=<kmh|nutshell|nanhu> UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_<cpu>-<suffix>
```

This creates `ready-to-program/fpga_top_debug.bit` and
`ready-to-program/fpga_top_debug.ltx` under `UVHS_WORK_DIR`.

Minimal UVHS runtime bringup
----------------------------

For board programming through the vendor runtime shell, stage only:

- `UVHS_WORK_DIR/hw.dat`
- `fpga_diff/user_script/hw_run_download.tcl`
- `fpga_diff/user_script/timing.tcl`

The default layout is:

```text
<runtime-stage>/
  hw.dat
  user_script/
    hw_run_download.tcl
    timing.tcl
```

Then launch the vendor shell from `<runtime-stage>` and run
`user_script/hw_run_download.tcl`. If `hw.dat` lives elsewhere, set
`UVHS_DB_PATH=/absolute/path/to/hw.dat` before launching the shell.

Current reproducible UVHS test method
-------------------------------------

The current NutShell UVHS test loop is:

1. Build a fresh UVHS work directory instead of reusing an old
   experiment.
```shell
make -f fpga_diff/uvhs/Makefile uvhs_all \
    CPU=nutshell \
    CORE_DIR=/nfs/home/fengkehan/project/minjie-playground/NutShell \
    SUFFIX=<new-tag> \
    UVHS_USE_LSF=0 \
    UVHS_EXPORT_IP_FORCE=0
```

2. Stage only the runtime database and the minimal download scripts to the
   remote runtime directory.

3. Run the vendor runtime shell from that staged directory and execute
   `user_script/hw_run_download.tcl`.

4. Validate only the minimal smoke-test criteria first:
   - `load_db` succeeds
   - `download` succeeds
   - `initialize` succeeds
   - reset release succeeds
   - board link returns to `link up`

5. Keep workload load, DDR probing, and host-side PCIe debugging as separate
   follow-up steps. Do not fold them into the minimal download script.

Current caveats:

- The default `vivado_*` targets do not use the UVHS DDR path.
- The UVHS build uses the UVHS DDR IP `uvw_axi4_to_ddr4`, skips Vivado export
  of `jtag_ddr_subsys`, and keeps the default Vivado `jtag_ddr_subsys` path
  separate.
- The UVHS frontend registers `uvw_axi4_to_ddr4` with `set_ip`, reads its Stub,
  and appends
  `add_rtl_inst -inst_name fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4`.
  It does not use `UV_MEM_ARRAY_F`.
- `query -memory` is still not sufficient to prove writable DDR runtime objects;
  both the local generated DB and the reference RTDB can report
  `No MEMORY instance found`.
- Runtime workload tests on 2026-05-25 reached `download` and `initialize` with
  the old `jtag_ddr_subsys` experiment, but `writeback_memory` failed with
  `It's not a memory`. Do not reuse that old DDR connection for UVHS.
- For UVHS, do not use the Vivado `write_bitstream` or `write_jtag_ddr` targets
  for board download or DDR workload loading. Use the vendor runtime shell with
  `user_script/hw_run_download.tcl` or `user_script/hw_run_workload.tcl`.
- If DDR-subsystem path timing fails in a future UVHS run, keep the UVHS flow
  split and copy the DDR pin placement plus clock constraints from the UVHS
  example project. Do not reintroduce the old Vivado DCP hookup.

Known-good UVHS DDR timing run:

- Work directory: `fpga_diff/fpga_diff_uvhs_nutshell-uvhs-ddr-ui200`
- PnR: `b0.f2(s0) PASS`
- Timing/bitstream failures: `0`
- Fast signoff WNS: `0.307`
- `CPU_CLK_IN` and `DDR_UI_CLK`: 200 MHz
- Candidate runtime DDR memory path tested by the UVHS workload script:
  `fpga_top_debug.core_def.U_JTAG_DDR_SUBSYS.mmp_i.DDR_MODEL_U0.u_mmk_ddr5_core_cha_rank0.u_array.memory`

Common overrides:

```shell
UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_nutshell-<suffix> make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_ASSIGN_PIN_FILE=/path/to/assign_pin.tcl make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_UVW_AXI4_TO_DDR4_SRC=/path/to/uvhs/ddr-or-reference-project make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_FETCH_UVW_AXI4_TO_DDR4=1 make uvhs_fetch_uvw_axi4_to_ddr4
make uvhs_show_uvw_axi4_to_ddr4
UVHS_USE_LSF=0 make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_EXPORT_IP=0 make vivado_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_EXPORT_IP_FORCE=0 make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
UVHS_SKIP_BOARD_CONSTRAINTS=1 make uvhs_frontend CPU=nutshell CORE_DIR=/path/to/core/build
```

For `CPU=nutshell`, the default `vivado_frontend` path stays on the
Vivado-export flow. The separate `uvhs_frontend` target copies the UVHS DDR
assets into `UVHS_WORK_DIR`, skips Vivado export of `jtag_ddr_subsys`, and
adds `fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4` as the runtime RTL
instance. Set `UVHS_UVW_AXI4_TO_DDR4_SRC` on `uvhs_frontend` if a different
DDR IP release or reference project should be reused. Source `uvhs/setenv.sh`
or run `make uvhs_show_uvw_axi4_to_ddr4` to see the currently visible DDR IP
source path and DCP md5.

Useful checks:

```shell
make uvhs_preflight
make uvhs_check_modules CPU=nanhu CORE_DIR=/path/to/core/build
make uvhs_status CPU=nanhu UVHS_WORK_DIR=/path/to/fpga_diff_uvhs_nanhu-<suffix>
```

For `CPU=nanhu`, the wrapper currently expects the core RTL to provide
`XlnFpgaTop`. If the available build only provides `XSTop`/`SimTop`, regenerate
or point `CORE_DIR` at the matching FPGA SoC RTL before launching UVHS.

`uvhs_prepare` extracts the reference scripts and DCPs from
`../uvhs.tar.gz` into `UVHS_WORK_DIR`, then writes `rtl/filelist.f` from the
current `fpga_diff` SoC wrapper, selected CPU wrapper, optional core RTL, and
optional CHI RTL. Tool locations and license settings come from
`uvhs/setenv.sh`; override that environment before invoking make when running
on a different machine.
