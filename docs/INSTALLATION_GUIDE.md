# JL Mixing Automation
## Installation Guide v1.0

## Distribution

End users install from versioned release archives, not from Git.

```text
jl-mixing-1.0.0-macos.tar.gz
jl-mixing-1.0.0-linux.tar.gz
```

## Requirements

Required:

- Bash 3.2 or newer
- Python 3
- `jq`

Optional:

- `ffprobe` for enhanced intake inspection
- ShellCheck for development

The installer creates a private Python virtual environment and installs the
pinned dependency listed in `packaging/requirements.txt`.

## Installation

```bash
tar -xzf jl-mixing-1.0.0-macos.tar.gz
cd jl-mixing-1.0.0
./install.sh
```

Default paths:

```text
Application: ~/.local/share/jl-mixing/
Commands:    ~/.local/bin/
```

The installer checks `PATH` and prints the exact shell configuration line if
`~/.local/bin` is missing. It does not silently edit shell startup files.

## Upgrade and uninstall

Running a newer package's installer replaces application files but preserves
the studio workspace. `uninstall.sh` removes only installed application files
and command links. It must never remove `~/Music/JL Mixing/` or another selected
workspace.
