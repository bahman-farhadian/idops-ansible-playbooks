# hello-nginx

Six stateless nginx Pods on Pocket Cluster. Each response prints the Pod hostname. Curl the Ingress ADDRESS that Cloud Provider KIND assigns. Do not curl 127.0.0.1.

## Teaching Note

The YAML files are numbered so `kubectl apply -f .` creates them in order: namespace, ConfigMap, Deployment (Pods), Service, Ingress. This app keeps no data on disk, so there is no PersistentVolume and no PersistentVolumeClaim. A ConfigMap holds the nginx page.

The Service is ClusterIP. Cloud Provider KIND gives the Ingress an external IP on the docker network. Deploy the cluster first: [../README.md](../README.md). `k8s_lab_start` starts that process.

Type `kubectl`. There is no `k` alias.

Every command here is safe to run again.

## Prerequisites

The cluster is up from [../README.md](../README.md).

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

## 1. Load the nginx Image

kind nodes do not see images on the host Docker daemon until you load them.

```sh
docker pull nginx:1.27
```

```sh
k8s_lab_load_image nginx:1.27
```

## 2. Apply the Manifests

The files in this directory are:

| File | Object |
| ---- | ------ |
| `00-namespace.yaml` | Namespace `idops-nginx-demo` |
| `01-configmap.yaml` | nginx page config |
| `02-deployment.yaml` | six stateless Pods |
| `03-service.yaml` | ClusterIP Service |
| `04-ingress.yaml` | Ingress (Cloud Provider KIND ADDRESS) |

No PersistentVolume and no PersistentVolumeClaim. These Pods are stateless.

```sh
cd "$K8S_LAB_ROOT/hello-nginx"
```

```sh
kubectl apply -f .
```

Check what the YAML created.

```sh
kubectl get namespace idops-nginx-demo
```

```sh
kubectl get cm,deploy,po,svc,ingress -n idops-nginx-demo -o wide
```

```sh
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

Expected: namespace exists, ConfigMap `hello-nginx`, Deployment `hello-nginx` 6/6, six Running Pods, Service type ClusterIP, Ingress with an ADDRESS IP (not `<none>`).

## 3. Access from the Host

Curl the Ingress IP. That is the kind approach. Do not use 127.0.0.1. Run curl several times. The `pod=` line is the Pod that served that request.

```sh
INGRESS_IP=$(kubectl get ingress hello-nginx -n idops-nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```sh
printf 'INGRESS_IP=%s\n' "$INGRESS_IP"
```

```sh
curl -sS "http://${INGRESS_IP}/"
```

Expected body:

```
Pocket Cluster
pod=hello-nginx-xxxxxxxx-xxxxx
```

## 4. Logs

nginx writes access logs to stdout.

```sh
kubectl logs -n idops-nginx-demo -l app=hello-nginx --tail=20
```

If a replica is not Ready:

```sh
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx
```

## 5. Remove the App

The cluster stays.

```sh
cd "$K8S_LAB_ROOT/hello-nginx"
```

```sh
kubectl delete -f . --ignore-not-found
```

## Troubleshooting

### Rollout Timed Out / 0 Replicas Available

```sh
kubectl get pods -n idops-nginx-demo -o wide
```

```sh
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx
```

ImagePullBackOff means the image is not on the node. Pull and load again, then wait.

```sh
docker pull nginx:1.27
```

```sh
k8s_lab_load_image nginx:1.27
```

```sh
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

### Ingress ADDRESS Is Empty / curl Fails

Cloud Provider KIND must be running. Go back to [../README.md](../README.md) and run `k8s_lab_start`.

```sh
k8s_lab_start
```

```sh
tail -n 50 "$K8S_LAB_ROOT/cloud-provider-kind.log"
```

```sh
kubectl get ingress hello-nginx -n idops-nginx-demo
```

```sh
INGRESS_IP=$(kubectl get ingress hello-nginx -n idops-nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```sh
curl -sS "http://${INGRESS_IP}/"
```
