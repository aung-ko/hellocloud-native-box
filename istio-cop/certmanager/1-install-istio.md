### Installing Istio

3 ways to install Istio:
* istioctl CLI tool
* Istio Operator
* Helm

#### Installation
```
kubectl create ns istio-system
```
Creating this service is `needed` to `workaround` a long-standing issue with Istio revisions until the Istio `tags` functionality makes it into the project.
```
cd $HOME
cd istio-cop/certmanager/

kubectl apply -f istiod-service.yaml -n istio-system
```
Install istio control plane using the `minimal` profile because we will only be installing `istiod` control plane.
```
istioctl version

Not `1.17.5`, use dash `1-17-5`
export ISTIO_REVISION=1-17-5

cd $HOME
cd istio-cop/certmanager/

istioctl install -y -n istio-system -f istiod-controlplane.yaml --revision ${ISTIO_REVISION}
```

Istiod components includes:
* xDS server for Envoy Config
* CA for signing workload certificates
* Service Discovery
* Sidecar injection webhook

```
$ kubectl get iop -A
NAMESPACE      NAME                                   REVISION   STATUS   AGE
istio-system   installed-state-control-plane-1-17-5   1-17-5              37s

$ kubectl get mutatingwebhookconfigurations -A
NAME                            WEBHOOKS   AGE
cert-manager-webhook            1          4m11s
istio-revision-tag-default      4          22s
istio-sidecar-injector-1-17-5   2          39s

$ kubectl get validatingwebhookconfigurations -A
NAME                                  WEBHOOKS   AGE
cert-manager-webhook                  1          4m16s
istio-validator-1-17-5-istio-system   1          45s
istiod-default-validator              1          27s
metallb-webhook-configuration         7          5m12s
```

We can query the istio control plane's `debug endpoints` to see what services we have running and what istio has discovered.

```
kubectl exec -n istio-system deploy/istiod-${ISTIO_REVISION} -- pilot-discovery request GET /debug/registryz | jq
```

The output of this command can be quite verbose as it lists all of the services in the Istio registry.
Workloads are included in the `istio registry` even if they are not officially part of the mesh (i.e, have a sidecar deployed next to it.)

#### Add applications to the Mesh

```
kubectl create ns hellocloud
kubectl label namespace hellocloud istio-injection=enabled
kubectl get ns -L istio-injection

kubectl apply -f httpbin.yaml -n hellocloud
```

```
kubectl delete ns hellocloud
kubectl create ns hellocloud
kubectl label namespace hellocloud istio.io/rev=${ISTIO_REVISION}
kubectl apply -f httpbin.yaml -n hellocloud
```
In the above command, we configure istioctl to use the configmaps for our revision.
We can run multiple versions of istio concurrently and can specify exactly which revision gets applied.

* Verify `kubectl get ns -L istio-injection` won't show anything.
* Verify using `kubectl get ns hellocloud --show-labels`