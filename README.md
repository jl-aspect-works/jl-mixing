# JL Mixing Automation

JL Mixing Automation v1.5 is a cross-platform workflow engine for professional
mixing projects. It creates consistent workspaces, preserves original client
files, manages revisions and approval, validates intake, and builds verified
final-delivery packages.

The authoritative v1.5 runtime is Python and is shared across Windows and macOS.
The Automation API remains version `1.0`, while workspace metadata schemas remain
version `1.1.0`.

## Workflow

```text
new-studio
  -> new-client
  -> new-mix (creates Revision_01)
  -> validate-intake
  -> work in and send the current revision
  -> new-revision when needed
  -> approve-mix
  -> create-delivery
```

The default workspace is `~/Music/Mixes/`. Projects live directly beneath
`Clients/<Client>/Projects/<Project>/`; there are no `Active/` or `Completed/`
directories.

## Installation

### Windows

Download and extract the Windows ZIP, then run the included PowerShell installer:

```powershell
.\windows\install.ps1
```

The Windows package includes its private Python runtime. End users do not need to
install Python, Bash, or jq separately. The default installation is beneath:

```text
%LOCALAPPDATA%\Programs\JL Mixing\
```

Open a new PowerShell session after installation so the managed PATH and shell
integration are active.

### macOS

Download and extract the macOS archive, then run:

```bash
./macos/install.sh
```

The macOS package includes its private Python runtime. End users do not need a
separate Python or jq installation. The default prefix is `~/.local`.

### Linux and source/developer installs

The Linux/source installer remains the compatibility path:

```bash
./install.sh
```

It requires Bash, Python 3.10+ with `venv`, and jq. See
[`docs/INSTALLATION_GUIDE.md`](docs/INSTALLATION_GUIDE.md) for platform-specific
details and custom-prefix options.

`ffprobe`/`ffmpeg` are optional external tools used for enhanced audio intake QC.
When unavailable, affected checks are reported as skipped rather than silently
assumed to have passed.

## Start

```bash
new-studio
new-client acme --name "Acme Records"
new-mix "Blue Sky" --client acme
```

`new-client` can be run from anywhere. Studio-root resolution uses this order:

1. explicit `--root PATH`
2. `JL_MIXING_ROOT`
3. current-directory studio context
4. the default `~/Music/Mixes` workspace

## Automation API

Machine clients discover the installed provider with:

```text
jl-mixing system-info --json
```

API 1.0 advertises capability-backed operations including:

```text
client.create
project.create
project.create.artist
intake.validate
intake.validate.report
revision.create
revision.create.description
revision.approve
delivery.create
system.info
```

Clients must use the reported `api_version` and `capabilities`; they must not
infer API compatibility from the Automation product release number.

## Compatibility

- Automation application release: v1.5
- Automation API: `1.0`
- readable metadata schemas: `1.1.0`
- writable metadata schema: `1.1.0`
- no v1.0 workspace migration

Existing valid v1.1+ workspaces remain usable. New records identify the current
application release in `created_with` without changing the metadata schema
identity.

## Documentation

Start with [`docs/README.md`](docs/README.md), the
[`User Guide`](docs/USER_GUIDE.md), and the
[`Installation Guide`](docs/INSTALLATION_GUIDE.md).

JL Mixing Automation is licensed under Apache-2.0. See [LICENSE](LICENSE).
