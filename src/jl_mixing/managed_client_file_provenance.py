"""Persistent provenance for managed Original Delivery -> Audio Prep lineage."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

from .errors import UnsafeOperationError, ValidationError
from . import managed_client_files as base

PROVENANCE_PATH = Path("00_Admin") / "audio-prep-provenance.json"
SCHEMA_VERSION = 1


def _empty_document() -> dict[str, Any]:
    return {"schema_version": SCHEMA_VERSION, "entries": []}


def _load(project_root: Path) -> dict[str, Any]:
    path = project_root / PROVENANCE_PATH
    if not path.exists():
        return _empty_document()
    if path.is_symlink() or not path.is_file():
        raise UnsafeOperationError(f"Audio Prep provenance path is unavailable or unsafe: {path}")
    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"Audio Prep provenance is unreadable: {path}") from exc
    if not isinstance(document, dict) or document.get("schema_version") != SCHEMA_VERSION or not isinstance(document.get("entries"), list):
        raise ValidationError("Audio Prep provenance has an unsupported format; repair is required.")

    seen_sources: set[str] = set()
    seen_working: set[str] = set()
    for entry in document["entries"]:
        if not isinstance(entry, dict):
            raise ValidationError("Audio Prep provenance contains an invalid entry; repair is required.")
        source = base._safe_relative(str(entry.get("source_relative_path", "")))
        working = base._safe_relative(str(entry.get("working_relative_path", "")))
        if not working.startswith(f"{base.AUDIO_ROOT.as_posix()}/"):
            raise ValidationError("Audio Prep provenance points outside Working_Audio; repair is required.")
        source_key = source.casefold()
        working_key = working.casefold()
        if source_key in seen_sources or working_key in seen_working:
            raise ValidationError("Audio Prep provenance contains ambiguous lineage; repair is required.")
        seen_sources.add(source_key)
        seen_working.add(working_key)
    return document


def _write(project_root: Path, document: dict[str, Any]) -> None:
    path = project_root / PROVENANCE_PATH
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.is_symlink():
        raise UnsafeOperationError(f"Audio Prep provenance path may not be a symlink: {path}")
    temporary = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    temporary.write_text(json.dumps(document, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temporary, path)


def _source_objects(plan: dict[str, Any]) -> list[base.SourceFile]:
    return [
        base.SourceFile(
            data["relative_path"],
            Path(data["source_path"]) if data.get("source_path") else None,
            data.get("zip_member"),
            int(data["size"]),
            data["fingerprint"],
        )
        for data in plan["files"]
    ]


def _working_hash_match(project_root: Path, working_sha256: str) -> str | None:
    audio_root = project_root / base.AUDIO_ROOT
    if not audio_root.exists():
        return None
    if audio_root.is_symlink() or not audio_root.is_dir():
        raise UnsafeOperationError(f"Audio Prep root is unavailable or unsafe: {audio_root}")
    matches: list[str] = []
    for current, dirs, names in os.walk(audio_root, followlinks=False):
        current_path = Path(current)
        for directory in dirs:
            if (current_path / directory).is_symlink():
                raise UnsafeOperationError(f"Audio Prep does not allow symlink traversal: {current_path / directory}")
        for name in names:
            candidate = current_path / name
            if candidate.is_symlink() or not candidate.is_file():
                continue
            if base._sha256_file(candidate) == working_sha256:
                relative = candidate.relative_to(audio_root).as_posix()
                matches.append((base.AUDIO_ROOT / Path(relative)).as_posix())
    if len(matches) > 1:
        raise ValidationError("Multiple Audio Prep files match recorded working-file provenance; repair is required.")
    return matches[0] if matches else None


def _lineage_destination(project_root: Path, source_relative: str) -> str | None:
    document = _load(project_root)
    matches = [
        entry for entry in document["entries"]
        if str(entry.get("source_relative_path", "")).casefold() == source_relative.casefold()
    ]
    if len(matches) > 1:
        raise ValidationError(f"Multiple Audio Prep lineage entries exist for {source_relative}; repair is required.")
    if not matches:
        return None
    entry = matches[0]
    working = base._safe_relative(str(entry["working_relative_path"]))
    destination = base._managed_destination(project_root, working)
    if destination.is_file():
        return working
    recorded_hash = entry.get("working_sha256")
    if isinstance(recorded_hash, str) and recorded_hash:
        return _working_hash_match(project_root, recorded_hash)
    return None


def _fallback_match(project_root: Path, source_relative: str, candidate: Path | None) -> str | None:
    if candidate is None or not candidate.is_file():
        return None
    return base._audio_prep_content_match(project_root, candidate)


def _resolved_destination(project_root: Path, source_relative: str, fallback_source: Path | None) -> str | None:
    return _lineage_destination(project_root, source_relative) or _fallback_match(project_root, source_relative, fallback_source)


def plan_import(project_root: Path, source_kind: str, sources: tuple[Path, ...]) -> dict[str, Any]:
    plan = base.plan_import(project_root, source_kind, sources)
    source_objects = {source.relative_path: source for source in _source_objects(plan)}
    items: list[dict[str, Any]] = []
    for item in plan["items"]:
        if item["area"] != "audio_prep":
            items.append(item)
            continue
        source_relative = item["source_relative_path"]
        existing_original = base._managed_destination(
            project_root,
            (base.ORIGINAL_ROOT / Path(source_relative)).as_posix(),
        )
        fallback = existing_original if existing_original.is_file() else source_objects[source_relative].source_path
        destination = _resolved_destination(project_root, source_relative, fallback)
        if destination:
            items.append(base._item(
                project_root,
                item["id"],
                "audio_prep",
                destination,
                source_objects[source_relative],
                depends_on=item.get("depends_on"),
            ))
        else:
            items.append(item)
    plan["items"] = items
    plan["plan_id"] = base._plan_id("client.files.import", source_kind, sources, source_objects.values(), items)
    return plan


def plan_reset(project_root: Path, relative_paths: tuple[str, ...]) -> dict[str, Any]:
    files: list[base.SourceFile] = []
    items: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw in enumerate(relative_paths):
        relative = base._safe_relative(raw)
        key = relative.casefold()
        if key in seen:
            raise ValidationError(f"Duplicate reset path: {relative}")
        seen.add(key)
        source = base._managed_destination(project_root, (base.ORIGINAL_ROOT / Path(relative)).as_posix())
        if not source.is_file():
            raise ValidationError(f"Original Delivery file not found: {relative}")
        source_file = base.SourceFile(relative, source, None, source.stat().st_size, base._source_fingerprint(source))
        files.append(source_file)
        destination = _resolved_destination(project_root, relative, source) or (base.AUDIO_ROOT / Path(relative)).as_posix()
        items.append(base._item(project_root, f"audio:{index}", "audio_prep", destination, source_file))
    if not files:
        raise ValidationError("At least one Original Delivery file is required.")
    return {
        "operation": "audio.prep.reset",
        "source_kind": "original_delivery",
        "sources": [source.relative_path for source in files],
        "plan_id": base._plan_id("audio.prep.reset", "original_delivery", (), files, items),
        "files": [base._serialized_source(source) for source in files],
        "items": items,
    }


def _record_successful_lineage(project_root: Path, plan: dict[str, Any], result: dict[str, Any]) -> None:
    statuses = {item["id"]: item["result"] for item in result.get("items", [])}
    document = _load(project_root)
    entries = list(document["entries"])
    changed = False
    for item in plan["items"]:
        if item["area"] != "audio_prep" or statuses.get(item["id"]) not in {"created", "replaced"}:
            continue
        source_relative = base._safe_relative(item["source_relative_path"])
        working_relative = base._safe_relative(item["destination_relative_path"])
        source_path = base._managed_destination(project_root, (base.ORIGINAL_ROOT / Path(source_relative)).as_posix())
        working_path = base._managed_destination(project_root, working_relative)
        if not source_path.is_file() or not working_path.is_file():
            continue
        source_key = source_relative.casefold()
        working_key = working_relative.casefold()
        entries = [
            entry for entry in entries
            if str(entry.get("source_relative_path", "")).casefold() != source_key
            and str(entry.get("working_relative_path", "")).casefold() != working_key
        ]
        entries.append({
            "source_relative_path": source_relative,
            "working_relative_path": working_relative,
            "source_sha256": base._sha256_file(source_path),
            "working_sha256": base._sha256_file(working_path),
            "transformations": ["copied"],
        })
        changed = True
    if changed:
        entries.sort(key=lambda entry: str(entry["source_relative_path"]).casefold())
        document["entries"] = entries
        _write(project_root, document)


def execute_plan(project_root: Path, plan: dict[str, Any], decisions: dict[str, str]) -> dict[str, Any]:
    result = base.execute_plan(project_root, plan, decisions)
    _record_successful_lineage(project_root, plan, result)
    return result
