#!/usr/bin/env bash
set -eu

# Purpose: Verify revision numbering, append behavior, approval, and superseding.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/revision.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
cp "$ROOT/examples/project-manifest.json" "$tmp/project.json"

# Assert: verify observable behavior rather than internal implementation.
assert_eq "2" "$(jl_revision_next_number "$tmp/project.json")" "next revision number"
record="$(jl_revision_create_record 2 'Vocal changes' 66666666-6666-4666-8666-666666666666 2026-07-19T12:00:00Z)"
assert_eq "open" "$(printf '%s' "$record" | jq -r '.status')" "new record status"
assert_eq "04_Revisions/Revision_02" "$(printf '%s' "$record" | jq -r '.folder')" "new record folder"
jl_revision_append "$tmp/project.json" 'Vocal changes' 2 2026-07-19T12:00:00Z 66666666-6666-4666-8666-666666666666
assert_eq "2" "$(jl_revision_current "$tmp/project.json")" "append updates current revision"
assert_eq "open" "$(jl_revision_status "$tmp/project.json" 2)" "appended revision is open"
jl_revision_approve "$tmp/project.json" 2 Client 2026-07-20T12:00:00Z
assert_eq "approved" "$(jl_revision_status "$tmp/project.json" 2)" "selected revision approved"
assert_eq "superseded" "$(jl_revision_status "$tmp/project.json" 1)" "prior approval superseded"
assert_eq "2" "$(jl_json_get "$tmp/project.json" '.state.approved_revision')" "approved revision state"
echo "[OK] revision.sh ($TEST_COUNT assertions)"
