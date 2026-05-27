#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BIN="$ROOT_DIR/bin/uyabuild"

assert_output_contains() {
  output_file=$1
  expected=$2
  case_name=$3

  if ! grep -F -- "$expected" "$output_file" >/dev/null 2>&1; then
    echo "FAIL $case_name: expected output to contain '$expected'" >&2
    echo "observed output:" >&2
    sed -n '1,200p' "$output_file" >&2
    exit 1
  fi
}

assert_dir_exists() {
  dir_path=$1
  case_name=$2

  if [ ! -d "$dir_path" ]; then
    echo "FAIL $case_name: expected directory $dir_path" >&2
    exit 1
  fi
}

assert_file_contains() {
  file_path=$1
  expected=$2
  case_name=$3

  if [ ! -f "$file_path" ]; then
    echo "FAIL $case_name: expected file $file_path" >&2
    exit 1
  fi
  if ! grep -F -- "$expected" "$file_path" >/dev/null 2>&1; then
    echo "FAIL $case_name: expected '$expected' in $file_path" >&2
    sed -n '1,120p' "$file_path" >&2
    exit 1
  fi
}

assert_file_exists() {
  file_path=$1
  case_name=$2

  if [ ! -f "$file_path" ]; then
    echo "FAIL $case_name: expected file $file_path" >&2
    exit 1
  fi
}

assert_executable_runs() {
  file_path=$1
  case_name=$2

  if [ ! -x "$file_path" ]; then
    echo "FAIL $case_name: expected executable $file_path" >&2
    exit 1
  fi
  "$file_path"
}

run_plan_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  shift 3

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  stdout_file="$workdir/stdout.txt"
  stderr_file="$workdir/stderr.txt"

  (
    cd "$workdir"
    "$BIN" plan --json "$target_label"
  ) >"$stdout_file" 2>"$stderr_file"

  while [ "$#" -gt 0 ]; do
    assert_output_contains "$stdout_file" "$1" "$case_name"
    shift
  done

  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/runs" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_executable_build_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  executable_path=$4
  expected_workspace=$5
  expected_action_count=$6

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  stdout_file="$workdir/stdout.txt"
  stderr_file="$workdir/stderr.txt"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$stdout_file" 2>"$stderr_file"

  assert_file_exists "$workdir/$executable_path" "$case_name"
  assert_executable_runs "$workdir/$executable_path" "$case_name"
  assert_output_contains "$stdout_file" "workspace: $expected_workspace" "$case_name"
  assert_output_contains "$stdout_file" "planned_actions: $expected_action_count" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_test_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  executable_path=$4
  expected_workspace=$5
  expected_action_count=$6
  expected_stdout=$7

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  stdout_file="$workdir/stdout.txt"
  stderr_file="$workdir/stderr.txt"

  (
    cd "$workdir"
    "$BIN" test "$target_label"
  ) >"$stdout_file" 2>"$stderr_file"

  assert_file_exists "$workdir/$executable_path" "$case_name"
  assert_output_contains "$stdout_file" "workspace: $expected_workspace" "$case_name"
  assert_output_contains "$stdout_file" "planned_actions: $expected_action_count" "$case_name"
  assert_output_contains "$stdout_file" "$expected_stdout" "$case_name"
  assert_output_contains "$stdout_file" "PASS $target_label" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_cxx_header_rebuild_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  header_path=$4
  executable_path=$5
  expected_workspace=$6
  expected_action_count=$7

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  first_stdout="$workdir/first-stdout.txt"
  first_stderr="$workdir/first-stderr.txt"
  second_stdout="$workdir/second-stdout.txt"
  second_stderr="$workdir/second-stderr.txt"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$first_stdout" 2>"$first_stderr"

  assert_file_exists "$workdir/$executable_path" "$case_name"
  assert_executable_runs "$workdir/$executable_path" "$case_name"
  assert_output_contains "$first_stdout" "workspace: $expected_workspace" "$case_name"
  assert_output_contains "$first_stdout" "planned_actions: $expected_action_count" "$case_name"

  printf '\n// scanner regression touch\n' >>"$workdir/$header_path"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$second_stdout" 2>"$second_stderr"

  assert_executable_runs "$workdir/$executable_path" "$case_name"
  assert_output_contains "$second_stdout" "workspace: $expected_workspace" "$case_name"
  assert_output_contains "$second_stdout" "success_no_change: $expected_action_count" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_build_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  output_file=$4
  expected_text=$5

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  stdout_file="$workdir/stdout.txt"
  stderr_file="$workdir/stderr.txt"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$stdout_file" 2>"$stderr_file"

  assert_file_contains "$workdir/$output_file" "$expected_text" "$case_name"
  assert_output_contains "$stdout_file" "workspace: legacy-shell" "$case_name"
  assert_output_contains "$stdout_file" "planned_actions: 1" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_node_build_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  output_file=$4
  expected_text=$5
  metadata_file=$6
  metadata_text=$7
  expected_workspace=$8
  expected_action_count=$9

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  stdout_file="$workdir/stdout.txt"
  stderr_file="$workdir/stderr.txt"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$stdout_file" 2>"$stderr_file"

  assert_file_contains "$workdir/$output_file" "$expected_text" "$case_name"
  assert_file_contains "$workdir/$metadata_file" "$metadata_text" "$case_name"
  assert_output_contains "$stdout_file" "workspace: $expected_workspace" "$case_name"
  assert_output_contains "$stdout_file" "planned_actions: $expected_action_count" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

