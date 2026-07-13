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

## Developer setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r packaging/requirements.txt
```

The commands also require `jq`. `ffprobe` is optional and enables enhanced
intake inspection.

## Verify Version 1.0

```bash
make test
make strict-test
tools/shellcheck-all
make release-check
```

## Install from the source tree

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

Release archives are written under `dist/`.

See `docs/USER_GUIDE.md`, `docs/INSTALLATION_GUIDE.md`, and
`docs/BATCH_4_IMPLEMENTATION.md`.
