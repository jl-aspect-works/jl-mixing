#!/usr/bin/env bash
set -eu

# Purpose: Verify upward context discovery and explicit project resolution.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
require_test_command jq
. "$ROOT/lib/context.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
project="$tmp/Clients/Acme/Projects/Active/Blue Sky"
mkdir -p "$tmp/Studio" "$tmp/Clients/Acme" "$project/00_Admin" "$project/04_Revisions/Revision_01/Prints"
cp "$ROOT/examples/studio.json" "$tmp/Studio/studio.json"
cp "$ROOT/examples/client.json" "$tmp/Clients/Acme/client.json"
cp "$ROOT/examples/project-manifest.json" "$project/00_Admin/project-manifest.json"

# Assert: verify observable behavior rather than internal implementation.
assert_eq "$project" "$(jl_context_project_root "$project/04_Revisions/Revision_01/Prints")" "project context upward"
assert_eq "$tmp/Clients/Acme" "$(jl_context_client_root "$project/03_DAW_Project")" "client context upward"
assert_eq "$tmp" "$(jl_context_studio_root "$project")" "studio context upward"
assert_eq "$project" "$(jl_context_resolve_project "$project" /tmp)" "explicit project override"
assert_eq "1" "$(jl_context_current_revision_number "$project")" "current revision number"
assert_eq "$project/04_Revisions/Revision_01" "$(jl_context_current_revision_root "$project")" "current revision root"
assert_failure "legacy v1.0 layout rejected" jl_context_reject_legacy_layout "$tmp"

v11="$tmp/v11"
v11_project="$v11/Clients/Acme Records/Projects/Blue Sky"
mkdir -p "$v11/Studio" "$v11_project/00_Admin" \
    "$v11_project/04_Revisions/Revision_01/sub" "$v11_project/05_Final_Delivery"
cat > "$v11/Studio/studio.json" <<'EOF_STUDIO'
{
  "metadata": {
    "schema": "mixing-studio",
    "schema_version": "1.1.0",
    "document_id": "11111111-1111-4111-8111-111111111111",
    "created_with": "jl-mixing 1.1.3",
    "created_at": "2026-07-14T20:00:00Z",
    "last_modified_at": "2026-07-14T20:00:00Z"
  }
}
EOF_STUDIO
cat > "$v11/Clients/Acme Records/client.json" <<'EOF_CLIENT'
{
  "metadata": {
    "schema": "mixing-client",
    "schema_version": "1.1.0",
    "document_id": "22222222-2222-4222-8222-222222222222",
    "created_with": "jl-mixing 1.1.3",
    "created_at": "2026-07-14T20:00:00Z",
    "last_modified_at": "2026-07-14T20:00:00Z"
  },
  "client_id": "acme"
}
EOF_CLIENT
cat > "$v11_project/00_Admin/project-manifest.json" <<'EOF_PROJECT'
{
  "metadata": {
    "schema": "mixing-project",
    "schema_version": "1.1.0",
    "document_id": "44444444-4444-4444-8444-444444444444",
    "created_with": "jl-mixing 1.1.3",
    "created_at": "2026-07-14T20:00:00Z",
    "last_modified_at": "2026-07-14T20:00:00Z"
  },
  "state": {"current_revision": 1, "approved_revision": null, "delivered_revision": null},
  "revisions": []
}
EOF_PROJECT
assert_success "v1.1 workspace accepted" jl_context_require_v11_workspace "$v11"
assert_eq "$v11" \
    "$(jl_context_studio_root_v11 "$v11_project/04_Revisions/Revision_01/sub")" \
    "v1.1 studio marker discovery"
assert_eq "$v11/Clients/Acme Records" \
    "$(jl_context_client_root_v11 "$v11_project/04_Revisions/Revision_01/sub")" \
    "v1.1 client marker discovery"
assert_eq "$v11/Clients/Acme Records" \
    "$(jl_context_resolve_client_v11 "$v11/Clients/Acme Records" /tmp)" \
    "explicit v1.1 client resolution"
assert_eq "$v11_project" \
    "$(jl_context_project_root_v11 "$v11_project/04_Revisions/Revision_01/sub")" \
    "v1.1 project marker discovery"
assert_eq "$v11_project/04_Revisions/Revision_01" \
    "$(jl_context_revision_root_v11 "$v11_project/04_Revisions/Revision_01/sub")" \
    "v1.1 revision boundary discovery"
assert_eq "$v11_project/04_Revisions/Revision_01" \
    "$(jl_context_revision_root_for_number "$v11_project" 1)" \
    "v1.1 numbered revision path"
assert_eq "$v11_project/05_Final_Delivery" \
    "$(jl_context_delivery_root_v11 "$v11_project")" \
    "v1.1 delivery boundary"
echo "[OK] context.sh ($TEST_COUNT assertions)"
