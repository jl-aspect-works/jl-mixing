#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Verifying Batch 1 repository artifacts..."

required='README.md
VERSION
Makefile
docs/DESIGN_SPECIFICATION_V1.md
docs/USER_GUIDE.md
docs/SCRIPT_REFERENCE.md
docs/INSTALLATION_GUIDE.md
docs/DEVELOPER_GUIDE.md
docs/ARCHITECTURE_DECISIONS.md
docs/SCOPE_FREEZE_V1.md
schemas/studio.schema.json
schemas/client.schema.json
schemas/project-manifest.schema.json
schemas/delivery-manifest.schema.json
templates/studio/studio.json.template
templates/client/client.json.template
templates/project/project-manifest.json.template
templates/delivery/delivery-manifest.json.template
templates/project/Project_Notes.md
templates/project/Intake_Report.md
templates/project/Preparation_Report.md
templates/project/Delivery_Notes.md
templates/project/Recall_Sheet.md
templates/revision/Revision_Notes.md
packaging/requirements.txt'

echo "$required" | while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ ! -f "$path" ]; then
        echo "Missing required artifact: $path" >&2
        exit 1
    fi
done

python3 - <<'PY'
import json
from pathlib import Path
for directory in ('schemas','examples','tests/fixtures'):
    for path in Path(directory).glob('*.json'):
        json.loads(path.read_text())
print('[OK] JSON syntax')
PY

find bin tools tests -type f -print | while IFS= read -r path; do
    case "$path" in
        *.sh|bin/*|tools/check-dependencies|tools/shellcheck-all|tools/release-check) bash -n "$path" ;;
    esac
done

echo "[OK] Shell syntax"
python3 tools/validate-json.py
echo "[OK] Batch 1 artifact verification passed"
