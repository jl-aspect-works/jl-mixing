#!/usr/bin/env bash
set -eu

# Purpose: Verify JSON reads, atomic mutations, identity checks, arrays, and schema validation.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/json.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
cp "$ROOT/examples/client.json" "$tmp/client.json"

# Assert: verify observable behavior rather than internal implementation.
assert_success "valid JSON detected" jl_json_is_valid "$tmp/client.json"
assert_eq "acme" "$(jl_json_get "$tmp/client.json" '.client_id')" "read JSON string"
jl_json_set_string "$tmp/client.json" '.client_name' 'Acme Updated'
assert_eq "Acme Updated" "$(jl_json_get "$tmp/client.json" '.client_name')" "atomic string update"
jl_json_set_value "$tmp/client.json" '.revision_defaults.included_revisions' '4'
assert_eq "4" "$(jl_json_get "$tmp/client.json" '.revision_defaults.included_revisions')" "atomic JSON value update"
assert_success "schema identity accepted" jl_json_require_schema_identity "$tmp/client.json" mixing-client 1
assert_failure "wrong schema rejected" jl_json_require_schema_identity "$tmp/client.json" mixing-project 1
assert_eq "1" "$(jl_json_schema_major "$tmp/client.json")" "schema major extracted"
echo "[OK] json.sh ($TEST_COUNT assertions)"
