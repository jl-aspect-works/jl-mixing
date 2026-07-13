# Architecture Decisions

This is a concise decision log rather than a formal ADR system.

- Application installation and studio workspaces are separate.
- Git is a developer dependency, not an end-user requirement.
- Logic Pro is the low-friction default DAW, not an architectural limitation.
- `03_DAW_Project/Project/` is an opaque DAW-owned boundary.
- Client originals are immutable.
- Routine revisions use one active DAW project.
- JSON contains machine-managed state; Markdown contains human documentation.
- Intake reports use explicit managed-section markers.
- Client profile snapshots are exact copies.
- Revision statuses are `open`, `approved`, and `superseded`.
- There is no `Superseded/` directory or `Revision_Log.md`.
- Audio preparation is primarily manual in Version 1.0.
- Delivery preparation and delivery recording are separate actions.
- User-facing commands are thin wrappers around shared libraries.
