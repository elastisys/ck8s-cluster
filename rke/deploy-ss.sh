#!/bin/bash

# terraform apply

# Can be done better! Just making sure that this is a clean install.
rm kube_config_cluster-ss.yaml cluster-ss.rkestate

./gen-rke-conf-ss.sh

rke up --config cluster-ss.yaml

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
export KUBECONFIG=kube_config_cluster-ss.yaml

cd ${SCRIPTS_PATH}/../terraform/system-services/

E_IP=$(terraform output ss-elastic-ip)

cd ${SCRIPTS_PATH}


# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml


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

${SCRIPTS_PATH}/../scripts/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/system-services "admin1"

source ${SCRIPTS_PATH}/../scripts/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs admin1


# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Create the namespace for cert-manager
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# FIX/do better at a later point in time...
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml


# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0


# Elasticsearch and kibana.


kubectl create ns elastic-system

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml

kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/operator.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/elasticsearch.yaml
sleep 5
kubectl apply -f ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/kibana.yaml

# Ingresses
kubectl apply -f ${SCRIPTS_PATH}/../manifests/ingress/ingress.yaml
