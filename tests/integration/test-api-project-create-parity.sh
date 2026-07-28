#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
human="$tmp/Human Studio"
api="$tmp/API Studio"
"$ROOT/bin/new-studio" --root "$human" --name Human --engineer Jake --no-default-cd >/dev/null
"$ROOT/bin/new-studio" --root "$api" --name API --engineer Jake --no-default-cd >/dev/null
(cd "$human" && "$ROOT/bin/new-client" parity --name "Parity Client" --artist "Parity Artist" --no-cd >/dev/null)
(cd "$api" && "$ROOT/bin/new-client" parity --name "Parity Client" --artist "Parity Artist" --no-cd >/dev/null)
(cd "$human" && "$ROOT/bin/new-mix" "Parity Project" --client parity --artist "Parity Artist" --sample-rate 48000 --bit-depth 24 --file-format WAV --deliverables main_mix,stems --no-cd >/dev/null)
api_response="$tmp/project-create-success.json"
(cd "$api" && "$ROOT/bin/jl-mixing" project create "Parity Project" --json --client parity --artist "Parity Artist" --sample-rate 48000 --bit-depth 24 --file-format WAV --deliverables main_mix,stems >"$api_response")
python3 - "$human/Clients/Parity Client/Projects/Parity Project/00_Admin/project-manifest.json" "$api/Clients/Parity Client/Projects/Parity Project/00_Admin/project-manifest.json" "$human/Clients/Parity Client/Projects/Parity Project/00_Admin/client-profile-snapshot.json" "$api/Clients/Parity Client/Projects/Parity Project/00_Admin/client-profile-snapshot.json" <<'PY'
import json, sys
from pathlib import Path
pairs=[(sys.argv[1],sys.argv[2]),(sys.argv[3],sys.argv[4])]
for left,right in pairs:
    a=json.loads(Path(left).read_text()); b=json.loads(Path(right).read_text())
    for d in (a,b):
        metadata=d.get("metadata", {})
        metadata.pop("document_id", None); metadata.pop("created_at", None); metadata.pop("last_modified_at", None)
        for rev in d.get("revisions", []):
            rev.pop("revision_id", None); rev.pop("created_at", None)
    assert a == b, (a,b)
PY
pass "API and human commands create equivalent project state"

python3 - "$api_response" <<'PY'
import json, sys
from pathlib import Path
d=json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "success"
assert d["operation"] == "project.create"
assert d["errors"] == []
assert Path(d["data"]["manifest_path"]).is_file()
assert Path(d["data"]["client_snapshot_path"]).is_file()
assert Path(d["data"]["initial_revision_path"]).is_dir()
PY
pass "project.create success response points to committed state"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    assert_success "project.create success matches schema" python3 "$ROOT/tools/validate-json.py" --strict \
        --schema "$ROOT/api/schemas/v1.0/operations/project-create.schema.json" --document "$api_response"
fi

echo "[OK] Automation API project.create parity ($TEST_COUNT assertions)"
