from collections.abc import Callable
from pathlib import Path
import shlex
from typing import Any

from .common import ManagerError, runner_name
from .models import Arguments, Group, Groups, Instance, Operation, OperationItem
from .packages import Packages
from .storage import Store
from .tmux import Tmux


class Preview:
    """Describe lifecycle changes without executing mutation steps."""

    def __init__(self, store: Store, packages: Packages, tmux: Tmux) -> None:
        """Bind previews to state, package and runtime inspectors."""
        self.store = store
        self.packages = packages
        self.tmux = tmux

    def show(self, message: str) -> None:
        """Print a proposed action with an explicit dry-run prefix."""
        print(f"[DRY RUN] {message}")

    def stop(self, arguments: Arguments, name: str, instance: Instance) -> bool:
        """Describe stopping a runner and report whether it is running."""
        state, pane = self.tmux.state(name, instance)
        if state == "stopped":
            if pane:
                self.show(
                    f"Close stopped tmux window {pane['id']} for {instance['name']}"
                )
            return False
        if arguments.force:
            policy = (
                "send Ctrl-C immediately; force termination after 10 seconds if needed"
            )
        else:
            policy = "wait until idle, send Ctrl-C and wait for process exit"
        self.show(f"Stop {instance['name']} ({state}): {policy}; close its tmux window")
        return True

    def run(
        self,
        arguments: Arguments,
        group: Group,
        groups: Groups,
        check_paths: Callable[[str, Group, int, Groups], None],
        registered: Callable[[str, Instance, Group], dict[str, Any]],
    ) -> None:
        """Validate a requested operation and print its proposed effects."""
        name = arguments.name
        self.show(f"{arguments.command} {name}; no changes will be made")
        if arguments.command in ("create", "remove"):
            self.show(
                f"GitHub URL: {group['url']}; labels: {','.join(group['labels']) or '(none)'}"
            )
        if group["proxy_command"]:
            self.show(
                f"Runner command: {shlex.join([*group['proxy_command'], './run.sh'])}"
            )
        if arguments.timeout is not None:
            self.show(f"Stop timeout: {arguments.timeout} seconds")
        pending = group.get("pending")
        if pending:
            self.show(
                f"Resume unfinished {pending['kind']} at phase {pending.get('phase', 'control')}"
            )
        if arguments.command in ("start", "stop"):
            for instance in self.store.instances(name, group):
                registered(name, instance, group)
                if arguments.command == "stop":
                    self.stop(arguments, name, instance)
                elif self.tmux.state(name, instance)[0] == "stopped":
                    self.show(
                        f"Start {instance['name']} in tmux session {self.tmux.session(name)} from {instance['path']}"
                    )
                else:
                    self.show(f"Skip running runner {instance['name']}")
            return
        if pending:
            self.resume(arguments, group, pending)
            return
        target = group["count"] if arguments.command == "update" else arguments.count
        if arguments.command == "create" and target < group["count"]:
            raise ManagerError(
                "create cannot shrink a group; use remove --count <remaining>"
            )
        if arguments.command == "remove" and target > group["count"]:
            raise ManagerError("remove --count cannot exceed the current count")
        check_paths(name, group, target, groups)
        self.show(f"Runner count: {group['count']} -> {target}")
        affected = [
            instance
            for instance in self.store.instances(name, group)
            if arguments.command == "update"
            or instance["index"] >= target
            or instance["name"]
            != runner_name(name, self.store.hostname, instance["index"], target)
        ]
        if not affected and target == group["count"]:
            self.show("Already at the requested count; no changes")
            return
        package = self.store.group_package(group)
        if arguments.command in ("create", "update"):
            if (
                arguments.runner_file
                or package is None
                or arguments.command == "update"
            ):
                package, actions = self.packages.preview(
                    arguments.runner_file, latest=arguments.command == "update"
                )
                for action in actions:
                    self.show(action)
            else:
                self.packages.verify(package)
                self.show(f"Reuse group runner package {package['version']}")
        if arguments.command == "update":
            if package:
                if group["package"] == package["sha256"]:
                    self.show("All runners already use this package; no changes")
                    return
            else:
                self.show(
                    "Update this group if its package differs from the selected release"
                )
        replace_package = arguments.command == "create" and (
            package is None or package["sha256"] != group["package"]
        )
        if replace_package:
            affected = self.store.instances(name, group)
        resume = []
        for instance in affected:
            if self.stop(arguments, name, instance) and instance["index"] < target:
                resume.append(instance["index"])
        for instance in sorted(
            affected, key=lambda value: (value["index"] < target, -value["index"])
        ):
            expected = (
                runner_name(name, self.store.hostname, instance["index"], target)
                if instance["index"] < target
                else None
            )
            if arguments.command == "update" or expected == instance["name"]:
                self.show(
                    f"Update program files for {instance['name']}; preserve credentials, work and logs"
                )
                continue
            self.show(
                f"Unregister {instance['name']} from {group['url']} using --token <redacted>"
            )
            if instance["index"] >= target:
                self.show(
                    f"Delete runner directory including work and logs: {instance['path']}"
                )
            else:
                expected = runner_name(
                    name, self.store.hostname, instance["index"], target
                )
                destination = Path(group["directory"]) / expected
                self.show(f"Rename {instance['path']} -> {destination}")
                if replace_package:
                    self.show(f"Install the shared group package into {destination}")
                self.show(
                    f"Register {expected} at {group['url']} using --token <redacted>"
                )
        for index in range(group["count"], target):
            expected = runner_name(name, self.store.hostname, index, target)
            self.show(
                f"Create {Path(group['directory']) / expected}; install runner and shared externals link"
            )
            self.show(
                f"Register {expected} at {group['url']} using --token <redacted>; leave stopped"
            )
        for index in resume:
            expected = runner_name(name, self.store.hostname, index, target)
            self.show(f"Restart previously running runner {expected} in tmux")
        if arguments.command in ("create", "remove"):
            self.show("A valid --token is required for actual registration or removal")
        action = "Remove group" if target == 0 else "Save group and operation progress"
        self.show(f"{action} in {self.store.path}")

    def resume(self, arguments: Arguments, group: Group, operation: Operation) -> None:
        """Preview the remaining stages recorded by an interrupted operation."""
        package = self.store.package(operation.get("package"))
        if arguments.runner_file:
            supplied = self.packages.describe(arguments.runner_file)
            if package is None or supplied["sha256"] != package["sha256"]:
                raise ManagerError("Retry must use the same runner package")
        if package:
            self.packages.verify(package)
        phase = operation.get("phase")
        if phase == "stopping":
            for item in operation.get("items", []):
                if item["old_name"] is not None:
                    self.stop(arguments, arguments.name, item)
        for item in sorted(
            operation.get("items", []),
            key=lambda value: (value["new_name"] is not None, -value["index"]),
        ):
            if item["stage"] == "done":
                continue
            self.show(f"Continue {item['name']} from stage {item['stage']}")
            if phase != "restoring":
                self.remaining_item(arguments, group, item)
        target = operation["final_count"]
        for index in operation.get("resume", []):
            if index < target:
                expected = runner_name(
                    arguments.name, self.store.hostname, index, target
                )
                self.show(
                    f"Restore previously running runner {expected} in tmux if stopped"
                )
        self.show(
            f"Finalize count {target} and clear operation progress in {self.store.path}"
        )

    def remaining_item(
        self, arguments: Arguments, group: Group, item: OperationItem
    ) -> None:
        """Describe unfinished directory and registration changes for an item."""
        stage = item["stage"]
        expected = item["new_name"]
        install_only = arguments.command == "update" or (
            item["old_name"] is not None and item["old_name"] == expected
        )
        if stage == "allocate":
            self.show(f"Create owned runner directory {item['path']}")
        if stage in ("allocate", "installing") or install_only and stage == "ready":
            self.show(f"Install selected runner package into {item['path']}")
        elif stage in ("ready", "unregistering"):
            self.show(
                f"Finish unregistering {item['old_name']} using --token <redacted> if still registered"
            )
        if expected is None:
            self.show(
                f"Delete runner directory including work and logs: {item['path']}"
            )
            return
        destination = Path(group["directory"]) / expected
        if (
            stage in ("ready", "unregistering", "unregistered", "moving")
            and not install_only
        ):
            self.show(f"Ensure directory renamed {item['path']} -> {destination}")
            operation = group.get("pending")
            if (
                arguments.command == "create"
                and operation
                and operation.get("package") != group["package"]
            ):
                self.show(f"Install selected runner package into {destination}")
        self.show(
            f"Ensure {expected} is registered at {group['url']}; preserve matching local registration"
        )
