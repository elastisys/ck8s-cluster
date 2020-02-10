#!/bin/bash
# Script used by pipeline to cleanup run.
# Can be used manually if these vars are set. and arg1 is set to build-number
# Run number can be found in first step of infra as GITHUB_RUN_ID.
# TF_TOKEN
# EXOSCALE_API_KEY
# EXOSCALE_SECRET_KEY
# VAULT_TOKEN
set -e
SCRIPTS_PATH="$(dirname "$(readlink -f "$0")")"

if [[ -z "$GITHUB_RUN_ID" ]]; then
    if [[ -n "$1" ]]; then
        export MANUAL=true
        GITHUB_RUN_ID=$1
    else 
        echo "ERROR: GITHUB_RUN_ID is empty and no arg1 is set. One is required"
        exit 1
    fi
fi

export CLOUD_PROVIDER=safespring
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source ${SCRIPTS_PATH}/vault-variables.sh
source ${SCRIPTS_PATH}/variables.sh

if [[ "$MANUAL" == true ]]; then
    export TF_VAR_ssh_pub_key_file_sc="not-needed"
    export TF_VAR_ssh_pub_key_file_wc="not-needed"
else
    export VAULT_TOKEN=$(${SCRIPTS_PATH}/vault-token-get.sh)
fi

export CONFIG_PATH=$(pwd)
export KUBECONFIG=$(pwd)/kube_config_eck-sc.yaml

echo "Getting files from vault"

mkdir -p certs/service_cluster/kube-system/certs
FILES="certs/service_cluster/kube-system/certs/ca-key.pem
certs/service_cluster/kube-system/certs/ca.pem
certs/service_cluster/kube-system/certs/helm-key.pem
certs/service_cluster/kube-system/certs/helm.pem
certs/service_cluster/kube-system/certs/tiller-key.pem
certs/service_cluster/kube-system/certs/tiller.pem"
for file in ${FILES}
do
    echo "Trying to get file $file"
    vault kv get -field=base64-content eck/v1/${CLOUD_PROVIDER}/${ENVIRONMENT_NAME}/${file} | base64 --decode > ${CONFIG_PATH}/${file}
    if [ $? == 0 ]
    then echo "Success"
    fi
done

export MANUAL=true
${SCRIPTS_PATH}/vault-cleanup.sh certs/service_cluster/kube-system/certs/ca-key.pem certs/service_cluster/kube-system/certs/ca.pem certs/service_cluster/kube-system/certs/helm-key.pem certs/service_cluster/kube-system/certs/helm.pem certs/service_cluster/kube-system/certs/tiller-key.pem certs/service_cluster/kube-system/certs/tiller.pem

kubectl delete elasticsearches.elasticsearch.k8s.elastic.co -n elastic-system --all
helmfile -f helmfile/helmfile.yaml -e service_cluster destroy
kubectl delete pvc -n harbor --all
kubectl delete pvc -n influxdb-prometheus --all

volumes_left="$(kubectl get pv -o json | jq '.items[] | {pv_name: .metadata.name, pvc_namespace: .spec.claimRef.namespace, pvc_name: .spec.claimRef.name}')"
counter=0
while [[ "$volumes_left" != "" ]] && [ $counter -lt 10 ]
do
    echo "Volumes are not removed yet"
    counter=$((counter+1))
    sleep 5
    volumes_left="$(kubectl get pv -o json | jq '.items[] | {pv_name: .metadata.name, pvc_namespace: .spec.claimRef.namespace, pvc_name: .spec.claimRef.name}')"
done
if [[ "$volumes_left" != "" ]]
then
    echo "Warning: There seems to be volumes left in the cluster, this will result in volumes on safespring that needs to be cleaned up manually."
    echo "Volumes left:"
    echo "$volumes_left"
    exit 1
fi
echo "Cleanup of volumes completed!"