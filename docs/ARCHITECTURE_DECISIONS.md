# Architecture Decisions

- Application installation and studio workspaces are separate.
- The default workspace is `~/Music/Mixes/`.
- Projects live directly beneath each client's `Projects/` directory and keep a
  stable path.
- Project lifecycle is derived from `current_revision`, `approved_revision`, and
  `delivered_revision`; there is no completed-project state or command.
- `03_DAW_Project/` is an opaque DAW/user-owned boundary. JL Mixing does not
  manage DAW templates, presets, or project metadata.
- Original client delivery files are immutable.
- JSON contains machine-managed state; Markdown contains human documentation.
- Only the marked automated section in `Intake_Report.md` is rewritten.
- Client profile snapshots are immutable historical records.
- Revision status is derived, not stored.
- `validate-intake` preserves v1.0.4's opportunistic `ffprobe` behavior without
  expanding audio QC in v1.1.
- Delivery file eligibility is not restricted by extension.
- Delivery classification is best-effort; unmatched files are `unclassified`.
- `create-delivery --clean` explicitly authorizes removal of every item inside
  `05_Final_Delivery/` and remains rollback-capable.
- Installation, upgrades, shell configuration, and uninstall are transactional.
- User-facing commands are thin orchestration layers over shared libraries and
  local helper tools.
