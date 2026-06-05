# UVHS FPGA Flow Notes

This file tracks reusable bringup facts for the `fpga_diff` NutShell UVHS flow.
Keep machine-specific licenses, full logs, generated work directories, and bit
outputs out of git.

## Current Reproducible Path

Use the UVHS make targets under `fpga_diff/uvhs/` and keep generated work
directories under the ignored `fpga_diff_uvhs_<cpu>-<suffix>` prefix.

Current timing-clean B0.F2-only build:

```sh
fpga_diff/fpga_diff_uvhs_nutshell-uvhs-b0f2-only-20260604_094242
```

Build characteristics:

- Target: `B0.F2` only.
- CPU/debug clocks: 25 MHz.
- DDR UI clock: 200 MHz.
- Difftest PCIe clock: 100 MHz.
- PnR result: `b0.f2(s0) PASS`.
- Final WNS: `0.075000`.
- Bitstream path:
  `hw.dat/Compile/PnR/B0/F2/vivado/Rundir/Strategy_uv_placer_extra_timing_opt/bitstream/pnr.bit`.

The useful remote stage used for smoke/host testing was:

```sh
/home/data/test/fengkehan/fpga_diff_uvhs_nutshell-b0f2-smoke-20260605_1415
```

## Minimal UVHS Runtime Smoke

Run the vendor runtime shell on the Hejian programming machine with the staged
`hw.dat` and `user_script/hw_run_download.tcl`:

```sh
cd <stage>
export UVHS_DB_PATH=$PWD/hw.dat
export UVHS_COMMAND_FILE=$PWD/uvhs_host_command.tcl
/home/data/UVHS/2506p4_0210/bin/uv_shell -rt_shell \
  -workdir $PWD/uvshell_download_smoke_<timestamp> \
  -script $PWD/user_script/hw_run_download.tcl
```

Smoke criteria:

- `load_db` opens the RTDB and selects only `B0.F2`.
- `download` succeeds.
- Board returns to `B0.F2 link up`.
- `systembus initialize success`.
- `ps initialize success`.
- `DDR4 initialize success` on connector `FMC3`.
- `rstn_sw6`, `rstn_sw4`, and `rstn_sw5` are released to `1`.

Observed result on 2026-06-05:

- `download -target dut -board P0 B0.F2 -> B0.F2 by root success`.
- `P0 B0.F2 -> B0.F2 linked up by root`.
- `systembus`, `ps`, and `DDR4` initialization all succeeded.
- Final `query -fpgas -all` showed `B0.F2 link up`.

This proves programming, link recovery, reset release, and DDR initialization
for the timing-clean B0.F2-only image. It does not prove CPU execution or C2H.

## Host Retry Result

Host-side retry command shape on open28:

```sh
cd /home/user01/project/env-scripts
export UVHS_HEJIAN_PASS=<set-locally>
export UVHS_STAGE_DIR=/home/data/test/fengkehan/fpga_diff_uvhs_nutshell-b0f2-smoke-20260605_1415
export UVHS_DB_PATH=$UVHS_STAGE_DIR/hw.dat
export UVHS_COMMAND_FILE=$UVHS_STAGE_DIR/uvhs_host_command.tcl
export UVHS_WORKLOAD_TXT=$UVHS_STAGE_DIR/ready-to-run/microbench-nutshell.txt
export UVHS_DDR_RTL=fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4
export UVHS_DDR_SCRIPT=$UVHS_STAGE_DIR/user_script/hw_write_workload_only.tcl
export UVHS_DDR_LOAD_CMD='python3 /home/user01/project/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-b0f2-smoke-20260605_1415/uvhs/trigger_ddr_hejian.py'
export FPGA_DDR_LOAD_CMD="$UVHS_DDR_LOAD_CMD"
export FPGA_HOST_DEBUG_INIT=1
timeout 120s /home/user01/fpga-release/20260428_NutShell_fpgadiff_BasicDiff_ESBIFDU_102043/build/fpga-host \
  --diff /home/user01/fpga-workload/riscv64-nemu-interpreter-so \
  -i /home/user01/project/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-b0f2-smoke-20260605_1415/ready-to-run/microbench-nutshell.bin
```

Observed host evidence:

- `fpga-host` opened `/dev/xdma0_c2h_0`.
- `HOST_IO_RESET` was asserted.
- RAM, flash, and device init completed.
- The external UVHS DDR load command ran successfully.
- Runtime wrote the workload with:
  `writeback_memory -rtl fpga_top_debug.core_def.U_UVHS_UVW_AXI4_TO_DDR4[0:26]`.
- Runtime reported `writeback DDR success`.
- NEMU/ref initialization completed.
- `HOST_IO_RESET` was released.
- No C2H packet progress and no `HIT GOOD TRAP` appeared before timeout.
- Exit code was `124`.

Conclusion: the remaining failure is after `HOST_IO_RESET released`, where the
host waits on C2H and receives no packets. Plain reburn/host retry is no longer
a useful discriminator. The next useful step is a Hejian-visible CPU liveness
check on the B0.F2-only build.

## Constraints And Known Decisions

- Use the Hejian/UVHS runtime flow for board programming and workload writes.
- Do not use Vivado `.ltx` for this path; use Hejian-visible probes/ILA when
  waveform inspection is needed.
- Keep workload writes separate from the minimal download script.
- Do not download timing-negative images.
- Do not kill unrelated PIDs. Only release exact processes created for the
  current stage or explicitly authorized stale UVHS runtime sessions.
- The Vivado 20.2 path was only proven for bounded IP export. It has not been
  proven as a full supported UVHS frontend/backend path.

## Cleanup State

After the 2026-06-05 smoke and host retry, exact runtime PIDs from the stage
were cleaned up. Follow-up checks on the programming machine and open28 showed
no remaining `uv_shell`, `uv_shell_exec`, `fpga-host`, `riscv64-nemu`, or host
timeout process except transient grep checks.
