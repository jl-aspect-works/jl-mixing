"""Cross-platform staged file transaction primitives."""

from __future__ import annotations

import os
import tempfile
from pathlib import Path

from .paths import assert_mutable_path


def atomic_write_bytes(target: Path, data: bytes, *, mode: int | None = None) -> None:
    """Atomically replace one file using a temporary sibling and os.replace()."""

    assert_mutable_path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    existing_mode = None
    if target.exists() and target.is_file():
        existing_mode = target.stat().st_mode & 0o777

    fd, temp_name = tempfile.mkstemp(prefix=f".{target.name}.", dir=target.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(fd, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        final_mode = mode if mode is not None else existing_mode
        if final_mode is not None:
            os.chmod(temp_path, final_mode)
        os.replace(temp_path, target)
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
