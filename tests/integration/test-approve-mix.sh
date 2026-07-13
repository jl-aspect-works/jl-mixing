#!/usr/bin/env bash
set -eu

# Purpose: Exercise approval and automatic superseding of the prior approval.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
project_root="$(fixture_project "$studio_root" two-revisions)"
manifest="$project_root/00_Admin/project-manifest.json"

(cd "$project_root/04_Revisions/Revision_02" && "$ROOT/bin/approve-mix" --approved-by Client)
# Assert: verify observable behavior rather than internal implementation.
assert_json_eq "2" "$manifest" '.state.approved_revision' "approved revision"
assert_json_eq "superseded" "$manifest" '.revisions[] | select(.number==1) | .status' "prior approval superseded"
assert_json_eq "approved" "$manifest" '.revisions[] | select(.number==2) | .status' "selected revision approved"
assert_json_eq "Client" "$manifest" '.state.approved_by' "approver recorded"

printf '[OK] approve-mix (%s assertions)\n' "$TEST_COUNT"
