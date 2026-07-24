# JL Mixing Automation Developer Guide

## Repository architecture

```text
bin/        User-facing Bash commands
lib/        Shared Bash logic
schemas/    Strict Draft 2020-12 v1.1 schemas
templates/  Runtime JSON and Markdown templates
docs/       User, design, and release documentation
tests/      Unit, integration, installation, and package tests
tools/      Python helpers and release utilities
examples/   Canonical valid v1.1 JSON documents
packaging/  Runtime dependency metadata
```

## Coding standards

- Maintain Bash 3.2 compatibility on macOS.
- Do not rely on empty-array expansion under `set -u`.
- Quote expansions unless splitting is intentional.
- Validate external input and reject symlinks at ownership boundaries.
- Use same-filesystem staging and rollback-capable transactions.
- Keep user-authored Markdown untouched outside explicitly managed markers.
- Keep command orchestration in `bin/`; reusable logic belongs in `lib/` or a
  focused local helper under `tools/`.
- Tests must use isolated temporary homes, prefixes, and workspaces.

## Validation layers

1. JSON syntax
2. Exact v1.1 schema identity and local Draft 2020-12 schema validation
3. Cross-document identity and pointer validation
4. Filesystem boundary and path validation

Schemas are always loaded locally from the installed application. Runtime
validation uses the private environment created by the installer.

## Development setup

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r packaging/requirements.txt
```

Required developer tools include `jq` and ShellCheck.

## Quality gates

```bash
make test
make strict-test
tools/shellcheck-all
make release-check
```

`make strict-test` includes installation and archive lifecycle tests. Tests must
cover transaction failure and rollback, not only happy paths.

## Release process

1. Complete work through feature PRs into `develop/v1.3`.
2. Run all quality gates from a clean integration branch.
3. Build and verify the archive with `make release-check`.
4. Merge `develop/v1.3` to `main` through a protected PR.
5. Tag the merge commit `v1.3.0` and publish the verified archive, checksum, and
   v1.3 release notes.
