#!/usr/bin/env bash
# Current client, project, studio, and revision detection.

if [ "${JL_MIXING_CONTEXT_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_CONTEXT_LOADED=1

JL_CONTEXT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_CONTEXT_LIB_DIR/common.sh"
# shellcheck source=lib/platform.sh
. "$JL_CONTEXT_LIB_DIR/platform.sh"
# shellcheck source=lib/json.sh
. "$JL_CONTEXT_LIB_DIR/json.sh"
# shellcheck source=lib/config.sh
. "$JL_CONTEXT_LIB_DIR/config.sh"

jl_find_up() {
    local start_path relative_marker current parent
    start_path="$1"
    relative_marker="$2"
    current="$(jl_abspath_allow_missing "$start_path")" || return $?
    [ -d "$current" ] || current="$(dirname "$current")"

    while :; do
        if [ -e "$current/$relative_marker" ]; then
            printf '%s\n' "$current"
            return 0
        fi
        parent="$(dirname "$current")"
        [ "$parent" != "$current" ] || break
        current="$parent"
    done
    return "$JL_EXIT_CONTEXT"
}

jl_context_project_root() {
    local start_path
    start_path="${1:-$PWD}"
    jl_find_up "$start_path" '00_Admin/project-manifest.json'
}

jl_context_client_root() {
    local start_path
    start_path="${1:-$PWD}"
    jl_find_up "$start_path" 'client.json'
}

jl_context_studio_root() {
    local start_path
    start_path="${1:-$PWD}"
    jl_config_find_root "$start_path"
}

jl_context_resolve_project() {
    local explicit_path start_path candidate
    explicit_path="${1:-}"
    start_path="${2:-$PWD}"

    if [ -n "$explicit_path" ]; then
        candidate="$(jl_abspath_allow_missing "$explicit_path")" || return $?
        if [ -f "$candidate" ] && [ "$(basename "$candidate")" = 'project-manifest.json' ]; then
            candidate="$(cd "$(dirname "$candidate")/.." && pwd)"
        fi
        if [ -f "$candidate/00_Admin/project-manifest.json" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        jl_error "Project not found at explicit path: $explicit_path"
        return "$JL_EXIT_CONTEXT"
    fi

    jl_context_project_root "$start_path" || {
        jl_error "No project context found from: $start_path"
        return "$JL_EXIT_CONTEXT"
    }
}

jl_context_resolve_client() {
    local explicit_path start_path candidate
    explicit_path="${1:-}"
    start_path="${2:-$PWD}"

    if [ -n "$explicit_path" ]; then
        candidate="$(jl_abspath_allow_missing "$explicit_path")" || return $?
        if [ -f "$candidate" ] && [ "$(basename "$candidate")" = 'client.json' ]; then
            candidate="$(dirname "$candidate")"
        fi
        if [ -f "$candidate/client.json" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        jl_error "Client not found at explicit path: $explicit_path"
        return "$JL_EXIT_CONTEXT"
    fi

    jl_context_client_root "$start_path" || {
        jl_error "No client context found from: $start_path"
        return "$JL_EXIT_CONTEXT"
    }
}

jl_context_project_manifest() {
    local project_root
    project_root="$1"
    printf '%s/00_Admin/project-manifest.json\n' "${project_root%/}"
}

jl_context_current_revision_number() {
    local project_root manifest
    project_root="$1"
    manifest="$(jl_context_project_manifest "$project_root")"
    jl_json_get "$manifest" '.state.current_revision'
}

jl_context_current_revision_root() {
    local project_root revision_number revision_folder
    project_root="$1"
    revision_number="$(jl_context_current_revision_number "$project_root")" || return $?
    if [ "$revision_number" -lt 1 ]; then
        jl_error "The project does not have a current revision."
        return "$JL_EXIT_CONTEXT"
    fi

    revision_folder="$(jl_json_get "$project_root/00_Admin/project-manifest.json" \
        ".revisions[] | select(.number == $revision_number) | .folder")" || return $?
    printf '%s/%s\n' "${project_root%/}" "$revision_folder"
}
