#!/bin/bash
# Wait until this play's holder files exist. A holder whose controller
# play pid is dead is released first, so a killed provision cannot keep
# the only host slot.
set -euo pipefail

remote="${1:?hypervisor}"
port="${2:?port}"
user="${3:-}"
shift 3
if [ "$#" -lt 1 ]; then
  echo "at least one holder path is required" >&2
  exit 1
fi
our=("$@")

ssh_base=(ssh -o BatchMode=yes -o ConnectTimeout=20 -p "$port")
if [ -n "$user" ]; then
  ssh_base+=(-l "$user")
fi
ssh_base+=("$remote")

remote_bash() {
  "${ssh_base[@]}" bash -s
}

deadline=$((SECONDS + 3600))
while [ "$SECONDS" -lt "$deadline" ]; do
  if ! rows="$(remote_bash << 'REMOTE'
set -euo pipefail
shopt -s nullglob
for f in /run/lock/idops-kvm-provision/holder-*; do
  sleeper="$(sed -n '1p' "$f" | tr -d '[:space:]')"
  owner="$(sed -n '2p' "$f" | tr -d '[:space:]')"
  printf '%s %s %s\n' "$f" "${sleeper:-0}" "${owner:-0}"
done
REMOTE
)"; then
    rows=""
  fi
  if [ -n "$rows" ]; then
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      # shellcheck disable=SC2086
      set -- $row
      path="$1"
      owner="${3:-0}"
      mine=0
      for have in "${our[@]}"; do
        if [ "$have" = "$path" ]; then
          mine=1
        fi
      done
      if [ "$mine" -eq 1 ]; then
        continue
      fi
      if [ "$owner" -gt 1 ] && ! kill -0 "$owner" 2>/dev/null; then
        "${ssh_base[@]}" bash /var/lib/idops/kvm-host-slot.sh 1 release "$path" || true
      fi
    done <<< "$rows"
  fi

  ready=1
  for path in "${our[@]}"; do
    if ! "${ssh_base[@]}" test -f "$path"; then
      ready=0
      break
    fi
  done
  if [ "$ready" -eq 1 ]; then
    exit 0
  fi
  sleep 2
done

echo "timed out waiting for a host provision slot" >&2
exit 1
