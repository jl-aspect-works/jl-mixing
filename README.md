# JL Mixing Automation

JL Mixing Automation v1.1 creates and manages a consistent filesystem workflow
for professional mixing projects. It preserves original client files, tracks
revision approvals, and builds verified final-delivery packages without taking
ownership of the DAW session itself.

## v1.1 workflow

```text
new-studio
  → new-client
  → new-mix
  → validate-intake
  → new-revision
  → send the revision to the client manually
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
tar -xzf jl-mixing-1.1.0-macos.tar.gz
cd jl-mixing-1.1.0
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
new-mix --project "Blue Sky"
```

Creation commands print a copy-and-paste `Next:` command. When shell integration
is active, `new-client`, `new-mix`, and `new-revision` can change the current
Terminal directory with `--cd`; the studio-wide default is configured by
`new-studio --default-cd`.

## Important v1.1 compatibility rule

JL Mixing Automation v1.1 requires a newly created v1.1 workspace. It does not
migrate, restructure, or modify v1.0 workspaces. Copy only user-owned material,
such as original client deliveries or notes, into newly created v1.1 projects.
Do not copy v1.0 JSON manifests or complete v1.0 project directories.

## Delivery behavior

`create-delivery` always packages the approved revision. Every selected regular
file is eligible regardless of extension. Familiar filename phrases are
classified on a best-effort basis; unmatched files are recorded as
`unclassified` and are still delivered.

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
[docs/RELEASE_NOTES_V1.1.md](docs/RELEASE_NOTES_V1.1.md) for release highlights.
