#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
export JL_MIXING_ROOT="$studio_root"

(cd "$tmp" && "$ROOT/bin/new-client" acme --name "Acme Records" --artist "The Acmes" --non-interactive)
client_root="$studio_root/Clients/Acme Records"
assert_file_exists "$client_root/client.json"
assert_dir_exists "$client_root/Projects/Active"
assert_dir_exists "$client_root/Projects/Completed"
assert_json_eq "acme" "$client_root/client.json" '.client_id' "client ID"
assert_json_eq "The Acmes" "$client_root/client.json" '.artist_name' "artist default"
"$ROOT/bin/new-client" beta --name "Beta Audio" --non-interactive
assert_file_exists "$studio_root/Clients/Beta Audio/client.json"
assert_failure "duplicate client ID is protected" "$ROOT/bin/new-client" acme --name Other --non-interactive

printf '[OK] new-client (%s assertions)\n' "$TEST_COUNT"
