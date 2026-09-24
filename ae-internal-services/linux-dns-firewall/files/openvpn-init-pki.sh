#!/bin/bash
# Build one CA and the server, admin, and user certificates.
# A second run leaves existing files in place so both firewall nodes
# keep presenting the same certificate after a VIP move.
set -euo pipefail

dest="${1:-}"
if [[ -z "$dest" ]]; then
  echo "Usage: openvpn-init-pki.sh DEST_DIR" >&2
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "openssl is not installed on the control node." >&2
  exit 1
fi

install -d -m 0700 "$dest"

if [[ -f "$dest/ca.crt" && -f "$dest/server.crt" && -f "$dest/admin.crt" && -f "$dest/user.crt" ]]; then
  echo "present"
  exit 0
fi

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

if [[ ! -f "$dest/ca.crt" ]]; then
  openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "$dest/ca.key" \
    -out "$dest/ca.crt" \
    -days 3650 \
    -subj "/CN=idops-firewall-ca"
  chmod 0600 "$dest/ca.key"
fi

[[ -f "$dest/server.crt" ]] || issue server "$ext_dir/server.ext"
[[ -f "$dest/admin.crt" ]] || issue admin "$ext_dir/client.ext"
[[ -f "$dest/user.crt" ]] || issue user "$ext_dir/client.ext"
echo "created"