run_node_graph_rebuild_case() {
  case_name=$1
  fixture_name=$2
  target_label=$3
  target_output_file=$4
  initial_text=$5
  workspace_metadata_file=$6
  workspace_metadata_text=$7
  expected_workspace_name=$8
  expected_action_count=$9
  unrelated_file=${10}
  related_file=${11}
  related_content=${12}
  updated_text=${13}

  workdir=$(mktemp -d "$TMP_ROOT/$case_name.XXXXXX")
  cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"

  first_stdout="$workdir/first-stdout.txt"
  first_stderr="$workdir/first-stderr.txt"
  second_stdout="$workdir/second-stdout.txt"
  second_stderr="$workdir/second-stderr.txt"
  third_stdout="$workdir/third-stdout.txt"
  third_stderr="$workdir/third-stderr.txt"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$first_stdout" 2>"$first_stderr"

  assert_file_contains "$workdir/$target_output_file" "$initial_text" "$case_name"
  assert_file_contains "$workdir/$workspace_metadata_file" "$workspace_metadata_text" "$case_name"
  assert_output_contains "$first_stdout" "workspace: $expected_workspace_name" "$case_name"
  assert_output_contains "$first_stdout" "planned_actions: $expected_action_count" "$case_name"

  printf '\n// unrelated workspace touch\n' >>"$workdir/$unrelated_file"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$second_stdout" 2>"$second_stderr"

  assert_file_contains "$workdir/$target_output_file" "$initial_text" "$case_name"
  assert_output_contains "$second_stdout" "workspace: $expected_workspace_name" "$case_name"
  assert_output_contains "$second_stdout" "planned_actions: $expected_action_count" "$case_name"

  printf '%s\n' "$related_content" >"$workdir/$related_file"

  (
    cd "$workdir"
    "$BIN" build "$target_label"
  ) >"$third_stdout" 2>"$third_stderr"

  assert_file_contains "$workdir/$target_output_file" "$updated_text" "$case_name"
  assert_output_contains "$third_stdout" "workspace: $expected_workspace_name" "$case_name"
  assert_output_contains "$third_stdout" "planned_actions: $expected_action_count" "$case_name"
  assert_dir_exists "$workdir/.uya-build/cas" "$case_name"
  assert_dir_exists "$workdir/.uya-build/meta" "$case_name"
  assert_dir_exists "$workdir/.uya-build/tmp" "$case_name"

  printf 'PASS %s\n' "$case_name"
}

if [ ! -x "$BIN" ]; then
  echo "bin/uyabuild is missing; run 'make bootstrap' first" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/tests/.tmp"
TMP_ROOT=$(mktemp -d "$ROOT_DIR/tests/.tmp/e2e.XXXXXX")
trap 'rm -rf "$TMP_ROOT"' EXIT INT TERM

pass_count=0

run_executable_build_case \
  "sample-cxx-minimal" \
  "cxx-minimal" \
  "//app:hello" \
  "out/bin/hello" \
  "cxx-minimal" \
  "2"
pass_count=$((pass_count + 1))

run_cxx_header_rebuild_case \
  "sample-cxx-header-scan" \
  "cxx-header-scan" \
  "//app:hello" \
  "src/detail.h" \
  "out/bin/hello" \
  "cxx-header-scan" \
  "2"
pass_count=$((pass_count + 1))

run_test_case \
  "sample-cxx-test" \
  "cxx-test" \
  "//tests:smoke" \
  "out/tests/smoke" \
  "cxx-test" \
  "2" \
  "smoke test passed"
pass_count=$((pass_count + 1))

run_node_build_case \
  "sample-node-workspace" \
  "node-workspace" \
  "//web:app" \
  "dist/app/message.txt" \
  "hello from workspace" \
  "out/web/workspace.workspace.json" \
  "\"workspaceCount\": 2" \
  "node-workspace" \
  "2"
pass_count=$((pass_count + 1))

run_node_graph_rebuild_case \
  "sample-node-workspace-graph" \
  "node-workspace-graph" \
  "//web:app" \
  "dist/app/message.txt" \
  "hello from workspace graph" \
  "out/web/workspace.workspace.json" \
  "\"localDependencies\": [" \
  "node-workspace-graph" \
  "2" \
  "packages/unused/src/index.js" \
  "packages/lib/src/index.js" \
  "module.exports = \"hello from updated workspace graph\";" \
  "hello from updated workspace graph"
pass_count=$((pass_count + 1))

run_plan_case \
  "sample-oci-multistage" \
  "oci-multistage" \
  "//image:demo" \
  '"name":"oci-multistage"' \
  '"label":"//image:demo"' \
  '"pool":"docker"' \
  '"command":["docker","buildx","build"]'
pass_count=$((pass_count + 1))

run_build_case \
  "sample-legacy-shell" \
  "legacy-shell" \
  "//legacy:echo" \
  "out/result.txt" \
  "legacy fixture"
pass_count=$((pass_count + 1))

printf 'e2e tests: %s/%s passed\n' "$pass_count" 7
