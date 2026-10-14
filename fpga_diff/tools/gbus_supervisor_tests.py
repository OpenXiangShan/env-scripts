#!/usr/bin/env python3
"""Local-only regression tests: fake SSH/RPC, disposable workers, no hardware."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest
from unittest.mock import Mock, patch

TOOLS = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("gbus_supervisor", TOOLS / "gbus_supervisor.py")
g = importlib.util.module_from_spec(spec)
spec.loader.exec_module(g)
GOOD = ("HIT GOOD TRAP\nGBus C2H interface layer=sram-window mode=config-window\n"
        "GBus DMA workload queued 8192 bytes\nGBD1 progress mode=config-window banks=1 bytes=768 seq=1\n"
        "Core-0 instrCnt = 525, cycleCnt = 1,927\n"
        "==================== Difftest PerfCnt ====================\n"
        "Run time: 1 s 123 ms\nSimulation speed: 1.72 KHz, 0.47 KIPS\n")
DMA_GOOD = (GOOD.replace("config-window", "axi-dma") +
            "GBD1 AXI verified addr=0x0ffff000 len=7 count=1 bytes=256\n"
            "GBD1 first frozen bank DMA/config mirror verified seq=1 bytes=768\n")


class SafetyTests(unittest.TestCase):
    def setUp(self):
        self.mock_contract = patch.object(g, "require_live_transport_contract")
        self.mock_contract.start()
        self.addCleanup(self.mock_contract.stop)
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.key = self.base / "key"
        self.key.touch()
        self.workload = self.base / "hello.bin"
        self.reference = self.base / "reference.so"
        self.workload.write_bytes(b"source hello")
        self.reference.write_bytes(b"reference ELF")
        release = self.base / "release/build/generated-src"
        release.mkdir(parents=True)
        (release / "difftest-state.h").write_text("release ABI")
        self.input_data = {"cpu": "nutshell", "c2h_mode": "config-window", "difftest_perfcnt": 1,
                           "release_dir": str(release.parent.parent),
                           "workload": {"path": str(self.workload), "sha256": g.digest(self.workload)},
                           "reference": {"path": str(self.reference), "sha256": g.digest(self.reference)}}
        self.manifest = self.base / "inputs.json"
        self.manifest.write_text(json.dumps(self.input_data))
        self.env = {"TAG": "test", "OUT_DIR": str(self.base / "out"), "FPGA_HOST_KEY": str(self.key),
                    "FPGA_HOST_PARENT": str(self.base), "WAIT_BOARD_TIMEOUT": "0", "RUNTIME_KEY": str(self.key),
                    "GBUS_LIBUVGBUS": "/vendor/gbus/lib/libuvgbus.so",
                    "GBUS_TEST_MANIFEST": str(self.manifest)}
        self.s = g.Supervisor(self.env)
        self.s.fpga = Mock()
        self.s.rt = Mock()
        self.s.fpga.call.return_value = {}
        self.s.fpga.host = "fake-fpga"
        self.s.rt.host = "fake-runtime"
        self.s.rt.call.return_value = {}

    def tearDown(self):
        self.tmp.cleanup()

    def new_owned(self, name="worker"):
        directory = self.base / name
        helper = (TOOLS / "gbus_supervisor.py").read_text()
        helper = helper.replace('    raise RuntimeError("live GBus programming/I/O blocked: vendor ACK failure propagation and request drain unverified")',
                                '    return None', 1)
        g.init_owned(str(directory), "token", "test", helper)
        return directory

    def launch_mock_host(self, directory, command, timeout=10):
        # This permit is an inert fixture, never a hardware health claim.
        permit = {"token": "token", "host_directory": str(directory), "command": command,
                  "state": "owned_runtime_healthy", "boot_id": "mock-boot", "pid": 4321,
                  "start": "123", "runtime_directory": "/mock-runtime", "id": "a" * 32}
        return g.launch(str(directory), "token", "host", command, timeout=timeout, authorization=permit)

    def wait(self, directory, name, seconds=10):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            status = g.remote({"action": "status", "directory": str(directory), "token": "token", "name": name})
            if status["rc"] is not None:
                return status
            time.sleep(.05)
        self.fail("worker failed to publish rc")

    def test_project_lock_is_nonblocking_and_project_scoped(self):
        self.s.root = self.base
        other = g.Supervisor(self.env)
        other.root = self.base
        project = self.base / "project"
        self.s.lock_project(project)
        try:
            with self.assertRaisesRegex(RuntimeError, "another supervisor"):
                other.lock_project(project)
            other.lock_project(self.base / "different-project")
            other.project_lock.close()
        finally:
            self.s.project_lock.close()
        other.lock_project(project)
        other.project_lock.close()

    def test_shell_entrypoints_block_without_authorization(self):
        for name in ("board_test_supervisor.sh", "fpga_host_sync_build.sh"):
            done = subprocess.run(["bash", str(TOOLS / name)], env={"PATH": os.environ["PATH"]}, capture_output=True)
            self.assertEqual(done.returncode, 64)
            self.assertIn(b"BLOCKED", done.stderr)

    def test_busy_and_unknown_never_stage_or_launch(self):
        self.s.revalidate_runtime_package = Mock()
        for response in ({"board": {"state": "busy"}, "transport": {"state": "healthy"}},
                         {"board": {"state": "unknown"}, "transport": {"state": "healthy"}},
                         {"board": {"state": "free"}, "transport": {"state": "unhealthy"}}, {}):
            with self.subTest(response=response):
                self.s.rt.call.return_value = response
                with self.assertRaisesRegex(RuntimeError, "busy/unknown|transport unhealthy/unknown"):
                    self.s.runtime()
                self.s.rt.sync.assert_not_called()
                self.assertFalse(any(c.args[0] == "launch" for c in self.s.rt.call.call_args_list))
        self.s.rt.call.side_effect = RuntimeError("SSH rc=255")
        with self.assertRaisesRegex(RuntimeError, "transport unhealthy/unknown"):
            self.s.runtime()
        self.s.rt.sync.assert_not_called()

    def test_build_failure_prevents_runtime(self):
        self.s.release = Mock()
        self.s.build = Mock(side_effect=RuntimeError("make failed rc=2"))
        self.s.runtime = Mock()
        self.s.run_host = Mock()
        self.s.finish = Mock(side_effect=lambda rc: rc)
        project = self.base / "project"
        project.mkdir()
        (project / "backend_run.log").write_text("UVHS_BACKEND_SUCCESS")
        (project / "hw.dat").mkdir()
        (project / "hw.dat/input.bin").write_bytes(b"new runtime")
        self.s.inputs["runtime_files"] = g.manifest(project / "hw.dat")
        self.s.validate_runtime_package = Mock()
        self.s.env.update(PRJ="project", PRJ_DIR=str(project))
        self.assertEqual(self.s.execute("supervise"), 1)
        self.s.runtime.assert_not_called()
        self.s.run_host.assert_not_called()

    def test_build_rpc_failure_prevents_binary_proof(self):
        self.s.generated = self.base
        self.s.generated_manifest = {"difftest-state.h": "hash"}
        self.s.env["DIFFTEST_SRC"] = str(self.base)
        self.s.wait_worker = Mock(return_value={"rc": 2, "result": {"child_rc": 2, "cleanup_errors": []}})
        with self.assertRaisesRegex(RuntimeError, "host build failed"):
            self.s.build()
        self.assertFalse(any(c.args[0] == "proof" for c in self.s.fpga.call.call_args_list))
        self.s.rt.call.assert_not_called()
        self.assertNotEqual(self.s.host_dir, str(self.base))
        launches = [c for c in self.s.fpga.call.call_args_list if c.args[0] == "launch"]
        script = launches[0].kwargs["command"][-1]
        self.assertIn("set -euo pipefail", script)
        self.assertIn("USE_SERIAL_PORT=0", script)
        self.assertIn("CPU=nutshell", script)
        self.assertIn("DIFFTEST_PERFCNT=1", script)
        self.assertEqual(launches[0].kwargs["env"], {"GBUS_LIBUVGBUS": "/vendor/gbus/lib/libuvgbus.so"})
        syncs = self.s.fpga.sync.call_args_list
        self.assertIn(".github/", syncs[2].args[2])
        self.assertIn("*.md", syncs[2].args[2])

    def test_build_requires_explicit_vendor_link_config_before_upload(self):
        del self.s.env["GBUS_LIBUVGBUS"]
        with self.assertRaisesRegex(RuntimeError, "explicit FPGA-host"):
            self.s.build()
        self.s.fpga.sync.assert_not_called()
        self.s.fpga.call.assert_not_called()

    def test_worker_preserves_explicit_build_link_settings_only(self):
        directory = self.new_owned()
        spec = directory / "build.spec.json"
        spec.write_text(json.dumps({"directory": str(directory), "token": "token", "name": "build",
                                    "command": [sys.executable, "-c", "print('build')"],
                                    "env": {"GBUS_RUNTIME_ROOT": "/vendor/gbus"}, "timeout": 10}))
        identity = {"pid": 4321, "start": "123", "state": "S", "uid": os.getuid(), "cwd": str(directory), "env": []}
        child = Mock()
        child.poll.return_value = 0
        child.wait.return_value = 0
        with patch.dict(os.environ, {"GBUS_C2H_MODE": "unsafe", "GBUS_LIBUVGBUS": "/stale/lib.so"}), \
             patch.object(g, "proc_identity", return_value=identity), patch.object(g.subprocess, "Popen", return_value=child) as start:
            self.assertEqual(g.worker(spec), 0)
        env = start.call_args.kwargs["env"]
        self.assertEqual(env["GBUS_RUNTIME_ROOT"], "/vendor/gbus")
        self.assertNotIn("GBUS_C2H_MODE", env)
        self.assertNotIn("GBUS_LIBUVGBUS", env)

    def test_release_mismatch_and_no_arbitrary_generated_fallback(self):
        release = self.base / "release/build/generated-src"
        project = self.base / "project"
        (project / "rtl").mkdir(parents=True)
        (project / "rtl/filelist.f").write_text("+define+CPU_NUTSHELL\n+define+DIFFTEST_HOST_GBUS\n/source/src/rtl/nutshell/SimTop_wrapper.sv\n+incdir+" + str(release) + "\n")
        self.s.release(project)
        self.assertEqual(self.s.generated, release)
        self.s.env["RELEASE_DIR"] = str(self.base / "wrong")
        with self.assertRaisesRegex(RuntimeError, "does not match"):
            self.s.release(project)

    def test_project_cpu_hostif_and_dma_must_match_manifest(self):
        project = self.base / "project"
        (project / "rtl").mkdir(parents=True)
        filelist = project / "rtl/filelist.f"
        incdir = "+incdir+" + str(self.base / "release/build/generated-src") + "\n/source/src/rtl/nutshell/SimTop_wrapper.sv\n"
        self.s.mode = "axi-dma"
        for defines in ("+define+CPU_KMH\n+define+DIFFTEST_HOST_GBUS\n+define+UVHS_GBUS_C2H_DMA\n",
                        "+define+CPU_NUTSHELL\n+define+DIFFTEST_HOST_XDMA\n+define+UVHS_GBUS_C2H_DMA\n",
                        "+define+CPU_NUTSHELL\n+define+DIFFTEST_HOST_GBUS\n"):
            filelist.write_text(defines + incdir)
            with self.assertRaisesRegex(RuntimeError, "project CPU|G[^ ]* host interface|DMA-enabled"):
                self.s.release(project)
        filelist.write_text("+define+CPU_NUTSHELL\n+define+DIFFTEST_HOST_GBUS\n+define+UVHS_GBUS_C2H_DMA\n" + incdir)
        self.s.release(project)

    def test_actual_kmh_and_nanhu_filelist_identity_without_new_cpu_macros(self):
        project = self.base / "project"
        (project / "rtl").mkdir(parents=True)
        filelist = project / "rtl/filelist.f"
        incdir = "+incdir+" + str(self.base / "release/build/generated-src") + "\n"
        for cpu in ("kmh", "nanhu"):
            self.s.inputs["cpu"] = cpu
            filelist.write_text("+define+DIFFTEST_HOST_GBUS\n/source/src/rtl/" + cpu + "/SimTop_wrapper.sv\n" + incdir)
            self.s.release(project)
            filelist.write_text("+define+DIFFTEST_HOST_GBUS\n/source/src/rtl/nutshell/SimTop_wrapper.sv\n" + incdir)
            with self.assertRaisesRegex(RuntimeError, "project CPU"):
                self.s.release(project)

    def test_large_remote_logs_do_not_kill_application(self):
        directory = self.new_owned()
        size = 10 * 1024 * 1024
        command = "import pathlib,sys; data=b'x'*" + str(size) + "; pathlib.Path('vendor.log').write_bytes(data); sys.stdout.buffer.write(data)"
        self.launch_mock_host(directory, [sys.executable, "-c", command], timeout=10)
        state = self.wait(directory, "host")
        self.assertEqual(state["rc"], 0)
        self.assertEqual(state["result"]["child_rc"], 0)
        self.assertEqual((directory / "host.log").stat().st_size, size)
        self.assertEqual((directory / "vendor.log").stat().st_size, size)
        self.assertIn("disk_guard", state["result"])
        self.assertLess(len(g.sample(directory / "host.log")["sample_b64"]), g.SAMPLE_CAP * 2)

    def test_worker_pipefail_not_masked_by_tee(self):
        directory = self.new_owned()
        g.launch(str(directory), "token", "build", ["bash", "-c", "set -o pipefail; exitcode() { return 23; }; exitcode | tee make.log"], timeout=5)
        state = self.wait(directory, "build")
        self.assertEqual(state["rc"], 23)
        self.assertEqual(state["result"]["child_rc"], 23)
        self.assertFalse((directory / "build.rc.tmp").exists())

    def test_dma_goodtrap_requires_nonzero_progress_and_actual_success(self):
        status = {"rc": 0, "result": {"rc": 0, "child_rc": 0, "reason": "exited", "cleanup_errors": []}}
        dma = DMA_GOOD
        self.assertEqual(g.verdict(status, dma, "axi-dma")["verdict"], "good_trap")
        for text in (dma.replace("bytes=768", "bytes=0"), dma.replace("banks=1", "banks=0"),
                     dma.replace("AXI verified", "AXI unverified"), dma.replace("mirror verified", "mirror absent"),
                     dma.replace("Difftest PerfCnt", "no PerfCnt"), dma + "HIT BAD TRAP", GOOD):
            self.assertEqual(g.verdict(status, text, "axi-dma")["verdict"], "failed_or_unproven")
        status["result"]["child_rc"] = 1
        self.assertEqual(g.verdict(status, dma, "axi-dma")["verdict"], "failed_or_unproven")

    def test_goodtrap_requires_actual_rc0_transport_and_no_timeout(self):
        directory = self.new_owned()
        started = time.monotonic()
        self.launch_mock_host(directory, [sys.executable, "-c", "import time; print(" + repr(GOOD) + ", flush=True); time.sleep(5)"], timeout=.3)
        self.assertLess(time.monotonic() - started, 1)
        state = self.wait(directory, "host")
        self.assertEqual(state["rc"], 124)
        self.assertEqual(g.verdict(state, GOOD, "config-window")["verdict"], "timeout")
        other = self.new_owned("success")
        self.launch_mock_host(other, [sys.executable, "-c", "print(" + repr(GOOD) + ")"], timeout=5)
        ok = self.wait(other, "host")
        self.assertEqual(g.verdict(ok, GOOD, "config-window")["verdict"], "good_trap")
        self.assertEqual(g.verdict(ok, "HIT GOOD TRAP", "config-window")["verdict"], "failed_or_unproven")
        self.assertEqual(g.verdict({"rc": None, "result": None}, GOOD, "config-window")["verdict"], "pending")
        self.assertEqual(g.verdict(dict(ok, rc=1), GOOD, "config-window")["verdict"], "failed_or_unproven")
        self.assertNotEqual(g.verdict(ok, GOOD + "HIT BAD TRAP", "config-window")["verdict"], "good_trap")

    def test_cleanup_identity_rejects_reused_pid_foreign_cwd_token_worker(self):
        directory = self.new_owned()
        record = {"pid": 123, "start": "100", "worker": "host"}
        valid = {"pid": 123, "start": "100", "state": "S", "uid": os.getuid(), "cwd": str(directory),
                 "env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=host"]}
        with patch.object(g.os, "pidfd_open", return_value=999, create=True), patch.object(g.os, "close"), \
             patch.object(g.signal, "pidfd_send_signal", create=True) as send:
            for update in ({"start": "101"}, {"cwd": str(self.base)}, {"env": []},
                           {"env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=uart"]}):
                with patch.object(g, "proc_identity", return_value=dict(valid, **update)):
                    with self.assertRaisesRegex(RuntimeError, "identity/cwd/token"):
                        g.safe_signal(record, directory, "token")
                    send.assert_not_called()
            with patch.object(g, "proc_identity", return_value=valid):
                g.safe_signal(record, directory, "token")
                send.assert_called_once()

    def test_foreign_runtime_shell_busy_build_shell_exempt(self):
        proc = self.base / "proc"
        proc.mkdir()
        p = proc / "101"
        p.mkdir()
        for args, expected in ((["uv_shell", "-s", "backend_run.tcl"], "free"),
                               (["uv_shell", "-rt_shell", "-script", "runtime_server.tcl"], "busy"),
                               (["uv_shell_exec"], "busy"),
                               (["uv_shell", "-s", "unknown.tcl"], "busy")):
            (p / "cmdline").write_bytes("\0".join(args).encode())
            self.assertEqual(g.board_state(proc)["state"], expected)
        original = Path.read_bytes
        def deny(path):
            if path.name == "cmdline":
                raise PermissionError("proc denied")
            return original(path)
        with patch.object(Path, "read_bytes", deny):
            self.assertEqual(g.board_state(proc)["state"], "unknown")

    def test_uploaded_hash_mismatch_is_fatal(self):
        directory = self.new_owned()
        (directory / "workload").mkdir()
        (directory / "workload/hello.bin").write_bytes(b"wrong")
        with self.assertRaisesRegex(RuntimeError, "hash mismatch"):
            g.remote({"action": "inputs", "directory": str(directory), "token": "token",
                      "workload_sha": g.digest(self.workload), "reference_sha": g.digest(self.reference)})

    def test_logs_are_bounded_and_no_vendor_or_donor_collection(self):
        directory = self.new_owned()
        (directory / "host.log").write_bytes(b"a" * (g.SAMPLE_CAP * 3))
        (directory / "vendor-secret.log").write_bytes(b"do not collect")
        (directory / "old-run.log").write_bytes(b"HIT GOOD TRAP")
        logs = g.remote({"action": "logs", "directory": str(directory), "token": "token"})
        self.assertEqual(set(logs), {"host.log"})
        self.assertLess(len(logs["host.log"]["sample_b64"]), g.SAMPLE_CAP * 2)

    def test_dmesg_permission_error_preserved(self):
        directory = self.new_owned()
        failed = subprocess.CompletedProcess(["dmesg"], 1, b"", b"Operation not permitted")
        with patch.object(g.subprocess, "run", return_value=failed):
            result = g.remote({"action": "diagnostics", "directory": str(directory), "token": "token"})
        self.assertEqual(result["dmesg"]["rc"], 1)
        self.assertIn("not permitted", result["dmesg"]["stderr"])

    def test_existing_owned_directory_never_reused(self):
        directory = self.new_owned()
        with self.assertRaises(FileExistsError):
            g.init_owned(str(directory), "token", "test", "")

    def test_occupied_retry_uses_unique_dirs_and_cleans_before_retry(self):
        self.s.project = self.base
        self.s.runtime_package = self.base / "package"
        self.s.revalidate_runtime_package = Mock()
        self.s.wait_board = Mock()
        self.s.init = Mock()
        self.s.start = Mock()
        self.s.stop = Mock()
        self.s.require_session_health = Mock()
        self.s.collect_one = Mock()
        self.s.inputs["runtime_files"] = {"input.bin": "hash"}
        calls = []
        def rpc(host, directory, action, **kwargs):
            calls.append((directory, action))
            if action == "status":
                if directory.endswith("attempt-2"):
                    return {"ready": True, "result": None, "rc": None}
                return {"ready": False, "result": {"rc": 3}, "rc": 3}
            if action == "logs":
                return {"uv_shell.log": {"sample_b64": g.base64.b64encode(b"RTM-101 occupied by other users").decode()}}
            return {}
        self.s.rpc = rpc
        self.s.runtime()
        launches = self.s.start.call_args_list
        self.assertEqual(len(launches), 2)
        self.assertNotEqual(launches[0].args[1], launches[1].args[1])
        self.s.stop.assert_called_once_with(self.s.rt, self.s.stage + "/attempt-1", "runtime")
        self.assertEqual(self.s.attempt, self.s.stage + "/attempt-2")
        self.assertIn("bash", launches[0].args[3][-1])
        self.assertIn("/bin/uv_shell", launches[0].args[3][-1])
        self.assertEqual(launches[0].args[4]["UVHS_RUNTIME_PRESERVE_ON_TIMEOUT"], "1")
        self.assertIn("runtime_package", [action for _, action in calls])
        self.assertEqual(self.s.rt.sync.call_args_list[0].args,
                         (str(self.s.runtime_package), self.s.stage + "/hw.dat"))
        self.assertNotIn("UVHS_IGNORE_TIMING_SIGNOFF_ERROR", launches[0].args[4])

    def test_ready_marker_never_overrides_failed_runtime(self):
        self.s.project = self.base
        self.s.runtime_package = self.base / "package"
        self.s.revalidate_runtime_package = Mock()
        self.s.inputs["runtime_files"] = {"input.bin": "hash"}
        self.s.wait_board = Mock()
        self.s.init = Mock()
        self.s.start = Mock()
        self.s.stop = Mock()
        self.s.require_session_health = Mock()
        self.s.collect_one = Mock()
        def rpc(host, directory, action, **kwargs):
            if action == "status":
                return {"ready": True, "result": {"rc": 1}, "rc": 1}
            if action == "logs":
                return {}
            return {}
        self.s.rpc = rpc
        with self.assertRaisesRegex(RuntimeError, "runtime failed/timeout"):
            self.s.runtime()
        self.s.require_session_health.assert_not_called()
        self.s.stop.assert_called_once()

    def test_worker_stop_cleans_only_its_own_child(self):
        directory = self.new_owned()
        self.launch_mock_host(directory, [sys.executable, "-c", "import time; time.sleep(20)"], timeout=30)
        deadline = time.monotonic() + 5
        while not (directory / "host.children.json").exists() and time.monotonic() < deadline:
            time.sleep(.05)
        g.remote({"action": "stop", "directory": str(directory), "token": "token", "name": "host"})
        status = self.wait(directory, "host")
        self.assertEqual(status["rc"], 143)
        self.assertEqual(status["result"]["cleanup_errors"], [])
        records = json.loads((directory / "host.children.json").read_text())
        for record in records:
            try:
                current = g.proc_identity(record["pid"])
            except (FileNotFoundError, ProcessLookupError):
                continue
            self.assertTrue(current["state"] == "Z" or current["start"] != record["start"])

    def test_legacy_retention_only_audits_never_deletes(self):
        old = self.base / "runtime_stage_test_run1"
        old.mkdir()
        (old / "dataset").write_text("preserve")
        with patch.object(Path, "iterdir", return_value=iter([old])):
            result = g.remote({"action": "retention", "prefix": "runtime_stage_test_"})
        self.assertEqual(result["removed"], [])
        self.assertEqual(result["reclaimed_bytes"], 0)
        self.assertIn("SKIP", result["skipped"][0]["decision"])
        self.assertTrue((old / "dataset").exists())

    def test_retention_blocks_fourth_upload_without_deleting_anything(self):
        directory = self.base / "runtime-uploads"
        directory.mkdir()
        for i in range(2):
            g.init_owned(str(directory / ("runtime_stage_test_" + str(i))), "token" + str(i), "test", "")
        self.assertTrue(g.retention_guard("test", directory)["upload_allowed"])
        g.init_owned(str(directory / "runtime_stage_test_2"), "token2", "test", "")
        with self.assertRaisesRegex(RuntimeError, "retention limit reached"):
            g.retention_guard("test", directory)
        self.assertEqual(len(list(directory.iterdir())), 3)

    def test_retention_uncertain_same_series_blocks_before_upload(self):
        directory = self.base / "runtime-uploads"
        directory.mkdir()
        (directory / "runtime_stage_test_uncertain").mkdir()
        with self.assertRaisesRegex(RuntimeError, "cannot certify"):
            g.retention_guard("test", directory)

    def test_retention_guard_runs_before_runtime_stage_or_sync(self):
        self.s.wait_board = Mock()
        self.s.revalidate_runtime_package = Mock()
        self.s.rt.call.side_effect = RuntimeError("retention limit reached")
        self.s.init = Mock()
        with self.assertRaisesRegex(RuntimeError, "retention limit"):
            self.s.runtime()
        self.s.init.assert_not_called()
        self.s.rt.sync.assert_not_called()

    def test_rsync_has_no_delete_option(self):
        remote = g.Remote("fake", self.key)
        with patch.object(g.subprocess, "run") as run:
            remote.sync("/source/", "/isolated/dest/", ("build/",))
        self.assertFalse(any("--delete" in arg for arg in run.call_args.args[0]))

    def test_manifest_requires_explicit_mode_cpu_hash_and_perfcnt(self):
        for change in ({"cpu": ""}, {"cpu": "nutshel"}, {"c2h_mode": ""},
                       {"c2h_mode": "AXI"}, {"difftest_perfcnt": 0}, {"difftest_perfcnt": True},
                       {"workload": {"path": str(self.workload), "sha256": "0" * 64}}):
            self.manifest.write_text(json.dumps(dict(self.input_data, **change)))
            with self.assertRaises(RuntimeError):
                g.test_inputs(self.manifest)
        self.manifest.write_text(json.dumps(self.input_data))
        self.assertEqual(g.test_inputs(self.manifest)["cpu"], "nutshell")
        self.workload.write_bytes(b"changed after manifest")
        with self.assertRaisesRegex(RuntimeError, "hash mismatch"):
            g.test_inputs(self.manifest)

    def test_health_detects_live_kernel_ack_errors_despite_stale_daemon_log(self):
        first = {"services": {}, "kernel": "", "uptime": 1000, "daemon": "old healthy", "time": 1, "boot_id": "boot"}
        for line, expected in (("[1001.23] invalid read ACK packet_id", "unhealthy"),
                               ("[1001.23] FIFO read timeout", "unhealthy"),
                               ("[10.00] invalid read ACK packet_id", "unhealthy"),
                               ("[1001.23] ordinary status", "healthy")):
            before = dict(first, kernel=line if expected == "healthy" else "")
            with patch.object(g, "transport_snapshot", side_effect=[before, dict(first, kernel=line)]), patch.object(g.time, "sleep"):
                self.assertEqual(g.transport_health()["state"], expected)
        with patch.object(g, "transport_snapshot", side_effect=PermissionError("dmesg denied")):
            self.assertEqual(g.transport_health()["state"], "unknown")
        ambiguous = dict(first, kernel="invalid read ACK packet_id")
        with patch.object(g, "transport_snapshot", side_effect=[ambiguous, ambiguous]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_health_detects_new_ack_despite_kernel_uptime_drift(self):
        first = {"services": {}, "kernel": "[19477.00] invalid read ACK packet_id", "uptime": 19498,
                 "daemon": "stale", "time": time.time(), "boot_id": "boot"}
        second = dict(first, kernel=first["kernel"] + "\n[19479.00] invalid read ACK packet_id")
        with patch.object(g, "transport_snapshot", side_effect=[first, second]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_health_unknown_if_kernel_snapshots_cannot_align(self):
        first = {"services": {}, "kernel": "[100] old status", "uptime": 1000,
                 "daemon": "stale", "time": time.time(), "boot_id": "boot"}
        with patch.object(g, "transport_snapshot", side_effect=[first, dict(first, kernel="[1002] unrelated status")]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unknown")
        line = "[19477.00] " + time.strftime("%Y-%m-%d %H:%M:%S") + ".001 invalid write ACK packet_id"
        first["kernel"] = line
        with patch.object(g, "transport_snapshot", side_effect=[first, first]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_host_never_launches_dma_with_unhealthy_session(self):
        self.s.attempt = "/owned/attempt"
        self.s.rpc = Mock(return_value={"board": {"state": "free"}, "transport": {"state": "unhealthy"}})
        self.s.start = Mock()
        with self.assertRaisesRegex(RuntimeError, "no host DMA"):
            self.s.run_host()
        self.s.start.assert_not_called()

    def test_host_requires_live_owned_runtime_not_only_transport_health(self):
        self.s.attempt = "/owned/attempt"
        self.s.rpc = Mock(side_effect=RuntimeError("runtime readiness lacks a live owned process"))
        self.s.start = Mock()
        with self.assertRaisesRegex(RuntimeError, "live owned"):
            self.s.run_host()
        self.s.start.assert_not_called()

    def test_ssh_uses_distinct_explicit_keys_and_no_jump(self):
        self.assertIn("-i", g.Remote("root@runtime", self.key).ssh)
        self.assertIn("IdentitiesOnly=yes", g.Remote("root@runtime", self.key).ssh)
        self.assertNotIn("-J", g.Remote("root@runtime", self.key).ssh)

    def runtime_fixture(self):
        stage = self.new_owned("runtime-stage")
        directory = stage / "attempt-1"
        g.init_owned(str(directory), "token", "test", "")
        script = stage / "runtime_session.sh"
        script.write_text("normal stop only\n")
        (directory / "runtime.spec.json").write_text(json.dumps({"host_directory": "/mock-host",
            "env": {"UVHS_SESSION_SCRIPT_SHA256": g.digest(script),
                    "UVHS_RUNTIME_SAFETY_HELPER": str(directory / "gbus_supervisor.py")}}))
        proof = {"token": "token", "host_directory": "/mock-host", "state": "never_started", "sealed": True}
        (directory / "runtime-stop-permit.json").write_text(json.dumps({"token": "token",
            "runtime_directory": str(directory), "pid": 4321, "start": "123", "host": proof,
            "expires": time.monotonic() + 60}))
        record = {"pid": 4321, "start": "123", "worker": "runtime"}
        (directory / "runtime.children.json").write_text(json.dumps([record]))
        (directory / "uv_shell.pid").write_text("4321\n")
        (directory / "uv_shell.ready").write_text("4321\n")
        identity = {"pid": 4321, "start": "123", "state": "S", "uid": os.getuid(), "cwd": str(directory),
                    "env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=runtime"]}
        return directory, identity

    def test_graceful_runtime_stop_enqueue_then_wait_with_owned_identity(self):
        directory, identity = self.runtime_fixture()
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"), \
             patch.object(g.subprocess, "run") as run, patch.object(g, "safe_signal") as kill:
            run.return_value.returncode = 0
            self.assertEqual(g.graceful_runtime_stop(directory, "token")["state"], "gracefully stopped")
            self.assertEqual([call.args[0][2] for call in run.call_args_list], ["enqueue", "wait"])
            self.assertEqual(run.call_args_list[0].args[0][-1], "stop")
            self.assertEqual(run.call_args_list[0].kwargs["env"]["UVHS_RUNTIME_SAFETY_HELPER"],
                             str(directory / "gbus_supervisor.py"))
            self.assertEqual(run.call_args_list[0].kwargs["env"]["GBUS_OWNER_TOKEN"], "token")
            self.assertEqual(run.call_args_list[0].kwargs["env"]["GBUS_WORKER_NAME"], "runtime")
            kill.assert_not_called()

    def test_graceful_runtime_stop_refuses_foreign_pid_or_timeout_without_kill(self):
        directory, identity = self.runtime_fixture()
        for altered in (dict(identity, start="other"), dict(identity, env=[]), dict(identity, cwd=str(self.base))):
            with patch.object(g, "proc_identity", return_value=altered), patch.object(g.subprocess, "run") as run:
                with self.assertRaisesRegex(RuntimeError, "mismatch"):
                    g.graceful_runtime_stop(directory, "token")
                run.assert_not_called()
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"), \
             patch.object(g.subprocess, "run") as run, patch.object(g, "safe_signal") as kill:
            run.return_value.returncode = 11
            with self.assertRaisesRegex(RuntimeError, "session preserved"):
                g.graceful_runtime_stop(directory, "token")
            self.assertEqual(len(run.call_args_list), 1)
            kill.assert_not_called()

    def test_failed_runtime_cleanup_preserves_children(self):
        directory = self.new_owned()
        spec = directory / "runtime.spec.json"
        spec.write_text(json.dumps({"directory": str(directory), "token": "token", "name": "runtime",
                                    "command": ["fake-command"], "env": {}, "timeout": 1}))
        identity = {"pid": 4321, "start": "123", "state": "S", "uid": os.getuid(), "cwd": str(directory),
                    "env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=runtime"]}
        child = Mock()
        child.poll.return_value = 1
        child.wait.return_value = 1
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"), \
             patch.object(g.subprocess, "Popen", return_value=child), \
             patch.object(g, "graceful_runtime_stop", side_effect=RuntimeError("not ready; session preserved")), patch.object(g, "safe_signal") as kill:
            g.worker(spec)
            kill.assert_not_called()
        result = json.loads((directory / "runtime.result.json").read_text())
        self.assertIn("session preserved", result["cleanup_errors"][0])

    def test_exited_runtime_pid_does_not_authorize_killing_live_children(self):
        directory, identity = self.runtime_fixture()
        child = dict(identity, pid=4322)
        records = json.loads((directory / "runtime.children.json").read_text())
        records.append({"pid": 4322, "start": "123", "worker": "runtime"})
        (directory / "runtime.children.json").write_text(json.dumps(records))
        def process(pid, *args):
            if pid == 4321:
                raise ProcessLookupError()
            return child
        with patch.object(g, "proc_identity", side_effect=process), patch.object(g.subprocess, "run") as run, patch.object(g, "safe_signal") as kill:
            with self.assertRaisesRegex(RuntimeError, "live child remains; session preserved"):
                g.graceful_runtime_stop(directory, "token")
            run.assert_not_called()
            kill.assert_not_called()

    def test_staged_runtime_package_must_match_before_programming(self):
        directory = self.new_owned()
        (directory / "hw.dat").mkdir()
        (directory / "hw.dat" / "input.bin").write_bytes(b"transport corrupted package")
        with self.assertRaisesRegex(RuntimeError, "runtime package mismatch"):
            g.remote({"action": "runtime_package", "directory": str(directory), "token": "token", "manifest": {"input.bin": "0" * 64}})

    def package_fixture(self):
        self.s.project = self.base / "compiled"
        self.s.project.mkdir()
        (self.s.project / "frontend_run.log").write_text("UVHS_FRONTEND_SUCCESS\n")
        (self.s.project / "backend_run.log").write_text(
            "UVHS_CLOCK_INFERENCE_SUCCESS\nUVHS_CLOCK_TRANSFORM_SUCCESS\nUVHS_BACKEND_SUCCESS\n")
        source = self.s.project / "hw.dat"
        for name in ("DB/Options/o", "DB/Linkage/l", "DB/Sys_Design/s", "DB/Names/name.db",
                     "DB/Runtime/uvrtdb/uvrtdb.hash", "DB/Runtime/uvrtdb/runtime.dat.zst",
                     "DB/Runtime/uvrtdb/sec.dat", "DB/Runtime/uvrtdb/mem.dat"):
            path = source / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(name.encode())
        for fpga in ("F0", "F1", "F2"):
            parent = source / "Compile/PnR/B0" / fpga
            parent.mkdir(parents=True)
            (parent / "backing.bin").write_bytes(fpga.encode())
            (parent / ("MOD_b0_" + fpga.lower() + ".bin")).symlink_to("backing.bin")
        package = self.base / "exported"
        result = g.load_local_tool("uvhs_runtime_package").export_runtime(source, package)
        self.s.inputs.update(runtime_package_dir=str(package), runtime_files=result["files"])
        return source, package

    def test_regular_runtime_package_matches_vendor_links_and_all_three_fpgas(self):
        source, package = self.package_fixture()
        self.s.validate_runtime_package()
        self.assertEqual(self.s.runtime_package, package)
        self.assertTrue((source / "Compile/PnR/B0/F1/MOD_b0_f1.bin").is_symlink())
        self.s.rt.call.assert_not_called()

    def test_caught_clock_error_blocks_before_host_build_or_runtime(self):
        self.package_fixture()
        log = self.s.project / "backend_run.log"
        log.write_text("[TCK-123] ERROR: dangling clock\n" + log.read_text())
        self.s.env["PRJ_DIR"] = str(self.s.project)
        self.s.release = Mock()
        self.s.build = Mock()
        self.s.runtime = Mock()
        self.s.finish = Mock(side_effect=lambda rc: rc)
        self.assertEqual(self.s.execute("supervise"), 1)
        self.s.build.assert_not_called()
        self.s.runtime.assert_not_called()

    def test_package_unrelated_to_build_or_missing_f1_blocks(self):
        source, package = self.package_fixture()
        bit = package / "Compile/PnR/B0/F1/MOD_b0_f1.bin"
        bit.write_bytes(b"foreign F1")
        self.s.inputs["runtime_files"] = g.manifest(package)
        with self.assertRaisesRegex(RuntimeError, "compiled project"):
            self.s.validate_runtime_package()
        (source / "Compile/PnR/B0/F1/MOD_b0_f1.bin").unlink()
        bit.unlink()
        (package / "Compile/PnR/B0/F1/backing.bin").unlink()
        self.s.inputs["runtime_files"] = g.manifest(package)
        with self.assertRaisesRegex(RuntimeError, "required runtime"):
            self.s.validate_runtime_package()

    def test_raw_vendor_db_cannot_be_used_as_regular_runtime_package(self):
        source, package = self.package_fixture()
        self.s.inputs["runtime_package_dir"] = str(source)
        with self.assertRaisesRegex(RuntimeError, "symlink"):
            self.s.validate_runtime_package()

    def test_special_file_in_package_rejected_even_when_file_hashes_match(self):
        source, package = self.package_fixture()
        os.mkfifo(package / "extra-fifo")
        with self.assertRaisesRegex(RuntimeError, "special file"):
            self.s.validate_runtime_package()

    def test_mutation_during_host_build_blocks_before_upload_or_init(self):
        source, package = self.package_fixture()
        self.s.validate_runtime_package()
        (package / "DB/Runtime/uvrtdb/sec.dat").write_bytes(b"changed after initial gate")
        self.s.wait_board = Mock()
        self.s.init = Mock()
        with self.assertRaisesRegex(RuntimeError, "changed before upload"):
            self.s.runtime()
        self.s.wait_board.assert_not_called()
        self.s.init.assert_not_called()
        self.s.rt.sync.assert_not_called()

    def test_mutation_while_waiting_for_board_blocks_before_upload(self):
        source, package = self.package_fixture()
        self.s.validate_runtime_package()
        self.s.wait_board = Mock(side_effect=lambda: (package / "DB/Runtime/uvrtdb/sec.dat").write_bytes(b"changed in wait"))
        self.s.init = Mock()
        with self.assertRaisesRegex(RuntimeError, "changed before upload"):
            self.s.runtime()
        self.s.init.assert_not_called()
        self.s.rt.sync.assert_not_called()

    def test_runtime_timeout_preserves_session_without_pid_only_signal(self):
        directory = self.base / "runtime-timeout"
        directory.mkdir()
        # The helper and sleeping child are local inert fixtures, not UVHS clients.
        helper = directory / "guard.py"
        helper.write_text("print('mock launch permitted')\n")
        script = TOOLS.parent / "uvhs/runtime/runtime_session.sh"
        env = dict(os.environ, UVHS_RUNTIME_SAFETY_HELPER=str(helper), GBUS_OWNER_TOKEN="mock")
        env.pop("UVHS_RUNTIME_PRESERVE_ON_TIMEOUT", None)
        pid = None
        try:
            result = subprocess.run(["bash", str(script), "start", str(directory / "pid"), str(directory / "ready"),
                                     str(directory / "log"), str(directory / "command"), "1", sys.executable,
                                     "-c", "import time; time.sleep(30)"], env=env, capture_output=True, timeout=5)
            pid = int((directory / "pid").read_text())
            self.assertEqual(result.returncode, 4)
            self.assertIn(b"session and evidence preserved", result.stderr)
            os.kill(pid, 0)
        finally:
            if pid is not None:
                os.kill(pid, g.signal.SIGTERM)

    def test_actual_timeout_forms_and_old_faults_remain_unhealthy(self):
        first = {"services": {}, "kernel": "", "uptime": 1000, "daemon": "", "time": time.time(), "boot_id": "boot"}
        for text in ("reg rw timeout", "IOCTL_XDMA_READ failed", "consumeDmaData timeout",
                     "FIFO length mismatch", "invalid write ACK"):
            with self.subTest(text=text), patch.object(g.time, "sleep"):
                snapshot = dict(first, kernel="[10.00] " + text)
                with patch.object(g, "transport_snapshot", side_effect=[snapshot, snapshot]):
                    self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_boot_change_unknown_and_stale_daemon_fault_current_boot_latches(self):
        now = time.time()
        first = {"services": {}, "kernel": "", "uptime": 1000, "daemon": "", "time": now, "boot_id": "boot"}
        with patch.object(g, "transport_snapshot", side_effect=[first, dict(first, boot_id="other")]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unknown")
        for age, expected in ((30, "unhealthy"), (2000, "healthy")):
            line = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(now - age)) + " reg rw timeout"
            snapshot = dict(first, daemon=line)
            with patch.object(g, "transport_snapshot", side_effect=[snapshot, snapshot]), patch.object(g.time, "sleep"):
                self.assertEqual(g.transport_health()["state"], expected)

    def test_session_unknown_or_fault_never_ages_out(self):
        directory = self.new_owned()
        with patch.object(g, "transport_health", return_value={"state": "unknown", "error": "logs denied"}) as health:
            self.assertEqual(g.session_transport_health(directory, "token")["state"], "unknown")
            health.return_value = {"state": "healthy"}
            self.assertEqual(g.session_transport_health(directory, "token")["state"], "unhealthy")
            self.assertEqual(health.call_count, 1)

    def test_direct_host_launch_requires_permit_even_via_rpc(self):
        directory = self.new_owned()
        with patch.object(g.subprocess, "Popen") as start:
            for route in (lambda: g.launch(str(directory), "token", "host", ["fake-host"]),
                          lambda: g.remote({"action": "launch", "directory": str(directory), "token": "token",
                                            "name": "host", "command": ["fake-host"], "timeout": 10})):
                with self.assertRaisesRegex(RuntimeError, "mandatory owned runtime"):
                    route()
            start.assert_not_called()
        self.assertFalse((directory / "host.spec.json").exists())

    def test_host_launch_permit_requires_live_healthy_bound_runtime(self):
        directory, identity = self.runtime_fixture()
        command = ["mock-host"]
        (directory / "runtime-stop-permit.json").unlink()
        with patch.object(g, "proc_identity", return_value=identity), \
             patch.object(g, "require_session_safe", side_effect=RuntimeError("transport unhealthy")):
            with self.assertRaisesRegex(RuntimeError, "unhealthy"):
                g.authorize_host_launch(directory, "token", "/mock-host", command)
        with patch.object(g, "proc_identity", return_value=identity), \
             patch.object(g, "require_session_safe", return_value={"transport": {"boot_id": "boot"}}):
            permit = g.authorize_host_launch(directory, "token", "/mock-host", command)
            self.assertEqual(permit["pid"], 4321)
            with self.assertRaisesRegex(RuntimeError, "repeated host launch"):
                g.authorize_host_launch(directory, "token", "/mock-host", command)

    def test_sealed_host_never_starts_again_and_failed_exit_no_runtime_permit(self):
        directory = self.new_owned()
        with patch.object(Path, "iterdir", return_value=iter([])):
            self.assertEqual(g.host_quiescent(directory, "token")["state"], "never_started")
        with self.assertRaisesRegex(RuntimeError, "sealed"):
            self.launch_mock_host(directory, ["fake-host"])
        (directory / "host.spec.json").write_text("{}")
        (directory / "host.result.json").write_text(json.dumps({"rc": 1, "child_rc": 1, "reason": "exited"}))
        (directory / "host.rc").write_text("1")
        with patch.object(Path, "iterdir", return_value=iter([])):
            with self.assertRaisesRegex(RuntimeError, "clean exit unconfirmed"):
                g.host_quiescent(directory, "token")

    def test_host_exit_proof_permission_unknown_blocks_and_seals(self):
        directory = self.new_owned()
        process = self.base / "12345"
        process.mkdir()
        with patch.object(Path, "iterdir", return_value=iter([process])), \
             patch.object(g, "proc_identity", side_effect=PermissionError("proc access denied")):
            with self.assertRaises(PermissionError):
                g.host_quiescent(directory, "token")
        self.assertTrue((directory / "host-closed.json").exists())
        self.assertFalse((directory / "host-quiescent.json").exists())

    def test_socket_finalize_is_not_vendor_daemon_drain(self):
        host = self.new_owned()
        (host / "host.spec.json").write_text("{}")
        (host / "host.result.json").write_text(json.dumps({"rc": 0, "child_rc": 0, "reason": "exited", "cleanup_errors": []}))
        (host / "host.rc").write_text("0")
        (host / "host.log").write_text(g.HOST_FINALIZED + "\n")
        with patch.object(Path, "iterdir", return_value=iter([])):
            proof = g.host_quiescent(host, "token")
        self.assertEqual(proof["state"], "finalized")
        self.assertEqual(proof["daemon_request_drain"], "unproven")
        directory, identity = self.runtime_fixture()
        proof["host_directory"] = "/mock-host"
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe") as health:
            with self.assertRaisesRegex(RuntimeError, "daemon request drain unproven"):
                g.authorize_runtime_stop(directory, "token", proof)
            health.assert_not_called()

    def test_runtime_stop_requires_positive_proof_and_one_shot_identity_bound_permit(self):
        directory, identity = self.runtime_fixture()
        permit = directory / "runtime-stop-permit.json"
        permit.unlink()
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g.subprocess, "run") as run:
            with self.assertRaises(FileNotFoundError):
                g.graceful_runtime_stop(directory, "token")
            run.assert_not_called()
        proof = {"token": "token", "host_directory": "/mock-host", "state": "never_started", "sealed": True}
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"):
            g.authorize_runtime_stop(directory, "token", proof)
            g.require_runtime_stop_permit(directory, "token", consume=True)
            self.assertFalse(permit.exists())
            with self.assertRaises(FileNotFoundError):
                g.require_runtime_stop_permit(directory, "token", consume=True)

    def test_host_stop_failure_blocks_runtime_cleanup_in_finish(self):
        self.s.workers = [(self.s.rt, "/mock-runtime", "runtime"), (self.s.fpga, "/mock-host", "host")]
        self.s.stop = Mock(side_effect=RuntimeError("host stop identity unknown"))
        self.assertEqual(self.s.finish(1), 1)
        self.s.stop.assert_called_once_with(self.s.fpga, "/mock-host", "host")
        self.assertIn("runtime preserved", self.s.result["cleanup_collection_errors"][-1])

    def test_runtime_timeout_disk_cancel_do_not_signal_descendants(self):
        for failure, expected in (("timeout", 124), ("disk_guard", 125), ("cancelled", 143)):
            with self.subTest(failure=failure):
                directory = self.new_owned(failure)
                spec = directory / "runtime.spec.json"
                spec.write_text(json.dumps({"directory": str(directory), "token": "token", "name": "runtime",
                                           "command": ["fake-runtime"], "env": {}, "timeout": 0 if failure == "timeout" else 30}))
                identity = {"pid": 4321, "start": "123", "state": "S", "uid": os.getuid(), "cwd": str(directory),
                            "env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=runtime"]}
                child = Mock()
                child.poll.return_value = None
                child.wait.side_effect = subprocess.TimeoutExpired("fake-runtime", 2)
                def start(*args, **kwargs):
                    if failure == "cancelled":
                        g.signal.getsignal(g.signal.SIGTERM)(None, None)
                    return child
                disk = Mock(free=1 if failure == "disk_guard" else 4 * 1024 ** 3)
                with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"), \
                     patch.object(g.subprocess, "Popen", side_effect=start), patch.object(g.shutil, "disk_usage", return_value=disk), \
                     patch.object(g, "graceful_runtime_stop", side_effect=RuntimeError("missing permit; session preserved")), \
                     patch.object(g, "safe_signal") as kill:
                    self.assertEqual(g.worker(spec), expected)
                    kill.assert_not_called()
                result = json.loads((directory / "runtime.result.json").read_text())
                self.assertIn("missing permit", result["cleanup_errors"][0])

    def test_runtime_normal_cleanup_never_falls_back_to_term_kill(self):
        directory = self.new_owned()
        spec = directory / "runtime.spec.json"
        spec.write_text(json.dumps({"directory": str(directory), "token": "token", "name": "runtime",
                                   "command": ["fake-runtime"], "env": {}, "timeout": 0}))
        identity = {"pid": 4321, "start": "123", "state": "S", "uid": os.getuid(), "cwd": str(directory),
                    "env": [b"GBUS_OWNER_TOKEN=token", b"GBUS_WORKER_NAME=runtime"]}
        child = Mock()
        child.poll.return_value = None
        child.wait.return_value = 0
        with patch.object(g, "proc_identity", return_value=identity), patch.object(g, "require_session_safe"), \
             patch.object(g.subprocess, "Popen", return_value=child), patch.object(g, "graceful_runtime_stop"), \
             patch.object(g, "safe_signal") as kill:
            g.worker(spec)
            kill.assert_not_called()

    def test_direct_shell_start_and_stop_without_guard_are_blocked(self):
        script = TOOLS.parent / "uvhs/runtime/runtime_session.sh"
        directory = self.base / "direct"
        directory.mkdir()
        env = dict(os.environ)
        for name in ("UVHS_RUNTIME_SAFETY_HELPER", "GBUS_OWNER_TOKEN"):
            env.pop(name, None)
        command = ["bash", str(script), "start", str(directory / "pid"), str(directory / "ready"),
                   str(directory / "log"), str(directory / "command"), "1", "touch", str(directory / "reached")]
        result = subprocess.run(command, capture_output=True, env=env, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((directory / "reached").exists())
        result = subprocess.run(["bash", str(script), "enqueue", str(directory / "command"), "1", "stop"],
                                capture_output=True, env=env, timeout=5)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((directory / "command").exists())

    def test_full_daemon_scan_detects_middle_ack_missing_from_sample(self):
        path = self.base / "daemon.log"
        line = time.strftime("%Y-%m-%d %H:%M:%S") + " invalid read ACK packet_id\n"
        path.write_text("normal status\n" * 8000 + line + "normal status\n" * 8000)
        sampled = g.base64.b64decode(g.sample(path)["sample_b64"]).decode()
        self.assertNotIn("invalid read ACK", sampled)
        scan = g.daemon_transport_history(path)
        self.assertEqual(scan["errors"], [line.strip()])
        snapshot = {"services": {}, "kernel": "", "uptime": 1000, "daemon": "\n".join(scan["errors"]),
                    "time": time.time(), "boot_id": "boot"}
        with patch.object(g, "transport_snapshot", side_effect=[snapshot, snapshot]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_daemon_scan_rejects_partial_special_symlink_and_large_history(self):
        path = self.base / "daemon.log"
        path.write_text("partial ACK record")
        with self.assertRaisesRegex(RuntimeError, "incomplete"):
            g.daemon_transport_history(path)
        path.write_text("normal\n")
        link = self.base / "daemon-link"
        link.symlink_to(path)
        with self.assertRaises(OSError):
            g.daemon_transport_history(link)
        fifo = self.base / "daemon-fifo"
        os.mkfifo(fifo)
        with self.assertRaisesRegex(RuntimeError, "regular"):
            g.daemon_transport_history(fifo)
        with path.open("wb") as stream:
            stream.truncate(128 * 1024 * 1024 + 1)
        with self.assertRaisesRegex(RuntimeError, "bounded regular"):
            g.daemon_transport_history(path)

    def test_daemon_scan_accepts_only_verified_append_not_prefix_mutation(self):
        path = self.base / "daemon.log"
        path.write_text("normal\n")
        original = g.os.fstat
        calls = [0]
        def append(fd):
            calls[0] += 1
            if calls[0] == 2:
                with path.open("ab") as stream:
                    stream.write(b"appended\n")
            return original(fd)
        with patch.object(g.os, "fstat", side_effect=append):
            scan = g.daemon_transport_history(path)
        self.assertEqual(scan["size"], len("normal\n"))
        self.assertEqual(scan["errors"], [])
        path.write_text("normal\n")
        calls[0] = 0
        def mutate(fd):
            calls[0] += 1
            if calls[0] == 2:
                path.write_text("mutant\nextra\n")
            return original(fd)
        with patch.object(g.os, "fstat", side_effect=mutate):
            with self.assertRaisesRegex(RuntimeError, "prefix changed"):
                g.daemon_transport_history(path)

    def test_daemon_scan_rejects_same_size_same_timestamp_rewrite(self):
        path = self.base / "daemon.log"
        replacement = b"invalid read ACK\n"
        path.write_bytes(b"n" * (len(replacement) - 1) + b"\n")
        original = g.os.fstat
        metadata = path.stat()
        calls = [0]
        def mutate(fd):
            calls[0] += 1
            if calls[0] == 2:
                path.write_bytes(replacement)
                os.utime(path, ns=(metadata.st_atime_ns, metadata.st_mtime_ns))
            return original(fd)
        with patch.object(g.os, "fstat", side_effect=mutate):
            with self.assertRaisesRegex(RuntimeError, "prefix changed"):
                g.daemon_transport_history(path)
        self.assertEqual(path.stat().st_size, metadata.st_size)
        self.assertEqual(path.stat().st_mtime_ns, metadata.st_mtime_ns)

    def test_fractional_boot_second_ack_is_not_discarded(self):
        boot = time.mktime(time.strptime("2026-10-12 09:57:34", "%Y-%m-%d %H:%M:%S")) + .75
        first = {"services": {}, "kernel": "", "uptime": 1000, "time": boot + 1000, "boot_id": "boot",
                 "daemon": "2026-10-12 09:57:34.900 invalid read ACK packet_id"}
        with patch.object(g, "transport_snapshot", side_effect=[first, first]), patch.object(g.time, "sleep"):
            self.assertEqual(g.transport_health()["state"], "unhealthy")

    def test_daemon_rotation_during_health_unknown(self):
        first = {"services": {}, "kernel": "", "uptime": 1000, "daemon": "", "time": time.time(),
                 "boot_id": "boot", "daemon_identity": [1, 2], "daemon_size": 500}
        for altered in (dict(first, daemon_identity=[1, 3]), dict(first, daemon_size=10)):
            with patch.object(g, "transport_snapshot", side_effect=[first, altered]), patch.object(g.time, "sleep"):
                self.assertEqual(g.transport_health()["state"], "unknown")

    def test_live_contract_block_cannot_be_enabled_by_environment(self):
        self.mock_contract.stop()
        directory = self.new_owned()
        with patch.dict(os.environ, {"BOARD_TEST_AUTHORIZE": "YES", "GBUS_ACK_SAFE": "1"}), \
             patch.object(g.subprocess, "Popen") as start:
            for route in (lambda: g.authorize_host_launch(directory, "token", "/mock-host", ["host"]),
                          lambda: g.launch(str(directory), "token", "host", ["host"], authorization={}),
                          lambda: g.launch(str(directory), "token", "runtime", ["runtime"], host_directory="/mock-host"),
                          lambda: g.runtime_guard(directory, "token", "stop")):
                with self.assertRaisesRegex(RuntimeError, "vendor ACK failure propagation"):
                    route()
            start.assert_not_called()
        self.s.build = Mock()
        self.assertEqual(self.s.execute("supervise"), 1)
        self.s.build.assert_not_called()
        self.s.fpga.call.assert_not_called()
        self.s.rt.call.assert_not_called()

    def test_source_upload_excludes_secrets_and_generated_artifacts(self):
        for pattern in (".env", ".env.*", "credentials*", "*.so", "*.a", "*.vcd", "*.pyc", "*.md"):
            self.assertIn(pattern, g.SOURCE_EXCLUDES)


if __name__ == "__main__":
    unittest.main(verbosity=2)
