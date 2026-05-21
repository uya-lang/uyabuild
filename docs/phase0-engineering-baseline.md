# Phase 0 Engineering Baseline

## Scope

Phase 0 only solves the bootstrap boundary and engineering baseline:

- `make bootstrap` compiles the pure `uya` source and nothing else
- post-bootstrap developer entrypoints unify under `uyabuild ...`
- the bootstrap binary owns command parsing, workspace discovery, and `.uya-build/` layout
- fixtures, golden tests, and benchmark recording are part of the committed baseline

It does not implement the DSL, graph analysis, or execution engine yet.

## Repository Layout

```text
build/
  bootstrap/
    seed/
      main.uya
benchmarks/
  baseline/
docs/
fixtures/
  workspaces/
scripts/
tests/
  golden/
```

Future runtime modules still follow the design target split:

```text
build/cli
build/core
build/dsl
build/analyzer
build/planner
build/executor
build/cas
build/meta
build/events
build/query
build/rules/*
build/adapters/*
build/bootstrap
```

## Naming Conventions

- docs: `kebab-case.md`
- scripts: `verb-noun.sh`
- fixtures: `fixtures/workspaces/<scenario>/`
- golden cases: `tests/golden/cases/<case-name>/`
- benchmark outputs: `benchmarks/baseline/<timestamp>.json`
- generated local state: `.uya-build/`

## Bootstrap Contract

`make bootstrap` and `bootstrap.sh` are limited to one responsibility:

1. call an existing `uya` compiler, defaulting to `../uya/bin/uya`
2. compile the `uya` sources under `build/bootstrap/seed/`
3. emit the first runnable `bin/uyabuild`

They must not absorb day-to-day build logic, tests, or release orchestration.

## State Directory Contract

The binary initializes the following layout on `uyabuild build ...` and `uyabuild query ...`:

```text
.uya-build/
  cas/
  meta/
  runs/
  tmp/
  locks/
  gc/
```

Each invocation also persists a minimal run manifest at:

```text
.uya-build/runs/<run-id>/invocation.json
```

## Golden Test Convention

Each golden case lives in its own directory and contains:

- `cwd.txt`: where the case runs from
- `argv.txt`: one CLI argument per line
- `exit_code.txt`
- `stdout.txt`
- `stderr.txt`
- optional `assert-dirs.txt`

The harness is `scripts/run-golden-tests.sh`.

## Benchmark Convention

Fixtures are committed under `fixtures/workspaces/`.

`scripts/benchmark-baseline.sh` records:

- bootstrap latency
- placeholder `uyabuild build` latency
- placeholder `uyabuild query` latency
- reserved fields for future null-build, single-file-edit, and cache-hit metrics

Benchmark output is written to `benchmarks/baseline/latest.json` and a timestamped snapshot.
