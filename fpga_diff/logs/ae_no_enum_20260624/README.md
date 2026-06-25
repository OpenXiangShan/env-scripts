# AE Evidence Package: UVHS F2 PCIe No Enumeration

Date: 2026-06-24

## Conclusion

The official Hejian 1EP reference image downloads and initializes successfully on `B0.F2`, but the separate FPGA PCIe host `open28` (`user01@172.38.8.132`) did not enumerate any Xilinx/XDMA endpoint after safe PCIe bus rescan during the original no-enum experiments. Host `dmesg` had no PCIe/Xilinx/XDMA/AER entries dated 2026-06-24 in that window.

This points to a platform-side PCIe link / slot / cable / hotplug / board-state issue rather than a local `fpga_diff` RTL, DRC, timing, or XDMA driver bind issue.

After AE restored the device/runtime state later the same day, the h2c-only
`fpga_diff` image did enumerate as `10ee:9048` at Gen3 x4 after host reboot and
safe rescan. The active blocker moved to XDMA driver BAR discovery: a rebuilt
`xdma_chr` matching host kernel `6.8.0-124-generic` mapped BAR0/BAR1 but failed
with `identify_bars: Failed to detect XDMA config BAR`, so no `/dev/xdma*`
nodes were created. A forced `config_bar_num=0` probe also failed, created no
`/dev/xdma*`, and left the endpoint reading back as `rev ff`; further probe
tests need a fresh bit download followed by FPGA-host reboot/rescan.

## Machines

- Hejian runtime/programming host: `root@172.38.11.85`
- FPGA PCIe host: `user01@172.38.8.132` (`open28`)

## Directory Contents

- `local/ae_evidence_1ep_no_enum_20260624.md`: synthesized evidence and conclusion.
- `local/reference_snippets/`: official 1EP reference pin/XDMA snippets.
- `hejian/download_1ep_ref_keepalive_20260624_1112/`: official 1EP runtime download log.
- `hejian/download_1ep_ref_keepalive_20260624_1112.tcl`: Tcl used for official 1EP keepalive experiment.
- `hejian/query_1ep_capture_20260624_115109/`: official 1EP UHD capture/trigger metadata query.
- `hejian/capture_1ep_user_lnk_up_20260624_120208/`: official 1EP UHD trigger/capture attempt for `user_lnk_up_0`.
- `hejian/capture_1ep_user_lnk_up_fixed*_20260624_*/`: follow-up corrected
  UHD command-order attempts; these redownloaded and initialized the official
  1EP image but stopped at UVHS trigger/capture command-syntax boundaries.
- `hejian/wait_1ep_user_lnk_up_20260624_1345/`: official 1EP natural
  trigger wait for `user_lnk_up_0 = 1`.
- `hejian/wait_1ep_user_lnk_up_rescan_20260624_1350/`: official 1EP
  60-second natural trigger wait while the host performed a safe global
  PCIe rescan.
- `hejian/download_hold_1ep_ref_20260624_1425/`: official 1EP synchronized
  download/init/hold log, held active from 14:17:38 to 14:20:39 with rc=0.
- `hejian/uv_runtime_readonly_after_ae_restore_20260624_172759/`: read-only
  runtime query after AE restored the device/runtime state; `query -fpgas -all`
  completed with `Total ERROR: 0`.
- `hejian/h2conly_keepalive_20260624_173006/`: post-restore h2c-only
  `fpga_diff` runtime download/init/keepalive log. It reached `DOWNLOAD_DONE`,
  `DDR4 initialize success`, `INITIALIZE_DONE`, B0.F2 `link up`, and
  `KEEPALIVE_READY`.
- `hejian/current_h2conly_dcp_props_20260624_212411/`: read-only Vivado 2024.1
  checkpoint extraction for the currently downloaded h2c-only `xdma_ep.dcp`.
  The DCP SHA256 is
  `2819594d7e7d057cb55483c5959111eef81ac473b0b05341883d691f947142f5`.
  Extracted properties confirm `PF0_DEVICE_ID=0x9048`, XDMA core
  `BARLITE1=1`, `BARLITE_EXT_PF0=0x01`, `BARLITE_INT_PF0=0x02`, and PCIE4CE4
  hard block BAR0 1 MiB / BAR1 64 KiB, matching host enumeration.
