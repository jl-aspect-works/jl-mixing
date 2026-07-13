# Batch 4 Implementation

Batch 4 completes the Version 1.0 implementation by adding end-user
installation, upgrades, uninstallation, release archive construction, and
release verification.

## Installation architecture

`install.sh` installs application files under:

```text
PREFIX/share/jl-mixing/
```

and managed command launchers under:

```text
PREFIX/bin/
```

The default prefix is `~/.local`.

The installer:

1. verifies the release package and required system commands;
2. stages runtime assets separately from any existing installation;
3. moves the prior installation to a rollback location;
4. creates an application-private Python virtual environment;
5. installs the pinned JSON Schema validator;
6. writes stable launcher scripts; and
7. removes the rollback copy only after successful verification.

A failed upgrade restores the previous application. Studio workspaces are
outside the application prefix and are never touched.

## Runtime Python

End users need Python 3.10 or newer, but they do not create, activate, or manage
a virtual environment. Installed launchers set `JL_MIXING_PYTHON` to the private
interpreter automatically.

## Uninstallation safety

`uninstall.sh` removes only the fixed application directory and launchers that
carry the JL Mixing managed-launcher marker. Unmanaged files with matching names
are preserved. Prefix directories are not removed because other applications
may use them.

## Release packaging

`tools/build-release` creates:

```text
jl-mixing-<version>-macos.tar.gz
jl-mixing-<version>-linux.tar.gz
```

along with a SHA-256 checksum and archive inventory. The archive excludes Git,
CI, tests, examples, local virtual environments, and development-only tools.

## Release gates

`tools/release-check` requires:

- strict unit, integration, schema, installation, and packaging tests;
- ShellCheck;
- successful release archive construction;
- clean extraction;
- installed command execution;
- transactional reinstall; and
- uninstall without workspace deletion.
