# Changelog

## 1.2.0

- Added positional project-name support to `new-mix` while preserving `--project`.
- Added client-name fallback when the client artist default is empty.
- Added transactional creation of unapproved Revision 1 during `new-mix`.
- Documented and regression-tested the two-step ZIP workflow that preserves
  completed `Delivery_Notes.md`.
- Decoupled application release provenance from metadata schema versioning:
  v1.2 writes `created_with: jl-mixing 1.2.0` while retaining the v1.1.0 schema.
- Preserved v1.1 workspace schema identities, document structures, and existing
  v1.1 compatibility.

## 1.1.0

- Flattened project storage and removed completion lifecycle directories.
- Removed JL-managed DAW resources and metadata.
- Added strict v1.1 schemas and immutable client/delivery snapshots.
- Added three-pointer revision state and older-revision approval support.
- Preserved v1.0.4 intake validation behavior with improved report layout.
- Added extension-neutral, SHA-256-verified final delivery with best-effort
  classification and destructive clean replacement.
- Added automatic bash/zsh integration, transactional install/upgrade/uninstall,
  and expanded release verification.