- `hejian/current_image_pin_assign.xdc`: current `fpga_diff` generated pin constraints.
- `hejian/current_image_dlp.xdc`: current `fpga_diff` generated DLP constraints.
- `hejian/current_image_reports/`: current `fpga_diff` DRC and timing reports.
- `hejian/download_h2conly_clean_20260624_1314/`: current `fpga_diff`
  h2c-only image runtime download/init log.
- `hejian/pcieconn_genscript4_20260624_145828/`: fresh h2c-only
  `STOP_AFTER_GENSCRIPT` experiment preserving all three F2 PCIe-ish
  HGC/APC `connect_fpga` links. It failed at PERST/APC16 pin `R11` already
  connected.
- `hejian/pcieconn_hgconly_genscript2_20260624_150304/`: fresh h2c-only
  `STOP_AFTER_GENSCRIPT` experiment preserving only HGC6/HGC7 links. It
  passed PERST but failed at HGC7 RX lane pin `U2` already connected.
- `hejian/pcieconn_genscript_evidence_20260624_1503.tgz`: raw tarball pulled
  from the Hejian machine containing the two experiment logs and generated
  assembly overlays.
- `fpga_host/uvhs-1ep-ref-keepalive-20260624_1114/`: safe rescan/lspci evidence after official 1EP download.
- `fpga_host/dmesg-check-20260624_1118/`: full and filtered dmesg capture.
- `fpga_host/pcie-rootport-readonly-20260624_1120/`: root-port lspci/sysfs snapshot.
- `fpga_host/uvhs-1ep-ref-capture-rescan-20260624_115949/`: safe rescan/lspci/dmesg evidence after the later official 1EP UHD capture run.
- `fpga_host/dmesg_check_20260624_1240/`: follow-up read-only `dmesg`,
  `journalctl -k`, `lspci`, and root-port sysfs snapshot.
- `fpga_host/host_rescan_debug_20260624_1255/`: local global-rescan
  before/after capture with root-port and kernel-log snapshots.
- `fpga_host/h2conly_clean_rescan_20260624_1316/`: host safe-rescan evidence
  after downloading the current `fpga_diff` h2c-only clean image.
- `fpga_host/post_wait_1ep_rescan_20260624_1342/`: host safe-rescan evidence
  after the official 1EP `user_lnk_up_0` natural-wait experiment.
- `fpga_host/rescan_during_1ep_wait_20260624_1342/`: host safe-rescan
  evidence captured during the official 1EP `user_lnk_up_0` wait window.
- `fpga_host/platform_readonly_20260624_1350/`: read-only host platform
  inventory (`dmidecode`, root-port sysfs, PCI slot sysfs, `lspci -tv/-vv`).
- `fpga_host/ref_1ep_hold_hostpoll_20260624_1425/`: host polling across the
  synchronized official 1EP hold window. It contains 288 samples through
  elapsed 600s; the rescan in this run happened before FPGA download, but the
  post-initialize samples still show no adapter/link presence.
- `fpga_host/h2conly_after_host_reboot_rescan_20260624_172909/`: post-AE
  restore host reboot plus safe rescan evidence. It shows `10ee:9048`
  enumerated at `0000:01:00.0`, endpoint `LnkSta: Speed 8GT/s, Width x4`, but
  no `/dev/xdma*`.
- `fpga_host/dmesg_debug_20260625_1446/`: 2026-06-25 post-reboot read-only
  `dmesg`/`lspci`/sysfs capture. It shows current boot enumeration of
  `10ee:9048` under `0000:00:01.0 -> 0000:01:00.0`, BAR0/BAR1 assignment,
  Gen3 x4 link, command state `Mem- BusMaster-`, no bound driver, and no
  `/dev/xdma*`.
- `fpga_host/driver_id_debug_20260625_1448/`: read-only driver-ID adaptation
  check. The current kernel module tree has no installed `xdma_chr` and no
  installed alias for `10ee:9048`, while MinJie's source and the rebuilt
  `6.8.0-124-generic` `xdma-chr.ko` both include the `10ee:9048` alias.
- `fpga_host/driver_bar_identify_source_20260625_1457/`: read-only MinJie
  driver source capture for BAR identification. It records that `xdma_chr`
  reads BAR offsets `0x2000` and `0x3000` and expects identifier high bits
  `0x1fc2` and `0x1fc3`; `config_bar_num=0` still runs this check and does not
  bypass a missing config register aperture.
- `fpga_host/xdma_chr_build_20260624_1738/`: rebuilt `xdma_chr` for host kernel
  `6.8.0-124-generic`, with alias for `10ee:9048`.
