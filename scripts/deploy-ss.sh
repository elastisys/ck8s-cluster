#!/bin/bash

set -e

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/deploy-common.sh"

: "${TF_VAR_exoscale_api_key:?Missing TF_VAR_exoscale_api_key}"
: "${TF_VAR_exoscale_secret_key:?Missing TF_VAR_exoscale_secret_key}"

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

E_IP=$(terraform output ss-elastic-ip)
NFS_SERVER_IP=$(terraform output ss-nfs-ip)

popd > /dev/null

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace elastic-system --dry-run -o yaml | kubectl apply -f -
kubectl create namespace harbor --dry-run -o yaml | kubectl apply -f -
kubectl create namespace dex --dry-run -o yaml | kubectl apply -f -
kubectl create namespace nfs-provisioner --dry-run -o yaml | kubectl apply -f -

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-ss.yaml

# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/system-services "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/system-services/kube-system/certs admin1

# DEX, OAUTH2, DASHBOARD
helm upgrade dex ../charts/dex --install --namespace dex \
 -f ../helm-values/dex-values.yaml --debug

helm upgrade oauth2 stable/oauth2-proxy --install --namespace kube-system \
    -f ../helm-values/oauth2-proxy-values.yaml --version 0.12.3

kubectl apply -f ../manifests/dashboard.yaml

# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
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

cat ${SCRIPTS_PATH}/../manifests/elasticsearch-kibana/ingress.yaml | envsubst | kubectl apply -f -

# NFS client provisioner

helm install stable/nfs-client-provisioner --set nfs.server=${NFS_SERVER_IP} --set nfs.path=/nfs \
 --namespace harbor --set serviceAccount.name=nfs-client-provisioner

# HARBOR

kubectl apply -f ${SCRIPTS_PATH}/../harbor/harbor-claim.yaml

# Create rolebindings for harbor
kubectl -n harbor create rolebinding harbor-privileged-psp \
    --clusterrole=psp:privileged --serviceaccount=harbor:default \
    --dry-run -o yaml | kubectl apply -f -

# Deploying harbor
helm upgrade harbor ${SCRIPTS_PATH}/../harbor/charts/harbor \
  --install \
  --namespace harbor \
  --values ${SCRIPTS_PATH}/../helm-values/harbor-values.yaml \
  --set persistence.imageChartStorage.s3.secretkey=$TF_VAR_exoscale_secret_key \
  --set persistence.imageChartStorage.s3.accesskey=$TF_VAR_exoscale_api_key

# Annotate certmanager for harbor
kubectl -n harbor annotate ingress harbor-harbor-ingress certmanager.k8s.io/cluster-issuer=letsencrypt-prod
