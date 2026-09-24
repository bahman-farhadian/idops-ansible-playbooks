#!/bin/bash
# OpenVPN calls this as: tls-verify.sh ALLOW_FILE DEPTH SUBJECT
# Depth 0 is the client certificate. Other depths are the CA chain.
set -euo pipefail
export PATH="/usr/bin:/bin"

allow_file="${1:-}"
depth="${2:-}"
subject="${3:-}"

if [[ "$depth" != "0" ]]; then
  exit 0
fi

cn="$(printf '%s' "$subject" | sed -n 's~.*CN=\([^/,]*\).*~\1~p')"
if [[ -z "$cn" ]]; then
  echo "Client certificate has no CN." >&2
  exit 1
fi

grep -qx -- "$cn" "$allow_file"
