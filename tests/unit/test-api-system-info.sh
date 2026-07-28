#!/usr/bin/env bash
set -eu

# Verify the stable, machine-readable Automation API discovery contract.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command python3

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
stdout_file="$tmp/system-info.json"
stderr_file="$tmp/system-info.stderr"

"$ROOT/bin/jl-mixing" system-info --json >"$stdout_file" 2>"$stderr_file"
assert_eq "" "$(cat "$stderr_file")" "system-info keeps stderr empty"

python3 - "$stdout_file" "$ROOT" <<'PY_ASSERT'
import json
from pathlib import Path
import sys

document_path = Path(sys.argv[1])
root = Path(sys.argv[2]).resolve()
document = json.loads(document_path.read_text(encoding="utf-8"))
api_version = (root / "API_VERSION").read_text(encoding="utf-8").strip()
application_version = (root / "VERSION").read_text(encoding="utf-8").strip()
assert document["api_version"] == api_version
assert document["application"] == {
    "name": "jl-mixing",
    "version": application_version,
}
assert document["metadata"] == {
    "readable_schema_versions": ["1.1.0"],
    "writable_schema_version": "1.1.0",
}
assert document["capabilities"] == ["client.create", "delivery.create", "intake.validate", "project.create", "revision.approve", "revision.create", "system.info"]
assert Path(document["schemas"]["installed_path"]).resolve() == (
    root / "api" / "schemas" / f"v{api_version}"
).resolve()
assert document["schemas"]["public_base_url"] == (
    f"https://jlaudio.github.io/jl-mixing/api/v{api_version}/schemas/"
)
PY_ASSERT
pass "system-info reports independent API, application, and metadata versions"

if python3 -c 'import jsonschema' >/dev/null 2>&1; then
    assert_success "system-info JSON matches its published schema" \
        python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/system-info.schema.json" \
            --document "$stdout_file"

    compatible_file="$tmp/system-info-compatible.json"
    python3 - "$stdout_file" "$compatible_file" <<'PY_COMPATIBLE'
import json
from pathlib import Path
import sys

source, destination = map(Path, sys.argv[1:])
document = json.loads(source.read_text(encoding="utf-8"))
document["future_optional_field"] = {"enabled": True}
document["application"]["future_build_metadata"] = "example"
document["metadata"]["future_optional_schema_policy"] = "additive"
document["schemas"]["future_optional_format"] = "json-schema"
destination.write_text(json.dumps(document) + "\n", encoding="utf-8")
PY_COMPATIBLE
    assert_success "API 1.0 schema accepts additive optional fields" \
        python3 "$ROOT/tools/validate-json.py" --strict \
            --schema "$ROOT/api/schemas/v1.0/system-info.schema.json" \
            --document "$compatible_file"
else
    echo "[SKIP] system-info schema validation requires jsonschema."
fi

assert_failure "system-info requires JSON mode" \
    "$ROOT/bin/jl-mixing" system-info
assert_failure "system-info rejects extra arguments" \
    "$ROOT/bin/jl-mixing" system-info --json extra
assert_failure "unknown API command is rejected" \
    "$ROOT/bin/jl-mixing" unknown --json

printf '1\n' > "$tmp/API_VERSION-invalid"
assert_failure "malformed API version is rejected" \
    env JL_MIXING_API_VERSION_FILE="$tmp/API_VERSION-invalid" \
        "$ROOT/bin/jl-mixing" system-info --json

printf '9.8\n' > "$tmp/API_VERSION-missing-schema"
assert_failure "API version without installed schemas is rejected" \
    env JL_MIXING_API_VERSION_FILE="$tmp/API_VERSION-missing-schema" \
        "$ROOT/bin/jl-mixing" system-info --json

echo "[OK] Automation API system-info ($TEST_COUNT assertions)"
