# working directory
cd $HOME/istio-cop/1-start-istio/

# secure inbound traffic with HTTPS
Create a TLS secret for `istioinaction.io` in the `istio-system` namespace

kubectl create -n istio-system secret tls istioinaction-cert --key secure-igw/certs/istioinaction.io.key --cert secure-igw/certs/istioinaction.io.crt

######### ######### ######### 
Note, we are pointing to the `istioinaction-cert` and 
that **the cert must be in the same namespace as the ingress gateway deployment**. 
Even though the `Gateway` resource is in the `istioinaction` namespace, _the cert must be where the gateway is actually deployed_.
######### ######### ######### 

# update Istio `Gateway` config
cat secure-igw/web-api-gw-https.yaml 

kubectl -n istioinaction apply -f secure-igw/web-api-gw-https.yaml 

# Test HTTPS
curl --cacert secure-igw/certs/ca/root-ca.crt -H "Host: istioinaction.io" https://istioinaction.io:$SECURE_INGRESS_PORT --resolve istioinaction.io:$SECURE_INGRESS_PORT:$GATEWAY_IP

# Test HTTP
curl -H "Host: istioinaction.io" http://$GATEWAY_IP:$INGRESS_PORT 

# Loop
for _ in {1..1000}; do curl -I -H "Host: istioinaction.io" http://$GATEWAY_IP:$INGRESS_PORT; sleep 1; done
