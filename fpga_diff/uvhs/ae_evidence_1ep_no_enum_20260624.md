# UVHS F2 PCIe No-Enumeration Evidence, 2026-06-24

## Summary

Official Hejian 1EP reference RTDB was downloaded to `B0.F2` and initialized successfully on the Hejian runtime host, but the separate FPGA PCIe host did not observe any Xilinx/XDMA PCIe endpoint after a safe bus rescan. Kernel logs also show no PCIe/Xilinx/XDMA/AER activity during the original 2026-06-24 no-enumeration experiments.

This points away from `fpga_diff` RTL/constraints or XDMA driver binding as the primary failure, because the official 1EP reference image also fails to enumerate on the host.

After AE restored the UVHS/runtime state later on 2026-06-24, the same
`fpga_diff` h2c-only image did enumerate on the FPGA host after reboot and a
safe global PCIe rescan:

- `0000:01:00.0 Memory controller [0580]: Xilinx Corporation Device [10ee:9048]`
- Endpoint link: `LnkSta: Speed 8GT/s (ok), Width x4 (ok)`
- BAR0: `85e00000`, 1 MiB; BAR1: `85f00000`, 64 KiB
- No `/dev/xdma*` nodes were present before driver binding.

The current blocker is therefore no longer pure no-enumeration. A rebuilt
`xdma_chr` driver matching host kernel `6.8.0-124-generic` probed the endpoint
but failed to identify the XDMA config BAR:

- `identify_bars: Failed to detect XDMA config BAR`
- `probe of 0000:01:00.0 failed with error -22`
- no `/dev/xdma*` nodes were created

A 2026-06-25 FPGA-host reboot restored the endpoint to a clean enumerated
state:

- boot time: 2026-06-25 14:40:46 CST
- endpoint: `0000:01:00.0 Memory controller [0580]: Xilinx Corporation Device
  [10ee:9048]`
- root path: `0000:00:01.0 -> 0000:01:00.0`
- link: `LnkSta: Speed 8GT/s (ok), Width x4 (ok)`
- BAR0: `0x85e00000-0x85efffff`, 1 MiB
- BAR1: `0x85f00000-0x85f0ffff`, 64 KiB
- command state: `I/O- Mem- BusMaster-`
- no `/dev/xdma*`, no `xdma_chr` in `lsmod`, and no active bound driver

The same 2026-06-25 driver-ID check rules out a missing MinJie device-ID
adaptation:

- host modalias is
  `pci:v000010EEd00009048sv000010EEsd00000007bc05sc80i00`
- current `/lib/modules/6.8.0-124-generic` has only Ubuntu's in-tree
  `drivers/dma/xilinx/xdma.ko`; it has no installed `xdma_chr` module and no
  installed alias matching `10ee:9048`
- MinJie source
  `/home/user01/project/minjie-playground/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma_mod.c`
  contains `PCI_DEVICE(0x10ee, 0x9048)`
- the rebuilt compatible module
  `/home/user01/uvhs-debug-logs/xdma_chr_build_20260624_1738/src/xdma/xdma-chr.ko`
  has `vermagic: 6.8.0-124-generic` and alias
  `pci:v000010EEd00009048sv*sd*bc*sc*i*`

So the remaining driver branch is not "add 10ee:9048 to the ID table". The
next meaningful check is why a matching `xdma_chr` probe maps BAR0/BAR1 but
does not find the XDMA config block.

The MinJie driver source explains exactly what "find the XDMA config block"
means:

- `libxdma.h` defines `XDMA_OFS_INT_CTRL=0x2000`,
  `XDMA_OFS_CONFIG=0x3000`, `IRQ_BLOCK_ID=0x1fc20000`, and
  `CONFIG_BLOCK_ID=0x1fc30000`
- `libxdma.c:is_config_bar()` maps a BAR, requires length at least `0x8000`,
  reads `BAR + 0x2000` and `BAR + 0x3000`, and compares the high 16 bits
  against `0x1fc2` and `0x1fc3`
- `config_bar_num=0` does not skip this test; it only says which BAR to check
  first and still fails if the identifier reads are not present

Therefore the active debug question is whether the current `xdma_ep` bitstream
actually decodes those XDMA identifier registers inside BAR0 or BAR1. The
driver-ID table itself is not the blocker.

This shifts the active debug branch from HGC/APC physical enumeration toward
the generated XDMA BAR/register layout, while keeping the earlier 1EP/no-enum
package as AE history.

## Machines

- Hejian runtime/programming host: `root@172.38.11.85`
- FPGA PCIe host: `user01@172.38.8.132`
- These are separate machines.

## Official 1EP Reference Experiment

Reference source:

- Local reference tree: `/nfs/home/fengkehan/project/env-scripts/uvhs_1ep_test_0417`
- Remote extracted RTDB:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/rtdb_1ep_test_0513`
- Reference bitstream used by RTDB:
  `.../Compile/PnR/B0/F2/vivado/Rundir/Strategy_uv_high_fanout_explore/bitstream/pnr.bin`

Runtime log:

- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/download_1ep_ref_keepalive_20260624_1112/download.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/query_1ep_capture_20260624_115109/query.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/capture_1ep_user_lnk_up_20260624_120208/capture.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/capture_1ep_user_lnk_up_fixed_20260624_1300/capture.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/capture_1ep_user_lnk_up_fixed2_20260624_1306/capture.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/capture_1ep_user_lnk_up_fixed3_20260624_1310/capture.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/wait_user_lnk_up_20260624_1345/wait.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/wait_user_lnk_up_rescan_20260624_1350/wait.log`
- `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/download_hold_1ep_ref_20260624_1425/download_hold.log`

Key runtime observations:

- `event: P0 B0.F2 -> B0.F2 linked up by root`
- `INFO:Done: download success`
- `event: systembus initialize success`
- `event: ps initialize success`
- `event: uhd initialize success`
- `INFO:Done: initialization complete success`
- `INFO: KEEPALIVE_READY official 1ep reference is downloaded and initialized`
- `Total ERROR:  0`
- `END ... rc=0`

The keepalive runtime was later stopped by creating its own stop file; no unrelated process was killed.

The synchronized 14:25 official 1EP download/hold run also completed cleanly:

- Host poll window: 2026-06-24T14:12:32 to 14:22:34 on FPGA host
  `172.38.8.132`
- Safe global rescan in that poll: 14:15:13, before FPGA download
- Hejian official 1EP download success: 14:17:34
- `initialize` success: 14:17:36
- Hold window: 14:17:38 to 14:20:39
- Final rc: `0`, `Total ERROR: 0`

That host poll contains samples throughout the post-initialize hold window.
Representative samples at 14:19:40 and 14:20:33 still show no
`10ee`/Xilinx/XDMA endpoint, no `/dev/xdma*`, root ports `0000:00:1a.0` and
`0000:00:1d.0` at `current_link_width=0` and `power_state=D3hot`, and all
reported PCIe slots with `adapter=0`. The active Realtek contrast port
`0000:00:1c.2` remained `current_link_width=1`.

