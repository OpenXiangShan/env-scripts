import hashlib
from http.client import HTTPResponse
import json
import os
from pathlib import Path, PurePosixPath
import platform
import re
import shutil
import tarfile
import tempfile
from typing import cast
import urllib.error
import urllib.request

from .common import ManagerError, atomic_json, read_json
from .models import Package

PACKAGE_PATTERN = re.compile(
    r"actions-runner-(linux-(?:x64|arm64))-(\d+\.\d+\.\d+)\.tar\.gz"
)
PROTECTED = {
    ".runner",
    ".credentials",
    ".credentials_rsaparams",
    ".env",
    ".path",
    "_work",
    "_diag",
    ".manager-owner.json",
}


def digest(path: Path) -> str:
    """Calculate a file's SHA-256 checksum in bounded chunks."""
    checksum = hashlib.sha256()
    with Path(path).open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
    return checksum.hexdigest()


class Packages:
    """Select, verify and install runner packages from a local cache."""

    def __init__(self, root: Path) -> None:
        """Locate the package cache relative to the manager root."""
        self.cache = root / ".cache"

    def target(self) -> str:
        """Return the supported runner platform for this host."""
        architecture = {"x86_64": "x64", "aarch64": "arm64"}.get(platform.machine())
        if platform.system() != "Linux" or not architecture:
            raise ManagerError("Only Linux x64 and arm64 runner packages are supported")
        return f"linux-{architecture}"

    def request(self, url: str) -> HTTPResponse:
        """Open a download without using environment proxy settings."""
        request = urllib.request.Request(
            url,
            headers={
                "User-Agent": "ci-runner-manager",
                "Accept": "application/vnd.github+json",
            },
        )
        try:
            return cast(
                HTTPResponse,
                urllib.request.build_opener(urllib.request.ProxyHandler({})).open(
                    request, timeout=30
                ),
            )
        except (OSError, urllib.error.URLError) as error:
            raise ManagerError(f"Download failed for {url}: {error}") from error

    def cached(self) -> list[Package]:
        """List cached package descriptions matching this host platform."""
        packages: list[Package] = []
        for path in sorted((self.cache / "packages").glob("*/package.json")):
            value = read_json(path)
            if value.get("platform") == self.target():
                packages.append(value)
        return packages

    def verify(self, package: Package) -> Package:
        """Check a cached package's location, payload and archive checksum."""
        root = Path(package["root"])
        if root.resolve() != root or not root.is_relative_to(
            (self.cache / "packages").resolve()
        ):
            raise ManagerError("Package is outside this manager's cache")
        if not (root / "files" / "bin" / "Runner.Listener").is_file():
            raise ManagerError(f"Incomplete package cache: {root}")
        if digest(root / "archive.tar.gz") != package["sha256"]:
            raise ManagerError(f"Package checksum mismatch: {root}")
        return package

    def select(self, runner_file: Path | None = None, latest: bool = False) -> Package:
        """Select an explicit package, cached version or latest stable release."""
        if runner_file:
            return self.ingest(Path(runner_file).expanduser().resolve())
        for archive in sorted(self.cache.glob("actions-runner-*.tar.gz")):
            match = PACKAGE_PATTERN.fullmatch(archive.name)
            if match and match[1] == self.target():
                self.ingest(archive)
        cached = self.cached()
        if cached and not latest:
            package = max(
                cached,
                key=lambda value: (
                    tuple(map(int, value["version"].split("."))),
                    value["sha256"],
                ),
            )
            return self.verify(package)
        with self.request(
            "https://api.github.com/repos/actions/runner/releases/latest"
        ) as response:
            release = json.load(response)
        if release.get("prerelease") or release.get("draft"):
            raise ManagerError("GitHub returned a non-stable release")
        version = release["tag_name"].removeprefix("v")
        filename = f"actions-runner-{self.target()}-{version}.tar.gz"
        asset = next(
            (item for item in release.get("assets", []) if item["name"] == filename),
            None,
        )
        if not asset:
            raise ManagerError(f"Release has no asset {filename}")
        checksum = asset.get("digest") or ""
        checksum = checksum.removeprefix("sha256:")
        if not re.fullmatch(r"[a-fA-F0-9]{64}", checksum):
            body = release.get("body") or ""
            matches = re.findall(
                re.escape(filename) + r"[^\n]*?\b([a-fA-F0-9]{64})\b", body
            )
            if not matches:
                matches = re.findall(
                    r"\b([a-fA-F0-9]{64})\b[^\n]*?" + re.escape(filename), body
                )
            if len(set(matches)) != 1:
                raise ManagerError(
                    "Release has no unambiguous SHA-256; supply a trusted --runner-file instead"
                )
            checksum = matches[0]
        checksum = checksum.lower()
        for package in cached:
            if package["version"] == version and package["sha256"] == checksum:
                return self.verify(package)
        self.cache.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(
            prefix="download-", dir=self.cache
        ) as temporary:
            archive = Path(temporary) / filename
            print(f"Downloading {filename}")
            with self.request(asset["browser_download_url"]) as response, archive.open(
                "wb"
            ) as stream:
                shutil.copyfileobj(response, stream)
            if digest(archive) != checksum:
                raise ManagerError(f"SHA-256 mismatch: {filename}")
            return self.ingest(archive)

    def ingest(self, archive: Path) -> Package:
        """Cache an archive and translate tar errors into manager errors."""
        try:
            return self.unpack(archive)
        except tarfile.TarError as error:
            raise ManagerError(f"Invalid runner archive {archive}: {error}") from error

    def describe(self, archive: Path) -> Package:
        """Describe a local archive without extracting or caching it."""
        match = PACKAGE_PATTERN.fullmatch(archive.name)
        if not match or match[1] != self.target() or not archive.is_file():
            raise ManagerError(
                "--runner-file must be an existing actions-runner-linux-<arch>-<version>.tar.gz matching this host"
            )
        checksum = digest(archive)
        destination = (
            self.cache / "packages" / f"{match[1]}-{match[2]}-{checksum}"
        ).resolve()
        return {
            "platform": match[1],
            "version": match[2],
            "sha256": checksum,
            "root": str(destination),
        }

    def preview(
        self, runner_file: Path | None = None, latest: bool = False
    ) -> tuple[Package | None, list[str]]:
        """Describe package selection without downloads or cache writes."""
        if runner_file:
            package = self.describe(runner_file)
            if Path(package["root"]).exists():
                self.verify(read_json(Path(package["root"]) / "package.json"))
                return package, [f"Reuse cached runner package {package['version']}"]
            return package, [
                f"Validate, cache and extract {runner_file} -> {package['root']}"
            ]
        archives = []
        for archive in sorted(self.cache.glob("actions-runner-*.tar.gz")):
            match = PACKAGE_PATTERN.fullmatch(archive.name)
            if match and match[1] == self.target():
                archives.append((archive, self.describe(archive)))
        actions = [
            f"Validate and cache local archive {archive}"
            for archive, package in archives
            if not Path(package["root"]).exists()
        ]
        if latest:
            return None, actions + [
                f"Query latest stable GitHub release for {self.target()} at execution time",
                f"Reuse matching cache or download, verify SHA-256 and extract into {self.cache}",
            ]
        cached = self.cached()
        candidates = cached + [package for archive, package in archives]
        if not candidates:
            return None, [
                f"Query latest stable GitHub release for {self.target()} at execution time",
                f"Download, verify SHA-256 and extract into {self.cache}",
            ]
        selected = max(
            candidates,
            key=lambda value: (
                tuple(map(int, value["version"].split("."))),
                value["sha256"],
            ),
        )
        if Path(selected["root"]).exists():
            self.verify(selected)
        return selected, actions + [f"Use cached runner package {selected['version']}"]

    def unpack(self, archive: Path) -> Package:
        """Validate and safely extract an archive into the package cache."""
        package = self.describe(archive)
        checksum = package["sha256"]
        destination = Path(package["root"])
        if destination.exists():
            return self.verify(read_json(destination / "package.json"))
        destination.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(
            prefix="extract-", dir=destination.parent
        ) as temporary:
            staging = Path(temporary) / "package"
            files = staging / "files"
            files.mkdir(parents=True)
            shutil.copyfile(archive, staging / "archive.tar.gz")
            if digest(staging / "archive.tar.gz") != checksum:
                raise ManagerError(f"Archive changed while being cached: {archive}")
            with tarfile.open(staging / "archive.tar.gz", "r:gz") as bundle:
                members = bundle.getmembers()
                for member in members:
                    relative = PurePosixPath(member.name)
                    if relative.is_absolute() or ".." in relative.parts:
                        raise ManagerError(f"Unsafe archive path: {member.name}")
                    if relative.parts and (
                        relative.parts[0] in PROTECTED
                        or relative.parts[0].startswith(".manager-")
                    ):
                        raise ManagerError(
                            f"Archive contains protected runner state: {member.name}"
                        )
                    if not (
                        member.isfile()
                        or member.isdir()
                        or member.issym()
                        or member.islnk()
                    ):
                        raise ManagerError(f"Unsupported archive entry: {member.name}")
                    if member.issym() or member.islnk():
                        target = (
                            files / member.linkname
                            if member.islnk()
                            else files / member.name / ".." / member.linkname
                        )
                        if not target.resolve().is_relative_to(files.resolve()):
                            raise ManagerError(f"Unsafe archive link: {member.name}")
                bundle.extractall(files, members=members, filter="data")
            for required in ("config.sh", "run.sh", "bin/Runner.Listener"):
                if not (files / required).is_file():
                    raise ManagerError(f"Package is missing {required}")
            if not (files / "externals").is_dir():
                raise ManagerError("Package is missing the externals directory")
            atomic_json(staging / "package.json", package)
            os.replace(staging, destination)
        return package

    def install(self, package: Package, destination: Path) -> None:
        """Replace runner program files while preserving local state."""
        files = Path(package["root"]) / "files"
        staging = destination / ".manager-install"
        self.discard(staging)
        staging.mkdir()
        for source in files.iterdir():
            staged = staging / source.name
            if source.name == "externals":
                staged.symlink_to(files / "externals", target_is_directory=True)
            elif source.is_symlink():
                staged.symlink_to(os.readlink(source))
            elif source.is_dir():
                shutil.copytree(source, staged, symlinks=True)
            else:
                shutil.copy2(source, staged)
        for staged in staging.iterdir():
            target = destination / staged.name
            backup = destination / f".manager-old-{staged.name}"
            if target.exists() or target.is_symlink():
                self.discard(backup)
                target.rename(backup)
            os.replace(staged, target)
            self.discard(backup)
        staging.rmdir()

    @staticmethod
    def discard(path: Path) -> None:
        """Remove a staging entry without following directory symlinks."""
        if path.is_dir() and not path.is_symlink():
            shutil.rmtree(path)
        elif path.exists() or path.is_symlink():
            path.unlink()
