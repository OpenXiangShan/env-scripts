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
GOOD = ("HIT GOOD TRAP\nGBus C2H interface layer=sram-window\n"
        "GBus DMA workload queued 8192 bytes\nGBus C2H progress reads=1 bytes=64 staged=8\n")


class SafetyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.base = Path(self.tmp.name)
        self.key = self.base / "key"
        self.key.touch()
        self.env = {"TAG": "test", "OUT_DIR": str(self.base / "out"), "FPGA_HOST_KEY": str(self.key),
                    "FPGA_HOST_DIR": str(self.base / "donor"), "WAIT_BOARD_TIMEOUT": "0",
                    "FPGA_HOST": "fake-fpga", "RUNTIME_HOST": "fake-runtime"}
        self.s = g.Supervisor(self.env)
        self.s.fpga = Mock()
        self.s.rt = Mock()
        self.s.fpga.call.return_value = {}
        self.s.fpga.host = "fake-fpga"
        self.s.rt.host = "fake-runtime"

    def tearDown(self):
        self.tmp.cleanup()

    def new_owned(self, name="worker"):
        directory = self.base / name
        g.init_owned(str(directory), "token", "test", (TOOLS / "gbus_supervisor.py").read_text())
        return directory

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
        for response in ({"state": "busy"}, {"state": "unknown"}, {"state": "unexpected"}):
            with self.subTest(response=response):
                self.s.rt.call.return_value = response
                with self.assertRaisesRegex(RuntimeError, "busy/unknown"):
                    self.s.runtime()
                self.s.rt.sync.assert_not_called()
                self.assertFalse(any(c.args[0] == "launch" for c in self.s.rt.call.call_args_list))
        self.s.rt.call.side_effect = RuntimeError("SSH rc=255")
        with self.assertRaisesRegex(RuntimeError, "busy/unknown"):
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
        self.assertNotEqual(self.s.host_dir, self.s.donor)
        launches = [c for c in self.s.fpga.call.call_args_list if c.args[0] == "launch"]
        script = launches[0].kwargs["command"][-1]
        self.assertIn("set -euo pipefail", script)
        self.assertIn("USE_SERIAL_PORT=0", script)

    def test_release_mismatch_and_no_arbitrary_generated_fallback(self):
        with self.assertRaisesRegex(RuntimeError, "RELEASE_DIR is required"):
            self.s.release()
        release = self.base / "release/build/generated-src"
        release.mkdir(parents=True)
        (release / "difftest-state.h").write_text("release ABI")
        project = self.base / "project"
        (project / "rtl").mkdir(parents=True)
        (project / "rtl/filelist.f").write_text("+incdir+" + str(release) + "\n")
        self.s.release(project)
        self.assertEqual(self.s.generated, release)
        self.s.env["RELEASE_DIR"] = str(self.base / "wrong")
        with self.assertRaisesRegex(RuntimeError, "does not match"):
            self.s.release(project)

    def test_large_remote_logs_do_not_kill_application(self):
        directory = self.new_owned()
        size = 10 * 1024 * 1024
        command = "import pathlib,sys; data=b'x'*" + str(size) + "; pathlib.Path('vendor.log').write_bytes(data); sys.stdout.buffer.write(data)"
        g.launch(str(directory), "token", "host", [sys.executable, "-c", command], timeout=10)
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
        dma = GOOD.replace("GBus C2H progress reads=1 bytes=64 staged=8",
                           "GBus GBD1 progress reads=4 bytes=1024 seq=1")
        self.assertEqual(g.verdict(status, dma)["verdict"], "good_trap")
        for text in (dma.replace("bytes=1024", "bytes=0"),
                     dma.replace("reads=4", "reads=0"), dma + "HIT BAD TRAP"):
            self.assertEqual(g.verdict(status, text)["verdict"], "failed_or_unproven")
        status["result"]["child_rc"] = 1
        self.assertEqual(g.verdict(status, dma)["verdict"], "failed_or_unproven")

    def test_goodtrap_requires_actual_rc0_transport_and_no_timeout(self):
        directory = self.new_owned()
        started = time.monotonic()
        g.launch(str(directory), "token", "host", [sys.executable, "-c", "import time; print(" + repr(GOOD) + ", flush=True); time.sleep(5)"], timeout=.3)
        self.assertLess(time.monotonic() - started, 1)
        state = self.wait(directory, "host")
        self.assertEqual(state["rc"], 124)
        self.assertEqual(g.verdict(state, GOOD)["verdict"], "timeout")
        other = self.new_owned("success")
        g.launch(str(other), "token", "host", [sys.executable, "-c", "print(" + repr(GOOD) + ")"], timeout=5)
        ok = self.wait(other, "host")
        self.assertEqual(g.verdict(ok, GOOD)["verdict"], "good_trap")
        self.assertEqual(g.verdict(ok, "HIT GOOD TRAP")["verdict"], "failed_or_unproven")
        self.assertEqual(g.verdict({"rc": None, "result": None}, GOOD)["verdict"], "pending")
        self.assertEqual(g.verdict(dict(ok, rc=1), GOOD)["verdict"], "failed_or_unproven")
        self.assertNotEqual(g.verdict(ok, GOOD + "HIT BAD TRAP")["verdict"], "good_trap")

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

    def test_donor_hash_mismatch_is_fatal(self):
        directory = self.new_owned()
        donor = self.base / "donor/workload"
        donor.mkdir(parents=True)
        (donor / "xiangshan-am-hello.bin").write_bytes(b"wrong")
        with self.assertRaisesRegex(RuntimeError, "hash mismatch"):
            g.remote({"action": "inputs", "directory": str(directory), "token": "token",
                      "donor": str(donor.parent), "workload_sha": g.WORKLOAD_SHA, "nemu_sha": g.NEMU_SHA})

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
        self.s.wait_board = Mock()
        self.s.init = Mock()
        self.s.start = Mock()
        self.s.stop = Mock()
        self.s.collect_one = Mock()
        calls = []
        def rpc(host, directory, action, **kwargs):
            calls.append((directory, action))
            if action == "status":
                return {"ready": directory.endswith("attempt-2"), "result": {"rc": 3}, "rc": 3}
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

    def test_worker_stop_cleans_only_its_own_child(self):
        directory = self.new_owned()
        g.launch(str(directory), "token", "host", [sys.executable, "-c", "import time; time.sleep(20)"], timeout=30)
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

    def test_rsync_has_no_delete_option(self):
        remote = g.Remote("fake", self.key)
        with patch.object(g.subprocess, "run") as run:
            remote.sync("/source/", "/isolated/dest/", ("build/",))
        self.assertFalse(any("--delete" in arg for arg in run.call_args.args[0]))


if __name__ == "__main__":
    unittest.main(verbosity=2)
