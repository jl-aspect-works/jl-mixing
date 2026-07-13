#!/usr/bin/env bash
# Text/JSON template rendering and managed Markdown section replacement.
#
# Python is used for literal replacement and escaping so user values cannot
# corrupt JSON or be interpreted as regular expressions.
if [ "${JL_MIXING_TEMPLATES_LOADED:-0}" = "1" ]; then
    return 0 2>/dev/null || exit 0
fi
JL_MIXING_TEMPLATES_LOADED=1

JL_TEMPLATES_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$JL_TEMPLATES_LIB_DIR/common.sh"
# shellcheck source=lib/filesystem.sh
. "$JL_TEMPLATES_LIB_DIR/filesystem.sh"

# Render a text template from TOKEN/VALUE pairs without overwriting output.
jl_template_render() {
    local template_file output_file temp_file
    template_file="$1"
    output_file="$2"
    shift 2

    [ -f "$template_file" ] || {
        jl_error "Template not found: $template_file"
        return "$JL_EXIT_VALIDATION"
    }
    if [ $(( $# % 2 )) -ne 0 ]; then
        jl_error "Template values must be supplied as TOKEN VALUE pairs."
        return "$JL_EXIT_ARGUMENTS"
    fi
    jl_require_command python3 "Python 3 is required for template rendering." || return $?
    jl_fs_assert_mutable_path "$output_file" || return $?

    temp_file="$(jl_mktemp_file_near "$output_file")" || return $?
    if ! python3 - "$template_file" "$temp_file" "${JL_TEMPLATE_ALLOW_UNRESOLVED:-0}" "$@" <<'PY_TEMPLATE'
from pathlib import Path
import re
import sys

template_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
allow_unresolved = sys.argv[3] == "1"
values = sys.argv[4:]

# Apply literal replacements; values are never interpreted as regex patterns.
text = template_path.read_text()
for index in range(0, len(values), 2):
    token = values[index]
    value = values[index + 1]
    text = text.replace("{{" + token + "}}", value)

# Reject forgotten tokens unless the caller explicitly permits a staged render.
unresolved = sorted(set(re.findall(r"\{\{[A-Z0-9_]+\}\}", text)))
if unresolved and not allow_unresolved:
    print("Unresolved template tokens: " + ", ".join(unresolved), file=sys.stderr)
    raise SystemExit(5)

output_path.write_text(text)
PY_TEMPLATE
    then
        rm -f "$temp_file"
        jl_error "Template rendering failed: $template_file"
        return "$JL_EXIT_VALIDATION"
    fi

    if [ -e "$output_file" ]; then
        rm -f "$temp_file"
        jl_error "Refusing to overwrite existing output: $output_file"
        return "$JL_EXIT_UNSAFE"
    fi

    mkdir -p "$(dirname "$output_file")"
    chmod 644 "$temp_file"
    mv "$temp_file" "$output_file"
}

# Replace exactly one marked Markdown region while preserving human text.
jl_markdown_replace_managed_section() {
    local markdown_file begin_marker end_marker replacement_file temp_file
    markdown_file="$1"
    begin_marker="$2"
    end_marker="$3"
    replacement_file="$4"

    [ -f "$markdown_file" ] || {
        jl_error "Markdown file not found: $markdown_file"
        return "$JL_EXIT_VALIDATION"
    }
    [ -f "$replacement_file" ] || {
        jl_error "Replacement content not found: $replacement_file"
        return "$JL_EXIT_VALIDATION"
    }
    jl_fs_assert_mutable_path "$markdown_file" || return $?

    temp_file="$(jl_mktemp_file_near "$markdown_file")" || return $?
    if ! python3 - "$markdown_file" "$replacement_file" "$begin_marker" "$end_marker" "$temp_file" <<'PY_MANAGED'
from pathlib import Path
import sys

markdown_path = Path(sys.argv[1])
replacement_path = Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]
output_path = Path(sys.argv[5])

# Preserve all content outside the single explicitly managed marker pair.
text = markdown_path.read_text()
replacement = replacement_path.read_text().strip("\n")

if text.count(begin) != 1 or text.count(end) != 1:
    print("Managed-section markers must each appear exactly once.", file=sys.stderr)
    raise SystemExit(5)

# Splice only the marker interior, retaining the marker lines themselves.
start = text.index(begin) + len(begin)
finish = text.index(end, start)
new_text = text[:start] + "\n\n" + replacement + "\n\n" + text[finish:]
output_path.write_text(new_text)
PY_MANAGED
    then
        rm -f "$temp_file"
        jl_error "Managed Markdown update failed: $markdown_file"
        return "$JL_EXIT_VALIDATION"
    fi

    chmod "$(jl_stat_mode "$markdown_file")" "$temp_file"
    mv "$temp_file" "$markdown_file"
}

# Render a JSON text template while escaping replacement values as JSON string
# contents. Templates used with this function must place tokens inside quotes.
# Render JSON-safe token values, parse the result, and write it atomically.
jl_template_render_json() {
    local template_file output_file temp_file allow_unresolved
    template_file="$1"
    output_file="$2"
    shift 2

    [ -f "$template_file" ] || {
        jl_error "Template not found: $template_file"
        return "$JL_EXIT_VALIDATION"
    }
    if [ $(( $# % 2 )) -ne 0 ]; then
        jl_error "Template values must be supplied as TOKEN VALUE pairs."
        return "$JL_EXIT_ARGUMENTS"
    fi
    jl_require_command python3 "Python 3 is required for JSON template rendering." || return $?
    jl_fs_assert_mutable_path "$output_file" || return $?

    if [ -e "$output_file" ]; then
        jl_error "Refusing to overwrite existing output: $output_file"
        return "$JL_EXIT_UNSAFE"
    fi

    temp_file="$(jl_mktemp_file_near "$output_file")" || return $?
    allow_unresolved="${JL_TEMPLATE_ALLOW_UNRESOLVED:-0}"
    if ! python3 - "$template_file" "$temp_file" "$allow_unresolved" "$@" <<'PY_JSON_TEMPLATE'
from pathlib import Path
import json
import re
import sys

template_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
allow_unresolved = sys.argv[3] == "1"
values = sys.argv[4:]
text = template_path.read_text()

# JSON-escape string contents before placing values inside quoted tokens.
for index in range(0, len(values), 2):
    token = values[index]
    value = values[index + 1]
    escaped_content = json.dumps(value, ensure_ascii=False)[1:-1]
    text = text.replace("{{" + token + "}}", escaped_content)

unresolved = sorted(set(re.findall(r"\{\{[A-Z0-9_]+\}\}", text)))
if unresolved and not allow_unresolved:
    print("Unresolved template tokens: " + ", ".join(unresolved), file=sys.stderr)
    raise SystemExit(5)

# Parse before writing so malformed templates never reach the repository.
json.loads(text)
output_path.write_text(text)
PY_JSON_TEMPLATE
    then
        rm -f "$temp_file"
        jl_error "JSON template rendering failed: $template_file"
        return "$JL_EXIT_VALIDATION"
    fi

    mkdir -p "$(dirname "$output_file")"
    chmod 644 "$temp_file"
    mv "$temp_file" "$output_file"
}
