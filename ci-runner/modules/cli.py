import argparse
from collections.abc import Sequence
import http.client
import json
from pathlib import Path
import re
import shlex
import sys
from urllib.parse import urlsplit

from .common import ManagerError, read_json
from .lifecycle import Manager
from .models import Arguments, LegacyConfig, Status


def positive(value: str) -> int:
    """Parse a positive integer argument."""
    number = int(value)
    if number <= 0:
        raise argparse.ArgumentTypeError("must be positive")
    return number


def nonnegative(value: str) -> int:
    """Parse an integer argument that may be zero."""
    number = int(value)
    if number < 0:
        raise argparse.ArgumentTypeError("must be nonnegative")
    return number


def valid_name(value: str) -> str:
    """Validate a runner group name for use in paths and tmux."""
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]*", value):
        raise argparse.ArgumentTypeError(
            "Names must start with a letter or digit and contain only letters, digits, _ or -"
        )
    return value


def normalize_url(value: str) -> str:
    """Validate a GitHub scope URL and remove its trailing slash."""
    parsed = urlsplit(value)
    if (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.username
        or parsed.password
    ):
        raise argparse.ArgumentTypeError(
            "--url must be an HTTPS GitHub repository or organization URL"
        )
    if parsed.query or parsed.fragment:
        raise argparse.ArgumentTypeError("--url cannot contain a query or fragment")
    segments = parsed.path.strip("/").split("/")
    if len(segments) not in (1, 2) or any(
        not segment or segment in (".", "..") for segment in segments
    ):
        raise argparse.ArgumentTypeError(
            "--url must identify an organization, repository or enterprise"
        )
    return value.rstrip("/")


def directory(value: str) -> Path:
    """Resolve a runner base directory and reject the filesystem root."""
    path = Path(value).expanduser().resolve()
    if path == Path("/"):
        raise argparse.ArgumentTypeError("Runner base directory cannot be /")
    return path


def runner_file(value: str) -> Path:
    """Resolve an existing local runner archive argument."""
    path = Path(value).expanduser().resolve()
    if not path.is_file():
        raise argparse.ArgumentTypeError(f"Runner archive does not exist: {path}")
    return path


def legacy_config(value: str) -> LegacyConfig:
    """Read and validate a legacy JSON group selector."""
    filename, separator, key = value.rpartition("#")
    if not separator or not filename or not key:
        raise argparse.ArgumentTypeError("--config must use path/to/config.json#key")
    try:
        data = read_json(Path(filename).expanduser())
        legacy = data.get(key) if isinstance(data, dict) else None
        if not isinstance(legacy, dict):
            raise argparse.ArgumentTypeError(f"No legacy configuration named {key}")
        for field in ("basename", "directory"):
            if not isinstance(legacy.get(field), str):
                raise argparse.ArgumentTypeError(f"Legacy {field} must be a string")
        count = legacy.get("count")
        if isinstance(count, bool) or not isinstance(count, (str, int)):
            raise argparse.ArgumentTypeError("Legacy count must be a positive integer")
        raw_labels = legacy.get("labels", [])
        if isinstance(raw_labels, str):
            imported_labels = labels(raw_labels) if raw_labels else []
        elif isinstance(raw_labels, list) and all(
            isinstance(item, str) for item in raw_labels
        ):
            imported_labels = labels(",".join(raw_labels)) if raw_labels else []
        else:
            raise argparse.ArgumentTypeError(
                "Legacy labels must be a comma-separated string or string list"
            )
        return LegacyConfig(
            valid_name(legacy["basename"]),
            directory(legacy["directory"]),
            positive(str(count)),
            imported_labels,
        )
    except (ManagerError, OSError, ValueError) as error:
        raise argparse.ArgumentTypeError(str(error)) from error


def labels(value: str) -> list[str]:
    """Parse and deduplicate a comma-separated label list."""
    values = value.split(",")
    if any(not item.strip() for item in values):
        raise argparse.ArgumentTypeError(
            "labels must be a comma-separated list of nonempty values"
        )
    return sorted(set(item.strip() for item in values))


