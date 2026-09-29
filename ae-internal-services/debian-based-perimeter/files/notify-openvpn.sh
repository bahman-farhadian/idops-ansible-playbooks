#!/bin/bash
# keepalived calls this as: notify-openvpn.sh GROUP NAME MASTER|BACKUP|FAULT
# OpenVPN stays stopped on the backup so only the VIP owner answers.
set -euo pipefail

state="${3:-}"
case "$state" in
  MASTER)
    systemctl start openvpn-server@admin openvpn-server@user
    ;;
  BACKUP | FAULT)
    systemctl stop openvpn-server@admin openvpn-server@user
    ;;
  *)
    echo "keepalived state '$state' was not MASTER, BACKUP, or FAULT" >&2
    exit 1
    ;;
esac
