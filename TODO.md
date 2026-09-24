# TODO

Repository-wide work queue. Keep entries short; put the real design work in
the branch/PR that picks the item up, not in this file.

## ad-network-and-connectivity

- OPNsense perimeter firewall (later): own image, `config.xml` or HTTPS API.

## ac-vm-provisioning/kvm-vm-provisioning

No open items. Ubuntu 24.04 and 26.04 catalog profiles live in
`vars/04-images.yml` (`image_distro: ubuntu`).

## ae-internal-services/linux-dns-firewall

The same guest is BIND and the Linux firewall. Recursive cache plus
authoritative `idops-repository.idops`. Forwarding and SNAT stay in
the hardening firewall role.

## af-artifact-management/nexus-repository-systemd

- Hosted/private Docker registry (out of scope for the Hub proxy).
