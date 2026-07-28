#!/usr/bin/env bash
# Structured Automation API adapter for the shared delivery-creation service.
set -eu

DELIVERY_API_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DELIVERY_API_ROOT="${JL_MIXING_HOME:-$(cd "$DELIVERY_API_DIR/.." && pwd)}"
# shellcheck source=lib/common.sh
. "$DELIVERY_API_ROOT/lib/common.sh"
# shellcheck source=lib/context.sh
. "$DELIVERY_API_ROOT/lib/context.sh"
# shellcheck source=lib/json.sh
. "$DELIVERY_API_ROOT/lib/json.sh"
# shellcheck source=lib/delivery-create.sh
. "$DELIVERY_API_ROOT/lib/delivery-create.sh"

jl_delivery_api_python() {
    local python
    python="${JL_MIXING_PYTHON:-$(command -v python3 || true)}"
    [ -n "$python" ] && [ -x "$python" ] || return "$JL_EXIT_CONFIG"
    printf '%s\n' "$python"
}

jl_delivery_api_version() {
    local file version
    file="${JL_MIXING_API_VERSION_FILE:-$DELIVERY_API_ROOT/API_VERSION}"
    [ -f "$file" ] || return "$JL_EXIT_CONFIG"
    version="$(sed -n '1p' "$file")"
    printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+$' || return "$JL_EXIT_CONFIG"
    printf '%s\n' "$version"
}

jl_delivery_api_emit_error() {
    local python api_version status code exit_code message
    python="$1"; api_version="$2"; status="$3"; code="$4"; exit_code="$5"; message="$6"
    "$python" - "$api_version" "$status" "$code" "$exit_code" "$message" <<'PY'
import json, sys
api_version, status, code, exit_code, message = sys.argv[1:]
print(json.dumps({
  "api_version": api_version,
  "operation": "delivery.create",
  "status": status,
  "data": {},
  "warnings": [],
  "errors": [{"code": code, "message": message.strip(), "details": {"exit_code": int(exit_code)}, "retryable": False}],
}, separators=(",", ":"), sort_keys=True))
PY
}

jl_delivery_create_response() {
    local api_version python json_seen project_seen project_ref dry_run zip_requested mode
    local output_file error_file status project_root manifest delivery_root revision_root approved_revision
    local project_id workspace_path zip_name files_delivered response_status error_code message
    api_version="$(jl_delivery_api_version)" || return "$JL_EXIT_CONFIG"
    python="$(jl_delivery_api_python)" || return "$JL_EXIT_CONFIG"
    json_seen=0; project_seen=0; project_ref=""; dry_run=0; zip_requested=0; mode=default

    args=("$@")
    i=0
    while [ "$i" -lt "${#args[@]}" ]; do
        arg="${args[$i]}"
        case "$arg" in
            --json) json_seen=$((json_seen + 1)) ;;
            --project)
                project_seen=$((project_seen + 1))
                i=$((i + 1))
                [ "$i" -lt "${#args[@]}" ] || {
                    jl_delivery_api_emit_error "$python" "$api_version" error INVALID_REQUEST "$JL_EXIT_ARGUMENTS" "--project requires a value."
                    return "$JL_EXIT_ARGUMENTS"
                }
                project_ref="${args[$i]}"
                ;;
            --dry-run) dry_run=1 ;;
            --zip) zip_requested=1 ;;
            --overwrite) mode=overwrite ;;
            --clean) mode=clean ;;
        esac
        i=$((i + 1))
    done

    if [ "$json_seen" -ne 1 ] || [ "$project_seen" -ne 1 ]; then
        jl_delivery_api_emit_error "$python" "$api_version" error INVALID_REQUEST "$JL_EXIT_ARGUMENTS" \
            "delivery create requires exactly one --json option and one explicit --project PATH."
        return "$JL_EXIT_ARGUMENTS"
    fi

    project_root="$(jl_context_resolve_project_v11 "$project_ref" "$PWD" 2>/dev/null || true)"
    manifest="${project_root:+$project_root/00_Admin/project-manifest.json}"
    delivery_root="${project_root:+$project_root/05_Final_Delivery}"
    approved_revision=""
    project_id=""
    workspace_path=""
    revision_root=""
    if [ -n "$project_root" ] && [ -f "$manifest" ]; then
        approved_revision="$(jl_json_get_optional "$manifest" '.state.approved_revision' '')"
        project_id="$(jl_json_get_optional "$manifest" '.project_id' '')"
        workspace_path="$(dirname "$(dirname "$(dirname "$(dirname "$project_root")")")")"
        if [ -n "$approved_revision" ]; then
            revision_root="$project_root/04_Revisions/$(printf 'Revision_%02d' "$approved_revision")"
        fi
    fi

    output_file="$(mktemp "${TMPDIR:-/tmp}/jl-mixing-delivery-out.XXXXXX")"
    error_file="$(mktemp "${TMPDIR:-/tmp}/jl-mixing-delivery-err.XXXXXX")"
    cleanup_delivery_api() { rm -f -- "$output_file" "$error_file"; }
    trap cleanup_delivery_api EXIT HUP INT TERM

    filtered=()
    for arg in "$@"; do
        [ "$arg" = "--json" ] || filtered+=("$arg")
    done

    set +e
    (jl_delivery_create_command "${filtered[@]}") >"$output_file" 2>"$error_file"
    status=$?
    set -e

    if [ "$status" -eq 0 ]; then
        [ "$dry_run" -eq 1 ] && response_status=planned || response_status=success
        zip_name="$(sed -n 's/^ZIP:[[:space:]]*//p' "$output_file" | head -1)"
        files_delivered="$(sed -n 's/^Files delivered:[[:space:]]*//p' "$output_file" | head -1)"
        [ -n "$files_delivered" ] || files_delivered=0
        "$python" - "$api_version" "$response_status" "$project_id" "$project_root" "$manifest" "$delivery_root" \
            "$revision_root" "${approved_revision:-0}" "$workspace_path" "$mode" "$zip_requested" "$zip_name" "$files_delivered" <<'PY'
