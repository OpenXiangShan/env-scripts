from collections.abc import Iterator
from contextlib import contextmanager
import fcntl
import os
import socket
from pathlib import Path

from .common import ManagerError, atomic_json, read_json, runner_name
from .models import Group, Groups, HostState, Instance, StoredInstance


class Store:
    """Persist runner state under a host-specific lock."""

    def __init__(self, root: Path) -> None:
        """Locate the state file for the local short hostname."""
        self.hostname = socket.gethostname().split(".")[0]
        self.path = root / "state" / f"{self.hostname}.json"
        self.data: HostState = {
            "schema_version": 2,
            "hostname": self.hostname,
            "groups": {},
        }

    def load(self) -> Groups:
        """Load group configurations after checking the host state schema."""
        if not self.path.exists():
            self.data = {"schema_version": 2, "hostname": self.hostname, "groups": {}}
        else:
            self.data = read_json(self.path)
            if not isinstance(self.data, dict) or self.data.get(
                "schema_version"
            ) not in (1, 2):
                raise ManagerError(f"Unsupported state schema: {self.path}")
            if self.data.get("hostname") != self.hostname or not isinstance(
                self.data.get("groups"), dict
            ):
                raise ManagerError(f"Invalid host state: {self.path}")
            for name, group in self.data["groups"].items():
                group["instances"] = [
                    self.resolve_instance(name, group, instance)
                    for instance in group["instances"]
                ]
            self.data["schema_version"] = 2
        return self.data["groups"]

    def resolve_instance(
        self, name: str, group: Group, instance: StoredInstance
    ) -> Instance:
        """Derive an instance's identity while preserving completed renames."""
        count = group["count"]
        operation = group.get("pending")
        if operation:
            for item in operation.get("items", []):
                if (
                    item["index"] == instance["index"]
                    and item["stage"] == "done"
                    and item["new_name"] is not None
                ):
                    count = operation["final_count"]
                    break
        expected_name = runner_name(name, self.hostname, instance["index"], count)
        expected_path = str(Path(group["directory"]) / expected_name)
        if (
            instance.get("name", expected_name) != expected_name
            or instance.get("path", expected_path) != expected_path
        ):
            raise ManagerError(
                f"Stored runner identity does not match derived name/path: {expected_path}"
            )
        return {**instance, "name": expected_name, "path": expected_path}

    def save(self) -> None:
        """Atomically save state without redundant instance names or paths."""
        groups: dict[str, dict[str, object]] = {}
        for name, group in self.data["groups"].items():
            instances: list[StoredInstance] = []
            for instance in group["instances"]:
                stored: StoredInstance = {"index": instance["index"]}
                if "package" in instance:
                    stored["package"] = instance["package"]
                instances.append(stored)
            groups[name] = {**group, "instances": instances}
        atomic_json(self.path, {**self.data, "schema_version": 2, "groups": groups})

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
