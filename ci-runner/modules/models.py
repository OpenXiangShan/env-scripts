from dataclasses import dataclass
from pathlib import Path
from typing import Literal, NotRequired, TypedDict

type Command = Literal[
    "create", "start", "stop", "status", "update", "remove", "import"
]
type RunnerState = Literal["stopped", "idle", "busy", "unknown", "error"]
type Stage = Literal[
    "ready",
    "allocate",
    "installing",
    "unregistering",
    "unregistered",
    "moving",
    "deleting",
    "registering",
    "done",
]


class Package(TypedDict):
    """Describe a cached runner package."""

    platform: str
    version: str
    sha256: str
    root: str


class ImportedPackage(TypedDict):
    """Describe the version of an imported runner."""

    version: str
    sha256: None


class Instance(TypedDict):
    """Describe a managed runner instance."""

    index: int
    name: str
    path: str
    package: NotRequired[Package | ImportedPackage]


class OperationItem(Instance):
    """Track one instance through a resumable operation."""

    old_name: str | None
    new_name: str | None
    stage: Stage


class Operation(TypedDict):
    """Record the progress needed to resume a command."""

    kind: Command
    target: int | None
    stop_sent: NotRequired[dict[str, str]]
    final_count: NotRequired[int]
    phase: NotRequired[Literal["stopping", "changing", "restoring"]]
    resume: NotRequired[list[int]]
    items: NotRequired[list[OperationItem]]
    package: NotRequired[Package | None]


class Group(TypedDict):
    """Store the configuration and instances of a runner group."""

    directory: str
    url: str
    labels: list[str]
    proxy_command: list[str]
    count: int
    package: Package | None
    instances: list[Instance]
    pending: NotRequired[Operation]


type Groups = dict[str, Group]


class HostState(TypedDict):
    """Store all runner groups belonging to one hostname."""

    schema_version: int
    hostname: str
    groups: Groups


class Owner(TypedDict):
    """Identify the owner of a managed runner directory."""

    hostname: str
    name: str
    index: int


class Pane(TypedDict):
    """Identify a managed tmux pane and its process."""

    id: str
    pid: int
    dead: bool
    session: str


class Process(TypedDict):
    """Describe the process fields used for runner detection."""

    parent: int
    group: int
    command: str


class RunnerDetails(TypedDict):
    """Describe runner activity parsed from captured tmux output."""

    state: RunnerState
    current_task: str | None
    started_at: str | None
    elapsed: int | None
    last_task: str | None
    result: str | None


class PendingStatus(TypedDict):
    """Summarize an unfinished command for status output."""

    kind: Command
    target: int | None
    phase: str | None


class InstanceStatus(TypedDict):
    """Describe the observed state of a runner instance."""

    index: int
    name: str
    directory: str
    version: str
    tmux: str | None
    state: RunnerState
    detail: NotRequired[str]
    current_task: NotRequired[str | None]
    started_at: NotRequired[str | None]
    elapsed: NotRequired[int | None]
    last_task: NotRequired[str | None]
    result: NotRequired[str | None]


class GroupStatus(TypedDict):
    """Summarize a runner group and its live instances."""

    name: str
    count: int
    pending: PendingStatus | None
    instances: list[InstanceStatus]


class Status(TypedDict):
    """Report live runner state for the current host."""

    hostname: str
    groups: list[GroupStatus]


@dataclass
class LegacyConfig:
    """Hold a validated group configuration from legacy JSON."""

    name: str
    directory: Path
    count: int


@dataclass
class Arguments:
    """Carry parsed command arguments into the lifecycle layer."""

    command: Command
    name: str = ""
    count: int = 0
    directory: Path | None = None
    url: str | None = None
    labels: list[str] | None = None
    proxy_command: list[str] | None = None
    runner_file: Path | None = None
    token: str | None = None
    timeout: int | None = None
    force: bool = False
    json: bool = False
    verbose: bool = False
    config: LegacyConfig | None = None
