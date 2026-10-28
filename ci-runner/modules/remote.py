import json
from pathlib import Path
import shlex
from typing import cast

from .common import ManagerError, execute
from .models import Status


def decode_status(output: str) -> Status:
    """Validate remote JSON before passing it to the local status renderer."""
    try:
        value = json.loads(output)
    except ValueError as error:
        raise ManagerError(f"Remote manager returned invalid JSON: {error}") from error
    if (
        not isinstance(value, dict)
        or not isinstance(value.get("hostname"), str)
        or not isinstance(value.get("groups"), list)
    ):
        raise ManagerError("Remote manager returned an invalid host status")
    for group in value["groups"]:
        if (
            not isinstance(group, dict)
            or not isinstance(group.get("name"), str)
            or type(group.get("count")) is not int
            or group["count"] < 0
            or not isinstance(group.get("instances"), list)
        ):
            raise ManagerError("Remote manager returned an invalid group status")
        for instance in group["instances"]:
            if (
                not isinstance(instance, dict)
                or type(instance.get("index")) is not int
                or any(
                    not isinstance(instance.get(field), str)
                    for field in ("name", "directory", "version", "state")
                )
                or instance["state"]
                not in ("stopped", "idle", "busy", "unknown", "error")
                or "tmux" not in instance
                or not isinstance(instance.get("tmux"), (str, type(None)))
                or ("tail" in instance and not isinstance(instance["tail"], str))
                or any(
                    instance.get(field) is not None
                    and not isinstance(instance[field], str)
                    for field in (
                        "detail",
                        "started_at",
                        "current_task",
                        "last_task",
                        "result",
                        "tail",
                    )
                )
                or (
                    instance.get("elapsed") is not None
                    and (
                        type(instance["elapsed"]) is not int or instance["elapsed"] < 0
                    )
                )
            ):
                raise ManagerError("Remote manager returned an invalid runner status")
    return cast(Status, value)


def query_status(root: Path, host: str, name: str, verbose: int) -> Status:
    """Run the same manager checkout over SSH and return its structured status."""
    command = ["python3", str(root.resolve() / "manager.py"), "status", "--json"]
    if name:
        command.append(name)
    if verbose:
        command.append("-" + "v" * min(verbose, 3))
    result = execute(
        [
            "ssh",
            "-nT",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=10",
            "--",
            host,
            shlex.join(command),
        ]
    )
    return decode_status(result.stdout)
