# UyaBuild

`UyaBuild` is the bootstrap workspace for the future `uya` build frontend.

## Quickstart

```sh
make bootstrap
./bin/uyabuild help
./bin/uyabuild query //...
./bin/uyabuild plan //bootstrap:uyabuild --json
```

Phase 1 currently provides:

- `uya.build` workspace loading, `include` expansion, and optional `uya.toml` workspace import
- a native DSL lexer/parser with source locations
- schema validation, label normalization, and a stable typed IR
- `uyabuild query` and `uyabuild plan --json`

Build execution intentionally still stops before planner/executor:

- `uyabuild build` fully analyzes and validates the graph
- planner, action graph, cache, and executor begin in later phases

Reference docs:

- [Phase 0 baseline](./docs/phase0-engineering-baseline.md)
- [Phase 1 DSL grammar](./docs/phase1-dsl-grammar.md)
- [Detailed design](./docs/uyabuild-detailed-design.md)
