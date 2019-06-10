#!/bin/bash

# Script for initializing tiller in a specific namespace with TLS enabled.
#
# Usage: ./initialize-tiller.sh <namespace> <cert-dir> <helm-rbac-dir>
#
# Based on https://github.com/helm/helm/blob/master/docs/tiller_ssl.md

NAMESPACE=${1:-kube-system}
CERT_DIR=${2:-certs}
HELM_RBAC_DIR=${3:-helm-setup}

# Avoid surprizes from helm environment variables
# Envirnoment vars seem to override some flags
unset HELM_TLS_CERT
unset HELM_TLS_KEY
unset HELM_TLS_CA_CERT
unset HELM_TLS_ENABLE


# Create RBAC resources for tiller
kubectl -n $NAMESPACE apply -R -f ${HELM_RBAC_DIR}

if [ "$NAMESPACE" == "kube-system" ]
then
    # Cluster wide tiller
    kubectl create clusterrolebinding tiller --clusterrole=cluster-admin \
        --serviceaccount=$NAMESPACE:tiller \
        --dry-run -o yaml | kubectl apply -f -
else
    kubectl -n $NAMESPACE create rolebinding tiller --role=tiller-role \
        --serviceaccount=$NAMESPACE:tiller \
        --dry-run -o yaml | kubectl apply -f -
fi

echo "Initializing tiller in namespace ${NAMESPACE}"

helm init \
    --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' \
    --tiller-tls \
    --tiller-tls-verify \
    --tiller-tls-cert=${CERT_DIR}/tiller.pem \
    --tiller-tls-key=${CERT_DIR}/tiller-key.pem \
    --tls-ca-cert=${CERT_DIR}/ca.pem \
    --service-account=tiller \
    --upgrade \
    --tiller-namespace=${NAMESPACE}

# Wait for tiller to become ready
# We cannot use `--wait` due to this: https://github.com/helm/helm/issues/5170
ready_pods=$(kubectl get deployment -n ${NAMESPACE} tiller-deploy -o jsonpath='{.status.readyReplicas}')
# Set default 0 (output is empty if no pod is ready)
until [ ${ready_pods:=0} -eq 1 ]
do
    echo "Waiting for tiller to become ready..."
    sleep 2s
    ready_pods=$(kubectl get deployment -n ${NAMESPACE} tiller-deploy -o jsonpath='{.status.readyReplicas}')
done

echo "Tiller deployed in namespace ${NAMESPACE}."
