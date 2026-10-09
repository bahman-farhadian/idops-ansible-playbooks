# 15. Deployment log

**Goal:** Record the exact pinned versions actually used each time a profile is deployed or upgraded. The steps in this repo use version *variables* (`KUBE_DEPLOY_VERSION`, `CEPH_DEPLOY_VERSION`, …) rather than hardcoded numbers — this doc is where the concrete values you picked for a given run actually live, since [00-overview.md](00-overview.md) can't record them for you.

## Teaching note

The docs tell you to copy madison. This log is where you write what you actually installed. Date, event, versions. Do not overwrite an old row. You need that history when 11 and 12 ask "what did we start from?" Fill it on the day you run, not later.

## Applies to
All profiles and both etcd scenarios. Add one new row per deploy and per upgrade — don't overwrite previous rows, the history is the point (it's what makes [11-update-kubernetes.md](11-update-kubernetes.md) checkable afterward: what did we run, what did we upgrade to, when).

## How to use this doc

Copy the table below for each profile ([README.md](README.md#rollout-plan) stacked or GPU) the first time you deploy it, then append a row every time you deploy or upgrade that profile.

### Profile: _(Stacked / GPU)_ — Scenario _(stacked / external)_ — Distro _(Debian 13 / Ubuntu 26)_

| Date       | Event          | KUBE version | Containerd | Calico | Ceph release/version | Ceph-CSI chart | Traefik chart | node_exporter / Prometheus / Grafana | NVIDIA driver / toolkit / plugin (GPU only) | Notes |
| ---------- | -------------- | ------------ | ---------- | ------ | -------------------- | -------------- | ------------- | ------------------------------------ | ------------------------------------------- | ----- |
| YYYY-MM-DD | Initial deploy |              |            |        |                      |                |               |                                      |                                             |       |
| YYYY-MM-DD | K8s upgrade    |              |            |        |                      |                |               |                                      |                                             |       |
| YYYY-MM-DD | Ceph upgrade   |              |            |        |                      |                |               |                                      |                                             |       |

- **Date** — when the step actually ran, not when it was planned.
- **Event** — "Initial deploy" ([05-deploy-kubernetes.md](05-deploy-kubernetes.md) through [09-smoke-test.md](09-smoke-test.md)), "K8s upgrade" ([11-update-kubernetes.md](11-update-kubernetes.md)) or "Ceph upgrade" ([12-update-ceph.md](12-update-ceph.md)), or anything else worth a line (cert rotation, node replaced, etc.).
- Leave columns blank if that component wasn't touched in this event — e.g. a Ceph upgrade row only needs the Ceph column filled in.

## Prerequisites
- Populated as each profile is actually deployed — nothing to fill in before then.
