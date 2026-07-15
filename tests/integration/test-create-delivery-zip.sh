#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"
require_test_command jq
require_test_command python3
if ! command -v zip >/dev/null 2>&1; then
    if [ "${JL_TEST_STRICT:-0}" = 1 ]; then fail 'zip is required for strict delivery ZIP tests'; fi
    echo '[SKIP] zip is not installed.'
    exit 0
fi
python3 -c 'import jsonschema' >/dev/null 2>&1 || { echo '[SKIP] create-delivery ZIP requires jsonschema.'; exit 0; }

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
studio_root="$tmp/studio"
project_root="$(fixture_v11_approved_project "$studio_root")"
revision="$project_root/04_Revisions/Revision_01"
delivery="$project_root/05_Final_Delivery"
dm="$delivery/delivery-manifest.json"
printf 'main\n' > "$revision/Blue Sky Main Mix.wav"
printf 'user attachment\n' > "$delivery/client-reference.pdf"
(cd "$project_root" && "$ROOT/bin/create-delivery" --zip >/dev/null)
assert_file_exists "$delivery/blue-sky-delivery.zip"
assert_eq '0' "$(jq '[.files[] | select(.path|endswith(".zip"))] | length' "$dm")" 'ZIP excluded from manifest'
if command -v unzip >/dev/null 2>&1; then
    assert_contains "$(unzip -l "$delivery/blue-sky-delivery.zip")" 'client-reference.pdf' 'ZIP preserves broad current-content behavior'
fi

echo "[OK] create-delivery ZIP ($TEST_COUNT assertions)"
