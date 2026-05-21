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
- target-closure planning, input snapshots, CAS object emission, action key calculation, and file-backed NoSQLite-style metadata indexes
- `uyabuild query`, `uyabuild plan --json`, and planning-only `uyabuild build` with `seeded-output`, `local-hit`, and `success-no-change`

Build execution intentionally still stops before the Phase 3 executor:

- `uyabuild build` now plans actions, performs early-cutoff output digest checks, seeds/checks the local cache index, and persists Phase 2 metadata
- pending actions still require the future executor/sandbox pipeline

Reference docs:

- [Phase 0 baseline](./docs/phase0-engineering-baseline.md)
- [Phase 1 DSL grammar](./docs/phase1-dsl-grammar.md)
- [Detailed design](./docs/uyabuild-detailed-design.md)
