# 02. Prepare the VMs

**Goal:** Confirm every VM is in the expected starting state before any cluster-building step begins.

## Teaching note

kubeadm needs a unique machine-id on every node, no swap, and kernel settings that survive reboot. Write the file that boot reads, then load that file. A one-shot `sysctl -w` is gone after the next restart. Unique IDs matter because kubeadm treats two clones as the same node and stops. Do this on every VM in the table you circled, including the new Ceph VMs. Kernel bridge sysctls are for Kubernetes nodes only.

> Continues from the root docs — read [00-overview.md](00-overview.md) through [01-inventory.md](01-inventory.md) first if you haven't. Circle **one** profile × scenario in [01-inventory.md](01-inventory.md) **and one distro** (Debian 13 or Ubuntu 26). That table is the node list for every later step. Do not mix distros in one cluster.

## Covers
- Base OS: **Debian 13 ("Trixie")** *or* **Ubuntu 26 ("Resolute Raccoon")**, minimal install, fully updated (`apt update && apt full-upgrade`) before you start
- Every VM reachable by hostname/IP from your workstation (or via the bastion as a jump host) over SSH, key-based auth, with a `sudo`-capable non-root user — including `k8s-fw-1` / `k8s-fw-2`
- `curl`, `gnupg`, `ca-certificates` present (needed to add the Kubernetes/Ceph/Grafana apt repos in later steps)
- The LAN plan in the table you circled matches what's assigned (including firewall LAN IPs, `k8s-etcd-*` if external, `k8s-work-4` if GPU). WAN addresses on the firewalls are site-local and stay out of this repo. There is no `k8s-monitor` VM.
- Each firewall VM has two NICs (WAN + LAN)
- A working path to the internet **once the firewall pair is up** (step 06); before that, you may need a temporary default route to finish `apt` on the firewalls themselves

## Verify before continuing
```sh
# from the workstation, once per node
ssh <user>@<node-ip> 'grep -E "^(ID|VERSION_ID)=" /etc/os-release; sudo -n true && echo "sudo OK"'  # distro and passwordless sudo
ssh <user>@<node-ip> 'cat /sys/class/dmi/id/product_uuid; cat /etc/machine-id'                      # kubeadm rejects duplicates
```
Confirm `ID=debian` and `VERSION_ID="13"`, **or** `ID=ubuntu` and `VERSION_ID="26.04"` / `"26.10"` (whichever Ubuntu 26 ships as), and `sudo` works, for every node in that table.

`product_uuid` and `/etc/machine-id` must be different on every VM. kubeadm uses them to identify nodes and refuses the install when two match ([install-kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address)). A from-scratch install already has unique values. A clone does not: `sudo rm -f /etc/machine-id && sudo systemd-machine-id-setup`, and set a new SMBIOS UUID in the hypervisor before boot.

## OS baseline

**Goal:** Bring every VM to a common, Kubernetes-ready OS state.

## Applies to
Every node in the inventory table you circled in [01-inventory.md](01-inventory.md).

## Steps

**1. Hostname and `/etc/hosts`** — one inventory name per VM. The hosts block is the same on every node. Read both first. `hostnamectl` writes `/etc/hostname`. The resolver reads `/etc/hosts`. Skip the append if the grep already shows this scenario's names.
```sh
hostname
grep -n -E 'k8s-|10\.0\.1\.' /etc/hosts || true          # read before writing
sudo hostnamectl set-hostname k8s-ctrl-1                # this VM's name from the inventory table
hostnamectl --static                                    # must match that name
```
Run **one** append below, on every node. Stacked uses the first block. External etcd uses the second. These are the **example** LAN addresses from [01-inventory.md](01-inventory.md) — substitute yours if they differ. Do not add WAN addresses here. GPU: after the append, add `10.0.1.24  k8s-work-4` to the same file and run `getent hosts k8s-work-4`.

Stacked etcd:
```sh
sudo tee -a /etc/hosts <<'EOF'
10.0.1.1    k8s-fw-1
10.0.1.2    k8s-fw-2
10.0.1.8    k8s-lb-1
10.0.1.9    k8s-lb-2
10.0.1.254  k8s-fw-vip
10.0.1.10   k8s-apiserver
10.0.1.11   k8s-bastion
10.0.1.12   k8s-ctrl-1
10.0.1.13   k8s-ctrl-2
10.0.1.14   k8s-ctrl-3
10.0.1.21   k8s-work-1
10.0.1.22   k8s-work-2
10.0.1.23   k8s-work-3
10.0.1.25   k8s-ceph-1
10.0.1.26   k8s-ceph-2
10.0.1.27   k8s-ceph-3
EOF
getent hosts k8s-fw-vip k8s-apiserver k8s-ceph-1       # the file answers; no extra reload
```

