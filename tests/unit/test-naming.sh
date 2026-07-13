#!/usr/bin/env bash
set -eu

# Purpose: Verify stable slugs and filesystem-safe naming conventions.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
. "$ROOT/lib/naming.sh"

# Assert: verify observable behavior rather than internal implementation.
assert_eq "acme-records" "$(jl_slugify 'Acme Records')" "slugify name"
assert_eq "Acme Records" "$(jl_title_from_slug acme-records)" "title from slug"
assert_eq "Bad-Name" "$(jl_sanitize_component ' Bad/Name ')" "sanitize filename component"
assert_eq "Revision_03" "$(jl_revision_name 3)" "revision name"
assert_eq "Acme - Blue Sky" "$(jl_daw_project_name Acme 'Blue Sky')" "DAW project name"
assert_eq "Acme - Blue Sky - Main Mix.wav" "$(jl_deliverable_name Acme 'Blue Sky' 'Main Mix' wav)" "deliverable filename"
assert_eq "WORK Acme - Blue Sky - Car Test.wav" "$(jl_working_print_name 'WORK ' Acme 'Blue Sky' 'Car Test' wav)" "working print filename"
assert_eq "Acme - Blue Sky - Main Mix" "$(jl_expand_naming_pattern '{{ARTIST}} - {{PROJECT_NAME}} - {{DELIVERABLE}}' Acme 'Blue Sky' 'Main Mix')" "pattern expansion"
echo "[OK] naming.sh ($TEST_COUNT assertions)"
