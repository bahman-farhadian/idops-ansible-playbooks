# Manual KVM guest provisioning

This runbook follows the workflow in `playbook.yml` and `tasks/`. The
Ansible project is the repeatable, guarded path; this manual path is for
learning the stages and recovering when Ansible is unavailable. It covers
one guest at a time. It does not reproduce the playbook's batching, host
slot control, restart recovery, or exact-scope cleanup safeguards. For
routine changes, use Ansible so observed state and disk chains are checked
before mutation.

Work on the KVM host as a user who can access the selected libvirt URI.
Use the values for one guest from `vars/01-hypervisors.yml` through
`vars/06-instances.yml` and the matching local settings file. Do not copy
real addresses, keys, or passwords into this repository.

## 1. Check the host

The playbook requires `virsh`, `qemu-img`, `cloud-localds`, `virt-install`,
`runuser`, and OVMF firmware. Install `acl`/`setfacl` only when the runtime
path checks need it. Debian or Ubuntu packages:

```bash
sudo apt-get update
sudo apt-get install -y libvirt-clients qemu-utils cloud-image-utils virtinst ovmf acl util-linux
```

Check the selected libvirt connection and required tools:

```bash
virsh -c qemu:///system uri
for command in virsh qemu-img cloud-localds virt-install runuser; do command -v "$command"; done
test -r /usr/share/OVMF/OVMF_CODE_4M.ms.fd
test -r /usr/share/OVMF/OVMF_VARS_4M.ms.fd
virsh -c qemu:///system net-list --all
```

Replace `qemu:///system` with the URI in the host settings if needed. Confirm
the chosen guest network exists and is active. An isolated libvirt network
does not route to guests from another machine; use SSH ProxyJump through the
KVM host when the control node cannot reach that network directly.

## 2. Set and check storage paths

Read `kvm_image_cache_path` and `kvm_instance_disk_pool_path` from the
selected settings. They must be absolute paths on this hypervisor. The image
cache and instance disk pool are separate roles; snapshot overlays are kept
in the instance disk pool. Do not assume `/var/lib/libvirt/images` is
allowed by this host's AppArmor, SELinux, or ACL policy.

```bash
sudo install -d -m 0755 /path/to/image-cache /path/to/instance-disks
namei -l /path/to/image-cache /path/to/instance-disks
```

Check access for the libvirt runtime user shown by `kvm_libvirt_runtime_user`
(usually `libvirt-qemu`). The playbook validates traversal and can optionally
add ACLs; a manual run must fix access deliberately before creating disks.

## 3. Acquire the pinned cloud image

Choose the instance's `image_profile_id` in `vars/06-instances.yml`. Read
that profile's distro, release token, filename pattern, URL, and checksum
algorithm from `vars/04-images.yml` and `tasks/provision.yml`. Keep the
release token pinned; do not use a moving `release/` URL for Ubuntu. Debian
uses the `generic` qcow2 image, and Ubuntu uses the `.img` file whose content
is qcow2.

The Ansible image-cache stage resolves the upstream checksum manifest once,
stores a local trusted checksum, verifies cached bytes, and fails closed on
a mismatch. For a manual acquisition, download the exact pinned artifact to
the configured cache and compare it with the checksum from that release's
official manifest before using it. Keep the manifest and trusted checksum
with the cache record. Do not disable verification to get past a mismatch.

```bash
cd /path/to/image-cache
curl --fail --location --retry 6 --retry-delay 20 --max-time 1800 \
  --output pinned-image.qcow2 'EXACT_PINNED_IMAGE_URL_FROM_THE_SELECTED_PROFILE'
printf '%s  %s\n' 'EXPECTED_CHECKSUM' pinned-image.qcow2 | sha512sum --check
```

Use `sha256sum --check` for profiles whose configured checksum algorithm is
`sha256`. Replace the uppercase tokens with the pinned URL and checksum; do
not commit real machine data or credential values.

## 4. Create the guest disks

Set shell variables from the instance definition and profile. `BASE_IMAGE`,
`DISK_POOL`, and `INSTANCE` must point to the values you verified above.

```bash
INSTANCE='guest-name'
BASE_IMAGE='/path/to/image-cache/pinned-image.qcow2'
DISK_POOL='/path/to/instance-disks'
ROOT_SIZE_GB=20
if test -e "$DISK_POOL/$INSTANCE-vda.qcow2"; then
  printf 'Refusing to overwrite existing disk: %s\n' "$DISK_POOL/$INSTANCE-vda.qcow2" >&2
  exit 1
fi
qemu-img convert -O qcow2 "$BASE_IMAGE" "$DISK_POOL/$INSTANCE-vda.qcow2"
qemu-img resize "$DISK_POOL/$INSTANCE-vda.qcow2" "${ROOT_SIZE_GB}G"
qemu-img info "$DISK_POOL/$INSTANCE-vda.qcow2"
```

For each declared extra disk, use its `guest_device`, size, and format from
the instance definition. Create the blank disk with `qemu-img create`; do not
format it on the host. Cloud-init formats and mounts it only when
`mount_point` is configured. `/var` is blocked unless the explicit override
is enabled.

## 5. Build the cloud-init seed

The playbook creates three per-instance files in its workspace: user-data,
meta-data, and network-config. Reproduce their content from the cloud-init
defaults in `vars/03-cloud-init.yml`, the instance values, and the render
logic in `tasks/provision-instances.yml` and
`tasks/provision-instances-batch-seed-define.yml`.

