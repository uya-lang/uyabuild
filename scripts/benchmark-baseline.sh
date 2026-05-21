#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
OUT_DIR="$ROOT_DIR/benchmarks/baseline"
LATEST_JSON="$OUT_DIR/latest.json"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
SNAPSHOT_JSON="$OUT_DIR/$TIMESTAMP.json"

now_ns() {
  date +%s%N
}

measure_cmd() {
  start_ns=$(now_ns)
  if "$@" >/dev/null 2>&1; then
    status=0
  else
    status=$?
  fi
  end_ns=$(now_ns)
  elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
  printf '%s %s\n' "$status" "$elapsed_ms"
}

mkdir -p "$OUT_DIR"

make -C "$ROOT_DIR" clean >/dev/null
set -- $(measure_cmd make -C "$ROOT_DIR" bootstrap)
bootstrap_status=$1
bootstrap_ms=$2

fixture_cxx="$ROOT_DIR/fixtures/workspaces/cxx-minimal"
rm -rf "$fixture_cxx/.uya-build"
set -- $(measure_cmd sh -c "cd '$fixture_cxx' && '$ROOT_DIR/bin/uyabuild' build //app:hello")
build_status=$1
build_ms=$2

rm -rf "$fixture_cxx/.uya-build"
set -- $(measure_cmd sh -c "cd '$fixture_cxx' && '$ROOT_DIR/bin/uyabuild' query //...")
query_status=$1
query_ms=$2
rm -rf "$fixture_cxx/.uya-build"

cat > "$SNAPSHOT_JSON" <<EOF
{
  "timestamp_utc": "$TIMESTAMP",
  "binary_name": "uyabuild",
  "binary_version": "0.1.0-phase0",
  "environment": {
    "platform": "$(uname -s)",
    "kernel": "$(uname -r)",
    "arch": "$(uname -m)"
  },
  "measured": {
    "bootstrap_ms": $bootstrap_ms,
    "bootstrap_exit_code": $bootstrap_status,
    "build_placeholder_ms": $build_ms,
    "build_placeholder_exit_code": $build_status,
    "query_placeholder_ms": $query_ms,
    "query_placeholder_exit_code": $query_status
  },
  "reserved_for_future_phases": {
    "null_build_ms": null,
    "single_file_edit_ms": null,
    "cache_hit_rate": null,
    "note": "These metrics require planner, executor, and cache support from Phase 2-4."
  }
}
EOF

cp "$SNAPSHOT_JSON" "$LATEST_JSON"

printf 'wrote benchmark baseline to %s\n' "$SNAPSHOT_JSON"
