# 03. Hello Nginx

**Goal:** Ship six stateless nginx Pods and curl the Ingress ADDRESS that Cloud Provider KIND assigns.

## Teaching note

The app is one file, [hello-nginx.yaml](hello-nginx.yaml), in this clone. `/opt` is the toolchain. Every line in that file has a comment. Objects are in create order: namespace, ConfigMap, Deployment, Service, Ingress. This app keeps no data on disk, so there is no PersistentVolume and no PersistentVolumeClaim.

The Service is ClusterIP. Cloud Provider KIND gives the Ingress an ADDRESS on the docker network. Run `kubectl get ingress`, read ADDRESS, and type that IP into curl. Do not curl `127.0.0.1`.

`k` is an alias for `kubectl` after you source `activate`. Tab-complete works on both.

Every command here is idempotent.

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

**2. Apply the manifest** — work from the clone. Open [hello-nginx.yaml](hello-nginx.yaml) and read it before you apply.
```sh
cd /path/to/kubernetes-lab/idops-pocket-cluster
kubectl apply -f hello-nginx.yaml
kubectl get namespace idops-nginx-demo
kubectl get cm,deploy,po,svc,ingress -n idops-nginx-demo -o wide
kubectl rollout status deployment/hello-nginx -n idops-nginx-demo --timeout=180s
```

Expected: namespace exists, ConfigMap `hello-nginx`, Deployment `hello-nginx` 6/6, six Running Pods on workers (NODE is a worker), Service type ClusterIP, Ingress with an ADDRESS IP.

**3. Access from the host** — `kubectl get ingress` prints ADDRESS. Copy that IP. Run curl several times. The `pod=` line is the Pod that served that request.
```sh
kubectl get ingress -n idops-nginx-demo
curl -sS http://ADDRESS/
```

Replace `ADDRESS` with the IP from the ADDRESS column. Expected body:

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
cd /path/to/kubernetes-lab/idops-pocket-cluster
kubectl delete -f hello-nginx.yaml --ignore-not-found
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

**Ingress ADDRESS is empty / curl fails** — Cloud Provider KIND must be running. Go back to [02-create-cluster.md](02-create-cluster.md) and run `k8s_lab_start`. Then get ingress again and curl the ADDRESS column.
```sh
k8s_lab_start
tail -n 50 "$K8S_LAB_ROOT/cloud-provider-kind.log"
kubectl get ingress -n idops-nginx-demo
curl -sS http://ADDRESS/
```

## Next

Practice CKAD tasks from the map in [00-overview.md](00-overview.md#ckad-practice-map).
