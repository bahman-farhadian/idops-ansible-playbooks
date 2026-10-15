# idops-pocket-cloud-provider-kind

Run Cloud Provider KIND so Ingress and LoadBalancer get an external IP. Curl that IP. Do not curl 127.0.0.1.

## Teaching Note

kind has no addon system. The official Ingress guide is Cloud Provider KIND ([kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress/), [kind LoadBalancer](https://kind.sigs.k8s.io/docs/user/loadbalancer/)). A process on the laptop watches the cluster and creates a LoadBalancer container. Ingress then gets an ADDRESS on the docker network. You curl that address.

This is not Traefik and not extraPortMappings to localhost.

The binary must keep running. `k8s_lab_start` starts it if it is not already running.

Every command here is safe to run again.

## Prerequisites

Follow [README.md](README.md) Part I through the cloud-provider-kind install, then:

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

## Check It Is Running

```sh
k8s_lab_info
```

```sh
kubectl get nodes
```

Cloud Provider KIND logs:

```sh
tail -n 20 "$K8S_LAB_ROOT/cloud-provider-kind.log"
```

## Next

Follow [idops-demo-hello-nginx.md](idops-demo-hello-nginx.md). After the Ingress has an ADDRESS:

```sh
INGRESS_IP=$(kubectl get ingress hello-nginx -n idops-nginx-demo -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

```sh
curl -sS "http://${INGRESS_IP}/"
```

## Troubleshooting

### Ingress ADDRESS stays empty

The `cloud-provider-kind` process is not running, or it cannot talk to Docker.

```sh
source /opt/pocket-cluster/activate
```

```sh
k8s_lab_start
```

```sh
tail -n 50 "$K8S_LAB_ROOT/cloud-provider-kind.log"
```

### Permission denied adding IPs

On Linux with Docker, this user must be in the `docker` group. Cloud Provider KIND also needs to add addresses on the kind network. Run the same user that owns the Docker socket. Do not curl localhost as a workaround.
