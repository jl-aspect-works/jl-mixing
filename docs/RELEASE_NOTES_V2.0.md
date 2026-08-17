# JL Mixing Automation 2.0

JL Mixing Automation 2.0 supplies the authoritative workflow and machine-readable API support used by the JL Mixing Studio 2.0 Daily Workflow release.

## Highlights

- Structured incremental intake validation for Studio, including cached file-level findings and technical metadata.
- Structured Audio Prep validation and exact-content provenance so Studio can show authoritative preparation state and source-file relationships without guessing.
- Revision-description mutation through Automation-owned metadata handling.
- Managed Delivery status and reconciliation, including missing, mismatched, unsafe, and untracked artifact detection.
- Generated Delivery package current/stale verification that incorporates the current Delivery Notes content.
- Safe generated-package deletion and authoritative package rebuild through the existing delivery creation workflow.
- Explicit failed-mutation safety coverage confirming existing authoritative Delivery state is preserved when package deletion fails.
- Native Windows runtime/install support from the 1.5 release line remains included.

## Compatibility

Automation 2.0 keeps the existing Automation API identity at **1.0** and keeps the supported workspace metadata schema identity at **1.1.0**. Application release versions remain independent from API and metadata schema versions.

Existing valid v1.1-schema workspaces remain compatible. No workspace migration is introduced by the 2.0 application release.

Studio compatibility should continue to be determined from Automation API version and advertised capabilities, not by requiring Studio and Automation product version numbers to match.

## Delivery safety

Studio may inspect managed Delivery state and invoke explicitly supported package operations, but manifest-managed deliverables remain Automation-owned. Automation does not expose unrestricted filesystem mutation of `05_Final_Delivery`.

Generated package deletion is restricted to JL Mixing package filenames for the current project. Rebuilds continue to use the existing authoritative `delivery create --overwrite --zip` semantics, preserving manifest/hash consistency and current Delivery Notes.

## Explicitly deferred beyond 2.0

- Audio Prep repair, normalization, Fix/Convert, or format-conversion mutations.
- Unrestricted managed-deliverable rename/delete operations.
- Generic filesystem management outside the defined Automation workflows.
- Real-time multi-user conflict resolution.

## Release candidate note

For prerelease tags such as `v2.0.0-rc.1`, this document describes the intended 2.0 release scope. Final stable promotion remains subject to coordinated Studio/Automation packaged acceptance and release approval.
