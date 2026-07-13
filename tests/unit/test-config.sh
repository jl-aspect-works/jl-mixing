#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/config.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/Studio" "$tmp/Clients/Acme"
cp "$ROOT/examples/studio.json" "$tmp/Studio/studio.json"
cp "$ROOT/examples/client.json" "$tmp/Clients/Acme/client.json"

assert_eq "$tmp/Studio/studio.json" "$(jl_config_file "$tmp")" "config path"
assert_success "valid studio root" jl_config_validate_root "$tmp"
assert_eq "Logic Pro" "$(jl_config_get "$tmp" '.default_daw')" "config value"
assert_eq "$tmp" "$(jl_config_find_root "$tmp/Clients/Acme")" "find studio root upward"
resolved="$(jl_resolve_value '' "$tmp/Clients/Acme/client.json" '.audio_defaults.sample_rate' "$tmp/Studio/studio.json" '.audio_defaults.sample_rate' 44100)"
assert_eq "48000" "$resolved" "client value wins resolution"
resolved="$(jl_resolve_value 96000 "$tmp/Clients/Acme/client.json" '.audio_defaults.sample_rate' "$tmp/Studio/studio.json" '.audio_defaults.sample_rate' 44100)"
assert_eq "96000" "$resolved" "explicit value wins resolution"
echo "[OK] config.sh ($TEST_COUNT assertions)"
