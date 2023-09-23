# pre-requisites
source .bash_profile
asdf list

# install istioctl of your choice if necessary
    # asdf install istioctl 1.18.2
    # asdf install istioctl 1.17.5
    # asdf install istioctl 1.16.7

# set the istio version
asdf global istioctl 1.17.5

export ISTIO_VERSION=1.17.5
export ISTIO_VERSION=1.18.2

curl -L https://istio.io/downloadIstio | ISTIO_VERSION=${ISTIO_VERSION} sh -

curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=1.18.0-alpha.0 sh -
curl -sL https://istio.io/downloadIstio | ISTIO_VERSION=1.18.0 sh -

# sudo cp istio-${ISTIO_VERSION}/bin/istioctl /usr/local/bin

istioctl x precheck

# istio profiles
istioctl profile list

# install demo profile
istioctl install --set profile=demo -y

kubectl get crds -n istio-system