- `fpga_host/xdma_chr_load_20260624_1738/`: driver probe evidence. Probe mapped
  BAR0/BAR1 but failed `identify_bars: Failed to detect XDMA config BAR`; no
  XDMA character devices were created.
- `fpga_host/xdma_rw_try_20260624_175222/`: forced `config_bar_num=0`
  probe/H2C attempt evidence. The endpoint was present before probe, no
  `/dev/xdma*` nodes were created, and the endpoint read back as `rev ff`
  afterward.
- `fpga_host/kernel_debug_20260624_180633/`: empty host-state capture directory
  retained only for timeline completeness.
- `local/current_status_20260624_2000/`: current live status after AE restore.
  The Hejian h2c-only keepalive runtime is still running and initialized, but
  FPGA host `172.38.8.132` is unreachable from both the local workspace and the
  Hejian runtime host. This directory also records generated XDMA BAR parameter
  inference: host AXI-Lite master on BAR0, XDMA control expected on BAR1.
- `local/current_status_20260624_2018/`: refreshed live status. It confirms
  `root@172.38.11.85` is reachable, tmux session
  `uvhs_h2conly_keepalive_20260624_173006` is still alive and reports
  `KEEPALIVE_READY`, and the runtime host still cannot ping or open TCP/22 to
  FPGA host `172.38.8.132`.
- `local/current_status_20260624_2041/`: refreshed local reachability. Runtime
  host `172.38.11.85` is reachable by ping/TCP/22; FPGA host `172.38.8.132`
  still has ping loss and TCP/22 timeout from the local workspace.
- `local/current_status_20260624_2049/`: local route/TCP check. Traffic to
  FPGA host `172.38.8.132` routes via `172.19.20.254` but TCP/22 still times
  out; runtime host TCP/22 remains reachable.
- `local/current_status_20260624_2100/`: refreshed local reachability with the
  same result: runtime host ping/TCP OK, FPGA host ping loss and TCP/22 timeout.
- `local/current_status_20260624_210753/`: full refreshed status. Local and
  runtime host can both reach `172.38.11.85`; neither can ping or open TCP/22 to
  FPGA host `172.38.8.132`. Runtime tmux session
  `uvhs_h2conly_keepalive_20260624_173006` remains alive and prints
  `KEEPALIVE_READY h2conly downloaded initialized reset released`.
- `local/current_status_20260624_213835/`: refreshed status after the DCP
  evidence update. Local and runtime host still reach `172.38.11.85`; local
  ping/TCP to FPGA host `172.38.8.132` fails, direct SSH to the FPGA host times
  out during banner exchange, and the runtime host also cannot ping or open
  TCP/22 to `172.38.8.132`. Runtime tmux session
  `uvhs_h2conly_keepalive_20260624_173006` is still alive and still prints
  `KEEPALIVE_READY h2conly downloaded initialized reset released`.
- `local/current_status_20260624_214824/`: refreshed status with the same
  result. Runtime host is reachable and the h2c-only keepalive tmux session is
  still alive; FPGA host `172.38.8.132` remains unreachable from both local and
  runtime hosts, with ping loss and TCP/22 timeout.
- `local/current_status_20260624_220334/`: refreshed status at 22:03/22:08.
  Runtime host `172.38.11.85` is reachable and tmux session
  `uvhs_h2conly_keepalive_20260624_173006` is still alive. FPGA host
  `172.38.8.132` remains unreachable from both local and runtime hosts: local
  SSH timed out during banner exchange, runtime-side ping had 100% packet loss,
  and runtime-side TCP/22 returned `tcp22_not_open`.
- `local/current_status_20260624_221816/`: refreshed status at 22:18/22:23.
  Runtime host `172.38.11.85` is reachable and tmux session
  `uvhs_h2conly_keepalive_20260624_173006` is still alive. FPGA host
  `172.38.8.132` remains unreachable from both local and runtime hosts: local
  SSH timed out during banner exchange, local and runtime-side ping had 100%
  packet loss, local TCP/22 returned `tcp22_not_open`, and runtime-side TCP/22
  returned `fpga_host_tcp22_not_open`.
- `local/current_status_20260624_2240/`: refreshed status at 22:36/22:41.
  Runtime host remains reachable and the h2c-only keepalive session still
  prints `KEEPALIVE_READY`. FPGA host `172.38.8.132` remains unreachable from
  the local workspace; verbose SSH shows the client going through
  `/usr/bin/sss_ssh_knownhostsproxy -p 22 172.38.8.132`, explaining the
  `UNKNOWN port 65535` banner-timeout wording as local proxy behavior.
  Follow-up checks show `ProxyCommand=none` direct SSH also times out, local
  name `open28` has no DNS resolution in this workspace, and the runtime host
  routes to `172.38.8.132` via `172.38.11.254` but still sees ping loss and
  `fpga_host_tcp22_not_open`.
