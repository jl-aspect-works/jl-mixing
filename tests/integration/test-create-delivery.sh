#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"
require_test_command jq
require_test_command python3
python3 -c 'import jsonschema' >/dev/null 2>&1 || { echo '[SKIP] create-delivery requires jsonschema.'; exit 0; }

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
studio_root="$tmp/studio"
project_root="$(fixture_v11_approved_project "$studio_root")"
manifest="$project_root/00_Admin/project-manifest.json"
revision="$project_root/04_Revisions/Revision_01"
printf 'main-data\n' > "$revision/Blue Sky Main Mix.wav"
printf 'custom-data\n' > "$revision/BlueSky_NoVox.wav"
printf 'stem-data\n' > "$revision/Blue Sky Stem Drums.wav"
printf 'working\n' > "$revision/WORK Blue Sky test.wav"

delivery="$project_root/05_Final_Delivery"
dm="$delivery/delivery-manifest.json"
# GitHub macOS runners may place a newer Bash ahead of Apple's /bin/bash in
# PATH. Exercise the public command with the system Bash on macOS so Bash 3.2
# compatibility regressions are caught by CI.
delivery_command=("$ROOT/bin/create-delivery")
if [ "$(uname -s)" = "Darwin" ] && [ -x /bin/bash ]; then
    delivery_command=(/bin/bash "$ROOT/bin/create-delivery")
fi
run_delivery() { (cd "$project_root" && "${delivery_command[@]}" "$@"); }

dry="$(run_delivery --dry-run)"
assert_contains "$dry" 'Blue Sky Main Mix.wav' 'dry-run lists main mix'
assert_contains "$dry" 'BlueSky_NoVox.wav' 'dry-run lists custom file'
assert_contains "$dry" 'unclassified' 'dry-run shows unclassified type'
assert_path_not_exists "$dm"

output="$(run_delivery)"
assert_file_exists "$delivery/Blue Sky Main Mix.wav"
assert_file_exists "$delivery/BlueSky_NoVox.wav"
assert_file_exists "$delivery/Stems/Blue Sky Stem Drums.wav"
assert_path_not_exists "$delivery/WORK Blue Sky test.wav"
assert_file_exists "$dm"
assert_json_eq '1' "$manifest" '.state.delivered_revision' 'delivered pointer updated'
assert_json_eq 'mixing-delivery' "$dm" '.metadata.schema' 'delivery schema identity'
assert_json_eq 'main_mix' "$dm" '.files[] | select(.path=="Blue Sky Main Mix.wav") | .deliverable_type' 'main mix classified'
assert_json_eq 'unclassified' "$dm" '.files[] | select(.path=="BlueSky_NoVox.wav") | .deliverable_type' 'custom name unclassified'
assert_json_eq 'stems' "$dm" '.files[] | select(.path=="Stems/Blue Sky Stem Drums.wav") | .deliverable_type' 'stem classified'
assert_eq '64' "$(jq -r '.files[0].sha256 | length' "$dm")" 'mandatory SHA-256 stored'
assert_contains "$output" 'Final delivery created successfully.' 'success heading'
assert_contains "$output" 'Transfer the contents' 'transfer guidance'

assert_failure 'removed revision option rejected' run_delivery --revision 1
assert_failure 'removed checksum option rejected' run_delivery --checksum
assert_failure 'removed mark option rejected' run_delivery --mark-delivered
assert_failure 'removed non-interactive option rejected' run_delivery --non-interactive
assert_failure 'overwrite and clean are exclusive' run_delivery --overwrite --clean

echo "[OK] create-delivery ($TEST_COUNT assertions)"
