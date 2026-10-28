from contextlib import nullcontext
from pathlib import Path

from .common import ManagerError
from .models import Groups
from .packages import Packages, digest
from .storage import Store


def references(groups: Groups) -> set[str]:
    """Collect package references from groups and unfinished operations."""
    result: set[str] = set()
    for group in groups.values():
        if checksum := group["package"]:
            result.add(checksum)
        operation = group.get("pending")
        if operation:
            if checksum := operation.get("package"):
                result.add(checksum)
            for item in operation.get("items", []):
                if checksum := item.get("package"):
                    result.add(checksum)
    return result


class Cleaner:
    """Remove unused package metadata and cache files across all hosts."""

    def __init__(self, root: Path) -> None:
        """Bind cleanup to the manager's shared state and cache directories."""
        self.root = root.resolve()
        self.cache = self.root / ".cache"
        self.store = Store(self.root)

    def collect(self) -> tuple[list[Store], set[str], set[Path]]:
        """Validate all state files before planning registry and cache cleanup."""
        changed: list[Store] = []
        used: set[str] = set()
        protected: set[Path] = set()
        for path in sorted((self.root / "state").glob("*.json")):
            if path.is_symlink() or not path.is_file():
                raise ManagerError(f"Cannot inspect state file safely: {path}")
            store = Store(self.root, path.stem)
            local_references = references(store.load())
            used.update(local_references)
            for checksum in local_references:
                package_root = store.data["packages"][checksum]["root"]
                if package_root is None:
                    continue
                directory = Path(package_root)
                if not directory.is_absolute():
                    raise ManagerError(f"Package path must be absolute: {directory}")
                if directory.is_relative_to(self.cache):
                    if directory.resolve() != directory:
                        raise ManagerError(
                            f"Referenced cache path is not canonical: {directory}"
                        )
                    protected.add(directory)
            if store.data["packages"].keys() - local_references:
                store.data["packages"] = {
                    checksum: info
                    for checksum, info in store.data["packages"].items()
                    if checksum in local_references
                }
                changed.append(store)
        return changed, used, protected

    def candidates(self, directory: Path, protected: set[Path]) -> list[Path]:
        """Find removable cache entries without following directory symlinks."""
        result: list[Path] = []
        for path in sorted(directory.iterdir()):
            if path in protected:
                continue
            if any(target.is_relative_to(path) for target in protected):
                if path.is_symlink() or not path.is_dir():
                    raise ManagerError(
                        f"Cannot traverse referenced cache directory: {path}"
                    )
                result.extend(self.candidates(path, protected))
            else:
                result.append(path)
        return result

    def plan(self) -> tuple[list[Store], list[Path]]:
        """Plan removal of unreferenced registry entries and cache contents."""
        if self.cache.is_symlink():
            raise ManagerError(f"Refusing to clean symlinked cache: {self.cache}")
        changed, used, protected = self.collect()
        if not self.cache.exists():
            return changed, []
        package_directory = self.cache / "packages"
        if package_directory.is_symlink():
            raise ManagerError(
                f"Refusing to inspect symlinked package cache: {package_directory}"
            )
        if package_directory.is_dir():
            for path in package_directory.iterdir():
                if path.name.rsplit("-", 1)[-1] in used:
                    protected.add(path)
        for path in self.cache.glob("actions-runner-*.tar.gz"):
            if not path.is_symlink() and path.is_file() and digest(path) in used:
                protected.add(path)
        if self.cache in protected:
            return changed, []
        return changed, self.candidates(self.cache, protected)

    def run(self, dry_run: bool = False) -> None:
        """Preview or execute cleanup while excluding concurrent cache mutations."""
        context = nullcontext() if dry_run else self.store.cache_locked(exclusive=True)
        with context:
            changed, paths = self.plan()
            prefix = "[DRY RUN] " if dry_run else ""
            for store in changed:
                print(f"{prefix}Prune unused package metadata: {store.path}")
                if not dry_run:
                    store.save()
            for path in paths:
                print(f"{prefix}Remove cache entry: {path}")
                if not dry_run:
                    Packages.discard(path)
            if not changed and not paths:
                print(f"{prefix}No unused packages or cache files")
