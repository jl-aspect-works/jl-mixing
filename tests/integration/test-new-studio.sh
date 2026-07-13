#!/usr/bin/env bash
set -eu

# Purpose: Exercise workspace creation, defaults, and overwrite protection.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/JL Mixing"

"$ROOT/bin/new-studio" --root "$studio_root" --engineer Jake --non-interactive
# Assert: verify observable behavior rather than internal implementation.
assert_file_exists "$studio_root/Studio/studio.json"
assert_dir_exists "$studio_root/DAWs/Logic Pro/Mix Templates"
assert_json_eq "Logic Pro" "$studio_root/Studio/studio.json" '.default_daw' "Logic Pro default"
assert_json_eq "Jake" "$studio_root/Studio/studio.json" '.default_mix_engineer' "engineer default"
assert_failure "existing workspace is protected" "$ROOT/bin/new-studio" --root "$studio_root" --non-interactive

printf '[OK] new-studio (%s assertions)\n' "$TEST_COUNT"
