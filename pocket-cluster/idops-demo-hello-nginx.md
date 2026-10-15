# idops-demo-hello-nginx

Six stateless nginx Pods on Pocket Cluster. Each response prints the Pod hostname. You reach the app from the laptop at `http://127.0.0.1:8080`.

## Teaching Note

Apply objects in this order: namespace, then config, then Pods, then the Service. This app keeps no data on disk, so there is no PersistentVolume and no PersistentVolumeClaim. A ConfigMap holds the nginx page.

The Service is NodePort `30080`. kind maps that port on the control-plane node to port `8080` on the host (`extraPortMappings` in [idops-pocket-k8s-cluster.yaml](idops-pocket-k8s-cluster.yaml)).

Type `kubectl`. There is no `k` alias.

Every command here is safe to run again.

## Prerequisites

Pocket Cluster is running. Follow [README.md](README.md) Part I, then:

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

If this cluster was created when `8080` still mapped to node port `80`, delete and start so the mapping is `30080`.

```sh
k8s_lab_delete_cluster
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

Publish NodePort `30080` so the host can reach the Pods.

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/03-service.yaml"
```

```sh
kubectl get deploy,po,svc -n idops-nginx-demo -o wide
```

Expected: Deployment `hello-nginx` 6/6, Service type NodePort `80:30080/TCP`.

## 7. Access from the Host

Hit the app from outside the cluster. Run curl several times. The `pod=` line is the Pod that served that request.

```sh
curl -sS http://127.0.0.1:8080
```

Expected body:

```
Pocket Cluster
pod=hello-nginx-xxxxxxxx-xxxxx
```

## 8. Logs

nginx writes access logs to stdout.

```sh
kubectl logs -n idops-nginx-demo -l app=hello-nginx --tail=20
```

If a replica is not Ready:

```sh
kubectl describe pod -n idops-nginx-demo -l app=hello-nginx
```

## 9. Remove the App

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

### curl to localhost:8080 Fails

kind maps laptop `:8080` to NodePort `30080` on the control-plane. If this cluster was created with `:8080` mapped to node `:80`, delete and start, then apply again in order.

```sh
k8s_lab_delete_cluster
```

```sh
k8s_lab_start
```

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/00-namespace.yaml"
```

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/01-configmap.yaml"
```

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/02-deployment.yaml"
```

```sh
kubectl apply -f "$K8S_LAB_ROOT/hello-nginx/03-service.yaml"
```
