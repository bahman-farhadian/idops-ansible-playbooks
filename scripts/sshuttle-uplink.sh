#!/usr/bin/env bash
# Gives THIS host an internet uplink by tunneling its own outbound
# traffic through a remote relay over SSH (sshuttle, tproxy method).
#
# Use case: a hypervisor with only a point-to-point link to a control
# host and no WAN uplink of its own (e.g. Hephaestus/Dionysus reaching
# the internet via Silenus). Run on the host that needs the uplink; the
# relay named by SSHUTTLE_HOST is the host that already has one.
#
# This is the opposite direction from reaching INTO a hypervisor's
# internal VM subnets from a control host for Ansible/SSH - that is a
# per-lab runbook precondition (see runbooks/*.local.sh), not this
# script.
#
# To move this to another KVM host, copy the file and edit the four
# variables below for that host - nothing else in here is host-specific.
#
# CONTRIBUTOR-GUIDE.md debug note 10 warns a 0.0.0.0 SSHUTTLE_LISTEN
# self-locks the admin's own SSH session - confirmed not to apply to
# this tproxy+fwmark setup (that note is about sshuttle's default
# non-tproxy NAT method).
set -euo pipefail

SSHUTTLE_USER=changeme
SSHUTTLE_HOST=203.0.113.1
SSHUTTLE_PORT=22
SSHUTTLE_LISTEN=0.0.0.0:12300

cleanup() {
  ip rule del fwmark 0x1 lookup 100 2>/dev/null || true
  ip route del local default dev lo table 100 2>/dev/null || true
}
trap cleanup EXIT INT TERM

ip rule add fwmark 0x1 lookup 100 2>/dev/null || true
ip route add local default dev lo table 100 2>/dev/null || true

excludes=()
while read -r net _; do
  excludes+=(-x "$net")
done < <(ip -4 route show scope link)

sshuttle --dns --method tproxy -l "$SSHUTTLE_LISTEN" \
  -r "${SSHUTTLE_USER}@${SSHUTTLE_HOST}:${SSHUTTLE_PORT}" \
  0.0.0.0/0 "${excludes[@]}"

# If guest VM traffic on this hypervisor ends up captured by sshuttle's
# own NAT chain instead of going out its normal forward/NAT path (seen
# as first-boot apt/qemu-guest-agent failures - CONTRIBUTOR-GUIDE.md
# debug note 3), exempt the guest WAN subnet after sshuttle is up. The
# chain name is this process's listen port and changes on each run:
#   iptables -t nat -I sshuttle-12300 1 -s <guest-wan-subnet>/24 -j RETURN
