#!/usr/bin/env python3
"""Build the automation-managed section of Intake_Report.md."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
from typing import Any

AUDIO_EXTENSIONS = {".wav", ".wave", ".aif", ".aiff", ".flac", ".mp3", ".m4a"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--expected-sample-rate", type=int)
    parser.add_argument("--expected-bit-depth", type=int)
    parser.add_argument("--no-duplicate-check", action="store_true")
    return parser.parse_args()


def ffprobe_metadata(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    command = [
        "ffprobe",
        "-v",
        "error",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=sample_rate,bits_per_sample,bits_per_raw_sample,channels",
        "-show_entries",
        "format=duration",
        "-of",
        "json",
        str(path),
    ]
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        message = result.stderr.strip() or "ffprobe could not read the file"
        return None, message

    try:
        payload = json.loads(result.stdout)
        stream = (payload.get("streams") or [{}])[0]
        fmt = payload.get("format") or {}
        bits = stream.get("bits_per_raw_sample") or stream.get("bits_per_sample") or None
        return (
            {
                "sample_rate": int(stream["sample_rate"]) if stream.get("sample_rate") else None,
                "bit_depth": int(bits) if bits and str(bits).isdigit() and int(bits) > 0 else None,
                "channels": int(stream["channels"]) if stream.get("channels") else None,
                "duration": float(fmt["duration"]) if fmt.get("duration") else None,
            },
            None,
        )
    except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
        return None, f"could not parse ffprobe output: {exc}"


def format_technical(metadata: dict[str, Any] | None) -> str:
    if not metadata:
        return "not inspected"
    values: list[str] = []
    if metadata.get("sample_rate"):
        values.append(f"{metadata['sample_rate']} Hz")
    if metadata.get("bit_depth"):
        values.append(f"{metadata['bit_depth']}-bit")
    if metadata.get("channels"):
        values.append(f"{metadata['channels']} ch")
    if metadata.get("duration") is not None:
        values.append(f"{metadata['duration']:.2f} s")
    return ", ".join(values) or "readable audio"


def main() -> int:
    args = parse_args()
    source = args.source.resolve()
    if not source.is_dir():
        print(f"Source directory not found: {source}", file=sys.stderr)
        return 5

    files = sorted((path for path in source.rglob("*") if path.is_file()), key=lambda p: str(p).lower())
    ffprobe_available = shutil.which("ffprobe") is not None
    warnings: list[str] = []
    errors: list[str] = []
    inventory: list[tuple[Path, dict[str, Any] | None]] = []

    if not files:
        errors.append("No files were found in the intake source.")

    if not args.no_duplicate_check:
        by_name: dict[str, list[Path]] = {}
        for path in files:
            by_name.setdefault(path.name.lower(), []).append(path)
        for duplicate_paths in by_name.values():
            if len(duplicate_paths) > 1:
                display = ", ".join(str(path.relative_to(source)) for path in duplicate_paths)
                warnings.append(f"Duplicate filename detected: {display}")

    for path in files:
        extension = path.suffix.lower()
        metadata: dict[str, Any] | None = None
        if extension in AUDIO_EXTENSIONS:
            if ffprobe_available:
                metadata, error = ffprobe_metadata(path)
                if error:
                    errors.append(f"Unreadable audio file `{path.relative_to(source)}`: {error}")
                elif metadata:
                    actual_rate = metadata.get("sample_rate")
                    actual_depth = metadata.get("bit_depth")
                    if args.expected_sample_rate and actual_rate and actual_rate != args.expected_sample_rate:
                        warnings.append(
                            f"Sample-rate mismatch for `{path.relative_to(source)}`: "
                            f"{actual_rate} Hz; expected {args.expected_sample_rate} Hz."
                        )
                    if args.expected_bit_depth and actual_depth and actual_depth != args.expected_bit_depth:
                        warnings.append(
                            f"Bit-depth mismatch for `{path.relative_to(source)}`: "
                            f"{actual_depth}-bit; expected {args.expected_bit_depth}-bit."
                        )
            else:
                metadata = None
        else:
            warnings.append(f"Non-audio or unsupported extension: `{path.relative_to(source)}`")
        inventory.append((path, metadata))

    passed: list[str] = []
    if files:
        passed.append(f"Inventoried {len(files)} file(s).")
    if not errors:
        passed.append("No blocking intake errors were detected.")
    if ffprobe_available:
        passed.append("Enhanced audio inspection was available through ffprobe.")
    else:
        warnings.append("ffprobe is not installed; enhanced audio inspection was skipped.")

    lines: list[str] = [
        "## Intake Summary",
        "",
        f"- Source: `{source}`",
        f"- Files discovered: {len(files)}",
        f"- Blocking errors: {len(errors)}",
        f"- Warnings: {len(warnings)}",
        "",
        "## Expected Project Settings",
        "",
        f"- Sample rate: {args.expected_sample_rate or 'not specified'}",
        f"- Bit depth: {args.expected_bit_depth or 'not specified'}",
        "",
        "## Validation Results",
        "",
        "### Passed",
        "",
    ]
    lines.extend(f"- {item}" for item in passed)
    if not passed:
        lines.append("- None.")

    lines.extend(["", "### Warnings", ""])
    lines.extend(f"- {item}" for item in warnings)
    if not warnings:
        lines.append("- None.")

    lines.extend(["", "### Errors", ""])
    lines.extend(f"- {item}" for item in errors)
    if not errors:
        lines.append("- None.")

    lines.extend(["", "## Source Inventory", "", "| File | Size (bytes) | Technical details |", "|---|---:|---|"])
    for path, metadata in inventory:
        relative = str(path.relative_to(source)).replace("|", "\\|")
        lines.append(f"| `{relative}` | {path.stat().st_size} | {format_technical(metadata)} |")
    if not inventory:
        lines.append("| _No files_ | 0 | — |")

    lines.extend(["", "## Preparation Recommendations", ""])
    if errors:
        lines.append("- Resolve blocking errors before preparing `Working_Audio/`.")
    if warnings:
        lines.append("- Review warnings and document any accepted exceptions in `Preparation_Report.md`.")
    if not errors and not warnings:
        lines.append("- Intake is ready for manual audio preparation.")

    args.output.write_text("\n".join(lines).rstrip() + "\n")
    return 5 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
