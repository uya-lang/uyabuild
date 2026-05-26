# UyaBuild

`UyaBuild` is the bootstrap workspace for the future `uya` build frontend.

## Quickstart

```sh
make bootstrap
make test
./bin/uyabuild help
./bin/uyabuild query //...
./bin/uyabuild plan //bootstrap:uyabuild --json
./bin/uyabuild why //bootstrap:uyabuild
./bin/uyabuild test //tests:smoke
```

Test entrypoints:

- `make test` runs the focused unit matrix, the golden regression suite, and the sample-workspace end-to-end matrix
- `./scripts/run-unit-tests.sh` runs the parser/analyzer/planner/executor unit matrix only
- `./scripts/run-golden-tests.sh` runs the CLI golden cases
- `./scripts/run-e2e-tests.sh` runs the representative workspace regression cases

Phase 2 currently provides:

- `uya.build` workspace loading, `include` expansion, and optional `uya.toml` workspace import
- a native DSL lexer/parser with source locations
- schema validation, label normalization, and a stable typed IR
- target-closure planning, input snapshots, file/tree/action-manifest/log CAS emission, action key calculation, and file-backed NoSQLite-style metadata indexes
- `uyabuild query`, `uyabuild plan --json`, and Phase 2 cache decisions such as `seeded-output`, `local-hit`, and `success-no-change`

Phase 3 now provides an initial local executor for `legacy.shell`, `task`, and the minimal `cxx` rule path:

- `uyabuild build` materializes a per-action temporary workspace, runs supported actions locally, captures `stdout`/`stderr`, and atomically commits declared outputs
- `uyabuild test` now builds `cxx.test` targets and executes the produced test binaries from the workspace root
- `uyabuild why` now explains whether planned targets are `local-hit`, `seeded-output`, `success-no-change`, or still `pending-execution`
- `uyabuild build --jobs <n>` now schedules supported local actions in parallel, with `pool = "link" | "docker" | "network"` and other non-`cpu` pool names serialized one at a time
- supported actions now honor `execution_mode = "pure" | "host" | "volatile"`: `pure` keeps undeclared workspace files out of the action root, `host` materializes the broader workspace for compatibility, and `volatile` always re-executes instead of reusing local cache decisions
- supported actions now default to host networking off and require `allow_network = true` to opt back into the host network namespace
- supported actions inherit only a small environment allowlist plus explicit `env_allowlist` entries from the rule
- executed actions persist `executed-local` metadata, log digests, and dedicated CAS log objects alongside the existing CAS/meta records
- executed actions now persist immutable ActionRecord history entries in `meta/actions/` and matching CAS objects under `.uya-build/cas/action-records/`
- executed actions also persist tracked read/write path lists for declared inputs, upstream outputs, and declared outputs as the Phase 3 dependency-tracking interface
- Linux builds now wrap supported local actions with `strace` so compat mode records `hidden_inputs` / `undeclared_outputs`, and `workspace.strict = true` turns those findings into hard failures before output commit

Still pending for later Phase 3 work:

- a macOS dependency-tracing backend for the same hidden-input / undeclared-output checks
- broader rule-kind execution backends beyond `cxx`, especially `node` and `oci`

Reference docs:

- [Phase 0 baseline](./docs/phase0-engineering-baseline.md)
- [Phase 1 DSL grammar](./docs/phase1-dsl-grammar.md)
- [Detailed design](./docs/uyabuild-detailed-design.md)
