#!/bin/bash

set -e

: "${ECK_SS_KUBECONFIG:?Missing ECK_SS_KUBECONFIG}"

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"
source "${SCRIPTS_PATH}/common.sh"

pushd "${SCRIPTS_PATH}/../terraform/" > /dev/null
export NFS_C_SERVER_IP=$(terraform output c_nfs_ip_address)
popd > /dev/null

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${1:-""}

ES_PW=$(kubectl --kubeconfig="${ECK_SS_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)


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
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/customer "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/customer/kube-system/certs "helm"


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# FLUENTD
kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml


# OPA
# Copy original 'allowed_registries'
cp ${SCRIPTS_PATH}/../policies/allowed_registries.rego ${SCRIPTS_PATH}/../policies/allowed_registries.rego.orig
# Add our Harbor domain as allowed registry.
envsubst < ${SCRIPTS_PATH}/../policies/allowed_registries.rego > ${SCRIPTS_PATH}/../policies/allowed_registries.rego.tmp
mv ${SCRIPTS_PATH}/../policies/allowed_registries.rego.tmp ${SCRIPTS_PATH}/../policies/allowed_registries.rego

kubectl -n opa create cm policies -o yaml --dry-run \
    --from-file="${SCRIPTS_PATH}/../policies/ingress-whitelist.rego" \
    --from-file="${SCRIPTS_PATH}/../policies/main.rego" \
    --from-file="${SCRIPTS_PATH}/../policies/netpol-demo.rego" \
    --from-file="${SCRIPTS_PATH}/../policies/allowed_registries.rego" | kubectl apply -f -
kubectl -n opa label cm policies openpolicyagent.org/policy=rego --overwrite
# Restore original file.
mv ${SCRIPTS_PATH}/../policies/allowed_registries.rego.orig ${SCRIPTS_PATH}/../policies/allowed_registries.rego


# Prometheus CRDS
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/alertmanager.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheus.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/prometheusrule.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/servicemonitor.crd.yaml
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/master/example/prometheus-operator-crd/podmonitor.crd.yaml

# Helmfile
echo -e "\nContinuing to Helmfile\n"

cd ${SCRIPTS_PATH}/../helmfile

# Install cert-manager and nfs-client-provisioner first.
helmfile -f helmfile.yaml -e customer -l app=cert-manager -l app=nfs-client-provisioner $INTERACTIVE apply

# Get status of the cert-manager webhook api.
STATUS=$(kubectl get apiservice v1beta1.admission.certmanager.k8s.io -o yaml -o=jsonpath='{.status.conditions[0].type}')

# Just want to see if this ever happens.
if [ $STATUS != "Available" ] 
then
    echo -e  "##\n##\nWaiting for cert-manager webhook to become ready\n##\n##"
    kubectl wait --for=condition=Available --timeout=300s \
        apiservice v1beta1.admission.certmanager.k8s.io
fi

# Install rest of the charts.
helmfile -f helmfile.yaml -e customer -l app!=cert-manager,app!=nfs-client-provisioner $INTERACTIVE apply
