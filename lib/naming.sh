#!/usr/bin/env bash
# Portable naming helpers for IDs, folders, DAW projects, and deliverables.
#
# The routines avoid Bash 4 features and sanitize user-controlled components
# before they become filesystem names.
if [ "${JL_MIXING_NAMING_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_NAMING_LOADED=1

JL_NAMING_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_NAMING_LIB_DIR/common.sh"

# Best-effort transliteration to ASCII using iconv when available.
jl_transliterate_ascii() {
    local value
    value="$1"
    if jl_command_exists iconv; then
        printf '%s' "$value" | iconv -f UTF-8 -t ASCII//TRANSLIT 2>/dev/null || printf '%s' "$value"
    else
        printf '%s' "$value"
    fi
}

# Convert user text into a lowercase hyphenated stable identifier.
jl_slugify() {
    local value
    value="$(jl_transliterate_ascii "$1")"
    printf '%s' "$value" |
        tr '[:upper:]' '[:lower:]' |
        sed 's/[^a-z0-9][^a-z0-9]*/-/g;s/^-//;s/-$//'
}

# Convert a slug into a readable title-cased default name.
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

# Remove unsafe filename characters and normalize whitespace.
jl_sanitize_component() {
    local value
    value="$1"
    printf '%s' "$value" |
        tr '\r\n\t' '   ' |
        sed 's#[/:*?"<>|]#-#g;s/[[:space:]][[:space:]]*/ /g;s/^[[:space:].-]*//;s/[[:space:].-]*$//'
}

# Format a zero-padded revision folder name.
jl_revision_name() {
    local number prefix padding
    number="$1"
    prefix="${2:-Revision_}"
    padding="${3:-2}"
    printf '%s%0*d\n' "$prefix" "$padding" "$number"
}

# Build the readable DAW project name from artist and project.
jl_daw_project_name() {
    local artist project
    artist="$(jl_sanitize_component "$1")"
    project="$(jl_sanitize_component "$2")"
    printf '%s - %s\n' "$artist" "$project"
}

# Build a deliverable filename stem from artist, project, and label.
jl_deliverable_name() {
    local artist project deliverable extension
    artist="$(jl_sanitize_component "$1")"
    project="$(jl_sanitize_component "$2")"
    deliverable="$(jl_sanitize_component "$3")"
    extension="${4:-wav}"
    extension="$(printf '%s' "$extension" | sed 's/^\.//')"
    printf '%s - %s - %s.%s\n' "$artist" "$project" "$deliverable" "$extension"
}

# Prefix a deliverable name so working prints are excluded from delivery.
jl_working_print_name() {
    local prefix artist project label extension
    prefix="$1"
    artist="$2"
    project="$3"
    label="$4"
    extension="${5:-wav}"
    printf '%s%s\n' "$prefix" "$(jl_deliverable_name "$artist" "$project" "$label" "$extension")"
}

# Replace supported naming tokens in a configured pattern.
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
