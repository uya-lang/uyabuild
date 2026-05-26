#!/usr/bin/env sh
set -eu

mkdir -p out
cat input.txt > out/result.txt
printf 'extra\n' > out/extra.txt
