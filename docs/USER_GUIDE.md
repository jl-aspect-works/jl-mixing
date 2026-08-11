# JL Mixing Automation v1.5 User Guide

## 1. Create the workspace

```text
new-studio
```

The default root is `~/Music/Mixes/`. Use `--default-cd` if creation commands
should enter newly created directories automatically. `--cd` and `--no-cd`
override that preference for an individual command.

## 2. Create a client

```text
new-client acme --name "Acme Records"
```

`new-client` may be run from anywhere. Studio-root resolution uses:

1. `--root PATH`
2. `JL_MIXING_ROOT`
3. current-directory studio context
4. `~/Music/Mixes`

A client contains `client.json` and a flattened `Projects/` directory. Audio and
delivery defaults are inherited from `studio.json` unless overridden. An artist
default is optional.

## 3. Create a project and Revision 1

From a client directory or with an explicit client reference:

```text
new-mix "Blue Sky"
new-mix "Blue Sky" --client acme
```

The equivalent `--project "Blue Sky"` form remains supported. When `--artist`
is omitted, the project uses the nonempty `client.defaults.artist` value and
then the client's display name.

`new-mix` creates `04_Revisions/Revision_01/Revision_Notes.md` with the initial
revision description. Use `--source PATH` to copy an initial client delivery into
`01_Client_Files/Original_Delivery/`. Source material is copied, never moved or
modified.

## 4. Validate intake

```text
validate-intake
```

Validation is non-destructive to `01_Client_Files/Original_Delivery/`. The
managed intake report can include:

- file inventory and channel counts
- project-format mismatches
- exact SHA-256 duplicate detection
- corrupt/unreadable-file findings
- `ffprobe` metadata inspection when available
- full-file decode integrity checks through `ffmpeg` when available
- exact dual-mono warnings for stereo files with identical channels
- skipped checks and preparation recommendations

Unavailable external inspection tools are reported as skipped. JL Mixing does
not automatically convert, repair, rename, move, or delete original client
files.

Prepare accepted files manually in `02_Audio_Preparation/Working_Audio/` and
record engineering decisions in `Preparation_Report.md`.

## 5. Work with revisions

Place initial mix prints in:

```text
04_Revisions/Revision_01/
```

When another revision is needed:

```text
new-revision --description "Client notes addressed"
```

Use `--source FILE_OR_DIRECTORY` to copy immediate mix-print files into the new
revision directory. JL Mixing does not add a separate review-package lifecycle.

## 6. Record approval

```text
approve-mix
```

The current revision is approved by default. An older existing revision can be
selected explicitly:

```text
approve-mix --revision 2 --approved-by "Client"
```

Approval updates project metadata only. It does not alter revision files or an
existing final-delivery package.

## 7. Create final delivery

```text
create-delivery
```

The command packages the approved revision, considering immediate regular files
except `Revision_Notes.md`. `--include`, `--exclude`, and `--working-prefix`
control selection. Copied files are SHA-256 verified and recorded in the delivery
manifest.

### ZIP workflow

To include edited delivery notes in a ZIP:

```text
create-delivery
# Edit 05_Final_Delivery/Delivery_Notes.md
create-delivery --zip --overwrite
```

Generated ZIP names use:

```text
<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip
```

### Replacing a delivery

```text
create-delivery --overwrite
```

`--overwrite` is for same-shape replacement and requires the delivered path set
to remain unchanged.

```text
create-delivery --clean
```

`--clean` replaces every file and directory inside the project's
`05_Final_Delivery/`. Review `create-delivery --dry-run --clean` before using it.
Current v1.5 behavior may regenerate delivery-note templates during a clean
rebuild; delivery-note preservation semantics are tracked for a future workflow
revision.

## 8. Machine/API integration

JL Mixing Studio and other machine clients discover Automation with:

```text
jl-mixing system-info --json
```

Automation API `1.0` exposes capability-backed client, project, intake,
revision/approval, delivery, and system-info operations. Machine clients should
use API capabilities instead of parsing human CLI output.

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
boundary but does not interpret or manage native DAW project files.

## Compatibility

v1.5 continues using metadata schema `1.1.0` and supports valid v1.1+
workspaces. It does not migrate v1.0 workspaces. Application, Automation API,
and metadata schema versions are independent contracts.