External etcd (no `k8s-ctrl-3`; dedicated etcd instead):
```sh
sudo tee -a /etc/hosts <<'EOF'
10.0.1.1    k8s-fw-1
10.0.1.2    k8s-fw-2
10.0.1.8    k8s-lb-1
10.0.1.9    k8s-lb-2
10.0.1.254  k8s-fw-vip
10.0.1.10   k8s-apiserver
10.0.1.11   k8s-bastion
10.0.1.12   k8s-ctrl-1
10.0.1.13   k8s-ctrl-2
10.0.1.15   k8s-etcd-1
10.0.1.16   k8s-etcd-2
10.0.1.17   k8s-etcd-3
10.0.1.21   k8s-work-1
10.0.1.22   k8s-work-2
10.0.1.23   k8s-work-3
10.0.1.25   k8s-ceph-1
10.0.1.26   k8s-ceph-2
10.0.1.27   k8s-ceph-3
EOF
getent hosts k8s-fw-vip k8s-apiserver k8s-etcd-1 k8s-ceph-1
```

There is no `k8s-monitor` VM. Prometheus/Grafana and Nexus run on `k8s-bastion`.

**2. Disable swap** — kubeadm will not start while swap is on. Read it first. The file change is what survives reboot. `swapoff` only applies that file to the running system.
```sh
swapon --show                                          # empty means swap is already off
grep -n swap /etc/fstab                                # the line that comes back at boot
sudo sed -i '/\sswap\s/s/^/#/' /etc/fstab              # persist: comment the swap line
sudo swapoff -a                                        # apply the file to this boot
swapon --show                                          # must stay empty
```

**2b. Leave the install-time default route in place.** Step 6 needs outbound apt, and the LAN VIP (`10.0.1.254`) does not exist until keepalived is up in [03-firewall.md](03-firewall.md). Pointing the default route at it here black-holes that apt run. Step 06 replaces the temporary gateway after the VIP answers.

**3. Kernel modules and sysctl** — control planes and workers only. Skip firewalls, the API proxies, the bastion, the etcd-only nodes, and the Ceph VMs. Read the live values, write the boot files, then load those files. Do not use `sysctl -w` or a bare `modprobe` as the change.
```sh
lsmod | grep -E '^(overlay|br_netfilter)' || true
sysctl -n net.ipv4.ip_forward
sysctl -n net.bridge.bridge-nf-call-iptables 2>/dev/null || true   # fails until br_netfilter is loaded
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf                  # loaded on every boot
overlay
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf                        # bridged traffic must pass iptables
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo systemctl restart systemd-modules-load.service                # read modules-load.d
sudo sysctl --system                                               # read sysctl.d
sysctl -n net.ipv4.ip_forward                                      # must print 1
lsmod | grep -E '^(overlay|br_netfilter)'
```

**4. Time sync** — both distros already enable `systemd-timesyncd`. Confirm it.
```sh
timedatectl status | grep "synchronized"   # must say yes before certificates are issued
```

**5. Host packet filter** — cluster nodes only. The firewall VMs are [03-firewall.md](03-firewall.md). Read whether a filter is already running. If neither is active, leave it that way. If one is active, allow the LAN from the file that service reads, then reload that service. `nft add` is gone at the next reboot.
```sh
systemctl is-active nftables || true
systemctl is-active ufw || true
sudo nft list ruleset || true                                    # what is loaded now
```
nftables active: read `/etc/nftables.conf`, add the allows there, `sudo nft -c -f /etc/nftables.conf`, then `sudo systemctl restart nftables`. ufw active: `sudo ufw status`, then `sudo ufw allow from 10.0.1.0/24` — that writes `/etc/ufw/user.rules` and ufw loads it. Port list: [01-inventory.md](01-inventory.md).

**6. Base packages** — still on the temporary default route. No cluster packages yet, so nothing to hold.
```sh
sudo apt update && sudo apt full-upgrade -y                              # current OS before any repo is added
sudo apt install -y curl gnupg ca-certificates apt-transport-https       # needed to add signed apt repos later
```

## Prerequisites
- [01-inventory.md](01-inventory.md)

## Next
- [03-firewall.md](03-firewall.md)
