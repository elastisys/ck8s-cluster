#!/bin/bash

set -e

: "${ECK_SS_KUBECONFIG:?Missing ECK_SS_KUBECONFIG}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/deploy-common.sh"

pushd "${SCRIPTS_PATH}/../terraform/customer/" > /dev/null

# Elastic ip for the customer cluster.
E_IP=$(terraform output c-elastic-ip)
NFS_SERVER_IP=$(terraform output c-nfs-ip)

popd > /dev/null

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

# Elastic ip for the system services cluster.
SS_E_IP=$(terraform output ss-elastic-ip)

popd > /dev/null

ES_PW=$(kubectl --kubeconfig="${ECK_SS_KUBECONFIG}" get secret quickstart-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace falco --dry-run -o yaml | kubectl apply -f -
kubectl create namespace nfs-provisioner --dry-run -o yaml | kubectl apply -f -

# Node restriction
sh ${SCRIPTS_PATH}/node-restriction.sh

# PSP

kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-c.yaml

# HELM, TILLER

mkdir -p ${SCRIPTS_PATH}/../certs/customer/kube-system/certs

${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/customer "admin1"

source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/customer/kube-system/certs admin1

# FLUENTD

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

# TODO: Use upstream chart once https://github.com/kiwigrid/helm-charts/pull/147
#       is merged.
# helm repo add kiwigrid https://kiwigrid.github.io
# helm repo update
# helm upgrade fluentd kiwigrid/fluentd-elasticsearch \
helm upgrade fluentd ${SCRIPTS_PATH}/../charts/fluentd-elasticsearch \
    --install --values "${SCRIPTS_PATH}/../helm-values/fluentd-values.yaml" \
    --set "elasticsearch.host=elastic.${ECK_DOMAIN}" \
    --namespace kube-system --version 4.3.2

# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite

# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
# Update your local Helm chart repository cache
helm repo update

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0

# FALCO

helm upgrade falco stable/falco --install --namespace falco --version 0.7.6

helm install stable/nfs-client-provisioner --set nfs.server=${NFS_SERVER_IP} --set nfs.path=/nfs \
 --namespace nfs-provisioner --set serviceAccount.name=nfs-client-provisioner