import json, sys
(api_version,status,project_id,project_path,manifest_path,delivery_path,revision_path,
 revision,workspace_path,mode,zip_requested,zip_name,files_delivered)=sys.argv[1:]
revision_no=int(revision)
data={
 "project":{"id":project_id,"path":project_path},
 "manifest_path":manifest_path,
 "delivery_path":delivery_path,
 "delivery_notes_path":delivery_path+"/Delivery_Notes.md",
 "delivery_manifest_path":delivery_path+"/delivery-manifest.json",
 "revision":{"number":revision_no,"path":revision_path},
 "workspace_path":workspace_path,
 "replacement_mode":mode,
 "zip_requested":zip_requested=="1",
}
if files_delivered.isdigit() and int(files_delivered) > 0:
 data["files_delivered"]=int(files_delivered)
if zip_name:
 data["zip_path"]=delivery_path+"/"+zip_name
if status=="planned":
 data["would_update"]=[manifest_path,delivery_path]
print(json.dumps({"api_version":api_version,"operation":"delivery.create","status":status,
 "data":data,"warnings":[],"errors":[]},separators=(",",":"),sort_keys=True))
PY
        trap - EXIT HUP INT TERM
        cleanup_delivery_api
        return 0
    fi

    message="$(cat "$error_file")"
    [ -n "$message" ] || message="Delivery creation failed."
    case "$status" in
        2) response_status=error; error_code=INVALID_REQUEST ;;
        3) response_status=error; error_code=CONFIGURATION_ERROR ;;
        4) response_status=error; error_code=WORKSPACE_CONTEXT_ERROR ;;
        5) response_status=blocked; error_code=DELIVERY_VALIDATION_FAILED ;;
        6) response_status=blocked; error_code=UNSAFE_OPERATION ;;
        *) response_status=error; error_code=INTERNAL_ERROR ;;
    esac
    if printf '%s' "$message" | grep -Eqi 'must be approved|approved revision'; then
        error_code=REVISION_NOT_APPROVED
    elif printf '%s' "$message" | grep -Eqi 'overwrite|already exists|replacement'; then
        error_code=DELIVERY_REPLACEMENT_REQUIRED
    elif printf '%s' "$message" | grep -Eqi 'unsafe|refus|clean'; then
        error_code=UNSAFE_DELIVERY_OPERATION
    fi
    jl_delivery_api_emit_error "$python" "$api_version" "$response_status" "$error_code" "$status" "$message"
    trap - EXIT HUP INT TERM
    cleanup_delivery_api
    return "$status"
}
