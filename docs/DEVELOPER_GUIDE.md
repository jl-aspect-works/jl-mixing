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
