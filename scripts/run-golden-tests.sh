#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BIN="$ROOT_DIR/bin/uyabuild"
CASES_DIR="$ROOT_DIR/tests/golden/cases"

normalize_expected_file() {
  input_file=$1
  output_file=$2

  if [ "$(tr -d '\r\n\t ' < "$input_file" | wc -c | tr -d ' ')" -eq 0 ]; then
    : > "$output_file"
  else
    cp "$input_file" "$output_file"
  fi
}

if [ ! -x "$BIN" ]; then
  echo "bin/uyabuild is missing; run 'make bootstrap' first" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/tests/.tmp"
TMP_ROOT=$(mktemp -d "$ROOT_DIR/tests/.tmp/golden.XXXXXX")
cleanup_dirs=
trap 'rm -rf "$TMP_ROOT" $cleanup_dirs' EXIT INT TERM

pass_count=0
case_count=0

for case_dir in "$CASES_DIR"/*; do
  [ -d "$case_dir" ] || continue
  case_count=$((case_count + 1))
  case_name=$(basename "$case_dir")
  run_dir="$TMP_ROOT/$case_name"
  mkdir -p "$run_dir"

  cwd_mode=$(tr -d '\n' < "$case_dir/cwd.txt")
  case "$cwd_mode" in
    repo)
      workdir="$ROOT_DIR"
      ;;
    fixture:*)
      fixture_name=${cwd_mode#fixture:}
      workdir="$ROOT_DIR/fixtures/workspaces/$fixture_name"
      ;;
    fixture-copy:*)
      fixture_name=${cwd_mode#fixture-copy:}
      workdir=$(mktemp -d)
      cleanup_dirs="$cleanup_dirs $workdir"
      cp -R "$ROOT_DIR/fixtures/workspaces/$fixture_name/." "$workdir"
      ;;
    temp-empty)
      workdir=$(mktemp -d)
      cleanup_dirs="$cleanup_dirs $workdir"
      ;;
    *)
      echo "unknown cwd mode for $case_name: $cwd_mode" >&2
      exit 1
      ;;
  esac

  if [ -d "$workdir/.uya-build" ]; then
    rm -rf "$workdir/.uya-build"
  fi
  if [ -d "$workdir/.uya-build-custom" ]; then
    rm -rf "$workdir/.uya-build-custom"
  fi

  set --
  while IFS= read -r arg || [ -n "$arg" ]; do
    set -- "$@" "$arg"
  done < "$case_dir/argv.txt"

  stdout_file="$run_dir/stdout.txt"
  stderr_file="$run_dir/stderr.txt"
  expected_stdout="$run_dir/expected-stdout.txt"
  expected_stderr="$run_dir/expected-stderr.txt"

  status=0
  (
    cd "$workdir"
    "$BIN" "$@"
  ) >"$stdout_file" 2>"$stderr_file" || status=$?

  expected_status=$(tr -d '\n' < "$case_dir/exit_code.txt")
  if [ "$status" -ne "$expected_status" ]; then
    echo "FAIL $case_name: expected exit $expected_status, got $status" >&2
    exit 1
  fi

  normalize_expected_file "$case_dir/stdout.txt" "$expected_stdout"
  normalize_expected_file "$case_dir/stderr.txt" "$expected_stderr"

  diff -u "$expected_stdout" "$stdout_file"
  diff -u "$expected_stderr" "$stderr_file"

  if [ -f "$case_dir/assert-dirs.txt" ]; then
    while IFS= read -r relative_dir || [ -n "$relative_dir" ]; do
      [ -n "$relative_dir" ] || continue
      if [ ! -d "$workdir/$relative_dir" ]; then
        echo "FAIL $case_name: expected directory $relative_dir" >&2
        exit 1
      fi
    done < "$case_dir/assert-dirs.txt"
  fi

  if [ -d "$workdir/.uya-build" ]; then
    rm -rf "$workdir/.uya-build"
  fi
  if [ -d "$workdir/.uya-build-custom" ]; then
    rm -rf "$workdir/.uya-build-custom"
  fi

  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$case_name"
done

printf 'golden tests: %s/%s passed\n' "$pass_count" "$case_count"
