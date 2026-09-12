# TODO

Repository-wide work queue. Keep entries short; put the real design work in
the branch/PR that picks the item up, not in this file.

## ac-vm-provisioning/kvm-vm-provisioning

### Add Ubuntu support

Currently Debian-only, not just by convention but by hardcoded checks. This
is not a config-only change — three things need to become distro-aware:

1. **Image catalog URL/filename construction** —
   `tasks/provision.yml:44-59` builds `image_filename`, `image_url`, and
   `image_checksum_manifest_url` from a Jinja expression that hardcodes the
   `debian-<major>-<variant>-amd64-<version>.qcow2` filename pattern and the
   `cloud.debian.org` host. Ubuntu cloud images live at
   `cloud-images.ubuntu.com` with a different filename/versioning scheme, so
   this needs to become a per-distro template (or per-catalog-entry URL
   fields) rather than one hardcoded expression covering every entry.

2. **Validation regexes assume Debian** —
   `tasks/provision.yml:253` (`item.image_filename is match('^debian-.+\.qcow2$')`)
   and `tasks/provision.yml:259` (`item.virt_install_os_variant is match('^debian')`)
   both reject anything that isn't Debian by name. These need to accept
   Ubuntu's naming too, without loosening them into accepting garbage.

3. **Checksum manifest format** — Debian publishes `SHA512SUMS`; confirm
   Ubuntu's manifest format/filename and algorithm before assuming the
   existing checksum-resolution logic (`tasks/provision-resolve-checksum-cache.yml`)
   carries over unchanged.

`vars/04-images.yml` currently states the project is Debian-only in a
comment (line 25) — update that once the above lands, not before, so the
comment stays true while the work is in progress.

Worth deciding up front: one shared `kvm_cloud_image_catalog` with a
per-entry `image_distro` (or similar) field driving which URL template
applies, versus a fully separate catalog structure per distro. Affects all
three items above, so settle it before touching the task files.
