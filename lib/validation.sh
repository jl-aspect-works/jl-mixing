#!/usr/bin/env bash
# Business-rule validation independent of JSON Schema.

if [ "${JL_MIXING_VALIDATION_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_VALIDATION_LOADED=1

JL_VALIDATION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_VALIDATION_LIB_DIR/common.sh"
# shellcheck source=lib/json.sh
. "$JL_VALIDATION_LIB_DIR/json.sh"

jl_validate_slug() {
    local value
    value="$1"
    case "$value" in
        ''|*[!a-z0-9-]*|-*|*-) return "$JL_EXIT_VALIDATION" ;;
    esac
    case "$value" in
        *--*) return "$JL_EXIT_VALIDATION" ;;
    esac
    return 0
}

jl_validate_project_name() {
    local value
    value="$(jl_trim "$1")"
    [ -n "$value" ] || return "$JL_EXIT_VALIDATION"
    case "$value" in
        *'/'*|*':'*) return "$JL_EXIT_VALIDATION" ;;
    esac
    return 0
}

jl_validate_enum() {
    local value allowed
    value="$1"
    shift
    for allowed in "$@"; do
        [ "$value" = "$allowed" ] && return 0
    done
    return "$JL_EXIT_VALIDATION"
}

jl_validate_sample_rate() {
    jl_validate_enum "$1" 44100 48000 88200 96000 176400 192000
}

jl_validate_bit_depth() {
    jl_validate_enum "$1" 16 24 32
}

jl_validate_file_format() {
    jl_validate_enum "$1" WAV AIFF
}

jl_validate_project_type() {
    jl_validate_enum "$1" mixing podcast audiobook dialogue_edit live_recording other
}

jl_validate_revision_status() {
    jl_validate_enum "$1" open approved superseded
}

jl_validate_single_approved_revision() {
    local manifest count
    manifest="$1"
    count="$(jq '[.revisions[] | select(.status == "approved")] | length' "$manifest")" || return $?
    [ "$count" -le 1 ] || {
        jl_error "Project contains more than one approved revision."
        return "$JL_EXIT_VALIDATION"
    }
}

jl_validate_project_completable() {
    local manifest status approved delivered
    manifest="$1"
    jl_json_require_schema_identity "$manifest" mixing-project 1 || return $?

    status="$(jl_json_get "$manifest" '.state.status')" || return $?
    approved="$(jl_json_get "$manifest" '.state.approved')" || return $?
    delivered="$(jl_json_get "$manifest" '.state.delivered')" || return $?

    [ "$status" = active ] || {
        jl_error "Only active projects can be completed."
        return "$JL_EXIT_VALIDATION"
    }
    [ "$approved" = true ] || {
        jl_error "Project cannot be completed until a revision is approved."
        return "$JL_EXIT_VALIDATION"
    }
    [ "$delivered" = true ] || {
        jl_error "Project cannot be completed until delivery is recorded."
        return "$JL_EXIT_VALIDATION"
    }
    jl_validate_single_approved_revision "$manifest"
}

jl_validate_delivery_entry() {
    local entry_json path type label
    entry_json="$1"
    path="$(printf '%s' "$entry_json" | jq -er '.path')" || return "$JL_EXIT_VALIDATION"
    type="$(printf '%s' "$entry_json" | jq -er '.deliverable_type')" || return "$JL_EXIT_VALIDATION"
    [ -n "$path" ] || return "$JL_EXIT_VALIDATION"
    jl_validate_enum "$type" main_mix instrumental acapella tv_mix performance_mix stems master other || return $?

    if [ "$type" = other ]; then
        label="$(printf '%s' "$entry_json" | jq -r '.label // empty')"
        [ -n "$label" ] || return "$JL_EXIT_VALIDATION"
    fi
}
