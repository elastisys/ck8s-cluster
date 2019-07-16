#!/bin/bash

# Dir where this script is located
HARBOR_DIR="$(dirname "$(readlink -f "$0")")"
SCRIPT_DIR="${HARBOR_DIR}/../scripts"
WORKSPACE="${HARBOR_DIR}/.."
CERT_FOLDER="staging-certs"

echo $HARBOR_DIR
echo $SCRIPT_DIR
echo $WORKSPACE
echo $CERT_FOLDER


mkdir -p ${CERT_FOLDER}/kube-system/certs

sh ${SCRIPT_DIR}/initialize-cluster.sh staging-certs "Jenkins admin1 admin2"

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

# add pod wait something

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0
# Create letsencrypt-staging and prod ClusterIssuers
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-prod.yaml

kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -

kubectl apply -f ${WORKSPACE}/manifests/podSecurityPolicy/psp-access.yaml

kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -


helm upgrade harbor ${WORKSPACE}/charts/harbor \
  --install \
  --namespace harbor \
  --values ${WORKSPACE}/helm-values/harbor-values.yaml

kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod

# helm upgrade harbor /home/erik/a1-demo/charts/harbor \
#   --install \
#   --namespace harbor \
#   --values /home/erik/a1-demo/helm-values/harbor-values.yaml


##############################################################

export CERT_FOLDER=staging-certs
export WORKSPACE=/home/erik/a1-demo

mkdir -p ${CERT_FOLDER}/kube-system/certs

kubectl apply -f ${WORKSPACE}/manifests/podSecurityPolicy/psp-access.yaml

sh ${WORKSPACE}/scripts/initialize-cluster.sh staging-certs "helm admin1 admin2"

source helm-env.sh kube-system staging-certs/kube-system/certs helm

### NAMESPACES ####
# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -

# Create the namespace for harbor
kubectl create ns harbor --dry-run -o yaml | kubectl apply -f -

### LABELS ####
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

### PSP ### 
# Run 
kubectl apply -f ${WORKSPACE}/manifests/podSecurityPolicy/psp-access.yaml

### Cert-manager ###
# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.1

# Create letsencrypt-staging and prod ClusterIssuers
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-prod.yaml

kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -


helm upgrade harbor ${WORKSPACE}/charts/harbor \
  --install \
  --namespace harbor \
  --values ${WORKSPACE}/helm-values/harbor-values.yaml \
  --set persistence.imageChartStorage.s3.secretkey=$TF_VAR_exoscale_secret_key \
  --set persistence.imageChartStorage.s3.accesskey=$TF_VAR_exoscale_api_key

kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod

 kubectl get secret mags-tls -n cert-manager --export -o yaml | kubectl apply -n harbor -f -
