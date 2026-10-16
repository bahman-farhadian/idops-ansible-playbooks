# 03. Hello Nginx

**Goal:** Ship six stateless nginx Pods and curl the Ingress ADDRESS that Cloud Provider KIND assigns.

## Teaching note

The YAML files in [hello-nginx/](hello-nginx/) are numbered so `kubectl apply -f .` creates them in order: namespace, ConfigMap, Deployment (Pods), Service, Ingress. This app keeps no data on disk, so there is no PersistentVolume and no PersistentVolumeClaim. A ConfigMap holds the nginx page.

The Service is ClusterIP. Cloud Provider KIND gives the Ingress an external IP on the docker network. Curl that IP. Do not curl `127.0.0.1`.

`k` is an alias for `kubectl` after you source `activate`. Tab-complete works on both.

Every command here is safe to run again.

## Prerequisites

- Cluster is up from [02-create-cluster.md](02-create-cluster.md)

## Steps

**1. Load the nginx image** — kind worker nodes do not see images on the host Docker daemon until you load them. `k8s_lab_load_image` loads onto workers only. The control plane is tainted and does not run application Pods.
```sh
source /opt/idops-pocket-cluster/activate
k8s_lab_start
docker pull nginx:1.27
k8s_lab_load_image nginx:1.27
```

**2. Apply the manifests**

| File | Object |
| ---- | ------ |
| `00-namespace.yaml` | Namespace `idops-nginx-demo` |
| `01-configmap.yaml` | nginx page config |
| `02-deployment.yaml` | six stateless Pods |
| `03-service.yaml` | ClusterIP Service |
| `04-ingress.yaml` | Ingress (Cloud Provider KIND ADDRESS) |

```sh
cd "$K8S_LAB_ROOT/hello-nginx"
kubectl apply -f .
kubectl get namespace idops-nginx-demo
kubectl get cm,deploy,po,svc,ingress -n idops-nginx-demo -o wide
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

Expected: namespace exists, ConfigMap `hello-nginx`, Deployment `hello-nginx` 6/6, six Running Pods on workers (NODE is not the control plane), Service type ClusterIP, Ingress with an ADDRESS IP (not `<none>`).

**3. Access from the host** — run curl several times. The `pod=` line is the Pod that served that request.
```sh
INGRESS_IP=$(kubectl get ingress hello-nginx -n idops-nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
printf 'INGRESS_IP=%s\n' "$INGRESS_IP"
curl -sS "http://${INGRESS_IP}/"
```

Expected body:

```
Pocket Cluster
pod=hello-nginx-xxxxxxxx-xxxxx
```

**4. Logs** — nginx writes access logs to stdout.
```sh
kubectl logs -n idops-nginx-demo -l app=hello-nginx --tail=20
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx   # if a replica is not Ready
```

**5. Remove the app** — the cluster stays.
```sh
cd "$K8S_LAB_ROOT/hello-nginx"
kubectl delete -f . --ignore-not-found
```

## Troubleshooting

**Rollout timed out / 0 replicas available** — ImagePullBackOff means the image is not on the node. Pull and load again, then wait.
```sh
kubectl get pods -n idops-nginx-demo -o wide
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx
docker pull nginx:1.27
k8s_lab_load_image nginx:1.27
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

**Ingress ADDRESS is empty / curl fails** — Cloud Provider KIND must be running. Go back to [02-create-cluster.md](02-create-cluster.md) and run `k8s_lab_start`.
```sh
k8s_lab_start
tail -n 50 "$K8S_LAB_ROOT/cloud-provider-kind.log"
kubectl get ingress hello-nginx -n idops-nginx-demo
INGRESS_IP=$(kubectl get ingress hello-nginx -n idops-nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -sS "http://${INGRESS_IP}/"
```

## Next

Practice CKAD tasks from the map in [00-overview.md](00-overview.md#ckad-practice-map).
