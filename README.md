# UyaBuild

`UyaBuild` is the bootstrap workspace for the future `uya` build frontend.

## Quickstart

```sh
make bootstrap
./bin/uyabuild help
./bin/uyabuild query //...
./bin/uyabuild plan //bootstrap:uyabuild --json
```

Phase 2 currently provides:

- `uya.build` workspace loading, `include` expansion, and optional `uya.toml` workspace import
- a native DSL lexer/parser with source locations
- schema validation, label normalization, and a stable typed IR
- target-closure planning, input snapshots, file/tree/action-manifest/log CAS emission, action key calculation, and file-backed NoSQLite-style metadata indexes
- `uyabuild query`, `uyabuild plan --json`, and Phase 2 cache decisions such as `seeded-output`, `local-hit`, and `success-no-change`

Phase 3 now provides an initial local executor for `legacy.shell` and `task`:

- `uyabuild build` materializes a per-action temporary workspace, runs supported actions locally, captures `stdout`/`stderr`, and atomically commits declared outputs
- supported actions inherit only a small environment allowlist plus explicit `env_allowlist` entries from the rule
- executed actions persist `executed-local` metadata, log digests, and dedicated CAS log objects alongside the existing CAS/meta records

Still pending for later Phase 3 work:

- execution modes such as `pure/host/volatile`
- filesystem dependency tracking and strict hidden-input enforcement
- parallel resource pools, network policy, and broader rule-kind execution backends

Reference docs:

- [Phase 0 baseline](./docs/phase0-engineering-baseline.md)
- [Phase 1 DSL grammar](./docs/phase1-dsl-grammar.md)
- [Detailed design](./docs/uyabuild-detailed-design.md)
