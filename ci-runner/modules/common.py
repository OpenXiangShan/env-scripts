from collections.abc import Sequence
import json
import os
from pathlib import Path
import subprocess
import tempfile
from typing import Any


class ManagerError(Exception):
    """Report a recoverable manager error."""


def execute(
    arguments: Sequence[str],
    cwd: Path | None = None,
    check: bool = True,
    secrets: Sequence[str] = (),
) -> subprocess.CompletedProcess[str]:
    """Run a command and redact secrets from failure output."""
    try:
        result = subprocess.run(arguments, cwd=cwd, text=True, capture_output=True)
    except OSError as error:
        raise ManagerError(f"Cannot execute {arguments[0]}: {error}") from error
    if check and result.returncode:
        detail = (result.stderr + result.stdout).strip()
        for secret in secrets:
            if secret:
                detail = detail.replace(secret, "<redacted>")
        raise ManagerError(
            f"{Path(arguments[0]).name} failed ({result.returncode}): {detail}"
        )
    return result


def read_json(path: str | Path) -> Any:
    """Read UTF-8 JSON with an optional BOM and report decoding errors."""
    try:
        return json.loads(Path(path).read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as error:
        raise ManagerError(f"Cannot read JSON {path}: {error}") from error


def atomic_json(path: str | Path, value: object) -> None:
    """Persist JSON with an atomic replacement and filesystem sync."""
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "w") as stream:
            json.dump(value, stream, indent=2, ensure_ascii=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def runner_name(name: str, hostname: str, index: int, count: int) -> str:
    """Format a runner name using the target count's index width."""
    width = max(1, len(str(count - 1)))
    return f"{name}-{hostname}-{index:0{width}d}"


def metadata(path: str | Path) -> dict[str, Any]:
    """Read and validate the shape of local runner metadata."""
    value = read_json(Path(path) / ".runner")
    if not isinstance(value, dict):
        raise ManagerError(f"Invalid runner metadata: {path}")
    return value


def verify_registration(path: str | Path, name: str, url: str) -> dict[str, Any]:
    """Verify a runner's registered name, URL and local credentials."""
    value = metadata(path)
    if value.get("agentName") != name or value.get("gitHubUrl", "").rstrip("/") != url:
        raise ManagerError(f"Runner identity does not match expected name/URL: {path}")
    if not (Path(path) / ".credentials").is_file():
        raise ManagerError(f"Runner credentials are missing: {path}")
    return value
