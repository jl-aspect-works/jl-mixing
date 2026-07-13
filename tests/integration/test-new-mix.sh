#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
client_root="$(fixture_client "$studio_root")"
export JL_MIXING_ROOT="$studio_root"
mkdir -p "$tmp/source"
printf 'client source\n' > "$tmp/source/readme.txt"

(cd "$client_root" && "$ROOT/bin/new-mix" --project "Blue Sky" --source "$tmp/source" --non-interactive)
project_root="$client_root/Projects/Active/Blue Sky"
assert_file_exists "$project_root/00_Admin/project-manifest.json"
assert_dir_exists "$project_root/03_DAW_Project/Project"
assert_file_exists "$project_root/01_Client_Files/Original_Delivery/readme.txt"
assert_same_bytes "$client_root/client.json" "$project_root/00_Admin/client-profile-snapshot.json"
assert_json_eq "Blue Sky" "$project_root/00_Admin/project-manifest.json" '.project_name' "project name"
assert_json_eq "Logic Pro" "$project_root/00_Admin/project-manifest.json" '.daw.name' "project DAW"
"$ROOT/bin/new-mix" --client acme --project "Second Project" --non-interactive
assert_file_exists "$client_root/Projects/Active/Second Project/00_Admin/project-manifest.json"
assert_failure "duplicate project is protected" "$ROOT/bin/new-mix" --client acme --project "Blue Sky" --non-interactive

printf '[OK] new-mix (%s assertions)\n' "$TEST_COUNT"
