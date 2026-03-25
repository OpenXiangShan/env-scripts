import logging
import threading
import time
from pathlib import Path


class Heartbeat:
    def __init__(self, name: str, parent_path: Path, interval: int):
        if not parent_path.is_dir():
            raise ValueError(f"Parent directory of {parent_path} does not exist")

        self.name = name
        self.lock_path = parent_path / f".{name}.lock"
        self.heartbeat_path = parent_path / f".{name}.heartbeat"
        self.interval = interval
        self.thread = None
        self.stop_event = threading.Event()
        self.lock_owned = False

    def __is_alive(self) -> bool:
        # check the write timestamp of the heartbeat file
        if not self.heartbeat_path.exists():
            return False
        last = self.heartbeat_path.stat().st_mtime
        curr = time.time()
        return curr - last < 2 * self.interval

    def __loop(self) -> None:
        while not self.stop_event.is_set():
            self.heartbeat_path.touch(exist_ok=True)
            if self.stop_event.wait(self.interval):
                break

    def __start(self) -> None:
        self.stop_event.clear()
        self.thread = threading.Thread(
            target=self.__loop,
            name="heartbeat",
            daemon=True,
        )
        self.thread.start()

    def __stop(self) -> None:
        if self.thread is not None:
            self.stop_event.set()
            self.thread.join()
            self.thread = None

        self.heartbeat_path.unlink(missing_ok=True)

    def try_acquire(self) -> bool:
        if self.lock_owned:
            return True

        try:
            self.lock_path.mkdir()
            self.lock_owned = True
            self.__start()
            return True
        except FileExistsError:
            if self.__is_alive():
                return False

            # The old owner appears stale; try to reclaim lock.
            try:
                self.lock_path.rmdir()
            except FileNotFoundError:
                pass
            except OSError:
                return False
            return self.try_acquire()

    def release(self):
        if not self.lock_owned:
            return

        self.__stop()

        try:
            self.lock_path.rmdir()
        except FileNotFoundError:
            pass
        except OSError:
            logging.warning("Failed to remove heartbeat lock dir: %s", self.lock_path)
        finally:
            self.lock_owned = False