This 14:25 run does not count as a post-download rescan experiment because the
rescan happened before the FPGA download. It does, however, prove that even
while the official 1EP image is initialized and held active, the host still sees
no adapter presence or link-width transition on the likely x4 root ports.

## Official 1EP UHD Probe/Trigger Evidence

The official 1EP RTDB contains UHD probe/trigger metadata for the XDMA
`user_lnk_up_0` signal:

- `query -capture` reports one enabled B0.F2 capture station:
  `B0.F2_caption_station_0`, clock `clk`, 1 signal.
- `query -trigger -name test` reports channel 0:
  `test.u_design_2_wrapper.user_lnk_up_0`.
- A capture run reached `capture -enable -open_database ... -force` and
  `trigger -force command completed success`.

The UHD capture did not create a `UHD/<database>` waveform directory; `wavegen
-open_database` failed because the database path did not exist. Therefore this
evidence proves the official 1EP probe/trigger is present and armable, but it
does not claim an actual sampled value for `user_lnk_up_0`.

Follow-up corrected-command experiments on 2026-06-24 13:00, 13:06, and 13:10
again downloaded and initialized the official 1EP image successfully, but did
not produce a usable waveform sample. They were stopped at UVHS command-syntax
boundaries (`capture -open_database` requiring `-enable`, trigger/capture
already running, and invalid `trigger -on`). These logs are retained as
tool-usage evidence, not as proof of the `user_lnk_up_0` value.

A later official 1EP natural wait armed the trigger condition
`test.u_design_2_wrapper.user_lnk_up_0 = 1` after a successful download and
initialization. The 15-second wait reported `Conditions Triggered false` and
`Waveform Data Ready false`, and `upload_uhd` refused to upload because the
trigger did not hit.

A follow-up 60-second wait kept the same trigger armed while the FPGA host ran
the safe global PCIe rescan. That run still reported `condition_triggered=0`
and `waveform_ready=0`.

## Host Rescan Evidence

Host evidence directories:

- `/home/user01/uvhs-debug-logs/uvhs-1ep-ref-keepalive-20260624_1114`
- `/home/user01/uvhs-debug-logs/dmesg-check-20260624_1118`
- `/home/user01/uvhs-debug-logs/pcie-rootport-readonly-20260624_1120`
- `/home/user01/uvhs-debug-logs/uvhs-1ep-ref-capture-rescan-20260624_115949`
- Local follow-up read-only capture:
  `fpga_diff/logs/dmesg_check_20260624_1240`
- Local global-rescan before/after capture:
  `fpga_diff/logs/host_rescan_debug_20260624_1255`
- Current `fpga_diff` h2c-only image rescan capture:
  `fpga_diff/logs/h2conly_clean_rescan_20260624_1316`
- Official 1EP natural trigger wait:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/wait_1ep_user_lnk_up_20260624_1345`
- Official 1EP natural trigger wait with host rescan during the wait:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/wait_1ep_user_lnk_up_rescan_20260624_1350`
- Official 1EP synchronized download/hold:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/download_hold_1ep_ref_20260624_1425`
- Host safe rescan after and during those waits:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/post_wait_1ep_rescan_20260624_1342`
  and `fpga_diff/logs/ae_no_enum_20260624/fpga_host/rescan_during_1ep_wait_20260624_1342`
- Host poll covering the synchronized 14:25 hold:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/ref_1ep_hold_hostpoll_20260624_1425`

Safe rescan command used:

```sh
printf 'er0doo$H\n' | sudo -S sh -c 'echo 1 > /sys/bus/pci/rescan'
```

No remove/unbind/port reset was used.

Host observations after rescan:

- `lspci -D -nn | egrep -i '10ee|xilinx|xdma'`: no output
- `/dev/xdma*`: no devices
- `lsmod`: only `xdma_chr` is loaded
- `xilinx_bdfs.txt`: 0 lines
- `journal_pci_since_1110.txt`: 0 lines
- After the later official 1EP UHD run, `journal_pci_filter_since_20min.txt`: 0 lines
- `dmesg` PCI/XDMA/Xilinx filtered logs have 0 entries dated `Jun 24`

`dmesg` only shows boot-time PCIe enumeration from `Wed Jun 17 10:47:57 2026` and XDMA driver module load from `Wed Jun 17 10:49:07 2026`.

A later 2026-06-24 12:41 follow-up read of `dmesg`, `journalctl -k`, `lspci`,
and root-port sysfs showed the same state: no 2026-06-24 PCIe/XDMA/Xilinx/AER
kernel messages, no `10ee` endpoint, no `/dev/xdma*`, and only the already
loaded `xdma_chr` module.

A 2026-06-24 12:49 global PCI bus rescan (`echo 1 > /sys/bus/pci/rescan`) made
no device-list change beyond the timestamped capture output. The kernel journal
since 12:45 remained empty, and the dmesg tail still only contained boot-time
PCIe enumeration plus the 2026-06-17 XDMA module-load messages.

After downloading the current `fpga_diff` h2c-only clean image at 2026-06-24
13:21, a safe global rescan again made no PCI device-list change and produced no
new PCIe/XDMA/Xilinx/AER kernel messages. The host still had no `10ee` endpoint
and no `/dev/xdma*`.

After the official 1EP `user_lnk_up_0` natural-wait experiment, another safe
rescan produced no `lspci` diff, no `10ee`/Xilinx/XDMA endpoint, no
`/dev/xdma*`, and no kernel journal entries since 13:35. During a second
60-second `user_lnk_up_0` wait, the same safe rescan produced no device-list
change and no kernel journal entries since 13:40.

During the synchronized 14:25 official 1EP download/hold run, host polling
continued across the 14:17:38 to 14:20:39 hold window. Samples in that interval
still had empty `10ee`/Xilinx/XDMA `lspci` output, no `/dev/xdma*`,
`0000:00:1a.0 current_link_width=0`, `0000:00:1d.0 current_link_width=0`, and
slot `adapter=0`. The final `sudo lspci -vv` snapshot again reported
`SltSta: PresDet-` for `0000:00:1a.0` and `0000:00:1d.0`, while the Realtek
contrast port `0000:00:1c.2` remained `PresDet+` and width x1.

## AE Restore / Current Enumeration Evidence

After AE restored the device/runtime state, a read-only UVHS query succeeded:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/uv_runtime_readonly_after_ae_restore_20260624_172759/`
- Remote source:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/logs/uv_runtime_readonly_after_ae_restore_20260624_172759/`
- `uv_shell` reported `[LIC-004] INFO: This program is authorized for 28 more days before expiration.`
- `query -fpgas -all` completed with `Total ERROR: 0`.

The h2c-only `fpga_diff` image was then downloaded in a tmux keepalive session:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/h2conly_keepalive_20260624_173006/`
- Remote source:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-refclkskip-genscript-fmc3x4-20260623_1242/logs/h2conly_keepalive_20260624_173006/`
- Runtime observations:
  - `INFO:Done: download success`
  - `DOWNLOAD_DONE`
  - `event: DDR4 initialize success`
  - `INFO:Done: initialization complete success`
  - `INITIALIZE_DONE`
  - `B0.F2 ... link up root`
  - `KEEPALIVE_READY h2conly downloaded initialized reset released`

The FPGA host was rebooted after download and then safely rescanned:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/h2conly_after_host_reboot_rescan_20260624_172909/`
- Remote source:
  `/home/user01/uvhs-debug-logs/h2conly_after_host_reboot_rescan_20260624_172909/`
