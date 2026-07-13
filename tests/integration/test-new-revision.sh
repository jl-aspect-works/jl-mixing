#!/usr/bin/env bash
set -eu

# Purpose: Exercise revision folder/template creation and manifest state.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
project_root="$(fixture_project "$studio_root" fresh)"
manifest="$project_root/00_Admin/project-manifest.json"

(cd "$project_root" && "$ROOT/bin/new-revision" --description "Initial mix")
# Assert: verify observable behavior rather than internal implementation.
assert_dir_exists "$project_root/04_Revisions/Revision_01/Prints"
assert_file_exists "$project_root/04_Revisions/Revision_01/Revision_Notes.md"
assert_json_eq "1" "$manifest" '.state.current_revision' "current revision"
assert_json_eq "open" "$manifest" '.revisions[0].status' "new revision status"
assert_json_eq "Initial mix" "$manifest" '.revisions[0].description' "revision description"

printf '[OK] new-revision (%s assertions)\n' "$TEST_COUNT"
