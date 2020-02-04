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

export CLOUD_PROVIDER=exoscale
export ENVIRONMENT_NAME="pipeline-$GITHUB_RUN_ID"
source ${SCRIPTS_PATH}/init-exoscale.sh
source ${SCRIPTS_PATH}/vault-variables.sh

if [[ "$MANUAL" == true ]]; then
    export TF_VAR_ssh_pub_key_file_sc="not-needed"
    export TF_VAR_ssh_pub_key_file_wc="not-needed"
else
    source ${SCRIPTS_PATH}/init-ssh.sh
    export VAULT_TOKEN=$(./${SCRIPTS_PATH}/vault-token-get.sh)
fi
# Revoke vault token, remove password secrets for services
${SCRIPTS_PATH}/vault-cleanup.sh grafana harbor influxdb kubelogin_client dashboard_client grafana_client prometheus customer_prometheus customer_grafana customer_alertmanager elasticsearch-es-elastic-user

export TF_VAR_dns_prefix=pipeline-$GITHUB_RUN_ID
#Destroy infrastructure
cd ${SCRIPTS_PATH}/../terraform/exoscale
echo '1' | TF_WORKSPACE=pipeline terraform init
terraform workspace select pipeline-$GITHUB_RUN_ID
terraform destroy -auto-approve
terraform workspace select pipeline
terraform workspace delete pipeline-$GITHUB_RUN_ID
echo "Cleanup completed!"