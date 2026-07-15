# JL Mixing Automation v1.1 User Guide

## 1. Create the workspace

```bash
new-studio
```

The default root is `~/Music/Mixes/`. Use `--default-cd` if creation commands
should enter newly created directories automatically. `--cd` and `--no-cd`
override that preference for an individual command.

## 2. Create a client

```bash
new-client acme --name "Acme Records"
```

A client contains `client.json` and a flattened `Projects/` directory. Audio and
delivery defaults are inherited from `studio.json` unless overridden.

## 3. Create a project

From the client directory:

```bash
new-mix --project "Blue Sky" --artist "Example Artist"
```

Use `--source PATH` to copy an initial delivery into
`01_Client_Files/Original_Delivery/`. The source is copied, never moved or
modified. The project is created directly beneath the client's `Projects/`
directory and keeps the same path for its entire lifetime.

## 4. Validate intake

```bash
validate-intake
```

The command recursively inventories the original delivery, preserves v1.0.4's
recognized-extension and duplicate-basename behavior, and uses `ffprobe`
opportunistically when available. It updates only the managed section in
`00_Admin/Intake_Report.md`; text outside the markers is preserved.

Prepare accepted files manually in `02_Audio_Preparation/Working_Audio/` and
record engineering decisions in `Preparation_Report.md`.

## 5. Create a revision

```bash
new-revision --description "Initial mix"
```

Use `--source FILE_OR_DIRECTORY` to copy immediate mix-print files into the new
`Revision_NN/` directory. Files can also be placed there manually after
creation. Send the revision files to the client using the studio's normal review
process; JL Mixing does not add a separate review-packaging command.

## 6. Record approval

```bash
approve-mix
```

The current revision is approved by default. An older existing revision can be
selected explicitly:

```bash
approve-mix --revision 2 --approved-by "Client"
```

Approval updates project metadata only. It does not copy files or alter the
existing final-delivery package.

## 7. Create final delivery

```bash
create-delivery
```

The command always packages the approved revision. It considers every immediate
regular file except `Revision_Notes.md`; there is no extension allowlist.
`--include`, `--exclude`, and `--working-prefix` control selection.

Recognized naming phrases are classified on a best-effort basis. Unmatched files
use `unclassified` and remain valid deliverables. Only files recognized as stems
are placed beneath `05_Final_Delivery/Stems/`.

Each copied file is verified by comparing source and staged SHA-256 values. The
final manifest records the destination-relative path, classification, size, and
SHA-256.

### Replacing a delivery

```bash
create-delivery --overwrite
```

`--overwrite` is for same-shape replacement and preserves unrelated content.
It fails if old tracked files would become stale.

```bash
create-delivery --clean
```

`--clean` is intentionally destructive. It replaces **every file and directory**
inside the project's `05_Final_Delivery/`, including untracked and user-added
content. Use `--dry-run --clean` to review the exact deletion plan first.

Use `--zip` to create `<project-id>-delivery.zip`. The ZIP recursively includes
the complete final-delivery directory except the ZIP itself.

## Directory layout

```text
~/Music/Mixes/
├── Studio/studio.json
└── Clients/<Client>/
    ├── client.json
    └── Projects/<Project>/
        ├── 00_Admin/
        ├── 01_Client_Files/
        ├── 02_Audio_Preparation/
        ├── 03_DAW_Project/
        ├── 04_Revisions/Revision_NN/
        ├── 05_Final_Delivery/
        └── 06_Recall/
```

`03_DAW_Project/` is opaque user/DAW-owned content. JL Mixing creates the
boundary but does not interpret, clean, or manage native DAW project files.

## v1.0 compatibility

v1.1 does not migrate v1.0 workspaces. Create a new v1.1 workspace and copy only
user-owned materials such as original client deliveries and notes. Commands stop
before modifying a workspace that uses a v1.0 schema or recognizable v1.0 layout.
