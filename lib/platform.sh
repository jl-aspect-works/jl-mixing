#!/usr/bin/env bash
# Cross-platform helpers for macOS and Linux.

if [ "${JL_MIXING_PLATFORM_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_PLATFORM_LOADED=1

JL_PLATFORM_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_PLATFORM_LIB_DIR/common.sh"

jl_platform_name() {
    case "$(uname -s)" in
        Darwin) printf '%s\n' macos ;;
        Linux)  printf '%s\n' linux ;;
        *)      printf '%s\n' unsupported ;;
    esac
}

jl_platform_require_supported() {
    local platform
    platform="$(jl_platform_name)"
    if [ "$platform" = "unsupported" ]; then
        jl_error "Unsupported operating system: $(uname -s)"
        return "$JL_EXIT_CONFIG"
    fi
}

jl_expand_home_path() {
    local path
    path="$1"
    case "$path" in
        '~') printf '%s\n' "$HOME" ;;
        '~/'*) printf '%s/%s\n' "$HOME" "${path#~/}" ;;
        *) printf '%s\n' "$path" ;;
    esac
}

jl_realpath() {
    local path directory base
    path="$(jl_expand_home_path "$1")"

    if [ -d "$path" ]; then
        (cd "$path" && pwd -P)
        return
    fi

    directory="$(dirname "$path")"
    base="$(basename "$path")"
    if [ -d "$directory" ]; then
        directory="$(cd "$directory" && pwd -P)" || return $?
        printf '%s/%s\n' "$directory" "$base"
        return 0
    fi

    jl_require_command python3 "Python 3 is required for portable path handling." || return $?
    python3 - "$path" <<'PY_REALPATH'
import os
import sys
print(os.path.realpath(sys.argv[1]))
PY_REALPATH
}

jl_abspath_allow_missing() {
    local path absolute directory base
    path="$(jl_expand_home_path "$1")"
    case "$path" in
        /*) absolute="$path" ;;
        *) absolute="$PWD/$path" ;;
    esac

    directory="$(dirname "$absolute")"
    base="$(basename "$absolute")"
    if [ -d "$directory" ]; then
        directory="$(cd "$directory" && pwd -P)" || return $?
        printf '%s/%s\n' "$directory" "$base"
        return 0
    fi

    jl_require_command python3 "Python 3 is required for portable path handling." || return $?
    python3 - "$absolute" <<'PY_ABSPATH'
import os
import sys
print(os.path.abspath(sys.argv[1]))
PY_ABSPATH
}

jl_stat_size() {
    local path
    path="$1"
    if stat -f '%z' "$path" >/dev/null 2>&1; then
        stat -f '%z' "$path"
    else
        stat -c '%s' "$path"
    fi
}

jl_stat_mode() {
    local path
    path="$1"
    if stat -f '%Lp' "$path" >/dev/null 2>&1; then
        stat -f '%Lp' "$path"
    else
        stat -c '%a' "$path"
    fi
}

jl_sha256() {
    local path
    path="$1"
    if jl_command_exists shasum; then
        shasum -a 256 "$path" | awk '{print $1}'
    elif jl_command_exists sha256sum; then
        sha256sum "$path" | awk '{print $1}'
    else
        jl_error "No SHA-256 utility is available."
        return "$JL_EXIT_CONFIG"
    fi
}

jl_mktemp_file_near() {
    local target directory base
    target="$1"
    directory="$(dirname "$target")"
    base="$(basename "$target")"
    mkdir -p "$directory"
    mktemp "$directory/.${base}.tmp.XXXXXX"
}

jl_mktemp_dir() {
    local prefix
    prefix="${1:-jl-mixing}"
    mktemp -d "${TMPDIR:-/tmp}/${prefix}.XXXXXX"
}

jl_open_path() {
    local path
    path="$1"
    case "$(jl_platform_name)" in
        macos) open "$path" ;;
        linux)
            if jl_command_exists xdg-open; then
                xdg-open "$path"
            else
                jl_error "xdg-open is not installed."
                return "$JL_EXIT_CONFIG"
            fi
            ;;
        *) jl_platform_require_supported ;;
    esac
}
