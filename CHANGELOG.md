# Changelog

## 1.4.0

- Added the structured Automation API 1.0 workflow operations used by JL Mixing
  Studio v1.1: client/project creation, intake validation, revision creation and
  approval, and delivery creation.
- Added additive capability discovery for the completed workflow API surface.
- Added provider-authored effective project artist and revision description
  results plus authoritative intake report content for Studio reconciliation.
- Expanded `delivery.create` results with selected/excluded files and clean-mode
  deletion inventory required for safe Studio preview/confirm/commit handling.
- Added SemVer prerelease/build-version support for application release identity,
  API discovery, and persisted `created_with` provenance so release candidates
  can be tested against real workspaces without changing metadata schema 1.1.0.
- Preserved the existing human-facing CLI workflows and v1.1 workspace schemas.

## 1.3.0

- Name delivery ZIPs with the project ID, zero-padded delivered revision, and
  local creation timestamp: `<project-id>-rev-<NN>-<YYYYMMDDHHMMSS>.zip`.
- Preserve earlier generated archives without nesting them inside later ZIPs.

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