- `summary.txt`: `rescan_exit=0`, `xilinx_lines=1`, `xdma_devs=0`
- `lspci`: `0000:01:00.0 Memory controller [0580]: Xilinx Corporation Device [10ee:9048]`
- Current boot kernel log places the endpoint under CPU root port
  `0000:00:01.0`, not under the earlier no-enum branch's candidate ports
  `0000:00:1a.0` or `0000:00:1d.0`:
  - `pci 0000:00:01.0: [8086:460d] type 01 class 0x060400 PCIe Root Port`
  - `pci 0000:00:01.0: PCI bridge to [bus 01]`
  - `pci 0000:01:00.0: [10ee:9048] type 00 class 0x058000 PCIe Endpoint`
  - `pci 0000:01:00.0: BAR 0 [mem 0x85e00000-0x85efffff]`
  - `pci 0000:01:00.0: BAR 1 [mem 0x85f00000-0x85f0ffff]`
- Endpoint `lspci -vv`:
  - `Region 0: Memory at 85e00000 ... [disabled] [size=1M]`
  - `Region 1: Memory at 85f00000 ... [disabled] [size=64K]`
  - `LnkCap: ... Speed 8GT/s, Width x4`
  - `LnkSta: Speed 8GT/s (ok), Width x4 (ok)`
- No XDMA driver was bound and `/dev/xdma*` did not exist.

A matching `xdma_chr` was rebuilt on the host:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/xdma_chr_build_20260624_1738/`
- Remote source:
  `/home/user01/uvhs-debug-logs/xdma_chr_build_20260624_1738/`
- `modinfo`: alias includes `pci:v000010EEd00009048...`
- `vermagic`: `6.8.0-124-generic SMP preempt mod_unload modversions`

Driver probe failed:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/xdma_chr_load_20260624_1738/`
- Remote source:
  `/home/user01/uvhs-debug-logs/xdma_chr_load_20260624_1738/`
- Before probe: `01:00.0 Memory controller: Xilinx Corporation Device 9048`
- After probe: no `/dev/xdma*`
- Kernel log:
  - `map_single_bar: BAR0 ... length=1048576`
  - `map_single_bar: BAR1 ... length=65536`
  - `identify_bars: Failed to detect XDMA config BAR`
  - `map_bars: Failed to identify bars`
  - `probe of 0000:01:00.0 failed with error -22`

The direct H2C/C2H host test was not run because no XDMA character devices were
created. Running `fpga-host` in this state would only fail before exercising the
DDR path.

A follow-up forced-config-BAR probe attempt is retained as negative evidence:

- Local copy:
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/xdma_rw_try_20260624_175222/`
- Remote source:
  `/home/user01/uvhs-debug-logs/xdma_rw_try_20260624_175222/`
- The endpoint was present before probe:
  `0000:01:00.0 Memory controller [0580]: Xilinx Corporation Device [10ee:9048]`
- `xdma_chr` was loaded with `config_bar_num=0`.
- No `/dev/xdma*` nodes were created.
- After the failed probe, `lspci` reported the endpoint as `rev ff`; sysfs
  reads were inconsistent (`current_link_speed=Unknown`, `current_link_width=63`).

This forced probe did not produce usable H2C/C2H devices and appears to leave
the endpoint in a bad config-read state. Do not repeat driver-probe experiments
on that image without a fresh bit download followed by FPGA-host reboot/rescan.

## Root Port Read-Only Evidence

Read-only host PCIe sysfs/lspci snapshot:

- `/home/user01/uvhs-debug-logs/pcie-rootport-readonly-20260624_1120`
- `/home/user01/uvhs-debug-logs/platform_readonly_20260624_1350`

Key observations:

- `0000:00:1a.0`: max x4 / 16 GT/s capable, current link width `0`
- `0000:00:1d.0`: max x4 / 8 GT/s capable, current link width `0`
- `0000:00:1c.2`: current link width `1`, has the only downstream device `0000:04:00.0` Realtek `10ec:8125`
- No Xilinx `10ee` device appears anywhere in `/sys/bus/pci/devices` or `lspci`
- `/sys/bus/pci/slots` reports the hotplug slots for `0000:01:00`,
  `0000:03:00`, and `0000:05:00` powered (`power=1`) but with
  `adapter=0`; the x4-capable root ports `0000:00:1a.0` and `0000:00:1d.0`
  are runtime-suspended with no downstream active children.
- `sudo lspci -vv` reports `0000:00:1a.0` and `0000:00:1d.0` as `LnkSta:
  Speed 2.5GT/s (downgraded), Width x0 (downgraded)`, `DLActive-`, and
  `SltSta: PresDet-`. The active Realtek port `0000:00:1c.2` is the contrast
  case: `Width x1`, `DLActive+`, and `PresDet+`.
- The 13:47 platform inventory identifies the host board as `ASUSTeK COMPUTER
  INC. PRIME Z690-P WIFI D4`. `dmidecode` marks the reported PCIe slots as
  `Current Usage: Available`, and `/sys/bus/pci/slots` reports the powered
  buses `0000:01:00`, `0000:03:00`, and `0000:05:00` with `adapter=0`.
  Root ports `0000:00:1a.0` and `0000:00:1d.0` are still x4-capable but idle:
  `current_link_width=0`, `power_state=D3hot`.

The later 2026-06-24 11:59 host rescan after another official 1EP download
showed the same state: `0000:00:1a.0 current_link_width=0`,
`0000:00:1d.0 current_link_width=0`, and no `10ee` endpoint.

This indicates the FPGA endpoint is not forming a PCIe link visible to the Linux host.

## Connector / Assembly Evidence

Read-only official 1EP RTDB queries show that the reference design uses `B0.F2`
and that `B0.F2_FMC3` is present as a `DAUGHTER_CARD`, but the PCIe-related
connectors used by the reference pin assignment remain disconnected in the RTDB:

- `B0.F2_HGC7`: `NONE`
- `B0.F2_HGC6`: `NONE`
- `B0.F2_APC16`: `NONE`

The official 1EP `assign_pin.tcl` maps the PCIe refclk and x4 lanes to
`b0.F2_HGC7`, optional x8 lanes to `b0.F2_HGC6`, and PERST to
`b0.F2_APC16`. The extracted official RTDB copy of `1B_4F_HGC_assemble.tcl`
has the corresponding `config_hw -connect_fpga` lines commented:

- `#config_hw -connect_fpga {b0.F2_APC16 b0.F3_APC12} -cable UV_IOC_500`
- `#config_hw -connect_fpga {b0.F2_HGC6 b0.F3_HGC6} -cable UV_HGC_1000`
- `#config_hw -connect_fpga {b0.F2_HGC7 b0.F3_HGC7} -cable UV_HGC_1000`

