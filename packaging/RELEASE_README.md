# JL Mixing Automation v1.5

JL Mixing Automation creates repeatable mixing-project workspaces, manages
revision approval, validates intake, and builds SHA-256-verified final-delivery
packages.

## Install

### Windows

Extract `jl-mixing-<version>-windows.zip`, then run:

```powershell
.\windows\install.ps1
```

The package contains its private runtime. No separate Python, Bash, or jq install
is required. The default prefix is:

```text
%LOCALAPPDATA%\Programs\JL Mixing
```

Open a new PowerShell session after installation.

### macOS

Extract `jl-mixing-<version>-macos.tar.gz`, then run:

```bash
./macos/install.sh
```

The package contains its private runtime. The default prefix is `~/.local`.
Open a new Terminal tab after installation so managed shell integration is
active.

### Linux/source compatibility path

Extract the Linux archive and run:

```bash
./install.sh
```

This path requires Bash, Python 3.10+ with `venv`, and jq.

Optional external `ffprobe`/`ffmpeg` tools enable enhanced intake QC. Checks that
cannot run are reported as skipped.

## Start

```text
new-studio
new-client acme --name "Acme Records"
new-mix "Blue Sky" --client acme
```

The default workspace is `~/Music/Mixes/`. `new-client` can run outside a studio
context; root resolution is `--root`, then `JL_MIXING_ROOT`, then current studio
context, then the default workspace.

## Workflow

```text
new-studio -> new-client -> new-mix -> validate-intake
-> manual mix/review -> new-revision as needed -> approve-mix -> create-delivery
```

For a ZIP with completed delivery notes:

```text
create-delivery
edit 05_Final_Delivery/Delivery_Notes.md
create-delivery --zip --overwrite
```

Generated ZIPs use `<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip`.
`create-delivery --clean` replaces all contents inside the selected project's
`05_Final_Delivery/` directory; use its dry-run mode before destructive cleanup.

## Automation API

Machine clients use:

```text
jl-mixing system-info --json
```

Automation API `1.0` reports the application version, readable/writable metadata
schema versions, installed schema path, and supported capabilities. Application,
API, and metadata schema versions are independent contracts.

## Compatibility

- Automation API: `1.0`
- metadata schema: `1.1.0`
- valid v1.1+ workspaces remain supported
- no v1.0 workspace migration

## Uninstall

Windows: run the included `windows\uninstall.ps1` from the package/application
installation path as documented in the Installation Guide.

macOS: run the packaged `macos/uninstall.sh` or installed managed uninstaller as
documented for the selected prefix.

Uninstall removes JL Mixing-managed application files and shell integration but
preserves user workspaces and project content.

See `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` for complete details.
