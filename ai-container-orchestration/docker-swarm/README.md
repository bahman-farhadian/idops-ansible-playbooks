# docker-swarm

Build a Docker Swarm on hosts that already run the engine from
`ah-container-runtime/docker-engine`. This playbook does not install
Docker and does not format disks.

Each member must already be Debian 12, Debian 13, Ubuntu 24.04, or
Ubuntu 26.04, x86_64, with Docker `29.8.1`, data-root `/docker`, and
`live-restore` false. Deploy reads `docker info` and refuses anything
else. Install that engine with `live_restore: false` on the host entry
before you run this playbook.

The first manager in `docker_swarm_managers` initializes the cluster.
The other managers join with the manager token. Workers join with the
worker token. The manager count must be odd. Tokens stay in the run
and are not written to a file.

The host firewall must already allow these ports between members:

- TCP `2377`
- TCP `7946`
- UDP `7946`
- UDP `4789`

This playbook does not open them.

`advertise_addr` is required on every member. Deploy does not use the
default-route address.

`docker_swarm_labels` and `docker_swarm_networks` are optional. A
network is created on the first manager as an overlay. An existing
network with a different driver or attachable flag is left in place
and deploy fails, so a running network is not recreated.

A node that is already `active` is not initialized again and is not
told to leave. `swarm init --force-new-cluster` is not an action.

## Raft recovery

When the remaining managers no longer have a quorum, pick one surviving
manager and run this on that host only:

```bash
docker swarm init --force-new-cluster --advertise-addr <that-host-advertise-addr>
```

Then run `make deploy` again with the same local settings file. The
other managers and the workers join the repaired cluster. Do this in a
maintenance window. The playbook will not run that command for you.

## Local settings

You must pass a `*.local.yml` file. There is no default.

```bash
make settings LOCAL_SETTINGS_FILE=vars/settings.docker-swarm.local.yml
```

Put managers and workers in that file. Do not put real addresses in
tracked vars.

## Commands

```bash
make help
make ping LOCAL_SETTINGS_FILE=vars/settings.docker-swarm.local.yml
make deploy LOCAL_SETTINGS_FILE=vars/settings.docker-swarm.local.yml
```

`make deploy` handles one member at a time, leader first, and stops at
the first failure. It then checks that every member is Ready, managers
are Leader or Reachable, and there is one leader.