- `local/current_status_20260624_2252/`: refreshed status at 22:48/22:53.
  Runtime host remains reachable and the h2c-only keepalive session still
  prints `KEEPALIVE_READY`. FPGA host `172.38.8.132` still has local and
  runtime-side ping loss plus TCP/22 timeout.
- `local/current_status_20260624_2258/`: refreshed local status at 23:00.
  Local ping/TCP to runtime host `172.38.11.85` succeeded, but the short direct
  SSH/tmux probe timed out. FPGA host `172.38.8.132` still had ping loss,
  TCP/22 timeout, and direct SSH timeout. A local evidence search found no
  `10ee:0948` entries; the captured endpoint ID remains `10ee:9048`.
- `local/current_status_20260624_2311/`: refreshed live status at 23:11/23:16.
  Runtime host `172.38.11.85` is reachable, the h2c-only keepalive tmux session
  is still alive, and its captured pane still shows B0.F2 `link up`, DDR4
  `FMC3`, resets released, and `KEEPALIVE_READY`. FPGA host `172.38.8.132`
  remains unreachable from both the local workspace and the runtime host, with
  ping loss and TCP/22 timeout.
- `local/current_status_20260624_2327/`: runtime-side network-only refresh at
  23:22. `open28` did not resolve within the short `getent` timeout, traffic to
  `172.38.8.132` still routes via `172.38.11.254` on `em1`, `ipmitool` is not
  installed on the runtime host, and runtime ping/TCP22 to the FPGA host still
  fails.
- `local/current_status_20260624_2334/`: final short local reachability probe
  for this turn. FPGA host `172.38.8.132` still has ping loss, TCP/22 timeout,
  and direct SSH timeout; runtime host TCP/22 remains open.
- `local/current_status_20260624_232424/`: refreshed local reachability probe.
  FPGA host `172.38.8.132` still has ping loss, TCP/22 timeout, and direct SSH
  timeout; runtime host `172.38.11.85` remains reachable by ping and TCP/22.
- `local/current_status_20260624_232424_runtime/`: refreshed runtime-side
  keepalive and host probe. Runtime tmux
  `uvhs_h2conly_keepalive_20260624_173006` remains alive and prints
  `KEEPALIVE_READY`; runtime-side ping/TCP22 to FPGA host still fails.
- `local/current_status_20260624_233010/` and
  `local/current_status_20260624_233010_runtime/`: another refreshed
  local/runtime probe with the same result. FPGA host remains unreachable by
  ping/TCP22/SSH; runtime host remains reachable and the h2c-only keepalive
  tmux session still prints `KEEPALIVE_READY`.
- `local/current_status_20260624_234119/`: refreshed local probe at 23:41.
  Runtime host `172.38.11.85` is reachable by ping and TCP/22. FPGA host
  `172.38.8.132` still has 100% ping loss, TCP/22 timeout, and direct
  `ProxyCommand=none` SSH timeout. This keeps raw BAR reads, driver reload, and
  `fpga-host` H2C/C2H tests blocked on FPGA-host reachability.
- `local/current_status_20260624_234938_runtime/`: refreshed runtime-side
  probe at 23:50. Runtime tmux
  `uvhs_h2conly_keepalive_20260624_173006` is still alive, the pane still shows
  DDR4 on `FMC3` and `KEEPALIVE_READY`, and runtime-side ping/TCP22 to FPGA
  host `172.38.8.132` still fails.
- `local/current_status_20260624_235423/` and
  `local/current_status_20260624_235859_runtime/`: refreshed local/runtime
  probe at 23:55/23:58. FPGA host remains unreachable from both sides, runtime
  keepalive is still alive, and a dry reachability run of
  `run_host_bar_peek_when_reachable.py` returned
  `RESULT=host_unreachable_before_reboot` before any reboot action.
- `local/current_status_20260625_000229/`: 2026-06-25 00:02 CST refresh.
  Runtime host `172.38.11.85` is reachable by ping/TCP/22; FPGA host
  `user01@172.38.8.132` still has 100% ping loss and TCP/22 timeout; helper
  syntax checks passed for the BAR peek, raw BAR peek, H2C/C2H smoke, and local
  orchestration scripts.
