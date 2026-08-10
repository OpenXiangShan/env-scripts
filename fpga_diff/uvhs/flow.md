# Hejian UVHS FPGA DiffTest Flow

This is the self-contained runbook for the `env-scripts/fpga_diff` Hejian
UVHS flow. The validated target is the NutShell SoC; the flow also provides a
XiangShan `FpgaDiffDefaultConfig` integration with the MinJie XDMA driver and
`fpga-host`.

## Validated Configuration

The checked Hejian preset uses:

- target `B0/F2`, platform `U2.2`, design `VU19P_X4`
- XDMA Gen3 x4, vendor/device `10ee:9048`
- BAR0 `0x80000` (512 KiB), BAR1 `0x10000` (64 KiB)
- CPU/SoC clock 25 MHz from `clk5_p` (`UVHS_CPU_DEBUG_CLK=1`,
  `UVHS_CPU_CLK_PERIOD_NS=40`), matching the Vivado flow
- XDMA AXI clock 125 MHz and DDR UI clock 200 MHz
- PnR strategy `Strategy_uv_high_fanout_explore`
- BAR1 signatures: offset `0x2000` high16 `0x1fc2`, offset `0x3000`
  high16 `0x1fc3`

This configuration has completed FPGA DiffTest with `HIT GOOD TRAP`.

## Prerequisites

The caller supplies all machine-specific paths. Do not commit licenses,
passwords, host keys, build databases, DCPs, bitstreams, workloads, NEMU shared
objects, or kernel modules.

Required inputs are:

- a NutShell generated RTL tree passed as `CORE_DIR`
- the Hejian template archive visible through `UVHS_TARBALL`
- Hejian UVHS and matching Vivado installations configured by
  `uvhs/setenv.local.sh`
- the checked x4 XDMA endpoint DCP and base assembly project
- the UVHS `uvw_axi4_to_ddr4` DCP/stub/constraints
- on the FPGA host, a locally compiled MinJie mainline `xdma-chr.ko` whose
  vermagic matches the running kernel
- a NutShell workload binary and matching NEMU shared object for DiffTest

Required executables by machine are:

- build host: GNU `bash`, `make`, `awk`, `sed`, `grep`, `find`, `sort`, `tar`,
  `sha256sum`, `realpath`, Python 3, `tclsh`, `csh`, Hejian `uv_shell`, and the
  Vivado release matching the selected DCPs (2024.2 for the checked XDMA DCP)
- runtime host: Hejian `uv_shell -rt_shell`, `tmux`, and the board runtime
  dependencies installed with UVHS
- FPGA host: `ssh`, `lspci`, `setpci`, `modinfo`, `lsmod`, `dmesg`, `fuser`,
  `strace` with `-yy`, GNU `timeout`, Python 3, a C/C++ build toolchain, and the
  running-kernel headers used to build `xdma-chr.ko`

Prepare the local environment:

```bash
cd fpga_diff
cp uvhs/setenv.local.example.sh uvhs/setenv.local.sh
# Set only local tool, license, hardware-server, and DCP paths in this ignored file.
source uvhs/setenv.sh
make uvhs_tools_check
```

`make uvhs_tools_check` is a static check. It does not invoke UVHS/Vivado,
program a board, rescan PCIe, write BARs, load a driver, or reboot a host.

## Tool Inventory

### Build and configuration

| File | Purpose |
| --- | --- |
| `Makefile` | Public forwarding targets for the UVHS sub-make. |
| `uvhs/Makefile` | Work-tree generation, IP export, frontend/backend, signoff, and packaging. |
| `uvhs/setenv.sh` | Repository-generic environment loader. |
| `uvhs/setenv.local.example.sh` | Template for ignored machine-local settings. |
| `uvhs/hejian_pcie_x4_env.sh` | Print/check the validated x4/BAR/clock preset. |
| `uvhs/filelist.awk`, `uvhs/check_modules.sh` | Generate and validate the UVHS RTL file list. |
| `uvhs/export_vivado_ip.tcl` | Export Vivado IP DCPs used by the UVHS assembly. |
| `uvhs/frontend_run.tcl` | Build the UVHS frontend database. |
| `uvhs/backend_run.tcl` | Partition, implement, route, and generate the bitstream. |
| `uvhs/assemble_uvhs.tcl`, `uvhs/partition.tcl` | Apply the selected B0/F2 hardware assembly and partition policy. |
| `uvhs/partition_capture_ddr_f3.tcl` | Move the complete functional DDR IP to F3 for the validated two-FPGA UHD build. |
| `uvhs/partition_nutshell_cpu_trace_ddr.tcl` | Place the passive NutShell trace DDR channels on F2/F1 and functional DDR on F3. |
| `uvhs/partition_xiangshan_cpu_trace_ddr.tcl` | Place XiangShan trace channels on F2/F1 and the compact-link functional DDR sink on F3. |
| `uvhs/assign_pin_nutshell_f2.tcl`, `uvhs/async_clocks.tcl`, `uvhs/timing_common.tcl` | NutShell pin and clock constraints. |
| `uvhs/patch_uvsyn_shell.sh`, `uvhs/uv_shell_exec_compat.sh`, `uvhs/make_compat/` | Versioned UVHS compatibility helpers. |
| `uvhs/tools/build/patch_nutshell_cdc.sh` | Apply the required idempotent CDC fix to generated NutShell RTL. |

