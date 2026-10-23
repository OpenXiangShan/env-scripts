from collections.abc import Iterator
from contextlib import contextmanager
import fcntl
import os
import socket
from pathlib import Path

from .common import ManagerError, atomic_json, read_json
from .models import Groups, HostState


class Store:
    """Persist runner state under a host-specific lock."""

    def __init__(self, root: Path) -> None:
        """Locate the state file for the local short hostname."""
        self.hostname = socket.gethostname().split(".")[0]
        self.path = root / "state" / f"{self.hostname}.json"
        self.data: HostState = {
            "schema_version": 1,
            "hostname": self.hostname,
            "groups": {},
        }

    def load(self) -> Groups:
        """Load group configurations after checking the host state schema."""
        if not self.path.exists():
            self.data = {"schema_version": 1, "hostname": self.hostname, "groups": {}}
        else:
            self.data = read_json(self.path)
            if not isinstance(self.data, dict) or self.data.get("schema_version") != 1:
                raise ManagerError(f"Unsupported state schema: {self.path}")
            if self.data.get("hostname") != self.hostname or not isinstance(
                self.data.get("groups"), dict
            ):
                raise ManagerError(f"Invalid host state: {self.path}")
        return self.data["groups"]

    def save(self) -> None:
        """Atomically save the current in-memory state."""
        atomic_json(self.path, self.data)

    @contextmanager
    def locked(self) -> Iterator[Groups]:
        """Load state while holding an exclusive host mutation lock."""
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(
            self.path.with_suffix(".lock"),
            "a",
            opener=lambda path, flags: os.open(path, flags, 0o600),
        ) as stream:
            try:
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise ManagerError(
                    f"Another manager is modifying host {self.hostname}"
                ) from error
            try:
                yield self.load()
            finally:
                fcntl.flock(stream, fcntl.LOCK_UN)
