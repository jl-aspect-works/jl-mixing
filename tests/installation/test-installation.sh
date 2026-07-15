#!/usr/bin/env bash
# Verify install, installed command execution, upgrade, and uninstall behavior.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"

require_test_command python3
require_test_command jq
python3 -c 'import jsonschema' >/dev/null 2>&1 || {
    if [ "${JL_TEST_STRICT:-0}" = "1" ]; then
        fail "Installation tests require the jsonschema package."
    fi
    echo "[SKIP] Installation tests require jsonschema."
    exit 0
}

temp_root="$(new_test_dir)"
trap 'rm -rf "$temp_root"' EXIT HUP INT TERM
prefix="$temp_root/prefix"
workspace="$temp_root/workspace"

JL_MIXING_TEST_SYSTEM_SITE_PACKAGES=1 "$ROOT/install.sh" --prefix "$prefix" >/dev/null
assert_file_exists "$prefix/share/jl-mixing/VERSION"
assert_file_exists "$prefix/share/jl-mixing/.venv/bin/python"
assert_file_exists "$prefix/bin/new-studio"
assert_file_exists "$prefix/share/jl-mixing/tools/project-state.py"
assert_file_exists "$prefix/share/jl-mixing/schemas/client-profile-snapshot.schema.json"
assert_file_exists "$prefix/share/jl-mixing/templates/Intake_Report.md"
assert_file_exists "$prefix/share/jl-mixing/templates/Revision_Notes.md"
assert_success "installed help works" "$prefix/bin/new-studio" --help

PATH="$prefix/bin:$PATH" new-studio --root "$workspace" >/dev/null
assert_file_exists "$workspace/Studio/studio.json"
assert_json_eq "1.1.0" "$workspace/Studio/studio.json" \
    '.metadata.schema_version' "installed new-studio creates v1.1 schema"
assert_path_not_exists "$workspace/DAWs"

# A sentinel in the application directory must disappear during upgrade, while
# the independent studio workspace remains untouched.
printf 'old application file\n' > "$prefix/share/jl-mixing/obsolete-sentinel"
JL_MIXING_TEST_SYSTEM_SITE_PACKAGES=1 "$ROOT/install.sh" --prefix "$prefix" >/dev/null
assert_path_not_exists "$prefix/share/jl-mixing/obsolete-sentinel"
assert_file_exists "$workspace/Studio/studio.json"

"$prefix/bin/jl-mixing-uninstall" >/dev/null
assert_path_not_exists "$prefix/share/jl-mixing"
assert_path_not_exists "$prefix/bin/new-studio"
assert_file_exists "$workspace/Studio/studio.json"

echo "[OK] installation lifecycle ($TEST_COUNT assertions)"
