#!/usr/bin/env bash
# Creation and maintenance of the standard metadata block in JSON documents.
#
# Creation identity is stable. Only last_modified_at changes during updates.
if [ "${JL_MIXING_METADATA_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_METADATA_LOADED=1

JL_METADATA_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JL_METADATA_REPO_ROOT="$(cd "$JL_METADATA_LIB_DIR/.." && pwd)"
# shellcheck source=lib/common.sh
. "$JL_METADATA_LIB_DIR/common.sh"
# shellcheck source=lib/json.sh
. "$JL_METADATA_LIB_DIR/json.sh"

# Read the application VERSION file from the resolved installation root.
jl_software_version() {
    local version_file first_line
    version_file="${JL_MIXING_VERSION_FILE:-$JL_METADATA_REPO_ROOT/VERSION}"
    if [ ! -f "$version_file" ]; then
        jl_error "VERSION file not found: $version_file"
        return "$JL_EXIT_CONFIG"
    fi
    first_line="$(sed -n '1p' "$version_file")"
    jl_assert_nonempty "$first_line" "software version" || return $?
    printf '%s\n' "$first_line"
}

# Build the standard created_with software identity string.
jl_created_with() {
    printf 'jl-mixing %s\n' "$(jl_software_version)"
}

# Create a complete metadata object for a new JSON document.
jl_metadata_create() {
    local schema_name created_by schema_version document_id timestamp
    schema_name="$1"
    created_by="$2"
    schema_version="${3:-1.0.0}"
    document_id="${4:-$(jl_uuid)}"
    timestamp="${5:-$(jl_now_iso8601)}"

    jl_json_require_jq || return $?
    jq -n \
        --arg schema "$schema_name" \
        --arg schema_version "$schema_version" \
        --arg document_id "$document_id" \
        --arg created_by "$created_by" \
        --arg created_with "$(jl_created_with)" \
        --arg created_at "$timestamp" \
        '{
            schema: $schema,
            schema_version: $schema_version,
            document_id: $document_id,
            created_by: $created_by,
            created_with: $created_with,
            created_at: $created_at,
            last_modified_at: $created_at
        }'
}

# Refresh only last_modified_at on an existing document.
jl_metadata_touch() {
    local file timestamp
    file="$1"
    timestamp="${2:-$(jl_now_iso8601)}"
    jl_json_set_string "$file" '.metadata.last_modified_at' "$timestamp"
}

# Validate required metadata fields and supported schema identity.
jl_metadata_validate() {
    local file expected_schema field value
    file="$1"
    expected_schema="$2"
    jl_json_require_schema_identity "$file" "$expected_schema" 1 || return $?

    for field in document_id created_by created_with created_at last_modified_at; do
        value="$(jl_json_get_optional "$file" ".metadata.$field" '')"
        if [ -z "$value" ]; then
            jl_error "Missing metadata field '$field' in $file"
            return "$JL_EXIT_VALIDATION"
        fi
    done
}

# Copy immutable creation metadata from one document to another JSON object.
jl_metadata_copy_creation_fields() {
    local source_file target_file
    source_file="$1"
    target_file="$2"

    jl_json_update "$target_file" \
        '.metadata.document_id = $document_id |
         .metadata.created_by = $created_by |
         .metadata.created_with = $created_with |
         .metadata.created_at = $created_at' \
        --arg document_id "$(jl_json_get "$source_file" '.metadata.document_id')" \
        --arg created_by "$(jl_json_get "$source_file" '.metadata.created_by')" \
        --arg created_with "$(jl_json_get "$source_file" '.metadata.created_with')" \
        --arg created_at "$(jl_json_get "$source_file" '.metadata.created_at')"
}
