#!/bin/bash

set -e


: "${ECK_SS_KUBECONFIG:?Missing ECK_SS_KUBECONFIG}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/common.sh"

pushd "${SCRIPTS_PATH}/../terraform/customer/" > /dev/null

# Elastic ip for the customer cluster.
E_IP=$(terraform output c-elastic-ip)

NFS_SERVER_IP=$(terraform output c-nfs-ip)

popd > /dev/null

pushd "${SCRIPTS_PATH}/../terraform/system-services/" > /dev/null

# Elastic ip for the system services cluster.
SS_E_IP=$(terraform output ss-elastic-ip)

popd > /dev/null

ES_PW=$(kubectl --kubeconfig="${ECK_SS_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

# NAMESPACES

kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace falco --dry-run -o yaml | kubectl apply -f -
kubectl create namespace opa --dry-run -o yaml | kubectl apply -f -

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

# Add Helm repositories and update repository cache

helm repo add jetstack https://charts.jetstack.io
helm repo add kiwigrid https://kiwigrid.github.io
helm repo update

# NFS client provisioner

helm upgrade nfs-client-provisioner stable/nfs-client-provisioner \
  --install --namespace kube-system --version 1.2.6 \
  --values ${SCRIPTS_PATH}/../helm-values/nfs-client-provisioner-values.yaml \
  --set nfs.server=${NFS_SERVER_IP}

# DASHBOARD, OAUTH2

helm upgrade oauth2 stable/oauth2-proxy --install --namespace kube-system \
    --set "extraArgs.oidc-issuer-url=https://dex.$ECK_DOMAIN" \
    --set "extraArgs.redirect-url=https://dashboard.$ECK_C_DOMAIN/oauth2/callback" \
    --set "ingress.hosts={dashboard.$ECK_C_DOMAIN}" \
    --set "ingress.tls[0].hosts={dashboard.$ECK_C_DOMAIN}" \
    -f ${SCRIPTS_PATH}/../helm-values/oauth2-proxy-values-c.yaml --version 0.12.3

kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# FLUENTD

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

helm upgrade fluentd kiwigrid/fluentd-elasticsearch \
    --install --values "${SCRIPTS_PATH}/../helm-values/fluentd-values.yaml" \
    --set "elasticsearch.host=elastic.${ECK_DOMAIN}" \
    --namespace kube-system --version 4.5.1

# CERT-MANAGER

# Install the cert-manager CRDs **before** installing the chart
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
# https://docs.cert-manager.io/en/latest/getting-started/install.html#installing-with-helm
# Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers

helm upgrade cert-manager jetstack/cert-manager \
    --install --namespace cert-manager --version v0.8.0

# FALCO

helm upgrade falco stable/falco --install --namespace falco --version 0.7.6

# OPA

# TODO: This appears to unfortunately take a while. Might want to use the cert
#       generation in the chart instead of cert-manager.
echo Waiting for cert-manager webhook to become ready
kubectl -n cert-manager wait --for=condition=Ready --timeout=300s \
    certificate cert-manager-webhook-webhook-tls

helm upgrade opa stable/opa --install \
    --values "${SCRIPTS_PATH}/../helm-values/opa-values.yaml" \
    --namespace opa --version 1.6.0

kubectl -n opa create cm policies -o yaml --dry-run \
    --from-file="${SCRIPTS_PATH}/../policies" | kubectl apply -f -
kubectl -n opa label cm policies openpolicyagent.org/policy=rego --overwrite

# Deploy prometheus operator
helm upgrade prometheus-operator stable/prometheus-operator \
  --install --namespace monitoring \
  -f ${SCRIPTS_PATH}/../helm-values/prometheus-c.yaml \
  --version 6.2.1 \
  --set "prometheus.prometheusSpec.remoteRead[0].url=https://influxdb-prometheus.${ECK_DOMAIN}/api/v1/prom/read?db\=customer&u\=demo&p\=demo-pass" \
  --set "prometheus.prometheusSpec.remoteWrite[0].url=https://influxdb-prometheus.${ECK_DOMAIN}/api/v1/prom/write?db\=customer&u\=demo&p\=demo-pass"
