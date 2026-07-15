#!/usr/bin/env bash
set -eu

# Purpose: Verify business rules not expressible solely through JSON Schema.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/validation.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT

# Assert: verify observable behavior rather than internal implementation.
assert_success "valid slug" jl_validate_slug acme-records
assert_failure "invalid slug" jl_validate_slug 'Acme Records'
assert_success "valid project name" jl_validate_project_name 'Blue Sky'
assert_failure "slash rejected in project name" jl_validate_project_name 'Blue/Sky'
assert_success "valid sample rate" jl_validate_sample_rate 48000
assert_failure "invalid sample rate" jl_validate_sample_rate 12345
assert_success "valid revision status" jl_validate_revision_status superseded
assert_success "valid project type" jl_validate_project_type podcast
cp "$ROOT/examples/project-manifest.json" "$tmp/project.json"
assert_success "single approved revision" jl_validate_single_approved_revision "$tmp/project.json"
entry='{"path":"Stems/","deliverable_type":"stems"}'
assert_success "folder delivery entry" jl_validate_delivery_entry "$entry"
entry='{"path":"Other.wav","deliverable_type":"other"}'
assert_failure "other delivery needs label" jl_validate_delivery_entry "$entry"
# Example is not delivered yet, so completion must fail.
assert_failure "undelivered project cannot complete" jl_validate_project_completable "$tmp/project.json"

assert_success "canonical folder name accepted" jl_validate_folder_name 'Blue Sky'
assert_failure "unsanitized folder name rejected" jl_validate_folder_name 'Blue/Sky'

mkdir -p "$tmp/studio/Clients/Acme" "$tmp/studio/Clients/Other"
cat > "$tmp/studio/Clients/Acme/client.json" <<'EOF_CLIENT'
{"metadata":{"document_id":"11111111-1111-4111-8111-111111111111"},"client_id":"acme"}
EOF_CLIENT
assert_failure "case-insensitive existing client ID rejected" \
    jl_validate_client_id_available "$tmp/studio" ACME
assert_success "new client ID accepted" jl_validate_client_id_available "$tmp/studio" other

mkdir -p "$tmp/studio/Clients/Acme/Projects/Blue Sky/00_Admin"
cat > "$tmp/studio/Clients/Acme/Projects/Blue Sky/00_Admin/project-manifest.json" <<'EOF_PROJECT'
{"metadata":{"document_id":"22222222-2222-4222-8222-222222222222"},"project_id":"blue-sky"}
EOF_PROJECT
assert_failure "case-insensitive existing project ID rejected" \
    jl_validate_project_id_available "$tmp/studio/Clients/Acme" BLUE-SKY
assert_success "new project ID accepted" \
    jl_validate_project_id_available "$tmp/studio/Clients/Acme" second-project
echo "[OK] validation.sh ($TEST_COUNT assertions)"
