#!/usr/bin/env sh
set -eu

out_file=$1
hidden_file=$2
mkdir -p "$(dirname "$out_file")"

if [ -f "$hidden_file" ]; then
  printf 'HIDDEN=present\n' > "$out_file"
else
  printf 'HIDDEN=missing\n' > "$out_file"
fi