- `fpga_host/bar_peek_20260625_000149/` and
  `fpga_host/bar_peek_20260625_000521/`: local orchestration attempts with
  short pre-reboot reachability gates. Both returned
  `RESULT=host_unreachable_before_reboot`; no FPGA-host reboot, PCIe rescan,
  BAR read, driver probe, PCIe remove/reset/unbind, or runtime reboot was
  performed.
- `local/current_status_20260625_001321/`: final reachability refresh for this
  turn. FPGA host `172.38.8.132` still has 100% ping loss, TCP/22 timeout, and
  direct `ssh -F /dev/null` timeout. Runtime SSH was separately confirmed at
  00:15 CST, with the h2c-only keepalive pane still printing
  `KEEPALIVE_READY h2conly downloaded initialized reset released`.
- `local/xdma_bar_layout_default_20260624_2015/`: local Vivado IP export
  parameter comparison for `XDMA_BAR_LAYOUT=default`. The generated XDMA XCI/SV
  keeps `PF0_DEVICE_ID=0x9048`, `AXILITE_MASTER_CONTROL=0x4`,
  `XDMA_CONTROL=0x4`, `BARLITE1=1`, `BARLITE_EXT_PF0=0x01`, and
  `BARLITE_INT_PF0=0x02`, matching the current relevant BAR-layout inference.
- `local/xdma_bar_layout_bar1_config_20260624_2042/`: experimental local Vivado
  IP export using `XDMA_BAR_LAYOUT=bar1-config`. Synthesis completed, but
  `bar_indicator` remained `BAR_0` and disabled, MSI-X BIR overrides were also
  disabled, and the generated BAR controls still match the default branch.
- `local/xdma_bar_layout_driver_config_20260624_222340/`: experimental local
  Vivado IP export using `XDMA_BAR_LAYOUT=driver-config-bar`. Export completed,
  but top-level XCI still has `pf0_bar1_enabled=false`, `bar_indicator=BAR_0`
  disabled, and generated controls `AXILITE_MASTER_CONTROL=0x4`,
  `XDMA_CONTROL=0x4`, `BARLITE1=1`, `BARLITE_EXT_PF0=0x01`, and
  `BARLITE_INT_PF0=0x02`; generated SV still has `PF0_BAR0_CONTROL=3'H4` and
  `PF0_BAR1_CONTROL=3'H0`.
- Remote legacy/default BAR generation at
  `/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-legacybar-genscript-fmc3x4-20260624_182532`
  reached `UVHS_STOP_AFTER_GENSCRIPT` only. Its exported XCI still matches the
  same relevant class: top-level `PF0_BAR1_CONTROL=0x0` and generated
  `BARLITE1=1` / `BARLITE_EXT_PF0=0x01` / `BARLITE_INT_PF0=0x02`, while the
  nested PCIE4C IP propagates BAR1 enabled. It has not been implemented,
  downloaded, or tested on hardware.
- `hejian/platform_readonly_20260624_1350/`: Hejian host timestamp and failed
  first-pass platform query. The query failed before loading a valid RTDB
  workdir and is retained only as command-attempt evidence.
- `hejian/readonly_connector_query_20260624_1412/`: read-only official 1EP
  RTDB connector query. It shows `B0.F2_FMC3` present as `DAUGHTER_CARD`, but
  the PCIe-related `B0.F2_HGC7`, `B0.F2_HGC6`, and `B0.F2_APC16` connectors
  as `NONE`.
- `local/hwdat_download_once_script/`: generic `hw.dat` download Tcl used for
  the current `fpga_diff` h2c-only runtime check.
- `local/host_bar_peek_after_rescan.sh` and `local/host_peek_xdma_bars.sh`:
  FPGA-host side safe evidence scripts for the next live run. They do not load
  `xdma_chr` and do not remove/reset/unbind PCIe ports; the wrapper captures
  state, performs only global PCIe rescan, then peeks BAR offsets.
- `local/run_host_bar_peek_when_reachable.py`: local orchestration helper for
  when FPGA host SSH returns. It checks TCP/22, reboots the FPGA host, waits for
  SSH, runs the same safe BAR peek script, and best-effort pulls remote
  `bar_peek_*` logs into this evidence tree. It requires the host password via
  `FPGA_HOST_PASS` or `--password`; no password is stored in the script. The
  current copy uses `ssh -F /dev/null -tt` so local SSH proxy configuration and
  remote `sudo` password prompts do not block the run once the FPGA host is
  reachable.
