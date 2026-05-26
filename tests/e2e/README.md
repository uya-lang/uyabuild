# End-to-End Sample Regression

The e2e sample suite exercises representative committed workspaces as whole
projects instead of single CLI snapshots.

Each scenario copies a fixture workspace into `tests/.tmp/`, runs the primary
`uyabuild` entrypoint for that sample, and checks for a small set of convincing
signals:

- `cxx-minimal`: `plan --json` produces the expected two-action graph
- `node-workspace`: `plan --json` preserves the workspace/app action chain
- `oci-multistage`: `plan --json` preserves the Docker action shape
- `legacy-shell`: `build` executes locally and commits the declared output

Run the suite with:

```sh
./scripts/run-e2e-tests.sh
```
