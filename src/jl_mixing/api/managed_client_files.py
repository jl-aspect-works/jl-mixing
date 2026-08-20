"""Automation API 1.0 adapters for managed Client Files import and Audio Prep reset."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ..context import resolve_project, studio_root
from ..errors import ArgumentError, ContextError, JLMixingError, UnsafeOperationError, ValidationError
from ..managed_client_files import execute_plan, plan_import, plan_reset
from ..versions import api_version


@dataclass(frozen=True)
class ImportRequest:
    project: Path | None
    source_kind: str
    sources: tuple[Path, ...]
    plan_id: str | None = None
    decisions: dict[str, str] | None = None


@dataclass(frozen=True)
class ResetRequest:
    project: Path | None
    relative_paths: tuple[str, ...]
    plan_id: str | None = None
    decisions: dict[str, str] | None = None


def _envelope(operation: str, status: str, data: dict[str, Any], *, errors: list[dict[str, Any]] | None = None) -> dict[str, Any]:
    return {"api_version": api_version(), "operation": operation, "status": status, "data": data, "warnings": [], "errors": errors or []}


def _error(operation: str, code: str, message: str, exit_code: int, *, status: str = "error") -> dict[str, Any]:
    return _envelope(operation, status, {}, errors=[{"code": code, "message": message, "details": {"exit_code": exit_code}, "retryable": False}])


def _project_data(root: Path) -> dict[str, str]:
    return {"path": str(root), "workspace_path": str(studio_root(root))}


def execute_import_plan(request: ImportRequest) -> tuple[dict[str, Any], int]:
    operation = "client_files.import.plan"
    try:
        root = resolve_project(request.project, Path.cwd())
        plan = plan_import(root, request.source_kind, request.sources)
        return _envelope(operation, "planned", {"project": _project_data(root), "plan": plan}), 0
    except ContextError as exc: return _error(operation, "PROJECT_NOT_FOUND", str(exc), exc.exit_code), exc.exit_code
    except UnsafeOperationError as exc: return _error(operation, "UNSAFE_OPERATION", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except ValidationError as exc: return _error(operation, "VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except (JLMixingError, OSError) as exc:
        code = "FILESYSTEM_ERROR" if isinstance(exc, OSError) else "INTERNAL_ERROR"
        exit_code = getattr(exc, "exit_code", 1)
        return _error(operation, code, str(exc), exit_code), exit_code


def execute_import(request: ImportRequest) -> tuple[dict[str, Any], int]:
    operation = "client_files.import.execute"
    try:
        if not request.plan_id:
            raise ValidationError("Import execute requires --plan-id.")
        root = resolve_project(request.project, Path.cwd())
        plan = plan_import(root, request.source_kind, request.sources)
        if plan["plan_id"] != request.plan_id:
            raise ValidationError("Import plan is stale; run import-plan again.")
        result = execute_plan(root, plan, request.decisions or {})
        return _envelope(operation, "success", {"project": _project_data(root), "plan_id": plan["plan_id"], "result": result}), 0
    except ContextError as exc: return _error(operation, "PROJECT_NOT_FOUND", str(exc), exc.exit_code), exc.exit_code
    except UnsafeOperationError as exc: return _error(operation, "UNSAFE_OPERATION", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except ValidationError as exc: return _error(operation, "VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except (JLMixingError, OSError) as exc:
        code = "FILESYSTEM_ERROR" if isinstance(exc, OSError) else "INTERNAL_ERROR"
        exit_code = getattr(exc, "exit_code", 1)
        return _error(operation, code, str(exc), exit_code), exit_code


def execute_reset_plan(request: ResetRequest) -> tuple[dict[str, Any], int]:
    operation = "audio_prep.reset.plan"
    try:
        root = resolve_project(request.project, Path.cwd())
        plan = plan_reset(root, request.relative_paths)
        return _envelope(operation, "planned", {"project": _project_data(root), "plan": plan}), 0
    except ContextError as exc: return _error(operation, "PROJECT_NOT_FOUND", str(exc), exc.exit_code), exc.exit_code
    except UnsafeOperationError as exc: return _error(operation, "UNSAFE_OPERATION", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except ValidationError as exc: return _error(operation, "VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except (JLMixingError, OSError) as exc:
        code = "FILESYSTEM_ERROR" if isinstance(exc, OSError) else "INTERNAL_ERROR"
        exit_code = getattr(exc, "exit_code", 1)
        return _error(operation, code, str(exc), exit_code), exit_code


def execute_reset(request: ResetRequest) -> tuple[dict[str, Any], int]:
    operation = "audio_prep.reset.execute"
    try:
        if not request.plan_id:
            raise ValidationError("Audio Prep reset execute requires --plan-id.")
        root = resolve_project(request.project, Path.cwd())
        plan = plan_reset(root, request.relative_paths)
        if plan["plan_id"] != request.plan_id:
            raise ValidationError("Audio Prep reset plan is stale; run reset-plan again.")
        result = execute_plan(root, plan, request.decisions or {})
        return _envelope(operation, "success", {"project": _project_data(root), "plan_id": plan["plan_id"], "result": result}), 0
    except ContextError as exc: return _error(operation, "PROJECT_NOT_FOUND", str(exc), exc.exit_code), exc.exit_code
    except UnsafeOperationError as exc: return _error(operation, "UNSAFE_OPERATION", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except ValidationError as exc: return _error(operation, "VALIDATION_FAILED", str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except (JLMixingError, OSError) as exc:
        code = "FILESYSTEM_ERROR" if isinstance(exc, OSError) else "INTERNAL_ERROR"
        exit_code = getattr(exc, "exit_code", 1)
        return _error(operation, code, str(exc), exit_code), exit_code


def _parse_decisions(raw: str) -> dict[str, str]:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ArgumentError("--decisions-json must be valid JSON.") from exc
    if not isinstance(value, dict) or not all(isinstance(key, str) and isinstance(item, str) for key, item in value.items()):
        raise ArgumentError("--decisions-json must be an object mapping conflict IDs to replace or skip.")
    return value


def parse_import_args(args: list[str], *, execute: bool) -> ImportRequest:
    project: Path | None = None; source_kind: str | None = None; sources: list[Path] = []
    plan_id: str | None = None; decisions: dict[str, str] | None = None; json_seen = 0; index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--json": json_seen += 1
        elif arg in {"--project", "--source-kind", "--source", "--plan-id", "--decisions-json"}:
            index += 1
            if index >= len(args): raise ArgumentError(f"{arg} requires a value.")
            value = args[index]
            if arg == "--project": project = Path(value)
            elif arg == "--source-kind": source_kind = value
            elif arg == "--source": sources.append(Path(value))
            elif arg == "--plan-id": plan_id = value
            else: decisions = _parse_decisions(value)
        else: raise ArgumentError(f"Unknown option: {arg}")
        index += 1
    if json_seen != 1: raise ArgumentError("managed import requires exactly one --json option.")
    if source_kind not in {"zip", "folder", "files"}: raise ArgumentError("--source-kind must be zip, folder, or files.")
    if not sources: raise ArgumentError("At least one --source is required.")
    if not execute and (plan_id is not None or decisions is not None): raise ArgumentError("import-plan does not accept execute-only options.")
    if execute and plan_id is None: raise ArgumentError("import-execute requires --plan-id.")
    return ImportRequest(project, source_kind, tuple(sources), plan_id, decisions)


def parse_reset_args(args: list[str], *, execute: bool) -> ResetRequest:
    project: Path | None = None; relative_paths: list[str] = []; plan_id: str | None = None
    decisions: dict[str, str] | None = None; json_seen = 0; index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--json": json_seen += 1
        elif arg in {"--project", "--relative-path", "--plan-id", "--decisions-json"}:
            index += 1
            if index >= len(args): raise ArgumentError(f"{arg} requires a value.")
            value = args[index]
            if arg == "--project": project = Path(value)
            elif arg == "--relative-path": relative_paths.append(value)
            elif arg == "--plan-id": plan_id = value
            else: decisions = _parse_decisions(value)
        else: raise ArgumentError(f"Unknown option: {arg}")
        index += 1
    if json_seen != 1: raise ArgumentError("Audio Prep reset requires exactly one --json option.")
    if not relative_paths: raise ArgumentError("At least one --relative-path is required.")
    if not execute and (plan_id is not None or decisions is not None): raise ArgumentError("reset-plan does not accept execute-only options.")
    if execute and plan_id is None: raise ArgumentError("reset-execute requires --plan-id.")
    return ResetRequest(project, tuple(relative_paths), plan_id, decisions)
