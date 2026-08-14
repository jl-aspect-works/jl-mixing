"""Incremental intake-validation coordinator.

The low-level intake service caches expensive file inspection facts. This layer
ensures those cached facts are reused only under the same project validation
context, so changes to expected format or tool capability cannot return stale
findings.
"""

from __future__ import annotations

import json
import os
import shutil
from pathlib import Path
from typing import Any

from .intake import IntakeResult, validate_intake


def _normalized_format(value: str | None) -> str | None:
    if not value:
        return None
    normalized = value.strip().lower().lstrip(".")
    return {"wave": "wav", "aif": "aiff"}.get(normalized, normalized)


def _tool_value(explicit: str | None, executable: str) -> str | None:
    if explicit is not None:
        return explicit or None
    return shutil.which(executable)


def _context(
    *,
    expected_sample_rate: int | None,
    expected_bit_depth: int | None,
    expected_format: str | None,
    ffprobe_path: str | None,
    ffmpeg_path: str | None,
) -> dict[str, Any]:
    return {
        "expected_sample_rate": expected_sample_rate,
        "expected_bit_depth": expected_bit_depth,
        "expected_format": _normalized_format(expected_format),
        "ffprobe_available": bool(ffprobe_path),
        "ffmpeg_available": bool(ffmpeg_path),
    }


def _read_context(cache_path: Path) -> dict[str, Any] | None:
    if not cache_path.is_file() or cache_path.is_symlink():
        return None
    try:
        document = json.loads(cache_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    context = document.get("validation_context") if isinstance(document, dict) else None
    return context if isinstance(context, dict) else None


def _annotate_cache(cache_path: Path, context: dict[str, Any]) -> None:
    document = json.loads(cache_path.read_text(encoding="utf-8"))
    if not isinstance(document, dict):
        return
    document["validation_context"] = context
    temporary = cache_path.with_name(f".{cache_path.name}.{os.getpid()}.context.tmp")
    temporary.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    temporary.replace(cache_path)


def validate_intake_incremental(
    source: Path,
    *,
    expected_sample_rate: int | None = None,
    expected_bit_depth: int | None = None,
    expected_format: str | None = None,
    duplicate_check: bool = True,
    ffprobe_path: str | None = None,
    ffmpeg_path: str | None = None,
    cache_path: Path | None = None,
    update_cache: bool = True,
) -> IntakeResult:
    resolved_ffprobe = _tool_value(ffprobe_path, "ffprobe")
    resolved_ffmpeg = _tool_value(ffmpeg_path, "ffmpeg")
    context = _context(
        expected_sample_rate=expected_sample_rate,
        expected_bit_depth=expected_bit_depth,
        expected_format=expected_format,
        ffprobe_path=resolved_ffprobe,
        ffmpeg_path=resolved_ffmpeg,
    )

    active_cache = cache_path
    temporary_cache: Path | None = None
    if cache_path is not None and _read_context(cache_path) != context:
        if update_cache:
            temporary_cache = cache_path.with_name(f".{cache_path.name}.{os.getpid()}.refresh.tmp")
            try:
                temporary_cache.unlink()
            except FileNotFoundError:
                pass
            active_cache = temporary_cache
        else:
            active_cache = None

    result = validate_intake(
        source,
        expected_sample_rate=expected_sample_rate,
        expected_bit_depth=expected_bit_depth,
        expected_format=expected_format,
        duplicate_check=duplicate_check,
        ffprobe_path=resolved_ffprobe or "",
        ffmpeg_path=resolved_ffmpeg or "",
        cache_path=active_cache,
        update_cache=update_cache,
    )

    if update_cache and active_cache is not None and active_cache.is_file():
        _annotate_cache(active_cache, context)
        if temporary_cache is not None and cache_path is not None:
            temporary_cache.replace(cache_path)

    return result
