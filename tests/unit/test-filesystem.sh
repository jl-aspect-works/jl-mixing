#!/usr/bin/env bash
set -eu

# Purpose: Verify safe creation, exact copy, atomic write, move, and immutability guards.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
. "$ROOT/tests/test-helper.sh"
. "$ROOT/lib/filesystem.sh"

# Arrange: build an isolated temporary fixture.
tmp="$(new_test_dir)"
trap 'rm -rf "$tmp"' EXIT

jl_fs_ensure_directory "$tmp/a/b"
# Assert: verify observable behavior rather than internal implementation.
assert_dir_exists "$tmp/a/b"
printf 'original' > "$tmp/source.txt"
jl_fs_copy_file_exact "$tmp/source.txt" "$tmp/copy.txt"
assert_file_exists "$tmp/copy.txt"
assert_success "exact copy bytes match" jl_fs_same_bytes "$tmp/source.txt" "$tmp/copy.txt"
assert_failure "copy refuses overwrite" jl_fs_copy_file_exact "$tmp/source.txt" "$tmp/copy.txt"
printf 'atomic' | jl_fs_atomic_write "$tmp/atomic.txt"
assert_eq "atomic" "$(cat "$tmp/atomic.txt")" "atomic write content"
immutable="$tmp/Project/01_Client_Files/Original_Delivery/file.wav"
assert_failure "immutable destination is rejected" jl_fs_assert_mutable_path "$immutable"
printf 'move' > "$tmp/move.txt"
jl_fs_safe_move "$tmp/move.txt" "$tmp/moved/file.txt"
assert_file_exists "$tmp/moved/file.txt"
mkdir "$tmp/empty"
assert_success "empty directory detected" jl_fs_directory_is_empty "$tmp/empty"
echo "[OK] filesystem.sh ($TEST_COUNT assertions)"
