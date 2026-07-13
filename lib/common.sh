#!/usr/bin/env bash
# Common helpers shared by every JL Mixing Automation command.
# Compatible with the Bash 3.2 version included with macOS.

if [ "${JL_MIXING_COMMON_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_COMMON_LOADED=1

# Standard JL Mixing Automation exit codes.
#
# These constants form part of the shared-library API and may be consumed by
# commands that source this file. ShellCheck analyzes common.sh independently.
# shellcheck disable=SC2034
readonly \
    JL_EXIT_GENERAL=1 \
    JL_EXIT_ARGUMENTS=2 \
    JL_EXIT_CONFIG=3 \
    JL_EXIT_CONTEXT=4 \
    JL_EXIT_VALIDATION=5 \
    JL_EXIT_UNSAFE=6

: "${JL_MIXING_LOG_LEVEL:=info}"

jl_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

jl_log_level_number() {
    local level
    case "$1" in
        debug) printf '%s\n' 10 ;;
        info)  printf '%s\n' 20 ;;
        warn)  printf '%s\n' 30 ;;
        error) printf '%s\n' 40 ;;
        *)     printf '%s\n' 20 ;;
    esac
}

jl_log() {
    local level configured requested label
    level="$1"
    shift

    configured="$(jl_log_level_number "$JL_MIXING_LOG_LEVEL")"
    requested="$(jl_log_level_number "$level")"
    [ "$requested" -ge "$configured" ] || return 0

    label="$(printf '%s' "$level" | tr '[:lower:]' '[:upper:]')"
    printf '[%s] %s\n' "$label" "$*" >&2
}

jl_debug() { jl_log debug "$@"; }
jl_info()  { jl_log info "$@"; }
jl_warn()  { jl_log warn "$@"; }
jl_error() { jl_log error "$@"; }

jl_die() {
    local message code
    message="$1"
    code="${2:-$JL_EXIT_GENERAL}"
    jl_error "$message"
    return "$code"
}

jl_require_command() {
    local command_name install_hint
    command_name="$1"
    install_hint="${2:-Install '$command_name' and try again.}"

    if ! jl_command_exists "$command_name"; then
        jl_error "Required command not found: $command_name"
        jl_error "$install_hint"
        return "$JL_EXIT_CONFIG"
    fi
}

jl_assert_nonempty() {
    local value label
    value="$1"
    label="${2:-value}"
    if [ -z "$value" ]; then
        jl_error "$label must not be empty."
        return "$JL_EXIT_ARGUMENTS"
    fi
}

jl_trim() {
    local value
    # sed is used instead of Bash extglob so this remains portable to Bash 3.2.
    printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

jl_is_truthy() {
    local value
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        1|true|yes|y|on) return 0 ;;
        *) return 1 ;;
    esac
}

jl_join_by() {
    local delimiter result separator item
    delimiter="$1"
    shift
    result=""
    separator=""
    for item in "$@"; do
        result="${result}${separator}${item}"
        separator="$delimiter"
    done
    printf '%s\n' "$result"
}

jl_now_iso8601() {
    # UTC is stable across macOS and Linux and satisfies ISO-8601 date-time.
    date -u '+%Y-%m-%dT%H:%M:%SZ'
}

jl_uuid() {
    if jl_command_exists uuidgen; then
        uuidgen | tr '[:upper:]' '[:lower:]'
        return 0
    fi

    if jl_command_exists python3; then
        python3 - <<'PY_UUID'
import uuid
print(uuid.uuid4())
PY_UUID
        return 0
    fi

    jl_error "Cannot generate a UUID: neither uuidgen nor python3 is available."
    return "$JL_EXIT_CONFIG"
}

jl_prompt() {
    local prompt_text default_value response
    prompt_text="$1"
    default_value="${2:-}"

    if [ -n "$default_value" ]; then
        printf '%s [%s]: ' "$prompt_text" "$default_value" >&2
    else
        printf '%s: ' "$prompt_text" >&2
    fi

    IFS= read -r response || response=""
    if [ -z "$response" ]; then
        response="$default_value"
    fi
    printf '%s\n' "$response"
}

jl_confirm() {
    local prompt_text default_answer suffix response
    prompt_text="$1"
    default_answer="${2:-no}"

    if [ "$default_answer" = "yes" ]; then
        suffix='[Y/n]'
    else
        suffix='[y/N]'
    fi

    printf '%s %s ' "$prompt_text" "$suffix" >&2
    IFS= read -r response || response=""
    response="$(printf '%s' "$response" | tr '[:upper:]' '[:lower:]')"

    if [ -z "$response" ]; then
        [ "$default_answer" = "yes" ]
        return
    fi

    case "$response" in
        y|yes) return 0 ;;
        *) return 1 ;;
    esac
}
