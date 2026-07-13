#!/usr/bin/env bash
set -eu

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_COUNT=0

fail() {
    echo "[FAIL] $*" >&2
    exit 1
}

pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
    echo "[PASS] $*"
}

assert_eq() {
    expected="$1"
    actual="$2"
    message="$3"
    [ "$expected" = "$actual" ] || fail "$message: expected '$expected', got '$actual'"
    pass "$message"
}

assert_file_exists() {
    [ -f "$1" ] || fail "Expected file: $1"
    pass "file exists: $1"
}

assert_dir_exists() {
    [ -d "$1" ] || fail "Expected directory: $1"
    pass "directory exists: $1"
}

assert_contains() {
    haystack="$1"
    needle="$2"
    message="$3"
    case "$haystack" in
        *"$needle"*) pass "$message" ;;
        *) fail "$message: '$needle' not found" ;;
    esac
}

assert_success() {
    message="$1"
    shift
    "$@" >/dev/null 2>&1 || fail "$message"
    pass "$message"
}

assert_failure() {
    message="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        fail "$message"
    fi
    pass "$message"
}

require_test_command() {
    command_name="$1"
    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    fi
    if [ "${JL_TEST_STRICT:-0}" = "1" ]; then
        fail "Required strict-test command is missing: $command_name"
    fi
    echo "[SKIP] $command_name-dependent tests: command is not installed."
    exit 0
}

new_test_dir() {
    local temp_dir
    temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/jl-mixing-test.XXXXXX")" || return $?
    (cd "$temp_dir" && pwd -P)
}