The UVHS installation's recommended `U2_with_HGC_standard` assembly file has
those three lines enabled, and the adjacent extracted `.bak` has the same
enabled form. The current `fpga_diff/uvhs/assemble_uvhs.tcl` also treats
`b0.F2_APC16`, `b0.F2_HGC6`, and `b0.F2_HGC7` as target-exclusive connectors
and filters active `connect_fpga` lines touching them in multi-FPGA mode.

This debug branch was tested with fresh h2c-only generated projects and
`UVHS_STOP_AFTER_GENSCRIPT=1`:

- Full HGC/APC preservation:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/uvhs_build_h2conly_pcieconn-genscript4-20260624_145828.log`
- Local evidence copy:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/pcieconn_genscript4_20260624_145828/`
- Generated overlay made all three lines active:
  `b0.F2_APC16-b0.F3_APC12`, `b0.F2_HGC6-b0.F3_HGC6`, and
  `b0.F2_HGC7-b0.F3_HGC7`.
- Frontend failed before script generation completed:
  `assign_pin -port fpga_top_debug.pcie_ep_perstn -connector b0.F2_APC16 -index 118`
  reported `[SYS-202] ERROR: FPGA b0.f2 pin R11 is illegal for assign_pin since it is already connected to another FPGA pin.`

A narrower HGC-only experiment filtered APC16 but left HGC6/HGC7 active:

- Remote log:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/uvhs_build_h2conly_pcieconn-hgconly-genscript2-20260624_150304.log`
- Local evidence copy:
  `fpga_diff/logs/ae_no_enum_20260624/hejian/pcieconn_hgconly_genscript2_20260624_150304/`
- PERST assignment then passed, but the first x4 RX lane failed:
  `assign_pin -port fpga_top_debug.pci_ep_rxp[0] -connector b0.F2_HGC7 -index 16`
  reported `[SYS-202] ERROR: FPGA b0.f2 pin U2 is illegal for assign_pin since it is already connected to another FPGA pin.`

Conclusion from these two generation experiments: enabling the F2 HGC/APC
`connect_fpga` lines is not a viable local fix for host PCIe enumeration in
this flow. Those assembly links occupy the same F2 pads that the PCIe endpoint
must assign as external refclk, lanes, and PERST. The original filtering of
target-exclusive HGC/APC links is therefore consistent with preserving external
PCIe endpoint pins, not an obvious cause of no-enumeration.

## Why This Is Not Just Current fpga_diff DRC/Timing

Current `fpga_diff` h2c-only no-probe image:

- Workdir:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-refclkskip-genscript-fmc3x4-20260623_1242`
- Bitstream:
  `.../hw.dat/Compile/PnR/B0/F2/vivado/Rundir/Strategy_uv_placer_extra_timing_opt/bitstream/pnr.bit`
