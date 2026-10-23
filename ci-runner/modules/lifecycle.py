from copy import deepcopy
from contextlib import nullcontext
from pathlib import Path
import shutil
from typing import Any

from . import github
from .common import (
    ManagerError,
    atomic_json,
    execute,
    metadata,
    read_json,
    runner_name,
    verify_registration,
)
from .models import (
    Arguments,
    Group,
    Groups,
    GroupStatus,
    Instance,
    InstanceStatus,
    Operation,
    OperationItem,
    Owner,
    Status,
)
from .packages import Packages
from .preview import Preview
from .storage import Store
from .tmux import Tmux, assert_no_unmanaged_process


class Manager:
    """Coordinate resumable runner lifecycle operations."""

    def __init__(self, root: Path) -> None:
        """Initialize storage, package management and tmux control."""
        self.root = root.resolve()
        self.store = Store(self.root)
        self.packages = Packages(self.root)
        self.tmux = Tmux(self.root, self.store.hostname)

    def identity(self, name: str, index: int) -> Owner:
        """Build the ownership marker for a runner index."""
        return {"hostname": self.store.hostname, "name": name, "index": index}

    def owned(self, name: str, instance: Instance) -> Path:
        """Verify directory ownership and return its canonical path."""
        path = Path(instance["path"])
        if path.is_symlink() or path.resolve() != path or not path.is_dir():
            raise ManagerError(
                f"Runner directory is missing or has changed identity: {path}"
            )
        if read_json(path / ".manager-owner.json") != self.identity(
            name, instance["index"]
        ):
            raise ManagerError(f"Runner directory is not owned by this group: {path}")
        return path

    def registered(self, name: str, instance: Instance, group: Group) -> dict[str, Any]:
        """Verify both directory ownership and runner registration."""
        path = self.owned(name, instance)
        return verify_registration(path, instance["name"], group["url"])

    def reserved_paths(self, group: Group) -> set[Path]:
        """Collect directories reserved by instances and pending changes."""
        paths = {Path(instance["path"]) for instance in group["instances"]}
        operation = group.get("pending")
        if operation:
            for item in operation.get("items", []):
                paths.add(Path(item["path"]))
                new_name = item["new_name"]
                if new_name:
                    paths.add(Path(group["directory"]) / new_name)
        return paths

    def check_paths(self, name: str, group: Group, target: int, groups: Groups) -> None:
        """Reject occupied or overlapping paths before changing runners."""
        base = Path(group["directory"])
        if base == Path("/") or base.resolve() != base:
            raise ManagerError(
                "Runner base directory must be canonical and cannot be /"
            )
        own_paths = {instance["path"] for instance in group["instances"]}
        other_paths: list[Path] = []
        for other_name, other in groups.items():
            if other_name != name:
                other_paths.extend(self.reserved_paths(other))
        for index in range(target):
            candidate = base / runner_name(name, self.store.hostname, index, target)
            if str(candidate) not in own_paths and (
                candidate.exists() or candidate.is_symlink()
            ):
                raise ManagerError(f"Target directory is already occupied: {candidate}")
            if any(
                candidate == other
                or candidate.is_relative_to(other)
                or other.is_relative_to(candidate)
                for other in other_paths
            ):
                raise ManagerError(
                    f"Runner directory overlaps another managed group: {candidate}"
                )
        for instance in group["instances"]:
            self.registered(name, instance, group)

    def check_existing_arguments(self, arguments: Arguments, group: Group) -> None:
        """Reject requested settings that conflict with an existing group."""
        supplied: tuple[tuple[str, object, object], ...] = (
            (
                "directory",
                str(arguments.directory) if arguments.directory else None,
                group["directory"],
            ),
            ("url", arguments.url, group["url"]),
            ("labels", arguments.labels, group["labels"]),
            ("proxy_command", arguments.proxy_command, group["proxy_command"]),
        )
        for key, value, current in supplied:
            if value is not None and value != current:
                raise ManagerError(
                    f"Existing group has a different {key}; create cannot modify it"
                )
        if arguments.runner_file and group["package"]:
            package = (
                self.packages.describe(arguments.runner_file)
                if arguments.dry_run
                else self.packages.select(arguments.runner_file)
            )
            if package["sha256"] != group["package"]["sha256"]:
                raise ManagerError(
                    "Use update to change an existing group's runner package"
                )

    def run(self, arguments: Arguments) -> Status | None:
        """Dispatch a validated command while serializing state mutations."""
        if arguments.command == "status":
            return self.status(arguments.name, verbose=arguments.verbose)
        context = (
            nullcontext(self.store.load()) if arguments.dry_run else self.store.locked()
        )
        with context as groups:
            if arguments.command == "import":
                self.import_group(arguments, groups)
                return None
            name = arguments.name
            group = groups.get(name)
            if arguments.command == "create":
                if group:
                    self.check_existing_arguments(arguments, group)
                else:
                    if not arguments.directory or not arguments.url:
                        raise ManagerError("First create requires --dir and --url")
                    group = {
                        "directory": str(arguments.directory),
                        "url": arguments.url,
                        "labels": arguments.labels or [],
                        "proxy_command": arguments.proxy_command or [],
                        "count": 0,
                        "package": None,
                        "instances": [],
                    }
            if group is None:
                if arguments.command == "remove" and arguments.count == 0:
                    if arguments.dry_run:
                        print("[DRY RUN] Group is already absent; no changes")
                    return None
                raise ManagerError(f"Unknown runner group: {name}")
            pending = group.get("pending")
            target = (
                arguments.count if arguments.command in ("create", "remove") else None
            )
            if pending and (
                pending["kind"] != arguments.command or pending.get("target") != target
            ):
                raise ManagerError(
                    f"Group has unfinished {pending['kind']} operation (target={pending.get('target')}); retry that operation first"
                )
            if arguments.dry_run:
                Preview(self.store, self.packages, self.tmux).run(
                    arguments, group, groups, self.check_paths, self.registered
                )
                return None
            if arguments.command in ("create", "remove", "update"):
                self.reconcile(arguments, name, group, groups)
            else:
                self.control(arguments, name, group)
        return None

    def reconcile(
        self, arguments: Arguments, name: str, group: Group, groups: Groups
    ) -> None:
        """Converge a group to its requested count or package version."""
        operation = group.get("pending")
        if operation is None:
            target = (
                arguments.count if arguments.command != "update" else group["count"]
            )
            if arguments.command == "create" and target < group["count"]:
                raise ManagerError(
                    "create cannot shrink a group; use remove --count <remaining>"
                )
            if arguments.command == "remove" and target > group["count"]:
                raise ManagerError("remove --count cannot exceed the current count")
            self.check_paths(name, group, target, groups)
            items: list[OperationItem] = []
            for instance in group["instances"]:
                expected = (
                    runner_name(name, self.store.hostname, instance["index"], target)
                    if instance["index"] < target
                    else None
                )
                if arguments.command == "update" or expected != instance["name"]:
                    items.append(
                        {
                            **deepcopy(instance),
                            "old_name": instance["name"],
                            "new_name": expected,
                            "stage": "ready",
                        }
                    )
            for index in range(group["count"], target):
                expected = runner_name(name, self.store.hostname, index, target)
                items.append(
                    {
                        "index": index,
                        "name": expected,
                        "path": str(Path(group["directory"]) / expected),
                        "old_name": None,
                        "new_name": expected,
                        "stage": "allocate",
                    }
                )
            if (
                arguments.command in ("create", "remove")
                and items
                and not arguments.token
            ):
                raise ManagerError(
                    "--token is required for registration, removal or renaming"
                )
            if not items:
                return
            package = group["package"]
            if arguments.command in ("create", "update"):
                runner_file = arguments.runner_file
                if arguments.command == "create" and group["count"] and runner_file:
                    supplied = self.packages.select(runner_file)
                    if package and supplied["sha256"] != package["sha256"]:
                        raise ManagerError(
                            "Use update to change an existing group's runner package"
                        )
                    package = supplied
                elif arguments.command == "update" or package is None:
                    package = self.packages.select(
                        runner_file, latest=arguments.command == "update"
                    )
                else:
                    self.packages.verify(package)
                if arguments.command == "update":
                    items = [
                        item
                        for item in items
                        if "package" not in item
                        or item["package"]["sha256"] != package["sha256"]
                    ]
                    if not items:
                        return
            resume = []
            for item in items:
                if (
                    item["old_name"] is not None
                    and self.tmux.state(name, item)[0] != "stopped"
                ):
                    resume.append(item["index"])
            operation = {
                "kind": arguments.command,
                "target": (
                    arguments.count
                    if arguments.command in ("create", "remove")
                    else None
                ),
                "final_count": target,
                "phase": "stopping",
                "resume": resume,
                "items": items,
                "package": package,
            }
            group["pending"] = operation
            groups[name] = group
            self.store.save()
        else:
            if (
                operation["kind"] in ("create", "remove")
                and operation["phase"] != "restoring"
                and not arguments.token
            ):
                raise ManagerError("--token is required to resume this operation")
            if arguments.runner_file:
                supplied = self.packages.select(arguments.runner_file)
                saved_package = operation.get("package")
                if (
                    saved_package is None
                    or supplied["sha256"] != saved_package["sha256"]
                ):
                    raise ManagerError("Retry must use the same runner package")
            saved_package = operation.get("package")
            if saved_package:
                self.packages.verify(saved_package)
        if operation["phase"] == "stopping":
            affected = [
                item for item in operation["items"] if item["old_name"] is not None
            ]
            self.tmux.stop(
                name,
                affected,
                operation,
                self.store.save,
                arguments.timeout,
                arguments.force,
            )
            operation["phase"] = "changing"
            self.store.save()
        if operation["phase"] == "changing":
            for item in sorted(
                operation["items"],
                key=lambda value: (value["new_name"] is not None, -value["index"]),
            ):
                self.change_instance(name, group, operation, item, arguments.token)
            group["count"] = operation["final_count"]
            if operation["kind"] in ("create", "update"):
                group["package"] = operation["package"]
            group["instances"].sort(key=lambda instance: instance["index"])
            operation["phase"] = "restoring"
            self.store.save()
        if operation["phase"] == "restoring":
            for instance in group["instances"]:
                if instance["index"] in operation["resume"]:
                    self.registered(name, instance, group)
                    self.tmux.start(name, instance, group["proxy_command"])
            del group["pending"]
            if not group["count"]:
                del groups[name]
            self.store.save()

    def change_instance(
        self,
        name: str,
        group: Group,
        operation: Operation,
        item: OperationItem,
        token: str | None,
    ) -> None:
        """Advance one runner through its persisted operation stages."""
        if item["stage"] == "done":
            return
        path = Path(item["path"])
        if path.exists():
            assert_no_unmanaged_process(path)
        if item["stage"] == "allocate":
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists() or path.is_symlink():
                if path.is_symlink() or not path.is_dir():
                    raise ManagerError(f"Target is not an owned directory: {path}")
                marker = path / ".manager-owner.json"
                if marker.exists():
                    self.owned(name, item)
                elif any(path.iterdir()):
                    raise ManagerError(
                        f"Refusing to claim a nonempty directory: {path}"
                    )
            else:
                path.mkdir()
            atomic_json(
                path / ".manager-owner.json", self.identity(name, item["index"])
            )
            item["stage"] = "installing"
            self.store.save()
        if operation["kind"] == "update" and item["stage"] == "ready":
            self.registered(name, item, group)
            item["stage"] = "installing"
            self.store.save()
        if item["stage"] == "ready":
            self.registered(name, item, group)
            item["stage"] = "unregistering"
            self.store.save()
        if item["stage"] == "unregistering":
            self.owned(name, item)
            has_runner = (path / ".runner").exists()
            has_credentials = (path / ".credentials").exists()
            if has_runner and has_credentials:
                old_name = item["old_name"]
                assert old_name is not None
                github.unregister(path, old_name, group, token)
            elif has_runner or has_credentials:
                raise ManagerError(
                    f"Partial local unregistration at {path}; inspect config.sh removal before retrying"
                )
            item["stage"] = "unregistered"
            self.store.save()
        if item["stage"] == "unregistered":
            item["stage"] = "moving" if item["new_name"] else "deleting"
            self.store.save()
        if item["stage"] == "deleting":
            if path.exists() or path.is_symlink():
                if path.is_symlink():
                    raise ManagerError(
                        f"Refusing to delete a symlinked runner directory: {path}"
                    )
                if any(path.iterdir()):
                    self.owned(name, item)
                assert_no_unmanaged_process(path)
                for child in path.iterdir():
                    if child.name == ".manager-owner.json":
                        continue
                    if child.is_dir() and not child.is_symlink():
                        shutil.rmtree(child)
                    else:
                        child.unlink()
                (path / ".manager-owner.json").unlink(missing_ok=True)
                path.rmdir()
            group["instances"] = [
                instance
                for instance in group["instances"]
                if instance["index"] != item["index"]
            ]
            item["stage"] = "done"
            self.store.save()
            return
        if item["stage"] == "moving":
            new_name = item["new_name"]
            assert new_name is not None
            destination = Path(group["directory"]) / new_name
            if path.exists():
                self.owned(name, item)
                if destination.exists() or destination.is_symlink():
                    raise ManagerError(f"Rename destination is occupied: {destination}")
                path.rename(destination)
            else:
                moved_instance: Instance = {
                    "index": item["index"],
                    "name": item["name"],
                    "path": str(destination),
                }
                self.owned(name, moved_instance)
            item["path"] = str(destination)
            item["name"] = new_name
            path = destination
            item["stage"] = "registering"
            self.store.save()
        if item["stage"] == "installing":
            self.owned(name, item)
            package = operation.get("package")
            assert package is not None
            self.packages.install(package, path)
            item["package"] = package
            item["stage"] = "registering"
            self.store.save()
        if item["stage"] == "registering":
            self.owned(name, item)
            new_name = item["new_name"]
            assert new_name is not None
            github.register(path, new_name, group, token)
            instance: Instance = {
                "index": item["index"],
                "name": item["name"],
                "path": item["path"],
                "package": item["package"],
            }
            group["instances"] = [
                existing
                for existing in group["instances"]
                if existing["index"] != item["index"]
            ]
            group["instances"].append(instance)
            item["stage"] = "done"
            self.store.save()
            print(f"Configured {item['name']}", flush=True)

    def control(self, arguments: Arguments, name: str, group: Group) -> None:
        """Start or stop a group while preserving retry progress."""
        for instance in group["instances"]:
            self.registered(name, instance, group)
        if not group.get("pending"):
            group["pending"] = {
                "kind": arguments.command,
                "target": None,
                "stop_sent": {},
            }
            self.store.save()
        if arguments.command == "start":
            for instance in group["instances"]:
                self.tmux.start(name, instance, group["proxy_command"])
        else:
            self.tmux.stop(
                name,
                group["instances"],
                group["pending"],
                self.store.save,
                arguments.timeout,
                arguments.force,
            )
        del group["pending"]
        self.store.save()

    def import_group(self, arguments: Arguments, groups: Groups) -> None:
        """Adopt validated legacy instances after confirming they are stopped."""
        name = arguments.name
        count = arguments.count
        base = arguments.directory
        assert base is not None
        instances: list[Instance] = []
        urls: set[str] = set()
        for index in range(count):
            expected = runner_name(name, self.store.hostname, index, count)
            path = base / expected
            if path.is_symlink() or path.resolve() != path:
                raise ManagerError(f"Cannot import symlinked runner directory: {path}")
            value = metadata(path)
            stored_url = value.get("gitHubUrl") or arguments.url
            if not isinstance(stored_url, str) or not stored_url:
                raise ManagerError(
                    f"Runner metadata has no GitHub URL; provide --url: {path}"
                )
            url = stored_url.rstrip("/")
            if arguments.url and url != arguments.url:
                raise ManagerError(f"Imported URL does not match --url: {path}")
            verify_registration(path, expected, url)
            urls.add(url)
            assert_no_unmanaged_process(path)
            marker = path / ".manager-owner.json"
            if marker.exists() and read_json(marker) != self.identity(name, index):
                raise ManagerError(
                    f"Runner directory already belongs to another group: {path}"
                )
            version_file = path / "bin" / "Runner.Listener"
            if not version_file.is_file() or not (path / "run.sh").is_file():
                raise ManagerError(f"Incomplete runner installation: {path}")
            version = (
                "unresolved"
                if arguments.dry_run
                else execute([str(version_file), "--version"], cwd=path).stdout.strip()
            )
            if not version:
                raise ManagerError(f"Cannot determine imported runner version: {path}")
            instances.append(
                {
                    "index": index,
                    "name": expected,
                    "path": str(path),
                    "package": {"version": version, "sha256": None},
                }
            )
        if len(urls) != 1:
            raise ManagerError("Legacy group contains multiple GitHub URLs")
        group: Group = {
            "directory": str(base),
            "url": urls.pop(),
            "labels": arguments.labels or [],
            "proxy_command": arguments.proxy_command or [],
            "count": count,
            "package": None,
            "instances": instances,
        }
        existing = groups.get(name)
        if existing:
            if existing.get("pending"):
                raise ManagerError("Cannot import a group with an unfinished operation")
            comparable = ("directory", "url", "labels", "proxy_command", "count")
            if any(existing.get(field) != group.get(field) for field in comparable) or [
                item["path"] for item in existing["instances"]
            ] != [item["path"] for item in instances]:
                raise ManagerError(
                    "Imported group conflicts with the existing configuration"
                )
            if arguments.dry_run:
                print(f"[DRY RUN] {name} is already imported; no changes")
            return
        self.check_paths(name, {**group, "instances": []}, 0, groups)
        for other in groups.values():
            for other_path in self.reserved_paths(other):
                if any(
                    Path(item["path"]) == other_path
                    or Path(item["path"]).is_relative_to(other_path)
                    or other_path.is_relative_to(Path(item["path"]))
                    for item in instances
                ):
                    raise ManagerError("Imported directory overlaps another group")
        if arguments.dry_run:
            print(
                f"[DRY RUN] Import {count} stopped runners as {name}; labels: {','.join(group['labels']) or '(none)'}"
            )
            for instance in instances:
                print(
                    f"[DRY RUN] Read runner version and write ownership marker: {instance['path']}"
                )
            print(f"[DRY RUN] Save group {name} to {self.store.path}")
            return
        for instance in instances:
            atomic_json(
                Path(instance["path"]) / ".manager-owner.json",
                self.identity(name, instance["index"]),
            )
        groups[name] = group
        self.store.save()
        print(f"Imported {count} runners as {name}")

    def status(self, selected: str | None = None, verbose: bool = False) -> Status:
        """Collect live status and pending-operation summaries for this host."""
        groups = self.store.load()
        if selected and selected not in groups:
            raise ManagerError(f"Unknown runner group: {selected}")
        result: Status = {"hostname": self.store.hostname, "groups": []}
        for name, group in sorted(groups.items()):
            if selected and name != selected:
                continue
            pending = group.get("pending")
            instances: dict[int, Instance] = {
                item["index"]: item for item in group["instances"]
            }
            if pending:
                instances.update(
                    {
                        item["index"]: item
                        for item in pending.get("items", [])
                        if item["stage"] != "done"
                    }
                )
            summary: GroupStatus = {
                "name": name,
                "count": group["count"],
                "pending": None,
                "instances": [],
            }
            if pending:
                summary["pending"] = {
                    "kind": pending["kind"],
                    "target": pending["target"],
                    "phase": pending.get("phase"),
                }
            for index, instance in sorted(instances.items()):
                package = instance.get("package")
                row: InstanceStatus = {
                    "index": index,
                    "name": instance["name"],
                    "directory": instance["path"],
                    "version": package["version"] if package else "unknown",
                    "tmux": None,
                    "state": "unknown",
                }
                if verbose:
                    row["current_task"] = None
                    row["started_at"] = None
                    row["elapsed"] = None
                    row["last_task"] = None
                    row["result"] = None
                try:
                    self.registered(name, instance, group)
                    row["state"], pane = self.tmux.state(name, instance)
                    if pane:
                        row["tmux"] = f"{pane['session']} {pane['id']}"
                    if verbose:
                        details = self.tmux.details(pane, row["state"])
                        row["current_task"] = details["current_task"]
                        row["started_at"] = details["started_at"]
                        row["elapsed"] = details["elapsed"]
                        row["last_task"] = details["last_task"]
                        row["result"] = details["result"]
                        if details["state"] != "unknown":
                            row["state"] = details["state"]
                except ManagerError as error:
                    row["state"] = "error"
                    row["detail"] = str(error)
                summary["instances"].append(row)
            result["groups"].append(summary)
        return result
