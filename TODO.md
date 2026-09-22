# TODO

Repository-wide work queue. Keep entries short; put the real design work in
the branch/PR that picks the item up, not in this file.

## ad-network-and-connectivity

- Perimeter firewall. The operator runs one project:
  - Debian/Ubuntu cloud-init guest (forward, NAT, DNAT, DMZ, OpenVPN, WireGuard)
  - OPNsense (own image, config.xml or HTTPS API)

## ac-vm-provisioning/kvm-vm-provisioning

No open items. Ubuntu 24.04 and 26.04 catalog profiles live in
`vars/04-images.yml` (`image_distro: ubuntu`).

## ae-internal-services/bind9-dns

No open items. Recursive cache plus authoritative `idops-repository.idops`.

## af-artifact-management/nexus-repository-systemd

- Hosted/private Docker registry (out of scope for the Hub proxy).
- Docker CE stable apt proxies for bookworm, trixie, noble, and resolute.
  `docker-engine` installs from those proxies and does not create them.
