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
- **Architecture-specific macOS packages:** v1.5.1 publishes separate Intel
  (`macos-x86_64`) and Apple Silicon (`macos-arm64`) archives and verifies the
  bundled runtime CPU architecture before upload.
- **Windows release artifacts:** official releases include a Windows ZIP,
  SHA-256 checksum, and inventory alongside Linux and both macOS archives.
- **Cross-platform CI:** native Windows tests and macOS/Linux regression suites
  cover CLI/API behavior, filesystem safety, installation, rollback, and package
  extraction/install lifecycles.
- **Root-aware client creation:** `new-client --root PATH` supports explicit
  studio-root selection with platform-neutral precedence across `--root`,
  `JL_MIXING_ROOT`, current studio context, and the default `~/Music/Mixes` root.

## Compatibility

Automation API remains **1.0**. Workspace metadata schema remains **1.1.0**.
Existing valid v1.1+ workspaces remain usable without migration.

Human CLI command names, options, output semantics, and exit-code behavior remain
compatible with v1.4. The v1.5.1 patch changes release packaging only; it does
not change workflow behavior or machine API contracts.

## v1.5.1 release candidate

`1.5.1-rc.1` fixes the v1.5.0 macOS self-contained packaging defect where a
single architecture-specific PyInstaller runtime was published under the generic
`macos` archive name. Use the package matching the test machine architecture:

- Intel: `jl-mixing-1.5.1-rc.1-macos-x86_64.tar.gz`
- Apple Silicon: `jl-mixing-1.5.1-rc.1-macos-arm64.tar.gz`

For RC acceptance, verify that `./macos/install.sh` installs and runs successfully
from the matching package on each architecture. Confirm `jl-mixing system-info
--json` reports Automation API 1.0 and the RC application version. Windows and
Linux remain regression-only for this packaging patch.

## v1.5.0 stable baseline

`1.5.0` promoted the accepted `1.5.0-rc.2` build after coordinated packaged
validation with JL Mixing Studio v1.1.1. RC2 included the post-RC1 root-resolution
fixes and refreshed v1.5 documentation set; no runtime behavior changes were added
between the accepted RC2 baseline and stable release identity.

That validation covered packaged macOS and Windows installs, Automation API 1.0
discovery/admission, valid v1.1 workspace compatibility, client/project/intake/
revision/approval/delivery workflows, and the Studio cross-platform compatibility
matrix. Linux remains supported through the release archive/source compatibility
path and existing CI coverage.
