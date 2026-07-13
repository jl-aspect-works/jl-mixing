#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
project_root="$(fixture_project "$studio_root" delivered1)"
destination="$studio_root/Clients/Acme/Projects/Completed/Blue Sky"

(cd "$project_root" && "$ROOT/bin/complete-project")
assert_path_not_exists "$project_root"
assert_dir_exists "$destination"
assert_json_eq "completed" "$destination/00_Admin/project-manifest.json" '.state.status' "completed status"
assert_success "completion timestamp recorded" jq -e '.state.completed_at != null' "$destination/00_Admin/project-manifest.json"

printf '[OK] complete-project (%s assertions)\n' "$TEST_COUNT"
