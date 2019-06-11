#!/bin/bash

# Dir where this script is located
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WORKSPACE="${SCRIPT_DIR}/../"

#
# Falco
#

# https://github.com/helm/charts/tree/master/stable/falco
helm upgrade falco stable/falco --install --namespace falco --version 0.7.6

# Faclo requires privileged PSP and does not include its own policy in the chart
kubectl -n falco create rolebinding falco-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=falco:falco \
    --dry-run -o yaml | kubectl apply -f -

#
# Nginx-ingress
#

https://github.com/helm/charts/tree/master/stable/nginx-ingress
helm upgrade nginx-ingress stable/nginx-ingress --install \
    --namespace nginx-ingress --version 1.6.16

#
# Cert-manager
#

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

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0
# Create letsencrypt-staging and prod ClusterIssuers
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-staging.yaml
kubectl apply -f ${WORKSPACE}/manifests/issuers/letsencrypt-prod.yaml
