# Automation API `delivery.create`

`delivery.create` exposes the existing `create-delivery` workflow through the Automation API 1.0 dispatcher without invoking the human-facing command as a subprocess.

## Command

```bash
jl-mixing delivery create --json --project PATH [options]
```

Supported delivery options mirror `create-delivery`, including `--include`, `--exclude`, `--working-prefix`, `--overwrite`, `--clean`, `--zip`, and `--dry-run`.

JSON mode requires an explicit `--project PATH` so clients do not depend on shell working-directory context.

## Results

The response uses the common API 1.0 envelope. Successful and planned responses identify the project, approved revision, project manifest, delivery folder, delivery notes, delivery manifest, replacement mode, workspace, and ZIP request state. Successful ZIP creation also reports the generated archive path.

A dry run returns `status: planned` and does not mutate the delivery folder or project manifest.

Completed delivery creation returns `status: success`. Validation or safety guardrails return `blocked` with stable machine-readable error codes while preserving the existing Automation exit-code contract.

## Authoritative state

Clients must re-read the project manifest and generated delivery artifacts after success. The JSON response describes the operation result but does not replace authoritative workspace state.

The API and `create-delivery` share the same in-process implementation, including approved-revision selection, file filtering/classification, checksum verification, ZIP handling, replacement guardrails, delivery notes behavior, and project manifest updates.
