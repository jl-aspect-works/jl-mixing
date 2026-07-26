# JL Mixing Automation Roadmap

**Status:** Proposed for review

## Product role

JL Mixing Automation is the stable workflow engine and CLI for the JL Mixing ecosystem. It owns project structure, metadata validation, lifecycle rules, filesystem mutation, delivery behavior, and the public machine-readable Automation API.

## Versioning

The Automation application version, Automation API version, and metadata schema version are independent. Application releases may retain the same API and schema versions when their contracts do not change.

## Near-term priorities

1. Preserve the released v1.3.0 CLI behavior and v1.1.0 metadata schemas.
2. Define Automation API 1.0 without changing existing human-oriented CLI behavior.
3. Add machine-readable compatibility discovery.
4. Add consistent JSON envelopes, operation identifiers, errors, warnings, and result semantics for Studio-supported operations.
5. Add contract fixtures and tests that Studio can validate against.

## Candidate API 1.x capabilities

These are candidates, not committed release scope:

- system and capability discovery;
- structured dry-run plans;
- structured results for existing workflow commands;
- project, client, revision, and delivery inspection;
- structured validation findings;
- project health checks;
- batch operations where transaction and partial-failure semantics are explicitly designed.

## Metadata policy

Metadata changes are the slowest-moving track. Add persisted fields only when the information must travel with the workspace and be understood by Automation, Studio, or another supported client. UI preferences, recent items, favorites, search history, and rebuildable indexes do not belong in project schemas.

## Release admission rule

A feature is assigned to an Automation release only after its behavior, API impact, schema impact, compatibility requirements, tests, and Studio dependency are approved. Cross-repository features use linked issues rather than a single mixed implementation issue.

## Non-goals

Automation does not own desktop presentation, local UI preferences, general-purpose indexing, cloud collaboration, accounting, CRM, or DAW session processing.
