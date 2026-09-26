#!/bin/bash
# One hypervisor, one budget. Disk clones and first boots take a slot.
# A dead holder is removed so a crashed play cannot leave the host full.
set -euo pipefail

slots="${1:?slot count}"
action="${2:?acquire or release}"
holder="${3:?holder path}"
controller_pid="${4:-}"
dir="/run/lock/idops-kvm-provision"
mkdir -p "$dir"
exec 9>"$dir/pool.lock"

holder_pid() {
  sed -n '1p' "$1" 2>/dev/null | tr -d '[:space:]'
}

reap() {
  local file pid
  for file in "$dir"/holder-*; do
    [ -e "$file" ] || continue
    pid="$(holder_pid "$file")"
    # A dead sleeper must not leave the only slot taken.
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$file"
    fi
  done
}

if [ "$action" = "release" ]; then
  flock 9
  if [ -f "$holder" ]; then
    pid="$(holder_pid "$holder")"
    if [ -n "$pid" ]; then
      kill "$pid" 2>/dev/null || true
    fi
    rm -f "$holder"
  fi
  exit 0
fi

if [ "$action" != "acquire" ]; then
  echo "action must be acquire or release" >&2
  exit 1
fi

while true; do
  flock 9
  reap
  count="$(find "$dir" -maxdepth 1 -name 'holder-*' | wc -l)"
  if [ "$count" -lt "$slots" ]; then
    # Line 2 is the controller ansible-playbook pid. A later play
    # releases this holder when that pid is gone, so a killed play
    # cannot keep the only slot until the async job times out.
    printf '%s\n%s\n' "$$" "${controller_pid:-0}" >"$holder"
    flock -u 9
    while true; do
      touch "$holder"
      sleep 30
    done
  fi
  flock -u 9
  sleep 2
done
