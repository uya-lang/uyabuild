# Unit Test Matrix

The unit matrix keeps a small, focused regression layer for the bootstrap
subsystems that now exist inside `bin/uyabuild`.

Each case lives under `tests/unit/cases/<component>/<case>/` and contains:

- `cwd.txt`: where the case runs from
- `argv.txt`: one CLI argument per line
- `exit_code.txt`
- optional `stdout-contains.txt`
- optional `stderr-contains.txt`
- optional `assert-files.txt`
- optional `assert-not-files.txt`
- optional `assert-contains.txt`

Run the matrix with:

```sh
./scripts/run-unit-tests.sh
```

Current coverage:

| Component | Case | Intent |
|---|---|---|
| `parser` | `query-minimal` | prove a tiny legal workspace parses and can be queried |
| `parser` | `invalid-string` | pin the string-literal parse diagnostic |
| `analyzer` | `config-select` | prove config-driven `select()` expansion reaches typed IR |
| `analyzer` | `invalid-field` | pin schema validation failures |
| `planner` | `action-dag-deps` | prove target planning emits a two-action DAG with deps |
| `executor` | `legacy-shell-success` | prove local execution commits declared outputs |
| `executor` | `strict-hidden-input` | prove strict mode blocks hidden inputs before output commit |
| `planner` | `node-workspace-graph` | prove `node.app` narrows inputs to reachable workspace packages while keeping workspace manifests visible for install/setup |
