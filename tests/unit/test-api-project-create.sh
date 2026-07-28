#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command python3

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
studio="$tmp/Studio Root"
"$ROOT/bin/new-studio" --root "$studio" --name "API Test Studio" --engineer "Jake" --no-default-cd >/dev/null
(cd "$studio" && "$ROOT/bin/new-client" api-client --name "API Client" --artist "API Artist" --no-cd >/dev/null)

planned="$tmp/planned.json"
(cd "$studio" && "$ROOT/bin/jl-mixing" project create "API Project" --json --client api-client --dry-run >"$planned")
assert_path_not_exists "$studio/Clients/API Client/Projects/API Project"
python3 - "$planned" "$studio" <<'PY'
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

set +e
"$ROOT/bin/jl-mixing" project create >"$tmp/invalid.json" 2>"$tmp/invalid.err"
status=$?
set -e
assert_eq "2" "$status" "invalid project request preserves argument exit code"
assert_eq "" "$(cat "$tmp/invalid.err")" "API preflight failures keep stderr empty"
python3 - "$tmp/invalid.json" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "error"
assert d["errors"][0]["code"] == "INVALID_REQUEST"
PY
pass "project.create invalid request is structured"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    for document in "$planned" "$tmp/invalid.json"; do
        assert_success "project.create response matches schema" python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/operations/project-create.schema.json" --document "$document"
    done
else
    echo "[SKIP] project.create schema validation requires jsonschema."
fi

# revision.create planning uses an existing project and must not mutate it.
(cd "$studio" && "$ROOT/bin/new-mix" "Revision API Project" --client api-client --artist "API Artist" --no-cd >/dev/null)
project="$studio/Clients/API Client/Projects/Revision API Project"
revision_planned="$tmp/revision-planned.json"
"$ROOT/bin/jl-mixing" revision create --json --project "$project" --description "API revision" --dry-run >"$revision_planned"
assert_path_not_exists "$project/04_Revisions/Revision_02"
python3 - "$revision_planned" "$project" "$studio" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["api_version"] == "1.0"
assert d["operation"] == "revision.create"
assert d["status"] == "planned"
assert d["errors"] == [] and d["warnings"] == []
assert d["data"]["revision"]["number"] == 2
assert Path(d["data"]["project"]["path"]) == Path(sys.argv[2])
assert Path(d["data"]["workspace_path"]) == Path(sys.argv[3])
PY
pass "revision.create dry-run is structured and non-mutating"

set +e
"$ROOT/bin/jl-mixing" revision create --project "$project" >"$tmp/revision-invalid.json" 2>"$tmp/revision-invalid.err"
revision_status=$?
set -e
assert_eq "2" "$revision_status" "revision.create requires JSON mode"
assert_eq "" "$(cat "$tmp/revision-invalid.err")" "revision API preflight failures keep stderr empty"
python3 - "$tmp/revision-invalid.json" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "error"
assert d["errors"][0]["code"] == "INVALID_REQUEST"
PY
pass "revision.create invalid request is structured"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    for document in "$revision_planned" "$tmp/revision-invalid.json"; do
        assert_success "revision.create response matches schema" python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/operations/revision-create.schema.json" --document "$document"
    done
fi

echo "[OK] Automation API project/revision create ($TEST_COUNT assertions)"