Include the required user, authorized key, password policy, hostname, pinned
timezone/locale, apt settings, package list, QEMU guest agent, SSH server,
zram unit, static primary NIC, and optional extra NICs/disks. Keep passwords
and private keys outside the repository. For network config, preserve the
profile's interface behavior: Debian 12 must not use `set-name`; the first
NIC owns the default route and an extra NIC has no gateway.

The seed path is `$DISK_POOL/$INSTANCE-seed.img`. Build the seed from those
three files:

```bash
cloud-localds --network-config /path/to/INSTANCE-network.yaml \
  /path/to/INSTANCE-seed.img \
  /path/to/INSTANCE-user-data.yaml \
  /path/to/INSTANCE-meta-data.yaml
```

Before continuing, review the seed contents locally and confirm the static
address, MAC address, hostname, and SSH key are for this guest.

## 6. Define and boot the UEFI guest

Use the machine type, OS variant, seed bus, MAC address, CPU, memory, and
libvirt network from the selected profile and instance. The playbook uses
OVMF pflash UEFI, a virtio root disk, a read-only cloud-init seed, and a
QEMU guest-agent virtio channel. Debian 12/13 and Ubuntu profiles use `q35`
and SCSI seed media in the current vars.

Set the remaining values from the profile and instance definition. Add
each extra disk and NIC declared for this instance before defining it.
Render the inactive XML with the same shape as the Ansible task:

```bash
URI='qemu:///system'
MEMORY_MB=2048
VCPU_COUNT=2
MACHINE='q35'
OS_VARIANT='debian13'
SEED_BUS='scsi'
NETWORK='default'
MAC='52:54:00:00:00:01'
virt-install --connect "$URI" --name "$INSTANCE" \
  --memory "$MEMORY_MB" --vcpus "$VCPU_COUNT,sockets=1,cores=$VCPU_COUNT,threads=1" \
  --machine "$MACHINE" --import \
  --boot loader=/usr/share/OVMF/OVMF_CODE_4M.ms.fd,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/OVMF/OVMF_VARS_4M.ms.fd \
  --disk "path=$DISK_POOL/$INSTANCE-vda.qcow2,format=qcow2,bus=virtio" \
  --disk "path=$DISK_POOL/$INSTANCE-seed.img,device=cdrom,bus=$SEED_BUS,format=raw,readonly=on" \
  --os-variant "$OS_VARIANT" \
  --network "network=$NETWORK,model=virtio,mac=$MAC" \
  --channel unix,target.type=virtio,target.name=org.qemu.guest_agent.0 \
  --graphics none --print-xml > "$INSTANCE-domain.xml"
```

Inspect the XML for OVMF pflash, the guest-agent channel, expected disks,
and NICs. Then define and start it:

```bash
virsh -c "$URI" define "$INSTANCE-domain.xml"
virsh -c "$URI" start "$INSTANCE"
virsh -c "$URI" domstate "$INSTANCE"
```

Do not run the `virt-install` command without `--print-xml`: the playbook
defines the domain first with all disks attached and then starts it only
after the seed is ready.

## 7. Wait for first boot and establish the baseline snapshot

The readiness gate is the QEMU guest agent, not a fixed sleep or a guest SSH
login. Check the guest-agent channel and cloud-init completion:

```bash
virsh -c qemu:///system domifaddr "$INSTANCE" --source agent
virsh -c qemu:///system domblklist "$INSTANCE" --inactive --details
```

On the guest console, confirm `/var/lib/cloud/instance/boot-finished`,
`ssh.service` active, TCP/22 listening, and any configured extra-disk mount.
If the agent never connects, inspect `/var/log/cloud-init-output.log` from
the console. Fix first-boot apt connectivity before rebuilding; cloud-init
does not retry a failed package install on the same disk.

After cloud-init completes, identify the seed device with
`virsh domblklist "$INSTANCE" --details`. Detach that device from the
persistent domain config with `virsh detach-disk "$INSTANCE" DEVICE
--config`; verify the seed path is absent from `domblklist --inactive`
before deleting the seed image. Then cleanly shut down the guest.

The baseline is an **atomic external disk snapshot**, not a libvirt memory
snapshot. Create its XML from the exact disk list and overlay paths in
`tasks/provision-runtime.yml`, then run the same `virsh snapshot-create
INSTANCE XML --disk-only --atomic` operation. Do not use a shorthand
`snapshot-create-as`: the project snapshot covers the root and every
declared extra disk as one transaction. Verify `virsh snapshot-list`,
`virsh snapshot-dumpxml`, and `virsh domblklist --inactive`, then start the
guest and confirm its active disks use the expected overlays. If any of
those checks disagree, stop and use the Ansible reconciliation path rather
than editing the chain by hand.

## 8. Verify

```bash
virsh -c "$URI" dominfo "$INSTANCE"
virsh -c "$URI" snapshot-list "$INSTANCE" --tree
virsh -c "$URI" domblklist "$INSTANCE" --details
```

Confirm the domain is running, the expected snapshot exists, the active disk
chain points into the instance pool, and the seed is no longer attached.
Ansible remains the supported path for reruns, reconciliation, snapshot
recovery, power actions, and cleanup. Do not manually delete disks or
domains outside the declared instance scope.
