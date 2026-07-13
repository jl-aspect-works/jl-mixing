# Batch 2 Implementation

## Scope

Batch 2 implements the shared Bash foundation required by every user-facing command.

Implemented libraries:

- `common.sh`: logging, errors, prompts, timestamps, UUIDs, constants
- `platform.sh`: macOS/Linux portability
- `filesystem.sh`: safe creation, copying, movement, atomic writes, immutable-original protection
- `json.sh`: jq reads, atomic updates, schema identity and validator invocation
- `metadata.sh`: metadata creation, validation, and timestamps
- `config.sh`: studio configuration and precedence resolution
- `context.sh`: studio, client, project, and revision detection
- `naming.sh`: slugs, revision names, DAW names, deliverables, working prints
- `templates.sh`: literal token rendering and managed Markdown sections
- `validation.sh`: core business-rule validation
- `revision.sh`: revision records, numbering, approval, and superseding

## Deliberately not implemented

The eight user-facing commands, installation, uninstallation, and release packaging remain placeholders. They are implemented in later batches.

## Verification

```bash
make test
```

Runs dependency-light verification. jq-dependent tests are skipped when jq is not installed; semantic JSON Schema validation is skipped when `jsonschema` is unavailable.

```bash
make strict-test
```

Requires jq and the pinned Python development dependency and exercises the complete Batch 2 test suite.

## Compatibility

The Bash implementation avoids associative arrays, `mapfile`, lowercase parameter expansion, and other features unavailable in macOS Bash 3.2.

## Package revision r1

The Batch 2 r1 package canonicalizes temporary test-directory paths before
assertions. This accommodates macOS, where `/var` resolves to `/private/var`,
without weakening production path canonicalization.
