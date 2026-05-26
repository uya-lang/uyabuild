#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
BIN="$ROOT_DIR/bin/uyabuild"
CASES_DIR="$ROOT_DIR/tests/unit/cases"

assert_file_contains_lines() {
  list_file=$1
  observed_file=$2
  case_name=$3
  stream_name=$4

  [ -f "$list_file" ] || return 0

  while IFS= read -r expected_line || [ -n "$expected_line" ]; do
    [ -n "$expected_line" ] || continue
    if ! grep -F -- "$expected_line" "$observed_file" >/dev/null 2>&1; then
      echo "FAIL $case_name: expected $stream_name to contain '$expected_line'" >&2
      echo "observed $stream_name:" >&2
      sed -n '1,200p' "$observed_file" >&2
      exit 1
    fi
  done < "$list_file"
}

if [ ! -x "$BIN" ]; then
  echo "bin/uyabuild is missing; run 'make bootstrap' first" >&2
  exit 1
fi

mkdir -p "$ROOT_DIR/tests/.tmp"
TMP_ROOT=$(mktemp -d "$ROOT_DIR/tests/.tmp/unit.XXXXXX")
cleanup_dirs=
trap 'rm -rf "$TMP_ROOT" $cleanup_dirs' EXIT INT TERM

pass_count=0
case_count=0

case_list_file="$TMP_ROOT/cases.txt"
find "$CASES_DIR" -type f -name exit_code.txt | sort > "$case_list_file"

while IFS= read -r exit_code_file; do
  case_dir=$(dirname "$exit_code_file")
  case_name=${case_dir#"$CASES_DIR"/}
  run_dir="$TMP_ROOT/$case_name"
  mkdir -p "$run_dir"
  case_count=$((case_count + 1))

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

  status=0
  (
    cd "$workdir"
    "$BIN" "$@"
  ) >"$stdout_file" 2>"$stderr_file" || status=$?

  expected_status=$(tr -d '\n' < "$case_dir/exit_code.txt")
  if [ "$status" -ne "$expected_status" ]; then
    echo "FAIL $case_name: expected exit $expected_status, got $status" >&2
    echo "observed stdout:" >&2
    sed -n '1,200p' "$stdout_file" >&2
    echo "observed stderr:" >&2
    sed -n '1,200p' "$stderr_file" >&2
    exit 1
  fi

  assert_file_contains_lines "$case_dir/stdout-contains.txt" "$stdout_file" "$case_name" "stdout"
  assert_file_contains_lines "$case_dir/stderr-contains.txt" "$stderr_file" "$case_name" "stderr"

  if [ -f "$case_dir/assert-files.txt" ]; then
    while IFS= read -r relative_file || [ -n "$relative_file" ]; do
      [ -n "$relative_file" ] || continue
      if [ ! -f "$workdir/$relative_file" ]; then
        echo "FAIL $case_name: expected file $relative_file" >&2
        exit 1
      fi
    done < "$case_dir/assert-files.txt"
  fi

  if [ -f "$case_dir/assert-not-files.txt" ]; then
    while IFS= read -r relative_file || [ -n "$relative_file" ]; do
      [ -n "$relative_file" ] || continue
      if [ -e "$workdir/$relative_file" ]; then
        echo "FAIL $case_name: unexpected path $relative_file" >&2
        exit 1
      fi
    done < "$case_dir/assert-not-files.txt"
  fi

  if [ -f "$case_dir/assert-contains.txt" ]; then
    while IFS= read -r assertion || [ -n "$assertion" ]; do
      [ -n "$assertion" ] || continue
      relative_file=${assertion%%|*}
      expected_text=${assertion#*|}
      if [ "$relative_file" = "$assertion" ]; then
        echo "FAIL $case_name: malformed assert-contains entry $assertion" >&2
        exit 1
      fi
      if [ ! -f "$workdir/$relative_file" ]; then
        echo "FAIL $case_name: expected file $relative_file for content assertion" >&2
        exit 1
      fi
      if ! grep -F -- "$expected_text" "$workdir/$relative_file" >/dev/null 2>&1; then
        echo "FAIL $case_name: expected '$expected_text' in $relative_file" >&2
        exit 1
      fi
    done < "$case_dir/assert-contains.txt"
  fi

  if [ -d "$workdir/.uya-build" ]; then
    rm -rf "$workdir/.uya-build"
  fi
  if [ -d "$workdir/.uya-build-custom" ]; then
    rm -rf "$workdir/.uya-build-custom"
  fi

  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$case_name"
done < "$case_list_file"

printf 'unit tests: %s/%s passed\n' "$pass_count" "$case_count"
