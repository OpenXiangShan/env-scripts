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
            "schema_version": 4,
            "hostname": self.hostname,
            "packages": {},
            "groups": {},
        }

    def load(self) -> Groups:
        """Load group configurations after checking the host state schema."""
        if not self.path.exists():
            self.data = {
                "schema_version": 4,
                "hostname": self.hostname,
                "packages": {},
                "groups": {},
            }
        else:
            self.data = read_json(self.path)
            if not isinstance(self.data, dict) or self.data.get(
                "schema_version"
            ) not in (1, 2, 3, 4):
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
                if (
                    not isinstance(group, dict)
                    or type(group.get("count")) is not int
                    or group["count"] < 0
                    or (
                        self.data["schema_version"] == 4
                        and ("package" not in group or "instances" in group)
                    )
                ):
                    raise ManagerError(f"Invalid group {name} in {self.path}")
                group["package"] = self.normalize_package(group.get("package"))
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
                if self.data["schema_version"] < 4:
                    self.migrate_group(name, group)
            self.data["schema_version"] = 4
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
        """Resolve the group's shared package for reuse during installation."""
        return self.package(group["package"])

    def instances(self, name: str, group: Group) -> list[Instance]:
        """Derive runner identities and packages from count and operation progress."""
        instances: dict[int, Instance] = {}
        for index in range(group["count"]):
            expected = runner_name(name, self.hostname, index, group["count"])
            instance: Instance = {
                "index": index,
                "name": expected,
                "path": str(Path(group["directory"]) / expected),
            }
            if group["package"]:
                instance["package"] = group["package"]
            instances[index] = instance
        operation = group.get("pending")
        if operation:
            for item in operation.get("items", []):
                if item["stage"] == "done" and item["new_name"] is None:
                    instances.pop(item["index"], None)
                    continue
                instance = {
                    "index": item["index"],
                    "name": item["name"],
                    "path": item["path"],
                }
                reference = item.get("package", group["package"])
                if (
                    operation["kind"] in ("create", "update")
                    and item["stage"] in ("registering", "done")
                    and operation.get("package")
                    and "package" not in item
                ):
                    reference = operation["package"]
                if reference:
                    instance["package"] = reference
                instances[item["index"]] = instance
        return [instance for _, instance in sorted(instances.items())]

    def migrate_group(self, name: str, group: Group) -> None:
        """Replace legacy instance records with a shared package and derived indices."""
        legacy = cast(dict[str, object], group)
        stored = legacy.pop("instances", None)
        if not isinstance(stored, list):
            raise ManagerError(f"Invalid legacy instances for group {name}")
        operation = group.get("pending")
        items = (
            {item["index"]: item for item in operation.get("items", [])}
            if operation
            else {}
        )
        references: dict[int, str | None] = {}
        for instance in stored:
            index = instance["index"]
            count = group["count"]
            item = items.get(index)
            if item and item["stage"] == "done" and item["new_name"]:
                assert operation is not None
                count = operation["final_count"]
            expected = runner_name(name, self.hostname, index, count)
            path = str(Path(group["directory"]) / expected)
            if (
                index in references
                or instance.get("name", expected) != expected
                or instance.get("path", path) != path
            ):
                raise ManagerError(f"Invalid legacy runner identity: {path}")
            references[index] = self.normalize_package(
                instance.get("package", group["package"]), Path(path)
            )
        target = operation.get("package") if operation else None
        baseline = {
            reference
            for index, reference in references.items()
            if reference is not None
            and not (
                operation
                and index in items
                and (
                    operation["kind"] == "update"
                    or operation["kind"] == "create"
                    and reference == target
                )
            )
        }
        if not baseline and group["package"]:
            baseline.add(group["package"])
        if not baseline and operation and operation["kind"] == "update":
            baseline = {
                reference
                for reference in references.values()
                if reference and reference != target
            }
            if baseline:
                baseline = {sorted(baseline)[0]}
        if len(baseline) > 1:
            raise ManagerError(
                f"Group {name} has mixed runner packages; unify them before migrating"
            )
        group["package"] = next(iter(baseline), target)
        if (
            operation
            and operation.get("phase") == "restoring"
            and operation["kind"] in ("create", "update")
        ):
            group["package"] = target
        expected_indices = set(range(group["count"]))
        for index, item in items.items():
            if item["stage"] == "done":
                if item["new_name"] is None:
                    expected_indices.discard(index)
                else:
                    expected_indices.add(index)
        if references.keys() != expected_indices:
            raise ManagerError(f"Legacy runner indices are not contiguous: {name}")
        for index, item in items.items():
            reference = references.get(index)
            if (
                reference
                and "package" not in item
                and item["stage"] not in ("registering", "done")
            ):
                item["package"] = reference
        if operation and operation["kind"] == "create":
            for index, reference in references.items():
                if index >= operation["final_count"] or reference == target:
                    continue
                item = items.get(index)
                if item is None or item["stage"] == "done":
                    raise ManagerError(
                        f"Group {name} has mixed runner packages; unify them before migrating"
                    )
        for instance in self.instances(name, group):
            index = instance["index"]
            item = items.get(index)
            if (
                index in references
                and (item is None or item["stage"] == "done")
                and references[index] != instance.get("package")
            ):
                raise ManagerError(
                    f"Group {name} has mixed runner packages; unify them before migrating"
                )

    def save(self) -> None:
        """Atomically save shared group configuration and operation progress."""
        atomic_json(self.path, {**self.data, "schema_version": 4})

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