- Download log:
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-refclkskip-genscript-fmc3x4-20260623_1242/logs/download_h2conly_clean_20260624_1314/download.log`

DRC:

- `pnr_drc_ipchk.rpt`: `NSTD-1 UCIO-1`, violations found: `0`

Timing:

- `pnr_timing_summary.rpt`: `WNS(ns) 0.083`, `TNS(ns) 0.000`, 0 failing endpoints
- `All user specified timing constraints are met.`

Generated PCIe pin constraints include:

- Refclk: `AC11/AC10`
- PERST: `R11`
- Lanes x4: `U2/U1`, `V4/V3`, `W2/W1`, `Y4/Y3`, TX `W7/W6`, `Y9/Y8`, `AA7/AA6`, `AB9/AB8`
- Refclk ports have `IO_BUFFER_TYPE NONE` and `CLOCK_BUFFER_TYPE NONE`

Runtime download of this image succeeded:

- `download -target dut -board P0 B0.F2 -> B0.F2 by root success`
- `P0 B0.F2 -> B0.F2 linked up by root`
- `DDR4 initialize success`
- `Done: initialization complete success`
- `generic hw.dat download complete`

The one logged `Total ERROR: 1` in this run is from a pre-download
`query -clock` command returning `no clock data item found`; it did not stop
download or initialization (`rc=0`).

The official 1EP reference uses the same F2 HGC7/APC16 pin indexes for refclk, x4 lanes, and PERST:

- refclk HGC7 indexes `29/30`
- PERST APC16 index `118`
- lanes 0-3 HGC7 indexes `16/17`, `13/14`, `4/5`, `1/2`, TX `35/36`, `32/33`, `23/24`, `20/21`
- `pre_place.tcl` fixes its XDMA hard block to `PCIE4CE4_X0Y6`

## Conclusion For AE / Hejian

With both:

1. our timing/DRC-clean h2c-only image, and
2. the official Hejian 1EP reference image

the FPGA host does not enumerate any Xilinx/XDMA endpoint after safe rescan. The host also emits no relevant PCIe/AER/Xilinx/XDMA kernel messages on 2026-06-24. Root-port readout shows x4-capable ports with link width 0 and PCIe slot presence detect negative. The official 1EP `user_lnk_up_0` signal also did not trigger during natural wait windows, including one where the host performed safe global rescan while the trigger was armed.

Current evidence supports a platform-side PCIe link recovery / cabling / host
slot / hotplug / board state issue rather than a local `fpga_diff` RTL, Vivado
DRC, or XDMA driver bind issue. The post-restore boot shows the working
endpoint path is `0000:00:01.0 -> 0000:01:00.0`; earlier no-enum readouts did
not capture this root port as the primary candidate, so AE should include
`0000:00:01.0` when checking physical slot/BIOS/link-retrain state.

AE's later restoration changed the observed state: the h2c-only `fpga_diff`
image now enumerates as `10ee:9048` at Gen3 x4 after host reboot/rescan. The
remaining local blocker is XDMA driver BAR discovery. The driver can bind to the
PCI ID, maps BAR0/BAR1, but does not find the XDMA config register block. That
points to one of:

- generated XDMA IP BAR/register layout mismatch,
- wrong BAR selected/exposed by the generated endpoint,
- endpoint config space present but XDMA AXI-lite/config aperture not decoding,
- or a bitstream/platform state issue after the first driver probe.

Recommended AE-side next checks:

- Confirm the physical PCIe cable/slot path between `B0.F2` and FPGA host
  `user01@172.38.8.132`.
- Confirm which host root port should receive the endpoint and why its `current_link_width` is 0.
- Confirm whether a platform-specific power-cycle/link-retrain procedure is required after UVHS download.
- If port reset/remove is required, perform it under AE guidance; it was intentionally not used here to avoid host instability.
- For the post-restore enumerating case, confirm the expected BAR layout for
  `10ee:9048` and which BAR should contain the XDMA config block.

## Current Live State, 2026-06-24 23:22 CST

The post-restore h2c-only runtime is still alive on the Hejian runtime host in
tmux session `uvhs_h2conly_keepalive_20260624_173006`. Its log shows
`DDR4 initialize success`, reset release on `rstn_sw4/5/6`, `B0.F2 link up`,
and `KEEPALIVE_READY h2conly downloaded initialized reset released`.

The FPGA host `172.38.8.132` is currently unreachable from both the local
workspace machine and the Hejian runtime host:

- local ping: 100% packet loss
- local TCP/22: timeout
- runtime host ping: 100% packet loss
- runtime host TCP/22: timeout

This blocks live `lspci`, `dmesg -T`, raw BAR peeking, driver reload, and
`fpga-host` H2C/C2H testing for the moment. No runtime reboot or PCIe
remove/reset/unbind was attempted.

Latest live status evidence:

```text
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2018/runtime_reachability.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2041/reachability_local.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2049/network_local.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2100/reachability_local.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_210753/reachability_and_runtime.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2311/reachability_local.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2311/runtime_keepalive_and_host.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2327/runtime_network_readonly.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_232424/local_reachability.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_232424_runtime/runtime_keepalive_and_host.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_233010/local_reachability.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_233010_runtime/runtime_keepalive_and_host.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_234119/status.txt
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_234938_runtime/runtime_keepalive_and_host.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_235423/local_reachability.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_235423/run_helper_unreachable.log
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_235859_runtime/runtime_keepalive_and_host.log
```

That log confirms `root@172.38.11.85` is reachable, the keepalive tmux session
is still present, and the runtime host itself also cannot ping or open TCP/22
to `172.38.8.132`. A refreshed local check at 20:43 CST again found the runtime
host reachable (`ping` rc=0, TCP/22 rc=0) and FPGA host `172.38.8.132`
unreachable (`ping` rc=1, TCP/22 timeout rc=124). A read-only SSH check to the
runtime host at 20:48 CST showed tmux session
`uvhs_h2conly_keepalive_20260624_173006` still present.

A later local network check at 20:49 CST routed `172.38.8.132` via
`172.19.20.254` and still timed out on TCP/22, while the runtime host TCP/22
remained reachable. A 21:00 CST refresh showed the same: runtime host ping/TCP
OK, FPGA host ping loss and TCP/22 timeout.

A 21:07 CST refresh archived the full current state in
`current_status_20260624_210753`: local-to-FPGA-host ping and TCP/22 failed,
local-to-runtime ping and TCP/22 succeeded, runtime-to-FPGA-host ping and
TCP/22 failed, and runtime tmux session
`uvhs_h2conly_keepalive_20260624_173006` still printed
`KEEPALIVE_READY h2conly downloaded initialized reset released`. No runtime
reboot and no PCIe remove/reset/unbind were performed.

A 21:38/21:43 CST refresh archived the same live state in
`current_status_20260624_213835`: local-to-runtime ping/TCP succeeded,
local-to-FPGA-host ping/TCP failed, direct SSH to the FPGA host timed out
during banner exchange, runtime-to-FPGA-host ping/TCP failed, and the runtime
tmux session still printed
`KEEPALIVE_READY h2conly downloaded initialized reset released`. No runtime
reboot and no PCIe remove/reset/unbind were performed.

A 21:48/21:53 CST refresh archived the same live state in
`current_status_20260624_214824`: runtime remains reachable and the h2c-only
keepalive session still prints `KEEPALIVE_READY`; FPGA host `172.38.8.132`
still has ping loss and TCP/22 timeout from both local and runtime hosts.

A 22:03/22:08 CST refresh archived the same live state in
`current_status_20260624_220334`: runtime host `172.38.11.85` remains
reachable, tmux session `uvhs_h2conly_keepalive_20260624_173006` is still
alive, and FPGA host `172.38.8.132` remains unreachable from both the local
workspace and the runtime host. Local SSH timed out during banner exchange;
runtime-side ping had 100% packet loss and runtime-side TCP/22 returned
`tcp22_not_open`. No runtime reboot and no PCIe remove/reset/unbind were
performed.

A 22:18/22:23 CST refresh archived the same state in
`current_status_20260624_221816`: local SSH to FPGA host still timed out during
banner exchange, local ping had 100% packet loss, and local TCP/22 returned
`tcp22_not_open`. Runtime host `172.38.11.85` remained reachable, tmux session
`uvhs_h2conly_keepalive_20260624_173006` remained alive, runtime-side ping to
`172.38.8.132` had 100% packet loss, and runtime-side TCP/22 returned
`fpga_host_tcp22_not_open`. Runtime routing to the host remained via
`172.38.11.254` on `em1`. No runtime reboot and no PCIe remove/reset/unbind
were performed.

A 22:36/22:41 CST refresh archived the same state in
`current_status_20260624_2240`: local ping/TCP to the runtime host succeeded,
local ping/TCP to FPGA host `172.38.8.132` failed, and direct SSH still timed
out during banner exchange. The verbose SSH log shows the local client using
`/usr/bin/sss_ssh_knownhostsproxy -p 22 172.38.8.132`; therefore the
`UNKNOWN port 65535` text is from the local SSH proxy path, not from the FPGA
host changing its SSH port. Runtime host `172.38.11.85` remained reachable, tmux
session `uvhs_h2conly_keepalive_20260624_173006` remained alive, and its pane
still printed `KEEPALIVE_READY h2conly downloaded initialized reset released`.
Follow-up checks in the same evidence directory show direct SSH with
`ProxyCommand=none` also times out to `172.38.8.132:22`; the local name
`open28` has no DNS resolution in this workspace; and the runtime host routes
to `172.38.8.132` via `172.38.11.254` on `em1` but still sees 100% ping loss
and `fpga_host_tcp22_not_open`.
No runtime reboot and no PCIe remove/reset/unbind were performed.

A 22:48/22:53 CST refresh archived the same state in
`current_status_20260624_2252`: runtime host ping/TCP succeeded, FPGA host
`172.38.8.132` still had 100% ping loss and direct SSH/TCP port 22 timeout from
the local workspace, and the runtime host still routed to `172.38.8.132` via
`172.38.11.254` on `em1` but could not ping or open TCP/22. The runtime tmux
keepalive session still printed
`KEEPALIVE_READY h2conly downloaded initialized reset released`. No runtime
reboot and no PCIe remove/reset/unbind were performed.

A 23:00 CST refresh archived the latest local state in
`current_status_20260624_2258`: local ping and TCP/22 to the runtime host
`172.38.11.85` succeeded, but a short direct SSH/tmux probe did not return
within the 6-second timeout. FPGA host `172.38.8.132` still had 100% ping loss,
TCP/22 timeout, and direct SSH timeout. A local evidence search for
`10ee:0948` found no matches; the enumerated endpoint ID captured in this
package is `10ee:9048`.

A 23:11/23:16 CST refresh archived the current live state in
`current_status_20260624_2311`: local ping/TCP to the runtime host
`172.38.11.85` still succeeded, local ping/TCP to FPGA host `172.38.8.132`
still failed, and the runtime host itself also saw 100% ping loss plus TCP/22
timeout to `172.38.8.132`. The runtime tmux session
`uvhs_h2conly_keepalive_20260624_173006` remained alive. Its captured pane
still showed B0.F2 `link up`, DDR4 on `FMC3`, SW4/SW5/SW6 released to `1`, and
`KEEPALIVE_READY h2conly downloaded initialized reset released`. No runtime
reboot and no PCIe remove/reset/unbind were performed.

A 23:22 CST runtime-side network refresh was archived in
`current_status_20260624_2327`: `getent hosts open28 172.38.8.132` returned no
host entry within the 3-second timeout, route lookup still sends
`172.38.8.132` via `172.38.11.254` on `em1`, `ipmitool` is not installed on the
runtime host, runtime TCP/22 to `172.38.8.132` still timed out, and runtime ping
still had 100% packet loss. This did not change runtime, FPGA, or PCIe state.

A final short local reachability probe in `current_status_20260624_2334` again
found FPGA host `172.38.8.132` unreachable: ping had 100% packet loss,
TCP/22 timed out, and direct SSH to port 22 timed out. Runtime host
`172.38.11.85` TCP/22 remained open.

A refreshed local/runtime pair in `current_status_20260624_232424` and
`current_status_20260624_232424_runtime` again found the same state: local
ping/TCP22/SSH to FPGA host failed, runtime host remained reachable, runtime
tmux `uvhs_h2conly_keepalive_20260624_173006` remained alive, and runtime-side
ping/TCP22 to FPGA host still failed. The runtime keepalive pane still printed
`KEEPALIVE_READY h2conly downloaded initialized reset released`.

Another refreshed local/runtime pair in `current_status_20260624_233010` and
`current_status_20260624_233010_runtime` again found the same state:
local ping/TCP22/SSH to FPGA host failed, runtime host remained reachable,
runtime-side ping/TCP22 to FPGA host still failed, and the runtime keepalive
pane still printed `KEEPALIVE_READY h2conly downloaded initialized reset
released`.

A 23:41 CST local refresh was archived in `current_status_20260624_234119`.
It again found runtime host `172.38.11.85` reachable by ping and TCP/22, while
FPGA host `172.38.8.132` had 100% ping loss, TCP/22 timeout, and direct
`ProxyCommand=none` SSH timeout. Therefore live `lspci`, kernel-log capture,
raw BAR read, driver reload, and `fpga-host` H2C/C2H tests are still blocked by
FPGA-host reachability, not by the runtime download session. `10ee:0948`
remains a typo/search term only; the captured Xilinx endpoint ID is
`10ee:9048`, and PCIe enumeration must be checked on FPGA host
`user01@172.38.8.132`, not on the Hejian runtime host.

A 23:50 CST runtime-side refresh was archived in
`current_status_20260624_234938_runtime`. It confirms the runtime tmux session
`uvhs_h2conly_keepalive_20260624_173006` is still alive, its pane still reports
DDR4 on `FMC3` and `KEEPALIVE_READY h2conly downloaded initialized reset
released`, and the runtime host still cannot ping or open TCP/22 to FPGA host
`172.38.8.132`.

A 23:55/23:58 CST refresh was archived in `current_status_20260624_235423` and
`current_status_20260624_235859_runtime`. Local-to-runtime ping/TCP22 still
succeeded; local-to-FPGA-host ping/TCP22/direct SSH still timed out; runtime
keepalive still printed DDR4 `FMC3` and `KEEPALIVE_READY`; and runtime-to-FPGA
host ping/TCP22 still failed. The BAR helper was also exercised with a 3-second
pre-reboot reachability gate and returned `RESULT=host_unreachable_before_reboot`
with rc `2`, confirming it does not issue a host reboot while TCP/22 is down.

Local XDMA generated-parameter inspection gives the expected BAR layout for the
current design branch:

- `AXILITE_MASTER_CONTROL=3'H4`, `AXILITE_MASTER_APERTURE_SIZE=8'H0D`
- `XDMA_CONTROL=3'H4`, `XDMA_APERTURE_SIZE=8'H09`
- `BARLITE1=1`, `BARLITE_EXT_PF0=6'H01`, `BARLITE_INT_PF0=6'H02`
- `PF0_BAR0_APERTURE_SIZE=8'H0A`, `PF0_BAR0_CONTROL=3'H4`
- `PF0_BAR1_CONTROL=3'H0`

