# Automation API `client.create`

The Automation API 1.0 client-creation operation is invoked through:

```bash
jl-mixing client create CLIENT_ID --json [options]
```

Supported options mirror the non-interactive creation inputs of `new-client`: `--name`, `--artist`, `--sample-rate`, `--bit-depth`, `--file-format`, `--delivery-method`, `--deliverables`, and `--dry-run`.

The operation uses the same in-process transactional client-creation implementation as `new-client`. It does not invoke the human-facing command as a subprocess.

Successful creation returns `status: success`. A valid dry run returns `status: planned` and does not mutate the workspace. Failures preserve the Automation exit-code contract and return stable machine-readable error codes in the API response envelope.

`system-info --json` advertises `client.create` only while the implementation, schemas, examples, parity tests, and packaged contract are present.
