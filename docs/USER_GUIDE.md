# JL Mixing Automation v1.3 User Guide

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
delivery defaults are inherited from `studio.json` unless overridden. An artist
default is optional.

## 3. Create a project and Revision 1

From the client directory:

```bash
new-mix "Blue Sky"
```

The equivalent explicit form remains supported:

```bash
new-mix --project "Blue Sky"
```

When `--artist` is omitted, the project uses the nonempty
`client.defaults.artist` value and then the client's display name. An explicit
nonempty `--artist` overrides both; an explicit empty value is rejected.

`new-mix` creates `04_Revisions/Revision_01/Revision_Notes.md` with the
description `Initial mix`. The new project starts in the existing `In progress`
state with Revision 1 unapproved.

Use `--source PATH` to copy an initial delivery into
`01_Client_Files/Original_Delivery/`. The source is copied, never moved or
modified. It is not copied into Revision 1. The project is created directly
beneath the client's `Projects/` directory and keeps the same path for its
entire lifetime.

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

## 5. Work with revisions

Place the initial mix prints directly in:

```text
04_Revisions/Revision_01/
```

Send those files to the client using the studio's normal review process. When a
later revision is needed, run:

```bash
new-revision --description "Client notes addressed"
```

Use `--source FILE_OR_DIRECTORY` to copy immediate mix-print files into the new
`Revision_NN/` directory. Files can also be placed there manually after
creation. JL Mixing does not add a separate review-packaging command.

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

### Create a ZIP with completed delivery notes

Use this two-step workflow:

```bash
create-delivery
# Edit 05_Final_Delivery/Delivery_Notes.md
create-delivery --zip --overwrite
```

The first command creates an editable delivery folder. The second rebuilds the
same delivery and creates a ZIP containing the edited `Delivery_Notes.md`.

ZIP filenames identify the delivered revision and creation time:

```text
<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip
```

The revision is zero-padded and the timestamp uses the computer's local timezone. For example:
`blue-sky-rev-01-20260724153045.zip`. Each generated archive has a unique,
traceable name; earlier generated archives are not nested inside later ones.

`--overwrite` requires the delivered path set to remain unchanged. File contents
may change, but adding, removing, or renaming delivered paths causes overwrite
to fail. A one-step `create-delivery --zip` contains the clean notes template
because the ZIP is created before the user has an opportunity to edit it.

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
content. Preserve edited notes before using it. Use `--dry-run --clean` to review
the exact deletion plan first.

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

v1.2 continues using v1.1 workspace schemas and supports valid v1.1 workspaces.
It does not migrate v1.0 workspaces. Commands stop before modifying a workspace
that uses a v1.0 schema or recognizable v1.0 layout.