def proxy_command(value: str) -> list[str]:
    """Split an optional command prefix into shell-free arguments."""
    try:
        return shlex.split(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(str(error)) from error


def stopping_options(parser: argparse.ArgumentParser) -> None:
    """Add the shared timeout and force flags to a command."""
    parser.add_argument(
        "--timeout",
        type=nonnegative,
        help="Total stop timeout in seconds (default: wait indefinitely)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Interrupt jobs; kill managed processes after a 10-second grace period",
    )


def parser() -> argparse.ArgumentParser:
    """Build the command parser with input validation at each option."""
    result = argparse.ArgumentParser(
        description="Manage GitHub self-hosted runners using tmux, without a manager daemon"
    )
    result.add_argument(
        "--dry-run", action="store_true", help="Preview actions without making changes"
    )
    commands = result.add_subparsers(dest="command", required=True)
    create = commands.add_parser(
        "create", help="Create or grow a group to the desired total count"
    )
    create.add_argument("name", type=valid_name)
    create.add_argument("--count", type=positive, required=True)
    create.add_argument("--dir", dest="directory", type=directory)
    create.add_argument("--url", type=normalize_url)
    create.add_argument("--labels", type=labels)
    create.add_argument("--proxy-command", type=proxy_command)
    create.add_argument("--runner-file", type=runner_file)
    create.add_argument("--token")
    stopping_options(create)
    start = commands.add_parser("start", help="Start stopped runners")
    start.add_argument("name", type=valid_name, nargs="?")
    stop = commands.add_parser("stop", help="Wait for idle runners and stop them")
    stop.add_argument("name", type=valid_name, nargs="?")
    stopping_options(stop)
    status = commands.add_parser("status", help="Inspect live local state")
    status.add_argument("name", type=valid_name, nargs="?")
    status.add_argument("--json", action="store_true")
    status.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="Show runner start time, running task duration and last task result",
    )
    update = commands.add_parser(
        "update", help="Install a local package or the latest stable release"
    )
    update.add_argument("name", type=valid_name, nargs="?")
    update.add_argument("--runner-file", type=runner_file)
    update.set_defaults(token=None)
    stopping_options(update)
    remove = commands.add_parser(
        "remove", help="Keep COUNT runners, removing only from the tail"
    )
    remove.add_argument("name", type=valid_name)
    remove.add_argument(
        "--count",
        type=nonnegative,
        required=True,
        help="Desired remaining count, NOT the number to delete",
    )
    remove.add_argument("--token")
    stopping_options(remove)
    imported = commands.add_parser(
        "import", help="Import a stopped group from legacy JSON"
    )
    imported.add_argument(
        "--config", type=legacy_config, required=True, help="Legacy JSON path#key"
    )
    imported.add_argument("--url", type=normalize_url)
    imported.add_argument(
        "--labels",
        type=labels,
        help="Override labels from the legacy JSON configuration",
    )
    imported.add_argument("--proxy-command", type=proxy_command)
    clean = commands.add_parser(
        "clean", help="Remove packages unreferenced by any state/*.json"
    )
    for command in (create, start, stop, status, update, remove, imported, clean):
        command.add_argument(
            "--dry-run",
            action="store_true",
            default=argparse.SUPPRESS,
            help="Preview actions without making changes",
        )
    return result


def parse_arguments(argv: Sequence[str] | None = None) -> Arguments:
    """Produce typed arguments and expand validated legacy configuration."""
    values = vars(parser().parse_args(argv))
    if values.get("name") is None:
        values.pop("name", None)
    arguments = Arguments(**values)
    if arguments.config is not None:
        arguments.name = arguments.config.name
        arguments.count = arguments.config.count
        arguments.directory = arguments.config.directory
        if arguments.labels is None:
            arguments.labels = arguments.config.labels
    return arguments


def elapsed_time(seconds: int | None) -> str:
    """Format a captured task duration as hours, minutes and seconds."""
    if seconds is None:
        return "-"
    hours, remainder = divmod(seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours:02}:{minutes:02}:{seconds:02}"


def print_status(result: Status, verbose: bool) -> None:
    """Render runner status rows or detailed activity blocks."""
    print(f"Host: {result['hostname']}")
    for group in result["groups"]:
        active = sum(instance["state"] != "stopped" for instance in group["instances"])
        print(f"{group['name']}: {active}/{group['count']} runners")
        if verbose and group["pending"]:
            print(f"{group['name']}: pending {group['pending']}")
        for instance in group["instances"]:
            if verbose:
                state = {
                    "busy": "Running",
                    "idle": "Idle",
                    "stopped": "Stopped",
                    "unknown": "Unknown",
                    "error": "Error",
                }[instance["state"]]
                print(f"  {instance['name']}:")
                print(f"    Version: {instance['version']}")
                print(f"    Path: {instance['directory']}")
                print(f"    Tmux: {instance['tmux'] or '-'}")
                print(f"    Status: {state}")
                if instance["state"] == "stopped":
                    continue
                print(f"    Started: {instance.get('started_at') or '-'}")
                if instance["state"] == "busy":
                    print(f"    Task: {instance.get('current_task') or '-'}")
                    print(f"    Elapsed: {elapsed_time(instance.get('elapsed'))}")
                elif instance["state"] == "idle":
                    print(f"    Last Task: {instance.get('last_task') or '-'}")
                    print(f"    Result: {instance.get('result') or '-'}")
            else:
                state = {
                    "busy": "Running",
                    "idle": "Idle",
                    "stopped": "Stopped",
                    "unknown": "Unknown",
                    "error": "Error",
                }[instance["state"]]
                print(f"  {instance['name']}: {state}")
            if instance.get("detail"):
                print(f"      Detail: {instance['detail']}")


def main(root: Path, argv: Sequence[str] | None = None) -> int:
    """Parse a command, execute it and render its result or error."""
    arguments = parse_arguments(argv)
    try:
        result = Manager(root).run(arguments)
        if arguments.command == "status":
            assert result is not None
            if arguments.json:
                print(json.dumps(result, indent=2, ensure_ascii=False))
            else:
                print_status(result, arguments.verbose)
        else:
            suffix = "preview complete" if arguments.dry_run else "complete"
            print(f"{arguments.command}: {suffix}")
        return 0
    except KeyboardInterrupt:
        print(
            "Interrupted; any recorded operation can be resumed with the same command",
            file=sys.stderr,
        )
        return 130
    except (
        ManagerError,
        OSError,
        ValueError,
        KeyError,
        TypeError,
        http.client.HTTPException,
    ) as error:
        message = str(error)
        token = getattr(arguments, "token", None)
        if token:
            message = message.replace(token, "<redacted>")
        print(f"Error: {message}", file=sys.stderr)
        return 1
