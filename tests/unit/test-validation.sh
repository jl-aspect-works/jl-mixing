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
echo "[OK] validation.sh ($TEST_COUNT assertions)"
