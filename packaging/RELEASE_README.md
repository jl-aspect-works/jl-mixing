# JL Mixing Automation v1.3

JL Mixing Automation creates repeatable professional mixing project workspaces,
tracks revision approval, and builds SHA-256-verified final-delivery packages.

## Requirements

- Bash 3.2 or newer
- Python 3.10 or newer
- `jq`
- Optional: `ffprobe` for enhanced intake reporting

## Install

```bash
./install.sh
```

Default locations:

```text
Application: ~/.local/share/jl-mixing/
Commands:    ~/.local/bin/
```

The installer configures one managed `.zshrc` or `.bashrc` block so no separate
PATH or wrapper setup is required. Open a new Terminal tab after installation.
Use `./install.sh --no-shell-integration` to opt out of startup-file changes.

## Start

```bash
new-studio
```

The default workspace is `~/Music/Mixes/`. v1.3 supports valid v1.1 workspaces
and does not migrate v1.0 workspaces. New records retain the v1.1.0 metadata
schema while recording the v1.3 application release in `created_with`.

## Workflow

```text
new-studio → new-client → new-mix (creates Revision_01) → validate-intake
→ manual mix/review → approve-mix → create-delivery
```

Use `new-revision` for later revisions. `new-mix PROJECT_NAME` and
`new-mix --project PROJECT_NAME` are both supported.

For a ZIP with completed delivery notes:

```text
create-delivery
edit 05_Final_Delivery/Delivery_Notes.md
create-delivery --zip --overwrite
```

Generated ZIPs use
`<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip`, with a zero-padded revision and
local timestamp.

`create-delivery --clean` deletes and replaces all contents inside the selected
project's `05_Final_Delivery/` directory.

## Automation API discovery

Supported machine clients use:

```bash
jl-mixing system-info --json
```

The JSON response reports the independent Automation API version, application
release, metadata schema compatibility, implemented capabilities, and bundled
schema path. API compatibility must be determined from `api_version` and
`capabilities`, not from the application release number.

## Upgrade and uninstall

Run the new release's `install.sh` to upgrade transactionally. Workspaces are
not modified.

```bash
jl-mixing-uninstall
```

See `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` for complete details.
