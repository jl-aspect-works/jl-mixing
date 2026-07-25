# JL Mixing Automation

JL Mixing Automation v1.3 creates and manages a consistent filesystem workflow
for professional mixing projects. It preserves original client files, tracks
revision approvals, and builds verified final-delivery packages without taking
ownership of the DAW session itself.

## v1.3 workflow

```text
new-studio
  → new-client
  → new-mix (creates Revision_01)
  → validate-intake
  → work in and send the current revision manually
  → new-revision when another revision is needed
  → approve-mix
  → create-delivery
```

The default workspace is `~/Music/Mixes/`. Projects have stable paths beneath
`Clients/<Client>/Projects/<Project>/`; there are no `Active/` or `Completed/`
directories and no project-completion command.

## Requirements

- macOS or Linux
- Bash 3.2 or newer
- Python 3.10 or newer
- `jq`
- `ffprobe` is optional and preserves the opportunistic intake inspection
  available in v1.0.4

## Install a release archive

```bash
cd ~/Downloads
tar -xzf jl-mixing-1.3.0-macos.tar.gz
cd jl-mixing-1.3.0
./install.sh
```

Use the `linux` archive name on Linux. The default installation is:

```text
Application: ~/.local/share/jl-mixing/
Commands:    ~/.local/bin/
```

The installer adds one reversible managed block to `.zshrc` or `.bashrc`. That
single block adds the command directory to `PATH` and loads the optional shell
wrappers used by `--cd`. Open a new Terminal tab after installation, or source
the startup file shown by the installer.

To install without editing shell configuration:

```bash
./install.sh --no-shell-integration
```

To install under another prefix:

```bash
./install.sh --prefix "$HOME/Applications/jl-local"
```

## Start

```bash
new-studio
new-client acme --name "Acme Records"
cd "$HOME/Music/Mixes/Clients/Acme Records"
new-mix "Blue Sky"
```

`new-mix --project "Blue Sky"` remains fully supported. When `--artist` is
omitted, `new-mix` uses the client's artist default and then the client display
name. Creation commands print a copy-and-paste `Next:` command. When shell
integration is active, `new-client`, `new-mix`, and `new-revision` can change the
current Terminal directory with `--cd`; the studio-wide default is configured
by `new-studio --default-cd`.

## Compatibility rule

JL Mixing Automation v1.3 continues using the v1.1 workspace schemas and is
compatible with valid v1.1 workspaces. Application provenance is independent:
new records use `created_with: jl-mixing 1.3.0` while the unchanged document
contract remains `schema_version: 1.1.0`. It does not migrate, restructure, or
modify v1.0 workspaces. Copy only user-owned material, such as original client
deliveries or notes, into newly created v1.1/v1.2 projects. Do not copy v1.0
JSON manifests or complete v1.0 project directories.

## Delivery behavior

`create-delivery` always packages the approved revision. Every selected regular
file is eligible regardless of extension. Familiar filename phrases are
classified on a best-effort basis; unmatched files are recorded as
`unclassified` and are still delivered.

To create a ZIP containing completed delivery notes:

```bash
create-delivery
# Edit 05_Final_Delivery/Delivery_Notes.md
create-delivery --zip --overwrite
```

`--overwrite` preserves the edited notes when the delivered path set is
unchanged. A one-step `create-delivery --zip` packages the clean notes template
because it creates and zips the delivery before the user can edit the file.

Generated ZIPs use
`<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip`, with a zero-padded revision and
local timestamp.

`create-delivery --clean` is intentionally destructive: it replaces every item
inside the resolved project's `05_Final_Delivery/` directory. Dry-run lists the
planned deletions before any changes occur.

## Upgrade and uninstall

Running a newer release's `install.sh` upgrades the application transactionally
without modifying studio workspaces.

```bash
jl-mixing-uninstall
```

Uninstall removes the application, managed launchers, and the exact managed
shell block. It never removes studio workspaces.

## Developer setup and quality gates

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r packaging/requirements.txt

make test
make strict-test
tools/shellcheck-all
make release-check
```

Release archives, checksums, and inventories are written to `dist/` by
`make release`.

See [docs/README.md](docs/README.md) for the full documentation index and
[docs/RELEASE_NOTES_V1.3.md](docs/RELEASE_NOTES_V1.3.md) for release highlights.
