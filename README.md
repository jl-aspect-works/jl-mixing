# JL Mixing Automation

JL Mixing Automation standardizes project setup, intake validation, revision
tracking, final delivery, and project completion for professional audio work.

This archive contains **Batch 3** of the Version 1.0 implementation:

- approved design documentation;
- JSON Schemas and valid examples;
- Markdown and JSON templates;
- all shared Bash libraries;
- all eight user-facing commands;
- shared-library unit tests;
- command integration tests;
- CI and release-check foundations; and
- intent-focused comments throughout commands, libraries, tests, Python tools, Makefile, and CI.

End-user installation, uninstallation, and release packaging are implemented in
Batch 4. During Batch 3, commands are run directly from `bin/` or with that
directory added temporarily to `PATH`.

## Developer setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r packaging/requirements.txt
```

The commands also require `jq`. `ffprobe` is optional and enables enhanced
intake inspection.

## Verify Batch 3

```bash
make test
make strict-test
```

`make test` runs all available checks and skips semantic/integration checks only
when their runtime dependencies are unavailable. `make strict-test` requires the
complete Batch 3 dependency set.

## Run the workflow from the repository

```bash
export PATH="$PWD/bin:$PATH"
new-studio --root "$HOME/Music/JL Mixing"
```

See `docs/USER_GUIDE.md`, `docs/SCRIPT_REFERENCE.md`, and
`docs/BATCH_3_IMPLEMENTATION.md`.
