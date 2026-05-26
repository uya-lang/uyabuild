#!/usr/bin/env sh
set -eu

mode=$1
out=$2

python3 - "$mode" "$out" <<'PY'
import errno
import pathlib
import socket
import sys

mode, out = sys.argv[1], sys.argv[2]
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

try:
    sock.connect(("1.1.1.1", 53))
    reachable = True
    error = None
except OSError as exc:
    reachable = False
    error = exc
finally:
    sock.close()

if mode == "blocked":
    if reachable:
        raise SystemExit("expected network namespace isolation to block the route")
    if getattr(error, "errno", None) != errno.ENETUNREACH:
        raise SystemExit(f"expected errno {errno.ENETUNREACH}, got {error!r}")
    pathlib.Path(out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(out).write_text("blocked\n", encoding="utf-8")
elif mode == "allowed":
    if not reachable:
        raise SystemExit(f"expected host networking, got {error!r}")
    pathlib.Path(out).parent.mkdir(parents=True, exist_ok=True)
    pathlib.Path(out).write_text("allowed\n", encoding="utf-8")
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
