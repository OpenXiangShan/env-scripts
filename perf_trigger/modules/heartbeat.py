import logging
import threading
import time
from pathlib import Path


class Heartbeat:
    def __init__(self, path: Path, interval: int):
        if not path.parent.is_dir():
            raise ValueError(f"Parent directory of {path} does not exist")
        if path.is_dir():
            raise ValueError(f"{path} exists and is a directory, cannot heartbeat here")

        self.path = path
        self.interval = interval
        self.thread = None
        self.stop_event = threading.Event()

    def is_alive(self) -> bool:
        # check the write timestamp of the heartbeat file
        if not self.path.exists():
            return False
        last = self.path.stat().st_mtime
        curr = time.time()
        return curr - last < 2 * self.interval

    def start(self):
        if self.thread is not None and self.thread.is_alive():
            logging.warning("Heartbeat is already running")
            return

        self.stop_event.clear()
        self.thread = threading.Thread(
            target=self._heartbeat_loop,
            name="heartbeat",
            daemon=True,
        )
        self.thread.start()

    def stop(self):
        if self.thread is None:
            return

        self.stop_event.set()
        self.thread.join()
        self.thread = None

        self.path.unlink(missing_ok=True)

    def _heartbeat_loop(self):
        self.path.parent.mkdir(parents=True, exist_ok=True)
        while not self.stop_event.is_set():
            self.path.touch(exist_ok=True)
            if self.stop_event.wait(self.interval):
                break
