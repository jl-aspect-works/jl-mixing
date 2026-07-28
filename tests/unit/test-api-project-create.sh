#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command python3

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

# Exercise planning in an isolated workspace so its intentionally expensive
# validation path cannot affect the subsequent committed-create fixture.
planned_studio="$tmp/Planned Studio Root"
"$ROOT/bin/new-studio" --root "$planned_studio" --name "API Planned Studio" --engineer "Jake" --no-default-cd >/dev/null
(cd "$planned_studio" && "$ROOT/bin/new-client" api-client --name "API Client" --artist "API Artist" --no-cd >/dev/null)

planned="$tmp/planned.json"
(cd "$planned_studio" && "$ROOT/bin/jl-mixing" project create "API Project" --json --client api-client --dry-run >"$planned")
assert_path_not_exists "$planned_studio/Clients/API Client/Projects/API Project"
python3 - "$planned" "$planned_studio" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["api_version"] == "1.0"
assert d["operation"] == "project.create"
assert d["status"] == "planned"
assert d["errors"] == [] and d["warnings"] == []
assert d["data"]["project"]["name"] == "API Project"
assert Path(d["data"]["workspace_path"]) == Path(sys.argv[2])
assert d["data"]["initial_revision_path"].endswith("Revision_01")
PY
pass "project.create dry-run is structured and non-mutating"

studio="$tmp/Studio Root"
"$ROOT/bin/new-studio" --root "$studio" --name "API Test Studio" --engineer "Jake" --no-default-cd >/dev/null
(cd "$studio" && "$ROOT/bin/new-client" api-client --name "API Client" --artist "API Artist" --no-cd >/dev/null)

success="$tmp/success.json"
(cd "$studio" && "$ROOT/bin/jl-mixing" project create "API Project" --json --client api-client --artist "Project Artist" >"$success")
manifest="$studio/Clients/API Client/Projects/API Project/00_Admin/project-manifest.json"
assert_file_exists "$manifest"
python3 - "$success" "$manifest" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text()); m=json.loads(Path(sys.argv[2]).read_text())
assert d["status"] == "success"
assert d["data"]["project"]["id"] == m["project_id"]
assert d["data"]["project"]["name"] == m["project_name"] == "API Project"
assert m["artist"] == "Project Artist"
assert Path(d["data"]["manifest_path"]) == Path(sys.argv[2])
assert Path(d["data"]["initial_revision_path"]).name == "Revision_01"
PY
pass "project.create commits authoritative project state"

set +e
(cd "$studio" && "$ROOT/bin/jl-mixing" project create "API Project" --json --client api-client >"$tmp/duplicate.json" 2>"$tmp/duplicate.err")
status=$?
set -e
assert_eq "5" "$status" "duplicate project preserves validation exit code"
assert_eq "" "$(cat "$tmp/duplicate.err")" "API failures keep stderr empty"
python3 - "$tmp/duplicate.json" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "blocked"
assert d["errors"][0]["code"] == "PROJECT_ALREADY_EXISTS"
PY
pass "duplicate project returns stable machine error"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    for document in "$planned" "$success" "$tmp/duplicate.json"; do
        assert_success "project.create response matches schema" python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/operations/project-create.schema.json" --document "$document"
    done
else
    echo "[SKIP] project.create schema validation requires jsonschema."
fi

echo "[OK] Automation API project.create ($TEST_COUNT assertions)"