Interpretation: host AXI-Lite master should occupy BAR0, while the XDMA control
block should be visible through BAR1. Therefore the previous driver failure is
not explained by a simple "no XDMA control BAR requested" configuration. The
next required check, once FPGA host `user01@172.38.8.132` is reachable, is a raw
read of BAR0/BAR1 offsets `0x2000` and `0x3000` before loading `xdma_chr`;
BAR1 should return the XDMA IRQ/config identifiers `0x1fc2....` and
`0x1fc3....`.

Current `fpga_diff/src/tcl/common/xdma_ep.tcl` intentionally exposes the
host-to-FPGA difftest register path through XDMA `M_AXI_LITE`, not XDMA
`S_AXI_LITE`: `M_AXI_LITE` is connected to the external `XDMA_AXI_LITE` BD
port and assigned a 1 MiB address segment. That matches the user's note that
the AXI-Lite BAR is the difftest register file rather than a simple BAR0 test
window. It is separate from the XDMA driver's config-BAR discovery, which reads
the XDMA internal register block identifiers in the PCIe BAR selected by
`XDMA_CONTROL`.

Generated XDMA core source makes this distinction explicit:

- `AXILITE_MASTER_CONTROL=4` selects BAR0 for the host-to-FPGA AXI-Lite master
  window (`XDMA_AXI_LITE`, difftest register file).
- `XDMA_CONTROL=4` with `BARLITE1=1` selects BAR1 for the XDMA internal config
  block.
- The core's generated `C_PCIEBAR_LEN_1` path gives BAR1 the XDMA aperture when
  both controls are 4, which matches the enumerated BAR1 size of 64 KiB.

Therefore the driver failure is now narrowed to whether the enumerated BAR1
actually returns the XDMA config identifiers at runtime, not whether the
difftest register file is on BAR0.

A read-only Vivado 2024.1 extraction of the currently downloaded h2c-only
`xdma_ep.dcp` confirms the same conclusion at checkpoint level. Evidence:

```text
fpga_diff/logs/ae_no_enum_20260624/hejian/current_h2conly_dcp_props_20260624_212411/current_h2conly_dcp_props/summary.md
```

The remote DCP SHA256 is
`2819594d7e7d057cb55483c5959111eef81ac473b0b05341883d691f947142f5`. The XDMA
core cell reports `PF0_DEVICE_ID=0x9048`, `BARLITE1=1`,
`BARLITE_EXT_PF0=0x01`, `BARLITE_INT_PF0=0x02`, and DMA H2C/C2H channels
enabled. The PCIE4CE4 hard block reports BAR0 as 1 MiB and BAR1 as 64 KiB,
matching the FPGA-host enumeration evidence. This DCP check performed no
synthesis, implementation, download, PCIe rescan, driver load, or port reset.

