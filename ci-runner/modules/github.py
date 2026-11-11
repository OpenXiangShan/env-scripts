from pathlib import Path

from .common import ManagerError, execute, verify_registration
from .models import Group


def register(path: Path, name: str, group: Group, token: str | None) -> None:
    """Register a runner unless its matching local registration exists."""
    path = Path(path)
    if (path / ".runner").exists():
        verify_registration(path, name, group["url"])
        return
    if not token:
        raise ManagerError("--token is required to register runners")
    arguments = [
        *group["proxy_command"],
        "./config.sh",
        "--unattended",
        "--url",
        group["url"],
        "--token",
        token,
        "--name",
        name,
        "--disableupdate",
    ]
    if group["labels"]:
        arguments.extend(["--labels", ",".join(group["labels"])])
    execute(arguments, cwd=path, secrets=(token,))
    verify_registration(path, name, group["url"])


def unregister(path: Path, name: str, group: Group, token: str | None) -> None:
    """Unregister a runner and verify its local credentials were removed."""
    path = Path(path)
    if not token:
        raise ManagerError("--token is required to unregister runners")
    verify_registration(path, name, group["url"])
    execute(
        [
            *group["proxy_command"],
            "./config.sh",
            "remove",
            "--unattended",
            "--token",
            token,
        ],
        cwd=path,
        secrets=(token,),
    )
    if (path / ".runner").exists() or (path / ".credentials").exists():
        raise ManagerError(f"Unregistration did not remove local credentials: {path}")
