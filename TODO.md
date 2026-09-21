# TODO

Repository-wide work queue. Keep entries short; put the real design work in
the branch/PR that picks the item up, not in this file.

## ac-vm-provisioning/kvm-vm-provisioning

No open items. Ubuntu 24.04 and 26.04 catalog profiles live in
`vars/04-images.yml` (`image_distro: ubuntu`).

## af-artifact-management/nexus-repository-systemd

- Add a hosted Docker repository later (today is Docker Hub reverse proxy only).
- After Nexus is up: fill the cache, then provision the four guests with
  `vars/settings.kvm.fleet-via-nexus.local.yml`.