- `local/host_xdma_rw_smoke.sh`: FPGA-host side bounded XDMA smoke for the
  BAR-success branch. It writes 4096 bytes to `/dev/xdma0_h2c_0`, attempts one
  short `/dev/xdma0_c2h_0` read, records return codes/byte counts, and never
  remove/reset/unbinds PCIe.
- Driver source inspection in
  `/nfs/home/fengkehan/project/minjie-playground/dma_ip_drivers/XDMA/linux-kernel/xdma/libxdma.c`
  shows `config_bar_num` is still verified by reading the XDMA identifier
  registers at offsets `0x2000` and `0x3000`; it is not a bypass for a BAR that
  does not decode the config block.
- Current `fpga_diff/src/tcl/common/xdma_ep.tcl` connects XDMA `M_AXI_LITE` to
  the external difftest register-file port (`XDMA_AXI_LITE`) and assigns that
  address space 1 MiB. Generated core parameters still select BAR1 for the XDMA
  internal config block (`XDMA_CONTROL=4`, `BARLITE1=1`). Thus the remaining
  live question is whether enumerated BAR1 returns the expected XDMA config IDs
  at runtime.
- `fpga_diff/uvhs/next_bar_debug_runbook_20260624.md`: concise next-run
  command sequence and decision criteria for host reboot, safe global rescan,
  raw BAR peek, and follow-up driver/H2C/C2H testing once FPGA host
  `user01@172.38.8.132` is
  reachable.
- `local/ref_1ep_capture_scripts/`: Tcl/INI scripts used for the official 1EP UHD metadata/capture experiments.
- `SHA256SUMS`: checksums for this package.

## Key Remote Source Logs

Hejian runtime official 1EP download:

```text
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/download_1ep_ref_keepalive_20260624_1112/download.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/query_1ep_capture_20260624_115109/query.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/capture_1ep_user_lnk_up_20260624_120208/capture.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/wait_user_lnk_up_20260624_1345/wait.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/wait_user_lnk_up_rescan_20260624_1350/wait.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/ref_1ep_rtdb_20260623/logs/download_hold_1ep_ref_20260624_1425/download_hold.log
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/logs/uv_runtime_readonly_after_ae_restore_20260624_172759
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-refclkskip-genscript-fmc3x4-20260623_1242/logs/h2conly_keepalive_20260624_173006
```

FPGA host captures:

```text
/home/user01/uvhs-debug-logs/uvhs-1ep-ref-keepalive-20260624_1114
/home/user01/uvhs-debug-logs/dmesg-check-20260624_1118
/home/user01/uvhs-debug-logs/pcie-rootport-readonly-20260624_1120
/home/user01/uvhs-debug-logs/uvhs-1ep-ref-capture-rescan-20260624_115949
/home/user01/uvhs-debug-logs/ref_1ep_hold_hostpoll_20260624_1425
/home/user01/uvhs-debug-logs/h2conly_after_host_reboot_rescan_20260624_172909
/home/user01/uvhs-debug-logs/xdma_chr_build_20260624_1738
/home/user01/uvhs-debug-logs/xdma_chr_load_20260624_1738
/home/user01/uvhs-debug-logs/xdma_rw_try_20260624_175222
```

## Safe Rescan Command Used

No PCIe remove/unbind/port reset was used.

```sh
printf 'er0doo$H\n' | sudo -S sh -c 'echo 1 > /sys/bus/pci/rescan'
```

## Key Observations

From official 1EP runtime download log:

- `event: P0 B0.F2 -> B0.F2 linked up by root`
- `INFO:Done: download success`
- `event: systembus initialize success`
- `event: ps initialize success`
- `event: uhd initialize success`
- `INFO:Done: initialization complete success`
- `INFO: KEEPALIVE_READY official 1ep reference is downloaded and initialized`
- `Total ERROR:  0`
- `END ... rc=0`

From official 1EP UHD metadata/capture logs:

- `query -capture` reports a `B0.F2` capture station enabled: `B0.F2_caption_station_0`, clock `clk`, 1 signal.
- `query -trigger -name test` reports trigger channel 0 is `test.u_design_2_wrapper.user_lnk_up_0`.
- A later capture run reached `capture -enable -open_database ... -force` and `trigger -force command completed success`.
- The capture run did not produce a `UHD/<database>` waveform directory; `wavegen -open_database` failed because the database path did not exist. Therefore this package proves the official probe/trigger is present and armable, but does not claim a measured value for `user_lnk_up_0`.
- Follow-up corrected-command attempts at 13:00, 13:06, and 13:10 again showed
  official 1EP download/init success but did not produce a waveform sample; the
  attempts stopped at UVHS capture/trigger command syntax errors.
