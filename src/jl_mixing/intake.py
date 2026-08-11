"""Authoritative cross-platform intake-validation service."""

from __future__ import annotations

import json
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .errors import ValidationError

AUDIO_EXTENSIONS = {".wav", ".wave", ".aif", ".aiff", ".flac", ".mp3", ".m4a"}


@dataclass(frozen=True)
class IntakeResult:
    report_markdown: str
    files_discovered: int
    blocking_errors: int
    warnings: int
    ffprobe_available: bool

    @property
    def blocked(self) -> bool:
        return self.blocking_errors > 0


def ffprobe_metadata(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    command = [
        "ffprobe", "-v", "error", "-select_streams", "a:0",
        "-show_entries", "stream=sample_rate,bits_per_sample,bits_per_raw_sample,channels",
        "-show_entries", "format=duration", "-of", "json", str(path),
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return None, result.stderr.strip() or "ffprobe could not read the file"
    try:
        payload = json.loads(result.stdout)
        stream = (payload.get("streams") or [{}])[0]
        fmt = payload.get("format") or {}
        bits = stream.get("bits_per_raw_sample") or stream.get("bits_per_sample") or None
        return {
            "sample_rate": int(stream["sample_rate"]) if stream.get("sample_rate") else None,
            "bit_depth": int(bits) if bits and str(bits).isdigit() and int(bits) > 0 else None,
            "channels": int(stream["channels"]) if stream.get("channels") else None,
            "duration": float(fmt["duration"]) if fmt.get("duration") else None,
        }, None
    except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        return None, f"could not parse ffprobe output: {exc}"


def _format_technical(metadata: dict[str, Any] | None, inspection: str) -> str:
    if inspection == "unreadable": return "not readable"
    if inspection == "not-inspected": return "not inspected"
    if not metadata: return "readable audio"
    values: list[str] = []
    if metadata.get("sample_rate"): values.append(f"{metadata['sample_rate']} Hz")
    if metadata.get("bit_depth"): values.append(f"{metadata['bit_depth']}-bit")
    if metadata.get("channels"): values.append(f"{metadata['channels']} ch")
    if metadata.get("duration") is not None: values.append(f"{metadata['duration']:.2f} s")
    return ", ".join(values) or "readable audio"


def _items(items: list[str]) -> list[str]:
    return [f"- {item}" for item in items] if items else ["- None."]


def validate_intake(
    source: Path,
    *,
    expected_sample_rate: int | None = None,
    expected_bit_depth: int | None = None,
    duplicate_check: bool = True,
    ffprobe_path: str | None = None,
) -> IntakeResult:
    source = source.resolve()
    if not source.is_dir() or source.is_symlink():
        raise ValidationError(f"Source directory not found or unsafe: {source}")

    files = sorted(
        (p for p in source.rglob("*") if p.is_file() and not p.is_symlink()),
        key=lambda p: str(p.relative_to(source)).lower(),
    )
    detected_ffprobe = ffprobe_path if ffprobe_path is not None else shutil.which("ffprobe")
    ffprobe_available = bool(detected_ffprobe)

    critical_errors: list[str] = []
    duplicate_findings: list[str] = []
    mismatch_findings: list[str] = []
    unsupported_findings: list[str] = []
    unavailable_findings: list[str] = []
    inventory: list[tuple[Path, dict[str, Any] | None, str]] = []

    if not files:
        critical_errors.append("No files were found in the intake source.")

    if duplicate_check:
        by_name: dict[str, list[Path]] = {}
        for path in files:
            by_name.setdefault(path.name.lower(), []).append(path)
        for duplicates in by_name.values():
            if len(duplicates) > 1:
                duplicate_findings.append(", ".join(f"`{p.relative_to(source)}`" for p in duplicates))
    else:
        unavailable_findings.append("Duplicate-basename detection was skipped.")

    for path in files:
        relative = path.relative_to(source)
        metadata: dict[str, Any] | None = None
        inspection = "not-inspected"
        if path.suffix.lower() in AUDIO_EXTENSIONS:
            if ffprobe_available:
                metadata, error = ffprobe_metadata(path)
                if error:
                    critical_errors.append(f"Unreadable audio file `{relative}`: {error}")
                    inspection = "unreadable"
                else:
                    inspection = "inspected"
                    if metadata:
                        rate, depth = metadata.get("sample_rate"), metadata.get("bit_depth")
                        if expected_sample_rate and rate and rate != expected_sample_rate:
                            mismatch_findings.append(f"`{relative}`: {rate} Hz; expected {expected_sample_rate} Hz.")
                        if expected_bit_depth and depth and depth != expected_bit_depth:
                            mismatch_findings.append(f"`{relative}`: {depth}-bit; expected {expected_bit_depth}-bit.")
        else:
            unsupported_findings.append(f"`{relative}`")
        inventory.append((path, metadata, inspection))

    if not ffprobe_available:
        unavailable_findings.append("ffprobe is not installed; enhanced audio inspection was unavailable.")

    warning_count = len(duplicate_findings) + len(mismatch_findings) + len(unsupported_findings) + (0 if ffprobe_available else 1)
    enhanced = "available through ffprobe" if ffprobe_available else "unavailable"
    lines = [
        "## Intake Summary", "", f"- Source: `{source}`", f"- Files discovered: {len(files)}",
        f"- Blocking errors: {len(critical_errors)}", f"- Warnings: {warning_count}",
        f"- Expected sample rate: {expected_sample_rate or 'not specified'}",
        f"- Expected bit depth: {expected_bit_depth or 'not specified'}",
        f"- Enhanced inspection: {enhanced}", "", "## Critical Errors", "",
    ]
    lines.extend(_items(critical_errors))
    for title, items in (
        ("Duplicate Filenames", duplicate_findings),
        ("Project-Format Mismatches", mismatch_findings),
        ("Unsupported or Non-Audio Files", unsupported_findings),
        ("Skipped or Unavailable Checks", unavailable_findings),
    ):
        lines.extend(["", f"## {title}", ""]); lines.extend(_items(items))

    lines.extend(["", "## Source Inventory", "", "| File | Size (bytes) | Technical details |", "|---|---:|---|"])
    for path, metadata, inspection in inventory:
        relative = str(path.relative_to(source)).replace("|", "\\|")
        lines.append(f"| `{relative}` | {path.stat().st_size} | {_format_technical(metadata, inspection)} |")
    if not inventory:
        lines.append("| _No files_ | 0 | — |")

    recommendations: list[str] = []
    if critical_errors: recommendations.append("Resolve blocking errors before preparing `Working_Audio/`.")
    if mismatch_findings: recommendations.append("Review project-format mismatches before conversion or DAW import.")
    if duplicate_findings: recommendations.append("Review duplicate filenames to avoid ambiguous DAW imports.")
    if unsupported_findings: recommendations.append("Review unsupported or non-audio files and retain any required documentation.")
    if unavailable_findings: recommendations.append("Document skipped or unavailable checks in `Preparation_Report.md`.")
    if not recommendations: recommendations.append("Intake is ready for manual audio preparation.")
    lines.extend(["", "## Preparation Recommendations", ""])
    lines.extend(f"- {item}" for item in recommendations)

    return IntakeResult(
        report_markdown="\n".join(lines).rstrip() + "\n",
        files_discovered=len(files), blocking_errors=len(critical_errors), warnings=warning_count,
        ffprobe_available=ffprobe_available,
    )
