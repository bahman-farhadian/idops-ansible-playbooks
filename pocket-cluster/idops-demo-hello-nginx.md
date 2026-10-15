# idops-demo-hello-nginx

Six stateless nginx Pods on Pocket Cluster. Each response prints the Pod hostname. You reach the app by curling the Ingress ADDRESS that Cloud Provider KIND assigns. Do not curl 127.0.0.1.

## Teaching Note

Apply objects in this order: namespace, then config, then Pods, then the Service, then the Ingress. This app keeps no data on disk, so there is no PersistentVolume and no PersistentVolumeClaim. A ConfigMap holds the nginx page.

The Service is ClusterIP. Cloud Provider KIND is the door: it gives the Ingress an external IP on the docker network. Start it with [idops-pocket-cloud-provider-kind.md](idops-pocket-cloud-provider-kind.md). `k8s_lab_start` starts that process.

Type `kubectl`. There is no `k` alias.

Every command here is safe to run again.

## Prerequisites

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

## 2. Namespace

Create `idops-nginx-demo` first. Every later object in this app lives there.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/00-namespace.yaml"
```

```sh
kubectl get namespace idops-nginx-demo
```

## 3. PersistentVolume and PersistentVolumeClaim

Skip both. These Pods are stateless. They do not write application data to a volume. The hostname page comes from a ConfigMap, not from a disk.

## 4. ConfigMap

Apply the nginx config.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/01-configmap.yaml"
```

```sh
kubectl get configmap hello-nginx -n idops-nginx-demo
```

## 5. Pods

Create six identical replicas.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/02-deployment.yaml"
```

```sh
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

```sh
kubectl get pods -n idops-nginx-demo -o wide
```

Expected: six Running Pods on the workers.

## 6. Service

ClusterIP only. The host does not talk to this port directly.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/03-service.yaml"
```

## 7. Ingress

Cloud Provider KIND assigns an ADDRESS to this Ingress. Path `/` goes to the Service.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/04-ingress.yaml"
```

```sh
kubectl get deploy,po,svc,ingress -n idops-nginx-demo -o wide
```

Expected: Deployment `hello-nginx` 6/6, Service type ClusterIP, Ingress with an ADDRESS IP (not `<none>`).

## 8. Access from the Host

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

## 9. Logs

nginx writes access logs to stdout.

```sh
kubectl logs -n idops-nginx-demo -l app=hello-nginx --tail=20
```

If a replica is not Ready:

```sh
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx
```

## 10. Remove the App

The cluster stays.

```sh
kubectl delete -f "$K8S_LAB_ROOT/hello-nginx" --ignore-not-found
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

Cloud Provider KIND must be running. Follow [idops-pocket-cloud-provider-kind.md](idops-pocket-cloud-provider-kind.md).

```sh
k8s_lab_start
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
