# Create a root certificate and key
step certificate create grincerlabs-ca ./ca/root-ca.crt ./ca/root-ca.key --profile root-ca --subtle --no-password --kty RSA --insecure --not-after="87600h"

# verify
openssl x509 --text --noout --in ./ca/root-ca.crt

# create leaf certificate which is signed by CA (for rabbit.io)
step certificate create rabbit.io rabbit.io.crt rabbit.io.key --profile leaf --subtle --no-password --kty RSA --insecure --not-after="87600h" --ca ./ca/root-ca.crt --ca-key ./ca/root-ca.key

# create leaf certificate which is signed by CA (for elephant.io)
step certificate create elephant.io elephant.io.crt elephant.io.key --profile leaf --subtle --no-password --kty RSA --insecure --not-after="87600h" --ca ./ca/root-ca.crt --ca-key ./ca/root-ca.key

# create leaf certificate which is signed by CA (for hellocloud.io)
step certificate create hellocloud.io hellocloud.io.crt hellocloud.io.key --profile leaf --subtle --no-password --kty RSA --insecure --not-after="87600h" --ca ./ca/root-ca.crt --ca-key ./ca/root-ca.key

######## verify
openssl x509 --text --noout --in ./rabbit.io.crt
openssl x509 --text --noout --in ./elephant.io.crt
openssl x509 --text --noout --in ./hellocloud.io.crt

kubectl create -n istio-system secret tls rabbit-cert --key rabbit.io.key --cert rabbit.io.crt
kubectl create -n istio-system secret tls elephant-cert --key elephant.io.key --cert elephant.io.crt
kubectl create -n istio-system secret tls hellocloud-cert --key hellocloud.io.key --cert hellocloud.io.crt