### SoC RTL and IP adaptation

| File | Purpose |
| --- | --- |
| `src/rtl/common/core_def_xdma.sv` | Final NutShell SoC, DDR, XDMA, DiffTest, UART, reset, and clock integration. |
| `src/rtl/common/uvhs_axi64_to_axi256.sv` | CPU-side 64-bit to UVHS DDR 256-bit AXI adaptation. |
| `src/rtl/common/uvhs_axilite_cdc_bridge.sv` | Owned AXI-Lite CDC bridge for the XDMA control path. |
| `src/rtl/common/uvhs_blackbox_stubs.v` | UVHS/Vivado IP interface declarations. |
| `src/rtl/common/cpu_trace/` | Passive CPU trace buffering/striping, dual-DDR AXI writing, and the XiangShan functional-DDR compact AXI link. |
| `src/tcl/common/AXI_bridge.tcl` | XDMA/DiffTest AXI bridge generation. |

### Reports, timing, CDC, and probes

| File | Purpose |
| --- | --- |
| `tools/report_post_route_cdc.tcl` | Routed CDC report and owned-vs-IP classification evidence. |
| `tools/report_pcie_route_evidence.tcl` | Routed XDMA link, BAR, clock, and connectivity evidence. |
| `uvhs/status.sh`, `uvhs/uvhs_preflight_status.sh` | Read-only build/runtime status summaries. |
| `uvhs/probe_template.tcl` | The single standard 15-signal, two-trigger-group UHD instrumentation definition. |

### Runtime programming and workload

| File | Purpose |
| --- | --- |
| `user_script/hw_run_download.tcl` | Load DB, program, update clocks/link, initialize, release resets, and keep the runtime attached. |
| `user_script/hw_capture_uhd.tcl`, `user_script/uhd_c2h.ini` | Arm the C2H condition, upload UHD capture data, and generate `UvData.usdb`. |
| `uvhs/uvhs_tagged_runtime.sh` | Exact-tag tmux start, readiness evidence, status, and cleanup. |
| `uvhs/uvhs_queue_uhd_capture.sh` | Queue the standard capture fragment into the exact tagged runtime. |

The final `fpga-host` path writes the workload to DDR through H2C. Specialized
CPU probes, BAR, XDMA, strace, recovery, and backdoor-DDR scripts remain local;
only the CPU-independent standard UHD path above is tracked.

## Build

Use a new suffix for every build:

```bash
cd fpga_diff
make uvhs_tools_check
make uvhs_hejian_pcie_x4_preflight CORE_DIR=/path/to/NutShell
make uvhs_hejian_pcie_x4_nutshell_all \
  CORE_DIR=/path/to/NutShell \
  SUFFIX=<unique-tag>
```

The work directory is:

```text
fpga_diff_uvhs_nutshell-<unique-tag>
```

The expected routed directory is:

```text
hw.dat/Compile/PnR/B0/F2/vivado/Rundir/Strategy_uv_high_fanout_explore
```

Package a clean routed build:

```bash
make uvhs_status CPU=nutshell SUFFIX=<unique-tag>
make uvhs_check_timing_clean CPU=nutshell SUFFIX=<unique-tag>
make uvhs_package_bitstream CPU=nutshell SUFFIX=<unique-tag>
```

## Signoff Gate

Before programming, retain the frontend, backend, PnR, bit-generation, timing,
CDC, and warning reports. Required gates are:

- frontend `ERROR=0`, backend `ERROR=0`, PnR `PASS=1`
- bit generation failure count `0`
- WNS/TNS/WHS/THS have no failing values
- owned RTL, `U_CPU_TOP`, `SimTop`, DiffTest blocks, host blocks, and XDMA
  adapter have zero Critical CDC
- XDMA/Aurora/UVHS IP-internal CDC is classified separately

Do not hide an owned CDC issue with a false path. Stop before board programming
if owned Critical CDC is nonzero. Keep the generated warning log: warnings are
part of signoff evidence and must not be disabled globally.

## Probe And Trigger Template

`probe_template.tcl` is the standard CPU-independent Hejian UHD template. It
adds two clock-domain-specific groups:

