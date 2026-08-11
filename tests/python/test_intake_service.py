from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from jl_mixing.intake import validate_intake

ROOT = Path(__file__).resolve().parents[2]


class IntakeServiceTests(unittest.TestCase):
    def test_empty_source_preserves_blocking_semantics(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            source.mkdir()
            result = validate_intake(source, ffprobe_path="")
            self.assertTrue(result.blocked)
            self.assertEqual(result.files_discovered, 0)
            self.assertEqual(result.blocking_errors, 1)
            self.assertIn("No files were found in the intake source.", result.report_markdown)

    def test_python_service_matches_existing_helper_without_ffprobe(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source"
            source.mkdir()
            (source / "Notes.txt").write_text("notes\n", encoding="utf-8")
            (source / "A").mkdir(); (source / "B").mkdir()
            (source / "A" / "same.txt").write_text("one\n", encoding="utf-8")
            (source / "B" / "same.txt").write_text("two\n", encoding="utf-8")

            result = validate_intake(
                source,
                expected_sample_rate=48000,
                expected_bit_depth=24,
                ffprobe_path="",
            )
            helper_report = Path(tmp) / "helper.md"
            env = os.environ.copy()
            env["PATH"] = ""
            proc = subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "tools" / "build-intake-report.py"),
                    "--source", str(source),
                    "--output", str(helper_report),
                    "--expected-sample-rate", "48000",
                    "--expected-bit-depth", "24",
                ],
                cwd=ROOT,
                env=env,
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(result.report_markdown, helper_report.read_text(encoding="utf-8"))
            self.assertEqual(result.files_discovered, 3)
            self.assertEqual(result.blocking_errors, 0)
            self.assertEqual(result.warnings, 5)  # duplicate pair + 3 unsupported files + ffprobe unavailable
            self.assertFalse(result.ffprobe_available)


if __name__ == "__main__":
    unittest.main()
