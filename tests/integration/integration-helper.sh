#!/usr/bin/env bash
# Shared fixture builders for command integration tests.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/test-helper.sh
. "$ROOT/tests/test-helper.sh"

export JL_MIXING_HOME="$ROOT"

fixture_studio() {
    local studio_root
    studio_root="$1"
    mkdir -p \
        "$studio_root/Studio" \
        "$studio_root/Clients" \
        "$studio_root/DAWs/Logic Pro/Mix Templates" \
        "$studio_root/DAWs/Logic Pro/Presets"
    jq --arg root "$studio_root" \
        '.workspace_root=$root | .default_mix_engineer="Jake"' \
        "$ROOT/examples/studio.json" > "$studio_root/Studio/studio.json"
}

fixture_client() {
    local studio_root client_root
    studio_root="$1"
    client_root="$studio_root/Clients/Acme"
    mkdir -p "$client_root/Projects/Active" "$client_root/Projects/Completed"
    cp "$ROOT/examples/client.json" "$client_root/client.json"
    printf '%s\n' "$client_root"
}

fixture_project() {
    local studio_root mode client_root project_root manifest timestamp
    studio_root="$1"
    mode="${2:-fresh}"
    client_root="$(fixture_client "$studio_root")"
    project_root="$client_root/Projects/Active/Blue Sky"
    timestamp="2026-07-13T12:00:00Z"

    mkdir -p \
        "$project_root/00_Admin" \
        "$project_root/01_Client_Files/Original_Delivery" \
        "$project_root/01_Client_Files/References" \
        "$project_root/01_Client_Files/Documentation" \
        "$project_root/02_Audio_Preparation/Working_Audio" \
        "$project_root/02_Audio_Preparation/Rejected_Files" \
        "$project_root/03_DAW_Project/Project" \
        "$project_root/04_Revisions" \
        "$project_root/05_Final_Delivery/Stems" \
        "$project_root/06_Recall/External_Files" \
        "$project_root/06_Recall/Screenshots"

    cp "$client_root/client.json" "$project_root/00_Admin/client-profile-snapshot.json"
    cp "$ROOT/templates/project/Intake_Report.md" "$project_root/00_Admin/Intake_Report.md"
    cp "$ROOT/templates/project/Delivery_Notes.md" "$project_root/05_Final_Delivery/Delivery_Notes.md"
    manifest="$project_root/00_Admin/project-manifest.json"

    case "$mode" in
        fresh)
            jq '.state={status:"active",current_revision:0,approved:false,approved_revision:null,
                approved_at:null,approved_by:"",delivered:false,delivered_at:null,completed_at:null} |
                .revisions=[]' "$ROOT/examples/project-manifest.json" > "$manifest"
            ;;
        open1)
            jq '.state={status:"active",current_revision:1,approved:false,approved_revision:null,
                approved_at:null,approved_by:"",delivered:false,delivered_at:null,completed_at:null} |
                .revisions[0].status="open"' "$ROOT/examples/project-manifest.json" > "$manifest"
            mkdir -p "$project_root/04_Revisions/Revision_01/Prints"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_01/Revision_Notes.md"
            ;;
        two-revisions)
            jq --arg timestamp "$timestamp" '
                .state={status:"active",current_revision:2,approved:true,approved_revision:1,
                    approved_at:$timestamp,approved_by:"Client",delivered:false,delivered_at:null,completed_at:null} |
                .revisions = [
                    .revisions[0],
                    {number:2,revision_id:"66666666-6666-4666-8666-666666666666",
                     created_at:$timestamp,created_by:"new-revision",description:"Second mix",
                     status:"open",folder:"04_Revisions/Revision_02"}
                ]' "$ROOT/examples/project-manifest.json" > "$manifest"
            mkdir -p "$project_root/04_Revisions/Revision_01/Prints" "$project_root/04_Revisions/Revision_02/Prints"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_01/Revision_Notes.md"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_02/Revision_Notes.md"
            ;;
        approved1|delivered1)
            cp "$ROOT/examples/project-manifest.json" "$manifest"
            mkdir -p "$project_root/04_Revisions/Revision_01/Prints"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_01/Revision_Notes.md"
            if [ "$mode" = delivered1 ]; then
                jq --arg timestamp "$timestamp" \
                    '.state.delivered=true | .state.delivered_at=$timestamp' \
                    "$manifest" > "$manifest.tmp"
                mv "$manifest.tmp" "$manifest"
            fi
            ;;
        *) fail "Unknown project fixture mode: $mode" ;;
    esac

    printf '%s\n' "$project_root"
}

fixture_wav() {
    local path
    path="$1"
    python3 - "$path" <<'PY_WAV'
import sys
import wave
from pathlib import Path

path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(path), "wb") as output:
    output.setnchannels(2)
    output.setsampwidth(3)
    output.setframerate(48000)
    silent_frame = (0).to_bytes(3, "little", signed=True) * 2
    output.writeframes(silent_frame * 480)
PY_WAV
}
