#!/bin/bash
# Script used by pipeline to cleanup volumes in safespring.
# Can be used manually if the cluster is still intact,
# kube_config to service cluster is in the current working directory, 
# and arg1 is set to build-number
# Run number can be found in first step of infra as GITHUB_RUN_ID.
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

kubectl delete ns elastic-system harbor monitoring fluentd influxdb-prometheus
kubectl delete pv --all --wait

volumes_left="$(kubectl get pv -o json | jq '.items[] | {pv_name: .metadata.name, pvc_namespace: .spec.claimRef.namespace, pvc_name: .spec.claimRef.name}')"
if [[ "$volumes_left" != "" ]]
then
    echo "Warning: There seems to be volumes left in the cluster, this will result in volumes on safespring that needs to be cleaned up manually."
    echo "Volumes left:"
    echo "$volumes_left"
    exit 1
fi
echo "Cleanup of volumes completed!"