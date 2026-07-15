#!/usr/bin/env bash
# Rollback-capable filesystem transactions for JL Mixing v1.1 commands.
#
# Commands build complete proposed results in sibling staging paths, validate
# them, and only then call these helpers. Rename operations therefore remain on
# one filesystem and can be reversed when a later coordinated step fails.
if [ "${JL_MIXING_TRANSACTION_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_TRANSACTION_LOADED=1

JL_TRANSACTION_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_TRANSACTION_LIB_DIR/common.sh"
# shellcheck source=lib/platform.sh
. "$JL_TRANSACTION_LIB_DIR/platform.sh"
# shellcheck source=lib/filesystem.sh
. "$JL_TRANSACTION_LIB_DIR/filesystem.sh"

# Test-only failure injection. A comma-separated JL_MIXING_FAIL_AT value may
# name one or more points. Production callers leave the variable unset.
jl_txn_fail_if_requested() {
    local point configured item old_ifs
    point="$1"
    configured="${JL_MIXING_FAIL_AT:-}"
    [ -n "$configured" ] || return 0

    old_ifs="$IFS"
    IFS=','
    # shellcheck disable=SC2086
    set -- $configured
    IFS="$old_ifs"
    for item in "$@"; do
        if [ "$(jl_trim "$item")" = "$point" ]; then
            jl_error "Injected transaction failure at: $point"
            return "$JL_EXIT_GENERAL"
        fi
    done
}

# Create a hidden staging directory beside the eventual destination.
jl_txn_stage_directory_near() {
    local destination parent base
    destination="$1"
    parent="$(dirname "$destination")"
    base="$(basename "$destination")"

    [ -d "$parent" ] || {
        jl_error "Transaction parent directory not found: $parent"
        return "$JL_EXIT_CONTEXT"
    }
    [ ! -L "$parent" ] || {
        jl_error "Transaction parent must not be a symbolic link: $parent"
        return "$JL_EXIT_UNSAFE"
    }

    mktemp -d "$parent/.${base}.stage.XXXXXX"
}

# Reserve a nonexistent hidden backup path beside a destination. mktemp creates
# the directory securely; removing that empty reservation leaves a unique name
# for a later atomic rename.
jl_txn_backup_path_near() {
    local destination parent base reservation
    destination="$1"
    parent="$(dirname "$destination")"
    base="$(basename "$destination")"
    reservation="$(mktemp -d "$parent/.${base}.backup.XXXXXX")" || return $?
    rmdir "$reservation" || return $?
    printf '%s\n' "$reservation"
}

# Move an existing entry to a unique sibling backup path. If the source does
# not exist, print an empty line so callers can use one uniform rollback flow.
jl_txn_backup_existing() {
    local source backup
    source="$1"
    if [ ! -e "$source" ] && [ ! -L "$source" ]; then
        printf '\n'
        return 0
    fi

    backup="$(jl_txn_backup_path_near "$source")" || return $?
    mv "$source" "$backup" || {
        jl_error "Unable to back up transaction target: $source"
        return "$JL_EXIT_GENERAL"
    }
    printf '%s\n' "$backup"
}

# Restore one backup, removing only the replacement entry created by the active
# transaction. The backup path itself is never followed when it is a symlink.
jl_txn_restore_backup() {
    local backup destination
    backup="$1"
    destination="$2"

    if [ -e "$destination" ] || [ -L "$destination" ]; then
        jl_fs_remove_entry_no_follow "$destination" || return $?
    fi
    if [ -n "$backup" ] && { [ -e "$backup" ] || [ -L "$backup" ]; }; then
        mv "$backup" "$destination" || {
            jl_error "Unable to restore transaction backup: $destination"
            return "$JL_EXIT_GENERAL"
        }
    fi
}

# Commit a new staged directory to a destination that must not already exist.
jl_txn_commit_new_directory() {
    local staged_directory destination status
    staged_directory="$1"
    destination="$2"

    jl_fs_is_directory_no_symlink "$staged_directory" || {
        jl_error "Staged directory is missing or unsafe: $staged_directory"
        return "$JL_EXIT_VALIDATION"
    }
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        jl_error "Transaction destination already exists: $destination"
        return "$JL_EXIT_UNSAFE"
    fi
    jl_fs_same_filesystem "$staged_directory" "$(dirname "$destination")" || {
        jl_error "Staging and destination are on different filesystems."
        return "$JL_EXIT_UNSAFE"
    }

    jl_txn_fail_if_requested before-directory-commit || return $?
    mv "$staged_directory" "$destination" || {
        jl_error "Unable to commit staged directory: $destination"
        return "$JL_EXIT_GENERAL"
    }
    if jl_txn_fail_if_requested after-directory-commit; then
        return 0
    else
        status=$?
    fi

    # A post-rename failure is still part of this command's transaction. Remove
    # only the directory just created by this invocation.
    jl_fs_remove_entry_no_follow "$destination" || {
        jl_error "New-directory commit failed and cleanup was incomplete: $destination"
        return "$JL_EXIT_GENERAL"
    }
    return "$status"
}

# Replace a directory as one rollback-capable transaction. Existing contents
# may be replaced only after the calling command has obtained explicit user
# authorization and completed all staging validation.
jl_txn_replace_directory() {
    local staged_directory destination backup status rollback_status
    staged_directory="$1"
    destination="$2"
    backup=""

    jl_fs_is_directory_no_symlink "$staged_directory" || {
        jl_error "Staged directory is missing or unsafe: $staged_directory"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_same_filesystem "$staged_directory" "$(dirname "$destination")" || {
        jl_error "Staging and destination are on different filesystems."
        return "$JL_EXIT_UNSAFE"
    }

    backup="$(jl_txn_backup_existing "$destination")" || return $?
    status=0
    jl_txn_fail_if_requested after-directory-backup || status=$?
    if [ "$status" -eq 0 ]; then
        mv "$staged_directory" "$destination" || status=$?
    fi
    if [ "$status" -eq 0 ]; then
        jl_txn_fail_if_requested after-directory-replacement || status=$?
    fi

    if [ "$status" -eq 0 ]; then
        [ -z "$backup" ] || jl_fs_remove_entry_no_follow "$backup"
        return 0
    fi

    rollback_status=0
    jl_txn_restore_backup "$backup" "$destination" || rollback_status=$?
    if [ "$rollback_status" -ne 0 ]; then
        jl_error "Directory replacement failed and rollback was incomplete: $destination"
        return "$JL_EXIT_GENERAL"
    fi
    return "$status"
}

# Commit a staged directory and staged manifest as one coordinated operation.
# The manifest staging file must be a sibling of its final path so its rename is
# atomic. Both prior targets are restored if either commit or verification hook
# fails.
jl_txn_commit_directory_and_file() {
    local staged_directory destination_directory staged_file destination_file
    local directory_backup file_backup status rollback_failed
    staged_directory="$1"
    destination_directory="$2"
    staged_file="$3"
    destination_file="$4"
    directory_backup=""
    file_backup=""

    jl_fs_is_directory_no_symlink "$staged_directory" || {
        jl_error "Staged directory is missing or unsafe: $staged_directory"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_is_regular_file_no_symlink "$staged_file" || {
        jl_error "Staged manifest is missing or unsafe: $staged_file"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_same_filesystem "$staged_directory" "$(dirname "$destination_directory")" || {
        jl_error "Directory staging is on a different filesystem."
        return "$JL_EXIT_UNSAFE"
    }
    jl_fs_same_filesystem "$staged_file" "$(dirname "$destination_file")" || {
        jl_error "Manifest staging is on a different filesystem."
        return "$JL_EXIT_UNSAFE"
    }

    directory_backup="$(jl_txn_backup_existing "$destination_directory")" || return $?
    file_backup="$(jl_txn_backup_existing "$destination_file")" || {
        jl_txn_restore_backup "$directory_backup" "$destination_directory" || true
        return "$JL_EXIT_GENERAL"
    }

    status=0
    jl_txn_fail_if_requested after-coordinated-backup || status=$?
    if [ "$status" -eq 0 ]; then
        mv "$staged_directory" "$destination_directory" || status=$?
    fi
    if [ "$status" -eq 0 ]; then
        jl_txn_fail_if_requested after-coordinated-directory || status=$?
    fi
    if [ "$status" -eq 0 ]; then
        mv "$staged_file" "$destination_file" || status=$?
    fi
    if [ "$status" -eq 0 ]; then
        jl_txn_fail_if_requested after-coordinated-file || status=$?
    fi

    if [ "$status" -eq 0 ]; then
        [ -z "$directory_backup" ] || jl_fs_remove_entry_no_follow "$directory_backup"
        [ -z "$file_backup" ] || jl_fs_remove_entry_no_follow "$file_backup"
        return 0
    fi

    rollback_failed=0
    jl_txn_restore_backup "$file_backup" "$destination_file" || rollback_failed=1
    jl_txn_restore_backup "$directory_backup" "$destination_directory" || rollback_failed=1
    if [ "$rollback_failed" -ne 0 ]; then
        jl_error "Coordinated transaction failed and rollback was incomplete."
        return "$JL_EXIT_GENERAL"
    fi
    return "$status"
}
