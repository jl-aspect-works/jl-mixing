#!/usr/bin/env bash
# Remove JL Mixing Automation application files and managed command launchers.
#
# The uninstaller is deliberately scoped to the installation prefix. It never
# reads, changes, or deletes a studio workspace such as ~/Music/JL Mixing.
set -eu

usage() {
    cat <<'USAGE'
Usage: jl-mixing-uninstall [--prefix PATH]
       ./uninstall.sh [--prefix PATH]

Options:
  --prefix PATH  Installation prefix (default: ~/.local)
  -h, --help     Show this help
USAGE
}

prefix="${JL_MIXING_INSTALL_PREFIX:-$HOME/.local}"
while [ "$#" -gt 0 ]; do
    case "$1" in
        --prefix)
            [ "$#" -ge 2 ] || { echo "Error: --prefix requires a value." >&2; exit 2; }
            prefix="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

case "$prefix" in
    /*) ;;
    *) prefix="$PWD/$prefix" ;;
esac
prefix_parent="$(dirname "$prefix")"
prefix_base="$(basename "$prefix")"
mkdir -p "$prefix_parent"
prefix_parent="$(cd "$prefix_parent" && pwd -P)"
prefix="$prefix_parent/$prefix_base"

app_dir="$prefix/share/jl-mixing"
bin_dir="$prefix/bin"
commands='new-studio
new-client
new-mix
validate-intake
new-revision
approve-mix
create-delivery
complete-project
jl-mixing-uninstall'

# Remove only launchers carrying the installer marker. A user-created file with
# the same name is preserved and reported rather than deleted.
echo "$commands" | while IFS= read -r command_name; do
    [ -n "$command_name" ] || continue
    launcher="$bin_dir/$command_name"
    [ -e "$launcher" ] || continue
    if grep -q 'JL Mixing Automation managed launcher' "$launcher" 2>/dev/null; then
        rm -f -- "$launcher"
        printf 'Removed launcher: %s\n' "$launcher"
    else
        printf 'Preserved unmanaged file: %s\n' "$launcher" >&2
    fi
done

if [ -d "$app_dir" ]; then
    rm -rf -- "${app_dir:?}"
    printf 'Removed application: %s\n' "$app_dir"
else
    printf 'Application is not installed at: %s\n' "$app_dir"
fi

# Do not remove PREFIX/bin or PREFIX/share; other applications may use them.
echo "JL Mixing Automation has been uninstalled."
echo "Studio workspaces were not modified."