An additional local Vivado IP export using `XDMA_BAR_LAYOUT=default` completed
successfully in `/tmp/fpga_diff_uvhs_barlayout_default_ipcheck`. Its generated
XCI/SV parameters are effectively the same for the relevant BAR controls:

- `axilite_master_en=true`, `xdma_en=true`, `xdma_axilite_slave=false`
- `bar_indicator=BAR_0`, `bar0_indicator=1`, `bar1_indicator=0`
- `AXILITE_MASTER_CONTROL=0x4`, `XDMA_CONTROL=0x4`
- `BARLITE1=1`, `BARLITE_EXT_PF0=0x01`, `BARLITE_INT_PF0=0x02`
- `PF0_DEVICE_ID=0x9048`

This makes "explicit layout differs from Vivado default" unlikely as the cause
of the driver BAR-identification failure. The next discriminating test remains
raw BAR reads on the FPGA host before loading the driver.

A follow-up local Vivado IP export using experimental
`XDMA_BAR_LAYOUT=bar1-config` also completed synthesis in
`/tmp/fpga_diff_uvhs_barlayout_bar1_config_ipcheck`, but it is not a viable
fix candidate:

- `xdma_axilite_slave=true` was accepted by the XCI, which also exposes
  unconnected slave-interface implications for the current BD.
- `bar_indicator` remained `BAR_0` and is marked `enabled=false`.
- `pf0_msix_cap_table_bir` and `pf0_msix_cap_pba_bir` are marked
  `enabled=false`.
- The generated relevant controls still match the default branch:
  `AXILITE_MASTER_CONTROL=0x4`, `XDMA_CONTROL=0x4`, `BARLITE1=1`,
  `BARLITE_EXT_PF0=0x01`, `BARLITE_INT_PF0=0x02`.

This rules out a simple Tcl override of disabled BAR-selection parameters as
the next local fix. The useful next hardware test remains raw BAR0/BAR1 reads
at offsets `0x2000` and `0x3000` on FPGA host `user01@172.38.8.132` after a
fresh bit download plus FPGA-host reboot/rescan, before loading `xdma_chr`.

A second experimental local Vivado IP export using
`XDMA_BAR_LAYOUT=driver-config-bar` completed in
`/tmp/fpga_diff_uvhs_barlayout_driver_config_ipcheck_20260624_222340`.
Evidence:

```text
fpga_diff/logs/ae_no_enum_20260624/local/xdma_bar_layout_driver_config_20260624_222340
```

This export also does not produce a distinct actionable BAR layout:

- `xdma_axilite_slave=true` and `axilite_master_en=true` are both present.
- Top-level XCI still has `pf0_bar0_enabled=true`, `pf0_bar1_enabled=false`,
  `bar_indicator=BAR_0` with `enabled=false`, `bar0_indicator=1`, and
  `bar1_indicator=0`.
- Generated controls still match the current branch:
  `AXILITE_MASTER_CONTROL=0x4`, `XDMA_CONTROL=0x4`, `BARLITE1=1`,
  `BARLITE_EXT_PF0=0x01`, `BARLITE_INT_PF0=0x02`.
- Generated SV still has `PF0_BAR0_CONTROL=3'H4`,
  `PF0_BAR1_CONTROL=3'H0`, `PF0_BAR0_APERTURE_SIZE=8'H0A`, and
  `PF0_BAR1_APERTURE_SIZE=8'H05`.

Therefore `driver-config-bar` is in the same relevant class as
`bar1-config`: it does not provide a new local fix candidate before the raw
BAR identifier read.

The live assembly/connector branch remains narrowed. The local overlay
`fpga_diff/uvhs/assemble_uvhs.tcl` already contains an opt-in
`UVHS_KEEP_PCIE_TARGET_CONNECTORS=1` path that can inject or preserve the three
F2 PCIe-ish `connect_fpga` lines, but the two fresh
`UVHS_STOP_AFTER_GENSCRIPT=1` experiments prove that path conflicts with the
external PCIe endpoint pad assignments in this flow. The all-link experiment
failed at APC16/PERST pin `R11`; the HGC-only experiment failed at HGC7/RX lane
pin `U2`. Therefore the evidence does not support changing the default assembly
filtering as the next debug step.

The official reference assembly supports the same conclusion. Current
`1B_4F_HGC_assemble.tcl` comments out the three F2 PCIe-ish connector links,
while `1B_4F_HGC_assemble.tcl.bak` enables them:

- `config_hw -connect_fpga {b0.F2_APC16 b0.F3_APC12} -cable UV_IOC_500`
- `config_hw -connect_fpga {b0.F2_HGC6 b0.F3_HGC6} -cable UV_HGC_1000`
- `config_hw -connect_fpga {b0.F2_HGC7 b0.F3_HGC7} -cable UV_HGC_1000`

Preserving those lines in the `fpga_diff` flow fails before implementation, and
the same h2c-only image later enumerated at Gen3 x4 without preserving them.
This makes HGC/APC filtering an unlikely live root cause for the current XDMA
driver/BAR issue.

Remote `XDMA_LEGACY_BAR_LAYOUT=1` / `XDMA_BAR_LAYOUT=default` generation was
also checked on the Hejian runtime host:

```text
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-legacybar-genscript-fmc3x4-20260624_182532
```

That run stopped at `UVHS_STOP_AFTER_GENSCRIPT`; it was not implemented,
downloaded, or tested on hardware. Its exported XCI still has top-level
`xdma_axilite_slave=false`, `pf0_bar1_enabled=false`,
`bar_indicator=BAR_0`, `bar1_indicator=0`, generated `PF0_BAR1_CONTROL=0x0`,
and generated `BARLITE1=1`, `BARLITE_EXT_PF0=0x01`,
`BARLITE_INT_PF0=0x02`. The generated nested PCIE4C IP still propagates
`pf0_bar1_enabled=true` / `PF0_BAR1_CONTROL=0x4`, same class as the current DCP
evidence. Therefore this legacy/default layout does not yet provide a distinct
fix candidate; the discriminating check is still the raw BAR identifier read.

The raw BAR offsets match the MinJie XDMA driver source:

- `XDMA_OFS_INT_CTRL = 0x2000`, expected high16 `IRQ_BLOCK_ID = 0x1fc2`.
- `XDMA_OFS_CONFIG = 0x3000`, expected high16 `CONFIG_BLOCK_ID = 0x1fc3`.
- `XDMA_BAR_SIZE = 0x8000`, so BAR1's enumerated 64 KiB aperture is large
  enough for both probes if the XDMA config block is actually decoded there.

