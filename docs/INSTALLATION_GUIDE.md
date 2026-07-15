# JL Mixing Automation v1.1 Installation Guide

## Requirements

- macOS or Linux
- Bash 3.2 or newer
- Python 3.10 or newer with `venv`
- `jq`
- Network access to install the pinned Python dependency unless the release
  includes an offline wheelhouse

`ffprobe` is optional and is checked only when `validate-intake` uses it.

## Standard installation

Extract the release archive and run:

```bash
./install.sh
```

Default locations:

```text
~/.local/share/jl-mixing/
~/.local/bin/
```

The installer builds and verifies the complete application in a staging area,
then commits the application, launchers, and shell configuration together. A
failed install restores the previous working version.

## Automatic shell configuration

By default, the installer detects bash or zsh and manages exactly one block in
`.bashrc` or `.zshrc`:

```text
# >>> JL Mixing managed configuration >>>
...
# <<< JL Mixing managed configuration <<<
```

The block adds the single installed `bin` directory to `PATH` and sources the
wrapper integration used by `--cd`. Existing startup-file content outside the
block is preserved byte-for-byte. Open a new Terminal tab after installation.

To avoid startup-file modification:

```bash
./install.sh --no-shell-integration
```

The commands still work; automatic directory changes fall back to a quoted
copy-and-paste `cd` command.

## Custom prefix

```bash
./install.sh --prefix "$HOME/Applications/jl-local"
```

The environment variable `JL_MIXING_INSTALL_PREFIX` is also supported, but an
explicit `--prefix` takes precedence.

## Upgrade

Extract the newer release and run its installer with the same prefix. Reinstall
is idempotent: the single managed shell block is replaced in place and the
active application is not changed until the staged version passes verification.
Studio workspaces are never modified.

## Uninstall

```bash
jl-mixing-uninstall
```

The uninstaller removes managed application files, launchers, and the exact
managed shell block as one rollback-capable transaction. Studio workspaces,
audio, and project data are never removed. Open a new Terminal tab afterward to
clear already-loaded shell functions and PATH entries.

## Fresh workspace requirement

v1.1 requires a newly created workspace. Installation or upgrade does not
migrate v1.0 workspaces. Use a separate root when retaining a v1.0 workspace for
reference.
