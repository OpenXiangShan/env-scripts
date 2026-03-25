import logging
import subprocess
import time
from pathlib import Path

HEARTBEAT_INTERVAL = 60


class Heartbeat:
    def __init__(self, path: Path):
        self.path = path
        self.proc = None

    def is_alive(self) -> bool:
        # check the write timestamp of the heartbeat file
        if not self.path.exists():
            return False
        last = self.path.stat().st_mtime
        curr = time.time()
        return curr - last < 2 * HEARTBEAT_INTERVAL

    def start(self):
        if self.proc is not None and self.proc.poll() is None:
            logging.warning("Heartbeat is already running")
            return

        self.proc = subprocess.Popen(
            [
                "bash",
                "-c",
                f"while true; do touch {self.path}; sleep {HEARTBEAT_INTERVAL}; done",
            ]
        )

    def stop(self):
        if self.proc is None:
            return

        self.proc.terminate()
        self.proc.wait()
        self.proc = None

        self.path.unlink(missing_ok=True)
