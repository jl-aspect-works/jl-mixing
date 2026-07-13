# JL Mixing Automation

JL Mixing Automation standardizes project setup, intake validation, revision
tracking, final delivery, and project completion for professional audio work.

This archive contains **Batch 2** of the Version 1.0 implementation:

- approved design documentation;
- JSON Schemas and valid examples;
- Markdown and JSON templates;
- all eleven shared Bash libraries;
- shared-library unit tests;
- placeholder user-facing commands and installers; and
- CI and release-check foundations.

The user-facing commands are intentionally deferred to Batch 3. Installation
and release packaging are implemented in Batch 4.

## Verify the package

```bash
make help
make test
```

`make test` runs the complete available suite and clearly skips tests whose
external development dependencies are unavailable.

For strict verification with `jq` and Python `jsonschema` installed:

```bash
make strict-test
```

## Documentation

See `docs/README.md` and `docs/BATCH_2_IMPLEMENTATION.md`.
