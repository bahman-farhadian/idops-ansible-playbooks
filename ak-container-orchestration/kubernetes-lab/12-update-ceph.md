# 12. Update Ceph

**Goal:** Upgrade Ceph from the release deployed in [06-ceph.md](06-ceph.md) to the next pinned release. Do this only after that cluster is healthy and after [11-update-kubernetes.md](11-update-kubernetes.md).

## Teaching note

Upgrade monitors one by one, then managers, then OSDs. Set `noout` first so Ceph does not rebalance while a daemon restarts. On Debian 13 this is an Umbrella patch, not Squid to Tentacle, because Trixie has no Squid or Tentacle packages. The three OSDs still share one SSD, so a "node down" test is a VM test, not a disk test.

Debian 13 deployed Umbrella from [06-ceph.md](06-ceph.md). `download.ceph.com` has no Trixie suite for Squid or Tentacle (checked 2026-10-10), so this file is **not** a Squid → Tentacle walk on Trixie. Use a newer Umbrella patch from madison on the same `debian-umbrella` suite, or wait until Vampire publishes `trixie`. Ubuntu later: pick the suite the OS table lists, then one named release up. Order still matters: **mons (one at a time) → mgrs → OSDs (one node at a time)**. Check the target release's own upgrade notes on [docs.ceph.com](https://docs.ceph.com/en/latest/releases/) first — some releases require `ceph osd require-osd-release <name>` once every daemon is upgraded.

**1. Same suite, newer pin — or a new suite if madison shows one.** On all three Ceph VMs, then stop rebalancing while daemons restart.
```sh
CEPH_DEPLOY_RELEASE=umbrella      # the suite 06 wrote; Debian 13 has no squid/tentacle
CEPH_UPGRADE_RELEASE=umbrella     # stay here until Vampire has trixie; recheck docs.ceph.com
grep -n debian- /etc/apt/sources.list.d/ceph.list     # the suite you are leaving
# same suite: skip sed. A later named jump sets CEPH_UPGRADE_RELEASE and runs the next line.
if [ "$CEPH_DEPLOY_RELEASE" != "$CEPH_UPGRADE_RELEASE" ]; then
  sudo sed -i "s/debian-${CEPH_DEPLOY_RELEASE}/debian-${CEPH_UPGRADE_RELEASE}/" /etc/apt/sources.list.d/ceph.list
fi
grep -n debian- /etc/apt/sources.list.d/ceph.list     # apt reads this file
sudo apt update
apt-cache madison ceph-common                         # copy the new pin
CEPH_UPGRADE_VERSION="<from madison>"                 # must match madison
sudo ceph osd set noout                                # mons store this; it survives a daemon restart
```

**3. Mons, one node at a time** — quorum before the next node.
```sh
sudo apt-mark unhold ceph-mon ceph-common
sudo apt install -y ceph-mon=${CEPH_UPGRADE_VERSION} ceph-common=${CEPH_UPGRADE_VERSION}
sudo apt-mark hold ceph-mon ceph-common
sudo systemctl restart ceph-mon@k8s-ceph-1
sudo ceph -s                                   # quorum intact before k8s-ceph-2
```
Repeat on `k8s-ceph-2`, then `k8s-ceph-3`. A mixed-version mon quorum during this rolling upgrade is expected and safe.

**4. Mgrs, one node at a time.** The active mgr fails over for a moment. That is expected.
```sh
sudo apt-mark unhold ceph-mgr
sudo apt install -y ceph-mgr=${CEPH_UPGRADE_VERSION}
sudo apt-mark hold ceph-mgr
sudo systemctl restart ceph-mgr@k8s-ceph-1
```
Repeat on the other two; `ceph -s` shows the active mgr fail over to a standby momentarily — expected.

**5. OSDs, one Ceph VM at a time.** The Kubernetes workers have no OSD.
```sh
sudo apt-mark unhold ceph-osd
sudo apt install -y ceph-osd=${CEPH_UPGRADE_VERSION}
sudo apt-mark hold ceph-osd
sudo systemctl restart ceph-osd@$(ls /var/lib/ceph/osd | grep -oP 'ceph-\K[0-9]+')
sudo ceph -s          # healthy, noout still set, before the next node
```
Repeat on `k8s-ceph-2` and `k8s-ceph-3`.

**6. Clear `noout`.**
```sh
sudo ceph osd unset noout
sudo ceph versions     # every daemon on the new version
sudo ceph -s           # HEALTH_OK
```

## Prerequisites
- [06-ceph.md](06-ceph.md) healthy
- [11-update-kubernetes.md](11-update-kubernetes.md)

## Next
- [13-troubleshooting.md](13-troubleshooting.md)
