# UyaBuild

`UyaBuild` is the bootstrap workspace for the future `uya` build frontend.

## Quickstart

```sh
make bootstrap
./bin/uyabuild help
./bin/uyabuild build //bootstrap:uyabuild
```

Phase 0 intentionally stops at:

- a minimal `make bootstrap -> bin/uyabuild` cold-start path
- unified developer entrypoints under `uyabuild ...`
- `.uya-build/` state layout initialization
- golden-test and benchmark scaffolding

The actual parser, IR, planner, and executor begin in Phase 1+.
