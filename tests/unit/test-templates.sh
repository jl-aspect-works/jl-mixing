#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
. "$ROOT/lib/templates.sh"

tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
printf 'Hello {{NAME}} from {{PLACE}}\n' > "$tmp/template.txt"
jl_template_render "$tmp/template.txt" "$tmp/output.txt" NAME Jake PLACE Studio
assert_eq "Hello Jake from Studio" "$(cat "$tmp/output.txt")" "render literal tokens"
assert_failure "unresolved token rejected" jl_template_render "$tmp/template.txt" "$tmp/bad.txt" NAME Jake

printf '{"name":"{{NAME}}","pattern":"{{PROJECT_NAME}}"}\n' > "$tmp/template.json"
JL_TEMPLATE_ALLOW_UNRESOLVED=1 jl_template_render_json \
    "$tmp/template.json" "$tmp/output.json" NAME 'Jake "Mix"'
json_name="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' "$tmp/output.json")"
assert_eq 'Jake "Mix"' "$json_name" "JSON template escapes string values"
assert_contains "$(cat "$tmp/output.json")" '{{PROJECT_NAME}}' "intentional naming token preserved"
cat > "$tmp/report.md" <<'EOF'
# Report

Human notes stay here.

<!-- BEGIN AUTO -->
old
<!-- END AUTO -->

Footer stays here.
EOF
printf 'new managed content\n' > "$tmp/replacement.md"
jl_markdown_replace_managed_section "$tmp/report.md" '<!-- BEGIN AUTO -->' '<!-- END AUTO -->' "$tmp/replacement.md"
content="$(cat "$tmp/report.md")"
assert_contains "$content" "Human notes stay here." "human notes preserved"
assert_contains "$content" "new managed content" "managed section replaced"
assert_contains "$content" "Footer stays here." "footer preserved"
echo "[OK] templates.sh ($TEST_COUNT assertions)"
