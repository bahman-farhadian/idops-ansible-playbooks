# 09. Smoke test

**Goal:** Prove the cluster actually works under load, not just that pods schedule — deploy a small nginx workload plus a scalable Debian `stress-ng` workload, ramp the second one up until the cluster is genuinely using roughly 80% of its worker capacity, watch it hold there via Grafana, then tear everything down cleanly.

## Teaching note

A green `kubectl get nodes` is not a test. Put a workload in its own namespace, push the workers, and watch Grafana. Then delete the namespace. If Ceph or Calico falls over under CPU load, you learned that before an application depends on it. The numbers in this file are examples. Read allocatable from the live nodes first.

Everything here goes in its own namespace so teardown is one command.

The example numbers below are illustrative. Recompute from `kubectl` allocatable on your actual nodes.

## Steps

**1. Create the namespace:**
```sh
kubectl create namespace smoke-test
```

**2. Baseline: read the cluster's real capacity before adding load.** Calico and Ceph-CSI already consume some of each worker. The Ceph daemons themselves run on `k8s-ceph-*`, not on these workers. Do not assume the raw VM spec is what's available:
```sh
kubectl describe nodes k8s-work-1 k8s-work-2 k8s-work-3 | grep -E "^(Name|.*cpu |.*memory )" -A0
# or, summed across the 3 workers:
kubectl get nodes k8s-work-1 k8s-work-2 k8s-work-3 -o json \
  | jq -r '.items[] | .status.allocatable.cpu + " " + .status.allocatable.memory'
```
Also check what's already requested (Ceph/Calico daemonsets, etc.):
```sh
kubectl describe nodes k8s-work-1 k8s-work-2 k8s-work-3 | grep -A5 "Allocated resources"
```
Write down: total allocatable CPU/memory across the workers, and what's already requested. The gap between "80% of allocatable" and "already requested" is what steps 4–5 need to add — work this out with your own numbers, not the ones below, which are illustrative only:

|                                  | Example (illustrative — use your own numbers)                   |
| -------------------------------- | --------------------------------------------------------------- |
| Allocatable, 3 workers combined  | 12 vCPU / 12 GB (3 × 4 vCPU/4 GB, minus kubelet/system reserve) |
| Already requested (Calico + CSI) | ~1.5 vCPU / ~1.5 GB                                             |
| 80% target                       | 9.6 vCPU / 9.6 GB                                               |
| Additional load to add           | ~8.1 vCPU / ~8.1 GB                                             |

**3. Deploy the baseline nginx workload** — small, fixed size, just proving ordinary app deployment + Service + Ingress still works normally under everything else running:
```yaml
# smoketest-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smoketest-nginx
  namespace: smoke-test
spec:
  replicas: 3
  selector:
    matchLabels: {app: smoketest-nginx}
  template:
    metadata:
      labels: {app: smoketest-nginx}
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports: [{containerPort: 80}]
          resources:
            requests: {cpu: "50m", memory: "32Mi"}
            limits: {cpu: "100m", memory: "64Mi"}
---
apiVersion: v1
kind: Service
metadata:
  name: smoketest-nginx
  namespace: smoke-test
spec:
  selector: {app: smoketest-nginx}
  ports: [{port: 80, targetPort: 80}]
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: smoketest-nginx
  namespace: smoke-test
spec:
  ingressClassName: traefik
  rules:
    - host: smoketest.lab.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service: {name: smoketest-nginx, port: {number: 80}}
```
Save the block above as `smoketest-nginx.yaml`. `kubectl apply` reads that file and stores it in the cluster.
```sh
kubectl apply -f smoketest-nginx.yaml
kubectl -n smoke-test rollout status deployment/smoketest-nginx
```
Verify through the API pair's port 80, added in [07-ingress.md](07-ingress.md):
```sh
curl -H "Host: smoketest.lab.local" http://10.0.1.10/   # API pair VIP, port 80 — expect the nginx welcome page
```

**4. Deploy the scalable Debian stress workload**, starting at 0 replicas — sizing (`cpu`/`memory` request=limit) matched to `stress-ng`'s flags so requested capacity and actual usage track each other:
```yaml
# smoketest-stress.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: smoketest-stress
  namespace: smoke-test
spec:
  replicas: 0
  selector:
    matchLabels: {app: smoketest-stress}
  template:
    metadata:
      labels: {app: smoketest-stress}
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: ScheduleAnyway
          labelSelector: {matchLabels: {app: smoketest-stress}}
      containers:
        - name: stress
          image: debian:trixie-slim
          command: ["sh", "-c"]
          args:
            - |
              apt-get update && apt-get install -y --no-install-recommends stress-ng
              exec stress-ng --cpu 1 --cpu-load 90 --vm 1 --vm-bytes 200M --vm-keep --timeout 900s --metrics-brief
          resources:
            requests: {cpu: "500m", memory: "256Mi"}
            limits: {cpu: "500m", memory: "256Mi"}
```
Each replica requests/uses ~0.5 vCPU / 256 Mi. `--timeout 900s` (15 min) is a safety net — if you walk away, load doesn't run forever; re-run `kubectl apply`/bump replicas to keep going past that.
Save the block above as `smoketest-stress.yaml`.
```sh
kubectl apply -f smoketest-stress.yaml
```

**5. Ramp up toward your target** (from step 2's math — for the illustrative numbers above, ~8 vCPU / 500m per pod ≈ 16 replicas), in a few increments rather than one jump, watching between each:
```sh
kubectl -n smoke-test scale deployment/smoketest-stress --replicas=6
sleep 60
kubectl describe nodes k8s-work-1 k8s-work-2 k8s-work-3 | grep -A5 "Allocated resources"
kubectl get pods -n smoke-test -o wide   # confirm spread across all 3 workers, none Pending

kubectl -n smoke-test scale deployment/smoketest-stress --replicas=12
sleep 60
kubectl -n smoke-test scale deployment/smoketest-stress --replicas=16   # or wherever your step-2 math landed
```
Watch actual usage climb on the "Node Exporter Full" Grafana dashboard from [08-observability.md](08-observability.md) — that's real usage, not just requests. If any pod stays `Pending`, `kubectl describe pod` it: you've hit the requested-capacity ceiling before reaching your live-usage target, which is itself a useful data point about how much headroom Calico and Ceph-CSI requests actually leave.

**6. Hold at ~80% for a few minutes and confirm nothing else broke:**
```sh
sudo ceph -s                              # still HEALTH_OK — storage shouldn't degrade under CPU/mem pressure
kubectl get pods -A | grep -v Running     # nothing unexpectedly Pending/CrashLooping/Evicted
kubectl describe nodes k8s-work-1 k8s-work-2 k8s-work-3 | grep -E "MemoryPressure|DiskPressure|PIDPressure"
curl -H "Host: smoketest.lab.local" http://10.0.1.10/   # API VIP :80, not the bastion
```

## Teardown

```sh
kubectl -n smoke-test scale deployment/smoketest-stress --replicas=0   # stop generating load first
kubectl delete namespace smoke-test                                    # then remove everything at once
```
Confirm on Grafana that CPU/memory on all workers drops back to baseline within a minute or two.

## Prerequisites
- [08-observability.md](08-observability.md) — you'll want Grafana open while this runs
- [07-ingress.md](07-ingress.md)

## Next
- [10-security.md](10-security.md)
