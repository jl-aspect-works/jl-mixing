#!/usr/bin/env bash
# Reusable fixtures for command-level integration tests.
#
# Every fixture is created under a temporary studio root; tests never touch the
# user's real JL Mixing workspace.
set -eu

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/test-helper.sh
. "$ROOT/tests/test-helper.sh"

export JL_MIXING_HOME="$ROOT"

# Create a minimal valid studio workspace for an integration test.
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
        "$ROOT/tests/fixtures/legacy-v1.0.4/studio.json" > "$studio_root/Studio/studio.json"
}

# Create a valid Acme client beneath a fixture studio.
fixture_client() {
    local studio_root client_root
    studio_root="$1"
    client_root="$studio_root/Clients/Acme"
    mkdir -p "$client_root/Projects/Active" "$client_root/Projects/Completed"
    cp "$ROOT/tests/fixtures/legacy-v1.0.4/client.json" "$client_root/client.json"
    printf '%s\n' "$client_root"
}

# Create a project fixture in the requested workflow state.
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
                .revisions=[]' "$ROOT/tests/fixtures/legacy-v1.0.4/project-manifest.json" > "$manifest"
            ;;
        open1)
            jq '.state={status:"active",current_revision:1,approved:false,approved_revision:null,
                approved_at:null,approved_by:"",delivered:false,delivered_at:null,completed_at:null} |
                .revisions[0].status="open"' "$ROOT/tests/fixtures/legacy-v1.0.4/project-manifest.json" > "$manifest"
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
                ]' "$ROOT/tests/fixtures/legacy-v1.0.4/project-manifest.json" > "$manifest"
            mkdir -p "$project_root/04_Revisions/Revision_01/Prints" "$project_root/04_Revisions/Revision_02/Prints"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_01/Revision_Notes.md"
            cp "$ROOT/templates/revision/Revision_Notes.md" "$project_root/04_Revisions/Revision_02/Revision_Notes.md"
            ;;
        approved1|delivered1)
            cp "$ROOT/tests/fixtures/legacy-v1.0.4/project-manifest.json" "$manifest"
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

# Generate a small valid 48 kHz, 24-bit stereo WAV fixture.
fixture_wav() {
    local path
    path="$1"
    python3 - "$path" <<'PY_WAV'
import sys
import wave
from pathlib import Path

# Generate a tiny silent file; audio content is irrelevant to workflow tests.
path = Path(sys.argv[1])
path.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(path), "wb") as output:
    output.setnchannels(2)
    output.setsampwidth(3)
    output.setframerate(48000)
    # A 24-bit stereo frame contains two signed three-byte samples.
    silent_frame = (0).to_bytes(3, "little", signed=True) * 2
    output.writeframes(silent_frame * 480)
PY_WAV
}

# Create a complete canonical v1.1 project in Setup state without invoking the
# slower project-creation command. Revision-workflow tests use this fixture to
# focus on the commands under test while still validating every governing JSON
# document and standard directory boundary.
fixture_v11_project() {
    local studio_root client_root project_root manifest
    studio_root="$1"
    client_root="$studio_root/Clients/Acme Records"
    project_root="$client_root/Projects/Blue Sky"

    mkdir -p \
        "$studio_root/Studio" \
        "$client_root/Projects" \
        "$project_root/00_Admin" \
        "$project_root/01_Client_Files/Original_Delivery" \
        "$project_root/01_Client_Files/References" \
        "$project_root/01_Client_Files/Documentation" \
        "$project_root/02_Audio_Preparation/Working_Audio" \
        "$project_root/02_Audio_Preparation/Rejected_Files" \
        "$project_root/03_DAW_Project" \
        "$project_root/04_Revisions" \
        "$project_root/05_Final_Delivery/Stems" \
        "$project_root/06_Recall/External_Files" \
        "$project_root/06_Recall/Screenshots"

    jq --arg root "$studio_root" '.root_path=$root' \
        "$ROOT/examples/studio.json" > "$studio_root/Studio/studio.json"
    cp "$ROOT/examples/client.json" "$client_root/client.json"
    cp "$ROOT/examples/client-profile-snapshot.json" \
        "$project_root/00_Admin/client-profile-snapshot.json"
    manifest="$project_root/00_Admin/project-manifest.json"
    jq '.state={current_revision:0,approved_revision:null,delivered_revision:null} |
        .revisions=[]' "$ROOT/examples/project-manifest.json" > "$manifest"

    cp "$ROOT/templates/Intake_Report.md" "$project_root/00_Admin/Intake_Report.md"
    cp "$ROOT/templates/Project_Notes.md" "$project_root/00_Admin/Project_Notes.md"
    cp "$ROOT/templates/Preparation_Report.md" \
        "$project_root/02_Audio_Preparation/Preparation_Report.md"
    cp "$ROOT/templates/Delivery_Notes.md" \
        "$project_root/05_Final_Delivery/Delivery_Notes.md"
    cp "$ROOT/templates/Recall_Sheet.md" "$project_root/06_Recall/Recall_Sheet.md"

    printf '%s\n' "$project_root"
}
