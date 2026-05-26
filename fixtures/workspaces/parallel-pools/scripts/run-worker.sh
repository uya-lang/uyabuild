#!/usr/bin/env sh
set -eu

mode=$1
name=$2
peer=$3
out=$4

run_prefix=$(basename "$PWD" | sed 's/-[0-9][0-9]*$//')
shared_root="../$run_prefix-pool-state"

mkdir -p "$shared_root"
mkdir -p "$(dirname "$out")"

case "$mode" in
  parallel)
    : > "$shared_root/$name.started"
    i=0
    while [ "$i" -lt 20 ]; do
      if [ -f "$shared_root/$peer.started" ]; then
        printf 'parallel\n' > "$out"
        exit 0
      fi
      i=$((i + 1))
      sleep 0.1
    done
    printf 'serial\n' > "$out"
    ;;
  lock)
    lock_dir="$shared_root/$peer.lock"
    if mkdir "$lock_dir" 2>/dev/null; then
      sleep 0.6
      printf 'exclusive\n' > "$out"
      rmdir "$lock_dir"
    else
      printf 'overlap\n' > "$out"
    fi
    ;;
  *)
    printf 'unknown mode: %s\n' "$mode" >&2
    exit 1
    ;;
esac
