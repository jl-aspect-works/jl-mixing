# JL Mixing Automation v1.1 Command Reference

Every command supports `-h` and `--help`. Mutating commands validate governing
JSON and filesystem boundaries before committing changes.

## `new-studio`

```text
new-studio [--root PATH] [--name NAME] [--engineer NAME]
           [--sample-rate HZ] [--bit-depth BITS]
           [--file-format WAV|AIFF]
           [--default-cd|--no-default-cd] [--dry-run]
```

Creates a new, previously nonexistent workspace. No DAW directories or DAW
metadata are created.

## `new-client`

```text
new-client CLIENT_ID [--name NAME] [--artist NAME]
           [--sample-rate HZ] [--bit-depth BITS]
           [--file-format WAV|AIFF] [--delivery-method TEXT]
           [--deliverables LIST] [--cd|--no-cd] [--dry-run]
```

Creates `Clients/<Readable Name>/client.json` and `Projects/`.

## `new-mix`

```text
new-mix --project NAME [--client ID_OR_PATH] [--project-id ID]
        [--artist NAME] [--album TITLE] [--producer NAME]
        [--engineer NAME] [--bpm NUMBER] [--key TEXT]
        [--time-signature TEXT] [--sample-rate HZ]
        [--bit-depth BITS] [--file-format WAV|AIFF]
        [--deadline YYYY-MM-DD] [--deliverables LIST]
        [--description TEXT] [--source PATH]
        [--cd|--no-cd] [--dry-run]
```

Creates the complete flattened project tree, strict project manifest, and
immutable client-profile snapshot. No initial revision is created.

## `validate-intake`

```text
validate-intake [--project PATH] [--source PATH]
                [--expected-sample-rate HZ]
                [--expected-bit-depth BITS]
                [--no-duplicate-check] [--dry-run]
```

Preserves v1.0.4 intake behavior while writing the clearer v1.1 managed report.
`--no-duplicate-check` skips duplicate-basename detection only.

## `new-revision`

```text
new-revision [--project PATH] [--description TEXT]
             [--source PATH] [--cd|--no-cd] [--dry-run]
```

Creates the next contiguous `Revision_NN/` directory and advances
`state.current_revision` transactionally.

## `approve-mix`

```text
approve-mix [--project PATH] [--revision NUMBER]
            [--approved-by NAME] [--date TIMESTAMP] [--dry-run]
```

Approves the current revision by default. Approval may move to any existing
revision. Approval does not modify revision files or final-delivery content.

## `create-delivery`

```text
create-delivery [--project PATH] [--include PATTERN]
                [--exclude PATTERN] [--working-prefix TEXT]
                [--overwrite|--clean] [--zip] [--dry-run]
```

Packages the approved revision, verifies copied bytes with SHA-256, writes the
strict delivery manifest, and updates `state.delivered_revision` as one
rollback-capable transaction.

`--clean` replaces all contents of `05_Final_Delivery/`, not only files listed by
a prior manifest.

## Removed v1.0 interface

v1.1 has no project-completion command. Known v1.0 flags are rejected with
specific diagnostics rather than silently ignored.
