#!/usr/bin/env sh
set -eu

mkdir -p out
cat input.txt > out/result.txt
printf 'generated\n' > generated.txt
