# idops-pocket-traefik

Install Traefik as the Ingress controller on Pocket Cluster.

## Teaching Note

kind has no addon system. Minikube can run `minikube addons enable ingress`. kind does not. You install a controller with Helm, the same way the HA lab does in [07-ingress.md](../07-ingress.md).

Traefik watches Ingress objects and opens HTTP on NodePort `30080`. kind maps that port on the control-plane to `http://127.0.0.1:8080` on the laptop. HTTPS is NodePort `30443` on host `8443`. This lab has no cert-manager.

Type `kubectl` and `helm`. Debian's apt package named `helm` is Emacs; this tree uses Helm 3 from the upstream tarball.

Every command here is safe to run again. `helm upgrade --install` updates an existing release.

## Prerequisites

Follow [README.md](README.md) Part I so `helm` is in `/opt/pocket-cluster`. Then:

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

## 1. Load the Traefik Image

kind nodes do not see images on the host Docker daemon until you load them.

```sh
docker pull traefik:v3.7.14
```

```sh
k8s_lab_load_image traefik:v3.7.14
```

## 2. Add the Chart Repo

Pin the chart version. Do not install without `--version`.

```sh
helm repo add traefik https://traefik.github.io/charts --force-update
```

```sh
helm repo update traefik
```

Chart pin: `41.7.1` (Traefik Proxy v3.7.14). Recheck [traefik-helm-chart releases](https://github.com/traefik/traefik-helm-chart/releases).

## 3. Install Traefik

Values in [traefik-kind-values.yaml](traefik-kind-values.yaml) set Service type NodePort and the two node ports that kind publishes.

```sh
helm upgrade --install traefik traefik/traefik --namespace traefik --create-namespace --version 41.7.1 --values "$K8S_LAB_ROOT/traefik-kind-values.yaml"
```

```sh
kubectl rollout status deployment/traefik -n traefik --timeout=180s
```

```sh
kubectl get deploy,po,svc,ingressclass -n traefik
```

Expected: Deployment Ready, Service type NodePort with `80:30080/TCP` and `443:30443/TCP`, IngressClass `traefik`.

## 4. Next

Follow [idops-demo-hello-nginx.md](idops-demo-hello-nginx.md). That app is a ClusterIP Service plus an Ingress on host `hello.localhost`.

## Troubleshooting

### ImagePullBackOff on traefik

```sh
kubectl get pods -n traefik -o wide
```

```sh
docker pull traefik:v3.7.14
```

```sh
k8s_lab_load_image traefik:v3.7.14
```

### helm: command not found

Install Helm 3 in [README.md](README.md) Part I (step Install Helm 3), then `source /opt/pocket-cluster/activate`.
