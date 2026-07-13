#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/context.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
project="$tmp/Clients/Acme/Projects/Active/Blue Sky"
mkdir -p "$tmp/Studio" "$tmp/Clients/Acme" "$project/00_Admin" "$project/04_Revisions/Revision_01/Prints"
cp "$ROOT/examples/studio.json" "$tmp/Studio/studio.json"
cp "$ROOT/examples/client.json" "$tmp/Clients/Acme/client.json"
cp "$ROOT/examples/project-manifest.json" "$project/00_Admin/project-manifest.json"

assert_eq "$project" "$(jl_context_project_root "$project/04_Revisions/Revision_01/Prints")" "project context upward"
assert_eq "$tmp/Clients/Acme" "$(jl_context_client_root "$project/03_DAW_Project")" "client context upward"
assert_eq "$tmp" "$(jl_context_studio_root "$project")" "studio context upward"
assert_eq "$project" "$(jl_context_resolve_project "$project" /tmp)" "explicit project override"
assert_eq "1" "$(jl_context_current_revision_number "$project")" "current revision number"
assert_eq "$project/04_Revisions/Revision_01" "$(jl_context_current_revision_root "$project")" "current revision root"
echo "[OK] context.sh ($TEST_COUNT assertions)"
