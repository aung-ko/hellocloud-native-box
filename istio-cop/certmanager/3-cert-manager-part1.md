### https://cert-manager.io/docs/

We can use cert-manager to provision the certs for us using a backend CA.
cert-manager can be integrated with a lot of backend PKI such as HashiCorp Vault, Venafi, Let's Encrypt.

#### Installation
```
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3 \
  --set installCRDs=true
```
#### Create CA `hellocloud-ca`
```
cd /home/vagrant/istio-cop/certmanager
mkdir ca

# Create a root certificate and key - do not encrypt the key when writing to disk

step certificate create hellocloud-ca ./ca/root-ca.crt ./ca/root-ca.key --profile root-ca --subtle --no-password --kty RSA --insecure --not-after="87600h"

# verify
openssl x509 --text --noout --in ./ca/root-ca.crt

```
#### Use our own CA which is `hellocloud-ca`, created as above, as backend. Create as kubernetes secret called `cert-manager-cacerts` as below.
```
kubectl create -n cert-manager secret tls cert-manager-cacerts --cert /home/vagrant/istio-cop/certmanager/ca/root-ca.crt --key /home/vagrant/istio-cop/certmanager/ca/root-ca.key

# Notes : this is just for the lab. Ideally if you use cert-manager, you'll be using HashiCorp Vault, Let's Encrypt, or your own PKI.

```
#### Create `ClusterIssuer` named as `ca-issuer` to use `hellocloud-ca` in `sandbox` namespace
```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: sandbox
spec:
  ca:
    secretName: cert-manager-cacerts
EOF
```

#### Let cert-manager issue a secret with this config using `Certificate` CRD
This will create `kubernetes secrets` called `hellocloud-cert` in `istio-ingress` namespace as well.

```
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: hellocloud-cert
  namespace: istio-ingress
spec:
  secretName: hellocloud-cert
  duration: 2160h # 90days
  renewBefore: 360h #15days
  subject:
    organizations:
    - hellocloud.io
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  dnsNames:
  - hellocloud.io
  issuerRef:
    name: ca-issuer
    kind: ClusterIssuer
    group: cert-manager.io
EOF

```
#### Verify
```
$ kubectl get certificate -n istio-ingress 
NAME              READY   SECRET            AGE
hellocloud-cert   True    hellocloud-cert   8s

$ kubectl get secret -n istio-ingress
NAME                                               TYPE                                  DATA   AGE
default-token-jbrz8                                kubernetes.io/service-account-token   3      27m
hellocloud-cert                                    kubernetes.io/tls                     3      40s
istio-ingressgateway-service-account-token-9mxt4   kubernetes.io/service-account-token   3      27m

kubectl get secret -n istio-ingress hellocloud-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d | step certificate inspect -

```

#### Secure inbound traffic with HTTPS Again
```
kubectl -n hellocloud apply -f web-api-gw-https.yaml
```
#### Test HTTPS Again
```
curl --cacert ca/root-ca.crt -H "Host: hellocloud.io" https://hellocloud.io:$SECURE_INGRESS_PORT --resolve hellocloud.io:$SECURE_INGRESS_PORT:$GATEWAY_IP
```

#### Test HTTP - Should Not Work Anymore
```
curl -H "Host: hellocloud.io" http://$GATEWAY_IP:$INGRESS_PORT
```

#### TODO
Please test `renewBefore: 360h #15days` works.
It should renew automatically.
