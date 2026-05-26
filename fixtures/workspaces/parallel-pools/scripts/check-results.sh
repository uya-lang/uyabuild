#!/usr/bin/env sh
set -eu

summary_out=$1

parallel_a=$(tr -d '\n' < out/parallel-a.txt)
parallel_b=$(tr -d '\n' < out/parallel-b.txt)
lock_a=$(tr -d '\n' < out/lock-a.txt)
lock_b=$(tr -d '\n' < out/lock-b.txt)

[ "$parallel_a" = "parallel" ]
[ "$parallel_b" = "parallel" ]
[ "$lock_a" = "exclusive" ]
[ "$lock_b" = "exclusive" ]

mkdir -p "$(dirname "$summary_out")"
{
  printf 'parallel-a=%s\n' "$parallel_a"
  printf 'parallel-b=%s\n' "$parallel_b"
  printf 'lock-a=%s\n' "$lock_a"
  printf 'lock-b=%s\n' "$lock_b"
} > "$summary_out"
