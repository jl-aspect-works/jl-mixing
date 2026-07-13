#!/usr/bin/env bash
set -eu

# Purpose: Verify metadata creation, touch semantics, and creation-field preservation.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/metadata.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
metadata="$(jl_metadata_create mixing-client new-client 1.0.0 11111111-1111-4111-8111-111111111111 2026-07-13T12:00:00Z)"
# Assert: verify observable behavior rather than internal implementation.
assert_eq "mixing-client" "$(printf '%s' "$metadata" | jq -r '.schema')" "metadata schema"
assert_eq "jl-mixing 1.0.0" "$(printf '%s' "$metadata" | jq -r '.created_with')" "created_with version"
cp "$ROOT/examples/client.json" "$tmp/client.json"
jl_metadata_touch "$tmp/client.json" 2026-07-14T12:00:00Z
assert_eq "2026-07-14T12:00:00Z" "$(jl_json_get "$tmp/client.json" '.metadata.last_modified_at')" "metadata touch"
assert_success "metadata validation" jl_metadata_validate "$tmp/client.json" mixing-client
echo "[OK] metadata.sh ($TEST_COUNT assertions)"
