### Adopting Envoy at the edge with Istio ingress gateway

Istio Ingress Gateway allows traffic into the mesh.
If you need more sophisticated edge gateway capabilities:
* rate-limiting
* request-transformation
* OIDC
* LDAP
* OPA, etc
then use a gateway specifically built for those use cases, such as Gloo Gateway.

#### Installation of Istio Ingress Gateway
Let's install istio igw with a revision that matches the control plane in the istio-ingress namespace.
We recommend that you install the `istio-ingress gateway` in a namespace that is different than `istiod` for better security and isolation.

```
istioctl version

Not `1.17.5`, use dash `1-17-5`
export ISTIO_REVISION=1-17-5

kubectl create ns istio-ingress

istioctl install -y -n istio-ingress -f istio-ingress-gateway.yaml --revision ${ISTIO_REVISION}
```

#### Deploy sample applications and Expose using Istio Ingress Gateway
```
cd /home/vagrant/istio-cop/certmanager

kubectl apply -n hellocloud -f sample-apps/web-api.yaml
kubectl apply -n hellocloud -f sample-apps/recommendation.yaml
kubectl apply -n hellocloud -f sample-apps/purchase-history-v1.yaml
kubectl apply -n hellocloud -f sample-apps/sleep.yaml

export GATEWAY_IP=$(kubectl get svc -n istio-ingress istio-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
export INGRESS_PORT=80
export SECURE_INGRESS_PORT=443

kubectl -n hellocloud apply -f ingress/web-api-gw.yaml
kubectl -n hellocloud apply -f ingress/web-api-gw-vs.yaml
```
#### Test
```
curl -H "Host: hellocloud.io" http://$GATEWAY_IP:$INGRESS_PORT
```
#### create leaf certificate which is signed by CA (for hellocloud.io)
```
step certificate create hellocloud.io hellocloud.io.crt hellocloud.io.key --profile leaf --subtle --no-password --kty RSA --insecure --not-after="8760h" --ca ./ca/root-ca.crt --ca-key ./ca/root-ca.key

# verify
openssl x509 --text --noout --in ./hellocloud.io.crt

```
#### create as k8s tls secret in `istio-ingress` namespace
Note, we are pointing to the `hellocloud-cert` and 
that the cert must be in the same namespace as the ingress gateway deployment which is `istio-ingress` in this lab. 
```
kubectl create -n istio-ingress secret tls hellocloud-cert --key hellocloud.io.key --cert hellocloud.io.crt

```

#### Secure inbound traffic with HTTPS
```
kubectl -n hellocloud apply -f web-api-gw-https.yaml
```
#### Test HTTPS
```
curl --cacert ca/root-ca.crt -H "Host: hellocloud.io" https://hellocloud.io:$SECURE_INGRESS_PORT --resolve hellocloud.io:$SECURE_INGRESS_PORT:$GATEWAY_IP
```

#### Test HTTP - Should Not Work Anymore
```
curl -H "Host: hellocloud.io" http://$GATEWAY_IP:$INGRESS_PORT
```

#### Common Issues that we run into with this approach
* Users may not have access to write anything (i.e, certs) into istio-ingress
* Users may not manage their own certificates
* Integration with CA/PKI is highly desirable

Let's delete the secret `hellocloud-cert` we created earlier.
```
kubectl delete secret hellocloud-cert -n istio-ingress
```
#### Test HTTPS again - Should Not Work Anymore
```
kubectl rollout restart deployment istio-ingressgateway -n istio-ingress
kubectl rollout restart deployment web-api -n hellocloud

curl --cacert ca/root-ca.crt -H "Host: hellocloud.io" https://hellocloud.io:$SECURE_INGRESS_PORT --resolve hellocloud.io:$SECURE_INGRESS_PORT:$GATEWAY_IP

```

#### Reset back to HTTP
```
kubectl -n hellocloud apply -f ingress/web-api-gw.yaml
curl -H "Host: hellocloud.io" http://$GATEWAY_IP:$INGRESS_PORT

```