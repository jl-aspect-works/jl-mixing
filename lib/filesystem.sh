#!/usr/bin/env bash
# Safe filesystem primitives used by commands and transactional workflows.
#
# These helpers centralize overwrite protection, atomic writes, exact copies,
# safe moves, and the invariant that Original_Delivery is never modified.
if [ "${JL_MIXING_FILESYSTEM_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_FILESYSTEM_LOADED=1

JL_FILESYSTEM_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_FILESYSTEM_LIB_DIR/common.sh"
# shellcheck source=lib/platform.sh
. "$JL_FILESYSTEM_LIB_DIR/platform.sh"

# Create a directory tree if missing and accept an existing directory.
jl_fs_ensure_directory() {
    local path
    path="$1"
    if [ -e "$path" ] && [ ! -d "$path" ]; then
        jl_error "Cannot create directory because a non-directory exists: $path"
        return "$JL_EXIT_UNSAFE"
    fi
    mkdir -p "$path"
}

# Create a new directory but refuse any existing destination.
jl_fs_create_directory() {
    local path
    path="$1"
    if [ -e "$path" ]; then
        jl_error "Refusing to overwrite existing path: $path"
        return "$JL_EXIT_UNSAFE"
    fi
    mkdir -p "$path"
}

# Identify paths inside the immutable Original_Delivery subtree.
jl_fs_is_original_delivery_path() {
    local path
    path="$(jl_abspath_allow_missing "$1")" || return $?
    case "$path" in
        */01_Client_Files/Original_Delivery|*/01_Client_Files/Original_Delivery/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Reject any attempted write beneath Original_Delivery.
jl_fs_assert_mutable_path() {
    local path
    path="$1"
    if jl_fs_is_original_delivery_path "$path"; then
        jl_error "Unsafe operation prevented inside immutable Original_Delivery: $path"
        return "$JL_EXIT_UNSAFE"
    fi
}

# Copy one file without overwriting and verify the bytes are identical.
jl_fs_copy_file_exact() {
    local source destination
    source="$1"
    destination="$2"

    [ -f "$source" ] || {
        jl_error "Source file not found: $source"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_assert_mutable_path "$destination" || return $?

    if [ -e "$destination" ]; then
        jl_error "Refusing to overwrite existing destination: $destination"
        return "$JL_EXIT_UNSAFE"
    fi

    mkdir -p "$(dirname "$destination")"
    cp -p "$source" "$destination"
}

# Copy a directory tree into a new destination without overwriting.
jl_fs_copy_tree() {
    local source destination
    source="$1"
    destination="$2"

    [ -d "$source" ] || {
        jl_error "Source directory not found: $source"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_assert_mutable_path "$destination" || return $?

    if [ -e "$destination" ]; then
        jl_error "Refusing to overwrite existing destination: $destination"
        return "$JL_EXIT_UNSAFE"
    fi

    mkdir -p "$(dirname "$destination")"
    cp -R "$source" "$destination"
}

# Write stdin to a sibling temporary file and atomically replace the target.
jl_fs_atomic_write() {
    local target temp_file
    target="$1"
    jl_fs_assert_mutable_path "$target" || return $?
    mkdir -p "$(dirname "$target")"

    temp_file="$(jl_mktemp_file_near "$target")" || return $?
    if ! cat > "$temp_file"; then
        rm -f "$temp_file"
        return "$JL_EXIT_GENERAL"
    fi

    if [ -e "$target" ]; then
        chmod "$(jl_stat_mode "$target")" "$temp_file"
    else
        chmod 644 "$temp_file"
    fi

    mv "$temp_file" "$target"
}

# Move a source to a non-existing destination after safety checks.
jl_fs_safe_move() {
    local source destination
    source="$1"
    destination="$2"

    [ -e "$source" ] || {
        jl_error "Source path not found: $source"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_assert_mutable_path "$source" || return $?
    jl_fs_assert_mutable_path "$destination" || return $?

    if [ -e "$destination" ]; then
        jl_error "Refusing to overwrite existing destination: $destination"
        return "$JL_EXIT_UNSAFE"
    fi

    mkdir -p "$(dirname "$destination")"
    mv "$source" "$destination"
}

# Return success when two regular files have identical content.
jl_fs_same_bytes() {
    local first second
    first="$1"
    second="$2"
    cmp -s "$first" "$second"
}

# Return success when a directory has no immediate entries.
jl_fs_directory_is_empty() {
    local path
    path="$1"
    [ -d "$path" ] || return 1
    [ -z "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit)" ]
}

# Copy the contents of a source directory into an existing empty destination.
# This is intended for one-time imports during project creation.
# Copy every top-level source entry into an existing destination safely.
jl_fs_copy_directory_contents() {
    local source destination entry
    source="$1"
    destination="$2"

    [ -d "$source" ] || {
        jl_error "Source directory not found: $source"
        return "$JL_EXIT_VALIDATION"
    }
    [ -d "$destination" ] || {
        jl_error "Destination directory not found: $destination"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_directory_is_empty "$destination" || {
        jl_error "Destination must be empty before importing files: $destination"
        return "$JL_EXIT_UNSAFE"
    }

    # Include dotfiles without relying on shell-specific glob options.
    find "$source" -mindepth 1 -maxdepth 1 -print |
    while IFS= read -r entry; do
        cp -Rp "$entry" "$destination/"
    done
}
