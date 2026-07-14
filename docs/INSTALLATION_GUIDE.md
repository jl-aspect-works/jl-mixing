# JL Mixing Automation
## Installation Guide v1.0

## Distribution

End users install from a versioned `.tar.gz` release archive. Git, a GitHub
account, and repository configuration are not required.

```text
jl-mixing-x.y.z-macos.tar.gz
jl-mixing-x.y.z-linux.tar.gz
```

## Requirements

- Bash 3.2 or newer
- Python 3.10 or newer
- `jq`

Optional:

- `ffprobe` for enhanced audio intake inspection

The installer creates and manages its own private Python environment. Users do
not install `jsonschema` globally and do not activate the application venv.

## Install

```bash
tar -xzf jl-mixing-x.y.z-macos.tar.gz
cd jl-mixing-x.y.z
./install.sh
```

Default locations:

```text
Application: ~/.local/share/jl-mixing/
Commands:    ~/.local/bin/
```

Use another prefix when needed:

```bash
./install.sh --prefix "$HOME/Applications/jl-local"
```

The installer verifies dependencies, stages application assets, creates the
private Python environment, installs the pinned validator, and writes managed
command launchers.

## PATH

If the command directory is not already in `PATH`, the installer prints the
exact export line to add. It does not silently edit `.zshrc`, `.bashrc`, or
another shell startup file.

For the default prefix:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Verify

```bash
new-studio --help
new-client --help
```

## Initialize the workspace

```bash
new-studio
```

Installation and workspace initialization are separate. Installing or upgrading
JL Mixing never creates or changes client projects. New studios default to
`~/Music/Mixes/`. Existing workspaces created at `~/Music/JL Mixing/` are not
moved or renamed during an upgrade.

## Upgrade

Extract the new release and run its installer:

```bash
./install.sh
```

The installer replaces application files transactionally. If installation
fails, the prior application is restored. The studio workspace is never part of
the upgrade transaction.

## Uninstall

```bash
jl-mixing-uninstall
```

Or from an extracted package:

```bash
./uninstall.sh
```

Uninstallation removes the application and its managed launchers. It never
removes `~/Music/Mixes/` or another configured workspace.

## Troubleshooting

### `python3` is missing or too old

Install Python 3.10 or newer, then rerun the installer.

### `jq` is missing

Install `jq`, then rerun the installer.

### Python package installation fails

Confirm that Python can reach its configured package index and that SSL
certificates are installed correctly. A failed upgrade restores the prior
application.

### Command not found

Add the installed command directory to `PATH`, open a new terminal, and retry.

### Existing studio workspace

`new-studio` intentionally refuses to overwrite an existing workspace. Use the
existing configuration or choose another `--root`.
