"""Cross-platform staged file transaction primitives."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

from .errors import JLMixingError
from .paths import assert_mutable_path


def _fail_requested(point: str) -> bool:
    configured = os.environ.get("JL_MIXING_FAIL_AT", "")
    return any(item.strip() == point for item in configured.split(",") if item.strip())


def _injected_failure(point: str) -> JLMixingError:
    return JLMixingError(f"Injected transaction failure at: {point}")


def _write_sibling(path: Path, data: bytes, mode: int | None) -> Path:
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        if mode is not None:
            os.chmod(temp_path, mode)
        return temp_path
    except Exception:
        if temp_path.exists():
            temp_path.unlink()
        raise


def atomic_write_bytes(target: Path, data: bytes, *, mode: int | None = None) -> None:
    """Atomically replace one file with rollback-compatible test hooks.

    The prior regular file is retained in memory until replacement succeeds so
    the v1.4 ``after-file-backup`` and ``after-file-replacement`` failure
    injection points can exercise the same rollback contract on every platform.
    Production behavior is unchanged when ``JL_MIXING_FAIL_AT`` is unset.
    """

    assert_mutable_path(target)
    target.parent.mkdir(parents=True, exist_ok=True)

    prior_exists = target.exists()
    prior_data: bytes | None = None
    prior_mode: int | None = None
    if prior_exists:
        if target.is_symlink() or not target.is_file():
            raise JLMixingError(f"Transaction file target is missing or unsafe: {target}")
        prior_data = target.read_bytes()
        prior_mode = target.stat().st_mode & 0o777

    if _fail_requested("after-file-backup"):
        raise _injected_failure("after-file-backup")

    final_mode = mode if mode is not None else prior_mode
    temp_path = _write_sibling(target, data, final_mode)
    replaced = False
    try:
        os.replace(temp_path, target)
        replaced = True
        if _fail_requested("after-file-replacement"):
            raise _injected_failure("after-file-replacement")
    except Exception:
        if replaced:
            if prior_exists:
                assert prior_data is not None
                restore = _write_sibling(target, prior_data, prior_mode)
                try:
                    os.replace(restore, target)
                finally:
                    if restore.exists():
                        restore.unlink()
            elif target.exists() or target.is_symlink():
                target.unlink()
        raise
    finally:
        if temp_path.exists():
            temp_path.unlink()


def atomic_write_text(
    target: Path,
    text: str,
    *,
    encoding: str = "utf-8",
    newline: str = "\n",
    mode: int | None = None,
) -> None:
    normalized = text.replace("\r\n", "\n").replace("\r", "\n")
    if newline != "\n":
        normalized = normalized.replace("\n", newline)
    atomic_write_bytes(target, normalized.encode(encoding), mode=mode)