- `uvhs_control` samples reset, host control, and XDMA link state on `sys_clk_i`.
- `uvhs_c2h` samples DiffTest startup and C2H AXI-Stream handshakes on
  `difftest_pcie_clock`.

The template is sourced by default but does nothing unless
`UVHS_ENABLE_PROBE_NET=1`. `UVHS_ENABLE_TRIGGER_NET=1` declares the same signals
as runtime-configurable trigger groups; it does not select a comparison value or
arm capture during the build. It does not change CPU/SoC RTL or the functional
AXI-to-DDR RTL connection. After verifying physical PDDR4DME cards at F2/FMC3
and F3/FMC3, use the validated two-FPGA target:

```bash
make uvhs_hejian_pcie_x4_nutshell_probe_all \
  CORE_DIR=/path/to/NutShell SUFFIX=<wave-tag>
```

This target keeps F2/F3, places the complete functional AXI-to-DDR IP on F3,
leaves the single UHD probe/capture implementation and its capture DDR on F2,
and localizes `SOC_GATED_CLK` for the cross-FPGA memory path.

Set `UVHS_ENABLE_TRIGGER_NET=0` to retain the probes without trigger groups. A
CPU-specific local template can replace the standard one with
`UVHS_PROBE_FILE=/path/to/local/probe.tcl`.

The probe/trigger template is the only signal-instrumentation flow. The vendor
UHD capture controller still requires capture storage; it is not an alternative
to `probe_net` and does not save LUT. A waveform build must verify that the
backend binding report and physical board inventory provide usable memory for
both UHD capture and the functional `uvw_axi4_to_ddr4` IP. Do not synthesize a
daughter-card declaration for an unverified physical connector.

After the tagged runtime is ready, queue the standard C2H condition capture and
then start the normal H2C `fpga-host` flow:

```bash
export UVHS_RUN_TAG=<unique-tag>
export UVHS_STAGE_DIR=/path/containing/<unique-tag>
bash "$UVHS_STAGE_DIR/uvhs_queue_uhd_capture.sh"
# Wait for UVHS_UHD_CAPTURE_ARMED in the runtime log, then start fpga-host.
```

The queued fragment uses `uhd_c2h.ini`, waits for
`difftest_to_host_axis_tvalid_io=1`, runs `upload_uhd`, and converts the same
capture with `wavegen` to `UHD/<output>/UvData.usdb`. This runtime layer consumes
the 15 probes and two trigger groups already built by `probe_template.tcl`; it
does not add a second instrumentation or capture-DDR path. The UVHS 2025.06.P4
runtime may reject `query -capture -sgfile` with `RTM-103`, so the validated
flow uses plain `query -capture` and the generated `VisualUsdb_Cap.wcf`.

## Runtime Programming

Stage the build database and helpers on the runtime host under a path containing
the exact run tag. Then run:

```bash
export UVHS_RUN_TAG=<unique-tag>
export UVHS_STAGE_DIR=/path/containing/<unique-tag>
export UVHS_ALLOW_DOWNLOAD=1
export UVHS_ALLOW_DOWNLOAD_TAG="$UVHS_RUN_TAG"

bash "$UVHS_STAGE_DIR/uvhs_preflight_status.sh"
bash "$UVHS_STAGE_DIR/uvhs_tagged_runtime.sh" start
bash "$UVHS_STAGE_DIR/uvhs_tagged_runtime.sh" status
```

Readiness requires logged evidence for `load_db`, download success, link up,
initialize, DDR initialize, and released `rstn_sw4/5/6`. The runtime shell must
remain attached while the FPGA host runs. Never reboot the runtime host, and
never kill a PID that is not proven to contain the exact current tag.

## FPGA-host and DiffTest

On the FPGA host, verify the expected Gen3 x4 `10ee:9048` endpoint, BAR sizes
and signatures, then load a matching locally built MinJie `xdma-chr.ko` and
confirm `/dev/xdma*`. Compile `fpga-host`, NEMU, and the NutShell workload on
that host. The normal flow sets `UVHS_DISABLE_DOWNLOAD=1` and lets `fpga-host`
write the workload through H2C. Board-specific automation and evidence capture
remain local rather than being shipped as part of the source flow.

## Cleanup

At the end of every run, stop only artifacts carrying the exact run tag:

```bash
UVHS_RUN_TAG=<unique-tag> \
UVHS_STAGE_DIR=/path/containing/<unique-tag> \
bash /path/containing/<unique-tag>/uvhs_tagged_runtime.sh cleanup
```

Retain build warnings, download/init logs, UART logs, host logs, strace summary,
C2H progress, `/dev/xdma*` occupancy, and dmesg evidence. Cleanup must show no
remaining tmux session or runtime process for the current tag.
