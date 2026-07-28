#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command python3

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
studio="$tmp/Studio Root"
"$ROOT/bin/new-studio" --root "$studio" --name "Artist API Studio" --engineer "Jake" --no-default-cd >/dev/null
(cd "$studio" && "$ROOT/bin/new-client" api-client --name "API Client" --artist "Inherited Artist" --no-cd >/dev/null)

planned="$tmp/planned.json"
(cd "$studio" && "$ROOT/bin/jl-mixing" project create "Inherited Project" --json --client api-client --dry-run >"$planned")
python3 - "$planned" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "planned"
assert d["data"]["project"]["artist"] == "Inherited Artist"
PY
pass "project.create exposes inherited effective artist"

explicit="$tmp/explicit.json"
(cd "$studio" && "$ROOT/bin/jl-mixing" project create "Explicit Project" --json --client api-client --artist "Explicit Artist" --dry-run >"$explicit")
python3 - "$explicit" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
assert d["data"]["project"]["artist"] == "Explicit Artist"
PY
pass "project.create exposes explicit effective artist"

(cd "$studio" && "$ROOT/bin/new-mix" "Revision Description Project" --client api-client --artist "Inherited Artist" --no-cd >/dev/null)
project="$studio/Clients/API Client/Projects/Revision Description Project"
revision_explicit="$tmp/revision-explicit.json"
"$ROOT/bin/jl-mixing" revision create --json --project "$project" --description "Vocal lift" --dry-run >"$revision_explicit"
python3 - "$revision_explicit" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "planned"
assert d["data"]["revision"]["number"] == 2
assert d["data"]["revision"]["description"] == "Vocal lift"
PY
pass "revision.create exposes explicit effective description"

revision_default="$tmp/revision-default.json"
"$ROOT/bin/jl-mixing" revision create --json --project "$project" --dry-run >"$revision_default"
python3 - "$revision_default" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
assert d["status"] == "planned"
assert d["data"]["revision"]["number"] == 2
assert d["data"]["revision"]["description"] == "Revision 2"
PY
pass "revision.create exposes default effective description"

info="$tmp/system-info.json"
"$ROOT/bin/jl-mixing" system-info --json >"$info"
python3 - "$info" <<'PY'
import json, sys
from pathlib import Path
d = json.loads(Path(sys.argv[1]).read_text())
assert "project.create.artist" in d["capabilities"]
assert "revision.create.description" in d["capabilities"]
PY
pass "system-info advertises additive effective-value capabilities"
