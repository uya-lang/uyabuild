#!/usr/bin/env sh
set -eu

out_file=$1
mkdir -p "$(dirname "$out_file")"
printf 'volatile-executed\n' > "$out_file"
