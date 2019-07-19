#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/deploy-common.sh"

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

E_IP=$(terraform output ss-elastic-ip)

popd > /dev/null

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace elastic-system --dry-run -o yaml | kubectl apply -f -
kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
kubectl create namespace dex --dry-run -o yaml | kubectl apply -f -

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-ss.yaml


# INGRESS

# Genereate certifiacte for ingress
openssl req -x509 -nodes -newkey rsa:4096 \
    -sha256 -keyout ss-key.pem -out ss-cert.pem \
    -subj "/CN=${E_IP}" -days 365

# Genereate the yaml file for deploying the ingress tls secret.
kubectl -n ingress-nginx create secret tls ingress-default-cert \
    --cert=ss-cert.pem --key=ss-key.pem -o yaml \
    --dry-run=true > ingress-default-cert.yaml

# Create the secret from the generated file.
kubectl	apply -f ingress-default-cert.yaml


# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/system-services "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs admin1


# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0

# Elasticsearch and kibana.

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana.yaml

# Ingresses
cat ${SCRIPTS_PATH}/../manifests/ingress/ingress.yaml | envsubst | kubectl apply -f -
