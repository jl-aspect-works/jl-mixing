#!/usr/bin/env bash
set -eu
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
. "$ROOT/lib/common.sh"

assert_eq "hello world" "$(jl_trim '  hello world  ')" "trim whitespace"
assert_success "truthy yes" jl_is_truthy yes
assert_failure "false is not truthy" jl_is_truthy false
assert_eq "a,b,c" "$(jl_join_by , a b c)" "join values"
assert_contains "$(jl_now_iso8601)" "T" "ISO timestamp contains T"
uuid="$(jl_uuid)"
assert_contains "$uuid" "-" "UUID is generated"
assert_failure "empty assertion fails" jl_assert_nonempty "" "test value"
echo "[OK] common.sh ($TEST_COUNT assertions)"
