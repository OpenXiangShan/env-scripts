from collections.abc import Iterator
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
import re
import socket
from pathlib import Path
from typing import cast

from .common import ManagerError, atomic_json, read_json, runner_name
from .models import (
    Group,
    Groups,
    HostState,
    Instance,
    Package,
    PackageInfo,
    StoredInstance,
)
from .packages import Packages, digest


class Store:
    """Persist runner state under a host-specific lock."""

    def __init__(self, root: Path, hostname: str | None = None) -> None:
        """Locate the state file for the local short hostname."""
        self.root = root.resolve()
        self.hostname = hostname or socket.gethostname().split(".")[0]
        self.path = self.root / "state" / f"{self.hostname}.json"
        self.data: HostState = {
            "schema_version": 3,
            "hostname": self.hostname,
            "packages": {},
            "groups": {},
        }

    def load(self) -> Groups:
        """Load group configurations after checking the host state schema."""
        if not self.path.exists():
            self.data = {
                "schema_version": 3,
                "hostname": self.hostname,
                "packages": {},
                "groups": {},
            }
        else:
            self.data = read_json(self.path)
            if not isinstance(self.data, dict) or self.data.get(
                "schema_version"
            ) not in (1, 2, 3):
                raise ManagerError(f"Unsupported state schema: {self.path}")
            if self.data.get("hostname") != self.hostname or not isinstance(
                self.data.get("groups"), dict
            ):
                raise ManagerError(f"Invalid host state: {self.path}")
            self.data.setdefault("packages", {})
            if not isinstance(self.data["packages"], dict):
                raise ManagerError(f"Invalid package registry: {self.path}")
            for checksum, info in self.data["packages"].items():
                self.validate_package(checksum, info)
            for name, group in self.data["groups"].items():
                legacy = cast(dict[str, object], group)
                group_reference = self.normalize_package(legacy.pop("package", None))
                if group_reference:
                    for instance in group["instances"]:
                        instance.setdefault("package", group_reference)
                group["instances"] = [
                    self.resolve_instance(name, group, instance)
                    for instance in group["instances"]
                ]
                operation = group.get("pending")
                if operation:
                    operation["package"] = self.normalize_package(
                        operation.get("package")
                    )
                    for item in operation.get("items", []):
                        reference = self.normalize_package(
                            item.get("package"), Path(item["path"])
                        )
                        if reference:
                            item["package"] = reference
            self.data["schema_version"] = 3
        return self.data["groups"]

    def validate_package(self, checksum: str, info: PackageInfo) -> None:
        """Reject malformed package registry entries before using references."""
        if (
            not re.fullmatch(r"[0-9a-f]{64}", checksum)
            or not isinstance(info, dict)
            or not isinstance(info.get("version"), str)
            or not isinstance(info.get("platform"), str)
            or "root" not in info
            or info.get("source") not in ("archive", "imported")
            or (info.get("root") is not None and not isinstance(info["root"], str))
            or (info.get("source") == "archive" and not info.get("root"))
        ):
            raise ManagerError(f"Invalid package {checksum} in {self.path}")

    def normalize_package(
        self, reference: object, directory: Path | None = None
    ) -> str | None:
        """Convert legacy inline metadata into a validated package reference."""
        if reference is None:
            return None
        if isinstance(reference, str):
            if reference not in self.data["packages"]:
                raise ManagerError(f"Unknown package {reference} in {self.path}")
            return reference
        if not isinstance(reference, dict) or not isinstance(
            reference.get("version"), str
        ):
            raise ManagerError(f"Invalid inline package in {self.path}")
        if reference.get("sha256") is None:
            return self.remember_import(reference["version"], directory)
        package: Package = {
            "sha256": reference["sha256"],
            "version": reference["version"],
            "platform": reference["platform"],
            "root": reference["root"],
        }
        return self.remember(package)

    def remember(self, package: Package) -> str:
        """Register shared metadata for a cached archive and return its checksum."""
        checksum = package["sha256"]
        info: PackageInfo = {
            "version": package["version"],
            "platform": package["platform"],
            "root": package["root"],
            "source": "archive",
        }
        self.validate_package(checksum, info)
        existing = self.data["packages"].get(checksum)
        if existing and existing != info:
            raise ManagerError(f"Conflicting metadata for package {checksum}")
        self.data["packages"][checksum] = info
        return checksum

    def remember_import(self, version: str, directory: Path | None) -> str:
        """Record an imported runner using its listener or legacy metadata digest."""
        info: PackageInfo = {
            "version": version,
            "platform": Packages(self.root).target(),
            "root": None,
            "source": "imported",
        }
        listener = directory / "bin" / "Runner.Listener" if directory else None
        checksum = (
            digest(listener)
            if listener and listener.is_file()
            else hashlib.sha256(json.dumps(info, sort_keys=True).encode()).hexdigest()
        )
        if directory:
            externals = directory / "externals"
            if externals.is_symlink():
                cached_root = externals.resolve().parent.parent
                if cached_root.is_relative_to(self.root / ".cache" / "packages"):
                    info["root"] = str(cached_root)
                    manifest = cached_root / "package.json"
                    cached_listener = cached_root / "files" / "bin" / "Runner.Listener"
                    if manifest.is_file() and cached_listener.is_file():
                        cached = read_json(manifest)
                        if (
                            isinstance(cached, dict)
                            and cached.get("version") == version
                            and cached.get("root") == str(cached_root)
                            and digest(cached_listener) == checksum
                        ):
                            return self.remember(cast(Package, cached))
                    checksum = hashlib.sha256(
                        json.dumps(
                            {"package": info, "listener": checksum}, sort_keys=True
                        ).encode()
                    ).hexdigest()
        self.data["packages"].setdefault(checksum, info)
        return checksum

    def package(self, checksum: str | None) -> Package | None:
        """Resolve an archive reference to the package installer metadata."""
        if checksum is None:
            return None
        info = self.data["packages"][checksum]
        if info["source"] == "imported":
            return None
        root = info["root"]
        assert root is not None
        return {
            "sha256": checksum,
            "version": info["version"],
            "platform": info["platform"],
            "root": root,
        }

    def group_package(self, group: Group) -> Package | None:
        """Choose the newest reusable archive referenced by a group's instances."""
        packages = [
            package
            for instance in group["instances"]
            if (package := self.package(instance.get("package"))) is not None
        ]
        return max(
            packages,
            key=lambda package: tuple(map(int, package["version"].split("."))),
            default=None,
        )

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
        result: Instance = {**instance, "name": expected_name, "path": expected_path}
        reference = self.normalize_package(instance.get("package"), Path(expected_path))
        if reference:
            result["package"] = reference
        else:
            result.pop("package", None)
        return result

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
        atomic_json(self.path, {**self.data, "schema_version": 3, "groups": groups})

    @contextmanager
    def cache_locked(self, exclusive: bool = False) -> Iterator[None]:
        """Coordinate cache mutations with exclusive cleanup across all hosts."""
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with open(
            self.path.parent / ".packages.lock",
            "a",
            opener=lambda path, flags: os.open(path, flags, 0o600),
        ) as stream:
            mode = fcntl.LOCK_EX if exclusive else fcntl.LOCK_SH
            try:
                fcntl.flock(stream, mode | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise ManagerError(
                    "Another manager is using the package cache"
                ) from error
            try:
                yield
            finally:
                fcntl.flock(stream, fcntl.LOCK_UN)

    @contextmanager
    def locked(self) -> Iterator[Groups]:
        """Load state while holding an exclusive host mutation lock."""
        with self.cache_locked(), open(
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