Driver source inspection also explains why the previous forced
`config_bar_num=0` probe is not a useful bypass. In
`dma_ip_drivers/XDMA/linux-kernel/xdma/libxdma.c`, `map_bars()` still calls
`is_config_bar()` for the requested BAR, and `is_config_bar()` reads the same
`0x2000` and `0x3000` identifiers before accepting it as the config BAR. Thus
forcing a BAR number cannot work unless that BAR already returns the XDMA
identifier registers. The next discriminating evidence is therefore the raw
BAR read before loading `xdma_chr`.

2026-06-25 00:02/00:05 CST refresh:

- Runtime host `172.38.11.85` is reachable by ping and TCP/22.
- Runtime tmux session `uvhs_h2conly_keepalive_20260624_173006` is still alive
  and still prints `KEEPALIVE_READY h2conly downloaded initialized reset
  released`; B0.F2 is `link up`, DDR4 is present on `FMC3`, and reset signals
  are released.
- FPGA host `user01@172.38.8.132` is still unreachable from the local
  workspace: ping has 100% packet loss and TCP/22 times out.
- The BAR helper was re-run with a short pre-reboot reachability gate and
  returned `RESULT=host_unreachable_before_reboot` twice, under
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/bar_peek_20260625_000149` and
  `fpga_diff/logs/ae_no_enum_20260624/fpga_host/bar_peek_20260625_000521`.
  Because TCP/22 was down, no host reboot, PCIe rescan, driver probe, BAR read,
  PCIe remove/reset/unbind, or runtime reboot was performed.
- `run_host_bar_peek_when_reachable.py` was tightened to ignore the local SSH
  proxy configuration (`-F /dev/null`) and allocate a TTY (`-tt`) so password
  and `sudo` prompts can be answered when the FPGA host comes back.
- `host_peek_xdma_bars.sh` was tightened to record sysfs `enable`, PCI config
  `COMMAND/STATUS`, vendor/device/class/link sysfs attributes, and resource
  flags before reading BAR offsets. The default mode still does not write
  sysfs `/enable`; a separate `XDMA_BAR_PEEK_ENABLE_DEVICE=1` run can be used
  later to mirror only the driver's `pci_enable_device()` step if the endpoint
  is visible but default BAR reads are disabled by the PCI command register.

2026-06-25 00:13/00:15 CST final refresh for this turn: FPGA host
`172.38.8.132` still has 100% ping loss, TCP/22 timeout, and direct
`ssh -F /dev/null` timeout. Runtime SSH to `172.38.11.85` still succeeds, and
the keepalive pane still prints `KEEPALIVE_READY h2conly downloaded initialized
reset released`. This leaves live BAR reads, driver load, H2C/C2H smoke, and
`fpga-host` blocked only by FPGA-host reachability.

2026-06-25 00:24/00:29 CST refresh archived in
`current_status_20260625_002418`: local ping/TCP22 to runtime host
`172.38.11.85` still succeeds, local ping/TCP22 to FPGA host
`172.38.8.132` still fails, and the runtime host itself also sees 100% ping
loss plus TCP/22 closed/timeout to `172.38.8.132`. The runtime tmux session
`uvhs_h2conly_keepalive_20260624_173006` remains alive; its pane still reports
B0.F2 `link up`, DDR4 on `FMC3`, and `KEEPALIVE_READY h2conly downloaded
initialized reset released`. No runtime reboot, FPGA-host reboot, PCIe rescan,
driver probe, BAR read, or PCIe remove/reset/unbind was performed by this
capture.

2026-06-25 00:33/00:37 CST refresh archived in
`current_status_20260625_003308`: local TCP/22 to runtime host
`172.38.11.85` is still open, while local ping/TCP22 to FPGA host
`172.38.8.132` still fails. Runtime-side route lookup sends
`172.38.8.132` via `172.38.11.254` on `em1`, but runtime-side ping still has
100% packet loss and TCP/22 is closed/timeout. The runtime tmux keepalive
session remains alive and still prints `KEEPALIVE_READY h2conly downloaded
initialized reset released`; its pane also shows reset signals released and
DDR4 on `FMC3`. No runtime reboot, FPGA-host reboot, PCIe rescan, driver probe,
BAR read, or PCIe remove/reset/unbind was performed by this capture.

A local search for `open28`, `172.38.8.132`, IPMI/BMC/WoL, sideband, and host
reboot helpers found no usable out-of-band recovery script in this workspace.
`fpga_diff/tools/pcie-remove.sh` exists but performs driver unbind plus PCIe
device remove, so it remains outside the allowed action set for this branch.

Recommended next live command sequence once FPGA host `user01@172.38.8.132` is
reachable again:

```sh
# On FPGA host, after fresh bit download, host reboot, and safe global rescan.
# Run before loading/probing xdma_chr. This captures state, performs only a
# safe global rescan, then reads BAR offsets. It does not remove/reset/unbind
# PCIe devices or ports, and default mode does not write sysfs /enable.
sudo bash /home/user01/project/env-scripts/fpga_diff/uvhs/host_bar_peek_after_rescan.sh
```

If BAR1 returns high16 `0x1fc2` at offset `0x2000` and `0x1fc3` at offset
`0x3000`, then the driver should be able to identify BAR1 as the XDMA config
BAR and the next step is normal `xdma_chr` load plus H2C/C2H testing. If both
BAR0 and BAR1 lack those IDs, the current endpoint is enumerating but not
decoding the XDMA config block expected by the MinJie driver.

New evidence path:

```text
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2000
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2018
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2041
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2049
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2100
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_210753
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_213835
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_214824
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_220334
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_221816
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2240
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2252
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2258
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2311
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_232424
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_232424_runtime
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2327
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_233010
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_233010_runtime
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_2334
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_234119
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_234938_runtime
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_235423
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260624_235859_runtime
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260625_000229
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260625_001321
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260625_002418
fpga_diff/logs/ae_no_enum_20260624/local/current_status_20260625_003308
fpga_diff/logs/ae_no_enum_20260624/fpga_host/bar_peek_20260625_000149
fpga_diff/logs/ae_no_enum_20260624/fpga_host/bar_peek_20260625_000521
fpga_diff/logs/ae_no_enum_20260624/hejian/current_h2conly_dcp_props_20260624_212411
fpga_diff/logs/ae_no_enum_20260624/local/host_bar_peek_after_rescan.sh
fpga_diff/logs/ae_no_enum_20260624/local/host_peek_xdma_bars.sh
fpga_diff/logs/ae_no_enum_20260624/local/host_xdma_rw_smoke.sh
fpga_diff/logs/ae_no_enum_20260624/local/run_host_bar_peek_when_reachable.py
fpga_diff/logs/ae_no_enum_20260624/local/xdma_bar_layout_default_20260624_2015
fpga_diff/logs/ae_no_enum_20260624/local/xdma_bar_layout_bar1_config_20260624_2042
fpga_diff/logs/ae_no_enum_20260624/local/xdma_bar_layout_driver_config_20260624_222340
fpga_diff/uvhs/next_bar_debug_runbook_20260624.md
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-legacybar-genscript-fmc3x4-20260624_182532
```
