#!/usr/bin/env bash
set -eu

# Purpose: Exercise filtering, classification, checksums, manifest creation, and delivery recording.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/integration/integration-helper.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT
studio_root="$tmp/studio"
fixture_studio "$studio_root"
project_root="$(fixture_project "$studio_root" approved1)"
manifest="$project_root/00_Admin/project-manifest.json"
prints="$project_root/04_Revisions/Revision_01/Prints"
fixture_wav "$prints/Acme - Blue Sky - Main Mix.wav"
fixture_wav "$prints/WORK Acme - Blue Sky - Car Test.wav"

(cd "$project_root" && "$ROOT/bin/create-delivery" --checksum)
delivery_root="$project_root/05_Final_Delivery"
delivery_manifest="$delivery_root/delivery-manifest.json"
# Assert: verify observable behavior rather than internal implementation.
assert_file_exists "$delivery_root/Acme - Blue Sky - Main Mix.wav"
assert_path_not_exists "$delivery_root/WORK Acme - Blue Sky - Car Test.wav"
assert_file_exists "$delivery_manifest"
assert_json_eq "main_mix" "$delivery_manifest" '.files[0].deliverable_type' "deliverable classified"
assert_json_eq "sha256" "$delivery_manifest" '.files[0].checksum.algorithm' "checksum recorded"

(cd "$project_root" && "$ROOT/bin/create-delivery" --mark-delivered)
assert_json_eq "true" "$manifest" '.state.delivered' "project delivery state"
assert_json_eq "Jake" "$delivery_manifest" '.delivery.delivered_by' "delivery engineer"

printf '[OK] create-delivery (%s assertions)\n' "$TEST_COUNT"
