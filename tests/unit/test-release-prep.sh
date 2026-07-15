#!/usr/bin/env bash
set -eu

# Purpose: Prevent removed lifecycle/schema/template artifacts from returning.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"

assert_path_not_exists "$ROOT/bin/complete-project"
assert_path_not_exists "$ROOT/tests/integration/test-complete-project.sh"
assert_path_not_exists "$ROOT/schemas/legacy"
assert_path_not_exists "$ROOT/templates/project"
assert_path_not_exists "$ROOT/templates/delivery"
assert_path_not_exists "$ROOT/templates/revision"

commands="$(find "$ROOT/bin" -maxdepth 1 -type f -perm -111 -exec basename {} \; | LC_ALL=C sort)"
expected='approve-mix
create-delivery
jl-mixing-shell-integration
new-client
new-mix
new-revision
new-studio
validate-intake'
assert_eq "$expected" "$commands" "public runtime command set"

for file in "$ROOT/README.md" "$ROOT/packaging/RELEASE_README.md" \
    "$ROOT/docs/USER_GUIDE.md" "$ROOT/docs/SCRIPT_REFERENCE.md" \
    "$ROOT/docs/INSTALLATION_GUIDE.md"; do
    assert_failure "active documentation omits old workspace root: $(basename "$file")" \
        grep -q 'Music/JL Mixing' "$file"
done

assert_file_exists "$ROOT/CHANGELOG.md"
assert_file_exists "$ROOT/docs/RELEASE_NOTES_V1.1.md"
assert_contains "$(cat "$ROOT/docs/USER_GUIDE.md")" \
    'create-delivery --clean' "user guide documents destructive clean"
assert_contains "$(cat "$ROOT/README.md")" \
    'requires a newly created v1.1 workspace' "README documents fresh workspace"

echo "[OK] release preparation ($TEST_COUNT assertions)"
