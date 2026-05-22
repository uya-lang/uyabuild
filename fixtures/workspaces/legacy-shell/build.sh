#!/usr/bin/env sh
set -eu

printf 'legacy-shell stdout\n'
printf 'legacy-shell stderr\n' >&2

mkdir -p out
cat input.txt > out/result.txt
