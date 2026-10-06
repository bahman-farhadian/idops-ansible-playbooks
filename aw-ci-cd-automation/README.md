# aw-ci-cd-automation

Domain status: decision only (no playbook files yet)

## Purpose

Git hosting, CI, and CD for this environment. `gitlab/`, `jenkins/`, and `argocd/` are separate playbooks. Running one does not install another.

GitLab hosts git and runs CI. It does not deploy. Jenkins and Argo CD are the CD setups. Each one has its own install. A deployment that does not want GitLab as the CD tool uses Jenkins, Argo CD, or both.

## Playbook

- `gitlab/`
  - Community Edition, package `gitlab-ce`, pin 19.4.1, published 23 September 2026. There is no long-term line. 19.5 is still a pre-release, so it is not the pin
  - The application is MIT. The Linux package sources are Apache-2.0. The Enterprise package stays out. Premium and Ultimate stay out
  - One guest. The website, git, the CI coordinator, and the PostgreSQL, Redis, and nginx that ship in the package stay on that guest as a systemd service
  - One extra disk holds GitLab's data. The size stays in local settings
  - Debian 12, Debian 13, Ubuntu 24.04, and Ubuntu 26.04
  - The runner is a second guest inside this playbook. Package `gitlab-runner` 19.4.1. Its own local settings file. The administrator provides both guests
  - The deployment chooses the executor in the runner's local settings. A deployment that is not containerized uses the shell executor. A containerized deployment uses Docker, and only when `aj-container-runtime/docker-engine` is already installed on the runner guest. This playbook does not install Docker
  - The Nexus address is a DNS name in the runner's local settings. The perimeter already publishes that name. `debian-based-perimeter` serves the zone, and a project that chose `opnsense-firewall` uses that playbook's DNS. When the name is empty, no mirror is configured. The name is the Docker Hub pull cache on port 8082. This playbook does not read the perimeter's parameter file
  - GitLab's container registry stays off. GitLab's npm, Maven, and PyPI registry stays off. Nexus is the artifact store
  - This playbook runs CI jobs. It does not deploy the result
  - OS login stays on port 2222. GitLab's git SSH uses port 22
  - The TLS certificate stays in local settings
  - A deployment can point the web page at `aq-identity-and-access/keycloak`, or leave GitLab's own login. The choice is in local settings. This playbook does not require Keycloak
  - `am-databases/postgresql` and `an-data-caching/redis` stay on their own guests
  - This playbook does not create either guest and does not call provisioning or hardening
- `jenkins/`
  - Its own setup. One controller guest. Jenkins runs as a systemd service
  - Pin Jenkins 2.580.1 LTS, published 30 September 2026. The license is MIT. The weekly line stays out
  - Java 21. Debian 13, Ubuntu 24.04, and Ubuntu 26.04 use OpenJDK 21 from the OS archive. Debian 12's archive has Java 17, and this Jenkins release does not start on Java 17, so Debian 12 uses Temurin 21
  - The same four releases as the other guests
  - One extra disk holds Jenkins's data. The size stays in local settings
  - Agents on other guests are a later task in this same playbook. That task uses its own local settings file. It does not create the guest
  - Shell or Docker follows the same deployment rule as the GitLab runner. This playbook does not install Docker and does not use the GitLab runner
  - A deployment can point the web page at `aq-identity-and-access/keycloak`, or leave Jenkins's own login. The choice is in local settings. This playbook does not require Keycloak
  - This playbook does not create the guest and does not call provisioning or hardening
- `argocd/`
  - Its own setup. It watches a git repository and applies it to Kubernetes
  - It runs inside the cluster from `ak-container-orchestration/kubernetes`. It adds no guest. A deployment without Kubernetes does not run it
  - Pin Argo CD 3.5.3, published 14 September 2026. The license is Apache 2.0. There is no long-term line. 3.6 is not out, so it is not the pin
  - More than one copy of each component, so one pod can die
  - The git address and the cluster address stay in local settings
  - The install brings its own Redis. That Redis is not `an-data-caching/redis`
  - This playbook does not install Kubernetes, does not call that playbook, and does not install an ingress
  - A deployment can point the web page at `aq-identity-and-access/keycloak`, or leave Argo CD's own login. The choice is in local settings. This playbook does not require Keycloak

## Alternatives

- Forgejo.

## Left out

- Forgejo
- The GitLab Enterprise package, Premium, and Ultimate
- Using GitLab to deploy
- GitLab's container registry, and its npm, Maven, and PyPI registry
- A hosted Docker registry. Nexus stays the Docker Hub pull cache
- The Jenkins weekly line
- Running Jenkins 2.580.1 on Java 17
- Argo CD 3.6
- Argo Workflows and Argo Rollouts

## Dependencies

- Upstream: the guests and, for Argo CD, the Kubernetes cluster the administrator provides. These playbooks do not create them
- Downstream: git repositories, CI jobs, and deploys from Jenkins or Argo CD

## Status

- Playbook files: no
- Review: decided
