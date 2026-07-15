#!/usr/bin/env bash
# Build and verify the same release archive an end user will download.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"

require_test_command python3
require_test_command jq
python3 -c 'import jsonschema' >/dev/null 2>&1 || {
    if [ "${JL_TEST_STRICT:-0}" = "1" ]; then
        fail "Release tests require the jsonschema package."
    fi
    echo "[SKIP] Release tests require jsonschema."
    exit 0
}

temp_root="$(new_test_dir)"
trap 'rm -rf "$temp_root"' EXIT HUP INT TERM
"$ROOT/tools/build-release" --output-dir "$temp_root/dist" --platform test >/dev/null
archive="$(find "$temp_root/dist" -name '*.tar.gz' -type f | head -n 1)"
[ -n "$archive" ] || fail "release archive was not created"
pass "release archive created"
assert_file_exists "$archive.sha256"
assert_file_exists "$archive.inventory.txt"
assert_contains "$(cat "$archive.inventory.txt")" 'tools/project-state.py' \
    "project-state tool included in release archive"
assert_success "release archive verifies" "$ROOT/tools/verify-release-archive" "$archive"

echo "[OK] release package ($TEST_COUNT assertions)"