- A later natural trigger wait on the official 1EP RTDB armed
  `test.u_design_2_wrapper.user_lnk_up_0 = 1` for 15 seconds after download
  and initialization. It reported `Conditions Triggered false` and
  `Waveform Data Ready false`; `upload_uhd` refused to upload because the
  trigger did not hit.
- A second official 1EP natural wait used a 60-second window while the host
  performed the same safe global PCIe rescan. It still reported
  `condition_triggered=0` and `waveform_ready=0`.
- A synchronized official 1EP download/hold run completed with `download`
  success at 14:17:34, `initialize` success at 14:17:36, `HOLD_START` at
  14:17:38, `HOLD_END` at 14:20:39, final `rc=0`, and `Total ERROR: 0`.
- Read-only connector query of the official 1EP RTDB reports `B0.F2_FMC3` as
  `DAUGHTER_CARD`, but `B0.F2_HGC7`, `B0.F2_HGC6`, and `B0.F2_APC16` as
  `NONE`. Those are exactly the connectors used by the official PCIe refclk,
  lanes, and PERST pin assignments.
- Preserving/enabling the F2 HGC/APC `connect_fpga` assembly links was tested
  with fresh h2c-only `STOP_AFTER_GENSCRIPT` builds. The all-link experiment
  failed on `pcie_ep_perstn` at APC16 index 118 / pin `R11`; the HGC-only
  experiment failed on `pci_ep_rxp[0]` at HGC7 index 16 / pin `U2`. This shows
  those assembly links occupy the same pads needed for the external PCIe
  endpoint and are not a viable local no-enum fix.

From FPGA host:

- `lspci -D -nn | egrep -i '10ee|xilinx|xdma'`: no output.
- `/dev/xdma*`: no devices.
- `xilinx_bdfs.txt`: 0 lines.
- `journal_pci_since_1110.txt`: 0 lines.
- After the later official 1EP UHD run, `journal_pci_filter_since_20min.txt`: 0 lines.
- Filtered `dmesg` contains 0 entries dated `Jun 24`.
- Root ports `0000:00:1a.0` and `0000:00:1d.0` are x4-capable, but `current_link_width=0`.
- The only active downstream endpoint is Realtek `10ec:8125` under `0000:00:1c.2`.
- A later 2026-06-24 12:41 follow-up still had no 2026-06-24 PCIe/XDMA/Xilinx/AER
  kernel messages, no `/dev/xdma*`, and no `10ee` endpoint.
- `/sys/bus/pci/slots` reports powered hotplug slots but `adapter=0` for the
  empty downstream slots, consistent with the host not detecting a present
  PCIe adapter on those ports.
- A 2026-06-24 12:49 global bus rescan did not change the PCI device list and
  did not create new kernel PCIe/XDMA/Xilinx/AER messages.
- `sudo lspci -vv` shows the x4-capable ports `0000:00:1a.0` and
  `0000:00:1d.0` at `Width x0`, `DLActive-`, and `PresDet-`, while the Realtek
  port `0000:00:1c.2` is `Width x1`, `DLActive+`, and `PresDet+`.
- Downloading the current `fpga_diff` h2c-only clean image at 13:21 also
  succeeded, including `DDR4 initialize success`, but the FPGA host still did
  not enumerate a `10ee` endpoint after safe rescan.
- After the official 1EP natural trigger wait, another safe rescan produced
  no `lspci` diff, no `10ee`/Xilinx/XDMA entry, no `/dev/xdma*`, and no kernel
  journal entries since 13:35.
- During the 60-second official 1EP trigger wait, a safe rescan again produced
  no `lspci` diff, no Xilinx/XDMA entry, no `/dev/xdma*`, and no kernel
  journal entries since 13:40.
- During the synchronized 14:25 official 1EP hold, host samples after
  `HOLD_START` still had no `10ee`/Xilinx/XDMA endpoint and no `/dev/xdma*`.
  Samples at 14:19:40 and 14:20:33 show `0000:00:1a.0` and `0000:00:1d.0`
  at `current_link_width=0`, `power_state=D3hot`, and slot `adapter=0`; the
  Realtek contrast port `0000:00:1c.2` stayed width x1.
