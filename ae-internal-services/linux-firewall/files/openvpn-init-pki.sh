#!/bin/bash
# Build one CA, the server certificate, and one client certificate per name.
# A second run leaves existing files in place so both firewall nodes
# keep presenting the same certificate after a VIP move.
set -euo pipefail

dest="${1:-}"
shift || true
if [[ -z "$dest" ]]; then
  echo "Usage: openvpn-init-pki.sh DEST_DIR [CLIENT ...]" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is not installed on the control node." >&2
  exit 1
fi

install -d -m 0700 "$dest"
for client_name in "$@"; do
  if [[ ! "$client_name" =~ ^[A-Za-z][A-Za-z0-9_-]{0,31}$ ]]; then
    echo "VPN client name '$client_name' must start with a letter and use only letters, digits, _ or -." >&2
    exit 1
  fi
done

ext_dir="$(mktemp -d)"
trap 'rm -rf "$ext_dir"' EXIT
printf 'extendedKeyUsage=serverAuth\nkeyUsage=digitalSignature,keyEncipherment\n' >"$ext_dir/server.ext"
printf 'extendedKeyUsage=clientAuth\nkeyUsage=digitalSignature\n' >"$ext_dir/client.ext"

issue() {
  local name="$1"
  local ext="$2"
  openssl req -newkey rsa:2048 -nodes \
    -keyout "$dest/${name}.key" \
    -out "$ext_dir/${name}.csr" \
    -subj "/CN=${name}"
  openssl x509 -req \
    -in "$ext_dir/${name}.csr" \
    -CA "$dest/ca.crt" \
    -CAkey "$dest/ca.key" \
    -CAcreateserial \
    -out "$dest/${name}.crt" \
    -days 3650 \
    -extfile "$ext"
  chmod 0600 "$dest/${name}.key"
}

created=0
if [[ ! -f "$dest/ca.crt" ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$dest/ca.key" \
    -out "$dest/ca.crt" \
    -days 3650 \
    -subj "/CN=idops-firewall-ca"
  chmod 0600 "$dest/ca.key"
  created=1
fi
if [[ ! -f "$dest/server.crt" ]]; then
  issue server "$ext_dir/server.ext"
  created=1
fi
for client_name in "$@"; do
  if [[ ! -f "$dest/${client_name}.crt" ]]; then
    issue "$client_name" "$ext_dir/client.ext"
    created=1
  fi
done
if [[ "$created" -eq 1 || ! -f "$dest/ca.crt" ]]; then
  echo "created"
else
  echo "present"
fi
