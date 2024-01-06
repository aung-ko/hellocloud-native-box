### https://cert-manager.io/docs/

#### Clean up
```
cd $HOME
cd k8s-cop/1-single-cluster/setup/
./teardown.sh

./setupkindcluster123.sh

cd $HOME
cd istio-cop/certmanager/

kubectl create ns istio-system
kubectl apply -f istiod-service.yaml -n istio-system

export ISTIO_REVISION=1-17-5
istioctl install -y -n istio-system -f istiod-controlplane.yaml --revision ${ISTIO_REVISION}

kubectl create ns hellocloud
kubectl label namespace hellocloud istio.io/rev=${ISTIO_REVISION}
kubectl apply -f httpbin.yaml -n hellocloud

kubectl create ns istio-ingress

istioctl install -y -n istio-ingress -f istio-ingress-gateway.yaml --revision ${ISTIO_REVISION}

kubectl apply -n hellocloud -f sample-apps/web-api.yaml
kubectl apply -n hellocloud -f sample-apps/recommendation.yaml
kubectl apply -n hellocloud -f sample-apps/purchase-history-v1.yaml
kubectl apply -n hellocloud -f sample-apps/sleep.yaml

export GATEWAY_IP=$(kubectl get svc -n istio-ingress istio-ingressgateway -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
export INGRESS_PORT=80
export SECURE_INGRESS_PORT=443

kubectl -n hellocloud apply -f ingress/web-api-gw.yaml
kubectl -n hellocloud apply -f ingress/web-api-gw-vs.yaml

curl -H "Host: hellocloud.io" http://$GATEWAY_IP:$INGRESS_PORT

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
#### Option 2 - Create your own `ClusterIssuer`
```
https://cert-manager.io/docs/configuration/selfsigned/

### define issuer for issuing certificates
kubectl apply -f 1-selfsigned-ca-cluster-issuer.yaml

### request Root CA Certificate from the issuer created above
kubectl apply -f 2-root-ca-certificate.yaml

kubectl apply -f 3-hellocloud-root-ca-issuer.yaml
kubectl apply -f 4-hellocloud-cert.yaml -n istio-ingress
```


```
kubectl get secret -n cert-manager root-certificate-ca-tls -o jsonpath="{.data['ca\.crt']}" | base64 -d | step certificate inspect -

kubectl get secret -n cert-manager root-certificate-ca-tls -o jsonpath="{.data['ca\.crt']}" | base64 -d -o cert-manager-ca.crt

kubectl get secret -n cert-manager root-certificate-ca-tls -o jsonpath="{.data['tls\.crt']}" | base64 -d | step certificate inspect -

kubectl get secret -n cert-manager root-certificate-ca-tls -o jsonpath="{.data['tls\.crt']}" | base64 -d -o cert-manager-tls.crt

kubectl get secret -n cert-manager root-certificate-ca-tls -o jsonpath="{.data['tls\.key']}" | base64 -d -o cert-manager-tls.key

kubectl get secret -n istio-ingress hellocloud-cert -o jsonpath="{.data['ca\.crt']}" | base64 -d | step certificate inspect -

kubectl get secret -n istio-ingress hellocloud-cert -o jsonpath="{.data['ca\.crt']}" | base64 -d -o hellocloud-ca.crt

kubectl get secret -n istio-ingress hellocloud-cert -o jsonpath="{.data['tls\.crt']}" | base64 -d | step certificate inspect -

```

#### Test
Get the cert-manager-ca.crt, cert-manager-tls.crt and cert-manager-tls.key manually for testing.

```
kubectl -n hellocloud apply -f web-api-gw-https.yaml

curl --cacert ./cert-manager-ca.crt -H "Host: hellocloud.io" https://hellocloud.io:$SECURE_INGRESS_PORT --resolve hellocloud.io:$SECURE_INGRESS_PORT:$GATEWAY_IP

```

# Test `curl -ivk`
```
$ curl  -H "Host: hellocloud.io" https://hellocloud.io:$SECURE_INGRESS_PORT --resolve hellocloud.io:$SECURE_INGRESS_PORT:$GATEWAY_IP -ivk
* Added hellocloud.io:443:172.18.255.150 to DNS cache
* Hostname hellocloud.io was found in DNS cache
*   Trying 172.18.255.150:443...
* Connected to hellocloud.io (172.18.255.150) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* TLSv1.0 (OUT), TLS header, Certificate Status (22):
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS header, Certificate Status (22):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS header, Finished (20):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.2 (OUT), TLS header, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384
* ALPN, server accepted to use h2
* Server certificate:
*  subject: CN=hellocloud.io
*  start date: Dec 18 15:12:47 2023 GMT
*  expire date: Mar 17 15:12:47 2024 GMT
*  issuer: CN=hellocloud.io
*  SSL certificate verify result: self-signed certificate (18), continuing anyway.
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* Using Stream ID: 1 (easy handle 0x561adfb21e90)
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
> GET / HTTP/2
> Host: hellocloud.io
> user-agent: curl/7.81.0
> accept: */*
> 
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):
* old SSL session ID is stale, removing
* TLSv1.2 (IN), TLS header, Supplemental data (23):
* Connection state changed (MAX_CONCURRENT_STREAMS == 2147483647)!
* TLSv1.2 (OUT), TLS header, Supplemental data (23):
* TLSv1.2 (IN), TLS header, Supplemental data (23):
< HTTP/2 200 
HTTP/2 200 
< vary: Origin
vary: Origin
< date: Mon, 18 Dec 2023 15:13:46 GMT
date: Mon, 18 Dec 2023 15:13:46 GMT
< content-length: 1104
content-length: 1104
< content-type: text/plain; charset=utf-8
content-type: text/plain; charset=utf-8
< x-envoy-upstream-service-time: 104
x-envoy-upstream-service-time: 104
< server: istio-envoy
server: istio-envoy

< 
{
  "name": "web-api",
  "uri": "/",
  "type": "HTTP",
  "ip_addresses": [
    "10.243.2.4"
  ],
  "start_time": "2023-12-18T15:13:46.314666",
  "end_time": "2023-12-18T15:13:46.396060",
  "duration": "81.394198ms",
  "body": "Hello From Web API",
  "upstream_calls": [
    {
      "name": "recommendation",
      "uri": "http://recommendation:8080",
      "type": "HTTP",
      "ip_addresses": [
        "10.243.3.3"
      ],
      "start_time": "2023-12-18T15:13:46.322933",
      "end_time": "2023-12-18T15:13:46.374371",
      "duration": "51.437852ms",
      "body": "Hello From Recommendations!",
      "upstream_calls": [
        {
          "name": "purchase-history-v1",
          "uri": "http://purchase-history:8080",
          "type": "HTTP",
          "ip_addresses": [
            "10.243.2.5"
          ],
          "start_time": "2023-12-18T15:13:46.328334",
          "end_time": "2023-12-18T15:13:46.328490",
          "duration": "156.049µs",
          "body": "Hello From Purchase History (v1)!",
          "code": 200
        }
      ],
      "code": 200
    }
  ],
  "code": 200
}
* Connection #0 to host hellocloud.io left intact
```