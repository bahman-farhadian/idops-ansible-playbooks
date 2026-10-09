# 07. Ingress

**Goal:** Expose services outside the cluster.

## Teaching note

Pods are not on the LAN. Ingress is the door. Traefik watches Ingress objects and opens 80 and 443. Those ports bind on the same API VIP as 6443, on the HAProxy pair, not on the bastion. Check `http://10.0.1.10/`, not the bastion address. This lab has no cert-manager. HTTPS is for later.

**Choice:** Traefik — ingress-nginx is being sunset upstream, so this lab standardizes on Traefik instead. No cert-manager for this lab (internal-only); revisit if you expose services externally.

## Steps

**1. Traefik** — from `k8s-bastion`. The pin is the `--version` flag. Never upgrade without it.
```sh
helm repo add traefik https://traefik.github.io/charts && helm repo update
helm search repo traefik/traefik --versions | head          # copy one chart version
TRAEFIK_CHART_VERSION="<version from the list above>"
kubectl create namespace traefik
helm install traefik traefik/traefik -n traefik --version "${TRAEFIK_CHART_VERSION}"
kubectl get svc -n traefik                                  # note the NodePort for 80 and 443
```

**2. Publish 80 and 443** — on both `k8s-lb-1` and `k8s-lb-2`. Read `/etc/haproxy/haproxy.cfg`, append these frontends to that file, check it, then reload. Backends are `<worker-ip>:<NodePort>` from step 1. Skip the append if `k8s-http` is already in the file. Nonlocal bind is already set.
```sh
HTTP_NODEPORT=<80 nodeport>
HTTPS_NODEPORT=<443 nodeport>
grep -n -E 'bind |^frontend' /etc/haproxy/haproxy.cfg
sudo tee -a /etc/haproxy/haproxy.cfg <<EOF

frontend k8s-http
    bind 10.0.1.10:80
    mode tcp
    timeout client 1h
    default_backend k8s-http-backend

backend k8s-http-backend
    mode tcp
    balance roundrobin
    timeout server 1h
    server k8s-work-1 10.0.1.21:${HTTP_NODEPORT} check
    server k8s-work-2 10.0.1.22:${HTTP_NODEPORT} check
    server k8s-work-3 10.0.1.23:${HTTP_NODEPORT} check

frontend k8s-https
    bind 10.0.1.10:443
    mode tcp
    timeout client 1h
    default_backend k8s-https-backend

backend k8s-https-backend
    mode tcp
    balance roundrobin
    timeout server 1h
    server k8s-work-1 10.0.1.21:${HTTPS_NODEPORT} check
    server k8s-work-2 10.0.1.22:${HTTPS_NODEPORT} check
    server k8s-work-3 10.0.1.23:${HTTPS_NODEPORT} check
EOF
sudo haproxy -c -f /etc/haproxy/haproxy.cfg             # stop if this fails
sudo systemctl reload haproxy                          # the process reads the file
```

**3. Check the VIP** — not the bastion address.
```sh
curl -sv --max-time 5 http://10.0.1.10/    # the API pair, port 80, after a test Ingress exists
```

## Prerequisites
- [06-ceph.md](06-ceph.md)

## Next
- [08-observability.md](08-observability.md)
