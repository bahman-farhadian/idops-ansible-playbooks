#!/bin/bash
# One hypervisor, one budget. Disk clones and first boots take a slot.
# A dead holder is removed so a crashed play cannot leave the host full.
set -euo pipefail

slots="${1:?slot count}"
action="${2:?acquire or release}"
holder="${3:?holder path}"
dir="/run/lock/idops-kvm-provision"
mkdir -p "$dir"
exec 9>"$dir/pool.lock"

reap() {
  local file pid
  for file in "$dir"/holder-*; do
    [ -e "$file" ] || continue
    pid="$(cat "$file" 2>/dev/null || true)"
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$file"
    fi
  done
}

if [ "$action" = "release" ]; then
  flock 9
  if [ -f "$holder" ]; then
    pid="$(cat "$holder" 2>/dev/null || true)"
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
    echo $$ >"$holder"
    flock -u 9
    while true; do
      touch "$holder"
      sleep 30
    done
  fi
  flock -u 9
  sleep 2
done
