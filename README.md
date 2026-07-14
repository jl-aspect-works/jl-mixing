# JL Mixing Automation

JL Mixing Automation standardizes project setup, intake validation, revision
tracking, final delivery, and project completion for professional audio work.

This repository contains the complete **Version 1.0 implementation**:

- approved design documentation;
- JSON Schemas and valid examples;
- Markdown and JSON templates;
- shared Bash libraries;
- all eight user-facing commands;
- unit and integration tests;
- transactional installation and upgrades;
- safe uninstallation;
- release tarball construction and verification; and
- intent-focused comments throughout the codebase.

## End-user installation

End users do **not** need to clone this Git repository. Download the appropriate
Version 1.0 release archive from the project's GitHub **Releases** page.

### Requirements

- macOS or Linux
- Bash 3.2 or newer
- Python 3.10 or newer
- `jq`

`ffprobe` is optional in Version 1.0 and enables enhanced intake inspection.

### macOS installation

The release archive may be downloaded and extracted in `~/Downloads` or any
other convenient temporary location. The extracted `jl-mixing-x.y.z` directory
is **not** the permanent application location; it only contains the installation
files used by `install.sh`.

```bash
cd ~/Downloads

tar -xzf jl-mixing-x.y.z-macos.tar.gz
cd jl-mixing-x.y.z

./install.sh
```

Running `install.sh` copies JL Mixing Automation to its permanent per-user
installation directories:


```text
Application files: ~/.local/share/jl-mixing/
Commands:          ~/.local/bin/
```

The installer creates a private Python environment for JL Mixing Automation and
installs its pinned JSON Schema dependency. End users do not need to activate or
manage that environment.

If the installer reports that `~/.local/bin` is not in `PATH`, add it to the
macOS Zsh configuration:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

Verify the installation:

```bash
which new-studio
new-studio --help
```

Start by creating the studio workspace:

```bash
new-studio
```

The default workspace for a new installation is:

```text
~/Music/Mixes/
```

Logic Pro is the Version 1.0 default DAW. Existing workspaces created at
`~/Music/JL Mixing/` are not moved or renamed during an upgrade.

### Linux installation

As on macOS, the archive may be extracted in `~/Downloads` or another temporary
directory. The installer copies the application to `~/.local/share/jl-mixing/`
and the commands to `~/.local/bin/`.

```bash
cd ~/Downloads

tar -xzf jl-mixing-x.y.z-linux.tar.gz
cd jl-mixing-x.y.z

./install.sh
```

If required, add the installed command directory to the shell configuration:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Optional checksum verification

On macOS:

```bash
shasum -a 256 jl-mixing-x.y.z-macos.tar.gz
cat jl-mixing-x.y.z-macos.tar.gz.sha256
```

The two SHA-256 values should match.

On Linux:

```bash
sha256sum -c jl-mixing-x.y.z-linux.tar.gz.sha256
```

### Install to another location

```bash
./install.sh --prefix "$HOME/Applications/jl-local"
```

### Upgrade

Download and extract the newer release archive, then run its installer:

```bash
./install.sh
```

Application files are replaced transactionally. Existing studio workspaces and
projects are not modified.

### Uninstall

```bash
jl-mixing-uninstall
```

Uninstallation removes the application and managed command launchers. It does
not remove the default studio workspace at `~/Music/Mixes/` or another
configured workspace.

After installation succeeds, you may delete both the downloaded archive and
the temporary extracted `jl-mixing-x.y.z` directory. Removing those files does
not uninstall the application.

See `docs/USER_GUIDE.md` and `docs/INSTALLATION_GUIDE.md` for the complete user
workflow and installation details.

## Developer setup

Clone the repository, then create a project-local Python environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r packaging/requirements.txt
```

The commands also require `jq`. ShellCheck is used by the development and CI
quality gates.

## Verify Version 1.0

```bash
make test
make strict-test
tools/shellcheck-all
make release-check
```

## Install from the source tree

For development or source-tree testing:

```bash
make install
```

Or install to another prefix:

```bash
PREFIX="$HOME/Applications/jl-local" make install
```

## Build the end-user package

```bash
make release
```

Release archives, checksums, and inventories are written under `dist/`.

See `docs/DEVELOPER_GUIDE.md` and `docs/BATCH_4_IMPLEMENTATION.md` for developer
and release-engineering details.
