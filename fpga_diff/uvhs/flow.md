# UVHS Hejian FPGA Debug Flow

Short handoff document for the UVHS + Hejian FPGA + `fpga-host` bring-up.
It collects the current working assumptions, the safe sequence, and the files
that should be reused when moving the flow into minjie's `env-scripts`.

## Current Status

- Runtime host: `root@172.38.11.85`
- FPGA host: `user01@172.38.8.132` (`open28`)
- Vivado: `2024.1`
- UV root: `/home/data/UVHS/2506p4_0210`
- Runtime env must keep `UVHS_LOCAL_ENV=/dev/null`
- PCIe target: Gen3 x4
- DDR target: `b0.F2_FMC3`

What is currently proven:

- Official Hejian 1EP reference image downloads and initializes successfully.
- The current h2c-only `fpga_diff` image also downloads and initializes
  successfully.
- The original no-enum state is no longer the main live blocker after the FPGA
  host rebooted.
- On the FPGA host, the endpoint now enumerates as `10ee:9048` at
  `0000:01:00.0` after safe rescan.
- The current blocker is XDMA BAR discovery / driver acceptance, not basic PCIe
  enumeration.

Latest FPGA-host probe facts:

- `COMMAND` was `0000` before explicit device enable.
- Writing to sysfs `enable` changed `COMMAND` to `0002`.
- `lspci -vv` shows BAR0 and BAR1 present, but the raw BAR identifier reads did
  not yield the XDMA `0x1fc2` / `0x1fc3` signatures.
- `xdma_chr` probe still failed to detect the XDMA config BAR.

## Safe Operating Rules

- Do not reboot the runtime host.
- Do not use PCIe remove/reset/unbind on the FPGA host.
- After each bit download, reboot the FPGA host first, then use only
  `echo 1 > /sys/bus/pci/rescan`.
- Do not manually toggle `SW4/5/6` after DDR writes.
- Do not move to NutShell / DiffTest until standalone XDMA H2C/C2H is
  understood.
- Host-side fpga-host work must use `USE_XDMA_H2C=1`.

## Canonical Debug Sequence

1. Build or refresh the UVHS image from a clean stage.
2. If changing assembly/connector behavior, use `UVHS_STOP_AFTER_GENSCRIPT=1`
   first.
3. Keep the runtime download script alive in `tmux` until the bitstream is
   intentionally unloaded.
4. After download, reboot the FPGA host.
5. Run a safe global rescan on the FPGA host.
6. Run the BAR probe before loading the XDMA driver.
7. If BAR IDs match, load `xdma_chr` and run the bounded H2C/C2H smoke.
8. Only after H2C/C2H is stable, move to `fpga-host` and
   `nutshell-am-hello`.

## Current Decision Gates

### BAR probe

Use this first on the FPGA host:

```sh
sudo bash /home/user01/project/env-scripts/fpga_diff/uvhs/host_bar_peek_after_rescan.sh
```

If the endpoint is visible but BAR reads are blocked by the device command
register, use the explicit enable probe once:

```sh
sudo env XDMA_BAR_PEEK_ENABLE_DEVICE=1 \
  bash /home/user01/project/env-scripts/fpga_diff/uvhs/host_bar_peek_after_rescan.sh
```

Decision:

- If BAR0/BAR1 expose `0x1fc2` and `0x1fc3`, proceed to XDMA smoke.
- If not, keep the current conclusion: the endpoint enumerates, but the XDMA
  config BAR is not being identified by the MinJie driver.

### XDMA smoke

Run only after BAR identification is good:

```sh
sudo bash /home/user01/project/env-scripts/fpga_diff/uvhs/host_xdma_rw_smoke.sh
```

Expected evidence:

- H2C write success (`h2c_rc=0`)
- C2H read success or a bounded timeout with readable packet counters
- `/dev/xdma0_h2c_0` and `/dev/xdma0_c2h_0` present

### fpga-host

Once H2C/C2H is stable, run the host workload with:

- `USE_XDMA_H2C=1`
- non-mempool path
- no extra DDR write outside the fpga-host path

## What Not To Re-try

These experiments were already checked and are not the next local fix:

- Preserving all three F2 PCIe-ish `config_hw -connect_fpga` links.
- HGC-only preservation with APC16 filtered out.

Reason:

- The all-link experiment failed at APC16/PERST pad conflict.
- The HGC-only experiment failed at HGC7 RX pad conflict.
- That makes HGC/APC connector preservation incompatible with the current F2
  endpoint pad assignment path.

## Useful Files

### Evidence and summaries

- `fpga_diff/uvhs/ae_evidence_1ep_no_enum_20260624.md`
- `fpga_diff/logs/ae_no_enum_20260624/README.md`
- `fpga_diff/logs/ae_no_enum_20260624/SHA256SUMS`
- `fpga_diff/uvhs/goal_debug_contract.md`
- `fpga_diff/uvhs/next_bar_debug_runbook_20260624.md`

### FPGA-host helpers

- `fpga_diff/uvhs/run_host_bar_peek_when_reachable.py`
- `fpga_diff/uvhs/host_bar_peek_after_rescan.sh`
- `fpga_diff/uvhs/host_peek_xdma_bars.sh`
- `fpga_diff/uvhs/host_xdma_rw_smoke.sh`
- `fpga_diff/uvhs/host_poll_rootports_safe.sh`

### Runtime / download helpers

- `fpga_diff/uvhs/hwdat_download_once.tcl`
- `fpga_diff/uvhs/hwdat_download_reset_release_keepalive.tcl`
- `fpga_diff/uvhs/ref_1ep_download_hold.tcl`
- `fpga_diff/uvhs/ref_1ep_wait_user_lnk_up.tcl`
- `fpga_diff/uvhs/trigger_ddr_hejian.py`
- `fpga_diff/uvhs/host_uvhs_remote.py`

### Assembly / connector experiments

- `fpga_diff/uvhs/assemble_uvhs.tcl`
- `fpga_diff/uvhs/assign_pin_nutshell_f2.tcl`
- `fpga_diff/uvhs/patch_nutshell_h2c_only.sh`
- `fpga_diff/uvhs/patch_xdma_vivado_lib_pins.sh`
- `fpga_diff/uvhs/patch_uvsyn_shell.sh`

## Porting Notes For minjie `env-scripts`

Keep the same separation of responsibilities:

- runtime host handles download / DDR init / keepalive
- FPGA host handles reboot / rescan / BAR probe / XDMA smoke / fpga-host
- no runtime reboot during the normal loop

Environment variables worth preserving:

- `UVHS_LOCAL_ENV=/dev/null`
- `UV_ROOT=/home/data/UVHS/2506p4_0210`
- `FPGA_HOST_SSH=user01@172.38.8.132`
- `FPGA_HOST_PASS=<secret>`
- `UVHS_HEJIAN_SSH=root@172.38.11.85`
- `UVHS_HEJIAN_PASS=<secret>`
- `XDMA_PCI_ID=10ee:9048`
- `USE_XDMA_H2C=1`

## Current Recommended Next Step

When the FPGA host is stable again:

1. Re-run the safe BAR probe.
2. If the BAR IDs are still wrong, keep the current conclusion and do not
   sink time into HGC/APC connector preservation.
3. If the BAR IDs look correct, move immediately to `host_xdma_rw_smoke.sh`.
4. Only after a clean XDMA smoke, move to `fpga-host` + `nutshell-am-hello`.
