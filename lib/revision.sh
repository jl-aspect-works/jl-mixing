#!/usr/bin/env bash
# Revision numbering and manifest state transitions.

if [ "${JL_MIXING_REVISION_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_REVISION_LOADED=1

JL_REVISION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_REVISION_LIB_DIR/common.sh"
# shellcheck source=lib/json.sh
. "$JL_REVISION_LIB_DIR/json.sh"
# shellcheck source=lib/metadata.sh
. "$JL_REVISION_LIB_DIR/metadata.sh"
# shellcheck source=lib/naming.sh
. "$JL_REVISION_LIB_DIR/naming.sh"

jl_revision_next_number() {
    local manifest
    manifest="$1"
    jl_json_require_schema_identity "$manifest" mixing-project 1 || return $?
    jq -r '([.revisions[].number] | max // 0) + 1' "$manifest"
}

jl_revision_create_record() {
    local number description revision_id timestamp prefix padding folder
    number="$1"
    description="$2"
    revision_id="${3:-$(jl_uuid)}"
    timestamp="${4:-$(jl_now_iso8601)}"
    prefix="${5:-Revision_}"
    padding="${6:-2}"
    folder="04_Revisions/$(jl_revision_name "$number" "$prefix" "$padding")"

    jq -n \
        --argjson number "$number" \
        --arg revision_id "$revision_id" \
        --arg created_at "$timestamp" \
        --arg description "$description" \
        --arg folder "$folder" \
        '{
            number: $number,
            revision_id: $revision_id,
            created_at: $created_at,
            created_by: "new-revision",
            description: $description,
            status: "open",
            folder: $folder
        }'
}

jl_revision_append() {
    local manifest description number timestamp revision_id prefix padding record
    manifest="$1"
    description="$2"
    number="${3:-$(jl_revision_next_number "$manifest")}" 
    timestamp="${4:-$(jl_now_iso8601)}"
    revision_id="${5:-$(jl_uuid)}"
    prefix="${6:-Revision_}"
    padding="${7:-2}"
    record="$(jl_revision_create_record "$number" "$description" "$revision_id" "$timestamp" "$prefix" "$padding")" || return $?

    jl_json_update "$manifest" \
        '.revisions += [$revision] |
         .state.current_revision = $number |
         .metadata.last_modified_at = $timestamp' \
        --argjson revision "$record" \
        --argjson number "$number" \
        --arg timestamp "$timestamp"
}

jl_revision_approve() {
    local manifest number approved_by timestamp exists
    manifest="$1"
    number="$2"
    approved_by="$3"
    timestamp="${4:-$(jl_now_iso8601)}"

    exists="$(jq --argjson number "$number" '[.revisions[] | select(.number == $number)] | length' "$manifest")" || return $?
    if [ "$exists" -ne 1 ]; then
        jl_error "Revision $number does not exist exactly once."
        return "$JL_EXIT_VALIDATION"
    fi

    jl_json_update "$manifest" \
        '.revisions |= map(
            if .number == $number then .status = "approved"
            elif .status == "approved" then .status = "superseded"
            else . end
         ) |
         .state.approved = true |
         .state.approved_revision = $number |
         .state.approved_at = $timestamp |
         .state.approved_by = $approved_by |
         .metadata.last_modified_at = $timestamp' \
        --argjson number "$number" \
        --arg timestamp "$timestamp" \
        --arg approved_by "$approved_by"
}

jl_revision_status() {
    local manifest number
    manifest="$1"
    number="$2"
    jq -er --argjson number "$number" '.revisions[] | select(.number == $number) | .status' "$manifest"
}

jl_revision_current() {
    local manifest
    manifest="$1"
    jl_json_get "$manifest" '.state.current_revision'
}
