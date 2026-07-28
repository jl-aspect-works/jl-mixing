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
(cd "$api" && "$ROOT/bin/jl-mixing" project create "Parity Project" --json --client parity --artist "Parity Artist" --sample-rate 48000 --bit-depth 24 --file-format WAV --deliverables main_mix,stems >/dev/null)
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
echo "[OK] Automation API project.create parity ($TEST_COUNT assertions)"
