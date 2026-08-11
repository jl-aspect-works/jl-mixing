# JL Mixing Automation 1.5

JL Mixing Automation 1.5 is the cross-platform runtime release. It preserves the
v1.4 workflow/API contract while moving the authoritative implementation to one
shared Python codebase and adding first-class Windows support.

## Highlights

- **Windows support:** all public JL Mixing commands now run natively on Windows,
  including PowerShell shell integration for parent-process `--cd` behavior.
- **Shared implementation:** macOS and Windows execute the same authoritative
  Python workflow services and Automation API adapters.
- **Self-contained runtimes:** packaged Windows and macOS releases include their
  own application runtime; end users do not need to install Python separately.
- **Self-contained installers:** Windows and macOS installers are transactional,
  rollback-capable, and preserve studio workspaces. The macOS packaged installer
  does not require external Python or jq.
- **Windows release artifacts:** official releases now include a Windows ZIP,
  SHA-256 checksum, and inventory alongside the existing macOS/Linux archives.
- **Cross-platform CI:** native Windows tests and macOS/Linux regression suites
  cover CLI/API behavior, filesystem safety, installation, rollback, and package
  extraction/install lifecycles.
- **Root-aware client creation:** `new-client --root PATH` now supports explicit
  studio-root selection with platform-neutral precedence across `--root`,
  `JL_MIXING_ROOT`, current studio context, and the default `~/Music/Mixes` root.

## Compatibility

Automation API remains **1.0**. Workspace metadata schema remains **1.1.0**.
Existing valid v1.1+ workspaces remain usable without migration.

Human CLI command names, options, output semantics, and exit-code behavior remain
compatible with v1.4. This release is a platform/runtime port, not a workflow
redesign.

## Release candidate

`1.5.0-rc.2` supersedes the earlier `1.5.0-rc.1` acceptance build and includes
post-RC1 root-resolution fixes plus the refreshed v1.5 documentation set. Use
RC2 for final cross-platform acceptance testing before the stable `1.5.0`
release. Validate the macOS and Windows packaged installers and representative
existing workspaces before promoting the final release.
