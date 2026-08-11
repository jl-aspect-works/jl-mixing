"""Automation API 1.0 adapter for intake.validate."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ..context import resolve_project
from ..errors import ArgumentError, ContextError, JLMixingError, ValidationError
from ..intake import validate_intake
from ..markdown import replace_managed_section
from ..validation import require_bit_depth, require_sample_rate
from ..versions import api_version

_BEGIN = "<!-- BEGIN AUTOMATED SECTION -->"
_END = "<!-- END AUTOMATED SECTION -->"


@dataclass(frozen=True)
class IntakeRequest:
    project: Path
    source: Path | None = None
    expected_sample_rate: int | None = None
    expected_bit_depth: int | None = None
    duplicate_check: bool = True
    dry_run: bool = False


def _manifest(project: Path) -> dict[str, Any]:
    path = project / "00_Admin" / "project-manifest.json"
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValidationError(f"Project manifest is unreadable: {path}") from exc


def _workspace_path(project: Path) -> Path:
    current = project
    for _ in range(4):
        current = current.parent
    return current


def _error_envelope(code: str, message: str, exit_code: int, *, status: str = "error") -> dict[str, Any]:
    return {
        "api_version": api_version(),
        "operation": "intake.validate",
        "status": status,
        "data": {},
        "warnings": [],
        "errors": [{
            "code": code,
            "message": message,
            "details": {"exit_code": exit_code},
            "retryable": False,
        }],
    }


def execute(request: IntakeRequest) -> tuple[dict[str, Any], int]:
    try:
        project = resolve_project(request.project, Path.cwd())
        manifest = _manifest(project)
        project_id = manifest.get("project_id", "")
        audio = manifest.get("audio") if isinstance(manifest.get("audio"), dict) else {}
        sample_rate = require_sample_rate(
            request.expected_sample_rate if request.expected_sample_rate is not None else audio.get("sample_rate")
        )
        bit_depth = require_bit_depth(
            request.expected_bit_depth if request.expected_bit_depth is not None else audio.get("bit_depth")
        )

        source = (request.source or (project / "01_Client_Files" / "Original_Delivery")).resolve()
        result = validate_intake(
            source,
            expected_sample_rate=sample_rate,
            expected_bit_depth=bit_depth,
            duplicate_check=request.duplicate_check,
        )
        report_path = project / "00_Admin" / "Intake_Report.md"
        if request.dry_run:
            report_markdown = result.report_markdown
        else:
            replace_managed_section(report_path, _BEGIN, _END, result.report_markdown)
            try:
                report_markdown = report_path.read_text(encoding="utf-8")
            except OSError as exc:
                raise ValidationError(f"Intake report is unreadable after update: {report_path}") from exc

        status = "planned" if request.dry_run and not result.blocked else "blocked" if result.blocked else "success"
        exit_code = 5 if result.blocked else 0
        data: dict[str, Any] = {
            "project": {"id": project_id, "path": str(project)},
            "manifest_path": str(project / "00_Admin" / "project-manifest.json"),
            "intake_report_path": str(report_path),
            "workspace_path": str(_workspace_path(project)),
            "source_path": str(source),
            "report_markdown": report_markdown,
            "summary": {
                "files_discovered": result.files_discovered,
                "blocking_errors": result.blocking_errors,
                "warnings": result.warnings,
                "ffprobe_available": result.ffprobe_available,
            },
        }
        if request.dry_run:
            data["would_update"] = [str(report_path)]
        errors: list[dict[str, Any]] = []
        if result.blocked:
            errors.append({
                "code": "INTAKE_BLOCKING_FINDINGS",
                "message": "Intake validation completed with blocking findings.",
                "details": {"exit_code": 5, "blocking_errors": result.blocking_errors},
                "retryable": False,
            })
        return {
            "api_version": api_version(),
            "operation": "intake.validate",
            "status": status,
            "data": data,
            "warnings": [],
            "errors": errors,
        }, exit_code
    except ContextError as exc:
        return _error_envelope("PROJECT_NOT_FOUND", str(exc), exc.exit_code), exc.exit_code
    except ValidationError as exc:
        code = "SOURCE_NOT_FOUND" if "Source directory" in str(exc) else "VALIDATION_FAILED"
        return _error_envelope(code, str(exc), exc.exit_code, status="blocked"), exc.exit_code
    except JLMixingError as exc:
        return _error_envelope("INTERNAL_ERROR", str(exc), exc.exit_code), exc.exit_code


def parse_args(args: list[str]) -> IntakeRequest:
    project: str | None = None
    source: str | None = None
    sample_rate: int | None = None
    bit_depth: int | None = None
    duplicate_check = True
    dry_run = False
    json_seen = 0
    index = 0
    while index < len(args):
        arg = args[index]
        if arg == "--json":
            json_seen += 1
        elif arg in {"--project", "--source", "--expected-sample-rate", "--expected-bit-depth"}:
            index += 1
            if index >= len(args):
                raise ArgumentError(f"{arg} requires a value.")
            value = args[index]
            if arg == "--project":
                if project is not None:
                    raise ArgumentError("intake validate JSON mode requires exactly one --project PATH option.")
                project = value
            elif arg == "--source":
                source = value
            elif arg == "--expected-sample-rate":
                try:
                    sample_rate = int(value)
                except ValueError as exc:
                    raise ArgumentError(f"Invalid sample rate: {value}") from exc
            else:
                try:
                    bit_depth = int(value)
                except ValueError as exc:
                    raise ArgumentError(f"Invalid bit depth: {value}") from exc
        elif arg == "--no-duplicate-check":
            duplicate_check = False
        elif arg == "--dry-run":
            dry_run = True
        elif arg.startswith("--progress="):
            raise ArgumentError("intake validate does not yet support JSON progress events.")
        else:
            raise ArgumentError(f"Unknown option: {arg}")
        index += 1
    if json_seen != 1:
        raise ArgumentError("intake validate requires exactly one --json option.")
    if not project:
        raise ArgumentError("intake validate JSON mode requires exactly one --project PATH option.")
    return IntakeRequest(
        project=Path(project),
        source=Path(source) if source else None,
        expected_sample_rate=sample_rate,
        expected_bit_depth=bit_depth,
        duplicate_check=duplicate_check,
        dry_run=dry_run,
    )
