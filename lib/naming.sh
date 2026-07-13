#!/usr/bin/env bash
# Consistent identifiers, revision folders, and audio filenames.

if [ "${JL_MIXING_NAMING_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_NAMING_LOADED=1

JL_NAMING_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_NAMING_LIB_DIR/common.sh"

jl_transliterate_ascii() {
    local value
    value="$1"
    if jl_command_exists iconv; then
        printf '%s' "$value" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "$value"
    else
        printf '%s' "$value"
    fi
}

jl_slugify() {
    local value
    value="$(jl_transliterate_ascii "$1")"
    printf '%s' "$value" |
        tr '[:upper:]' '[:lower:]' |
        sed 's/[^a-z0-9][^a-z0-9]*/-/g;s/^-//;s/-$//'
}

jl_title_from_slug() {
    local slug
    slug="$1"
    printf '%s' "$slug" | tr '-' ' ' | awk '{
        for (i = 1; i <= NF; i++) {
            $i = toupper(substr($i, 1, 1)) substr($i, 2)
        }
        print
    }'
}

jl_sanitize_component() {
    local value
    value="$1"
    printf '%s' "$value" |
        tr '\r\n\t' '   ' |
        sed 's#[/:*?"<>|]#-#g;s/[[:space:]][[:space:]]*/ /g;s/^[[:space:].-]*//;s/[[:space:].-]*$//'
}

jl_revision_name() {
    local number prefix padding
    number="$1"
    prefix="${2:-Revision_}"
    padding="${3:-2}"
    printf '%s%0*d\n' "$prefix" "$padding" "$number"
}

jl_daw_project_name() {
    local artist project
    artist="$(jl_sanitize_component "$1")"
    project="$(jl_sanitize_component "$2")"
    printf '%s - %s\n' "$artist" "$project"
}

jl_deliverable_name() {
    local artist project deliverable extension
    artist="$(jl_sanitize_component "$1")"
    project="$(jl_sanitize_component "$2")"
    deliverable="$(jl_sanitize_component "$3")"
    extension="${4:-wav}"
    extension="$(printf '%s' "$extension" | sed 's/^\.//')"
    printf '%s - %s - %s.%s\n' "$artist" "$project" "$deliverable" "$extension"
}

jl_working_print_name() {
    local prefix artist project label extension
    prefix="$1"
    artist="$2"
    project="$3"
    label="$4"
    extension="${5:-wav}"
    printf '%s%s\n' "$prefix" "$(jl_deliverable_name "$artist" "$project" "$label" "$extension")"
}

jl_expand_naming_pattern() {
    local pattern artist project deliverable result
    pattern="$1"
    artist="$2"
    project="$3"
    deliverable="${4:-}"
    result="$pattern"
    result="$(printf '%s' "$result" | sed "s/{{ARTIST}}/$(printf '%s' "$artist" | sed 's/[&|]/\\&/g')/g")"
    result="$(printf '%s' "$result" | sed "s/{{PROJECT_NAME}}/$(printf '%s' "$project" | sed 's/[&|]/\\&/g')/g")"
    result="$(printf '%s' "$result" | sed "s/{{DELIVERABLE}}/$(printf '%s' "$deliverable" | sed 's/[&|]/\\&/g')/g")"
    printf '%s\n' "$result"
}
