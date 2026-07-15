#!/usr/bin/env bash
# Install or upgrade JL Mixing Automation under a user-selected prefix.
#
# The installer copies immutable application assets into a stable application
# directory, creates a private Python virtual environment for JSON Schema
# validation, and writes small launchers into PREFIX/bin. It never creates,
# changes, or removes a studio workspace.
set -eu

usage() {
    cat <<'USAGE'
Usage: ./install.sh [--prefix PATH]

Options:
  --prefix PATH  Installation prefix (default: ~/.local)
  -h, --help     Show this help

Installed locations:
  Application: PREFIX/share/jl-mixing
  Commands:    PREFIX/bin
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

SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Canonicalize an existing or not-yet-created destination without requiring
# realpath, which is not part of the macOS Bash 3.2 baseline.
canonicalize_destination() {
    local path parent base
    path="$1"
    case "$path" in
        /*) ;;
        *) path="$PWD/$path" ;;
    esac
    parent="$(dirname "$path")"
    base="$(basename "$path")"
    mkdir -p "$parent"
    parent="$(cd "$parent" && pwd -P)"
    printf '%s/%s\n' "$parent" "$base"
}

prefix="$(canonicalize_destination "$prefix")"
app_dir="$prefix/share/jl-mixing"
bin_dir="$prefix/bin"
share_dir="$prefix/share"

required_paths='VERSION
LICENSE
README.md
bin
lib
schemas
templates
docs
tools/validate-json.py
tools/build-intake-report.py
tools/project-state.py
tools/import-project-source.py
tools/import-revision-source.py
tools/build-delivery.py
packaging/requirements.txt
uninstall.sh'

# Fail before touching the installation when the archive is incomplete.
echo "$required_paths" | while IFS= read -r relative_path; do
    [ -n "$relative_path" ] || continue
    if [ ! -e "$SOURCE_ROOT/$relative_path" ]; then
        echo "Error: installation package is missing $relative_path" >&2
        exit 3
    fi
done

# Python 3.10+ is required by the pinned jsonschema runtime dependency.
command -v python3 >/dev/null 2>&1 || {
    echo "Error: Python 3.10 or newer is required." >&2
    exit 3
}
command -v jq >/dev/null 2>&1 || {
    echo "Error: jq is required." >&2
    exit 3
}
python3 - <<'PY_VERSION' || exit 3
import sys
if sys.version_info < (3, 10):
    print("Error: Python 3.10 or newer is required.", file=sys.stderr)
    raise SystemExit(1)
PY_VERSION

mkdir -p "$share_dir" "$bin_dir"
stage_dir="$(mktemp -d "$share_dir/.jl-mixing-stage.XXXXXX")"
backup_dir=""
new_app_installed=0

# Restore the previous application if any installation step fails. Launchers
# use a stable application path, so restored versions remain immediately usable.
rollback_install() {
    status=$?
    if [ "$status" -ne 0 ]; then
        echo "Installation failed; restoring the previous version." >&2
        rm -rf -- "$stage_dir"
        if [ "$new_app_installed" -eq 1 ]; then
            rm -rf -- "${app_dir:?}"
        fi
        if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
            mv "$backup_dir" "$app_dir"
        fi
    fi
    exit "$status"
}
trap rollback_install EXIT HUP INT TERM

# Copy only runtime and documentation assets. Development tests, CI metadata,
# examples, Git data, and local virtual environments are intentionally excluded.
mkdir -p "$stage_dir/bin" "$stage_dir/lib" "$stage_dir/schemas" \
    "$stage_dir/templates" "$stage_dir/docs" "$stage_dir/tools" "$stage_dir/packaging"
cp "$SOURCE_ROOT/VERSION" "$SOURCE_ROOT/LICENSE" "$SOURCE_ROOT/README.md" "$stage_dir/"
cp -R "$SOURCE_ROOT/bin/." "$stage_dir/bin/"
cp -R "$SOURCE_ROOT/lib/." "$stage_dir/lib/"
cp -R "$SOURCE_ROOT/schemas/." "$stage_dir/schemas/"
cp -R "$SOURCE_ROOT/templates/." "$stage_dir/templates/"
cp -R "$SOURCE_ROOT/docs/." "$stage_dir/docs/"
cp "$SOURCE_ROOT/tools/validate-json.py" "$SOURCE_ROOT/tools/build-intake-report.py" \
    "$SOURCE_ROOT/tools/project-state.py" "$SOURCE_ROOT/tools/import-project-source.py" \
    "$SOURCE_ROOT/tools/import-revision-source.py" "$SOURCE_ROOT/tools/build-delivery.py" "$stage_dir/tools/"
cp "$SOURCE_ROOT/packaging/requirements.txt" "$stage_dir/packaging/"
cp "$SOURCE_ROOT/install.sh" "$SOURCE_ROOT/uninstall.sh" "$stage_dir/"

# A release builder may include a platform-specific wheelhouse. When present,
# the installer uses it without network access; otherwise pip resolves the
# pinned package from the configured Python package index.
if [ -d "$SOURCE_ROOT/packaging/vendor" ]; then
    cp -R "$SOURCE_ROOT/packaging/vendor" "$stage_dir/packaging/"
fi

chmod +x "$stage_dir/install.sh" "$stage_dir/uninstall.sh" "$stage_dir/bin/"* \
    "$stage_dir/tools/validate-json.py" "$stage_dir/tools/build-intake-report.py" \
    "$stage_dir/tools/project-state.py" "$stage_dir/tools/import-project-source.py" \
    "$stage_dir/tools/import-revision-source.py" \
    "$stage_dir/tools/build-delivery.py"

if [ -d "$app_dir" ]; then
    backup_dir="$(mktemp -d "$share_dir/.jl-mixing-backup.XXXXXX")"
    rmdir "$backup_dir"
    mv "$app_dir" "$backup_dir"
fi
mv "$stage_dir" "$app_dir"
new_app_installed=1

# Tests may opt into system site packages to avoid network access. Production
# installs always use an isolated environment owned entirely by the application.
python3 -m venv "$app_dir/.venv"

# Installation tests link the invoking interpreter's package directory into the
# private venv. This is deliberately test-only and avoids package-index access
# even when the invoking Python is itself inside a virtual environment.
if [ "${JL_MIXING_TEST_SYSTEM_SITE_PACKAGES:-0}" = "1" ]; then
    host_site="$(python3 - <<'PY_HOST_SITE'
import site
print(site.getsitepackages()[0])
PY_HOST_SITE
)"
    venv_site="$("$app_dir/.venv/bin/python" - <<'PY_VENV_SITE'
import site
print(site.getsitepackages()[0])
PY_VENV_SITE
)"
    printf '%s\n' "$host_site" > "$venv_site/jl_mixing_test_host_site.pth"
fi

# Installation tests can reuse an exact host package without contacting a
# package index. Production environments remain isolated and install normally.
dependency_ready=0
if [ "${JL_MIXING_TEST_SYSTEM_SITE_PACKAGES:-0}" = "1" ]; then
    if "$app_dir/.venv/bin/python" - <<'PY_PRESENT'
from importlib.metadata import PackageNotFoundError, version
try:
    actual = version("jsonschema")
except PackageNotFoundError:
    raise SystemExit(1)
raise SystemExit(0 if actual == "4.26.0" else 1)
PY_PRESENT
    then
        dependency_ready=1
    fi
fi

if [ "$dependency_ready" -eq 0 ]; then
    if [ -d "$app_dir/packaging/vendor" ] &&
            find "$app_dir/packaging/vendor" -type f | grep -q .; then
        "$app_dir/.venv/bin/python" -m pip install \
            --disable-pip-version-check --no-input --no-index \
            --find-links "$app_dir/packaging/vendor" \
            -r "$app_dir/packaging/requirements.txt"
    else
        "$app_dir/.venv/bin/python" -m pip install \
            --disable-pip-version-check --no-input \
            -r "$app_dir/packaging/requirements.txt"
    fi
fi

"$app_dir/.venv/bin/python" - <<'PY_VERIFY'
from importlib.metadata import version
expected = "4.26.0"
actual = version("jsonschema")
if actual != expected:
    raise SystemExit(
        f"jsonschema version mismatch: expected {expected}, found {actual}"
    )
PY_VERIFY

# Bash's %q produces a value safe to embed in Bash launcher scripts, including
# prefixes that contain spaces.
quoted_app_dir="$(printf '%q' "$app_dir")"
commands='new-studio
new-client
new-mix
validate-intake
new-revision
approve-mix
create-delivery
complete-project'

write_launcher() {
    local command_name destination temporary
    command_name="$1"
    destination="$bin_dir/$command_name"
    temporary="$destination.tmp.$$"
    cat > "$temporary" <<EOF_LAUNCHER
#!/usr/bin/env bash
# JL Mixing Automation managed launcher. Generated by install.sh.
export JL_MIXING_HOME=$quoted_app_dir
export JL_MIXING_PYTHON=$quoted_app_dir/.venv/bin/python
exec $quoted_app_dir/bin/$command_name "\$@"
EOF_LAUNCHER
    chmod +x "$temporary"
    mv "$temporary" "$destination"
}

echo "$commands" | while IFS= read -r command_name; do
    [ -n "$command_name" ] || continue
    write_launcher "$command_name"
done

# Install a dedicated uninstall entry point without adding a workflow command.
uninstall_launcher="$bin_dir/jl-mixing-uninstall"
cat > "$uninstall_launcher.tmp.$$" <<EOF_UNINSTALL
#!/usr/bin/env bash
# JL Mixing Automation managed launcher. Generated by install.sh.
exec $quoted_app_dir/uninstall.sh --prefix $(printf '%q' "$prefix") "\$@"
EOF_UNINSTALL
chmod +x "$uninstall_launcher.tmp.$$"
mv "$uninstall_launcher.tmp.$$" "$uninstall_launcher"

# The stable app path is now valid and all launchers are in place. Discard the
# rollback copy only after every verification and write succeeds.
if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
    rm -rf -- "$backup_dir"
fi
new_app_installed=0
trap - EXIT HUP INT TERM

version="$(cat "$app_dir/VERSION")"
printf 'Installed JL Mixing Automation %s\n' "$version"
printf 'Application: %s\n' "$app_dir"
printf 'Commands:    %s\n' "$bin_dir"

case ":$PATH:" in
    *":$bin_dir:"*) ;;
    *)
        echo
        echo "Add the command directory to PATH:"
        printf '  export PATH="%s:$PATH"\n' "$bin_dir"
        ;;
esac

echo
echo "Next: new-studio"
