# Automation API Implementation Status

## Current implementation

Automation API `1.0` discovery is implemented through:

```bash
jl-mixing system-info --json
```

The discovery response reports these independently versioned contracts:

- Automation API version from `API_VERSION`;
- Automation application release from `VERSION`;
- readable and writable workspace metadata schema versions;
- implemented machine-facing capabilities; and
- installed and public API-schema locations.

The discovery response is governed by
`api/schemas/v1.0/system-info.schema.json` and has a reviewed golden example at
`api/examples/v1.0/success/system-info.json`.

## Capability admission rule

`system-info` advertises only capabilities implemented and covered by contract
tests. The initial capability set is:

```text
system.info
```

Existing human-facing commands are not automatically Automation API operations.
They remain supported, but Studio and other API clients must not treat their
human-readable output as API `1.0` JSON.

Workflow capabilities such as `client.create`, `project.create`,
`intake.validate`, `revision.create`, `revision.approve`, and `delivery.create`
will be advertised only after their dispatcher routes, response envelopes,
schemas, golden examples, parity tests, and packaging checks are implemented.

## Compatibility

The Automation application version may change without changing `API_VERSION`
when the published API contract remains backward compatible. Workspace metadata
schema versions remain independent from both product and API versions.

Within API major version 1, clients must ignore unknown optional fields and use
capability discovery instead of inferring support from the Automation product
release number.
