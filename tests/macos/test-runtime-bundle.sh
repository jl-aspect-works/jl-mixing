#!/usr/bin/env bash
set -eu

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
runtime="$ROOT/runtime/python"

[ -x "$runtime" ] || { echo "[FAIL] bundled macOS runtime exists" >&2; exit 1; }

tmp="$(mktemp -d "${TMPDIR:-/tmp}/jl-mixing-macos-runtime.XXXXXX")"
cleanup() { rm -rf -- "$tmp"; }
trap cleanup EXIT HUP INT TERM

old_pythonpath="${PYTHONPATH-}"
unset PYTHONPATH
export JL_MIXING_HOME="$ROOT"

"$runtime" -m jl_mixing.cli system-info --json > "$tmp/system-info.json"
python3 - "$tmp/system-info.json" <<'PY'
import json
from pathlib import Path
import sys
obj = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert obj['api_version'] == '1.0'
assert obj['application']['name'] == 'jl-mixing'
PY
echo "[PASS] bundled runtime reports API discovery"

"$runtime" -m jl_mixing.new_studio_cli --help > "$tmp/help.txt"
grep -q '^Usage:' "$tmp/help.txt"
echo "[PASS] bundled runtime executes human CLI"

if "$runtime" -m jl_mixing.not_a_command >/dev/null 2>&1; then
    echo "[FAIL] bundled runtime rejects unsupported module" >&2
    exit 1
fi
echo "[PASS] bundled runtime rejects unsupported module"

if [ -n "$old_pythonpath" ]; then export PYTHONPATH="$old_pythonpath"; else unset PYTHONPATH; fi

echo "[OK] macOS bundled runtime"
