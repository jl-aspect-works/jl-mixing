# JL Mixing Automation
## Developer Guide v1.0

## Repository architecture

```text
bin/        Thin user-facing command wrappers
lib/        Shared business logic
schemas/    Draft 2020-12 JSON Schemas
templates/  Generated Markdown and JSON source templates
docs/       Approved product and developer documentation
tests/      Unit, integration, and artifact tests
tools/      Development and release utilities
examples/   Valid example documents
packaging/  Release dependency and packaging metadata
```

## Shared libraries

```text
common.sh
config.sh
context.sh
filesystem.sh
json.sh
metadata.sh
naming.sh
platform.sh
revision.sh
templates.sh
validation.sh
```

## Coding standards

- Target Bash 3.2 compatibility on macOS.
- Prefer readable functions over clever shell constructs.
- Quote expansions unless splitting is intentional.
- Validate all external input.
- Use atomic JSON updates.
- Make errors explain what failed, why, and how to correct it.
- Keep business logic out of `bin/`.
- Tests must use isolated temporary workspaces.

## Validation strategy

1. Parse JSON syntax.
2. Validate Draft 2020-12 schema.
3. Enforce business rules.

Runtime schema validation uses a private virtual environment and the pinned
`jsonschema` version in `packaging/requirements.txt`.

## Testing layers

- Unit tests for shared libraries.
- Integration tests for complete commands.
- Packaging tests for clean install, upgrade, and uninstall.
- Acceptance tests for the documented end-to-end lifecycle.

## Design invariants

- `Original_Delivery/` is immutable.
- One active DAW project boundary exists per project.
- JSON is authoritative machine state.
- Human-authored Markdown is not silently rewritten.
- Managed sections use explicit markers.
- Commands remain thin wrappers.
- Shared logic belongs in `lib/`.
- `new-studio` never overwrites an existing workspace.
- Installation never modifies projects.
- Client snapshots are exact copies.
- Completion requires approval and recorded delivery.

## Development dependency behavior

`make test` verifies all JSON syntax and performs Draft 2020-12 semantic
validation when the optional `jsonschema` development package is available.
It reports a clear skip when that package is absent, because the production
private virtual environment is implemented in a later batch.

Developers who require strict semantic validation can run:

```bash
python3 -m venv .venv
.venv/bin/pip install -r packaging/requirements.txt
PATH="$PWD/.venv/bin:$PATH" make schema-test
```

## Batch 4 installation and release implementation

The installed application uses a stable `PREFIX/share/jl-mixing` path and
managed launchers in `PREFIX/bin`. Launchers set both `JL_MIXING_HOME` and
`JL_MIXING_PYTHON`, so commands resolve runtime assets and the private validator
without user configuration.

Release work uses:

```bash
make install-test
make release
make release-check
```

The release check must prove installation, upgrade behavior, installed command
execution, archive hygiene, and workspace-preserving uninstallation before a
Version 1.0 package is published.