- The 13:47 read-only platform inventory identifies the FPGA host motherboard
  as `ASUSTeK COMPUTER INC. PRIME Z690-P WIFI D4`. Its PCI slot sysfs entries
  for buses `0000:01:00`, `0000:03:00`, and `0000:05:00` are powered
  (`power=1`) but report `adapter=0`. The x4-capable root ports
  `0000:00:1a.0` and `0000:00:1d.0` remain `current_link_width=0` and
  `power_state=D3hot`; the active Realtek contrast port is still
  `0000:00:1c.2` with width x1.
- After AE restored the device/runtime state, the h2c-only image was downloaded
  again in a keepalive session. Host reboot plus safe rescan then produced one
  Xilinx endpoint: `0000:01:00.0 Memory controller [0580]: Xilinx Corporation
  Device [10ee:9048]`. Endpoint `lspci -vv` showed BAR0 size 1 MiB, BAR1 size
  64 KiB, and `LnkSta: Speed 8GT/s (ok), Width x4 (ok)`. No `/dev/xdma*`
  nodes existed before driver binding.
- A rebuilt `xdma_chr` for kernel `6.8.0-124-generic` included alias
  `pci:v000010EEd00009048...` and loaded. Probe mapped BAR0/BAR1 but reported
  `identify_bars: Failed to detect XDMA config BAR` and failed with `error
  -22`; no `/dev/xdma*` nodes were created. Direct `fpga-host` H2C/C2H testing
  was therefore not run.
- A forced `config_bar_num=0` probe also created no `/dev/xdma*`. Before that
  probe the endpoint was visible as `10ee:9048`; afterward `lspci` reported it
  as `rev ff` and sysfs link fields were inconsistent. This is treated as a
  failed negative experiment, not as a valid H2C/C2H datapath test.

## Current fpga_diff Build Sanity

Current h2c-only image:

```text
/home/data/test/stage_h2conly_hosth2c_publicref_src_20260622_172031/env-scripts/fpga_diff/fpga_diff_uvhs_nutshell-h2conly-hosth2c-refclkskip-genscript-fmc3x4-20260623_1242
```

Reports copied into `hejian/current_image_reports/` show:

- `pnr_drc_ipchk.rpt`: `NSTD-1 UCIO-1`, violations found: `0`
- `pnr_timing_summary.rpt`: WNS `0.083`, TNS `0.000`, 0 failing endpoints
- Runtime download/init log `hejian/download_h2conly_clean_20260624_1314/`
  shows download success, B0.F2 linked up by root, DDR4 initialize success, and
  `rc=0`.

Generated constraints include refclk `AC11/AC10`, PERST `R11`, and x4 PCIe lanes matching the official 1EP reference F2 HGC7/APC16 indexes.

## Recommended AE Checks

- Verify physical cable/slot path between `B0.F2` and FPGA host
  `user01@172.38.8.132`.
- Confirm expected host root port and why its `current_link_width` stays `0`.
- Confirm whether the platform requires a board/slot power-cycle or AE-approved link retrain after UVHS download.
- If port reset/remove is required, run it under AE guidance; it was intentionally avoided here.
- For the post-restore enumerating case, confirm the expected XDMA BAR layout
  for `10ee:9048`, especially which BAR should contain the XDMA config block.
- Once FPGA host `user01@172.38.8.132` is reachable again, capture raw BAR0/BAR1
  reads at offsets `0x2000` and `0x3000` before loading `xdma_chr`. Current
  generated parameters predict the XDMA config block should be in BAR1. The
  current BAR helper records sysfs `enable`, PCI config `COMMAND/STATUS`, and
  resource flags; default mode still does not write sysfs `/enable`.
- As of `current_status_20260624_210753`, this raw BAR check is still blocked
  only by FPGA-host reachability; later refreshes through
  `current_status_20260625_003308` and the two
  `fpga_host/bar_peek_20260625_*` attempts show FPGA host `172.38.8.132`
  remains unreachable from both the local workspace and the runtime host while
  runtime tmux `uvhs_h2conly_keepalive_20260624_173006` still reports B0.F2
  link up and `KEEPALIVE_READY h2conly downloaded initialized reset released`.
  Local search found no usable BMC/IPMI/WoL sideband helper for recovering
  `172.38.8.132`; `fpga_diff/tools/pcie-remove.sh` performs driver unbind plus
  PCIe device remove and was intentionally not used.
  The most recent ID check also confirms `10ee:0948` is not in the evidence;
  the observed Xilinx endpoint ID is `10ee:9048`, and that endpoint can only be
  observed on FPGA host `user01@172.38.8.132`.
