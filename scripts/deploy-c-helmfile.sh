#!/bin/bash

set -e
: "${ECK_SS_KUBECONFIG:?Missing ECK_SS_KUBECONFIG}"
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
source "${SCRIPTS_PATH}/common.sh"

# ES_PW=$(kubectl --kubeconfig="${ECK_SS_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)


# NAMESPACES
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace falco --dry-run -o yaml | kubectl apply -f -
kubectl create namespace opa --dry-run -o yaml | kubectl apply -f -


# Node restriction
# sh ${SCRIPTS_PATH}/node-restriction.sh


# PSP
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-c.yaml


# HELM, TILLER
mkdir -p ${SCRIPTS_PATH}/../certs/customer/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/customer "admin1"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/customer/kube-system/certs admin1


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# FLUENTD
kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers


# OPA
# TODO: This appears to unfortunately take a while. Might want to use the cert
#       generation in the chart instead of cert-manager.
# echo Waiting for cert-manager webhook to become ready
# kubectl -n cert-manager wait --for=condition=Ready --timeout=300s \
#     certificate cert-manager-webhook-webhook-tls
kubectl -n opa create cm policies -o yaml --dry-run \
    --from-file="${SCRIPTS_PATH}/../policies" | kubectl apply -f -
kubectl -n opa label cm policies openpolicyagent.org/policy=rego --overwrite


# Prometheus CRDS
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml