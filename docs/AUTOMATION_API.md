# JL Mixing Automation API

**Status:** Proposed design; not yet implemented  
**Initial target:** API 1.0

## Purpose

The Automation API is the stable machine contract used by JL Mixing Studio and future supported clients. It does not replace the human-oriented CLI. Existing commands remain usable interactively while supported machine operations gain documented JSON behavior.

## Transition baseline

JL Mixing Studio 1.0 depends on the exact JL Mixing Automation 1.3.0 command contract. API 1.0 will be introduced explicitly; no current command output should be described as API 1.0 until implementation and contract tests are released.

## Dispatcher and version discovery

`jl-mixing` is the canonical machine-facing Automation API dispatcher. JL Mixing Studio and future supported API clients invoke only this executable with allowlisted subcommands and arguments.

Existing human-facing commands such as `new-client`, `new-mix`, `validate-intake`, `new-revision`, `approve-mix`, and `create-delivery` remain supported. The dispatcher and existing commands share the same underlying implementation; the dispatcher must not invoke the existing commands as subprocesses or create a competing implementation of workflow rules.

Machine-readable discovery uses:

```bash
jl-mixing system-info --json
```

Example response:

```json
{
  "api_version": "1.0",
  "application": {
    "name": "jl-mixing",
    "version": "1.4.0"
  },
  "metadata": {
    "readable_schema_versions": ["1.1.0"],
    "writable_schema_version": "1.1.0"
  },
  "capabilities": [
    "client.create",
    "project.create",
    "intake.validate",
    "revision.create",
    "revision.approve",
    "delivery.create"
  ]
}
```

## Response envelope

Every API operation returns one JSON object on standard output:

```json
{
  "api_version": "1.0",
  "operation": "project.create",
  "status": "success",
  "data": {},
  "warnings": [],
  "errors": []
}
```

Required top-level fields are `api_version`, `operation`, `status`, `data`, `warnings`, and `errors`.

Allowed status values for API 1.0 are:

- `success` — operation completed and authoritative state was committed;
- `planned` — dry-run completed without mutation;
- `blocked` — request was understood but governing state or findings prevented completion;
- `error` — request could not be completed because of invalid input, environment, transport, or internal failure.

## Error objects

Errors use stable machine codes and human-readable messages:

```json
{
  "code": "PROJECT_NOT_FOUND",
  "message": "The requested project could not be resolved.",
  "details": {},
  "retryable": false
}
```

Clients must branch on `code`, not message text.

## Compatibility rules

Within API major version 1:

- new optional fields and capabilities may be added;
- existing required fields and field meanings must not change;
- operation identifiers and documented status meanings must remain stable;
- clients must ignore unknown optional fields;
- removed or incompatible behavior requires API 2.0.

The Automation application version may change without changing the API version.

## Capability discovery

Studio shall use capability identifiers for optional features. A missing optional capability disables only that feature. Missing required capabilities make the installed Automation version incompatible with that Studio release.

Capability names use stable dotted identifiers. Initial candidates include:

- `system.info`
- `studio.create`
- `client.create`
- `project.create`
- `intake.validate`
- `revision.create`
- `revision.approve`
- `delivery.create`

## Dry-run contract

Mutating operations that support preview return `status: planned` and a structured plan. The confirmed operation must identify the same logical request. Clients must still re-read authoritative workspace state after success; JSON output does not replace post-operation reconciliation.

## Output and process rules

- JSON mode writes only the response object to standard output.
- Human diagnostics and progress may use standard error only when documented.
- Commands remain non-interactive in JSON mode.
- Paths are returned as explicit fields, never embedded only in prose.
- Exit codes remain documented per operation and must agree with the JSON status.
- Secrets and unrestricted command strings are never returned.

## Contract testing

API releases shall include:

- JSON Schema or equivalent fixtures for every response type;
- golden success, planned, blocked, and error examples;
- compatibility tests proving older API 1.x clients can ignore newly added optional fields;
- tests for paths containing spaces and non-destructive dry-run behavior;
- exact tests for operation identifiers, machine error codes, and exit-code mapping;
- parity tests proving dispatcher operations and corresponding human-facing commands use the same workflow rules and produce equivalent authoritative state.

## Approved design decisions

1. `jl-mixing` is the canonical machine-facing API dispatcher. Existing human-facing commands remain supported and share the same underlying implementation.

## Open design decisions

Before implementation, approve:

1. exact exit-code mapping;
2. progress-event behavior for long operations;
3. whether read-only query operations ship in API 1.0 or a later 1.x addition;
4. JSON Schema publication and location.
