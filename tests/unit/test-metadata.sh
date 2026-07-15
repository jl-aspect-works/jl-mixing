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
expected_version="$(sed -n '1p' "$ROOT/VERSION")"
assert_eq "jl-mixing $expected_version" "$(printf '%s' "$metadata" | jq -r '.created_with')" "created_with version"
cp "$ROOT/examples/client.json" "$tmp/client.json"
jl_metadata_touch "$tmp/client.json" 2026-07-14T12:00:00Z
assert_eq "2026-07-14T12:00:00Z" "$(jl_json_get "$tmp/client.json" '.metadata.last_modified_at')" "metadata touch"
assert_success "metadata validation" jl_metadata_validate "$tmp/client.json" mixing-client

printf '1.1.4
' > "$tmp/VERSION-v11"
v11_mutable="$(JL_MIXING_VERSION_FILE="$tmp/VERSION-v11" \
    jl_metadata_create_v11_mutable mixing-project 1.1.0 \
    44444444-4444-4444-8444-444444444444 2026-07-14T12:00:00Z)"
assert_eq "false" "$(printf '%s' "$v11_mutable" | jq 'has("created_by")')" \
    "v1.1 mutable metadata omits created_by"
assert_eq "2026-07-14T12:00:00Z" \
    "$(printf '%s' "$v11_mutable" | jq -r '.last_modified_at')" \
    "v1.1 mutable metadata starts with matching modification time"
printf '{"metadata":%s}
' "$v11_mutable" > "$tmp/v11-mutable.json"
assert_success "v1.1 mutable metadata validates" \
    jl_metadata_validate_v11 "$tmp/v11-mutable.json" mixing-project mutable

v11_immutable="$(JL_MIXING_VERSION_FILE="$tmp/VERSION-v11" \
    jl_metadata_create_v11_immutable mixing-delivery 1.1.0 \
    66666666-6666-4666-8666-666666666666 2026-07-14T13:00:00Z)"
assert_eq "false" "$(printf '%s' "$v11_immutable" | jq 'has("last_modified_at")')" \
    "v1.1 immutable metadata omits last_modified_at"
printf '{"metadata":%s}
' "$v11_immutable" > "$tmp/v11-immutable.json"
assert_success "v1.1 immutable metadata validates" \
    jl_metadata_validate_v11 "$tmp/v11-immutable.json" mixing-delivery immutable
echo "[OK] metadata.sh ($TEST_COUNT assertions)"
