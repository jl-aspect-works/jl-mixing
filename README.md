# JL Mixing Automation

JL Mixing Automation v2.0 is the cross-platform workflow engine behind JL Mixing Studio. It creates consistent workspaces, preserves original client files, validates intake, manages revisions/approval, exposes the Automation API used by Studio, and builds verified final-delivery packages.

The authoritative runtime is Python and is shared across Windows and macOS. Automation API remains version `1.0`, while workspace metadata schemas remain version `1.1.0`.

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

The default workspace is `~/Music/Mixes/`. Projects live directly beneath `Clients/<Client>/Projects/<Project>/`; there are no `Active/` or `Completed/` directories.

## Installation

### Windows

Download and extract `jl-mixing-2.0.0-windows.zip`, then run:

```powershell
.\windows\install.ps1
```

If Windows marks the downloaded installer script as blocked:

```powershell
Unblock-File .\windows\install.ps1
.\windows\install.ps1
```

The package includes its private Python runtime. The default installation is beneath `%LOCALAPPDATA%\Programs\JL Mixing\`. Open a new PowerShell session after installation, then verify with `jl-mixing --version`.

### macOS

Choose the release archive for your architecture (`macos-x86_64` for Intel or `macos-arm64` for Apple Silicon) and extract it. The 2.0 packages are unsigned and not notarized, so after verifying the release checksum remove quarantine recursively from the extracted folder before installing:

```bash
xattr -dr com.apple.quarantine /path/to/jl-mixing-2.0.0
cd /path/to/jl-mixing-2.0.0
./macos/install.sh
```

Recursive quarantine removal is required because the package contains a bundled Python framework/runtime. The default prefix is `~/.local`. Open a new Terminal session after installation if needed, then verify with `jl-mixing --version`.

### Linux and source/developer installs

The Linux/source compatibility installer remains:

```bash
./install.sh
```

It requires Bash, Python 3.10+ with `venv`, and jq. See [`docs/INSTALLATION_GUIDE.md`](docs/INSTALLATION_GUIDE.md) for platform-specific details and custom-prefix options.

`ffprobe`/`ffmpeg` are optional external tools used for enhanced audio intake QC. When unavailable, affected checks are reported as skipped rather than silently assumed to have passed.

## Automation API

Machine clients discover the installed provider with:

```text
jl-mixing system-info --json
```

Studio 2.0 consumes additive API 1.0 capabilities for structured cached intake validation, Audio Prep validation/provenance, revision-description updates, managed Delivery status, and package reconciliation in addition to the established client/project/revision/approval/delivery operations.

Clients must use the reported `api_version` and `capabilities`; they must not infer compatibility from the Automation product release number.

## Compatibility

- Automation application release: v2.0
- Automation API: `1.0`
- readable metadata schemas: `1.1.0`
- writable metadata schema: `1.1.0`
- existing valid v1.1 workspaces remain compatible

New records identify the current application release in `created_with` without changing metadata schema identity.

## Documentation

Start with [`docs/README.md`](docs/README.md), the [`User Guide`](docs/USER_GUIDE.md), the [`Installation Guide`](docs/INSTALLATION_GUIDE.md), and the [`2.0 release notes`](docs/RELEASE_NOTES_V2.0.md).

JL Mixing Automation is licensed under Apache-2.0. See [LICENSE](LICENSE).
