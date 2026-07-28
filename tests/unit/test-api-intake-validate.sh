#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command python3
require_test_command jq

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
studio="$tmp/Studio Root"
"$ROOT/bin/new-studio" --root "$studio" --name "API Intake Studio" --engineer "Jake" --no-default-cd >/dev/null
(cd "$studio" && "$ROOT/bin/new-client" api-client --name "API Client" --no-cd >/dev/null)
(cd "$studio" && "$ROOT/bin/new-mix" "Good Project" --client api-client --no-cd >/dev/null)
(cd "$studio" && "$ROOT/bin/new-mix" "Blocked Project" --client api-client --no-cd >/dev/null)

good="$studio/Clients/API Client/Projects/Good Project"
blocked="$studio/Clients/API Client/Projects/Blocked Project"
printf 'session notes\n' > "$good/01_Client_Files/Original_Delivery/Notes.txt"

report="$good/00_Admin/Intake_Report.md"
before="$(cksum "$report")"
planned="$tmp/planned.json"
"$ROOT/bin/jl-mixing" intake validate --json --project "$good" --dry-run >"$planned"
after="$(cksum "$report")"
assert_eq "$before" "$after" "intake.validate dry-run does not update report"
python3 - "$planned" "$good" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["operation"] == "intake.validate"
assert d["status"] == "planned"
assert d["data"]["project"]["path"] == sys.argv[2]
assert d["data"]["summary"]["files_discovered"] == 1
assert d["data"]["summary"]["blocking_errors"] == 0
assert d["data"]["would_update"] == [str(Path(sys.argv[2]) / "00_Admin" / "Intake_Report.md")]
PY
pass "intake.validate dry-run is structured and non-mutating"

success="$tmp/success.json"
"$ROOT/bin/jl-mixing" intake validate --json --project "$good" >"$success"
assert_contains "$(cat "$report")" "Notes.txt" "intake.validate updates managed report"
python3 - "$success" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "success"
assert d["errors"] == []
assert d["data"]["summary"]["files_discovered"] == 1
assert d["data"]["summary"]["blocking_errors"] == 0
assert d["data"]["summary"]["warnings"] >= 1
PY
pass "intake.validate returns structured success"

set +e
"$ROOT/bin/jl-mixing" intake validate --json --project "$blocked" >"$tmp/blocked.json" 2>"$tmp/blocked.err"
status=$?
set -e
assert_eq "5" "$status" "blocking intake findings preserve exit code"
assert_eq "" "$(cat "$tmp/blocked.err")" "completed blocked validation keeps stderr empty"
python3 - "$tmp/blocked.json" "$blocked" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "blocked"
assert d["data"]["project"]["path"] == sys.argv[2]
assert d["data"]["summary"]["blocking_errors"] == 1
assert d["errors"][0]["code"] == "INTAKE_BLOCKING_FINDINGS"
PY
pass "intake.validate returns structured blocked findings"

set +e
"$ROOT/bin/jl-mixing" intake validate --json --project "$tmp/missing" >"$tmp/error.json" 2>"$tmp/error.err"
status=$?
set -e
assert_eq "4" "$status" "missing project preserves context exit code"
assert_eq "" "$(cat "$tmp/error.err")" "API context failure keeps stderr empty"
python3 - "$tmp/error.json" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "error"
assert d["errors"][0]["code"] in {"PROJECT_NOT_FOUND", "WORKSPACE_CONTEXT_ERROR"}
PY
pass "intake.validate returns structured context error"

set +e
"$ROOT/bin/jl-mixing" intake validate --json --project "$good" --progress=json >"$tmp/progress.json" 2>"$tmp/progress.err"
status=$?
set -e
assert_eq "2" "$status" "unsupported progress mode is an argument error"
assert_eq "" "$(cat "$tmp/progress.err")" "progress preflight error keeps stderr empty"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    for document in "$planned" "$success" "$tmp/blocked.json" "$tmp/error.json" "$tmp/progress.json"; do
        assert_success "intake.validate response matches schema" python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/operations/intake-validate.schema.json" --document "$document"
    done
else
    echo "[SKIP] intake.validate schema validation requires jsonschema."
fi

echo "[OK] Automation API intake.validate ($TEST_COUNT assertions)"
