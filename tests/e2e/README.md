# End-to-End Sample Regression

The e2e sample suite exercises representative committed workspaces as whole
projects instead of single CLI snapshots.

Each scenario copies a fixture workspace into `tests/.tmp/`, runs the primary
`uyabuild` entrypoint for that sample, and checks for a small set of convincing
signals:

- `cxx-minimal`: `build` executes the two-action C++ chain and emits a runnable binary
- `cxx-header-scan`: `build` discovers recursive `#include` inputs and rebuilds when a scanned header changes
- `cxx-test`: `test` builds a `cxx.test` target, executes the resulting binary, and reports a passing test
- `node-workspace`: `build` installs a local workspace/app chain and commits the declared frontend output
- `node-workspace-graph`: `build` narrows `node.app` inputs to reachable workspace packages, skips unrelated workspace edits, and rebuilds when a reachable package changes
- `oci-multistage`: `plan --json` preserves the Docker action shape
- `legacy-shell`: `build` executes locally and commits the declared output

Run the suite with:

```sh
./scripts/run-e2e-tests.sh
```
