# 14. GPU node

**Goal:** After a healthy stacked or external cluster, add `k8s-work-4` as a tainted NVIDIA worker. GPU is that cluster plus this step, not a from-scratch build.

**Status:** Outline — fill in with real commands on the first GPU run. PCI passthrough / IOMMU is hypervisor-level and out of scope (see [00-overview.md](00-overview.md)); this repo assumes the GPU is already visible inside the VM.

## Teaching note

A GPU worker is a tainted node. Only pods that ask for a GPU and tolerate the taint land there. Do not join this VM to Ceph. The toolkit change is a file in containerd, then a restart, not a live-only flag. This page has no commands until a GPU is actually in the guest.

Do this only when `k8s-work-4` is in the table you deployed ([01-inventory.md](01-inventory.md), 12 GB or 16 GB, no Ceph disk). It should already have been joined in [05-deploy-kubernetes.md](05-deploy-kubernetes.md). Do not add it to the Ceph cluster.

## Covers
- Confirm the GPU is visible in the guest (`lspci`, `nvidia-smi` after the driver)
- NVIDIA driver + `nvidia-container-toolkit` inside the VM
- Wire the toolkit into containerd: read `/etc/containerd/config.toml`, write that file, then restart containerd and kubelet. Do not change the running daemon only in memory
- Label + **taint** `k8s-work-4` (`nvidia.com/gpu=present:NoSchedule`) so ordinary pods cannot land there
- NVIDIA Kubernetes device plugin DaemonSet (plain device plugin — no GPU Operator / MIG / time-slicing, per [00-overview.md](00-overview.md#fixed-decisions))
- A one-pod smoke test that *tolerates* the taint and requests `nvidia.com/gpu: 1`

## Prerequisites
- Stacked or external cluster already through [09-smoke-test.md](09-smoke-test.md)
- [01-inventory.md](01-inventory.md) GPU table (Scenario A or B)

## Next
- [15-deployment-log.md](15-deployment-log.md)
