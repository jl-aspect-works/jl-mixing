# JL Mixing Automation v1.1

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

The default workspace is `~/Music/Mixes/`. v1.1 requires a fresh workspace and
does not migrate v1.0 workspaces.

## Workflow

```text
new-studio → new-client → new-mix → validate-intake → new-revision
→ manual client review → approve-mix → create-delivery
```

`create-delivery --clean` deletes and replaces all contents inside the selected
project's `05_Final_Delivery/` directory.

## Upgrade and uninstall

Run the new release's `install.sh` to upgrade transactionally. Workspaces are
not modified.

```bash
jl-mixing-uninstall
```

See `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` for complete details.
