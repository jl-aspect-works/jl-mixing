# JL Mixing Automation

JL Mixing Automation organizes professional audio mixing projects, preserves
client originals, tracks revisions and approvals, assembles final delivery
packages, and records project completion.

## Install

Required before installation:

- Bash 3.2 or newer
- Python 3.10 or newer
- `jq`

Extract the archive and run:

```bash
./install.sh
```

The default installation is:

```text
Application: ~/.local/share/jl-mixing/
Commands:    ~/.local/bin/
```

Use another prefix when needed:

```bash
./install.sh --prefix "$HOME/Applications/jl-local"
```

If the command directory is not already in `PATH`, the installer prints the
exact line to add to the shell configuration.

## Start

```bash
new-studio
```

Logic Pro is the Version 1.0 default DAW. Use `new-studio --help` for options.

## Upgrade

Extract the newer release and run its `install.sh`. Application files are
replaced transactionally. Studio workspaces are never modified.

## Uninstall

```bash
jl-mixing-uninstall
```

Uninstallation removes the application and managed launchers only. It never
removes `~/Music/Mixes/` or another configured studio workspace.

See `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` for complete details.
