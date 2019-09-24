#!/bin/bash

set -e

: "${ECK_SC_KUBECONFIG:?Missing ECK_SC_KUBECONFIG}"

# If unset -> true.
ENABLE_OPA=${ENABLE_OPA:-true}
ENABLE_PSP=${ENABLE_PSP:-true}

SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

source "${SCRIPTS_PATH}/common.sh"

if [[ "$#" -lt 1 ]]
then 
  echo "Usage: deploy-wc.sh path-to-infra-file <--interactive>"
  exit 1
fi

infra="$1"

pushd "${SCRIPTS_PATH}/../" > /dev/null
export NFS_WC_SERVER_IP=$(cat $infra | jq -r '.workload_cluster.nfs_ip_address')
popd > /dev/null

# Arg for Helmfile to be interactive so that one can decide on which releases
# to update if changes are found.
# USE: --interactive, default is not interactive.
INTERACTIVE=${2:-""}

# NAMESPACES
kubectl create namespace cert-manager --dry-run -o yaml | kubectl apply -f -
kubectl create namespace falco --dry-run -o yaml | kubectl apply -f -

if [[ $ENABLE_OPA == "true" ]]
then
    kubectl create namespace opa --dry-run -o yaml | kubectl apply -f -
fi


# PSP
if [[ $ENABLE_PSP == "true" ]]
then
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/restricted-psp.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access.yaml
    kubectl apply -f ${SCRIPTS_PATH}/../manifests/podSecurityPolicy/psp-access-wc.yaml
fi

# HELM, TILLER
mkdir -p ${SCRIPTS_PATH}/../certs/workload_cluster/kube-system/certs
${SCRIPTS_PATH}/initialize-cluster.sh ${SCRIPTS_PATH}/../certs/workload_cluster "helm"
source ${SCRIPTS_PATH}/helm-env.sh kube-system ${SCRIPTS_PATH}/../certs/workload_cluster/kube-system/certs "helm"


# DASHBOARD
kubectl apply -f ${SCRIPTS_PATH}/../manifests/dashboard.yaml


# CERT-MANAGER
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true --overwrite
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-prod.yaml
kubectl apply -f ${SCRIPTS_PATH}/../manifests/issuers/letsencrypt-staging.yaml


# OPA
if [[ $ENABLE_OPA == "true" ]]
then
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
fi

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
helmfile -f helmfile.yaml -e workload_cluster -l app=cert-manager -l app=nfs-client-provisioner $INTERACTIVE apply

# Get status of the cert-manager webhook api.
STATUS=$(kubectl get apiservice v1beta1.webhook.certmanager.k8s.io -o yaml -o=jsonpath='{.status.conditions[0].type}')

# Just want to see if this ever happens.
if [ $STATUS != "Available" ] 
then
    echo -e  "##\n##\nWaiting for cert-manager webhook to become ready\n##\n##"
    kubectl wait --for=condition=Available --timeout=300s \
        apiservice v1beta1.webhook.certmanager.k8s.io
fi

if [[ $ENABLE_OPA == "true" ]]
then
    # Install rest of the charts excluding fluentd and prometheus.
    helmfile -f helmfile.yaml -e workload_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd,app!=prometheus-operator $INTERACTIVE apply
else
    helmfile -f helmfile.yaml -e workload_cluster -l app!=cert-manager,app!=nfs-client-provisioner,app!=fluentd,app!=prometheus-operator,app!=opa $INTERACTIVE apply
fi

# Install prometheus-operator. Retry three times.
tries=3 
success=false

for i in $(seq 1 $tries)
do
    if helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE apply
    then
        success=true
        break
    else
        echo failed to deploy prometheus operator on try $i
        helmfile -f helmfile.yaml -e workload_cluster -l app=prometheus-operator $INTERACTIVE destroy
    fi
done

# Then prometheus operator failed too many times
if [ $success != "true" ] 
then
    exit 1
fi


# FLUENTD

# Get elastisearch password from service_cluster cluster
ES_PW=$(kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)

while [ -z "$ES_PW" ]
do
    echo "Waiting for elasticsearch password"
    sleep 5
    ES_PW=$(kubectl --kubeconfig="${ECK_SC_KUBECONFIG}" get secret elasticsearch-es-elastic-user -n elastic-system -o=jsonpath='{.data.elastic}' | base64 --decode)
done
echo "Got elsticsearch password"

kubectl -n kube-system create secret generic elasticsearch \
    --from-literal=password="${ES_PW}" --dry-run -o yaml | kubectl apply -f -

# Install fluentd
helmfile -f helmfile.yaml -e workload_cluster -l app=fluentd $INTERACTIVE apply