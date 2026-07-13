# JL Mixing Automation
## Design Specification v1.0

## Purpose

JL Mixing Automation manages the filesystem and workflow around professional
audio projects. The DAW remains responsible for its own project contents.

## Design principles

- Pay-as-you-go complexity with useful defaults.
- One authoritative source for each type of information.
- Immutable client originals.
- Safe, atomic, script-managed state changes.
- Context-aware commands with explicit options taking precedence.
- Thin command wrappers with reusable logic in `lib/`.
- Human-authored Markdown remains under human control.

## Product identity

- Product name: **JL Mixing Automation**
- Software and repository identifier: `jl-mixing`
- Metadata string: `jl-mixing <version>`
- Default workspace: `~/Music/JL Mixing`

## Studio workspace

```text
~/Music/JL Mixing/
├── Clients/
├── DAWs/
└── Studio/
```

`new-studio` uses Logic Pro as the Version 1.0 built-in default DAW while the
architecture remains DAW-agnostic.

## Client structure

```text
Clients/<Client Name>/
├── client.json
└── Projects/
    ├── Active/
    └── Completed/
```

## Project structure

```text
<Project Name>/
├── 00_Admin/
│   ├── project-manifest.json
│   ├── client-profile-snapshot.json
│   ├── Intake_Report.md
│   └── Project_Notes.md
├── 01_Client_Files/
│   ├── Original_Delivery/
│   ├── References/
│   └── Documentation/
├── 02_Audio_Preparation/
│   ├── Working_Audio/
│   ├── Rejected_Files/
│   └── Preparation_Report.md
├── 03_DAW_Project/
│   └── Project/
├── 04_Revisions/
│   └── Revision_XX/
│       ├── Revision_Notes.md
│       └── Prints/
├── 05_Final_Delivery/
│   ├── Stems/
│   ├── Delivery_Notes.md
│   └── delivery-manifest.json
└── 06_Recall/
    ├── Recall_Sheet.md
    ├── External_Files/
    └── Screenshots/
```

## Folder responsibilities

### Client originals

`01_Client_Files/Original_Delivery/` is immutable. Commands must not rename,
convert, move, overwrite, or delete its contents.

### Audio preparation

Audio preparation is manual in Version 1.0. Engineers populate
`02_Audio_Preparation/Working_Audio/` and maintain `Preparation_Report.md`.
Rejected files may be copied into `Rejected_Files/`; originals remain intact.

### DAW boundary

`03_DAW_Project/Project/` is opaque DAW-owned content. Automation may create,
copy, launch, or move this boundary but must not interpret its internals.

### Revisions

Revision folders are created only by `new-revision`. Status values are:

```text
open
approved
superseded
```

Approving a revision changes any previously approved revision to `superseded`.
There is no `Superseded/` directory and no `Revision_Log.md`.

### Delivery

`create-delivery` prepares and validates the package.
`create-delivery --mark-delivered` records that the package was actually sent.

## Data ownership

Machine-owned:

- `studio.json`
- `client.json`
- `project-manifest.json`
- `delivery-manifest.json`

Human-owned after creation:

- `Project_Notes.md`
- `Revision_Notes.md`
- `Preparation_Report.md`
- `Delivery_Notes.md`
- `Recall_Sheet.md`

Mixed ownership:

- `Intake_Report.md`, with an explicitly delimited managed section.

## Project metadata

All JSON documents include:

```json
{
  "metadata": {
    "schema": "<schema name>",
    "schema_version": "1.0.0",
    "document_id": "<UUID>",
    "created_by": "<command>",
    "created_with": "jl-mixing 1.0.0",
    "created_at": "<ISO-8601 timestamp>",
    "last_modified_at": "<ISO-8601 timestamp>"
  }
}
```

Schema versions use semantic versioning. Unsupported major versions are rejected.

## Project identity and type

The canonical name field is `project_name`; command syntax uses:

```bash
new-mix --project "Blue Sky"
```

Optional `project_type` values are:

```text
mixing
podcast
audiobook
dialogue_edit
live_recording
other
```

## Naming tokens

All templates use `{{PROJECT_NAME}}`, never `{{SONG_TITLE}}`.

## Core commands

```text
new-studio
new-client
new-mix
validate-intake
new-revision
approve-mix
create-delivery
complete-project
```

## Validation

Validation order:

1. JSON syntax
2. JSON Schema Draft 2020-12
3. Business rules

Version 1.0 uses Python 3 and an application-private virtual environment with a
pinned `jsonschema` dependency. `ffprobe` is optional and enables enhanced audio
inspection.

## Installation and distribution

End users install versioned `.tar.gz` packages. Git is not required.

Default paths:

```text
~/.local/share/jl-mixing/
~/.local/bin/
```

Installation never creates or modifies the studio workspace.

## Deferred features

- Billing and contracts
- Automatic backups and cloud synchronization
- Multi-user support
- DAW parsing
- Automatic destructive audio conversion
- Database storage
- Plug-in management
- Advanced reporting
