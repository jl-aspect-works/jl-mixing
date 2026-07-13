#!/usr/bin/env bash
set -eu

# Purpose: Exercise source inventory generation while preserving engineer notes.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
project_root="$(fixture_project "$studio_root" fresh)"
report="$project_root/00_Admin/Intake_Report.md"
fixture_wav "$project_root/01_Client_Files/Original_Delivery/Lead Vocal.wav"
python3 - "$report" <<'PY'
from pathlib import Path
import sys
# Seed user-authored text outside the managed section to prove preservation.
path = Path(sys.argv[1])
path.write_text(path.read_text().replace("Add manual observations here.", "Keep this engineer note."))
PY

(cd "$project_root/01_Client_Files" && "$ROOT/bin/validate-intake")
report_text="$(cat "$report")"
# Assert: verify observable behavior rather than internal implementation.
assert_contains "$report_text" "Keep this engineer note." "engineer notes are preserved"
assert_contains "$report_text" "Lead Vocal.wav" "source inventory is written"
assert_contains "$report_text" "Files discovered: 1" "file count is reported"

printf '[OK] validate-intake (%s assertions)\n' "$TEST_COUNT"
