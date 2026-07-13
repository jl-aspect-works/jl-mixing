#!/usr/bin/env bash
# Batch 3 test orchestrator.
#
# The basic mode always verifies artifacts, syntax, and unit tests. Integration
# and semantic schema tests run when their dependencies are available; strict
# mode converts missing dependencies into a failure.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "Verifying Batch 3 repository artifacts..."

# Keep this list explicit so missing packaged artifacts fail immediately.
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
docs/BATCH_2_IMPLEMENTATION.md
docs/BATCH_3_IMPLEMENTATION.md
docs/CODE_DOCUMENTATION_PASS.md
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
packaging/requirements.txt
lib/common.sh
lib/platform.sh
lib/filesystem.sh
lib/json.sh
lib/metadata.sh
lib/config.sh
lib/context.sh
lib/naming.sh
lib/templates.sh
lib/validation.sh
lib/revision.sh
bin/new-studio
bin/new-client
bin/new-mix
bin/validate-intake
bin/new-revision
bin/approve-mix
bin/create-delivery
bin/complete-project
tools/build-intake-report.py'

# Verify the release-shaped repository contains every required contract and implementation file.
echo "$required" | while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ ! -f "$path" ]; then
        echo "Missing required artifact: $path" >&2
        exit 1
    fi
done

echo "[OK] Required artifacts"

# Syntax-check every JSON example, schema, and fixture before executing tests.
python3 - <<'PY'
import json
from pathlib import Path
# Parse syntax only here; Draft 2020-12 semantics are checked later when available.
for directory in ('schemas', 'examples', 'tests/fixtures'):
    for path in Path(directory).glob('*.json'):
        json.loads(path.read_text())
print('[OK] JSON syntax')
PY

# Parse every shell-identified file without executing it.
for path in install.sh uninstall.sh bin/* lib/*.sh tests/*.sh tests/unit/*.sh tests/integration/*.sh tools/*; do
    [ -f "$path" ] || continue
    first_line="$(sed -n '1p' "$path")"
    case "$path:$first_line" in
        *.sh:*|*:'#!'*'/sh'|*:'#!'*'/bash'|*:'#!'*'env sh'|*:'#!'*'env bash')
            bash -n "$path"
            ;;
    esac
done

echo "[OK] Shell syntax"

# Unit tests are dependency-light and always run.
for test_file in tests/unit/test-*.sh; do
    echo
    echo "Running $test_file"
    "$test_file"
done

# Prefer an explicit/private interpreter, then the repository venv, then system Python.
validator_python="${JL_MIXING_PYTHON:-}"
if [ -z "$validator_python" ] && [ -x "$ROOT/.venv/bin/python" ]; then
    validator_python="$ROOT/.venv/bin/python"
fi
if [ -z "$validator_python" ]; then
    validator_python="$(command -v python3 || true)"
fi

# Integration tests require jq plus jsonschema because commands validate every JSON write.
integration_available=1
command -v jq >/dev/null 2>&1 || integration_available=0
[ -n "$validator_python" ] || integration_available=0
# Run the full command lifecycle only when all runtime validation dependencies exist.
if [ "$integration_available" -eq 1 ]; then
    "$validator_python" -c 'import jsonschema' >/dev/null 2>&1 || integration_available=0
fi

if [ "$integration_available" -eq 1 ]; then
    export JL_MIXING_PYTHON="$validator_python"
    echo
    echo "Running command integration tests..."
    for test_file in tests/integration/test-*.sh; do
        echo
        echo "Running $test_file"
        "$test_file"
    done
    echo
    "$validator_python" tools/validate-json.py --strict
else
    if [ "${JL_TEST_STRICT:-0}" = "1" ]; then
        echo "[FAIL] Strict tests require jq, Python 3, and jsonschema." >&2
        exit 1
    fi
    echo
    echo "[SKIP] Integration and semantic schema tests require jq and jsonschema."
    python3 tools/validate-json.py
fi

echo
if [ "${JL_TEST_STRICT:-0}" = "1" ]; then
    echo "[OK] Batch 3 strict verification passed"
else
    echo "[OK] Batch 3 verification passed"
fi
