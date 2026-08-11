from __future__ import annotations

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "src"


def write_project(root: Path) -> Path:
    project = root / "Clients" / "API Client" / "Projects" / "Intake Project"
    admin = project / "00_Admin"
    source = project / "01_Client_Files" / "Original_Delivery"
    admin.mkdir(parents=True)
    source.mkdir(parents=True)
    manifest = {
        "metadata": {
            "schema": "mixing-project",
            "schema_version": "1.1.0",
            "document_id": "11111111-1111-1111-1111-111111111111",
            "created_with": "jl-mixing 1.4.0",
            "created_at": "2030-01-01T12:00:00Z",
            "last_modified_at": "2030-01-01T12:00:00Z",
        },
        "project_id": "intake-project",
        "project_name": "Intake Project",
        "audio": {"sample_rate": 48000, "bit_depth": 24},
    }
    (admin / "project-manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (admin / "Intake_Report.md").write_text(
        "# Intake Report\n\n<!-- BEGIN AUTOMATED SECTION -->\nold\n<!-- END AUTOMATED SECTION -->\n",
        encoding="utf-8",
    )
    return project


def run_cli(*args: str) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(SRC)
    return subprocess.run(
        [sys.executable, "-m", "jl_mixing.cli", *args],
        cwd=ROOT,
        env=env,
        text=True,
        capture_output=True,
        check=False,
    )


class IntakeApiTests(unittest.TestCase):
    def test_dry_run_is_structured_and_non_mutating(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = write_project(Path(tmp))
            source = project / "01_Client_Files" / "Original_Delivery"
            (source / "Notes.txt").write_text("notes\n", encoding="utf-8")
            report = project / "00_Admin" / "Intake_Report.md"
            before = report.read_bytes()
            proc = run_cli("intake", "validate", "--json", "--project", str(project), "--dry-run")
            self.assertEqual(proc.returncode, 0, proc.stderr)
            self.assertEqual(proc.stderr, "")
            payload = json.loads(proc.stdout)
            self.assertEqual(payload["operation"], "intake.validate")
            self.assertEqual(payload["status"], "planned")
            self.assertEqual(payload["data"]["project"]["id"], "intake-project")
            self.assertEqual(payload["data"]["summary"]["files_discovered"], 1)
            self.assertIn("Notes.txt", payload["data"]["report_markdown"])
            self.assertEqual(payload["data"]["would_update"], [str(report.resolve())])
            self.assertEqual(report.read_bytes(), before)

    def test_success_updates_only_managed_report_region(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = write_project(Path(tmp))
            source = project / "01_Client_Files" / "Original_Delivery"
            (source / "Notes.txt").write_text("notes\n", encoding="utf-8")
            report = project / "00_Admin" / "Intake_Report.md"
            proc = run_cli("intake", "validate", "--json", "--project", str(project))
            self.assertEqual(proc.returncode, 0, proc.stderr)
            payload = json.loads(proc.stdout)
            self.assertEqual(payload["status"], "success")
            persisted = report.read_text(encoding="utf-8")
            self.assertTrue(persisted.startswith("# Intake Report\n"))
            self.assertIn(payload["data"]["report_markdown"].rstrip(), persisted)
            self.assertEqual(payload["errors"], [])

    def test_empty_source_returns_blocked_contract_and_updates_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            project = write_project(Path(tmp))
            report = project / "00_Admin" / "Intake_Report.md"
            proc = run_cli("intake", "validate", "--json", "--project", str(project))
            self.assertEqual(proc.returncode, 5)
            payload = json.loads(proc.stdout)
            self.assertEqual(payload["status"], "blocked")
            self.assertEqual(payload["errors"][0]["code"], "INTAKE_BLOCKING_FINDINGS")
            self.assertIn("No files were found", report.read_text(encoding="utf-8"))

    def test_invalid_request_is_machine_json_with_argument_exit_code(self) -> None:
        proc = run_cli("intake", "validate", "--project", "/missing")
        self.assertEqual(proc.returncode, 2)
        self.assertEqual(proc.stderr, "")
        payload = json.loads(proc.stdout)
        self.assertEqual(payload["status"], "error")
        self.assertEqual(payload["errors"][0]["code"], "INVALID_REQUEST")
        self.assertEqual(payload["errors"][0]["details"]["exit_code"], 2)


if __name__ == "__main__":
    unittest.main()
