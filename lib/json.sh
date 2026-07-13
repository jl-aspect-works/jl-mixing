#!/usr/bin/env bash
# JSON syntax checks, reads, atomic jq updates, and schema validation.

if [ "${JL_MIXING_JSON_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_JSON_LOADED=1

JL_JSON_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JL_JSON_REPO_ROOT="$(cd "$JL_JSON_LIB_DIR/.." && pwd)"
# shellcheck source=lib/common.sh
. "$JL_JSON_LIB_DIR/common.sh"
# shellcheck source=lib/platform.sh
. "$JL_JSON_LIB_DIR/platform.sh"
# shellcheck source=lib/filesystem.sh
. "$JL_JSON_LIB_DIR/filesystem.sh"

jl_json_require_jq() {
    jl_require_command jq "Install jq before using JL Mixing Automation JSON features."
}

jl_json_is_valid() {
    local file
    file="$1"
    [ -f "$file" ] || return 1
    jl_json_require_jq || return $?
    jq empty "$file" >/dev/null 2>&1
}

jl_json_get() {
    local file filter
    file="$1"
    filter="$2"
    jl_json_require_jq || return $?
    jq -er "$filter" "$file"
}

jl_json_get_optional() {
    local file filter default_value value
    file="$1"
    filter="$2"
    default_value="${3:-}"
    jl_json_require_jq || return $?

    value="$(jq -er "$filter // empty" "$file" 2>/dev/null || true)"
    if [ -z "$value" ]; then
        printf '%s\n' "$default_value"
    else
        printf '%s\n' "$value"
    fi
}

jl_json_get_json() {
    local file filter
    file="$1"
    filter="$2"
    jl_json_require_jq || return $?
    jq -e "$filter" "$file"
}

jl_json_update() {
    local file filter temp_file
    file="$1"
    filter="$2"
    shift 2

    [ -f "$file" ] || {
        jl_error "JSON file not found: $file"
        return "$JL_EXIT_VALIDATION"
    }
    jl_json_require_jq || return $?
    jl_json_is_valid "$file" || {
        jl_error "Invalid JSON syntax: $file"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_assert_mutable_path "$file" || return $?

    temp_file="$(jl_mktemp_file_near "$file")" || return $?
    if ! jq "$@" "$filter" "$file" > "$temp_file"; then
        rm -f "$temp_file"
        jl_error "JSON update failed: $file"
        return "$JL_EXIT_VALIDATION"
    fi

    chmod "$(jl_stat_mode "$file")" "$temp_file"
    mv "$temp_file" "$file"
}

jl_json_set_string() {
    local file path_expression value
    file="$1"
    path_expression="$2"
    value="$3"
    jl_json_update "$file" "$path_expression = \$jl_value" --arg jl_value "$value"
}

jl_json_set_value() {
    local file path_expression json_value
    file="$1"
    path_expression="$2"
    json_value="$3"
    jl_json_update "$file" "$path_expression = \$jl_value" --argjson jl_value "$json_value"
}

jl_json_delete() {
    local file path_expression
    file="$1"
    path_expression="$2"
    jl_json_update "$file" "del($path_expression)"
}

jl_json_schema_major() {
    local file version
    file="$1"
    version="$(jl_json_get "$file" '.metadata.schema_version')" || return $?
    printf '%s\n' "$version" | cut -d. -f1
}

jl_json_require_schema_identity() {
    local file expected_schema expected_major actual_schema actual_major
    file="$1"
    expected_schema="$2"
    expected_major="${3:-1}"

    actual_schema="$(jl_json_get "$file" '.metadata.schema')" || return $?
    actual_major="$(jl_json_schema_major "$file")" || return $?

    if [ "$actual_schema" != "$expected_schema" ]; then
        jl_error "Unexpected schema '$actual_schema'; expected '$expected_schema'."
        return "$JL_EXIT_VALIDATION"
    fi
    if [ "$actual_major" != "$expected_major" ]; then
        jl_error "Unsupported schema major version '$actual_major'; expected '$expected_major'."
        return "$JL_EXIT_VALIDATION"
    fi
}

jl_json_validator_python() {
    if [ -n "${JL_MIXING_PYTHON:-}" ] && [ -x "$JL_MIXING_PYTHON" ]; then
        printf '%s\n' "$JL_MIXING_PYTHON"
    elif [ -x "$JL_JSON_REPO_ROOT/.venv/bin/python" ]; then
        printf '%s\n' "$JL_JSON_REPO_ROOT/.venv/bin/python"
    elif jl_command_exists python3; then
        command -v python3
    else
        return "$JL_EXIT_CONFIG"
    fi
}

jl_json_validate_schema() {
    local schema_file document_file python_command
    schema_file="$1"
    document_file="$2"
    python_command="$(jl_json_validator_python)" || {
        jl_error "Python 3 is required for JSON Schema validation."
        return "$JL_EXIT_CONFIG"
    }

    "$python_command" "$JL_JSON_REPO_ROOT/tools/validate-json.py" \
        --strict --schema "$schema_file" --document "$document_file"
}
