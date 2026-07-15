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
cp "$ROOT/tests/fixtures/legacy-v1.0.4/client.json" "$tmp/client.json"

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

# Exact v1.1 identity is intentionally stricter than the legacy major-version check.
jq '.metadata.schema_version = "1.1.0" | .metadata.created_with = "jl-mixing 1.1.7"' \
    "$tmp/client.json" > "$tmp/client-v11.json"
assert_success "exact schema identity accepted" \
    jl_json_require_exact_schema_identity "$tmp/client-v11.json" mixing-client 1.1.0
assert_failure "v1.0 exact schema rejected" \
    jl_json_require_exact_schema_identity "$tmp/client.json" mixing-client 1.1.0
assert_failure "different exact v1.1 version rejected" \
    jl_json_require_exact_schema_identity "$tmp/client-v11.json" mixing-client 1.1.1
assert_success "created_with patch release accepted" \
    jl_json_require_created_with_series "$tmp/client-v11.json" 1.1.0
jq '.metadata.created_with = "jl-mixing 1.2.0"' "$tmp/client-v11.json" > "$tmp/client-wrong-series.json"
assert_failure "created_with different series rejected" \
    jl_json_require_created_with_series "$tmp/client-wrong-series.json" 1.1.0
assert_eq "$ROOT/schemas/client.schema.json" \
    "$(jl_json_schema_path client.schema.json)" "local schema path resolved"
assert_failure "schema path traversal rejected" jl_json_schema_path '../client.schema.json'

mkdir -p "$tmp/studio/Studio" "$tmp/studio/Clients/Acme"
cp "$tmp/client-v11.json" "$tmp/studio/Clients/Acme/client.json"
jq '.metadata.schema = "mixing-studio" | .metadata.document_id = "11111111-1111-4111-8111-111111111111"' \
    "$tmp/client-v11.json" > "$tmp/studio/Studio/studio.json"
assert_success "unique studio document IDs accepted" \
    jl_json_validate_unique_document_ids "$tmp/studio"
assert_failure "existing document ID rejected" \
    jl_json_assert_document_id_available "$tmp/studio" 22222222-2222-4222-8222-222222222222
assert_success "new document ID accepted" \
    jl_json_assert_document_id_available "$tmp/studio" 99999999-9999-4999-8999-999999999999
mkdir -p "$tmp/studio/Clients/Acme/Projects/Blue Sky/00_Admin"
jq -n '{
  metadata: {document_id: "44444444-4444-4444-8444-444444444444"},
  revisions: [{revision_id: "55555555-5555-4555-8555-555555555555"}]
}' > "$tmp/studio/Clients/Acme/Projects/Blue Sky/00_Admin/project-manifest.json"
assert_failure "existing revision UUID rejected" \
    jl_json_assert_uuid_available "$tmp/studio" 55555555-5555-4555-8555-555555555555
cp "$tmp/studio/Clients/Acme/client.json" "$tmp/studio/Clients/Acme/duplicate.json"
mkdir -p "$tmp/studio/Clients/Other"
cp "$tmp/studio/Clients/Acme/client.json" "$tmp/studio/Clients/Other/client.json"
assert_failure "duplicate studio document IDs rejected" \
    jl_json_validate_unique_document_ids "$tmp/studio"
echo "[OK] json.sh ($TEST_COUNT assertions)"
